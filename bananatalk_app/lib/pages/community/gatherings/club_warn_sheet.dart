import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_rules.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// What the organizer chose in [showClubWarnSheet].
typedef ClubWarning = ({String rule, String? note});

/// Clubs v2: warn [member], citing one of [club]'s rules (or "Other", typed).
/// Returns null when dismissed.
Future<ClubWarning?> showClubWarnSheet(
  BuildContext context, {
  required Club club,
  required ClubMember member,
}) {
  return showModalBottomSheet<ClubWarning>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ClubWarnSheet(club: club, member: member),
  );
}

class _ClubWarnSheet extends StatefulWidget {
  const _ClubWarnSheet({required this.club, required this.member});

  final Club club;
  final ClubMember member;

  @override
  State<_ClubWarnSheet> createState() => _ClubWarnSheetState();
}

class _ClubWarnSheetState extends State<_ClubWarnSheet> {
  /// Index into the club's rules, or -1 for "Other".
  int? _picked;
  final _other = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _rule => _picked == null
      ? ''
      : _picked! < 0
          ? _other.text.trim()
          : widget.club.rules[_picked!];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rules = widget.club.rules;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.lg, Spacing.lg, Spacing.lg,
        MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.clubWarnTitle(widget.member.name), style: context.titleLarge),
            Spacing.gapSM,
            Text(l10n.clubWarnPickRule, style: context.bodyMedium),
            for (var i = 0; i < rules.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: _picked,
                title: Text(rules[i]),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _picked = v),
              ),
            RadioListTile<int>(
              value: -1,
              groupValue: _picked,
              title: Text(l10n.clubWarnOtherRule),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _picked = v),
            ),
            if (_picked == -1)
              TextField(
                key: const Key('club-warn-other'),
                controller: _other,
                maxLength: kMaxClubRuleLength,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: l10n.clubRuleHint),
              ),
            Spacing.gapSM,
            TextField(
              key: const Key('club-warn-note'),
              controller: _note,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.clubWarnNoteLabel),
            ),
            Spacing.gapMD,
            FilledButton(
              key: const Key('club-warn-send'),
              onPressed: _rule.isEmpty
                  ? null
                  : () => Navigator.pop<ClubWarning>(context, (
                        rule: _rule,
                        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                      )),
              child: Text(l10n.clubWarnSend),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clubs v2: "Remove now" for serious cases. The reason is required and goes
/// to the admin queue. Returns the reason, or null when dismissed.
Future<String?> showClubRemoveNowSheet(BuildContext context, {required String name}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RemoveNowSheet(name: name),
  );
}

class _RemoveNowSheet extends StatefulWidget {
  const _RemoveNowSheet({required this.name});

  final String name;

  @override
  State<_RemoveNowSheet> createState() => _RemoveNowSheetState();
}

class _RemoveNowSheetState extends State<_RemoveNowSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = _reason.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.lg, Spacing.lg, Spacing.lg,
        MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.clubRemoveReasonTitle(widget.name), style: context.titleLarge),
          Spacing.gapSM,
          Text(l10n.clubRemoveAfterWarningsBody, style: context.bodySmall),
          Spacing.gapMD,
          TextField(
            key: const Key('club-remove-now-reason'),
            controller: _reason,
            maxLength: 500,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.clubRemoveReasonHint),
          ),
          Spacing.gapMD,
          FilledButton(
            key: const Key('club-remove-now-confirm'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: reason.isEmpty ? null : () => Navigator.pop(context, reason),
            child: Text(l10n.clubRemoveMember),
          ),
        ],
      ),
    );
  }
}
