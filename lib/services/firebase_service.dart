import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/provider.dart';
import 'package:soundhive2/lib/dashboard_provider/notification_provider.dart';
import 'package:soundhive2/services/loader_service.dart';
import 'package:soundhive2/services/fcm_service.dart';
import 'package:soundhive2/screens/creator/chat_screen/chats.dart';

import 'package:soundhive2/lib/dashboard_provider/call_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../screens/chats/call_screen.dart';


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
      // Read the login token now (authTokenProvider caches the value from app start).
      final authToken = await container.read(storageProvider).read(key: 'auth_token');
      if (authToken == null) {
        print("No auth token available - skipping FCM token refresh");
        return;
      }

      try {
        await container.read(dioProvider).post(
          '/notification/set-up',
          data: {'token': newToken, 'email': '', 'platform': Platform.isIOS ? 'ios' : 'android'},
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
  // Android channel (only applies to Android)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',              // id
    'Important Notifications',               // name
    description: 'This channel is used for important notifications',
    importance: Importance.high,
    // playSound: true,                      // optional
    // sound: RawResourceAndroidNotificationSound('custom_sound'), // if you have custom sound
  );

  // Create Android channel (safe — does nothing on iOS)
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // iOS / macOS initialization settings
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    // Optional: request permissions right away (recommended)
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    // If you want default notification sound → usually not needed
    // defaultPresentAlert: true,
    // defaultPresentBadge: true,
    // defaultPresentSound: true,
  );

  // Android initialization (you already had this)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon'); // ← make sure this icon exists

  // Combine both
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,           // ← this was missing
    // macOS: initializationSettingsDarwin,      // if you support macOS
  );

  // Initialize the plugin
  await notificationsPlugin.initialize(
    initializationSettings,
    // Very useful: handle when user taps a notification
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Tapping a notification shown while the app was open.
      try {
        final data = Map<String, dynamic>.from(jsonDecode(response.payload ?? '{}') as Map);
        _openFromData(data).ignore();
      } catch (_) {}
    },
    // onDidReceiveBackgroundNotificationResponse: ... (for background)
  );

  // Optional but strongly recommended for iOS:
  // Request permissions explicitly (especially iOS 10+)
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}
  // Future<void> _setupNotificationChannels() async {
  //   const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //     'high_importance_channel',
  //     'Important Notifications',
  //     description: 'This channel is used for important notifications',
  //     importance: Importance.high,
  //   );

  //   // Initialize plugin with icon
  //   const AndroidInitializationSettings initializationSettingsAndroid =
  //   AndroidInitializationSettings('app_icon');

  //   await notificationsPlugin.initialize(
  //     const InitializationSettings(
  //       android: initializationSettingsAndroid,
  //     ),
  //   );

  //   await notificationsPlugin
  //       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  //       ?.createNotificationChannel(channel);
  // }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _getFCMToken() async {
    // Signed in already? Re-register this phone with the server on every start, so a failed
    // registration or a rotated token never leaves the phone silent until the next login.
    // (The server links the token to whoever the login token belongs to.)
    final authToken = await container.read(storageProvider).read(key: 'auth_token');
    if (authToken != null && authToken.isNotEmpty) {
      FcmTokenService(container.read(dioProvider)).registerFcmToken('').ignore();
    }
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Already looking at this chat? Don't pop a notification over it.
      if (message.data['type'] == 'chat' && message.data['chat_id'] != null && message.data['chat_id'] == ActiveChat.id) {
        return;
      }
      _showNotification(message);
      container.read(notificationProvider.notifier).addNotification();
      container.read(notificationProvider.notifier).fetchUnreadCount();
      final type = message.data['type'] ?? '';
      if(type == 'wallet') {
        await container.read(userProvider.notifier).loadUserProfile();
      }

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
      // One notification per chat: a new message replaces the previous one.
      message.data['type'] == 'chat' ? (message.data['chat_id'] ?? '').hashCode : message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationInteraction(RemoteMessage message) {
    final data = message.data;

    if (data['type'] == 'incoming_call') {
      _handleIncomingCallNotification(data);
    } else {
      container.read(notificationProvider.notifier).clearNotifications();
      _openFromData(data).ignore();
    }
  }

  /// Where a tapped notification goes. Chat messages open the chat list.
  Future<void> _openFromData(Map<String, dynamic> data) async {
    if (data['type'] != 'chat') return;
    // This service has its own provider container, so the profile may not be loaded here yet.
    var user = container.read(userProvider).value;
    if (user == null) {
      try {
        await container.read(userProvider.notifier).loadUserProfile();
        user = container.read(userProvider).value;
      } catch (_) {}
    }
    final context = LoaderService.navigatorKey.currentContext;
    if (context == null || user == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatListScreen(user: user!)));
  }
  void _handleIncomingCallNotification(Map<String, dynamic> data) {
    // Parse caller data if it's a JSON string
    Map<String, dynamic> parsedData = Map.from(data);

    if (data['caller'] is String) {
      try {
        parsedData['caller'] = jsonDecode(data['caller']);
      } catch (e) {
        print('Error parsing caller data: $e');
      }
    }

    final context = LoaderService.navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
       
        title: const Text('Incoming Call', style: TextStyle(color: Colors.white)),
        content: Text('${parsedData['caller_name']} is calling you...',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectCallFromNotification(parsedData);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptCallFromNotification(parsedData);
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
      // Pass the data to show caller details
      _showCallScreenFromNotification(context, data);
    }
  }

  void _showCallScreenFromNotification(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            final callNotifier = ref.read(audioCallProvider.notifier);

            return AudioCallScreen(
              callerData: data,
              onEndCall: () {
                Navigator.pop(context);
                callNotifier.endCall();
              },
            );
          },
        ),
        fullscreenDialog: true,
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