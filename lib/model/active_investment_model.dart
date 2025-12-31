import 'dart:convert';
import 'market_orders_service_model.dart';

class ActiveInvestmentResponse {
  final bool status;
  final PaginatedActiveInvestmentData data;

  ActiveInvestmentResponse({
    required this.status,
    required this.data,
  });

  factory ActiveInvestmentResponse.fromJson(String source) =>
      ActiveInvestmentResponse.fromMap(json.decode(source));

  factory ActiveInvestmentResponse.fromMap(Map<String, dynamic> map) {
    return ActiveInvestmentResponse(
      status: map['status'] ?? false,
      data: PaginatedActiveInvestmentData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedActiveInvestmentData {
  final int currentPage;
  final List<ActiveInvestment> data;
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

  PaginatedActiveInvestmentData({
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

  factory PaginatedActiveInvestmentData.fromMap(Map<String, dynamic> map) {
    return PaginatedActiveInvestmentData(
      currentPage: map['current_page'] ?? 0,
      data: List<ActiveInvestment>.from(
          map['data']?.map((x) => ActiveInvestment.fromMap(x)) ?? []),
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

class ActiveInvestment {
  final int id;
  final String serviceId;
  final String userId;
  final List<String> date;
  final String status;
  final String createdAt;
  final String updatedAt;
  final MarketOrder? service;

  ActiveInvestment({
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.date,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.service,
  });

  factory ActiveInvestment.fromJson(String source) =>
      ActiveInvestment.fromMap(json.decode(source));

  factory ActiveInvestment.fromMap(Map<String, dynamic> map) {
    return ActiveInvestment(
      id: map['id'] ?? 0,
      serviceId: map['service_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      date: map['date'] is List
          ? List<String>.from(map['date'])
          : [map['date']?.toString() ?? ''],
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      service: map['service'] != null ? MarketOrder.fromMap(map['service']) : null,
    );
  }
}