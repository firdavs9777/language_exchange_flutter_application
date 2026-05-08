# Step 3 — Stories Restructure + Ship April Spec Features — Design

**Date:** 2026-05-09
**Branch:** `refactor/step3-stories-restructure` (off `main`)
**Scope:** `lib/pages/stories/` (canonical) + delete `lib/pages/story/` (orphan) + paired backend
**Shape:** Restructure wave with bundled feature work — mirror community wave-1 cadence

## Goal

Three discrete wins, packaged as one wave:

1. **Delete `lib/pages/story/`** (4,775 lines, zero importers) — pure dead-code retirement.
2. **Restructure `lib/pages/stories/`** into subfolders with the canonical viewer collapsed and a cleanup sweep.
3. **Ship the unlanded April spec features** (`docs/superpowers/specs/2026-04-19-story-enhancements.md`): text stories with gradient backgrounds, highlights finish, overlays/stickers.

Mirror the community wave-1 + Step 2 cadence: deps → ARB → cleanup → splits → features → polish → PR. Backend changes commit to `main` of the paired backend repo (no feature branch over there per project pattern).

## Non-goals (explicit)

- **No music on stories** — explicitly deferred in the April spec, stays deferred.
- **No story analytics** ("seen by" counts, view-lists) — out of scope, defer to a future round.
- **No cross-posting story → moment** — out of scope.
- **No story replies (DM-style)** — covered by Step 5 moments-comments-modernize work if relevant.
- **No story reactions** — defer.
- **No custom sticker packs** — system emoji only per April spec.
- **No moments folder work** — that's Step 5.
- **No new viewer features beyond the April spec** — overlays/stickers are the only viewer-rendering additions.

## Current state diagnostics

### Two parallel folders (the headline issue)

| Folder | Lines | Files | Status |
|---|---|---|---|
| `lib/pages/stories/` (plural) | 5,026 | 5 + `widgets/overlay_editor.dart` | **Canonical** — all real importers point here |
| `lib/pages/story/` (singular) | 4,775 | 5 (`close_friends_screen`, `story_archive_screen`, `story_creation_screen`, `story_highlights_screen`, `story_viewer_screen`) | **Dead code** — `grep -rln "pages/story/" lib/` returns zero matches |

**Verified:** all live importers (`moments_main.dart`, `profile/highlights.dart`, etc.) reference `lib/pages/stories/` (plural). The singular folder is unreachable from any wired-up entry point.

### Canonical folder (`lib/pages/stories/`) shape

| File | Lines | Smell |
|---|---|---|
| `modern_story_viewer.dart` | 1,578 | Newer-style viewer (name implies it); both this and `story_viewer_screen.dart` have importers |
| `story_viewer_screen.dart` | 1,323 | Older viewer; partial migration left behind. Need to investigate which is actually used in the live flow before retiring one |
| `create_story_screen.dart` | 899 | Single big file, no tabs structure for the upcoming text-story addition |
| `modern_stories_feed.dart` | 683 | Feed renderer used by `moments_main` |
| `stories_feed_widget.dart` | 543 | Smaller feed wrapper |
| `widgets/overlay_editor.dart` | (small) | Partial overlay editor, never wired into create flow |

### Cross-cutting smells (cleanup debt)

- **28 `.withOpacity(`** calls (deprecated)
- **42 `Colors.grey[*]`** instances (not theme-aware) — highest count in any post-wave-1 folder
- **23 inline `ScaffoldMessenger.showSnackBar`** calls

### April spec landing audit

| April spec feature | Backend state | Flutter state | Verdict |
|---|---|---|---|
| **#1 Text stories** (storyType + text + backgroundColor + 13 gradient presets) | ❌ no `storyType`, `text`, `backgroundColor` on `Story.js` | ❌ no text-story creation tab | **Not shipped — full work needed** |
| **#2 Highlights** (StoryHighlight model, isHighlighted flag, profile highlights row) | ✅ `StoryHighlight.js` model exists; `Story.isHighlighted` field exists | Need audit — `lib/pages/profile/highlights.dart` exists but coverage TBD | **Partially shipped — audit and finish** |
| **#3 Stickers + overlays** (Story.overlays JSON, draggable editor, viewer rendering) | ❌ no `overlays` field on `Story.js` | ⚠️ `widgets/overlay_editor.dart` partial | **Not shipped — finish editor + add backend persistence** |

---

## Architecture decisions (locked-in)

### Canonical viewer

The duplicate viewer needs to be collapsed to one file. Two candidates:

- `modern_story_viewer.dart` (1,578 lines) — name strongly suggests this is the migration target.
- `story_viewer_screen.dart` (1,323 lines) — older; partial migration leftover.

**Decision:** investigate-then-pick during C2 (collapse-viewer commit). The default is `modern_story_viewer.dart` (newer naming + larger size suggests more features). Verify by reading both files end-to-end and checking which is reached from the live entry points (`moments_main` → `StoriesFeedWidget` → ?).

