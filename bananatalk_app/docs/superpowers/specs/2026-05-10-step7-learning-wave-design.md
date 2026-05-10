# Step 7 — Learning Wave (Restructure + Modern Features) — Design

**Date:** 2026-05-10
**Branch:** `refactor/step7-learning-wave` (off `main`)
**Scope:** `lib/pages/learning/` (~8,618 lines, 16 files, 2 monoliths) + `lib/providers/learning_providers.dart` (1,023 lines) + `lib/services/learning_service.dart` (1,275 lines) + paired backend audit
**Shape:** Restructure + l10n catch-up + cleanup + 5 features. Mid-size wave (smaller than Step 6 chat — Learning has fewer entry points but l10n debt is heavy).

## Goal

Four discrete wins, packaged as one wave:

1. **Split the 3 learning monoliths** — `learning_main.dart` (1,443) → main/ with hub + sections; `leaderboard_screen.dart` (1,108) → leaderboard/tabs/ structure; `learning_providers.dart` (1,023) → split by feature area. Target: each unit ≤500 lines, well-defined responsibility.
2. **l10n catch-up** — Audit reveals only 4 learning ARB keys exist (`dailyMessageLimitExceeded`, `dailyLearningJourney`, `dailyChallenges`, `silencedByCap`). Hardcoded strings throughout. Goal: ~80 new English keys + 18-locale translations (~1,440 string adds).
3. **Cleanup sweep** — `withOpacity` → `withValues`, `Colors.grey[*]` → `context.X` getters, inline snackbars → `showLearningSnackBar` helper, `debugPrint` purge. Plus `learning/widgets/` scaffolding (snackbar/empty/error helpers — mirrors past waves).
4. **7 modern features (5 new + 2 existing-feature improvements)**:
   - **F1. Streak freeze UI** — backend has `streakFreezesAvailable` model field with no frontend. Surface freeze count in streak widget + "use freeze" affordance + freeze history.
   - **F2. SRS daily review dashboard** — backend SRS exists (`Vocabulary.nextReviewAt`, `interval`, `masteryLevel`). Build dedicated review queue UI: due-card count badge, daily review goal, session player.
   - **F3. Leaderboard social polish** — M3 redesign + friend badges + language-filtered ranks + animated rank-change indicators.
   - **F4. Gamification animations** — XP gain pop on completion, streak milestone celebration (7/30/100/365 days), achievement unlock confetti, level-up sequence.
   - **F5. Weekly digest card** — in-app weekly report on hub (XP earned, lessons completed, vocab learned, streak status, top achievement).
   - **F6. Vocabulary list polish (improve existing)** — current `vocabulary_screen.dart` (311L) has flat list. Add: search bar, filter by mastery level (new/learning/mastered), sort options (recent/alphabetical/mastery), per-row mastery indicator chip.
   - **F7. Progress hero weekly XP chart (improve existing)** — current hero shows level + XP number. Replace with: level progress ring + 7-day XP bar chart + trend indicator (↑/↓ vs last week).

## Non-goals (explicit)

- **No new learning content (lessons, quizzes, challenges)** — backend already serves these. Step 7 polishes presentation, not content authoring.
- **No backend schema changes** — `LearningProgress`, `Vocabulary`, `Lesson`, `Quiz`, `Challenge`, `Badge` are sufficient. Only minor controller additions if audit reveals gaps (e.g., weekly-digest aggregation endpoint).
- **No AI tutor expansion** — AI quiz/conversation/grammar/pronunciation already exist. Step 7 doesn't add new AI surfaces.
- **No placement test** — schema has fields, but full placement flow is its own wave (deferred to Step 9).
- **No notification work** — push notification surface (streak reminders, vocab reviews) untouched. Already plumbed; Step 7 doesn't change cadence.
- **No drag-and-drop reordering** for vocabulary or lessons.

## Current state diagnostics

### Folder shape (~8,618 lines, 16 files, flat structure)

