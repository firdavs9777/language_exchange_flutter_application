import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/session_prefs.dart';

import '../helpers/community_fixture.dart';

class _NoBiometric implements BiometricTokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> save(String token) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final events = <(String, Map<String, Object>)>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  List<Map<String, Object>> milestones() => [
        for (final e in events)
          if (e.$1 == 'activation_milestone') e.$2,
      ];

  test('markDone is idempotent and only a new set reports', () async {
    final s = ActivationStore();
    expect(await s.markDone(ActivationAction.moment), isTrue);
    expect(await s.markDone(ActivationAction.moment), isFalse);
    expect(await s.isDone(ActivationAction.moment), isTrue);
    expect(await s.doneCount(), 1);
    expect(milestones(), [
      {'action': 'moment', 'count': 1},
    ]);
  });

  test('count is the number done after this one', () async {
    final s = ActivationStore();
    await s.markDone(ActivationAction.lesson);
    await s.markDone(ActivationAction.profile);
    expect(milestones().last, {'action': 'profile', 'count': 2});
  });

  test('two concurrent marks report once', () async {
    final s = ActivationStore();
    final r = await Future.wait([
      s.markDone(ActivationAction.lesson),
      s.markDone(ActivationAction.lesson),
    ]);
    expect(r.where((x) => x), hasLength(1));
    expect(milestones(), hasLength(1));
  });

  test('an existing install that already messaged is back-filled silently',
      () async {
    SharedPreferences.setMockInitialValues({'first_conversation_done': true});
    final s = ActivationStore();
    expect(await s.isDone(ActivationAction.message), isTrue);
    expect(await s.doneCount(), 1);
    expect(milestones(), isEmpty);
  });

  test('a first message after the first read still reports once', () async {
    final s = ActivationStore();
    expect(await s.isDone(ActivationAction.message), isFalse);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_conversation_done', true);
    expect(await s.markDone(ActivationAction.message), isTrue);
    expect(milestones(), [
      {'action': 'message', 'count': 1},
    ]);
  });

  test('a wrong-typed pref reads as not done instead of throwing', () async {
    SharedPreferences.setMockInitialValues({'activation_done_lesson': 'yes'});
    expect(await ActivationStore().isDone(ActivationAction.lesson), isFalse);
  });

  test('slugs and pref keys are append-only', () {
    expect(ActivationAction.values.map((a) => a.slug),
        ['message', 'moment', 'lesson', 'profile']);
    expect(ActivationAction.lesson.prefKey, 'activation_done_lesson');
  });

  test('profile counts only with a photo AND a bio', () async {
    await checkProfileComplete(
        communityFixture(imageUrls: const ['https://x/a.jpg'], bio: '  '));
    expect(await ActivationStore().isDone(ActivationAction.profile), isFalse);
    await checkProfileComplete(
        communityFixture(imageUrls: const ['https://x/a.jpg'], bio: 'Hi'));
    expect(await ActivationStore().isDone(ActivationAction.profile), isTrue);
  });

  test('logout clears activation state (user-scoped prefs)', () async {
    await ActivationStore().markDone(ActivationAction.moment);
    final prefs = await SharedPreferences.getInstance();
    await clearUserSessionPrefs(prefs: prefs, biometricStorage: _NoBiometric());
    expect(await ActivationStore().doneCount(), 0);
  });

  test('activationDoneProvider re-emits after markDone', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sub = c.listen(activationDoneProvider, (_, __) {});
    addTearDown(sub.close);
    expect(await c.read(activationDoneProvider.future), isEmpty);
    await ActivationStore().markDone(ActivationAction.lesson);
    await pumpEventQueue();
    expect(c.read(activationDoneProvider).valueOrNull,
        {ActivationAction.lesson});
  });
}
