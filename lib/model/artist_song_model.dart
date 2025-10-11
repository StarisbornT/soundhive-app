import 'dart:convert';

import 'package:soundhive2/model/user_model.dart';

class ArtistSongModel {
  final bool status;
  final String message;
  final PaginatedSongData data;

  ArtistSongModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ArtistSongModel.fromJson(String source) =>
      ArtistSongModel.fromMap(json.decode(source));

  factory ArtistSongModel.fromMap(Map<String, dynamic> map) {
    return ArtistSongModel(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: PaginatedSongData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedSongData {
  final int currentPage;
  final List<SongItem> data;
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

  PaginatedSongData({
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

  factory PaginatedSongData.fromMap(Map<String, dynamic> map) {
    return PaginatedSongData(
      currentPage: map['current_page'] ?? 1,
      data: List<SongItem>.from(
        (map['data'] ?? []).map((x) => SongItem.fromMap(x)),
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

class SongItem {
  final int id;
  final String artistId;
  final String title;
  final String type;
  final String songAudio;
  final String coverPhoto;
  final dynamic featuredArtists;
  final String status;
  final String createdAt;
  final String updatedAt;
  final Artist? artist;
  final String plays;

  SongItem({
    required this.id,
    required this.artistId,
    required this.title,
    required this.type,
    required this.songAudio,
    required this.coverPhoto,
    this.featuredArtists,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.artist,
    required this.plays
  });

  factory SongItem.fromMap(Map<String, dynamic> map) {
    return SongItem(
      id: map['id'] ?? 0,
      artistId: map['artist_id']?.toString() ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? '',
      songAudio: map['song_audio'] ?? '',
      coverPhoto: map['cover_photo'] ?? '',
      featuredArtists: map['featured_artists'],
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      plays: map['plays'],
      artist: map['artist'] != null
          ? Artist.fromJson(map['artist'])
          : null,
    );
  }
}
