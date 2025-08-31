import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/notification_model.dart';
import '../provider.dart';

final notificationApiProvider = StateNotifierProvider<NotificationApiNotifier, AsyncValue<NotificationModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return NotificationApiNotifier(dio, storage);
});

class NotificationApiNotifier extends StateNotifier<AsyncValue<NotificationModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  PaginatedNotifications? _paginatedData;

  NotificationApiNotifier(this._dio, this._storage) : super(const AsyncValue.loading()) {
    getNotifications();
  }

  Future<void> getNotifications({bool refresh = false}) async {
    if (refresh) {
      state = const AsyncValue.loading();
    }

    try {
      final response = await _dio.get(
        '/notifications',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final serviceResponse = NotificationModel.fromMap(response.data);
      _paginatedData = serviceResponse.data;
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_paginatedData?.nextPageUrl == null) return;

    try {

      final response = await _dio.get(
        _paginatedData!.nextPageUrl!,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final newData = NotificationModel.fromMap(response.data);
      _paginatedData = PaginatedNotifications(
        currentPage: newData.data.currentPage,
        notifications: [...?_paginatedData?.notifications, ...newData.data.notifications],
        firstPageUrl: newData.data.firstPageUrl,
        from: newData.data.from,
        lastPage: newData.data.lastPage,
        lastPageUrl: newData.data.lastPageUrl,
        links: newData.data.links,
        nextPageUrl: newData.data.nextPageUrl,
        path: newData.data.path,
        perPage: newData.data.perPage,
        prevPageUrl: newData.data.prevPageUrl,
        to: newData.data.to,
        total: newData.data.total,
      );

      state = AsyncValue.data(NotificationModel(
        success: true,
        data: _paginatedData!,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.put(
        '/notifications/$notificationId/read',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',

          },
        ),
      );

      // Update local state
      if (_paginatedData != null) {
        final updatedNotifications = _paginatedData!.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        _paginatedData = _paginatedData!.copyWith(notifications: updatedNotifications);
        state = AsyncValue.data(NotificationModel(
          success: true,
          data: _paginatedData!,
        ));
      }
    } catch (error) {
      // Silently fail - we can retry later
      debugPrint('Failed to mark notification as read: $error');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.post(
        '/notifications/mark-all-read',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',

          },
        ),
      );

      // Update local state
      if (_paginatedData != null) {
        final updatedNotifications = _paginatedData!.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();

        _paginatedData = _paginatedData!.copyWith(notifications: updatedNotifications);
        state = AsyncValue.data(NotificationModel(
          success: true,
          data: _paginatedData!,
        ));
      }
    } catch (error) {
      debugPrint('Failed to mark all notifications as read: $error');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(
        '/notifications/unread-count',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data['count'] ?? 0;
    } catch (error) {
      debugPrint('Failed to get unread count: $error');
      return 0;
    }
  }
}