import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/image_picker_field.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../domain/entities/business.dart';
import '../controllers/business_controller.dart';
import 'location_picker_screen.dart';

class EditBusinessScreen extends ConsumerStatefulWidget {
  const EditBusinessScreen({super.key, required this.business});

  final Business business;

  @override
  ConsumerState<EditBusinessScreen> createState() =>
      _EditBusinessScreenState();
}

class _EditBusinessScreenState extends ConsumerState<EditBusinessScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  final _phoneController = TextEditingController();

  late BusinessCategory _category;
  late TimeOfDay _opensAt;
  late TimeOfDay _closesAt;
  late Set<int> _openDays;
  late double _lat;
  late double _lng;

  File? _logoFile;
  bool _pickingLogo = false;
  String? _nameError;
  bool _locationChanged = false;

  PhoneValue _phone = const PhoneValue(
    fullNumber: '',
    isEmpty: true,
    isComplete: false,
    expectedDigits: 10,
  );

  @override
  void initState() {
    super.initState();

    final b = widget.business;

    _nameController = TextEditingController(text: b.name);
    _descriptionController = TextEditingController(text: b.description ?? '');
    _addressController = TextEditingController(text: b.address ?? '');

    // Kayitli numara "+905551112233" formatinda; ulke kodunu ayiriyoruz.
    if (b.phone != null && b.phone!.startsWith('+90')) {
      _phoneController.text = b.phone!.substring(3);
    }

    _category = b.category;
    _opensAt = _parseTime(b.opensAt) ?? const TimeOfDay(hour: 8, minute: 0);
    _closesAt = _parseTime(b.closesAt) ?? const TimeOfDay(hour: 20, minute: 0);
    _openDays = b.openDays.toSet();
    _lat = b.latitude;
    _lng = b.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  static TimeOfDay? _parseTime(String? value) {
    if (value == null || value.length < 5) return null;
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickLogo(bool fromCamera) async {
    setState(() => _pickingLogo = true);

    final file =
        await ref.read(imageUploadServiceProvider).pick(fromCamera: fromCamera);

    if (!mounted) return;

    setState(() {
      _pickingLogo = false;
      if (file != null) _logoFile = file;
    });
  }

  Future<void> _pickTime({required bool isOpening}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _opensAt : _closesAt,
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isOpening) {
        _opensAt = picked;
      } else {
        _closesAt = picked;
      }
    });
  }

  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus();

    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLat: _lat, initialLng: _lng),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _lat = picked.latitude;
      _lng = picked.longitude;
      _locationChanged = true;
      if (_addressController.text.trim().isEmpty) {
        _addressController.text = picked.address;
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().length < 2) {
      setState(() => _nameError = 'İşletme adı en az 2 karakter olmalı');
      return;
    }

    if (_openDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir gün seçmelisin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final ok = await ref.read(businessControllerProvider.notifier).updateBusiness(
          name: _nameController.text,
          category: _category,
          description: _descriptionController.text,
          address: _addressController.text,
          phone: _phone.isEmpty ? null : _phone.fullNumber,
          opensAt: '${_fmt(_opensAt)}:00',
          closesAt: '${_fmt(_closesAt)}:00',
          openDays: _openDays.toList()..sort(),
          logoFile: _logoFile,
          latitude: _locationChanged ? _lat : null,
          longitude: _locationChanged ? _lng : null,
        );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşletme bilgileri güncellendi'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(businessControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşletme Bilgileri'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              120,
            ),
            children: [
              // ---- Logo
              Center(
                child: ImagePickerField(
                  onPick: _pickLogo,
                  localFile: _logoFile,
                  remoteUrl: _logoFile == null ? widget.business.logoUrl : null,
                  isUploading: _pickingLogo,
                  onRemove: () => setState(() => _logoFile = null),
                  height: 110,
                  circular: true,
                  label: '',
                  hint: '',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  'Logoyu değiştirmek için dokun',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ---- Ad
              const _Label('İşletme Adı'),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  errorText: _nameError,
                ),
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Kategori
              const _Label('Kategori'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: BusinessCategory.values.map((c) {
                  final active = c == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : theme.colorScheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        c.displayName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: active
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Aciklama
              const _Label('Açıklama'),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Her sabah taze hamur işi üretiyoruz.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ---- Telefon
              const _Label('Telefon'),
              PhoneField(
                controller: _phoneController,
                onChanged: (v) => setState(() => _phone = v),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Konum
              const _Label('Konum'),
              Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: InkWell(
                  onTap: _pickLocation,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: _locationChanged
                            ? AppColors.success
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _locationChanged
                              ? Icons.check_circle_rounded
                              : Icons.map_rounded,
                          color: _locationChanged
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _locationChanged
                                ? 'Yeni konum seçildi'
                                : 'Haritadan konumu değiştir',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Adres
              const _Label('Adres Detayı'),
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Saatler
              const _Label('Çalışma Saatleri'),
              Row(
                children: [
                  Expanded(
                    child: _TimeBox(
                      label: 'Açılış',
                      value: _fmt(_opensAt),
                      icon: Icons.wb_sunny_outlined,
                      onTap: () => _pickTime(isOpening: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _TimeBox(
                      label: 'Kapanış',
                      value: _fmt(_closesAt),
                      icon: Icons.nightlight_outlined,
                      onTap: () => _pickTime(isOpening: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Gunler
              const _Label('Açık Olduğun Günler'),
              Row(
                children: List.generate(7, (i) {
                  const labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
                  final active = _openDays.contains(i);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (active) {
                            _openDays.remove(i);
                          } else {
                            _openDays.add(i);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 46,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : theme.colorScheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              labels[i],
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: active
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isLoading ? null : _save,
              child: state.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Değişiklikleri Kaydet'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}