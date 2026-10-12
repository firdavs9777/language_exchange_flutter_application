import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/services/launch_candidates.dart';
import 'package:bananatalk_app/widgets/promo/announcement_modal.dart';

const _cfg = AppConfig(
  minVersion: '0.0.0', latestVersion: '0.0.0', forceUpdate: false,
  iosUrl: '', androidUrl: '', releaseNotes: '',
  announcements: [Announcement(id: 'a1', title: 'Big news', body: 'Body', priority: 1)],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('order and new-user filter (spec §4.1)', () {
    final c = standardLaunchCandidates(
        config: null, pickSpotlight: () async => null, onSpotlightTry: (_) {});
    expect(c.map((x) => x.id), ['announcement', 'ads_notice', 'feature_spotlight']);
    expect(c.map((x) => x.allowedForNewUsers), [false, true, false]);
  });

  test('ads notice is due once per install', () async {
    expect(await AdsNoticeCandidate().isDue(), isTrue);
    SharedPreferences.setMockInitialValues({'ads_notice_shown_v1': true});
    expect(await AdsNoticeCandidate().isDue(), isFalse);
  });

  testWidgets('announcement: due when unseen, shown, then seen', (t) async {
    final c = AnnouncementCandidate(config: _cfg);
    expect(await c.isDue(), isTrue);
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (ctx) => TextButton(
          onPressed: () => c.show(ctx), child: const Text('go'))),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Big news'), findsOneWidget);
    expect(await AnnouncementSeenStore.read(), contains('a1'));
    expect(await AnnouncementCandidate(config: _cfg).isDue(), isFalse);
  });

  testWidgets('announcement: a failed show does not mark it seen', (t) async {
    final c = AnnouncementCandidate(config: _cfg);
    expect(await c.isDue(), isTrue);
    late BuildContext ctx;
    // No Navigator / MaterialApp: the sheet cannot be pushed.
    await t.pumpWidget(Builder(builder: (b) {
      ctx = b;
      return const SizedBox();
    }));
    Object? error;
    try {
      await c.show(ctx);
    } catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(await AnnouncementSeenStore.read(), isNot(contains('a1')));
    expect(await AnnouncementCandidate(config: _cfg).isDue(), isTrue);
  });

  test('announcement: unreadable seen set or no config shows nothing',
      () async {
    expect(await AnnouncementCandidate(config: null).isDue(), isFalse);
    SharedPreferences.setMockInitialValues({kAnnouncementsSeenKey: 'oops'});
    expect(await AnnouncementCandidate(config: _cfg).isDue(), isFalse);
  });

  test('announcement links', () {
    expect(announcementLinkKind('/learning/daily'), AnnouncementLinkKind.inApp);
    expect(announcementLinkKind('https://banatalk.com/x'), AnnouncementLinkKind.external);
    expect(announcementLinkKind('  '), AnnouncementLinkKind.none);
    // Controller ruling R1 / A11: the model's rule decides.
    expect(announcementLinkKind('bananatalk://moment/1'), AnnouncementLinkKind.inApp);
    expect(announcementLinkKind('//evil.example'), AnnouncementLinkKind.none);
    expect(announcementLinkKind('ftp://x.example/a'), AnnouncementLinkKind.none);
    expect(announcementLinkKind('javascript:alert(1)'), AnnouncementLinkKind.none);
    expect(announcementRoutePath('bananatalk://moment/1'), '/moment/1');
    expect(announcementRoutePath('BananaTalk://community/matches'),
        '/community/matches');
    expect(announcementRoutePath(' /learning/daily '), '/learning/daily');
    expect(announcementRoutePath('https://banatalk.com/x'), isNull);
  });

  test('openAnnouncementLink: router for app links, browser for http(s)',
      () async {
    final pushed = <String>[];
    final launched = <Uri>[];
    Future<void> open(String url) => openAnnouncementLink(url,
        push: pushed.add,
        launch: (u) async {
          launched.add(u);
          return true;
        });
    await open('bananatalk://moment/1');
    await open('/learning/daily');
    await open('https://banatalk.com/x');
    await open('//evil.example');
    await open('mailto:a@b.c');
    expect(pushed, ['/moment/1', '/learning/daily']);
    expect(launched, [Uri.parse('https://banatalk.com/x')]);
  });

  test('the version check no longer owns the announcement; the shell runs the coordinator', () {
    expect(File('lib/services/version_check_coordinator.dart')
        .readAsStringSync().contains('AnnouncementModal'), isFalse);
    final shell = File('lib/pages/menu_tab/TabBarMenu.dart').readAsStringSync();
    expect(shell.contains('LaunchModalCoordinator('), isTrue);
    expect(shell.contains('AdsNoticeModal.showIfNeeded'), isFalse);
  });
}
