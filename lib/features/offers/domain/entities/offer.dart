enum FoodType { bakery, meal, grocery, produce, other }

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
  });

  final String id;
  final String businessName;
  final String title;
  final double originalPrice;
  final double price;
  final int quantityAvailable;
  final DateTime pickupEnd;
  final double distanceKm;
  final double rating;
  final FoodType foodType;

  bool get isFree => price == 0;

  int get discountPercent {
    if (originalPrice <= 0 || price >= originalPrice) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }

  bool get isLastChance => quantityAvailable <= 2;

  /// "1s 20dk kaldi" seklinde metin uretir.
  String get timeLeftLabel {
    final diff = pickupEnd.difference(DateTime.now());
    if (diff.isNegative) return 'Süre doldu';
    if (diff.inHours >= 1) {
      final m = diff.inMinutes % 60;
      return m == 0 ? '${diff.inHours} sa' : '${diff.inHours} sa $m dk';
    }
    return '${diff.inMinutes} dk';
  }

  String get distanceLabel =>
      distanceKm < 1 ? '${(distanceKm * 1000).round()} m' : '${distanceKm.toStringAsFixed(1)} km';
}