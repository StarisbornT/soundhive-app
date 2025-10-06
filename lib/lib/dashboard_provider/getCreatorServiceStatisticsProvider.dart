import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/creator_service_statistics_model.dart';
import '../provider.dart';
final getCreatorServiceStatistics = StateNotifierProvider<GetCreatorServiceStatisticsNotifier, AsyncValue<CreatorServiceStatisticsModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetCreatorServiceStatisticsNotifier(dio, storage);
});

class GetCreatorServiceStatisticsNotifier extends StateNotifier<AsyncValue<CreatorServiceStatisticsModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetCreatorServiceStatisticsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getStats() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/get-current-creator-statistics',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = CreatorServiceStatisticsModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}