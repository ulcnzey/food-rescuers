import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/offer.dart';
import '../domain/entities/offer_detail.dart';

class OfferRepository {
  OfferRepository(this._client);

  final SupabaseClient _client;

  /// Yakindaki aktif ilanlar. Mesafe hesabi ve filtreleme
  /// PostGIS tarafinda yapilir; istemci sadece sonucu alir.
  Future<List<Offer>> fetchNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 10000,
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

  /// Tek ilanin detayi. Konum verilirse mesafe de hesaplanir.
  Future<OfferDetail> fetchDetail({
    required String offerId,
    double? latitude,
    double? longitude,
  }) async {
    final rows = await _client.rpc(
      'offer_detail',
      params: {
        'p_offer_id': offerId,
        'p_lat': latitude,
        'p_lng': longitude,
      },
    ) as List<dynamic>;

    if (rows.isEmpty) throw Exception('OFFER_NOT_FOUND');
    return OfferDetail.fromMap(rows.first as Map<String, dynamic>);
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

  /// Mevcut ilanin gorselini gunceller. Sahiplik kontrolu
  /// veritabani fonksiyonunda yapilir.
  Future<void> updateOfferImage({
    required String offerId,
    required String imageUrl,
  }) async {
    await _client.rpc(
      'update_offer_image',
      params: {'p_offer_id': offerId, 'p_image_url': imageUrl},
    );
  }

  Future<void> cancelOffer(String offerId) async {
    await _client.rpc('cancel_offer', params: {'p_offer_id': offerId});
  }
}