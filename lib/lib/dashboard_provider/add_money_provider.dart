
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/add_money_model.dart';
import '../../services/loader_service.dart';
import '../provider.dart';

final addMoneyProvider = StateNotifierProvider<AddMoneyNotifier, AsyncValue<void>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return AddMoneyNotifier(dio, storage);
});

class AddMoneyNotifier extends StateNotifier<AsyncValue<void>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AddMoneyNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<AddMoneyModel> addMoney({
    required BuildContext context,
    required double amount,
    required String currency
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/payment',
        data: jsonEncode({
          'amount': amount,
          'currency': currency
        }),
      );
      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return AddMoneyModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      LoaderService.hideLoader(context);
    }
  }
}