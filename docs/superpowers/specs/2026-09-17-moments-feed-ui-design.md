# Moments Feed & Detail, and Story Rings on Authors — Design

**Date:** 2026-09-17
**Status:** approved, ready for implementation planning
**Goal:** make the moments viewing path read the way people expect a photo feed to
read, and let a moment's author show a story ring like every other avatar in the app
already does.

---

## 1. What is already there

Worth stating first, because it narrows the work considerably. The moments UI is further
along than "make it Instagram-like" suggests:

- Double-tap to like, and long-press for a reaction picker, both on `moment_card.dart`.
- A 3-up grid of a user's posts on their profile.
- A story viewer with tap-to-advance, pause, replies, mentions and progress segments.
- Reels with a controller pool and prefetch.
- `StoryGradientRing`, wired into the chat list, the stories feed, the viewer's own
  profile, another user's profile header, and three community widgets
  (`partner_card`, `partner_list_item`, `compact_user_tile`).

None of that is rebuilt here.

---

## 2. The gaps

### 2.1 Multiple images render as a grid, not a carousel

`moment_card_media.dart:116` lays images out with
`GridView.builder(crossAxisCount: 3)`. That is the WeChat Moments pattern: small square
tiles, several at once. A photo feed people recognise is full-width, one image at a time,
swiped, with a dot indicator.

### 2.2 The grid silently drops images

```js
itemCount: imageCount > 6 ? 6 : imageCount
```

A nine-image post renders six. The other three are unreachable — not collapsed behind a
"+3", simply absent. The poster has no way to know.

### 2.3 Double-tap likes, and nothing happens on screen

The gesture works and the like is recorded, but there is no animation of any kind — no
scale, no fade, nothing. A gesture with no feedback reads as a gesture that did not
register, so people tap again, which un-likes.

### 2.4 Tapping into detail cuts, it does not transition

No `Hero`, so the image the reader was looking at vanishes and a new screen appears. The
continuity that makes a feed feel like one surface is missing.

### 2.5 A moment's author can never show a story ring

This one is server-side, which is why no amount of Flutter work would have fixed it.

`controllers/moments.js`:

```js
const USER_FIELDS = 'name email bio images native_language language_to_learn';
```

No `hasActiveStory`, and `moments.js` never calls `lib/activeStoryFlags.js` — which
already exists and is used by `users.js`, `community.js` and `messages.js`. So
`moment_card_header.dart`'s `CachedCircleAvatar` has no flag to render a ring from.

`moment_card.dart` already carries an `onAvatarTap` callback for exactly this purpose. It
is currently unused for stories.

---

## 3. Decisions

| Question | Decision |
|---|---|
| Image sizing | **Fixed 4:5 portrait, crop to fill** |
| Image cap | 10, and stated — not silently truncated |
| Heart animation | On **like only**, never on un-like |
| Reduced motion | Honoured, following `otp_code_field.dart` |
| Detail view | Same carousel as the feed |

### 3.1 Why a fixed ratio

Every card the same height gives the feed a predictable rhythm: the reader knows where the
next post begins without looking. Letting each post set its own height makes scrolling
jumpy, and letterboxing to avoid cropping makes a feed of mixed orientations look
unfinished rather than designed.

The cost is real and accepted: a panorama loses its edges in the feed. Tapping through to
detail shows the same 4:5 crop — consistency between the two matters more than recovering
the edges in one of them.

### 3.2 Why the heart never animates on un-like

Un-liking is a correction. Animating it celebrates the removal, which reads as confirming
the wrong action. Instagram makes the same choice and it is worth copying.

### 3.3 Why detail gets the carousel too

A carousel in the feed and a grid in detail is worse than either consistently: swiping
works, then stops working, at the exact moment the reader has expressed more interest.

---

## 4. Components

| Unit | Purpose | Depends on |
|---|---|---|
| `moments/card/moment_media_carousel.dart` | **new** — render a `List<String>` as a swipeable 4:5 carousel with dots | nothing |
| `moments/card/moment_double_tap_heart.dart` | **new** — the burst overlay, motion-aware | nothing |
| `moments/card/moment_card_media.dart` | use the carousel instead of the grid | carousel |
| `moments/single/moment_image_grid.dart` | use the carousel | carousel |
| `moments/card/moment_card_header.dart` | ring the author avatar | `hasActiveStory` |
| `backend/controllers/moments.js` | stamp `hasActiveStory` per page | `activeStoryFlags` |
| `app/lib/providers/.../moments_model.dart` | parse `hasActiveStory` on the author | — |

`MomentMediaCarousel` takes a list of URLs and an optional `onPageChanged`, and nothing
else. That is what makes it testable without a network, a provider or a moment.

---

## 5. The story-ring fix, precisely

`getMoments`, `getReelsFeed`, `getMoment` and the other moment readers each already
`.populate('user', USER_FIELDS)`. The change is:

1. Add `hasActiveStory` to what the client receives for a moment's author.
2. After the page is fetched, call `usersWithVisibleActiveStory(authorIds, viewerId,
   followingIds)` **once for the whole page** and stamp the result.

One query per page, not per moment. `lib/activeStoryFlags.js` says so itself: *"callers
stamp `hasActiveStory` on a whole page of users from a single"* lookup. A per-moment
lookup on a 20-card page would be 20 round trips for a decorative ring.

The flag respects story privacy already — `visibleOwners` filters on
`VISIBLE_PRIVACIES` and the viewer's following set — so a private story does not leak a
ring to someone who could not watch it.

**Expected visible result: one new ring, in the moments feed.** Every other surface the
request named already has it.

---

## 6. Testing

| Property | Where |
|---|---|
| A 9-image post exposes all 9 | carousel widget test |
| Beyond 10 is capped, and the cap is visible | carousel widget test |
| Dots track the current page | carousel widget test |
| A single image shows no dots | carousel widget test |
| The heart fires on like | card widget test |
| **The heart does NOT fire on un-like** | card widget test |
| Nothing animates when `disableAnimations` is set | card widget test |
| Hero tags match between card and detail | widget test |
| No overflow at 320pt | widget test |
| `hasActiveStory` is stamped in ONE query per page | controller test |
| No ring when the author's story is not visible to the viewer | controller test |

The un-like case is the one to keep if anything is cut: it is the difference between an
animation that confirms and one that misleads.

---

## 7. Explicitly not in this spec

- **Story viewer polish** — swipe-down dismiss, quick reactions. Its own spec.
- **The `create_moment` restructure** — 2,634 lines, a different kind of work, and
  posting already functions.
- **Rebuilding rings on community, profile or chat.** Already built. If one is not
  appearing, that is a defect to diagnose, not a feature to write.
- **Changing how images are stored or cropped server-side.** The 4:5 frame is a display
  decision; the originals are untouched.

---

## 8. Risk

The carousel changes how every multi-image post looks, and 4:5 crops photos that the grid
showed whole. That is the trade accepted in §3.1, and it is the one decision here that
would be expensive to revisit — people form an impression of a feed's shape quickly.

The smaller risk is the story flag becoming an N+1: it is a decorative ring, and it must
never cost a query per card. §5 fixes the shape; the test pins it.
