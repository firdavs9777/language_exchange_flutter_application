# Step 5 — Moments Restructure + April Spec Audit — Design

**Date:** 2026-05-10
**Branch:** `refactor/step5-moments-restructure` (off `main`)
**Scope:** `lib/pages/moments/` (~7,608 lines, 14 files) + paired backend audit
**Shape:** Restructure-heavy wave with bundled cleanup + spec audit; mirrors community wave-1 and Step 3 stories cadence

## Goal

Three discrete wins, packaged as one wave:

1. **Folder restructure** of `lib/pages/moments/` into focused subfolders (mirror community / chat / stories pattern). 14 flat files → ~30+ focused files in 5-6 subfolders.
2. **Split the four big files** (`create_moment.dart` 2,278, `moment_card.dart` 1,237, `single_moment.dart` 1,015, `moment_filter_sheet.dart` 792) into focused units of ~400 lines max.
3. **Cleanup sweep + April spec audit + bug bounties** — 21 `withOpacity`, 25 `Colors.grey[*]`, 26 inline snackbars, 12 debug `print`/`debugPrint` statements (mostly heart-emoji love spam in `moment_card.dart`), plus a re-check of the two April specs (`moments-instagram-redesign.md`, `moments-comments-stories-modernize.md`) for stragglers and any minor features worth bundling.

## Non-goals (explicit)

- **No new big features** — the April specs are 90%+ shipped (per the catch-all `eeff4ec` "complete moments redesign" commit + several follow-up patches). Step 5 finishes the long-tail and structures.
- **No backend rewrite** — only schema verifications + minor controller adjustments where the audit reveals gaps.
- **No moments → stories integration** (e.g., cross-posting a moment to story). Out of scope.
- **No moment edit-after-post flow** — currently delete + recreate is the pattern; leave alone.
- **No comment translation** — out of scope.
- **No comment notifications redesign** — out of scope.

## Current state diagnostics

### Folder shape (~7,608 lines, flat)

| File | Lines | Smell |
|---|---|---|
| `create_moment.dart` | **2,278** | Biggest file in this wave. Single massive `StatefulWidget` with image/video pick, gradient text mode, location, scheduling, tag dialog, validation, post action |
| `moment_card.dart` | **1,237** | Card with two layouts (media + gradient-text), double-tap-to-like, action bar, comments preview, ad-every-3 logic. ~7 leftover heart-emoji `debugPrint` calls |
| `single_moment.dart` | **1,015** | Detail screen with comments thread, replies, reactions, viewer-list dialog |
| `moment_filter_sheet.dart` | **792** | Mood / category / language / privacy / mutual-only filter sections |
| `moments_main.dart` | 492 | Tab bar, feed list, embedded stories feed, filter button |
| `saved_moments_screen.dart` | 444 | Saved/bookmarked moments list |
| `video_player_widget.dart` | 401 | Video controls + state |
| `moment_filter_bar.dart` | 306 | Active-filter chip strip |
| `moment_filter_model.dart` | 244 | Filter state model |
| `moment_filter_utility.dart` | 159 | Filter helper functions |
| `moment_detail_wrapper.dart` | 100 | ID-based detail-screen wrapper (loads moment then renders SingleMoment) |
| `image_viewer.dart` | 98 | Full-screen image viewer for tap-on-photo |
| `action_widget.dart` | 42 | Tiny action button helper |
| `update_moment.dart` | 0 | Empty file (orphan — delete) |

### Cleanup debt

- **21 `.withOpacity(`** calls (deprecated)
- **25 `Colors.grey[*]`** instances
- **26 inline `ScaffoldMessenger.showSnackBar`** calls
- **2 TODO/FIXME** comments
- **~12 `debugPrint` statements** — most are the `❤️ ` heart-emoji love-spam from `cfe61cc` debug commit (`moment_card.dart:122,182,197,202,208,215,221,228,306`), `moment_detail_wrapper.dart:45`, and a few legitimate error logs in `create_moment.dart` (which can stay or be downgraded to silent catches)

### April spec status

