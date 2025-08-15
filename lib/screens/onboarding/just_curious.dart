import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:soundhive2/screens/non_creator/marketplace/marketplace.dart';
import 'package:soundhive2/screens/non_creator/non_creator.dart'; // Import Font Awesome icons

class JustCurious extends StatefulWidget {
  static String id = 'just_curious';
  final FlutterSecureStorage storage;
  final Dio dio;
  const JustCurious({super.key, required this.storage, required this.dio});

  @override
  State<JustCurious> createState() => _JustCuriousState(); // Corrected state class name
}

class _JustCuriousState extends State<JustCurious> { // Corrected state class name
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050110),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40.0), // Space from the top
              // Soundhive Logo and Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('images/logo.png', height: 28),
                  const SizedBox(width: 3),
                  const Text(
                    'Soundhive',
                    style: TextStyle(
                      fontFamily: 'Nohemi',
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30.0), // Space after logo
              // "We are just curious...." text
              const Text(
                'We are just curious....',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10.0),
              // "What is the first thing you want to do?" text
              const Text(
                'What is the first thing you want to do?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(height: 40.0), // Space before options

              // Option 1: Explore Marketplace
              _buildOptionCard(
                icon: FontAwesomeIcons.store, // Using a store icon for marketplace
                text: 'Explore Marketplace',
                onTap: () {
                  Navigator.pushNamed(context, NonCreatorDashboard.id);
                },
              ),
              const SizedBox(height: 20.0),

              // Option 2: Find Creatives
              _buildOptionCard(
                icon: FontAwesomeIcons.userPlus, // Using a group icon for creatives
                text: 'Find Creatives',
                onTap: () {
                  // Handle tap for Find Creatives
                  print('Find Creatives tapped');
                },
              ),
              const SizedBox(height: 20.0),

              // Option 3: Stream music from your favourite artists
              _buildOptionCard(
                icon: FontAwesomeIcons.music, // Using a music icon
                text: 'Stream music from your favourite artists',
                onTap: () {
                  // Handle tap for Stream music
                  print('Stream music tapped');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build each option card
  Widget _buildOptionCard({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
          border: Border.all(
            color: Colors.white38, // Light border color
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              color: Colors.white,
              size: 24.0,
            ),
            const SizedBox(width: 20.0),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}