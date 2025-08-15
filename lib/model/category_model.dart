import 'dart:convert';

class CategoryResponse {
  final List<Category> data;

  CategoryResponse({required this.data});

  factory CategoryResponse.fromJson(String source) =>
      CategoryResponse.fromMap(json.decode(source));

  factory CategoryResponse.fromMap(dynamic map) {
    return CategoryResponse(
      data: List<Category>.from(map.map((x) => Category.fromMap(x))),
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
      name: map['name'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}
