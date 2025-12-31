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
    ThemeData? theme,
    bool? isDark,
  }) {
    final currentTheme = theme ?? Theme.of(context);
    final currentIsDark = isDark ?? currentTheme.brightness == Brightness.dark;

    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      backgroundColor: currentTheme.cardColor,
      builder: (context) => _buildSongOptionsContent(
        context: context,
        song: song,
        onAddToPlaylist: onAddToPlaylist,
        onArtistProfile: onArtistProfile,
        theme: currentTheme,
        isDark: currentIsDark,
      ),
    );
  }

  static Widget _buildSongOptionsContent({
    required BuildContext context,
    required SongItem song,
    required VoidCallback onAddToPlaylist,
    required VoidCallback onArtistProfile,
    required ThemeData theme,
    required bool isDark,
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
              child: Icon(
                Icons.close,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._buildSongOptions(
            context: context,
            song: song,
            onAddToPlaylist: onAddToPlaylist,
            onArtistProfile: onArtistProfile,
            theme: theme,
            isDark: isDark,
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
    required ThemeData theme,
    required bool isDark,
  }) {
    return [
      _BottomOption(
        icon: Icons.playlist_add,
        label: "Add to playlist",
        onTap: () {
          Navigator.pop(context);
          onAddToPlaylist();
        },
        theme: theme,
        isDark: isDark,
      ),
      _BottomOption(
        icon: Icons.person_outline,
        label: "Check artist profile",
        onTap: () {
          Navigator.pop(context);
          onArtistProfile();
        },
        theme: theme,
        isDark: isDark,
      ),
      _BottomOption(
        icon: Icons.work_outline,
        label: "Book artist",
        onTap: () => Navigator.pop(context),
        theme: theme,
        isDark: isDark,
      ),
      _BottomOption(
        icon: Icons.mic_none_outlined,
        label: "Play karaoke",
        onTap: () => Navigator.pop(context),
        theme: theme,
        isDark: isDark,
      ),
      _BottomOption(
        icon: Icons.share_outlined,
        label: "Share song",
        onTap: () => Navigator.pop(context),
        theme: theme,
        isDark: isDark,
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
    ThemeData? theme,
    bool? isDark,
  }) {
    final currentTheme = theme ?? Theme.of(context);
    final currentIsDark = isDark ?? currentTheme.brightness == Brightness.dark;

    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: currentTheme.cardColor,
      builder: (context) => _buildAddToPlaylistContent(
        context: context,
        song: song,
        ref: ref,
        onCreatePlaylist: onCreatePlaylist,
        onPlaylistTap: onPlaylistTap,
        onPlaylistRename: onPlaylistRename,
        onPlaylistDelete: onPlaylistDelete,
        theme: currentTheme,
        isDark: currentIsDark,
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
    required ThemeData theme,
    required bool isDark,
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
            theme: theme, context: context,
          ),
          const SizedBox(height: 20),
          _buildPlaylistList(
            context: context,
            song: song,
            ref: ref,
            onPlaylistTap: onPlaylistTap,
            onPlaylistRename: onPlaylistRename,
            onPlaylistDelete: onPlaylistDelete,
            theme: theme,
            isDark: isDark,
          ),
          _buildCreatePlaylistButton(
            context,
            onCreatePlaylist,
            theme,
            isDark,
          ),
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
    required ThemeData theme,
    required bool isDark,
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
              theme: theme,
              isDark: isDark,
            ),
            loading: () => _buildLoadingIndicator(theme),
            error: (err, stack) => _buildErrorWidget(err, theme),
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
    required ThemeData theme,
    required bool isDark,
  }) {
    if (playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 50, bottom: 50),
        child: Center(
          child: Text(
            "You have not created any playlist yet",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
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
            return _buildLoadMoreIndicator(theme);
          }
          return _buildPlaylistTile(
            playlist: playlists[index],
            song: song,
            onPlaylistTap: onPlaylistTap,
            onPlaylistRename: onPlaylistRename,
            onPlaylistDelete: onPlaylistDelete,
            theme: theme,
            isDark: isDark,
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
    required ThemeData theme,
    required bool isDark,
  }) {
    return _PlaylistTile(
      playlist: playlist,
      onTap: () => onPlaylistTap(playlist, song),
      onRename: () => onPlaylistRename(playlist),
      onDelete: () => onPlaylistDelete(playlist),
      theme: theme,
      isDark: isDark,
    );
  }

  static Widget _buildLoadMoreIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Consumer(
          builder: (context, ref, _) {
            final playlistState = ref.watch(getPlaylistProvider);
            final isLoading = playlistState.isLoading;

            return isLoading
                ? CircularProgressIndicator(color: theme.colorScheme.primary)
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  static Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }

  static Widget _buildErrorWidget(dynamic error, ThemeData theme) {
    return Center(
      child: Text(
        'Error loading playlists: $error',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }

  static Widget _buildCreatePlaylistButton(
      BuildContext context,
      VoidCallback onCreatePlaylist,
      ThemeData theme,
      bool isDark,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RoundedButton(
        title: 'Create new playlist',
        onPressed: () {
          Navigator.pop(context);
          onCreatePlaylist();
        },
        color: AppColors.BUTTONCOLOR,
        textColor: Colors.white,
        minWidth: double.infinity,
        borderRadius: 25.0,
      ),
    );
  }

  // Rename Playlist Bottom Sheet
  static void showRenamePlaylist({
    required BuildContext context,
    required Playlist playlist,
    required TextEditingController renameController,
    required VoidCallback onRename,
    ThemeData? theme,
    bool? isDark,
  }) {
    final currentTheme = theme ?? Theme.of(context);
    final currentIsDark = isDark ?? currentTheme.brightness == Brightness.dark;

    renameController.text = playlist.title;

    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: currentTheme.cardColor,
      builder: (context) => _buildRenamePlaylistContent(
        context: context,
        renameController: renameController,
        onRename: onRename,
        theme: currentTheme,
        isDark: currentIsDark,
      ),
    );
  }

  static Widget _buildRenamePlaylistContent({
    required BuildContext context,
    required TextEditingController renameController,
    required VoidCallback onRename,
    required ThemeData theme,
    required bool isDark,
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
              onClose: () => Navigator.pop(context), context: context,
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
              color: AppColors.BUTTONCOLOR,
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
    ThemeData? theme,
    bool? isDark,
  }) {
    final currentTheme = theme ?? Theme.of(context);
    final currentIsDark = isDark ?? currentTheme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.cardColor,
        title: Text(
          'Delete Playlist',
          style: TextStyle(color: currentTheme.colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.title}"? This action cannot be undone.',
          style: TextStyle(color: currentTheme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: currentTheme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: currentTheme.colorScheme.error),
            ),
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
  final ThemeData theme;
  final bool isDark;

  const _BottomOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
    required this.isDark,
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
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
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
  final ThemeData theme;
  final bool isDark;

  const _PlaylistTile({
    required this.playlist,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.transparent : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.playlist_play,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.songs.length} songs',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                  icon: Icon(
                    Icons.edit_outlined,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: onRename,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error.withOpacity(0.7),
                    size: 20,
                  ),
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