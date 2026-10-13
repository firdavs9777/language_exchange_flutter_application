import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/services/app_config_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/services/launch_candidates.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/services/version_check_coordinator.dart';
import 'package:bananatalk_app/services/welcome_back_service.dart';
import 'package:bananatalk_app/widgets/welcome_back_modal.dart';

import '../helpers/community_fixture.dart';

class _FakeConfigService extends AppConfigService {
  _FakeConfigService(this._fetch);
  final Future<AppConfig?> Function() _fetch;
  @override
  Future<AppConfig?> fetch() => _fetch();
}

AppConfig _config({
  String min = '0.0.0',
  String latest = '0.0.0',
  bool force = false,
}) =>
    AppConfig(
      minVersion: min,
      latestVersion: latest,
      forceUpdate: force,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      announcements: const [
        Announcement(id: 'a1', title: 'Big news', body: 'Body', priority: 1),
      ],
    );

Future<BuildContext> _app(WidgetTester t) async {
  // A phone-sized surface: the ads notice sheet is taller than 800x600.
  await t.binding.setSurfaceSize(const Size(430, 1000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  late BuildContext ctx;
  await t.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })),
  ));
  return ctx;
}

/// The TabBarMenu run, minus the shell: what shows after the splash.
Future<void> _launch(BuildContext ctx, AppConfig config,
        {bool guidePeriod = false}) =>
    LaunchModalCoordinator(standardLaunchCandidates(
      config: config,
      pickSpotlight: () async => null,
      onSpotlightTry: (_) {},
    )).run(ctx,
        guidePeriod: guidePeriod,
        updateShown: VersionCheckCoordinator.lastCheckShowedUpdate);

Future<bool> _announcementShown() async =>
    (await AnnouncementSeenStore.read())!.contains('a1');

