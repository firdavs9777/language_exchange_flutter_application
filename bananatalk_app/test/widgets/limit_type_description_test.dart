import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('one limit-type description for the dialog and the feature gate', () {
    expect(limitTypeDescription(l10n, 'messages'), l10n.limitDescMessages);
    expect(limitTypeDescription(l10n, 'Moment'), l10n.limitDescMoments);
    expect(limitTypeDescription(l10n, 'stories'), l10n.limitDescStories);
    expect(limitTypeDescription(l10n, 'comment'), l10n.limitDescComments);
    expect(limitTypeDescription(l10n, 'profileViews'), l10n.limitDescProfileViews);
    expect(limitTypeDescription(l10n, 'wave'), l10n.waveLimitBody);
    expect(limitTypeDescription(l10n, 'unknown'), l10n.limitDescDefault);
  });

  test('feature_gate has no copy of the switch', () {
    final gate = File('lib/utils/feature_gate.dart').readAsStringSync();
    expect(gate, contains('limitTypeDescription(l10n, limitType)'));
    expect(gate, isNot(contains('l10n.limitDescMessages')));
  });
}