Both `2026-04-19-moments-instagram-redesign.md` and `2026-04-19-moments-comments-stories-modernize.md` largely landed via `eeff4ec` (the catch-all "complete moments redesign, comments, stories & UI modernization" commit) and several follow-ups:

- ✅ `d7374a6` — gradient detection by `backgroundColor` + ads every 3 posts
- ✅ `454d4a7` — gradient preview in create form + tag dialog fix
- ✅ `56c6ffd` — gradient card in detail view + mood/tags/category display
- ✅ `51af66b` — drop reference to non-existent `Moments.title` getter

Remaining spec items (audit during execution; expected to be small):

- Re-verify the language-list sync (44 backend / Flutter alignment) per spec §6.2
- Re-verify `isDeleted` filter on all 3 endpoints (main feed, user moments, single moment) per spec §1.3
- Re-verify category + mood enums sync between backend and Flutter per spec §1.4 / §1.5
- Audit whether the dead `update_moment.dart` (0 bytes) is truly unused — verified during C2 deletion

### Single backward-compat concern

None obvious — moments has been actively iterated. The deprecated/removed `slugify` and `slug` field per spec §10 dropped already; old documents in DB still have the field but it's harmless.

---

## Architecture

### Target folder layout

```
lib/pages/moments/
├── widgets/                            NEW — shared scaffolding
│   ├── moments_snackbar.dart           showMomentsSnackBar()
│   ├── moments_dialog_scaffold.dart    rounded card for sheets
│   ├── moments_empty_state.dart
│   └── moments_error_state.dart
│
├── feed/                               NEW — was moments_main.dart (492)
│   ├── moments_main.dart               ~250 (tab bar + feed list shell)
│   ├── moments_feed_widget.dart        the actual feed list with ad insertion
│   └── moments_filter_button.dart      filter sheet trigger
│
├── card/                               NEW — was moment_card.dart (1,237)
│   ├── moment_card.dart                ~300 (orchestrator, branches by type)
│   ├── moment_card_media.dart          full-width image/video card
│   ├── moment_card_gradient.dart       gradient text-only card
│   ├── moment_card_header.dart         user avatar + name + timestamp + menu
│   ├── moment_card_actions.dart        like/comment/share/save bar
│   └── moment_card_double_tap.dart     overlay heart animation
│
├── single/                             NEW — was single_moment.dart (1,015)
│   ├── single_moment.dart              ~400 (composes header + content + comments)
│   ├── single_moment_header.dart       back button + share + report row
│   ├── single_moment_content.dart      media/gradient render + caption/tags
│   ├── single_moment_comments.dart     comment thread list
│   ├── single_moment_reactions.dart    reactions row + viewers list
│   └── comment_input_bar.dart          composer at bottom
│
├── create/                             NEW — was create_moment.dart (2,278)
│   ├── create_moment.dart              ~500 (orchestrator)
│   ├── create_image_section.dart       photo/video picker + preview
│   ├── create_text_section.dart        gradient text composer
│   ├── create_chips_row.dart           mood/category/language compact chips
│   ├── create_tag_dialog.dart          tag-add modal
│   ├── create_location_picker.dart     location auto-detect + manual override
│   ├── create_schedule_picker.dart     scheduled-publish toggle
│   ├── create_privacy_picker.dart      public/friends/private dropdown
│   └── create_post_action.dart         the post button + submission logic
│
├── filter/                             NEW — was moment_filter_sheet.dart (792)
│   ├── moment_filter_sheet.dart        ~200 (shell)
│   ├── filter_mood_section.dart
│   ├── filter_category_section.dart
│   ├── filter_language_section.dart
│   ├── filter_privacy_section.dart
│   ├── filter_other_section.dart       newest-only, mutual-only, etc.
│   ├── moment_filter_bar.dart          MOVED (active-chip strip)
│   ├── moment_filter_model.dart        MOVED
│   └── moment_filter_utility.dart      MOVED
│
├── viewer/                             NEW — image/video viewer
│   ├── image_viewer.dart               MOVED
│   └── video_player_widget.dart        MOVED
│
├── saved/                              NEW
│   └── saved_moments_screen.dart       MOVED
│
└── moment_detail_wrapper.dart          STAYS at root (small, deep-link entry)
```

