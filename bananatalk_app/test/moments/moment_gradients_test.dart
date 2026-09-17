import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

/// Reads the server's list from source rather than a copy of it.
///
/// The bug this exists for: the app offered thirteen gradients while the
/// model's enum accepted eight. Picking one of the five the server did not
/// know about failed Mongoose validation on save — so it did not lose the
/// colour, it stopped the moment being posted at all. Two hand-maintained
/// lists is what made that possible.
List<String> _serverGradients() {
  final src = File('../backend/lib/momentGradients.js').readAsStringSync();
  final block = RegExp(r'MOMENT_GRADIENTS = Object\.freeze\(\[(.*?)\]\)', dotAll: true)
      .firstMatch(src)!
      .group(1)!;
  return RegExp(r"'(gradient_[a-z_]+)'")
      .allMatches(block)
      .map((m) => m.group(1)!)
      .toList();
}

void main() {
  test('every gradient the app offers, the server accepts', () {
    final server = _serverGradients().toSet();
    final missing = MomentGradients.keys.where((k) => !server.contains(k)).toList();
    expect(
      missing,
      isEmpty,
      reason: 'the server rejects these on save, so picking one breaks posting',
    );
  });

  test('every gradient the server accepts, the app can render', () {
    // The reverse direction matters too: a key stored by an older client must
    // still draw, rather than silently falling back to purple.
    final appKeys = MomentGradients.keys.toSet();
    final orphans = _serverGradients().where((k) => !appKeys.contains(k)).toList();
    expect(orphans, isEmpty, reason: 'these would render as the default gradient');
  });

  test('every preset has exactly two colours', () {
    for (final entry in MomentGradients.presets.entries) {
      expect(entry.value.length, 2, reason: '${entry.key} is not a two-stop gradient');
    }
  });

  test('every colour is fully opaque', () {
    // A stop with a zero alpha renders as a transparent band and reads as a
    // broken gradient.
    for (final entry in MomentGradients.presets.entries) {
      for (final c in entry.value) {
        expect(c >> 24 & 0xFF, 0xFF, reason: '${entry.key} has a translucent stop');
      }
    }
  });

  test('the two stops of a gradient differ', () {
    // Identical stops render as a flat block, which is not what a gradient
    // swatch promises.
    for (final entry in MomentGradients.presets.entries) {
      expect(entry.value[0], isNot(equals(entry.value[1])), reason: entry.key);
    }
  });

  test('the default gradient is one that exists', () {
    expect(MomentGradients.presets.containsKey(MomentGradients.defaultGradient), isTrue);
  });

  test('an unknown key falls back to the default rather than throwing', () {
    expect(
      MomentGradients.getColors('gradient_nonexistent'),
      MomentGradients.presets[MomentGradients.defaultGradient],
    );
  });

  test('keys are stable identifiers, not display names', () {
    // Colour values can be retuned without migrating stored moments only if
    // the key carries no styling information.
    for (final key in MomentGradients.keys) {
      expect(key, matches(RegExp(r'^gradient_[a-z_]+$')), reason: key);
    }
  });
}
