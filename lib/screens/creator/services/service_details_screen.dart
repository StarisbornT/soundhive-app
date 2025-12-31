import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundhive2/screens/creator/services/edit_service.dart';
import 'package:soundhive2/screens/creator/services/offer_details.dart';
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
import '../../../model/getOfferFromUserProvider.dart';
import '../../../model/service_model.dart';
import '../../../utils/alert_helper.dart';

class ServiceDetailsScreen extends ConsumerStatefulWidget {
  final ServiceItem services;
  final String earnings;
  const ServiceDetailsScreen({super.key, required this.services, required this.earnings});

  @override
  ConsumerState<ServiceDetailsScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceDetailsScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _bookingsScrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await  ref.read(getOfferFromUserProvider.notifier).getOffers(id: widget.services.id, pageSize: 10);
    });

    _tabController.addListener(() {
      // When Offers tab is selected
      if (_tabController.index == 3) {
        final notifier = ref.read(getOfferFromUserProvider.notifier);
        if (notifier.allServices.isEmpty) {
          notifier.getOffers(id: widget.services.id, pageSize: 10);
        }
      }
    });

    _bookingsScrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _bookingsScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_bookingsScrollController.position.pixels ==
        _bookingsScrollController.position.maxScrollExtent) {
      _loadMoreBookings();
    }
  }

  Future<void> _loadMoreBookings() async {
    final notifier = ref.read(getOfferFromUserProvider.notifier);
    if (!notifier.isLastPage && mounted) {
      await notifier.getOffers(loadMore: true, id: widget.services.id);
    }
  }
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
      length: 4, // About, Portfolio, Reviews
      child: Scaffold(
       
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
                Tab(text: "Offers"),
              ],
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  _aboutTab(),
                  _portfolioTab(),
                  _reviewsTab(),
                  buildMyBookingsUI(),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget buildMyBookingsUI() {
    final offersState = ref.watch(getOfferFromUserProvider);

    return offersState.when(
      loading: () => _buildShimmerBookingsList(),
      error: (e, _) => Center(
        child: Text("Error: $e", style: const TextStyle(color: Colors.white)),
      ),
      data: (offerModel) {
        // Access the offers list correctly from the model
        final offers = offerModel.data.data ?? [];
        final isLastPage = ref.read(getOfferFromUserProvider.notifier).isLastPage;
        final isLoadingMore = ref.read(getOfferFromUserProvider.notifier).isLoadingMore;

        if (offers.isEmpty) {
          return const Center(
            child: Text("No offers found", style: TextStyle(color: Colors.white)),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              controller: _bookingsScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final service = offer.service;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OfferDetailScreen(
                          offer: offer,
                        ),
                      ),
                    );
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
                          service?.coverImage ?? '',
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
                        service?.serviceName ?? "Offer #${offer.id}",
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Amount: ${ref.formatCreatorCurrency(offer.convertedAmount)}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            "Offered on ${DateFormat('dd/MM/yyyy').format(DateTime.parse(offer.createdAt))}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: offer.status == "PENDING"
                                  ? const Color.fromRGBO(255, 193, 7, 0.1)
                                  : offer.status == "ACCEPTED"
                                  ? const Color.fromRGBO(76, 175, 80, 0.1)
                                  : const Color.fromRGBO(244, 67, 54, 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              offer.status,
                              style: TextStyle(
                                color: offer.status == "PENDING"
                                    ? const Color(0xFFFFC107)
                                    : offer.status == "ACCEPTED"
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFF44336),
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
