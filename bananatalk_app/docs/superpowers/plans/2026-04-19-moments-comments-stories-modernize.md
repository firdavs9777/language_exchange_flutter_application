# Moments, Comments & Stories — Bug Fixes + UI Modernization Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix likes/comment count bugs, modernize the visual polish of moment cards, comments, and stories bar/viewer, add engagement text, story viewers list, and story reactions via chat.

**Architecture:** Component-by-component approach — fully polish moment cards (including bug fixes), then comments, then stories. Each component is self-contained and testable before moving on. Backend changes are minimal (add storyReference to Message model).

**Tech Stack:** Node.js/Express + MongoDB (backend), Flutter + Riverpod (frontend)

**Spec:** `docs/superpowers/specs/2026-04-19-moments-comments-stories-modernize.md`

---

## Task 1: Moment Card — Bug Fixes

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/moment_card.dart`

- [ ] **Step 1: Fix double-tap like toggle**

In `_buildDoubleTapLikeArea` (line 821-860), change the `onDoubleTap` handler. Currently line 824 has `if (!isLiked) { toggleLike(); }`. Change to just `toggleLike();` so double-tap always toggles:

```dart
onDoubleTap: () {
  toggleLike();
  setState(() => _showHeartAnimation = true);
  Future.delayed(const Duration(milliseconds: 800), () {
    if (mounted) setState(() => _showHeartAnimation = false);
  });
},
```

- [ ] **Step 2: Commit bug fix**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/moments/moment_card.dart
git commit -m "fix(moments): double-tap like now toggles regardless of current state"
```

---

## Task 2: Comment Count Sync Bug Fix

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/comments/create_comment.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/comments/comments_main.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/providers/provider_root/comments_providers.dart`

- [ ] **Step 1: Fix comment count after adding comment**

In `create_comment.dart`, after the comment is created (around line 83-86), the code invalidates `commentsProvider` and `momentsServiceProvider`. Change line 86 to also invalidate `momentsFeedProvider`:

```dart
ref.invalidate(commentsProvider(widget.id));
ref.invalidate(momentsFeedProvider);
```

Make sure `momentsFeedProvider` is imported from moments_providers.dart.

- [ ] **Step 2: Fix comment count after deleting comment**

In `comments_main.dart`, in the delete handler (around line 282-288), after calling `widget.onRefresh()`, also invalidate `momentsFeedProvider`:

```dart
widget.onRefresh();
ref.invalidate(momentsFeedProvider);
```

Add the import for `momentsFeedProvider` from moments_providers.dart if not already present.

- [ ] **Step 3: Commit comment count fix**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/comments/create_comment.dart lib/pages/comments/comments_main.dart
git commit -m "fix(comments): sync comment count with moments feed after add/delete"
```

---

## Task 3: Moment Card — Visual Polish

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/moment_card.dart`

- [ ] **Step 1: Update spacing — consistent 16px padding**

Find all `EdgeInsets.fromLTRB(8, 4, 8, 12)` and `EdgeInsets.fromLTRB(12, ...)` padding values in the card's build method and update to use 16px horizontal:

- Action bar padding (line 712): change `EdgeInsets.fromLTRB(8, 4, 8, 12)` to `EdgeInsets.fromLTRB(16, 4, 16, 8)`
- User header padding: ensure 16px left/right
- Content/caption padding: ensure 16px left/right

- [ ] **Step 2: Replace bottom divider with spacing**

Remove the bottom divider (line 779-780):
```dart
// Remove: Container(height: 1, color: context.dividerColor),
```

The parent list should use 8px spacing between cards instead. If the parent `ListView` uses `itemBuilder`, add `SizedBox(height: 8)` between items or use padding on the card.

- [ ] **Step 3: Update typography and avatar**

- Username: change from `context.labelLarge` to `context.titleSmall` wherever the username is displayed in the card header
- Avatar: change radius from 22 to 24 in the card header's `CircleAvatar`

- [ ] **Step 4: Update action icon sizes**

In `_buildActionButton` (line 862-890), change icon size from 20 to 22:
```dart
Icon(icon, size: 22, color: color),
```

Also update the standalone `IconButton` widgets for translate, gift, and share (lines 739-773) — change `size: 20` to `size: 22`.

- [ ] **Step 5: Add engagement text below action bar**

After the action bar `Padding` widget (after line 777), add engagement text:

```dart
// Engagement counts
if (likeCount > 0 || widget.moments.commentCount > 0)
  Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (likeCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              AppLocalizations.of(context)!.likedByXPeople(likeCount),
              style: context.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        if (widget.moments.commentCount > 0)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (context) => SingleMoment(moment: widget.moments),
                ),
              );
            },
            child: Text(
              widget.moments.commentCount == 1
                  ? AppLocalizations.of(context)!.oneComment
                  : AppLocalizations.of(context)!.xComments(widget.moments.commentCount),
              style: context.bodySmall.copyWith(color: context.textMuted),
            ),
          ),
      ],
    ),
  ),
