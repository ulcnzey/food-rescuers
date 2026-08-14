import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../reviews/presentation/screens/business_reviews_screen.dart';
import '../../../reviews/presentation/widgets/star_rating.dart';
import '../../domain/entities/favorite_business.dart';
import '../controllers/favorite_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key, this.onDiscover});

  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFavoritesProvider);

    return Scaffold(
      body: Column(
        children: [
          const _FavoritesTopBar(),

          Expanded(
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
                        'yeni ilanlarından haberdar ol.',
                    actionLabel: 'İşletmeleri Keşfet',
                    onAction: onDiscover,
                  );
                }

                final withOffers =
                    list.where((f) => f.hasActiveOffers).toList();
                final without = list.where((f) => !f.hasActiveOffers).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(favoriteIdsProvider.notifier).load();
                    ref.invalidate(myFavoritesProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Bildirim tercihi aciklamasi
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              size: 20,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Zil simgesi açıkken bu işletme yeni ilan '
                                'verdiğinde sana bildirim gelir.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      if (withOffers.isNotEmpty) ...[
                        _SectionTitle(
                          title: 'Şu an ilan veriyor',
                          count: withOffers.length,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...withOffers.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
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
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...without.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- UST BASLIK

class _FavoritesTopBar extends ConsumerWidget {
  const _FavoritesTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Food',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Rescuers',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              constraints: const BoxConstraints(minWidth: 18),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: AppColors.primaryDark,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Favorilerim',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
    final accent = item.isIndividual ? AppColors.success : AppColors.secondary;

    return Opacity(
      opacity: item.hasActiveOffers ? 1 : 0.75,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: item.hasActiveOffers
                ? AppColors.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outline,
          ),
        ),
        child: Column(
          children: [
            Row(
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (item.ratingCount > 0) ...[
                            const SizedBox(width: 6),
                            RatingBadge(
                              rating: item.ratingAvg,
                              count: item.ratingCount,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (item.hasActiveOffers) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
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
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---- Bildirim anahtari
                BouncyTap(
                  scale: 0.85,
                  onTap: () => ref
                      .read(favoriteNotifyControllerProvider)
                      .toggle(item.businessId),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.notify
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        item.notify
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined,
                        key: ValueKey(item.notify),
                        size: 19,
                        color: item.notify
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // ---- Favoriden cikar
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
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),

            // ---- Yorumlari gor
            if (item.ratingCount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: theme.colorScheme.outline),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    SmoothPageRoute<void>(
                      page: BusinessReviewsScreen(
                        businessId: item.businessId,
                        businessName: item.name,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.ratingCount} değerlendirmeyi gör',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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