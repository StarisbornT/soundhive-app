import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/lib/dashboard_provider/assetsProvider.dart';
import 'package:soundhive2/model/asset_model.dart';
import 'package:soundhive2/screens/dashboard/account/catalogue/asset/view_assets.dart';
import 'package:soundhive2/screens/dashboard/account/catalogue/services/add_service.dart';
import 'package:soundhive2/screens/creator/services/service_details_screen.dart';
import '../../../../../model/service_model.dart';
import '../../../../../utils/utils.dart';

class ServiceCatalogueScreen extends ConsumerStatefulWidget {
  final List<dynamic> services;
  const ServiceCatalogueScreen({Key? key, required this.services}) : super(key: key);
  @override
  _ServiceCatalogoueScreenState createState() => _ServiceCatalogoueScreenState();
}

class _ServiceCatalogoueScreenState extends ConsumerState<ServiceCatalogueScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    // _searchController.addListener(() {
    //   setState(() {});
    // });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {}); // Trigger rebuild
    }
  }


  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    return Scaffold(
      backgroundColor: const Color(0xFF0C051F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C051F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: services.isEmpty
                  ? buildEmptyCatalogueUI(context)
                  : null
          )
      ),
      floatingActionButton: services.isNotEmpty
          ? SizedBox(
        width: 70,
        height: 70,
        child: RawMaterialButton(
          onPressed: () {
            print('clicking');
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddService()));
          },
          fillColor: const Color(0xFF8C52FF),
          shape: const CircleBorder(),
          elevation: 6,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 36,
          ),
        ),
      )
          : null,
    );
  }
  Widget buildEmptyCatalogueUI(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Catalogue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Opacity(
          opacity: 0.7,
          child: Image.asset(
            'images/service.png',
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'No asset Added',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'You have not added any service \nto your catalogue yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddService()));
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add an service to catalogue',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        )
      ],
    );
  }
  // Widget buildTabViewUI(BuildContext context, List <Services> services) {
  //   return Column(
  //     children: [
  //       // Header
  //       Container(
  //         alignment: Alignment.topLeft,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 'Service Catalogue',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 24,
  //                   fontWeight: FontWeight.w400,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //
  //       TabBar(
  //         controller: _tabController,
  //         labelColor: Colors.white,
  //         unselectedLabelColor: Colors.white60,
  //         tabs: const [
  //           Tab(text: 'Published'),
  //           Tab(text: 'Under Review'),
  //           Tab(text: 'Rejected'),
  //         ],
  //       ),
  //
  //       // Expanded(
  //       //   child: _tabController.index == 0
  //       //       ? buildAssetList(
  //       //       services.where((asset) => asset.status == 'PUBLISHED').toList(),
  //       //       'No published assets')
  //       //       : _tabController.index == 1
  //       //       ? buildAssetList(
  //       //       services.where((asset) => asset.status == 'UNDER_REVIEW').toList(),
  //       //       'No assets under review')
  //       //       : buildAssetList(
  //       //       services.where((asset) => asset.status == 'REJECTED').toList(),
  //       //       'No rejected assets'),
  //       // )
  //
  //     ],
  //   );
  // }
  // Widget buildAssetList(List<Services> items, String emptyMessage) {
  //   if (items.isEmpty) {
  //     return Center(
  //       child: Text(
  //         emptyMessage,
  //         style: const TextStyle(color: Colors.white70),
  //       ),
  //     );
  //   }
  //   return ListView.builder(
  //     itemCount: items.length,
  //     itemBuilder: (context, index) {
  //       final item = items[index];
  //       return GestureDetector(
  //         onTap: () {
  //           Navigator.push(context,  MaterialPageRoute(
  //             builder: (context) => ServiceDetailsScreen(
  //               services: item,
  //             ),
  //           ),);
  //         },
  //         child: Container(
  //           padding: EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Color(0xFF1A102F),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Row(
  //             children: [
  //               // Image section with proper error handling
  //               Container(
  //                 width: 100, // Fixed width for image container
  //                 height: 100,
  //                 child: (item.imageUrl?.isNotEmpty ?? false)
  //                     ? Image.network(
  //                   item.imageUrl!,
  //                   fit: BoxFit.cover,
  //                   errorBuilder: (context, error, stackTrace) => Utils.buildImagePlaceholder(),
  //                 )
  //                     : Utils.buildImagePlaceholder(),
  //               ),
  //               SizedBox(width: 10),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       item.serviceType,
  //                       style: TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold
  //                       ),
  //                       maxLines: 2,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                     SizedBox(height: 5),
  //                     Text(
  //                       '${Utils.formatCurrency(item.price)}',
  //                       style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
  //                     ),
  //                     SizedBox(height: 5),
  //                     Text(
  //                       '${item.status == "UNDER_REVIEW" ? 'Submitted ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item.createdAt))}' : ''}',
  //                       style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
  //                     ),
  //
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}