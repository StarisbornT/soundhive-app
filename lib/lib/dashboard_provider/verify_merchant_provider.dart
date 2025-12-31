import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/verify_merchant_model.dart';
import '../provider.dart';

final verifyMerchantProvider = StateNotifierProvider<verifyMerchantNotifier, AsyncValue<VerifyMerchantResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return verifyMerchantNotifier(dio, storage);
});

class verifyMerchantNotifier extends StateNotifier<AsyncValue<VerifyMerchantResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  verifyMerchantNotifier(this._dio, this._storage) : super(const AsyncValue.loading());


  Future<VerifyMerchantResponse> verifyMerchant({
    required String serviceId,
    required String billersCode,
    String? type,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post(
          '/bills/verify-merchant',
          data: jsonEncode({
            'serviceID': serviceId,
            'billersCode': billersCode,
            'type': type ?? ''
          })
      );
      if(response.statusCode == 200) {
        final responseData = VerifyMerchantResponse.fromJson(response.data);
        state = AsyncValue.data(responseData);
        return responseData;
      }else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}