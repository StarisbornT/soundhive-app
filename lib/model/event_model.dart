import 'dart:convert';

import 'active_investment_model.dart';

/// ======================
/// MAIN RESPONSE
/// ======================
class EventResponse {
  final bool status;
  final String message;
  final PaginatedEventData data;

  EventResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory EventResponse.fromJson(String source) =>
      EventResponse.fromMap(json.decode(source));

  factory EventResponse.fromMap(Map<String, dynamic> map) {
    return EventResponse(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: PaginatedEventData.fromMap(map['data'] ?? {}),
    );
  }
}
class PaginatedEventData {
  final int currentPage;
  final List<EventItem> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final List<PageLink> links;
  final String? nextPageUrl;
  final String? path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  PaginatedEventData({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory PaginatedEventData.fromMap(Map<String, dynamic> map) {
    return PaginatedEventData(
      currentPage: map['current_page'] ?? 1,
      data: List<EventItem>.from(
        (map['data'] ?? []).map((x) => EventItem.fromMap(x)),
      ),
      firstPageUrl: map['first_page_url'],
      from: map['from'],
      lastPage: map['last_page'] ?? 1,
      lastPageUrl: map['last_page_url'],
      links: List<PageLink>.from(
        (map['links'] ?? []).map((x) => PageLink.fromMap(x)),
      ),
      nextPageUrl: map['next_page_url'],
      path: map['path'],
      perPage: map['per_page'] is int
          ? map['per_page']
          : int.tryParse(map['per_page']?.toString() ?? '10') ?? 10,
      prevPageUrl: map['prev_page_url'],
      to: map['to'],
      total: map['total'] ?? 0,
    );
  }
}

class EventItem {
  final int id;
  final String title;
  final String userId;
  final String date;
  final String time;
  final String location;
  final String description;
  final String type;
  final String image;
  final String currency;
  final String? reasonForCancellation;
  final String ticketLimit;
  final String amount;
  final String eventStatus;
  final String status;
  final String createdAt;
  final String updatedAt;
  final double? convertedRate;
  final String? convertedCurrency;
  final double? conversionRate;

  EventItem({
    required this.id,
    required this.title,
    required this.userId,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.type,
    required this.image,
    required this.currency,
    this.reasonForCancellation,
    required this.ticketLimit,
    required this.amount,
    required this.eventStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.convertedRate,
    this.convertedCurrency,
    this.conversionRate,

  });

  factory EventItem.fromMap(Map<String, dynamic> map) {
    return EventItem(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      userId: map['user_id'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      image: map['image'] ?? '',
      currency: map['currency'] ?? '',
      reasonForCancellation: map['reason_for_cancellation'],
      ticketLimit: map['ticket_limit'] ?? '',
      amount: map['amount'] ?? '',
      eventStatus: map['event_status'] ?? '',
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      convertedRate: map['converted_rate'] is String
          ? double.tryParse(map['converted_rate']) ?? 0.0
          : (map['converted_rate'] as num?)?.toDouble() ?? 0.0,
      convertedCurrency: map['converted_currency'] ?? '',
      conversionRate: map['conversion_rate'] is String
          ? double.tryParse(map['conversion_rate']) ?? 0.0
          : (map['conversion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
  bool get isPaid => type.toUpperCase() == 'PAID';
  bool get isFree => type.toUpperCase() == 'FREE';
  bool get isUpcoming => eventStatus.toUpperCase() == 'UPCOMING';
  bool get isOngoing => eventStatus.toUpperCase() == 'ONGOING';
  bool get isCompleted => eventStatus.toUpperCase() == 'COMPLETED';
  bool get isCancelled => eventStatus.toUpperCase() == 'CANCELLED';
  bool get isPublished => status.toUpperCase() == 'PUBLISHED';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  // Get parsed numeric values
  double get amountAsDouble => double.tryParse(amount) ?? 0.0;
  int get ticketLimitAsInt => int.tryParse(ticketLimit) ?? 0;
}

