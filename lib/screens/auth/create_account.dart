import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/screens/auth/otp_screen.dart';
import 'package:soundhive2/screens/auth/terms_and_condition.dart';
import '../../components/label_text.dart';
import 'package:soundhive2/lib/auth_provider/create_account_provider.dart';
import 'package:soundhive2/lib/state/create_account_state.dart';
import '../../utils/alert_helper.dart';
import '../../utils/app_colors.dart';

class CreateAccount extends ConsumerStatefulWidget {
  final FlutterSecureStorage storage;
  final Dio dio;
  const CreateAccount({super.key, required this.storage, required this.dio});
  static String id = 'create_account';

  @override
  ConsumerState<CreateAccount> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccount> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  late final CreateAccountDeps _deps;

  @override
  void initState() {
    super.initState();
    _deps = CreateAccountDeps(storage: widget.storage, dio: widget.dio);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    referralCodeController.dispose();
    super.dispose();
  }

  void _navigate(String routeId) {
    switch (routeId) {
      case 'otp':
        Navigator.pushNamed(context, OtpScreen.id);
        break;
      case 'terms':
        Navigator.pushNamed(context, TermsAndCondition.id);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(createAccountProvider(_deps).notifier);

    ref.listen<CreateAccountState>(createAccountProvider(_deps), (previous, next) {
      if (next.pendingAlert != null) {
        final alert = next.pendingAlert!;
        showCustomAlert(
          context: context,
          isSuccess: alert.isSuccess,
          title: alert.title,
          message: alert.message,
        );
        notifier.consumeAlert();
      }
      if (next.navigateToRouteId != null) {
        _navigate(next.navigateToRouteId!);
        notifier.consumeNavigation();
      }
    });

    final state = ref.watch(createAccountProvider(_deps));

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
              LabeledTextField(
                label: 'First name',
                hintText: 'Enter your first name',
                controller: firstNameController,
              ),
              LabeledTextField(
                label: 'Last name',
                hintText: 'Enter your last name',
                controller: lastNameController,
              ),
              LabeledTextField(
                label: 'Email address',
                hintText: 'Enter your email address',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              LabeledTextField(
                label: 'Password',
                hintText: 'Enter your password',
                controller: passwordController,
                obscureText: state.isPasswordObscured,
                hasToggleVisibility: true,
                showVisibility: !state.isPasswordObscured,
                toggleVisibility: notifier.toggleObscurePassword,
                onChanged: notifier.validatePassword,
              ),
              LabeledTextField(
                label: 'Referral code',
                secondLabel: 'Optional',
                hintText: 'Enter a referral code',
                controller: referralCodeController,
              ),
              _buildPasswordIndicators(state),
              const SizedBox(height: 16),
              _buildButton(
                state.isLoading ? 'Loading' : 'Continue',
                AppColors.PRIMARYCOLOR,
                onTap: () => notifier.submit(
                  email: emailController.text,
                  password: passwordController.text,
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  referralCode: referralCodeController.text,
                ),
              ),
              const SizedBox(height: 24),
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
              _buildSocialButton(
                'Sign up with Google',
                'images/google.png',
                isLoading: state.isLoading,
                onTap: notifier.signUpWithGoogle,
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                'Sign up with Apple',
                'images/apple.png',
                isLoading: state.isLoading,
                onTap: notifier.signUpWithApple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordIndicators(CreateAccountState state) {
    final v = state.passwordValidation;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildIndicator('Lower case', v.hasLowerCase, state.hasAttemptedSubmit),
            _buildIndicator('Upper case', v.hasUpperCase, state.hasAttemptedSubmit),
            _buildIndicator('Number', v.hasNumber, state.hasAttemptedSubmit),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildIndicator('Special character', v.hasSpecialChar, state.hasAttemptedSubmit),
            _buildIndicator('8 characters in length', v.hasMinLength, state.hasAttemptedSubmit),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicator(String label, bool isValid, bool hasAttemptedSubmit) {
    Color iconAndTextColor;

    if (isValid) {
      iconAndTextColor = Colors.green;
    } else {
      iconAndTextColor = hasAttemptedSubmit ? Colors.red : Colors.grey;
    }

    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : (hasAttemptedSubmit ? Icons.cancel : Icons.circle_outlined),
          color: iconAndTextColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: iconAndTextColor == Colors.grey ? Colors.white70 : iconAndTextColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildButton(String text, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      String text,
      String asset, {
        required bool isLoading,
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}