import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/services/user_service.dart';

const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
  'barbapp_reservations',
  'Reservas y cancelaciones',
  description: 'Notificaciones de reservas y cancelaciones',
  importance: Importance.high,
);

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _backgroundHandlerRegistered = false;
  static Uint8List? _logoBytes;

  static Future<void> initialize() async {
    await _ensureFirebaseReady();
    _registerBackgroundHandler();

    if (_initialized) {
      await _registerDeviceToken();
      return;
    }

    _initialized = true;

    await _requestPermissions();
    await _configureLocalNotifications();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await _registerDeviceToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      UserService.registerDeviceToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      _showForegroundNotification(message);
    });

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _ensureFirebaseReady() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static void _registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) {
      return;
    }

    _backgroundHandlerRegistered = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_defaultChannel);
  }

  static Future<void> _registerDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await UserService.registerDeviceToken(token);
  }

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    final largeIcon = await _loadNotificationLogo();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannel.id,
        _defaultChannel.name,
        channelDescription: _defaultChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: notification.android?.smallIcon ?? '@mipmap/ic_launcher',
        largeIcon: largeIcon,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  static Future<ByteArrayAndroidBitmap?> _loadNotificationLogo() async {
    if (_logoBytes != null) {
      return ByteArrayAndroidBitmap(_logoBytes!);
    }

    try {
      final data = await rootBundle.load('assets/barbapp_logo.png');
      final bytes = data.buffer.asUint8List();
      if (bytes.isEmpty) {
        return null;
      }
      _logoBytes = bytes;
      return ByteArrayAndroidBitmap(bytes);
    } catch (_) {
      return null;
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
