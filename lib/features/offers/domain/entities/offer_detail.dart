import 'offer.dart';

/// Ilan detay ekraninin ihtiyac duydugu genisletilmis veri.
class OfferDetail {
  const OfferDetail({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.foodType,
    required this.price,
    required this.quantityTotal,
    required this.quantityAvailable,
    required this.pickupEnd,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.businessAddress,
    this.businessPhone,
    this.businessRating = 0,
    this.businessRatingCount = 0,
    this.isIndividualProvider = false,
    this.description,
    this.imageUrl,
    this.originalPrice = 0,
    this.pickupStart,
    this.distanceKm,
    this.alreadyReserved = false,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final double businessRating;
  final int businessRatingCount;
  final bool isIndividualProvider;

  final String title;
  final String? description;
  final String? imageUrl;
  final FoodType foodType;
  final double originalPrice;
  final double price;
  final int quantityTotal;
  final int quantityAvailable;
  final DateTime? pickupStart;
  final DateTime pickupEnd;
  final OfferStatus status;
  final double latitude;
  final double longitude;
  final double? distanceKm;

  /// Kullanicinin bu ilana zaten aktif rezervasyonu var mi.
  final bool alreadyReserved;

  bool get isFree => price == 0;

  bool get isAvailable =>
      status == OfferStatus.active &&
      quantityAvailable > 0 &&
      pickupEnd.isAfter(DateTime.now());

  int get discountPercent {
    if (originalPrice <= 0 || price >= originalPrice) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }

  /// Stok doluluk orani. Ilerleme cubugunda kullanilir.
  double get stockRatio =>
      quantityTotal == 0 ? 0 : quantityAvailable / quantityTotal;

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

  String get distanceLabel {
    if (distanceKm == null) return '';
    return distanceKm! < 1
        ? '${(distanceKm! * 1000).round()} m'
        : '${distanceKm!.toStringAsFixed(1)} km';
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

    final t = now.add(const Duration(days: 1));
    if (d.year == t.year && d.month == t.month && d.day == t.day) {
      return 'Yarın';
    }

    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  factory OfferDetail.fromMap(Map<String, dynamic> map) {
    return OfferDetail(
      id: map['id'] as String,
      businessId: (map['business_id'] as String?) ?? '',
      businessName: (map['business_name'] as String?) ?? '',
      businessAddress: map['business_address'] as String?,
      businessPhone: map['business_phone'] as String?,
      businessRating: (map['business_rating'] as num?)?.toDouble() ?? 0,
      businessRatingCount: (map['business_rating_count'] as int?) ?? 0,
      isIndividualProvider: (map['provider_type'] as String?) == 'individual',
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      foodType: FoodType.values.firstWhere(
        (t) => t.name == map['food_type'],
        orElse: () => FoodType.other,
      ),
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantityTotal: (map['quantity_total'] as int?) ?? 0,
      quantityAvailable: (map['quantity_available'] as int?) ?? 0,
      pickupStart: _parse(map['pickup_start']),
      pickupEnd: _parse(map['pickup_end']) ?? DateTime.now(),
      status: OfferStatusX.fromDb(map['status'] as String?),
      latitude: (map['lat'] as num?)?.toDouble() ?? 0,
      longitude: (map['lng'] as num?)?.toDouble() ?? 0,
      distanceKm: (map['distance_m'] as num?) == null
          ? null
          : (map['distance_m'] as num).toDouble() / 1000,
      alreadyReserved: (map['already_reserved'] as bool?) ?? false,
    );
  }

  static DateTime? _parse(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();
}