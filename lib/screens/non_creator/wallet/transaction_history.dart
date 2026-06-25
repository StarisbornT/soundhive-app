import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/getTransactionHistory.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../model/transaction_history_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/app_colors.dart';
import 'package:pdf/widgets.dart' as pw;

class TransactionHistory extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const TransactionHistory({super.key, required this.user});

  @override
  ConsumerState<TransactionHistory> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistory> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getTransactionHistoryPlaceProvider.notifier).refresh();
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore) return;

    final notifier = ref.read(getTransactionHistoryPlaceProvider.notifier);
    if (notifier.hasMore) {
      setState(() {
        _isLoadingMore = true;
      });

      try {
        await notifier.loadMore();
      } finally {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(getTransactionHistoryPlaceProvider.notifier).refresh();
        },
        child: Padding(
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
                              MaterialPageRoute(
                                  builder: (_) =>
                                      WalletScreen(user: widget.user.user!)),
                            );
                          }),
                    ),
                  ),
                )
              else
                _buildTransactionsList(serviceState, context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
      AsyncValue<TransactionHistoryResponse> serviceState,
      BuildContext context,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return serviceState.when(
      data: (serviceResponse) {
        final allServices = serviceResponse.data.data;

        if (allServices.isEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                'No Transaction History',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          );
        }

        final notifier = ref.read(getTransactionHistoryPlaceProvider.notifier);

        return Expanded(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: allServices.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= allServices.length) {
                        // Loading indicator at the bottom
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }

                      return TransactionCard(
                        transaction: allServices[index],
                        theme: theme,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
              ),

            ],
          ),
        );
      },
      loading: () => Expanded(
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      ),
      error: (error, _) => Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading transactions',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => ref
                    .read(getTransactionHistoryPlaceProvider.notifier)
                    .refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionReceiptScreen(transaction: transaction),
        ),
      ),
      child: Container(
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
                  child: FaIcon(
                    isDebit
                        ? FontAwesomeIcons.arrowDown
                        : FontAwesomeIcons.arrowUp,
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
                      transaction.transactionStatus ?? '',
                      style: TextStyle(
                        color:
                        currentTheme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy')
                          .format(DateTime.parse(transaction.createdAt)),
                      style: TextStyle(
                        color:
                        currentTheme.colorScheme.onSurface.withOpacity(0.5),
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ),
    );
  }
}

class TransactionReceiptScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionReceiptScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDebit = transaction.type == "DEBIT";
    final amountColor = isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    pw.Widget _pdfRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Future<void> _shareReceipt(BuildContext context) async {
      final isDebit = transaction.type == "DEBIT";
      final amountColor = isDebit
          ? PdfColors.red400
          : PdfColors.green400;
      final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
          .format(DateTime.parse(transaction.createdAt));

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 24),
                  decoration: pw.BoxDecoration(
                    color: isDebit ? PdfColors.red50 : PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          color: isDebit ? PdfColors.red100 : PdfColors.green100,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            isDebit ? '↓' : '↑',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: amountColor,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        '${transaction.currency ?? ''} ${transaction.amount}',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: isDebit ? PdfColors.red100 : PdfColors.green100,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          transaction.transactionStatus,
                          style: pw.TextStyle(
                            color: amountColor,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Title
                pw.Text(
                  'Transaction Receipt',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  formattedDate,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Divider
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 12),

                // Receipt rows
                _pdfRow('Narration', transaction.narration),
                _pdfRow('Reference', transaction.reference),
                _pdfRow('Type', isDebit ? 'Debit' : 'Credit'),
                _pdfRow('Total Amount', '${transaction.currency ?? ''} ${transaction.totalAmount}'),
                _pdfRow('Total Charge', '${transaction.currency ?? ''} ${transaction.totalCharge}'),
                if (transaction.feeAmount != null)
                  _pdfRow('Fee', '${transaction.currency ?? ''} ${transaction.feeAmount}'),
                if (transaction.feePercent != null)
                  _pdfRow('Fee Percent', '${transaction.feePercent}%'),
                if (transaction.sourceBankName != null)
                  _pdfRow('Source Bank', transaction.sourceBankName!),
                if (transaction.otherInfo != null)
                  _pdfRow('Other Info', transaction.otherInfo!),

                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 20),

                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Transaction ID: ${transaction.id}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Vest ID: ${transaction.vestId}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'This is an auto-generated receipt.',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt_${transaction.reference}.pdf');
      await file.writeAsBytes(await pdf.save());

      final box = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          fileNameOverrides: ['Receipt_${transaction.reference}.pdf'],
          subject: 'Transaction Receipt - ${transaction.reference}',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
    }



    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transaction Receipt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.transactionStatus.toLowerCase() == 'successful'
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: amountColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            Text(
              "${transaction.currency ?? ''} ${transaction.amount}",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 4),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                transaction.transactionStatus,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Receipt card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A191E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  _receiptRow(context, 'Narration', transaction.narration),
                  _divider(context),
                  _receiptRow(context, 'Reference', transaction.reference),
                  _divider(context),
                  _receiptRow(context, 'Type', transaction.type ?? '-'),
                  _divider(context),
                  _receiptRow(context, 'Total Amount', "${transaction.currency ?? ''} ${transaction.totalAmount}"),
                  _divider(context),
                  _receiptRow(context, 'Total Charge', "${transaction.currency ?? ''} ${transaction.totalCharge}"),
                  if (transaction.feeAmount != null) ...[
                    _divider(context),
                    _receiptRow(context, 'Fee', "${transaction.currency ?? ''} ${transaction.feeAmount}"),
                  ],
                  if (transaction.sourceBankName != null) ...[
                    _divider(context),
                    _receiptRow(context, 'Source Bank', transaction.sourceBankName!),
                  ],
                  _divider(context),
                  _receiptRow(
                    context,
                    'Date',
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(DateTime.parse(transaction.createdAt)),
                  ),
                  if (transaction.otherInfo != null) ...[
                    _divider(context),
                    _receiptRow(context, 'Other Info', transaction.otherInfo!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Share / Download button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async => await _shareReceipt(context),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Receipt'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.08),
    );
  }
}