If the investigation reveals the OLDER viewer is actually canonical (e.g., `modern_*` was an abandoned rewrite), retire `modern_story_viewer.dart` instead. Either way, **only one viewer survives**, and importers are migrated to it.

### Folder structure (target)

```
lib/pages/stories/
├── widgets/                        existing + new shared scaffolding
│   ├── overlay_editor.dart         (existing — finish in F3)
│   ├── stories_snackbar.dart       NEW
│   ├── stories_dialog_scaffold.dart NEW
│   ├── stories_empty_state.dart    NEW
│   └── stories_error_state.dart    NEW
│
├── viewer/                         NEW — collapsed canonical viewer
│   ├── story_viewer_screen.dart    ~600 (was 1,578 in modern_story_viewer.dart)
│   ├── viewer_progress_bar.dart    extracted top progress segments
│   ├── viewer_header.dart          extracted user info + close button
│   ├── viewer_controls.dart        extracted tap/long-press controls
│   ├── viewer_text_story_layer.dart NEW — renders text stories
│   └── viewer_overlay_layer.dart   NEW — renders text/emoji overlays
│
├── feed/                           NEW
│   ├── modern_stories_feed.dart    MOVED, light split
│   ├── stories_feed_widget.dart    MOVED
│   └── story_avatar_ring.dart      extracted ring with seen/unseen state
│
├── create/                         NEW — was create_story_screen.dart (899)
│   ├── create_story_screen.dart    ~300 (shell with tab controller)
│   ├── create_image_tab.dart       photo/video flow (existing logic)
│   ├── create_text_tab.dart        NEW — text-story flow with gradient picker
│   ├── gradient_picker.dart        NEW — 13-preset selector
│   ├── overlay_picker.dart         NEW — text + emoji sticker insertion
│   └── create_actions_bar.dart     post / cancel / privacy controls
│
└── models/                         NEW
    ├── story_overlay.dart          overlay JSON model (type, position, scale, rotation, content, style)
    └── story_gradient.dart         13 gradient preset constants + lookup
```

### Text stories — backend schema additions

Add to `models/Story.js`:

```js
storyType: { type: String, enum: ['image', 'video', 'text'], default: 'image' },
text: { type: String, maxlength: 500, default: null },
backgroundColor: {
  type: String,
  enum: [
    'gradient_sunset', 'gradient_ocean', 'gradient_forest', 'gradient_purple',
    'gradient_fire', 'gradient_midnight', 'gradient_candy', 'gradient_sky',
    'gradient_aurora', 'gradient_peach', 'gradient_mint', 'gradient_lavender',
    'gradient_galaxy',
  ],
  default: null,
},
```

(13 presets per the April spec.)

Validator update: text stories must have non-empty `text` AND non-null `backgroundColor`; no `media` URL required. Image/video stories must have `media`; `text` and `backgroundColor` ignored.

### Overlays — backend schema additions

Add to `models/Story.js`:

```js
overlays: [{
  type: { type: String, enum: ['text', 'emoji'], required: true },
  position: {
    xPct: { type: Number, min: 0, max: 100, required: true },
    yPct: { type: Number, min: 0, max: 100, required: true },
  },
  scale: { type: Number, min: 0.5, max: 3.0, default: 1.0 },
  rotation: { type: Number, default: 0 },  // degrees
  content: { type: String, required: true },  // text content or emoji char
  style: {
    fontStyle: { type: String, enum: ['sans', 'serif', 'bold', 'handwritten'], default: 'sans' },
    color: { type: String, enum: ['white', 'black', 'red', 'blue', 'green', 'yellow', 'pink', 'purple'], default: 'white' },
  },
}],
```

Stored as JSON array; max 5 overlays per story (validator-enforced); rendered client-side as Stack overlays on the media/text layer.

### Highlights audit + finish

Verify during F2 what's already shipped:

- ✅ `models/StoryHighlight.js` exists
- ✅ `Story.isHighlighted` field exists
- ❓ `controllers/highlights.js` — verify CRUD endpoints exist (`POST /highlights`, `GET /users/:id/highlights`, `DELETE /highlights/:id`)
- ❓ `routes/highlights.js` — verify routes wired
- ❓ `lib/services/highlights_service.dart` — verify Flutter service exists
- ❓ `lib/pages/profile/main/profile_highlights.dart` — verify the Instagram-style row on profile

Whatever's missing gets implemented in F2. Whatever exists gets verified working.

---

## Cross-cutting

### l10n plan

New ARB keys (~25-30 across the new features):

