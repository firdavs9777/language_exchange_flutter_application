import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/community/first_session/first_message_reporter.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

/// Source-level for the same reason as first_message_paths_test: the
/// failure is a hook bolted to a path users do not take.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<(String, Map<String, Object>)> events;
  setUp(() {
    events = [];
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  test('the first successful send records the message milestone', () async {
    SharedPreferences.setMockInitialValues({});
    await reportFirstMessageIfFirst();
    expect(await ActivationStore().isDone(ActivationAction.message), isTrue);
  });

  test(
      'a brand-new user whose store was never read still logs the milestone '
      'exactly once (the back-fill must not swallow it)', () async {
    SharedPreferences.setMockInitialValues({});
    await reportFirstMessageIfFirst();
    await reportFirstMessageIfFirst();
    final milestones = events
        .where((e) =>
            e.$1 == 'activation_milestone' && e.$2['action'] == 'message')
        .toList();
    expect(milestones.length, 1);
  });

  const hooks = <String, (String, int)>{
    'lib/pages/moments/create/create_moment.dart': ('ActivationAction.moment', 1),
    'lib/services/upload_queue_service.dart': ('ActivationAction.moment', 2),
    'lib/providers/provider_root/learning/lessons_providers.dart':
        ('ActivationAction.lesson', 1),
    'lib/providers/provider_root/learning/quizzes_providers.dart':
        ('ActivationAction.lesson', 1),
    'lib/providers/provider_root/learning/vocabulary_providers.dart':
        ('ActivationAction.lesson', 1),
    'lib/pages/learning/daily/daily_pack_flow.dart':
        ('ActivationAction.lesson', 1),
    // Tutor chat and roleplay both reply through TutorChatController.send.
    'lib/providers/tutor_provider.dart': ('ActivationAction.lesson', 1),
    'lib/pages/profile/profile_main.dart': ('checkProfileComplete(', 1),
  };
  test('create_moment reads the activation store before awaiting createMoments', () {
    // After the await the user may have left the screen (ref unusable).
    final src = File('lib/pages/moments/create/create_moment.dart').readAsStringSync();
    final read = src.indexOf('ref.read(activationStoreProvider)');
    final create = src.indexOf('.createMoments(');
    final mark = src.indexOf('activation.markDone(ActivationAction.moment)');
    expect(read, greaterThan(-1));
    expect(read, lessThan(create));
    expect(mark, greaterThan(create));
  });

  test('vocab review records the lesson on any successful card, not only the last',
      () {
    final src = File('lib/providers/provider_root/learning/vocabulary_providers.dart')
        .readAsStringSync();
    expect(src.contains("if (result['success'] == true) {\n      ActivationStore()"),
        isTrue);
    expect(src.contains('isComplete && result'), isFalse);
  });

  for (final e in hooks.entries) {
    test('${e.key} records ${e.value.$1} on success (${e.value.$2}x)', () {
      final src = File(e.key).readAsStringSync();
      expect(e.value.$1.allMatches(src).length, e.value.$2);
    });
  }
}
