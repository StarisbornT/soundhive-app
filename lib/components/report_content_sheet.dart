// lib/components/report_content_sheet.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lib/provider.dart';
import '../utils/alert_helper.dart';

enum ReportReason {
  objectionableContent('Objectionable content'),
  harassment('Harassment or bullying'),
  spam('Spam or misleading'),
  hateSpeech('Hate speech'),
  violence('Violence or threats'),
  other('Other');

  const ReportReason(this.label);
  final String label;
}

class ReportContentSheet extends ConsumerStatefulWidget {
  final String contentId;
  final String contentType; // 'track', 'post', 'comment', etc.
  final String reportedUserId;

  const ReportContentSheet({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.reportedUserId,
  });

  static Future<void> show({
    required BuildContext context,
    required String contentId,
    required String contentType,
    required String reportedUserId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportContentSheet(
        contentId: contentId,
        contentType: contentType,
        reportedUserId: reportedUserId,
      ),
    );
  }

  @override
  ConsumerState<ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends ConsumerState<ReportContentSheet> {
  ReportReason? _selected;
  bool _isSubmitting = false;

  Future<void> _submit() async {
   final dio = ref.watch(dioProvider);
    if (_selected == null) return;
    setState(() => _isSubmitting = true);

    try {
      await dio.post(
        '/reports',
        data: {
          'content_id': widget.contentId,
          'content_type': widget.contentType,
          'reported_user_id': widget.reportedUserId,
          'reason': _selected!.name,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (mounted) {
        Navigator.pop(context);
        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Report submitted',
          message: 'Thank you. Our moderation team will review this within 24 hours.',
        );
      }
    } on DioException catch (e) {
      setState(() => _isSubmitting = false);
      final msg = e.response?.data?['message'] ?? 'Failed to submit report. Please try again.';
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: msg,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Report content',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Select a reason. Reports are reviewed by our moderation team within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
            value: reason,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v),
            title: Text(
              reason.label,
              style: const TextStyle(color: Colors.white),
            ),
            activeColor: const Color(0xFF924ACE),
          )),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selected != null && !_isSubmitting) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF924ACE),
                  disabledBackgroundColor: const Color(0xFF5F5873),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Submit report',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}