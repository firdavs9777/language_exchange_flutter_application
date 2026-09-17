# Moments Feed & Detail UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the moments viewing path into a swipeable photo feed with feedback and continuity, and let a moment's author show a story ring.

**Architecture:** One new widget, `MomentMediaCarousel`, takes a `List<String>` and renders a fixed 4:5 `PageView` with dots — it has no other input, which is what makes it testable without a network or a provider. `MomentCardMedia` and `MomentImageGrid` both delegate to it. A second small widget owns the double-tap heart. The story ring is a backend fix: `controllers/moments.js` must stamp `hasActiveStory` per page using the `activeStoryFlags` helper the other controllers already use.

**Tech Stack:** Flutter 3 + Riverpod (`flutter_test`), Node 20 + Mongoose (`node:test`).

**Spec:** `docs/superpowers/specs/2026-09-17-moments-feed-ui-design.md`

## Global Constraints

- **Fixed 4:5 portrait, `BoxFit.cover`.** Every card the same height. (spec §3.1)
- **Cap at 10 images, and make the cap visible.** Never silently truncate — the current grid drops everything past the sixth with no indication. (spec §2.2)
- **The heart fires on like ONLY, never on un-like.** Animating a removal confirms the wrong action. (spec §3.2)
- **Honour `MediaQuery.of(context).disableAnimations`**, following `lib/pages/authentication/widgets/otp_code_field.dart`. (spec §3)
- **`hasActiveStory` is stamped in ONE query per page**, never per moment. A decorative ring must not cost 20 round trips on a 20-card page. (spec §5)
- Detail and feed use the same carousel. (spec §3.3)

---

## File Structure

| File | Responsibility |
|---|---|
| `app/lib/pages/moments/card/moment_media_carousel.dart` | **new** — `List<String>` → 4:5 PageView + dots |
| `app/lib/pages/moments/card/moment_double_tap_heart.dart` | **new** — the burst overlay, motion-aware |
| `app/lib/pages/moments/card/moment_card_media.dart` | delegate to the carousel |
| `app/lib/pages/moments/single/moment_image_grid.dart` | delegate to the carousel |
| `app/lib/pages/moments/card/moment_card_header.dart` | ring the author avatar |
| `app/lib/providers/provider_models/moments_model.dart` | parse author `hasActiveStory` |
| `backend/controllers/moments.js` | stamp the flag per page |

---

## Task 1 — `MomentMediaCarousel`

**Files:**
- Create: `app/lib/pages/moments/card/moment_media_carousel.dart`
- Test: `app/test/moments/moment_media_carousel_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `MomentMediaCarousel({required List<String> imageUrls, ValueChanged<int>? onPageChanged, String? heroPrefix})`; `const int kMomentImageCap = 10;`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/card/moment_media_carousel.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

List<String> _urls(int n) =>
    List.generate(n, (i) => 'https://example.com/$i.jpg');

void main() {
  testWidgets('GLOBAL CONSTRAINT: a 9-image post exposes all 9', (tester) async {
    // The grid this replaces rendered `imageCount > 6 ? 6 : imageCount`, so
    // images 7-9 were unreachable and the poster had no way to know.
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(9))));
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 9);
  });

  testWidgets('GLOBAL CONSTRAINT: beyond the cap is limited, and said out loud',
      (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(14))));
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, kMomentImageCap);
    // Silent truncation is the bug being fixed; a visible count is the fix.
    expect(find.byKey(const Key('carousel-cap-notice')), findsOneWidget);
  });

  testWidgets('a single image shows no dots and no cap notice', (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(1))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carousel-dots')), findsNothing);
    expect(find.byKey(const Key('carousel-cap-notice')), findsNothing);
  });

  testWidgets('several images show one dot each', (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(4))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carousel-dots')), findsOneWidget);
    expect(find.byKey(const Key('carousel-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('carousel-dot-3')), findsOneWidget);
  });

  testWidgets('swiping advances the page and reports it', (tester) async {
    var reported = -1;
    await tester.pumpWidget(_host(MomentMediaCarousel(
      imageUrls: _urls(3),
      onPageChanged: (i) => reported = i,
    )));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(reported, 1);
  });

  testWidgets('GLOBAL CONSTRAINT: the frame is 4:5', (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(2))));
    await tester.pumpAndSettle();
    final ratio = tester.widget<AspectRatio>(
      find.ancestor(of: find.byType(PageView), matching: find.byType(AspectRatio)).first,
    );
    expect(ratio.aspectRatio, closeTo(4 / 5, 0.001));
  });

  testWidgets('an empty list renders nothing rather than an empty frame',
      (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: const [])));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('it does not overflow at 320pt', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(5))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hero prefix produces one tag per page', (tester) async {
    await tester.pumpWidget(_host(
      MomentMediaCarousel(imageUrls: _urls(2), heroPrefix: 'moment-abc'),
    ));
    await tester.pumpAndSettle();
    final hero = tester.widget<Hero>(find.byType(Hero).first);
    expect(hero.tag, 'moment-abc-0');
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd bananatalk_app && flutter test test/moments/moment_media_carousel_test.dart`
Expected: FAIL — `Couldn't resolve the package 'moment_media_carousel'`

