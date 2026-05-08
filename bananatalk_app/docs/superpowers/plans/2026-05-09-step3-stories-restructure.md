# Step 3 — Stories Restructure + April Spec Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete `lib/pages/story/` (dead orphan folder, 4,775 lines) and the unused `Modern*` viewer/feed files in the canonical folder (2,261 lines), restructure `lib/pages/stories/`, finish the April story-enhancements spec features (text stories, overlays, highlights audit).

**Architecture:** No new design — uses the existing `StoryViewerScreen` as the canonical viewer (verified live via `moments_main.dart` → `StoriesFeedWidget` → `StoryViewerScreen`). Backend `Story.js` already has `storyType`/`text`/`backgroundColor`/`fontStyle` fields shipped — Step 3 work is Flutter-only for text stories. Backend still needs `Story.overlays` JSON array + a highlights CRUD controller/routes.

**Tech Stack:** Flutter + Riverpod, Node.js/Express + MongoDB (backend), SharedPreferences

**Spec:** `docs/superpowers/specs/2026-05-09-step3-stories-restructure-design.md`

**Branch:** `refactor/step3-stories-restructure` (off `main`)

**Project pattern:** No new Flutter widget tests — verification is `flutter analyze` clean + manual smoke. Backend additions get unit tests where indicated.

## Spec corrections discovered during plan-writing

