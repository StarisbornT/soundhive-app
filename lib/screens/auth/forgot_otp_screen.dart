import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:soundhive2/screens/auth/reset_password.dart';
import 'package:soundhive2/screens/auth/update_profile1.dart';
import '../../services/fcm_service.dart';
import '../../services/loader_service.dart';
import '../../utils/alert_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotOtpScreen extends ConsumerStatefulWidget {

  final FlutterSecureStorage storage;
  final Dio dio;
  static String id = 'forgot_otp_screen';
  const ForgotOtpScreen({super.key, required this.storage, required this.dio});

  @override
  ConsumerState<ForgotOtpScreen> createState() => _ForgotOtpScreenScreenState();
}

class _ForgotOtpScreenScreenState extends ConsumerState<ForgotOtpScreen> with WidgetsBindingObserver  {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  late Dio dio;
  String? email;
  Future<void> loadData() async {
    try {
      final storedEmail = await widget.storage.read(key: 'email');
      if (mounted) {
        setState(() {
          email = storedEmail;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          email = null;
        });
      }
    }
  }
  String maskEmail(String? email) {
    if (email == null || !email.contains('@')) return 'Loading email...';

    List<String> parts = email.split('@');
    if (parts.length != 2) return 'Loading email...';

    String firstTwo = parts[0].substring(0, 2); // First two characters
    String domain = parts[1]; // Domain part
    return '$firstTwo***@$domain';
  }
  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addObserver(this);
    loadData();

    // Add this to handle app coming back from background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAppResume();
    });
  }
  void _onFocusChange() {
    if (_otpFocusNode.hasFocus) {
      // Ensure the OTP field is visible when focused
      Future.delayed(const Duration(milliseconds: 300), () {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleAppResume() {
    if (mounted) {
      loadData();
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _otpController.dispose();
    _otpFocusNode.removeListener(_onFocusChange);
    _otpFocusNode.dispose();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Use a delay to ensure the UI is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          loadData();
        }
      });
    }
  }

  Future<void> verify() async {
    if (!mounted || _otpController.text.isEmpty) return;
    try {
      LoaderService.showLoader(context);
      Map<String, String> payload = {
        "email": email ?? '',
        'otp': _otpController.text
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await widget.dio.post(
          '/auth/password/check-otp',
          data: jsonEncode(payload),
          options: options
      );
      if (!mounted) return;
      LoaderService.hideLoader(context);
      if (response.statusCode == 200) {
        final responseData = response.data;
        await widget.storage.write(key: 'email', value: email);
        Navigator.pushNamed(context, ResetPassword.id);
      }
      else {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Email OTP not verified',
        );
      }
    }on TimeoutException {
      if (!mounted) return;
      LoaderService.hideLoader(context);
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Timeout',
        message: 'Request timed out. Please try again.',
      );
    }
    catch(error) {
      LoaderService.hideLoader(context);
      if (error is DioError) {
        String errorMessage = "Login Failed, Please check input";

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
      backgroundColor: const Color(0xFF0C051F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/logo.png', height: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Soundhive',
                      style: TextStyle(
                        fontFamily: 'Nohemi',
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF2C2C2C),),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFB0AEB8), size: 24),
                ),
                const SizedBox(height: 24),
                // OTP Verification Title
                const Center(
                  child: Text(
                    'Verify your OTP',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Nohemi',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Email Information
                Center(
                  child: Text(
                    'We just sent an OTP to ${maskEmail(email)},\nkindly enter it below',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFB0AEB8),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // OTP Input Fields
                Center(
                  child: PinCodeTextField(
                    appContext: context,
                    length: 4,
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 50,
                      activeFillColor: Colors.transparent,
                      inactiveFillColor: Colors.transparent,
                      selectedFillColor: Colors.transparent,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white,
                      selectedColor: Colors.purple,
                    ),
                    cursorColor: Colors.white,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {},
                    onCompleted: (value) {},
                    beforeTextPaste: (text) => true,
                  ),
                ),
                const SizedBox(height: 32),

                // Verify OTP Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        verify();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3C98),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
