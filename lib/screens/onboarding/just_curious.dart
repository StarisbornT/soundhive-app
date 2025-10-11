import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:soundhive2/screens/non_creator/non_creator.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../lib/navigator_provider.dart';
import '../non_creator/marketplace/creators_list.dart';
import '../non_creator/streaming/preference.dart';

class JustCurious extends ConsumerStatefulWidget {
  static String id = 'just_curious';
  final FlutterSecureStorage storage;
  final Dio dio;
  const JustCurious({super.key, required this.storage, required this.dio});

  @override
  ConsumerState<JustCurious> createState() => _JustCuriousState();
}

class _JustCuriousState extends ConsumerState<JustCurious> {
  void _showCre8paySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more than half the screen
      backgroundColor: Colors.transparent, // Important to show the custom rounded container
      builder: (BuildContext context) {
        return const Cre8payComingSoonBottomSheet();
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Utils.logo(),
              ),
              const SizedBox(height: 30),

              // Title
              const Text(
                "One last thing....",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "We are just curious....",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "What is the first thing you want to do?",
                style: TextStyle(
                  color: Color(0xFFF2F2F2),
                  fontSize: 14.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Options grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _buildOptionCard(
                      icon: FontAwesomeIcons.store,
                      text: "Explore Hives",
                      color: const Color.fromRGBO(234, 208, 255, 0.1),
                      backgroundImage: "images/c4.png",
                      onTap: () {
                        print("Access services tapped");
                      },
                    ),
                    _buildOptionCard(
                      icon: FontAwesomeIcons.userGroup,
                      text: "Find Creators",
                      color: const Color.fromRGBO(255, 179, 150, 0.1),
                      backgroundImage: "images/c3.png",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreatorsList(),
                          ),
                        );
                      },
                    ),
                    _buildOptionCard(
                      icon: FontAwesomeIcons.chartLine,
                      text: "View Investment Opportunities",
                      color: const Color.fromRGBO(193, 255, 196, 0.1),
                      backgroundImage: "images/c1.png",
                      onTap: () {
                        Navigator.pushNamed(context, NonCreatorDashboard.id).then((_) {
                          ref.read(bottomNavigationProvider.notifier).state = 2;
                        });
                      },
                    ),
                    _buildOptionCard(
                      icon: FontAwesomeIcons.music,
                      text: "Stream music from your favourite artists",
                      color: const Color.fromRGBO(255, 215, 151, 0.1),
                      backgroundImage: "images/c2.png",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  const PreferenceScreen(),
                          ),
                        );
                      },
                    ),
                    _buildOptionCard(
                      icon: FontAwesomeIcons.wallet,
                      text: "Cre8pay – Coming soon",
                      color: const Color.fromRGBO(141, 160, 255, 0.1),
                      backgroundImage: "images/c5.png",
                      onTap: () {
                        _showCre8paySheet(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card widget
  Widget _buildOptionCard({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    String? backgroundImage, // optional background image
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: backgroundImage != null
              ? DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          )
              : null,
          color: backgroundImage == null
              ? color.withOpacity(disabled ? 0.4 : 1)
              : null, // only apply solid color if no image
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // transparent overlay tint using your color
            color: color.withOpacity(0.3), // 👈 makes image visible but tinted
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: disabled ? FontWeight.w400 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class Cre8payComingSoonBottomSheet extends StatelessWidget {
  const Cre8payComingSoonBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final contentHeight = screenHeight * 0.55;

    return Container(
      height: contentHeight,
      decoration: const BoxDecoration(
        color: AppColors.BACKGROUNDCOLOR,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Spacer for the top handle if needed, or just padding
                const SizedBox(height: 16),

                // 1. Header: Title and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Cre8pay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // Invisible Spacer to keep title centered while Close button is present
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('images/credpay.png', height: 200,),
                        const SizedBox(height: 10),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'A multi-currency wallet solution to power your transactions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 4. "Coming soon" Text
                        const Text(
                          '(Coming soon)',
                          style: TextStyle(
                            color: Color(0xFFB0B0B6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
