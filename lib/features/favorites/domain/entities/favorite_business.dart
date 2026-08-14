import '../../../business/domain/entities/business.dart';

/// Favoriler ekraninda gosterilen isletme ozeti.
class FavoriteBusiness {
  const FavoriteBusiness({
    required this.businessId,
    required this.name,
    required this.category,
    required this.providerType,
    this.logoUrl,
    this.address,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.latitude,
    this.longitude,
    this.activeOfferCount = 0,
    this.minPrice,
    this.notify = true,
  });

  final String businessId;
  final String name;
  final String? logoUrl;
  final BusinessCategory category;
  final ProviderType providerType;
  final String? address;
  final double ratingAvg;
  final int ratingCount;
  final double? latitude;
  final double? longitude;

  /// Su an alinabilir ilan sayisi.
  final int activeOfferCount;

  /// Aktif ilanlar icindeki en dusuk fiyat.
  final double? minPrice;

  /// Bu isletme yeni ilan verdiginde bildirim gonderilsin mi.
  final bool notify;

  bool get hasActiveOffers => activeOfferCount > 0;
  bool get isIndividual => providerType == ProviderType.individual;

  String get offerLabel {
    if (activeOfferCount == 0) return 'Şu an ilan yok';
    if (minPrice == 0) return '$activeOfferCount ilan · Ücretsiz';
    if (minPrice != null) {
      return '$activeOfferCount ilan · ${minPrice!.toStringAsFixed(0)}₺\'den';
    }
    return '$activeOfferCount ilan';
  }

  factory FavoriteBusiness.fromMap(Map<String, dynamic> map) {
    return FavoriteBusiness(
      businessId: map['business_id'] as String,
      name: (map['name'] as String?) ?? '',
      logoUrl: map['logo_url'] as String?,
      category: BusinessCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => BusinessCategory.other,
      ),
      providerType: (map['provider_type'] as String?) == 'individual'
          ? ProviderType.individual
          : ProviderType.business,
      address: map['address'] as String?,
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['rating_count'] as int?) ?? 0,
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      activeOfferCount: (map['active_offer_count'] as int?) ?? 0,
      minPrice: (map['min_price'] as num?)?.toDouble(),
      notify: (map['notify'] as bool?) ?? true,
    );
  }
}