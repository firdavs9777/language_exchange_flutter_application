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

  /// Target ids the shell knows how to reopen.
  static const String imageVocab = 'image_vocab';

  /// Call just before opening the camera.
  static Future<void> markPending(String target) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, target);
    } catch (_) {}
  }

  /// Call when the camera returned normally (photo or cancel).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKey);
    } catch (_) {}
  }

  /// The photo a killed app never received, and the screen that asked for
  /// it; null when nothing is pending. Clears the pending mark either way.
  static Future<({String target, XFile file})?> takeLost({
    ImagePicker? picker,
    @visibleForTesting bool? isAndroid,
  }) async {
    if (!(isAndroid ?? Platform.isAndroid)) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final target = prefs.getString(prefsKey);
      if (target == null) return null;
      await prefs.remove(prefsKey);
      final lost = await (picker ?? ImagePicker()).retrieveLostData();
      final file = lost.file ?? (lost.files?.isNotEmpty == true ? lost.files!.first : null);
      if (lost.isEmpty || file == null) return null;
      return (target: target, file: file);
    } catch (_) {
      return null;
    }
  }
}
