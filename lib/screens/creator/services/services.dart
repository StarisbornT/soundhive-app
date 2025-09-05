import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/screens/creator/services/add_new_service.dart';
import 'package:soundhive2/screens/creator/services/service_details_screen.dart';
import 'package:soundhive2/utils/app_colors.dart';

import '../../../components/rounded_button.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/serviceProvider.dart';
import '../../../model/service_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/utils.dart';
import '../profile/setup_screen.dart';

class ServiceScreen extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const ServiceScreen({super.key, required this.user});
  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showBlur = widget.user.user?.creator == null || widget.user.user?.creator!.active == false;

    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFB0B0B6)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Earnings from Services',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatColumn(Utils.formatCurrency('100,300'), 'Amount Earned'),
                        _buildStatColumn(Utils.formatCurrency('10,300'), 'Amount in escrows'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                        'Services Summary',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatColumn('14', 'Under review'),
                        _buildStatColumn('15', 'Approved services'),

                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white54, thickness: 1),
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF917FC0),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                tabs: const [
                  Tab(text: 'Published'),
                  Tab(text: 'Under review'),
                  Tab(text: 'Rejected'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final publishedState = ref.watch(serviceProvider('published'));
                        return publishedState.when(
                          data: (serviceResponse) =>
                              buildServiceList(serviceResponse.data.data, "No published services"),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Center(child: Text('Error: $error')),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final pendingState = ref.watch(serviceProvider('pending'));
                        return pendingState.when(
                          data: (serviceResponse) =>
                              buildServiceList(serviceResponse.data.data, "No services under review"),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Center(child: Text('Error: $error')),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final rejectedState = ref.watch(serviceProvider('rejected'));
                        return rejectedState.when(
                          data: (serviceResponse) =>
                              buildServiceList(serviceResponse.data.data, "No rejected services"),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Center(child: Text('Error: $error')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 🔥 Overlay blur (will cover everything including FAB)
          if (showBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          textAlign: TextAlign.center,
                          (widget.user?.user?.creator == null)
                              ? "Complete your KYC so as to activate your Soundhive Vest Account Unlock your ability to Invest in verifiable and quality entertainment projects or artists, as well as share in their success."
                              : "Your account is under review",
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (widget.user?.user?.creator == null)
                        RoundedButton(
                          title: 'Verify my identity',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SetupScreen(user: widget.user),
                              ),
                            );
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
      floatingActionButton: showBlur
          ? SizedBox(
        width: 70,
        height: 70,
        child: RawMaterialButton(
          onPressed: null, // Disabled when blur is shown
          fillColor: const Color(0xFF8C52FF).withOpacity(0.6),
          shape: const CircleBorder(),
          elevation: 3,
          child: const Icon(
            Icons.add,
            color: Colors.white70,
            size: 36,
          ),
        ),
      )
          : SizedBox(
        width: 70,
        height: 70,
        child: RawMaterialButton(
          onPressed: () {
            if (widget.user.user?.creator != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNewServiceScreen()));
            } else {
              showCustomAlert(
                context: context,
                isSuccess: false,
                title: 'Error',
                message: "Please Verify Account before setting up creative profile",
              );
            }
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
      ),
    );
  }

  // Helper widget to build a single statistic column
  Widget _buildStatColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              color: Color(0xFFC5AFFF),
              fontSize: 18,
              fontWeight: FontWeight.w400,
            )
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget buildServiceList(List<ServiceItem> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: (item.coverImage.isNotEmpty)
                    ? Image.network(
                  item.coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Utils.buildImagePlaceholder(),
                )
                    : Utils.buildImagePlaceholder(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceName,
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
                      Utils.formatCurrency(item.rate),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.status == "PENDING" ? 'Submitted ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item.createdAt))}' : '',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),

                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showBottomSheet(item);
                },
                  child: const Icon(Icons.more_vert, color: Colors.white,)
              )
            ],
          ),
        );
      },
    );
  }

  void showBottomSheet(ServiceItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceActionSheet(
        onView: () {
          Navigator.push(context,  MaterialPageRoute(
                          builder: (context) => ServiceDetailsScreen(
                            services: item,
                          ),
                        ),);
        },
        onEdit: item.status.toLowerCase() == 'rejected'
            ? null
            : () {
          // Handle edit
        },
        onDelete: () {
          // Handle delete
        },
      ),
    );
  }


  // Helper widget to build the list of services
  Widget _buildServiceList(List<Map<String, dynamic>> services) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          color: const Color(0xFF2B0050), // Card background color, slightly lighter than primary
          margin: const EdgeInsets.only(bottom: 12.0), // Spacing between cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners for cards
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Service Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners for image
                  child: Image.network(
                    service['image'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback for image loading errors
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[700],
                        child: const Icon(Icons.image, color: Colors.white),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12), // Spacing between image and text
                // Service Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service['price'],
                        style: const TextStyle(
                          color: Colors.purpleAccent, // Price color
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Published ${service['publishedDate']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.person, color: Colors.white70, size: 14), // Person icon
                          Text(
                            '${service['customers']} customers',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // More options icon
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: () {
                    // Handle more options button press
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}