import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/offer.dart';

class OfferRepository {
  OfferRepository(this._client);

  final SupabaseClient _client;

  /// Yakindaki aktif ilanlar.
  Future<List<Offer>> fetchNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    FoodType? foodType,
    double? maxPrice,
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _client.rpc(
      'nearby_offers',
      params: {
        'p_lat': latitude,
        'p_lng': longitude,
        'p_radius_m': radiusMeters,
        'p_food_type': foodType?.name,
        'p_max_price': maxPrice,
        'p_limit': limit,
        'p_offset': offset,
      },
    ) as List<dynamic>;

    return rows
        .map((e) => Offer.fromNearbyMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Isletmenin kendi ilanlari.
  Future<List<Offer>> fetchMyOffers(String businessName) async {
    final rows = await _client.rpc('my_offers') as List<dynamic>;

    return rows
        .map((e) =>
            Offer.fromMyOfferMap(e as Map<String, dynamic>, businessName))
        .toList();
  }

  /// Yeni ilan olusturur, id doner.
  Future<String> createOffer({
    required String title,
    required FoodType foodType,
    required double price,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    String? description,
    double? originalPrice,
    String? imageUrl,
  }) async {
    final id = await _client.rpc(
      'create_offer',
      params: {
        'p_title': title,
        'p_food_type': foodType.name,
        'p_price': price,
        'p_quantity': quantity,
        'p_pickup_start': pickupStart.toUtc().toIso8601String(),
        'p_pickup_end': pickupEnd.toUtc().toIso8601String(),
        'p_description': description,
        'p_original_price': originalPrice,
        'p_image_url': imageUrl,
      },
    );

    return id as String;
  }

  Future<void> cancelOffer(String offerId) async {
    await _client.rpc('cancel_offer', params: {'p_offer_id': offerId});
  }
}