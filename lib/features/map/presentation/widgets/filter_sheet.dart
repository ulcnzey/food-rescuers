import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/entities/offer_filter.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../../offers/presentation/widgets/food_type_style.dart';

/// Tum filtreleri iceren alt sayfa.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late OfferFilter _draft;

  @override
  void initState() {
    super.initState();
    // Kullanici "Uygula" demeden mevcut filtre degismesin.
    _draft = ref.read(offerFilterProvider);
  }

  void _apply() {
    ref.read(offerFilterProvider.notifier).state = _draft;
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() => _draft = const OfferFilter());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text('Filtreler', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  if (!_draft.isDefault)
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Temizle'),
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  // ---- Kategori
                  const _SectionLabel('Kategori'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _Chip(
                        label: 'Tümü',
                        icon: Icons.apps_rounded,
                        color: AppColors.primary,
                        active: _draft.foodType == null,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(clearFoodType: true),
                        ),
                      ),
                      ...FoodType.values.map((t) {
                        final s = FoodTypeStyle.of(t);
                        return _Chip(
                          label: s.label,
                          icon: s.icon,
                          color: s.color,
                          active: _draft.foodType == t,
                          onTap: () => setState(() {
                            _draft = _draft.foodType == t
                                ? _draft.copyWith(clearFoodType: true)
                                : _draft.copyWith(foodType: t);
                          }),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ---- Alim zamani
                  const _SectionLabel('Alım zamanı'),
                  Column(
                    children: PickupWindow.values.map((w) {
                      return _RadioRow(
                        label: w.label,
                        selected: _draft.pickupWindow == w,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(pickupWindow: w),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ---- Fiyat
                  const _SectionLabel('Fiyat'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _draft.freeOnly,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(freeOnly: v),
                    ),
                    title: const Text('Sadece ücretsiz paylaşımlar'),
                    subtitle: Text(
                      'Bağış olarak paylaşılan ürünler',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    activeThumbColor: AppColors.primary,
                  ),

                  if (!_draft.freeOnly) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          'En fazla',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _draft.maxPrice == null
                              ? 'Sınırsız'
                              : '${_draft.maxPrice!.toStringAsFixed(0)} ₺',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _draft.maxPrice ?? 250,
                      min: 10,
                      max: 250,
                      divisions: 24,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() {
                        _draft = v >= 250
                            ? _draft.copyWith(clearMaxPrice: true)
                            : _draft.copyWith(maxPrice: v);
                      }),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // ---- Siralama
                  const _SectionLabel('Sıralama'),
                  Column(
                    children: OfferSort.values.map((s) {
                      return _RadioRow(
                        label: s.label,
                        selected: _draft.sort == s,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(sort: s),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ---- Mesafe
                  const _SectionLabel('Arama yarıçapı'),
                  Row(
                    children: [
                      Text(
                        'Yakınımdaki',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(_draft.radiusMeters / 1000).toStringAsFixed(0)} km',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _draft.radiusMeters.toDouble(),
                    min: 1000,
                    max: 50000,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(radiusMeters: v.round()),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Uygula
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: Text(
                    _draft.isDefault
                        ? 'Uygula'
                        : 'Uygula (${_draft.activeCount} filtre)',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: active ? color : theme.colorScheme.outline,
            width: active ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}