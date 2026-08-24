import 'package:flutter/material.dart';

/// Placeholder destination for "Listen to snippets / Artist mixtape".
///
/// Song upload + snippet playback (the real mixtape experience) is a
/// phase-two feature — there is no backend support for it yet (no
/// snippet upload endpoint, no per-artist snippet list). Rather than
/// disable the entry point entirely, tapping it takes the user here so
/// they know the feature exists and is on the way, instead of the button
/// silently doing nothing or being hidden.
///
/// Intentionally generic/reusable: takes an optional [artistName] and
/// [featureLabel] so the same screen can back other "phase two" entry
/// points later without copy/pasting a new screen each time.
class MixtapeComingSoonScreen extends StatelessWidget {
  static const String id = '/mixtapecomingsoon';

  final String? artistName;
  final String featureLabel;

  const MixtapeComingSoonScreen({
    super.key,
    this.artistName,
    this.featureLabel = 'Artist mixtape & snippets',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C051F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.withOpacity(0.15),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: Colors.purpleAccent,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      featureLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'COMING SOON',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      artistName != null && artistName!.isNotEmpty
                          ? "We're building song uploads and snippet playback so you can hear more from $artistName before you invest. Check back soon."
                          : "We're building song uploads and snippet playback so you can hear more from the artist before you invest. Check back soon.",
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4D3490)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}