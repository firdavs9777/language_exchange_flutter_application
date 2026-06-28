import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_study_tip.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Curated tips and teaching techniques for an exam. Categorised
/// (Strategy, Grammar, Time Management, etc.) and surfaced as
/// expandable cards. Loaded via /exam-study/exams/:examId/tips.
class StudyTipsScreen extends ConsumerWidget {
  const StudyTipsScreen({super.key, required this.exam});

  final ExamType exam;

  static IconData _iconForCategory(String c) => switch (c) {
        'strategy' => Icons.flag_rounded,
        'grammar' => Icons.spellcheck_rounded,
        'vocabulary' => Icons.translate_rounded,
        'time-management' => Icons.timer_outlined,
        'common-mistakes' => Icons.report_outlined,
        'band-booster' => Icons.trending_up_rounded,
        'cultural-notes' => Icons.public_rounded,
        'pronunciation' => Icons.record_voice_over_outlined,
        'fluency' => Icons.chat_bubble_outline_rounded,
        _ => Icons.tips_and_updates_outlined,
      };

  String _labelForCategory(AppLocalizations l10n, String c) => switch (c) {
        'strategy' => l10n.examTipsCategoryStrategy,
        'grammar' => l10n.examTipsCategoryGrammar,
        'vocabulary' => l10n.examTipsCategoryVocabulary,
        'time-management' => l10n.examTipsCategoryTimeManagement,
        'common-mistakes' => l10n.examTipsCategoryCommonMistakes,
        'band-booster' => l10n.examTipsCategoryBandBooster,
        'cultural-notes' => l10n.examTipsCategoryCulturalNotes,
        'pronunciation' => l10n.examTipsCategoryPronunciation,
        'fluency' => l10n.examTipsCategoryFluency,
        _ => c,
      };

  // Display order of category groups in the UI.
  static const _categoryOrder = [
    'strategy',
    'band-booster',
    'time-management',
    'grammar',
    'vocabulary',
    'pronunciation',
    'fluency',
    'common-mistakes',
    'cultural-notes',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tipsAsync = ref.watch(examStudyTipsProvider(exam.id));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.examTipsTitle,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(examStudyTipsProvider(exam.id)),
        child: tipsAsync.when(
          data: (tips) => _buildList(context, l10n, tips),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _errorState(context, ref, l10n),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations l10n, List<ExamStudyTip> tips) {
    if (tips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.examTipsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    final byCategory = <String, List<ExamStudyTip>>{};
    for (final t in tips) {
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }
    final orderedCategories = [
      ..._categoryOrder.where(byCategory.containsKey),
      ...byCategory.keys.where((c) => !_categoryOrder.contains(c)),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          l10n.examTipsSubtitle(exam.name),
          style: TextStyle(
            fontSize: 14,
            color: context.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        for (final cat in orderedCategories) ...[
          Row(
            children: [
              Icon(_iconForCategory(cat), size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text(
                _labelForCategory(l10n, cat),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.primaryColor,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${byCategory[cat]!.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...byCategory[cat]!.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TipCard(tip: t),
              )),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _errorState(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: context.textMuted),
          const SizedBox(height: 12),
          Text(
            l10n.examStudyError,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(examStudyTipsProvider(exam.id)),
            child: Text(l10n.examStudyRetry),
          ),
        ],
      ),
    );
  }
}

/// Expandable tip card. Collapsed = title + first line of body, expanded
/// = full body. Tap anywhere on the card to toggle.
class _TipCard extends StatefulWidget {
  const _TipCard({required this.tip});
  final ExamStudyTip tip;

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.dividerColor, width: 1),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.tip.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.tip.body,
                maxLines: _expanded ? null : 2,
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
              if (_expanded && widget.tip.sectionType != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.tip.sectionType!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
