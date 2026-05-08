import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Bottom control bar for a voice room (chat / raise-hand / mute / leave).
class VoiceRoomControls extends StatelessWidget {
  final bool isMuted;
  final bool isHandRaised;
  final VoidCallback onRaiseHand;
  final VoidCallback onMute;
  final VoidCallback onLeave;

  /// When [isHost] is true the leave button is replaced with an "End room"
  /// button that calls [onEnd] instead of [onLeave].
  final bool isHost;
  final VoidCallback onEnd;

  /// Chat panel toggle
  final int unreadChatCount;
  final VoidCallback onChatToggle;

  /// Localised labels passed in from the parent so this widget stays
  /// free of direct l10n dependencies.
  final String raiseHandLabel;
  final String lowerHandLabel;
  final String muteLabel;
  final String unmuteLabel;
  final String leaveLabel;
  final String endRoomLabel;

  const VoiceRoomControls({
    super.key,
    required this.isMuted,
    required this.isHandRaised,
    required this.onRaiseHand,
    required this.onMute,
    required this.onLeave,
    required this.isHost,
    required this.onEnd,
    required this.unreadChatCount,
    required this.onChatToggle,
    required this.raiseHandLabel,
    required this.lowerHandLabel,
    required this.muteLabel,
    required this.unmuteLabel,
    required this.leaveLabel,
    required this.endRoomLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0x0DFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Chat toggle with unread badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ControlButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '',
                  color: Colors.white,
                  backgroundColor: const Color(0x1AFFFFFF),
                  onTap: onChatToggle,
                ),
                if (unreadChatCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            _ControlButton(
              icon: isHandRaised
                  ? Icons.front_hand_rounded
                  : Icons.front_hand_outlined,
              label: isHandRaised ? lowerHandLabel : raiseHandLabel,
              color: isHandRaised ? const Color(0xFFFFB74D) : Colors.white,
              backgroundColor: isHandRaised
                  ? const Color(0xFFFFB74D).withValues(alpha: 0.2)
                  : const Color(0x1AFFFFFF),
              onTap: onRaiseHand,
            ),
            _ControlButton(
              icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: isMuted ? unmuteLabel : muteLabel,
              color: isMuted ? Colors.red : const Color(0xFF00BFA5),
              backgroundColor: isMuted
                  ? Colors.red.withValues(alpha: 0.2)
                  : const Color(0xFF00BFA5).withValues(alpha: 0.2),
              onTap: onMute,
              isLarge: true,
            ),
            _ControlButton(
              icon: isHost ? Icons.cancel_rounded : Icons.call_end_rounded,
              label: isHost ? endRoomLabel : leaveLabel,
              color: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.2),
              onTap: isHost ? onEnd : onLeave,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool isLarge;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 72.0 : 56.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
          ),
        ),
        Spacing.gapSM,
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF)),
        ),
      ],
    );
  }
}
