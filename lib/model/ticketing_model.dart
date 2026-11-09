// Module 3 — event ticket categories, checkout and orders.
// Mirrors:
//   GET  /events/{id}/ticketing            -> EventTicketing
//   POST /events/tickets/checkout          -> CheckoutResult
//   GET  /events/ticket-orders/{reference} -> TicketOrderModel

import 'dart:convert';
import 'dart:typed_data';

double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
double? _dn(dynamic v) => v == null ? null : double.tryParse(v.toString());
int _i(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;
int? _in(dynamic v) => v == null ? null : int.tryParse(v.toString());

class TicketCategory {
  final int id;
  final String name;
  final String? description;
  final String? perks;
  final double price;
  final String currency;
  final double userPrice;
  final int? available; // null = unlimited
  final int minPerOrder;
  final int maxPerOrder;
  final bool onSale;
  final bool soldOut;

  TicketCategory({
    required this.id,
    required this.name,
    this.description,
    this.perks,
    required this.price,
    required this.currency,
    required this.userPrice,
    this.available,
    required this.minPerOrder,
    required this.maxPerOrder,
    required this.onSale,
    required this.soldOut,
  });

  factory TicketCategory.fromMap(Map<String, dynamic> m) => TicketCategory(
        id: _i(m['id']),
        name: m['name']?.toString() ?? '',
        description: m['description']?.toString(),
        perks: m['perks']?.toString(),
        price: _d(m['price']),
        currency: m['currency']?.toString() ?? 'NGN',
        userPrice: _d(m['user_price']),
        available: _in(m['available']),
        minPerOrder: _i(m['min_per_order']) == 0 ? 1 : _i(m['min_per_order']),
        maxPerOrder: _i(m['max_per_order']) == 0 ? 10 : _i(m['max_per_order']),
        onSale: m['on_sale'] == true,
        soldOut: m['sold_out'] == true,
      );
}

class EventTicketing {
  final int eventId;
  final String title;
  final String? image;
  final String date;
  final String time;
  final String location;
  final String? ageRestriction;
  final String organiser;
  final String issuedBy;
  final List<TicketCategory> categories;
  final String userCurrency;
  final bool purchasable;
  final String? closedReason;
  final int maxPerOrder;

  EventTicketing({
    required this.eventId,
    required this.title,
    this.image,
    required this.date,
    required this.time,
    required this.location,
    this.ageRestriction,
    required this.organiser,
    required this.issuedBy,
    required this.categories,
    required this.userCurrency,
    required this.purchasable,
    this.closedReason,
    required this.maxPerOrder,
  });

  factory EventTicketing.fromMap(Map<String, dynamic> m) {
    final e = Map<String, dynamic>.from(m['event'] ?? {});
    return EventTicketing(
      eventId: _i(e['id']),
      title: e['title']?.toString() ?? '',
      image: e['image']?.toString(),
      date: e['date']?.toString() ?? '',
      time: e['time']?.toString() ?? '',
      location: e['location']?.toString() ?? '',
      ageRestriction: e['age_restriction']?.toString(),
      organiser: e['organiser']?.toString() ?? '',
      issuedBy: e['issued_by']?.toString() ?? 'Cre8Hive',
      categories: ((m['ticket_types'] as List?) ?? [])
          .map((t) => TicketCategory.fromMap(Map<String, dynamic>.from(t)))
          .toList(),
      userCurrency: m['user_currency']?.toString() ?? 'NGN',
      purchasable: m['purchasable'] == true,
      closedReason: m['closed_reason']?.toString(),
      maxPerOrder: _i(m['max_per_order']) == 0 ? 10 : _i(m['max_per_order']),
    );
  }
}

class IssuedTicketModel {
  final int id;
  final String ticketNumber;
  final String? type;
  final String? attendeeName;
  final String status; // PAID (valid) USED REFUNDED VOIDED
  final String? checkinStatus;
  final String? qrCodePath; // data:image/png;base64,...

  IssuedTicketModel({
    required this.id,
    required this.ticketNumber,
    this.type,
    this.attendeeName,
    required this.status,
    this.checkinStatus,
    this.qrCodePath,
  });

  bool get isValid => status == 'PAID';

  Uint8List? get qrBytes {
    final p = qrCodePath;
    if (p == null || !p.startsWith('data:image/png;base64,')) return null;
    try {
      return base64.decode(p.split(',').last);
    } catch (_) {
      return null;
    }
  }

  factory IssuedTicketModel.fromMap(Map<String, dynamic> m) => IssuedTicketModel(
        id: _i(m['id']),
        ticketNumber: m['ticket_number']?.toString() ?? '',
        type: m['type']?.toString(),
        attendeeName: m['attendee_name']?.toString(),
        status: m['status']?.toString() ?? '',
        checkinStatus: m['checkin_status']?.toString(),
        qrCodePath: m['qr_code_path']?.toString(),
      );
}

class TicketOrderItemModel {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  TicketOrderItemModel({required this.name, required this.quantity, required this.unitPrice, required this.lineTotal});

  factory TicketOrderItemModel.fromMap(Map<String, dynamic> m) => TicketOrderItemModel(
        name: m['name']?.toString() ?? '',
        quantity: _i(m['quantity']),
        unitPrice: _d(m['unit_price']),
        lineTotal: _d(m['line_total']),
      );
}

class TicketOrderModel {
  final int id;
  final String reference;
  final String status;
  final String statusLabel;
  final String message;
  final bool isFinal;
  final String eventTitle;
  final String? eventDate;
  final String? eventTime;
  final String? eventLocation;
  final List<TicketOrderItemModel> items;
  final int quantity;
  final double total;
  final String currency;
  final double? paidAmount;
  final String? paidCurrency;
  final String paymentMethod;
  final double refundedAmount;
  final List<IssuedTicketModel> tickets;

  TicketOrderModel({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.message,
    required this.isFinal,
    required this.eventTitle,
    this.eventDate,
    this.eventTime,
    this.eventLocation,
    required this.items,
    required this.quantity,
    required this.total,
    required this.currency,
    this.paidAmount,
    this.paidCurrency,
    required this.paymentMethod,
    required this.refundedAmount,
    required this.tickets,
  });

  bool get isIssued => status == 'ISSUED' || status == 'PARTIALLY_REFUNDED';
  bool get isWaiting => status == 'PAID' || status == 'ISSUING' || status == 'PENDING_PAYMENT';
  bool get isFailed => status == 'ISSUE_FAILED' || status == 'PAYMENT_FAILED' || status == 'EXPIRED' || status == 'REFUNDED';

  factory TicketOrderModel.fromMap(Map<String, dynamic> m) {
    final e = Map<String, dynamic>.from(m['event'] ?? {});
    return TicketOrderModel(
      id: _i(m['id']),
      reference: m['reference']?.toString() ?? '',
      status: m['status']?.toString() ?? '',
      statusLabel: m['status_label']?.toString() ?? '',
      message: m['message']?.toString() ?? '',
      isFinal: m['is_final'] == true,
      eventTitle: e['title']?.toString() ?? '',
      eventDate: e['date']?.toString(),
      eventTime: e['time']?.toString(),
      eventLocation: e['location']?.toString(),
      items: ((m['items'] as List?) ?? []).map((i) => TicketOrderItemModel.fromMap(Map<String, dynamic>.from(i))).toList(),
      quantity: _i(m['quantity']),
      total: _d(m['total']),
      currency: m['currency']?.toString() ?? 'NGN',
      paidAmount: _dn(m['paid_amount']),
      paidCurrency: m['paid_currency']?.toString(),
      paymentMethod: m['payment_method']?.toString() ?? '',
      refundedAmount: _d(m['refunded_amount']),
      tickets: ((m['tickets'] as List?) ?? []).map((t) => IssuedTicketModel.fromMap(Map<String, dynamic>.from(t))).toList(),
    );
  }
}

class CheckoutResult {
  final TicketOrderModel order;
  final String? paymentLink;
  final String message;

  CheckoutResult({required this.order, this.paymentLink, required this.message});
}
