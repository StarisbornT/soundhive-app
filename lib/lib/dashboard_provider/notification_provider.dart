import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider.dart';

final notificationProvider = StateNotifierProvider<NotificationNotifier, int>((ref) {
  return NotificationNotifier(ref);
});

class NotificationNotifier extends StateNotifier<int> {
  final Ref ref;
  NotificationNotifier(this.ref) : super(0) {
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchUnreadCount();
    _setupListener();
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await ref.read(dioProvider).get('/notifications/unread-count');
      state = response.data['count'] ?? 0;
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  void _setupListener() {
    // Listen to Firebase messages and update count
    FirebaseMessaging.onMessage.listen((_) {
      state++;
    });

    // When notification is opened, reset count
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      state = 0;
    });
  }

  void addNotification() => state++;
  void clearNotifications() => state = 0;
  void setCount(int count) => state = count;
}