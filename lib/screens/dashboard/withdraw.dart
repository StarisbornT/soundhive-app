import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../components/pin_screen.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';

import '../../lib/dashboard_provider/apiresponseprovider.dart';
import '../../lib/dashboard_provider/get_banks_provider.dart';
import '../../model/apiresponse_model.dart';
import '../../utils/alert_helper.dart';

final withdrawStateProvider = StateProvider<bool>((ref) => false);
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawalScreenState();
}
class _WithdrawalScreenState extends ConsumerState<WithdrawScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(getBanksProvider.notifier).getBanks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showConfirmation = ref.watch(withdrawStateProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () {
            if (showConfirmation) {
              ref.read(withdrawStateProvider.notifier).state = false;
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: showConfirmation ? const ConfirmWithdrawal() : const WithdrawForm(),
      ),
    );
  }
}
class WithdrawForm extends ConsumerStatefulWidget {
  const WithdrawForm({super.key});
  @override
  ConsumerState<WithdrawForm> createState() => _WithdrawFormState();
}

class _WithdrawFormState extends ConsumerState<WithdrawForm> {
  late TextEditingController accountNumberController;
  late TextEditingController bankController;
  late TextEditingController amountController;

  String? selectedBank;
  Map<String, dynamic>? _accountDetails;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    accountNumberController = TextEditingController();
    bankController = TextEditingController();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    accountNumberController.dispose();
    bankController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _tryVerifyAccount() {
    if (selectedBank != null &&
        accountNumberController.text.trim().length == 10 &&
        !_isVerifying) {
      _verifyAccount();
    }
  }
  Future<void> _verifyAccount() async {
    if (selectedBank == null ||
        accountNumberController.text.trim().length != 10) return;

    setState(() {
      _isVerifying = true;
      _accountDetails = null;
    });

    try {
      final payload = {
        "type": "nuban",
        "bankCode": selectedBank,
        "accountNumber": accountNumberController.text.trim(),
      };

      final response =
      await ref.read(apiresponseProvider.notifier).validateAccount(
        context: context,
        payload: payload,
      );

      if (response.status) {
        setState(() {
          _accountDetails = response.data;
        });

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Account Verified',
          message: 'Account validation successful',
        );
      }
    } catch (error) {
      _handleOfferError(error);
    } finally {
      setState(() => _isVerifying = false);
    }
  }


  void _handleOfferError(dynamic error) {
    String errorMessage = 'An unexpected error occurred';

    print("Raw error: $error");

    if (error is DioException) {
      print("Dio error: ${error.response?.data}");
      print("Status code: ${error.response?.statusCode}");

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

    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: errorMessage,
    );
  }
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).value?.user;
    final bankState = ref.watch(getBanksProvider);

    final List<Map<String, String>> banks = bankState.when( data: (res) => res.data .map( (bank) => { 'label': bank.name, 'value': bank.code, }, ) .toList(), loading: () => [], error: (_, __) => [], );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Withdraw from wallet',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 24),

          LabeledTextField(
            label: 'Amount',
            controller: amountController,
            keyboardType: TextInputType.number,
            hintText: 'Enter Amount to withdraw',
            secondLabel:
            'Wallet: ${ref.formatUserCurrency(user?.wallet?.balance)}',
          ),

          const SizedBox(height: 8),

          LabeledTextField(
            label: 'Account Number',
            controller: accountNumberController,
            keyboardType: TextInputType.number,
            hintText: 'Enter Account number',
            onChanged: (_) => _tryVerifyAccount(),
          ),

          const SizedBox(height: 16),

          LabeledSelectField(
            label: 'Bank',
            controller: bankController,
            items: banks,
            hintText:
            bankState.isLoading ? 'Loading banks...' : 'Select Bank',
            onChanged: (value) {
              selectedBank = value;
              _tryVerifyAccount();
            },
          ),

          if (_isVerifying)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),

          if (_accountDetails != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Account Name: ${_accountDetails!['accountName'] ?? _accountDetails!['data']?['accountName'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.black),
              ),
            ),

          const SizedBox(height: 24),

          RoundedButton(
            title: 'Continue',
            onPressed: _accountDetails == null ? null : () {},
          ),
        ],
      ),
    );
  }

}


class ConfirmWithdrawal extends ConsumerWidget {
  const ConfirmWithdrawal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Withdrawal',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 24),

        // Confirmation Details
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              confirmRow('Amount', '₦100,000'),
              confirmRow('From', 'Soundhive Vest'),
              confirmRow('Beneficiary name', 'John Doe'),
              confirmRow('Beneficiary account number', '0261544227'),
              confirmRow('Beneficiary bank', 'GTBank'),
            ],
          ),
        ),
        Spacer(),

        // Confirm Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4D3490),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PinAuthenticationScreen(
                    buttonName: 'Withdraw',
                    onPinEntered: (pin) {
                      print("Entered PIN: $pin");
                      // Handle PIN authentication logic here
                    },
                  ),
                ),
              );

            },
            child: Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget confirmRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.white)),
          Text(value, style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Input Field Decoration
InputDecoration inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey),
    filled: true,
    fillColor: Colors.black,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.purple),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

