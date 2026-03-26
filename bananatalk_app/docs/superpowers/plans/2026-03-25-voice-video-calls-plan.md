# Voice & Video Calls + Voice Rooms Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement complete voice/video calling and voice room functionality with localizations for 18 languages.

**Architecture:** Extend existing CallManager and WebRTCService to support both 1-on-1 calls and multi-peer voice rooms. Add VoiceRoomManager for group audio orchestration. All real-time communication via existing ChatSocketService.

**Tech Stack:** Flutter, WebRTC (flutter_webrtc), Socket.IO (socket_io_client), Riverpod, Dart

**Spec Reference:** `docs/superpowers/specs/2026-03-25-voice-video-calls-design.md`

---

## File Structure Overview

```
lib/
├── models/
│   ├── call_model.dart                    # MODIFY: Add peer state fields
│   └── call_record_model.dart             # CREATE: Call history record
│
├── services/
│   ├── webrtc_service.dart                # MODIFY: Add multi-peer support
│   ├── call_manager.dart                  # MODIFY: Add missing socket events
│   ├── voice_room_manager.dart            # CREATE: Voice room orchestration
│   ├── call_history_service.dart          # CREATE: REST API for history
│   └── chat_socket_service.dart           # MODIFY: Add voiceroom:* events
│
├── providers/
│   ├── call_provider.dart                 # MODIFY: Add peer state
│   └── voice_room_provider.dart           # CREATE: Voice room state
│
├── screens/
│   ├── active_call_screen.dart            # MODIFY: Timer, localization
│   ├── incoming_call_screen.dart          # MODIFY: Localization
│   └── call_history_screen.dart           # CREATE: History list
│
├── pages/community/voice_rooms/
│   ├── voice_room_screen.dart             # MODIFY: Wire WebRTC
│   ├── voice_rooms_tab.dart               # MODIFY: Real API data
│   └── create_room_sheet.dart             # MODIFY: API integration
│
├── widgets/
│   ├── call/
│   │   ├── call_duration_timer.dart       # CREATE
│   │   ├── call_buttons.dart              # CREATE
│   │   └── call_history_bubble.dart       # CREATE
│   └── voice_room/
│       └── room_chat_drawer.dart          # CREATE
│
└── l10n/
    └── app_*.arb                          # MODIFY: Add ~50 strings each
```

---

## Phase 1: Fix Existing 1-on-1 Calls

### Task 1.1: Add Localization Strings for Calls

**Files:**
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add English call strings to app_en.arb**

Add these strings after the existing "voiceRooms" key (around line 532):

```json
  "incomingAudioCall": "Incoming Audio Call",
  "incomingVideoCall": "Incoming Video Call",
  "outgoingCall": "Calling...",
  "callRinging": "Ringing...",
  "callConnecting": "Connecting...",
  "callConnected": "Connected",
  "callReconnecting": "Reconnecting...",
  "callEnded": "Call Ended",
  "callFailed": "Call Failed",
  "callMissed": "Missed Call",
  "callDeclined": "Call Declined",
  "callDuration": "{duration}",
  "@callDuration": {"placeholders": {"duration": {"type": "String"}}},
  "acceptCall": "Accept",
  "declineCall": "Decline",
  "endCall": "End",
  "muteCall": "Mute",
  "unmuteCall": "Unmute",
  "speakerOn": "Speaker",
  "speakerOff": "Earpiece",
  "videoOn": "Video On",
  "videoOff": "Video Off",
  "switchCamera": "Switch Camera",
  "callPermissionDenied": "Microphone permission is required for calls",
  "cameraPermissionDenied": "Camera permission is required for video calls",
  "callConnectionFailed": "Could not connect. Please try again.",
  "userBusy": "User is busy",
  "userOffline": "User is offline",
  "callHistory": "Call History",
  "noCallHistory": "No call history",
  "missedCalls": "Missed Calls",
  "allCalls": "All Calls",
  "callBack": "Call Back",
  "callAt": "Call at {time}",
  "@callAt": {"placeholders": {"time": {"type": "String"}}},
  "voiceCall": "Voice Call",
  "videoCall": "Video Call",
  "audioCall": "Audio Call",
  "exchange3MessagesBeforeCall": "Exchange 3+ messages before calling",
  "tryAgain": "Try Again",
  "voiceRoom": "Voice Room",
  "voiceRooms": "Voice Rooms",
  "noVoiceRooms": "No voice rooms active",
  "createVoiceRoom": "Create Voice Room",
  "joinRoom": "Join Room",
  "leaveRoom": "Leave Room",
  "leaveRoomConfirm": "Leave Room?",
  "leaveRoomMessage": "Are you sure you want to leave this room?",
  "stay": "Stay",
  "leave": "Leave",
  "roomTitle": "Room Title",
  "roomTitleHint": "Enter room title",
  "roomTopic": "Topic",
  "roomLanguage": "Language",
  "roomHost": "Host",
  "roomParticipants": "{count} participants",
  "@roomParticipants": {"placeholders": {"count": {"type": "int"}}},
  "roomMaxParticipants": "Max {count} participants",
  "@roomMaxParticipants": {"placeholders": {"count": {"type": "int"}}},
  "selectTopic": "Select Topic",
  "selectLanguage": "Select Language",
  "raiseHand": "Raise Hand",
  "lowerHand": "Lower Hand",
  "handRaisedNotification": "Hand raised! The host will see your request.",
  "handLoweredNotification": "Hand lowered",
  "muteParticipant": "Mute Participant",
  "kickParticipant": "Remove from Room",
  "promoteToCoHost": "Make Co-Host",
  "endRoomConfirm": "End Room?",
  "endRoomMessage": "This will end the room for all participants.",
  "roomEnded": "Room ended by host",
  "youWereRemoved": "You were removed from the room",
  "roomIsFull": "Room is full",
  "roomChat": "Room Chat",
  "noMessages": "No messages yet",
  "typeMessage": "Type a message..."
```

- [ ] **Step 2: Run flutter gen-l10n to generate**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app && flutter gen-l10n
```

Expected: Generated files in `.dart_tool/flutter_gen/gen_l10n/`

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/app_en.arb
git commit -m "feat(l10n): add English call and voice room strings"
```

---

### Task 1.2: Enhance CallModel with Peer State

**Files:**
- Modify: `lib/models/call_model.dart`

- [ ] **Step 1: Add ConnectionState enum and peer fields**

Add after the existing `CallStatus` enum (line 13):

```dart
enum CallConnectionState { connecting, connected, reconnecting, failed }
```

- [ ] **Step 2: Add peer state fields to CallModel**

Add these fields after `duration` (line 25):

```dart
  final bool isPeerMuted;
  final bool isPeerVideoEnabled;
  final CallConnectionState connectionState;
```

- [ ] **Step 3: Update constructor with default values**

Update the constructor to include new fields with defaults:

```dart
  CallModel({
    required this.callId,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.callType,
    required this.direction,
    this.status = CallStatus.ringing,
    required this.startTime,
    this.endTime,
    this.duration,
    this.isPeerMuted = false,
    this.isPeerVideoEnabled = true,
    this.connectionState = CallConnectionState.connecting,
  });
```

- [ ] **Step 4: Update copyWith method**

Add new fields to `copyWith`:

