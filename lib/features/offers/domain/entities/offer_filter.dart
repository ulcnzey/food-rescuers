import 'offer.dart';

enum OfferSort { distance, price, discount, rating, urgent }

extension OfferSortX on OfferSort {
  String get dbValue => switch (this) {
        OfferSort.distance => 'distance',
        OfferSort.price => 'price',
        OfferSort.discount => 'discount',
        OfferSort.rating => 'rating',
        OfferSort.urgent => 'urgent',
      };

  String get label => switch (this) {
        OfferSort.distance => 'En yakın',
        OfferSort.price => 'En ucuz',
        OfferSort.discount => 'En çok indirim',
        OfferSort.rating => 'En yüksek puan',
        OfferSort.urgent => 'Süresi dolmak üzere',
      };
}

/// Alim zamani araligi. Haritadaki "Alım saati" filtresi.
enum PickupWindow { any, nextHour, today, tomorrow }

extension PickupWindowX on PickupWindow {
  String get label => switch (this) {
        PickupWindow.any => 'Tüm saatler',
        PickupWindow.nextHour => 'Önümüzdeki 1 saat',
        PickupWindow.today => 'Bugün',
        PickupWindow.tomorrow => 'Yarına kadar',
      };

  /// Filtrede kullanilacak ust sinir. Null ise sinir yok.
  DateTime? get upperBound {
    final now = DateTime.now();
    return switch (this) {
      PickupWindow.any => null,
      PickupWindow.nextHour => now.add(const Duration(hours: 1)),
      PickupWindow.today => DateTime(now.year, now.month, now.day, 23, 59),
      PickupWindow.tomorrow =>
        DateTime(now.year, now.month, now.day + 1, 23, 59),
    };
  }
}

class OfferFilter {
  const OfferFilter({
    this.foodType,
    this.maxPrice,
    this.freeOnly = false,
    this.pickupWindow = PickupWindow.any,
    this.sort = OfferSort.distance,
    this.radiusMeters = 20000,
  });

  final FoodType? foodType;
  final double? maxPrice;
  final bool freeOnly;
  final PickupWindow pickupWindow;
  final OfferSort sort;
  final int radiusMeters;

  /// Varsayilandan sapan filtre sayisi. Rozet olarak gosterilir.
  int get activeCount {
    var n = 0;
    if (foodType != null) n++;
    if (maxPrice != null) n++;
    if (freeOnly) n++;
    if (pickupWindow != PickupWindow.any) n++;
    if (sort != OfferSort.distance) n++;
    return n;
  }

  bool get isDefault => activeCount == 0;

  OfferFilter copyWith({
    FoodType? foodType,
    bool clearFoodType = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    bool? freeOnly,
    PickupWindow? pickupWindow,
    OfferSort? sort,
    int? radiusMeters,
  }) {
    return OfferFilter(
      foodType: clearFoodType ? null : (foodType ?? this.foodType),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      freeOnly: freeOnly ?? this.freeOnly,
      pickupWindow: pickupWindow ?? this.pickupWindow,
      sort: sort ?? this.sort,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OfferFilter &&
      other.foodType == foodType &&
      other.maxPrice == maxPrice &&
      other.freeOnly == freeOnly &&
      other.pickupWindow == pickupWindow &&
      other.sort == sort &&
      other.radiusMeters == radiusMeters;

  @override
  int get hashCode => Object.hash(
        foodType,
        maxPrice,
        freeOnly,
        pickupWindow,
        sort,
        radiusMeters,
      );
}