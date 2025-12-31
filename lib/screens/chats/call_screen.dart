import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/call_provider.dart';

class AudioCallScreen extends ConsumerWidget {
  final VoidCallback onEndCall;
  final Map<String, dynamic>? callerData;

  const AudioCallScreen({
    super.key,
    required this.onEndCall,
    this.callerData,
  });

  String get callerName {
    if (callerData?['caller_name'] != null) {
      return callerData!['caller_name'];
    }
    if (callerData?['caller'] != null) {
      final caller = callerData!['caller'];
      return '${caller['first_name'] ?? ''} ${caller['last_name'] ?? ''}'.trim();
    }
    return 'Unknown User';
  }

  String get callerRole {
    if (callerData?['caller'] != null) {
      final caller = callerData!['caller'];
      return caller['role'] ?? 'Service Provider';
    }
    return 'Service Provider';
  }

  String? get imageUrl {
    if (callerData?['caller'] != null) {
      final caller = callerData!['caller'];
      return caller['image'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(audioCallProvider);
    final callNotifier = ref.read(audioCallProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (callState.status == CallStatus.ended || callState.status == CallStatus.failed) {
        Future.delayed(Duration.zero, () {
          onEndCall();
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A191E),
      body: SafeArea(
        child: Column(
          children: [
            // Top status bar area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Calling',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 48), // For symmetry
                ],
              ),
            ),

            // User profile section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile image
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 3,
                      ),
                    ),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      ),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        color: _getAvatarColor(callerName), // Generate color from name
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(callerName), // Get first letter(s)
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User name
                  Text(
                    callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // User role/title - Format the role to be more readable
                  Text(
                    _formatRole(callerRole),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Call status text
                  Text(
                    _getCallStatusText(callState.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Call duration
                  if (callState.status == CallStatus.connected)
                    Consumer(
                      builder: (context, ref, child) {
                        final callState = ref.watch(audioCallProvider);
                        return Text(
                          callState.callDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Call controls section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _CallControlButton(
                    icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    backgroundColor: callState.isMuted ? Colors.red : const Color(0xFF4D3490),
                    onPressed: () => callNotifier.toggleMute(),
                  ),

                  // End call button (larger)
                  Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.call_end, color: Colors.white, size: 35),
                          onPressed: onEndCall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'End call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Speaker button
                  _CallControlButton(
                    icon: callState.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    label: 'Speaker',
                    backgroundColor: callState.isSpeakerOn ? Colors.green : const Color(0xFF4D3490),
                    onPressed: () => callNotifier.toggleSpeaker(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCallStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.calling:
        return 'Calling...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call Ended';
      case CallStatus.failed:
        return 'Call Failed';
      default:
        return '';
    }
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      // Get first letter of first and last name
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    } else if (parts.length == 1) {
      // Get first letter of single name
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

// Helper method to generate a consistent color from the name
  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.grey;

    // Use a simple hash to generate a consistent color
    final hash = name.codeUnits.fold(0, (int a, int b) => a + b);

    // List of nice avatar colors
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];

    return colors[hash % colors.length];
  }

  String _formatRole(String role) {
    // Format the role to be more readable
    switch (role.toUpperCase()) {
      case 'CREATOR':
        return 'Content Creator';
      case 'SERVICE_PROVIDER':
      case 'PROVIDER':
        return 'Service Provider';
      case 'USER':
        return 'User';
      default:
        return role;
    }
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}