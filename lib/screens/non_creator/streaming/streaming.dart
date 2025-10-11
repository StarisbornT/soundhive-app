import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/artist_song_model.dart';
import 'package:soundhive2/screens/non_creator/streaming/play_music.dart';

import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/getAllSongsProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../lib/audio_player_provider.dart';
import '../../../utils/app_colors.dart';

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
  _StreamingState createState() => _StreamingState();
}

class _StreamingState extends ConsumerState<Streaming> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(getAllSongsProvider.notifier).getAllSongs();
    });
  }
  List<String> types = [
    "Gospel", "Metal", "Rock", "Hip-Pop", "Reggae",
    "Country", "Classical", "Jazz", "Blues"
  ];
  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        // 🔍 Search box
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.BACKGROUNDCOLOR,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.TEXT_SECONDARY.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.TEXT_SECONDARY, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Search for a song',
                      hintStyle: TextStyle(color: AppColors.TEXT_SECONDARY, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (value) {
                      ref.read(getAllSongsProvider.notifier).getAllSongs(search: value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10.0),

        // 🎚️ Filter button
        Container(
          decoration: BoxDecoration(
            color: AppColors.BACKGROUNDCOLOR,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: TextButton.icon(
            onPressed: _showTypeFilterBottomSheet,
            icon: const Icon(Icons.filter_list, color: Colors.white),
            label: const Text(
              'Filter',
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
  void _showTypeFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Song Type',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: types.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple,
                    backgroundColor: const Color(0xFF2C2C2C),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.TEXT_SECONDARY,
                    ),
                    onSelected: (_) {
                      Navigator.pop(context);
                      setState(() => selectedType = type);
                      ref.read(getAllSongsProvider.notifier).getAllSongs(type: type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (selectedType != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => selectedType = null);
                    ref.read(getAllSongsProvider.notifier).getAllSongs();
                  },
                  child: const Text('Clear Filter', style: TextStyle(color: Colors.white70)),
                ),
            ],
          ),
        );
      },
    );
  }
  // Widget for a single track list item
  Widget _buildTrackItem(SongItem song) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            image: DecorationImage(
              image: NetworkImage(song.coverPhoto), // ✅ Use song cover
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.artist?.userName ?? "Unknown Artist",
              style: const TextStyle(color: AppColors.TEXT_SECONDARY, fontSize: 12),
            ),
            Text(
              "${song.plays} plays",
              style: const TextStyle(color: AppColors.TEXT_SECONDARY, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.more_vert, color: AppColors.TEXT_SECONDARY),
        // In the _buildTrackItem method, update the onTap:
        onTap: () {
          final songsState = ref.read(getAllSongsProvider);
          List<SongItem>? playlist;

          songsState.when(
            data: (songModel) {
              playlist = songModel.data.data;
            },
            loading: () => playlist = null,
            error: (e, _) => playlist = null,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayMusic(
                song: song,
                playlist: playlist, // Pass the entire playlist
              ),
            ),
          );
        },
      ),
    );
  }
  // Widget for the persistent mini player at the bottom
  // In Streaming screen - _buildMiniPlayer method
  // In the Streaming screen - _buildMiniPlayer method
  Widget _buildMiniPlayer() {
    final audioState = ref.watch(audioPlayerProvider);
    final currentSong = audioState.currentSong;

    // Don't show mini player if no song is playing
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayMusic(
              song: currentSong,
              playlist: audioState.playlist,
              fromMiniPlayer: true,
            ),
          ),
        );
      },
      child: Container(
        height: 70.0,
        color: AppColors.MINI_PLAYER_COLOR,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            // Album Art with proper error handling
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: currentSong.coverPhoto.isNotEmpty
                    ? Image.network(
                  currentSong.coverPhoto,
                  fit: BoxFit.cover,
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                    );
                  },
                )
                    : Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                ),
              ),
            ),

            // Title and Artist
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentSong.artist?.userName ?? 'Unknown Artist',
                    style: const TextStyle(color: AppColors.TEXT_SECONDARY, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Play/Pause button
            IconButton(
              icon: Icon(
                audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
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
    final user = ref.watch(userProvider);
    final songsState = ref.watch(getAllSongsProvider);

    Widget buildDiscoverSection() {
      return songsState.when(
        data: (songModel) {
          final tracks = songModel.data.data;
          if (tracks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No songs found', style: TextStyle(color: Colors.white70)),
              ),
            );
          }

          return Column(
            children: tracks.map((song) {
              return _buildTrackItem(song); // ✅ Pass the actual song model
            }).toList(),
          );

        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFB0B0B6),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'SoundHive- Stream Music',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              // 1. Verification Banner
              CreatorBanner(user: user.value!,),

              const SizedBox(height: 10,),

              // 2. Search and Filter
              _buildSearchAndFilter(),
              const SizedBox(height: 10,),

              // 3. Discover Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => Categories(user: widget.user),
                      //   ),
                      // )
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2C2C2C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Text(
                      'View More',
                      style: TextStyle(color: Color(0xFFB0B0B6), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              // 4. Track List
              buildDiscoverSection(),

              const SizedBox(height: 70.0),
            ],
          ),
        ),
      ),
      // 5. Mini Player (using bottomNavigationBar for persistence)
      bottomNavigationBar: _buildMiniPlayer(),
    );
  }
}
