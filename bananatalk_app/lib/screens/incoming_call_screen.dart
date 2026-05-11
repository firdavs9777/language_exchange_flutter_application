import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/services/call_manager.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Incoming-call ring screen.
///
/// Step 8 / B5: accept/decline buttons delegate to [CallManager] directly
/// (the LiveKit-aware B3 implementation). The token to join the room is
/// already on `currentCall.livekitToken` when FCM delivered it; if not,
/// [CallManager.acceptCall] mints a fresh one via `POST /calls/:id/accept`.
/// No pre-screen ICE-server fetch happens any more.
class IncomingCallScreen extends ConsumerWidget {
  final CallModel call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isVideo = call.callType == CallType.video;

    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header — prominent call-type label + icon
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      isVideo
                          ? l10n.incomingVideoCall
                          : l10n.incomingAudioCall,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      isVideo ? Icons.videocam : Icons.phone,
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
                  const SizedBox(height: 6),

                  // Call type subtitle (e.g. "Video Call" / "Audio Call")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.phone,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isVideo ? l10n.videoCall : l10n.audioCall,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Ringing Status
                  Text(
                    l10n.callRinging,
                    style: const TextStyle(
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
                    // Reject Button — delegate to CallManager (B3).
                    _CallActionButton(
                      icon: Icons.call_end,
                      label: l10n.declineCall,
                      color: Colors.red,
                      onPressed: () {
                        CallManager().rejectCall();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),

                    // Accept Button — delegate to CallManager.acceptCall()
                    // (B3). The LiveKit token is on `call.livekitToken`
                    // (FCM-delivered) or will be re-minted by /accept.
                    _CallActionButton(
                      icon: Icons.call,
                      label: l10n.acceptCall,
                      color: Colors.green,
                      onPressed: () async {
                        // Carry over the VIP flag so the duration limit logic
                        // inside CallManager stays correct.
                        final authState = ref.read(authServiceProvider);
                        final currentUserId = authState.userId;
                        final isVip = ref.read(isVipProvider(currentUserId));
                        CallManager().setVipCall(isVip);

                        try {
                          await CallManager().acceptCall();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to accept call: $e')),
                            );
                            Navigator.pop(context);
                          }
                          return;
                        }

                        final accepted = CallManager().currentCall;
                        if (!context.mounted) return;

                        // If acceptCall tore the call down (permissions
                        // denied, server error), bail out.
                        if (accepted == null) {
                          Navigator.pop(context);
                          return;
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveCallScreen(call: accepted),
                          ),
                        );
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
