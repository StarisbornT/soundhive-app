import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/screens/auth/login.dart';

import '../services/loader_service.dart';

class BaseUrlInterceptor extends Interceptor {
  @override
  Future onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final baseUrl = dotenv.env['BASE_URL'];

    if (baseUrl == null) {
      throw Exception("Base Url not found in .env.production file");
    }

    final uri = Uri.parse(options.uri.toString());
    final endpoint = uri.path;

    options.baseUrl = baseUrl;
    options.path = endpoint;

    return super.onRequest(options, handler);
  }
}

class TokenInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  TokenInterceptor({required this.storage});

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await storage.read(
      key: 'auth_token',
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    );

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      options.headers['Accept'] = 'application/json';
      options.headers['Content-Type'] = 'application/json';
    }

    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await storage.delete(key: 'auth_token');
      // Redirect to login using the navigator key
      LoaderService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Login.id,
            (route) => false,
      );
    }
    return super.onError(err, handler);
  }
}
