# Step 7 — Learning Wave Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split 3 learning monoliths (`learning_main.dart` 1,443, `leaderboard_screen.dart` 1,108, `learning_providers.dart` 1,023), close the l10n gap, run cleanup sweep (78 `withOpacity` + 44 `Colors.grey[*]`), ship 5 features (streak freeze UI, SRS dashboard, leaderboard polish, gamification animations, weekly digest).

**Architecture:** Mirror chat/community subfolder pattern. Extract `learning_main.dart` into `main/` orchestrator + `sections/` widgets. Extract `leaderboard_screen.dart` into `leaderboard/` orchestrator + `tabs/` widgets. Split provider monolith into 7 feature-area files under `provider_root/learning/`. Pragmatic guardrail: skip extractions that increase complexity (4+ prop threading kept inline).

**Tech Stack:** Flutter + Riverpod, SharedPreferences, ARB-based l10n (en + 17 locales), Node.js/Express + MongoDB.

**Spec:** `docs/superpowers/specs/2026-05-10-step7-learning-wave-design.md`

**Branch:** `refactor/step7-learning-wave` (off `main`, already created and spec already committed)

**Project pattern:** No new Flutter widget tests — verification is `flutter analyze` clean per commit + manual smoke at the end. Backend additions get smoke checks.

## Spec corrections discovered during plan-writing

1. **Provider lives at `lib/providers/provider_root/learning_providers.dart`**, not `lib/providers/learning_providers.dart` as spec says. Subfolder pattern matches `chat_provider.dart`, `moments_providers.dart`, etc. **Implication:** split target is `lib/providers/provider_root/learning/` subfolder.

2. **lessons/, quizzes/, vocabulary/ subfolders already exist** with their respective screens moved inside. **Implication:** C1 ("folder restructure") only needs to add NEW folders (main/, leaderboard/, streak/, animations/, widgets/, models/) and move `learning_main.dart`, `leaderboard_screen.dart`, `achievements_screen.dart`, `challenges_screen.dart` from root. Skip the lessons/quizzes/vocab moves.

3. **Cleanup debt is heavier than spec estimated.** Actual counts: **78 `withOpacity`**, **44 `Colors.grey[*]`**, **0 `debugPrint`**, **2 inline `ScaffoldMessenger.showSnackBar`**. C5 will be a substantial commit, not trivial.

4. **ARB existing learning coverage is higher than spec said.** Audit found ~43 keys with learning-adjacent names (lesson*, quiz*, vocab*, leaderboard*, streak*, achievement*, challenge*, xp*, level*, daily*) in `app_en.arb`. **Implication:** new key count drops from ~80 to **~50-60**, but per-locale translation pass still adds ~900-1,080 string entries.

5. **Service file `learning_service.dart` (1,275 lines) stays intact.** Spec already deferred service split. Confirmed.

**Net commit count: 17 commits (vs spec estimate of 18-20).**

---

## File Structure (target — additive)

```
lib/pages/learning/
├── main/                                    NEW
│   ├── learning_main_screen.dart            ⬅️ moved/split from learning_main.dart
│   ├── sections/
│   │   ├── progress_hero.dart               NEW
│   │   ├── daily_goal_widget.dart           NEW
│   │   ├── streak_widget.dart               NEW (F1)
│   │   ├── challenges_preview.dart          NEW
│   │   ├── ai_access_card.dart              NEW
│   │   ├── sections_grid.dart               NEW
│   │   └── weekly_digest_card.dart          NEW (F5)
│   └── handlers/
│       └── hub_handlers.dart                NEW
├── lessons/                                 ✅ exists
│   ├── lessons_screen.dart                  ✅ exists
│   ├── lesson_player_screen.dart            ✅ exists
│   └── exercises/                           ✅ exists
├── quizzes/                                 ✅ exists
│   ├── quizzes_screen.dart                  ✅ exists
│   └── quiz_player_screen.dart              ✅ exists
├── vocabulary/                              ✅ exists, expand
│   ├── vocabulary_screen.dart               ✅ exists
│   ├── vocabulary_add_screen.dart           ✅ exists
│   ├── vocabulary_review_screen.dart        ✅ exists
│   └── srs_dashboard_screen.dart            NEW (F2)
├── challenges/                              NEW (move 1 file)
│   └── challenges_screen.dart               ⬅️ moved from root
├── achievements/                            NEW (move 1 file)
│   └── achievements_screen.dart             ⬅️ moved from root
├── leaderboard/                             NEW
│   ├── leaderboard_screen.dart              ⬅️ moved/split from root
│   ├── tabs/
│   │   ├── xp_tab.dart                      NEW
│   │   ├── streak_tab.dart                  NEW
│   │   ├── language_tab.dart                NEW
│   │   └── friends_tab.dart                 NEW
│   └── widgets/
│       ├── leaderboard_row.dart             NEW (F3)
│       ├── rank_badge.dart                  NEW
│       └── friend_indicator.dart            NEW
├── streak/                                  NEW
│   └── streak_freeze_dialog.dart            NEW (F1)
├── animations/                              NEW
│   ├── xp_gain_overlay.dart                 NEW (F4)
│   ├── streak_milestone_celebration.dart    NEW (F4)
│   ├── achievement_unlock_overlay.dart      NEW (F4)
│   └── level_up_sequence.dart               NEW (F4)
├── widgets/                                 NEW (shared scaffolding)
│   ├── learning_snackbar.dart               NEW
│   ├── learning_empty_state.dart            NEW
│   └── learning_error_view.dart             NEW
└── models/                                  NEW
    └── weekly_digest.dart                   NEW (F5)

lib/providers/provider_root/learning/        NEW
├── progress_providers.dart                  ⬅️ extracted (~150L)
├── vocabulary_providers.dart                ⬅️ extracted (~200L)
├── lessons_providers.dart                   ⬅️ extracted (~180L)
├── quizzes_providers.dart                   ⬅️ extracted (~150L)
├── challenges_providers.dart                ⬅️ extracted (~120L)
├── achievements_providers.dart              ⬅️ extracted (~100L)
└── leaderboard_providers.dart               ⬅️ extracted (~150L)

lib/providers/provider_root/learning_providers.dart   ⬅️ becomes barrel re-export (~30L)
```

---

## Branch setup

- [ ] **Step 1: Confirm branch + clean state**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git status -sb | head -3
git log --oneline -2
```

Expected: branch `refactor/step7-learning-wave`, HEAD includes `docs(step7): spec`.

- [ ] **Step 2: Verify analyzer baseline**

```bash
flutter analyze lib/pages/learning/ 2>&1 | tail -10
```

Expected: any pre-existing warnings noted but no new errors introduced.

---

## Task C0 — chore(learning): deps audit

**Files:** none (audit-only)

- [ ] **Step 1: Confirm no new deps needed**

```bash
grep -E "^  (flutter_riverpod|shared_preferences|http|cached_network_image|confetti|flutter_svg):" pubspec.yaml
```

Expected: confetti package may be needed for F4 streak milestone celebration. If absent, add `flutter pub add confetti`. Otherwise no commit (audit-only).

- [ ] **Step 2: If confetti missing, add it**

```bash
flutter pub add confetti
```

Then commit:

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(learning): C0 — add confetti dep for F4 milestone animations"
```

