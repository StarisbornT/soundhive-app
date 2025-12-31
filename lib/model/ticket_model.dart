import 'dart:convert';

import 'package:soundhive2/model/user_model.dart';

import 'event_model.dart';

class TicketModel {
  final bool status;
  final PaginatedEventData data;

  TicketModel({
    required this.status,
    required this.data,
  });

  factory TicketModel.fromJson(String source) =>
      TicketModel.fromMap(json.decode(source));

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      status: map['status'] ?? false,
      data: PaginatedEventData.fromMap(map['tickets'] ?? {}),
    );
  }
}

class PaginatedEventData {
  final int currentPage;
  final List<TicketItem> data;
  final String firstPageUrl;
  final int from;
  final int lastPage;
  final String lastPageUrl;
  final List<PageLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  PaginatedEventData({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory PaginatedEventData.fromMap(Map<String, dynamic> map) {
    return PaginatedEventData(
      currentPage: map['current_page'] ?? 0,
      data: List<TicketItem>.from(
          map['data']?.map((x) => TicketItem.fromMap(x)) ?? []),
      firstPageUrl: map['first_page_url'] ?? '',
      from: map['from'] ?? 0,
      lastPage: map['last_page'] ?? 0,
      lastPageUrl: map['last_page_url'] ?? '',
      links: List<PageLink>.from(
          map['links']?.map((x) => PageLink.fromMap(x)) ?? []),
      nextPageUrl: map['next_page_url'],
      path: map['path'] ?? '',
      perPage: map['per_page'] ?? 0,
      prevPageUrl: map['prev_page_url'],
      to: map['to'] ?? 0,
      total: map['total'] ?? 0,
    );
  }
}

class TicketItem {
  final int id;
  final dynamic eventId;
  final dynamic userId;
  final String ticketNumber;
  final String qrCodePath;
  final String status;
  final String amount;
  final String createdAt;
  final String updatedAt;
  final EventItem event;
  final User user;

  TicketItem({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.ticketNumber,
    required this.qrCodePath,
    required this.status,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    required this.event,
    required this.user,

  });

  factory TicketItem.fromMap(Map<String, dynamic> map) {
    return TicketItem(
      id: map['id'] ?? 0,
      eventId: map['event_id'] ?? '',
      userId: map['user_id'] ?? '',
      ticketNumber: map['ticket_number'] ?? '',
      qrCodePath: map['qr_code_path'] ?? '',
      status: map['status'] ?? '',
      amount: map['amount'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      event: EventItem.fromMap(map['event'] ?? {}),
      user: User.fromJson(map['user'] ?? {}),
    );
  }
}

class PageLink {
  final String? url;
  final String label;
  final bool active;

  PageLink({
    this.url,
    required this.label,
    required this.active,
  });

  factory PageLink.fromMap(Map<String, dynamic> map) {
    return PageLink(
      url: map['url'],
      label: map['label'] ?? '',
      active: map['active'] ?? false,
    );
  }
}

