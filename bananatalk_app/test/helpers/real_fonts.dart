import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the Flutter SDK's Roboto into the test engine under the family the
/// Material theme asks for on Android, so text measures like on a device
/// instead of in the square-glyph test font (which makes every glyph one
/// em wide and every label far too long).
///
/// Returns false when the SDK fonts can't be found; callers skip then.
Future<bool> loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return false;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return false;
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    final f = File('${dir.path}/Roboto-$w.ttf');
    if (!f.existsSync()) return false;
    final bytes = f.readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  return true;
}
