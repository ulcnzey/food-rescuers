import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/favorite_business.dart';
import '../controllers/favorite_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key, this.onDiscover});

  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFavoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => EmptyState(
            art: EmptyStateArt.noResults,
            title: 'Favoriler yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
            actionLabel: 'Tekrar Dene',
            onAction: () => ref.invalidate(myFavoritesProvider),
          ),

          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                art: EmptyStateArt.storefront,
                title: 'Henüz favorin yok',
                message: 'Beğendiğin işletmelerin kalp simgesine dokun, '
                    'yeni ilanlarını kolayca takip et.',
                actionLabel: 'İşletmeleri Keşfet',
                onAction: onDiscover,
              );
            }

            final withOffers = list.where((f) => f.hasActiveOffers).toList();
            final without = list.where((f) => !f.hasActiveOffers).toList();

            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(favoriteIdsProvider.notifier).load();
                ref.invalidate(myFavoritesProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (withOffers.isNotEmpty) ...[
                    _SectionTitle(
                      title: 'Şu an ilan veriyor',
                      count: withOffers.length,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...withOffers.asMap().entries.map(
                          (e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: FadeSlideIn(
                              index: e.key,
                              child: _FavoriteTile(item: e.value),
                            ),
                          ),
                        ),
                  ],

                  if (without.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SectionTitle(
                      title: 'Takip ettiklerin',
                      count: without.length,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...without.asMap().entries.map(
                          (e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: FadeSlideIn(
                              index: withOffers.length + e.key,
                              child: _FavoriteTile(item: e.value),
                            ),
                          ),
                        ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
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

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.item});

  final FavoriteBusiness item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent =
        item.isIndividual ? AppColors.success : AppColors.secondary;

    return Opacity(
      opacity: item.hasActiveOffers ? 1 : 0.7,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: item.hasActiveOffers
                ? AppColors.primary.withValues(alpha: 0.35)
                : theme.colorScheme.outline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.logoUrl != null
                  ? Image.network(
                      item.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _icon(accent),
                    )
                  : _icon(accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (item.hasActiveOffers)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (item.hasActiveOffers) const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.offerLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: item.hasActiveOffers
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: item.hasActiveOffers
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.ratingCount > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item.ratingAvg.toStringAsFixed(1)} (${item.ratingCount})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            BouncyTap(
              scale: 0.85,
              onTap: () => ref
                  .read(favoriteIdsProvider.notifier)
                  .toggle(item.businessId),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(Color accent) => Icon(
        item.isIndividual
            ? Icons.volunteer_activism_rounded
            : Icons.storefront_rounded,
        color: accent,
        size: 24,
      );
}