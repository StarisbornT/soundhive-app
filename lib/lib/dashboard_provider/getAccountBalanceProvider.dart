import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/user_model.dart';
import '../../model/walletBalanceModel.dart';
import '../provider.dart';

final getAccountBalance = StateNotifierProvider<AccountBalanceNotifier, AsyncValue<WalletBalanceModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return AccountBalanceNotifier(dio, storage);
});

class AccountBalanceNotifier extends StateNotifier<AsyncValue<WalletBalanceModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AccountBalanceNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<WalletBalanceModel?> getAccountBalance(String verifyId) async {
    try {
      final response = await _dio.get('/member/account/getbalance/$verifyId');
      final userData = WalletBalanceModel.fromMap(response.data);
      state = AsyncValue.data(userData);
      return userData;
    } catch (error, stackTrace) {
      print("Failed to load profile: $error");
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