```dart
  CallModel copyWith({
    String? callId,
    String? userId,
    String? userName,
    String? userProfilePicture,
    CallType? callType,
    CallDirection? direction,
    CallStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    bool? isPeerMuted,
    bool? isPeerVideoEnabled,
    CallConnectionState? connectionState,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      callType: callType ?? this.callType,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isPeerMuted: isPeerMuted ?? this.isPeerMuted,
      isPeerVideoEnabled: isPeerVideoEnabled ?? this.isPeerVideoEnabled,
      connectionState: connectionState ?? this.connectionState,
    );
  }
```

- [ ] **Step 5: Commit**

```bash
git add lib/models/call_model.dart
git commit -m "feat(models): add peer state fields to CallModel"
```

---

### Task 1.3: Add Missing Socket Emissions to CallManager

**Files:**
- Modify: `lib/services/call_manager.dart`

- [ ] **Step 1: Add new callback properties after existing callbacks (around line 28)**

```dart
  // NEW: Additional callbacks for peer state
  Function(bool)? onPeerMuteChanged;
  Function(bool)? onPeerVideoChanged;
  Function()? onPeerReconnecting;
  Function()? onPeerReconnected;
  Function()? onCallTimeout;
  Function()? onReconnecting;
  Function()? onReconnected;
```

- [ ] **Step 2: Update toggleMute to emit to server**

Replace the existing `toggleMute` method:

```dart
  void toggleMute() {
    _webrtcService.toggleMicrophone();
    // Emit mute state to server
    if (_socket != null && currentCall != null) {
      _socket!.emit('call:mute', {
        'callId': currentCall!.callId,
        'isMuted': !_webrtcService.isMicrophoneEnabled,
      });
    }
  }
```

- [ ] **Step 3: Update toggleVideo to emit to server**

Replace the existing `toggleVideo` method:

```dart
  void toggleVideo() {
    _webrtcService.toggleCamera();
    // Emit video state to server
    if (_socket != null && currentCall != null) {
      _socket!.emit('call:video-toggle', {
        'callId': currentCall!.callId,
        'isVideoEnabled': _webrtcService.isCameraEnabled,
      });
    }
  }
```

- [ ] **Step 4: Add peer state listeners in _setupSocketListeners**

Add these listeners at the end of `_setupSocketListeners()`:

```dart
    // Listen for peer mute state
    _socket!.on('call:mute', (data) {
      if (data['callId'] == currentCall?.callId && data['userId'] != null) {
        final isMuted = data['isMuted'] == true;
        if (currentCall != null) {
          currentCall = currentCall!.copyWith(isPeerMuted: isMuted);
        }
        onPeerMuteChanged?.call(isMuted);
      }
    });

    // Listen for peer video state
    _socket!.on('call:video-toggle', (data) {
      if (data['callId'] == currentCall?.callId && data['userId'] != null) {
        final isVideoEnabled = data['isVideoEnabled'] == true;
        if (currentCall != null) {
          currentCall = currentCall!.copyWith(isPeerVideoEnabled: isVideoEnabled);
        }
        onPeerVideoChanged?.call(isVideoEnabled);
      }
    });

    // Listen for call timeout
    _socket!.on('call:timeout', (data) {
      if (currentCall != null) {
        currentCall = currentCall!.copyWith(status: CallStatus.missed);
        onCallTimeout?.call();
        _cleanup();
      }
    });

    // Listen for peer reconnecting
    _socket!.on('call:peer-reconnecting', (data) {
      if (data['callId'] == currentCall?.callId) {
        onPeerReconnecting?.call();
      }
    });

    // Listen for peer reconnected
    _socket!.on('call:peer-reconnected', (data) {
      if (data['callId'] == currentCall?.callId) {
        onPeerReconnected?.call();
      }
    });
```

- [ ] **Step 5: Commit**

```bash
git add lib/services/call_manager.dart
git commit -m "feat(call): add mute/video socket emissions and peer state listeners"
```

---

### Task 1.4: Create Call Duration Timer Widget

**Files:**
- Create: `lib/widgets/call/call_duration_timer.dart`

- [ ] **Step 1: Create widgets/call directory**

```bash
mkdir -p /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/widgets/call
```

- [ ] **Step 2: Create call_duration_timer.dart**

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class CallDurationTimer extends StatefulWidget {
  final DateTime startTime;
  final TextStyle? style;

  const CallDurationTimer({
    super.key,
    required this.startTime,
    this.style,
  });

  @override
  State<CallDurationTimer> createState() => _CallDurationTimerState();
}

class _CallDurationTimerState extends State<CallDurationTimer> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDuration();
    });
  }

  void _updateDuration() {
    setState(() {
      _duration = DateTime.now().difference(widget.startTime);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_duration),
      style: widget.style ??
          const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/call/call_duration_timer.dart
git commit -m "feat(widgets): add CallDurationTimer widget"
```

---

### Task 1.5: Create Call Buttons Widget

**Files:**
- Create: `lib/widgets/call/call_buttons.dart`

- [ ] **Step 1: Create call_buttons.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CallButtons extends ConsumerWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientProfilePicture;
  final int messageCount;
  final Color? iconColor;
  final double iconSize;

  const CallButtons({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientProfilePicture,
    required this.messageCount,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final canCall = messageCount >= 3;
    final color = iconColor ?? Theme.of(context).iconTheme.color;
    final disabledColor = color?.withOpacity(0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio call button
        Tooltip(
          message: canCall ? l10n.voiceCall : l10n.exchange3MessagesBeforeCall,
          child: IconButton(
            icon: Icon(
              Icons.call_outlined,
              color: canCall ? color : disabledColor,
              size: iconSize,
            ),
            onPressed: canCall
                ? () => _initiateCall(context, ref, CallType.audio)
                : null,
          ),
        ),
        // Video call button
        Tooltip(
          message: canCall ? l10n.videoCall : l10n.exchange3MessagesBeforeCall,
          child: IconButton(
            icon: Icon(
              Icons.videocam_outlined,
              color: canCall ? color : disabledColor,
              size: iconSize,
            ),
            onPressed: canCall
                ? () => _initiateCall(context, ref, CallType.video)
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _initiateCall(
    BuildContext context,
    WidgetRef ref,
    CallType callType,
  ) async {
    try {
      await ref.read(callProvider.notifier).initiateCall(
            recipientId,
            recipientName,
            recipientProfilePicture,
            callType,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/call/call_buttons.dart
git commit -m "feat(widgets): add CallButtons widget with 3-message restriction"
```

---

### Task 1.6: Update ActiveCallScreen with Timer and Localization

**Files:**
- Modify: `lib/screens/active_call_screen.dart`

- [ ] **Step 1: Add imports at top of file**

```dart
import 'package:bananatalk_app/widgets/call/call_duration_timer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

- [ ] **Step 2: Add connected time tracking in state**

Add after `bool _isSpeakerOn = true;` (around line 19):

```dart
  DateTime? _connectedTime;
  bool _isPeerMuted = false;
```

- [ ] **Step 3: Track call connection via call status**

Add a method to track when call becomes connected:

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch for call status changes to set connected time
    final callState = ref.read(callProvider);
    if (callState?.status == CallStatus.connected && _connectedTime == null) {
      _connectedTime = DateTime.now();
    }
  }
```

Also listen for status changes in initState via listener:

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Setup CallManager callbacks for peer state
      final callManager = ref.read(callProvider.notifier).callManager;

      callManager.onPeerMuteChanged = (isMuted) {
        if (mounted) {
          setState(() => _isPeerMuted = isMuted);
        }
      };

      // Watch for status changes
      ref.listenManual(callProvider, (previous, next) {
        if (next?.status == CallStatus.connected && _connectedTime == null) {
          setState(() => _connectedTime = DateTime.now());
        }
      });
    });
  }
