import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/geocoding_service.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return const GeocodingService();
});

/// Kullanicinin secili konumu. Ilk acilista GPS'ten alinir,
/// sonrasinda kayitli adreslerden veya haritadan degistirilebilir.
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.label,
    this.address,
    this.isSaved = false,
  });

  final double latitude;
  final double longitude;

  /// Gosterilecek ad: "Ev", "Is" veya cozumlenen semt.
  final String? label;

  /// Tam adres. Kayitli konumlarda alt satirda gosterilir.
  final String? address;

  /// Kayitli adreslerden mi secildi. Ikon secimini etkiler.
  final bool isSaved;
}

class LocationState {
  const LocationState({this.location, this.isLoading = false, this.error});

  final UserLocation? location;
  final bool isLoading;
  final String? error;

  bool get hasLocation => location != null;
}

class LocationController extends StateNotifier<LocationState> {
  LocationController(this._service, this._geocoding)
      : super(const LocationState());

  final LocationService _service;
  final GeocodingService _geocoding;

  /// GPS'ten mevcut konumu alir ve adres cozumler.
  Future<void> resolveCurrent() async {
    state = const LocationState(isLoading: true);

    final result = await _service.getCurrentLocation();

    if (!result.isSuccess) {
      state = LocationState(error: result.error);
      return;
    }

    // Once koordinati yaz, ekran hemen calissin.
    state = LocationState(
      location: UserLocation(
        latitude: result.latitude!,
        longitude: result.longitude!,
      ),
    );

    // Adres cozumleme arka planda; gecikirse kullanici beklemez.
    final address = await _geocoding.reverseGeocode(
      result.latitude!,
      result.longitude!,
    );

    if (!mounted) return;

    state = LocationState(
      location: UserLocation(
        latitude: result.latitude!,
        longitude: result.longitude!,
        label: _shortLabel(address),
        address: address,
      ),
    );
  }

  /// Haritadan secilen konum. Etiket cozumlenen adresten gelir.
  void setManual(double lat, double lng, String label) {
    state = LocationState(
      location: UserLocation(
        latitude: lat,
        longitude: lng,
        label: _shortLabel(label) ?? label,
        address: label,
      ),
    );
  }

  /// Kayitli adres secildiginde etiketi korur.
  /// GPS'ten gelen semt adi yerine kullanicinin verdigi ad gosterilir.
  void setSavedLocation({
    required double latitude,
    required double longitude,
    required String label,
    String? address,
  }) {
    state = LocationState(
      location: UserLocation(
        latitude: latitude,
        longitude: longitude,
        label: label,
        address: address,
        isSaved: true,
      ),
    );
  }

  /// "Cumhuriyet Mah., Merkez, Elazig" -> "Merkez, Elazig"
  static String? _shortLabel(String? full) {
    if (full == null || full.trim().isEmpty) return null;

    final parts = full.split(',').map((e) => e.trim()).toList();
    if (parts.length <= 2) return full;

    return parts.sublist(parts.length - 2).join(', ');
  }
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController(
    ref.watch(locationServiceProvider),
    ref.watch(geocodingServiceProvider),
  );
});