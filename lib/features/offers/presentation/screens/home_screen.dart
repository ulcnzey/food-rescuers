import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../favorites/presentation/controllers/favorite_controller.dart';
import '../../../reservations/presentation/controllers/reservation_controller.dart';
import '../../domain/entities/offer.dart';
import '../controllers/offer_controller.dart';
import '../widgets/food_type_style.dart';
import '../widgets/offer_card.dart';
import 'offer_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  FoodType? _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Ilk acilista konumu cozumle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationControllerProvider.notifier).resolveCurrent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = ref.watch(locationControllerProvider);
    final impact = ref.watch(myImpactProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(locationControllerProvider.notifier)
                .resolveCurrent();
            ref.invalidate(myImpactProvider);
            await ref.read(favoriteIdsProvider.notifier).load();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  locationLabel: locationState.location?.label,
                  isLoading: locationState.isLoading,
                  onTapLocation: () => ref
                      .read(locationControllerProvider.notifier)
                      .resolveCurrent(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              SliverToBoxAdapter(
                child: _ImpactCard(
                  meals: impact.valueOrNull?.savedMeals ?? 0,
                  co2: impact.valueOrNull?.co2Kg ?? 0,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              SliverToBoxAdapter(
                child: _SearchBar(
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              SliverToBoxAdapter(
                child: _Categories(
                  selected: _selected,
                  onChanged: (v) => setState(() => _selected = v),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // ---- Icerik: konum durumuna gore dallanir
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
                  search: _search,
                  theme: theme,
                  onClearFilters: () => setState(() {
                    _selected = null;
                    _search = '';
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- LISTE

class _OfferSection extends ConsumerWidget {
  const _OfferSection({
    required this.latitude,
    required this.longitude,
    required this.foodType,
    required this.search,
    required this.theme,
    required this.onClearFilters,
  });

  final double latitude;
  final double longitude;
  final FoodType? foodType;
  final String search;
  final ThemeData theme;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = NearbyQuery(
      latitude: latitude,
      longitude: longitude,
      foodType: foodType,
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

      data: (all) {
        // Arama istemci tarafinda: liste zaten kucuk ve
        // her tusa basista sunucuya gitmek gereksiz.
        final visible = search.trim().isEmpty
            ? all
            : all.where((o) {
                final q = search.toLowerCase().trim();
                return o.title.toLowerCase().contains(q) ||
                    o.businessName.toLowerCase().contains(q);
              }).toList();

        if (visible.isEmpty) {
          final filtered = foodType != null || search.trim().isNotEmpty;

          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              art: filtered ? EmptyStateArt.noResults : EmptyStateArt.basket,
              title:
                  filtered ? 'Sonuç bulunamadı' : 'Yakınında henüz ilan yok',
              message: filtered
                  ? 'Farklı bir kategori veya arama deneyebilirsin.'
                  : 'Bölgende ilan yayınlandığında burada göreceksin. '
                      'Sen de işletmenle katılabilirsin.',
              actionLabel: filtered ? 'Filtreleri Temizle' : null,
              onAction: filtered ? onClearFilters : null,
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
                      'Yakınındaki fırsatlar',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${visible.length} ilan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
                itemCount: visible.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) {
                  final offer = visible[i];

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

/// Yukleme sirasinda kartlarin yerini tutan iskelet.
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
                  height: 140,
                  radius: AppSpacing.radiusXl,
                ),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(width: 160, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 220, height: 18),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- PARCALAR

class _Header extends StatelessWidget {
  const _Header({
    required this.locationLabel,
    required this.isLoading,
    required this.onTapLocation,
  });

  final String? locationLabel;
  final bool isLoading;
  final VoidCallback onTapLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: BouncyTap(
              onTap: onTapLocation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konumun',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          isLoading
                              ? 'Konum alınıyor...'
                              : (locationLabel ?? 'Konum seç'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.meals, required this.co2});

  final int meals;
  final double co2;

  @override
  Widget build(BuildContext context) {
    final hasImpact = meals > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImpact)
                    Row(
                      children: [
                        CounterText(
                          value: meals.toDouble(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          ' öğün kurtardın',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'İlk öğününü kurtarmaya hazır mısın?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    hasImpact
                        ? 'Yaklaşık ${co2.toStringAsFixed(1)} kg CO₂ önlendi'
                        : 'Yakınındaki fırsatlara göz at',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'İşletme veya ürün ara...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.selected, required this.onChanged});

  final FoodType? selected;
  final ValueChanged<FoodType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _Chip(
            label: 'Tümü',
            icon: Icons.apps_rounded,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          ...FoodType.values.map((t) {
            final s = FoodTypeStyle.of(t);
            return _Chip(
              label: s.label,
              icon: s.icon,
              active: selected == t,
              onTap: () => onChanged(selected == t ? null : t),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: BouncyTap(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: active ? AppColors.primary : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    active ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: active ? Colors.white : theme.colorScheme.onSurface,
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