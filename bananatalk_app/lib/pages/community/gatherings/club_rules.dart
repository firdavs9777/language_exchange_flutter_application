import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Clubs v2: at most this many rules (the server refuses more).
const int kMaxClubRules = 10;

/// Clubs v2: one rule is at most this long (the server refuses longer).
const int kMaxClubRuleLength = 200;

/// The rules a new club starts with, in the creator's language. The owner can
/// edit or delete any of them.
List<String> defaultClubRules(AppLocalizations l10n) => [
      l10n.clubRuleRespect,
      l10n.clubRuleBothLanguages,
      l10n.clubRuleNoSelling,
      l10n.clubRuleReleaseSeat,
    ];

/// "English ↔ Korean" when the club has a pair, else its one language.
String clubLanguageLine(Club club, {required bool clubsV2}) {
  final second = club.secondLanguageLabel.isNotEmpty
      ? club.secondLanguageLabel
      : (club.secondLanguage ?? '');
  if (!clubsV2 || second.isEmpty) return club.displayLanguage;
  return '${club.displayLanguage} ↔ $second';
}

/// Edits a club's rules: one field per rule, delete per row, "Add a rule" up
/// to [kMaxClubRules]. Reports the non-empty, trimmed rules on every change.
class ClubRulesEditor extends StatefulWidget {
  const ClubRulesEditor({
    super.key,
    required this.initialRules,
    required this.onChanged,
  });

  final List<String> initialRules;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ClubRulesEditor> createState() => _ClubRulesEditorState();
}

class _ClubRulesEditorState extends State<ClubRulesEditor> {
  late final List<TextEditingController> _rows = widget.initialRules
      .take(kMaxClubRules)
      .map((r) => TextEditingController(text: r))
      .toList();

  @override
  void dispose() {
    for (final c in _rows) {
      c.dispose();
    }
    super.dispose();
  }

  void _report() => widget.onChanged(
        _rows.map((c) => c.text.trim()).where((r) => r.isNotEmpty).toList(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.clubRulesTitle, style: context.titleSmall),
        Spacing.gapSM,
        for (var i = 0; i < _rows.length; i++)
          Padding(
            key: ObjectKey(_rows[i]),
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('club-rule-$i'),
                    controller: _rows[i],
                    maxLength: kMaxClubRuleLength,
                    onChanged: (_) => _report(),
                    decoration: InputDecoration(
                      hintText: l10n.clubRuleHint,
                      counterText: '',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: AppRadius.borderMD),
                    ),
                  ),
                ),
                IconButton(
                  key: Key('club-rule-delete-$i'),
                  tooltip: l10n.delete,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() => _rows.removeAt(i).dispose());
                    _report();
                  },
                ),
              ],
            ),
          ),
        if (_rows.length < kMaxClubRules)
          TextButton.icon(
            key: const Key('club-rule-add'),
            onPressed: () => setState(() => _rows.add(TextEditingController())),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.clubRuleAdd),
          ),
      ],
    );
  }
}

/// The club's rules, numbered, as people see them before joining.
class ClubRulesList extends StatelessWidget {
  const ClubRulesList({super.key, required this.rules});

  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const Key('club-rules'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.clubRulesTitle, style: context.titleSmall),
        Spacing.gapXS,
        for (var i = 0; i < rules.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Text('${i + 1}. ${rules[i]}', style: context.bodyMedium),
          ),
      ],
    );
  }
}
