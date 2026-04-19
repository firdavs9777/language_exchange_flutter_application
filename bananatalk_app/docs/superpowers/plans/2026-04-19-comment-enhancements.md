# Comment Enhancements Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add emoji reactions, @mentions with autocomplete, GIF picker, image attachments, and missing notifications to the comments system.

**Architecture:** Backend-first (schema + endpoints), then Flutter model updates, then UI changes. Backend changes: Comment model gets `reactions` and `mentions` arrays, new react/unreact endpoints, 3 new notification types. Flutter: update Comment model, add reaction chips to bubbles, @mention autocomplete in input, reuse chat GIF picker, add image attachment support.

**Tech Stack:** Node.js/Express + MongoDB (backend), Flutter + Riverpod (frontend), Giphy API (GIF picker, already integrated)

**Spec:** `docs/superpowers/specs/2026-04-19-comment-enhancements.md`

---

## Task 1: Backend — Comment Model Updates

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/models/Comment.js`

- [ ] **Step 1: Add reactions array to Comment schema**

After the `likeCount` field (line 44), add:

```js
// Emoji reactions (replaces simple likes for new comments)
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
},
```

- [ ] **Step 2: Add mentions array to Comment schema**

After the new `reactionCount` field, add:

```js
// @Mentions
mentions: [{
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  username: String,
  offset: Number,
  length: Number
}],
```

- [ ] **Step 3: Commit model changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add models/Comment.js
git commit -m "feat(comments): add reactions and mentions arrays to Comment schema"
```

---

## Task 2: Backend — React/Unreact Endpoints

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/comments.js`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/routes/comment.js`

- [ ] **Step 1: Add reactToComment controller**

Add after the `likeComment` function (after line 306) in controllers/comments.js:

```js
// @desc    React to a comment with emoji
// @route   POST /api/v1/moments/:momentId/comments/:id/react
// @access  Private
exports.reactToComment = asyncHandler(async (req, res, next) => {
    const commentId = req.params.id || req.params.commentId;
    const userId = req.user._id;
    const { emoji } = req.body;

    if (!emoji) {
        return next(new ErrorResponse('Emoji is required', 400));
    }

    const comment = await Comment.findById(commentId);
    if (!comment) {
        return next(new ErrorResponse('Comment not found', 404));
    }

    // Initialize reactions array if needed
    if (!comment.reactions) comment.reactions = [];

    // Check if user already reacted
    const existingIndex = comment.reactions.findIndex(
        r => r.user.toString() === userId.toString()
    );

    if (existingIndex !== -1) {
        if (comment.reactions[existingIndex].emoji === emoji) {
            // Same emoji — toggle off (remove)
            comment.reactions.splice(existingIndex, 1);
        } else {
            // Different emoji — replace
            comment.reactions[existingIndex].emoji = emoji;
            comment.reactions[existingIndex].createdAt = new Date();
        }
    } else {
        // New reaction
        comment.reactions.push({ user: userId, emoji, createdAt: new Date() });
    }

    comment.reactionCount = comment.reactions.length;
    await comment.save();

    // Send notification (if not self-reaction)
    const commentOwnerId = comment.user.toString();
    if (userId.toString() !== commentOwnerId) {
        const notificationService = require('../services/notificationService');
        if (notificationService.sendCommentReaction) {
            notificationService.sendCommentReaction(
                commentOwnerId, userId.toString(), comment.moment, emoji
            ).catch(err => console.error('Comment reaction notification failed:', err));
        }
    }

    res.status(200).json({
        success: true,
        data: {
            reactions: comment.reactions,
            reactionCount: comment.reactionCount
        }
    });
});

// @desc    Remove reaction from comment
// @route   DELETE /api/v1/moments/:momentId/comments/:id/react
// @access  Private
exports.unreactToComment = asyncHandler(async (req, res, next) => {
    const commentId = req.params.id || req.params.commentId;
    const userId = req.user._id;

    const comment = await Comment.findById(commentId);
    if (!comment) {
        return next(new ErrorResponse('Comment not found', 404));
    }

    if (!comment.reactions) comment.reactions = [];

    comment.reactions = comment.reactions.filter(
        r => r.user.toString() !== userId.toString()
    );
    comment.reactionCount = comment.reactions.length;
    await comment.save();

    res.status(200).json({
        success: true,
        data: {
            reactions: comment.reactions,
            reactionCount: comment.reactionCount
        }
    });
});
```

