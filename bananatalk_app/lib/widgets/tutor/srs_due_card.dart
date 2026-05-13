import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Inline SRS-due card the tutor drops in when the user has cards
/// waiting. Payload shape:
///   { dueCount: number, preview: [{ word: string, definition?: string }] }
///
/// Tapping "Review now" sends a chat message back so the tutor can
/// either kick off an inline review (next turn) or deep-link to the
/// SRS screen. For A2 we keep it conversational — the AI's next reply
/// drives whatever happens next.
class SrsDueCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> payload;
  const SrsDueCard({super.key, required this.payload});

  @override
  ConsumerState<SrsDueCard> createState() => _SrsDueCardState();
}

class _SrsDueCardState extends ConsumerState<SrsDueCard> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dueCount = (widget.payload['dueCount'] as num?)?.toInt() ?? 0;
    final preview = (widget.payload['preview'] as List?) ?? const [];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.refresh, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  l10n.aiTutorCardReviewDue,
                  style: context.bodySmall.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aiTutorCardReviewCount(dueCount),
              style: context.titleSmall.copyWith(fontWeight: FontWeight.w600),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final raw in preview.take(3))
                if (raw is Map)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: raw['word']?.toString() ?? '',
                                  style: context.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                                if (raw['definition'] != null)
                                  TextSpan(
                                    text: '  — ${raw['definition']}',
                                    style: context.bodySmall.copyWith(
                                        color: context.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _tapped
                    ? null
                    : () {
                        setState(() => _tapped = true);
                        ref.read(tutorChatControllerProvider.notifier).send(
                              "Let's review my due cards now ($dueCount).",
                            );
                      },
                icon: const Icon(Icons.play_arrow),
                label: Text(_tapped ? l10n.aiTutorCardReviewStarting : l10n.aiTutorCardReviewNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
