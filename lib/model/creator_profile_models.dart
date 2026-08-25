// creator_profile_models.dart
//
// Supporting models + helpers for the rebuilt Creator Profile & Service
// Detail portfolio/trust-badge surfaces.
//
// Now properly mapping the real fields from CreatorData:
// - portfolioItems -> PortfolioItem
// - experiences -> ExperienceEntry
// - skills -> SkillTag
// - availability fields -> AvailabilityInfo

import 'package:flutter/material.dart';
import '../../model/creator_model.dart';

/// A single piece of portfolio media (image or video thumbnail).
class PortfolioItem {
  final int id;
  final String thumbnailUrl;
  final String? fullUrl;
  final bool isVideo;
  final String? caption;

  const PortfolioItem({
    required this.id,
    required this.thumbnailUrl,
    this.fullUrl,
    this.isVideo = false,
    this.caption,
  });

  /// Factory to create from CreatorPortfolioItem
  factory PortfolioItem.fromCreatorPortfolioItem(CreatorPortfolioItem item) {
    return PortfolioItem(
      id: item.id,
      thumbnailUrl: item.mediaUrl,
      fullUrl: item.mediaUrl,
      isVideo: item.type == 'video',
      caption: item.caption,
    );
  }
}

/// Star-by-star breakdown (5★ / 4★ / 3★ / 2★ / 1★) built from the
/// creator's actual `Review.rating` values — no invented categories.
class RatingDistribution {
  /// star (1-5) -> number of reviews with that rating
  final Map<int, int> counts;
  final int totalReviews;
  final double average;

  const RatingDistribution({
    required this.counts,
    required this.totalReviews,
    required this.average,
  });

  factory RatingDistribution.fromReviews(List<Review> reviews) {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    var sum = 0;
    for (final r in reviews) {
      final star = r.rating.clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
      sum += r.rating;
    }
    final total = reviews.length;
    return RatingDistribution(
      counts: counts,
      totalReviews: total,
      average: total == 0 ? 0 : sum / total,
    );
  }

  /// Fraction (0.0-1.0) of reviews that gave this star rating — used to
  /// size the distribution bars.
  double fractionFor(int star) {
    if (totalReviews == 0) return 0;
    return (counts[star] ?? 0) / totalReviews;
  }
}

/// A single line item in the Experience tab.
class ExperienceEntry {
  final int id;
  final String title;
  final String organization;
  final String period;
  final String? description;
  final bool isCurrent;
  final int sortOrder;

  const ExperienceEntry({
    required this.id,
    required this.title,
    required this.organization,
    required this.period,
    this.description,
    required this.isCurrent,
    required this.sortOrder,
  });

  /// Factory to create from CreatorExperience
  factory ExperienceEntry.fromCreatorExperience(CreatorExperience exp) {
    // Format the period string
    String period = '';
    if (exp.startDate != null) {
      period = _formatDate(exp.startDate!);
    }
    if (exp.isCurrent) {
      period += ' - Present';
    } else if (exp.endDate != null) {
      period += ' - ${_formatDate(exp.endDate!)}';
    }

    return ExperienceEntry(
      id: exp.id,
      title: exp.title,
      organization: exp.organization,
      period: period,
      description: exp.description,
      isCurrent: exp.isCurrent,
      sortOrder: exp.sortOrder,
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// A skill / area-of-expertise tag for the Skills tab.
class SkillTag {
  final int id;
  final String label;
  final int sortOrder;

  const SkillTag({
    required this.id,
    required this.label,
    required this.sortOrder,
  });

  /// Factory to create from CreatorSkill
  factory SkillTag.fromCreatorSkill(CreatorSkill skill) {
    return SkillTag(
      id: skill.id,
      label: skill.label,
      sortOrder: skill.sortOrder,
    );
  }
}

/// A credibility badge shown next to the creator's name.
class TrustBadge {
  final String label;
  final IconData icon;

  const TrustBadge({required this.label, required this.icon});
}

/// Availability & responsiveness summary.
class AvailabilityInfo {
  final String responseTime;
  final String status;
  final bool isAvailableNow;

  const AvailabilityInfo({
    required this.responseTime,
    required this.status,
    this.isAvailableNow = true,
  });

  /// Factory to create from CreatorData
  factory AvailabilityInfo.fromCreator(CreatorData creator) {
    return AvailabilityInfo(
      responseTime: creator.availabilityResponseTime ?? 'N/A',
      status: creator.availabilityStatus ?? 'Not specified',
      isAvailableNow: creator.isAvailableNow,
    );
  }
}

/// Bundles everything the new Portfolio UI needs, decoupled from wherever
/// the data actually comes from. Build this once per screen and pass it
/// down to the shared widgets in creator_profile_widgets.dart.
class CreatorProfileExtras {
  final List<PortfolioItem> portfolio;
  final RatingDistribution ratingDistribution;
  final List<ExperienceEntry> experience;
  final List<SkillTag> skills;
  final List<TrustBadge> trustBadges;
  final AvailabilityInfo? availability;

  const CreatorProfileExtras({
    this.portfolio = const [],
    required this.ratingDistribution,
    this.experience = const [],
    this.skills = const [],
    this.trustBadges = const [],
    this.availability,
  });

  factory CreatorProfileExtras.fromCreator(CreatorData creator) {
    // Map portfolio items
    final List<PortfolioItem> portfolioItems = creator.portfolioItems
        .map((item) => PortfolioItem.fromCreatorPortfolioItem(item))
        .toList();

    // Map experiences
    final List<ExperienceEntry> experienceEntries = creator.experiences
        .map((exp) => ExperienceEntry.fromCreatorExperience(exp))
        .toList();

    // Map skills
    final List<SkillTag> skillTags = creator.skills
        .map((skill) => SkillTag.fromCreatorSkill(skill))
        .toList();

    // Create availability info if any data exists
    AvailabilityInfo? availabilityInfo;
    if (creator.availabilityResponseTime != null ||
        creator.availabilityStatus != null) {
      availabilityInfo = AvailabilityInfo.fromCreator(creator);
    }

    return CreatorProfileExtras(
      portfolio: portfolioItems,
      ratingDistribution: RatingDistribution.fromReviews(creator.reviews),
      experience: experienceEntries,
      skills: skillTags,
      trustBadges: _deriveBadges(creator),
      availability: availabilityInfo,
    );
  }

  /// Built from the real verification flags on CreatorData — no guessing.
  static List<TrustBadge> _deriveBadges(CreatorData creator) {
    final badges = <TrustBadge>[];
    if (creator.verified) {
      badges.add(const TrustBadge(label: 'Verified', icon: Icons.verified));
    }
    if (creator.hasVerifiedIdentity) {
      badges.add(const TrustBadge(label: 'ID Verified', icon: Icons.badge));
    }
    if (creator.hasVerifiedCreativeProfile) {
      badges.add(const TrustBadge(label: 'Vetted Pro', icon: Icons.workspace_premium));
    }
    if (creator.hasLiveTest) {
      badges.add(const TrustBadge(label: 'Skill Tested', icon: Icons.check_circle));
    }
    return badges;
  }
}