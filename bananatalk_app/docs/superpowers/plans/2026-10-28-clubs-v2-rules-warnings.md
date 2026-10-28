# Clubs v2, slice 1: access flag, language pair, rules, warnings — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clubs get a second language (the pair), owner-written rules shown before joining, and organizer warnings with a "Remove?" prompt at the 3rd, all visible only to an allow-listed test group, with nothing changing for anyone else.

**Architecture:** A new backend switch `CLUBS_V2_ENABLED` (default off) plus `CLUBS_V2_USER_IDS` decides per user; `GET /clubs/access` tells the app. New Club fields are additive and always returned (old apps ignore them) but only writable by users with access; warnings are a new collection behind new routes that 404 without access. The app reads access once and shows the new UI only when it is true.

**Tech Stack:** Backend Node/Express + Mongoose, tests `node --test` with `mongodb-memory-server`. App Flutter + Riverpod 2, `flutter_test`.

**Spec:** `docs/moim-plan.md` (Phase 0.5, Phase 2 "Club rules and warnings", §1 "Clubs vs. gatherings", §8 items 9 and 12).

## Global Constraints

- Prod must not change for anyone outside the allow-list: existing endpoints keep every field they return today and accept every body they accept today; `GATHERINGS_ENABLED` behaviour is untouched.
- 2.6.1 / 2.2.6 app builds must keep working against the new backend (they ignore unknown JSON fields).
- `controllers/gatherings.js` and `models/Gathering.js` are NOT touched in this slice: backend `04c38321` (unpushed) edits them.
- Backend work happens in a new worktree off `origin/main`: `/Users/davis/Desktop/Personal/be-clubs-v2`, branch `feat/clubs-v2-rules`. App work on branch `feat/clubs-v2-rules` off the current app branch.
- Every commit updates `docs/REMAINING_WORK.md` in its repo (CLAUDE.md). No Co-Authored-By trailer.
- Dart: `package:` imports only. All user-facing strings are ARB keys in all 19 locales (en source; others machine-drafted and appended to `docs/l10n/native-qa-strings-2026-10.csv`).
- Limits: rules ≤ 10 items, each 1–200 chars after trim; warning `rule` 1–200 chars, `note` ≤ 500 chars.

## Review Focus

1. A non-allow-listed user sending `rules` / `secondLanguage` in create/update → silently ignored, not 400 (old and new apps share endpoints). Test in Task 2.
2. An organizer warning another organizer or the owner → 403 / 400, same rules as `removeMember`. Test in Task 3.
3. A removed-with-ban member calling `POST /clubs/:id/join` → 403 "You can't rejoin this club"; a removed-without-ban member can rejoin as today. Test in Task 3.
4. `GET /clubs/access` while `GATHERINGS_ENABLED=false` → 404 like every other club route, and the app treats any failure as "no access". Tests in Tasks 1 and 4.
5. Warning count after the member leaves and rejoins → still counted (warnings belong to club + user, not to the membership row). Test in Task 3.

---

### Task 1: Backend access switch

**Files:**
- Modify: `config/limitations.js` (add the two settings next to `GATHERINGS_ENABLED`, export both)
- Create: `lib/clubsV2Access.js`
- Modify: `controllers/clubs.js`, `routes/clubs.js` (new `GET /access`, declared before `/:id`)
- Test: `test/clubsV2Access.test.js`

**Interfaces:**
- Produces: `clubsV2EnabledFor(userId: string|ObjectId) -> boolean` (true if `CLUBS_V2_ENABLED` or the id is in `CLUBS_V2_USER_IDS`, a comma-separated list, trimmed); `exports.getClubsAccess` → `200 { success: true, data: { clubsV2: boolean } }`.
- Settings: `CLUBS_V2_ENABLED` (string `'true'` to enable, default false), `CLUBS_V2_USER_IDS` (default empty). Read per call (not at module load) so tests can set `process.env`.

