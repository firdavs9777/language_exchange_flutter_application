import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class ConversationStarterRibbon extends StatelessWidget {
  final Community community;
  final bool compact;

  const ConversationStarterRibbon({
    super.key,
    required this.community,
    this.compact = false,
  });

  String _pickPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = community.location.country;
    final language = community.language_to_learn;
    final candidates = <String>[
      l10n.starterAskMoment,
      l10n.starterSayHi,
      l10n.starterCurious,
      if (country.isNotEmpty) l10n.starterFromCountry(country),
      if (language.isNotEmpty) l10n.starterPracticeLang(language),
    ];
    if (candidates.isEmpty) return l10n.starterSayHi;
    final hash = community.id.hashCode.abs();
    return candidates[hash % candidates.length];
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _pickPrompt(context);
    return GestureDetector(
      onTap: () {
        context.push(
          '/chat/${community.id}?prefill=${Uri.encodeComponent(prompt)}',
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: compact ? 12 : 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                prompt,
                style: (compact ? context.captionSmall : context.bodySmall)
                    .copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
