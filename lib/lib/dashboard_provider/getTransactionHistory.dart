import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/transaction_history_model.dart';
import '../provider.dart';
final getTransactionHistoryPlaceProvider = StateNotifierProvider<GetTransactionHistoryNotifier, AsyncValue<TransactionHistoryResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetTransactionHistoryNotifier(dio, storage);
});

class GetTransactionHistoryNotifier extends StateNotifier<AsyncValue<TransactionHistoryResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetTransactionHistoryNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getTransactionHistory(String accountId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/account/getstatement/$accountId?page=0&limit=100&fromDate=2015-07-04&toDate=2025-07-27&type=Debit',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = TransactionHistoryResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}