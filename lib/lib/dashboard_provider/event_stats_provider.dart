import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/event_stats_model.dart';
import '../provider.dart';
final eventStatsProvider = StateNotifierProvider<EventStatsNotifier, AsyncValue<EventStatsModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return EventStatsNotifier(dio, storage);
});

class EventStatsNotifier extends StateNotifier<AsyncValue<EventStatsModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  EventStatsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getStats() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/events/my-events/stats',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = EventStatsModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}