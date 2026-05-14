import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/admin_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Step 15 F4 — admin audit log screen.
///
/// Paginated history of moderator actions written by services/banService.js.
/// Filter chips at the top narrow by action type:
///   - All        (no action filter)
///   - Bans       (action=user_banned)
///   - Unbans     (action=user_unbanned)
///   - Roles      (action=role_changed)
///
/// Each entry shows: action + moderator → target + reason + source pill +
/// relative timestamp. Tap → bottom sheet with full details payload.
class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

enum _Filter { all, bans, unbans, roles }

extension on _Filter {
  String? get actionParam {
    switch (this) {
      case _Filter.all:
        return null;
      case _Filter.bans:
        return 'user_banned';
      case _Filter.unbans:
        return 'user_unbanned';
      case _Filter.roles:
        return 'role_changed';
    }
  }

  String get label {
    switch (this) {
      case _Filter.all:
        return 'All';
      case _Filter.bans:
        return 'Bans';
      case _Filter.unbans:
        return 'Unbans';
      case _Filter.roles:
        return 'Roles';
    }
  }
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  final AdminService _adminService = AdminService();
  final ScrollController _scrollController = ScrollController();

  _Filter _filter = _Filter.all;
  final List<dynamic> _entries = [];
  bool _isLoading = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(userProvider).valueOrNull;
      if (user?.isAdmin != true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _NotAuthorizedScreen()),
        );
        return;
      }
      _load(reset: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _load();
    }
  }

  void _setFilter(_Filter f) {
    if (_filter == f) return;
    setState(() => _filter = f);
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _entries.clear();
        _page = 1;
        _error = null;
      });
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await _adminService.getAuditLog(
      action: _filter.actionParam,
      page: _page,
      limit: 50,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        final newEntries = (result['data'] as List?) ?? [];
        _entries.addAll(newEntries);
        final pagination =
            (result['pagination'] as Map<String, dynamic>?) ?? const {};
        _hasMore = pagination['hasMore'] == true;
        _page += 1;
      } else {
        _error = result['error']?.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _Filter.values
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.label),
                            selected: _filter == f,
                            onSelected: (_) => _setFilter(f),
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color:
                                  _filter == f ? AppColors.primary : Colors.black87,
                              fontWeight: _filter == f
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_error != null && _entries.isEmpty) {
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
              FilledButton(
                onPressed: () => _load(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No audit log entries match the filter.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _entries.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final entry = _entries[i] as Map<String, dynamic>;
          return _AuditEntry(
            entry: entry,
            onTap: () => _showDetailSheet(entry),
          );
        },
      ),
    );
  }

  void _showDetailSheet(Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) {
          return SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry['action']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Moderator',
                  value: entry['moderator'] is Map
                      ? (entry['moderator']['name']?.toString() ?? '(unknown)')
                      : '(unknown)',
                ),
                _DetailRow(
                  label: 'Target',
                  value: entry['target'] is Map
                      ? (entry['target']['name']?.toString() ?? '(unknown)')
                      : '(unknown)',
                ),
                _DetailRow(
                  label: 'Timestamp',
                  value: _formatFull(entry['timestamp']?.toString()),
                ),
                if (entry['source'] != null)
                  _DetailRow(
                    label: 'Source',
                    value: entry['source'].toString(),
                  ),
                if (entry['reason'] != null &&
                    entry['reason'].toString().isNotEmpty)
                  _DetailRow(
                    label: 'Reason',
                    value: entry['reason'].toString(),
                  ),
                if (entry['details'] is Map &&
                    (entry['details'] as Map).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Details',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatJson(entry['details'] as Map),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatFull(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('MMM d, yyyy · HH:mm:ss')
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  String _formatJson(Map data) {
    final lines = <String>[];
    data.forEach((k, v) => lines.add('$k: $v'));
    return lines.join('\n');
  }
}

class _AuditEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;
  const _AuditEntry({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final action = entry['action']?.toString() ?? '';
    final moderator = entry['moderator'] is Map
        ? (entry['moderator']['name']?.toString() ?? '(unknown)')
        : '(unknown)';
    final target = entry['target'] is Map
        ? (entry['target']['name']?.toString() ?? '(unknown)')
        : null;
    final reason = entry['reason']?.toString();
    final source = entry['source']?.toString();
    final timestamp = entry['timestamp']?.toString();

    final color = _colorForAction(action);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(_iconForAction(action), color: color, size: 20),
      ),
      title: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          if (source != null && source.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                source,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            target != null ? '$moderator → $target' : moderator,
            style: TextStyle(color: context.textMuted, fontSize: 12),
          ),
          if (reason != null && reason.isNotEmpty)
            Text(
              reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          if (timestamp != null && timestamp.isNotEmpty)
            Text(
              _formatRelative(timestamp),
              style: TextStyle(color: context.textMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Color _colorForAction(String action) {
    if (action == 'user_banned') return AppColors.error;
    if (action == 'user_unbanned') return AppColors.success;
    if (action == 'role_changed') return const Color(0xFF9C27B0);
    if (action.contains('failed') || action.contains('noop')) {
      return Colors.black45;
    }
    return Colors.black54;
  }

  IconData _iconForAction(String action) {
    if (action == 'user_banned') return Icons.block;
    if (action == 'user_unbanned') return Icons.check_circle_outline;
    if (action == 'role_changed') return Icons.shield_outlined;
    if (action.contains('failed')) return Icons.error_outline;
    if (action.contains('noop')) return Icons.replay_outlined;
    return Icons.history;
  }

  String _formatRelative(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: context.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _NotAuthorizedScreen extends StatelessWidget {
  const _NotAuthorizedScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text("This page isn't available.")),
    );
  }
}