| Group | Keys (approx) |
|---|---|
| Stories snackbar / empty / error | 4 (`storiesEmpty`, `storiesLoadError`, `storiesRetry`, `storiesNoMore`) |
| Text story creation | 8 (`createTextStoryTab`, `enterTextHint`, `pickBackground`, `gradientSunset` … `gradientGalaxy` for 13 names — actually use generic labels like `gradientPreset1`-`13`, simpler) |
| Overlay editor | 6 (`addText`, `addEmoji`, `chooseFont`, `chooseColor`, `dragToMove`, `pinchToScale`) |
| Highlights | 4 (`createHighlight`, `highlightName`, `addToHighlight`, `removeFromHighlight`) |
| Story actions / errors | 3 (`storyDeleted`, `storySaved`, `storyTooLong`) |

Cadence: en-keys commit (C3) → 17-locale translations commit (C4), matches Step 2 pattern.

### Testing

- `flutter analyze` clean per commit.
- Backend additions: unit tests for text-story validator, overlay validator, highlight CRUD if test infra exists.
- Manual smoke: create text story, post → see in feed → tap → render → close. Repeat for overlay-on-image flow. Verify highlights pin/unpin and 24h cleanup respects the flag.

### Risk register

| Risk | Mitigation |
|---|---|
| Wrong viewer picked as canonical → live flow breaks | Investigate-then-pick in C2; verify `moments_main` flow still works after the migration. Keep the retired viewer file in its own commit so revert is one git command |
| Singular folder deletion breaks something we didn't grep for | Grep was exhaustive (`grep -rln "pages/story/"` over `lib/` returned empty). If anything breaks, revert C1 alone — it's the first commit and isolated |
| Text-story validator silently rejects valid creates | Add explicit error responses (400 with field-specific message) for missing `text`/`backgroundColor` on text-type stories |
| Overlay JSON shape drift between Flutter and backend | Define the shape in `lib/pages/stories/models/story_overlay.dart` Dart class with `toJson` / `fromJson`; backend Mongoose validator mirrors the Dart shape exactly |
| Highlights partial-shipping audit reveals a model migration is needed | Document in F2 commit and split — don't bundle migration with new feature |
| 24h cleanup cron currently deletes highlighted stories | The April spec called for skipping highlighted stories in cleanup. Verify the cron honors `isHighlighted: $ne: true` (per `models/Story.js:301` already shows this filter); add unit test if missing |

---

## PR / commit breakdown

| # | Commit | Type | Notes |
|---|---|---|---|
| C0 | `chore(stories)`: branch + deps audit | chore | Likely no-op, no commit |
| C1 | `chore(stories)`: delete dead `lib/pages/story/` orphan folder | chore | -4,775 lines; risk-free since zero importers |
| C2 | `refactor(stories)`: investigate + collapse duplicate viewer to canonical | refactor | Read both viewers, pick winner, migrate importers |
| C3 | `refactor(stories)`: add ~25-30 English ARB keys | refactor | |
| C4 | `refactor(stories)`: translate ARB keys to 17 locales | refactor | Matches Step 2 cadence |
| C5 | `refactor(stories)`: add `widgets/` scaffolding (snackbar, dialog, empty, error) | refactor | Mirrors wave-1 C1 |
| C6 | `refactor(stories)`: migrate ~23 inline snackbars to `showStoriesSnackBar` | refactor | |
| C7 | `fix(stories)`: withOpacity → withValues + Colors.grey sweep | fix | 28 + 42 sites |
| C8 | `refactor(stories)`: split `create_story_screen` into `create/` subfolder with tabs | refactor | Sets up text-story tab slot |
| C9 | `refactor(stories)`: split canonical viewer into `viewer/` subfolder | refactor | |
| C10 | `refactor(stories)`: move feed files into `feed/` subfolder | refactor | |
| C11 | `feat(stories)` + backend: text stories — Story.js fields + validator | feat + backend | Adds storyType/text/backgroundColor + validator |
| C12 | `feat(stories)`: text-story creation tab + gradient picker (Flutter) | feat | Renders text creation flow + posts |
| C13 | `feat(stories)`: text-story rendering in viewer | feat | Adds `viewer_text_story_layer.dart` |
| C14 | `feat(stories)` + backend: highlights audit + finish missing pieces | feat + backend | Whatever F2 audit surfaces |
| C15 | `feat(stories)` + backend: overlays — Story.overlays schema + validator | feat + backend | |
| C16 | `feat(stories)`: overlay editor wire-up (text + emoji insertion) | feat | Builds on existing `widgets/overlay_editor.dart` |
| C17 | `feat(stories)`: overlay rendering in viewer | feat | Adds `viewer_overlay_layer.dart` |
| C18 | `chore(stories)`: final analyzer + smoke + push + PR | chore | |

**Total: 18 commits, ~5-7 weeks.** Backend commits (C11, C14, C15) land on `main` of the paired backend repo per project pattern.

---

## Future / deferred

- Music on stories
- Story view-list / "seen by"
- Story replies (DM-style)
- Story reactions
- Cross-post story → moment
- Custom sticker packs
- Story analytics dashboard
