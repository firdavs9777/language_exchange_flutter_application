import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/theme_extensions.dart';
import 'pronunciation_session_screen.dart';

/// Entry screen for the Pronunciation Coach drill.
///
/// Surfaces the two ways to pick a target sentence so users see both
/// options upfront instead of discovering "Use my own ✏️" only after
/// the first AI sentence has loaded.
class PronunciationStartScreen extends StatelessWidget {
  const PronunciationStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiTutorChipPronounce)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                l10n.aiTutorPronounceStartHeadline,
                style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.aiTutorPronounceStartSubhead,
                style: context.bodyMedium.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: 24),
              _ChoiceCard(
                emoji: '✨',
                title: l10n.aiTutorPronounceStartAITitle,
                subtitle: l10n.aiTutorPronounceStartAISubtitle,
                color: AppColors.primary,
                onTap: () => _push(context, customMode: false),
              ),
              const SizedBox(height: 12),
              _ChoiceCard(
                emoji: '✏️',
                title: l10n.aiTutorPronounceStartCustomTitle,
                subtitle: l10n.aiTutorPronounceStartCustomSubtitle,
                color: const Color(0xFF8B5CF6),
                onTap: () => _push(context, customMode: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, {required bool customMode}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PronunciationSessionScreen(startInCustomMode: customMode),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Material(
      color: isDark ? context.cardBackground : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.3 : 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.12 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: context.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: context.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
