import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Widget to display when content is blocked or not available
class BlockedContentWidget extends StatelessWidget {
  final String? title;
  final String? message;

  /// Localized [message] for the factories, resolved in [build].
  final String Function(AppLocalizations l10n)? _localizedMessage;
  final IconData icon;
  final VoidCallback? onRetry;
  final bool showRetry;
  final EdgeInsets padding;

  const BlockedContentWidget({
    Key? key,
    this.title,
    this.message,
    this.icon = Icons.block,
    this.onRetry,
    this.showRetry = false,
    this.padding = const EdgeInsets.all(32),
  })  : _localizedMessage = null,
        super(key: key);

  const BlockedContentWidget._localized(
    this._localizedMessage, {
    required this.icon,
    this.onRetry,
    this.showRetry = false,
  })  : title = null,
        message = null,
        padding = const EdgeInsets.all(32);

  /// Standard blocked content display
  factory BlockedContentWidget.standard({String? message, VoidCallback? onRetry}) {
    return BlockedContentWidget._localized(
      (l10n) => message ?? l10n.blockedContentUnavailableToYou,
      icon: Icons.visibility_off,
      onRetry: onRetry,
    );
  }

  /// User blocked display
  factory BlockedContentWidget.userBlocked({String? userName}) {
    return BlockedContentWidget._localized(
      (l10n) => userName != null
          ? l10n.blockedCantViewUserContent(userName)
          : l10n.blockedCantViewThisUserContent,
      icon: Icons.person_off,
    );
  }

  /// Profile blocked display (for profile pages)
  factory BlockedContentWidget.profile({String? userName}) {
    return BlockedContentWidget._localized(
      (l10n) => userName != null
          ? l10n.blockedCantViewUserProfile(userName)
          : l10n.blockedProfileUnavailable,
      icon: Icons.person_off,
    );
  }

  /// Moments blocked display
  factory BlockedContentWidget.moments({VoidCallback? onRetry}) {
    return BlockedContentWidget._localized(
      (l10n) => l10n.blockedContentUnavailable,
      icon: Icons.photo_library_outlined,
      onRetry: onRetry,
      showRetry: onRetry != null,
    );
  }

  /// Stories blocked display
  factory BlockedContentWidget.stories() {
    return BlockedContentWidget._localized(
      (l10n) => l10n.blockedCantViewStories,
      icon: Icons.auto_stories,
    );
  }

  /// Chat blocked display
  factory BlockedContentWidget.chat({String? userName}) {
    return BlockedContentWidget._localized(
      (l10n) => userName != null
          ? l10n.blockedCantMessageUser(userName)
          : l10n.blockedCantMessageThisUser,
      icon: Icons.chat_bubble_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? displayTitle = title;
    final displayMessage = message ?? _localizedMessage?.call(l10n);
    
    // Localize title based on icon if title is null (from factory methods)
    if (displayTitle == null) {
      if (icon == Icons.visibility_off) {
        displayTitle = l10n.contentNotAvailable;
      } else if (icon == Icons.person_off) {
        displayTitle = l10n.profileNotAvailable;
      } else if (icon == Icons.photo_library_outlined) {
        displayTitle = l10n.noMomentsToShow;
      } else if (icon == Icons.auto_stories) {
        displayTitle = l10n.storiesNotAvailable;
      } else if (icon == Icons.chat_bubble_outline) {
        displayTitle = l10n.cantMessageThisUser;
      } else {
        displayTitle = l10n.contentNotAvailable;
      }
    }
    
    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          if (displayMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              displayMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (showRetry && onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.tryAgain),
            ),
          ],
        ],
      ),
    );
  }
}

/// Placeholder widget shown in place of blocked user content in lists
class BlockedContentPlaceholder extends StatelessWidget {
  final String? message;
  final double height;

  const BlockedContentPlaceholder({
    Key? key,
    this.message,
    this.height = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility_off, color: Colors.grey[400], size: 20),
          const SizedBox(width: 8),
          Builder(
            builder: (context) => Text(
              message ?? AppLocalizations.of(context)!.contentNotAvailable,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Snackbar helper for blocked content actions
class BlockedContentSnackbar {
  static void show(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? AppLocalizations.of(context)!.blockedActionNotAllowed,
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showCannotLike(BuildContext context) {
    show(context, message: AppLocalizations.of(context)!.blockedCantLike);
  }

  static void showCannotComment(BuildContext context) {
    show(context, message: AppLocalizations.of(context)!.blockedCantComment);
  }

  static void showCannotMessage(BuildContext context) {
    show(context, message: AppLocalizations.of(context)!.cantMessageThisUser);
  }

  static void showContentNotAvailable(BuildContext context) {
    show(context, message: AppLocalizations.of(context)!.blockedContentUnavailable);
  }
}

/// Extension for handling blocked API responses
extension BlockedResponseHandler on Map<String, dynamic> {
  bool get isBlocked => this['blocked'] == true;
  
  bool get isBlockedError =>
      this['success'] == false &&
      (this['blocked'] == true || this['error']?.toString().contains('block') == true);
  
  String get blockMessage =>
      this['message'] ?? this['error'] ?? '';
}

/// Mixin for handling blocked content in StatefulWidgets
mixin BlockedContentMixin<T extends StatefulWidget> on State<T> {
  bool _isBlocked = false;
  String? _blockedMessage;

  bool get isBlocked => _isBlocked;
  String? get blockedMessage => _blockedMessage;

  void setBlocked(bool blocked, [String? message]) {
    setState(() {
      _isBlocked = blocked;
      _blockedMessage = message;
    });
  }

  void handleBlockedResponse(Map<String, dynamic> response) {
    if (response.isBlocked || response.isBlockedError) {
      setBlocked(true, response.blockMessage);
    }
  }

  void clearBlocked() {
    setBlocked(false, null);
  }

  Widget buildBlockedContent() {
    return BlockedContentWidget.standard(message: _blockedMessage);
  }
}

