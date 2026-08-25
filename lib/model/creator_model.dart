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
      user: json['creators'] != null
          ? CreatorPaginatedData.fromMap(json['creators'])
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
  final String? referralCode;
  final int? userId; // Changed to int? since JSON shows integer
  final String? gender;
  final String? role; // Made nullable
  final String? nin;
  final String? idType;
  final String? copyOfId;
  final String? utilityBill;
  final String? copyOfUtilityBill;
  final String? jobTitle; // Made nullable
  final String? bio; // Made nullable
  final bool active;
  final bool hasLiveTest;
  final bool hasVerifiedIdentity;
  final bool hasVerifiedCreativeProfile;
  final String? location; // Made nullable
  final String? linkedin;
  final String? x;
  final String? instagram;
  final String? businessName;
  final String? businessPhone;
  final String? businessEmail;
  final String? businessAddress;
  final String? bvn;
  final String? cacDocs;
  final String? videoUrl;
  final String? videoPublicId;
  final bool verified;
  final String? baseCurrency;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final User? user;
  final List<Review> reviews;
  final List<CreatorPortfolioItem> portfolioItems;
  final List<CreatorExperience> experiences;
  final List<CreatorSkill> skills;
  final List<CreatorService> services; // NEW: Added services field
  final String? availabilityResponseTime;
  final String? availabilityStatus;
  final bool isAvailableNow;

  CreatorData({
    required this.id,
    this.referralCode,
    this.userId,
    this.gender,
    this.role,
    this.nin,
    this.idType,
    this.copyOfId,
    this.utilityBill,
    this.copyOfUtilityBill,
    this.jobTitle,
    this.bio,
    required this.active,
    required this.hasLiveTest,
    required this.hasVerifiedIdentity,
    required this.hasVerifiedCreativeProfile,
    this.location,
    this.linkedin,
    this.x,
    this.videoUrl,
    this.videoPublicId,
    this.instagram,
    this.businessName,
    this.businessPhone,
    this.businessEmail,
    this.businessAddress,
    this.bvn,
    this.cacDocs,
    required this.verified,
    this.baseCurrency,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.user,
    this.reviews = const [],
    this.portfolioItems = const [],
    this.experiences = const [],
    this.skills = const [],
    this.services = const [], // Initialize with empty list
    this.availabilityResponseTime,
    this.availabilityStatus,
    this.isAvailableNow = true,
  });

  factory CreatorData.fromJson(Map<String, dynamic> json) {
    return CreatorData(
      id: json['id'] ?? 0,
      referralCode: json['referral_code'],
      userId: json['user_id'] as int?, // Cast to int
      gender: json['gender'],
      role: json['role'],
      nin: json['nin'],
      idType: json['id_type'],
      copyOfId: json['copy_of_id'],
      utilityBill: json['utility_bill'],
      copyOfUtilityBill: json['copy_of_utility_bill'],
      jobTitle: json['job_title'],
      bio: json['bio'],
      active: json['active'] ?? false,
      hasLiveTest: json['has_live_test'] ?? false,
      hasVerifiedIdentity: json['has_verified_identity'] ?? false,
      hasVerifiedCreativeProfile: json['has_verified_creative_profile'] ?? false,
      location: json['location'],
      linkedin: json['linkedin'],
      x: json['x'],
      instagram: json['instagram'],
      businessName: json['business_name'],
      businessPhone: json['business_phone'],
      businessEmail: json['business_email'],
      businessAddress: json['business_address'],
      bvn: json['bvn'],
      cacDocs: json['cac_docs'],
      videoUrl: json['video_url'],
      videoPublicId: json['video_public_id'],
      verified: json['verified'] ?? false,
      baseCurrency: json['base_currency'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      reviews: json['reviews'] != null
          ? List<Review>.from(json['reviews'].map((r) => Review.fromJson(r)))
          : [],
      portfolioItems: json['portfolio_items'] != null
          ? List<CreatorPortfolioItem>.from(
          json['portfolio_items'].map((p) => CreatorPortfolioItem.fromJson(p)))
          : [],
      experiences: json['experiences'] != null
          ? List<CreatorExperience>.from(
          json['experiences'].map((e) => CreatorExperience.fromJson(e)))
          : [],
      skills: json['skills'] != null
          ? List<CreatorSkill>.from(
          json['skills'].map((s) => CreatorSkill.fromJson(s)))
          : [],
      services: json['services'] != null
          ? List<CreatorService>.from(
          json['services'].map((s) => CreatorService.fromJson(s)))
          : [],
      availabilityResponseTime: json['availability_response_time'],
      availabilityStatus: json['availability_status'],
      isAvailableNow: json['is_available_now'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referral_code': referralCode,
      'user_id': userId,
      'gender': gender,
      'role': role,
      'nin': nin,
      'id_type': idType,
      'copy_of_id': copyOfId,
      'utility_bill': utilityBill,
      'copy_of_utility_bill': copyOfUtilityBill,
      'job_title': jobTitle,
      'bio': bio,
      'active': active,
      'has_live_test': hasLiveTest,
      'has_verified_identity': hasVerifiedIdentity,
      'has_verified_creative_profile': hasVerifiedCreativeProfile,
      'location': location,
      'linkedin': linkedin,
      'x': x,
      'instagram': instagram,
      'business_name': businessName,
      'business_phone': businessPhone,
      'business_email': businessEmail,
      'business_address': businessAddress,
      'bvn': bvn,
      'cac_docs': cacDocs,
      'video_url': videoUrl,
      'video_public_id': videoPublicId,
      'verified': verified,
      'base_currency': baseCurrency,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'user': user?.toJson(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'portfolio_items': portfolioItems.map((p) => p.toJson()).toList(),
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'skills': skills.map((s) => s.toJson()).toList(),
      'services': services.map((s) => s.toJson()).toList(),
      'availability_response_time': availabilityResponseTime,
      'availability_status': availabilityStatus,
      'is_available_now': isAvailableNow,
    };
  }
}

// NEW: CreatorService class
class CreatorService {
  final int id;
  final String? userId;
  final String serviceName;
  final String? categoryId;
  final String? subCategoryId;
  final String rate;
  final String? coverImage;
  final String? link;
  final String? serviceImage;
  final String? serviceAudio;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? currency;
  final String? serviceDescription;

  CreatorService({
    required this.id,
    this.userId,
    required this.serviceName,
    this.categoryId,
    this.subCategoryId,
    required this.rate,
    this.coverImage,
    this.link,
    this.serviceImage,
    this.serviceAudio,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.currency,
    this.serviceDescription,
  });

  factory CreatorService.fromJson(Map<String, dynamic> json) {
    return CreatorService(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString(),
      serviceName: json['service_name'] ?? '',
      categoryId: json['category_id']?.toString(),
      subCategoryId: json['sub_category_id']?.toString(),
      rate: json['rate']?.toString() ?? '0',
      coverImage: json['cover_image'],
      link: json['link'],
      serviceImage: json['service_image'],
      serviceAudio: json['service_audio'],
      status: json['status'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      currency: json['currency'],
      serviceDescription: json['service_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_name': serviceName,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'rate': rate,
      'cover_image': coverImage,
      'link': link,
      'service_image': serviceImage,
      'service_audio': serviceAudio,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'currency': currency,
      'service_description': serviceDescription,
    };
  }
}


class Review {
  final int id;
  final String userId;
  final String creatorId;
  final String bookingId;
  final String? type;
  final int rating;
  final String reviewText;
  final bool isApproved;
  final bool isFlagged;
  final String? flaggedReason;
  final String createdAt;
  final String updatedAt;

  final User? user;
  final List<ReviewTag> tags;
  final ReviewMedia? media;

  Review({
    required this.id,
    required this.userId,
    required this.creatorId,
    required this.bookingId,
    this.type,
    required this.rating,
    required this.reviewText,
    required this.isApproved,
    required this.isFlagged,
    this.flaggedReason,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    required this.tags,
    this.media,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      creatorId: json['creator_id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      type: json['type'] ?? '',
      rating: json['rating'] ?? 0,
      reviewText: json['review_text'] ?? '',
      isApproved: json['is_approved'] ?? false,
      isFlagged: json['is_flagged'] ?? false,
      flaggedReason: json['flagged_reason'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      tags: json['tags'] != null
          ? List<ReviewTag>.from(json['tags'].map((t) => ReviewTag.fromJson(t)))
          : [],
      media: json['media'] != null ? ReviewMedia.fromJson(json['media']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'creator_id': creatorId,
      'booking_id': bookingId,
      'type': type,
      'rating': rating,
      'review_text': reviewText,
      'is_approved': isApproved,
      'is_flagged': isFlagged,
      'flagged_reason': flaggedReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user': user,
      'tags': tags.map((t) => t.toJson()).toList(),
      'media': media?.toJson(),
    };
  }
}

class ReviewMedia {
  final int id;
  final String reviewId;
  final String filePath;
  final String fileType;
  final String fileSize;
  final String originalName;
  final String createdAt;
  final String updatedAt;

  ReviewMedia({
    required this.id,
    required this.reviewId,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.originalName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewMedia.fromJson(Map<String, dynamic> json) {
    return ReviewMedia(
      id: json['id'] ?? 0,
      reviewId: json['review_id']?.toString() ?? '',
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] ?? '',
      originalName: json['original_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_id': reviewId,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'original_name': originalName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ReviewTag {
  final int id;
  final String reviewId;
  final String tag;

  ReviewTag({
    required this.id,
    required this.reviewId,
    required this.tag,
  });

  factory ReviewTag.fromJson(Map<String, dynamic> json) {
    return ReviewTag(
      id: json['id'] ?? 0,
      reviewId: json['review_id']?.toString() ?? '',
      tag: json['tag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_id': reviewId,
      'tag': tag,
    };
  }
}

class CreatorPortfolioItem {
  final int id;
  final String type;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final int sortOrder;

  CreatorPortfolioItem({
    required this.id,
    required this.type,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    required this.sortOrder,
  });

  bool get isVideo => type == 'video';

  factory CreatorPortfolioItem.fromJson(Map<String, dynamic> json) {
    return CreatorPortfolioItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'image',
      mediaUrl: json['media_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      caption: json['caption'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'sort_order': sortOrder,
    };
  }
}

class CreatorExperience {
  final int id;
  final String title;
  final String organization;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? description;
  final int sortOrder;

  CreatorExperience({
    required this.id,
    required this.title,
    required this.organization,
    this.startDate,
    this.endDate,
    required this.isCurrent,
    this.description,
    required this.sortOrder,
  });

  factory CreatorExperience.fromJson(Map<String, dynamic> json) {
    return CreatorExperience(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      organization: json['organization'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      isCurrent: json['is_current'] ?? false,
      description: json['description'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organization': organization,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      'description': description,
      'sort_order': sortOrder,
    };
  }
}

class CreatorSkill {
  final int id;
  final String label;
  final int? proficiency;
  final int sortOrder;

  CreatorSkill({
    required this.id,
    required this.label,
    this.proficiency,
    required this.sortOrder,
  });

  factory CreatorSkill.fromJson(Map<String, dynamic> json) {
    return CreatorSkill(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      proficiency: json['proficiency'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'proficiency': proficiency,
      'sort_order': sortOrder,
    };
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
      url: map['url'] ?? '',
      label: map['label'] ?? '',
      active: map['active'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'label': label,
      'active': active,
    };
  }
}