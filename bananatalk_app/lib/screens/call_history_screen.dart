import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/services/call_history_service.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  List<CallRecord> _calls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
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
      final calls = await service.getCallHistory();
      setState(() {
        _calls = calls;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.callHistory),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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

    if (_calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.call_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noCallHistory,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      child: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          return _CallHistoryTile(
            call: _calls[index],
            currentUserId: _currentUserId,
            onTap: () => _initiateCall(_calls[index]),
          );
        },
      ),
    );
  }

  void _initiateCall(CallRecord record) {
    final other = record.getOtherParticipant(_currentUserId);
    if (other == null) return;

    ref.read(callProvider.notifier).initiateCall(
          other.id,
          other.name,
          other.profilePicture,
          record.type,
        );
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
          color: isMissed ? Colors.red : null,
          fontWeight: isMissed ? FontWeight.bold : null,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            call.direction == CallDirection.incoming
                ? Icons.call_received
                : Icons.call_made,
            size: 14,
            color: isMissed ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            call.type == CallType.video ? l10n.videoCall : l10n.audioCall,
            style: TextStyle(
              color: isMissed ? Colors.red : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat.MMMd().add_jm().format(call.startTime),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.duration != null)
            Text(
              call.formattedDuration,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
}
