import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/services/pronunciation_voice_service.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';

enum PronStatus {
  loading,
  ready,
  recording,
  scoring,
  scored,
  summary,
}

class SentenceAttempt {
  final PronunciationSentence sentence;
  final PronunciationScore? lastScore;
  final int attempts;

  const SentenceAttempt({
    required this.sentence,
    this.lastScore,
    this.attempts = 0,
  });

  SentenceAttempt copyWith({
    PronunciationSentence? sentence,
    PronunciationScore? lastScore,
    int? attempts,
  }) =>
      SentenceAttempt(
        sentence: sentence ?? this.sentence,
        lastScore: lastScore ?? this.lastScore,
        attempts: attempts ?? this.attempts,
      );
}

class PronunciationState {
  final PronStatus status;
  final int currentIndex;
  final List<SentenceAttempt> session;
  final String? errorMessage;
  final String? recordingPath;
  final bool customDraftOpen;

  const PronunciationState({
    this.status = PronStatus.loading,
    this.currentIndex = 0,
    this.session = const [],
    this.errorMessage,
    this.recordingPath,
    this.customDraftOpen = false,
  });

  static const int sessionLength = 5;

  PronunciationState copyWith({
    PronStatus? status,
    int? currentIndex,
    List<SentenceAttempt>? session,
    String? errorMessage,
    String? recordingPath,
    bool? customDraftOpen,
    bool clearError = false,
    bool clearRecording = false,
  }) =>
      PronunciationState(
        status: status ?? this.status,
        currentIndex: currentIndex ?? this.currentIndex,
        session: session ?? this.session,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        recordingPath:
            clearRecording ? null : (recordingPath ?? this.recordingPath),
        customDraftOpen: customDraftOpen ?? this.customDraftOpen,
      );

  SentenceAttempt? get current =>
      currentIndex < session.length ? session[currentIndex] : null;
}

class PronunciationController extends StateNotifier<PronunciationState> {
  final TutorService _svc;
  final PronunciationVoiceService _voice;
  final Ref _ref;
  PronunciationController(this._svc, this._voice, this._ref)
      : super(const PronunciationState());

  /// Guards every state write — autoDispose can tear the controller down
  /// mid-await (e.g. user backs out during a 3-5s sentence-generation
  /// call), and writing to a defunct StateNotifier would crash any
  /// ConsumerStatefulElement still listening. Mirrors the pattern landed
  /// for TutorChatController.
  void _safeSet(PronunciationState next) {
    if (!mounted) return;
    state = next;
  }

