import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';

/// Review Focus 5. The conversion event counts a message SENT, not a Say hi
/// TAPPED, and it must fire once: the flag is the guard, so a chatty user
/// does not report first_message_sent forever.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the first send marks the flag; later sends are no longer first',
      () async {
    SharedPreferences.setMockInitialValues({});

    expect((await FirstSessionStore.read()).hasMessaged, isFalse,
        reason: 'before any send this is the first');

    await FirstSessionStore.markMessaged();

    expect((await FirstSessionStore.read()).hasMessaged, isTrue,
        reason: 'a second send must see itself as not-first');
  });

  test('marking twice stays true and does not throw', () async {
    SharedPreferences.setMockInitialValues({});
    await FirstSessionStore.markMessaged();
    await FirstSessionStore.markMessaged();
    expect((await FirstSessionStore.read()).hasMessaged, isTrue);
  });

  test('a user who already messaged is never reported again', () async {
    // Two sends in quick succession: the guard reads the flag before writing,
    // so only the first is "first".
    SharedPreferences.setMockInitialValues({kPrefHasMessaged: true});
    var reported = 0;

    Future<void> reportIfFirst() async {
      final s = await FirstSessionStore.read();
      if (s.hasMessaged) return;
      await FirstSessionStore.markMessaged();
      reported++;
    }

    await reportIfFirst();
    await reportIfFirst();
    expect(reported, 0, reason: 'an established chatter reports nothing');
  });

  test('exactly one of several sequential first-sends reports', () async {
    SharedPreferences.setMockInitialValues({});
    var reported = 0;

    Future<void> reportIfFirst() async {
      final s = await FirstSessionStore.read();
      if (s.hasMessaged) return;
      await FirstSessionStore.markMessaged();
      reported++;
    }

    await reportIfFirst();
    await reportIfFirst();
    await reportIfFirst();
    expect(reported, 1);
  });
}
