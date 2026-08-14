import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../favorites/presentation/controllers/favorite_controller.dart';
import '../../../home/domain/entities/banner_item.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../home/presentation/widgets/location_sheet.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../domain/entities/offer.dart';
import '../controllers/offer_controller.dart';
import '../widgets/food_type_style.dart';
import '../widgets/offer_card.dart';
import 'offer_detail_screen.dart';
import '../../domain/entities/offer_filter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  FoodType? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationControllerProvider.notifier).resolveCurrent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = ref.watch(locationControllerProvider);

    return Scaffold(
      body: Column(
        children: [
          // ---- Yesil ust baslik (sabit)
          _TopBar(
            locationLabel: locationState.location?.label,
            isLoadingLocation: locationState.isLoading,
          ),

          // ---- Kaydirilabilir icerik
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(locationControllerProvider.notifier)
                    .resolveCurrent();
                ref.invalidate(bannersProvider);
                await ref.read(favoriteIdsProvider.notifier).load();
              },
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),

                  // ---- Reklam karuseli
                  const SliverToBoxAdapter(child: _BannerCarousel()),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),

                  // ---- Sektor sekmeleri
                  SliverToBoxAdapter(
                    child: _CategoryTabs(
                      selected: _selected,
                      onChanged: (v) => setState(() => _selected = v),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),

                  // ---- Ilan listesi
                  if (locationState.error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        art: EmptyStateArt.noResults,
                        title: 'Konum alınamadı',
                        message: locationState.error!,
                        actionLabel: 'Tekrar Dene',
                        onAction: () => ref
                            .read(locationControllerProvider.notifier)
                            .resolveCurrent(),
                      ),
                    )
                  else if (!locationState.hasLocation)
                    const SliverToBoxAdapter(child: _LoadingList())
                  else
                    _OfferSection(
                      latitude: locationState.location!.latitude,
                      longitude: locationState.location!.longitude,
                      foodType: _selected,
                      theme: theme,
                      onClearFilters: () => setState(() => _selected = null),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ UST BASLIK

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.locationLabel,
    required this.isLoadingLocation,
  });

  final String? locationLabel;
  final bool isLoadingLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
              // ---- Marka + bildirim
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

              const SizedBox(height: AppSpacing.sm),

              // ---- Konum secici
              BouncyTap(
                onTap: () => showLocationSheet(context, ref),
                scale: 0.98,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isLoadingLocation
                              ? 'Konum alınıyor...'
                              : (locationLabel ?? 'Konum seç'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ BANNER

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel();

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Bannerlar kendiliginden doner; kullanici etkilesimi
  /// oldugunda zamanlayici yeniden baslar.
  void _startAutoScroll(int count) {
    _timer?.cancel();
    if (count < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;

      final next = (_page + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bannersProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ShimmerBox(
          width: double.infinity,
          height: 120,
          radius: AppSpacing.radiusXl,
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_timer == null) _startAutoScroll(banners.length);
        });

        return Column(
          children: [
            SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _controller,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _BannerCard(item: banners[i]),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: _page == i ? 20 : 6,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.item});

  final BannerItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BouncyTap(
      onTap: () {},
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          color: item.bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: item.bgColor.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (item.imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

            // Dekoratif daireler
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -40,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================ SEKTORLER

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onChanged});

  final FoodType? selected;
  final ValueChanged<FoodType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _CategoryItem(
            label: 'Tümü',
            icon: Icons.apps_rounded,
            color: AppColors.primary,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          ...FoodType.values.map((t) {
            final s = FoodTypeStyle.of(t);
            return _CategoryItem(
              label: s.label,
              icon: s.icon,
              color: s.color,
              active: selected == t,
              onTap: () => onChanged(selected == t ? null : t),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
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

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: BouncyTap(
        onTap: onTap,
        scale: 0.92,
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: active ? color : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: active ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ LISTE

class _OfferSection extends ConsumerWidget {
  const _OfferSection({
    required this.latitude,
    required this.longitude,
    required this.foodType,
    required this.theme,
    required this.onClearFilters,
  });

  final double latitude;
  final double longitude;
  final FoodType? foodType;
  final ThemeData theme;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = NearbyQuery(
      latitude: latitude,
      longitude: longitude,
      filter: OfferFilter(foodType: foodType),
    );

    final offersAsync = ref.watch(nearbyOffersProvider(query));
    final favoriteIds = ref.watch(favoriteIdsProvider);

    return offersAsync.when(
      loading: () => const SliverToBoxAdapter(child: _LoadingList()),

      error: (_, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          art: EmptyStateArt.noResults,
          title: 'İlanlar yüklenemedi',
          message: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
          actionLabel: 'Tekrar Dene',
          onAction: () => ref.invalidate(nearbyOffersProvider(query)),
        ),
      ),

      data: (offers) {
        if (offers.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              art: foodType != null
                  ? EmptyStateArt.noResults
                  : EmptyStateArt.basket,
              title: foodType != null
                  ? 'Bu kategoride ilan yok'
                  : 'Yakınında henüz ilan yok',
              message: foodType != null
                  ? 'Farklı bir kategori deneyebilirsin.'
                  : 'Bölgende ilan yayınlandığında burada göreceksin.',
              actionLabel: foodType != null ? 'Tümünü Göster' : null,
              onAction: foodType != null ? onClearFilters : null,
            ),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      '${offers.length} İşletme Listelendi',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: offers.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) {
                  final offer = offers[i];

                  return FadeSlideIn(
                    key: ValueKey(offer.id),
                    index: i,
                    child: OfferCard(
                      offer: offer,
                      isFavorite: favoriteIds.contains(offer.businessId),
                      onFavoriteToggle: () => ref
                          .read(favoriteIdsProvider.notifier)
                          .toggle(offer.businessId),
                      onTap: () {
                        Navigator.of(context).push(
                          SmoothPageRoute<void>(
                            page: OfferDetailScreen(offerId: offer.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(
          3,
          (i) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: 150,
                  radius: AppSpacing.radiusXl,
                ),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(width: 180, height: 16),
                SizedBox(height: 8),
                ShimmerBox(width: 240, height: 13),
                SizedBox(height: 10),
                ShimmerBox(width: 140, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}