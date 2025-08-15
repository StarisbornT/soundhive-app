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

  GetMyOrdersAssetNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  List<MarketOrder> get allServices => _allServices;

  // In your GetMyOrdersAssetNotifier
  Future<void> resetMarketplaceState() async {
    _currentPage = 1;
    _allServices = [];
    _isLastPage = false;
    state = const AsyncValue.loading();
    await getMarketPlaceService(); // Load fresh data without filters
  }

  Future<void> getMarketPlaceService({
    bool loadMore = false,
    String? serviceName,
    int? pageSize,
    String status = 'Pending',
  }) async {
    if (_isLastPage && loadMore) return;

    if (!loadMore) {
      state = const AsyncValue.loading();
      _currentPage = 1;
      _allServices = [];
      _isLastPage = false;
    }

    try {
      final response = await _dio.get(
        '/member/service/all-list',
        queryParameters: {
          'page': _currentPage,
          'per_page': pageSize,
          'status': status,
          if (serviceName != null && serviceName.isNotEmpty) 'service_name': serviceName,
        },
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

}

