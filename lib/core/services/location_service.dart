import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({this.latitude, this.longitude, this.error});

  final double? latitude;
  final double? longitude;
  final String? error;

  bool get isSuccess => latitude != null && longitude != null;
}

/// Cihazin konumunu alir. Izin ve servis durumlarini
/// anlasilir Turkce mesajlarla bildirir.
class LocationService {
  const LocationService();

  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        error: 'Konum servisi kapalı. Lütfen telefonunuzun konumunu açın.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult(
        error: 'Konum izni verilmedi. İşletme konumunuzu kaydedebilmemiz için '
            'izin gerekiyor.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        error: 'Konum izni kalıcı olarak reddedilmiş. Ayarlar > Uygulamalar '
            'bölümünden izin verebilirsiniz.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationResult(
        error: 'Konum alınamadı. Açık alanda tekrar deneyin.',
      );
    }
  }
}