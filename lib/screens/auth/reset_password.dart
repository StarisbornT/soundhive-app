import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../components/success.dart';
import '../../services/loader_service.dart';
import '../../utils/alert_helper.dart';
import 'login.dart';
import 'otp_screen.dart';

class ResetPassword extends StatefulWidget {
  static String id = 'reset_password';
  final FlutterSecureStorage storage;
  final Dio dio;
  const ResetPassword({super.key, required this.dio, required this.storage});


  @override
  State<ResetPassword> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPassword> {
  bool _isObscured = true;
  late Dio dio;
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }
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
  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
  Future<void> _saveFormData() async {
    print("Click");
    try {
      LoaderService.showLoader(context);
      Map<String, String> payload = {
        "email": email ?? '',
        "password": passwordController.text,
        "password_confirmation": confirmPasswordController.text,
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await widget.dio.post(
          '/auth/password/reset',
          data: jsonEncode(payload),
          options: options
      );

      if (response.statusCode == 200) {
        LoaderService.hideLoader(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              image: 'images/success_profile.png',
              title: 'Password Reset successfully',
              subtitle: '',
              onButtonPressed: () async {
                await widget.storage.deleteAll();
                await Future.delayed(Duration(milliseconds: 500));

                Map<String, String> allData = await widget.storage.readAll();
                print("Storage After Delete: $allData");
                Navigator.pushNamed(context, Login.id);
              },
            ),
          ),
        );

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
                'Reset Password',
                style: TextStyle(
                  fontFamily: 'Nohemi',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              // Password Field
              _buildTextField('Password', 'Enter your password', true, passwordController),
              const SizedBox(height: 16),
              _buildTextField('Confirm Password', 'Confirm your password', true, confirmPasswordController),
              const SizedBox(height: 16),

              _buildButton('Reset', const Color(0xFF4D3490)),
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
}
