import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/lib/dashboard_provider/getInvestmentProvider.dart';
import 'package:soundhive2/model/investment_model.dart';
import 'package:soundhive2/screens/non_creator/vest/vest_details.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveVestProvider.dart';
import '../../../model/get_active_vest_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/utils.dart';
import '../../dashboard/withdraw.dart';
import '../wallet/add_money_screen.dart';
import '../wallet/wallet_cards.dart';
import 'active_vest_details.dart';
import 'package:shimmer/shimmer.dart';

final authTokenProvider = FutureProvider<String?>((ref) async {
  const storage = FlutterSecureStorage();
  return await storage.read(key: 'auth_token');
});

class SoundHiveVestScreen extends ConsumerStatefulWidget {
  static const String id = '/soundhivevest';
  final MemberCreatorResponse user;
  const SoundHiveVestScreen({super.key, required this.user});

  @override
  ConsumerState<SoundHiveVestScreen> createState() => _SoundHiveVestScreenState();
}

class _SoundHiveVestScreenState extends ConsumerState<SoundHiveVestScreen> with TickerProviderStateMixin {

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // Remove _scrollController from NestedScrollView and create a separate one for the list
  final ScrollController _innerScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_handleSearch);
    _innerScrollController.addListener(_handleScroll); // ← use inner controller

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getInvestmentProvider.notifier).getInvestments();
    });
  }

  void _handleScroll() {
    if (_innerScrollController.position.pixels >=
        _innerScrollController.position.maxScrollExtent - 100) {
      _loadMoreData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _innerScrollController.dispose(); // ← dispose inner controller
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchController.text.trim() == query) {
          ref.read(getInvestmentProvider.notifier).searchInvestments(query);
        }
      });
    } else {
      ref.read(getInvestmentProvider.notifier).getInvestments(reset: true);
    }
  }

  void _loadMoreData() async {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      await ref.read(getInvestmentProvider.notifier).loadMore();

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _handleTabChange() {
    // indexIsChanging is true DURING animation, false when settled
    // Use index directly and guard with a debounce flag instead
    if (_tabController.indexIsChanging) return; // ← was !indexIsChanging, wrong logic

    final notifier = ref.read(getInvestmentProvider.notifier);
    final activeNotifier = ref.read(getActiveVestProvider.notifier);
    switch (_tabController.index) {
      case 0:
        notifier.getInvestments(reset: true);
        break;
      case 1:
        activeNotifier.getActiveVest(status: "active");
        break;
      case 2:
        activeNotifier.getActiveVest(status: "matured");
        break;
    }
  }

  void _showAmountInputModal(String currency) {
    showDialog(
      context: context,
      builder: (_) => AddMoneyScreen(
        user: widget.user.user!,
        currency: currency,
      ),
    );
  }

  void _navigateToWithdraw() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WithdrawScreen(walletType: 'NGN',)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(authTokenProvider);
    return tokenAsync.when(
      loading: () => _buildShimmerLoadingScreen(),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (token) {
        final serviceState = ref.watch(getInvestmentProvider);
        final activeState = ref.watch(getActiveVestProvider);
        final user = widget.user.user;

        return Scaffold(
          backgroundColor: const Color(0xFF0C051F),
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cre8Vest',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (user?.wallet != null)
                            WalletBalanceCard(
                              title: 'Base balance',
                              balance: user?.wallet?.balance != null
                                  ? ref.formatUserCurrency(user?.wallet?.balance)
                                  : '',
                              currencySymbol: user?.wallet!.currency ?? '',
                              onAddFunds: () => _showAmountInputModal(user?.wallet!.currency ?? ''),
                              onWithdraw: _navigateToWithdraw,
                            ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        indicatorColor: Colors.purple,
                        tabs: const [
                          Tab(text: "Vest options"),
                          Tab(text: "Active vests"),
                          Tab(text: "Matured vests"),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVestOptions(serviceState),
                    _buildActiveInvestments(activeState),
                    _buildMaturedInvestments(activeState),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0C051F),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Shimmer.fromColors(
              baseColor: Colors.grey[700]!,
              highlightColor: Colors.grey[500]!,
              child: Container(
                width: 200,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Shimmer.fromColors(
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
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[500]!,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[500]!,
                    child: Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[500]!,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVestOptions(AsyncValue<InvestmentResponse> serviceState) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Invest in artists, invest in events, share in catalogues and revenue',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for investments',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: serviceState.when(
            data: (serviceResponse) {
              final allServices = serviceResponse.data.data;
              if (allServices.isEmpty) return _buildEmptyState(context);

              return ListView.builder(
                controller: _innerScrollController, // ← attach here
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                ),
                itemCount: allServices.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == allServices.length) {
                    return _buildLoadingIndicator();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VestDetailsScreen(
                              investment: allServices[index],
                              user: widget.user.user!,
                            ),
                          ),
                        );
                      },
                      child: _investmentCard(allServices[index]),
                    ),
                  );
                },
              );
            },
            loading: () => _buildShimmerInvestmentList(),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
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

  Widget _buildActiveInvestments(AsyncValue<ActiveVestResponse> state) {
    return state.when(
      data: (response) {
        final allServices = response.data.data;
        if (allServices.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          itemCount: allServices.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ActiveVestDetailsScreen(
                        investment: allServices[index],
                      ),
                    ));
                  },
                  child: _activeinvestmentCard(allServices[index])
              ),
            );
          },
        );
      },
      loading: () => _buildShimmerInvestmentList(),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildMaturedInvestments(AsyncValue<ActiveVestResponse> state) {
    return state.when(
      data: (response) {
        final maturedInvestments = response.data.data;
        if (maturedInvestments.isEmpty) return _buildEmptyState(context);

        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          itemCount: maturedInvestments.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveVestDetailsScreen(
                      investment: maturedInvestments[index],
                    ),
                  ),
                );
              },
              child: _activeinvestmentCard(maturedInvestments[index]),
            ),
          ),
        );
      },
      loading: () => _buildShimmerInvestmentList(),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildShimmerInvestmentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            'No Investment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _investmentCard(Investment investment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: (investment.images.isNotEmpty)
                ? Image.network(
              investment.images.first,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
            )
                : _buildImagePlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.investmentName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  'Min of ${ref.formatUserCurrency(investment.convertedMinimumAmount)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Roboto'),
                ),
                const SizedBox(height: 5),
                Text(
                  'ROI: ${investment.roi}% in ${investment.duration} months',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: investment.status == 'ACTIVE'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    investment.status,
                    style: TextStyle(
                        color: investment.status == 'ACTIVE'
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeinvestmentCard(ActiveVest investment) {
    DateTime? maturityDate;
    bool isMatured = false;

    try {
      if (investment.maturityDate.isNotEmpty) {
        maturityDate = DateFormat("MMM dd, yyyy").parse(investment.maturityDate);
        isMatured = DateTime.now().isAfter(maturityDate);
      }
    } catch (e) {
      maturityDate = null;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(12),
        border: isMatured ? Border.all(color: Colors.green, width: 1.5) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: (investment.vest?.images.isNotEmpty ?? false)
                ? Image.network(
              investment.vest!.images.first,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildImagePlaceholder(),
            )
                : _buildImagePlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.vest?.investmentName ?? "Unknown Investment",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  'Invested ${ref.formatUserCurrency(investment.amount)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  maturityDate != null
                      ? '${isMatured ? "Matured" : "Matures"}: ${DateFormat("dd/MM/yyyy").format(maturityDate)}'
                      : "No maturity date",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, color: Colors.white54),
    );
  }
}

// ========== ADD THIS PERSISTENT DELEGATE TO YOUR FILE ==========
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0C051F), // Matches screen's background color perfectly
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}