```

- [ ] **Step 4: Update _getCallStatusText to use localization and show timer**

Replace the `_getCallStatusText` method:

```dart
  Widget _buildCallStatus(AppLocalizations l10n) {
    final call = widget.call;

    if (call.status == CallStatus.connected && _connectedTime != null) {
      return CallDurationTimer(
        startTime: _connectedTime!,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      );
    }

    String statusText;
    switch (call.status) {
      case CallStatus.ringing:
        statusText = l10n.callRinging;
      case CallStatus.connecting:
        statusText = l10n.callConnecting;
      case CallStatus.connected:
        statusText = l10n.callConnected;
      default:
        statusText = '';
    }

    return Text(
      statusText,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }
```

- [ ] **Step 5: Update button labels to use localization**

In the `build` method, get localization:

```dart
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final callNotifier = ref.read(callProvider.notifier);
    // ... rest of build
```

Update the mute button label:

```dart
label: _isMuted ? l10n.unmuteCall : l10n.muteCall,
```

Update the end call button label:

```dart
label: l10n.endCall,
```

Update the video toggle label:

```dart
label: _isVideoEnabled ? l10n.videoOff : l10n.videoOn,
```

Update the speaker toggle label:

```dart
label: _isSpeakerOn ? l10n.speakerOn : l10n.speakerOff,
```

- [ ] **Step 6: Replace status text display in both places**

Replace the hardcoded status Text widgets with the new method:

```dart
_buildCallStatus(l10n),
```

- [ ] **Step 7: Commit**

```bash
git add lib/screens/active_call_screen.dart
git commit -m "feat(call): add duration timer and localization to ActiveCallScreen"
```

---

### Task 1.7: Update IncomingCallScreen with Localization

**Files:**
- Modify: `lib/screens/incoming_call_screen.dart`

- [ ] **Step 1: Add localization import**

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

- [ ] **Step 2: Update build method to use localization**

At the start of build method:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
```

- [ ] **Step 3: Replace hardcoded strings**

Replace "Incoming Video/Audio Call" text:

```dart
Text(
  call.callType == CallType.video
      ? l10n.incomingVideoCall
      : l10n.incomingAudioCall,
  style: const TextStyle(
    color: Colors.white70,
    fontSize: 16,
  ),
),
```

Replace "Ringing..." text:

```dart
Text(
  l10n.callRinging,
  style: const TextStyle(
    color: Colors.white70,
    fontSize: 18,
  ),
),
```

Replace button labels:

```dart
_CallActionButton(
  icon: Icons.call_end,
  label: l10n.declineCall,
  // ...
),
_CallActionButton(
  icon: Icons.call,
  label: l10n.acceptCall,
  // ...
),
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/incoming_call_screen.dart
git commit -m "feat(call): add localization to IncomingCallScreen"
```

---

### Task 1.8: Enable Call Buttons in Chat App Bar

**Files:**
- Modify: `lib/pages/chat/widgets/chat_app_bar.dart` (or wherever the chat app bar is)

- [ ] **Step 1: Find and read the chat app bar file**

First, locate the file:

```bash
find /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib -name "*chat*app*bar*" -o -name "*chat*header*"
```

- [ ] **Step 2: Import CallButtons widget**

```dart
import 'package:bananatalk_app/widgets/call/call_buttons.dart';
```

- [ ] **Step 3: Add CallButtons to the app bar actions**

Replace any disabled/commented call buttons with:

```dart
CallButtons(
  recipientId: recipientId,
  recipientName: recipientName,
  recipientProfilePicture: recipientProfilePicture,
  messageCount: messageCount, // Get from chat provider
  iconColor: Colors.white,
),
```

- [ ] **Step 4: Commit**

```bash
git add lib/pages/chat/
git commit -m "feat(chat): enable call buttons in chat app bar"
```

---

## Phase 2: Voice Rooms

### Task 2.1: Enhance WebRTCService for Multi-Peer

**Files:**
- Modify: `lib/services/webrtc_service.dart`

- [ ] **Step 1: Add multi-peer properties after existing properties (around line 12)**

```dart
  // Multi-peer support for voice rooms
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteAudioStreams = {};
  bool _isMultiPeerMode = false;
  List<dynamic>? _currentIceServers;

  // Multi-peer callbacks
  Function(String peerId, RTCSessionDescription)? onOfferCreatedForPeer;
  Function(String peerId, RTCSessionDescription)? onAnswerCreatedForPeer;
  Function(String peerId, RTCIceCandidate)? onIceCandidateForPeer;
  Function(String peerId, MediaStream)? onRemoteStreamForPeer;
  Function(String peerId)? onPeerDisconnected;
  Function(String peerId, RTCPeerConnectionState)? onPeerConnectionStateChange;
```

- [ ] **Step 2: Add method to initialize multi-peer mode**

```dart
  /// Initialize for multi-peer mode (voice rooms)
  Future<void> initializeMultiPeer(List<dynamic> iceServers) async {
    _isMultiPeerMode = true;
    _currentIceServers = iceServers;

    // Get audio-only local stream
    final constraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
  }
```

- [ ] **Step 3: Add method to create peer connection for specific peer**

```dart
  /// Create a peer connection for a specific participant
  Future<void> createPeerConnectionForPeer(String peerId) async {
    if (_peerConnections.containsKey(peerId)) {
      return; // Already connected
    }

    final iceConfig = {
      'iceServers': _currentIceServers ?? _iceServers['iceServers'],
    };

    final pc = await createPeerConnection(iceConfig, _config);
    _peerConnections[peerId] = pc;

    // Add local audio track
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    // Setup listeners for this peer
    _setupPeerListeners(peerId, pc);
  }

  void _setupPeerListeners(String peerId, RTCPeerConnection pc) {
    pc.onIceCandidate = (candidate) {
      onIceCandidateForPeer?.call(peerId, candidate);
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteAudioStreams[peerId] = event.streams[0];
        onRemoteStreamForPeer?.call(peerId, event.streams[0]);
      }
    };

    pc.onConnectionState = (state) {
      onPeerConnectionStateChange?.call(peerId, state);
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        onPeerDisconnected?.call(peerId);
      }
    };
  }
```

- [ ] **Step 4: Add methods for WebRTC signaling with specific peers**

```dart
  /// Create offer for a specific peer
  Future<void> createOfferForPeer(String peerId) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await pc.setLocalDescription(offer);
    onOfferCreatedForPeer?.call(peerId, offer);
  }

  /// Handle offer from a specific peer
  Future<void> handleOfferFromPeer(
    String peerId,
    RTCSessionDescription offer,
  ) async {
    // Create connection if doesn't exist
    if (!_peerConnections.containsKey(peerId)) {
      await createPeerConnectionForPeer(peerId);
    }

    final pc = _peerConnections[peerId];
    if (pc == null) return;

    await pc.setRemoteDescription(offer);

    final answer = await pc.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await pc.setLocalDescription(answer);
    onAnswerCreatedForPeer?.call(peerId, answer);
  }

  /// Handle answer from a specific peer
  Future<void> handleAnswerFromPeer(
    String peerId,
    RTCSessionDescription answer,
  ) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    await pc.setRemoteDescription(answer);
  }

  /// Add ICE candidate for a specific peer
  Future<void> addIceCandidateForPeer(
    String peerId,
    RTCIceCandidate candidate,
  ) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    await pc.addCandidate(candidate);
  }

  /// Remove a peer connection
  Future<void> removePeer(String peerId) async {
    final pc = _peerConnections.remove(peerId);
    await pc?.close();
    _remoteAudioStreams.remove(peerId);
  }

  /// Dispose all peer connections (for leaving room)
  Future<void> disposeAllPeers() async {
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    _remoteAudioStreams.clear();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    _isMultiPeerMode = false;
  }
```

- [ ] **Step 5: Commit**

```bash
git add lib/services/webrtc_service.dart
git commit -m "feat(webrtc): add multi-peer support for voice rooms"
```

---

### Task 2.2: Add Voice Room Socket Events to ChatSocketService

**Files:**
- Modify: `lib/services/chat_socket_service.dart`

- [ ] **Step 1: Add voice room event emitters**

Add these methods to the ChatSocketService class:

```dart
  // ============ Voice Room Events ============

  /// Join a voice room's socket channel
  void joinVoiceRoom(String roomId) {
    socket?.emit('voiceroom:join', {'roomId': roomId});
  }

  /// Leave a voice room
  void leaveVoiceRoom(String roomId) {
    socket?.emit('voiceroom:leave', {'roomId': roomId});
  }

  /// Send speaking status
  void sendSpeakingStatus(String roomId, bool isSpeaking) {
    socket?.emit('voiceroom:speaking', {
      'roomId': roomId,
      'isSpeaking': isSpeaking,
    });
  }

  /// Send mute status in voice room
  void sendVoiceRoomMuteStatus(String roomId, bool isMuted) {
    socket?.emit('voiceroom:mute', {
      'roomId': roomId,
      'isMuted': isMuted,
    });
  }

  /// Raise/lower hand
  void sendRaiseHand(String roomId) {
    socket?.emit('voiceroom:raise_hand', {'roomId': roomId});
  }

  /// Send chat message in voice room
  void sendVoiceRoomChat(String roomId, String message) {
    socket?.emit('voiceroom:chat', {
      'roomId': roomId,
      'message': message,
    });
  }

  /// Send WebRTC offer to specific peer in room
  void sendVoiceRoomOffer(String roomId, String targetUserId, Map offer) {
    socket?.emit('voiceroom:rtc_offer', {
      'roomId': roomId,
      'targetUserId': targetUserId,
      'offer': offer,
    });
  }

  /// Send WebRTC answer to specific peer in room
  void sendVoiceRoomAnswer(String roomId, String targetUserId, Map answer) {
    socket?.emit('voiceroom:rtc_answer', {
      'roomId': roomId,
      'targetUserId': targetUserId,
      'answer': answer,
    });
  }

  /// Send ICE candidate to specific peer in room
  void sendVoiceRoomIceCandidate(
    String roomId,
    String targetUserId,
    Map candidate,
  ) {
    socket?.emit('voiceroom:ice_candidate', {
      'roomId': roomId,
      'targetUserId': targetUserId,
      'candidate': candidate,
    });
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/chat_socket_service.dart
git commit -m "feat(socket): add voice room event emitters"
```

---

### Task 2.3: Create VoiceRoomManager Service

**Files:**
- Create: `lib/services/voice_room_manager.dart`

- [ ] **Step 1: Create the voice_room_manager.dart file**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/services/webrtc_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/api_client.dart';

class VoiceRoomChatMessage {
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;

  VoiceRoomChatMessage({
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
  });
}

class VoiceRoomManager {
  static final VoiceRoomManager _instance = VoiceRoomManager._internal();
  factory VoiceRoomManager() => _instance;
  VoiceRoomManager._internal();

  final WebRTCService _webrtcService = WebRTCService();
  final ApiClient _apiClient = ApiClient();
  ChatSocketService? _chatSocketService;
  IO.Socket? _socket;
  bool _isInitialized = false;

  VoiceRoom? currentRoom;
  List<RoomParticipant> participants = [];
  bool isMuted = true; // Start muted by default
  bool isHandRaised = false;
  List<VoiceRoomChatMessage> chatMessages = [];

  // Callbacks
  Function(VoiceRoom, List<dynamic> iceServers)? onRoomJoined;
  Function(RoomParticipant)? onParticipantJoined;
  Function(String participantId)? onParticipantLeft;
  Function(String participantId, bool isSpeaking)? onParticipantSpeaking;
  Function(String participantId, bool isMuted)? onParticipantMuted;
  Function(RoomParticipant)? onHandRaised;
  Function(VoiceRoomChatMessage)? onChatMessage;
  Function()? onRoomEnded;
  Function(String)? onError;

  WebRTCService get webrtcService => _webrtcService;

  Future<void> initialize(ChatSocketService chatSocketService) async {
    if (_isInitialized) return;

    _chatSocketService = chatSocketService;
    _socket = chatSocketService.socket;
    await _webrtcService.initialize();
    _setupSocketListeners();
    _setupWebRTCCallbacks();
    _isInitialized = true;
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Successfully joined room
    _socket!.on('voiceroom:joined', (data) {
      final roomData = data['room'] ?? data;
      currentRoom = VoiceRoom.fromJson(roomData);

      final participantsList = data['participants'] as List? ?? [];
      participants = participantsList
          .map((p) => RoomParticipant.fromJson(p))
          .toList();

      final iceServers = data['iceServers'] as List? ?? [];
      onRoomJoined?.call(currentRoom!, iceServers);

      // Connect to existing participants
      for (final participant in participants) {
        _connectToPeer(participant.id);
      }
    });

    // New participant joined
    _socket!.on('voiceroom:user_joined', (data) {
      final participant = RoomParticipant.fromJson(data['user'] ?? data);
      if (!participants.any((p) => p.id == participant.id)) {
        participants.add(participant);
        onParticipantJoined?.call(participant);
        _connectToPeer(participant.id);
      }
    });

    // Participant left
    _socket!.on('voiceroom:user_left', (data) {
      final userId = data['userId']?.toString() ?? '';
      participants.removeWhere((p) => p.id == userId);
      _disconnectFromPeer(userId);
      onParticipantLeft?.call(userId);

      // Check if room ended
      if (data['roomEnded'] == true) {
        _handleRoomEnded();
      }
    });

    // Speaking status update
    _socket!.on('voiceroom:speaking', (data) {
      final userId = data['userId']?.toString() ?? '';
      final isSpeaking = data['isSpeaking'] == true;
      _updateParticipantSpeaking(userId, isSpeaking);
      onParticipantSpeaking?.call(userId, isSpeaking);
    });

    // Mute status update
    _socket!.on('voiceroom:mute', (data) {
      final userId = data['userId']?.toString() ?? '';
      final isMuted = data['isMuted'] == true;
      _updateParticipantMuted(userId, isMuted);
      onParticipantMuted?.call(userId, isMuted);
    });

    // Hand raised
    _socket!.on('voiceroom:hand_raised', (data) {
      final participant = RoomParticipant.fromJson(data['user'] ?? data);
      onHandRaised?.call(participant);
    });

    // Chat message
    _socket!.on('voiceroom:chat', (data) {
      final message = VoiceRoomChatMessage(
        userId: data['user']?['_id']?.toString() ?? '',
        userName: data['user']?['name']?.toString() ?? 'Unknown',
        message: data['message']?.toString() ?? '',
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      );
      chatMessages.add(message);
      onChatMessage?.call(message);
    });

    // WebRTC signaling
    _socket!.on('voiceroom:rtc_offer', (data) async {
      final fromUserId = data['fromUserId']?.toString() ?? '';
      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await _webrtcService.handleOfferFromPeer(fromUserId, offer);
    });

    _socket!.on('voiceroom:rtc_answer', (data) async {
      final fromUserId = data['fromUserId']?.toString() ?? '';
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _webrtcService.handleAnswerFromPeer(fromUserId, answer);
    });

    _socket!.on('voiceroom:ice_candidate', (data) async {
      final fromUserId = data['fromUserId']?.toString() ?? '';
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _webrtcService.addIceCandidateForPeer(fromUserId, candidate);
    });

    // Room ended by host
    _socket!.on('voiceroom:ended', (data) {
      _handleRoomEnded();
    });

    // Error
    _socket!.on('voiceroom:error', (data) {
      onError?.call(data['message']?.toString() ?? 'Unknown error');
    });
  }

  void _setupWebRTCCallbacks() {
    _webrtcService.onOfferCreatedForPeer = (peerId, offer) {
      if (currentRoom != null) {
        _chatSocketService?.sendVoiceRoomOffer(
          currentRoom!.id,
          peerId,
          {'type': offer.type, 'sdp': offer.sdp},
        );
      }
    };

    _webrtcService.onAnswerCreatedForPeer = (peerId, answer) {
      if (currentRoom != null) {
        _chatSocketService?.sendVoiceRoomAnswer(
          currentRoom!.id,
          peerId,
          {'type': answer.type, 'sdp': answer.sdp},
        );
      }
    };

    _webrtcService.onIceCandidateForPeer = (peerId, candidate) {
      if (currentRoom != null) {
        _chatSocketService?.sendVoiceRoomIceCandidate(
          currentRoom!.id,
          peerId,
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      }
    };
  }

  // ============ Room Lifecycle ============

  /// Create a new voice room
  Future<VoiceRoom> createRoom(CreateRoomRequest request) async {
    final response = await _apiClient.post(
      '/api/v1/voicerooms',
      body: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final room = VoiceRoom.fromJson(response.data['data']);
      return room;
    } else {
      throw Exception(response.data['message'] ?? 'Failed to create room');
    }
  }

  /// Join an existing voice room
  Future<void> joinRoom(String roomId) async {
    // First, call REST API to join
    final response = await _apiClient.post('/api/v1/voicerooms/$roomId/join');

    if (response.statusCode != 200) {
      throw Exception(response.data['message'] ?? 'Failed to join room');
    }

    // Request microphone permission
    final hasPermission = await _webrtcService.requestPermissions(false);
    if (!hasPermission) {
      throw Exception('Microphone permission required');
    }

    // Then join socket room
    _chatSocketService?.joinVoiceRoom(roomId);
  }

  /// Leave the current voice room
  Future<void> leaveRoom() async {
    if (currentRoom == null) return;

    final roomId = currentRoom!.id;

    // Leave socket room
    _chatSocketService?.leaveVoiceRoom(roomId);

    // Call REST API
    await _apiClient.post('/api/v1/voicerooms/$roomId/leave');

    // Cleanup
    await _cleanup();
  }

  // ============ Participant Actions ============

  void toggleMute() {
    isMuted = !isMuted;
    _webrtcService.toggleMicrophone();

    if (currentRoom != null) {
      _chatSocketService?.sendVoiceRoomMuteStatus(currentRoom!.id, isMuted);
    }
  }

  void toggleHandRaise() {
    isHandRaised = !isHandRaised;

    if (currentRoom != null && isHandRaised) {
      _chatSocketService?.sendRaiseHand(currentRoom!.id);
    }
  }

  void sendChatMessage(String message) {
    if (currentRoom != null && message.trim().isNotEmpty) {
      _chatSocketService?.sendVoiceRoomChat(currentRoom!.id, message.trim());
    }
  }

  // ============ Host Actions ============

  Future<void> endRoom() async {
    if (currentRoom == null) return;

    await _apiClient.post('/api/v1/voicerooms/${currentRoom!.id}/end');
    await _cleanup();
  }

  Future<void> kickParticipant(String participantId) async {
    if (currentRoom == null) return;
    // This would need a backend endpoint - for now just remove locally
    participants.removeWhere((p) => p.id == participantId);
  }

  // ============ Private Methods ============

  Future<void> _connectToPeer(String peerId) async {
    await _webrtcService.createPeerConnectionForPeer(peerId);
    await _webrtcService.createOfferForPeer(peerId);
  }

  void _disconnectFromPeer(String peerId) {
    _webrtcService.removePeer(peerId);
  }

  void _updateParticipantSpeaking(String userId, bool isSpeaking) {
    final index = participants.indexWhere((p) => p.id == userId);
    if (index != -1) {
      // Create updated participant (models are immutable)
      final updated = RoomParticipant(
        id: participants[index].id,
        name: participants[index].name,
        avatar: participants[index].avatar,
        isSpeaking: isSpeaking,
        isMuted: participants[index].isMuted,
        isHost: participants[index].isHost,
        joinedAt: participants[index].joinedAt,
      );
      participants[index] = updated;
    }
  }

  void _updateParticipantMuted(String userId, bool isMuted) {
    final index = participants.indexWhere((p) => p.id == userId);
    if (index != -1) {
      final updated = RoomParticipant(
        id: participants[index].id,
        name: participants[index].name,
        avatar: participants[index].avatar,
        isSpeaking: participants[index].isSpeaking,
        isMuted: isMuted,
        isHost: participants[index].isHost,
        joinedAt: participants[index].joinedAt,
      );
      participants[index] = updated;
    }
  }

  void _handleRoomEnded() {
    onRoomEnded?.call();
    _cleanup();
  }

  Future<void> _cleanup() async {
    await _webrtcService.disposeAllPeers();
    currentRoom = null;
    participants.clear();
    chatMessages.clear();
    isMuted = true;
    isHandRaised = false;
  }

  void dispose() {
    _cleanup();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/voice_room_manager.dart
git commit -m "feat(voice-room): create VoiceRoomManager service"
```

---

### Task 2.4: Create VoiceRoomProvider

**Files:**
- Create: `lib/providers/voice_room_provider.dart`

- [ ] **Step 1: Create voice_room_provider.dart**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/services/voice_room_manager.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';

enum VoiceRoomState { idle, joining, connected, reconnecting, leaving, error }

final voiceRoomManagerProvider = Provider<VoiceRoomManager>((ref) {
  return VoiceRoomManager();
});

final voiceRoomProvider = ChangeNotifierProvider<VoiceRoomNotifier>((ref) {
  final manager = ref.read(voiceRoomManagerProvider);
  return VoiceRoomNotifier(manager);
});

class VoiceRoomNotifier extends ChangeNotifier {
  final VoiceRoomManager _manager;

  VoiceRoomState _state = VoiceRoomState.idle;
  String? _errorMessage;

  VoiceRoomNotifier(this._manager) {
    _setupCallbacks();
  }

  // Getters
  VoiceRoomState get state => _state;
  String? get errorMessage => _errorMessage;
  VoiceRoom? get currentRoom => _manager.currentRoom;
  List<RoomParticipant> get participants => _manager.participants;
  bool get isMuted => _manager.isMuted;
  bool get isHandRaised => _manager.isHandRaised;
  List<VoiceRoomChatMessage> get chatMessages => _manager.chatMessages;

  bool isHost(String userId) => currentRoom?.hostId == userId;

  void _setupCallbacks() {
    _manager.onRoomJoined = (room, iceServers) async {
      // Initialize multi-peer WebRTC
      await _manager.webrtcService.initializeMultiPeer(iceServers);
      _state = VoiceRoomState.connected;
      notifyListeners();
    };

    _manager.onParticipantJoined = (_) => notifyListeners();
    _manager.onParticipantLeft = (_) => notifyListeners();
    _manager.onParticipantSpeaking = (_, __) => notifyListeners();
    _manager.onParticipantMuted = (_, __) => notifyListeners();
    _manager.onHandRaised = (_) => notifyListeners();
    _manager.onChatMessage = (_) => notifyListeners();

    _manager.onRoomEnded = () {
      _state = VoiceRoomState.idle;
      notifyListeners();
    };

    _manager.onError = (error) {
      _state = VoiceRoomState.error;
      _errorMessage = error;
      notifyListeners();
    };
  }

  Future<void> initialize(ChatSocketService chatSocketService) async {
    await _manager.initialize(chatSocketService);
  }

  Future<VoiceRoom> createRoom(CreateRoomRequest request) async {
    _state = VoiceRoomState.joining;
    _errorMessage = null;
    notifyListeners();

    try {
      final room = await _manager.createRoom(request);
      // Auto-join after creating
      await joinRoom(room.id);
      return room;
    } catch (e) {
      _state = VoiceRoomState.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId) async {
    _state = VoiceRoomState.joining;
    _errorMessage = null;
    notifyListeners();

    try {
      await _manager.joinRoom(roomId);
      // State will be updated via onRoomJoined callback
    } catch (e) {
      _state = VoiceRoomState.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leaveRoom() async {
    _state = VoiceRoomState.leaving;
    notifyListeners();

    try {
      await _manager.leaveRoom();
      _state = VoiceRoomState.idle;
      notifyListeners();
    } catch (e) {
      _state = VoiceRoomState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void toggleMute() {
    _manager.toggleMute();
    notifyListeners();
  }

  void toggleHandRaise() {
    _manager.toggleHandRaise();
    notifyListeners();
  }

  void sendChat(String message) {
    _manager.sendChatMessage(message);
  }

  Future<void> endRoom() async {
    await _manager.endRoom();
    _state = VoiceRoomState.idle;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/voice_room_provider.dart
git commit -m "feat(providers): create VoiceRoomProvider"
```

---

### Task 2.5: Wire Up VoiceRoomScreen to Real WebRTC

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart`

- [ ] **Step 1: Update imports**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

- [ ] **Step 2: Replace local state with provider state**

Remove local state variables `_isMuted` and `_isHandRaised`.

Update the widget to use provider:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final voiceRoom = ref.watch(voiceRoomProvider);
  final participants = voiceRoom.participants;
  final isMuted = voiceRoom.isMuted;
  final isHandRaised = voiceRoom.isHandRaised;
  final room = voiceRoom.currentRoom ?? widget.room;
```

- [ ] **Step 3: Update toggle methods to use provider**

```dart
void _toggleMute() {
  HapticFeedback.lightImpact();
  ref.read(voiceRoomProvider.notifier).toggleMute();
}

void _toggleHandRaise() {
  HapticFeedback.lightImpact();
  final l10n = AppLocalizations.of(context)!;
  ref.read(voiceRoomProvider.notifier).toggleHandRaise();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ref.read(voiceRoomProvider).isHandRaised
            ? l10n.handRaisedNotification
            : l10n.handLoweredNotification,
      ),
      backgroundColor: const Color(0xFF00BFA5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}
```

- [ ] **Step 4: Update leave room to use provider**

```dart
void _leaveRoom() {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.leaveRoomConfirm),
      content: Text(l10n.leaveRoomMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.stay),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            await ref.read(voiceRoomProvider.notifier).leaveRoom();
            if (mounted) {
              Navigator.pop(context); // Leave screen
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.leave),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 5: Update participant grid to use real data**

```dart
Widget _buildParticipants() {
  final voiceRoom = ref.watch(voiceRoomProvider);
  final allParticipants = voiceRoom.participants;

  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      childAspectRatio: 0.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    ),
    itemCount: allParticipants.length,
    itemBuilder: (context, index) {
      final participant = allParticipants[index];
      return _ParticipantTile(
        participant: participant,
        isHost: participant.isHost,
      );
    },
  );
}
```

- [ ] **Step 6: Update controls with localized labels**

```dart
Widget _buildControls() {
  final l10n = AppLocalizations.of(context)!;
  final voiceRoom = ref.watch(voiceRoomProvider);
  final isMuted = voiceRoom.isMuted;
  final isHandRaised = voiceRoom.isHandRaised;

  return Container(
    // ... existing styling
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: isHandRaised
              ? Icons.front_hand_rounded
              : Icons.front_hand_outlined,
          label: isHandRaised ? l10n.lowerHand : l10n.raiseHand,
          // ... rest
        ),
        _ControlButton(
          icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: isMuted ? l10n.unmuteCall : l10n.muteCall,
          // ... rest
        ),
        _ControlButton(
          icon: Icons.call_end_rounded,
          label: l10n.leave,
          // ... rest
        ),
      ],
    ),
  );
}
```

- [ ] **Step 7: Commit**

```bash
git add lib/pages/community/voice_rooms/voice_room_screen.dart
git commit -m "feat(voice-room): wire up VoiceRoomScreen to provider and WebRTC"
```

---

### Task 2.6: Update Voice Rooms Tab with Real API Data

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_rooms_tab.dart`

