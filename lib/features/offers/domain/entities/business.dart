enum BusinessCategory { bakery, restaurant, market, cafe, other }

extension BusinessCategoryX on BusinessCategory {
  String get displayName => switch (this) {
        BusinessCategory.bakery => 'Fırın / Pastane',
        BusinessCategory.restaurant => 'Restoran',
        BusinessCategory.market => 'Market',
        BusinessCategory.cafe => 'Kafe',
        BusinessCategory.other => 'Diğer',
      };
}

class Business {
  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.description,
    this.address,
    this.logoUrl,
    this.phone,
    this.isVerified = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.opensAt,
    this.closesAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final BusinessCategory category;
  final double latitude;
  final double longitude;
  final String? description;
  final String? address;
  final String? logoUrl;
  final String? phone;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;

  /// "07:00" seklinde metin olarak tutulur.
  final String? opensAt;
  final String? closesAt;

  String get workingHoursLabel {
    if (opensAt == null || closesAt == null) return 'Saat bilgisi yok';
    return '${_short(opensAt!)} - ${_short(closesAt!)}';
  }

  static String _short(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      category: BusinessCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => BusinessCategory.other,
      ),
      latitude: (map['lat'] as num?)?.toDouble() ?? 0,
      longitude: (map['lng'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String?,
      address: map['address'] as String?,
      logoUrl: map['logo_url'] as String?,
      phone: map['phone'] as String?,
      isVerified: (map['is_verified'] as bool?) ?? false,
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['rating_count'] as int?) ?? 0,
      opensAt: map['opens_at'] as String?,
      closesAt: map['closes_at'] as String?,
    );
  }
}