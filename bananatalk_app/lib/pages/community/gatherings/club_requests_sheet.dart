import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Clubs v2 slice 4: who is asking to join, with what a host needs to decide
/// (languages, meetups attended), and Approve / Deny for each.
Future<void> showClubRequestsSheet(
  BuildContext context, {
  required String clubId,
  required GatheringApiClient api,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ClubRequestsSheet(clubId: clubId, api: api),
  );
}

class _ClubRequestsSheet extends StatefulWidget {
  const _ClubRequestsSheet({required this.clubId, required this.api});

  final String clubId;
  final GatheringApiClient api;

  @override
  State<_ClubRequestsSheet> createState() => _ClubRequestsSheetState();
}

class _ClubRequestsSheetState extends State<_ClubRequestsSheet> {
  List<ClubJoinRequest>? _requests;
  bool _failed = false;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.api.getClubJoinRequests(widget.clubId);
    if (!mounted) return;
    setState(() {
      _requests = list;
      _failed = list == null;
    });
  }

  Future<void> _decide(ClubJoinRequest r, bool approve) async {
    setState(() => _busy.add(r.userId));
    final ok = await widget.api.decideClubJoinRequest(widget.clubId, r.userId, approve: approve);
    if (!mounted) return;
    setState(() {
      _busy.remove(r.userId);
      if (ok) _requests = _requests?.where((x) => x.userId != r.userId).toList();
    });
    if (!ok) {
      showCommunitySnackBar(context,
          message: AppLocalizations.of(context)!.clubMemberUpdateFailed,
          type: CommunitySnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requests = _requests;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.gatheringRequests(requests?.length ?? 0), style: context.titleMedium),
            const SizedBox(height: 8),
            if (requests == null && !_failed)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_failed)
              Text(l10n.clubMemberUpdateFailed, style: context.bodyMedium)
            else if (requests!.isEmpty)
              Text(l10n.clubRequestsEmpty, style: context.bodyMedium)
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in requests)
                      ListTile(
                        key: Key('club-request-${r.userId}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.name),
                        subtitle: Text([
                          if (r.nativeLanguage.isNotEmpty || r.learningLanguage.isNotEmpty)
                            '${r.nativeLanguage} → ${r.learningLanguage}',
                          l10n.clubRequestMeetups(r.meetupsAttended),
                        ].join('\n')),
                        isThreeLine: true,
                        trailing: _busy.contains(r.userId)
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(onPressed: () => _decide(r, false), child: Text(l10n.gatheringDeny)),
                                  FilledButton(onPressed: () => _decide(r, true), child: Text(l10n.clubApprove)),
                                ],
                              ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
