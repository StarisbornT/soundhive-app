import 'dart:convert';

import 'artists_model.dart';

class InvestmentResponse {
  final bool status;
  final PaginatedData data;

  InvestmentResponse({
    required this.status,
    required this.data,
  });

  factory InvestmentResponse.fromJson(String source) =>
      InvestmentResponse.fromMap(json.decode(source));

  factory InvestmentResponse.fromMap(Map<String, dynamic> map) {
    return InvestmentResponse(
      status: map['status'] ?? false,
      data: PaginatedData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedData {
  final int currentPage;
  final List<Investment> data;
  final String? firstPageUrl;
  final int from;
  final int lastPage;
  final String? lastPageUrl;
  final List<Link> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  PaginatedData({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    required this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory PaginatedData.fromMap(Map<String, dynamic> map) {
    return PaginatedData(
      currentPage: map['current_page'] ?? 1,
      data: List<Investment>.from(
        (map['data'] ?? []).map((x) => Investment.fromMap(x)),
      ),
      firstPageUrl: map['first_page_url'],
      from: map['from'] ?? 0,
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
      to: map['to'] ?? 0,
      total: map['total'] ?? 0,
    );
  }
}

class Investment {
  final int id;
  final String vestFor;
  final String beneficiaryName;
  final String investmentName;
  final String minimumAmount;
  final String roi;
  final String duration;
  final String description;
  final List<String> images;
  final String riskAssessment;
  final List<String> news;
  final String status;
  final String type; // GENERAL or ARTIST
  final String createdAt;
  final String updatedAt;
  final dynamic convertedMinimumAmount;
  final ArtistDetails? artistDetails;
  final List<VestMilestone> milestones;

  Investment({
    required this.id,
    required this.vestFor,
    required this.beneficiaryName,
    required this.investmentName,
    required this.minimumAmount,
    required this.roi,
    required this.duration,
    required this.description,
    required this.images,
    required this.riskAssessment,
    required this.news,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.convertedMinimumAmount,
    this.artistDetails,
    this.milestones = const [],
  });

  bool get isArtistVest => type.toUpperCase() == 'ARTIST';

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'] ?? 0,
      vestFor: map['vest_for'] ?? '',
      beneficiaryName: map['beneficiary_name'] ?? '',
      investmentName: map['investment_name'] ?? '',
      minimumAmount: map['minimum_amount'] ?? '',
      roi: map['roi']?.toString() ?? '',
      duration: map['duration']?.toString() ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      riskAssessment: map['risk_assessment'] ?? '',
      news: List<String>.from(map['news'] ?? []),
      status: map['status'] ?? '',
      type: map['type'] ?? 'GENERAL',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      convertedMinimumAmount: map['converted_minimum_amount'] ?? '',
      artistDetails: map['artist_details'] != null
          ? ArtistDetails.fromMap(map['artist_details'])
          : null,
      milestones: List<VestMilestone>.from(
        (map['milestones'] ?? []).map((x) => VestMilestone.fromMap(x)),
      ),
    );
  }
}

class ArtistDetails {
  final int id;
  final int categoryId;
  final String projectStage; // PRE_RELEASE or RELEASED
  final String projectType; // SINGLE, EP, ALBUM
  final double fundingTarget;
  final double totalRaised;
  // Backend now computes this via ArtistVestDetail::$appends — always
  // prefer this over doing the division on the client.
  final double fundingProgressPercentage;
  final double targetRoiMin;
  final double targetRoiMax;
  final double revenueSplitArtist;
  final double revenueSplitInvestor;
  final String riskLevel; // LOW / MEDIUM / HIGH — artist-vest specific
  final List<String> revenueStreamTags;
  final String? previewAudioUrl;
  final int? previewDurationSeconds;
  final HiveCategory? category;
  final VestSong? song;

  ArtistDetails({
    required this.id,
    required this.categoryId,
    required this.projectStage,
    required this.projectType,
    required this.fundingTarget,
    required this.totalRaised,
    required this.fundingProgressPercentage,
    required this.targetRoiMin,
    required this.targetRoiMax,
    required this.revenueSplitArtist,
    required this.revenueSplitInvestor,
    required this.riskLevel,
    required this.revenueStreamTags,
    this.previewAudioUrl,
    this.previewDurationSeconds,
    this.category,
    this.song,
  });

  /// 0.0–1.0 for LinearProgressIndicator. Derived from the backend-computed
  /// percentage so there's a single source of truth for the raw numbers.
  double get fundingProgress => (fundingProgressPercentage / 100).clamp(0.0, 1.0);

  /// Convenience passthrough — the artist behind this vest, if the song
  /// relation was loaded with its artist. Nullable because not every API
  /// call eager-loads this deep (e.g. list endpoints may omit it).
  ArtistItem? get artist => song?.artist;

  factory ArtistDetails.fromMap(Map<String, dynamic> map) {
    return ArtistDetails(
      id: map['id'] ?? 0,
      categoryId: map['category_id'] ?? 0,
      projectStage: map['project_stage'] ?? '',
      projectType: map['project_type'] ?? '',
      fundingTarget: double.tryParse(map['funding_target']?.toString() ?? '0') ?? 0.0,
      totalRaised: double.tryParse(map['total_raised']?.toString() ?? '0') ?? 0.0,
      fundingProgressPercentage:
      double.tryParse(map['funding_progress_percentage']?.toString() ?? '0') ?? 0.0,
      targetRoiMin: double.tryParse(map['target_roi_min']?.toString() ?? '0') ?? 0.0,
      targetRoiMax: double.tryParse(map['target_roi_max']?.toString() ?? '0') ?? 0.0,
      revenueSplitArtist: double.tryParse(map['revenue_split_artist']?.toString() ?? '0') ?? 0.0,
      revenueSplitInvestor:
      double.tryParse(map['revenue_split_investor']?.toString() ?? '0') ?? 0.0,
      riskLevel: map['risk_level'] ?? 'HIGH',
      revenueStreamTags: List<String>.from(map['revenue_stream_tags'] ?? []),
      previewAudioUrl: map['preview_audio_url'],
      previewDurationSeconds: map['preview_duration_seconds'],
      category: map['category'] != null ? HiveCategory.fromMap(map['category']) : null,
      song: map['song'] != null ? VestSong.fromMap(map['song']) : null,
    );
  }
}

class HiveCategory {
  final int id;
  final String name;

  HiveCategory({required this.id, required this.name});

  factory HiveCategory.fromMap(Map<String, dynamic> map) {
    return HiveCategory(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
    );
  }
}

class VestSong {
  final int id;
  final String title;
  final String? status;
  final ArtistItem? artist;

  VestSong({required this.id, required this.title, this.status, this.artist});

  factory VestSong.fromMap(Map<String, dynamic> map) {
    return VestSong(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      status: map['status'],
      artist: map['artist'] != null ? ArtistItem.fromMap(map['artist']) : null,
    );
  }
}

class VestMilestone {
  final int id;
  final String title;
  final String? description;
  final String status; // PENDING, IN_PROGRESS, COMPLETED
  final int position;
  final String? completedAt;

  VestMilestone({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.position,
    this.completedAt,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isInProgress => status == 'IN_PROGRESS';

  factory VestMilestone.fromMap(Map<String, dynamic> map) {
    return VestMilestone(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'],
      status: map['status'] ?? 'PENDING',
      position: map['position'] ?? 0,
      completedAt: map['completed_at'],
    );
  }
}

class Link {
  final String? url;
  final String label;
  final bool active;

  Link({this.url, required this.label, required this.active});

  factory Link.fromMap(Map<String, dynamic> map) {
    return Link(
      url: map['url'],
      label: map['label'] ?? '',
      active: map['active'] ?? false,
    );
  }
}