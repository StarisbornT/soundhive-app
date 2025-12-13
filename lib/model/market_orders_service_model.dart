import 'dart:convert';

import 'package:soundhive2/model/user_model.dart';

class MarketOrdersPaginatedModel {
  final bool status;
  final String message;
  final MarketOrdersPaginatedData data;

  MarketOrdersPaginatedModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory MarketOrdersPaginatedModel.fromJson(String source) =>
      MarketOrdersPaginatedModel.fromMap(json.decode(source));

  factory MarketOrdersPaginatedModel.fromMap(Map<String, dynamic> map) {
    return MarketOrdersPaginatedModel(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: MarketOrdersPaginatedData.fromMap(map['data'] ?? {}),
    );
  }
}

class MarketOrdersPaginatedData {
  final int currentPage;
  final List<MarketOrder> data;
  final String firstPageUrl;
  final int? from;
  final int lastPage;
  final String lastPageUrl;
  final List<PageLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  MarketOrdersPaginatedData({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory MarketOrdersPaginatedData.fromMap(Map<String, dynamic> map) {
    return MarketOrdersPaginatedData(
      currentPage: map['current_page'] ?? 1,
      data: List<MarketOrder>.from(
          map['data']?.map((x) => MarketOrder.fromMap(x)) ?? []),
      firstPageUrl: map['first_page_url'] ?? '',
      from: map['from'],
      lastPage: map['last_page'] ?? 1,
      lastPageUrl: map['last_page_url'] ?? '',
      links: List<PageLink>.from(
          map['links']?.map((x) => PageLink.fromMap(x)) ?? []),
      nextPageUrl: map['next_page_url'],
      path: map['path'] ?? '',
      perPage: int.tryParse(map['per_page'].toString()) ?? 10,
      prevPageUrl: map['prev_page_url'],
      to: map['to'],
      total: map['total'] ?? 0,
    );
  }
}

class MarketOrder {
  final int id;
  final String userId;
  final String serviceName;
  final String categoryId;
  final String subCategoryId;
  final String rate;
  final String coverImage;
  final String? link;
  final String serviceImage;
  final String? serviceAudio;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String currency;
  final String serviceDescription;
  final dynamic convertedRate;
  final String? bookingCount;
  final String convertedCurrency;
  final User? user;

  MarketOrder({
    required this.id,
    required this.userId,
    required this.serviceName,
    required this.categoryId,
    required this.subCategoryId,
    required this.rate,
    required this.coverImage,
    this.link,
    required this.serviceImage,
    this.serviceAudio,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.currency,
    this.bookingCount,
    required this.serviceDescription,
    required this.convertedRate,
    required this.convertedCurrency,
    this.user,
  });

  factory MarketOrder.fromMap(Map<String, dynamic> map) {
    return MarketOrder(
      id: map['id'] ?? 0,
      userId: map['user_id'] ?? '',
      serviceName: map['service_name'] ?? '',
      categoryId: map['category_id'] ?? '',
      bookingCount: map['bookings_count'] ?? '',
      subCategoryId: map['sub_category_id'] ?? '',
      rate: map['rate'] ?? '',
      coverImage: map['cover_image'] ?? '',
      link: map['link'],
      serviceImage: map['service_image'] ?? '',
      serviceAudio: map['service_audio'],
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      currency: map['currency'] ?? '',
      serviceDescription: map['service_description'] ?? '',
      convertedCurrency: map['converted_currency'] ?? '',
      convertedRate: map['converted_rate'] ?? '',
      user: map['user'] != null ? User.fromJson(map['user']) : null,
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