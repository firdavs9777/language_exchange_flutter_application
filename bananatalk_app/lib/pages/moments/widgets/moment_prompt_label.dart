import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter/material.dart';

/// "Answering: {emoji} {prompt}" — shown on the moment card and the moment
/// detail screen when the moment answers a daily prompt. Renders nothing
/// when [prompt] is null (older backends, or no prompt).
class MomentPromptLabel extends StatelessWidget {
  const MomentPromptLabel({
    super.key,
    required this.prompt,
    this.padding = EdgeInsets.zero,
    this.maxLines = 2,
  });

  final MomentPrompt? prompt;
  final EdgeInsetsGeometry padding;
  final int? maxLines;

  static const _accent = Color(0xFFC9A415);

  @override
  Widget build(BuildContext context) {
    final p = prompt;
    if (p == null) return const SizedBox.shrink();
    final label = AppLocalizations.of(context)!.momentAnsweringPrompt(
      p.display,
    );
    return Padding(
      padding: padding,
      child: Container(
        key: const Key('moment-prompt-label'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.emoji.isEmpty) ...[
              const Icon(Icons.wb_sunny_outlined, size: 14, color: _accent),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
                maxLines: maxLines,
                overflow: maxLines == null
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
