/// Mesafeden yaklasik yuruyus suresi hesaplar.
/// Ortalama yaya hizi 4.5 km/sa; sehir ici trafik isiklari ve
/// kavsaklar icin %20 pay eklenir.
class WalkingTime {
  WalkingTime._();

  static const _speedKmh = 4.5;
  static const _cityFactor = 1.2;

  /// Dakika cinsinden tahmini sure.
  static int minutesFor(double distanceKm) {
    if (distanceKm <= 0) return 0;
    final minutes = (distanceKm / _speedKmh) * 60 * _cityFactor;
    return minutes.ceil();
  }

  /// "8 dk", "1 sa 5 dk", "35+ dk"
  static String label(double distanceKm) {
    final m = minutesFor(distanceKm);

    if (m == 0) return 'Çok yakın';
    if (m < 60) return '$m dk';

    final h = m ~/ 60;
    final rest = m % 60;
    return rest == 0 ? '$h sa' : '$h sa $rest dk';
  }

  /// Uzun mesafede yuruyus mantikli degil.
  static bool isWalkable(double distanceKm) => distanceKm <= 3;
}