
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet.dart';

import '../../../components/label_text.dart';
import '../../../components/rounded_button.dart';
import '../../../components/success.dart';
import '../../../lib/dashboard_provider/user_provider.dart';
import '../../../lib/navigator_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';

class ActivateWallet extends ConsumerStatefulWidget {
  const ActivateWallet({super.key});

  @override
  _ActivateWalletScreenState createState() => _ActivateWalletScreenState();
}

class _ActivateWalletScreenState extends ConsumerState<ActivateWallet> {
  final TextEditingController bvnNumberController = TextEditingController();
  final TextEditingController verifyBvnNumberController = TextEditingController();
  int _currentStep = 0;
  String? _identityId;
  void _nextStep() {
      setState(() {
        _currentStep++;
      });
  }

  Future<void> sendIdVerification() async {
    try {
      final payload = {
        "type": "BVN",
        "id_number": bvnNumberController.text
      };

      final response = await ref.read(apiresponseProvider.notifier).sendIdVerification(
        context: context,
        payload: payload,
      );

      _identityId = response.data['_id'];

      _nextStep();
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      print("Error: $errorMessage");
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }


  Future<void> verifyIdentity() async {
    try {
      if (_identityId == null) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Identity ID is missing. Please verify BVN again.',
        );
        return;
      }

      final payload = {
        "identity_id": _identityId,
        "otp": verifyBvnNumberController.text,
        "type": "BVN"
      };

      final response = await ref.read(apiresponseProvider.notifier).verifyId(
        context: context,
        payload: payload,
      );

      // showCustomAlert(
      //   context: context,
      //   isSuccess: true,
      //   title: 'Verified',
      //   message: response.message,
      // );

      generateAccount();
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      print("Error: $errorMessage");
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  Future<void> generateAccount() async {
    try {
      final response = await ref.read(apiresponseProvider.notifier).generateAccount(
        context: context
      );
      final user = await ref.read(userProvider.notifier).loadUserProfile();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Account generated',
            subtitle: 'Your account has been generated successfully',
            onButtonPressed: () {
              ref.read(bottomNavigationProvider.notifier).state = 1;
            },
          ),
        ),
      );
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      print("Error: $errorMessage");
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _bvnForm();
      case 1:
        return _verifyBVN();
      default:
        return const Center(child: Text("More steps to come", style: TextStyle(color: Colors.white)));
    }
  }
  Widget _bvnForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Enter BVN',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        LabeledTextField(
          label: 'Enter BVN Number',
          controller: bvnNumberController,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
  Widget _verifyBVN() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Verify BVN',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        LabeledTextField(
          label: 'Verify BVN Number',
          controller: verifyBvnNumberController,
        ),
      ],
    );
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFB0B0B6)),
                    onPressed: _previousStep,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStepContent(),
                  ),
                ),
                const SizedBox(height: 10),
                RoundedButton(
                  title: 'Continue',
                  onPressed: _currentStep == 0 ? sendIdVerification : verifyIdentity,
                  color: AppColors.BUTTONCOLOR,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}