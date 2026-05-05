import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/correction_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/chat/header/user_avatar.dart';

/// A chat bubble that displays a correction as a standalone message
/// in the chat flow (HelloTalk/Tandem style).
class CorrectionMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe; // whether the correction was made by the current user
  final String otherUserName;
  final String? otherUserPicture;

  const CorrectionMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.otherUserName,
    this.otherUserPicture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final correction = message.corrections.isNotEmpty
        ? message.corrections.first
        : null;
    if (correction == null) return const SizedBox.shrink();

    final isDark = context.isDarkMode;
    final diffs = CorrectionService.getDifferences(
      correction.originalText,
      correction.correctedText,
    );

    final correctorName = isMe ? 'You' : correction.corrector.name;

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 48 : 8,
        right: isMe ? 8 : 48,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              userName: otherUserName,
              profilePicture: otherUserPicture,
              radius: 14,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: correction icon + corrector name
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.spellcheck_rounded,
                        size: 14,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$correctorName corrected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (correction.isAccepted) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle, size: 12, color: Colors.green[600]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Diff display: strikethrough deleted, green bold added, normal unchanged
                  Text.rich(
                    TextSpan(
                      children: diffs.map((diff) {
                        switch (diff.type) {
                          case DiffType.unchanged:
                            return TextSpan(
                              text: '${diff.text} ',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.gray300 : AppColors.gray700,
                              ),
                            );
                          case DiffType.deleted:
                            return TextSpan(
                              text: '${diff.text} ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[400],
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.red[400],
                              ),
                            );
                          case DiffType.added:
                            return TextSpan(
                              text: '${diff.text} ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w600,
                              ),
                            );
                        }
                      }).toList(),
                    ),
                  ),
                  // Explanation if provided
                  if (correction.explanation != null &&
                      correction.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      correction.explanation!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
