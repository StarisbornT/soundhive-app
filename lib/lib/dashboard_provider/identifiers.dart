import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/identifier_model.dart';
import '../provider.dart';

final identifierProvider = StateNotifierProvider<IdentifiersNotifier, AsyncValue<List<IdentifierModel>>>((ref) {
  final dio = ref.watch(dioProvider);
  return IdentifiersNotifier(dio);
});

class IdentifiersNotifier extends StateNotifier<AsyncValue<List<IdentifierModel>>> {
  final Dio _dio;

  IdentifiersNotifier(this._dio) : super(const AsyncValue.loading());


  Future<void> loadIdentifier(String identifier) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/bills/get-identifiers/$identifier');
      final List<dynamic> dataList = response.data['data'];
      final identifiers = dataList
          .map((json) => IdentifierModel.fromJson(json))
          .toList();
      state = AsyncValue.data(identifiers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}