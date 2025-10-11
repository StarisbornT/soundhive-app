import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/artist_profile_id_model.dart';
import '../provider.dart';

final getArtistProfileByIdProvider = StateNotifierProvider<GetArtistProfileByIdNotifier, AsyncValue<ArtistProfileIdModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetArtistProfileByIdNotifier(dio, storage);
});

class GetArtistProfileByIdNotifier extends StateNotifier<AsyncValue<ArtistProfileIdModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetArtistProfileByIdNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getArtistProfile(int artistId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/artist-arena/artist/$artistId',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = ArtistProfileIdModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}