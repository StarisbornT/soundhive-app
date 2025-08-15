import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/asset_market_response.dart';
import '../../model/asset_model.dart';
import '../provider.dart';
final getMarketPlaceProvider = StateNotifierProvider<GetMarketPlaceNotifier, AsyncValue<AssetMarketResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetMarketPlaceNotifier(dio, storage);
});

class GetMarketPlaceNotifier extends StateNotifier<AsyncValue<AssetMarketResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetMarketPlaceNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getMarketPlace(String status) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/hive-assets/list',
          queryParameters: {
            'status': status,
          },
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = AssetMarketResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}