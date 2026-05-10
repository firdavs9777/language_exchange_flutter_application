# Step 5 — Moments Restructure + April Spec Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `lib/pages/moments/` (14 files, 7,608 lines) into 8 focused subfolders, split the four big files (`create_moment` 2,278, `moment_card` 1,237, `single_moment` 1,015, `moment_filter_sheet` 792), purge debug/heart-emoji love-spam, run the cleanup sweep (snackbars, withOpacity, grey-shades), audit the two April moments specs and remediate stragglers, and bundle two minor features (tag autocomplete, hide-this-user local mute).

**Architecture:** Single-PR mass move with `git mv` + analyzer enforcement, mirroring the cadence of community wave-1 (Step 1) and stories restructure (Step 3). The four big files split by responsibility (orchestrator + sections), with a pragmatic guardrail: if a split adds complexity vs. reduces it, fall back to `git mv` + minor extractions only. Tag autocomplete and hide-user use SharedPreferences (no backend). April spec audit is verification-first; only commits remediation when a gap is found.

**Tech Stack:** Flutter + Riverpod, SharedPreferences, ARB-based l10n (18 locales). No backend changes expected (audit may surface a small `controllers/moments.js` patch).

**Spec:** `docs/superpowers/specs/2026-05-10-step5-moments-restructure-design.md`

**Branch:** `refactor/step5-moments-restructure` (off `main`, already created and spec already committed)

**Project pattern:** No new Flutter widget tests — verification is `flutter analyze` clean per commit + manual smoke at the end. Backend additions (if any) get unit tests where indicated.

## Spec corrections discovered during plan-writing

- **`action_widget.dart` is unused outside its own file.** Verified: the only matches for `ActionButton`/`action_widget` outside that file are unrelated `_ActionButton` private classes in `lib/pages/comments/`, `lib/widgets/community/*`, and `lib/screens/incoming_call_screen.dart`. **Implication:** delete `action_widget.dart` outright in C1; do not migrate it.
- **`update_moment.dart` is a 0-byte orphan.** Confirmed empty + zero importers. **Implication:** `git rm` in C1.
- **External cross-references discovered:**
  - `lib/pages/moments/image_viewer.dart` is imported from `lib/pages/chat/message/message_bubble/image_message_view.dart`, `lib/pages/profile/moments/moment_card.dart`, `lib/pages/community/single/single_community_header.dart`
  - `lib/pages/moments/single_moment.dart` is imported from `lib/pages/community/single/single_community_moments.dart`
  - `lib/pages/moments/moments_main.dart` is imported from `lib/pages/menu_tab/TabBarMenu.dart`
  - `lib/pages/moments/moment_detail_wrapper.dart` is imported from `lib/router/app_router.dart`
  - `lib/pages/moments/saved_moments_screen.dart` imports `lib/pages/moments/moment_card.dart`

  **Implication:** every move task must `grep -rln` for old import paths and update *all* call sites (in-folder + the cross-references above).

- **Cleanup debt counts (re-measured during plan-writing):** 21 `withOpacity`, 28 `ScaffoldMessenger.showSnackBar` (spec said ~26), 26 `Colors.grey[*]` (spec said 25), ~18 `debugPrint` / `print(` total in `lib/pages/moments/*.dart` (spec said ~12). Mostly the 9 `❤️ ` heart-emoji love-spam in `moment_card.dart` (lines 122, 182, 197, 202, 208, 215, 221, 228, 306) plus a handful of legitimate error logs in `create_moment.dart` (`debugPrint('Error loading saved moment filter…')` etc.) which stay.

- **`moment_card.dart` already contains a `_buildActionButton` private helper** (line 1055). The new card subfolder split will fold this in naturally; we do not need to import the orphaned `ActionButton` class from `action_widget.dart`.

Total commits remain 19 (C0–C18) as specified. Estimated wall-time: 3–5 weeks at this cadence.

---

## File Structure (target)

```
lib/pages/moments/
├── widgets/                            NEW
│   ├── moments_snackbar.dart
│   ├── moments_dialog_scaffold.dart
│   ├── moments_empty_state.dart
│   └── moments_error_state.dart
├── feed/                               NEW (was moments_main.dart 492 → ~250)
│   ├── moments_main.dart
│   ├── moments_feed_widget.dart
│   └── moments_filter_button.dart
├── card/                               NEW (was moment_card.dart 1,237)
│   ├── moment_card.dart                  ~300 (orchestrator, branches by type)
│   ├── moment_card_media.dart            full-width image/video card
│   ├── moment_card_gradient.dart         gradient text-only card
│   ├── moment_card_header.dart           avatar + name + timestamp + menu
│   ├── moment_card_actions.dart          like / comment / share / save / 3-dot
│   └── moment_card_double_tap.dart       overlay heart animation
├── single/                             NEW (was single_moment.dart 1,015)
│   ├── single_moment.dart                ~400 (orchestrator)
│   ├── single_moment_header.dart
│   ├── single_moment_content.dart
│   ├── single_moment_comments.dart
│   ├── single_moment_reactions.dart
│   └── comment_input_bar.dart
├── create/                             NEW (was create_moment.dart 2,278)
│   ├── create_moment.dart                ~500 (orchestrator)
│   ├── create_image_section.dart
│   ├── create_text_section.dart          gradient text composer
│   ├── create_chips_row.dart             mood/category/language compact chips
│   ├── create_tag_dialog.dart            tag-add modal (autocomplete added in C16)
│   ├── create_location_picker.dart
│   ├── create_schedule_picker.dart
│   ├── create_privacy_picker.dart
│   └── create_post_action.dart
├── filter/                             NEW (was moment_filter_sheet.dart 792)
│   ├── moment_filter_sheet.dart          ~200 (shell)
│   ├── filter_mood_section.dart
│   ├── filter_category_section.dart
│   ├── filter_language_section.dart
│   ├── filter_privacy_section.dart
│   ├── filter_other_section.dart
│   ├── moment_filter_bar.dart            MOVED
│   ├── moment_filter_model.dart          MOVED
│   └── moment_filter_utility.dart        MOVED
├── viewer/                             NEW
│   ├── image_viewer.dart                 MOVED
│   └── video_player_widget.dart          MOVED
├── saved/                              NEW
│   └── saved_moments_screen.dart         MOVED
└── moment_detail_wrapper.dart          STAYS at root
```

Files to delete: `update_moment.dart` (0 bytes), `action_widget.dart` (42 lines, unused).

---

## Branch setup

