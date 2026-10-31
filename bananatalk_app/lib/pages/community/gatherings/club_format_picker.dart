import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Clubs v2 slice 4: where the club meets, and whether new members are
/// approved. In person always approves, so the switch is locked on there.
class ClubFormatPicker extends StatelessWidget {
  const ClubFormatPicker({
    super.key,
    required this.format,
    required this.joinApproval,
    required this.onChanged,
  });

  final String format;
  final bool joinApproval;
  final void Function(String format, bool joinApproval) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offline = format == 'offline';
    return Column(
      key: const Key('club-format-picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.clubFormatLabel, style: context.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'online', label: Text(l10n.clubFormatOnline), icon: const Icon(Icons.wifi_rounded)),
            ButtonSegment(value: 'offline', label: Text(l10n.clubFormatOffline), icon: const Icon(Icons.place_outlined)),
          ],
          selected: {format},
          onSelectionChanged: (s) => onChanged(s.first, joinApproval),
        ),
        SwitchListTile(
          key: const Key('club-approval-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.clubApprovalToggle),
          subtitle: offline ? Text(l10n.clubApprovalOfflineHint) : null,
          value: offline || joinApproval,
          onChanged: offline ? null : (v) => onChanged(format, v),
        ),
      ],
    );
  }
}