**Total folders:** 8 (`widgets/`, `feed/`, `card/`, `single/`, `create/`, `filter/`, `viewer/`, `saved/`). Total files end at ~30 (was 14). Each new file targets ≤400 lines.

### Files to delete

- `lib/pages/moments/update_moment.dart` (0 bytes, orphan).
- `lib/pages/moments/action_widget.dart` (42 lines) — verify whether anything imports it; if not, delete. If only used inside `moment_card.dart`, fold it into the card subfolder as a private widget.

### Files that stay put

- `lib/widgets/ads/ad_widgets.dart` — used inline in the feed for ad-every-3 logic; not moments-specific.
- `lib/providers/provider_models/moments_model.dart` — model stays at provider-models layer.
- `lib/providers/provider_root/moments_providers.dart` — provider stays at root layer.
- `lib/services/moments_service.dart` (if exists) — service stays.

### Cleanup passes

1. **Snackbar migration** (~26 sites) → `showMomentsSnackBar()` helper. Skip `Row`-content snackbars (icon + text) per past wave pattern.
2. **`withOpacity` sweep** (21 sites) → `withValues(alpha:)`.
3. **`Colors.grey[*]` migration** (25 sites) → `context.containerColor` / `dividerColor` / `textMuted` / `textSecondary` per the wave-1 mapping. **Exception:** white-on-color buttons (`foregroundColor: Colors.white` paired with a colored `backgroundColor`) and white text on colored gradient cards stay.
4. **Debug `debugPrint` cleanup** — purge the ~9 `❤️` heart-emoji statements from `moment_card.dart` (the `cfe61cc` debug commit residue). Keep legitimate error-path `debugPrint` calls unchanged or downgrade to silent catches per project pattern.
5. **`update_moment.dart`** orphan deletion.
6. **`action_widget.dart`** verification + retire if unused.

### April spec audit (during execution)

C-numbered audit task verifies these spec sub-bullets are in current code:

- §1.3 (backend `isDeleted` filter on getMoments / getUserMoments / getMoment endpoints — check `controllers/moments.js`)
- §1.4 (category enum sync between `Moment.js` schema and Flutter create form)
- §1.5 (mood enum sync between `Moment.js` schema and Flutter create form — list of 12 canonical moods)
- §1.6 (translation endpoint accepts moment text — verify `/translate` route honors moments)
- §6.1 / §6.2 (translation buttons wired + language lists synced — Flutter side)
- §10 keys 11-13 (mounted/dispose, isDeleted, dead slug code) verified

Any straggler that didn't land becomes a remediation commit during the wave. Expected total: ≤5 small commits.

### Minor features bundled (light-touch)

These small adds are natural for a moments wave and don't need their own spec:

- **Save-to-collection (bookmarks)** UX polish — `saved_moments_screen.dart` already exists; verify the save toggle on `moment_card_actions.dart` is wired correctly + has a snackbar. Likely just verification, not new code.
- **Tag autocomplete** in create — when user types a tag in `create_tag_dialog.dart`, suggest from their last 10 used tags (stored in SharedPreferences `recent_moment_tags`). Tiny feature, ~1 commit.
- **Hide-this-user's-moments** quick-action on the moment card menu (3-dot button) — adds the user's id to a local-only `mutedMoments` set in SharedPreferences; feed filters them out client-side. ~1 commit. Avoids the heavier "block" flow which already exists separately.

---

## Cross-cutting

### l10n plan

~12-15 new ARB keys (English + 17 locale translations):

| Group | Keys (approx) |
|---|---|
| Moments snackbar / empty / error | `momentsEmpty`, `momentsLoadError`, `momentsRetry` |
| Tag autocomplete | `recentTags`, `noRecentTags` |
| Mute user's moments | `hideMomentsFromUser`, `momentsHidden`, `unhideMoments` |
| Save toggle | `momentSaved`, `momentUnsaved`, `momentSaveFailed` |
| Verifications during audit | (variable; only if audit reveals stale strings) |

### Testing

- `flutter analyze` clean per commit.
- Backend unit tests for the audit findings (only if a fix is committed).
- Manual smoke: create gradient text moment, post, verify card renders correctly; double-tap to like; comment + reply; viewers list opens; save/unsave; hide-this-user → verify moments disappear from feed; restart app → verify hidden state persists.

