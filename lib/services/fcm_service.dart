import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  final Dio dio;

  FcmTokenService(this.dio);

  Future<void> registerFcmToken(String email) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final options = Options(headers: {'Accept': 'application/json'});
      await dio.post(
        '/notification/set-up',
        data: {'token': fcmToken, "email": email},
          options: options
      );
      print("FCM token registered successfully");
    } on FirebaseException catch (e) {
      if (e.code == 'messaging/registration-token-not-registered') {
        print("Token invalidated - generating new token");
        await refreshFcmToken();
      } else {
        print("Firebase error: ${e.message}");
      }
    } on DioException catch (e) {
      print("Dio error: ${e.message}");
      if (e.response?.statusCode == 502) {
        print("Retrying after server error...");
        await Future.delayed(const Duration(seconds: 2));
        await refreshFcmToken();
      }
    } catch (e) {
      refreshFcmToken();
      print("Error registering FCM token: $e");
    }

  }

  Future<void> refreshFcmToken() async {
    try {
      // Delete invalid token
      await FirebaseMessaging.instance.deleteToken();

      // Generate new token
      final newToken = await FirebaseMessaging.instance.getToken();
      if (newToken == null) return;

      print("New FCM token generated: $newToken");
      // await registerFcmToken();
    } catch (e) {
      print("Error refreshing FCM token: $e");
    }
  }
}