# Chat Message Actions & Correctness (Web) — Design Spec

**Date:** 2026-07-18
**Status:** Design spec (autonomous build per user pre-confirmation). A scoped slice of roadmap **Package 2 (Chat)** — the highest-value, backend-ready message-action features + correctness fixes. Design system: **Tailwind**.

## Goal

Port the app's Telegram-style **message action menu** (reactions, reply, forward, pin, bookmark, copy, TTS) to web, wire the features whose backend + RTK mutations already exist, and fix the dead/broken message routes the web currently calls. Mobile is source of truth. Verified against real app + backend code.

## Why this slice (scope rationale)

Package 2 is enormous. The web chat is a monolith (`ChatContent.tsx` 1,869 lines, bootstrap/SCSS) with much already working (text/media/voice/typing/read-receipts/**corrections**/translation/presence). This spec targets the **backend-ready gaps that ship as one coherent feature** — a message action menu — plus **correctness bugs**, WITHOUT the large `ChatContent` refactor, composer overhaul, themes/wallpaper, or language rooms (all deferred to later Package-2 slices).

## Current web state (verified)

- Live: `src/components/chat/ChatContent.tsx` (1,869, monolith), `UsersList.tsx` (989, conv list), `MainChat.tsx`, socket singleton `hooks/useSocket.ts`. RTK in `src/store/slices/chatSlice.ts`.
- Working: text (socket `sendMessage`), media/voice (HTTP), stickers/GIFs, typing, read receipts (socket `markAsRead`), delete (socket), **corrections (fully wired)**, translation, per-user presence.
- **Dead RTK listeners** (server never emits these over socket): `messageReaction`, `messageEdited`, `newVideoMessage`.
- **Broken/404 routes the web calls** (do NOT exist in backend `routes/messages.js`): `GET /messages/unread-count`, `GET /messages/:id/read-receipts`, `PUT /messages/:id/read`.
- There is an **abandoned decomposed `components/` set** (`MessageBubble`, `ReactionPicker`, `ReplyPreview`, etc.) — unused; a future refactor target, NOT adopted here.

## Backend contract (verified, READ-ONLY — no backend changes in this slice)

`routes/messages.js` (all `protect`):
- Reactions: `GET /messages/:id/reactions`, `POST /messages/:id/reactions` (`{emoji}`), `DELETE /messages/:id/reactions/:emoji`.
- Reply: `POST /messages/:id/reply`; threads: `GET /messages/:id/replies`. (`POST /messages` also accepts `replyTo`.)
- Forward: `POST /messages/:id/forward`.
- Pin: `POST /messages/:id/pin` (and per app, an unpin — confirm `DELETE`/toggle during planning).
- Bookmark: `POST /messages/:id/bookmark`, `DELETE /messages/:id/bookmark`, `GET /messages/bookmarks`.
- TTS: **`POST /messages/:id/tts`** (POST, not GET — roadmap was wrong).
- Corrections/translate/vocabulary: already wired on web.
- Real unread/read: `PUT /conversations/:id/read` EXISTS (mark conversation read). There is NO `GET /messages/unread-count`, NO `/:id/read-receipts`, NO `PUT /messages/:id/read` — the web's calls to these are dead.

App message-action sheet (`message_actions_bottom_sheet.dart`): quick-reaction row 👍 ❤️ 😂 😮 😢 🙏 (highlight own), Reply, Copy, Translate, Forward, Pin/Unpin, Edit (own text, ≤15 min), Delete (own; delete-for-everyone ≤1 h). Pinned-messages bar `message/pinned_messages_bar.dart`, socket `messagePinned`. Bookmarks screen `bookmarks/bookmarks_screen.dart`.

## Scope

