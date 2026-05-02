import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/artist_song_model.dart';
import 'package:soundhive2/screens/non_creator/streaming/play_music.dart';
import 'package:soundhive2/screens/non_creator/streaming/song_helper.dart';

import '../../../components/label_text.dart';
import '../../../components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/getAllSongsProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/audio_player_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/getPlayListProvider.dart';
import '../../../model/playlist_model.dart';
import '../../../utils/app_colors.dart';
import 'artist_profile.dart';

class Track {
  final String title;
  final String artist;
  final String stats;
  final String imageUrl;

  Track({
    required this.title,
    required this.artist,
    required this.stats,
    required this.imageUrl,
  });
}

class Streaming extends ConsumerStatefulWidget {
  const Streaming({super.key});

  @override
  ConsumerState<Streaming> createState() => _StreamingState();
}


class _StreamingState extends ConsumerState<Streaming> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _playlistTitleController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();
  String? selectedType;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(getAllSongsProvider.notifier).loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(getAllSongsProvider.notifier).searchSongs('');
      await ref.read(getPlaylistProvider.notifier).getPlaylists();
    });
  }
  String? _selectedGenre;

  List<String> types = [
    "Gospel", "Metal", "Rock", "Hip-Pop", "Reggae",
    "Country", "Classical", "Jazz", "Blues", "Afrofusion", "Agro Beat", "Juju", "Other Genres"
  ];
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(getAllSongsProvider.notifier).searchSongs(value);
    });
  }

  final List<Map<String, dynamic>> _genres = [
    {'label': 'Afrobeats', 'emoji': '🥁'},
    {'label': 'Gospel',    'emoji': '🙏'},
    {'label': 'Hip-Hop',   'emoji': '🎤'},
    {'label': 'Reggae',    'emoji': '🌿'},
    {'label': 'Jazz',      'emoji': '🎷'},
  ];

  Widget _buildGenreChips(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final isSelected = _selectedGenre == genre['label'];

          return GestureDetector(
            onTap: () {
              final tapped = genre['label'] as String;
              final next = isSelected ? null : tapped;
              setState(() => _selectedGenre = next);
              ref.read(getAllSongsProvider.notifier).searchSongs(next ?? '');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.BUTTONCOLOR
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.BUTTONCOLOR
                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    genre['emoji'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    genre['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.BACKGROUNDCOLOR : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search for a song',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
        // const SizedBox(width: 10.0),
        // Container(
        //   decoration: BoxDecoration(
        //     color: isDark ? AppColors.BACKGROUNDCOLOR : Colors.grey[100],
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: theme.dividerColor),
        //   ),
        //   child: TextButton.icon(
        //     onPressed: () => _showTypeFilterBottomSheet(theme, isDark),
        //     icon: Icon(
        //       Icons.filter_list,
        //       color: theme.colorScheme.onSurface,
        //     ),
        //     label: Text(
        //       'Filter',
        //       style: TextStyle(
        //         color: theme.colorScheme.onSurface.withOpacity(0.6),
        //         fontSize: 12,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  // void _showTypeFilterBottomSheet(ThemeData theme, bool isDark) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: theme.cardColor,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (context) {
  //       return Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Select Song Type',
  //               style: TextStyle(
  //                 color: theme.colorScheme.onSurface,
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             Wrap(
  //               spacing: 8,
  //               children: types.map((type) {
  //                 final isSelected = selectedType == type;
  //                 return ChoiceChip(
  //                   label: Text(
  //                     type,
  //                     style: TextStyle(
  //                       color: isSelected
  //                           ? Colors.white
  //                           : theme.colorScheme.onSurface.withOpacity(0.8),
  //                     ),
  //                   ),
  //                   selected: isSelected,
  //                   selectedColor: AppColors.BUTTONCOLOR,
  //                   backgroundColor: isDark
  //                       ? const Color(0xFF2C2C2C)
  //                       : Colors.grey[200],
  //                   onSelected: (_) {
  //                     Navigator.pop(context);
  //                     setState(() => selectedType = type);
  //                     ref.read(getAllSongsProvider.notifier).getAllSongs(type: type);
  //                   },
  //                 );
  //               }).toList(),
  //             ),
  //             const SizedBox(height: 8),
  //             if (selectedType != null)
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   setState(() => selectedType = null);
  //                   ref.read(getAllSongsProvider.notifier).getAllSongs();
  //                 },
  //                 child: Text(
  //                   'Clear Filter',
  //                   style: TextStyle(
  //                     color: theme.colorScheme.onSurface.withOpacity(0.7),
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildTrackItem(SongItemData song, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.transparent : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              image: DecorationImage(
                image: NetworkImage(song.cover),
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            song.title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.artist,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            onPressed: () => _showSongOptions(song, theme, isDark),
          ),
          onTap: () {
            final songsState = ref.read(getAllSongsProvider);
            List<SongItemData>? playlist;

            songsState.when(
              data: (songModel) {
                playlist = songModel.data;
              },
              loading: () => playlist = null,
              error: (e, _) => playlist = null,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayMusic(
                  song: song,
                  playlist: playlist,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSongOptions(SongItemData song, ThemeData theme, bool isDark) {
    SharedBottomSheets.showSongOptions(
      context: context,
      song: song,
      ref: ref,
      theme: theme,
      isDark: isDark,
      onAddToPlaylist: () => _showAddToPlaylist(song, theme, isDark),
      onArtistProfile: () => _navigateToArtistProfile(song),
    );
  }

  void _showAddToPlaylist(SongItemData song, ThemeData theme, bool isDark) {
    SharedBottomSheets.showAddToPlaylist(
      context: context,
      song: song,
      ref: ref,
      theme: theme,
      isDark: isDark,
      onCreatePlaylist: () => _showCreatePlaylistBottomSheet(theme, isDark),
      onPlaylistTap: (playlist, songToAdd) => _onPlaylistTap(playlist, songToAdd),
      onPlaylistRename: (playlist) => _onPlaylistRename(playlist, theme, isDark),
      onPlaylistDelete: (playlist) => _onPlaylistDelete(playlist, theme, isDark),
    );
  }

  void _onPlaylistTap(Playlist playlist, SongItemData songToAdd) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${songToAdd.title} to ${playlist.title}'),
        backgroundColor: AppColors.BUTTONCOLOR,
      ),
    );
  }

  void _onPlaylistRename(Playlist playlist, ThemeData theme, bool isDark) {
    Navigator.pop(context);
    SharedBottomSheets.showRenamePlaylist(
      context: context,
      playlist: playlist,
      renameController: _renameController,
      theme: theme,
      isDark: isDark,
      onRename: () => _renamePlaylist(playlist.id),
    );
  }

  void _onPlaylistDelete(Playlist playlist, ThemeData theme, bool isDark) {
    Navigator.pop(context);
    SharedBottomSheets.showDeletePlaylistConfirmation(
      context: context,
      playlist: playlist,
      theme: theme,
      isDark: isDark,
      onDelete: () => _deletePlaylist(playlist.id),
    );
  }

  void _renamePlaylist(int playlistId) async {
    try {
      final playlistService = ref.read(playlistServiceProvider);
      final response = await playlistService.renamePlaylist(
        context: context,
        playlistId: playlistId,
        title: _renameController.text,
      );

      if (response.status) {
        Navigator.pop(context);
        _renameController.clear();
        playlistService.refreshPlaylists();
      }
    } catch (error) {
      ErrorHandler.showErrorAlert(context: context, error: error);
    }
  }

  void _deletePlaylist(int playlistId) async {
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

  void _navigateToArtistProfile(SongItemData song) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ArtistProfile(
    //       artistId: int.parse(song.artistId),
    //     ),
    //   ),
    // );
  }

  void _showCreatePlaylistBottomSheet(ThemeData theme, bool isDark) {
    BottomSheetHelper.showCommonBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      builder: (context) => _buildCreatePlaylistContent(theme, isDark),
    );
  }

  Widget _buildCreatePlaylistContent(ThemeData theme, bool isDark) {
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
              title: "Create new playlist",
              onClose: () => Navigator.pop(context),
              theme: theme, context: context,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Title of Playlist',
              controller: _playlistTitleController,
            ),
            const SizedBox(height: 16),
            RoundedButton(
              title: 'Save playlist',
              onPressed: _createPlaylist,
              color: AppColors.BUTTONCOLOR,
            ),
          ],
        ),
      ),
    );
  }

  void _createPlaylist() async {
    try {
      final playlistService = ref.read(playlistServiceProvider);
      final response = await playlistService.createPlaylist(
        context: context,
        title: _playlistTitleController.text,
      );

      if (response.status) {
        Navigator.pop(context);
        _playlistTitleController.clear();
        playlistService.refreshPlaylists();
      }
    } catch (error) {
      ErrorHandler.showErrorAlert(context: context, error: error);
    }
  }

  Widget _buildMiniPlayer(ThemeData theme, bool isDark) {
    final audioState = ref.watch(audioPlayerProvider);
    final currentSong = audioState.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => PlayMusic(
        //       song: currentSong,
        //       playlist: audioState,
        //       fromMiniPlayer: true,
        //     ),
        //   ),
        // );
      },
      child: Container(
        height: 70.0,
        color: isDark ? AppColors.MINI_PLAYER_COLOR : Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: currentSong.cover.isNotEmpty
                    ? Image.network(
                  currentSong.cover,
                  fit: BoxFit.cover,
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      child: Icon(
                        Icons.music_note,
                        color: theme.colorScheme.onSurface,
                        size: 24,
                      ),
                    );
                  },
                )
                    : Container(
                  width: 50,
                  height: 50,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  child: Icon(
                    Icons.music_note,
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentSong.artist,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                color: theme.colorScheme.onSurface,
                size: 30,
              ),
              onPressed: () {
                ref.read(audioPlayerProvider.notifier).togglePlayPause();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final songsState = ref.watch(getAllSongsProvider);

    Widget buildDiscoverSection(DeepFreezerModel songModel) {
      final tracks = songModel.data;

      if (tracks.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No songs found',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        );
      }

      return Column(
        children: [
          ...tracks.map((song) => _buildTrackItem(song, theme, isDark)),

          if (songModel.hasMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          const SizedBox(height: 10),

          Text(
            'SoundHive - Stream Music',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 10),

          Image.asset('images/music_banner.png'),

          const SizedBox(height: 10),

          _buildSearchAndFilter(theme, isDark),

          const SizedBox(height: 12),

          _buildGenreChips(theme, isDark),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discover',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          songsState.when(
            data: (songModel) => buildDiscoverSection(songModel),
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),

      bottomNavigationBar: _buildMiniPlayer(theme, isDark),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _playlistTitleController.dispose();
    _renameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