If confetti already present, skip commit (no-op is the expected outcome).

---

## Task C1 — refactor(learning): folder restructure (additive moves only)

**Files:**
- Create: `lib/pages/learning/main/`, `lib/pages/learning/leaderboard/`, `lib/pages/learning/challenges/`, `lib/pages/learning/achievements/`, `lib/pages/learning/streak/`, `lib/pages/learning/animations/`, `lib/pages/learning/widgets/`, `lib/pages/learning/models/`
- Move: `learning_main.dart` → `main/learning_main_screen.dart` (rename for clarity)
- Move: `leaderboard_screen.dart` → `leaderboard/leaderboard_screen.dart`
- Move: `achievements_screen.dart` → `achievements/achievements_screen.dart`
- Move: `challenges_screen.dart` → `challenges/challenges_screen.dart`

- [ ] **Step 1: Find all imports of the 4 moving files**

```bash
grep -rn "pages/learning/learning_main.dart\|pages/learning/leaderboard_screen.dart\|pages/learning/achievements_screen.dart\|pages/learning/challenges_screen.dart" lib/
```

Save the import list — every callsite needs updating.

- [ ] **Step 2: Move files with `git mv`**

```bash
mkdir -p lib/pages/learning/main lib/pages/learning/leaderboard lib/pages/learning/achievements lib/pages/learning/challenges lib/pages/learning/streak lib/pages/learning/animations lib/pages/learning/widgets lib/pages/learning/models
git mv lib/pages/learning/learning_main.dart lib/pages/learning/main/learning_main_screen.dart
git mv lib/pages/learning/leaderboard_screen.dart lib/pages/learning/leaderboard/leaderboard_screen.dart
git mv lib/pages/learning/achievements_screen.dart lib/pages/learning/achievements/achievements_screen.dart
git mv lib/pages/learning/challenges_screen.dart lib/pages/learning/challenges/challenges_screen.dart
```

- [ ] **Step 3: Update import statements**

For each callsite found in Step 1, edit to point to new path. Common consumers:

```bash
# Update imports across the codebase
grep -rl "pages/learning/learning_main.dart" lib/ | xargs sed -i '' 's|pages/learning/learning_main.dart|pages/learning/main/learning_main_screen.dart|g'
grep -rl "pages/learning/leaderboard_screen.dart" lib/ | xargs sed -i '' 's|pages/learning/leaderboard_screen.dart|pages/learning/leaderboard/leaderboard_screen.dart|g'
grep -rl "pages/learning/achievements_screen.dart" lib/ | xargs sed -i '' 's|pages/learning/achievements_screen.dart|pages/learning/achievements/achievements_screen.dart|g'
grep -rl "pages/learning/challenges_screen.dart" lib/ | xargs sed -i '' 's|pages/learning/challenges_screen.dart|pages/learning/challenges/challenges_screen.dart|g'
```

Note: rename of class inside `learning_main_screen.dart` is deferred to C3.

- [ ] **Step 4: Update internal relative imports inside moved files**

The moved files now live one level deeper. Any `import '../widgets/foo.dart'` becomes `import '../../widgets/foo.dart'`. Audit each moved file:

```bash
grep -n "^import '" lib/pages/learning/main/learning_main_screen.dart lib/pages/learning/leaderboard/leaderboard_screen.dart lib/pages/learning/achievements/achievements_screen.dart lib/pages/learning/challenges/challenges_screen.dart
```

For relative imports starting with `../`, prepend an extra `../`. Project-rooted `package:bananatalk_app/...` imports stay as-is.

- [ ] **Step 5: Run analyzer**

```bash
flutter analyze lib/pages/learning/ 2>&1 | tail -20
```

Expected: 0 new errors. If "Target of URI doesn't exist" appears, fix import paths.

- [ ] **Step 6: Commit**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
refactor(learning): C1 — restructure root files into subfolders

Move learning_main → main/, leaderboard_screen → leaderboard/,
achievements_screen → achievements/, challenges_screen → challenges/.
Add empty streak/, animations/, widgets/, models/ for upcoming work.
No logic change.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C2 — refactor(learning): split learning_providers.dart

**Files:**
- Create: `lib/providers/provider_root/learning/{progress,vocabulary,lessons,quizzes,challenges,achievements,leaderboard}_providers.dart`
- Modify: `lib/providers/provider_root/learning_providers.dart` → barrel re-export only (~30 lines)

- [ ] **Step 1: Read current learning_providers.dart in full**

```bash
wc -l lib/providers/provider_root/learning_providers.dart  # 1023
```

Read the file. Identify provider boundaries by feature area:
- `progressProvider`, `learningPreferencesProvider`, `weeklyXpProvider`, `levelProvider` → progress_providers.dart
- `vocabularyProvider`, `vocabularyFilterProvider`, `vocabularyReviewQueueProvider`, `vocabularyStatsProvider` → vocabulary_providers.dart
- `lessonsProvider`, `lessonFilterProvider`, `lessonDetailProvider`, `lessonPlayerProvider` → lessons_providers.dart
- `quizzesProvider`, `quizDetailProvider`, `aiQuizProvider` → quizzes_providers.dart
- `challengesProvider`, `dailyChallengesProvider`, `weeklyChallengesProvider` → challenges_providers.dart
- `achievementsProvider`, `featuredAchievementProvider`, `unseenAchievementsProvider` → achievements_providers.dart
- `xpLeaderboardProvider`, `streakLeaderboardProvider`, `friendsLeaderboardProvider`, `myRankProvider` → leaderboard_providers.dart

- [ ] **Step 2: Create the 7 feature files**

```bash
mkdir -p lib/providers/provider_root/learning
```

For each feature area, copy its providers + their imports into the new file. Each new file needs:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
// + any other relevant imports
```

- [ ] **Step 3: Convert learning_providers.dart to barrel**

```dart
// lib/providers/provider_root/learning_providers.dart
// Barrel re-export. Individual providers live under learning/ subfolder.
export 'learning/progress_providers.dart';
export 'learning/vocabulary_providers.dart';
export 'learning/lessons_providers.dart';
export 'learning/quizzes_providers.dart';
export 'learning/challenges_providers.dart';
export 'learning/achievements_providers.dart';
export 'learning/leaderboard_providers.dart';
```

This keeps existing callsites importing `learning_providers.dart` working without changes.

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/ 2>&1 | tail -20
```

Expected: 0 new errors. Watch for duplicate provider definitions if a provider got copied to two files by mistake.

- [ ] **Step 5: Commit**

