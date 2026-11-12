import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/share_offer_policy.dart';
import 'package:bananatalk_app/widgets/share_as_moment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePolicy extends ShareOfferPolicy {
  _FakePolicy({this.allowed = true});
  bool allowed;
  final calls = <String>[];

  @override
  Future<bool> canOffer(DateTime now) async {
    calls.add('canOffer');
    return allowed;
  }

  @override
  Future<void> recordShown(DateTime now) async => calls.add('shown');
  @override
  Future<void> recordDismissed(DateTime now) async => calls.add('dismissed');
  @override
  Future<void> recordAccepted(DateTime now) async => calls.add('accepted');
}

class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}

AppConfig _config(bool on) => AppConfig(
  minVersion: '1.0.0',
  latestVersion: '1.0.0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
  shareOffersEnabled: on,
);

Future<void> _pump(
  WidgetTester t, {
  required bool flag,
  required _FakePolicy policy,
  required _Obs obs,
  VoidCallback? onDismiss,
  Brightness brightness = Brightness.light,
}) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWith((ref) async => _config(flag)),
        shareOfferPolicyProvider.overrideWithValue(policy),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        navigatorObservers: [obs],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShareAsMomentCard(
            prefillText: 'Today I learned a lot',
            language: 'ko',
            onDismiss: onDismiss ?? () {},
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('flag off: builds nothing and never reads the policy', (t) async {
    final policy = _FakePolicy();
    await _pump(t, flag: false, policy: policy, obs: _Obs());
    expect(find.byType(Card), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(policy.calls, isEmpty);
  });

  testWidgets('flag on but policy refuses: nothing shown, nothing recorded', (
    t,
  ) async {
    final policy = _FakePolicy(allowed: false);
    await _pump(t, flag: true, policy: policy, obs: _Obs());
    expect(find.byType(FilledButton), findsNothing);
    expect(policy.calls, ['canOffer']);
  });

  testWidgets('flag on and allowed: shows the card and records it shown', (
    t,
  ) async {
    final policy = _FakePolicy();
    await _pump(t, flag: true, policy: policy, obs: _Obs());
    expect(find.byType(FilledButton), findsOneWidget);
    expect(policy.calls, ['canOffer', 'shown']);
  });

  testWidgets('accept opens the composer with the text and language', (
    t,
  ) async {
    final policy = _FakePolicy();
    final obs = _Obs();
    await _pump(t, flag: true, policy: policy, obs: obs);
    obs.pushed.clear();
    await t.tap(find.byType(FilledButton));
    await t.pump();
    expect(policy.calls, contains('accepted'));
    final route = obs.pushed.single as MaterialPageRoute<dynamic>;
    final composer =
        route.builder(t.element(find.byType(Scaffold))) as CreateMoment;
    expect(composer.prefillText, 'Today I learned a lot');
    expect(composer.prefillLanguage, 'ko');
    expect(composer.momentToEdit, isNull);
    expect(find.byType(FilledButton), findsNothing, reason: 'card is gone');
  });

  testWidgets('dismiss hides the card, records it, calls onDismiss', (t) async {
    final policy = _FakePolicy();
    var dismissed = 0;
    await _pump(
      t,
      flag: true,
      policy: policy,
      obs: _Obs(),
      onDismiss: () => dismissed++,
    );
    await t.tap(
      find.byTooltip(
        MaterialLocalizations.of(
          t.element(find.byType(Scaffold)),
        ).closeButtonTooltip,
      ),
    );
    await t.pump();
    expect(policy.calls, contains('dismissed'));
    expect(dismissed, 1);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('fits a small dark screen without overflow', (t) async {
    t.view.physicalSize = const Size(320, 480);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await _pump(
      t,
      flag: true,
      policy: _FakePolicy(),
      obs: _Obs(),
      brightness: Brightness.dark,
    );
    expect(find.byType(FilledButton), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
