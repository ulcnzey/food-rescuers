class BusinessStats {
  const BusinessStats({
    this.activeOffers = 0,
    this.todayReservations = 0,
    this.todayCompleted = 0,
    this.todayRevenue = 0,
    this.weekRevenue = 0,
    this.totalSavedMeals = 0,
    this.pendingPickups = 0,
  });

  final int activeOffers;
  final int todayReservations;
  final int todayCompleted;
  final double todayRevenue;
  final double weekRevenue;
  final int totalSavedMeals;

  /// Bugun teslim bekleyen aktif rezervasyonlar.
  final int pendingPickups;

  factory BusinessStats.fromMap(Map<String, dynamic> map) {
    return BusinessStats(
      activeOffers: (map['active_offers'] as int?) ?? 0,
      todayReservations: (map['today_reservations'] as int?) ?? 0,
      todayCompleted: (map['today_completed'] as int?) ?? 0,
      todayRevenue: (map['today_revenue'] as num?)?.toDouble() ?? 0,
      weekRevenue: (map['week_revenue'] as num?)?.toDouble() ?? 0,
      totalSavedMeals: (map['total_saved_meals'] as int?) ?? 0,
      pendingPickups: (map['pending_pickups'] as int?) ?? 0,
    );
  }
}