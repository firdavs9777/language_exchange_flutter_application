import 'package:bananatalk_app/pages/moments/create/moment_draft_rules.dart';
import 'package:bananatalk_app/services/session_prefs.dart';
import 'package:bananatalk_app/services/share_offer_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final day1 = DateTime(2026, 11, 12, 9);
  DateTime later(DateTime d, int days, [int hour = 9]) =>
      DateTime(d.year, d.month, d.day + days, hour);

  test('a fresh install can be offered', () async {
    expect(await ShareOfferPolicy().canOffer(day1), isTrue);
  });

  test(
    'a second offer on the same local day is refused, the next day is fine',
    () async {
      final p = ShareOfferPolicy();
      await p.recordShown(day1);
      expect(await p.canOffer(DateTime(2026, 11, 12, 23, 59)), isFalse);
      expect(await p.canOffer(DateTime(2026, 11, 13, 0, 1)), isTrue);
    },
  );

  test('state survives a new policy object (it is stored)', () async {
    await ShareOfferPolicy().recordShown(day1);
    expect(await ShareOfferPolicy().canOffer(day1), isFalse);
  });

  test(
    'two consecutive dismissals: none for 7 days, allowed on day 8',
    () async {
      final p = ShareOfferPolicy();
      await p.recordShown(day1);
      await p.recordDismissed(day1);
      final d2 = later(day1, 1);
      expect(await p.canOffer(d2), isTrue);
      await p.recordShown(d2);
      await p.recordDismissed(d2);
      for (var i = 1; i <= 7; i++) {
        expect(await p.canOffer(later(d2, i)), isFalse, reason: 'day +$i');
      }
      expect(await p.canOffer(later(d2, 8, 0)), isTrue);
    },
  );

  test('one dismissal does not block the next day', () async {
    final p = ShareOfferPolicy();
    await p.recordShown(day1);
    await p.recordDismissed(day1);
    expect(await p.canOffer(later(day1, 1)), isTrue);
  });

  test('an accept between dismissals resets the count', () async {
    final p = ShareOfferPolicy();
    await p.recordDismissed(day1);
    await p.recordAccepted(later(day1, 1));
    await p.recordDismissed(later(day1, 2));
    // Only one dismissal since the accept: not blocked.
    expect(await p.canOffer(later(day1, 3)), isTrue);
  });

  test('after the 7 days the count starts again', () async {
    final p = ShareOfferPolicy();
    await p.recordDismissed(day1);
    await p.recordDismissed(day1);
    final d8 = later(day1, 8);
    expect(await p.canOffer(d8), isTrue);
    await p.recordDismissed(d8);
    expect(await p.canOffer(later(d8, 1)), isTrue);
  });

  test('uses the device-local date of the instant it is given', () async {
    final p = ShareOfferPolicy();
    await p.recordShown(DateTime.utc(2026, 11, 12, 12).toLocal());
    expect(await p.canOffer(DateTime.utc(2026, 11, 12, 12).toLocal()), isFalse);
  });

  test('its keys are user-scoped: sign-out removes them', () async {
    final p = ShareOfferPolicy();
    await p.recordShown(day1);
    await p.recordDismissed(day1);
    await p.recordDismissed(day1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isNotEmpty);
    expect(prefs.getKeys().where(isDeviceLevelPrefsKey), isEmpty);
    await clearUserScopedPrefs(prefs);
    expect(prefs.getKeys(), isEmpty);
  });

  group('textPrefill (composer)', () {
    test('fills a new post', () {
      expect(
        textPrefill(editing: false, isReel: false, prefillText: ' hi '),
        'hi',
      );
    });
    test('never over an edit', () {
      expect(
        textPrefill(editing: true, isReel: false, prefillText: 'hi'),
        isNull,
      );
    });
    test('never in a reel, never over a prompt, ignores blanks', () {
      expect(
        textPrefill(editing: false, isReel: true, prefillText: 'x'),
        isNull,
      );
      expect(
        textPrefill(
          editing: false,
          isReel: false,
          prefillPrompt: 'p',
          prefillText: 'x',
        ),
        isNull,
      );
      expect(
        textPrefill(editing: false, isReel: false, prefillText: '  '),
        isNull,
      );
      expect(textPrefill(editing: false, isReel: false), isNull);
    });
  });
}
