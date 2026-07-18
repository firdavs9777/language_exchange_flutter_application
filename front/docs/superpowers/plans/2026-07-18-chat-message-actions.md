# Chat Message Actions & Correctness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Checkbox steps.

**Goal:** Port the app's message action menu to web (reactions, reply, forward, pin, bookmark, TTS) using existing backend + RTK, and fix the dead/404 message routes — without rewriting the `ChatContent.tsx` monolith.

**Architecture:** Front repo ONLY. Build isolated, testable pieces first (pure predicates, slice endpoints, new Tailwind components), then wire them into `ChatContent.tsx` with minimal surgical edits LAST.

**Tech Stack:** React 18, TS, RTK Query, react-scripts test (Jest/RTL), Tailwind, existing socket singleton.

## Global Constraints

- Design system **Tailwind** for all new UI; no new `.scss`. Telegram-style action sheet; top emoji-reaction row 👍 ❤️ 😂 😮 😢 🙏; gradient send `#667EEA→#764BA2`; dark-mode aware.
- Backend routes (confirmed, `protect`): `POST /messages/:id/pin` (toggle, no DELETE), `POST|DELETE /messages/:id/bookmark`, `GET /messages/bookmarks`, `POST /messages/:id/forward`, `POST /messages/:id/reply`, `GET /messages/:id/replies`, `GET|POST /messages/:id/reactions` + `DELETE /messages/:id/reactions/:emoji`, `POST /messages/:id/tts`. NO `/messages/unread-count`, NO `/:id/read-receipts`, NO `PUT /:id/read` — these are DEAD (remove).
- Server does NOT emit `messageReaction`/`messageEdited`/`newVideoMessage` over socket → reactions/pins/bookmarks update via RTK tag invalidation (refetch), not socket.
- Edit window: own text ≤15 min. Delete-for-everyone: own ≤1 h.
- **CRITICAL (two subagents corrupted files this session): touch ONLY the files each task names; after committing, run `git status` and confirm ONLY intended files changed — if anything else is modified, STOP and report.** Never `git add -A`; never `git push`; never `git checkout/restore` other files. `tsc --noEmit` is broken repo-wide — verify with `CI=false npx react-scripts build` + Jest.
- Commit locally per task. Do NOT touch the backend repo.

---

### Task 1: `messageActions` pure predicates

**Files:** Create `src/components/chat/lib/messageActions.ts` + `.test.ts`.

**Interfaces:** `canEdit(msg, meId, now?) => boolean` (own + text + ≤15min); `canDeleteForEveryone(msg, meId, now?) => boolean` (own + ≤1h); `QUICK_REACTIONS = ['👍','❤️','😂','😮','😢','🙏']`. `msg` shape: `{ sender: string|{_id}, messageType?: string, type?: string, createdAt: string }`.

- [ ] **Step 1: Write failing test**

```ts
// src/components/chat/lib/messageActions.test.ts
import { canEdit, canDeleteForEveryone, QUICK_REACTIONS } from './messageActions';
const now = new Date('2026-07-18T12:00:00Z');
const mk = (over: any = {}) => ({ sender: 'me', messageType: 'text', createdAt: '2026-07-18T11:50:00Z', ...over });
it('canEdit: own text within 15min', () => { expect(canEdit(mk(), 'me', now)).toBe(true); });
it('canEdit: false if not own', () => { expect(canEdit(mk({ sender: 'other' }), 'me', now)).toBe(false); });
it('canEdit: false if older than 15min', () => { expect(canEdit(mk({ createdAt: '2026-07-18T11:40:00Z' }), 'me', now)).toBe(false); });
it('canEdit: false if not text', () => { expect(canEdit(mk({ messageType: 'image' }), 'me', now)).toBe(false); });
it('canEdit: sender as object', () => { expect(canEdit(mk({ sender: { _id: 'me' } }), 'me', now)).toBe(true); });
it('canDeleteForEveryone: own within 1h', () => { expect(canDeleteForEveryone(mk({ createdAt: '2026-07-18T11:15:00Z' }), 'me', now)).toBe(true); });
it('canDeleteForEveryone: false after 1h', () => { expect(canDeleteForEveryone(mk({ createdAt: '2026-07-18T10:00:00Z' }), 'me', now)).toBe(false); });
it('exposes 6 quick reactions', () => { expect(QUICK_REACTIONS).toHaveLength(6); });
```

- [ ] **Step 2:** Run `CI=true npx react-scripts test src/components/chat/lib/messageActions.test.ts --watchAll=false` → FAIL.
- [ ] **Step 3:** Implement:

