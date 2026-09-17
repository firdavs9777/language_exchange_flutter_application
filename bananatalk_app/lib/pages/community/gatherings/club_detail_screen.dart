import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/pages/community/gatherings/create_gathering_form.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_card.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_detail_screen.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_safety_menu.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_people_section.dart';
import 'package:bananatalk_app/pages/community/gatherings/group_cover.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// A club, and what it has coming up.
///
/// A club with nothing scheduled is not a failure state — that is the whole
/// reason the club is the primary entity. "49 members" is true on a quiet
/// week, whereas an event list resets to empty after every event and reads as
/// abandoned.
class ClubDetailScreen extends StatefulWidget {
  const ClubDetailScreen({super.key, required this.clubId, this.apiClient});

  final String clubId;
  final GatheringApiClient? apiClient;

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  late final GatheringApiClient _api = widget.apiClient ?? GatheringApiClient();
  late Future<Club?> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getClub(widget.clubId);
  }

  Future<void> _reload() async {
    final next = _api.getClub(widget.clubId);
    // Block body, not an arrow: `() => _future = next` evaluates to the
    // assigned Future, and setState rejects a callback that returns one.
    setState(() {
      _future = next;
    });
    await next;
  }

  /// Edit name, description, interest and where it meets.
  ///
  /// Language is absent on purpose: it is the discovery spine, and every
  /// member joined a club in a language they chose. Moving it would take a
  /// Korean club away from everyone in it.
  Future<void> _editClub(Club club) async {
    final name = TextEditingController(text: club.name);
    final description = TextEditingController(text: club.description);
    final interest = TextEditingController(text: club.interest);
    final city = TextEditingController(text: club.city ?? '');
    final placeName = TextEditingController(text: club.place?.name ?? '');
    final l10n = AppLocalizations.of(context)!;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.clubEdit,
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                key: const Key('club-edit-name'),
                controller: name,
                decoration: InputDecoration(labelText: l10n.clubNameLabel),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                decoration:
                    InputDecoration(labelText: l10n.clubDescriptionLabel),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: interest,
                decoration: InputDecoration(labelText: l10n.clubInterestLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: city,
                decoration: InputDecoration(labelText: l10n.city),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: placeName,
                decoration: InputDecoration(labelText: l10n.clubPlaceLabel),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('club-edit-save'),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    setState(() => _busy = true);
    final result = await _api.updateClub(
      club.id,
      name: name.text.trim(),
      description: description.text.trim(),
      interest: interest.text.trim(),
      city: city.text.trim(),
      placeName: placeName.text.trim().isEmpty ? null : placeName.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.success) _future = _api.getClub(widget.clubId);
    });
    if (!result.success) {
      showCommunitySnackBar(context, message: result.error ?? '');
    }
  }

  /// Delete, after saying plainly what survives.
  ///
  /// The confirmation names the consequence rather than asking "are you sure":
  /// the scheduled events stay, because people have already said they are
  /// coming and those are commitments between attendees, not the owner's to
  /// cancel by tidying up.
  Future<void> _deleteClub(Club club) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clubDeleteConfirmTitle),
        content: Text(l10n.clubDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('club-delete-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clubDelete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await _api.deleteClub(club.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      Navigator.of(context).pop(true);
    } else {
      showCommunitySnackBar(context, message: result.error ?? '');
    }
  }

  /// Promote, demote or remove — long-pressing a face.
  Future<void> _manageMember(Club club, ClubMember member) async {
    if (member.isOwner) return;
    final l10n = AppLocalizations.of(context)!;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(member.role),
            ),
            const Divider(height: 1),
            // Role changes are the owner's alone: letting organizers appoint
            // organizers compounds one bad appointment beyond what the owner
            // can undo.
            if (club.viewerIsOwner)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(member.isOrganizer
                    ? l10n.clubRemoveOrganizer
                    : l10n.clubMakeOrganizer),
                onTap: () => Navigator.pop(
                    sheetContext, member.isOrganizer ? 'demote' : 'promote'),
              ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
              title: Text(l10n.clubRemoveMember,
                  style: const TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    setState(() => _busy = true);
    final result = action == 'remove'
        ? await _api.removeClubMember(club.id, member.id)
        : await _api.setClubMemberRole(
            club.id,
            member.id,
            role: action == 'promote' ? 'organizer' : 'member',
          );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.success) _future = _api.getClub(widget.clubId);
    });
    if (!result.success) {
      showCommunitySnackBar(context, message: result.error ?? '');
    }
  }

  /// Pick, take or remove the cover photo.
  ///
  /// A failure here never blocks anything: the club is unchanged and the
  /// message says so. Nobody should be unable to run their club because an
  /// upload timed out.
  Future<void> _changeCover(Club club) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.groupCoverFromLibrary),
              onTap: () => Navigator.pop(sheetContext, 'library'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.groupCoverTakePhoto),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            if (club.coverImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(l10n.groupCoverRemove,
                    style: const TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 'remove') {
      setState(() => _busy = true);
      final result = await _api.removeClubCover(club.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (result.success) _future = _api.getClub(widget.clubId);
      });
      if (!result.success) {
        showCommunitySnackBar(context, message: result.error ?? '');
      }
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      // Capped before upload: a modern phone photo is several megabytes and a
      // cover is shown at most a few hundred pixels tall.
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    final result = await _api.uploadClubCover(club.id, File(picked.path));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.success) _future = _api.getClub(widget.clubId);
    });
    if (!result.success) {
      showCommunitySnackBar(context, message: result.error ?? '');
    }
  }

  Future<void> _toggleMembership(Club club) async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = club.viewerIsMember
        ? (await _api.leaveClub(club.id)).error
        : (await _api.joinClub(club.id)).error;
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      showCommunitySnackBar(
        context,
        message: error,
        type: CommunitySnackBarType.error,
      );
      return;
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clubDetailTitle),
        // Same future as the body: a resolved future rebuilds synchronously,
        // so this adds no request. Nothing renders for the owner.
        actions: [
          FutureBuilder<Club?>(
            future: _future,
            builder: (context, snapshot) {
              final club = snapshot.data;
              if (club == null) return const SizedBox.shrink();
              if (club.viewerCanManage) {
                return _ClubOwnerMenu(
                  club: club,
                  onEdit: () => _editClub(club),
                  onDelete: club.viewerIsOwner ? () => _deleteClub(club) : null,
                );
              }
              return GatheringSafetyMenu(
                target: SafetyTarget.club,
                contentId: club.id,
                hostId: club.owner.id,
                hostName: club.owner.name,
                viewerIsOwner: club.viewerIsOwner,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Club?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final club = snapshot.data;
          if (club == null) {
            return CommunityErrorState(
              message: l10n.clubNotFound,
              onRetry: _reload,
            );
          }
          return _body(context, l10n, club);
        },
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, Club club) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacing.xxxl),
        children: [
          // Optional: most clubs will have no photo, and the colour fallback
          // is the designed state rather than an error case.
          GroupCover(
            id: club.id,
            title: club.name,
            imageUrl: club.coverImage,
            onTap: club.viewerCanManage ? () => _changeCover(club) : null,
          ),
          Padding(
            padding: Spacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name, style: context.displaySmall),
                Spacing.gapSM,
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: context.primaryColor,
                    ),
                    Spacing.hGapXS,
                    Text(
                      l10n.clubMembers(club.memberCount),
                      style: context.bodyMedium.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (club.displayLanguage.isNotEmpty) ...[
                      Spacing.hGapSM,
                      Text('·', style: context.bodyMedium),
                      Spacing.hGapSM,
                      Flexible(
                        child: Text(
                          club.interest.isEmpty
                              ? club.displayLanguage
                              : '${club.displayLanguage} · ${club.interest}',
                          style: context.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (club.description.isNotEmpty) ...[
                  Spacing.gapMD,
                  Text(club.description, style: context.bodyMedium),
                ],
                // Where it meets and how often it actually has. Both were
                // stored on the server model since it was written and never
                // sent, so a club that meets every Saturday in Hapjeong looked
                // identical to one that has never met at all.
                if (club.city != null ||
                    club.place != null ||
                    club.pastCount > 0) ...[
                  Spacing.gapMD,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (club.city != null)
                        _ClubFact(
                          key: const Key('club-city'),
                          icon: Icons.place_outlined,
                          label: club.place?.name != null
                              ? '${club.place!.name} · ${club.city}'
                              : l10n.clubMeetsIn(club.city!),
                        ),
                      _ClubFact(
                        key: const Key('club-history'),
                        icon: Icons.history_rounded,
                        label: club.pastCount > 0
                            ? l10n.clubEventsHeld(club.pastCount)
                            : l10n.clubNoEventsHeld,
                      ),
                    ],
                  ),
                ],
                Spacing.gapLG,
                if (!club.viewerIsOwner)
                  SizedBox(
                    width: double.infinity,
                    child: club.viewerIsMember
                        ? OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _toggleMembership(club),
                            child: Text(l10n.clubLeave),
                          )
                        : FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _toggleMembership(club),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: Spacing.md,
                              ),
                            ),
                            child: Text(l10n.clubJoin),
                          ),
                  ),
              ],
            ),
          ),

          ClubPeopleSection(
            club: club,
            onMemberLongPress: club.viewerCanManage
                ? (member) => _manageMember(club, member)
                : null,
          ),
          Spacing.gapLG,

          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Text(l10n.clubUpcoming, style: context.titleMedium),
          ),

          if (club.gatherings.isEmpty)
            Padding(
              padding: Spacing.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clubNothingScheduled,
                    style: context.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  // Only members may host for a club — the backend refuses
                  // otherwise, and for a good reason: anyone could otherwise
                  // hang a gathering off a 586-member club and borrow its
                  // audience.
                  if (club.viewerIsMember) ...[
                    Spacing.gapLG,
                    CreateGatheringForm(
                      compact: true,
                      clubId: club.id,
                      defaultLanguage: club.displayLanguage,
                      onCreated: (_) => _reload(),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            ...club.gatherings.map(
              (g) => GatheringCard(
                gathering: g,
                onTap: () async {
                  await Navigator.of(context).push(
                    AppPageRoute(
                      builder: (_) => GatheringDetailScreen(gatheringId: g.id),
                    ),
                  );
                  await _reload();
                },
              ),
            ),
            if (club.viewerIsMember)
              Padding(
                padding: Spacing.paddingLG,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final created = await showCreateGatheringSheet(
                      context,
                      defaultLanguage: club.displayLanguage,
                      clubId: club.id,
                    );
                    if (created != null) await _reload();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.clubHostGathering),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// One fact about the club — where it meets, how often it has.
class _ClubFact extends StatelessWidget {
  const _ClubFact({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.captionSmall.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Edit and delete, for whoever may use them.
///
/// Delete is owner-only and simply absent for an organizer — a disabled entry
/// would invite a tap that can only ever fail.
class _ClubOwnerMenu extends StatelessWidget {
  const _ClubOwnerMenu({
    required this.club,
    required this.onEdit,
    this.onDelete,
  });

  final Club club;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      key: const Key('club-owner-menu'),
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.clubEdit),
          ),
        ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                l10n.clubDelete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
      ],
    );
  }
}
