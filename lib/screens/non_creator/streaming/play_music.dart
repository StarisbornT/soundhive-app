import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:soundhive2/components/label_text.dart';

import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/getAllSongsProvider.dart';
import 'package:soundhive2/lib/audio_player_provider.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/getPlayListProvider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/artist_song_model.dart';
import '../../../model/playlist_model.dart';
import '../../../utils/alert_helper.dart';
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
  ConsumerState<PlayMusic> createState() => _PlayMusicState();
}

// ========== REUSABLE COMPONENTS ==========

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PlaylistTile({
    required this.playlist,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.songs.length} songs',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
                  onPressed: onRename,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

// ========== UTILITY CLASSES ==========


class BottomSheetHelper {
  static Widget buildBottomSheetWrapper({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.only(top: 16),
    ThemeData? theme,
  }) {
    final currentTheme = theme ?? Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: currentTheme.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      padding: padding,
      child: child,
    );
  }

  static Widget buildBottomSheetHeader({
    required BuildContext context,
    required String title,
    required VoidCallback onClose,
    ThemeData? theme,
  }) {
    final currentTheme = theme ?? Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: currentTheme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              color: currentTheme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  static void showCommonBottomSheet({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    Color? backgroundColor,
    ThemeData? theme,
  }) {
    final currentTheme = theme ?? Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? currentTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: builder,
    );
  }
}

class ErrorHandler {
  static String parseDioError(DioException error) {
    if (error.response?.data != null) {
      try {
        final apiResponse = ApiResponseModel.fromJson(error.response?.data);
        return apiResponse.message;
      } catch (e) {
        return 'Failed to parse error message';
      }
    } else {
      return error.message ?? 'Network error occurred';
    }
  }

  static void showErrorAlert({
    required BuildContext context,
    required dynamic error,
  }) {
    String errorMessage = 'An unexpected error occurred';

    if (error is DioException) {
      errorMessage = parseDioError(error);
    }

    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: errorMessage,
    );
  }
}

class PlaylistService {
  final Ref ref;

  PlaylistService(this.ref);

  Future<ApiResponseModel> createPlaylist({
    required BuildContext context,
    required String title,
  }) async {
    final payload = {"title": title};
    return await ref.read(apiresponseProvider.notifier).createPlaylist(
      context: context,
      payload: payload,
    );
  }

  Future<ApiResponseModel> renamePlaylist({
    required BuildContext context,
    required int playlistId,
    required String title,
  }) async {
    final payload = {"title": title};
    return await ref.read(apiresponseProvider.notifier).renamePlaylist(
      context: context,
      playlistId: playlistId,
      payload: payload,
    );
  }

  Future<ApiResponseModel> deletePlaylist({
    required BuildContext context,
    required int playlistId,
  }) async {
    return await ref.read(apiresponseProvider.notifier).deletePlaylist(
      context: context,
      playlistId: playlistId,
    );
  }

  void refreshPlaylists() {
    ref.invalidate(getPlaylistProvider);
  }
}

// ========== PROVIDERS ==========

final playTrackingProvider = StateProvider<Map<String, bool>>((ref) => {});
final playlistServiceProvider = Provider((ref) => PlaylistService(ref));

// ========== MAIN WIDGET STATE ==========

class _PlayMusicState extends ConsumerState<PlayMusic> {
  Timer? _playTimer;
  int _listenDuration = 0;
  bool _playCounted = false;
  bool _apiCallMade = false;
  int? _currentSongId;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController renameController = TextEditingController();

  late final PlaylistService _playlistService;

