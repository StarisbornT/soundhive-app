import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/screens/auth/update_profile1.dart';
import 'package:soundhive2/lib/interceptor.dart';
import 'package:soundhive2/lib/provider.dart';
import '../../services/loader_service.dart';
import '../../utils/alert_helper.dart';
import '../dashboard/dashboard.dart';

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
    dio = Dio();
    dio.interceptors.add(BaseUrlInterceptor());
    initializeDioLogger(dio);
  }
  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }
  Future<void> _saveFormData() async {
    try {
      LoaderService.showLoader(context);
      Map<String, String> payload = {
        "email": emailController.text,
        "password": passwordController.text,
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await dio.post(
          '/auth/login',
          data: jsonEncode(payload),
          options: options
      );

      if (response.statusCode == 200) {
        LoaderService.hideLoader(context);
        final responseData = response.data;

        await widget.storage.write(key: 'auth_token', value: responseData['token']);

        print("FULL RESPONSE: ${response.data}");
        print("STATUS: ${responseData['member']['status']}");
        Navigator.pushNamed(context, DashboardScreen.id);


        if (responseData['member']['status'] == "uncompleted") {
          Navigator.pushNamed(context, UpdateProfile1.id);
        } else {
          Navigator.pushNamed(context, DashboardScreen.id);
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
      backgroundColor: const Color(0xFF0C051F),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('images/logo.png', height: 28),
                  const SizedBox(width: 3),
                  const Text(
                    'oundhive',
                    style: TextStyle(
                      fontFamily: 'Nohemi',
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
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
              const SizedBox(height: 16),

              _buildButton('Login', Color(0xFF4D3490)),
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
              _buildSocialButton('Login with Google', 'images/google.png'),
              const SizedBox(height: 12),
              _buildSocialButton('Login with Facebook', 'images/facebook.png'),
              const SizedBox(height: 12),
              _buildSocialButton('Login with Apple ID', 'images/apple.png'),
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
        Text(label, style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword ? _isObscured : false,
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white54),
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
          style: TextStyle(color: Colors.white),
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

  Widget _buildSocialButton(String text, String asset) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14),
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
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
