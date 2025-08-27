
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/lib/provider.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(storageProvider));
});

class AuthState {
  final String? token;
  final bool isLoading;

  AuthState({this.token, this.isLoading = true});
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;

  AuthStateNotifier(this._storage) : super(AuthState()) {
    // Initialize auth state
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await _storage.read(
        key: 'auth_token',
        aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      );
      state = AuthState(token: token, isLoading: false);
    } catch (e) {
      state = AuthState(token: null, isLoading: false);
    }
  }

  Future<void> setToken(String token) async {
    try {
      await _storage.write(
        key: 'auth_token',
        value: token,
        aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      );
      state = AuthState(token: token, isLoading: false);
    } catch (e) {
      state = AuthState(token: null, isLoading: false);
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'auth_token');
      state = AuthState(token: null, isLoading: false);
    } catch (e) {
      state = AuthState(token: null, isLoading: false);
    }
  }
}