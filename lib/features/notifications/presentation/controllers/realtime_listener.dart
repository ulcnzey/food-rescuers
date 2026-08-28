import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../../../core/services/notification_service.dart';
import 'notification_controller.dart';

/// Veritabanina yeni bildirim eklendiginde cihazda gosterir.
/// Supabase Realtime kanali uzerinden dinliyor; boylece
/// uygulama acikken bildirim aninda dusuyor.
class NotificationListener extends ConsumerStatefulWidget {
  const NotificationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationListener> createState() =>
      _NotificationListenerState();
}

class _NotificationListenerState extends ConsumerState<NotificationListener> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final client = ref.read(supabaseProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    _channel = client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _onNewNotification(payload.newRecord),
        )
        .subscribe();
  }

  void _unsubscribe() {
    final channel = _channel;
    if (channel != null) {
      ref.read(supabaseProvider).removeChannel(channel);
      _channel = null;
    }
  }

  Future<void> _onNewNotification(Map<String, dynamic> record) async {
    // Rozet ve liste tazelensin.
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);

    // Kullanici bildirimleri kapatmissa cihazda gosterme.
    final pref = await ref.read(notificationPreferenceProvider.future);
    if (pref.enabled != true) return;

    await NotificationService.instance.show(
      title: (record['title'] as String?) ?? 'FoodRescuers',
      body: (record['body'] as String?) ?? '',
      payload: record['id'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}