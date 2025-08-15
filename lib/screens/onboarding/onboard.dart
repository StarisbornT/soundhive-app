import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundhive2/screens/auth/create_account.dart';

import '../auth/identity_screen.dart';
import '../auth/login.dart';

class Onboard extends StatefulWidget {
  const Onboard({super.key});
  static String id = 'onboard_screen';

  @override
  State<Onboard> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<Onboard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;

  final List<Map<String, String>> slides = [
    {
      'title': 'Get paid for listening to your Favourite Artists',
      'subtitle': 'Get access to a list of inspiring songs from artists you love and get paid for it',
      'image': 'images/intro1.png',
    },
    {
      'title': 'Sing your heart out with Soundhive',
      'subtitle': 'With Soundhive you get to unleash your inner rockstar talent',
      'image': 'images/intro2.png',
    },
    {
      'title': 'Invest in specially curated projects and artists',
      'subtitle': 'Get the chance to invest in upcoming talents as well as events, and earn high returns',
      'image': 'images/intro3.png',
    },
    {
      'title': 'Buy and Sell your services and digital assets',
      'subtitle': 'Make extra income by selling your services and assets on Soundhive',
      'image': 'images/intro4.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: slides.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    slides[index]['image']!,
                    fit: BoxFit.cover,
                  ),
                  // Gradient Fade before buttons
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    top: MediaQuery.of(context).size.height * 0.4, // Start fading from title area
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,   // Fades downward
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF0C051F),  // Solid at the title area
                            const Color(0xFF0C051F),  // Gradually transitions
                            const Color(0x03000000),  // Fully fades at the bottom
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Progress Bar
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              children: List.generate(
                slides.length,
                    (index) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentPage ? Color(0xFF4D3490) : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Logo
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('images/logo.png', height: 24),
                  const SizedBox(width: 3),
                  const Text(
                    'oundhive',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Nohemi',
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Text & Buttons
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  slides[_currentPage]['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nohemi',
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  slides[_currentPage]['subtitle']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nohemi',
                    fontWeight: FontWeight.w300,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                _buildButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, IdentityScreen.id);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF6A49F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                'Create account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, Login.id);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                'Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
