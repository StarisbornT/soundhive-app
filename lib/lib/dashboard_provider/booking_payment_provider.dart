import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/booking_payment_model.dart';
import '../provider.dart';

/// Module 2 — advance & milestone payment endpoints.
final bookingPaymentApiProvider = Provider<BookingPaymentApi>((ref) {
  return BookingPaymentApi(ref.watch(dioProvider));
});

/// Payment schedule for one booking. Refresh with
/// `ref.invalidate(bookingPaymentSummaryProvider(bookingId))`.
final bookingPaymentSummaryProvider =
    FutureProvider.autoDispose.family<BookingPaymentSummary, int>((ref, bookingId) {
  return ref.watch(bookingPaymentApiProvider).getSummary(bookingId);
});

/// Thrown with the server's own message so screens can show it as-is.
class BookingPaymentError implements Exception {
  final String message;
  final int? statusCode;
  final bool insufficientFunds;

  BookingPaymentError(this.message, {this.statusCode})
      : insufficientFunds = message.toLowerCase().contains('insufficient');

  @override
  String toString() => message;
}

class BookingPaymentApi {
  final Dio _dio;

  BookingPaymentApi(this._dio);

  Future<PaymentQuote> preview({
    required int serviceId,
    required PaymentPlanRequest plan,
  }) async {
    final data = await _call(() => _dio.post('/service/payment-plan/preview', data: {
          'service_id': serviceId,
          'payment_plan': plan.toJson(),
        }));
    return PaymentQuote.fromMap(Map<String, dynamic>.from(data));
  }

  Future<BookingPaymentSummary> getSummary(int bookingId) async {
    final data = await _call(() => _dio.get('/service/bookings/$bookingId/payments'));
    return BookingPaymentSummary.fromMap(Map<String, dynamic>.from(data));
  }

  Future<BookingPaymentSummary> fundMilestone(int bookingId, int milestoneId) =>
      _summaryCall(() => _dio.post('/service/bookings/$bookingId/milestones/$milestoneId/fund'));

  Future<BookingPaymentSummary> submitMilestone(int bookingId, int milestoneId, {String? note}) =>
      _summaryCall(() => _dio.post(
            '/service/bookings/$bookingId/milestones/$milestoneId/submit',
            data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
          ));

  Future<BookingPaymentSummary> approveMilestone(int bookingId, int milestoneId) =>
      _summaryCall(() => _dio.post('/service/bookings/$bookingId/milestones/$milestoneId/approve'));

  Future<BookingPaymentSummary> cancelBooking(int bookingId, String reason) =>
      _summaryCall(() => _dio.post('/service/bookings/$bookingId/cancel', data: {'reason': reason}));

  /// Creator: opt a service in/out of milestone bookings.
  Future<Map<String, dynamic>> updatePaymentTerms({
    required int serviceId,
    required bool allowsMilestones,
    double? maxAdvancePercent,
    List<PlanStageInput>? template,
  }) async {
    final data = await _call(() => _dio.put('/services/$serviceId/payment-terms', data: {
          'allows_milestones': allowsMilestones,
          if (maxAdvancePercent != null) 'max_advance_percent': maxAdvancePercent,
          if (template != null && template.isNotEmpty)
            'milestone_template': template.map((s) => s.toJson()).toList(),
        }));
    return Map<String, dynamic>.from(data);
  }

  // ── helpers ──────────────────────────────────────────────────────────

  Future<BookingPaymentSummary> _summaryCall(Future<Response> Function() fn) async {
    final data = await _call(fn);
    return BookingPaymentSummary.fromMap(Map<String, dynamic>.from(data));
  }

  Future<dynamic> _call(Future<Response> Function() fn) async {
    try {
      final res = await fn();
      final body = res.data;
      if (body is Map && (body['status'] == true || body['success'] == true)) {
        return body['data'];
      }
      throw BookingPaymentError(
        body is Map ? (body['message']?.toString() ?? 'Something went wrong') : 'Something went wrong',
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map && body['message'] != null
          ? body['message'].toString()
          : (e.message ?? 'Network error. Please try again.');
      throw BookingPaymentError(message, statusCode: e.response?.statusCode);
    }
  }
}
