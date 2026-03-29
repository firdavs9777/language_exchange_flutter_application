import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/services/call_history_service.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/daily_call_limit_service.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<CallRecord> _allCalls = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCallHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCallHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authServiceProvider);
      final currentUserId = authState.userId;
      final service = CallHistoryService(ApiClient(), currentUserId);
      final calls = await service.getCallHistory(limit: 50);
      setState(() {
        _allCalls = calls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String get _currentUserId {
    final authState = ref.read(authServiceProvider);
    return authState.userId;
  }

  List<CallRecord> get _missedCalls =>
      _allCalls.where((c) => c.status == CallRecordStatus.missed).toList();

  List<CallRecord> get _incomingCalls =>
      _allCalls.where((c) => c.direction == CallDirection.incoming).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.callHistory),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.callMissed),
            Tab(text: l10n.incomingAudioCall.split(' ').first),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(l10n)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCallList(_allCalls, l10n),
                    _buildCallList(_missedCalls, l10n),
                    _buildCallList(_incomingCalls, l10n),
                  ],
                ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCallHistory,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildCallList(List<CallRecord> calls, AppLocalizations l10n) {
    if (calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noCallHistory,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Group calls by date
    final grouped = <String, List<CallRecord>>{};
    for (final call in calls) {
      final key = _dateGroupKey(call.startTime);
      grouped.putIfAbsent(key, () => []).add(call);
    }

    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      child: ListView.builder(
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final key = grouped.keys.elementAt(index);
          final groupCalls = grouped[key]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              ...groupCalls.map((call) => _CallHistoryTile(
                    call: call,
                    currentUserId: _currentUserId,
                    onTap: () => _initiateCall(call),
                  )),
            ],
          );
        },
      ),
    );
  }

  String _dateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(callDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat.EEEE().format(date);
    return DateFormat.yMMMd().format(date);
  }

  Future<void> _initiateCall(CallRecord record) async {
    final other = record.getOtherParticipant(_currentUserId);
    if (other == null) return;

    // Check VIP status for call limits
    final isVip = ref.read(isVipProvider(_currentUserId));
    if (!isVip) {
      final canMakeCall = await DailyCallLimitService.canCall();
      if (!canMakeCall && mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => VipUpgradeSheet(
            featureName: 'Unlimited Calls',
            description:
                'Free users can make up to ${DailyCallLimitService.maxDailyCalls} calls per day. '
                'Upgrade to VIP for unlimited calls!',
          ),
        );
        return;
      }
    }

    final callNotifier = ref.read(callProvider.notifier);
    callNotifier.setVipCall(isVip);
    await callNotifier.initiateCall(
      other.id,
      other.name,
      other.profilePicture,
      record.type,
    );

    // Record call for daily limit
    if (!isVip) {
      final currentCall = callNotifier.currentCall;
      if (currentCall != null && currentCall.callId.isNotEmpty) {
        await DailyCallLimitService.recordCall(currentCall.callId);
      }
    }
  }
}

class _CallHistoryTile extends StatelessWidget {
  final CallRecord call;
  final String currentUserId;
  final VoidCallback onTap;

  const _CallHistoryTile({
    required this.call,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final other = call.getOtherParticipant(currentUserId);
    final isMissed = call.status == CallRecordStatus.missed;
    final isRejected = call.status == CallRecordStatus.rejected;
    final isBad = isMissed || isRejected;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: other?.profilePicture != null
            ? NetworkImage(other!.profilePicture!)
            : null,
        child: other?.profilePicture == null
            ? Text(other?.name.substring(0, 1).toUpperCase() ?? '?')
            : null,
      ),
      title: Text(
        other?.name ?? 'Unknown',
        style: TextStyle(
          color: isBad ? Colors.red : null,
          fontWeight: isBad ? FontWeight.bold : null,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            _directionIcon,
            size: 14,
            color: _directionColor,
          ),
          const SizedBox(width: 4),
          Text(
            call.type == CallType.video ? l10n.videoCall : l10n.audioCall,
            style: TextStyle(color: isBad ? Colors.red : null),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat.jm().format(call.startTime),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.duration != null && call.duration! > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                call.formattedDuration,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          IconButton(
            icon: Icon(
              call.type == CallType.video ? Icons.videocam : Icons.call,
            ),
            onPressed: onTap,
            tooltip: l10n.callBack,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  IconData get _directionIcon {
    if (call.status == CallRecordStatus.missed) return Icons.call_missed;
    if (call.status == CallRecordStatus.rejected) return Icons.call_end;
    if (call.direction == CallDirection.outgoing) return Icons.call_made;
    return Icons.call_received;
  }

  Color get _directionColor {
    if (call.status == CallRecordStatus.missed ||
        call.status == CallRecordStatus.rejected) return Colors.red;
    return Colors.green;
  }
}
