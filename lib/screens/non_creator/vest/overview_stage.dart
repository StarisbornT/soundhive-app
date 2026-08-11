import 'package:flutter/material.dart';
import 'package:soundhive2/model/investment_model.dart';

import '../../../model/artists_model.dart';

/// Stage 1 — Overview.
///
/// Spec asks for: profile picture, verified badge, genre, short bio,
/// monthly listeners, followers.
///
/// Confirmed available today on [ArtistItem]: profilePhoto, coverPhoto,
/// username, status.
///
/// NOT available on the current model/API response — rendered
/// conditionally so nothing fabricated ever reaches the user:
///   - genre            -> needs a field on artists (or a shared taxonomy)
///   - bio               -> needs a text column on artists
///   - monthly listeners -> needs a time-windowed play metric; only a
///                          lifetime `plays` figure exists today, and it's
///                          not even exposed on ArtistItem yet
///   - followers          -> exists on the Artists backend model but is
///                          NOT present on the ArtistItem model as given;
///                          add it to ArtistItem.fromMap once confirmed
///
/// `status` is rendered as a verified badge — this is an ASSUMPTION
/// pending confirmation (see conversation), not a confirmed mapping.
class OverviewStage extends StatelessWidget {
  final Investment investment;
  const OverviewStage({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final ArtistItem? artist = investment.artistDetails?.artist;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverAndAvatar(artist),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: Text(
                  artist?.username.isNotEmpty == true
                      ? artist!.username
                      : investment.beneficiaryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (artist?.status == true) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: Colors.purpleAccent, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            investment.investmentName,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Genre / bio / monthly listeners / followers all render only
          // when present so the card never shows fabricated placeholders.
          _buildComingSoonNotice(),

          const SizedBox(height: 24),
          const Text(
            'Why this stage matters',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "You're about to learn about the artist behind this opportunity before any numbers come into play. "
                "Swipe through their story, then their portfolio, then the project itself — the investment details come last.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverAndAvatar(ArtistItem? artist) {
    final bool hasCover = artist?.coverPhoto.isNotEmpty == true;
    final bool hasAvatar = artist?.profilePhoto.isNotEmpty == true;

    return SizedBox(
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: double.infinity,
              height: 130,
              child: hasCover
                  ? Image.network(
                artist!.coverPhoto,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
              )
                  : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.35),
                      const Color(0xFF1A102F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 16,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0C051F), width: 3),
                color: Colors.grey[800],
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                  artist!.profilePhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, color: Colors.white54, size: 32),
                )
                    : const Icon(Icons.person, color: Colors.white54, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white38, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Genre, bio, monthly listeners and followers will appear here once the artist profile API includes them.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}