- [ ] **Step 1: Read the current file to understand structure**

```bash
cat /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/community/voice_rooms/voice_rooms_tab.dart
```

- [ ] **Step 2: Add API fetching for room list**

Add a method to fetch rooms from API:

```dart
Future<List<VoiceRoom>> _fetchRooms() async {
  final response = await ApiClient().get('/api/v1/voicerooms');
  if (response.statusCode == 200) {
    final data = response.data['data'] as List? ?? [];
    return data.map((r) => VoiceRoom.fromJson(r)).toList();
  }
  return [];
}
```

- [ ] **Step 3: Replace mock data with FutureBuilder**

Update the build method to use FutureBuilder:

```dart
late Future<List<VoiceRoom>> _roomsFuture;

@override
void initState() {
  super.initState();
  _roomsFuture = _fetchRooms();
}

@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Scaffold(
    body: RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _roomsFuture = _fetchRooms();
        });
      },
      child: FutureBuilder<List<VoiceRoom>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _roomsFuture = _fetchRooms()),
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.headphones_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(l10n.noVoiceRooms, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) => _VoiceRoomCard(
              room: rooms[index],
              onTap: () => _joinRoom(rooms[index]),
            ),
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showCreateRoomSheet(context),
      icon: const Icon(Icons.add),
      label: Text(l10n.createVoiceRoom),
    ),
  );
}
```

