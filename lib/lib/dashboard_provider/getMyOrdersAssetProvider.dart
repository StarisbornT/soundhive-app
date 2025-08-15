import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/market_orders_asset_purchase.dart';
import '../provider.dart';
final getMyOrdersAssetProvider = StateNotifierProvider<GetMyOrdersAssetNotifier, AsyncValue<MarketOrdersAssetPurchaseModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetMyOrdersAssetNotifier(dio, storage);
});

class GetMyOrdersAssetNotifier extends StateNotifier<AsyncValue<MarketOrdersAssetPurchaseModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetMyOrdersAssetNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getMyOrdersAssets() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/hive-assets/member/purchase-list',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = MarketOrdersAssetPurchaseModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}