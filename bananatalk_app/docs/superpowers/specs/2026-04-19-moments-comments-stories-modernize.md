# Moments, Comments & Stories — Bug Fixes + UI Modernization

**Date:** 2026-04-19
**Status:** Approved
**Scope:** Backend (language_exchange_backend_application) + Flutter (bananatalk_app)
**Sub-project:** 1 of 3 (this covers bugs + UI polish; sub-project 2 = comment enhancements, sub-project 3 = story enhancements)

---

## Overview

Fix critical bugs in likes and comment counts, modernize the visual design of moment cards, comments section, and stories bar/viewer. Add engagement text below moment action bars, story viewer list, and story reactions via chat. Localize all hardcoded strings.

---

## 1. Moment Card — Bug Fixes + Polish

### 1.1 Bug Fixes

**Double-tap like toggle (moment_card.dart ~line 823):**
- Current: `if (!isLiked) toggleLike();` — only likes if not already liked, does nothing on already-liked posts
- Fix: Change to `toggleLike();` — double-tap always toggles state. Heart animation always plays regardless.

**Comment count staleness:**
- Current: After adding/deleting a comment in single_moment view, the moment card in the feed still shows old commentCount
- Fix: When returning from single_moment/comment screens, invalidate `momentsFeedProvider` so the card refreshes with the updated count
- Also invalidate after `createComment()` and `deleteComment()` operations in comments_providers.dart

### 1.2 Visual Polish

**Spacing:**
- Increase horizontal padding to 16px consistently throughout the card (currently 12px in some spots, 8px in others)
- Replace hard 1px dividers between cards with 8px vertical spacing (cleaner separation)

**Typography:**
- Username: use `titleSmall` instead of `labelLarge` for slightly more visual weight
- Timestamp: lighter color, use `context.textMuted` consistently

**Avatar:**
- Increase from 22px radius to 24px radius for better visual weight

**Action icons:**
- Increase icon size from 20px to 22px
- Ensure minimum 44px tap target on all action buttons

**Like animation:**
- Smoother scale curve on the heart overlay (already implemented, just tune the curve)

### 1.3 Engagement Counts (Instagram-style)

Add below the action bar:
- **Like text:** "Liked by X people" when likeCount > 0, tappable
- **Comment text:** "X comments" when commentCount > 0, tappable (navigates to single_moment)
- Typography: `bodySmall` with `fontWeight.w600` for counts, `bodySmall` regular for labels
- Padding: 0px top, 8px horizontal, 4px bottom

---

## 2. Comments Section — Bug Fixes + Modernization

### 2.1 Bug Fixes

**Comment count not updating after add:**
- In create_comment.dart, after creating a comment: invalidate `momentsFeedProvider` (not just `momentsServiceProvider`) so the parent moment card refreshes its commentCount

**Comment count not decrementing after delete:**
- In comments_main.dart, after deleting a comment: invalidate `momentsFeedProvider` so the card count updates

**Reply count consistency:**
- Validate that `replyCount` displayed matches actual replies loaded

### 2.2 Bubble Modernization

**Bubble style:**
- Softer border radius: 16px on all corners (currently mixed: topRight 16px, bottomLeft/Right 16px)
- Lighter background: use `surfaceContainerLow` instead of `surfaceContainerHighest.withOpacity(0.5)`
- Remove hard dividers between comments, use 12px vertical spacing instead

**Author & timestamp:**
- Author name: `labelLarge` with `fontWeight.w700`, inline
- Timestamp: relative time ("2m", "1h", "3d") in muted color, right-aligned from name
- Edited tag: small "(edited)" in muted color after timestamp

### 2.3 Threaded Replies

- Indentation: 40px for replies (consistent)
- Thread line: 1px width (currently 2px), rounded ends, muted color
- Collapse/expand: smooth 300ms slide animation
- Toggle text: "View X replies" / "Hide replies" with chevron icon that rotates on toggle

### 2.4 Comment Input Bar

- Sticky at bottom of single_moment view
- Avatar on left side of input field
- Rounded input field with placeholder "Add a comment..."
- Send button: accent colored (Color(0xFF00BFA5)), only visible when text is not empty
- Smooth appear/disappear animation on send button

---

## 3. Stories Bar + Viewer — Polish + Features

### 3.1 Stories Bar (top of moments feed)

**Gradient ring for unseen stories:**
- Unseen: colorful gradient ring (pink → orange → yellow) around avatar
- Seen: gray ring around avatar
- Determine seen/unseen based on whether current user's ID is in the story's `views` array

**Story count dots:**
- Small dots (4px diameter) below each avatar
- Number of dots = number of active stories (max 5 visible)
- Filled dots for viewed stories, hollow for unviewed

**Username labels:**
- Add truncated username below each avatar (max 8 chars + ellipsis)
- `captionSmall` size, muted color

