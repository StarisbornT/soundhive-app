import 'package:flutter/material.dart';
import 'package:soundhive2/model/investment_model.dart';

import '../../../model/artists_model.dart';
import 'mixtape_coming_soon_screen.dart';

/// Stage 1 — Overview.
///
/// Spec asks for: profile picture, verified badge, genre, short bio,
/// monthly listeners, followers.
///
///
/// All six now come from the API: profilePhoto/coverPhoto/username/status
/// were already there; genre, bio, followers and monthlyListeners were
/// added to `ArtistItem` alongside the `artists.genre`/`artists.bio`
/// migration and the `Artists::monthly_listeners` accessor. `followers`
/// is rendered but flagged in artists_model.dart as an unconfirmed
/// column — double check it before shipping if that hasn't happened yet.
///
/// `status` is still rendered as a verified badge — this was already an
/// ASSUMPTION pending confirmation before this change and remains one;
/// not something this pass resolved.
///
/// "Listen to snippets / Artist mixtape" button: song upload + snippet
/// playback has no backend support yet (phase two). Rather than hide the
/// entry point, tapping it opens [MixtapeComingSoonScreen] so users know
/// the feature is on the way instead of the button doing nothing.
class OverviewStage extends StatelessWidget {
  final Investment investment;
  const OverviewStage({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final ArtistItem? artist = investment.artistDetails?.artist;
    final String displayName = artist?.username.isNotEmpty == true
        ? artist!.username
        : investment.beneficiaryName;

    final bool hasGenre = artist?.genre?.trim().isNotEmpty == true;
    final bool hasBio = artist?.bio?.trim().isNotEmpty == true;

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
                  displayName,
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
          if (hasGenre) ...[
            Text(
              artist!.genre!,
              style: const TextStyle(
                color: Colors.purpleAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            investment.investmentName,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),

          _buildStatsRow(artist),
          const SizedBox(height: 20),

          if (hasBio) ...[
            _buildBioSection(artist!.bio!),
            const SizedBox(height: 20),
          ],

          _buildMixtapeButton(context, displayName),
          const SizedBox(height: 20),

          const SizedBox(height: 4),
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

  Widget _buildStatsRow(ArtistItem? artist) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBlock(
            label: 'Followers',
            value: _formatCount(artist?.followers ?? 0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBlock(
            label: 'Monthly listeners',
            value: _formatCount(artist?.monthlyListeners ?? 0),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBlock({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  Widget _buildBioSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          bio,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildMixtapeButton(BuildContext context, String displayName) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MixtapeComingSoonScreen(artistName: displayName),
            ),
          );
        },
        icon: const Icon(Icons.headphones_rounded, color: Colors.purpleAccent, size: 18),
        label: const Text(
          'Listen to snippets · Artist mixtape',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Colors.white.withValues(alpha: 0.03),
        ),
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
                      Colors.purple.withValues(alpha: 0.35),
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
}