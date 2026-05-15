# Step 19 — Real Chat (Recon)

Date: 2026-05-15
Branch: (planning) — execute on `feat/step19-real-chat`

## TL;DR

The BananaTalk chat system is **~95% feature-complete** and thoroughly over-engineered for a v1 language-exchange app. Almost every feature (corrections, translations, reactions, disappearing messages, polls, bookmarks, typing indicators, online presence, full-text search, media, socket event streaming) has a fully-formed schema, backend endpoint, socket event, and Flutter widget. The gaps are narrow but specific:

1. **Group chat**: schema + static methods present, zero UX endpoints or Flutter screens
2. **@mentions**: schema + read endpoint present, write-side parsing unconfirmed, no notification
3. **Socket rate limiting**: REST is rate-limited but socket `sendMessage` is not
4. **Pinned message list**: pin/unpin endpoints exist, no `GET /pinned` endpoint
5. **Message drafts**: no persistence anywhere
6. **Disappearing messages + Polls**: backend complete; Flutter UI unverified
7. **Production log smell**: REST message create has debug socket room logs at line 732–735

---

## 1. Message Model (models/Message.js)

Full schema — every field documented:

| Group | Fields |
|---|---|
| **Core** | `sender`, `receiver`, `participants`, `message` (max 2000), `messageType` (text\|media\|voice\|poll\|location\|contact\|sticker\|system\|call\|gif), `createdAt`, `updatedAt` |
| **Read** | `read`, `readAt`, `readBy[]` |
| **Media** | `media.{url, type, thumbnail, fileName, fileSize, mimeType, duration, dimensions, waveform, location, callData}` |
| **Corrections** | `corrections[].{corrector, originalText, correctedText, explanation, createdAt, isAccepted}` |
| **Translations** | `translations[].{language, translatedText, transliteration, breakdown, translatedAt, provider}` |
| **Reactions** | `reactions[].{user, emoji}` (one per user) |
| **Replies** | `replyTo` (ObjectId → Message) |
| **Forward** | `forwardedFrom.{sender, messageId, originalMessage}`, `isForwarded` |
| **Disappearing** | `selfDestruct.{enabled, expiresAt, destructAfterRead, destructTimer, destructAt}` |
| **Mentions** | `mentions[].{user, username, startIndex, endIndex}` |
| **Story → DM** | `storyReference.{storyId, thumbnail}` |
| **Pinning** | `pinned`, `pinnedAt`, `pinnedBy` |
| **Poll** | `poll` (ObjectId → Poll) |
| **Schedule** | `isScheduled`, `scheduledFor` |
| **Edit** | `isEdited`, `editedAt` |
| **Soft delete** | `isDeleted`, `deletedAt`, `deletedFor[]` |

**Indexes:** `sender+receiver+createdAt`, `receiver+read`, `participants+createdAt`, `$text` on `message`.

**Key static methods:** `getConversation()`, `markAsRead()`, `getMessagesWithCorrections()`, `cleanupExpiredMessages()`.

**Key instance methods:** `addCorrection()`, `acceptCorrection()`, `addTranslation()`, `getTranslation()`, `parseMentions()`.

---

## 2. Backend endpoints — complete map

### messages.js (basic CRUD)
- `POST /api/v1/conversations` — create/get conversation
- `GET /api/v1/conversations` — all conversations (aggregation with unread, pinned, muted)
- `GET /api/v1/messages` — paginated message list
- `POST /api/v1/messages` — create message (text + media + location + reply + forward); emits `newMessage` socket to receiver and `messageSent` to sender's other devices
- `GET /api/v1/messages/:id` — single message
- `GET /api/v1/messages/user/:userId` — all messages for user
- `GET /api/v1/messages/senders/:userId` — conversation list (aggregation: unread count, pinned, muted)
- `GET /api/v1/messages/conversation/:senderId/:receiverId` — paginated thread (oldest→newest)
- `DELETE /api/v1/messages/:id` — hard delete + DigitalOcean Spaces cleanup