```ts
// src/components/chat/lib/messageActions.ts
export const QUICK_REACTIONS = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
const senderId = (s: any): string => (typeof s === 'string' ? s : s?._id) ?? '';
const ageMs = (createdAt: string, now: Date) => now.getTime() - new Date(createdAt).getTime();
export function canEdit(msg: any, meId: string, now: Date = new Date()): boolean {
  const t = msg?.messageType ?? msg?.type;
  return senderId(msg?.sender) === meId && t === 'text' && ageMs(msg.createdAt, now) <= 15 * 60 * 1000;
}
export function canDeleteForEveryone(msg: any, meId: string, now: Date = new Date()): boolean {
  return senderId(msg?.sender) === meId && ageMs(msg.createdAt, now) <= 60 * 60 * 1000;
}
```

- [ ] **Step 4:** Run test → PASS.
- [ ] **Step 5:** Commit `feat(chat): add message-action predicates (edit 15m, delete-for-everyone 1h)`.

---

### Task 2: chatSlice — add action endpoints, fix reaction tags, remove dead routes

**Files:** Modify `src/store/slices/chatSlice.ts` (+ `src/constants.ts` if it holds the message URLs). Test: `src/store/slices/chatActionsEndpoints.test.ts`.

**Interfaces:** add `pinMessage` (POST `/messages/:id/pin`), `bookmarkMessage` (POST `/messages/:id/bookmark`), `unbookmarkMessage` (DELETE same), `getBookmarks` (GET `/messages/bookmarks`), `forwardMessage` (POST `/messages/:id/forward` `{targetConversationId|targetUserIds}` — confirm shape from backend at impl), `replyToMessage` (POST `/messages/:id/reply`), `ttsMessage` (POST `/messages/:id/tts`). Export their hooks. REMOVE `getUnreadCount`, `getReadReceipts`, `markMessageRead` (dead 404 routes). Ensure `addReaction`/`removeReaction`/`pin`/`bookmark` `invalidatesTags` the message/conversation so the UI refetches.

- [ ] **Step 1:** Read `chatSlice.ts` fully. Grep for consumers of `useGetUnreadCountQuery`/`useGetReadReceiptsQuery`/`useMarkMessageReadMutation` — if any component uses them, note and adapt minimally (e.g. drop the call) so the build stays green. Write `chatActionsEndpoints.test.ts` asserting the new endpoint URL/methods and that the 3 dead URLs are absent from constants/slice.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement inside the single existing injectEndpoints; export hooks in the single export block; remove the 3 dead endpoints + their exports (and any dead consumer call). Add tags.
- [ ] **Step 4:** Run test + `CI=false npx react-scripts build` → PASS/compiles.
- [ ] **Step 5:** Commit `feat(chat): add pin/bookmark/forward/reply/tts endpoints; remove dead 404 message routes`.

---

### Task 3: `ReactionRow` component

**Files:** Create `src/components/chat/actions/ReactionRow.tsx` + `.test.tsx`.

**Interfaces:** `<ReactionRow reactions myUserId onToggle(emoji) />` — renders aggregated reaction chips (emoji + count), highlights ones the user reacted with; a quick-pick row of `QUICK_REACTIONS`; clicking toggles. Purely presentational + callback.

- [ ] **Step 1:** RTL test: given reactions `[{emoji:'❤️', users:['me','x']},{emoji:'👍',users:['y']}]` and `myUserId='me'` → renders "❤️ 2" highlighted, "👍 1" not; clicking ❤️ calls `onToggle('❤️')`. (Adapt the reaction shape to what the backend returns — confirm at impl; keep the test asserting count + highlight + toggle.)
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implement (Tailwind pill chips, highlighted state teal-tinted). Import `QUICK_REACTIONS` from Task 1.
- [ ] **Step 4:** PASS + build.
- [ ] **Step 5:** Commit `feat(chat): ReactionRow (aggregated chips + quick-pick, Tailwind)`.

---

### Task 4: `MessageActionMenu` + `ForwardDialog`

**Files:** Create `src/components/chat/actions/MessageActionMenu.tsx`, `src/components/chat/actions/ForwardDialog.tsx` (+ optional tests).

**Interfaces:** `<MessageActionMenu message meId anchor onReply onForward onCopy onPin onBookmark onTts onEdit onDelete onReact onClose />` — a Tailwind popover with the top `ReactionRow` quick-pick and action buttons; shows Edit only when `canEdit`, Delete-for-everyone only when `canDeleteForEveryone` (from Task 1). `<ForwardDialog open message conversations onForward(target) onClose />` — recipient picker calling the forward endpoint.

