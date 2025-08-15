import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveInvestmentProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/getInvestmentProvider.dart';
import 'package:soundhive2/model/active_investment_model.dart';
import 'package:soundhive2/model/investment_model.dart';
import 'package:soundhive2/screens/dashboard/account/account.dart';
import 'package:soundhive2/screens/dashboard/transaction_history.dart';
import 'package:soundhive2/screens/dashboard/verification_webview.dart';
import 'package:soundhive2/screens/dashboard/vest/vest_details.dart';
import 'package:soundhive2/screens/dashboard/withdraw.dart';
import '../../../components/rounded_button.dart';
import '../../../model/user_model.dart';
import '../../../utils/utils.dart';
import 'active_vest_details.dart';

final authTokenProvider = FutureProvider<String?>((ref) async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'auth_token');
});

class SoundhiveVestScreen extends ConsumerStatefulWidget {
  static const String id = '/soundhivevest';
  final User user;
  SoundhiveVestScreen({required this.user});

  @override
  _SoundhiveVestScreenState createState() => _SoundhiveVestScreenState();
}

class _SoundhiveVestScreenState extends ConsumerState<SoundhiveVestScreen> with TickerProviderStateMixin {

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getInvestmentProvider.notifier).getInvestments();
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final notifier = ref.read(getInvestmentProvider.notifier);
      final activeNotifier = ref.read(getActiveInvestmentProvider.notifier);
      switch (_tabController.index) {
        case 0:
          notifier.getInvestments();
          break;
        case 1:
          activeNotifier.getActiveInvestments();
          break;
        case 2:
          activeNotifier.getActiveInvestments();
          break;
      }
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(authTokenProvider);
    return tokenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (token) {
        final serviceState = ref.watch(getInvestmentProvider);
        final activeState = ref.watch(getActiveInvestmentProvider);
        return Scaffold(
          backgroundColor: const Color(0xFF0C051F),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                const Text(
                  'Soundhive Vest',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(
                  height: 10,
                ),
                // Wallet Section
                // WalletCard(
                //     balance: widget.user.balance!,
                //     onAddFunds: () => Utils.showBankTransferBottomSheet(
                //         context,
                //         widget.user.paystackBankName,
                //       widget.user.paystackBankAccountNumber,
                //       widget.user.paystackBankAccountName
                //     )
                // ),

                SizedBox(height: 20),

                // Tabs
                Expanded(
                  child: Stack(
                    children: [
                      // Content Column (Tabs + Search + Investments)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tabs Section
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
                                const SizedBox(height: 10),
                                const Text(
                                  'Invest in artists, invest in events, share in catalogues and revenue',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 15),

                          // Search Bar
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for investments',
                              hintStyle: TextStyle(color: Colors.white54),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 15),

                          // Investment Cards List
                    Expanded(
                child: _tabController.index == 0
                ? _buildVestOptions(serviceState)
                  : _tabController.index == 1
              ? _buildActiveInvestments(activeState)
                : _buildMaturedInvestments(activeState),
        )

                        ],
                      ),

                      // Blur Overlay (Conditional)
                      // if (widget.user.bvnData == null)
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
                                  const Center(
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      "Verify your Identity to invest in projects, events and artists curated by Soundhive",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  RoundedButton(
                                    title: 'Verify my identity',
                                      onPressed: () {
                                        if (token != null) {
                                          final url = 'https://soundhive.igree.noblepay.online?token=$token';
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VerificationWebView(url: url),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Authentication token missing'),
                                            ),
                                          );
                                        }
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
  Widget _buildVestOptions(AsyncValue<InvestmentResponse> serviceState) {
    return  serviceState.when(
      data: (serviceResponse) {
        final allServices = serviceResponse.data;
        if (allServices.isEmpty) {
          return _buildEmptyState(context);
        }
        final filteredServices = allServices.where((service) =>
            service.investmentName.toLowerCase().contains(_searchController.text.toLowerCase())
        ).toList();

        return Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filteredServices.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: GestureDetector(
                    onTap: () {
                      Navigator.push(context,  MaterialPageRoute(
                        builder: (context) => VestDetailsScreen(
                          investment: filteredServices[index],
                          user: widget.user,
                        ),
                      ),);
                    },
                    child: _investmentCard(filteredServices[index])
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
  Widget _buildActiveInvestments(AsyncValue<ActiveInvestmentResponse> state) {
    return state.when(
      data: (response) {
        final allServices = response.data;
        if (allServices.isEmpty) {
          return _buildEmptyState(context);
        }
        // final filteredServices = allServices.where((service) =>
        //     service.investment.investmentName.toLowerCase().contains(_searchController.text.toLowerCase())
        // ).toList();
        if (response.data.isEmpty) return _buildEmptyState(context);
        return ListView.builder(
          itemCount: response.data.length,
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
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildMaturedInvestments(AsyncValue<ActiveInvestmentResponse> state) {
    return state.when(
      data: (response) {
        final maturedInvestments = response.data.where((investment) {
          try {
            final endDate = DateTime.parse(investment.endDate!);
            final currentDate = DateTime.now();
            return currentDate.isAfter(endDate);
          } catch (e) {
            return false;
          }
        }).toList();

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: const Text(
            'No Investment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }
  Widget _investmentCard(Investment investment) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Image section with proper error handling
          Container(
            width: 100, // Fixed width for image container
            height: 100,
            child: (investment.imageUrl?.isNotEmpty ?? false)
                ? Image.network(
              investment.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
            )
                : _buildImagePlaceholder(),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.investmentName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  'Min of ${Utils.formatCurrency(investment.minimumAmount)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Roboto',),
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
                    color: investment.status == 'AVAILABLE'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    investment.status,
                    style: TextStyle(
                        color: investment.status == 'AVAILABLE'
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

  Widget _activeinvestmentCard(ActiveInvestment investment) {
    final isMatured = () {
      try {
        return DateTime.now().isAfter(DateTime.parse(investment.endDate!));
      } catch (e) {
        return false;
      }
    }();
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(12),
        border: isMatured
            ? Border.all(color: Colors.green)
            : null,
      ),
      child: Row(
        children: [
          // Image section with proper error handling
          // Container(
          //   width: 100, // Fixed width for image container
          //   height: 100,
          //   child: (investment.investment.imageUrl.isNotEmpty)
          //       ? Image.network(
          //     investment.investment.imageUrl,
          //     fit: BoxFit.cover,
          //     errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
          //   )
          //       : _buildImagePlaceholder(),
          // ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   investment.investment.investmentName,
                //   style: TextStyle(
                //       color: Colors.white,
                //       fontSize: 16,
                //       fontWeight: FontWeight.bold
                //   ),
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                // ),
                SizedBox(height: 5),
                Text(
                  'Invested ${Utils.formatCurrency(investment.amount)}',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Roboto',),
                ),
                SizedBox(height: 5),
                Text(
                  // '${isMatured ? 'Matured' : 'Matures'}: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(investment.endDate))}',
                  '${isMatured ? 'Matured' : 'Matures'}: ${DateFormat('d MMMM, yyyy').format(DateFormat('dd-MM-yyyy').parse('15-05-2026'))}',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
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
