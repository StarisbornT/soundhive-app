import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/creator/profile/verify_business_screen.dart';
import 'package:soundhive2/screens/creator/profile/verify_identity.dart';

import '../../../components/widgets.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import 'creative_form_screen.dart';
import 'live_test_intro_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const SetupScreen({super.key, required this.user});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  static const _backgroundColor = Color(0xFF0C0513);
  static const _textColor = Colors.white;
  static const _subtitleColor = Color(0xFFB0B0B6);
  static const _cardBgColor = Color(0xFF3B2C42);
  static const _successColor = Color(0xFF4CAF50);
  static const _warningColor = Colors.amber;
  static const _errorColor = Colors.red;

  static const _horizontalPadding = 20.0;
  static const _verticalPadding = 10.0;
  static const _spacingSmall = 8.0;
  static const _spacingMedium = 16.0;
  static const _spacingLarge = 25.0;

  late final _user = widget.user.user;
  late final _creator = _user?.creator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: _verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: _spacingLarge),
            ..._buildCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(),
        SizedBox(height: 10),
        Text(
          'Creator Verification & Access Setup',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: _textColor,
          ),
        ),
        SizedBox(height: _spacingSmall),
        Text(
          'To fully access CreateHive as a creator and investor, we need to verify your identity and creator details.'
   ' Completing the steps below helps us keep the platform secure, build trust, and unlock earnings, investments, and withdrawals.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCards() {
    final cards = [
      _buildVerificationCard(),
      if (_creator?.role != "BUSINESS") ...[
        const SizedBox(height: _spacingMedium),
        _buildLivelinessCard(),
      ],
      const SizedBox(height: _spacingMedium),
      _buildKYCCard(),
    ];

    return cards;
  }

  Widget _buildVerificationCard() {
    final hasVerifiedIdentity = _creator?.hasVerifiedIdentity == true;
    final isBusiness = _creator?.role == "BUSINESS";
    final isVerified = hasVerifiedIdentity;

    return _SetupCard(
      icon: Icons.person_2_outlined,
      title: 'Identity & KYC Verification',
      subtitle:
      'Verify your identity to unlock earnings, withdrawals, and investment access.'
     ' This includes submitting your BVN or NIN, a government-issued ID, and proof of address where required.',
      status: isVerified ? 'Under review' : 'Not submitted',
      statusColor: isVerified ? _warningColor : _errorColor,
      onTap: !isVerified
          ? () => _navigateToVerification(isBusiness)
          : null,
    );
  }

  Widget _buildLivelinessCard() {
    final hasLiveTest = _creator?.hasLiveTest == true;

    return _SetupCard(
      icon: Icons.person_2_outlined,
      title: 'Liveliness Check',
      subtitle:
      'Complete a quick live photo check to confirm you are the rightful account owner.'
     ' This helps prevent impersonation and protects creators and investors on the platform.',
      status: hasLiveTest ? 'Completed' : 'Not submitted',
      statusColor: hasLiveTest ? _successColor : _errorColor,
      onTap: () => _handleLivelinessTap(),
    );
  }

  Widget _buildKYCCard() {
    final hasVerifiedCreativeProfile = _creator?.hasVerifiedCreativeProfile == true;
    final status = !hasVerifiedCreativeProfile ? 'Not submitted' : 'Under review';
    final statusColor = !hasVerifiedCreativeProfile ? _errorColor : _warningColor;

    return _SetupCard(
      icon: Icons.work_outline,
      title: 'Creator / Business Profile Setup',
      subtitle:
      'Share details about your creative service or business.'
      'Add your service category, offerings, pricing, and basic business information to help users discover and book you.',
      status: status,
      statusColor: statusColor,
      onTap: () => !hasVerifiedCreativeProfile ? _handleKYCTap() : null,
    );
  }

  void _navigateToVerification(bool isBusiness) {
    final user = _user;
    if (user == null) return;

    final route = isBusiness
        ? MaterialPageRoute(builder: (_) => VerifyBusinessScreen(user: user))
        : MaterialPageRoute(builder: (_) => VerifyIdentity(user: user));

    Navigator.push(context, route);
  }

  void _handleLivelinessTap() {
    if (_creator?.hasVerifiedIdentity == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveTestIntroScreen()),
      );
    } else {
      _showVerificationRequiredAlert();
    }
  }

  void _handleKYCTap() {
    final creator = _creator;

    if (creator == null) {
      _showVerificationRequiredAlert();
      return;
    }

    // Identity verification is mandatory for everyone
    if (creator.hasVerifiedIdentity != true) {
      _showVerificationRequiredAlert();
      return;
    }

    // Business creators do NOT require live test
    if (creator.role == "BUSINESS") {
      _navigateToCreativeForm();
      return;
    }

    // Non-business creators MUST have live test completed
    if (creator.hasLiveTest == true) {
      _navigateToCreativeForm();
    } else {
      _showVerificationRequiredAlert();
    }
  }


  void _navigateToCreativeForm() {
    final user = _user;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreativeFormScreen(user: user)),
    );
  }

  void _showVerificationRequiredAlert() {
    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: 'Please verify account before setting up creative profile',
    );
  }
}

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final VoidCallback? onTap;

  const _SetupCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DashedBorderBox(
        bgColor: _SetupScreenState._backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: _SetupScreenState._textColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _SetupScreenState._subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _SetupScreenState._cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: statusColor, fontSize: 8),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new,
        color: Color(0xFFB0B0B6),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }
}
