import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Push token registration with the Cre8Hive server.
///
/// The server ties the token to whoever is signed in (the login token is sent by the Dio
/// interceptor), so registering again after a different person logs in on this phone moves the
/// phone to them. Call [unregister] before logging out so the phone stops getting the old
/// account's notifications.
class FcmTokenService {
  final Dio dio;

  FcmTokenService(this.dio);

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Register this phone's push token for the signed-in user. Safe to call often.
  Future<void> registerFcmToken(String email) async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken == null) return;
        await dio.post(
          '/notification/set-up',
          data: {'token': fcmToken, 'email': email, 'platform': _platform},
          options: Options(headers: {'Accept': 'application/json'}),
        );
        return;
      } catch (e) {
        // A network or server hiccup must not delete a working token (it used to). Retry once;
        // the app also re-registers on its next start.
        print('Push token registration failed (attempt $attempt): $e');
        if (attempt == 1) await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  /// Before logging out: remove this phone from the account on the server, and get a fresh
  /// token for whoever signs in next. Never throws.
  Future<String?> unregister() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await dio.post('/notification/remove-token', data: {'token': token},
            options: Options(headers: {'Accept': 'application/json'}));
      }
      await FirebaseMessaging.instance.deleteToken();
      return token;
    } catch (e) {
      print('Push token removal failed: $e');
      return null;
    }
  }

  /// Ask the server to push a chat message the user just saved in Firebase. Fire and forget.
  static void notifyChatMessage(Dio dio, String chatId, String? messageId) {
    if (messageId == null || messageId.isEmpty) return;
    dio
        .post('/chat/notify',
            data: {'chat_id': chatId, 'message_id': messageId},
            options: Options(headers: {'Accept': 'application/json'}))
        .catchError((e) {
      print('Chat push request failed: $e');
      return Response(requestOptions: RequestOptions(path: '/chat/notify'));
    });
  }
}

/// Which chat is on screen right now, so a push for it isn't shown on top of it.
class ActiveChat {
  static String? id;
}
