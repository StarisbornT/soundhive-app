import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundhive2/lib/dashboard_provider/getAccountBalanceProvider.dart';
import 'package:soundhive2/screens/non_creator/wallet/activate_wallet.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../../model/user_model.dart';
import '../../dashboard/withdraw.dart';
import '../streaming/streaming.dart';

class WalletScreen extends ConsumerStatefulWidget {
  final User user;
  const WalletScreen({super.key, required this.user});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {

  @override
  void initState() {
    super.initState();
    // if(widget.user.account != null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     ref.read(getAccountBalance.notifier).getAccountBalance(widget.user.account!.accountId);
    //   });
    // }

  }
  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(getAccountBalance);
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20,),
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
                      Utils.showBankTransferBottomSheet(
                                  context,
                                  widget.user.wallet?.bankName,
                                widget.user.wallet?.accountNumber,
                                widget.user.firstName
                      );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ActivateWallet()),
                );
              }
            ),
            const Spacer(),
            // No Transactions Placeholder
            const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, color: Colors.white24, size: 40),
                SizedBox(height: 12),
                Text(
                  'No transaction done yet',
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
