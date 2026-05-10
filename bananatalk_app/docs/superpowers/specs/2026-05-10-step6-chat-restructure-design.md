# Step 6 — Chat Restructure + Modern Features — Design

**Date:** 2026-05-10
**Branch:** `refactor/step6-chat-restructure` (off `main`)
**Scope:** `lib/pages/chat/` (~15,131 lines, 17 subfolders, 3 monoliths) + paired backend audit
**Shape:** Restructure-heavy wave with bundled cleanup + 5 modernization-leaning features. Larger than Step 5 due to monolith size.

## Goal

Three discrete wins, packaged as one wave:

1. **Split the 3 chat monoliths** — `chat_conversation_screen.dart` (1,996), `chat_list_screen.dart` (1,634), `message_bubble.dart` (1,048) — into focused units of ≤500 lines each. Other large files (`chat_app_bar` 666, `wallpaper_picker_screen` 635, `gif_picker_panel` 578) get section splits if extraction reduces complexity.
2. **5 features + UI modernization**:
   - **E. Swipe-to-reply gesture** — drag bubble right to reply (iMessage-style)
   - **G. Voice message transcription** — auto/on-tap transcribe (backend `speech.transcribeAudio` already exists)
   - **H. Save-to-vocabulary from message** — long-press a word → save to user's `Vocabulary` collection (with SRS auto-scheduling)
   - **I. Auto-translate received** — per-conversation toggle in chat header; auto-renders translated text inline below original
   - **L. Material 3 / bubble redesign** — modern shadows, rounded corners, animated send/receive
3. **Cleanup sweep** (small): 0 `withOpacity` (clean), 5 `Colors.grey[*]`, 1 inline snackbar, 9 `debugPrint`. Plus `chat/widgets/` scaffolding (snackbar/empty/error helpers — mirrors past waves).

## Non-goals (explicit)

