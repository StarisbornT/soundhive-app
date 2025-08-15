import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/category_model.dart';
import '../provider.dart';
final categoryProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<CategoryResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return CategoryNotifier(dio, storage);
});

class CategoryNotifier extends StateNotifier<AsyncValue<CategoryResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  CategoryNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getCategory() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/categories',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = CategoryResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}