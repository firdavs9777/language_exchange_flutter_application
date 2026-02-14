# Backend Push Notifications Implementation Guide

## 📱 Current Status

✅ **Frontend is 100% Ready:**
- FCM tokens are being generated and stored
- App can receive push notifications
- Deep linking with go_router is implemented
- Notification permissions are granted

❌ **Backend Missing:**
- Push notifications are NOT being sent when messages arrive
- Need to integrate FCM notification sending in socket handlers

## 🎯 What Needs to Be Done

When a user sends a chat message, the backend needs to:
1. ✅ Send the message via socket (already working)
2. ❌ **Send a push notification if the recipient is offline/background** (MISSING)

---

## 📋 Implementation Steps

### Step 1: Verify FCM Token Registration

**Check if tokens are being stored:**

```javascript
// In your User model, verify this exists:
const userSchema = new mongoose.Schema({
  // ... other fields ...
  fcmTokens: [{
    token: String,
    platform: String,  // 'ios' or 'android'
    deviceId: String,
    createdAt: { type: Date, default: Date.now },
    lastUsed: { type: Date, default: Date.now }
  }]
});
```

**Test Query:**
```javascript
// Check if user has FCM token
const user = await User.findById('69423c0cb696bd1f501fe3e1');
console.log('FCM Tokens:', user.fcmTokens);

// Expected output:
// [{
//   token: "eXwacvP6CUwUlNKqZ8dmIA:APA91b...",
//   platform: "ios",
//   deviceId: "iPhone_12345"
// }]
```

---

### Step 2: Update Socket Handler for Chat Messages

**File:** `socket/socketHandler.js` or wherever you handle socket events

#### Current Code (What You Have):
```javascript
socket.on('message', async (data) => {
  try {
    const { receiverId, message, messageType } = data;
    const senderId = socket.userId;
    
    // Save message to database
    const newMessage = await Message.create({
      sender: senderId,
      receiver: receiverId,
      message: message,
      messageType: messageType
    });
    
    // Send to recipient via socket
    const recipientSocketId = onlineUsers.get(receiverId);
    if (recipientSocketId) {
      io.to(recipientSocketId).emit('message', {
        message: newMessage,
        senderId: senderId
      });
    }
    
    // Acknowledge to sender
    socket.emit('message_sent', { 
      status: 'success',
      message: newMessage 
    });
    
  } catch (error) {
    console.error('Error sending message:', error);
  }
});
```

#### Updated Code (What You Need):
```javascript
socket.on('message', async (data) => {
  try {
    const { receiverId, message, messageType } = data;
    const senderId = socket.userId;
    
    // Save message to database
    const newMessage = await Message.create({
      sender: senderId,
      receiver: receiverId,
      message: message,
      messageType: messageType
    });
    
    // Get sender info for notification
    const sender = await User.findById(senderId).select('name profileImages');
    
    // Check if recipient is online
    const recipientSocketId = onlineUsers.get(receiverId);
    const isRecipientOnline = !!recipientSocketId;
    
    if (isRecipientOnline) {
      // Send via socket if online
      io.to(recipientSocketId).emit('message', {
        message: newMessage,
        senderId: senderId
      });
    } else {
      // 🔥 SEND PUSH NOTIFICATION IF OFFLINE
      console.log(`📱 Recipient ${receiverId} is offline, sending push notification...`);
      
      try {
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
        // Don't fail the message send if notification fails
      }
    }
    
    // Acknowledge to sender
    socket.emit('message_sent', { 
      status: 'success',
      message: newMessage 
    });
    
  } catch (error) {
    console.error('Error sending message:', error);
  }
});
```

---

### Step 3: Verify Notification Service

**File:** `services/notificationService.js`

Make sure your notification service has this method:

```javascript
class NotificationService {
  /**
   * Send push notification to a user
   * @param {Object} options
   * @param {String} options.userId - User ID to send to
   * @param {String} options.type - Notification type (chat_message, moment_like, etc)
   * @param {String} options.title - Notification title
   * @param {String} options.body - Notification body
   * @param {Object} options.data - Additional data for deep linking
   */
  async sendNotification({ userId, type, title, body, data = {} }) {
    try {
      // Get user's FCM tokens
      const user = await User.findById(userId).select('fcmTokens notificationSettings');
      
      if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
        console.log(`⚠️ No FCM tokens found for user ${userId}`);
        return { success: false, message: 'No FCM tokens' };
      }
      
      // Check if user has notifications enabled
      if (user.notificationSettings && !user.notificationSettings.enabled) {
        console.log(`⚠️ Notifications disabled for user ${userId}`);
        return { success: false, message: 'Notifications disabled' };
      }
      
      // Check type-specific settings
      if (type === 'chat_message' && user.notificationSettings && !user.notificationSettings.chatMessages) {
        console.log(`⚠️ Chat notifications disabled for user ${userId}`);
        return { success: false, message: 'Chat notifications disabled' };
      }
      
      // Prepare FCM message
      const fcmTokens = user.fcmTokens.map(t => t.token);
      
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          ...data,
          type: type,
          timestamp: Date.now().toString()
        },
        tokens: fcmTokens,
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              'content-available': 1,
              'mutable-content': 1
            }
          }
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'chat_messages',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true
          }
        }
      };
      
      // Send via Firebase Admin SDK
      const response = await admin.messaging().sendMulticast(message);
      
      console.log(`✅ Notification sent: ${response.successCount} success, ${response.failureCount} failed`);
      
      // Remove invalid tokens
      if (response.failureCount > 0) {
        const tokensToRemove = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.log(`❌ Failed to send to token ${idx}:`, resp.error);
            if (resp.error.code === 'messaging/invalid-registration-token' ||
                resp.error.code === 'messaging/registration-token-not-registered') {
              tokensToRemove.push(fcmTokens[idx]);
            }
          }
        });
        
        // Remove invalid tokens from database
        if (tokensToRemove.length > 0) {
          await User.findByIdAndUpdate(userId, {
            $pull: { fcmTokens: { token: { $in: tokensToRemove } } }
          });
          console.log(`🗑️ Removed ${tokensToRemove.length} invalid tokens`);
        }
      }
      
      // Save to notification history
      await Notification.create({
        user: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: false
      });
      
      return { 
        success: true, 
        successCount: response.successCount,
        failureCount: response.failureCount
      };
      
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      throw error;
    }
  }
}

module.exports = new NotificationService();
```

