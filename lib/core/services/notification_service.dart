import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Cihaz ustu bildirim yonetimi.
/// Su asamada uzak sunucu (FCM) baglantisi yok; uygulama
/// acikken olusan bildirimler yerel olarak gosteriliyor.
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Bildirime tiklanildiginda calisan geri cagri.
  void Function(String? payload)? onTap;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        onTap?.call(response.payload);
      },
    );

    _initialized = true;
  }

  /// Sistem izni ister. Kullanici reddederse false doner.
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('NOTIFICATION PERMISSION ERROR: $e');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      return Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Cihazda bildirim gosterir.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'foodrescuers_general',
        'Genel Bildirimler',
        channelDescription: 'Rezervasyon ve ilan bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF0F4C42),
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}