- [ ] **Step 4: Add noVoiceRooms to localizations (if not already added)**

In `app_en.arb`, add:
```json
  "noVoiceRooms": "No voice rooms active"
```

- [ ] **Step 5: Commit**

```bash
git add lib/pages/community/voice_rooms/voice_rooms_tab.dart
git commit -m "feat(voice-room): connect voice rooms list to API"
```

---

### Task 2.7: Update Create Room Sheet with API Integration

**Files:**
- Modify: `lib/pages/community/voice_rooms/create_room_sheet.dart`

- [ ] **Step 1: Add provider import**

```dart
import 'package:bananatalk_app/providers/voice_room_provider.dart';
```

- [ ] **Step 2: Update create button to call API**

```dart
ElevatedButton(
  onPressed: () async {
    if (_titleController.text.isEmpty) {
      // Show error
      return;
    }

    final request = CreateRoomRequest(
      title: _titleController.text,
      topic: _selectedTopic ?? 'casual',
      language: _selectedLanguage ?? 'en',
      maxParticipants: 8,
    );

    try {
      final room = await ref.read(voiceRoomProvider.notifier).createRoom(request);
      if (mounted) {
        Navigator.pop(context); // Close sheet
        // Navigate to room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceRoomScreen(room: room),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $e')),
      );
    }
  },
  child: Text(l10n.createVoiceRoom),
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/pages/community/voice_rooms/create_room_sheet.dart
git commit -m "feat(voice-room): integrate create room with API"
```

