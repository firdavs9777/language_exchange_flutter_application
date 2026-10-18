import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bananatalk_app/pages/chat/header/user_avatar.dart';

/// A short banner at the top of the screen for a chat message that arrives
/// while the app is open but the person is not in that chat (2026-10-18).
/// The server sends no push while the chat socket is connected and the app
/// dropped foreground chat pushes, so a message received on AI Study (or any
/// other screen) showed nothing but a badge.
class InAppMessageBanner {
  InAppMessageBanner._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static const Duration visibleFor = Duration(seconds: 4);

  /// Shows (or replaces) the banner on [overlay]. [onTap] opens the chat.
  static void show({
    required OverlayState overlay,
    required String senderName,
    required String preview,
    String? avatarUrl,
    required VoidCallback onTap,
  }) {
    hide();
    final entry = OverlayEntry(
      builder: (context) => _BannerView(
        senderName: senderName,
        preview: preview,
        avatarUrl: avatarUrl,
        onTap: () {
          hide();
          onTap();
        },
        onDismiss: hide,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(visibleFor, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  @visibleForTesting
  static bool get isShowing => _entry != null;
}

class _BannerView extends StatelessWidget {
  const _BannerView({
    required this.senderName,
    required this.preview,
    required this.avatarUrl,
    required this.onTap,
    required this.onDismiss,
  });

  final String senderName;
  final String preview;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -1, end: 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) =>
              FractionalTranslation(translation: Offset(0, t), child: child),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Dismissible(
              key: const ValueKey('in-app-message-banner-dismiss'),
              direction: DismissDirection.up,
              onDismissed: (_) => onDismiss(),
              child: Material(
                key: const Key('in-app-message-banner'),
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        UserAvatar(
                          profilePicture: avatarUrl,
                          userName: senderName,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                preview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
