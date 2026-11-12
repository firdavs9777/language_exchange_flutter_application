import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/hashtag_providers.dart';
import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:bananatalk_app/utils/hashtag_text.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/hashtag_text.dart' show openHashtag;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Moments search [query] belongs to this panel instead of the
/// text search: empty (trending tags) or starting with `#` (suggestions).
bool isHashtagSearchQuery(String query) {
  final trimmed = query.trim();
  return trimmed.isEmpty || trimmed.startsWith('#');
}

/// What the Moments search shows, with hashtags on, while the query is empty
/// (trending tags) or starts with `#` (suggestions for what follows it).
/// Failing or empty calls draw nothing: the server answers 404 while its
/// hashtag switch is off.
class HashtagSearchPanel extends ConsumerStatefulWidget {
  const HashtagSearchPanel({
    super.key,
    required this.query,
    this.onOpen,
    this.onNoSuggestions,
  });

  /// The search box text.
  final String query;

  /// Opens a tag's page; defaults to the hashtag route.
  final void Function(String tag)? onOpen;

  /// Called with the trimmed query when a `#...` lookup returned nothing (or
  /// failed), so the caller can fall back to the plain text search.
  final void Function(String query)? onNoSuggestions;

  @override
  ConsumerState<HashtagSearchPanel> createState() => _HashtagSearchPanelState();
}

class _HashtagSearchPanelState extends ConsumerState<HashtagSearchPanel> {
  static const _debounce = Duration(milliseconds: 250);

  Timer? _timer;
  int _generation = 0;
  List<HashtagCount> _results = const [];

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(HashtagSearchPanel old) {
    super.didUpdateWidget(old);
    if (old.query.trim() != widget.query.trim()) _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// The tag typed after `#`, cleaned; null when the query is not a tag
  /// search or nothing usable follows the `#` (a bare `#` asks nothing).
  String? get _typedTag {
    final q = widget.query.trim();
    if (!q.startsWith('#')) return null;
    return normalizeHashtag(q.substring(1));
  }

  void _schedule() {
    _timer?.cancel();
    final generation = ++_generation;
    final tag = _typedTag;
    final query = widget.query.trim();
    if (tag == null) {
      if (_results.isNotEmpty) _results = const [];
      return;
    }
    _timer = Timer(_debounce, () async {
      List<HashtagCount> found;
      try {
        found = await ref.read(hashtagServiceProvider).suggest(tag);
      } catch (_) {
        found = const [];
      }
      // A newer query was typed meanwhile: its answer is the one to show.
      if (!mounted || generation != _generation) return;
      setState(() => _results = found);
      if (found.isEmpty) widget.onNoSuggestions?.call(query);
    });
  }

  void _open(String tag) {
    final onOpen = widget.onOpen;
    if (onOpen != null) {
      onOpen(tag);
    } else {
      openHashtag(context, tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Empty, a bare `#` or nothing usable after it: trending.
    if (_typedTag == null) {
      final trending = ref.watch(trendingHashtagsProvider).valueOrNull;
      if (trending == null || trending.isEmpty) return const SizedBox.shrink();
      return _list(
        title: AppLocalizations.of(context)!.hashtagTrendingTitle,
        rows: trending,
      );
    }
    if (_results.isEmpty) return const SizedBox.shrink();
    return _list(rows: _results);
  }

  Widget _list({String? title, required List<HashtagCount> rows}) {
    // Opaque: it lies over the feed body and draws only when it has rows.
    return ColoredBox(
      color: context.scaffoldBackground,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(title, style: context.titleMedium),
            ),
          for (final row in rows)
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text('#${row.tag}'),
              trailing: row.postCount > 0
                  ? Text('${row.postCount}', style: context.bodySmall)
                  : null,
              onTap: () => _open(row.tag),
            ),
        ],
      ),
    );
  }
}
