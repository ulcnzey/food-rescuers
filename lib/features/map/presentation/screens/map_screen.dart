import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../../offers/presentation/screens/offer_detail_screen.dart';
import '../../../offers/presentation/widgets/food_type_style.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();

  FoodType? _selected;
  Offer? _highlighted;

  /// Harita ilk veri geldiginde bir kez kullanicinin konumuna gider.
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

  void _goToMyLocation(double lat, double lng) {
    setState(() => _highlighted = null);
    _mapController.move(LatLng(lat, lng), 15);
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider).location;

    if (location == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Konum alınıyor...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final query = NearbyQuery(
      latitude: location.latitude,
      longitude: location.longitude,
      radiusMeters: 20000,
      foodType: _selected,
    );

    final offersAsync = ref.watch(nearbyOffersProvider(query));
    final offers = offersAsync.valueOrNull ?? [];

    // Ilk veri geldiginde haritayi kullanicinin konumuna hizala.
    if (!_centeredOnce && offersAsync.hasValue) {
      _centeredOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(location.latitude, location.longitude),
          14,
        );
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(location.latitude, location.longitude),
              initialZoom: 14,
              minZoom: 4,
              maxZoom: 18,
              onTap: (_, _) => setState(() => _highlighted = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodrescuers.food_rescuers',
                maxZoom: 19,
              ),

              // Kullanici konumu
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(location.latitude, location.longitude),
                    radius: 10,
                    color: AppColors.info.withValues(alpha: 0.9),
                    borderColor: Colors.white,
                    borderStrokeWidth: 3,
                  ),
                  CircleMarker(
                    point: LatLng(location.latitude, location.longitude),
                    radius: 700,
                    useRadiusInMeter: true,
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderColor: AppColors.info.withValues(alpha: 0.25),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),

              // Ilan pinleri. Yakin olanlar otomatik kumelenir;
              // yogun bolgelerde harita okunabilir kaliyor.
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
                          width: 46,
                          height: 54,
                          child: _OfferPin(
                            offer: o,
                            selected: _highlighted?.id == o.id,
                            onTap: () => _focusOn(o),
                          ),
                        ),
                      )
                      .toList(),
                  builder: (context, markers) => _ClusterBubble(
                    count: markers.length,
                  ),
                ),
              ),

              // OSM atifi (lisans geregi zorunlu)
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap katkıcıları'),
                ],
              ),
            ],
          ),

          // ---- Ust: kategori filtreleri
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    children: [
                      _FilterChip(
                        label: 'Tümü',
                        icon: Icons.apps_rounded,
                        active: _selected == null,
                        onTap: () => setState(() {
                          _selected = null;
                          _highlighted = null;
                        }),
                      ),
                      ...FoodType.values.map((t) {
                        final s = FoodTypeStyle.of(t);
                        return _FilterChip(
                          label: s.label,
                          icon: s.icon,
                          active: _selected == t,
                          onTap: () => setState(() {
                            _selected = _selected == t ? null : t;
                            _highlighted = null;
                          }),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---- Sag: konumuma git
          Positioned(
            right: AppSpacing.md,
            bottom: _highlighted != null ? 210 : 100,
            child: SafeArea(
              child: Column(
                children: [
                  _MapButton(
                    icon: Icons.my_location_rounded,
                    onTap: () => _goToMyLocation(
                      location.latitude,
                      location.longitude,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MapButton(
                    icon: Icons.add_rounded,
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _MapButton(
                    icon: Icons.remove_rounded,
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Alt: ilan sayisi veya secili ilan karti
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _highlighted != null
                    ? Padding(
                        key: ValueKey(_highlighted!.id),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: _MapOfferCard(
                          offer: _highlighted!,
                          onClose: () => setState(() => _highlighted = null),
                          onTap: () {
                            Navigator.of(context).push(
                              SmoothPageRoute<void>(
                                page: OfferDetailScreen(
                                  offerId: _highlighted!.id,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Padding(
                        key: const ValueKey('count'),
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: Center(
                          child: _CountPill(
                            count: offers.length,
                            isLoading: offersAsync.isLoading,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- PARCALAR

/// Haritadaki tek ilan pini. Fiyat etiketi tasir.
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                offer.isFree
                    ? 'Ücretsiz'
                    : '${offer.price.toStringAsFixed(0)}₺',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Pinin ucu
            Container(width: 2.5, height: 8, color: color),
          ],
        ),
      ),
    );
  }
}

/// Kumelenmis pinlerin sayisini gosteren balon.
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: active ? Colors.white : Colors.black87,
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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.isLoading});

  final int count;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.place_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isLoading
                ? 'Yükleniyor...'
                : (count == 0
                    ? 'Bu bölgede ilan yok'
                    : '$count ilan bulundu'),
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Pine basilinca alttan cikan ozet kart.
class _MapOfferCard extends StatelessWidget {
  const _MapOfferCard({
    required this.offer,
    required this.onTap,
    required this.onClose,
  });

  final Offer offer;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = FoodTypeStyle.of(offer.foodType);

    return BouncyTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: offer.imageUrl != null
                      ? Image.network(
                          offer.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallback(style),
                        )
                      : _fallback(style),
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
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
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
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          offer.distanceLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          offer.timeLeftLabel,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(FoodTypeStyle style) => DecoratedBox(
        decoration: BoxDecoration(color: style.color.withValues(alpha: 0.15)),
        child: Center(child: Icon(style.icon, size: 30, color: style.color)),
      );
}