- [ ] **Step 3: Write the widget**

```dart
import 'package:flutter/material.dart';

import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// Instagram caps a post at 10; beyond that a carousel becomes a scroll trap.
/// The cap is SHOWN — the grid this replaces dropped everything past the sixth
/// with no indication at all, so the poster could not tell.
const int kMomentImageCap = 10;

/// A moment's images, one at a time, swipeable.
///
/// Fixed 4:5 so every card in the feed is the same height and the reader knows
/// where the next post starts. The cost is accepted: a panorama loses its
/// edges. Detail uses this same widget, so swiping does not stop working at
/// the moment someone taps through.
class MomentMediaCarousel extends StatefulWidget {
  const MomentMediaCarousel({
    super.key,
    required this.imageUrls,
    this.onPageChanged,
    this.heroPrefix,
  });

  final List<String> imageUrls;
  final ValueChanged<int>? onPageChanged;

  /// When set, each page is wrapped in a Hero tagged `<prefix>-<index>`, so
  /// opening from the third image expands THAT image rather than the first.
  final String? heroPrefix;

  @override
  State<MomentMediaCarousel> createState() => _MomentMediaCarouselState();
}

class _MomentMediaCarouselState extends State<MomentMediaCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  List<String> get _shown =>
      widget.imageUrls.take(kMomentImageCap).toList(growable: false);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _shown;
    if (images.isEmpty) return const SizedBox.shrink();

    final hidden = widget.imageUrls.length - images.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    widget.onPageChanged?.call(i);
                  },
                  itemBuilder: (context, index) {
                    final image = CachedImageWidget(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                    if (widget.heroPrefix == null) return image;
                    return Hero(
                      tag: '${widget.heroPrefix}-$index',
                      child: image,
                    );
                  },
                ),
                if (images.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _counter(context, '${_page + 1}/${images.length}'),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            key: const Key('carousel-dots'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                Container(
                  key: Key('carousel-dot-$i'),
                  width: i == _page ? 7 : 6,
                  height: i == _page ? 7 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? context.primaryColor
                        : context.textMuted.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ],
        if (hidden > 0)
          Padding(
            key: const Key('carousel-cap-notice'),
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+$hidden more',
              style: context.captionSmall.copyWith(color: context.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _counter(BuildContext context, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
}
```

- [ ] **Step 4: Run the tests and watch them pass**

