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
  int _currentPage = 1;
  bool _isLastPage = false;
  bool _isLoadingMore = false;
  int? _sessionSeed;

  String? _searchTerm;
  int? _categoryId;
  int? _subCategoryId;
  double? _minRate;
  double? _maxRate;

  GetMyOrdersAssetNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  List<MarketOrder> get allServices => _allServices;
  bool get isLastPage => _isLastPage;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> resetMarketplaceState() async {
    _clearPaginationState();
    _clearFilters();
    _sessionSeed = null;
    state = const AsyncValue.loading();
    await _fetchServices();
  }

  Future<void> resetWithCurrentFilters() async {
    _clearPaginationState();
    _sessionSeed = null;
    state = const AsyncValue.loading();
    await _fetchServices();
  }

  Future<void> applyFilters({
    int? categoryId,
    int? subCategoryId,
    double? minPrice,
    double? maxPrice,
  }) async {
    _clearPaginationState();
    _sessionSeed = null;
    _categoryId = categoryId;
    _subCategoryId = subCategoryId;
    _minRate = minPrice;
    _maxRate = maxPrice;
    state = const AsyncValue.loading();
    await _fetchServices();
  }

  Future<void> getMarketPlaceService({
    bool loadMore = false,
    String? searchTerm,
    int? categoryId,
    int? subCategoryId,
    double? minRate,
    double? maxRate,
  }) async {
    if (loadMore) {
      await _fetchServices(loadMore: true);
    } else {
      _clearPaginationState();
      _sessionSeed = null;
      _searchTerm = searchTerm;
      _categoryId = categoryId;
      _subCategoryId = subCategoryId;
      _minRate = minRate;
      _maxRate = maxRate;
      state = const AsyncValue.loading();
      await _fetchServices();
    }
  }

  void resetFilters() {
    _clearPaginationState();
    _clearFilters();
    _sessionSeed = null;
  }

  Future<void> _fetchServices({bool loadMore = false}) async {
    if (_isLoadingMore) return;

    try {
      if (loadMore) {
        if (_isLastPage) return;
        _isLoadingMore = true;
        _currentPage++;
      }

      final Map<String, dynamic> params = {
        'page': _currentPage,
      };

      if (loadMore && _sessionSeed != null) {
        params['seed'] = _sessionSeed;
      }

      if (_searchTerm != null && _searchTerm!.isNotEmpty) {
        params['search_term'] = _searchTerm;
      }
      if (_categoryId != null) params['category_id'] = _categoryId;
      if (_subCategoryId != null) params['sub_category_id'] = _subCategoryId;
      if (_minRate != null) params['min_rate'] = _minRate;
      if (_maxRate != null) params['max_rate'] = _maxRate;

      final response = await _dio.get(
        '/marketplace',
        queryParameters: params,
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final result = MarketOrdersPaginatedModel.fromMap(response.data);
      final newServices = result.data.data;

      if (!loadMore && result.seed != null) {
        _sessionSeed = result.seed;
        debugPrint('🎲 New session seed: $_sessionSeed');
      }

      if (loadMore) {
        _allServices = [..._allServices, ...newServices];
      } else {
        _allServices = newServices;
      }

      _isLastPage = result.data.currentPage >= result.data.lastPage || newServices.isEmpty;

      state = AsyncValue.data(result);

      debugPrint(
        '📦 Page ${result.data.currentPage}/${result.data.lastPage} | '
            'Seed: $_sessionSeed | '
            'New: ${newServices.length} | '
            'Total: ${_allServices.length} | '
            'LastPage: $_isLastPage',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ Marketplace fetch error: $error');
      if (loadMore) _currentPage--;
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoadingMore = false;
    }
  }

  void _clearPaginationState() {
    _currentPage = 1;
    _allServices = [];
    _isLastPage = false;
    _isLoadingMore = false;
  }

  void _clearFilters() {
    _searchTerm = null;
    _categoryId = null;
    _subCategoryId = null;
    _minRate = null;
    _maxRate = null;
  }
} // Closing brace for the class