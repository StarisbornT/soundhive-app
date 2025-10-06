import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/user_model.dart';
import '../../screens/auth/login.dart';
import '../../screens/auth/update_profile1.dart';
import '../../services/loader_service.dart';
import '../auth_state_provider.dart';
import '../provider.dart';

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<MemberCreatorResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return UserNotifier(dio, storage, ref);
});

class UserNotifier extends StateNotifier<AsyncValue<MemberCreatorResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Ref _ref;

  UserNotifier(this._dio, this._storage, this._ref) : super(const AsyncValue.loading()) {
    loadUserProfile();
  }

  Future<MemberCreatorResponse?> loadUserProfile() async {
    try {
      final response = await _dio.get('/profile', options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          }
      ));
      final userData = MemberCreatorResponse.fromJson(response.data);
      state = AsyncValue.data(userData);
      if (userData.user?.firstName == null || userData.user!.firstName.isEmpty) {
        LoaderService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          UpdateProfile1.id,
              (route) => false,
        );
      }
      return userData;
    }on DioException catch (dioError, stackTrace) {
      if (dioError.response?.statusCode == 401) {
        // Handle 401 Unauthorized error
        print("Unauthorized access - redirecting to login");

        // Clear the auth token
        await _storage.delete(key: 'auth_token');

        // Clear the user state
        state = const AsyncValue.loading();

        // Redirect to login screen
        LoaderService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          Login.id,
              (route) => false,
        );

        _ref.read(authStateProvider.notifier).clearToken();
      }
      if (dioError.response?.statusCode == 401) {
        // Handle 401 Unauthorized error
        print("Unauthorized access - redirecting to login");

        // Clear the auth token
        await _storage.delete(key: 'auth_token');

        // Clear the user state
        state = const AsyncValue.loading();

        // Redirect to login screen
        LoaderService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          Login.id,
              (route) => false,
        );

        _ref.read(authStateProvider.notifier).clearToken();
      }else {
        // Handle other Dio errors
        print("Failed to load profile: $dioError");
        state = AsyncValue.error(dioError, stackTrace);
      }
      return null;
    }  catch (error, stackTrace) {
      print("Failed to load profile: $error");
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

