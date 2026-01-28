import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/market_orders_service_model.dart';
import '../provider.dart';

final getMarketplaceServiceProvider = StateNotifierProvider<GetMyOrdersAssetNotifier, AsyncValue<MarketOrdersPaginatedModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetMyOrdersAssetNotifier(dio, storage);
});

class GetMyOrdersAssetNotifier extends StateNotifier<AsyncValue<MarketOrdersPaginatedModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  List<MarketOrder> _allServices = [];
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _isLastPage = false;
  Map<String, dynamic> _currentFilters = {};

  GetMyOrdersAssetNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  List<MarketOrder> get allServices => _allServices;
  bool get isLastPage => _isLastPage;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> resetMarketplaceState() async {
    _currentPage = 1;
    _allServices = [];
    _isLastPage = false;
    _currentFilters = {};
    state = const AsyncValue.loading();
    await getMarketPlaceService();
  }

  void resetFilters() {
    _currentFilters.clear();
    _currentPage = 1;
    _allServices = [];
    _isLastPage = false;
  }

  Future<void> getMarketPlaceService({
    bool loadMore = false,
    String? searchTerm,
    int? categoryId,
    int? subCategoryId,
    double? minRate,
    double? maxRate,
  }) async {
    try {
      if (_isLoadingMore) return;

      // Update loading states
      if (!loadMore) {
        state = const AsyncValue.loading();
        _currentPage = 1;
        _allServices = [];
        _isLastPage = false;
      } else {
        _isLoadingMore = true;
        _currentPage++;
      }

      // Build query parameters - NO HARDCODED pageSize
      final Map<String, dynamic> queryParams = {
        'page': _currentPage,
      };

      // Add filters
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['search_term'] = searchTerm;
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }
      if (subCategoryId != null) {
        queryParams['sub_category_id'] = subCategoryId;
      }
      if (minRate != null) {
        queryParams['min_rate'] = minRate;
      }
      if (maxRate != null) {
        queryParams['max_rate'] = maxRate;
      }

      final response = await _dio.get(
        '/marketplace',
        queryParameters: queryParams,
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final result = MarketOrdersPaginatedModel.fromMap(response.data);
      final newServices = result.data.data;

      // Update services list
      if (loadMore) {
        _allServices.addAll(newServices);
      } else {
        _allServices = newServices;
      }

      // Update state
      state = AsyncValue.data(result);

      // Check if we've reached the last page using API's pagination info
      _isLastPage = result.data.currentPage >= result.data.lastPage ||
          newServices.isEmpty;

      debugPrint('Page ${result.data.currentPage}/${result.data.lastPage}, Items: ${newServices.length}, Total: ${_allServices.length}, Last page: $_isLastPage');

    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      if (loadMore) _currentPage--;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> applyFilters({
    int? categoryId,
    double? minPrice,
    int? subCategoryId,
    double? maxPrice,
  }) async {
    _currentPage = 1;
    _allServices = [];
    _isLastPage = false;

    await getMarketPlaceService(
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      minRate: minPrice,
      maxRate: maxPrice,
    );
  }
}