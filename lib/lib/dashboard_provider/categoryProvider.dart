import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/category_model.dart';
import '../provider.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<CategoryResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return CategoryNotifier(dio, storage);
});

class CategoryNotifier extends StateNotifier<AsyncValue<CategoryResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  int _currentPage = 1;
  String _searchQuery = '';
  bool _hasMore = true;

  CategoryNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getCategory({bool loadMore = false, String? searchQuery}) async {
    if (searchQuery != null) {
      _searchQuery = searchQuery;
      _currentPage = 1;
      _hasMore = true;
    }

    if (!loadMore) {
      state = const AsyncValue.loading();
    }

    try {
      final Map<String, dynamic> queryParams = {
        'page': _currentPage,
      };

      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final response = await _dio.get(
          '/categories',
          queryParameters: queryParams,
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );

      final serviceResponse = CategoryResponse.fromMap(response.data);

      if (loadMore && state.value != null) {
        // Merge with existing data
        final existingData = state.value!.data;
        final newData = serviceResponse.data;

        final mergedData = CategoryData(
          currentPage: newData.currentPage,
          data: [...existingData.data, ...newData.data],
          firstPageUrl: newData.firstPageUrl,
          from: newData.from,
          lastPage: newData.lastPage,
          lastPageUrl: newData.lastPageUrl,
          links: newData.links,
          nextPageUrl: newData.nextPageUrl,
          path: newData.path,
          perPage: newData.perPage,
          prevPageUrl: newData.prevPageUrl,
          to: newData.to,
          total: newData.total,
        );

        final mergedResponse = CategoryResponse(
          status: serviceResponse.status,
          data: mergedData,
        );

        state = AsyncValue.data(mergedResponse);
      } else {
        state = AsyncValue.data(serviceResponse);
      }

      // Update pagination state
      _hasMore = serviceResponse.data.nextPageUrl != null;
      if (_hasMore) {
        _currentPage++;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchCategories(String query) async {
    await getCategory(searchQuery: query);
  }

  Future<void> loadMore() async {
    if (_hasMore) {
      await getCategory(loadMore: true);
    }
  }

  void resetSearch() {
    _searchQuery = '';
    _currentPage = 1;
    _hasMore = true;
  }
}