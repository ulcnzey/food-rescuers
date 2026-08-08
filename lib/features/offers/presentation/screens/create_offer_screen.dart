import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../business/domain/entities/business.dart';
import '../../../business/presentation/controllers/business_controller.dart';
import '../../domain/entities/offer.dart';
import '../controllers/offer_controller.dart';
import '../widgets/food_type_style.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();

  FoodType _foodType = FoodType.bakery;
  int _quantity = 1;
  bool _isFree = false;

  /// 0 = bugun, 1 = yarin
  int _dayOffset = 0;
  TimeOfDay _pickupStart = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _pickupEnd = const TimeOfDay(hour: 20, minute: 0);

  String? _titleError;
  String? _priceError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    super.dispose();
  }

  double get _price =>
      _isFree ? 0 : double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;

  double? get _originalPrice {
    final v = double.tryParse(
      _originalPriceController.text.replaceAll(',', '.'),
    );
    return (v == null || v <= 0) ? null : v;
  }

  int get _discountPercent {
    final orig = _originalPrice;
    if (orig == null || orig <= 0 || _price >= orig) return 0;
    return (((orig - _price) / orig) * 100).round();
  }

  DateTime _resolve(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day + _dayOffset,
      t.hour,
      t.minute,
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _pickupStart : _pickupEnd,
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _pickupStart = picked;
        // Bitis baslangictan onceyse otomatik 2 saat sonraya al.
        final startMin = picked.hour * 60 + picked.minute;
        final endMin = _pickupEnd.hour * 60 + _pickupEnd.minute;
        if (endMin <= startMin) {
          final newEnd = (startMin + 120).clamp(0, 23 * 60 + 59);
          _pickupEnd = TimeOfDay(hour: newEnd ~/ 60, minute: newEnd % 60);
        }
      } else {
        _pickupEnd = picked;
      }
    });
  }

  bool get _canSubmit {
    if (_titleController.text.trim().length < 3) return false;
    if (!_isFree && _price <= 0) return false;
    return true;
  }

  Future<void> _submit(Business business) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _titleError = _titleController.text.trim().length < 3
          ? 'Ürün adı en az 3 karakter olmalı'
          : null;
      _priceError =
          (!_isFree && _price <= 0) ? 'Geçerli bir fiyat girin' : null;
    });

    if (_titleError != null || _priceError != null) return;

    final start = _resolve(_pickupStart);
    final end = _resolve(_pickupEnd);

    final ok = await ref.read(offerControllerProvider.notifier).createOffer(
          title: _titleController.text,
          foodType: _foodType,
          price: _price,
          quantity: _quantity,
          pickupStart: start,
          pickupEnd: end,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text,
          originalPrice: _originalPrice,
        );

    if (!mounted || !ok) return;

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İlanın yayınlandı'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(myBusinessProvider);

    return businessAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Scaffold(
        body: Center(child: Text('İşletme bilgisi yüklenemedi')),
      ),
      data: (business) {
        if (business == null) {
          return const Scaffold(
            body: Center(child: Text('Önce işletme oluşturmalısın')),
          );
        }

        // Bireysel saglayici ucretli ilan veremez.
        final forcedFree = business.isIndividual;
        if (forcedFree && !_isFree) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isFree = true);
          });
        }

        return _buildForm(business, forcedFree);
      },
    );
  }

  Widget _buildForm(Business business, bool forcedFree) {
    final theme = Theme.of(context);
    final state = ref.watch(offerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Yeni İlan'),
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
              Text(
                'Ne kurtarıyorsun?',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Gün sonu kalan ürünlerini birkaç adımda listele.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ---------------- Urun adi
              const _Label('Ürün Adı'),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Karışık Poğaça Paketi',
                  errorText: _titleError,
                ),
                onChanged: (_) => setState(() => _titleError = null),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---------------- Kategori
              const _Label('Kategori'),
              _CategoryPicker(
                selected: _foodType,
                onChanged: (t) => setState(() => _foodType = t),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---------------- Aciklama
              const _Label('Açıklama (isteğe bağlı)'),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Sabah pişen poğaçalardan karışık bir paket.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ---------------- Fiyat
              const _Label('Fiyat'),
              if (forcedFree)
                _InfoBanner(
                  icon: Icons.volunteer_activism_rounded,
                  color: AppColors.success,
                  text: 'Bireysel paylaşımcı olarak yalnızca ücretsiz '
                      'bağış yapabilirsin.',
                )
              else
                _FreeToggle(
                  isFree: _isFree,
                  onChanged: (v) => setState(() {
                    _isFree = v;
                    _priceError = null;
                  }),
                ),

              if (!_isFree) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _PriceField(
                        controller: _originalPriceController,
                        label: 'Normal fiyat',
                        hint: '60',
                        onChanged: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PriceField(
                        controller: _priceController,
                        label: 'Satış fiyatı',
                        hint: '20',
                        errorText: _priceError,
                        highlight: true,
                        onChanged: () => setState(() => _priceError = null),
                      ),
                    ),
                  ],
                ),
                if (_discountPercent > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DiscountBadge(percent: _discountPercent),
                ],

                // FIYAT ONERISI buraya gelecek (ileri asama).
              ],

              const SizedBox(height: AppSpacing.lg),

              // ---------------- Adet
              const _Label('Kaç adet?'),
              _QuantityStepper(
                value: _quantity,
                onChanged: (v) => setState(() => _quantity = v),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---------------- Alim zamani
              const _Label('Alım Zamanı'),
              _DayPicker(
                selected: _dayOffset,
                onChanged: (v) => setState(() => _dayOffset = v),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _TimeBox(
                      label: 'Başlangıç',
                      value: _fmt(_pickupStart),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
                  Expanded(
                    child: _TimeBox(
                      label: 'Bitiş',
                      value: _fmt(_pickupEnd),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ---------------- Onizleme
              const _Label('Önizleme'),
              _PreviewCard(
                businessName: business.name,
                title: _titleController.text.trim().isEmpty
                    ? 'Ürün adı'
                    : _titleController.text.trim(),
                foodType: _foodType,
                price: _price,
                originalPrice: _originalPrice,
                quantity: _quantity,
                pickupLabel:
                    '${_dayOffset == 0 ? 'Bugün' : 'Yarın'} ${_fmt(_pickupStart)} - ${_fmt(_pickupEnd)}',
              ),

              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _InfoBanner(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.error,
                  text: state.errorMessage!,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomBar(
        enabled: _canSubmit && !state.isLoading,
        isLoading: state.isLoading,
        onPressed: () => _submit(business),
      ),
    );
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ================================================================ PARCALAR

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

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onChanged});

  final FoodType selected;
  final ValueChanged<FoodType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: FoodType.values.map((t) {
        final style = FoodTypeStyle.of(t);
        final active = t == selected;

        return GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: active
                  ? style.color.withValues(alpha: 0.15)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: active ? style.color : theme.colorScheme.outline,
                width: active ? 1.6 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 17, color: style.color),
                const SizedBox(width: 6),
                Text(
                  style.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FreeToggle extends StatelessWidget {
  const _FreeToggle({required this.isFree, required this.onChanged});

  final bool isFree;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'İndirimli Satış',
              active: !isFree,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Ücretsiz Bağış',
              active: isFree,
              activeColor: AppColors.success,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor = AppColors.primary,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: active ? Colors.white : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.errorText,
    this.highlight = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onChanged;
  final String? errorText;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: '₺',
            errorText: errorText,
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer_rounded,
              size: 15, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            '%$percent indirim uygulanacak',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Text(
            'Adet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: value > 1,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: value < 50,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.12)
          : theme.colorScheme.outline.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DayChip(
            label: 'Bugün',
            active: selected == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DayChip(
            label: 'Yarın',
            active: selected == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: active ? AppColors.primary : theme.colorScheme.outline,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: active ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.businessName,
    required this.title,
    required this.foodType,
    required this.price,
    required this.originalPrice,
    required this.quantity,
    required this.pickupLabel,
  });

  final String businessName;
  final String title;
  final FoodType foodType;
  final double price;
  final double? originalPrice;
  final int quantity;
  final String pickupLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = FoodTypeStyle.of(foodType);
    final isFree = price == 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 96,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  style.color.withValues(alpha: 0.30),
                  style.color.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Center(
              child: Icon(style.icon,
                  size: 40, color: style.color.withValues(alpha: 0.6)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pickupLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '$quantity adet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (isFree)
                      const Text(
                        'Ücretsiz',
                        style: TextStyle(
                          color: AppColors.freeBadge,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      )
                    else ...[
                      if (originalPrice != null) ...[
                        Text(
                          '${originalPrice!.toStringAsFixed(0)}₺',
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${price.toStringAsFixed(0)}₺',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('İlanı Yayınla'),
          ),
        ),
      ),
    );
  }
}