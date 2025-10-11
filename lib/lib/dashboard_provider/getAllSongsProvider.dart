import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/artist_song_model.dart';
import '../provider.dart';
final getAllSongsProvider = StateNotifierProvider<GetAllSongsNotifier, AsyncValue<ArtistSongModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetAllSongsNotifier(dio, storage);
});

class GetAllSongsNotifier extends StateNotifier<AsyncValue<ArtistSongModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetAllSongsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getAllSongs({String? search, String? type}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _dio.get(
        '/songs/all',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final serviceResponse = ArtistSongModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

}