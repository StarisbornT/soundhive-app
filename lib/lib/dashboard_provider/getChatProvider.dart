import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/chat_response.dart';
import '../provider.dart';
final getChatProvider = StateNotifierProvider<GetChatNotifier, AsyncValue<List<ChatData>>>((ref) {

  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetChatNotifier(dio, storage);
});

class GetChatNotifier extends StateNotifier<AsyncValue<List<ChatData>>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  GetChatNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getChat(String memberId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/message/$memberId',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      try {
        final chatResponse = ChatResponse.fromJson(response.data);
        state = AsyncValue.data(chatResponse.data);
      } catch (e) {
        state = AsyncValue.error(
          'Invalid API response format: ${e.toString()}',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}