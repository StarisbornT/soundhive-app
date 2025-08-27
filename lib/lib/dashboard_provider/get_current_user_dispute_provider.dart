import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/dispute_model.dart';
import '../provider.dart';

final getCurrentUserDisputeProvider = StateNotifierProvider<GetCurrentUserDisputeNotifier, AsyncValue<DisputeModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetCurrentUserDisputeNotifier(dio, storage);
});

class GetCurrentUserDisputeNotifier extends StateNotifier<AsyncValue<DisputeModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetCurrentUserDisputeNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<DisputeModel?> getDispute({required int bookingId}) async {
    try {
      final response = await _dio.get('/dispute/current-user/$bookingId');
      final userData = DisputeModel.fromMap(response.data);
      state = AsyncValue.data(userData);
      return userData;
    } catch (error, stackTrace) {
      print("Failed to load profile: $error");
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

