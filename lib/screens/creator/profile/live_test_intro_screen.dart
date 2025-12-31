import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/creator/profile/liveliness_check_screen.dart';
import 'package:soundhive2/utils/app_colors.dart';

class LiveTestIntroScreen extends ConsumerStatefulWidget {
  const LiveTestIntroScreen({super.key});

  @override
  ConsumerState<LiveTestIntroScreen> createState() =>
      _LiveTestIntroScreenState();
}

class _LiveTestIntroScreenState
    extends ConsumerState<LiveTestIntroScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
         color: AppColors.BACKGROUNDCOLOR
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFB0B0B6)),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 20),

                /// Title
                const Text(
                  "Liveliness Check",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                /// Subtitle
                const Text(
                  "Kindly note the instructions below before you proceed.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                /// Face placeholder
                Center(
                  child: Container(
                    width: size.width * 0.45,
                    height: size.width * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 120,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                /// Instructions title
                const Text(
                  "Things to note before you begin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                /// Instruction list
                _instructionItem(
                  1,
                  "Ensure you are in a well-lit or bright environment.",
                ),
                _instructionItem(
                  2,
                  "Remove all head coverings and eye-glasses.",
                ),
                _instructionItem(
                  3,
                  "Ensure your face is clear and inside the capture area.",
                ),

                const Spacer(),

                /// Continue button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LivelinessCheckScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F4AE8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _instructionItem(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$index.",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
