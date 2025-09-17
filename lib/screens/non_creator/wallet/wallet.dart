import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/screens/non_creator/wallet/transaction_history.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/add_money_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/getTransactionHistory.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/add_money_model.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../dashboard/dashboard.dart';
import '../../dashboard/verification_webview.dart';
import '../streaming/streaming.dart';

class WalletScreen extends ConsumerStatefulWidget {
  final User user;
  const WalletScreen({super.key, required this.user});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {

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
              Navigator.pushNamed(context, DashboardScreen.id);
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

  TextEditingController amountController = TextEditingController();
  void _showAmountInputModal() {

    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter Amount"),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                String newText = newValue.text.replaceAll(',', '');
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
            decoration: const InputDecoration(
              prefix: Text(
                '₦ ',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
              hintText: "Enter amount to fund",
              hintStyle: TextStyle(color: Colors.black54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String cleanText = amountController.text.replaceAll(',', '');
                int? amount = int.tryParse(cleanText);
                if (amount != null && amount > 0) {
                  Navigator.of(context).pop();
                  fundWallet(); // will now work
                }
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  void fundWallet() async {
    try {
      final cleanAmount = amountController.text.replaceAll(',', '');
      final response = await ref.read(addMoneyProvider.notifier).addMoney(
        context: context,
        amount: double.parse(cleanAmount), // safe parse
      );
      if (response.url != null) {
        if (!mounted) return;
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationWebView(url: response.url!, title: 'Add Money',),
          ),
        );
        if (result == 'success') {
          if (mounted) {
            await ref.read(userProvider.notifier).loadUserProfile();
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
        }
      }
    } catch (error) {
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
      print("Error: $errorMessage");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getTransactionHistoryPlaceProvider.notifier).getTransactionHistory();
    });

  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(getTransactionHistoryPlaceProvider);
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
           const SizedBox(height: 20,),
            // Wallet Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4D3490),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
            children: [
            const Text(
            'Wallet balance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
              widget.user.wallet == null
                  ?  Text(
                '₦0.00',
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  )
                ),
              )
                  : Text(
                Utils.formatCurrency(widget.user.wallet?.balance),
                style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    )
                ),
              ),
              if(widget.user.wallet != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAmountInputModal();
                    },
                    icon: const Icon(Icons.add, color: Color(0xFF4D3490), size: 18),
                    label: const Text(
                      'Add funds',
                      style: TextStyle(color: Color(0xFF4D3490), fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Streaming(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download, color: Colors.white, size: 18),
                    label: const Text(
                      'Withdraw',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
            ),
            const SizedBox(height: 16),
            // Activate Wallet Card
            if(widget.user.wallet == null)
            Utils.reviewCard(
                context,
                title: "Activate Wallet",
                subtitle: "Create a virtual account to \n activate your wallet useful for \n purchasing show tickets, and \n paying creatives you want to hire.",
              image: "images/invest.png",
              onTap: () {
                generateAccount();
              }
            ),
            Container(
              alignment: Alignment.topLeft,
              child: const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            // No Transactions Placeholder
            serviceState.when(
              data: (serviceResponse) {
                final allServices = serviceResponse.data.data;
                if (allServices.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text(
                        'No Transaction History',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A191E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: allServices.length,
                      itemBuilder: (context, index) {
                        return TransactionCard(transaction: allServices[index]);
                      },
                    ),
                  ),
                );
              },
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Expanded(
                child: Center(
                  child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
            // const Column(
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   children: [
            //     Icon(Icons.receipt_long, color: Colors.white24, size: 40),
            //     SizedBox(height: 12),
            //     Text(
            //       'No transaction done yet',
            //       style: TextStyle(color: Colors.white38),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
