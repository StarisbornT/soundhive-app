import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

class JustCurious extends StatefulWidget {
  static String id = 'just_curious';
  final FlutterSecureStorage storage;
  final Dio dio;
  const JustCurious({super.key, required this.storage, required this.dio});

  @override
  State<JustCurious> createState() => _JustCuriousState();
}

class _JustCuriousState extends State<JustCurious> {
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
                      text: "Access services and bookings",
                      color: const Color(0xFF4B0082),
                      onTap: () {
                        print("Access services tapped");
                      },
                    ),
                    _buildOptionCard(
                      icon: FontAwesomeIcons.userGroup,
                      text: "Find Creators",
                      color: const Color(0xFF8B0000),
                      onTap: () {
                        print("Find Creators tapped");
                      },
                    ),
                    _buildOptionCard(
                      icon: FontAwesomeIcons.chartLine,
                      text: "View Investment Opportunities",
                      color: const Color(0xFF006400),
                      onTap: () {
                        print("Investment tapped");
                      },
                    ),
                    _buildOptionCard(
                      icon: FontAwesomeIcons.music,
                      text: "Stream music from your favourite artists",
                      color: const Color(0xFF3D0066),
                      onTap: () {
                        print("Stream music tapped");
                      },
                    ),
                    _buildOptionCard(
                      icon: FontAwesomeIcons.wallet,
                      text: "Cre8pay – Coming soon",
                      color: Colors.grey.shade800,
                      onTap: () {},
                      disabled: true,
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
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(disabled ? 0.4 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