**"Add story" button:**
- Camera icon with "+" badge overlay
- "Your Story" label below
- If user already has active stories, show their avatar with a "+" badge instead

**Overall height:**
- Increase from 100px to ~120px to accommodate labels and dots

### 3.2 Story Viewer Polish

**Progress bars:**
- Thin segmented progress bars at top (one segment per story in the group)
- Smooth fill animation matching auto-advance duration
- Pause on hold, resume on release

**Timestamps:**
- Show "Xh ago" in the header next to username

**View count:**
- Show eye icon + view count at bottom of own stories

**Navigation:**
- Left/right tap zones on screen to go prev/next
- Swipe left/right between different users' story groups
- Swipe down to dismiss

### 3.3 Story Viewers List

- Only visible to the story owner
- Swipe up on own story or tap "Seen by X" bar at bottom
- Bottom sheet with scrollable list: avatar, name, time viewed
- Sorted by most recent viewer first
- Show total view count in header

### 3.4 Story Reactions via Chat (Instagram-style)

**Reaction row (on other users' stories):**
- Show row of 6 quick-reaction emojis at bottom: ❤️ 🔥 😂 😢 😮 👏
- Also show a text input field: "Send message..."

**Sending a reaction:**
- Tapping an emoji or submitting text sends it as a **chat message** to the story owner
- The message includes a `storyReference` with the story ID and thumbnail URL
- The chat UI renders this as "Replied to your story" with a small story preview thumbnail above the message text/emoji

**Backend changes:**
- Add optional `storyReference` field to the chat/message model: `{ storyId: String, thumbnail: String }`
- No new story reaction model needed — reactions flow through existing chat system

---

## 4. Localization

### 4.1 Strings to Audit and Add

Audit these files for hardcoded strings and add missing ones to all 18 ARB files:
- `moment_card.dart` — engagement text ("Liked by X people", "X comments")
- `comments_main.dart` — "View X replies", "Hide replies", "(edited)"
- `create_comment.dart` — "Add a comment..."
- `stories_feed_widget.dart` — "Your Story"
- `story_viewer_screen.dart` — "Seen by X", "Xh ago", reaction labels
- `single_moment.dart` — any remaining hardcoded strings

### 4.2 New Localization Keys Needed

**Moments:**
- `likedByXPeople` — "Liked by {count} people" (with plural handling)
- `xComments` — "{count} comments"
- `oneComment` — "1 comment"

**Comments:**
- `addAComment` — "Add a comment..."
- `viewXReplies` — "View {count} replies"
- `hideReplies` — "Hide replies"
- `edited` — "(edited)"

**Stories:**
- `yourStory` — "Your Story"
- `seenByX` — "Seen by {count}"
- `xHoursAgo` — "{count}h ago"
- `xMinutesAgo` — "{count}m ago"
- `sendMessage` — "Send message..."
- `repliedToYourStory` — "Replied to your story"

---

## 5. Files to Modify

### Backend (language_exchange_backend_application)
| File | Changes |
|------|---------|
| `models/Message.js` (or chat model) | Add optional `storyReference` field |
| `controllers/stories.js` | Add endpoint to get viewer list with populated user details |

### Flutter (bananatalk_app)
| File | Changes |
|------|---------|
| `lib/pages/moments/moment_card.dart` | Fix double-tap bug, polish spacing/typography/icons, add engagement text |
| `lib/pages/moments/single_moment.dart` | Invalidate feed on return, polish |
| `lib/pages/comments/comments_main.dart` | Fix count sync, modernize bubbles, improve threading |
| `lib/pages/comments/create_comment.dart` | Fix count invalidation, modernize input bar |
| `lib/providers/provider_root/comments_providers.dart` | Invalidate momentsFeedProvider after comment ops |
| `lib/pages/stories/stories_feed_widget.dart` | Gradient rings, count dots, username labels, height increase |
| `lib/pages/stories/story_viewer_screen.dart` | Progress bars, timestamps, viewer list, reaction row |
| `lib/l10n/app_en.arb` | Add ~15 new strings |
| `lib/l10n/app_*.arb` (17 files) | Add translated versions |

---

## 6. Summary of Key Decisions

1. **Fix double-tap like** — always toggle, always animate
2. **Fix comment count sync** — invalidate momentsFeedProvider after comment add/delete
3. **Polish, don't redesign** — same card structure, improved spacing/typography/icons
4. **Engagement text** — Instagram-style "Liked by X people" and "X comments" below actions
5. **Comment bubbles** — softer, lighter, no dividers, better threading
6. **Stories gradient ring** — unseen = colorful gradient, seen = gray
7. **Story count dots + username labels** — under each avatar
8. **Story viewers list** — swipe up on own story, bottom sheet with viewer details
9. **Story reactions via chat** — emoji/text reactions sent as chat messages with story preview, no new models
10. **Localize everything** — ~15 new strings across 18 languages