- [ ] **Step 1: Failing tests** — `off by default`, `on for an allow-listed id with spaces in the list`, `on for everyone when CLUBS_V2_ENABLED=true`, `GET /clubs/access returns { clubsV2 } for req.user`.
- [ ] **Step 2: Run** `node --test test/clubsV2Access.test.js` → FAIL (module missing).
- [ ] **Step 3: Implement** the helper and the handler; the route sits behind the existing `gatheringsEnabledGuard` and auth like every club route.
- [ ] **Step 4: Run** the test and `node --test test/clubs.test.js test/gatheringsKillSwitch.test.js` → PASS.
- [ ] **Step 5: Commit** `feat(clubs): per-user access switch for clubs v2 (off by default)`.

### Task 2: Club language pair and rules

**Files:**
- Modify: `models/Club.js` (fields), `controllers/clubs.js` (`present`, `createClub`, `updateClub`)
- Test: `test/clubsV2Fields.test.js`

**Interfaces:**
- Consumes: `clubsV2EnabledFor` (Task 1), `matchKey` (`lib/matchLanguage.js`).
- Produces (Club fields, all optional, defaults shown): `secondLanguage: String|null = null` (base code via `matchKey`), `secondLanguageLabel: String = ''`, `rules: [String] = []`. `present()` adds `secondLanguage`, `secondLanguageLabel`, `rules` to every club response.
- Body fields accepted on create/update **only when `clubsV2EnabledFor(req.user.id)`**: `secondLanguage` (string; `''`/null clears on update), `rules` (array of strings).

- [ ] **Step 1: Failing tests** —
  - `allow-listed creator sets secondLanguage "Korean" with language "English" → stored "ko", label "Korean"`
  - `secondLanguage equal to language → 400 "Pick two different languages"`
  - `rules are trimmed, empty ones dropped; 11 rules → 400; a 201-char rule → 400`
  - `non-allow-listed creator sending rules/secondLanguage → 201, fields stay default` (Review Focus 1)
  - `GET /clubs/:id and the list both include secondLanguage, secondLanguageLabel, rules`
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Validation lives in one helper in `controllers/clubs.js`, `readV2Fields(body, language) -> { secondLanguage, secondLanguageLabel, rules } | ErrorResponse`, used by both create and update.
- [ ] **Step 4: Run** this test plus `test/clubs*.test.js` → PASS.
- [ ] **Step 5: Commit** `feat(clubs): a second language and owner-written rules (clubs v2 only)`.

### Task 3: Warnings, the 3rd-warning prompt, removal with ban

**Files:**
- Create: `models/ClubWarning.js`
- Modify: `models/Club.js` (`bannedUsers: [ObjectId]`, default `[]`, never returned by `present`), `controllers/clubs.js` (`warnMember`, `getMemberWarnings`, `removeMember`, `joinClub`, `getClub`), `routes/clubs.js`, `models/Notification.js` (enum `club_warning`), `services/notificationService.js` (`sendClubWarning`), the template file `templateService` reads (key `club_warning`, en + ko)
- Test: `test/clubWarnings.test.js`

