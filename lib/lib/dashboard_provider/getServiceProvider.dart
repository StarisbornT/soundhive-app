import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/model/service_model.dart';

import '../../model/asset_market_response.dart';
import '../../model/asset_model.dart';
import '../provider.dart';
final getServiceMarketPlaceProvider = StateNotifierProvider<GetServiceMarketPlaceNotifier, AsyncValue<ServiceResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetServiceMarketPlaceNotifier(dio, storage);
});

class GetServiceMarketPlaceNotifier extends StateNotifier<AsyncValue<ServiceResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetServiceMarketPlaceNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getServiceMarketPlace() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/hive-services/list',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = ServiceResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}