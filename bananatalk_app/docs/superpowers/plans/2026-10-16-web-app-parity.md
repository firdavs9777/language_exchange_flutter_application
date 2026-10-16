# Web ↔ App Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every P0/P1 from the 2026-10-16 web/app audits and connect banatalk.com and the app, then build the website's missing features behind flags.

**Architecture:** Phased: web baseline → backend (always live, backward compatible) → app (ships with 2.7.0) → web bug fixes (area-sized pushes) → web features (flagged off). This file holds Phases 0–1 in full; Phases 2, 3 and 4 each get their own plan file (`2026-10-16-web-app-parity-phase{2,3,4}.md`), written at phase start against the code as it is then.

**Tech Stack:** Node/Express/Mongo/socket.io + node:test (backend); Flutter/Riverpod (app); React/TS CRA + RTK Query + Jest (web); LiveKit; ffmpeg.

**Spec:** `docs/superpowers/specs/2026-10-16-web-app-parity-design.md`; audits `docs/audits/2026-10-16-web-parity/`.

## Global Constraints

- Web and backend deploy on push to `main`: never push without a green full suite + (web) `npm run build`.
- Backend responses stay backward compatible with live web (origin/main) and app 2.6.1; only privacy-removed fields may disappear.
- `POST /messages/conversations` response keeps `{isNew, participants, lastMessage, isGroupMessage}`, no top-level `data._id`.
- New flags default false: `WEB_REELS_ENABLED`, `WEB_GATHERINGS_ENABLED`, `WEB_VOICE_ROOMS_ENABLED`, `WEB_LANGUAGE_ROOMS_ENABLED`, `WEB_CALLS_ENABLED`, `WEB_APPLE_SIGNIN_ENABLED`.
- Voice pass-through MIME list: `audio/mpeg`, `audio/mp3`, `audio/aac`, `audio/x-aac`, `audio/mp4`, `audio/m4a`, `audio/x-m4a`.
- Every commit updates `docs/REMAINING_WORK.md` of its repo and lists still-open items in the body; no Co-Authored-By / AI attribution.
- Backend full suite: `node --experimental-test-module-mocks --test --test-force-exit --test-concurrency=4 services/*.test.js test/*.test.js` (1 known local failure: `authSecretRotation` 32-char secret).

## Review Focus

1. Populated vs unpopulated refs (blocked lists of `{userId}` objects, populated `following`) — compare ids with a helper, never `String(ref)`; P1-CHAT-0 and P1-PRIV-1/3 pin it.
2. Signed-out viewers on `/:id/public` (no coordinates, birth month/day, follower lists, lastSeen/online) — P1-PRIV-1 pins it; live web then shows 0 followers for signed-out visitors until Phase 3 reads `followersCount`.
3. Voice uploads with wrong/odd MIME (`audio/webm;codecs=opus`, `video/webm`, no audio track, ffmpeg missing) — P1-MOM-3/4 pin it; mislabelled WebM-as-mp4 stays unconverted (open item).
4. Reused / expired / parallel Google exchange codes and Apple tokens minted for the app — P1-LINK-5/6 pin it.
5. Legacy clients: live web sends query `forEveryone`, edit `content`; 2.6.1 reads chat list fields — P1-CHAT-2/6 and the contract tests pin it.

## Execution order (Phase 1)

1. P1-MERGE (coordinator, one worktree `be-integration`).
2. Then four parallel worktrees off the merged main: CHAT (P1-CHAT-0…7), PRIV (P1-PRIV-1…5), MOM (P1-MOM-1…4), LINK (P1-LINK-1…8; 5 before 6).
3. Coordinator merges the four, runs the full suite, pushes once (deploys), verifies `/api/v1/app-config` 200.

---

## Phase 0 — web repo baseline

Facts (2026-10-16): local `main` of `/Users/davis/Desktop/Personal/language_exchange_web_front` is 23 commits
ahead of `origin/main` (head 502663f). `git diff origin/main main` touches 292 files; all 245 deleted
files are unit tests (`*.test.*`, `__tests__`, setupTests) removed by `9ba0eb9` (merged in `ab59100`).
Pushing `main` deploys the website (`.github/workflows/deploy.yml`, on push to main).

### Task P0-1: one commit with the other session's fixes, tests kept

**Files:** whole web repo (worktree `/Users/davis/Desktop/Personal/wt-web-p0`).

- [ ] **Step 1: Worktree on origin/main**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
git fetch origin
git worktree add -b web/p0-baseline /Users/davis/Desktop/Personal/wt-web-p0 origin/main
cd /Users/davis/Desktop/Personal/wt-web-p0
ln -s /Users/davis/Desktop/Personal/language_exchange_web_front/node_modules node_modules
```

- [ ] **Step 2: Apply the 23 commits' net change, except deletions of test files**

```bash
git diff origin/main main --binary --diff-filter=d | git apply --index
# modified/added files only; deletions are excluded by --diff-filter=d
git diff origin/main main --name-status | awk '$1=="D"' | grep -vE '\.test\.|__tests__|setupTests' 
# Expected: no output (every deletion is a test file). If anything prints, delete it too:
#   git rm <path>
```

- [ ] **Step 3: Run the restored test suite**

Run: `CI=true npm test -- --watchAll=false 2>&1 | tail -30`
Expected: some failures where the other session changed behaviour the old tests pinned.

- [ ] **Step 4: Fix each failing test**

For each failure, read the commit that changed the behaviour (`git log origin/main..main -- <src file>`).
If the new behaviour is intended (the commit message says so), update the test's expectation to the new
behaviour. If it is a bug, fix the source. Re-run until `Tests: N passed`. Record each changed test in the
commit body.

- [ ] **Step 5: Build**

Run: `npm run build 2>&1 | tail -15`
Expected: "Compiled successfully" (warnings allowed) and prerender finishes without error.

- [ ] **Step 6: Commit (one commit) with the tracker updated**

Add to `docs/REMAINING_WORK.md` (web repo) under a "Web/app parity" heading: the Phase 3/4 items from the
spec as `- [ ]` lines, and `- [x] Baseline: 23 local commits squashed, tests restored`.

```bash
git add -A
git commit -F - <<'EOF'
fix: moments, stories and privacy settings audit fixes (squashed), tests kept

Squash of 23 local commits (story canvas/app gradients, own reaction and
vote restored, highlights on the shared canvas, prompt-of-the-day chip,
My moments paging, privacy settings page, notification settings endpoint)
without "chore: remove unit test files". Tests updated where behaviour
intentionally changed: <list>.

Still open: web/app parity phases 3-4 (see docs/REMAINING_WORK.md).
EOF
```

- [ ] **Step 7: Push (deploys) and verify**

```bash
git push origin web/p0-baseline:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/          # 200
curl -s https://banatalk.com/ | grep -o '<title>[^<]*</title>'          # site title, not an error page
```

- [ ] **Step 8: Retire the old local main**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
git branch -f backup/pre-p0-main main     # keep the 23 commits reachable
# do NOT reset main while another session might use this checkout; leave it and note it in the report
```

**Status:** done 2026-10-16 — web fba6208 pushed and deployed.

## Phase 1 — backend

# Phase 1 — backend: merge `fix/moments-stories-audit`, item 4 (highlights + translate), item 5 (voice transcode)

Repo: backend worktree `/Users/davis/Desktop/Personal/be-integration` (branch `main`, at `232fb49` = `origin/main`).
The branch to merge lives in the main checkout `/Users/davis/Desktop/Personal/language_exchange_backend_application`
(`fix/moments-stories-audit` @ `d6b0c33`, clean, **never pushed**). Worktrees share refs, so it is mergeable from
`be-integration` directly.

House rules for every task below:
- `docs/REMAINING_WORK.md` (backend) is updated in the same commit; the commit body lists what is still open.
- **No `Co-Authored-By` / AI attribution** in any commit message.
- **Do not push** from these tasks. A push to backend `main` deploys to production; Phase 1 is pushed once, after all
  Phase 1 items are merged and the full suite is green (spec §3 "Each phase is merged, tested and pushed").
- Full suite (run from `be-integration`):
  `node --experimental-test-module-mocks --test --test-force-exit --test-concurrency=4 services/*.test.js test/*.test.js`
  Known local-only failure: `authSecretRotation` (needs a 32-char `JWT_SECRET`; the local one is 12 chars). Any other
  failure blocks the task.
- Single-file runs: `node --experimental-test-module-mocks --test --test-force-exit test/<file>.test.js`.

---

### Task P1-MERGE: merge `fix/moments-stories-audit` into backend `main`

**Files:** whole branch (37 files, +3268/−454; 29 commits `1df438c..d6b0c33`). Files touched on **both** sides since
the merge base: `controllers/auth.js`, `controllers/community.js`, `docs/REMAINING_WORK.md`.
Test path: the branch's own new tests — `test/storyAudit.test.js`, `test/storyRedaction.test.js`,
`test/userPrivacyRedaction.test.js`, `test/privacyFollowups.test.js`, `test/privacySettingsMerge.test.js`,
`test/presenceHiddenStatus.test.js`, `test/momentPrompt.test.js`, `test/momentUpdateValidator.test.js`,
`test/storyLink.test.js`, `test/updateUsername.test.js` — plus the full suite.

**Interfaces:**
- Produces (used by later Phase 1 items): `lib/privacySettings.js` → `redactUserForViewer(user, viewerId)`,
  `PUBLIC_PRIVACY_KEYS`, `PUBLIC_PRIVACY_PROJECTION`, `VISIBLE_ONLINE_FILTER`, `VISIBLE_AGE_FILTER`,
  `findSortedByVisibleActivity(Model, filter, {select, sort, skip, limit})`, `privacySettingsUpdate(obj)`,
  `applyPresenceVisibility(req, userId, paths)`; `models/StoryHighlight.js` →
  `StoryHighlight.HIGHLIGHT_STORY_FIELDS` (space-separated string), `StoryHighlight.syncStoryFlags(ids)`;
  `utils/storyUtils.js` → `processStory(story, { viewerId })` (owner-only data redacted, `userReaction` added).

**Conflict forecast (measured read-only, 2026-10-16):**
- `git merge-tree --write-tree --name-only main fix/moments-stories-audit` → exit 0, tree `d3db8d7`, **no conflicted
  paths**. The legacy 3-arg `git merge-tree <base> main fix/moments-stories-audit` shows "changed in both" for exactly
  3 files and **0** `<<<<<<<` markers.
- `controllers/auth.js`: main changed the support address in two email templates (~:1208, ~:1391); branch changed the
  imports (:29) and `updateDetails` privacy merge (~:1595, ~:1663). Disjoint hunks → auto-merges.
- `controllers/community.js`: main added `UserInteraction` import + `recordInteraction` in `sendWave` (~:5, ~:326);
  branch added the `lib/privacySettings` import (~:13) and redaction in `getNearbyUsers` / `getTopicUsers`. Disjoint →
  auto-merges. **Semantic check**: both import blocks must survive (`UserInteraction` *and* the privacy import).
- `docs/REMAINING_WORK.md`: both sides edited §1/§4/§6 → auto-merges textually, but **read it after the merge**: the
  branch's "Bug-fix wave … merged to main" / "privacy follow-ups" lines and main's Partners/DailyDrop/purchases lines
  must both be present exactly once, and §1 Status must say the branch is merged and not deployed.
- If a conflict *does* appear (main moved since 2026-10-16): resolve code files by keeping **both** sides' intent
  (main's fix + branch's redaction), never by taking one side wholesale; in `REMAINING_WORK.md` keep every open item from
  both sides and de-duplicate.

- [ ] **Step 1 — baseline on `main` before merging** (records the pre-merge failure set):
  ```bash
  cd /Users/davis/Desktop/Personal/be-integration
  git status --short            # must be empty
  git fetch origin && git status -sb | head -1   # must be "## main...origin/main" with no ahead/behind
  node --experimental-test-module-mocks --test --test-force-exit --test-concurrency=4 services/*.test.js test/*.test.js 2>&1 | tail -12
  ```
  Expected: `# fail 1` (`authSecretRotation`). Note the `# pass` count.

- [ ] **Step 2 — re-check the conflict forecast against the current tips:**
  ```bash
  git merge-tree --write-tree --name-only main fix/moments-stories-audit; echo "exit=$?"
  ```
  Expected: one tree id line, `exit=0`. (exit 1 + listed paths = real conflicts → resolve as described above.)

- [ ] **Step 3 — merge without committing** (so `REMAINING_WORK.md` is fixed up inside the merge commit):
  ```bash
  git merge --no-ff --no-commit fix/moments-stories-audit
  git status --short   # expect only staged paths, no "UU"
  git diff --cached --stat | tail -1   # ~37 files changed
  ```

- [ ] **Step 4 — semantic checks on the auto-merged files:**
  ```bash
  grep -n "require('../models/UserInteraction')\|require('../lib/privacySettings')" controllers/community.js
  grep -n "recordInteraction(fromUserId, targetUserId, 'wave'" controllers/community.js
  grep -n "privacySettingsUpdate\|bananatalkmain@gmail.com" controllers/auth.js
  node -e "require('./controllers/community'); require('./controllers/auth'); require('./controllers/stories'); require('./controllers/users'); console.log('load ok')"
  grep -n "^## \|^Bug-fix wave\|moments-stories-audit" docs/REMAINING_WORK.md
  ```
  Expected: both community imports present, the wave interaction call present, `privacySettingsUpdate` and the new
  support address both present in auth.js, `load ok`, and REMAINING_WORK sections 1–6 each appear exactly once.

- [ ] **Step 5 — run the branch tests, then the full suite:**
  ```bash
  for f in storyAudit storyRedaction userPrivacyRedaction privacyFollowups privacySettingsMerge presenceHiddenStatus momentPrompt momentUpdateValidator storyLink updateUsername; do
    node --experimental-test-module-mocks --test --test-force-exit test/$f.test.js 2>&1 | grep -E "^# (pass|fail)" | tr '\n' ' '; echo " $f"; done
  node --experimental-test-module-mocks --test --test-force-exit --test-concurrency=4 services/*.test.js test/*.test.js 2>&1 | tail -12
  ```
  Expected: every branch file `# fail 0`; full suite `# fail 1` (`authSecretRotation` only) and `# pass` = baseline +
  the branch's new tests. Any other failure: fix it on `main` inside this merge (it is a merge-integration bug), re-run.

- [ ] **Step 6 — update `docs/REMAINING_WORK.md`** (staged into the merge commit):
  - §1 Status: add a bullet
    `- **fix/moments-stories-audit merged to main (2026-10-16), NOT deployed**: privacy redaction (`redactUserForViewer`) on users/matching/community lists, story viewer-data redaction + `userReaction` (moments#20), video-story link sticker (moments#18), `link.host` persisted (moments#25), highlight flags/visibility/render fields, moment prompt + update validation.`
  - §4 Code work — open, add under a new heading `Web ↔ app parity (spec 2026-10-16), Phase 1`:
    ```
    - [x] Item 0: merge fix/moments-stories-audit (this commit).
    - [ ] Item 1: re-check community#1, #6, links#11 against the merged redaction, then extend redactUserForViewer to GET /auth/users/:id, /:id/public (+ anonymous, + hasActiveStory), recommendations, topic users, blocked viewers.
    - [ ] Item 2: follow refuses blocked pairs (403); minimal profile for blocked viewers.
    - [ ] Item 3: chat backend (conversations route, delete-for-everyone query, lastMessage media.type, deletedFor filters, socket unread, sender populate, edit `content` alias).
    - [ ] Item 4: highlights select `music`; translate validator uses SUPPORTED_LANGUAGES + tl.
    - [ ] Item 5: voice notes transcoded to AAC .m4a (moment audio + chat voice).
    - [ ] Items 6–8: email links, OG `i` type, Pub/Sub audience fallback, web feature endpoints + flags, wrong-domain docs.
    - [ ] Deploy Phase 1 (push main) once items 0–8 are merged and the suite is green.
    ```

- [ ] **Step 7 — commit the merge:**
  ```bash
  git add docs/REMAINING_WORK.md
  git commit -F - <<'EOF'
  Merge fix/moments-stories-audit

  Privacy redaction for other users' profiles in lists and matching
  (redactUserForViewer), story viewer-data redaction and userReaction,
  link sticker on video stories, link.host persisted, highlight flags and
  render fields, moment prompt and update validation. Merged cleanly with
  main's wave/Partners, DailyDrop, purchases and support-address fixes.

  Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 1):
  - items 1-8 of Phase 1 (profile/public redaction paths, blocks, chat,
    highlights music + translate codes, voice transcode, links/emails,
    web feature endpoints, wrong-domain docs)
  - deploy: not pushed; Phase 1 is pushed as one deploy
  EOF
  git log --oneline -1
  ```
  Expected: a merge commit on `main`, `main` ahead of `origin/main` by 30. **Do not push.**

- [ ] **Step 8 — hand-off for item 1** (read-only, paste the output into the item-1 task notes):
  ```bash
  grep -n "redactUserForViewer" controllers/*.js | cut -c1-120
  grep -n "exports.getUser \|exports.getPublicProfile\|exports.getRecommendations\|exports.getTopicUsers" controllers/*.js
  ```
  These show which of community#1 / #6 / links#11 paths the merge already covers and which item 1 must still add.

---

### Task P1-MOM-1: highlights load every Story field a viewer renders (moments#19)

After P1-MERGE most of moments#19 is already done: the branch's `HIGHLIGHT_STORY_FIELDS`
(`models/StoryHighlight.js:174-181` on the merged tree) selects overlays, mentions, link, fontStyle, text, colours,
poll, question box, video metadata. The one viewer field still missing is **`music`** (the app parses it:
`lib/providers/provider_models/story_model.dart:267`). This task adds it and adds a guard so a future Story schema
field can't silently go missing from highlights again.

**Files:**
- Modify: `models/StoryHighlight.js:174-181` (`HIGHLIGHT_STORY_FIELDS`, merged tree).
- Test (new): `test/highlightFields.test.js`.

**Interfaces:**
- Consumes: `StoryHighlight.HIGHLIGHT_STORY_FIELDS: string`; `Story.schema.paths`; controller
  `exports.getUserHighlights(req, res, next)` (`controllers/stories.js` ~:1623 merged).
- Produces: `HIGHLIGHT_STORY_FIELDS` now also contains `music`. Response shape unchanged (additive field).

- [ ] **Step 1 — failing test** `test/highlightFields.test.js`:
  ```js
  'use strict';

  /**
   * moments#19: highlights loaded only some story fields, so highlights lost
   * overlays and app text stories made only of emoji showed blank. The
   * stories audit branch widened the select list; this pins it to the Story
   * schema so a new field can't go missing from highlights again, and adds
   * the one still missing (music, which the app parses).
   *
   * Run: node --test --test-force-exit test/highlightFields.test.js
   */
  process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

  const test = require('node:test');
  const assert = require('node:assert/strict');
  const mongoose = require('mongoose');
  const { MongoMemoryServer } = require('mongodb-memory-server');

  let mongod, User, Story, StoryHighlight, controller;

  const run = (fn, req) => new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      status(c) { this.statusCode = c; return this; },
      json(body) { resolve({ status: this.statusCode, body }); },
    };
    req.app = { get: () => null };
    req.body = req.body || {};
    req.query = req.query || {};
    fn(req, res, (err) => (err
      ? resolve({ status: err.statusCode || 500, error: err.message })
      : resolve({ status: 204 })))
      .catch(reject);
  });

  const realLog = console.log;
  const realError = console.error;

  test.before(async () => {
    console.log = () => {};
    console.error = () => {};
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri(), { dbName: 'highlightFields' });
    User = require('../models/User');
    Story = require('../models/Story');
    StoryHighlight = require('../models/StoryHighlight');
    controller = require('../controllers/stories');
  });
  test.after(async () => {
    await mongoose.disconnect();
    await mongod.stop();
    console.log = realLog;
    console.error = realError;
  });

  const makeUser = (name) => User.create({
    name,
    email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
    password: 'hashed-password-placeholder',
    birth_year: '2000', birth_month: '1', birth_day: '1', gender: 'other',
    native_language: 'English', language_to_learn: 'Korean',
  });
  const asViewer = (user) => ({ ...user.toObject(), id: user._id.toString(), _id: user._id });

  // Owner-only, unbounded, and drawn by no viewer: the reply texts live in chat,
  // shares are only counted (shareCount is selected).
  const NOT_FOR_VIEWERS = new Set(['_id', '__v', 'replies', 'shares']);

  test('every top-level Story field a viewer can render is selected for highlights', () => {
    const selected = new Set(StoryHighlight.HIGHLIGHT_STORY_FIELDS.split(/\s+/).filter(Boolean));
    const topLevel = [...new Set(Object.keys(Story.schema.paths).map((p) => p.split('.')[0]))];
    const missing = topLevel.filter((p) => !NOT_FOR_VIEWERS.has(p) && !selected.has(p)).sort();
    assert.deepEqual(missing, [], `Story fields not loaded for highlights: ${missing.join(', ')}`);
  });

  test('a highlighted text story keeps music, mentions, overlays, link and font for another viewer', async () => {
    const owner = await makeUser('hlFieldsOwner');
    const stranger = await makeUser('hlFieldsStranger');
    const tagged = await makeUser('hlFieldsTagged');

    const story = await Story.create({
      user: owner._id, mediaType: 'text', text: '🙂🙂', privacy: 'public',
      backgroundColor: '#112233', textColor: '#fafafa', fontStyle: 'handwriting',
      overlays: [{ type: 'emoji', content: '🔥', x: 0.3, y: 0.4 }],
      mentions: [{ user: tagged._id, username: 'tagged', position: { x: 40, y: 60 } }],
      link: { url: 'https://example.com/a', host: 'example.com', displayText: 'Open' },
      music: { trackId: 't1', title: 'Song', artist: 'Band', startTime: 3, duration: 15 },
      hashtags: ['korean'],
    });
    await StoryHighlight.createFromStory(owner._id, story._id, 'Fields');

    const out = await run(controller.getUserHighlights, {
      params: { userId: owner._id.toString() }, user: asViewer(stranger),
    });
    assert.equal(out.status, 200, JSON.stringify(out));
    const s = out.body.data[0].stories[0].story;
    assert.equal(s.text, '🙂🙂');
    assert.equal(s.backgroundColor, '#112233');
    assert.equal(s.textColor, '#fafafa');
    assert.equal(s.fontStyle, 'handwriting');
    assert.equal(s.overlays.length, 1);
    assert.equal(s.mentions.length, 1);
    assert.equal(s.mentions[0].username, 'tagged');
    assert.equal(s.link.host, 'example.com');
    assert.deepEqual(s.hashtags, ['korean']);
    assert.ok(s.music, 'music sticker loaded');
    assert.equal(s.music.title, 'Song');
    assert.equal(s.music.startTime, 3);
  });
  ```

- [ ] **Step 2 — run, expect FAIL:**
  `node --experimental-test-module-mocks --test --test-force-exit test/highlightFields.test.js`
  Expected: 2 failures — `Story fields not loaded for highlights: music` (deepEqual `['music']` vs `[]`) and
  `music sticker loaded` (`s.music` undefined). If the first test lists any field other than `music`, the merged
  schema has more than expected: add that field too if a viewer reads it (check app `story_model.dart` fromJson and web
  `src/components/stories/types.ts`), otherwise add it to `NOT_FOR_VIEWERS` with a one-line reason.

- [ ] **Step 3 — implementation** in `models/StoryHighlight.js`, replace the `HIGHLIGHT_STORY_FIELDS` array:
  ```js
  const HIGHLIGHT_STORY_FIELDS = [
    'user', 'mediaUrl', 'mediaUrls', 'mediaType', 'videoMetadata',
    'text', 'backgroundColor', 'textColor', 'fontStyle', 'privacy',
    'overlays', 'mentions', 'location', 'link', 'poll', 'questionBox', 'hashtags', 'music',
    'views', 'viewCount', 'reactions', 'reactionCount', 'replyCount', 'shareCount',
    'allowReplies', 'allowSharing', 'highlight', 'isHighlighted',
    'isActive', 'isArchived', 'archivedAt', 'expiresAt', 'createdAt', 'updatedAt'
  ].join(' ');
  ```
  (Only change: `'music'` added. `replies` and `shares` stay out on purpose — see the test's `NOT_FOR_VIEWERS`.)

- [ ] **Step 4 — run → PASS:** same command, expected `# pass 2`, `# fail 0`. Then
  `node --experimental-test-module-mocks --test --test-force-exit test/storyAudit.test.js` → `# fail 0`.

- [ ] **Step 5 — commit** (with the REMAINING_WORK change from P1-MOM-2 if done together, else alone):
  In `docs/REMAINING_WORK.md` §4 "Web ↔ app parity … Phase 1", change item 4 to
  `- [ ] Item 4: ~~highlights select music~~ done (highlightFields.test.js guards the field list); translate validator uses SUPPORTED_LANGUAGES + tl.`
  ```bash
  git add models/StoryHighlight.js test/highlightFields.test.js docs/REMAINING_WORK.md
  git commit -F - <<'EOF'
  fix(stories): highlights load the music sticker; pin fields to the schema

  The highlight select list missed `music`, which the app parses. A test
  now fails when a Story schema field is neither selected for highlights
  nor listed as not-for-viewers (replies, shares).

  Still open: translate validator codes (item 4), voice transcode (item 5),
  Phase 1 items 1-3 and 6-8, Phase 1 deploy.
  EOF
  ```

---

### Task P1-MOM-2: translate accepts every supported language incl. `tl` (moments#12)

`validators/translationValidator.js:15-20` hard-codes 38 codes and leaves out `uz az kk ky tg tk` (already in
`services/translationService.js:256-258` `SUPPORTED_LANGUAGES`) and `tl` (in neither). Both controllers also gate on
the service list (`controllers/moments.js` ~:1988, `controllers/comments.js:642` → `isValidLanguageCode`), so `tl`
must be added to the service list, and the validator must read that list instead of its own copy.
Translation itself is OpenAI-backed (`aiTranslationService.getEnhancedTranslation`, code passed into the prompt; no
enum on `Translation`/`EnhancedTranslation` models), so new codes need no other change.

**Files:**
- Modify: `services/translationService.js:256-258` (add `'tl'`).
- Modify: `validators/translationValidator.js` (whole file, 27 lines).
- Test (new): `test/translationValidator.test.js`.

**Interfaces:**
- Consumes: `require('../services/translationService').SUPPORTED_LANGUAGES: string[]`,
  `isValidLanguageCode(code): boolean`.
- Produces: `exports.translateValidation` (same name, same position in `routes/moments.js:118-119` and
  `routes/comment.js:50-52`); accepted set = `SUPPORTED_LANGUAGES` (now 45 codes). Error message unchanged
  (`Unsupported language code: <code>`), still HTTP 400 via `middleware/validation.js`.

- [ ] **Step 1 — failing test** `test/translationValidator.test.js`:
  ```js
  'use strict';

  /**
   * moments#12: the translate validator allowed 38 hard-coded codes and left
   * out `tl` (a web UI language) and uz/az/kk/ky/tg/tk (in the app's language
   * picker and already in translationService.SUPPORTED_LANGUAGES). Those users
   * got a 400 on every Translate tap. The validator now reads the service's
   * list, so the two can't drift again.
   */
  const test = require('node:test');
  const assert = require('node:assert/strict');
  const { validationResult } = require('express-validator');
  const { translateValidation } = require('../validators/translationValidator');
  const translationService = require('../services/translationService');

  const errorsFor = async (body) => {
    const req = { body, query: {}, params: {}, cookies: {}, headers: {} };
    for (const chain of translateValidation) await chain.run(req);
    return validationResult(req).array().map((e) => e.path ?? e.param);
  };

  const ADDED = ['tl', 'uz', 'az', 'kk', 'ky', 'tg', 'tk'];

  test('the codes the audit found refused are accepted by the validator and the controllers', async () => {
    for (const code of ADDED) {
      assert.deepEqual(await errorsFor({ targetLanguage: code }), [], `${code} refused by the validator`);
      assert.equal(translationService.isValidLanguageCode(code), true, `${code} refused by the controller gate`);
    }
  });

  test('the validator accepts exactly the service list', async () => {
    for (const code of translationService.SUPPORTED_LANGUAGES) {
      assert.deepEqual(await errorsFor({ targetLanguage: code }), [], `${code} refused`);
    }
  });

  test('case and whitespace are normalised as before', async () => {
    assert.deepEqual(await errorsFor({ targetLanguage: 'TL' }), []);
    assert.deepEqual(await errorsFor({ targetLanguage: ' ko ' }), []);
  });

  test('unknown, empty and non-string codes are still refused', async () => {
    assert.deepEqual(await errorsFor({ targetLanguage: 'xx' }), ['targetLanguage']);
    assert.deepEqual(await errorsFor({ targetLanguage: '' }), ['targetLanguage']);
    assert.deepEqual(await errorsFor({}), ['targetLanguage']);
    assert.deepEqual(await errorsFor({ targetLanguage: 42 }), ['targetLanguage']);
    assert.deepEqual(await errorsFor({ targetLanguage: 'english' }), ['targetLanguage']);
  });
  ```
  Note: `errorsFor` returns one entry per failed rule only if the chain bails; express-validator 7 records every
  failing rule in the chain, so for `''`/`{}`/`42` the array may contain `targetLanguage` more than once. If Step 2
  shows e.g. `['targetLanguage','targetLanguage']` for those *before and after* the change, wrap those three asserts as
  `assert.ok((await errorsFor(x)).includes('targetLanguage'))` — the behaviour under test is "refused", not the count.

- [ ] **Step 2 — run, expect FAIL:**
  `node --experimental-test-module-mocks --test --test-force-exit test/translationValidator.test.js`
  Expected: test 1 fails at `tl refused by the validator` (got `['targetLanguage']`); test 2 fails at `uz refused`.

- [ ] **Step 3 — implementation.**
  `services/translationService.js`, replace the list at :256-258:
  ```js
  exports.SUPPORTED_LANGUAGES = [
    'en', 'zh', 'ko', 'ru', 'es', 'ar', 'fr', 'de', 'ja', 'pt', 'it', 'hi', 'th', 'vi', 'id', 'tr', 'pl', 'nl', 'sv', 'da', 'fi', 'no', 'cs', 'hu', 'ro', 'el', 'he', 'uk', 'bg', 'hr', 'sk', 'sl', 'et', 'lv', 'lt', 'mt', 'ga', 'cy', 'uz', 'az', 'kk', 'ky', 'tg', 'tk',
    'tl' // Tagalog: a web UI language (web src/hooks/useTargetLanguage.ts)
  ];
  ```
  `validators/translationValidator.js`, whole file:
  ```js
  const { body } = require('express-validator');
  const { SUPPORTED_LANGUAGES } = require('../services/translationService');

  /**
   * Validation for translation requests (POST /moments/:id/translate,
   * POST /comments/:id/translate).
   *
   * The accepted codes are translationService.SUPPORTED_LANGUAGES — the same
   * list the controllers check with isValidLanguageCode. This file used to keep
   * its own shorter copy, which refused tl/uz/az/kk/ky/tg/tk with a 400.
   */
  exports.translateValidation = [
    body('targetLanguage')
      .notEmpty().withMessage('Target language is required')
      .isString().withMessage('Target language must be a string')
      .isLength({ min: 2, max: 5 }).withMessage('Target language must be a valid ISO 639-1 code (2-5 characters)')
      .trim()
      .toLowerCase()
      .custom((value) => {
        if (!SUPPORTED_LANGUAGES.includes(value)) {
          throw new Error(`Unsupported language code: ${value}`);
        }
        return true;
      })
  ];
  ```

- [ ] **Step 4 — run → PASS:** same command → `# fail 0`. Also
  `node -e "require('./routes/moments'); require('./routes/comment'); console.log('routes ok')"` → `routes ok`.

- [ ] **Step 5 — commit:** in `docs/REMAINING_WORK.md` tick item 4:
  `- [x] Item 4: highlights select music; translate validator uses SUPPORTED_LANGUAGES + tl (moments#12, #19).`
  ```bash
  git add services/translationService.js validators/translationValidator.js test/translationValidator.test.js docs/REMAINING_WORK.md
  git commit -F - <<'EOF'
  fix(translate): accept every supported language, Tagalog included

  The translate validator kept its own 38-code list and refused tl, uz,
  az, kk, ky, tg and tk with a 400. It now reads
  translationService.SUPPORTED_LANGUAGES, which gains tl, so the
  validator and the controller gate can't drift apart again.

  Still open: voice transcode (item 5), Phase 1 items 1-3 and 6-8,
  Phase 1 deploy.
  EOF
  ```

---

### Task P1-MOM-3: voice transcode helper (`lib/voiceTranscode.js`)

Pure helper, no Express. Decides from the **declared** MIME type whether a voice upload must become AAC, and runs the
system ffmpeg (`FFMPEG_PATH = '/usr/bin/ffmpeg'` from `lib/videoTranscodePlan.js:37`, same as
`utils/videoTranscode.js`). ffmpeg is injected (`runFfmpeg`) so tests never need the binary; one integration test
uses a real ffmpeg when one exists and is skipped otherwise. Like `utils/videoTranscode.js`, every failure returns
`null` (never throws): the caller then keeps the original — today's behaviour.

Command (verified locally with ffmpeg 7 on a libopus WebM: output `ftypM4A`, codec `aac`; a video-only WebM exits
non-zero with "Stream map '0:a:0' matches no streams" → `null` → original kept):
`ffmpeg -hide_banner -loglevel error -nostdin -y -i <in> -vn -map 0:a:0 -c:a aac -b:a 64k -ac 1 -ar 44100 -movflags +faststart -f ipod <out>.m4a`

**Files:**
- Create: `lib/voiceTranscode.js`.
- Test (new): `test/voiceTranscode.test.js`.

**Interfaces:**
- Consumes: `FFMPEG_PATH` (`lib/videoTranscodePlan.js`), `safeUnlink(path): Promise<void>` (`utils/videoTranscode.js:65`).
- Produces:
  - `PASS_THROUGH_AUDIO_TYPES: readonly string[]` = `['audio/mpeg','audio/mp3','audio/aac','audio/x-aac','audio/mp4','audio/m4a','audio/x-m4a']`
  - `AAC_MIME_TYPE = 'audio/mp4'`, `VOICE_TRANSCODE_TIMEOUT_MS = 120000`
  - `normalizeMimeType(mime?: string): string` — lower-cased, parameters (`;codecs=…`) and spaces stripped, `''` for non-strings
  - `needsAacTranscode(mime?: string): boolean` — `true` unless the normalised type is on the pass-through list
  - `buildVoiceTranscodeArgs(inputPath: string, outputPath: string): string[]`
  - `transcodeVoiceToAac(inputPath: string, opts?: { runFfmpeg?, ffmpegPath?, timeoutMs?, tmpDir? }): Promise<{ path: string, bytes: number, mimeType: 'audio/mp4' } | null>`
    where `runFfmpeg(ffmpegPath: string, args: string[], { timeout, maxBuffer }): Promise<unknown>` (defaults to
    promisified `child_process.execFile`).

- [ ] **Step 1 — failing test** `test/voiceTranscode.test.js`:
  ```js
  'use strict';

  /**
   * moments#2 / chat#13: web records voice as WebM/Opus and the backend stored
   * it as-is; iOS (AVPlayer, via just_audio) cannot play WebM. Voice uploads
   * whose declared type is not AAC/MP3 are now converted to AAC .m4a.
   */
  const test = require('node:test');
  const assert = require('node:assert/strict');
  const fs = require('fs');
  const os = require('os');
  const path = require('path');
  const { execFileSync } = require('child_process');

  const {
    PASS_THROUGH_AUDIO_TYPES, AAC_MIME_TYPE, normalizeMimeType, needsAacTranscode,
    buildVoiceTranscodeArgs, transcodeVoiceToAac,
  } = require('../lib/voiceTranscode');

  const tmp = () => fs.mkdtempSync(path.join(os.tmpdir(), 'voice-tc-'));
  const realError = console.error;
  test.beforeEach(() => { console.error = () => {}; });
  test.afterEach(() => { console.error = realError; });

  test('the pass-through list is exactly the AAC/MP3 types of the upload whitelist', () => {
    assert.deepEqual([...PASS_THROUGH_AUDIO_TYPES].sort(), [
      'audio/aac', 'audio/m4a', 'audio/mp3', 'audio/mp4', 'audio/mpeg', 'audio/x-aac', 'audio/x-m4a',
    ]);
    const { ALLOWED_AUDIO_TYPES } = require('../middleware/uploadToSpaces');
    for (const t of PASS_THROUGH_AUDIO_TYPES) assert.ok(ALLOWED_AUDIO_TYPES.includes(t), `${t} not uploadable`);
  });

  test('normalizeMimeType strips parameters, case and spaces', () => {
    assert.equal(normalizeMimeType('audio/webm;codecs=opus'), 'audio/webm');
    assert.equal(normalizeMimeType(' Audio/MP4 ; codecs="mp4a.40.2"'), 'audio/mp4');
    assert.equal(normalizeMimeType(undefined), '');
    assert.equal(normalizeMimeType(42), '');
  });

  test('only non-AAC/MP3 declared types need a transcode', () => {
    for (const t of PASS_THROUGH_AUDIO_TYPES) assert.equal(needsAacTranscode(t), false, t);
    assert.equal(needsAacTranscode('audio/M4A'), false);
    for (const t of ['audio/webm', 'audio/webm;codecs=opus', 'audio/ogg', 'audio/opus', 'audio/wav',
      'audio/x-wav', 'audio/wave', 'audio/flac', 'audio/x-flac', 'audio/3gpp', 'audio/amr',
      'video/webm', 'video/mp4', '', undefined]) {
      assert.equal(needsAacTranscode(t), true, String(t));
    }
  });

  test('the ffmpeg arguments drop video, keep the first audio stream and write AAC in an M4A container', () => {
    const args = buildVoiceTranscodeArgs('/tmp/in-file', '/tmp/out.m4a');
    assert.equal(args[args.indexOf('-i') + 1], '/tmp/in-file');
    assert.equal(args[args.length - 1], '/tmp/out.m4a');
    for (const pair of [['-c:a', 'aac'], ['-map', '0:a:0'], ['-f', 'ipod'], ['-movflags', '+faststart']]) {
      assert.equal(args[args.indexOf(pair[0]) + 1], pair[1], pair[0]);
    }
    assert.ok(args.includes('-vn'));
    assert.ok(args.includes('-nostdin'));
    assert.ok(args.indexOf('-y') < args.indexOf('-i'));
  });

  test('a successful run returns the local AAC file', async () => {
    const dir = tmp();
    let seen = null;
    const runFfmpeg = async (bin, args, opts) => {
      seen = { bin, args, opts };
      fs.writeFileSync(args[args.length - 1], Buffer.from('fake-aac'));
    };
    const out = await transcodeVoiceToAac('/x/in', { runFfmpeg, ffmpegPath: '/opt/ff', tmpDir: dir, timeoutMs: 1234 });
    assert.equal(seen.bin, '/opt/ff');
    assert.equal(seen.opts.timeout, 1234);
    assert.equal(out.mimeType, AAC_MIME_TYPE);
    assert.equal(out.bytes, 8);
    assert.ok(out.path.startsWith(dir) && out.path.endsWith('.m4a'));
    assert.equal(fs.readFileSync(out.path, 'utf8'), 'fake-aac');
  });

  test('defaults: system ffmpeg path and the voice timeout', async () => {
    const dir = tmp();
    let seen = null;
    await transcodeVoiceToAac('/x/in', {
      tmpDir: dir,
      runFfmpeg: async (bin, args, opts) => { seen = { bin, opts }; fs.writeFileSync(args[args.length - 1], 'a'); },
    });
    assert.equal(seen.bin, '/usr/bin/ffmpeg');
    assert.equal(seen.opts.timeout, 120000);
  });

  test('ffmpeg missing, failing or producing nothing returns null and leaves no file', async () => {
    const dir = tmp();
    const enoent = Object.assign(new Error('spawn /usr/bin/ffmpeg ENOENT'), { code: 'ENOENT' });
    assert.equal(await transcodeVoiceToAac('/x/in', { tmpDir: dir, runFfmpeg: async () => { throw enoent; } }), null);
    assert.equal(await transcodeVoiceToAac('/x/in', {
      tmpDir: dir,
      runFfmpeg: async (b, args) => { fs.writeFileSync(args[args.length - 1], 'partial'); throw new Error('exit 1'); },
    }), null);
    assert.equal(await transcodeVoiceToAac('/x/in', {
      tmpDir: dir, runFfmpeg: async (b, args) => { fs.writeFileSync(args[args.length - 1], ''); },
    }), null);
    assert.equal(await transcodeVoiceToAac('/x/in', { tmpDir: dir, runFfmpeg: async () => {} }), null);
    assert.deepEqual(fs.readdirSync(dir), []);
  });

  // Real ffmpeg, when this machine has one (the server's is /usr/bin/ffmpeg).
  const REAL_FFMPEG = ['/usr/bin/ffmpeg', '/opt/homebrew/bin/ffmpeg', '/usr/local/bin/ffmpeg'].find((p) => fs.existsSync(p));

  test('real ffmpeg turns a WebM/Opus note into an M4A/AAC file', { skip: !REAL_FFMPEG && 'no ffmpeg on this machine' }, async () => {
    const dir = tmp();
    const input = path.join(dir, 'in.webm');
    execFileSync(REAL_FFMPEG, ['-hide_banner', '-loglevel', 'quiet', '-nostdin', '-y', '-f', 'lavfi',
      '-i', 'sine=frequency=440:duration=1', '-c:a', 'libopus', input]);
    const out = await transcodeVoiceToAac(input, { ffmpegPath: REAL_FFMPEG, tmpDir: dir });
    assert.ok(out, 'transcode succeeded');
    const head = fs.readFileSync(out.path).subarray(4, 12).toString('latin1');
    assert.equal(head, 'ftypM4A ', 'M4A container');
    assert.ok(out.bytes > 0);
  });

  test('real ffmpeg on a WebM with no audio stream returns null (original is kept)', { skip: !REAL_FFMPEG && 'no ffmpeg on this machine' }, async () => {
    const dir = tmp();
    const input = path.join(dir, 'silent.webm');
    execFileSync(REAL_FFMPEG, ['-hide_banner', '-loglevel', 'quiet', '-nostdin', '-y', '-f', 'lavfi',
      '-i', 'color=c=black:s=16x16:d=1', '-c:v', 'libvpx', input]);
    assert.equal(await transcodeVoiceToAac(input, { ffmpegPath: REAL_FFMPEG, tmpDir: dir }), null);
    assert.deepEqual(fs.readdirSync(dir), ['silent.webm']);
  });
  ```

- [ ] **Step 2 — run, expect FAIL:**
  `node --experimental-test-module-mocks --test --test-force-exit test/voiceTranscode.test.js`
  Expected: `Error: Cannot find module '../lib/voiceTranscode'` (whole file fails).

- [ ] **Step 3 — implementation** `lib/voiceTranscode.js`:
  ```js
  'use strict';

  /**
   * Voice notes to AAC (.m4a), synchronously, before the upload is stored.
   *
   * Why: the web records with MediaRecorder, which gives WebM/Opus in Chrome and
   * Firefox. The app plays voice with just_audio, i.e. AVPlayer on iOS, and
   * AVPlayer cannot open WebM — so web voice notes were silent for iOS users
   * (moments#2, chat#13). AAC in an M4A container plays in AVPlayer, ExoPlayer
   * and every browser.
   *
   * Decided from the client-DECLARED type: AAC/MP3 types pass through untouched
   * (what the app records), everything else is converted. A file whose
   * declared type lies (WebM bytes labelled audio/mp4) passes through as today.
   *
   * SAFETY PROPERTY (same as utils/videoTranscode.js): every failure returns
   * null and never throws. The caller then stores the original, which is
   * exactly the pre-transcode behaviour — never worse.
   */

  const { execFile } = require('child_process');
  const fs = require('fs');
  const os = require('os');
  const path = require('path');
  const { promisify } = require('util');
  const { FFMPEG_PATH } = require('./videoTranscodePlan');
  const { safeUnlink } = require('../utils/videoTranscode');

  /** The AAC/MP3 types already on the upload whitelist (middleware/uploadToSpaces.js). */
  const PASS_THROUGH_AUDIO_TYPES = Object.freeze([
    'audio/mpeg', 'audio/mp3', 'audio/aac', 'audio/x-aac', 'audio/mp4', 'audio/m4a', 'audio/x-m4a',
  ]);

  const AAC_MIME_TYPE = 'audio/mp4';

  /** Chat voice is capped at 5 minutes; AAC encodes that in a few seconds. */
  const VOICE_TRANSCODE_TIMEOUT_MS = 2 * 60 * 1000;

  const normalizeMimeType = (mime) => (
    typeof mime === 'string' ? mime.split(';')[0].trim().toLowerCase() : ''
  );

  const needsAacTranscode = (mime) => !PASS_THROUGH_AUDIO_TYPES.includes(normalizeMimeType(mime));

  /**
   * -vn + -map 0:a:0: a "video/webm" that is really a voice note keeps only its
   * audio; a file with no audio stream at all makes ffmpeg fail (-> null ->
   * original kept). Mono 64 kb/s is plenty for speech. -f ipod writes an M4A
   * brand, which AVPlayer identifies without relying on the extension.
   */
  const buildVoiceTranscodeArgs = (inputPath, outputPath) => [
    '-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
    '-i', inputPath,
    '-vn', '-map', '0:a:0',
    '-c:a', 'aac', '-b:a', '64k', '-ac', '1', '-ar', '44100',
    '-movflags', '+faststart',
    '-f', 'ipod',
    outputPath,
  ];

  const execFileAsync = promisify(execFile);
  const defaultRunFfmpeg = (ffmpegPath, args, options) => execFileAsync(ffmpegPath, args, options);

  /**
   * @returns {Promise<{path: string, bytes: number, mimeType: string}|null>}
   */
  const transcodeVoiceToAac = async (inputPath, {
    runFfmpeg = defaultRunFfmpeg,
    ffmpegPath = FFMPEG_PATH,
    timeoutMs = VOICE_TRANSCODE_TIMEOUT_MS,
    tmpDir = os.tmpdir(),
  } = {}) => {
    const output = path.join(
      tmpDir,
      `voice-out-${Date.now()}-${Math.random().toString(36).slice(2)}.m4a`
    );
    try {
      // execFile, not exec: arguments stay an array, nothing is shell-parsed.
      await runFfmpeg(ffmpegPath, buildVoiceTranscodeArgs(inputPath, output), {
        timeout: timeoutMs,
        maxBuffer: 1024 * 1024,
      });
      const stat = await fs.promises.stat(output);
      if (!stat.size) {
        await safeUnlink(output);
        return null;
      }
      return { path: output, bytes: stat.size, mimeType: AAC_MIME_TYPE };
    } catch (err) {
      console.error('⚠️  voice transcode failed, keeping original:', err.message);
      await safeUnlink(output);
      return null;
    }
  };

  module.exports = {
    PASS_THROUGH_AUDIO_TYPES,
    AAC_MIME_TYPE,
    VOICE_TRANSCODE_TIMEOUT_MS,
    normalizeMimeType,
    needsAacTranscode,
    buildVoiceTranscodeArgs,
    transcodeVoiceToAac,
  };
  ```

- [ ] **Step 4 — run → PASS:** same command → `# fail 0` (the two real-ffmpeg tests run on this Mac via
  `/opt/homebrew/bin/ffmpeg`, `# skipped 0`; on a machine without ffmpeg they show as skipped).

- [ ] **Step 5 — commit:** `docs/REMAINING_WORK.md` item 5 →
  `- [ ] Item 5: voice notes transcoded to AAC .m4a — helper lib/voiceTranscode.js done; routes not wired yet.`
  ```bash
  git add lib/voiceTranscode.js test/voiceTranscode.test.js docs/REMAINING_WORK.md
  git commit -F - <<'EOF'
  feat(voice): helper that converts non-AAC voice notes to AAC .m4a

  Decides from the declared type (AAC/MP3 pass through), runs the system
  ffmpeg with injected execution for tests, and returns null on any
  failure so callers keep the original.

  Still open: wire it into PUT /moments/:id/audio and POST
  /messages/voice (item 5), Phase 1 items 1-3 and 6-8, Phase 1 deploy.
  EOF
  ```

---

### Task P1-MOM-4: voice upload middleware stages to disk, transcodes, uploads only the AAC

Replaces `uploadSingle` (multer-s3 streaming) on exactly two routes:
- `routes/moments.js:101-107` — `PUT /moments/:id/audio`, field `audio`, folder `bananatalk/moments/audio`
- `routes/messages.js:72-79` — `POST /messages/voice`, field `voice`, folder `bananatalk/voice`

The new middleware leaves `req.file` in the **same shape multer-s3 did** (`location`, `key`, `mimetype`, `size`,
`originalname`), so the controllers (`controllers/moments.js` `momentAudioUpload` ~:1121-1212,
`controllers/advancedMessages.js` `sendVoiceMessage` :829-937) and `checkConversationStart.discardUpload` need **no
change**: they keep deleting `req.file.location` on refusal, and store `req.file.location` / `req.file.mimetype`.
After a transcode those are the AAC URL and `audio/mp4`, and `originalname` ends in `.m4a`, so
`utils/audioUtils.js validateAudioFile` (moment route: extension + MIME + 10 MB check) accepts it.

**Files:**
- Create: `middleware/uploadVoiceNote.js`.
- Modify: `middleware/uploadToSpaces.js:241-299` — add `BUCKET_NAME` to `module.exports` (one line, next to `BUCKET_URL`).
- Modify: `routes/moments.js:35` (import) and `:99-107` (route); `routes/messages.js:19` (import) and `:71-79` (route).
- Tests (new): `test/uploadVoiceNote.test.js` (middleware, supertest, injected S3 + transcode),
  `test/voiceRoutesWiring.test.js` (routes use it, `mock.module`).

**Interfaces:**
- Consumes: `transcodeVoiceToAac`, `needsAacTranscode`, `normalizeMimeType` (P1-MOM-3); `isUploadTypeAllowed`,
  `fixS3Url`, `BUCKET_NAME`, `BUCKET_URL` (`middleware/uploadToSpaces.js`); `MEDIA_CACHE_CONTROL`
  (`lib/mediaCacheControl.js`); `safeUnlink` (`utils/videoTranscode.js`); `s3.upload(params).promise() →
  { Location }` (`config/spaces.js`, aws-sdk v2).
- Produces:
  - `VOICE_UPLOAD_MAX_BYTES = 25 * 1024 * 1024` (the cap `GET /messages/video-config` already advertises for voice)
  - `createVoiceUpload({ s3?, transcode?, tmpDir?, maxBytes? }) → (fieldName: string, folder: string) → express middleware`
  - `uploadVoiceNote(fieldName: string, folder: string) → express middleware` (= `createVoiceUpload()` with the real
    Spaces client and `transcodeVoiceToAac`)
  - On success `req.file = { fieldname, originalname, encoding, mimetype, size, location, key }` (no `path`; the staged
    file is gone). On no file: `next()` with `req.file` undefined (controllers already 400). Errors: multer
    `LIMIT_FILE_SIZE` → 400 "File is too large"; disallowed type → 400 "File type not allowed! …"; S3 failure → passed
    to `next(err)` (500). In every case the local temp files are deleted before `next` is called.

**Behaviour changes to note in the commit / QA:**
- Chat voice is now capped at 25 MB at upload (was 1 GB via the shared multer limit; the cap matches what
  `/messages/video-config` already advertises). Moment audio stays 10 MB in the controller.
- App 2.6.1 uploads (`audio/m4a`, `audio/mp4`) pass through unchanged (staged to disk first instead of streamed).
  App `audio/wav` / `audio/ogg` / `audio/webm` uploads (possible via `media_service.dart` / `message_provider.dart`)
  are now converted to AAC too — strictly better for playback, smaller files.

- [ ] **Step 1 — failing middleware test** `test/uploadVoiceNote.test.js`:
  ```js
  'use strict';

  /**
   * Voice uploads (PUT /moments/:id/audio, POST /messages/voice) are staged to
   * local disk, converted to AAC when the declared type is not AAC/MP3, and
   * only the AAC is stored (moments#2, chat#13). req.file keeps the shape
   * multer-s3 produced, so the controllers and checkConversationStart's
   * cleanup work unchanged. ffmpeg and Spaces are injected.
   */
  const test = require('node:test');
  const assert = require('node:assert/strict');
  const fs = require('fs');
  const os = require('os');
  const path = require('path');
  const express = require('express');
  const request = require('supertest');

  const { createVoiceUpload, VOICE_UPLOAD_MAX_BYTES } = require('../middleware/uploadVoiceNote');
  const { validateAudioFile } = require('../utils/audioUtils');

  let tmpDir, uploads, transcodeCalls, transcodeBehaviour, s3Behaviour, logged;
  const realError = console.error;

  const fakeS3 = {
    upload(params) {
      return {
        promise: async () => {
          const chunks = [];
          for await (const c of params.Body) chunks.push(c);
          const stored = { ...params, body: Buffer.concat(chunks) };
          delete stored.Body;
          if (s3Behaviour) await s3Behaviour(stored);
          uploads.push(stored);
          return { Location: `https://my-projects-media.sfo3.digitaloceanspaces.com/${params.Key}` };
        },
      };
    },
  };

  const fakeTranscode = async (inputPath, opts) => {
    transcodeCalls.push({ inputPath, opts, input: fs.readFileSync(inputPath) });
    return transcodeBehaviour(inputPath, opts);
  };
  const succeed = async (inputPath, { tmpDir: dir }) => {
    const out = path.join(dir, `fake-${Date.now()}.m4a`);
    fs.writeFileSync(out, Buffer.from('AAC-BYTES'));
    return { path: out, bytes: 9, mimeType: 'audio/mp4' };
  };

  const appFor = (field = 'voice', folder = 'bananatalk/voice') => {
    const app = express();
    const upload = createVoiceUpload({ s3: fakeS3, transcode: fakeTranscode, tmpDir })(field, folder);
    app.post('/up', upload, (req, res) => res.json({ file: req.file || null }));
    app.use(require('../middleware/error'));
    return app;
  };

  test.beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'voice-up-'));
    uploads = []; transcodeCalls = []; logged = [];
    transcodeBehaviour = succeed;
    s3Behaviour = null;
    console.error = (...a) => { logged.push(a.join(' ')); };
  });
  test.afterEach(() => { console.error = realError; });

  const WEBM = Buffer.from('1a45dfa3-pretend-webm-opus');

  test('a WebM voice note is stored only as AAC, under an .m4a key', async () => {
    const res = await request(appFor()).post('/up')
      .attach('voice', WEBM, { filename: 'voice.webm', contentType: 'audio/webm' });
    assert.equal(res.status, 200, JSON.stringify(res.body));
    assert.equal(transcodeCalls.length, 1);
    assert.deepEqual(transcodeCalls[0].input, WEBM, 'ffmpeg got the uploaded bytes');
    assert.equal(uploads.length, 1, 'the original is never stored');
    const [u] = uploads;
    assert.match(u.Key, /^bananatalk\/voice\/\d+-voice\.m4a$/);
    assert.equal(u.ContentType, 'audio/mp4');
    assert.equal(u.ACL, 'public-read');
    assert.equal(u.Bucket, 'my-projects-media');
    assert.equal(u.body.toString(), 'AAC-BYTES');
    const f = res.body.file;
    assert.equal(f.location, `https://my-projects-media.sfo3.digitaloceanspaces.com/${u.Key}`);
    assert.equal(f.key, u.Key);
    assert.equal(f.mimetype, 'audio/mp4');
    assert.equal(f.size, 9);
    assert.equal(f.originalname, 'voice.m4a');
    assert.equal(f.path, undefined, 'no local path leaks to the controller');
    assert.equal(validateAudioFile(f, 'pronunciation').valid, true, 'moment controller accepts the result');
    assert.deepEqual(fs.readdirSync(tmpDir), [], 'staged and transcoded temp files removed');
  });

  test('a MIME type with codec parameters is still recognised as WebM', async () => {
    const res = await request(appFor()).post('/up')
      .attach('voice', WEBM, { filename: 'voice-note.webm', contentType: 'audio/webm;codecs=opus' });
    assert.equal(res.status, 200, JSON.stringify(res.body));
    assert.equal(transcodeCalls.length, 1);
    assert.match(uploads[0].Key, /-voice-note\.m4a$/);
    assert.equal(uploads[0].ContentType, 'audio/mp4');
  });

  test('a voice note mislabelled video/webm is converted too', async () => {
    const res = await request(appFor()).post('/up')
      .attach('voice', WEBM, { filename: 'blob', contentType: 'video/webm' });
    assert.equal(res.status, 200, JSON.stringify(res.body));
    assert.equal(transcodeCalls.length, 1);
    assert.match(uploads[0].Key, /-blob\.m4a$/);
    assert.equal(res.body.file.mimetype, 'audio/mp4');
  });

  for (const type of ['audio/mpeg', 'audio/mp3', 'audio/aac', 'audio/x-aac', 'audio/mp4', 'audio/m4a', 'audio/x-m4a']) {
    test(`${type} passes through untouched`, async () => {
      const bytes = Buffer.from(`original-${type}`);
      const res = await request(appFor()).post('/up')
        .attach('voice', bytes, { filename: 'rec.m4a', contentType: type });
      assert.equal(res.status, 200, JSON.stringify(res.body));
      assert.equal(transcodeCalls.length, 0);
      assert.equal(uploads.length, 1);
      assert.equal(uploads[0].ContentType, type);
      assert.match(uploads[0].Key, /^bananatalk\/voice\/\d+-rec\.m4a$/);
      assert.deepEqual(uploads[0].body, bytes);
      assert.equal(res.body.file.mimetype, type);
      assert.equal(res.body.file.size, bytes.length);
      assert.deepEqual(fs.readdirSync(tmpDir), []);
    });
  }

  test('when ffmpeg fails the original is stored as before and the failure is logged', async () => {
    transcodeBehaviour = async () => null;
    const res = await request(appFor()).post('/up')
      .attach('voice', WEBM, { filename: 'voice.webm', contentType: 'audio/webm' });
    assert.equal(res.status, 200, JSON.stringify(res.body));
    assert.equal(uploads.length, 1);
    assert.equal(uploads[0].ContentType, 'audio/webm');
    assert.match(uploads[0].Key, /-voice\.webm$/);
    assert.deepEqual(uploads[0].body, WEBM);
    assert.equal(res.body.file.mimetype, 'audio/webm');
    assert.ok(logged.some((l) => l.includes('voice transcode') && l.includes('audio/webm')), logged.join('\n'));
    assert.deepEqual(fs.readdirSync(tmpDir), []);
  });

  test('a transcoder that throws is treated like a failed transcode', async () => {
    transcodeBehaviour = async () => { throw new Error('boom'); };
    const res = await request(appFor()).post('/up')
      .attach('voice', WEBM, { filename: 'voice.webm', contentType: 'audio/webm' });
    assert.equal(res.status, 200, JSON.stringify(res.body));
    assert.equal(uploads[0].ContentType, 'audio/webm');
  });

  test('the moment route folder and field are honoured', async () => {
    const res = await request(appFor('audio', 'bananatalk/moments/audio')).post('/up')
      .attach('audio', WEBM, { filename: '../../x y.webm', contentType: 'audio/ogg' });
    assert.equal(res.status, 200, JSON.stringify(res.body));
    assert.match(uploads[0].Key, /^bananatalk\/moments\/audio\/\d+-x_y\.m4a$/, 'path parts and spaces never reach the key');
  });

  test('an upload over the voice cap is refused with 400 and nothing is stored or left on disk', async () => {
    const res = await request(appFor()).post('/up')
      .attach('voice', Buffer.alloc(VOICE_UPLOAD_MAX_BYTES + 1), { filename: 'big.webm', contentType: 'audio/webm' });
    assert.equal(res.status, 400);
    assert.equal(uploads.length, 0);
    assert.equal(transcodeCalls.length, 0);
    assert.deepEqual(fs.readdirSync(tmpDir), []);
  });

  test('a type outside the upload whitelist is refused with 400', async () => {
    const res = await request(appFor()).post('/up')
      .attach('voice', Buffer.from('MZ'), { filename: 'x.exe', contentType: 'application/x-msdownload' });
    assert.equal(res.status, 400);
    assert.match(res.body.error || res.body.message, /File type not allowed/);
    assert.equal(uploads.length, 0);
    assert.deepEqual(fs.readdirSync(tmpDir), []);
  });

  test('a Spaces failure is an error response and still cleans up', async () => {
    s3Behaviour = async () => { throw new Error('spaces down'); };
    const res = await request(appFor()).post('/up')
      .attach('voice', WEBM, { filename: 'voice.webm', contentType: 'audio/webm' });
    assert.equal(res.status, 500);
    assert.deepEqual(fs.readdirSync(tmpDir), []);
  });

  test('no file: the request continues without req.file', async () => {
    const res = await request(appFor()).post('/up').field('receiver', 'abc');
    assert.equal(res.status, 200);
    assert.equal(res.body.file, null);
    assert.equal(uploads.length, 0);
  });
  ```

- [ ] **Step 2 — failing wiring test** `test/voiceRoutesWiring.test.js`:
  ```js
  'use strict';

  /**
   * Both voice routes use the transcoding voice upload, not the streaming
   * multer-s3 uploadSingle. On /messages/voice it must still run BEFORE
   * checkConversationStart (receiver is multipart; the cap needs the parsed
   * body, and its refusal deletes req.file.location).
   *
   * Run with --experimental-test-module-mocks.
   */
  const test = require('node:test');
  const { mock } = require('node:test');
  const assert = require('node:assert/strict');

  const calls = [];
  const fakeUploadVoiceNote = (fieldName, folder) => {
    const mw = function voiceUploadSentinel(req, res, next) { next(); };
    calls.push({ fieldName, folder, mw });
    return mw;
  };
  mock.module('../middleware/uploadVoiceNote.js', {
    namedExports: {
      uploadVoiceNote: fakeUploadVoiceNote,
      createVoiceUpload: () => fakeUploadVoiceNote,
      VOICE_UPLOAD_MAX_BYTES: 25 * 1024 * 1024,
    },
  });

  const messagesRouter = require('../routes/messages');
  const momentsRouter = require('../routes/moments');
  const { checkConversationStart } = require('../middleware/checkConversationStart');

  const handlers = (router, routePath, method) => {
    const layer = router.stack.find((l) => l.route && l.route.path === routePath && l.route.methods[method]);
    assert.ok(layer, `${method.toUpperCase()} ${routePath} exists`);
    return layer.route.stack.filter((s) => s.method === method).map((s) => s.handle);
  };

  test('POST /messages/voice uploads through the voice transcoder, before the conversation cap', () => {
    const call = calls.find((c) => c.fieldName === 'voice');
    assert.ok(call, 'uploadVoiceNote("voice", …) was used');
    assert.equal(call.folder, 'bananatalk/voice');
    const chain = handlers(messagesRouter, '/voice', 'post');
    const at = chain.indexOf(call.mw);
    assert.ok(at >= 0, 'voice upload is in the route chain');
    assert.ok(at < chain.indexOf(checkConversationStart), 'upload runs before checkConversationStart');
  });

  test('PUT /moments/:id/audio uploads through the voice transcoder', () => {
    const call = calls.find((c) => c.fieldName === 'audio');
    assert.ok(call, 'uploadVoiceNote("audio", …) was used');
    assert.equal(call.folder, 'bananatalk/moments/audio');
    assert.ok(handlers(momentsRouter, '/:id/audio', 'put').includes(call.mw));
  });

  test('no other route was switched to the voice transcoder', () => {
    assert.deepEqual(calls.map((c) => c.fieldName).sort(), ['audio', 'voice']);
  });
  ```

- [ ] **Step 3 — run both, expect FAIL:**
  ```bash
  node --experimental-test-module-mocks --test --test-force-exit test/uploadVoiceNote.test.js
  node --experimental-test-module-mocks --test --test-force-exit test/voiceRoutesWiring.test.js
  ```
  Expected: first → `Cannot find module '../middleware/uploadVoiceNote'`. Second → the mocked module resolves to a
  non-existent file; either `Cannot find module` or (if mocking a missing file is allowed) all three tests fail with
  `uploadVoiceNote("voice", …) was used` / `("audio", …)` because the routes still call `uploadSingle`.

- [ ] **Step 4 — implementation.**
  `middleware/uploadToSpaces.js`, in `module.exports` next to `BUCKET_URL,` add:
  ```js
    BUCKET_NAME,
  ```
  `middleware/uploadVoiceNote.js` (new):
  ```js
  'use strict';

  /**
   * Voice-note upload for PUT /moments/:id/audio and POST /messages/voice.
   *
   * Unlike uploadSingle (multer-s3, streamed straight to Spaces), this stages
   * the file on local disk so a non-AAC voice note (web WebM/Opus, WAV, OGG …)
   * can be converted to AAC .m4a BEFORE anything is stored: iOS (AVPlayer)
   * cannot play WebM (moments#2, chat#13). Only the AAC is uploaded and only its
   * URL reaches the controller; the original never leaves this server. If the
   * conversion fails the original is uploaded unchanged and the failure logged
   * — the old behaviour, never worse.
   *
   * req.file ends up in the shape multer-s3 produced (location, key, mimetype,
   * size, originalname), so the controllers and checkConversationStart's
   * discardUpload keep working unchanged. Local temp files are always removed
   * before the next middleware runs.
   */

  const crypto = require('crypto');
  const fs = require('fs');
  const os = require('os');
  const path = require('path');
  const multer = require('multer');
  const { MEDIA_CACHE_CONTROL } = require('../lib/mediaCacheControl');
  const {
    isUploadTypeAllowed, fixS3Url, BUCKET_NAME, BUCKET_URL,
  } = require('./uploadToSpaces');
  const {
    transcodeVoiceToAac, needsAacTranscode, normalizeMimeType,
  } = require('../lib/voiceTranscode');
  const { safeUnlink } = require('../utils/videoTranscode');

  /** The voice cap GET /messages/video-config already advertises. */
  const VOICE_UPLOAD_MAX_BYTES = 25 * 1024 * 1024;

  /** Client filename -> a key-safe base name (no directories, no spaces). */
  const safeFileName = (originalname) => {
    const base = path.basename(String(originalname || ''))
      .replace(/[^A-Za-z0-9._-]/g, '_')
      .replace(/^[._]+/, '')
      .slice(-100);
    return base || 'voice';
  };

  const withM4aExtension = (name) => `${name.replace(/\.[A-Za-z0-9]{1,5}$/, '')}.m4a`;

  const createVoiceUpload = ({
    s3 = null,
    transcode = transcodeVoiceToAac,
    tmpDir = os.tmpdir(),
    maxBytes = VOICE_UPLOAD_MAX_BYTES,
  } = {}) => (fieldName, folder) => {
    const staging = multer({
      storage: multer.diskStorage({
        destination: tmpDir,
        filename: (req, file, cb) =>
          cb(null, `voice-in-${Date.now()}-${crypto.randomBytes(6).toString('hex')}`),
      }),
      limits: { fileSize: maxBytes, files: 1 },
      fileFilter: (req, file, cb) => {
        if (!isUploadTypeAllowed(normalizeMimeType(file.mimetype))) {
          return cb(new Error('File type not allowed! Voice notes must be audio (M4A, AAC, MP3, WAV, OGG, Opus, WebM, FLAC, AMR).'));
        }
        cb(null, true);
      },
    });

    return (req, res, next) => {
      staging.single(fieldName)(req, res, async (uploadErr) => {
        if (uploadErr) {
          // multer removes its own partial file on a limit error; this covers the rest.
          if (req.file && req.file.path) await safeUnlink(req.file.path);
          return next(uploadErr);
        }
        if (!req.file) return next();

        const stagedPath = req.file.path;
        let transcoded = null;
        let failure = null;

        try {
          const declared = normalizeMimeType(req.file.mimetype);
          let bodyPath = stagedPath;
          let contentType = req.file.mimetype;
          let name = safeFileName(req.file.originalname);
          let size = req.file.size;

          if (needsAacTranscode(declared)) {
            try {
              transcoded = await transcode(stagedPath, { tmpDir });
            } catch (err) {
              transcoded = null;
              console.error('⚠️  voice transcode threw:', err.message);
            }
            if (transcoded) {
              bodyPath = transcoded.path;
              contentType = transcoded.mimeType;
              name = withM4aExtension(name);
              size = transcoded.bytes;
            } else {
              console.error(`⚠️  voice transcode failed for ${declared} (${req.file.size} bytes); storing the original`);
            }
          }

          const key = `${folder}/${Date.now()}-${name}`;
          const client = s3 || require('../config/spaces');
          const result = await client.upload({
            Bucket: BUCKET_NAME,
            Key: key,
            Body: fs.createReadStream(bodyPath),
            ACL: 'public-read',
            ContentType: contentType,
            CacheControl: MEDIA_CACHE_CONTROL,
          }).promise();

          req.file = {
            fieldname: req.file.fieldname,
            originalname: name,
            encoding: req.file.encoding,
            mimetype: contentType,
            size,
            location: (result && result.Location) || `${BUCKET_URL}/${key}`,
            key,
          };
          fixS3Url(req.file);
        } catch (err) {
          failure = err;
        } finally {
          await safeUnlink(stagedPath);
          if (transcoded) await safeUnlink(transcoded.path);
        }

        return failure ? next(failure) : next();
      });
    };
  };

  const uploadVoiceNote = (fieldName, folder) => createVoiceUpload()(fieldName, folder);

  module.exports = { createVoiceUpload, uploadVoiceNote, VOICE_UPLOAD_MAX_BYTES };
  ```
  Note on the pass-through name: the key keeps the client's (sanitised) name, e.g. `rec.m4a`; only transcoded files are
  renamed to `.m4a`. On ffmpeg failure the key keeps the original extension (`voice.webm`), as today.

  `routes/moments.js` — replace the import on line 35 (`uploadSingle` was used only by the audio route, :104):
  ```js
  const { uploadMultipleCompressed } = require('../middleware/uploadToSpaces');
  const { uploadVoiceNote } = require('../middleware/uploadVoiceNote');
  ```
  and replace the audio route block (`:99-107`):
  ```js
  // Audio upload (voice-note moments, max 60 seconds)
  // Staged to disk and converted to AAC .m4a unless already AAC/MP3, so web
  // WebM notes play on iOS (middleware/uploadVoiceNote.js).
  router.route('/:id/audio')
    .put(
      protect,
      uploadVoiceNote('audio', 'bananatalk/moments/audio'),
      momentAudioUpload
    )
    .delete(protect, deleteAudio);
  ```
  `routes/messages.js` — replace line 19 (`uploadSingle` was used only by the voice route, :75):
  ```js
  const { uploadSingleCompressed } = require('../middleware/uploadToSpaces');
  const { uploadVoiceNote } = require('../middleware/uploadVoiceNote');
  ```
  and replace the voice route (`:71-79`):
  ```js
  // Voice messages — staged to disk and converted to AAC .m4a unless already
  // AAC/MP3 (middleware/uploadVoiceNote.js), so web WebM notes play on iOS.
  router.route('/voice').post(
    protect,
    checkMessageLimit,
    uploadVoiceNote('voice', 'bananatalk/voice'),
    // AFTER the upload, for the same reason as /video above.
    checkConversationStart,
    advancedMessages.sendVoiceMessage
  );
  ```

- [ ] **Step 5 — run → PASS:**
  ```bash
  node --experimental-test-module-mocks --test --test-force-exit test/uploadVoiceNote.test.js
  node --experimental-test-module-mocks --test --test-force-exit test/voiceRoutesWiring.test.js
  node --experimental-test-module-mocks --test --test-force-exit test/conversationCapUploadCleanup.test.js test/momentDeleteAudio.test.js test/uploadAudioTypes.test.js test/uploadErrorMapping.test.js
  ```
  Expected: all `# fail 0`. Then the full suite → only `authSecretRotation` fails.

- [ ] **Step 6 — local end-to-end smoke with real ffmpeg** (no Spaces needed; proves the default wiring calls ffmpeg —
  `/usr/bin/ffmpeg` doesn't exist on this Mac, so the default path is exercised as "ffmpeg missing → original kept"):
  ```bash
  node -e "
  const { transcodeVoiceToAac } = require('./lib/voiceTranscode');
  transcodeVoiceToAac('/nonexistent').then(r => console.log('default path result:', r));
  "
  ```
  Expected: `⚠️  voice transcode failed, keeping original: spawn /usr/bin/ffmpeg ENOENT` then `default path result: null`.
  On the droplet after deploy: `ls -l /usr/bin/ffmpeg` must exist (it already serves `utils/videoTranscode.js`).

- [ ] **Step 7 — commit:** `docs/REMAINING_WORK.md`:
  - §4 Phase 1 list: `- [x] Item 5: voice notes (moment audio + chat voice) staged to disk and converted to AAC .m4a before storing; original kept on ffmpeg failure (moments#2, chat#13).`
  - §3 Production QA, add: `- [ ] After the Phase 1 deploy: record a voice note on web Chrome (moment + chat), confirm the stored URL ends .m4a and it plays in the iOS app; confirm an app 2.6.1 voice note still uploads unchanged; check pm2 logs for "voice transcode failed".`
  - §4, add open items:
    `- [ ] Already-stored WebM voice notes are not migrated (spec non-goal); revisit only if iOS users report silent old notes. S`
    `- [ ] Voice type is decided from the declared MIME type: WebM bytes declared audio/mp4 pass through unconverted. Sniffing (ffprobe) would close it if it shows up in logs. S`
    `- [ ] Transcodes run in the request on a 960 MB droplet: watch CPU/latency of /messages/voice after deploy; move to a queue if p95 > 3 s. S`
  ```bash
  git add middleware/uploadVoiceNote.js middleware/uploadToSpaces.js routes/moments.js routes/messages.js \
    test/uploadVoiceNote.test.js test/voiceRoutesWiring.test.js docs/REMAINING_WORK.md
  git commit -F - <<'EOF'
  fix(voice): store web voice notes as AAC so they play on iOS

  PUT /moments/:id/audio and POST /messages/voice now stage the upload on
  disk instead of streaming it to Spaces. A note whose declared type is
  not AAC/MP3 (web WebM/Opus, WAV, OGG, video/webm) is converted to AAC
  .m4a with the system ffmpeg before the response; only the AAC is
  uploaded and stored. If ffmpeg fails the original is stored as before
  and the failure is logged. req.file keeps the multer-s3 shape, so the
  controllers and the conversation-cap cleanup are unchanged. Chat voice
  uploads are now capped at 25 MB, the limit /messages/video-config
  already advertised.

  Still open: device check of web voice notes on iOS after deploy; old
  WebM notes not migrated; type decided from the declared MIME; Phase 1
  items 1-3 and 6-8; Phase 1 deploy.
  EOF
  ```

---

## Risky inputs (item 5) and how the design handles them

| Input | Handling |
|---|---|
| Huge file | Staging cap 25 MB (`VOICE_UPLOAD_MAX_BYTES`) → multer `LIMIT_FILE_SIZE` → 400, partial file removed by multer, nothing uploaded. Moment route still enforces 10 MB on the stored file. Disk use per request ≤ 25 MB + AAC output. |
| ffmpeg missing / crashes / times out (120 s) | `transcodeVoiceToAac` returns `null` (ENOENT/exit≠0/timeout/empty output, temp output deleted) → original uploaded with its declared type and `voice transcode failed` logged. Same as today. |
| `audio/webm;codecs=opus` | busboy (1.6) already strips parameters → `audio/webm`; `normalizeMimeType` strips them again defensively. Transcoded. |
| `video/webm` (or `video/mp4`) sent for a voice note | Not on the pass-through list → transcoded with `-vn -map 0:a:0`; a file with no audio stream fails ffmpeg → original kept (still accepted, as today). |
| Lying type (WebM bytes declared `audio/mp4`) | Passes through unconverted (decision is on the declared type, per spec). Logged as an open item; ffprobe sniffing is the follow-up. |
| `application/octet-stream` / non-media | Refused by the same whitelist as before (`isUploadTypeAllowed`) → 400. |
| Hostile filename (`../../x y.webm`) | `safeFileName` keeps the basename, replaces unsafe characters → key `…/<ts>-x_y.m4a`. ffmpeg never sees the client name (staged file has a random name; `execFile` with an args array). |
| Refused after upload (cap, block, message limit, non-owner moment) | Controllers / `checkConversationStart.discardUpload` delete `req.file.location` exactly as before — that is now the AAC URL, which is the only stored object. |
| Many concurrent web notes | Synchronous ffmpeg per request on a small droplet; voice notes are ≤ 60 s (moment) / ≤ 5 min (chat), encode in ~1–3 s. Open item to watch p95. |

# Phase 1 items 1–2 — profile field visibility + blocks (backend)

Spec: `bt-integration/bananatalk_app/docs/superpowers/specs/2026-10-16-web-app-parity-design.md` §2, Phase 1 items 0–2.
Audits: `community.md` #1, #5, #6; `links.md` #11.
Repo: `/Users/davis/Desktop/Personal/be-integration`, branch for this work cut from `main` **after item 0**
(`fix/moments-stories-audit` merged). All paths below are relative to that repo. Line numbers are the
post-merge ones: `main` has not touched `controllers/users.js`, `lib/privacySettings.js`, `utils/blockingUtils.js`
or `routes/users.js` since the merge base, so they equal `git show fix/moments-stories-audit:<file>`.

## 0. What item 0 (the branch) already covers — verified, NOT re-planned

Read via `git show fix/moments-stories-audit:<file>`:

| Path | Status on the branch | Test on the branch |
|---|---|---|
| `GET /auth/users/:id` (`getUser`, users.js:552-588) | `redactUserForViewer(..., req.user?._id)` + `hasActiveStory` | `userPrivacyRedaction` "single-profile reads" |
| `GET /auth/users/:id/public` (`getUserPublic`, users.js:611-655) | per-toggle redaction, but **viewer id passed as `null` for every non-owner** (signed-in or not) | `userPrivacyRedaction`, `privacyFollowups` (expects coarse coords for anonymous), `updateUsername`, `publicIntents` |
| `GET /auth/users/username/:u`, `/search/username`, `getUsers`, `getFollowers`/`getFollowing` | redacted | `userPrivacyRedaction` |
| `GET /matching/recommendations` (matching.js:132, `redactRecommendation` + line 320), `/daily`, `/quick`, `/language`, `/similar` | redacted, cached rows re-read toggles | `privacyFollowups` "matching: every surface redacts" |
| `GET /community/topics/:topicId/users` (community.js:518-590) | redacted, blocked excluded | `userPrivacyRedaction` "community nearby and topic lists" |
| Nearby, chat list, visitors, gathering hosts | redacted | `privacyFollowups` |
| Lists exclude blocked users (`getBlockedUserIds`) | yes on getUsers, search, followers/following, topic, nearby, matching | — |

**Still open after item 0 (this plan):**

1. Signed-out viewers of `/:id/public` still get `location.coordinates` (coarsened to 0.1°, not removed),
   `birth_month`/`birth_day`, and the full `followers`/`following` id arrays (links#11).
2. `/:id/public` has no `hasActiveStory` (community#6).
3. No profile read (`getUser`, `getUserPublic`, `getUserByUsername`) checks blocks: a blocked/blocking
   viewer gets the full profile (community#5).
4. `followUser` ignores blocks (community#5).
5. Found on the way: `followUser`/`unfollowUser` never check that `:userId` is the caller — any signed-in
   user can make anyone follow/unfollow anyone (and fire a "new follower" push in their name).

Design decisions (all inside the spec's "extend `redactUserForViewer`, no second helper"):

- **Anonymous = `viewerId == null`** inside `redactUserForViewer`. Fails closed: any caller that forgets a
  viewer gets the strictest shape. Every other caller already passes `req.user?._id` behind `protect`
  (checked: community.js:202,570, gatherings.js:26, matching.js:67,77,320,676,721,771, messages.js:457,
  users.js:521,578,681,721,1256,1293). The one caller that passes `null` for signed-in viewers is
  `getUserPublic` — fixed in the same commit (Task 1), otherwise signed-in web viewers would lose
  `followers` and the web's `isFollowing` (`useProfileData.ts:107-110`) would break.
- Anonymous shape: `location.coordinates` absent (city/country names stay per toggles), `birth_month`,
  `birth_day`, `birthDate`, `birthday` absent (`birth_year` stays iff `showAge !== false`), `followers` /
  `following` absent with additive `followersCount` / `followingCount`. Field names unchanged.
  Known cosmetic effect: the live web's `countOf(user.followers)` shows 0 to signed-out visitors until the
  Phase 3 web reads `followersCount` — recorded as an open web item.
- Blocked viewers (either direction, signed in, not the owner) get a **minimal card**:
  `{ _id, name, username, images: [first], imageUrls: [first], isBlocked: true }` with status 200 —
  same `{ success, data }` envelope, so app 2.6.1 (`Community.fromJson` tolerates missing fields) and the
  live web render a header instead of erroring. `isBlocked` is additive.
- `followUser` → `403 'Cannot follow this user'` when either side blocked (same wording/shape as
  `sendWave`'s block refusal, community.js:275). App 2.6.1 already maps 403 to "You cannot follow this user"
  (`community_provider.dart:211`).

### Input classes likely to bite (apply to every task)

- **User with no `privacySettings` sub-document** (raw insert / pre-schema accounts): `ps` falls back to
  `{}` = everything visible; the anonymous rules must still apply. Task 1 tests a raw `insertOne` user.
- **Populated vs unpopulated refs:** never `String(ref)` a possibly-populated ref (`'[object Object]'`
  matches nobody, silently). `followers` may hold ObjectIds or populated docs; `req.user.following` is
  ObjectIds from `optionalAuth`/`protect` but `{ _id }`-shaped in some tests. Compare through
  `idOf(ref) = ref && ref._id ? ref._id : ref` then `String(...)` (Task 2 adds it to users.js).
- **`req.user` shapes:** a mongoose doc (real middleware), `{ _id }` only (publicIntents/updateUsername
  tests), `{ _id: '<string>' }`, or absent (publicIntents calls `getUserByUsername` with no user). Block
  checks read the DB, never `req.user.blockedUsers`.
- **Block entries:** schema shape `{ userId, blockedAt }`, but legacy rows may be bare ObjectIds;
  `checkBlockStatus` handles both via `(b.userId || b)` — Task 3 tests the legacy shape.
- **Block cache:** `checkBlockStatus` caches a pair for 30 s; tests use fresh users per test and call
  `invalidateBlockedCache` after an unblock, exactly like `controllers/userBlocks.js:59-60`.
- **Rows that already carry `followersCount`** (`getUsers` builds it): keep the existing number.

Test runner for every task: `node --experimental-test-module-mocks --test --test-force-exit test/<file>.test.js`.
Commits: no `Co-Authored-By` or any AI attribution; each commit updates `docs/REMAINING_WORK.md`.

---

### Task P1-PRIV-1: Signed-out viewers get no coordinates, birth day/month or follower lists

**Files:**
- Modify `lib/privacySettings.js`: constants after line 109 (`const COORDINATE_DECIMALS = 1;`); docstring
  lines 140-156; function body — insert before line 192 (`if (has('privacySettings')) {`).
- Modify `controllers/users.js` lines 643-647 (`getUserPublic`: the redaction call and its comment) and the
  header comment lines 590-610.
- Modify `test/privacyFollowups.test.js` lines 114-115 (anonymous `getUserPublic` no longer has coordinates).
- Modify `docs/REMAINING_WORK.md` (new block, see step 7).
- Test: Create `test/profileViewerParity.test.js`.

**Interfaces:**
- Consumes: `processUserImages(user, req)` (utils/imageUtils.js:53), `User` model.
- Produces: `redactUserForViewer(user: object, viewerId: ObjectId|string|null|undefined): object` — same
  signature; new rule: `viewerId == null` ⇒ anonymous shape. `getUserPublic` now calls
  `redactUserForViewer(userWithImages, req.user ? req.user._id : null)`.

- [ ] **Step 1: Write the failing test** — create `test/profileViewerParity.test.js`:

```js
'use strict';
/**
 * Web <-> app parity, Phase 1 items 1-2 (spec 2026-10-16-web-app-parity-design):
 * the profile reads every client uses give the same fields for the same
 * viewer, signed-out viewers of the shareable /:id/public get no precise
 * data (links#11), /:id/public carries the story ring (community#6), and a
 * block in either direction leaves a minimal card and refuses follows
 * (community#5).
 *
 * Run: node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const { redactUserForViewer } = require('../lib/privacySettings');

let mongod, User, users;

const run = (fn, req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    cookie() { return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  req.app = req.app || { get: () => null };
  fn(req, res, (err) => (err
    ? resolve({ status: err.statusCode || 500, error: err.message, isError: true })
    : resolve({ status: 204 })))
    .catch(reject);
});

const realLog = console.log;
const realError = console.error;

test.before(async () => {
  console.log = () => {};
  console.error = () => {};
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'profileViewerParity' });
  User = require('../models/User');
  await User.init().catch(() => {});
  users = require('../controllers/users');
});
test.after(async () => {
  await mongoose.disconnect();
  await mongod.stop();
  console.log = realLog;
  console.error = realError;
});

const SEOUL = [126.978, 37.5665];
const EXACT = [SEOUL[0] + 0.0123, SEOUL[1] + 0.0456];

const makeUser = (name, extra = {}) => User.create({
  name,
  username: `${name.toLowerCase()}${Math.floor(Math.random() * 1e6)}`,
  email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '1990', birth_month: '5', birth_day: '17', gender: 'other',
  native_language: 'English', language_to_learn: 'Korean',
  profileCompleted: true,
  images: ['a.jpg', 'b.jpg'],
  isOnline: true, lastActive: new Date(), lastSeenAt: new Date(),
  location: { type: 'Point', coordinates: EXACT, city: 'Seoul', country: 'South Korea' },
  ...extra,
});

// A signed-in viewer as protect/optionalAuth leave it on req.user (a doc).
const reqAs = (viewer, extra = {}) => ({
  user: viewer || null,
  params: {}, query: {}, body: {},
  protocol: 'https', get: () => 'api.test',
  ...extra,
});

// ---------------------------------------------------------------------------
// P1-PRIV-1: signed-out viewers (links#11)
// ---------------------------------------------------------------------------

test('redactUserForViewer, signed out: no coordinates, no birth day/month, lists become counts', () => {
  const id = new mongoose.Types.ObjectId();
  const plainFollower = new mongoose.Types.ObjectId();
  const populatedFollower = { _id: new mongoose.Types.ObjectId(), name: 'Populated' };
  const u = redactUserForViewer({
    _id: id,
    birth_year: '1990', birth_month: '5', birth_day: '17',
    location: { type: 'Point', coordinates: EXACT, city: 'Seoul', country: 'South Korea' },
    followers: [plainFollower, populatedFollower],
    following: [plainFollower],
    privacySettings: {},
  }, null);
  assert.equal(u.birth_year, '1990', 'age stays (showAge not off)');
  assert.equal(u.birth_month, undefined);
  assert.equal(u.birth_day, undefined);
  assert.equal(u.location.coordinates, undefined, 'no coordinates at all');
  assert.equal(u.location.city, 'Seoul', 'city name stays');
  assert.equal(u.location.country, 'South Korea');
  assert.equal(u.followers, undefined);
  assert.equal(u.following, undefined);
  assert.equal(u.followersCount, 2);
  assert.equal(u.followingCount, 1);
  assert.equal(redactUserForViewer({ _id: id, followers: [] }, undefined).followersCount, 0,
    'undefined is signed out too');
});

test('redactUserForViewer, signed out: an existing followersCount is kept, showAge off drops the year', () => {
  const id = new mongoose.Types.ObjectId();
  const u = redactUserForViewer({
    _id: id, birth_year: '1990', followersCount: 7, followers: [], privacySettings: { showAge: false },
  }, null);
  assert.equal(u.followersCount, 7);
  assert.equal(u.birth_year, undefined);
});

test('redactUserForViewer, signed in non-owner: birth date, coarse coordinates and lists stay', () => {
  const id = new mongoose.Types.ObjectId();
  const viewer = new mongoose.Types.ObjectId();
  const u = redactUserForViewer({
    _id: id, birth_year: '1990', birth_month: '5', birth_day: '17',
    location: { type: 'Point', coordinates: EXACT, city: 'Seoul' },
    followers: [viewer], following: [],
    privacySettings: {},
  }, viewer);
  assert.equal(u.birth_month, '5', 'the app derives the zodiac from it');
  assert.equal(u.birth_day, '17');
  assert.deepEqual(u.location.coordinates, [127, 37.6]);
  assert.deepEqual(u.followers, [viewer]);
  assert.equal(u.followersCount, undefined, 'nothing added for signed-in viewers');
});

test('getUserPublic: signed out vs signed in vs owner', async () => {
  const viewer = await makeUser('PubViewer');
  const target = await makeUser('PubTarget', { followers: [viewer._id] });
  await User.updateOne({ _id: viewer._id }, { $set: { following: [target._id] } });
  const viewerDoc = await User.findById(viewer._id);

  let r = await run(users.getUserPublic, reqAs(null, { params: { id: String(target._id) } }));
  assert.equal(r.status, 200, JSON.stringify(r));
  let d = r.body.data;
  assert.equal(d.location.coordinates, undefined, 'signed out: no coordinates');
  assert.equal(d.location.city, 'Seoul');
  assert.equal(d.birth_month, undefined);
  assert.equal(d.birth_day, undefined);
  assert.equal(d.birth_year, '1990');
  assert.equal(d.followers, undefined);
  assert.equal(d.following, undefined);
  assert.equal(d.followersCount, 1);
  assert.equal(d.followingCount, 0);

  r = await run(users.getUserPublic, reqAs(viewerDoc, { params: { id: String(target._id) } }));
  d = r.body.data;
  assert.deepEqual(d.location.coordinates, [127, 37.6], 'signed in: coarse coordinates');
  assert.equal(d.birth_month, '5');
  assert.deepEqual(d.followers.map(String), [String(viewer._id)], 'web isFollowing still works');

  const targetDoc = await User.findById(target._id);
  r = await run(users.getUserPublic, reqAs(targetDoc, { params: { id: String(target._id) } }));
  assert.deepEqual(r.body.data.location.coordinates, EXACT, 'owner: exact');
  assert.equal(r.body.data.birth_day, '17');
});

test('getUserPublic, signed out: a user with no privacySettings sub-document is still cut down', async () => {
  const _id = new mongoose.Types.ObjectId();
  await User.collection.insertOne({
    _id, name: 'Legacy', username: `legacy${Math.floor(Math.random() * 1e6)}`,
    email: `legacy-${_id}@example.com`, password: 'x',
    birth_year: '1985', birth_month: '2', birth_day: '3',
    location: { type: 'Point', coordinates: EXACT, city: 'Seoul' },
    followers: [new mongoose.Types.ObjectId()], following: [],
    images: [],
  });
  const r = await run(users.getUserPublic, reqAs(null, { params: { id: String(_id) } }));
  assert.equal(r.status, 200, JSON.stringify(r));
  const d = r.body.data;
  assert.equal(d.location.coordinates, undefined);
  assert.equal(d.birth_month, undefined);
  assert.equal(d.followers, undefined);
  assert.equal(d.followersCount, 1);
  assert.equal(d.birth_year, '1985', 'missing toggles = visible');
});
```

- [ ] **Step 2: Run it** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`
  Expected: FAIL in the signed-out tests — `birth_month` is `'5'` (not undefined), `location.coordinates`
  is `[127, 37.6]`, `followers` is an array, `followersCount` undefined. The signed-in unit test passes.

- [ ] **Step 3: Implement — `lib/privacySettings.js`.** After line 109 (`const COORDINATE_DECIMALS = 1;`) add:

```js

// Signed-out viewers (the web's shared /profile/:id links, crawlers, anyone
// with the URL): an age at most. Birth day and month stay for signed-in
// people -- the app derives the zodiac from them, per showZodiac -- and the
// owner. (links#11)
const ANONYMOUS_HIDDEN_BIRTH_FIELDS = ['birth_month', 'birth_day', 'birthDate', 'birthday'];
// Who follows whom is for signed-in people. A signed-out viewer gets the
// counts under the *Count names the list endpoints already use.
const FOLLOW_LISTS = [['followers', 'followersCount'], ['following', 'followingCount']];
```

  In the docstring, replace the line ` * - showGiftingLevel:  vipSubscription dropped; userMode 'vip' -> 'regular'` (line 155) with:

```js
 * - showGiftingLevel:  vipSubscription dropped; userMode 'vip' -> 'regular'
 * - signed out (viewerId null/undefined), on top of the above:
 *                      location.coordinates dropped; birth_month / birth_day
 *                      (and birthDate/birthday) dropped; followers / following
 *                      dropped, followersCount / followingCount set from them
 *                      unless already a number. Fails closed: a caller that
 *                      forgets the viewer gets this strictest shape.
```

  Insert immediately before line 192 (`  if (has('privacySettings')) {`):

```js
  if (viewerId == null) {
    // `user.location` is already this function's own copy (above), so the
    // caller's object is not mutated through it.
    if (isPlainObject(user.location)) delete user.location.coordinates;
    ANONYMOUS_HIDDEN_BIRTH_FIELDS.forEach((f) => delete user[f]);
    for (const [list, count] of FOLLOW_LISTS) {
      if (!has(list)) continue;
      if (typeof user[count] !== 'number') {
        user[count] = Array.isArray(user[list]) ? user[list].length : 0;
      }
      delete user[list];
    }
  }
```

- [ ] **Step 4: Implement — `controllers/users.js` `getUserPublic`.** Replace lines 643-647:

```js
  // Non-owners: the shared per-toggle redaction (lib/privacySettings.js),
  // which also cuts privacySettings down to the six public keys. An
  // unauthenticated visitor is never the owner.
  redactUserForViewer(userWithImages, isOwner ? req.user._id : null);
```

  with:

```js
  // The shared redaction (lib/privacySettings.js) with the REAL viewer: the
  // owner gets everything, a signed-in viewer the same fields getUser gives
  // them (follower lists included -- the web's isFollowing reads them), and
  // a signed-out visitor (req.user null) the strict anonymous shape: no
  // coordinates, no birth day/month, follower counts instead of lists.
  redactUserForViewer(userWithImages, req.user ? req.user._id : null);
```

  In the header comment (lines 605-606), after the line `//   - privacySettings itself                       → only the six show* keys` add:

```js
//   - signed out (no req.user)                     → no location.coordinates, no birth_month/day,
//                                                     followersCount/followingCount instead of the lists
```

- [ ] **Step 5: Update the existing expectation** — `test/privacyFollowups.test.js` lines 114-115, replace:

```js
  r = await run(users.getUserPublic, reqAs(null, { params: { id: String(open._id) } }));
  check(r.body.data, 'getUserPublic');
```

  with:

```js
  r = await run(users.getUserPublic, reqAs(viewer, { params: { id: String(open._id) } }));
  check(r.body.data, 'getUserPublic (signed in)');
  // Signed out: no coordinates at all (links#11), city name still there.
  r = await run(users.getUserPublic, reqAs(null, { params: { id: String(open._id) } }));
  assert.equal(r.body.data.location.city, 'Seoul', 'getUserPublic (signed out): city kept');
  assert.equal(r.body.data.location.coordinates, undefined, 'getUserPublic (signed out): no coordinates');
  for (const f of ['street', 'zipcode', 'formattedAddress']) {
    assert.equal(r.body.data.location[f], undefined, `getUserPublic (signed out): location.${f}`);
  }
```

- [ ] **Step 6: Run → PASS**
  `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`
  then the neighbours, each must pass:
  `node --experimental-test-module-mocks --test --test-force-exit test/privacyFollowups.test.js`
  `node --experimental-test-module-mocks --test --test-force-exit test/userPrivacyRedaction.test.js`
  `node --experimental-test-module-mocks --test --test-force-exit test/updateUsername.test.js`
  `node --experimental-test-module-mocks --test --test-force-exit test/publicIntents.test.js`
  (Run files individually: `npm test` dies under Node 25, see memory "Backend local tests". The known
  1 failure in the full suite is the local 12-char `JWT_SECRET`, unrelated.)

- [ ] **Step 7: `docs/REMAINING_WORK.md`.** In §4 "Code work — open", directly after the bullet that starts
  `- Web notification settings: the web's \`NotificationSettings.tsx\``, insert:

```markdown

Web ↔ app parity, Phase 1 items 1–2 (bt spec `docs/superpowers/specs/2026-10-16-web-app-parity-design.md`)
- [x] Signed-out `GET /auth/users/:id/public` (web share links, links#11): no `location.coordinates`, no `birth_month`/`birth_day`, `followers`/`following` replaced by `followersCount`/`followingCount`; rule lives in `redactUserForViewer` (`viewerId == null` = signed out, fails closed). Signed-in viewers of `/:id/public` now get the same fields as `getUser` (the handler passed `null` for every non-owner). Test `profileViewerParity`.
- [ ] `/:id/public` carries `hasActiveStory` (community#6). S
- [ ] Blocked viewers (either direction) get a minimal card on `getUser` / `getUserPublic` / `getUserByUsername` (community#5). S
- [ ] `followUser` refuses (403) when either side blocked (community#5). S
- [ ] `followUser` / `unfollowUser` act only for the caller (`:userId` must be `req.user`). S
- [ ] Web repo: profile stats read `followersCount`/`followingCount` when `followers` is absent (signed-out visitors see 0 until then). S
- [ ] Decide: signed-out `/:id/public` still returns `isOnline`/`lastActive`/`lastSeenAt` when `showOnlineStatus` is on (links#11 lists `lastSeenAt`; the spec leaves it). S
```

- [ ] **Step 8: Commit**

```bash
cd /Users/davis/Desktop/Personal/be-integration
git add lib/privacySettings.js controllers/users.js test/profileViewerParity.test.js test/privacyFollowups.test.js docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(privacy): signed-out profile reads get no coordinates, birth date or follower lists

redactUserForViewer treats a missing viewer as signed out: location.coordinates,
birth_month/birth_day and the followers/following arrays are dropped, with
followersCount/followingCount in their place. getUserPublic now passes the real
viewer, so signed-in web viewers keep the lists (isFollowing) and only the
anonymous share-link read is cut down (links#11).

Still open (docs/REMAINING_WORK.md, web parity Phase 1):
- /:id/public hasActiveStory (community#6)
- minimal card for blocked viewers; followUser 403 on blocks (community#5)
- follow/unfollow only on the caller's own behalf
- web: read followersCount for signed-out visitors
- decide: signed-out online/last-seen fields
EOF
```

---

### Task P1-PRIV-2: `/:id/public` carries `hasActiveStory`

**Files:**
- Modify `controllers/users.js`: add `idOf` after line 26 (end of the `lib/privacySettings` require);
  in `getUserPublic` insert after line 650 (`userWithImages.intents = publicIntents(user.intents);`).
- Modify `docs/REMAINING_WORK.md` (tick).
- Test: Modify `test/profileViewerParity.test.js` (append).

**Interfaces:**
- Consumes: `usersWithVisibleActiveStory(userIds: ObjectId[], viewerId: ObjectId|null, followingIds: (ObjectId|string)[]): Promise<Set<string>>` (lib/activeStoryFlags.js, already imported at users.js:19).
- Produces: `idOf(ref: any): any` (module-local in controllers/users.js); `getUserPublic` response `data.hasActiveStory: boolean` (additive; absent on the wholly-private minimal branch, as before).

- [ ] **Step 1: Write the failing test** — append to `test/profileViewerParity.test.js`:

```js
// ---------------------------------------------------------------------------
// P1-PRIV-2: the story ring on /:id/public (community#6)
// ---------------------------------------------------------------------------

test('getUserPublic: hasActiveStory follows the same visibility as getUser', async () => {
  const Story = require('../models/Story');
  const owner = await makeUser('RingOwner');
  const follower = await makeUser('RingFollower', { following: [owner._id] });
  const stranger = await makeUser('RingStranger');
  const ring = async (viewer) => {
    const r = await run(users.getUserPublic, reqAs(viewer, { params: { id: String(owner._id) } }));
    assert.equal(r.status, 200, JSON.stringify(r));
    return r.body.data.hasActiveStory;
  };

  assert.equal(await ring(null), false, 'no story: false, and present');

  const friendsOnly = await Story.create({ user: owner._id, mediaType: 'text', text: 'f', privacy: 'friends' });
  assert.equal(await ring(null), false, 'friends-only: not for signed out');
  assert.equal(await ring(await User.findById(stranger._id)), false, 'friends-only: not for a stranger');
  assert.equal(await ring(await User.findById(follower._id)), true, 'friends-only: a follower sees it');
  // req.user shaped { _id, following: [populated] } -- the ref must not be String()ed whole.
  assert.equal(await ring({ _id: follower._id, following: [{ _id: owner._id, name: 'RingOwner' }] }), true,
    'populated following entries still match');

  await Story.deleteOne({ _id: friendsOnly._id });
  await Story.create({ user: owner._id, mediaType: 'text', text: 'c', privacy: 'close_friends' });
  assert.equal(await ring(await User.findById(follower._id)), false, 'close_friends never lights the ring');

  await Story.create({ user: owner._id, mediaType: 'text', text: 'p', privacy: 'public' });
  assert.equal(await ring(null), true, 'public: signed out sees the ring');

  await Story.updateMany({ user: owner._id }, { $set: { expiresAt: new Date(Date.now() - 1000) } });
  assert.equal(await ring(null), false, 'expired stories do not count');
});
```

- [ ] **Step 2: Run it** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`
  Expected: FAIL on the first assertion — `hasActiveStory` is `undefined`, not `false`.

- [ ] **Step 3: Implement.** In `controllers/users.js`, after line 26 (`} = require('../lib/privacySettings');`) add:

```js

// A ref that may or may not be populated -> its id. Compare with
// String(idOf(a)) === String(idOf(b)); String() of a populated doc is
// '[object Object]' and silently matches nobody.
const idOf = (ref) => (ref && ref._id ? ref._id : ref);
```

  In `getUserPublic`, after line 650 (`  userWithImages.intents = publicIntents(user.intents);`) insert:

```js

  // The story ring (community#6): getUser and the lists stamp it, and the
  // web's profile reads this path. Same visibility as getUser: public
  // always, friends only when the viewer follows the owner, close_friends
  // never; a signed-out visitor sees public stories only.
  const activeStoryOwners = await usersWithVisibleActiveStory(
    [user._id],
    req.user ? req.user._id : null,
    ((req.user && req.user.following) || []).map(idOf)
  );
  userWithImages.hasActiveStory = activeStoryOwners.has(String(user._id));
```

- [ ] **Step 4: Run → PASS** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`,
  then `test/publicIntents.test.js` and `test/updateUsername.test.js` (their `req.user` has no `following`).

- [ ] **Step 5: `docs/REMAINING_WORK.md`** — in the "Web ↔ app parity, Phase 1 items 1–2" block replace
  `- [ ] \`/:id/public\` carries \`hasActiveStory\` (community#6). S` with:

```markdown
- [x] `/:id/public` carries `hasActiveStory` (community#6), same visibility as `getUser` (public; friends for followers; never close_friends; signed out = public only). Test `profileViewerParity`.
```

- [ ] **Step 6: Commit**

```bash
cd /Users/davis/Desktop/Personal/be-integration
git add controllers/users.js test/profileViewerParity.test.js docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(users): story ring on the public profile read

GET /auth/users/:id/public now returns hasActiveStory with the same
visibility rules as getUser, so the web profile shows the ring the app
shows (community#6). Additive field.

Still open (docs/REMAINING_WORK.md, web parity Phase 1):
- minimal card for blocked viewers; followUser 403 on blocks (community#5)
- follow/unfollow only on the caller's own behalf
- web: read followersCount for signed-out visitors
- decide: signed-out online/last-seen fields
EOF
```

---

### Task P1-PRIV-3: Blocked viewers get a minimal card on every single-profile read

**Files:**
- Modify `controllers/users.js`: line 17 (blockingUtils import); add two helpers right after the `idOf`
  line from Task 2; `getUser` insert after line 559 (closing `}` of the 404 check); `getUserPublic` insert
  after line 618 (`const isOwner = ...`); `getUserByUsername` insert after line 675 (closing `}` of its 404).
  (Line numbers before Task 2's insertions; after Task 2 they shift by +5 above `getUserPublic`'s
  insertion point and +16 below it — anchor on the quoted code, not the number.)
- Modify `docs/REMAINING_WORK.md` (tick).
- Test: Modify `test/profileViewerParity.test.js` (append).

**Interfaces:**
- Consumes: `checkBlockStatus(userId1: string, userId2: string): Promise<{ isBlocked: boolean, blockedBy, iBlockedThem, theyBlockedMe }>` and `invalidateBlockedCache(userId, otherUserId)` (utils/blockingUtils.js); `processUserImages`; `idOf` (Task 2).
- Produces (module-local in controllers/users.js):
  - `viewerBlockRelation(viewer: object|null|undefined, targetId: ObjectId|string): Promise<boolean>`
  - `blockedProfileCard(user: object, req: object): { _id, name, username, images: string[], imageUrls: string[], isBlocked: true }`

- [ ] **Step 1: Write the failing test** — append to `test/profileViewerParity.test.js`:

```js
// ---------------------------------------------------------------------------
// P1-PRIV-3: blocked viewers get a minimal card (community#5)
// ---------------------------------------------------------------------------

const { invalidateBlockedCache } = require('../utils/blockingUtils');

const block = async (blocker, blocked) => {
  await User.updateOne({ _id: blocker._id }, { $push: { blockedUsers: { userId: blocked._id, blockedAt: new Date() } } });
  await User.updateOne({ _id: blocked._id }, { $push: { blockedBy: { userId: blocker._id, blockedAt: new Date() } } });
  invalidateBlockedCache(String(blocker._id), String(blocked._id));
  invalidateBlockedCache(String(blocked._id), String(blocker._id));
};

const MINIMAL_KEYS = ['_id', 'imageUrls', 'images', 'isBlocked', 'name', 'username'];

const assertMinimal = (d, label) => {
  assert.deepEqual(Object.keys(d).sort(), MINIMAL_KEYS, `${label}: only the minimal card`);
  assert.equal(d.isBlocked, true, `${label}: isBlocked`);
  assert.deepEqual(d.images, ['a.jpg'], `${label}: first image only`);
  assert.equal(d.imageUrls.length, 1, `${label}: one image URL`);
};

test('a block in either direction leaves a minimal card on getUser, getUserPublic and getUserByUsername', async () => {
  const blocker = await makeUser('Blocker');
  const blocked = await makeUser('Blocked');
  const bystander = await makeUser('Bystander');
  await block(blocker, blocked);

  const reads = (viewer, target) => [
    ['getUser', users.getUser, { params: { id: String(target._id) } }],
    ['getUserPublic', users.getUserPublic, { params: { id: String(target._id) } }],
    ['getUserByUsername', users.getUserByUsername, { params: { username: target.username } }],
  ].map(([label, fn, extra]) => [label, fn, reqAs(viewer, extra)]);

  const blockerDoc = await User.findById(blocker._id);
  const blockedDoc = await User.findById(blocked._id);
  for (const [label, fn, req] of reads(blockerDoc, blocked)) {
    const r = await run(fn, req);
    assert.equal(r.status, 200, `${label}: ${JSON.stringify(r)}`);
    assertMinimal(r.body.data, `blocker reads blocked, ${label}`);
  }
  for (const [label, fn, req] of reads(blockedDoc, blocker)) {
    const r = await run(fn, req);
    assertMinimal(r.body.data, `blocked reads blocker, ${label}`);
  }
  // req.user as a bare { _id } with a STRING id: the check reads the DB, not req.user.
  let r = await run(users.getUser, reqAs({ _id: String(blocked._id) }, { params: { id: String(blocker._id) } }));
  assertMinimal(r.body.data, 'string-id viewer');

  // Uninvolved viewers, the owner and signed-out visitors are unaffected.
  r = await run(users.getUser, reqAs(await User.findById(bystander._id), { params: { id: String(blocked._id) } }));
  assert.equal(r.body.data.isBlocked, undefined, 'bystander: full profile');
  assert.equal(r.body.data.location.city, 'Seoul');
  r = await run(users.getUser, reqAs(blockedDoc, { params: { id: String(blocked._id) } }));
  assert.equal(r.body.data.isBlocked, undefined, 'owner: full profile');
  r = await run(users.getUserPublic, reqAs(null, { params: { id: String(blocked._id) } }));
  assert.equal(r.body.data.isBlocked, undefined, 'signed out: the anonymous profile, not the card');
  assert.equal(r.body.data.location.city, 'Seoul');
});

test('unblocking restores the full profile', async () => {
  const a = await makeUser('UnblockA');
  const b = await makeUser('UnblockB');
  await block(a, b);
  let r = await run(users.getUser, reqAs(await User.findById(a._id), { params: { id: String(b._id) } }));
  assert.equal(r.body.data.isBlocked, true);

  await User.updateOne({ _id: a._id }, { $set: { blockedUsers: [] } });
  await User.updateOne({ _id: b._id }, { $set: { blockedBy: [] } });
  invalidateBlockedCache(String(a._id), String(b._id));
  invalidateBlockedCache(String(b._id), String(a._id));

  r = await run(users.getUser, reqAs(await User.findById(a._id), { params: { id: String(b._id) } }));
  assert.equal(r.body.data.isBlocked, undefined);
  assert.equal(r.body.data.birth_year, '1990');
});

test('a legacy bare-id block entry counts as a block', async () => {
  const a = await makeUser('LegacyA');
  const b = await makeUser('LegacyB');
  // Pre-schema shape: the ObjectId itself, no { userId } wrapper (raw write, no casting).
  await User.collection.updateOne({ _id: a._id }, { $push: { blockedUsers: b._id } });
  invalidateBlockedCache(String(a._id), String(b._id));
  const r = await run(users.getUserPublic, reqAs(await User.findById(b._id), { params: { id: String(a._id) } }));
  assertMinimal(r.body.data, 'legacy block entry');
});
```

- [ ] **Step 2: Run it** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`
  Expected: FAIL — the blocked reads return the full profile (keys include `bio`, `location`, …;
  `isBlocked` undefined).

  Note for the legacy test: only `b` (the viewer) is hydrated as a doc; `a`'s bare-id entry is read by
  `checkBlockStatus` with `.lean()` and `getUserPublic` does not select `blockedUsers`, so nothing casts
  the legacy entry. Keep any future read of `blockedUsers` lean for the same reason.

- [ ] **Step 3: Implement.** `controllers/users.js` line 17, replace:

```js
const { getBlockedUserIds } = require('../utils/blockingUtils');
```

  with:

```js
const { getBlockedUserIds, checkBlockStatus } = require('../utils/blockingUtils');
```

  Directly after the `const idOf = ...` line added in Task 2, add:

```js

/**
 * Whether a signed-in viewer and `targetId` are in a block relationship,
 * either direction (community#5). Signed-out viewers and the owner never
 * are. Reads the DB (checkBlockStatus, 30 s pair cache, invalidated by
 * block/unblock) -- never req.user.blockedUsers, which callers and tests
 * shape differently ({ _id } only, string ids).
 */
async function viewerBlockRelation(viewer, targetId) {
  const viewerId = idOf(viewer);
  const target = idOf(targetId);
  if (viewerId == null || target == null) return false;
  if (String(viewerId) === String(target)) return false;
  const status = await checkBlockStatus(String(viewerId), String(target));
  return !!(status && status.isBlocked);
}

/**
 * What a viewer in a block relationship gets instead of a profile: enough
 * for the existing headers to render a name and an avatar, plus the
 * additive `isBlocked: true`. Field names are the profile's own; every
 * other field is absent. Same { success, data } envelope and status 200,
 * so app 2.6.1 and the live web render a card instead of an error screen.
 */
function blockedProfileCard(user, req) {
  const images = Array.isArray(user.images) && user.images.length ? [user.images[0]] : [];
  return {
    ...processUserImages({ _id: user._id, name: user.name, username: user.username, images }, req),
    isBlocked: true,
  };
}
```

  `getUser` — after the 404 block

```js
  if (!user) {
    return next(new ErrorResponse(`User not found with id of ${req.params.id}`, 404));
  }
```

  (the first one in `exports.getUser`) insert:

```js

  if (await viewerBlockRelation(req.user, user._id)) {
    return res.status(200).json({ success: true, data: blockedProfileCard(user, req) });
  }
```

  `getUserPublic` — after `  const isOwner = !!(req.user && req.user._id.toString() === req.params.id);` insert:

```js

  // A signed-in viewer in a block relationship, either direction: the
  // minimal card, before any other branch (community#5).
  if (await viewerBlockRelation(req.user, user._id)) {
    return res.status(200).json({ success: true, data: blockedProfileCard(user, req) });
  }
```

  `getUserByUsername` — after

```js
  if (!user) {
    return next(new ErrorResponse(`User not found with username @${normalizedUsername}`, 404));
  }
```

  insert:

```js

  if (await viewerBlockRelation(req.user, user._id)) {
    return res.status(200).json({ success: true, data: blockedProfileCard(user, req) });
  }
```

- [ ] **Step 4: Run → PASS** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`,
  then `test/publicIntents.test.js` (calls `getUserByUsername` with no `req.user`), `test/updateUsername.test.js`,
  `test/userPrivacyRedaction.test.js`, `test/privacyFollowups.test.js`.

- [ ] **Step 5: `docs/REMAINING_WORK.md`** — replace
  `- [ ] Blocked viewers (either direction) get a minimal card on \`getUser\` / \`getUserPublic\` / \`getUserByUsername\` (community#5). S` with:

```markdown
- [x] Blocked viewers (either direction) get a minimal card on `getUser` / `getUserPublic` / `getUserByUsername`: `{ _id, name, username, images: [first], imageUrls, isBlocked: true }`, status 200 (community#5). Reads the DB via `checkBlockStatus`, legacy bare-id block entries included. Test `profileViewerParity`.
- [ ] Clients: app/web could render a "blocked" state from `isBlocked` (today they render the card as a sparse profile). S
```

- [ ] **Step 6: Commit**

```bash
cd /Users/davis/Desktop/Personal/be-integration
git add controllers/users.js test/profileViewerParity.test.js docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(users): blocked viewers get a minimal profile card

getUser, getUserPublic and getUserByUsername return only _id, name,
username, the first image and isBlocked: true when the signed-in viewer
and the profile are in a block relationship in either direction
(community#5). Same envelope and status, so live clients still render.

Still open (docs/REMAINING_WORK.md, web parity Phase 1):
- followUser 403 on blocks (community#5)
- follow/unfollow only on the caller's own behalf
- web: read followersCount for signed-out visitors
- clients: render a blocked state from isBlocked
- decide: signed-out online/last-seen fields
EOF
```

---

### Task P1-PRIV-4: `followUser` refuses when either side blocked

**Files:**
- Modify `controllers/users.js` `followUser` (branch lines 1139-1189): insert after the
  `'User not found'` 404 block (branch lines 1152-1154), before `if (user.following.includes(targetUserId))`.
- Modify `docs/REMAINING_WORK.md` (tick).
- Test: Modify `test/profileViewerParity.test.js` (append).

**Interfaces:**
- Consumes: `checkBlockStatus` (imported in Task 3).
- Produces: `PUT /auth/users/:userId/follow/:targetUserId` → `403 { success: false, error: 'Cannot follow this user' }` when blocked; nothing written, no notification.

- [ ] **Step 1: Write the failing test** — append to `test/profileViewerParity.test.js`:

```js
// ---------------------------------------------------------------------------
// P1-PRIV-4: follow refuses blocks (community#5)
// ---------------------------------------------------------------------------

const followReq = (actor, target) => reqAs(actor, {
  params: { userId: String(actor._id), targetUserId: String(target._id) },
});

test('followUser: 403 when either side blocked, nothing written, no push', async () => {
  const notificationService = require('../services/notificationService');
  const sent = [];
  notificationService.sendNewFollower = async (to, from) => { sent.push([String(to), String(from)]); };

  const a = await makeUser('FollowA');
  const b = await makeUser('FollowB');
  const c = await makeUser('FollowC');
  await block(a, b);

  let r = await run(users.followUser, followReq(await User.findById(b._id), a));
  assert.equal(r.status, 403, 'the blocked side cannot follow the blocker');
  assert.equal(r.error, 'Cannot follow this user');
  r = await run(users.followUser, followReq(await User.findById(a._id), b));
  assert.equal(r.status, 403, 'the blocker cannot follow the blocked side either');

  const [aAfter, bAfter] = await Promise.all([User.findById(a._id).lean(), User.findById(b._id).lean()]);
  assert.deepEqual(aAfter.following, []);
  assert.deepEqual(aAfter.followers, []);
  assert.deepEqual(bAfter.following, []);
  assert.deepEqual(bAfter.followers, []);
  assert.deepEqual(sent, [], 'no new-follower push');

  r = await run(users.followUser, followReq(await User.findById(c._id), b));
  assert.equal(r.status, 200, `an uninvolved user still follows: ${JSON.stringify(r)}`);
  const bNow = await User.findById(b._id).lean();
  assert.deepEqual(bNow.followers.map(String), [String(c._id)]);
});
```

- [ ] **Step 2: Run it** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`
  Expected: FAIL — first follow returns `200`, not `403`.

- [ ] **Step 3: Implement.** In `exports.followUser`, after

```js
  if (!user || !targetUser) {
    return next(new ErrorResponse('User not found', 404));
  }
```

  insert:

```js

  // Either side blocked the other: no follow (community#5). Same wording
  // and status as sendWave's block refusal; the app maps 403 to "You
  // cannot follow this user". Blocking already removed any follow both ways.
  const blockStatus = await checkBlockStatus(String(user._id), String(targetUser._id));
  if (blockStatus && blockStatus.isBlocked) {
    return next(new ErrorResponse('Cannot follow this user', 403));
  }
```

- [ ] **Step 4: Run → PASS** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`.
  Also grep for other follow tests and run them: `ls test | grep -i follow` (run each that exists).

- [ ] **Step 5: `docs/REMAINING_WORK.md`** — replace
  `- [ ] \`followUser\` refuses (403) when either side blocked (community#5). S` with:

```markdown
- [x] `followUser` refuses (403 "Cannot follow this user") when either side blocked; nothing written, no push (community#5). Test `profileViewerParity`.
```

- [ ] **Step 6: Commit**

```bash
cd /Users/davis/Desktop/Personal/be-integration
git add controllers/users.js test/profileViewerParity.test.js docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(users): follow refuses when either side blocked

followUser checked only self-follow, existence and already-following, so a
blocked user could follow the person who blocked them (and send them a
new-follower push). Now 403, nothing written (community#5).

Still open (docs/REMAINING_WORK.md, web parity Phase 1):
- follow/unfollow only on the caller's own behalf
- web: read followersCount for signed-out visitors
- clients: render a blocked state from isBlocked
- decide: signed-out online/last-seen fields
EOF
```

---

### Task P1-PRIV-5: follow / unfollow only on the caller's own behalf (found on the way)

Not in the spec text but in the same handler and a real hole: `PUT /:userId/follow/:targetUserId` trusts
`:userId`. Both clients send the viewer's own id (app `single_community_screen.dart:210` passes the
signed-in `userId`; web `useFollowToggle.ts:60` passes `viewerId`). Step 0 confirms the remaining callers
before the change. Drop this task if the owner prefers to keep Phase 1 to the spec.

**Files:**
- Modify `controllers/users.js` `followUser` and `unfollowUser`: insert as the first statement after
  `const { userId, targetUserId } = req.params;` in each (branch lines 1140 and 1195).
- Modify `docs/REMAINING_WORK.md` (tick).
- Test: Modify `test/profileViewerParity.test.js` (append).

**Interfaces:**
- Consumes: `idOf` (Task 2).
- Produces: both routes → `403 { error: 'Not authorized to change another user\'s follows' }` when
  `String(idOf(req.user)) !== String(userId)`.

- [ ] **Step 0: Verify callers** — in `/Users/davis/Desktop/Personal/language_exchange_web_front`:
  `grep -rn "<FollowButton" src | grep -v test` and check each passes the signed-in user's id as `userId`;
  in `bt-integration/bananatalk_app`: `grep -rn "followUser(\|unfollowUser(" lib` and check `moment_card.dart:325-330`
  and `followers.dart:84,152` pass the current user id. If any passes another id, stop and report.

- [ ] **Step 1: Write the failing test** — append to `test/profileViewerParity.test.js`:

```js
// ---------------------------------------------------------------------------
// P1-PRIV-5: follow/unfollow act only for the caller
// ---------------------------------------------------------------------------

test('follow and unfollow refuse a :userId that is not the caller', async () => {
  require('../services/notificationService').sendNewFollower = async () => {};
  const victim = await makeUser('Victim');
  const target = await makeUser('Target');
  const attacker = await makeUser('Attacker');
  const attackerDoc = await User.findById(attacker._id);

  let r = await run(users.followUser, reqAs(attackerDoc, {
    params: { userId: String(victim._id), targetUserId: String(target._id) },
  }));
  assert.equal(r.status, 403);
  assert.deepEqual((await User.findById(victim._id).lean()).following, []);

  // Own behalf, with req.user as a bare { _id } string: allowed.
  r = await run(users.followUser, reqAs({ _id: String(victim._id) }, {
    params: { userId: String(victim._id), targetUserId: String(target._id) },
  }));
  assert.equal(r.status, 200, JSON.stringify(r));

  r = await run(users.unfollowUser, reqAs(attackerDoc, {
    params: { userId: String(victim._id), targetUserId: String(target._id) },
  }));
  assert.equal(r.status, 403);
  assert.deepEqual((await User.findById(victim._id).lean()).following.map(String), [String(target._id)]);

  r = await run(users.unfollowUser, reqAs(await User.findById(victim._id), {
    params: { userId: String(victim._id), targetUserId: String(target._id) },
  }));
  assert.equal(r.status, 200, JSON.stringify(r));
});
```

- [ ] **Step 2: Run it** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`
  Expected: FAIL — the attacker's follow returns `200`.

- [ ] **Step 3: Implement.** In `exports.followUser` and in `exports.unfollowUser`, directly after
  `  const { userId, targetUserId } = req.params;` insert:

```js

  // Only for yourself: :userId used to be trusted, so anyone signed in
  // could make anyone follow / unfollow anyone (and fire a new-follower
  // push in their name). Both clients send the caller's own id.
  if (String(idOf(req.user)) !== String(userId)) {
    return next(new ErrorResponse("Not authorized to change another user's follows", 403));
  }
```

- [ ] **Step 4: Run → PASS** — `node --experimental-test-module-mocks --test --test-force-exit test/profileViewerParity.test.js`
  (the Task 4 test already sends `userId` = the caller, so it stays green).

- [ ] **Step 5: `docs/REMAINING_WORK.md`** — replace
  `- [ ] \`followUser\` / \`unfollowUser\` act only for the caller (\`:userId\` must be \`req.user\`). S` with:

```markdown
- [x] `followUser` / `unfollowUser` act only for the caller (403 when `:userId` is someone else); both clients already send their own id. Test `profileViewerParity`.
```

- [ ] **Step 6: Commit**

```bash
cd /Users/davis/Desktop/Personal/be-integration
git add controllers/users.js test/profileViewerParity.test.js docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(users): follow and unfollow only on the caller's own behalf

The :userId path segment was trusted, so any signed-in user could make
anyone follow or unfollow anyone. Now 403 unless it is the caller. Both
clients already send their own id.

Still open (docs/REMAINING_WORK.md, web parity Phase 1):
- web: read followersCount for signed-out visitors
- clients: render a blocked state from isBlocked
- decide: signed-out online/last-seen fields
EOF
```

---

## After the tasks (phase gate, not a task)

- Run the full suite file by file (Node 25 breaks `npm test`): `for f in test/*.test.js services/*.test.js; do node --experimental-test-module-mocks --test --test-force-exit "$f" >/dev/null 2>&1 || echo "FAIL $f"; done` — only the known local `JWT_SECRET` failure may remain.
- Live-API spot check after deploy (backend `main` auto-deploys): `curl -s https://api.banatalk.com/api/v1/auth/users/<id>/public | jq '.data | {coords: .location.coordinates, bm: .birth_month, f: .followers, fc: .followersCount, ring: .hasActiveStory}'` → `null, null, null, <n>, <bool>`.
- Re-check community#1/#6 and links#11 as closed in the audit tracker.

# Phase 1 item 3 — Chat (backend) — implementation tasks

Spec: `bananatalk_app/docs/superpowers/specs/2026-10-16-web-app-parity-design.md` §2 + Phase 1 item 3.
Audit: `bananatalk_app/docs/audits/2026-10-16-web-parity/chat.md` (chat#2, #3, #8, #10, #11; chat#1 is the edit alias).

## Base and conventions

- **Base:** backend `be-integration` `main` **after** `fix/moments-stories-audit` is merged (Phase 1 item 0).
  Branch for this work: `git checkout -b fix/chat-parity-p1 main` (after the merge).
- **Overlap check (done):** `git diff main...fix/moments-stories-audit -- controllers/messages* controllers/conversations* controllers/messageManagement.js socket*`
  touches only `populate(...)` select strings (adds `privacySettings.showGiftingLevel`) in `controllers/messages.js`,
  `controllers/messageManagement.js`, `controllers/conversations.js`, plus presence/privacy code in `socket/socketHandler.js`.
  `main` has 6 commits not on the branch; none touch chat files. No logical conflict with any task below.
  **All line numbers below are from `fix/moments-stories-audit` (d6b0c33)** = what `main` holds after the merge.
  They shift slightly as earlier tasks land. Anchor every edit on the quoted code, not on the line number.
- **Test command:** local Node is v25 (memory: `SlowBuffer` gone → `jsonwebtoken` throws at require). Every command
  below therefore adds `--require ./test/helpers/nodeCompat.js`. That flag does nothing on Node 20 (prod/CI).
  Run from `/Users/davis/Desktop/Personal/be-integration`.
- **Commits:** no `Co-Authored-By`, no AI attribution. Each commit updates `docs/REMAINING_WORK.md`: it ticks its own
  line and its body lists what is still open. Pushing `main` deploys, so push only after the full suite passes
  (end of this phase, not per task).
- **Live-client compatibility (spec §2):** every response change here is additive or a bug fix. Nothing a live
  client reads is removed. The live web (`language_exchange_web_front` `origin/main` a944011) and app 2.6.1 are checked
  per task.

### Input classes that bite here

| Input | Where it matters | Handling below |
|---|---|---|
| `blockedUsers` / `blockedBy` are **subdocuments** `{userId, blockedAt}`, not ids | socket block check (`id.toString() === receiver` is never true for a subdoc; verified: `String(subdoc)` prints `{ userId: new ObjectId(...) ... }`) | Task 0 compares `entry.userId`, falling back to a bare id for legacy rows |
| Populated vs unpopulated refs | wave/story emits (sender was a bare ObjectId → web `msg.sender._id` undefined → wrong side); `Conversation.unreadCount[].user` | Task 5 populates both; Task 4's `unreadCountFor` accepts `user` or `user._id` |
| Legacy messages without `deletedFor` / `participants` / `read` | thread and feed filters; `createConversationRoom` existing branch | `$ne` on an array also matches a missing field. Legacy `participants: []` passes through as it does today (no reader uses it) |
| Group / hub / topic-room rows | `/messages/user/:id` deleted-conversation join | `buildConversationIndex` skips rows that don't have exactly 2 participants. The Conversation read excludes `roomType: hub/topic`. Group messages with no `receiver` still match `receiver: {$nin}` (a missing field matches) |
| Duplicate DM Conversation rows (legacy, pre-`pairKey`) | deleted-conversation state | the newest row wins (`sort lastMessageAt -1`), the same rule `getUserSenders` uses |
| String vs boolean flags | `deleteForEveryone`, `forEveryone` | body counts only when `=== true`. Query counts only when `=== 'true'` (live web sends `?forEveryone=false` for delete-for-me) |
| Cap kill switch | `CONVERSATION_CAP_ENABLED` is `false` in prod | Task 1's cap check stays inactive in prod until the flag is turned on. Tests force it on |

---

### Task P1-CHAT-0: Socket block check reads the block entry's `userId` (prerequisite, found while planning)

Found while tracing the "block check" for item (a). `socket/socketHandler.js:927-932` (text `sendMessage`, the app's
main send path) and `socket/socketGuards.js:55-60` (`assertDmSendAllowed`, used for voice and disappearing messages) compare
`id.toString() === receiver` over `blockedUsers`/`blockedBy`. Those arrays hold `{userId, blockedAt, reason}`
subdocuments (`models/User.js:774-800`), so the comparison never matches. **No socket send to or from a blocked user is
refused.** The REST path (`createMessage`, `senderUser.isBlocked()`) is correct. No existing test covers this
(`test/socketGuards.test.js` has no block case). Phase 1 item 3 asks for block checks on chat, so fix it first.

**Files:**
- Modify: `socket/socketGuards.js:42-60` (add `isBlockedEitherWay`, use it in `assertDmSendAllowed`), `:134-142` (export)
- Modify: `socket/socketHandler.js:29-31` (import), `:927-932` (use helper)
- Test: `test/socketBlockCheck.test.js` (new)
- Docs: `docs/REMAINING_WORK.md` (adds this phase's checklist, see step 6)

**Interfaces:**
- Consumes: `User` hydrated doc or lean object with `blockedUsers`/`blockedBy` (subdocs or legacy bare ids).
- Produces: `isBlockedEitherWay(senderUser, receiverId) -> boolean` exported from `socket/socketGuards.js`. The socket
  `sendMessage` error ack stays `{status:'error', error:'Cannot send message to blocked user'}` (the app already handles this string).

- [ ] **Step 1: Write the failing test** `test/socketBlockCheck.test.js`

```js
'use strict';
/**
 * The socket send paths refuse blocked pairs.
 *
 * blockedUsers / blockedBy hold { userId, blockedAt, reason } subdocuments.
 * Both socket checks compared `entry.toString() === receiver`, and a
 * subdocument's toString is its inspect output, never the id — so every
 * socket text, voice and disappearing message to or from a blocked user was
 * delivered. The REST path (User#isBlocked) compared entry.userId and was fine.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, User, Message, initializeSocket, isBlockedEitherWay, assertDmSendAllowed;

const connectSocket = async (userId) => {
  let connectionHandler;
  const io = {
    use: () => {},
    on: (event, fn) => { if (event === 'connection') connectionHandler = fn; },
    to: () => ({ emit: () => {} }),
    in: () => ({ emit: () => {}, fetchSockets: async () => [] }),
    sockets: { sockets: new Map(), adapter: { rooms: new Map() } },
    emit: () => {},
  };
  initializeSocket(io);
  const handlers = new Map();
  const socket = {
    id: `sock-${userId}`,
    user: { id: String(userId) },
    deviceId: 'test-device',
    handshake: { auth: {}, query: {}, headers: {} },
    rooms: new Set(),
    on: (event, fn) => handlers.set(event, fn),
    emit: () => {},
    join: () => {},
    leave: () => {},
    to: () => ({ emit: () => {} }),
    broadcast: { emit: () => {} },
    disconnect: () => {},
  };
  await connectionHandler(socket);
  return handlers;
};

const send = (handlers, data) => new Promise((resolve) => {
  handlers.get('sendMessage')(data, resolve);
});

const realLog = console.log;
const realError = console.error;
const realWarn = console.warn;

test.before(async () => {
  console.log = () => {};
  console.error = () => {};
  console.warn = () => {};
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'socketBlockCheck' });
  User = require('../models/User');
  Message = require('../models/Message');
  ({ initializeSocket } = require('../socket/socketHandler'));
  ({ isBlockedEitherWay, assertDmSendAllowed } = require('../socket/socketGuards'));
});
test.after(async () => {
  await new Promise((r) => setTimeout(r, 3000));
  await mongoose.disconnect();
  await mongod.stop();
  console.log = realLog;
  console.error = realError;
  console.warn = realWarn;
});

const makeUser = (name, extra = {}) => User.create({
  name, email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder', birth_year: '2000', birth_month: '1',
  birth_day: '1', gender: 'other', native_language: 'English', language_to_learn: 'Korean',
  ...extra,
});

test('isBlockedEitherWay reads subdocument userId, legacy bare ids, both directions', () => {
  const bob = new mongoose.Types.ObjectId();
  const other = new mongoose.Types.ObjectId();
  const hydrated = new User({ blockedUsers: [{ userId: bob }], blockedBy: [] });
  assert.equal(isBlockedEitherWay(hydrated, String(bob)), true);
  assert.equal(isBlockedEitherWay(hydrated, String(other)), false);

  const blockedMe = new User({ blockedUsers: [], blockedBy: [{ userId: bob }] });
  assert.equal(isBlockedEitherWay(blockedMe, String(bob)), true);

  // Lean rows and pre-subdocument data: bare ObjectIds.
  assert.equal(isBlockedEitherWay({ blockedUsers: [bob], blockedBy: [] }, String(bob)), true);
  assert.equal(isBlockedEitherWay({}, String(bob)), false);
  assert.equal(isBlockedEitherWay(null, String(bob)), false);
});

test('assertDmSendAllowed refuses a blocked receiver (voice / disappearing paths)', async () => {
  const bob = new mongoose.Types.ObjectId();
  const me = new User({ blockedUsers: [{ userId: bob }], blockedBy: [] });
  await assert.rejects(
    assertDmSendAllowed({ senderUser: me, userId: String(me._id), receiver: String(bob) }),
    /Cannot send message to blocked user/
  );
});

test('socket sendMessage to someone I blocked is refused and stores nothing', async () => {
  const bob = await makeUser('blk-bob');
  const ada = await makeUser('blk-ada', { blockedUsers: [{ userId: bob._id }] });
  await Message.create({ sender: bob._id, receiver: ada._id, message: 'earlier' });

  const handlers = await connectSocket(ada._id);
  const ack = await send(handlers, { receiver: String(bob._id), message: 'should not arrive' });

  assert.equal(ack.status, 'error');
  assert.equal(ack.error, 'Cannot send message to blocked user');
  assert.equal(await Message.countDocuments({ sender: ada._id }), 0);
});

test('socket sendMessage to someone who blocked me is refused', async () => {
  const bob = await makeUser('blkby-bob');
  const ada = await makeUser('blkby-ada', { blockedBy: [{ userId: bob._id }] });

  const handlers = await connectSocket(ada._id);
  const ack = await send(handlers, { receiver: String(bob._id), message: 'nope' });

  assert.equal(ack.status, 'error');
  assert.equal(ack.error, 'Cannot send message to blocked user');
});

test('an unblocked pair still sends', async () => {
  const bob = await makeUser('ok-bob');
  const ada = await makeUser('ok-ada', { blockedUsers: [{ userId: new mongoose.Types.ObjectId() }] });
  await Message.create({ sender: bob._id, receiver: ada._id, message: 'hi' });

  const handlers = await connectSocket(ada._id);
  const ack = await send(handlers, { receiver: String(bob._id), message: 'hello' });
  assert.equal(ack.status, 'success');
});
```

- [ ] **Step 2: Run and confirm it fails**

```
node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit test/socketBlockCheck.test.js
```
Expected: FAIL. The first test throws `TypeError: isBlockedEitherWay is not a function`. The assertDmSendAllowed test fails
with "Missing expected rejection" (or a later first-chat DB error). Both socket block tests get `ack.status === 'success'`.
The unblocked test passes.

- [ ] **Step 3: Implement**

`socket/socketGuards.js`: insert directly above the `/**` doc comment of `assertDmSendAllowed` (line 36):

```js
/**
 * Has either side of this pair blocked the other?
 *
 * blockedUsers / blockedBy hold { userId, blockedAt, reason } subdocuments
 * (models/User.js). Comparing the ENTRY's toString — what both socket checks
 * did — never matches, because a subdocument stringifies to its inspect
 * output. Bare ids (lean legacy rows) are still accepted.
 */
const blockEntryId = (entry) => String(entry && entry.userId ? entry.userId : entry);

const isBlockedEitherWay = (senderUser, receiverId) => {
  if (!senderUser) return false;
  const target = String(receiverId);
  return [senderUser.blockedUsers, senderUser.blockedBy]
    .some((list) => (list || []).some((entry) => blockEntryId(entry) === target));
};
```

In `assertDmSendAllowed`, replace:

```js
  const blockedUsers = senderUser.blockedUsers || [];
  const blockedBy = senderUser.blockedBy || [];
  if (blockedUsers.some((id) => id.toString() === receiver)
      || blockedBy.some((id) => id.toString() === receiver)) {
    throw new Error('Cannot send message to blocked user');
  }
```
with:
```js
  if (isBlockedEitherWay(senderUser, receiver)) {
    throw new Error('Cannot send message to blocked user');
  }
```

Add `isBlockedEitherWay,` to `module.exports` (after `isHexId,`).

`socket/socketHandler.js:29-31`, change the import to:
```js
const {
  isHexId, assertDmSendAllowed, countFirstChatMessages, validateVoicePayload, MAX_MESSAGE_LENGTH,
  isBlockedEitherWay,
} = require('./socketGuards');
```
`socket/socketHandler.js:926-932`, replace:
```js
      // Check block status (using cached data)
      const blockedUsers = senderUser.blockedUsers || [];
      const blockedBy = senderUser.blockedBy || [];
      if (blockedUsers.some(id => id.toString() === receiver) ||
          blockedBy.some(id => id.toString() === receiver)) {
        throw new Error('Cannot send message to blocked user');
      }
```
with:
```js
      // Check block status (using cached data). The lists hold subdocuments;
      // see isBlockedEitherWay for why comparing entries directly never fired.
      if (isBlockedEitherWay(senderUser, receiver)) {
        throw new Error('Cannot send message to blocked user');
      }
```
Also grep for any other copy: `grep -rn "blockedUsers.some\|blockedBy.some" socket controllers lib`. Fix any remaining
`entry.toString()` comparison over these arrays the same way (on d6b0c33 only these two exist).

- [ ] **Step 4: Run → PASS** (same command). Then run the neighbouring suites:
`... test/socketGuards.test.js test/socketSendPath.test.js test/chatMessageSentEcho.test.js test/socketConversationCap.test.js` → all PASS.

- [ ] **Step 5: Known trade-off to record:** `getCachedUser` caches the sender for `USER_CACHE_TTL` (60 s), so a block
  takes up to 60 s to apply on the socket path unless `invalidateUserCache` is called on block/unblock. Check with
  `grep -rn invalidateUserCache controllers`. If block/unblock doesn't call it, add it to the open list (don't fix it here).

- [ ] **Step 6: REMAINING_WORK + commit.** Insert this block in `docs/REMAINING_WORK.md` on the line right after the
  `## 4. Code work — open` heading (a blank line above and below). Tick the first line:

```md
Web ↔ app parity, Phase 1 item 3 — chat (spec `bananatalk_app/docs/superpowers/specs/2026-10-16-web-app-parity-design.md`)
- [x] Socket block check compared the block subdocument, not its `userId`, so socket text/voice/disappearing sends to or from a blocked user went through. Test `socketBlockCheck`.
- [ ] `POST /messages/conversations` creates no "Conversation started" message; block check + new-conversation cap (403 `CONVERSATION_START_LIMIT`, not charged); daily-message-limit gate removed (nothing is sent). Test `conversationRoomNoMessage`.
- [ ] `DELETE /messages/:id` deletes for everyone on body `deleteForEveryone === true` or query `forEveryone=true`. Test `messageDeleteForEveryone`.
- [ ] Thread and `/messages/user/:id` hide `deletedFor` messages; `/messages/user/:id` also hides blocked partners and conversations the owner deleted. Test `chatReadFilters`.
- [ ] Socket `newMessage.unreadCount` is the receiver's real conversation unread count (was always 1). Test `socketUnreadCount`.
- [ ] Wave mirror and `story_share` emits carry a populated `sender`/`receiver`. Test `chatSenderPopulated`.
- [ ] `PUT /messages/:id` accepts `content` as an alias of `message`. Test `messageEditContentAlias`.
- [ ] `GET /conversations` (+ `/:id`) `lastMessage` includes `media.type`. Test `conversationListPreview`.
- [ ] Owner, measure first: `db.messages.countDocuments({ message: 'Conversation started' })`. These legacy rows show as text bubbles in the app and count toward the 5-message first-chat limit. Then decide on a purge script.
- [ ] Wave mirror and `story_share` messages never create/update a Conversation row, so they are missing from `GET /conversations` (the only list Phase 3 web will use). Decide whether to route them through `findOrCreateDm`.
- [ ] The thread does not hide the history of a deleted or blocked conversation: `deletedBy` has no timestamp, and the sender stays in `deletedBy` after resuming. Needs a per-user `deletedAt` if wanted.
- [ ] `GET /messages/senders/:userId` (app chat list) has no block filter. Verify, and decide.
```

```
git add socket/socketGuards.js socket/socketHandler.js test/socketBlockCheck.test.js docs/REMAINING_WORK.md
git commit -m "fix(chat): socket sends refuse blocked pairs" -m "blockedUsers/blockedBy hold {userId} subdocuments; both socket checks compared the entry itself, which never matched, so socket text, voice and disappearing messages to or from a blocked user were delivered. One helper, isBlockedEitherWay, now backs both paths.

Still open (Phase 1 item 3): conversation-room message + block/cap, delete-for-everyone query flag, deletedFor/blocked read filters, real socket unread count, populated wave/story_share senders, edit content alias, lastMessage media.type; owner purge of legacy 'Conversation started' rows."
```

---

### Task P1-CHAT-1: `POST /messages/conversations` stops creating "Conversation started"; block check + new-conversation cap (chat#3)

**Files:**
- Modify: `controllers/messages.js:9` (import), `:13` (import), `:29-121` (`createConversationRoom`)
- Modify: `routes/messages.js:45-52` (drop `checkMessageLimit` from this route)
- Test: `test/conversationRoomNoMessage.test.js` (new)

**Interfaces:**
- Consumes: `checkBlockStatus(a, b)` (`utils/blockingUtils.js:75`, 30 s cache, fails open), `evaluateConversationStart({userId, receiverId})`
  and `CONVERSATION_START_LIMIT_MESSAGE` (`lib/conversationQuota.js`).
- Produces (response contract, **shape unchanged**):
  - existing thread → `200 {success, data:{isNew:false, participants, lastMessage:<populated msg>, isGroupMessage:false}}` (unchanged)
  - no thread → `201 {success, data:{isNew:true, participants:[{_id,name},{_id,name}], lastMessage:null, isGroupMessage:false}}`
  - **no top-level `data._id` ever** (live `NewChat.tsx:94-99` navigates to `/chat/<data._id>` when one is present)
  - blocked either way → `403 'Cannot send message to this user'` (same text as `createMessage`)
  - cap reached (only when `CONVERSATION_CAP_ENABLED=true`) → `403 {error: CONVERSATION_START_LIMIT_MESSAGE, code:'CONVERSATION_START_LIMIT'}`. **Not charged.** The first real send charges.
  - **Must not create a Conversation row.** `evaluateConversationStart` treats an existing row as a reply (`reason:'reply'`, never capped),
    so a row created here would let every later send skip the cap.

- [ ] **Step 1: Check every reader of this response tolerates `lastMessage: null` (and record the result in the commit body)**

```
cd /Users/davis/Desktop/Personal/language_exchange_web_front && git fetch origin && \
  git grep -n "createChatRoom\|messages/conversations" origin/main -- src ; git grep -n "createChatRoom(" main -- src
cd /Users/davis/Desktop/Personal/bt-integration/bananatalk_app && grep -rn "createConversationRoom\|createConversationRoomURL" lib test
```
Findings at planning time (re-confirm, they must still hold):
- `src/components/chat/NewChat.tsx:92-99` reads only `result?.data?._id`. That is undefined both before and after, so it
  always takes the `navigate(/chat/<userId>)` fallback. A 403 shows `error.data.error` as a toast (spec: intended).
- `src/components/profile/parts/ProfileActions.tsx:139` and `ConversationStarters.tsx:152` ignore the result and
  swallow errors, then navigate. A block/cap 403 is silent there, and the first real send gets the refusal instead.
- `src/components/chat/MessageBubble.tsx:195-200` and `UsersList.tsx:86` hide legacy "Conversation started" rows. Keep them.
- Local web `main` (23 unpushed commits, Phase 0) has the same three call sites, unchanged.
- App: `lib/services/conversation_service.dart:23-56` `createConversationRoom` POSTs to `conversations`
  (= `/api/v1/conversations`, which has no POST `/` route → 404). It has **no callers** in `lib/` or `test/`. Nothing in the app reads this response.

- [ ] **Step 2: Write the failing test** `test/conversationRoomNoMessage.test.js`

```js
'use strict';
/**
 * POST /api/v1/messages/conversations — "open a chat with this person".
 *
 * It used to create a real Message ("Conversation started") from the caller
 * to a stranger: a visible bubble in the app, one of the five first-chat
 * messages spent, and no block or new-conversation check on the way.
 * Opening a chat now creates nothing; the first real send does.
 */
// The cap branch is exercised here, so force the kill switch on before
// config/limitations.js is first required (it defaults OFF in prod).
process.env.CONVERSATION_CAP_ENABLED = 'true';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, Message, User, Conversation, controller, messagesRouter, checkMessageLimit, localDayKey;

const asHandler = (fn) => (req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  fn(req, res, (err) => (err
    ? resolve({ status: err.statusCode || 500, error: err.message, code: err.errorCode })
    : resolve({ status: 204 })))
    .catch(reject);
});

test.before(async () => {
  console.error = () => {};
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'convRoomNoMessage' });
  Message = require('../models/Message');
  User = require('../models/User');
  Conversation = require('../models/Conversation');
  controller = require('../controllers/messages');
  messagesRouter = require('../routes/messages');
  ({ checkMessageLimit } = require('../middleware/checkLimitations'));
  ({ localDayKey } = require('../lib/localDay'));
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([Message.deleteMany({}), User.deleteMany({}), Conversation.deleteMany({})]);
});

const makeUser = (name, extra = {}) => User.create({
  name,
  email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '2000', birth_month: '1', birth_day: '1', gender: 'other',
  native_language: 'English', language_to_learn: 'Korean',
  userMode: 'regular', profileCompleted: true, timezone: 'UTC',
  ...extra,
});

const open = (viewer, other) => asHandler(controller.createConversationRoom)({
  user: viewer, body: { userId: String(other._id) },
});

test('a new pair gets 201 with lastMessage null, and nothing is written', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');

  const res = await open(me, ada);

  assert.equal(res.status, 201, JSON.stringify(res));
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.isNew, true);
  assert.equal(res.body.data.lastMessage, null);
  assert.equal(res.body.data.isGroupMessage, false);
  // Live web NewChat.tsx navigates to /chat/<data._id> when present — there must be none.
  assert.equal(res.body.data._id, undefined);
  assert.deepEqual(
    res.body.data.participants.map((p) => String(p._id)).sort(),
    [String(me._id), String(ada._id)].sort()
  );
  assert.ok(res.body.data.participants.every((p) => typeof p.name === 'string'));

  assert.equal(await Message.countDocuments({}), 0, 'no "Conversation started" message');
  // A pre-created Conversation would make every later send a "reply" and skip the cap.
  assert.equal(await Conversation.countDocuments({}), 0, 'no Conversation row either');
});

test('an existing thread still answers 200 with its last message, unchanged', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  const last = await Message.create({ sender: ada._id, receiver: me._id, message: 'hey' });

  const res = await open(me, ada);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.isNew, false);
  assert.equal(String(res.body.data.lastMessage._id), String(last._id));
  assert.equal(res.body.data._id, undefined);
  assert.equal(await Message.countDocuments({}), 1);
});

test('refused (403) when I blocked them, nothing written', async () => {
  const ada = await makeUser('ada');
  const me = await makeUser('me', { blockedUsers: [{ userId: ada._id }] });

  const res = await open(me, ada);

  assert.equal(res.status, 403);
  assert.equal(res.error, 'Cannot send message to this user');
  assert.equal(await Message.countDocuments({}), 0);
});

test('refused (403) when they blocked me', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada', { blockedUsers: [{ userId: me._id }] });

  const res = await open(me, ada);

  assert.equal(res.status, 403);
});

test('blocked also refuses a pair that already has history', async () => {
  const ada = await makeUser('ada');
  const me = await makeUser('me', { blockedUsers: [{ userId: ada._id }] });
  await Message.create({ sender: ada._id, receiver: me._id, message: 'old' });

  const res = await open(me, ada);
  assert.equal(res.status, 403);
});

test('a capped caller is refused with CONVERSATION_START_LIMIT and is not charged', async () => {
  const today = localDayKey(new Date(), 'UTC');
  const me = await makeUser('me', { conversationQuota: { dayKey: today, started: 3, adCredits: 0 } });
  const ada = await makeUser('ada');

  const res = await open(me, ada);

  assert.equal(res.status, 403);
  assert.equal(res.code, 'CONVERSATION_START_LIMIT');
  const fresh = await User.findById(me._id).select('conversationQuota').lean();
  assert.equal(fresh.conversationQuota.started, 3, 'opening a chat must not spend quota');
  assert.equal(await Message.countDocuments({}), 0);
});

test('an allowed open does not charge the quota (the first real send does)', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');

  const res = await open(me, ada);

  assert.equal(res.status, 201);
  const fresh = await User.findById(me._id).select('conversationQuota').lean();
  assert.ok(!fresh.conversationQuota || !fresh.conversationQuota.started, 'started stays 0/absent');
});

test('a capped caller can still open a thread that already exists', async () => {
  const today = localDayKey(new Date(), 'UTC');
  const me = await makeUser('me', { conversationQuota: { dayKey: today, started: 3, adCredits: 0 } });
  const ada = await makeUser('ada');
  await Message.create({ sender: me._id, receiver: ada._id, message: 'earlier' });

  const res = await open(me, ada);
  assert.equal(res.status, 200);
});

test('self and unknown users are still refused', async () => {
  const me = await makeUser('me');
  assert.equal((await open(me, me)).status, 400);
  assert.equal((await open(me, { _id: new mongoose.Types.ObjectId() })).status, 404);
});

test('route: nothing is sent, so the daily message limit no longer gates opening a chat', () => {
  const layer = messagesRouter.stack.find(
    (l) => l.route && l.route.path === '/conversations' && l.route.methods.post
  );
  assert.ok(layer, 'expected POST /conversations');
  const handlers = layer.route.stack.filter((s) => s.method === 'post').map((s) => s.handle);
  assert.ok(!handlers.includes(checkMessageLimit), 'checkMessageLimit must not run on POST /conversations');
  assert.equal(handlers[handlers.length - 1], controller.createConversationRoom);
});
```

- [ ] **Step 3: Run and confirm it fails**

```
node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit test/conversationRoomNoMessage.test.js
```
Expected: FAIL. First test: `lastMessage` is the populated "Conversation started" message, and the `Message.countDocuments` assertion fails with 1 !== 0.
Both block tests get 201 or 200 instead of 403. The cap test gets 201. The route test fails because `checkMessageLimit` is still mounted.
The existing-thread, self and unknown tests pass.

- [ ] **Step 4: Implement**

`controllers/messages.js:9`, change to:
```js
const { getBlockedUserIds, checkBlockStatus } = require('../utils/blockingUtils');
```
`controllers/messages.js:13`, change to:
```js
const {
  chargeConversationStart,
  evaluateConversationStart,
  CONVERSATION_START_LIMIT_MESSAGE,
} = require('../lib/conversationQuota');
```
Replace the whole of `exports.createConversationRoom` (lines 29-121, from the `/**` doc comment through the closing `});`) with:

```js
/**
 * @desc    "Open a chat with this person" (web: NewChat, profile Message
 *          button, conversation starters)
 * @route   POST /api/v1/messages/conversations
 * @access  Private
 *
 * Creates NOTHING. It used to create a real Message ("Conversation started")
 * from the caller: a visible text bubble in the app from a stranger, one of
 * the five first-chat messages spent, and no block or new-conversation check
 * on the way. The first real send creates the message and the Conversation,
 * and charges the quota.
 *
 * It must not create a Conversation row either: evaluateConversationStart
 * treats an existing row as a reply, and replies are never capped, so a
 * pre-created row would let the first real send skip the cap.
 *
 * Response shape is the old one: { isNew, participants, lastMessage,
 * isGroupMessage }, with lastMessage null for a new pair and NO top-level
 * data._id (live web NewChat navigates to /chat/<data._id> when present).
 */
exports.createConversationRoom = asyncHandler(async (req, res, next) => {
  const { userId } = req.body || {};

  if (!userId) {
    return next(new ErrorResponse('User ID is required', 400));
  }
  if (!req.user) {
    return next(new ErrorResponse('Not authenticated', 401));
  }

  const currentUserId = req.user._id;

  if (currentUserId.toString() === String(userId)) {
    return next(new ErrorResponse('Cannot create conversation with yourself', 400));
  }

  const target = await User.findById(userId).select('_id name').lean();
  if (!target) {
    return next(new ErrorResponse('User not found', 404));
  }

  // The refusal a send to a blocked pair gets (createMessage). Either direction.
  const block = await checkBlockStatus(currentUserId, userId);
  if (block.isBlocked) {
    return next(new ErrorResponse('Cannot send message to this user', 403));
  }

  try {
    const existingMessages = await Message.find({
      $or: [
        { sender: currentUserId, receiver: userId },
        { sender: userId, receiver: currentUserId }
      ],
      isGroupMessage: false
    })
    .sort({ createdAt: -1 })
    .limit(1)
    .lean();

    if (existingMessages.length > 0) {
      const populatedMessage = await Message.populate(existingMessages[0], [
        { path: 'sender', select: 'name avatar' },
        { path: 'receiver', select: 'name avatar' },
        { path: 'participants', select: 'name avatar' }
      ]);

      return res.status(200).json({
        success: true,
        data: {
          isNew: false,
          participants: populatedMessage.participants,
          lastMessage: populatedMessage,
          isGroupMessage: false
        }
      });
    }

    // A new pair: would the first send be refused by the new-conversation
    // cap? Say so now. Read-only: chargeConversationStart runs on the first
    // real send, never here. Inert while CONVERSATION_CAP_ENABLED is off.
    const decision = await evaluateConversationStart({
      userId: currentUserId,
      receiverId: userId,
    });
    if (!decision.allowed && decision.reason === 'limit') {
      return next(new ErrorResponse(CONVERSATION_START_LIMIT_MESSAGE, 403, 'CONVERSATION_START_LIMIT'));
    }

    return res.status(201).json({
      success: true,
      data: {
        isNew: true,
        // Same fields the old populate selected ('name avatar'; avatar is not
        // a User field, so it was always just _id + name).
        participants: [
          { _id: currentUserId, name: req.user.name },
          { _id: target._id, name: target.name }
        ],
        lastMessage: null,
        isGroupMessage: false
      }
    });
  } catch (error) {
    console.error('Error creating conversation:', error);
    return next(new ErrorResponse('Failed to create conversation', 500));
  }
});
```

`routes/messages.js:45-52`, replace with:
```js
// Opening a chat sends nothing (see createConversationRoom), so the daily
// message limit does not apply; the first real send enforces it.
router.route('/conversations').post(
  protect,
  messageLimiter,
  createConversationRoomValidation,
  validate,
  createConversationRoom
).get(protect, getConversationRooms);
```
(`checkMessageLimit` is still imported and used by other routes in that file. Leave the import.)

- [ ] **Step 5: Run → PASS** (same command). Then `... test/conversationStartCoverage.test.js test/checkConversationStart.test.js test/messageParticipantGuard.test.js` → PASS.

- [ ] **Step 6: Commit** (tick the `POST /messages/conversations` line in `docs/REMAINING_WORK.md`)

```
git add controllers/messages.js routes/messages.js test/conversationRoomNoMessage.test.js docs/REMAINING_WORK.md
git commit -m "fix(chat): opening a chat no longer posts 'Conversation started'" -m "POST /messages/conversations created a real message from the caller: a visible bubble in the app, one of the five first-chat messages spent, no block or cap check. It now writes nothing (no Message, no Conversation, which would let the first send skip the cap), refuses blocked pairs (403) and a capped caller (403 CONVERSATION_START_LIMIT, read-only while CONVERSATION_CAP_ENABLED is off), and no longer runs the daily message limit. Response shape unchanged: lastMessage is null for a new pair, no data._id.

Readers checked: live web NewChat reads only data._id (absent, falls back to /chat/<userId>); ProfileActions and ConversationStarters ignore the result; the app has no caller.

Still open (Phase 1 item 3): delete-for-everyone query flag, deletedFor/blocked read filters, real socket unread count, populated wave/story_share senders, edit content alias, lastMessage media.type; owner purge of legacy 'Conversation started' rows."
```

---

### Task P1-CHAT-2: `DELETE /messages/:id` honours body `deleteForEveryone === true` OR query `forEveryone=true` (chat#2)

**Files:**
- Modify: `controllers/messageManagement.js:101-104` (flag parsing), `:117` and `:206` (use the parsed flag)
- Test: `test/messageDeleteForEveryone.test.js` (new)

**Interfaces:**
- Consumes: app 2.6.1 sends JSON body `{deleteForEveryone: <bool>}` (`message_provider.dart:303-306`). Live web sends
  `DELETE /messages/:id?forEveryone=true|false` with no body (`chatSlice.ts:253-259`). Phase 3 web will send the body key.
- Produces: unchanged responses and socket events (`messageDeleted {deletedForEveryone:true,...}` to `user_<receiver>` and `user_<sender>`).
  Behaviour change: the body string `'false'` (or any truthy non-`true` value) used to mean "for everyone". It now means "for me".
  No known client sends a string.

- [ ] **Step 1: Write the failing test** `test/messageDeleteForEveryone.test.js`

```js
'use strict';
/**
 * DELETE /messages/:id — "delete for everyone" from every client.
 *
 * The app sends JSON { deleteForEveryone: true }. The live web sends
 * ?forEveryone=true and no body, which the controller never read: it took
 * the "delete for me" branch, the receiver kept the message, and it came back
 * for the web user after a reload.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, Message, User, controller;

const run = (fn, req, emits) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  const io = { to: (room) => ({ emit: (event, payload) => emits.push({ room, event, payload }) }) };
  req.app = { get: (k) => (k === 'io' ? io : null) };
  req.query = req.query || {};
  fn(req, res, (err) => (err
    ? resolve({ status: err.statusCode || 500, error: err.message })
    : resolve({ status: 204 })))
    .catch(reject);
});

test.before(async () => {
  console.log = () => {};
  console.error = () => {};
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'msgDeleteForEveryone' });
  Message = require('../models/Message');
  User = require('../models/User');
  controller = require('../controllers/messageManagement');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([Message.deleteMany({}), User.deleteMany({})]);
});

const makeUser = (name) => User.create({
  name,
  email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '2000', birth_month: '1', birth_day: '1', gender: 'other',
  native_language: 'English', language_to_learn: 'Korean',
});

const setup = async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  const msg = await Message.create({ sender: me._id, receiver: ada._id, message: 'oops' });
  return { me, ada, msg };
};

const del = (me, msg, { body, query } = {}) => {
  const emits = [];
  return run(controller.deleteMessage, {
    user: me, params: { id: String(msg._id) }, body, query,
  }, emits).then((r) => ({ ...r, emits }));
};

const assertDeletedForEveryone = async ({ res, msg, ada }) => {
  assert.equal(res.status, 200, JSON.stringify(res));
  assert.equal(res.body.message, 'Message deleted for everyone');
  const stored = await Message.findById(msg._id).lean();
  assert.equal(stored.isDeleted, true);
  assert.equal(stored.message, 'This message was deleted');
  const toReceiver = res.emits.find((e) => e.room === `user_${ada._id}` && e.event === 'messageDeleted');
  assert.ok(toReceiver, 'the receiver is told');
  assert.equal(toReceiver.payload.deletedForEveryone, true);
};

test('live web: ?forEveryone=true with no body deletes for everyone', async () => {
  const { me, ada, msg } = await setup();
  const res = await del(me, msg, { query: { forEveryone: 'true' } });
  await assertDeletedForEveryone({ res, msg, ada });
});

test('app: body { deleteForEveryone: true } still deletes for everyone', async () => {
  const { me, ada, msg } = await setup();
  const res = await del(me, msg, { body: { deleteForEveryone: true } });
  await assertDeletedForEveryone({ res, msg, ada });
});

test('live web delete-for-me: ?forEveryone=false only hides it for me', async () => {
  const { me, ada, msg } = await setup();
  const res = await del(me, msg, { query: { forEveryone: 'false' } });
  assert.equal(res.body.message, 'Message deleted for you');
  const stored = await Message.findById(msg._id).lean();
  assert.notEqual(stored.isDeleted, true);
  assert.deepEqual(stored.deletedFor.map(String), [String(me._id)]);
  assert.ok(!res.emits.some((e) => e.room === `user_${ada._id}`), 'the receiver hears nothing');
});

test('app delete-for-me: body { deleteForEveryone: false }', async () => {
  const { me, msg } = await setup();
  const res = await del(me, msg, { body: { deleteForEveryone: false } });
  assert.equal(res.body.message, 'Message deleted for you');
});

test('only a real boolean true in the body counts (the string "false" used to delete for everyone)', async () => {
  const { me, msg } = await setup();
  const res = await del(me, msg, { body: { deleteForEveryone: 'false' } });
  assert.equal(res.body.message, 'Message deleted for you');
  assert.notEqual((await Message.findById(msg._id).lean()).isDeleted, true);
});

test('no body and no query at all is delete-for-me, not a crash', async () => {
  const { me, msg } = await setup();
  const res = await del(me, msg, { body: undefined, query: {} });
  assert.equal(res.status, 200);
  assert.equal(res.body.message, 'Message deleted for you');
});

test('the query flag still respects the 1-hour window and sender-only rule', async () => {
  const { me, ada, msg } = await setup();
  await Message.updateOne({ _id: msg._id }, { $set: { createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000) } });
  const late = await del(me, msg, { query: { forEveryone: 'true' } });
  assert.equal(late.status, 400);

  const other = await Message.create({ sender: me._id, receiver: ada._id, message: 'mine' });
  const notMine = await del(ada, other, { query: { forEveryone: 'true' } });
  assert.equal(notMine.status, 403);
});
```

- [ ] **Step 2: Run and confirm it fails**

```
node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit test/messageDeleteForEveryone.test.js
```
Expected: FAIL. The `?forEveryone=true` test gets 'Message deleted for you'. The string `'false'` test gets 'Message deleted for everyone'.
The no-body test fails with a 500 or TypeError from destructuring `undefined`, depending on the asyncHandler path. The window test's first assertion gets 200 instead of 400.
The others pass.

- [ ] **Step 3: Implement** — `controllers/messageManagement.js`, replace line 103:

```js
  const { deleteForEveryone } = req.body; // true for "delete for everyone", false for "delete for me"
```
with:
```js
  // Two client shapes for the same request. The app sends JSON
  // { deleteForEveryone: true }; the live web sends ?forEveryone=true with no
  // body. Only a real boolean true in the body counts — a truthy string such
  // as 'false' used to delete for everyone.
  const deleteForEveryone = (req.body && req.body.deleteForEveryone === true)
    || (req.query && req.query.forEveryone === 'true');
```
Lines 117 (`if (deleteForEveryone) {`) and 206 (`message: deleteForEveryone ? ...`) stay as they are. They now read the
parsed boolean.

- [ ] **Step 4: Run → PASS.**

- [ ] **Step 5: Commit** (tick the `DELETE /messages/:id` line)

```
git add controllers/messageManagement.js test/messageDeleteForEveryone.test.js docs/REMAINING_WORK.md
git commit -m "fix(chat): delete-for-everyone from the web's query flag" -m "The live web sends DELETE /messages/:id?forEveryone=true with no body; only body.deleteForEveryone was read, so web 'delete for everyone' hid the message for the web user alone. Either shape now works; only a boolean true in the body counts.

Still open (Phase 1 item 3): deletedFor/blocked read filters, real socket unread count, populated wave/story_share senders, edit content alias, lastMessage media.type; owner purge of legacy 'Conversation started' rows."
```

---

### Task P1-CHAT-3: Thread and `/messages/user/:id` filter `deletedFor`; the feed also drops blocked partners and deleted conversations (chat#2, chat#10)

**Scope decision (flag to the caller):** the spec line says both endpoints filter "deletedFor and deleted/blocked conversations".
This task applies **`deletedFor` to both**. It applies **blocked partners and deleted conversations to `/messages/user/:id` only**
(the raw feed live web merges into its list, chat#10). It does **not** blank the thread of a deleted or blocked conversation, because:
1. `Conversation.deletedBy` has no timestamp, so there is no "messages before the deletion" to hide.
2. `updateConversation` removes only the **receiver** from `deletedBy` (`socketHandler.js:2032-2039`, `messages.js:681-686`).
   A deleter who resumes chatting stays in `deletedBy`, so a filtered thread would go blank while they talk.
3. App 2.6.1 opens a blocked chat with history visible and input disabled, and reporting needs that history.
   It's recorded as an open item in Task 0's checklist. If the caller wants the thread filtered anyway, it needs a per-user `deletedAt` (schema change) first.

**Files:**
- Modify: `controllers/messages.js:217-246` (`getUserMessages`: id guard, hidden-partner read, query)
- Modify: `controllers/messages.js:845-866` (`getConversation`: viewer id + `deletedFor` on both reads)
- Test: `test/chatReadFilters.test.js` (new)

**Interfaces:**
- Consumes: `getBlockedUserIds(userId)` (both directions, 120 s cache), `buildConversationIndex(rows, userId)` (`lib/chatListJoin.js`).
- Produces: same response shapes. Fewer rows, and `total` / `pagination` count only what is returned.
  `/messages/user/:id` with a non-ObjectId `:id` (admin path) → 400 instead of a cast 500.

- [ ] **Step 1: Write the failing test** `test/chatReadFilters.test.js`

```js
'use strict';
/**
 * What the two raw message reads hand back.
 *
 * - "Delete for me" pushes the viewer onto Message.deletedFor, but both reads
 *   filtered only isDeleted, so the message came back on the next load.
 * - GET /messages/user/:id (the feed the live web merges into its chat list)
 *   ignored blocks and deleted conversations, so a deleted chat reappeared
 *   and blocked people stayed listed.
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, Message, User, Conversation, controller;

const asHandler = (fn) => (req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  fn(req, res, (err) => (err
    ? resolve({ status: err.statusCode || 500, error: err.message })
    : resolve({ status: 204 })))
    .catch(reject);
});

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'chatReadFilters' });
  Message = require('../models/Message');
  User = require('../models/User');
  Conversation = require('../models/Conversation');
  controller = require('../controllers/messages');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([Message.deleteMany({}), User.deleteMany({}), Conversation.deleteMany({})]);
});

const makeUser = (name, extra = {}) => User.create({
  name,
  email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '2000', birth_month: '1', birth_day: '1', gender: 'other',
  native_language: 'English', language_to_learn: 'Korean',
  ...extra,
});

const say = (from, to, text, extra = {}) => Message.create({
  sender: from._id, receiver: to._id, message: text, ...extra,
});

const thread = (viewer, a, b) => asHandler(controller.getConversation)({
  user: viewer, params: { senderId: String(a._id), receiverId: String(b._id) }, query: {},
});

const feed = (viewer, owner = viewer) => asHandler(controller.getUserMessages)({
  user: viewer, params: { userId: String(owner._id) }, query: {},
});

const texts = (res) => res.body.data.map((m) => m.message).sort();

// ---------------------------------------------------------------- thread

test('thread: a message I deleted for me stays gone; my partner still sees it', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  await say(ada, me, 'keep');
  await say(me, ada, 'hidden for me', { deletedFor: [me._id] });

  const mine = await thread(me, me, ada);
  assert.deepEqual(texts(mine), ['keep']);
  assert.equal(mine.body.total, 1);

  const hers = await thread(ada, me, ada);
  assert.deepEqual(texts(hers), ['hidden for me', 'keep']);
});

test('thread: legacy rows without deletedFor are still returned', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  await Message.collection.insertOne({
    sender: ada._id, receiver: me._id, message: 'legacy', createdAt: new Date(), isGroupMessage: false,
  });
  assert.deepEqual(texts(await thread(me, me, ada)), ['legacy']);
});

test('thread: an admin reading for moderation is not filtered by their own id', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  const admin = await makeUser('admin', { role: 'admin' });
  await say(me, ada, 'hidden for me', { deletedFor: [me._id] });
  const res = await thread({ _id: admin._id, role: 'admin' }, me, ada);
  assert.deepEqual(texts(res), ['hidden for me']);
});

// ------------------------------------------------------- /messages/user/:id

test('feed: deletedFor me is hidden', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  await say(ada, me, 'keep');
  await say(ada, me, 'hidden', { deletedFor: [me._id] });

  const res = await feed(me);
  assert.deepEqual(texts(res), ['keep']);
  assert.equal(res.body.total, 1);
});

test('feed: partners I blocked, and partners who blocked me, are hidden', async () => {
  const blockedByMe = await makeUser('blockedByMe');
  const blocksMe = await makeUser('blocksMe');
  const ada = await makeUser('ada');
  const me = await makeUser('me', {
    blockedUsers: [{ userId: blockedByMe._id }],
    blockedBy: [{ userId: blocksMe._id }],
  });
  await say(blockedByMe, me, 'from blocked');
  await say(me, blocksMe, 'to blocker');
  await say(ada, me, 'from ada');

  assert.deepEqual(texts(await feed(me)), ['from ada']);
});

test('feed: a conversation I deleted is hidden; one only my partner deleted is not', async () => {
  const me = await makeUser('me');
  const gone = await makeUser('gone');
  const ada = await makeUser('ada');
  await Conversation.create({ participants: [me._id, gone._id], isGroup: false, deletedBy: [me._id] });
  await Conversation.create({ participants: [me._id, ada._id], isGroup: false, deletedBy: [ada._id] });
  await say(gone, me, 'from deleted chat');
  await say(me, gone, 'to deleted chat');
  await say(ada, me, 'from ada');

  assert.deepEqual(texts(await feed(me)), ['from ada']);
});

test('feed: a group message with no receiver is still returned, not a crash', async () => {
  const me = await makeUser('me');
  const x = await makeUser('x');
  const y = await makeUser('y');
  const gone = await makeUser('gone');
  await Conversation.create({ participants: [me._id, gone._id], isGroup: false, deletedBy: [me._id] });
  await Message.create({
    sender: me._id, isGroupMessage: true, participants: [me._id, x._id, y._id], message: 'group hi',
  });

  const res = await feed(me);
  assert.equal(res.status, 200);
  assert.deepEqual(texts(res), ['group hi']);
});

test('feed: an admin reads the owner\'s view (owner\'s blocks and deletions)', async () => {
  const blocked = await makeUser('blocked');
  const ada = await makeUser('ada');
  const me = await makeUser('me', { blockedUsers: [{ userId: blocked._id }] });
  const admin = await makeUser('admin', { role: 'admin' });
  await say(blocked, me, 'from blocked');
  await say(ada, me, 'from ada');

  const res = await feed({ _id: admin._id, role: 'admin' }, me);
  assert.deepEqual(texts(res), ['from ada']);
});

test('feed: a non-ObjectId :userId (admin path) is a 400, not a cast 500', async () => {
  const admin = await makeUser('admin', { role: 'admin' });
  const res = await asHandler(controller.getUserMessages)({
    user: { _id: admin._id, role: 'admin' }, params: { userId: 'not-an-id' }, query: {},
  });
  assert.equal(res.status, 400);
});

test('feed: still refuses someone else\'s mailbox', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  const res = await feed(me, ada);
  assert.equal(res.status, 403);
});
```

- [ ] **Step 2: Run and confirm it fails**

```
node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit test/chatReadFilters.test.js
```
Expected: FAIL. In the thread and feed `deletedFor` tests, 'hidden…' is present. The blocked, deleted-conversation and admin-view feed tests return extra rows.
The non-ObjectId test gets a 500 (CastError). The legacy, moderation-thread, group and 403 tests pass.

- [ ] **Step 3: Implement**

`getConversation`: insert right after line 825 (`const receiverObjId = new mongoose.Types.ObjectId(receiverId);`):
```js
    // "Delete for me" pushes the viewer onto deletedFor. Filtering only
    // isDeleted brought those messages back on the next load. $ne on an array
    // matches rows whose array lacks the id AND rows with no deletedFor at all
    // (legacy). An admin reading for moderation is never on a thread's
    // deletedFor, so they still see everything.
    const viewerObjId = new mongoose.Types.ObjectId(String(req.user._id));
```
Then in **both** the `Message.countDocuments({...})` (line 852) and the `Message.find({...})` (line 861) filters, change
```js
        isDeleted: { $ne: true }
      }
```
to
```js
        isDeleted: { $ne: true },
        deletedFor: { $ne: viewerObjId }
      }
```
(Leave the unused `baseQuery` at line 820 alone.)

`getUserMessages`: replace lines 230-233:
```js
    const query = {
      $or: [{ sender: userId }, { receiver: userId }],
      isDeleted: { $ne: true }
    };
```
with:
```js
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return next(new ErrorResponse('Invalid user id', 400));
    }
    // The MAILBOX OWNER's view, also when an admin reads it.
    const ownerObjId = new mongoose.Types.ObjectId(userId);

    // Partners whose messages never reach this feed: anyone blocked in either
    // direction, and anyone whose conversation the owner deleted. The live web
    // merges this feed into its chat list, so without this a deleted chat
    // reappeared there and blocked people stayed listed. A partner who writes
    // again pulls the owner out of deletedBy (updateConversation), which
    // brings the chat back, the same rule GET /conversations follows.
    const [blockedIds, conversationRows] = await Promise.all([
      getBlockedUserIds(userId),
      Conversation.find({
        participants: ownerObjId,
        roomType: { $nin: ['hub', 'topic'] }
      })
        .select('_id participants deletedBy')
        .sort({ lastMessageAt: -1 }) // newest row wins for a duplicated pair
        .lean()
    ]);
    const { byPartner } = buildConversationIndex(conversationRows, userId);
    const deletedPartnerIds = [];
    for (const [partnerId, state] of byPartner) {
      if (state.isDeleted) deletedPartnerIds.push(partnerId);
    }
    const hiddenPartnerIds = [...new Set([...blockedIds.map(String), ...deletedPartnerIds])]
      .map((id) => new mongoose.Types.ObjectId(id));

    const query = {
      $or: [{ sender: ownerObjId }, { receiver: ownerObjId }],
      isDeleted: { $ne: true },
      deletedFor: { $ne: ownerObjId }
    };
    if (hiddenPartnerIds.length > 0) {
      // Every row has the owner on one side, so excluding these ids on both
      // sides excludes exactly the conversations with them. A group message
      // with no receiver still matches ($nin matches a missing field).
      query.sender = { $nin: hiddenPartnerIds };
      query.receiver = { $nin: hiddenPartnerIds };
    }
```
(`Conversation`, `mongoose`, `getBlockedUserIds` and `buildConversationIndex` are already imported at the top of the file.)

- [ ] **Step 4: Run → PASS.** Then `... test/chatHistory.test.js test/messageListScope.test.js test/chatListSenders.test.js test/chatListJoin.test.js` → PASS.

- [ ] **Step 5: Commit** (tick the thread / `/messages/user/:id` line)

```
git add controllers/messages.js test/chatReadFilters.test.js docs/REMAINING_WORK.md
git commit -m "fix(chat): delete-for-me sticks; the raw feed drops blocked and deleted chats" -m "The thread and GET /messages/user/:id filtered only isDeleted, so a message deleted for me came back on reload. The feed, which the live web merges into its chat list, also ignored blocks and deleted conversations. Both now exclude deletedFor; the feed also excludes partners blocked either way and conversations the owner deleted. The thread keeps the history of deleted/blocked chats on purpose (no deletion timestamp; the sender stays in deletedBy after resuming).

Still open (Phase 1 item 3): real socket unread count, populated wave/story_share senders, edit content alias, lastMessage media.type; thread history of deleted chats needs a per-user deletedAt; owner purge of legacy 'Conversation started' rows."
```

---

### Task P1-CHAT-4: Socket `newMessage.unreadCount` is the real count (chat#11)

`socket/socketHandler.js:1037-1041` (main: `:969-973`) always sends `unreadCount: 1`. Live web stores that as an override
over the server's list count (`UsersList.tsx:332-337, 626-631`), so five unread texts show "1".
`controllers/messages.js:425` (main `:417`) is **not** a bug: it is the `$project` inclusion `unreadCount: 1` of the
aggregated `$sum`, already pinned by `test/chatListSenders.test.js:92` (expects 2). Leave it.

Design: read the count from the Conversation that `updateConversation` has just incremented. That is the number
`GET /conversations` reports, which the web list sits on top of. It needs **no extra query**: `test/socketSendPath.test.js`
deliberately forbids `Message.countDocuments` on this hot path, and a `{receiver, sender, read:false}` count scans the pair's history.
Cost: the receiver's `newMessage` now goes out after the conversation update (one find + one save) and not before it.
The sender's ack is untouched.

**Files:**
- Create: `lib/conversationUnread.js` (pure `unreadCountFor`)
- Modify: `socket/socketHandler.js` import block (after line 33), and `:1033-1072` (reorder: conversation update, then emit)
- Test: `test/socketUnreadCount.test.js` (new)

**Interfaces:**
- Produces: `unreadCountFor(conversation, userId, fallback = 1) -> number`. `newMessage` payload `{message, unreadCount:<real>, senderId}`.
  The offline queue stores the same payload, so a queued message carries the count as of its send.
- App: `chat_socket_service.dart:394` passes the payload through; no app code reads `unreadCount` off `newMessage`
  (`grep -rn "\['unreadCount'\]" lib` shows only REST models). No app impact.

- [ ] **Step 1: Write the failing test** `test/socketUnreadCount.test.js`

```js
'use strict';
/**
 * The receiver's newMessage carries their real unread count.
 *
 * The socket send path hard-coded unreadCount: 1. The web stores that number
 * as an override over the list's own count, so five unread texts from an app
 * user showed "1". The REST path always sent the real number.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, User, Message, Conversation, initializeSocket, unreadCountFor;

/**
 * Drive initializeSocket() with a fake io that records room emits. Rooms in
 * `liveRooms` report one connected socket, so sendMessageWithRetry treats that
 * receiver as online and emits instead of queueing.
 */
const connectSocket = async (userId, liveRooms = new Set()) => {
  const emits = [];
  let connectionHandler;
  const io = {
    use: () => {},
    on: (event, fn) => { if (event === 'connection') connectionHandler = fn; },
    to: (room) => ({ emit: (event, payload) => emits.push({ room, event, payload }) }),
    in: (room) => ({
      emit: () => {},
      fetchSockets: async () => (liveRooms.has(room) ? [{ id: `live-${room}` }] : []),
    }),
    sockets: { sockets: new Map(), adapter: { rooms: new Map() } },
    emit: () => {},
  };
  initializeSocket(io);
  const handlers = new Map();
  const socket = {
    id: `sock-${userId}-${Math.random()}`,
    user: { id: String(userId) },
    deviceId: `dev-${userId}`,
    handshake: { auth: {}, query: {}, headers: {} },
    rooms: new Set(),
    on: (event, fn) => handlers.set(event, fn),
    emit: () => {},
    join: () => {},
    leave: () => {},
    to: () => ({ emit: () => {} }),
    broadcast: { emit: () => {} },
    disconnect: () => {},
  };
  await connectionHandler(socket);
  return { handlers, emits };
};

const send = (handlers, data) => new Promise((resolve) => {
  handlers.get('sendMessage')(data, resolve);
});
const settle = () => new Promise((r) => setTimeout(r, 500));

const realLog = console.log;
const realError = console.error;
const realWarn = console.warn;

test.before(async () => {
  console.log = () => {};
  console.error = () => {};
  console.warn = () => {};
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'socketUnreadCount' });
  User = require('../models/User');
  Message = require('../models/Message');
  Conversation = require('../models/Conversation');
  ({ initializeSocket } = require('../socket/socketHandler'));
  ({ unreadCountFor } = require('../lib/conversationUnread'));
});
test.after(async () => {
  await new Promise((r) => setTimeout(r, 3000));
  await mongoose.disconnect();
  await mongod.stop();
  console.log = realLog;
  console.error = realError;
  console.warn = realWarn;
});

const makeUser = (name) => User.create({
  name, email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder', birth_year: '2000', birth_month: '1',
  birth_day: '1', gender: 'other', native_language: 'English', language_to_learn: 'Korean',
});

test('unreadCountFor: row for the user, populated user, missing row, no conversation', () => {
  const u = new mongoose.Types.ObjectId();
  const other = new mongoose.Types.ObjectId();
  assert.equal(unreadCountFor({ unreadCount: [{ user: other, count: 9 }, { user: u, count: 4 }] }, u), 4);
  assert.equal(unreadCountFor({ unreadCount: [{ user: { _id: u }, count: 2 }] }, String(u)), 2);
  assert.equal(unreadCountFor({ unreadCount: [{ user: other, count: 9 }] }, u), 1);
  assert.equal(unreadCountFor(null, u), 1);
  assert.equal(unreadCountFor(undefined, u, 0), 0);
});

test('three unread texts arrive as 1, 2, 3 — not 1, 1, 1', async () => {
  const ada = await makeUser('unr-ada');
  const bob = await makeUser('unr-bob');
  await Message.create({ sender: bob._id, receiver: ada._id, message: 'hi', read: true });

  await connectSocket(bob._id); // bob is online
  const { handlers, emits } = await connectSocket(ada._id, new Set([`user_${bob._id}`]));

  for (const text of ['one', 'two', 'three']) {
    const ack = await send(handlers, { receiver: String(bob._id), message: text });
    assert.equal(ack.status, 'success');
    await settle();
  }

  const counts = emits
    .filter((e) => e.event === 'newMessage' && e.room === `user_${bob._id}`)
    .map((e) => e.payload.unreadCount);
  assert.deepEqual(counts, [1, 2, 3]);
});

test('an existing unread backlog is reflected (4 unread + 1 = 5)', async () => {
  const ada = await makeUser('unr2-ada');
  const bob = await makeUser('unr2-bob');
  await Message.create({ sender: bob._id, receiver: ada._id, message: 'hi', read: true });
  await Conversation.create({
    participants: [ada._id, bob._id], isGroup: false,
    unreadCount: [{ user: bob._id, count: 4 }],
  });

  await connectSocket(bob._id);
  const { handlers, emits } = await connectSocket(ada._id, new Set([`user_${bob._id}`]));
  const ack = await send(handlers, { receiver: String(bob._id), message: 'five' });
  assert.equal(ack.status, 'success');
  await settle();

  const toBob = emits.find((e) => e.event === 'newMessage' && e.room === `user_${bob._id}`);
  assert.ok(toBob, 'newMessage reached bob');
  assert.equal(toBob.payload.unreadCount, 5);
  assert.equal(toBob.payload.message.message, 'five');
  assert.equal(String(toBob.payload.senderId), String(ada._id));
});

test('messageSent still reaches the sender account with unreadCount 0', async () => {
  const ada = await makeUser('unr3-ada');
  const bob = await makeUser('unr3-bob');
  await Message.create({ sender: bob._id, receiver: ada._id, message: 'hi', read: true });

  const { handlers, emits } = await connectSocket(ada._id);
  await send(handlers, { receiver: String(bob._id), message: 'x' });
  await settle();

  const sent = emits.filter((e) => e.event === 'messageSent' && e.room === `user_${ada._id}`);
  assert.equal(sent.length, 1);
  assert.equal(sent[0].payload.unreadCount, 0);
});
```

- [ ] **Step 2: Run and confirm it fails**

```
node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit test/socketUnreadCount.test.js
```
Expected: FAIL. `test.before` throws `Cannot find module '../lib/conversationUnread'`, so every test fails. (With only the lib created,
the socket tests would get `[1, 1, 1]` and `1 !== 5`.)

- [ ] **Step 3: Implement**

Create `lib/conversationUnread.js`:
```js
'use strict';

/**
 * A participant's unread count on a Conversation document.
 *
 * Conversation.unreadCount is [{ user, count }]. `user` is a bare ObjectId on
 * every write path, but a populated read hands back { _id, ... }, so both are
 * accepted. `fallback` is for a missing conversation or row: the socket send
 * path calls this right after delivering a message, so "at least 1" is the
 * honest answer when the conversation update failed.
 */
function unreadCountFor(conversation, userId, fallback = 1) {
  if (!conversation || !Array.isArray(conversation.unreadCount)) return fallback;
  const target = String(userId);
  const row = conversation.unreadCount.find((u) => {
    if (!u || !u.user) return false;
    const id = u.user._id ? u.user._id : u.user;
    return String(id) === target;
  });
  return row && typeof row.count === 'number' ? row.count : fallback;
}

module.exports = { unreadCountFor };
```

`socket/socketHandler.js`: after line 33 (`const { consumeMessageAllowance } = require('../lib/messageAllowance');`) add:
```js
const { unreadCountFor } = require('../lib/conversationUnread');
```

Replace lines 1034-1072, from `// Send to receiver` through the end of the `const conversationUpdatePromise = ... });` statement:
```js
          // Send to receiver
          const messagePayload = {
            message: populatedMessage,
            unreadCount: 1,
            senderId: userId
          };

          const sent = await sendMessageWithRetry(io, receiver, 'newMessage', messagePayload);

          if (!sent) {
            queueOfflineMessage(receiver, messagePayload);
          }

          // Every socket signed in as the sender, ...
          // ... (comment block unchanged) ...
          io.to(`user_${userId}`).emit('messageSent', {
            message: populatedMessage,
            unreadCount: 0,
            receiverId: receiver
          });

          // Update conversation (non-blocking). Keep the promise so the
          // ... (comment unchanged) ...
          const conversationUpdatePromise = updateConversation(userId, receiver, newMessage._id)
            .catch(err => {
              console.error('Background update error:', err.message);
              return null;
            });
```
with:
```js
          // Update the conversation FIRST. Its per-user unreadCount, just
          // incremented for the receiver, is the number newMessage carries.
          // This used to be a literal 1, and the web keeps the payload's
          // number as an override over its list count, so five unread texts
          // showed "1". It is also the number GET /conversations reports, and
          // costs no extra query (a Message count here would scan the pair's
          // history on every send — see socketSendPath.test.js). Keep the
          // promise: the quota charge and messageDelivered below reuse it
          // rather than racing a second find/create.
          const conversationUpdatePromise = updateConversation(userId, receiver, newMessage._id)
            .catch(err => {
              console.error('Background update error:', err.message);
              return null;
            });
          const updatedConversation = await conversationUpdatePromise;

          // Send to receiver
          const messagePayload = {
            message: populatedMessage,
            unreadCount: unreadCountFor(updatedConversation, receiver),
            senderId: userId
          };

          const sent = await sendMessageWithRetry(io, receiver, 'newMessage', messagePayload);

          if (!sent) {
            queueOfflineMessage(receiver, messagePayload);
          }

          // Every socket signed in as the sender, INCLUDING the one that
          // sent this. `socket.to(room)` excludes the emitting socket, so the
          // sender's other devices got their conversation list refreshed live
          // and the window the message was typed in did not — it kept the
          // previous last message and the previous row order until something
          // else happened to refetch. `io.to(room)` is the same room without
          // that exclusion, and is what messageDelivered below already uses.
          io.to(`user_${userId}`).emit('messageSent', {
            message: populatedMessage,
            unreadCount: 0,
            receiverId: receiver
          });
```
Everything after that (the `if (startsNewConversation)` charge, the `if (sent)` delivered block, push) stays as it is and keeps using
`conversationUpdatePromise`. `updateConversation` swallows its own errors and returns `undefined`, and `unreadCountFor(undefined)` gives 1,
so a failed update degrades to today's value.

- [ ] **Step 4: Run → PASS.** Then `... test/socketSendPath.test.js test/chatMessageSentEcho.test.js test/socketConversationCap.test.js test/chatUnreadReset.test.js test/conversationRead.test.js test/socketBlockCheck.test.js` → PASS.

- [ ] **Step 5: Commit** (tick the socket unread line)

```
git add lib/conversationUnread.js socket/socketHandler.js test/socketUnreadCount.test.js docs/REMAINING_WORK.md
git commit -m "fix(chat): socket newMessage carries the real unread count" -m "The socket send path hard-coded unreadCount: 1, and the web keeps that number over its list count, so five unread texts showed '1'. The conversation is now updated before the receiver's emit and its per-user count is sent: the same number GET /conversations reports, with no extra query. messages.js:417 (getUserSenders) was already real; it is a \$project inclusion.

Still open (Phase 1 item 3): populated wave/story_share senders, edit content alias, lastMessage media.type; thread history of deleted chats; owner purge of legacy 'Conversation started' rows."
```

---

### Task P1-CHAT-5: Wave mirror and `story_share` messages populate `sender`/`receiver` like normal messages (chat#8)

Both emit a freshly created, **unpopulated** Message. `sender` is a bare ObjectId, so live web's `msg.sender._id === userId`
is false for the web user's own wave: the bubble lands on the wrong side with a broken avatar until reload. The app's
`Message.fromJson` already handles populated senders (every other emit), so populating is safe for 2.6.1.

**Files:**
- Modify: `lib/waveMirror.js:25-44` (populate before the two emits)
- Modify: `controllers/stories.js:1473-1496` (`shareStory` DM branch: populate before emit)
- Test: `test/chatSenderPopulated.test.js` (new)

**Interfaces:**
- Produces: `newMessage` / `messageSent` payload `message.sender` and `message.receiver` are objects
  `{_id, name, ...}`. Select strings match their neighbours: `lib/waveMirror.js` uses the REST `createMessage` set
  (`name username images userMode privacySettings.showGiftingLevel`), and `stories.js` uses the set its other DM emits use
  (`name images userMode privacySettings.showGiftingLevel`, `stories.js:1034-1035`). Every other payload field is unchanged
  (`senderId`, `sharedStory`, unread counts).
- Callers: `mirrorWaveToChat` from `controllers/community.js:340` (`fromUserId = req.user.id`, a string) and
  `lib/welcomeWave.js:100` (an ObjectId). Both shapes are tested.

- [ ] **Step 1: Write the failing test** `test/chatSenderPopulated.test.js`

```js
'use strict';
/**
 * Wave and story-share chat messages reach clients with a populated sender.
 *
 * Both emitted the raw created document, whose sender is a bare ObjectId. The
 * web decides "mine or theirs" by msg.sender._id, so a wave the web user sent
 * rendered as a RECEIVED bubble with a broken avatar until reload.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, User, Story, Message, mirrorWaveToChat, stories;

const recordingIo = () => {
  const emits = [];
  return { emits, io: { to: (room) => ({ emit: (event, payload) => emits.push({ room, event, payload }) }) } };
};

// Mongoose documents and plain objects both expose the populated sender.
const plain = (m) => (m && typeof m.toObject === 'function' ? m.toObject() : m);

test.before(async () => {
  console.log = () => {};
  console.error = () => {};
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'chatSenderPopulated' });
  User = require('../models/User');
  Story = require('../models/Story');
  Message = require('../models/Message');
  ({ mirrorWaveToChat } = require('../lib/waveMirror'));
  stories = require('../controllers/stories');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });

const makeUser = (name) => User.create({
  name, email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder', birth_year: '2000', birth_month: '1',
  birth_day: '1', gender: 'other', native_language: 'English', language_to_learn: 'Korean',
});

const assertPopulatedParties = (message, sender, receiver) => {
  const m = plain(message);
  assert.equal(typeof m.sender, 'object', 'sender is an object, not a bare id');
  assert.equal(String(m.sender._id), String(sender._id));
  assert.equal(m.sender.name, sender.name);
  assert.equal(String(m.receiver._id), String(receiver._id));
  assert.equal(m.receiver.name, receiver.name);
  assert.equal(m.sender.password, undefined, 'only the public selection');
  assert.equal(m.sender.email, undefined);
};

for (const shape of ['ObjectId (welcomeWave)', 'string (community.sendWave)']) {
  test(`wave mirror populates sender and receiver — fromUserId as ${shape}`, async () => {
    const ada = await makeUser(`wave-ada-${shape.length}`);
    const bob = await makeUser(`wave-bob-${shape.length}`);
    const { io, emits } = recordingIo();
    const asId = (u) => (shape.startsWith('string') ? String(u._id) : u._id);

    await mirrorWaveToChat({ fromUserId: asId(ada), toUserId: asId(bob), message: 'hello there', io });

    const toBob = emits.find((e) => e.event === 'newMessage' && e.room === `user_${bob._id}`);
    const toAda = emits.find((e) => e.event === 'messageSent' && e.room === `user_${ada._id}`);
    assert.ok(toBob && toAda, 'both emits went out');
    assertPopulatedParties(toBob.payload.message, ada, bob);
    assertPopulatedParties(toAda.payload.message, ada, bob);
    assert.equal(String(toBob.payload.senderId), String(ada._id));
    assert.equal(plain(toBob.payload.message).messageType, 'sticker');
  });
}

test('wave mirror without io still stores the message (no populate needed)', async () => {
  const ada = await makeUser('wave-noio-ada');
  const bob = await makeUser('wave-noio-bob');
  await mirrorWaveToChat({ fromUserId: ada._id, toUserId: bob._id, message: undefined, io: null });
  const stored = await Message.findOne({ sender: ada._id, receiver: bob._id }).lean();
  assert.equal(stored.message, '👋');
});

test('story share to DM emits newMessage with a populated sender', async () => {
  const owner = await makeUser('share-owner');
  const friend = await makeUser('share-friend');
  const story = await Story.create({
    user: owner._id, text: 'share me', mediaType: 'text', privacy: 'public',
  });
  const { io, emits } = recordingIo();

  const result = await new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      status(c) { this.statusCode = c; return this; },
      json(body) { resolve({ status: this.statusCode, body }); },
    };
    stories.shareStory({
      params: { id: String(story._id) },
      user: { ...owner.toObject(), id: String(owner._id), _id: owner._id },
      body: { sharedTo: 'dm', receiverId: String(friend._id) },
      query: {},
      app: { get: (k) => (k === 'io' ? io : null) },
    }, res, (err) => (err ? resolve({ status: err.statusCode || 500, error: err.message }) : resolve({ status: 204 })))
      .catch(reject);
  });

  assert.equal(result.status, 200, JSON.stringify(result));
  const toFriend = emits.find((e) => e.event === 'newMessage' && e.room === `user_${friend._id}`);
  assert.ok(toFriend, 'newMessage reached the receiver');
  assertPopulatedParties(toFriend.payload.message, owner, friend);
  assert.equal(plain(toFriend.payload.message).messageType, 'story_share');
  assert.equal(String(plain(toFriend.payload.message).storyReference.storyId), String(story._id));
  assert.equal(String(toFriend.payload.sharedStory._id), String(story._id), 'sharedStory unchanged');
});
```

- [ ] **Step 2: Run and confirm it fails**

```
node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit test/chatSenderPopulated.test.js
```
Expected: FAIL. In the wave tests and the story test, `typeof` passes (an ObjectId is an object), and the failure is
`m.sender.name`: `undefined` !== the user's name. The no-io test passes.

- [ ] **Step 3: Implement**

`lib/waveMirror.js`: insert at the top of the `if (io) {` block (before the `Promise.all` of unread counts):
```js
      // Same parties every other chat emit carries. The raw document's
      // sender is a bare ObjectId, and the web decides "mine or theirs" by
      // msg.sender._id, so the sender's own wave rendered as received, with
      // no avatar, until reload. Only when someone is listening: the stored
      // row needs no populate.
      await chatMsg.populate([
        { path: 'sender', select: 'name username images userMode privacySettings.showGiftingLevel' },
        { path: 'receiver', select: 'name username images userMode privacySettings.showGiftingLevel' },
      ]);
```
(The emits keep using `fromUserId.toString()` / `toUserId.toString()` from the arguments, not `chatMsg.sender`, so populating
does not change any room name or id field.)

`controllers/stories.js`: in `shareStory`, directly after the `const dmMessage = await Message.create({...});` statement
(it ends at line 1484), insert:
```js
      // Populated like every other DM emit in this file (see replyToStory):
      // a bare-ObjectId sender put the sharer's own bubble on the wrong side
      // on web.
      await dmMessage.populate('sender', 'name images userMode privacySettings.showGiftingLevel');
      await dmMessage.populate('receiver', 'name images userMode privacySettings.showGiftingLevel');
```

- [ ] **Step 4: Run → PASS.** Then `... test/welcomeWave.test.js test/storyPrivacyAccess.test.js test/storyAudit.test.js test/waveLimit.test.js` → PASS.

- [ ] **Step 5: Commit** (tick the wave / story_share line)

```
git add lib/waveMirror.js controllers/stories.js test/chatSenderPopulated.test.js docs/REMAINING_WORK.md
git commit -m "fix(chat): wave and story-share messages emit a populated sender" -m "Both emitted the raw created message, sender a bare ObjectId; the web picks the bubble side by msg.sender._id, so the sender's own wave or story share showed as received with no avatar until reload. Both now populate sender and receiver like every other chat emit.

Still open (Phase 1 item 3): edit content alias, lastMessage media.type; wave/story_share messages still don't create a Conversation row (missing from GET /conversations); thread history of deleted chats; owner purge of legacy 'Conversation started' rows."
```

---

### Task P1-CHAT-6: `PUT /messages/:id` accepts `content` as an alias of `message` (chat#1)

Live web sends `PUT /messages/:id {content}` (`chatSlice.ts:245-252`). The validator (`validators/messageValidator.js:94-101`) and
the controller (`controllers/messageManagement.js:14-18`) require `message`, so every web edit gets a 400. The app sends `{message}`.
Phase 3 web will send `{message}`. Both must work.

**Files:**
- Modify: `validators/messageValidator.js:91-101` (`editMessageValidation`: alias sanitizer before the rule)
- Modify: `controllers/messageManagement.js:12-23` (`editMessage`: read `message ?? content`, type-guard)
- Test: `test/messageEditContentAlias.test.js` (new)

**Interfaces:**
- Consumes: body `{message}` (app, Phase 3 web) or `{content}` (live web). A non-blank `message` wins over `content`.
- Produces: unchanged response and `messageEdited` socket events. A body with neither (or a non-string) → 400 'Message content is required' (unchanged text).
- Express-validator 7.3: verified locally that a `customSanitizer` on a missing `message` writes `req.body.message`, and that the next
  chain on the same field sees it (`{content:' hi '}` → `req.body.message === 'hi'`, no errors).

- [ ] **Step 1: Write the failing test** `test/messageEditContentAlias.test.js`

```js
'use strict';
/**
 * PUT /messages/:id — the web sent { content }, the app sends { message }.
 *
 * Validator and controller both required `message`, so every edit from the
 * live web returned 400 and the web only logged it: edits silently did
 * nothing. `content` is now an alias; a non-blank `message` wins.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const { validationResult } = require('express-validator');
const { editMessageValidation } = require('../validators/messageValidator');

let mongod, Message, User, controller;

const runChains = async (body) => {
  const req = {
    body, query: {}, params: { id: new mongoose.Types.ObjectId().toString() }, cookies: {}, headers: {},
  };
  for (const chain of editMessageValidation) {
    await chain.run(req);
  }
  return { req, errors: validationResult(req).array().map((e) => e.msg) };
};

const run = (fn, req, emits) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  const io = { to: (room) => ({ emit: (event, payload) => emits.push({ room, event, payload }) }) };
  req.app = { get: (k) => (k === 'io' ? io : null) };
  fn(req, res, (err) => (err
    ? resolve({ status: err.statusCode || 500, error: err.message })
    : resolve({ status: 204 })))
    .catch(reject);
});

test.before(async () => {
  console.log = () => {};
  console.error = () => {};
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'msgEditAlias' });
  Message = require('../models/Message');
  User = require('../models/User');
  controller = require('../controllers/messageManagement');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });

const makeUser = (name) => User.create({
  name, email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder', birth_year: '2000', birth_month: '1',
  birth_day: '1', gender: 'other', native_language: 'English', language_to_learn: 'Korean',
});

// ------------------------------------------------------------- validator

test('validator: { content } passes and lands on req.body.message (trimmed)', async () => {
  const { req, errors } = await runChains({ content: '  fixed typo  ' });
  assert.deepEqual(errors, []);
  assert.equal(req.body.message, 'fixed typo');
});

test('validator: { message } still passes unchanged', async () => {
  const { req, errors } = await runChains({ message: 'app edit' });
  assert.deepEqual(errors, []);
  assert.equal(req.body.message, 'app edit');
});

test('validator: a non-blank message wins over content', async () => {
  const { req } = await runChains({ message: 'from message', content: 'from content' });
  assert.equal(req.body.message, 'from message');
});

test('validator: a blank message falls back to content', async () => {
  const { req, errors } = await runChains({ message: '', content: 'from content' });
  assert.deepEqual(errors, []);
  assert.equal(req.body.message, 'from content');
});

test('validator: neither field, or a non-string content, is still refused', async () => {
  assert.ok((await runChains({})).errors.includes('Message content is required'));
  assert.ok((await runChains({ content: 5 })).errors.length > 0);
});

test('validator: content over 2000 characters is refused like message', async () => {
  const { errors } = await runChains({ content: 'x'.repeat(2001) });
  assert.ok(errors.includes('Message cannot exceed 2000 characters'));
});

// ------------------------------------------------------------ controller

test('controller: { content } edits the message and tells the receiver', async () => {
  const me = await makeUser('edit-me');
  const ada = await makeUser('edit-ada');
  const msg = await Message.create({ sender: me._id, receiver: ada._id, message: 'teh' });
  const emits = [];

  const res = await run(controller.editMessage, {
    user: me, params: { id: String(msg._id) }, body: { content: 'the' },
  }, emits);

  assert.equal(res.status, 200, JSON.stringify(res));
  const stored = await Message.findById(msg._id).lean();
  assert.equal(stored.message, 'the');
  assert.equal(stored.isEdited, true);
  assert.ok(emits.some((e) => e.room === `user_${ada._id}` && e.event === 'messageEdited'));
});

test('controller: { message } still works (app)', async () => {
  const me = await makeUser('edit2-me');
  const ada = await makeUser('edit2-ada');
  const msg = await Message.create({ sender: me._id, receiver: ada._id, message: 'a' });
  const res = await run(controller.editMessage, {
    user: me, params: { id: String(msg._id) }, body: { message: 'b' },
  }, []);
  assert.equal(res.status, 200);
  assert.equal((await Message.findById(msg._id).lean()).message, 'b');
});

test('controller: no text at all, or a non-string, is a 400 not a TypeError', async () => {
  const me = await makeUser('edit3-me');
  const ada = await makeUser('edit3-ada');
  const msg = await Message.create({ sender: me._id, receiver: ada._id, message: 'a' });
  for (const body of [{}, { content: 42 }, { message: { $gt: '' } }]) {
    const res = await run(controller.editMessage, { user: me, params: { id: String(msg._id) }, body }, []);
    assert.equal(res.status, 400, JSON.stringify(body));
    assert.equal(res.error, 'Message content is required');
  }
});
```

- [ ] **Step 2: Run and confirm it fails**

```
node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit test/messageEditContentAlias.test.js
```
Expected: FAIL. In the validator tests, `{content}` and blank-message→content give 'Message content is required'. The controller `{content}` test gets 400.
In the non-string controller test, `{message:{$gt:''}}` throws `message.trim is not a function` (500). The 2001-char test also fails, because
without the alias the error is 'Message content is required' and not the length message. The `{message}`, message-wins and neither-field tests pass.

- [ ] **Step 3: Implement**

`validators/messageValidator.js`, replace `exports.editMessageValidation` (lines 91-101, doc comment included) with:
```js
/**
 * Validation rules for editing a message
 *
 * `content` is an alias of `message`. The live web sent PUT { content } while
 * this required `message`, so every web edit was a 400. A non-blank `message`
 * wins; otherwise a string `content` is copied into `message` here, so the
 * rule below and the controller only ever read `message`.
 */
exports.editMessageValidation = [
  param('id')
    .isMongoId().withMessage('Invalid message ID'),

  body('message').customSanitizer((value, { req }) => {
    if (typeof value === 'string' && value.trim().length > 0) return value;
    const content = req.body && req.body.content;
    return typeof content === 'string' ? content : value;
  }),

  body('message')
    .notEmpty().withMessage('Message content is required')
    .isString().withMessage('Message must be a string')
    .isLength({ max: 2000 }).withMessage('Message cannot exceed 2000 characters')
    .trim(),
];
```

`controllers/messageManagement.js`, replace lines 13-19:
```js
  const { id } = req.params;
  const { message } = req.body;
  const userId = req.user._id;

  if (!message || message.trim().length === 0) {
    return next(new ErrorResponse('Message content is required', 400));
  }
```
with:
```js
  const { id } = req.params;
  const body = req.body || {};
  // `content` is the live web's name for the same field. The route's
  // validator already copies it into `message`; this repeats the rule for
  // any caller that reaches the handler without that validator.
  const message = typeof body.message === 'string' && body.message.trim().length > 0
    ? body.message
    : body.content;
  const userId = req.user._id;

  if (typeof message !== 'string' || message.trim().length === 0) {
    return next(new ErrorResponse('Message content is required', 400));
  }
```

- [ ] **Step 4: Run → PASS.**

- [ ] **Step 5: Commit** (tick the edit-alias line)

```
git add validators/messageValidator.js controllers/messageManagement.js test/messageEditContentAlias.test.js docs/REMAINING_WORK.md
git commit -m "fix(chat): message edit accepts content as well as message" -m "The live web edits with PUT /messages/:id {content}; validator and controller required message, so every web edit was a silent 400. content is now an alias (a non-blank message wins), so the live web, Phase 3 web and the app all work. Non-string bodies are a 400, not a TypeError.

Still open (Phase 1 item 3): lastMessage media.type; wave/story_share Conversation rows; thread history of deleted chats; owner purge of legacy 'Conversation started' rows."
```

---

### Task P1-CHAT-7: `GET /conversations` `lastMessage` includes `media.type` (chat#10)

`controllers/conversations.js:31` populates `lastMessage` with `'message messageType createdAt sender'`. Photo, voice and call last messages
have an empty `message`, so list previews are blank. Phase 3 web builds its list from `/conversations` only and maps `media.type`
to "Photo/Voice/Call". `GET /conversations/:id` (`:92-99`) gets the same field so the two views agree.

**Files:**
- Modify: `controllers/conversations.js:31`, `:94`
- Test: `test/conversationListPreview.test.js` (new)

**Interfaces:**
- Produces: `data[].lastMessage.media = { type }` when the last message has media. The key is absent otherwise (lean + projection,
  no defaults). Additive: no field is removed. App 2.6.1 does not read this endpoint for previews (`getUserSenders`), and
  live web ignores unknown keys.

- [ ] **Step 1: Write the failing test** `test/conversationListPreview.test.js`

```js
'use strict';
/**
 * GET /conversations — the list the Phase 3 web builds its sidebar from.
 *
 * lastMessage was populated without media, and photo / voice / call messages
 * have an empty `message`, so their previews were blank. media.type is what a
 * client needs to say "Photo", "Voice message" or "Call".
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, Message, User, Conversation, controller;

const asHandler = (fn) => (req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  fn(req, res, (err) => (err
    ? resolve({ status: err.statusCode || 500, error: err.message })
    : resolve({ status: 204 })))
    .catch(reject);
});

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'convListPreview' });
  Message = require('../models/Message');
  User = require('../models/User');
  Conversation = require('../models/Conversation');
  controller = require('../controllers/conversations');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([Message.deleteMany({}), User.deleteMany({}), Conversation.deleteMany({})]);
});

const makeUser = (name) => User.create({
  name, email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder', birth_year: '2000', birth_month: '1',
  birth_day: '1', gender: 'other', native_language: 'English', language_to_learn: 'Korean',
});

const conversationWith = async (me, other, lastMessage) => Conversation.create({
  participants: [me._id, other._id], isGroup: false,
  lastMessage: lastMessage._id, lastMessageAt: new Date(),
});

const list = (me) => asHandler(controller.getConversations)({ user: me, query: {} });

test('a call last message carries media.type "call"', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  const call = await Message.create({
    sender: ada._id, receiver: me._id, messageType: 'call',
    media: { type: 'call', callData: { callId: `c-${new mongoose.Types.ObjectId()}`, callType: 'audio', status: 'missed' } },
  });
  await conversationWith(me, ada, call);

  const res = await list(me);
  assert.equal(res.status, 200);
  assert.equal(res.body.data[0].lastMessage.media.type, 'call');
  assert.equal(res.body.data[0].lastMessage.messageType, 'call');
});

test('photo and voice last messages carry their media.type; the url is not added', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  const bob = await makeUser('bob');
  const photo = await Message.create({
    sender: ada._id, receiver: me._id, messageType: 'media',
    media: { type: 'image', url: 'https://cdn.example.com/p.jpg' },
  });
  const voice = await Message.create({
    sender: bob._id, receiver: me._id, messageType: 'voice',
    media: { type: 'voice', url: 'https://cdn.example.com/v.m4a', duration: 3 },
  });
  await conversationWith(me, ada, photo);
  await conversationWith(me, bob, voice);

  const res = await list(me);
  const byPartner = Object.fromEntries(
    res.body.data.map((c) => [String(c.otherParticipant._id), c.lastMessage])
  );
  assert.equal(byPartner[String(ada._id)].media.type, 'image');
  assert.equal(byPartner[String(bob._id)].media.type, 'voice');
  assert.equal(byPartner[String(ada._id)].media.url, undefined, 'list stays lean: type only');
});

test('a text last message is unchanged (text present, no media key needed)', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  const text = await Message.create({ sender: ada._id, receiver: me._id, message: 'hey' });
  await conversationWith(me, ada, text);

  const res = await list(me);
  assert.equal(res.body.data[0].lastMessage.message, 'hey');
  assert.ok(!res.body.data[0].lastMessage.media || !res.body.data[0].lastMessage.media.type);
});

test('GET /conversations/:id agrees with the list', async () => {
  const me = await makeUser('me');
  const ada = await makeUser('ada');
  const photo = await Message.create({
    sender: ada._id, receiver: me._id, messageType: 'media',
    media: { type: 'image', url: 'https://cdn.example.com/p.jpg' },
  });
  const conv = await conversationWith(me, ada, photo);

  const res = await asHandler(controller.getConversation)({ user: me, params: { id: String(conv._id) }, query: {} });
  assert.equal(res.status, 200, JSON.stringify(res));
  assert.equal(res.body.data.lastMessage.media.type, 'image');
});
```

- [ ] **Step 2: Run and confirm it fails**

```
node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit test/conversationListPreview.test.js
```
Expected: FAIL. The call, photo/voice and `:id` tests throw `Cannot read properties of undefined (reading 'type')`. The text test passes.
(`getConversation` responds `{success, data:{...conversation, otherParticipant, unreadCount}}`, `conversations.js:126-133`, so
`data.lastMessage` is the right path.)

- [ ] **Step 3: Implement** — `controllers/conversations.js`

Line 31:
```js
      .populate('lastMessage', 'message messageType createdAt sender') // Only needed fields
```
→
```js
      // media.type lets a client label photo / voice / call previews, whose
      // `message` is empty. Type only: the list never needs the URL.
      .populate('lastMessage', 'message messageType createdAt sender media.type')
```
Line 94 (inside `getConversation`):
```js
      select: 'message createdAt sender receiver',
```
→
```js
      select: 'message messageType createdAt sender receiver media.type',
```

- [ ] **Step 4: Run → PASS.** Then `... test/conversations.hubExclusion.test.js test/conversationRead.test.js test/callMessages.test.js` → PASS.

- [ ] **Step 5: Commit** (tick the media.type line)

```
git add controllers/conversations.js test/conversationListPreview.test.js docs/REMAINING_WORK.md
git commit -m "fix(chat): conversation list lastMessage includes media.type" -m "Photo, voice and call messages have an empty text, and lastMessage was populated without media, so list previews were blank. GET /conversations and /conversations/:id now include media.type (type only, no URL).

Still open (Phase 1 item 3): wave/story_share messages don't create a Conversation row (missing from GET /conversations); thread history of deleted chats needs a per-user deletedAt; senders list has no block filter (verify); owner purge of legacy 'Conversation started' rows. Phase 1 item 3 code is otherwise done."
```

---

## Phase gate (after Task 7)

- [ ] Full suite on Node 20, or locally with the shim:
  `node --experimental-test-module-mocks --require ./test/helpers/nodeCompat.js --test --test-force-exit --test-concurrency=4 services/*.test.js test/*.test.js`
  The only known local failure is the 12-char `JWT_SECRET` test (memory). Anything else blocks the push.
- [ ] Live-web smoke after deploy (web is unchanged in this phase): web "Message" on a profile opens the chat, and no bubble
  appears on the app side. Web delete-for-everyone removes it on the app. Web edit works. Five app texts show a badge of 5 on web.
  A wave sent from web sits on the right-hand side.
- [ ] Hand to Phase 3 web (chat): build the list from `/conversations` only (it now has `media.type`); send `{message}` on edit and
  `{deleteForEveryone}` in the body; normalise `sender` with `typeof sender === 'string' ? {_id: sender} : sender` for legacy queued
  payloads; increment unread locally (or trust the now-real payload).

# Phase 1 — links, emails, web endpoints (items 6, 7, 8): implementation tasks

Spec: `bt-integration/bananatalk_app/docs/superpowers/specs/2026-10-16-web-app-parity-design.md` (§2, §4, Phase 1 items 6–8).
Audit: `docs/audits/2026-10-16-web-parity/links.md` (#9, #12, #13, #17, #18, #19).

Repos: backend `/Users/davis/Desktop/Personal/be-integration` (main), web `/Users/davis/Desktop/Personal/language_exchange_web_front`,
app `/Users/davis/Desktop/Personal/bt-integration/bananatalk_app`. All paths below are relative to the backend repo unless they say otherwise.

**How this was checked.** Every test and implementation below was run against a scratch copy of `be-integration` @ `232fb49`
(Node 25.5, mongodb-memory-server). Every new test fails on unmodified main for the reason given, and passes after the change.
These suites still pass with all eight changes applied: `og`, `emailCatalogs`, `referrals`, `googleWebhookSender`, `rooms.killSwitch`,
`studyHubConfig`, `conversationCapKillSwitch`, `matchesLayoutKillSwitch`, `appConfigAnnouncements`, `appleAuthTokens`,
all 13 `authAudit.*`, `cookieAuthIntegration`, `schemaIndexRedundancy`.

**Rules for every task**
- Backend `main` auto-deploys, so **commit only**. Phase 1 pushes once, after the full gate. `npm test` crashes under Node ≥ 24 (SlowBuffer), so run test files one at a time. If `jsonwebtoken` throws `reading 'prototype'`, add `--require ./test/helpers/nodeCompat.js`.
- Commits have **no** `Co-Authored-By` and no AI attribution. In the same commit, update `docs/REMAINING_WORK.md` in that repo. Use the section `## 4. Code work — open`, under a heading `### Web parity Phase 1 — links + web endpoints (spec 2026-10-16 items 6–8)`. Create the heading if it isn't there. Tick your item and add any follow-ups. The commit body lists what is still open.
- Order: tasks 1, 2, 3, 4, 5, 7 and 8 are independent. **Task 6 needs Task 4**, because it reads `WEB_APPLE_SIGNIN_ENABLED` from `config/limitations.js`. Tasks 5 and 6 both edit `controllers/auth.js` and `routes/auth.js`. They touch different blocks, but if they run in parallel worktrees, merge one before starting the other.
- Backward compatibility (spec §2): every change adds something. The live web, still on `origin/main`, keeps working. The Google callback still carries `?token=` (Task 5).

---

### Task P1-LINK-1: Email buttons point at real web routes (links#9, links#18)

**Files:**
- Modify `utils/emailTemplates.js`: constants after line 10; welcome lines 120 and 138; `weeklyDigest` line 427; `newFollowerEmail` lines 500–501 and 527; `newMessageEmail` line 548; `correctionReceivedEmail` line 600; `adminReportAlert` lines 1289 and 1299.
- Modify `services/emailService.js` lines 192 and 200 (`sendNewFollowerEmail` passes `followerId` through).
- Test (new): `test/emailWebLinks.test.js`

**Web routes these were checked against** (`language_exchange_web_front/src/router/routes.tsx`):
`communities` (line 193), `profile` (209), `chat/:userId?` (241, a **user id**, not a name), `forgot-password` (192), and `admin/content` with `?tab=reports` (286; `AdminContent.tsx:41,70` reads `tab`). `/explore`, `/messages`, `/messages/new/:name`, `/profile/stats` and `/admin/reports/:id` do not exist.

**Interfaces:**
- `newFollowerEmail(userName, followerName, followerImage, locale = 'en', followerId = null)`. The new trailing parameter is optional, so existing calls are unchanged. A 24-hex `followerId` gives `/chat/<id>` (passed through `encodeURIComponent`). Anything else, such as no id, a name or junk, gives `/chat`. The name never goes into the URL.
- `emailService.sendNewFollowerEmail(user, followerName, followerImage, followerId = null)`.
- Note: nothing calls `sendNewFollowerEmail`, `sendNewMessageEmail` or `sendCorrectionEmail` today (`notificationService.sendNewFollower` only sends a push). The templates are fixed now so the links are right whenever those emails get wired up. That wiring is a follow-up item, not this task.

- [ ] **Step 1: Write the failing test** `test/emailWebLinks.test.js`:
```js
'use strict';
/**
 * links#9, links#18: every banatalk.com link in an email must land on a route
 * the website actually has (language_exchange_web_front src/router/routes.tsx).
 * Unknown paths render NotFound with HTTP 200, and /profile/stats was also
 * claimed by the AASA, so the app opened a profile with the id "stats".
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const templates = require('../utils/emailTemplates');

// Mirror of the web routes an email may point at. Update together with
// routes.tsx; a path missing here fails the test on purpose.
const WEB_ROUTES = [
  /^\/$/,
  /^\/communities$/,
  /^\/chat$/,
  /^\/chat\/[0-9a-f]{24}$/,
  /^\/profile$/,
  /^\/forgot-password$/,
  /^\/admin\/content\?tab=reports$/,
];

const webPaths = (rendered) => {
  const all = `${rendered.html || ''}\n${rendered.text || ''}`;
  const out = [];
  for (const m of all.matchAll(/https:\/\/banatalk\.com([^\s"'<>)]*)/g)) out.push(m[1] || '/');
  return out;
};

const assertAllRoutable = (name, rendered) => {
  const paths = webPaths(rendered);
  assert.ok(paths.length > 0, `${name}: expected at least one banatalk.com link`);
  for (const p of paths) {
    assert.ok(WEB_ROUTES.some((re) => re.test(p)), `${name}: ${p} is not a web route`);
  }
};

const FOLLOWER_ID = '6ad0a9ea0123456789abcdef';

test('welcome email links to /communities, not /explore', () => {
  const r = templates.welcomeEmail('Alex', 'en');
  assertAllRoutable('welcomeEmail', r);
  assert.ok(webPaths(r).includes('/communities'));
});

test('weekly digest links to /profile, not /profile/stats', () => {
  const r = templates.weeklyDigest('Alex', { wordsReviewed: 2 }, null, 'en');
  assertAllRoutable('weeklyDigest', r);
  assert.ok(webPaths(r).includes('/profile'));
});

test('new follower email opens the chat with the follower by id', () => {
  const r = templates.newFollowerEmail('Alex', 'Jo & "Mi"/../x', null, 'en', FOLLOWER_ID);
  assertAllRoutable('newFollowerEmail', r);
  assert.ok(r.html.includes(`https://banatalk.com/chat/${FOLLOWER_ID}`));
  assert.ok(!r.html.includes('/messages/new/'), 'no name in the URL');
});

test('new follower email without an id falls back to /chat', () => {
  const r = templates.newFollowerEmail('Alex', 'Jo', null, 'en');
  assertAllRoutable('newFollowerEmail(no id)', r);
  assert.ok(webPaths(r).every((p) => p === '/chat'));
});

test('a follower id that is not an ObjectId never reaches the URL', () => {
  const r = templates.newFollowerEmail('Alex', 'Jo', null, 'en', '../admin?x=<b>');
  assertAllRoutable('newFollowerEmail(bad id)', r);
});

test('new message and correction emails link to /chat, not /messages', () => {
  assertAllRoutable('newMessageEmail', templates.newMessageEmail('Alex', 'Jo', 'hello', 'en'));
  assertAllRoutable('correctionReceivedEmail', templates.correctionReceivedEmail('Alex', 'Jo', 'a', 'b', 'en'));
});

test('admin report alert links to the admin reports tab', () => {
  const prev = process.env.APP_URL;
  delete process.env.APP_URL;
  try {
    const r = templates.adminReportAlert({ _id: 'r1', reason: 'spam' }, 'A', 'B');
    assertAllRoutable('adminReportAlert', r);
    assert.ok(!`${r.html}${r.text}`.includes('/admin/reports/'));
  } finally {
    if (prev !== undefined) process.env.APP_URL = prev;
  }
});

test('translated locales keep the same links', () => {
  for (const locale of ['ko', 'ar', 'ja']) {
    assertAllRoutable(`welcomeEmail ${locale}`, templates.welcomeEmail('Alex', locale));
    assertAllRoutable(`newFollowerEmail ${locale}`, templates.newFollowerEmail('Alex', 'Jo', null, locale, FOLLOWER_ID));
  }
});
```
- [ ] **Step 2: Run, expect FAIL (0/8 pass).**
`node --experimental-test-module-mocks --test --test-force-exit test/emailWebLinks.test.js`
Expected messages include: `welcomeEmail: /explore is not a web route`, `weeklyDigest: /profile/stats is not a web route`, `newFollowerEmail: /messages/new/Jo is not a web route`, `newMessageEmail: /messages is not a web route`, `adminReportAlert: /admin/reports/r1 is not a web route`.
- [ ] **Step 3: Implement** (exact diff):
```diff
--- a/utils/emailTemplates.js
+++ b/utils/emailTemplates.js
@@ -8,6 +8,17 @@
 const APP_NAME = 'Bananatalk';
 const SUPPORT_EMAIL = 'bananatalkmain@gmail.com';
 const YEAR = new Date().getFullYear();
+
+// The website. Every path below must exist in language_exchange_web_front
+// src/router/routes.tsx (test/emailWebLinks.test.js keeps the list).
+const WEB_URL = 'https://banatalk.com';
+const OBJECT_ID_RE = /^[0-9a-f]{24}$/i;
+
+// /chat/<userId> opens the thread with that user; anything that is not a
+// user id (a name, a missing id) falls back to the chat list.
+const chatUrl = (userId) => (userId && OBJECT_ID_RE.test(String(userId))
+  ? `${WEB_URL}/chat/${encodeURIComponent(String(userId))}`
+  : `${WEB_URL}/chat`);
 
 // All user-facing copy lives in email_templates/{locale}.json (per-key en
 // fallback via services/emailTemplateService.js). This file keeps ONLY
@@ -117,7 +128,7 @@
         <table width="100%" cellpadding="0" cellspacing="0" style="margin: 30px 0;">
           <tr>
             <td align="center">
-              <a href="https://banatalk.com/explore" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; padding: 15px 40px; border-radius: 30px; font-size: 16px; font-weight: bold;">
+              <a href="${WEB_URL}/communities" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; padding: 15px 40px; border-radius: 30px; font-size: 16px; font-weight: bold;">
                 ${t(locale, 'welcome.cta', vars)}
               </a>
             </td>
@@ -135,7 +146,7 @@
 ${t(locale, 'welcome.whatYouCanDo', vars)}
 ${features.map((f) => `- ${f}`).join('\n')}
 
-${t(locale, 'welcome.cta', vars)}: https://banatalk.com/explore`
+${t(locale, 'welcome.cta', vars)}: ${WEB_URL}/communities`
   };
 };
 
@@ -424,7 +435,7 @@
  * Weekly digest email
  */
 exports.weeklyDigest = (userName, stats = {}, unsubscribeUrl = null, locale = 'en') => {
-  const url = 'https://banatalk.com/profile/stats';
+  const url = `${WEB_URL}/profile`;
   const statVars = {
     wordsReviewed: stats.wordsReviewed || 0,
     wordsSaved: stats.wordsSaved || 0,
@@ -497,8 +508,9 @@
 /**
  * New follower notification
  */
-exports.newFollowerEmail = (userName, followerName, followerImage, locale = 'en') => {
-  const vars = { userName, followerName, appName: APP_NAME, url: 'https://banatalk.com/messages' };
+exports.newFollowerEmail = (userName, followerName, followerImage, locale = 'en', followerId = null) => {
+  const url = chatUrl(followerId);
+  const vars = { userName, followerName, appName: APP_NAME, url };
   const varsHtml = { ...vars, userName: `<strong>${userName}</strong>`, followerName: `<strong>${followerName}</strong>` };
 
   const content = `
@@ -524,7 +536,7 @@
         <table width="100%" cellpadding="0" cellspacing="0" style="margin: 30px 0;">
           <tr>
             <td align="center">
-              <a href="https://banatalk.com/messages/new/${followerName}" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; padding: 15px 40px; border-radius: 30px; font-size: 16px; font-weight: bold;">
+              <a href="${url}" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; padding: 15px 40px; border-radius: 30px; font-size: 16px; font-weight: bold;">
                 ${t(locale, 'newFollower.cta')}
               </a>
             </td>
@@ -545,7 +557,7 @@
  * New message notification (for users not actively using the app)
  */
 exports.newMessageEmail = (userName, senderName, messagePreview, locale = 'en') => {
-  const url = 'https://banatalk.com/messages';
+  const url = chatUrl(null);
   const vars = { userName, senderName, appName: APP_NAME, url, messagePreview };
   const varsHtml = { ...vars, userName: `<strong>${userName}</strong>`, senderName: `<strong>${senderName}</strong>` };
 
@@ -597,7 +609,7 @@
  * Correction received notification (HelloTalk style)
  */
 exports.correctionReceivedEmail = (userName, correctorName, originalText, correctedText, locale = 'en') => {
-  const url = 'https://banatalk.com/messages';
+  const url = chatUrl(null);
   const vars = { userName, correctorName, appName: APP_NAME, url };
   const varsHtml = { ...vars, userName: `<strong>${userName}</strong>`, correctorName: `<strong>${correctorName}</strong>` };
 
@@ -1286,7 +1298,7 @@
 Priority: ${report.priority || 'normal'}
 Description: ${report.description || '(none)'}
 
-View in admin: ${process.env.APP_URL || 'https://banatalk.com'}/admin/reports/${report._id}
+View in admin: ${process.env.APP_URL || WEB_URL}/admin/content?tab=reports (report ${report._id})
 
 This is an automated alert. The full report is also included in
 the daily admin digest.`,
@@ -1296,7 +1308,7 @@
   <li>Priority: ${report.priority || 'normal'}</li>
   <li>Description: ${report.description || '(none)'}</li>
 </ul>
-<p>View in admin: <a href="${process.env.APP_URL || 'https://banatalk.com'}/admin/reports/${report._id}">${report._id}</a></p>`
+<p>View in admin: <a href="${process.env.APP_URL || WEB_URL}/admin/content?tab=reports">report ${report._id}</a></p>`
 });
 
 /**
--- a/services/emailService.js
+++ b/services/emailService.js
@@ -189,7 +189,7 @@
 /**
  * Send new follower notification
  */
-exports.sendNewFollowerEmail = async (user, followerName, followerImage) => {
+exports.sendNewFollowerEmail = async (user, followerName, followerImage, followerId = null) => {
   try {
     // Check if user has email notifications enabled
     if (user.privacySettings?.emailNotifications === false) {
@@ -197,7 +197,7 @@
     }
     
     const locale = resolveEmailLocale(user);
-    const template = templates.newFollowerEmail(user.name, followerName, followerImage, locale);
+    const template = templates.newFollowerEmail(user.name, followerName, followerImage, locale, followerId);
     await sendEmail({
       email: user.email,
       subject: template.subject,
```
- [ ] **Step 4: Run, expect PASS.** `node --experimental-test-module-mocks --test --test-force-exit test/emailWebLinks.test.js test/emailCatalogs.test.js` gives `pass 16, fail 0`.
- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, under the Phase 1 heading, tick `- [x] Email links go to real web routes (welcome → /communities, digest → /profile, follower → /chat/<id>, message/correction → /chat, admin report → /admin/content?tab=reports)`. Add these open items: `- [ ] Wire sendNewFollowerEmail / sendNewMessageEmail / sendCorrectionEmail (no callers today); pass followerId. S` and `- [ ] Email templates interpolate user names into HTML unescaped (followerName, senderName, originalText…); escape them. S`.
```
git add utils/emailTemplates.js services/emailService.js test/emailWebLinks.test.js docs/REMAINING_WORK.md
git commit -m "fix(email): CTA links go to routes the website has" -m "Welcome linked to /explore, follower/message/correction to /messages (and /messages/new/<unencoded name>), digest to /profile/stats (claimed by the AASA, opened a profile called 'stats'), admin alert to /admin/reports/:id. None exist on banatalk.com. Now /communities, /chat/<followerId> (id only, encoded), /chat, /profile, /admin/content?tab=reports; test keeps a mirror of the web routes.

Still open: wire the three notification emails that have no caller; escape user names in email HTML; rest of Phase 1 items 6-8 (OG invite, Pub/Sub audience, web flags, Apple web, Google code exchange, contract tests, doc domains)."
```

---

### Task P1-LINK-2: OG preview for invite links `/og/i/:code` (links#17)

**Files:**
- Modify `controllers/og.js`: header comment line 10; require after line 18; constants after line 43; new `buildInviteOg` placed before the `getOg` doc comment (line 187); dispatch in `getOg` lines 199–201.
- No route change. `routes/og.js` already matches `/:type/:id`.
- Test (new): `test/ogInvite.test.js`

**How invites are stored** (`controllers/referrals.js`, `lib/referralCode.js`): `User.referralCode` is unique and sparse, 8 characters of `A-Z2-7`, upper-case (claims call `.toUpperCase()`). Links look like `https://banatalk.com/i/<code>` (`LINK_BASE`).

**Interfaces:**
- `GET /og/i/:code` returns 200 with title `"<name> invited you to BananaTalk"`, `og:url` `<FRONTEND>/i/<CODE>` and the inviter's first image (falling back to the default image).
- Lower-case codes are normalised.
- A malformed, unknown or suspended (`isBanned`) inviter gets a 404 generic card. Malformed codes are rejected by regex before any database query.
- A non-public profile (`isProfileNonPublic`) gets the card "You're invited to BananaTalk", without the name.
- The endpoint does not check `REFERRALS_ENABLED`. The web `/i/:code` page renders either way, and the card promises no coins.
- The crawler rule that sends `/i/` to this endpoint belongs to the nginx snippet and Phase 5. It is not part of this task.

- [ ] **Step 1: Write the failing test** `test/ogInvite.test.js`:
```js
'use strict';
/**
 * links#17: /og/i/:code gives invite links a real preview ("Ada invited you")
 * instead of the generic homepage card.
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, makeUser } = require('./helpers/callKit');

let getOg;

test.before(async () => {
  await startDb('ogInvite');
  ({ getOg } = require('../controllers/og'));
});
test.after(stopDb);

const run = (type, id) => new Promise((resolve) => {
  const res = {
    statusCode: 200,
    headers: {},
    status(c) { this.statusCode = c; return this; },
    set(k, v) { this.headers[k] = v; return this; },
    send(body) { resolve({ status: this.statusCode, html: body }); },
  };
  getOg({ params: { type, id } }, res);
});

const ogTitle = (html) => (/<meta property="og:title" content="([^"]*)">/.exec(html) || [])[1];
const ogUrl = (html) => (/<meta property="og:url" content="([^"]*)">/.exec(html) || [])[1];

test('known invite code: personalised card that links back to /i/<code>', async () => {
  await makeUser('Ada', { referralCode: 'ABCDEF23', images: ['https://cdn.test/ada.jpg'] });
  const { status, html } = await run('i', 'ABCDEF23');
  assert.equal(status, 200);
  assert.equal(ogTitle(html), 'Ada invited you to BananaTalk');
  assert.match(ogUrl(html), /\/i\/ABCDEF23$/);
  assert.match(html, /<meta property="og:image" content="https:\/\/cdn\.test\/ada\.jpg">/);
});

test('lower-case code in the link still resolves (codes are stored upper-case)', async () => {
  await makeUser('Bo', { referralCode: 'QWERTY23' });
  const { status, html } = await run('i', 'qwerty23');
  assert.equal(status, 200);
  assert.equal(ogTitle(html), 'Bo invited you to BananaTalk');
  assert.match(ogUrl(html), /\/i\/QWERTY23$/);
});

test('inviter name is HTML-escaped', async () => {
  await makeUser('eve', { name: '<b>Eve</b>', referralCode: 'EVEEVE23' });
  const { html } = await run('i', 'EVEEVE23');
  assert.equal(ogTitle(html), '&lt;b&gt;Eve&lt;/b&gt; invited you to BananaTalk');
});

test('unknown or malformed code: generic card with 404, no DB error', async () => {
  for (const code of ['ZZZZZZ22', 'short', '../../etc', 'ABCDEF2!']) {
    const { status, html } = await run('i', code);
    assert.equal(status, 404, code);
    assert.ok(!/invited you/.test(html), code);
  }
});

test('suspended inviter: generic card, not their name', async () => {
  await makeUser('Mallory', { referralCode: 'BANNED23', isBanned: true });
  const { status, html } = await run('i', 'BANNED23');
  assert.equal(status, 404);
  assert.ok(!/Mallory/.test(html));
});
```
- [ ] **Step 2: Run, expect FAIL (0/5).** `node --experimental-test-module-mocks --test --test-force-exit test/ogInvite.test.js`. Today `i` is an unknown type, so the endpoint returns a 200 generic card. So the title assertions get the default `BananaTalk - #1 Free Language Exchange App` instead of `Ada invited you to BananaTalk`, and the unknown-code test fails with `ZZZZZZ22 200 !== 404`.
- [ ] **Step 3: Implement** (exact diff):
```diff
--- a/controllers/og.js
+++ b/controllers/og.js
@@ -7,7 +7,8 @@
 // so a crawler gets a rich preview while a human who somehow lands here
 // gets bounced to the actual app/web route.
 //
-// Route: GET /og/:type/:id   type ∈ moment | profile | community | user
+// Route: GET /og/:type/:id   type ∈ moment | profile | community | user | i
+//        (i = invite link banatalk.com/i/<referral code>; :id is the code)
 // Access: fully public, no auth. Must never throw — always resolves to a
 // 200 (or 404) HTML response, falling back to a generic BananaTalk card
 // for unknown ids/types/errors.
@@ -16,6 +17,7 @@
 const { canViewMoment } = require('../lib/momentVisibility');
 const User = require('../models/User');
 const { toCdnUrl } = require('../utils/imageUtils');
+const { CODE_LENGTH } = require('../lib/referralCode');
 
 // Same field allow-list used by controllers/users.js getUser/getUserPublic —
 // duplicated here rather than imported. The users controller now DOES export
@@ -42,6 +44,12 @@
 // the canonical web URL so it matches the web app's actual route.
 const USER_OG_TYPES = new Set(['profile', 'community', 'user']);
 
+// Referral codes are CODE_LENGTH chars of RFC 4648 base32 (lib/referralCode).
+// Anything else is rejected before it reaches the database.
+const INVITE_CODE_RE = new RegExp(`^[A-Z2-7]{${CODE_LENGTH}}$`);
+const INVITE_DESCRIPTION =
+  'Practise languages with native speakers on BananaTalk. Free on iPhone, Android and the web.';
+
 /**
  * Minimal HTML-escaper for text dropped into attribute values / body text.
  * Order matters: & must be escaped first.
@@ -186,6 +194,41 @@
 }
 
 /**
+ * Invite link preview: "<name> invited you to BananaTalk". Looks the inviter
+ * up by referralCode (stored upper-case). Unknown, malformed and suspended
+ * codes return null, which the caller turns into a 404 generic card. Does
+ * not depend on REFERRALS_ENABLED: the web /i/:code page renders either way,
+ * and the preview promises nothing about coins.
+ */
+async function buildInviteOg(rawCode) {
+  const code = String(rawCode || '').trim().toUpperCase();
+  if (!INVITE_CODE_RE.test(code)) return null;
+
+  const user = await User.findOne({ referralCode: code })
+    .select('name username images privacySettings isBanned')
+    .lean();
+  if (!user || user.isBanned === true) return null;
+
+  const canonicalUrl = `${FRONTEND_URL_BASE}/i/${code}`;
+  if (isProfileNonPublic(user)) {
+    return {
+      canonicalUrl,
+      title: `You're invited to ${APP_NAME}`,
+      description: INVITE_DESCRIPTION,
+      image: DEFAULT_OG_IMAGE,
+    };
+  }
+
+  const who = user.name || (user.username ? `@${user.username}` : null);
+  return {
+    canonicalUrl,
+    title: who ? `${who} invited you to ${APP_NAME}` : `You're invited to ${APP_NAME}`,
+    description: INVITE_DESCRIPTION,
+    image: toCdnUrl((user.images && user.images[0]) || undefined),
+  };
+}
+
+/**
  * @desc    Public OG/link-preview HTML for a shared moment/profile URL
  * @route   GET /og/:type/:id
  * @access  Public
@@ -198,6 +241,8 @@
 
     if (type === 'moment') {
       ogData = await buildMomentOg(id);
+    } else if (type === 'i') {
+      ogData = await buildInviteOg(id);
     } else if (USER_OG_TYPES.has(type)) {
       ogData = await buildUserOg(id, 'profile');
     } else {
```
- [ ] **Step 4: Run, expect PASS.** `node --experimental-test-module-mocks --test --test-force-exit test/ogInvite.test.js test/og.test.js` gives `pass 8, fail 0`.
- [ ] **Step 5: Commit.** In REMAINING_WORK, tick `- [x] /og/i/:code invite previews ("<name> invited you")`. In section 2 (owner), add: `nginx crawler rule must include /i/ (→ /og/i/<code>) alongside moment|profile|community|story — web deploy/nginx.snippet.conf + Phase 5`.
```
git add controllers/og.js test/ogInvite.test.js docs/REMAINING_WORK.md
git commit -m "feat(og): invite link previews at /og/i/:code" -m "Invite links unfurled as the generic homepage card. Looks the inviter up by referralCode (upper-cased, regex-checked before the query), escapes the name, hides it for non-public profiles, and returns a 404 generic card for unknown or suspended codes.

Still open: nginx bot rule incl. /i/ (owner, Phase 5); rest of Phase 1 items 6-8."
```

---

### Task P1-LINK-3: Pub/Sub audience fallback uses api.banatalk.com (links#13)

**Files:**
- Modify `middleware/webhookAuth.js` line 138.
- Test (new): `test/googleWebhookAudience.test.js`

**Interfaces:** The expected audience is `GOOGLE_PUBSUB_AUDIENCE`, or else `https://${DOMAIN || 'api.banatalk.com'}/api/v1/purchases/android/webhook`. Only the last fallback changes.

**Risk:** if prod sets `DOMAIN` to something other than the API host (for example `banatalk.com`), RTDN verification still fails. That is the owner check below. This code change only fixes the case where neither variable is set.

- [ ] **Step 1: Write the failing test** `test/googleWebhookAudience.test.js`:
```js
'use strict';
/**
 * links#13: with neither GOOGLE_PUBSUB_AUDIENCE nor DOMAIN set, the expected
 * RTDN audience was https://api.bananatalk.com/... (the parked double-n
 * domain), so every Play push would fail verification with a 401.
 */
const { test, mock, afterEach } = require('node:test');
const assert = require('node:assert/strict');

const audiences = [];
mock.module('google-auth-library', {
  namedExports: {
    OAuth2Client: class {
      async verifyIdToken({ audience }) {
        audiences.push(audience);
        return { getPayload: () => ({ email: 'push@p.iam.gserviceaccount.com', sub: '1' }) };
      }
    },
  },
});
mock.module('../utils/securityLogger.js', {
  namedExports: { logSecurityEvent: mock.fn(async () => {}) },
});

const { verifyGoogleWebhookSignature } = require('../middleware/webhookAuth');

const saved = { aud: process.env.GOOGLE_PUBSUB_AUDIENCE, domain: process.env.DOMAIN };
afterEach(() => {
  audiences.length = 0;
  for (const [k, v] of [['GOOGLE_PUBSUB_AUDIENCE', saved.aud], ['DOMAIN', saved.domain]]) {
    if (v === undefined) delete process.env[k]; else process.env[k] = v;
  }
});

async function run() {
  const req = { headers: { authorization: 'Bearer t' }, ip: '1.2.3.4' };
  const res = { status() { return res; }, json() { return res; } };
  let passed = false;
  await verifyGoogleWebhookSignature(req, res, () => { passed = true; });
  return passed;
}

test('fallback audience is api.banatalk.com (single n)', async () => {
  delete process.env.GOOGLE_PUBSUB_AUDIENCE;
  delete process.env.DOMAIN;
  assert.equal(await run(), true);
  assert.deepEqual(audiences, ['https://api.banatalk.com/api/v1/purchases/android/webhook']);
});

test('DOMAIN still overrides the fallback host', async () => {
  delete process.env.GOOGLE_PUBSUB_AUDIENCE;
  process.env.DOMAIN = 'staging.banatalk.com';
  await run();
  assert.deepEqual(audiences, ['https://staging.banatalk.com/api/v1/purchases/android/webhook']);
});

test('GOOGLE_PUBSUB_AUDIENCE wins over everything', async () => {
  process.env.GOOGLE_PUBSUB_AUDIENCE = 'https://example.test/hook';
  process.env.DOMAIN = 'ignored.example';
  await run();
  assert.deepEqual(audiences, ['https://example.test/hook']);
});
```
- [ ] **Step 2: Run, expect FAIL (1 of 3).** `node --experimental-test-module-mocks --test --test-force-exit test/googleWebhookAudience.test.js` fails `fallback audience is api.banatalk.com (single n)`, because the actual value is `https://api.bananatalk.com/...`. The other two pass.
- [ ] **Step 3: Implement:**
```diff
--- a/middleware/webhookAuth.js
+++ b/middleware/webhookAuth.js
@@ -135,7 +135,7 @@
     // Verify the token is from Google Pub/Sub
     // The token should be issued by Google for our project
     const expectedAudience = process.env.GOOGLE_PUBSUB_AUDIENCE ||
-                             `https://${process.env.DOMAIN || 'api.bananatalk.com'}/api/v1/purchases/android/webhook`;
+                             `https://${process.env.DOMAIN || 'api.banatalk.com'}/api/v1/purchases/android/webhook`;
 
     const ticket = await googleAuthClient.verifyIdToken({
       idToken: token,
```
- [ ] **Step 4: Run, expect PASS.** `node --experimental-test-module-mocks --test --test-force-exit test/googleWebhookAudience.test.js test/googleWebhookSender.test.js` gives `pass 6, fail 0`.
- [ ] **Step 5: Commit.** In REMAINING_WORK, tick `- [x] RTDN audience fallback api.banatalk.com`. In owner section 2, add `Check prod GOOGLE_PUBSUB_AUDIENCE / DOMAIN equal the Pub/Sub push subscription audience (https://api.banatalk.com/api/v1/purchases/android/webhook)`, next to the existing `GOOGLE_PUBSUB_SERVICE_ACCOUNT` item.
```
git add middleware/webhookAuth.js test/googleWebhookAudience.test.js docs/REMAINING_WORK.md
git commit -m "fix(purchases): RTDN audience fallback is api.banatalk.com" -m "With neither GOOGLE_PUBSUB_AUDIENCE nor DOMAIN set, every Play RTDN push was verified against the parked api.bananatalk.com and refused with 401.

Still open: owner confirms prod GOOGLE_PUBSUB_AUDIENCE/DOMAIN; rest of Phase 1 items 6-8."
```

---

### Task P1-LINK-4: Six website feature flags in limitations + app-config (spec §4)

**Files:**
- Modify `config/limitations.js`: after line 135 (`COOKIE_AUTH_ENABLED`), and in `module.exports` after line 156.
- Modify `controllers/appConfig.js`: the destructure at lines 1–3, and the payload after line 150 (`gatheringsEnabled`).
- Test (new): `test/webFeatureFlags.test.js`

**Interfaces (env var → `/app-config` `data` key, all boolean, default `false`, on only when the value is `true` in any case):**
`WEB_REELS_ENABLED`→`webReelsEnabled`, `WEB_GATHERINGS_ENABLED`→`webGatheringsEnabled`, `WEB_VOICE_ROOMS_ENABLED`→`webVoiceRoomsEnabled`,
`WEB_LANGUAGE_ROOMS_ENABLED`→`webLanguageRoomsEnabled`, `WEB_CALLS_ENABLED`→`webCallsEnabled`, `WEB_APPLE_SIGNIN_ENABLED`→`webAppleSigninEnabled`.

These are the same `String(env || 'false').toLowerCase() === 'true'` pattern as every other flag, so existing behaviour is unchanged. The existing global switches still apply to everyone: `REELS_ENABLED`, `GATHERINGS_ENABLED` and `ROOMS_ENABLED`. Voice rooms get no global switch. The app ignores the new keys.

- [ ] **Step 1: Write the failing test** `test/webFeatureFlags.test.js`. It uses the same `require.cache` pattern as `test/matchesLayoutKillSwitch.test.js`:
```js
'use strict';
/**
 * Web parity spec §4: six website feature flags, each default FALSE, each
 * exposed in /app-config so the website can hide its nav entry, routes and
 * buttons while the flag is off. Same pattern as MATCHES_LAYOUT_ENABLED
 * (test/matchesLayoutKillSwitch.test.js).
 */
const { test } = require('node:test');
const assert = require('node:assert/strict');

const FLAGS = [
  ['WEB_REELS_ENABLED', 'webReelsEnabled'],
  ['WEB_GATHERINGS_ENABLED', 'webGatheringsEnabled'],
  ['WEB_VOICE_ROOMS_ENABLED', 'webVoiceRoomsEnabled'],
  ['WEB_LANGUAGE_ROOMS_ENABLED', 'webLanguageRoomsEnabled'],
  ['WEB_CALLS_ENABLED', 'webCallsEnabled'],
  ['WEB_APPLE_SIGNIN_ENABLED', 'webAppleSigninEnabled'],
];

async function withEnv(name, value, fn) {
  const original = process.env[name];
  const reset = () => {
    delete require.cache[require.resolve('../config/limitations')];
    delete require.cache[require.resolve('../controllers/appConfig')];
  };
  try {
    if (value === undefined) delete process.env[name];
    else process.env[name] = value;
    reset();
    return await fn();
  } finally {
    if (original === undefined) delete process.env[name];
    else process.env[name] = original;
    reset();
  }
}

const mockRes = () => ({
  statusCode: null,
  body: null,
  status(code) { this.statusCode = code; return this; },
  json(body) { this.body = body; return this; },
});

for (const [envName, configKey] of FLAGS) {
  test(`config/limitations.js: ${envName} defaults to false`, async () => {
    await withEnv(envName, undefined, () => {
      assert.equal(require('../config/limitations')[envName], false);
    });
  });

  test(`config/limitations.js: ${envName}=true turns it on, anything else is off`, async () => {
    await withEnv(envName, 'true', () => assert.equal(require('../config/limitations')[envName], true));
    await withEnv(envName, 'TRUE', () => assert.equal(require('../config/limitations')[envName], true));
    await withEnv(envName, 'false', () => assert.equal(require('../config/limitations')[envName], false));
    await withEnv(envName, '1', () => assert.equal(require('../config/limitations')[envName], false));
  });

  test(`appConfig: ${configKey} is false by default and true when ${envName}=true`, async () => {
    await withEnv(envName, undefined, async () => {
      const res = mockRes();
      await require('../controllers/appConfig').getAppConfig({ query: { platform: 'web' }, headers: {} }, res, () => {});
      assert.equal(res.body.data[configKey], false);
    });
    await withEnv(envName, 'true', async () => {
      const res = mockRes();
      await require('../controllers/appConfig').getAppConfig({ query: { platform: 'web' }, headers: {} }, res, () => {});
      assert.equal(res.body.data[configKey], true);
    });
  });
}
```
- [ ] **Step 2: Run, expect FAIL (0/18).** `node --experimental-test-module-mocks --test --test-force-exit test/webFeatureFlags.test.js` fails with `undefined !== false` (the flag doesn't exist yet).
- [ ] **Step 3: Implement:**
```diff
--- a/config/limitations.js
+++ b/config/limitations.js
@@ -134,6 +134,21 @@
 // production.
 const COOKIE_AUTH_ENABLED = String(process.env.COOKIE_AUTH_ENABLED || 'false').toLowerCase() === 'true';
 
+// Website feature flags (web parity spec 2026-10-16 §4). Each defaults to
+// FALSE so the web feature ships dark: the website reads the matching
+// app-config boolean and hides the nav entry, routes and buttons while it is
+// off. They gate the WEBSITE only; the app's own switches still apply to
+// everyone (REELS_ENABLED, GATHERINGS_ENABLED, ROOMS_ENABLED). Voice rooms
+// have no global switch, so WEB_VOICE_ROOMS_ENABLED is their only gate on web.
+// WEB_APPLE_SIGNIN_ENABLED also gates POST /auth/apple/web (404 while off).
+// Turned on one at a time after browser QA (owner step, Phase 5).
+const WEB_REELS_ENABLED = String(process.env.WEB_REELS_ENABLED || 'false').toLowerCase() === 'true';
+const WEB_GATHERINGS_ENABLED = String(process.env.WEB_GATHERINGS_ENABLED || 'false').toLowerCase() === 'true';
+const WEB_VOICE_ROOMS_ENABLED = String(process.env.WEB_VOICE_ROOMS_ENABLED || 'false').toLowerCase() === 'true';
+const WEB_LANGUAGE_ROOMS_ENABLED = String(process.env.WEB_LANGUAGE_ROOMS_ENABLED || 'false').toLowerCase() === 'true';
+const WEB_CALLS_ENABLED = String(process.env.WEB_CALLS_ENABLED || 'false').toLowerCase() === 'true';
+const WEB_APPLE_SIGNIN_ENABLED = String(process.env.WEB_APPLE_SIGNIN_ENABLED || 'false').toLowerCase() === 'true';
+
 module.exports = {
   AI_QUOTA_ENABLED,
   ROOMS_ENABLED,
@@ -154,6 +169,12 @@
   CONVERSATION_CAP_ENABLED,
   GATHERINGS_ENABLED,
   COOKIE_AUTH_ENABLED,
+  WEB_REELS_ENABLED,
+  WEB_GATHERINGS_ENABLED,
+  WEB_VOICE_ROOMS_ENABLED,
+  WEB_LANGUAGE_ROOMS_ENABLED,
+  WEB_CALLS_ENABLED,
+  WEB_APPLE_SIGNIN_ENABLED,
 
   // ===================== VISITOR LIMITS =====================
   // Users who haven't verified email or just browsing
--- a/controllers/appConfig.js
+++ b/controllers/appConfig.js
@@ -1,7 +1,8 @@
 const asyncHandler = require('../middleware/async');
 const { ROOMS_ENABLED, SMART_SORT_ENABLED, MATCHES_LAYOUT_ENABLED, STUDY_HUB_ENABLED, STUDY_VIP_ONLY_FEATURES, REELS_ENABLED, COINS_ENABLED, CONVERSATION_CAP_ENABLED,
   GATHERINGS_ENABLED, WELCOME_WAVE_ENABLED, LIFECYCLE_PUSH_ENABLED, REFERRALS_ENABLED, BOOSTS_ENABLED, REWARDED_LIMITS_ENABLED,
-  WAVE_CAP_ENABLED } = require('../config/limitations');
+  WAVE_CAP_ENABLED, WEB_REELS_ENABLED, WEB_GATHERINGS_ENABLED, WEB_VOICE_ROOMS_ENABLED, WEB_LANGUAGE_ROOMS_ENABLED,
+  WEB_CALLS_ENABLED, WEB_APPLE_SIGNIN_ENABLED } = require('../config/limitations');
 
 const { REWARDED_FEATURES } = require('../config/coinCatalog');
 const mongoose = require('mongoose');
@@ -147,6 +148,13 @@
       coinsEnabled: COINS_ENABLED,
       conversationCapEnabled: CONVERSATION_CAP_ENABLED,
       gatheringsEnabled: GATHERINGS_ENABLED,
+      // Website-only feature flags (web parity spec §4). The app ignores them.
+      webReelsEnabled: WEB_REELS_ENABLED,
+      webGatheringsEnabled: WEB_GATHERINGS_ENABLED,
+      webVoiceRoomsEnabled: WEB_VOICE_ROOMS_ENABLED,
+      webLanguageRoomsEnabled: WEB_LANGUAGE_ROOMS_ENABLED,
+      webCallsEnabled: WEB_CALLS_ENABLED,
+      webAppleSigninEnabled: WEB_APPLE_SIGNIN_ENABLED,
     },
   });
 });
```
- [ ] **Step 4: Run, expect PASS.** `node --experimental-test-module-mocks --test --test-force-exit test/webFeatureFlags.test.js test/matchesLayoutKillSwitch.test.js test/appConfigAnnouncements.test.js` gives `pass 39, fail 0`.
- [ ] **Step 5: Commit.** In REMAINING_WORK, tick `- [x] WEB_* flags (6) in limitations + app-config, default false`. In owner section 2, item 9 (flags), add a bullet: `Website (default OFF, turn on one at a time after browser QA): WEB_REELS_ENABLED, WEB_GATHERINGS_ENABLED, WEB_VOICE_ROOMS_ENABLED, WEB_LANGUAGE_ROOMS_ENABLED, WEB_CALLS_ENABLED, WEB_APPLE_SIGNIN_ENABLED (also needs APPLE_WEB_SERVICES_ID)`.
```
git add config/limitations.js controllers/appConfig.js test/webFeatureFlags.test.js docs/REMAINING_WORK.md
git commit -m "feat(config): website feature flags, exposed in app-config" -m "WEB_REELS/GATHERINGS/VOICE_ROOMS/LANGUAGE_ROOMS/CALLS/APPLE_SIGNIN_ENABLED, all default false, as webReelsEnabled ... webAppleSigninEnabled. The website hides each feature while its flag is off; global switches still apply.

Still open: web reads the flags (Phase 3/4); Apple web endpoint (P1-LINK-6) gates on WEB_APPLE_SIGNIN_ENABLED; rest of Phase 1 items 6-8."
```

---

### Task P1-LINK-5: Google web login — one-time code instead of the JWT in the URL (links#12)

**Files:**
- Create `models/OAuthLoginCode.js`.
- Create `lib/oauthLoginCode.js`.
- Modify `controllers/auth.js`: replace the `googleCallback` block, lines 478–532 (from the `/**` above `@desc Google callback route` up to the line before `// resolveRegistrationUsername lives…`), with the block below. That block also adds `exchangeGoogleCode`.
- Modify `routes/auth.js`: import at line 14; route after line 53.
- Test (new): `test/googleWebLoginCode.test.js`

**Design decisions:**
- **Storage is Mongo with a TTL index, not `services/redisService`.** The cache service has no atomic get-and-delete. Without `REDIS_URL` it also falls back to a per-process `Map`, so under PM2 a code could be spent twice or not be found by another worker. `findOneAndDelete({codeHash, expiresAt: {$gt: now}})` is atomic, and its own expiry check covers the roughly 60 s lag of the TTL monitor.
- **The table stores the user id and a SHA-256 of the code, never tokens.** The token pair is minted at exchange time through `sendTokenResponse(user, 200, res, req, getDeviceInfo(req))`, so the refresh token is bound to the browser that redeems the code. The response matches every other login: `{ success, token, refreshToken, user }`. Web Google login gets a refresh token for the first time.
- **The code is 32 random bytes as base64url (43 characters). It lasts 60 s and works once.** Anything that isn't a string of 1–128 characters is rejected before hashing, which also blocks NoSQL operator objects such as `{ "$gt": "" }`.
- **`?token=` stays in the redirect** next to `?code=`, because the live web's `AuthCallback.tsx:46` reads only `token`. The Phase 3 web switches to `code`. After that release is live, remove the `params.set('token', …)` line (REMAINING_WORK item below).
- **Callback refusals now redirect** to `<FRONTEND>/auth/callback?error=<message>&reason=<EMAIL_EXISTS|BANNED|GOOGLE_FAILED>` instead of rendering a JSON 409/403/500 on api.banatalk.com. The live web already shows `error` as a toast (`AuthCallback.tsx:47-51`).

**Risky inputs, all covered by the test:**
- A reused code returns 400 `OAUTH_CODE_INVALID`. With three parallel exchanges, exactly one succeeds.
- An expired code returns 400, even before the TTL sweep.
- Missing, numeric, object or oversized codes return 400, never 500.
- An account banned between the callback and the exchange returns 403 `ACCOUNT_BANNED` with no tokens.
- An existing account with the same email where Google says `email_verified: false` gets the `EMAIL_EXISTS` redirect (passport strategy unchanged, `controllers/auth.js:220-223`). When the email is verified, the account is linked as before.

**Interfaces:**
- `GET /api/v1/auth/google/callback` redirects (302) to `<FRONTEND>/auth/callback?code=<43 chars>&token=<legacy JWT>`.
- `POST /api/v1/auth/google/exchange`, body `{ code }`, uses `authLimiter`. It returns 200 `{ success, token, refreshToken, user }`, or 400 `{ code: 'OAUTH_CODE_INVALID' }`, or 403 `ACCOUNT_BANNED`.
- `lib/oauthLoginCode`: `issueLoginCode(userId, provider='google') → Promise<string>`, `consumeLoginCode(code, provider='google') → Promise<ObjectId|null>`, and `CODE_TTL_MS = 60000`.

- [ ] **Step 1: Write the failing test** `test/googleWebLoginCode.test.js`. The test replaces the registered Google strategy's `authenticate` on the instance. Passport 0.7 does `Object.create(passport._strategy(name))`, so the override is inherited:
```js
'use strict';
/**
 * links#12: web Google login used to redirect to /auth/callback?token=<JWT>
 * (JWT in history, proxy logs and Referer) and never issued a refresh token.
 * The callback now also carries a single-use code that expires in 60 s;
 * POST /auth/google/exchange {code} returns the same token pair as the other
 * logins, exactly once. `token=` stays in the redirect until the Phase 3 web
 * (which reads `code`) is live — then it is removed (REMAINING_WORK).
 */
process.env.FRONTEND_URL = 'https://web.test';

const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const mongoose = require('mongoose');
const passport = require('passport');
const { start, createUser } = require('./helpers/authHarness');

let h;
let nextOutcome = null; // { user } | { err }

test.before(async () => {
  h = await start('googleWebLoginCode');
  // Stand-in for the Google round trip: the callback's passport.authenticate
  // resolves to whatever the test queued.
  passport._strategy('google').authenticate = function fakeGoogle() {
    const o = nextOutcome;
    if (o.err) return this.error(o.err);
    return this.success(o.user);
  };
});
test.after(async () => { await h.stop(); });

const callback = async (outcome) => {
  nextOutcome = outcome;
  const res = await request(h.app).get('/api/v1/auth/google/callback?code=google-auth-code');
  assert.equal(res.status, 302, JSON.stringify(res.body));
  return new URL(res.headers.location);
};
const exchange = (code) => request(h.app).post('/api/v1/auth/google/exchange').send({ code });

test('callback redirects to /auth/callback with a one-time code (and the legacy token for the live web)', async () => {
  const u = await createUser(h.User, { googleId: `g-${new mongoose.Types.ObjectId()}` });
  const loc = await callback({ user: await h.User.findById(u._id) });
  assert.equal(loc.origin + loc.pathname, 'https://web.test/auth/callback');
  const code = loc.searchParams.get('code');
  assert.ok(code && code.length >= 32, 'code is long and random');
  assert.ok(loc.searchParams.get('token'), 'legacy token kept until the Phase 3 web is live');
});

test('exchange returns token + refreshToken + user, once', async () => {
  const u = await createUser(h.User, { googleId: `g-${new mongoose.Types.ObjectId()}` });
  const code = (await callback({ user: await h.User.findById(u._id) })).searchParams.get('code');

  const first = await exchange(code);
  assert.equal(first.status, 200, JSON.stringify(first.body));
  assert.ok(first.body.token);
  assert.ok(first.body.refreshToken, 'web Google login now gets a refresh token');
  assert.equal(String(first.body.user._id), String(u._id));
  assert.equal(first.body.user.password, undefined);

  const again = await exchange(code);
  assert.equal(again.status, 400);
  assert.equal(again.body.code, 'OAUTH_CODE_INVALID');
});

test('two parallel exchanges of one code: exactly one wins', async () => {
  const u = await createUser(h.User, { googleId: `g-${new mongoose.Types.ObjectId()}` });
  const code = (await callback({ user: await h.User.findById(u._id) })).searchParams.get('code');
  const results = await Promise.all([exchange(code), exchange(code), exchange(code)]);
  assert.deepEqual(results.map((r) => r.status).sort(), [200, 400, 400]);
});

test('expired code is refused even before the TTL sweeper removes it', async () => {
  const u = await createUser(h.User, { googleId: `g-${new mongoose.Types.ObjectId()}` });
  const code = (await callback({ user: await h.User.findById(u._id) })).searchParams.get('code');
  await mongoose.model('OAuthLoginCode').updateMany({}, { $set: { expiresAt: new Date(Date.now() - 1000) } });
  const res = await exchange(code);
  assert.equal(res.status, 400);
  assert.equal(res.body.code, 'OAUTH_CODE_INVALID');
});

test('missing, non-string, oversized and unknown codes are 400, never 500', async () => {
  for (const body of [{}, { code: 123 }, { code: { $gt: '' } }, { code: 'x'.repeat(500) }, { code: 'not-a-real-code' }]) {
    const res = await request(h.app).post('/api/v1/auth/google/exchange').send(body);
    assert.equal(res.status, 400, JSON.stringify(body));
    assert.equal(res.body.code, 'OAUTH_CODE_INVALID');
  }
});

test('account suspended between callback and exchange: 403 ACCOUNT_BANNED, no tokens', async () => {
  const u = await createUser(h.User, { googleId: `g-${new mongoose.Types.ObjectId()}` });
  const code = (await callback({ user: await h.User.findById(u._id) })).searchParams.get('code');
  await h.User.updateOne({ _id: u._id }, { $set: { isBanned: true, banReason: 'spam' } });
  const res = await exchange(code);
  assert.equal(res.status, 403);
  assert.equal(res.body.code, 'ACCOUNT_BANNED');
  assert.equal(res.body.token, undefined);
});

test('callback refusals go back to the web with a readable error, not a JSON page on the API host', async () => {
  const exists = new Error('An account with this email already exists. Please sign in with your email and password.');
  exists.code = 'EMAIL_EXISTS';
  const loc = await callback({ err: exists });
  assert.equal(loc.origin + loc.pathname, 'https://web.test/auth/callback');
  assert.equal(loc.searchParams.get('reason'), 'EMAIL_EXISTS');
  assert.match(loc.searchParams.get('error'), /already exists/);
  assert.equal(loc.searchParams.get('code'), null);
  assert.equal(loc.searchParams.get('token'), null);

  const banned = new Error('This account has been permanently suspended and cannot be reactivated.');
  banned.code = 'BANNED';
  const loc2 = await callback({ err: banned });
  assert.equal(loc2.searchParams.get('reason'), 'BANNED');
});
```
- [ ] **Step 2: Run, expect FAIL (0/7).** `node --experimental-test-module-mocks --test --test-force-exit test/googleWebLoginCode.test.js`. The first test fails with `code is long and random` (no `code` param yet). The exchange tests get `404 !== 200` (no route). The expiry test fails with `MissingSchemaError: Schema hasn't been registered for model "OAuthLoginCode"`. The refusal test gets JSON 409 instead of a 302.
- [ ] **Step 3: Implement.**

`models/OAuthLoginCode.js`:
```js
/**
 * One-time login codes for the web OAuth redirect (links#12).
 *
 * GET /auth/google/callback used to put the access JWT in the redirect URL.
 * It now stores a random code here (only its SHA-256) and redirects with the
 * code; POST /auth/google/exchange trades it for the token pair once.
 *
 * Mongo rather than services/redisService: that cache has no atomic
 * get-and-delete and falls back to a per-process Map without REDIS_URL, so a
 * code could be spent twice or not be found by another PM2 worker.
 * findOneAndDelete is atomic, and the TTL index cleans up unused codes.
 */
const mongoose = require('mongoose');

const OAuthLoginCodeSchema = new mongoose.Schema({
  codeHash: { type: String, required: true, unique: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  provider: { type: String, enum: ['google'], required: true },
  // The exchange checks expiresAt itself: the TTL monitor only runs every
  // ~60 s, so an expired row can still exist for a while.
  expiresAt: { type: Date, required: true },
}, { timestamps: { createdAt: true, updatedAt: false } });

OAuthLoginCodeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.models.OAuthLoginCode
  || mongoose.model('OAuthLoginCode', OAuthLoginCodeSchema);
```
`lib/oauthLoginCode.js`:
```js
'use strict';

const crypto = require('crypto');
const OAuthLoginCode = require('../models/OAuthLoginCode');

const CODE_TTL_MS = 60 * 1000;
// 32 random bytes as base64url = 43 chars. Anything longer than this bound
// is refused before hashing.
const MAX_CODE_LENGTH = 128;

const hashCode = (code) => crypto.createHash('sha256').update(code).digest('hex');

/** Store a new single-use code for `userId`; returns the raw code (never stored). */
async function issueLoginCode(userId, provider = 'google') {
  const code = crypto.randomBytes(32).toString('base64url');
  await OAuthLoginCode.create({
    codeHash: hashCode(code),
    user: userId,
    provider,
    expiresAt: new Date(Date.now() + CODE_TTL_MS),
  });
  return code;
}

/**
 * Spend a code. Returns the user id, or null when the code is missing,
 * malformed, unknown, already spent or expired. Atomic: of two concurrent
 * calls with one code, exactly one gets the id.
 */
async function consumeLoginCode(code, provider = 'google') {
  if (typeof code !== 'string' || code.length === 0 || code.length > MAX_CODE_LENGTH) return null;
  const row = await OAuthLoginCode.findOneAndDelete({
    codeHash: hashCode(code),
    provider,
    expiresAt: { $gt: new Date() },
  }).lean();
  return row ? row.user : null;
}

module.exports = { issueLoginCode, consumeLoginCode, CODE_TTL_MS };
```
`controllers/auth.js`: replace original lines 478–532 with:
```js
/**
 * @desc    Google callback route
 * @route   GET /api/v1/auth/google/callback
 * @access  Public
 */
exports.googleCallback = asyncHandler(async (req, res, next) => {
  const frontendUrl = process.env.FRONTEND_URL || (process.env.NODE_ENV === 'production' ? 'https://banatalk.com' : 'http://localhost:3000');
  // Refusals go back to the web's callback page (it shows `error`), not to a
  // JSON error page on the API host the user can do nothing with.
  const refuse = (reason, message) => res.redirect(
    `${frontendUrl}/auth/callback?error=${encodeURIComponent(message)}&reason=${encodeURIComponent(reason)}`
  );

  passport.authenticate('google', { session: false }, async (err, user) => {
    if (err) {
      if (err.code === 'BANNED') {
        logSecurityEvent('BANNED_IDENTITY_REJECTED', { endpoint: 'googleCallback' });
        return refuse('BANNED', err.message);
      }
      if (err.code === 'EMAIL_EXISTS') {
        return refuse('EMAIL_EXISTS', err.message);
      }
      console.error('Google auth callback error:', err);
      logSecurityEvent('GOOGLE_AUTH_FAILED', {
        error: err.message
      });
      return refuse('GOOGLE_FAILED', 'Google sign-in failed. Please try again.');
    }

    if (!user) {
      return refuse('GOOGLE_FAILED', 'Google sign-in failed. Please try again.');
    }

    const deviceInfo = getDeviceInfo(req);

    // Update lastLogin and lastActivityAt timestamps
    user.lastLogin = new Date();
    user.lastActivityAt = new Date();
    await user.save({ validateBeforeSave: false });

    logSecurityEvent('GOOGLE_LOGIN_SUCCESS', {
      userId: user._id,
      email: user.email,
      ipAddress: deviceInfo.ipAddress
    });

    try {
      // One-time code (60 s, single use) for POST /auth/google/exchange.
      const { issueLoginCode } = require('../lib/oauthLoginCode');
      const params = new URLSearchParams({ code: await issueLoginCode(user._id, 'google') });
      // LEGACY: the live website (before the Phase 3 web release) reads only
      // `token`. Remove this line once that release is live — tracked in
      // docs/REMAINING_WORK.md ("drop ?token= from the Google web callback").
      params.set('token', user.getSignedJwtToken());
      res.redirect(`${frontendUrl}/auth/callback?${params.toString()}`);
    } catch (error) {
      console.error('Token generation error:', error);
      res.redirect(`${frontendUrl}/login?error=token_failed`);
    }
  })(req, res, next);
});

/**
 * @desc    Trade the one-time code from the Google web callback for tokens
 * @route   POST /api/v1/auth/google/exchange   body { code }
 * @access  Public
 *
 * Returns the same `{ success, token, refreshToken, user }` as the other
 * logins. A code works once, for 60 s; anything else is 400
 * OAUTH_CODE_INVALID (the web sends the user back to /login).
 */
exports.exchangeGoogleCode = asyncHandler(async (req, res, next) => {
  const { consumeLoginCode } = require('../lib/oauthLoginCode');
  const invalid = () => next(new ErrorResponse(
    'That sign-in link has expired. Please sign in again.', 400, 'OAUTH_CODE_INVALID'
  ));

  const userId = await consumeLoginCode(req.body && req.body.code, 'google');
  if (!userId) return invalid();

  const user = await User.findById(userId);
  if (!user) return invalid();
  if (user.isBanned === true) {
    logSecurityEvent('BANNED_USER_LOGIN_REJECTED', { endpoint: 'exchangeGoogleCode', userId: user._id });
    return next(bannedError(user));
  }

  const deviceInfo = getDeviceInfo(req);
  logSecurityEvent('GOOGLE_WEB_CODE_EXCHANGED', { userId: user._id, ipAddress: deviceInfo.ipAddress });
  return sendTokenResponse(user, 200, res, req, deviceInfo);
});
```
(`sendTokenResponse`, `bannedError`, `getDeviceInfo`, `logSecurityEvent`, `ErrorResponse` and `User` are already in scope in this file. `sendTokenResponse` is a `const` further down, which is fine because it is only called at request time.)

`routes/auth.js`:
```diff
@@ -12,6 +12,7 @@
   facebookCallback,
   googleLogin,
   googleCallback,
+  exchangeGoogleCode,
   sendVerificationCode,
   verifyCode,
   forgotPassword,
@@ -51,6 +52,7 @@
 router.get('/facebook/callback', facebookCallback);
 router.get('/google', googleLogin);
 router.get('/google/callback', googleCallback);
+router.post('/google/exchange', authLimiter, exchangeGoogleCode);
 
 // Email verification (rate limited)
 router.post(
```
- [ ] **Step 4: Run, expect PASS.** `node --experimental-test-module-mocks --test --test-force-exit test/googleWebLoginCode.test.js` gives `pass 7`. Then run the regression set one file at a time: `for f in test/authAudit.*.test.js test/cookieAuthIntegration.test.js; do node --experimental-test-module-mocks --test --test-force-exit $f; done` (all pass). Also run `node --experimental-test-module-mocks --test --test-force-exit --require ./test/helpers/nodeCompat.js test/schemaIndexRedundancy.test.js`, which passes and confirms the new model's index is not redundant.
- [ ] **Step 5: Commit.** In REMAINING_WORK, tick `- [x] Google web login: one-time code (60 s, single use, Mongo TTL) + POST /auth/google/exchange; web Google login now gets a refresh token; callback refusals redirect to /auth/callback?error=`. Edit the existing line 114 ("…web Google OAuth puts the JWT in the redirect URL…") to say `still also sent as ?token= until the Phase 3 web is live`. Add the open item `- [ ] Drop ?token= from the Google web callback (controllers/auth.js googleCallback, the line marked LEGACY) once the Phase 3 web (reads ?code=) is live. S`.
```
git add models/OAuthLoginCode.js lib/oauthLoginCode.js controllers/auth.js routes/auth.js test/googleWebLoginCode.test.js docs/REMAINING_WORK.md
git commit -m "feat(auth): Google web login one-time code exchange" -m "The callback put the access JWT in the redirect URL and issued no refresh token. It now also redirects with a random single-use code (SHA-256 stored in a Mongo TTL collection, 60 s); POST /auth/google/exchange {code} returns the standard token pair once (atomic findOneAndDelete; reused/expired/malformed -> 400 OAUTH_CODE_INVALID; banned -> 403). Callback refusals redirect to /auth/callback?error=&reason= instead of a JSON page on the API host. ?token= is kept for the live web.

Still open: remove ?token= after the Phase 3 web ships; web AuthCallback reads code (Phase 3); rest of Phase 1 items 6-8."
```

---

### Task P1-LINK-6: Sign in with Apple on the web — `POST /auth/apple/web` (links#12)

**Depends on Task P1-LINK-4** (`WEB_APPLE_SIGNIN_ENABLED`).

**Files:**
- Modify `controllers/auth.js`: replace the `appleMobileLogin` block, lines 262–414 (from the `/**` above `@desc Apple Sign-In for mobile` up to the line before the `/**` of `@desc Facebook login route`), with the block below. It contains `appleDisplayName`, the shared `appleIdentityLogin`, the unchanged-behaviour `appleMobileLogin`, and the new `appleWebLogin`.
- Modify `routes/auth.js`: import at line 21; route after line 156.
- Test (new): `test/appleWebLogin.test.js`

**Design:**
- **Reuse, not a second copy.** The body of `appleMobileLogin` becomes `appleIdentityLogin(req, res, next, { identityToken, appleUser, authorizationCode, audience, nonce, endpoint, successEvent })`. It covers verify, then ban check, then find by `appleId`, then link by email, then the banned-user check, then create with empty profile defaults, then auto-complete, then `sendTokenResponse`. Mobile passes `audience = APPLE_BUNDLE_ID || 'com.banatalk.app'` and no nonce, so it behaves exactly as before (regression test included). The web endpoint passes `audience = APPLE_WEB_SERVICES_ID` and the page's `nonce`, which `jsonwebtoken` checks against the token's `nonce` claim.
- **The response is the same token pair as other logins:** `{ success, token, refreshToken, user }`.
- **Gate.** The flag is read at request time from `require('../config/limitations')`, the same pattern as `referralsEnabledGuard`. While it is off, the endpoint returns `404 { code: 'feature_disabled' }` before looking at the body. If the flag is on but `APPLE_WEB_SERVICES_ID` is unset, it returns 503 rather than verifying against a wrong audience.
- **Apple JS `user` shape.** Apple JS sends `{ name: { firstName, lastName }, email }` on the first authorization only, and as a JSON string with `response_mode=form_post`. iOS sends `{ fullName: { givenName, familyName } }`. `appleDisplayName` reads both shapes and falls back to `Apple User`.
- **The web `authorizationCode` is not exchanged.** `lib/appleAuthTokens` uses the bundle id as `client_id`, while a web code needs the Services ID. This is a follow-up item: revoking web-only Apple sign-ups on delete.

**Risky inputs, covered by the test:**
- **Hide My Email.** The relay address is stored as the email. `sub` and the relay address are per developer team, so a person who later signs in from the app lands on the same account by `appleId`. This holds only if the Services ID is in the same team and grouped with the app's primary App ID (owner step).
- **No email claim** (any sign-in after the first): new users get `<sub>@privaterelay.appleid.com`, the same as mobile.
- **Existing app user with the same `sub`:** the same account is returned and no duplicate is created.
- **Existing email/password account with the same email:** Apple is linked to it, which is current mobile behaviour. Apple only returns verified addresses. Unlike Google, this code does not check `email_verified`. Noted as a deliberate parity choice.
- **An app token sent to the web endpoint** (audience = bundle id) returns 401. A web token sent to the mobile endpoint also returns 401.
- **Nonce mismatch** (a replayed token) returns 401. A missing or short nonce returns 400.
- **A banned account** returns 403 `ACCOUNT_BANNED` with no tokens.

**Interfaces:**
- `POST /api/v1/auth/apple/web` takes body `{ identityToken: string, nonce: string /^[A-Za-z0-9._~-]{16,128}$/, user?: object|string }` and uses `authLimiter`. Responses: 200 token pair, 400, 401 `Invalid Apple token`, 403 `ACCOUNT_BANNED`, 404 `feature_disabled`, or 503.
- New env var `APPLE_WEB_SERVICES_ID`, the Services ID identifier, for example `com.bananatalk.web`. Owner step.

- [ ] **Step 1: Write the failing test** `test/appleWebLogin.test.js`. It stubs `apple-signin-auth` the same way as `test/authAudit.bannedLogin.test.js`, but the stub enforces `audience` and `nonce` the way `jsonwebtoken` would:
```js
'use strict';
/**
 * links#12 / web parity Phase 1 item 7: Sign in with Apple on the website.
 * POST /auth/apple/web verifies an Apple JS identity token whose audience is
 * the Services ID (APPLE_WEB_SERVICES_ID), checks the nonce the page sent,
 * and returns the same token pair as every other login. 404 while
 * WEB_APPLE_SIGNIN_ENABLED is false.
 */
process.env.APPLE_WEB_SERVICES_ID = 'com.bananatalk.web';
delete process.env.APPLE_BUNDLE_ID; // mobile audience falls back to com.banatalk.app

const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const mongoose = require('mongoose');

// apple-signin-auth is required lazily inside the handler. The stub applies
// the two checks jsonwebtoken would (audience, nonce) to a JSON "token", so
// the test proves the controller passes the right options.
const stubModule = (name, exportsValue) => {
  const resolved = require.resolve(name);
  require.cache[resolved] = { id: resolved, filename: resolved, loaded: true, exports: exportsValue };
};
stubModule('apple-signin-auth', {
  verifyIdToken: async (identityToken, opts = {}) => {
    const p = JSON.parse(identityToken);
    if (opts.audience && p.aud !== opts.audience) throw new Error('jwt audience invalid');
    if (opts.nonce !== undefined && p.nonce !== opts.nonce) throw new Error('jwt nonce invalid');
    return p;
  },
});

const { start, createUser } = require('./helpers/authHarness');
const limitations = require('../config/limitations');

let h;
test.before(async () => { h = await start('appleWebLogin'); });
test.after(async () => { await h.stop(); });
test.beforeEach(() => {
  limitations.WEB_APPLE_SIGNIN_ENABLED = true;
  process.env.APPLE_WEB_SERVICES_ID = 'com.bananatalk.web';
});

const sub = () => `001234.${new mongoose.Types.ObjectId()}.0101`;
const NONCE = 'n-0123456789abcdef0123456789abcdef';
const webToken = (claims) => JSON.stringify({ aud: 'com.bananatalk.web', nonce: NONCE, ...claims });
const web = (body) => request(h.app).post('/api/v1/auth/apple/web').send(body);

test('flag off: 404 feature_disabled, token never inspected', async () => {
  limitations.WEB_APPLE_SIGNIN_ENABLED = false;
  const res = await web({ identityToken: webToken({ sub: sub() }), nonce: NONCE });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'feature_disabled');
});

test('flag on but no Services ID configured: 503, not a silent wrong audience', async () => {
  delete process.env.APPLE_WEB_SERVICES_ID;
  const res = await web({ identityToken: webToken({ sub: sub() }), nonce: NONCE });
  assert.equal(res.status, 503);
});

test('missing identityToken or nonce: 400', async () => {
  assert.equal((await web({ nonce: NONCE })).status, 400);
  assert.equal((await web({ identityToken: webToken({ sub: sub() }) })).status, 400);
  assert.equal((await web({ identityToken: webToken({ sub: sub() }), nonce: 'short' })).status, 400);
});

test('an app token (audience = bundle id) is refused on the web endpoint', async () => {
  const res = await web({ identityToken: JSON.stringify({ aud: 'com.banatalk.app', nonce: NONCE, sub: sub() }), nonce: NONCE });
  assert.equal(res.status, 401);
});

test('nonce mismatch (replayed token): 401', async () => {
  const res = await web({ identityToken: webToken({ sub: sub() }), nonce: 'n-ffffffffffffffffffffffffffffffff' });
  assert.equal(res.status, 401);
});

test('new user, Apple JS name shape, Hide My Email relay: created, token pair returned', async () => {
  const s = sub();
  const relay = `x7${Date.now()}@privaterelay.appleid.com`;
  const res = await web({
    identityToken: webToken({ sub: s, email: relay, email_verified: 'true', is_private_email: 'true' }),
    nonce: NONCE,
    user: { name: { firstName: 'Ada', lastName: 'Lovelace' }, email: relay },
  });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.ok(res.body.token);
  assert.ok(res.body.refreshToken);
  const u = await h.User.findOne({ appleId: s }).lean();
  assert.equal(u.name, 'Ada Lovelace');
  assert.equal(u.email, relay);
  assert.equal(u.profileCompleted, false);
});

test('Apple JS form_post sends `user` as a JSON string: name still read', async () => {
  const s = sub();
  const res = await web({
    identityToken: webToken({ sub: s, email: `p${Date.now()}@privaterelay.appleid.com` }),
    nonce: NONCE,
    user: JSON.stringify({ name: { firstName: 'Grace', lastName: 'Hopper' } }),
  });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal((await h.User.findOne({ appleId: s }).lean()).name, 'Grace Hopper');
});

test('no email claim at all (later sign-ins): placeholder relay address, no crash', async () => {
  const s = sub();
  const res = await web({ identityToken: webToken({ sub: s }), nonce: NONCE });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  const u = await h.User.findOne({ appleId: s }).lean();
  assert.equal(u.email, `${s}@privaterelay.appleid.com`);
  assert.equal(u.name, 'Apple User');
});

test('user who signed up with Apple in the app gets the SAME account on web', async () => {
  const s = sub();
  const existing = await createUser(h.User, { appleId: s, profileCompleted: true });
  const res = await web({ identityToken: webToken({ sub: s }), nonce: NONCE });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal(String(res.body.user._id), String(existing._id));
  assert.equal(await h.User.countDocuments({ appleId: s }), 1);
});

test('existing email account with the same (Apple-verified) email: Apple is linked to it', async () => {
  const existing = await createUser(h.User);
  const s = sub();
  const res = await web({ identityToken: webToken({ sub: s, email: existing.email, email_verified: 'true' }), nonce: NONCE });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal(String(res.body.user._id), String(existing._id));
  assert.equal((await h.User.findById(existing._id).lean()).appleId, s);
});

test('suspended account: 403 ACCOUNT_BANNED, no tokens', async () => {
  const s = sub();
  await createUser(h.User, { appleId: s, isBanned: true, banReason: 'abuse' });
  const res = await web({ identityToken: webToken({ sub: s }), nonce: NONCE });
  assert.equal(res.status, 403);
  assert.equal(res.body.code, 'ACCOUNT_BANNED');
  assert.equal(res.body.token, undefined);
});

test('regression: mobile endpoint still verifies against the bundle id (iOS fullName shape)', async () => {
  const s = sub();
  const res = await request(h.app).post('/api/v1/auth/apple/mobile').send({
    identityToken: JSON.stringify({ aud: 'com.banatalk.app', sub: s }),
    user: { fullName: { givenName: 'Lin', familyName: 'Yu' } },
  });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal((await h.User.findOne({ appleId: s }).lean()).name, 'Lin Yu');
  const webTokenOnMobile = await request(h.app).post('/api/v1/auth/apple/mobile')
    .send({ identityToken: webToken({ sub: sub() }) });
  assert.equal(webTokenOnMobile.status, 401);
});
```
- [ ] **Step 2: Run, expect FAIL (11 of 12; the mobile regression passes).** `node --experimental-test-module-mocks --test --test-force-exit test/appleWebLogin.test.js`. With no route, the endpoint returns a plain 404 without `code`, which gives `undefined !== 'feature_disabled'`, `404 !== 503`, `404 !== 400` and `404 !== 401`.
- [ ] **Step 3: Implement.** `controllers/auth.js`: replace original lines 262–414 with:
```js
/**
 * Display name from the `user` object Apple hands the client on the FIRST
 * sign-in only. iOS (sign_in_with_apple) sends { fullName: { givenName,
 * familyName } }; Apple JS sends { name: { firstName, lastName } }, and as a
 * JSON string when it posts the form (response_mode=form_post).
 */
function appleDisplayName(rawUser) {
  let appleUser = rawUser;
  if (typeof appleUser === 'string') {
    try { appleUser = JSON.parse(appleUser); } catch (_) { appleUser = null; }
  }
  const full = appleUser && appleUser.fullName;
  const web = appleUser && appleUser.name;
  const parts = full ? [full.givenName, full.familyName]
    : web ? [web.firstName, web.lastName] : [];
  const name = parts.filter((p) => typeof p === 'string' && p.trim()).map((p) => p.trim()).join(' ');
  return name || 'Apple User';
}

/**
 * Shared Apple sign-in: verify the identity token, find or link or create the
 * user, refuse suspended accounts, answer with the standard token pair. Used
 * by POST /auth/apple/mobile (audience = bundle id) and POST /auth/apple/web
 * (audience = Services ID). Apple's `sub` is per developer team, so the same
 * person gets the same `sub` from the app and from the website (the Services
 * ID must be grouped with the app's primary App ID — owner step).
 */
async function appleIdentityLogin(req, res, next, {
  identityToken, appleUser, authorizationCode, audience, nonce, endpoint, successEvent,
}) {
  try {
    const appleSignin = require('apple-signin-auth');

    // Verify the identity token with Apple. `audience` is the bundle id for
    // the app and the Services ID for the website; `nonce` (web only) must
    // match the token's nonce claim (jsonwebtoken checks it).
    const appleResponse = await appleSignin.verifyIdToken(identityToken, {
      audience,
      ignoreExpiration: false, // Set to true for development/testing only
      ...(nonce !== undefined ? { nonce } : {}),
    });
    
    const { sub: appleId } = appleResponse;
    const email = appleResponse.email ? normalizeEmail(appleResponse.email) : null;

    const banCheck = await banService.checkBannedIdentity({ appleId, email: email || null });
    if (banCheck.banned) {
      logSecurityEvent('BANNED_IDENTITY_REJECTED', { endpoint });
      return next(new ErrorResponse('This account has been permanently suspended and cannot be reactivated.', 403));
    }

    // Try to find existing user by Apple ID
    let user = await User.findOne({ appleId });
    
    // If not found by Apple ID, try by email (if email was provided)
    if (!user && email) {
      user = await findUserByEmail(User, email);
      
      // If user exists with this email, link Apple account
      if (user) {
        user.appleId = appleId;
        await user.save();
      }
    }
    
    if (user?.isBanned === true) {
      logSecurityEvent('BANNED_USER_LOGIN_REJECTED', { endpoint, userId: user._id });
      return next(bannedError(user));
    }

    // If still no user, create new one
    if (!user) {
      // Apple sends the name only on the very first sign-in (null afterwards).
      const userName = appleDisplayName(appleUser);

      // Generate unique username
      const username = await generateUsername(userName);

      user = await User.create({
        appleId,
        email: email || `${appleId}@privaterelay.appleid.com`, // Apple may hide email
        name: userName || 'Apple User',
        username,
        images: [],
        isEmailVerified: true,
        isRegistrationComplete: true,
        // Empty defaults - user MUST fill these in profile completion
        gender: '',
        bio: '',
        birth_year: '',
        birth_month: '',
        birth_day: '',
        profileCompleted: false,
        native_language: '',
        language_to_learn: '',
        location: {
          type: 'Point',
          coordinates: [0.0, 0.0],
          formattedAddress: '',
          city: '',
          country: ''
        }
      });
      // Note: Admin notification will be sent when user completes their profile
    } else {

      // Existing user - check if profile is actually complete but flag wasn't set
      // Core requirements: gender, birth year, both languages
      // Bio, images, location are optional — don't block login for them
      if (!user.profileCompleted) {
        const hasRealGender = user.gender && user.gender.length > 0;
        const hasRealBirthYear = user.birth_year && user.birth_year.length > 0;
        const hasRealLanguages = user.native_language && user.language_to_learn &&
          user.native_language.length > 0 && user.language_to_learn.length > 0 &&
          user.native_language !== user.language_to_learn;

        const coreFieldsComplete = hasRealGender && hasRealBirthYear && hasRealLanguages;

        if (coreFieldsComplete) {
          console.log(`🔧 Auto-completing profile for existing user ${user._id} - core fields present`);
          user.profileCompleted = true;
          await user.save();
          onProfileCompleted(user, { io: req.app.get('io') }); // welcome wave (flag-gated, fire-and-forget)
        } else {
          console.log(`⚠️ Profile incomplete for ${user._id}: gender=${hasRealGender}, birthYear=${hasRealBirthYear}, languages=${hasRealLanguages}`);
        }
      }
    }

    // Exchange the sign-in authorizationCode for Apple's refresh token and
    // store it, so account deletion/logout can REVOKE it (Apple guideline
    // 5.1.1(v)) — the old flow never captured any user token, which is half
    // of why revocation never worked. Non-blocking and null-safe: older app
    // builds don't send the code, and the exchange needs the .p8 env
    // material (lib/appleAuthTokens) — either way sign-in proceeds as before.
    if (authorizationCode) {
      const { exchangeAppleAuthCode } = require('../lib/appleAuthTokens');
      exchangeAppleAuthCode(authorizationCode)
        .then((refreshToken) => (refreshToken
          ? User.updateOne({ _id: user._id }, { $set: { appleRefreshToken: refreshToken } })
          : null))
        .catch((err) => console.error('⚠️ Apple refresh-token store failed (non-blocking):', err.message));
    }

    const deviceInfo = getDeviceInfo(req);

    // Update lastLogin and lastActivityAt timestamps
    user.lastLogin = new Date();
    user.lastActivityAt = new Date();
    await user.save({ validateBeforeSave: false });

    logSecurityEvent(successEvent, {
      userId: user._id,
      email: user.email,
      ipAddress: deviceInfo.ipAddress
    });

    sendTokenResponse(user, 200, res, req, deviceInfo);
    
  } catch (error) {
    console.error('❌ Apple sign-in error:', error);
    logSecurityEvent('APPLE_AUTH_FAILED', {
      endpoint,
      error: error.message
    });
    return next(new ErrorResponse('Invalid Apple token', 401));
  }
}

/**
 * @desc    Apple Sign-In for mobile (ID token verification)
 * @route   POST /api/v1/auth/apple/mobile
 * @access  Public
 */
exports.appleMobileLogin = asyncHandler(async (req, res, next) => {
  const { identityToken, user: appleUser, authorizationCode } = req.body;

  if (!identityToken) {
    return next(new ErrorResponse('Identity token is required', 400));
  }

  return appleIdentityLogin(req, res, next, {
    identityToken,
    appleUser,
    authorizationCode,
    audience: process.env.APPLE_BUNDLE_ID || 'com.banatalk.app',
    endpoint: 'appleMobileLogin',
    successEvent: 'APPLE_MOBILE_LOGIN_SUCCESS',
  });
});

// Apple JS nonce: the page generates a random string per attempt, passes it
// to AppleID.auth.init({ nonce }) and posts the same string here.
const APPLE_NONCE_RE = /^[A-Za-z0-9._~-]{16,128}$/;

/**
 * @desc    Sign in with Apple on the website (Apple JS identity token)
 * @route   POST /api/v1/auth/apple/web   body { identityToken, nonce, user? }
 * @access  Public — 404 while WEB_APPLE_SIGNIN_ENABLED is false
 *
 * Same response as every other login: { success, token, refreshToken, user }.
 * The web's authorizationCode is NOT exchanged: lib/appleAuthTokens uses the
 * bundle id as client_id, and a code issued to the Services ID needs the
 * Services ID (REMAINING_WORK: revocation for web-only Apple sign-ups).
 */
exports.appleWebLogin = asyncHandler(async (req, res, next) => {
  // Read at request time (not destructured) so tests and a restart flip it.
  if (!require('../config/limitations').WEB_APPLE_SIGNIN_ENABLED) {
    return res.status(404).json({ success: false, error: 'Not found', code: 'feature_disabled' });
  }
  const servicesId = process.env.APPLE_WEB_SERVICES_ID;
  if (!servicesId) {
    console.error('❌ WEB_APPLE_SIGNIN_ENABLED is on but APPLE_WEB_SERVICES_ID is not set');
    return next(new ErrorResponse('Sign in with Apple is not available right now', 503));
  }

  const { identityToken, nonce, user: appleUser } = req.body || {};
  if (typeof identityToken !== 'string' || !identityToken) {
    return next(new ErrorResponse('Identity token is required', 400));
  }
  if (typeof nonce !== 'string' || !APPLE_NONCE_RE.test(nonce)) {
    return next(new ErrorResponse('A valid nonce is required', 400));
  }

  return appleIdentityLogin(req, res, next, {
    identityToken,
    appleUser,
    authorizationCode: null,
    audience: servicesId,
    nonce,
    endpoint: 'appleWebLogin',
    successEvent: 'APPLE_WEB_LOGIN_SUCCESS',
  });
});
```
`routes/auth.js`:
```diff
@@ -19,6 +19,7 @@
   resetPassword,
   googleMobileLogin,
   appleMobileLogin,
+  appleWebLogin,
   deleteAccount,
   makeAdmin,
   acceptTerms
@@ -154,6 +155,7 @@
 router.post('/verifyEmailCode', authLimiter, verifyCodeValidation, validate, verifyCode);
 router.post('/google/mobile', authLimiter, googleMobileLogin);
 router.post('/apple/mobile', authLimiter, appleMobileLogin); 
+router.post('/apple/web', authLimiter, appleWebLogin); // 404 while WEB_APPLE_SIGNIN_ENABLED is false
 // Admin only route - MUST be protected
 router.put('/make-admin/:userId', protect, authorize('admin'), makeAdmin);
```
(Line 156 ends in a trailing space. Keep it, or the context won't match.)
- [ ] **Step 4: Run, expect PASS.** `node --experimental-test-module-mocks --test --test-force-exit test/appleWebLogin.test.js` gives `pass 12`. Regression: `node --experimental-test-module-mocks --test --test-force-exit test/authAudit.bannedLogin.test.js`, `node --experimental-test-module-mocks --test --test-force-exit test/authAudit.emailNormalize.test.js`, `node --experimental-test-module-mocks --test --test-force-exit test/appleAuthTokens.test.js` and `node --experimental-test-module-mocks --test --test-force-exit test/authAudit.oauthEmailVerified.test.js` all pass.
- [ ] **Step 5: Commit.** In REMAINING_WORK, tick `- [x] POST /auth/apple/web (Services ID audience + nonce, shared appleIdentityLogin, 404 while WEB_APPLE_SIGNIN_ENABLED off)`. In owner section 2, add: `Apple web sign-in: create a Services ID in team RJF4T5CJ76, grouped with primary App ID com.bananatalk.bananatalkApp; add domain banatalk.com and the return URL the web uses; set APPLE_WEB_SERVICES_ID on prod; then WEB_APPLE_SIGNIN_ENABLED=true after browser QA`. Add the open item `- [ ] Exchange the web authorizationCode with client_id = Services ID so web-only Apple sign-ups can be revoked on delete (lib/appleAuthTokens). S`.
```
git add controllers/auth.js routes/auth.js test/appleWebLogin.test.js docs/REMAINING_WORK.md
git commit -m "feat(auth): Sign in with Apple for the website (dark)" -m "POST /auth/apple/web verifies an Apple JS identity token for APPLE_WEB_SERVICES_ID with the page's nonce and returns the standard token pair. Shares appleIdentityLogin with the mobile endpoint (unchanged behaviour, regression-tested); reads both Apple JS and iOS name shapes; 404 while WEB_APPLE_SIGNIN_ENABLED is false, 503 if the Services ID is unset.

Still open: owner creates the Services ID + sets APPLE_WEB_SERVICES_ID; web Apple JS button (Phase 4); web authorizationCode exchange for revocation; rest of Phase 1 items 6-8."
```

---

### Task P1-LINK-7: Contract tests for the endpoints the Phase 4 website reuses (spec item 7, §5)

**Files:**
- Test (new): `test/webFeatureContracts.test.js`. No production code changes.

**What the web will call.** Requests are the same shape as the app's Dart clients send. Response fields are the ones the app reads, which is what the web will read too.

| Area | Request (router, all `protect`) | Response fields asserted | Dart source |
|---|---|---|---|
| Reels create | `POST /api/v1/moments` `{description, privacy, category, language, isReel:true}` (`routes/moments.js:75`) | 201 `data._id,user,description,privacy,language,createdAt`, `data.isReel===true` | `moments_providers.dart:160-237` |
| Reels feed | `GET /api/v1/moments/reels?limit=12` (`routes/moments.js:59`, `reelsEnabledGuard`) | `success`, `data[]`, `nextCursor`; each reel `_id,user{_id,name,images},description,video{url,thumbnail,duration},likeCount,commentCount,createdAt,mediaType,language` | `reels_api_client.dart`, `Moments.fromJson` |
| Gatherings | `POST /gatherings` `{title,language,startsAt(ISO UTC),description,durationMinutes,capacity,quorum,joinMode}`; `GET /gatherings?scope=all&page=1`; `GET /gatherings/:id`; `POST`/`DELETE /gatherings/:id/rsvp` | `_id,title,language,startsAt,durationMinutes,capacity,quorum,going,needed,status,joinMode,host,viewerIsHost,viewerIsAttending` | `gathering_api_client.dart:73-264`, `Gathering.fromJson` |
| Clubs | `POST /clubs` `{name,description,language,interest}`; `GET /clubs?scope=all`; `POST`/`DELETE /clubs/:id/join` | `_id,name,description,language,languageLabel,interest,owner,memberCount,members,roleCounts,viewerCanManage,viewerIsMember,viewerIsOwner` | `gathering_api_client.dart:315-557`, `Club.fromJson` |
| Voice rooms + LiveKit | `POST /voicerooms` `{title,topic,language,maxParticipants}`; `GET /voicerooms`; `POST /:id/join`; `POST /:id/token`; `POST /:id/leave` | create `_id,title,topic,language,host,participants,maxParticipants,status`; token `data{token,url,roomName,role}` (`participant`/`host`); token before join returns 403 | `voice_room_provider.dart:140`, `voice_room_livekit_manager.dart:73-85`, `voice_room_manager.dart:489` |
| Language rooms | `POST /rooms` `{title,targetLanguage,description}`; `GET /rooms`; `GET /rooms/:id`; `POST /rooms/:id/join`; `GET /rooms/:id/messages` | `_id,title,roomType,targetLanguage,memberCount,onlineCount,isMember,isOwnerOrAdmin`; messages `data[]` | `room_api_client.dart`, `Room.fromJson` |
| Calls | `POST /calls/initiate` `{receiverId,type}`; `GET /calls/:id`; `GET /calls/current`; `POST /calls/:id/accept` `{}`; `POST /calls/:id/end`; `GET /calls?page=1&limit=20`; `GET /calls/missed/count`; `POST /calls/:id/decline` `{message}` | initiate `data{call{_id,callUuid},token,url,roomName}`; get `status,startTime,type`; current `data.call`; accept `data{token,url,roomName}`; history `data[]`, `pagination.hasMore`; missed `data.count:number`; decline `data.messageDelivered:boolean` | `call/call_api.dart`, `call_manager.dart:1063-1100,1185-1198,1255`, `call_history_service.dart` |

Socket signalling (`call:incoming` and the like) is already covered by `test/callController.test.js` and `test/callEvents.test.js`, so it is not repeated here.

**Stubs.** `services/livekitService` returns a fixed `{token,url}`. `services/livekitAdminService` and `services/callPushService` are replaced with no-ops, and `middleware/rateLimiter`, `utils/sendEmail` and `services/emailService` are replaced by `test/helpers/authHarness`. A fake `io` has `sockets.adapter.rooms` (for `onlineCount`) and `emit` (voice room create). The real routers and `protect` run, with a real JWT from `user.getSignedJwtToken()`.

- [ ] **Step 1: Write the test** `test/webFeatureContracts.test.js`:
```js
'use strict';
/**
 * Web parity spec Phase 1 item 7 / §5: contract tests for the endpoints the
 * Phase 4 website reuses from the app — reels, gatherings + clubs, voice
 * rooms (+ LiveKit token), language rooms, calls. Each test sends the request
 * the web will send (same shape the app's Dart client sends) through the real
 * router + `protect`, and asserts the response fields the client reads
 * (from the app models: Moments.fromJson, Gathering/Club.fromJson,
 * VoiceRoom.fromJson, Room.fromJson, call_manager.dart, call_history_service).
 *
 * These pin CURRENT behaviour: they pass on first run. A failure later means
 * a backend change broke the app and the website at once.
 */
process.env.REELS_ENABLED = 'true';
process.env.GATHERINGS_ENABLED = 'true';
process.env.ROOMS_ENABLED = 'true';
process.env.CONVERSATION_CAP_ENABLED = 'false';

const test = require('node:test');
const assert = require('node:assert/strict');
const { stub } = require('./helpers/authHarness');
const { startDb, stopDb, makeUser, fakeIo, silence } = require('./helpers/callKit');

stub('services/livekitService', {
  mintRoomToken: async ({ identity, roomName }) => ({ token: `tok-${identity}-${roomName}`, url: 'wss://lk.test' }),
});
stub('services/livekitAdminService', {
  endRoom: async () => {}, disconnectParticipant: async () => {},
  countParticipants: async () => ({ ok: true, count: 2, missing: false }),
});
stub('services/callPushService', {
  sendIncomingCall: async () => {}, sendCallCancelled: async () => {}, sendMissedCall: async () => {},
});

const request = require('supertest');
const express = require('express');

let app, io, restore, Moment;

test.before(async () => {
  restore = silence();
  await startDb('webFeatureContracts');
  Moment = require('../models/Moment');
  io = fakeIo();
  io.sockets = { adapter: { rooms: new Map() } };
  io.emit = (event, payload) => { io.sent.push({ rooms: ['*'], event, payload }); return true; };
  require('../lib/callIo').setIo(io);
  app = express();
  app.use(express.json());
  app.set('io', io);
  app.use('/api/v1/moments', require('../routes/moments'));
  app.use('/api/v1/gatherings', require('../routes/gatherings'));
  app.use('/api/v1/clubs', require('../routes/clubs'));
  app.use('/api/v1/voicerooms', require('../routes/voiceRooms'));
  app.use('/api/v1/rooms', require('../routes/rooms'));
  app.use('/api/v1/calls', require('../routes/calls'));
  app.use(require('../middleware/error'));
});
test.after(async () => {
  const svc = require('../services/callStateService');
  const Call = require('../models/Call');
  for (const c of await Call.find({}).select('_id')) svc.clearRingTimer(c._id);
  await stopDb();
  restore();
});

const person = (name) => makeUser(name, {
  userMode: 'regular', timezone: 'UTC', profileCompleted: true,
  native_language: 'English', language_to_learn: 'Korean',
});
const bearer = (u) => ({ Authorization: `Bearer ${u.getSignedJwtToken()}` });
const hasKeys = (obj, keys, where) => {
  for (const k of keys) assert.ok(obj && Object.prototype.hasOwnProperty.call(obj, k), `${where}: missing "${k}" in ${JSON.stringify(obj).slice(0, 300)}`);
};
const TOMORROW = () => new Date(Date.now() + 24 * 3600 * 1000).toISOString();

// ------------------------------------------------------------------ reels
test('reels: POST /moments {isReel:true} -> data._id; GET /moments/reels -> {data:[moment], nextCursor}', async () => {
  const author = await person('reelauthor');
  const viewer = await person('reelviewer');

  const created = await request(app).post('/api/v1/moments').set(bearer(author))
    .send({ description: 'my first reel', privacy: 'public', category: 'general', language: 'ko', isReel: true });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  hasKeys(created.body.data, ['_id', 'user', 'description', 'privacy', 'language', 'createdAt'], 'create reel');
  assert.equal(created.body.data.isReel, true);

  // The web's second step (PUT /moments/:id/video) streams to Spaces; the
  // feed contract is pinned on a stored video instead.
  await Moment.updateOne({ _id: created.body.data._id }, {
    $set: { mediaType: 'video', video: { url: 'https://cdn.test/r.mp4', thumbnail: 'https://cdn.test/r.jpg', duration: 12 } },
  });

  const feed = await request(app).get('/api/v1/moments/reels?limit=12').set(bearer(viewer));
  assert.equal(feed.status, 200, JSON.stringify(feed.body));
  assert.equal(feed.body.success, true);
  assert.ok(Array.isArray(feed.body.data));
  assert.ok('nextCursor' in feed.body);
  const reel = feed.body.data.find((m) => String(m._id) === String(created.body.data._id));
  assert.ok(reel, 'created reel is in the feed');
  hasKeys(reel, ['_id', 'user', 'description', 'video', 'likeCount', 'commentCount', 'createdAt', 'mediaType', 'language'], 'reel');
  hasKeys(reel.user, ['_id', 'name', 'images'], 'reel.user');
  hasKeys(reel.video, ['url', 'thumbnail', 'duration'], 'reel.video');
});

// ------------------------------------------------------------------ gatherings + clubs
test('gatherings: create, list, detail, rsvp, cancel rsvp — fields the gathering card reads', async () => {
  const host = await person('gHost');
  const guest = await person('gGuest');
  const G = ['_id', 'title', 'language', 'startsAt', 'durationMinutes', 'capacity', 'quorum', 'going', 'needed',
    'status', 'joinMode', 'host', 'viewerIsHost', 'viewerIsAttending'];

  const created = await request(app).post('/api/v1/gatherings').set(bearer(host)).send({
    title: 'Korean coffee chat', language: 'Korean', startsAt: TOMORROW(), description: '',
    durationMinutes: 60, capacity: 6, quorum: 3, joinMode: 'open',
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  hasKeys(created.body.data, G, 'create gathering');
  const id = created.body.data._id;

  const list = await request(app).get('/api/v1/gatherings').query({ scope: 'all', page: '1' }).set(bearer(guest));
  assert.equal(list.status, 200, JSON.stringify(list.body));
  assert.ok(Array.isArray(list.body.data));
  hasKeys(list.body.data.find((g) => String(g._id) === String(id)), G, 'list gathering');

  const detail = await request(app).get(`/api/v1/gatherings/${id}`).set(bearer(guest));
  assert.equal(detail.status, 200);
  hasKeys(detail.body.data, G, 'gathering detail');

  const rsvp = await request(app).post(`/api/v1/gatherings/${id}/rsvp`).set(bearer(guest));
  assert.equal(rsvp.status, 200, JSON.stringify(rsvp.body));
  hasKeys(rsvp.body.data, G, 'rsvp');
  assert.equal(rsvp.body.data.viewerIsAttending, true);

  const un = await request(app).delete(`/api/v1/gatherings/${id}/rsvp`).set(bearer(guest));
  assert.equal(un.status, 200, JSON.stringify(un.body));
  assert.equal(un.body.data.viewerIsAttending, false);
});

test('clubs: create, list, join, leave — fields the club card reads', async () => {
  const owner = await person('cOwner');
  const member = await person('cMember');
  const C = ['_id', 'name', 'description', 'language', 'languageLabel', 'interest', 'owner', 'memberCount',
    'members', 'roleCounts', 'viewerCanManage', 'viewerIsMember', 'viewerIsOwner'];

  const created = await request(app).post('/api/v1/clubs').set(bearer(owner))
    .send({ name: 'Seoul readers', description: 'Books', language: 'Korean', interest: 'books' });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  hasKeys(created.body.data, C, 'create club');
  const id = created.body.data._id;

  const list = await request(app).get('/api/v1/clubs').query({ scope: 'all' }).set(bearer(member));
  assert.equal(list.status, 200);
  hasKeys(list.body.data.find((c) => String(c._id) === String(id)), C, 'list club');

  const join = await request(app).post(`/api/v1/clubs/${id}/join`).set(bearer(member));
  assert.equal(join.status, 200, JSON.stringify(join.body));
  assert.equal(join.body.data.viewerIsMember, true);

  const leave = await request(app).delete(`/api/v1/clubs/${id}/join`).set(bearer(member));
  assert.equal(leave.status, 200, JSON.stringify(leave.body));
  assert.equal(leave.body.data.viewerIsMember, false);
});

// ------------------------------------------------------------------ voice rooms
test('voice rooms: create, list, join, token -> {token,url,roomName,role}', async () => {
  const host = await person('vHost');
  const listener = await person('vListener');

  const created = await request(app).post('/api/v1/voicerooms').set(bearer(host))
    .send({ title: 'Evening Korean', topic: 'language_exchange', language: 'Korean', maxParticipants: 8 });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  hasKeys(created.body.data, ['_id', 'title', 'topic', 'language', 'host', 'participants', 'maxParticipants', 'status'], 'create voice room');
  const id = created.body.data._id;

  const list = await request(app).get('/api/v1/voicerooms').set(bearer(listener));
  assert.equal(list.status, 200, JSON.stringify(list.body));
  assert.ok(Array.isArray(list.body.data));
  hasKeys(list.body.data.find((r) => String(r._id) === String(id)), ['_id', 'title', 'language', 'host', 'participants', 'maxParticipants'], 'list voice room');

  const before = await request(app).post(`/api/v1/voicerooms/${id}/token`).set(bearer(listener));
  assert.equal(before.status, 403, 'token requires /join first');

  const join = await request(app).post(`/api/v1/voicerooms/${id}/join`).set(bearer(listener));
  assert.equal(join.status, 200, JSON.stringify(join.body));

  const tok = await request(app).post(`/api/v1/voicerooms/${id}/token`).set(bearer(listener));
  assert.equal(tok.status, 200, JSON.stringify(tok.body));
  hasKeys(tok.body.data, ['token', 'url', 'roomName', 'role'], 'voice room token');
  assert.equal(tok.body.data.role, 'participant');

  const hostTok = await request(app).post(`/api/v1/voicerooms/${id}/token`).set(bearer(host));
  assert.equal(hostTok.body.data.role, 'host');

  const leave = await request(app).post(`/api/v1/voicerooms/${id}/leave`).set(bearer(listener));
  assert.equal(leave.status, 200, JSON.stringify(leave.body));
});

// ------------------------------------------------------------------ language rooms
test('language rooms: create topic room, list, detail, join, messages', async () => {
  const owner = await person('rOwner');
  const other = await person('rOther');
  const ROOM_FIELDS = ['_id', 'title', 'roomType', 'targetLanguage', 'memberCount', 'onlineCount', 'isMember', 'isOwnerOrAdmin'];

  const created = await request(app).post('/api/v1/rooms').set(bearer(owner))
    .send({ title: 'K-drama talk', targetLanguage: 'ko', description: 'drama' });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  hasKeys(created.body.data, ROOM_FIELDS, 'create room');
  const id = created.body.data._id;

  const list = await request(app).get('/api/v1/rooms').set(bearer(other));
  assert.equal(list.status, 200, JSON.stringify(list.body));
  assert.ok(Array.isArray(list.body.data));
  hasKeys(list.body.data.find((r) => String(r._id) === String(id)), ROOM_FIELDS, 'list room');

  const detail = await request(app).get(`/api/v1/rooms/${id}`).set(bearer(other));
  assert.equal(detail.status, 200, JSON.stringify(detail.body));
  hasKeys(detail.body.data, ['_id', 'title', 'roomType', 'targetLanguage'], 'room detail');

  const join = await request(app).post(`/api/v1/rooms/${id}/join`).set(bearer(other));
  assert.equal(join.status, 200, JSON.stringify(join.body));

  const msgs = await request(app).get(`/api/v1/rooms/${id}/messages`).set(bearer(other));
  assert.equal(msgs.status, 200, JSON.stringify(msgs.body));
  assert.ok(Array.isArray(msgs.body.data));
});

// ------------------------------------------------------------------ calls
test('calls: initiate -> {call:{_id,callUuid}, token, url, roomName}; accept -> token; end; history; missed count; current', async () => {
  const caller = await person('callA');
  const callee = await person('callB');

  const init = await request(app).post('/api/v1/calls/initiate').set(bearer(caller))
    .send({ receiverId: String(callee._id), type: 'video' });
  assert.equal(init.status, 200, JSON.stringify(init.body));
  hasKeys(init.body.data, ['call', 'token', 'url', 'roomName'], 'initiate');
  hasKeys(init.body.data.call, ['_id', 'callUuid'], 'initiate.call');
  const callId = String(init.body.data.call._id);

  const peek = await request(app).get(`/api/v1/calls/${callId}`).set(bearer(callee));
  assert.equal(peek.status, 200, JSON.stringify(peek.body));
  hasKeys(peek.body.data, ['status', 'startTime', 'type'], 'GET /calls/:id');

  const cur = await request(app).get('/api/v1/calls/current').set(bearer(callee));
  assert.equal(cur.status, 200);
  hasKeys(cur.body.data, ['call'], 'current');

  const acc = await request(app).post(`/api/v1/calls/${callId}/accept`).set(bearer(callee)).send({});
  assert.equal(acc.status, 200, JSON.stringify(acc.body));
  hasKeys(acc.body.data, ['token', 'url', 'roomName'], 'accept');

  const end = await request(app).post(`/api/v1/calls/${callId}/end`).set(bearer(caller));
  assert.equal(end.status, 200, JSON.stringify(end.body));

  const hist = await request(app).get('/api/v1/calls').query({ page: '1', limit: '20' }).set(bearer(caller));
  assert.equal(hist.status, 200, JSON.stringify(hist.body));
  assert.ok(Array.isArray(hist.body.data));
  hasKeys(hist.body, ['pagination'], 'history');
  hasKeys(hist.body.pagination, ['hasMore'], 'history.pagination');

  const missed = await request(app).get('/api/v1/calls/missed/count').set(bearer(callee));
  assert.equal(missed.status, 200);
  assert.equal(typeof missed.body.data.count, 'number');
});

test('calls: decline with a message -> data.messageDelivered is a boolean', async () => {
  const caller = await person('decA');
  const callee = await person('decB');
  const init = await request(app).post('/api/v1/calls/initiate').set(bearer(caller))
    .send({ receiverId: String(callee._id), type: 'audio' });
  assert.equal(init.status, 200, JSON.stringify(init.body));
  const dec = await request(app).post(`/api/v1/calls/${init.body.data.call._id}/decline`).set(bearer(callee))
    .send({ message: 'In a meeting, call you later' });
  assert.equal(dec.status, 200, JSON.stringify(dec.body));
  assert.equal(typeof dec.body.data.messageDelivered, 'boolean');
});
```
- [ ] **Step 2: Run.** `node --experimental-test-module-mocks --test --test-force-exit test/webFeatureContracts.test.js`. **Expected: PASS (7/7) on the first run.** These are characterisation tests that pin current behaviour, so there is no red step. To check that they can fail, temporarily rename `roomName` to `room` in the `res.status(200).json` of `controllers/voiceRooms.js:406-414`. The voice-rooms test should then fail with `voice room token: missing "roomName"`. Revert before committing.
- [ ] **Step 3: Commit.** In REMAINING_WORK, tick `- [x] Contract tests for web-reused endpoints (reels, gatherings, clubs, voice rooms + token, language rooms, calls) — test/webFeatureContracts.test.js`. Add the open item `- [ ] Extend webFeatureContracts when Phase 4 web adds a call not listed there (e.g. reel video upload PUT /moments/:id/video, voice room promote/status, gathering host decisions). S`.
```
git add test/webFeatureContracts.test.js docs/REMAINING_WORK.md
git commit -m "test(contracts): pin the endpoints the website will reuse" -m "Real routers + protect on mongodb-memory-server: reels create/feed, gatherings, clubs, voice rooms + LiveKit token, language rooms, calls (initiate/accept/decline/end/history/missed/current). Request shapes and response fields come from the app's Dart clients, so a break shows up for app and web alike.

Still open: extend as Phase 4 adds calls (video upload, host controls); rest of Phase 1 items 6-8."
```

---

### Task P1-LINK-8: Remove leftover wrong-domain references from docs (links#19)

`git grep -n -I "bananatalk\.com"` was run in all three repos on 2026-10-16. Here is what it found and what to do with each hit.

| Repo | File:line | Action |
|---|---|---|
| backend | `docs/superpowers/specs/2026-06-07-flame-merge-design.md:9,174-181,332,377` | Change `api.bananatalk.com` to `api.banatalk.com`, 11 occurrences |
| backend | `middleware/webhookAuth.js:138` | Code, already fixed by P1-LINK-3 |
| app | `docs/VOICE_MESSAGES.md:436` | Change `https://api.bananatalk.com/api/v1/messages/voice` to `https://api.banatalk.com/api/v1/messages/voice` |
| app | `docs/qa/regression-suite.csv:439` (row PROF-068) | Change `support@bananatalk.com` to `bananatalkmain@gmail.com`. That is the address the app shows (`helpEmailSupportSubtitle` in every ARB) and the backend uses (`utils/emailTemplates.js:9`) |
| app | `android/app/google-services.json*`, `"bundle_id": "com.bananatalk.com"` | **Leave.** It is a Firebase iOS bundle-id string, not a domain |
| app | `docs/audits/2026-10-16-web-parity/*.md`, the spec | **Leave.** They describe the bug |
| app | `lib/pages/stories/viewer/story_viewer_screen.dart:736` | **Not here.** App code, fixed in Phase 2 (story share) |
| web | none in docs | Nothing to commit. Re-run the grep to confirm. The two `http://banatalk.com` links in `src/components/navbar/PrivacyPolicy.tsx:322` and `DataDeletion.tsx:165` are code (they redirect 301 to https). They go in the Phase 3 links push |

**Files:**
- Backend: `docs/superpowers/specs/2026-06-07-flame-merge-design.md`, `docs/REMAINING_WORK.md`
- App: `docs/VOICE_MESSAGES.md`, `docs/qa/regression-suite.csv`, `docs/REMAINING_WORK.md`
- Test: a grep check (docs only, no unit test)

- [ ] **Step 1: Failing check (backend).**
`cd /Users/davis/Desktop/Personal/be-integration && git grep -n -I "bananatalk\.com" -- docs`
Expected: 11 hits in `2026-06-07-flame-merge-design.md`.
- [ ] **Step 2: Fix (backend).**
`sed -i '' 's/api\.bananatalk\.com/api.banatalk.com/g' docs/superpowers/specs/2026-06-07-flame-merge-design.md`
- [ ] **Step 3: Re-run, expect no output.** `git grep -n -I "bananatalk\.com" -- docs`
- [ ] **Step 4: Commit (backend, docs only, so add `[skip ci]`).** In REMAINING_WORK, tick `- [x] Wrong-domain (bananatalk.com) references removed from docs`.
```
git add docs/superpowers/specs/2026-06-07-flame-merge-design.md docs/REMAINING_WORK.md
git commit -m "docs: api.banatalk.com, not the parked bananatalk.com [skip ci]" -m "Flame merge spec still named api.bananatalk.com in 11 places.

Still open: rest of Phase 1 items 6-8 (see REMAINING_WORK)."
```
- [ ] **Step 5: Failing check (app).**
`cd /Users/davis/Desktop/Personal/bt-integration/bananatalk_app && git grep -n -I "bananatalk\.com" -- docs ':!docs/audits' ':!docs/superpowers'`
Expected: `docs/VOICE_MESSAGES.md:436` and `docs/qa/regression-suite.csv:439`.
- [ ] **Step 6: Fix (app).**
```
sed -i '' 's#https://api\.bananatalk\.com/api/v1/messages/voice#https://api.banatalk.com/api/v1/messages/voice#' docs/VOICE_MESSAGES.md
sed -i '' 's/(support@bananatalk\.com)/(bananatalkmain@gmail.com)/' docs/qa/regression-suite.csv
```
- [ ] **Step 7: Re-run, expect no output.** Run the Step 5 command again. Also check that the CSV still parses with the same row count: `python3 -c "import csv;print(sum(1 for _ in csv.reader(open('docs/qa/regression-suite.csv'))))"`. Run it before and after, and the two numbers must match.
- [ ] **Step 8: Commit (app).** In the app's `docs/REMAINING_WORK.md` §4, tick `- [x] Wrong-domain references in docs (VOICE_MESSAGES curl, PROF-068 support address)`. Keep the story-share item open for Phase 2.
```
git add docs/VOICE_MESSAGES.md docs/qa/regression-suite.csv docs/REMAINING_WORK.md
git commit -m "docs: banatalk.com API host and the real support address" -m "VOICE_MESSAGES curl used api.bananatalk.com; PROF-068 expected support@bananatalk.com, the app shows bananatalkmain@gmail.com.

Still open: story share URL (Phase 2, story_viewer_screen.dart:736); web http://banatalk.com links in PrivacyPolicy/DataDeletion (Phase 3 links push)."
```
- [ ] **Step 9: Web, verify only.** `cd /Users/davis/Desktop/Personal/language_exchange_web_front && git grep -n -I "bananatalk\.com"` should print nothing. There is no commit. Web `main` deploys live, and a docs-only change isn't worth a deploy.

---

## Not in this plan (belongs elsewhere)
- nginx crawler rule for `/(moment|profile|community|story|i)/` → `/og/...`. Web `deploy/nginx.snippet.conf` plus the owner, in Phase 5.
- Web consumers: `AuthCallback` reads `code` and calls `/auth/google/exchange`; Apple JS button; reading the `web*Enabled` flags. Phases 3 and 4.
- Apple Services ID, `APPLE_WEB_SERVICES_ID`, and the `GOOGLE_PUBSUB_AUDIENCE`/`DOMAIN` check. Owner steps, written into backend REMAINING_WORK §2 by tasks 3, 4 and 6.