### messageManagement.js
- `PUT /api/v1/messages/:id` — edit message (15-min window); emits `messageEdited`
- `DELETE /api/v1/messages/:id` — soft delete with `deleteForEveryone` flag; emits `messageDeleted`
- `POST /api/v1/messages/:id/reply` — reply chain
- `POST /api/v1/messages/:id/forward` — forward with attribution
- `POST /api/v1/messages/:id/pin` — pin message
- `GET /api/v1/messages/:id/replies` — fetch replies

### messageReactions.js
- `POST /api/v1/messages/:id/reactions` — add reaction; emits `messageReaction` to sender + receiver
- `DELETE /api/v1/messages/:id/reactions/:emoji` — remove reaction
- `GET /api/v1/messages/:id/reactions` — all reactions

### advancedMessages.js
| Category | Endpoints |
|---|---|
| Corrections | POST `/:id/correct`, GET `/:id/corrections`, PUT `/:id/corrections/:cid/accept` |
| Translation | POST `/:id/translate` (word-by-word breakdown, daily limit, cache), GET `/:id/translations`, POST `/:id/tts` |
| Save vocab | POST `/:id/vocabulary` |
| Video | POST `/video` (max 10min, 1GB, thumbnail generation), GET `/video-config` |
| Voice | POST `/voice` (waveform stored, duration extracted server-side) |
| Disappearing | POST `/disappearing`, POST `/:id/trigger-destruct` |
| Polls | POST `/poll`, POST `/poll/:id/vote`, GET `/poll/:id`, POST `/poll/:id/close` |
| Mentions | GET `/mentions` |
| Bookmarks | POST `/:id/bookmark`, DELETE `/:id/bookmark`, GET `/bookmarks` |
| Conversation UX | PUT `/conversations/:id/theme`, GET `/conversations/:id/theme`, PUT `/conversations/:id/nickname`, POST `/conversations/:id/secret`, POST/GET `/conversations/:id/quick-replies` |

### messageSearch.js
- `GET /api/v1/messages/search` — full-text ($text index) + regex on fileName; filters: conversationId, mediaType, hasMedia, isPinned, dateFrom, dateTo; paginated

---

## 3. Socket.IO event map (socketHandler.js)

### Authentication & Lifecycle
- JWT auth middleware on connect (line 111)
- Multi-device: max 5 connections per user, deviceId tracked (line 38, 340)
- Token expiry warning 5min before, disconnect on expiry (line 142)
- Heartbeat ping/pong every 30s, 4 missed = disconnect (line 399)
- Grace period: 10s window before marking offline (line 1493)
- Offline queue: max 50 messages per user, 24h TTL (line 1654)

### Message events
| Event | Direction | Notes |
|---|---|---|
| `sendMessage` | C→S | 5-phase pipeline: fast validation → parallel DB (cache, block, first-chat limit, count) → create → immediate ACK → background delivery. Checks block + first-chat 5-msg limit + daily limit (line 647) |
| `newMessage` | S→C | To receiver room with unreadCount, mediaType (line 738) |
| `messageSent` | S→C | Sync to sender's other devices (line 747) |
| `markAsRead` | C→S | Marks as read, decrements badge, emits `messagesRead` to sender (line 876) |
| `messagesRead` | S→C | Notifies sender of read receipt |
| `deleteMessage` | C→S | Emits `messageDeleted` to receiver (line 953) |

### Typing & presence
| Event | Direction | Notes |
|---|---|---|
| `typing` / `stopTyping` | C→S | 5s auto-clear timeout (line 1116) |
| `userTyping` / `userStoppedTyping` | S→C | Broadcast to receiver |
| `updateStatus` | C→S | online\|away\|busy\|offline |
| `userStatusUpdate` | S→C | Broadcast to all |
| `getUserStatus` | C→S | Single-user query, cache-first |
| `requestStatusUpdates` | C→S | Batch query |
| `presence:online/offline/bulk` | S→C | Interested subscribers only (followers + conversation partners, capped 200) |

### Corrections, reactions, voice, polls, disappearing — all have full socket handlers

---

## 4. Flutter chat screens

