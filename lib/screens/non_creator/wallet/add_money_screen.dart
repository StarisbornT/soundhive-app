import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/alert_helper.dart';
import 'package:soundhive2/lib/dashboard_provider/add_money_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/getTransactionHistory.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/model/user_model.dart';
import 'package:soundhive2/screens/dashboard/verification_webview.dart';
import 'package:soundhive2/components/success.dart';

// Which top-level tab the user has chosen
enum _FundingMethod { bankTransfer, payOnline }

class AddMoneyScreen extends ConsumerStatefulWidget {
  final User user;
  final String currency;

  const AddMoneyScreen({
    super.key,
    required this.user,
    required this.currency,
  });

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  _FundingMethod? _selectedMethod;
  String? _selectedGateway;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final formatter =
  NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String get _cleanAmount => _amountController.text.replaceAll(',', '');

  bool get _hasValidAmount {
    final amount = double.tryParse(_cleanAmount);
    return amount != null && amount >= 100;
  }

  bool get _canProceed {
    if (!_hasValidAmount) return false;
    if (_selectedMethod == _FundingMethod.bankTransfer) return true;
    if (_selectedMethod == _FundingMethod.payOnline) {
      return _selectedGateway != null;
    }
    return false;
  }

  String get _buttonLabel {
    if (!_hasValidAmount) return 'Enter an Amount';
    if (_selectedMethod == null) return 'Choose a Payment Method';
    if (_selectedMethod == _FundingMethod.payOnline &&
        _selectedGateway == null) {
      return 'Select a Gateway';
    }
    if (_selectedMethod == _FundingMethod.bankTransfer) {
      return 'View Account Details';
    }
    return 'Pay ${widget.currency} ${_amountController.text}';
  }

  void _onPrimaryAction() {
    if (!_canProceed) return;

    if (_selectedMethod == _FundingMethod.bankTransfer) {
      _showBankTransferSheet();
    } else {
      _payOnline();
    }
  }

  // ── Bank Transfer: show account details in a bottom sheet ────────────────
  void _showBankTransferSheet() {
    final wallet = widget.user.wallet!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BankTransferSheet(
        wallet: wallet,
        amount: _amountController.text,
        currency: widget.currency,
      ),
    );
  }

  // ── Online Payment ───────────────────────────────────────────────────────
  void _payOnline() async {
    if (!_canProceed || _selectedGateway == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await ref.read(addMoneyProvider.notifier).addMoney(
        context: context,
        amount: double.parse(_cleanAmount),
        currency: widget.currency,
        gateway: _selectedGateway!,
      );

      if (!mounted) return;

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

        if (!mounted) return;

        if (result == 'success') {
          await ref.read(userProvider.notifier).loadUserProfile();
          await ref
              .read(getTransactionHistoryPlaceProvider.notifier)
              .getTransactionHistory();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Success(
                title: 'Money Added!',
                subtitle:
                '${widget.currency} ${_amountController.text} has been added to your wallet.',
                onButtonPressed: () => Navigator.pop(context),
              ),
            ),
          );
        } else {
          showCustomAlert(
            context: context,
            isSuccess: false,
            title: 'Payment Unsuccessful',
            message: 'Your payment was not completed. Please try again.',
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      String msg = 'An unexpected error occurred';
      if (error is Exception)
        msg = error.toString().replaceAll('Exception: ', '');
      showCustomAlert(
          context: context, isSuccess: false, title: 'Error', message: msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wallet = widget.user.wallet;
    final hasVirtualAccount =
        wallet?.accountNumber != null && wallet!.accountNumber!.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                size: 16, color: theme.colorScheme.onSurface),
          ),
        ),
        title: Text(
          'Add Money',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Amount Card ───────────────────────────────────────
                _AmountCard(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  currency: widget.currency,
                  formatter: formatter,
                  isDark: isDark,
                  theme: theme,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 32),

                // ── How would you like to pay? ────────────────────────
                _SectionLabel(label: 'How would you like to pay?', theme: theme),
                const SizedBox(height: 14),

                // ── Method 1: Bank Transfer (only if virtual account exists)
                if (hasVirtualAccount) ...[
                  _MethodCard(
                    icon: Icons.account_balance_outlined,
                    title: 'Bank Transfer',
                    subtitle: 'Send directly to your virtual account',
                    badge: 'Instant · Free',
                    badgeColor: Colors.green,
                    isSelected: _selectedMethod == _FundingMethod.bankTransfer,
                    onTap: () => setState(() {
                      _selectedMethod = _FundingMethod.bankTransfer;
                      _selectedGateway = null;
                    }),
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Method 2: Pay Online ──────────────────────────────
                _MethodCard(
                  icon: Icons.payment_outlined,
                  title: 'Pay Online',
                  subtitle: 'Use a payment gateway with your card or bank',
                  badge: 'Card · USSD · Mobile',
                  badgeColor: AppColors.BUTTONCOLOR,
                  isSelected: _selectedMethod == _FundingMethod.payOnline,
                  onTap: () => setState(() {
                    _selectedMethod = _FundingMethod.payOnline;
                  }),
                  theme: theme,
                  isDark: isDark,
                ),

                // ── Gateway picker (animates in when Pay Online is selected)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _selectedMethod == _FundingMethod.payOnline
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _SectionLabel(
                          label: 'Choose Gateway', theme: theme),
                      const SizedBox(height: 12),
                      _GatewayCard(
                        id: 'paystack',
                        name: 'Paystack',
                        tagline: 'Card · Bank Transfer · USSD',
                        accentColor: const Color(0xFF00C3F7),
                        isSelected: _selectedGateway == 'paystack',
                        onTap: () => setState(
                                () => _selectedGateway = 'paystack'),
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _GatewayCard(
                        id: 'flutterwave',
                        name: 'Flutterwave',
                        tagline: 'Card · Mobile Money · Bank',
                        accentColor: const Color(0xFFF5A623),
                        isSelected: _selectedGateway == 'flutterwave',
                        onTap: () => setState(
                                () => _selectedGateway = 'flutterwave'),
                        theme: theme,
                        isDark: isDark,
                      ),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── Sticky CTA ────────────────────────────────────────────────────
      bottomNavigationBar: _BottomPayButton(
        canProceed: _canProceed,
        isLoading: _isLoading,
        label: _buttonLabel,
        onPay: _onPrimaryAction,
        theme: theme,
      ),
    );
  }
}

// ─── Method Selection Card ────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.BUTTONCOLOR
                : theme.dividerColor.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.BUTTONCOLOR.withOpacity(isDark ? 0.1 : 0.05)
              : (isDark ? const Color(0xFF1A191E) : Colors.grey[50]),
        ),
        child: Row(
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.BUTTONCOLOR.withOpacity(0.15)
                    : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.BUTTONCOLOR
                    : theme.colorScheme.onSurface.withOpacity(0.45),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.BUTTONCOLOR
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 7),
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.BUTTONCOLOR : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.BUTTONCOLOR
                      : theme.colorScheme.onSurface.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bank Transfer Bottom Sheet ───────────────────────────────────────────────

