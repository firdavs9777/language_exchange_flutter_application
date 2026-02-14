# Voice Messages Implementation Guide

## Overview

Voice messages allow users to send audio recordings in chat. The implementation supports both REST API upload and real-time Socket.IO delivery.

---

## Backend API

### REST API Endpoint

**Upload and Send Voice Message**

```
POST /api/v1/messages/voice
```

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request Body (multipart/form-data):**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| voice | File | Yes | Audio file (m4a, mp3, wav, aac, ogg) |
| receiver | String | Yes | Recipient user ID |
| duration | Number | No | Duration in seconds (auto-extracted if not provided) |
| waveform | JSON Array | No | Array of amplitude values for visualization |

**Response (200/201):**
```json
{
  "success": true,
  "message": "Voice message sent",
  "data": {
    "_id": "msg_123",
    "sender": "user_abc",
    "receiver": "user_xyz",
    "messageType": "voice",
    "media": {
      "type": "voice",
      "url": "https://storage.../voice_123.m4a",
      "duration": 15,
      "waveform": [0.1, 0.5, 0.8, 0.3, ...]
    },
    "createdAt": "2025-01-31T00:00:00.000Z"
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Failed to send voice message"
}
```

---

## Socket.IO Events

### Send Voice Message (Pre-uploaded URL)

If you've already uploaded the audio file separately, use this socket event:

**Emit:**
```javascript
socket.emit('sendVoiceMessage', {
  receiver: 'userId',
  mediaUrl: 'https://storage.../voice_123.m4a',
  duration: 15,
  waveform: [0.1, 0.5, 0.8, 0.3, ...]
});
```

### Receive Voice Message

**Listen:**
```javascript
socket.on('newVoiceMessage', (data) => {
  // data.message - Full message object
  // data.duration - Voice duration in seconds
  console.log('New voice message:', data.message);
});
```

### Mark Voice Message as Played

When user listens to a voice message:

**Emit:**
```javascript
socket.emit('voiceMessagePlayed', {
  messageId: 'msg_123',
  senderId: 'sender_user_id'
});
```

### Receive Listened Notification

Sender receives when recipient plays their voice message:

**Listen:**
```javascript
socket.on('voiceMessageListened', (data) => {
  // data.messageId - The message that was listened to
  // data.listenedBy - User ID who listened
  console.log('Voice message listened:', data);
});
```

---

## Flutter Implementation

### Files Structure

```
lib/
├── services/
│   └── voice_message_service.dart    # Upload, download, utilities
├── widgets/
│   ├── voice_recorder_widget.dart    # Recording UI
│   └── voice_message_player.dart     # Playback UI
└── pages/chat/
    └── chat_single.dart              # Integration
```

### Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter_sound: ^9.2.13      # Recording
  audio_session: ^0.1.18      # Audio session management
  just_audio: ^0.9.36         # Playback
  permission_handler: ^11.0.1 # Microphone permission
  path_provider: ^2.1.1       # File storage
```

### Service: VoiceMessageService

```dart
import 'package:bananatalk_app/services/voice_message_service.dart';

// Send voice message
final result = await VoiceMessageService.sendVoiceMessage(
  receiverId: 'user_123',
  voiceFile: File('/path/to/recording.m4a'),
  durationSeconds: 15,
  waveform: [0.1, 0.5, 0.8, ...],  // Optional
);

if (result['success']) {
  Message message = result['data'];
  print('Voice message sent: ${message.id}');
} else {
  print('Error: ${result['error']}');
}

// Generate recording path
final path = await VoiceMessageService.generateRecordingPath();
// Returns: /tmp/voice_recordings/voice_1706659200000.m4a

// Format duration for display
String formatted = VoiceMessageService.formatDuration(125);
// Returns: "02:05"

// Download voice message for offline
final localFile = await VoiceMessageService.downloadVoiceMessage(
  url: 'https://storage.../voice_123.m4a',
  messageId: 'msg_123',
);

// Cleanup old recordings (older than 7 days)
await VoiceMessageService.cleanupOldRecordings(maxAgeDays: 7);
```

### Widget: VoiceRecorderWidget

Full-screen recording interface with waveform visualization:

```dart
import 'package:bananatalk_app/widgets/voice_recorder_widget.dart';

// Show as bottom sheet
showModalBottomSheet(
  context: context,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: Colors.transparent,
  builder: (context) => VoiceRecorderWidget(
    onRecordingComplete: (File file, int duration, List<double> waveform) async {
      Navigator.pop(context);
      // Send the voice message
      await _sendVoiceMessage(file, duration, waveform);
    },
    onCancel: () {
      Navigator.pop(context);
    },
  ),
);
```

**Features:**
- Live waveform visualization
- Duration display with recording indicator
- Pause/Resume recording
- Auto-stop at 5 minutes
- Minimum 1 second required
- Cancel/Delete recording

### Widget: VoiceRecordButton

Compact button for chat input bar:

```dart
import 'package:bananatalk_app/widgets/voice_recorder_widget.dart';

VoiceRecordButton(
  enabled: !_isSending,
  onRecordingComplete: (file, duration, waveform) async {
    await _sendVoiceMessage(file, duration, waveform);
  },
)
```

### Widget: VoiceMessagePlayer

Playback widget with progress and waveform:

```dart
import 'package:bananatalk_app/widgets/voice_message_player.dart';

