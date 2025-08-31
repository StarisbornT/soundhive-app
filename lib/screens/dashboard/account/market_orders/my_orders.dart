import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/model/asset_market_response.dart';
import 'package:soundhive2/utils/utils.dart';

import 'package:soundhive2/lib/dashboard_provider/getMarketPlaceProvider.dart';
import '../../../../lib/dashboard_provider/getMyOrdersAssetProvider.dart';
import '../../../../lib/dashboard_provider/getMarketPlaceService.dart';
import '../../../../model/asset_model.dart';
import '../../../../model/market_orders_asset_purchase.dart';
import '../../../../model/market_orders_service_model.dart';
import '../../../../model/user_model.dart';
import '../../marketplace/asset_success.dart';
import '../../marketplace/markplace_recept.dart';
import '../../../non_creator/marketplace/mark_as_completed.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  final User user;

  MyOrdersScreen({required this.user});

  @override
  _MarketplaceState createState() => _MarketplaceState();
}

class _MarketplaceState extends ConsumerState<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  @override
Widget build(BuildContext context) {
    return Scaffold();
  }

  // final TextEditingController _searchController = TextEditingController();
  // late TabController _tabController;
  // bool _servicesInitialized = false;
  // @override
  // void initState() {
  //   super.initState();
  //   _tabController = TabController(length: 2, vsync: this);
  //   _tabController.addListener(_handleTabChange);
  //   _searchController.addListener(() {
  //     setState(() {});
  //   });
  //   ref.read(getMyOrdersAssetProvider.notifier).getMyOrdersAssets();
  // }
  //
  // void _handleTabChange() {
  //   if (_tabController.index == 1 && !_servicesInitialized) {
  //     // Services tab selected and not yet initialized
  //     ref.read(getMyOrdersServiceProvider.notifier).getMyOrders();
  //     _servicesInitialized = true;
  //   }
  // }
  //
  // @override
  // void dispose() {
  //   _tabController.removeListener(_handleTabChange);
  //   _tabController.dispose();
  //   _searchController.dispose();
  //   super.dispose();
  // }
  //
  // @override
  // Widget build(BuildContext context) {
  //   final tokenAsync = ref.watch(authTokenProvider);
  //   return tokenAsync.when(
  //     loading: () => const Center(child: CircularProgressIndicator()),
  //     error: (error, stack) => Center(child: Text('Error: $error')),
  //     data: (token) {
  //       // Now use the token in your screen
  //       print("Loaded token: ${token ?? 'No token found'}");
  //       final assetState = ref.watch(getMyOrdersAssetProvider);
  //       // final serviceState = ref.watch(getMyOrdersServiceProvider);
  //       return Scaffold(
  //         backgroundColor: const Color(0xFF0C051F),
  //         appBar: AppBar(
  //           backgroundColor: const Color(0xFF0C051F),
  //           elevation: 0,
  //           leading: IconButton(
  //             icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
  //             onPressed: () => Navigator.pop(context),
  //           ),
  //         ),
  //         body: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 "My Orders",
  //                 style: TextStyle(
  //                     fontSize: 24,
  //                     fontWeight: FontWeight.w400,
  //                     color: Colors.white),
  //               ),
  //               const SizedBox(height: 10),
  //               Expanded(
  //                 child: Stack(children: [
  //                   Column(
  //                     children: [
  //                       TabBar(
  //                         controller: _tabController,
  //                         labelColor: Colors.white,
  //                         unselectedLabelColor: Colors.grey,
  //                         indicatorColor: Colors.white,
  //                         tabs: const [
  //                           Tab(text: "Assets"),
  //                           Tab(text: "Services"),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 15),
  //                       const SizedBox(height: 10),
  //                       Expanded(
  //                         child: TabBarView(
  //                           controller: _tabController,
  //                           children: [
  //                             _buildGridView(assetState),
  //                             _buildServicesGrid(serviceState),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ]),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  //
  // Widget _buildGridView(AsyncValue<MarketOrdersAssetPurchaseModel> serviceState) {
  //   return serviceState.when(
  //     data: (serviceResponse) {
  //       final allServices = serviceResponse.data ?? [];
  //       if (allServices.isEmpty) {
  //         return _buildEmptyState(context, "Assets");
  //       }
  //       final filteredServices = allServices
  //           .where((service) => service.asset.assetName
  //               .toLowerCase()
  //               .contains(_searchController.text.toLowerCase()))
  //           .toList();
  //
  //       return ListView.builder(
  //         padding: const EdgeInsets.all(10),
  //         itemCount: filteredServices.length,
  //         itemBuilder: (context, index) {
  //           return Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 5),
  //             child: _buildMarketItem(filteredServices[index]),
  //           );
  //         },
  //       );
  //     },
  //     loading: () => const Center(child: CircularProgressIndicator()),
  //     error: (error, _) => Center(child: Text('Error: $error')),
  //   );
  // }
  //
  // Widget _buildServicesGrid(AsyncValue<MarketOrdersServiceModel> serviceState) {
  //   return serviceState.when(
  //     data: (serviceResponse) {
  //       final allServices = serviceResponse.data ?? [];
  //       if (allServices.isEmpty) return _buildEmptyState(context, "Services");
  //
  //       final filteredServices = allServices
  //           .where((service) => service.service.serviceType
  //               .toLowerCase()
  //               .contains(_searchController.text.toLowerCase()))
  //           .toList();
  //
  //       return ListView.builder(
  //         padding: const EdgeInsets.all(10),
  //         itemCount: filteredServices.length,
  //         itemBuilder: (context, index) {
  //           return Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 5),
  //             child: _buildServiceItem(filteredServices[index]),
  //           );
  //         },
  //       );
  //
  //     },
  //     loading: () => const Center(child: CircularProgressIndicator()),
  //     error: (error, _) => Center(child: Text('Error: $error')),
  //   );
  // }
  //
  // Widget _buildServiceItem(MarketOrder service) {
  //   return GestureDetector(
  //     onTap: () {
  //       service.purchaseApprovalAt == null ?
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => MarkAsCompletedScreen(
  //             services: service,
  //             user: widget.user,
  //           ),
  //         ),
  //       )
  //           :
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => MarketplaceReceiptScreen(
  //              serviceId: service.hiveServicePurchasesId,
  //           ),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       padding: EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: Color(0xFF1A102F),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Row(
  //         children: [
  //           // Image section with proper error handling
  //           Container(
  //             width: 100, // Fixed width for image container
  //             height: 100,
  //             child: (service.service.imageUrl?.isNotEmpty ?? false)
  //                 ? Image.network(
  //               service.service.imageUrl!,
  //               fit: BoxFit.cover,
  //               errorBuilder: (context, error, stackTrace) =>
  //                   _buildImagePlaceholder(),
  //             )
  //                 : _buildImagePlaceholder(),
  //           ),
  //           SizedBox(width: 10),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   service.service.serviceType,
  //                   style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold),
  //                   maxLines: 2,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //                 SizedBox(height: 5),
  //                 Text(
  //                   'Initiated at ${DateFormat('dd/MM/yyyy').format(DateTime.parse(service.createdAt))}',
  //                   style: TextStyle(color: Colors.white70, fontSize: 12),
  //                 ),
  //                 SizedBox(height: 5),
  //                 Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                 decoration: BoxDecoration(
  //                 color: service.purchaseApprovalAt == null ? Colors.yellow.withOpacity(0.2)
  //                     : Colors.green.withOpacity(0.2),
  //                 borderRadius: BorderRadius.circular(4),
  //                 ),
  //                 child: Text(
  //                 service.purchaseApprovalAt == null ? 'Ongoing' : 'Completed',
  //                 style: TextStyle(
  //                 color:  service.purchaseApprovalAt == null ? Colors.yellow
  //                     : Colors.green,
  //                 fontSize: 12
  //                 ),
  //                 ),
  //                 ),
  //
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget _buildEmptyState(BuildContext context, String itemName) {
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Center(
  //         child: Text(
  //           'No $itemName',
  //           style: TextStyle(
  //               fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildMarketItem(MarketOrderAsset asset) {
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => OrderSuccessScreen(
  //             asset: asset.asset,
  //           ),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       padding: EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: Color(0xFF1A102F),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Row(
  //         children: [
  //           // Image section with proper error handling
  //           Container(
  //             width: 100, // Fixed width for image container
  //             height: 100,
  //             child: (asset.asset.imageUrl?.isNotEmpty ?? false)
  //                 ? Image.network(
  //                     asset.asset.imageUrl!,
  //                     fit: BoxFit.cover,
  //                     errorBuilder: (context, error, stackTrace) =>
  //                         _buildImagePlaceholder(),
  //                   )
  //                 : _buildImagePlaceholder(),
  //           ),
  //           SizedBox(width: 10),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   asset.asset.assetName,
  //                   style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold),
  //                   maxLines: 2,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //                 SizedBox(height: 5),
  //                 Text(
  //                   'Order #${asset.id}',
  //                   style: TextStyle(color: Colors.white70, fontSize: 14),
  //                 ),
  //                 SizedBox(height: 5),
  //                 Text(
  //                   'Purchased At ${DateFormat('dd/MM/yyyy').format(DateTime.parse(asset.createdAt))}',
  //                   style: TextStyle(color: Colors.white70, fontSize: 12),
  //                 ),
  //                 SizedBox(height: 5),
  //                 // Container(
  //                 // padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                 // decoration: BoxDecoration(
  //                 // color: investment.status == 'AVAILABLE'
  //                 // ? Colors.green.withOpacity(0.2)
  //                 //     : Colors.red.withOpacity(0.2),
  //                 // borderRadius: BorderRadius.circular(4),
  //                 // ),
  //                 // child: Text(
  //                 // investment.status,
  //                 // style: TextStyle(
  //                 // color: investment.status == 'AVAILABLE'
  //                 // ? Colors.green
  //                 //     : Colors.red,
  //                 // fontSize: 12
  //                 // ),
  //                 // ),
  //                 // ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget _buildRatingInfo() {
  //   return const Row(
  //     children: [
  //       Icon(Icons.star, color: Colors.yellow, size: 10),
  //       SizedBox(width: 4),
  //       Text(
  //         "4.5 rating",
  //         style: TextStyle(
  //           color: Colors.grey,
  //           fontSize: 8,
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildDownloadInfo(String purchaseCount) {
  //   return Row(
  //     children: [
  //       Icon(Icons.download, color: Colors.grey, size: 10),
  //       SizedBox(width: 4),
  //       Text(
  //         "${purchaseCount}k downloads",
  //         style: TextStyle(
  //           color: Colors.grey,
  //           fontSize: 8,
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildImagePlaceholder() {
  //   return Container(
  //     height: 150,
  //     color: Colors.grey[800],
  //     child: Icon(Icons.broken_image, color: Colors.white54),
  //   );
  // }
}
