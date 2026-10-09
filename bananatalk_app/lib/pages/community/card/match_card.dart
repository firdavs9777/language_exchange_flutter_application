import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/card/match_reason_chips.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/utils/country_flags.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/guides/pulse_highlight.dart';

/// One daily-match card: avatar, identity row, language pair, reasons, actions.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onSayHi,
    required this.onWave,
    required this.onSkip,
    this.highlightSayHi = false,
  });

  final DailyMatch match;
  final VoidCallback onSayHi;
  final VoidCallback onWave;
  final VoidCallback onSkip;

  /// Rings Say hi for a first-timer. Set on the TOP card only: the guide
  /// above names one action, and three cards all pulsing at once is a page
  /// flashing rather than a page pointing.
  final bool highlightSayHi;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = match.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showCountry = user.privacySettings?.showCountryRegion ?? true;
    final flag = CountryFlags.userBadgeFlag(
      country: showCountry ? user.location.country : null,
      nativeLanguage: user.native_language,
    );
    final activeToday = match.lastActiveBucket == 'today';
    final repliesFast = match.responseRate != null && match.responseRate! >= 0.7;
    final pair = [user.native_language, user.language_to_learn]
        .where((s) => s.isNotEmpty)
        .join(' → ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.matchHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: user.profileImageUrl, name: user.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.matchInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(flag, style: const TextStyle(fontSize: 16)),
                        if (activeToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            key: const Key('match-presence-dot'),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.matchSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (pair.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.matchChipSurface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              pair,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.matchInk,
                              ),
                            ),
                          ),
                          if (repliesFast)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.matchSuccessTint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.matchRepliesFast,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.matchSuccess,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ] else if (repliesFast) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.matchRepliesFast,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.matchSuccess,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (match.boosted) ...[
            Container(
              key: const Key('match-boosted-chip'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.matchAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.boostedChip,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.matchInk,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          MatchReasonChips(match: match),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PulseHighlight(
                  enabled: highlightSayHi,
                  color: AppColors.matchAccent,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      key: const Key('match-say-hi'),
                      onPressed: onSayHi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.matchAccent,
                        foregroundColor: AppColors.matchInk,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const _SayHiLabel(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 84,
                height: 44,
                child: OutlinedButton(
                  key: const Key('match-wave'),
                  onPressed: onWave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.matchInk,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : AppColors.matchHairline,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const _WaveLabel(),
                ),
              ),
              SizedBox(
                width: 56,
                height: 44,
                child: TextButton(
                  key: const Key('match-skip'),
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.matchMutedText,
                    padding: EdgeInsets.zero,
                  ),
                  child: const _SkipLabel(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SayHiLabel extends StatelessWidget {
  const _SayHiLabel();
  @override
  Widget build(BuildContext context) => Text(
        AppLocalizations.of(context)!.matchSayHi,
        style: const TextStyle(fontWeight: FontWeight.w700),
      );
}

class _WaveLabel extends StatelessWidget {
  const _WaveLabel();
  @override
  Widget build(BuildContext context) =>
      Text('\u{1F44B} ${AppLocalizations.of(context)!.wave}');
}

class _SkipLabel extends StatelessWidget {
  const _SkipLabel();
  @override
  Widget build(BuildContext context) =>
      Text(AppLocalizations.of(context)!.skip);
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});
  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
          color: AppColors.matchChipSurface,
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.matchInk,
            ),
          ),
        );
    return ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
        child: (url != null && url!.isNotEmpty)
            ? CachedImageWidget(
                imageUrl: url!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: fallback(),
              )
            : fallback(),
      ),
    );
  }
}
