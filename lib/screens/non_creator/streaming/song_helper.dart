// shared_bottom_sheets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/non_creator/streaming/play_music.dart';

import '../../../components/label_text.dart';
import '../../../components/rounded_button.dart';
import '../../../lib/dashboard_provider/getPlayListProvider.dart';
import '../../../model/artist_song_model.dart';
import '../../../model/playlist_model.dart';
import '../../../utils/app_colors.dart';

// ========== SHARED BOTTOM SHEET COMPONENTS ==========

class SharedBottomSheets {
  // Song Options Bottom Sheet
  static void showSongOptions({
    required BuildContext context,
    required SongItem song,
    required WidgetRef ref,
    required VoidCallback onAddToPlaylist,
    required VoidCallback onArtistProfile,
  }) {
    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      builder: (context) => _buildSongOptionsContent(
        context: context,
        song: song,
        onAddToPlaylist: onAddToPlaylist,
        onArtistProfile: onArtistProfile,
      ),
    );
  }

  static Widget _buildSongOptionsContent({
    required BuildContext context,
    required SongItem song,
    required VoidCallback onAddToPlaylist,
    required VoidCallback onArtistProfile,
  }) {
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
          ..._buildSongOptions(
            context: context,
            song: song,
            onAddToPlaylist: onAddToPlaylist,
            onArtistProfile: onArtistProfile,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static List<Widget> _buildSongOptions({
    required BuildContext context,
    required SongItem song,
    required VoidCallback onAddToPlaylist,
    required VoidCallback onArtistProfile,
  }) {
    return [
      _BottomOption(
        icon: Icons.playlist_add,
        label: "Add to playlist",
        onTap: () {
          Navigator.pop(context);
          onAddToPlaylist();
        },
      ),
      _BottomOption(
        icon: Icons.person_outline,
        label: "Check artist profile",
        onTap: () {
          Navigator.pop(context);
          onArtistProfile();
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

  // Add to Playlist Bottom Sheet
  static void showAddToPlaylist({
    required BuildContext context,
    required SongItem song,
    required WidgetRef ref,
    required VoidCallback onCreatePlaylist,
    required Function(Playlist, SongItem) onPlaylistTap,
    required Function(Playlist) onPlaylistRename,
    required Function(Playlist) onPlaylistDelete,
  }) {
    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildAddToPlaylistContent(
        context: context,
        song: song,
        ref: ref,
        onCreatePlaylist: onCreatePlaylist,
        onPlaylistTap: onPlaylistTap,
        onPlaylistRename: onPlaylistRename,
        onPlaylistDelete: onPlaylistDelete,
      ),
    );
  }

  static Widget _buildAddToPlaylistContent({
    required BuildContext context,
    required SongItem song,
    required WidgetRef ref,
    required VoidCallback onCreatePlaylist,
    required Function(Playlist, SongItem) onPlaylistTap,
    required Function(Playlist) onPlaylistRename,
    required Function(Playlist) onPlaylistDelete,
  }) {
    return BottomSheetHelper.buildBottomSheetWrapper(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottomSheetHelper.buildBottomSheetHeader(
            title: "Add to playlist",
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
          _buildPlaylistList(
            context: context,
            song: song,
            ref: ref,
            onPlaylistTap: onPlaylistTap,
            onPlaylistRename: onPlaylistRename,
            onPlaylistDelete: onPlaylistDelete,
          ),
          _buildCreatePlaylistButton(context, onCreatePlaylist),
        ],
      ),
    );
  }

  static Widget _buildPlaylistList({
    required BuildContext context,
    required SongItem song,
    required WidgetRef ref,
    required Function(Playlist, SongItem) onPlaylistTap,
    required Function(Playlist) onPlaylistRename,
    required Function(Playlist) onPlaylistDelete,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final playlistsAsyncValue = ref.watch(getPlaylistProvider);
        final playlistNotifier = ref.read(getPlaylistProvider.notifier);

        return Flexible(
          child: playlistsAsyncValue.when(
            data: (playlists) => _buildPlaylistListView(
              context: context,
              playlists: playlists.data.data,
              song: song,
              playlistNotifier: playlistNotifier,
              onPlaylistTap: onPlaylistTap,
              onPlaylistRename: onPlaylistRename,
              onPlaylistDelete: onPlaylistDelete,
            ),
            loading: () => _buildLoadingIndicator(),
            error: (err, stack) => _buildErrorWidget(err),
          ),
        );
      },
    );
  }

  static Widget _buildPlaylistListView({
    required BuildContext context,
    required List<Playlist> playlists,
    required SongItem song,
    required GetPlaylistNotifier playlistNotifier,
    required Function(Playlist, SongItem) onPlaylistTap,
    required Function(Playlist) onPlaylistRename,
    required Function(Playlist) onPlaylistDelete,
  }) {
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
          return _buildPlaylistTile(
            playlist: playlists[index],
            song: song,
            onPlaylistTap: onPlaylistTap,
            onPlaylistRename: onPlaylistRename,
            onPlaylistDelete: onPlaylistDelete,
          );
        },
      ),
    );
  }

  static Widget _buildPlaylistTile({
    required Playlist playlist,
    required SongItem song,
    required Function(Playlist, SongItem) onPlaylistTap,
    required Function(Playlist) onPlaylistRename,
    required Function(Playlist) onPlaylistDelete,
  }) {
    return _PlaylistTile(
      playlist: playlist,
      onTap: () => onPlaylistTap(playlist, song),
      onRename: () => onPlaylistRename(playlist),
      onDelete: () => onPlaylistDelete(playlist),
    );
  }

  static Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Consumer(
          builder: (context, ref, _) {
            final playlistState = ref.watch(getPlaylistProvider);
            final isLoading = playlistState.isLoading;

            return isLoading
                ? const CircularProgressIndicator(color: Color(0xFF9B59B6))
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }


  static Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(color: Color(0xFF9B59B6)),
      ),
    );
  }

  static Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Text(
        'Error loading playlists: $error',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  static Widget _buildCreatePlaylistButton(BuildContext context, VoidCallback onCreatePlaylist) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RoundedButton(
        title: 'Create new playlist',
        onPressed: () {
          Navigator.pop(context);
          onCreatePlaylist();
        },
        color: AppColors.PRIMARYCOLOR,
      ),
    );
  }

  // Rename Playlist Bottom Sheet
  static void showRenamePlaylist({
    required BuildContext context,
    required Playlist playlist,
    required TextEditingController renameController,
    required VoidCallback onRename,
  }) {
    renameController.text = playlist.title;

    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildRenamePlaylistContent(
        context: context,
        renameController: renameController,
        onRename: onRename,
      ),
    );
  }

  static Widget _buildRenamePlaylistContent({
    required BuildContext context,
    required TextEditingController renameController,
    required VoidCallback onRename,
  }) {
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
              title: "Rename playlist",
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Title of Playlist',
              controller: renameController,
            ),
            const SizedBox(height: 16),
            RoundedButton(
              title: 'Save changes',
              onPressed: onRename,
              color: AppColors.PRIMARYCOLOR,
            ),
          ],
        ),
      ),
    );
  }

  // Delete Playlist Confirmation Dialog
  static void showDeletePlaylistConfirmation({
    required BuildContext context,
    required Playlist playlist,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        title: const Text(
          'Delete Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.title}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Reusable components
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