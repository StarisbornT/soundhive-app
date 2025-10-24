import 'dart:convert';

import 'artist_profile_id_model.dart';

class PlaylistModel {
  final bool status;
  final PaginatedData data;

  PlaylistModel({
    required this.status,
    required this.data,
  });

  factory PlaylistModel.fromJson(String source) =>
      PlaylistModel.fromMap(json.decode(source));

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      status: map['status'] ?? false,
      data: PaginatedData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedData {
  final int currentPage;
  final List<Playlist> data;
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

  PaginatedData({
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

  factory PaginatedData.fromMap(Map<String, dynamic> map) {
    return PaginatedData(
      currentPage: map['current_page'] ?? 1,
      data: List<Playlist>.from(
        (map['data'] ?? []).map((x) => Playlist.fromMap(x)),
      ),
      firstPageUrl: map['first_page_url'],
      from: map['from'],
      lastPage: map['last_page'] ?? 0,
      lastPageUrl: map['last_page_url'],
      links: List<Link>.from(
        (map['links'] ?? []).map((x) => Link.fromMap(x)),
      ),
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

class Playlist {
  final int id;
  final String userId;
  final String title;
  final String createdAt;
  final String updatedAt;
  final String songsCount;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.songsCount,
    required this.songs,
  });

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] ?? 0,
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      songsCount: map['songs_count'] ?? '0',
      songs: List<Song>.from(
        (map['songs'] ?? []).map((x) => Song.fromMap(x)),
      ),
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
