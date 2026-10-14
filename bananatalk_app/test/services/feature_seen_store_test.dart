import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';

void main() {
  test('reads empty, then marks and reads back', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await FeatureSeenStore.readSeen(), isEmpty);
    await FeatureSeenStore.markSeen('tutor');
    expect(await FeatureSeenStore.readSeen(), {'tutor'});
  });

  test('wrong-typed value reads as unseen, never throws', () async {
    SharedPreferences.setMockInitialValues({'study_feature_seen_tutor': 'yes'});
    expect(await FeatureSeenStore.readSeen(), isEmpty);
  });

  test('keys are user-scoped (cleared on logout)', () {
    // session_prefs keeps only an allow-list of device-level keys.
    expect(FeatureSeenStore.keyFor('tutor'), 'study_feature_seen_tutor');
  });

  test('unreadable storage -> everything seen (no NEW badges)', () async {
    final seen = await FeatureSeenStore.readSeen(prefs: () async => throw Exception('io'));
    expect(seen.length, 12);
  });
}
