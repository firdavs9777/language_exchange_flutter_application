import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/wallpaper/premium_wallpapers.dart';
import 'package:bananatalk_app/pages/chat/wallpaper/wallpaper_names.dart';

/// Wallpaper preset names are stored ids (prefs + server theme); only the
/// label shown under each swatch is translated.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));

  // Every preset id the picker offers, read from its source so a new preset
  // without a label fails here.
  final pickerSource = File(
    'lib/pages/chat/wallpaper/wallpaper_picker_screen.dart',
  ).readAsStringSync();
  final freeIds = RegExp(r"'name':\s*'([a-z_]+)'")
      .allMatches(pickerSource)
      .map((m) => m.group(1)!)
      .toSet();
  final allIds = {...freeIds, ...premiumWallpapers.map((w) => w.name)};

  test('the picker offers the 28 free labels and 6 premium presets', () {
    expect(premiumWallpapers, hasLength(6));
    final freeLabels = freeIds.map((id) => wallpaperDisplayName(en, id)).toSet();
    expect(freeLabels, hasLength(28));
  });

  test('every preset id has an English label', () {
    for (final id in allIds) {
      final label = wallpaperDisplayName(en, id);
      expect(label, isNot(id), reason: id);
      expect(label.trim(), isNotEmpty, reason: id);
    }
    expect(wallpaperDisplayName(en, 'deep_sea'), 'Deep Sea');
    expect(wallpaperDisplayName(en, 'gradient_rose'), 'Rose Gold');
    expect(wallpaperDisplayName(en, 'premium_golden_hour'), 'Golden Hour');
  });

  test('labels are translated, ids stay as they are', () {
    for (final id in allIds) {
      expect(
        wallpaperDisplayName(ru, id),
        isNot(wallpaperDisplayName(en, id)),
        reason: id,
      );
    }
    expect(wallpaperDisplayName(ru, 'ocean'), 'Океан');
    expect(wallpaperDisplayName(ru, 'gradient_ocean'), 'Океан');
    expect(wallpaperDisplayName(ru, 'premium_galaxy'), 'Галактика');
    expect(premiumWallpapers.first.name, 'premium_aurora_borealis');
  });

  test('an unknown id (older/newer build) shows as-is rather than blank', () {
    expect(wallpaperDisplayName(en, 'custom'), 'custom');
  });

  test('the picker no longer carries English labels', () {
    expect(pickerSource, isNot(contains("'label':")));
  });
}
