import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/user_model.dart';
import '../provider.dart';

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<MemberCreatorResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return UserNotifier(dio, storage);
});

class UserNotifier extends StateNotifier<AsyncValue<MemberCreatorResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  UserNotifier(this._dio, this._storage) : super(const AsyncValue.loading()) {
    loadUserProfile();
  }

  Future<MemberCreatorResponse?> loadUserProfile() async {
    try {
      final response = await _dio.get('/member/profile');
      final userData = MemberCreatorResponse.fromJson(response.data);
      state = AsyncValue.data(userData);
      return userData;
    } catch (error, stackTrace) {
      print("Failed to load profile: $error");
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

