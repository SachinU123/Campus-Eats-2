/// ─── CampusEats — Notification Service (Phase 11) ────────────────────────
///
/// Initialises Firebase Messaging, requests permissions, and handles
/// foreground / background / terminated notification delivery.
///
/// Design principles:
///  - Single call-site: NotificationService.instance.init() in main()
///  - All errors are caught — FCM failure must never crash the app
///  - Foreground messages show via flutter_local_notifications
///  - Token registration is fire-and-forget to the backend
///  - Works even if the user denies notification permission
///    (all push-dependent features degrade gracefully)
///
/// Required:
///  - google-services.json (Android) must be placed in android/app/
///  - GoogleService-Info.plist (iOS) must be placed in ios/Runner/
///  Both files come from your Firebase console > Project Settings > Apps.

library;

import 'dart:developer' as dev;
import 'package:campus_eats_ag/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Background message handler ─────────────────────────────────────────────
// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // App is in background/terminated — just log; the system tray shows it.
  dev.log(
    '[FCM BG] Received: ${message.notification?.title}',
    name: 'NotificationService',
  );
}

// ─── Local notification channel (Android 8+) ────────────────────────────────
const _channel = AndroidNotificationChannel(
  'campus_eats_orders',         // must match channelId in backend FCM payload
  'CampusEats Orders',
  description: 'Order status alerts from the CampusEats canteen',
  importance: Importance.high,
  playSound: true,
);

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _localNotifs = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Call once from main() before runApp().
  /// [onTokenRefresh]: called whenever a fresh FCM token is obtained —
  /// your code should POST it to /orders/fcm-token.
  Future<void> init({
    required Future<void> Function(String token) onTokenRefresh,
  }) async {
    if (_initialized) return;
    _initialized = true;

    try {
      // ── Firebase Core ───────────────────────────────────────────
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ── Background handler (must be top-level) ──────────────────
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // ── Local notifications init ────────────────────────────────
      await _localNotifs.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
      );

      // Create Android notification channel
      final androidPlugin = _localNotifs
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);

      // ── Request permission ──────────────────────────────────────
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      dev.log(
        '[FCM] Permission: ${settings.authorizationStatus.name}',
        name: 'NotificationService',
      );

      // ── Foreground notification display ─────────────────────────
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final n = message.notification;
        if (n == null) return;
        dev.log(
          '[FCM FG] ${n.title} — ${n.body}',
          name: 'NotificationService',
        );
        _showLocal(title: n.title ?? '', body: n.body ?? '');
      });

      // ── Token management ────────────────────────────────────────
      // Get current token and register immediately
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        dev.log('[FCM] Token obtained: ...${token.substring(token.length - 8)}',
            name: 'NotificationService');
        await onTokenRefresh(token).catchError((e) {
          dev.log('[FCM] Token registration failed: $e',
              name: 'NotificationService');
        });
      }

      // Re-register when FCM rotates the token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        dev.log('[FCM] Token refreshed', name: 'NotificationService');
        await onTokenRefresh(newToken).catchError((e) {
          dev.log('[FCM] Token refresh registration failed: $e',
              name: 'NotificationService');
        });
      });

      dev.log('[FCM] NotificationService initialised', name: 'NotificationService');
    } catch (e, st) {
      // Never crash the app — FCM is a best-effort feature
      dev.log('[FCM] Init failed: $e\n$st', name: 'NotificationService');
    }
  }

  /// Shows a foreground notification using the local notification plugin.
  void _showLocal({required String title, required String body}) {
    try {
      _localNotifs.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      dev.log('[FCM] Show local failed: $e', name: 'NotificationService');
    }
  }
}
