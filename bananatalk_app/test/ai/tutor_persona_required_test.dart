import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';

/// No persona yet: the server refuses the chat with "Pick a persona first"
/// and the screen must open the persona picker, not a dead-end retry
/// (2026-10-17, Android device run).
class _NoPersona extends TutorService {
  @override
  Future<TutorSession> startSession() async => throw const PersonaRequiredException();
}

class _Offline extends TutorService {
  @override
  Future<TutorSession> startSession() async => throw StateError('offline');
}

void main() {
  test('the refusal is recognised by code or by message', () {
    expect(isPersonaRequired('PERSONA_REQUIRED', null), isTrue);
    expect(isPersonaRequired(null, 'Pick a persona first'), isTrue);
    expect(isPersonaRequired(null, 'Too many requests'), isFalse);
    expect(isPersonaRequired(null, null), isFalse);
  });

  Future<TutorChatState> startWith(TutorService svc) async {
    final container = ProviderContainer(
      overrides: [tutorServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(tutorChatControllerProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(tutorChatControllerProvider.notifier).start();
    return container.read(tutorChatControllerProvider);
  }

  test('no persona: the controller flags it instead of an error', () async {
    final s = await startWith(_NoPersona());
    expect(s.personaRequired, isTrue);
    expect(s.error, isNull);
  });

  test('other failures stay an error with a retry', () async {
    final s = await startWith(_Offline());
    expect(s.personaRequired, isFalse);
    expect(s.error, contains('offline'));
  });
}
