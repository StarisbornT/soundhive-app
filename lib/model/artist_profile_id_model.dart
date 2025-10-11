import 'dart:convert';

class ArtistProfileIdModel {
  final bool success;
  final ArtistData data;

  ArtistProfileIdModel({
    required this.success,
    required this.data,
  });

  factory ArtistProfileIdModel.fromJson(String source) =>
      ArtistProfileIdModel.fromMap(json.decode(source));

  factory ArtistProfileIdModel.fromMap(Map<String, dynamic> map) {
    return ArtistProfileIdModel(
      success: map['success'] ?? false,
      data: ArtistData.fromMap(map['data'] ?? {}),
    );
  }
}

class ArtistData {
  final Artist artist;
  final Stats stats;
  final List<Song> songs;
  final List<Event> events;

  ArtistData({
    required this.artist,
    required this.stats,
    required this.songs,
    required this.events,
  });

  factory ArtistData.fromMap(Map<String, dynamic> map) {
    return ArtistData(
      artist: Artist.fromMap(map['artist'] ?? {}),
      stats: Stats.fromMap(map['stats'] ?? {}),
      songs: List<Song>.from((map['songs'] ?? []).map((x) => Song.fromMap(x))),
      events: List<Event>.from((map['events'] ?? []).map((x) => Event.fromMap(x))),
    );
  }
}

class Artist {
  final int id;
  final String name;
  final String displayName;
  final String profileImage;
  final String coverImage;
  final String followerCount;

  Artist({
    required this.id,
    required this.name,
    required this.displayName,
    required this.profileImage,
    required this.coverImage,
    required this.followerCount,
  });

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      displayName: map['display_name'] ?? '',
      profileImage: map['profile_image'] ?? '',
      coverImage: map['cover_image'] ?? '',
      followerCount: map['follower_count'] ?? '0',
    );
  }
}

class Stats {
  final int totalViews;
  final int totalSongs;
  final String totalFollowers;

  Stats({
    required this.totalViews,
    required this.totalSongs,
    required this.totalFollowers,
  });

  factory Stats.fromMap(Map<String, dynamic> map) {
    return Stats(
      totalViews: map['total_views'] ?? 0,
      totalSongs: map['total_songs'] ?? 0,
      totalFollowers: map['total_followers'] ?? '0',
    );
  }
}

class Song {
  final int id;
  final String artistId;
  final String title;
  final String type;
  final String songAudio;
  final String coverPhoto;
  final String? featuredArtists;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String plays;

  Song({
    required this.id,
    required this.artistId,
    required this.title,
    required this.type,
    required this.songAudio,
    required this.coverPhoto,
    required this.featuredArtists,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.plays,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] ?? 0,
      artistId: map['artist_id'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? '',
      songAudio: map['song_audio'] ?? '',
      coverPhoto: map['cover_photo'] ?? '',
      featuredArtists: map['featured_artists'],
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      plays: map['plays'] ?? '0',
    );
  }
}

class Event {
  // You can expand this later when event fields are defined
  Event();

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event();
  }
}
