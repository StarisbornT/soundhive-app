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
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    // Auto-focus amount field
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

  bool get _canProceed {
    final amount = double.tryParse(_cleanAmount);
    return amount != null && amount >= 100 && _selectedGateway != null;
  }

  void _pay() async {
    if (!_canProceed) return;

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
      if (error is Exception) msg = error.toString().replaceAll('Exception: ', '');
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Amount Entry Card ───────────────────────────────────
                _AmountCard(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  currency: widget.currency,
                  formatter: formatter,
                  isDark: isDark,
                  theme: theme,
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 28),

                // ── Virtual Account Section ─────────────────────────────
                if (hasVirtualAccount) ...[
                  _SectionLabel(label: 'Your Virtual Account', theme: theme),
                  const SizedBox(height: 12),
                  _VirtualAccountTile(
                    wallet: wallet,
                    isDark: isDark,
                    theme: theme,
                    context: context,
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Payment Gateway Section ─────────────────────────────
                _SectionLabel(label: 'Pay With', theme: theme),
                const SizedBox(height: 12),

                _GatewayCard(
                  id: 'paystack',
                  name: 'Paystack',
                  tagline: 'Card · Bank Transfer · USSD',
                  accentColor: const Color(0xFF00C3F7),
                  gradientColors: [
                    const Color(0xFF00C3F7).withOpacity(0.15),
                    const Color(0xFF0052CC).withOpacity(0.08),
                  ],
                  isSelected: _selectedGateway == 'paystack',
                  onTap: () => setState(() => _selectedGateway = 'paystack'),
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _GatewayCard(
                  id: 'flutterwave',
                  name: 'Flutterwave',
                  tagline: 'Card · Mobile Money · Bank',
                  accentColor: const Color(0xFFF5A623),
                  gradientColors: [
                    const Color(0xFFF5A623).withOpacity(0.15),
                    const Color(0xFFFF6B35).withOpacity(0.08),
                  ],
                  isSelected: _selectedGateway == 'flutterwave',
                  onTap: () =>
                      setState(() => _selectedGateway = 'flutterwave'),
                  theme: theme,
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                // ── Hint ────────────────────────────────────────────────
                if (_selectedGateway == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 13,
                            color:
                            theme.colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 6),
                        Text(
                          'Select a payment method to continue',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      // ── Sticky Pay Button ─────────────────────────────────────────────
      bottomNavigationBar: _BottomPayButton(
        canProceed: _canProceed,
        isLoading: _isLoading,
        currency: widget.currency,
        amount: _amountController.text,
        onPay: _pay,
        theme: theme,
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
              // Currency badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.BUTTONCOLOR.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currency,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.BUTTONCOLOR,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Amount input
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
                      if (newText.isEmpty) return newValue.copyWith(text: '');
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
          // Quick amount chips
          Wrap(
            spacing: 8,
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

// ─── Virtual Account Tile ─────────────────────────────────────────────────────

class _VirtualAccountTile extends StatelessWidget {
  final dynamic wallet;
  final bool isDark;
  final ThemeData theme;
  final BuildContext context;

  const _VirtualAccountTile({
    required this.wallet,
    required this.isDark,
    required this.theme,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.BUTTONCOLOR.withOpacity(0.9),
            AppColors.BUTTONCOLOR,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.bankName ?? 'Bank78',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  wallet.accountNumber ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(
                  ClipboardData(text: wallet.accountNumber ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account number copied'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
              const Icon(Icons.copy, color: Colors.white, size: 16),
            ),
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
  final List<Color> gradientColors;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _GatewayCard({
    required this.id,
    required this.name,
    required this.tagline,
    required this.accentColor,
    required this.gradientColors,
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
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
            isSelected ? accentColor : theme.dividerColor.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? (isDark
              ? accentColor.withOpacity(0.1)
              : gradientColors[0])
              : (isDark ? const Color(0xFF1A191E) : Colors.grey[50]),
        ),
        child: Row(
          children: [
            // Logo container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(0.15)
                    : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                    color: accentColor.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: Icon(
                id == 'paystack' ? Icons.credit_card : Icons.account_balance,
                color: isSelected
                    ? accentColor
                    : theme.colorScheme.onSurface.withOpacity(0.4),
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
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? accentColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tagline,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
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
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
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

// ─── Bottom Pay Button ────────────────────────────────────────────────────────

class _BottomPayButton extends StatelessWidget {
  final bool canProceed;
  final bool isLoading;
  final String currency;
  final String amount;
  final VoidCallback onPay;
  final ThemeData theme;

  const _BottomPayButton({
    required this.canProceed,
    required this.isLoading,
    required this.currency,
    required this.amount,
    required this.onPay,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: canProceed
              ? AppColors.BUTTONCOLOR
              : AppColors.BUTTONCOLOR.withOpacity(0.35),
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
                canProceed && amount.isNotEmpty
                    ? 'Pay $currency $amount'
                    : 'Enter Amount & Select Method',
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