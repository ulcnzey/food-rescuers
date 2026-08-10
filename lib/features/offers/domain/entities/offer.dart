enum FoodType { bakery, meal, grocery, produce, other }

enum OfferStatus { active, soldOut, expired, cancelled }

extension OfferStatusX on OfferStatus {
  String get dbValue => switch (this) {
        OfferStatus.active => 'active',
        OfferStatus.soldOut => 'sold_out',
        OfferStatus.expired => 'expired',
        OfferStatus.cancelled => 'cancelled',
      };

  String get displayName => switch (this) {
        OfferStatus.active => 'Aktif',
        OfferStatus.soldOut => 'Tükendi',
        OfferStatus.expired => 'Süresi doldu',
        OfferStatus.cancelled => 'İptal edildi',
      };

  static OfferStatus fromDb(String? value) => switch (value) {
        'sold_out' => OfferStatus.soldOut,
        'expired' => OfferStatus.expired,
        'cancelled' => OfferStatus.cancelled,
        _ => OfferStatus.active,
      };
}

class Offer {
  const Offer({
    required this.id,
    required this.businessName,
    required this.title,
    required this.originalPrice,
    required this.price,
    required this.quantityAvailable,
    required this.pickupEnd,
    required this.distanceKm,
    required this.rating,
    required this.foodType,
    this.businessId = '',
    this.businessLogo,
    this.description,
    this.imageUrl,
    this.quantityTotal = 0,
    this.pickupStart,
    this.status = OfferStatus.active,
    this.reservedCount = 0,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String businessId;
  final String businessName;

  /// Isletme logosu. Kartta yuvarlak rozet olarak gosterilir.
  final String? businessLogo;

  final String title;
  final String? description;
  final String? imageUrl;
  final double originalPrice;
  final double price;
  final int quantityTotal;
  final int quantityAvailable;
  final DateTime? pickupStart;
  final DateTime pickupEnd;
  final double distanceKm;
  final double rating;
  final FoodType foodType;
  final OfferStatus status;

  /// Isletme panelinde kac kisinin rezerve ettigini gosterir.
  final int reservedCount;

  final double? latitude;
  final double? longitude;

  bool get isFree => price == 0;

  bool get isActive =>
      status == OfferStatus.active && pickupEnd.isAfter(DateTime.now());

  int get discountPercent {
    if (originalPrice <= 0 || price >= originalPrice) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }

  bool get isLastChance => quantityAvailable > 0 && quantityAvailable <= 2;

  /// Satilan adet. Isletme panelinde ilerleme cubugunda kullanilir.
  int get soldCount => quantityTotal - quantityAvailable;

  /// "1 sa 20 dk" seklinde kalan sure.
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

  String get distanceLabel => distanceKm < 1
      ? '${(distanceKm * 1000).round()} m'
      : '${distanceKm.toStringAsFixed(1)} km';

  /// "18:00 - 20:00" seklinde alim araligi.
  String get pickupWindowLabel {
    if (pickupStart == null) return _hm(pickupEnd);
    return '${_hm(pickupStart!)} - ${_hm(pickupEnd)}';
  }

  /// "Bugün" / "Yarın" / "12.08"
  String get dateLabel {
    final now = DateTime.now();
    final d = pickupEnd;

    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Bugün';
    }

    final t = now.add(const Duration(days: 1));
    if (d.year == t.year && d.month == t.month && d.day == t.day) {
      return 'Yarın';
    }

    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// nearby_offers RPC ciktisi
  factory Offer.fromNearbyMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'] as String,
      businessId: (map['business_id'] as String?) ?? '',
      businessName: (map['business_name'] as String?) ?? '',
      businessLogo: map['business_logo'] as String?,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantityAvailable: (map['quantity_available'] as int?) ?? 0,
      pickupStart: _parse(map['pickup_start']),
      pickupEnd: _parse(map['pickup_end']) ?? DateTime.now(),
      distanceKm: ((map['distance_m'] as num?)?.toDouble() ?? 0) / 1000,
      rating: (map['business_rating'] as num?)?.toDouble() ?? 0,
      foodType: _foodType(map['food_type'] as String?),
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
    );
  }

  /// my_offers RPC ciktisi
  factory Offer.fromMyOfferMap(Map<String, dynamic> map, String businessName) {
    return Offer(
      id: map['id'] as String,
      businessName: businessName,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantityTotal: (map['quantity_total'] as int?) ?? 0,
      quantityAvailable: (map['quantity_available'] as int?) ?? 0,
      pickupStart: _parse(map['pickup_start']),
      pickupEnd: _parse(map['pickup_end']) ?? DateTime.now(),
      distanceKm: 0,
      rating: 0,
      foodType: _foodType(map['food_type'] as String?),
      status: OfferStatusX.fromDb(map['status'] as String?),
      reservedCount: (map['reserved_count'] as int?) ?? 0,
    );
  }

  static DateTime? _parse(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();

  static FoodType _foodType(String? value) => FoodType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => FoodType.other,
      );
}