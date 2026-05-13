import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:bananatalk_app/models/tutor/tutor_memory.dart';
import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/models/tutor/tutor_story.dart';
import 'package:bananatalk_app/services/api_client.dart';

class PronunciationSentence {
  final String sentence;
  final String level;
  final String targetLanguage;
  final String ttsAudioUrl;

  const PronunciationSentence({
    required this.sentence,
    required this.level,
    required this.targetLanguage,
    required this.ttsAudioUrl,
  });

  factory PronunciationSentence.fromJson(Map<String, dynamic> j) =>
      PronunciationSentence(
        sentence: j['sentence']?.toString() ?? '',
        level: j['level']?.toString() ?? 'A1',
        targetLanguage: j['targetLanguage']?.toString() ?? 'en',
        ttsAudioUrl: j['ttsAudioUrl']?.toString() ?? '',
      );
}

class PronunciationWordScore {
  final String word;
  final String status; // 'ok' | 'wrong' | 'missing'
  final List<Map<String, dynamic>>? charDiff;

  const PronunciationWordScore({
    required this.word,
    required this.status,
    this.charDiff,
  });

  factory PronunciationWordScore.fromJson(Map<String, dynamic> j) {
    final cd = j['charDiff'];
    List<Map<String, dynamic>>? parsed;
    if (cd is List) {
      parsed = cd
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return PronunciationWordScore(
      word: j['word']?.toString() ?? '',
      status: j['status']?.toString() ?? 'missing',
      charDiff: parsed,
    );
  }
}

class PronunciationScore {
  final int overallScore;
  final String transcript;
  final List<PronunciationWordScore> wordScores;

  const PronunciationScore({
    required this.overallScore,
    required this.transcript,
    required this.wordScores,
  });

  factory PronunciationScore.fromJson(Map<String, dynamic> j) =>
      PronunciationScore(
        overallScore: (j['overallScore'] as num?)?.toInt() ?? 0,
        transcript: j['transcript']?.toString() ?? '',
        wordScores: ((j['wordScores'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => PronunciationWordScore.fromJson(
                  e.cast<String, dynamic>(),
                ))
            .toList(),
      );
}

/// Thin wrapper around [ApiClient] for the tutor endpoints.
///
/// Each method unwraps the standard `{success, data}` envelope our
/// [ApiClient] already returns under `response.data`.
class TutorService {
  final ApiClient _api = ApiClient();

  /// Step 13A: returns both memory + the top-level quotas block from
  /// the response so a single /tutor/me call can hydrate the memory
  /// provider AND the quota provider without a second HTTP round trip.
  Future<({TutorMemory memory, Map<String, dynamic>? quotas})> getMemory() async {
    final res = await _api.get('tutor/me');
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to load tutor memory');
    }
    return (
      memory: TutorMemory.fromJson(_dataObj(res.data)),
      quotas: res.quotas,
    );
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

  /// POST /tutor/pronunciation/sentence — returns a level-tuned target
  /// sentence + TTS URL. Pass [custom] to skip GPT and just TTS your
  /// own text.
  Future<PronunciationSentence> fetchPronunciationSentence({String? custom}) async {
    final body = <String, dynamic>{'preferWeakWords': true};
    if (custom != null && custom.trim().isNotEmpty) body['custom'] = custom.trim();
    final res = await _api.post('tutor/pronunciation/sentence', body: body);
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to fetch sentence');
    }
    return PronunciationSentence.fromJson(_dataObj(res.data));
  }

  /// POST /tutor/pronunciation/score — multipart audio upload, returns
  /// word-by-word score + transcript.
  Future<PronunciationScore> scorePronunciationAttempt({
    required String audioFilePath,
    required String targetSentence,
  }) async {
    // Match the existing tutor_voice_service pattern: don't override
    // contentType — let http_parser infer from the file extension.
    final multipart = await http.MultipartFile.fromPath('audio', audioFilePath);
    final res = await _api.postMultipart(
      'tutor/pronunciation/score',
      files: [multipart],
      fields: {'targetSentence': targetSentence},
    );
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to score');
    }
    return PronunciationScore.fromJson(_dataObj(res.data));
  }

  /// POST /tutor/pronunciation/summary — flushes session weak words
  /// back into TutorMemory.weakAreas (pronunciation:<word> prefix).
  Future<void> submitPronunciationSummary(List<String> weakWords) async {
    final res = await _api.post(
      'tutor/pronunciation/summary',
      body: {'weakWords': weakWords},
    );
    if (!res.success) {
      throw StateError(res.error ?? 'Failed to submit summary');
    }
  }
}

final tutorServiceProvider = Provider<TutorService>((_) => TutorService());

/// Internal — holds the raw record (memory + quotas) so we can
/// fan it out to two public providers without making two HTTP calls.
/// Step 13A.
final tutorMemoryAndQuotasProvider = FutureProvider.autoDispose<
    ({TutorMemory memory, Map<String, dynamic>? quotas})>((ref) {
  return ref.read(tutorServiceProvider).getMemory();
});

/// Public — backward-compatible memory-only view.
final tutorMemoryProvider = FutureProvider<TutorMemory>((ref) async {
  final r = await ref.watch(tutorMemoryAndQuotasProvider.future);
  return r.memory;
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
  final Ref _ref;
  TutorChatController(this._svc, this._ref) : super(const TutorChatState());

  /// Invalidate the memory+quotas provider so the chip UI re-fetches
  /// the latest quotas after a successful gated action. Step 13A.
  void _refreshQuotas() {
    try {
      _ref.invalidate(tutorMemoryAndQuotasProvider);
    } catch (_) {
      // Defensive — ref may be in a teardown state.
    }
  }

  /// Safe state setter — silently skips if the notifier was disposed
  /// (autoDispose can kick in mid-await when the screen unmounts).
  /// Without this, an in-flight session-start/sendMessage that resolves
  /// after dispose triggers a Flutter assertion when listeners try to
  /// rebuild a defunct element.
  void _safeSet(TutorChatState next) {
    if (!mounted) return;
    state = next;
  }

  Future<void> start() async {
    try {
      final s = await _svc.startSession();
      _safeSet(TutorChatState(session: s));
    } catch (e) {
      _safeSet(state.copyWith(error: e.toString()));
    }
  }

  Future<void> startRoleplay(String scenarioId) async {
    try {
      final s = await _svc.startRoleplay(scenarioId);
      _safeSet(TutorChatState(session: s));
      _refreshQuotas();
    } catch (e) {
      _safeSet(state.copyWith(error: e.toString()));
    }
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
    _safeSet(state.copyWith(session: optimistic, sending: true, error: null));

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
      _safeSet(state.copyWith(session: updated, sending: false));
      _refreshQuotas();
    } catch (e) {
      _safeSet(state.copyWith(sending: false, error: e.toString()));
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
  return TutorChatController(ref.read(tutorServiceProvider), ref);
});
