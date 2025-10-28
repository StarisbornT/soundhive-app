import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/market_orders_service_model.dart';
import '../provider.dart';
final getCreatorServiceProvider = StateNotifierProvider<
    GetCreatorServicesNotifier, AsyncValue<List<MarketOrder>>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetCreatorServicesNotifier(dio, storage);
});

class GetCreatorServicesNotifier
    extends StateNotifier<AsyncValue<List<MarketOrder>>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetCreatorServicesNotifier(this._dio, this._storage)
      : super(const AsyncValue.loading());

  Future<void> getCreatorService({
    required String memberId,
    required int perPage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '/creator-services/$memberId',
        queryParameters: {
          'per_page': perPage,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final List<dynamic> data = response.data["data"]['data'];
      final services =
      data.map((e) => MarketOrder.fromMap(e)).toList();

      state = AsyncValue.data(services);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

