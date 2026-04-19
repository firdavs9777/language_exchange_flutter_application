# Comment Enhancements — Reactions, @Mentions, Rich Input

**Date:** 2026-04-19
**Status:** Approved
**Scope:** Backend (language_exchange_backend_application) + Flutter (bananatalk_app)
**Sub-project:** 2 of 3

---

## Overview

Replace the single like button on comments with emoji reactions (any emoji), add @mention support with autocomplete and notifications, add GIF picker (reusing existing chat GIF infrastructure) and image attachments in comments, and add missing notifications for replies, reactions, and mentions.

---

## 1. Comment Reactions

### 1.1 Backend — Comment Model Changes

Replace `likedUsers` array with `reactions` array in Comment schema:

```js
reactions: [{
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  emoji: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}],
reactionCount: {
  type: Number,
  default: 0
}
```

Keep `likedUsers` and `likeCount` temporarily for backward compatibility — new code uses `reactions`, old data stays.

### 1.2 Backend — New Endpoints

**POST /api/v1/moments/:momentId/comments/:commentId/react**
- Body: `{ emoji: "❤️" }`
- One reaction per user per comment — adding a new emoji replaces the old one
- If same emoji already exists from this user, remove it (toggle)
- Update `reactionCount`
- Send notification to comment author (if not self)

**DELETE /api/v1/moments/:momentId/comments/:commentId/react**
- Remove user's reaction from the comment
- Update `reactionCount`

### 1.3 Flutter UI — Reaction Chips

Below each comment bubble, show grouped reaction chips:
- Format: `❤️ 3  😂 2  🔥 1` — grouped by emoji, sorted by count descending
- Tapping a chip toggles your reaction for that emoji
- Your own reaction chip has accent border highlight
- If no reactions, show nothing (no empty state)

### 1.4 Flutter UI — Adding Reactions

- Replace the current like button with a "+" reaction button
- Tap: opens system emoji keyboard / emoji picker to select any emoji
- The selected emoji is sent via the react endpoint
- Optimistic UI update

---

## 2. @Mentions

### 2.1 Backend — Comment Model Changes

Add `mentions` array to Comment schema:

```js
mentions: [{
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  username: String,
  offset: Number,
  length: Number
}]
```

### 2.2 Backend — Mention Notifications

When a comment is created with mentions:
- For each mentioned user, send a push notification: "X mentioned you in a comment"
- Add `sendCommentMention(mentionedUserId, mentionerId, momentId, commentText)` to notificationService
- Skip if mentioning yourself
- Respect `notificationSettings.moments` preference
- Include moment ID for deep linking

### 2.3 Flutter UI — Input Autocomplete

- Typing `@` in the comment input triggers an autocomplete overlay above the input field
- Shows users the current user follows, filtered by characters typed after `@`
- Reuse existing user search service from chat
- Tapping a user inserts `@username` and stores mention metadata
- `@username` text in the input field styled with accent color (Color(0xFF00BFA5))

### 2.4 Flutter UI — Display

- In rendered comments, `@username` text is bold + accent color
- Tapping a mention navigates to that user's profile (SingleCommunity screen)
- Parse mentions from the `mentions` array using offset/length to style the text

---

## 3. Rich Comment Input (GIF + Image)

### 3.1 GIF Picker

- Reuse existing `lib/pages/chat/gif_picker_panel.dart` and `lib/services/giphy_service.dart`
- Add GIF button to comment input bar
- Tapping opens GIF picker as bottom sheet
- Selecting a GIF stores the Giphy URL in the comment's `imageUrl` field
- GIF displays inline in the comment bubble, auto-plays

### 3.2 Image Attachment

- Add camera/gallery button to comment input bar
- Selected image uploaded to DigitalOcean Spaces (same pattern as moment photo upload)
- CDN URL stored in comment's `imageUrl` field
- Image displays inline in comment bubble, max 200px height, rounded corners
- Tap image to open full-screen ImageViewer (reuse existing)
- Users can send text + image together, or image/GIF only

