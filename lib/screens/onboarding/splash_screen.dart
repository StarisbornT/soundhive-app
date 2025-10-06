import 'package:flutter/material.dart';
import 'dart:async';

import 'package:soundhive2/screens/onboarding/onboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static String id = 'loading_screen';

  @override
  State<SplashScreen> createState() => _SplashScreenScreenState();
}

class _SplashScreenScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      Navigator.pushNamed(context, Onboard.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050110),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation,
              child: Image.asset(
                'images/logo.png',
                width: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
