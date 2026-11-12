import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Closes a paged moments list: a spinner while the next page loads, or, when
/// that fetch failed, a message with a Retry button. While a retry is in
/// flight the button is replaced by a small spinner (so a tap gives feedback
/// and cannot start a second request). Shared by the feed and hashtag pages.
class FeedLoadMoreFooter extends StatefulWidget {
  const FeedLoadMoreFooter({super.key, required this.failed, this.onRetry});

  /// The last next-page fetch failed.
  final bool failed;

  /// Asks for the page again; the returned future completing ends the
  /// spinner (a plain callback ends it right away).
  final FutureOr<void> Function()? onRetry;

  @override
  State<FeedLoadMoreFooter> createState() => _FeedLoadMoreFooterState();
}

class _FeedLoadMoreFooterState extends State<FeedLoadMoreFooter> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await widget.onRetry?.call();
    } catch (_) {
      // The owner shows its own failure state.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final spinner = SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(primary),
      ),
    );
    if (!widget.failed) {
      return Padding(
        key: const ValueKey('feed-load-more'),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: spinner),
      );
    }
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      key: const ValueKey('feed-load-more-failed'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              l10n.feedCouldNotLoadMore,
              style: context.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          if (_retrying)
            // Same footprint as the button so the row does not jump.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            )
          else
            TextButton(onPressed: _retry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
