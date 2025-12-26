# Google Sign-In Fix - SHA-1 Fingerprints

## ✅ Code Fix Applied
- Updated `google_login.dart` to use `serverClientId` for Android instead of `clientId`
- This removes the warning and properly configures Google Sign-In for Android

## 📋 SHA-1 Fingerprints

### Debug SHA-1 (for development/testing)
```
62:9D:EE:27:BD:B2:1B:E6:A1:48:6B:F5:D9:4C:36:81:D8:58:30:68
```
**Use this for:** Testing on emulators and debug builds

### Release SHA-1 (for production/Play Store)
```
5D:AE:A2:BB:3D:0F:B5:97:09:B3:3B:20:B9:FD:E5:6A:C0:48:8E:04
```
**Use this for:** Production builds and Play Store releases

## 🔧 Add SHA-1 to Firebase Console

### Steps:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **bananatalk-backend**
3. Click the ⚙️ **Settings** icon → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app: **com.bananatalk.app**
6. Click **Add fingerprint** button
7. Add **BOTH** SHA-1 fingerprints:
   - Debug: `62:9D:EE:27:BD:B2:1B:E6:A1:48:6B:F5:D9:4C:36:81:D8:58:30:68`
   - Release: `5D:AE:A2:BB:3D:0F:B5:97:09:B3:3B:20:B9:FD:E5:6A:C0:48:8E:04`
8. Click **Save**

## ✅ Verify Package Name
- Package name: `com.bananatalk.app`
- This matches your `android/app/build.gradle` (line 48)

## ⏱️ Wait Time
After adding SHA-1 fingerprints:
- **Wait 5-10 minutes** for Google to propagate the changes
- Then test Google Sign-In again

## 🧪 Testing
After adding SHA-1 and waiting:
```bash
flutter clean
flutter run
```

Try Google Sign-In - it should work now!

## 📝 Notes
- Error 12500 = "DEVELOPER_ERROR" - usually means SHA-1 mismatch
- Both debug and release SHA-1s are needed for complete functionality
- iOS doesn't require SHA-1 fingerprints (only Android)

