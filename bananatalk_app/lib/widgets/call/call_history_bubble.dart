import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CallHistoryBubble extends StatelessWidget {
  final CallRecord call;
  final bool isOutgoing;
  final VoidCallback? onTap;

  const CallHistoryBubble({
    super.key,
    required this.call,
    required this.isOutgoing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMissed = call.status == CallRecordStatus.missed;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMissed
              ? Colors.red.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMissed
                ? Colors.red.withOpacity(0.3)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              call.type == CallType.video
                  ? Icons.videocam_outlined
                  : Icons.call_outlined,
              color: isMissed ? Colors.red : theme.iconTheme.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMissed
                      ? l10n.callMissed
                      : (call.type == CallType.video
                          ? l10n.videoCall
                          : l10n.audioCall),
                  style: TextStyle(
                    color: isMissed ? Colors.red : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  call.duration != null
                      ? call.formattedDuration
                      : DateFormat.jm().format(call.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.replay,
                size: 16,
                color: theme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
