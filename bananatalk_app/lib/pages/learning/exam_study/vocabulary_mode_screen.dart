import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:bananatalk_app/pages/learning/exam_study/vocabulary_quiz_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/word_card.dart';
import 'package:bananatalk_app/providers/provider_models/exam/vocabulary_word.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 3 of the Vocabulary flow — toggle between Browse (word list with
/// audio) and Practice (10-Q quiz). Both modes use the same (level, topic)
/// scope set on the previous screen.
class VocabularyModeScreen extends ConsumerStatefulWidget {
  const VocabularyModeScreen({
    super.key,
    required this.examId,
    required this.examName,
    required this.level,
    this.topic,
  });

  final String examId;
  final String examName;
  final String level;
  final String? topic;

  @override
  ConsumerState<VocabularyModeScreen> createState() =>
      _VocabularyModeScreenState();
}

class _VocabularyModeScreenState extends ConsumerState<VocabularyModeScreen> {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  String? _playingWordId;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playWord(VocabularyWord word) async {
    setState(() => _playingWordId = word.id);
    try {
      String? url = word.audioUrl;
      if (url == null || url.isEmpty) {
        url = await ref
            .read(examStudyServiceProvider)
            .getVocabularyAudioUrl(word.id);
      }
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        setState(() => _playingWordId = null);
        return;
      }
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
      if (mounted) setState(() => _playingWordId = null);
    } catch (_) {
      if (mounted) setState(() => _playingWordId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wordsAsync = ref.watch(
      vocabularyWordsProvider(
        VocabularyWordsQuery(
          examId: widget.examId,
          level: widget.level,
          topic: widget.topic,
          limit: 100,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          widget.topic ?? l10n.examVocabAllTopics,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: _modeButton(
                    context,
                    label: l10n.examVocabBrowse,
                    icon: Icons.list_alt_rounded,
                    selected: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _modeButton(
                    context,
                    label: l10n.examVocabPractice,
                    icon: Icons.quiz_outlined,
                    selected: false,
                    onTap: () => _openPractice(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(
                vocabularyWordsProvider(
                  VocabularyWordsQuery(
                    examId: widget.examId,
                    level: widget.level,
                    topic: widget.topic,
                    limit: 100,
                  ),
                ),
              ),
              child: wordsAsync.when(
                data: (words) => _buildList(context, words, l10n),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    l10n.examStudyError,
                    style: TextStyle(color: context.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<VocabularyWord> words,
    AppLocalizations l10n,
  ) {
    if (words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.examVocabEmptyList,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final word = words[index];
        return WordCard(
          word: word,
          isPlaying: _playingWordId == word.id,
          onPlayAudio: () => _playWord(word),
        );
      },
    );
  }

  Widget _modeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? context.primaryColor
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.primaryColor : context.dividerColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : context.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPractice(BuildContext context) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => VocabularyQuizScreen(
          examId: widget.examId,
          level: widget.level,
          topic: widget.topic,
        ),
      ),
    );
  }
}
