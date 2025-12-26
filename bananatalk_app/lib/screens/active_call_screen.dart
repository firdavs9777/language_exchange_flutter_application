import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final CallModel call;

  const ActiveCallScreen({super.key, required this.call});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();

    // Setup call ended callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callProvider.notifier).setCallEndedCallback((call) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final callNotifier = ref.read(callProvider.notifier);
    final webrtcService = callNotifier.callManager.webrtcService;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Remote Video (Full Screen)
              if (widget.call.callType == CallType.video)
                Positioned.fill(
                  child: RTCVideoView(
                    webrtcService.remoteRenderer,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                )
              else
                // Audio call - show user info
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: widget.call.userProfilePicture != null
                            ? NetworkImage(widget.call.userProfilePicture!)
                            : null,
                        child: widget.call.userProfilePicture == null
                            ? const Icon(Icons.person,
                                size: 80, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        widget.call.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _getCallStatusText(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              // Local Video (Picture in Picture)
              if (widget.call.callType == CallType.video)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RTCVideoView(
                        webrtcService.localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.call.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _getCallStatusText(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        widget.call.callType == CallType.video
                            ? Icons.videocam
                            : Icons.phone,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute/Unmute
                      _ControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        onPressed: () {
                          setState(() => _isMuted = !_isMuted);
                          callNotifier.toggleMute();
                        },
                        backgroundColor:
                            _isMuted ? Colors.white : Colors.white24,
                        iconColor: _isMuted ? Colors.black : Colors.white,
                      ),

                      // End Call
                      _ControlButton(
                        icon: Icons.call_end,
                        label: 'End',
                        onPressed: () {
                          callNotifier.endCall();
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        backgroundColor: Colors.red,
                        iconColor: Colors.white,
                        size: 65,
                      ),

                      // Video Toggle (only for video calls)
                      if (widget.call.callType == CallType.video)
                        _ControlButton(
                          icon: _isVideoEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          label:
                              _isVideoEnabled ? 'Stop Video' : 'Start Video',
                          onPressed: () {
                            setState(() => _isVideoEnabled = !_isVideoEnabled);
                            callNotifier.toggleVideo();
                          },
                          backgroundColor:
                              _isVideoEnabled ? Colors.white24 : Colors.white,
                          iconColor:
                              _isVideoEnabled ? Colors.white : Colors.black,
                        )
                      else
                        // Speaker Toggle (for audio calls)
                        _ControlButton(
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                          label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                          onPressed: () {
                            setState(() => _isSpeakerOn = !_isSpeakerOn);
                            // TODO: Implement speaker toggle
                          },
                          backgroundColor:
                              _isSpeakerOn ? Colors.white : Colors.white24,
                          iconColor: _isSpeakerOn ? Colors.black : Colors.white,
                        ),
                    ],
                  ),
                ),
              ),

              // Switch Camera Button (video calls only)
              if (widget.call.callType == CallType.video)
                Positioned(
                  bottom: 150,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: () {
                      callNotifier.switchCamera();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCallStatusText() {
    final call = widget.call;

    switch (call.status) {
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return 'Connected';
      default:
        return '';
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 55,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor),
            iconSize: size * 0.5,
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