---

### Task 2.8: Create Voice Room Chat Drawer

**Files:**
- Create: `lib/widgets/voice_room/room_chat_drawer.dart`

- [ ] **Step 1: Create room_chat_drawer.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/services/voice_room_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RoomChatDrawer extends ConsumerStatefulWidget {
  const RoomChatDrawer({super.key});

  @override
  ConsumerState<RoomChatDrawer> createState() => _RoomChatDrawerState();
}

class _RoomChatDrawerState extends ConsumerState<RoomChatDrawer> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    ref.read(voiceRoomProvider.notifier).sendChat(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final voiceRoom = ref.watch(voiceRoomProvider);
    final messages = voiceRoom.chatMessages;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_outlined),
                const SizedBox(width: 8),
                Text(
                  l10n.roomChat,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      l10n.noMessages,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _ChatMessageBubble(message: msg);
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final VoiceRoomChatMessage message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.userName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.message),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add missing localization keys to app_en.arb**

```json
  "roomChat": "Room Chat",
  "noMessages": "No messages yet",
  "typeMessage": "Type a message..."
```

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/voice_room/room_chat_drawer.dart
git commit -m "feat(voice-room): create RoomChatDrawer widget"
```

---

## Phase 3: Call History

### Task 3.1: Create CallRecord Model

**Files:**
- Create: `lib/models/call_record_model.dart`

- [ ] **Step 1: Create call_record_model.dart**

```dart
import 'package:bananatalk_app/models/call_model.dart';

