import 'package:flutter/material.dart';

class LogoLoader extends StatefulWidget {
  final String logoPath;
  final double size;

  const LogoLoader({
    Key? key,
    required this.logoPath,
    this.size = 100.0,
  }) : super(key: key);

  @override
  _LogoLoaderState createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1), // 1 full rotation in 1 second
      vsync: this,
    )..repeat(); // Repeats infinitely
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular loader behind the logo
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.grey, // Customize the color
            ),
          ),
          // Rotating logo
          Container(
            width: widget.size - 20, // Slightly smaller than the loader
            height: widget.size - 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(widget.logoPath),
            ),
          ),
        ],
      ),
    );
  }
}
