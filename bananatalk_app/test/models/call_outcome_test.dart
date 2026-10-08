import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/models/call_record_model.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  String label(CallOutcome o, {required bool caller, bool video = false, int duration = 0}) =>
      CallLabels.label(l10n,
          outcome: o, viewerIsCaller: caller, isVideo: video, duration: duration, otherName: 'Ada');

  test('§3 labels, caller and receiver side', () {
    expect(label(CallOutcome.completed, caller: true, duration: 83), 'Outgoing voice call · 1:23');
    expect(label(CallOutcome.completed, caller: false, video: true, duration: 5), 'Incoming video call · 0:05');
    expect(label(CallOutcome.noAnswer, caller: true), 'Voice call · No answer');
    expect(label(CallOutcome.noAnswer, caller: false), 'Missed voice call');
    expect(label(CallOutcome.cancelled, caller: true), 'Cancelled voice call');
    expect(label(CallOutcome.cancelled, caller: false, video: true), 'Missed video call');
    expect(label(CallOutcome.declined, caller: true), 'Voice call declined');
    expect(label(CallOutcome.declined, caller: false), 'Declined voice call');
    expect(label(CallOutcome.busy, caller: true), 'Ada was on another call');
    expect(label(CallOutcome.busy, caller: false), 'Missed voice call');
  });

  test('missed (badge, red) only on the receiver side of no_answer / cancelled / busy', () {
    for (final o in [CallOutcome.noAnswer, CallOutcome.cancelled, CallOutcome.busy]) {
      expect(CallLabels.isMissedForViewer(o, viewerIsCaller: false), isTrue);
      expect(CallLabels.isMissedForViewer(o, viewerIsCaller: true), isFalse);
    }
    expect(CallLabels.isMissedForViewer(CallOutcome.declined, viewerIsCaller: false), isFalse);
    expect(CallLabels.isMissedForViewer(CallOutcome.completed, viewerIsCaller: false), isFalse);
  });

  test('formatCallDuration', () {
    expect(formatCallDuration(0), '0:00');
    expect(formatCallDuration(61), '1:01');
    expect(formatCallDuration(3725), '1:02:05');
  });

  test('CallRecord reads the server superset; legacy rows fall back to status', () {
    final r = CallRecord.fromJson({
      '_id': 'c1', 'callId': 'c1', 'callUuid': 'u-1', 'initiator': 'me', 'participants': [],
      'type': 'video', 'startTime': '2026-10-08T12:00:00.000Z', 'duration': 61,
      'status': 'missed', 'outcome': 'busy',
    }, 'me');
    expect(r.outcome, CallOutcome.busy);
    expect(r.callUuid, 'u-1');
    expect(r.direction, CallDirection.outgoing);
    expect(r.duration, 61);
    final legacy = CallRecord.fromJson({'_id': 'c2', 'initiator': 'x', 'type': 'audio', 'status': 'missed'}, 'me');
    expect(legacy.outcome, CallOutcome.noAnswer);
    final fractional = CallRecord.fromJson({'_id': 'c3', 'initiator': 'x', 'duration': 12.7, 'status': 'ended'}, 'me');
    expect(fractional.duration, 12);
  });

  test('callPreviewText uses the viewer perspective', () {
    final data = {'initiator': 'me', 'type': 'audio', 'status': 'missed', 'outcome': 'no_answer', 'duration': 0};
    expect(callPreviewText(l10n, data, viewerId: 'me', otherName: 'Ada'), '📞 Voice call · No answer');
    expect(callPreviewText(l10n, data, viewerId: 'other', otherName: 'Ada'), '📞 Missed voice call');
  });

  test('CallLogEntry parses GET /calls items', () {
    final e = CallLogEntry.fromJson({
      'id': 'c1', 'callUuid': 'u', 'type': 'video', 'direction': 'in', 'outcome': 'cancelled', 'duration': 0,
      'otherParty': {'id': 'u2', 'name': 'Ada', 'avatar': 'https://cdn.test/a.jpg'},
      'createdAt': '2026-10-08T12:00:00.000Z',
    });
    expect(e.direction, CallDirection.incoming);
    expect(e.outcome, CallOutcome.cancelled);
    expect(e.type, CallType.video);
    expect(e.otherName, 'Ada');
    expect(e.otherAvatar, 'https://cdn.test/a.jpg');
  });
}
