import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/get_artist_profile_by_id_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import '../../../model/apiresponse_model.dart';

class ArtistProfile extends ConsumerStatefulWidget {
  final int artistId;
  const ArtistProfile({super.key, required this.artistId});

  @override
  ConsumerState<ArtistProfile> createState() => _ArtistProfileScreenState();
}

final followStatusProvider = StateProvider<Map<String, bool>>((ref) => {});

class _ArtistProfileScreenState extends ConsumerState<ArtistProfile> {
  bool showSongs = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(getArtistProfileByIdProvider.notifier)
          .getArtistProfile(widget.artistId);
      await checkFollowStatus();
    });
  }
  Future<void> checkFollowStatus() async {
    try {
      final response = await ref.read(apiresponseProvider.notifier).checkFollowStatus(
        context: context,
        artistId: widget.artistId,
      );

      print('🔍 CheckFollowStatus API Response:');
      print('🔍 Status: ${response.status}');
      print('🔍 Data: ${response.data}');
      print('🔍 is_following: ${response.data['is_following']}');
      ref.read(followStatusProvider.notifier).state = {
        ...ref.read(followStatusProvider),
        widget.artistId.toString(): response.data['is_following']
      };
    } catch (error) {
      print("❌ Error checking follow status: $error");
    }
  }

  Future<void> followArtist() async {

    try {
      final isFollowing = ref.read(followStatusProvider)[widget.artistId.toString()] ?? false;
      ApiResponseModel response;

      if (isFollowing) {
        // Unfollow
        response = await ref.read(apiresponseProvider.notifier).unfollowArtist(
          context: context,
          artistId: widget.artistId,
        );
      } else {
        // Follow
        response = await ref.read(apiresponseProvider.notifier).followArtist(
          context: context,
          artistId: widget.artistId,
        );
      }

      if (response.status) {
        // Update follow status immediately
        ref.read(followStatusProvider.notifier).update((state) {
          return {...state, widget.artistId.toString(): response.data['is_following']};
        });

        // Refresh artist profile to update follower count
        await ref
            .read(getArtistProfileByIdProvider.notifier)
            .getArtistProfile(widget.artistId);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(getArtistProfileByIdProvider);
    final followStatus = ref.watch(followStatusProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0817),
      body: SafeArea(
        child: profileState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (err, _) => Center(
            child: Text(
              'Failed to load artist profile: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          data: (artistProfile) {
            final artist = artistProfile.data.artist;
            final stats = artistProfile.data.stats;
            final songs = artistProfile.data.songs;
            final events = artistProfile.data.events;
            final isFollowing = followStatus[widget.artistId.toString()] ?? false;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.network(
                        artist.coverImage,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: -35,
                        left: 20,
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFF8A2BE2),
                          backgroundImage: artist.profileImage.isNotEmpty
                              ? NetworkImage(artist.profileImage)
                              : null,
                          child: artist.profileImage.isEmpty
                              ? Text(
                            artist.name.isNotEmpty
                                ? artist.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          artist.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A2BE2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          child: const Text(
                            'Book artist',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: followArtist,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                          ),
                          child: Text(
                              isFollowing ? 'Unfollow' : 'Follow',
                            style: const TextStyle(color: Colors.black, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatsItem(
                            title: '${stats.totalViews}', subtitle: 'views'),
                        _StatsItem(
                            title: '${stats.totalSongs}', subtitle: 'songs'),
                        _StatsItem(
                            title: '${stats.totalFollowers}',
                            subtitle: 'followers'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tabs (Songs / Events)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _TabButton(
                          text: 'Songs',
                          isActive: showSongs,
                          onTap: () => setState(() => showSongs = true),
                        ),
                        const SizedBox(width: 10),
                        _TabButton(
                          text: 'Events',
                          isActive: !showSongs,
                          onTap: () => setState(() => showSongs = false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Song or Event List
                  if (showSongs)
                    songs.isNotEmpty
                        ? Column(
                      children: songs.map((song) {
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              song.coverPhoto,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${song.plays} plays',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white70,
                            ),
                            onPressed: () {},
                          ),
                        );
                      }).toList(),
                    )
                        : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No songs yet',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    events.isNotEmpty
                        ? Column(
                      children: events.map((event) {
                        return const ListTile(
                          title: Text(
                            'Upcoming Event',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                        : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No events yet',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatsItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StatsItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8A2BE2) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

