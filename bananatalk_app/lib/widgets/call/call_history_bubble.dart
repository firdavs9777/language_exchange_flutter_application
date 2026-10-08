import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/models/call_record_model.dart';

/// A call message in the conversation. One message is shared by both users;
/// each side renders its own §3 label from `outcome` and who called.
class CallHistoryBubble extends StatelessWidget {
  final CallRecord call;

  /// True when the viewer sent the message, i.e. was the caller.
  final bool isOutgoing;
  final String otherName;
  final VoidCallback? onTap;

  const CallHistoryBubble({
    super.key,
    required this.call,
    required this.isOutgoing,
    this.otherName = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outcome = call.outcome ?? CallOutcome.completed;
    final isVideo = call.type == CallType.video;
    final missed = CallLabels.isMissedForViewer(outcome, viewerIsCaller: isOutgoing);
    final negative = missed || outcome == CallOutcome.declined;
    final label = CallLabels.label(
      l10n,
      outcome: outcome,
      viewerIsCaller: isOutgoing,
      isVideo: isVideo,
      duration: call.duration ?? 0,
      otherName: otherName,
    );
    final directionIcon = missed
        ? Icons.call_missed
        : (isOutgoing ? Icons.call_made : Icons.call_received);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: negative ? Colors.red.withValues(alpha: 0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: negative ? Colors.red.withValues(alpha: 0.3) : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(directionIcon, color: negative ? Colors.red : Colors.green, size: 18),
            const SizedBox(width: 6),
            Icon(isVideo ? Icons.videocam_outlined : Icons.call_outlined,
                color: negative ? Colors.red : theme.iconTheme.color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: negative ? Colors.red : null, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.jm().format(call.startTime.toLocal()),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(isVideo ? Icons.videocam : Icons.call, size: 16, color: theme.primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}
