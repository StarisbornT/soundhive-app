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
  int _currentPage = 1;
  bool _isFetching = false;

  NotificationApiNotifier(this._dio, this._storage) : super(const AsyncValue.loading()) {
    getNotifications();
  }

  Future<void> getNotifications({bool refresh = false, int page = 1, bool append = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (refresh) {
      state = const AsyncValue.loading();
    }

    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'page': page},
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final serviceResponse = NotificationModel.fromMap(response.data);

      if (append && state.hasValue) {
        // Append new notifications to existing ones
        final oldData = state.value!;
        final combinedNotifications = [
          ...oldData.data.notifications,
          ...serviceResponse.data.notifications,
        ];

        final combinedData = NotificationModel(
          success: true,
          data: PaginatedNotifications(
            currentPage: serviceResponse.data.currentPage,
            notifications: combinedNotifications,
            firstPageUrl: serviceResponse.data.firstPageUrl,
            from: serviceResponse.data.from,
            lastPage: serviceResponse.data.lastPage,
            lastPageUrl: serviceResponse.data.lastPageUrl,
            links: serviceResponse.data.links,
            nextPageUrl: serviceResponse.data.nextPageUrl,
            path: serviceResponse.data.path,
            perPage: serviceResponse.data.perPage,
            prevPageUrl: serviceResponse.data.prevPageUrl,
            to: serviceResponse.data.to,
            total: serviceResponse.data.total,
          ),
        );

        state = AsyncValue.data(combinedData);
      } else {
        state = AsyncValue.data(serviceResponse);
      }

      _currentPage = serviceResponse.data.currentPage;

      print('Fetched page $_currentPage. Total notifications: ${serviceResponse.data.notifications.length}');
      print('Next page available: ${serviceResponse.data.nextPageUrl != null}');

    } catch (error, stackTrace) {
      print('Error fetching notifications: $error');
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    final nextPage = _currentPage + 1;

    // Check if we have more pages to load
    if (state.hasValue && nextPage <= state.value!.data.lastPage) {
      print('Loading more - page $nextPage');
      await getNotifications(page: nextPage, append: true);
    } else {
      print('No more pages to load. Current page: $_currentPage, Last page: ${state.value?.data.lastPage}');
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
      if (state.hasValue) {
        final currentData = state.value!;
        final updatedNotifications = currentData.data.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        final updatedData = NotificationModel(
          success: true,
          data: currentData.data.copyWith(notifications: updatedNotifications),
        );

        state = AsyncValue.data(updatedData);
      }
    } catch (error) {
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
      if (state.hasValue) {
        final currentData = state.value!;
        final updatedNotifications = currentData.data.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();

        final updatedData = NotificationModel(
          success: true,
          data: currentData.data.copyWith(notifications: updatedNotifications),
        );

        state = AsyncValue.data(updatedData);
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