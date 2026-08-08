import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/providers/location_providers.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';


/// Secilen konum ve cozumlenen adres.
class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _mapController = MapController();
  final _geocoding = const GeocodingService();

  /// Baslangic: Turkiye merkezi. Konum alininca guncellenir.
  LatLng _center = const LatLng(39.0, 35.0);
  bool _hasLocation = false;

  String? _address;
  bool _addressLoading = false;
  bool _gpsLoading = false;
  String? _error;

  /// Nominatim'e cok sik istek atmamak icin son sorgu zamani.
  DateTime _lastGeocodeAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();

    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
      _hasLocation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAddress());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation());
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _gpsLoading = true;
      _error = null;
    });

    final result = await ref.read(locationServiceProvider).getCurrentLocation();

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _gpsLoading = false;
        _error = result.error;
      });
      return;
    }

    setState(() {
      _center = LatLng(result.latitude!, result.longitude!);
      _hasLocation = true;
      _gpsLoading = false;
    });

    _mapController.move(_center, 17);
    await _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    // Nominatim politikasi: saniyede 1 istekten fazlasi yasak.
    final elapsed = DateTime.now().difference(_lastGeocodeAt);
    if (elapsed < const Duration(milliseconds: 1200)) {
      await Future<void>.delayed(
        const Duration(milliseconds: 1200) - elapsed,
      );
    }
    _lastGeocodeAt = DateTime.now();

    if (!mounted) return;
    setState(() => _addressLoading = true);

    final result = await _geocoding.reverseGeocode(
      _center.latitude,
      _center.longitude,
    );

    if (!mounted) return;

    setState(() {
      _addressLoading = false;
      _address = result ?? 'Adres çözümlenemedi';
    });
  }

  void _confirm() {
    Navigator.of(context).pop(
      PickedLocation(
        latitude: _center.latitude,
        longitude: _center.longitude,
        address: _address ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _hasLocation ? 17 : 5.5,
              minZoom: 3,
              maxZoom: 19,
              // Harita hareket ederken pin sabit kalir, merkez degisir.
              onPositionChanged: (position, hasGesture) {
                if (!hasGesture) return;
                _center = position.center;
                _hasLocation = true;
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _resolveAddress();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodrescuers.food_rescuers',
                maxZoom: 19,
              ),
            ],
          ),

          // Sabit merkez pin
          IgnorePointer(
            child: Center(
              child: Padding(
                // Pinin ucu tam merkeze denk gelsin.
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 14,
                      color: AppColors.primary,
                    ),
                    Container(
                      width: 10,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // OSM atifi (lisans geregi zorunlu)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white70,
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          ),

          // Konumuma git
          Positioned(
            right: AppSpacing.md,
            bottom: 190,
            child: FloatingActionButton.small(
              heroTag: 'gps',
              onPressed: _gpsLoading ? null : _useMyLocation,
              backgroundColor: theme.colorScheme.surface,
              child: _gpsLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                    ),
            ),
          ),

          // Alt panel: adres + onay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Seçilen Konum',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (_addressLoading)
                    Row(
                      children: [
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Adres çözümleniyor...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _address ?? 'Haritayı hareket ettirerek konum seçin',
                      style: theme.textTheme.bodyMedium,
                    ),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Pin işletmenin tam girişinde olmalı. Haritayı '
                    'kaydırarak ayarlayabilirsin.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  FilledButton(
                    onPressed: (!_hasLocation || _addressLoading)
                        ? null
                        : _confirm,
                    child: const Text('Bu Konumu Kullan'),
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