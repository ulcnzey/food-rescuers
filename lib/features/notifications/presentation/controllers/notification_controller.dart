import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/notification_repository.dart';
import '../../domain/entities/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseProvider));
});

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(notificationRepositoryProvider).fetchAll();
});

/// Zil ikonundaki rozet sayisi.
final unreadCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authStateProvider);
  ref.watch(notificationsProvider);
  return ref.watch(notificationRepositoryProvider).unreadCount();
});

class NotificationController extends StateNotifier<bool> {
  NotificationController(this._repo, this._ref) : super(false);

  final NotificationRepository _repo;
  final Ref _ref;

  Future<void> markRead(String id) async {
    try {
      await _repo.markRead(id);
      _invalidate();
    } catch (_) {
      // Okundu isaretleme kritik degil, sessizce gec.
    }
  }

  Future<void> markAllRead() async {
    state = true;
    try {
      await _repo.markAllRead();
      _invalidate();
    } catch (_) {
      // Yoksay.
    } finally {
      state = false;
    }
  }

  void _invalidate() {
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, bool>((ref) {
  return NotificationController(ref.watch(notificationRepositoryProvider), ref);
});