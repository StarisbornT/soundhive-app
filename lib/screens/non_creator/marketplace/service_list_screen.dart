import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soundhive2/lib/dashboard_provider/getMarketPlaceService.dart';
import 'package:soundhive2/model/user_model.dart';
import 'package:soundhive2/utils/app_colors.dart';

import '../../../main.dart';
import 'marketplace_details.dart';

class ServicesListScreen extends ConsumerStatefulWidget {
  final int id;
  final int? subCategoryId; // Add subcategory ID
  final String? categoryName;
  final MemberCreatorResponse user;

  const ServicesListScreen({
    super.key,
    required this.id,
    this.subCategoryId,
    this.categoryName,
    required this.user
  });
  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen>
    with SingleTickerProviderStateMixin,  RouteAware {
  late TabController _tabController;
  late RouteObserver<ModalRoute> _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeObserver = ref.read(routeObserverProvider);
      _routeObserver.subscribe(this, ModalRoute.of(context)!);
      ref.read(getMarketplaceServiceProvider.notifier)
          .getMarketPlaceService(
        categoryId: widget.id,
        subCategoryId: widget.subCategoryId, // Pass subcategory ID
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceNotifier = ref.read(getMarketplaceServiceProvider.notifier);
    final marketplaceState = ref.watch(getMarketplaceServiceProvider);
    final services = marketplaceNotifier.allServices;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              // Reset the marketplace state before going back
              ref.read(getMarketplaceServiceProvider.notifier)
                  .resetMarketplaceState(); // Clear the category filter
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.categoryName ?? 'Services',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Search Box
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    marketplaceNotifier.getMarketPlaceService(
                      serviceName: value,
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              // Service Grid
              Expanded(
                child: marketplaceState.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text("Error: $e",
                        style: const TextStyle(color: Colors.white)),
                  ),
                  data: (_) {
                    if (services.isEmpty) {
                      return const Center(
                        child: Text("No services found",
                            style: TextStyle(color: Colors.white)),
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            notification.metrics.pixels ==
                                notification.metrics.maxScrollExtent) {
                          marketplaceNotifier.getMarketPlaceService(
                            loadMore: true,
                            categoryId: widget.id,
                          );
                        }
                        return false;
                      },
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final item = services[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MarketplaceDetails(
                                    service: item,
                                    user: widget.user,
                                  ),
                                ),
                              );
                            },
                            child: _buildServiceCard(
                              context,
                              title: item.serviceName,
                              price: '₦${item.rate}',
                              name:
                              "${item.user?.firstName} ${item.user?.lastName}",
                              rating: 4.5,
                              clients: '20k clients',
                              location: item.status,
                              isRemote: item.status
                                  .toLowerCase()
                                  .contains('remote'),
                              image: item.coverImage,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
        color: const Color(0xFF1A191E), // Card background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF6A0DAD), // Placeholder for image
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              // You can replace this with an actual image asset
              image: DecorationImage(
                image:  NetworkImage(image) , // Placeholder for beat production image
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style:  const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto'
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
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
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.group, color: Colors.white70, size: 14),
                        Text(
                          clients,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                        ),
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
