import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/walking_time.dart';
import '../../../favorites/presentation/controllers/favorite_controller.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/entities/offer_filter.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../../offers/presentation/screens/offer_detail_screen.dart';
import '../../../offers/presentation/widgets/food_type_style.dart';
import '../widgets/filter_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  Offer? _highlighted;
  bool _centeredOnce = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _focusOn(Offer offer) {
    if (offer.latitude == null || offer.longitude == null) return;

    setState(() => _highlighted = offer);
    _mapController.move(LatLng(offer.latitude!, offer.longitude!), 16);
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider).location;
    final filter = ref.watch(offerFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          const _MapTopBar(),

          Expanded(
            child: location == null
                ? const _LocationLoading()
                : _MapBody(
                    mapController: _mapController,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    filter: filter,
                    highlighted: _highlighted,
                    onFocus: _focusOn,
                    onClearHighlight: () =>
                        setState(() => _highlighted = null),
                    centeredOnce: _centeredOnce,
                    onCentered: () => _centeredOnce = true,
                  ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ UST BASLIK

class _MapTopBar extends ConsumerWidget {
  const _MapTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final filter = ref.watch(offerFilterProvider);

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
                        text: TextSpan(
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

              // ---- Filtre cubugu
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterPill(
                      icon: Icons.tune_rounded,
                      label: filter.activeCount > 0
                          ? 'Filtre (${filter.activeCount})'
                          : 'Filtre',
                      active: filter.activeCount > 0,
                      onTap: () => showFilterSheet(context),
                    ),
                    _FilterPill(
                      label: filter.foodType == null
                          ? 'Kategori'
                          : FoodTypeStyle.of(filter.foodType!).label,
                      active: filter.foodType != null,
                      hasArrow: true,
                      onTap: () => showFilterSheet(context),
                    ),
                    _FilterPill(
                      label: filter.pickupWindow == PickupWindow.any
                          ? 'Alım saati'
                          : filter.pickupWindow.label,
                      active: filter.pickupWindow != PickupWindow.any,
                      hasArrow: true,
                      onTap: () => showFilterSheet(context),
                    ),
                    _FilterPill(
                      label: 'Ücretsiz',
                      active: filter.freeOnly,
                      onTap: () {
                        final f = ref.read(offerFilterProvider);
                        ref.read(offerFilterProvider.notifier).state =
                            f.copyWith(freeOnly: !f.freeOnly);
                      },
                    ),
                    _FilterPill(
                      label: filter.sort == OfferSort.distance
                          ? 'Sırala'
                          : filter.sort.label,
                      active: filter.sort != OfferSort.distance,
                      hasArrow: true,
                      onTap: () => showFilterSheet(context),
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.hasArrow = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final bool hasArrow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: BouncyTap(
        onTap: onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: active ? AppColors.primary : Colors.white,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.primary : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasArrow) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: active ? AppColors.primary : Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ HARITA

class _MapBody extends ConsumerWidget {
  const _MapBody({
    required this.mapController,
    required this.latitude,
    required this.longitude,
    required this.filter,
    required this.highlighted,
    required this.onFocus,
    required this.onClearHighlight,
    required this.centeredOnce,
    required this.onCentered,
  });

  final MapController mapController;
  final double latitude;
  final double longitude;
  final OfferFilter filter;
  final Offer? highlighted;
  final ValueChanged<Offer> onFocus;
  final VoidCallback onClearHighlight;
  final bool centeredOnce;
  final VoidCallback onCentered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = NearbyQuery(
      latitude: latitude,
      longitude: longitude,
      filter: filter,
    );

    final offersAsync = ref.watch(nearbyOffersProvider(query));
    final offers = offersAsync.valueOrNull ?? [];

    if (!centeredOnce && offersAsync.hasValue) {
      onCentered();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(LatLng(latitude, longitude), 14);
      });
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: 14,
            minZoom: 4,
            maxZoom: 19,
            onTap: (_, _) => onClearHighlight(),
          ),
          children: [
            // Standart OSM karolari: binalar, yollar ve sokak
            // isimleri dahil tam detay gosterir.
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.foodrescuers.food_rescuers',
              maxZoom: 19,
            ),

            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(latitude, longitude),
                  radius: filter.radiusMeters.toDouble(),
                  useRadiusInMeter: true,
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderColor: AppColors.primary.withValues(alpha: 0.20),
                  borderStrokeWidth: 1.5,
                ),
                CircleMarker(
                  point: LatLng(latitude, longitude),
                  radius: 9,
                  color: AppColors.info,
                  borderColor: Colors.white,
                  borderStrokeWidth: 3,
                ),
              ],
            ),

            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 55,
                size: const Size(46, 46),
                padding: const EdgeInsets.all(50),
                markers: offers
                    .where((o) => o.latitude != null && o.longitude != null)
                    .map(
                      (o) => Marker(
                        point: LatLng(o.latitude!, o.longitude!),
                        width: 58,
                        height: 58,
                        child: _OfferPin(
                          offer: o,
                          selected: highlighted?.id == o.id,
                          onTap: () => onFocus(o),
                        ),
                      ),
                    )
                    .toList(),
                builder: (context, markers) =>
                    _ClusterBubble(count: markers.length),
              ),
            ),

            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap katkıcıları'),
              ],
            ),
          ],
        ),

        // ---- Sag alt: harita kontrolleri
        Positioned(
          right: AppSpacing.md,
          bottom: highlighted != null ? 200 : 80,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.my_location_rounded,
                onTap: () {
                  onClearHighlight();
                  mapController.move(LatLng(latitude, longitude), 15);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ZoomButton(
                      icon: Icons.add_rounded,
                      onTap: () => mapController.move(
                        mapController.camera.center,
                        mapController.camera.zoom + 1,
                      ),
                    ),
                    Container(width: 26, height: 1, color: Colors.black12),
                    _ZoomButton(
                      icon: Icons.remove_rounded,
                      onTap: () => mapController.move(
                        mapController.camera.center,
                        mapController.camera.zoom - 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ---- Alt: sonuc bilgisi veya secili ilan
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: highlighted != null
                ? Padding(
                    key: ValueKey(highlighted!.id),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _MapOfferCard(
                      offer: highlighted!,
                      onClose: onClearHighlight,
                      onTap: () {
                        Navigator.of(context).push(
                          SmoothPageRoute<void>(
                            page: OfferDetailScreen(offerId: highlighted!.id),
                          ),
                        );
                      },
                    ),
                  )
                : Padding(
                    key: const ValueKey('info'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Center(
                      child: _CountPill(
                        count: offers.length,
                        isLoading: offersAsync.isLoading,
                        hasFilter: filter.activeCount > 0,
                        onClearFilter: () => ref
                            .read(offerFilterProvider.notifier)
                            .state = const OfferFilter(),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _LocationLoading extends StatelessWidget {
  const _LocationLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text('Konum alınıyor...', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ================================================================ PARCALAR

/// Haritadaki ilan pini. Logo ve fiyat etiketi tasir.
class _OfferPin extends StatelessWidget {
  const _OfferPin({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final Offer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = offer.isFree ? AppColors.freeBadge : AppColors.primary;
    final style = FoodTypeStyle.of(offer.foodType);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo balonu
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: offer.businessLogo != null
                  ? Image.network(
                      offer.businessLogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(style.icon, size: 18, color: color),
                    )
                  : Icon(style.icon, size: 18, color: color),
            ),
            // Fiyat etiketi
            Transform.translate(
              offset: const Offset(0, -4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  offer.isFree
                      ? 'Free'
                      : '${offer.price.toStringAsFixed(0)}₺',
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
    );
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(11),
          child: Icon(
            Icons.my_location_rounded,
            size: 22,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(icon, size: 21, color: AppColors.primary),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.count,
    required this.isLoading,
    required this.hasFilter,
    required this.onClearFilter,
  });

  final int count;
  final bool isLoading;
  final bool hasFilter;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = count == 0 && !isLoading;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              height: 15,
              width: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              empty ? Icons.search_off_rounded : Icons.place_rounded,
              size: 19,
              color: empty
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.primary,
            ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              isLoading
                  ? 'Yükleniyor...'
                  : (empty
                      ? 'Bu bölgede ilan yok'
                      : '$count ilan bulundu'),
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (empty && hasFilter) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onClearFilter,
              child: Text(
                'Filtreyi temizle',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pine basilinca alttan cikan premium ozet kart.
class _MapOfferCard extends ConsumerWidget {
  const _MapOfferCard({
    required this.offer,
    required this.onTap,
    required this.onClose,
  });

  final Offer offer;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = FoodTypeStyle.of(offer.foodType);
    final isFavorite =
        ref.watch(favoriteIdsProvider).contains(offer.businessId);

    return BouncyTap(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Gorsel
                  SizedBox(
                    width: 82,
                    height: 82,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          child: offer.imageUrl != null
                              ? Image.network(
                                  offer.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _fallback(style),
                                )
                              : _fallback(style),
                        ),
                        if (offer.isFree || offer.discountPercent > 0)
                          Positioned(
                            left: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: offer.isFree
                                    ? AppColors.freeBadge
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                offer.isFree
                                    ? 'FREE'
                                    : '%${offer.discountPercent}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
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
                                offer.businessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            BouncyTap(
                              scale: 0.85,
                              onTap: () => ref
                                  .read(favoriteIdsProvider.notifier)
                                  .toggle(offer.businessId),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 20,
                                color: isFavorite
                                    ? AppColors.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: onClose,
                              child: Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offer.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Meta(
                              icon: Icons.directions_walk_rounded,
                              text: WalkingTime.isWalkable(offer.distanceKm)
                                  ? WalkingTime.label(offer.distanceKm)
                                  : offer.distanceLabel,
                            ),
                            const SizedBox(width: 10),
                            _Meta(
                              icon: Icons.schedule_rounded,
                              text: offer.pickupWindowLabel,
                            ),
                            const Spacer(),
                            if (offer.isFree)
                              Text(
                                'Ücretsiz',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.freeBadge,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (offer.originalPrice > 0) ...[
                                    Text(
                                      '${offer.originalPrice.toStringAsFixed(0)}₺',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        decoration:
                                            TextDecoration.lineThrough,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    '${offer.price.toStringAsFixed(0)}₺',
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Alt seritte kalan sure
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${offer.timeLeftLabel} içinde al · ${offer.quantityAvailable} adet kaldı',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(FoodTypeStyle style) => DecoratedBox(
        decoration: BoxDecoration(color: style.color.withValues(alpha: 0.15)),
        child: Center(child: Icon(style.icon, size: 32, color: style.color)),
      );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}