class _BankTransferSheet extends StatelessWidget {
  final dynamic wallet;
  final String amount;
  final String currency;

  const _BankTransferSheet({
    required this.wallet,
    required this.amount,
    required this.currency,
  });

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Text(
            'Transfer to This Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Send exactly the amount below to fund your wallet instantly.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),

          // Amount to send
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.BUTTONCOLOR.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.BUTTONCOLOR.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  'Amount to Send',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$currency $amount',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.BUTTONCOLOR,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Account details
          _DetailRow(
            label: 'Bank Name',
            value: wallet.bankName ?? 'Bank78',
            onCopy: () =>
                _copy(context, wallet.bankName ?? 'Bank78', 'Bank name'),
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Account Number',
            value: wallet.accountNumber ?? '',
            onCopy: () => _copy(
                context, wallet.accountNumber ?? '', 'Account number'),
            theme: theme,
            isDark: isDark,
            highlight: true,
          ),
          const SizedBox(height: 24),

          // Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border:
              Border.all(color: Colors.orange.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your wallet is credited automatically once the bank confirms the transfer. This usually takes a few seconds.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.BUTTONCOLOR,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final ThemeData theme;
  final bool isDark;
  final bool highlight;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.onCopy,
    required this.theme,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    )),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: highlight ? 20 : 15,
                    fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: highlight ? 2 : 0,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.BUTTONCOLOR.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy,
                  size: 16, color: AppColors.BUTTONCOLOR),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Amount Entry Card ────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String currency;
  final NumberFormat formatter;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<String> onChanged;

  const _AmountCard({
    required this.controller,
    required this.focusNode,
    required this.currency,
    required this.formatter,
    required this.isDark,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.BUTTONCOLOR.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Amount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.BUTTONCOLOR.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.BUTTONCOLOR,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final newText = newValue.text.replaceAll(',', '');
                      if (newText.isEmpty)
                        return newValue.copyWith(text: '');
                      final number = int.tryParse(newText);
                      if (number == null) return oldValue;
                      final formatted = formatter.format(number);
                      return TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                            offset: formatted.length),
                      );
                    }),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['1,000', '5,000', '10,000', '50,000'].map((amt) {
              return GestureDetector(
                onTap: () {
                  controller.text = amt;
                  onChanged(amt);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$currency $amt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Gateway Card ─────────────────────────────────────────────────────────────

class _GatewayCard extends StatelessWidget {
  final String id;
  final String name;
  final String tagline;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _GatewayCard({
    required this.id,
    required this.name,
    required this.tagline,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : theme.dividerColor.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? accentColor.withOpacity(isDark ? 0.1 : 0.06)
              : (isDark ? const Color(0xFF222124) : Colors.grey[100]),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(0.15)
                    : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                id == 'paystack'
                    ? Icons.credit_card
                    : Icons.account_balance,
                color: isSelected
                    ? accentColor
                    : theme.colorScheme.onSurface.withOpacity(0.4),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? accentColor
                            : theme.colorScheme.onSurface,
                      )),
                  Text(tagline,
                      style: TextStyle(
                          fontSize: 11,
                          color:
                          theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : theme.colorScheme.onSurface.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface.withOpacity(0.4),
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Bottom CTA Button ────────────────────────────────────────────────────────

class _BottomPayButton extends StatelessWidget {
  final bool canProceed;
  final bool isLoading;
  final String label;
  final VoidCallback onPay;
  final ThemeData theme;

  const _BottomPayButton({
    required this.canProceed,
    required this.isLoading,
    required this.label,
    required this.onPay,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
            top: BorderSide(
                color: theme.dividerColor.withOpacity(0.12), width: 1)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: canProceed
              ? AppColors.BUTTONCOLOR
              : AppColors.BUTTONCOLOR.withOpacity(0.3),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canProceed && !isLoading ? onPay : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}