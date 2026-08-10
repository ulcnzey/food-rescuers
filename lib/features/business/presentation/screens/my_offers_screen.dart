import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../../offers/presentation/screens/create_offer_screen.dart';
import '../../../offers/presentation/widgets/food_type_style.dart';

class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(myOffersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('İlanlarım')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateOfferScreen()),
          );
          ref.invalidate(myOffersProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni İlan'),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => EmptyState(
            art: EmptyStateArt.noResults,
            title: 'İlanlar yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
            actionLabel: 'Tekrar Dene',
            onAction: () => ref.invalidate(myOffersProvider),
          ),

          data: (all) {
            if (all.isEmpty) {
              return EmptyState(
                title: 'Henüz ilan vermedin',
                message: 'Gün sonu kalan ürünlerini listele, '
                    'israfı önlemeye başla.',
                actionLabel: 'İlk İlanını Ver',
                onAction: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateOfferScreen(),
                    ),
                  );
                  ref.invalidate(myOffersProvider);
                },
              );
            }

            final active = all.where((o) => o.isActive).toList();
            final past = all.where((o) => !o.isActive).toList();

            // Ozet: toplam satilan ve kurtarilan ogun sayisi.
            final totalSold = all.fold<int>(0, (s, o) => s + o.soldCount);

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myOffersProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  100,
                ),
                children: [
                  _SummaryBar(
                    activeCount: active.length,
                    totalCount: all.length,
                    soldCount: totalSold,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (active.isNotEmpty) ...[
                    _SectionTitle(
                      title: 'Yayında',
                      count: active.length,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...active.asMap().entries.map(
                          (e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: FadeSlideIn(
                              index: e.key,
                              child: _OfferTile(offer: e.value, isActive: true),
                            ),
                          ),
                        ),
                  ],

                  if (past.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SectionTitle(
                      title: 'Geçmiş',
                      count: past.length,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...past.asMap().entries.map(
                          (e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: FadeSlideIn(
                              index: active.length + e.key,
                              child:
                                  _OfferTile(offer: e.value, isActive: false),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- PARCALAR

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.activeCount,
    required this.totalCount,
    required this.soldCount,
  });

  final int activeCount;
  final int totalCount;
  final int soldCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(value: activeCount, label: 'Yayında'),
          ),
          const _Divider(),
          Expanded(
            child: _SummaryItem(value: totalCount, label: 'Toplam ilan'),
          ),
          const _Divider(),
          Expanded(
            child: _SummaryItem(value: soldCount, label: 'Kurtarılan'),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CounterText(
          value: value.toDouble(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(width: 4, height: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Text(
          '($count)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OfferTile extends ConsumerWidget {
  const _OfferTile({required this.offer, required this.isActive});

  final Offer offer;
  final bool isActive;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
        title: const Text('İlanı kaldır'),
        content: Text(
          offer.reservedCount > 0
              ? '${offer.reservedCount} kişi bu ilanı rezerve etmiş. '
                  'Kaldırırsan rezervasyonları da iptal olacak.'
              : 'Bu ilan yayından kaldırılacak. Emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok =
        await ref.read(offerControllerProvider.notifier).cancelOffer(offer.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'İlan kaldırıldı' : 'İlan kaldırılamadı'),
        backgroundColor: ok ? null : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = FoodTypeStyle.of(offer.foodType);

    final statusColor = switch (offer.status) {
      OfferStatus.active => AppColors.primary,
      OfferStatus.soldOut => AppColors.success,
      OfferStatus.cancelled => AppColors.error,
      OfferStatus.expired => theme.colorScheme.onSurfaceVariant,
    };

    final ratio =
        offer.quantityTotal == 0 ? 0.0 : offer.soldCount / offer.quantityTotal;

    return Opacity(
      opacity: isActive ? 1 : 0.72,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gorsel
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: offer.imageUrl != null
                          ? Image.network(
                              offer.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _iconBox(style),
                            )
                          : _iconBox(style),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                offer.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                              child: Text(
                                offer.status.displayName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${offer.dateLabel} ${offer.pickupWindowLabel}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Text(
                              offer.isFree
                                  ? 'Ücretsiz'
                                  : '${offer.price.toStringAsFixed(0)}₺',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: offer.isFree
                                    ? AppColors.freeBadge
                                    : AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Satis ilerlemesi
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: ratio),
                                  duration:
                                      const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, v, _) =>
                                      LinearProgressIndicator(
                                    value: v,
                                    minHeight: 6,
                                    backgroundColor:
                                        theme.colorScheme.outline,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${offer.soldCount}/${offer.quantityTotal}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isActive) ...[
              Divider(height: 1, color: theme.colorScheme.outline),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _cancel(context, ref),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Kaldır'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconBox(FoodTypeStyle style) {
    return DecoratedBox(
      decoration: BoxDecoration(color: style.color.withValues(alpha: 0.15)),
      child: Center(child: Icon(style.icon, size: 26, color: style.color)),
    );
  }
}