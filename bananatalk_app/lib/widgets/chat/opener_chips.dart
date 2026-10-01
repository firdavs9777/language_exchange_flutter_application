import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// Conversation starters shown in an empty chat. Tapping a chip only hands
/// the text to [onPick] (the caller fills the composer) -- never auto-sends.
class OpenerChips extends StatelessWidget {
  const OpenerChips({
    super.key,
    required this.me,
    required this.partner,
    required this.onPick,
  });

  final Community me;
  final Community partner;
  final ValueChanged<String> onPick;

  static String _norm(String s) => s.trim().toLowerCase();

  /// Pure opener selection: reciprocal pair, first shared topic, generic.
  /// Max 3, no duplicates, rules with missing inputs are skipped.
  static List<String> buildOpeners(
    AppLocalizations l10n,
    Community me,
    Community partner,
  ) {
    final out = <String>[];
    void add(String s) {
      if (out.length < 3 && !out.contains(s)) out.add(s);
    }

    final myNative = me.native_language.trim();
    final myLearn = me.language_to_learn.trim();
    final theirNative = partner.native_language.trim();
    final theirLearn = partner.language_to_learn.trim();

    if (myNative.isNotEmpty &&
        myLearn.isNotEmpty &&
        _norm(myNative) == _norm(theirLearn) &&
        _norm(myLearn) == _norm(theirNative)) {
      add(l10n.openerReciprocal(theirNative, myNative));
    }

    final theirTopics = {for (final t in partner.topics) _norm(t)};
    for (final t in me.topics) {
      if (t.trim().isNotEmpty && theirTopics.contains(_norm(t))) {
        add(l10n.openerSharedTopic(t.trim()));
        break;
      }
    }

    final name = partner.name.trim();
    if (name.isNotEmpty && theirNative.isNotEmpty) {
      add(l10n.openerGeneric(name, theirNative));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final openers = buildOpeners(l10n, me, partner);
    if (openers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.openerChipsTitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.matchMutedText,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < openers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: i == 0
                    ? AppColors.matchReasonTint
                    : AppColors.matchChipSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: i == 0
                        ? AppColors.matchReasonText
                        : AppColors.matchHairline,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onPick(openers[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        openers[i],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.matchInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
