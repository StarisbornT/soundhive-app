import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/getTransactionHistory.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../../model/transaction_history_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/app_colors.dart';
class TransactionHistory extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const TransactionHistory({super.key, required this.user});

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}
class _TransactionHistoryScreenState extends ConsumerState<TransactionHistory>{
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
    final account = widget.user.user?.wallet;

    return Scaffold(
      backgroundColor: const Color(0xFF050110),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050110),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: const Text(
                'Transaction History',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            if (account == null)
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: 60,
                    child: RoundedButton(
                        title: 'Activate Wallet',
                        color: AppColors.BUTTONCOLOR,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WalletScreen(user: widget.user.user!)),
                          );
                        }
                    ),
                  )
                ),
              )
            else
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
          ],
        ),
      ),
    );
  }

}

class TransactionCard extends ConsumerWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color.fromRGBO(188, 174, 226, 0.3),
        child: Icon(
          transaction.type == "DEBIT" ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(
        transaction.narration,
        maxLines: 1, // Limits to a single line
        overflow: TextOverflow.ellipsis, // Adds '...'
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),


      subtitle: Text(
        transaction.type ?? '',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
           "${transaction.currency ?? ref.userCurrency} ${transaction.amount}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat('dd/MM/yyyy').format(DateTime.parse(transaction.createdAt)),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
