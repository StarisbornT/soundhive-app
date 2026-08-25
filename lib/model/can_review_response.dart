// model/can_review_response.dart
class CanReviewResponse {
  final bool success;
  final bool canReview;
  final bool hasReviewed;
  final String? reviewType; // "creative_service" | "general_user"
  final String? revieweeId;
  final List<String> allowedTags;
  final String? message;

  CanReviewResponse({
    required this.success,
    required this.canReview,
    required this.hasReviewed,
    this.reviewType,
    this.revieweeId,
    this.allowedTags = const [],
    this.message,
  });

  factory CanReviewResponse.fromJson(Map<String, dynamic> json) {
    return CanReviewResponse(
      success: json['success'] ?? false,
      canReview: json['can_review'] ?? false,
      hasReviewed: json['has_reviewed'] ?? false,
      reviewType: json['review_type'],
      revieweeId: json['reviewee_id']?.toString(),
      allowedTags: (json['allowed_tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
      message: json['message'],
    );
  }

  bool get isGeneralUserReview => reviewType == 'general_user';
  bool get isCreativeServiceReview => reviewType == 'creative_service';
}