| File | Lines | Smell |
|---|---|---|
| `learning_main.dart` | **1,443** | Hub with tabs, progress hero, daily goals widget, challenges preview, AI access cards, sections grid all inline |
| `leaderboard_screen.dart` | **1,108** | XP/streak leaderboards with 4 tabs + filters + animations all in one file |
| `lesson_player_screen.dart` | 685 | Exercise player; under threshold |
| `challenges_screen.dart` | 663 | Daily/weekly challenge browser |
| `quiz_player_screen.dart` | 631 | Quiz session player |
| `exercises/multiple_choice_exercise.dart` | 502 | OK; existing |
| `exercises/fill_blank_exercise.dart` | ~430 | OK |
| `achievements_screen.dart` | 437 | Achievement gallery |
| `lessons_screen.dart` | 417 | Lesson catalog |
| `vocabulary_review_screen.dart` | 382 | SRS review session |
| `quizzes_screen.dart` | 383 | Quiz catalog |
| `vocabulary_add_screen.dart` | 351 | Add vocab form |
| `vocabulary_screen.dart` | 311 | Vocab list |
| Other exercise widgets | 199-340 | Each |

**Provider/service layer:**
| File | Lines | Smell |
|---|---|---|
| `lib/providers/learning_providers.dart` | **1,023** | 30+ providers across progress, vocab, lessons, quizzes, achievements, challenges, leaderboards |
| `lib/services/learning_service.dart` | 1,275 | API layer (kept intact — service files traditionally larger; split deferred) |
| `lib/providers/badge_count_provider.dart` | 188 | Unread badge counter |

### Already-shipped features (verified during planning)

- ✅ Vocabulary CRUD + SRS scheduling (backend full, frontend partial)
- ✅ Lessons (curriculum, player with 5 exercise types: MCQ, fill blank, translation, matching, ordering)
- ✅ Quizzes (catalog, AI-generated, stats)
- ✅ Daily/weekly challenges
- ✅ Achievements (gallery, featured selection, unread counter)
- ✅ Leaderboards (XP weekly/all-time, streak, language-filtered, friends)
- ✅ AI features (conversation, grammar feedback, pronunciation, lesson builder, AI quiz)
- ✅ Adaptive recommendations (weak areas + refresh)
- ✅ Daily goals (casual/regular/serious/intense, progress tracking)
- ✅ Streak (current/longest, freeze model in backend)
- ✅ XP, levels (A1-C2 proficiency virtual on LearningProgress)

### Backend health

- **`/api/learning/`** — 22 endpoints, well-structured (asyncHandler + ErrorResponse pattern)
- **`/api/leaderboard/`** — 5 endpoints
- **Schemas:** `LearningProgress` (XP, streak with freezes, daily goal progress), `Vocabulary` (full SRS), `Lesson`, `Quiz`, `Challenge`, `Badge` — all production-ready
- **One backend addition needed:** `GET /learning/weekly-digest` — aggregates last-7-day XP/lessons/vocab/streak for F5 weekly card. Existing `/activity` endpoint is per-day; aggregation is new.

### Cleanup debt (learning folder)

Estimated by surveying chat-style cleanup patterns from past waves:

- ~15-20 `withOpacity` calls (deprecated API)
- ~25-35 `Colors.grey[*]` raw refs (should use `context.dividerColor`/etc.)
- 0 inline snackbars (audit during C5 — likely 5-10 candidates)
- ~10-15 `debugPrint` statements

Actual numbers to be measured at C5 (cleanup commit).

### l10n debt (severe)

**Audit:** `lib/l10n/app_en.arb` contains exactly **4** keys with learning context. The Learning surface has hundreds of hardcoded strings: tab labels, section titles, button labels, empty states, error messages, achievement names, exercise prompts, snackbar text. **Estimated ~80 new keys** required for Step 7's surface (post-restructure files only — pre-existing l10n debt outside Step 7 scope flagged for future wave).

---

## Architecture

### Target folder layout

