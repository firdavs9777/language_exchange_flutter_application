// lib/pages/community/rooms/room_members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/chat/header/user_avatar.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Hub member list — Workstream D (Task 11).
///
/// Owner/admin-only moderation actions (remove/mute) are gated on
/// `room.isOwnerOrAdmin`, which the backend hasn't wired up yet (its
/// moderation endpoints are a later phase of this workstream) — until then
/// this defaults to `false` and the screen is a read-only member list for
/// everyone, which is a safe fallback rather than exposing controls to the
/// wrong users.
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
        _error = 'Could not load members';
      });
    }
  }

  String _memberId(Map<String, dynamic> member) =>
      (member['_id'] ?? member['id'] ?? member['userId'])?.toString() ?? '';

  String _memberName(Map<String, dynamic> member) =>
      member['name']?.toString() ?? 'Member';

  String? _memberPicture(Map<String, dynamic> member) {
    final images = member['imageUrls'] ?? member['images'];
    if (images is List && images.isNotEmpty) return images.first?.toString();
    return member['profilePicture']?.toString();
  }

  bool _memberMuted(Map<String, dynamic> member) => member['muted'] == true;

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final userId = _memberId(member);
    if (userId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${_memberName(member)} from ${widget.room.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
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
        content: Text(ok ? 'Member removed' : 'Failed to remove member'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _toggleMute(Map<String, dynamic> member) async {
    final userId = _memberId(member);
    if (userId.isEmpty) return;
    final currentlyMuted = _memberMuted(member);

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
              ? (currentlyMuted ? 'Member unmuted' : 'Member muted')
              : 'Failed to update mute status',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canModerate = widget.room.isOwnerOrAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.room.title} · Members'),
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
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _members.isEmpty
                  ? const Center(child: Text('No members to show yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(Spacing.md),
                      itemCount: _members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final muted = _memberMuted(member);
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
                                ? const Text(
                                    'Muted',
                                    style: TextStyle(color: AppColors.warning),
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
                                        child: Text(muted ? 'Unmute' : 'Mute'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'remove',
                                        child: Text('Remove'),
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
