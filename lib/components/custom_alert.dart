import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:soundhive2/components/rounded_button.dart';

class CustomAlert extends StatelessWidget {
  final String title;
  final String message;
  final String? iconPath;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onClose;

  const CustomAlert({
    Key? key,
    required this.title,
    required this.message,
    this.iconPath,
    required this.backgroundColor,
    required this.textColor,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GifView.asset(
              iconPath ?? '',
              height: 60,
              width: 60,
              frameRate: 30, // default is 15 FPS
            ),
            // Image.asset(iconPath ?? '', width: 60, height: 60), // Display success/error icon
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            RoundedButton(
              title: 'Close',
              onPressed: onClose,
              borderWidth: 0,
            )
          ],
        ),
      ),
    );
  }
}
