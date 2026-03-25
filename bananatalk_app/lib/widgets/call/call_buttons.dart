import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CallButtons extends ConsumerWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientProfilePicture;
  final int messageCount;
  final Color? iconColor;
  final double iconSize;

  const CallButtons({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientProfilePicture,
    required this.messageCount,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final canCall = messageCount >= 3;
    final color = iconColor ?? Theme.of(context).iconTheme.color;
    final disabledColor = color?.withOpacity(0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio call button
        Tooltip(
          message: canCall ? l10n.voiceCall : l10n.exchange3MessagesBeforeCall,
          child: IconButton(
            icon: Icon(
              Icons.call_outlined,
              color: canCall ? color : disabledColor,
              size: iconSize,
            ),
            onPressed: canCall
                ? () => _initiateCall(context, ref, CallType.audio)
                : null,
          ),
        ),
        // Video call button
        Tooltip(
          message: canCall ? l10n.videoCall : l10n.exchange3MessagesBeforeCall,
          child: IconButton(
            icon: Icon(
              Icons.videocam_outlined,
              color: canCall ? color : disabledColor,
              size: iconSize,
            ),
            onPressed: canCall
                ? () => _initiateCall(context, ref, CallType.video)
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _initiateCall(
    BuildContext context,
    WidgetRef ref,
    CallType callType,
  ) async {
    try {
      await ref.read(callProvider.notifier).initiateCall(
            recipientId,
            recipientName,
            recipientProfilePicture,
            callType,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }
}