```
lib/pages/learning/
├── main/                                    NEW
│   ├── learning_main_screen.dart            (~250L — was 1,443)
│   ├── sections/
│   │   ├── progress_hero.dart               NEW (~150L)
│   │   ├── daily_goal_widget.dart           NEW (~120L)
│   │   ├── streak_widget.dart               NEW (~140L) — F1 lives here
│   │   ├── challenges_preview.dart          NEW (~100L)
│   │   ├── ai_access_card.dart              NEW (~80L)
│   │   ├── sections_grid.dart               NEW (~130L)
│   │   └── weekly_digest_card.dart          NEW (~150L) — F5
│   └── handlers/
│       └── hub_handlers.dart                NEW (~80L)
├── lessons/                                 NEW (move existing)
│   ├── list/
│   │   └── lessons_screen.dart              (moved, 417L)
│   ├── player/
│   │   └── lesson_player_screen.dart        (moved, 685L)
│   └── exercises/                           (moved 5 widgets)
├── quizzes/                                 NEW (move existing)
│   ├── list/quizzes_screen.dart             (moved, 383L)
│   └── player/quiz_player_screen.dart       (moved, 631L)
├── vocabulary/                              NEW (move existing)
│   ├── list/vocabulary_screen.dart          (moved, 311L)
│   ├── add/vocabulary_add_screen.dart       (moved, 351L)
│   ├── review/
│   │   ├── vocabulary_review_screen.dart    (moved, 382L)
│   │   └── srs_dashboard_screen.dart        NEW (~250L) — F2
│   └── widgets/
├── challenges/
│   └── challenges_screen.dart               (moved, 663L)
├── achievements/
│   └── achievements_screen.dart             (moved, 437L)
├── leaderboard/                             NEW
│   ├── leaderboard_screen.dart              (~250L — was 1,108)
│   ├── tabs/
│   │   ├── xp_tab.dart                      NEW (~180L)
│   │   ├── streak_tab.dart                  NEW (~150L)
│   │   ├── language_tab.dart                NEW (~150L)
│   │   └── friends_tab.dart                 NEW (~150L)
│   └── widgets/
│       ├── leaderboard_row.dart             NEW (~120L) — F3 polish
│       ├── rank_badge.dart                  NEW (~80L)
│       └── friend_indicator.dart            NEW (~60L)
├── streak/                                  NEW
│   └── streak_freeze_dialog.dart            NEW (~180L) — F1
├── animations/                              NEW
│   ├── xp_gain_overlay.dart                 NEW (~120L) — F4
│   ├── streak_milestone_celebration.dart    NEW (~150L) — F4
│   ├── achievement_unlock_overlay.dart      NEW (~140L) — F4
│   └── level_up_sequence.dart               NEW (~130L) — F4
├── widgets/                                 NEW (shared scaffolding)
│   ├── learning_snackbar.dart               NEW (showLearningSnackBar)
│   ├── learning_empty_state.dart            NEW
│   └── learning_error_view.dart             NEW
└── models/                                  NEW
    └── weekly_digest.dart                   NEW (~80L) — F5 model
```

### Provider split (lib/providers/learning/)

```
lib/providers/learning/                      NEW (extracted from learning_providers.dart)
├── progress_providers.dart                  (~150L — XP, streak, level, daily goal)
├── vocabulary_providers.dart                (~200L — list, filter, review queue, stats, SRS)
├── lessons_providers.dart                   (~180L — list, filter, detail, player state)
├── quizzes_providers.dart                   (~150L — list, AI gen, stats)
├── challenges_providers.dart                (~120L — daily, weekly, completion)
├── achievements_providers.dart              (~100L — list, featured, unread)
└── leaderboard_providers.dart               (~150L — XP, streak, language, friends, ranks)
```

`learning_providers.dart` becomes a barrel re-export (~30L) for backward compat during migration. Final cleanup commit deletes the barrel after import migration.

### Backend additions

**One new endpoint:**

