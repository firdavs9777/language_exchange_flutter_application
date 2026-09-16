import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The intent values the server accepts, in display order.
///
/// Kept in one place so the picker, the chips and any future surface cannot
/// drift from `lib/matchIntent.js`'s enum.
const kIntentLearn = 'learn';
const kIntentMeet = 'meet';
const kIntentDate = 'date';
const kIntents = <String>[kIntentLearn, kIntentMeet, kIntentDate];

/// Multi-select, because "learn and meet" is the honest answer for most
/// language-exchange users. Forcing one choice collects the safest answer
/// rather than the true one, and the safest answer carries no signal.
///
/// Dating is offered here but never rendered on anyone else's profile — the
/// server strips it from every response about another user. The note under the
/// options says so, because a privacy promise the user cannot see is one they
/// cannot act on.
class IntentEdit extends StatelessWidget {
  const IntentEdit({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showDate = true,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// False for under-18 accounts. The server strips `date` regardless; hiding
  /// the option means a minor is never shown a choice that would be discarded.
  final bool showDate;

  String _label(AppLocalizations l10n, String intent) => switch (intent) {
    kIntentLearn => l10n.intentLearn,
    kIntentMeet => l10n.intentMeet,
    _ => l10n.intentDate,
  };

  IconData _icon(String intent) => switch (intent) {
    kIntentLearn => Icons.school_rounded,
    kIntentMeet => Icons.people_alt_rounded,
    _ => Icons.favorite_rounded,
  };

  void _toggle(String intent) {
    final next = List<String>.from(selected);
    next.contains(intent) ? next.remove(intent) : next.add(intent);
    // Sorted into the canonical order so the stored value does not depend on
    // the order the user happened to tap.
    next.sort((a, b) => kIntents.indexOf(a).compareTo(kIntents.indexOf(b)));
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = showDate
        ? kIntents
        : kIntents.where((i) => i != kIntentDate).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.intentSectionTitle,
          style: context.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final intent in options)
              FilterChip(
                key: Key('intent-$intent'),
                selected: selected.contains(intent),
                onSelected: (_) => _toggle(intent),
                avatar: Icon(
                  _icon(intent),
                  size: 16,
                  color: selected.contains(intent)
                      ? AppColors.primary
                      : context.textSecondary,
                ),
                label: Text(_label(l10n, intent)),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.intentPrivacyNote,
          style: context.captionSmall.copyWith(color: context.textMuted),
        ),
      ],
    );
  }
}

/// The intents that may be shown on someone else's profile.
///
/// `date` is removed here as well as on the server. Two layers, because a
/// public "open to dating" badge is a harassment vector and one filter is a
/// single careless edit away from being bypassed.
List<String> publicIntents(List<String> intents) =>
    intents.where((i) => i == kIntentLearn || i == kIntentMeet).toList();
