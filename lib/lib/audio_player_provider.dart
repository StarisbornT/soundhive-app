// providers/audio_player_provider.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../model/artist_song_model.dart';

final audioPlayerProvider = StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});

class AudioPlayerState {
  final AudioPlayer player;
  final SongItem? currentSong;
  final List<SongItem>? playlist;
  final List<SongItem>? originalPlaylist; // Store original order
  final bool isPlaying;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool isShuffled;

  AudioPlayerState({
    required this.player,
    this.currentSong,
    this.playlist,
    this.originalPlaylist,
    this.isPlaying = false,
    this.currentIndex = 0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffled = false,
  });

  AudioPlayerState copyWith({
    AudioPlayer? player,
    SongItem? currentSong,
    List<SongItem>? playlist,
    List<SongItem>? originalPlaylist,
    bool? isPlaying,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? isShuffled,
  }) {
    return AudioPlayerState(
      player: player ?? this.player,
      currentSong: currentSong ?? this.currentSong,
      playlist: playlist ?? this.playlist,
      originalPlaylist: originalPlaylist ?? this.originalPlaylist,
      isPlaying: isPlaying ?? this.isPlaying,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffled: isShuffled ?? this.isShuffled,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  AudioPlayerNotifier() : super(AudioPlayerState(player: AudioPlayer())) {
    _setupListeners();
  }

  void _setupListeners() {
    state.player.playerStateStream.listen((playerState) {
      // Only update if the state is actually different to avoid unnecessary rebuilds
      if (state.isPlaying != playerState.playing) {
        state = state.copyWith(
          isPlaying: playerState.playing,
        );
      }
    });

    state.player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    state.player.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });

    // Listen for song completion
    state.player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _playNext();
          }
        });
      }
    });
  }

  Future<void> playSong(SongItem song, {List<SongItem>? playlist}) async {
    try {
      await state.player.stop();
      await state.player.setUrl(song.songAudio);
      await state.player.play();

      final currentPlaylist = playlist ?? [song];
      final currentIndex = currentPlaylist.indexWhere((s) => s.id == song.id);

      state = AudioPlayerState(
        player: state.player,
        currentSong: song,
        playlist: currentPlaylist,
        originalPlaylist: List.from(currentPlaylist),
        currentIndex: currentIndex >= 0 ? currentIndex : 0,
        isPlaying: true,
        position: Duration.zero,
        duration: Duration.zero,
        isShuffled: false,
      );

      debugPrint("🎵 Started playing: ${song.title}");
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (state.isPlaying) {
        await state.player.pause();
        // Don't update state here - let the playerStateStream handle it
      } else {
        await state.player.play();
        // Don't update state here - let the playerStateStream handle it
      }
    } catch (e) {
      debugPrint("Error in togglePlayPause: $e");
    }
  }

  Future<void> _playNext() async {
    if (state.playlist == null || state.playlist!.length <= 1) return;

    int nextIndex;
    if (state.isShuffled) {
      do {
        nextIndex = DateTime.now().microsecondsSinceEpoch % state.playlist!.length;
      } while (nextIndex == state.currentIndex && state.playlist!.length > 1);
    } else {
      nextIndex = (state.currentIndex + 1) % state.playlist!.length;
    }

    await _loadSongByIndex(nextIndex);
  }

  Future<void> _playPrevious() async {
    if (state.playlist == null || state.playlist!.length <= 1) return;

    int previousIndex;
    if (state.isShuffled) {
      do {
        previousIndex = DateTime.now().microsecondsSinceEpoch % state.playlist!.length;
      } while (previousIndex == state.currentIndex && state.playlist!.length > 1);
    } else {
      previousIndex = (state.currentIndex - 1) % state.playlist!.length;
      if (previousIndex < 0) previousIndex = state.playlist!.length - 1;
    }

    await _loadSongByIndex(previousIndex);
  }

  Future<void> _loadSongByIndex(int index) async {
    if (state.playlist == null || index < 0 || index >= state.playlist!.length) return;

    try {
      final newSong = state.playlist![index];

      debugPrint("🔄 Loading new song: ${newSong.title} at index: $index");

      // Completely stop and reset the player
      await state.player.stop();
      await state.player.setUrl(newSong.songAudio);

      // Create a new state with isPlaying set to true since we're about to play
      state = AudioPlayerState(
        player: state.player,
        currentSong: newSong,
        playlist: state.playlist,
        originalPlaylist: state.originalPlaylist,
        currentIndex: index,
        isPlaying: true, // Set to true since we're about to play
        position: Duration.zero,
        duration: Duration.zero,
        isShuffled: state.isShuffled,
      );

      // Now play the song
      await state.player.play();

      debugPrint("✅ Now playing: ${newSong.title}");

    } catch (e) {
      debugPrint("❌ Error loading song by index: $e");
      // If there's an error, set isPlaying to false
      state = state.copyWith(isPlaying: false);
    }
  }

  void toggleShuffle() {
    if (state.playlist == null || state.playlist!.length <= 1) return;

    if (!state.isShuffled) {
      final currentSong = state.currentSong;
      final tempList = List<SongItem>.from(state.playlist!)..removeAt(state.currentIndex);
      tempList.shuffle();
      tempList.insert(state.currentIndex, currentSong!);

      state = state.copyWith(
        playlist: tempList,
        isShuffled: true,
      );
    } else {
      final currentIndex = state.originalPlaylist!.indexWhere((song) => song.id == state.currentSong!.id);

      state = state.copyWith(
        playlist: List.from(state.originalPlaylist!),
        currentIndex: currentIndex,
        isShuffled: false,
      );
    }
  }

  Future<void> seek(Duration position) async {
    await state.player.seek(position);
  }

  Future<void> stop() async {
    await state.player.stop();
    state = AudioPlayerState(
      player: state.player,
      currentSong: null,
      playlist: null,
      originalPlaylist: null,
      isPlaying: false,
      currentIndex: 0,
      position: Duration.zero,
      duration: Duration.zero,
      isShuffled: false,
    );
  }

  // Public methods for next/previous
  Future<void> next() async => _playNext();
  Future<void> previous() async => _playPrevious();

  @override
  void dispose() {
    state.player.dispose();
    super.dispose();
  }
}