import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/creator_bookings_model.dart';
import '../../utils/review_type.dart';
import '../../utils/utils.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';

import '../non_creator/marketplace/mark_as_completed.dart';

class CreatorBookingsDetailScreen extends ConsumerStatefulWidget {
  final Booking service;
  const CreatorBookingsDetailScreen({super.key, required this.service});

  @override
  ConsumerState<CreatorBookingsDetailScreen> createState() => _CreatorBookingsDetailScreenState();
}

class _CreatorBookingsDetailScreenState extends ConsumerState<CreatorBookingsDetailScreen> {
  bool _loadingReviewStatus = true;
  bool _canReview = false;
  bool _hasReviewed = false;

  bool get _isCompleted => widget.service.status == "SUCCESSFUL";

  @override
  void initState() {
    super.initState();
    if (_isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReviewStatus());
    } else {
      _loadingReviewStatus = false;
    }
  }
  Future<void> _fetchReviewStatus() async {
    try {
      final response = await ref.read(apiresponseProvider.notifier).canReview(
        bookingId: widget.service.id,
        context: context,
      );

      if (!mounted) return;

      setState(() {
        _canReview = response.canReview;
        _hasReviewed = response.hasReviewed;
        _loadingReviewStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReviewStatus = false);
    }
  }

  void _openReviewSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return ReviewBottomSheetContent(
          bookingId: widget.service.id,
          reviewType: ReviewType.generalUser, // creator reviewing the client
          submitInvestment: () {
            if (mounted) setState(() => _hasReviewed = true);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Row(
              children: [
                Text(
                  widget.service.service!.serviceName,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 10),
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
            ),
            if (_isCompleted) ...[
              const SizedBox(height: 20),
              _buildReviewAction(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewAction() {
    if (_loadingReviewStatus) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }

    if (_hasReviewed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A191E),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Text(
          "You've reviewed this client",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
    }

    if (!_canReview) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _openReviewSheet,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: const Text("Leave a review for this client", style: TextStyle(fontSize: 15)),
      ),
    );
  }
}