The spec assumed text-story backend fields were unshipped. They're actually all there in `models/Story.js`:
- `storyType: ['image', 'video', 'text']` ✅
- `text: { type: String, maxLength: 5000 }` ✅ (note: 5000 not 500)
- `backgroundColor: { type: String, default: '#000000' }` ✅ (hex string, no enum constraint — gradient names like `gradient_sunset` are also accepted as strings; Flutter renders client-side)
- `textColor: { type: String, default: '#ffffff' }` ✅
- `fontStyle: { type: String, enum: ['normal', 'bold', 'italic', 'handwriting'] }` ✅ (note: enum differs from April spec's `['sans','serif','bold','handwritten']`)

**Implication:** F1 (text stories) is Flutter-only work. The plan reflects this — no `Story.js` schema changes for text stories.

The spec also assumed a duplicate-viewer "investigate-then-pick" was needed. Investigation showed:
- Live: `moments_main.dart` → `StoriesFeedWidget` → `StoryViewerScreen` (the older viewer)
- Dead: `ModernStoryViewer` (1,578 lines) imported only by `ModernStoriesFeed` (683 lines), neither reachable from any live entry point

**Implication:** C2 simplifies to "delete the unused `Modern*` files" rather than a viewer-collapse migration.

Total commits drop from 18 → 16, effort ~4-5 weeks (was 5-7).

---

## Branch setup

- [ ] **Step 1: Create branch off main**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull
git checkout -b refactor/step3-stories-restructure
```

- [ ] **Step 2: Verify clean state (excluding platform-generated files)**

```bash
git status -s | grep -v -E "(Podfile.lock|generated_plugin_registrant|GeneratedPluginRegistrant)"
flutter analyze lib/pages/stories/ 2>&1 | tail -10
```

Expected: zero new analyzer errors above baseline.

---

## Task C0 — chore(stories): branch + deps audit

- [ ] **Step 1: Confirm no new deps needed**

Step 3 introduces no new packages; uses existing `flutter_riverpod`, `shared_preferences`, `http`, `image_picker`, `video_player`, `cached_network_image`. Verify:

```bash
grep -E "^  (flutter_riverpod|shared_preferences|http|image_picker|video_player|cached_network_image):" pubspec.yaml
```

If anything is missing, add via `flutter pub add <name>`. Otherwise no commit.

---

## Task C1 — chore(stories): delete dead `lib/pages/story/` orphan folder

**Files:**
- Delete: entire `lib/pages/story/` directory (5 files, 4,775 lines)

- [ ] **Step 1: Verify zero importers**

```bash
grep -rln "pages/story/" lib/ 2>/dev/null
grep -rln "StoryViewerScreen\|StoryCreationScreen\|StoryHighlightsScreen\|StoryArchiveScreen\|CloseFriendsScreen" lib/ 2>/dev/null | grep -v "lib/pages/story/" | grep -v "lib/pages/stories/"
```

Expected: both commands return empty (or only print files in `lib/pages/story/` itself, never outside). If anything else appears, STOP and investigate.

- [ ] **Step 2: Delete the folder**

```bash
git rm -r lib/pages/story/
```

- [ ] **Step 3: Verify analyzer + commit**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Expected: no errors. The deleted files have zero importers — analyzer should be clean.

```bash
git commit -m "chore(stories): C1 — delete dead lib/pages/story/ orphan folder (-4,775 lines)"
```

---

## Task C2 — chore(stories): delete unused Modern* viewer + feed files

**Files:**
- Delete: `lib/pages/stories/modern_story_viewer.dart` (1,578 lines)
- Delete: `lib/pages/stories/modern_stories_feed.dart` (683 lines)

- [ ] **Step 1: Verify zero live importers**

```bash
grep -rln "ModernStoryViewer\|modern_story_viewer\.dart" lib/ 2>/dev/null | grep -v "lib/pages/stories/modern_"
grep -rln "ModernStoriesFeed\|modern_stories_feed\.dart" lib/ 2>/dev/null | grep -v "lib/pages/stories/modern_"
```

Expected: both empty. The live flow uses `StoryViewerScreen` and `StoriesFeedWidget`; the `Modern*` files are unreferenced.

- [ ] **Step 2: Delete the files**

```bash
git rm lib/pages/stories/modern_story_viewer.dart lib/pages/stories/modern_stories_feed.dart
```

- [ ] **Step 3: Verify + commit**

```bash
flutter analyze lib/pages/stories/ 2>&1 | tail -10
```

```bash
git commit -m "chore(stories): C2 — delete unused ModernStoryViewer + ModernStoriesFeed (-2,261 lines)"
```

---

## Task C3 — refactor(stories): add ~28 English ARB keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_localizations.dart` (regenerated)
- Modify: `lib/l10n/app_localizations_en.dart` (regenerated)

- [ ] **Step 1: Insert keys into `app_en.arb`** (skip any that already exist with the same value)

```json
"storiesEmpty": "No stories yet",
"storiesLoadError": "Couldn't load stories",
"storiesRetry": "Try again",
"storiesNoMore": "You're all caught up",
"createTextStoryTab": "Text",
"createImageStoryTab": "Photo",
"createVideoStoryTab": "Video",
"enterTextHint": "Tap to type",
"pickBackground": "Background",
"pickFontStyle": "Font",
"pickTextColor": "Color",
"addText": "Add text",
"addEmoji": "Add emoji",
"chooseFont": "Choose font",
"chooseColor": "Choose color",
"dragToMove": "Drag to move",
"pinchToScale": "Pinch to scale",
"createHighlight": "New highlight",
"highlightName": "Highlight name",
"addToHighlight": "Add to highlight",
"removeFromHighlight": "Remove from highlight",
"highlightDeleted": "Highlight deleted",
"storyDeleted": "Story deleted",
"storySaved": "Saved to your story",
"storyTooLong": "Text is too long",
"storyPostFailed": "Couldn't post story",
"fontNormal": "Normal",
"fontBold": "Bold",
"fontItalic": "Italic",
"fontHandwriting": "Handwriting"
```

- [ ] **Step 2: Regenerate**

```bash
flutter gen-l10n
flutter analyze lib/l10n/ 2>&1 | tail -5
```

Expected: no errors. "Untranslated message" warnings for other locales are expected, fixed in C4.

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart
git commit -m "refactor(stories): C3 — add ~30 English ARB keys for Step 3"
```

---

## Task C4 — refactor(stories): translate ARB keys to 17 locales

**Files:**
- Modify: `lib/l10n/app_<locale>.arb` for: `ar de es fr hi id it ja ko pt ru th tl tr vi zh zh_TW`

- [ ] **Step 1: For each of the 17 locales, add the same keys with locale-appropriate translations.**

Critical rules:
- No ICU placeholders in this set (none of the C3 keys use `{...}`); just plain string translations.
- Skip keys that already exist with any value.

Examples for one locale (Korean, `lib/l10n/app_ko.arb`):

```json
"storiesEmpty": "아직 스토리가 없어요",
"storiesLoadError": "스토리를 불러올 수 없어요",
"storiesRetry": "다시 시도",
"storiesNoMore": "모두 확인했어요",
"createTextStoryTab": "텍스트",
"createImageStoryTab": "사진",
"createVideoStoryTab": "동영상",
"enterTextHint": "탭하여 입력",
"pickBackground": "배경",
"pickFontStyle": "글꼴",
"pickTextColor": "색상",
"addText": "텍스트 추가",
"addEmoji": "이모지 추가",
"chooseFont": "글꼴 선택",
"chooseColor": "색상 선택",
"dragToMove": "드래그하여 이동",
"pinchToScale": "핀치하여 크기 조정",
"createHighlight": "새 하이라이트",
"highlightName": "하이라이트 이름",
"addToHighlight": "하이라이트에 추가",
"removeFromHighlight": "하이라이트에서 제거",
"highlightDeleted": "하이라이트 삭제됨",
"storyDeleted": "스토리 삭제됨",
"storySaved": "스토리에 저장됨",
"storyTooLong": "텍스트가 너무 길어요",
"storyPostFailed": "스토리를 게시할 수 없어요",
"fontNormal": "보통",
"fontBold": "굵게",
"fontItalic": "기울임",
"fontHandwriting": "손글씨"
```

For agentic execution: dispatch a single agent across all 17 locales OR one per locale (per the wave-1 C6 cadence). Preserve any existing keys; only append the new ones.

- [ ] **Step 2: Regenerate + verify**

```bash
flutter gen-l10n
flutter analyze lib/l10n/ 2>&1 | tail -10
```

Expected: no errors; "untranslated message" warnings cleared for the new keys.

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/
git commit -m "refactor(stories): C4 — translate ~30 Step 3 keys to 17 locales"
```

---

## Task C5 — refactor(stories): add `widgets/` scaffolding

**Files:**
- Create: `lib/pages/stories/widgets/stories_snackbar.dart`
- Create: `lib/pages/stories/widgets/stories_dialog_scaffold.dart`
- Create: `lib/pages/stories/widgets/stories_empty_state.dart`
- Create: `lib/pages/stories/widgets/stories_error_state.dart`

(`overlay_editor.dart` already exists; leave alone.)

- [ ] **Step 1: Create `stories_snackbar.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum StoriesSnackBarType { info, success, error }

void showStoriesSnackBar(
  BuildContext context, {
  required String message,
  StoriesSnackBarType type = StoriesSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    StoriesSnackBarType.success => AppColors.primary,
    StoriesSnackBarType.error => AppColors.error,
    StoriesSnackBarType.info => Theme.of(context).colorScheme.surface,
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

- [ ] **Step 2: Create `stories_dialog_scaffold.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class StoriesDialogScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const StoriesDialogScaffold({
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

- [ ] **Step 3: Create `stories_empty_state.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class StoriesEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const StoriesEmptyState({
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
              Text(subtitle!,
                  style: context.bodySmall.copyWith(color: context.textSecondary),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `stories_error_state.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class StoriesErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const StoriesErrorState({
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
flutter analyze lib/pages/stories/widgets/ 2>&1 | tail -10
```

- [ ] **Step 6: Commit**

```bash
git add lib/pages/stories/widgets/
git commit -m "refactor(stories): C5 — add widgets/ scaffolding (snackbar, dialog, empty, error)"
```

---

## Task C6 — refactor(stories): migrate ~23 inline snackbars

**Files:**
- Modify various files under `lib/pages/stories/` containing `ScaffoldMessenger.showSnackBar`

- [ ] **Step 1: Locate sites**

```bash
grep -rn "ScaffoldMessenger\.of(context)\.showSnackBar" lib/pages/stories/
```

Expected: ~23 hits across `story_viewer_screen.dart`, `create_story_screen.dart`, possibly others.

- [ ] **Step 2: Migrate plain-text sites to `showStoriesSnackBar`**

Pattern:

```dart
// BEFORE
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(l10n.storySaved),
    backgroundColor: const Color(0xFF00BFA5),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
  ),
);

// AFTER
showStoriesSnackBar(
  context,
  message: l10n.storySaved,
  type: StoriesSnackBarType.success,
);
```

Color → type mapping:
- `AppColors.primary` / `0xFF00BFA5` → `success`
- `Colors.red` / `AppColors.error` → `error`
- otherwise → `info`

Add to each modified file:

```dart
import 'package:bananatalk_app/pages/stories/widgets/stories_snackbar.dart';
```

**SKIP** snackbars whose `content:` is a custom `Row` (icon + text) — leave those as-is.

- [ ] **Step 3: Verify + commit**

```bash
flutter analyze lib/pages/stories/ 2>&1 | tail -10
```

```bash
git add lib/pages/stories/
git commit -m "refactor(stories): C6 — migrate ~23 inline snackbars to showStoriesSnackBar"
```

---

## Task C7 — fix(stories): withOpacity + Colors.grey sweep

- [ ] **Step 1: Replace `.withOpacity(...)` with `.withValues(alpha: ...)`**

```bash
grep -rl "\.withOpacity(" lib/pages/stories/ | xargs sed -i '' 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g'
grep -rn "\.withOpacity(" lib/pages/stories/
```

Re-grep should return empty.

- [ ] **Step 2: Migrate hardcoded grey/white**

```bash
grep -rn "Colors\.grey\[\|Colors\.white\b" lib/pages/stories/
```

Apply per-site judgment using the wave-1 mapping:

| From | To (import `package:bananatalk_app/utils/theme_extensions.dart`) |
|---|---|
| `Colors.white` (background of card / surface / sheet) | `context.surfaceColor` |
| `Colors.grey[50]` / `[100]` | `context.containerColor` |
| `Colors.grey[200]` / `[300]` | `context.dividerColor` |
| `Colors.grey[400]` / `[500]` | `context.textMuted` |
| `Colors.grey[600]` / `[700]` | `context.textSecondary` |

**EXCEPTIONS — DO NOT migrate:**
- `Colors.white` used as `foregroundColor:` on `ElevatedButton.styleFrom(backgroundColor: <colored>, ...)` — universal codebase pattern
- White text on a colored gradient (e.g., the gradient story background)
- White on the always-dark story-viewer chrome (story viewer is intentionally a fixed dark theme like `voice_room_screen` was)

- [ ] **Step 3: Verify + commit**

```bash
flutter analyze lib/pages/stories/ 2>&1 | tail -10
```

```bash
git add lib/pages/stories/
git commit -m "fix(stories): C7 — withOpacity → withValues + Colors.grey theme migration"
```

---

## Task C8 — refactor(stories): split `create_story_screen.dart` into `create/` subfolder

**Files:**
- Modify: `lib/pages/stories/create_story_screen.dart` → moved to `lib/pages/stories/create/create_story_screen.dart`
- Create: `lib/pages/stories/create/create_image_tab.dart`
- (NEW text + overlay tabs come in C11/C13/C16, not here)

- [ ] **Step 1: Read current file end-to-end**

```bash
wc -l lib/pages/stories/create_story_screen.dart
sed -n '1,80p' lib/pages/stories/create_story_screen.dart
```

Identify:
- The current widget structure (likely a single `StatefulWidget` with image-picker + caption flow)
- Whether there's already a tab controller or if it's a single-flow screen

- [ ] **Step 2: Move + start subfolder**

```bash
mkdir -p lib/pages/stories/create
git mv lib/pages/stories/create_story_screen.dart lib/pages/stories/create/create_story_screen.dart
```

- [ ] **Step 3: Refactor into a TabController shell**

The shell needs to accommodate 3 tabs: Image, Video (if exists), Text (added in C11). For C8, just set up the shell with the existing image flow extracted to its own file:

```dart
// lib/pages/stories/create/create_story_screen.dart — shell
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/create/create_image_tab.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);  // text tab added in C11 → length 2
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text('Create story'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.createImageStoryTab),
            // Tab(text: l10n.createTextStoryTab) added in C11
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CreateImageTab(),
          // CreateTextTab() added in C11
        ],
      ),
    );
  }
}
```

Move the existing image-pick + caption + post flow from the original file body into a new `lib/pages/stories/create/create_image_tab.dart`:

```dart
import 'package:flutter/material.dart';

