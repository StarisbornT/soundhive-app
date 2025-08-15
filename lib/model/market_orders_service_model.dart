import 'dart:convert';

import 'package:soundhive2/model/user_model.dart';

class MarketOrdersPaginatedModel {
  final bool status;
  final MarketOrdersPaginatedData data;

  MarketOrdersPaginatedModel({
    required this.status,
    required this.data,
  });

  factory MarketOrdersPaginatedModel.fromJson(String source) =>
      MarketOrdersPaginatedModel.fromMap(json.decode(source));

  factory MarketOrdersPaginatedModel.fromMap(Map<String, dynamic> map) {
    return MarketOrdersPaginatedModel(
      status: map['status'] ?? false,
      data: MarketOrdersPaginatedData.fromMap(map['data'] ?? {}),
    );
  }
}

class MarketOrdersPaginatedData {
  final int currentPage;
  final List<MarketOrder> data;
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

  MarketOrdersPaginatedData({
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

  factory MarketOrdersPaginatedData.fromMap(Map<String, dynamic> map) {
    return MarketOrdersPaginatedData(
      currentPage: map['current_page'] ?? 1,
      data: List<MarketOrder>.from(
          map['data']?.map((x) => MarketOrder.fromMap(x)) ?? []),
      firstPageUrl: map['first_page_url'] ?? '',
      from: map['from'] ?? 0,
      lastPage: map['last_page'] ?? 1,
      lastPageUrl: map['last_page_url'] ?? '',
      links: List<PageLink>.from(
          map['links']?.map((x) => PageLink.fromMap(x)) ?? []),
      nextPageUrl: map['next_page_url'],
      path: map['path'] ?? '',
      perPage: int.tryParse(map['per_page'].toString()) ?? 10,
      prevPageUrl: map['prev_page_url'],
      to: map['to'] ?? 0,
      total: map['total'] ?? 0,
    );
  }
}

class MarketOrder {
  final int id;
  final String memberId;
  final String status;
  final String serviceName;
  final String serviceAmount;
  final String serviceImage;
  final String servicePortfolioFormat;
  final String servicePortfolioImage;
  final String? servicePortfolioLink;
  final String? servicePortfolioAudio;
  final String createdAt;
  final String updatedAt;
  final User? user;
  final Creator? creator;

  MarketOrder({
    required this.id,
    required this.memberId,
    required this.status,
    required this.serviceName,
    required this.serviceAmount,
    required this.serviceImage,
    required this.servicePortfolioFormat,
    required this.servicePortfolioImage,
    this.servicePortfolioLink,
    this.servicePortfolioAudio,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.creator
  });

  factory MarketOrder.fromMap(Map<String, dynamic> map) {
    return MarketOrder(
      id: map['id'] ?? 0,
      memberId: map['member_id'] ?? '',
      status: map['status'] ?? '',
      serviceName: map['service_name'] ?? '',
      serviceAmount: map['service_amount'] ?? '',
      serviceImage: map['service_image'] ?? '',
      servicePortfolioFormat: map['service_portfolio_format'] ?? '',
      servicePortfolioImage: map['service_portfolio_image'] ?? '',
      servicePortfolioLink: map['service_portfolio_link'],
      servicePortfolioAudio: map['service_portfolio_audio'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      user: map['member'] != null ? User.fromJson(map['member']) : null,
      creator: map['creator'] != null ? Creator.fromJson(map['creator']) : null,
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