```
GET /api/learning/weekly-digest
Auth: required
Response:
{
  weekStart: ISO,
  weekEnd: ISO,
  xpEarned: 320,
  lessonsCompleted: 4,
  vocabularyLearned: 18,
  challengesCompleted: 2,
  currentStreak: 12,
  topAchievement: { id, name, unlockedAt } | null,
  daysActive: 5
}
```

Aggregates from existing `LearningProgress` daily history + `Vocabulary` collection + `Achievement` model. Cached for 1 hour per user (route-level cache or in-controller manual cache).

### Feature implementation sketches

**F1. Streak freeze UI** — `streak_widget.dart` shows freeze count badge. Tap freeze icon → `streak_freeze_dialog.dart` with current count, freeze history (last 30 days), "use freeze now" button. Backend: `LearningProgress.streakFreezesAvailable` already exists — frontend adds dialog + service method `useFreeze()`. New endpoint *not* required if existing `PUT /progress` accepts freeze deltas; otherwise add `POST /progress/use-freeze`.

**F2. SRS daily review dashboard** — new `srs_dashboard_screen.dart` shows due-cards count (today, tomorrow, this week), daily review goal progress, "Start review session" CTA. Reuses existing `vocabulary_review_screen.dart` for actual session. Backend `GET /vocabulary/review` already returns due cards.

**F3. Leaderboard social polish** — `leaderboard_row.dart` redesign with avatar + rank badge (gold/silver/bronze for top 3) + friend indicator dot + animated rank-change arrow. M3 elevated card style.

**F4. Gamification animations** — overlay widgets that animate in on event. `xp_gain_overlay.dart` shows "+15 XP" with scale+fade pop after lesson/quiz completion. `streak_milestone_celebration.dart` triggers full-screen confetti at 7/30/100/365-day milestones. `achievement_unlock_overlay.dart` for new badge unlock. `level_up_sequence.dart` for proficiency level changes. All triggered from `learning_handlers.dart` (new handler module).

**F5. Weekly digest card** — `weekly_digest_card.dart` on hub shows Sunday-rollup stats. Calls new backend endpoint. Skeleton loader while loading. Tappable → opens detail modal with day-by-day breakdown.

---

## Data flow

**Read paths (existing, unchanged):**
- Progress hero ← `progressProvider` ← `LearningService.getProgress()` ← `GET /learning/progress`
- Vocabulary list ← `vocabularyProvider` ← `LearningService.getVocabulary()` ← `GET /vocabulary`
- Leaderboard ← `xpLeaderboardProvider` ← `LearningService.getXpLeaderboard()` ← `GET /leaderboard/xp`

**New read path (F5):**
- Weekly digest ← `weeklyDigestProvider` (NEW) ← `LearningService.getWeeklyDigest()` (NEW) ← `GET /learning/weekly-digest` (NEW)

**New write path (F1):**
- Use freeze ← `LearningService.useStreakFreeze()` (NEW) ← `POST /progress/use-freeze` (NEW)

**Animation triggers (F4):**
- Lesson/quiz completion handler → emits XP gain → overlay shows
- Streak day check (on app launch) → if milestone → trigger celebration
- New achievement unlock event → trigger unlock overlay
- Level-up detection (in progress polling) → trigger sequence

---

## Error handling

