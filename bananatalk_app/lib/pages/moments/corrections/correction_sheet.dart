import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/moments/widgets/moments_snackbar.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The operation a [DiffSpan] represents relative to the original text.
enum DiffOp { equal, removed, added }

/// A single word (or run of words) in a word-level diff, tagged with
/// whether it is unchanged, removed from the original, or added in the
/// corrected text.
class DiffSpan {
  final String text;
  final DiffOp op;

  const DiffSpan({required this.text, required this.op});

  @override
  String toString() => 'DiffSpan($op, "$text")';

  @override
  bool operator ==(Object other) =>
      other is DiffSpan && other.text == text && other.op == op;

  @override
  int get hashCode => Object.hash(text, op);
}

/// Word-level diff between [a] (original) and [b] (corrected) using an LCS
/// (longest common subsequence) over whitespace-split tokens. Matched tokens
/// become `DiffOp.equal` spans; tokens only in [a] become `DiffOp.removed`;
/// tokens only in [b] become `DiffOp.added`.
List<DiffSpan> diffWords(String a, String b) {
  final wordsA = a.trim().isEmpty ? <String>[] : a.trim().split(RegExp(r'\s+'));
  final wordsB = b.trim().isEmpty ? <String>[] : b.trim().split(RegExp(r'\s+'));

  final n = wordsA.length;
  final m = wordsB.length;

  // Standard LCS DP table.
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (int i = n - 1; i >= 0; i--) {
    for (int j = m - 1; j >= 0; j--) {
      if (wordsA[i] == wordsB[j]) {
        dp[i][j] = 1 + dp[i + 1][j + 1];
      } else {
        dp[i][j] = dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
      }
    }
  }

  // Walk the table to emit one span per word, in order.
  final spans = <DiffSpan>[];

  int i = 0, j = 0;
  while (i < n && j < m) {
    if (wordsA[i] == wordsB[j]) {
      spans.add(DiffSpan(text: wordsA[i], op: DiffOp.equal));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      spans.add(DiffSpan(text: wordsA[i], op: DiffOp.removed));
      i++;
    } else {
      spans.add(DiffSpan(text: wordsB[j], op: DiffOp.added));
      j++;
    }
  }
  while (i < n) {
    spans.add(DiffSpan(text: wordsA[i], op: DiffOp.removed));
    i++;
  }
  while (j < m) {
    spans.add(DiffSpan(text: wordsB[j], op: DiffOp.added));
    j++;
  }

  return spans;
}

/// Bottom sheet for suggesting a correction to a moment's text
/// (HelloTalk/Tandem style). Shows the original text read-only, a
/// corrected-text field prefilled with the original for inline editing,
/// and an optional explanation field.
class CorrectionSheet extends StatefulWidget {
  final String momentText;
  final Future<void> Function(
    String original,
    String corrected,
    String? explanation,
  ) onSubmit;

  const CorrectionSheet({
    super.key,
    required this.momentText,
    required this.onSubmit,
  });

  @override
  State<CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends State<CorrectionSheet> {
  late TextEditingController _correctedController;
  late TextEditingController _explanationController;
  bool _isSubmitting = false;

  bool get _hasChanges =>
      _correctedController.text.trim() != widget.momentText.trim() &&
      _correctedController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _correctedController = TextEditingController(text: widget.momentText);
    _explanationController = TextEditingController();
    _correctedController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _correctedController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_hasChanges || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        widget.momentText,
        _correctedController.text.trim(),
        _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showMomentsSnackBar(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: MomentsSnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final theme = Theme.of(context);

    final diffs = _hasChanges
        ? diffWords(widget.momentText, _correctedController.text.trim())
        : <DiffSpan>[];

    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85 - viewInsetsBottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray700 : AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.spellcheck_rounded, size: 22, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suggest a correction',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.gray800 : AppColors.gray100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      widget.momentText,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.gray300 : AppColors.gray700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your correction',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _correctedController,
                    maxLines: null,
                    minLines: 2,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.white : AppColors.gray900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type the corrected version...',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.gray600 : AppColors.gray400,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.gray800
                          : theme.primaryColor.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.gray700
                              : theme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  if (diffs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Changes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.gray800 : AppColors.gray50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text.rich(
                        TextSpan(children: _buildDiffSpans(diffs, isDark)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Explanation (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _explanationController,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.white : AppColors.gray900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Why did you make this correction?',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.gray600 : AppColors.gray400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.gray800 : AppColors.gray50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _hasChanges && !_isSubmitting ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        isDark ? AppColors.gray800 : AppColors.gray200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Send Correction',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildDiffSpans(List<DiffSpan> diffs, bool isDark) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < diffs.length; i++) {
      final d = diffs[i];
      switch (d.op) {
        case DiffOp.equal:
          spans.add(TextSpan(
            text: d.text,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.gray300 : AppColors.gray700,
            ),
          ));
          break;
        case DiffOp.removed:
          spans.add(TextSpan(
            text: d.text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.red[400],
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.red[400],
            ),
          ));
          break;
        case DiffOp.added:
          spans.add(TextSpan(
            text: d.text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ));
          break;
      }
      if (i != diffs.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return spans;
  }
}

/// Show the correction bottom sheet for a moment's description.
Future<bool?> showCorrectionSheet(
  BuildContext context, {
  required String momentText,
  required Future<void> Function(
    String original,
    String corrected,
    String? explanation,
  ) onSubmit,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: CorrectionSheet(momentText: momentText, onSubmit: onSubmit),
    ),
  );
}

/// Read-only panel rendering an accepted/suggested correction attached to a
/// comment. Visually mirrors [TranslatedMomentWidget]'s soft-tinted panel
/// (teal-accented left border) so corrections read as part of the same
/// "inline assist" family as translations: original text with per-word
/// strikethrough where changed, corrected text in teal, explanation caption.
class CorrectionPanel extends StatelessWidget {
  final String originalText;
  final String correctedText;
  final String? explanation;

  const CorrectionPanel({
    super.key,
    required this.originalText,
    required this.correctedText,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    const accent = AppColors.primary;
    final diffs = diffWords(originalText, correctedText);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? accent.withValues(alpha: 0.10) : accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.spellcheck_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                'Suggested correction',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Original with per-word strikethrough where it differs.
          Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < diffs.length; i++)
                  if (diffs[i].op != DiffOp.added) ...[
                    TextSpan(
                      text: diffs[i].text,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                        decoration: diffs[i].op == DiffOp.removed
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.red[400],
                      ),
                    ),
                    if (i != diffs.length - 1) const TextSpan(text: ' '),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Corrected text in teal.
          Text(
            correctedText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accent,
              height: 1.35,
            ),
          ),
          if (explanation != null && explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              explanation!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: context.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
