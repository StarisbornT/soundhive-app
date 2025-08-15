import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/model/catelogue_breakdown_model.dart';
import '../provider.dart';
final getBreakDownProvider = StateNotifierProvider<GetBreakDownNotifier, AsyncValue<CatalogueBreakdownModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetBreakDownNotifier(dio, storage);
});

class GetBreakDownNotifier extends StateNotifier<AsyncValue<CatalogueBreakdownModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetBreakDownNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getBreakDown() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/catalogue-service-breakdown',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = CatalogueBreakdownModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}