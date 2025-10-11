import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/category_model.dart';
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

  CreatorNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getCreators({int page = 1, bool append = false, String search = ''}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {'page': page};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
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
        final combined = CreatorListResponse(
          message: newResponse.message,
          user: oldData.user != null && newResponse.user != null
              ? CreatorPaginatedData(
            currentPage: newResponse.user!.currentPage,
            data: [...oldData.user!.data, ...newResponse.user!.data],
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
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> searchCreators(String searchQuery) async {
    // Reset to first page when searching
    await getCreators(page: 1, search: searchQuery);
  }

  Future<void> loadNextPage() async {
    final nextPage = _currentPage + 1;
    if (state.hasValue &&
        nextPage <= (state.value?.user?.lastPage ?? 1)) {
      await getCreators(page: nextPage, append: true, search: _currentSearch);
    }
  }

  void clearSearch() {
    _currentSearch = '';
    getCreators(page: 1);
  }
}

