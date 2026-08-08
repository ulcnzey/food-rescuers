import 'dart:convert';
import 'dart:io';

class GeocodingService {
  const GeocodingService();

  /// Koordinati okunabilir adrese cevirir (Nominatim / OpenStreetMap).
  /// Servis politikasi geregi User-Agent zorunlu, istek sikligi dusuk
  /// tutulmali. Basarisiz olursa null doner.
  Future<String?> reverseGeocode(double lat, double lng) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'format': 'jsonv2',
      'accept-language': 'tr',
      'zoom': '18',
    });

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'FoodRescuers/1.0 (portfolio project)');

      final response = await request.close().timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;

      if (address == null) return json['display_name'] as String?;

      return _buildReadableAddress(address);
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }

  /// Nominatim cok fazla alan donuyor. Turkiye adresleri icin
  /// anlamli olan parcalari secip birlestiriyoruz.
  String _buildReadableAddress(Map<String, dynamic> a) {
    final parts = <String>[];

    void add(String? value) {
      if (value != null && value.trim().isNotEmpty && !parts.contains(value)) {
        parts.add(value.trim());
      }
    }

    add(a['road'] as String?);
    if (a['house_number'] != null) {
      parts.add('No: ${a['house_number']}');
    }
    add((a['neighbourhood'] ?? a['suburb'] ?? a['quarter']) as String?);
    add((a['town'] ?? a['city_district'] ?? a['district']) as String?);
    add((a['city'] ?? a['province'] ?? a['state']) as String?);

    return parts.isEmpty ? 'Adres bulunamadı' : parts.join(', ');
  }
}