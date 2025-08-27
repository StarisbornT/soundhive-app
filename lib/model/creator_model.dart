import 'dart:convert';
import 'package:soundhive2/model/user_model.dart';

class CreatorListResponse {
  final String message;
  final CreatorPaginatedData? user;

  CreatorListResponse({
    required this.message,
    this.user,
  });

  factory CreatorListResponse.fromJson(String source) =>
      CreatorListResponse.fromMap(json.decode(source));

  factory CreatorListResponse.fromMap(Map<String, dynamic> json) {
    return CreatorListResponse(
      message: json['message'] ?? '',
      user: json['user'] != null
          ? CreatorPaginatedData.fromMap(json['user'])
          : null,
    );
  }
}



class CreatorPaginatedData {
  final int currentPage;
  final List<CreatorData> data;
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

  CreatorPaginatedData({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory CreatorPaginatedData.fromJson(String source) =>
      CreatorPaginatedData.fromMap(json.decode(source));

  factory CreatorPaginatedData.fromMap(Map<String, dynamic> json) {
    return CreatorPaginatedData(
      currentPage: json['current_page'] ?? 1,
      data: List<CreatorData>.from(
          (json['data'] ?? []).map((x) => CreatorData.fromJson(x))),
      firstPageUrl: json['first_page_url'],
      from: json['from'],
      lastPage: json['last_page'] ?? 1,
      lastPageUrl: json['last_page_url'],
      links: List<Link>.from((json['links'] ?? []).map((x) => Link.fromMap(x))),
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      perPage: json['per_page'] is String
          ? int.tryParse(json['per_page']) ?? 0
          : (json['per_page'] ?? 0),
      prevPageUrl: json['prev_page_url'],
      to: json['to'],
      total: json['total'] ?? 0,
    );
  }
}



class CreatorData {
  final int id;
  final String userId;
  final String gender;
  final String nin;
  final String idType;
  final String? copyOfId;
  final String utilityBill;
  final String? copyOfUtilityBill;
  final String jobTitle;
  final String bio;
  final bool active;
  final String location;
  final String linkedin;
  final String x;
  final String instagram;
  final String createdAt;
  final String updatedAt;
  final User? user; // embedded user object

  CreatorData({
    required this.id,
    required this.userId,
    required this.gender,
    required this.nin,
    required this.idType,
    this.copyOfId,
    required this.utilityBill,
    this.copyOfUtilityBill,
    required this.jobTitle,
    required this.bio,
    required this.active,
    required this.location,
    required this.linkedin,
    required this.x,
    required this.instagram,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory CreatorData.fromJson(Map<String, dynamic> json) {
    return CreatorData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      gender: json['gender'] ?? '',
      nin: json['nin'] ?? '',
      idType: json['id_type'] ?? '',
      copyOfId: json['copy_of_id'],
      utilityBill: json['utility_bill'] ?? '',
      copyOfUtilityBill: json['copy_of_utility_bill'],
      jobTitle: json['job_title'] ?? '',
      bio: json['bio'] ?? '',
      active: json['active'] ?? false,
      location: json['location'] ?? '',
      linkedin: json['linkedin'] ?? '',
      x: json['x'] ?? '',
      instagram: json['instagram'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class Link {
  final String? url;
  final String label;
  final bool active;

  Link({
    this.url,
    required this.label,
    required this.active,
  });

  factory Link.fromMap(Map<String, dynamic> map) {
    return Link(
      url: map['url'],
      label: map['label'] ?? '',
      active: map['active'] ?? false,
    );
  }
}
