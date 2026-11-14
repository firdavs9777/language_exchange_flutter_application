import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';
import 'package:bananatalk_app/pages/learning/my_words/widgets/candidate_row.dart';
import 'package:bananatalk_app/pages/learning/my_words/widgets/mistake_row.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/providers/provider_root/learning/my_words_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/services/study/my_words_api.dart';
import 'package:bananatalk_app/services/study/study_tracker.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Words looked up in chats, mistakes to practise, and words due for review.
class MyWordsScreen extends ConsumerStatefulWidget {
  const MyWordsScreen({super.key});

  @override
  ConsumerState<MyWordsScreen> createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends ConsumerState<MyWordsScreen> {
  // The provider's rows, in server order. Rows with a request in flight or
  // already done are hidden, not removed, so a refresh can neither bring a
  // row back nor duplicate it, and a failure puts it back in its own place.
  MyWords? _source;
  List<WordCandidate> _candidates = [];
  List<StudyMistakeItem> _mistakes = [];

  // Ids hidden from the lists: removal in flight or confirmed.
  final Set<String> _hidden = {};

  // Ids with a request in flight: a second tap sends nothing.
  final Set<String> _busy = {};

  // Latest "got it" count per mistake, over whatever a refresh returns.
  final Map<String, int> _progress = {};

  @override
  void initState() {
    super.initState();
    studyLog(StudyEvent.featureOpened, kind: 'my_words');
  }

  void _adopt(MyWords data) {
    if (identical(_source, data)) return;
    _source = data;
    _candidates = List.of(data.candidates);
    _mistakes = List.of(data.mistakes);
  }

  List<WordCandidate> get _visibleCandidates => [
    for (final c in _candidates)
      if (!_hidden.contains(c.id)) c,
  ];

  List<StudyMistakeItem> get _visibleMistakes => [
    for (final m in _mistakes)
      if (!_hidden.contains(m.id)) m,
  ];

  /// Keep or dismiss: the row leaves now and comes back on failure.
  Future<void> _removeCandidate(
    WordCandidate c,
    Future<void> Function(MyWordsApi api) call, {
    bool isKeep = false,
  }) async {
    if (!_busy.add(c.id)) return;
    // Taken before the await: the screen may be gone when the answer lands.
    final api = ref.read(myWordsApiProvider);
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final failedText = AppLocalizations.of(context)!.myWordsActionFailed;
    setState(() => _hidden.add(c.id));
    try {
      await call(api);
      if (isKeep) container.invalidate(vocabularyStatsProvider);
    } catch (_) {
      _hidden.remove(c.id);
      if (mounted) {
        setState(() {});
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(failedText)));
      }
    } finally {
      _busy.remove(c.id);
    }
  }

  Future<void> _gotIt(StudyMistakeItem m) async {
    if (!_busy.add(m.id)) return;
    final api = ref.read(myWordsApiProvider);
    final messenger = ScaffoldMessenger.of(context);
    final failedText = AppLocalizations.of(context)!.myWordsActionFailed;
    setState(() {});
    try {
      final r = await api.gotIt(m.id);
      _progress[m.id] = r.successes;
      if (r.resolved) _hidden.add(m.id);
    } catch (_) {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(failedText)));
      }
    } finally {
      _busy.remove(m.id);
      if (mounted) setState(() {});
    }
  }

  /// Says [text] in the row's own [language].
  void _sayIt(String text, String language) {
    studyLog(StudyEvent.featureOpened, kind: 'say_it');
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => PronunciationScreen(
          initialText: text,
          initialLanguage: language,
          ownSentence: true,
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Text(text, style: context.titleMedium),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(myWordsProvider);
    final stats = ref.watch(vocabularyStatsProvider(null));
    final due = stats.valueOrNull?.dueToday ?? 0;
    final statsLoading = stats.isLoading && stats.valueOrNull == null;
    final data = async.valueOrNull;
    if (data != null) _adopt(data);

    Widget body;
    if (data == null && async.hasError) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              l10n.somethingWentWrong,
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(myWordsProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    } else if (data == null) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else {
      final candidates = _visibleCandidates;
      final mistakes = _visibleMistakes;
      final empty =
          candidates.isEmpty && mistakes.isEmpty && due <= 0 && !statsLoading;
      body = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vocabularyStatsProvider);
          ref.invalidate(myWordsProvider);
          try {
            await ref.read(myWordsProvider.future);
          } catch (_) {
            // A failed refresh keeps the rows on screen.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (empty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  l10n.myWordsEmpty,
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
            if (candidates.isNotEmpty) ...[
              _heading(l10n.myWordsFromChats),
              for (final c in candidates)
                CandidateRow(
                  key: ValueKey('candidate-${c.id}'),
                  candidate: c,
                  busy: _busy.contains(c.id),
                  onKeep: () => _removeCandidate(
                    c,
                    (api) => api.keep(c.id),
                    isKeep: true,
                  ),
                  onDismiss: () =>
                      _removeCandidate(c, (api) => api.dismiss(c.id)),
                  onSayIt: () => _sayIt(c.text, c.language),
                ),
            ],
            if (mistakes.isNotEmpty) ...[
              _heading(l10n.myWordsMistakes),
              for (final m in mistakes)
                MistakeRow(
                  key: ValueKey('mistake-${m.id}'),
                  mistake: _progress.containsKey(m.id)
                      ? _withSuccesses(m, _progress[m.id]!)
                      : m,
                  busy: _busy.contains(m.id),
                  onGotIt: () => _gotIt(m),
                  onSayIt: () => _sayIt(m.corrected, m.language),
                ),
            ],
            if (due > 0) ...[
              _heading(l10n.myWordsToReview),
              Text(l10n.myWordsDueCount(due), style: context.bodyMedium),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    AppPageRoute(
                      builder: (_) => const VocabularyReviewScreen(),
                    ),
                  ),
                  child: Text(l10n.myWordsReview),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myWordsTitle)),
      body: body,
    );
  }
}

StudyMistakeItem _withSuccesses(StudyMistakeItem m, int successes) =>
    StudyMistakeItem(
      id: m.id,
      original: m.original,
      corrected: m.corrected,
      explanation: m.explanation,
      source: m.source,
      language: m.language,
      successes: successes,
    );