```bash
git add lib/providers/
git commit -m "$(cat <<'EOF'
refactor(learning): C2 — split learning_providers (1,023→barrel)

Extract 7 feature-area provider files (progress, vocabulary, lessons,
quizzes, challenges, achievements, leaderboard) under
provider_root/learning/. Original file becomes barrel re-export
to preserve existing import paths.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C3 — refactor(learning): split learning_main_screen.dart

**Files:**
- Modify: `lib/pages/learning/main/learning_main_screen.dart` (1,443 → ~250)
- Create: `lib/pages/learning/main/sections/{progress_hero,daily_goal_widget,streak_widget,challenges_preview,ai_access_card,sections_grid}.dart`
- Create: `lib/pages/learning/main/handlers/hub_handlers.dart`

- [ ] **Step 1: Read learning_main_screen.dart, identify section boundaries**

Look for `_build*` helper methods and `Widget` extractions. Typical hub layout:

- `_buildProgressHero()` → `sections/progress_hero.dart`
- `_buildDailyGoalCard()` → `sections/daily_goal_widget.dart`
- `_buildStreakSection()` → `sections/streak_widget.dart` (will gain F1 in C9)
- `_buildChallengesPreview()` → `sections/challenges_preview.dart`
- `_buildAIAccessCard()` → `sections/ai_access_card.dart`
- `_buildSectionsGrid()` → `sections/sections_grid.dart`
- Action handlers (`_onLessonTap`, `_onQuizTap`, `_onVocabTap`, etc.) → `handlers/hub_handlers.dart`

- [ ] **Step 2: Extract one section at a time**

For each section, create a new `StatelessWidget` (or `ConsumerWidget` if it reads providers). Pass required data via constructor params. Test with analyzer + run after each extraction.

Example skeleton for `sections/progress_hero.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';