enum CallRecordStatus { answered, missed, rejected }

class CallParticipant {
  final String id;
  final String name;
  final String? profilePicture;

  const CallParticipant({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      profilePicture: json['profilePicture']?.toString() ?? json['image']?.toString(),
    );
  }
}

class CallRecord {
  final String id;
  final List<CallParticipant> participants;
  final CallType type;
  final CallRecordStatus status;
  final int? duration; // seconds
  final DateTime startTime;
  final DateTime? endTime;
  final String initiatorId;
  final CallDirection direction;

  const CallRecord({
    required this.id,
    required this.participants,
    required this.type,
    required this.status,
    this.duration,
    required this.startTime,
    this.endTime,
    required this.initiatorId,
    required this.direction,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determine direction based on initiator
    final initiatorId = json['initiator']?.toString() ?? '';
    final direction = initiatorId == currentUserId
        ? CallDirection.outgoing
        : CallDirection.incoming;

    // Parse status
    CallRecordStatus status;
    final statusStr = json['status']?.toString() ?? '';
    switch (statusStr) {
      case 'answered':
      case 'ended':
        status = CallRecordStatus.answered;
      case 'missed':
        status = CallRecordStatus.missed;
      case 'rejected':
        status = CallRecordStatus.rejected;
      default:
        status = CallRecordStatus.answered;
    }

    return CallRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      participants: (json['participants'] as List? ?? [])
          .map((p) => CallParticipant.fromJson(p))
          .toList(),
      type: json['type'] == 'video' ? CallType.video : CallType.audio,
      status: status,
      duration: json['duration'] as int?,
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ??
          DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
      initiatorId: initiatorId,
      direction: direction,
    );
  }

  /// Get the other participant (for 1-on-1 calls)
  CallParticipant? getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  /// Format duration as mm:ss or hh:mm:ss
  String get formattedDuration {
    if (duration == null) return '';
    final d = Duration(seconds: duration!);
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/models/call_record_model.dart
git commit -m "feat(models): create CallRecord model for call history"
```

---

### Task 3.2: Create CallHistoryService

**Files:**
- Create: `lib/services/call_history_service.dart`

- [ ] **Step 1: Create call_history_service.dart**

```dart
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/services/api_client.dart';

class CallHistoryService {
  final ApiClient _apiClient;
  final String _currentUserId;

  CallHistoryService(this._apiClient, this._currentUserId);

  /// Get paginated call history
  Future<List<CallRecord>> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/calls',
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as List? ?? [];
      return data
          .map((json) => CallRecord.fromJson(json, _currentUserId))
          .toList();
    }
    return [];
  }

  /// Get call history with specific user
  Future<List<CallRecord>> getCallHistoryWithUser(String recipientId) async {
    final response = await _apiClient.get(
      '/api/v1/calls',
      queryParameters: {'userId': recipientId},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as List? ?? [];
      return data
          .map((json) => CallRecord.fromJson(json, _currentUserId))
          .toList();
    }
    return [];
  }