- Weekly digest endpoint failure → skip card, log silently (not fatal)
- Streak freeze use failure → snackbar with retry
- Animation overlay failure → skip animation (don't block completion flow)
- All failures use existing `learning_error_view.dart` pattern (NEW in C7)

---

## Testing

Per established wave pattern: smoke checks via `flutter analyze` + manual run-through. No unit-test requirement (Flutter app has minimal test suite; established convention).

Per-feature manual checks:
- F1: streak widget shows freeze count, dialog opens, freeze use updates count
- F2: SRS dashboard shows due-card count matching backend; session launches
- F3: leaderboard row renders with badge/avatar/friend dot
- F4: overlays trigger on completion events without lag
- F5: weekly digest card loads, taps to detail, refreshes weekly

---

## Commit plan (overview — full plan in writing-plans wave)

**Estimated 18-20 commits:**

- C0: Audit pass (deps, l10n keys, debugPrints, withOpacity counts)
- C1: Folder restructure — move existing files into subfolders, update imports (no logic change)
- C2: Provider split — extract `learning_providers.dart` into 7 feature-area files
- C3: `learning_main.dart` split — main/ folder + 7 section widgets
- C4: `leaderboard_screen.dart` split — leaderboard/ folder + 4 tab widgets
- C5: Cleanup sweep — withOpacity, Colors.grey, debugPrint, snackbar helper
- C6: ARB English keys (~80 new)
- C7: ARB translations (17 locales × ~80 keys)
- C8: `learning/widgets/` scaffolding (snackbar/empty/error)
- C9: F1 — Streak freeze UI + backend `POST /progress/use-freeze` if needed
- C10: F2 — SRS daily review dashboard
- C11: F3 — Leaderboard social polish (M3 redesign)
- C12: F4 — XP gain overlay
- C13: F4 — Streak milestone celebration
- C14: F4 — Achievement unlock overlay
- C15: F4 — Level-up sequence + handler wiring
- C16: F5 — Backend `GET /learning/weekly-digest` endpoint
- C17: F5 — Frontend weekly digest card + provider/service
- C18: Final l10n sweep + flutter analyze + smoke check
- C19: PR + merge

---

## Acceptance criteria

- [ ] No file in `lib/pages/learning/` exceeds 700 lines (ideally ≤500)
- [ ] `learning_providers.dart` ≤ 50 lines (barrel) or deleted
- [ ] All learning UI strings sourced from ARB (en + 17 locales)
- [ ] `flutter analyze` passes with 0 new warnings
- [ ] Streak freeze visible on hub, usable via dialog
- [ ] SRS dashboard shows due cards, launches session
- [ ] Leaderboard rows have polish (badges, avatars, friend dots)
- [ ] XP gain overlay fires on lesson/quiz completion
- [ ] Weekly digest card renders on hub with backend data
- [ ] Backend `weekly-digest` endpoint returns valid JSON for authenticated user
- [ ] No regression in existing learning flows

---

## Risks & mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Provider split breaks downstream imports | High | Keep `learning_providers.dart` as barrel re-export until final commit migrates imports |
| F4 overlay animations too heavy on mid-tier devices | Medium | Use simple Tween + Opacity (no Rive/Lottie); keep durations ≤600ms |
| Backend weekly-digest aggregation slow at scale | Low | 1-hour cache per user; aggregation runs against indexed fields |
| l10n translation pass breaks existing keys | Medium | Diff against current ARB before commit; never touch unrelated keys |
| Streak freeze backend mismatch (model exists but no endpoint) | Medium | Audit `controllers/learning.js` at C9; add endpoint if missing |
| F4 animations conflict with existing toast/snackbar layers | Low | Use `OverlayEntry` with explicit z-index; test layering |

---

## Out-of-scope follow-ups (defer to Step 9 / future)

- Placement test (full questionnaire flow)
- Notification cadence tuning (streak reminders, vocab reviews)
- Lesson authoring UI (admin / content team)
- Email/push weekly digest delivery
- Group leaderboards (friend cohorts vs all)
- AI tutor expansion beyond current surfaces
- Vocabulary import (CSV / Anki deck)
- Pronunciation scoring expansion

---

## Definition of done

1. Branch `refactor/step7-learning-wave` merged to `main` via PR
2. Backend changes (1 endpoint, possibly 1 more for streak freeze) deployed-ready
3. Manual smoke pass on iOS simulator: hub loads, all sub-screens render, F1-F5 features work end-to-end
4. l10n keys reach 18 locales
5. `flutter analyze` clean
6. Memory updated if any non-obvious decisions emerge during execution
