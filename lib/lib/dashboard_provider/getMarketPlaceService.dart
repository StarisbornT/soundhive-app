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

  // Reset marketplace state
  Future<void> resetMarketplaceState() async {
    _currentPage = 1;
    _allServices = [];
    _isLastPage = false;
    _currentFilters = {};
    state = const AsyncValue.loading();
    await getMarketPlaceService();
  }

  String _currentSearch = '';
  int? _currentCategoryId;
  bool _hasMore = true;
  int? _currentSubCategoryId;

  void resetFilters() {
    _currentSearch = '';
    _currentCategoryId = null;
    _currentPage = 1;
    _hasMore = true;
  }

  // Get marketplace services with server-side filtering
  Future<void> getMarketPlaceService({
    bool loadMore = false,
    String? serviceName,
    String? creatorName,
    String? searchTerm, // NEW: Combined search parameter
    int? categoryId,
    int? subCategoryId,
    double? minRate,
    double? maxRate,
    String? provider,
    int? pageSize = 20,
  }) async {
    if (_isLastPage && loadMore) return;
    if (_isLoadingMore) return;

    if (!loadMore) {
      state = const AsyncValue.loading();
      _currentPage = 1;
      _allServices = [];
      _isLastPage = false;
    } else {
      _isLoadingMore = true;
    }

    // NEW: Handle combined search - use search_term parameter for backend
    if (searchTerm != null && searchTerm.isNotEmpty) {
      _currentFilters['search_term'] = searchTerm;
      // Remove individual service_name and creator_name when using combined search
      _currentFilters.remove('service_name');
      _currentFilters.remove('creator_name');
    } else {
      // Use individual filters if no combined search
      if (serviceName != null) _currentFilters['service_name'] = serviceName;
      if (creatorName != null) _currentFilters['creator_name'] = creatorName;
      _currentFilters.remove('search_term');
    }

    // Update other filters
    if (categoryId != null) _currentFilters['category_id'] = categoryId;
    if (subCategoryId != null) _currentFilters['sub_category_id'] = subCategoryId;
    if (minRate != null) _currentFilters['min_rate'] = minRate;
    if (maxRate != null) _currentFilters['max_rate'] = maxRate;
    if (provider != null) _currentFilters['provider'] = provider;

    try {
      final queryParams = {
        'page': _currentPage,
        'per_page': pageSize,
        ..._currentFilters,
      };

      // Remove null values from query parameters
      queryParams.removeWhere((key, value) => value == null);

      debugPrint('API Call: /marketplace?${queryParams.toString()}');

      final response = await _dio.get(
        '/marketplace',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final result = MarketOrdersPaginatedModel.fromMap(response.data);
      final newServices = result.data.data;

      _allServices.addAll(newServices);
      state = AsyncValue.data(result);

      if (newServices.isEmpty || result.data.currentPage >= result.data.lastPage) {
        _isLastPage = true;
      } else {
        _currentPage += 1;
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching marketplace: $error');
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoadingMore = false;
    }
  }

  void clearCategoryFilter() {
    _currentCategoryId = null;
    _currentSubCategoryId = null;
    _currentPage = 1;
    _hasMore = true;
  }

  // Apply filters from filter screen
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
      pageSize: 20,
    );
  }
}


