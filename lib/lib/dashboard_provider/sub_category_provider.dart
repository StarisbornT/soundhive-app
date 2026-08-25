import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/sub_categories.dart';
import '../provider.dart';

final subcategoryProvider = StateNotifierProvider<SubCategoryNotifier, AsyncValue<SubCategories>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return SubCategoryNotifier(dio, storage);
});

class SubCategoryNotifier extends StateNotifier<AsyncValue<SubCategories>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  int _currentPage = 1;
  bool _hasMore = true;
  int? _currentCategoryId;
  String _searchQuery = '';

  SubCategoryNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getSubCategory(int categoryId, {bool loadMore = false, String? searchQuery}) async {
    // Reset pagination if category changed or new search
    if (categoryId != _currentCategoryId || searchQuery != null) {
      _currentCategoryId = categoryId;
      _currentPage = 1;
      _hasMore = true;
      if (searchQuery != null) _searchQuery = searchQuery;
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
        '/categories/subcategory/$categoryId',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final serviceResponse = SubCategories.fromMap(response.data);

      if (loadMore && state.value != null) {
        final merged = SubCategories(
          status: serviceResponse.status,
          data: [...state.value!.data, ...serviceResponse.data],
          // carry over pagination meta if your model has it
        );
        state = AsyncValue.data(merged);
      } else {
        state = AsyncValue.data(serviceResponse);
      }

      _hasMore = serviceResponse.nextPageUrl != null;
      if (_hasMore) _currentPage++;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_hasMore && _currentCategoryId != null) {
      await getSubCategory(_currentCategoryId!, loadMore: true);
    }
  }

  Future<void> searchSubCategories(String query) async {
    if (_currentCategoryId != null) {
      await getSubCategory(_currentCategoryId!, searchQuery: query);
    }
  }

  void reset() {
    _currentPage = 1;
    _hasMore = true;
    _currentCategoryId = null;
    _searchQuery = '';
  }
}