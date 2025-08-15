import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/asset_model.dart';

import '../../../lib/dashboard_provider/getMarketPlaceProvider.dart';
import '../../../model/service_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/utils.dart';
import '../../non_creator/marketplace/marketplace_details.dart';
import 'marketplace_service_details.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  final String category;
  final User user;

  const AssetListScreen({
    required this.category,
    required this.user,
  });

  @override
  ConsumerState<AssetListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<AssetListScreen> {
  @override
  void initState() {
    super.initState();
    // Load services when the screen initializes
    Future.microtask(() {
      ref.read(getMarketPlaceProvider.notifier).getMarketPlace('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(getMarketPlaceProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.category, style: TextStyle(color: Colors.white),),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0C051F),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: serviceState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (serviceResponse) {
            final filteredServices = widget.category == 'All'
                ? serviceResponse.data // Show all services when "All" is selected
                : serviceResponse.data
                .where((service) => service.assetType == widget.category)
                .toList();

            if (filteredServices.isEmpty) {
              return _buildEmptyState("assets");
            }

            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.5,
              ),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) => ServiceItemWidget(
                service: filteredServices[index],
                user: widget.user,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String itemName) {
    return Center(
      child: Text(
        'No $itemName available',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class ServiceItemWidget extends StatelessWidget {
  final Asset service;
  final User user;

  const ServiceItemWidget({
    required this.service,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: () => Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => AssetDetailsScreen(
      //       asset: service,
      //       user: user,
      //     ),
      //   ),
      // ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: (service.imageUrl?.isNotEmpty ?? false)
                    ? Image.network(
                  service.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImagePlaceholder(),
                )
                    : _buildImagePlaceholder(),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.assetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Utils.formatCurrency(double.parse(service.price)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundImage: AssetImage('images/avatar.png'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${service.seller!.firstName} ${service.seller!.lastName}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        service.assetType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.image, color: Colors.white54),
    );
  }
}