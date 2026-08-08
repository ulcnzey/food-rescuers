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

/// Saglayici tipi.
/// business  -> ticari isletme, ucretli veya ucretsiz ilan verebilir
/// individual -> bireysel paylasimci, SADECE ucretsiz bagis yapabilir
enum ProviderType { business, individual }

extension ProviderTypeX on ProviderType {
  String get displayName => switch (this) {
        ProviderType.business => 'İşletme',
        ProviderType.individual => 'Bireysel Paylaşımcı',
      };

  String get description => switch (this) {
        ProviderType.business =>
          'Fırın, market, kafe gibi ticari işletmeler. Ücretli veya ücretsiz ilan verebilir.',
        ProviderType.individual =>
          'Evindeki fazla gıdayı paylaşmak isteyen bireyler. Sadece ücretsiz bağış yapabilir.',
      };

  /// Ucretli ilan verme yetkisi.
  bool get canSellPaid => this == ProviderType.business;
}

class Business {
  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.providerType = ProviderType.business,
    this.description,
    this.address,
    this.logoUrl,
    this.phone,
    this.isVerified = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.opensAt,
    this.closesAt,
    this.openDays = const [0, 1, 2, 3, 4, 5],
  });

  final String id;
  final String ownerId;
  final String name;
  final BusinessCategory category;
  final ProviderType providerType;
  final double latitude;
  final double longitude;
  final String? description;
  final String? address;
  final String? logoUrl;
  final String? phone;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;

  /// "07:00:00" formatinda gelir.
  final String? opensAt;
  final String? closesAt;

  /// Pazartesi = 0 ... Pazar = 6
  final List<int> openDays;

  static const _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  bool get isIndividual => providerType == ProviderType.individual;

  String get workingHoursLabel {
    if (opensAt == null || closesAt == null) return 'Saat bilgisi yok';
    return '${_short(opensAt!)} - ${_short(closesAt!)}';
  }

  String get openDaysLabel {
    if (openDays.isEmpty) return 'Gün seçilmedi';
    if (openDays.length == 7) return 'Her gün';

    final sorted = [...openDays]..sort();

    // Ardisik gunleri araliga cevir: Pzt - Cum
    var consecutive = true;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] != sorted[i - 1] + 1) {
        consecutive = false;
        break;
      }
    }

    if (consecutive && sorted.length > 2) {
      return '${_dayNames[sorted.first]} - ${_dayNames[sorted.last]}';
    }

    return sorted.map((d) => _dayNames[d]).join(', ');
  }

  static String _short(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;

  factory Business.fromMap(Map<String, dynamic> map) {
    final rawDays = map['open_days'];

    return Business(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      category: BusinessCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => BusinessCategory.other,
      ),
      providerType: (map['provider_type'] as String?) == 'individual'
          ? ProviderType.individual
          : ProviderType.business,
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
      openDays: rawDays is List
          ? rawDays.map((e) => (e as num).toInt()).toList()
          : const [0, 1, 2, 3, 4, 5],
    );
  }
}