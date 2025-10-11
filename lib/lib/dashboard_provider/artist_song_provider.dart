
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/artist_song_model.dart';
import '../provider.dart';
final artistSongProvider = StateNotifierProvider.family<ArtistSongNotifier, AsyncValue<ArtistSongModel>, String>((ref, status) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  final notifier = ArtistSongNotifier(dio, storage);
  notifier.getArtistSongs(status: status); // fetch on creation
  return notifier;
});


class ArtistSongNotifier extends StateNotifier<AsyncValue<ArtistSongModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ArtistSongNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getArtistSongs({required String status}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '/songs',
        queryParameters: {
          'status': status.toUpperCase(),
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final serviceResponse = ArtistSongModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
