
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../model/user_model.dart';
class HomeScreen extends ConsumerWidget {
  final User user;

  HomeScreen({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle('Discover'),
            _buildDiscoverList(),
            sectionTitle('Recommended'),
            _buildRecommendedList(),
            sectionTitle('Personalised Playlists'),
            _buildPlaylistList(),
            sectionTitle('Popular Artists'),
            _buildArtistsList(),
            sectionTitle('Curated Playlists'),
            _buildCuratedPlaylists(),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDiscoverList() {
    return Column(
      children: [
        _discoverItem('A Good Time', 'Davido - 1M followers', '10M plays'),
        _discoverItem('Kese', 'Wizkid - 1M followers', '1M plays'),
        _discoverItem('Pray', 'Wizkid - 1M followers', '1M plays'),
        _discoverItem('Essence', 'Wizkid, Tems', '120k plays'),
        _discoverItem('Peace be unto you', 'Asake - 1M followers', '120k plays'),
      ],
    );
  }

  Widget _discoverItem(String title, String artist, String plays) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        color: Colors.grey[800], // Placeholder for image
      ),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text('$artist\n$plays', style: TextStyle(color: Colors.grey)),
      trailing: Icon(Icons.more_vert, color: Colors.white),
    );
  }

  Widget _buildRecommendedList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          final items = [
            ['Essence', 'Wizkid, Tems'],
            ['Peace be unto you', 'Asake'],
            ['Prophesy', 'Olamide']
          ];
          return _recommendedItem(items[index][0], items[index][1]);
        },
      ),
    );
  }


  Widget _recommendedItem(String title, String artist) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          color: Colors.grey[800],
        ),
        SizedBox(height: 5),
        Text(title, style: TextStyle(color: Colors.white)),
        Text(artist, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildPlaylistList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          final items = [
            ['Good old days', 'Wizkid, Asake, Burnaboy'],
            ['Work Mood', 'Tems, Wizkid'],
            ['Hope', 'Olamide, Davido']
          ];
          return _playlistItem(items[index][0], items[index][1]);
        },
      ),
    );
  }

  Widget _playlistItem(String title, String artists) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          color: Colors.grey[800],
        ),
        SizedBox(height: 5),
        Text(title, style: TextStyle(color: Colors.white)),
        Text(artists, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildArtistsList() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _artistItem('Burnaboy', '1M followers'),
        _artistItem('Davido', '1.9M followers'),
        _artistItem('Tems', '999k followers'),
      ],
    );
  }

  Widget _artistItem(String name, String followers) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[800],
        ),
        SizedBox(height: 5),
        Text(name, style: TextStyle(color: Colors.white)),
        Text(followers, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildCuratedPlaylists() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          final items = [
            ['Ayó (Joy)', 'Soundhive - 12 songs'],
            ['I told them', 'Soundhive - 12 songs'],
            ['Yawa dey', 'Soundhive']
          ];
          return _playlistItem(items[index][0], items[index][1]);
        },
      ),
    );
  }

}