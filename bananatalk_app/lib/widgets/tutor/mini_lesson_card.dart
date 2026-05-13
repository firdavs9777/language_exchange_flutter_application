import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Inline mini-lesson card the tutor drops in when teaching a small
/// concept. Payload shape:
///   { title: string, bullets: [string, ...up to 3],
///     practicePrompt?: string }
///
/// If practicePrompt is present, the card surfaces a "Try it"
/// CTA that sends the prompt back as a user message so the AI
/// can grade the attempt on its next turn.
class MiniLessonCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> payload;
  const MiniLessonCard({super.key, required this.payload});

  @override
  ConsumerState<MiniLessonCard> createState() => _MiniLessonCardState();
}

class _MiniLessonCardState extends ConsumerState<MiniLessonCard> {
  bool _practiced = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.payload['title']?.toString() ?? '';
    final bullets =
        (widget.payload['bullets'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final practicePrompt = widget.payload['practicePrompt']?.toString();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: Colors.indigo.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined, size: 16, color: Colors.indigo),
                const SizedBox(width: 6),
                Text(
                  l10n.aiTutorCardMiniLesson,
                  style: context.bodySmall.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: context.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final b in bullets.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: context.bodyMedium),
                    Expanded(child: Text(b, style: context.bodyMedium)),
                  ],
                ),
              ),
            if (practicePrompt != null && practicePrompt.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _practiced
                      ? null
                      : () {
                          setState(() => _practiced = true);
                          ref.read(tutorChatControllerProvider.notifier).send(
                                "Let me try: $practicePrompt",
                              );
                        },
                  icon: const Icon(Icons.edit),
                  label: Text(_practiced ? l10n.aiTutorCardPracticing : l10n.aiTutorCardTryIt),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
