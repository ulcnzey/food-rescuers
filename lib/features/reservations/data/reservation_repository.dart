import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/reservation.dart';

class ReservationRepository {
  ReservationRepository(this._client);

  final SupabaseClient _client;

  /// Rezervasyon olusturur. Stok kontrolu ve satir kilidi
  /// veritabani fonksiyonunda yapilir; burada yaris durumu olusamaz.
  Future<Reservation> reserve({
    required String offerId,
    int quantity = 1,
  }) async {
    final id = await _client.rpc(
      'reserve_offer',
      params: {'p_offer_id': offerId, 'p_quantity': quantity},
    ) as String;

    // Olusan rezervasyonu tam veriyle (isletme, QR, saat) geri cek.
    final all = await fetchMine();
    return all.firstWhere((r) => r.id == id);
  }

  Future<List<Reservation>> fetchMine() async {
    final rows = await _client.rpc('my_reservations') as List<dynamic>;
    return rows
        .map((e) => Reservation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancel(String reservationId) async {
    await _client.rpc(
      'cancel_reservation',
      params: {'p_reservation_id': reservationId},
    );
  }

  /// Isletme tarafi: QR okutulunca teslimi onaylar.
  Future<void> completeByQr(String qrToken) async {
    await _client.rpc(
      'complete_reservation',
      params: {'p_qr_token': qrToken},
    );
  }

  Future<ImpactStats> fetchImpact() async {
    final rows = await _client.rpc('my_impact') as List<dynamic>;
    if (rows.isEmpty) return const ImpactStats();
    return ImpactStats.fromMap(rows.first as Map<String, dynamic>);
  }
}