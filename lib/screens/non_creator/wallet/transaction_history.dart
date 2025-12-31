import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  ConsumerState<TransactionHistory> createState() => _TransactionHistoryScreenState();
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
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
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
  final ThemeData? theme;
  final bool? isDark;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.theme,
    this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = theme ?? Theme.of(context);
    final currentIsDark = isDark ?? currentTheme.brightness == Brightness.dark;

    final isDebit = transaction.type == "DEBIT";
    final amountColor = isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final iconBackground = isDebit
        ? const Color.fromRGBO(239, 68, 68, 0.1)
        : const Color.fromRGBO(16, 185, 129, 0.1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: currentIsDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentTheme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isDebit ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
                  color: amountColor,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.narration,
                    style: TextStyle(
                      color: currentTheme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.type ?? '',
                    style: TextStyle(
                      color: currentTheme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(transaction.createdAt)),
                    style: TextStyle(
                      color: currentTheme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${transaction.currency ?? ref.userCurrency} ${transaction.amount}",
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isDebit ? 'Debit' : 'Credit',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
