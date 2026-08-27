import 'package:flutter/material.dart';
import 'package:soundhive2/model/investment_model.dart';

import '../../../model/artists_model.dart';

/// Stage 2 — Portfolio: "why is this artist worth investing in".
///
/// Spec asks for: songs, press, engagement, awards, collaborators, videos.
///
/// Now available and rendered with real data:
///   - discography  -> artist.songs, eager-loaded via
///                     artistDetails.song.artist.songs on the vest
///                     endpoints; placeholder/demo rows are filtered out
///                     client-side (see ArtistItem.publishedDiscography)
///   - collaborators -> derived from featured_artists across the real
///                     discography (ArtistItem.collaborators) — this is
///                     an artist-level aggregate now, not per-song
///
/// Still genuinely unavailable — no table, no ingestion path anywhere in
/// the app for any of these, so these stay as a clear "not yet" notice
/// rather than fabricated content:
///   - press mentions
///   - engagement metrics beyond monthly listeners (which now lives on
///     the Overview stage) — no per-song breakdown exists
///   - awards
///   - videos
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
    final artist = artistDetails?.artist;
    final discography = artist?.publishedDiscography ?? [];
    final collaborators = artist?.collaborators ?? [];

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

          if (discography.isNotEmpty) ...[
            _buildDiscographySection(discography),
            const SizedBox(height: 20),
          ],

          if (collaborators.isNotEmpty) ...[
            _buildCollaboratorsSection(collaborators),
            const SizedBox(height: 20),
          ],

          // _buildComingSoonSection(
          //   icon: Icons.newspaper_outlined,
          //   title: 'Press',
          //   note: 'Press mentions will appear here once available on the artist profile.',
          // ),
          // const SizedBox(height: 12),
          // _buildComingSoonSection(
          //   icon: Icons.emoji_events_outlined,
          //   title: 'Awards',
          //   note: 'Awards and recognitions will appear here once available.',
          // ),
          // const SizedBox(height: 12),
          // _buildComingSoonSection(
          //   icon: Icons.play_circle_outline,
          //   title: 'Videos',
          //   note: 'Video content will appear here once available.',
          // ),
        ],
      ),
    );
  }

  Widget _buildDiscographySection(List<ArtistSong> songs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discography · ${songs.length} track${songs.length == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...songs.map((s) => _buildDiscographyRow(s)),
      ],
    );
  }

  Widget _buildDiscographyRow(ArtistSong song) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: song.coverPhoto.isNotEmpty
                  ? Image.network(
                song.coverPhoto,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[850]),
              )
                  : Container(color: Colors.grey[850]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              song.title,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorsSection(List<String> collaborators) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Collaborators',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: collaborators
              .map((name) => Chip(
            label: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            side: BorderSide.none,
          ))
              .toList(),
        ),
      ],
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