# Voice & Video Calls + Voice Rooms — Design Specification

## Overview

Implement complete voice/video calling and voice room functionality for BananaTalk, integrating with the existing backend WebRTC signaling infrastructure.

### Scope

| Feature | Status |
|---------|--------|
| 1-on-1 Audio Calls | Enhance existing |
| 1-on-1 Video Calls | Enhance existing |
| Voice Rooms (Group Audio) | New implementation |
| Call History | New implementation |
| Localizations (18 languages) | New strings |

### Key Decisions

- **Architecture**: Extend existing services (Approach A)
- **Call history location**: Within individual chats + Profile/Settings section
- **Incoming calls**: Full-screen takeover (current behavior)
- **Call button restriction**: Show disabled with tooltip until 3+ messages exchanged
- **Voice room UI**: Keep existing beautiful design, wire up WebRTC

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         UI LAYER                             │
│  ┌────────────────┐ ┌────────────────┐ ┌─────────────────┐  │
│  │ ActiveCallScreen│ │IncomingCallScreen│ │VoiceRoomScreen │  │
│  └───────┬────────┘ └───────┬────────┘ └────────┬────────┘  │
│          └──────────────────┴───────────────────┘            │
│                             │                                │
│  ┌──────────────────────────┴──────────────────────────┐    │
│  │              RIVERPOD PROVIDERS                      │    │
│  │  callProvider (existing)  │  voiceRoomProvider (new) │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                      SERVICE LAYER                           │
│  ┌─────────────────┐              ┌──────────────────────┐  │
│  │  CallManager    │              │  VoiceRoomManager    │  │
│  │  (enhanced)     │              │  (NEW)               │  │
│  └────────┬────────┘              └───────────┬──────────┘  │
│           └──────────────┬────────────────────┘             │
│                          ▼                                   │
│           ┌─────────────────────────────┐                   │
│           │  WebRTCService (enhanced)   │                   │
│           │  • Single peer (1-on-1)     │                   │
│           │  • Multi-peer mesh (rooms)  │                   │
│           └──────────────┬──────────────┘                   │
│                          ▼                                   │
│           ┌─────────────────────────────┐                   │
│           │  ChatSocketService          │                   │
│           │  • call:* events            │                   │
│           │  • voiceroom:* events       │                   │
│           └─────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. WebRTCService Enhancements

**Current state**: Manages single `RTCPeerConnection` for 1-on-1 calls.

**Required changes**:

```dart
class WebRTCService {
  // Existing (keep)
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer localRenderer;
  RTCVideoRenderer remoteRenderer;

  // NEW: Multi-peer support for voice rooms
  Map<String, RTCPeerConnection> _peerConnections = {};
  Map<String, MediaStream> _remoteStreams = {};

  // NEW: Mode switching
  enum WebRTCMode { singlePeer, multiPeer }
  WebRTCMode _mode = WebRTCMode.singlePeer;

  // NEW: Multi-peer methods
  Future<void> initializeMultiPeer(List<dynamic> iceServers);
  Future<void> createPeerConnection(String peerId, List<dynamic> iceServers);
  Future<void> createOfferForPeer(String peerId);
  Future<void> handleOfferFromPeer(String peerId, RTCSessionDescription offer);
  Future<void> handleAnswerFromPeer(String peerId, RTCSessionDescription answer);
  Future<void> addIceCandidateForPeer(String peerId, RTCIceCandidate candidate);
  void removePeer(String peerId);
  void disposeAllPeers();

  // NEW: Callbacks for multi-peer
  Function(String peerId, RTCSessionDescription)? onOfferCreatedForPeer;
  Function(String peerId, RTCSessionDescription)? onAnswerCreatedForPeer;
  Function(String peerId, RTCIceCandidate)? onIceCandidateForPeer;
  Function(String peerId, MediaStream)? onRemoteStreamForPeer;
  Function(String peerId)? onPeerDisconnected;
}
```

### 2. CallManager Enhancements

**Missing socket emissions to add**:

