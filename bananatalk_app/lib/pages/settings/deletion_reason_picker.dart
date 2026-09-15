import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// The reason codes the server accepts, in display order.
///
/// Mirrors DELETION_REASONS in the backend's lib/deletionReason.js. Kept in
/// step deliberately: an unknown code is recorded there as 'other' rather than
/// rejected, so a mismatch loses signal quietly instead of breaking a
/// deletion — which is exactly the kind of drift a test should catch and a
/// user should never feel.
const List<String> kDeletionReasons = [
  'no_people',
  'no_content',
  'not_useful',
  'bugs',
  'notifications',
  'privacy',
  'other',
];

/// Matches MAX_REASON_TEXT on the server, so text is never silently truncated
/// after the user has typed it.
const int kDeletionReasonMaxLength = 280;

/// An optional "why are you leaving?" prompt on the account deletion screen.
///
/// ~130 accounts a month are deleted deliberately — about 17% of signups, most
/// within an hour of signing up — and nothing recorded why.
///
/// It asks once, it never blocks, and it never argues. Nothing is preselected,
/// no answer is required, tapping a chosen reason again clears it, and the
/// delete button behaves identically whether or not anything is chosen. A user
/// who has decided to leave is owed a door, not a survey.
class DeletionReasonPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String> onTextChanged;

  const DeletionReasonPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onTextChanged,
  });

  String _label(AppLocalizations l10n, String code) {
    switch (code) {
      case 'no_people':
        return l10n.deletionReasonNoPeople;
      case 'no_content':
        return l10n.deletionReasonNoContent;
      case 'not_useful':
        return l10n.deletionReasonNotUseful;
      case 'bugs':
        return l10n.deletionReasonBugs;
      case 'notifications':
        return l10n.deletionReasonNotifications;
      case 'privacy':
        return l10n.deletionReasonPrivacy;
      default:
        return l10n.deletionReasonOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.deletionReasonTitle,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.deletionReasonOptional,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kDeletionReasons.map((code) {
            final isSelected = selected == code;
            return ChoiceChip(
              key: Key('deletion-reason-$code'),
              label: Text(_label(l10n, code)),
              selected: isSelected,
              // Re-tapping clears it: an answer given by accident, on the way
              // out of the product, must be retractable.
              onSelected: (_) => onChanged(isSelected ? null : code),
              selectedColor: AppColors.error.withValues(alpha: 0.15),
            );
          }).toList(),
        ),
        if (selected == 'other') ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('deletion-reason-text'),
            maxLength: kDeletionReasonMaxLength,
            maxLines: 3,
            minLines: 2,
            onChanged: onTextChanged,
            decoration: InputDecoration(
              hintText: l10n.deletionReasonHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}
