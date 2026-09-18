# Community Discovery & Profile Detail — Design

**Date:** 2026-09-18
**Status:** approved, ready for implementation planning
**Goal:** make the Community partner list dense enough to browse and the profile detail
screen reachable enough to act on, without borrowing another app's visual language.

**Scope:** app-only. No backend change, no API change, no new field on any model.
The matching work this conversation also uncovered is a separate spec
(`2026-09-18-matching-design.md`) and is deliberately not mixed in here.

---

## 1. Where this came from

The reference given was HelloTalk: a pinned Follow/Chat bar on the profile, and a
denser partner list. The explicit instruction after seeing a first pass was **not** to
copy it — to solve the same two problems in our own design language.

That matters, because our tokens point the opposite way from HelloTalk's. Ours
(`lib/core/theme/app_theme.dart`) are teal `#00BFA5`, banana `#FFD54F`, radii 12–24,
and deliberately soft shadows (`AppShadows.sm/md/lg` at 4%/6%/8% alpha). HelloTalk is
flat grey hairlines and purple. Flattening our list into hairline rows would fix the
density and lose the app.

So: keep the rounded, shadowed, teal identity. Fix what is actually broken about it.

---

## 2. The two problems

### 2.1 The detail screen's primary action scrolls away

`single_community_screen.dart:557` mounts `SingleCommunityActions` as a
`SliverToBoxAdapter` between the header and the pinned tab bar. It is not pinned.

Once the user scrolls into Moments or About — which is the entire point of the screen —
Follow, Message and Wave are all off-screen. There is no way to start a conversation
without scrolling back up. On a language-exchange app, starting the conversation is the
only action that matters.

### 2.2 The partner list spends a screen on two people

`CommunityCard` is a 24-radius container with `AppShadows.md`, 20px padding and 16px
bottom margin, stacking four blocks:

1. header (avatar 64 + name + location + wave button)
2. `buildLanguageExchange` — two grey chips, "Korean · Native" and "English · B1"
3. bio
4. `buildFooter` — follower/moment stat chips and a "View Profile →" button

At that height roughly two people fit on a phone screen. Two of those blocks do not earn
their space:

- **The footer's "View Profile →" button** is a second control doing exactly what tapping
  anywhere on the card already does.
- **The stat chips** (follower count, moment count) are not how anyone picks a language
  partner.

And the thing that *would* make someone tap — why this person is worth their time — is
not on the card at all.

---

## 3. Design

### 3.1 The partner row

One row per person. Radius 20, `AppShadows.sm`, 14px padding, 8px vertical gap,
surface-coloured. Still a card; simply not a poster.

```
┌────────────────────────────────────────────────────┐
│ ◉54  Yeonwoo  VIP                            ( 👋 )│
│      ╭─────────────────────╮                       │
│      │ KR ●●● ⇄ EN ●○○     │  ← teal pill          │
│      ╰─────────────────────╯                       │
│      Hi I am yeonwoo. I am from korea.             │
│      ✦ New   Similar age                           │
└────────────────────────────────────────────────────┘
```

Two new widgets, both pure and testable in isolation:

**`CommunityLanguagePill`** — replaces `buildLanguageExchange`'s two grey chips with one
teal pill carrying both sides and a three-dot proficiency indicator. Reads
`native_language`, `language_to_learn` and `languageLevel` off `Community`. On a language
app the exchange pair is the single most important fact on the card; two neutral grey
blocks is not how you say that.

Dot mapping: `A1/A2 → ●○○`, `B1/B2 → ●●○`, `C1/C2 → ●●●`, native side always `●●●`,
`languageLevel` null → no dots rendered on that side (not zero dots — absent, so a
missing level never reads as "beginner").

**`CommunityMatchTags`** — up to two chips, derived on-device from `(candidate,
currentUser)`. No network, no new field:

| Tag | Condition | Style |
|---|---|---|
| `New` | `candidate.isNewUser` (already on the model, ≤6 days) | banana |
| `Similar age` | both ages known and within 3 years | teal |
| `Both like X` | first overlapping entry in `topics` | teal |
| `Replies fast` | `responseRate >= 80` | teal |

Evaluated in that order, first two taken. When none apply the strip renders nothing and
the row gets shorter — an empty tag strip must not reserve height.