```dart
// In CallManager

void toggleMute() {
  _webrtcService.toggleMicrophone();
  // NEW: Emit to server
  _socket?.emit('call:mute', {
    'callId': currentCall?.callId,
    'isMuted': !_webrtcService.isMicrophoneEnabled,
  });
}

void toggleVideo() {
  _webrtcService.toggleCamera();
  // NEW: Emit to server
  _socket?.emit('call:video-toggle', {
    'callId': currentCall?.callId,
    'isVideoEnabled': _webrtcService.isCameraEnabled,
  });
}

// NEW: Reconnection handling
void _handleReconnecting() {
  _socket?.emit('call:reconnecting', {'callId': currentCall?.callId});
  onReconnecting?.call();
}

void _handleReconnected() {
  _socket?.emit('call:reconnected', {'callId': currentCall?.callId});
  onReconnected?.call();
}

// NEW: Listen for peer state changes
void _setupAdditionalListeners() {
  _socket?.on('call:mute', (data) {
    onPeerMuteChanged?.call(data['isMuted']);
  });

  _socket?.on('call:video-toggle', (data) {
    onPeerVideoChanged?.call(data['isVideoEnabled']);
  });

  _socket?.on('call:peer-reconnecting', (data) {
    onPeerReconnecting?.call();
  });

  _socket?.on('call:peer-reconnected', (data) {
    onPeerReconnected?.call();
  });

  _socket?.on('call:timeout', (data) {
    _handleCallTimeout();
  });
}
```

### 3. VoiceRoomManager (NEW)

```dart
class VoiceRoomManager {
  static final VoiceRoomManager _instance = VoiceRoomManager._internal();
  factory VoiceRoomManager() => _instance;
  VoiceRoomManager._internal();

  final WebRTCService _webrtcService = WebRTCService();
  ChatSocketService? _chatSocketService;
  IO.Socket? _socket;

  VoiceRoom? currentRoom;
  List<RoomParticipant> participants = [];
  bool isMuted = true; // Start muted by default
  bool isHandRaised = false;

  // Callbacks
  Function(VoiceRoom)? onRoomJoined;
  Function(RoomParticipant)? onParticipantJoined;
  Function(String odeparticipants? on departicipantLeftParticipantLeft;
  Function(String odeparticipants,bool)? onParticipantSpeaking;
  Function(String odeparticipants,bool)? onParticipantMuted;
  Function(RoomParticipant)? onHandRaised;
  Function(ChatMessage)? onChatMessage;
  Function()? onRoomEnded;
  Function(String)? onError;

  Future<void> initialize(ChatSocketService chatSocketService);

  // Room lifecycle
  Future<VoiceRoom> createRoom(CreateRoomRequest request);
  Future<void> joinRoom(String roomId);
  Future<void> leaveRoom();

  // Participant actions
  void toggleMute();
  void toggleHandRaise();
  void sendChatMessage(String message);

  // Host actions
  void muteParticipant(String odeparticipants);
  void kickParticipant(String odeparticipants);
  void promoteToCoHost(String odeparticipants);
  void endRoom();

  // WebRTC mesh management
  Future<void> _connectToPeer(String odeparticipants);
  void _disconnectFromPeer(String odeparticipants);
  void _handleNewParticipant(RoomParticipant participant);
}
```

### 4. VoiceRoomProvider (NEW)

```dart
final voiceRoomManagerProvider = Provider<VoiceRoomManager>((ref) {
  return VoiceRoomManager();
});

final voiceRoomProvider = ChangeNotifierProvider<VoiceRoomNotifier>((ref) {
  return VoiceRoomNotifier(ref.read(voiceRoomManagerProvider));
});

class VoiceRoomNotifier extends ChangeNotifier {
  final VoiceRoomManager _manager;

  VoiceRoom? get currentRoom => _manager.currentRoom;
  List<RoomParticipant> get participants => _manager.participants;
  bool get isMuted => _manager.isMuted;
  bool get isHandRaised => _manager.isHandRaised;
  bool get isHost => currentRoom?.hostId == _currentUserId;

  // Room state
  VoiceRoomState state = VoiceRoomState.idle;
  String? errorMessage;
  List<VoiceRoomChatMessage> chatMessages = [];

  Future<void> createRoom(CreateRoomRequest request);
  Future<void> joinRoom(String roomId);
  Future<void> leaveRoom();
  void toggleMute();
  void toggleHandRaise();
  void sendChat(String message);

  // Host-only
  void muteParticipant(String odeparticipants);
  void kickParticipant(String odeparticipants);
  void endRoom();
}

enum VoiceRoomState { idle, joining, connected, reconnecting, error }
```

### 5. CallHistoryService (NEW)

