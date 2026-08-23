import '../../../offers/domain/entities/offer.dart';

enum ReservationStatus { active, completed, cancelled, expired }

extension ReservationStatusX on ReservationStatus {
  String get displayName => switch (this) {
        ReservationStatus.active => 'Aktif',
        ReservationStatus.completed => 'Teslim alındı',
        ReservationStatus.cancelled => 'İptal edildi',
        ReservationStatus.expired => 'Süresi doldu',
      };

  static ReservationStatus fromDb(String? value) => switch (value) {
        'completed' => ReservationStatus.completed,
        'cancelled' => ReservationStatus.cancelled,
        'expired' => ReservationStatus.expired,
        _ => ReservationStatus.active,
      };
}

class Reservation {
  const Reservation({
    required this.id,
    required this.offerId,
    required this.offerTitle,
    required this.foodType,
    required this.businessId,
    required this.businessName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.pickupCode,
    required this.qrToken,
    required this.pickupEnd,
    required this.createdAt,
    this.offerImageUrl,
    this.businessAddress,
    this.businessPhone,
    this.businessLat,
    this.businessLng,
    this.pickupStart,
    this.completedAt,
    this.hasReview = false,
    this.myRating,
  });

  final String id;
  final String offerId;
  final String offerTitle;
  final String? offerImageUrl;
  final FoodType foodType;

  final String businessId;
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final double? businessLat;
  final double? businessLng;

  final int quantity;
  final double totalPrice;
  final ReservationStatus status;

  /// QR okunamazsa manuel dogrulama icin 6 haneli kod.
  final String pickupCode;

  /// QR koda gomulen tek kullanimlik token.
  final String qrToken;

  final DateTime? pickupStart;
  final DateTime pickupEnd;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Kullanici bu siparise yorum yapmis mi.
  final bool hasReview;

  /// Yapmissa kac yildiz vermis.
  final int? myRating;

  bool get isFree => totalPrice == 0;

  bool get isActive =>
      status == ReservationStatus.active && pickupEnd.isAfter(DateTime.now());

  bool get isExpiredNow =>
      status == ReservationStatus.active && pickupEnd.isBefore(DateTime.now());

  /// Alim saatine kalan sure.
  String get timeLeftLabel {
    final diff = pickupEnd.difference(DateTime.now());
    if (diff.isNegative) return 'Süre doldu';
    if (diff.inHours >= 24) return '${diff.inDays} gün';
    if (diff.inHours >= 1) {
      final m = diff.inMinutes % 60;
      return m == 0 ? '${diff.inHours} sa' : '${diff.inHours} sa $m dk';
    }
    return '${diff.inMinutes} dk';
  }

  String get pickupWindowLabel {
    if (pickupStart == null) return _hm(pickupEnd);
    return '${_hm(pickupStart!)} - ${_hm(pickupEnd)}';
  }

  String get dateLabel {
    final now = DateTime.now();
    final d = pickupEnd;

    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Bugün';
    }

    final tomorrow = now.add(const Duration(days: 1));
    if (d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day) {
      return 'Yarın';
    }

    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as String,
      offerId: map['offer_id'] as String,
      offerTitle: (map['offer_title'] as String?) ?? '',
      offerImageUrl: map['offer_image_url'] as String?,
      foodType: FoodType.values.firstWhere(
        (t) => t.name == map['food_type'],
        orElse: () => FoodType.other,
      ),
      businessId: (map['business_id'] as String?) ?? '',
      businessName: (map['business_name'] as String?) ?? '',
      businessAddress: map['business_address'] as String?,
      businessPhone: map['business_phone'] as String?,
      businessLat: (map['business_lat'] as num?)?.toDouble(),
      businessLng: (map['business_lng'] as num?)?.toDouble(),
      quantity: (map['quantity'] as int?) ?? 1,
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0,
      status: ReservationStatusX.fromDb(map['status'] as String?),
      pickupCode: (map['pickup_code'] as String?) ?? '',
      qrToken: (map['qr_token'] as String?) ?? '',
      pickupStart: _parse(map['pickup_start']),
      pickupEnd: _parse(map['pickup_end']) ?? DateTime.now(),
      createdAt: _parse(map['created_at']) ?? DateTime.now(),
      completedAt: _parse(map['completed_at']),
      hasReview: (map['has_review'] as bool?) ?? false,
      myRating: map['my_rating'] as int?,
    );
  }

  static DateTime? _parse(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();
}

/// Kullanicinin toplam etkisi.
class ImpactStats {
  const ImpactStats({
    this.savedMeals = 0,
    this.savedMoney = 0,
    this.co2Kg = 0,
  });

  final int savedMeals;
  final double savedMoney;
  final double co2Kg;

  factory ImpactStats.fromMap(Map<String, dynamic> map) {
    return ImpactStats(
      savedMeals: (map['saved_meals'] as int?) ?? 0,
      savedMoney: (map['saved_money'] as num?)?.toDouble() ?? 0,
      co2Kg: (map['co2_kg'] as num?)?.toDouble() ?? 0,
    );
  }
}