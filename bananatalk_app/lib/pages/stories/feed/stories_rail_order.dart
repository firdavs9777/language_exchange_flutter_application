import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// One ring in the stories rail (own story is a separate first ring).
class RailEntry {
  const RailEntry({required this.group, required this.isDiscover});

  final UserStories group;

  /// True for a public story from someone the viewer does not follow.
  final bool isDiscover;
}

/// The rail order: unseen followed (server order), then Discover (server
/// order), then fully seen followed.
///
/// With [discoverEnabled] off, or nothing to discover once filtered, the
/// followed groups keep the server's order untouched: the rail is then
/// exactly what the app drew before Discover existed.
///
/// A Discover group is dropped when its user is also followed (it shows once,
/// as followed), is the current user, is blocked, or repeats. Followed groups
/// of the current user and of blocked users are dropped too (own stories have
/// their own ring).
List<RailEntry> orderStoriesRail({
  required List<UserStories> followed,
  required List<UserStories> discover,
  required bool discoverEnabled,
  Set<String> blockedUserIds = const {},
  String? currentUserId,
}) {
  bool allowed(UserStories g) =>
      !blockedUserIds.contains(g.user.id) &&
      !(currentUserId != null && g.user.id == currentUserId);

  final visibleFollowed = followed.where(allowed).toList();

  final followedIds = visibleFollowed.map((g) => g.user.id).toSet();
  final visibleDiscover = <UserStories>[];
  if (discoverEnabled) {
    final seen = <String>{};
    for (final g in discover) {
      if (!allowed(g) || followedIds.contains(g.user.id)) continue;
      if (seen.add(g.user.id)) visibleDiscover.add(g);
    }
  }

  RailEntry followedEntry(UserStories g) =>
      RailEntry(group: g, isDiscover: false);

  if (visibleDiscover.isEmpty) {
    return visibleFollowed.map(followedEntry).toList();
  }
  return [
    ...visibleFollowed.where((g) => g.hasUnviewed).map(followedEntry),
    ...visibleDiscover.map((g) => RailEntry(group: g, isDiscover: true)),
    ...visibleFollowed.where((g) => !g.hasUnviewed).map(followedEntry),
  ];
}

/// The image worth preloading for [story], matching what the viewer draws:
/// a photo's feed-size rendition when the server sent one (else the original),
/// a video's thumbnail only. Null when there is nothing to preload.
String? storyPrecacheUrl(Story story) {
  if (story.isVideo) {
    final t = story.videoMetadata?.thumbnail;
    return (t == null || t.isEmpty) ? null : t;
  }
  if (story.mediaType != 'image' || story.mediaUrl.isEmpty) return null;
  return story.variantFor(story.mediaUrl)?.feedUrl ?? story.mediaUrl;
}

/// The first story of each of the first [entryCount] rail entries.
List<String> storiesRailPrecacheUrls(
  List<RailEntry> entries, {
  int entryCount = 3,
}) {
  final urls = <String>[];
  for (final e in entries.take(entryCount)) {
    final stories = e.group.activeStories;
    if (stories.isEmpty) continue;
    final url = storyPrecacheUrl(stories.first);
    if (url != null && !urls.contains(url)) urls.add(url);
  }
  return urls;
}

/// What to preload while the viewer shows story [storyIndex] of group
/// [userIndex]: the next story, and (off mobile data) the next author's first
/// story as well.
List<String> storyViewerPrecacheUrls({
  required List<UserStories> groups,
  required int userIndex,
  required int storyIndex,
  required bool onMobileData,
}) {
  if (userIndex < 0 || userIndex >= groups.length) return const [];
  final current = groups[userIndex].activeStories;

  Story? firstOfNextAuthor() {
    if (userIndex + 1 >= groups.length) return null;
    final next = groups[userIndex + 1].activeStories;
    return next.isEmpty ? null : next.first;
  }

  final hasNextInGroup = storyIndex + 1 < current.length;
  final nextStory = hasNextInGroup ? current[storyIndex + 1] : firstOfNextAuthor();
  final targets = <Story?>[
    nextStory,
    if (!onMobileData && hasNextInGroup) firstOfNextAuthor(),
  ];

  final urls = <String>[];
  for (final s in targets) {
    if (s == null) continue;
    final url = storyPrecacheUrl(s);
    if (url != null && !urls.contains(url)) urls.add(url);
  }
  return urls;
}

/// [groups] with expired stories removed, and without the groups left with
/// no live story. For a rail painted from the cache: it lives 7 days, a
/// story 24 hours, and a ring with nothing live opens an empty viewer.
List<UserStories> dropExpiredStoryGroups(List<UserStories> groups) {
  final kept = <UserStories>[];
  for (final g in groups) {
    final live = g.activeStories;
    if (live.isEmpty) continue;
    if (live.length == g.stories.length) {
      kept.add(g);
      continue;
    }
    final latest = g.latestStory;
    final unviewed =
        g.unviewedCount < live.length ? g.unviewedCount : live.length;
    kept.add(UserStories(
      user: g.user,
      stories: live,
      hasUnviewed: g.hasUnviewed && unviewed > 0,
      unviewedCount: unviewed,
      latestStory: latest != null && live.any((s) => s.id == latest.id)
          ? latest
          : live.last,
    ));
  }
  return kept;
}
