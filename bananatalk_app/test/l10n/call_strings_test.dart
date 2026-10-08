import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

const _callKeys = [
  'callLabelOutgoing',
  'callLabelIncoming',
  'callLabelNoAnswer',
  'callLabelMissed',
  'callLabelCancelled',
  'callLabelDeclinedOutgoing',
  'callLabelDeclinedIncoming',
  'callLabelBusy',
  'callsTitle',
  'callsEmpty',
  'callCameraPaused',
  'callFullScreenIntentTitle',
  'callFullScreenIntentBody',
  'callForegroundTitle',
  'callForegroundBody',
];

void main() {
  test('every locale defines every Phase 1 call string', () {
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .toList();
    expect(arbs.length, 19);
    for (final file in arbs) {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in _callKeys) {
        final value = map[key];
        expect(value is String && value.trim().isNotEmpty, isTrue,
            reason: '${file.path} is missing $key');
      }
      for (final key in _callKeys.where(
          (k) => k.startsWith('callLabel') && k != 'callLabelBusy')) {
        expect(
          map[key],
          allOf(contains('{type, select,'), contains('video{'),
              contains('other{')),
          reason: '${file.path} $key must select on type',
        );
      }
      expect(map['callLabelBusy'], contains('{name}'), reason: file.path);
    }
  });

  test('generated getters render both branches and the name', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.callLabelMissed('video'), 'Missed video call');
    expect(en.callLabelMissed('audio'), 'Missed voice call');
    expect(en.callLabelNoAnswer('audio'), 'Voice call · No answer');
    expect(en.callLabelBusy('Ada'), 'Ada was on another call');
    final ko = lookupAppLocalizations(const Locale('ko'));
    expect(ko.callLabelMissed('audio'), '부재중 음성 통화');
    // The voice branch says "voice" like every other Thai call label.
    final th = lookupAppLocalizations(const Locale('th'));
    expect(th.callLabelMissed('audio'), 'การโทรด้วยเสียงที่ไม่ได้รับ');
  });
}
