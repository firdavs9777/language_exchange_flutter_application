import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/admin/admin_content_rules.dart';
import 'package:bananatalk_app/providers/provider_root/admin_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Moderation for clubs and gatherings.
///
/// POST-moderation: everything here has ALREADY published. This screen exists
/// so an admin can review and remove, not to gate creation — pre-approval was
/// weighed and rejected, because putting a human in front of a feature with 1
/// club and 2 gatherings means the first person to create one waits and never
/// comes back.
///
/// Two tabs rather than two screens: clubs and gatherings moderate identically
/// — same filters, same paging, same "who made this and has anyone
/// complained" — and two screens would be two places for that logic to drift.
///
/// Nothing here deletes. Archive and cancel both use states the app already
/// filters on, so a wrong call is reversible.
class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Enforced server-side too (authorize('admin')); this stops a
      // non-admin who deep-links here from seeing an empty shell.
      final user = ref.read(userProvider).valueOrNull;
      if (user?.isAdmin != true) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs & Gatherings'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(key: Key('admin-tab-clubs'), text: 'Clubs'),
            Tab(key: Key('admin-tab-gatherings'), text: 'Gatherings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ContentList(kind: _Kind.clubs),
          _ContentList(kind: _Kind.gatherings),
        ],
      ),
    );
  }
}

enum _Kind { clubs, gatherings }

class _ContentList extends ConsumerStatefulWidget {
  const _ContentList({required this.kind});

  final _Kind kind;

  @override
  ConsumerState<_ContentList> createState() => _ContentListState();
}

class _ContentListState extends ConsumerState<_ContentList>
    with AutomaticKeepAliveClientMixin {
  final AdminService _admin = AdminService();
  final TextEditingController _search = TextEditingController();

  List<dynamic> _items = const [];
  bool _loading = false;
  bool _reportedOnly = false;
  String? _error;
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  bool get _isClubs => widget.kind == _Kind.clubs;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = _isClubs
        ? await _admin.listClubs(q: _search.text, reportedOnly: _reportedOnly)
        : await _admin.listGatherings(q: _search.text, reportedOnly: _reportedOnly);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _items = (result['data'] as List?) ?? const [];
      } else {
        _error = result['error']?.toString();
      }
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  /// Ask for a reason before acting.
  ///
  /// Not ceremony: the reason lands in the audit log, and an entry that says
  /// only "a club was archived" cannot be reviewed by anyone later, including
  /// the moderator who wrote it.
  Future<String?> _askReason(String title, String actionLabel) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          key: const Key('admin-reason-field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Recorded in the audit log',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('admin-reason-confirm'),
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(actionLabel, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _act(Map<String, dynamic> item) async {
    final status = item['status']?.toString();
    final removed = isRemoved(status);
    final label = moderationActionLabel(isClub: _isClubs, status: status);
    final name = (_isClubs ? item['name'] : item['title'])?.toString() ?? '';

    String? reason = '';
    if (actionNeedsReason(isClub: _isClubs, status: status)) {
      reason = await _askReason('$label "$name"?', label);
      if (reason == null || !mounted) return;
    }

    final result = _isClubs
        ? await _admin.setClubArchived(
            item['_id'].toString(),
            archived: !removed,
            reason: reason,
          )
        : await _admin.cancelGathering(item['_id'].toString(), reason: reason);

    if (!mounted) return;
    if (result['success'] == true) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']?.toString() ?? 'Action failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            key: const Key('admin-content-search'),
            controller: _search,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: _isClubs ? 'Search clubs' : 'Search gatherings',
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilterChip(
              key: const Key('admin-reported-filter'),
              label: const Text('Reported only'),
              selected: _reportedOnly,
              onSelected: (v) {
                setState(() => _reportedOnly = v);
                _load();
              },
            ),
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_error != null) {
      return _Centered(
        icon: Icons.error_outline,
        title: _error!,
        action: TextButton(onPressed: _load, child: const Text('Retry')),
      );
    }
    if (_items.isEmpty && !_loading) {
      return _Centered(
        icon: Icons.inbox_outlined,
        title: _reportedOnly
            ? 'Nothing reported'
            : (_isClubs ? 'No clubs yet' : 'No gatherings yet'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        key: const Key('admin-content-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) => _row(
          Map<String, dynamic>.from(_items[i] as Map),
        ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> item) {
    final name = (_isClubs ? item['name'] : item['title'])?.toString() ?? '—';
    final ownerMap = (_isClubs ? item['owner'] : item['host']);
    final owner = ownerMap is Map ? (ownerMap['name']?.toString() ?? '') : '';
    final status = item['status']?.toString();
    final reports = (item['openReports'] as num?)?.toInt() ?? 0;
    final removed = isRemoved(status);

    return ListTile(
      key: Key('admin-content-${item['_id']}'),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          // Struck through rather than hidden: a moderator needs to see what
          // they already acted on, or they act on it twice.
          decoration: removed ? TextDecoration.lineThrough : null,
          color: removed ? context.textMuted : null,
        ),
      ),
      subtitle: Text(
        moderationSubtitle(
          isClub: _isClubs,
          ownerName: owner,
          status: status,
          count: ((_isClubs ? item['memberCount'] : item['goingCount']) as num?)
                  ?.toInt() ??
              0,
        ),
        style: context.captionSmall.copyWith(color: context.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reports > 0)
            Container(
              key: const Key('admin-report-badge'),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$reports',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          TextButton(
            key: Key('admin-action-${item['_id']}'),
            onPressed: () => _act(item),
            child: Text(
              moderationActionLabel(isClub: _isClubs, status: status),
              style: TextStyle(color: removed ? null : AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textMuted),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
