import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/model/asset_model.dart';
import 'package:soundhive2/model/service_model.dart';

import '../../services/loader_service.dart';
import '../provider.dart';
final serviceProvider = StateNotifierProvider.family<AssetsNotifier, AsyncValue<ServiceResponse>, String>((ref, status) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  final notifier = AssetsNotifier(dio, storage);
  notifier.getService(status: status); // fetch on creation
  return notifier;
});


class AssetsNotifier extends StateNotifier<AsyncValue<ServiceResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AssetsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getService({required String status}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '/member/service/list',
        queryParameters: {
          'per_page': 10,
          'status': status,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final serviceResponse = ServiceResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
