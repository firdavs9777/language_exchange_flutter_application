import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Snapshot of the running client's platform, OS, and app build — sent to
/// the backend with /auth/register and /auth/updatedetails so we can attribute
/// signups to iOS / Android / Web without UA sniffing (Dart's default
/// `User-Agent: Dart/3.x (dart:io)` matches none of the backend regex tokens).
///
/// Backend `signupPlatform` enum is ['ios','android','web','unknown']; we
/// collapse desktop platforms to 'unknown' since they have no enum slot.
class ClientInfo {
  static Map<String, String>? _cached;

  static Future<Map<String, String>> collect() async {
    if (_cached != null) return _cached!;

    final platform = _platform();
    String deviceModel = '';
    String osVersion = '';

    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        deviceModel = web.browserName.name;
        osVersion = web.platform ?? '';
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        deviceModel = ios.utsname.machine; // e.g. "iPhone16,1"
        osVersion = '${ios.systemName} ${ios.systemVersion}';
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        deviceModel = '${android.manufacturer} ${android.model}';
        osVersion = 'Android ${android.version.release} (SDK ${android.version.sdkInt})';
      }
    } catch (_) {
      // Device info is best-effort; never block signup on it.
    }

    String appVersion = '';
    String appBuild = '';
    try {
      final pkg = await PackageInfo.fromPlatform();
      appVersion = pkg.version;
      appBuild = pkg.buildNumber;
    } catch (_) {}

    _cached = {
      'platform': platform,
      if (deviceModel.isNotEmpty) 'deviceModel': deviceModel,
      if (osVersion.isNotEmpty) 'osVersion': osVersion,
      if (appVersion.isNotEmpty) 'appVersion': appVersion,
      if (appBuild.isNotEmpty) 'appBuild': appBuild,
    };
    return _cached!;
  }

  static String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}
