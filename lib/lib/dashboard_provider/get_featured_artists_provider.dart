import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/artists_model.dart';
import '../provider.dart';
final getFeaturedArtistProvider = StateNotifierProvider<GetFeaturedArtistsNotifier, AsyncValue<ArtistsModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetFeaturedArtistsNotifier(dio, storage);
});

class GetFeaturedArtistsNotifier extends StateNotifier<AsyncValue<ArtistsModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetFeaturedArtistsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getArtists() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/artist-arena/artists',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = ArtistsModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}