  /// Get missed calls count
  Future<int> getMissedCallsCount() async {
    final response = await _apiClient.get('/api/v1/calls/missed/count');

    if (response.statusCode == 200) {
      return response.data['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Get single call details
  Future<CallRecord?> getCallDetails(String callId) async {
    final response = await _apiClient.get('/api/v1/calls/$callId');

    if (response.statusCode == 200) {
      return CallRecord.fromJson(response.data['data'], _currentUserId);
    }
    return null;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/call_history_service.dart
git commit -m "feat(services): create CallHistoryService for REST API"
```

---

### Task 3.3: Create CallHistoryScreen

**Files:**
- Create: `lib/screens/call_history_screen.dart`

- [ ] **Step 1: Create call_history_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/services/call_history_service.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  List<CallRecord> _calls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Get current user ID from auth provider
      final currentUserId = ''; // Replace with actual user ID
      final service = CallHistoryService(ApiClient(), currentUserId);
      final calls = await service.getCallHistory();
      setState(() {
        _calls = calls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.callHistory),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCallHistory,
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    if (_calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.call_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noCallHistory,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      child: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          return _CallHistoryTile(
            call: _calls[index],
            currentUserId: '', // TODO: Get from provider
            onTap: () => _initiateCall(_calls[index]),
          );
        },
      ),
    );
  }

  void _initiateCall(CallRecord record) {
    final other = record.getOtherParticipant(''); // TODO: current user ID
    if (other == null) return;

    ref.read(callProvider.notifier).initiateCall(
          other.id,
          other.name,
          other.profilePicture,
          record.type,
        );
  }
}

class _CallHistoryTile extends StatelessWidget {
  final CallRecord call;
  final String currentUserId;
  final VoidCallback onTap;

  const _CallHistoryTile({
    required this.call,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final other = call.getOtherParticipant(currentUserId);
    final isMissed = call.status == CallRecordStatus.missed;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: other?.profilePicture != null
            ? NetworkImage(other!.profilePicture!)
            : null,
        child: other?.profilePicture == null
            ? Text(other?.name.substring(0, 1).toUpperCase() ?? '?')
            : null,
      ),
      title: Text(
        other?.name ?? 'Unknown',
        style: TextStyle(
          color: isMissed ? Colors.red : null,
          fontWeight: isMissed ? FontWeight.bold : null,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            call.direction == CallDirection.incoming
                ? Icons.call_received
                : Icons.call_made,
            size: 14,
            color: isMissed ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            call.type == CallType.video ? l10n.videoCall : l10n.audioCall,
            style: TextStyle(
              color: isMissed ? Colors.red : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat.MMMd().add_jm().format(call.startTime),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.duration != null)
            Text(
              call.formattedDuration,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          IconButton(
            icon: Icon(
              call.type == CallType.video ? Icons.videocam : Icons.call,
            ),
            onPressed: onTap,
            tooltip: l10n.callBack,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/call_history_screen.dart
git commit -m "feat(screens): create CallHistoryScreen"
```

---

### Task 3.4: Create Call History Bubble Widget for Chat

**Files:**
- Create: `lib/widgets/call/call_history_bubble.dart`

- [ ] **Step 1: Create call_history_bubble.dart**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CallHistoryBubble extends StatelessWidget {
  final CallRecord call;
  final bool isOutgoing;
  final VoidCallback? onTap;

  const CallHistoryBubble({
    super.key,
    required this.call,
    required this.isOutgoing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMissed = call.status == CallRecordStatus.missed;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMissed
              ? Colors.red.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMissed
                ? Colors.red.withOpacity(0.3)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              call.type == CallType.video
                  ? Icons.videocam_outlined
                  : Icons.call_outlined,
              color: isMissed ? Colors.red : theme.iconTheme.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMissed
                      ? l10n.callMissed
                      : (call.type == CallType.video
                          ? l10n.videoCall
                          : l10n.audioCall),
                  style: TextStyle(
                    color: isMissed ? Colors.red : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  call.duration != null
                      ? call.formattedDuration
                      : DateFormat.jm().format(call.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.replay,
                size: 16,
                color: theme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/call/call_history_bubble.dart
git commit -m "feat(widgets): create CallHistoryBubble for in-chat display"
```

---

### Task 3.5: Integrate CallHistoryBubble into Chat Screen

**Files:**
- Modify: `lib/pages/chat/chat_screen.dart` (or wherever chat messages are rendered)

- [ ] **Step 1: Find the chat screen message list builder**

First locate the chat screen:

```bash
find /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib -name "*chat_screen*" -o -name "*chat_page*"
```

- [ ] **Step 2: Add import for CallHistoryBubble**

```dart
import 'package:bananatalk_app/widgets/call/call_history_bubble.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
```

- [ ] **Step 3: Update message builder to handle call records**

In the message list builder (typically a ListView.builder), add a check for call record messages:

```dart
// In the message list builder
itemBuilder: (context, index) {
  final message = messages[index];

  // Check if this is a call record message
  if (message.type == MessageType.call) {
    final callRecord = CallRecord.fromJson(
      message.metadata ?? {},
      currentUserId,
    );
    return CallHistoryBubble(
      call: callRecord,
      isOutgoing: message.senderId == currentUserId,
      onTap: () => _initiateCall(callRecord),
    );
  }

  // Regular message handling
  return _buildMessageBubble(message);
}
```

- [ ] **Step 4: Add callback to initiate call from history bubble**

```dart
void _initiateCall(CallRecord record) {
  final other = record.getOtherParticipant(currentUserId);
  if (other == null) return;

  ref.read(callProvider.notifier).initiateCall(
    other.id,
    other.name,
    other.profilePicture,
    record.type,
  );
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/pages/chat/
git commit -m "feat(chat): integrate CallHistoryBubble into chat messages"
```

---

## Phase 4: Localizations for All Languages

### Task 4.1: Add Localizations to All 17 Non-English Languages

**Files:**
- Modify: All `lib/l10n/app_*.arb` files (ar, de, es, fr, hi, id, it, ja, ko, pt, ru, th, tl, tr, vi, zh, zh_TW)

- [ ] **Step 1: Create a script or manually add strings to each file**

For each language file, add the same keys with translated values. Example for Korean (app_ko.arb):

```json
  "incomingAudioCall": "음성 통화 수신",
  "incomingVideoCall": "영상 통화 수신",
  "outgoingCall": "전화 거는 중...",
  "callRinging": "벨이 울리는 중...",
  "callConnecting": "연결 중...",
  "callConnected": "연결됨",
  "callReconnecting": "재연결 중...",
  "callEnded": "통화 종료",
  "callFailed": "통화 실패",
  "callMissed": "부재중 전화",
  "callDeclined": "통화 거절됨",
  "acceptCall": "수락",
  "declineCall": "거절",
  "endCall": "종료",
  "muteCall": "음소거",
  "unmuteCall": "음소거 해제",
  "speakerOn": "스피커",
  "speakerOff": "수화기",
  "videoOn": "비디오 켜기",
  "videoOff": "비디오 끄기",
  "switchCamera": "카메라 전환",
  "callHistory": "통화 기록",
  "noCallHistory": "통화 기록 없음",
  "callBack": "다시 전화",
  "audioCall": "음성 통화",
  "createVoiceRoom": "음성방 만들기",
  "raiseHand": "손 들기",
  "lowerHand": "손 내리기",
  "handRaisedNotification": "손을 들었습니다! 호스트가 확인할 것입니다.",
  "handLoweredNotification": "손을 내렸습니다",
  "roomEnded": "호스트가 방을 종료했습니다",
  "youWereRemoved": "방에서 내보내졌습니다",
  "roomIsFull": "방이 가득 찼습니다"
```

- [ ] **Step 2: Run flutter gen-l10n**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app && flutter gen-l10n
```

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/
git commit -m "feat(l10n): add call and voice room strings for all 18 languages"
```

---

## Final Steps

### Task F.1: Integration Testing

- [ ] **Step 1: Test 1-on-1 audio call flow**

1. Open app on two devices
2. Exchange 3+ messages
3. Tap audio call button
4. Verify incoming call screen appears
5. Accept call
6. Verify call connects
7. Test mute/unmute
8. End call

- [ ] **Step 2: Test 1-on-1 video call flow**

Same as above but with video.

- [ ] **Step 3: Test voice room flow**

1. Create a voice room
2. Join from another device
3. Verify participants appear
4. Test mute/unmute
5. Test raise hand
6. Leave room

- [ ] **Step 4: Test call history**

1. Make a few calls
2. Open call history screen
3. Verify calls appear with correct status
4. Tap to call back

---

### Task F.2: Final Commit and Tag

- [ ] **Step 1: Ensure all tests pass**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app && flutter test
```

- [ ] **Step 2: Final commit**

```bash
git add .
git commit -m "feat: complete voice/video calls and voice rooms implementation"
```

- [ ] **Step 3: Create release tag**

```bash
git tag -a v1.x.0-calls -m "Voice/Video Calls and Voice Rooms"
```

---

## Summary

| Phase | Tasks | Estimated Files |
|-------|-------|-----------------|
| Phase 1: Fix 1-on-1 Calls | 8 tasks | ~6 modified, 3 created |
| Phase 2: Voice Rooms | 7 tasks | ~4 modified, 3 created |
| Phase 3: Call History | 4 tasks | 4 created |
| Phase 4: Localizations | 1 task | 18 modified |
| Final | 2 tasks | - |

**Total: 22 tasks across 4 phases**
