import 'package:flutter/material.dart';

enum NotificationType {
  reservationCreated,
  newReservation,
  reservationCompleted,
  newOffer,
  other,
}

extension NotificationTypeX on NotificationType {
  IconData get icon => switch (this) {
        NotificationType.reservationCreated => Icons.confirmation_number_rounded,
        NotificationType.newReservation => Icons.shopping_bag_rounded,
        NotificationType.reservationCompleted => Icons.check_circle_rounded,
        NotificationType.newOffer => Icons.local_offer_rounded,
        NotificationType.other => Icons.notifications_rounded,
      };

  static NotificationType fromDb(String? value) => switch (value) {
        'reservation_created' => NotificationType.reservationCreated,
        'new_reservation' => NotificationType.newReservation,
        'reservation_completed' => NotificationType.reservationCompleted,
        'new_offer' => NotificationType.newOffer,
        _ => NotificationType.other,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data = const {},
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// Ilgili kayit kimlikleri: offer_id, reservation_id, business_id.
  final Map<String, dynamic> data;

  String? get offerId => data['offer_id'] as String?;

  /// "3 dk once", "2 sa once", "dun", "12.08"
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';

    return '${createdAt.day.toString().padLeft(2, '0')}.'
        '${createdAt.month.toString().padLeft(2, '0')}';
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: NotificationTypeX.fromDb(map['type'] as String?),
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      isRead: (map['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      data: (map['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}