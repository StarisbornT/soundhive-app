import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/model/chat_send_model.dart';

import '../../model/active_investment_model.dart';
import '../provider.dart';
final chatSendProvider = StateNotifierProvider<ChatSendNotifier, AsyncValue<ChatSendModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return ChatSendNotifier(dio, storage);
});

class ChatSendNotifier extends StateNotifier<AsyncValue<ChatSendModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ChatSendNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<ChatSendModel> sendMessage({
    required String receiverId,
    required String message,
}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post(
          '/member/message/create',
          data: jsonEncode({
            'receiver_id': receiverId,
            "message": message
          }),
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )

      );
      if (response.statusCode == 200) {
        final responseData = ChatSendModel.fromMap(response.data);
        state = AsyncValue.data(responseData);
        return responseData;
      } else {

        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}