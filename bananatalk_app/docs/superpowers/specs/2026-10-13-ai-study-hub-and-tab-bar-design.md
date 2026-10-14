# AI Study hub + floating tab bar — design

Date: 2026-10-13 · Branch: `feat/ai-study-hub` · Mockup: https://claude.ai/artifact/R1A8GWY8C6cqEMkfs5akEK (private)

## 1. Goal

Make AI Study (tab 0) easier to read, show users everything it offers, then earn from that
visibility. Priority order agreed with the owner:

1. **Visibility and typography** — one clear hierarchy, readable type, compact spacing (the owner
   was explicit: "spacing very important, don't waste space").
2. **Feature discovery** — every feature reachable from the first screen or one short scroll;
   nothing behind sub-tabs, swipes or a ⋮ menu.
3. **Revenue** — each visible feature tile is a place to show quota, a lock, a coin trial or VIP.

The floating tab bar is redesigned in the same wave: the active tab shows its name, the bar gets out
of the way, and the floating coffee button goes.

### Why (evidence)

- Today the tab has three sub-tabs (Today / AI Tools / Exam Study). Only the first is seen on arrival;
  Exam Study sits third and the guide had to add a second button just to reveal it.
- The Today sub-tab stacks ~9 sections (hero, stats, digest, quick actions, progress button, AI
  banner, ad, challenges, continue learning, ad); the first screen shows little more than the hero.
- Leaderboard and Achievements are hidden in a ⋮ menu.
- Quota counts exist before tap (`/tutor/me` → `tutorQuotaProvider`) but are only shown inside the
  destination screens, so users discover the cap by hitting a 429.
- ~56 hard-coded `TextStyle(fontSize:)` across the AI Study files; `AppTypography` exists in
  `core/theme/app_theme.dart` and is unused here. Smallest text today is 9 pt (VIP badge).
- Earlier measurements (memory, not re-run): AI tutor ~4× Exam Study usage; 58 % of learners target a
  non-English language; ~17 % of signups delete within ~18 min.
- **Baseline not measured this session** (prod DB access was not available). See §9.

## 2. Scope

In: `LearningMain` restructure, feature grid, badges, upgrade/trial sheet, spotlight carousel,
recommended tile, AI Study guide rewrite, typography in the touched files, floating tab bar
redesign + hide-on-scroll + shared bottom clearance, coffee button removal.

Out: new learning content, server-side quota changes, tab order or tab count changes, redesign of the
destination screens (tutor, exam flow, etc.), per-tab announcement targeting (needs a backend field;
later).

## 3. Hub layout (`LearningMain`)

One `CustomScrollView`; the `TabController`, `TabBar`, `TabBarView`, `StudyHubTab` enum and
`LearnTab`/`AIToolsTab` composition are removed. `ExamStudyTab` content is no longer embedded;
Exam Study is a tile pushing the existing exam language list.

Top to bottom:

| # | Section | Height | Shown when |
|---|---|---|---|
| 1 | Header (gradient, collapses on scroll) | ~110 expanded / 56 collapsed | always |
| 2 | First-week guide **or** spotlight carousel | guide ~120 / carousel 84 + dots | guide: `shouldShowGuide`; carousel: ≥1 live announcement and guide hidden |
| 3 | Today's pack row | 72 | always (existing `needsLanguage` / placement states keep their current behaviour, restyled to the row) |
| 4 | Recommended for you | 48 | a weak area with ≥3 attempts exists |
| 5 | Explore groups: Talk · Practice · Prepare & compete | 2 rows × 64 per group | always |
| 6 | Your progress card | ~96 | always |
| 7 | One native ad | — | `showAdsProvider` (hidden for VIP), as today |

**Header**: line 1 greeting + `VipUpPill` + `CoinBalancePill` + `NotificationBell`; line 2 chips:
streak, level, target language + CEFR level. The ⋮ menu is removed.

