import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/services/voice_room_manager.dart';

class VoiceRoomChatPanel extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onClose;
  const VoiceRoomChatPanel({
    super.key,
    required this.scrollController,
    this.onClose,
  });

  @override
  ConsumerState<VoiceRoomChatPanel> createState() => _VoiceRoomChatPanelState();
}

class _VoiceRoomChatPanelState extends ConsumerState<VoiceRoomChatPanel> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    ref.read(voiceRoomProvider).sendChat(text);
    _inputController.clear();
    // Auto-scroll to bottom on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The voice room screen is on a fixed dark theme; mirror it here.
    final messages = ref.watch(voiceRoomProvider).chatMessages;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF22223A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title row with close button
          SizedBox(
            height: 32,
            child: Row(
              children: [
                const SizedBox(width: 40), // balance the close button
                Expanded(
                  child: Text(
                    l10n.voiceRoomChat,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: widget.onClose,
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      l10n.voiceRoomChatEmpty,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _ChatLine(messages[i]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l10n.voiceRoomChatPlaceholder,
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatLine extends StatelessWidget {
  final VoiceRoomChatMessage message;
  const _ChatLine(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${message.userName}: ',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: message.message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
