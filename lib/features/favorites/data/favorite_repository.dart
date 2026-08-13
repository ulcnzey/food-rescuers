import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/favorite_business.dart';

class FavoriteRepository {
  FavoriteRepository(this._client);

  final SupabaseClient _client;

  /// Favoriye ekler veya cikarir. Sonuc: favoride mi.
  Future<bool> toggle(String businessId) async {
    final result = await _client.rpc(
      'toggle_favorite',
      params: {'p_business_id': businessId},
    );

    return result as bool;
  }

  /// Sadece kimlikler. Kart listelerinde hizli kontrol icin.
  Future<Set<String>> fetchIds() async {
    final rows = await _client.rpc('my_favorite_ids') as List<dynamic>;
    return rows
        .map((e) => (e as Map<String, dynamic>)['business_id'] as String)
        .toSet();
  }

  Future<List<FavoriteBusiness>> fetchAll() async {
    final rows = await _client.rpc('my_favorites') as List<dynamic>;
    return rows
        .map((e) => FavoriteBusiness.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}