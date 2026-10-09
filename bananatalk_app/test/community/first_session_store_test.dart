import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';

/// Local state, deliberately: it resets on reinstall and does not follow a
/// second device, which `Community.isNewUser` bounds to six days. The
/// alternative spends a network round trip on every cold start for a
/// low-stakes decision.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install reports no message and no views', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await FirstSessionStore.read();
    expect(s.hasMessaged, isFalse);
    expect(s.timesShown, 0);
  });

  test('markMessaged persists', () async {
    SharedPreferences.setMockInitialValues({});
    await FirstSessionStore.markMessaged();
    expect((await FirstSessionStore.read()).hasMessaged, isTrue);
  });

  test('recordShown increments', () async {
    SharedPreferences.setMockInitialValues({});
    await FirstSessionStore.recordShown();
    await FirstSessionStore.recordShown();
    expect((await FirstSessionStore.read()).timesShown, 2);
  });

  test('a non-int counter left by an older build reads as zero', () async {
    SharedPreferences.setMockInitialValues(
        {kPrefTimesShown: 'not-a-number', kPrefHasMessaged: 'yes'});
    final s = await FirstSessionStore.read();
    expect(s.timesShown, 0);
    expect(s.hasMessaged, isFalse);
  });

  test('the unknown state is the safe default: show nothing', () {
    // Storage unreadable must hide the panel, never break Matches.
    expect(FirstSessionState.unknown.hasMessaged, isTrue);
  });
}
