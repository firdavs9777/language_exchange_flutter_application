# Chat Improvements + Coin Promotion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add date separators and a true "delivered" tick state to chat, and promote coins across four chat surfaces (message-limit unlock, translate-limit unlock, coin pill in header, premium wallpapers).

**Architecture:** Client work in Flutter/Riverpod; two tasks touch the Node/Express + Mongoose backend (separate repo). New logic lands in small, testable files (`chat_row.dart`, a `tickIconFor` helper); large files (`chat_conversation_screen.dart` 1,951 lines, `message_bubble.dart` 1,544 lines) get minimal wiring only. Coin surfaces reuse the existing `UnlockCta` / unlock-catalog infra and stay gated behind `AppConfig.coinsEnabled`.

**Tech Stack:** Flutter, Riverpod, socket.io client; backend Node/Express, Mongoose, socket.io.

## Global Constraints

- Every coin surface renders nothing when `AppConfig.coinsEnabled` is false OR when its catalog key is absent (existing `UnlockCta` behavior). Dark-launch safe.
- Coin cost/grant values are read live from `GET /coins/unlock-catalog` — never hardcoded in the client.
- Both light and dark mode must be handled for every new visual element.
- `delivered` only ever transitions `false → true` (idempotent); `read` implies delivered for rendering.
- **Commits are deferred per the user's standing "commit later" instruction.** Execute the commit steps as *staging checkpoints* only if the user re-authorizes; otherwise leave changes in the working tree and skip `git commit`.
- Backend repo is separate and currently on branch `feat/pkg1a-registration-parity`; confirm branch with the user before applying backend tasks.

---

## Task 1: Date-separator row model (`buildChatRows`)

**Files:**
- Create: `lib/pages/chat/message/chat_row.dart`
- Test: `test/chat/chat_row_test.dart`

**Interfaces:**
- Consumes: `Message` from `lib/providers/provider_models/message_model.dart` (fields used: `id`, `createdAt` ISO string, `sender.id`, `type`).
- Produces:
  - `sealed class ChatRow`
  - `class DateSeparatorRow extends ChatRow { final DateTime day; }` (local date-only midnight)
  - `class MessageRow extends ChatRow { final Message message; final bool isFirstInGroup; final bool isLastInGroup; }`
  - `List<ChatRow> buildChatRows(List<Message> messages)`

- [ ] **Step 1: Write the failing test**

```dart
// test/chat/chat_row_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/chat/message/chat_row.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

Message _msg(String id, String senderId, String iso, {String type = 'text'}) =>
    Message.fromJson({
      'id': id,
      'sender': {'_id': senderId, 'name': 'U', 'images': []},
      'receiver': {'_id': 'other', 'name': 'O', 'images': []},
      'message': 'hi',
      'createdAt': iso,
      'type': type,
      'read': false,
      'reactions': [],
      'translations': [],
      'corrections': [],
      'mentions': [],
    });

void main() {
  test('one separator for a single-day conversation', () {
    final rows = buildChatRows([
      _msg('1', 'a', '2026-07-18T09:00:00.000Z'),
      _msg('2', 'a', '2026-07-18T09:01:00.000Z'),
    ]);
    expect(rows.whereType<DateSeparatorRow>().length, 1);
    expect(rows.length, 3); // sep + 2 messages
  });

  test('separator inserted at each day boundary and grouping resets', () {
    final rows = buildChatRows([
      _msg('1', 'a', '2026-07-17T09:00:00.000Z'),
      _msg('2', 'a', '2026-07-18T09:00:00.000Z'),
    ]);
    expect(rows.whereType<DateSeparatorRow>().length, 2);
    final firstMsgAfterBreak =
        rows.whereType<MessageRow>().firstWhere((r) => r.message.id == '2');
    expect(firstMsgAfterBreak.isFirstInGroup, true);
  });

  test('same author within 3 minutes groups (middle msg not first/last)', () {
    final rows = buildChatRows([
      _msg('1', 'a', '2026-07-18T09:00:00.000Z'),
      _msg('2', 'a', '2026-07-18T09:01:00.000Z'),
      _msg('3', 'a', '2026-07-18T09:02:00.000Z'),
    ]);
    final middle =
        rows.whereType<MessageRow>().firstWhere((r) => r.message.id == '2');
    expect(middle.isFirstInGroup, false);
    expect(middle.isLastInGroup, false);
  });

  test('empty input yields no rows', () {
    expect(buildChatRows(const []), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat/chat_row_test.dart`
