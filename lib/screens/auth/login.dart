import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:soundhive2/screens/auth/terms_and_condition.dart';
import 'package:soundhive2/screens/auth/update_profile1.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../services/loader_service.dart';
import '../../utils/alert_helper.dart';
import '../../utils/app_colors.dart';
import '../dashboard/dashboard.dart';
import 'forgot_password.dart';
import 'otp_screen.dart';

class Login extends StatefulWidget {
  static String id = 'login';
  final FlutterSecureStorage storage;
  final Dio dio;
  const Login({super.key, required this.dio, required this.storage});


  @override
  State<Login> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login> {
  bool _isObscured = true;
  late Dio dio;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn.instance;

    // Initialize with serverClientId
    _googleSignIn.initialize(
      serverClientId: dotenv.env["CLIENT_SERVER_ID"],
    ).then((_) {
      // Listen to auth events
      _googleSignIn.authenticationEvents.listen(
        _handleGoogleAuthEvent,
        onError: _handleGoogleAuthError,
      );

    });
  }
  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }
  late final GoogleSignIn _googleSignIn;
  Future<void> _saveFormData() async {
    try {
      LoaderService.showLoader(context);
      Map<String, String> payload = {
        "email": emailController.text,
        "password": passwordController.text,
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await widget.dio.post(
          '/auth/login',
          data: jsonEncode(payload),
          options: options
      );

      if (response.statusCode == 200) {
        LoaderService.hideLoader(context);
        final responseData = response.data;

        await widget.storage.write(key: 'auth_token', value: responseData['token']);

        print("FULL RESPONSE: ${response.data}");


        if (responseData['user']['first_name'] != null) {
          Navigator.pushNamed(context, DashboardScreen.id);
        } else {
          Navigator.pushNamed(context, UpdateProfile1.id);
        }
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
      if (error is DioException) {
        if (error.response?.statusCode == 400) {

          await widget.storage.write(key: 'email', value: emailController.text);
          Navigator.pushNamed(context, OtpScreen.id);
          return;
        }
        if (error.response?.statusCode == 403) {
          final responseData = error.response?.data;

          await widget.storage.write(key: 'auth_token', value: responseData['token']);
          Navigator.pushNamed(context, TermsAndCondition.id);
          return;
        }
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
  Future<void> _signUpWithGoogle() async {
    try {
      LoaderService.showLoader(context);

      await _googleSignIn.authenticate(); // 👈 THIS starts the flow

    } catch (e) {
      LoaderService.hideLoader(context);
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Google sign in cancelled',
      );
    }
  }
  Future<void> _handleGoogleAuthEvent(event) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      final googleAuth = event.user;

      // ✅ ID TOKEN (this is what Firebase needs)
      final idToken = googleAuth.authentication.idToken;

      if (idToken == null) {
        throw Exception('No ID token');
      }

      // 🔥 Firebase credential (NO accessToken needed)
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) throw Exception('Firebase auth failed');

      await _sendGoogleUserToBackend(user);
    }

    LoaderService.hideLoader(context);
  }
  void _handleGoogleAuthError(Object error) {
    LoaderService.hideLoader(context);
    print("Google Error $error");
    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: 'Google authentication failed',
    );
  }



  Future<void> _sendGoogleUserToBackend(User user) async {
    final payload = {
      "email": user.email,
    };

    final response = await widget.dio.post(
      '/auth/login/google',
      data: jsonEncode(payload),
      options: Options(headers: {'Accept': 'application/json'}),
    );

   LoaderService.hideLoader(context);

    if (response.statusCode == 200) {
      final responseData = response.data;

      await widget.storage.write(key: 'auth_token', value: responseData['token']);

      print("FULL RESPONSE: ${response.data}");


      if (responseData['user']['first_name'] != null) {
        Navigator.pushNamed(context, DashboardScreen.id);
      } else {
        Navigator.pushNamed(context, UpdateProfile1.id);
      }
    } else {
      throw Exception("Backend auth failed");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C051F),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              // Logo
             Utils.logo(),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Login to your account',
                style: TextStyle(
                  fontFamily: 'Nohemi',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              // Email Field
              _buildTextField('Email address', 'Enter your email address', false, emailController),
              const SizedBox(height: 16),
              // Password Field
              _buildTextField('Password', 'Enter your password', true, passwordController),
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, ForgotPassword.id);
                  },
                  child: const Text(
                    'Forgot Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildButton('Login', AppColors.PRIMARYCOLOR),
              const SizedBox(height: 24),
              // OR Divider
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Or', style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(child: Divider(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 24),
              // Social Login Buttons
              _buildSocialButton(
                'Sign in with Google',
                'images/google.png',
                onTap: _signUpWithGoogle,
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, bool isPassword, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword ? _isObscured : false,
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () {
                setState(() {
                  _isObscured = !_isObscured; // Toggle state
                });
              },
            )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildButton(String text, Color color) {
    return GestureDetector(
      onTap: () {
        _saveFormData();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      String text,
      String asset, {
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, height: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
