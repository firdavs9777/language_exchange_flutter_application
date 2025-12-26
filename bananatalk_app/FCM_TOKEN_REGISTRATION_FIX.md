# FCM Token Registration Fix ✅

## 🔍 Problem Identified

Backend developer found that **FCM tokens were not being stored in the database**. 

The frontend was generating tokens successfully:
```
🔑 FCM Token: eXwacvP6CUwUlNKqZ8dmIA:APA91b...
```

But they weren't being registered with the backend API.

## 🐛 Root Cause

The `registerToken()` method had timing issues:

1. **Parameter not used**: The userId parameter was passed but not used
2. **Timing issue**: FCM token might not be ready when `registerToken()` is called after login
3. **No retry**: If token wasn't ready, registration would silently fail

### Before (Broken):
```dart
Future<void> registerToken(String userId) async {
  debugPrint('🔑 Registering token for user: $userId');
  await _registerTokenWithBackend(); // userId not passed!
}

Future<void> _registerTokenWithBackend() async {
  // Always reads from SharedPreferences
  final userId = prefs.getString('userId');
  // ... might not be set yet
}
```

## ✅ Solution

Updated the token registration logic to:

1. **Accept userId parameter**: Pass userId directly to avoid timing issues
2. **Wait for token**: Add a 1-second wait if FCM token isn't ready yet
3. **Better logging**: Add detailed logs to track registration
4. **Fallback**: Can still read from SharedPreferences if needed

### After (Fixed):
```dart
Future<void> registerToken(String userId) async {
  debugPrint('🔑 Registering token for user: $userId');
  
  // Wait for FCM token if not ready
  if (_fcmToken == null) {
    debugPrint('⏳ FCM token not ready yet, waiting...');
    await Future.delayed(const Duration(seconds: 1));
  }
  
  if (_fcmToken == null) {
    debugPrint('❌ FCM token still not available after waiting');
    return;
  }
  
  await _registerTokenWithBackend(userId); // Pass userId!
}

Future<void> _registerTokenWithBackend([String? userId]) async {
  // Use provided userId or fallback to SharedPreferences
  String? userIdToUse = userId ?? prefs.getString('userId');
  
  // ... register with backend
}
```

## 📋 What to Look For in Logs

### After Login, You Should See:

```
🔑 Registering token for user: 69423c0cb696bd1f501fe3e1
📤 Registering token with backend for user: 69423c0cb696bd1f501fe3e1
📤 FCM Token: eXwacvP6CUwUlNKqZ8dmIA:APA91bGjMJp9wTWRAP0KOMrak...
📤 Device ID: iPhone_xxxxx
📤 Platform: ios
✅ Token registered with backend successfully!
```

### If Token Not Ready:

```
🔑 Registering token for user: 69423c0cb696bd1f501fe3e1
⏳ FCM token not ready yet, waiting...
📤 Registering token with backend for user: 69423c0cb696bd1f501fe3e1
✅ Token registered with backend successfully!
```

## 🧪 Testing Steps

### 1. Login Fresh

1. **Delete and reinstall** the app (or clear data)
2. **Login** with your account
3. **Check logs** for registration messages
4. **Verify in backend**: Check MongoDB for FCM token

```javascript
// MongoDB query
db.users.findOne(
  { _id: ObjectId("69423c0cb696bd1f501fe3e1") },
  { fcmTokens: 1 }
)

// Expected:
{
  "fcmTokens": [{
    "token": "eXwacvP6CUwUlNKqZ8dmIA:APA91b...",
    "platform": "ios",
    "deviceId": "iPhone_xxxxx",
    "createdAt": "2024-12-18T10:00:00.000Z"
  }]
}
```

### 2. Test Push Notification

1. **Close the app completely**
2. **Have someone send you a message**
3. **Push notification should appear** 📱
4. **Tap it** → Should open to that chat

## 📊 Registration Flow

```
App Launch
  ↓
Firebase.initializeApp()
  ↓
NotificationService.initialize()
  ↓
Get APNS token (iOS)
  ↓
Get FCM token
  ↓
Save token locally
  ↓
User logs in
  ↓
AuthService calls NotificationService.registerToken(userId)
  ↓
Check if FCM token is ready
  ↓
Wait if needed (1 second)
  ↓
Call backend API: POST /api/v1/notifications/register-token
  ↓
Backend saves token to MongoDB
  ↓
✅ Token registered!
```

## 🔄 Token Refresh

When FCM token changes (rare, but happens):

```
FCM Token Refreshed
  ↓
onTokenRefresh listener fires
  ↓
Update local _fcmToken
  ↓
Call _registerTokenWithBackend()
  ↓
Read userId from SharedPreferences
  ↓
Register new token with backend
  ↓
✅ Updated!
```

## ✅ Files Modified

- `lib/services/notification_service.dart`
  - Updated `_registerTokenWithBackend()` to accept userId parameter
  - Updated `registerToken()` to wait for FCM token
  - Added better logging

## 🎯 Expected Results

After this fix:

1. ✅ FCM token registered immediately after login
2. ✅ Token visible in MongoDB user document
3. ✅ Backend can send push notifications
4. ✅ Notifications appear when app is closed/background
5. ✅ Tapping notification opens correct screen

## 🐛 Troubleshooting

### If token still not registering:

**Check 1: Is FCM token being generated?**
```
Look for: 🔑 FCM Token: eXw...
```

**Check 2: Is registerToken being called?**
```
Look for: 🔑 Registering token for user: ...
```

**Check 3: Is API call succeeding?**
```
Look for: ✅ Token registered with backend successfully!
```

**Check 4: Backend API working?**
```bash
# Test manually
curl -X POST https://api.banatalk.com/api/v1/notifications/register-token \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "test_fcm_token",
    "platform": "ios",
    "deviceId": "test_device"
  }'
```

### Common Issues:

| Issue | Solution |
|-------|----------|
| "No FCM token available" | Wait for APNS token on iOS |
| "No userId available" | Make sure login completed |
| "Failed to register token" | Check backend API/logs |
| "Token not in database" | Check backend save logic |

## 📞 Next Steps

1. **Run the updated app** on your physical device
2. **Watch the logs** for token registration
3. **Verify in MongoDB** that token is saved
4. **Test push notifications** by closing app and receiving message

---

**Status:** ✅ **Fixed**  
**Impact:** High - Enables push notifications  
**Test Required:** Yes - Verify token in database

*Fixed: December 18, 2024*

 