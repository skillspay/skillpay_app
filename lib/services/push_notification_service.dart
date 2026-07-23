import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:skillpay/services/api_client.dart';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'skillpay_notifications',
    'Skillpay Notifications',
    description: 'Notifications from Skillpay',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // 3. Set up local notifications for foreground messages
    await _setupLocalNotifications();

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle notification tap (app in background / terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Check if app was launched from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);

    // 7. Get & save FCM token via NestJS
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 3));
          await _messaging.getAPNSToken();
        }
      }
      final token = await _messaging.getToken();
      if (token != null) await _saveFcmToken(token);
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // 8. Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveFcmToken);
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
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
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Add deep-link / navigation logic here as features are added.
    debugPrint('Notification tapped: ${message.data}');
  }

  /// Save the FCM token to NestJS — stored in the `users` table.
  /// Called at startup and on every token refresh.
  Future<void> _saveFcmToken(String token) async {
    try {
      await ApiClient.instance.patch('/auth/fcm-token', body: {
        'fcmToken': token,
      });
      debugPrint('FCM token saved via API');
    } on ApiException catch (e) {
      // Non-critical — user will still receive notifications next session
      debugPrint('Failed to save FCM token: ${e.message}');
    }
  }
}