- [ ] **Step 1: Confirm branch and clean state**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git status -sb | head -3
git log --oneline -1
```

Expected: branch is `refactor/step5-moments-restructure`, HEAD is the spec commit `docs(moments): spec for Step 5 — moments restructure + April spec audit`.

- [ ] **Step 2: Verify analyzer baseline**

```bash
flutter analyze lib/pages/moments/ 2>&1 | tail -10
```

Expected: any pre-existing warnings are noted but not new errors.

---

## Task C0 — chore(moments): deps audit

**Files:** none

- [ ] **Step 1: Confirm no new deps needed**

Step 5 introduces no new packages; uses existing `flutter_riverpod`, `shared_preferences`, `http`, `image_picker`, `video_player`, `cached_network_image`, `flutter_animate`, `geolocator` (already in pubspec). Verify:

```bash
grep -E "^  (flutter_riverpod|shared_preferences|http|image_picker|video_player|cached_network_image|flutter_animate|geolocator):" pubspec.yaml
```

Expected: every line above present. If anything missing, add via `flutter pub add <name>`. Otherwise no commit (this is an audit task — no-op is the expected outcome).

---

## Task C1 — chore(moments): delete `update_moment.dart` orphan + `action_widget.dart` unused

**Files:**
- Delete: `lib/pages/moments/update_moment.dart` (0 bytes)
- Delete: `lib/pages/moments/action_widget.dart` (42 lines, only `ActionButton` class, unused)

- [ ] **Step 1: Verify both files have zero importers outside themselves**

```bash
grep -rln "pages/moments/update_moment\|pages/moments/action_widget" lib/ 2>/dev/null
```

Expected: empty.

```bash
grep -rn "import.*moments/action_widget\|action_widget.dart" lib/ --include="*.dart"
```

Expected: empty (the file `action_widget.dart` exports only the `ActionButton` class; no other file imports it).

```bash
grep -rn "\\bActionButton\\b" lib/ --include="*.dart" | grep -v "action_widget.dart\|class _ActionButton\|_CallActionButton\|_buildActionButton\|class _CompactActionButton\|FloatingActionButton\|ProfileActionButtons\|class ActionButton\b"
```

Expected: empty (any matches are unrelated symbols).

If any match outside `action_widget.dart` looks like a real importer, STOP and investigate.

- [ ] **Step 2: Delete the files**

```bash
git rm lib/pages/moments/update_moment.dart
git rm lib/pages/moments/action_widget.dart
```

- [ ] **Step 3: Verify analyzer**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: zero new errors.

- [ ] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
chore(moments): C1 — delete update_moment.dart orphan + action_widget.dart unused

update_moment.dart was a 0-byte placeholder. action_widget.dart's only
exported class (ActionButton) had no importers anywhere in lib/.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C2 — chore(moments): purge heart-emoji `debugPrint` from `moment_card.dart`

**Files:**
- Modify: `lib/pages/moments/moment_card.dart` lines 122, 182, 197, 202, 208, 215, 221, 228, 306

- [ ] **Step 1: List the lines to remove**

```bash
grep -n "❤️" lib/pages/moments/moment_card.dart
```

Expected output:

```
122:      debugPrint('❤️ _initLikeStatus: momentId=${widget.moments.id}, userId=$currentUserId, isLiked=$isLiked, likeCount=$likeCount, likedUsers=${widget.moments.likedUsers}');
182:    debugPrint('❤️ toggleLike: momentId=${widget.moments.id}, wasLiked=$previousLiked, prevCount=$previousCount');
197:        debugPrint('❤️ Calling dislikeMoment...');
202:        debugPrint('❤️ Calling likeMoment...');
208:      debugPrint('❤️ API result: $result');
215:        debugPrint('❤️ Updated state: isLiked=$isLiked, likeCount=$likeCount');
221:      debugPrint('❤️ ERROR: $e');
228:        debugPrint('❤️ Reverted to: isLiked=$previousLiked, likeCount=$previousCount');
275:      children: ['❤️', '🔥', '😂', '😢', '😮', '👏'].map((emoji) {  ← KEEP (this is reaction UI)
306:      debugPrint('React to moment error: $e');                       ← downgrade per Step 2
```

- [ ] **Step 2: Remove the 8 love-spam lines and downgrade line 306**

Use the Edit tool to delete each `debugPrint('❤️ …')` line (8 of them at 122, 182, 197, 202, 208, 215, 221, 228). Keep the reaction-UI line at 275 (it's the emoji palette, not a debugPrint). Line 306 (`debugPrint('React to moment error: $e')`) is a real error path — keep as-is.

For example, line 122:

```dart
// BEFORE
      debugPrint('❤️ _initLikeStatus: momentId=${widget.moments.id}, userId=$currentUserId, isLiked=$isLiked, likeCount=$likeCount, likedUsers=${widget.moments.likedUsers}');
```

```dart
// AFTER
      // (line removed)
```

Repeat for the other 7 love-spam lines. Use `Edit` with full surrounding context for each so the edit is unambiguous.

- [ ] **Step 3: Verify all heart-emoji `debugPrint` calls are gone**

```bash
grep -n "❤️.*debugPrint\|debugPrint.*❤️" lib/pages/moments/moment_card.dart
```

Expected: empty.

```bash
grep -cn "debugPrint" lib/pages/moments/moment_card.dart
```

Expected: 1 (only the legitimate `React to moment error` log at line 306).

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/pages/moments/ 2>&1 | tail -10
```

Expected: no new errors.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/moments/moment_card.dart
git commit -m "$(cat <<'EOF'
chore(moments): C2 — purge heart-emoji debugPrint from moment_card

Removes the 8 ❤️-prefixed debugPrint statements added in cfe61cc for
like-toggle debugging. The legitimate error log on line 306 stays.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C3 — refactor(moments): add ~14 English ARB keys

**Files:**
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Identify duplicates first**

```bash
grep -E "^  \"(momentSaved|momentUnsaved|noMomentsYet|momentsRetry|recentTags|noRecentTags|hideMomentsFromUser|momentsHidden|unhideMoments|momentSaveFailed|momentSaveError|momentsLoadError)\"" lib/l10n/app_en.arb
```

Expected output (some keys may already exist):

```
  "momentSaved": "Saved",
  "momentUnsaved": "Removed from saved",
```

(`momentSaved` and `momentUnsaved` already exist per the existing ARB grep at planning time. Reuse them — do NOT redefine.)

- [ ] **Step 2: Add ONLY the new keys to `app_en.arb`**

Open `lib/l10n/app_en.arb`. Just before the closing `}`, add (alphabetized roughly by first key name):

```json
  "momentsLoadError": "Couldn't load moments",
  "@momentsLoadError": { "description": "Error state on moments feed" },

  "momentsRetry": "Try again",
  "@momentsRetry": { "description": "Retry button on moments error state" },

  "recentTags": "Recent tags",
  "@recentTags": { "description": "Header in tag dialog showing tags this user has used recently" },

  "noRecentTags": "No recent tags yet",
  "@noRecentTags": { "description": "Shown when user has no tag history yet" },

  "hideMomentsFromUser": "Hide moments from this user",
  "@hideMomentsFromUser": { "description": "3-dot menu action on a moment card" },

  "momentsHidden": "Moments from this user will be hidden",
  "@momentsHidden": { "description": "Snackbar confirmation after hiding a user's moments" },

  "unhideMoments": "Show moments from this user",
  "@unhideMoments": { "description": "Reverse action — re-show a user's moments" },

  "momentsHiddenCount": "{count, plural, =0{No hidden users} =1{1 user hidden} other{{count} users hidden}}",
  "@momentsHiddenCount": {
    "description": "Plural count of users whose moments are hidden",
    "placeholders": { "count": { "type": "int" } }
  },

  "momentSaveFailed": "Couldn't save moment",
  "@momentSaveFailed": { "description": "Error snackbar when save toggle fails" },

  "tagAlreadyAdded": "Tag already added",
  "@tagAlreadyAdded": { "description": "Snackbar when user tries to add a duplicate tag" },

  "tagLimitReached": "Maximum tags reached",
  "@tagLimitReached": { "description": "Snackbar when tag limit hit" },

  "hideThisUser": "Hide this user's posts",
  "@hideThisUser": { "description": "Short label for the 3-dot menu" }
```

(Re-use `momentSaved` / `momentUnsaved` / `noMomentsYet` / `unableToLoadMoments` etc. that already exist.)

- [ ] **Step 3: Validate JSON**

```bash
python3 -c "import json; json.load(open('lib/l10n/app_en.arb'))" && echo OK
```

Expected: `OK`.

- [ ] **Step 4: Regenerate localizations**

```bash
flutter gen-l10n
```

Expected: no errors. New getters appear in `lib/l10n/app_localizations*.dart` (English-only at this commit; other locales fall back to English until C4 fills them).

- [ ] **Step 5: Verify analyzer**

```bash
flutter analyze lib/l10n/ 2>&1 | tail -10
```

Expected: zero new errors.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_localizations*.dart
git commit -m "$(cat <<'EOF'
refactor(moments): C3 — add ~12 English ARB keys for Step 5

Adds keys for moments error/retry, tag autocomplete (recent/empty),
hide-this-user mute, and tag-dialog edge cases. Reuses existing
momentSaved/momentUnsaved/noMomentsYet keys.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C4 — refactor(moments): translate ARB keys to 17 locales

**Files:**
- Modify: `lib/l10n/app_ar.arb`, `app_de.arb`, `app_es.arb`, `app_fr.arb`, `app_hi.arb`, `app_id.arb`, `app_it.arb`, `app_ja.arb`, `app_ko.arb`, `app_pt.arb`, `app_ru.arb`, `app_th.arb`, `app_tl.arb`, `app_tr.arb`, `app_vi.arb`, `app_zh.arb`, `app_zh_TW.arb`

- [ ] **Step 1: Confirm exact list of new keys to translate**

The 12 keys added in C3:
- `momentsLoadError`
- `momentsRetry`
- `recentTags`
- `noRecentTags`
- `hideMomentsFromUser`
- `momentsHidden`
- `unhideMoments`
- `momentsHiddenCount` (ICU plural)
- `momentSaveFailed`
- `tagAlreadyAdded`
- `tagLimitReached`
- `hideThisUser`

- [ ] **Step 2: For each non-English locale, add the 12 keys with translated values**

Use the same key order and structure as `app_en.arb`. For ICU plurals (`momentsHiddenCount`), preserve the `{count, plural, ...}` syntax — only translate the surrounding strings.

Example for Korean (`app_ko.arb`):

```json
  "momentsLoadError": "모먼트를 불러올 수 없습니다",
  "momentsRetry": "다시 시도",
  "recentTags": "최근 태그",
  "noRecentTags": "최근 태그가 없습니다",
  "hideMomentsFromUser": "이 사용자의 모먼트 숨기기",
  "momentsHidden": "이 사용자의 모먼트가 숨겨집니다",
  "unhideMoments": "이 사용자의 모먼트 다시 표시",
  "momentsHiddenCount": "{count, plural, =0{숨긴 사용자 없음} =1{사용자 1명 숨김} other{사용자 {count}명 숨김}}",
  "momentSaveFailed": "모먼트를 저장할 수 없습니다",
  "tagAlreadyAdded": "이미 추가된 태그입니다",
  "tagLimitReached": "최대 태그 수에 도달했습니다",
  "hideThisUser": "이 사용자의 게시물 숨기기"
```

For ARB metadata (`@key` blocks), match the English structure but DO NOT redefine `@key` for ICU placeholders — only the English file holds those metadata anchors. Other locales need only the value lines.

Translate naturally for each locale. The shape of the key (placeholders, plural) must match English exactly.

Repeat for the other 16 locales: ar, de, es, fr, hi, id, it, ja, pt, ru, th, tl, tr, vi, zh, zh_TW.

If any locale file already has any of these keys (very unlikely — they're all new), skip it for that file.

- [ ] **Step 3: Validate every locale file**

```bash
for f in lib/l10n/app_*.arb; do python3 -c "import json; json.load(open('$f'))" || echo "FAIL: $f"; done
```

Expected: no `FAIL` lines.

- [ ] **Step 4: Regenerate localizations**

```bash
flutter gen-l10n
```

Expected: no errors. Generated files for all 18 locales include the new keys.

- [ ] **Step 5: Verify analyzer**

```bash
flutter analyze lib/l10n/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/
git commit -m "$(cat <<'EOF'
refactor(moments): C4 — translate ~12 Step 5 keys to 17 locales

Mirrors C3 — adds translated values for momentsLoadError, momentsRetry,
recentTags, noRecentTags, hideMomentsFromUser, momentsHidden,
unhideMoments, momentsHiddenCount, momentSaveFailed, tagAlreadyAdded,
tagLimitReached, hideThisUser across ar, de, es, fr, hi, id, it, ja,
ko, pt, ru, th, tl, tr, vi, zh, zh_TW.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C5 — refactor(moments): add `widgets/` scaffolding

**Files:**
- Create: `lib/pages/moments/widgets/moments_snackbar.dart`
- Create: `lib/pages/moments/widgets/moments_dialog_scaffold.dart`
- Create: `lib/pages/moments/widgets/moments_empty_state.dart`
- Create: `lib/pages/moments/widgets/moments_error_state.dart`

These are direct copies of the community / stories scaffolding pattern, with names rebranded.

- [ ] **Step 1: Create `moments_snackbar.dart`**

```bash
mkdir -p lib/pages/moments/widgets
```

```dart
// lib/pages/moments/widgets/moments_snackbar.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum MomentsSnackBarType { info, success, error }

void showMomentsSnackBar(
  BuildContext context, {
  required String message,
  MomentsSnackBarType type = MomentsSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    MomentsSnackBarType.success => AppColors.primary,
    MomentsSnackBarType.error => AppColors.error,
    MomentsSnackBarType.info => Theme.of(context).colorScheme.surface,
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
      duration: duration,
    ),
  );
}
```

- [ ] **Step 2: Create `moments_dialog_scaffold.dart`**

```dart
// lib/pages/moments/widgets/moments_dialog_scaffold.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class MomentsDialogScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const MomentsDialogScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: padding,
      child: SafeArea(child: child),
    );
  }
}
```

- [ ] **Step 3: Create `moments_empty_state.dart`**

```dart
// lib/pages/moments/widgets/moments_empty_state.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class MomentsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const MomentsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.textMuted),
            const SizedBox(height: 16),
            Text(title, style: context.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: context.bodySmall.copyWith(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `moments_error_state.dart`**

```dart
// lib/pages/moments/widgets/moments_error_state.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class MomentsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const MomentsErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ignore: prefer_const_constructors
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, style: context.titleMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel ?? 'Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Verify analyzer**

```bash
flutter analyze lib/pages/moments/widgets/ 2>&1 | tail -10
```

Expected: zero errors. (These widgets are not yet imported — analyzer should flag them as unused only if `unused_element` is enabled, which is not the project default.)

- [ ] **Step 6: Commit**

```bash
git add lib/pages/moments/widgets/
git commit -m "$(cat <<'EOF'
refactor(moments): C5 — add widgets/ scaffolding (snackbar, dialog, empty, error)

Mirrors community/widgets/ and stories/widgets/ — gives the wave a
single helper for snackbars (~28 inline call sites land on this in C6)
plus shared empty/error/dialog primitives.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C6 — refactor(moments): migrate ~28 inline snackbars to `showMomentsSnackBar`

**Files:**
- Modify: every file in `lib/pages/moments/` that uses `ScaffoldMessenger.of(context).showSnackBar(`

- [ ] **Step 1: Enumerate the call sites**

```bash
grep -rn "ScaffoldMessenger.of(context).showSnackBar" lib/pages/moments/*.dart
```

Expected: ~28 matches across `create_moment.dart`, `single_moment.dart`, `moment_card.dart`, `moments_main.dart`, `saved_moments_screen.dart`, `moment_filter_sheet.dart`.

- [ ] **Step 2: For each call site, decide migration vs. skip**

Migrate only when the snackbar's `content` is a plain `Text(...)`. **Skip** when the content is a `Row` with icons or a multi-widget composition (per past wave pattern — those richer snackbars stay inline).

For each migrate-able site, rewrite as:

```dart
// BEFORE
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(l10n.momentDeleted),
    backgroundColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
  ),
);

// AFTER
showMomentsSnackBar(
  context,
  message: l10n.momentDeleted,
  type: MomentsSnackBarType.success,
);
```

**Type mapping:**
- `AppColors.primary` / green / success-ish → `MomentsSnackBarType.success`
- `AppColors.error` / red / failure → `MomentsSnackBarType.error`
- Default theme surface / informational → `MomentsSnackBarType.info`

For each affected file, add the import at the top:

```dart
import 'package:bananatalk_app/pages/moments/widgets/moments_snackbar.dart';
```

- [ ] **Step 3: Verify count drops**

```bash
grep -rn "ScaffoldMessenger.of(context).showSnackBar" lib/pages/moments/*.dart | wc -l
```

Expected: ≤ 5 (the `Row`-content stragglers that intentionally stay inline).

```bash
grep -rn "showMomentsSnackBar" lib/pages/moments/*.dart | wc -l
```

Expected: ≥ 23.

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/pages/moments/ 2>&1 | tail -15
```

Expected: zero new errors. (Old `SnackBar` import may be flagged as unused in some files — remove it.)

- [ ] **Step 5: Commit**

```bash
git add lib/pages/moments/
git commit -m "$(cat <<'EOF'
refactor(moments): C6 — migrate ~23 inline snackbars to showMomentsSnackBar

Sweeps create_moment, single_moment, moment_card, moments_main,
saved_moments_screen, moment_filter_sheet. Row-content snackbars
(icon + text) intentionally stay inline.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C7 — fix(moments): withOpacity → withValues + Colors.grey theme migration

**Files:** all `lib/pages/moments/*.dart`

- [ ] **Step 1: Enumerate `withOpacity` sites**

```bash
grep -rn "\.withOpacity(" lib/pages/moments/*.dart
```

Expected: 21 lines.

- [ ] **Step 2: Rewrite each `withOpacity(x)` → `withValues(alpha: x)`**

Mechanical: `someColor.withOpacity(0.5)` → `someColor.withValues(alpha: 0.5)`. Preserve the surrounding code. Use the Edit tool one-call-per-site (or `replace_all` only if a literal regex like `\.withOpacity\(0\.5\)` is unique enough — usually not).

- [ ] **Step 3: Enumerate `Colors.grey[*]` sites**

```bash
grep -rn "Colors\.grey" lib/pages/moments/*.dart
```

Expected: 26 lines.

- [ ] **Step 4: Migrate `Colors.grey[*]` per the wave-1 mapping**

Mapping (use `lib/utils/theme_extensions.dart` getters):

| Old | New |
|---|---|
| `Colors.grey[100]` / `[200]` (containers, fills) | `context.containerColor` |
| `Colors.grey[300]` / `[400]` (dividers) | `context.dividerColor` |
| `Colors.grey[500]` / `[600]` / `[700]` (icons, secondary text) | `context.textSecondary` |
| `Colors.grey[800]` / `[900]` (primary muted text) | `context.textMuted` |
| Plain `Colors.grey` (no shade) | `context.textSecondary` |

**Exception:** keep `Colors.white` literals on colored buttons (e.g. `foregroundColor: Colors.white` paired with a colored `backgroundColor`). Keep white text on gradient cards. Do NOT migrate those.

For each match, update with `Edit` providing surrounding context (Edit fails on duplicates so context is required).

Each affected file needs the import:

```dart
import 'package:bananatalk_app/utils/theme_extensions.dart';
```

(Most already have it — verify via `grep "theme_extensions" lib/pages/moments/<file>.dart` first.)

- [ ] **Step 5: Verify counts**

```bash
grep -rn "\.withOpacity(" lib/pages/moments/*.dart | wc -l
grep -rn "Colors\.grey" lib/pages/moments/*.dart | wc -l
```

Expected: 0 and 0 (or close — leftover legitimate `Colors.grey` only on colored backgrounds, but try to drive both to 0).

- [ ] **Step 6: Run analyzer**

```bash
flutter analyze lib/pages/moments/ 2>&1 | tail -15
```

Expected: zero new errors.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/moments/
git commit -m "$(cat <<'EOF'
fix(moments): C7 — withOpacity → withValues + Colors.grey theme migration

21 withOpacity → withValues(alpha:). 26 Colors.grey[*] → context.*
theme getters. Preserves white-on-color button text.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C8 — refactor(moments): move filter files into `filter/` + split `moment_filter_sheet`

**Files:**
- Move (`git mv`):
  - `lib/pages/moments/moment_filter_bar.dart` → `lib/pages/moments/filter/moment_filter_bar.dart`
  - `lib/pages/moments/moment_filter_model.dart` → `lib/pages/moments/filter/moment_filter_model.dart`
  - `lib/pages/moments/moment_filter_utility.dart` → `lib/pages/moments/filter/moment_filter_utility.dart`
  - `lib/pages/moments/moment_filter_sheet.dart` → `lib/pages/moments/filter/moment_filter_sheet.dart`
- Create (split out of `moment_filter_sheet.dart`):
  - `lib/pages/moments/filter/filter_sort_section.dart` (lines 341–439 — `_buildSortTab` + `_buildSortOption`)
  - `lib/pages/moments/filter/filter_language_section.dart` (lines 440–582 — `_buildLanguageTab`)
  - `lib/pages/moments/filter/filter_category_section.dart` (lines 583–613 — `_buildCategoryTab`)
  - `lib/pages/moments/filter/filter_mood_section.dart` (lines 614–644 — `_buildMoodTab`)
  - `lib/pages/moments/filter/filter_chips.dart` (lines 251–268, 645–738 — badge + section title + chip helpers)

- [ ] **Step 1: Create the subfolder + move files**

```bash
mkdir -p lib/pages/moments/filter
git mv lib/pages/moments/moment_filter_bar.dart lib/pages/moments/filter/moment_filter_bar.dart
git mv lib/pages/moments/moment_filter_model.dart lib/pages/moments/filter/moment_filter_model.dart
git mv lib/pages/moments/moment_filter_utility.dart lib/pages/moments/filter/moment_filter_utility.dart
git mv lib/pages/moments/moment_filter_sheet.dart lib/pages/moments/filter/moment_filter_sheet.dart
```

- [ ] **Step 2: Update internal imports inside the moved files**

Inside `lib/pages/moments/filter/moment_filter_utility.dart`:

```dart
// BEFORE
import 'package:bananatalk_app/pages/moments/moment_filter_model.dart';

// AFTER
import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
```

Inside `lib/pages/moments/filter/moment_filter_sheet.dart`:

```dart
// BEFORE
import 'moment_filter_model.dart';

// AFTER (still works — same folder — but explicit is clearer)
import 'moment_filter_model.dart';
```

(Same-folder relative imports are fine.)

- [ ] **Step 3: Update external importers**

```bash
grep -rln "pages/moments/moment_filter_bar\|pages/moments/moment_filter_model\|pages/moments/moment_filter_utility\|pages/moments/moment_filter_sheet" lib/ 2>/dev/null
```

Expected: a handful of files in `lib/pages/moments/`. For each, rewrite the import:

```dart
// BEFORE
import 'package:bananatalk_app/pages/moments/moment_filter_bar.dart';

// AFTER
import 'package:bananatalk_app/pages/moments/filter/moment_filter_bar.dart';
```

(Same for `moment_filter_model`, `moment_filter_utility`, `moment_filter_sheet`.)

- [ ] **Step 4: Verify analyzer is clean before splitting**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: zero new errors. (If imports were missed, analyzer surfaces them now.)

- [ ] **Step 5: Split `moment_filter_sheet.dart` — extract sort tab**

Read `lib/pages/moments/filter/moment_filter_sheet.dart` lines 341–439 (the `_buildSortTab` and `_buildSortOption` methods).

Create `lib/pages/moments/filter/filter_sort_section.dart`:

```dart
// lib/pages/moments/filter/filter_sort_section.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'moment_filter_model.dart';

class FilterSortSection extends StatelessWidget {
  final MomentFilter tempFilter;
  final ValueChanged<MomentFilter> onChanged;

  const FilterSortSection({
    super.key,
    required this.tempFilter,
    required this.onChanged,
  });

  // Paste in the body of _buildSortTab here, replacing the
  // setState((){ _tempFilter = … }) calls with onChanged(tempFilter.copyWith(…))
  // and replacing _localizedSortLabel/_localizedDateLabel with helpers.
  // ...
}
```

(Full body adapted from `moment_filter_sheet.dart` lines 341–439. Key edits: `setState((){ _tempFilter = X; })` → `onChanged(X)`; `_tempFilter` → `tempFilter`; helper functions for localized labels move with it.)

In `moment_filter_sheet.dart`, remove the in-class methods and replace with:

```dart
// In TabBarView at line ~250 of moment_filter_sheet.dart
FilterSortSection(
  tempFilter: _tempFilter,
  onChanged: (v) => setState(() => _tempFilter = v),
),
```

- [ ] **Step 6: Repeat split for language, category, mood tabs**

Same pattern as Step 5 — extract `_buildLanguageTab`, `_buildCategoryTab`, `_buildMoodTab` into `filter_language_section.dart`, `filter_category_section.dart`, `filter_mood_section.dart` respectively. Each takes `tempFilter` + `onChanged` callback. Move the section's helper functions (e.g., `_toggleLanguage`, `_toggleCategory`) with their owning section.

- [ ] **Step 7: Extract chip helpers to `filter_chips.dart`**

The `_buildBadge`, `_buildSectionTitle`, `_buildFilterChip`, `_buildMoodChip` methods (lines 251–738 minus the section bodies) become standalone helper functions or a `FilterChips` static-method class.

```dart
// lib/pages/moments/filter/filter_chips.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

Widget filterBadge(BuildContext context, int count) {
  // body of _buildBadge from moment_filter_sheet.dart
  // ...
}

Widget filterSectionTitle(BuildContext context, String title, IconData icon) {
  // body of _buildSectionTitle
  // ...
}

Widget filterChip({
  required BuildContext context,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  // body of _buildFilterChip
  // ...
}

Widget filterMoodChip({
  required BuildContext context,
  required String emoji,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  // body of _buildMoodChip
  // ...
}
```

In each section file (and the parent sheet), replace `_buildSectionTitle(...)` → `filterSectionTitle(context, ...)`, etc.

- [ ] **Step 8: Pragmatic guardrail check**

If extraction increases complexity (e.g., need to thread 6+ callback params per section), STOP — leave the section bodies in `moment_filter_sheet.dart` and only commit the `git mv` + `filter_chips.dart` extraction. Note this in the commit message.

- [ ] **Step 9: Verify analyzer + manual smoke-line count**

```bash
flutter analyze lib/pages/moments/filter/ 2>&1 | tail -10
wc -l lib/pages/moments/filter/*.dart
```

Expected: zero errors. Each new file ≤ ~250 lines. The shell `moment_filter_sheet.dart` should drop from 792 → ~250.

- [ ] **Step 10: Commit**

```bash
git add lib/pages/moments/ lib/pages/moments/filter/
git commit -m "$(cat <<'EOF'
refactor(moments): C8 — move filter files to filter/ + split filter sheet

git mv: moment_filter_bar, moment_filter_model, moment_filter_utility,
moment_filter_sheet → filter/. Split the 792-line sheet into
filter_sort_section, filter_language_section, filter_category_section,
filter_mood_section, filter_chips. Pragmatic fallback applied where
extraction would increase complexity.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C9 — refactor(moments): move feed files into `feed/` + split `moments_main`

**Files:**
- Move (`git mv`): `lib/pages/moments/moments_main.dart` → `lib/pages/moments/feed/moments_main.dart`
- Create:
  - `lib/pages/moments/feed/moments_feed_widget.dart` — the feed list ListView with ad insertion
  - `lib/pages/moments/feed/moments_filter_button.dart` — the floating filter trigger

- [ ] **Step 1: Move + update imports**

```bash
mkdir -p lib/pages/moments/feed
git mv lib/pages/moments/moments_main.dart lib/pages/moments/feed/moments_main.dart
```

- [ ] **Step 2: Update external importer**

```bash
grep -rln "pages/moments/moments_main" lib/ 2>/dev/null
```

Expected: `lib/pages/menu_tab/TabBarMenu.dart` (and possibly internal moments files).

In `lib/pages/menu_tab/TabBarMenu.dart`:

```dart
// BEFORE
import 'package:bananatalk_app/pages/moments/moments_main.dart';

// AFTER
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart';
```

Inside the moved file, update imports for `moment_card`, `moment_filter_*`, etc. (those will be moved in C8 / C10, so use the post-C8 paths; `moment_card` reference stays at root for now, will be re-pointed in C10).

- [ ] **Step 3: Identify the feed ListView block to extract**

Open `lib/pages/moments/feed/moments_main.dart`. Find the `ListView.builder` (or equivalent) that renders the moments feed with ad insertion every 3 posts (likely around the `body:` of the Scaffold). It depends on `filteredMomentsProvider` and the ad widget.

Extract that block into a new `MomentsFeedWidget(StatelessWidget)` that takes `List<Moments> moments` (or watches `filteredMomentsProvider` directly) and renders the list.

```dart
// lib/pages/moments/feed/moments_feed_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/moments/moment_card.dart';  // updated path in C10
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class MomentsFeedWidget extends ConsumerWidget {
  final List<Moments> moments;
  final ScrollController scrollController;

  const MomentsFeedWidget({
    super.key,
    required this.moments,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: scrollController,
      itemCount: moments.length + (moments.length ~/ 3),
      itemBuilder: (context, index) {
        // Insert ad every 3 moments
        if ((index + 1) % 4 == 0) {
          return const NativeAdWidget();
        }
        final realIndex = index - (index ~/ 4);
        if (realIndex >= moments.length) return const SizedBox.shrink();
        return MomentCard(moments: moments[realIndex]);
      },
    );
  }
}
```

(Adjust the actual extraction to match the existing logic; the ad-every-3 math may differ — use what's already in `moments_main.dart`.)

- [ ] **Step 4: Extract the filter-trigger button**

If the floating filter button (FAB or similar) in `moments_main.dart` is non-trivial (>20 lines), extract into:

```dart
// lib/pages/moments/feed/moments_filter_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_sheet.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart' show momentFilterProvider;

class MomentsFilterButton extends ConsumerWidget {
  const MomentsFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(momentFilterProvider);
    final hasActive = filter.hasActiveFilters;
    return FloatingActionButton(
      heroTag: 'moments-filter',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => MomentFilterSheet(
            currentFilter: filter,
            onApplyFilter: (f) =>
                ref.read(momentFilterProvider.notifier).setFilter(f),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.filter_list_rounded),
          if (hasActive)
            const Positioned(
              right: -2,
              top: -2,
              child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
            ),
        ],
      ),
    );
  }
}
```

(The real filter button code may differ — use the existing layout.)

- [ ] **Step 5: Pragmatic guardrail**

If extracting the filter button or feed widget would require threading 5+ callbacks/providers through props, just `git mv` the file and skip the split. Document inline.

- [ ] **Step 6: Verify analyzer**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/moments/feed/ lib/pages/moments/ lib/pages/menu_tab/TabBarMenu.dart
git commit -m "$(cat <<'EOF'
refactor(moments): C9 — move feed files to feed/ + split moments_main

git mv moments_main.dart → feed/. Extract feed ListView and filter
button where extraction reduces complexity.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C10 — refactor(moments): split `moment_card` into `card/` subfolder

**Files:**
- Move (`git mv`): `lib/pages/moments/moment_card.dart` → `lib/pages/moments/card/moment_card.dart`
- Create:
  - `lib/pages/moments/card/moment_card_media.dart` — image/video card layout (split from main `build` for non-gradient)
  - `lib/pages/moments/card/moment_card_gradient.dart` — gradient text-only layout (extracted from `_buildGradientTextCard` at line 982)
  - `lib/pages/moments/card/moment_card_header.dart` — avatar + name + timestamp + 3-dot menu
  - `lib/pages/moments/card/moment_card_actions.dart` — like/comment/share/save bar (the `_buildActionButton` at line 1055 + surrounding row)
  - `lib/pages/moments/card/moment_card_double_tap.dart` — double-tap heart overlay (`_buildDoubleTapLikeArea` at line 1016)

- [ ] **Step 1: `git mv` the file**

```bash
mkdir -p lib/pages/moments/card
git mv lib/pages/moments/moment_card.dart lib/pages/moments/card/moment_card.dart
```

- [ ] **Step 2: Update all importers**

```bash
grep -rln "pages/moments/moment_card" lib/ 2>/dev/null
```

Expected matches (each gets the path updated):
- `lib/pages/moments/saved_moments_screen.dart`
- `lib/pages/moments/feed/moments_feed_widget.dart` (created in C9)
- `lib/pages/moments/feed/moments_main.dart` (if it imports moment_card directly)
- (Possibly `lib/pages/moments/single_moment.dart` — verify)

For each:

```dart
// BEFORE
import 'package:bananatalk_app/pages/moments/moment_card.dart';

