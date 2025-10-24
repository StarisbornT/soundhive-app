import 'dart:convert';

class SongStatsModel {
  final bool status;
  final String message;
  final SongStatsData data;

  SongStatsModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SongStatsModel.fromJson(String source) =>
      SongStatsModel.fromMap(json.decode(source));

  factory SongStatsModel.fromMap(Map<String, dynamic> map) {
    return SongStatsModel(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: SongStatsData.fromMap(map['data'] ?? {}),
    );
  }
}

class SongStatsData {
  final SongStats songStats;
  final Performance performance;
  final Earnings earnings;

  SongStatsData({
    required this.songStats,
    required this.performance,
    required this.earnings,
  });

  factory SongStatsData.fromMap(Map<String, dynamic> map) {
    return SongStatsData(
      songStats: SongStats.fromMap(map['song_stats'] ?? {}),
      performance: Performance.fromMap(map['performance'] ?? {}),
      earnings: Earnings.fromMap(map['earnings'] ?? {}),
    );
  }
}

class SongStats {
  final int created;
  final int published;
  final int rejected;
  final int underReview;

  SongStats({
    required this.created,
    required this.published,
    required this.rejected,
    required this.underReview,
  });

  factory SongStats.fromMap(Map<String, dynamic> map) {
    return SongStats(
      created: map['created'] ?? 0,
      published: map['published'] ?? 0,
      rejected: map['rejected'] ?? 0,
      underReview: map['under_review'] ?? 0,
    );
  }
}

class Performance {
  final dynamic plays;
  final String followers;

  Performance({
    required this.plays,
    required this.followers,
  });

  factory Performance.fromMap(Map<String, dynamic> map) {
    return Performance(
      plays: map['plays'] ?? 0,
      followers: map['followers'] ?? 0,
    );
  }
}

class Earnings {
  final double totalEarned;
  final String formattedTotal;

  Earnings({
    required this.totalEarned,
    required this.formattedTotal,
  });

  factory Earnings.fromMap(Map<String, dynamic> map) {
    return Earnings(
      totalEarned: (map['total_earned'] ?? 0).toDouble(),
      formattedTotal: map['formatted_total'] ?? '0.00',
    );
  }
}
