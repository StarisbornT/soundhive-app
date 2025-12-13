import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../provider.dart';

// Agora token request model
class AgoraTokenRequest {
  final String channelName;
  final int uid;
  final int? expireTime;

  AgoraTokenRequest({
    required this.channelName,
    required this.uid,
    this.expireTime = 3600,
  });

  Map<String, dynamic> toJson() {
    return {
      'channelName': channelName,
      'uid': uid,
      'expireTime': expireTime,
    };
  }
}

// Agora token response model
class AgoraTokenResponse {
  final String token;
  final int expireTime;

  AgoraTokenResponse({
    required this.token,
    required this.expireTime,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      token: json['token'] ?? '',
      expireTime: json['expireTime'] ?? 3600,
    );
  }
}

// Agora Token Provider using your existing pattern
final agoraTokenProvider = StateNotifierProvider<AgoraTokenNotifier, AsyncValue<String>>((ref) {
  final dio = ref.watch(dioProvider);
  return AgoraTokenNotifier(dio);
});

class AgoraTokenNotifier extends StateNotifier<AsyncValue<String>> {
  final Dio _dio;

  AgoraTokenNotifier(this._dio) : super(const AsyncValue.data(''));

  // Generate Agora token
  Future<String> generateToken(AgoraTokenRequest request) async {
    state = const AsyncValue.loading();

    try {
      // Replace with your actual endpoint
      final response = await _dio.post(
        '/agora/generate-token', // Your server endpoint for Agora tokens
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final tokenResponse = AgoraTokenResponse.fromJson(response.data);
        state = AsyncValue.data(tokenResponse.token);
        return tokenResponse.token;
      } else {
        throw Exception('Failed to generate token: ${response.statusCode}');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Clear token
  void clearToken() {
    state = const AsyncValue.data('');
  }
}