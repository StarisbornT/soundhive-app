import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/check_offer_model.dart';
import '../provider.dart';
final checkOfferProvider = StateNotifierProvider<CheckOfferNotifier, AsyncValue<CheckOfferModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return CheckOfferNotifier(dio, storage);
});

class CheckOfferNotifier extends StateNotifier<AsyncValue<CheckOfferModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  CheckOfferNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> checkOffer(int id) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/services/$id/check-offer',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = CheckOfferModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}