The current user comes from `userProvider`, so `CommunityMatchTags` is a `ConsumerWidget`
and the derivation itself is a top-level pure function taking both users — the function
is what gets unit-tested, not the widget.

**Removed:** `buildFooter`, `_buildStatChip`, `_buildViewProfileButton`, and
`_buildLocationRow` (city/country moves into the tag strip only as a last-resort tag when
nothing better applies).

**Entrance animation:** the current 500ms staggered fade + slide + `easeOutBack` scale is
tuned for two big cards. At four rows per screen the stagger reads as the list lagging
behind the scroll. Replaced with a 150ms fade, no slide, no scale.

### 3.2 The tab strip becomes pill chips

`CommunityTabBar` becomes `CommunityChipBar`: a horizontally scrollable row of fully
round chips. Selected is teal fill, white label, soft teal shadow; unselected is surface
with a `gray300` border. Icons drop — at eight entries the icon+label pairs are what make
the strip feel crowded. The Waves unread dot stays.

**All eight destinations stay exactly where they are.** This is a rendering change only.
The `TabController`, the `TabBarView`, `remapTabIndexForRoomsFlag`, `_roomsInsertionIndex`
and both server kill switches (`roomsEnabled`, `gatheringsEnabled`) are untouched. That
index arithmetic is load-bearing and subtle; nothing here goes near it.

The existing active-filter chip row below keeps its tonal grey + `×` treatment
specifically so two rows of pills do not read as one confusing control surface.

### 3.3 The detail screen's pinned action bar

`SingleCommunityActions` → `SingleCommunityActionBar`, moved out of the sliver list into a
`Stack` layered over the `NestedScrollView`.

- Floating: 14px insets, fully round, translucent surface with a blur, `AppShadows.lg`.
- `Follow` outlined teal (`Following` outlined neutral once followed) · `Chat` teal
  gradient at `flex: 1.4` · `Wave` round tonal icon button.
- Bottom inset respects `MediaQuery.of(context).padding.bottom`.
- Hidden entirely on your own profile, as the wave button already is.

Because it floats, both tab bodies (`SingleCommunityMoments`, `SingleCommunityAbout`) need
bottom padding equal to the bar height + insets, or the last grid row and the last About
entry sit underneath it. This is the one real cost of floating over docking, and it is
paid explicitly in both children rather than left to chance.

The header reclaims the vertical space the action row used to occupy, so avatar, name,
language pill and the three stats now sit above the fold and the Moments grid starts
higher.

**Conversation-starter ribbon:** stays on the screen, directly above the bar, as a
dismissible banana strip. Dismissal is per-screen (`setState`), not persisted — a
persisted dismissal needs a storage key per target user, which is not worth it for a
suggestion that changes as the profile does.

---

## 4. What is explicitly not changing

Avatar and story-ring behaviour (`_onAvatarTap`, `showAvatarActionSheet`), block/report,
the follow and wave network calls, the profile-view limit gate, the filter sheet, the
search flow, and every tab body except for the bottom padding named in §3.3.

---

## 5. Testing

- Unit: the `CommunityMatchTags` derivation — each tag's condition, the ordering, the cap
  of two, and the case where none apply.
- Widget: `CommunityLanguagePill` renders both sides and the right dot counts, including
  the null-`languageLevel` case.
- Widget: `CommunityChipBar` selection follows `TabController.index`, and tapping a chip
  animates the controller to that index.
- Widget: the partner row lays out without overflow at 320pt with a long name, a long bio
  and two tags — the 61-pixel gathering-card overflow found in 2.4.0 was exactly this
  shape of bug, caught by exactly this shape of test.
- Widget: the action bar is present while the detail screen is scrolled to Moments — the
  regression this whole spec exists to prevent.
- Widget: the action bar is absent on your own profile.

`test/community/gathering_card_layout_test.dart` is unaffected.

---

## 6. Risks

- **Density versus reach.** Four rows per screen means four wave buttons per screen. If
  wave volume jumps, the one-wave-per-pair rule (already enforced backend-side via
  `ALREADY_WAVED`) is what holds; no new limit is introduced here.
- **Tag honesty.** `Both like X` reads `topics`, which many profiles leave empty. The
  strip renders nothing rather than inventing a reason — an empty strip is correct output,
  not a bug to pad.
- **`languageLevel` coverage.** Where it is null the pill shows the pair without dots. It
  must not fall back to a guessed level.