class CreateImageTab extends StatefulWidget {
  const CreateImageTab({super.key});

  @override
  State<CreateImageTab> createState() => _CreateImageTabState();
}

class _CreateImageTabState extends State<CreateImageTab> {
  // ... migrated state from the original screen (image picker, caption, post action, etc.)
  // Keep all existing logic identical — pure extract.

  @override
  Widget build(BuildContext context) {
    // ... migrated build body
    return const Placeholder();  // replace with the actual migrated UI
  }
}
```

**Pragmatic note:** if the original `create_story_screen.dart` has logic deeply entangled with state (provider, scaffolds, etc.) that resists clean extraction, leave the original code intact in `create_story_screen.dart` and **defer the tab structure to C11** when the text tab actually arrives. Report DONE_WITH_CONCERNS in that case.

- [ ] **Step 4: Update imports across the app**

```bash
grep -rln "pages/stories/create_story_screen\.dart" lib/ | grep -v "pages/stories/create/"
```

Update each importer to `pages/stories/create/create_story_screen.dart`.

- [ ] **Step 5: Verify + commit**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

```bash
git add lib/pages/stories/ lib/
git commit -m "refactor(stories): C8 — split create_story_screen into create/ subfolder"
```

---

## Task C9 — refactor(stories): split canonical viewer into `viewer/` subfolder

**Files:**
- Modify: `lib/pages/stories/story_viewer_screen.dart` → moved to `lib/pages/stories/viewer/story_viewer_screen.dart`
- Create: `lib/pages/stories/viewer/viewer_progress_bar.dart`
- Create: `lib/pages/stories/viewer/viewer_header.dart`
- Create: `lib/pages/stories/viewer/viewer_controls.dart`

- [ ] **Step 1: Read current viewer**

```bash
wc -l lib/pages/stories/story_viewer_screen.dart
sed -n '1,100p' lib/pages/stories/story_viewer_screen.dart
```

Identify the composable parts: top progress bar segments, user info header (avatar + name + close), tap-to-skip / long-press-to-pause controls, the media render area.

- [ ] **Step 2: Move + start subfolder**

```bash
mkdir -p lib/pages/stories/viewer
git mv lib/pages/stories/story_viewer_screen.dart lib/pages/stories/viewer/story_viewer_screen.dart
```

- [ ] **Step 3: Extract `viewer_progress_bar.dart`**

```dart
import 'package:flutter/material.dart';

class ViewerProgressBar extends StatelessWidget {
  final int totalSegments;
  final int currentSegment;
  final double currentProgress;  // 0..1 within the current segment

