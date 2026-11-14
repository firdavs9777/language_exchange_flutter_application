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
  // Local copy of the provider's rows, so a row can leave at once and come
  // back if the request fails.
  MyWords? _source;
  List<WordCandidate> _candidates = [];
  List<StudyMistakeItem> _mistakes = [];

  // Ids with a request in flight: a second tap sends nothing.
  final Set<String> _busy = {};

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
    _busy.clear();
  }

  void _failed() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.myWordsActionFailed),
      ),
    );
  }

  /// Keep or dismiss: the row leaves now and returns to its place on failure.
  Future<void> _removeCandidate(
    WordCandidate c,
    Future<void> Function(MyWordsApi api) call, {
    bool isKeep = false,
  }) async {
    if (!_busy.add(c.id)) return;
    final index = _candidates.indexWhere((x) => x.id == c.id);
    if (index < 0) {
      _busy.remove(c.id);
      return;
    }
    setState(() => _candidates.removeAt(index));
    try {
      await call(ref.read(myWordsApiProvider));
      if (isKeep) ref.invalidate(vocabularyStatsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _candidates.insert(index.clamp(0, _candidates.length), c);
      });
      _failed();
    } finally {
      _busy.remove(c.id);
    }
  }

  Future<void> _gotIt(StudyMistakeItem m) async {
    if (!_busy.add(m.id)) return;
    setState(() {});
    try {
      final r = await ref.read(myWordsApiProvider).gotIt(m.id);
      if (!mounted) return;
      setState(() {
        final i = _mistakes.indexWhere((x) => x.id == m.id);
        if (i < 0) return;
        if (r.resolved) {
          _mistakes.removeAt(i);
        } else {
          _mistakes[i] = StudyMistakeItem(
            id: m.id,
            original: m.original,
            corrected: m.corrected,
            explanation: m.explanation,
            source: m.source,
            language: m.language,
            successes: r.successes,
          );
        }
      });
    } catch (_) {
      _failed();
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
    final due = ref.watch(vocabularyStatsProvider(null)).value?.dueToday ?? 0;
    final data = async.value;
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
      final empty = _candidates.isEmpty && _mistakes.isEmpty && due <= 0;
      body = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vocabularyStatsProvider);
          ref.invalidate(myWordsProvider);
          await ref.read(myWordsProvider.future);
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
            if (_candidates.isNotEmpty) ...[
              _heading(l10n.myWordsFromChats),
              for (final c in _candidates)
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
            if (_mistakes.isNotEmpty) ...[
              _heading(l10n.myWordsMistakes),
              for (final m in _mistakes)
                MistakeRow(
                  key: ValueKey('mistake-${m.id}'),
                  mistake: m,
                  busy: _busy.contains(m.id),
                  onGotIt: () => _gotIt(m),
                  onSayIt: () => _sayIt(m.corrected, m.language),
                ),
            ],
            if (due > 0) ...[
              _heading(l10n.myWordsToReview),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.myWordsDueCount(due),
                      style: context.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
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
                ],
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
