import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';

class IncomingCallScreen extends ConsumerWidget {
  final CallModel call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Incoming ${call.callType == CallType.video ? 'Video' : 'Audio'} Call',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      call.callType == CallType.video
                          ? Icons.videocam
                          : Icons.phone,
                      color: Colors.white,
                      size: 40,
                    ),
                  ],
                ),
              ),

              // Caller Info
              Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: call.userProfilePicture != null
                        ? NetworkImage(call.userProfilePicture!)
                        : null,
                    child: call.userProfilePicture == null
                        ? const Icon(Icons.person,
                            size: 60, color: Colors.white54)
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Caller Name
                  Text(
                    call.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Ringing Status
                  const Text(
                    'Ringing...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              // Call Actions
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject Button
                    _CallActionButton(
                      icon: Icons.call_end,
                      label: 'Decline',
                      color: Colors.red,
                      onPressed: () {
                        ref.read(callProvider.notifier).rejectCall();
                        Navigator.pop(context);
                      },
                    ),

                    // Accept Button
                    _CallActionButton(
                      icon: Icons.call,
                      label: 'Accept',
                      color: Colors.green,
                      onPressed: () async {
                        await ref.read(callProvider.notifier).acceptCall();

                        // Navigate to active call screen
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveCallScreen(call: call),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 35),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