Future<bool> _adsNoticeShown() async =>
    (await SharedPreferences.getInstance()).getBool('ads_notice_shown_v1') ==
    true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'BananaTalk',
      packageName: 'com.bananatalk',
      version: '2.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    PopupBudget.debugReset();
    VersionCheckCoordinator.lastCheckShowedUpdate = false;
  });

  group('guide period at launch', () {
    test('a failed user load takes the restrictive path', () async {
      final c = ProviderContainer(overrides: [
        userProvider.overrideWith((ref) async => throw Exception('offline')),
      ]);
      addTearDown(c.dispose);
      expect(await launchGuidePeriod(() => c.read(isGuidePeriodProvider.future)),
          isTrue);
    });

    test('a loaded answer is used as is', () async {
      final c = ProviderContainer(overrides: [
        userProvider.overrideWith((ref) async => communityFixture(daysOld: 30)),
      ]);
      addTearDown(c.dispose);
      expect(await launchGuidePeriod(() => c.read(isGuidePeriodProvider.future)),
          isFalse);
    });

    testWidgets('restrictive path: no launch pop-up, the budget is left for priming', (t) async {
      final ctx = await _app(t);
      final guidePeriod = await launchGuidePeriod(() async => throw 'boom');
      await _launch(ctx, _config(), guidePeriod: guidePeriod);
      await t.pumpAndSettle();
      expect(await _announcementShown(), isFalse);
      expect(await _adsNoticeShown(), isFalse);
      expect(PopupBudget.spent, isFalse,
          reason: "a new user's first-session notification priming still gets its pop-up");
    });

    testWidgets('after the guide period the ads notice shows once as before', (t) async {
      final ctx = await _app(t);
      _launch(ctx, _config(), guidePeriod: false); // announcement first
      await t.pumpAndSettle();
      expect(await _announcementShown(), isTrue);
      expect(await _adsNoticeShown(), isFalse);
    });
  });

  group('update dialog', () {
    testWidgets('a force update blocks every other pop-up', (t) async {
      final ctx = await _app(t);
      final cfg = _config(min: '3.0.0', force: true);
      // Never completes: the force dialog cannot be dismissed.
      VersionCheckCoordinator(service: _FakeConfigService(() async => cfg))
          .check(ctx);
      await t.pump();
      await t.pump();
      expect(VersionCheckCoordinator.lastCheckShowedUpdate, isTrue);
      expect(PopupBudget.spent, isTrue);

      expect(await maybeShowWelcomeBack(ctx, due: true), isFalse);
      await _launch(ctx, cfg);
      expect(await _announcementShown(), isFalse);
      expect(await _adsNoticeShown(), isFalse);
      expect(PopupBudget.tryConsume(), isFalse, reason: 'priming blocked too');
    });

    testWidgets('a force update shows even when the budget is spent',
        (t) async {
      final ctx = await _app(t);
      PopupBudget.tryConsume();
      VersionCheckCoordinator(
              service: _FakeConfigService(() async => _config(force: true)))
          .check(ctx);
      await t.pump();
      await t.pump();
      expect(VersionCheckCoordinator.lastCheckShowedUpdate, isTrue);
    });

    testWidgets('a soft update is the launch pop-up', (t) async {
      final ctx = await _app(t);
      final cfg = _config(latest: '2.1.0');
      final shown = VersionCheckCoordinator(
              service: _FakeConfigService(() async => cfg))
          .check(ctx);
      await t.pumpAndSettle();
      // Dismiss it ("Later" = barrier tap).
      await t.tapAt(const Offset(5, 5));
      await t.pumpAndSettle();
      expect(await shown, isTrue);
      expect(await maybeShowWelcomeBack(ctx, due: true), isFalse);
      await _launch(ctx, cfg);
      expect(await _announcementShown(), isFalse);
      expect(await _adsNoticeShown(), isFalse);
    });

    testWidgets('a soft update waits when the budget is already spent',
        (t) async {
      final ctx = await _app(t);
      PopupBudget.tryConsume();
      final shown = await VersionCheckCoordinator(
              service: _FakeConfigService(() async => _config(latest: '2.1.0')))
          .check(ctx);
      expect(shown, isFalse);
      expect(VersionCheckCoordinator.lastCheckShowedUpdate, isFalse);
    });

    testWidgets('no update: nothing shown, the budget stays free', (t) async {
      final ctx = await _app(t);
      final cfg = _config();
      expect(
          await VersionCheckCoordinator(
                  service: _FakeConfigService(() async => cfg))
              .check(ctx),
          isFalse);
      expect(PopupBudget.spent, isFalse);
      _launch(ctx, cfg); // sheet stays open
      await t.pumpAndSettle();
      expect(find.text('Big news'), findsOneWidget);
      expect(await _announcementShown(), isTrue);
    });

    testWidgets('a throwing check counts as not shown; launch continues',
        (t) async {
      final ctx = await _app(t);
      final shown = await VersionCheckCoordinator.checkSafely(ctx,
          coordinator: VersionCheckCoordinator(
              service: _FakeConfigService(() async => throw 'network')));
      expect(shown, isFalse);
      expect(VersionCheckCoordinator.lastCheckShowedUpdate, isFalse);
      expect(PopupBudget.spent, isFalse);
      _launch(ctx, _config()); // sheet stays open
      await t.pumpAndSettle();
      expect(await _announcementShown(), isTrue);
    });
  });

  group('splash welcome-back (R5)', () {
    testWidgets('due + free budget: shows and spends the budget', (t) async {
      final ctx = await _app(t);
      final shown = maybeShowWelcomeBack(ctx, due: true);
      await t.pumpAndSettle();
      expect(find.text('Welcome back! 👋'), findsOneWidget);
      expect(PopupBudget.spent, isTrue);
      await _launch(ctx, _config());
      expect(await _announcementShown(), isFalse);
      expect(await _adsNoticeShown(), isFalse);
      Navigator.of(ctx).pop();
      await t.pumpAndSettle();
      expect(await shown, isTrue);
    });

    testWidgets('not due: no sheet, budget untouched', (t) async {
      final ctx = await _app(t);
      expect(await maybeShowWelcomeBack(ctx, due: false), isFalse);
      expect(PopupBudget.spent, isFalse);
    });

    testWidgets('budget spent by the update dialog: welcome-back is not marked', (t) async {
      final eightDaysAgo = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'last_app_open_ms': eightDaysAgo});
      final ctx = await _app(t);
      expect(await WelcomeBackService.isDue(), isTrue);
      PopupBudget.tryConsume(); // the update dialog
      var marked = false;
      expect(
          await maybeShowWelcomeBack(ctx, due: true, onShown: () async {
            marked = true;
            await WelcomeBackService.markOpened();
          }),
          isFalse);
      expect(marked, isFalse);
      expect(await WelcomeBackService.isDue(), isTrue,
          reason: 'still armed for the next launch');
    });

    testWidgets('shown: marked as it opens, no longer due', (t) async {
      final eightDaysAgo = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'last_app_open_ms': eightDaysAgo});
      final ctx = await _app(t);
      final shown = maybeShowWelcomeBack(ctx,
          due: true, onShown: WelcomeBackService.markOpened);
      await t.pumpAndSettle();
      expect(await WelcomeBackService.isDue(), isFalse);
      Navigator.of(ctx).pop();
      await t.pumpAndSettle();
      expect(await shown, isTrue);
    });
  });

  group('WelcomeBackService', () {
    test('isDue reads only; markOpened records the launch', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await WelcomeBackService.isDue(), isFalse, reason: 'first launch');
      final old = DateTime.now()
          .subtract(const Duration(days: 7, minutes: 1))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'last_app_open_ms': old});
      expect(await WelcomeBackService.isDue(), isTrue);
      expect(await WelcomeBackService.isDue(), isTrue, reason: 'reading does not mark');
      await WelcomeBackService.markOpened();
      expect(await WelcomeBackService.isDue(), isFalse);
    });
  });

  test('splash and shell are wired through the shared budget', () {
    final splash =
        File('lib/pages/home/splash_screen.dart').readAsStringSync();
    expect(splash.contains('VersionCheckCoordinator.checkSafely('), isTrue);
    expect(splash.contains('maybeShowWelcomeBack('), isTrue);
    expect(splash.contains('showWelcomeBackModal('), isFalse);
    final shell = File('lib/pages/menu_tab/TabBarMenu.dart').readAsStringSync();
    expect(shell.contains('launchGuidePeriod('), isTrue);
    expect(
        shell.contains(
            'updateShown: VersionCheckCoordinator.lastCheckShowedUpdate'),
        isTrue);
    expect(shell.contains('showFeatureSpotlight('), isFalse);
  });
}
