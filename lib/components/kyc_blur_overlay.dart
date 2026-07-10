import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/model/user_model.dart';

class KycBlurOverlay extends StatelessWidget {
  final bool showBlur;
  final MemberCreatorResponse user; // Replace 'dynamic' with your actual User data model type if possible
  final VoidCallback onVerifyPressed;

  const KycBlurOverlay({
    super.key,
    required this.showBlur,
    required this.user,
    required this.onVerifyPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBlur) return const SizedBox.shrink();

    final creator = user.user?.creator;

    // Determine if the user needs to complete KYC or if they are just under review
    final bool needsVerification = creator == null ||
        creator.hasVerifiedIdentity == false ||
        creator.hasVerifiedCreativeProfile == false;

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  needsVerification
                      ? "Complete your KYC so as to enjoy full cre8hive economy"
                      : "Your account is under review",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                if (needsVerification)
                  RoundedButton(
                    title: 'Verify my identity',
                    onPressed: onVerifyPressed,
                    color: const Color(0xFF4D3490),
                    borderWidth: 0,
                    borderRadius: 12.0,
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}