Run: `cd bananatalk_app && flutter test test/moments/moment_media_carousel_test.dart`
Expected: PASS, 9/9

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/moments/card/moment_media_carousel.dart bananatalk_app/test/moments/moment_media_carousel_test.dart
git commit -m "feat(moments): a swipeable 4:5 carousel that shows every image"
```

---

## Task 2 — the double-tap heart

**Files:**
- Create: `app/lib/pages/moments/card/moment_double_tap_heart.dart`
- Test: `app/test/moments/moment_double_tap_heart_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `MomentDoubleTapHeart({required Widget child, required bool isLiked, required VoidCallback onLike})`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/card/moment_double_tap_heart.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('double-tap on an unliked moment calls onLike', (tester) async {
    var liked = 0;
    await tester.pumpWidget(_host(MomentDoubleTapHeart(
      isLiked: false,
      onLike: () => liked++,
      child: const SizedBox(width: 200, height: 200),
    )));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.pump(const Duration(milliseconds: 50));
    expect(liked, 1);
  });

  testWidgets('the heart appears on like', (tester) async {
    await tester.pumpWidget(_host(MomentDoubleTapHeart(
      isLiked: false,
      onLike: () {},
      child: const SizedBox(width: 200, height: 200),
    )));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('double-tap-heart')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('GLOBAL CONSTRAINT: no heart when already liked', (tester) async {
    // Un-liking is a correction. Animating it celebrates the removal, which
    // reads as confirming the wrong action.
    var called = 0;
    await tester.pumpWidget(_host(MomentDoubleTapHeart(
      isLiked: true,
      onLike: () => called++,
      child: const SizedBox(width: 200, height: 200),
    )));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('double-tap-heart')), findsNothing);
    expect(called, 0, reason: 'a double-tap must never un-like');
    await tester.pumpAndSettle();
  });

  testWidgets('GLOBAL CONSTRAINT: nothing animates when motion is disabled',
      (tester) async {
    var liked = 0;
    await tester.pumpWidget(_host(
      MomentDoubleTapHeart(
        isLiked: false,
        onLike: () => liked++,
        child: const SizedBox(width: 200, height: 200),
      ),
      disableAnimations: true,
    ));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('double-tap-heart')), findsNothing);
    expect(liked, 1, reason: 'the like must still register');
    await tester.pumpAndSettle();
  });

  testWidgets('a single tap does not like', (tester) async {
    var liked = 0;
    await tester.pumpWidget(_host(MomentDoubleTapHeart(
      isLiked: false,
      onLike: () => liked++,
      child: const SizedBox(width: 200, height: 200),
    )));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.pump(const Duration(milliseconds: 400));
    expect(liked, 0);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd bananatalk_app && flutter test test/moments/moment_double_tap_heart_test.dart`
Expected: FAIL — package not resolved.

- [ ] **Step 3: Write the widget**

```dart
import 'package:flutter/material.dart';

/// Wraps media so a double-tap likes it, with a heart that says so.
///
/// The gesture already worked before this existed; what was missing was any
/// feedback, so it read as not having registered and people tapped again --
/// which un-liked.
class MomentDoubleTapHeart extends StatefulWidget {
  const MomentDoubleTapHeart({
    super.key,
    required this.child,
    required this.isLiked,
    required this.onLike,
  });

  final Widget child;

  /// When true the double-tap does nothing at all. A double-tap is a LIKE
  /// gesture, not a toggle: making it un-like turns an enthusiastic second tap
  /// into an undo.
  final bool isLiked;

  final VoidCallback onLike;

  @override
  State<MomentDoubleTapHeart> createState() => _MomentDoubleTapHeartState();
}

class _MomentDoubleTapHeartState extends State<MomentDoubleTapHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  bool _showing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDoubleTap() async {
    if (widget.isLiked) return;
    widget.onLike();

    // Same check otp_code_field.dart makes: the action still happens, only the
    // motion is skipped.
    if (MediaQuery.of(context).disableAnimations) return;

    setState(() => _showing = true);
    await _controller.forward(from: 0);
    if (mounted) setState(() => _showing = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showing)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  // Up fast, then fade: the shape of a reaction rather than a
                  // loading indicator.
                  final scale = 0.6 + (t < 0.3 ? t / 0.3 : 1.0) * 0.6;
                  final opacity = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4);
                  return Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.favorite,
                        key: Key('double-tap-heart'),
                        color: Colors.white,
                        size: 92,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 12)],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests and watch them pass**

Run: `cd bananatalk_app && flutter test test/moments/moment_double_tap_heart_test.dart`
Expected: PASS, 5/5

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/moments/card/moment_double_tap_heart.dart bananatalk_app/test/moments/moment_double_tap_heart_test.dart
git commit -m "feat(moments): a heart that confirms the double-tap"
```

---

## Task 3 — use both in the feed and in detail

**Files:**
- Modify: `app/lib/pages/moments/card/moment_card_media.dart`
- Modify: `app/lib/pages/moments/single/moment_image_grid.dart`
- Test: `app/test/moments/moment_card_media_test.dart`

**Interfaces:**
- Consumes: `MomentMediaCarousel` (Task 1).
- Produces: `MomentCardMedia` gains `String? heroPrefix`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_media.dart';
import 'package:bananatalk_app/pages/moments/card/moment_media_carousel.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('three images use the carousel, not a grid', (tester) async {
    await tester.pumpWidget(_host(MomentCardMedia(
      imageUrls: const ['a.jpg', 'b.jpg', 'c.jpg'],
    )));
    await tester.pumpAndSettle();
    expect(find.byType(MomentMediaCarousel), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('one image uses the carousel too, for a consistent frame',
      (tester) async {
    await tester.pumpWidget(_host(MomentCardMedia(imageUrls: const ['a.jpg'])));
    await tester.pumpAndSettle();
    expect(find.byType(MomentMediaCarousel), findsOneWidget);
  });

  testWidgets('no images renders no carousel', (tester) async {
    await tester.pumpWidget(_host(MomentCardMedia(imageUrls: const [])));
    await tester.pumpAndSettle();
    expect(find.byType(MomentMediaCarousel), findsNothing);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd bananatalk_app && flutter test test/moments/moment_card_media_test.dart`
