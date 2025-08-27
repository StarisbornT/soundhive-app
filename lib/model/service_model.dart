import 'dart:convert';

class ServiceResponse {
  final bool status;
  final String message;
  final PaginatedServiceData data;

  ServiceResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ServiceResponse.fromJson(String source) =>
      ServiceResponse.fromMap(json.decode(source));

  factory ServiceResponse.fromMap(Map<String, dynamic> map) {
    return ServiceResponse(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: PaginatedServiceData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedServiceData {
  final int currentPage;
  final List<ServiceItem> data;
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

  PaginatedServiceData({
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

  factory PaginatedServiceData.fromMap(Map<String, dynamic> map) {
    return PaginatedServiceData(
      currentPage: map['current_page'] ?? 1,
      data: List<ServiceItem>.from(
        (map['data'] ?? []).map((x) => ServiceItem.fromMap(x)),
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

class ServiceItem {
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

  ServiceItem({
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
  });

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] ?? 0,
      userId: map['user_id'] ?? '',
      serviceName: map['service_name'] ?? '',
      categoryId: map['category_id'] ?? '',
      subCategoryId: map['sub_category_id'] ?? '',
      rate: map['rate'] ?? '',
      coverImage: map['cover_image'] ?? '',
      link: map['link'],
      serviceImage: map['service_image'] ?? '',
      serviceAudio: map['service_audio'],
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}
