import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call_manager.dart'
    show CallUiState, CallQuality;
import 'package:bananatalk_app/widgets/call/call_duration_timer.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final CallModel call;

  const ActiveCallScreen({super.key, required this.call});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  late bool _isSpeakerOn;
  DateTime? _connectedTime;
  bool _isPeerMuted = false;
  bool _isEnding = false;
  bool _callEnded = false;
  CallUiState _connState = CallUiState.ringing;
  CallQuality _quality = CallQuality.good;
  int? _durationWarningRemaining; // seconds remaining when warning fires

  @override
  void initState() {
    super.initState();
    // Default: speaker ON for video calls, OFF for audio calls
    _isSpeakerOn = widget.call.callType == CallType.video;

    // Check if call is already connected
    if (widget.call.status == CallStatus.connected) {
      _connectedTime = DateTime.now();
    }

    // Setup call ended callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callProvider.notifier).setCallEndedCallback((call) {
        if (mounted) {
          setState(() {
            _callEnded = true;
            _isEnding = true;
          });
        }
        // Brief delay so user sees "Call ended" before screen closes
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      });

      // Setup callback to track when call connects
      ref.read(callProvider.notifier).setCallAcceptedCallback((call) {
        if (mounted && call.status == CallStatus.connected && _connectedTime == null) {
          setState(() => _connectedTime = DateTime.now());
        }
      });

      // Wire up onCallConnected — this fires when remote stream arrives
      ref.read(callProvider.notifier).setCallConnectedCallback((call) {
        if (mounted && _connectedTime == null) {
          debugPrint('📞 ActiveCallScreen: call connected, starting timer');
          setState(() => _connectedTime = DateTime.now());
        }
      });

      // Listen for connection state changes
      ref.read(callProvider.notifier).setConnectionStateCallback((state) {
        if (mounted) {
          setState(() => _connState = state);
        }
      });

      // Listen for call quality changes
      ref.read(callProvider.notifier).setCallQualityCallback((quality) {
        if (mounted) {
          setState(() => _quality = quality);
        }
      });

      // Listen for call duration warning (1 min remaining)
      ref.read(callProvider.notifier).setCallDurationWarningCallback((remaining) {
        if (mounted) {
          setState(() => _durationWarningRemaining = remaining);
          // Auto-hide after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) setState(() => _durationWarningRemaining = null);
          });
        }
      });

      // Listen for call duration limit reached
      ref.read(callProvider.notifier).setCallDurationLimitCallback(() {
        // Call will be ended by CallManager — onCallEnded handles navigation
      });

      // Listen for peer mute state
      final callManager = ref.read(callProvider.notifier).callManager;
      callManager.onPeerMuteChanged = (isMuted) {
        if (mounted) {
          setState(() => _isPeerMuted = isMuted);
        }
      };

      // Watch for status changes (fallback)
      ref.listenManual(callProvider, (previous, next) {
        if (next?.currentCall?.status == CallStatus.connected && _connectedTime == null) {
          setState(() => _connectedTime = DateTime.now());
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              if (widget.call.callType == CallType.video && !_isEnding && !webrtcService.isDisposed)
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
                      _buildCallStatus(l10n),
                    ],
                  ),
                ),

              // Local Video (Picture in Picture)
              if (widget.call.callType == CallType.video && !_isEnding && !webrtcService.isDisposed)
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
                          _buildCallStatus(l10n),
                        ],
                      ),
                      Row(
                        children: [
                          // Signal quality indicator
                          if (_connectedTime != null && !_callEnded)
                            _buildQualityIndicator(),
                          const SizedBox(width: 8),
                          Icon(
                            widget.call.callType == CallType.video
                                ? Icons.videocam
                                : Icons.phone,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
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
                        label: _isMuted ? l10n.unmuteCall : l10n.muteCall,
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
                        label: l10n.endCall,
                        onPressed: () {
                          if (_isEnding) return; // Prevent double tap
                          setState(() => _isEnding = true);
                          callNotifier.endCall();
                          // Don't pop here — onCallEnded callback handles it
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
                              _isVideoEnabled ? l10n.videoOff : l10n.videoOn,
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
                          label: _isSpeakerOn ? l10n.speakerOn : l10n.speakerOff,
                          onPressed: () {
                            callNotifier.toggleSpeaker();
                            setState(() => _isSpeakerOn = !_isSpeakerOn);
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
              if (widget.call.callType == CallType.video && !_isEnding && !webrtcService.isDisposed)
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

              // Reconnecting banner
              if (_connState == CallUiState.reconnecting)
                Positioned(
                  top: 80,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Reconnecting...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

              // Duration limit warning banner (1 min remaining)
              if (_durationWarningRemaining != null)
                Positioned(
                  top: _connState == CallUiState.reconnecting ? 130 : 80,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_durationWarningRemaining! ~/ 60}:${(_durationWarningRemaining! % 60).toString().padLeft(2, '0')} remaining — Upgrade to VIP for unlimited calls',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Peer muted indicator
              if (_isPeerMuted && _connectedTime != null)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_off, color: Colors.white70, size: 16),
                          SizedBox(width: 4),
                          Text('Muted', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallStatus(AppLocalizations l10n) {
    if (_callEnded) {
      return Text(
        l10n.endCall,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    if (_connState == CallUiState.reconnecting) {
      return const Text(
        'Reconnecting...',
        style: TextStyle(color: Colors.orangeAccent, fontSize: 14),
      );
    }

    if (_connState == CallUiState.poorConnection && _connectedTime != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CallDurationTimer(
            startTime: _connectedTime!,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(width: 8),
          const Text(
            'Poor Connection',
            style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
          ),
        ],
      );
    }

    if (_connectedTime != null) {
      return CallDurationTimer(
        startTime: _connectedTime!,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    if (_connState == CallUiState.connecting) {
      return const Text(
        'Connecting...',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    return Text(
      l10n.callRinging,
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
  }

  Widget _buildQualityIndicator() {
    Color color;
    int bars;
    switch (_quality) {
      case CallQuality.good:
        color = Colors.green;
        bars = 3;
        break;
      case CallQuality.fair:
        color = Colors.orange;
        bars = 2;
        break;
      case CallQuality.poor:
        color = Colors.red;
        bars = 1;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final height = 6.0 + (i * 4);
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: i < bars ? color : Colors.white24,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
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

