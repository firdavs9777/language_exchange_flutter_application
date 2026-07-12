import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Banana-accent card shown atop the "For You" feed tab that surfaces the
/// deterministic prompt-of-the-day (see `promptOfDayProvider`, Task 5) and
/// deep-links into the moment composer with the prompt pre-filled.
///
/// Renders nothing while loading, on error, or if the backend returns no
/// prompt for the day — the tab simply falls back to the plain feed.
class PromptOfDayCard extends ConsumerWidget {
  const PromptOfDayCard({super.key});

  static const Color _accent = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promptAsync = ref.watch(promptOfDayProvider);

    return promptAsync.when(
      data: (data) {
        final prompt = data['text'] as String?;
        if (prompt == null || prompt.isEmpty) {
          return const SizedBox.shrink();
        }

        final emoji = data['emoji'] as String? ?? '💬';
        final promptId = data['promptId']?.toString();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prompt of the day',
                      style: context.labelMedium.copyWith(
                        color: context.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt,
                      style: context.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            AppPageRoute(
                              builder: (_) => CreateMoment(
                                prefillPrompt: prompt,
                                prefillPromptId: promptId,
                              ),
                            ),
                          ).then((_) => ref.invalidate(forYouMomentsProvider));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC9A415),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Answer',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
