import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/screens/auth/otp_screen.dart';

import 'package:soundhive2/lib/interceptor.dart';
import 'package:soundhive2/lib/provider.dart';
import '../../utils/alert_helper.dart';
import '../../utils/app_colors.dart';

class CreateAccount extends StatefulWidget {
  final FlutterSecureStorage storage;
  final Dio dio;
  const CreateAccount({super.key, required this.storage, required this.dio});
  static String id = 'create_account';

  @override
  State<CreateAccount> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccount> {
  bool _isObscured = true;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  late Dio dio;
  bool _isPasswordValid = false;
  bool isLoading = false;

  @override
  void dispose() {
    passwordController.removeListener(_validatePassword);
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    dio = Dio();
    dio.interceptors.add(BaseUrlInterceptor());
    initializeDioLogger(dio);
    passwordController.addListener(_validatePassword);
    loadData();
  }


  String? identity;
  String? creatorIdentity;

  Future<void> loadData() async {
    String? storedEmail = await widget.storage.read(key: 'identity');
    String? storedIdentity = await widget.storage.read(key: 'creator_identity');
    print("Identity $storedEmail");
    setState(() {
      identity = storedEmail;
      creatorIdentity = storedIdentity;
    });
  }

  Future<void> _saveFormData() async {
    try {
      setState(() {
        isLoading = true;
      });
      Map<String, String> payload = {
        "email": emailController.text,
        "password": passwordController.text,
        "role": identity == "creator" ? "CREATOR" : "USER",
        'creator_role': creatorIdentity?.toUpperCase() ?? ""
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await dio.post(
          '/auth/register',
          data: jsonEncode(payload),
          options: options
      );
      print(response);
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        await widget.storage.write(key: 'identity', value: identity);
        await widget.storage.write(key: 'email', value: emailController.text);
        Navigator.pushNamed(context, OtpScreen.id);
      }
      else {
        setState(() {
          isLoading = false;
        });
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Account not Created',
        );
      }
    }
    catch(error) {
      setState(() {
        isLoading = false;
      });
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


  void _validatePassword() {
    final password = passwordController.text;
    final hasLowerCase = RegExp(r"[a-z]").hasMatch(password);
    final hasUpperCase = RegExp(r"[A-Z]").hasMatch(password);
    final hasNumber = RegExp(r"\d").hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    final hasMinLength = password.length >= 8;

    setState(() {
      _isPasswordValid = hasLowerCase && hasUpperCase && hasNumber && hasSpecialChar && hasMinLength;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Image.asset('images/logo.png', width: 200),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Create an account',
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
              // Password strength indicators
              _buildPasswordIndicators(),
              const SizedBox(height: 32),
              // Continue Button
              _buildButton(isLoading ? 'Loading' : 'Continue', AppColors.PRIMARYCOLOR),
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
              _buildSocialButton('Sign up with Google', 'images/google.png'),
              const SizedBox(height: 12),
              _buildSocialButton('Sign up with Facebook', 'images/facebook.png'),
              const SizedBox(height: 12),
              _buildSocialButton('Sign up with Apple ID', 'images/apple.png'),
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

  Widget _buildPasswordIndicators() {
    final password = passwordController.text;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildIndicator('Lower case', RegExp(r"[a-z]").hasMatch(password)),
            _buildIndicator('Upper case', RegExp(r"[A-Z]").hasMatch(password)),
            _buildIndicator('Number', RegExp(r"\d").hasMatch(password)),

          ],
        ),
        const SizedBox(height: 10,),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildIndicator('Special character', RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)),
            _buildIndicator('8 characters in length', password.length >= 8),
          ],
        )
      ],
    );
  }

  Widget _buildIndicator(String label, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.circle_outlined, color: isValid ? Colors.green : Colors.grey, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildButton(String text, Color color) {
    return GestureDetector(
      onTap: (!isLoading && _isPasswordValid) ? _saveFormData : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child:  Center(
          child: Text(
            text,
            style: const TextStyle(
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
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
