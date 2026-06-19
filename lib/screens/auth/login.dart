import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    _googleSignIn
        .initialize(
      serverClientId: dotenv.env["CLIENT_SERVER_ID"],
    )
        .then((_) {
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
        "email": emailController.text.toLowerCase(),
        "password": passwordController.text,
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await widget.dio
          .post('/auth/login', data: jsonEncode(payload), options: options);

      if (response.statusCode == 200) {
        LoaderService.hideLoader(context);
        final responseData = response.data;

        await widget.storage
            .write(key: 'auth_token', value: responseData['token']);

        final firebaseToken = responseData['firebase_token'];
        if (firebaseToken != null) {
          await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
        }

        print("FULL RESPONSE: ${response.data}");

        if (responseData['user']['first_name'] != null) {
          Navigator.pushNamed(context, DashboardScreen.id);
        } else {
          Navigator.pushNamed(context, UpdateProfile1.id);
        }
      } else {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Email OTP not verified',
        );
      }
    } catch (error) {
      LoaderService.hideLoader(context);
      if (error is DioException) {
        if (error.response?.statusCode == 400) {
          await widget.storage.write(key: 'email', value: emailController.text);
          Navigator.pushNamed(context, OtpScreen.id);
          return;
        }
        if (error.response?.statusCode == 403) {
          final responseData = error.response?.data;

          await widget.storage
              .write(key: 'auth_token', value: responseData['token']);
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

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String? _emailFromAppleIdentityToken(String? identityToken) {
    if (identityToken == null) return null;
    try {
      final parts = identityToken.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is Map && payload['email'] is String) {
        return payload['email'] as String;
      }
    } catch (_) {}
    return null;
  }

  String _appleEmailStorageKey(String userIdentifier) =>
      'apple_email_$userIdentifier';

  Future<String?> _resolveAppleEmail(
    AuthorizationCredentialAppleID appleCredential,
  ) async {
    final tokenEmail =
        _emailFromAppleIdentityToken(appleCredential.identityToken);
    final credentialEmail = appleCredential.email ?? tokenEmail;

    if (credentialEmail != null && credentialEmail.isNotEmpty) {
      if (appleCredential.userIdentifier != null) {
        await widget.storage.write(
          key: _appleEmailStorageKey(appleCredential.userIdentifier!),
          value: credentialEmail.toLowerCase(),
        );
      }
      return credentialEmail.toLowerCase();
    }

    if (appleCredential.userIdentifier != null) {
      final storedEmail = await widget.storage.read(
        key: _appleEmailStorageKey(appleCredential.userIdentifier!),
      );
      if (storedEmail != null && storedEmail.isNotEmpty) {
        return storedEmail.toLowerCase();
      }
    }

    return null;
  }

  Future<String?> _emailFromFirebaseAppleAuth(
    AuthorizationCredentialAppleID appleCredential,
    String rawNonce,
  ) async {
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    final user = userCredential.user;
    if (user == null) return null;

    try {
      await user.reload();
    } catch (_) {}

    return FirebaseAuth.instance.currentUser?.email ?? user.email;
  }

  Future<void> _signUpWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Sign in with Apple is not available on this device.',
        );
        return;
      }

      LoaderService.showLoader(context);

      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCredential.identityToken == null) {
        throw Exception('Apple Sign In did not return an identity token');
      }

      var email = await _resolveAppleEmail(appleCredential);

      email ??= await _emailFromFirebaseAppleAuth(appleCredential, rawNonce);

      if (email != null &&
          appleCredential.userIdentifier != null &&
          email.isNotEmpty) {
        await widget.storage.write(
          key: _appleEmailStorageKey(appleCredential.userIdentifier!),
          value: email.toLowerCase(),
        );
      }

      if (email == null || email.isEmpty) {
        LoaderService.hideLoader(context);
        _showAppleEmailUnavailableAlert();
        return;
      }

      await _completeSocialLogin(email);
    } on SignInWithAppleAuthorizationException catch (e) {
      LoaderService.hideLoader(context);
      if (e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Apple sign in failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      LoaderService.hideLoader(context);
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: _firebaseAuthErrorMessage(e),
      );
    } catch (e) {
      LoaderService.hideLoader(context);
      debugPrint('Apple sign in error: $e');
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: e is DioException
            ? _dioErrorMessage(e, fallback: 'Apple sign in failed.')
            : 'Apple sign in failed. Please try again.',
      );
    }
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Apple Sign In is not enabled in Firebase. Please contact support.';
      case 'invalid-credential':
        return 'Apple sign in credential was rejected. Please try again.';
      default:
        return e.message ?? 'Apple sign in failed. Please try again.';
    }
  }

  String _dioErrorMessage(DioException error, {required String fallback}) {
    if (error.response?.data is Map &&
        (error.response!.data as Map).containsKey('message')) {
      return (error.response!.data as Map)['message'] as String;
    }
    return fallback;
  }

  void _showAppleEmailUnavailableAlert() {
    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Email required',
      message:
          'We could not retrieve an email from Apple. When prompted, choose Share My Email or Hide My Email — both work for sign-in. If you used Apple Sign In before, go to Settings → Apple Account → Sign in with Apple → Cre8Hive → Stop Using Apple ID, then try again.',
    );
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

      await _sendSocialUserToBackend(user);
    }

    LoaderService.hideLoader(context);
  }

  void _handleGoogleAuthError(Object error) {
    LoaderService.hideLoader(context);
    debugPrint('Google sign in error: $error');
    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: 'Google authentication failed',
    );
  }

  Future<void> _sendSocialUserToBackend(User user) async {
    try {
      try {
        await user.reload();
      } catch (_) {}

      final refreshedUser = FirebaseAuth.instance.currentUser ?? user;
      final email = refreshedUser.email?.toLowerCase();

      if (email == null || email.isEmpty) {
        throw Exception('No email returned from sign in provider');
      }

      await _completeSocialLogin(email);
    } catch (error) {
      LoaderService.hideLoader(context);
      if (error is DioException) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: _dioErrorMessage(error, fallback: 'Sign in failed.'),
        );
        return;
      }
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Sign in failed. Please try again.',
      );
    }
  }

  Future<void> _completeSocialLogin(String email) async {
    try {
      final payload = {
        'email': email.toLowerCase(),
      };

      final response = await widget.dio.post(
        '/auth/login/google',
        data: jsonEncode(payload),
        options: Options(headers: {'Accept': 'application/json'}),
      );

      LoaderService.hideLoader(context);

      if (response.statusCode == 200) {
        final responseData = response.data;
        await widget.storage
            .write(key: 'auth_token', value: responseData['token']);

        // ADD THIS: sign into Firebase with custom token
        final firebaseToken = responseData['firebase_token'];
        if (firebaseToken != null) {
          await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
        }

        if (responseData['user']['first_name'] != null) {
          Navigator.pushNamed(context, DashboardScreen.id);
        } else {
          Navigator.pushNamed(context, UpdateProfile1.id);
        }
      }
    } on DioException catch (error) {
      LoaderService.hideLoader(context);

      if (error.response?.statusCode == 403) {
        final responseData = error.response?.data;
        await widget.storage
            .write(key: 'auth_token', value: responseData['token']);
        Navigator.pushNamed(context, TermsAndCondition.id);
        return;
      }

      rethrow;
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
              _buildTextField('Email address', 'Enter your email address',
                  false, emailController),
              const SizedBox(height: 16),
              // Password Field
              _buildTextField(
                  'Password', 'Enter your password', true, passwordController),
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, ForgotPassword.id);
                  },
                  child: const Text(
                    'Forgot Password',
                    style: TextStyle(color: Colors.white, fontSize: 13),
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
              // Social Login Buttons
              const SizedBox(height: 10),

              _buildSocialButton(
                'Sign in with Apple',
                'images/apple.png',
                onTap: _signUpWithApple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, bool isPassword,
      TextEditingController controller) {
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
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