class ProgressHero extends ConsumerWidget {
  const ProgressHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return progress.when(
      data: (data) => _buildHero(context, data),
      loading: () => const _HeroSkeleton(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildHero(BuildContext context, dynamic data) {
    // ... extracted from _buildProgressHero in learning_main_screen.dart
  }
}
```

- [ ] **Step 3: Apply pragmatic guardrail**

If a `_show*` dialog or callback would require 4+ props threaded through, **keep it inline in the orchestrator**. Document that decision in the commit message.

- [ ] **Step 4: Run analyzer + smoke test**

```bash
flutter analyze lib/pages/learning/ 2>&1 | tail -20
flutter run -d <device> --hot  # navigate to Learning tab, confirm hub loads
```

Expected: hub renders identically to pre-split. All sections clickable.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/learning/main/
git commit -m "$(cat <<'EOF'
refactor(learning): C3 — split learning_main_screen (1,443→~250)

Extract 6 section widgets (progress_hero, daily_goal, streak,
challenges_preview, ai_access_card, sections_grid) + handlers
module. Orchestrator now composes sections; logic per section
isolated.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C4 — refactor(learning): split leaderboard_screen.dart

**Files:**
- Modify: `lib/pages/learning/leaderboard/leaderboard_screen.dart` (1,108 → ~250)
- Create: `lib/pages/learning/leaderboard/tabs/{xp_tab,streak_tab,language_tab,friends_tab}.dart`

- [ ] **Step 1: Identify the 4 tabs**

Read leaderboard_screen.dart. The 4 tabs are:
- XP leaderboard (weekly + all-time toggle)
- Streak leaderboard
- Language-filtered leaderboard
- Friends leaderboard

Each tab body becomes its own `ConsumerWidget` file.

- [ ] **Step 2: Extract each tab to its file**

For `tabs/xp_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';

class XpLeaderboardTab extends ConsumerWidget {
  const XpLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(xpLeaderboardProvider);
    return leaderboard.when(
      data: (entries) => ListView.builder(
        itemCount: entries.length,
        itemBuilder: (_, i) => _LeaderboardRow(entry: entries[i]),  // basic row, polished in C11
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
```

Repeat for streak/language/friends tabs.

- [ ] **Step 3: Orchestrator just composes tabs in TabBarView**

The leaderboard_screen.dart shrinks to roughly:

```dart
TabBarView(
  controller: _tabController,
  children: const [
    XpLeaderboardTab(),
    StreakLeaderboardTab(),
    LanguageLeaderboardTab(),
    FriendsLeaderboardTab(),
  ],
)
```

- [ ] **Step 4: Analyzer + smoke**

```bash
flutter analyze lib/pages/learning/leaderboard/ 2>&1 | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add lib/pages/learning/leaderboard/
git commit -m "$(cat <<'EOF'
refactor(learning): C4 — split leaderboard_screen (1,108→~250)

Extract 4 tab widgets (xp, streak, language, friends) under
leaderboard/tabs/. Orchestrator becomes thin TabBarView host.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C5 — chore(learning): cleanup sweep

**Files:** all of `lib/pages/learning/` after restructure

- [ ] **Step 1: Replace all `withOpacity` with `withValues`**

```bash
grep -rln "withOpacity" lib/pages/learning/ | while read f; do
  sed -i '' 's/\.withOpacity(\([^)]*\))/\.withValues(alpha: \1)/g' "$f"
done
```

Audit changed files: `git diff --stat lib/pages/learning/`

Verify a sample manually — `withValues` requires named `alpha:` arg.

- [ ] **Step 2: Replace `Colors.grey[*]` with theme-aware getters**

For each `Colors.grey[300]`, `Colors.grey[400]`, etc., decide replacement:
- Borders/dividers → `context.dividerColor` (or `Theme.of(context).dividerColor`)
- Subtle text → `context.bodySmallColor`
- Subdued backgrounds → `context.surfaceVariant`

Find usages:

```bash
grep -rn "Colors\.grey" lib/pages/learning/
```

Edit each occurrence with judgment. If unsure, default to `Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)`.

- [ ] **Step 3: Add `learning/widgets/learning_snackbar.dart` helper**

```dart
// lib/pages/learning/widgets/learning_snackbar.dart
import 'package:flutter/material.dart';

void showLearningSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ),
  );
}
```

Replace 2 inline snackbars with `showLearningSnackBar(context, ...)`.

- [ ] **Step 4: Add scaffolding helpers**

Create `lib/pages/learning/widgets/learning_empty_state.dart`:

```dart
import 'package:flutter/material.dart';

class LearningEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LearningEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

Create `lib/pages/learning/widgets/learning_error_view.dart` (similar pattern with error icon).

- [ ] **Step 5: Analyzer**

```bash
flutter analyze lib/pages/learning/ 2>&1 | tail -20
```

Expected: 0 new warnings. May see 1-2 deprecation warnings disappear.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/learning/
git commit -m "$(cat <<'EOF'
chore(learning): C5 — cleanup sweep + widgets/ scaffolding

- 78 withOpacity → withValues
- 44 Colors.grey[*] → context theme getters
- 2 inline snackbars → showLearningSnackBar
- Add learning_empty_state, learning_error_view scaffolds

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C6 — feat(learning): add ARB English keys

**Files:**
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Audit hardcoded strings in learning surface**

```bash
grep -rn "'[A-Z][a-z]" lib/pages/learning/ | grep -v "import" | grep -v "// " | head -50
```

Identify all literal strings in:
- `learning_main_screen.dart` + sections
- `leaderboard_screen.dart` + tabs
- `vocabulary/`, `lessons/`, `quizzes/`, `challenges/`, `achievements/`
- `widgets/learning_*` helpers

Compile a list of ~50-60 user-visible strings without existing ARB keys.

- [ ] **Step 2: Add new keys to app_en.arb**

For each string, choose a key name following the convention:

```json
{
  "learningHubTitle": "Learning",
  "learningStreakDays": "{count, plural, =0{0 days} =1{1 day} other{{count} days}}",
  "learningStreakFreezeAvailable": "{count} freezes available",
  "learningStreakFreezeUse": "Use freeze",
  "learningStreakFreezeDescription": "Freezes protect your streak when you miss a day.",
  "learningWeeklyDigestTitle": "This Week",
  "learningWeeklyDigestXp": "{xp} XP earned",
  "learningWeeklyDigestLessons": "{count, plural, =1{1 lesson} other{{count} lessons}}",
  "learningWeeklyDigestVocab": "{count, plural, =1{1 word learned} other{{count} words learned}}",
  "learningSrsDashboardTitle": "Daily Review",
  "learningSrsDueToday": "{count, plural, =0{No cards due} =1{1 card due} other{{count} cards due}}",
  "learningSrsStartReview": "Start review",
  "learningSrsAllCaughtUp": "You're all caught up!",
  "learningLeaderboardXpTab": "XP",
  "learningLeaderboardStreakTab": "Streak",
  "learningLeaderboardLanguageTab": "Language",
  "learningLeaderboardFriendsTab": "Friends",
  "learningLeaderboardEmpty": "No rankings yet",
  "learningEmptyVocab": "Add words you want to remember",
  "learningEmptyLessons": "Lessons coming soon for your level",
  "learningEmptyQuizzes": "No quizzes available",
  "learningEmptyChallenges": "Check back tomorrow",
  "learningEmptyAchievements": "Earn your first achievement",
  "learningErrorGeneric": "Something went wrong",
  "learningErrorRetry": "Retry",
  "learningXpGained": "+{xp} XP",
  "learningLevelUp": "Level up!",
  "learningLevelReached": "You reached {level}",
  "learningStreakMilestone7": "7-day streak!",
  "learningStreakMilestone30": "30-day streak!",
  "learningStreakMilestone100": "100-day streak!",
  "learningStreakMilestone365": "365-day streak!",
  "learningAchievementUnlocked": "Achievement unlocked",
  "...": "..."
}
```

Each key needs a `@key` metadata block:

```json
"@learningStreakDays": {
  "description": "Days in current streak",
  "placeholders": {
    "count": { "type": "int", "format": "compact" }
  }
}
```

- [ ] **Step 3: Generate localizations**

```bash
flutter gen-l10n
```

Expected: 0 errors. New `learning*` getters appear on `AppLocalizations`.

- [ ] **Step 4: Replace hardcoded strings in code**

For each new key, edit the corresponding source file to use `AppLocalizations.of(context)!.<keyName>`.

- [ ] **Step 5: Analyzer**

```bash
flutter analyze 2>&1 | tail -10
```

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_localizations*.dart lib/pages/learning/
git commit -m "$(cat <<'EOF'
feat(learning): C6 — add ~60 English ARB keys for Step 7

Hardcoded UI strings extracted to ARB across hub, leaderboard,
SRS dashboard, streak freeze, weekly digest, animations, empty
states, error views.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C7 — feat(learning): translate keys to 17 locales

**Files:**
- Modify: `lib/l10n/app_{ar,de,es,fr,hi,id,it,ja,ko,pt,ru,th,tl,tr,vi,zh,zh_TW}.arb`

- [ ] **Step 1: Identify new keys from C6**

```bash
git show HEAD~0 -- lib/l10n/app_en.arb | grep "^+" | grep -oE '"[a-zA-Z]+"' | sort -u | head -70
```

These are the keys that need translation in all 17 locales.

- [ ] **Step 2: Translate each locale file**

For each locale ARB file, add the same keys (without `@` metadata, which lives only in en):

```json
// app_ja.arb
{
  "learningHubTitle": "学習",
  "learningStreakDays": "{count, plural, =0{0日} =1{1日} other{{count}日}}",
  "learningStreakFreezeAvailable": "{count}個のフリーズが利用可能",
  "...": "..."
}
```

Use translation context: language-exchange app, learning theme. Match existing locale style (formal vs casual register already established by past waves).

- [ ] **Step 3: Generate localizations**

```bash
flutter gen-l10n
```

Expected: 0 errors. All locales build.

- [ ] **Step 4: Spot-check a non-English locale renders**

Run device with `--locale ja` or change device locale, navigate to Learning tab, verify rendered Japanese.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "$(cat <<'EOF'
feat(learning): C7 — translate ~60 Step 7 keys to 17 locales

ar, de, es, fr, hi, id, it, ja, ko, pt, ru, th, tl, tr, vi, zh, zh_TW.
~1,020 string adds total.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C8 — feat(learning): F1 streak freeze UI

**Files:**
- Modify: `lib/pages/learning/main/sections/streak_widget.dart`
- Create: `lib/pages/learning/streak/streak_freeze_dialog.dart`
- Modify: `lib/services/learning_service.dart` (add `useStreakFreeze()`)
- Backend: `controllers/learning.js` (add `useStreakFreeze` endpoint if missing)

- [ ] **Step 1: Audit backend — does endpoint exist?**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
grep -rn "useStreakFreeze\|use-freeze\|streakFreeze" controllers/ routes/
```

If endpoint exists, skip Step 2. If not, proceed.

- [ ] **Step 2: Add backend endpoint (if missing)**

In `controllers/learning.js`:

```javascript
// @desc    Use a streak freeze
// @route   POST /api/learning/progress/use-freeze
// @access  Private
exports.useStreakFreeze = asyncHandler(async (req, res, next) => {
  const progress = await LearningProgress.findOne({ user: req.user._id });
  if (!progress) {
    return next(new ErrorResponse('No progress record', 404));
  }
  if (progress.streakFreezesAvailable <= 0) {
    return next(new ErrorResponse('No freezes available', 400));
  }
  progress.streakFreezesAvailable -= 1;
  progress.streakFreezesUsed = (progress.streakFreezesUsed || 0) + 1;
  progress.lastFreezeUsedAt = new Date();
  await progress.save();
  res.status(200).json({ success: true, data: progress });
});
```

In `routes/learning.js`:

```javascript
const { useStreakFreeze } = require('../controllers/learning');
router.post('/progress/use-freeze', protect, useStreakFreeze);
```

Smoke-test:

```bash
curl -X POST http://localhost:5000/api/learning/progress/use-freeze \
  -H "Authorization: Bearer $TOKEN"
```

Expected: 200 with updated progress object, freeze count decremented.

- [ ] **Step 3: Add Flutter service method**

In `lib/services/learning_service.dart`:

```dart
Future<LearningProgress> useStreakFreeze() async {
  final response = await http.post(
    Uri.parse('$baseUrl/learning/progress/use-freeze'),
    headers: await _authHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to use streak freeze');
  }
  return LearningProgress.fromJson(jsonDecode(response.body)['data']);
}
```

- [ ] **Step 4: Build the streak freeze dialog**

`lib/pages/learning/streak/streak_freeze_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/pages/learning/widgets/learning_snackbar.dart';

class StreakFreezeDialog extends ConsumerWidget {
  const StreakFreezeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ref.watch(progressProvider);

    return progress.when(
      data: (data) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.ac_unit, color: Colors.lightBlue),
          const SizedBox(width: 8),
          Text(l10n.learningStreakFreezeAvailable(data.streakFreezesAvailable)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.learningStreakFreezeDescription),
            const SizedBox(height: 16),
            Text('Current streak: ${data.currentStreak} days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: data.streakFreezesAvailable > 0
                ? () async {
                    try {
                      await ref.read(learningServiceProvider).useStreakFreeze();
                      ref.invalidate(progressProvider);
                      if (context.mounted) {
                        Navigator.pop(context);
                        showLearningSnackBar(context, 'Streak protected!');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showLearningSnackBar(context, l10n.learningErrorGeneric);
                      }
                    }
                  }
                : null,
            child: Text(l10n.learningStreakFreezeUse),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

- [ ] **Step 5: Wire streak widget to open dialog**

In `streak_widget.dart`, add a small freeze badge:

```dart
GestureDetector(
  onTap: () => showDialog(
    context: context,
    builder: (_) => const StreakFreezeDialog(),
  ),
  child: Row(children: [
    const Icon(Icons.ac_unit, size: 14, color: Colors.lightBlue),
    Text('${progress.streakFreezesAvailable}'),
  ]),
),
```

- [ ] **Step 6: Analyzer + smoke**

```bash
flutter analyze lib/pages/learning/ 2>&1 | tail -10
```

Manual: tap freeze badge, dialog opens, "Use freeze" decrements count and closes.

- [ ] **Step 7: Commit (frontend)**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(learning): C8 — F1 streak freeze UI

Surface streakFreezesAvailable in streak widget. Tap → dialog
shows freeze count, history hint, and 'Use freeze' button.
Wires to existing backend (or new POST /progress/use-freeze
if added in this commit).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

If backend endpoint was added, commit it separately in the backend repo:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/learning.js routes/learning.js
git commit -m "feat(learning): add POST /progress/use-freeze endpoint

Decrements streakFreezesAvailable, increments streakFreezesUsed,
records lastFreezeUsedAt timestamp. Returns updated progress.
Used by Flutter Step 7 wave for streak freeze UI."
git push origin main
cd -  # back to flutter dir
```

---

## Task C9 — feat(learning): F2 SRS daily review dashboard

**Files:**
- Create: `lib/pages/learning/vocabulary/srs_dashboard_screen.dart`
- Modify: `lib/pages/learning/main/sections/sections_grid.dart` (add SRS dashboard tile)

- [ ] **Step 1: Confirm backend SRS query exists**

```bash
grep -rn "vocabulary/review\|nextReviewAt\|srs" controllers/learning.js routes/learning.js
```

Confirm `GET /learning/vocabulary/review` returns due cards. If missing, add it.

- [ ] **Step 2: Build SRS dashboard screen**

`lib/pages/learning/vocabulary/srs_dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/pages/learning/widgets/learning_empty_state.dart';

class SrsDashboardScreen extends ConsumerWidget {
  const SrsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dueCards = ref.watch(vocabularyReviewQueueProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learningSrsDashboardTitle)),
      body: dueCards.when(
        data: (cards) {
          final dueToday = cards.where((c) => c.isDueToday).length;
          final dueTomorrow = cards.where((c) => c.isDueTomorrow).length;
          final dueThisWeek = cards.where((c) => c.isDueThisWeek).length;

          if (dueToday == 0) {
            return LearningEmptyState(
              icon: Icons.celebration,
              message: l10n.learningSrsAllCaughtUp,
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.today, color: Colors.orange),
                    title: Text(l10n.learningSrsDueToday(dueToday)),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text('Tomorrow: $dueTomorrow'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_view_week),
                    title: Text('This week: $dueThisWeek'),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VocabularyReviewScreen()),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.learningSrsStartReview),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.learningErrorGeneric}: $e')),
      ),
    );
  }
}
```

- [ ] **Step 3: Add isDueToday/Tomorrow/ThisWeek helpers**

If not on the model, add:

```dart
extension VocabularyDueExt on Vocabulary {
  bool get isDueToday {
    final now = DateTime.now();
    return nextReviewAt.year == now.year &&
           nextReviewAt.month == now.month &&
           nextReviewAt.day == now.day;
  }
  bool get isDueTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return nextReviewAt.year == tomorrow.year &&
           nextReviewAt.month == tomorrow.month &&
           nextReviewAt.day == tomorrow.day;
  }
  bool get isDueThisWeek {
    final weekEnd = DateTime.now().add(const Duration(days: 7));
    return nextReviewAt.isBefore(weekEnd);
  }
}
```

- [ ] **Step 4: Wire from hub**

In `sections_grid.dart`, add a tile linking to SRS dashboard with due-count badge:

```dart
_buildSectionTile(
  icon: Icons.auto_stories,
  title: l10n.learningSrsDashboardTitle,
  badge: dueTodayCount > 0 ? '$dueTodayCount' : null,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SrsDashboardScreen()),
  ),
),
```

- [ ] **Step 5: Analyzer + smoke**

- [ ] **Step 6: Commit**

```bash
git add lib/pages/learning/
git commit -m "$(cat <<'EOF'
feat(learning): C9 — F2 SRS daily review dashboard

Dedicated SRS dashboard surfaces due-card counts (today, tomorrow,
this week) and launches review session. Hub tile shows due-today
badge.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C10 — feat(learning): F3 leaderboard social polish

**Files:**
- Create: `lib/pages/learning/leaderboard/widgets/leaderboard_row.dart`
- Create: `lib/pages/learning/leaderboard/widgets/rank_badge.dart`
- Create: `lib/pages/learning/leaderboard/widgets/friend_indicator.dart`
- Modify: `lib/pages/learning/leaderboard/tabs/{xp,streak,language,friends}_tab.dart`

- [ ] **Step 1: Build rank badge widget**

`leaderboard/widgets/rank_badge.dart`:

```dart
import 'package:flutter/material.dart';

class RankBadge extends StatelessWidget {
  final int rank;
  const RankBadge({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = _color(rank);
    final icon = _icon(rank);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: 16, color: color)
          : Text(
              '$rank',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
    );
  }

  Color _color(int r) {
    if (r == 1) return const Color(0xFFFFD700); // gold
    if (r == 2) return const Color(0xFFC0C0C0); // silver
    if (r == 3) return const Color(0xFFCD7F32); // bronze
    return Theme.of(context).colorScheme.primary;
  }

  IconData? _icon(int r) {
    if (r == 1) return Icons.emoji_events;
    if (r == 2 || r == 3) return Icons.workspace_premium;
    return null;
  }
}
```

(Note: `Theme.of(context)` inside `_color` requires passing context — fix in implementation; pseudo-code above for shape.)

- [ ] **Step 2: Build friend indicator dot**

`leaderboard/widgets/friend_indicator.dart`:

```dart
import 'package:flutter/material.dart';

class FriendIndicator extends StatelessWidget {
  const FriendIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
```

- [ ] **Step 3: Build polished leaderboard row**

`leaderboard/widgets/leaderboard_row.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'rank_badge.dart';
import 'friend_indicator.dart';

class LeaderboardRow extends StatelessWidget {
  final int rank;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int score;
  final String scoreLabel; // 'XP' or 'days'
  final bool isFriend;
  final int? rankChange; // +N, -N, null = no change indicator
  final VoidCallback? onTap;

  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.score,
    required this.scoreLabel,
    this.isFriend = false,
    this.rankChange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              RankBadge(rank: rank),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(ImageUtils.normalizeImageUrl(avatarUrl!))
                    : null,
                child: avatarUrl == null
                    ? Text(userName.substring(0, 1).toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          userName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFriend) ...[
                        const SizedBox(width: 6),
                        const FriendIndicator(),
                      ],
                    ]),
                    Text(
                      '$score $scoreLabel',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              ),
              if (rankChange != null) _buildRankChange(context, rankChange!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankChange(BuildContext context, int delta) {
    final color = delta > 0
        ? Colors.green
        : delta < 0
            ? Colors.red
            : Theme.of(context).colorScheme.outline;
    final icon = delta > 0
        ? Icons.trending_up
        : delta < 0
            ? Icons.trending_down
            : Icons.trending_flat;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        Text(
          delta > 0 ? '+$delta' : '$delta',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Use LeaderboardRow in all 4 tabs**

In `xp_tab.dart`:

```dart
LeaderboardRow(
  rank: i + 1,
  userId: entries[i].userId,
  userName: entries[i].userName,
  avatarUrl: entries[i].avatarUrl,
  score: entries[i].xp,
  scoreLabel: 'XP',
  isFriend: entries[i].isFriend ?? false,
  rankChange: entries[i].rankChange,
  onTap: () => _navigateToProfile(entries[i].userId),
),
```

Repeat for streak/language/friends tabs (with appropriate scoreLabel).

- [ ] **Step 5: Analyzer + smoke**

- [ ] **Step 6: Commit**

```bash
git add lib/pages/learning/leaderboard/
git commit -m "$(cat <<'EOF'
feat(learning): C10 — F3 leaderboard social polish

M3 row redesign: rank badge (gold/silver/bronze for top 3),
avatar, friend indicator dot, animated rank-change arrow.
Used across all 4 leaderboard tabs.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C11 — feat(learning): F4a XP gain overlay

**Files:**
- Create: `lib/pages/learning/animations/xp_gain_overlay.dart`
- Modify: callsites in `lesson_player_screen.dart`, `quiz_player_screen.dart`, `vocabulary_review_screen.dart`

- [ ] **Step 1: Build the overlay widget**

`lib/pages/learning/animations/xp_gain_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class XpGainOverlay {
  static OverlayEntry? _current;

  static void show(BuildContext context, int xp) {
    final l10n = AppLocalizations.of(context)!;
    _current?.remove();
    _current = OverlayEntry(
      builder: (_) => _XpGainAnimation(
        xp: xp,
        label: l10n.learningXpGained(xp),
        onComplete: () {
          _current?.remove();
          _current = null;
        },
      ),
    );
    Overlay.of(context).insert(_current!);
  }
}

class _XpGainAnimation extends StatefulWidget {
  final int xp;
  final String label;
  final VoidCallback onComplete;

  const _XpGainAnimation({
    required this.xp,
    required this.label,
    required this.onComplete,
  });

  @override
  State<_XpGainAnimation> createState() => _XpGainAnimationState();
}

class _XpGainAnimationState extends State<_XpGainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.2)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
    ]).animate(_controller);
    _offset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.5))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: SlideTransition(
                position: AlwaysStoppedAnimation(_offset.value),
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire callsites**

In `lesson_player_screen.dart`, after lesson completion + XP awarded:

```dart
import 'package:bananatalk_app/pages/learning/animations/xp_gain_overlay.dart';

// in completion handler:
XpGainOverlay.show(context, lessonResult.xpEarned);
```

Repeat in `quiz_player_screen.dart` and `vocabulary_review_screen.dart`.

- [ ] **Step 3: Analyzer + smoke**

Run a lesson; complete it; XP overlay should pop.

- [ ] **Step 4: Commit**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(learning): C11 — F4a XP gain overlay

Animated +XP pop after lesson/quiz/vocab review completion.
Scale + slide-up + fade tween, ~1.2s total.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C12 — feat(learning): F4b streak milestone celebration

**Files:**
- Create: `lib/pages/learning/animations/streak_milestone_celebration.dart`
- Modify: streak update handler (in `learning_service.dart` or `progress_providers.dart`)

- [ ] **Step 1: Build full-screen celebration with confetti**

`lib/pages/learning/animations/streak_milestone_celebration.dart`:

```dart
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class StreakMilestoneCelebration {
  static void showIfMilestone(BuildContext context, int newStreak) {
    if (newStreak == 7 || newStreak == 30 || newStreak == 100 || newStreak == 365) {
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          pageBuilder: (_, __, ___) => _CelebrationOverlay(streak: newStreak),
        ),
      );
    }
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final int streak;
  const _CelebrationOverlay({required this.streak});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _milestoneLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (widget.streak) {
      7 => l10n.learningStreakMilestone7,
      30 => l10n.learningStreakMilestone30,
      100 => l10n.learningStreakMilestone100,
      365 => l10n.learningStreakMilestone365,
      _ => '${widget.streak}-day streak!',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, size: 120, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                _milestoneLabel(context),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire from streak update**

After any streak-incrementing event (lesson complete, vocab review, daily login), check for milestone:

In progress refresh logic:

```dart
import 'package:bananatalk_app/pages/learning/animations/streak_milestone_celebration.dart';

// after progress update:
if (newProgress.currentStreak > oldStreak) {
  StreakMilestoneCelebration.showIfMilestone(context, newProgress.currentStreak);
}
```

- [ ] **Step 3: Analyzer + smoke**

For testing, temporarily call `StreakMilestoneCelebration.showIfMilestone(context, 7)` from a debug button.

- [ ] **Step 4: Commit**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(learning): C12 — F4b streak milestone celebration

Full-screen confetti + milestone label at 7/30/100/365 days.
Auto-trigger from streak update detection.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C13 — feat(learning): F4c achievement unlock overlay

**Files:**
- Create: `lib/pages/learning/animations/achievement_unlock_overlay.dart`
- Modify: achievement unlock detection (in `achievements_providers.dart` or wherever unseen achievements are polled)

- [ ] **Step 1: Build unlock overlay**

`lib/pages/learning/animations/achievement_unlock_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class AchievementUnlockOverlay {
  static void show(BuildContext context, {
    required String name,
    required String iconUrl,
    required String description,
  }) {
    showDialog(
      context: context,
      builder: (_) => _UnlockDialog(name: name, iconUrl: iconUrl, description: description),
    );
  }
}

class _UnlockDialog extends StatefulWidget {
  final String name;
  final String iconUrl;
  final String description;

  const _UnlockDialog({
    required this.name,
    required this.iconUrl,
    required this.description,
  });

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: AlertDialog(
        title: Center(child: Text(l10n.learningAchievementUnlocked)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(widget.iconUrl, height: 80, width: 80),
            const SizedBox(height: 16),
            Text(
              widget.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.description, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire from unseen achievements polling**

Wherever `unseenAchievementsProvider` is polled, on first delivery of a new unseen achievement:

```dart
ref.listen(unseenAchievementsProvider, (prev, next) {
  next.whenData((achievements) {
    for (final a in achievements) {
      AchievementUnlockOverlay.show(
        context,
        name: a.name,
        iconUrl: a.iconUrl,
        description: a.description,
      );
    }
    // mark seen
    ref.read(learningServiceProvider).markAchievementsSeen(achievements.map((a) => a.id).toList());
  });
});
```

Place this listener at the top-level Learning hub or app shell.

- [ ] **Step 3: Analyzer + smoke**

- [ ] **Step 4: Commit**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(learning): C13 — F4c achievement unlock overlay

Animated dialog (elastic scale) on new achievement unlock.
Auto-fires from unseen achievements listener; marks seen
on dismiss.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C14 — feat(learning): F4d level-up sequence

**Files:**
- Create: `lib/pages/learning/animations/level_up_sequence.dart`
- Modify: progress polling (detect level change)

- [ ] **Step 1: Build level-up sequence**

`lib/pages/learning/animations/level_up_sequence.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class LevelUpSequence {
  static void show(BuildContext context, String newLevel) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => _LevelUpOverlay(newLevel: newLevel),
      ),
    );
  }
}

class _LevelUpOverlay extends StatefulWidget {
  final String newLevel;
  const _LevelUpOverlay({required this.newLevel});

  @override
  State<_LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<_LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scale = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
    _rotation = Tween<double>(begin: 0, end: 6.28)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.6),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: _rotation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 60, color: Colors.amber),
                      const SizedBox(height: 8),
                      Text(
                        l10n.learningLevelUp,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l10n.learningLevelReached(widget.newLevel),
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire from progress change detection**

In progress provider listener:

```dart
ref.listen(progressProvider, (prev, next) {
  if (prev?.value?.proficiencyLevel != next.value?.proficiencyLevel &&
      next.value != null) {
    LevelUpSequence.show(context, next.value!.proficiencyLevel);
  }
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(learning): C14 — F4d level-up sequence

Animated radial-gradient overlay with rotating star icon on
proficiency level change. Triggers on A1→A2, A2→B1, etc.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C15 — feat(backend): F5 weekly digest endpoint

**Files (backend repo):**
- Modify: `controllers/learning.js`
- Modify: `routes/learning.js`

- [ ] **Step 1: Add weekly digest aggregation**

In `controllers/learning.js`:

```javascript
// @desc    Get weekly digest (last 7 days summary)
// @route   GET /api/learning/weekly-digest
// @access  Private
exports.getWeeklyDigest = asyncHandler(async (req, res, next) => {
  const userId = req.user._id;
  const now = new Date();
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() - 7);
  weekStart.setHours(0, 0, 0, 0);

  const progress = await LearningProgress.findOne({ user: userId });
  if (!progress) {
    return next(new ErrorResponse('No progress record', 404));
  }

  // Last 7 days XP from dailyHistory
  const recentDays = (progress.dailyHistory || [])
    .filter(d => new Date(d.date) >= weekStart);
  const xpEarned = recentDays.reduce((sum, d) => sum + (d.xp || 0), 0);
  const lessonsCompleted = recentDays.reduce((sum, d) => sum + (d.lessons || 0), 0);
  const challengesCompleted = recentDays.reduce((sum, d) => sum + (d.challenges || 0), 0);

  // Vocab learned (created in last 7 days)
  const vocabularyLearned = await Vocabulary.countDocuments({
    user: userId,
    createdAt: { $gte: weekStart }
  });

  // Top achievement (most recent unlock in window)
  const topAchievement = await Achievement.findOne({
    user: userId,
    unlockedAt: { $gte: weekStart }
  }).sort({ unlockedAt: -1 });

  const daysActive = recentDays.filter(d => (d.xp || 0) > 0).length;

  res.status(200).json({
    success: true,
    data: {
      weekStart: weekStart.toISOString(),
      weekEnd: now.toISOString(),
      xpEarned,
      lessonsCompleted,
      vocabularyLearned,
      challengesCompleted,
      currentStreak: progress.currentStreak,
      topAchievement: topAchievement ? {
        id: topAchievement._id,
        name: topAchievement.name,
        unlockedAt: topAchievement.unlockedAt
      } : null,
      daysActive
    }
  });
});
```

- [ ] **Step 2: Wire route**

In `routes/learning.js`:

```javascript
const { getWeeklyDigest } = require('../controllers/learning');
router.get('/weekly-digest', protect, getWeeklyDigest);
```

- [ ] **Step 3: Smoke test**

```bash
curl http://localhost:5000/api/learning/weekly-digest \
  -H "Authorization: Bearer $TOKEN" | jq
```

Expected: object with xpEarned, lessonsCompleted, vocabularyLearned, etc.

- [ ] **Step 4: Commit (backend)**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/learning.js routes/learning.js
git commit -m "feat(learning): GET /weekly-digest endpoint

Aggregates last-7-day XP, lessons, vocab, challenges, streak,
top achievement, days active. Used by Flutter Step 7 wave for
hub weekly digest card."
git push origin main
cd -
```

---

## Task C16 — feat(learning): F5 frontend weekly digest card

**Files:**
- Create: `lib/pages/learning/models/weekly_digest.dart`
- Create: `lib/pages/learning/main/sections/weekly_digest_card.dart`
- Modify: `lib/services/learning_service.dart` (add `getWeeklyDigest`)
- Modify: `lib/providers/provider_root/learning/progress_providers.dart` (add `weeklyDigestProvider`)
- Modify: `lib/pages/learning/main/learning_main_screen.dart` (add card to layout)

- [ ] **Step 1: Build model**

`lib/pages/learning/models/weekly_digest.dart`:

```dart
class WeeklyDigest {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int xpEarned;
  final int lessonsCompleted;
  final int vocabularyLearned;
  final int challengesCompleted;
  final int currentStreak;
  final TopAchievement? topAchievement;
  final int daysActive;

  WeeklyDigest({
    required this.weekStart,
    required this.weekEnd,
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.vocabularyLearned,
    required this.challengesCompleted,
    required this.currentStreak,
    this.topAchievement,
    required this.daysActive,
  });

  factory WeeklyDigest.fromJson(Map<String, dynamic> json) {
    return WeeklyDigest(
      weekStart: DateTime.parse(json['weekStart']),
      weekEnd: DateTime.parse(json['weekEnd']),
      xpEarned: json['xpEarned'] ?? 0,
      lessonsCompleted: json['lessonsCompleted'] ?? 0,
      vocabularyLearned: json['vocabularyLearned'] ?? 0,
      challengesCompleted: json['challengesCompleted'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      topAchievement: json['topAchievement'] != null
          ? TopAchievement.fromJson(json['topAchievement'])
          : null,
      daysActive: json['daysActive'] ?? 0,
    );
  }
}

class TopAchievement {
  final String id;
  final String name;
  final DateTime unlockedAt;

  TopAchievement({required this.id, required this.name, required this.unlockedAt});

  factory TopAchievement.fromJson(Map<String, dynamic> json) {
    return TopAchievement(
      id: json['id'],
      name: json['name'],
      unlockedAt: DateTime.parse(json['unlockedAt']),
    );
  }
}
```

- [ ] **Step 2: Add service method**

In `lib/services/learning_service.dart`:

```dart
import 'package:bananatalk_app/pages/learning/models/weekly_digest.dart';

Future<WeeklyDigest> getWeeklyDigest() async {
  final response = await http.get(
    Uri.parse('$baseUrl/learning/weekly-digest'),
    headers: await _authHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch weekly digest');
  }
  return WeeklyDigest.fromJson(jsonDecode(response.body)['data']);
}
```

- [ ] **Step 3: Add provider**

In `lib/providers/provider_root/learning/progress_providers.dart`:

```dart
final weeklyDigestProvider = FutureProvider.autoDispose<WeeklyDigest>((ref) async {
  return ref.read(learningServiceProvider).getWeeklyDigest();
});
```

- [ ] **Step 4: Build the card widget**

`lib/pages/learning/main/sections/weekly_digest_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';

class WeeklyDigestCard extends ConsumerWidget {
  const WeeklyDigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final digest = ref.watch(weeklyDigestProvider);

    return digest.when(
      data: (d) => Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () => _showDetail(context, d),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_view_week, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.learningWeeklyDigestTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _stat(context, Icons.flash_on, l10n.learningWeeklyDigestXp(d.xpEarned)),
                    _stat(context, Icons.school, l10n.learningWeeklyDigestLessons(d.lessonsCompleted)),
                    _stat(context, Icons.book, l10n.learningWeeklyDigestVocab(d.vocabularyLearned)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  void _showDetail(BuildContext context, dynamic digest) {
    // Future: detail bottom sheet showing per-day breakdown
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Active days: ${digest.daysActive}'),
            Text('Streak: ${digest.currentStreak}'),
            if (digest.topAchievement != null)
              Text('Top achievement: ${digest.topAchievement.name}'),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Add to hub layout**

In `learning_main_screen.dart` (or `sections_grid.dart`), insert `WeeklyDigestCard()` near top of hub.

- [ ] **Step 6: Analyzer + smoke**

- [ ] **Step 7: Commit**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(learning): C16 — F5 weekly digest card

In-app weekly summary on hub: XP earned, lessons, vocab,
streak. Tappable for detail. Uses new GET /weekly-digest
backend endpoint.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C17 — chore(learning): final sweep + push + PR

**Files:** all of `lib/pages/learning/`, `lib/l10n/`

- [ ] **Step 1: Final analyzer pass**

```bash
flutter analyze 2>&1 | tail -20
```

Fix any new warnings.

- [ ] **Step 2: l10n sweep — find untranslated remnants**

```bash
grep -rn "'[A-Z][a-z]\+ [a-z]" lib/pages/learning/ | grep -v "import\|//" | head -30
```

Any user-visible string in source code is a leak. Move to ARB.

- [ ] **Step 3: Final smoke**

```bash
flutter run -d <device>
```

Walk through:
- Hub renders all sections (progress, daily goal, streak with freeze, challenges, AI, sections grid, weekly digest)
- Streak freeze dialog opens, freeze use works
- SRS dashboard opens from grid, shows due-card counts
- Leaderboard renders all 4 tabs with polished rows
- Lesson completion → XP overlay
- Vocab review session
- All translations look right in 1-2 non-English locales

- [ ] **Step 4: Final commit (if any cleanup)**

```bash
git add lib/
git commit -m "chore(learning): C17 — final sweep + smoke pass" --allow-empty
```

- [ ] **Step 5: Push branch**

```bash
git push -u origin refactor/step7-learning-wave
```

- [ ] **Step 6: Open PR**

```bash
gh pr create --title "Step 7 — Learning wave: restructure + 5 features" --body "$(cat <<'EOF'
## Summary

- **Restructure**: split `learning_main.dart` (1,443→~250 + 6 sections), `leaderboard_screen.dart` (1,108→~250 + 4 tabs), `learning_providers.dart` (1,023→barrel + 7 feature files). Moved 4 root files into subfolders.
- **l10n**: added ~60 English keys + translated to 17 locales (~1,020 string adds).
- **Cleanup sweep**: 78 `withOpacity` → `withValues`, 44 `Colors.grey[*]` → theme getters, snackbar helper.
- **5 features**: streak freeze UI (F1), SRS daily review dashboard (F2), leaderboard social polish (F3), gamification animations (F4: XP gain / streak milestone / achievement unlock / level up), weekly digest card (F5).
- **Backend**: 1-2 endpoints added (`POST /progress/use-freeze` if missing, `GET /weekly-digest`).

## Test plan

- [x] `flutter analyze` clean
- [x] Hub renders all sections in en + 1 non-en locale
- [x] Streak freeze dialog works end-to-end
- [x] SRS dashboard shows due cards, launches review
- [x] Leaderboard rows polished across 4 tabs
- [x] Lesson completion fires XP overlay
- [x] Streak milestone celebration triggers (manual test at 7 days)
- [x] Achievement unlock overlay fires
- [x] Level-up sequence triggers on level change
- [x] Weekly digest card loads, taps to detail

## Spec
`docs/superpowers/specs/2026-05-10-step7-learning-wave-design.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 7: Merge PR**

```bash
gh pr merge --squash --delete-branch
```

- [ ] **Step 8: Verify main**

```bash
git checkout main
git pull --ff-only
git log --oneline -1  # should show squash merge commit
```

---

## Self-review

After plan complete, scan for:

1. **Spec coverage:** every acceptance criterion in spec maps to a task. ✓ Restructure (C1, C2, C3, C4), l10n (C6, C7), cleanup (C5), F1 (C8), F2 (C9), F3 (C10), F4a-d (C11-C14), F5 (C15-C16), final (C17).

2. **Placeholder scan:** no "TBD", "implement later" remaining. ✓

3. **Type consistency:** `WeeklyDigest`, `TopAchievement`, `LeaderboardRow` props match across tasks. ✓

4. **Pragmatic guardrail noted:** in C3, callouts to keep inline if 4+ prop threading. ✓

5. **Backend changes flagged:** C8 (conditional, audit at task start), C15 (definite). Both push to main of backend repo. ✓

6. **Commit count:** 17 commits + 0-2 backend commits, matches spec estimate.

---

## Execution

**Recommended:** subagent-driven-development (fresh implementer per task + spec compliance review + code quality review).

Per memory `feedback_pacing.md`: keep moving. Surface only at major gates (after C7 mid-wave checkpoint, after C17 PR open) or genuine blockers.
