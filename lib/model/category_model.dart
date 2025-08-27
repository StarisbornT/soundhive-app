import 'dart:convert';

class CategoryResponse {
  final bool status;
  final CategoryData data;

  CategoryResponse({
    required this.status,
    required this.data,
  });

  factory CategoryResponse.fromJson(String source) =>
      CategoryResponse.fromMap(json.decode(source));

  factory CategoryResponse.fromMap(Map<String, dynamic> map) {
    return CategoryResponse(
      status: map['status'] ?? false,
      data: CategoryData.fromMap(map['data'] ?? {}),
    );
  }
}

class CategoryData {
  final int currentPage;
  final List<Category> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final List<Link> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  CategoryData({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.path,
    required this.perPage,
    required this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory CategoryData.fromJson(String source) =>
      CategoryData.fromMap(json.decode(source));

  factory CategoryData.fromMap(Map<String, dynamic> map) {
    return CategoryData(
      currentPage: map['current_page'] ?? 1,
      data: List<Category>.from(
          (map['data'] ?? []).map((x) => Category.fromMap(x))),
      firstPageUrl: map['first_page_url'],
      from: map['from'],
      lastPage: map['last_page'] ?? 1,
      lastPageUrl: map['last_page_url'],
      links:
      List<Link>.from((map['links'] ?? []).map((x) => Link.fromMap(x))),
      nextPageUrl: map['next_page_url'],
      path: map['path'] ?? '',
      perPage: map['per_page'] is String
          ? int.tryParse(map['per_page']) ?? 0
          : (map['per_page'] ?? 0),
      prevPageUrl: map['prev_page_url'],
      to: map['to'],
      total: map['total'] ?? 0,
    );
  }
}

class Category {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(String source) =>
      Category.fromMap(json.decode(source));

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? 0,
      name: map['category_name'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}

class Link {
  final String? url;
  final String label;
  final bool active;

  Link({
    required this.url,
    required this.label,
    required this.active,
  });

  factory Link.fromJson(String source) =>
      Link.fromMap(json.decode(source));

  factory Link.fromMap(Map<String, dynamic> map) {
    return Link(
      url: map['url'],
      label: map['label'] ?? '',
      active: map['active'] ?? false,
    );
  }
}