```dart
class CallHistoryService {
  final ApiClient _apiClient;

  CallHistoryService(this._apiClient);

  /// Get paginated call history
  Future<PaginatedResponse<CallRecord>> getCallHistory({
    int page = 1,
    int limit = 20,
  });

  /// Get call history for specific user (for in-chat display)
  Future<List<CallRecord>> getCallHistoryWithUser(String odeparticipants);

  /// Get missed calls count (for badge)
  Future<int> getMissedCallsCount();

  /// Mark calls as seen
  Future<void> markCallsAsSeen(List<String> callIds);

  /// Get single call details
  Future<CallRecord> getCallDetails(String callId);
}

class CallRecord {
  final String id visib;
  final List<CallParticipant> participants;
  final CallType type;
  final CallRecordStatus status; // answered, missed, rejected
  final int? duration; // seconds
  final DateTime startTime;
  final DateTime? endTime;
  final String initiatorId;
  final CallDirection direction; // relative to current user
}
```

---

## Socket Events

### 1-on-1 Calls (call:*)

| Event | Direction | Purpose |
|-------|-----------|---------|
| `call:initiate` | Client → Server | Start outgoing call |
| `call:incoming` | Server → Client | Notify of incoming call |
| `call:answer` | Client → Server | Accept/reject call |
| `call:accepted` | Server → Client | Call was accepted |
| `call:rejected` | Server → Client | Call was rejected |
| `call:offer` | Bidirectional | WebRTC SDP offer |
| `call:answer-sdp` | Bidirectional | WebRTC SDP answer |
| `call:ice-candidate` | Bidirectional | ICE candidates |
| `call:end` | Client → Server | End the call |
| `call:ended` | Server → Client | Call ended notification |
| `call:mute` | Bidirectional | Mute state changed |
| `call:video-toggle` | Bidirectional | Video state changed |
| `call:timeout` | Server → Client | Call not answered (60s) |
| `call:missed` | Server → Client | Missed call notification |
| `call:reconnecting` | Bidirectional | Connection issues |
| `call:reconnected` | Bidirectional | Connection restored |
| `call:failed` | Bidirectional | Connection failed |

### Voice Rooms (voiceroom:*)

| Event | Direction | Purpose |
|-------|-----------|---------|
| `voiceroom:join` | Client → Server | Join room's socket channel |
| `voiceroom:joined` | Server → Client | Successfully joined with participant list |
| `voiceroom:leave` | Client → Server | Leave the room |
| `voiceroom:user_joined` | Server → Client | New participant joined |
| `voiceroom:user_left` | Server → Client | Participant left |
| `voiceroom:speaking` | Bidirectional | Voice activity indicator |
| `voiceroom:mute` | Bidirectional | Mute state changed |
| `voiceroom:raise_hand` | Client → Server | Request to speak |
| `voiceroom:hand_raised` | Server → Client | Someone raised hand |
| `voiceroom:chat` | Bidirectional | In-room text message |
| `voiceroom:rtc_offer` | Bidirectional | WebRTC offer to specific peer |
| `voiceroom:rtc_answer` | Bidirectional | WebRTC answer to specific peer |
| `voiceroom:ice_candidate` | Bidirectional | ICE candidate to specific peer |
| `voiceroom:ended` | Server → Client | Room closed by host |
| `voiceroom:error` | Server → Client | Error occurred |

---

## UI Components

### 1. ActiveCallScreen Enhancements

**Current issues to fix**:
- Add call duration timer
- Add connection state indicator (connecting, connected, reconnecting)
- Add peer mute/video state indicators
- Implement speaker toggle
- Replace hardcoded strings with localizations

**New widgets needed**:
```dart
// Call duration timer
class CallDurationTimer extends StatefulWidget {
  final DateTime startTime;
  // Displays: 00:00, 01:23, etc.
}

// Connection quality indicator
class ConnectionQualityIndicator extends StatelessWidget {
  final ConnectionQuality quality; // good, fair, poor
  // Shows colored bars or icon
}

// Peer state indicator (shown when peer mutes/disables video)
class PeerStateIndicator extends StatelessWidget {
  final bool isMuted;
  final bool isVideoEnabled;
}
```

### 2. IncomingCallScreen Enhancements

- Replace hardcoded strings with localizations
- Add caller's profile picture loading state
- Add ringtone/vibration (via flutter_ringtone_player or system)

### 3. VoiceRoomScreen Enhancements

**Current state**: Beautiful UI, but no WebRTC integration.

**Required changes**:
- Connect to VoiceRoomProvider instead of local state
- Wire up mute toggle to actually mute audio
- Wire up raise hand to emit socket event
- Add real-time participant updates
- Add speaking indicators (animate avatar border)
- Add in-room chat drawer/panel
- Replace hardcoded strings with localizations

