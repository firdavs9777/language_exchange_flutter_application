import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// Your expired stories.
///
/// The backend archived them all along — GET /stories/archive, the service
/// method, and even the endpoint constant all existed — but nothing ever
/// called them, so 112 stories sat in a place no one could open.
///
/// The consequence was specific rather than cosmetic: a highlight is created
/// from ONE story id, and the only screen offering that was the live viewer.
/// So a story could be highlighted during the 24 hours it was up, and never
/// again. This screen makes yesterday's story reachable.
/// Fetches one page of the archive. Injected so the empty and failure states
/// can be tested — they are the two a user is most likely to hit and the two
/// a live network cannot be made to produce on demand.
typedef ArchiveLoader = Future<ArchiveResponse> Function(int page);

class StoryArchiveScreen extends StatefulWidget {
  const StoryArchiveScreen({super.key, this.loader});

  final ArchiveLoader? loader;

  @override
  State<StoryArchiveScreen> createState() => _StoryArchiveScreenState();
}

class _StoryArchiveScreenState extends State<StoryArchiveScreen> {
  final ScrollController _scroll = ScrollController();
  final List<Story> _stories = [];

  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final load = widget.loader ??
        (page) => StoriesService.getArchivedStories(page: page);
    final res = await load(_page);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (!res.success) {
        _error = res.error;
        return;
      }
      _stories.addAll(res.data);
      // Driven by the page count the server returns, not by an empty page, so
      // reaching the end does not cost an extra round trip.
      _hasMore = _page < res.pages;
      _page += 1;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _stories.clear();
      _page = 1;
      _hasMore = true;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storyArchiveTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              // Said plainly: an archive of your own posts is unsettling until
              // you know nobody else can see it.
              child: Text(
                l10n.storyArchiveSubtitle,
                style: context.captionSmall.copyWith(color: context.textMuted),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(onRefresh: _refresh, child: _body(l10n)),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_error != null && _stories.isEmpty) {
      return _centered(
        icon: Icons.error_outline,
        title: _error!,
        action: TextButton(onPressed: _refresh, child: Text(l10n.retry)),
      );
    }
    if (_stories.isEmpty && !_loading) {
      return _centered(
        icon: Icons.inventory_2_outlined,
        title: l10n.storyArchiveEmpty,
        body: l10n.storyArchiveEmptyBody,
      );
    }

    return GridView.builder(
      key: const Key('story-archive-grid'),
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        // Stories are vertical; a square tile crops every one through the
        // middle.
        childAspectRatio: 9 / 16,
      ),
      itemCount: _stories.length + (_loading ? 3 : 0),
      itemBuilder: (context, i) {
        if (i >= _stories.length) {
          return Container(color: context.containerColor);
        }
        return _tile(_stories[i], l10n);
      },
    );
  }

  Widget _tile(Story story, AppLocalizations l10n) {
    final thumb = story.mediaUrls.isNotEmpty
        ? story.mediaUrls.first
        : (story.mediaUrl.isNotEmpty ? story.mediaUrl : null);

    return GestureDetector(
      key: Key('archive-tile-${story.id}'),
      onTap: () => _openActions(story, l10n),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumb != null)
            CachedImageWidget(imageUrl: thumb, fit: BoxFit.cover)
          else
            // Text stories keep their own background, so a tile still looks
            // like the story it came from.
            Container(
              color: _colorOf(story.backgroundColor),
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              child: Text(
                story.text ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          if (story.isHighlighted)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.star_rounded, size: 16, color: Colors.amber),
            ),
          Positioned(
            left: 4,
            bottom: 4,
            child: Text(
              _ageOf(story),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The action the archive exists for.
  Future<void> _openActions(Story story, AppLocalizations l10n) async {
    final add = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('archive-add-highlight'),
              leading: const Icon(Icons.star_outline_rounded),
              title: Text(l10n.storyArchiveAddHighlight),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
          ],
        ),
      ),
    );
    if (add != true || !mounted) return;

    final title = await _askTitle(l10n);
    if (title == null || title.isEmpty || !mounted) return;

    final result = await StoriesService.createHighlight(
      title: title,
      storyId: story.id,
    );
    if (!mounted) return;

    final ok = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? l10n.storyArchiveAdded
            : (result['error']?.toString() ?? l10n.somethingWentWrong)),
      ),
    );
    // Refresh so the star appears on the tile that is now highlighted.
    if (ok) await _refresh();
  }

  Future<String?> _askTitle(AppLocalizations l10n) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.storyArchiveAddHighlight),
        content: TextField(
          key: const Key('archive-highlight-title'),
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(labelText: l10n.highlightTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('archive-highlight-save'),
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _centered({
    required IconData icon,
    required String title,
    String? body,
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Icon(icon, size: 40, color: context.textMuted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.bodyMedium.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: context.captionSmall.copyWith(color: context.textMuted),
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 8),
          Center(child: action),
        ],
      ],
    );
  }

  static Color _colorOf(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return Colors.black;
    return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
  }

  String _ageOf(Story story) {
    final days = DateTime.now().difference(story.createdAt).inDays;
    if (days < 1) return 'today';
    if (days < 7) return '${days}d';
    if (days < 365) return '${(days / 7).floor()}w';
    return '${(days / 365).floor()}y';
  }
}
