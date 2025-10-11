import 'dart:convert';

class ArtistsModel {
  final bool status;
  final String message;
  final PaginatedArtistData data;

  ArtistsModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ArtistsModel.fromJson(String source) =>
      ArtistsModel.fromMap(json.decode(source));

  factory ArtistsModel.fromMap(Map<String, dynamic> map) {
    return ArtistsModel(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: PaginatedArtistData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedArtistData {
  final int currentPage;
  final List<ArtistItem> data;
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

  PaginatedArtistData({
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

  factory PaginatedArtistData.fromMap(Map<String, dynamic> map) {
    return PaginatedArtistData(
      currentPage: map['current_page'] ?? 1,
      data: List<ArtistItem>.from(
        (map['data'] ?? []).map((x) => ArtistItem.fromMap(x)),
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

class ArtistItem {
  final int id;
  final String userId;
  final String username;
  final String profilePhoto;
  final String coverPhoto;
  final bool status;
  final String createdAt;
  final String updatedAt;

  ArtistItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.profilePhoto,
    required this.coverPhoto,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArtistItem.fromMap(Map<String, dynamic> map) {
    return ArtistItem(
      id: map['id'] ?? 0,
      userId: map['user_id']?.toString() ?? '',
      username: map['username'] ?? '',
      profilePhoto: map['profile_photo'] ?? '',
      coverPhoto: map['cover_photo'] ?? '',
      status: map['status'] ?? false,
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}
