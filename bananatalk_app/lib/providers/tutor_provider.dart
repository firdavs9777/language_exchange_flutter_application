import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor/tutor_memory.dart';
import '../models/tutor/tutor_session.dart';
import '../models/tutor/tutor_story.dart';
import '../services/api_client.dart';

/// Thin wrapper around [ApiClient] for the tutor endpoints.
///
/// Each method unwraps the standard `{success, data}` envelope our
/// [ApiClient] already returns under `response.data`.
class TutorService {
  final ApiClient _api = ApiClient();

  Future<TutorMemory> getMemory() async {
    final res = await _api.get('tutor/me');
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to load tutor memory');
    }
    return TutorMemory.fromJson(_dataObj(res.data));
  }

  Future<TutorMemory> setPersona(String persona) async {
    final res = await _api.put('tutor/persona', body: {'persona': persona});
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to set persona');
    }
    return TutorMemory.fromJson(_dataObj(res.data));
  }

  Future<DailyPlan?> getDailyPlan() async {
    final res = await _api.get('tutor/daily-plan');
    if (!res.success || res.data == null) return null;
    final obj = _dataObj(res.data);
    if (obj.isEmpty) return null;
    return DailyPlan.fromJson(obj);
  }

  Future<TutorSession> startSession() async {
    final res = await _api.post('tutor/sessions');
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to start session');
    }
    return TutorSession.fromJson(_dataObj(res.data));
  }

  Future<TutorMessage> sendMessage(String sessionId, String content) async {
    final res = await _api.post(
      'tutor/sessions/$sessionId/message',
      body: {'content': content},
    );
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to send message');
    }
    final body = _dataObj(res.data);
    final msg = body['message'];
    if (msg is! Map<String, dynamic>) {
      throw StateError('Malformed sendMessage response');
    }
    return TutorMessage.fromJson(msg);
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _api.post('tutor/sessions/$sessionId/end');
    } catch (e) {
      debugPrint('[tutor] endSession ignored: $e');
    }
  }

  /// GET /tutor/scenarios — list available roleplay scenarios.
  Future<List<TutorScenario>> listScenarios() async {
    final res = await _api.get('tutor/scenarios');
    if (!res.success || res.data == null) return [];
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? (raw['data'] as List? ?? const []) : const []);
    return list
        .map((e) => TutorScenario.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /tutor/stories/generate — returns the freshly generated story.
  Future<TutorStory> generateStory({int wordCount = 5, String theme = 'free'}) async {
    final res = await _api.post(
      'tutor/stories/generate',
      body: {'wordCount': wordCount, 'theme': theme},
    );
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to generate story');
    }
    return TutorStory.fromJson(_dataObj(res.data));
  }

  /// POST /tutor/sessions/roleplay — start a scenario session.
  Future<TutorSession> startRoleplay(String scenarioId) async {
    final res = await _api.post(
      'tutor/sessions/roleplay',
      body: {'scenarioId': scenarioId},
    );
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to start roleplay');
    }
    return TutorSession.fromJson(_dataObj(res.data));
  }

  Future<List<TutorSession>> listSessions({int limit = 10}) async {
    final res = await _api.get(
      'tutor/sessions',
      queryParams: {'limit': '$limit'},
    );
    if (!res.success || res.data == null) return [];
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? (raw['data'] as List? ?? const []) : const []);
    return list
        .map((e) => TutorSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ApiClient returns either the full body (when both `data` and
  /// `pagination` are present) or the unwrapped `data` payload. The
  /// tutor endpoints DON'T paginate, so we always want the inner object.
  Map<String, dynamic> _dataObj(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return const {};
  }
}

final tutorServiceProvider = Provider<TutorService>((_) => TutorService());

final tutorMemoryProvider = FutureProvider<TutorMemory>((ref) {
  return ref.read(tutorServiceProvider).getMemory();
});

final tutorDailyPlanProvider = FutureProvider<DailyPlan?>((ref) {
  return ref.read(tutorServiceProvider).getDailyPlan();
});

final tutorRecentSessionsProvider = FutureProvider<List<TutorSession>>((ref) {
  return ref.read(tutorServiceProvider).listSessions();
});

final tutorScenariosProvider = FutureProvider<List<TutorScenario>>((ref) {
  return ref.read(tutorServiceProvider).listScenarios();
});

class TutorChatState {
  final TutorSession? session;
  final bool sending;
  final String? error;
  const TutorChatState({this.session, this.sending = false, this.error});

  TutorChatState copyWith({TutorSession? session, bool? sending, String? error}) =>
      TutorChatState(
        session: session ?? this.session,
        sending: sending ?? this.sending,
        error: error,
      );
}

class TutorChatController extends StateNotifier<TutorChatState> {
  final TutorService _svc;
  TutorChatController(this._svc) : super(const TutorChatState());

  Future<void> start() async {
    final s = await _svc.startSession();
    state = TutorChatState(session: s);
  }

  Future<void> startRoleplay(String scenarioId) async {
    final s = await _svc.startRoleplay(scenarioId);
    state = TutorChatState(session: s);
  }

  /// Optimistically appends the user message, calls send, then appends the
  /// AI reply on success. On error, surfaces the error but leaves the
  /// user message in place so the user sees what they sent.
  Future<void> send(String content) async {
    final s = state.session;
    if (s == null) return;

    final optimistic = TutorSession(
      id: s.id,
      persona: s.persona,
      startedAt: s.startedAt,
      endedAt: s.endedAt,
      summary: s.summary,
      messages: [
        ...s.messages,
        TutorMessage(
          role: 'user',
          content: content,
          messageType: 'text',
          payload: null,
          createdAt: DateTime.now(),
        ),
      ],
    );
    state = state.copyWith(session: optimistic, sending: true, error: null);

    try {
      final reply = await _svc.sendMessage(s.id, content);
      final updated = TutorSession(
        id: s.id,
        persona: s.persona,
        startedAt: s.startedAt,
        endedAt: s.endedAt,
        summary: s.summary,
        messages: [...optimistic.messages, reply],
      );
      state = state.copyWith(session: updated, sending: false);
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }

  Future<void> end() async {
    final s = state.session;
    if (s == null) return;
    await _svc.endSession(s.id);
  }
}

final tutorChatControllerProvider =
    StateNotifierProvider.autoDispose<TutorChatController, TutorChatState>((ref) {
  return TutorChatController(ref.read(tutorServiceProvider));
});