---

### Step 4: Test the Implementation

#### Test 1: Check FCM Token Storage

```javascript
// In MongoDB or via API
db.users.findOne(
  { _id: ObjectId("69423c0cb696bd1f501fe3e1") },
  { fcmTokens: 1 }
)

// Expected:
{
  "_id": "69423c0cb696bd1f501fe3e1",
  "fcmTokens": [{
    "token": "eXwacvP6CUwUlNKqZ8dmIA:APA91b...",
    "platform": "ios",
    "deviceId": "...",
    "lastUsed": "2024-12-18T09:45:00.000Z"
  }]
}
```

#### Test 2: Send Test Notification

Use the existing test endpoint:

```bash
curl -X POST https://api.banatalk.com/api/v1/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "69423c0cb696bd1f501fe3e1",
    "type": "chat_message"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Test notification sent",
  "successCount": 1,
  "failureCount": 0
}
```

**Expected on Device:**
Push notification should appear!

#### Test 3: Send Real Message

1. **Close the app** on the recipient's device
2. **Send a message** from another user
3. **Check logs:**

```
📱 Recipient 69423c0cb696bd1f501fe3e1 is offline, sending push notification...
✅ Push notification sent successfully
```

4. **Verify:** Push notification appears on device

---

## 🔍 Debugging

### Check 1: Firebase Admin SDK Initialized?

```javascript
// In your server.js or app.js
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('✅ Firebase Admin SDK initialized');
```

### Check 2: Are Messages Being Sent?

Add logging to your socket handler:

```javascript
socket.on('message', async (data) => {
  console.log('📨 Received message:', {
    from: socket.userId,
    to: data.receiverId,
    message: data.message
  });
  
  const recipientSocketId = onlineUsers.get(data.receiverId);
  console.log('🔍 Recipient online?', !!recipientSocketId);
  
  if (!recipientSocketId) {
    console.log('📱 Sending push notification...');
    // ... notification code
  }
});
```

### Check 3: FCM Token Valid?

Test manually:

```javascript
const admin = require('firebase-admin');

const testToken = async (token) => {
  try {
    const response = await admin.messaging().send({
      notification: {
        title: 'Test',
        body: 'Testing FCM token'
      },
      token: token
    });
    console.log('✅ Token is valid:', response);
  } catch (error) {
    console.error('❌ Token is invalid:', error);
  }
};

// Test with the user's token
testToken('eXwacvP6CUwUlNKqZ8dmIA:APA91b...');
```

---

## 📊 Expected Flow

### When App is CLOSED/BACKGROUND:

```
1. User A sends message
   ↓
2. Backend receives via socket
   ↓
3. Backend checks: Is User B online?
   ↓
4. User B is OFFLINE
   ↓
5. Backend sends FCM notification
   ↓
6. User B's phone receives notification
   ↓
7. User B taps notification
   ↓
8. App opens to that chat
```

### When App is OPEN:

```
1. User A sends message
   ↓
2. Backend receives via socket
   ↓
3. Backend checks: Is User B online?
   ↓
4. User B is ONLINE
   ↓
5. Backend sends via socket only (no push notification)
   ↓
6. User B sees message instantly in app
```

---

## ✅ Checklist

- [ ] FCM tokens are stored in user documents
- [ ] Socket handler checks if recipient is online
- [ ] Socket handler sends push notification if offline
- [ ] Notification service is properly configured
- [ ] Firebase Admin SDK is initialized
- [ ] Test endpoint works
- [ ] Real messages trigger notifications
- [ ] Notifications appear on closed/background app
- [ ] Tapping notification opens correct chat
- [ ] Invalid tokens are removed from database

---

## 🎯 Priority Tasks

1. **Immediate:** Add push notification sending to socket message handler
2. **Immediate:** Test with real messages
3. **Soon:** Add notifications for moments, friend requests, etc.
4. **Later:** Add notification scheduling, quiet hours, etc.

---

## 📞 Support

If you encounter issues:

1. **Check backend logs** - Are notifications being sent?
2. **Check FCM token** - Is it stored in database?
3. **Test notification endpoint** - Does it work?
4. **Check Firebase Console** - Any errors in Cloud Messaging?

Frontend is ready and waiting! Just need to send those notifications from the backend. 🚀

---

**Last Updated:** December 18, 2024  
**Frontend Status:** ✅ Complete  
**Backend Status:** ⏳ Waiting for push notification implementation

