# Chat Improvements + Coin Promotion — Design Spec

**Date:** 2026-07-18
**Status:** Approved (design), pending implementation plan
**Scope:** Two chat UX/feature improvements (P1, F1) + four coin-promotion
surfaces in chat (C1, C2, C3, C4). C3 is sequenced as phase 2.

---

## Background

BananaTalk's chat is already mature: read receipts (✓/✓✓), optimistic send
with retry, reactions, polls, self-destruct, inline corrections, translations,
forwarding, swipe-to-reply, jump-to-bottom FAB, presence/online, typing,
drafts, wallpaper, stickers, pinned messages. Investigation confirmed that
**message grouping (P3) is already implemented** — `messages_list.dart`
computes `isFirstInGroup`/`isLastInGroup` (same author + 3-min window) and the
bubble already collapses spacing, shows the avatar only on the last message of
a run, and rounds only the group's outer corners. P3 was therefore dropped
from scope.

Two genuine chat gaps remain (P1, F1). Separately, the coin system
(`coins-v1`, `vip-coins-boost`) is built but under-promoted inside chat: the
`LimitExceededDialog` already hosts a coin `UnlockCta`, but
`_featureKeyForUnlock()` only returns a key for `moment` — so a free user who
hits the **daily message cap** sees "Go VIP" only, with no coin option. Four
coin-promotion surfaces (C1–C4) address that.

## Goals

- P1: calendar date separators between message groups.
- F1: a true "delivered" state (3-state ticks: sent → delivered → read).
- C1: coin unlock offered when the daily message cap is hit.
- C2: coin unlock offered when auto-translate hits its cap, in-conversation.
- C3 (phase 2): coin-unlockable premium chat wallpaper pack.
- C4: coin balance pill in the chat-detail header.

## Non-goals

- Unread divider ("New messages" line) — explicitly deferred.
- Message grouping changes — already implemented; not touched.
- Rewriting `chat_conversation_screen.dart` (1,951 lines) or
  `message_bubble.dart` (1,544 lines). New logic lands in new/small files;
  existing files get minimal wiring only.

## Cross-cutting constraints

- Every coin surface stays gated behind `AppConfig.coinsEnabled` and renders
  nothing when the unlock catalog lacks the relevant key (existing `UnlockCta`
  behavior). This lets the server dark-launch each piece independently.
- Cost/grant values are read live from `GET /coins/unlock-catalog` — never
  hardcoded in the client.
- Light + dark mode must both be handled for every new visual element.

---

## P1 — Date separators (client only)

**New file: `lib/pages/chat/message/chat_row.dart`**

```dart
sealed class ChatRow { const ChatRow(); }
class DateSeparatorRow extends ChatRow {
  final DateTime day; // local, date-only (midnight)
  const DateSeparatorRow(this.day);
}
class MessageRow extends ChatRow {
  final Message message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  const MessageRow(this.message, {required this.isFirstInGroup, required this.isLastInGroup});
}

/// Pure, unit-testable. Produces the ordered render model:
/// a DateSeparatorRow before the first message of each local calendar day,
/// with grouping flags computed once here (same author + <3 min window),
/// and grouping forced to restart after a day break.
List<ChatRow> buildChatRows(List<Message> messages);
```

- Grouping logic moves out of `messages_list.dart`'s builder into
  `buildChatRows` (single source of truth). A message immediately after a
  `DateSeparatorRow` is always `isFirstInGroup: true`.
- `correction` and `call` message types keep their existing standalone
  treatment; they never merge into a group (matches current behavior) and a
  date separator may precede them.

**New widget: `DateSeparatorChip`**
- Centered pill, muted surface + subtle border; theme-aware.
- Label: `Today` / `Yesterday` / weekday name (within the last 7 days) /
  `MMM d` (this year) / `MMM d, yyyy` (other years), via `intl DateFormat`
  and existing l10n where strings are user-facing ("Today"/"Yesterday").

**Edit: `lib/pages/chat/message/messages_list.dart`**
- Build `rows = buildChatRows(messages)` once per build.
- `itemCount = (hasHeader ? 1 : 0) + rows.length + (isLoadingMore ? 1 : 0)`.
- Builder: index 0 → header (unchanged); tail → loading spinner (unchanged);
  otherwise switch on `rows[i]`: `DateSeparatorRow` → `DateSeparatorChip`;
  `MessageRow` → existing bubble construction, reading the precomputed group
  flags instead of recomputing prev/next inline.
- Group-mode sender-name header (line ~333) is preserved unchanged.

**Test:** `test/chat/chat_row_test.dart` — messages spanning multiple local
days produce the correct separators, order, count, and group-flag reset after
a day boundary; single-day list produces exactly one separator.

---

## F1 — Delivered state (backend + client)

**Message states (my messages):**
`sending` (⏱) → `sent` (`✓` grey) → `delivered` (`✓✓` grey) → `read` (`✓✓` blue).

**Backend**
- Add `delivered: Boolean` (default `false`) to the Message schema.
- When the server routes a `newMessage` to a **connected** recipient socket,
  persist `delivered: true` and emit `messageDelivered` to the sender's room
  with `{ messageId, conversationId }`.
