import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/model/market_orders_service_model.dart';
import '../../../components/rounded_button.dart';
import '../../../model/user_model.dart';
import '../../../utils/utils.dart';
import '../../non_creator/marketplace/mark_as_completed.dart';

class MarketplaceReceiptScreen extends ConsumerStatefulWidget {
  final MarketOrder service;
  final String paymentMethod;
  final List<DateTime> availability;
  final User user;
  final String? memberServiceId;
  const MarketplaceReceiptScreen(
      {super.key,
      required this.service,
      required this.availability,
        required this.user,
        this.memberServiceId,
      required this.paymentMethod});

  @override
  ConsumerState<MarketplaceReceiptScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends ConsumerState<MarketplaceReceiptScreen> {
  Widget build(BuildContext context) {
    final service = widget.service;
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              const SizedBox(
                height: 40,
              ),
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
                    const SizedBox(
                      height: 20,
                    ),
                    Utils.confirmRow(
                        'Price', Utils.formatCurrency(service.serviceAmount)),
                    const SizedBox(
                      height: 20,
                    ),
                    Utils.confirmRow('Payment Method', widget.paymentMethod),
                    const SizedBox(
                      height: 20,
                    ),
                    Utils.confirmRow(
                      'Start Date',
                      widget.availability.isNotEmpty
                          ? widget.availability
                              .map((date) =>
                                  DateFormat('dd MMM yyyy').format(date))
                              .join(', ')
                          : 'No dates selected',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 330,),
              RoundedButton(
                  title: 'Continue',
                  color: const Color(0xFF4D3490),
                  borderWidth: 0,
                  borderRadius: 25.0,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarkAsCompletedScreen(
                            services: widget.service,
                          user: widget.user,
                          memberServiceId: widget.memberServiceId,
                        ),
                      ),
                    );
                  }
              )
            ])));
  }
}
