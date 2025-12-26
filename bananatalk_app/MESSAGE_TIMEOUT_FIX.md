# BananaTalk Chat - Socket.IO Implementation Fix

## Changes Made (Based on Official API Documentation)

### 1. Fixed `sendMessage` Event Format

**Before (Incorrect):**
```dart
_socket!.emit('sendMessage', {
  'sender': _currentUserId,  // Not needed - server gets from auth
  'receiver': widget.userId,
  'message': text,
  'type': messageType ?? 'text',  // Not documented
});
```

**After (Correct - Per API Docs):**
```dart
_socket!.emitWithAck('sendMessage', {
  'receiver': widget.userId,  // Required
  'message': text,            // Required
}, ack: (response) {
  // Handle callback response
  if (response['status'] == 'success') {
    // Message sent successfully
  } else {
    // Handle error: response['error']
  }
});
```

### 2. Fixed Typing Indicators

**Before:**
```dart
_socket?.emit('typing', {
  'sender': _currentUserId,  // Not needed
  'receiver': widget.userId,
});
```

**After (Per API Docs):**
```dart
_socket?.emit('typing', {
  'receiver': widget.userId,
});
```

### 3. Added Proper Event Listeners

| Event | Purpose | Handler |
|-------|---------|---------|
| `newMessage` | Incoming messages | Parse and display, mark as read |
| `messageSent` | Multi-device sync | Add to messages list |
| `messagesRead` | Read receipts | Update UI to show read status |
| `messageDeleted` | Deleted messages | Remove from messages list |
| `userTyping` | Typing indicator | Show "typing..." |
| `userStoppedTyping` | Stop typing | Hide "typing..." |
| `userStatusUpdate` | Online status | Update online/offline indicator |
| `onlineUsers` | Initial online users | Set initial status |

### 4. Added User Status Features

- **Request user status on connect:** `getUserStatus` event
- **Set own status:** `setOnline` event on connection
- **Listen for status changes:** `userStatusUpdate` event
- **Display in app bar:** Online/Offline with last seen time

### 5. Added Read Receipts

- **Mark messages as read:** `markAsRead` event when viewing chat
- **Listen for read confirmations:** `messagesRead` event
- **Update UI:** Show read status on sent messages

### 6. Enhanced Error Handling

- Uses `emitWithAck` for callback-based confirmation
- Proper error messages based on error type:
  - Limit exceeded → VIP upgrade prompt
  - Blocked user → Block message
  - Not found → User not found
  - Unauthorized → Re-login prompt
- Message restoration on all error paths
- Retry button with original message

### 7. Connection Status Indicators

- **Socket connection status:** Shows "Connecting..." when disconnected
- **User online status:** Green dot = Online, Gray dot = Offline
- **Last seen:** Shows how long ago user was active

## Files Modified

1. **`lib/pages/chat/chat_single.dart`**
   - Fixed `sendMessage` to use `emitWithAck` with callback
   - Fixed `typing`/`stopTyping` event format
   - Added proper event listeners for all socket events
   - Added user status tracking
   - Added `markAsRead` on message receive
   - Added automatic reconnection logic

2. **`lib/pages/chat/chat_app_bar.dart`**
   - Added `isOnline` and `lastSeen` properties
   - Added status widget with priority: typing > connecting > online/offline
   - Added last seen time formatting

## Socket.IO Event Reference (From API Docs)

### Events to Emit (Client → Server)

```dart
// Send message with callback
socket.emitWithAck('sendMessage', {
  'receiver': receiverId,
  'message': text,
}, ack: (response) { ... });

// Mark as read
socket.emitWithAck('markAsRead', {
  'senderId': senderId,
}, ack: (response) { ... });

// Typing indicators
socket.emit('typing', { 'receiver': receiverId });
socket.emit('stopTyping', { 'receiver': receiverId });

// User status
socket.emit('setOnline');
socket.emit('setAway');
socket.emit('setBusy');

socket.emitWithAck('getUserStatus', {
  'userId': targetUserId,
}, ack: (response) { ... });
```

### Events to Listen (Server → Client)

```dart
socket.on('newMessage', (data) {
  // data: { message, senderId, unreadCount }
});

socket.on('messageSent', (data) {
  // data: { message, receiverId, unreadCount }
});

socket.on('messagesRead', (data) {
  // data: { readBy, count }
});

socket.on('messageDeleted', (data) {
  // data: { messageId, senderId }
});

socket.on('userTyping', (data) {
  // data: { userId }
});

socket.on('userStoppedTyping', (data) {
  // data: { userId }
});

socket.on('userStatusUpdate', (data) {
  // data: { userId, status, lastSeen }
});

socket.on('onlineUsers', (users) {
  // users: [{ userId, status, lastSeen }, ...]
});
```

## Testing Checklist

- [ ] Send text message - verify callback response
- [ ] Receive message from other user
- [ ] Typing indicator shows when other user types
- [ ] Online status shows correctly
- [ ] Last seen time displays for offline users
- [ ] Connection status shows "Connecting..." when disconnected
- [ ] Messages marked as read when viewing chat
- [ ] Read receipts show on sent messages
- [ ] Error messages are clear and actionable
- [ ] Retry button works with original message
- [ ] Automatic reconnection works

## Troubleshooting

If messages still timeout:

1. **Check server logs** for incoming `sendMessage` events
2. **Verify callback** is being sent from server
3. **Check authentication** - token may be expired
4. **Check network** - try different connection
5. **Enable verbose logging** to see exact socket events

## Server-Side Requirements

The server MUST:

1. Handle `sendMessage` with callback:
```javascript
socket.on('sendMessage', (data, callback) => {
  try {
    const message = await createMessage(data);
    callback({ status: 'success', message });
  } catch (error) {
    callback({ status: 'error', error: error.message });
  }
});
```

2. Emit proper events to all relevant clients
3. Include all required fields in responses
4. Handle authentication via socket handshake
