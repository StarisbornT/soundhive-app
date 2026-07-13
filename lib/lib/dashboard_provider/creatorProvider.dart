import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/creator_model.dart';
import '../provider.dart';
final creatorProvider = StateNotifierProvider<CreatorNotifier, AsyncValue<CreatorListResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return CreatorNotifier(dio, storage);
});

class CreatorNotifier extends StateNotifier<AsyncValue<CreatorListResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  int _currentPage = 1;
  bool _isFetching = false;
  String _currentSearch = '';
  bool _currentNearby = false;
  double? _currentRadiusKm;

  CreatorNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getCreators({
    int page = 1,
    bool append = false,
    String search = '',
    bool nearby = false,
    double? radiusKm,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final Map<String, dynamic> queryParams = {'page': page};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      } else if (nearby) {
        queryParams['nearby'] = true;
        if (radiusKm != null) {
          queryParams['radius_km'] = radiusKm;
        }
      }

      final response = await _dio.get(
        '/creators',
        queryParameters: queryParams,
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final newResponse = CreatorListResponse.fromMap(response.data);

      if (append && state.hasValue && search == _currentSearch) {
        final oldData = state.value!;

        final existingIds = oldData.user!.data.map((c) => c.id).toSet();
        final deduped = newResponse.user!.data.where((c) => !existingIds.contains(c.id)).toList();

        final combined = CreatorListResponse(
          message: newResponse.message,
          user: oldData.user != null && newResponse.user != null
              ? CreatorPaginatedData(
            currentPage: newResponse.user!.currentPage,
            data: [...oldData.user!.data, ...deduped],
            firstPageUrl: newResponse.user!.firstPageUrl,
            from: newResponse.user!.from,
            lastPage: newResponse.user!.lastPage,
            lastPageUrl: newResponse.user!.lastPageUrl,
            links: newResponse.user!.links,
            nextPageUrl: newResponse.user!.nextPageUrl,
            path: newResponse.user!.path,
            perPage: newResponse.user!.perPage,
            prevPageUrl: newResponse.user!.prevPageUrl,
            to: newResponse.user!.to,
            total: newResponse.user!.total,
          )
              : newResponse.user,
        );
        state = AsyncValue.data(combined);
      } else {
        state = AsyncValue.data(newResponse);
      }

      _currentPage = newResponse.user?.currentPage ?? 1;
      _currentSearch = search;
      _currentNearby = search.isEmpty ? nearby : false;
      _currentRadiusKm = search.isEmpty ? radiusKm : null;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> searchCreators(String searchQuery) async {
    await getCreators(page: 1, search: searchQuery);
  }

  /// Loads creators sorted by distance from the user's own stored location.
  Future<void> getNearbyCreators({double radiusKm = 25}) async {
    await getCreators(page: 1, nearby: true, radiusKm: radiusKm);
  }

  Future<void> loadNextPage() async {
    final nextPage = _currentPage + 1;
    if (state.hasValue &&
        nextPage <= (state.value?.user?.lastPage ?? 1)) {
      await getCreators(
        page: nextPage,
        append: true,
        search: _currentSearch,
        nearby: _currentNearby,
        radiusKm: _currentRadiusKm,
      );
    }
  }

  /// Fetches a single creator by ID — used for deep links and direct navigation,
  /// where only an ID is available rather than a full CreatorData object.
  /// Does not touch `state`; returns the creator directly so callers can
  /// manage their own loading/error UI independently of the list state.
  Future<CreatorData> getCreatorById(int id) async {
    final response = await _dio.get(
      '/creators/$id',
      options: Options(headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }),
    );

    if (response.statusCode == 200 && response.data['creator'] != null) {
      return CreatorData.fromJson(response.data['creator']);
    }

    throw Exception(response.data['message'] ?? 'Creator not found');
  }

  void clearSearch() {
    _currentSearch = '';
    _currentNearby = false;
    _currentRadiusKm = null;
    getCreators(page: 1);
  }
}