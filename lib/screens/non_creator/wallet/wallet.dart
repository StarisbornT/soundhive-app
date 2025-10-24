import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../streaming/streaming.dart';
import 'fund_wallet_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getTransactionHistoryPlaceProvider.notifier).getTransactionHistory();
    });
  }

  void _showAmountInputModal(String currency) {
    showDialog(
      context: context,
      builder: (_) => FundWalletModal(
        currency: currency,
      ),
    );
  }

  void _navigateToWithdraw() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Streaming()),
    );
  }

  void _showDollarWalletActivationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.BACKGROUNDCOLOR,
          borderRadius: BorderRadius.only(
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
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Welcome icon/illustration
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 40,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 24),

              // Welcome title
              const Text(
                'Welcome to Cre8Pay!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                      ),
                      _buildBenefitItem(
                        Icons.security,
                        'Secure Transactions',
                        'Bank-level security to keep your funds safe and protected',
                      ),
                      _buildBenefitItem(
                        Icons.speed,
                        'Instant Transfers',
                        'Send and receive money instantly across borders',
                      ),
                      _buildBenefitItem(
                        Icons.analytics,
                        'Better Exchange Rates',
                        'Enjoy competitive exchange rates without hidden fees',
                      ),
                      _buildBenefitItem(
                        Icons.language,
                        'Global Access',
                        'Make payments and receive funds from anywhere in the world',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
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
      final response = await ref.read(apiresponseProvider.notifier).activateDollarWallet(
        context: context,
      );

      if(response.status) {
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

      print("Raw error: $error");

      if (error is DioException) {
        print("Dio error: ${error.response?.data}");
        print("Status code: ${error.response?.statusCode}");

        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
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
    final serviceState = ref.watch(getTransactionHistoryPlaceProvider);
    final user = widget.user;

    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Wallet Balance Cards
            _buildWalletBalanceCards(user),
            const SizedBox(height: 16),

            // Recent Transactions Header
            _buildTransactionsHeader(),
            const SizedBox(height: 10),

            // Transactions List
            _buildTransactionsList(serviceState),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCards(User user) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
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
          if(!user.wallet!.hasActivatedDollarWallet)
            _buildDollarWalletActivationCard(),
          if(user.wallet!.hasActivatedDollarWallet)
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

  Widget _buildDollarWalletActivationCard() {
    return GestureDetector(
      onTap: _showDollarWalletActivationSheet,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A191E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_open,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dollar Wallet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Activate your dollar wallet to start making international transactions and enjoy global payment features.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.PRIMARYCOLOR,
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

  Widget _buildTransactionsHeader() {
    return const Text(
      'Recent Transactions',
      style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Colors.white
      ),
    );
  }

  Widget _buildTransactionsList(AsyncValue<TransactionHistoryResponse> serviceState) {
    return serviceState.when(
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
          child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white)
          ),
        ),
      ),
    );
  }
}
