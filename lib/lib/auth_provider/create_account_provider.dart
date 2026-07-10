import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../services/fcm_service.dart';
import '../state/create_account_state.dart';

/// Bundles the two dependencies the screen currently receives via its
/// constructor, so they can be forwarded into the provider family.
class CreateAccountDeps {
  final FlutterSecureStorage storage;
  final Dio dio;

  const CreateAccountDeps({required this.storage, required this.dio});

  @override
  bool operator ==(Object other) =>
      other is CreateAccountDeps && other.storage == storage && other.dio == dio;

  @override
  int get hashCode => Object.hash(storage, dio);
}

final createAccountProvider = StateNotifierProvider.autoDispose
    .family<CreateAccountNotifier, CreateAccountState, CreateAccountDeps>(
      (ref, deps) => CreateAccountNotifier(storage: deps.storage, dio: deps.dio),
);

class CreateAccountNotifier extends StateNotifier<CreateAccountState> {
  final FlutterSecureStorage storage;
  final Dio dio;

  late final GoogleSignIn _googleSignIn;

  CreateAccountNotifier({required this.storage, required this.dio})
      : super(CreateAccountState.initial()) {
    _init();
  }

  Future<void> _init() async {
    await _loadIdentity();
    _initGoogleSignIn();
  }

  Future<void> _loadIdentity() async {
    final storedIdentity = await storage.read(key: 'identity');
    final storedCreatorIdentity = await storage.read(key: 'creator_identity');
    state = state.copyWith(
      identity: storedIdentity,
      creatorIdentity: storedCreatorIdentity,
    );
  }