```

- [ ] **Step 6: Commit visual polish**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/moments/moment_card.dart
git commit -m "feat(moments): polish card spacing, typography, icons, add engagement text"
```

---

## Task 4: Comments — Bug Fix + Bubble Modernization

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/comments/comments_main.dart`

- [ ] **Step 1: Modernize comment bubble styling**

Find the comment bubble `Container` decoration (around lines 391-400). Update:

```dart
decoration: BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerLow,
  borderRadius: BorderRadius.circular(16),
),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
```

Change from the mixed `BorderRadius.only(topRight: 16, bottomLeft: 16, bottomRight: 16)` to uniform `BorderRadius.circular(16)`.
Change background from `surfaceContainerHighest.withOpacity(0.5)` to `surfaceContainerLow`.

- [ ] **Step 2: Remove dividers, add spacing**

Replace the `Divider` between comments (line 558) with a `SizedBox(height: 12)`.

- [ ] **Step 3: Improve thread line**

In the reply thread line (lines 971-977), change width from 2 to 1:

```dart
Container(
  width: 1,
  color: Theme.of(context).colorScheme.outlineVariant,
  // ... rest stays the same
)
```

- [ ] **Step 4: Commit comment modernization**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/comments/comments_main.dart
git commit -m "feat(comments): modernize bubble style, remove dividers, thinner thread lines"
```

---

## Task 5: Stories Bar — Gradient Rings, Dots, Labels

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/stories/stories_feed_widget.dart`

- [ ] **Step 1: Increase stories bar height**

Change the default height from 100 to 120 (line 28):
```dart
this.height = 120,
```

- [ ] **Step 2: Add story count dots below avatars**

After each story avatar, add a row of dots. Create a helper widget:

```dart
Widget _buildStoryDots(int totalStories, int viewedStories) {
  final dotCount = totalStories.clamp(0, 5);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(dotCount, (i) {
      final isViewed = i < viewedStories;
      return Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isViewed
              ? Colors.grey
              : Theme.of(context).colorScheme.primary,
          border: isViewed
              ? null
              : Border.all(color: Theme.of(context).colorScheme.primary, width: 0.5),
        ),
      );
    }),
  );
}
```

Add this below each avatar in the story items (both user's own stories and other users' stories).

- [ ] **Step 3: Ensure gradient ring differentiates seen vs unseen**

The `StoryGradientRing` already exists (lines 323-328 and 433-439). Verify it uses a colorful gradient for unseen stories and a gray ring for seen stories. If not, update the gradient colors:
- Unseen: `[Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)]` (Instagram-style)
- Seen: `[Colors.grey, Colors.grey]`

Determine seen/unseen by checking if the current user's ID is in any of the story's `views` array.

- [ ] **Step 4: Ensure username labels are truncated properly**

Username labels already exist (lines 461-469). Ensure they use max 8 chars with ellipsis:
```dart
Text(
  userName.length > 8 ? '${userName.substring(0, 8)}...' : userName,
  style: context.captionSmall.copyWith(color: context.textMuted),
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
)
```

- [ ] **Step 5: Commit stories bar changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/stories/stories_feed_widget.dart
git commit -m "feat(stories): gradient rings, count dots, height increase, username truncation"
```

---