- **No group chats** — design with future-groups in mind (don't paint into corners), but ship 1-on-1 only. Deferred to its own wave.
- **No calling rebuild** — that's Step 6a (next wave). Step 6 leaves `flutter_webrtc` mesh + `callkit_service` untouched. Only the call-button hook in `chat_input_bar.dart` may need a touch when 6a lands.
- **No new chat features beyond E/G/H/I/L** — scheduled messages, message editing UI polish, mentions, disappearing messages all deferred. Edit/pin/forward/delete handlers already exist (lines 1422-1674 of conversation screen) — they stay as-is.
- **No backend rewrite** — only schema verifications + minor controller changes if audit reveals gaps.
- **No conversation-list complete redesign** — split + modernize the bubble/tile, but keep the existing list shape.

## Current state diagnostics

### Folder shape (~15,131 lines, 17 subfolders)

| File | Lines | Smell |
|---|---|---|
| `conversation/chat_conversation_screen.dart` | **1,996** | Single massive `ChatScreen` ConsumerStatefulWidget with lifecycle, scroll, panels, send, edit/pin/forward handlers, 3 controllers, 3 animations |
| `list/chat_list_screen.dart` | **1,634** | Conversation list + search + filter + bulk actions all inline |
| `message/message_bubble.dart` | **1,048** | Generic bubble shell + text/voice/image/gif/reply variant branching all inline |
| `header/chat_app_bar.dart` | 666 | App bar with avatar/title/actions + menu logic |
| `wallpaper/wallpaper_picker_screen.dart` | 635 | Wallpaper picker with preview + categories + custom upload |
| `panels/gif_picker_panel.dart` | 578 | GIF picker with search/trending tabs |
| `dialogs/chat_options_menu.dart` | 477 | Long-press menu options |
| `bookmarks/bookmarks_screen.dart` | 443 | Bookmarked messages list |
| `media/chat_media_screen.dart` | 435 | Media gallery for a conversation |
| `input/chat_input_bar.dart` | 427 | Composer with text + voice + attachments |
| `message/message_bubble/image_message_view.dart` | 397 | Image bubble variant (already extracted) |

### Already-shipped features (verified during planning)

- ✅ Reactions (`messageReaction` socket event)
- ✅ Read receipts (`markAsRead` emit)
- ✅ Voice messages (record + send + play)
- ✅ GIF picker (Tenor or similar)
- ✅ Wallpapers per conversation
- ✅ Bookmarks
- ✅ Reply-to (`reply_preview.dart` exists)
- ✅ Edit / pin / forward / delete (handlers at conversation_screen.dart:1422+)
- ✅ Translation (manual via long-press → `_showTranslation` → bottom sheet)
- ✅ Typing indicator
- ✅ Search messages (`messageSearch.js` backend + UI)

### Cleanup debt (chat folder)

- **0 `withOpacity`** (already clean — past sweeps caught this)
- **5 `Colors.grey[*]`** (small)
- **1 inline `ScaffoldMessenger.showSnackBar`** (trivial)
- **9 `debugPrint`** statements
- **No major TODO/FIXME** noise

This is a restructure-heavy wave; cleanup is minimal.

---

## Architecture

### Target folder layout (additive — no folder renames)

```
lib/pages/chat/
├── widgets/                                 (existing, expand)
│   ├── chat_snackbar.dart                   NEW (showChatSnackBar)
│   ├── chat_empty_state.dart                NEW
│   ├── chat_error_state.dart                NEW
│   └── (existing widgets stay)
│
├── conversation/                            (existing, expand)
│   ├── chat_conversation_screen.dart        SPLIT 1,996 → ~500 (orchestrator)
│   ├── sections/                            NEW
│   │   ├── conversation_lifecycle_mixin.dart    initState/dispose/didChange*
│   │   ├── conversation_scroll_controller.dart  scroll-to-bottom + scroll-to-message
│   │   ├── conversation_message_list.dart       the ListView body
│   │   └── conversation_animations.dart         _initializeAnimations + theme listener
│   ├── handlers/                            NEW
│   │   ├── message_action_handlers.dart         edit/delete/pin/forward/retry (lines 1422-1674)
│   │   ├── panel_handlers.dart                  toggleMediaPanel/StickerPanel/hidePanels
│   │   └── send_handlers.dart                   _showSendError, _selectSticker, _sendWaveSticker
│
├── list/                                    (existing, expand)
│   ├── chat_list_screen.dart                SPLIT 1,634 → ~500
│   ├── conversation_tile.dart               NEW (each row)
│   ├── list_search_bar.dart                 NEW
│   ├── list_filter_chips.dart               NEW
│   ├── list_empty_state.dart                NEW
│   └── list_swipe_actions.dart              NEW (swipe-to-archive, etc.)
│
├── message/                                 (existing, expand)
│   ├── message_bubble.dart                  SPLIT 1,048 → ~400 (orchestrator + branch)
│   ├── bubble/                              NEW
│   │   ├── bubble_container.dart                shared shell (bg + shadow + rounded corners — Material 3)
│   │   ├── text_bubble.dart                     plain text variant
│   │   ├── system_bubble.dart                   system messages (joined, left)
│   │   ├── bubble_actions.dart                  long-press action sheet
│   │   ├── swipe_to_reply_wrapper.dart          NEW — feature E
│   │   └── word_long_press_handler.dart         NEW — feature H (save-to-vocab)
│   └── (existing image/voice/gif/reply views stay in message_bubble/)
│
├── header/                                  (existing)
│   └── chat_app_bar.dart                    SPLIT 666 → ~300 if clean (extract avatar + actions)
│   └── auto_translate_toggle.dart           NEW — feature I
│
├── input/                                   (existing)
│   └── chat_input_bar.dart                  no major split (427 is fine)
│
├── panels/                                  (existing)
│   └── gif_picker_panel.dart                SPLIT 578 → ~250 if clean (extract search bar + tabs)
│
├── wallpaper/                               (existing)
│   └── wallpaper_picker_screen.dart         SPLIT 635 → ~300 if clean (extract preview + grid + custom)
│
└── (other subfolders untouched: bookmarks, dialogs, error, media, models, search, state)
```

**Net file count change:** ~17 → ~30 (small/medium files added, no folder renames).

### Pragmatic guardrail

Same as Step 5: if a split adds prop-threading complexity vs. reducing it, keep that piece inline and document in the commit message. Don't force splits.

### Feature designs

**E. Swipe-to-reply gesture** (UI only — ~1 commit)

Wrap each `MessageBubble` in `SwipeToReplyWrapper(child: bubble, onReply: () => _setReplyTo(message))`. Use `GestureDetector` with horizontal-drag tracking. At threshold (~50px), trigger haptic + invoke callback. Animate bubble back to position. Reuse existing `_setReplyTo` logic that powers the current reply system.

**G. Voice message transcription** (full-stack, ~2 commits)

- **Backend:** `speech.transcribeAudio` already exists at `controllers/speech.js`. Verify endpoint accepts URL (the message's voice file URL) + language hint. If not, add `transcribeFromUrl` variant.
- **Flutter:** In `voice_message_view.dart`, add a "Transcribe" button below the play button. On tap → POST to `/speech/transcribe-audio` with the message's audio URL → cache result on the `Message` model (add `transcription: String?`). Render below the waveform with a subtle "transcribed" label. Cache in `Message.metadata.transcription` so it's only fetched once per message.

**H. Save-to-vocabulary from message** (full-stack, ~1-2 commits)

UX: long-press a single word in any text bubble → small popup "Save '<word>' to vocabulary" with translation preview. Tap save → POST to `/vocabulary` with `{ word, language: msg.language, nativeLanguage: user.nativeLanguage, translation: <fetched> }`. Vocabulary model handles SRS auto-scheduling.

Flutter side: replace bubble's `Text` with a `RichText` that wraps each word in a `TapGestureRecognizer` for long-press. Show `Vocabulary` save sheet on long-press. (Consider performance — use a single `LongPressGestureDetector` that detects which word using touch position, rather than per-word recognizers, to avoid widget bloat.)

Backend: `controllers/learning.js` likely has vocab endpoints already (per the existence of `Vocabulary.js` model). Verify; add the create endpoint if missing.

**I. Auto-translate received** (~1-2 commits)

UX: in `chat_app_bar.dart`, add a `Switch` toggle "Auto-translate" in the menu. State persisted per-conversation in SharedPreferences as `autoTranslate_<conversationId>`. When ON, every received text bubble fetches translation on receive (or render-time) and shows it as a small italic line below the original. Reuses existing `showTranslationBottomSheet` translation API; just renders inline instead of in a sheet.

**L. Material 3 / bubble redesign** (~1-2 commits, distributed across files)

- Bubble container: rounded `BorderRadius.circular(20)`, subtle `BoxShadow` with theme-aware color, refined paddings
- Send button: filled M3 style with animated state
- App bar: M3 large title, transparent on scroll
- Tile in list: M3 card with rounded edges
- Animated message-in slide (200ms, ease-out)

---

## Cross-cutting

### l10n plan

~12-15 new ARB keys (English + 17 locale translations):

| Group | Keys (approx) |
|---|---|
| Snackbar / empty / error scaffolding | `chatRetry`, `chatLoadError`, `noConversationsYet` |
| Voice transcription | `transcribeMessage`, `transcribing`, `transcriptionFailed` |
| Save to vocabulary | `saveToVocabulary`, `addedToVocabulary`, `alreadyInVocabulary`, `tapWordToSave` |
| Auto-translate | `autoTranslate`, `autoTranslateOn`, `autoTranslateOff` |
| Modernization | `replyToHint` (swipe gesture hint, shown once) |

### Testing

- `flutter analyze` clean per commit
- Manual smoke per C-final: open conversation → send text → swipe-to-reply → save word to vocab → toggle auto-translate → transcribe a voice message → all message-action handlers (edit/pin/forward/delete) still work
- Backend unit tests for any controller change (likely just `learning.js` vocab create if missing)

### Risk register

| Risk | Mitigation |
|---|---|
| Splitting `chat_conversation_screen.dart` (1,996) breaks the 3 controllers + 3 animations + lifecycle | Use a `mixin` for lifecycle/animations to keep them on the State class. Extract handlers (pure methods taking `Message` + `ref`) to separate files — easy. Sections that own widgets (message list, scroll) extract as widgets that take state via constructor params. Pragmatic guardrail applies. |
| Word-level long-press for vocab save adds widget overhead per message | Use a single `Listener` per bubble + hit-test the touch position against `RichText`'s `getPositionForOffset`. Avoid per-word `GestureRecognizer` instances. Profile if needed. |
| Auto-translate per-message creates N translation API calls on conversation open | Lazy: only translate visible messages (via `VisibilityDetector`). Cache per message ID in `Message.metadata.translatedText`. Use existing translation API. |
| Voice transcription latency varies (cloud STT 2-10s) | Show inline spinner on the transcribe button. On success, replace spinner with text. On failure, show retry. Don't block the bubble render. |
| M3 bubble redesign breaks visual identity users are used to | Keep theme colors (primary green/teal). Only update shape/shadow/radius — incremental, not a brand redo. |
| `chat_list_screen.dart` (1,634) split breaks deep-link to conversation from notifications | Test the route after each split commit. The conversation-tile tap handler stays in one place; the list-shell extraction is the risky part. |

---

## PR / commit breakdown

| # | Commit | Type |
|---|---|---|
| C0 | `chore(chat)`: branch + deps audit | chore |
| C1 | `chore(chat)`: purge 9 debugPrint + drop 5 Colors.grey + 1 inline snackbar | chore |
| C2 | `refactor(chat)`: ARB keys (en) ~13 keys | refactor |
| C3 | `refactor(chat)`: translate ARB keys to 17 locales | refactor |
| C4 | `refactor(chat)`: add `chat/widgets/` scaffolding (snackbar, empty, error) | refactor |
| C5 | `refactor(chat)`: split `message_bubble.dart` (1,048 → orchestrator + bubble/) | refactor |
| C6 | `refactor(chat)`: split `chat_list_screen.dart` (1,634 → orchestrator + tiles + sections) | refactor |
| C7 | `refactor(chat)`: extract handlers from `chat_conversation_screen.dart` (~250 lines out) | refactor |
| C8 | `refactor(chat)`: extract sections from `chat_conversation_screen.dart` (lifecycle mixin, scroll, message list) | refactor |
| C9 | `refactor(chat)`: split `chat_app_bar.dart` (666 → orchestrator + extracted) — pragmatic | refactor |
| C10 | `refactor(chat)`: split `wallpaper_picker_screen.dart` + `gif_picker_panel.dart` if clean — pragmatic | refactor |
| C11 | `feat(chat)`: E — swipe-to-reply gesture wrapper | feat |
| C12 | `feat(chat)` + backend: G — voice message transcription | feat |
| C13 | `feat(chat)` + backend: H — save-to-vocabulary from message (long-press word) | feat |
| C14 | `feat(chat)`: I — auto-translate received toggle (header + per-msg render) | feat |
| C15 | `feat(chat)`: L — Material 3 bubble + tile + app bar redesign | feat |
| C16 | `feat(chat)`: L — message animations (slide-in, send-bounce) | feat |
| C17 | `chore(chat)`: final analyzer + smoke + push + PR | chore |

**Total: 18 commits.** Larger than Step 5 due to the 1,996-line monolith requiring 2 split commits (C7 + C8). Estimated wall-time: ~5-7 weeks.

---

## Future / deferred

- Group chat support (own wave)
- Scheduled messages (own ~2 commits in a future polish wave)
- Message editing UI improvements (handler exists; visual polish deferred)
- Pinned messages list view (tap pin icon → see all pinned in a sheet)
- Mentions / @ user (more useful in groups)
- Disappearing messages
- Message threads / dedicated reply-thread view
- Drafts persistence
- AI grammar suggestion in input (J — deferred — own wave)
- AI smart replies (K — deferred — own wave)
- Forward to multiple chats at once (currently single)
- Multi-attach (image + voice in one message)
- Voice message playback speed control
- Voice message waveform from server-side analysis (currently client-side guess)
