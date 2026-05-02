import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/dashboard/withdraw.dart';
import 'package:soundhive2/screens/non_creator/wallet/bills/cable_tv_screen.dart';
import 'package:soundhive2/screens/non_creator/wallet/bills/data_screen.dart';
import 'package:soundhive2/screens/non_creator/wallet/bills/electricy_screen.dart';
import 'package:soundhive2/screens/non_creator/wallet/transaction_history.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet_cards.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../components/rounded_button.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/getTransactionHistory.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/transaction_history_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import 'add_money_screen.dart';
import 'bills/airtime_screen.dart';


class WalletScreen extends ConsumerStatefulWidget {
  final User user;
  const WalletScreen({super.key, required this.user});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getTransactionHistoryPlaceProvider.notifier).getTransactionHistory();
    });
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

  // Replace this method
  void _showAmountInputModal(String currency) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMoneyScreen(
          user: widget.user,
          currency: currency,
        ),
      ),
    );
  }

  void _navigateToWithdraw() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WithdrawScreen()),
    );
  }

  void _showDollarWalletActivationSheet(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.BACKGROUNDCOLOR : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Welcome icon/illustration
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.BUTTONCOLOR.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 40,
                  color: AppColors.BUTTONCOLOR,
                ),
              ),

              const SizedBox(height: 24),

              // Welcome title
              Text(
                'Welcome to Cre8Pay!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Benefits list
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildBenefitItem(
                        Icons.currency_exchange,
                        'Multi-Currency Support',
                        'Access to both local and dollar wallets for seamless international transactions',
                        theme: theme,
                        isDark: isDark,
                      ),
                      _buildBenefitItem(
                        Icons.security,
                        'Secure Transactions',
                        'Bank-level security to keep your funds safe and protected',
                        theme: theme,
                        isDark: isDark,
                      ),
                      _buildBenefitItem(
                        Icons.speed,
                        'Instant Transfers',
                        'Send and receive money instantly across borders',
                        theme: theme,
                        isDark: isDark,
                      ),
                      _buildBenefitItem(
                        Icons.analytics,
                        'Better Exchange Rates',
                        'Enjoy competitive exchange rates without hidden fees',
                        theme: theme,
                        isDark: isDark,
                      ),
                      _buildBenefitItem(
                        Icons.language,
                        'Global Access',
                        'Make payments and receive funds from anywhere in the world',
                        theme: theme,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Activation button
              RoundedButton(
                title: 'Activate Dollar Wallet',
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  activateDollarWallet(); // Call activation function
                },
                color: AppColors.BUTTONCOLOR,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description,
      {required ThemeData theme, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.BUTTONCOLOR.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.BUTTONCOLOR, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void activateDollarWallet() async {
    try {
      final response =
      await ref.read(apiresponseProvider.notifier).activateDollarWallet(
        context: context,
      );

      if (response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Success(
              title: 'Dollar Wallet Activated',
              subtitle: 'Your dollar Wallet has been successfully activated',
            ),
          ),
        );
      }
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      debugPrint("Raw error: $error");

      if (error is DioException) {
        debugPrint("Dio error: ${error.response?.data}");
        debugPrint("Status code: ${error.response?.statusCode}");

        if (error.response?.data != null) {
          try {
            final apiResponse =
            ApiResponseModel.fromJson(error.response?.data);
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

  void generateAccount() async {
    try {
      final response =
      await ref.read(apiresponseProvider.notifier).generateAccount(
        context: context,
      );

      if (response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Success(
              title: 'Account Generated Successfully',
              subtitle: 'Your Virtual has been successfully generated',
            ),
          ),
        );
      }
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      debugPrint("Raw error: $error");

      if (error is DioException) {
        debugPrint("Dio error: ${error.response?.data}");
        debugPrint("Status code: ${error.response?.statusCode}");

        if (error.response?.data != null) {
          try {
            final apiResponse =
            ApiResponseModel.fromJson(error.response?.data);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final serviceState = ref.watch(getTransactionHistoryPlaceProvider);
    final user = widget.user;

    return Scaffold(
      body: SafeArea(  // ← ADD SafeArea to avoid status bar overflow
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(           // ← This Column must be the direct flex parent
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildWalletBalanceCards(user, theme, isDark),
              const SizedBox(height: 16),
              _buildHeader("Quick Actions", theme),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickActionItem(icon: Icons.call, label: "Airtime",
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => AirtimeScreen(user: widget.user))),
                      theme: theme, isDark: isDark),
                  _quickActionItem(icon: Icons.swap_vert, label: "Data",
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => DataScreen(user: widget.user))),
                      theme: theme, isDark: isDark),
                  _quickActionItem(icon: Icons.lightbulb_outline, label: "Electricity",
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ElectricityScreen(user: widget.user))),
                      theme: theme, isDark: isDark),
                  _quickActionItem(icon: Icons.tv, label: "Cable TV",
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => CableTvScreen(user: widget.user))),
                      theme: theme, isDark: isDark),
                ],
              ),
              const SizedBox(height: 16),
              _buildHeader("Recent Transactions", theme),
              const SizedBox(height: 10),
              // ↓ This Expanded must be a direct child of the Column above
              Expanded(
                child: _buildTransactionsList(serviceState, theme, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppColors.BUTTONCOLOR,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Replace only the _buildWalletBalanceCards method and add _buildGenerateAccountCard

  Widget _buildWalletBalanceCards(User user, ThemeData theme, bool isDark) {
    final hasAccount = user.wallet?.accountNumber != null &&
        user.wallet!.accountNumber!.isNotEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // ── NGN Wallet card ──
          WalletBalanceCard(
            title: 'Base balance',
            balance: user.wallet?.balance != null
                ? ref.formatUserCurrency(user.wallet?.balance)
                : '',
            currencySymbol: user.wallet!.currency,
            onAddFunds: () => _showAmountInputModal(user.wallet!.currency),
            onWithdraw: _navigateToWithdraw,
          ),
          const SizedBox(width: 10),

          // ── Generate Account card (if no virtual account yet) ──
          if (!hasAccount) _buildGenerateAccountCard(theme, isDark),

          // ── Virtual account info card (once generated) ──
          if (hasAccount) _buildVirtualAccountCard(user, theme, isDark),

          const SizedBox(width: 10),

          // ── Dollar Wallet ──
          if (!user.wallet!.hasActivatedDollarWallet)
            _buildDollarWalletActivationCard(theme, isDark),
          if (user.wallet!.hasActivatedDollarWallet)
            WalletBalanceCard(
              title: 'Dollar balance',
              balance: user.wallet?.dollarBalance != null
                  ? ref.formatUserDollarCurrency(user.wallet?.dollarBalance)
                  : '',
              currencySymbol: 'USD',
              onAddFunds: () => _showAmountInputModal('USD'),
              onWithdraw: _navigateToWithdraw,
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateAccountCard(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: generateAccount,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.BUTTONCOLOR.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.BUTTONCOLOR.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: AppColors.BUTTONCOLOR,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Virtual Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Generate a dedicated bank account to receive transfers directly into your wallet.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.BUTTONCOLOR,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Generate Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualAccountCard(User user, ThemeData theme, bool isDark) {
    final wallet = user.wallet!;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.BUTTONCOLOR.withOpacity(0.85),
            AppColors.BUTTONCOLOR,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Virtual Account',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            wallet.bankName ?? 'Bank78',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wallet.accountNumber ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: wallet.accountNumber ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account number copied'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Icon(Icons.copy, color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${user.firstName} ${user.lastName}',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDollarWalletActivationCard(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _showDollarWalletActivationSheet(theme, isDark),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.BUTTONCOLOR.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.BUTTONCOLOR.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_open,
                    color: AppColors.BUTTONCOLOR,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dollar Wallet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Activate your dollar wallet to start making international transactions and enjoy global payment features.',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.BUTTONCOLOR,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Activate Now',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

// Replace _buildTransactionsList — remove all the Expanded wrappers inside

  Widget _buildTransactionsList(
      AsyncValue<TransactionHistoryResponse> serviceState,
      ThemeData theme,
      bool isDark) {
    return serviceState.when(
      data: (serviceResponse) {
        final allServices = serviceResponse.data.data;

        if (allServices.isEmpty) {
          return const Center(child: Text('No Transaction History'));
        }

        return Container(
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
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: theme.colorScheme.primary),
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
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading transactions',
                style: TextStyle(color: theme.colorScheme.error)),
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
    );
  }
}
