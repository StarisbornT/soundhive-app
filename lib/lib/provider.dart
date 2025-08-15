import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'authInterceptor.dart';
import 'interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final storageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

void initializeDioLogger(Dio dio) {
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      compact: false,
    ),
  );
}

// Define a provider for Dio
final dioProvider = Provider<Dio>((ref) {
  final storage = FlutterSecureStorage();
  final dio = Dio();
  dio.interceptors.add(BaseUrlInterceptor());
  dio.interceptors.add(TokenInterceptor(storage: storage));
  dio.interceptors.add(AuthInterceptor(storage));
  initializeDioLogger(dio);
  return dio;
});

final recieptProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {};
});

final bottomNavigationBarIndexProvider = StateProvider<int>((ref) => 0);
