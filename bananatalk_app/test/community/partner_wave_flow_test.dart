import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Partners tab used to wave through `interactions/wave` and post a real
/// '👋' chat message on every wave, bypassing the Waves inbox, the wave cap
/// and the one-wave rule that every other surface gets from
/// `showSendWaveSheet` -> `community/wave`.
void main() {
  final src = File(
    'lib/pages/community/tabs/partner_discovery_tab.dart',
  ).readAsStringSync();

  test('Partners tab waves through the shared send-wave sheet', () {
    expect(src, contains('showSendWaveSheet('));
  });

  test('Partners tab no longer uses the legacy wave or sends a chat 👋', () {
    expect(src, isNot(contains('InteractionService.waveUser')));
    expect(src, isNot(contains("message: '👋'")));
  });
}
