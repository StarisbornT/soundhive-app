import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/sub_categories.dart';
import '../provider.dart';
final subcategoryProvider = StateNotifierProvider<SubCategoryNotifier, AsyncValue<SubCategories>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return SubCategoryNotifier(dio, storage);
});

class SubCategoryNotifier extends StateNotifier<AsyncValue<SubCategories>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  SubCategoryNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getSubCategory(int categoryId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/categories/subcategory/$categoryId',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = SubCategories.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}