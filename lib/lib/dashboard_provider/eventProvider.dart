import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/model/service_model.dart';
import '../../model/event_model.dart';
import '../provider.dart';
final eventProvider = StateNotifierProvider.family<EventNotifier, AsyncValue<EventResponse>, String>((ref, status) {
  final dio = ref.watch(dioProvider);
  final notifier = EventNotifier(dio);
  notifier.getEvent(status: status); // fetch on creation
  return notifier;
});


class EventNotifier extends StateNotifier<AsyncValue<EventResponse>> {
  final Dio _dio;

  EventNotifier(this._dio) : super(const AsyncValue.loading());

  Future<void> getEvent({required String status}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '/events/my-events',
        queryParameters: {
          'status': status.toUpperCase(),
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final serviceResponse = EventResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
