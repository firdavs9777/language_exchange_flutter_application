import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/pages/moments/reels/create_reel_flow.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Banana-accent card shown atop the "For You" feed tab that surfaces the
/// deterministic prompt-of-the-day (see `promptOfDayProvider`, Task 5) and
/// deep-links into the moment composer with the prompt pre-filled.
///
/// The prompt is deliberately in the user's `language_to_learn` (writing
/// practice in the target language — the server derives it). To make that
/// obvious rather than confusing, the card shows a "Practice writing in
/// {language}" subtitle and a tap-to-translate toggle that renders the
/// prompt in the user's native language inline.
///
/// Renders nothing while loading, on error, or if the backend returns no
/// prompt for the day — the tab simply falls back to the plain feed.
///
/// NOTE: card strings are plain English for now (matching the card's
/// pre-existing 'Prompt of the day' / 'Answer' strings) — l10n pass is a
/// follow-up.
class PromptOfDayCard extends ConsumerStatefulWidget {
  const PromptOfDayCard({super.key});

  @override
  ConsumerState<PromptOfDayCard> createState() => _PromptOfDayCardState();
}

class _PromptOfDayCardState extends ConsumerState<PromptOfDayCard> {
  static const Color _accent = Color(0xFFFFD54F);
  static const Color _accentDark = Color(0xFFC9A415);

  String? _translation; // fetched once, then toggled from memory
  bool _showTranslation = false;
  bool _translating = false;
  bool _translationFailed = false;

  Future<void> _toggleTranslation(String prompt, String? sourceLanguage) async {
    if (_showTranslation) {
      setState(() => _showTranslation = false);
      return;
    }
    if (_translation != null) {
      setState(() => _showTranslation = true);
      return;
    }
    setState(() {
      _translating = true;
      _translationFailed = false;
    });

    // Translate into the user's native language (profile-cached, device
    // fallback). Reuses the raw-text enhanced-translate endpoint; on ANY
    // failure (network, quota) this degrades to a soft "Translation
    // unavailable" label instead of failing hard.
    final target = await TranslationService.getAutoTranslateLanguage();
    final result = await TranslationService.translateWord(
      word: prompt,
      targetLanguage: target,
      sourceLanguage: sourceLanguage,
    );

    if (!mounted) return;
    setState(() {
      _translating = false;
      if (result != null && result.trim().isNotEmpty) {
        _translation = result;
        _showTranslation = true;
      } else {
        _translationFailed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final promptAsync = ref.watch(promptOfDayProvider);

    return promptAsync.when(
      data: (data) {
        final prompt = data['text'] as String?;
        if (prompt == null || prompt.isEmpty) {
          return const SizedBox.shrink();
        }

        final emoji = data['emoji'] as String? ?? '💬';
        final promptId = data['promptId']?.toString();
        final langCode = (data['language'] as String? ?? '').trim();
        final langName = langCode.isEmpty
            ? ''
            : TranslationService.getLanguageName(langCode);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prompt of the day',
                      style: context.labelSmall.copyWith(
                        color: context.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_showTranslation && _translation != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _translation!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    _buildContextRow(context, prompt, langCode, langName),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton(
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
                      backgroundColor: _accentDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Answer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  // Workstream G: camera-answer entry point into the reel
                  // creation flow, pre-tagged with this prompt. Hidden
                  // while the server-side Reels kill switch is off.
                  if (ref.watch(appConfigProvider).maybeWhen(
                        data: (config) => config?.reelsEnabled ?? false,
                        orElse: () => false,
                      )) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          AppPageRoute(
                            builder: (_) => CreateReelFlow(
                              prefillPrompt: prompt,
                              prefillPromptId: promptId,
                              prefillLanguage:
                                  langCode.isEmpty ? null : langCode,
                            ),
                          ),
                        ).then((_) => ref.invalidate(forYouMomentsProvider));
                      },
                      child: Text(
                        '🎥 Answer on camera',
                        style: context.labelSmall.copyWith(
                          color: _accentDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// "Practice writing in {language} · See translation" line. The subtitle
  /// explains WHY the prompt is in the target language; the trailing
  /// affordance toggles an inline native-language translation.
  Widget _buildContextRow(
    BuildContext context,
    String prompt,
    String langCode,
    String langName,
  ) {
    final secondaryStyle = context.labelSmall.copyWith(
      color: context.textSecondary,
    );

    final String translateLabel;
    if (_translating) {
      translateLabel = 'Translating…';
    } else if (_translationFailed) {
      translateLabel = 'Translation unavailable';
    } else if (_showTranslation) {
      translateLabel = 'Hide translation';
    } else {
      translateLabel = 'See translation';
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        if (langName.isNotEmpty)
          Text('Practice writing in $langName', style: secondaryStyle),
        if (langName.isNotEmpty) Text('·', style: secondaryStyle),
        GestureDetector(
          onTap: (_translating || _translationFailed)
              ? null
              : () => _toggleTranslation(
                    prompt,
                    langCode.isEmpty ? null : langCode,
                  ),
          child: Text(
            translateLabel,
            style: secondaryStyle.copyWith(
              color: _translationFailed ? context.textSecondary : _accentDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