- On recipient reconnect / backlog delivery, stamp any of their still-
  undelivered messages as `delivered: true` and emit `messageDelivered` for
  each to the respective sender rooms.
- Read pipeline (`messageRead` / `messagesRead` / `bulkStatusUpdate`)
  unchanged; `read` implies delivered for rendering.

**Client**
- `Message` model: add `final bool delivered;` + `fromJson` parse
  (`json['delivered'] ?? false`) + include in `copyWith` / status copies.
- `chat_socket_service.dart`: add `_messageDeliveredController` +
  `Stream get onMessageDelivered`, and `_socket?.on('messageDelivered', ...)`
  → `_safeAdd`. Mirror the existing `messageRead` wiring.
- State layer (where `onMessageRead` is consumed): on `messageDelivered`, set
  the target message's `delivered = true` (no-op if already `read`).
- `message_bubble.dart` (status row ~1369): replace the 2-state icon with:
  - `!delivered && !read` → `Icons.done` (grey / timestamp color)
  - `delivered && !read` → `Icons.done_all` (grey / timestamp color)
  - `read` → `Icons.done_all` (primary/blue)
  - `sendingStatus != none` keeps `_buildSendingStatus()` (⏱ / failed).

**Test:** bubble render logic — a small extracted `tickIconFor(message)` helper
returning `(IconData, ColorRole)` so the 4-state mapping is unit-testable
without pumping the full widget.

---

## C1 — Message-limit coin unlock (backend catalog + 1 client mapping)

**Backend**
- Add catalog key `chat` to the coin unlock catalog: cost + grant of "N more
  messages today", mirroring the existing `moment` unlock (per-UTC-day grant,
  idempotent credit/debit).
- `POST /coins/unlock` with `chat` debits coins and raises the caller's daily
  message allowance for the current UTC day.

**Client**
- `lib/widgets/limit_exceeded_dialog.dart` `_featureKeyForUnlock()`: add
  `case 'message': case 'messages': return 'chat';`.
- The dialog already renders `UnlockCta(featureKey, onUnlocked)` and retries;
  `onUnlocked` closes with `'unlocked'` and the send is retried by the caller
  (the conversation send path already handles the `messages` limit via
  `limitType: 'messages'`).
- Renders nothing if the `chat` key is absent from the catalog (dark-launch
  safe).

---

## C2 — Translate-limit coin unlock, in-conversation (client only)

- Identify the auto-translate cap path in chat (translate action /
  `auto_translate_toggle` + the translate call in the conversation).
- On a translate limit/429, surface `UnlockCta(featureKey: 'translation')`
  **directly at the call site** via a compact bottom sheet (not through
  `LimitExceededDialog`, whose `_featureKeyForUnlock` intentionally maps only
  `moment`). `translation` already exists in the catalog, so the CTA renders
  its live cost/grant.
- `onUnlocked` retries the translation inline.

---

## C3 — Premium chat wallpapers (backend catalog + client) — PHASE 2

**Backend**
- Add a single catalog key `wallpaper` that unlocks the whole premium pack
  (simpler than per-image keys). `POST /coins/unlock` with `wallpaper`
  persists a durable entitlement on the user (not per-day).
- Expose the entitlement so the client can tell locked from unlocked.

**Client**
- Bundle a premium wallpaper pack under `assets/` (finite set of images).
- `wallpaper_picker_screen.dart`: premium items show a lock + `💎 X` price
  badge (price from catalog). Tapping a locked item triggers coin unlock;
  after success the whole pack becomes selectable. Free wallpapers unchanged.
- Gated behind `coinsEnabled`; if the `wallpaper` key is absent, premium items
  are simply hidden (only free wallpapers show).

**Test:** picker shows lock/price on premium items when locked and makes them
selectable after entitlement flips.

---

## C4 — Coin balance pill in chat header (client only)

- Add the existing `CoinBalancePill` to `chat_app_bar.dart` (chat-detail
  header), tappable → Coin Shop, gated on `AppConfig.coinsEnabled`.
- Must not crowd existing header actions (call / options); place compactly and
  verify layout in both themes and with long partner names.

---

## Sequencing (phase 1 ships without C3)

1. **P1** date separators (client, isolated, testable)
2. **F1** delivered state (backend emit + client tick states)
3. **C1** message-limit coin unlock (catalog key + 1 mapping)
4. **C2** translate-limit coin unlock (client)
5. **C4** coin pill in chat header (client)
6. **C3** premium wallpapers (phase 2 — assets + entitlement)

## Risks / mitigations

- **F1 backend correctness** — offline→reconnect delivered stamping must not
  double-emit or mis-target; reuse the read pipeline's room-scoping and make
  the delivered stamp idempotent (`delivered` only transitions false→true).
- **Large files** — confine edits in `chat_conversation_screen.dart` and
  `message_bubble.dart` to minimal wiring; extract new logic
  (`buildChatRows`, `tickIconFor`) into new small, tested files.
- **Coin dark-launch** — every coin surface must no-op cleanly when its
  catalog key is missing or `coinsEnabled` is false.
