import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/model/market_orders_service_model.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/extension.dart';
import '../../../components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveInvestmentProvider.dart';
import '../../../model/active_investment_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/utils.dart';
import '../../non_creator/marketplace/mark_as_completed.dart';

class MarketplaceReceiptScreen extends ConsumerStatefulWidget {
  final MarketOrder service;
  final String paymentMethod;
  final String price;
  final List<DateTime> availability;
  final User user;
  const MarketplaceReceiptScreen({
    super.key,
    required this.service,
    required this.price,
    required this.availability,
    required this.user,
    required this.paymentMethod,
  });

  @override
  ConsumerState<MarketplaceReceiptScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends ConsumerState<MarketplaceReceiptScreen> {
  ActiveInvestment? _findActiveInvestment() {
    final investmentsState = ref.watch(getActiveInvestmentProvider);

    return investmentsState.maybeWhen(
      data: (investments) {
        // Find the active investment that matches this service
        return investments.data.data.firstWhereOrNull(
              (investment) => investment.serviceId == widget.service.id.toString(),
          orElse: () => null,
        );
      },
      orElse: () => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final activeInvestment = _findActiveInvestment();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Text(
                    'Booking Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A191E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Utils.confirmRow('Service', service.serviceName),
                  const SizedBox(height: 20),
                  Utils.confirmRow('Price', ref.formatUserCurrency(widget.price)),
                  const SizedBox(height: 20),
                  Utils.confirmRow('Payment Method', widget.paymentMethod),
                  const SizedBox(height: 20),
                  Utils.confirmRow(
                    'Start Date',
                    widget.availability.isNotEmpty
                        ? widget.availability
                        .map((date) => DateFormat('dd MMM yyyy').format(date))
                        .join(', ')
                        : 'No dates selected',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 330),
            RoundedButton(
              title: 'Continue',
              color: AppColors.PRIMARYCOLOR,
              borderWidth: 0,
              borderRadius: 25.0,
              onPressed: activeInvestment != null
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkAsCompletedScreen(
                      services: activeInvestment, // Pass the ActiveInvestment
                      user: widget.user,
                    ),
                  ),
                );
              }
                  : null, // Disable button if no active investment found
            )
          ],
        ),
      ),
    );
  }
}
