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
  final String? genre;
  final String? bio;
  // ASSUMPTION — unconfirmed against the actual `artists` migration.
  // A prior comment in OverviewStage said followers "exists on the
  // Artists backend model" but that was never verified against schema.
  // Defaults to 0 rather than throwing if the column turns out to be
  // named differently or doesn't exist yet — but confirm the real
  // column name before trusting this in the UI.
  final int followers;
  // Computed on the backend (Artists::getMonthlyListenersAttribute),
  // not a stored column — always present, 0 is a legitimate value
  // (no plays in the last 30 days), not "missing data".
  final int monthlyListeners;
  // Full catalogue, only present when the API eager-loads artist.songs
  // (currently: the vest list/detail endpoints). Null, not empty list,
  // when it wasn't requested — so screens can tell "not loaded" apart
  // from "artist genuinely has no songs".
  final List<ArtistSong>? songs;

  ArtistItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.profilePhoto,
    required this.coverPhoto,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.genre,
    this.bio,
    this.followers = 0,
    this.monthlyListeners = 0,
    this.songs,
  });

  /// Real discography with placeholder/demo rows stripped out.
  ///
  /// STOPGAP: songs get created as FK placeholders (see
  /// SoundHiveVestSeeder::seedR3nayArtist) before an artist has real
  /// tracks uploaded, and those are marked PUBLISHED so they aren't
  /// hidden anywhere else that filters by status — which means they'd
  /// otherwise show up here as if they were real catalogue. Filtering by
  /// a title suffix is fragile; the correct fix is an `is_placeholder`
  /// boolean column on `songs` so this can check a real flag instead of
  /// pattern-matching a string.
  List<ArtistSong> get publishedDiscography =>
      (songs ?? []).where((s) => !s.title.endsWith('(Placeholder)')).toList();

  /// Artist-level "worked with" list, deduped, derived from
  /// featured_artists across every real (non-placeholder) song —
  /// there's no dedicated collaborators table, so this is the closest
  /// thing to real data rather than an invented list.
  List<String> get collaborators {
    final seen = <String>{};
    for (final song in publishedDiscography) {
      for (final name in song.featuredArtists) {
        if (name.trim().isNotEmpty) seen.add(name.trim());
      }
    }
    return seen.toList();
  }

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
      genre: map['genre'],
      bio: map['bio'],
      followers: map['followers'] ?? 0,
      monthlyListeners: map['monthly_listeners'] ?? 0,
      songs: map['songs'] != null
          ? List<ArtistSong>.from(
          (map['songs'] as List).map((x) => ArtistSong.fromMap(x)))
          : null,
    );
  }
}

/// A song as it appears in an artist's discography. Deliberately separate
/// from investment_model.dart's VestSong (the single track attached to a
/// specific vest) rather than shared, so artists_model.dart doesn't need
/// to import investment_model.dart (which already imports this file).
class ArtistSong {
  final int id;
  final String title;
  final String coverPhoto;
  final String status; // PENDING, REJECTED, PUBLISHED
  final List<String> featuredArtists;

  ArtistSong({
    required this.id,
    required this.title,
    required this.coverPhoto,
    required this.status,
    required this.featuredArtists,
  });

  factory ArtistSong.fromMap(Map<String, dynamic> map) {
    return ArtistSong(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      coverPhoto: map['cover_photo'] ?? '',
      status: map['status'] ?? 'PENDING',
      featuredArtists: map['featured_artists'] != null
          ? List<String>.from(map['featured_artists'])
          : [],
    );
  }
}