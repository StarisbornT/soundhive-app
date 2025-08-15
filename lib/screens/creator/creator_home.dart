
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundhive2/screens/creator/profile/setup_screen.dart';
import 'package:soundhive2/screens/non_creator/streaming/streaming.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

import 'package:soundhive2/lib/dashboard_provider/getAccountBalanceProvider.dart';
import '../../model/user_model.dart';
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
    if(widget.user.member?.account != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(getAccountBalance.notifier).getAccountBalance(widget.user.member!.account!.accountId);
      });
    }

  }

  Widget _buildBalanceCard() {
    final serviceState = ref.watch(getAccountBalance);

    return serviceState.when(
      loading: () => _walletCard("Account balance", "Loading...", showButton: true),
      error: (err, _) => _walletCard("Account balance", "Error", showButton: true),
      data: (response) => _walletCard(
        "Account balance",
        response.data.accountBalance.toString(),
        showButton: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earnings = 0.0;


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
                // Review status

                widget.user.creator?.status != "active" ?
                Utils.reviewCard(
                    context,
                    title: widget.user.creator != null ? "Account under review" : "Setup your creative profile",
                    subtitle: widget.user.creator != null ? "We are currently reviewing your submissions, and will give feedback within 24hours." : "To publish anything or gain clients visibility on soundhive, you need to setup your profile.",
                    image: widget.user.creator != null ? "images/review.png" : "images/bag.png",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>  SetupScreen(user: widget.user,),
                        ),
                      );
                    }
                ): SizedBox(),
                SizedBox(height: 16),
                // Menu buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Utils.menuButton("Insights", true),
                      SizedBox(width: 10),
                      Utils.menuButton("Bookings (2)", false),
                      SizedBox(width: 10),
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
            SizedBox(height: 12),
            Text(
              note,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (showButton) ...[
            const SizedBox(height: 16),
            if(widget.user.member?.account != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Utils.showBankTransferBottomSheet(
                          context,
                          widget.user.member?.account?.bank,
                          widget.user.member?.account?.accountNumber,
                          widget.user.member?.account?.accountName
                      );
                    },
                    icon: Icon(Icons.add, color: Color(0xFF4D3490), size: 18),
                    label: Text(
                      'Add funds',
                      style: TextStyle(color: Color(0xFF4D3490), fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Streaming(),
                        ),
                      );
                    },
                    icon: Icon(Icons.download, color: Colors.white, size: 18),
                    label: Text(
                      'Withdraw',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      side: BorderSide(color: Colors.white),
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
                      builder: (context) =>  WalletScreen(user: widget.user.member!,),
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

  // Widget _accountCard(String title, String amount, {bool showButton = false, String? note}) {
  //   return Container(
  //     width: 300,
  //     height: 162,
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppColors.BUTTONCOLOR,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Text(
  //           title,
  //           style: TextStyle(color: Colors.white70, fontSize: 14),
  //         ),
  //         SizedBox(height: 8),
  //         Text(
  //           Utils.formatCurrency(amount),
  //           style: GoogleFonts.roboto(
  //             textStyle: const TextStyle(color: Colors.white, fontSize: 24),
  //           ),
  //         ),
  //         if (note != null) ...[
  //           SizedBox(height: 12),
  //           Text(
  //             note,
  //             style: TextStyle(
  //               color: Colors.white70,
  //               fontSize: 12,
  //             ),
  //           ),
  //         ],
  //         if (showButton) ...[
  //           const SizedBox(height: 16),
  //           widget.user.member?.account != null ?
  //           ElevatedButton.icon(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.white,
  //               foregroundColor: AppColors.BUTTONCOLOR,
  //               shape: const StadiumBorder(),
  //             ),
  //             icon: const Icon(Icons.arrow_downward),
  //             label: const Text("Withdraw"),
  //             onPressed: () {},
  //           ): ElevatedButton.icon(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.white,
  //               foregroundColor: AppColors.BUTTONCOLOR,
  //               shape: const StadiumBorder(),
  //             ),
  //             label: const Text("Activate Wallet"),
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) =>  WalletScreen(user: widget.user.member!,),
  //                 ),
  //               );
  //             },
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _earningsGraph(double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("₦${total.toStringAsFixed(2)}",
            style: TextStyle(color: Colors.white, fontSize: 20)),
        SizedBox(height: 16),
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
