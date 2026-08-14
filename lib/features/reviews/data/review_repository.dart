import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/review.dart';

class ReviewRepository {
  ReviewRepository(this._client);

  final SupabaseClient _client;

  Future<List<Review>> fetchForBusiness(String businessId) async {
    final rows = await _client.rpc(
      'business_reviews',
      params: {'p_business_id': businessId},
    ) as List<dynamic>;

    return rows
        .map((e) => Review.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<RatingBreakdown> fetchBreakdown(String businessId) async {
    final rows = await _client.rpc(
      'business_rating_breakdown',
      params: {'p_business_id': businessId},
    ) as List<dynamic>;

    return RatingBreakdown.fromRows(rows);
  }

  /// Yorum ekler veya gunceller. Sadece teslim alinmis
  /// rezervasyonlar icin veritabani izin verir.
  Future<void> addReview({
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    await _client.rpc(
      'add_review',
      params: {
        'p_reservation_id': reservationId,
        'p_rating': rating,
        'p_comment': comment,
      },
    );
  }

  /// Isletme sahibi yoruma cevap yazar.
  Future<void> reply({
    required String reviewId,
    required String text,
  }) async {
    await _client.rpc(
      'reply_to_review',
      params: {'p_review_id': reviewId, 'p_reply': text},
    );
  }
}