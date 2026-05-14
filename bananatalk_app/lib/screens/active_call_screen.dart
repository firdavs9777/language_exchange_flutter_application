import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/services/call_manager.dart'
    show CallManager, CallUiState, CallQuality;
import 'package:bananatalk_app/widgets/call/call_duration_timer.dart';

/// Maximum time (s) we tolerate a transient reconnect before auto-ending the
/// call with a "Connection lost" snackbar. Matches the iOS dial-tone limit.
const int _reconnectGraceSeconds = 15;

class ActiveCallScreen extends ConsumerStatefulWidget {
  final CallModel call;

  const ActiveCallScreen({super.key, required this.call});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  late bool _isSpeakerOn;
  DateTime? _connectedTime;
  bool _isPeerMuted = false;
  bool _isPeerVideoEnabled = true;
  bool _isEnding = false;
  bool _callEnded = false;
  CallUiState _connState = CallUiState.ringing;
  CallQuality _quality = CallQuality.good;
  // Raw LiveKit quality drives the new top-right badge. Distinct from the
  // collapsed [_quality] which feeds the legacy 3-bar indicator and the
  // "Poor connection" status text.
  lk.ConnectionQuality _lkQuality = lk.ConnectionQuality.unknown;
  int? _durationWarningRemaining; // seconds remaining when warning fires
  bool _isReconnecting = false;

  // Reconnect banner — slide-down animation + 15s grace timer.
  late final AnimationController _reconnectAnimController;
  late final Animation<Offset> _reconnectSlide;
  Timer? _reconnectGraceTimer;

  /// Cached CallManager so dispose() can null out callbacks without
  /// going through `ref` (ref is invalid once ConsumerStatefulElement
  /// is being unmounted — see tutor_chat_screen for the same pattern).
  CallManager? _cachedCallManager;