// AFTER
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
```

(Note: the `lib/pages/profile/moments/moment_card.dart` is a *different* file in the profile area — do NOT touch its imports unless it imports `pages/moments/moment_card.dart` itself.)

- [ ] **Step 3: Verify analyzer is clean before splitting**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 4: Extract gradient card**

Open `lib/pages/moments/card/moment_card.dart`. Find `_buildGradientTextCard` (at line 982 in pre-move file). Extract to:

```dart
// lib/pages/moments/card/moment_card_gradient.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
// ... other imports as needed

class MomentCardGradient extends StatelessWidget {
  final Moments moment;
  final VoidCallback onTap;
  // additional props as needed by the existing _buildGradientTextCard body

  const MomentCardGradient({
    super.key,
    required this.moment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Paste body of _buildGradientTextCard from moment_card.dart here
    // Replace `widget.moments` with `moment`
    // Replace `widget.X` callbacks with `X` direct passes
    // ...
  }
}
```

In `moment_card.dart`, replace the inline `_buildGradientTextCard(moment)` call with:

```dart
MomentCardGradient(moment: moment, onTap: () { /* existing onTap */ })
```

- [ ] **Step 5: Extract double-tap overlay**

Same pattern. The `_buildDoubleTapLikeArea(child)` method (at line 1016 pre-move) becomes:

```dart
// lib/pages/moments/card/moment_card_double_tap.dart
import 'package:flutter/material.dart';

class MomentCardDoubleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onDoubleTap;
  final bool showHeart; // animation trigger

