import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/investment_statistics_model.dart';
import '../provider.dart';
final getInvestmentStatisticsProvider = StateNotifierProvider<GetInvestmentStatisticsNotifier, AsyncValue<InvestmentStatisticsModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetInvestmentStatisticsNotifier(dio, storage);
});

class GetInvestmentStatisticsNotifier extends StateNotifier<AsyncValue<InvestmentStatisticsModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetInvestmentStatisticsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getBreakDown(int id) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/soundhive-vests/$id/statistics',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = InvestmentStatisticsModel.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}