Expected: FAIL — `GridView` still found for three images.

- [ ] **Step 3: Replace `_buildImageGrid` in `moment_card_media.dart`**

Delete the 1-image, 2-image and 3+-grid branches and return the carousel. Keep the audio
branch untouched:

```dart
  Widget _buildImageGrid(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    // One widget for every count, so a 1-image post and a 5-image post have
    // the same frame and the feed keeps its rhythm.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MomentMediaCarousel(
        imageUrls: imageUrls,
        heroPrefix: heroPrefix,
      ),
    );
  }
```

Add the field and constructor parameter:

```dart
  /// When set, pages are Hero-tagged so tapping through to detail expands the
  /// image the reader was actually looking at.
  final String? heroPrefix;
```

- [ ] **Step 4: Point `moment_image_grid.dart` at the same widget**

Replace its `GridView.builder` with `MomentMediaCarousel(imageUrls: ..., heroPrefix: ...)`.
A carousel in the feed and a grid in detail is worse than either consistently.

- [ ] **Step 5: Run every app test**

Run: `cd bananatalk_app && flutter test && flutter analyze lib/`
Expected: green, zero analyzer errors. Any existing test asserting a `GridView` in a
moment card is asserting the behaviour being replaced — update it to the carousel
contract rather than weakening it.

- [ ] **Step 6: Commit**

```bash
git add bananatalk_app/lib bananatalk_app/test
git commit -m "feat(moments): carousel in the feed and in detail"
```

---

## Task 4 — stamp `hasActiveStory` on a moment's author

**Files:**
- Modify: `backend/controllers/moments.js`
- Test: `backend/test/momentAuthorStoryFlag.test.js`

**Interfaces:**
- Consumes: `usersWithVisibleActiveStory(userIds, viewerId, followingIds)` from `lib/activeStoryFlags.js`.
- Produces: every moment's `user` carries `hasActiveStory: boolean`.

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { visibleOwners, VISIBLE_PRIVACIES } = require('../lib/activeStoryFlags');

test('the helper this task depends on filters by privacy', () => {
  assert.ok(Array.isArray(VISIBLE_PRIVACIES) || VISIBLE_PRIVACIES instanceof Set);
  assert.equal(typeof visibleOwners, 'function');
});

test('a public story makes its owner visible', () => {
  const owners = visibleOwners(
    [{ user: 'u1', privacy: 'public' }],
    new Set()
  );
  assert.ok([...owners].map(String).includes('u1'));
});

test('a followers-only story is hidden from a non-follower', () => {
  const owners = visibleOwners(
    [{ user: 'u1', privacy: 'followers' }],
    new Set()
  );
  assert.equal([...owners].map(String).includes('u1'), false);
});
```

- [ ] **Step 2: Run it**

Run: `cd backend && node --test --test-force-exit test/momentAuthorStoryFlag.test.js`
Expected: PASS — this pins the helper's contract before relying on it. If a case fails,
read `lib/activeStoryFlags.js` and correct the test to the real contract before writing
the controller change; do not change the helper.

- [ ] **Step 3: Add the field and the stamp in `controllers/moments.js`**

Add `hasActiveStory` is NOT a stored field — it is computed. So leave `USER_FIELDS` as the
stored projection and stamp after the query. Directly after each place a page of moments
is fetched and before the response is built, add:

```js
  // One lookup for the whole page. lib/activeStoryFlags.js exists for exactly
  // this and says so: "callers stamp hasActiveStory on a whole page of users
  // from a single" lookup. A per-moment call would be 20 round trips on a
  // 20-card page for a decorative ring.
  await stampAuthorStoryFlags(moments, req.user);
```

And define the helper once near the top of the controller:

```js
const { usersWithVisibleActiveStory } = require('../lib/activeStoryFlags');

/**
 * Marks each moment's author with `hasActiveStory`, in one query per page.
 *
 * Anonymous callers get `false` throughout rather than a query: story
 * visibility depends on who is asking, and there is no one asking.
 */
