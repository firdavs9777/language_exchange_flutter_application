import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/admin_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:intl/intl.dart';

/// Step 15 F3 — admin user detail screen.
///
/// Loads the admin-view detail (rich user card + recent audit log
/// entries targeting this user). Surfaces destructive actions —
/// ban / unban / promote / demote — each behind a confirmation
/// dialog with a required-reason TextField.
///
/// Self-actions (banning yourself, demoting yourself) are hidden
/// at the button level — defense-in-depth matching the server-side
/// 403 from controllers/admin.js.
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isActionInFlight = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _adminService.getUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _user = result['data'] as Map<String, dynamic>;
      } else {
        _error = result['error']?.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?['name']?.toString() ?? 'User'),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.person_outlined),
              tooltip: 'View public profile',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileWrapper(userId: widget.userId),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final user = _user;
    if (user == null) {
      return const Center(child: Text('User not found.'));
    }

    final currentUser = ref.watch(userProvider).valueOrNull;
    final isSelf = currentUser?.id == widget.userId;
    final isBanned = user['isBanned'] == true;
    final role = user['role']?.toString() ?? 'user';
    final recentActions = (user['recentActions'] as List?) ?? [];
    final activity = user['activitySummary'] as Map?;

    return ListView(
      padding: Spacing.paddingLG,
      children: [
        _buildUserCard(user),
        const SizedBox(height: 16),
        if (activity != null) ...[
          _buildActivityCard(activity),
          const SizedBox(height: 16),
        ],
        _buildActionsSection(user, isSelf: isSelf, isBanned: isBanned, role: role),
        const SizedBox(height: 24),
        if (recentActions.isNotEmpty) ...[
          const Text(
            'Recent actions on this user',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...recentActions.map((a) => _ActionRow(action: a as Map<String, dynamic>)),
        ],
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? '(unknown)';
    final email = user['email']?.toString();
    final username = user['username']?.toString();
    final native = user['native_language']?.toString();
    final learning = user['language_to_learn']?.toString();
    final loc = user['location'] is Map ? user['location'] as Map : null;
    final city = loc?['city']?.toString();
    final country = loc?['country']?.toString();
    final createdAt = user['createdAt']?.toString();
    final lastActive = user['lastActive']?.toString();
    final isBanned = user['isBanned'] == true;
    final banReason = user['banReason']?.toString();
    final bannedAt = user['bannedAt']?.toString();
    final role = user['role']?.toString() ?? 'user';
    final userMode = user['userMode']?.toString();
    final vipActive = user['vipSubscription']?['isActive'] == true;

    final List<String> imgList = [
      ...((user['imageUrls'] is List)
          ? List<String>.from(user['imageUrls']).whereType<String>()
          : const <String>[]),
      ...((user['images'] is List)
          ? List<String>.from(user['images']).whereType<String>()
          : const <String>[]),
    ];
    final avatarUrl = imgList.firstWhere(
      (u) => u.isNotEmpty && u.startsWith('http'),
      orElse: () => '',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isBanned) _Pill(text: 'BANNED', color: AppColors.error),
                        if (role == 'admin')
                          const _Pill(text: 'ADMIN', color: Color(0xFF9C27B0)),
                        if (vipActive)
                          _Pill(text: 'VIP', color: AppColors.secondary),
                      ],
                    ),
                    if (username != null && username.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(color: context.textMuted),
                      ),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(color: context.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Field(label: 'Role', value: role),
          if (userMode != null) _Field(label: 'Mode', value: userMode),
          if (native != null && native.isNotEmpty)
            _Field(
              label: 'Language',
              value: learning != null && learning.isNotEmpty
                  ? '$native → $learning'
                  : native,
            ),
          if (city != null || country != null)
            _Field(
              label: 'Location',
              value:
                  [city, country].where((x) => x != null && x!.isNotEmpty).join(', '),
            ),
          if (createdAt != null && createdAt.isNotEmpty)
            _Field(label: 'Joined', value: _formatDate(createdAt)),
          if (lastActive != null && lastActive.isNotEmpty)
            _Field(label: 'Last active', value: _formatDate(lastActive)),
          if (isBanned) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banned ${bannedAt != null ? _formatDate(bannedAt) : ""}',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (banReason != null && banReason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: $banReason',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map activity) {
    final lastMsg = activity['lastMessageAt']?.toString();
    final msgs30d = (activity['messagesLast30d'] as num?)?.toInt() ?? 0;
    final lastMoment = activity['lastMomentAt']?.toString();
    final moments30d = (activity['momentsLast30d'] as num?)?.toInt() ?? 0;

    String rel(String? iso) {
      if (iso == null) return 'never';
      try {
        final dt = DateTime.parse(iso).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) return 'just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        if (diff.inDays < 30) return '${diff.inDays}d ago';
        return DateFormat('MMM d, yyyy').format(dt);
      } catch (_) {
        return '—';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity (last 30 days)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActivityStat(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                label: 'Messages',
                value: msgs30d.toString(),
                sub: 'last: ${rel(lastMsg)}',
              ),
              const SizedBox(width: 10),
              _ActivityStat(
                icon: Icons.photo_library_outlined,
                color: const Color(0xFFFF6D00),
                label: 'Moments',
                value: moments30d.toString(),
                sub: 'last: ${rel(lastMoment)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
    Map<String, dynamic> user, {
    required bool isSelf,
    required bool isBanned,
    required String role,
  }) {
    if (isSelf) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "You can't take admin actions on your own account.",
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isBanned)
          _ActionButton(
            label: 'Ban user',
            icon: Icons.block_rounded,
            color: AppColors.error,
            enabled: !_isActionInFlight,
            onTap: () => _handleBan(),
          ),
        if (isBanned)
          _ActionButton(
            label: 'Unban user',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            enabled: !_isActionInFlight,
            onTap: () => _handleUnban(),
          ),
        const SizedBox(height: 10),
        if (role == 'user')
          _ActionButton(
            label: 'Promote to admin',
            icon: Icons.upgrade_rounded,
            color: const Color(0xFF9C27B0),
            enabled: !_isActionInFlight,
            onTap: () => _handleRoleChange('admin'),
          ),
        if (role == 'admin')
          _ActionButton(
            label: 'Revoke admin role',
            icon: Icons.remove_moderator_outlined,
            color: const Color(0xFF9C27B0),
            enabled: !_isActionInFlight,
            onTap: () => _handleRoleChange('user'),
          ),
      ],
    );
  }

  Future<void> _handleBan() async {
    final reason = await _showReasonDialog(
      title: 'Ban user',
      hint: 'Reason for banning (required)',
      confirmLabel: 'Ban',
      confirmColor: AppColors.error,
    );
    if (reason == null) return;
    setState(() => _isActionInFlight = true);
    final result = await _adminService.banUser(widget.userId, reason);
    if (!mounted) return;
    setState(() => _isActionInFlight = false);
    _showResultSnack(result, successText: 'User banned');
    if (result['success'] == true) {
      AnalyticsService.instance.adminActionTaken(
        action: 'user_banned',
        targetUserId: widget.userId,
      );
      await _load();
    }
  }

  Future<void> _handleUnban() async {
    final reason = await _showReasonDialog(
      title: 'Unban user',
      hint: 'Reason for unbanning (required)',
      confirmLabel: 'Unban',
      confirmColor: AppColors.success,
    );
    if (reason == null) return;
    setState(() => _isActionInFlight = true);
    final result = await _adminService.unbanUser(widget.userId, reason);
    if (!mounted) return;
    setState(() => _isActionInFlight = false);
    _showResultSnack(result, successText: 'User unbanned');
    if (result['success'] == true) {
      AnalyticsService.instance.adminActionTaken(
        action: 'user_unbanned',
        targetUserId: widget.userId,
      );
      await _load();
    }
  }

  Future<void> _handleRoleChange(String newRole) async {
    final reason = await _showReasonDialog(
      title: newRole == 'admin' ? 'Promote to admin' : 'Revoke admin role',
      hint: 'Reason (required)',
      confirmLabel: newRole == 'admin' ? 'Promote' : 'Revoke',
      confirmColor: const Color(0xFF9C27B0),
    );
    if (reason == null) return;
    setState(() => _isActionInFlight = true);
    final result =
        await _adminService.changeRole(widget.userId, newRole, reason);
    if (!mounted) return;
    setState(() => _isActionInFlight = false);
    _showResultSnack(
      result,
      successText: newRole == 'admin' ? 'Promoted to admin' : 'Admin role revoked',
    );
    if (result['success'] == true) {
      AnalyticsService.instance.adminActionTaken(
        action: 'role_changed',
        targetUserId: widget.userId,
      );
      await _load();
    }
  }

  void _showResultSnack(Map<String, dynamic> result, {required String successText}) {
    final ok = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? successText : (result['error']?.toString() ?? 'Failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<String?> _showReasonDialog({
    required String title,
    required String hint,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final hasReason = controller.text.trim().isNotEmpty;
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                onChanged: (_) => setLocal(() {}),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: confirmColor),
                  onPressed: hasReason
                      ? () => Navigator.pop(ctx, controller.text.trim())
                      : null,
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final Map<String, dynamic> action;
  const _ActionRow({required this.action});

  @override
  Widget build(BuildContext context) {
    final actionName = action['action']?.toString() ?? '';
    final moderator = action['moderator'] is Map
        ? (action['moderator']['name']?.toString() ?? '(unknown)')
        : '(unknown)';
    final reason = action['reason']?.toString();
    final source = action['source']?.toString();
    final timestamp = action['timestamp']?.toString();

    final color = _colorForAction(actionName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconForAction(actionName), color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$actionName · by $moderator',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (reason != null && reason.isNotEmpty)
                  Text(
                    reason,
                    style: TextStyle(
                      color: context.textMuted,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                Row(
                  children: [
                    if (timestamp != null && timestamp.isNotEmpty)
                      Text(
                        _formatTimestamp(timestamp),
                        style:
                            TextStyle(color: context.textMuted, fontSize: 11),
                      ),
                    if (source != null && source.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          source,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForAction(String action) {
    if (action.contains('ban') && !action.contains('un')) return AppColors.error;
    if (action.contains('unban') || action.contains('un_')) return AppColors.success;
    if (action.contains('role')) return const Color(0xFF9C27B0);
    return Colors.black54;
  }

  IconData _iconForAction(String action) {
    if (action.contains('ban') && !action.contains('un')) return Icons.block;
    if (action.contains('unban')) return Icons.check_circle_outline;
    if (action.contains('role')) return Icons.shield_outlined;
    return Icons.history;
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('MMM d, yyyy · HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _ActivityStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;
  const _ActivityStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