### Conversation list
- `pages/chat/list/chat_list_screen.dart` — filter tabs (all/unread/online), search, unread badge
- `list/chat_list_tile.dart` — last message, timestamp, unread badge, online dot
- `list/list_socket_handlers.dart` — `newMessage`, `typing`, `statusUpdate` listeners

### Chat thread
- `pages/chat/conversation/chat_conversation_screen.dart` — main thread
- `conversation/conversation_header.dart` — user name, online status, typing indicator
- `conversation/conversation_messages_view.dart` — paginated scroll
- `conversation/conversation_input_area.dart` — text + media + emoji + sticker

### Message bubbles
- `message/message_bubble.dart` — swipe-to-reply, long-press menu, animation
- `message/message_bubble/text_message_view.dart`
- `message/message_bubble/image_message_view.dart`
- `message/message_bubble/voice_message_view.dart` — waveform visualization
- `message/message_bubble/gif_message_view.dart`
- `message/typing_indicator.dart` — animated dots
- `message/pinned_messages_bar.dart` — pinned message preview
- `message/correction_message_bubble.dart` — HelloTalk correction display
- `message/forwarded_message_indicator.dart`
- `message/bubble_actions_menu.dart` — reply, edit, delete, pin, forward, correct, translate, bookmark, react

### Input
- `input/chat_input_bar.dart`, `chat_input_section.dart`
- `panels/chat_media_panel.dart`, `chat_sticker_panel.dart`, `gif_picker_panel.dart`

### Utility screens
- `search/chat_search_screen.dart` — full-text search within conversations
- `bookmarks/bookmarks_screen.dart` — saved messages

### Providers
- `providers/message_provider.dart` — message state, pagination, optimistic updates
- `providers/chat_state_provider.dart` — active conversation, typing users, online users
- `providers/message_count_provider.dart` — unread counts per conversation
- `providers/global_chat_listener.dart` — centralized socket subscription

---

## 5. Feature completeness matrix

| Feature | Backend | Flutter | Status | Notes |
|---|---|---|---|---|
| Core CRUD | ✅ | ✅ | Complete | |
| Media (img/video/voice/doc) | ✅ | ✅ | Complete | Verify video duration middleware |
| Corrections (HelloTalk) | ✅ | ✅ | Complete | |
| Reactions | ✅ | ✅ | Complete | |
| Translations + word breakdown | ✅ | ✅ | Complete | Daily limit, VIP bypass |
| Bookmarks | ✅ | ✅ | Complete | |
| Typing indicators | ✅ | ✅ | Complete | |
| Online presence | ✅ | ✅ | Complete | 10s grace period |
| Unread badges | ✅ | ✅ | Complete | Message + conversation level |
| Full-text search | ✅ | ✅ | Complete | |
| Message pinning | ✅ | ✅ | Partial | No list endpoint |
| Reply chain | ✅ | ✅ | Complete | |
| Forward | ✅ | ✅ | Complete | |
| Edit (15-min window) | ✅ | ✅ | Complete | |
| Soft delete | ✅ | ✅ | Complete | |
| Disappearing messages | ✅ | ❓ | Partial | Flutter UI unverified |
| Polls | ✅ | ❓ | Partial | Flutter UI unverified |
| Story → DM | ✅ | ❓ | Partial | Flutter UI unverified |
| @mentions | ⚠️ | ❓ | Partial | No write-side parse + no notification |
| Group chat | ⚠️ | ❌ | Stubbed | Schema only, zero UX |
| Socket rate limiting | ❌ | — | Missing | REST is protected, socket is not |
| Pinned messages list | ❌ | — | Missing | No GET /pinned endpoint |
| Message drafts | ❌ | ❌ | Missing | |
| Message edit history | ❌ | — | Missing | Schema tracks isEdited, not history |
| E2E encryption | ❌ | ❌ | Stubbed | Secret chat has no real crypto |
| Call records | ⚠️ | ❌ | Stubbed | Schema placeholder |

---

## 6. Gap analysis — prioritized

### P0 — Production risks
1. **Socket `sendMessage` has no per-second rate limit** — REST has `messageLimiter` middleware (routes/messages.js:34); socket path is unprotected. Socket spam can flood DB and exhaust server resources.
2. **Debug logs in production** — messages.js:732–735 logs socket room membership per message. Verbose in production, but minor.