Expected: FAIL — `chat_row.dart` / `buildChatRows` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/pages/chat/message/chat_row.dart
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// Render model for the chat message list: either a day separator or a
/// message carrying its precomputed grouping flags. Produced by the pure
/// [buildChatRows] so the ListView builder stays dumb and this logic is
/// unit-testable in isolation.
sealed class ChatRow {
  const ChatRow();
}

class DateSeparatorRow extends ChatRow {
  final DateTime day; // local, date-only (midnight)
  const DateSeparatorRow(this.day);
}

class MessageRow extends ChatRow {
  final Message message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  const MessageRow(
    this.message, {
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });
}

DateTime? _localDay(String iso) {
  try {
    final t = DateTime.parse(iso).toLocal();
    return DateTime(t.year, t.month, t.day);
  } catch (_) {
    return null;
  }
}

bool _groups(Message a, Message b) {
  if (a.sender.id != b.sender.id) return false;
  if (a.type == 'correction' || a.type == 'call') return false;
  if (b.type == 'correction' || b.type == 'call') return false;
  try {
    final ta = DateTime.parse(a.createdAt);
    final tb = DateTime.parse(b.createdAt);
    return tb.difference(ta).inMinutes.abs() < 3;
  } catch (_) {
    return false;
  }
}

/// Builds the ordered render rows: a [DateSeparatorRow] before the first
/// message of each local calendar day, and a [MessageRow] per message with
/// grouping flags (same author + <3 min window) computed once. Grouping
/// always restarts after a day boundary.
List<ChatRow> buildChatRows(List<Message> messages) {
  final rows = <ChatRow>[];
  DateTime? currentDay;

  for (var i = 0; i < messages.length; i++) {
    final msg = messages[i];
    final day = _localDay(msg.createdAt);

    final dayChanged = day != null &&
        (currentDay == null || !day.isAtSameMomentAs(currentDay));
    if (dayChanged) {
      rows.add(DateSeparatorRow(day));
      currentDay = day;
    }

    final prev = i > 0 ? messages[i - 1] : null;
    final next = i < messages.length - 1 ? messages[i + 1] : null;

    final isFirstInGroup = dayChanged || prev == null || !_groups(prev, msg);
    // If the next message opens a new day it will get its own separator, so
    // this message ends its group.
    final nextSameDay = next != null && _localDay(next.createdAt) == day;
    final isLastInGroup = next == null || !nextSameDay || !_groups(msg, next);

    rows.add(MessageRow(msg,
        isFirstInGroup: isFirstInGroup, isLastInGroup: isLastInGroup));
  }
  return rows;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat/chat_row_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit (staging checkpoint — see Global Constraints)**

```bash
git add lib/pages/chat/message/chat_row.dart test/chat/chat_row_test.dart
git commit -m "feat(chat): add chat row model with date separators + grouping"
```

---

## Task 2: `DateSeparatorChip` widget + wire into `messages_list.dart`

**Files:**
- Create: `lib/pages/chat/message/date_separator_chip.dart`
- Modify: `lib/pages/chat/message/messages_list.dart` (builder ~174–357)
- Test: `test/chat/date_separator_chip_test.dart`

**Interfaces:**
- Consumes: `DateSeparatorRow`, `MessageRow`, `buildChatRows` (Task 1).
- Produces: `class DateSeparatorChip extends StatelessWidget { final DateTime day; }` and `String dateSeparatorLabel(DateTime day, DateTime now)` (pure, testable).

- [ ] **Step 1: Write the failing test**

```dart
// test/chat/date_separator_chip_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/chat/message/date_separator_chip.dart';

void main() {
  final now = DateTime(2026, 7, 18, 15, 0);
  test('today', () {
    expect(dateSeparatorLabel(DateTime(2026, 7, 18), now), 'Today');
  });
  test('yesterday', () {
    expect(dateSeparatorLabel(DateTime(2026, 7, 17), now), 'Yesterday');
  });
  test('within last week -> weekday', () {
    expect(dateSeparatorLabel(DateTime(2026, 7, 14), now), 'Tuesday');
  });
  test('this year older -> MMM d', () {
    expect(dateSeparatorLabel(DateTime(2026, 3, 2), now), 'Mar 2');
  });
  test('other year -> MMM d, yyyy', () {
    expect(dateSeparatorLabel(DateTime(2025, 3, 2), now), 'Mar 2, 2025');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat/date_separator_chip_test.dart`
Expected: FAIL — `dateSeparatorLabel` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/pages/chat/message/date_separator_chip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Human date label for a chat day separator. Pure so it is unit-testable;
/// [now] is injected (defaults to DateTime.now() at the call site).
String dateSeparatorLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(day.year, day.month, day.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return DateFormat('EEEE').format(d); // weekday
  if (d.year == today.year) return DateFormat('MMM d').format(d);
  return DateFormat('MMM d, yyyy').format(d);
}

class DateSeparatorChip extends StatelessWidget {
  const DateSeparatorChip({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final label = dateSeparatorLabel(day, DateTime.now());
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: context.surfaceVariantColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dividerColor, width: 0.5),
        ),
        child: Text(
          label,
          style: context.captionSmall.copyWith(
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
```

> Note: if `context.surfaceVariantColor` is not present in `theme_extensions.dart`, use `context.surfaceColor` — verify the available getter before running.

- [ ] **Step 4: Run label test to verify it passes**

Run: `flutter test test/chat/date_separator_chip_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Wire rows into the list builder**

In `lib/pages/chat/message/messages_list.dart`, replace the per-message grouping computation (lines ~256–289) and the item indexing with the row model. Concretely:

Add import at top:
```dart
import 'package:bananatalk_app/pages/chat/message/chat_row.dart';
import 'package:bananatalk_app/pages/chat/message/date_separator_chip.dart';
```

Before the `ListView.builder`, build rows once:
```dart
final rows = buildChatRows(messages);
final headerCount = hasHeader ? 1 : 0;
final totalItems = headerCount + rows.length + (isLoadingMore ? 1 : 0);
```

In `itemBuilder`, after the header (index 0) and loading-more tail checks, resolve the row:
```dart
final rowIndex = index - headerCount;
if (rowIndex < 0 || rowIndex >= rows.length) return const SizedBox.shrink();
final row = rows[rowIndex];
if (row is DateSeparatorRow) {
  return DateSeparatorChip(day: row.day);
}
final messageRow = row as MessageRow;
final message = messageRow.message;
final isMe = message.sender.id == currentUserId;
final isFirstInGroup = messageRow.isFirstInGroup;
final isLastInGroup = messageRow.isLastInGroup;
```
Then keep the existing `correction` / `call` branches and the `ChatMessageBubble(...)` construction unchanged, but delete the old inline `prevIndex/nextIndex` grouping block (now provided by `messageRow`). The group-mode sender-name header block (line ~333) stays as-is.

- [ ] **Step 6: Verify build + analyze**

Run: `flutter analyze lib/pages/chat/message/messages_list.dart lib/pages/chat/message/date_separator_chip.dart lib/pages/chat/message/chat_row.dart`
Expected: No issues found.

- [ ] **Step 7: Commit (staging checkpoint)**

```bash
git add lib/pages/chat/message/date_separator_chip.dart test/chat/date_separator_chip_test.dart lib/pages/chat/message/messages_list.dart
git commit -m "feat(chat): render date separators between message groups"
```

---

## Task 3: Backend — `delivered` field + `messageDelivered` emit

**Files (backend repo):**
- Modify: `models/Message.js` (add `delivered` field)
- Modify: the socket handler that routes `newMessage` to recipients (e.g. `socket/` or `controllers/messages.js` socket section) — persist `delivered` + emit `messageDelivered`
- Modify: recipient reconnect / backlog path — stamp + emit for undelivered

**Interfaces:**
- Produces socket event `messageDelivered` with payload `{ messageId, conversationId }`, emitted to the **sender's** room.

- [ ] **Step 1: Add schema field**

In `models/Message.js`, add to the schema:
```js
delivered: { type: Boolean, default: false },
```

- [ ] **Step 2: Persist + emit on live delivery**

Where the server emits `newMessage` to a connected recipient socket, add (idempotent — only when currently false):
```js
if (!message.delivered) {
  message.delivered = true;
  await message.save();
}
io.to(senderRoomId).emit('messageDelivered', {
  messageId: message._id.toString(),
  conversationId,
});
```
(Use the project's existing room-id helper for `senderRoomId`; mirror how `messageRead` targets rooms.)

- [ ] **Step 3: Stamp backlog on reconnect**

In the recipient reconnect / backlog-fetch path, for each still-undelivered message addressed to the reconnecting user, set `delivered = true`, save, and emit `messageDelivered` to that message's sender room. Batch the DB update (`updateMany`) and emit per affected sender.

- [ ] **Step 4: Verify**

Run backend syntax check: `node --check models/Message.js` and the socket file.
Manual: send a message to an online recipient; confirm the sender receives `messageDelivered`. Restart recipient; confirm backlog delivered events fire.

- [ ] **Step 5: Commit (staging checkpoint, backend repo)**

```bash
git add models/Message.js <socket-file>
git commit -m "feat(chat): emit messageDelivered + persist delivered flag"
```

---

## Task 4: Client — `Message.delivered` model field

**Files:**
- Modify: `lib/providers/provider_models/message_model.dart` (field ~53 area, `fromJson` ~146, `copyWith` ~351, `toJson` ~318)
- Test: `test/chat/message_delivered_test.dart`

**Interfaces:**
- Produces: `final bool delivered;` on `Message`; parsed from `json['delivered']`; threaded through `copyWith`/`toJson`.

- [ ] **Step 1: Write the failing test**

```dart
// test/chat/message_delivered_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

Map<String, dynamic> _base(Map<String, dynamic> extra) => {
      'id': '1',
      'sender': {'_id': 'a', 'name': 'U', 'images': []},
      'receiver': {'_id': 'b', 'name': 'O', 'images': []},
      'message': 'hi',
      'createdAt': '2026-07-18T09:00:00.000Z',
      'type': 'text',
      'read': false,
      'reactions': [],
      'translations': [],
      'corrections': [],
      'mentions': [],
      ...extra,
    };

void main() {
  test('delivered defaults false when absent', () {
    expect(Message.fromJson(_base({})).delivered, false);
  });
  test('delivered parses true', () {
    expect(Message.fromJson(_base({'delivered': true})).delivered, true);
  });
  test('copyWith updates delivered', () {
    final m = Message.fromJson(_base({}));
    expect(m.copyWith(delivered: true).delivered, true);
  });
  test('toJson round-trips delivered', () {
    final m = Message.fromJson(_base({'delivered': true}));
    expect(Message.fromJson(m.toJson()).delivered, true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat/message_delivered_test.dart`
Expected: FAIL — no named parameter `delivered` / getter missing.

- [ ] **Step 3: Implement the field**

In `message_model.dart`:
- Add field near `read` (line ~53): `final bool delivered;`
- Add to the constructor params: `this.delivered = false,`
- In `fromJson` (~146): `delivered: json['delivered'] ?? false,`
- In `copyWith` params add `bool? delivered,` and in its body `delivered: delivered ?? this.delivered,`
- In `toJson` (~318) add `'delivered': delivered,`
- In `copyWithStatus` (~85), preserve `delivered: delivered,` when reconstructing.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat/message_delivered_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit (staging checkpoint)**

```bash
git add lib/providers/provider_models/message_model.dart test/chat/message_delivered_test.dart
git commit -m "feat(chat): add delivered flag to Message model"
```

---

## Task 5: Client — `messageDelivered` socket stream + state wiring

**Files:**
- Modify: `lib/services/chat_socket_service.dart` (~44 controllers, ~91 stream getters, ~428 `.on` handlers)
- Modify: `lib/services/chat_socket_state_manager.dart` (~19 subs, ~39 callbacks, ~208 subscriptions)
- Modify: `lib/pages/chat/state/chat_state_provider.dart` (~127 `onMessagesRead` block)

**Interfaces:**
- Consumes: `Message.delivered` (Task 4).
- Produces:
  - `chat_socket_service`: `Stream<dynamic> get onMessageDelivered`
  - `chat_socket_state_manager`: `Function(String messageId)? onMessageDelivered`
  - `chat_state_provider`: flips `delivered` on the matching message in state.

- [ ] **Step 1: Add stream to socket service**

In `chat_socket_service.dart`, beside `_messageReadController`:
```dart
final _messageDeliveredController = StreamController<dynamic>.broadcast();
```
Beside `onMessageRead`:
```dart
Stream<dynamic> get onMessageDelivered => _messageDeliveredController.stream;
```
In the `.on` setup block (beside `messageRead` ~428):
```dart
_socket?.on('messageDelivered', (data) {
  _safeAdd(_messageDeliveredController, data);
});
```
And close the controller wherever `_messageReadController` is closed (dispose).

- [ ] **Step 2: Add callback + subscription to the state manager**

In `chat_socket_state_manager.dart`:
- Beside `_messageReadSub` (~19): `StreamSubscription? _messageDeliveredSub;`
- Beside `onMessagesRead` (~39): `Function(String messageId)? onMessageDelivered;`
- In `_setupSubscriptions` beside the `messageRead` subscription (~208):
```dart
_messageDeliveredSub = _socketService.onMessageDelivered.listen((data) {
  final id = data is Map ? (data['messageId']?.toString()) : null;
  if (id != null) onMessageDelivered?.call(id);
});
```
- Cancel `_messageDeliveredSub` in `dispose()` alongside the others.

- [ ] **Step 3: Handle it in the conversation state**

In `chat_state_provider.dart`, after the `onMessagesRead` block (~137):
```dart
_socketManager!.onMessageDelivered = (messageId) {
  final messages = state.messages.map((msg) {
    if (msg.id == messageId && !msg.delivered && !msg.read) {
      return msg.copyWith(delivered: true);
    }
    return msg;
  }).toList();
  state = state.copyWith(messages: messages);
};
```

- [ ] **Step 4: Verify build + analyze**

Run: `flutter analyze lib/services/chat_socket_service.dart lib/services/chat_socket_state_manager.dart lib/pages/chat/state/chat_state_provider.dart`
Expected: No issues found.

- [ ] **Step 5: Commit (staging checkpoint)**

```bash
git add lib/services/chat_socket_service.dart lib/services/chat_socket_state_manager.dart lib/pages/chat/state/chat_state_provider.dart
git commit -m "feat(chat): wire messageDelivered socket event into conversation state"
```

---

## Task 6: Client — 4-state tick rendering (`tickIconFor` + bubble)

**Files:**
- Create: `lib/pages/chat/message/tick_status.dart`
- Modify: `lib/pages/chat/message/message_bubble.dart` (status row ~1369–1381)
- Test: `test/chat/tick_status_test.dart`

**Interfaces:**
- Consumes: `Message` (`sendingStatus`, `delivered`, `read`).
- Produces: `enum TickRole { none, sent, delivered, read }` and `TickRole tickRoleFor(Message m)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/chat/tick_status_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/chat/message/tick_status.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

Message _m({bool delivered = false, bool read = false}) => Message.fromJson({
      'id': '1',
      'sender': {'_id': 'a', 'name': 'U', 'images': []},
      'receiver': {'_id': 'b', 'name': 'O', 'images': []},
      'message': 'hi',
      'createdAt': '2026-07-18T09:00:00.000Z',
      'type': 'text',
      'read': read,
      'delivered': delivered,
      'reactions': [],
      'translations': [],
      'corrections': [],
      'mentions': [],
    });

void main() {
  test('sent when neither delivered nor read', () {
    expect(tickRoleFor(_m()), TickRole.sent);
  });
  test('delivered when delivered but not read', () {
    expect(tickRoleFor(_m(delivered: true)), TickRole.delivered);
  });
  test('read wins over delivered', () {
    expect(tickRoleFor(_m(delivered: true, read: true)), TickRole.read);
  });
  test('read even if delivered flag missing', () {
    expect(tickRoleFor(_m(read: true)), TickRole.read);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat/tick_status_test.dart`
Expected: FAIL — `tick_status.dart` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/pages/chat/message/tick_status.dart
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// Delivery tick state for one of the current user's own messages, used to
/// pick the check-mark icon + color. Only meaningful when
/// `sendingStatus == MessageSendingStatus.none`.
enum TickRole { none, sent, delivered, read }

TickRole tickRoleFor(Message m) {
  if (m.read) return TickRole.read;
  if (m.delivered) return TickRole.delivered;
  return TickRole.sent;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat/tick_status_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Use it in the bubble**

In `message_bubble.dart`, replace the read-only icon (lines ~1369–1381) with a 4-state mapping. Add import:
```dart
import 'package:bananatalk_app/pages/chat/message/tick_status.dart';
```
Replace the block:
```dart
if (widget.message.sendingStatus == MessageSendingStatus.none) ...[
  Spacing.hGapXXS,
  Builder(builder: (_) {
    final role = tickRoleFor(widget.message);
    final isRead = role == TickRole.read;
    return Icon(
      role == TickRole.sent ? Icons.done : Icons.done_all,
      size: 14,
      color: isRead ? _myMessageColor(context) : _timestampColor(context),
    );
  }),
],
```
(So: sent → `done` grey; delivered → `done_all` grey; read → `done_all` primary.)

- [ ] **Step 6: Verify analyze**

Run: `flutter analyze lib/pages/chat/message/tick_status.dart lib/pages/chat/message/message_bubble.dart`
Expected: No issues found.

- [ ] **Step 7: Commit (staging checkpoint)**

```bash
git add lib/pages/chat/message/tick_status.dart test/chat/tick_status_test.dart lib/pages/chat/message/message_bubble.dart
git commit -m "feat(chat): 4-state delivery ticks (sent/delivered/read)"
```

---

## Task 7: Backend — `chat` unlock catalog key

**Files (backend repo):**
- Modify: `config/coinCatalog.js` (add `chat` entry)
- Modify: `controllers/coins.js` unlock handler (grant "N more messages today" for `chat`)

**Interfaces:**
- Produces: catalog key `chat` returned by `GET /coins/unlock-catalog`; `POST /coins/unlock` `{featureKey:'chat'}` debits coins and raises the caller's daily message allowance for the current UTC day.

- [ ] **Step 1: Add catalog entry**

In `config/coinCatalog.js`, add (mirroring `moment`):
```js
chat: { cost: <coins>, grant: <extraMessages>, label: 'Extra messages today' },
```
(Use the same cost convention as the existing `moment` entry; confirm values with product before finalizing.)

- [ ] **Step 2: Grant on unlock**

In the unlock handler, add a `chat` branch that, after debiting coins, raises the user's daily message counter/allowance for the current UTC day — reuse the same per-UTC-day mechanism the message-limit check reads. Idempotency: rely on the existing coin-debit ledger idempotency.

- [ ] **Step 3: Verify**

Run: `node --check config/coinCatalog.js controllers/coins.js`
Manual: `GET /coins/unlock-catalog` includes `chat`; unlocking `chat` reduces balance and raises the daily message allowance.

- [ ] **Step 4: Commit (staging checkpoint, backend repo)**

```bash
git add config/coinCatalog.js controllers/coins.js
git commit -m "feat(coins): add chat (extra messages) unlock catalog key"
```

---

## Task 8: Client — message-limit → coin CTA mapping (C1)

**Files:**
- Modify: `lib/widgets/limit_exceeded_dialog.dart` (`_featureKeyForUnlock` ~96–104)

**Interfaces:**
- Consumes: backend `chat` catalog key (Task 7); existing `UnlockCta` in the dialog.

- [ ] **Step 1: Map the messages limit type**

In `_featureKeyForUnlock()`, add before `default`:
```dart
case 'message':
case 'messages':
  return 'chat';
```
No other change needed — the dialog already renders `UnlockCta(featureKey, onUnlocked)` and the conversation send path invokes the dialog with `limitType: 'messages'` (see `chat_conversation_screen.dart:818`). The CTA renders nothing if the `chat` key is absent (dark-launch safe).

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/widgets/limit_exceeded_dialog.dart`
Expected: No issues found.

- [ ] **Step 3: Manual check**

With `coinsEnabled` true and a `chat` catalog key present, hit the daily message cap → the dialog shows "Unlock … for 💎X" beside Go VIP; unlocking retries the send.

- [ ] **Step 4: Commit (staging checkpoint)**

```bash
git add lib/widgets/limit_exceeded_dialog.dart
git commit -m "feat(coins): offer coin unlock when daily message cap is hit"
```

---

## Task 9: Client — translate-limit coin CTA in-conversation (C2)

**Files:**
- Create: `lib/pages/chat/dialogs/translate_unlock_sheet.dart`
- Modify: the in-conversation translate call site (find via `grep -rn "translate\|translation" lib/pages/chat/conversation lib/pages/chat/header/auto_translate_toggle.dart`) to catch the limit/429 and present the sheet.

**Interfaces:**
- Consumes: existing `translation` catalog key + `UnlockCta`.
- Produces: `Future<bool> showTranslateUnlockSheet(BuildContext context)` — resolves `true` if the user unlocked (caller retries translation).

- [ ] **Step 1: Create the sheet**

```dart
// lib/pages/chat/dialogs/translate_unlock_sheet.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Bottom sheet shown when auto-translate hits its daily cap in a
/// conversation. Offers the à-la-carte coin unlock (translation key).
/// Returns true when the user successfully unlocked.
Future<bool> showTranslateUnlockSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Translation limit reached',
              style: context.titleMedium),
          const SizedBox(height: 8),
          Text('Unlock more translations with coins.',
              style: context.bodyMedium.copyWith(color: context.textSecondary)),
          const SizedBox(height: 16),
          UnlockCta(
            featureKey: 'translation',
            onUnlocked: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
```

- [ ] **Step 2: Present on translate limit**

At the translate call site, when the translate request fails with the limit/429 signal, call:
```dart
final unlocked = await showTranslateUnlockSheet(context);
if (unlocked) {
  // retry the translation for the same message
}
```
Gate the whole path on `AppConfig.coinsEnabled` (read via the existing app-config provider); if coins are off, keep the current behavior (e.g. the existing VIP/limit message).

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/pages/chat/dialogs/translate_unlock_sheet.dart <edited-call-site-file>`
Expected: No issues found.

- [ ] **Step 4: Commit (staging checkpoint)**

```bash
git add lib/pages/chat/dialogs/translate_unlock_sheet.dart <edited-call-site-file>
git commit -m "feat(coins): offer coin unlock when chat auto-translate cap is hit"
```

---

## Task 10: Client — coin balance pill in chat header (C4)

**Files:**
- Modify: `lib/pages/chat/header/chat_app_bar.dart` (`actions` list ~335)

**Interfaces:**
- Consumes: existing `CoinBalancePill` (`lib/widgets/coins/coin_balance_pill.dart`, ctor `CoinBalancePill({onTap, onLight})`), `AppConfig.coinsEnabled`.

- [ ] **Step 1: Add the pill (gated)**

Add import:
```dart
import 'package:bananatalk_app/widgets/coins/coin_balance_pill.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
```
In `build`, read the flag:
```dart
final coinsEnabled = ref.watch(appConfigProvider).valueOrNull?.coinsEnabled ?? false;
```
(Confirm the exact provider/getter name in `app_config_providers.dart`; match how `UnlockCta` reads it.)
Prepend to `actions` (before the video-call button):
```dart
if (coinsEnabled)
  Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Center(child: CoinBalancePill()),
  ),
```

- [ ] **Step 2: Verify analyze + layout**

Run: `flutter analyze lib/pages/chat/header/chat_app_bar.dart`
Expected: No issues found.
Manual: verify the header doesn't overflow with the pill + two call buttons + options menu, with a long partner name, in light and dark mode.

- [ ] **Step 3: Commit (staging checkpoint)**

```bash
git add lib/pages/chat/header/chat_app_bar.dart
git commit -m "feat(coins): show coin balance pill in chat header"
```

---

## Task 11 (PHASE 2): Backend — `wallpaper` unlock key + entitlement

**Files (backend repo):**
- Modify: `config/coinCatalog.js` (add `wallpaper` entry)
- Modify: `controllers/coins.js` unlock handler (persist durable wallpaper entitlement)
- Modify: user model / entitlements to expose unlocked state to the client

**Interfaces:**
- Produces: catalog key `wallpaper`; `POST /coins/unlock` `{featureKey:'wallpaper'}` persists a durable (not per-day) entitlement; the client can read whether the pack is unlocked (via user profile / entitlements payload).

- [ ] **Step 1: Add catalog entry** — `wallpaper: { cost: <coins>, label: 'Premium wallpapers' }`.
- [ ] **Step 2: Persist entitlement** — on unlock, add `wallpaper` to the user's durable unlocked-features set (idempotent).
- [ ] **Step 3: Expose entitlement** — include unlocked features in the profile/entitlements response the client already fetches.
- [ ] **Step 4: Verify** — `node --check`; unlocking `wallpaper` persists across sessions and appears in the client-visible entitlements.
- [ ] **Step 5: Commit (staging checkpoint, backend repo)**

```bash
git add config/coinCatalog.js controllers/coins.js <user-model/entitlements-file>
git commit -m "feat(coins): add premium wallpaper unlock entitlement"
```

---

## Task 12 (PHASE 2): Client — premium wallpapers in picker

**Files:**
- Add: premium wallpaper assets under `assets/` (register in `pubspec.yaml`)
- Modify: `lib/pages/chat/wallpaper/wallpaper_picker_screen.dart`

**Interfaces:**
- Consumes: `wallpaper` catalog key + entitlement (Task 11); `UnlockCta` or direct `CoinApiClient.unlock('wallpaper')`.

- [ ] **Step 1: Add + register assets**

Place a finite premium pack under `assets/wallpapers/premium/` and add the folder to `pubspec.yaml` `flutter/assets`. Run `flutter pub get`.

- [ ] **Step 2: Show locked premium items**

In the picker, render premium wallpapers with a lock overlay + `💎 X` price badge (price from `coinUnlockCatalogProvider['wallpaper']`). Only show premium items when `coinsEnabled` and the `wallpaper` key exists; otherwise show only the free wallpapers (unchanged).

- [ ] **Step 3: Unlock on tap**

Tapping a locked premium wallpaper triggers the coin unlock; on success (entitlement flips), remove the lock and allow selection. Selecting an unlocked premium wallpaper behaves exactly like the free ones today.

- [ ] **Step 4: Verify analyze + build**

Run: `flutter analyze lib/pages/chat/wallpaper/wallpaper_picker_screen.dart`
Then: `flutter build ios --simulator --debug` (integration sanity for the whole feature set).
Expected: analyze clean; build succeeds.

- [ ] **Step 5: Commit (staging checkpoint)**

```bash
git add pubspec.yaml assets/wallpapers/premium lib/pages/chat/wallpaper/wallpaper_picker_screen.dart
git commit -m "feat(coins): coin-unlockable premium chat wallpapers"
```

---

## Self-Review notes

- **Spec coverage:** P1 → Tasks 1–2; F1 → Tasks 3–6; C1 → Tasks 7–8; C2 → Task 9; C4 → Task 10; C3 (phase 2) → Tasks 11–12. All spec sections covered.
- **Type consistency:** `buildChatRows`/`ChatRow`/`DateSeparatorRow`/`MessageRow` (Task 1) reused verbatim in Task 2. `Message.delivered` (Task 4) consumed in Tasks 5 & 6. `tickRoleFor`/`TickRole` (Task 6) defined and used in one task. Socket names `messageDelivered` / `onMessageDelivered` consistent across service (Task 5 step 1), state manager (step 2), provider (step 3), and backend emit (Task 3).
- **Dark-launch:** every coin task no-ops without its catalog key / `coinsEnabled` (Tasks 8, 9, 10, 12).
- **Verify-before-use flags:** `context.surfaceVariantColor` (Task 2), `appConfigProvider.coinsEnabled` getter name (Task 10) — both call for confirming the exact existing symbol before running.
