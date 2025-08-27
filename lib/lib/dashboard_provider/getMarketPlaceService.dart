import 'package:dio/dio.dart';
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
  Map<String, dynamic> _currentFilters = {};

  GetMyOrdersAssetNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  List<MarketOrder> get allServices => _allServices;
  bool get isLastPage => _isLastPage;

  // Reset marketplace state
  Future<void> resetMarketplaceState() async {
    _currentPage = 1;
    _allServices = [];
    _isLastPage = false;
    _currentFilters = {};
    state = const AsyncValue.loading();
    await getMarketPlaceService();
  }

  // Get marketplace services with server-side filtering
  Future<void> getMarketPlaceService({
    bool loadMore = false,
    String? serviceName,
    int? categoryId,
    double? minRate,
    double? maxRate,
    String? provider,
    int? pageSize = 20,
  }) async {
    if (_isLastPage && loadMore) return;

    if (!loadMore) {
      state = const AsyncValue.loading();
      _currentPage = 1;
      _allServices = [];
      _isLastPage = false;
    }

    // Update current filters
    if (serviceName != null) _currentFilters['service_name'] = serviceName;
    if (categoryId != null) _currentFilters['category_id'] = categoryId;
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
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Apply filters from filter screen
  Future<void> applyFilters({
    int? categoryId,
    double? minPrice,
    double? maxPrice,
  }) async {
    _currentPage = 1;
    _allServices = [];
    _isLastPage = false;

    await getMarketPlaceService(
      categoryId: categoryId,
      minRate: minPrice,
      maxRate: maxPrice,
      pageSize: 20,
    );
  }
}


