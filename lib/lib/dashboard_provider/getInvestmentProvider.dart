import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/model/investment_model.dart';

import '../provider.dart';
final getInvestmentProvider = StateNotifierProvider<GetInvestmentNotifier, AsyncValue<InvestmentResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetInvestmentNotifier(dio, storage);
});

class GetInvestmentNotifier extends StateNotifier<AsyncValue<InvestmentResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetInvestmentNotifier(this._dio, this._storage) : super(const AsyncValue.loading()) {
    getInvestments(); // Auto-fetch data when the notifier is created
  }

  Future<void> getInvestments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/investment/list',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = InvestmentResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> getActiveInvestments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/investment/member-list',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = InvestmentResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}