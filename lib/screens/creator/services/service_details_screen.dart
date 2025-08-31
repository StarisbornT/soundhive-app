

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../../model/service_model.dart';

class ServiceDetailsScreen extends ConsumerStatefulWidget {
  final ServiceItem services;
  const ServiceDetailsScreen({super.key, required this.services});

  @override
  ConsumerState<ServiceDetailsScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceDetailsScreen> {

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(widget.services.coverImage, height: 200, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.services.serviceName,
              style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
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
                  Utils.confirmRow('Status', widget.services.status),
                  // Utils.confirmRow('Work Type', [widget.services.workType, ...widget.services.availableToWork]),
                  Utils.confirmRow('Price', Utils.formatCurrency(widget.services.rate)),
                  Utils.confirmRow('Date Submitted', DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.services.createdAt))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}