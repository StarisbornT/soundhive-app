import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/category_model.dart';
import '../../model/creator_model.dart';
import '../provider.dart';
final creatorProvider = StateNotifierProvider<CreatorNotifier, AsyncValue<CreatorListResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return CreatorNotifier(dio, storage);
});

class CreatorNotifier extends StateNotifier<AsyncValue<CreatorListResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  CreatorNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getCreator() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/creator/list',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = CreatorListResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}