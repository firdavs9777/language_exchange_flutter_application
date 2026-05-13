import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tutor_provider.dart';
import '../../utils/theme_extensions.dart';
import '../../core/theme/app_theme.dart';

/// Inline quiz card the tutor can drop into chat.
///
/// Payload shape (from backend):
///   { question, options: [...], correctIdx, explanation }
///
/// On pick, the chosen answer is sent back as a user message so the
/// tutor sees the choice and can react on its next turn.
class QuizCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> payload;
  const QuizCard({super.key, required this.payload});

  @override
  ConsumerState<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends ConsumerState<QuizCard> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final question = widget.payload['question']?.toString() ?? '';
    final options =
        (widget.payload['options'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final correctIdx = (widget.payload['correctIdx'] as num?)?.toInt() ?? -1;
    final explanation = widget.payload['explanation']?.toString() ?? '';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Quiz',
                  style: context.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question,
              style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < options.length; i++) ...[
              _OptionTile(
                label: options[i],
                state: _picked == null
                    ? _OptState.idle
                    : (i == correctIdx
                        ? _OptState.correct
                        : (i == _picked ? _OptState.wrong : _OptState.dim)),
                onTap: _picked == null ? () => _onPick(i, correctIdx, options) : null,
              ),
              const SizedBox(height: 6),
            ],
            if (_picked != null && explanation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                explanation,
                style: context.bodySmall.copyWith(
                  color: context.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onPick(int i, int correctIdx, List<String> options) {
    setState(() => _picked = i);
    final pickedLabel = options.length > i ? options[i] : '';
    final isRight = i == correctIdx;
    final correctLabel = (correctIdx >= 0 && correctIdx < options.length)
        ? options[correctIdx]
        : 'option ${correctIdx + 1}';
    ref.read(tutorChatControllerProvider.notifier).send(
      isRight
          ? 'I picked: $pickedLabel (correct)'
          : 'I picked: $pickedLabel (wrong — correct was $correctLabel)',
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
