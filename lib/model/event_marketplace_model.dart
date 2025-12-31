import 'dart:convert';

import 'event_model.dart';

class EventMarketplaceModel {
  final bool status;
  final String message;
  final PaginatedEventData data;

  EventMarketplaceModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory EventMarketplaceModel.fromJson(String source) =>
      EventMarketplaceModel.fromMap(json.decode(source));

  factory EventMarketplaceModel.fromMap(Map<String, dynamic> map) {
    return EventMarketplaceModel(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: PaginatedEventData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedEventData {
  final int currentPage;
  final List<EventItem> data;
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
      data: List<EventItem>.from(
          map['data']?.map((x) => EventItem.fromMap(x)) ?? []),
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

