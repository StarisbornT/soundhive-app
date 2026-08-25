// creator_profile_widgets.dart
//
// Shared, presentation-only widgets used by both the rebuilt Creator
// Profile screen and the Service Detail page (see section 6.1 of the
// Portfolio Overhaul spec — the same creator credibility block needs to
// show up in both places).
//
//   - TrustBadgeRow      "Vetted Pro" / "Top Rated" chips
//   - RatingBreakdown    multi-category rating bars + overall score
//   - PortfolioGrid      grid with "See all" + "+N more" overflow tile
//   - ExperienceTimeline vertical timeline for the Experience tab
//   - SkillChips         wrap of skill tags for the Skills tab
//   - AvailabilityCard   response-time / availability summary
//   - CreatorTrustBlock  compact badges + portfolio strip for Service Detail

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../model/creator_profile_models.dart';

class TrustBadgeRow extends StatelessWidget {
  final List<TrustBadge> badges;
  const TrustBadgeRow({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges
          .map(
            (b) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.BUTTONCOLOR.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.BUTTONCOLOR.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(b.icon, size: 14, color: AppColors.BUTTONCOLOR),
              const SizedBox(width: 4),
              Text(
                b.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.BUTTONCOLOR,
                ),
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}

/// Star-by-star rating breakdown (5★ / 4★ / 3★ / 2★ / 1★), built from the
/// creator's actual review ratings — replaces a single blended star
/// average with a real distribution instead of an invented per-category
/// score, since Review only has one `rating` field.
class RatingBreakdown extends StatelessWidget {
  final RatingDistribution distribution;
  final bool compact;

  const RatingBreakdown({
    super.key,
    required this.distribution,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (distribution.totalReviews == 0) {
      return Text(
        'No ratings yet',
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                distribution.average.toStringAsFixed(1),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '(${distribution.totalReviews} ${distribution.totalReviews == 1 ? 'review' : 'reviews'})',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        for (var star = 5; star >= 1; star--)
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 4 : 8),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '$star ★',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: distribution.fractionFor(star),
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(AppColors.BUTTONCOLOR),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${distribution.counts[star] ?? 0}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Portfolio grid with a "See all" link and a "+N more" overflow tile on
/// the last visible cell when there are more items than fit on screen.
class PortfolioGrid extends StatelessWidget {
  final List<PortfolioItem> items;
  final int previewCount;
  final int crossAxisCount;
  final bool showHeader;
  final VoidCallback? onSeeAll;
  final ValueChanged<PortfolioItem>? onItemTap;

  const PortfolioGrid({
    super.key,
    required this.items,
    this.previewCount = 6,
    this.crossAxisCount = 3,
    this.showHeader = true,
    this.onSeeAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Text(
        'No portfolio items yet',
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      );
    }

    final visible = items.take(previewCount).toList();
    final overflowCount = items.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portfolio',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (onSeeAll != null)
                  InkWell(
                    onTap: onSeeAll,
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.BUTTONCOLOR,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = visible[index];
            final isLastTile = index == visible.length - 1;
            final showOverflow = isLastTile && overflowCount > 0;

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: showOverflow ? onSeeAll : () => onItemTap?.call(item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(item.thumbnailUrl, fit: BoxFit.cover),
                    if (item.isVideo && !showOverflow)
                      const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                      ),
                    if (showOverflow)
                      Container(
                        color: Colors.black.withOpacity(0.55),
                        alignment: Alignment.center,
                        child: Text(
                          '+$overflowCount more',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Simple vertical timeline for the Experience tab.
class ExperienceTimeline extends StatelessWidget {
  final List<ExperienceEntry> entries;
  const ExperienceTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Text(
        'No experience listed yet',
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.BUTTONCOLOR,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.organization} · ${e.period}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                    if (e.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        e.description!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Wrap of skill tags for the Skills tab.
class SkillChips extends StatelessWidget {
  final List<SkillTag> skills;
  const SkillChips({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (skills.isEmpty) {
      return Text(
        'No skills listed yet',
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map(
            (s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            s.label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}

/// Compact availability / response-time card, used on Overview and
/// (optionally) on the Service Detail trust block.
class AvailabilityCard extends StatelessWidget {
  final AvailabilityInfo info;
  const AvailabilityCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            info.isAvailableNow ? Icons.check_circle : Icons.schedule,
            color: info.isAvailableNow ? Colors.greenAccent : Colors.orangeAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.status,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.responseTime,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact "creator credibility" block for the Service Detail page —
/// trust badges + a short portfolio strip + a link to the full profile.
/// Meant to sit right before the Book / Offer buttons (spec 6.1).
class CreatorTrustBlock extends StatelessWidget {
  final String creatorName;
  final String? creatorImage;
  final List<TrustBadge> badges;
  final List<PortfolioItem> portfolioPreview;
  final RatingDistribution? ratingDistribution;
  final VoidCallback onViewProfile;

  const CreatorTrustBlock({
    super.key,
    required this.creatorName,
    required this.onViewProfile,
    this.creatorImage,
    this.badges = const [],
    this.portfolioPreview = const [],
    this.ratingDistribution,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.BUTTONCOLOR.withOpacity(0.6),
                backgroundImage: creatorImage != null ? NetworkImage(creatorImage!) : null,
                child: creatorImage == null
                    ? Text(
                  creatorName.isNotEmpty ? creatorName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorName,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ratingDistribution != null && ratingDistribution!.totalReviews > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${ratingDistribution!.average.toStringAsFixed(1)} '
                                '(${ratingDistribution!.totalReviews})',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewProfile,
                child: const Text(
                  'View profile',
                  style: TextStyle(color: AppColors.BUTTONCOLOR, fontSize: 12),
                ),
              ),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            TrustBadgeRow(badges: badges),
          ],
          if (portfolioPreview.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: portfolioPreview.length.clamp(0, 6),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = portfolioPreview[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.thumbnailUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}