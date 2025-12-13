import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/provider.dart';
import 'package:soundhive2/lib/dashboard_provider/notification_provider.dart';
import 'package:soundhive2/services/loader_service.dart';

import '../lib/dashboard_provider/call_provider.dart';
import '../lib/dashboard_provider/user_provider.dart';
import '../screens/chats/call_screen.dart';
import '../utils/app_colors.dart';


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
    final data = message.data;

    if (data['type'] == 'incoming_call') {
      _handleIncomingCallNotification(data);
    } else {
      container.read(notificationProvider.notifier).clearNotifications();
      // Your existing notification handling
    }
  }
  void _handleIncomingCallNotification(Map<String, dynamic> data) {
    // Use navigatorKey to handle navigation from anywhere
    final context =LoaderService.navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        title: const Text('Incoming Call', style: TextStyle(color: Colors.white)),
        content: Text('${data['caller_name']} is calling you...',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectCallFromNotification(data);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptCallFromNotification(data);
            },
            child: const Text('Accept', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

// ADD THESE METHODS:
  void _rejectCallFromNotification(Map<String, dynamic> data) {
    print('Call rejected from notification: ${data['call_id']}');

    // You can add logic to notify the caller that call was rejected
    // For now, just log it
  }

  void _acceptCallFromNotification(Map<String, dynamic> data) {
    print('Call accepted from notification: ${data['call_id']}');

    final channelName = data['channel_name'];

    // Get the current user from your provider
    final currentUser = container.read(userProvider).value?.user;
    if (currentUser == null) return;

    // Join the call
    container.read(audioCallProvider.notifier).joinCall(
        channelName,
        int.parse(currentUser.id.toString())
    );

    // Navigate to call screen
    final context = LoaderService.navigatorKey.currentContext;
    if (context != null) {
      // You'll need to implement this method to show the call screen
      _showCallScreenFromNotification(context);
    }
  }

  void _showCallScreenFromNotification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            final callNotifier = ref.read(audioCallProvider.notifier);

            return AudioCallScreen(
              onEndCall: () {
                Navigator.pop(context);
                callNotifier.endCall();
              },
            );
          },
        ),
        fullscreenDialog: true, // This gives it a modal-like appearance
      ),
    );
  }
}



@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final service = FirebaseService.background();
  final data = message.data;
  if (data['type'] == 'incoming_call') {
    // In background, we can only show notification, not the dialog
    await service._showNotification(message);
  } else {
    await service._showNotification(message);
  }
}