VoiceMessagePlayer(
  audioUrl: message.media!.url,
  durationSeconds: message.media!.duration ?? 0,
  waveform: message.media!.waveform,
  isFromMe: message.sender == currentUserId,
  messageId: message.id,
  senderId: message.sender,
  onPlayed: () {
    // Emit socket event to mark as listened
    socket.emit('voiceMessagePlayed', {
      'messageId': message.id,
      'senderId': message.sender,
    });
  },
)
```

**Features:**
- Play/Pause toggle
- Progress bar with seek
- Waveform visualization
- Duration display
- Loading state

---

## Message Model

Voice messages use the standard Message model with `messageType: 'voice'`:

```dart
class Message {
  final String id;
  final String sender;
  final String receiver;
  final String messageType;  // 'voice'
  final Media? media;
  final DateTime createdAt;
  // ... other fields
}

class Media {
  final String type;         // 'voice'
  final String url;          // Audio file URL
  final int? duration;       // Duration in seconds
  final List<double>? waveform;  // Amplitude values for visualization
}
```

---

## Chat Integration

In `chat_single.dart`, voice messages are integrated as follows:

```dart
class _ChatScreenState extends ConsumerState<ChatScreen> {

  // Show recording bottom sheet
  void _showVoiceRecorder() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceRecorderWidget(
        onRecordingComplete: (file, duration, waveform) async {
          Navigator.pop(context);
          await _sendVoiceMessage(file, duration, waveform);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  // Send voice message via REST API
  Future<void> _sendVoiceMessage(
    File voiceFile,
    int durationSeconds,
    List<double> waveform,
  ) async {
    setState(() => _isSending = true);

    try {
      final result = await VoiceMessageService.sendVoiceMessage(
        receiverId: widget.userId,
        voiceFile: voiceFile,
        durationSeconds: durationSeconds,
        waveform: waveform,
      );

      if (result['success']) {
        await _loadMessages();  // Refresh messages
        await voiceFile.delete();  // Cleanup temp file
      } else {
        _showError(result['error']);
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  // Display voice message in chat
  Widget _buildVoiceMessage(Message message) {
    final isFromMe = message.sender == _currentUserId;

    return VoiceMessagePlayer(
      audioUrl: message.media!.url,
      durationSeconds: message.media!.duration ?? 0,
      waveform: message.media!.waveform,
      isFromMe: isFromMe,
      messageId: message.id,
      senderId: message.sender,
      onPlayed: () {
        // Notify sender that message was played
        ChatSocketService().socket?.emit('voiceMessagePlayed', {
          'messageId': message.id,
          'senderId': message.sender,
        });
      },
    );
  }
}
```

---

## Audio Specifications

| Property | Value |
|----------|-------|
| Format | AAC/M4A (recommended), MP3, WAV, OGG |
| Codec | Codec.aacMP4 |
| Bit Rate | 128 kbps |
| Sample Rate | 44100 Hz |
| Max Duration | 5 minutes |
| Min Duration | 1 second |

---

## Permissions

### iOS (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>BananaTalk needs microphone access to record voice messages</string>
```

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

---

## Storage

Voice messages are stored in:
- **Cloud:** `bananatalk/voice/` on your storage provider
- **Local (temp):** `{temp_dir}/voice_recordings/`

Old local recordings are automatically cleaned up after 7 days.

---

## Error Handling

Common errors and handling:

| Error | Cause | Solution |
|-------|-------|----------|
| "Microphone permission required" | Permission denied | Show permission dialog |
| "Recording too short" | < 1 second | Show minimum duration message |
| "Voice message file too large" | File > limit | Compress or limit duration |
| "Failed to play voice message" | Network/file error | Show retry option |
| "Message limit reached" | User at daily limit | Show upgrade dialog |

---

## Best Practices

1. **Always request microphone permission** before recording
2. **Show loading state** while uploading
3. **Delete temp files** after successful upload
4. **Cache downloaded voice messages** for offline playback
5. **Handle interruptions** (phone calls, app backgrounding)
6. **Validate duration** before sending (1s - 5min)
7. **Show visual feedback** during recording (waveform, timer)

---

## Testing

```bash
# Test voice message upload
curl -X POST https://api.bananatalk.com/api/v1/messages/voice \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "voice=@/path/to/audio.m4a" \
  -F "receiver=USER_ID" \
  -F "duration=15"
```

---

## Troubleshooting

### Recording doesn't start
- Check microphone permission
- Ensure audio session is properly configured
- Check if another app is using the microphone

### Playback fails
- Verify audio URL is accessible
- Check network connection
- Try downloading for offline playback

### Waveform not showing
- Ensure waveform data was saved with message
- Check if waveform array has valid values (0-1 range)

---

## Related Files

- `lib/services/voice_message_service.dart` - Service layer
- `lib/widgets/voice_recorder_widget.dart` - Recording UI
- `lib/widgets/voice_message_player.dart` - Playback UI
- `lib/pages/chat/chat_single.dart` - Chat integration
- `lib/providers/provider_models/message_model.dart` - Message model
- `lib/service/endpoints.dart` - API endpoints