### P1 — Missing features with direct user impact
3. **@mentions auto-parse + notification** — Schema + `parseMentions()` method exist. Call site (`POST /api/v1/messages`) doesn't call `parseMentions()`. Users @tagging each other get no notification and mentions don't persist in the array. The `GET /mentions` endpoint returns empty for everyone.
4. **Pinned messages list** — `POST /:id/pin` works but there's no `GET /conversations/:id/pinned` or `GET /messages?pinned=true` (the search endpoint supports `isPinned=true` but returns all messages, not just pinned in a conversation).
5. **Message drafts (local)** — No persistence on navigate-away. Flutter-only: SharedPreferences or Riverpod state per conversation key.

### P2 — Unverified Flutter UIs
6. **Disappearing messages Flutter** — Backend complete. Flutter UI existence uncertain; if it exists, verify the destruct countdown timer widget and `triggerSelfDestruct` call.
7. **Polls Flutter** — Backend complete. Verify vote UI, poll result display, close-poll action.
8. **Story → DM Flutter** — Schema present. Verify that story reply tap navigates to chat with storyReference bubble rendering correctly.

### P3 — Low impact / nice-to-have
9. **Waveform server-side generation fallback** — Backend stores waveform array sent by client; no server-side compute if client doesn't send one. Most users see flat waveform.
10. **Group chat** — Full infrastructure present. Building group chat UX is a standalone wave of work (separate design needed).
11. **Mention notification** — Depends on P1 @mentions write-side fix.

---

## 7. Design decisions for the wave

### DD1 — Scope: stability + P1 gaps, not group chat
Group chat (despite full schema) is a standalone wave — it requires new screens, group management UX, and multiple new endpoints. This wave focuses on making the existing 1:1 chat production-solid.

**In scope:**
- Socket rate limiting (P0)
- @mentions write-side: auto-parse on create + push notification (P1)
- Pinned messages list endpoint (P1)
- Message drafts (local persistence, Flutter-only) (P1)
- Disappearing messages + Polls Flutter verification + fixes (P2)
- Story → DM verification (P2)

**Rejected — group chat in this wave:** Separate design doc needed. Adds 5–7 new endpoints + 3–4 new Flutter screens. Don't conflate with stability work.

**Rejected — E2E encryption:** Significant cryptographic undertaking. Out of scope.

### DD2 — Socket rate limiting: in-memory token bucket per user
Use a `Map<userId, { tokens, lastRefill }>` token bucket in socketHandler.js: refill 1 token/second, max burst 10. On `sendMessage`, check bucket before DB ops. Fits existing socketHandler pattern; no new Redis dependency.

**Rejected — Redis-backed rate limit:** Correct for multi-node, but this is a single-node backend. In-memory is simpler and sufficient.

### DD3 — @mentions: parse on REST create, not socket
`POST /api/v1/messages` (messages.js) is the canonical create path. Add `parseMentions()` call after message is created. Socket `sendMessage` already delegates to a shared createMessage path; if it does, one change covers both.

### DD4 — Drafts: Riverpod in-memory per conversation (no backend)
Per-conversation draft stored in a `StateProvider<Map<String, String>>` keyed by otherUserId. Persists across screen navigations within the app session. No SharedPreferences for v1 — ephemeral state is fine.

---

## 8. Smoke checklist

- [ ] Socket spam test: send 20 messages in 1s via socket — 11th+ should be throttled, no DB flood
- [ ] Send a message with "@username text" → Vocabulary.parseMentions() fires → `mentions` array populated → mentioned user gets push notification
- [ ] Pin 2 messages → `GET /conversations/:id/pinned` returns both in order
- [ ] Navigate away from chat mid-sentence → return → draft text restored
- [ ] (Disappearing) Enable disappearing mode → send a message → receiver opens → countdown starts → message disappears
- [ ] (Poll) Create a poll in chat → receiver votes → poll result updates in real-time
- [ ] (Story→DM) Reply to a story → opens DM thread → message bubble shows story thumbnail
