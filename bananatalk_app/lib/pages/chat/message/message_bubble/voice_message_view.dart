import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/voice_message_player.dart';
import 'package:bananatalk_app/services/voice_message_service.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'reply_preview.dart';

/// Renders voice (and audio) messages.
///
/// Delegates playback UI + waveform to [VoiceMessagePlayer].
/// Reply preview is shown above the player when present.
/// A "Transcribe" button below the player lets users convert speech to text
/// on demand; the result is displayed inline in italic text.
class VoiceMessageView extends StatefulWidget {
  final Message message;
  final bool isMe;
  final Function(String messageId)? onReplyTap;
  final VoidCallback? onLongPress;

  const VoiceMessageView({
    super.key,
    required this.message,
    required this.isMe,
    this.onReplyTap,
    this.onLongPress,
  });

  @override
  State<VoiceMessageView> createState() => _VoiceMessageViewState();
}

class _VoiceMessageViewState extends State<VoiceMessageView> {
  String? _transcription;
  bool _isTranscribing = false;

  Future<void> _transcribe() async {
    final url = widget.message.media?.url;
    if (url == null || url.isEmpty) return;

    setState(() => _isTranscribing = true);

    final result = await VoiceMessageService.transcribeMessage(
      audioUrl: url,
    );

    if (!mounted) return;
    setState(() {
      _transcription = result;
      _isTranscribing = false;
    });

    if (result == null) {
      showChatSnackBar(
        context,
        message: AppLocalizations.of(context)!.transcriptionFailed,
        type: ChatSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deleted placeholder — no transcribe button here
    if (widget.message.isDeleted && widget.message.deletedForEveryone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.containerColor.withValues(alpha: 0.5),
          borderRadius: AppRadius.borderLG,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 16, color: context.textSecondary),
            Spacing.hGapSM,
            Text(
              'This message was deleted',
              style: context.bodySmall.copyWith(
                color: context.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final media = widget.message.media;
    if (media == null || media.url.isEmpty) {
      return const SizedBox.shrink();
    }

    final normalizedUrl = ImageUtils.normalizeImageUrl(media.url);

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message.replyTo != null)
            ReplyPreview(
              message: widget.message,
              isMe: widget.isMe,
              onReplyTap: widget.onReplyTap,
            ),
          VoiceMessagePlayer(
            audioUrl: normalizedUrl,
            durationSeconds: media.duration ?? 0,
            waveform: media.waveform,
            isFromMe: widget.isMe,
            messageId: widget.message.id,
            senderId: widget.message.sender.id,
          ),
          if (_transcription != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _transcription!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: widget.isMe
                      ? Colors.white70
                      : Theme.of(context).hintColor,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: _isTranscribing ? null : _transcribe,
                icon: _isTranscribing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.text_fields_rounded,
                        size: 16,
                        color: widget.isMe ? Colors.white : null,
                      ),
                label: Text(
                  _isTranscribing
                      ? AppLocalizations.of(context)!.transcribing
                      : AppLocalizations.of(context)!.transcribeMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isMe ? Colors.white : null,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(0, 28),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
