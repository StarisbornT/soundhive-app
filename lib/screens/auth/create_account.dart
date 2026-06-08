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
import 'package:soundhive2/screens/auth/otp_screen.dart';
import 'package:soundhive2/screens/auth/terms_and_condition.dart';
import '../../services/fcm_service.dart';
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

  late final GoogleSignIn _googleSignIn;

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
        "email": emailController.text.toLowerCase(),
        "password": passwordController.text,
        "role": identity == "creator" ? "CREATOR" : "USER",
        'creator_role': creatorIdentity?.toUpperCase() ?? ""
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await widget.dio
          .post('/auth/register', data: jsonEncode(payload), options: options);
      print(response);
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        await widget.storage.write(key: 'identity', value: identity);
        await widget.storage.write(key: 'email', value: emailController.text);
        Navigator.pushNamed(context, OtpScreen.id);
      } else {
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
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      if (error is DioException) {
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
      setState(() => isLoading = true);

      await _googleSignIn.authenticate();
    } catch (e) {
      setState(() => isLoading = false);
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

  String? _appleDisplayName(AuthorizationCredentialAppleID credential) {
    final parts = <String>[
      if (credential.givenName != null) credential.givenName!,
      if (credential.familyName != null) credential.familyName!,
    ];
    final name = parts.join(' ').trim();
    return name.isEmpty ? null : name;
  }

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

  Future<User?> _firebaseUserFromAppleAuth(
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

    return FirebaseAuth.instance.currentUser ?? user;
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

      setState(() => isLoading = true);

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
      var name = _appleDisplayName(appleCredential);
      var userId = appleCredential.userIdentifier;

      if (email == null) {
        final firebaseUser =
            await _firebaseUserFromAppleAuth(appleCredential, rawNonce);
        email = firebaseUser?.email?.toLowerCase();
        userId ??= firebaseUser?.uid;
        name ??= firebaseUser?.displayName;
      }

      if (email != null &&
          appleCredential.userIdentifier != null &&
          email.isNotEmpty) {
        await widget.storage.write(
          key: _appleEmailStorageKey(appleCredential.userIdentifier!),
          value: email.toLowerCase(),
        );
      }

      if (email == null || email.isEmpty) {
        throw Exception('No email returned from Apple Sign In');
      }

      await _completeSocialRegistration(
        email: email,
        name: name,
        userId: userId ?? email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      setState(() => isLoading = false);
      if (e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Apple sign up failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: _firebaseAuthErrorMessage(e),
      );
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Apple sign up error: $e');
      if (e is! DioException) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Apple sign up failed. Please try again.',
        );
      }
    }
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Apple Sign In is not enabled in Firebase. Please contact support.';
      case 'invalid-credential':
        return 'Apple sign up credential was rejected. Please try again.';
      default:
        return e.message ?? 'Apple sign up failed. Please try again.';
    }
  }

  Future<void> _handleGoogleAuthEvent(event) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      final googleAuth = event.user;

      final idToken = googleAuth.authentication.idToken;

      if (idToken == null) {
        throw Exception('No ID token');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) throw Exception('Firebase auth failed');

      await _sendGoogleUserToBackend(user);
    }

    setState(() => isLoading = false);
  }

  void _handleGoogleAuthError(Object error) {
    setState(() => isLoading = false);
    debugPrint('Google sign up error: $error');
    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: 'Google authentication failed',
    );
  }

  Future<void> _completeSocialRegistration({
    required String email,
    String? name,
    required String userId,
    String? avatar,
  }) async {
    try {
      final payload = {
        'email': email.toLowerCase(),
        'name': name,
        'google_id': userId,
        'avatar': avatar,
        'role': identity == 'creator' ? 'CREATOR' : 'USER',
        'creator_role': creatorIdentity?.toUpperCase() ?? '',
      };

      final response = await widget.dio.post(
        '/auth/register/google',
        data: jsonEncode(payload),
        options: Options(headers: {'Accept': 'application/json'}),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final fcmService = FcmTokenService(widget.dio);
        await fcmService.registerFcmToken(email);
        await widget.storage
            .write(key: 'auth_token', value: responseData['token']);
        Navigator.pushNamed(context, TermsAndCondition.id);
      }
    } on DioException catch (error) {
      setState(() => isLoading = false);

      String errorMessage = 'Registration failed';

      if (error.response != null && error.response!.data != null) {
        final responseData = error.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        } else if (responseData is Map && responseData.containsKey('errors')) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final messages = <String>[];
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              messages.addAll(value.map((e) => '$key: $e'));
            }
          });
          errorMessage = messages.join('\n');
        }
      }

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    } catch (e) {
      setState(() => isLoading = false);
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> _sendGoogleUserToBackend(User user) async {
    try {
      try {
        await user.reload();
      } catch (_) {}

      final refreshedUser = FirebaseAuth.instance.currentUser ?? user;
      if (refreshedUser.email == null || refreshedUser.email!.isEmpty) {
        throw Exception('No email returned from Google Sign In');
      }

      await _completeSocialRegistration(
        email: refreshedUser.email!.toLowerCase(),
        name: refreshedUser.displayName,
        userId: refreshedUser.uid,
        avatar: refreshedUser.photoURL,
      );
    } catch (e) {
      if (e is! DioException) {
        setState(() => isLoading = false);
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Google registration failed. Please try again.',
        );
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
      _isPasswordValid = hasLowerCase &&
          hasUpperCase &&
          hasNumber &&
          hasSpecialChar &&
          hasMinLength;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
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
              _buildTextField('Email address', 'Enter your email address',
                  false, emailController),
              const SizedBox(height: 16),
              // Password Field
              _buildTextField(
                  'Password', 'Enter your password', true, passwordController),
              const SizedBox(height: 16),
              // Password strength indicators
              _buildPasswordIndicators(),
              const SizedBox(height: 32),
              // Continue Button
              _buildButton(
                  isLoading ? 'Loading' : 'Continue', AppColors.PRIMARYCOLOR),
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
                'Sign up with Google',
                'images/google.png',
                onTap: _signUpWithGoogle,
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                'Sign up with Apple',
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
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildIndicator('Special character',
                RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)),
            _buildIndicator('8 characters in length', password.length >= 8),
          ],
        )
      ],
    );
  }

  Widget _buildIndicator(String label, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.circle_outlined,
            color: isValid ? Colors.green : Colors.grey, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
      onTap: isLoading ? null : onTap,
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
