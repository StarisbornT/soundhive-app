import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/non_creator/marketplace/categories.dart';
import 'package:soundhive2/screens/non_creator/marketplace/creators_list.dart';
import 'package:soundhive2/screens/non_creator/streaming/streaming.dart';
import 'package:soundhive2/utils/utils.dart';
import 'package:soundhive2/lib/dashboard_provider/categoryProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/creatorProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveInvestmentProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/getMarketPlaceService.dart';
import '../../../main.dart';
import '../../../model/creator_model.dart';
import '../../../model/market_orders_service_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/app_colors.dart';
import '../../creator/profile/setup_screen.dart';
import 'creator.dart';
import 'mark_as_completed.dart';
import 'marketplace_details.dart';

class Marketplace extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const Marketplace({super.key, required this.user});

  @override
  _MarketplaceState createState() => _MarketplaceState();
}

class _MarketplaceState extends ConsumerState<Marketplace>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  int selectedTabIndex = 0;
  final ScrollController _bookingsScrollController = ScrollController();
  bool _hasLoadedBookings = false;
  Timer? _searchDebounce;
  bool _isInitialized = false;
  final _searchController = TextEditingController();

  late List<String> _selectedFilters = [];
  bool _showFilters = true;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final routeObserver = ref.read(routeObserverProvider);
      routeObserver.subscribe(this, ModalRoute.of(context)!);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    if (_isInitialized) {
      final routeObserver = ref.read(routeObserverProvider);
      routeObserver.unsubscribe(this);
    }
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _bookingsScrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(getMarketplaceServiceProvider.notifier).resetFilters();
        ref.read(getMarketplaceServiceProvider.notifier).getMarketPlaceService();
      }
    });
  }

  @override
  void didPush() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Reset filters when navigating to marketplace
        ref.read(getMarketplaceServiceProvider.notifier).resetFilters();
        ref.read(getMarketplaceServiceProvider.notifier).getMarketPlaceService();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(_handleTabChange);
    _bookingsScrollController.addListener(_scrollListener);

    // Load initial data with delay between calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
        final route = ModalRoute.of(context);
        if (route != null) {
          route.addScopedWillPopCallback(() {
            // This will be called when popping from this screen
            ref.read(getMarketplaceServiceProvider.notifier).resetFilters();
            return SynchronousFuture(true);
          });
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      if (!mounted) return;

      await ref.read(getMarketplaceServiceProvider.notifier)
          .getMarketPlaceService(pageSize: 20);

      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      await Future.microtask(() {
        if (mounted) {
          ref.read(creatorProvider.notifier).getCreators();
        }
      });

    } catch (e) {
      if (mounted) debugPrint('Error loading initial data: $e');
    }
  }


  void _scrollListener() {
    if (_bookingsScrollController.position.pixels ==
        _bookingsScrollController.position.maxScrollExtent) {
      _loadMoreBookings();
    }
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && !_hasLoadedBookings) {
      ref.read(getActiveInvestmentProvider.notifier).getActiveInvestments(
        pageSize: 10, // Add pagination limit
      );
      _hasLoadedBookings = true;
    }
    if (mounted) {
      setState(() => selectedTabIndex = _tabController.index);
    }
  }

  Future<void> _loadMoreBookings() async {
    final notifier = ref.read(getActiveInvestmentProvider.notifier);
    if (!notifier.isLastPage && mounted) {
      await notifier.getActiveInvestments(loadMore: true);
    }
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(getMarketplaceServiceProvider.notifier).getMarketPlaceService(
          serviceName: value,
          pageSize: 20, // Add pagination limit
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listenManual<AsyncValue<void>>(getMarketplaceServiceProvider, (_, state) {
      if (!mounted) return;
      state.whenOrNull(error: (error, _) => debugPrint('Error: $error'));
    });

    // Listen to creator state changes
    ref.listen<AsyncValue<void>>(creatorProvider, (_, state) {
      state.whenOrNull(
        error: (error, stack) => debugPrint('Creator error: $error'),
      );
    });
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    if(widget.user.user?.creator == null)...[
                      GestureDetector(
                          onTap: (){
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
                      GestureDetector(
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SetupScreen(user: widget.user),
                            ),
                          );
                          },
                          child: Image.asset('images/banner.png')
                      )
                    ],
                    const SizedBox(height: 20,),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Utils.menuButton(
                            "Marketplace",
                            selectedTabIndex == 0,
                            onTap: () => _tabController.animateTo(0),
                          ),
                          const SizedBox(width: 10),
                          Utils.menuButton(
                            "My Bookings",
                            selectedTabIndex == 1,
                            onTap: () => _tabController.animateTo(1),
                          ),
                          const SizedBox(width: 10),
                          Utils.menuButton(
                            "My Events",
                            selectedTabIndex == 2,
                            onTap: () => _tabController.animateTo(2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (selectedTabIndex == 0)
                      buildMarketPlaceUI()
                    else if (selectedTabIndex == 1)
                      buildMyBookingsUI()
                    else
                      const SizedBox(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMyBookingsUI() {
    final investmentsState = ref.watch(getActiveInvestmentProvider);
    final investments = ref.read(getActiveInvestmentProvider.notifier).allServices;
    final isLastPage = ref.read(getActiveInvestmentProvider.notifier).isLastPage;
    final isLoadingMore = ref.read(getActiveInvestmentProvider.notifier).isLoadingMore;

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
                          builder: (context) => MarkAsCompletedScreen(
                            services: investment,
                            user: widget.user.user!,
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
                          service!.coverImage,
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

  Widget buildMarketPlaceUI() {
    final marketplaceState = ref.watch(getMarketplaceServiceProvider);
    final creatorState = ref.watch(creatorProvider);
    final servicesNotifier = ref.read(getMarketplaceServiceProvider.notifier);
    final services = servicesNotifier.allServices;


    return Column(
      children: [
        // Search Bar with debounce
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedFilters.isEmpty
                      ? TextFormField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                      ),
                      hintText: 'Search',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                  )
                      : _buildFilterChips(),
                ),
              ),
              if (_showFilters) _buildFilterButton(),
            ],
          ),
        ),

        // Services Around You Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Services around you',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Categories(user: widget.user),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2C2C2C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Text(
                  'View categories',
                  style: TextStyle(color: Color(0xFFB0B0B6), fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Marketplace Services Grid
        marketplaceState.when(
          loading: () => _buildShimmerServicesGrid(),
          error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
          data: (_) {
            final displayedServices = services;

            if (displayedServices.isEmpty) {
              return Center(
                child: Text(
                  _selectedFilters.isEmpty
                      ? "No services found"
                      : "No services match your filters",
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            return _buildServicesGrid(displayedServices);
          },
        ),

        // Banner
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Streaming()),
            ),
            child: Image.asset('images/discover.png'),
          ),
        ),

        // Creatives Section
        creatorState.when(
          loading: () => _buildShimmerCreativesSection(),
          error: (e, _) => Center(
              child: Text("Error loading creators: $e", style: const TextStyle(color: Colors.white))),
          data: (creatorListResponse) {
            final creators =
            (creatorListResponse.user?.data ?? []).where((c) => c.user != null).toList();

            final notifier = ref.read(creatorProvider.notifier);

            return CreativesSection(
              creators: creators,
              notifier: notifier,
            );
          },
        ),

        // More Services Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'More services for you',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Categories(user: widget.user),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2C2C2C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Text(
                  'View categories',
                  style: TextStyle(color: Color(0xFFB0B0B6), fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // More Services List
        marketplaceState.when(
          loading: () => _buildShimmerMoreServicesList(),
          error: (e, _) => Center(
              child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
          data: (_) {
            if (services.isEmpty) {
              return const Center(
                child: Text("No services found", style: TextStyle(color: Colors.white)),
              );
            }
            return _buildMoreServicesList(services);
          },
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShimmerServicesGrid() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        itemBuilder: (context, pageIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 5,
              childAspectRatio: 0.75,
              children: List.generate(4, (index) => _buildShimmerServiceItem()),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerServiceItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[700]!,
      highlightColor: Colors.grey[500]!,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 80,
                        height: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 40,
                            height: 8,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 40,
                            height: 8,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCreativesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[500]!,
                child: Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[500]!,
                child: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[700]!,
                  highlightColor: Colors.grey[500]!,
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerMoreServicesList() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[700]!,
              highlightColor: Colors.grey[500]!,
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2C2C2C)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _selectedFilters.map((filter) {
                  String displayText = '';
                  VoidCallback? onRemove;

                  if (filter.startsWith('Category:')) {
                    displayText = filter.replaceFirst('Category:', '');
                    onRemove = () {
                      setState(() {
                        // Remove both category name and ID filters
                        _selectedFilters.removeWhere((f) =>
                        f.startsWith('Category:') || f.startsWith('CategoryId:'));
                        if (_selectedFilters.isEmpty) {
                          _showFilters = true;
                        }
                        // Reset to get all services without filters
                        ref.read(getMarketplaceServiceProvider.notifier).resetMarketplaceState();
                      });
                    };
                  } else if (filter.startsWith('Min:')) {
                    displayText = filter.replaceFirst('Min:', 'Min');
                    onRemove = () {
                      setState(() {
                        _selectedFilters.remove(filter);
                        if (_selectedFilters.isEmpty) {
                          _showFilters = true;
                        }
                        // Reapply filters without the min price
                        _applyServerFilters();
                      });
                    };
                  } else if (filter.startsWith('Max:')) {
                    displayText = filter.replaceFirst('Max:', 'Max');
                    onRemove = () {
                      setState(() {
                        _selectedFilters.remove(filter);
                        if (_selectedFilters.isEmpty) {
                          _showFilters = true;
                        }
                        // Reapply filters without the max price
                        _applyServerFilters();
                      });
                    };
                  } else {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A191E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          displayText,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onRemove,
                          child: const Icon(Icons.close, size: 14, color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilters.clear();
                _showFilters = true;
                // Reset to get all services without filters
                ref.read(getMarketplaceServiceProvider.notifier).resetMarketplaceState();
              });
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _applyServerFilters() {
    int? categoryId;
    double? minPrice;
    double? maxPrice;

    for (final filter in _selectedFilters) {
      if (filter.startsWith('CategoryId:')) {
        categoryId = int.tryParse(filter.replaceFirst('CategoryId:', ''));
      } else if (filter.startsWith('Min:')) {
        minPrice = double.tryParse(filter.replaceAll('Min: ₦', '').replaceAll(',', ''));
      } else if (filter.startsWith('Max:')) {
        maxPrice = double.tryParse(filter.replaceAll('Max: ₦', '').replaceAll(',', ''));
      }
    }

    // Apply server-side filters
    ref.read(getMarketplaceServiceProvider.notifier).applyFilters(
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
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

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white30),
            onPressed: () async {
              final filters = await Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                  const FilterScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0, 1);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );

              if (filters != null && filters.isNotEmpty && mounted) {
                setState(() {
                  _selectedFilters = filters;
                  _showFilters = false;

                  // Apply server-side filters using the helper method
                  _applyServerFilters();
                });
              }
            },
          ),
          const Text(
            'Filter',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(List<MarketOrder> services) {
    final pageCount = (services.length / 4).ceil();
    final rowCount = (services.length / 2).ceil();
    final gridHeight = rowCount * 220;

    return SizedBox(
      height: gridHeight.toDouble().clamp(220, 480),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels == notification.metrics.maxScrollExtent) {
            ref.read(getMarketplaceServiceProvider.notifier).getMarketPlaceService(
              loadMore: true,
              pageSize: 20,
            );
          }
          return false;
        },
        child: PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: pageCount,
          itemBuilder: (context, pageIndex) {
            final startIndex = pageIndex * 4;
            final endIndex = (startIndex + 4).clamp(0, services.length);
            final pageItems = services.sublist(startIndex, endIndex);

            // Create a list of items for this page, filling empty slots with empty containers
            final gridItems = List<Widget>.generate(4, (index) {
              if (index < pageItems.length) {
                return _buildServiceItem(pageItems[index]);
              } else {
                return const SizedBox.shrink(); // Empty slot
              }
            });

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 5,
                childAspectRatio: 0.75,
                children: gridItems,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceItem(MarketOrder item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarketplaceDetails(service: item, user: widget.user),
        ),
      ),
      child: _buildServiceCard(
        context,
        title: item.serviceName,
        price: ref.formatUserCurrency(item.convertedRate),
        name: "${item.user?.firstName} ${item.user?.lastName}",
        rating: 4.5,
        clients: '20k clients',
        location: item.status,
        isRemote: item.status.toLowerCase().contains('remote'),
        image: item.coverImage,
      ),
    );
  }

  Widget _buildMoreServicesList(List<MarketOrder> services) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        itemCount: services.length,
        itemBuilder: (context, index) {
          final item = services[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarketplaceDetails(service: item, user: widget.user),
              ),
            ),
            child: _buildServiceCard(
              context,
              title: item.serviceName,
              price: ref.formatUserCurrency(item.convertedRate),
              name: "${item.user?.firstName ?? ''} ${item.user?.lastName ?? ''}",
              rating: 4.5,
              clients: '20k clients',
              location: item.status,
              isRemote: item.status.toLowerCase().contains('remote'),
              image: item.coverImage,
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(
      BuildContext context, {
        required String title,
        required String price,
        required String name,
        required double rating,
        required String clients,
        required String location,
        required String image,
        bool isRemote = false,
      }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(left: 16.0, right: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A191E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF6A0DAD),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: CachedNetworkImageProvider(image),
                fit: BoxFit.cover,
              ),
            ),
            child: isRemote
                ? const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: GoogleFonts.notoSans(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                    )
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        Text(
                          '$rating rating',
                          style: const TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.group, color: Colors.white70, size: 14),
                        Text(
                          clients,
                          style: const TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(color: Colors.white70, fontSize: 8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
const Color kPurpleAccent = AppColors.BUTTONCOLOR; // A shade of deep purple

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  final TextEditingController maximumAmount = TextEditingController();
  final TextEditingController minimumAmount = TextEditingController();

  // Track selected filters - now only single selection
  String? selectedCategory;
  String? selectedCategoryId;
  final Set<String> selectedLocations = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryProvider.notifier).getCategory();
    });
  }

  @override
  void dispose() {
    maximumAmount.dispose();
    minimumAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter by',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Category Section
                      const Text(
                        'Choose a Category',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      categoryState.when(
                        data: (categories) => Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: categories.data.data.map((category) {
                            return FilterChip(
                              label: category.name,
                              selected: selectedCategory == category.name,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedCategory = category.name;
                                    selectedCategoryId = category.id.toString();
                                  } else if (selectedCategory == category.name) {
                                    selectedCategory = null;
                                    selectedCategoryId = null;
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        loading: () => Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: List.generate(6, (index) => Shimmer.fromColors(
                            baseColor: Colors.grey[700]!,
                            highlightColor: Colors.grey[500]!,
                            child: Container(
                              width: 80,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          )),
                        ),
                        error: (e, _) => const Text(
                          'Error loading categories',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Budget Section
                      const Text(
                        'Enter your Budget',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: LabeledTextField(
                              label: 'Minimum Amount',
                              controller: minimumAmount,
                              hintText: '₦0.00',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '-',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LabeledTextField(
                              label: 'Maximum Amount',
                              controller: maximumAmount,
                              hintText: '₦0.00',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Filter Button
              RoundedButton(
                title: 'Apply Filters',
                onPressed: () {
                  final List<String> filters = [];

                  // Add selected category with a prefix (only one category allowed)
                  if (selectedCategory != null) {
                    filters.add('Category:$selectedCategory');
                    if (selectedCategoryId != null) {
                      filters.add('CategoryId:$selectedCategoryId');
                    }
                  }

                  // Add budget range if specified
                  if (minimumAmount.text.isNotEmpty) {
                    filters.add('Min: ₦${minimumAmount.text}');
                  }
                  if (maximumAmount.text.isNotEmpty) {
                    filters.add('Max: ₦${maximumAmount.text}');
                  }

                  Navigator.pop(context, filters);
                },
                color: AppColors.BUTTONCOLOR,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return RawChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontSize: 14,
        ),
      ),
      backgroundColor: selected ? kPurpleAccent : const Color(0xFF1A191E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide.none,
      onPressed: () => onSelected(!selected),
    );
  }
}

class CreativesSection extends StatefulWidget {
  final List<CreatorData> creators;
  final CreatorNotifier notifier;

  const CreativesSection({
    super.key,
    required this.creators,
    required this.notifier,
  });

  @override
  _CreativesSectionState createState() => _CreativesSectionState();
}

class _CreativesSectionState extends State<CreativesSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        widget.notifier.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creators = widget.creators;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Highly rated creatives',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              OutlinedButton(
                onPressed: creators.isNotEmpty
                    ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatorsList(),
                  ),
                )
                    : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2C2C2C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(color: Color(0xFFB0B0B6), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        if (creators.isEmpty)
          const Center(
            child: Text("No creatives found",
                style: TextStyle(color: Colors.white)),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: creators.length,
              itemBuilder: (context, index) {
                final creator = creators[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatorProfile(creator: creator),
                    ),
                  ),
                  child: Utils.buildCreativeCard(
                    context,
                    name:
                    '${creator.user?.firstName} ${creator.user?.lastName}',
                    role: creator.jobTitle,
                    rating: 4.8,
                    profileImage: creator.user?.image ?? '',
                    firstName: creator.user?.firstName ?? '',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

