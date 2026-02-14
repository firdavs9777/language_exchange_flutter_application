# Quick Start: Enable Push Notifications (Backend)

## 🎯 Goal
Send push notifications when users receive messages while app is closed/background.

## ✅ Current Status
- ✅ Frontend generates FCM tokens
- ✅ Frontend registers tokens with backend
- ✅ Socket messages work
- ❌ Push notifications not being sent

## 🔧 What You Need to Do

Add **ONE piece of code** to your socket message handler to send push notifications.

---

## 📝 Step-by-Step Implementation

### Step 1: Find Your Socket Message Handler

**File:** `socket/socketHandler.js` or `controllers/socketController.js`

Look for this code:
```javascript
socket.on('message', async (data) => {
  // Your existing message handling code
  const { receiverId, message } = data;
  const senderId = socket.userId;
  
  // Save message to database
  const newMessage = await Message.create({ ... });
  
  // Send via socket if recipient is online
  const recipientSocketId = onlineUsers.get(receiverId);
  if (recipientSocketId) {
    io.to(recipientSocketId).emit('message', messageData);
  }
  
  // Acknowledge sender
  socket.emit('message_sent', { status: 'success' });
});
```

---

### Step 2: Add Push Notification Code

**Replace the message handler with this:**

```javascript
socket.on('message', async (data) => {
  const { receiverId, message, messageType } = data;
  const senderId = socket.userId;
  
  try {
    // 1. Save message to database (your existing code)
    const newMessage = await Message.create({
      sender: senderId,
      receiver: receiverId,
      message: message,
      messageType: messageType || 'text'
    });
    
    // 2. Get sender info
    const sender = await User.findById(senderId).select('name');
    
    // 3. Check if recipient is online
    const recipientSocketId = onlineUsers.get(receiverId);
    const isRecipientOnline = !!recipientSocketId;
    
    if (isRecipientOnline) {
      // Recipient is ONLINE - send via socket
      console.log(`✅ Recipient ${receiverId} is online, sending via socket`);
      io.to(recipientSocketId).emit('message', {
        message: newMessage,
        senderId: senderId
      });
    } else {
      // Recipient is OFFLINE - send push notification
      console.log(`📱 Recipient ${receiverId} is offline, sending push notification...`);
      
      try {
        // Import at top of file: const notificationService = require('../services/notificationService');
        await notificationService.sendNotification({
          userId: receiverId,
          type: 'chat_message',
          title: sender.name,
          body: message.length > 100 ? message.substring(0, 100) + '...' : message,
          data: {
            type: 'chat_message',
            senderId: senderId.toString(),
            conversationId: newMessage._id.toString(),
            messageId: newMessage._id.toString(),
            screen: 'chat'
          }
        });
        console.log('✅ Push notification sent successfully');
      } catch (notifError) {
        console.error('❌ Error sending push notification:', notifError);
        // Don't fail the message if notification fails
      }
    }
    
    // 4. Acknowledge sender
    socket.emit('message_sent', { 
      status: 'success',
      message: newMessage 
    });
    
  } catch (error) {
    console.error('❌ Error handling message:', error);
    socket.emit('message_error', { error: error.message });
  }
});
```

---

### Step 3: Add Import at Top of File

At the top of your socket handler file, add:

```javascript
const notificationService = require('../services/notificationService');
// Adjust path based on your file structure
```

---

### Step 4: Verify Notification Service Exists

Make sure `services/notificationService.js` has this method:

```javascript
async sendNotification({ userId, type, title, body, data = {} }) {
  // Get user's FCM tokens
  const user = await User.findById(userId).select('fcmTokens');
  
  if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
    console.log(`⚠️ No FCM tokens for user ${userId}`);
    return { success: false };
  }
  
  // Get all tokens
  const fcmTokens = user.fcmTokens.map(t => t.token);
  
  // Send via Firebase Admin SDK
  const message = {
    notification: { title, body },
    data: { ...data, type, timestamp: Date.now().toString() },
    tokens: fcmTokens,
    apns: {
      payload: {
        aps: { badge: 1, sound: 'default', 'content-available': 1 }
      }
    },
    android: {
      priority: 'high',
      notification: { channelId: 'chat_messages', priority: 'high' }
    }
  };
  
  const response = await admin.messaging().sendMulticast(message);
  console.log(`📨 Sent to ${response.successCount}/${fcmTokens.length} devices`);
  
  return { success: true, successCount: response.successCount };
}
```

*If this file doesn't exist, check `BACKEND_PUSH_NOTIFICATIONS_GUIDE.md` lines 128-221 for full implementation.*

---

## 🧪 Testing

### Test 1: Check Logs

After implementing, restart your server and send a message:

**Expected logs:**
```
📤 Message: 69423c0cb696bd1f501fe3e1 → 694358a0b696bd1f501ff051
📱 Recipient 694358a0b696bd1f501ff051 is offline, sending push notification...
✅ Push notification sent successfully
📨 Sent to 1/1 devices
```

### Test 2: Real Device Test

1. **User A**: Close app completely
2. **User B**: Send a message to User A
3. **User A**: Should see push notification appear! 📱
4. **Tap notification**: App opens to that chat

---

## 📊 What Happens

### Scenario 1: Recipient Online
```
Message arrives
  ↓
Check: Is recipient online?
  ↓
YES → Send via socket (real-time)
  ↓
Message appears instantly in app
```

### Scenario 2: Recipient Offline
```
Message arrives
  ↓
Check: Is recipient online?
  ↓
NO → Send push notification
  ↓
FCM delivers to device
  ↓
Notification appears on phone
  ↓
User taps → Opens app
```

---

## 🐛 Troubleshooting

### Issue 1: "No FCM tokens for user"
**Solution:** User needs to login on Flutter app to register token

### Issue 2: "sendMulticast is not a function"
**Solution:** Make sure Firebase Admin SDK is initialized:
```javascript
const admin = require('firebase-admin');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
```

### Issue 3: Notification not appearing
**Checklist:**
- [ ] User has FCM token in database
- [ ] Backend logs show "✅ Push notification sent successfully"
- [ ] User's app is closed/background
- [ ] User granted notification permissions

---

## ✅ Verification Checklist

- [ ] Code added to socket message handler
- [ ] Import added at top of file
- [ ] Server restarted
- [ ] Test message sent to offline user
- [ ] Logs show: `📱 Recipient is offline, sending push notification...`
- [ ] Logs show: `✅ Push notification sent successfully`
- [ ] Push notification appears on device
- [ ] Tapping notification opens correct chat

---

## 🎯 Summary

**What you're adding:**
- Check if recipient is online/offline
- If offline → send push notification
- If online → send via socket (existing behavior)

**Code to add:**
- ~30 lines in socket handler
- 1 import statement

**Time required:**
- 5-10 minutes

**Impact:**
- Push notifications work for all offline users! 🚀

---

## 📞 Need Help?

**Check these files:**
- `BACKEND_PUSH_NOTIFICATIONS_GUIDE.md` - Full implementation details
- `FCM_TOKEN_REGISTRATION_FIX.md` - Frontend token registration
- `FIREBASE_SETUP_INSTRUCTIONS.md` - Firebase setup

**Test the notification API directly:**
```bash
curl -X POST https://api.banatalk.com/api/v1/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"userId": "69423c0cb696bd1f501fe3e1", "type": "chat_message"}'
```

---

**Last Updated:** December 18, 2024  
**Status:** Ready to implement  
**Difficulty:** Easy (5-10 minutes)