  @override
  void initState() {
    super.initState();
    _cachedCallManager = ref.read(callProvider.notifier).callManager;
    // Default: speaker ON for video calls, OFF for audio calls
    _isSpeakerOn = widget.call.callType == CallType.video;
    _isVideoEnabled = widget.call.callType == CallType.video;

    _reconnectAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _reconnectSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _reconnectAnimController,
      curve: Curves.easeOut,
    ));

    // Check if call is already connected
    if (widget.call.status == CallStatus.connected) {
      _connectedTime = DateTime.now();
    }

    // Setup call ended callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callNotifier = ref.read(callProvider.notifier);
      final callManager = callNotifier.callManager;

      callNotifier.setCallEndedCallback((call) {
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
      callNotifier.setCallAcceptedCallback((call) {
        if (mounted &&
            call.status == CallStatus.connected &&
            _connectedTime == null) {
          setState(() => _connectedTime = DateTime.now());
        }
      });

      // Wire up onCallConnected — this fires when remote stream arrives
      callNotifier.setCallConnectedCallback((call) {
        if (mounted && _connectedTime == null) {
          debugPrint('📞 ActiveCallScreen: call connected, starting timer');
          setState(() => _connectedTime = DateTime.now());
        }
      });

      // Listen for connection state changes (drives reconnect banner)
      callNotifier.setConnectionStateCallback((state) {
        if (!mounted) return;
        setState(() => _connState = state);
        if (state == CallUiState.reconnecting) {
          _showReconnectBanner();
        } else {
          _hideReconnectBanner();
        }
      });

      // Listen for call quality changes (collapsed CallQuality — drives the
      // 3-bar legacy indicator + "Poor Connection" status line).
      callNotifier.setCallQualityCallback((quality) {
        if (mounted) {
          setState(() => _quality = quality);
        }
      });

      // Raw LiveKit per-peer quality — drives the top-right colored badge.
      // We hook the manager directly because the app-level CallQuality enum
      // collapses excellent+good and poor+lost into two buckets, and the badge
      // wants the finer-grained signal.
      callManager.liveKit.onConnectionQualityChanged = (q) {
        if (!mounted) return;
        setState(() => _lkQuality = q);
      };

      // Direct reconnect callbacks from CallManager (set by B3). These run in
      // parallel with [setConnectionStateCallback] above — the connection-state
      // callback updates the status-line text, while these drive the banner.
      // Both paths are idempotent.
      callManager.onPeerReconnecting = () {
        if (!mounted) return;
        setState(() => _isReconnecting = true);
        _showReconnectBanner();
      };

      callManager.onPeerReconnected = () {
        if (!mounted) return;
        setState(() => _isReconnecting = false);
        _hideReconnectBanner();
      };

      // Listen for call duration warning (1 min remaining)
      callNotifier.setCallDurationWarningCallback((remaining) {
        if (mounted) {
          setState(() => _durationWarningRemaining = remaining);
          // Auto-hide after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) setState(() => _durationWarningRemaining = null);
          });
        }
      });

      // Listen for call duration limit reached
      callNotifier.setCallDurationLimitCallback(() {
        // Call will be ended by CallManager — onCallEnded handles navigation
      });

      // Listen for peer mute state
      callManager.onPeerMuteChanged = (isMuted) {
        if (mounted) {
          setState(() => _isPeerMuted = isMuted);
        }
      };

      // Listen for peer video on/off so the remote tile rebuilds when the
      // peer toggles their camera.
      callManager.onPeerVideoChanged = (enabled) {
        if (mounted) {
          setState(() => _isPeerVideoEnabled = enabled);
        }
      };

      // Watch for status changes (fallback)
      ref.listenManual(callProvider, (previous, next) {
        if (next.currentCall?.status == CallStatus.connected &&
            _connectedTime == null) {
          setState(() => _connectedTime = DateTime.now());
        }
      });
    });
  }

  @override
  void dispose() {
    _reconnectGraceTimer?.cancel();
    // Null out the CallManager callbacks we wired directly so we don't leak
    // a closure that captures this disposed State. The provider-mediated
    // callbacks (setConnectionStateCallback, setCallQualityCallback, etc.)
    // are owned by CallNotifier and managed there.
    final callManager = _cachedCallManager;
    if (callManager != null) {
      callManager.onPeerReconnecting = null;
      callManager.onPeerReconnected = null;
      callManager.onPeerMuteChanged = null;
      callManager.onPeerVideoChanged = null;
      callManager.liveKit.onConnectionQualityChanged = null;
    }
    _reconnectAnimController.dispose();
    super.dispose();
  }

  void _showReconnectBanner() {
    _reconnectAnimController.forward();
    _reconnectGraceTimer?.cancel();
    _reconnectGraceTimer =
        Timer(const Duration(seconds: _reconnectGraceSeconds), () {
      if (!mounted) return;
      // Still reconnecting after grace window — give up on this call.
      final notifier = ref.read(callProvider.notifier);
      notifier.endCall();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection lost'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  void _hideReconnectBanner() {
    _reconnectGraceTimer?.cancel();
    _reconnectGraceTimer = null;
    _reconnectAnimController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final callNotifier = ref.read(callProvider.notifier);
    final callManager = callNotifier.callManager;
    final localTrack = callManager.liveKit.localVideoTrack;
    final remoteTrack = callManager.liveKit.remoteVideoTrack;
    final isVideoCall = widget.call.callType == CallType.video;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Remote Video (Full Screen) — for video calls when the peer's
              // camera is on and their video track is subscribed.
              if (isVideoCall && !_isEnding && _isPeerVideoEnabled &&
                  remoteTrack != null)
                Positioned.fill(
                  child: lk.VideoTrackRenderer(
                    remoteTrack,
                    fit: lk.VideoViewFit.cover,
                    mirrorMode: lk.VideoViewMirrorMode.off,
                  ),
                )
              else
                // Audio call OR remote video unavailable — show avatar/info
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

              // Local Video (Picture in Picture) — only when camera is on.
              if (isVideoCall && !_isEnding && _isVideoEnabled)
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
                      child: localTrack != null
                          ? lk.VideoTrackRenderer(
                              localTrack,
                              fit: lk.VideoViewFit.cover,
                              mirrorMode: lk.VideoViewMirrorMode.mirror,
                            )
                          : Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.videocam_off,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                size: 32,
                              ),
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
                          // Signal quality bars (legacy 3-bar indicator)
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

              // Connection-quality badge (top-right, pill)
              if (_connectedTime != null && !_callEnded)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildQualityBadge(context),
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
                          final next = !_isMuted;
                          callManager.setMuted(next);
                          setState(() => _isMuted = next);
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
                      if (isVideoCall)
                        _ControlButton(
                          icon: _isVideoEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          label:
                              _isVideoEnabled ? l10n.videoOff : l10n.videoOn,
                          onPressed: () {
                            final next = !_isVideoEnabled;
                            callManager.setVideoEnabled(next);
                            setState(() => _isVideoEnabled = next);
                          },
                          backgroundColor:
                              _isVideoEnabled ? Colors.white24 : Colors.white,
                          iconColor:
                              _isVideoEnabled ? Colors.white : Colors.black,
                        )
                      else
                        // Speaker Toggle (for audio calls)
                        _ControlButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_off,
                          label: _isSpeakerOn
                              ? l10n.speakerOn
                              : l10n.speakerOff,
                          onPressed: () async {
                            final next = !_isSpeakerOn;
                            await callManager.setSpeakerOn(next);
                            if (mounted) {
                              setState(() => _isSpeakerOn = next);
                            }
                          },
                          backgroundColor:
                              _isSpeakerOn ? Colors.white : Colors.white24,
                          iconColor:
                              _isSpeakerOn ? Colors.black : Colors.white,
                        ),
                    ],
                  ),
                ),
              ),

              // Switch Camera Button (video calls only)
              if (isVideoCall && !_isEnding && _isVideoEnabled)
                Positioned(
                  bottom: 150,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: () {
                      callManager.switchCamera();
                    },
                  ),
                ),

              // Reconnecting banner — slides down from the top with a small
              // CircularProgressIndicator. Auto-hides on reconnect, or after
              // 15s ends the call. We keep the SlideTransition mounted (so it
              // can animate out cleanly) but hide it from the semantics tree
              // and pointer hits while [_isReconnecting] is false.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_isReconnecting,
                  child: SlideTransition(
                  position: _reconnectSlide,
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reconnecting…',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
              ),

              // Duration limit warning banner (1 min remaining)
              if (_durationWarningRemaining != null)
                Positioned(
                  top: _connState == CallUiState.reconnecting ? 80 : 80,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_off, color: Colors.white70, size: 16),
                          SizedBox(width: 4),
                          Text('Muted',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
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

  /// Small pill badge in the top-right that maps LiveKit's per-peer
  /// [ConnectionQuality] to a single 18×18 icon with a long-press tooltip.
  /// Hidden when quality is unknown.
  Widget _buildQualityBadge(BuildContext context) {
    final IconData icon;
    final Color color;
    final double iconSize;
    final String tooltip;
    switch (_lkQuality) {
      case lk.ConnectionQuality.excellent:
        icon = Icons.circle;
        color = Colors.green;
        iconSize = 10;
        tooltip = 'Excellent quality';
        break;
      case lk.ConnectionQuality.good:
        icon = Icons.circle;
        color = Colors.amber;
        iconSize = 10;
        tooltip = 'Good quality';
        break;
      case lk.ConnectionQuality.poor:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        iconSize = 14;
        tooltip = 'Poor quality';
        break;
      case lk.ConnectionQuality.lost:
        icon = Icons.signal_wifi_off;
        color = Colors.red;
        iconSize = 14;
        tooltip = 'Connection lost';
        break;
      case lk.ConnectionQuality.unknown:
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
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
