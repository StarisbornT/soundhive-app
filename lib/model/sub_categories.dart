import 'dart:convert';

class SubCategories {
  final bool status;
  final List<SubCategory> data;
  final String? nextPageUrl;   // add this
  final int? currentPage;      // add this
  final int? lastPage;
  // final String message;

  SubCategories({
    required this.status,
    required this.data,
    this.nextPageUrl,
    this.currentPage,
    this.lastPage,
  });

  factory SubCategories.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];

    // API returns a flat array (no pagination wrapper)
    if (rawData is List) {
      return SubCategories(
        status: map['status'] ?? false,
        data: rawData.map((e) => SubCategory.fromMap(e)).toList(),
        nextPageUrl: null,
        currentPage: null,
        lastPage: null,
      );
    }

    // Paginated response (future-proofed if API changes)
    final pagination = rawData as Map<String, dynamic>?;
    return SubCategories(
      status: map['status'] ?? false,
      data: (pagination?['data'] as List? ?? [])
          .map((e) => SubCategory.fromMap(e))
          .toList(),
      nextPageUrl: pagination?['next_page_url'] as String?,
      currentPage: pagination?['current_page'] as int?,
      lastPage: pagination?['last_page'] as int?,
    );
  }
}

class SubCategory {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  SubCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubCategory.fromJson(String source) =>
      SubCategory.fromMap(json.decode(source));

  factory SubCategory.fromMap(Map<String, dynamic> map) {
    return SubCategory(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}