- [ ] **Step 1:** Build `MessageActionMenu` (Tailwind sheet; conditional Edit/Delete via Task 1 predicates; Copy uses `navigator.clipboard`; TTS/pin/bookmark/reply/forward call the passed handlers).
- [ ] **Step 2:** Build `ForwardDialog` (list from `useGetConversationsQuery`; select → `onForward`).
- [ ] **Step 3:** `CI=false npx react-scripts build` compiles; a light RTL test that the menu hides Edit for a partner message and shows it for an editable own message.
- [ ] **Step 4:** Commit `feat(chat): MessageActionMenu + ForwardDialog (Tailwind, action-gated)`.

---

### Task 5: `PinnedBar`, `BookmarksView`, `ReplyComposerBar`

**Files:** Create `src/components/chat/actions/PinnedBar.tsx`, `src/components/chat/actions/BookmarksView.tsx`, `src/components/chat/actions/ReplyComposerBar.tsx`.

**Interfaces:** `<PinnedBar pinned onJump(msgId) onUnpin(msgId) />` (top-of-thread bar; hidden when none). `<BookmarksView />` uses `useGetBookmarksQuery` → list of saved messages (open route or modal). `<ReplyComposerBar replyingTo onCancel />` (band above composer showing the quoted message + cancel).

- [ ] **Step 1:** Build the three Tailwind components (presentational + hooks where noted).
- [ ] **Step 2:** `CI=false npx react-scripts build` compiles.
- [ ] **Step 3:** Commit `feat(chat): PinnedBar + BookmarksView + ReplyComposerBar (Tailwind)`.

---

### Task 6: Wire into `ChatContent.tsx` (surgical — HIGH CARE)

**Files:** Modify `src/components/chat/ChatContent.tsx` (minimal, surgical). Possibly `MainChat.tsx`/route for BookmarksView.

**Do NOT rewrite the monolith.** Add:
- A hover/right-click affordance on each message bubble that opens `MessageActionMenu` for that message (manage `activeActionMsg` state + anchor).
- Render `ReactionRow` under each bubble (from the message's reactions), wired to `useAddReactionMutation`/`useRemoveReactionMutation` + refetch.
- Render `PinnedBar` at the top of the thread (pinned messages from the conversation/messages).
- Render `ReplyComposerBar` above the composer when replying; set `replyTo` on send (payload already supports it).
- Wire menu handlers: reply (set replyingTo), forward (open ForwardDialog), copy, pin (`usePinMessageMutation`), bookmark (`useBookmark…`), tts (`useTtsMessageMutation` → play returned audio), edit/delete (reuse existing paths).
- Remove any call to the deleted dead endpoints (unread-count/read-receipts/markMessageRead) that lived here.

- [ ] **Step 1:** Read `ChatContent.tsx` fully first. Make the smallest possible edits to mount the new components + handlers; do not restructure existing logic.
- [ ] **Step 2:** `CI=true npx react-scripts test src/components/chat --watchAll=false` (existing tests pass) + `CI=false npx react-scripts build 2>&1 | tail -25` (compiles, no NEW errors).
- [ ] **Step 3:** Run `git status` — confirm ONLY `ChatContent.tsx` (+ any explicitly-intended file) changed. If anything else is modified, STOP.
- [ ] **Step 4:** Commit `feat(chat): wire message action menu, reactions, pinned bar, reply band into thread`.

---

### Task 7: Remove dead socket listeners + cleanup

**Files:** Modify `src/components/chat/ChatContent.tsx` (only the dead listeners) — or wherever they live.

- [ ] **Step 1:** Remove the dead socket listeners the server never emits (`messageEdited`, `newVideoMessage`; `messageReaction` now replaced by refetch — remove if unused). Verify via the backend recon (server emit list). Do NOT remove live ones (`newMessage`, `messagesRead`, `messageDeleted`, `userTyping`, `messageCorrection`, etc.).
- [ ] **Step 2:** Build + existing tests pass; `git status` shows only intended file.
- [ ] **Step 3:** Commit `chore(chat): remove dead socket listeners (server never emits them)`.

---

## Self-Review notes (author)
- Spec coverage: action menu (T4) + reactions (T2/T3/T6) + reply (T5/T6) + forward (T2/T4/T6) + pin/pinned-bar (T2/T5/T6) + bookmark/saved-view (T2/T5/T6) + TTS (T2/T4/T6) + dead-route removal (T2) + dead-listener removal (T7). Predicates (T1) gate edit/delete. Monolith refactor/themes/rooms/composer deferred per spec.
- Risk: T6 edits the 1,869-line live monolith — smallest-possible surgical edits, mandatory `git status` check after commit (two subagents corrupted files earlier this session).
- No backend changes; backend working tree (user WIP) untouched.
