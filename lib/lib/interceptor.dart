import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  Future onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'auth_token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return super.onRequest(options, handler);
  }
}
