import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/block_user_dialog.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';

/// Which kind of thing is being reported. The string values are sent to the
/// backend verbatim and must stay inside `models/Report.js`'s `type` enum,
/// which already accepts both.
enum SafetyTarget {
  gathering('gathering'),
  club('club');

  const SafetyTarget(this.wireValue);
  final String wireValue;
}

/// Report-or-block overflow menu for a gathering or a club.
///
/// ONE widget used by both detail screens rather than two parallel copies,
/// because the recurring defect in this codebase is two hand-maintained lists
/// drifting apart.
///
/// Gatherings are where people arrange to meet IN PERSON, which makes this the
/// highest-stakes safety surface in the app — and it shipped without any way to
/// report the event or its host. The backend has accepted `gathering` and
/// `club` reports the whole time; only the UI was missing.
///
/// Renders nothing for the owner: reporting or blocking yourself is not a
/// thing, and an owner already has edit and cancel controls.
class GatheringSafetyMenu extends StatefulWidget {
  const GatheringSafetyMenu({
    super.key,
    required this.target,
    required this.contentId,
    required this.hostId,
    required this.hostName,
    required this.viewerIsOwner,
  });

  final SafetyTarget target;
  final String contentId;
  final String hostId;
  final String hostName;
  final bool viewerIsOwner;

  @override
  State<GatheringSafetyMenu> createState() => _GatheringSafetyMenuState();
}

class _GatheringSafetyMenuState extends State<GatheringSafetyMenu> {
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('userId') ?? '';
      if (mounted) setState(() => _currentUserId = id);
    } catch (e) {
      // Blocking needs the viewer's own id. Without it the block entry stays
      // hidden, but reporting — which does not need it — still works.
      debugPrint('[GatheringSafetyMenu] could not read userId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewerIsOwner) return const SizedBox.shrink();
    if (widget.hostId.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final canBlock =
        _currentUserId.isNotEmpty && _currentUserId != widget.hostId;

    return PopupMenuButton<String>(
      key: const Key('gathering-safety-menu'),
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'report',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: Text(widget.target == SafetyTarget.gathering
                ? l10n.reportGathering
                : l10n.reportClub),
          ),
        ),
        if (canBlock)
          PopupMenuItem<String>(
            value: 'block',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text(l10n.blockUser),
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'report') {
          showDialog<void>(
            context: context,
            builder: (context) => ReportDialog(
              type: widget.target.wireValue,
              reportedId: widget.contentId,
              // The host answers for the event they created.
              reportedUserId: widget.hostId,
            ),
          );
        } else if (value == 'block') {
          BlockUserDialog.show(
            context: context,
            currentUserId: _currentUserId,
            targetUserId: widget.hostId,
            targetUserName: widget.hostName,
          );
        }
      },
    );
  }
}
