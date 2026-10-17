import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recovers a photo taken with the camera after Android killed the app.
///
/// Opening the camera puts the app in the background, and on low-memory
/// devices Android's low-memory killer reclaims it there (seen 2026-10-17 on a
/// Galaxy Tab S7 FE: "lmkd: Reclaim 'com.bananatalk.app' ... Process has
/// died"). Android then starts the app fresh to deliver the photo, so the
/// screen that asked for it and the photo were both lost. image_picker keeps
/// the result for [ImagePicker.retrieveLostData]; this remembers which screen
/// asked, so the shell can reopen it with the photo.
class CameraRecovery {
  CameraRecovery._();

  static const String prefsKey = 'camera_pending_target';
  static const String extraPrefsKey = 'camera_pending_extra';

  /// Target ids the shell knows how to reopen.
  static const String imageVocab = 'image_vocab';
  static const String moment = 'moment';
  static const String story = 'story';

  /// A chat; [extra] carries `userId`, `userName`, `profilePicture`.
  static const String chat = 'chat';

  /// Call just before opening the camera. [extra] is what the shell needs to
  /// reopen the screen (e.g. which chat).
  static Future<void> markPending(String target,
      {Map<String, String>? extra}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, target);
      if (extra == null) {
        await prefs.remove(extraPrefsKey);
      } else {
        await prefs.setString(extraPrefsKey, jsonEncode(extra));
      }
    } catch (_) {}
  }

  /// Call when the camera returned normally (photo or cancel).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKey);
      await prefs.remove(extraPrefsKey);
    } catch (_) {}
  }

  /// The photo a killed app never received, and the screen that asked for
  /// it; null when nothing is pending. Clears the pending mark either way.
  static Future<({String target, XFile file, Map<String, String> extra})?>
      takeLost({
    ImagePicker? picker,
    @visibleForTesting bool? isAndroid,
  }) async {
    if (!(isAndroid ?? Platform.isAndroid)) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final target = prefs.getString(prefsKey);
      if (target == null) return null;
      final extraJson = prefs.getString(extraPrefsKey);
      await prefs.remove(prefsKey);
      await prefs.remove(extraPrefsKey);
      final extra = <String, String>{};
      if (extraJson != null) {
        final decoded = jsonDecode(extraJson);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v is String) extra['$k'] = v;
          });
        }
      }
      final lost = await (picker ?? ImagePicker()).retrieveLostData();
      final file = lost.file ?? (lost.files?.isNotEmpty == true ? lost.files!.first : null);
      if (lost.isEmpty || file == null) return null;
      return (target: target, file: file, extra: extra);
    } catch (_) {
      return null;
    }
  }
}
