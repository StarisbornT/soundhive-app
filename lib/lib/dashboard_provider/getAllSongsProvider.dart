import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/artist_song_model.dart';
import '../provider.dart';
final getAllSongsProvider = StateNotifierProvider<GetAllSongsNotifier, AsyncValue<DeepFreezerModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetAllSongsNotifier(dio, storage);
});

class GetAllSongsNotifier extends StateNotifier<AsyncValue<DeepFreezerModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  int _page = 1;
  bool _hasMore = true;
  String _currentQuery = '';
  List<SongItemData> _songs = [];

  GetAllSongsNotifier(this._dio, this._storage)
      : super(const AsyncValue.loading());

  Future<void> searchSongs(String? search) async {
    _page = 1;
    _songs.clear();
    _hasMore = true;
    _currentQuery = search ?? '';

    await _fetchSongs();
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    _page++;
    await _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    try {
      final response = await _dio.get(
        '/songs/spotify',
        queryParameters: {
          'q': _currentQuery,
          'page': _page,
          'limit': 25,
        },
      );

      final model = DeepFreezerModel.fromMap(response.data);

      _hasMore = model.hasMore;

      _songs.addAll(model.data);

      state = AsyncValue.data(
        DeepFreezerModel(
          status: model.status,
          page: _page,
          limit: model.limit,
          total: model.total,
          hasMore: _hasMore,
          data: _songs,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}