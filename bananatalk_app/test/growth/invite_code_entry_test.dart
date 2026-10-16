import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/pages/profile/referral_invite_code_card.dart';
import 'package:bananatalk_app/pages/profile/referral_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/referral_service.dart';

import '../helpers/community_fixture.dart';

class _FakeService implements ReferralService {
  _FakeService({this.error});
  final Object? error;
  final int invitee = 50;
  final claimed = <String>[];

  @override
  Future<ReferralInfo> getMine() async =>
      const ReferralInfo(code: 'ABC234', link: 'https://banatalk.com/i/ABC234', invited: 0);

  @override
  Future<ReferralClaimResult> claim(String code) async {
    claimed.add(code);
    if (error != null) throw error!;
    return ReferralClaimResult(inviter: 100, invitee: invitee);
  }
}

Future<void> _pump(WidgetTester tester, _FakeService service, {int daysOld = 2}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      referralServiceProvider.overrideWithValue(service),
      userProvider.overrideWith((ref) async => communityFixture(daysOld: daysOld)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ReferralScreen(),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  final l10n = AppLocalizationsEn();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('canEnterInviteCode', () {
    final now = DateTime.utc(2026, 10, 16, 12);
    test('inside 14 days', () {
      expect(canEnterInviteCode('2026-10-03T12:00:01Z', now), isTrue);
    });
    test('14 days or older, or unparseable', () {
      expect(canEnterInviteCode('2026-10-02T12:00:00Z', now), isFalse);
      expect(canEnterInviteCode('', now), isFalse);
      expect(canEnterInviteCode('not a date', now), isFalse);
    });
  });

  group('inviteClaimErrorText', () {
    test('unknown code', () {
      expect(
        inviteClaimErrorText(l10n, const ReferralRejectedException('x', statusCode: 404, code: referralUnknownCode)),
        l10n.referralCodeUnknown,
      );
    });
    test('other refusals', () {
      for (final e in const [
        ReferralRejectedException('Referral already claimed', statusCode: 409),
        ReferralRejectedException('limit', statusCode: 409, code: 'INVITER_CAP'),
        ReferralRejectedException('Referrals are only available to new accounts', statusCode: 400),
      ]) {
        expect(inviteClaimErrorText(l10n, e), l10n.referralCodeNotAccepted);
      }
    });
    test('network / 5xx', () {
      expect(inviteClaimErrorText(l10n, Exception('socket')), l10n.networkError);
    });
  });

  testWidgets('a new account claims a typed code', (tester) async {
    final service = _FakeService();
    await _pump(tester, service);
    expect(find.byKey(const ValueKey('invite_code_card')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('invite_code_field')), ' abcd2345 ');
    await tester.tap(find.byKey(const ValueKey('invite_code_apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.claimed, ['ABCD2345']);
    expect(find.text('You earned 50 coins!'), findsOneWidget);
    expect(find.byKey(const ValueKey('invite_code_card')), findsNothing);
  });

  testWidgets('an unknown code shows the error and keeps the card', (tester) async {
    final service = _FakeService(
      error: const ReferralRejectedException('Unknown referral code', statusCode: 404, code: referralUnknownCode),
    );
    await _pump(tester, service);
    await tester.enterText(find.byKey(const ValueKey('invite_code_field')), 'ZZZZ2345');
    await tester.tap(find.byKey(const ValueKey('invite_code_apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(l10n.referralCodeUnknown), findsOneWidget);
    expect(find.byKey(const ValueKey('invite_code_card')), findsOneWidget);
  });

  testWidgets('an invalid code is refused locally', (tester) async {
    final service = _FakeService();
    await _pump(tester, service);
    await tester.enterText(find.byKey(const ValueKey('invite_code_field')), 'AB-1');
    await tester.tap(find.byKey(const ValueKey('invite_code_apply')));
    await tester.pump();
    expect(service.claimed, isEmpty);
    expect(find.text(l10n.referralCodeUnknown), findsOneWidget);
  });

  testWidgets('a stored pending code is prefilled', (tester) async {
    SharedPreferences.setMockInitialValues({pendingReferralPrefsKey: 'QWER2345'});
    await _pump(tester, _FakeService());
    expect(find.text('QWER2345'), findsOneWidget);
  });

  testWidgets('accounts 14+ days old do not see the card', (tester) async {
    await _pump(tester, _FakeService(), daysOld: 30);
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.byKey(const ValueKey('invite_code_card')), findsNothing);
  });
}
