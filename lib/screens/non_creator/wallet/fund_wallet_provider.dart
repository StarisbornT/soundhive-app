import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/utils/alert_helper.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/add_money_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/getTransactionHistory.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/add_money_model.dart';
import '../../dashboard/verification_webview.dart';

final fundWalletProvider = Provider<FundWalletService>((ref) {
  return FundWalletService(ref);
});

class FundWalletService {
  final Ref ref;

  FundWalletService(this.ref);

  Future<void> fundWallet({
    required BuildContext context,
    required String amount,
    required String currency,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ref.read(addMoneyProvider.notifier).addMoney(
        context: context,
        amount: double.parse(amount),
        currency: currency,
      );

      if (response.url != null) {
        if (!context.mounted) return;

        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationWebView(
              url: response.url!,
              title: 'Add Money',
            ),
          ),
        );

        if (result == 'success' && context.mounted) {
          await ref.read(userProvider.notifier).loadUserProfile();
          await ref.read(getTransactionHistoryPlaceProvider.notifier).getTransactionHistory();
          onSuccess();
        }
      }
    } catch (error) {
      _handleError(error, context);
    }
  }

  void _handleError(Object error, BuildContext context) {
    String errorMessage = 'An unexpected error occurred';

    if (error is DioException) {
      if (error.response?.data != null) {
        try {
          final apiResponse = AddMoneyModel.fromJson(error.response?.data);
          errorMessage = apiResponse.message;
        } catch (e) {
          errorMessage = 'Failed to parse error message';
        }
      } else {
        errorMessage = error.message ?? 'Network error occurred';
      }
    }

    showCustomAlert(
        context: context, isSuccess: false, title: 'Error', message: errorMessage);
  }
}

// Fund Wallet Modal Widget
class FundWalletModal extends ConsumerStatefulWidget {
  final String currency; // Add currency parameter

  const FundWalletModal({
    super.key,
    required this.currency,
  });

  @override
  ConsumerState<FundWalletModal> createState() => _FundWalletModalState();
}

class _FundWalletModalState extends ConsumerState<FundWalletModal> {
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _fundWallet() {
    final cleanText = amountController.text.replaceAll(',', '');
    final amount = int.tryParse(cleanText);

    if (amount != null && amount > 0) {
      ref.read(fundWalletProvider).fundWallet(
        context: context,
        amount: cleanText,
        currency: widget.currency,
        onSuccess: _showSuccessScreen,
      );
    }
  }

  void _showSuccessScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Success(
          title: 'Money Added Successfully',
          subtitle: 'You have funded your wallet',
          onButtonPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);

    return AlertDialog(
      title: Text("Enter Amount (${widget.currency})"), // Show currency in title
      content: TextField(
        controller: amountController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          TextInputFormatter.withFunction((oldValue, newValue) {
            final newText = newValue.text.replaceAll(',', '');
            if (newText.isEmpty) return newValue.copyWith(text: '');
            final number = int.tryParse(newText);
            if (number == null) return oldValue;
            final newFormatted = formatter.format(number);
            return TextEditingValue(
              text: newFormatted,
              selection: TextSelection.collapsed(offset: newFormatted.length),
            );
          }),
        ],
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefix: Text(
            '${widget.currency} ', // Use the passed currency symbol
            style: const TextStyle(color: Colors.black),
          ),
          hintText: "Enter amount to fund",
          hintStyle: const TextStyle(color: Colors.black54),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _fundWallet,
          child: const Text("Continue"),
        ),
      ],
    );
  }
}