### In scope
1. **Message action menu** (Tailwind popover/sheet on hover-affordance + right-click/long-press): a top **6-emoji quick-reaction row** (👍 ❤️ 😂 😮 😢 🙏, highlighting the user's current reaction) + actions **Reply, Copy, Forward, Pin/Unpin, Bookmark/Unbookmark, TTS ("Listen"), Edit** (own text, ≤15 min), **Delete** (own; for-everyone ≤1 h). Reuse the existing delete/edit paths already in `ChatContent`.
2. **Reactions wiring**: use existing `useAddReactionMutation`/`useRemoveReactionMutation`; since the server does NOT emit `messageReaction` over socket, update optimistically + refetch the message/conversation (invalidate tags) rather than relying on the dead listener. Render a reaction chip row under bubbles.
3. **Reply/quote**: set `replyTo` on send (payload already supports it); render a reply-preview band above the composer and a quoted snippet in the bubble; tapping a quoted snippet scrolls to the original. (Threaded replies list `GET /:id/replies` optional — include a "N replies" affordance only if tractable.)
4. **Forward**: a recipient-picker dialog → `POST /messages/:id/forward`.
5. **Pin**: `POST /messages/:id/pin` (+ unpin) and a **pinned-messages bar** at the top of the thread showing pinned message(s), tap to scroll.
6. **Bookmark**: toggle via `POST|DELETE /messages/:id/bookmark`; a **saved-messages view** via `GET /messages/bookmarks`.
7. **TTS**: "Listen" action → `POST /messages/:id/tts` → play returned audio (HTML5 Audio).
8. **Correctness fixes (bugs)**: remove/repoint the dead web calls — delete `getUnreadCount`(`/messages/unread-count`), `getReadReceipts`(`/messages/:id/read-receipts`), `markMessageRead`(`PUT /messages/:id/read`) OR repoint unread to the real mechanism (conversation-level `PUT /conversations/:id/read` already used); and remove the dead socket listeners (`messageReaction` post-wire, `messageEdited`, `newVideoMessage`) or convert reactions to the refetch model. No 404-generating calls left.

### Out of scope (deferred to later Package-2 slices)
- The big `ChatContent.tsx` / `UsersList.tsx` refactor (adopt the unused `components/` set) — separate effort.
- Composer overhaul (Mic⇄Send cross-fade, + attach menu parity), voice waveform/transcribe, video parity.
- Conversation themes/wallpaper (socket `themeChanged`), per-conversation nicknames, quick-replies/phrases panels, archive UI.
- Language rooms (`room:*`), bulk presence adoption, polls, disappearing messages, mentions, auto-translate toggle.
- Any backend change.

## Web design
- New `src/components/chat/actions/` (Tailwind): `MessageActionMenu.tsx` (the popover), `ReactionRow.tsx`, `ForwardDialog.tsx`, `PinnedBar.tsx`, `BookmarksView.tsx`, `ReplyComposerBar.tsx`.
- `chatSlice.ts`: add/confirm `pinMessage`/`unpinMessage`, `bookmarkMessage`/`unbookmarkMessage`, `getBookmarks`, `forwardMessage`, `replyToMessage`, `ttsMessage` (POST) endpoints; add proper `invalidatesTags`/`providesTags` so reactions/pins/bookmarks refetch (compensating for missing socket emits); REMOVE the 3 dead endpoints (or repoint). Keep it inside the single existing injectEndpoints/export block.
- Wire the menu into `ChatContent` bubbles with minimal, surgical edits (do NOT rewrite the monolith); a small pure helper `src/components/chat/lib/messageActions.ts` for the edit/delete time-window predicates (`canEdit(msg, now)` ≤15 min own-text; `canDeleteForEveryone(msg, now)` ≤1 h own) — unit-tested.
- Design system Tailwind: Telegram-style action sheet, top emoji row, tinted icon chips, gradient send button `#667EEA→#764BA2`, red `#EF4444` unread, dark-mode aware.

## Testing
- Unit (Jest/RTL): `messageActions` predicates (edit ≤15 min own-text; delete-for-everyone ≤1 h; false for others); `ReactionRow` highlights the user's reaction + emits add/remove; `MessageActionMenu` shows the right actions per message (own vs partner, editable window); chatSlice reaction/pin/bookmark endpoint configs; a test that the removed dead endpoints are gone (no `/messages/unread-count` etc. in constants/slice).
- Build gate: `CI=false npx react-scripts build` (NOT tsc — broken repo-wide). Manual: react to a message (persists via refetch), pin (appears in bar), bookmark (appears in saved view), forward, TTS plays, reply quotes + scrolls.

## Open items for the plan (routes now confirmed; shapes TBD at plan time)
Confirmed in `backend/routes/messages.js`: `POST /:id/pin` (single route → `messageManagement.pinMessage`, i.e. a **toggle** — no separate DELETE), `POST|DELETE /:id/bookmark`, `GET /bookmarks`, `POST /:id/forward`, `POST /:id/reply`, `GET /:id/replies`, `GET|POST /:id/reactions` + `DELETE /:id/reactions/:emoji`, `POST /:id/tts` (→ `advancedMessages.getMessageTTS`). **`unread-count` has NO backend route anywhere — DROP the client `getUnreadCount` feature and rely on conversation unread from `getConversations`.**
Still to confirm at plan time (read the controllers):
1. `pinMessage` toggle semantics + response (pinned bool / updated message).
2. Exact request/response shapes for reactions (add/remove), forward (target conv/user param), bookmark, and `getMessageReplies`.
3. TTS response shape (audio URL vs base64/binary) from `advancedMessages.getMessageTTS`.
