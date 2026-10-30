import 'dart:convert';

import '../utils/json_parse.dart';
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
      currentPage: asInt(map['current_page'], 1),
      data: List<Investment>.from(
        (map['data'] ?? []).map((x) => Investment.fromMap(x)),
      ),
      firstPageUrl: asStringOrNull(map['first_page_url']),
      from: asInt(map['from']),
      lastPage: asInt(map['last_page']),
      lastPageUrl: asStringOrNull(map['last_page_url']),
      links: List<Link>.from(
        (map['links'] ?? []).map((x) => Link.fromMap(x)),
      ),
      nextPageUrl: asStringOrNull(map['next_page_url']),
      path: asString(map['path']),
      perPage: asInt(map['per_page']),
      prevPageUrl: asStringOrNull(map['prev_page_url']),
      to: asInt(map['to']),
      total: asInt(map['total']),
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
  /// Always 'NGN' — vest amounts are stored and served in Naira.
  final String currency;
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
    this.currency = 'NGN',
    this.artistDetails,
    this.milestones = const [],
  });

  bool get isArtistVest => type.toUpperCase() == 'ARTIST';

  /// Minimum ticket size in Naira, as a number.
  double get minimumAmountValue => asDouble(minimumAmount);

  /// Investor's share of revenue, e.g. 10.0 for 10%.
  double get roiValue => asDouble(roi);

  /// Duration in months as a number (payback period for artist vests).
  int get durationMonths => asInt(duration);

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: asInt(map['id']),
      vestFor: asString(map['vest_for']),
      beneficiaryName: asString(map['beneficiary_name']),
      investmentName: asString(map['investment_name']),
      minimumAmount: asString(map['minimum_amount'], '0'),
      roi: asString(map['roi']),
      duration: asString(map['duration']),
      description: asString(map['description']),
      images: asStringList(map['images']),
      riskAssessment: asString(map['risk_assessment']),
      news: asStringList(map['news']),
      status: asString(map['status']),
      type: asString(map['type'], 'GENERAL'),
      createdAt: asString(map['created_at']),
      updatedAt: asString(map['updated_at']),
      convertedMinimumAmount: map['converted_minimum_amount'] ?? map['minimum_amount'] ?? '0',
      currency: asString(map['currency'], 'NGN'),
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
  /// Months until the investor's capital is fully recovered (e.g. 12).
  final int? paybackPeriodMonths;
  /// How long the investor return runs, e.g. "In perpetuity".
  final String? returnTimeline;
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
    this.paybackPeriodMonths,
    this.returnTimeline,
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

  bool get hasPaybackPeriod => (paybackPeriodMonths ?? 0) > 0;

  bool get isPerpetual =>
      (returnTimeline ?? '').toLowerCase().contains('perpetu');

  /// "12 Months" / "1 Month"
  String get paybackLabel {
    final m = paybackPeriodMonths ?? 0;
    return '$m ${m == 1 ? 'Month' : 'Months'}';
  }

  /// "500%" when min == max, otherwise "300–500%".
  String get forecastedReturnLabel {
    final min = targetRoiMin.toStringAsFixed(0);
    final max = targetRoiMax.toStringAsFixed(0);
    return targetRoiMin == targetRoiMax ? '$max%' : '$min–$max%';
  }

  factory ArtistDetails.fromMap(Map<String, dynamic> map) {
    return ArtistDetails(
      id: asInt(map['id']),
      categoryId: asInt(map['category_id']),
      projectStage: asString(map['project_stage']),
      projectType: asString(map['project_type']),
      fundingTarget: asDouble(map['funding_target']),
      totalRaised: asDouble(map['total_raised']),
      fundingProgressPercentage: map['funding_progress_percentage'] != null
          ? asDouble(map['funding_progress_percentage'])
          // Fallback if the backend doesn't append it.
          : (asDouble(map['funding_target']) > 0
              ? asDouble(map['total_raised']) / asDouble(map['funding_target']) * 100
              : 0.0),
      targetRoiMin: asDouble(map['target_roi_min']),
      targetRoiMax: asDouble(map['target_roi_max']),
      revenueSplitArtist: asDouble(map['revenue_split_artist']),
      revenueSplitInvestor: asDouble(map['revenue_split_investor']),
      riskLevel: asString(map['risk_level'], 'HIGH'),
      revenueStreamTags: asStringList(map['revenue_stream_tags']),
      paybackPeriodMonths: asIntOrNull(map['payback_period_months']),
      returnTimeline: asStringOrNull(map['return_timeline']),
      previewAudioUrl: asStringOrNull(map['preview_audio_url']),
      previewDurationSeconds: asIntOrNull(map['preview_duration_seconds']),
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
      id: asInt(map['id']),
      name: asString(map['name']),
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
      id: asInt(map['id']),
      title: asString(map['title']),
      status: asStringOrNull(map['status']),
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
      id: asInt(map['id']),
      title: asString(map['title']),
      description: asStringOrNull(map['description']),
      status: asString(map['status'], 'PENDING'),
      position: asInt(map['position']),
      completedAt: asStringOrNull(map['completed_at']),
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
      url: asStringOrNull(map['url']),
      label: asString(map['label']),
      active: asBool(map['active']),
    );
  }
}