import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/banner_item.dart';
import '../domain/entities/saved_location.dart';

class HomeRepository {
  HomeRepository(this._client);

  final SupabaseClient _client;

  /// Kullanici tarafi bannerlari.
  Future<List<BannerItem>> fetchBanners() async {
    final rows = await _client.rpc('active_banners') as List<dynamic>;
    return rows
        .map((e) => BannerItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Isletme paneli bannerlari. Ayri tabloda tutuluyor,
  /// boylece iki taraf birbirini etkilemeden yonetilebiliyor.
  Future<List<BannerItem>> fetchBusinessBanners() async {
    final rows = await _client.rpc('active_business_banners') as List<dynamic>;
    return rows
        .map((e) => BannerItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SavedLocation>> fetchLocations() async {
    final rows = await _client.rpc('my_locations') as List<dynamic>;
    return rows
        .map((e) => SavedLocation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveLocation({
    required String label,
    required double latitude,
    required double longitude,
    String? address,
    bool isDefault = false,
  }) async {
    final id = await _client.rpc(
      'save_location',
      params: {
        'p_label': label,
        'p_lat': latitude,
        'p_lng': longitude,
        'p_address': address,
        'p_is_default': isDefault,
      },
    );

    return id as String;
  }

  Future<void> deleteLocation(String id) async {
    await _client.rpc('delete_location', params: {'p_id': id});
  }
}