- [ ] **Step 2: Add routes for react/unreact**

In routes/comment.js, add the imports and routes. Update the destructured imports (line 4-8):

```js
const {
  getComments, getComment, createComment,
  updateComment, deleteComment,
  likeComment, getReplies,
  translateComment, getCommentTranslations,
  reactToComment, unreactToComment
} = require('../controllers/comments');
```

Add after the like route (line 27):

```js
// React/unreact to a comment
router.route('/:id/react')
  .post(protect, reactToComment)
  .delete(protect, unreactToComment);
```

- [ ] **Step 3: Commit endpoints**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/comments.js routes/comment.js
git commit -m "feat(comments): add react/unreact endpoints"
```

---

## Task 3: Backend — Notifications (Reply, Reaction, Mention)

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/services/notificationService.js`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/comments.js`

- [ ] **Step 1: Add 3 new notification functions to notificationService.js**

Find the exports at the bottom of notificationService.js and add these functions before the module.exports:

```js
/**
 * Send notification when someone replies to a comment
 */
const sendCommentReply = async (parentAuthorId, replierId, momentId, replyText) => {
  try {
    const replier = await User.findById(replierId);
    if (!replier) return { success: false, error: 'Replier not found' };

    const notification = {
      title: `${replier.name} replied to your comment`,
      body: replyText.length > 100 ? replyText.substring(0, 100) + '...' : replyText,
      data: { type: 'comment_reply', userId: replierId, momentId: momentId.toString() }
    };

    if (replier.images && replier.images.length > 0) {
      notification.imageUrl = replier.images[0];
    }

    return await send(parentAuthorId, 'comment_reply', notification);
  } catch (error) {
    console.error('Error sending comment reply notification:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send notification when someone reacts to a comment
 */
const sendCommentReaction = async (commentAuthorId, reactorId, momentId, emoji) => {
  try {
    const reactor = await User.findById(reactorId);
    if (!reactor) return { success: false, error: 'Reactor not found' };

    const notification = {
      title: `${reactor.name} reacted ${emoji} to your comment`,
      body: 'Tap to view',
      data: { type: 'comment_reaction', userId: reactorId, momentId: momentId.toString() }
    };

    if (reactor.images && reactor.images.length > 0) {
      notification.imageUrl = reactor.images[0];
    }

    return await send(commentAuthorId, 'comment_reaction', notification);
  } catch (error) {
    console.error('Error sending comment reaction notification:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send notification when someone mentions a user in a comment
 */
const sendCommentMention = async (mentionedUserId, mentionerId, momentId, commentText) => {
  try {
    const mentioner = await User.findById(mentionerId);
    if (!mentioner) return { success: false, error: 'Mentioner not found' };

    const notification = {
      title: `${mentioner.name} mentioned you in a comment`,
      body: commentText.length > 100 ? commentText.substring(0, 100) + '...' : commentText,
      data: { type: 'comment_mention', userId: mentionerId, momentId: momentId.toString() }
    };

    if (mentioner.images && mentioner.images.length > 0) {
      notification.imageUrl = mentioner.images[0];
    }

    return await send(mentionedUserId, 'comment_mention', notification);
  } catch (error) {
    console.error('Error sending comment mention notification:', error);
    return { success: false, error: error.message };
  }
};
```

Add to the module.exports: `sendCommentReply, sendCommentReaction, sendCommentMention`

- [ ] **Step 2: Wire reply notification in createComment**

In controllers/comments.js, in `createComment` (around line 180-207), after the reply count increment block, add:

```js
// Send notification to parent comment author (if replying)
if (req.body.parentComment) {
    const parentComment = await Comment.findById(req.body.parentComment);
    if (parentComment && parentComment.user.toString() !== req.user.id) {
        const notificationService = require('../services/notificationService');
        if (notificationService.sendCommentReply) {
            notificationService.sendCommentReply(
                parentComment.user.toString(),
                req.user.id,
                moment._id,
                comment.text
            ).catch(err => console.error('Reply notification failed:', err));
        }
    }
}
```

- [ ] **Step 3: Wire mention notifications in createComment**

After the reply notification block, add:

```js
// Send notifications to mentioned users
if (req.body.mentions && req.body.mentions.length > 0) {
    const notificationService = require('../services/notificationService');
    for (const mention of req.body.mentions) {
        if (mention.user && mention.user.toString() !== req.user.id) {
            if (notificationService.sendCommentMention) {
                notificationService.sendCommentMention(
                    mention.user.toString(),
                    req.user.id,
                    moment._id,
                    comment.text
                ).catch(err => console.error('Mention notification failed:', err));
            }
        }
    }
}
```

- [ ] **Step 4: Commit notifications**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add services/notificationService.js controllers/comments.js
git commit -m "feat(comments): add reply, reaction, and mention notifications"
```

---

## Task 4: Backend — Comment Image Upload Endpoint

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/comments.js`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/routes/comment.js`

- [ ] **Step 1: Add uploadCommentImage controller**

Add to controllers/comments.js:

```js
// @desc    Upload image to comment
// @route   PUT /api/v1/moments/:momentId/comments/:id/image
// @access  Private
exports.uploadCommentImage = asyncHandler(async (req, res, next) => {
    const commentId = req.params.id || req.params.commentId;
    const comment = await Comment.findById(commentId);

    if (!comment) {
        return next(new ErrorResponse('Comment not found', 404));
    }

    if (comment.user.toString() !== req.user._id.toString()) {
        return next(new ErrorResponse('Not authorized', 403));
    }

    if (!req.file) {
        return next(new ErrorResponse('Please upload an image', 400));
    }

    comment.imageUrl = req.file.location;
    await comment.save();

    res.status(200).json({
        success: true,
        data: { imageUrl: comment.imageUrl }
    });
});
```

- [ ] **Step 2: Add route**

In routes/comment.js, add after the react routes:

```js
// Upload image to comment
router.route('/:id/image')
  .put(protect, uploadSingleCompressed('image', 'bananatalk/comments'), exports.uploadCommentImage || require('../controllers/comments').uploadCommentImage);
```

Actually, since we already import `uploadSingleCompressed` at line 13, just add:

```js
const { uploadCommentImage } = require('../controllers/comments');
```

to the imports (update the destructure at lines 4-8), then:

```js
router.route('/:id/image').put(protect, uploadSingleCompressed('image', 'bananatalk/comments'), uploadCommentImage);
```

- [ ] **Step 3: Commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/comments.js routes/comment.js
git commit -m "feat(comments): add image upload endpoint for comments"
```

---

## Task 5: Flutter — Comment Model Updates

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/providers/provider_models/moments_model.dart`

- [ ] **Step 1: Add CommentReaction class**

Add before the `Comment` class:

```dart
/// Reaction on a comment
class CommentReaction {
  final String id;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  const CommentReaction({
    required this.id,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory CommentReaction.fromJson(Map<String, dynamic> json) {
    return CommentReaction(
      id: json['_id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Mention in a comment
class CommentMention {
  final String userId;
  final String username;
  final int offset;
  final int length;

  const CommentMention({
    required this.userId,
    required this.username,
    required this.offset,
    required this.length,
  });

  factory CommentMention.fromJson(Map<String, dynamic> json) {
    return CommentMention(
      userId: json['user']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      offset: json['offset'] is int ? json['offset'] : 0,
      length: json['length'] is int ? json['length'] : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': userId,
    'username': username,
    'offset': offset,
    'length': length,
  };
}
```

- [ ] **Step 2: Update Comment class with reactions, mentions, imageUrl**

Add to Comment constructor:
```dart
this.reactions = const [],
this.reactionCount = 0,
this.mentions = const [],
this.imageUrl,
```

Add field declarations:
```dart
final List<CommentReaction> reactions;
final int reactionCount;
final List<CommentMention> mentions;
final String? imageUrl;
```

Update `fromJson`:
```dart
reactions: json['reactions'] != null && json['reactions'] is List
    ? (json['reactions'] as List)
        .where((r) => r != null && r is Map<String, dynamic>)
        .map((r) => CommentReaction.fromJson(r))
        .toList()
    : [],
reactionCount: json['reactionCount'] is int ? json['reactionCount'] : 0,
mentions: json['mentions'] != null && json['mentions'] is List
    ? (json['mentions'] as List)
        .where((m) => m != null && m is Map<String, dynamic>)
        .map((m) => CommentMention.fromJson(m))
        .toList()
    : [],
imageUrl: json['imageUrl']?.toString(),
```

- [ ] **Step 3: Commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/providers/provider_models/moments_model.dart
git commit -m "feat(comments): add CommentReaction, CommentMention classes, update Comment model"
```

---

## Task 6: Flutter — Reaction Chips UI in Comment Bubbles

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/comments/comments_main.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/services/moments_service.dart`

- [ ] **Step 1: Add react API call to moments_service.dart**

Add to the MomentsService class:

```dart
static Future<Map<String, dynamic>> reactToComment({
  required String momentId,
  required String commentId,
  required String emoji,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final response = await http.post(
    Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/comments/$commentId/react'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'emoji': emoji}),
  );
  return jsonDecode(response.body);
}
```

- [ ] **Step 2: Add reaction chips below comment bubble**

In comments_main.dart, find the comment bubble Container and add below it (after the bubble's closing parenthesis, still inside the comment item's Column):

```dart
// Reaction chips
if (widget.comment.reactions.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 4, left: 4),
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: _groupReactions(widget.comment.reactions).entries.map((entry) {
        final isMyReaction = widget.comment.reactions.any(
          (r) => r.emoji == entry.key && r.userId == widget.currentUserId,
        );
        return GestureDetector(
          onTap: () => _reactToComment(entry.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isMyReaction
                  ? const Color(0xFF00BFA5).withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: isMyReaction
                  ? Border.all(color: const Color(0xFF00BFA5), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text('${entry.value}', style: context.captionSmall),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  ),
```

Add helper methods:

```dart
Map<String, int> _groupReactions(List<CommentReaction> reactions) {
  final map = <String, int>{};
  for (final r in reactions) {
    map[r.emoji] = (map[r.emoji] ?? 0) + 1;
  }
  // Sort by count descending
  final sorted = Map.fromEntries(
    map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
  return sorted;
}

Future<void> _reactToComment(String emoji) async {
  try {
    await api.MomentsService.reactToComment(
      momentId: widget.momentId,
      commentId: widget.comment.id,
      emoji: emoji,
    );
    widget.onRefresh();
  } catch (e) {
    debugPrint('React error: $e');
  }
}
```

- [ ] **Step 3: Replace like button with "+" reaction button**

Find the existing like action button for comments and replace it with a "+" button that opens the emoji keyboard:

```dart
GestureDetector(
  onTap: () => _showEmojiPicker(),
  child: Icon(Icons.add_reaction_outlined, size: 16, color: context.textMuted),
),
```

Add the emoji picker method — use `showModalBottomSheet` with a simple emoji grid or the system emoji input.

- [ ] **Step 4: Commit reaction chips UI**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/comments/comments_main.dart lib/services/moments_service.dart
git commit -m "feat(comments): add emoji reaction chips below comment bubbles"
```

---

## Task 7: Flutter — @Mention Autocomplete in Input

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/comments/create_comment.dart`

- [ ] **Step 1: Add mention tracking state**

Add state variables to `_CreateCommentState`:

```dart
List<CommentMention> _mentions = [];
bool _showMentionOverlay = false;
String _mentionQuery = '';
List<dynamic> _mentionSuggestions = [];
```

- [ ] **Step 2: Add text change listener for @ detection**

In initState or the TextField's onChanged, detect `@` patterns:

```dart
void _onTextChanged(String text) {
  final cursorPos = commentController.selection.baseOffset;
  if (cursorPos <= 0) {
    setState(() => _showMentionOverlay = false);
    return;
  }

  // Find @ before cursor
  final textBefore = text.substring(0, cursorPos);
  final atIndex = textBefore.lastIndexOf('@');

  if (atIndex >= 0) {
    final query = textBefore.substring(atIndex + 1);
    if (!query.contains(' ') && query.length <= 20) {
      setState(() {
        _showMentionOverlay = true;
        _mentionQuery = query;
      });
      _searchUsers(query);
      return;
    }
  }
  setState(() => _showMentionOverlay = false);
}
```

- [ ] **Step 3: Add user search and autocomplete overlay**

Add search method that calls the user search endpoint:

```dart
Future<void> _searchUsers(String query) async {
  // Reuse existing user/community search service
  // Filter to users the current user follows
  // Update _mentionSuggestions
}
```

Build an overlay above the input showing matching users:

```dart
Widget _buildMentionOverlay() {
  if (!_showMentionOverlay || _mentionSuggestions.isEmpty) {
    return const SizedBox.shrink();
  }
  return Container(
    constraints: const BoxConstraints(maxHeight: 200),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
    ),
    child: ListView.builder(
      shrinkWrap: true,
      itemCount: _mentionSuggestions.length,
      itemBuilder: (context, index) {
        final user = _mentionSuggestions[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(radius: 16),
          title: Text(user.name),
          onTap: () => _insertMention(user),
        );
      },
    ),
  );
}
```

- [ ] **Step 4: Insert mention into text and track metadata**

```dart
void _insertMention(dynamic user) {
  final text = commentController.text;
  final cursorPos = commentController.selection.baseOffset;
  final textBefore = text.substring(0, cursorPos);
  final atIndex = textBefore.lastIndexOf('@');

  final mentionText = '@${user.name} ';
  final newText = text.replaceRange(atIndex, cursorPos, mentionText);

  _mentions.add(CommentMention(
    userId: user.id,
    username: user.name,
    offset: atIndex,
    length: mentionText.trim().length,
  ));

  commentController.text = newText;
  commentController.selection = TextSelection.collapsed(
    offset: atIndex + mentionText.length,
  );
  setState(() => _showMentionOverlay = false);
}
```

- [ ] **Step 5: Send mentions with comment creation**

Update the `submitComment` method to include mentions in the API call body.

- [ ] **Step 6: Commit @mentions**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/comments/create_comment.dart
git commit -m "feat(comments): add @mention autocomplete with user search"
```

---

## Task 8: Flutter — GIF Picker + Image Attachment in Comments

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/comments/create_comment.dart`

- [ ] **Step 1: Add GIF and image buttons to input bar**

Update the input bar layout to include camera and GIF buttons:

```dart
// Input bar layout: [Avatar] [TextField] [📷] [GIF] [Send]
Row(
  children: [
    // Avatar
    // TextField (expanded)
    // Camera button
    IconButton(
      icon: Icon(Icons.camera_alt_outlined, size: 20, color: context.textMuted),
      onPressed: _pickImage,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    ),
    // GIF button
    IconButton(
      icon: Icon(Icons.gif_box_outlined, size: 20, color: context.textMuted),
      onPressed: _openGifPicker,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    ),
    // Send button (visible when text/image/gif selected)
  ],
)
```

- [ ] **Step 2: Add image picker integration**

```dart
File? _selectedImage;

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
  if (picked != null) {
    setState(() => _selectedImage = File(picked.path));
  }
}
```

Show a preview thumbnail above the input when an image is selected, with an X button to remove.

- [ ] **Step 3: Add GIF picker integration**

Import and reuse the existing `GifPickerPanel` from chat:

```dart
import 'package:bananatalk_app/pages/chat/gif_picker_panel.dart';

void _openGifPicker() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: GifPickerPanel(
        onGifSelected: (gif) {
          Navigator.pop(context);
          _submitGif(gif.url);
        },
      ),
    ),
  );
}
```

- [ ] **Step 4: Handle image upload after comment creation**

After creating the comment, if `_selectedImage` is not null, upload it:

```dart
if (_selectedImage != null) {
  await momentsService.uploadCommentImage(
    momentId: widget.id,
    commentId: newComment.id,
    imageFile: _selectedImage!,
  );
}
```

For GIFs, include the GIF URL directly in the comment creation body as `imageUrl`.

- [ ] **Step 5: Commit GIF + image**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/comments/create_comment.dart
git commit -m "feat(comments): add GIF picker and image attachment to comment input"
```

---

## Task 9: Flutter — Display Mentions + Images in Comment Bubbles

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/comments/comments_main.dart`

- [ ] **Step 1: Render @mentions as styled text**

Replace the plain `Text(comment.text)` in the comment bubble with a `RichText` that styles mentions:

```dart
Widget _buildCommentText(Comment comment) {
  if (comment.mentions.isEmpty) {
    return Text(comment.text, style: context.bodyMedium);
  }

  final spans = <TextSpan>[];
  int lastEnd = 0;

  // Sort mentions by offset
  final sortedMentions = List<CommentMention>.from(comment.mentions)
    ..sort((a, b) => a.offset.compareTo(b.offset));

  for (final mention in sortedMentions) {
    // Add plain text before mention
    if (mention.offset > lastEnd) {
      spans.add(TextSpan(
        text: comment.text.substring(lastEnd, mention.offset),
      ));
    }
    // Add styled mention
    final end = (mention.offset + mention.length).clamp(0, comment.text.length);
    spans.add(TextSpan(
      text: comment.text.substring(mention.offset, end),
      style: TextStyle(
        color: const Color(0xFF00BFA5),
        fontWeight: FontWeight.w600,
      ),
      recognizer: TapGestureRecognizer()..onTap = () {
        // Navigate to user profile
      },
    ));
    lastEnd = end;
  }

  // Add remaining text
  if (lastEnd < comment.text.length) {
    spans.add(TextSpan(text: comment.text.substring(lastEnd)));
  }

  return RichText(
    text: TextSpan(style: context.bodyMedium, children: spans),
  );
}
```

- [ ] **Step 2: Display inline images in bubbles**

In the comment bubble, before the text, add image display:

```dart
if (comment.imageUrl != null && comment.imageUrl!.isNotEmpty)
  GestureDetector(
    onTap: () => _openImageViewer(comment.imageUrl!),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: comment.imageUrl!,
        maxHeightDiskCache: 400,
        fit: BoxFit.cover,
        constraints: const BoxConstraints(maxHeight: 200),
      ),
    ),
  ),
```

- [ ] **Step 3: Commit display changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/comments/comments_main.dart
git commit -m "feat(comments): render @mentions styled text and inline images in bubbles"
```

---

## Task 10: Localization + Verification

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/l10n/app_en.arb`
- Modify: All 17 other `app_*.arb` files

- [ ] **Step 1: Add English strings**

```json
"mentionedYouInComment": "{name} mentioned you in a comment",
"@mentionedYouInComment": { "placeholders": { "name": { "type": "String" } } },
"repliedToYourComment": "{name} replied to your comment",
"@repliedToYourComment": { "placeholders": { "name": { "type": "String" } } },
"reactedToYourComment": "{name} reacted to your comment",
"@reactedToYourComment": { "placeholders": { "name": { "type": "String" } } },
"searchUsers": "Search users...",
"addReaction": "Add reaction",
"attachImage": "Attach image",
"pickGif": "Pick a GIF"
```

- [ ] **Step 2: Add translations to all 17 ARB files**

- [ ] **Step 3: Regenerate and verify**

```bash
flutter gen-l10n
flutter analyze 2>&1 | grep -E "^   (error|warning)"
```

- [ ] **Step 4: Verify backend**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node -e "const Comment = require('./models/Comment'); console.log('reactions:', !!Comment.schema.paths['reactions']); console.log('mentions:', !!Comment.schema.paths['mentions']);"
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(l10n): add comment enhancement localization strings"
```
