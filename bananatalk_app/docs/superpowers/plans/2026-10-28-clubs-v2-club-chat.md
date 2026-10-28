# Clubs v2, slice 2: club chat — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every club gets one members-only group chat, with an organizer notice (공지) at the top, built on the existing rooms system and visible only to clubs v2 users.

**Architecture:** A club chat is a `Conversation` with `roomType: 'club'` and a new `club` ref, created lazily the first time a member opens it (so existing clubs get one with no migration). `Club.members` stays the single source of truth: access checks read the club, and one helper rewrites the room's `participants/owner/admins` from the club after every membership change. Club rooms are hidden from every room list and refuse the public join paths. The app reuses the room screen at `/room/:id`.

**Tech Stack:** as slice 1 (Node/Express/Mongoose + `node --test`; Flutter/Riverpod + `flutter_test`).

**Spec:** `docs/moim-plan.md` Phase 2 "Club chat"; slice 1 plan `docs/superpowers/plans/2026-10-28-clubs-v2-rules-warnings.md` (access switch, bans).

## Global Constraints

- Stacks on slice 1: backend branch `feat/clubs-v2-chat` off `feat/clubs-v2-rules` (worktree `/Users/davis/Desktop/Personal/be-clubs-v2`), app branch `feat/clubs-v2-chat` off app `feat/clubs-v2-rules`.
- Prod must not change for anyone without clubs v2 access: club rooms are only created through the new v2-only endpoint, so no `roomType: 'club'` document exists until a test user opens a chat; every rooms list, DM list and public join path must ignore club rooms.
- `controllers/gatherings.js` / `models/Gathering.js` untouched (unpushed `04c38321`).
- Every commit updates `docs/REMAINING_WORK.md` in its repo; no Co-Authored-By trailer; Dart `package:` imports; new strings in all 19 locales + native-review CSV rows (edit the CSV by plain line append/replace, never re-serialise it).

## Decisions in this plan (from the spec, or chosen here)

- **Notifications default "mentions only"** (spec: default "events only"; events are not in this slice). Club rooms push like hubs (mentions), not like topic rooms (every message). The existing per-conversation mute (`POST /conversations/:id/mute`) is "off". An "every message" mode is deferred.
- **Notice (공지) is a `Club.notice` field** (≤ 500 chars, managers set it from the club edit sheet), not a pinned message: rooms have no message pinning.
- **Deferred to later slices:** automatic event messages ("New 정모 scheduled", "Confirmed", "Starting in 10 min") — they hook into `controllers/gatherings.js`; the "all messages" notification mode; server-side block filtering on the live socket (the app already hides blocked senders).

## Review Focus

1. A non-member (or a banned/removed member) calling `GET /rooms/:id`, `GET /rooms/:id/messages`, socket `room:join`, or posting to a club room → refused, even though the same calls work on topic rooms. Test in Task 1.
2. A removed member is out of the room's `participants` immediately (no push, no access), and a rejoined member is back in. Test in Task 2.
3. Club rooms never appear in `GET /rooms`, the "my rooms"/joined list, or the DM conversation list. Test in Task 1.
4. `POST /rooms/:id/join` and `request-join` on a club room → refused (membership only via the club). Test in Task 1.
5. Deleting a club leaves no reachable room (archived or deleted with it). Test in Task 2.

---

### Task 1: Club rooms in the rooms system (type, link, privacy)

**Files:**
- Modify: `models/Conversation.js` (`roomType` enum + `'club'`; `club: { type: ObjectId, ref: 'Club', default: null, index: true }`), `controllers/rooms.js` (`ROOM_TYPES`, `getRooms`, `getRoom`, `getRoomMessages`, `joinRoom`, `requestJoin`), `lib/roomAccess.js`, `socket/roomHandler.js` (type list, `room:join`, push branch), `lib/dmConversation.js` (`DM_ROOM_EXCLUSION`), `lib/conversationListQuery.js`, `controllers/messages.js` (room-type exclusion near :264), wherever `loadAccessibleRoom` lives
- Create: `lib/clubRoomAccess.js`
- Test: `test/clubRoomPrivacy.test.js`

