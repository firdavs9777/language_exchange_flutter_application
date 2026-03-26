import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for platform detection and feature availability
class PlatformUtils {
  /// Check if running on desktop (macOS, Windows, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Check if running on mobile (iOS, Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Check if running on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Check if running on Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Check if running on Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  // ============ Feature Availability ============

  /// Voice recording is available on mobile and macOS (not Windows)
  static bool get supportsVoiceRecording {
    if (kIsWeb) return false;
    // flutter_sound supports iOS, Android, and macOS
    // But for now, we'll only enable on mobile until we test macOS
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Camera capture is only available on mobile
  static bool get supportsCamera {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Location services work on mobile and macOS (not Windows)
  static bool get supportsLocation {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid || Platform.isMacOS;
  }

  /// In-app purchases only work on mobile
  static bool get supportsInAppPurchases {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Push notifications work everywhere except Linux
  static bool get supportsPushNotifications {
    if (kIsWeb) return false;
    return !Platform.isLinux;
  }

  /// Video compression only works on mobile
  static bool get supportsVideoCompression {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Permission handler only works on mobile
  static bool get supportsPermissionHandler {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Get platform name for display
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