  @override
  void initState() {
    super.initState();
    _currentSongId = widget.song.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.fromMiniPlayer) {
        ref.read(audioPlayerProvider.notifier).playSong(
          widget.song,
          playlist: widget.playlist,
        );
      }
      ref.read(getPlaylistProvider.notifier).getPlaylists();
    });

    _startPlayTracking();
  }

  // ========== PLAY TRACKING METHODS ==========

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

        if (_listenDuration == 30) {
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

  // ========== PLAYER CONTROL METHODS ==========

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

  // ========== BOTTOM SHEET METHODS ==========

  void showAddToPlaylistBottomSheet(BuildContext context, SongItem songToAdd) {
    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildAddToPlaylistContent(songToAdd),
    );
  }

  Widget _buildAddToPlaylistContent(SongItem songToAdd) {
    return BottomSheetHelper.buildBottomSheetWrapper(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottomSheetHelper.buildBottomSheetHeader(
            title: "Add to playlist",
            onClose: () => Navigator.pop(context), context: context,
          ),
          const SizedBox(height: 20),
          _buildPlaylistList(songToAdd),
          _buildCreatePlaylistButton(),
        ],
      ),
    );
  }

  Widget _buildPlaylistList(SongItem songToAdd) {
    return Consumer(
      builder: (context, ref, child) {
        final playlistsAsyncValue = ref.watch(getPlaylistProvider);
        final playlistNotifier = ref.read(getPlaylistProvider.notifier);

        return Flexible(
          child: playlistsAsyncValue.when(
            data: (playlists) => _buildPlaylistListView(playlists.data.data, songToAdd, playlistNotifier),
            loading: () => _buildLoadingIndicator(),
            error: (err, stack) => _buildErrorWidget(err),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistListView(List<Playlist> playlists, SongItem songToAdd, GetPlaylistNotifier playlistNotifier) {
    if (playlists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 50, bottom: 50),
        child: Center(
          child: Text(
            "You have not created any playlist yet",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          playlistNotifier.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: playlists.length + 1,
        itemBuilder: (context, index) {
          if (index == playlists.length) {
            return _buildLoadMoreIndicator();
          }
          return _buildPlaylistTile(playlists[index], songToAdd);
        },
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist, SongItem songToAdd) {
    return _PlaylistTile(
      playlist: playlist,
      onTap: () => _onPlaylistTap(playlist, songToAdd),
      onRename: () => _onPlaylistRename(playlist),
      onDelete: () => _onPlaylistDelete(playlist),
    );
  }

  void _onPlaylistTap(Playlist playlist, SongItem songToAdd) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${songToAdd.title} to ${playlist.title}'),
      ),
    );
  }

  void _onPlaylistRename(Playlist playlist) {
    Navigator.pop(context);
    renamePlaylistBottomSheet(context, playlist);
  }

  void _onPlaylistDelete(Playlist playlist) {
    deletePlaylist(context, playlist.id);
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ref.watch(getPlaylistProvider).isLoading
            ? const CircularProgressIndicator(color: Color(0xFF9B59B6))
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(color: Color(0xFF9B59B6)),
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Text(
        'Error loading playlists: $error',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildCreatePlaylistButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RoundedButton(
        title: 'Create new playlist',
        onPressed: () {
          Navigator.pop(context);
          createPlaylistBottomSheet(context);
        },
        color: AppColors.PRIMARYCOLOR,
      ),
    );
  }

  // ========== PLAYLIST CRUD METHODS ==========

  void createPlaylist() async {
    try {
      final playlistService = ref.read(playlistServiceProvider);
      final response = await playlistService.createPlaylist(
        context: context,
        title: titleController.text,
      );

      if (response.status) {
        Navigator.pop(context);
        playlistService.refreshPlaylists();
      }
    } catch (error) {
      ErrorHandler.showErrorAlert(context: context, error: error);
    }
  }

  void renamePlaylist(BuildContext context, int playlistId) async {
    try {
      final playlistService = ref.read(playlistServiceProvider);
      final response = await playlistService.renamePlaylist(
        context: context,
        playlistId: playlistId,
        title: renameController.text,
      );

      if (response.status) {
        Navigator.pop(context);
        playlistService.refreshPlaylists();
      }
    } catch (error) {
      ErrorHandler.showErrorAlert(context: context, error: error);
    }
  }

  void deletePlaylist(BuildContext context, int playlistId) async {
    try {
      final playlistService = ref.read(playlistServiceProvider);
      final response = await playlistService.deletePlaylist(
        context: context,
        playlistId: playlistId,
      );

      if (response.status) {
        Navigator.pop(context);
        playlistService.refreshPlaylists();
      }
    } catch (error) {
      ErrorHandler.showErrorAlert(context: context, error: error);
    }
  }

  // ========== BOTTOM SHEET CREATION METHODS ==========

  void createPlaylistBottomSheet(BuildContext context) {
    _showFormBottomSheet(
      context: context,
      title: "Create new playlist",
      controller: titleController,
      onSave: createPlaylist,
    );
  }

  void renamePlaylistBottomSheet(BuildContext context, Playlist playlist) {
    renameController.text = playlist.title;
    _showFormBottomSheet(
      context: context,
      title: "Rename playlist",
      controller: renameController,
      onSave: () => renamePlaylist(context, playlist.id),
    );
  }

  void _showFormBottomSheet({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFormBottomSheetContent(title, controller, onSave),
    );
  }

  Widget _buildFormBottomSheetContent(String title, TextEditingController controller, VoidCallback onSave) {
    return BottomSheetHelper.buildBottomSheetWrapper(
      context: context,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BottomSheetHelper.buildBottomSheetHeader(
              title: title,
              onClose: () => Navigator.pop(context), context: context,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Title of Playlist',
              controller: controller,
            ),
            const SizedBox(height: 16),
            RoundedButton(
              title: 'Save playlist',
              onPressed: onSave,
              color: AppColors.PRIMARYCOLOR,
            ),
          ],
        ),
      ),
    );
  }

  // ========== SONG OPTIONS BOTTOM SHEET ==========

  void showSongOptionsBottomSheet(BuildContext context) {
    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      builder: (context) => _buildSongOptionsContent(),
    );
  }

  Widget _buildSongOptionsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 10),
          ..._buildSongOptions(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  List<Widget> _buildSongOptions() {
    return [
      _BottomOption(
        icon: Icons.playlist_add,
        label: "Add to playlist",
        onTap: () {
          Navigator.pop(context);
          showAddToPlaylistBottomSheet(context, widget.song);
        },
      ),
      _BottomOption(
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
      _BottomOption(
        icon: Icons.work_outline,
        label: "Book artist",
        onTap: () => Navigator.pop(context),
      ),
      _BottomOption(
        icon: Icons.mic_none_outlined,
        label: "Play karaoke",
        onTap: () => Navigator.pop(context),
      ),
      _BottomOption(
        icon: Icons.share_outlined,
        label: "Share song",
        onTap: () => Navigator.pop(context),
      ),
    ];
  }

  // ========== BUILD METHOD ==========

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
                _buildTopBar(isPlayCounted),
                const SizedBox(height: 40),
                _buildAlbumArt(currentSong),
                const SizedBox(height: 35),
                _buildSongInfo(currentSong),
                const SizedBox(height: 20),
                _buildProgressBar(audioState.player),
                const SizedBox(height: 30),
                _buildPlayerControls(audioState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== UI COMPONENT METHODS ==========

  Widget _buildTopBar(bool isPlayCounted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
            isPlayCounted ? 'Listening' : 'Listening...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumArt(SongItem currentSong) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: currentSong.coverPhoto.isNotEmpty
          ? Image.network(
        currentSong.coverPhoto,
        height: 340,
        width: 340,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderArt(),
      )
          : _buildPlaceholderArt(),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      height: 340,
      width: 340,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 60),
    );
  }

  Widget _buildSongInfo(SongItem currentSong) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildProgressBar(AudioPlayer player) {
    return StreamBuilder<DurationState>(
      stream: _durationStateStream(player),
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
    );
  }

  Widget _buildPlayerControls(AudioPlayerState audioState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: audioState.isShuffled ? Colors.white : Colors.white70,
            size: 28,
          ),
          onPressed: _toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
          onPressed: audioState.playlist != null && audioState.playlist!.length > 1
              ? _playPrevious : null,
        ),
        _buildPlayPauseButton(audioState),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
          onPressed: audioState.playlist != null && audioState.playlist!.length > 1
              ? _playNext : null,
        ),
        IconButton(
          onPressed: () => showSongOptionsBottomSheet(context),
          icon: const Icon(Icons.more_vert, color: Colors.white70, size: 28),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(AudioPlayerState audioState) {
    return GestureDetector(
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
    );
  }

  // ========== HELPER STREAMS ==========

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

  @override
  void dispose() {
    _stopPlayTracking();
    titleController.dispose();
    renameController.dispose();
    super.dispose();
  }
}

// ========== DATA MODELS ==========

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