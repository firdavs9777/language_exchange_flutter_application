# Push Notifications - Quick Start Guide

## ✅ What's Been Done

All code has been implemented! The push notifications system is ready to use once Firebase is configured.

## 🔥 Firebase Setup (Required - 15 minutes)

Before notifications will work, you need to complete Firebase setup:

### 1. Android Setup (5 minutes)

```bash
# Steps:
# 1. Go to https://console.firebase.google.com
# 2. Open/create "bananatalk-backend" project
# 3. Add Android app with package: com.bananatalk.app
# 4. Download google-services.json
# 5. Place it in: android/app/google-services.json
```

### 2. iOS Setup (10 minutes)

```bash
# Steps:
# 1. In Firebase Console, add iOS app
# 2. Download GoogleService-Info.plist
# 3. Place in: ios/Runner/GoogleService-Info.plist
# 4. Open ios/Runner.xcworkspace in Xcode
# 5. Add GoogleService-Info.plist to Runner target
# 6. Enable "Push Notifications" capability
# 7. Create APNs certificate/key and upload to Firebase
```

**See `FIREBASE_SETUP_INSTRUCTIONS.md` for detailed steps**

## 🚀 Build & Run

Once Firebase is configured:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run on Android
flutter run

# Run on iOS (requires physical device)
flutter run

# Build release
flutter build appbundle --release  # Android
flutter build ipa --release         # iOS
```

## 🧪 Testing Notifications

### Option 1: Using the Debug Screen

1. Login to the app
2. Go to: **Profile → [Debug icon]** (if added to profile drawer)
3. Or navigate directly to `NotificationDebugScreen`
4. Tap buttons to send test notifications

### Option 2: Using Backend API

```bash
# Send test notification via API
curl -X POST YOUR_BACKEND_URL/api/v1/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "chat_message"}'
```

### Option 3: Using Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Copy FCM token from app logs
4. Send test notification

## 📱 Where to Find Notification Settings

1. Open BanaTalk app
2. Go to **Profile** tab
3. Tap hamburger menu (☰)
4. Select **"Notifications"**

## 🔔 Features You Can Test

- ✅ Enable/disable notifications globally
- ✅ Toggle individual notification types
- ✅ View notification history
- ✅ See badge counts on tabs
- ✅ Tap notifications to navigate
- ✅ Mute specific conversations
- ✅ Test all notification types

## 📊 Monitoring

Check logs for:

```
✅ Firebase initialized successfully
✅ Notification service initialized
🔑 FCM Token: [your_token]
📤 Registering FCM token for device: [device_id]
✅ FCM token registered successfully
```

## 🐛 Common Issues

### "No FCM token"
- Check Firebase setup is complete
- Verify google-services.json / GoogleService-Info.plist are in place
- Run `flutter clean && flutter pub get`

### "Notifications not received (iOS)"
- iOS notifications only work on **physical devices** (not simulator)
- Check APNs certificate is uploaded to Firebase
- Verify Push Notifications capability is enabled

### "Token registration failed"
- Check user is logged in
- Verify backend is running and accessible
- Check `/api/v1/notifications/register-token` endpoint works

## 📁 Important Files

### Configuration
- `android/app/google-services.json` - Android Firebase config (NOT YET ADDED)
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config (NOT YET ADDED)

### Code Files (All Implemented ✅)
- `lib/services/notification_service.dart` - Core FCM service
- `lib/services/notification_router.dart` - Deep linking
- `lib/pages/notifications/` - UI screens
- `lib/providers/notification_*_provider.dart` - State management

### Documentation
- `FIREBASE_SETUP_INSTRUCTIONS.md` - Detailed Firebase setup
- `PUSH_NOTIFICATIONS_IMPLEMENTATION_SUMMARY.md` - Complete implementation details
- `NOTIFICATIONS_QUICK_START.md` - This file

## 🎯 Next Steps

1. **Complete Firebase Setup** (15 min) - See `FIREBASE_SETUP_INSTRUCTIONS.md`
2. **Build & Run** the app
3. **Login** with a test account
4. **Test** notifications using one of the methods above
5. **Verify** all features work on both Android and iOS

## 💡 Tips

- Test on physical devices (especially iOS)
- Check both foreground and background notifications
- Try all notification types (chat, moments, friend requests, etc.)
- Verify deep linking works (taps navigate correctly)
- Test muting conversations
- Check badge counts update correctly

## 📞 Support

If you encounter issues:
1. Check logs for error messages
2. Review `FIREBASE_SETUP_INSTRUCTIONS.md` troubleshooting section
3. Verify all configuration files are in place
4. Make sure backend is running

---

**Status:** ✅ Code Complete | ⏳ Firebase Setup Required

Once Firebase is configured, everything will work! 🎉

