import 'package:flutter/material.dart';
import 'package:soundhive2/model/investment_model.dart';

/// Stage 2 — Portfolio: "why is this artist worth investing in".
///
/// Spec asks for: songs, press, engagement, awards, collaborators, videos.
///
/// Confirmed available today: the single [VestSong] tied to this vest
/// (title + preview audio), via `artistDetails.song`.
///
/// NOT available on the current model/API response:
///   - a real discography list -> Artists::songs() exists on the backend
///     but isn't returned on this endpoint; would need e.g.
///     `artist_details.song.artist.songs` eager-loaded, or a dedicated
///     `GET /artists/{id}/songs` call from this screen
///   - press mentions          -> no table/field anywhere
///   - engagement metrics       -> only lifetime `plays` exists on Songs,
///                                and it isn't exposed on VestSong yet
///   - awards                   -> no table/field anywhere
///   - collaborators             -> `featured_artists` exists per-song on
///                                the Songs model but isn't surfaced on
///                                VestSong; and it's per-song, not an
///                                artist-level "worked with" list
///   - videos                   -> no table/field anywhere
///
/// Each missing section below is a collapsed "coming soon" row rather
/// than invented content.
class PortfolioStage extends StatefulWidget {
  final Investment investment;
  const PortfolioStage({super.key, required this.investment});

  @override
  State<PortfolioStage> createState() => _PortfolioStageState();
}

class _PortfolioStageState extends State<PortfolioStage> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final artistDetails = widget.investment.artistDetails;
    final song = artistDetails?.song;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "The work behind this opportunity.",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (song != null) _buildFeaturedSongCard(song, artistDetails),
          if (song != null) const SizedBox(height: 20),

          _buildComingSoonSection(
            icon: Icons.newspaper_outlined,
            title: 'Press',
            note: 'Press mentions will appear here once available on the artist profile.',
          ),
          const SizedBox(height: 12),
          _buildComingSoonSection(
            icon: Icons.trending_up,
            title: 'Engagement',
            note: 'Play counts and engagement stats will appear here once exposed on this endpoint.',
          ),
          const SizedBox(height: 12),
          _buildComingSoonSection(
            icon: Icons.emoji_events_outlined,
            title: 'Awards',
            note: 'Awards and recognitions will appear here once available.',
          ),
          const SizedBox(height: 12),
          _buildComingSoonSection(
            icon: Icons.group_outlined,
            title: 'Collaborators',
            note: 'Notable collaborators will appear here once surfaced on the vest song.',
          ),
          const SizedBox(height: 12),
          _buildComingSoonSection(
            icon: Icons.play_circle_outline,
            title: 'Videos',
            note: 'Video content will appear here once available.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSongCard(VestSong song, ArtistDetails? artistDetails) {
    final bool hasPreview = artistDetails?.previewAudioUrl != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured track',
            style: TextStyle(color: Colors.purpleAccent.shade100, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasPreview)
                GestureDetector(
                  onTap: () => setState(() => _isPlaying = !_isPlaying),
                  child: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.purpleAccent,
                    size: 44,
                  ),
                )
              else
                const Icon(Icons.music_note, color: Colors.white24, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title.isNotEmpty ? song.title : 'Untitled track',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPreview
                          ? (_isPlaying ? 'Playing preview...' : 'Tap to preview')
                          : 'Preview not available',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonSection({required IconData icon, required String title, required String note}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white24, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(note, style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}