import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/referral_screen.dart';
import 'package:bananatalk_app/services/referral_service.dart';

class _FakeService implements ReferralService {
  _FakeService({this.fail = false});
  final bool fail;
  @override
  Future<ReferralInfo> getMine() async {
    if (fail) throw Exception('boom');
    return const ReferralInfo(
        code: 'ABC234', link: 'https://banatalk.com/i/ABC234', invited: 2);
  }

  @override
  Future<ReferralClaimResult> claim(String code) async =>
      const ReferralClaimResult(inviter: 0, invitee: 0);
}

Future<void> _pump(WidgetTester tester, ReferralService service) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [referralServiceProvider.overrideWithValue(service)],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReferralScreen(),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('shows code and invited count', (tester) async {
    await _pump(tester, _FakeService());
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.text('Invited: 2'), findsOneWidget);
  });

  testWidgets('error shows a retry button', (tester) async {
    await _pump(tester, _FakeService(fail: true));
    expect(find.byKey(const ValueKey('referral_retry')), findsOneWidget);
  });
}
