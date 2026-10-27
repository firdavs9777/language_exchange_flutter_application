import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_routes.dart';
import 'package:bananatalk_app/services/call_manager.dart';
import 'package:bananatalk_app/widgets/call/decline_message_sheet.dart';
import 'package:bananatalk_app/utils/image_utils.dart';

/// Incoming-call ring screen. CallManager opens it (once per callId) and
/// closes it through its single exit path.
class IncomingCallScreen extends StatefulWidget {
  final CallModel call;

  /// The server times a ring out at 45 s; this screen never outlives 50 s.
  static const Duration safetyNet = Duration(seconds: 50);

  const IncomingCallScreen({super.key, required this.call});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _busy = false;
  bool _sheetOpen = false;
  Timer? _safetyNet;
  StreamSubscription<CallFinish>? _finishSub;

  @override
  void initState() {
    super.initState();
    _safetyNet = Timer(IncomingCallScreen.safetyNet, _expire);
    // CallManager closes call routes itself; this also covers a screen that
    // was opened for a call CallManager is not tracking. removeRoute is
    // guarded by isActive so it never double-pops after CallManager closed us.
    _finishSub = CallManager().finishes.listen((finish) {
      if (finish.call.callId.toLowerCase() == widget.call.callId.toLowerCase()) _closeSelf();
    });
  }

  @override
  void dispose() {
    _safetyNet?.cancel();
    _finishSub?.cancel();
    super.dispose();
  }

  Future<void> _expire() async {
    final ended = await CallManager().expireIncoming(widget.call.callId);
    if (!ended && !CallManager().isAccepting(widget.call.callId)) _closeSelf();
  }

  void _closeSelf() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    // A decline sheet may sit above this screen: close it first so it is not
    // orphaned (its future resolves null, so no decline is sent).
    if (_sheetOpen) navigator.popUntil((r) => r == route);
    navigator.removeRoute(route);
  }

  Future<void> _decline() async {
    if (_busy) return;
    setState(() => _busy = true);
    await CallManager().rejectCall();
  }

  Future<void> _declineWithMessage() async {
    if (_sheetOpen || _busy) return;
    _sheetOpen = true;
    final String? text;
    try {
      text = await showDeclineMessageSheet(context);
    } finally {
      _sheetOpen = false;
    }
    if (text == null || !mounted) return;
    final manager = CallManager();
    final current = manager.currentCall;
    // The call ended, was answered elsewhere or is being accepted while the
    // sheet was open: nothing left to decline.
    if (_busy ||
        current == null ||
        current.callId.toLowerCase() != widget.call.callId.toLowerCase() ||
        current.status != CallStatus.ringing) {
      return;
    }
    setState(() => _busy = true);
    await manager.rejectCall(message: text);
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    _safetyNet?.cancel(); // an accept in flight must not be cut off at 50 s
    final manager = CallManager();
    await manager.acceptCall();
    if (!mounted) return;
    final accepted = manager.currentCall;
    if (accepted != null &&
        accepted.callId == widget.call.callId &&
        accepted.status == CallStatus.connecting) {
      Navigator.of(context).pushReplacement(CallRoutes.activeRoute(accepted));
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final call = widget.call;
    final isVideo = call.callType == CallType.video;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      isVideo ? l10n.incomingVideoCall : l10n.incomingAudioCall,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Icon(isVideo ? Icons.videocam : Icons.phone, color: Colors.white, size: 40),
                  ],
                ),
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: call.userProfilePicture != null
                        ? ImageUtils.avatarProvider(call.userProfilePicture!,
                            quality: ImageQuality.medium)
                        : null,
                    child: call.userProfilePicture == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white54)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    call.userName,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.callRinging, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallActionButton(
                      icon: Icons.call_end,
                      label: l10n.declineCall,
                      color: Colors.red,
                      onPressed: _busy ? null : _decline,
                    ),
                    _CallActionButton(
                      icon: Icons.message_rounded,
                      label: l10n.callDeclineWithMessage,
                      color: Colors.blueGrey,
                      onPressed: _busy ? null : _declineWithMessage,
                    ),
                    _CallActionButton(
                      icon: isVideo ? Icons.videocam : Icons.call,
                      label: l10n.acceptCall,
                      color: Colors.green,
                      onPressed: _busy ? null : _accept,
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
  final VoidCallback? onPressed;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // One semantic button (label + action); the circle and the label share
    // the same tap handler.
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(icon, color: Colors.white, size: 35),
              onPressed: onPressed,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