**Removed**: sub-tabs, AI banner, quick-stats row (folded into progress card), weekly digest card
(reachable from the progress card's "Full report"), second ad, `_showArrow` scroll hint,
`DailyPracticeCard` leftovers.

**Kept unchanged**: streak / level-up / achievement celebration listeners, daily-pack invalidation
logic in `learn_tab.dart` (moved, not rewritten), `PageGuide` widget mechanics.

### 3.1 Spacing (compact, fixed)

Page margin 12 · tile gap 8 · group gap 16 · group label → tiles 8 · tile height 64 · today row 72 ·
recommended 48 · carousel card 84 · card radius 16 (tiles 14).
Expressed as named constants in one file (`study_hub_metrics.dart`), not literals.

### 3.2 Typography

All text in the touched files uses `Theme.of(context).textTheme` / `AppTypography`; no `fontSize:`
literals remain in them (a test greps for this). Minimum size 12.

| Use | Style |
|---|---|
| Greeting | `headlineSmall`, w800 |
| Group label | `labelLarge`, uppercase, +0.06em, secondary colour |
| Tile title | `titleSmall` (15, w650) |
| Tile description, captions | `bodySmall` (12) |
| Badge | `labelSmall` (12, w700) |
| Stat numbers | `titleLarge`, w800 |

## 4. Feature grid

### 4.1 Tiles and order

One `StudyFeature` enum + `studyFeatureGroups` const list (replaces `practice_entries.dart` order);
a test asserts order and uniqueness.

| Group | Tile | Destination (existing) | Quota key |
|---|---|---|---|
| Talk | AI Tutor | `TutorChatScreen` (via persona picker if none) | `chat` |
| Talk | Roleplay | `ScenarioPickerScreen` (via picker) | `roleplay` |
| Talk | Story | `StorySetupScreen` (via picker) | `story` |
| Talk | Photo | `ImageVocabScreen` (via picker) | `photo` |
| Practice | Speak | `PronunciationScreen` | `pronunciation` |
| Practice | Review | `VocabularyReviewScreen` | — (shows due count) |
| Practice | Writing | `GrammarFeedbackScreen` | — |
| Practice | Quizzes | `AIQuizScreen` | — |
| Prepare & compete | Exam prep | exam language list (`/exam-study`) | — (essay quota stays inside the flow) |
| Prepare & compete | Lessons | `LessonsScreen` | — |
| Prepare & compete | Challenges | `ChallengesScreen` | — |
| Prepare & compete | Leaderboard | `LeaderboardScreen` | — |

Achievements, Mastery ("Full report"), Weekly report, SRS dashboard and Vocabulary are reached from
the progress card. Tutor home (persona settings) stays reachable from inside the tutor screens.

### 4.2 `StudyFeatureTile`

Row layout: 36 px tinted icon square (group colour), title, one-line description (ellipsis), at most
**one** trailing badge. White surface (dark: `#1E1E24`), 1 px hairline + soft shadow. Whole tile is
the tap target; semantics label = title + description + badge text.

Group colours: Talk violet `#6D3FE0` on `#EFE9FE`; Practice teal `#00786A` on `#DDF5EF`; Prepare amber
`#A85E00` on `#FEF0D9` (dark mode uses 16–18 % alpha fills with light icon colours; all text ≥4.5:1).

### 4.3 Badge state — one pure function

`TileBadge badgeFor(feature, {isVip, vipOnlySet, quota, dueCount, seen})`, first match wins:

1. **Locked** — feature in `vipOnlySet` and `!isVip` → "VIP" with lock icon.
2. **Exhausted** — `quota.remaining == 0` and not unlimited → "0 left" (red).
3. **Low** — `quota.shouldShowIndicator` (≥50 % used) → "N left".
4. **Due** — Review with `dueCount > 0` → "N due".
5. **New** — not yet opened (see 4.5) → "NEW".
6. none.

Unit-tested per state and per precedence pair.

### 4.4 Tap behaviour and the upgrade/trial sheet

- Locked → `StudyUpgradeSheet(feature, reason: locked)`.
- Exhausted → `StudyUpgradeSheet(feature, reason: exhausted)` **before** navigating, instead of
  letting the destination hit a 429.
- Otherwise navigate; mark seen.

`StudyUpgradeSheet` (new, `widgets/study/study_upgrade_sheet.dart`): feature icon + name + one-line
value, two benefit lines, then:
- **Try once for N coins** — the existing `UnlockCta(featureKey: quotaKey)`; hides itself when coins
  are off or the feature is not in the unlock catalog. Price always comes from the catalog.
- **Get VIP — unlimited** → `VipPlansScreen`.
- **Not now**.
On successful unlock: invalidate `tutorMemoryAndQuotasProvider`, close sheet, open the feature.
The global 429 handler and `PersonaUpgradeSheet` stay as the fallback path.

**VIP-only set is remote**: new app-config field `studyVipOnlyFeatures: List<String>` (default
empty). Nothing is newly locked at launch; the owner can lock e.g. `photo` without a release. Locked
tiles are still visible (a hidden feature sells nothing).

### 4.5 NEW badges — `FeatureSeenStore`

SharedPreferences, key `study_feature_seen_<slug>`, every read/write wrapped like `GuideStore`;
cleared by `session_reset` so it is per account. A tile is marked seen on tap.
To avoid a wall of badges for existing users: **at most 3 NEW badges at once**, the first unseen tiles
in grid order; the rest show none until earlier ones are opened.

### 4.6 Language coverage

`featureCoverage(feature, targetLanguage)` returns `supported | englishOnly | unknown`, fed by data
the app already receives (exam languages, pronunciation language list, lesson-builder
`supportedLanguages`, daily-pack `needsLanguage`). Features with no source → `unknown` → no note.
When `englishOnly`, the tile description becomes "English only for now" (tile stays tappable). The
plan's first task verified each feature's real support against the backend (2026-10-14):

| Feature | Backend finding | Coverage |
|---|---|---|
| tutor | `controllers/tutor.js` takes `language_to_learn` from the user; no language allow-list | unknown (unrestricted) |
| roleplay | `aiConversation.js` takes any `targetLanguage`; no allow-list | unknown (unrestricted) |
| story | `story.js` route; no language gate found | unknown |
| photo | no language gate found | unknown |
| speak | `speech.js`: `language` is required but not validated against a list; voices resolved per language | unknown (unrestricted) |
| review | not language-gated | unknown |
| writing | `grammarFeedback.js` uses `targetLanguage` from user/body; no allow-list | unknown (unrestricted) |
| quizzes | AI quiz uses user target language; no allow-list | unknown |
| exam | `/exam-study/languages` list (dynamic, `examLanguagesProvider`) | supported / unknown |
| lessons | lesson builder lists 11 languages (en es fr de it pt ru zh ja ko ar) as UI choices only; not enforced | unknown |
| challenges, leaderboard | language-independent | unknown |

No hard English-only restriction exists in code, so `_staticLanguageSupport` is empty and
`englishOnly` is never produced yet; the mechanism is kept for future restrictions.

## 5. Recommended tile

From `weakAreasProvider`: lowest `accuracy` with `attempts ≥ 3`. Copy: "For you: {name} — {acc}%
right · 5-min quiz ›". Tap → `AIQuizScreen` (as the Weak Areas button does today). Hidden while
loading, on error, or with no qualifying area.

## 6. Spotlight carousel

Source: `appConfigProvider.announcements` (already platform/language filtered, priority sorted), max
3. Card: optional label, title, optional button label; tap follows the announcement's button URL
through the existing announcement link handling, else opens `AnnouncementScreen`. Dismissed ids are
stored locally (`study_spotlight_dismissed`). **Hidden while the first-week guide is visible** — one
teaching surface at a time. Global announcements only (no tab targeting in v1).

## 7. Screen guide (AI Study)

On `origin/main` the guide's buttons animate to sub-tabs that no longer exist. New guide:
- Title "Your daily language gym"; body "A 5-minute pack every day, plus an AI tutor whenever you
  want to talk." (new l10n keys, all 19 locales).
- Primary "Start today's pack" → opens the pack (the action that retires the guide).
- Secondary "See all features" → scrolls to the Explore groups.
- **Fix**: completing an AI tutor chat or roleplay session also calls
  `ActivationStore().markDone(ActivationAction.lesson)`; today only daily pack, lessons, quizzes and
  vocab do, so tutor-only users see the guide all week.
- Guide window, milestone stop and retire analytics unchanged.

## 8. Floating tab bar (`TabsScreen`)

### 8.1 Look

Same glass pill, same 5 tabs and order, height 56 (was 60), item height 44.
- Inactive: icon only (48 wide), grey.
- **Active: capsule with icon + name**, capsule fill = tab colour at 14 % (dark 18–20 %), label in the
  darkened tab colour (≥4.5:1), `labelLarge` 13 w700. Width/colour animate 220 ms easeOutCubic.
- Names reuse existing keys: `study` ("AI Study"), `community`, `chats`, `moments`, `profile`.
- Badges: unread dot/count stays on the icon; on the active capsule the count sits after the label.
- Every item has a semantics label + selected state even when the name is not drawn.

### 8.2 Behaviour — never in the way

- **Hide on scroll**: a `NotificationListener<UserScrollNotification>` around the page stack
  (vertical axis, depth 0 of each tab's primary scrollable). Downward scroll beyond 24 px → bar
  slides down (200 ms); any upward scroll, reaching the top, or reaching the end → slides back.
- **Keyboard open** (`viewInsets.bottom > 0`) → hidden.
- **Re-tap active tab** → scroll that tab to top (generalise the existing `tabRefreshNotifier` into a
  per-tab reselect signal; tabs without a list ignore it).
- **Shared clearance**: `FloatingTabBar.clearance(context)` = bar height + bottom gap + safe-area
  inset. Every tab's scrollables use it for bottom padding, replacing the scattered
  `EdgeInsets.only(bottom: 100)` literals; a test asserts no tab page keeps a literal.

### 8.3 Coffee button

The floating `_CoffeeButton` is removed. `_SupportSheet` moves to its own file and is opened from a
"Support BananaTalk" row in Profile › Settings. Nothing else floats over content.

## 9. Measurement

Analytics events (existing `AnalyticsService`):
`study_tile_tap {feature, badge}`, `study_upgrade_sheet_shown {feature, reason}`,
`study_upgrade_unlock {feature, method: coins|vip}`, `study_spotlight_tap {id}`,
`study_recommended_tap {area}`.

Success (compare 14 days before vs after release):
- distinct AI Study features opened per active learner per week — up;
- share of new users who open ≥2 features in week 1 — up;
- upgrade sheet → coin unlock or VIP purchase rate — first real number (baseline is effectively zero).

**Before release**: run the baseline queries against prod (feature usage per user, 30 days) — they
could not be run during design.

## 10. Rollout and rollback

- App-config flag `studyHubEnabled` (default **false**): false renders the current `LearningMain`
  unchanged; true renders the hub. The tab bar redesign and coffee removal are not flagged (low risk,
  no data dependency).
- Backend: app-config response gains `studyHubEnabled` and `studyVipOnlyFeatures` (additive, both
  default off/empty). Deploy backend before the app; old apps ignore the fields.
- Old `LearnTab` / `AIToolsTab` stay in the tree until the flag has been on for a release, then are
  deleted (tracked in `REMAINING_WORK.md`).

## 11. Testing

Unit: `badgeFor` (each state + precedence), `FeatureSeenStore` (read/write/reset, max-3 rule),
`featureCoverage`, recommended-area selection, `studyFeatureGroups` order.
Widget: hub renders all three groups with flag on and the old screen with flag off; guide buttons
(pack, scroll to groups); carousel hidden while guide shows; exhausted tile opens the sheet instead
of navigating; tab bar active capsule label, hide on scroll down / show on scroll up, hidden with
keyboard; reselect scrolls to top.
Static: no `fontSize:` literal in the hub files; no `bottom: 100` literal in tab pages.
Manual: light/dark, smallest phone (iPhone SE width 320 — tiles must not overflow), largest text
scale 1.3, Korean and Arabic (RTL) locales.

## 12. Files

New: `pages/learning/main/study_hub.dart`, `.../sections/study_feature_tile.dart`,
`.../sections/study_features.dart` (enum, groups, `badgeFor`, coverage), `.../sections/spotlight_carousel.dart`,
`.../sections/recommended_tile.dart`, `.../study_hub_metrics.dart`, `services/feature_seen_store.dart`,
`widgets/study/study_upgrade_sheet.dart`, `widgets/navigation/floating_tab_bar.dart`,
`pages/profile/support/support_sheet.dart`.
Changed: `learning_main_screen.dart` (flag switch), `pages/menu_tab/TabBarMenu.dart`,
`models/app_config.dart`, tutor/roleplay completion (activation), `session_reset`, tab pages' bottom
padding, profile settings, 19 `.arb` files.
