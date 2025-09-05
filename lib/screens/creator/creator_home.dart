
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/screens/creator/profile/setup_screen.dart';
import 'package:soundhive2/screens/non_creator/streaming/streaming.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../components/success.dart';
import '../../lib/dashboard_provider/add_money_provider.dart';
import '../../lib/dashboard_provider/user_provider.dart';
import '../../model/add_money_model.dart';
import '../../model/user_model.dart';
import '../dashboard/verification_webview.dart';
import '../dashboard/withdraw.dart';
import '../non_creator/wallet/wallet.dart';

class CreatorHome extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const CreatorHome({super.key, required this.user});

  @override
  _CreatorHomeState createState() => _CreatorHomeState();
}
class _CreatorHomeState extends ConsumerState<CreatorHome>  {

  @override
  void initState() {
    super.initState();
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


  Widget _buildBalanceCard() {
    final user = ref.watch(userProvider);
    if(user.value?.user?.wallet == null) {
      return _walletCard("Account balance", "Error", showButton: true);
    }else {
     return _walletCard(
        "Account balance",
        user.value?.user?.wallet?.balance ?? '',
        showButton: true,
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final earnings = 0.0;

    final user = ref.watch(userProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(widget.user.user?.creator == null)...[
                  Image.asset('images/banner.png')
                ]else if(!(widget.user.user?.creator!.active ?? false))...[
                  Utils.reviewCard(
                    context,
                    title: "Account under review",
                    subtitle:"We are currently reviewing your submissions...",
                    image: "images/review.png",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetupScreen(user: widget.user),
                      ),
                    ),
                  ),
             ],
                const SizedBox(height: 16),
                // Menu buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Utils.menuButton("Insights", true),
                      const SizedBox(width: 10),
                      Utils.menuButton("Bookings (2)", false),
                      const SizedBox(width: 10),
                      Utils.menuButton("Community (100)", false),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Account Balance card
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [

                      _buildBalanceCard(),
                    // SizedBox(width: 16),
                    //   _accountCard(
                    //     "Escrow balance",
                    //     "100000.00",
                    //     note:
                    //     "N.B: This money is only paid to your balance after completion of the job.",
                    //   ),
                    //   SizedBox(width: 16),
                    //   _accountCard("Services Earnings", "1000000.00"),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Analytics Section
                Text("Analytics",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),

                SizedBox(height: 12),

                // Analytics Filters
                // Wrap(
                //   spacing: 8,
                //   runSpacing: 8,
                //   children: [
                //     _filterChip("Lyrics Writing", selected: true),
                //     _filterChip("Music production"),
                //     _filterChip("DJ Booking"),
                //     _filterChip("Content creation"),
                //   ],
                // ),
                //
                // SizedBox(height: 12),
                //
                // Wrap(
                //   spacing: 8,
                //   children: [
                //     _filterChip("Earnings", selected: true),
                //     _filterChip("Booking"),
                //     _filterChip("Rating"),
                //     _filterChip("Last 30days", icon: Icons.keyboard_arrow_down),
                //   ],
                // ),
                //
                // SizedBox(height: 16),
                //
                // // Earnings Summary
                earnings > 0
                    ? _earningsGraph(earnings)
                    : Center(
                  child: Text(
                    "No transaction done yet!",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _walletCard(String title, String amount, {bool showButton = false, String? note}) {
    return Container(
      width: 300,
      height: 162,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.BUTTONCOLOR,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            Utils.formatCurrency(amount),
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Text(
              note,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (showButton) ...[
            const SizedBox(height: 16),
            if(widget.user.user?.wallet != null) ...[
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
            ]else...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.BUTTONCOLOR,
                  shape: const StadiumBorder(),
                ),
                label: const Text("Activate Wallet"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  WalletScreen(user: widget.user.user!,),
                    ),
                  );
                },
              ),
            ]


          ],
        ],
      ),
    );
  }

  Widget _earningsGraph(double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("₦${total.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Graph Placeholder",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}
