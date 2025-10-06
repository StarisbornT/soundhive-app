import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/screens/creator/services/edit_service.dart';
import 'package:soundhive2/screens/creator/services/services.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../../components/audio_player.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/getCreatorServiceStatisticsProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/serviceProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/service_model.dart';
import '../../../utils/alert_helper.dart';

class ServiceDetailsScreen extends ConsumerStatefulWidget {
  final ServiceItem services;
  final String earnings;
  const ServiceDetailsScreen({super.key, required this.services, required this.earnings});

  @override
  ConsumerState<ServiceDetailsScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceDetailsScreen> {

  void deleteService(item) async {

    try {
      final response =  await ref.read(apiresponseProvider.notifier).deleteService(
        context: context,
        serviceId: item.id,
      );

      if (response.status) {
        // Refresh before leaving
        await ref.read(getCreatorServiceStatistics.notifier).getStats();
        ref.invalidate(serviceProvider('published'));
        ref.invalidate(serviceProvider('pending'));
        ref.invalidate(serviceProvider('rejected'));
        final user = await ref.read(userProvider.notifier).loadUserProfile();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Your service is deleted successfully',
              subtitle: 'Your service is deleted successfully',
              onButtonPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ServiceScreen(user: user!)),
                );
              },
            ),
          ),
        );
      }

    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      print("Error: $errorMessage");

      if(mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // About, Portfolio, Reviews
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Top Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.services.coverImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // Title Row with Edit/Delete
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.services.serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Row(
                    children: [
                      if (widget.services.status != 'PENDING' && widget.services.status != 'REJECTED')
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditServiceScreen(
                                  service: widget.services,
                                ),
                              ),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          ConfirmBottomSheet.show(
                            context: context,
                            message: "Are you sure you want to delete this service?",
                            confirmText: "Delete",
                            cancelText: "Cancel",
                            confirmColor: const Color(0xFFFE6163),
                            onConfirm: () {
                              deleteService(widget.services);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem( ref.formatCreatorCurrency(
                    (widget.earnings).toString(),
                  ), "Earnings"),
                  _statItem("100", "Customers"),
                  _statItem("15", "Reviews"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // TabBar
            const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "About"),
                Tab(text: "Portfolio"),
                Tab(text: "Reviews"),
              ],
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  _aboutTab(),
                  _portfolioTab(),
                  _reviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for Stats
  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  // About Tab
  Widget _aboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A191E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Utils.confirmRow('Status', widget.services.status),
            Utils.confirmRow('Price', Utils.formatCurrency(widget.services.rate)),
            Utils.confirmRow('Date Submitted',
                DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.services.createdAt))),
          ],
        ),
      ),
    );
  }

  // Portfolio Tab
  Widget _portfolioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Example portfolio images
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(widget.services.serviceImage, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          // Example link
          if(widget.services.link != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A191E),
              borderRadius: BorderRadius.circular(10),
            ),
            child:  Row(
              children: [
                Expanded(
                  child: Text(
                    widget.services.link ?? '',
                    style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                  ),
                ),
                const Icon(Icons.open_in_new, color: Colors.white70),
              ],
            ),
          ),

          const SizedBox(height: 16),
          if(widget.services.serviceAudio != null) ...[
            AudioPlayerWidget(audioUrl: widget.services.serviceAudio ?? ""),
          ],
        ],
      ),
    );
  }
  Widget _reviewsTab() {
    return const Center(
      child: Text("Reviews go here", style: TextStyle(color: Colors.white70)),
    );
  }
}
