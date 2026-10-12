import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';

import '../helpers/community_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final events = <(String, Map<String, Object>)>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  test('all guides stop at 3 of 4 actions', () {
    expect(shouldShowGuide(withinWindow: true, acted: false, milestonesDone: 2),
        isTrue);
    expect(shouldShowGuide(withinWindow: true, acted: false, milestonesDone: 3),
        isFalse);
  });

  test('the window is 7 days', () => expect(kGuideWindowDays, 7));

  test('each surface retires on its own real action', () {
    expect(GuideSurface.aiStudy.action, ActivationAction.lesson);
    expect(GuideSurface.moments.action, ActivationAction.moment);
    expect(GuideSurface.chats.action, ActivationAction.message);
    expect(GuideSurface.matches.action, ActivationAction.message);
    expect(GuideSurface.profile.action, ActivationAction.profile);
    expect(GuideSurface.chatTip.action, isNull);
    expect(GuideSurface.chatTip.slug, 'chat_tip');
    expect(GuideSurface.chatTip.actedKey, 'guide_acted_chat_tip');
  });

  test('guideRetiredReason', () {
    String? r({bool shown = true, bool win = true, bool acted = false, int n = 0}) =>
        guideRetiredReason(
            wasShown: shown, withinWindow: win, acted: acted, milestonesDone: n);
    expect(r(), isNull, reason: 'still showing');
    expect(r(shown: false, acted: true), isNull, reason: 'never shown');
    expect(r(acted: true, n: 3), 'acted');
    expect(r(n: 3), 'milestones');
    expect(r(win: false), 'window');
  });

  test('guide_retired is logged once per surface', () async {
    await GuideStore.recordRetired(GuideSurface.moments, 'acted');
    await GuideStore.recordRetired(GuideSurface.moments, 'acted');
    await GuideStore.recordRetired(GuideSurface.chats, 'window');
    final retired = [for (final e in events) if (e.$1 == 'guide_retired') e.$2];
    expect(retired, [
      {'surface': 'moments', 'reason': 'acted'},
      {'surface': 'chats', 'reason': 'window'},
    ]);
  });

  group('isGuidePeriod', () {
    test('no user, or past 7 days, is not the guide period', () async {
      final s = ActivationStore();
      expect(await isGuidePeriod(null, s), isFalse);
      expect(await isGuidePeriod(communityFixture(daysOld: 8), s), isFalse);
    });
    test('2 of 4 inside the window is; 3 of 4 is not', () async {
      final s = ActivationStore();
      await s.markDone(ActivationAction.lesson);
      await s.markDone(ActivationAction.moment);
      expect(await isGuidePeriod(communityFixture(), s), isTrue);
      await s.markDone(ActivationAction.message);
      expect(await isGuidePeriod(communityFixture(), s), isFalse);
    });
    test('the provider back-fills profile from the loaded user', () async {
      final c = ProviderContainer(overrides: [
        userProvider.overrideWith((ref) async => communityFixture(
            imageUrls: const ['https://x/a.jpg'], bio: 'Hi')),
      ]);
      addTearDown(c.dispose);
      expect(await c.read(isGuidePeriodProvider.future), isTrue);
      expect(await ActivationStore().isDone(ActivationAction.profile), isTrue);
    });
    test('an unlistened read right after the 3rd action does not hang',
        () async {
      final c = ProviderContainer(overrides: [
        userProvider.overrideWith((ref) async => communityFixture()),
      ]);
      addTearDown(c.dispose);
      final s = ActivationStore();
      await s.markDone(ActivationAction.lesson);
      await s.markDone(ActivationAction.moment);
      expect(await c.read(isGuidePeriodProvider.future), isTrue);
      await s.markDone(ActivationAction.message);
      expect(
        await c
            .read(isGuidePeriodProvider.future)
            .timeout(const Duration(seconds: 2)),
        isFalse,
      );
    });
    test('with a listener the value flips live on the 3rd action', () async {
      final c = ProviderContainer(overrides: [
        userProvider.overrideWith((ref) async => communityFixture()),
      ]);
      addTearDown(c.dispose);
      final seen = <bool>[];
      c.listen(isGuidePeriodProvider, (_, n) {
        final v = n.valueOrNull;
        if (v != null) seen.add(v);
      }, fireImmediately: true);
      final s = ActivationStore();
      await s.markDone(ActivationAction.lesson);
      await s.markDone(ActivationAction.moment);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(seen.last, isTrue);
      await s.markDone(ActivationAction.message);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(seen.last, isFalse);
    });
    test('a failed user load throws rather than answering', () async {
      final c = ProviderContainer(overrides: [
        userProvider.overrideWith((ref) async => throw Exception('offline')),
      ]);
      addTearDown(c.dispose);
      await expectLater(
          c.read(isGuidePeriodProvider.future), throwsA(isA<Exception>()));
    });
  });
}
