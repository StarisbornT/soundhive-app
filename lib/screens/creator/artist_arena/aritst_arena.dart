import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../model/user_model.dart';
import 'create_artist_profile.dart';
const Color _kGradientBaseColor = Color(0xFF0C051F);

class ArtistArena extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const ArtistArena({super.key, required this.user});

  @override
  ConsumerState<ArtistArena> createState() => _ArtistArenaState();
}

class _ArtistArenaState extends ConsumerState<ArtistArena> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
     
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // 1. Background Fade/Gradient (Simulated)
          Container(
            height: screenHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kGradientBaseColor,
                  _kGradientBaseColor,
                  Colors.transparent,
                ],
                stops: [
                  0.1252, // 12.52%
                  0.3254, // 32.54%
                  1.0,    // 100%
                ],
              ),
            ),
          ),


          // 2. Main Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: const Text(
                    'Artist Arena',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Flexible space to push the main content down
                const Spacer(),

                // The Central Graphic (Musical Note/CD)
                // Using a custom widget to mimic the complex graphic
                const _MusicGraphic(),

                const SizedBox(height: 40),

                // "No published songs" text
                const Text(
                  'No published songs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtext
                const Text(
                  'You have not published any song on\nSoundhive yet.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Flexible space to push the button to the bottom
                const Spacer(),

                // "Add new song" Button
                RoundedButton(
                    title: 'Setup Profile', onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  CreateArtistProfile(user: widget.user.user!),
                    ),
                  );
                },
                  borderWidth: 0,
                  color: AppColors.PRIMARYCOLOR,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A custom widget to better mimic the complex note/CD graphic
class _MusicGraphic extends StatelessWidget {
  const _MusicGraphic();

  @override
  Widget build(BuildContext context) {
    // NOTE: For the exact graphic from the image, you would use a custom SVG
    // or image asset. This is a simplified version using an Icon to demonstrate
    // the positioning and purple color/opacity.

    return const Stack(
      alignment: Alignment.center,
      children: [
        // A placeholder for the CD part (circular shape)
        Icon(
          Icons.album,
          color: Color(0xFF5D317D), // A darker, metallic purple
          size: 140,
        ),
        // The musical note part (faded purple)
        Icon(
          Icons.music_note,
          color: Color(0xFFC792E8), // A lighter, more translucent purple
          size: 160,
        ),
      ],
    );
  }
}