const stampAuthorStoryFlags = async (moments, viewer) => {
  if (!Array.isArray(moments) || moments.length === 0) return;

  if (!viewer) {
    moments.forEach((m) => { if (m.user) m.user.hasActiveStory = false; });
    return;
  }

  const authorIds = [...new Set(
    moments.map((m) => m.user && m.user._id).filter(Boolean).map(String)
  )];
  if (authorIds.length === 0) return;

  const owners = await usersWithVisibleActiveStory(
    authorIds, viewer._id, viewer.following || []
  );

  moments.forEach((m) => {
    if (m.user) m.user.hasActiveStory = owners.has(String(m.user._id));
  });
};
```

Apply it in `getMoments`, `getReelsFeed`, `exploreMoments`, `getTrendingMoments` and
`getUserMoments` — wherever a page of moments is returned with a populated `user`.

- [ ] **Step 4: Run the backend suite**

Run: `cd backend && npm test`
Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add backend/controllers/moments.js backend/test/momentAuthorStoryFlag.test.js
git commit -m "feat(moments): tell the client which authors have a story"
```

---

## Task 5 — ring the author avatar

**Files:**
- Modify: `app/lib/providers/provider_models/moments_model.dart`
- Modify: `app/lib/pages/moments/card/moment_card_header.dart`
- Test: `app/test/moments/moment_author_ring_test.dart`

**Interfaces:**
- Consumes: `hasActiveStory` on the author payload (Task 4); `StoryGradientRing` from `lib/widgets/story/story_gradient_ring.dart`; the existing `onAvatarTap` callback.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/widgets/story/story_gradient_ring.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_header.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('an author with a story gets a ring', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      userName: 'Ana',
      userImageUrl: '',
      hasActiveStory: true,
      onAvatarTap: () {},
      timeAgo: '2h',
    )));
    await tester.pumpAndSettle();
    expect(find.byType(StoryGradientRing), findsOneWidget);
  });

  testWidgets('an author with no story gets no ring', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      userName: 'Ana',
      userImageUrl: '',
      hasActiveStory: false,
      onAvatarTap: () {},
      timeAgo: '2h',
    )));
    await tester.pumpAndSettle();
    expect(find.byType(StoryGradientRing), findsNothing);
  });

  testWidgets('tapping the ringed avatar fires onAvatarTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(MomentCardHeader(
      userName: 'Ana',
      userImageUrl: '',
      hasActiveStory: true,
      onAvatarTap: () => tapped++,
      timeAgo: '2h',
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StoryGradientRing));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd bananatalk_app && flutter test test/moments/moment_author_ring_test.dart`
Expected: FAIL — `MomentCardHeader` has no `hasActiveStory` parameter.

- [ ] **Step 3: Parse the flag**

In `moments_model.dart`, on whatever type holds a moment's author, add
`final bool hasActiveStory;` defaulting to `false`, and parse
`hasActiveStory: json['hasActiveStory'] == true`. Default false so a payload from an older
server simply shows no ring rather than throwing.

- [ ] **Step 4: Ring the avatar**

In `moment_card_header.dart`, add `final bool hasActiveStory;` and wrap the existing
`CachedCircleAvatar` at line 93:

```dart
        hasActiveStory
            ? GestureDetector(
                onTap: onAvatarTap,
                child: StoryGradientRing(child: avatar),
              )
            : avatar,
```

Pass `hasActiveStory: moment.user.hasActiveStory` from `moment_card.dart`, which already
holds an `onAvatarTap` callback for this purpose.

- [ ] **Step 5: Run everything**

Run: `cd bananatalk_app && flutter test && flutter analyze lib/`
Expected: green, zero analyzer errors.

- [ ] **Step 6: Commit**

```bash
git add bananatalk_app/lib bananatalk_app/test
git commit -m "feat(moments): a story ring on the author's avatar"
```

---

## Self-Review

**Spec coverage:**

| Spec section | Task |
|---|---|
| §2.1 carousel replaces grid | 1, 3 |
| §2.2 no silent truncation | 1 (cap notice + test) |
| §2.3 heart on double-tap | 2 |
| §2.4 Hero into detail | 1 (`heroPrefix`), 3 |
| §2.5 author story ring | 4 (server), 5 (client) |
| §3.1 fixed 4:5 | 1 (test) |
| §3.2 never on un-like | 2 (test) |
| §3.3 detail uses the carousel | 3 |
| §5 one query per page | 4 |
| §6 testing table | every task |

**Type consistency:** `MomentMediaCarousel({imageUrls, onPageChanged, heroPrefix})` keeps
one signature in Tasks 1 and 3. `kMomentImageCap` is used in Task 1 and asserted there.
`hasActiveStory` is the same name on the server (Task 4), the model and the header
(Task 5) — matching what `Community.hasActiveStory` already uses elsewhere in the app.

**Placeholders:** none.

**One risk worth naming:** Task 3 changes how every multi-image post looks, and existing
widget tests may assert the grid. Those assertions are the old contract — update them to
the carousel rather than loosening them, or the suite stops protecting anything here.