  const MomentCardDoubleTap({
    super.key,
    required this.child,
    required this.onDoubleTap,
    required this.showHeart,
  });

  @override
  State<MomentCardDoubleTap> createState() => _MomentCardDoubleTapState();
}

class _MomentCardDoubleTapState extends State<MomentCardDoubleTap>
    with SingleTickerProviderStateMixin {
  // Paste relevant animation state from moment_card.dart's _MomentCardState
  // (the heart overlay AnimationController setup)
  // ...

  @override
  Widget build(BuildContext context) {
    // Paste body of _buildDoubleTapLikeArea here
    // ...
  }
}
```

In `moment_card.dart`, replace the inline call with `MomentCardDoubleTap(child: ..., onDoubleTap: _toggleLike, showHeart: _showDoubleTapHeart)`.

- [ ] **Step 6: Extract action bar**

The `_buildActionButton(...)` calls + the surrounding `Row` of buttons (around line 832 in pre-move file) extract to:

```dart
// lib/pages/moments/card/moment_card_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class MomentCardActions extends ConsumerWidget {
  final Moments moment;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onSaveTap;
  final bool isSaved;

  const MomentCardActions({
    super.key,
    required this.moment,
    required this.isLiked,
    required this.likeCount,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onSaveTap,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Body adapted from _buildActionButton row in moment_card.dart
    // ...
  }
}
```

- [ ] **Step 7: Extract header (avatar + name + timestamp + 3-dot menu)**

The header row at the top of the card body becomes `MomentCardHeader`:

```dart
// lib/pages/moments/card/moment_card_header.dart
class MomentCardHeader extends StatelessWidget {
  final Moments moment;
  final VoidCallback onAvatarTap;
  final VoidCallback onMenuTap;
  // ...
}
```

The 3-dot menu callback (`onMenuTap`) is the entry point for the new "hide this user's moments" action coming in C17 — leave it as a simple `VoidCallback` for now and wire C17 into it later.

- [ ] **Step 8: Extract media card layout**

The non-gradient card layout (image/video grid + caption + action bar) extracts to `MomentCardMedia`:

```dart
// lib/pages/moments/card/moment_card_media.dart
class MomentCardMedia extends ConsumerStatefulWidget {
  final Moments moment;
  // ...
}
```

The orchestrator `MomentCard` becomes a thin shell:

```dart
@override
Widget build(BuildContext context) {
  final isGradient = widget.moments.backgroundColor != null &&
      widget.moments.backgroundColor!.isNotEmpty &&
      (widget.moments.images?.isEmpty ?? true);
  if (isGradient) {
    return MomentCardGradient(moment: widget.moments, onTap: _onCardTap);
  }
  return MomentCardMedia(moment: widget.moments);
}
```

- [ ] **Step 9: Pragmatic guardrail**

If any single extraction adds >50 lines of prop-threading vs. inline code, fall back: keep the helper inline as a private method on `_MomentCardState` and skip extracting that piece. Note in commit message which extractions were skipped.

- [ ] **Step 10: Verify analyzer + line counts**

```bash
flutter analyze lib/ 2>&1 | tail -15
wc -l lib/pages/moments/card/*.dart
```

Expected: zero errors. Each new file ≤ ~400 lines. Orchestrator `moment_card.dart` should be ≤ ~400 lines (was 1,237).

- [ ] **Step 11: Commit**

```bash
git add lib/pages/moments/ lib/pages/moments/card/
git commit -m "$(cat <<'EOF'
refactor(moments): C10 — split moment_card into card/ subfolder

git mv moment_card.dart → card/. Extract moment_card_gradient,
moment_card_double_tap, moment_card_actions, moment_card_header,
moment_card_media. Orchestrator drops from 1,237 → ~400 lines.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C11 — refactor(moments): split `single_moment` into `single/` subfolder

**Files:**
- Move (`git mv`): `lib/pages/moments/single_moment.dart` → `lib/pages/moments/single/single_moment.dart`
- Create:
  - `lib/pages/moments/single/single_moment_header.dart`
  - `lib/pages/moments/single/single_moment_content.dart`
  - `lib/pages/moments/single/single_moment_comments.dart`
  - `lib/pages/moments/single/single_moment_reactions.dart`
  - `lib/pages/moments/single/comment_input_bar.dart`

- [ ] **Step 1: `git mv` + update external imports**

```bash
mkdir -p lib/pages/moments/single
git mv lib/pages/moments/single_moment.dart lib/pages/moments/single/single_moment.dart

grep -rln "pages/moments/single_moment" lib/ 2>/dev/null
```

Expected importers (update all):
- `lib/pages/moments/moment_detail_wrapper.dart`
- `lib/pages/community/single/single_community_moments.dart`
- (Possibly `lib/pages/moments/card/moment_card.dart` if it pushes onto `SingleMoment`)

For each:

```dart
// BEFORE
import 'package:bananatalk_app/pages/moments/single_moment.dart';

// AFTER
import 'package:bananatalk_app/pages/moments/single/single_moment.dart';
```

- [ ] **Step 2: Verify analyzer**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 3: Extract header (back button + share + report row)**

Find the AppBar / top-bar block (likely in the Scaffold's `appBar:` slot, ~lines 430–500). Extract:

```dart
// lib/pages/moments/single/single_moment_header.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class SingleMomentHeader extends StatelessWidget implements PreferredSizeWidget {
  final Moments moment;
  final VoidCallback onShareTap;
  final VoidCallback onReportTap;

  const SingleMomentHeader({
    super.key,
    required this.moment,
    required this.onShareTap,
    required this.onReportTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // ... body extracted from existing AppBar
    );
  }
}
```

Replace inline AppBar with `appBar: SingleMomentHeader(moment: …, …)`.

- [ ] **Step 4: Extract content (media render + caption + tags)**

The `_buildImageGrid` / `_buildImageItem` (at lines 867 / 963) plus the caption and tags row extract to:

```dart
// lib/pages/moments/single/single_moment_content.dart
class SingleMomentContent extends StatelessWidget {
  final Moments moment;
  // callbacks for image-tap → image_viewer.dart route

  const SingleMomentContent({
    super.key,
    required this.moment,
    // ...
  });

  @override
  Widget build(BuildContext context) {
    // Body merged from _buildImageGrid + caption rendering + tags row
    // ...
  }
}
```

- [ ] **Step 5: Extract comments thread**

The comment list (likely a `ListView` of comment widgets) extracts to:

```dart
// lib/pages/moments/single/single_moment_comments.dart
class SingleMomentComments extends ConsumerWidget {
  final String momentId;

  const SingleMomentComments({super.key, required this.momentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Body extracted from existing comments rendering
    // ...
  }
}
```

- [ ] **Step 6: Extract reactions row + viewers list**

```dart
// lib/pages/moments/single/single_moment_reactions.dart
class SingleMomentReactions extends ConsumerWidget {
  final Moments moment;
  // ...
}
```

- [ ] **Step 7: Extract bottom comment composer bar**

```dart
// lib/pages/moments/single/comment_input_bar.dart
class CommentInputBar extends StatefulWidget {
  final String momentId;
  final ValueChanged<String> onSubmit;
  // ...
}
```

- [ ] **Step 8: Pragmatic guardrail**

Same as C10 — skip extractions that add complexity. Note in commit message.

- [ ] **Step 9: Verify analyzer + line counts**

```bash
flutter analyze lib/ 2>&1 | tail -10
wc -l lib/pages/moments/single/*.dart
```

Expected: zero errors. Orchestrator `single_moment.dart` ≤ ~400 lines (was 1,015).

- [ ] **Step 10: Commit**

```bash
git add lib/pages/moments/ lib/pages/moments/single/
git commit -m "$(cat <<'EOF'
refactor(moments): C11 — split single_moment into single/ subfolder

git mv single_moment.dart → single/. Extract single_moment_header,
single_moment_content, single_moment_comments, single_moment_reactions,
comment_input_bar. Orchestrator drops from 1,015 → ~400 lines.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C12 — refactor(moments): split `create_moment` into `create/` subfolder

**Files:**
- Move (`git mv`): `lib/pages/moments/create_moment.dart` → `lib/pages/moments/create/create_moment.dart`
- Create (split out):
  - `lib/pages/moments/create/create_image_section.dart`
  - `lib/pages/moments/create/create_text_section.dart`
  - `lib/pages/moments/create/create_chips_row.dart`
  - `lib/pages/moments/create/create_tag_dialog.dart`
  - `lib/pages/moments/create/create_location_picker.dart`
  - `lib/pages/moments/create/create_schedule_picker.dart`
  - `lib/pages/moments/create/create_privacy_picker.dart`
  - `lib/pages/moments/create/create_post_action.dart`

- [ ] **Step 1: `git mv` + update external imports**

```bash
mkdir -p lib/pages/moments/create
git mv lib/pages/moments/create_moment.dart lib/pages/moments/create/create_moment.dart

grep -rln "pages/moments/create_moment" lib/ 2>/dev/null
```

Update each importer's path. Likely importers:
- `lib/pages/moments/feed/moments_main.dart` (FAB launches CreateMoment)
- `lib/pages/moments/card/moment_card.dart` (sometimes CreateMoment is pushed via "edit" action — though the spec says no edit-after-post; still, verify)
- `lib/pages/moments/single/single_moment.dart` (similar)

- [ ] **Step 2: Verify analyzer**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 3: Decide split scope (pragmatic guardrail upfront)**

Open `lib/pages/moments/create/create_moment.dart` (was 2,278 lines). Identify the in-class state fields (`_selectedImages`, `_videoFile`, `_titleController`, `_tagController`, `_selectedMood`, etc.) and read the `build` method (line 1303).

Answer the question: **does the form state read & write in tightly entangled ways across all sections?** If yes, the full split increases complexity (lots of callback threading) and we use the conservative variant. If sections are mostly independent (each owning local UI but sharing a few key fields via callbacks), do the full split.

**Decision rule:**
- If ≥5 sections each share ≥3 state fields with the orchestrator → conservative variant (steps 4–6 below; skip steps 7–11)
- Otherwise → full split (steps 7–11)

- [ ] **Step 4: Conservative variant — extract tag dialog only**

The `_buildTagDialog` method (line 2191) is the most contained. Extract to:

```dart
// lib/pages/moments/create/create_tag_dialog.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

Future<String?> showCreateTagDialog(
  BuildContext context, {
  required List<String> existingTags,
  required int maxTags,
}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      // Body adapted from _buildTagDialog(), with autocomplete hooks
      // for C16 reserved as a TODO comment in the spec — actual
      // autocomplete arrives in C16.
    },
  );
}
```

In `create_moment.dart`, replace the call to `_buildTagDialog()` with `showCreateTagDialog(context, …)`.

- [ ] **Step 5: Conservative variant — extract _buildBottomButton + _buildActionIcon helpers**

The `_buildActionIcon` (line 2102) and `_buildBottomButton` (line 2165) helpers extract to private functions in the same file or a small helper file:

```dart
// lib/pages/moments/create/create_action_helpers.dart
import 'package:flutter/material.dart';

Widget createActionIcon({
  required IconData icon,
  required VoidCallback onTap,
  String? label,
}) {
  // body of _buildActionIcon
}

Widget createBottomButton({
  required String label,
  required VoidCallback? onPressed,
  required bool loading,
}) {
  // body of _buildBottomButton
}
```

- [ ] **Step 6: Conservative variant — commit**

```bash
git add lib/pages/moments/create/
git commit -m "$(cat <<'EOF'
refactor(moments): C12 — move create_moment to create/ subfolder

Conservative split: git mv create_moment.dart → create/, extract
create_tag_dialog (with hooks for C16 autocomplete) and
create_action_helpers. Body remains entangled — full split deferred
to a follow-up wave.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Skip steps 7–11.)

- [ ] **Step 7: Full split variant — extract image picker section**

Find the photo/video picker UI (in the body of `build`). Extract to `CreateImageSection(StatefulWidget)` taking:
- `List<File> images` (current value)
- `File? video` (current value)
- `ValueChanged<List<File>> onImagesChanged`
- `ValueChanged<File?> onVideoChanged`
- The `_pickImages`, `_pickVideo`, `_removeImage`, `_removeVideo` handlers stay alongside the section.

```dart
// lib/pages/moments/create/create_image_section.dart
class CreateImageSection extends StatelessWidget {
  final List<File> images;
  final File? video;
  final ValueChanged<List<File>> onImagesChanged;
  final ValueChanged<File?> onVideoChanged;
  // ...
}
```

- [ ] **Step 8: Full split variant — extract gradient text section**

The gradient-text-only entry mode (used when no images/video; user picks a background gradient and writes text). Extract to `CreateTextSection`.

- [ ] **Step 9: Full split variant — extract chips row + location/schedule/privacy pickers**

Each picker becomes its own `StatelessWidget` taking the current value + onChanged callback. ~5 small widgets.

- [ ] **Step 10: Full split variant — extract post action**

The submit button + actual `createMoment` POST submission logic extracts to `CreatePostAction`:

```dart
// lib/pages/moments/create/create_post_action.dart
class CreatePostAction extends ConsumerStatefulWidget {
  final String title;
  final List<File> images;
  final File? video;
  final List<String> tags;
  final String? mood;
  final String? category;
  final String privacy;
  final String language;
  final DateTime? scheduledFor;
  final Position? location;
  final VoidCallback onSuccess;

  // ...
}
```

(All the form fields pass in; the action widget owns the submit + invalidate logic.)

- [ ] **Step 11: Full split variant — verify + commit**

```bash
flutter analyze lib/ 2>&1 | tail -10
wc -l lib/pages/moments/create/*.dart
```

Expected: zero errors. Orchestrator `create_moment.dart` ≤ ~600 lines (was 2,278).

```bash
git add lib/pages/moments/ lib/pages/moments/create/
git commit -m "$(cat <<'EOF'
refactor(moments): C12 — split create_moment into create/ subfolder

git mv create_moment.dart → create/. Extract create_image_section,
create_text_section, create_chips_row, create_tag_dialog (with hooks
for C16 autocomplete), create_location_picker, create_schedule_picker,
create_privacy_picker, create_post_action. Orchestrator drops from
2,278 → ~600 lines.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C13 — refactor(moments): move `image_viewer` + `video_player_widget` into `viewer/`

**Files:**
- Move: `lib/pages/moments/image_viewer.dart` → `lib/pages/moments/viewer/image_viewer.dart`
- Move: `lib/pages/moments/video_player_widget.dart` → `lib/pages/moments/viewer/video_player_widget.dart`

- [ ] **Step 1: `git mv` both files**

```bash
mkdir -p lib/pages/moments/viewer
git mv lib/pages/moments/image_viewer.dart lib/pages/moments/viewer/image_viewer.dart
git mv lib/pages/moments/video_player_widget.dart lib/pages/moments/viewer/video_player_widget.dart
```

- [ ] **Step 2: Update all importers**

```bash
grep -rln "pages/moments/image_viewer\|pages/moments/video_player_widget" lib/ 2>/dev/null
```

Expected (each gets path updated):
- `lib/pages/chat/message/message_bubble/image_message_view.dart`
- `lib/pages/profile/moments/moment_card.dart`
- `lib/pages/community/single/single_community_header.dart`
- `lib/pages/moments/card/moment_card.dart`
- `lib/pages/moments/single/single_moment.dart`

For each:

```dart
// BEFORE
import 'package:bananatalk_app/pages/moments/image_viewer.dart';

// AFTER
import 'package:bananatalk_app/pages/moments/viewer/image_viewer.dart';
```

(Same for `video_player_widget`.)

- [ ] **Step 3: Verify analyzer**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 4: Commit**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
refactor(moments): C13 — move image_viewer + video_player_widget to viewer/

git mv. Updates imports in chat/message_bubble, profile/moments,
community/single, and the moments orchestrators.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C14 — refactor(moments): move `saved_moments_screen` into `saved/`

**Files:**
- Move: `lib/pages/moments/saved_moments_screen.dart` → `lib/pages/moments/saved/saved_moments_screen.dart`

- [ ] **Step 1: `git mv`**

```bash
mkdir -p lib/pages/moments/saved
git mv lib/pages/moments/saved_moments_screen.dart lib/pages/moments/saved/saved_moments_screen.dart
```

- [ ] **Step 2: Update importers**

```bash
grep -rln "pages/moments/saved_moments_screen" lib/ 2>/dev/null
```

For each match:

```dart
// BEFORE
import 'package:bananatalk_app/pages/moments/saved_moments_screen.dart';

// AFTER
import 'package:bananatalk_app/pages/moments/saved/saved_moments_screen.dart';
```

- [ ] **Step 3: Inside the moved file, update import to `moment_card`**

The moved file already imports `moment_card.dart`. After C10 it's at `card/moment_card.dart`. Verify:

```bash
grep "pages/moments/moment_card\|pages/moments/card/moment_card" lib/pages/moments/saved/saved_moments_screen.dart
```

Update if needed.

- [ ] **Step 4: Verify analyzer**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 5: Commit**

```bash
git add lib/
git commit -m "$(cat <<'EOF'
refactor(moments): C14 — move saved_moments_screen to saved/

git mv. Final file move of the Step 5 restructure.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C15 — feat(moments): April spec audit + remediation

**Files:**
- Modify: `lib/pages/moments/create/create_moment.dart` (and helpers) IF audit reveals stale category/mood enums
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/moments.js` IF audit reveals missing `isDeleted` filter
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/models/Moment.js` IF audit reveals stale enum

This task is verification-first. Each sub-step verifies a spec claim; only commit a fix if the audit reveals a gap.

- [ ] **Step 1: §1.3 — verify `isDeleted` filter on backend endpoints**

```bash
grep -n "isDeleted" /Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/moments.js
```

Expected: at least 3 references in `getMoments`, `getUserMoments`, `getMoment` controllers, each filtering `isDeleted: { $ne: true }` (or equivalent) in the Mongoose query.

If any of the three endpoints lacks the filter, **add it**. For example in `getMoments`:

```javascript
// BEFORE
const moments = await Moment.find({}).sort({ createdAt: -1 });

// AFTER
const moments = await Moment.find({ isDeleted: { $ne: true } }).sort({ createdAt: -1 });
```

Same pattern for `getUserMoments` and `getMoment`. **Note:** for `getMoment` (single fetch by ID), use `findOne({ _id: id, isDeleted: { $ne: true } })` so deleted moments return 404.

- [ ] **Step 2: §1.4 / §1.5 — verify mood + category enums sync**

Read the backend schema:

```bash
grep -A 30 "mood:\|category:" /Users/davis/Desktop/Personal/language_exchange_backend_application/models/Moment.js
```

Read the Flutter side. Open `lib/pages/moments/create/create_moment.dart` (or the chips section if extracted in C12) and find the constants for mood / category options. They're typically defined as Lists.

Compare. If the lists differ, update Flutter to match backend (canonical source). Backend changes only if Flutter has a value the backend rejects.

Example of a Flutter mood constant location:

```dart
// inside create_moment.dart or a helper
const List<String> _availableMoods = [
  'happy', 'excited', 'calm', 'thoughtful', 'inspired', 'nostalgic',
  'grateful', 'curious', 'peaceful', 'energetic', 'creative', 'reflective',
];
```

Verify all 12 are in the backend enum. If any is missing/extra, list the gap and either:
- Update Flutter constants to drop unsupported values, OR
- Add to backend enum (if a recent feature needs it)

Make the fix and stage it.

- [ ] **Step 3: §6.1 / §6.2 — verify translation buttons + language list sync**

```bash
grep -rn "translateMoment\|momentTranslation" lib/pages/moments/
```

Expected: a translate button somewhere in `single_moment_content.dart` (or in `moment_card.dart` if it does inline translation). Also verify the language list passed to translation is consistent with the rest of the app (`lib/l10n/` languages or wherever the canonical list lives).

If translation is missing on moments while it's wired on stories/comments, this is a remediation task. Add a basic translate button → `/translate` API call → display result. (Use the same pattern as `lib/pages/comments/comments_main.dart` if it has translation.)

- [ ] **Step 4: §10 keys 11-13 — mounted/dispose, isDeleted, dead slug**

```bash
grep -rn "if.*mounted" lib/pages/moments/create/ lib/pages/moments/single/ lib/pages/moments/card/ | head -5
grep -rn "slug" lib/pages/moments/ /Users/davis/Desktop/Personal/language_exchange_backend_application/models/Moment.js
```

Expected: `mounted` checks present after every `await` followed by a `setState`. No `slug` references remain in either codebase.

If any `setState` happens after an `await` without a preceding `if (!mounted) return;` or `if (mounted) setState(…)`, fix it.

If `slug` field is still on backend or referenced in Flutter, and is unused per spec, drop it (the schema field stays — just remove the references in code).

- [ ] **Step 5: Audit summary commit (Flutter)**

If any Flutter changes were made:

```bash
git add lib/
git commit -m "$(cat <<'EOF'
feat(moments): C15 — April spec audit + remediation (Flutter)

Verifies spec items §1.3 (isDeleted filter), §1.4/§1.5 (mood+category
enum sync), §6.1/§6.2 (translation buttons + language list), §10
keys 11-13 (mounted, slug). Fixes <list of gaps found>.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

If no Flutter changes were needed (audit clean), skip the Flutter commit.

- [ ] **Step 6: Audit summary commit (backend, if any)**

If backend changes were made:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/moments.js models/Moment.js
git commit -m "$(cat <<'EOF'
fix(moments): align with April spec (isDeleted / enum / slug)

Adds isDeleted filter to getMoments/getUserMoments/getMoment
controllers; updates mood/category enum in Moment.js to match
canonical Flutter list. Drops unused slug references.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
```

If no backend changes, skip. The branch state matters in the Flutter repo — backend gets its own push at C18 if it was touched.

- [ ] **Step 7: If no changes anywhere, commit a no-op audit log instead**

```bash
git commit --allow-empty -m "$(cat <<'EOF'
chore(moments): C15 — April spec audit complete (no fixes needed)

Verified §1.3 isDeleted filter, §1.4/§1.5 mood/category enum sync,
§6.1/§6.2 translation, §10 keys 11-13 (mounted, slug). All clean —
spec items already shipped via the catch-all eeff4ec commit and
follow-ups (d7374a6, 454d4a7, 56c6ffd, 51af66b).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C16 — feat(moments): tag autocomplete (recent tags from SharedPrefs)

**Files:**
- Modify: `lib/pages/moments/create/create_tag_dialog.dart` (created in C12)
- Modify: `lib/pages/moments/create/create_moment.dart` — call site that adds a tag must also persist it

- [ ] **Step 1: Add the SharedPreferences key constant**

In `lib/pages/moments/create/create_tag_dialog.dart`, near the top:

```dart
import 'package:shared_preferences/shared_preferences.dart';

const String _kRecentTagsKey = 'recent_moment_tags';
const int _kMaxRecentTags = 10;

Future<List<String>> _loadRecentTags() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_kRecentTagsKey) ?? <String>[];
}

Future<void> _persistRecentTag(String tag) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getStringList(_kRecentTagsKey) ?? <String>[];
  // Move tag to front, dedupe, cap at 10
  current.remove(tag);
  current.insert(0, tag);
  if (current.length > _kMaxRecentTags) {
    current.removeRange(_kMaxRecentTags, current.length);
  }
  await prefs.setStringList(_kRecentTagsKey, current);
}
```

- [ ] **Step 2: Update `showCreateTagDialog` to fetch + render recent tags**

```dart
Future<String?> showCreateTagDialog(
  BuildContext context, {
  required List<String> existingTags,
  required int maxTags,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final recentTags = await _loadRecentTags();
  // Filter out tags already on the moment
  final suggestable = recentTags.where((t) => !existingTags.contains(t)).toList();

  if (!context.mounted) return null;
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.addTag),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.tagHint),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            if (suggestable.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.recentTags, style: Theme.of(ctx).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestable.take(8).map((tag) => ActionChip(
                  label: Text('#$tag'),
                  onPressed: () => Navigator.pop(ctx, tag),
                )).toList(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                l10n.noRecentTags,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).disabledColor,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.add),
          ),
        ],
      );
    },
  );
}
```

- [ ] **Step 3: Persist a tag when added**

In the call site that adds a tag to the moment (in `create_moment.dart`'s `_addTag` method or wherever the tag is appended), after a successful add:

```dart
// AFTER tag added to local list:
await _persistRecentTag(tag);  // import _persistRecentTag from create_tag_dialog.dart
```

(Export `_persistRecentTag` by removing the leading underscore, or wrap in a public helper.)

- [ ] **Step 4: Verify analyzer**

```bash
flutter analyze lib/pages/moments/create/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 5: Manual smoke**

Run the app:

```bash
flutter run
```

1. Open create moment, add tag `travel`. Cancel/post.
2. Open create moment again, click "add tag" — verify `#travel` appears under "Recent tags".
3. Tap the chip — tag is added and dialog closes.
4. Add 12 different tags across multiple sessions — verify only the most recent 10 are kept.

(Skip the smoke if running headless; rely on analyzer + the unit-style fact that `setStringList` capped at 10 works.)

- [ ] **Step 6: Commit**

```bash
git add lib/pages/moments/create/
git commit -m "$(cat <<'EOF'
feat(moments): C16 — tag autocomplete from recent SharedPreferences

Adds recent-tags chip row to the tag dialog. Persists last 10 tags
the user added in 'recent_moment_tags' SharedPreferences key. Empty
state shows 'No recent tags yet'.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C17 — feat(moments): hide-this-user's-moments local mute

**Files:**
- Create: `lib/pages/moments/feed/muted_users_provider.dart` — Riverpod state notifier backed by SharedPreferences
- Modify: `lib/pages/moments/feed/moments_main.dart` — wire provider into the `filteredMomentsProvider` chain
- Modify: `lib/pages/moments/card/moment_card_header.dart` (or wherever the 3-dot menu lives, possibly `moment_card.dart`) — add the menu item

- [ ] **Step 1: Create the muted-users provider**

```dart
// lib/pages/moments/feed/muted_users_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kMutedMomentsKey = 'mutedMoments';

class MutedMomentsNotifier extends StateNotifier<Set<String>> {
  MutedMomentsNotifier() : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kMutedMomentsKey) ?? <String>[];
    state = list.toSet();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kMutedMomentsKey, state.toList());
  }

  Future<void> mute(String userId) async {
    state = {...state, userId};
    await _persist();
  }

  Future<void> unmute(String userId) async {
    state = {...state}..remove(userId);
    await _persist();
  }

  bool isMuted(String userId) => state.contains(userId);
}

final mutedMomentsProvider =
    StateNotifierProvider<MutedMomentsNotifier, Set<String>>(
  (ref) => MutedMomentsNotifier(),
);
```

- [ ] **Step 2: Wire the provider into `filteredMomentsProvider`**

Open `lib/pages/moments/feed/moments_main.dart`. Find the `filteredMomentsProvider` definition. Add the muted-users filter to the chain:

```dart
// BEFORE
final filteredMomentsProvider = Provider<AsyncValue<List<Moments>>>((ref) {
  final momentsAsync = ref.watch(momentsFeedProvider);
  final filter = ref.watch(momentFilterProvider);
  final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);
  return momentsAsync.whenData((moments) {
    final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};
    final filteredByBlock = moments.where((m) => !blockedUserIds.contains(m.user.id)).toList();
    return MomentFilterUtility.filterMoments(filteredByBlock, filter);
  });
});

// AFTER
import 'muted_users_provider.dart';

final filteredMomentsProvider = Provider<AsyncValue<List<Moments>>>((ref) {
  final momentsAsync = ref.watch(momentsFeedProvider);
  final filter = ref.watch(momentFilterProvider);
  final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);
  final mutedUserIds = ref.watch(mutedMomentsProvider);
  return momentsAsync.whenData((moments) {
    final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};
    final filteredByBlockAndMute = moments.where((m) {
      return !blockedUserIds.contains(m.user.id) &&
             !mutedUserIds.contains(m.user.id);
    }).toList();
    return MomentFilterUtility.filterMoments(filteredByBlockAndMute, filter);
  });
});
```

- [ ] **Step 3: Add the menu item to the moment card**

Find the 3-dot menu (likely in `moment_card_header.dart` or in `moment_card.dart`). It probably uses `PopupMenuButton<String>`. Add a `hide-user` entry:

```dart
import 'package:bananatalk_app/pages/moments/feed/muted_users_provider.dart';
import 'package:bananatalk_app/pages/moments/widgets/moments_snackbar.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

// inside the popup menu items list:
PopupMenuItem<String>(
  value: 'hide-user',
  child: Row(
    children: [
      const Icon(Icons.visibility_off_outlined, size: 20),
      const SizedBox(width: 12),
      Text(AppLocalizations.of(context)!.hideThisUser),
    ],
  ),
),

// in onSelected:
case 'hide-user':
  await ref.read(mutedMomentsProvider.notifier).mute(moment.user.id);
  if (context.mounted) {
    showMomentsSnackBar(
      context,
      message: AppLocalizations.of(context)!.momentsHidden,
      type: MomentsSnackBarType.success,
    );
  }
  break;
```

(`ref` requires the popup to be inside a `ConsumerWidget` / `ConsumerStatefulWidget`. If it isn't, wrap in `Consumer(builder: (ctx, ref, _) => ...)` for the menu item.)

- [ ] **Step 4: Verify analyzer**

```bash
flutter analyze lib/pages/moments/ 2>&1 | tail -10
```

Expected: zero errors.

- [ ] **Step 5: Manual smoke**

```bash
flutter run
```

1. Open the moments feed. Note a moment by user `Alice`.
2. Tap the 3-dot menu on Alice's moment → "Hide this user's posts" → snackbar appears.
3. Verify the moment disappears from the feed.
4. Pull to refresh. Verify Alice's moments do not reappear.
5. Hot-restart. Open feed. Verify Alice's moments are still hidden.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/moments/
git commit -m "$(cat <<'EOF'
feat(moments): C17 — hide-this-user's-moments local mute toggle

Adds 3-dot menu action 'Hide this user's posts'. Stores muted user
IDs in 'mutedMoments' SharedPreferences key as a Set<String>.
filteredMomentsProvider filters muted users out of the feed.
Local-only — no backend involvement.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task C18 — chore(moments): final analyzer + smoke + push + PR

**Files:**
- May modify: any leftover analyzer warnings

- [ ] **Step 1: Run full analyzer**

```bash
flutter analyze 2>&1 | tail -30
```

Expected: zero errors. If any warnings appear in `lib/pages/moments/`, address them with targeted edits and stage.

- [ ] **Step 2: Run pub.lock + i18n regen one last time**

```bash
flutter pub get
flutter gen-l10n
```

Expected: no errors.

- [ ] **Step 3: Manual smoke (full path)**

```bash
flutter run
```

Verify each entry point works:
1. Bottom-tab to moments → feed renders
2. Tap a moment → detail screen opens with comments
3. Long-press / double-tap a moment → like animation fires
4. Tap "Create" FAB → create form opens; pick image; type caption; pick mood/category; post → success snackbar
5. Open create form again → tap "Add tag" → recent tags chip row visible
6. Open the 3-dot menu on a moment → "Hide this user's posts" → moment disappears
7. Filter sheet opens → can change sort/language/category/mood; apply works
8. Saved moments screen opens via menu/profile entry
9. Image viewer opens on tap from chat (cross-folder regression check)
10. Single moment from community search-card route still opens

- [ ] **Step 4: Verify the diff size and commit count**

```bash
git log main..HEAD --oneline | wc -l
git diff main..HEAD --stat | tail -3
```

Expected: ~19 commits (C0 if it was a no-op may be skipped; expect 18–19 total). Files changed should be in `lib/pages/moments/`, `lib/l10n/`, and the cross-reference files in `chat/`, `profile/`, `community/`, `menu_tab/`, `router/`.

- [ ] **Step 5: Commit any final polish**

```bash
# only if there are leftover warnings or formatting fixes
git add lib/
git commit -m "$(cat <<'EOF'
chore(moments): C18 — final analyzer cleanup pass

Last sweep before PR. Addresses any straggler warnings from the
restructure.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Skip if there are no changes to commit — empty commits are NOT desirable here.)

- [ ] **Step 6: Push the branch**

```bash
git push -u origin refactor/step5-moments-restructure
```

Expected: push succeeds.

- [ ] **Step 7: Push the backend branch IF C15 touched the backend**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git status
git push  # only if the backend repo has uncommitted commits from C15
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
```

- [ ] **Step 8: Create the PR**

```bash
gh pr create --title "Step 5 — Moments restructure + April spec audit" --body "$(cat <<'EOF'
## Summary
- Restructured `lib/pages/moments/` (14 files → 30+ across 8 subfolders: `widgets/`, `feed/`, `card/`, `single/`, `create/`, `filter/`, `viewer/`, `saved/`)
- Split 4 big files: `create_moment` (2,278 → orchestrator + 8 sections), `moment_card` (1,237 → orchestrator + 5 components), `single_moment` (1,015 → orchestrator + 5 sections), `moment_filter_sheet` (792 → shell + 5 sections)
- Cleanup sweep: 21 `withOpacity` → `withValues(alpha:)`, 26 `Colors.grey[*]` → theme getters, ~28 inline snackbars → `showMomentsSnackBar`, 8 ❤️-emoji love-spam debugPrints removed, `update_moment.dart` (orphan) and `action_widget.dart` (unused) deleted
- April spec audit: §1.3 isDeleted filter, §1.4/§1.5 mood/category enum sync, §6.1/§6.2 translation, §10 keys 11-13 (mounted, slug) — verified + remediated stragglers
- 2 minor features: tag autocomplete (recent 10 tags from SharedPreferences) + hide-this-user's-moments local mute (3-dot menu, SharedPreferences-backed)
- ~12 new ARB keys translated to all 18 locales

## Test plan
- [ ] `flutter analyze` is clean
- [ ] Moments feed renders, infinite scroll works
- [ ] Create moment with image works; create with gradient text works
- [ ] Tag dialog shows recent tags after the user has added some
- [ ] Hide-this-user's-moments removes user's posts from feed; persists across restarts
- [ ] Single moment detail loads from feed and from deep-link / community search-card
- [ ] Image viewer still opens correctly from chat message bubble (cross-folder regression)
- [ ] Filter sheet renders all tabs (sort/language/category/mood); apply persists across restarts
- [ ] Saved moments screen opens from profile/menu entry
- [ ] No new analyzer warnings vs main

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 9: Report the PR URL**

The output of `gh pr create` includes the URL. Surface it to the user as the final progress report.

---

## Summary

19 commits (C0–C18). Restructure-heavy with bundled cleanup + April spec audit + 2 minor features. Mirrors the cadence of community wave-1 (Step 1) and stories restructure (Step 3).

**Total Flutter files touched:** ~30 (most are `git mv`-only; 4 are split into ~25 new files).
**Total backend files touched:** 0–2 depending on C15 audit findings.
**Total ARB strings added:** ~12 × 18 locales = 216 string additions.

## Test plan

- `flutter analyze` clean per commit
- `flutter pub get` + `flutter gen-l10n` clean at C18
- Manual smoke per C18 step 3 (feed → single → create → filter → saved → image viewer cross-ref)
- Backend tests run only if C15 touches `controllers/moments.js`

## Plan complete

Plan saved to `docs/superpowers/plans/2026-05-10-step5-moments-restructure.md`. Per user authorization ("do it automatic u don't need to ask me for confirmation for any task u do, I'm busy, u handle it"), proceeding directly to Subagent-Driven execution.

## Self-review notes (post-write)

**Spec coverage check:**
- Folder restructure into 8 subfolders → C8 (filter), C9 (feed), C10 (card), C11 (single), C12 (create), C13 (viewer), C14 (saved). ✅
- 4 big-file splits → C8, C10, C11, C12. ✅
- Cleanup sweep (snackbars / withOpacity / grey / debug) → C2, C5–C7. ✅
- l10n → C3, C4. ✅
- April spec audit + remediation → C15. ✅
- Tag autocomplete → C16. ✅
- Hide-this-user → C17. ✅
- Save-to-collection verification → covered as part of C6 snackbar migration + manual smoke at C18 (no separate task; the spec marked this as "likely just verification, not new code").
- Final analyzer + push + PR → C18. ✅

**Placeholder scan:** None of the disallowed patterns ("TBD", "TODO", "implement later", "fill in details", "appropriate error handling", etc.) used in the plan. Sections that say "adapt the body of X" reference an actual existing method by name and line number, which the implementer will read directly. ✅

**Type consistency:**
- `MomentsSnackBarType` enum used identically in C5, C6, C17. ✅
- `mutedMomentsProvider` defined in C17 step 1, consumed in C17 step 2 + step 3. ✅
- `_persistRecentTag` defined in C16 step 1, called in C16 step 3 (note: step 3 calls out to "remove the leading underscore" — sticking with `persistRecentTag` for the call site is correct). ✅
- `showCreateTagDialog` defined in C12 (or C16 if conservative variant deferred extraction), called from `create_moment.dart`. ✅

No issues found. Plan ready for execution.
