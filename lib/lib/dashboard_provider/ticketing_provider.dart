import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/ticketing_model.dart';
import '../provider.dart';

/// Module 3 — event ticket categories, checkout and orders.
final ticketingApiProvider = Provider<TicketingApi>((ref) => TicketingApi(ref.watch(dioProvider)));

final eventTicketingProvider = FutureProvider.autoDispose.family<EventTicketing, int>((ref, eventId) {
  return ref.watch(ticketingApiProvider).getEventTicketing(eventId);
});

class TicketingError implements Exception {
  final String message;
  final int? statusCode;

  TicketingError(this.message, {this.statusCode});

  bool get insufficientFunds => message.toLowerCase().contains('insufficient');

  @override
  String toString() => message;
}

class TicketingApi {
  final Dio _dio;

  TicketingApi(this._dio);

  Future<EventTicketing> getEventTicketing(int eventId) async {
    final body = await _call(() => _dio.get('/events/$eventId/ticketing'));
    return EventTicketing.fromMap(Map<String, dynamic>.from(body['data']));
  }

  /// [quantities] maps ticket category id -> quantity (zero entries are ignored).
  Future<CheckoutResult> checkout({
    required int eventId,
    required Map<int, int> quantities,
    required String paymentMethod, // wallet | flutterwave
    List<Map<String, String>>? attendees,
  }) async {
    final items = quantities.entries
        .where((e) => e.value > 0)
        .map((e) => {'ticket_type_id': e.key, 'quantity': e.value})
        .toList();

    final body = await _call(() => _dio.post('/events/tickets/checkout', data: {
          'event_id': eventId,
          'items': items,
          'payment_method': paymentMethod,
          if (attendees != null && attendees.isNotEmpty) 'attendees': attendees,
        }));

    final data = Map<String, dynamic>.from(body['data']);
    return CheckoutResult(
      order: TicketOrderModel.fromMap(Map<String, dynamic>.from(data['order'])),
      paymentLink: data['payment_link']?.toString(),
      message: body['message']?.toString() ?? '',
    );
  }

  Future<TicketOrderModel> getOrder(String reference) async {
    final body = await _call(() => _dio.get('/events/ticket-orders/$reference'));
    return TicketOrderModel.fromMap(Map<String, dynamic>.from(body['data']));
  }

  Future<Map<String, dynamic>> _call(Future<Response> Function() fn) async {
    try {
      final res = await fn();
      final body = res.data;
      if (body is Map && body['status'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw TicketingError(body is Map ? (body['message']?.toString() ?? 'Something went wrong') : 'Something went wrong',
          statusCode: res.statusCode);
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map && body['message'] != null ? body['message'].toString() : (e.message ?? 'Network error. Please try again.');
      throw TicketingError(message, statusCode: e.response?.statusCode);
    }
  }
}
