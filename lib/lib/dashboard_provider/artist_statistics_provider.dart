import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/song_stats.dart';
import '../provider.dart';

final getArtistProfileStatistics = StateNotifierProvider<GetArtistProfileStatisticsNotifier, AsyncValue<SongStatsModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetArtistProfileStatisticsNotifier(dio, storage);
});

class GetArtistProfileStatisticsNotifier extends StateNotifier<AsyncValue<SongStatsModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetArtistProfileStatisticsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getStats() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/songs/artist/statistics',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = SongStatsModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}