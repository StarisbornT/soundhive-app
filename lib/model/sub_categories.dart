import 'dart:convert';

class SubCategories {
  final List<SubCategory> data;
  final String message;

  SubCategories({
    required this.data,
    required this.message,
  });

  factory SubCategories.fromMap(Map<String, dynamic> json) {
    return SubCategories(
      data: (json['data'] as List<dynamic>)
          .map((item) => SubCategory.fromMap(item as Map<String, dynamic>))
          .toList(),
      message: json['message'] ?? '',
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
