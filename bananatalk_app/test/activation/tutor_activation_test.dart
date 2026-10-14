import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/activation_store.dart';

/// Answers the two calls a tutor chat needs; anything else is a test bug.
class _FakeTutorService implements TutorService {
  _FakeTutorService({this.fail = false});
  final bool fail;

  TutorSession _session() => TutorSession(
    id: 's1',
    persona: 'friendly',
    messages: const [],
    startedAt: DateTime(2026, 10, 14),
  );

  @override
  Future<TutorSession> startSession() async => _session();

  @override
  Future<TutorSession> startRoleplay(String scenarioId) async => _session();

  @override
  Future<TutorMessage> sendMessage(String sessionId, String content) async {
    if (fail) throw StateError('network');
    return TutorMessage(
      role: 'assistant',
      content: 'hello',
      messageType: 'text',
      payload: null,
      createdAt: DateTime(2026, 10, 14),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Spec §7: a real tutor exchange is a learning start, so tutor-only users
/// stop seeing the AI Study guide.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<bool> runChat(_FakeTutorService svc, {bool roleplay = false}) async {
    final container = ProviderContainer(
      overrides: [tutorServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    // Keep the autoDispose controller alive across the awaits.
    final sub = container.listen(tutorChatControllerProvider, (_, __) {});
    addTearDown(sub.close);
    final c = container.read(tutorChatControllerProvider.notifier);
    if (roleplay) {
      await c.startRoleplay('scenario');
    } else {
      await c.start();
    }
    await c.send('hi');
    // markDone is fire-and-forget; let it land.
    await Future<void>.delayed(Duration.zero);
    return ActivationStore().isDone(ActivationAction.lesson);
  }

  test('a successful tutor reply records the lesson milestone', () async {
    expect(await runChat(_FakeTutorService()), isTrue);
  });

  test('a successful roleplay reply records the lesson milestone', () async {
    expect(await runChat(_FakeTutorService(), roleplay: true), isTrue);
  });

  test('a failed send does not', () async {
    expect(await runChat(_FakeTutorService(fail: true)), isFalse);
  });
}
