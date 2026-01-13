import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../components/pin_screen.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';

import '../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/get_banks_provider.dart';
import '../../model/apiresponse_model.dart';
import '../../utils/alert_helper.dart';

// Add this provider to store withdrawal data
final withdrawalDataProvider = StateProvider<Map<String, dynamic>>((ref) => {});

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
        child: showConfirmation
            ? const ConfirmWithdrawal()
            : const WithdrawForm(),
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
  String? selectedBankName;
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
        "type": "bank_account",
        "bankCode": selectedBank,
        "accountNumber": accountNumberController.text.trim(),
      };

      final response = await ref
          .read(apiresponseProvider.notifier)
          .validateAccount(context: context, payload: payload);

      if (response.status) {
        setState(() {
          _accountDetails = response.data;
        });
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

  void _showConfirmation() {
    if (_accountDetails == null ||
        amountController.text.isEmpty ||
        selectedBank == null ||
        selectedBankName == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Incomplete Information',
        message: 'Please fill all fields and verify account',
      );
      return;
    }

    // Store withdrawal data
    ref.read(withdrawalDataProvider.notifier).state = {
      'amount': amountController.text,
      'amountFormatted': ref.formatUserCurrency(
          double.tryParse(amountController.text.replaceAll(",", "")) ?? 0),
      'accountNumber': accountNumberController.text.trim(),
      'accountName': _accountDetails!['accountName'] ??
          _accountDetails!['data']?['accountName'] ??
          'N/A',
      'bankCode': selectedBank,
      'bankName': selectedBankName,
      'from': 'Soundhive Vest', // You can customize this
    };

    // Show confirmation screen
    ref.read(withdrawStateProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).value?.user;
    final bankState = ref.watch(getBanksProvider);

    final List<Map<String, String>> banks = bankState.when(
      data: (res) => res.data
          .map(
            (bank) => {
          'label': bank.name,
          'value': bank.code,
        },
      )
          .toList(),
      loading: () => [],
      error: (_, __) => [],
    );

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
          CurrencyInputField(
            label: "Amount",
            controller: amountController,
            currencySymbol: ref.userCurrency,
            onChanged: (value) {
              print('Input changed to: $value');
            },
            validator: (value) {
              if (value == null || value.isEmpty || double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
              return null;
            },
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
            hintText: bankState.isLoading ? 'Loading banks...' : 'Select Bank',
            onChanged: (value) {
              selectedBank = value;
              // Get the selected bank name
              final selectedBankData =
              banks.firstWhere((bank) => bank['value'] == value);
              selectedBankName = selectedBankData['label'];
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
            onPressed: _accountDetails == null ? null : _showConfirmation,
          ),
        ],
      ),
    );
  }
}

class ConfirmWithdrawal extends ConsumerWidget {
  const ConfirmWithdrawal({super.key});

  Future<void> _processWithdrawal(BuildContext context, WidgetRef ref, String pin) async {
    final withdrawalData = ref.read(withdrawalDataProvider);

    if (withdrawalData.isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Withdrawal data not found. Please try again.',
      );
      ref.read(withdrawStateProvider.notifier).state = false;
      return;
    }

    try {
      final payload = {
        "paymentDestination": "bank_account",
        "amount": int.parse(withdrawalData['amount'].replaceAll(",", "")),
        "beneficiary": {
          "accountHolderName": withdrawalData['accountName'],
          "accountNumber": withdrawalData['accountNumber'],
          "bankCode": withdrawalData['bankCode'],
        },
        "pin": pin
      };

      final response = await ref
          .read(apiresponseProvider.notifier)
          .createPayout(context: context, payload: payload);

      if (response.status) {
        final customerResponse = await ref
            .read(apiresponseProvider.notifier)
            .getCustomerReference(
          context: context,
          reference: response.data['customerReference'],
        );

        if (customerResponse.status) {
          await ref.read(userProvider.notifier).loadUserProfile();

          // Clear withdrawal data
          ref.read(withdrawalDataProvider.notifier).state = {};
          ref.read(withdrawStateProvider.notifier).state = false;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Success(
                title: 'Withdrawal Successful',
                subtitle: 'Your withdrawal has been processed successfully',
                onButtonPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ),
          );
        }
      }
    } catch (error) {
      _handleWithdrawalError(context, error);
    }
  }

  void _handleWithdrawalError(BuildContext context, dynamic error) {
    String errorMessage = 'An unexpected error occurred';

    debugPrint("Raw error: $error");

    if (error is DioException) {
      debugPrint("Dio error: ${error.response?.data}");
      debugPrint("Status code: ${error.response?.statusCode}");

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
      title: 'Withdrawal Failed',
      message: errorMessage,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalData = ref.watch(withdrawalDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Withdrawal',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        const SizedBox(height: 24),

        // Confirmation Details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              confirmRow('Amount', withdrawalData['amountFormatted']?.toString() ?? '₦0'),
              confirmRow('From', withdrawalData['from']?.toString() ?? 'Wallet'),
              confirmRow('Account Name',
                  withdrawalData['accountName']?.toString() ?? 'N/A'),
              confirmRow('Account number',
                  withdrawalData['accountNumber']?.toString() ?? ''),
              confirmRow('Bank',
                  withdrawalData['bankName']?.toString() ?? ''),
            ],
          ),
        ),
        const Spacer(),

        // Confirm Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D3490),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PinAuthenticationScreen(
                    buttonName: 'Withdraw',
                    onPinEntered: (pin) {
                      print("Entered PIN: $pin");
                      // Handle PIN verification here if needed
                      // For now, we'll proceed with withdrawal after PIN entry
                      _processWithdrawal(context, ref, pin);
                    },
                  ),
                ),
              );
            },
            child: const Text('Confirm Withdrawal',
                style: TextStyle(color: Colors.white, fontSize: 16)),
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
          Text(title,
              style: const TextStyle(fontSize: 14, color: Colors.white)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
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

