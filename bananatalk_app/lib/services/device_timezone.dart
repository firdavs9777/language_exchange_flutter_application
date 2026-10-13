import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// The device's IANA zone (e.g. "Asia/Tashkent"), or null when the platform
/// cannot say. One source for the top-level timezone report and the quiet
/// hours window. `DateTime.now().timeZoneName` is not used: on some
/// platforms it is an abbreviation ("CST"), not an IANA zone.
Future<String?> deviceTimezone() async {
  try {
    final id = (await FlutterTimezone.getLocalTimezone()).identifier;
    return id.isEmpty ? null : id;
  } catch (e) {
    debugPrint('[timezone] device zone unavailable: $e');
    return null;
  }
}