**Interfaces:**
- Consumes: `clubsV2EnabledFor`, `canManageClub`, `isClubOwner`, `memberIdOf`, `isClubMember` (`lib/clubMembers.js`).
- Produces:
  - `ClubWarning { club: ObjectId (index), user: ObjectId (index), issuedBy: ObjectId, rule: String, note: String = '', createdAt }`, compound index `{ club: 1, user: 1 }`.
  - `POST /clubs/:id/members/:userId/warnings` body `{ rule, note? }` → `201 { success, data: { warningCount: number, promptRemoval: boolean } }`; `promptRemoval` is `warningCount >= 3`. Nothing is removed automatically.
  - `GET /clubs/:id/members/:userId/warnings` (managers only) → `{ data: [{ rule, note, issuedBy: { _id, name }, createdAt }] }` newest first.
  - `GET /clubs/:id` adds, only for users with access: `viewerWarningCount: number` (the viewer's own), and on each `members[]` entry for managers `warningCount: number`. Without access neither key appears.
  - `DELETE /clubs/:id/members/:userId` accepts optional body `{ ban: boolean, reason: string }` **only with access**: `ban: true` pushes the id to `bannedUsers`; a non-empty `reason` creates a `Report { type: 'club', reportId: club._id, reportedBy: remover, reportedUser: target, reason: 'other', description: reason (≤500) }`. Without access the body is ignored (today's behaviour).
  - `joinClub`: an id in `bannedUsers` → `403 "You can't rejoin this club"`. Runs for every caller (only v2 removals ever write the list).
  - `sendClubWarning(userId, club, rule)` → `send(userId, 'club_warning', { title, body, data: { type: 'club_warning', clubId } })`, shaped like `sendRoomJoin`.
- Warn permissions mirror `removeMember`: managers only (403); the owner can't be warned (400); only the owner warns an organizer (403); the target must be a member (404). All warning routes 404 without access.

- [ ] **Step 1: Failing tests** —
  - `organizer warns a member → 201, warningCount 1, promptRemoval false; a club_warning notification row exists`
  - `third warning → warningCount 3, promptRemoval true, member still in club`
  - `organizer warns organizer → 403; anyone warns owner → 400; member warns member → 403; non-member target → 404` (Review Focus 2)
  - `rule missing or > 200 chars → 400; note > 500 → 400`
  - `warning routes → 404 for a user without access`
  - `leave and rejoin keeps warningCount` (Review Focus 5)
  - `remove with { ban: true, reason } → member gone, rejoin 403, one Report of type club`; `remove without ban → rejoin works` (Review Focus 3)
  - `GET /clubs/:id: viewerWarningCount for a warned member with access; warningCount on members only for managers; neither key without access`
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** in the files above.
- [ ] **Step 4: Run** this test plus `test/clubs*.test.js` → PASS.
- [ ] **Step 5: Commit** `feat(clubs): rules-based warnings and remove-with-ban (clubs v2 only)`; update backend `docs/REMAINING_WORK.md` with the two env settings and "not deployed".

### Task 4: App access, model fields, API calls

**Files:**
- Modify: `lib/models/community/gathering_model.dart` (`Club`, `ClubMember`), `lib/services/gathering_api_client.dart`
- Create: `lib/providers/provider_root/clubs_v2_provider.dart`
- Test: `test/community/clubs_v2_model_test.dart`, `test/community/clubs_v2_access_test.dart`

**Interfaces:**
- Produces:
  - `clubsV2AccessProvider`: `FutureProvider<bool>`; `GET clubs/access` → `data.clubsV2 == true`; any error or non-200 → `false`. Register it as user-scoped in `lib/services/session_reset.dart` (the classification test enforces this).
  - `Club`: `secondLanguage` (`String?`), `secondLanguageLabel` (`String`, default `''`), `rules` (`List<String>`, default `[]`), `viewerWarningCount` (`int`, default 0). `ClubMember.warningCount` (`int`, default 0). Missing keys parse to the defaults.
  - `GatheringApiClient`: `createClub`/`updateClub` gain optional `String? secondLanguage, List<String>? rules` (sent only when non-null); `warnMember(String clubId, String userId, {required String rule, String? note}) -> Future<({int warningCount, bool promptRemoval})?>`; `removeMember` gains optional `{bool ban = false, String? reason}` (body sent only when `ban` or `reason` is set).
- [ ] **Step 1: Failing tests** — old JSON (no new keys) parses to defaults; new JSON parses all fields; access provider returns false on 404 and on a thrown error (Review Focus 4), true on `{clubsV2: true}`.
- [ ] **Step 2: Run** `flutter test test/community/clubs_v2_model_test.dart test/community/clubs_v2_access_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** those plus `flutter test test/community test/services/session_reset_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat(clubs): app reads clubs v2 access and the new club fields`.

### Task 5: App UI — pair and rules on create/edit, rules before joining

**Files:**
- Modify: `lib/pages/community/gatherings/create_club_sheet.dart`, `lib/pages/community/gatherings/club_detail_screen.dart`, ARB files (`lib/l10n/app_*.arb`)
- Create: `lib/pages/community/gatherings/club_rules.dart` (`defaultClubRules(AppLocalizations) -> List<String>`, `ClubRulesEditor`, `ClubRulesList`)
- Test: `test/community/club_rules_test.dart`

**Interfaces:**
- Consumes: `clubsV2AccessProvider`, Task 4 API.
- Behaviour (only when access is true; otherwise both screens render exactly as today):
  - Create/edit sheet: a second language picker (the shared `languagesProvider` picker), and a rules editor pre-filled on create with 4 defaults: `clubRuleRespect` "Be respectful.", `clubRuleBothLanguages` "Use both languages of the club.", `clubRuleNoSelling` "No dating, selling or recruiting.", `clubRuleReleaseSeat` "RSVP honestly and release your seat if you can't come." Add / edit / delete rows, max 10.
  - Club detail: the language chip reads "English ↔ 한국어" when a pair is set. Non-members see the rules above the Join button and the button reads `clubJoinAgree` "Agree and join"; a club with no rules keeps today's "Join".
- [ ] **Step 1: Failing widget tests** — access off: no pair picker, no rules editor, Join button text unchanged; access on: 4 default rules prefilled, an 11th rule can't be added, detail shows rules and "Agree and join" for a non-member, pair chip text.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement**; new keys in all 19 ARBs, CSV rows appended.
- [ ] **Step 4: Run** `flutter test test/community test/l10n` → PASS.
- [ ] **Step 5: Commit** `feat(clubs): language pair and rules in the club sheet and before joining (clubs v2)`.

### Task 6: App UI — warn, 3rd-warning prompt, remove with ban

**Files:**
- Modify: `lib/pages/community/gatherings/club_people_section.dart` (manager actions per member), `club_detail_screen.dart` (member's own count), ARB files, the notification tap router for `club_warning` (opens the club; find it next to the `gathering_time_changed` handling)
- Create: `lib/pages/community/gatherings/club_warn_sheet.dart`
- Test: `test/community/club_warnings_test.dart`

**Interfaces:**
- Consumes: `warnMember`, `removeMember(ban:, reason:)`, `Club.rules`, `ClubMember.warningCount`, `Club.viewerWarningCount`.
- Behaviour (access only):
  - Manager long-press / menu on a member: "Warn" opens `ClubWarnSheet` — pick one of the club's rules (radio list; "Other" if the club has none, free text), optional note, Send. Member rows show "⚠ 2" when `warningCount > 0`.
  - After a send that returns `promptRemoval: true`: dialog `clubRemoveAfterWarningsTitle` "{name} has 3 warnings. Remove them?" with Remove / Not now. Remove calls `removeMember(ban: true)`.
  - "Remove now" in the same menu asks for a reason (required, ≤ 500) and calls `removeMember(ban: true, reason:)`.
  - A member with `viewerWarningCount > 0` sees "You have {count} of 3 warnings in this club" under the header.
  - Failures show `friendlyErrorMessage` snackbars; nothing optimistic.
- [ ] **Step 1: Failing widget tests** — warn flow sends the picked rule; promptRemoval true shows the dialog and Remove calls `removeMember(ban: true)`; "Remove now" without a reason can't submit; own-count banner; access off: no Warn / Remove now entries (existing remove entry unchanged).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/community test/l10n` and `flutter analyze` (0 errors) → PASS.
- [ ] **Step 5: Commit** `feat(clubs): warnings, the 3-warning prompt and remove-with-ban (clubs v2)`; tick the slice in app `docs/REMAINING_WORK.md`, list deploy + allow-list setup as owner steps.

---

**Not in this slice** (next plans): host approval for offline clubs, club chat, club feed, open vs. club gatherings and everything in `controllers/gatherings.js` (after `04c38321` is pushed), the first-visit explainer (Phase 5).
