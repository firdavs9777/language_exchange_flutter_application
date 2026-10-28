# Clubs v2, slice 4: join approval — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** In-person clubs always approve new members; online clubs may choose to. The host sees who is asking (profile, languages, how many meetups they've been to) and approves or declines.

**Spec:** `docs/moim-plan.md` §8 item 11 ("Required offline, optional online"), §1 walkthrough.

**Architecture:** Club gains `format` ('online' | 'offline', default 'online') and `joinApproval` (bool, default false); approval applies when `format === 'offline' || joinApproval`. `joinRequests [{ user, requestedAt }]` on Club (never sent to clients). `POST /clubs/:id/join` on an approval club records a request instead of joining. Managers list and decide requests; both sides get an in-app notice.

## Global Constraints
- Backend `feat/clubs-v2-approval` off `feat/clubs-v2-feed`; app `feat/clubs-v2-approval` off app `feat/clubs-v2-feed`. Not deployed without the owner's go-ahead.
- Only clubs v2 users can set `format` / `joinApproval`, so every existing club stays open-join. A user without v2 joining an approval club gets 403 "This club approves new members. Update BananaTalk to ask to join." (old apps show the server message).
- `controllers/gatherings.js` untouched (reads of `Gathering` for the attendance count are fine).
- REMAINING_WORK per commit; no Co-Authored-By; strings in 19 locales + CSV rows (line edits only); notification templates in all 19 locale files.

## Review Focus
1. A request never makes someone a member or a chat participant until approved; approval adds both (`syncClubRoom`).
2. Banned users can't request; a pending request is not duplicated; withdrawing works; deciding a request that no longer exists → 404.
3. Only owner/organizers list or decide (organizers included); non-v2 users 404 on the new routes.
4. Existing open clubs: join behaviour unchanged for everyone.
5. `joinRequests` never appears in any club payload.

### Task 1: Backend — fields, request/withdraw, list, decide, notices
**Files:** `models/Club.js`, `controllers/clubs.js` (`readV2Fields` + `present` + `joinClub` + `leaveClub` withdraw + `getJoinRequests` + `decideJoinRequest`), `routes/clubs.js`, `models/Notification.js` + `services/fcmService.js` + `test/notificationTypeEnum.test.js` (`club_join_request`, `club_join_approved`, `club_join_denied`), `services/notificationService.js` (`sendClubJoinRequest`, `sendClubJoinDecision`), `notification_templates/*.json`
**Interfaces:**
- `present` adds `format`, `joinApproval`, `needsApproval`, and per viewer `viewerRequestPending`; managers with v2 get `pendingRequestCount`.
- `POST /clubs/:id/join` on an approval club (v2): 202 `{ data: club, pending: true }`; notifies owner + organizers.
- `DELETE /clubs/:id/join` with a pending request: withdraws it (200).
- `GET /clubs/:id/requests` (managers, v2): `[{ user: { _id, name, images, native_language, language_to_learn }, requestedAt, meetupsAttended }]` oldest first; `meetupsAttended` = past gatherings where the user was `going`.
- `POST /clubs/:id/requests/:userId` `{ approve: bool }` (managers, v2): approve → member + chat sync; either way the request is removed and the requester notified.
- [ ] Failing tests `test/clubJoinApproval.test.js` (Review Focus 1–5) → implement → run with all `test/club*.test.js` → commit.

### Task 2: App — format and approval, ask/pending/withdraw, requests sheet
**Files:** `gathering_model.dart` (Club fields), `gathering_api_client.dart` (`joinClub` reads `pending`; `getClubJoinRequests`; `decideClubJoinRequest`; create/update send `format`, `joinApproval`), `create_club_sheet.dart` + club edit sheet (format choice; approval switch, locked on for in-person), `club_detail_screen.dart` (Ask to join / Request pending + Withdraw; managers' "N waiting to join" → requests sheet), new `club_requests_sheet.dart`, `notification_router.dart` (`club_join_*` → `/club/:id`), ARB.
- Reused strings: `gatheringAskToJoin`, `gatheringRequestPending`, `gatheringWithdrawRequest`, `gatheringRequests`, `gatheringDeny`. New: `clubFormatLabel`, `clubFormatOnline`, `clubFormatOffline`, `clubApprovalToggle`, `clubApprovalOfflineHint`, `clubApprove`, `clubRequestsEmpty`, `clubRequestMeetups` (plural), `clubRequestSent`.
- [ ] Failing tests `test/community/club_join_approval_test.dart` → implement → full `flutter test` + analyze → commit.
