
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/creator_bookings_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/utils.dart';

class CreatorBookingsDetailScreen extends ConsumerStatefulWidget {
  final Booking service;
  const CreatorBookingsDetailScreen({super.key, required this.service});

  @override
  _CreatorBookingsDetailScreenState createState() => _CreatorBookingsDetailScreenState();
}
class _CreatorBookingsDetailScreenState extends ConsumerState<CreatorBookingsDetailScreen>  {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
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
        child:  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.service.service!.serviceName,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.service.status == "PENDING"
                        ? const Color.fromRGBO(255, 193, 7, 0.1)
                        : const Color.fromRGBO(76, 175, 80, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.service.status == "PENDING" ? 'Ongoing' : 'Completed',
                    style: TextStyle(
                      color: widget.service.status == "PENDING"
                          ? const Color(0xFFFFC107)
                          : const Color(0xFF4CAF50),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10,),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A191E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Utils.confirmRow('Client', "${widget.service.user?.firstName} ${widget.service.user?.lastName}"),
                  Utils.confirmRow('Price', Utils.formatCurrency(widget.service.service?.rate)),
                  Utils.confirmRow('Service Request', widget.service.service?.serviceName),
                  Utils.confirmRow('Date Booked', widget.service.date),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}