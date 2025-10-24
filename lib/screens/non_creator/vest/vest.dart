import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/lib/dashboard_provider/getInvestmentProvider.dart';
import 'package:soundhive2/model/investment_model.dart';
import 'package:soundhive2/screens/creator/profile/setup_screen.dart';
import 'package:soundhive2/screens/non_creator/vest/vest_details.dart';
import '../../../components/rounded_button.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveVestProvider.dart';
import '../../../lib/dashboard_provider/add_money_provider.dart';
import '../../../lib/dashboard_provider/user_provider.dart';
import '../../../model/add_money_model.dart';
import '../../../model/get_active_vest_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/utils.dart';
import '../../dashboard/verification_webview.dart';
import 'active_vest_details.dart';
import 'package:shimmer/shimmer.dart';

final authTokenProvider = FutureProvider<String?>((ref) async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'auth_token');
});

class SoundhiveVestScreen extends ConsumerStatefulWidget {
  static const String id = '/soundhivevest';
  final MemberCreatorResponse user;
  SoundhiveVestScreen({required this.user});

  @override
  _SoundhiveVestScreenState createState() => _SoundhiveVestScreenState();
}



class _SoundhiveVestScreenState extends ConsumerState<SoundhiveVestScreen> with TickerProviderStateMixin {

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_handleSearch);

    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getInvestmentProvider.notifier).getInvestments();
    });
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // Add a delay to avoid too many API calls while typing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchController.text.trim() == query) {
          ref.read(getInvestmentProvider.notifier).searchInvestments(query);
        }
      });
    } else {
      ref.read(getInvestmentProvider.notifier).getInvestments(reset: true);
    }
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreData();
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
    if (!_tabController.indexIsChanging) {
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        amount: double.parse(cleanAmount), // safe parse
        currency: ''
      );
      if (response.url != null) {
        if (!mounted) return;
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationWebView(url: response.url!, title: 'Add Money',),
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
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Soundhive Vest',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 10),
                // Wallet Section
                if(user?.wallet != null)
                  WalletCard(
                      balance: user?.wallet!.balance ?? '',
                      onAddFunds: () {
                        _showAmountInputModal();
                      },
                    user: widget.user,
                  ),
                const SizedBox(height: 20),
                // Tabs
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTabController(
                            length: 3,
                            child: Column(
                              children: [
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Investment Cards List
                          Expanded(
                            child: AnimatedPadding(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom,
                              ),
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

                        ],
                      ),

                      // Blur Overlay (Conditional)
                      if (user?.creator == null || user!.creator!.active == false)
                        Positioned.fill(
                          top: 50,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   Center(
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      (user?.creator == null) ?  "Complete your KYC so as to activate your Soundhive Vest Account Unlock your ability to Invest in verifiable and quality entertainment projects or artists, as well as share in their success.": "Your account is under review",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if(user?.creator == null)
                                  RoundedButton(
                                    title: 'Verify my identity',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SetupScreen(user: widget.user),
                                        ),
                                      );
                                    },
                                    color: const Color(0xFF4D3490),
                                    borderWidth: 0,
                                    borderRadius: 12.0,
                                  )
                                ],
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
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // 👈 helps UX
                padding: EdgeInsets.fromLTRB(
                  10, 10, 10,
                  MediaQuery.of(context).viewInsets.bottom + 10, // 👈 add bottom space when keyboard shows
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
            error: (error, _) => Center(child: Text('Error: $error')), // 👈 don’t return Expanded here
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
          itemCount: allServices.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,  MaterialPageRoute(
                      builder: (context) => ActiveVestDetailsScreen(
                        investment: allServices[index],
                      ),
                    ),);
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
      child: Icon(Icons.broken_image, color: Colors.white54),
    );
  }
}