### 4. Call History UI (NEW)

**In-chat display** (`chat_screen.dart`):
```dart
// Show call entries in chat message list
class CallHistoryBubble extends StatelessWidget {
  final CallRecord call;
  // Shows: icon, "Voice call" or "Video call", duration, timestamp
  // Missed calls shown in red
}
```

**Profile/Settings section** (new screen):
```dart
class CallHistoryScreen extends ConsumerWidget {
  // List of all calls
  // Grouped by date
  // Tap to call back
  // Shows: avatar, name, call type icon, time, duration
}
```

### 5. Call Button States

**In chat app bar**:
```dart
class CallButtons extends ConsumerWidget {
  final String recipientId;
  final int messageCount;

  @override
  Widget build(context, ref) {
    final canCall = messageCount >= 3;

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.call),
          onPressed: canCall ? () => _initiateCall(CallType.audio) : null,
          tooltip: canCall ? null : context.l10n.exchange3MessagesBeforeCall,
        ),
        IconButton(
          icon: Icon(Icons.videocam),
          onPressed: canCall ? () => _initiateCall(CallType.video) : null,
          tooltip: canCall ? null : context.l10n.exchange3MessagesBeforeCall,
        ),
      ],
    );
  }
}
```

---

## Data Models

### Enhanced CallModel

```dart
class CallModel {
  final String callId;
  final String odeparticipants;
  final String userName;
  final String? userProfilePicture;
  final CallType callType;
  final CallDirection direction;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;

  // NEW fields
  final bool isPeerMuted;
  final bool isPeerVideoEnabled;
  final ConnectionState connectionState;
}

enum ConnectionState { connecting, connected, reconnecting, failed }
```

### VoiceRoom Model (existing, verify alignment)

```dart
class VoiceRoom {
  final String id visib;
  final String title;
  final String topic;
  final String language;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final int maxParticipants;
  final List<RoomParticipant> participants;
  final DateTime createdAt;
  final VoiceRoomStatus status;
  final VoiceRoomSettings settings;
}

class RoomParticipant {
  final String id visib;
  final String name;
  final String avatar;
  final bool isHost;
  final bool isCoHost;
  final bool isSpeaking;
  final bool isMuted;
  final bool hasHandRaised;
  final DateTime joinedAt;
}

class VoiceRoomSettings {
  final bool allowRaiseHand;
  final bool allowChat;
}
```

---

## Localizations

### New strings required (~50 strings × 18 languages)

```json
{
  "// 1-on-1 Calls": "",
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
  "callDuration": "Duration: {duration}",

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

  "// Voice Rooms": "",
  "voiceRoom": "Voice Room",
  "voiceRooms": "Voice Rooms",
  "createRoom": "Create Room",
  "joinRoom": "Join Room",
  "leaveRoom": "Leave Room",
  "roomTitle": "Room Title",
  "roomTopic": "Topic",
  "roomLanguage": "Language",
  "roomHost": "Host",
  "roomParticipants": "{count} participants",
  "roomMaxParticipants": "Max {count} participants",

  "raiseHand": "Raise Hand",
  "lowerHand": "Lower Hand",
  "handRaisedNotification": "Hand raised! The host will see your request.",
  "handLoweredNotification": "Hand lowered",

  "muteParticipant": "Mute",
  "kickParticipant": "Remove",
  "promoteToCoHost": "Make Co-Host",
  "endRoomConfirm": "End Room?",
  "endRoomMessage": "This will end the room for all participants.",
  "leaveRoomConfirm": "Leave Room?",
  "leaveRoomMessage": "Are you sure you want to leave this voice room?",
  "stay": "Stay",
  "leave": "Leave",

  "// Call History": "",
  "callHistory": "Call History",
  "noCallHistory": "No call history",
  "missedCalls": "Missed Calls",
  "allCalls": "All Calls",
  "callBack": "Call Back",
  "audioCall": "Audio Call",
  "videoCall": "Video Call",
  "callAt": "at {time}"
}
```

---

## Error Handling

### Connection Errors

| Scenario | User Feedback | Recovery Action |
|----------|---------------|-----------------|
| Socket disconnected during call | "Reconnecting..." toast | Auto-reconnect, retry 3 times |
| ICE connection failed | "Connection failed" dialog | Offer retry or end call |
| Peer disconnected unexpectedly | "Other user disconnected" | Auto-end call |
| Permission denied | Specific permission dialog | Link to settings |
| User offline | "User is offline" toast | Disable call button |
| User busy | "User is busy" toast | Show "try again later" |
| Call timeout (60s) | "No answer" | Auto-end, show missed call |

