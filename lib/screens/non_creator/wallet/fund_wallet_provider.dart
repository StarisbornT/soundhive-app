import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/utils/alert_helper.dart';
import 'package:soundhive2/utils/app_colors.dart';
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
    required String gateway,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ref.read(addMoneyProvider.notifier).addMoney(
        context: context,
        amount: double.parse(amount),
        currency: currency,
        gateway: gateway,
      );

      if (response.data?.checkoutUrl != null) {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationWebView(
              url: response.data!.checkoutUrl!,
              title: 'Add Money',
            ),
          ),
        );

        if (result == 'success' && context.mounted) {
          await ref.read(userProvider.notifier).loadUserProfile();
          await ref.read(getTransactionHistoryPlaceProvider.notifier).getTransactionHistory();
          onSuccess();
        } else if (context.mounted) {
          showCustomAlert(
            context: context,
            isSuccess: false,
            title: 'Error',
            message: "Funding was not successful",
          );
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
          final apiResponse = AddMoneyResponse.fromJson(error.response?.data);
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
}

// ─── Fund Wallet Modal ────────────────────────────────────────────────────────

class FundWalletModal extends ConsumerStatefulWidget {
  final String currency;
  const FundWalletModal({super.key, required this.currency});

  @override
  ConsumerState<FundWalletModal> createState() => _FundWalletModalState();
}

class _FundWalletModalState extends ConsumerState<FundWalletModal> {
  final TextEditingController amountController = TextEditingController();
  final PageController _pageController = PageController();

  String? _selectedGateway;
  bool _isLoading = false;

  @override
  void dispose() {
    amountController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToGatewaySelection() {
    final cleanText = amountController.text.replaceAll(',', '');
    final amount = int.tryParse(cleanText);
    if (amount == null || amount <= 0) return;
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _goBack() {
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _fundWallet() async {
    if (_selectedGateway == null) return;
    final cleanText = amountController.text.replaceAll(',', '');
    setState(() => _isLoading = true);
    await ref.read(fundWalletProvider).fundWallet(
      context: context,
      amount: cleanText,
      currency: widget.currency,
      gateway: _selectedGateway!,
      onSuccess: _showSuccessScreen,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSuccessScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Success(
          title: 'Money Added Successfully',
          subtitle: 'You have funded your wallet',
          onButtonPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter =
    NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);

    // Use showModalBottomSheet sizing approach via Dialog
    // intrinsicHeight + keyboard padding handles all screen sizes
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        // Lift content above keyboard
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          // Fixed height per page — tall enough for all content
          height: 380,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildAmountPage(theme, formatter),
              _buildGatewayPage(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 1: Amount ──────────────────────────────────────────────────────────
  Widget _buildAmountPage(ThemeData theme, NumberFormat formatter) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Money',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the amount you want to add to your wallet',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          // Amount field
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                final newText = newValue.text.replaceAll(',', '');
                if (newText.isEmpty) return newValue.copyWith(text: '');
                final number = int.tryParse(newText);
                if (number == null) return oldValue;
                final formatted = formatter.format(number);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            decoration: InputDecoration(
              prefixText: '${widget.currency} ',
              hintText: '0',
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.BUTTONCOLOR, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToGatewaySelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.BUTTONCOLOR,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Gateway ─────────────────────────────────────────────────────────
  Widget _buildGatewayPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: _goBack,
                child: Icon(Icons.arrow_back,
                    color: theme.colorScheme.onSurface, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choose Payment Method',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              'Select how you want to pay',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.55)),
            ),
          ),
          const SizedBox(height: 20),

          // Paystack card
          _GatewayOptionCard(
            id: 'paystack',
            name: 'Paystack',
            description: 'Card, bank transfer or USSD',
            icon: Icons.credit_card,
            iconColor: const Color(0xFF00C3F7),
            isSelected: _selectedGateway == 'paystack',
            onTap: () => setState(() => _selectedGateway = 'paystack'),
            theme: theme,
          ),
          const SizedBox(height: 12),

          // Flutterwave card
          _GatewayOptionCard(
            id: 'flutterwave',
            name: 'Flutterwave',
            description: 'Card, mobile money or bank',
            icon: Icons.account_balance,
            iconColor: const Color(0xFFF5A623),
            isSelected: _selectedGateway == 'flutterwave',
            onTap: () => setState(() => _selectedGateway = 'flutterwave'),
            theme: theme,
          ),
          const SizedBox(height: 20),

          // Pay Now button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
              (_selectedGateway != null && !_isLoading) ? _fundWallet : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.BUTTONCOLOR,
                disabledBackgroundColor: AppColors.BUTTONCOLOR.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                'Pay Now',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gateway Option Card ──────────────────────────────────────────────────────

class _GatewayOptionCard extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _GatewayOptionCard({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.BUTTONCOLOR
                : theme.colorScheme.onSurface.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.BUTTONCOLOR.withOpacity(0.06)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon — fixed 40x40, never grows
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Text — Expanded takes remaining space, never overflows
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Radio — fixed 22x22, never grows
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.BUTTONCOLOR
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                  width: 2,
                ),
                color:
                isSelected ? AppColors.BUTTONCOLOR : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}