**Interfaces:**
- Produces: `canUseClubRoom(room, userId) -> Promise<boolean>` — true only if `room.club` names an active club whose `members` include `userId` and whose `bannedUsers` don't. Every access path above calls it when `room.roomType === 'club'`; topic/hub behaviour is unchanged.
- Club rooms: excluded from `getRooms` (all scopes) and from DM/conversation lists; `joinRoom` / `requestJoin` → `403 "Join the club to use its chat"`; push on new message follows the hub (mentions-only) branch.
- [ ] **Step 1: Failing tests** — non-member `getRoom` / `getRoomMessages` → 403; member → 200; banned → 403; `getRooms` with a club room present doesn't list it; `joinRoom` / `requestJoin` → 403; the DM list query excludes it; a topic room's behaviour is unchanged (non-member can still read it).
- [ ] **Step 2: Run** `node --test test/clubRoomPrivacy.test.js` → FAIL.
- [ ] **Step 3: Implement.** Grep every list of room types (`'hub'`, `'topic'`) and add `'club'` where it means "this is a room", never where it means "public".
- [ ] **Step 4: Run** it plus every `test/room*.test.js`, `test/conversation*.test.js`, `test/dm*.test.js` that exists → PASS.
- [ ] **Step 5: Commit** `feat(clubs): club rooms are members-only and hidden from room and DM lists`.

### Task 2: One chat per club, kept in sync; notice; the chat endpoint

**Files:**
- Create: `lib/clubRoom.js`
- Modify: `models/Club.js` (`notice: { type: String, default: '' }`), `controllers/clubs.js` (`present` adds `notice`; `readV2Fields` accepts `notice` ≤ 500; hooks after join / leave / removeMember / setMemberRole / updateClub name / deleteClub; new `getClubChat`), `routes/clubs.js` (`GET /:id/chat`), `controllers/rooms.js` `getRoom` (adds `clubId`, `clubNotice` for club rooms)
- Test: `test/clubChat.test.js`

**Interfaces:**
- Produces:
  - `getOrCreateClubRoom(club) -> Promise<Conversation>`: finds the room by `club: club._id`, else creates `{ roomType: 'club', club, title: club.name, targetLanguage: club.language, isPublic: false, owner: club.owner, admins: organizer ids, participants: member ids, memberCount }`. Unique per club (handle a concurrent double-create by catching the duplicate and re-reading; add a unique sparse index on `club`).
  - `syncClubRoom(club) -> Promise<void>`: if a room exists, rewrites `participants`, `owner`, `admins`, `memberCount`, `title` from the club; on archived/deleted club, deletes the room (`Conversation.deleteOne`) — Review Focus 5. No-op when no room exists yet. Never throws into the caller (logs).
  - `GET /clubs/:id/chat` → `200 { data: { roomId } }`; 404 without v2 access; 403 for non-members.
  - `GET /rooms/:id` for a club room adds `clubId` and `clubNotice`.
- [ ] **Step 1: Failing tests** — member gets a roomId, twice the same id; non-member 403; without access 404; join → participant; leave → not; remove (with and without ban) → not; role change → admins updated; rename → title; delete club → room gone; notice saved with access (≤ 500, 501 → 400), ignored without; `getRoom` returns `clubNotice`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** this + all `test/club*.test.js` → PASS.
- [ ] **Step 5: Commit** `feat(clubs): one members-only chat per club, synced from membership; club notice`; backend `docs/REMAINING_WORK.md` lists the deferred items above.

### Task 3: App — open the chat, show the notice, edit the notice

**Files:**
- Modify: `lib/models/community/gathering_model.dart` (`Club.notice`), `lib/services/gathering_api_client.dart` (`getClubChatRoomId(String clubId) -> Future<String?>`), the room model/screen (`clubId`, `clubNotice` parsed; notice banner at the top when non-empty; no Join bar when `clubId != null`), `lib/pages/community/gatherings/club_detail_screen.dart` (a "Chat" button for members with access → `context.push('/room/$roomId')`; notice field in the edit sheet), ARB files, `test/l10n/hardcoded_strings_test.dart` registries
- Test: `test/community/club_chat_test.dart`

**Interfaces:**
- Strings: `clubChat` "Chat", `clubNoticeLabel` "Notice for members (optional)", `clubNoticeTitle` "Notice", `clubChatFailed` "Couldn't open the chat."
- Behaviour: Chat button only when `clubsV2 && club.viewerIsMember`; failure → snackbar `clubChatFailed`. Notice shown on the club page under the description and as a banner in the club room. Without access: no button, no notice, no edit field.
- [ ] **Step 1: Failing tests** — member with access sees Chat and tapping calls `getClubChatRoomId`; non-member / no access: no Chat; notice shows on the page; edit sheet sends `notice`; room model parses `clubNotice` and the banner renders; a club room shows no Join bar.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** `flutter test test/community test/l10n` and full `flutter test` → PASS; `flutter analyze` 0 errors.
- [ ] **Step 5: Commit** `feat(clubs): open the club chat from the club page; the organizer notice (clubs v2)`; app `docs/REMAINING_WORK.md` updated.
