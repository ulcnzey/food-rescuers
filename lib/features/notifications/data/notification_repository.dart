import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetchAll({int limit = 50}) async {
    final rows = await _client.rpc(
      'my_notifications',
      params: {'p_limit': limit},
    ) as List<dynamic>;

    return rows
        .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final result = await _client.rpc('unread_notification_count');
    return (result as int?) ?? 0;
  }

  Future<void> markRead(String id) async {
    await _client.rpc('mark_notification_read', params: {'p_id': id});
  }

  Future<void> markAllRead() async {
    await _client.rpc('mark_all_notifications_read');
  }
}