### Voice Room Errors

| Scenario | User Feedback | Recovery Action |
|----------|---------------|-----------------|
| Room full | "Room is full" toast | Stay on room list |
| Room ended | "Room ended by host" dialog | Return to room list |
| Kicked from room | "You were removed" dialog | Return to room list |
| Connection lost | "Reconnecting..." | Auto-reconnect to room |

---

## Testing Considerations

### Unit Tests

- CallManager: test call state transitions
- VoiceRoomManager: test room lifecycle
- WebRTCService: test peer connection management
- CallHistoryService: test API responses

### Integration Tests

- Full call flow: initiate → ring → accept → connected → end
- Voice room flow: create → join → multiple participants → leave
- Permission flows: denied, granted, permanently denied

### Manual Testing Checklist

- [ ] Audio call between two devices
- [ ] Video call between two devices
- [ ] Call rejection
- [ ] Call timeout (60 seconds)
- [ ] Mute/unmute during call
- [ ] Video on/off during call
- [ ] Switch camera during video call
- [ ] Speaker toggle during audio call
- [ ] Voice room with 3+ participants
- [ ] Voice room chat
- [ ] Raise hand feature
- [ ] Host mute participant
- [ ] Host kick participant
- [ ] Host end room
- [ ] Call history display in chat
- [ ] Call history in settings
- [ ] Push notification for incoming call (app backgrounded)
- [ ] All UI strings in non-English locale

---

## File Structure

```
lib/
├── models/
│   ├── call_model.dart              # Enhanced
│   ├── call_record_model.dart       # NEW
│   └── community/
│       └── voice_room_model.dart    # Verify/enhance
│
├── services/
│   ├── webrtc_service.dart          # Enhanced (multi-peer)
│   ├── call_manager.dart            # Enhanced (missing events)
│   ├── voice_room_manager.dart      # NEW
│   ├── call_history_service.dart    # NEW
│   └── chat_socket_service.dart     # Enhanced (voiceroom:* events)
│
├── providers/
│   ├── call_provider.dart           # Enhanced
│   └── voice_room_provider.dart     # NEW
│
├── screens/
│   ├── active_call_screen.dart      # Enhanced
│   ├── incoming_call_screen.dart    # Enhanced
│   └── call_history_screen.dart     # NEW
│
├── pages/
│   └── community/
│       └── voice_rooms/
│           ├── voice_room_screen.dart    # Enhanced (WebRTC)
│           ├── voice_rooms_tab.dart      # Enhanced (real data)
│           └── create_room_sheet.dart    # Enhanced (API call)
│
├── widgets/
│   ├── call/                        # NEW directory
│   │   ├── call_duration_timer.dart
│   │   ├── connection_quality_indicator.dart
│   │   ├── call_history_bubble.dart
│   │   └── call_buttons.dart
│   └── voice_room/                  # NEW directory
│       ├── participant_tile.dart
│       ├── speaking_indicator.dart
│       └── room_chat_drawer.dart
│
└── l10n/
    ├── app_en.arb                   # Add ~50 strings
    ├── app_ko.arb                   # Add ~50 strings
    └── ... (16 more languages)
```

---

## Dependencies

**Already in pubspec.yaml** (no changes needed):
- `flutter_webrtc: ^1.2.0`
- `socket_io_client: ^2.0.3+1`
- `permission_handler: ^11.0.1`
- `flutter_riverpod: ^2.4.10`

**Consider adding**:
- `flutter_ringtone_player` — for incoming call ringtone (optional)
- `wakelock` — keep screen on during calls (optional)

---

## Implementation Priority

1. **Phase 1: Fix existing 1-on-1 calls**
   - Add missing socket emissions (mute, video-toggle)
   - Add call duration timer
   - Add localizations
   - Enable call buttons in chat

2. **Phase 2: Voice rooms**
   - WebRTCService multi-peer support
   - VoiceRoomManager implementation
   - Wire up VoiceRoomScreen to real WebRTC
   - Add voiceroom:* socket events

3. **Phase 3: Call history**
   - CallHistoryService
   - Call history screen
   - In-chat call bubbles

4. **Phase 4: Polish**
   - Connection quality indicators
   - Reconnection handling
   - Error states and edge cases
   - All 18 language translations
