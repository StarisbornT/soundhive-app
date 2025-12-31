import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/utils/app_colors.dart';

class Success extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? token; // Added token parameter
  final String? navigation;
  final String? image;
  final VoidCallback? onButtonPressed;
  final ThemeData? theme;
  final bool? isDark;

  const Success({
    required this.title,
    required this.subtitle,
    this.token,
    this.navigation,
    this.image,
    super.key,
    this.onButtonPressed,
    this.theme,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = theme ?? Theme.of(context);
    final currentIsDark = isDark ?? currentTheme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: currentIsDark
            ? const Color(0xFF070214)
            : Colors.grey[50],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Checkmark Icon
                Center(
                  child: Image.asset(
                    image ?? 'images/success_profile.png',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 30),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentTheme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),

                // Token Section (Visible only if token is provided)
                if (token != null) ...[
                  const SizedBox(height: 40),
                  Text(
                    "Electricity token",
                    style: TextStyle(
                      color: currentTheme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentIsDark
                          ? const Color(0xFF1A191E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentTheme.dividerColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            token!,
                            style: TextStyle(
                              color:
                              currentTheme.colorScheme.onSurface.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: token!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Token copied to clipboard",
                                  style: TextStyle(
                                    color: currentTheme.colorScheme.onPrimary,
                                  ),
                                ),
                                backgroundColor: AppColors.BUTTONCOLOR,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.copy_rounded,
                            color: AppColors.BUTTONCOLOR,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 60),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RoundedButton(
                    title: 'Okay, thanks',
                    color: AppColors.BUTTONCOLOR,
                    borderRadius: 30,
                    minWidth: double.infinity,
                    borderWidth: 0,
                    onPressed: () {
                      if (onButtonPressed != null) {
                        onButtonPressed!();
                      } else if (navigation != null) {
                        Navigator.pushReplacementNamed(context, navigation!);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}