  const ViewerProgressBar({
    super.key,
    required this.totalSegments,
    required this.currentSegment,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSegments, (i) {
        final progress = i < currentSegment
            ? 1.0
            : i == currentSegment
                ? currentProgress
                : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Extract `viewer_header.dart`**

```dart
import 'package:flutter/material.dart';

class ViewerHeader extends StatelessWidget {
  final String userName;
  final String? userAvatar;
  final String timeAgo;
  final VoidCallback onClose;

  const ViewerHeader({
    super.key,
    required this.userName,
    required this.timeAgo,
    required this.onClose,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: (userAvatar != null && userAvatar!.isNotEmpty)
                ? NetworkImage(userAvatar!)
                : null,
            child: (userAvatar == null || userAvatar!.isEmpty)
                ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    )),
                Text(timeAgo,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Extract `viewer_controls.dart`**

`ViewerControls` is the gesture-detector layer (left tap = previous, right tap = next, long-press = pause). Match the existing logic in `story_viewer_screen.dart`:

```dart
import 'package:flutter/material.dart';

class ViewerControls extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final Widget child;

  const ViewerControls({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.onPause,
    required this.onResume,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Row(
          children: [
            // Left tap zone — previous
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onPrevious,
                onLongPressStart: (_) => onPause(),
                onLongPressEnd: (_) => onResume(),
              ),
            ),
            // Right tap zone — next
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onNext,
                onLongPressStart: (_) => onPause(),
                onLongPressEnd: (_) => onResume(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Update `story_viewer_screen.dart` to compose the extracted widgets**

The screen-level state (story list, current index, animation controller, video controller, etc.) stays. The build replaces inline Row / GestureDetector / Header blocks with the new widgets:

```dart
import 'package:bananatalk_app/pages/stories/viewer/viewer_progress_bar.dart';
import 'package:bananatalk_app/pages/stories/viewer/viewer_header.dart';
import 'package:bananatalk_app/pages/stories/viewer/viewer_controls.dart';
```

Body composition:

```dart
Scaffold(
  backgroundColor: Colors.black,
  body: SafeArea(
    child: Stack(
      children: [
        // Media layer (existing)
        Positioned.fill(child: _buildMediaLayer()),
        // Tap controls (full-screen, non-blocking)
        Positioned.fill(
          child: ViewerControls(
            onPrevious: _previous,
            onNext: _next,
            onPause: _pause,
            onResume: _resume,
            child: const SizedBox.expand(),
          ),
        ),
        // Top overlay: progress + header
        Positioned(
          top: 0, left: 0, right: 0,
          child: Column(
            children: [
              ViewerProgressBar(
                totalSegments: _stories.length,
                currentSegment: _currentIndex,
                currentProgress: _progressController.value,
              ),
              ViewerHeader(
                userName: _currentStory.userName,
                userAvatar: _currentStory.userAvatar,
                timeAgo: _currentStory.timeAgo,
                onClose: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
```

Match field/method names to whatever the existing `_StoryViewerScreenState` actually has (likely `_currentIndex`, `_pageController`, `_progressAnimation`, etc.). Read the file before extraction to find them.

- [ ] **Step 7: Update imports across the app**

```bash
grep -rln "pages/stories/story_viewer_screen\.dart" lib/ | grep -v "pages/stories/viewer/"
```

Likely importers: `lib/pages/stories/stories_feed_widget.dart` and `lib/pages/profile/highlights.dart`. Update each to `pages/stories/viewer/story_viewer_screen.dart`.

- [ ] **Step 8: Verify + commit**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

```bash
git add lib/pages/stories/ lib/
git commit -m "refactor(stories): C9 — split story_viewer_screen into viewer/ subfolder"
```

---

## Task C10 — refactor(stories): move feed files into `feed/` subfolder

**Files:**
- Modify: `lib/pages/stories/stories_feed_widget.dart` → moved to `lib/pages/stories/feed/stories_feed_widget.dart`
- (modern_stories_feed.dart was deleted in C2; only the live `stories_feed_widget.dart` survives)

- [ ] **Step 1: Move**

```bash
mkdir -p lib/pages/stories/feed
git mv lib/pages/stories/stories_feed_widget.dart lib/pages/stories/feed/stories_feed_widget.dart
```

- [ ] **Step 2: Update imports across the app**

```bash
grep -rln "pages/stories/stories_feed_widget\.dart" lib/ | grep -v "pages/stories/feed/"
```

Likely importer: `lib/pages/moments/moments_main.dart`. Update to `pages/stories/feed/stories_feed_widget.dart`.

- [ ] **Step 3: Verify + commit**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

```bash
git add lib/pages/stories/ lib/
git commit -m "refactor(stories): C10 — move stories_feed_widget into feed/ subfolder"
```

---

## Task C11 — feat(stories): text-story creation tab

**Files:**
- Create: `lib/pages/stories/models/story_gradient.dart` (13 gradient presets)
- Create: `lib/pages/stories/create/create_text_tab.dart`
- Create: `lib/pages/stories/create/gradient_picker.dart`
- Modify: `lib/pages/stories/create/create_story_screen.dart` (extend tab controller to length 2)
- Modify: the existing story-post service method to accept `storyType: 'text'` payloads

**Backend status:** `Story.js` already has `storyType`, `text`, `backgroundColor`, `textColor`, `fontStyle` fields. No backend schema changes needed.

- [ ] **Step 1: Create `story_gradient.dart` (13 presets)**

```dart
import 'package:flutter/material.dart';

class StoryGradient {
  final String id;
  final String name;
  final List<Color> colors;
  final List<double> stops;

  const StoryGradient({
    required this.id,
    required this.name,
    required this.colors,
    this.stops = const [0.0, 1.0],
  });

  LinearGradient toLinearGradient() => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: stops,
      );

  static const List<StoryGradient> presets = [
    StoryGradient(id: 'gradient_sunset', name: 'Sunset', colors: [Color(0xFFFF512F), Color(0xFFF09819)]),
    StoryGradient(id: 'gradient_ocean', name: 'Ocean', colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)]),
    StoryGradient(id: 'gradient_forest', name: 'Forest', colors: [Color(0xFF134E5E), Color(0xFF71B280)]),
    StoryGradient(id: 'gradient_purple', name: 'Purple', colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
    StoryGradient(id: 'gradient_fire', name: 'Fire', colors: [Color(0xFFEB5757), Color(0xFFF2994A)]),
    StoryGradient(id: 'gradient_midnight', name: 'Midnight', colors: [Color(0xFF232526), Color(0xFF414345)]),
    StoryGradient(id: 'gradient_candy', name: 'Candy', colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)]),
    StoryGradient(id: 'gradient_sky', name: 'Sky', colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
    StoryGradient(id: 'gradient_aurora', name: 'Aurora', colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]),
    StoryGradient(id: 'gradient_peach', name: 'Peach', colors: [Color(0xFFED4264), Color(0xFFFFEDBC)]),
    StoryGradient(id: 'gradient_mint', name: 'Mint', colors: [Color(0xFF00B09B), Color(0xFF96C93D)]),
    StoryGradient(id: 'gradient_lavender', name: 'Lavender', colors: [Color(0xFFE1B0FF), Color(0xFFB39DDB)]),
    StoryGradient(id: 'gradient_galaxy', name: 'Galaxy', colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], stops: [0.0, 0.5, 1.0]),
  ];

  static StoryGradient byId(String id) =>
      presets.firstWhere((g) => g.id == id, orElse: () => presets.first);
}
```

- [ ] **Step 2: Create `gradient_picker.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/stories/models/story_gradient.dart';

class GradientPicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onChanged;

  const GradientPicker({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: StoryGradient.presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = StoryGradient.presets[i];
          final isSelected = g.id == selectedId;
          return GestureDetector(
            onTap: () => onChanged(g.id),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: g.toLinearGradient(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 3 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Create `create_text_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/models/story_gradient.dart';
import 'package:bananatalk_app/pages/stories/create/gradient_picker.dart';
import 'package:bananatalk_app/pages/stories/widgets/stories_snackbar.dart';

class CreateTextTab extends StatefulWidget {
  const CreateTextTab({super.key});

  @override
  State<CreateTextTab> createState() => _CreateTextTabState();
}

class _CreateTextTabState extends State<CreateTextTab> {
  final _controller = TextEditingController();
  String _gradientId = StoryGradient.presets.first.id;
  String _fontStyle = 'normal';  // backend enum: normal/bold/italic/handwriting
  String _textColor = '#FFFFFF';
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isPosting = true);
    try {
      // Calls existing story-post service with:
      //   storyType: 'text'
      //   text: _controller.text.trim()
      //   backgroundColor: _gradientId   (gradient name; backend stores as string)
      //   textColor: _textColor
      //   fontStyle: _fontStyle
      // Implementation: invoke whatever the existing post-story service is.
      // (See lib/services/stories_service.dart or similar — find the actual path
      // during implementation, mirror the image-post pattern.)
      await Future.delayed(const Duration(milliseconds: 300));  // placeholder
      if (!mounted) return;
      Navigator.of(context).pop();
      showStoriesSnackBar(context,
          message: AppLocalizations.of(context)!.storySaved,
          type: StoriesSnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      showStoriesSnackBar(context,
          message: AppLocalizations.of(context)!.storyPostFailed,
          type: StoriesSnackBarType.error);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gradient = StoryGradient.byId(_gradientId);
    return Container(
      decoration: BoxDecoration(gradient: gradient.toLinearGradient()),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 5000,
                    textAlign: TextAlign.center,
                    maxLines: null,
                    style: TextStyle(
                      color: _textColor == '#FFFFFF' ? Colors.white : Colors.black,
                      fontSize: 28,
                      fontWeight: _fontStyle == 'bold' ? FontWeight.bold : FontWeight.normal,
                      fontStyle: _fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.enterTextHint,
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ),
            GradientPicker(
              selectedId: _gradientId,
              onChanged: (id) => setState(() => _gradientId = id),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isPosting || _controller.text.trim().isEmpty ? null : _post,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: Text(_isPosting ? '…' : 'Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire `create_text_tab` into `create_story_screen.dart`**

Update the shell to length 2 and add the second Tab + child:

```dart
_tabController = TabController(length: 2, vsync: this);
// ...
TabBar(
  controller: _tabController,
  tabs: [
    Tab(text: l10n.createImageStoryTab),
    Tab(text: l10n.createTextStoryTab),
  ],
),
TabBarView(
  controller: _tabController,
  children: const [
    CreateImageTab(),
    CreateTextTab(),
  ],
),
```

- [ ] **Step 5: Wire the actual post call**

Find the existing story-post service method (likely in `lib/services/stories_service.dart` or `lib/providers/`):

```bash
grep -rn "createStory\|postStory\|uploadStory" lib/ 2>/dev/null | head -10
```

Replace the `await Future.delayed(...)` placeholder in `_post()` with a call to the real service, passing `{storyType: 'text', text, backgroundColor: _gradientId, textColor, fontStyle}`. The existing service likely already handles the multipart/JSON payload — just feed it the new fields.

- [ ] **Step 6: Verify + commit**

```bash
flutter analyze lib/pages/stories/ 2>&1 | tail -10
```

```bash
git add lib/pages/stories/
git commit -m "feat(stories): C11 — text-story creation tab + gradient picker (Flutter)"
```

---

## Task C12 — feat(stories): text-story rendering in viewer

**Files:**
- Create: `lib/pages/stories/viewer/viewer_text_story_layer.dart`
- Modify: `lib/pages/stories/viewer/story_viewer_screen.dart` (use the new layer when `storyType == 'text'`)

- [ ] **Step 1: Create the rendering layer**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/stories/models/story_gradient.dart';

class ViewerTextStoryLayer extends StatelessWidget {
  final String text;
  final String backgroundColorHint;  // either '#RRGGBB' or 'gradient_<name>'
  final String textColor;             // '#RRGGBB'
  final String fontStyle;             // 'normal' | 'bold' | 'italic' | 'handwriting'

  const ViewerTextStoryLayer({
    super.key,
    required this.text,
    required this.backgroundColorHint,
    required this.textColor,
    required this.fontStyle,
  });

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(value, radix: 16));
  }

  Decoration _background() {
    if (backgroundColorHint.startsWith('gradient_')) {
      return BoxDecoration(
        gradient: StoryGradient.byId(backgroundColorHint).toLinearGradient(),
      );
    }
    return BoxDecoration(color: _parseColor(backgroundColorHint));
  }

  TextStyle _textStyleOf() {
    final base = TextStyle(
      color: _parseColor(textColor),
      fontSize: 28,
      height: 1.3,
    );
    return switch (fontStyle) {
      'bold' => base.copyWith(fontWeight: FontWeight.bold),
      'italic' => base.copyWith(fontStyle: FontStyle.italic),
      'handwriting' => base.copyWith(fontFamily: 'Caveat'),  // assume fontFamily exists or fallback
      _ => base,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _background(),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: _textStyleOf(),
            ),
          ),
        ),
      ),
    );
  }
}
```

(Font family `'Caveat'` is a placeholder for "handwriting" — if the project doesn't bundle that font, the platform default applies. If you want a true handwriting font, add it to `pubspec.yaml` as a follow-up; deferred here.)

- [ ] **Step 2: Use the new layer in `story_viewer_screen.dart`**

In the media-render branch (where the screen currently shows `Image.network` or `VideoPlayer`), add a top-level branch on `storyType`:

```dart
Widget _buildMediaLayer() {
  final story = _currentStory;
  if (story.storyType == 'text') {
    return ViewerTextStoryLayer(
      text: story.text ?? '',
      backgroundColorHint: story.backgroundColor ?? '#000000',
      textColor: story.textColor ?? '#FFFFFF',
      fontStyle: story.fontStyle ?? 'normal',
    );
  }
  // ... existing image/video rendering branches ...
}
```

Match the actual field names on the Flutter `Story` model (likely `lib/providers/provider_models/story_model.dart`). If the model is missing `storyType`/`text`/`backgroundColor`/`textColor`/`fontStyle` fields, add them in this same commit (the JSON shape from backend already includes them).

- [ ] **Step 3: Update the `Story` model if needed**

```bash
grep -n "class Story\|storyType\|text\|backgroundColor\|textColor\|fontStyle" lib/providers/provider_models/story_model.dart 2>/dev/null
```

If fields are missing, add them with default values matching the backend schema.

- [ ] **Step 4: Verify + commit**

```bash
flutter analyze lib/pages/stories/ lib/providers/provider_models/ 2>&1 | tail -10
```

```bash
git add lib/
git commit -m "feat(stories): C12 — text-story rendering in viewer"
```

---

## Task C13 — feat(stories) + backend: highlights audit + finish

**Files (backend):**
- Verify: `models/StoryHighlight.js` (exists per spec audit)
- Possibly add: `controllers/highlights.js`, `routes/highlights.js` (likely missing)

**Files (Flutter):**
- Possibly create: `lib/services/highlights_service.dart`
- Possibly create: `lib/pages/profile/main/profile_highlights.dart` or similar

- [ ] **Step 1: Audit backend**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
ls controllers/ routes/ | grep -i highlight
cat models/StoryHighlight.js
```

If `controllers/highlights.js` and `routes/highlights.js` don't exist, they need to be created.

- [ ] **Step 2: If missing, implement backend CRUD**

In `controllers/highlights.js`:

```js
const StoryHighlight = require('../models/StoryHighlight');
const Story = require('../models/Story');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/async');

exports.createHighlight = asyncHandler(async (req, res, next) => {
  const { name, coverStoryId, storyIds } = req.body;
  if (!name || !Array.isArray(storyIds) || storyIds.length === 0) {
    return next(new ErrorResponse('name and storyIds[] required', 400));
  }
  const highlight = await StoryHighlight.create({
    user: req.user._id,
    name,
    coverStoryId,
    stories: storyIds,
  });
  // Mark each story as highlighted so cleanup cron skips them
  await Story.updateMany(
    { _id: { $in: storyIds }, user: req.user._id },
    { $set: { isHighlighted: true } }
  );
  res.status(201).json({ success: true, data: highlight });
});

exports.getUserHighlights = asyncHandler(async (req, res, next) => {
  const userId = req.params.userId;
  const highlights = await StoryHighlight.find({ user: userId })
    .populate('coverStoryId')
    .sort({ createdAt: -1 });
  res.status(200).json({ success: true, data: highlights });
});

exports.deleteHighlight = asyncHandler(async (req, res, next) => {
  const highlight = await StoryHighlight.findById(req.params.id);
  if (!highlight) return next(new ErrorResponse('Highlight not found', 404));
  if (String(highlight.user) !== String(req.user._id)) {
    return next(new ErrorResponse('Forbidden', 403));
  }
  // Unset isHighlighted on stories no longer in any highlight
  const storyIds = highlight.stories;
  await highlight.deleteOne();
  // Re-check: if any story is in another highlight, leave isHighlighted true
  const stillHighlighted = await StoryHighlight.find({
    stories: { $in: storyIds },
  }).distinct('stories');
  const stillSet = new Set(stillHighlighted.map(String));
  const toUnflag = storyIds.filter((id) => !stillSet.has(String(id)));
  if (toUnflag.length > 0) {
    await Story.updateMany(
      { _id: { $in: toUnflag } },
      { $set: { isHighlighted: false } }
    );
  }
  res.status(200).json({ success: true, data: { id: req.params.id } });
});
```

In `routes/highlights.js`:

```js
const express = require('express');
const { protect } = require('../middleware/auth');
const {
  createHighlight,
  getUserHighlights,
  deleteHighlight,
} = require('../controllers/highlights');

const router = express.Router();

router.post('/', protect, createHighlight);
router.get('/users/:userId', protect, getUserHighlights);
router.delete('/:id', protect, deleteHighlight);

module.exports = router;
```

Mount the router in `server.js` (or wherever routes are registered):

```js
app.use('/api/v1/highlights', require('./routes/highlights'));
```

- [ ] **Step 3: Audit Flutter highlights consumer**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
ls lib/services/ | grep -i highlight
ls lib/pages/profile/ -R | grep -i highlight
cat lib/pages/profile/highlights.dart
```

Whatever's missing (`highlights_service.dart`, profile-highlights row widget), build it. Mirror the existing `email_preferences` / `community_provider` service pattern for the API client. Mirror the community/wave-1 widget patterns for the profile-row UI.

- [ ] **Step 4: Verify + commit**

Backend:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node --check controllers/highlights.js
node --check routes/highlights.js
git add controllers/ routes/ server.js
git commit -m "feat(stories): C13 — highlights CRUD endpoints"
```

Flutter (only if frontend gaps were filled):

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze lib/ 2>&1 | tail -10
git add lib/
git commit -m "feat(stories): C13 — highlights service + profile row (Flutter)"
```

---

## Task C14 — feat(stories) + backend: overlays schema

**Files (backend):**
- Modify: `models/Story.js` — add `overlays` array

- [ ] **Step 1: Add `overlays` to `Story.js`**

In `models/Story.js`, add:

```js
overlays: {
  type: [{
    type: { type: String, enum: ['text', 'emoji'], required: true },
    content: { type: String, required: true },
    x: { type: Number, min: 0, max: 1, required: true },
    y: { type: Number, min: 0, max: 1, required: true },
    scale: { type: Number, min: 0.5, max: 3.0, default: 1.0 },
    rotation: { type: Number, default: 0 },
    color: { type: String, default: '#FFFFFF' },
    fontStyle: { type: String, enum: ['sans-serif', 'serif', 'bold', 'handwritten'], default: 'sans-serif' },
    bgMode: { type: String, enum: ['none', 'semi', 'solid'], default: 'none' },
  }],
  validate: {
    validator: function (arr) {
      return Array.isArray(arr) && arr.length <= 5;
    },
    message: 'A story can have at most 5 overlays',
  },
  default: [],
},
```

(Field shape mirrors the existing Flutter `OverlayElement` toJson at `lib/pages/stories/widgets/overlay_editor.dart` lines 24-34.)

- [ ] **Step 2: Update story-creation controller** to accept `overlays` from body

In `controllers/stories.js` (or wherever stories are created):

```js
// Inside the create-story handler, after extracting other fields:
const overlays = Array.isArray(req.body.overlays) ? req.body.overlays : [];
// ... pass `overlays` to Story.create({...})
```

- [ ] **Step 3: Verify + commit (backend)**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node --check models/Story.js
node --check controllers/stories.js
git add models/ controllers/
git commit -m "feat(stories): C14 — Story.overlays JSON array (max 5 overlays)"
```

---

## Task C15 — feat(stories): overlay editor wire-up + viewer rendering

**Files:**
- Modify: `lib/pages/stories/widgets/overlay_editor.dart` (likely already complete; just wire into create flow)
- Modify: `lib/pages/stories/create/create_image_tab.dart` (add an "Add overlays" button that opens the editor)
- Create: `lib/pages/stories/viewer/viewer_overlay_layer.dart`
- Modify: `lib/pages/stories/viewer/story_viewer_screen.dart` (render overlay layer)
- Modify: Flutter Story model — add `overlays: List<OverlayElement>` field
- Modify: story-post service — pass `overlays` field

- [ ] **Step 1: Add overlays editor entry to image-create tab**

Find the post-image-pick UI in `create_image_tab.dart` and add a button:

```dart
ElevatedButton.icon(
  icon: const Icon(Icons.text_format),
  label: Text(AppLocalizations.of(context)!.addText),
  onPressed: _openOverlayEditor,
),
```

`_openOverlayEditor` opens a full-screen modal where the user adds/manipulates overlays via the existing `OverlayEditor` widget and returns the `List<OverlayElement>` on save:

```dart
Future<void> _openOverlayEditor() async {
  final result = await Navigator.of(context).push<List<OverlayElement>>(
    MaterialPageRoute(
      builder: (_) => OverlayEditorScreen(
        backgroundImage: _pickedImage,
        initialOverlays: _overlays,
      ),
    ),
  );
  if (result != null) {
    setState(() => _overlays = result);
  }
}
```

If `OverlayEditorScreen` (the wrapping screen) doesn't exist yet, create it in `lib/pages/stories/widgets/overlay_editor.dart` alongside the existing `OverlayElement` and `DraggableOverlay` classes. Match the existing file's style.

- [ ] **Step 2: Pass `overlays` to the post-story service**

Update `_post()` in `create_image_tab.dart` and `create_text_tab.dart` (text stories CAN also have overlays per April spec) to include the field:

```dart
final overlaysJson = _overlays.map((e) => e.toJson()).toList();
await storiesService.postStory(..., overlays: overlaysJson);
```

If `postStory` doesn't accept `overlays`, extend its signature.

- [ ] **Step 3: Create `viewer_overlay_layer.dart`**

```dart
import 'package:flutter/material.dart';

class StoryOverlay {
  final String type;     // 'text' | 'emoji'
  final String content;
  final double x;        // 0..1
  final double y;        // 0..1
  final double scale;
  final double rotation;
  final String color;    // hex like '#FFFFFF'
  final String fontStyle;
  final String bgMode;   // 'none' | 'semi' | 'solid'

  StoryOverlay({
    required this.type,
    required this.content,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0,
    this.color = '#FFFFFF',
    this.fontStyle = 'sans-serif',
    this.bgMode = 'none',
  });

  factory StoryOverlay.fromJson(Map<String, dynamic> json) => StoryOverlay(
        type: json['type']?.toString() ?? 'text',
        content: json['content']?.toString() ?? '',
        x: (json['x'] as num?)?.toDouble() ?? 0.5,
        y: (json['y'] as num?)?.toDouble() ?? 0.5,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        color: json['color']?.toString() ?? '#FFFFFF',
        fontStyle: json['fontStyle']?.toString() ?? 'sans-serif',
        bgMode: json['bgMode']?.toString() ?? 'none',
      );
}

class ViewerOverlayLayer extends StatelessWidget {
  final List<StoryOverlay> overlays;

  const ViewerOverlayLayer({super.key, required this.overlays});

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(value, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Stack(
          children: overlays.map((o) {
            final left = o.x * constraints.maxWidth;
            final top = o.y * constraints.maxHeight;
            final color = _parseColor(o.color);
            final base = TextStyle(color: color, fontSize: 24);
            final styled = switch (o.fontStyle) {
              'bold' => base.copyWith(fontWeight: FontWeight.bold),
              'serif' => base.copyWith(fontFamily: 'serif'),
              'handwritten' => base.copyWith(fontFamily: 'Caveat'),
              _ => base,
            };
            Widget body = Text(o.content, style: styled);
            if (o.type == 'emoji') {
              body = Text(o.content, style: TextStyle(fontSize: 36 * o.scale));
            } else {
              body = Transform.scale(scale: o.scale, child: body);
            }
            if (o.bgMode == 'semi') {
              body = Container(
                color: Colors.black.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: body,
              );
            } else if (o.bgMode == 'solid') {
              body = Container(
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: body,
              );
            }
            return Positioned(
              left: left - 60,  // approximate centering — pivot fix
              top: top - 20,
              child: Transform.rotate(
                angle: o.rotation * 3.14159 / 180,
                child: body,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Render overlays in the viewer**

In `story_viewer_screen.dart`, stack `ViewerOverlayLayer` on top of the media (between media and tap-controls):

```dart
Stack(
  children: [
    Positioned.fill(child: _buildMediaLayer()),
    if (_currentStory.overlays.isNotEmpty)
      Positioned.fill(
        child: ViewerOverlayLayer(overlays: _currentStory.overlays),
      ),
    // ... existing controls + header overlays
  ],
)
```

Update the Flutter `Story` model to include:

```dart
final List<StoryOverlay> overlays;
```

with `fromJson` parsing the array.

- [ ] **Step 5: Verify + commit**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

```bash
git add lib/
git commit -m "feat(stories): C15 — overlay editor wire-up + viewer rendering"
```

---

## Task C16 — chore(stories): final analyzer + smoke + push + PR

- [ ] **Step 1: Run analyzer scoped to Step 3 areas**

```bash
flutter analyze \
  lib/pages/stories/ \
  lib/providers/provider_models/story_model.dart \
  lib/services/highlights_service.dart \
  2>&1 | tail -50
```

If `highlights_service.dart` doesn't exist (Flutter half of C13 was a no-op), drop that path from the analyze call. Triage:
- Errors → must fix
- Warnings introduced by Step 3 → fix
- Info-level lints (unused imports introduced by Step 3) → remove

- [ ] **Step 2: Final analyzer pass on the whole tree**

```bash
flutter analyze lib/ 2>&1 | grep "error •" | head -10
```

Expected: zero new errors. Fix or revert anything that appears.

- [ ] **Step 3: Optional cleanup commit**

If the analyzer pass found anything to fix:

```bash
git add lib/
git commit -m "chore(stories): C16 — final analyzer cleanup pass"
```

If nothing changed, skip.

- [ ] **Step 4: Push the Flutter branch**

```bash
git push -u origin refactor/step3-stories-restructure 2>&1 | tail -5
```

- [ ] **Step 5: Push backend commits**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git status -s
git log --oneline @{u}.. 2>&1 | head -10
git push origin main 2>&1 | tail -5
```

Backend should have 2-3 wave-3 commits pending: highlights CRUD (C13) + Story.overlays (C14), and any controller updates for accepting overlays in story-create.

- [ ] **Step 6: Create PR for the Flutter branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
gh pr create --title "Stories restructure + April spec features (Step 3)" --body "$(cat <<'EOF'
## Summary

Step 3 of the post-wave-1 roadmap. Three discrete wins bundled:

### 1. Dead-code retirement (-7,036 lines)
- `lib/pages/story/` (singular, 4,775 lines) — zero importers
- `lib/pages/stories/modern_story_viewer.dart` (1,578) + `modern_stories_feed.dart` (683) — unused parallel viewer/feed never reachable from live flow
- Live flow = `moments_main` → `StoriesFeedWidget` → `StoryViewerScreen` confirmed canonical

### 2. Restructure + cleanup
- `lib/pages/stories/` → `widgets/`, `viewer/`, `feed/`, `create/`, `models/` subfolders
- `withOpacity` → `withValues(alpha:)` (28 sites), `Colors.grey[*]` → theme getters (42 sites)
- 23 inline snackbars → new `showStoriesSnackBar` helper
- Light split of `create_story_screen` into a 2-tab shell (Image / Text)

### 3. April spec — finished features
- **Text stories** with 13 gradient presets (Flutter-only — backend fields shipped previously)
- **Highlights audit + CRUD** — `controllers/highlights.js` + `routes/highlights.js` if missing; profile row UI if missing
- **Overlays / stickers** — new `Story.overlays` JSON array (max 5), editor wire-up, viewer rendering

## Test plan

- [ ] Stories restructure: every entry point still works (moments_main → feed → viewer; profile highlights tap → viewer)
- [ ] Text story: create → post → see in feed → tap → render gradient + text → close
- [ ] Highlights: pin a story → appears on profile → unpinning removes; cleanup cron preserves highlighted stories past 24h
- [ ] Overlays: add text + emoji to an image story → drag/scale/rotate → post → viewer renders overlays in correct positions
- [ ] Dark mode: walk every stories screen; no white-on-white surfaces

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" 2>&1 | tail -5
```

- [ ] **Step 7: Report**

Output the final state: branch SHA, total commit count, PR URL, backend commit count pushed.

---

## Plan complete

**Spec:** `docs/superpowers/specs/2026-05-09-step3-stories-restructure-design.md`
**Plan:** this file
**Branch:** `refactor/step3-stories-restructure`
**Total: ~16 commits, ~4-5 weeks** (down from 18 / 5-7 weeks because the duplicate-viewer "investigation" turned into pure dead-code deletion and text-story backend was already shipped).

Backend commits land on `main` of `language_exchange_backend_application` per project pattern.

---

## Self-review notes (post-write)

**Spec coverage:**
- ✅ Delete `lib/pages/story/` orphan (C1)
- ✅ Collapse duplicate viewer (became delete-Modern-files in C2)
- ✅ ARB keys + 17 locales (C3, C4)
- ✅ Cleanup sweep — widgets scaffolding, snackbars, withOpacity, Colors.grey (C5, C6, C7)
- ✅ Folder restructure — create/, viewer/, feed/ (C8, C9, C10)
- ✅ Text stories — Flutter creation + viewer rendering (C11, C12); backend was already shipped
- ✅ Highlights audit + finish (C13)
- ✅ Overlays — backend schema + editor wire-up + viewer rendering (C14, C15)
- ✅ Final polish + PR (C16)

**Type consistency:**
- `StoryGradient.id` (string like `gradient_sunset`) is consistent across `story_gradient.dart`, `gradient_picker.dart`, `create_text_tab.dart`, `viewer_text_story_layer.dart`.
- `OverlayElement` (Flutter, in `widgets/overlay_editor.dart`) and `StoryOverlay` (Flutter, in `viewer/viewer_overlay_layer.dart`) — different classes by design (editor vs viewer), but their JSON shapes match the backend Mongoose validator added in C14. Cross-check field names: `type`, `content`, `x`, `y`, `scale`, `rotation`, `color`, `fontStyle`, `bgMode`. ✓
- `Story.fontStyle` enum is `['normal', 'bold', 'italic', 'handwriting']` per existing backend schema — reused consistently across C11 (creation) and C12 (rendering).
- `Story.backgroundColor` accepts hex strings AND gradient names like `gradient_sunset` (no enum constraint on backend); `viewer_text_story_layer.dart` branches on `startsWith('gradient_')` to differentiate. ✓

**Placeholder scan:** no "TBD" / "TODO" / "implement later" placeholders. The `Future.delayed` in C11 step 3 is a explicitly-marked placeholder for the post-call, with C11 step 5 specifying the actual wiring step.

**Cross-PR dependencies:**
- C8 (create/ subfolder) must precede C11 (which adds the text tab to the shell).
- C9 (viewer/ subfolder) must precede C12 (text-story rendering) and C15 (overlay rendering).
- C14 (backend overlays schema) must precede C15 (Flutter overlay sending) — otherwise the sent overlays would be silently dropped.
- C13 (highlights) is independent of all other commits; can land anywhere after C5.
