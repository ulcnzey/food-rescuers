import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/static_page.dart';
import '../controllers/settings_controller.dart';
import '../../../../core/illustrations/empty_basket_illustration.dart';

enum ImpactKind { money, co2 }

class ImpactDetailScreen extends ConsumerWidget {
  const ImpactDetailScreen({super.key, required this.kind});

  final ImpactKind kind;

  bool get _isMoney => kind == ImpactKind.money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(monthlyImpactProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isMoney ? 'Tasarrufun' : 'Önlenen CO₂'),
        actions: [
          if (!_isMoney)
            IconButton(
              onPressed: () => _showMethodology(context),
              icon: const Icon(Icons.info_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => const Center(child: Text('Veri yüklenemedi')),

          data: (months) {
            if (months.isEmpty) {
              return _EmptyImpact(isMoney: _isMoney);
            }

            final total = _isMoney
                ? months.fold<double>(0, (a, m) => a + m.moneySaved)
                : months.fold<double>(0, (a, m) => a + m.co2Kg);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      ...months.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: FadeSlideIn(
                                index: e.key,
                                child: _MonthCard(
                                  item: e.value,
                                  isMoney: _isMoney,
                                ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // ---- Toplam seridi
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.outline),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Icon(
                          _isMoney
                              ? Icons.savings_outlined
                              : Icons.eco_rounded,
                          color: _isMoney
                              ? AppColors.secondary
                              : AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _isMoney ? 'Toplam tasarruf' : 'Toplam önlenen',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        CounterText(
                          value: total,
                          decimals: _isMoney ? 0 : 1,
                          suffix: _isMoney ? ' ₺' : ' kg',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: _isMoney
                                ? AppColors.secondary
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMethodology(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nasıl hesaplıyoruz?',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Kurtarılan her öğünü ortalama 0,7 kg gıda olarak kabul '
                'ediyoruz. FAO\'nun gıda israfı ayak izi raporuna göre '
                '1 kg gıdanın üretim ve tedarik zinciri boyunca yaklaşık '
                '2,5 kg CO₂ eşdeğeri salım oluşturuyor.\n\n'
                'Bu iki katsayıyı çarparak önlenen salımı hesaplıyoruz. '
                'Değerler tahminidir; ürün türüne göre gerçek etki '
                'farklılık gösterebilir.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Anladım'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- PARCALAR

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.item, required this.isMoney});

  final MonthlyImpact item;
  final bool isMoney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: theme.colorScheme.surface,
            child: Text(
              item.monthLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _Row(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Kurtarılan öğün',
                  value: '${item.mealsSaved}',
                ),
                if (isMoney) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Row(
                    icon: Icons.sell_outlined,
                    label: 'Normal değeri',
                    value: '${item.originalValue.toStringAsFixed(0)} ₺',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Row(
                    icon: Icons.payments_outlined,
                    label: 'Ödediğin',
                    value: '${item.paidValue.toStringAsFixed(0)} ₺',
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
                  _Row(
                    icon: Icons.scale_outlined,
                    label: 'Kurtarılan gıda',
                    value: '${(item.mealsSaved * 0.7).toStringAsFixed(1)} kg',
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outline),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(
                  isMoney ? 'Tasarruf' : 'Önlenen CO₂',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  isMoney
                      ? '${item.moneySaved.toStringAsFixed(0)} ₺'
                      : '${item.co2Kg.toStringAsFixed(1)} kg',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color:
                        isMoney ? AppColors.secondary : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 17,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EmptyImpact extends StatelessWidget {
  const _EmptyImpact({required this.isMoney});

  final bool isMoney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 180,
              height: 180,
              child: EmptyBasketIllustration(size: 180),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Burası biraz boş görünüyor',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isMoney
                  ? 'İlk siparişini tamamladığında tasarrufun burada görünecek.'
                  : 'İlk siparişini tamamladığında çevresel etkin burada görünecek.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}