  void _initGoogleSignIn() {
    _googleSignIn = GoogleSignIn.instance;
    _googleSignIn
        .initialize(serverClientId: dotenv.env["CLIENT_SERVER_ID"])
        .then((_) {
      _googleSignIn.authenticationEvents.listen(
        _handleGoogleAuthEvent,
        onError: _handleGoogleAuthError,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Password validation
  // ---------------------------------------------------------------------

  void validatePassword(String password) {
    final validation = PasswordValidation.fromPassword(password);
    state = state.copyWith(
      passwordValidation: validation,
      hasAttemptedSubmit: password.isEmpty ? false : state.hasAttemptedSubmit,
    );
  }

  void toggleObscurePassword() {
    state = state.copyWith(isPasswordObscured: !state.isPasswordObscured);
  }

  // ---------------------------------------------------------------------
  // One-shot event handling helpers
  // ---------------------------------------------------------------------

  void _emitAlert({required bool isSuccess, required String title, required String message}) {
    state = state.copyWith(
      pendingAlert: CreateAccountAlert(isSuccess: isSuccess, title: title, message: message),
    );
  }

  void consumeAlert() {
    state = state.copyWith(clearPendingAlert: true);
  }

  void consumeNavigation() {
    state = state.copyWith(clearNavigateToRouteId: true);
  }

  // ---------------------------------------------------------------------
  // Email/password sign up
  // ---------------------------------------------------------------------

  /// Returns true if validation passed and the request was attempted.
  void submit({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String referralCode,
  }) {
    if (state.isLoading) return;

    state = state.copyWith(hasAttemptedSubmit: true);

    if (!state.passwordValidation.isValid) {
      _emitAlert(
        isSuccess: false,
        title: 'Weak Password',
        message: 'Please fulfill all password requirements highlighted below.',
      );
      return;
    }

    _saveFormData(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      referralCode: referralCode,
    );
  }

  Future<void> _saveFormData({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String referralCode,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final Map<String, String> payload = {
        "email": email.toLowerCase(),
        "password": password,
        "first_name": firstName,
        "last_name": lastName,
        "referral_code": referralCode,
        "role": state.identity == "creator" ? "CREATOR" : "USER",
        'creator_role': state.creatorIdentity?.toUpperCase() ?? "",
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response =
      await dio.post('/auth/register', data: jsonEncode(payload), options: options);

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        final referralData = response.data['referral'];
        if (referralData != null && referralData['applied'] == false) {
          _emitAlert(
            isSuccess: false,
            title: 'Error',
            message: referralData['message'] ?? 'Could not apply referral code',
          );
        }
        await storage.write(key: 'identity', value: state.identity);
        await storage.write(key: 'email', value: email);
        state = state.copyWith(navigateToRouteId: _RouteIds.otp);
      } else {
        state = state.copyWith(isLoading: false);
        _emitAlert(isSuccess: false, title: 'Error', message: 'Account not Created');
      }
    } catch (error) {
      state = state.copyWith(isLoading: false);
      if (error is DioException) {
        _emitAlert(
          isSuccess: false,
          title: 'Error',
          message: _dioErrorMessage(error, fallback: 'Failed, Please check input'),
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Google sign up
  // ---------------------------------------------------------------------

  Future<void> signUpWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true);
      await _googleSignIn.authenticate();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _emitAlert(isSuccess: false, title: 'Error', message: 'Google sign in cancelled');
    }
  }

  Future<void> _handleGoogleAuthEvent(event) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      final googleAuth = event.user;
      final idToken = googleAuth.authentication.idToken;

      if (idToken == null) {
        throw Exception('No ID token');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) throw Exception('Firebase auth failed');

      await _sendGoogleUserToBackend(user);
    }

    state = state.copyWith(isLoading: false);
  }

  void _handleGoogleAuthError(Object error) {
    state = state.copyWith(isLoading: false);
    debugPrint('Google sign up error: $error');
    _emitAlert(isSuccess: false, title: 'Error', message: 'Google authentication failed');
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

      final nameParts = _splitFullName(refreshedUser.displayName);

      await _completeSocialRegistration(
        email: refreshedUser.email!.toLowerCase(),
        firstName: nameParts.firstName,
        lastName: nameParts.lastName,
        userId: refreshedUser.uid,
        avatar: refreshedUser.photoURL,
      );
    } catch (e) {
      if (e is! DioException) {
        state = state.copyWith(isLoading: false);
        _emitAlert(
          isSuccess: false,
          title: 'Error',
          message: 'Google registration failed. Please try again.',
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Apple sign up
  // ---------------------------------------------------------------------

  Future<void> signUpWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        _emitAlert(
          isSuccess: false,
          title: 'Error',
          message: 'Sign in with Apple is not available on this device.',
        );
        return;
      }

      state = state.copyWith(isLoading: true);

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
      await _storeAppleNameParts(appleCredential); // persist before anything can go wrong
      var firstName = appleCredential.givenName;
      var lastName = appleCredential.familyName;
      if (firstName == null && lastName == null) {
        final stored = await _resolveAppleNameParts(appleCredential);
        firstName = stored.firstName;
        lastName = stored.lastName;
      }
      var userId = appleCredential.userIdentifier;

      if (email == null) {
        final firebaseUser = await _firebaseUserFromAppleAuth(appleCredential, rawNonce);
        email = firebaseUser?.email?.toLowerCase();
        userId ??= firebaseUser?.uid;
        if (firstName == null && lastName == null) {
          final fallback = _splitFullName(firebaseUser?.displayName);
          firstName = fallback.firstName;
          lastName = fallback.lastName;
        }
        if (appleCredential.userIdentifier != null &&
            (firstName != null || lastName != null)) {
          await storage.write(
            key: _appleFirstNameStorageKey(appleCredential.userIdentifier!),
            value: firstName ?? '',
          );
          await storage.write(
            key: _appleLastNameStorageKey(appleCredential.userIdentifier!),
            value: lastName ?? '',
          );
        }
      }

      if (email != null && appleCredential.userIdentifier != null && email.isNotEmpty) {
        await storage.write(
          key: _appleEmailStorageKey(appleCredential.userIdentifier!),
          value: email.toLowerCase(),
        );
      }

      if (email == null || email.isEmpty) {
        state = state.copyWith(isLoading: false);
        _emitAlert(
          isSuccess: false,
          title: 'Email required',
          message:
          'We could not retrieve an email from Apple. When prompted, choose Share My '
              'Email or Hide My Email — both work for sign-up. If you used Apple Sign In '
              'before, go to Settings → Apple Account → Sign in with Apple → Cre8Hive → '
              'Stop Using Apple ID, then try again.',
        );
        return;
      }

      await _completeSocialRegistration(
        email: email,
        firstName: firstName,
        lastName: lastName,
        userId: userId ?? email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      state = state.copyWith(isLoading: false);
      if (e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      _emitAlert(isSuccess: false, title: 'Error', message: 'Apple sign up failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      _emitAlert(isSuccess: false, title: 'Error', message: _firebaseAuthErrorMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Apple sign up error: $e');
      if (e is! DioException) {
        _emitAlert(isSuccess: false, title: 'Error', message: 'Apple sign up failed. Please try again.');
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

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
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
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      if (payload is Map && payload['email'] is String) {
        return payload['email'] as String;
      }
    } catch (_) {}
    return null;
  }

  String _appleEmailStorageKey(String userIdentifier) => 'apple_email_$userIdentifier';

  String _appleFirstNameStorageKey(String userIdentifier) => 'apple_first_name_$userIdentifier';

  String _appleLastNameStorageKey(String userIdentifier) => 'apple_last_name_$userIdentifier';

  /// Best-effort split of a single display name (e.g. from Firebase) into
  /// first/last name parts.
  ({String? firstName, String? lastName}) _splitFullName(String? fullName) {
    final trimmed = fullName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return (firstName: null, lastName: null);
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (firstName: parts.first, lastName: null);
    }
    return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
  }

  Future<String?> _resolveAppleEmail(AuthorizationCredentialAppleID appleCredential) async {
    final tokenEmail = _emailFromAppleIdentityToken(appleCredential.identityToken);
    final credentialEmail = appleCredential.email ?? tokenEmail;

    if (credentialEmail != null && credentialEmail.isNotEmpty) {
      if (appleCredential.userIdentifier != null) {
        await storage.write(
          key: _appleEmailStorageKey(appleCredential.userIdentifier!),
          value: credentialEmail.toLowerCase(),
        );
      }
      return credentialEmail.toLowerCase();
    }

    if (appleCredential.userIdentifier != null) {
      final storedEmail =
      await storage.read(key: _appleEmailStorageKey(appleCredential.userIdentifier!));
      if (storedEmail != null && storedEmail.isNotEmpty) {
        return storedEmail.toLowerCase();
      }
    }

    return null;
  }

  Future<void> _storeAppleNameParts(AuthorizationCredentialAppleID appleCredential) async {
    final userIdentifier = appleCredential.userIdentifier;
    if (userIdentifier == null) return;

    if (appleCredential.givenName != null) {
      await storage.write(
        key: _appleFirstNameStorageKey(userIdentifier),
        value: appleCredential.givenName!,
      );
    }
    if (appleCredential.familyName != null) {
      await storage.write(
        key: _appleLastNameStorageKey(userIdentifier),
        value: appleCredential.familyName!,
      );
    }
  }

  Future<({String? firstName, String? lastName})> _resolveAppleNameParts(
      AuthorizationCredentialAppleID appleCredential,
      ) async {
    if (appleCredential.givenName != null || appleCredential.familyName != null) {
      return (firstName: appleCredential.givenName, lastName: appleCredential.familyName);
    }

    final userIdentifier = appleCredential.userIdentifier;
    if (userIdentifier == null) return (firstName: null, lastName: null);

    final storedFirst = await storage.read(key: _appleFirstNameStorageKey(userIdentifier));
    final storedLast = await storage.read(key: _appleLastNameStorageKey(userIdentifier));
    return (
    firstName: (storedFirst != null && storedFirst.isNotEmpty) ? storedFirst : null,
    lastName: (storedLast != null && storedLast.isNotEmpty) ? storedLast : null,
    );
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

    final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    final user = userCredential.user;
    if (user == null) return null;

    try {
      await user.reload();
    } catch (_) {}

    return FirebaseAuth.instance.currentUser ?? user;
  }

  // ---------------------------------------------------------------------
  // Shared social-registration completion
  // ---------------------------------------------------------------------

  Future<void> _completeSocialRegistration({
    required String email,
    String? firstName,
    String? lastName,
    required String userId,
    String? avatar,
  }) async {
    try {
      final payload = {
        'email': email.toLowerCase(),
        'first_name': firstName,
        'last_name': lastName,
        'google_id': userId,
        'avatar': avatar,
        'role': state.identity == 'creator' ? 'CREATOR' : 'USER',
        'creator_role': state.creatorIdentity?.toUpperCase() ?? '',
      };

      final response = await dio.post(
        '/auth/register/google',
        data: jsonEncode(payload),
        options: Options(headers: {'Accept': 'application/json'}),
      );

      state = state.copyWith(isLoading: false);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final fcmService = FcmTokenService(dio);
        await fcmService.registerFcmToken(email);
        await storage.write(key: 'auth_token', value: responseData['token']);
        if (firstName != null) {
          await storage.write(key: 'social_first_name', value: firstName);
        }
        if (lastName != null) {
          await storage.write(key: 'social_last_name', value: lastName);
        }
        state = state.copyWith(navigateToRouteId: _RouteIds.terms);
      }
    } on DioException catch (error) {
      state = state.copyWith(isLoading: false);
      _emitAlert(
        isSuccess: false,
        title: 'Error',
        message: _dioErrorMessage(error, fallback: 'Registration failed'),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _emitAlert(
        isSuccess: false,
        title: 'Error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  String _dioErrorMessage(DioException error, {required String fallback}) {
    String errorMessage = fallback;

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
    return errorMessage;
  }
}

/// Keep route ids in one place so the notifier doesn't need to import
/// screen widgets directly. Map these to your actual screen `.id` values
/// in the UI layer when handling `navigateToRouteId`.
class _RouteIds {
  static const otp = 'otp';
  static const terms = 'terms';
}