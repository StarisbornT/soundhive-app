import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/lib/dashboard_provider/getInvestmentProvider.dart';
import 'package:soundhive2/model/investment_model.dart';
import 'package:soundhive2/screens/non_creator/vest/vest_details.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveVestProvider.dart';
import '../../../components/kyc_blur_overlay.dart';
import '../../../model/get_active_vest_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/utils.dart';
import '../../creator/profile/setup_screen.dart';
import '../../dashboard/withdraw.dart';
import '../wallet/add_money_screen.dart';
import '../wallet/wallet_cards.dart';
import 'active_vest_details.dart';
import 'package:shimmer/shimmer.dart';

import 'artist_vest.dart';

final authTokenProvider = FutureProvider<String?>((ref) async {
  const storage = FlutterSecureStorage();
  return await storage.read(key: 'auth_token');
});

class SoundHiveVestScreen extends ConsumerStatefulWidget {
  static const String id = '/soundhivevest';
  final MemberCreatorResponse user;
  const SoundHiveVestScreen({super.key, required this.user});

  @override
  ConsumerState<SoundHiveVestScreen> createState() =>
      _SoundHiveVestScreenState();
}

class _SoundHiveVestScreenState extends ConsumerState<SoundHiveVestScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _isLoadingMore = false;
  final ScrollController _innerScrollController = ScrollController();

  // Filter track state variables
  String _activeTypeFilter = 'ALL';
  String _activeStageFilter = 'ALL';

  // Tracking current active playing index for preview players
  int? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_handleSearch);
    _innerScrollController.addListener(_handleScroll);

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
    _innerScrollController.dispose();
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
    if (_tabController.indexIsChanging) return;

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
      MaterialPageRoute(
          builder: (context) => const WithdrawScreen(walletType: 'NGN')),
    );
  }

  // NEW — single navigation entry point for tapping an investment card.
  // Artist vests must build trust first (Overview -> Portfolio -> Project
  // -> Opportunity) before reaching the invest action. General vests keep
  // the original behaviour: straight into VestDetailsScreen.
  void _openInvestment(Investment investment) {
    if (investment.isArtistVest) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArtistVestFlowScreen(
            investment: investment,
            user: widget.user.user!,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VestDetailsScreen(
            investment: investment,
            user: widget.user.user!,
          ),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(authTokenProvider);
    final bool showBlur = widget.user.user?.creator == null ||
        widget.user.user?.creator!.active == false;
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
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cre8Vest',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (user?.wallet != null)
                            WalletBalanceCard(
                              title: 'Base balance',
                              balance: user?.wallet?.balance != null
                                  ? ref
                                  .formatUserCurrency(user?.wallet?.balance)
                                  : '',
                              currencySymbol: user?.wallet!.currency ?? '',
                              onAddFunds: () => _showAmountInputModal(
                                  user?.wallet!.currency ?? ''),
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
                child: Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVestOptions(serviceState),
                        _buildActiveInvestments(activeState),
                        _buildMaturedInvestments(activeState),
                      ],
                    ),
                    KycBlurOverlay(
                      showBlur: showBlur,
                      user: widget.user,
                      onVerifyPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SetupScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
        const SizedBox(height: 12),

        _buildFilterChipsTier(),
        const SizedBox(height: 10),

        Expanded(
          child: serviceState.when(
            data: (serviceResponse) {
              final allServices = serviceResponse.data.data;
              if (allServices.isEmpty) return _buildEmptyState(context);

              return ListView.builder(
                controller: _innerScrollController,
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
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
                      // CHANGED: was an unconditional push to VestDetailsScreen.
                      // Now routes through _openInvestment so artist vests go
                      // through the 5-stage flow, general vests unaffected.
                      onTap: () => _openInvestment(allServices[index]),
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

  Widget _buildFilterChipsTier() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip(
              label: 'All Vests',
              isActive: _activeTypeFilter == 'ALL',
              onTap: () => _updateTypeFilter('ALL')),
          _filterChip(
              label: '🎵 Artist Vests',
              isActive: _activeTypeFilter == 'ARTIST',
              onTap: () => _updateTypeFilter('ARTIST')),
          _filterChip(
              label: '💼 General Vests',
              isActive: _activeTypeFilter == 'GENERAL',
              onTap: () => _updateTypeFilter('GENERAL')),

          if (_activeTypeFilter == 'ARTIST') ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0),
              child: Text('|', style: TextStyle(color: Colors.white24)),
            ),
            _filterChip(
                label: 'All Stages',
                isActive: _activeStageFilter == 'ALL',
                onTap: () => _updateStageFilter('ALL')),
            _filterChip(
                label: '🚀 Pre-Release',
                isActive: _activeStageFilter == 'PRE_RELEASE',
                onTap: () => _updateStageFilter('PRE_RELEASE')),
            _filterChip(
                label: '💿 Released',
                isActive: _activeStageFilter == 'RELEASED',
                onTap: () => _updateStageFilter('RELEASED')),
          ]
        ],
      ),
    );
  }

  Widget _filterChip(
      {required String label,
        required bool isActive,
        required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onTap(),
        selectedColor: Colors.purple.shade700,
        backgroundColor: Colors.white10,
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }

  void _updateTypeFilter(String value) {
    setState(() {
      _activeTypeFilter = value;
      if (value != 'ARTIST') _activeStageFilter = 'ALL';
    });
    ref.read(getInvestmentProvider.notifier).filterVests(
      type: _activeTypeFilter,
      stage: _activeStageFilter,
    );
  }

  void _updateStageFilter(String value) {
    setState(() {
      _activeStageFilter = value;
    });
    ref.read(getInvestmentProvider.notifier).filterVests(
      type: _activeTypeFilter,
      stage: _activeStageFilter,
    );
  }

  Widget _investmentCard(Investment investment) {
    final bool isArtist = investment.isArtistVest;
    final artistDetails = investment.artistDetails;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(12),
        border: isArtist
            ? Border.all(color: Colors.purple.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (investment.images.isNotEmpty)
                      ? Image.network(
                    investment.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImagePlaceholder(),
                  )
                      : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isArtist
                                ? Colors.purple.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isArtist ? "ARTIST VEST" : "GENERAL VEST",
                            style: TextStyle(
                              color: isArtist
                                  ? Colors.purple.shade300
                                  : Colors.blue.shade300,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
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
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      investment.investmentName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Min: ${ref.formatUserCurrency(investment.convertedMinimumAmount)}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ROI: ${investment.roi}% • ${investment.duration} mos',
                      style:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isArtist && artistDetails != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stage: ${artistDetails.projectStage}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Split: ${artistDetails.revenueSplitInvestor.toStringAsFixed(0)}% to Investors',
                  style:
                  const TextStyle(color: Colors.purpleAccent, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: artistDetails.fundingProgress,
                      backgroundColor: Colors.white10,
                      color: Colors.purpleAccent,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${artistDetails.fundingProgressPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (artistDetails.previewAudioUrl != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_currentlyPlayingId == investment.id) {
                      _currentlyPlayingId = null;
                    } else {
                      _currentlyPlayingId = investment.id;
                    }
                  });
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentlyPlayingId == investment.id
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.purpleAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentlyPlayingId == investment.id
                            ? 'Playing Preview Snippet...'
                            : 'Listen to Track Preview',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ]
        ],
      ),
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveVestDetailsScreen(
                            investment: allServices[index],
                          ),
                        ));
                  },
                  child: _activeinvestmentCard(allServices[index])),
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
            'No Investment Found',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _activeinvestmentCard(ActiveVest investment) {
    DateTime? maturityDate;
    bool isMatured = false;

    try {
      if (investment.maturityDate.isNotEmpty) {
        maturityDate =
            DateFormat("MMM dd, yyyy").parse(investment.maturityDate);
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
                      fontFamily: 'Roboto'),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0C051F),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}