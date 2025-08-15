

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/lib/dashboard_provider/assetsProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/getBreakDownProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/serviceProvider.dart';
import 'package:soundhive2/model/asset_model.dart';
import 'package:soundhive2/screens/dashboard/account/catalogue/asset/asset.dart';
import 'package:soundhive2/screens/dashboard/account/catalogue/services/add_service.dart';
import 'package:soundhive2/screens/dashboard/account/catalogue/services/service.dart';
import '../../../../model/service_model.dart';
import '../../../../utils/utils.dart';
import 'asset/add_assets.dart';
class CatalogueScreen extends ConsumerStatefulWidget {

  @override
  _CatalogoueScreenState createState() => _CatalogoueScreenState();
}

class _CatalogoueScreenState extends ConsumerState<CatalogueScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    // _searchController.addListener(() {
    //   setState(() {});
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assetsProvider.notifier).getAssets('');
      // ref.read(serviceProvider.notifier).getService();
      ref.read(getBreakDownProvider.notifier).getBreakDown();
    });
  }
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {}); // Trigger rebuild
    }
  }


  @override
  Widget build(BuildContext context) {
    final assetState = ref.watch(assetsProvider);
    // final serviceState = ref.watch(serviceProvider);
    final breakDownState = ref.watch(getBreakDownProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C051F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B041C), Color(0xFF140B2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: assetState.when(
              data: (assetResponse) {
                // return serviceState.when(
                //   data: (serviceResponse) {
                //     final allAssets = assetResponse.data;
                //     final allServices = serviceResponse.data;
                //
                //     if (allAssets.isEmpty && allServices.isEmpty) {
                //       return buildEmptyCatalogueUI(context);
                //     }
                //
                //     // return buildCatalogueUI(
                //     //     context,
                //     //     allAssets,
                //     //     allServices
                //     // );
                //   },
                //   loading: () => const Center(child: CircularProgressIndicator()),
                //   error: (error, _) => Center(child: Text('Error: $error')),
                // );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ),
      ),
    );
  }

  // Widget buildCatalogueUI(BuildContext context,
  //     List<Asset> assets,
  //     List<Services> service) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Catalogue',
  //         style: TextStyle(
  //           fontSize: 24,
  //           fontWeight: FontWeight.w600,
  //           color: Colors.white,
  //         ),
  //       ),
  //       const SizedBox(height: 20),
  //       const Divider(color: Colors.white24),
  //       const SizedBox(height: 20),
  //
  //       // Earnings Row
  //       ref.watch(getBreakDownProvider).maybeWhen(
  //         data: (breakDown) {
  //           final assetAmount = breakDown.data.hiveAssetPurchaseCount;
  //           final serviceAmount = breakDown.data.hiveServicePurchaseAmount;
  //           final totalAmount = assetAmount + serviceAmount;
  //
  //           return Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               EarningsCard(amount: Utils.formatCurrency(totalAmount), label: 'Total Earnings'),
  //               EarningsCard(amount: Utils.formatCurrency(assetAmount), label: 'Asset Earnings'),
  //               EarningsCard(amount: Utils.formatCurrency(serviceAmount), label: 'Service Earnings'),
  //             ],
  //           );
  //         },
  //         orElse: () => Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: const [
  //             EarningsCard(amount: '₦0', label: 'Total Earnings'),
  //             EarningsCard(amount: '₦0', label: 'Asset Earnings'),
  //             EarningsCard(amount: '₦0', label: 'Service Earnings'),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 30),
  //
  //       // Assets Button
  //       CatalogueButton(
  //         icon: Icons.folder_copy_outlined,
  //         label: 'Assets (${assets.length})',
  //         onTap: () {
  //           Navigator.push(context, MaterialPageRoute(
  //               builder: (_) => AssetCatalogueScreen(assets: assets,)
  //           ));
  //         },
  //       ),
  //       const SizedBox(height: 16),
  //
  //       // Services Button
  //       CatalogueButton(
  //         icon: Icons.work_outline,
  //         label: 'Services (${service.length})',
  //         onTap: () {
  //           Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceCatalogueScreen(services: service)));
  //         },
  //       ),
  //       const SizedBox(height: 16),
  //
  //       // Clients Button with Notification
  //       Stack(
  //         children: [
  //           CatalogueButton(
  //             icon: Icons.person_outline,
  //             label: 'Clients (19)',
  //             onTap: () {
  //               // Navigate to Clients
  //             },
  //           ),
  //           Positioned(
  //             right: 20,
  //             top: 12,
  //             child: CircleAvatar(
  //               radius: 10,
  //               backgroundColor: Colors.redAccent,
  //               child: Text(
  //                 '2',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 100), // For floating button spacing
  //     ],
  //   );
  // }


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
                  'Catalogue',
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
            'images/catelogue.png',
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'No items in your catalogue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'You have not added any asset or service\nto your catalogue yet.',
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
                addToCatalogue(context);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add to catalogue',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        )
      ],
    );
  }

  
  void addToCatalogue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'What do you want to add to your catalogue?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
              ),
              const SizedBox(height: 8),
              buildEarningsCard(
                'Assets',
                'This could be a sound track, loop, sound effect, e-book, beats, music licensing etc.',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddAssets()));
                },
              ),
              const SizedBox(height: 10),
              buildEarningsCard(
                'Services',
                'This involves services you render and want to be hired for such as DJ bookings, event management, music production, song writing, Tech related services etc.',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddService()));
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget buildEarningsCard(String title, String data, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300)),
      subtitle: Text(data, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      onTap: onTap,
    );
  }
}

class EarningsCard extends StatelessWidget {
  final String amount;
  final String label;

  const EarningsCard({required this.amount, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFBBA9FF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
class CatalogueButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const CatalogueButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

