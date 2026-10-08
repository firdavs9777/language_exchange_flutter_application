import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/providers/missed_calls_provider.dart';
import 'package:bananatalk_app/services/call/call_launcher.dart';
import 'package:bananatalk_app/services/call_history_service.dart';
import 'package:bananatalk_app/widgets/navigation/app_back_button.dart';

/// The Calls list (spec §5.7): every call with labels derived from §3,
/// 30 per page, opening it clears the missed badge.
class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  final List<CallLogEntry> _items = [];
  final ScrollController _scroll = ScrollController();
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(missedCallsProvider.notifier).markSeen();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final page = await ref.read(callHistoryServiceProvider).fetchPage(_page + 1);
    if (!mounted) return;
    setState(() {
      _page++;
      _items.addAll(page.items);
      _hasMore = page.hasMore;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text(l10n.callsTitle)),
      body: _items.isEmpty && !_loading
          ? Center(child: Text(l10n.callsEmpty))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, i) => i >= _items.length
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _CallLogTile(entry: _items[i]),
              ),
            ),
    );
  }
}

class _CallLogTile extends ConsumerWidget {
  const _CallLogTile({required this.entry});

  final CallLogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isCaller = entry.direction == CallDirection.outgoing;
    final isVideo = entry.type == CallType.video;
    final missed = CallLabels.isMissedForViewer(entry.outcome, viewerIsCaller: isCaller);
    final label = CallLabels.label(
      l10n,
      outcome: entry.outcome,
      viewerIsCaller: isCaller,
      isVideo: isVideo,
      duration: entry.duration,
      otherName: entry.otherName,
    );
    final time = DateFormat.MMMd().add_jm().format(entry.createdAt.toLocal());
    final avatar = entry.otherAvatar;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child: avatar == null || avatar.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(entry.otherName, style: TextStyle(color: missed ? Colors.red : null)),
      subtitle: Row(
        children: [
          Icon(
            missed ? Icons.call_missed : (isCaller ? Icons.call_made : Icons.call_received),
            size: 14,
            color: missed ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 4),
          Icon(isVideo ? Icons.videocam_outlined : Icons.call_outlined, size: 14),
          const SizedBox(width: 4),
          Expanded(child: Text('$label · $time', overflow: TextOverflow.ellipsis)),
        ],
      ),
      trailing: IconButton(
        icon: Icon(isVideo ? Icons.videocam : Icons.call),
        onPressed: entry.otherId.isEmpty
            ? null
            : () => CallLauncher.start(
                  context,
                  ref,
                  userId: entry.otherId,
                  userName: entry.otherName,
                  avatar: entry.otherAvatar,
                  type: entry.type,
                ),
      ),
      onTap: entry.otherId.isEmpty ? null : () => context.push('/chat/${entry.otherId}'),
    );
  }
}