  Future<void> init() async {
    _safeSet(state.copyWith(status: PronStatus.loading, clearError: true));
    try {
      final s = await _svc.fetchPronunciationSentence();
      _safeSet(state.copyWith(
        session: [SentenceAttempt(sentence: s)],
        currentIndex: 0,
        status: PronStatus.ready,
      ));
    } catch (e) {
      _safeSet(state.copyWith(
        status: PronStatus.loading,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Custom-mode entry: skip AI sentence generation on the first
  /// sentence, seed an empty placeholder attempt, and open the
  /// custom-draft TextField immediately. submitCustom() will fetch
  /// the TTS-only response once the user types.
  void initCustomMode() {
    const empty = PronunciationSentence(
      sentence: '',
      level: 'A1',
      targetLanguage: 'en',
      ttsAudioUrl: '',
    );
    _safeSet(state.copyWith(
      session: const [SentenceAttempt(sentence: empty)],
      currentIndex: 0,
      status: PronStatus.ready,
      customDraftOpen: true,
      clearError: true,
    ));
  }

  Future<void> tapRecord() async {
    if (state.status != PronStatus.ready) return;
    final granted = await _voice.requestMicPermission();
    if (!mounted) return;
    if (!granted) {
      _safeSet(state.copyWith(
        errorMessage: 'Microphone permission denied. Please enable it in Settings.',
      ));
      return;
    }
    try {
      final path = await _voice.startRecording();
      _safeSet(state.copyWith(
        status: PronStatus.recording,
        recordingPath: path,
        clearError: true,
      ));
    } catch (e) {
      _safeSet(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> tapStop() async {
    if (state.status != PronStatus.recording) return;
    final path = await _voice.stopRecording();
    final current = state.current;
    if (!mounted) return;
    if (path == null || current == null) {
      _safeSet(state.copyWith(status: PronStatus.ready));
      return;
    }
    _safeSet(state.copyWith(status: PronStatus.scoring, clearError: true));
    try {
      final score = await _svc.scorePronunciationAttempt(
        audioFilePath: path,
        targetSentence: current.sentence.sentence,
      );
      final updated = [...state.session];
      updated[state.currentIndex] = current.copyWith(
        lastScore: score,
        attempts: current.attempts + 1,
      );
      _safeSet(state.copyWith(session: updated, status: PronStatus.scored));
    } catch (e) {
      _safeSet(state.copyWith(
        status: PronStatus.scored,
        errorMessage: e.toString(),
      ));
    }
  }

  void retry() {
    if (state.status != PronStatus.scored) return;
    _safeSet(state.copyWith(status: PronStatus.ready, clearError: true));
  }

  Future<void> next() async {
    if (state.status != PronStatus.scored) return;
    final isLast = state.currentIndex + 1 >= PronunciationState.sessionLength;
    if (isLast) {
      _safeSet(state.copyWith(status: PronStatus.summary));
      return;
    }
    _safeSet(state.copyWith(status: PronStatus.loading, clearError: true));
    try {
      final nextSentence = await _svc.fetchPronunciationSentence();
      final updated = [...state.session, SentenceAttempt(sentence: nextSentence)];
      _safeSet(state.copyWith(
        session: updated,
        currentIndex: state.currentIndex + 1,
        status: PronStatus.ready,
      ));
    } catch (e) {
      _safeSet(state.copyWith(
        status: PronStatus.loading,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> submitCustom(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _safeSet(state.copyWith(status: PronStatus.loading, clearError: true));
    try {
      final s = await _svc.fetchPronunciationSentence(custom: trimmed);
      final updated = [...state.session];
      updated[state.currentIndex] = SentenceAttempt(sentence: s);
      _safeSet(state.copyWith(
        session: updated,
        status: PronStatus.ready,
        customDraftOpen: false,
      ));
    } catch (e) {
      _safeSet(state.copyWith(
        status: PronStatus.ready,
        errorMessage: e.toString(),
      ));
    }
  }

  void openCustomDraft() => _safeSet(state.copyWith(customDraftOpen: true));
  void closeCustomDraft() => _safeSet(state.copyWith(customDraftOpen: false));

  Future<void> playReference() async {
    final c = state.current;
    if (c == null) return;
    await _voice.playReference(c.sentence.ttsAudioUrl);
  }

  Future<void> finish() async {
    final weakWords = <String>{};
    for (final a in state.session) {
      final s = a.lastScore;
      if (s == null) continue;
      for (final w in s.wordScores) {
        if (w.status == 'wrong' || w.status == 'missing') {
          weakWords.add(w.word);
        }
      }
    }
    try {
      await _svc.submitPronunciationSummary(weakWords.take(5).toList());
      // Step 13A: invalidate so the AI Tools tab re-fetches /tutor/me
      // and the quota indicator reflects the post-increment count.
      try {
        _ref.invalidate(tutorMemoryAndQuotasProvider);
      } catch (_) {
        // Defensive — ref may be in a teardown state.
      }
    } catch (e) {
      _safeSet(state.copyWith(errorMessage: e.toString()));
      rethrow;
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }
}

final pronunciationVoiceServiceProvider =
    Provider<PronunciationVoiceService>((_) => PronunciationVoiceService());

final pronunciationControllerProvider = StateNotifierProvider.autoDispose<
    PronunciationController, PronunciationState>((ref) {
  return PronunciationController(
    ref.read(tutorServiceProvider),
    ref.read(pronunciationVoiceServiceProvider),
    ref,
  );
});
