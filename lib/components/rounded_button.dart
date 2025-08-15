import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String title;

  final VoidCallback? onPressed;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double minWidth;
  final double height;
  final bool isBusy;
  final Color? color;

  final Color textColor;
  final Icon? icon;

  RoundedButton({
    required this.title,
    required this.onPressed,
    this.isBusy = false,
    this.color,
    this.borderColor = Colors.black,
    this.borderWidth = 2.0,
    this.borderRadius = 100.0,
    this.minWidth = 200.0,
    this.height = 42.0,
    this.textColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          elevation: 0.0, // No shadow
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: MaterialButton(
            onPressed: onPressed,
            minWidth: minWidth,
            height: height,
            child: Center(
              child: Container(
                width: minWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) icon!,
                    if (icon != null) SizedBox(width: 8.0),
                    if (!isBusy)
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                        ),
                      )
                    else
                      CircularProgressIndicator(
                        strokeWidth: 5,
                        valueColor: AlwaysStoppedAnimation(textColor),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
