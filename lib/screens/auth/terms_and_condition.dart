import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/screens/auth/update_profile1.dart';
import 'package:soundhive2/utils/app_colors.dart';

import '../../services/loader_service.dart';
import '../../utils/alert_helper.dart';

class TermsAndCondition extends ConsumerStatefulWidget {
  static String id = 'terms_and_condition';
  final FlutterSecureStorage storage;
  final Dio dio;
  const TermsAndCondition({super.key, required this.dio, required this.storage});

  @override
  ConsumerState<TermsAndCondition> createState() => _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends ConsumerState<TermsAndCondition> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() => _hasReachedBottom = true);
    }
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveFormData() async {
    try {
      LoaderService.showLoader(context);
      Map<String, bool> payload = {
        "accepted_terms": true,
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await widget.dio.post(
          '/accept/terms',
          data: jsonEncode(payload),
          options: options
      );

      if (response.statusCode == 200) {
        LoaderService.hideLoader(context);
        final responseData = response.data;
        await widget.storage.write(key: 'role', value: responseData['data']['role']);
        Navigator.pushNamed(context, UpdateProfile1.id);
      }

      else {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Email OTP not verified',
        );
      }
    }
    catch(error) {
      LoaderService.hideLoader(context);
      if (error is DioError) {
        String errorMessage = "Failed, Please check input";

        if (error.response != null && error.response!.data != null) {
          Map<String, dynamic> responseData = error.response!.data;
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          } else if (responseData.containsKey('errors')) {
            Map<String, dynamic> errors = responseData['errors'];
            List<String> errorMessages = [];
            errors.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorMessages.addAll(value.map((error) => "$key: $error"));
              }
            });
            errorMessage = errorMessages.join("\n");
          }
        }
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
        return;
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
   
    body: SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset('images/logo.png', width: 200),
          ),
          const SizedBox(height: 40),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Last updated: 27 October, 2025\n\n'
                    'By creating an account or tapping “Agree”, you accept these Terms. Please do not proceed if you disagree.\n\n'
                    '1️⃣ Use of the App\n\n'
                    'Cre8hive includes:\n'
                    '• Cre8hive Marketplace – book and offer creative services\n'
                    '• Cre8Vest – access investment opportunities\n'
                    '• SoundHive Streaming – stream licensed content\n'
                    '• Cre8Pay Wallet – pay and receive funds within the ecosystem\n\n'
                    'You agree to use the App lawfully and not upload harmful, abusive, or infringing content.\n\n'
                    '2️⃣ Accounts & Security\n\n'
                    'Provide accurate information and keep your login secure. You are responsible for all activity under your account.\n\n'
                    '3️⃣ Payments & Wallet\n\n'
                    'Wallet funds are used to pay for services and receive earnings.\n'
                    '• Marketplace bookings are held in Escrow until confirmed\n'
                    '• Cleared earnings move to Actual Balance for withdrawal\n'
                    '• Multi-currency support may depend on verification and third-party processors (e.g., Stripe)\n'
                    'KYC and country restrictions may apply.\n\n'
                    '4️⃣ Content & Streaming\n\n'
                    'Streaming content is provided by creators and rights-holders. We do not guarantee uninterrupted or error-free playback. '
                    'Copyright rules must be respected — you may not copy, repost, or redistribute protected content.\n\n'
                    '5️⃣ Disputes & Enforcement\n\n'
                    'Disputes between Users and Creators may be reviewed by Cre8hive, whose decision will be final regarding payouts/refunds. '
                    'We may suspend or terminate accounts that violate these Terms.\n\n'
                    '6️⃣ Intellectual Property\n\n'
                    'All Cre8hive brand assets, software, and design belong to Cre8hive and must not be copied without permission.\n\n'
                    '7️⃣ Limitation of Liability\n\n'
                    'Cre8hive is provided “as is”. We are not liable for indirect or consequential damages resulting from use or unavailability of the App.\n\n'
                    '8️⃣ Changes & Contact\n\n'
                    'We may update these Terms occasionally. Continued use means continued acceptance.\n'
                    'For concerns or support, contact: support@cre8hiveapp.io',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Fixed bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Handle "I do not agree"
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF676579)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                    ),
                    child: const Text(
                      'I do not agree',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasReachedBottom
                        ? () {
                            _saveFormData();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasReachedBottom
                          ? const Color(0xFF924ACE)
                          : const Color(0xFF5F5873),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                    ),
                    child: const Text(
                      'Agree & continue',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


}