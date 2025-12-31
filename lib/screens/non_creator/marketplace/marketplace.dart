import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/non_creator/marketplace/categories.dart';
import 'package:soundhive2/screens/non_creator/marketplace/creators_list.dart';
import 'package:soundhive2/screens/non_creator/marketplace/ticket_detail_screen.dart';
import 'package:soundhive2/screens/non_creator/streaming/streaming.dart';
import 'package:soundhive2/utils/utils.dart';
import 'package:soundhive2/lib/dashboard_provider/categoryProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/creatorProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveInvestmentProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/getMarketPlaceService.dart';
import '../../../lib/dashboard_provider/eventMarketPlaceProvider.dart';
import '../../../lib/dashboard_provider/getMyTicketProvider.dart';
import '../../../main.dart';
import '../../../model/creator_model.dart';
import '../../../model/market_orders_service_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/app_colors.dart';
import '../../creator/profile/setup_screen.dart';
import '../ai/ai_conversation_list.dart';
import 'creator.dart';
import 'event_details.dart';
import 'mark_as_completed.dart';
import 'marketplace_details.dart';

class Marketplace extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const Marketplace({super.key, required this.user});

  @override
  ConsumerState<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends ConsumerState<Marketplace>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  int selectedTabIndex = 0;
  final ScrollController _bookingsScrollController = ScrollController();
  final ScrollController _eventScrollController = ScrollController();
  final ScrollController _myEventScrollController = ScrollController();
  bool _hasLoadedBookings = false;
  Timer? _searchDebounce;
  bool _isInitialized = false;
  final _searchController = TextEditingController();

  late List<String> _selectedFilters = [];
  bool _showFilters = true;
  int selectedEventSubTab = 0;

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
    _eventScrollController.dispose();
    _myEventScrollController.dispose();
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
    _eventScrollController.addListener(_scrollEventListener);
    _myEventScrollController.addListener(_scrollMyEventListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
        final route = ModalRoute.of(context);
        if (route != null) {
          route.addScopedWillPopCallback(() {
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

      await ref
          .read(getMarketplaceServiceProvider.notifier)
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

  void _scrollEventListener() {
    if (_eventScrollController.position.pixels ==
        _eventScrollController.position.maxScrollExtent) {
      _loadMoreEvent();
    }
  }

  void _scrollMyEventListener() {
    if (_myEventScrollController.position.pixels ==
        _myEventScrollController.position.maxScrollExtent) {
      _loadMoreMyEvent();
    }
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && !_hasLoadedBookings) {
      ref.read(getActiveInvestmentProvider.notifier).getActiveInvestments(
        pageSize: 10,
      );
      _hasLoadedBookings = true;
    } else if (_tabController.index == 2) {
      ref.read(eventMarketPlaceProvider.notifier).getEventMarketplace();
      ref.read(getMyTicketProvider.notifier).getMyTicket();
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

  Future<void> _loadMoreEvent() async {
    final notifier = ref.read(eventMarketPlaceProvider.notifier);
    if (!notifier.isLastPage && mounted) {
      await notifier.getEventMarketplace(loadMore: true);
    }
  }

  Future<void> _loadMoreMyEvent() async {
    final notifier = ref.read(getMyTicketProvider.notifier);
    if (!notifier.isLastPage && mounted) {
      await notifier.getMyTicket(loadMore: true);
    }
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final searchTerm = value.trim();

        if (searchTerm.isEmpty) {
          ref.read(getMarketplaceServiceProvider.notifier).resetMarketplaceState();
        } else {
          ref
              .read(getMarketplaceServiceProvider.notifier)
              .getMarketPlaceService(
            searchTerm: searchTerm,
            pageSize: 20,
          );
        }
      }
    });
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listenManual<AsyncValue<void>>(
        getMarketplaceServiceProvider, (_, state) {
      if (!mounted) return;
      state.whenOrNull(error: (error, _) => debugPrint('Error: $error'));
    });

    ref.listen<AsyncValue<void>>(creatorProvider, (_, state) {
      state.whenOrNull(
        error: (error, stack) => debugPrint('Creator error: $error'),
      );
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed header section (banner + tabs)
              Column(
                children: [
                  if (widget.user.user?.creator == null) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetupScreen(user: widget.user),
                          ),
                        );
                      },
                      child: Image.asset('images/banner.png'),
                    )
                  ] else if (!(widget.user.user?.creator!.active ?? false)) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetupScreen(user: widget.user),
                          ),
                        );
                      },
                      child: Image.asset('images/banner.png'),
                    )
                  ],
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        _buildTabButton("Marketplace", selectedTabIndex == 0,
                            onTap: () => _tabController.animateTo(0)),
                        const SizedBox(width: 10),
                        _buildTabButton("My Bookings", selectedTabIndex == 1,
                            onTap: () => _tabController.animateTo(1)),
                        const SizedBox(width: 10),
                        _buildTabButton("My Events", selectedTabIndex == 2,
                            onTap: () => _tabController.animateTo(2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),

              // Tab content with different scrolling behaviors
              if (selectedTabIndex == 0)
              // Marketplace - Scrollable page
                Expanded(
                  child: SingleChildScrollView(
                    child: buildMarketPlaceUI(theme, isDark),
                  ),
                )
              else if (selectedTabIndex == 1)
              // Bookings - Full screen list with pagination
                Expanded(
                  child: buildMyBookingsUI(theme, isDark),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildEventSubTabs(theme, isDark),
                      const SizedBox(height: 12),
                      Expanded(
                        child: selectedEventSubTab == 0
                            ? buildEventUI(theme, isDark)
                            : buildMyEventUI(theme, isDark),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: SizedBox(
          width: 70,
          height: 70,
          child: RawMaterialButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AiChatConversationScreen()));
            },
            fillColor: AppColors.BUTTONCOLOR,
            shape: const CircleBorder(),
            elevation: 6,
            child: Image.asset(
              "images/ai_chat.png",
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.BUTTONCOLOR
              : isDark
              ? Colors.grey[900]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDark
                ? Colors.white70
                : Colors.black87,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget buildMyBookingsUI(ThemeData theme, bool isDark) {
    final investmentsState = ref.watch(getActiveInvestmentProvider);
    final investments = ref.read(getActiveInvestmentProvider.notifier).allServices;
    final isLastPage = ref.read(getActiveInvestmentProvider.notifier).isLastPage;
    final isLoadingMore =
        ref.read(getActiveInvestmentProvider.notifier).isLoadingMore;

    return investmentsState.when(
      loading: () => _buildShimmerBookingsList(isDark),
      error: (e, _) => Center(
        child: Text(
          "Error: $e",
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
      data: (_) {
        if (investments.isEmpty) {
          return Center(
            child: Text(
              "No bookings found",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollEndNotification) {
                    final metrics = scrollNotification.metrics;
                    if (metrics.pixels >= metrics.maxScrollExtent * 0.8 &&
                        !isLastPage &&
                        !isLoadingMore) {
                      _loadMoreBookings();
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _bookingsScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              ),
                            ),
                          );
                        }
                      },
                      child: Card(
                        color: theme.cardColor,
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
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          )
                              : CircleAvatar(
                            backgroundColor: AppColors.BUTTONCOLOR,
                            child: Icon(Icons.work,
                                color: theme.colorScheme.onPrimary),
                          ),
                          title: Text(
                            service?.serviceName ?? "Booking #${investment.id}",
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Booked on ${DateFormat('dd/MM/yyyy').format(DateTime.parse(investment.createdAt))}",
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: investment.status == "PENDING"
                                      ? const Color.fromRGBO(255, 193, 7, 0.1)
                                      : const Color.fromRGBO(76, 175, 80, 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  investment.status == "PENDING"
                                      ? 'Ongoing'
                                      : 'Completed',
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
              ),
            ),

            // Loading indicator at bottom
            if (isLoadingMore)
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: _buildLoadingIndicator(isDark)),
              ),
          ],
        );
      },
    );
  }

  Widget buildEventSubTabs(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _eventSubTab(
            title: "Explore",
            isSelected: selectedEventSubTab == 0,
            theme: theme,
            onTap: () {
              setState(() => selectedEventSubTab = 0);
            },
          ),
          const SizedBox(width: 24),
          _eventSubTab(
            title: "My Events",
            isSelected: selectedEventSubTab == 1,
            theme: theme,
            onTap: () {
              setState(() => selectedEventSubTab = 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _eventSubTab({
    required String title,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? AppColors.BUTTONCOLOR
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          if (isSelected)
            Container(
              width: 102,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.BUTTONCOLOR,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildEventUI(ThemeData theme, bool isDark) {
    final investmentsState = ref.watch(eventMarketPlaceProvider);
    final investments = ref.read(eventMarketPlaceProvider.notifier).allServices;
    final isLastPage = ref.read(eventMarketPlaceProvider.notifier).isLastPage;
    final isLoadingMore =
        ref.read(eventMarketPlaceProvider.notifier).isLoadingMore;

    return investmentsState.when(
      loading: () => _buildShimmerBookingsList(isDark),
      error: (e, _) => Center(
        child: Text(
          "Error: $e",
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
      data: (_) {
        if (investments.isEmpty) {
          return Center(
            child: Text(
              "No bookings found",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollEndNotification) {
                    final metrics = scrollNotification.metrics;
                    if (metrics.pixels >= metrics.maxScrollExtent * 0.8 &&
                        !isLastPage &&
                        !isLoadingMore) {
                      _loadMoreEvent();
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _eventScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: investments.length,
                  itemBuilder: (context, index) {
                    final investment = investments[index];
                    final item = investment;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetails(
                              event: investment,
                              user: widget.user.user!,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: (item.image.isNotEmpty)
                                  ? Image.network(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Utils.buildImagePlaceholder(),
                              )
                                  : Utils.buildImagePlaceholder(),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title,
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                          size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(item.location,
                                            style: TextStyle(
                                                color: theme.colorScheme.onSurface
                                                    .withOpacity(0.6),
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      // Status badge
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.isUpcoming
                                                ? const Color.fromRGBO(
                                                255, 193, 7, 0.1)
                                                : item.isCompleted
                                                ? const Color.fromRGBO(
                                                76, 175, 80, 0.1)
                                                : item.isOngoing
                                                ? const Color.fromRGBO(
                                                188, 174, 226, 0.1)
                                                : const Color.fromRGBO(
                                                244, 67, 54, 0.1),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            item.eventStatus,
                                            style: TextStyle(
                                              color: item.isUpcoming
                                                  ? const Color(0xFFFFC107)
                                                  : item.isCompleted
                                                  ? const Color(0xFF4CAF50)
                                                  : item.isOngoing
                                                  ? const Color(
                                                  0xFFBCAEE2)
                                                  : const Color(
                                                  0xFFF44336),
                                              fontSize: 10,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          "${formatDate(item.date)}, ${item.time}",
                                          style: TextStyle(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 8),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                                item.type == "PAID"
                                    ? ref.formatUserCurrency(item.convertedRate)
                                    : item.type,
                                style: TextStyle(
                                    color:
                                    theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Loading indicator at bottom
            if (isLoadingMore)
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: _buildLoadingIndicator(isDark)),
              ),
          ],
        );
      },
    );
  }

  Widget buildMyEventUI(ThemeData theme, bool isDark) {
    final investmentsState = ref.watch(getMyTicketProvider);
    final investments = ref.read(getMyTicketProvider.notifier).allServices;
    final isLastPage = ref.read(getMyTicketProvider.notifier).isLastPage;
    final isLoadingMore = ref.read(getMyTicketProvider.notifier).isLoadingMore;

    return investmentsState.when(
      loading: () => _buildShimmerBookingsList(isDark),
      error: (e, _) => Center(
        child: Text(
          "Error: $e",
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
      data: (_) {
        if (investments.isEmpty) {
          return Center(
            child: Text(
              "No bookings found",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollEndNotification) {
                    final metrics = scrollNotification.metrics;
                    if (metrics.pixels >= metrics.maxScrollExtent * 0.8 &&
                        !isLastPage &&
                        !isLoadingMore) {
                      _loadMoreEvent();
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _myEventScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: investments.length,
                  itemBuilder: (context, index) {
                    final investment = investments[index];
                    final item = investment.event;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TicketDetailScreen(
                              ticket: investment,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: (item.image.isNotEmpty)
                                  ? Image.network(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Utils.buildImagePlaceholder(),
                              )
                                  : Utils.buildImagePlaceholder(),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title,
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                          size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(item.location,
                                            style: TextStyle(
                                                color: theme.colorScheme.onSurface
                                                    .withOpacity(0.6),
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.isUpcoming
                                                ? const Color.fromRGBO(
                                                255, 193, 7, 0.1)
                                                : item.isCompleted
                                                ? const Color.fromRGBO(
                                                76, 175, 80, 0.1)
                                                : item.isOngoing
                                                ? const Color.fromRGBO(
                                                188, 174, 226, 0.1)
                                                : const Color.fromRGBO(
                                                244, 67, 54, 0.1),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            item.eventStatus,
                                            style: TextStyle(
                                              color: item.isUpcoming
                                                  ? const Color(0xFFFFC107)
                                                  : item.isCompleted
                                                  ? const Color(0xFF4CAF50)
                                                  : item.isOngoing
                                                  ? const Color(
                                                  0xFFBCAEE2)
                                                  : const Color(
                                                  0xFFF44336),
                                              fontSize: 10,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          "${formatDate(item.date)}, ${item.time}",
                                          style: TextStyle(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 8),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                                item.type == "PAID"
                                    ? ref.formatUserCurrency(investment.amount)
                                    : item.type,
                                style: TextStyle(
                                    color:
                                    theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Loading indicator at bottom
            if (isLoadingMore)
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: _buildLoadingIndicator(isDark)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerBookingsList(bool isDark) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildMarketPlaceUI(ThemeData theme, bool isDark) {
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
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedFilters.isEmpty
                      ? TextFormField(
                    controller: _searchController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: theme.dividerColor.withOpacity(0.5)),
                      ),
                      hintText: 'Search',
                      hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5)),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14.0),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.5)),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(
                              getMarketplaceServiceProvider.notifier)
                              .resetMarketplaceState();
                        },
                      )
                          : null,
                    ),
                  )
                      : _buildFilterChips(theme),
                ),
              ),
              if (_showFilters) _buildFilterButton(theme, isDark),
            ],
          ),
        ),

        // Services Around You Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Services around you',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Categories(),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  'Explore Hives',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Marketplace Services Grid
        marketplaceState.when(
          loading: () => _buildShimmerServicesGrid(isDark),
          error: (e, _) => Center(
              child: Text("Error: $e",
                  style: TextStyle(color: theme.colorScheme.error))),
          data: (_) {
            final displayedServices = services;

            if (displayedServices.isEmpty) {
              return Center(
                child: Text(
                  _selectedFilters.isEmpty
                      ? "No services found"
                      : "No services match your filters",
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              );
            }

            return _buildServicesGrid(displayedServices, theme, isDark, ref);
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
          loading: () => _buildShimmerCreativesSection(theme, isDark),
          error: (e, _) => Center(
              child: Text("Error loading creators: $e",
                  style: TextStyle(color: theme.colorScheme.error))),
          data: (creatorListResponse) {
            final creators = (creatorListResponse.user?.data ?? [])
                .where((c) => c.user != null)
                .toList();

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
              Text(
                'More services for you',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Categories(),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  'Explore Hives',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // More Services List
        marketplaceState.when(
          loading: () => _buildShimmerMoreServicesList(isDark),
          error: (e, _) => Center(
              child: Text("Error: $e",
                  style: TextStyle(color: theme.colorScheme.error))),
          data: (_) {
            if (services.isEmpty) {
              return Center(
                child: Text("No services found",
                    style: TextStyle(color: theme.colorScheme.onSurface)),
              );
            }
            return _buildMoreServicesList(services, theme, isDark);
          },
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShimmerServicesGrid(bool isDark) {
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
              children: List.generate(4, (index) => _buildShimmerServiceItem(isDark)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerServiceItem(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
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
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 14,
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[300],
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 80,
                        height: 10,
                        color: isDark ? Colors.grey[600] : Colors.grey[300],
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
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 40,
                            height: 8,
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 40,
                            height: 8,
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
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

  Widget _buildShimmerCreativesSection(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
                child: Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
                child: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
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
                  baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
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

  Widget _buildShimmerMoreServicesList(bool isDark) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list,
              color: theme.colorScheme.onSurface.withOpacity(0.5), size: 20),
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
                        _selectedFilters.removeWhere((f) =>
                        f.startsWith('Category:') ||
                            f.startsWith('CategoryId:'));
                        if (_selectedFilters.isEmpty) {
                          _showFilters = true;
                        }
                        ref
                            .read(getMarketplaceServiceProvider.notifier)
                            .resetMarketplaceState();
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
                        _applyServerFilters();
                      });
                    };
                  } else {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          displayText,
                          style: TextStyle(
                              color: theme.colorScheme.onSurface, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onRemove,
                          child: Icon(Icons.close,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5)),
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
                ref
                    .read(getMarketplaceServiceProvider.notifier)
                    .resetMarketplaceState();
              });
            },
            child: Text(
              'Clear',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12),
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
        minPrice = double.tryParse(
            filter.replaceAll('Min: ₦', '').replaceAll(',', ''));
      } else if (filter.startsWith('Max:')) {
        maxPrice = double.tryParse(
            filter.replaceAll('Max: ₦', '').replaceAll(',', ''));
      }
    }

    ref.read(getMarketplaceServiceProvider.notifier).applyFilters(
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.filter_list,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
            onPressed: () async {
              final filters = await Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                  const FilterScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0, 1);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );

              if (filters != null && filters.isNotEmpty && mounted) {
                setState(() {
                  _selectedFilters = filters;
                  _showFilters = false;
                  _applyServerFilters();
                });
              }
            },
          ),
          Text(
            'Filter',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(List<MarketOrder> services, ThemeData theme,
      bool isDark, WidgetRef ref) {
    final servicesNotifier = ref.read(getMarketplaceServiceProvider.notifier);
    final isLastPage = servicesNotifier.isLastPage;
    final isLoadingMore = servicesNotifier.isLoadingMore;

    final pageCount = (services.length / 4).ceil();
    final rowCount = (services.length / 2).ceil();
    final gridHeight = rowCount * 220;

    return SizedBox(
      height: gridHeight.toDouble().clamp(220, 480),
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent * 0.8 &&
              !isLastPage &&
              !isLoadingMore) {
            _loadMoreServices(servicesNotifier);
          }
          return false;
        },
        child: PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: pageCount + (isLastPage ? 0 : 1),
          itemBuilder: (context, pageIndex) {
            if (pageIndex >= pageCount && !isLastPage) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading more services...',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            final startIndex = pageIndex * 4;
            final endIndex = (startIndex + 4).clamp(0, services.length);
            final pageItems = services.sublist(startIndex, endIndex);

            final gridItems = List<Widget>.generate(4, (index) {
              if (index < pageItems.length) {
                return _buildServiceItem(pageItems[index], theme, isDark);
              } else {
                return const SizedBox.shrink();
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

  Future<void> _loadMoreServices(
      GetMyOrdersAssetNotifier servicesNotifier) async {
    await servicesNotifier.getMarketPlaceService(
      loadMore: true,
      pageSize: 20,
    );
  }

  Widget _buildServiceItem(
      MarketOrder item, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MarketplaceDetails(service: item, user: widget.user),
        ),
      ),
      child: _buildServiceCard(
        context,
        title: item.serviceName,
        price: ref.formatUserCurrency(item.convertedRate),
        name: "${item.user?.firstName} ${item.user?.lastName}",
        rating: 4.5,
        clients: '${item.bookingCount} clients',
        location: item.status,
        isRemote: item.status.toLowerCase().contains('remote'),
        image: item.coverImage,
        theme: theme,
        isDark: isDark,
      ),
    );
  }

  Widget _buildMoreServicesList(
      List<MarketOrder> services, ThemeData theme, bool isDark) {
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
                builder: (context) =>
                    MarketplaceDetails(service: item, user: widget.user),
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
              theme: theme,
              isDark: isDark,
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
        required ThemeData theme,
        required bool isDark,
        bool isRemote = false,
      }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(left: 16.0, right: 8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.BUTTONCOLOR.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: CachedNetworkImageProvider(image),
                fit: BoxFit.cover,
              ),
            ),
            child: isRemote
                ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios,
                        color: theme.colorScheme.onPrimary, size: 16),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        color: theme.colorScheme.onPrimary, size: 16),
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
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    color: AppColors.BUTTONCOLOR,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12),
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
                        Icon(Icons.group,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            size: 14),
                        Text(
                          clients,
                          style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 8),
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
                        style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 8),
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
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                          Text(
                            'Filter by',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: theme.colorScheme.onSurface),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Category Section
                      Text(
                        'Choose a Category',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
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
                              theme: theme,
                            );
                          }).toList(),
                        ),
                        loading: () => Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: List.generate(6, (index) => Shimmer.fromColors(
                            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
                            child: Container(
                              width: 80,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[700] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          )),
                        ),
                        error: (e, _) => Text(
                          'Error loading categories',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Budget Section
                      Text(
                        'Enter your Budget',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
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
                          Text(
                            '-',
                            style: TextStyle(color: theme.colorScheme.onSurface),
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
  final ThemeData theme;

  const FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return RawChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      backgroundColor: selected
          ? kPurpleAccent
          : isDark
          ? const Color(0xFF1A191E)
          : Colors.grey[200],
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
  State<CreativesSection> createState() => _CreativesSectionState();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final creators = widget.creators;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Highly rated creatives',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
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
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  backgroundColor: theme.cardColor,
                ),
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (creators.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                "No creatives found",
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
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
                    rating: Utils.getOverallRating(creator),
                    profileImage: creator.user?.image ?? '',
                    firstName: creator.user?.firstName ?? '',
                    theme: theme,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

