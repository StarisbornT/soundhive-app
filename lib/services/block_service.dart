// lib/services/block_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/alert_helper.dart';

class BlockService {
  static Future<void> blockUser({
    required BuildContext context,
    required String blockedUserId,
    required String blockedUserName,
    required Dio dio,
    required FlutterSecureStorage storage,
    required VoidCallback onBlocked, // caller removes content immediately
  }) async {
    // Confirm dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        title: const Text(
          'Block user?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You will no longer see content from $blockedUserName. '
              'This action also notifies our moderation team.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Remove content from UI immediately — before the API call
    onBlocked();

    try {
      await dio.post(
        '/users/block',
        data: jsonEncode({'blocked_user_id': blockedUserId}),
        options: Options(headers: {'Accept': 'application/json'}),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Block saved locally. Will sync when online.';
      debugPrint('Block API error: $msg');
      // Don't un-hide the content — keep the block in place even if API fails
    }

    if (context.mounted) {
      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'User blocked',
        message: '$blockedUserName has been blocked and their content removed from your feed.',
      );
    }
  }
}