# Moments Feed & Detail — Design

**Date:** 2026-09-18
**Status:** approved, ready for implementation planning
**Goal:** fix what is wrong underneath the moments feed — duplicated counts, a fake
proficiency indicator, unsafe text truncation, and a detail screen that can do less than
the card that links to it.

**Scope:** app-only. No backend, no API, no new model field.

**Relationship to other specs.** `2026-09-17-moments-feed-ui-design.md` shipped the
carousel, the confirming heart, the staged composer and author story rings. None of that
is touched here. `2026-09-18-community-ui-design.md` introduces
`CommunityLanguagePill`; §3.1 below promotes it to a shared widget these screens use too,
so the two specs must be planned together.

---

## 1. Problems

### 1.1 Every count is rendered twice

`moment_card.dart:873` adds an "Engagement counts" block — `189 likes` over
`21 comments` — directly beneath an action row that already shows
`❤ 189` and `💬 21` (`moment_card.dart:800-836`). The same two numbers, one on top of
the other, on every card that has any engagement at all.

### 1.2 The proficiency dots are a constant

`moment_card_header.dart:181`:

```dart
children: List.generate(5, (index) {
  ... color: index < 3 ? context.textSecondary : context.dividerColor,
```

Five dots, three always filled. Every user, every card, regardless of `languageLevel`.
It reads as data and is decoration. On a language-exchange app, a proficiency indicator
that is the same for a beginner and a C2 speaker is worse than no indicator.

### 1.3 Truncation slices UTF-16

`moment_card.dart:597-599`:

```dart
final shouldShowMore = fullText.length > 150;
final displayText = !isExpanded && shouldShowMore
    ? '${fullText.substring(0, 150)}...'
```

`String.length` and `substring` count UTF-16 code units. A caption with an emoji straddling
index 150 is cut mid-surrogate-pair and renders as a replacement glyph. The app ships in 19
locales and the feed is full of emoji; this is a visible defect, not a theoretical one.

It also mis-measures: a 150-code-unit Korean caption is 150 characters, but a 150-code-unit
caption containing ten emoji is 140 — so the "show more" threshold varies by script.

### 1.4 The card is neither a card nor a row

`moment_card.dart:614` sets `BorderRadius.circular(0)` on a `Container` that has a 12px
horizontal margin and no border, no divider and no shadow. Detached from the edges like a
card, but with none of a card's edges. Our tokens (radius 12–24, `AppShadows.sm/md`) say
what this should look like and it does not.

### 1.5 The feed cannot follow anyone

A discovery feed of strangers with no follow affordance. The only way to act on a post you
like is to open the author's profile and act there.

### 1.6 Detail can do less than the card

`single_moment.dart:777-800` gives detail like, comment and share. The card additionally
has **save** in its action row and an inline **Translate** chip under the caption.

So a user can translate a caption truncated to 150 code units in the feed, and cannot
translate the full caption on the screen that exists to show the full caption.

---

## 2. Design

### 2.1 One shared language pill

`CommunityLanguagePill` (from the community spec) is promoted out of
`lib/pages/community/` into `lib/widgets/language/language_exchange_pill.dart` and used by
both the partner row and `MomentCardHeader`.

It reads `languageLevel` and renders `A1/A2 → ●○○`, `B1/B2 → ●●○`, `C1/C2 → ●●●`, native
side always `●●●`, and **nothing at all when the level is null** — absent, not zero dots,
so a missing level never reads as "beginner".

This deletes the header's hand-rolled native-underline + arrow + five fake dots, deletes
the partner card's two grey language chips, and leaves one implementation of the single
most important fact on either screen.

### 2.2 One count, in the action row

The engagement-counts block at `moment_card.dart:873` is removed. The action row keeps
`❤ N` and `💬 N`, which are tappable and already the place people look.

The reaction chips below are **not** counts of the same thing and stay.

### 2.3 Safe truncation

Replace the manual `substring` with the text engine's own clamping:

```dart
Text(fullText, maxLines: isExpanded ? null : 4, overflow: TextOverflow.ellipsis)
```

`maxLines` clamps on grapheme clusters, so no emoji or Hangul syllable is ever split, and
"4 lines" is the same visual promise in every script — which 150 code units is not.

"Show more" must then key off *whether the text actually overflowed*, not off a length
guess: measure with a `TextPainter` (or `LayoutBuilder` + `didExceedMaxLines`) and only
render the toggle when it did. A caption of 300 short-line-broken characters may not
overflow four lines; today it always shows the toggle.

### 2.4 The card becomes a card

Radius 20, `AppShadows.sm`, surface colour, 12px side margin, 10px gap — deliberately the
same treatment as the community partner row in the paired spec, so the two main browse
surfaces stop looking like different apps.

### 2.5 Follow on the card header

A compact outlined teal `Follow` pill in the header, collapsing to `Following` once
followed, hidden on your own posts.

It reuses the community follow flow rather than reimplementing it: same service call, same
`userProvider`/`communityProvider` invalidation. This is a wiring change, not new
behaviour, and it is the reason this spec should be implemented after the community one.

### 2.6 Detail reaches parity

`single_moment.dart` gains, in its existing action row, **save** (same
`_toggleSave` semantics as the card) and the inline **Translate** chip under the full
caption (same `MomentTranslateChip` → `TranslatedMomentWidget` pair).

Detail also gains a liker avatar row — up to five avatars and `N Likes ›` — placed between
the action row and the comments divider.

**Not** moved to detail: the reaction picker's long-press, which stays a card interaction.

---

## 3. Explicitly not changing

The media carousel, the double-tap heart, story rings, the staged composer, reels, the
filter bar and sheet, comments and corrections, the ad placements, and the inline
Translate chip's position on the card (it was deliberately moved out of the action row for
discoverability — see the comment at `moment_card.dart:648-652`).

---

## 4. Testing

- Unit: the shared pill's level→dots mapping, including null (renders no dots) and an
  unrecognised level string.
- Widget: a caption containing an emoji at the truncation boundary renders no replacement
  glyph — the regression test for §1.3, and the reason that fix is worth shipping.
- Widget: "show more" is absent when the caption does not overflow, present when it does.
- Widget: the card renders exactly one like count and one comment count (guards §1.1 from
  coming back).
- Widget: Follow is absent on your own post.
- Widget: detail renders save and translate affordances.
- Golden-ish: card lays out without overflow at 320pt with a long name, VIP badge, language
  pill and post-language chip all present — the header is now the busiest row on the screen.

---

## 5. Risks

- **The shared pill lands in two screens at once.** A regression in it is a regression in
  both browse surfaces. It is pure and fully unit-tested for that reason, and it is the
  first task in the plan so everything else builds on a tested widget.
- **`TextPainter` measurement cost.** Measuring every caption on every build would be
  wasteful in a scrolling list; measurement must be cached per caption/width, or done via
  `LayoutBuilder` once per layout rather than per frame.
- **Follow state on the card can go stale** when the same author appears in several posts
  in one feed. It must read follow state from the provider rather than local `setState`,
  or two cards by one author will disagree after a tap.
