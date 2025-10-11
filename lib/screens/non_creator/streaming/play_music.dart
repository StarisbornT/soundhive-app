import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/getAllSongsProvider.dart';
import 'package:soundhive2/lib/audio_player_provider.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../model/artist_song_model.dart';
import 'artist_profile.dart';

class PlayMusic extends ConsumerStatefulWidget {
  final SongItem song;
  final List<SongItem>? playlist;
  final bool fromMiniPlayer;

  const PlayMusic({
    super.key,
    required this.song,
    this.playlist,
    this.fromMiniPlayer = false,
  });

  @override
  _PlayMusicState createState() => _PlayMusicState();
}


// Just add this simple state provider to track counted plays
final playTrackingProvider = StateProvider<Map<String, bool>>((ref) => {});

class _PlayMusicState extends ConsumerState<PlayMusic> {
  Timer? _playTimer;
  int _listenDuration = 0;
  bool _playCounted = false;
  bool _apiCallMade = false;
  int? _currentSongId;

  @override
  void initState() {
    super.initState();
    _currentSongId = widget.song.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.fromMiniPlayer) {
        // 👇 Only start playback when not coming from mini player
        ref.read(audioPlayerProvider.notifier).playSong(
          widget.song,
          playlist: widget.playlist,
        );
      }
    });


    _startPlayTracking();
  }

  void _startPlayTracking() {
    _playTimer?.cancel();
    _listenDuration = 0;
    _playCounted = false;
    _apiCallMade = false;

    _playTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final audioState = ref.read(audioPlayerProvider);

      if (audioState.isPlaying && audioState.currentSong != null) {
        setState(() {
          _listenDuration++;
        });

        if (_listenDuration == 30 && !_playCounted && !_apiCallMade) {
          _countPlay(audioState.currentSong!);
        }
      }
    });
  }

  void _stopPlayTracking() {
    _playTimer?.cancel();
    _listenDuration = 0;
  }

  void _countPlay(SongItem currentSong) async {
    if (_playCounted || _apiCallMade) return;

    setState(() {
      _apiCallMade = true;
    });

    try {
      await ref.read(apiresponseProvider.notifier).trackPlays(
        context: context,
        songId: currentSong.id,
        payload: {"duration": _listenDuration},
      );

      setState(() {
        _playCounted = true;
      });
      ref.read(getAllSongsProvider.notifier).getAllSongs();
      final currentState = ref.read(playTrackingProvider);
      ref.read(playTrackingProvider.notifier).state = {
        ...currentState,
        currentSong.id.toString(): true
      };

    } catch (e) {
      debugPrint('❌ Error counting play: $e');
    }
  }

  void _toggleShuffle() {
    ref.read(audioPlayerProvider.notifier).toggleShuffle();
  }

  void _togglePlayPause() {
    ref.read(audioPlayerProvider.notifier).togglePlayPause();
  }

  void _playNext() {
    ref.read(audioPlayerProvider.notifier).next();
  }

  void _playPrevious() {
    ref.read(audioPlayerProvider.notifier).previous();
  }

  @override
  void dispose() {
    _stopPlayTracking();
    super.dispose();
  }

  void showSongOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.BACKGROUNDCOLOR, // same dark tone
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Close button at top right ---
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 10),

              // --- Menu items ---
              _buildOption(
                icon: Icons.playlist_add,
                label: "Add to playlist",
                onTap: () {
                  Navigator.pop(context);
                  // handle add to playlist
                },
              ),
              _buildOption(
                icon: Icons.person_outline,
                label: "Check artist profile",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtistProfile(
                        artistId: int.parse(widget.song.artistId),
                      ),
                    ),
                  );
                },
              ),
              _buildOption(
                icon: Icons.work_outline,
                label: "Book artist",
                onTap: () {
                  Navigator.pop(context);
                  // handle book artist
                },
              ),
              _buildOption(
                icon: Icons.mic_none_outlined,
                label: "Play karaoke",
                onTap: () {
                  Navigator.pop(context);
                  // handle karaoke mode
                },
              ),
              _buildOption(
                icon: Icons.share_outlined,
                label: "Share song",
                onTap: () {
                  Navigator.pop(context);
                  // handle share
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerProvider);
    final playTrackingState = ref.watch(playTrackingProvider);

    final currentSong = audioState.currentSong ?? widget.song;
    final isPlayCounted = _playCounted || (playTrackingState[currentSong.id.toString()] ?? false);

    // Reset tracking when song changes
    if (_currentSongId != currentSong.id) {
      debugPrint("🔄 Song changed from $_currentSongId to ${currentSong.id}");
      _currentSongId = currentSong.id;
      _stopPlayTracking();
      _playCounted = false;
      _apiCallMade = false;
      _listenDuration = 0;
      _startPlayTracking();
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFF050110),
              Color(0xFF6D81F1),
            ],
            stops: [-0.15, 0.56],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- Top Bar ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      "Playing",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPlayCounted ? 'Play Counted' : 'Listening...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // --- Album Art ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: currentSong.coverPhoto.isNotEmpty
                      ? Image.network(
                    currentSong.coverPhoto,
                    height: 340,
                    width: 340,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 340,
                        width: 340,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white, size: 60),
                      );
                    },
                  )
                      : Container(
                    height: 340,
                    width: 340,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 60),
                  ),
                ),

                const SizedBox(height: 35),

                // --- Song Info ---
                Text(
                  currentSong.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  currentSong.artist?.userName ?? 'Unknown Artist',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                // --- Progress Bar ---
                StreamBuilder<DurationState>(
                  stream: _durationStateStream(audioState.player),
                  builder: (context, snapshot) {
                    final durationState = snapshot.data;
                    final progress = durationState?.position ?? Duration.zero;
                    final buffered = durationState?.buffered ?? Duration.zero;
                    final total = durationState?.total ?? Duration.zero;

                    return ProgressBar(
                      progress: progress,
                      buffered: buffered,
                      total: total,
                      onSeek: (position) {
                        ref.read(audioPlayerProvider.notifier).seek(position);
                      },
                      progressBarColor: Colors.white,
                      baseBarColor: Colors.white38,
                      bufferedBarColor: Colors.white54,
                      thumbColor: Colors.white,
                      timeLabelTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // --- Player Controls ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle Button
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: audioState.isShuffled ? Colors.white : Colors.white70,
                        size: 28,
                      ),
                      onPressed: _toggleShuffle,
                    ),

                    // Previous Button
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                      onPressed: audioState.playlist != null && audioState.playlist!.length > 1
                          ? _playPrevious : null,
                    ),

                    // Play/Pause Button
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Icon(
                          audioState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 36,
                          color: const Color(0xFF6D81F1),
                        ),
                      ),
                    ),

                    // Next Button
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                      onPressed: audioState.playlist != null && audioState.playlist!.length > 1
                          ? _playNext : null,
                    ),
                    IconButton(
                        onPressed: () => showSongOptionsBottomSheet(context),
                        icon: const Icon(Icons.more_vert, color: Colors.white70, size: 28)
                    )
                    ,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Stream to combine position + duration ---
  Stream<DurationState> _durationStateStream(AudioPlayer player) {
    return Rx.combineLatest3<Duration, Duration, Duration?, DurationState>(
      player.positionStream,
      player.bufferedPositionStream,
      player.durationStream,
          (position, buffered, total) => DurationState(
        position: position,
        buffered: buffered,
        total: total ?? Duration.zero,
      ),
    );
  }
}

// --- Duration state model for progress bar ---
class DurationState {
  const DurationState({
    required this.position,
    required this.buffered,
    required this.total,
  });

  final Duration position;
  final Duration buffered;
  final Duration total;
}

