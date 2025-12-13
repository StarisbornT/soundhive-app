
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundhive2/screens/creator/profile/setup_screen.dart';
import 'package:soundhive2/screens/non_creator/streaming/streaming.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/add_money_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/getCreatorBookings.dart';
import '../../model/add_money_model.dart';
import '../../model/user_model.dart';
import '../dashboard/verification_webview.dart';
import '../non_creator/wallet/wallet.dart';
import 'creator_bookings_detail.dart';

class CreatorHome extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const CreatorHome({super.key, required this.user});

  @override
  ConsumerState<CreatorHome> createState() => _CreatorHomeState();
}
class _CreatorHomeState extends ConsumerState<CreatorHome> with SingleTickerProviderStateMixin  {
  int selectedTabIndex = 0;
  final ScrollController _bookingsScrollController = ScrollController();
  late TabController _tabController;

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _bookingsScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(_handleTabChange);
    _bookingsScrollController.addListener(_scrollListener);
  }
  void _handleTabChange() {
    if (_tabController.index == 1 ) {
      ref.read(getCreatorBookingProvider.notifier).getActiveInvestments(
        pageSize: 10, // Add pagination limit
      );
    }
    if (mounted) {
      setState(() => selectedTabIndex = _tabController.index);
    }
  }
  void _scrollListener() {
    if (_bookingsScrollController.position.pixels ==
        _bookingsScrollController.position.maxScrollExtent) {
      _loadMoreBookings();
    }
  }
  Future<void> _loadMoreBookings() async {
    final notifier = ref.read(getCreatorBookingProvider.notifier);
    if (!notifier.isLastPage && mounted) {
      await notifier.getActiveInvestments(loadMore: true);
    }
  }

  TextEditingController amountController = TextEditingController();
  void _showAmountInputModal() {

    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter Amount"),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                String newText = newValue.text.replaceAll(',', '');
                if (newText.isEmpty) return newValue.copyWith(text: '');
                final number = int.tryParse(newText);
                if (number == null) return oldValue;
                final newFormatted = formatter.format(number);
                return TextEditingValue(
                  text: newFormatted,
                  selection: TextSelection.collapsed(offset: newFormatted.length),
                );
              }),
            ],
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              prefix: Text(
                '${ref.userCurrency} ',
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
              hintText: "Enter amount to fund",
              hintStyle: const TextStyle(color: Colors.black54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String cleanText = amountController.text.replaceAll(',', '');
                int? amount = int.tryParse(cleanText);
                if (amount != null && amount > 0) {
                  Navigator.of(context).pop();
                  fundWallet(); // will now work
                }
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  void fundWallet() async {
    try {
      final cleanAmount = amountController.text.replaceAll(',', '');
      final response = await ref.read(addMoneyProvider.notifier).addMoney(
        context: context,
        amount: double.parse(cleanAmount),
        currency: 'NGN'
      );
      if (response.data != null) {
        if (!mounted) return;
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationWebView(url: response.data!.checkoutUrl!, title: 'Add Money',),
          ),
        );
        if (result == 'success') {
          if (mounted) {
            await ref.read(userProvider.notifier).loadUserProfile();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Success(
                  title: 'Money Added Successfully',
                  subtitle: 'You have funded your wallet',
                  onButtonPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            );

          }
        }
      }
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';
      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = AddMoneyModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }
      print("Error: $errorMessage");
    }
  }


  Widget _buildBalanceCard() {
    final user = ref.watch(userProvider);
    if(user.value?.user?.wallet == null) {
      return _walletCard("Account balance", "Error", showButton: true);
    }else {
     return _walletCard(
       "Account balance",
      (ref.formatUserCurrency(user.value?.user?.wallet?.balance)),
       showButton: true,
     );

    }

  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

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
                if((widget.user.user?.creator == null || widget.user.user?.creator?.hasVerifiedIdentity == false || widget.user.user?.creator?.hasVerifiedCreativeProfile == false))...[
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetupScreen(user: widget.user),
                        ),
                      );

                    },
                      child: Image.asset('images/banner.png')
                  )
                ]else if(!(widget.user.user?.creator!.active ?? false))...[
                  Utils.reviewCard(
                    context,
                    title: "Account under review",
                    subtitle:"We are currently reviewing your submissions...",
                    image: "images/review.png",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetupScreen(user: widget.user),
                      ),
                    ),
                  ),
             ],
                const SizedBox(height: 16),
                // Menu buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Utils.menuButton("Insights",  selectedTabIndex == 0,
                        onTap: () => _tabController.animateTo(0),),
                      const SizedBox(width: 10),
                      Utils.menuButton("Bookings", selectedTabIndex == 1,
                        onTap: () => _tabController.animateTo(1),),
                      const SizedBox(width: 10),
                      Utils.menuButton("Community (100)", false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedTabIndex == 0)
                  creatorHomeWidget((user.value?.user?.wallet?.escrowBalance ?? ''), (user.value?.user?.wallet?.amountEarned ?? ''))
                else if (selectedTabIndex == 1)
                  buildMyBookingsUI()
                else
                  const SizedBox(),

              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildShimmerBookingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[700]!,
            highlightColor: Colors.grey[500]!,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget buildMyBookingsUI() {
    final investmentsState = ref.watch(getCreatorBookingProvider);
    final investments = ref.read(getCreatorBookingProvider.notifier).allServices;
    final isLastPage = ref.read(getCreatorBookingProvider.notifier).isLastPage;
    final isLoadingMore = ref.read(getCreatorBookingProvider.notifier).isLoadingMore;

    return investmentsState.when(
      loading: () => _buildShimmerBookingsList(),
      error: (e, _) => Center(
        child: Text("Error: $e", style: const TextStyle(color: Colors.white)),
      ),
      data: (_) {
        if (investments.isEmpty) {
          return const Center(
            child: Text("No bookings found", style: TextStyle(color: Colors.white)),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              controller: _bookingsScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: investments.length,
              itemBuilder: (context, index) {
                final investment = investments[index];
                final service = investment.service;

                return GestureDetector(
                  onTap: () {
                    if (investment.status == "PENDING") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatorBookingsDetailScreen(
                            service: investment,
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: service?.coverImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          service?.coverImage ?? '',
                          width: 100,
                          height: 78,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, color: Colors.white),
                        ),
                      )
                          : const CircleAvatar(
                        backgroundColor: AppColors.BUTTONCOLOR,
                        child: Icon(Icons.work, color: Colors.white),
                      ),
                      title: Text(
                        service?.serviceName ?? "Booking #${investment.id}",
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Booked on ${DateFormat('dd/MM/yyyy').format(DateTime.parse(investment.createdAt))}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: investment.status == "PENDING"
                                  ? const Color.fromRGBO(255, 193, 7, 0.1)
                                  : const Color.fromRGBO(76, 175, 80, 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              investment.status == "PENDING" ? 'Ongoing' : 'Completed',
                              style: TextStyle(
                                color: investment.status == "PENDING"
                                    ? const Color(0xFFFFC107)
                                    : const Color(0xFF4CAF50),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (!isLastPage && isLoadingMore)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(child: _buildLoadingIndicator()),
              ),
          ],
        );
      },
    );
  }
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[700]!,
          highlightColor: Colors.grey[500]!,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
  Widget creatorHomeWidget(String escrowBalance, String amountEarned) {
    return Column(
      children: [
        // Account Balance card
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [

              _buildBalanceCard(),
              const SizedBox(width: 16),
              _walletCard(
                "Escrow balance",
                ref.formatCreatorCurrency(escrowBalance),
                note:
                "N.B: This money is only paid to your balance after completion of the job.",
              ),
              const SizedBox(width: 16),
              _walletCard("Services Earnings", ref.formatCreatorCurrency(amountEarned)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Analytics Section
        const Text("Analytics",
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
        // amountEarned > 0
        //     ? _earningsGraph(amountEarned)
        //     : Center(
        //   child: Text(
        //     "No transaction done yet!",
        //     style: TextStyle(color: Colors.grey),
        //   ),
        // )
      ],
    );
  }

  Widget _walletCard(String title, String amount, {bool showButton = false, String? note}) {
    return Container(
      width: 300,
      height: 162,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.PRIMARYCOLOR,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (showButton) ...[
            const SizedBox(height: 16),
            if(widget.user.user?.wallet != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAmountInputModal();
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
                      builder: (context) =>  WalletScreen(user: widget.user.user!,),
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

}
