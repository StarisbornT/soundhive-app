import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/variation_model.dart';
import '../provider.dart';

final variationProvider = StateNotifierProvider<VariationNotifier, AsyncValue<List<ServiceVariation>>>((ref) {
  final dio = ref.watch(dioProvider);
  return VariationNotifier(dio);
});

class VariationNotifier extends StateNotifier<AsyncValue<List<ServiceVariation>>> {
  final Dio _dio;

  VariationNotifier(this._dio) : super(const AsyncValue.loading());

  Future<void> loadServiceVariation(String serviceId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/bills/get-variations/$serviceId');
      final List<dynamic> dataList = response.data['data'];
      final variations = dataList
          .map((json) => ServiceVariation.fromJson(json))
          .toList();
      state = AsyncValue.data(variations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}