## Task 6: Story Viewer — Polish + Viewers List

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/stories/story_viewer_screen.dart`

- [ ] **Step 1: Add "Seen by X" bar for own stories**

For the story owner, add a tappable bar at the bottom showing "Seen by X" with an eye icon. When tapped, show a bottom sheet with the viewers list.

The backend endpoint `GET /api/v1/stories/:id/views` already exists (controllers/stories.js line 327-358). Use it to fetch viewer data.

```dart
Widget _buildSeenByBar(Story story) {
  return GestureDetector(
    onTap: () => _showViewersList(story),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.seenByX(story.viewCount),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_up, color: Colors.white),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Implement viewers list bottom sheet**

```dart
void _showViewersList(Story story) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ViewersListSheet(storyId: story.id),
  );
}
```

Create a `_ViewersListSheet` stateful widget that:
- Fetches viewers from the story API service
- Shows a header with total view count
- Lists each viewer with avatar, name, and time viewed (sorted most recent first)

- [ ] **Step 3: Commit story viewer changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/stories/story_viewer_screen.dart
git commit -m "feat(stories): add seen-by bar and viewers list bottom sheet"
```

---

## Task 7: Story Reactions via Chat — Backend

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/models/Message.js`

- [ ] **Step 1: Add storyReference field to Message schema**

In `models/Message.js`, add after the `replyTo` field:

```js
storyReference: {
  storyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Story',
    default: null
  },
  thumbnail: {
    type: String,
    default: null
  }
},
```

- [ ] **Step 2: Commit backend change**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add models/Message.js
git commit -m "feat(chat): add storyReference field for story reactions via chat"
```

---

## Task 8: Story Reactions via Chat — Flutter

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/stories/story_viewer_screen.dart`

- [ ] **Step 1: Update reaction bar with 6 emojis**

The story viewer already has a reaction bar (lines 773-815) with 4 emojis. Update to 6 emojis:

```dart
final reactions = ['❤️', '🔥', '😂', '😢', '😮', '👏'];
```

- [ ] **Step 2: Wire reactions to send chat messages**

When a user taps a reaction emoji or submits text, send it as a chat message to the story owner with `storyReference` data:

```dart
void _sendStoryReaction(String emoji, Story story) async {
  try {
    await chatService.sendMessage(
      receiverId: story.user.id,
      message: emoji,
      storyReference: {
        'storyId': story.id,
        'thumbnail': story.mediaUrl ?? story.thumbnail ?? '',
      },
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.repliedToYourStory),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    debugPrint('Story reaction error: $e');
  }
}
```

Update the chat service's `sendMessage` method to accept an optional `storyReference` parameter and include it in the request body.

- [ ] **Step 3: Commit story reactions**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/stories/story_viewer_screen.dart
git commit -m "feat(stories): story reactions via chat with 6 emoji presets"
```

---

## Task 9: Localization — Add New Strings

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/l10n/app_en.arb`
- Modify: All 17 other `app_*.arb` files

- [ ] **Step 1: Add English strings to app_en.arb**

Add before the closing `}`:

```json
"likedByXPeople": "Liked by {count} people",
"@likedByXPeople": { "placeholders": { "count": { "type": "int" } } },
"xComments": "{count} comments",
"@xComments": { "placeholders": { "count": { "type": "int" } } },
"oneComment": "1 comment",
"addAComment": "Add a comment...",
"viewXReplies": "View {count} replies",
"@viewXReplies": { "placeholders": { "count": { "type": "int" } } },
"hideReplies": "Hide replies",
"edited": "(edited)",
"yourStory": "Your Story",
"seenByX": "Seen by {count}",
"@seenByX": { "placeholders": { "count": { "type": "int" } } },
"sendMessage": "Send message...",
"repliedToYourStory": "Replied to your story"
```

Check which of these already exist in the ARB file to avoid duplicates.

- [ ] **Step 2: Add translations to all 17 other ARB files**

Add translated versions of each new key to all non-English ARB files (ar, de, es, fr, hi, id, it, ja, ko, pt, ru, th, tl, tr, vi, zh, zh_TW).

- [ ] **Step 3: Regenerate localization files**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter gen-l10n
```

- [ ] **Step 4: Commit localization**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/l10n/
git commit -m "feat(l10n): add localization strings for engagement text, comments, stories"
```

---

## Task 10: Verify — Analyze and Build

- [ ] **Step 1: Run Flutter analyzer**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze 2>&1 | grep -E "^   (error|warning)"
```

Expected: no errors or warnings from our changes.

- [ ] **Step 2: Verify backend schema loads**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node -e "const Message = require('./models/Message'); console.log('storyReference exists:', !!Message.schema.paths['storyReference.storyId']); console.log('Schema OK');"
```

- [ ] **Step 3: Fix any errors found and commit**

```bash
git add -A
git commit -m "fix: resolve build errors from modernization"
```
