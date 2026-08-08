import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../domain/entities/business.dart';
import '../controllers/business_controller.dart';
import 'business_dashboard_screen.dart';
import 'location_picker_screen.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _pageController = PageController();
  int _step = 0;

  // ---- Adim 1: bilgiler
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  BusinessCategory _category = BusinessCategory.bakery;
  String? _nameError;
  String? _phoneError;
  PhoneValue _phone = const PhoneValue(
    fullNumber: '',
    isEmpty: true,
    isComplete: false,
    expectedDigits: 10,
  );

  // ---- Adim 2: konum
  final _addressController = TextEditingController();
  double? _lat;
  double? _lng;
  String? _resolvedAddress;
  String? _locationError;

  // ---- Adim 3: saatler
  TimeOfDay _opensAt = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closesAt = const TimeOfDay(hour: 20, minute: 0);

  /// Pazartesi = 0 ... Pazar = 6
  final Set<int> _openDays = {0, 1, 2, 3, 4, 5};

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _canGoNext => switch (_step) {
        0 => _nameController.text.trim().length >= 2 && _phone.isValid,
        1 => _lat != null && _lng != null,
        _ => _openDays.isNotEmpty,
      };

  void _next() {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      if (_nameController.text.trim().length < 2) {
        setState(() => _nameError = 'İşletme adı en az 2 karakter olmalı');
        return;
      }
      if (!_phone.isValid) {
        setState(() {
          _phoneError =
              'Telefon numarası ${_phone.expectedDigits} haneli olmalı';
        });
        return;
      }
    }

    setState(() {
      _nameError = null;
      _phoneError = null;
      _step++;
    });

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Haritali konum secici ekranini acar.
  Future<void> _openLocationPicker() async {
    FocusScope.of(context).unfocus();

    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
        ),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _lat = picked.latitude;
      _lng = picked.longitude;
      _resolvedAddress = picked.address;
      _locationError = null;

      // Kullanici kendi adres yazmadiysa haritadan geleni doldur.
      if (_addressController.text.trim().isEmpty) {
        _addressController.text = picked.address;
      }
    });
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final ok =
        await ref.read(businessControllerProvider.notifier).createBusiness(
              name: _nameController.text,
              category: _category,
              latitude: _lat!,
              longitude: _lng!,
              openDays: _openDays.toList()..sort(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text,
              address: _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text,
              phone: _phone.isEmpty ? null : _phone.fullNumber,
              opensAt: '${_formatTime(_opensAt)}:00',
              closesAt: '${_formatTime(_closesAt)}:00',
            );

    if (!mounted || !ok) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(businessControllerProvider);
    final isLast = _step == 2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: state.isLoading ? null : _back,
        ),
        title: Text('İşletme Kurulumu  ${_step + 1}/3'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / 3,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.outline,
                    color: AppColors.primary,
                  ),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepInfo(
                      nameController: _nameController,
                      descriptionController: _descriptionController,
                      phoneController: _phoneController,
                      category: _category,
                      nameError: _nameError,
                      phoneError: _phoneError,
                      onCategoryChanged: (c) => setState(() => _category = c),
                      onNameChanged: () => setState(() {}),
                      onPhoneChanged: (v) => setState(() {
                        _phone = v;
                        _phoneError = null;
                      }),
                    ),
                    _StepLocation(
                      addressController: _addressController,
                      lat: _lat,
                      lng: _lng,
                      resolvedAddress: _resolvedAddress,
                      error: _locationError,
                      onPickLocation: _openLocationPicker,
                    ),
                    _StepHours(
                      opensAt: _formatTime(_opensAt),
                      closesAt: _formatTime(_closesAt),
                      openDays: _openDays,
                      onToggleDay: (i) => setState(() {
                        if (_openDays.contains(i)) {
                          _openDays.remove(i);
                        } else {
                          _openDays.add(i);
                        }
                      }),
                      onPickOpening: () => _pickTime(isOpening: true),
                      onPickClosing: () => _pickTime(isOpening: false),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    if (state.errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
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
                      const SizedBox(height: AppSpacing.md),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (!_canGoNext || state.isLoading)
                            ? null
                            : (isLast ? _submit : _next),
                        child: state.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isLast ? 'İşletmemi Oluştur' : 'Devam Et'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ ADIM 1

class _StepInfo extends StatelessWidget {
  const _StepInfo({
    required this.nameController,
    required this.descriptionController,
    required this.phoneController,
    required this.category,
    required this.nameError,
    required this.phoneError,
    required this.onCategoryChanged,
    required this.onNameChanged,
    required this.onPhoneChanged,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController phoneController;
  final BusinessCategory category;
  final String? nameError;
  final String? phoneError;
  final ValueChanged<BusinessCategory> onCategoryChanged;
  final VoidCallback onNameChanged;
  final ValueChanged<PhoneValue> onPhoneChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İşletmeni tanıtalım',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bu bilgiler müşterilerin ilanlarında görünecek.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'İşletme Adı',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Ahmet Usta Fırın',
              prefixIcon: const Icon(Icons.storefront_outlined),
              errorText: nameError,
            ),
            onChanged: (_) => onNameChanged(),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Kategori',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: BusinessCategory.values.map((c) {
              final active = c == category;
              return GestureDetector(
                onTap: () => onCategoryChanged(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        active ? AppColors.primary : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: active
                          ? AppColors.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    c.displayName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color:
                          active ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Kısa Açıklama (isteğe bağlı)',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            maxLength: 200,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Her sabah taze hamur işi üretiyoruz.',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            'Telefon (isteğe bağlı)',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          PhoneField(
            controller: phoneController,
            errorText: phoneError,
            onChanged: onPhoneChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ================================================================ ADIM 2

class _StepLocation extends StatelessWidget {
  const _StepLocation({
    required this.addressController,
    required this.lat,
    required this.lng,
    required this.resolvedAddress,
    required this.error,
    required this.onPickLocation,
  });

  final TextEditingController addressController;
  final double? lat;
  final double? lng;
  final String? resolvedAddress;
  final String? error;
  final VoidCallback onPickLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = lat != null && lng != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İşletmen nerede?',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Müşteriler yakınlarındaki ilanları konuma göre görüyor. '
            'Haritadan işletmenin tam yerini seç.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Material(
            color: hasLocation
                ? AppColors.success.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: InkWell(
              onTap: onPickLocation,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: hasLocation
                        ? AppColors.success
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      hasLocation
                          ? Icons.check_circle_rounded
                          : Icons.map_rounded,
                      size: 44,
                      color:
                          hasLocation ? AppColors.success : AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      hasLocation ? 'Konum seçildi' : 'Haritadan konum seç',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (hasLocation && resolvedAddress != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        resolvedAddress!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      hasLocation
                          ? 'Değiştirmek için dokun'
                          : 'Haritayı açmak için dokun',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
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
                      error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          Text(
            'Adres Detayı',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Haritadan gelen adresi düzenleyebilir, kapı numarası gibi '
            'detaylar ekleyebilirsin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Cumhuriyet Mah. Gazi Cad. No:12',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ================================================================ ADIM 3

class _StepHours extends StatelessWidget {
  const _StepHours({
    required this.opensAt,
    required this.closesAt,
    required this.openDays,
    required this.onToggleDay,
    required this.onPickOpening,
    required this.onPickClosing,
  });

  final String opensAt;
  final String closesAt;
  final Set<int> openDays;
  final ValueChanged<int> onToggleDay;
  final VoidCallback onPickOpening;
  final VoidCallback onPickClosing;

  static const _dayLabels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çalışma saatlerin',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Profilinde görünecek genel saatler. Her ilan için ayrıca '
            'alım saati belirleyeceksin.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              Expanded(
                child: _TimeBox(
                  label: 'Açılış',
                  value: opensAt,
                  icon: Icons.wb_sunny_outlined,
                  onTap: onPickOpening,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TimeBox(
                  label: 'Kapanış',
                  value: closesAt,
                  icon: Icons.nightlight_outlined,
                  onTap: onPickClosing,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text(
                'Açık Olduğun Günler',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (openDays.isEmpty)
                Text(
                  'En az bir gün seç',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(7, (i) {
              final active = openDays.contains(i);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => onToggleDay(i),
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
                          _dayLabels[i],
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

          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Bu bilgileri daha sonra profilinden değiştirebilirsin.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
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
              Text(
                value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}