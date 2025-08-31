import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/provider.dart';
import 'package:soundhive2/lib/dashboard_provider/notification_provider.dart';


final authTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.read(storageProvider);
  return await storage.read(key: 'auth_token');
});
class FirebaseService {
  final ProviderContainer container;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  FirebaseService(this.container)
      : notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Background handler constructor
  factory FirebaseService.background() => FirebaseService._internal();

  FirebaseService._internal()
      : container = ProviderContainer(),
        notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> _setupTokenRefresh() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      // Get the current auth token
      final authToken = await container.read(authTokenProvider.future);
      if (authToken == null) {
        print("No auth token available - skipping FCM token refresh");
        return;
      }

      try {
        await container.read(dioProvider).post(
          '/notification/set-up',
          data: {'token': newToken},
          options: Options(headers: {
            'Authorization': 'Bearer $authToken',
          }),
        );
        print("Refreshed FCM token sent to server");
      } catch (e) {
        print("Error sending refreshed token: $e");
      }
    });
  }

  Future<void> initialize() async {
    await _setupNotificationChannels();
    await _requestPermissions();
    await _getFCMToken();
    _setupForegroundHandler();
    _setupBackgroundHandler();
    _setupNotificationInteractions();
    _setupTokenRefresh();
  }

  Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Important Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
    );

    // Initialize plugin with icon
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

    await notificationsPlugin.initialize(
      const InitializationSettings(
        android: initializationSettingsAndroid,
      ),
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _getFCMToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
    await _setupTokenRefresh();
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
      container.read(notificationProvider.notifier).addNotification();
      container.read(notificationProvider.notifier).fetchUnreadCount();

    });
  }

  void _setupNotificationInteractions() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        container.read(notificationProvider.notifier).clearNotifications();
        _handleNotificationInteraction(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      container.read(notificationProvider.notifier).clearNotifications();
      _handleNotificationInteraction(message);
    });
  }

  void _setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Important Notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'app_icon',
    );

    await notificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(android: androidDetails),
    );
  }

  void _handleNotificationInteraction(RemoteMessage message) {
    container.read(notificationProvider.notifier).clearNotifications();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final service = FirebaseService.background();
  await service._showNotification(message);
}