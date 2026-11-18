import 'package:flutter/material.dart';
import 'package:soundhive2/screens/bookings/booking_payments_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/creator_bookings_model.dart';
import '../../utils/review_type.dart';
import '../../utils/utils.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';

import '../non_creator/marketplace/mark_as_completed.dart';
import '../non_creator/disputes/dispute_chat_screen.dart';
import '../../lib/dashboard_provider/get_current_user_dispute_provider.dart';
import '../../lib/dashboard_provider/user_provider.dart';
import '../../model/dispute_model.dart';
import 'package:dio/dio.dart';

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
  bool get _isActive => widget.service.status == "PENDING";

  // Disputes: creators can raise one too (the client, Cre8Hive support and the creator then talk in the dispute chat).
  DisputeData? _dispute;
  bool _disputeLoading = true;
  bool _raising = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDispute());
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

  Future<void> _loadDispute() async {
    final result = await ref.read(getCurrentUserDisputeProvider.notifier).getDispute(bookingId: widget.service.id);
    if (!mounted) return;
    setState(() {
      _dispute = result?.data;
      _disputeLoading = false;
    });
  }

  String get _clientName => "${widget.service.user?.firstName ?? ''} ${widget.service.user?.lastName ?? ''}".trim();

  void _openDisputeChat() {
    final me = ref.read(userProvider).value?.user;
    if (me == null || _dispute == null) return;
    final myName = "${me.firstName} ${me.lastName}".trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DisputeChatScreen(
          // sellerId is "the other participant" for the chat index: here, the client.
          sellerId: widget.service.userId,
          sellerName: _clientName,
          userId: me.id.toString(),
          senderName: myName,
          disputeId: _dispute!.id.toString(),
          disputeTitle: "Dispute Resolution with $_clientName",
        ),
      ),
    );
  }

  Future<void> _raiseDispute() async {
    final reasonController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F10),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Raise a dispute?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Cre8Hive support will review this booking with you and $_clientName. While the dispute is open, payments on this booking are on hold.',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLength: 255,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'What went wrong? (optional)', hintStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Raise dispute', style: TextStyle(color: Colors.white)),
              ),
            ),
            Center(child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now'))),
          ],
        ),
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _raising = true);
    try {
      final response = await ref.read(apiresponseProvider.notifier).initiateDispute(
        context: context,
        payload: {"booking_id": widget.service.id, if (reason.isNotEmpty) "reason": reason},
      );
      if (!mounted) return;
      if (response.status) {
        await _loadDispute();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute raised. Cre8Hive support will be in touch in the dispute chat.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      String message = 'Could not raise the dispute. Please try again.';
      if (error is DioException && error.response?.data is Map && error.response?.data['message'] is String) {
        message = error.response!.data['message'];
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _raising = false);
    }
  }

  Widget _buildDisputeSection() {
    if (_disputeLoading) return const SizedBox.shrink();
    final open = _dispute != null && _dispute!.status == 'PENDING';

    if (open) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 82, 82, 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dispute open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Payments on this booking are on hold while Cre8Hive support reviews it.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openDisputeChat,
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
              label: const Text('Dispute chat', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isActive) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _raising ? null : _raiseDispute,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(_raising ? 'Raising dispute…' : 'Raise a dispute', style: const TextStyle(color: Colors.redAccent)),
      ),
    );
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
            const SizedBox(height: 16),
            // Module 2 — advance received, escrow and milestones to deliver
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPaymentsScreen(
                      bookingId: widget.service.id,
                      serviceName: widget.service.service?.serviceName,
                    ),
                  ),
                ),
                icon: const Icon(Icons.payments_outlined, color: Colors.white, size: 18),
                label: const Text('Payments & milestones', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildDisputeSection(),
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