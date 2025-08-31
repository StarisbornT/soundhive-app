import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/creator/profile/verify_identity.dart';

import '../../../components/widgets.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import 'creative_form_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const SetupScreen({super.key, required this.user});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0513),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back arrow
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFB0B0B6)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),

              // Title
              const Text(
                'Setup your creative profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'After completing the information below, it gets reviewed by '
                    'soundhive, and after that your account would be good to go!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 25),

              // First card
              _buildDashedCard(
                  icon: Icons.person_2_outlined,
                  title: 'Verify your account',
                  subtitle:
                  'We want to know you in more detail, kindly provide your BVN, NIN, a government issued ID and utility bill.',
                  status: widget.user.user?.creator != null
                      ? 'Under review'
                      : 'Not submitted',
                  statusColor: widget.user.user?.creator != null
                      ? Colors.amber
                      : Colors.red,
                  onTap:
                    widget.user.user?.creator == null ? () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyIdentity(user: widget.user.user!,)));
                    }: null
              ),

              const SizedBox(height: 16),

              // Second card
              _buildDashedCard(
                  icon: Icons.work_outline,
                  title: 'Creative profile setup',
                  subtitle:
                  'Let us know what you can do, the projects you have done over time and how much you charge.',
                status: widget.user.user?.creator == null
                    ? 'Not submitted'
                    : (widget.user.user!.creator!.active == true
                    ? 'Active'
                    : 'Not submitted'),

                statusColor: widget.user.user?.creator == null
                    ? Colors.red
                    : (widget.user.user!.creator!.active == true
                    ? Colors.amber
                    : Colors.red),
                onTap: () {
                    if(widget.user.user?.creator != null) {
                      if (!(widget.user.user?.creator?.active ?? false)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreativeFormScreen()),
                        );
                      }

                    }else {
                      showCustomAlert(
                        context: context,
                        isSuccess: false,
                        title: 'Error',
                        message: "Please verify account before setting up creative profile",
                      );
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyIdentity(user: widget.user.member!,)));
                    }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DashedBorderBox(
        bgColor: Color(0xFF0C0513),
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
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B2C42),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFB0B0B6),
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
}