### 3.3 Backend — Image Upload

- Add endpoint: `PUT /api/v1/moments/:momentId/comments/:commentId/image`
- Uses same multer-s3 upload middleware as moment photos
- Stores URL in comment's `imageUrl` field
- Max size: 10MB

### 3.4 Comment Input Bar Layout

```
[Avatar] [Text field...............] [📷] [GIF] [➤ Send]
```

- 📷 opens image picker (gallery/camera choice)
- GIF opens GIF picker panel
- Send button: accent colored, visible when text is not empty OR image/GIF is selected
- When image is selected, show small preview thumbnail above the input bar with an X to remove

---

## 4. Notifications — New Types

### 4.1 Comment Reply Notification

- When someone replies to your comment (parentComment is set), notify the parent comment author
- "X replied to your comment"
- Add `sendCommentReply(parentCommentAuthorId, replierId, momentId, replyText)` to notificationService
- Wire in comments controller when parentComment is provided

### 4.2 Comment Reaction Notification

- When someone reacts to your comment, notify the comment author
- "X reacted to your comment"
- Add `sendCommentReaction(commentAuthorId, reactorId, momentId, emoji)` to notificationService
- Wire in the new react endpoint

### 4.3 @Mention Notification

- "X mentioned you in a comment"
- `sendCommentMention(mentionedUserId, mentionerId, momentId, commentText)`
- Wire in comments controller when mentions array is non-empty

### 4.4 All Notifications Must

- Not fire for self-actions
- Respect user's `notificationSettings.moments` preference
- Include moment ID for deep linking to the moment/comment

---

## 5. Localization

New strings for all 18 ARB files:

- `mentionedYouInComment` — "{name} mentioned you in a comment"
- `repliedToYourComment` — "{name} replied to your comment"
- `reactedToYourComment` — "{name} reacted to your comment"
- `searchUsers` — "Search users..."
- `noGifsFound` — "No GIFs found"
- `addReaction` — "Add reaction"
- `removeReaction` — "Remove reaction"
- `attachImage` — "Attach image"
- `pickGif` — "Pick a GIF"

---

## 6. Files to Modify

### Backend (language_exchange_backend_application)
| File | Changes |
|------|---------|
| `models/Comment.js` | Add `reactions` array, `mentions` array, keep `likedUsers` for compat |
| `controllers/comments.js` | Add react/unreact endpoints, mention handling, image upload |
| `routes/moments.js` | Add new comment routes (react, image upload) |
| `services/notificationService.js` | Add `sendCommentReply`, `sendCommentReaction`, `sendCommentMention` |

### Flutter (bananatalk_app)
| File | Changes |
|------|---------|
| `lib/providers/provider_models/moments_model.dart` | Update Comment model with reactions, mentions |
| `lib/pages/comments/comments_main.dart` | Reaction chips below bubbles, mention display styling, inline images |
| `lib/pages/comments/create_comment.dart` | @mention autocomplete, GIF button, image button, updated input bar |
| `lib/services/moments_service.dart` | Add react/unreact API calls, comment image upload |
| `lib/l10n/app_en.arb` | Add ~9 new strings |
| `lib/l10n/app_*.arb` (17 files) | Add translated versions |

---

## 7. Summary of Key Decisions

1. **Any emoji as reaction** — Slack/Discord-style, not limited preset
2. **One reaction per user per comment** — adding new replaces old, same emoji toggles off
3. **Reaction chips below bubble** — grouped by emoji with counts, tappable to toggle
4. **@mentions with autocomplete** — shows followed users, accent styled, tappable to profile
5. **Reuse chat GIF picker** — gif_picker_panel.dart + giphy_service.dart
6. **Inline images in bubbles** — max 200px height, tap to expand
7. **3 new notification types** — reply, reaction, mention — all respect settings
8. **Keep likedUsers for compat** — new code uses reactions, old data stays
