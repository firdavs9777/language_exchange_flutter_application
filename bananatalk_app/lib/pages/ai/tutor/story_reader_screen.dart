import 'package:flutter/material.dart';

import '../../../models/tutor/tutor_story.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Paragraph-by-paragraph reveal — answering the comprehension Q
/// correctly unlocks the next paragraph. Wrong answer gives one
/// retry hint, then unlocks anyway so the user isn't blocked.
class StoryReaderScreen extends StatefulWidget {
  final TutorStory story;
  const StoryReaderScreen({super.key, required this.story});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  int _unlockedIndex = 0; // last paragraph the user can SEE
  final Map<int, int> _picks = {}; // paragraph index → option index picked
  bool _showVocab = false;

  bool _allAnswered() {
    for (int i = 0; i < widget.story.paragraphs.length; i++) {
      if (widget.story.paragraphs[i].question != null && !_picks.containsKey(i)) {
        return false;
      }
    }
    return true;
  }

  void _onPick(int paragraphIdx, int optionIdx) {
    final q = widget.story.paragraphs[paragraphIdx].question!;
    setState(() {
      _picks[paragraphIdx] = optionIdx;
      // Unlock the next paragraph regardless — wrong answer doesn't
      // block reading, it just gets a worse summary at the end.
      if (paragraphIdx == _unlockedIndex) {
        _unlockedIndex = (paragraphIdx + 1).clamp(0, widget.story.paragraphs.length);
      }
    });
    if (optionIdx != q.correctIdx) {
      // brief shake-feedback via snackbar
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.aiTutorStoryReaderWrongHint),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = widget.story;
    final totalQs = s.paragraphs.where((p) => p.question != null).length;
    final correctCount = _picks.entries.where((e) {
      final q = s.paragraphs[e.key].question;
      return q != null && q.correctIdx == e.value;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiTutorStoryReaderTitle),
        actions: [
          IconButton(
            tooltip: l10n.aiTutorStoryReaderVocab,
            icon: Icon(_showVocab ? Icons.menu_book : Icons.menu_book_outlined),
            onPressed: () => setState(() => _showVocab = !_showVocab),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            s.title,
            style: context.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(s.level,
                  style: context.bodySmall.copyWith(color: AppColors.primary)),
              if (s.targetLanguage.isNotEmpty) ...[
                Text('  •  ',
                    style: context.bodySmall.copyWith(color: context.textMuted)),
                Text(s.targetLanguage,
                    style:
                        context.bodySmall.copyWith(color: context.textSecondary)),
              ],
            ],
          ),
          if (_showVocab && s.vocabUsed.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aiTutorStoryReaderVocabUsed,
                      style: context.bodySmall
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  for (final v in s.vocabUsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: RichText(
                        text: TextSpan(
                          style: context.bodyMedium,
                          children: [
                            TextSpan(
                              text: v.word,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (v.definition.isNotEmpty)
                              TextSpan(
                                text: '  — ${v.definition}',
                                style: context.bodySmall
                                    .copyWith(color: context.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          for (int i = 0; i < s.paragraphs.length && i <= _unlockedIndex; i++) ...[
            _ParagraphCard(
              index: i + 1,
              paragraph: s.paragraphs[i],
              picked: _picks[i],
              onPick: (opt) => _onPick(i, opt),
            ),
            const SizedBox(height: 16),
          ],
          if (_allAnswered()) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aiTutorStoryReaderNiceWork,
                      style: context.titleMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.aiTutorStoryReaderScore(correctCount, totalQs),
                    style: context.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.done),
                label: Text(l10n.aiTutorStoryReaderDone),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParagraphCard extends StatelessWidget {
  final int index;
  final StoryParagraph paragraph;
  final int? picked;
  final ValueChanged<int> onPick;

  const _ParagraphCard({
    required this.index,
    required this.paragraph,
    required this.picked,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final q = paragraph.question;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: AppRadius.borderMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.aiTutorStoryReaderPart(index),
              style: context.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text(
            paragraph.text,
            style: context.bodyLarge.copyWith(height: 1.5),
          ),
          if (q != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.borderMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.q,
                      style: context.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  for (int i = 0; i < q.options.length; i++) ...[
                    _OptionTile(
                      label: q.options[i],
                      state: picked == null
                          ? _OptState.idle
                          : (i == q.correctIdx
                              ? _OptState.correct
                              : (i == picked ? _OptState.wrong : _OptState.dim)),
                      onTap: picked == null ? () => onPick(i) : null,
                    ),
                    if (i != q.options.length - 1) const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dim }

class _OptionTile extends StatelessWidget {
  final String label;
  final _OptState state;
  final VoidCallback? onTap;
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData? icon;
    switch (state) {
      case _OptState.correct:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case _OptState.wrong:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      case _OptState.dim:
        bg = context.containerColor;
        fg = context.textMuted;
        icon = null;
        break;
      case _OptState.idle:
        bg = context.surfaceColor;
        fg = context.textPrimary;
        icon = null;
        break;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(color: fg))),
              if (icon != null) Icon(icon, color: fg, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
