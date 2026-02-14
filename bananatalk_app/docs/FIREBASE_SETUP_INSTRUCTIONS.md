# Firebase Setup Instructions for BanaTalk Push Notifications

## Overview
This guide will help you complete the Firebase setup for push notifications in the BanaTalk Flutter app.

## Prerequisites
- Firebase account
- Access to [Firebase Console](https://console.firebase.google.com)
- Xcode (for iOS)
- Android Studio (for Android)

## Step 1: Create/Access Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Either:
   - Create a new project named "bananatalk-backend"
   - OR use the existing "bananatalk-backend" project (if already created for backend)
3. Enable **Cloud Messaging** in the Firebase Console

## Step 2: Android Setup

### 2.1 Add Android App to Firebase

1. In Firebase Console, click "Add app" → Select Android
2. Enter the package name: `com.bananatalk.app`
   - You can verify this in `android/app/build.gradle` under `namespace` or `applicationId`
3. Enter app nickname (optional): "BanaTalk Android"
4. Skip adding SHA-1 for now (only needed for Google Sign-In)
5. Click "Register app"

### 2.2 Download Configuration File

1. Download the `google-services.json` file
2. Place it in: `android/app/google-services.json`
   ```
   /Users/firdavsmutalipov/Desktop/BananaTalk/bananatalk_app/android/app/google-services.json
   ```

### 2.3 Verify Gradle Configuration

The following have already been configured in the code:

- ✅ `android/build.gradle` - Google services classpath added
- ✅ `android/app/build.gradle` - Google services plugin applied
- ✅ `android/app/src/main/res/values/strings.xml` - Notification channel configured
- ✅ `android/app/src/main/AndroidManifest.xml` - FCM metadata added

## Step 3: iOS Setup

### 3.1 Add iOS App to Firebase

1. In Firebase Console, click "Add app" → Select iOS
2. Enter the iOS bundle ID
   - Find it in: `ios/Runner/Info.plist` under `CFBundleIdentifier`
   - Or in Xcode: Runner target → General → Bundle Identifier
3. Enter app nickname (optional): "BanaTalk iOS"
4. Click "Register app"

### 3.2 Download Configuration File

1. Download the `GoogleService-Info.plist` file
2. Place it in: `ios/Runner/GoogleService-Info.plist`
   ```
   /Users/firdavsmutalipov/Desktop/BananaTalk/bananatalk_app/ios/Runner/GoogleService-Info.plist
   ```

### 3.3 Add to Xcode Project

1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Right-click on "Runner" in the left panel
3. Select "Add Files to Runner..."
4. Navigate to and select `GoogleService-Info.plist`
5. **IMPORTANT**: Make sure "Copy items if needed" is checked
6. Make sure "Runner" target is checked
7. Click "Add"

### 3.4 Enable Push Notifications Capability

1. In Xcode, select "Runner" project in the left panel
2. Select "Runner" target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Search for and add "Push Notifications"
6. Also add "Background Modes" capability
7. Under Background Modes, check:
   - Remote notifications

### 3.5 Create APNs Certificate (Important!)

You need an APNs (Apple Push Notification service) certificate for iOS notifications to work:

#### Option A: APNs Authentication Key (Recommended - Easier)

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Click "+" to create a new key
3. Name it "BanaTalk APNs Key"
4. Check "Apple Push Notifications service (APNs)"
5. Click "Continue" → "Register"
6. Download the `.p8` key file (you can only download this once!)
7. Note the Key ID

**Upload to Firebase:**
1. In Firebase Console → Project Settings → Cloud Messaging
2. Scroll to "Apple app configuration"
3. Click "Upload" under "APNs Authentication Key"
4. Upload the `.p8` file
5. Enter your Key ID
6. Enter your Team ID (find it in [Apple Developer Portal](https://developer.apple.com/account/#/membership))
7. Click "Upload"

#### Option B: APNs Certificate (Traditional)

1. Follow [this guide](https://firebase.google.com/docs/cloud-messaging/ios/certs) to create an APNs certificate
2. Upload it to Firebase Console → Project Settings → Cloud Messaging

## Step 4: Verify Setup

### Android Verification

1. Run `flutter clean`
2. Run `flutter pub get`
3. Build the app: `flutter run` (on Android device/emulator)
4. Check logs for:
   ```
   ✅ Firebase initialized successfully
   ✅ Notification service initialized
   🔑 FCM Token: [token_string]
   ```

### iOS Verification

1. Run `flutter clean`
2. Run `flutter pub get`
3. Build the app: `flutter run` (on iOS device - simulator won't receive push notifications)
4. **IMPORTANT**: iOS push notifications only work on physical devices, not simulators
5. Check logs for:
   ```
   ✅ Firebase initialized successfully
   ✅ Notification service initialized
   🔑 FCM Token: [token_string]
   ```

## Step 5: Test Notifications

### Method 1: Using Debug Screen (Recommended)

1. Open the app
2. Go to Profile → Notifications → Settings
3. Look for "Debug" or "Test" menu (if added)
4. Tap "Send Test Notification"
5. Check if notification appears

### Method 2: Using Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Click "Send test message"
5. Enter the FCM token from your device logs
6. Click "Test"

### Method 3: Using Backend API

```bash
# Register token first (automatically done on login)
# Then send a test notification
curl -X POST http://your-backend-url/api/v1/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "system"}'
```

## Troubleshooting

### Android Issues

**Problem:** "google-services.json not found"
- **Solution:** Make sure the file is in `android/app/` directory
- Run `flutter clean` and rebuild

**Problem:** No FCM token received
- **Solution:** Check Google Services are properly configured in `build.gradle` files
- Make sure you have internet connection
- Check Firebase project has Cloud Messaging enabled

### iOS Issues

**Problem:** "GoogleService-Info.plist not found"
- **Solution:** Make sure the file is added to Xcode project (not just placed in folder)
- Check it's included in "Copy Bundle Resources" build phase

**Problem:** No push notifications on simulator
- **Solution:** iOS simulators don't support push notifications - test on a physical device

**Problem:** "APNs device token not set"
- **Solution:** 
  - Make sure Push Notifications capability is enabled in Xcode
  - Upload APNs certificate/key to Firebase Console
  - Test on a physical device (not simulator)

**Problem:** Notifications work in development but not in production
- **Solution:**
  - Make sure you have both Development and Production APNs certificates
  - Verify Firebase has the correct certificate for the build type

### General Issues

**Problem:** App crashes on startup
- **Solution:**
  - Check `google-services.json` and `GoogleService-Info.plist` are valid
  - Run `flutter clean`
  - Rebuild the app

**Problem:** Token registration fails
- **Solution:**
  - Make sure user is logged in before registering token
  - Check backend API is accessible
  - Verify `/api/v1/notifications/register-token` endpoint is working

## Next Steps

After completing the Firebase setup:

1. ✅ Test notifications on both Android and iOS
2. ✅ Verify token registration with backend
3. ✅ Test notification settings screen
4. ✅ Test notification history
5. ✅ Test badge counts
6. ✅ Test deep linking (tapping notifications navigates to correct screen)

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Setup](https://firebase.flutter.dev/docs/overview)
- [iOS Push Notifications Guide](https://developer.apple.com/documentation/usernotifications)
- [Android Notification Channels](https://developer.android.com/training/notify-user/channels)

## Support

If you encounter issues:

1. Check the logs for error messages
2. Verify all configuration files are in place
3. Make sure Firebase project is properly set up
4. Check backend API is running and accessible
5. Review the troubleshooting section above

For backend-related issues, refer to `PUSH_NOTIFICATIONS_BACKEND_GUIDE.md` (in the backend repository).