### Risk register

| Risk | Mitigation |
|---|---|
| Folder restructure breaks imports app-wide (moments is referenced from chat reply previews, profile moments tab, search results, deep links) | Single-PR mass-move with `git mv`, analyzer enforcement, manual smoke per entry point. Past 4 restructures used the same approach without regressions |
| `create_moment.dart` 2,278-line split has tightly-entangled state | Pragmatic guardrail (used in Step 3 C8): if extraction adds complexity vs. file count, do `git mv` only and leave the body intact. Splits in `create/` are the goal but not all are forced |
| `moment_card.dart` two-layout split (media vs gradient) breaks one of the layouts | Branching is already in the existing code (`d7374a6` added the gradient-detection logic). Extract the shared header+actions, then branch on `storyType`/`backgroundColor` into the two layout files |
| Debug `debugPrint` cleanup loses useful diagnostic | The 9 `❤️` calls in moment_card.dart are clearly debug (per `cfe61cc` commit message "add logging to user moments API call"). Removing them = restoring pre-debug state. The 3-4 legitimate error catches in create_moment.dart stay |
| Audit reveals a backend issue that requires schema migration | Document inline; if migration is heavy, defer to follow-up wave. The April specs are mostly shipped, so this is unlikely |
| `update_moment.dart` is referenced via reflection or dynamic import (Flutter doesn't really do this) | Trivial check: `git grep update_moment` returns zero outside-of-the-file matches → safe to delete |

---

## PR / commit breakdown

| # | Commit | Type |
|---|---|---|
| C0 | `chore(moments)`: branch + deps audit | chore |
| C1 | `chore(moments)`: delete `update_moment.dart` orphan + verify `action_widget.dart` | chore |
| C2 | `chore(moments)`: purge heart-emoji `debugPrint` from moment_card | chore |
| C3 | `refactor(moments)`: ARB keys (en) ~14 keys | refactor |
| C4 | `refactor(moments)`: translate ARB keys to 17 locales | refactor |
| C5 | `refactor(moments)`: add `widgets/` scaffolding (snackbar, dialog, empty, error) | refactor |
| C6 | `refactor(moments)`: migrate ~26 inline snackbars to `showMomentsSnackBar` | refactor |
| C7 | `fix(moments)`: withOpacity → withValues + Colors.grey theme migration | fix |
| C8 | `refactor(moments)`: move filter files into `filter/` subfolder + split `moment_filter_sheet` | refactor |
| C9 | `refactor(moments)`: move feed files into `feed/` subfolder + split `moments_main` | refactor |
| C10 | `refactor(moments)`: split `moment_card` into `card/` subfolder | refactor |
| C11 | `refactor(moments)`: split `single_moment` into `single/` subfolder | refactor |
| C12 | `refactor(moments)`: split `create_moment` into `create/` subfolder (mostly extract; `git mv`-only fallback if entangled) | refactor |
| C13 | `refactor(moments)`: move `image_viewer` + `video_player_widget` into `viewer/` subfolder | refactor |
| C14 | `refactor(moments)`: move `saved_moments_screen` into `saved/` subfolder | refactor |
| C15 | `feat(moments)`: April spec audit + remediation | feat (or chore if all green) |
| C16 | `feat(moments)`: tag autocomplete (recent tags from SharedPrefs) | feat |
| C17 | `feat(moments)`: hide-this-user's-moments local mute toggle | feat |
| C18 | `chore(moments)`: final analyzer + smoke + push + PR | chore |

**Total: 19 commits, ~5-6 weeks.** Smaller than originally estimated (was ~30-40) because the April specs largely landed; Step 5 is restructure-heavy with light feature work.

---

## Future / deferred

- Comment translation
- Cross-post moment → story
- Moment edit-after-post flow
- Reactions on comments (different from moment reactions)
- Hide-this-user's-moments → server-side mute (currently local-only, ~1 commit. Server-side is its own design round)
- Moment search (text/tag query)
- Hashtag detection in moment description (`#travel` → tap to filter)
