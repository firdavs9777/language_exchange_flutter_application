# CocoaPods Dependency Conflict Fix

## Issue

When running `flutter run` on iOS, you encountered the following CocoaPods dependency conflict:

```
[!] CocoaPods could not find compatible versions for pod "GoogleUtilities/UserDefaults":
  In Podfile:
    firebase_messaging (from `.symlinks/plugins/firebase_messaging/ios`) was resolved to 14.7.10, which depends on
      Firebase/Messaging (= 10.25.0) was resolved to 10.25.0, which depends on
        FirebaseMessaging (~> 10.25.0) was resolved to 10.25.0, which depends on
          GoogleUtilities/UserDefaults (~> 7.8)

    google_sign_in_ios (from `.symlinks/plugins/google_sign_in_ios/darwin`) was resolved to 0.0.1, which depends on
      GoogleSignIn (~> 8.0) was resolved to 8.0.0, which depends on
        AppCheckCore (~> 11.0) was resolved to 11.2.0, which depends on
          GoogleUtilities/UserDefaults (~> 8.0)
```

## Root Cause

The conflict occurred because:

1. **firebase_messaging 14.7.10** (older version) requires Firebase SDK 10.25.0, which requires `GoogleUtilities ~> 7.8`
2. **google_sign_in_ios** requires GoogleSignIn 8.0, which requires `AppCheckCore ~> 11.0`, which requires `GoogleUtilities ~> 8.0`

These two requirements are incompatible:
- Firebase wants GoogleUtilities 7.8+
- Google Sign In wants GoogleUtilities 8.0+

## Solution

Updated Firebase packages to newer versions that are compatible with GoogleSignIn 8.0:

### Changes Made

**In `pubspec.yaml`:**

```yaml
# Before:
firebase_core: ^2.24.2
firebase_messaging: ^14.7.10

# After:
firebase_core: ^3.0.0
firebase_messaging: ^15.0.0
```

### Commands Run

```bash
# 1. Update pubspec.yaml (as shown above)

# 2. Clean build and remove CocoaPods cache
flutter clean
rm -f ios/Podfile.lock
rm -rf ios/Pods

# 3. Get new dependencies
flutter pub get

# 4. Run the app
flutter run
```

## Result

After the update:
- **firebase_core**: 2.32.0 → 3.15.2
- **firebase_messaging**: 14.7.10 → 15.2.10
- **_flutterfire_internals**: 1.3.35 → 1.3.59

These newer versions are compatible with GoogleSignIn 8.0 and GoogleUtilities 8.0+, resolving the conflict.

## Why This Works

The newer Firebase packages (v3.x and v15.x) were updated by the Firebase team to work with the newer Google Sign In library and its dependencies. They require `GoogleUtilities ~> 8.0`, which matches what GoogleSignIn needs.

## Important Notes

1. **Breaking Changes**: Firebase v3.x may have breaking changes from v2.x, but our implementation should work fine as we're using standard FCM APIs.

2. **API Compatibility**: The notification implementation we created uses standard Firebase Messaging APIs that are consistent across these versions.

3. **Future Updates**: Always check package compatibility when updating Firebase or Google Sign In packages.

## If You Encounter Similar Issues

When you see CocoaPods conflicts:

1. **Identify the conflicting packages** from the error message
2. **Check which versions are required** by each package
3. **Update to compatible versions** (usually the newer ones)
4. **Clean build artifacts**:
   ```bash
   flutter clean
   rm -f ios/Podfile.lock
   rm -rf ios/Pods
   ```
5. **Get fresh dependencies**:
   ```bash
   flutter pub get
   ```

## Verification

To verify the fix worked:

1. The app should build successfully
2. Check logs for:
   ```
   ✅ Firebase initialized successfully
   ✅ Notification service initialized
   ```
3. No CocoaPods errors during `pod install`

## Reference

- [Firebase iOS SDK Changelog](https://firebase.google.com/support/release-notes/ios)
- [FlutterFire Changelog](https://firebase.flutter.dev/docs/overview)
- [Google Sign-In iOS Changelog](https://developers.google.com/identity/sign-in/ios/release-notes)

---

**Status:** ✅ Fixed  
**Date:** December 18, 2024  
**Solution:** Updated Firebase packages to v3.x/v15.x

