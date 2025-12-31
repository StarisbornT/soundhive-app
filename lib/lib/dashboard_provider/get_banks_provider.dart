import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/get_banks_model.dart';
import '../provider.dart';
final getBanksProvider = StateNotifierProvider<GetBanksNotifier, AsyncValue<GetBanksResponseModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetBanksNotifier(dio, storage);
});

class GetBanksNotifier extends StateNotifier<AsyncValue<GetBanksResponseModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetBanksNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getBanks() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/fincra/get-banks',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = GetBanksResponseModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}