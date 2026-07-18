// lib/pages/community/rooms/room_members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/chat/header/user_avatar.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Hub member list — Workstream D (Task 11), moderation wired up in Task 16
/// (client layer C).
///
/// Owner/admin-only moderation actions (remove/mute) are gated on
/// `room.isOwnerOrAdmin`. On a topic room, "Remove" is a kick-as-ban: the
/// backend atomically removes the member and adds them to `bannedUsers`, so
/// they can't silently rejoin — they must `requestJoin` and get re-approved
/// (Task 16). Hubs have no ban concept, so removal there is a plain kick.
/// The room owner can never be removed — the trailing menu simply omits the
/// "Remove" item for their row (mirrors the backend's `canKickMember` gate).
class RoomMembersScreen extends ConsumerStatefulWidget {
  const RoomMembersScreen({super.key, required this.room});

  final Room room;

  @override
  ConsumerState<RoomMembersScreen> createState() => _RoomMembersScreenState();
}

class _RoomMembersScreenState extends ConsumerState<RoomMembersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(roomApiClientProvider);
      final members = await apiClient.getMembers(widget.room.id);
      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AppLocalizations.of(context)!.roomMembersLoadError;
      });
    }
  }

  String _memberId(Map<String, dynamic> member) =>
      (member['_id'] ?? member['id'] ?? member['userId'])?.toString() ?? '';

  String _memberName(Map<String, dynamic> member) =>
      member['name']?.toString() ??
      AppLocalizations.of(context)!.roomMemberFallbackName;

  String? _memberPicture(Map<String, dynamic> member) {
    final images = member['imageUrls'] ?? member['images'];
    if (images is List && images.isNotEmpty) return images.first?.toString();
    return member['profilePicture']?.toString();
  }

  bool _memberMuted(Map<String, dynamic> member) => member['muted'] == true;

  /// The owner can never be kicked (server-enforced too, via
  /// `canKickMember` — this is a client-side mirror so the option never
  /// even appears).
  bool _isOwner(Map<String, dynamic> member) =>
      widget.room.ownerId != null && _memberId(member) == widget.room.ownerId;

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final userId = _memberId(member);
    if (userId.isEmpty || _isOwner(member)) return;
    final isTopicRoom = widget.room.isTopicRoom;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTopicRoom ? l10n.roomRemoveBanTitle : l10n.roomRemoveTitle),
        content: Text(
          isTopicRoom
              ? l10n.roomRemoveBanConfirm(_memberName(member))
              : l10n.roomRemoveConfirm(_memberName(member), widget.room.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isTopicRoom ? l10n.roomRemoveBanButton : l10n.roomRemoveButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final apiClient = ref.read(roomApiClientProvider);
    final ok = await apiClient.removeMember(widget.room.id, userId);
    if (!mounted) return;
    if (ok) {
      setState(() => _members.removeWhere((m) => _memberId(m) == userId));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (isTopicRoom ? l10n.roomMemberRemovedBanned : l10n.roomMemberRemoved)
              : l10n.roomMemberRemoveFailed,
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _toggleMute(Map<String, dynamic> member) async {
    final userId = _memberId(member);
    if (userId.isEmpty) return;
    final currentlyMuted = _memberMuted(member);
    final l10n = AppLocalizations.of(context)!;

    final apiClient = ref.read(roomApiClientProvider);
    final ok = await apiClient.muteMember(
      widget.room.id,
      userId,
      muted: !currentlyMuted,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        final idx = _members.indexWhere((m) => _memberId(m) == userId);
        if (idx != -1) {
          _members[idx] = {..._members[idx], 'muted': !currentlyMuted};
        }
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (currentlyMuted ? l10n.roomMemberUnmuted : l10n.roomMemberMuted)
              : l10n.roomMemberMuteFailed,
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canModerate = widget.room.isOwnerOrAdmin;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roomMembersAppBarTitle(widget.room.title)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
                    ],
                  ),
                )
              : _members.isEmpty
                  ? Center(child: Text(l10n.roomMembersEmpty))
                  : ListView.separated(
                      padding: const EdgeInsets.all(Spacing.md),
                      itemCount: _members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final muted = _memberMuted(member);
                        final isOwner = _isOwner(member);
                        return Material(
                          color: context.containerColor,
                          borderRadius: AppRadius.borderMD,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.xs,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMD,
                            ),
                            leading: UserAvatar(
                              profilePicture: _memberPicture(member),
                              userName: _memberName(member),
                              radius: 20,
                            ),
                            title: Text(_memberName(member)),
                            subtitle: muted
                                ? Text(
                                    l10n.roomMemberMutedLabel,
                                    style: const TextStyle(color: AppColors.warning),
                                  )
                                : null,
                            trailing: canModerate
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'remove') {
                                        _removeMember(member);
                                      } else if (value == 'mute') {
                                        _toggleMute(member);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'mute',
                                        child: Text(muted ? l10n.unmute : l10n.mute),
                                      ),
                                      // The owner can never be removed —
                                      // omit the option entirely rather
                                      // than show it disabled.
                                      if (!isOwner)
                                        PopupMenuItem(
                                          value: 'remove',
                                          child: Text(
                                            widget.room.isTopicRoom
                                                ? l10n.roomRemoveBanButton
                                                : l10n.roomRemoveButton,
                                          ),
                                        ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }
}
