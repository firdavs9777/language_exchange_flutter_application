# Web ↔ App Parity — Phase 3 (website bug fixes) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every Phase 3 bullet of the spec on banatalk.com (chat, moments, community, links), so a web user and an app user can chat, see each other's moments and stories, and find each other with nothing broken, missing or leaked, and links between banatalk.com and the app work.

**Architecture:** Four push units, each built in its own worktree off one shared base commit, each ending in a push gate (full Jest suite + `npm run build` green, then the coordinator pushes, which deploys). Order of pushes: CHAT → MOMENTS → COMMUNITY → LINKS. Units can be developed in parallel; each later unit rebases onto the freshly pushed `origin/main` before its gate. Everything is a client-side fix against the Phase 1 backend contract. No new web feature is flagged here (that is Phase 4).

**Tech Stack:** React 18 + TypeScript **3.7.2** (CRA 5 / react-scripts), RTK Query (`apiSlice.injectEndpoints`), socket.io-client 4, react-i18next (18 locale JSON files in `src/utils/locales/`), react-toastify, react-helmet-async, Jest + React Testing Library.

**Spec:** `bananatalk_app/docs/superpowers/specs/2026-10-16-web-app-parity-design.md` §3 Phase 3. **Audits:** `bananatalk_app/docs/audits/2026-10-16-web-parity/{chat,moments,community,links}.md` (findings cited as `chat#3`, `moments#21`, …). **Master plan:** `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity.md` (Phase 0–1; the backend contract this plan consumes is defined by its P1-* tasks).

## Global Constraints

- **Web deploys on push to `main`** (`.github/workflows/deploy.yml`). Never push without a green full suite and a green `npm run build` in the worktree you push from. Only the coordinator pushes, only at a unit's push step.
- **Baseline:** web `origin/main` = `fba6208` (Phase 0, deployed). Local `main` of `/Users/davis/Desktop/Personal/language_exchange_web_front` is stale (502663f); never branch from it. Baseline suite: 244 suites passed / 1 skipped, 3190 tests passed / 6 skipped, ~18 s.
- **Precondition:** Phase 1 backend is merged and deployed before the first Phase 3 push (spec §3: phases run in order). Check: `curl -s https://api.banatalk.com/api/v1/app-config | grep -o '"webReelsEnabled":[a-z]*'` prints `"webReelsEnabled":false`. Every task still keeps working against the **pre-Phase-1** backend where that costs one fallback line (e.g. `followersCount ?? followers.length`, `media.type ?? messageType`), so a backend rollback never breaks the site.
- **Legacy data:** messages, moments and stories written by app 2.6.1 and by the old website stay readable: unpopulated `sender`/`receiver` (bare id string), no `media.type` on list previews, waves stored as `messageType:'sticker'` sentences, `call`/`location` media, `story_share`, no `deletedForEveryone`, relative storage paths in `images[]`.
- **TypeScript 3.7.2:** no `import type`, no `export * as ns`, no `satisfies`, no template-literal types, no labelled/variadic tuples. `?.` and `??` are fine. Slices keep the house style (`builder: any`, hooks re-exported `as any`).
- **Strings:** every new user-facing string goes through `t("<ns>.<key>") || "English fallback"`. Each task adds its English to `src/utils/locales/eng.json` in its own commit. The other 17 locales are filled once per unit by that unit's `*-I18N` task through `scripts/i18n/merge-keys.js` (which refuses partial input), before the unit's push. No unit is pushed with English-only keys.
- **RTL (`ar`):** new layout uses logical properties (`margin-inline-start`, `padding-inline-end`, `inset-inline-*`, `text-align: start`). Story/overlay coordinates are fractions of the canvas and are **never** mirrored.
- **Tests:** TDD per task. Single file: `CI=true npm test -- --watchAll=false <pattern>`. Full: `CI=true npm test -- --watchAll=false`. Build: `npm run build` (CRA build + `scripts/prerender.js`). Copy mocks from the neighbouring test file named in each task; do not invent new global mocks.
- **Commits:** one per task. `git add` explicit paths (never `-A` inside a unit) plus `docs/REMAINING_WORK.md`, which each commit edits: tick the task's own `- [ ] P3-…` line, and end the body with `Still open (Phase 3 <unit>): …`. **No `Co-Authored-By`, no AI attribution** in commits or PRs.
- **Tracker:** the web repo's `docs/REMAINING_WORK.md`, section "Web/app parity". Task P3-0 replaces the four coarse "Phase 3 …" lines with one line per task, so each task can tick its own.
- **Node modules:** each worktree symlinks the main checkout's `node_modules` (as Phase 0 did). Do not `npm install` new packages in Phase 3; nothing here needs one.

## Review Focus

Five inputs most likely to bite real users. Reviewers check each unit against these before its push step.

1. **Messages from app 2.6.1 and the old website, with legacy fields.** A wave stored as a 200-char `sticker`, a `call` row with `media:{type:'call', callData}` and empty `message`, a `location` row with empty `message`, `story_share` with no thumbnail, a `sender` that is a bare id string (unpopulated emit before P1-CHAT-5 deploys), a list `lastMessage` without `media.type` (before P1-CHAT-7), "Conversation started" rows already in prod. None may render as "File", giant text, the wrong side, or a blank bubble. Pinned by P3-CHAT-6, -10…-13 tests that use these exact fixtures.
2. **RTL locales (`ar`) and mixed-direction text.** New banners, dialogs, chips and the edited/forwarded labels must sit on the logical side. Emoji-only detection must ignore bidi marks (U+200E/U+200F) and variation selectors. Story overlays and mention boxes keep their fractional coordinates. Pinned by the RTL cases in P3-CHAT-12 and the story placement tests (P3-MOM story tasks).
3. **Slow, dropped or kicked sockets.** Ack > 5 s on a slow link (no REST double-send any more: the bubble goes failed + Retry, and a late ack/`messageSent` replaces the optimistic bubble instead of adding a second), laptop sleep then wake (page 1 + conversations refetched on re-`connect`), the 6th tab getting `forceDisconnect`, `tokenExpired` mid-session (refresh, then reconnect, no logout). Pinned by P3-CHAT-5 and P3-CHAT-7.
4. **Missing or odd media.** Relative storage paths and deleted Spaces objects (`images[0]`, avatars in waves/nearby → `photoUrl` + `onError` fallback), a story id that expired or was deleted (`/story/:id` shows an "unavailable" state, not a blank page), a missing `storyReference.thumbnail`, recording on Safari < 18.4 (`MediaRecorder` with an unsupported `mimeType` must never throw), the GIF provider failing, a comment photo upload failing after the text posted. Pinned by P3-CHAT-9/13, P3-MOM recorder/comment tasks, P3-LINK story page tests.
5. **Signed-out and blocked viewers.** `/profile/:id`, `/moment/:id`, `/story/:id`, `/i/:code` opened from a chat app by someone with no account: no crash on absent follower arrays (read `followersCount`), no action buttons that 401, a smart banner/app banner that opens *this* page in the app. A viewer in a block relationship gets the minimal card and a 403 on follow → a localized toast, not a raw error. Pinned by P3-COM profile task and P3-LINK banner/story tasks.

## Execution

1. Coordinator: Task P3-0 (shared base branch with the per-task tracker lines).
2. Four worktrees off `web/p3-base`, worked in parallel (one implementer each, tasks in order inside a unit):
   - CHAT `/Users/davis/Desktop/Personal/wt-web-p3-chat` (branch `web/p3-chat`)
   - MOMENTS `/Users/davis/Desktop/Personal/wt-web-p3-moments` (branch `web/p3-moments`)
   - COMMUNITY `/Users/davis/Desktop/Personal/wt-web-p3-community` (branch `web/p3-community`)
   - LINKS `/Users/davis/Desktop/Personal/wt-web-p3-links` (branch `web/p3-links`)
3. Pushes in order CHAT → MOMENTS → COMMUNITY → LINKS, each through its `*-PUSH` task. A later unit rebases on the new `origin/main` first. Expected rebase conflicts and their resolution are listed in each push task (only `eng.json`/other locale files, `docs/REMAINING_WORK.md`, and `src/utils/recorderMime.ts` if both CHAT and MOMENTS created it).
4. After LINKS is pushed: the owner applies `deploy/nginx.snippet.conf` (Phase 5). Phase 3 is done when the four units are deployed and every `P3-` line in the tracker is ticked or moved to an owner/device line.

---

### Task P3-0: Shared base branch with per-task tracker lines

**Files:**
- Modify: `docs/REMAINING_WORK.md` (web repo), section "Web/app parity (spec: …)": the four lines starting `- [ ] Phase 3 Chat:`, `- [ ] Phase 3 Moments:`, `- [ ] Phase 3 Community:`, `- [ ] Phase 3 Links:`.

- [ ] **Step 1: Base worktree on origin/main**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
git fetch origin
git log origin/main --oneline -1          # expect fba6208 or a later deployed commit
git worktree add -b web/p3-base /Users/davis/Desktop/Personal/wt-web-p3-base origin/main
cd /Users/davis/Desktop/Personal/wt-web-p3-base
ln -s /Users/davis/Desktop/Personal/language_exchange_web_front/node_modules node_modules
```

- [ ] **Step 2: Replace the four coarse lines with per-task lines**

Replace each coarse `- [ ] Phase 3 <Area>: …` line with a sub-heading and the lines below (exact text; tasks tick them):

```markdown
Phase 3 Chat (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md`)
- [ ] P3-CHAT-1 Edit sends `{message}`, in an in-app dialog, with the failure shown (chat#1, chat#19)
- [ ] P3-CHAT-2 Delete sends body `{deleteForEveryone}`, asks in a dialog, and "deleted for everyone" leaves a placeholder (chat#2, chat#15, chat#19)
- [ ] P3-CHAT-3 Opening a chat never posts "Conversation started" (chat#3)
- [ ] P3-CHAT-4 Limit, paywall and block refusals open a dialog instead of a bare "Failed" (chat#4)
- [ ] P3-CHAT-5 A slow socket ack marks the bubble failed with Retry; no REST fallback, no duplicates (chat#5)
- [ ] P3-CHAT-6 Conversation list from `GET /conversations` only; typed previews; unread from the server (chat#10, chat#11, chat#19)
- [ ] P3-CHAT-7 Catch up after a reconnect; recover a kicked tab; refresh instead of logging out on `tokenExpired` (chat#12, chat#20)
- [ ] P3-CHAT-8 Videos go through `POST /messages/video` with the server's limits checked first (chat#16)
- [ ] P3-CHAT-9 Voice recorder picks a type the browser supports (AAC first), names the file to match, and sends a waveform (chat#13)
- [ ] P3-CHAT-10 App call-history messages render as a call card, not "File" (chat#6)
- [ ] P3-CHAT-11 Location messages render as a map card, and the web can send one (chat#7, chat#17)
- [ ] P3-CHAT-12 Waves are a greeting card, only 1–3 emoji are sticker-sized, and a bare-id sender lands on the right side (chat#8)
- [ ] P3-CHAT-13 Story shares, replies and reactions keep their story (chat#9)
- [ ] P3-CHAT-14 Live pins, the "edited" label, the "Forwarded" chip and every correction (chat#14)
- [ ] P3-CHAT-15 The app's six premium wallpapers render on web (chat#18)
- [ ] P3-CHAT-16 Search the messages of a conversation (chat#17)
- [ ] P3-CHAT-17 Saved (bookmarked) messages: list, open, unbookmark (chat#17)
- [ ] P3-CHAT-18 Archive / unarchive conversations, and mute for 1 hour, 8 hours, 1 week or always (chat#17)
- [ ] P3-CHAT-19 "You can't message this person" banner when either side blocked (chat#17)
- [ ] P3-CHAT-20 The chat's remaining hard-coded English goes through `t()` (chat#19)
- [ ] P3-CHAT-I18N New chat strings in all 18 locales
- [ ] P3-CHAT-PUSH Push unit chat (suite + build green, deployed, production smoke recorded)

Phase 3 Moments (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md`)
- [ ] P3-MOM-1 Post and save photo-, video- or voice-only moments (moments#4)
- [ ] P3-MOM-2 The app's 20 moment gradients, same colours (moments#5)
- [ ] P3-MOM-3 Remove the Title field from the composer (moments#6)
- [ ] P3-MOM-4 The moment's owner can delete other people's comments (moments#9)
- [ ] P3-MOM-5 Report a comment, and block an author from a moment or a comment (moments#10, moment/comment part)
- [ ] P3-MOM-6 Saved moments load every page and draw every kind of moment (moments#11)
- [ ] P3-MOM-7 Feed cards show mood, tags and location (moments#22)
- [ ] P3-MOM-8 Comments with a GIF, a photo and no text, and mentions drawn (moments#21)
- [ ] P3-MOM-9 Leftovers: `uploadMomentPhotos` typing, no `mediaType: "text"`, dead `reportMoment` (moments#23)
- [ ] P3-MOM-10 Moment voice notes record `audio/mp4` where the browser can (moments#2)
- [ ] P3-MOM-11 Moments text in every language: Saved Moments keys and hard-coded English (moments#24)
- [ ] P3-MOM-12 a story carries one picture (moments#16)
- [ ] P3-MOM-13 the story viewer shows the story's location (moments#17)
- [ ] P3-MOM-14 report a story and block its author from the viewer (moments#10, story part)
- [ ] P3-MOM-15 text-story font style and overlay faces match the app (moments#25)
- [ ] P3-MOM-16 solid and semi plates match the app (moments#25)
- [ ] P3-MOM-17 overlays honour rotation; centring stays exact; mention pills look like the app's (moments#25)
- [ ] P3-MOM-18 the viewer shows a story's hashtags (moments#25)
- [ ] P3-MOM-19 the viewer honours `allowReplies` and `allowSharing` (moments#25)
- [ ] P3-MOM-20 the link sticker always shows the real host under its label (moments#25)
- [ ] P3-MOM-I18N New moments strings in all 18 locales
- [ ] P3-MOM-PUSH Push unit moments (suite + build green, deployed, production smoke recorded)

Phase 3 Community (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md`)
- [ ] P3-COM-1 Nearby works — real params, real fields, real profile route, privacy toggles (community#2)
- [ ] P3-COM-2 @username search uses the `/auth/users` routes (community#3)
- [ ] P3-COM-3 Language filter offers the whole catalog, labelled in the reader's language (community#4)
- [ ] P3-COM-4 Waves inbox — archive, reveal, loadable avatars, a real "Find people" route (community#10)
- [ ] P3-COM-5 Wave cap answers with a VIP dialog, not a raw English toast (community#8)
- [ ] P3-COM-6 "Serious learners" segment tab (`activeWithin=7d`) (community#9)
- [ ] P3-COM-7 Smart sort by default when the server offers it; reciprocal ("perfect partners") filter (community#9)
- [ ] P3-COM-8 "More members like X" asks for people who speak X's language (community#11)
- [ ] P3-COM-9 Today marks a card "Waved" after a wave (community#14)
- [ ] P3-COM-10 Delete the dead community endpoints and wave shims (community#12)
- [ ] P3-COM-11 Profile counts from `followersCount` for signed-out visitors; story ring from `hasActiveStory` (community#6, links#11)
- [ ] P3-COM-12 Blocked viewers see a neutral card; follow refused by a block says so (community#5)
- [ ] P3-COM-13 Community copy through `t()`, and a test that every key exists (community#13)
- [ ] P3-COM-I18N New community strings in all 18 locales
- [ ] P3-COM-PUSH Push unit community (suite + build green, deployed, production smoke recorded)

Phase 3 Links (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md`)
- [ ] P3-LINK-1 Crawler rule sends link-preview bots to the backend OG cards (links#4, links#17, moments#13)
- [ ] P3-LINK-2 AASA stops claiming `/chat/*` and web-only pages (links#6, links#15)
- [ ] P3-LINK-3 Smart banner and app banner open the page being viewed (links#16)
- [ ] P3-LINK-4 `/story/:id` page — the target of story share links (links#1, moments#1)
- [ ] P3-LINK-5 Google sign-in reads the one-time `code` (links#12)
- [ ] P3-LINK-6 Legal pages link to https://banatalk.com (links#19)
- [ ] P3-LINK-7 Chat story cards open `/story/:id` (chat#9 follow-up, links#1)
- [ ] P3-LINK-I18N New links strings in all 18 locales
- [ ] P3-LINK-PUSH Push unit links (suite + build green, deployed, production smoke recorded)
```

- [ ] **Step 3: Commit**

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: split Phase 3 parity work into per-task tracker lines

One line per Phase 3 task (chat, moments, community, links) so each
commit can tick its own item.

Still open (Phase 3): every P3- line; Phase 4 features; bundle budget.
EOF
```

- [ ] **Step 4: Unit worktrees off the base**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
for u in chat moments community links; do
  git worktree add -b web/p3-$u /Users/davis/Desktop/Personal/wt-web-p3-$u web/p3-base
  ln -s /Users/davis/Desktop/Personal/language_exchange_web_front/node_modules /Users/davis/Desktop/Personal/wt-web-p3-$u/node_modules
done
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false 2>&1 | tail -5
```
Expected: `Tests: 6 skipped, 3190 passed` (or the counts of the current `origin/main`). Not pushed now: the tracker commit travels with the CHAT push.

---

## Unit CHAT (push 1 of 4) — P3-CHAT-1 … P3-CHAT-20, P3-CHAT-I18N, P3-CHAT-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p3-chat`, branch `web/p3-chat` (from `web/p3-base`). One implementer, tasks
in number order: 1–9 change the contract, sending, the list and sync; 10–20 build on them (rendering, features, the
remaining strings). Task 6 rewrites `UsersList.tsx`; tasks 10 and 18 anchor on the code task 6 keeps.

Unit-level facts:
- Works against today's backend and Phase 1: edit `{message}` and delete body `{deleteForEveryone}` were already
  accepted before Phase 1; list previews fall back from `media.type` to `messageType` (P1-CHAT-7); a bare-id `sender`
  is normalised (P1-CHAT-5); unread starts from the server count (P1-CHAT-4).
- Behaviour changes users will notice: block/cap refusals now show dialogs (P1-CHAT-1 makes the backend refuse); the
  conversation list no longer shows conversations that exist only as raw messages without a Conversation record (same
  as the app); "deleted for everyone" shows the placeholder for the session, and after a reload the message is gone on
  both sides (P1-CHAT-3 filters `deletedFor`).
- `src/utils/recorderMime.ts` (P3-CHAT-9) is shared with MOMENTS (P3-MOM-10). Its API is fixed by P3-CHAT-9.
- Archive (P3-CHAT-18) exists only on web; the app lists archived chats normally. Product decision recorded as open.

### Task P3-CHAT-1: Edit sends `{message}`, in an in-app dialog, with the failure shown (chat#1, chat#19)

**Files:**
- Modify: `src/store/slices/chatSlice.ts:236-243` (`editMessage` endpoint)
- Create: `src/components/chat/actions/EditMessageDialog.tsx`
- Modify: `src/components/chat/ChatContent.tsx:1657-1675` (`handleEditMessageAction`, which calls `window.prompt`) and the render block before `{/* Forward dialog */}` (`:2292`)
- Modify: `src/utils/locales/eng.json` (`chatPage.editDialog.*`)
- Test: `src/store/slices/chatActionsEndpoints.test.ts` (add one case), `src/components/chat/actions/EditMessageDialog.test.tsx` (new), `src/components/chat/ChatContent.test.tsx` (add two cases, change one mock line)

**Interfaces:**
- Consumes: `PUT /api/v1/messages/:id` body `{message}` (`be/controllers/messageManagement.js:12-18`, validator `editMessageValidation`). Pre-Phase-1 only `message` is read, so `{content}` (today's web) always 400s "Message content is required". Post-Phase-1 (P1-CHAT-6) `content` is also accepted; `{message}` works on both. Errors: 400 `{error:"Message can only be edited within 15 minutes"}`, 400 "Cannot edit deleted message", 403 "Not authorized to edit this message", 400 "Message cannot exceed 2000 characters". Success emits `messageEdited` (already handled at `ChatContent.tsx:597`).
- Produces: `editMessage({messageId, message})` (the arg key changes from `content` to `message`; ChatContent is the only caller — `grep -rn "editMessage(" src`). `EditMessageDialog` default export, props `{ initialText: string; busy: boolean; error: string; onSave(text: string): void; onCancel(): void }`, testids `edit-message-dialog`, `edit-message-input`, `edit-message-save`, `edit-message-cancel`, `edit-message-error`. `editErrorText(err, t)` named export from the same file.

- [ ] **Step 1: Write the failing tests**

Append to `src/store/slices/chatActionsEndpoints.test.ts`, inside the existing `describe("chatSlice message-action endpoints hit the REAL backend routes", ...)` block (it already has `mockFetch`/`makeStore`):

```ts
  it("editMessage -> PUT /api/v1/messages/:id with {message} (the field the backend reads)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).editMessage.initiate({ messageId: "msg-1", message: "fixed" })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/msg-1`);
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({ message: "fixed" });
  });
```

Create `src/components/chat/actions/EditMessageDialog.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import EditMessageDialog, { editErrorText } from "./EditMessageDialog";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const t = () => "";

function renderDialog(props: any = {}) {
  const onSave = jest.fn();
  const onCancel = jest.fn();
  render(
    <EditMessageDialog
      initialText="helo"
      busy={false}
      error=""
      onSave={onSave}
      onCancel={onCancel}
      {...props}
    />
  );
  return { onSave, onCancel };
}

it("starts with the message text and saves the trimmed edit", () => {
  const { onSave } = renderDialog();
  const input = screen.getByTestId("edit-message-input") as HTMLTextAreaElement;
  expect(input.value).toBe("helo");
  fireEvent.change(input, { target: { value: "  hello  " } });
  fireEvent.click(screen.getByTestId("edit-message-save"));
  expect(onSave).toHaveBeenCalledWith("hello");
});

it("cannot save an empty or unchanged text", () => {
  const { onSave } = renderDialog();
  expect(screen.getByTestId("edit-message-save")).toBeDisabled();
  fireEvent.change(screen.getByTestId("edit-message-input"), { target: { value: "   " } });
  expect(screen.getByTestId("edit-message-save")).toBeDisabled();
  fireEvent.click(screen.getByTestId("edit-message-save"));
  expect(onSave).not.toHaveBeenCalled();
});

it("caps the text at the backend's 2000 characters", () => {
  renderDialog();
  expect(screen.getByTestId("edit-message-input")).toHaveAttribute("maxLength", "2000");
});

it("shows the failure inside the dialog and locks it while saving", () => {
  renderDialog({ busy: true, error: "You can only edit a message within 15 minutes of sending it." });
  expect(screen.getByTestId("edit-message-error")).toHaveTextContent("15 minutes");
  expect(screen.getByTestId("edit-message-cancel")).toBeDisabled();
});

it("cancels", () => {
  const { onCancel } = renderDialog();
  fireEvent.click(screen.getByTestId("edit-message-cancel"));
  expect(onCancel).toHaveBeenCalled();
});

describe("editErrorText", () => {
  it("names the 15-minute window", () => {
    expect(
      editErrorText({ status: 400, data: { success: false, error: "Message can only be edited within 15 minutes" } }, t)
    ).toBe("You can only edit a message within 15 minutes of sending it.");
  });
  it("falls back to a generic line for anything else, never the raw validator text", () => {
    expect(editErrorText({ status: 400, data: { error: "Message content is required" } }, t)).toBe(
      "Couldn't edit the message. Try again."
    );
    expect(editErrorText(undefined, t)).toBe("Couldn't edit the message. Try again.");
  });
});
```

In `src/components/chat/ChatContent.test.tsx`:
- add `const mockEditMessage = jest.fn();` next to `const mockCreateMessage = jest.fn();` (line 22),
- in the `jest.mock("../../store/slices/chatSlice", ...)` factory replace `useEditMessageMutation: () => mutation(),` with `useEditMessageMutation: () => [mockEditMessage, { isLoading: false }],`,
- in `beforeEach` add `mockEditMessage.mockReturnValue({ unwrap: () => Promise.resolve({ success: true, data: {} }) });`,
- append:

```tsx
// --- Editing a message -----------------------------------------------------
//
// The web sent PUT /messages/:id {content}; the backend reads `message`, so
// every edit was a 400 that only reached the console. And it asked through
// window.prompt, which a browser can suppress and no locale can style.

/** One message of mine, sent just now, already in the thread. */
function threadWithMyMessage() {
  mockGetConversation.mockReturnValue({
    data: {
      data: [
        {
          _id: "m-mine",
          message: "helo",
          messageType: "text",
          sender: { _id: "me", name: "Me" },
          receiver: "u2",
          createdAt: new Date().toISOString(),
        },
      ],
      total: 1,
    },
    error: undefined,
    isLoading: false,
  });
}

function openActionsOn(id: string) {
  const bubble = document.querySelector(`[data-msg-id="${id}"]`) as HTMLElement;
  fireEvent.contextMenu(bubble);
}

it("edits in an in-app dialog and sends the field the backend reads", async () => {
  const promptSpy = jest.spyOn(window, "prompt").mockImplementation(() => null);
  threadWithMyMessage();
  renderChat("/chat/u2");
  await waitFor(() => expect(document.querySelector('[data-msg-id="m-mine"]')).not.toBe(null));

  openActionsOn("m-mine");
  fireEvent.click(screen.getByTestId("action-edit"));

  expect(promptSpy).not.toHaveBeenCalled();
  fireEvent.change(screen.getByTestId("edit-message-input"), { target: { value: "hello" } });
  fireEvent.click(screen.getByTestId("edit-message-save"));

  await waitFor(() =>
    expect(mockEditMessage).toHaveBeenCalledWith({ messageId: "m-mine", message: "hello" })
  );
  await waitFor(() => expect(screen.queryByTestId("edit-message-dialog")).not.toBeInTheDocument());
  expect(document.querySelector('[data-msg-id="m-mine"]')).toHaveTextContent("hello");
  promptSpy.mockRestore();
});

it("keeps the dialog open and says why when the 15 minutes are up", async () => {
  mockEditMessage.mockReturnValue({
    unwrap: () =>
      Promise.reject({ status: 400, data: { success: false, error: "Message can only be edited within 15 minutes" } }),
  });
  threadWithMyMessage();
  renderChat("/chat/u2");
  await waitFor(() => expect(document.querySelector('[data-msg-id="m-mine"]')).not.toBe(null));

  openActionsOn("m-mine");
  fireEvent.click(screen.getByTestId("action-edit"));
  fireEvent.change(screen.getByTestId("edit-message-input"), { target: { value: "hello" } });
  fireEvent.click(screen.getByTestId("edit-message-save"));

  await waitFor(() =>
    expect(screen.getByTestId("edit-message-error")).toHaveTextContent("within 15 minutes")
  );
  expect(document.querySelector('[data-msg-id="m-mine"]')).toHaveTextContent("helo");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatActionsEndpoints EditMessageDialog ChatContent.test
```
Expected: FAIL. The endpoint test gets body `{"content":"fixed"}`. `EditMessageDialog` cannot be resolved. The ChatContent edit tests cannot find `edit-message-input` (the old code calls `window.prompt`, which the spy answers with `null`).

- [ ] **Step 3: Implement**

`src/store/slices/chatSlice.ts`, replace:

```ts
    editMessage: builder.mutation({
      query: ({ messageId, content }: { messageId: string; content: string }) => ({
        url: `${MESSAGES_URL}/${messageId}`,
        method: "PUT",
        body: { content },
      }),
      invalidatesTags: ["Conversation"],
    }),
```
with:
```ts
    // PUT /api/v1/messages/:id {message}. `message` is the field the backend
    // validator and controller read (controllers/messageManagement.js
    // editMessage); the old `{content}` body was a 400 on every edit.
    editMessage: builder.mutation({
      query: ({ messageId, message }: { messageId: string; message: string }) => ({
        url: `${MESSAGES_URL}/${messageId}`,
        method: "PUT",
        body: { message },
      }),
      invalidatesTags: ["Conversation"],
    }),
```

Create `src/components/chat/actions/EditMessageDialog.tsx`:

```tsx
import React, { useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import DialogShell from "../../../design/DialogShell";

/** The backend's own cap (controllers/messageManagement.js editMessage). */
export const EDIT_MAX_LENGTH = 2000;

type Translate = (key: string, options?: any) => string;

/**
 * What to tell the writer when an edit is refused. Only the 15-minute window
 * is worth naming — it is the one refusal a person can understand and stop
 * trying; everything else (validator text, 403, network) reads as "try again".
 */
export function editErrorText(err: any, t: Translate): string {
  const raw = String((err && err.data && (err.data.error || err.data.message)) || "");
  if (/15 minutes/i.test(raw)) {
    return (
      t("chatPage.editDialog.tooLate") ||
      "You can only edit a message within 15 minutes of sending it."
    );
  }
  return t("chatPage.editDialog.failed") || "Couldn't edit the message. Try again.";
}

export interface EditMessageDialogProps {
  initialText: string;
  busy: boolean;
  error: string;
  onSave: (text: string) => void;
  onCancel: () => void;
}

/** Replaces window.prompt: same rules as the app's edit sheet (non-empty, changed, <= 2000). */
const EditMessageDialog: React.FC<EditMessageDialogProps> = ({
  initialText,
  busy,
  error,
  onSave,
  onCancel,
}) => {
  const { t } = useTranslation();
  const [text, setText] = useState(initialText || "");
  const inputRef = useRef<HTMLTextAreaElement | null>(null);
  const trimmed = text.trim();
  const canSave = !busy && trimmed.length > 0 && trimmed !== (initialText || "").trim();

  return (
    <DialogShell
      labelledBy="edit-message-title"
      onClose={onCancel}
      testId="edit-message-dialog"
      backdropTestId="edit-message-backdrop"
      initialFocusRef={inputRef}
      dismissible={!busy}
    >
      <h2 id="edit-message-title" className="font-display text-base text-ink-900 dark:text-ink-50">
        {t("chatPage.editDialog.title") || "Edit message"}
      </h2>
      <textarea
        ref={inputRef}
        data-testid="edit-message-input"
        aria-label={t("chatPage.editDialog.label") || "Message"}
        value={text}
        maxLength={EDIT_MAX_LENGTH}
        rows={4}
        dir="auto"
        onChange={(e) => setText(e.target.value)}
        className="mt-3 w-full rounded-card border border-line bg-surface px-3 py-2 text-sm text-ink-900 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50"
      />
      {error ? (
        <div
          data-testid="edit-message-error"
          role="alert"
          className="mt-3 rounded-card border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-500/40 dark:bg-red-500/10 dark:text-red-300"
        >
          {error}
        </div>
      ) : null}
      <div className="mt-4 flex justify-end gap-2">
        <button
          type="button"
          data-testid="edit-message-cancel"
          onClick={onCancel}
          disabled={busy}
          className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 disabled:opacity-50 dark:border-line-dark dark:text-ink-200"
        >
          {t("chatPage.editDialog.cancel") || "Cancel"}
        </button>
        <button
          type="button"
          data-testid="edit-message-save"
          onClick={() => canSave && onSave(trimmed)}
          disabled={!canSave}
          aria-busy={busy}
          className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white disabled:opacity-50"
        >
          {t("chatPage.editDialog.save") || "Save"}
        </button>
      </div>
    </DialogShell>
  );
};

export default EditMessageDialog;
```

`src/components/chat/ChatContent.tsx`:
1. Imports: below `import ForwardDialog from "./actions/ForwardDialog";` add
   `import EditMessageDialog, { editErrorText } from "./actions/EditMessageDialog";`
2. State: below `const [forwardMsg, setForwardMsg] = useState<Message | null>(null);` add
```tsx
  const [editingMsg, setEditingMsg] = useState<Message | null>(null);
  const [editBusy, setEditBusy] = useState(false);
  const [editError, setEditError] = useState("");
```
3. Replace the whole `handleEditMessageAction` (`:1657-1675`, from `const handleEditMessageAction = useCallback(` through `[editMessage, t]\n  );`) with:
```tsx
  // Opens the edit dialog; the save itself is handleEditSave.
  const handleEditMessageAction = useCallback((msg: Message) => {
    setEditError("");
    setEditingMsg(msg);
  }, []);

  const handleEditSave = useCallback(
    (text: string) => {
      const target = editingMsg;
      if (!target) return;
      setEditBusy(true);
      setEditError("");
      editMessage({ messageId: target._id, message: text })
        .unwrap()
        .then(() => {
          const patch = { message: text, isEdited: true, editedAt: new Date().toISOString() };
          setMessages((prev) => prev.map((m) => (m._id === target._id ? { ...m, ...patch } : m)));
          patchInThread(target._id, patch as Partial<Message>, selectedUserRef.current);
          setEditingMsg(null);
        })
        .catch((err: any) => setEditError(editErrorText(err, t as any)))
        .then(() => setEditBusy(false));
    },
    [editingMsg, editMessage, patchInThread, t]
  );
```
4. Render: directly above `{/* Forward dialog */}` add
```tsx
      {editingMsg && (
        <EditMessageDialog
          initialText={editingMsg.message || ""}
          busy={editBusy}
          error={editError}
          onSave={handleEditSave}
          onCancel={() => {
            if (!editBusy) setEditingMsg(null);
          }}
        />
      )}
```

`src/utils/locales/eng.json`, inside `"chatPage": {`, add (alongside `"deleteModal"`):
```json
    "editDialog": {
      "title": "Edit message",
      "label": "Message",
      "save": "Save",
      "cancel": "Cancel",
      "tooLate": "You can only edit a message within 15 minutes of sending it.",
      "failed": "Couldn't edit the message. Try again."
    },
```

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatActionsEndpoints EditMessageDialog ChatContent MessageActionMenu
```
Expected: all suites pass (the two `ChatContent` suites included).

- [ ] **Step 5: Commit** (tick `P3-CHAT-1`)

```bash
git add src/store/slices/chatSlice.ts src/store/slices/chatActionsEndpoints.test.ts \
  src/components/chat/actions/EditMessageDialog.tsx src/components/chat/actions/EditMessageDialog.test.tsx \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): editing a message sends {message} and asks in a dialog

The backend reads `message`; the web sent `content`, so every edit was a
400 that only reached the console. The edit now goes in an in-app dialog
(2000-char cap, no empty/unchanged save) instead of window.prompt, and a
refusal stays in the dialog -- the 15-minute window is named.

Still open (Phase 3 chat): P3-CHAT-2..20 (delete body + placeholder,
no "Conversation started", send-error dialogs, no REST after slow ack,
conversation list, reconnect, video, voice MIME, rendering, search,
bookmarks, archive, mute, blocked banner, wallpapers) and the chat i18n pass.
EOF
```

---

### Task P3-CHAT-2: Delete sends body `{deleteForEveryone}`, asks in a dialog, and "deleted for everyone" leaves a placeholder (chat#2, chat#15, chat#19)

**Files:**
- Modify: `src/store/slices/chatSlice.ts:244-250` (`deleteMessage`)
- Create: `src/components/chat/actions/DeleteMessageDialog.tsx`
- Modify: `src/components/chat/actions/MessageActionMenu.tsx:77-78,167-174` (Delete only on my own messages, one label)
- Modify: `src/components/chat/MessageBubble.tsx:59-84` (`Message` type) and `:196-202` (placeholder branch)
- Modify: `src/components/chat/ChatContent.tsx:525-528` (`handleMessageDeleted`), `:1677-1693` (`handleDeleteMessageAction`, which calls `window.confirm`), render block
- Modify: `src/components/chat/ChatContent.css` (one rule), `src/utils/locales/eng.json` (`chatPage.deleteMessage.*`)
- Test: `chatActionsEndpoints.test.ts` (one case), `actions/DeleteMessageDialog.test.tsx` (new), `actions/MessageActionMenu.test.tsx` (one case changes), `MessageBubble.test.tsx` (one case), `ChatContent.test.tsx` (three cases)

**Interfaces:**
- Consumes: `DELETE /api/v1/messages/:id` JSON body `{deleteForEveryone: boolean}` (`be/controllers/messageManagement.js:101-103`). Works before Phase 1 (body is the only thing read) and after (P1-CHAT-2 also reads `?forEveryone=true`, only a boolean `true` in the body counts). Only the sender may delete at all (403 otherwise). "For everyone" only within 1 hour (400 "Message can only be deleted for everyone within 1 hour"). Socket `messageDeleted {messageId, deletedForEveryone: true, message}` to both sides, or `{messageId, deletedForEveryone: false, deletedFor: 'me'}` to my other devices.
- Produces: `deleteMessage({messageId, forEveryone})` (same arg names, new wire shape). `Message.isDeleted?`, `Message.deletedForEveryone?` on the shared type (CHAT-10+ bubble branches must keep the placeholder branch first). `DeleteMessageDialog` props `{ canDeleteForEveryone: boolean; busy: boolean; error: string; onDelete(forEveryone: boolean): void; onCancel(): void }`, testids `delete-message-dialog`, `delete-for-me`, `delete-for-everyone`, `delete-message-cancel`, `delete-message-error`; bubble testid `message-deleted-placeholder`.

- [ ] **Step 1: Write the failing tests**

`chatActionsEndpoints.test.ts` (same describe block):

```ts
  it("deleteMessage -> DELETE /api/v1/messages/:id with a JSON body, no query flag", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).deleteMessage.initiate({ messageId: "msg-1", forEveryone: true })
    );
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/msg-1`);
    expect(url.search).toBe("");
    expect(calls[0].method).toBe("DELETE");
    expect(JSON.parse(calls[0].body as string)).toEqual({ deleteForEveryone: true });
  });

  it("deleteMessage for me sends deleteForEveryone:false (a real boolean)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).deleteMessage.initiate({ messageId: "msg-2" })
    );
    expect(JSON.parse(calls[0].body as string)).toEqual({ deleteForEveryone: false });
  });
```

Create `src/components/chat/actions/DeleteMessageDialog.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import DeleteMessageDialog, { deleteErrorText } from "./DeleteMessageDialog";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

function renderDialog(props: any = {}) {
  const onDelete = jest.fn();
  const onCancel = jest.fn();
  render(
    <DeleteMessageDialog
      canDeleteForEveryone
      busy={false}
      error=""
      onDelete={onDelete}
      onCancel={onCancel}
      {...props}
    />
  );
  return { onDelete, onCancel };
}

it("offers both choices inside the hour", () => {
  const { onDelete } = renderDialog();
  fireEvent.click(screen.getByTestId("delete-for-everyone"));
  expect(onDelete).toHaveBeenCalledWith(true);
  fireEvent.click(screen.getByTestId("delete-for-me"));
  expect(onDelete).toHaveBeenCalledWith(false);
});

it("offers only 'for me' once the hour is over", () => {
  renderDialog({ canDeleteForEveryone: false });
  expect(screen.queryByTestId("delete-for-everyone")).not.toBeInTheDocument();
  expect(screen.getByTestId("delete-for-me")).toBeInTheDocument();
});

it("locks while the request runs and shows its failure", () => {
  renderDialog({ busy: true, error: "Couldn't delete the message. Try again." });
  expect(screen.getByTestId("delete-for-me")).toBeDisabled();
  expect(screen.getByTestId("delete-message-cancel")).toBeDisabled();
  expect(screen.getByTestId("delete-message-error")).toHaveTextContent("Couldn't delete");
});

it("names the one-hour window", () => {
  const t = () => "";
  expect(
    deleteErrorText({ data: { error: "Message can only be deleted for everyone within 1 hour" } }, t)
  ).toBe("You can only delete a message for everyone within 1 hour of sending it.");
  expect(deleteErrorText({ status: 500 }, t)).toBe("Couldn't delete the message. Try again.");
});
```

`MessageActionMenu.test.tsx`: replace the body of `it('hides Edit for a partner message', ...)` with:

```tsx
it('hides Edit and Delete for a partner message (the backend lets only the sender delete)', () => {
  render(<MessageActionMenu {...baseProps} message={partnerMessage} meId="me" />);
  expect(screen.queryByTestId('action-edit')).not.toBeInTheDocument();
  expect(screen.queryByTestId('action-delete')).not.toBeInTheDocument();
});
```
and in `it('shows Edit for an editable own text message', ...)` change the second expectation to
`expect(screen.getByTestId('action-delete')).toHaveTextContent('Delete');`.

`MessageBubble.test.tsx` — append:

```tsx
it("draws a placeholder for a message deleted for everyone, with no actions", () => {
  const { props } = renderBubble({
    message: message({ isDeleted: true, deletedForEveryone: true, message: "This message was deleted" } as any),
  });
  expect(screen.getByTestId("message-deleted-placeholder")).toHaveTextContent("This message was deleted");
  fireEvent.contextMenu(document.querySelector('[data-msg-id="m1"]') as HTMLElement);
  expect(props.onOpenActions).not.toHaveBeenCalled();
});
```

`ChatContent.test.tsx`:
- add `const mockDeleteMessage = jest.fn();`, replace the factory line `useDeleteMessageMutation: () => mutation(),` with `useDeleteMessageMutation: () => [mockDeleteMessage, { isLoading: false }],`, and in `beforeEach` add `mockDeleteMessage.mockReturnValue({ unwrap: () => Promise.resolve({ success: true, data: {} }) });`
- append (reuses `threadWithMyMessage`, `openActionsOn`, `silentSocket` from this file):

```tsx
// --- Deleting a message ----------------------------------------------------

it("deletes for everyone with the body flag and leaves the app's placeholder", async () => {
  const confirmSpy = jest.spyOn(window, "confirm").mockImplementation(() => true);
  threadWithMyMessage();
  renderChat("/chat/u2");
  await waitFor(() => expect(document.querySelector('[data-msg-id="m-mine"]')).not.toBe(null));

  openActionsOn("m-mine");
  fireEvent.click(screen.getByTestId("action-delete"));
  expect(confirmSpy).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("delete-for-everyone"));

  await waitFor(() =>
    expect(mockDeleteMessage).toHaveBeenCalledWith({ messageId: "m-mine", forEveryone: true })
  );
  await waitFor(() => expect(screen.getByTestId("message-deleted-placeholder")).toBeInTheDocument());
  confirmSpy.mockRestore();
});

it("delete for me removes the bubble", async () => {
  threadWithMyMessage();
  renderChat("/chat/u2");
  await waitFor(() => expect(document.querySelector('[data-msg-id="m-mine"]')).not.toBe(null));

  openActionsOn("m-mine");
  fireEvent.click(screen.getByTestId("action-delete"));
  fireEvent.click(screen.getByTestId("delete-for-me"));

  await waitFor(() =>
    expect(mockDeleteMessage).toHaveBeenCalledWith({ messageId: "m-mine", forEveryone: false })
  );
  await waitFor(() => expect(document.querySelector('[data-msg-id="m-mine"]')).toBe(null));
});

it("turns a message the other person deleted for everyone into the placeholder", async () => {
  const s = silentSocket();
  mockUseSocket.mockReturnValue(s.value);
  mockGetConversation.mockReturnValue({
    data: {
      data: [{ _id: "m-theirs", message: "oops", sender: { _id: "u2", name: "Ada" }, receiver: "me", createdAt: new Date().toISOString() }],
      total: 1,
    },
    error: undefined,
    isLoading: false,
  });
  renderChat("/chat/u2");
  await waitFor(() => expect(document.querySelector('[data-msg-id="m-theirs"]')).not.toBe(null));

  act(() => {
    s.handlers["messageDeleted"].forEach((fn) =>
      fn({ messageId: "m-theirs", deletedForEveryone: true, message: { _id: "m-theirs", message: "This message was deleted", isDeleted: true } })
    );
  });

  await waitFor(() => expect(screen.getByTestId("message-deleted-placeholder")).toBeInTheDocument());
  expect(document.querySelector('[data-msg-id="m-theirs"]')).not.toBe(null);
});
```
(add `act` to the `@testing-library/react` import at the top of the file.)

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatActionsEndpoints DeleteMessageDialog MessageActionMenu MessageBubble ChatContent.test
```
Expected: FAIL — endpoint URL carries `?forEveryone=true` and no body; `DeleteMessageDialog` missing; the partner menu still shows Delete; no placeholder testid; ChatContent calls `window.confirm`; the socket handler filters the bubble out.

- [ ] **Step 3: Implement**

`chatSlice.ts`, replace:
```ts
    deleteMessage: builder.mutation({
      query: ({ messageId, forEveryone = false }: { messageId: string; forEveryone?: boolean }) => ({
        url: `${MESSAGES_URL}/${messageId}?forEveryone=${forEveryone}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Conversation"],
    }),
```
with:
```ts
    // DELETE /api/v1/messages/:id {deleteForEveryone}. The backend reads the
    // JSON body (the app's shape); the old ?forEveryone= query was ignored
    // before backend P1-CHAT-2, so "for everyone" deleted for the web user only.
    deleteMessage: builder.mutation({
      query: ({ messageId, forEveryone = false }: { messageId: string; forEveryone?: boolean }) => ({
        url: `${MESSAGES_URL}/${messageId}`,
        method: "DELETE",
        body: { deleteForEveryone: forEveryone === true },
      }),
      invalidatesTags: ["Conversation"],
    }),
```

Create `src/components/chat/actions/DeleteMessageDialog.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import DialogShell from "../../../design/DialogShell";

type Translate = (key: string, options?: any) => string;

export function deleteErrorText(err: any, t: Translate): string {
  const raw = String((err && err.data && (err.data.error || err.data.message)) || "");
  if (/within 1 hour/i.test(raw)) {
    return (
      t("chatPage.deleteMessage.tooLate") ||
      "You can only delete a message for everyone within 1 hour of sending it."
    );
  }
  return t("chatPage.deleteMessage.failed") || "Couldn't delete the message. Try again.";
}

export interface DeleteMessageDialogProps {
  canDeleteForEveryone: boolean;
  busy: boolean;
  error: string;
  onDelete: (forEveryone: boolean) => void;
  onCancel: () => void;
}

/** Replaces window.confirm. The same two choices as the app's delete sheet. */
const DeleteMessageDialog: React.FC<DeleteMessageDialogProps> = ({
  canDeleteForEveryone,
  busy,
  error,
  onDelete,
  onCancel,
}) => {
  const { t } = useTranslation();
  const button =
    "w-full rounded-chip px-3 py-2 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50";
  return (
    <DialogShell
      labelledBy="delete-message-title"
      onClose={onCancel}
      testId="delete-message-dialog"
      backdropTestId="delete-message-backdrop"
      dismissible={!busy}
    >
      <h2 id="delete-message-title" className="font-display text-base text-ink-900 dark:text-ink-50">
        {t("chatPage.deleteMessage.title") || "Delete message?"}
      </h2>
      {error ? (
        <div
          data-testid="delete-message-error"
          role="alert"
          className="mt-3 rounded-card border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-500/40 dark:bg-red-500/10 dark:text-red-300"
        >
          {error}
        </div>
      ) : null}
      <div className="mt-4 flex flex-col gap-2">
        {canDeleteForEveryone && (
          <button
            type="button"
            data-testid="delete-for-everyone"
            disabled={busy}
            onClick={() => onDelete(true)}
            className={`${button} bg-red-600 text-white hover:bg-red-700`}
          >
            {t("chatPage.deleteMessage.forEveryone") || "Delete for everyone"}
          </button>
        )}
        <button
          type="button"
          data-testid="delete-for-me"
          disabled={busy}
          onClick={() => onDelete(false)}
          className={`${button} border border-red-300 text-red-700 dark:border-red-500/40 dark:text-red-300`}
        >
          {t("chatPage.deleteMessage.forMe") || "Delete for me"}
        </button>
        <button
          type="button"
          data-testid="delete-message-cancel"
          disabled={busy}
          onClick={onCancel}
          className={`${button} border border-line text-ink-700 dark:border-line-dark dark:text-ink-200`}
        >
          {t("chatPage.deleteMessage.cancel") || "Cancel"}
        </button>
      </div>
    </DialogShell>
  );
};

export default DeleteMessageDialog;
```

`MessageActionMenu.tsx`: replace
```tsx
  const showEdit = canEdit(message, meId);
  const canDeleteEveryone = canDeleteForEveryone(message, meId);
```
with
```tsx
  const showEdit = canEdit(message, meId);
  // The backend lets only the sender delete (403 for anyone else), so the
  // item is offered on my own messages only; the dialog picks me/everyone.
  const sender: any = message && message.sender;
  const isMine = (typeof sender === "string" ? sender : sender && sender._id) === meId;
```
and replace the Delete `ActionItem` (`testId="action-delete"`) with:
```tsx
        {isMine && (
          <ActionItem
            testId="action-delete"
            icon={<Trash2 size={16} className="text-red-600 dark:text-red-400" />}
            tint="bg-red-100 dark:bg-red-900/40"
            label="Delete"
            danger
            onClick={withClose(onDelete)}
          />
        )}
```
Remove `canDeleteForEveryone` from the `'../lib/messageActions'` import there (now unused; CRA's lint fails the CI build on unused imports only as warnings, but keep it clean).

`MessageBubble.tsx`:
- in `export interface Message`, after `pinned?: boolean;` add
```ts
  /** Deleted for everyone (the server rewrites `message` to "This message was deleted"). */
  isDeleted?: boolean;
  deletedForEveryone?: boolean;
```
- directly after the `if (msg.message === "Conversation started") { ... }` block (ends `:202`), add:
```tsx
  // Deleted for everyone: the app draws "This message was deleted" in place
  // (text_message_view.dart). No actions, no reactions, no media -- the
  // server already removed the file.
  if (msg.isDeleted || msg.deletedForEveryone) {
    return (
      <div
        data-msg-id={msg._id}
        className={`modern-message ${isSent ? "sent" : "received"}${messageGapClass(position, isFirstInGroup)}`}
      >
        {!isSent && <div className="message-avatar message-avatar--hidden" />}
        <div className="message-wrapper">
          <div
            className={`message-bubble message-bubble--deleted${bubblePositionClass(position)}`}
            data-testid="message-deleted-placeholder"
          >
            {t("chatPage.deleteMessage.placeholder") || "This message was deleted"}
          </div>
        </div>
      </div>
    );
  }
```

`ChatContent.css` — append:
```css
.message-bubble--deleted {
  font-style: italic;
  opacity: 0.7;
}
```

`ChatContent.tsx`:
1. Import below the EditMessageDialog import:
   `import DeleteMessageDialog, { deleteErrorText } from "./actions/DeleteMessageDialog";`
2. State below the edit state:
```tsx
  const [deletingMsg, setDeletingMsg] = useState<Message | null>(null);
  const [deleteBusy, setDeleteBusy] = useState(false);
  const [deleteError, setDeleteError] = useState("");
```
3. Add at module level, below `const MESSAGE_PAGE_SIZE = 50;` (module level so the socket effect and the callbacks can use it without a dependency):
```tsx
// "Deleted for everyone" stays on screen as the app's placeholder; only
// "deleted for me" removes the bubble.
const DELETED_PATCH: Partial<Message> = {
  isDeleted: true,
  deletedForEveryone: true,
  message: "This message was deleted",
  media: undefined,
  reactions: [],
};
```
4. Replace `handleMessageDeleted` (`:525-528`):
```tsx
    const handleMessageDeleted = (data: { messageId: string }) => {
      setMessages((prev) => prev.filter((msg) => msg._id !== data.messageId));
      forgetFromThread(data.messageId, selectedUserRef.current);
    };
```
with:
```tsx
    const handleMessageDeleted = (data: {
      messageId: string;
      deletedForEveryone?: boolean;
    }) => {
      if (!data || !data.messageId) return;
      const id = String(data.messageId);
      if (data.deletedForEveryone) {
        setMessages((prev) => prev.map((m) => (m._id === id ? { ...m, ...DELETED_PATCH } : m)));
        patchInThread(id, DELETED_PATCH, selectedUserRef.current);
        return;
      }
      // Deleted for me on another of my devices.
      setMessages((prev) => prev.filter((msg) => msg._id !== id));
      forgetFromThread(id, selectedUserRef.current);
    };
```
5. Replace `handleDeleteMessageAction` (`:1677-1693`, the block that calls `window.confirm`) with:
```tsx
  const handleDeleteMessageAction = useCallback((msg: Message) => {
    setDeleteError("");
    setDeletingMsg(msg);
  }, []);

  const handleDeleteConfirm = useCallback(
    (forEveryone: boolean) => {
      const target = deletingMsg;
      if (!target) return;
      setDeleteBusy(true);
      setDeleteError("");
      deleteMessageApi({ messageId: target._id, forEveryone })
        .unwrap()
        .then(() => {
          if (forEveryone) {
            setMessages((prev) =>
              prev.map((m) => (m._id === target._id ? { ...m, ...DELETED_PATCH } : m))
            );
            patchInThread(target._id, DELETED_PATCH, selectedUserRef.current);
          } else {
            setMessages((prev) => prev.filter((m) => m._id !== target._id));
            forgetFromThread(target._id, selectedUserRef.current);
          }
          setDeletingMsg(null);
        })
        .catch((err: any) => setDeleteError(deleteErrorText(err, t as any)))
        .then(() => setDeleteBusy(false));
    },
    [deletingMsg, deleteMessageApi, forgetFromThread, patchInThread, t]
  );
```
6. Render, below the `EditMessageDialog` block from P3-CHAT-1:
```tsx
      {deletingMsg && (
        <DeleteMessageDialog
          canDeleteForEveryone={canDeleteForEveryone(deletingMsg, userId || "")}
          busy={deleteBusy}
          error={deleteError}
          onDelete={handleDeleteConfirm}
          onCancel={() => {
            if (!deleteBusy) setDeletingMsg(null);
          }}
        />
      )}
```
(`canDeleteForEveryone` is already imported at `:32`.)

`eng.json`, in `chatPage`:
```json
    "deleteMessage": {
      "title": "Delete message?",
      "forEveryone": "Delete for everyone",
      "forMe": "Delete for me",
      "cancel": "Cancel",
      "placeholder": "This message was deleted",
      "tooLate": "You can only delete a message for everyone within 1 hour of sending it.",
      "failed": "Couldn't delete the message. Try again."
    },
```

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatActionsEndpoints DeleteMessageDialog MessageActionMenu MessageBubble ChatContent
```

- [ ] **Step 5: Commit** (tick `P3-CHAT-2`)

```bash
git add src/store/slices/chatSlice.ts src/store/slices/chatActionsEndpoints.test.ts \
  src/components/chat/actions/DeleteMessageDialog.tsx src/components/chat/actions/DeleteMessageDialog.test.tsx \
  src/components/chat/actions/MessageActionMenu.tsx src/components/chat/actions/MessageActionMenu.test.tsx \
  src/components/chat/MessageBubble.tsx src/components/chat/MessageBubble.test.tsx \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx src/components/chat/ChatContent.css \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): delete for everyone reaches the other person, with a placeholder

The web sent ?forEveryone=true, which the backend never read, so "delete
for everyone" hid the message for the web user only and the app user kept
it. The flag now goes in the JSON body like the app's. A message deleted
for everyone stays as "This message was deleted" (as in the app) instead
of vanishing; "for me" still removes it. A dialog replaces window.confirm
and offers "for everyone" only inside the backend's 1-hour window; Delete
is no longer offered on the other person's messages (the backend 403s).

Still open (Phase 3 chat): P3-CHAT-3..20 and the chat i18n pass.
EOF
```

---

### Task P3-CHAT-3: Opening a chat never posts "Conversation started" (chat#3)

**Files:**
- Modify: `src/components/chat/NewChat.tsx:9,66,86-114,238,277` (drop `createChatRoom`, navigate by user id)
- Modify: `src/components/profile/parts/ProfileActions.tsx:14,84,131-142,208`
- Modify: `src/components/profile/parts/ConversationStarters.tsx:1,6,129-158,193`
- Modify: `src/store/slices/chatSlice.ts:90-97,445` (delete `createChatRoom` + its hook export)
- Test: `src/components/profile/parts/ProfileActions.test.tsx:16,36-38,68,100-118`, `src/components/profile/parts/ConversationStarters.test.tsx:8,19-21,28-30,121-178`, `src/components/profile/ProfilePage.test.tsx:26,64,122`, new `src/components/chat/NewChat.test.tsx`

**Interfaces:**
- Consumes: nothing new. `/chat/:userId` already opens an empty thread for a user with no messages (`MainChat.tsx:27-40` fetches the name via `useGetUserByIdQuery`; `ChatContent` shows "No messages yet"); the first real send creates the Conversation server-side (socket `updateConversation` / REST `createMessage`). `?draft=` seeding already exists (`ChatContent.tsx:833-841`).
- Backend: before Phase 1, `POST /messages/conversations` creates a real "Conversation started" Message (chat#3). After P1-CHAT-1 it no longer does, but runs the block check and cap and can 403. The web stops calling it either way, so the live behaviour is fixed the moment this pushes, independent of the backend deploy.
- Produces: `useCreateChatRoomMutation` no longer exists. Test files that still mock it inside a `jest.mock` factory keep working (a factory may export extra names), but they are cleaned up here.

- [ ] **Step 1: Write / change the failing tests**

`ProfileActions.test.tsx`:
- delete `const mockCreateChatRoom = jest.fn();`, the `jest.mock("../../../store/slices/chatSlice", ...)` block, and `mockCreateChatRoom.mockReturnValue(resolved());` from `beforeEach`.
- replace the two tests `"opens the chat the way the community page does"` and `"still opens the chat screen when creating the room fails"` with:

```tsx
  it("opens the chat by the other user's id and posts nothing", () => {
    const fetchSpy = jest.spyOn(global as any, "fetch").mockImplementation(() => {
      throw new Error("no request expected");
    });
    renderActions();
    fireEvent.click(screen.getByTestId("action-message"));
    expect(mockNavigate).toHaveBeenCalledWith("/chat/u2");
    expect(fetchSpy).not.toHaveBeenCalled();
    fetchSpy.mockRestore();
  });
```
- in `"sends a logged-out viewer to the login screen instead"` delete the line `expect(mockCreateChatRoom).not.toHaveBeenCalled();`.

`ConversationStarters.test.tsx`:
- delete `mockCreateChatRoom`, its `jest.mock` block and the `beforeEach` that sets it.
- delete the test `"only the pressed Send waits -- the other two stay live"` (nothing waits any more) and `"still opens the chat when the room pre-create fails"`.
- replace `"opens the chat with the starter as a draft"` with:

```tsx
  it("opens the chat with the starter as a draft, without creating anything", () => {
    renderCard();
    const text = screen.getAllByTestId("conversation-starter")[0].textContent || "";
    fireEvent.click(screen.getAllByTestId("conversation-starter-send")[0]);

    expect(mockNavigate).toHaveBeenCalledTimes(1);
    const target_ = String(mockNavigate.mock.calls[0][0]);
    expect(target_.startsWith("/chat/u2?draft=")).toBe(true);
    const draft = decodeURIComponent(target_.split("?draft=")[1]);
    expect(text).toContain(draft);
  });
```

`ProfilePage.test.tsx`: delete `const mockCreateChatRoom = jest.fn();` (`:26`), the `useCreateChatRoomMutation: ...` line in its chatSlice mock (`:64`) and `mockCreateChatRoom.mockReturnValue(resolved());` (`:122`).

Create `src/components/chat/NewChat.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import NewChat from "./NewChat";

const mockNavigate = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../store/slices/usersSlice", () => ({
  useSearchUsersQuery: (_arg: any, opts: any) =>
    opts && opts.skip
      ? { data: undefined, isLoading: false }
      : { data: { data: [{ _id: "u2", name: "Ada", imageUrls: [] }] }, isLoading: false },
  useSearchUsersByUsernameQuery: () => ({ data: undefined, isLoading: false }),
  useGetUserByIdQuery: () => ({ data: undefined, isLoading: false }),
}));

afterEach(() => jest.clearAllMocks());

it("opens /chat/<userId> for the picked person and creates nothing", () => {
  render(
    <MemoryRouter>
      <NewChat />
    </MemoryRouter>
  );
  fireEvent.change(screen.getByRole("textbox"), { target: { value: "Ada" } });
  fireEvent.click(screen.getByText("Ada"));
  expect(mockNavigate).toHaveBeenCalledWith("/chat/u2");
});
```
(`NewChat` has one `<input>`.)

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false ProfileActions ConversationStarters ProfilePage NewChat
```
Expected: FAIL — `ProfileActions` calls `useCreateChatRoomMutation` from a module the test no longer mocks (real RTK hook outside a store → "could not find react-redux context value"), likewise `ConversationStarters`; `NewChat` calls `createChatRoom` without a store.

- [ ] **Step 3: Implement**

`NewChat.tsx`:
- delete `import { useCreateChatRoomMutation } from "../../store/slices/chatSlice";` and `const [createChatRoom, { isLoading: isCreating }] = useCreateChatRoomMutation();`
- replace `handleCreateChat` (the whole `const handleCreateChat = async (user: User) => { ... };`) with:
```tsx
  // No pre-create. POST /messages/conversations used to write a real
  // "Conversation started" message to the other person (and count it against
  // the 5-message first-chat limit). The app opens the thread and lets the
  // first real send create the conversation; so does the web now.
  const handleCreateChat = (user: User) => {
    navigate(`/chat/${user._id}`);
  };
```
- remove `disabled={isCreating}` (`:238`) and replace the `{isCreating ? (<Loader2 .../>) : (<MessageCircle .../>)}` ternary (`:277-281`) with `<MessageCircle className="w-5 h-5 text-teal-500" />`; keep `Loader2` (the search spinner at `:218` still uses it) and delete `import { Bounce, toast } from "react-toastify";` (its only use was the removed handler).

`ProfileActions.tsx`:
- delete `import { useCreateChatRoomMutation } from "../../../store/slices/chatSlice";` and `const [createChatRoom, { isLoading: isCreatingChat }] = useCreateChatRoomMutation();`
- replace `handleMessage` with:
```tsx
  const handleMessage = (): void => {
    if (!viewerId) {
      navigate("/login");
      return;
    }
    // Straight to the thread: the first real send creates the conversation.
    navigate(`/chat/${userId}`);
  };
```
- delete `disabled={isCreatingChat}` from the `action-message` button.
- fix the comment above `mounted` ("Block, report and the chat pre-create all await…") to "Block and report await a round trip…".

`ConversationStarters.tsx`:
- delete the chatSlice import, `const [createChatRoom] = useCreateChatRoomMutation();`, `pendingKey` state, the `mounted` ref and its effect.
- replace `handleSend` with:
```tsx
  const handleSend = (text: string): void => {
    // Into the composer, not sent: the viewer reads it and presses Send.
    navigate(`/chat/${userId}?draft=${encodeURIComponent(text)}`);
  };
```
- the button: `onClick={() => handleSend(starter.text)}` and delete `disabled={pendingKey === starter.key}`.
- `import React, { useEffect, useRef, useState } from "react";` → `import React from "react";`

`chatSlice.ts`: delete the `createChatRoom: builder.mutation({ ... }),` block (`:90-97`) and `useCreateChatRoomMutation,` from the export list (`:445`). Verify: `grep -rn "createChatRoom\|CreateChatRoom" src` prints nothing.

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false ProfileActions ConversationStarters ProfilePage NewChat chatActionsEndpoints
```

- [ ] **Step 5: Commit** (tick `P3-CHAT-3`)

```bash
git add src/components/chat/NewChat.tsx src/components/chat/NewChat.test.tsx \
  src/components/profile/parts/ProfileActions.tsx src/components/profile/parts/ProfileActions.test.tsx \
  src/components/profile/parts/ConversationStarters.tsx src/components/profile/parts/ConversationStarters.test.tsx \
  src/components/profile/ProfilePage.test.tsx src/store/slices/chatSlice.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): opening a chat no longer posts "Conversation started"

New chat, the profile's Message button and conversation starters all
called POST /messages/conversations first. Before backend P1-CHAT-1 that
wrote a real "Conversation started" message from the web user, which the
app shows as a text bubble and counts against the 5-message first-chat
limit. All three now go straight to /chat/<userId>, as the app does; the
first real send creates the conversation. createChatRoom is removed.

Still open (Phase 3 chat): P3-CHAT-4..20 and the chat i18n pass; owner:
purge legacy "Conversation started" rows in prod (backend REMAINING_WORK).
EOF
```

---

### Task P3-CHAT-4: Limit, paywall and block refusals open a dialog instead of a bare "Failed" (chat#4)

**Files:**
- Create: `src/components/chat/lib/sendErrors.ts` (pure classifier)
- Create: `src/components/chat/actions/SendErrorDialog.tsx`
- Modify: `src/components/chat/ChatContent.tsx` — `handleMessageError` (`:555-557`), `handleMessageSendError` (`:639-641`), the `catch` of the reply path (`:1116`), `sendViaRestApi` (`:1188`), `sendInlineMessageViaRest` (`:1264`), `sendStickerViaRest` (`:1333`), `handleSendMedia` (`:1416`), `sendVoiceRecording` (`:1545`), render block
- Modify: `src/utils/locales/eng.json` (`chatPage.sendErrors.*`)
- Test: `src/components/chat/lib/sendErrors.test.ts` (new), `src/components/chat/actions/SendErrorDialog.test.tsx` (new), `ChatContent.test.tsx` (two cases)

**Interfaces:**
- Consumes (exact backend strings, `be-integration` main):
  - Socket ack on refusal: `{status:'error', error: <message>}` (`socket/socketHandler.js` catch of `sendMessage`); with no callback the same object is emitted as `messageError`.
  - Burst limiter: socket `messageSendError {error:'Too many messages — slow down.'}` and **no ack** (`socketHandler.js:879-881`).
  - First-chat limit: `"You can only send 5 messages until they reply. Please wait for a response."` — socket, and REST 429 (`controllers/messages.js:584-589`).
  - Daily limit: socket `"Daily message limit exceeded. Used x/y. Resets at …"`; REST 429 `"Daily messages limit exceeded. You have used x of y messages today. Limit resets at …"` (`utils/limitations.js:158-174`).
  - Conversation cap (`CONVERSATION_CAP_ENABLED`, off in prod): socket text `CONVERSATION_START_LIMIT_MESSAGE` = "You have started the most conversations you can today. Watch an ad for one more, or go VIP to start as many as you want." (`lib/conversationQuota.js:189-190`); REST 403 with `code:'CONVERSATION_START_LIMIT'` (`middleware/checkConversationStart.js`).
  - Blocked: socket "Cannot send message to blocked user"; REST 403 "Cannot send message to this user" (`controllers/messages.js:569`, `advancedMessages.js` video/voice).
  - REST error envelope: `{success:false, error, code?}` → RTK `err = {status, data:{error, code}}`.
- App reference: `chat_conversation_screen.dart:986-1010` (`_showSendError`) — same matching order (rate → first-chat → limit → blocked).
- Produces: `classifySendError(input: any): { kind: SendErrorKind; detail: string }` with `SendErrorKind = "rateLimited" | "firstChatLimit" | "dailyLimit" | "conversationCap" | "blocked" | "generic"`; `SendErrorDialog` default export, props `{ error: { kind, detail } ; onClose(): void }` (testids `send-error-dialog`, `send-error-vip`, `send-error-close`); in ChatContent a `reportSendError(err: any): void` callback that P3-CHAT-5/8/9 reuse.

- [ ] **Step 1: Write the failing tests**

Create `src/components/chat/lib/sendErrors.test.ts`:

```ts
import { classifySendError } from "./sendErrors";

const rest = (status: number, error: string, code?: string) => ({
  status,
  data: { success: false, error, ...(code ? { code } : {}) },
});

it.each([
  [{ status: "error", error: "You can only send 5 messages until they reply. Please wait for a response." }, "firstChatLimit"],
  [rest(429, "You can only send 5 messages until they reply. Please wait for a response."), "firstChatLimit"],
  [{ status: "error", error: "Daily message limit exceeded. Used 20/20. Resets at 10/17/2026, 12:00:00 AM." }, "dailyLimit"],
  [rest(429, "Daily messages limit exceeded. You have used 20 of 20 messages today. Limit resets at midnight."), "dailyLimit"],
  [rest(403, "You have started the most conversations you can today. Watch an ad for one more, or go VIP to start as many as you want.", "CONVERSATION_START_LIMIT"), "conversationCap"],
  [{ status: "error", error: "You have started the most conversations you can today. Watch an ad for one more, or go VIP to start as many as you want." }, "conversationCap"],
  [{ status: "error", error: "Cannot send message to blocked user" }, "blocked"],
  [rest(403, "Cannot send message to this user"), "blocked"],
  [{ error: "Too many messages — slow down." }, "rateLimited"],
  [rest(500, "Server error"), "generic"],
  [undefined, "generic"],
  [new Error("Failed to fetch"), "generic"],
])("classifies %j as %s", (input: any, kind: string) => {
  expect(classifySendError(input).kind).toBe(kind);
});

it("keeps the server text as detail (the first-chat line names the number)", () => {
  expect(
    classifySendError({ status: "error", error: "You can only send 5 messages until they reply. Please wait for a response." }).detail
  ).toContain("5 messages");
});

it("prefers the machine code over the text", () => {
  expect(classifySendError(rest(403, "anything", "CONVERSATION_START_LIMIT")).kind).toBe("conversationCap");
});
```

Create `src/components/chat/actions/SendErrorDialog.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import SendErrorDialog from "./SendErrorDialog";

const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

function show(kind: string, detail = "") {
  const onClose = jest.fn();
  render(
    <MemoryRouter>
      <SendErrorDialog error={{ kind: kind as any, detail }} onClose={onClose} />
    </MemoryRouter>
  );
  return onClose;
}

it("daily limit offers VIP and goes to the VIP page", () => {
  const onClose = show("dailyLimit");
  expect(screen.getByTestId("send-error-dialog")).toHaveTextContent("Daily message limit reached");
  fireEvent.click(screen.getByTestId("send-error-vip"));
  expect(mockNavigate).toHaveBeenCalledWith("/settings/vip");
  expect(onClose).toHaveBeenCalled();
});

it("conversation cap offers VIP", () => {
  show("conversationCap");
  expect(screen.getByTestId("send-error-vip")).toBeInTheDocument();
});

it("first-chat limit explains the wait and has no VIP button", () => {
  show("firstChatLimit", "You can only send 5 messages until they reply. Please wait for a response.");
  expect(screen.getByTestId("send-error-dialog")).toHaveTextContent("until they reply");
  expect(screen.queryByTestId("send-error-vip")).not.toBeInTheDocument();
});

it("blocked says the person can't be messaged", () => {
  const onClose = show("blocked");
  expect(screen.getByTestId("send-error-dialog")).toHaveTextContent("You can't send messages to this person.");
  fireEvent.click(screen.getByTestId("send-error-close"));
  expect(onClose).toHaveBeenCalled();
});
```

`ChatContent.test.tsx` — append (reuses `offlineSocket`, `messageBox`):

```tsx
// --- Refusals the user can act on ------------------------------------------

it("shows the first-chat limit as a dialog when REST answers 429", async () => {
  mockUseSocket.mockReturnValue(offlineSocket());
  mockCreateMessage.mockReturnValue({
    unwrap: () =>
      Promise.reject({
        status: 429,
        data: { success: false, error: "You can only send 5 messages until they reply. Please wait for a response." },
      }),
  });
  renderChat("/chat/u2");

  fireEvent.change(messageBox(), { target: { value: "hi" } });
  fireEvent.submit(messageBox().closest("form")!);

  await waitFor(() => expect(screen.getByTestId("send-error-dialog")).toHaveTextContent("until they reply"));
  expect(screen.getByTestId("msg-status-error")).toBeInTheDocument();
});

it("shows the burst limiter's refusal (no ack arrives for it)", async () => {
  const s = silentSocket();
  mockUseSocket.mockReturnValue(s.value);
  renderChat("/chat/u2");

  fireEvent.change(messageBox(), { target: { value: "hi" } });
  fireEvent.submit(messageBox().closest("form")!);
  act(() => {
    s.handlers["messageSendError"].forEach((fn) => fn({ error: "Too many messages — slow down." }));
  });

  await waitFor(() => expect(screen.getByTestId("msg-status-error")).toBeInTheDocument());
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false sendErrors SendErrorDialog ChatContent.test
```
Expected: FAIL — modules missing; ChatContent only `console.error`s.

- [ ] **Step 3: Implement**

Create `src/components/chat/lib/sendErrors.ts`:

```ts
/**
 * Why a send was refused, in the terms the UI acts on.
 *
 * The backend refuses over three channels with three shapes: the socket ack
 * ({status:'error', error}), the socket `messageSendError` push ({error},
 * burst limiter, no ack) and REST ({status, data:{error, code}}). The text is
 * the contract today (only the conversation cap has a code), so the match is
 * on the server's own wording -- the same order the app uses in
 * chat_conversation_screen.dart _showSendError.
 */
export type SendErrorKind =
  | "rateLimited"
  | "firstChatLimit"
  | "dailyLimit"
  | "conversationCap"
  | "blocked"
  | "generic";

export interface SendError {
  kind: SendErrorKind;
  /** The server's own text, when there was one. */
  detail: string;
}

function textOf(input: any): string {
  if (!input) return "";
  if (typeof input === "string") return input;
  if (input.data && typeof input.data === "object") {
    return String(input.data.error || input.data.message || "");
  }
  return String(input.error || input.message || "");
}

function codeOf(input: any): string {
  if (!input || typeof input !== "object") return "";
  if (input.data && typeof input.data === "object" && input.data.code) return String(input.data.code);
  return input.code ? String(input.code) : "";
}

export function classifySendError(input: any): SendError {
  const detail = textOf(input);
  const text = detail.toLowerCase();
  const code = codeOf(input);

  if (code === "CONVERSATION_START_LIMIT" || text.indexOf("most conversations") > -1) {
    return { kind: "conversationCap", detail };
  }
  if (text.indexOf("too many messages") > -1) return { kind: "rateLimited", detail };
  if (text.indexOf("until they reply") > -1) return { kind: "firstChatLimit", detail };
  if (/daily messages? limit/.test(text)) return { kind: "dailyLimit", detail };
  if (text.indexOf("blocked") > -1 || text.indexOf("cannot send message to this user") > -1) {
    return { kind: "blocked", detail };
  }
  return { kind: "generic", detail };
}
```

Create `src/components/chat/actions/SendErrorDialog.tsx`:

```tsx
import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import DialogShell from "../../../design/DialogShell";
import { SendError } from "../lib/sendErrors";

export interface SendErrorDialogProps {
  error: SendError;
  onClose: () => void;
}

/**
 * The refusals a person can do something about. The app shows these as its
 * LimitExceeded dialog / snackbars; the web has no rewarded ads or coin
 * unlock, so the action it offers is VIP (/settings/vip).
 */
const SendErrorDialog: React.FC<SendErrorDialogProps> = ({ error, onClose }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  let title = "";
  let body = "";
  let offerVip = false;
  switch (error.kind) {
    case "firstChatLimit":
      title = t("chatPage.sendErrors.firstChatTitle") || "Wait for a reply";
      body =
        t("chatPage.sendErrors.firstChatBody") ||
        "You can send 5 messages until they reply. You can write again once they answer.";
      break;
    case "dailyLimit":
      title = t("chatPage.sendErrors.dailyTitle") || "Daily message limit reached";
      body =
        t("chatPage.sendErrors.dailyBody") ||
        "You've sent all your messages for today. Go VIP for unlimited messages, or come back tomorrow.";
      offerVip = true;
      break;
    case "conversationCap":
      title = t("chatPage.sendErrors.capTitle") || "New conversation limit reached";
      body =
        t("chatPage.sendErrors.capBody") ||
        "You've started as many new conversations as you can today. Go VIP to start as many as you want.";
      offerVip = true;
      break;
    case "blocked":
      title = t("chatPage.sendErrors.blockedTitle") || "Message not sent";
      body = t("chatPage.sendErrors.blockedBody") || "You can't send messages to this person.";
      break;
    default:
      return null;
  }

  return (
    <DialogShell labelledBy="send-error-title" onClose={onClose} testId="send-error-dialog">
      <h2 id="send-error-title" className="font-display text-base text-ink-900 dark:text-ink-50">
        {title}
      </h2>
      <p className="pt-2 text-sm text-ink-600 dark:text-ink-300">{body}</p>
      <div className="mt-5 flex justify-end gap-2">
        <button
          type="button"
          data-testid="send-error-close"
          onClick={onClose}
          className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 dark:border-line-dark dark:text-ink-200"
        >
          {t("chatPage.sendErrors.ok") || "OK"}
        </button>
        {offerVip && (
          <button
            type="button"
            data-testid="send-error-vip"
            onClick={() => {
              onClose();
              navigate("/settings/vip");
            }}
            className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white"
          >
            {t("chatPage.sendErrors.goVip") || "Go VIP"}
          </button>
        )}
      </div>
    </DialogShell>
  );
};

export default SendErrorDialog;
```

`ChatContent.tsx`:
1. Imports (values only — `SendError` is an interface, and importing an interface by name is the TS 3.7 + Babel trap described in `src/design/index.ts`, so the state type is written inline):
```tsx
import SendErrorDialog from "./actions/SendErrorDialog";
import { classifySendError } from "./lib/sendErrors";
import notify from "../../design/notify";
```
2. State (below the delete state): `const [sendError, setSendError] = useState<{ kind: any; detail: string } | null>(null);`
3. Below `markOptimisticError` (`:1073-1079`) add:
```tsx
  // One place a refused send is explained. Limits / cap / block get a
  // dialog; the burst limiter and anything unexpected get a toast. The bubble
  // itself is marked failed by the caller (Retry stays available).
  const reportSendError = useCallback(
    (err: any) => {
      const classified = classifySendError(err);
      if (classified.kind === "rateLimited") {
        notify.error(t("chatPage.sendErrors.tooFast") || "You're sending messages too fast. Wait a moment.", {
          toastId: "chat-send-too-fast",
        });
        return;
      }
      if (classified.kind === "generic") {
        notify.error(t("chatPage.sendErrors.generic") || "Message not sent. Tap Retry to try again.", {
          toastId: "chat-send-failed",
        });
        return;
      }
      setSendError(classified);
    },
    [t]
  );
  useEffect(() => {
    reportSendErrorRef.current = reportSendError;
  });
```
   and, next to `const selectedUserRef = useRef<string>(selectedUser);` (above the socket-listener effect, which runs before `reportSendError` exists in source order):
```tsx
  // The socket listeners are bound once per socket; they reach the current
  // reportSendError through this ref instead of re-binding on every render.
  const reportSendErrorRef = useRef<(err: any) => void>(() => {});
```
   SendErrorDialog's own file imports `SendError` as a type only inside `SendErrorDialogProps`; if the build trips on it there, inline `{ kind: string; detail: string }` the same way.
4. Socket handlers: replace
```tsx
    const handleMessageError = (errorData: { message: string; error: string }) => {
      console.error("[Socket] Message error:", errorData);
    };
```
with
```tsx
    // A refusal for an emit that carried no callback (ours always do, so this
    // is defensive) -- explain it all the same.
    const handleMessageError = (errorData: { message?: string; error?: string }) => {
      reportSendErrorRef.current(errorData);
    };
```
and replace
```tsx
    const handleMessageSendError = (errorData: { error?: string }) => {
      console.error("[Socket] messageSendError:", errorData);
    };
```
with
```tsx
    // The burst limiter refuses with this push and NO ack, so the newest
    // in-flight bubble would otherwise spin until the ack timeout.
    const handleMessageSendError = (errorData: { error?: string }) => {
      setMessages((prev) => {
        for (let i = prev.length - 1; i >= 0; i -= 1) {
          const m = prev[i];
          if (m.isOptimistic && m.status === "sending") {
            const next = [...prev];
            next[i] = { ...m, status: "error", isOptimistic: false };
            return next;
          }
        }
        return prev;
      });
      reportSendErrorRef.current(errorData);
    };
```
5. Every REST `catch` in the send paths calls it after marking the bubble failed:
   - reply path `} catch (err) { console.error("Reply send failed:", err); markOptimisticError(tempId); }` → add `reportSendError(err);`
   - `sendViaRestApi` catch → add `reportSendError(err);` after the `setMessages(...)` call
   - `sendInlineMessageViaRest` catch → also set `isOptimistic: false` in its map (it was missing) and add `reportSendError(err);`
   - `sendStickerViaRest` catch → add `reportSendError(err);`
   - `handleSendMedia` catch → add `reportSendError(err);`
   - `sendVoiceRecording` catch → add `reportSendError(err);`
6. Render below the delete dialog:
```tsx
      {sendError && <SendErrorDialog error={sendError} onClose={() => setSendError(null)} />}
```

`eng.json`, in `chatPage`:
```json
    "sendErrors": {
      "firstChatTitle": "Wait for a reply",
      "firstChatBody": "You can send 5 messages until they reply. You can write again once they answer.",
      "dailyTitle": "Daily message limit reached",
      "dailyBody": "You've sent all your messages for today. Go VIP for unlimited messages, or come back tomorrow.",
      "capTitle": "New conversation limit reached",
      "capBody": "You've started as many new conversations as you can today. Go VIP to start as many as you want.",
      "blockedTitle": "Message not sent",
      "blockedBody": "You can't send messages to this person.",
      "tooFast": "You're sending messages too fast. Wait a moment.",
      "generic": "Message not sent. Tap Retry to try again.",
      "goVip": "Go VIP",
      "ok": "OK"
    },
```

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false sendErrors SendErrorDialog ChatContent
```

- [ ] **Step 5: Commit** (tick `P3-CHAT-4`)

```bash
git add src/components/chat/lib/sendErrors.ts src/components/chat/lib/sendErrors.test.ts \
  src/components/chat/actions/SendErrorDialog.tsx src/components/chat/actions/SendErrorDialog.test.tsx \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): explain refused sends instead of a bare "Failed"

The first-chat limit, the daily limit, the new-conversation cap and
blocks all ended in a red "Failed" bubble with the reason only in the
console. A classifier reads the three refusal shapes (socket ack,
messageSendError push, REST envelope) and the chat shows a dialog --
with a VIP action for the daily limit and the cap -- or a toast for the
burst limiter. The bubble still offers Retry.

Still open (Phase 3 chat): P3-CHAT-5..20 and the chat i18n pass.
EOF
```

---

### Task P3-CHAT-5: A slow socket ack marks the bubble failed with Retry; no REST fallback, no duplicates (chat#5)

**Files:**
- Create: `src/components/chat/lib/socketAck.ts`
- Modify: `src/components/chat/ChatContent.tsx` — `handleMessageSent` adoption (`:476-479`), `finalizeOptimistic` (`:1054-1071`), `handleSendMessage` socket branch (`:1148-1173`), `sendInlineMessage` (`:1208-1248`), `handleSendSticker` (`:1273-1320`), `handleRetryMessage` (`:1595-1636`)
- Modify: `src/utils/locales/eng.json` (`chatPage.sendErrors.reattach`)
- Test: `src/components/chat/lib/socketAck.test.ts` (new), `ChatContent.test.tsx` (four cases)

**Interfaces:**
- Consumes: socket `sendMessage {receiver, message, messageType?}` with ack `{status:'success', message}` or `{status:'error', error}` (`socketHandler.js:873-1180`). The server creates the Message **before** it acks (`:991-1026`), so a timeout does not mean "not sent". `messageSent {message, receiverId}` arrives on every socket of the sender (incl. this one).
- Behaviour after this task:
  - socket connected → send over the socket only. A refusal ack → bubble failed + `reportSendError` (P3-CHAT-4). No ack within `SOCKET_ACK_TIMEOUT_MS` (10 s) → bubble failed with Retry; **nothing** is sent over REST. A late success ack still replaces the failed bubble (it keeps its temp id); a late `messageSent` adopts a failed temp bubble with the same text.
  - socket not connected at send time → REST, as today (one request, no race).
  - Retry: text/sticker/gif re-send their own `messageType` over the socket (REST when disconnected); a failed reply re-sends through `/messages/:id/reply`; a failed media/voice bubble is removed with a toast asking to attach the file again (the `File` is gone).
- Produces: `emitWithAck(socket, event, payload, timeoutMs, { onAck(response, late: boolean), onTimeout() })` and `SOCKET_ACK_TIMEOUT_MS` from `lib/socketAck.ts`. `Message.replyTo` is used by Retry to choose the reply path.

- [ ] **Step 1: Write the failing tests**

Create `src/components/chat/lib/socketAck.test.ts`:

```ts
import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "./socketAck";

beforeEach(() => jest.useFakeTimers());
afterEach(() => jest.useRealTimers());

function socketThatAcks(after: number | null, response: any = { status: "success", message: { _id: "m1" } }) {
  return {
    emit: jest.fn((_e: string, _p: any, cb: (r: any) => void) => {
      if (after !== null) setTimeout(() => cb(response), after);
    }),
  };
}

it("answers onAck when the ack is in time", () => {
  const onAck = jest.fn();
  const onTimeout = jest.fn();
  emitWithAck(socketThatAcks(100) as any, "sendMessage", { a: 1 }, 1000, { onAck, onTimeout });
  jest.advanceTimersByTime(100);
  expect(onAck).toHaveBeenCalledWith({ status: "success", message: { _id: "m1" } }, false);
  jest.advanceTimersByTime(5000);
  expect(onTimeout).not.toHaveBeenCalled();
});

it("times out, then still delivers a late ack flagged late", () => {
  const onAck = jest.fn();
  const onTimeout = jest.fn();
  emitWithAck(socketThatAcks(3000) as any, "sendMessage", {}, 1000, { onAck, onTimeout });
  jest.advanceTimersByTime(1000);
  expect(onTimeout).toHaveBeenCalledTimes(1);
  jest.advanceTimersByTime(2000);
  expect(onAck).toHaveBeenCalledWith(expect.anything(), true);
});

it("never calls onTimeout twice or after an ack", () => {
  const onTimeout = jest.fn();
  emitWithAck(socketThatAcks(null) as any, "sendMessage", {}, 1000, { onAck: jest.fn(), onTimeout });
  jest.advanceTimersByTime(10000);
  expect(onTimeout).toHaveBeenCalledTimes(1);
});

it("waits 10 s by default", () => {
  expect(SOCKET_ACK_TIMEOUT_MS).toBe(10000);
});
```

`ChatContent.test.tsx` — append:

```tsx
// --- A slow ack is not a reason to send twice --------------------------------
//
// After 5 s without an ack the web re-sent the same text over REST. The
// server had already created the first copy (it creates before it acks), so
// the app user got the message twice.

it("marks the bubble failed after the ack timeout and sends nothing over REST", async () => {
  jest.useFakeTimers();
  const s = silentSocket();
  mockUseSocket.mockReturnValue(s.value);
  renderChat("/chat/u2");

  fireEvent.change(messageBox(), { target: { value: "hello" } });
  fireEvent.submit(messageBox().closest("form")!);
  act(() => {
    jest.advanceTimersByTime(10000);
  });

  expect(screen.getByTestId("msg-status-error")).toBeInTheDocument();
  expect(mockCreateMessage).not.toHaveBeenCalled();
  jest.useRealTimers();
});

it("a late ack turns the failed bubble into the real message, once", async () => {
  jest.useFakeTimers();
  const s = silentSocket();
  let ack: (r: any) => void = () => undefined;
  s.value.socket.emit = jest.fn((event: string, _d: any, cb?: (r: any) => void) => {
    if (event === "sendMessage" && cb) ack = cb;
  }) as any;
  mockUseSocket.mockReturnValue(s.value);
  renderChat("/chat/u2");

  fireEvent.change(messageBox(), { target: { value: "hello" } });
  fireEvent.submit(messageBox().closest("form")!);
  act(() => {
    jest.advanceTimersByTime(10000);
  });
  act(() => {
    ack({ status: "success", message: { _id: "m-real", message: "hello", sender: { _id: "me" } } });
  });

  expect(renderedIds()).toEqual(["m-real"]);
  jest.useRealTimers();
});

it("a late messageSent adopts the failed bubble instead of adding a second", async () => {
  jest.useFakeTimers();
  const s = silentSocket();
  mockUseSocket.mockReturnValue(s.value);
  renderChat("/chat/u2");

  fireEvent.change(messageBox(), { target: { value: "hello" } });
  fireEvent.submit(messageBox().closest("form")!);
  act(() => {
    jest.advanceTimersByTime(10000);
  });
  act(() => {
    s.handlers["messageSent"].forEach((fn) =>
      fn({ message: { _id: "m-real", message: "hello", sender: { _id: "me" }, receiver: "u2" }, receiverId: "u2" })
    );
  });

  expect(renderedIds()).toEqual(["m-real"]);
  jest.useRealTimers();
});

it("a refusal ack fails the bubble and explains it, without REST", async () => {
  const s = silentSocket();
  s.value.socket.emit = jest.fn((event: string, _d: any, cb?: (r: any) => void) => {
    if (event === "sendMessage" && cb) cb({ status: "error", error: "Cannot send message to blocked user" });
  }) as any;
  mockUseSocket.mockReturnValue(s.value);
  renderChat("/chat/u2");

  fireEvent.change(messageBox(), { target: { value: "hello" } });
  fireEvent.submit(messageBox().closest("form")!);

  await waitFor(() => expect(screen.getByTestId("send-error-dialog")).toBeInTheDocument());
  expect(screen.getByTestId("msg-status-error")).toBeInTheDocument();
  expect(mockCreateMessage).not.toHaveBeenCalled();
});

it("Retry re-sends a failed sticker as a sticker", async () => {
  const s = silentSocket();
  const sends: any[] = [];
  s.value.socket.emit = jest.fn((event: string, d: any, cb?: (r: any) => void) => {
    if (event !== "sendMessage" || !cb) return;
    sends.push(d);
    if (sends.length === 1) cb({ status: "error", error: "boom" });
    else cb({ status: "success", message: { _id: "m-ok", message: d.message, messageType: d.messageType, sender: { _id: "me" } } });
  }) as any;
  mockUseSocket.mockReturnValue(s.value);
  renderChat("/chat/u2");

  fireEvent.click(screen.getByLabelText("Stickers"));
  // "Recent" is empty in a fresh browser; open the first real category.
  const tabs = document.querySelectorAll(".sticker-tab");
  fireEvent.click(tabs[tabs.length > 1 ? 1 : 0] as HTMLElement);
  fireEvent.click(document.querySelector(".sticker-item") as HTMLElement);
  await waitFor(() => expect(screen.getByTestId("msg-status-error")).toBeInTheDocument());

  fireEvent.click(screen.getByText("Retry"));
  await waitFor(() => expect(sends).toHaveLength(2));
  expect(sends[1].messageType).toBe("sticker");
});
```
(`StickerPanel.tsx:117-150`: tabs are `.sticker-tab`, stickers `.sticker-item`.)

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false socketAck ChatContent.test
```
Expected: FAIL — `socketAck` missing; after 5 s the old code calls `createMessage` (REST); the late `messageSent` adds a second bubble; a refusal ack falls back to REST; Retry sends a sticker as plain text (no `messageType`).

- [ ] **Step 3: Implement**

Create `src/components/chat/lib/socketAck.ts`:

```ts
/**
 * Emit with an ack and a deadline, without ever giving up on the ack.
 *
 * The backend creates the message BEFORE it acks (socket/socketHandler.js
 * sendMessage), so "no ack yet" never means "not sent". The deadline only
 * changes what the bubble says (failed, with Retry); the ack, whenever it
 * comes, still reconciles it -- `late` tells the caller it already timed out.
 * Nothing here falls back to REST: a second channel for the same text is how
 * the app user got every slow message twice.
 */
export const SOCKET_ACK_TIMEOUT_MS = 10000;

export interface AckHandlers {
  onAck: (response: any, late: boolean) => void;
  onTimeout: () => void;
}

export function emitWithAck(
  socket: { emit: (event: string, payload: any, cb: (r: any) => void) => any },
  event: string,
  payload: any,
  timeoutMs: number,
  handlers: AckHandlers
): void {
  let timedOut = false;
  let acked = false;
  const timer = setTimeout(() => {
    if (acked) return;
    timedOut = true;
    handlers.onTimeout();
  }, timeoutMs);
  socket.emit(event, payload, (response: any) => {
    if (acked) return;
    acked = true;
    clearTimeout(timer);
    handlers.onAck(response, timedOut);
  });
}
```

`ChatContent.tsx`:

1. Import: `import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "./lib/socketAck";`

2. `handleMessageSent` adoption — replace
```tsx
          const pending = prev.findIndex(
            (msg) =>
              msg.isOptimistic &&
              (msg.message || "") === (data.message.message || "")
          );
```
with
```tsx
          // A bubble that timed out is still ours under its temp id: the
          // server may well have the message (it creates before it acks).
          const pending = prev.findIndex(
            (msg) =>
              (msg.isOptimistic ||
                (msg.status === "error" && String(msg._id).indexOf("temp-") === 0)) &&
              (msg.message || "") === (data.message.message || "")
          );
```

3. `finalizeOptimistic` — replace its first statement
```tsx
    setMessages((prev) =>
      prev.map((m) =>
        m._id === tempId ? { ...msgData, status: "sent", isOptimistic: false } : m
      )
    );
```
with
```tsx
    setMessages((prev) => {
      // Already here under its real id (messageSent beat a late ack): drop
      // the temp copy instead of holding two.
      if (msgData && msgData._id && prev.some((m) => m._id === msgData._id)) {
        return prev.filter((m) => m._id !== tempId);
      }
      return prev.map((m) =>
        m._id === tempId ? { ...msgData, status: "sent", isOptimistic: false } : m
      );
    });
```

4. Below `reportSendError` (P3-CHAT-4) add the one socket send used by every inline path:
```tsx
  // Text, sticker and GIF over the socket. Socket only: see lib/socketAck.
  const sendInlineOverSocket = (tempId: string, text: string, messageType?: string) => {
    if (!socket) return;
    const payload: any = { receiver: selectedUser, message: text };
    if (messageType && messageType !== "text") payload.messageType = messageType;
    emitWithAck(socket as any, "sendMessage", payload, SOCKET_ACK_TIMEOUT_MS, {
      onAck: (response: any) => {
        setIsSending(false);
        if (response && response.status === "success" && response.message) {
          finalizeOptimistic(tempId, response.message);
          return;
        }
        markOptimisticError(tempId);
        reportSendError(response);
      },
      onTimeout: () => {
        setIsSending(false);
        markOptimisticError(tempId);
      },
    });
  };
```

5. `handleSendMessage` — replace from `let resolved = false;` (after the stop-typing block) through the end of the function:
```tsx
    let resolved = false;

    if (socket?.connected) {
      socket.emit(
        ...
      }, 5000);
    } else {
      resolved = true;
      await sendViaRestApi(tempId, messageToSend);
    }
  };
```
with:
```tsx
    if (socket?.connected) {
      sendInlineOverSocket(tempId, messageToSend);
    } else {
      // Not connected at all: one REST request, no race with a socket copy.
      await sendViaRestApi(tempId, messageToSend);
    }
  };
```

6. `sendInlineMessage` — replace from `let resolved = false;` through the end of the function with:
```tsx
    if (socket?.connected) {
      sendInlineOverSocket(tempId, text, messageType);
    } else {
      await sendInlineMessageViaRest(tempId, text, messageType);
    }
  };
```

7. `handleSendSticker` — replace its whole body after `isAtBottomRef.current = true;` (the `let resolved = false; ... }` block) with:
```tsx
    if (socket?.connected) {
      sendInlineOverSocket(tempId, sticker, "sticker");
    } else {
      await sendStickerViaRest(tempId, sticker);
    }
  };
```

8. Replace `handleRetryMessage` entirely with:
```tsx
  const handleRetryMessage = (failedMsg: Message) => {
    // A file is not kept after a failed upload; ask for it again rather than
    // re-sending an empty bubble.
    if (failedMsg.media && failedMsg.messageType !== "sticker" && failedMsg.messageType !== "gif") {
      setMessages((prev) => prev.filter((msg) => msg._id !== failedMsg._id));
      notify.info(t("chatPage.sendErrors.reattach") || "Attach the file again to send it.");
      return;
    }

    setMessages((prev) => prev.filter((msg) => msg._id !== failedMsg._id));
    const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const optimisticMessage: Message = {
      ...failedMsg,
      _id: tempId,
      status: "sending",
      isOptimistic: true,
    };
    setMessages((prev) => [...prev, optimisticMessage]);
    isAtBottomRef.current = true;

    // A failed reply goes back through the reply route, keeping its link.
    if (failedMsg.replyTo && failedMsg.replyTo._id) {
      replyToMessage({
        messageId: failedMsg.replyTo._id,
        message: failedMsg.message,
        receiver: selectedUser,
      })
        .unwrap()
        .then((result: any) => finalizeOptimistic(tempId, result.data || result))
        .catch((err: any) => {
          markOptimisticError(tempId);
          reportSendError(err);
        });
      return;
    }

    const type = failedMsg.messageType || "text";
    if (socket?.connected) {
      setIsSending(true);
      sendInlineOverSocket(tempId, failedMsg.message, type);
    } else if (type === "sticker") {
      sendStickerViaRest(tempId, failedMsg.message);
    } else if (type === "gif") {
      sendInlineMessageViaRest(tempId, failedMsg.message, type);
    } else {
      sendViaRestApi(tempId, failedMsg.message);
    }
  };
```

`eng.json`: add `"reattach": "Attach the file again to send it."` inside `chatPage.sendErrors`.

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false socketAck ChatContent
```
The older tests "refreshes it after the REST fallback too" and "writes it when the send fell back to REST too" use `offlineSocket()` (disconnected), which still goes over REST — they stay green.

- [ ] **Step 5: Commit** (tick `P3-CHAT-5`)

```bash
git add src/components/chat/lib/socketAck.ts src/components/chat/lib/socketAck.test.ts \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): a slow socket ack no longer sends the message twice

After 5 s without an ack the web re-sent the same text over REST, but the
server creates the message before it acks, so the app user received two
copies. Sends now stay on the socket: no ack in 10 s marks the bubble
failed with Retry (as the app does), a late ack or messageSent turns that
bubble into the real message, and a refusal is explained (P3-CHAT-4).
REST is used only when the socket is not connected at all. Retry keeps
the message type (sticker/GIF) and a reply's link; failed uploads ask for
the file again.

Still open (Phase 3 chat): P3-CHAT-6..20 and the chat i18n pass.
EOF
```

---

### Task P3-CHAT-6: Conversation list from `GET /conversations` only; typed previews; unread from the server (chat#10, chat#11, chat#19)

**Files:**
- Create: `src/components/chat/lib/conversationPreview.ts`, `src/components/chat/lib/unreadOverrides.ts`
- Modify: `src/components/chat/UsersList.tsx` — imports (`:3-11`), `getMessageText` (`:73-87`, removed), the query (`:126-129`), `handleNewMessage` (`:332-341`), `chatPartners` (`:526-631`), every bare `refetch();` (`:235, 339, 351, 363, 368, 377, 398, 490, 696, 779`) and their dependency arrays, loading/error copy (`:756-787`)
- Modify: `src/components/chat/ChatContent.tsx` `finalizeOptimistic` invalidation (`["Conversations", "UserMessages"]` → `["Conversations"]`)
- Modify: `src/utils/locales/eng.json` (`chatPage.preview.*`, `chatPage.list.loading`, `.loadError`, `.tryAgain`)
- Test: `src/components/chat/lib/conversationPreview.test.ts`, `src/components/chat/lib/unreadOverrides.test.ts` (new); `UsersList.test.tsx` (mock change + four cases); `ChatContent.test.tsx` (expectation `["Conversations", "UserMessages"]` → `["Conversations"]`, 3 places)

**Interfaces:**
- Consumes: `GET /api/v1/conversations?page=1&limit=100` → `{data: [{_id, participants:[{_id,name,images,userMode}], otherParticipant, lastMessage:{message, messageType, createdAt, sender}, lastMessageAt, unreadCount:number, isMuted, isPinned, isArchived}]}` (`be/controllers/conversations.js:13-75`). Before P1-CHAT-7 `lastMessage` has **no `media`**; after it, `media.type` is populated. `messageType` values from the Message model: `text, media, voice, sticker, poll, location, contact, system, gif, story_share, call` (call rows from `callMessageService.js`). The list already excludes deleted (`deletedBy`), archived and hub/topic rooms server-side (`lib/conversationListQuery.js`).
- Socket: `newMessage {message, unreadCount, senderId}` — `unreadCount` is a hard-coded `1` before P1-CHAT-4, so it is **not** read; `newVoiceMessage`/`newVideoMessage {message}`; `messagesRead {readBy}`.
- Produces: `previewOf(lastMessage, t): string` (pure, i18n'd); `pruneOverrides(server, overrides)` / `displayUnread(id, server, overrides)` / `bumpUnread(id, server, overrides)`. `UsersList` no longer calls `useGetUserMessagesQuery` (the hook stays exported; `ChatInfoPanel`/others may use it — `grep -rn useGetUserMessagesQuery src`). The `UserMessages` tag is no longer invalidated by sends.

- [ ] **Step 1: Write the failing tests**

Create `src/components/chat/lib/conversationPreview.test.ts`:

```ts
import { previewOf } from "./conversationPreview";

const t = () => "";

it.each([
  [{ message: "hi", messageType: "text" }, "hi"],
  [{ message: "Conversation started" }, ""],
  [{ messageType: "voice", message: "" }, "🎤 Voice message"],
  [{ messageType: "media", media: { type: "image" } }, "🖼️ Photo"],
  [{ messageType: "media", media: { type: "video" } }, "🎥 Video"],
  [{ messageType: "media", media: { type: "document" } }, "📎 File"],
  [{ messageType: "media" }, "📎 Attachment"],
  [{ messageType: "call", media: { type: "call" } }, "📞 Call"],
  [{ messageType: "call" }, "📞 Call"],
  [{ messageType: "location" }, "📍 Location"],
  [{ messageType: "location", media: { type: "location" } }, "📍 Location"],
  [{ messageType: "gif", message: "https://media.giphy.com/x.gif" }, "GIF"],
  [{ messageType: "sticker", message: "👋" }, "👋"],
  [{ messageType: "story_share", message: "Shared a story" }, "📖 Story"],
  [{ messageType: "poll", message: "" }, "📊 Poll"],
  [null, ""],
  [undefined, ""],
])("%j -> %s", (msg: any, expected: string) => {
  expect(previewOf(msg, t)).toBe(expected);
});

it("prefers the translation when there is one", () => {
  const tr = (key: string) => (key === "chatPage.preview.voice" ? "🎤 Sprachnachricht" : "");
  expect(previewOf({ messageType: "voice" }, tr)).toBe("🎤 Sprachnachricht");
});

it("shows a caption under a photo when the message has one (legacy media rows)", () => {
  expect(previewOf({ messageType: "media", media: { type: "image" }, message: "look" }, t)).toBe("🖼️ look");
});
```

Create `src/components/chat/lib/unreadOverrides.test.ts`:

```ts
import { bumpUnread, displayUnread, pruneOverrides } from "./unreadOverrides";

it("bumps from what is on screen, not from the socket's payload", () => {
  const server = { u2: 4 };
  const once = bumpUnread("u2", server, {});
  expect(once).toEqual({ u2: 5 });
  expect(bumpUnread("u2", server, once)).toEqual({ u2: 6 });
});

it("shows the override while it is ahead of the server", () => {
  expect(displayUnread("u2", { u2: 4 }, { u2: 6 })).toBe(6);
  expect(displayUnread("u3", { u2: 4 }, {})).toBe(0);
});

it("drops an override once the server has caught up (the server wins)", () => {
  expect(pruneOverrides({ u2: 6 }, { u2: 6, u3: 2 })).toEqual({ u3: 2 });
  expect(pruneOverrides({ u2: 0 }, { u2: 0 })).toEqual({});
});
```

`UsersList.test.tsx`:
- in the chatSlice mock delete `useGetUserMessagesQuery: ...`, delete `const mockUserMessages = jest.fn();` and its `beforeEach` setup. Add `isLoading: false, isError: false, error: undefined` to the default `mockConversations` return value.
- append:

```tsx
// --- The list is the conversations endpoint, and nothing else ---------------

it("shows a conversation the server returns, with a typed preview", () => {
  mockConversations.mockReturnValue({
    data: {
      data: [conversation({ lastMessage: { messageType: "voice", message: "", createdAt: "2026-09-20T10:00:00.000Z" } })],
    },
    isLoading: false,
    isError: false,
    refetch: jest.fn(),
  });
  renderList();
  expect(screen.getByText("🎤 Voice message")).toBeInTheDocument();
});

it("does not invent rows from raw messages (deleted conversations stay deleted)", () => {
  mockConversations.mockReturnValue({ data: { data: [] }, isLoading: false, isError: false, refetch: jest.fn() });
  renderList();
  expect(screen.queryByText("Ada")).not.toBeInTheDocument();
});

it("shows the server's unread count", () => {
  mockConversations.mockReturnValue({
    data: { data: [conversation({ unreadCount: 5 })] },
    isLoading: false,
    isError: false,
    refetch: jest.fn(),
  });
  renderList();
  expect(screen.getByTestId("users-list-unread-u2")).toHaveTextContent("5");
});

it("counts a live message up from the server count instead of trusting newMessage.unreadCount", () => {
  const handlers: Record<string, Function[]> = {};
  mockUseSocket.mockReturnValue({
    socket: {
      connected: false,
      on: (e: string, fn: Function) => {
        (handlers[e] = handlers[e] || []).push(fn);
      },
      off: jest.fn(),
      emit: jest.fn(),
    },
    isConnected: false,
  });
  mockConversations.mockReturnValue({
    data: { data: [conversation({ unreadCount: 4 })] },
    isLoading: false,
    isError: false,
    refetch: jest.fn(),
  });
  renderList();
  act(() => {
    handlers["newMessage"].forEach((fn) =>
      fn({ message: { _id: "m9", sender: { _id: "u2" }, receiver: "me" }, unreadCount: 1, senderId: "u2" })
    );
  });
  expect(screen.getByTestId("users-list-unread-u2")).toHaveTextContent("5");
});
```
(add `act` to the RTL import.) The unread badge has no testid today; Step 3 adds one.

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false conversationPreview unreadOverrides UsersList
```
Expected: FAIL — helper modules missing; `UsersList` calls the now-unmocked `useGetUserMessagesQuery`; the live badge shows `1` (the payload).

- [ ] **Step 3: Implement**

Create `src/components/chat/lib/conversationPreview.ts`:

```ts
/**
 * The one-line preview under a conversation in the list.
 *
 * Read from `lastMessage.messageType` first: before backend P1-CHAT-7 the
 * conversations endpoint does not populate `media`, so a call, a location or
 * a photo arrives as `{messageType}` only. `media.type` refines it when it is
 * there. Unknown types fall back to the text, then to "Attachment".
 */
type Translate = (key: string, options?: any) => string;

const tr = (t: Translate, key: string, fallback: string): string => t(key) || fallback;

export function previewOf(msg: any, t: Translate): string {
  if (!msg) return "";
  const text: string = (msg.message || msg.content || "").toString();
  const type: string = msg.messageType || "";
  const mediaType: string = (msg.media && msg.media.type) || "";

  // Legacy rows written by the old POST /messages/conversations.
  if (text === "Conversation started" && !mediaType) return "";

  if (type === "call" || mediaType === "call") return tr(t, "chatPage.preview.call", "📞 Call");
  if (type === "location" || mediaType === "location") return tr(t, "chatPage.preview.location", "📍 Location");
  if (type === "voice" || mediaType === "voice") return tr(t, "chatPage.preview.voice", "🎤 Voice message");
  if (type === "gif") return tr(t, "chatPage.preview.gif", "GIF");
  if (type === "story_share") return tr(t, "chatPage.preview.story", "📖 Story");
  if (type === "poll") return tr(t, "chatPage.preview.poll", "📊 Poll");
  if (type === "sticker") return text;

  if (mediaType) {
    if (mediaType.indexOf("image") === 0) {
      return text ? `🖼️ ${text}` : tr(t, "chatPage.preview.photo", "🖼️ Photo");
    }
    if (mediaType.indexOf("video") === 0) {
      return text ? `🎥 ${text}` : tr(t, "chatPage.preview.video", "🎥 Video");
    }
    return text ? `📎 ${text}` : tr(t, "chatPage.preview.file", "📎 File");
  }
  if (type === "media") return text || tr(t, "chatPage.preview.attachment", "📎 Attachment");
  return text;
}
```

Create `src/components/chat/lib/unreadOverrides.ts`:

```ts
/**
 * Live unread counts between two fetches of the conversations list.
 *
 * The server's per-conversation `unreadCount` is the truth. A socket message
 * bumps the number on screen by one until the next fetch, and the fetch wins
 * as soon as it has caught up. The socket payload's own `unreadCount` is not
 * read: before backend P1-CHAT-4 it is always 1.
 */
export type Counts = { [userId: string]: number };

export function displayUnread(id: string, server: Counts, overrides: Counts): number {
  if (overrides[id] !== undefined) return overrides[id];
  return server[id] || 0;
}

export function bumpUnread(id: string, server: Counts, overrides: Counts): Counts {
  return { ...overrides, [id]: displayUnread(id, server, overrides) + 1 };
}

export function pruneOverrides(server: Counts, overrides: Counts): Counts {
  const next: Counts = {};
  Object.keys(overrides).forEach((id) => {
    if ((server[id] || 0) < overrides[id]) next[id] = overrides[id];
  });
  return next;
}
```
(A zero override — set when a thread is opened — is pruned by the first fetch after `markAsRead`, which the ack already triggers at `:483-492`.)

`UsersList.tsx`:
1. Imports: remove `useGetUserMessagesQuery,` from the chatSlice import; add
```tsx
import { previewOf } from "./lib/conversationPreview";
import { bumpUnread, displayUnread, pruneOverrides, Counts } from "./lib/unreadOverrides";
```
   (`Counts` is a type alias; if Babel complains, inline `{ [id: string]: number }` instead.)
2. Delete `getMessageText` (`:73-87`).
3. Replace
```tsx
  const { data, error, isLoading, isError, refetch } = useGetUserMessagesQuery(
    currentUser?._id,
    { skip: !currentUser?._id }
  );
  // The shared argument: ...
  const { data: conversationsData, refetch: refetchConversations } =
    useGetConversationsQuery(CONVERSATIONS_PAGE, { skip: !currentUser?._id });
```
with
```tsx
  // The list is GET /conversations and nothing else, as in the app. It used
  // to be merged with GET /messages/user/:id (500 raw messages), which knows
  // nothing about deleted conversations or blocks -- every deleted chat came
  // back. The shared argument: ChatInfoPanel asks with the same one.
  const {
    data: conversationsData,
    error,
    isLoading,
    isError,
    refetch: refetchConversations,
  } = useGetConversationsQuery(CONVERSATIONS_PAGE, { skip: !currentUser?._id });
```
4. Delete every bare `refetch();` line (each sits next to `refetchConversations();`) and `refetch` from the dependency arrays (`[pinConversation, unpinConversation, refetch, ...]`, the socket effect `[socket, refetch, refetchConversations]`, the markAsRead effect). Check: `grep -n "\brefetch\b" src/components/chat/UsersList.tsx` prints only `refetch: refetchConversations` lines.
5. Unread: keep `const [unreadCounts, setUnreadCounts] = useState<Record<string, number>>({});` (now "overrides"). Add after it:
```tsx
  // The server's counts, by partner id, for the override helpers.
  const serverUnread = useMemo(() => {
    const counts: Counts = {};
    ((conversationsData && conversationsData.data) || []).forEach((c: any) => {
      const other = c.otherParticipant || (c.participants || []).find((p: any) => p && p._id !== currentUser?._id);
      if (other && other._id) counts[other._id] = c.unreadCount || 0;
    });
    return counts;
  }, [conversationsData, currentUser]);
  const serverUnreadRef = useRef<Counts>({});
  useEffect(() => {
    serverUnreadRef.current = serverUnread;
    setUnreadCounts((prev) => pruneOverrides(serverUnread, prev));
  }, [serverUnread]);
```
6. Replace `handleNewMessage`:
```tsx
    const handleNewMessage = (data: { message: Message; unreadCount: number; senderId: string }) => {
      if (data.senderId !== activeUserIdRef.current) {
        setUnreadCounts((prev) => ({
          ...prev,
          [data.senderId]: data.unreadCount,
        }));
      }
      refetch();
      refetchConversations();
    };
```
with
```tsx
    const handleNewMessage = (data: { message: Message; senderId?: string }) => {
      const senderId = data.senderId || (data.message && (data.message as any).sender && (data.message as any).sender._id);
      if (senderId && senderId !== activeUserIdRef.current) {
        setUnreadCounts((prev) => bumpUnread(senderId, serverUnreadRef.current, prev));
      }
      refetchConversations();
    };
```
   and in `handleNewVoiceMessage` / `handleNewVideoMessage` replace `[senderId]: (prev[senderId] || 0) + 1,` blocks with `setUnreadCounts((prev) => bumpUnread(senderId, serverUnreadRef.current, prev));`.
7. Replace the whole `chatPartners` memo (`:526-631`) with:
```tsx
  const chatPartners = useMemo(() => {
    if (!currentUser) return [];
    const rows: any[] = (conversationsData && conversationsData.data) || [];
    const partners: Array<User & { lastMessage?: string; unreadCount: number; lastMessageTime?: Date }> = [];
    const seen: { [id: string]: boolean } = {};

    rows.forEach((conversation: any) => {
      const otherUser =
        conversation.otherParticipant ||
        (conversation.participants || []).find((p: any) => p && p._id !== currentUser._id);
      if (!otherUser || !otherUser._id || seen[otherUser._id]) return;
      seen[otherUser._id] = true;

      const lastMsg = conversation.lastMessage;
      const when = (lastMsg && lastMsg.createdAt) || conversation.lastMessageAt;
      partners.push({
        ...otherUser,
        imageUrls: otherUser.imageUrls || otherUser.images || [],
        lastMessage: previewOf(lastMsg, t as any),
        unreadCount:
          otherUser._id === activeUserId
            ? 0
            : displayUnread(otherUser._id, serverUnread, unreadCounts),
        lastMessageTime: when ? new Date(when) : undefined,
        status: getUserStatus(otherUser._id) as any,
        lastSeen: userStatuses[otherUser._id]?.lastSeen,
        conversationId: conversation._id,
        isPinned: Boolean(conversation.isPinned),
        isMuted: Boolean(conversation.isMuted),
      });
    });

    return partners.sort((a, b) => {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      const aTime = a.lastMessageTime ? a.lastMessageTime.getTime() : 0;
      const bTime = b.lastMessageTime ? b.lastMessageTime.getTime() : 0;
      return bTime - aTime;
    });
  }, [conversationsData, currentUser, userStatuses, getUserStatus, unreadCounts, serverUnread, activeUserId, t]);
```
8. Loading / error copy (`:756-787`): `"Loading chats..."` → `{t("chatPage.list.loading") || "Loading chats..."}`; `"Error loading conversations"` / `"An unexpected error occurred"` → `t("chatPage.list.loadError") || "Couldn't load your conversations"`; `"Try Again"` → `t("chatPage.list.tryAgain") || "Try again"`; the retry button calls `refetchConversations()` only.
9. The unread badge (`:910`): `<span className="users-list-badge">` → `<span className="users-list-badge" data-testid={`users-list-unread-${user._id}`}>`.

`ChatContent.tsx` `finalizeOptimistic`: `invalidateTags(["Conversations", "UserMessages"])` → `invalidateTags(["Conversations"])`; update its three expectations in `ChatContent.test.tsx` (`toHaveBeenCalledWith(["Conversations", "UserMessages"])` → `toHaveBeenCalledWith(["Conversations"])`).

`eng.json`:
```json
    "preview": {
      "call": "📞 Call",
      "location": "📍 Location",
      "voice": "🎤 Voice message",
      "gif": "GIF",
      "story": "📖 Story",
      "poll": "📊 Poll",
      "photo": "🖼️ Photo",
      "video": "🎥 Video",
      "file": "📎 File",
      "attachment": "📎 Attachment"
    },
```
and in the existing `chatPage.list` object add `"loading": "Loading chats...", "loadError": "Couldn't load your conversations", "tryAgain": "Try again"`.

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false conversationPreview unreadOverrides UsersList ChatContent ChatInfoPanel conversationMatch
```

- [ ] **Step 5: Commit** (tick `P3-CHAT-6`)

```bash
git add src/components/chat/lib/conversationPreview.ts src/components/chat/lib/conversationPreview.test.ts \
  src/components/chat/lib/unreadOverrides.ts src/components/chat/lib/unreadOverrides.test.ts \
  src/components/chat/UsersList.tsx src/components/chat/UsersList.test.tsx \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): conversation list from /conversations only, real unread counts

The list merged GET /conversations with 500 raw messages from
/messages/user/:id, which knows nothing about deleted conversations or
blocks, so every deleted chat came back. It is now the conversations
endpoint only, as in the app. Previews are typed from messageType first
(call, location, voice, GIF, story, poll; media.type refines it once the
backend populates it) and translated. Unread is the server's count; a
live message bumps what is on screen by one until the next fetch instead
of trusting newMessage.unreadCount, which is always 1 today.

Still open (Phase 3 chat): P3-CHAT-7..20 and the chat i18n pass.
EOF
```

---

### Task P3-CHAT-7: Catch up after a reconnect; recover a kicked tab; refresh instead of logging out on `tokenExpired` (chat#12, chat#20)

**Files:**
- Create: `src/store/refreshSession.ts`
- Modify: `src/components/chat/hooks/useSocket.ts` — context shape (`:19-23`, `:131-135`), provider effect (`:137-262`), value (`:270-274`)
- Create: `src/components/chat/ConnectionBanner.tsx`
- Modify: `src/components/chat/ChatContent.tsx` — reconnect effect next to the "Request user status" effect (`:704-727`); banner above `<PinnedBar` 
- Modify: `src/store/index.ts` (call `setupListeners`)
- Modify: `src/utils/locales/eng.json` (`chatPage.connection.*`)
- Test: `src/store/refreshSession.test.ts` (new), `src/components/chat/hooks/useSocket.test.tsx` (three cases; the existing `it.each(["authError","tokenExpired"])` stays valid — its store has no refresh token), `src/components/chat/ConnectionBanner.test.tsx` (new), `src/store/setupListeners.test.ts` (new), `ChatContent.test.tsx` (one case + `endpoints` in the mock)

**Interfaces:**
- Consumes: server `forceDisconnect {reason:'max_connections'}` then `disconnect(true)` (`socketHandler.js:470-474`) — socket.io-client does **not** auto-reconnect after a server-side disconnect; `tokenExpired {reason:'token_expired'}` then `disconnect(true)` (`:231-236`); `POST /api/v1/auth/refresh-token {refreshToken}` → `{token, refreshToken?}` (the same call `apiSlice.ts:99-131` makes).
- Produces (context, additive — every existing consumer keeps working): `useSocket()` returns `{ socket, isConnected, emit, connectionEpoch: number, kicked: boolean, reconnect(): void }`. `connectionEpoch` increments on every `connect` after the first one the provider saw (including the first connect of a socket re-created after a token refresh). On each such reconnect the provider also invalidates the `Conversations` tag. `refreshSession(dispatch, getState): Promise<boolean>`.

- [ ] **Step 1: Write the failing tests**

Create `src/store/refreshSession.test.ts`:

```ts
import { refreshSession } from "./refreshSession";

const okResponse = (body: any) =>
  Promise.resolve(new Response(JSON.stringify(body), { status: 200, headers: { "content-type": "application/json" } }));

afterEach(() => jest.restoreAllMocks());

function harness(userInfo: any) {
  const actions: any[] = [];
  const dispatch = (a: any) => {
    actions.push(a);
    return a;
  };
  const getState = () => ({ auth: { userInfo } });
  return { actions, dispatch, getState };
}

it("swaps in the fresh token and keeps the session", async () => {
  (global as any).fetch = jest.fn(() => okResponse({ token: "new-t", refreshToken: "new-r" }));
  const h = harness({ user: { _id: "u1" }, token: "old-t", refreshToken: "old-r" });
  await expect(refreshSession(h.dispatch, h.getState)).resolves.toBe(true);
  expect(h.actions[0].type).toBe("auth/setCredentials");
  expect(h.actions[0].payload).toEqual(expect.objectContaining({ token: "new-t", refreshToken: "new-r" }));
  const [, init] = ((global as any).fetch as jest.Mock).mock.calls[0];
  expect(JSON.parse(init.body)).toEqual({ refreshToken: "old-r" });
});

it("logs out with no refresh token", async () => {
  (global as any).fetch = jest.fn();
  const h = harness({ user: { _id: "u1" }, token: "old-t" });
  await expect(refreshSession(h.dispatch, h.getState)).resolves.toBe(false);
  expect(h.actions[0].type).toBe("auth/logout");
  expect((global as any).fetch).not.toHaveBeenCalled();
});

it("logs out when the refresh is refused", async () => {
  (global as any).fetch = jest.fn(() =>
    Promise.resolve(new Response(JSON.stringify({ success: false }), { status: 401 }))
  );
  const h = harness({ user: { _id: "u1" }, token: "old-t", refreshToken: "bad" });
  await expect(refreshSession(h.dispatch, h.getState)).resolves.toBe(false);
  expect(h.actions[0].type).toBe("auth/logout");
});
```
(`authSlice.ts:100` names the slice `auth`, so the types are `auth/setCredentials` and `auth/logout`.)

`useSocket.test.tsx` — extend `Probe` to also render `connectionEpoch` and `kicked`:
```tsx
const Probe: React.FC = () => {
  const { socket, isConnected, emit, connectionEpoch, kicked } = useSocket() as any;
  return (
    <div>
      <span data-testid="socket">{socket ? (socket as any).id : "none"}</span>
      <span data-testid="connected">{isConnected ? "yes" : "no"}</span>
      <span data-testid="emit">{typeof emit}</span>
      <span data-testid="epoch">{String(connectionEpoch)}</span>
      <span data-testid="kicked">{kicked ? "yes" : "no"}</span>
    </div>
  );
};
```
add `connect: jest.fn(() => { socket.connected = true; return socket; })` to `makeFakeSocket`'s object (and `connect: jest.Mock;` to `FakeSocket`), then append:

```tsx
it("counts reconnects, not the first connect", async () => {
  const sock = makeFakeSocket("sock-epoch");
  mockIo.mockImplementation(() => sock);
  await renderProvider(makeTestStore("tok-epoch"));
  await waitFor(() => expect(sock.handlerCount("connect")).toBeGreaterThan(0));

  act(() => sock.fire("connect"));
  expect(screen.getByTestId("epoch")).toHaveTextContent("0");
  act(() => sock.fire("disconnect"));
  act(() => sock.fire("connect"));
  expect(screen.getByTestId("epoch")).toHaveTextContent("1");
});

it("marks a tab the server kicked and reconnects it when it is shown again", async () => {
  const sock = makeFakeSocket("sock-kicked");
  mockIo.mockImplementation(() => sock);
  await renderProvider(makeTestStore("tok-kicked"));
  await waitFor(() => expect(sock.handlerCount("forceDisconnect")).toBe(1));

  act(() => {
    sock.connected = false;
    sock.fire("forceDisconnect", { reason: "max_connections" });
  });
  expect(screen.getByTestId("kicked")).toHaveTextContent("yes");

  Object.defineProperty(document, "visibilityState", { configurable: true, get: () => "visible" });
  act(() => {
    document.dispatchEvent(new Event("visibilitychange"));
  });
  expect(sock.connect).toHaveBeenCalled();
});

it("refreshes the session on tokenExpired when a refresh token is stored", async () => {
  const sock = makeFakeSocket("sock-refresh");
  mockIo.mockImplementation(() => sock);
  (global as any).fetch = jest.fn(() =>
    Promise.resolve(new Response(JSON.stringify({ token: "tok-fresh" }), { status: 200, headers: { "content-type": "application/json" } }))
  );
  const store = configureStore({
    reducer: { auth: authReducer },
    preloadedState: { auth: { userInfo: { user: { _id: "u1" }, token: "tok-old", refreshToken: "r1" } } } as any,
  });
  await renderProvider(store);
  await waitFor(() => expect(sock.handlerCount("tokenExpired")).toBe(1));

  await act(async () => {
    sock.fire("tokenExpired", { reason: "token_expired" });
    await Promise.resolve();
    await Promise.resolve();
  });

  await waitFor(() => expect((store.getState() as any).auth.userInfo.token).toBe("tok-fresh"));
});
```

Create `src/components/chat/ConnectionBanner.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import ConnectionBanner from "./ConnectionBanner";

const mockUseSocket = jest.fn();
jest.mock("./hooks/useSocket", () => ({ useSocket: () => mockUseSocket() }));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

it("renders nothing while connected and not kicked", () => {
  mockUseSocket.mockReturnValue({ kicked: false, reconnect: jest.fn() });
  const { container } = render(<ConnectionBanner />);
  expect(container).toBeEmptyDOMElement();
});

it("offers to reconnect a kicked tab", () => {
  const reconnect = jest.fn();
  mockUseSocket.mockReturnValue({ kicked: true, reconnect });
  render(<ConnectionBanner />);
  expect(screen.getByTestId("connection-banner")).toHaveTextContent("Chat is open somewhere else");
  fireEvent.click(screen.getByTestId("connection-banner-reconnect"));
  expect(reconnect).toHaveBeenCalled();
});
```

Create `src/store/setupListeners.test.ts`:

```ts
const mockSetupListeners = jest.fn();
jest.mock("@reduxjs/toolkit/query", () => ({
  ...jest.requireActual("@reduxjs/toolkit/query"),
  setupListeners: (...args: any[]) => mockSetupListeners(...args),
}));

it("wires RTK Query's online/focus listeners to the store, so refetchOnReconnect does something", () => {
  jest.isolateModules(() => {
    const store = require("./index").default;
    expect(mockSetupListeners).toHaveBeenCalledWith(store.dispatch);
  });
});
```

`ChatContent.test.tsx`:
- add `const mockInitiate = jest.fn();` and in the chatSlice factory change `chatApiSlice` to
```tsx
  chatApiSlice: {
    util: { ... unchanged ... },
    endpoints: { getConversation: { initiate: (...args: any[]) => mockInitiate(...args) } },
  },
```
  and in `beforeEach`: `mockInitiate.mockImplementation(() => ({ type: "chatApi/initiate" }));`
- append:
```tsx
function ChatWithEpoch({ epoch }: { epoch: number }) {
  mockUseSocket.mockReturnValue({ socket: null, isConnected: true, emit: jest.fn(), connectionEpoch: epoch });
  return <ChatContent selectedUser="u2" userName="Ada" profilePicture="" />;
}

it("re-reads the newest page of the open thread after a reconnect", () => {
  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user: { _id: "me", name: "Me" }, token: "t" } }) => state },
  });
  const tree = (epoch: number) => (
    <Provider store={store}>
      <MemoryRouter initialEntries={["/chat/u2"]}>
        <ChatWithEpoch epoch={epoch} />
      </MemoryRouter>
    </Provider>
  );
  const view = render(tree(0));
  expect(mockInitiate).not.toHaveBeenCalled();

  view.rerender(tree(1));
  expect(mockInitiate).toHaveBeenCalledWith(
    { senderId: "me", receiverId: "u2", page: 1, limit: 50 },
    { forceRefetch: true, subscribe: false }
  );
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false refreshSession useSocket ConnectionBanner setupListeners ChatContent.test
```
Expected: FAIL — modules missing; `epoch`/`kicked` render `undefined`/`no`; `tokenExpired` logs out; `setupListeners` never called; no initiate on epoch change.

- [ ] **Step 3: Implement**

Create `src/store/refreshSession.ts`:

```ts
import { BASE_URL } from "../constants";
import { logout, setCredentials } from "./slices/authSlice";

/**
 * One silent token refresh, outside RTK Query: the socket's `tokenExpired`
 * push has no request to retry, so baseQueryWithReauth never sees it. Same
 * endpoint and body as apiSlice.ts. A new token re-creates the socket
 * (SocketProvider keys on it); a failure ends the session as before.
 */
export async function refreshSession(
  dispatch: (action: any) => any,
  getState: () => any
): Promise<boolean> {
  const userInfo = getState() && getState().auth && getState().auth.userInfo;
  const refreshToken = userInfo && userInfo.refreshToken;
  if (!refreshToken) {
    dispatch(logout(undefined));
    return false;
  }
  try {
    const res = await fetch(`${BASE_URL}/api/v1/auth/refresh-token`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });
    const body: any = res.ok ? await res.json() : null;
    if (body && body.token) {
      dispatch(
        setCredentials({
          ...userInfo,
          token: body.token,
          refreshToken: body.refreshToken || refreshToken,
        })
      );
      return true;
    }
  } catch (err) {
    // Network failure: same outcome as a refusal.
  }
  dispatch(logout(undefined));
  return false;
}
```

`useSocket.ts`:
1. Imports: `import React, { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';`, `import { useSelector, useDispatch, useStore } from 'react-redux';`, `import { refreshSession } from '../../../store/refreshSession';`
2. `SocketContextValue` gains
```ts
  /** Increments on every reconnect (not the first connect). Consumers re-read on change. */
  connectionEpoch: number;
  /** The server dropped this tab (`forceDisconnect`, >5 sockets); it will not reconnect by itself. */
  kicked: boolean;
  reconnect: () => void;
```
   and the `createContext` default gains `connectionEpoch: 0, kicked: false, reconnect: () => {},`.
3. Provider state (top of `SocketProvider`):
```ts
  const [connectionEpoch, setConnectionEpoch] = useState(0);
  const [kicked, setKicked] = useState(false);
  const store = useStore();
  // Survives a token-rotation socket swap, so the new socket's first connect
  // still counts as a REconnect (the thread missed whatever came meanwhile).
  const seenConnectRef = useRef(false);
```
4. In the effect: in the `if (!token)` branch add `seenConnectRef.current = false; setKicked(false);`. Replace
```ts
    const onConnect = () => setIsConnected(true);
```
with
```ts
    const onConnect = () => {
      setIsConnected(true);
      setKicked(false);
      if (seenConnectRef.current) {
        // REST, media, voice, call and wave messages sent while this tab was
        // away are not in the server's offline queue; the list re-reads now
        // and every open thread re-reads its newest page off the epoch.
        setConnectionEpoch((n) => n + 1);
        (dispatch as any)((chatApiSlice.util as any).invalidateTags(['Conversations']));
      }
      seenConnectRef.current = true;
    };
    const onForceDisconnect = () => setKicked(true);
```
   Replace `onTokenExpired` with:
```ts
    // The server has given up on this token and closed the socket. Refresh
    // it the way a REST 401 would; the new token re-creates the socket. Only
    // a failed refresh ends the session (refreshSession logs out).
    const onTokenExpired = (data?: { reason?: string }) => {
      logError('tokenExpired — refreshing', data);
      refreshSession(dispatch as any, store.getState);
    };
```
   Attach / detach `forceDisconnect` alongside the others (`s.on('forceDisconnect', onForceDisconnect);` and `attached.off('forceDisconnect', onForceDisconnect);`). In `if (s.connected) { setIsConnected(true); }` also set `seenConnectRef.current = true;`. Add `store` to the effect's dependency array.
5. After the effect:
```ts
  const reconnect = useCallback(() => {
    if (globalSocket && !globalSocket.connected) globalSocket.connect();
  }, []);

  // A kicked tab comes back when the person returns to it -- never on its
  // own timer, or two open tabs would keep kicking each other.
  useEffect(() => {
    if (!kicked) return undefined;
    const onVisible = () => {
      if (document.visibilityState === 'visible') reconnect();
    };
    document.addEventListener('visibilitychange', onVisible);
    return () => document.removeEventListener('visibilitychange', onVisible);
  }, [kicked, reconnect]);
```
6. `const value: SocketContextValue = { socket, isConnected, emit, connectionEpoch, kicked, reconnect };`

Create `src/components/chat/ConnectionBanner.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { useSocket } from "./hooks/useSocket";

/** Shown when the server dropped this tab for a newer connection. */
const ConnectionBanner: React.FC = () => {
  const { t } = useTranslation();
  const { kicked, reconnect } = useSocket() as any;
  if (!kicked) return null;
  return (
    <div
      role="status"
      data-testid="connection-banner"
      className="flex items-center justify-between gap-3 bg-amber-50 px-4 py-2 text-sm text-amber-900 dark:bg-amber-500/10 dark:text-amber-200"
    >
      <span>
        {t("chatPage.connection.kicked") ||
          "Chat is open somewhere else, so this tab stopped receiving messages."}
      </span>
      <button
        type="button"
        data-testid="connection-banner-reconnect"
        onClick={() => reconnect()}
        className="shrink-0 rounded-chip bg-amber-600 px-3 py-1 text-xs font-semibold text-white"
      >
        {t("chatPage.connection.reconnect") || "Use here"}
      </button>
    </div>
  );
};

export default ConnectionBanner;
```

`ChatContent.tsx`:
1. `import ConnectionBanner from "./ConnectionBanner";`
2. `const { socket, emit } = useSocket();` → `const { socket, emit, connectionEpoch } = useSocket() as any;`
3. Below the "Request user status" effect add:
```tsx
  // After a reconnect, re-read the newest page of this thread: anything that
  // arrived while the socket was down (laptop sleep, network drop, a kicked
  // tab) reached the server but never reached this screen. `merge` upserts by
  // id, so nothing doubles.
  useEffect(() => {
    if (!connectionEpoch || !userId || !selectedUser) return;
    const endpoint = (chatApiSlice as any).endpoints && (chatApiSlice as any).endpoints.getConversation;
    if (!endpoint) return;
    dispatch(
      endpoint.initiate(
        { senderId: userId, receiverId: selectedUser, page: 1, limit: MESSAGE_PAGE_SIZE },
        { forceRefetch: true, subscribe: false }
      )
    );
    // Only the epoch decides; a conversation switch has its own fetch.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [connectionEpoch]);
```
4. Render `<ConnectionBanner />` directly above `{/* Pinned messages bar (renders null when there are none) */}`.

`src/store/index.ts`: add `import { setupListeners } from "@reduxjs/toolkit/query";` and after `const store = makeStore(readPreloadedState());`:
```ts
// RTK Query's online/offline (and focus) listeners. Without this call the
// apiSlice's `refetchOnReconnect: true` did nothing. Browser only: the
// prerender builds stores in node.
if (typeof window !== "undefined") setupListeners(store.dispatch);
```

`eng.json`, in `chatPage`:
```json
    "connection": {
      "kicked": "Chat is open somewhere else, so this tab stopped receiving messages.",
      "reconnect": "Use here"
    },
```

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false refreshSession useSocket ConnectionBanner setupListeners ChatContent UsersList preloaded
```
The `preloadedState`/`preloadedRefetch` store tests must stay green (`setupListeners` only adds window listeners).

- [ ] **Step 5: Commit** (tick `P3-CHAT-7`)

```bash
git add src/store/refreshSession.ts src/store/refreshSession.test.ts src/store/index.ts src/store/setupListeners.test.ts \
  src/components/chat/hooks/useSocket.ts src/components/chat/hooks/useSocket.test.tsx \
  src/components/chat/ConnectionBanner.tsx src/components/chat/ConnectionBanner.test.tsx \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): catch up after a reconnect and recover dropped tabs

Messages that arrived while the socket was down (REST, media, voice,
call, wave -- none of them in the server's offline queue) never showed
until the thread was reopened. Every reconnect now re-reads the list and
the open thread's newest page. A tab the server drops for a newer
connection shows a "use here" banner and reconnects when it is shown
again (socket.io does not reconnect after a server-side disconnect).
tokenExpired refreshes the token the way a REST 401 does instead of
logging the user out. setupListeners is finally called, so
refetchOnReconnect works.

Still open (Phase 3 chat): P3-CHAT-8..20 and the chat i18n pass.
EOF
```

---

### Task P3-CHAT-8: Videos go through `POST /messages/video` with the server's limits checked first (chat#16)

**Files:**
- Modify: `src/store/slices/chatSlice.ts` (add `getVideoMessageConfig` query + hook)
- Create: `src/components/chat/lib/videoLimits.ts`
- Modify: `src/components/chat/ChatContent.tsx` — imports, `handleSendMedia` (`:1380-1428`)
- Modify: `src/components/chat/ChatContent.test.tsx`, `src/components/chat/ChatContent.pagination.test.tsx` (mock factories gain two hooks)
- Modify: `src/utils/locales/eng.json` (`chatPage.video.*`)
- Test: `src/components/chat/lib/videoLimits.test.ts` (new), `chatActionsEndpoints.test.ts` (one case), `ChatContent.test.tsx` (two cases)

**Interfaces:**
- Consumes: `GET /api/v1/messages/video-config` (public) → `{success, data: {video: {maxDuration: 600, maxSize: 1073741824, allowedTypes: ['video/mp4','video/quicktime','video/x-msvideo','video/webm','video/3gpp','video/x-m4v'], ...}, voice: {...}}}` (`be/controllers/advancedMessages.js:800-818`, `utils/videoUtils.js:9-22,202-219`). `POST /api/v1/messages/video` multipart field `video` + `receiver` (`routes/messages.js:59-68`): checks duration server-side (400 "Video duration … exceeds maximum …"), makes a thumbnail, stores `messageType:'media', media:{type:'video', thumbnail, duration, dimensions}`, emits `newVideoMessage` to the receiver, returns `201 {data: message}`. It ignores any caption.
- Behaviour: a caption typed with a video is sent as a separate text message right after the video succeeds (the endpoint has no caption field). If the config request fails, the client falls back to the server's current values (600 s, 1 GB) — the server enforces them anyway.
- Produces: `useGetVideoMessageConfigQuery`; `checkVideo(file, limits, durationSeconds|null): "ok" | "tooBig" | "tooLong" | "badType"`; `readVideoDuration(file): Promise<number|null>`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/chat/lib/videoLimits.test.ts`:

```ts
import { checkVideo, DEFAULT_VIDEO_LIMITS, limitsFromConfig } from "./videoLimits";

const file = (type: string, size: number) => ({ type, size } as any as File);

it("accepts a video inside the limits", () => {
  expect(checkVideo(file("video/mp4", 10), DEFAULT_VIDEO_LIMITS, 30)).toBe("ok");
});

it("refuses one over the size cap before uploading", () => {
  expect(checkVideo(file("video/mp4", DEFAULT_VIDEO_LIMITS.maxSize + 1), DEFAULT_VIDEO_LIMITS, 30)).toBe("tooBig");
});

it("refuses one over the duration cap when the duration is known", () => {
  expect(checkVideo(file("video/mp4", 10), DEFAULT_VIDEO_LIMITS, 601)).toBe("tooLong");
  expect(checkVideo(file("video/mp4", 10), DEFAULT_VIDEO_LIMITS, null)).toBe("ok");
});

it("refuses a type the server does not take", () => {
  expect(checkVideo(file("video/x-matroska", 10), DEFAULT_VIDEO_LIMITS, 30)).toBe("badType");
});

it("reads the server's config and keeps the defaults for anything missing", () => {
  const limits = limitsFromConfig({ data: { video: { maxDuration: 180, maxSize: 100 } } });
  expect(limits.maxDuration).toBe(180);
  expect(limits.maxSize).toBe(100);
  expect(limits.allowedTypes).toEqual(DEFAULT_VIDEO_LIMITS.allowedTypes);
  expect(limitsFromConfig(undefined)).toEqual(DEFAULT_VIDEO_LIMITS);
});
```

`chatActionsEndpoints.test.ts`:
```ts
  it("getVideoMessageConfig -> GET /api/v1/messages/video-config", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((chatApiSlice.endpoints as any).getVideoMessageConfig.initiate(undefined));
    expect(new URL(calls[0].url).pathname).toBe(`${MESSAGES_URL}/video-config`);
    expect(calls[0].method).toBe("GET");
  });
```

`ChatContent.test.tsx`:
- add `const mockSendVideo = jest.fn();` and `const mockSendMedia = jest.fn();`; in the factory replace `useSendMediaMessageMutation: () => mutation(),` with `useSendMediaMessageMutation: () => [mockSendMedia, { isLoading: false }],` and add
```tsx
  useSendVideoMessageMutation: () => [mockSendVideo, { isLoading: false }],
  useGetVideoMessageConfigQuery: () => ({ data: { data: { video: { maxDuration: 600, maxSize: 1000 } } } }),
```
  and in `beforeEach`: `mockSendVideo.mockReturnValue({ unwrap: () => Promise.resolve({ data: { _id: "m-vid", messageType: "media", media: { type: "video", url: "v.mp4" }, sender: { _id: "me" }, receiver: "u2", createdAt: new Date().toISOString() } }) });` and `mockSendMedia.mockReturnValue({ unwrap: () => Promise.resolve({ data: { _id: "m-img", sender: { _id: "me" } } }) });`
- `ChatContent.pagination.test.tsx` factory: add the same two lines (`useSendVideoMessageMutation: () => mutation(),` and `useGetVideoMessageConfigQuery: () => ({ data: undefined }),`).
- append:
```tsx
// --- Videos -----------------------------------------------------------------

function pickFile(file: File) {
  const input = document.querySelector('input[type="file"]') as HTMLInputElement;
  fireEvent.change(input, { target: { files: [file] } });
}

beforeAll(() => {
  if (!(URL as any).createObjectURL) (URL as any).createObjectURL = () => "blob:x";
  if (!(URL as any).revokeObjectURL) (URL as any).revokeObjectURL = () => undefined;
});

it("sends a video through /messages/video (field `video`), not as an attachment", async () => {
  mockUseSocket.mockReturnValue(offlineSocket());
  renderChat("/chat/u2");
  pickFile(new File(["x"], "clip.mp4", { type: "video/mp4" }));
  fireEvent.submit(messageBox().closest("form")!);

  await waitFor(() => expect(mockSendVideo).toHaveBeenCalledTimes(1));
  const form: FormData = mockSendVideo.mock.calls[0][0];
  expect(form.get("video")).toBeTruthy();
  expect(form.get("receiver")).toBe("u2");
  expect(mockSendMedia).not.toHaveBeenCalled();
});

it("refuses a video over the server's size cap before uploading", async () => {
  mockUseSocket.mockReturnValue(offlineSocket());
  renderChat("/chat/u2");
  pickFile(new File(["x".repeat(2000)], "big.mp4", { type: "video/mp4" }));
  fireEvent.submit(messageBox().closest("form")!);

  await waitFor(() => expect(screen.queryByTestId("msg-status-sending")).not.toBeInTheDocument());
  expect(mockSendVideo).not.toHaveBeenCalled();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false videoLimits chatActionsEndpoints ChatContent
```
Expected: FAIL — helpers and endpoint missing; the video goes to `sendMediaMessage` with field `attachment`.

- [ ] **Step 3: Implement**

`chatSlice.ts`, after `sendVideoMessage`:
```ts
    // GET /api/v1/messages/video-config (public): the server's video caps,
    // read before a 1 GB upload rather than after it.
    getVideoMessageConfig: builder.query({
      query: () => ({ url: `${MESSAGES_URL}/video-config` }),
      keepUnusedDataFor: 3600,
    }),
```
and export `useGetVideoMessageConfigQuery,` next to `useSendVideoMessageMutation,`.

Create `src/components/chat/lib/videoLimits.ts`:

```ts
/** The server's caps (utils/videoUtils.js), used until /video-config answers. */
export interface VideoLimits {
  maxDuration: number;
  maxSize: number;
  allowedTypes: string[];
}

export const DEFAULT_VIDEO_LIMITS: VideoLimits = {
  maxDuration: 600,
  maxSize: 1024 * 1024 * 1024,
  allowedTypes: ["video/mp4", "video/quicktime", "video/x-msvideo", "video/webm", "video/3gpp", "video/x-m4v"],
};

export function limitsFromConfig(response: any): VideoLimits {
  const video = response && response.data && response.data.video;
  if (!video) return DEFAULT_VIDEO_LIMITS;
  return {
    maxDuration: Number(video.maxDuration) || DEFAULT_VIDEO_LIMITS.maxDuration,
    maxSize: Number(video.maxSize) || DEFAULT_VIDEO_LIMITS.maxSize,
    allowedTypes:
      Array.isArray(video.allowedTypes) && video.allowedTypes.length
        ? video.allowedTypes
        : DEFAULT_VIDEO_LIMITS.allowedTypes,
  };
}

export type VideoCheck = "ok" | "tooBig" | "tooLong" | "badType";

export function checkVideo(file: File, limits: VideoLimits, durationSeconds: number | null): VideoCheck {
  const type = (file.type || "").split(";")[0];
  if (type && limits.allowedTypes.indexOf(type) === -1) return "badType";
  if (file.size > limits.maxSize) return "tooBig";
  if (durationSeconds !== null && durationSeconds > limits.maxDuration) return "tooLong";
  return "ok";
}

/** The file's duration from its metadata, or null when the browser can't tell (2 s cap). */
export function readVideoDuration(file: File): Promise<number | null> {
  return new Promise((resolve) => {
    if (typeof document === "undefined" || !(URL as any).createObjectURL) {
      resolve(null);
      return;
    }
    const url = URL.createObjectURL(file);
    const video = document.createElement("video");
    let done = false;
    const finish = (value: number | null) => {
      if (done) return;
      done = true;
      URL.revokeObjectURL(url);
      resolve(value);
    };
    video.preload = "metadata";
    video.onloadedmetadata = () => finish(isFinite(video.duration) ? video.duration : null);
    video.onerror = () => finish(null);
    setTimeout(() => finish(null), 2000);
    video.src = url;
  });
}
```

`ChatContent.tsx`:
1. Import `useSendVideoMessageMutation, useGetVideoMessageConfigQuery,` from chatSlice, and `import { checkVideo, limitsFromConfig, readVideoDuration } from "./lib/videoLimits";`
2. Below `const [sendMediaMessage] = useSendMediaMessageMutation();`:
```tsx
  const [sendVideoMessage] = useSendVideoMessageMutation();
  const { data: videoConfig } = useGetVideoMessageConfigQuery(undefined);
```
3. At the top of `handleSendMedia`, after `if (!mediaPreview || isSending) return;`, add the video branch:
```tsx
    if (mediaPreview.type === "video") {
      const preview = mediaPreview;
      const caption = newMessage.trim();
      const limits = limitsFromConfig(videoConfig);
      const duration = await readVideoDuration(preview.file);
      const verdict = checkVideo(preview.file, limits, duration);
      if (verdict !== "ok") {
        notify.error(
          verdict === "tooBig"
            ? t("chatPage.video.tooBig", { mb: Math.round(limits.maxSize / (1024 * 1024)) }) ||
                `This video is too large. The limit is ${Math.round(limits.maxSize / (1024 * 1024))} MB.`
            : verdict === "tooLong"
            ? t("chatPage.video.tooLong", { minutes: Math.round(limits.maxDuration / 60) }) ||
                `This video is too long. The limit is ${Math.round(limits.maxDuration / 60)} minutes.`
            : t("chatPage.video.badType") || "This video format can't be sent. Try an MP4."
        );
        handleCancelMedia();
        return;
      }

      setIsSending(true);
      isAtBottomRef.current = true;
      const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
      setMessages((prev) => [
        ...prev,
        {
          _id: tempId,
          message: "",
          sender: { _id: userId, name: currentUserName || "" },
          receiver: selectedUser,
          messageType: "media",
          media: { url: preview.url, type: "video" },
          createdAt: new Date().toISOString(),
          isOptimistic: true,
          status: "sending",
        },
      ]);
      setNewMessage("");
      try {
        const formData = new FormData();
        formData.append("video", preview.file);
        formData.append("receiver", selectedUser);
        const result: any = await sendVideoMessage(formData).unwrap();
        finalizeOptimistic(tempId, result.data || result);
        // /messages/video has no caption field; the caption follows as text.
        if (caption) {
          setIsSending(false);
          await sendInlineMessage(caption, "text");
        }
      } catch (err) {
        markOptimisticError(tempId);
        reportSendError(err);
      } finally {
        setIsSending(false);
        handleCancelMedia();
      }
      return;
    }
```
   (`sendInlineMessage` with `"text"` goes over the socket when connected and sends no `messageType`, see `sendInlineOverSocket`; over REST `type:"text"`.) `sendInlineMessage`'s guard `if (isSending) return;` reads state from this render — call `setIsSending(false)` before it as above, and if that guard still blocks in practice, pass the caption through `sendInlineOverSocket`/`sendInlineMessageViaRest` directly with a fresh optimistic bubble.

`eng.json`, in `chatPage`:
```json
    "video": {
      "tooBig": "This video is too large. The limit is {{mb}} MB.",
      "tooLong": "This video is too long. The limit is {{minutes}} minutes.",
      "badType": "This video format can't be sent. Try an MP4."
    },
```

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false videoLimits chatActionsEndpoints ChatContent
```

- [ ] **Step 5: Commit** (tick `P3-CHAT-8`)

```bash
git add src/store/slices/chatSlice.ts src/store/slices/chatActionsEndpoints.test.ts \
  src/components/chat/lib/videoLimits.ts src/components/chat/lib/videoLimits.test.ts \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx src/components/chat/ChatContent.pagination.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): send videos through the video pipeline

Web videos were uploaded as a generic attachment: no thumbnail, no
duration, no duration cap, and the whole file buffered in memory by the
image compressor. They now go to POST /messages/video (field `video`),
like the app's, after a client check against /messages/video-config
(type, size, and duration when the browser can read it). A caption
follows as its own text message, since the video route has none.

Still open (Phase 3 chat): P3-CHAT-9..20 and the chat i18n pass.
EOF
```

---

### Task P3-CHAT-9: Voice recorder picks a type the browser supports (AAC first), names the file to match, and sends a waveform (chat#13)

**Files:**
- Create: `src/utils/recorderMime.ts` (shared with the MOMENTS unit — exact name and signature below)
- Create: `src/utils/audioWaveform.ts`
- Modify: `src/components/chat/ChatContent.tsx` — `startRecording` (`:1430-1470`), `sendVoiceRecording` (`:1496-1554`), a ref for the chosen type
- Modify: `src/utils/locales/eng.json` (`chatPage.voice.*`)
- Test: `src/utils/recorderMime.test.ts`, `src/utils/audioWaveform.test.ts` (new); `ChatContent.test.tsx` (one case)

**Interfaces:**
- Consumes: `POST /api/v1/messages/voice` multipart `voice` (file), `receiver`, `duration`, `waveform` (JSON string of 0–1 numbers; `be/controllers/advancedMessages.js:828-905`, model `Message.media.waveform` min 0 max 1). The upload whitelist accepts `audio/mp4`, `audio/webm`, `audio/ogg` (`be/middleware/uploadToSpaces.js:66-81`) — matched on the base type, so the Blob is typed without `;codecs=`. After backend Phase 1 item 5, anything outside the AAC/MP3 pass-through list (i.e. WebM/Ogg from Chrome/Firefox) is transcoded to AAC `.m4a`; `audio/mp4` from Safari/new Chrome passes through untouched.
- Produces: `pickRecorderMime(): { mimeType: string | undefined; ext: string }` and `extForMime(mime: string): string`, `baseMime(mime: string): string` from `src/utils/recorderMime.ts` (the MOMENTS unit's `VoiceNoteRecorder` imports these); `computeWaveform(blob: Blob, bars?: number): Promise<number[] | null>` from `src/utils/audioWaveform.ts`.

- [ ] **Step 1: Write the failing tests**

Create `src/utils/recorderMime.test.ts`:

```ts
import { pickRecorderMime, extForMime, baseMime } from "./recorderMime";

const originalMR = (window as any).MediaRecorder;
afterEach(() => {
  (window as any).MediaRecorder = originalMR;
});

function withSupported(types: string[] | "throws") {
  (window as any).MediaRecorder = {
    isTypeSupported: (type: string) => {
      if (types === "throws") throw new Error("nope");
      return types.indexOf(type) > -1;
    },
  };
}

it("prefers AAC in MP4 (plays in the iOS app without conversion)", () => {
  withSupported(["audio/mp4", "audio/webm;codecs=opus"]);
  expect(pickRecorderMime()).toEqual({ mimeType: "audio/mp4", ext: "m4a" });
});

it("falls back to Opus in WebM on Chrome/Firefox", () => {
  withSupported(["audio/webm;codecs=opus", "audio/webm"]);
  expect(pickRecorderMime()).toEqual({ mimeType: "audio/webm;codecs=opus", ext: "webm" });
});

it("then plain WebM, then Ogg", () => {
  withSupported(["audio/webm"]);
  expect(pickRecorderMime()).toEqual({ mimeType: "audio/webm", ext: "webm" });
  withSupported(["audio/ogg;codecs=opus"]);
  expect(pickRecorderMime()).toEqual({ mimeType: "audio/ogg;codecs=opus", ext: "ogg" });
});

it("lets the browser choose when it supports none of them, or cannot say", () => {
  withSupported([]);
  expect(pickRecorderMime()).toEqual({ mimeType: undefined, ext: "webm" });
  withSupported("throws");
  expect(pickRecorderMime()).toEqual({ mimeType: undefined, ext: "webm" });
  (window as any).MediaRecorder = undefined;
  expect(pickRecorderMime()).toEqual({ mimeType: undefined, ext: "webm" });
});

it("maps a recorder's actual type to a file extension", () => {
  expect(extForMime("audio/mp4")).toBe("m4a");
  expect(extForMime("audio/mp4;codecs=mp4a.40.2")).toBe("m4a");
  expect(extForMime("audio/aac")).toBe("aac");
  expect(extForMime("audio/ogg;codecs=opus")).toBe("ogg");
  expect(extForMime("audio/mpeg")).toBe("mp3");
  expect(extForMime("audio/webm;codecs=opus")).toBe("webm");
  expect(extForMime("")).toBe("webm");
});

it("strips codec parameters for the upload's Content-Type", () => {
  expect(baseMime("audio/webm;codecs=opus")).toBe("audio/webm");
  expect(baseMime("")).toBe("audio/webm");
});
```

Create `src/utils/audioWaveform.test.ts`:

```ts
import { computeWaveform } from "./audioWaveform";

const originalAC = (window as any).AudioContext;
afterEach(() => {
  (window as any).AudioContext = originalAC;
});

it("returns null when the browser has no AudioContext", async () => {
  (window as any).AudioContext = undefined;
  (window as any).webkitAudioContext = undefined;
  await expect(computeWaveform(new Blob(["x"]), 10)).resolves.toBe(null);
});

it("turns samples into `bars` peaks between 0 and 1", async () => {
  const samples = new Float32Array(1000);
  for (let i = 0; i < 1000; i += 1) samples[i] = i < 500 ? 0.1 : -0.8;
  (window as any).AudioContext = function () {
    return {
      decodeAudioData: (_buf: ArrayBuffer) => Promise.resolve({ getChannelData: () => samples }),
      close: () => Promise.resolve(),
    };
  };
  const blob: any = { arrayBuffer: () => Promise.resolve(new ArrayBuffer(8)) };
  const bars = await computeWaveform(blob, 10);
  expect(bars).toHaveLength(10);
  bars!.forEach((v) => {
    expect(v).toBeGreaterThanOrEqual(0);
    expect(v).toBeLessThanOrEqual(1);
  });
  expect(bars![0]).toBeLessThan(bars![9]);
  expect(bars![9]).toBe(1);
});

it("returns null when decoding fails (never blocks the send)", async () => {
  (window as any).AudioContext = function () {
    return { decodeAudioData: () => Promise.reject(new Error("bad")), close: () => Promise.resolve() };
  };
  const blob: any = { arrayBuffer: () => Promise.resolve(new ArrayBuffer(8)) };
  await expect(computeWaveform(blob, 10)).resolves.toBe(null);
});
```

`ChatContent.test.tsx`:
- add `const mockSendVoice = jest.fn();`; factory: `useSendVoiceMessageMutation: () => [mockSendVoice, { isLoading: false }],`; `beforeEach`: `mockSendVoice.mockReturnValue({ unwrap: () => Promise.resolve({ data: { _id: "m-voice", messageType: "voice", sender: { _id: "me" }, media: { type: "voice", url: "v.m4a" } } }) });`
- append:
```tsx
// --- Voice notes ----------------------------------------------------------------

it("records AAC where the browser can, and uploads it as .m4a with a matching type", async () => {
  const stream = { getTracks: () => [{ stop: jest.fn() }] };
  (navigator as any).mediaDevices = { getUserMedia: jest.fn(() => Promise.resolve(stream)) };
  const created: any[] = [];
  const FakeRecorder: any = function (this: any, _s: any, opts: any) {
    created.push(opts);
    this.mimeType = (opts && opts.mimeType) || "audio/webm";
    this.state = "inactive";
    this.start = () => {
      this.state = "recording";
      this.ondataavailable({ data: new Blob(["abc"], { type: this.mimeType }) });
    };
    this.stop = () => {
      this.state = "inactive";
    };
  };
  FakeRecorder.isTypeSupported = (type: string) => type === "audio/mp4";
  (window as any).MediaRecorder = FakeRecorder;
  mockUseSocket.mockReturnValue(offlineSocket());
  renderChat("/chat/u2");

  fireEvent.click(screen.getByLabelText("Voice message"));
  await waitFor(() => expect(created).toHaveLength(1));
  expect(created[0]).toEqual({ mimeType: "audio/mp4" });

  fireEvent.click(document.querySelector(".recording-send-btn") as HTMLElement);
  await waitFor(() => expect(mockSendVoice).toHaveBeenCalledTimes(1));
  const form: FormData = mockSendVoice.mock.calls[0][0];
  const file = form.get("voice") as File;
  expect(file.name).toMatch(/\.m4a$/);
  expect(file.type).toBe("audio/mp4");
});
```
(The send button is only rendered once chunks exist; if `.recording-send-btn` is disabled for a 0-second recording, advance with `jest.advanceTimersByTime(1000)` under fake timers.)

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false recorderMime audioWaveform ChatContent.test
```
Expected: FAIL — modules missing; ChatContent constructs the recorder with `audio/webm` and names the file `.webm`.

- [ ] **Step 3: Implement**

Create `src/utils/recorderMime.ts`:

```ts
/**
 * Which audio type to ask MediaRecorder for.
 *
 * AAC in MP4 first: it is what the app records and what iOS (AVPlayer, via
 * just_audio) plays; Safari and recent Chrome can make it. Then Opus in
 * WebM/Ogg for Chrome/Firefox -- backend Phase 1 transcodes those to AAC.
 * Never a type the browser refuses: `new MediaRecorder(s, {mimeType})` with an
 * unsupported type THROWS (Safari < 18.4 with audio/webm), which is how web
 * recording broke there. With nothing supported, let the browser choose and
 * read `recorder.mimeType` afterwards (`extForMime`).
 */
export interface RecorderMime {
  mimeType: string | undefined;
  ext: string;
}

const CANDIDATES: RecorderMime[] = [
  { mimeType: "audio/mp4", ext: "m4a" },
  { mimeType: "audio/webm;codecs=opus", ext: "webm" },
  { mimeType: "audio/webm", ext: "webm" },
  { mimeType: "audio/ogg;codecs=opus", ext: "ogg" },
];

export function pickRecorderMime(): RecorderMime {
  const MR: any = typeof window !== "undefined" ? (window as any).MediaRecorder : undefined;
  if (!MR || typeof MR.isTypeSupported !== "function") return { mimeType: undefined, ext: "webm" };
  for (let i = 0; i < CANDIDATES.length; i += 1) {
    try {
      if (MR.isTypeSupported(CANDIDATES[i].mimeType)) return { ...CANDIDATES[i] };
    } catch (err) {
      return { mimeType: undefined, ext: "webm" };
    }
  }
  return { mimeType: undefined, ext: "webm" };
}

/** The type without codec parameters -- what the upload whitelist matches on. */
export function baseMime(mime: string): string {
  const base = (mime || "").split(";")[0].trim();
  return base || "audio/webm";
}

export function extForMime(mime: string): string {
  const base = baseMime(mime);
  if (base === "audio/mp4" || base === "audio/x-m4a" || base === "audio/m4a") return "m4a";
  if (base === "audio/aac" || base === "audio/x-aac") return "aac";
  if (base === "audio/ogg") return "ogg";
  if (base === "audio/mpeg" || base === "audio/mp3") return "mp3";
  return "webm";
}
```

Create `src/utils/audioWaveform.ts`:

```ts
/**
 * Peak amplitudes (0..1) for a recorded clip, the shape the app draws its
 * voice bars from (Message.media.waveform). Best effort: any failure -- no
 * AudioContext, a codec the browser can record but not decode -- returns null
 * and the note is sent without one (the app then draws default bars).
 */
export async function computeWaveform(blob: Blob, bars: number = 30): Promise<number[] | null> {
  const AC: any =
    typeof window !== "undefined"
      ? (window as any).AudioContext || (window as any).webkitAudioContext
      : undefined;
  if (!AC || !blob || typeof (blob as any).arrayBuffer !== "function") return null;
  let ctx: any = null;
  try {
    ctx = new AC();
    const buffer = await (blob as any).arrayBuffer();
    const audio = await ctx.decodeAudioData(buffer);
    const data: Float32Array = audio.getChannelData(0);
    if (!data || data.length === 0) return null;
    const step = Math.max(1, Math.floor(data.length / bars));
    const peaks: number[] = [];
    for (let i = 0; i < bars; i += 1) {
      let peak = 0;
      const end = Math.min(data.length, (i + 1) * step);
      for (let j = i * step; j < end; j += 1) {
        const v = Math.abs(data[j]);
        if (v > peak) peak = v;
      }
      peaks.push(peak);
    }
    const max = Math.max.apply(null, peaks) || 1;
    return peaks.map((p) => Math.round((p / max) * 100) / 100);
  } catch (err) {
    return null;
  } finally {
    if (ctx && typeof ctx.close === "function") ctx.close().catch(() => undefined);
  }
}
```

`ChatContent.tsx`:
1. Imports: `import { pickRecorderMime, extForMime, baseMime } from "../../utils/recorderMime";` and `import { computeWaveform } from "../../utils/audioWaveform";`
2. Next to `audioChunksRef`: `const recorderMimeRef = useRef<string>("");`
3. In `startRecording` replace
```tsx
      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: MediaRecorder.isTypeSupported("audio/webm;codecs=opus")
          ? "audio/webm;codecs=opus"
          : "audio/webm",
      });
```
with
```tsx
      const choice = pickRecorderMime();
      let mediaRecorder: MediaRecorder;
      try {
        mediaRecorder = choice.mimeType
          ? new MediaRecorder(stream, { mimeType: choice.mimeType })
          : new MediaRecorder(stream);
      } catch (err) {
        // A browser that said yes and then refused: let it pick.
        mediaRecorder = new MediaRecorder(stream);
      }
      recorderMimeRef.current = mediaRecorder.mimeType || choice.mimeType || "";
```
   and in its `catch (err)` (`console.error("Failed to start recording:", err);`) add:
```tsx
      notify.error(
        t("chatPage.voice.unavailable") ||
          "Voice recording isn't available. Check the microphone permission for this site."
      );
```
4. In `sendVoiceRecording` replace
```tsx
    const audioBlob = new Blob(audioChunksRef.current, { type: "audio/webm" });
```
with
```tsx
    const recordedType = baseMime(recorderMimeRef.current);
    const audioBlob = new Blob(audioChunksRef.current, { type: recordedType });
```
   and replace
```tsx
      formData.append("voice", audioBlob, `voice-${Date.now()}.webm`);
      formData.append("receiver", selectedUser);
      formData.append("duration", duration.toString());
```
with
```tsx
      formData.append("voice", audioBlob, `voice-${Date.now()}.${extForMime(recordedType)}`);
      formData.append("receiver", selectedUser);
      formData.append("duration", duration.toString());
      const waveform = await computeWaveform(audioBlob, 30);
      if (waveform && waveform.length) formData.append("waveform", JSON.stringify(waveform));
```

`eng.json`, in `chatPage`:
```json
    "voice": {
      "unavailable": "Voice recording isn't available. Check the microphone permission for this site."
    },
```

- [ ] **Step 4: Run → PASS**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false recorderMime audioWaveform ChatContent
```

- [ ] **Step 5: Commit** (tick `P3-CHAT-9`)

```bash
git add src/utils/recorderMime.ts src/utils/recorderMime.test.ts src/utils/audioWaveform.ts src/utils/audioWaveform.test.ts \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): voice notes record AAC where possible and never break on Safari

The recorder always asked for audio/webm, which Safari before 18.4
refuses by throwing, so recording was impossible there; and WebM does
not play in the iOS app. It now asks for AAC in MP4 first, then Opus in
WebM/Ogg, never a type the browser refuses, and names the upload after
what was actually recorded (.m4a/.webm/.ogg, codec params stripped).
WebM/Ogg are converted to AAC by the backend (Phase 1 item 5). A
waveform is computed and sent so the app draws real bars. The helper
lives in src/utils/recorderMime.ts for the moments recorder too.

Still open (Phase 3 chat): P3-CHAT-10..20 and the chat i18n pass;
device QA: a web voice note plays in the iOS app (QA sheet, Web area).
EOF
```

---

#### Keys added by P3-CHAT-1..9

All under `chatPage` in `src/utils/locales/eng.json` (English below; the coordinator's i18n task fills the other 17 locales):

| Key | English |
|---|---|
| `chatPage.editDialog.title` | Edit message |
| `chatPage.editDialog.label` | Message |
| `chatPage.editDialog.save` | Save |
| `chatPage.editDialog.cancel` | Cancel |
| `chatPage.editDialog.tooLate` | You can only edit a message within 15 minutes of sending it. |
| `chatPage.editDialog.failed` | Couldn't edit the message. Try again. |
| `chatPage.deleteMessage.title` | Delete message? |
| `chatPage.deleteMessage.forEveryone` | Delete for everyone |
| `chatPage.deleteMessage.forMe` | Delete for me |
| `chatPage.deleteMessage.cancel` | Cancel |
| `chatPage.deleteMessage.placeholder` | This message was deleted |
| `chatPage.deleteMessage.tooLate` | You can only delete a message for everyone within 1 hour of sending it. |
| `chatPage.deleteMessage.failed` | Couldn't delete the message. Try again. |
| `chatPage.sendErrors.firstChatTitle` | Wait for a reply |
| `chatPage.sendErrors.firstChatBody` | You can send 5 messages until they reply. You can write again once they answer. |
| `chatPage.sendErrors.dailyTitle` | Daily message limit reached |
| `chatPage.sendErrors.dailyBody` | You've sent all your messages for today. Go VIP for unlimited messages, or come back tomorrow. |
| `chatPage.sendErrors.capTitle` | New conversation limit reached |
| `chatPage.sendErrors.capBody` | You've started as many new conversations as you can today. Go VIP to start as many as you want. |
| `chatPage.sendErrors.blockedTitle` | Message not sent |
| `chatPage.sendErrors.blockedBody` | You can't send messages to this person. |
| `chatPage.sendErrors.tooFast` | You're sending messages too fast. Wait a moment. |
| `chatPage.sendErrors.generic` | Message not sent. Tap Retry to try again. |
| `chatPage.sendErrors.goVip` | Go VIP |
| `chatPage.sendErrors.ok` | OK |
| `chatPage.sendErrors.reattach` | Attach the file again to send it. |
| `chatPage.preview.call` | 📞 Call |
| `chatPage.preview.location` | 📍 Location |
| `chatPage.preview.voice` | 🎤 Voice message |
| `chatPage.preview.gif` | GIF |
| `chatPage.preview.story` | 📖 Story |
| `chatPage.preview.poll` | 📊 Poll |
| `chatPage.preview.photo` | 🖼️ Photo |
| `chatPage.preview.video` | 🎥 Video |
| `chatPage.preview.file` | 📎 File |
| `chatPage.preview.attachment` | 📎 Attachment |
| `chatPage.list.loading` | Loading chats... |
| `chatPage.list.loadError` | Couldn't load your conversations |
| `chatPage.list.tryAgain` | Try again |
| `chatPage.connection.kicked` | Chat is open somewhere else, so this tab stopped receiving messages. |
| `chatPage.connection.reconnect` | Use here |
| `chatPage.video.tooBig` | This video is too large. The limit is {{mb}} MB. |
| `chatPage.video.tooLong` | This video is too long. The limit is {{minutes}} minutes. |
| `chatPage.video.badType` | This video format can't be sent. Try an MP4. |
| `chatPage.voice.unavailable` | Voice recording isn't available. Check the microphone permission for this site. |

Not keys but noted for the i18n pass: `MessageActionMenu.tsx` item labels ("Reply", "Edit", "Delete", "Listen" …) are hard-coded English today (pre-existing; not changed by these tasks).


### Conventions for P3-CHAT-10 … P3-CHAT-20 (read once)

- Worktree `/Users/davis/Desktop/Personal/wt-web-p3-chat`, branch `web/p3-chat`. These tasks run **after** P3-CHAT-1…9 in
  the same branch. Line numbers are from origin/main **fba6208**; tasks 1–9 move them. Anchor every edit on the quoted
  code, not the number.
- `src/components/chat/chatStyling.test.ts` holds `STRICT_FILES` to: no `style={{`, no hex colour, no
  react-bootstrap, **no emoji character in the source** (`MessageBubble.tsx`, `ChatContent.tsx`, `ChatInfoPanel.tsx` are
  on it). So emoji tests live in `lib/*.ts` (written with `\u{…}` escapes), and a wave card renders the emoji it got
  from the message text, never a literal. Every new `.tsx` under `src/components/chat` is added to `STRICT_FILES`.
- `src/components/chat/chatTokens.test.ts` holds `ChatContent.css` / `MainChat.css` / `UsersList.css` to **no hex
  colour** and only `var(--chat-*)` tokens that exist in `src/index.css`. All new CSS below uses existing tokens:
  `--chat-card-in`, `--chat-card-out`, `--chat-line`, `--chat-muted`, `--chat-text`, `--chat-accent`,
  `--chat-danger`, `--chat-danger-soft`, `--chat-danger-line`, `--chat-surface`, `--chat-bubble-out-text`.
  New layout uses logical properties (`margin-inline-start`, `padding-inline`, `inset-inline-end`) so `ar` (RTL) mirrors.
- Tests that mount `ChatContent` (`ChatContent.test.tsx`, `ChatContent.pagination.test.tsx`) mock
  `../../store/slices/chatSlice` module-wide. A new child component that owns its own store hooks is therefore
  **stubbed** in both files with `jest.mock("./components/<Name>", …)`, exactly as `./ChatInfoPanel` already is.
  Component suites mock `react-i18next` with `t: () => ""`, so assertions read the English fallbacks.
- Strings: `t("chatPage.<area>.<key>") || "English"`; the English goes into `src/utils/locales/eng.json` in the same
  commit (under the existing `"chatPage"` object). The 17 other locales come from the coordinator's i18n task; the
  full key list is at the end of this section.
- Commits: no `Co-Authored-By`, no AI attribution. Each commit ticks its own `- [ ] P3-CHAT-N` line in
  `docs/REMAINING_WORK.md` (`- [x]`) and names what is still open.

---

### Task P3-CHAT-10: App call-history messages render as a call card, not "File" (chat#6)

**Files:**
- Create: `src/components/chat/lib/callLabel.ts`, `src/components/chat/components/CallMessageCard.tsx`
- Modify: `src/components/chat/MessageBubble.tsx` (`MessageMedia` :45-55, flags :205-213, bubble class :386, branch :388, chips :481)
- Modify: `src/components/chat/ChatContent.css` (append), `src/components/chat/chatStyling.test.ts` (`STRICT_FILES`)
- Test: `src/components/chat/lib/callLabel.test.ts` (new), `src/components/chat/MessageBubble.test.tsx` (append)

**Interfaces:**
- Consumes: backend `services/callMessageService.js:88-95` writes `messageType:'call'`,
  `media:{type:'call', callData:{_id, callId, callUuid, initiator:<id string>, participants:[], type:'audio'|'video',
  startTime, duration:<int s>, status:<legacy>, outcome:'completed'|'no_answer'|'cancelled'|'declined'|'busy'}}` and an
  English fallback `message` ("📞 Missed voice call"). Rows written before `outcome` existed carry only `status`
  (`ended|answered|missed|rejected|busy`) — mapped exactly like app `lib/models/call_outcome.dart` `legacyCallOutcome`.
  The `sender` of a call message is always the caller, so when `callData.initiator` is missing the bubble's `isSent` is
  the fallback.
- Produces: `callLabel(data, viewerId, isSentFallback, otherName)` and `callPreviewText(t, data, viewerId, isSent, otherName)`
  — P3-CHAT-6's conversation-list preview for `call` uses `callPreviewText` (Step 3d).

- [ ] **Step 1: Write the failing tests**

`src/components/chat/lib/callLabel.test.ts`:

```ts
import { callLabel, callPreviewText, formatCallDuration, outcomeOf } from "./callLabel";

/**
 * One call message is shared by both people; each side words it from
 * media.callData.outcome and whether the viewer placed the call — the app's
 * CallLabels (lib/models/call_outcome.dart), case for case.
 */
const ME = "me";
const THEM = "u2";

describe("outcomeOf", () => {
  it("reads outcome when the server wrote one", () => {
    expect(outcomeOf({ outcome: "busy" })).toBe("busy");
  });
  it("maps the legacy status of rows written before outcome existed", () => {
    expect(outcomeOf({ status: "ended" })).toBe("completed");
    expect(outcomeOf({ status: "answered" })).toBe("completed");
    expect(outcomeOf({ status: "missed" })).toBe("no_answer");
    expect(outcomeOf({ status: "rejected" })).toBe("declined");
    expect(outcomeOf({ status: "busy" })).toBe("busy");
  });
  it("treats an unknown or empty record as a completed call, like the app", () => {
    expect(outcomeOf({ outcome: "exploded" })).toBe("completed");
    expect(outcomeOf(undefined)).toBe("completed");
  });
});

describe("formatCallDuration", () => {
  it("is m:ss under an hour and h:mm:ss above", () => {
    expect(formatCallDuration(0)).toBe("0:00");
    expect(formatCallDuration(75)).toBe("1:15");
    expect(formatCallDuration(3725)).toBe("1:02:05");
  });
  it("never shows a negative or fractional duration", () => {
    expect(formatCallDuration(-5)).toBe("0:00");
    expect(formatCallDuration(61.9)).toBe("1:01");
    expect(formatCallDuration(NaN)).toBe("0:00");
  });
});

describe("callLabel, from each side", () => {
  const cases: Array<[string, any, string, string, boolean]> = [
    // [name, callData, viewer, expected fallback, negative]
    ["caller, completed voice", { outcome: "completed", type: "audio", initiator: ME, duration: 75 }, ME, "Outgoing voice call", false],
    ["callee, completed video", { outcome: "completed", type: "video", initiator: THEM }, ME, "Incoming video call", false],
    ["caller, no answer", { outcome: "no_answer", type: "audio", initiator: ME }, ME, "Voice call · No answer", false],
    ["callee, no answer = missed", { outcome: "no_answer", type: "audio", initiator: THEM }, ME, "Missed voice call", true],
    ["caller, cancelled", { outcome: "cancelled", type: "video", initiator: ME }, ME, "Cancelled video call", false],
    ["callee, cancelled = missed", { outcome: "cancelled", type: "video", initiator: THEM }, ME, "Missed video call", true],
    ["caller, declined", { outcome: "declined", type: "audio", initiator: ME }, ME, "Voice call declined", true],
    ["callee, declined", { outcome: "declined", type: "audio", initiator: THEM }, ME, "Declined voice call", true],
    ["caller, busy", { outcome: "busy", type: "audio", initiator: ME }, ME, "Ada was on another call", false],
    ["callee, busy = missed", { outcome: "busy", type: "audio", initiator: THEM }, ME, "Missed voice call", true],
  ];
  cases.forEach(([name, data, viewer, fallback, negative]) => {
    it(name, () => {
      const label = callLabel(data, viewer, false, "Ada");
      expect(label.fallback).toBe(fallback);
      expect(label.negative).toBe(negative);
    });
  });

  it("only a completed call carries a duration", () => {
    expect(callLabel({ outcome: "completed", initiator: ME, duration: 75 }, ME, false, "Ada").duration).toBe("1:15");
    expect(callLabel({ outcome: "no_answer", initiator: ME, duration: 75 }, ME, false, "Ada").duration).toBeNull();
  });

  it("reads a populated initiator as well as a bare id", () => {
    expect(callLabel({ outcome: "completed", initiator: { _id: ME } }, ME, false, "Ada").direction).toBe("outgoing");
  });

  it("falls back to the bubble's side when the record names no initiator", () => {
    expect(callLabel({ outcome: "completed" }, ME, true, "Ada").direction).toBe("outgoing");
    expect(callLabel({ outcome: "completed" }, ME, false, "Ada").direction).toBe("incoming");
  });
});

describe("callPreviewText", () => {
  it("adds the duration to a completed call, the way the app's list does", () => {
    const t = () => "";
    expect(
      callPreviewText(t, { outcome: "completed", type: "audio", initiator: ME, duration: 75 }, ME, true, "Ada")
    ).toBe("Outgoing voice call · 1:15");
    expect(callPreviewText(t, { outcome: "no_answer", initiator: THEM }, ME, false, "Ada")).toBe("Missed voice call");
  });
});
```

Append to `src/components/chat/MessageBubble.test.tsx`:

```tsx
describe("call history messages (chat#6)", () => {
  const callMessage = (callData: any, extra: Partial<Message> = {}): Message =>
    message({
      messageType: "call",
      message: "📞 Missed voice call",
      media: { type: "call", url: "", callData } as any,
      ...extra,
    });

  it("draws a call card, not a File attachment", () => {
    renderBubble({
      message: callMessage({ type: "audio", outcome: "completed", duration: 75, initiator: "me" }),
    });

    expect(screen.getByTestId("call-card")).toBeInTheDocument();
    expect(screen.queryByText("File")).toBeNull();
    expect(screen.getByText("Outgoing voice call")).toBeInTheDocument();
    expect(screen.getByText("1:15")).toBeInTheDocument();
  });

  it("words a missed call from the side of the person who missed it", () => {
    renderBubble({
      message: callMessage(
        { type: "audio", outcome: "no_answer", initiator: "u2" },
        { sender: { _id: "u2", name: "Ada" } }
      ),
      isSent: false,
    });

    expect(screen.getByText("Missed voice call")).toBeInTheDocument();
    expect(screen.getByTestId("call-card")).toHaveClass("call-card--negative");
  });

  it("reads the legacy status of rows written before outcome existed", () => {
    renderBubble({ message: callMessage({ type: "audio", status: "rejected", initiator: "me" }) });
    expect(screen.getByText("Voice call declined")).toBeInTheDocument();
  });

  it("does not print the server's fallback text under the card", () => {
    renderBubble({ message: callMessage({ type: "audio", outcome: "no_answer", initiator: "me" }) });
    expect(screen.queryByText("📞 Missed voice call")).toBeNull();
  });

  it("offers no Correct or Translate chip on a call", () => {
    renderBubble({
      message: callMessage(
        { type: "video", outcome: "completed", initiator: "u2", duration: 5 },
        { sender: { _id: "u2", name: "Ada" } }
      ),
      isSent: false,
    });
    expect(screen.queryByText("Correct")).toBeNull();
    expect(screen.queryByText("Translate")).toBeNull();
  });

  it("survives a call message whose callData is missing", () => {
    renderBubble({ message: callMessage(undefined) });
    expect(screen.getByTestId("call-card")).toBeInTheDocument();
    expect(screen.queryByText("File")).toBeNull();
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false callLabel MessageBubble
```
Expected: `callLabel.test.ts` fails to compile ("Cannot find module './callLabel'"); the new `MessageBubble` cases fail
(`Unable to find an element by: [data-testid="call-card"]`, and "File" is found). Existing cases pass.

- [ ] **Step 3: Implement**

3a. Create `src/components/chat/lib/callLabel.ts`:

```ts
/**
 * The words a call-history message shows, from the viewer's side.
 *
 * One message is shared by both people (backend services/callMessageService.js);
 * each side words it from `media.callData.outcome` and whether the viewer
 * placed the call. Case for case the app's CallLabels
 * (lib/models/call_outcome.dart), so a call reads the same on web and phone.
 */
export type CallOutcome = "completed" | "no_answer" | "cancelled" | "declined" | "busy";

export interface CallData {
  callId?: string;
  /** A bare id string as written today; tolerated populated. */
  initiator?: string | { _id?: string } | null;
  /** "audio" | "video" */
  type?: string;
  /** Whole seconds. */
  duration?: number;
  /** Legacy (pre-outcome) status: ended | answered | missed | rejected | busy. */
  status?: string;
  outcome?: string;
  startTime?: string;
}

export interface CallLabel {
  outcome: CallOutcome;
  key: string;
  fallback: string;
  params: { [key: string]: any };
  isVideo: boolean;
  direction: "outgoing" | "incoming";
  /** Missed in the app's sense: the viewer was called and did not pick up. */
  missed: boolean;
  /** Drawn red: missed, or declined by either side. */
  negative: boolean;
  /** "m:ss" for a completed call, otherwise null. */
  duration: string | null;
}

const KNOWN: CallOutcome[] = ["completed", "no_answer", "cancelled", "declined", "busy"];

const LEGACY: { [status: string]: CallOutcome } = {
  ended: "completed",
  answered: "completed",
  missed: "no_answer",
  rejected: "declined",
  busy: "busy",
};

export function outcomeOf(data: CallData | null | undefined): CallOutcome {
  if (data && data.outcome && KNOWN.indexOf(data.outcome as CallOutcome) !== -1) {
    return data.outcome as CallOutcome;
  }
  if (data && data.status && LEGACY[data.status]) return LEGACY[data.status];
  return "completed";
}

export function formatCallDuration(seconds: number): string {
  const whole = typeof seconds === "number" && isFinite(seconds) && seconds > 0 ? Math.floor(seconds) : 0;
  const h = Math.floor(whole / 3600);
  const m = Math.floor((whole % 3600) / 60);
  const s = whole % 60;
  const pad = (n: number): string => (n < 10 ? `0${n}` : String(n));
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
}

function initiatorId(data: CallData): string {
  const initiator = data.initiator;
  if (!initiator) return "";
  if (typeof initiator === "string") return initiator;
  return initiator._id ? String(initiator._id) : "";
}

export function callLabel(
  data: CallData | null | undefined,
  viewerId: string,
  isSentFallback: boolean,
  otherName: string
): CallLabel {
  const record: CallData = data || {};
  const outcome = outcomeOf(record);
  const isVideo = record.type === "video";
  const kind = isVideo ? "Video" : "Voice";
  const lower = isVideo ? "video" : "voice";
  const initiator = initiatorId(record);
  const viewerIsCaller = initiator ? initiator === viewerId : isSentFallback;

  let key: string;
  let fallback: string;
  const params: { [key: string]: any } = {};
  switch (outcome) {
    case "no_answer":
      key = viewerIsCaller ? `chatPage.call.noAnswer${kind}` : `chatPage.call.missed${kind}`;
      fallback = viewerIsCaller ? `${kind} call · No answer` : `Missed ${lower} call`;
      break;
    case "cancelled":
      key = viewerIsCaller ? `chatPage.call.cancelled${kind}` : `chatPage.call.missed${kind}`;
      fallback = viewerIsCaller ? `Cancelled ${lower} call` : `Missed ${lower} call`;
      break;
    case "declined":
      key = viewerIsCaller ? `chatPage.call.declinedOutgoing${kind}` : `chatPage.call.declinedIncoming${kind}`;
      fallback = viewerIsCaller ? `${kind} call declined` : `Declined ${lower} call`;
      break;
    case "busy":
      if (viewerIsCaller) {
        key = "chatPage.call.busy";
        params.name = otherName;
        fallback = `${otherName} was on another call`;
      } else {
        key = `chatPage.call.missed${kind}`;
        fallback = `Missed ${lower} call`;
      }
      break;
    default:
      key = viewerIsCaller ? `chatPage.call.outgoing${kind}` : `chatPage.call.incoming${kind}`;
      fallback = `${viewerIsCaller ? "Outgoing" : "Incoming"} ${lower} call`;
  }

  const missed =
    !viewerIsCaller && (outcome === "no_answer" || outcome === "cancelled" || outcome === "busy");

  return {
    outcome: outcome,
    key: key,
    fallback: fallback,
    params: params,
    isVideo: isVideo,
    direction: viewerIsCaller ? "outgoing" : "incoming",
    missed: missed,
    negative: missed || outcome === "declined",
    duration: outcome === "completed" ? formatCallDuration(Number(record.duration) || 0) : null,
  };
}

/** The conversation-list line for a call, as the app's callPreviewText words it (minus the icon). */
export function callPreviewText(
  t: (key: string, options?: any) => string,
  data: CallData | null | undefined,
  viewerId: string,
  isSent: boolean,
  otherName: string
): string {
  const label = callLabel(data, viewerId, isSent, otherName);
  const text = t(label.key, label.params) || label.fallback;
  return label.duration ? `${text} · ${label.duration}` : text;
}
```

3b. Create `src/components/chat/components/CallMessageCard.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { Phone, PhoneIncoming, PhoneMissed, PhoneOutgoing, Video } from "lucide-react";
import { callLabel, CallData } from "../lib/callLabel";

interface CallMessageCardProps {
  callData: CallData | null | undefined;
  viewerId: string;
  isSent: boolean;
  otherName: string;
}

/**
 * A call-history message (messageType 'call'), drawn the way the app's
 * CallHistoryBubble draws it: kind icon, the viewer-side label, the duration
 * of a completed call, a direction icon; red for missed or declined.
 */
const CallMessageCard: React.FC<CallMessageCardProps> = ({ callData, viewerId, isSent, otherName }) => {
  const { t } = useTranslation();
  const label = callLabel(callData, viewerId, isSent, otherName);
  const text = t(label.key, label.params) || label.fallback;
  const KindIcon = label.isVideo ? Video : Phone;
  const DirectionIcon = label.missed
    ? PhoneMissed
    : label.direction === "outgoing"
    ? PhoneOutgoing
    : PhoneIncoming;

  return (
    <div
      className={`call-card${label.negative ? " call-card--negative" : ""}`}
      data-testid="call-card"
      data-outcome={label.outcome}
    >
      <KindIcon size={18} className="call-card-kind" aria-hidden="true" />
      <div className="call-card-body">
        <span className="call-card-label">{text}</span>
        {label.duration ? <span className="call-card-duration">{label.duration}</span> : null}
      </div>
      <DirectionIcon size={16} className="call-card-direction" aria-hidden="true" />
    </div>
  );
};

export default CallMessageCard;
```

3c. `src/components/chat/MessageBubble.tsx`:

Add the import under `import { firstLink } from "./utils/linkDetector";`:
```tsx
import CallMessageCard from "./components/CallMessageCard";
import { CallData } from "./lib/callLabel";
```

In `export interface MessageMedia` add after `dimensions?: { width: number; height: number };`:
```tsx
  /** media.type 'call' (services/callMessageService.js). */
  callData?: CallData;
```

Replace
```tsx
  const hasMedia = !!msg.media?.type && !isVoice;
  const isPlainText = !isSticker && !isGif && !isVoice && !hasMedia;
```
with
```tsx
  // A call record is media.type 'call' with an English fallback text; it is a
  // card of its own, never an attachment and never a text bubble.
  const isCall = msg.messageType === "call" || msg.media?.type === "call";
  const hasMedia = !!msg.media?.type && !isVoice && !isCall;
  const isPlainText = !isSticker && !isGif && !isVoice && !hasMedia && !isCall;
```

Replace the bubble class line
```tsx
          className={`message-bubble${isVoice ? " voice-bubble" : ""}${hasMedia ? " media-bubble" : ""}${isSticker ? " sticker-bubble" : ""}${bubblePositionClass(position)}`}
        >
          {isSticker ? (
```
with
```tsx
          className={`message-bubble${isVoice ? " voice-bubble" : ""}${hasMedia ? " media-bubble" : ""}${isSticker ? " sticker-bubble" : ""}${isCall ? " call-bubble" : ""}${bubblePositionClass(position)}`}
        >
          {isCall ? (
            <CallMessageCard
              callData={msg.media && msg.media.callData}
              viewerId={currentUserId}
              isSent={isSent}
              otherName={otherUserName}
            />
          ) : isSticker ? (
```

Replace the chip-row condition
```tsx
        {!isSent && !isSticker && !isVoice && !hasMedia && msg.message && (
```
with
```tsx
        {!isSent && !isSticker && !isVoice && !hasMedia && !isCall && msg.message && (
```

3d. Conversation-list preview (P3-CHAT-6 owns the list). If P3-CHAT-6's preview helper still shows a generic line (or
`📎 Attachment`) for `media.type === 'call'`, make its call branch read:
```tsx
  if (msg.messageType === "call" || (msg.media && msg.media.type === "call")) {
    return callPreviewText(t, (msg.media as any) && (msg.media as any).callData, viewerId, senderIdOf(msg) === viewerId, partnerName);
  }
```
with `import { callPreviewText } from "./lib/callLabel";` — use whatever names P3-CHAT-6 gave the viewer id, partner
name and sender-id helper in that function. Add a `UsersList.test.tsx` case if 6 did not: a conversation whose
`lastMessage` is `{messageType:'call', media:{type:'call', callData:{outcome:'no_answer', initiator:'u2'}}}` previews
"Missed voice call".

3e. Append to `src/components/chat/ChatContent.css`:
```css
/* Call history card (chat#6) — the bubble is only the card's frame. */
.message-bubble.call-bubble {
  background: transparent !important;
  padding: 0 !important;
  box-shadow: none !important;
}

.call-card {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 200px;
  padding: 10px 12px;
  background: var(--chat-card-in);
  border: 1px solid var(--chat-line);
  border-radius: 12px;
  color: var(--chat-text);
}

.modern-message.sent .call-card {
  background: var(--chat-card-out);
  border-color: var(--chat-card-out);
  color: var(--chat-bubble-out-text);
}

.call-card--negative,
.modern-message.sent .call-card--negative {
  background: var(--chat-danger-soft);
  border-color: var(--chat-danger-line);
  color: var(--chat-danger);
}

.call-card-body {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;
}

.call-card-label {
  font-size: 14px;
  font-weight: 600;
}

.call-card-duration {
  font-size: 12px;
  color: var(--chat-muted);
  font-variant-numeric: tabular-nums;
}
```

3f. `src/components/chat/chatStyling.test.ts`: add `"components/CallMessageCard.tsx",` to `STRICT_FILES`.

3g. `src/utils/locales/eng.json`, inside `"chatPage"`, add:
```json
"call": {
  "outgoingVoice": "Outgoing voice call",
  "outgoingVideo": "Outgoing video call",
  "incomingVoice": "Incoming voice call",
  "incomingVideo": "Incoming video call",
  "noAnswerVoice": "Voice call · No answer",
  "noAnswerVideo": "Video call · No answer",
  "missedVoice": "Missed voice call",
  "missedVideo": "Missed video call",
  "cancelledVoice": "Cancelled voice call",
  "cancelledVideo": "Cancelled video call",
  "declinedOutgoingVoice": "Voice call declined",
  "declinedOutgoingVideo": "Video call declined",
  "declinedIncomingVoice": "Declined voice call",
  "declinedIncomingVideo": "Declined video call",
  "busy": "{{name}} was on another call"
}
```

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false callLabel MessageBubble chatStyling chatTokens UsersList
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/chat/lib/callLabel.ts src/components/chat/lib/callLabel.test.ts \
  src/components/chat/components/CallMessageCard.tsx src/components/chat/MessageBubble.tsx \
  src/components/chat/MessageBubble.test.tsx src/components/chat/ChatContent.css \
  src/components/chat/chatStyling.test.ts src/components/chat/UsersList.tsx src/components/chat/UsersList.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): draw app call-history messages as call cards

The backend writes one messageType 'call' message per finished call with
media.callData. The web treated any media.type as an attachment and showed
a paperclip and "File". The bubble now renders a call card worded from the
viewer's side (outgoing/incoming, missed, declined, busy, duration), the
same cases as the app's CallLabels, including legacy status-only rows.
The list preview uses the same wording.

Still open (Phase 3 chat): location messages + sending, wave/sticker sizing
and bare senders, story shares, pinned/edited/forwarded, premium wallpapers,
search, bookmarks, archive + mute durations, blocked banner, i18n sweep.
EOF
```

---

### Task P3-CHAT-11: Location messages render as a map card, and the web can send one (chat#7, chat#17)

**Files:**
- Modify: `src/store/slices/chatSlice.ts` (new `sendLocationMessage` after `sendVideoMessage` :300-309; export)
- Create: `src/components/chat/components/LocationMessageCard.tsx`, `src/components/chat/components/LocationShareButton.tsx`
- Modify: `src/components/chat/MessageBubble.tsx` (`MessageMedia`, flags, `renderMediaContent` :248-306)
- Modify: `src/components/chat/ChatContent.tsx` (composer, after the attachment button :2175-2183)
- Modify: `src/components/chat/ChatContent.test.tsx`, `src/components/chat/ChatContent.pagination.test.tsx` (stub)
- Modify: `src/components/chat/ChatContent.css`, `src/components/chat/chatStyling.test.ts`, `src/utils/locales/eng.json`
- Test: `src/store/slices/chatLocationEndpoint.test.ts` (new), `src/components/chat/components/LocationShareButton.test.tsx` (new),
  `src/components/chat/MessageBubble.test.tsx` (append)

**Interfaces:**
- Consumes: app `message_provider.dart:820-843` posts `POST /api/v1/messages` JSON
  `{receiver, location:{latitude, longitude, address?, placeName?}}` with no `type`. Backend
  `controllers/messages.js:639-648` stores `media:{type:'location', location:{latitude, longitude, address|null,
  placeName|null}}`, `message: null`, `messageType:'text'`; the route runs `checkMessageLimit` + `checkConversationStart`
  like any send, so 403/429 can come back. Note the server's `location.latitude && location.longitude` check: a
  coordinate of exactly 0 is refused with 400 (open item, backend). Reverse geocode: `GET /api/v1/geocode/reverse?lat&lng`
  → `{success, data:{city, country, formattedAddress, coordinates}|null}` (`controllers/geocode.js`), via the existing
  `useLazyReverseGeocodeQuery` (`usersSlice.ts:395`, export `:445`).
- Produces: `useSendLocationMessageMutation({receiver, latitude, longitude, address?, placeName?})`;
  `mapsUrl(lat, lng)` (Google Maps search URL, the one the app opens in `widgets/media_message_widget.dart:229`).

- [ ] **Step 1: Write the failing tests**

`src/store/slices/chatLocationEndpoint.test.ts`:

```ts
/**
 * The web sends a location with the exact body the app sends
 * (message_provider.dart sendLocationMessage): POST /messages, JSON
 * {receiver, location:{latitude, longitude, address?, placeName?}}.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { chatApiSlice } from "./chatSlice";
import * as chatSliceExports from "./chatSlice";
import { MESSAGES_URL } from "../../constants";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: null }) => state,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; body: string | undefined };

function mockFetch(): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify({ success: true, data: {} }), {
      status: 201,
      headers: { "content-type": "application/json" },
    });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

it("exports the hook", () => {
  expect(typeof (chatSliceExports as any).useSendLocationMessageMutation).toBe("function");
});

it("POSTs {receiver, location} to /messages", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(
    (chatApiSlice.endpoints as any).sendLocationMessage.initiate({
      receiver: "u2",
      latitude: 37.5665,
      longitude: 126.978,
      placeName: "Seoul, South Korea",
      address: "Jung-gu, Seoul, South Korea",
    })
  );
  expect(calls).toHaveLength(1);
  expect(new URL(calls[0].url).pathname).toBe(MESSAGES_URL);
  expect(calls[0].method).toBe("POST");
  expect(JSON.parse(calls[0].body as string)).toEqual({
    receiver: "u2",
    location: {
      latitude: 37.5665,
      longitude: 126.978,
      placeName: "Seoul, South Korea",
      address: "Jung-gu, Seoul, South Korea",
    },
  });
});

it("leaves out a place name and address it does not have", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(
    (chatApiSlice.endpoints as any).sendLocationMessage.initiate({ receiver: "u2", latitude: 1.5, longitude: 2.5 })
  );
  expect(JSON.parse(calls[0].body as string)).toEqual({ receiver: "u2", location: { latitude: 1.5, longitude: 2.5 } });
});
```

`src/components/chat/components/LocationShareButton.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import LocationShareButton from "./LocationShareButton";

const mockSend = jest.fn();
const mockReverse = jest.fn();
const mockNotifyError = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../../store/slices/chatSlice", () => ({
  useSendLocationMessageMutation: () => [mockSend, { isLoading: false }],
}));

jest.mock("../../../store/slices/usersSlice", () => ({
  useLazyReverseGeocodeQuery: () => [mockReverse, {}],
}));

jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { error: (m: string) => mockNotifyError(m), success: jest.fn(), info: jest.fn() },
}));

function installGeolocation(impl: (ok: any, fail: any) => void) {
  (navigator as any).geolocation = { getCurrentPosition: jest.fn(impl) };
}

const position = { coords: { latitude: 37.5665123, longitude: 126.9780456 } };

beforeEach(() => {
  mockSend.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
  mockReverse.mockReturnValue({
    unwrap: () =>
      Promise.resolve({
        data: { city: "Seoul", country: "South Korea", formattedAddress: "Jung-gu, Seoul, South Korea" },
      }),
  });
});

afterEach(() => {
  jest.clearAllMocks();
  delete (navigator as any).geolocation;
});

it("asks before sending, showing the place it found", async () => {
  installGeolocation((ok) => ok(position));
  render(<LocationShareButton receiverId="u2" />);

  fireEvent.click(screen.getByTestId("share-location"));

  expect(await screen.findByText("Share your location?")).toBeInTheDocument();
  expect(screen.getByText("Seoul, South Korea")).toBeInTheDocument();
  expect(mockSend).not.toHaveBeenCalled();
});

it("sends the app's body once confirmed", async () => {
  installGeolocation((ok) => ok(position));
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  fireEvent.click(await screen.findByText("Send"));

  await waitFor(() =>
    expect(mockSend).toHaveBeenCalledWith({
      receiver: "u2",
      latitude: 37.566512,
      longitude: 126.978046,
      placeName: "Seoul, South Korea",
      address: "Jung-gu, Seoul, South Korea",
    })
  );
});

it("still sends the pin when the place lookup fails", async () => {
  installGeolocation((ok) => ok(position));
  mockReverse.mockReturnValue({ unwrap: () => Promise.reject(new Error("nominatim down")) });
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  fireEvent.click(await screen.findByText("Send"));

  await waitFor(() =>
    expect(mockSend).toHaveBeenCalledWith({ receiver: "u2", latitude: 37.566512, longitude: 126.978046 })
  );
});

it("says so when the browser refuses the permission", async () => {
  installGeolocation((_ok, fail) => fail({ code: 1 }));
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  await waitFor(() => expect(mockNotifyError).toHaveBeenCalledWith("Location permission was denied"));
  expect(mockSend).not.toHaveBeenCalled();
});

it("says so when the browser has no geolocation at all", () => {
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  expect(mockNotifyError).toHaveBeenCalledWith("This browser can't share a location");
});

it("keeps the dialog open with the server's reason when the send is refused", async () => {
  installGeolocation((ok) => ok(position));
  mockSend.mockReturnValue({ unwrap: () => Promise.reject({ data: { error: "Cannot send message to blocked user" } }) });
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  fireEvent.click(await screen.findByText("Send"));
  expect(await screen.findByText("Cannot send message to blocked user")).toBeInTheDocument();
});
```

Append to `src/components/chat/MessageBubble.test.tsx`:

```tsx
describe("location messages (chat#7)", () => {
  const locationMessage = (location: any): Message =>
    message({ message: "", media: { type: "location", url: "", location } as any });

  it("draws a map card that opens the pin in Maps, not a File attachment", () => {
    renderBubble({
      message: locationMessage({ latitude: 37.5665, longitude: 126.978, placeName: "Seoul", address: "Jung-gu" }),
    });
    const card = screen.getByTestId("location-card");
    expect(card).toHaveAttribute("href", "https://www.google.com/maps/search/?api=1&query=37.5665,126.978");
    expect(card).toHaveAttribute("target", "_blank");
    expect(screen.getByText("Seoul")).toBeInTheDocument();
    expect(screen.getByText("Jung-gu")).toBeInTheDocument();
    expect(screen.queryByText("File")).toBeNull();
  });

  it("titles a pin with no names 'Location'", () => {
    renderBubble({ message: locationMessage({ latitude: 1, longitude: 2, placeName: null, address: null }) });
    expect(screen.getByText("Location")).toBeInTheDocument();
  });

  it("draws a card with no link when the coordinates are missing", () => {
    renderBubble({ message: locationMessage(undefined) });
    expect(screen.getByTestId("location-card")).not.toHaveAttribute("href");
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatLocationEndpoint LocationShareButton MessageBubble
```
Expected: the endpoint suite fails (`sendLocationMessage` undefined → `Cannot read properties of undefined (reading 'initiate')`,
hook not exported); `LocationShareButton.test.tsx` cannot find the module; the location bubble cases find "File".

- [ ] **Step 3: Implement**

3a. `src/store/slices/chatSlice.ts` — after the `sendVideoMessage` endpoint (ends `onQueryStarted: refetchFirstPageOnSuccess,\n    }),`)
add:
```ts
    // Location — POST /api/v1/messages, JSON {receiver, location}: the body the
    // app sends (message_provider.dart sendLocationMessage). The server stores
    // media.type 'location' with an empty text; the bubble draws a map card.
    sendLocationMessage: builder.mutation({
      query: ({
        receiver,
        latitude,
        longitude,
        address,
        placeName,
      }: {
        receiver: string;
        latitude: number;
        longitude: number;
        address?: string;
        placeName?: string;
      }) => {
        const location: { [key: string]: any } = { latitude: latitude, longitude: longitude };
        if (address) location.address = address;
        if (placeName) location.placeName = placeName;
        return { url: `${MESSAGES_URL}`, method: "POST", body: { receiver: receiver, location: location } };
      },
      invalidatesTags: ["Conversations"],
      onQueryStarted: refetchFirstPageOnSuccess,
    }),
```
and in the export list after `useSendVideoMessageMutation,` add:
```ts
  // Location
  useSendLocationMessageMutation,
```

3b. Create `src/components/chat/components/LocationMessageCard.tsx`:
```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { MapPin } from "lucide-react";

export interface MessageLocation {
  latitude?: number | null;
  longitude?: number | null;
  address?: string | null;
  placeName?: string | null;
}

/** The URL the app opens for a location message (widgets/media_message_widget.dart). */
export function mapsUrl(latitude: number, longitude: number): string {
  return `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`;
}

function hasCoordinates(location: MessageLocation | null | undefined): boolean {
  if (!location) return false;
  const lat = Number(location.latitude);
  const lng = Number(location.longitude);
  return location.latitude !== null && location.longitude !== null && isFinite(lat) && isFinite(lng);
}

/**
 * A location message (media.type 'location'): a pin, the place name (or the
 * address, or "Location"), the address under a place name, and a link that
 * opens the pin in Maps. Nothing is fetched to draw it.
 */
const LocationMessageCard: React.FC<{ location?: MessageLocation | null }> = ({ location }) => {
  const { t } = useTranslation();
  const generic = t("chatPage.location.title") || "Location";
  const title = (location && (location.placeName || location.address)) || generic;
  const subtitle = location && location.placeName && location.address ? location.address : null;
  const body = (
    <React.Fragment>
      <MapPin size={20} className="location-card-pin" aria-hidden="true" />
      <span className="location-card-text">
        <span className="location-card-title">{title}</span>
        {subtitle ? <span className="location-card-sub">{subtitle}</span> : null}
        <span className="location-card-open">{t("chatPage.location.open") || "Open in Maps"}</span>
      </span>
    </React.Fragment>
  );

  if (!hasCoordinates(location)) {
    return (
      <div className="location-card location-card--empty" data-testid="location-card">
        {body}
      </div>
    );
  }
  const loc = location as MessageLocation;
  return (
    <a
      className="location-card"
      data-testid="location-card"
      href={mapsUrl(Number(loc.latitude), Number(loc.longitude))}
      target="_blank"
      rel="noopener noreferrer"
      onClick={(e) => e.stopPropagation()}
    >
      {body}
    </a>
  );
};

export default LocationMessageCard;
```

3c. Create `src/components/chat/components/LocationShareButton.tsx`:
```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { MapPin } from "lucide-react";
import ConfirmDialog from "../../../design/ConfirmDialog";
import notify from "../../../design/notify";
import { useSendLocationMessageMutation } from "../../../store/slices/chatSlice";
import { useLazyReverseGeocodeQuery } from "../../../store/slices/usersSlice";

interface PendingLocation {
  latitude: number;
  longitude: number;
  placeName?: string;
  address?: string;
}

interface LocationShareButtonProps {
  receiverId: string;
  disabled?: boolean;
}

/** Six decimals (~10 cm) is everything a phone fix carries; more is noise. */
const round = (value: number): number => Math.round(value * 1e6) / 1e6;

/**
 * Share the current location in the chat, the way the app's location option
 * does: the browser's fix, an optional place name from our own reverse
 * geocoder, then a confirmation that shows what will be sent. Nothing goes
 * out without the explicit Send.
 */
const LocationShareButton: React.FC<LocationShareButtonProps> = ({ receiverId, disabled }) => {
  const { t } = useTranslation();
  const [sendLocation, { isLoading }] = useSendLocationMessageMutation();
  const [reverseGeocode] = useLazyReverseGeocodeQuery();
  const [locating, setLocating] = useState(false);
  const [pending, setPending] = useState<PendingLocation | null>(null);
  const [error, setError] = useState("");

  const locate = (): void => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      notify.error(t("chatPage.location.unsupported") || "This browser can't share a location");
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const next: PendingLocation = {
          latitude: round(pos.coords.latitude),
          longitude: round(pos.coords.longitude),
        };
        try {
          const res: any = await reverseGeocode({ lat: next.latitude, lng: next.longitude }).unwrap();
          const place = res && res.data;
          if (place) {
            const name = [place.city, place.country].filter(Boolean).join(", ");
            if (name) next.placeName = name;
            if (place.formattedAddress) next.address = place.formattedAddress;
          }
        } catch (lookupError) {
          // The pin alone is a complete location message.
        }
        setLocating(false);
        setPending(next);
      },
      (positionError) => {
        setLocating(false);
        notify.error(
          positionError && positionError.code === 1
            ? t("chatPage.location.denied") || "Location permission was denied"
            : t("chatPage.location.failed") || "Couldn't get your location"
        );
      },
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 }
    );
  };

  const confirm = async (): Promise<void> => {
    if (!pending) return;
    setError("");
    try {
      await sendLocation({ receiver: receiverId, ...pending }).unwrap();
      setPending(null);
    } catch (sendError) {
      const data: any = sendError && (sendError as any).data;
      setError(
        (data && (data.error || data.message)) ||
          t("chatPage.location.sendFailed") ||
          "Couldn't send your location"
      );
    }
  };

  const label = t("chatPage.location.share") || "Share location";
  return (
    <React.Fragment>
      <button
        type="button"
        className="attachment-btn"
        data-testid="share-location"
        title={label}
        aria-label={label}
        onClick={locate}
        disabled={disabled || locating || isLoading}
      >
        {locating ? <span className="spinner spinner--sm" /> : <MapPin size={20} />}
      </button>
      <ConfirmDialog
        open={!!pending}
        title={t("chatPage.location.confirmTitle") || "Share your location?"}
        body={
          pending
            ? pending.placeName || pending.address || `${pending.latitude}, ${pending.longitude}`
            : undefined
        }
        confirmLabel={t("chatPage.location.send") || "Send"}
        cancelLabel={t("chatPage.location.cancel") || "Cancel"}
        busy={isLoading}
        error={error || undefined}
        onConfirm={confirm}
        onCancel={() => {
          setPending(null);
          setError("");
        }}
      />
    </React.Fragment>
  );
};

export default LocationShareButton;
```

3d. `src/components/chat/MessageBubble.tsx`:
- import under the `CallMessageCard` import:
  ```tsx
  import LocationMessageCard, { MessageLocation } from "./components/LocationMessageCard";
  ```
- `MessageMedia`: add `location?: MessageLocation;`
- the flags become
  ```tsx
  const isCall = msg.messageType === "call" || msg.media?.type === "call";
  const isLocation = msg.media?.type === "location";
  const hasMedia = !!msg.media?.type && !isVoice && !isCall && !isLocation;
  const isPlainText = !isSticker && !isGif && !isVoice && !hasMedia && !isCall && !isLocation;
  ```
- in `renderMediaContent`, directly after `if (mediaType === "voice") { return renderVoiceMessage(); }` add:
  ```tsx
    if (mediaType === "location") {
      return <LocationMessageCard location={msg.media.location} />;
    }
  ```
- the chip-row condition gains `&& !isLocation` after `!isCall`.

3e. `src/components/chat/ChatContent.tsx`:
- import under `import ChatInfoPanel from "./ChatInfoPanel";`:
  ```tsx
  import LocationShareButton from "./components/LocationShareButton";
  ```
- in the composer, directly after the attachment button that ends
  ```tsx
                {mediaPreview ? <ImageIcon size={20} /> : <Paperclip size={20} />}
              </button>
  ```
  add
  ```tsx
              <LocationShareButton receiverId={selectedUser} disabled={!!mediaPreview} />
  ```

3f. Both `ChatContent.test.tsx` and `ChatContent.pagination.test.tsx`: next to the existing `jest.mock("./ChatInfoPanel", …)`
add
```tsx
// Owns its own store hooks; its suite is components/LocationShareButton.test.tsx.
jest.mock("./components/LocationShareButton", () => ({
  __esModule: true,
  default: () => require("react").createElement("span", { "data-testid": "share-location" }),
}));
```
and in `ChatContent.test.tsx` add the composer case:
```tsx
it("offers Share location in the composer", () => {
  renderChat("/chat/u2");
  expect(screen.getByTestId("share-location")).toBeInTheDocument();
});
```

3g. Append to `src/components/chat/ChatContent.css`:
```css
/* Location card (chat#7) */
.location-card {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  width: 250px;
  max-width: 100%;
  padding: 10px 12px;
  background: var(--chat-card-in);
  border: 1px solid var(--chat-line);
  border-radius: 12px;
  color: var(--chat-text);
  text-decoration: none;
}

.modern-message.sent .location-card {
  background: var(--chat-card-out);
  border-color: var(--chat-card-out);
  color: var(--chat-bubble-out-text);
}

.location-card:hover {
  text-decoration: none;
}

.location-card-pin {
  flex: none;
  color: var(--chat-danger);
}

.location-card-text {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.location-card-title {
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.location-card-sub,
.location-card-open {
  font-size: 12px;
  color: var(--chat-muted);
}

.location-card--empty .location-card-open {
  display: none;
}
```

3h. `chatStyling.test.ts` `STRICT_FILES`: add `"components/LocationMessageCard.tsx",` and `"components/LocationShareButton.tsx",`.

3i. `eng.json` `chatPage`:
```json
"location": {
  "title": "Location",
  "open": "Open in Maps",
  "share": "Share location",
  "confirmTitle": "Share your location?",
  "send": "Send",
  "cancel": "Cancel",
  "unsupported": "This browser can't share a location",
  "denied": "Location permission was denied",
  "failed": "Couldn't get your location",
  "sendFailed": "Couldn't send your location"
}
```

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatLocationEndpoint LocationShareButton MessageBubble ChatContent chatStyling chatTokens chatActionsEndpoints
```

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/chatSlice.ts src/store/slices/chatLocationEndpoint.test.ts \
  src/components/chat/components/LocationMessageCard.tsx src/components/chat/components/LocationShareButton.tsx \
  src/components/chat/components/LocationShareButton.test.tsx src/components/chat/MessageBubble.tsx \
  src/components/chat/MessageBubble.test.tsx src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx \
  src/components/chat/ChatContent.pagination.test.tsx src/components/chat/ChatContent.css \
  src/components/chat/chatStyling.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(chat): location messages render as map cards and can be sent from web

App location messages (media.type 'location', empty text) showed as a
paperclip and "File". They now draw a card with the place name, address
and a Maps link (the URL the app opens). The composer gains Share location:
browser fix, optional place name from our reverse geocoder, a confirmation
showing what will be sent, then the app's exact body {receiver, location}.

Still open (Phase 3 chat): wave/sticker sizing and bare senders, story
shares, pinned/edited/forwarded, premium wallpapers, search, bookmarks,
archive + mute durations, blocked banner, i18n sweep. Backend: a latitude
or longitude of exactly 0 is refused (truthiness check).
EOF
```

---

### Task P3-CHAT-12: Waves are a greeting card, only 1–3 emoji are sticker-sized, and a bare-id sender lands on the right side (chat#8)

**Files:**
- Create: `src/components/chat/lib/messageKinds.ts`, `src/components/chat/lib/normalizeMessage.ts`
- Modify: `src/components/chat/MessageBubble.tsx` (`isSticker` :206, sticker branch :388-389)
- Modify: `src/components/chat/ChatContent.tsx` (`handleNewMessage` :394-431, `handleMediaMessage` :434-454,
  `handleMessageSent` :456-490, `handleQueuedMessages` :643-663, render map :2017)
- Modify: `src/components/chat/ChatContent.css` (append)
- Test: `src/components/chat/lib/messageKinds.test.ts`, `src/components/chat/lib/normalizeMessage.test.ts` (new),
  `src/components/chat/MessageBubble.test.tsx` (append + one changed case), `src/components/chat/ChatContent.pagination.test.tsx` (append)

**Interfaces:**
- Consumes: backend `lib/waveMirror.js:16-38` stores the wave text (up to 200 chars, often a sentence) as
  `messageType:'sticker'` and emits `newMessage` (to the receiver) and `messageSent` (to the waver) with **unpopulated**
  `sender`/`receiver` (bare ObjectId strings) until P1-CHAT-5 is deployed; `story_share` emits the same way
  (`controllers/stories.js:1485`). After P1-CHAT-5 they are populated `{_id, name, images}`. Both shapes must work, and
  so must 2.6.1 rows already stored. The app decides by content (`text_message_view.dart:114-130`): `👋` with any skin tone
  → greeting card ("Hi!"), emoji-only → sticker size, anything else → a normal text bubble.
- Produces: `isEmojiOnly(text)`, `isWaveText(text)`, `normalizeMessage(msg)`, `senderIdOf(msg)` — used again by
  P3-CHAT-13/16/17.

- [ ] **Step 1: Write the failing tests**

`src/components/chat/lib/messageKinds.test.ts`:

```ts
import { isEmojiOnly, isWaveText } from "./messageKinds";

/**
 * The app sizes a message by what it says, not by its messageType
 * (text_message_view.dart _isWaveSticker / _isSticker): the wave mirror
 * stores whole sentences as 'sticker', and a plain-text "😂" is a sticker
 * too. Emoji are written as escapes so this file reads the same everywhere.
 */
const WAVE = "\u{1F44B}";
const WAVE_DARK = "\u{1F44B}\u{1F3FF}";
const LAUGH = "\u{1F602}";
const HEART = "❤️";
const FAMILY = "\u{1F468}‍\u{1F469}‍\u{1F467}";
const FLAG_KR = "\u{1F1F0}\u{1F1F7}";
const KEYCAP_ONE = "1️⃣";

describe("isWaveText", () => {
  it("is a wave hand, with or without a skin tone", () => {
    expect(isWaveText(WAVE)).toBe(true);
    expect(isWaveText(` ${WAVE_DARK} `)).toBe(true);
  });
  it("is not a sentence that starts with one, or two hands", () => {
    expect(isWaveText(`${WAVE} Hi, I'm learning Korean!`)).toBe(false);
    expect(isWaveText(WAVE + WAVE)).toBe(false);
    expect(isWaveText("")).toBe(false);
    expect(isWaveText(undefined)).toBe(false);
  });
});

describe("isEmojiOnly", () => {
  it("accepts one to three emoji, ZWJ families, flags, keycaps and hearts included", () => {
    expect(isEmojiOnly(LAUGH)).toBe(true);
    expect(isEmojiOnly(LAUGH + LAUGH + LAUGH)).toBe(true);
    expect(isEmojiOnly(`${LAUGH} ${HEART}`)).toBe(true);
    expect(isEmojiOnly(FAMILY)).toBe(true);
    expect(isEmojiOnly(FLAG_KR)).toBe(true);
    expect(isEmojiOnly(KEYCAP_ONE)).toBe(true);
  });
  it("refuses four or more, any letters, digits, or nothing", () => {
    expect(isEmojiOnly(LAUGH + LAUGH + LAUGH + LAUGH)).toBe(false);
    expect(isEmojiOnly(`${LAUGH} ok`)).toBe(false);
    expect(isEmojiOnly("123")).toBe(false);
    expect(isEmojiOnly("Hi, I'm learning Korean and want to practise with you")).toBe(false);
    expect(isEmojiOnly("   ")).toBe(false);
    expect(isEmojiOnly(null)).toBe(false);
  });
});
```

`src/components/chat/lib/normalizeMessage.test.ts`:

```ts
import { normalizeMessage, senderIdOf, idOf } from "./normalizeMessage";

describe("normalizeMessage", () => {
  it("turns a bare sender id into the {_id} shape every reader expects", () => {
    const msg: any = { _id: "m1", message: "x", sender: "me", receiver: "u2" };
    const out: any = normalizeMessage(msg);
    expect(out.sender).toEqual({ _id: "me", name: "" });
    expect(out.receiver).toBe("u2");
  });
  it("hands a populated message back untouched (same object)", () => {
    const msg: any = { _id: "m1", sender: { _id: "me", name: "Me" }, receiver: { _id: "u2", name: "Ada" } };
    expect(normalizeMessage(msg)).toBe(msg);
  });
  it("survives a message with no sender at all", () => {
    const out: any = normalizeMessage({ _id: "m1" } as any);
    expect(out.sender).toEqual({ _id: "", name: "" });
  });
});

describe("senderIdOf / idOf", () => {
  it("reads either shape", () => {
    expect(senderIdOf({ sender: "me" } as any)).toBe("me");
    expect(senderIdOf({ sender: { _id: "me" } } as any)).toBe("me");
    expect(senderIdOf({} as any)).toBe("");
    expect(idOf({ _id: 42 })).toBe("42");
  });
});
```

Append to `MessageBubble.test.tsx`:

```tsx
describe("waves and stickers are sized by what they say (chat#8)", () => {
  it("draws a greeting card for a wave, with the hand the message carried", () => {
    renderBubble({ message: message({ message: "\u{1F44B}\u{1F3FD}", messageType: "sticker" }) });
    const card = screen.getByTestId("wave-card");
    expect(card).toHaveTextContent("\u{1F44B}\u{1F3FD}");
    expect(card).toHaveTextContent("Hi!");
    expect(document.querySelector(".sticker-message")).toBeNull();
  });

  it("draws a wave sentence stored as 'sticker' as a normal text bubble", () => {
    renderBubble({
      message: message({ message: "\u{1F44B} Hi! I'm learning Korean, want to practise?", messageType: "sticker" }),
    });
    expect(document.querySelector(".sticker-message")).toBeNull();
    expect(document.querySelector(".message-text")).toHaveTextContent("I'm learning Korean");
  });

  it("draws one to three emoji at sticker size, whatever the messageType", () => {
    renderBubble({ message: message({ message: "\u{1F602}\u{1F602}", messageType: "text" }) });
    expect(document.querySelector(".sticker-message")).toHaveTextContent("\u{1F602}\u{1F602}");
  });

  it("draws four emoji as text", () => {
    renderBubble({ message: message({ message: "\u{1F602}\u{1F602}\u{1F602}\u{1F602}" }) });
    expect(document.querySelector(".sticker-message")).toBeNull();
  });
});
```

In the same file, the existing case
```tsx
  it("shows no card on a sticker", () => {
    renderBubble({
      message: message({ message: "https://example.com", messageType: "sticker" }),
```
pinned the old rule (any `messageType:'sticker'` is a sticker). Under the app's rule a URL is text. Replace that case
with:
```tsx
  it("shows no link card on an emoji sticker", () => {
    renderBubble({ message: message({ message: "\u{1F602}", messageType: "sticker" }) });
    expect(screen.queryByTestId("message-link-card")).toBeNull();
  });
```

Append to `ChatContent.pagination.test.tsx`:

```tsx
// --- Bare-id senders (chat#8) ------------------------------------------------
//
// The wave mirror and story_share emits carried an UNPOPULATED sender: a bare
// id string. `msg.sender._id` was undefined, so a wave the web user sent
// showed as RECEIVED, with a broken avatar, until a reload.

it("puts a wave I sent, with a bare-id sender, on my side", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  socket.fire("messageSent", {
    message: {
      _id: "wave-1",
      message: "\u{1F44B}",
      messageType: "sticker",
      createdAt: "2026-09-20T12:00:00.000Z",
      sender: "me",
      receiver: "u2",
    },
    receiverId: "u2",
  });

  await waitFor(() => expect(renderedIds()).toContain("wave-1"));
  const bubble = document.querySelector('[data-msg-id="wave-1"]') as HTMLElement;
  expect(bubble).toHaveClass("sent");
  expect(bubble.querySelector('[data-testid="wave-card"]')).not.toBeNull();
});

it("puts their wave, with a bare-id sender, on their side", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  socket.fire("newMessage", {
    message: {
      _id: "wave-2",
      message: "\u{1F44B}",
      messageType: "sticker",
      createdAt: "2026-09-20T12:00:00.000Z",
      sender: "u2",
      receiver: "me",
    },
    unreadCount: 1,
  });

  await waitFor(() => expect(renderedIds()).toContain("wave-2"));
  expect(document.querySelector('[data-msg-id="wave-2"]')).toHaveClass("received");
});
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false messageKinds normalizeMessage MessageBubble ChatContent.pagination
```
Expected: the two lib suites cannot find their modules; the wave/emoji bubble cases fail (no `wave-card`, the sentence
gets `.sticker-message`, plain-text emoji are not stickers); `wave-1` renders with class `received`; `wave-2` is never
added (`newMsg.sender._id === currentSelectedUser` is false and there is no `senderId`) — after the fix the
sender check matches it (the normalized `sender._id` is `u2`).

- [ ] **Step 3: Implement**

3a. Create `src/components/chat/lib/messageKinds.ts`:
```ts
/**
 * What a message IS, read from what it says — the app's rule
 * (text_message_view.dart _isWaveSticker / _isSticker), not messageType. The
 * wave mirror stores whole sentences as 'sticker'; a plain-text emoji is a
 * sticker all the same.
 *
 * Kept out of the components on purpose: chatStyling.test.ts forbids emoji
 * characters in chat component sources, so every emoji here is an escape.
 */

// One emoji as a person sees it: a flag (two regional indicators), a keycap,
// or a pictograph with an optional VS16 / skin tone, ZWJ-joined to more.
const CLUSTER =
  "(?:\\p{Regional_Indicator}{2}" +
  "|[0-9#*]\\uFE0F?\\u20E3" +
  "|\\p{Extended_Pictographic}(?:\\uFE0F|\\p{Emoji_Modifier})?" +
  "(?:\\u200D\\p{Extended_Pictographic}(?:\\uFE0F|\\p{Emoji_Modifier})?)*)";

const EMOJI_ONLY = new RegExp(`^(?:${CLUSTER}\\s*){1,3}$`, "u");
const WAVE = new RegExp("^\\u{1F44B}\\p{Emoji_Modifier}?\\uFE0F?$", "u");

/** One to three emoji and nothing else: drawn at sticker size. */
export function isEmojiOnly(text: string | null | undefined): boolean {
  if (typeof text !== "string") return false;
  const trimmed = text.trim();
  if (!trimmed || trimmed.length > 48) return false;
  return EMOJI_ONLY.test(trimmed);
}

/** A lone waving hand, any skin tone: drawn as the app's greeting card. */
export function isWaveText(text: string | null | undefined): boolean {
  if (typeof text !== "string") return false;
  return WAVE.test(text.trim());
}
```

3b. Create `src/components/chat/lib/normalizeMessage.ts`:
```ts
/**
 * Socket payloads do not always carry a populated sender. The wave mirror and
 * story_share emits sent the bare id (backend P1-CHAT-5 populates them; rows
 * and clients from before it remain). Every reader here does
 * `msg.sender._id`, so a bare id put my own message on the wrong side.
 */
export function idOf(party: any): string {
  if (!party) return "";
  if (typeof party === "string") return party;
  return party._id !== undefined && party._id !== null ? String(party._id) : "";
}

export function senderIdOf(message: { sender?: any } | null | undefined): string {
  return message ? idOf(message.sender) : "";
}

/** Same object when nothing needed fixing, so memoized bubbles keep their identity. */
export function normalizeMessage<T extends { sender?: any }>(message: T): T {
  if (!message) return message;
  const sender: any = message.sender;
  if (sender && typeof sender === "object") return message;
  return Object.assign({}, message, { sender: { _id: idOf(sender), name: "" } });
}
```

3c. `MessageBubble.tsx`:
- import under the other lib imports:
  ```tsx
  import { isEmojiOnly, isWaveText } from "./lib/messageKinds";
  ```
- replace `const isSticker = msg.messageType === "sticker";` with
  ```tsx
  // By content, like the app: a lone wave is a greeting card, 1-3 emoji are
  // sticker-sized, and a sentence stored as 'sticker' (the wave mirror does
  // that) is ordinary text.
  const isWave = !msg.media?.type && isWaveText(msg.message);
  const isSticker = !isWave && !msg.media?.type && isEmojiOnly(msg.message);
  ```
- the bubble class gains `${isWave ? " sticker-bubble wave-bubble" : ""}` (after the `isSticker` part), and the branch
  ```tsx
          ) : isSticker ? (
            <div className="sticker-message">{msg.message}</div>
  ```
  becomes
  ```tsx
          ) : isWave ? (
            <div className="wave-card" data-testid="wave-card">
              <span className="wave-card-hand" aria-hidden="true">{msg.message.trim()}</span>
              <span className="wave-card-text">{t("chatPage.wave.hi") || "Hi!"}</span>
            </div>
          ) : isSticker ? (
            <div className="sticker-message">{msg.message}</div>
  ```
- `isPlainText` gains `!isWave &&`; the chip-row condition gains `!isWave &&`.

3d. `ChatContent.tsx`:
- import under `import LocationShareButton …`:
  ```tsx
  import { normalizeMessage, senderIdOf } from "./lib/normalizeMessage";
  ```
- `handleNewMessage`: `const newMsg = notificationData.message;` → `const newMsg = normalizeMessage(notificationData.message);`
- `handleMediaMessage`: `const newMsg = data.message;` → `const newMsg = normalizeMessage(data.message);`
- `handleMessageSent`: first line of the handler body becomes
  ```tsx
      const sent = normalizeMessage(data.message);
  ```
  and every `data.message` inside the handler is replaced by `sent` (five places: the `some`, the `map` id check,
  the `pending` body compare, `next[pending] = { ...sent, status: "sent" }`, the append, and `rememberInThread(sent, …)`).
- `handleQueuedMessages`: `.map((entry) => entry?.message)` → `.map((entry) => (entry && entry.message ? normalizeMessage(entry.message) : undefined))`
- render map: `const isSent = msg.sender._id === userId;` → `const isSent = senderIdOf(msg) === userId;`

3e. Append to `ChatContent.css`:
```css
/* Wave greeting card (chat#8): the app's "👋 Hi!" card. */
.wave-card {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background: var(--chat-card-in);
  border: 1px solid var(--chat-line);
  border-radius: 20px;
}

.modern-message.sent .wave-card {
  background: var(--chat-card-out);
  border-color: var(--chat-card-out);
}

.wave-card-hand {
  font-size: 40px;
  line-height: 1;
}

.wave-card-text {
  font-size: 20px;
  font-weight: 700;
  color: var(--chat-accent);
}
```
(The comment's emoji is in a stylesheet, which `chatStyling.test.ts` does not scan; drop it if a reviewer prefers.)

3f. `eng.json` `chatPage`: `"wave": { "hi": "Hi!" }`.

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false messageKinds normalizeMessage MessageBubble ChatContent chatStyling chatTokens
```

- [ ] **Step 5: Commit**

```bash
git add src/components/chat/lib/messageKinds.ts src/components/chat/lib/messageKinds.test.ts \
  src/components/chat/lib/normalizeMessage.ts src/components/chat/lib/normalizeMessage.test.ts \
  src/components/chat/MessageBubble.tsx src/components/chat/MessageBubble.test.tsx \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.pagination.test.tsx \
  src/components/chat/ChatContent.css src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): size waves and stickers by content; bare-id senders land on the right side

The wave mirror stores the wave text (often a sentence) as 'sticker', and
the web drew every sticker at 5rem. Like the app, a lone wave hand is now a
greeting card, 1-3 emoji are sticker-sized, and everything else is text.
Wave and story_share socket payloads carry a bare sender id until backend
P1-CHAT-5 is live (and in old rows); they are normalized on arrival, so a
wave the web user sent no longer shows as received.

Still open (Phase 3 chat): story shares, pinned/edited/forwarded, premium
wallpapers, search, bookmarks, archive + mute durations, blocked banner,
i18n sweep.
EOF
```

---

### Task P3-CHAT-13: Story shares, replies and reactions keep their story (chat#9)

**Files:**
- Create: `src/components/chat/components/StoryReferenceCard.tsx`, `src/components/chat/lib/useOpenStoryFromChat.ts`
- Modify: `src/components/chat/MessageBubble.tsx` (`Message` :59-84, props :142-167, bubble body :385-440)
- Modify: `src/components/chat/ChatContent.tsx` (hook + `onOpenStory` prop on `<MessageBubble>`)
- Modify: `src/components/chat/ChatContent.css`, `src/components/chat/chatStyling.test.ts`, `src/utils/locales/eng.json`
- Test: `src/components/chat/lib/useOpenStoryFromChat.test.tsx` (new), `src/components/chat/MessageBubble.test.tsx` (append)

**Interfaces:**
- Consumes: backend stores `storyReference:{storyId, thumbnail}` (thumbnail = `story.mediaUrls[0] || story.mediaUrl || null`,
  so **null for text stories**) on story reactions (`controllers/stories.js:1009-1018`, `messageType:'text'`, message = the
  emoji), story replies (`:1176-1184`, `messageType:'text'`, message = reply text) and shares
  (`:1474-1483`, `messageType:'story_share'`, message = English "Shared a story"). No author id is stored. `GET
  /api/v1/stories/:id` (`storiesSlice.getIndividualStory`) answers `{data: <story with user populated>}`, 404 when expired
  (24 h) or gone, 403 when the viewer may not see it.
- Produces: `MessageBubbleProps.onOpenStory?: (storyId: string) => void`. Opening goes to `/stories/<authorId>` today.
  **Cross-unit:** once the LINKS unit's `/story/:id` route is live, change `useOpenStoryFromChat` to
  `navigate(\`/story/${storyId}\`)` with no fetch (tracked as an open item in the commit body).

- [ ] **Step 1: Write the failing tests**

`src/components/chat/lib/useOpenStoryFromChat.test.tsx`:

```tsx
import React from "react";
import { renderHook, act, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "../../../store/slices/apiSlice";
import { useOpenStoryFromChat, storyOwnerId } from "./useOpenStoryFromChat";

const mockNavigate = jest.fn();
const mockInfo = jest.fn();

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { info: (m: string) => mockInfo(m), error: jest.fn(), success: jest.fn() },
}));

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: { user: { _id: "me" }, token: "t" } }) => state,
    },
    middleware: (gdm) => gdm().concat(apiSlice.middleware),
  });
}

function answer(status: number, body: any) {
  (global as any).fetch = jest.fn(async () =>
    new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } })
  );
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.clearAllMocks();
});

function setup() {
  const store = makeStore();
  const wrapper: React.FC<{ children?: React.ReactNode }> = ({ children }) => (
    <Provider store={store}>{children}</Provider>
  );
  return renderHook(() => useOpenStoryFromChat(), { wrapper });
}

describe("storyOwnerId", () => {
  it("reads a populated or bare user", () => {
    expect(storyOwnerId({ data: { user: { _id: "u9" } } })).toBe("u9");
    expect(storyOwnerId({ data: { user: "u9" } })).toBe("u9");
    expect(storyOwnerId({ data: {} })).toBe("");
  });
});

it("opens the author's stories when the story is still live", async () => {
  answer(200, { success: true, data: { _id: "s1", user: { _id: "u9", name: "Ada" } } });
  const { result } = setup();
  act(() => result.current("s1"));
  await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/stories/u9"));
});

it("says the story is gone when the server says 404", async () => {
  answer(404, { success: false, error: "Story is no longer available" });
  const { result } = setup();
  act(() => result.current("s1"));
  await waitFor(() => expect(mockInfo).toHaveBeenCalledWith("This story is no longer available"));
  expect(mockNavigate).not.toHaveBeenCalled();
});

it("does nothing without a story id", () => {
  (global as any).fetch = jest.fn();
  const { result } = setup();
  act(() => result.current(""));
  expect((global as any).fetch).not.toHaveBeenCalled();
});
```

Append to `MessageBubble.test.tsx`:

```tsx
describe("story shares, replies and reactions (chat#9)", () => {
  it("draws a story card for a story_share and hides the server's English text", () => {
    const onOpenStory = jest.fn();
    renderBubble({
      message: message({
        messageType: "story_share",
        message: "Shared a story",
        storyReference: { storyId: "s1", thumbnail: "https://cdn.example/s1.jpg" },
        sender: { _id: "u2", name: "Ada" },
      } as any),
      isSent: false,
      onOpenStory,
    });
    const card = screen.getByTestId("story-ref");
    expect(card).toHaveTextContent("Shared a story");
    expect(document.querySelectorAll(".message-text")).toHaveLength(0);
    expect((card.querySelector("img") as HTMLImageElement).src).toBe("https://cdn.example/s1.jpg");
    fireEvent.click(card);
    expect(onOpenStory).toHaveBeenCalledWith("s1");
  });

  it("puts the story above a reply's text", () => {
    renderBubble({
      message: message({
        message: "Love this!",
        storyReference: { storyId: "s1", thumbnail: null },
        sender: { _id: "u2", name: "Ada" },
      } as any),
      isSent: false,
    });
    expect(screen.getByTestId("story-ref")).toHaveTextContent("Replied to your story");
    expect(document.querySelector(".message-text")).toHaveTextContent("Love this!");
  });

  it("keeps the story above an emoji reaction drawn as a sticker", () => {
    renderBubble({
      message: message({ message: "\u{1F525}", storyReference: { storyId: "s1", thumbnail: null } } as any),
    });
    expect(screen.getByTestId("story-ref")).toHaveTextContent("You replied to their story");
    expect(document.querySelector(".sticker-message")).not.toBeNull();
  });

  it("draws a placeholder when a text story has no thumbnail", () => {
    renderBubble({
      message: message({ message: "hi", storyReference: { storyId: "s1", thumbnail: null } } as any),
    });
    expect(screen.getByTestId("story-ref").querySelector("img")).toBeNull();
  });

  it("does not offer to open a story_share that lost its reference", () => {
    renderBubble({ message: message({ messageType: "story_share", message: "Shared a story" } as any), onOpenStory: jest.fn() });
    expect(screen.getByTestId("story-ref")).toBeDisabled();
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false useOpenStoryFromChat MessageBubble
```
Expected: the hook suite cannot find its module; the bubble cases find no `story-ref`.

- [ ] **Step 3: Implement**

3a. Create `src/components/chat/lib/useOpenStoryFromChat.ts`:
```ts
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { storiesApiSlice } from "../../../store/slices/storiesSlice";
import notify from "../../../design/notify";

/** The author of a GET /stories/:id answer, populated or not. */
export function storyOwnerId(response: any): string {
  const story = response && (response.data || response);
  const user = story && story.user;
  if (!user) return "";
  return typeof user === "string" ? user : user._id ? String(user._id) : "";
}

/**
 * Open the story a chat message points at. The message stores only
 * {storyId, thumbnail}, and the website shows stories by author
 * (/stories/:userId), so the story is read first: that also tells an
 * expired story (404 after 24 h) or a hidden one (403) apart from a live one.
 *
 * When the LINKS unit's /story/:id route is live, this becomes a plain
 * navigate(`/story/${storyId}`).
 */
export function useOpenStoryFromChat(): (storyId: string) => void {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { t } = useTranslation();

  return useCallback(
    (storyId: string) => {
      if (!storyId) return;
      const request: any = dispatch(
        (storiesApiSlice.endpoints as any).getIndividualStory.initiate(storyId, {
          subscribe: false,
          forceRefetch: true,
        }) as any
      );
      request
        .unwrap()
        .then((response: any) => {
          const owner = storyOwnerId(response);
          if (owner) navigate(`/stories/${owner}`);
          else notify.info(t("chatPage.story.unavailable") || "This story is no longer available");
        })
        .catch(() => {
          notify.info(t("chatPage.story.unavailable") || "This story is no longer available");
        });
    },
    [dispatch, navigate, t]
  );
}

export default useOpenStoryFromChat;
```

3b. Create `src/components/chat/components/StoryReferenceCard.tsx`:
```tsx
import React, { useState } from "react";
import { Image as ImageIcon } from "lucide-react";

interface StoryReferenceCardProps {
  storyId: string;
  thumbnail?: string | null;
  label: string;
  onOpen?: (storyId: string) => void;
}

/**
 * The story a message is about (a share, a reply, a reaction), drawn above
 * the message the way the app's story reference preview is: thumbnail (a
 * placeholder for a text story, which has none) and what happened.
 */
const StoryReferenceCard: React.FC<StoryReferenceCardProps> = ({ storyId, thumbnail, label, onOpen }) => {
  const [broken, setBroken] = useState(false);
  const showThumbnail = !!thumbnail && !broken;
  return (
    <button
      type="button"
      className="story-ref"
      data-testid="story-ref"
      disabled={!storyId || !onOpen}
      onClick={(e) => {
        e.stopPropagation();
        if (storyId && onOpen) onOpen(storyId);
      }}
    >
      <span className="story-ref-thumb">
        {showThumbnail ? (
          <img
            src={thumbnail as string}
            alt=""
            loading="lazy"
            decoding="async"
            onError={() => setBroken(true)}
          />
        ) : (
          <ImageIcon size={18} aria-hidden="true" />
        )}
      </span>
      <span className="story-ref-label">{label}</span>
    </button>
  );
};

export default StoryReferenceCard;
```

3c. `MessageBubble.tsx`:
- import: `import StoryReferenceCard from "./components/StoryReferenceCard";`
- `interface Message`: after `pinned?: boolean;` add
  ```tsx
  /** Set on story replies, reactions and shares (backend controllers/stories.js). */
  storyReference?: { storyId?: string | null; thumbnail?: string | null } | null;
  ```
- `MessageBubbleProps`: after `onRetry: (message: Message) => void;` add
  ```tsx
  /** Opens the story a share/reply/reaction points at. */
  onOpenStory?: (storyId: string) => void;
  ```
  and destructure `onOpenStory,` after `onRetry,`.
- after the `isLocation`/`hasMedia` flags add:
  ```tsx
  const isStoryShare = msg.messageType === "story_share";
  const storyId = (msg.storyReference && msg.storyReference.storyId) || "";
  const showStoryRef = isStoryShare || !!storyId;
  const storyLabel = isStoryShare
    ? isSent
      ? t("chatPage.story.youShared") || "You shared a story"
      : t("chatPage.story.shared") || "Shared a story"
    : isSent
    ? t("chatPage.story.youReplied") || "You replied to their story"
    : t("chatPage.story.replied") || "Replied to your story";
  ```
- directly inside the bubble `<div className={`message-bubble…`}>`, **before** `{isCall ? (`, add
  ```tsx
          {showStoryRef && (
            <StoryReferenceCard
              storyId={String(storyId)}
              thumbnail={msg.storyReference && msg.storyReference.thumbnail}
              label={storyLabel}
              onOpen={onOpenStory}
            />
          )}
  ```
- the text paragraph `{msg.message && !isVoice && (` becomes `{msg.message && !isVoice && !isStoryShare && (`;
  `isPlainText` gains `&& !isStoryShare`.

3d. `ChatContent.tsx`:
- import: `import { useOpenStoryFromChat } from "./lib/useOpenStoryFromChat";`
- after `const { socket, emit } = useSocket();` add `const openStory = useOpenStoryFromChat();`
- on `<MessageBubble …>` after `onRetry={handleRetry}` add `onOpenStory={openStory}`.

3e. Append to `ChatContent.css`:
```css
/* Story reference (chat#9) — above a share, reply or reaction. */
.story-ref {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  margin-block-end: 6px;
  padding: 6px;
  background: var(--chat-card-in);
  border: 1px solid var(--chat-line);
  border-radius: 10px;
  color: inherit;
  text-align: start;
  cursor: pointer;
}

.modern-message.sent .story-ref {
  background: var(--chat-card-out);
  border-color: var(--chat-card-out);
}

.story-ref:disabled {
  cursor: default;
}

.story-ref-thumb {
  display: flex;
  flex: none;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  overflow: hidden;
  border-radius: 8px;
  background: var(--chat-surface);
  color: var(--chat-muted);
}

.story-ref-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.story-ref-label {
  font-size: 12px;
  color: var(--chat-muted);
}
```

3f. `STRICT_FILES` += `"components/StoryReferenceCard.tsx",`.

3g. `eng.json` `chatPage`:
```json
"story": {
  "shared": "Shared a story",
  "youShared": "You shared a story",
  "replied": "Replied to your story",
  "youReplied": "You replied to their story",
  "unavailable": "This story is no longer available"
}
```

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false useOpenStoryFromChat MessageBubble ChatContent chatStyling chatTokens
```

- [ ] **Step 5: Commit**

```bash
git add src/components/chat/lib/useOpenStoryFromChat.ts src/components/chat/lib/useOpenStoryFromChat.test.tsx \
  src/components/chat/components/StoryReferenceCard.tsx src/components/chat/MessageBubble.tsx \
  src/components/chat/MessageBubble.test.tsx src/components/chat/ChatContent.tsx src/components/chat/ChatContent.css \
  src/components/chat/chatStyling.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(chat): story shares, replies and reactions show the story they are about

Messages carrying storyReference {storyId, thumbnail} (replies, reactions)
and story_share messages rendered as bare text ("Shared a story" in English
for every locale). They now show a story card above the message, a
placeholder for text stories, and open the story: the story is read first so
an expired one says so instead of opening an empty viewer.

Still open (Phase 3 chat): pinned/edited/forwarded, premium wallpapers,
search, bookmarks, archive + mute durations, blocked banner, i18n sweep.
Switch useOpenStoryFromChat to /story/:id once the LINKS unit's route is live.
EOF
```

---

### Task P3-CHAT-14: Live pins, the "edited" label, the "Forwarded" chip and every correction (chat#14)

**Files:**
- Modify: `src/components/chat/ChatContent.tsx` (new `handleMessagePinned` beside `handleMessageReaction` :622-637; `socket.on/off` :665-700)
- Modify: `src/store/slices/chatSlice.ts` (wrong comment :311-313 above `pinMessage`)
- Modify: `src/components/chat/MessageBubble.tsx` (`Message`, bubble body, meta :442-445, corrections :470-479)
- Modify: `src/components/chat/ChatContent.css`, `src/utils/locales/eng.json`
- Test: `src/components/chat/MessageBubble.test.tsx` (append), `src/components/chat/ChatContent.pagination.test.tsx` (append)

**Interfaces:**
- Consumes: backend `controllers/messageManagement.js:504-508` emits `messagePinned {messageId, pinned, pinnedBy}` to the
  **other** participant only (whichever thread they have open); pinning a new message unpins every other pinned message
  of the pair (`:455-476`). `isEdited`/`editedAt`, `isForwarded`/`forwardedFrom{sender, messageId, originalMessage}` and
  `corrections[]` are on every thread message (2.6.1 rows included; absent = false/empty).
- Produces: nothing new for other tasks.

- [ ] **Step 1: Write the failing tests**

Append to `MessageBubble.test.tsx`:

```tsx
describe("edited, forwarded and corrections (chat#14)", () => {
  it("labels an edited message", () => {
    renderBubble({ message: message({ isEdited: true }) });
    expect(screen.getByTestId("message-edited")).toHaveTextContent("edited");
  });

  it("says nothing on a message that was never edited", () => {
    renderBubble();
    expect(screen.queryByTestId("message-edited")).toBeNull();
  });

  it("marks a forwarded message", () => {
    renderBubble({ message: message({ isForwarded: true } as any) });
    expect(screen.getByTestId("message-forwarded")).toHaveTextContent("Forwarded");
  });

  it("shows every correction, not only the first", () => {
    renderBubble({
      message: message({
        sender: { _id: "u2", name: "Ada" },
        corrections: [
          { _id: "c1", originalText: "I goed", correctedText: "I went", corrector: { _id: "me", name: "Me" } },
          { _id: "c2", originalText: "I goed", correctedText: "I have gone", corrector: { _id: "u3", name: "Bo" } },
        ],
      } as any),
      isSent: false,
    });
    expect(screen.getByText("I went")).toBeInTheDocument();
    expect(screen.getByText("I have gone")).toBeInTheDocument();
  });
});
```

Append to `ChatContent.pagination.test.tsx`:

```tsx
// --- messagePinned (chat#14) -------------------------------------------------
//
// The backend emits messagePinned to the other participant; the web never
// listened (a comment even said the server does not emit it), so a pin made
// in the app only appeared on web after a reload.

it("shows a pin the other person made, live", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  await waitFor(() => expect(renderedIds()).toContain("newer-b"));
  expect(screen.queryByTestId("pinned-bar")).toBeNull();

  socket.fire("messagePinned", { messageId: "newer-b", pinned: true, pinnedBy: "u2" });

  expect(await screen.findByTestId("pinned-bar")).toHaveTextContent("newer-b");
  expect(mockUpdateQueryData).toHaveBeenCalledWith(
    "getConversation",
    expect.objectContaining({ senderId: "me", receiverId: "u2" }),
    expect.any(Function)
  );
});

it("unpins the old message when a new one is pinned, as the server does", async () => {
  answerWith({
    page1: [
      { ...PAGE_1[0], pinned: true },
      PAGE_1[1],
    ],
  });
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  expect(await screen.findByTestId("pinned-bar")).toHaveTextContent("newer-a");

  socket.fire("messagePinned", { messageId: "newer-b", pinned: true, pinnedBy: "u2" });

  await waitFor(() => expect(screen.getByTestId("pinned-bar")).toHaveTextContent("newer-b"));
  expect(screen.getByTestId("pinned-bar")).not.toHaveTextContent("newer-a");
});

it("ignores a pin from a conversation that is not open", async () => {
  answerWith({ page1: [{ ...PAGE_1[0], pinned: true }, PAGE_1[1]] });
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  expect(await screen.findByTestId("pinned-bar")).toHaveTextContent("newer-a");

  socket.fire("messagePinned", { messageId: "elsewhere", pinned: true, pinnedBy: "u7" });

  expect(screen.getByTestId("pinned-bar")).toHaveTextContent("newer-a");
});

it("clears the bar when the pin is removed", async () => {
  answerWith({ page1: [{ ...PAGE_1[0], pinned: true }, PAGE_1[1]] });
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  expect(await screen.findByTestId("pinned-bar")).toBeInTheDocument();

  socket.fire("messagePinned", { messageId: "newer-a", pinned: false, pinnedBy: "u2" });

  await waitFor(() => expect(screen.queryByTestId("pinned-bar")).toBeNull());
});
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false MessageBubble ChatContent.pagination
```
Expected: no `message-edited` / `message-forwarded`; "I have gone" not found; the three live-pin cases fail (the bar
never changes). "ignores a pin from a conversation that is not open" passes already — it guards Step 3.

- [ ] **Step 3: Implement**

3a. `ChatContent.tsx` — after `handleMessageReaction` (ends `selectedUserRef.current\n      );\n    };`) add:
```tsx
    // The other participant pinned or unpinned a message (messageManagement.js
    // pinMessage). The server keeps ONE pinned message per pair, so a new pin
    // unpins the rest — but only for the conversation this pin belongs to: the
    // event reaches us whatever thread is open.
    const handleMessagePinned = (data: { messageId: string; pinned: boolean }) => {
      if (!data || !data.messageId) return;
      const id = String(data.messageId);
      const pinned = Boolean(data.pinned);
      const repin = (list: any[]): any[] =>
        list.map((m: any) => {
          if (!m) return m;
          if (m._id === id) return m.pinned === pinned ? m : { ...m, pinned: pinned };
          if (pinned && m.pinned) return { ...m, pinned: false };
          return m;
        });
      setMessages((prev) => (prev.some((m) => m._id === id) ? (repin(prev) as Message[]) : prev));
      // The same change in the thread cache, so a conversation switch does not
      // bring the old pin back. One updater for the target AND the unpinned
      // rest; a thread that does not hold the id is left alone.
      if (userId && selectedUserRef.current) {
        dispatch(
          (chatApiSlice.util as any).updateQueryData(
            "getConversation",
            { senderId: userId, receiverId: selectedUserRef.current, page: 1, limit: MESSAGE_PAGE_SIZE },
            (draft: any) => {
              if (!draft || !Array.isArray(draft.data)) return;
              if (!draft.data.some((m: any) => m && m._id === id)) return;
              draft.data = repin(draft.data);
            }
          )
        );
      }
    };
```
Register beside the others: after `socket.on("messageReaction", handleMessageReaction);` add
`socket.on("messagePinned", handleMessagePinned);` and after `socket.off("messageReaction", handleMessageReaction);` add
`socket.off("messagePinned", handleMessagePinned);`. Add `dispatch` to that effect's dependency array
(`[socket, userId, rememberInThread, forgetFromThread, patchInThread]` → `[socket, userId, dispatch, rememberInThread, forgetFromThread, patchInThread]`;
`dispatch` is stable, so this never re-subscribes).

(The local update and the cache update are computed independently from their own lists — no value is carried out of
the `setMessages` updater, which React 18 runs lazily outside event handlers.)

3b. `chatSlice.ts` — replace
```ts
    // Pin (toggle) — POST /api/v1/messages/:id/pin, no body. Server does NOT
    // emit this over socket, so invalidate the conversation/list tags so the
    // UI refetches the pinned state.
```
with
```ts
    // Pin (toggle) — POST /api/v1/messages/:id/pin, no body. The server emits
    // `messagePinned` to the OTHER participant only (ChatContent listens), so
    // our own pin still refetches the thread to pick up the new state.
```

3c. `MessageBubble.tsx`:
- import `CornerUpRight` from `lucide-react` (add to the existing import list).
- `interface Message`: after `editedAt?: string;` add
  ```tsx
  isForwarded?: boolean;
  forwardedFrom?: { sender?: string; messageId?: string; originalMessage?: string };
  ```
- in the non-sticker branch, first child of the `<>` fragment (before `{renderMediaContent()}`):
  ```tsx
              {msg.isForwarded && (
                <span className="message-forwarded" data-testid="message-forwarded">
                  <CornerUpRight size={12} aria-hidden="true" />
                  {t("chatPage.forwarded") || "Forwarded"}
                </span>
              )}
  ```
- meta row: replace
  ```tsx
          <div className="message-meta">
            <span className="message-time">{timeLabel}</span>
  ```
  with
  ```tsx
          <div className="message-meta">
            {msg.isEdited && (
              <span className="message-edited" data-testid="message-edited">
                {t("chatPage.editedLabel") || "edited"}
              </span>
            )}
            <span className="message-time">{timeLabel}</span>
  ```
- corrections: replace
  ```tsx
        {msg.corrections && msg.corrections.length > 0 && (
          <CorrectionCard
            messageId={msg._id}
            correction={msg.corrections[0]}
            isMe={isSent}
            currentUserId={currentUserId || ""}
            otherUserName={otherUserName}
            onAccepted={(correctionId) => onCorrectionAccepted(msg._id, correctionId)}
          />
        )}
  ```
  with
  ```tsx
        {msg.corrections &&
          msg.corrections.map((correction) => (
            <CorrectionCard
              key={correction._id}
              messageId={msg._id}
              correction={correction}
              isMe={isSent}
              currentUserId={currentUserId || ""}
              otherUserName={otherUserName}
              onAccepted={(correctionId) => onCorrectionAccepted(msg._id, correctionId)}
            />
          ))}
  ```

3d. Append to `ChatContent.css`:
```css
/* Forwarded chip and edited label (chat#14) */
.message-forwarded {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin-block-end: 4px;
  font-size: 11px;
  font-style: italic;
  color: var(--chat-muted);
}

.modern-message.sent .message-forwarded,
.modern-message.sent .message-edited {
  color: var(--chat-bubble-out-text);
  opacity: 0.8;
}

.message-edited {
  margin-inline-end: 4px;
  font-size: 11px;
  font-style: italic;
  color: var(--chat-muted);
}
```

3e. `eng.json` `chatPage`: `"forwarded": "Forwarded"`, `"editedLabel": "edited"`.

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false MessageBubble ChatContent chatActionsEndpoints chatTokens
```

- [ ] **Step 5: Commit**

```bash
git add src/components/chat/ChatContent.tsx src/components/chat/ChatContent.pagination.test.tsx \
  src/store/slices/chatSlice.ts src/components/chat/MessageBubble.tsx src/components/chat/MessageBubble.test.tsx \
  src/components/chat/ChatContent.css src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(chat): live pins, edited label, forwarded chip, all corrections

The backend emits messagePinned to the other participant; the web never
listened, so a pin made in the app appeared only after a reload. Pins now
apply live (and unpin the previous one, as the server does), scoped to the
open conversation. Bubbles show "edited" and "Forwarded" like the app, and
every correction instead of only the first.

Still open (Phase 3 chat): premium wallpapers, search, bookmarks, archive +
mute durations, blocked banner, i18n sweep.
EOF
```

---

### Task P3-CHAT-15: The app's six premium wallpapers render on web (chat#18)

**Files:**
- Modify: `src/design/chatWallpapers.ts` (after `CHAT_WALLPAPERS` :78-80), `src/index.css` (after the gradient rules :399-410)
- Modify: `src/components/chat/WallpaperPicker.tsx` (hint under the preview), `src/utils/locales/eng.json`
- Test: `src/components/chat/chatTokens.test.ts` (premium block), `src/components/chat/WallpaperPicker.test.tsx` (append)

**Interfaces:**
- Consumes: app `lib/pages/chat/wallpaper/premium_wallpapers.dart:47-71` — names and colours below, drawn
  `Alignment.topLeft → bottomRight` (= CSS `135deg`); gated in the app by the coin catalog key `wallpaper`
  (`unlocks.wallpaper >= 1` unlocks the whole pack). The backend stores `conversation.theme.preset` as a free string and
  pushes it via `themeChanged`; the web paints `[data-chat-theme="<preset>"]` rules.
- Decision: **render-only on web.** The web sells no coin unlock and has no unlock state, so the picker keeps offering
  only the free presets (its existing "ships no coin-gated premium preset" test stays). A conversation an app user set to a
  premium preset now shows it instead of the default surface; an unknown future `premium_*` name gets a generic premium
  gradient. Choosing a free preset on web replaces it for both people, and the picker says so.
- Produces: `PREMIUM_WALLPAPERS`, `isPremiumWallpaper(name)`.

- [ ] **Step 1: Write the failing tests**

In `chatTokens.test.ts`, change the import to
`import { CHAT_WALLPAPERS, PREMIUM_WALLPAPERS } from "../../design/chatWallpapers";`, and in
`describe("the wallpaper presets the picker offers are the ones the CSS can paint", …)` replace
```ts
  it("offers no coin-gated premium preset", () => {
    const premium = CHAT_WALLPAPERS.filter(
      (wallpaper) => wallpaper.name.indexOf("premium") !== -1
    );
    expect(premium).toEqual([]);
    expect(indexCss).not.toContain('[data-chat-theme="premium');
  });
```
with
```ts
  it("offers no coin-gated premium preset in the picker", () => {
    const premium = CHAT_WALLPAPERS.filter(
      (wallpaper) => wallpaper.name.indexOf("premium") !== -1
    );
    expect(premium).toEqual([]);
  });
```
and add after that `describe` block:
```ts
describe("the app's premium pack renders, though the picker does not offer it (chat#18)", () => {
  it("is exactly the app's six presets", () => {
    expect(PREMIUM_WALLPAPERS.map((w) => w.name).sort()).toEqual([
      "premium_aurora_borealis",
      "premium_diamond_shine",
      "premium_emerald_luxe",
      "premium_galaxy",
      "premium_golden_hour",
      "premium_royal_velvet",
    ]);
  });

  PREMIUM_WALLPAPERS.forEach((wallpaper) => {
    it(`${wallpaper.name} has a [data-chat-theme] rule with the app's colours`, () => {
      const rule = new RegExp(`\\[data-chat-theme="${wallpaper.name}"\\]\\s*\\{[^}]*--chat-bg:[^}]*\\}`);
      const match = indexCss.match(rule);
      expect(match).not.toBeNull();
      (wallpaper.gradientColors as string[]).forEach((colour) => {
        expect((match as RegExpMatchArray)[0]).toContain(colour);
      });
    });
  });

  it("paints an unknown premium_* preset with a premium gradient, not the default surface", () => {
    expect(indexCss).toMatch(/\[data-chat-theme\^="premium_"\]\s*\{[^}]*--chat-bg:\s*linear-gradient/);
  });

  it("declares the prefix rule BEFORE the named rules, so the named ones win", () => {
    expect(indexCss.indexOf('[data-chat-theme^="premium_"]')).toBeLessThan(
      indexCss.indexOf('[data-chat-theme="premium_aurora_borealis"]')
    );
  });
});
```

Append to `WallpaperPicker.test.tsx` (inside `describe("WallpaperPicker", …)`):
```tsx
  it("says when the chat wears a Premium wallpaper chosen in the app", () => {
    renderPicker({ currentPreset: "premium_galaxy" });
    expect(screen.getByTestId("wallpaper-premium-hint")).toHaveTextContent("Premium wallpaper");
    expect(screen.getByTestId("wallpaper-preview")).toHaveAttribute("data-chat-theme", "premium_galaxy");
  });

  it("says nothing about premium for a free preset", () => {
    renderPicker({ currentPreset: "navy" });
    expect(screen.queryByTestId("wallpaper-premium-hint")).toBeNull();
  });
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatTokens WallpaperPicker
```
Expected: `PREMIUM_WALLPAPERS` is undefined (`Cannot read properties of undefined (reading 'map')`); no premium rules in
`index.css`; no `wallpaper-premium-hint`.

- [ ] **Step 3: Implement**

3a. `src/design/chatWallpapers.ts` — update the header comment's sentence "The coin-gated `premium_*` pack … falls back to
the default surface." to "The coin-gated `premium_*` pack is RENDER-ONLY here (PREMIUM_WALLPAPERS below): the web sells
no unlock, so the picker does not offer it, but a chat an app user dressed in one paints it." Then after
`export const CHAT_WALLPAPERS …;` add:
```ts
export const PREMIUM_WALLPAPER_PREFIX = "premium_";

/**
 * The app's coin-unlocked Premium pack (lib/pages/chat/wallpaper/
 * premium_wallpapers.dart), colours verbatim, drawn top-left to bottom-right.
 * Not offered by the picker; painted when a conversation already wears one.
 */
export const PREMIUM_WALLPAPERS: ChatWallpaper[] = [
  { name: "premium_aurora_borealis", label: "Aurora Borealis", gradientColors: ["#00c9ff", "#92fe9d", "#fc466b"] },
  { name: "premium_golden_hour", label: "Golden Hour", gradientColors: ["#ffd700", "#ff8c00", "#ff4500"] },
  { name: "premium_galaxy", label: "Galaxy", gradientColors: ["#0f0c29", "#302b63", "#24243e"] },
  { name: "premium_emerald_luxe", label: "Emerald Luxe", gradientColors: ["#11998e", "#38ef7d"] },
  { name: "premium_royal_velvet", label: "Royal Velvet", gradientColors: ["#360033", "#0b8793"] },
  { name: "premium_diamond_shine", label: "Diamond Shine", gradientColors: ["#b993d6", "#8ca6db"] },
];

export function isPremiumWallpaper(name: string | null | undefined): boolean {
  return typeof name === "string" && name.indexOf(PREMIUM_WALLPAPER_PREFIX) === 0;
}
```

3b. `src/index.css` — update the comment block above the solid grounds ("The coin-gated `premium_*` pack is
deliberately not implemented -- an unknown preset name matches no rule …") to say the pack is render-only and listed in
`PREMIUM_WALLPAPERS`. After `[data-chat-theme="gradient_lavender"] { … }` add:
```css
/* Premium pack (render only -- src/design/chatWallpapers.ts PREMIUM_WALLPAPERS).
   The prefix rule comes first: a premium preset this build does not know yet
   still reads as premium; the named rules below override it. */
[data-chat-theme^="premium_"] { --chat-bg: linear-gradient(135deg, #302b63 0%, #b993d6 100%); }
[data-chat-theme="premium_aurora_borealis"] { --chat-bg: linear-gradient(135deg, #00c9ff 0%, #92fe9d 50%, #fc466b 100%); }
[data-chat-theme="premium_golden_hour"] { --chat-bg: linear-gradient(135deg, #ffd700 0%, #ff8c00 50%, #ff4500 100%); }
[data-chat-theme="premium_galaxy"] { --chat-bg: linear-gradient(135deg, #0f0c29 0%, #302b63 50%, #24243e 100%); }
[data-chat-theme="premium_emerald_luxe"] { --chat-bg: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); }
[data-chat-theme="premium_royal_velvet"] { --chat-bg: linear-gradient(135deg, #360033 0%, #0b8793 100%); }
[data-chat-theme="premium_diamond_shine"] { --chat-bg: linear-gradient(135deg, #b993d6 0%, #8ca6db 100%); }
```

3c. `WallpaperPicker.tsx` — add `isPremiumWallpaper` to the existing `../../design/chatWallpapers` import, and directly
after the preview `<div data-testid="wallpaper-preview" … />` add:
```tsx
      {isPremiumWallpaper(currentPreset) ? (
        <p
          data-testid="wallpaper-premium-hint"
          className="pt-2 text-xs text-ink-500 dark:text-ink-400"
        >
          {t("chatPage.wallpaper.premiumInUse") ||
            "This chat uses a Premium wallpaper from the app. Choosing another one changes it for both of you."}
        </p>
      ) : null}
```

3d. `eng.json` `chatPage.wallpaper`: add
`"premiumInUse": "This chat uses a Premium wallpaper from the app. Choosing another one changes it for both of you."`

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatTokens WallpaperPicker ChatInfoPanel
```

- [ ] **Step 5: Commit**

```bash
git add src/design/chatWallpapers.ts src/index.css src/components/chat/WallpaperPicker.tsx \
  src/components/chat/chatTokens.test.ts src/components/chat/WallpaperPicker.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(chat): paint the app's premium wallpapers on web

A conversation an app user dressed in one of the six coin-unlocked
premium_* wallpapers fell back to the default surface on web. Their
gradients are now painted (colours verbatim from the app), with a generic
premium gradient for any future premium_* name. The web picker still offers
only the free presets, since the web has no coin unlock, and says when the
chat already wears a premium one.

Still open (Phase 3 chat): search, bookmarks, archive + mute durations,
blocked banner, i18n sweep.
EOF
```

---

### Task P3-CHAT-16: Search the messages of a conversation (chat#17)

**Files:**
- Create: `src/components/chat/components/MessageSearchDialog.tsx`
- Modify: `src/components/chat/ChatContent.tsx` (header action :1931-1946, dialog mount, jump handler next to `handleJumpToMessage` :1708-1711)
- Modify: `src/components/chat/ChatContent.css`, `src/components/chat/chatStyling.test.ts`, `src/utils/locales/eng.json`
- Modify: `src/components/chat/ChatContent.test.tsx`, `src/components/chat/ChatContent.pagination.test.tsx` (stub + cases)
- Test: `src/components/chat/components/MessageSearchDialog.test.tsx` (new)

**Interfaces:**
- Consumes: `GET /api/v1/messages/search?q&conversationId&page&limit` (`routes/messages.js:44`, `controllers/messageSearch.js`).
  `conversationId` is **the other user's id** (the controller looks it up as a User and narrows to the pair). Response
  `{success, count, total, pagination{currentPage,totalPages,limit,hasNextPage,hasPrevPage}, data:[message]}`, newest
  first, `sender`/`receiver` populated `{_id, name, images}`; deleted messages excluded; `searchLimiter` allows 20/min per
  user (hence the debounce). The existing unused `useSearchMessagesQuery({query, conversationId, page, limit})`
  (`chatSlice.ts:397-406`) builds exactly that URL.
  **Contract check before shipping:** the controller puts `$text` inside an `$or` with a regex on `media.fileName`;
  MongoDB refuses that unless every `$or` clause is indexed. Step 0 probes production; if it 500s, the dialog still
  ships (it shows "Search isn't available right now") and a backend item is filed.
- Produces: `ChatContent` jump-to-result: scrolls to and flashes a loaded message, or explains that it is further back.

- [ ] **Step 0: Probe the live contract (read-only)**

```bash
TOKEN=<a test account's JWT from the web app's localStorage userInfo.token>
PARTNER=<a user id that account has messages with>
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.banatalk.com/api/v1/messages/search?q=hello&conversationId=$PARTNER&limit=5" | head -c 600
```
Expected `{"success":true,…,"data":[…]}`. If the answer is a 500 mentioning `$or` / "indexed", add to the **backend**
repo's `docs/REMAINING_WORK.md`: "messages/search: `$text` inside `$or` with an unindexed regex → 500; drop the
`media.fileName` regex clause (fileName is already in the text index)". Note the outcome in this task's commit body.

- [ ] **Step 1: Write the failing tests**

`src/components/chat/components/MessageSearchDialog.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import MessageSearchDialog from "./MessageSearchDialog";

const mockSearch = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../../store/slices/chatSlice", () => ({
  useSearchMessagesQuery: (arg: any, opts: any) => mockSearch(arg, opts),
}));

const onClose = jest.fn();
const onJump = jest.fn();

function renderDialog() {
  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user: { _id: "me" }, token: "t" } }) => state },
  });
  return render(
    <Provider store={store}>
      <MessageSearchDialog partnerId="u2" partnerName="Ada" onClose={onClose} onJump={onJump} debounceMs={0} />
    </Provider>
  );
}

const lastArgs = () => mockSearch.mock.calls[mockSearch.mock.calls.length - 1];

beforeEach(() => {
  mockSearch.mockReturnValue({ data: undefined, isFetching: false, isError: false });
});
afterEach(() => jest.clearAllMocks());

it("does not search until two characters are typed", () => {
  renderDialog();
  expect(lastArgs()[1]).toEqual(expect.objectContaining({ skip: true }));
  expect(screen.getByText("Type at least 2 characters")).toBeInTheDocument();
});

it("searches this conversation only, by the other person's id", async () => {
  renderDialog();
  fireEvent.change(screen.getByTestId("chat-search-input"), { target: { value: "  market " } });
  await waitFor(() =>
    expect(lastArgs()).toEqual([
      { query: "market", conversationId: "u2", limit: 30 },
      expect.objectContaining({ skip: false }),
    ])
  );
});

it("lists results with who said it, and jumps to the one picked", async () => {
  mockSearch.mockReturnValue({
    data: {
      data: [
        { _id: "m1", message: "See you at the market", createdAt: "2026-09-20T10:00:00.000Z", sender: { _id: "u2", name: "Ada" } },
        { _id: "m2", message: "Which market?", createdAt: "2026-09-20T10:01:00.000Z", sender: "me" },
      ],
    },
    isFetching: false,
    isError: false,
  });
  renderDialog();
  fireEvent.change(screen.getByTestId("chat-search-input"), { target: { value: "market" } });

  const first = await screen.findByTestId("chat-search-result-m1");
  expect(first).toHaveTextContent("Ada");
  expect(first).toHaveTextContent("See you at the market");
  expect(screen.getByTestId("chat-search-result-m2")).toHaveTextContent("You");

  fireEvent.click(first);
  expect(onJump).toHaveBeenCalledWith("m1");
});

it("says when nothing matched", async () => {
  mockSearch.mockReturnValue({ data: { data: [] }, isFetching: false, isError: false });
  renderDialog();
  fireEvent.change(screen.getByTestId("chat-search-input"), { target: { value: "zebra" } });
  expect(await screen.findByText("No messages found")).toBeInTheDocument();
});

it("says when search itself failed (500, rate limit)", async () => {
  mockSearch.mockReturnValue({ data: undefined, isFetching: false, isError: true });
  renderDialog();
  fireEvent.change(screen.getByTestId("chat-search-input"), { target: { value: "zebra" } });
  expect(await screen.findByText("Search isn't available right now")).toBeInTheDocument();
});
```

Add to both `ChatContent.test.tsx` and `ChatContent.pagination.test.tsx`, next to the other stubs:
```tsx
// Owns its own query; its suite is components/MessageSearchDialog.test.tsx.
jest.mock("./components/MessageSearchDialog", () => ({
  __esModule: true,
  default: (props: any) =>
    require("react").createElement(
      "div",
      { "data-testid": "chat-search-dialog" },
      require("react").createElement("button", { "data-testid": "search-jump-loaded", onClick: () => props.onJump("newer-b") }),
      require("react").createElement("button", { "data-testid": "search-jump-missing", onClick: () => props.onJump("not-loaded") })
    ),
}));
```
`ChatContent.pagination.test.tsx` also mocks notify (top of file, beside the other `jest.mock` calls):
```tsx
const mockNotifyInfo = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { info: (m: string) => mockNotifyInfo(m), error: jest.fn(), success: jest.fn(), warning: jest.fn() },
}));
```

Append to `ChatContent.test.tsx`:
```tsx
it("opens message search from the header", () => {
  renderChat("/chat/u2");
  expect(screen.queryByTestId("chat-search-dialog")).toBeNull();
  fireEvent.click(screen.getByTestId("chat-header-search"));
  expect(screen.getByTestId("chat-search-dialog")).toBeInTheDocument();
});
```

Append to `ChatContent.pagination.test.tsx`:
```tsx
// --- Message search (chat#17) ------------------------------------------------

it("jumps to a search result that is on screen and flashes it", async () => {
  renderChat();
  await waitFor(() => expect(renderedIds()).toContain("newer-b"));
  fireEvent.click(screen.getByTestId("chat-header-search"));
  fireEvent.click(screen.getByTestId("search-jump-loaded"));

  const bubble = document.querySelector('[data-msg-id="newer-b"]') as HTMLElement;
  expect((Element.prototype as any).scrollIntoView).toHaveBeenCalled();
  expect(bubble).toHaveClass("modern-message--highlight");
  expect(screen.queryByTestId("chat-search-dialog")).toBeNull();
});

it("explains a result that is further back than what is loaded", async () => {
  renderChat();
  fireEvent.click(screen.getByTestId("chat-header-search"));
  fireEvent.click(screen.getByTestId("search-jump-missing"));
  expect(mockNotifyInfo).toHaveBeenCalledWith("That message is further back. Scroll up to load it.");
});
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false MessageSearchDialog ChatContent
```
Expected: the dialog suite cannot find its module; `chat-header-search` does not exist.

- [ ] **Step 3: Implement**

3a. Create `src/components/chat/components/MessageSearchDialog.tsx`:
```tsx
import React, { useEffect, useRef, useState } from "react";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { Search, X } from "lucide-react";
import DialogShell from "../../../design/DialogShell";
import { useSearchMessagesQuery } from "../../../store/slices/chatSlice";
import { senderIdOf } from "../lib/normalizeMessage";

interface MessageSearchDialogProps {
  /** The OTHER person: the search endpoint's `conversationId` is their user id. */
  partnerId: string;
  partnerName: string;
  onClose: () => void;
  onJump: (messageId: string) => void;
  /** Tests pass 0. The endpoint allows 20 searches a minute. */
  debounceMs?: number;
}

const MIN_CHARS = 2;
const RESULT_LIMIT = 30;

const FIELD = [
  "w-full rounded-card border border-line bg-surface py-2 ps-9 pe-3 text-sm",
  "text-ink-900 placeholder:text-ink-400",
  "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
].join(" ");
const STATUS = "px-1 py-6 text-center text-sm text-ink-500 dark:text-ink-400";

/** Search one conversation, newest first; picking a result jumps to it in the thread. */
const MessageSearchDialog: React.FC<MessageSearchDialogProps> = ({
  partnerId,
  partnerName,
  onClose,
  onJump,
  debounceMs = 350,
}) => {
  const { t, i18n } = useTranslation();
  const viewerId = useSelector((state: any) => state.auth.userInfo?.user?._id || "");
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [text, setText] = useState("");
  const [query, setQuery] = useState("");

  useEffect(() => {
    const trimmed = text.trim();
    const timer = setTimeout(() => setQuery(trimmed), debounceMs);
    return () => clearTimeout(timer);
  }, [text, debounceMs]);

  const tooShort = query.length < MIN_CHARS;
  const { data, isFetching, isError } = useSearchMessagesQuery(
    { query: query, conversationId: partnerId, limit: RESULT_LIMIT },
    { skip: tooShort || !partnerId }
  );
  const results: any[] = !tooShort && data && Array.isArray(data.data) ? data.data : [];

  const dateLabel = (iso: string): string => {
    const date = new Date(iso);
    return isNaN(date.getTime())
      ? ""
      : date.toLocaleDateString(i18n.language || undefined, { month: "short", day: "numeric", year: "numeric" });
  };

  let status: string | null = null;
  if (tooShort) status = t("chatPage.search.hint") || "Type at least 2 characters";
  else if (isError) status = t("chatPage.search.unavailable") || "Search isn't available right now";
  else if (isFetching && results.length === 0) status = t("chatPage.search.searching") || "Searching…";
  else if (results.length === 0) status = t("chatPage.search.empty") || "No messages found";

  return (
    <DialogShell
      labelledBy="chat-search-title"
      onClose={onClose}
      testId="chat-search-dialog-shell"
      backdropTestId="chat-search-backdrop"
      initialFocusRef={inputRef}
      panelClassName={[
        "relative flex max-h-[85vh] w-full max-w-lg flex-col rounded-card border border-line",
        "bg-surface p-4 shadow-lg dark:border-line-dark dark:bg-cardbg-dark",
      ].join(" ")}
    >
      <div className="flex items-start justify-between gap-2">
        <h2 id="chat-search-title" className="font-display text-base text-ink-900 dark:text-ink-50">
          {t("chatPage.search.title", { name: partnerName }) || `Search messages with ${partnerName}`}
        </h2>
        <button
          type="button"
          onClick={onClose}
          aria-label={t("chatPage.search.close") || "Close"}
          className="rounded-chip p-1.5 text-ink-500 hover:bg-ink-100 dark:text-ink-300 dark:hover:bg-ink-800"
        >
          <X className="h-4 w-4" aria-hidden />
        </button>
      </div>

      <div className="relative mt-3">
        <Search className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-400" aria-hidden />
        <input
          ref={inputRef}
          type="search"
          data-testid="chat-search-input"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder={t("chatPage.search.placeholder") || "Search this chat"}
          aria-label={t("chatPage.search.placeholder") || "Search this chat"}
          className={FIELD}
        />
      </div>

      <div className="mt-2 flex-1 overflow-y-auto" role="list">
        {status ? (
          <p className={STATUS} role="status">
            {status}
          </p>
        ) : (
          results.map((m: any) => {
            const mine = senderIdOf(m) === viewerId;
            const who = mine ? t("chatPage.search.you") || "You" : partnerName;
            const body = m.message || (m.media && m.media.fileName) || "";
            return (
              <button
                key={m._id}
                type="button"
                role="listitem"
                data-testid={`chat-search-result-${m._id}`}
                onClick={() => onJump(String(m._id))}
                className="flex w-full flex-col gap-0.5 rounded-card px-3 py-2 text-start hover:bg-ink-100 dark:hover:bg-ink-800"
              >
                <span className="flex w-full items-baseline justify-between gap-2 text-xs text-ink-500 dark:text-ink-400">
                  <span className="font-semibold text-ink-700 dark:text-ink-200">{who}</span>
                  <span>{dateLabel(m.createdAt)}</span>
                </span>
                <span className="line-clamp-2 text-sm text-ink-900 dark:text-ink-50">{body}</span>
              </button>
            );
          })
        )}
      </div>
    </DialogShell>
  );
};

export default MessageSearchDialog;
```

3b. `ChatContent.tsx`:
- imports: add `Search` to the `lucide-react` import list; add
  ```tsx
  import MessageSearchDialog from "./components/MessageSearchDialog";
  import notify from "../../design/notify";
  ```
- state, next to `isInfoOpen`'s `useState`: `const [isSearchOpen, setIsSearchOpen] = useState(false);`
- after `handleJumpToMessage` add:
  ```tsx
  // A search result. The search covers the whole history; the thread holds
  // only the pages loaded so far, so a result further back is explained
  // rather than silently doing nothing.
  const handleJumpFromSearch = useCallback(
    (messageId: string) => {
      setIsSearchOpen(false);
      const container = chatContainerRef.current;
      const el = container ? (container.querySelector(`[data-msg-id="${messageId}"]`) as HTMLElement | null) : null;
      if (!el) {
        notify.info(t("chatPage.search.notLoaded") || "That message is further back. Scroll up to load it.");
        return;
      }
      el.scrollIntoView({ behavior: "smooth", block: "center" });
      el.classList.add("modern-message--highlight");
      window.setTimeout(() => el.classList.remove("modern-message--highlight"), 2000);
    },
    [t]
  );
  ```
- header: inside `<div className="header-actions">`, before the existing "More options" button, add:
  ```tsx
            <button
              className="action-btn"
              type="button"
              data-testid="chat-header-search"
              onClick={() => setIsSearchOpen(true)}
              aria-haspopup="dialog"
              title={t("chatPage.search.open") || "Search messages"}
              aria-label={t("chatPage.search.open") || "Search messages"}
            >
              <Search size={20} />
            </button>
  ```
- after the `{isInfoOpen && ( <ChatInfoPanel … /> )}` block add:
  ```tsx
      {isSearchOpen && (
        <MessageSearchDialog
          partnerId={selectedUser}
          partnerName={userName}
          onClose={() => setIsSearchOpen(false)}
          onJump={handleJumpFromSearch}
        />
      )}
  ```
- the "Clear state when switching conversations" effect also does `setIsSearchOpen(false);`.

3c. Append to `ChatContent.css`:
```css
/* A message reached from search (chat#17). */
.modern-message--highlight .message-bubble {
  outline: 2px solid var(--chat-accent);
  outline-offset: 2px;
  transition: outline-color 0.3s ease;
}
```

3d. `STRICT_FILES` += `"components/MessageSearchDialog.tsx",`.

3e. `eng.json` `chatPage`:
```json
"search": {
  "open": "Search messages",
  "title": "Search messages with {{name}}",
  "close": "Close",
  "placeholder": "Search this chat",
  "hint": "Type at least 2 characters",
  "searching": "Searching…",
  "empty": "No messages found",
  "unavailable": "Search isn't available right now",
  "you": "You",
  "notLoaded": "That message is further back. Scroll up to load it."
}
```

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false MessageSearchDialog ChatContent chatStyling chatTokens
```

- [ ] **Step 5: Commit**

```bash
git add src/components/chat/components/MessageSearchDialog.tsx src/components/chat/components/MessageSearchDialog.test.tsx \
  src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx src/components/chat/ChatContent.pagination.test.tsx \
  src/components/chat/ChatContent.css src/components/chat/chatStyling.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(chat): search a conversation's messages

useSearchMessagesQuery existed but nothing used it. The chat header gains a
search: debounced (the endpoint allows 20 a minute), scoped to this
conversation, results with who said it and when; picking one scrolls to and
flashes the message, or says it is further back than what is loaded.
Live contract probe: <ok | 500 $or/$text — backend item filed>.

Still open (Phase 3 chat): bookmarks, archive + mute durations, blocked
banner, i18n sweep.
EOF
```

---

### Task P3-CHAT-17: Saved (bookmarked) messages: list, open, unbookmark (chat#17)

**Files:**
- Modify: `src/store/slices/chatSlice.ts` (`bookmarkMessage`/`unbookmarkMessage`/`getBookmarks` :322-342),
  `src/store/slices/apiSlice.ts` (`tagTypes` :149-197)
- Create: `src/components/chat/components/BookmarksDialog.tsx`
- Modify: `src/components/chat/ChatInfoPanel.tsx` (row + dialog), `src/components/chat/ChatContent.tsx` (bookmark feedback :2302-2306)
- Modify: `src/components/chat/chatStyling.test.ts`, `src/utils/locales/eng.json`
- Test: `src/components/chat/components/BookmarksDialog.test.tsx` (new), `src/store/slices/chatActionsEndpoints.test.ts`
  (append), `src/components/chat/ChatInfoPanel.test.tsx` (stub + case)

**Interfaces:**
- Consumes: `GET /api/v1/messages/bookmarks?page&limit` (`controllers/advancedMessages.js:1058-1083`) →
  `{success, count, total, pages, data:[{message:<populated with sender/receiver {_id,name,images}> | null, bookmarkedAt, note?}]}`
  in the order bookmarked (oldest first); `message` is null when the message was deleted. `POST /messages/:id/bookmark`
  answers 400 "Message already bookmarked" for a repeat; `DELETE /messages/:id/bookmark` removes it. Bookmarks belong to
  the user, not to a conversation, so the dialog lists all of them.
- Produces: `useGetBookmarksQuery({page?, limit?})` (args now optional object), tag `"Bookmarks"`.

- [ ] **Step 1: Write the failing tests**

Append to `chatActionsEndpoints.test.ts` (inside the main `describe`):
```ts
  it("getBookmarks asks for one page of 50 by default", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((chatApiSlice.endpoints as any).getBookmarks.initiate({}));
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/bookmarks`);
    expect(url.searchParams.get("page")).toBe("1");
    expect(url.searchParams.get("limit")).toBe("50");
  });
```

`src/components/chat/components/BookmarksDialog.test.tsx`:
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import BookmarksDialog from "./BookmarksDialog";

const mockBookmarks = jest.fn();
const mockUnbookmark = jest.fn();
const mockSuccess = jest.fn();
const mockError = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
jest.mock("../../../store/slices/chatSlice", () => ({
  useGetBookmarksQuery: (arg: any, opts: any) => mockBookmarks(arg, opts),
  useUnbookmarkMessageMutation: () => [mockUnbookmark, { isLoading: false }],
}));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { success: (m: string) => mockSuccess(m), error: (m: string) => mockError(m), info: jest.fn() },
}));

const onClose = jest.fn();

function renderDialog() {
  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user: { _id: "me" }, token: "t" } }) => state },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <BookmarksDialog onClose={onClose} />
      </MemoryRouter>
    </Provider>
  );
}

const row = (id: string, sender: any, receiver: any, text: string) => ({
  message: { _id: id, message: text, createdAt: "2026-09-20T10:00:00.000Z", sender, receiver },
  bookmarkedAt: "2026-09-21T10:00:00.000Z",
});

beforeEach(() => {
  mockBookmarks.mockReturnValue({
    data: {
      data: [
        row("m1", { _id: "u2", name: "Ada" }, { _id: "me", name: "Me" }, "The bus leaves at 9"),
        row("m2", { _id: "me", name: "Me" }, { _id: "u3", name: "Bo" }, "My address is 12 Elm St"),
        { message: null, bookmarkedAt: "2026-09-21T10:00:00.000Z" },
      ],
    },
    isLoading: false,
    isError: false,
  });
  mockUnbookmark.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
});
afterEach(() => jest.clearAllMocks());

it("lists saved messages newest first, skipping deleted ones", () => {
  renderDialog();
  const rows = screen.getAllByTestId(/^bookmark-row-/);
  expect(rows.map((r) => r.getAttribute("data-testid"))).toEqual(["bookmark-row-m2", "bookmark-row-m1"]);
});

it("names the other person of each chat and links to it", () => {
  renderDialog();
  expect(screen.getByTestId("bookmark-row-m1")).toHaveTextContent("Ada");
  expect(screen.getByTestId("bookmark-open-m1")).toHaveAttribute("href", "/chat/u2");
  expect(screen.getByTestId("bookmark-row-m2")).toHaveTextContent("Bo");
  expect(screen.getByTestId("bookmark-open-m2")).toHaveAttribute("href", "/chat/u3");
});

it("removes a bookmark", async () => {
  renderDialog();
  fireEvent.click(screen.getByTestId("bookmark-remove-m1"));
  expect(mockUnbookmark).toHaveBeenCalledWith("m1");
  await waitFor(() => expect(mockSuccess).toHaveBeenCalledWith("Removed from saved messages"));
});

it("shows what the server said when removing fails", async () => {
  mockUnbookmark.mockReturnValue({ unwrap: () => Promise.reject({ data: { error: "Bookmark not found" } }) });
  renderDialog();
  fireEvent.click(screen.getByTestId("bookmark-remove-m1"));
  await waitFor(() => expect(mockError).toHaveBeenCalledWith("Bookmark not found"));
});

it("has an empty state", () => {
  mockBookmarks.mockReturnValue({ data: { data: [] }, isLoading: false, isError: false });
  renderDialog();
  expect(screen.getByText("No saved messages yet")).toBeInTheDocument();
});
```

In `ChatInfoPanel.test.tsx` add a stub beside the other `jest.mock` calls:
```tsx
jest.mock("./components/BookmarksDialog", () => ({
  __esModule: true,
  default: () => require("react").createElement("div", { "data-testid": "bookmarks-dialog" }),
}));
```
and a case in `describe("the entries the panel offers", …)`:
```tsx
  it("opens the saved messages", () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-bookmarks"));
    expect(screen.getByTestId("bookmarks-dialog")).toBeInTheDocument();
  });
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatActionsEndpoints BookmarksDialog ChatInfoPanel
```
Expected: `page`/`limit` are null; the dialog module is missing; `chat-info-bookmarks` does not exist.

- [ ] **Step 3: Implement**

3a. `apiSlice.ts` `tagTypes`: after `"Conversation",` add
```ts
    // The viewer's saved messages (GET /messages/bookmarks): user-wide, so its
    // own tag rather than refetching a thread on every bookmark change.
    "Bookmarks",
```

3b. `chatSlice.ts` — replace the three bookmark endpoints with:
```ts
    // Bookmarks — the viewer's saved messages, user-wide (advancedMessages.js).
    bookmarkMessage: builder.mutation({
      query: (messageId: string) => ({
        url: `${MESSAGES_URL}/${messageId}/bookmark`,
        method: "POST",
      }),
      invalidatesTags: ["Bookmarks"],
    }),
    unbookmarkMessage: builder.mutation({
      query: (messageId: string) => ({
        url: `${MESSAGES_URL}/${messageId}/bookmark`,
        method: "DELETE",
      }),
      invalidatesTags: ["Bookmarks"],
    }),
    getBookmarks: builder.query({
      query: ({ page = 1, limit = 50 }: { page?: number; limit?: number } = {}) => ({
        url: `${MESSAGES_URL}/bookmarks?page=${page}&limit=${limit}`,
      }),
      providesTags: ["Bookmarks"],
    }),
```
(`invalidatesTags: ["Conversation"]` is dropped on purpose: a bookmark changes nothing in the thread, and the old tag
refetched the open conversation on every bookmark.)

3c. Create `src/components/chat/components/BookmarksDialog.tsx`:
```tsx
import React from "react";
import { Link } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { BookmarkMinus, MessageCircle, X } from "lucide-react";
import DialogShell from "../../../design/DialogShell";
import notify from "../../../design/notify";
import { useGetBookmarksQuery, useUnbookmarkMessageMutation } from "../../../store/slices/chatSlice";
import { idOf } from "../lib/normalizeMessage";

interface BookmarksDialogProps {
  onClose: () => void;
}

const STATUS = "px-1 py-6 text-center text-sm text-ink-500 dark:text-ink-400";
const ICON_BTN =
  "flex h-8 w-8 flex-none items-center justify-center rounded-chip text-ink-500 hover:bg-ink-100 disabled:opacity-50 dark:text-ink-300 dark:hover:bg-ink-800";

/** The viewer's saved messages from every chat, newest first, the way the app's bookmarks screen lists them. */
const BookmarksDialog: React.FC<BookmarksDialogProps> = ({ onClose }) => {
  const { t, i18n } = useTranslation();
  const viewerId = useSelector((state: any) => state.auth.userInfo?.user?._id || "");
  const { data, isLoading, isError } = useGetBookmarksQuery({ page: 1, limit: 50 });
  const [unbookmark, { isLoading: isRemoving }] = useUnbookmarkMessageMutation();

  // The server lists in the order things were saved and keeps a row whose
  // message was deleted (message: null).
  const rows: any[] = ((data && data.data) || [])
    .filter((row: any) => row && row.message && row.message._id)
    .slice()
    .reverse();

  const remove = async (messageId: string): Promise<void> => {
    try {
      await unbookmark(messageId).unwrap();
      notify.success(t("chatPage.bookmarks.removed") || "Removed from saved messages");
    } catch (error) {
      const body: any = error && (error as any).data;
      notify.error((body && (body.error || body.message)) || t("chatPage.bookmarks.removeFailed") || "Couldn't remove it");
    }
  };

  let status: string | null = null;
  if (isLoading) status = t("chatPage.bookmarks.loading") || "Loading saved messages…";
  else if (isError) status = t("chatPage.bookmarks.error") || "Couldn't load saved messages";
  else if (rows.length === 0) status = t("chatPage.bookmarks.empty") || "No saved messages yet";

  return (
    <DialogShell
      labelledBy="chat-bookmarks-title"
      onClose={onClose}
      testId="chat-bookmarks-dialog"
      backdropTestId="chat-bookmarks-backdrop"
      panelClassName={[
        "relative flex max-h-[85vh] w-full max-w-lg flex-col rounded-card border border-line",
        "bg-surface p-4 shadow-lg dark:border-line-dark dark:bg-cardbg-dark",
      ].join(" ")}
    >
      <div className="flex items-start justify-between gap-2">
        <h2 id="chat-bookmarks-title" className="font-display text-base text-ink-900 dark:text-ink-50">
          {t("chatPage.bookmarks.title") || "Saved messages"}
        </h2>
        <button type="button" onClick={onClose} aria-label={t("chatPage.bookmarks.close") || "Close"} className={ICON_BTN}>
          <X className="h-4 w-4" aria-hidden />
        </button>
      </div>

      <div className="mt-2 flex-1 overflow-y-auto">
        {status ? (
          <p className={STATUS} role="status">
            {status}
          </p>
        ) : (
          rows.map((row: any) => {
            const msg = row.message;
            const senderId = idOf(msg.sender);
            const partner = senderId === viewerId ? msg.receiver : msg.sender;
            const partnerId = idOf(partner);
            const partnerName = (partner && typeof partner === "object" && partner.name) || "";
            const body =
              msg.message ||
              (msg.media && (msg.media.fileName || msg.media.type)) ||
              t("chatPage.bookmarks.attachment") ||
              "Attachment";
            const when = new Date(msg.createdAt);
            return (
              <div
                key={msg._id}
                data-testid={`bookmark-row-${msg._id}`}
                className="flex items-start gap-2 rounded-card px-2 py-2 hover:bg-ink-50 dark:hover:bg-ink-900"
              >
                <div className="min-w-0 flex-1">
                  <p className="flex items-baseline justify-between gap-2 text-xs text-ink-500 dark:text-ink-400">
                    <span className="truncate font-semibold text-ink-700 dark:text-ink-200">{partnerName}</span>
                    <span>
                      {isNaN(when.getTime())
                        ? ""
                        : when.toLocaleDateString(i18n.language || undefined, { month: "short", day: "numeric" })}
                    </span>
                  </p>
                  <p className="line-clamp-3 text-sm text-ink-900 dark:text-ink-50">{body}</p>
                </div>
                {partnerId ? (
                  <Link
                    to={`/chat/${partnerId}`}
                    data-testid={`bookmark-open-${msg._id}`}
                    onClick={onClose}
                    aria-label={t("chatPage.bookmarks.open") || "Open chat"}
                    title={t("chatPage.bookmarks.open") || "Open chat"}
                    className={ICON_BTN}
                  >
                    <MessageCircle className="h-4 w-4" aria-hidden />
                  </Link>
                ) : null}
                <button
                  type="button"
                  data-testid={`bookmark-remove-${msg._id}`}
                  onClick={() => remove(String(msg._id))}
                  disabled={isRemoving}
                  aria-label={t("chatPage.bookmarks.remove") || "Remove from saved"}
                  title={t("chatPage.bookmarks.remove") || "Remove from saved"}
                  className={ICON_BTN}
                >
                  <BookmarkMinus className="h-4 w-4" aria-hidden />
                </button>
              </div>
            );
          })
        )}
      </div>
    </DialogShell>
  );
};

export default BookmarksDialog;
```

3d. `ChatInfoPanel.tsx`:
- imports: add `Bookmark` to the `lucide-react` list; `import BookmarksDialog from "./components/BookmarksDialog";`
- `dialog` state union: `"block" | "delete" | "report" | "wallpaper" | "bookmarks" | null`
- after the shared-media `<Link …>` row add:
  ```tsx
          <button
            type="button"
            data-testid="chat-info-bookmarks"
            onClick={() => setDialog("bookmarks")}
            className={ROW}
          >
            <Bookmark className="h-4 w-4 shrink-0" aria-hidden />
            <span className="flex-1">{t("chatPage.bookmarks.title") || "Saved messages"}</span>
            <ChevronRight className="h-4 w-4 shrink-0" aria-hidden />
          </button>
  ```
- after `{dialog === "wallpaper" ? (…) : null}` add `{dialog === "bookmarks" ? <BookmarksDialog onClose={closeDialog} /> : null}`.

3e. `ChatContent.tsx` — the action menu's bookmark currently only logs. Replace
```tsx
              onBookmark={() =>
                bookmarkMessage(activeActionMsg._id)
                  .unwrap()
                  .catch((e) => console.error("Bookmark failed:", e))
              }
```
with
```tsx
              onBookmark={() =>
                bookmarkMessage(activeActionMsg._id)
                  .unwrap()
                  .then(() => notify.success(t("chatPage.bookmarks.added") || "Saved"))
                  .catch((e: any) =>
                    notify.error(
                      (e && e.data && (e.data.error || e.data.message)) ||
                        t("chatPage.bookmarks.addFailed") ||
                        "Couldn't save the message"
                    )
                  )
              }
```
(`notify` was imported in P3-CHAT-16. The 400 "Message already bookmarked" now reaches the reader as that text.)

3f. `STRICT_FILES` += `"components/BookmarksDialog.tsx",`.

3g. `eng.json` `chatPage`:
```json
"bookmarks": {
  "title": "Saved messages",
  "close": "Close",
  "loading": "Loading saved messages…",
  "error": "Couldn't load saved messages",
  "empty": "No saved messages yet",
  "attachment": "Attachment",
  "open": "Open chat",
  "remove": "Remove from saved",
  "removed": "Removed from saved messages",
  "removeFailed": "Couldn't remove it",
  "added": "Saved",
  "addFailed": "Couldn't save the message"
}
```

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatActionsEndpoints BookmarksDialog ChatInfoPanel ChatContent apiSlice chatStyling
```

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/chatSlice.ts src/store/slices/apiSlice.ts src/store/slices/chatActionsEndpoints.test.ts \
  src/components/chat/components/BookmarksDialog.tsx src/components/chat/components/BookmarksDialog.test.tsx \
  src/components/chat/ChatInfoPanel.tsx src/components/chat/ChatInfoPanel.test.tsx src/components/chat/ChatContent.tsx \
  src/components/chat/chatStyling.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(chat): saved messages list with open and unbookmark

The web could bookmark a message but never show or remove one. Chat info
gains "Saved messages": every bookmarked message newest first (deleted
ones skipped), who the chat is with, a link to that chat, and Remove.
Bookmarking now says whether it worked (including "already bookmarked")
and no longer refetches the open thread.

Still open (Phase 3 chat): archive + mute durations, blocked banner, i18n
sweep.
EOF
```

---

### Task P3-CHAT-18: Archive / unarchive conversations, and mute for 1 hour, 8 hours, 1 week or always (chat#17)

**Files:**
- Modify: `src/store/slices/chatSlice.ts` (two endpoints after `unpinConversation` :137-143; exports)
- Create: `src/components/chat/lib/muteDurations.ts`, `src/components/chat/components/MuteDurationDialog.tsx`
- Modify: `src/components/chat/ChatInfoPanel.tsx` (`handleMute` :196-214, rows :359-396, dialogs)
- Modify: `src/components/chat/UsersList.tsx` (`User` interface :24-39, conversation threading :600-611,
  `handleToggleMute` :156-197, `filteredChatPartners` :653-661, row menu :947-1000, list header)
- Modify: `src/components/chat/UsersList.css`, `src/components/chat/chatStyling.test.ts`, `src/utils/locales/eng.json`
- Test: `src/components/chat/lib/muteDurations.test.ts`, `src/components/chat/components/MuteDurationDialog.test.tsx` (new),
  `src/store/slices/chatActionsEndpoints.test.ts`, `src/components/chat/ChatInfoPanel.test.tsx`, `src/components/chat/UsersList.test.tsx`

**Interfaces:**
- Consumes: `POST /api/v1/conversations/:id/mute {duration?: <ms>}` (`controllers/conversations.js:143`,
  `models/Conversation.js:412` `mutedUntil = duration ? now + duration : null`; no body = until unmuted — what the app sends
  today, `conversation_service.dart:152-164`). `POST /conversations/:id/archive` and `/unarchive` (`routes/conversations.js:27-28`).
  `GET /conversations` rows carry `isArchived`, `isMuted` (already false once `mutedUntil` passed) and `mutedBy[]`; with no
  `archived` param the list returns archived rows too (`lib/conversationListQuery.js`), which is what the app shows — the
  app has **no** archive UI, so archiving on web hides a chat on web only; the app keeps showing it (stated in the UI).
- Depends on P3-CHAT-6 (list built from `/conversations` only). The UsersList edits below anchor on code P3-CHAT-6 keeps:
  the `User` row type, the place `isPinned`/`isMuted` are copied from the conversation onto the row, `filteredChatPartners`,
  the row menu and `handleToggleMute`.
- Produces: `useArchiveConversationMutation`, `useUnarchiveConversationMutation`, `MUTE_DURATIONS`, `muteArgs()`,
  `MuteDurationDialog`.

- [ ] **Step 1: Write the failing tests**

Append to `chatActionsEndpoints.test.ts`:
```ts
  it("archiveConversation -> POST /api/v1/conversations/:id/archive", async () => {
    const calls = mockFetch();
    await makeStore().dispatch((chatApiSlice.endpoints as any).archiveConversation.initiate("c1"));
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/conversations/c1/archive");
    expect(calls[0].method).toBe("POST");
  });

  it("unarchiveConversation -> POST /api/v1/conversations/:id/unarchive", async () => {
    const calls = mockFetch();
    await makeStore().dispatch((chatApiSlice.endpoints as any).unarchiveConversation.initiate("c1"));
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/conversations/c1/unarchive");
  });

  it("muteConversation sends the duration in ms, and no duration for 'always'", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((chatApiSlice.endpoints as any).muteConversation.initiate({ conversationId: "c1", duration: 3600000 }));
    await store.dispatch((chatApiSlice.endpoints as any).muteConversation.initiate({ conversationId: "c1" }));
    expect(JSON.parse(calls[0].body as string)).toEqual({ duration: 3600000 });
    expect(JSON.parse(calls[1].body as string)).toEqual({});
  });
```

`src/components/chat/lib/muteDurations.test.ts`:
```ts
import { MUTE_DURATIONS, muteArgs } from "./muteDurations";

it("offers 1 hour, 8 hours, 1 week and always, in that order", () => {
  expect(MUTE_DURATIONS.map((d) => d.id)).toEqual(["1h", "8h", "1w", "always"]);
  expect(MUTE_DURATIONS.map((d) => d.ms)).toEqual([3600000, 28800000, 604800000, null]);
});

it("builds the mutation argument: a duration, or none for always", () => {
  expect(muteArgs("c1", 3600000)).toEqual({ conversationId: "c1", duration: 3600000 });
  expect(muteArgs("c1", null)).toEqual({ conversationId: "c1" });
});
```

`src/components/chat/components/MuteDurationDialog.test.tsx`:
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import MuteDurationDialog from "./MuteDurationDialog";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

it("hands back the chosen duration in ms (null for always)", () => {
  const onChoose = jest.fn();
  render(<MuteDurationDialog name="Ada" onChoose={onChoose} onCancel={jest.fn()} />);
  expect(screen.getByText("Mute Ada?")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("mute-option-8h"));
  expect(onChoose).toHaveBeenCalledWith(28800000);
  fireEvent.click(screen.getByTestId("mute-option-always"));
  expect(onChoose).toHaveBeenLastCalledWith(null);
});

it("cancels", () => {
  const onCancel = jest.fn();
  render(<MuteDurationDialog name="Ada" onChoose={jest.fn()} onCancel={onCancel} />);
  fireEvent.click(screen.getByTestId("mute-cancel"));
  expect(onCancel).toHaveBeenCalled();
});
```

`ChatInfoPanel.test.tsx` — add `const mockArchive = jest.fn(); const mockUnarchive = jest.fn();`, add to the chatSlice mock
```tsx
  useArchiveConversationMutation: () => [mockArchive, { isLoading: false }],
  useUnarchiveConversationMutation: () => [mockUnarchive, { isLoading: false }],
```
set `mockArchive.mockReturnValue(resolved()); mockUnarchive.mockReturnValue(resolved());` in `beforeEach`, and **replace** the
case `"mutes the conversation this pair actually has"` with:
```tsx
  it("asks how long, then mutes the conversation this pair actually has", async () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-mute"));
    expect(mockMute).not.toHaveBeenCalled();
    fireEvent.click(screen.getByTestId("mute-option-1h"));
    expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1", duration: 3600000 });
    await waitFor(() => expect(screen.queryByTestId("mute-option-1h")).toBeNull());
  });

  it("mutes until unmuted when 'always' is chosen (no duration, like the app)", () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-mute"));
    fireEvent.click(screen.getByTestId("mute-option-always"));
    expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1" });
  });
```
and add:
```tsx
describe("archive", () => {
  it("archives the conversation", async () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-archive"));
    expect(mockArchive).toHaveBeenCalledWith("c1");
  });

  it("unarchives one that is archived", () => {
    mockConversations.mockReturnValue({
      data: { data: [{ _id: "c1", participants: [{ _id: "me" }, { _id: "u2" }], isArchived: true }] },
      isLoading: false,
    });
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-archive"));
    expect(mockUnarchive).toHaveBeenCalledWith("c1");
    expect(mockArchive).not.toHaveBeenCalled();
  });

  it("cannot archive before the conversation exists", () => {
    mockConversations.mockReturnValue({ data: { data: [] }, isLoading: false });
    renderPanel();
    expect(screen.getByTestId("chat-info-archive")).toBeDisabled();
  });
});
```

`UsersList.test.tsx` — add `const mockArchive = jest.fn(); const mockUnarchive = jest.fn();`, add the same two hooks to the
chatSlice mock, `resolved()` them in `beforeEach`. The two cases that click `users-list-mute-u2` on an unmuted row and
expect `mockMute({conversationId:"c1"})` immediately (`"resolves the conversation through the shared matcher…"` and
`"mutes a conversation from the row's menu"`) gain one click before the assertion:
```tsx
  fireEvent.click(screen.getByTestId("mute-option-always"));
```
and add:
```tsx
it("mutes from the row's menu for the chosen time", () => {
  renderList();
  fireEvent.click(screen.getByTestId("users-list-menu-u2"));
  fireEvent.click(screen.getByTestId("users-list-mute-u2"));
  fireEvent.click(screen.getByTestId("mute-option-1w"));
  expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1", duration: 604800000 });
});

it("hides archived chats from the list and shows them behind the Archived toggle", () => {
  mockConversations.mockReturnValue({
    data: {
      data: [
        conversation(),
        conversation({
          _id: "c2",
          isArchived: true,
          participants: [
            { _id: "me", name: "Me", images: [] },
            { _id: "u3", name: "Bo", images: [] },
          ],
        }),
      ],
    },
    refetch: jest.fn(),
  });
  renderList();
  expect(screen.getByText("Ada")).toBeInTheDocument();
  expect(screen.queryByText("Bo")).toBeNull();

  fireEvent.click(screen.getByTestId("users-list-archived-toggle"));
  expect(screen.getByText("Bo")).toBeInTheDocument();
  expect(screen.queryByText("Ada")).toBeNull();
});

it("archives from the row's menu", async () => {
  renderList();
  fireEvent.click(screen.getByTestId("users-list-menu-u2"));
  fireEvent.click(screen.getByTestId("users-list-archive-u2"));
  expect(mockArchive).toHaveBeenCalledWith("c1");
});

it("offers no Archived toggle when nothing is archived", () => {
  renderList();
  expect(screen.queryByTestId("users-list-archived-toggle")).toBeNull();
});
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatActionsEndpoints muteDurations MuteDurationDialog ChatInfoPanel UsersList
```
Expected: `archiveConversation` undefined; both new modules missing; mute fires without a choice; no
`chat-info-archive`, `users-list-archive-u2` or `users-list-archived-toggle`; "Bo" is visible. The mute body test passes
already (the endpoint forwards `duration`) — it pins the shape.

- [ ] **Step 3: Implement**

3a. `chatSlice.ts` — after `unpinConversation` add:
```ts
    // Archive — web-only view state for now: the app has no archive screen and
    // its list shows archived chats like any other (GET /conversations without
    // `archived` returns both).
    archiveConversation: builder.mutation({
      query: (conversationId: string) => ({
        url: `${CONVERSATIONS_URL}/${conversationId}/archive`,
        method: "POST",
      }),
      invalidatesTags: ["Conversations"],
    }),
    unarchiveConversation: builder.mutation({
      query: (conversationId: string) => ({
        url: `${CONVERSATIONS_URL}/${conversationId}/unarchive`,
        method: "POST",
      }),
      invalidatesTags: ["Conversations"],
    }),
```
exports after `useUnpinConversationMutation,`: `useArchiveConversationMutation, useUnarchiveConversationMutation,`.

3b. Create `src/components/chat/lib/muteDurations.ts`:
```ts
/**
 * How long a mute lasts. The backend takes `duration` in ms and stores
 * mutedUntil = now + duration; no duration means until unmuted, which is what
 * the app sends today.
 */
export interface MuteDuration {
  id: "1h" | "8h" | "1w" | "always";
  ms: number | null;
  key: string;
  fallback: string;
}

const HOUR = 60 * 60 * 1000;

export const MUTE_DURATIONS: MuteDuration[] = [
  { id: "1h", ms: HOUR, key: "chatPage.mute.oneHour", fallback: "For 1 hour" },
  { id: "8h", ms: 8 * HOUR, key: "chatPage.mute.eightHours", fallback: "For 8 hours" },
  { id: "1w", ms: 7 * 24 * HOUR, key: "chatPage.mute.oneWeek", fallback: "For 1 week" },
  { id: "always", ms: null, key: "chatPage.mute.always", fallback: "Until I turn it back on" },
];

export function muteArgs(conversationId: string, ms: number | null): { conversationId: string; duration?: number } {
  return ms ? { conversationId: conversationId, duration: ms } : { conversationId: conversationId };
}
```

3c. Create `src/components/chat/components/MuteDurationDialog.tsx`:
```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import DialogShell from "../../../design/DialogShell";
import { MUTE_DURATIONS } from "../lib/muteDurations";

interface MuteDurationDialogProps {
  name: string;
  busy?: boolean;
  onChoose: (ms: number | null) => void;
  onCancel: () => void;
}

const OPTION =
  "w-full rounded-card px-3 py-3 text-start text-sm text-ink-700 hover:bg-ink-100 disabled:opacity-50 dark:text-ink-200 dark:hover:bg-ink-800";

/** "Mute Ada?" with the four lengths. Picking one is the confirmation. */
const MuteDurationDialog: React.FC<MuteDurationDialogProps> = ({ name, busy, onChoose, onCancel }) => {
  const { t } = useTranslation();
  return (
    <DialogShell
      labelledBy="chat-mute-title"
      onClose={onCancel}
      testId="chat-mute-dialog"
      backdropTestId="chat-mute-backdrop"
      dismissible={!busy}
    >
      <h2 id="chat-mute-title" className="font-display text-base text-ink-900 dark:text-ink-50">
        {t("chatPage.mute.title", { name: name }) || `Mute ${name}?`}
      </h2>
      <div className="mt-3 flex flex-col gap-0.5">
        {MUTE_DURATIONS.map((option) => (
          <button
            key={option.id}
            type="button"
            data-testid={`mute-option-${option.id}`}
            disabled={busy}
            onClick={() => onChoose(option.ms)}
            className={OPTION}
          >
            {t(option.key) || option.fallback}
          </button>
        ))}
      </div>
      <div className="mt-3 flex justify-end">
        <button
          type="button"
          data-testid="mute-cancel"
          onClick={onCancel}
          disabled={busy}
          className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
        >
          {t("chatPage.mute.cancel") || "Cancel"}
        </button>
      </div>
    </DialogShell>
  );
};

export default MuteDurationDialog;
```

3d. `ChatInfoPanel.tsx`:
- imports: add `Archive, ArchiveRestore` to `lucide-react`; add `useArchiveConversationMutation, useUnarchiveConversationMutation`
  to the chatSlice import; add
  ```tsx
  import MuteDurationDialog from "./components/MuteDurationDialog";
  import { muteArgs } from "./lib/muteDurations";
  ```
- after `const isMuted = Boolean(conversation?.isMuted);` add `const isArchived = Boolean(conversation?.isArchived);`
- after the `deleteConversation` hook line add:
  ```tsx
  const [archiveConversation, { isLoading: isArchiving }] = useArchiveConversationMutation();
  const [unarchiveConversation, { isLoading: isUnarchiving }] = useUnarchiveConversationMutation();
  ```
- `dialog` union adds `"mute"`.
- replace `handleMute` with:
  ```tsx
  const handleMute = async (): Promise<void> => {
    if (!conversationId) return;
    if (!isMuted) {
      setDialog("mute");
      return;
    }
    try {
      await unmuteConversation(conversationId).unwrap();
      notify.success(t("chatPage.info.unmuted") || "Notifications are back on");
    } catch (error) {
      notify.error(messageOf(error, t("chatPage.info.muteFailed") || "Couldn't update notifications"));
    }
  };

  const handleMuteFor = async (ms: number | null): Promise<void> => {
    if (!conversationId) return;
    try {
      await muteConversation(muteArgs(conversationId, ms)).unwrap();
      if (mounted.current) closeDialog();
      notify.success(t("chatPage.info.muted") || "Notifications muted");
    } catch (error) {
      notify.error(messageOf(error, t("chatPage.info.muteFailed") || "Couldn't update notifications"));
    }
  };

  const handleArchive = async (): Promise<void> => {
    if (!conversationId) return;
    try {
      if (isArchived) await unarchiveConversation(conversationId).unwrap();
      else await archiveConversation(conversationId).unwrap();
      notify.success(
        isArchived
          ? t("chatPage.archive.unarchived") || "Moved back to your chats"
          : t("chatPage.archive.archived") || "Archived on the website. The app still shows it."
      );
    } catch (error) {
      notify.error(messageOf(error, t("chatPage.archive.failed") || "Couldn't update the archive"));
    }
  };
  ```
- after the mute `<button …>` row add:
  ```tsx
          <button
            type="button"
            data-testid="chat-info-archive"
            onClick={handleArchive}
            disabled={conversationUnavailable || isArchiving || isUnarchiving}
            className={ROW}
          >
            {isArchived ? (
              <ArchiveRestore className="h-4 w-4 shrink-0" aria-hidden />
            ) : (
              <Archive className="h-4 w-4 shrink-0" aria-hidden />
            )}
            <span className="flex-1">
              {isArchived
                ? t("chatPage.archive.unarchive") || "Unarchive chat"
                : t("chatPage.archive.archive") || "Archive chat"}
              {noConversationHint ? <span className={HINT}>{noConversationHint}</span> : null}
            </span>
          </button>
  ```
- after `{dialog === "bookmarks" ? … : null}` add:
  ```tsx
      {dialog === "mute" ? (
        <MuteDurationDialog name={userName} busy={isMuting} onChoose={handleMuteFor} onCancel={closeDialog} />
      ) : null}
  ```

3e. `UsersList.tsx`:
- imports: add `Archive, ArchiveRestore` to the `lucide-react` import; add `useArchiveConversationMutation,
  useUnarchiveConversationMutation` to the chatSlice import; add
  ```tsx
  import MuteDurationDialog from "./components/MuteDurationDialog";
  import { muteArgs } from "./lib/muteDurations";
  ```
- `interface User`: after `isMuted?: boolean;` add `isArchived?: boolean;`
- where the conversation's flags are copied onto the row (today `isPinned: Boolean(conversation.isPinned),` /
  `isMuted: Boolean(conversation.isMuted),` and `existing.isMuted = Boolean(conversation.isMuted);`), copy
  `isArchived: Boolean(conversation.isArchived)` the same way in every place `isMuted` is copied.
- state, beside `openMenuFor`:
  ```tsx
  const [showArchived, setShowArchived] = useState(false);
  const [mutingPartner, setMutingPartner] = useState<User | null>(null);
  const [archiveConversation] = useArchiveConversationMutation();
  const [unarchiveConversation] = useUnarchiveConversationMutation();
  ```
- in `handleToggleMute`, replace the branch
  ```tsx
        if (partner.isMuted) {
          await unmuteConversation(resolvedConversationId).unwrap();
        } else {
          await muteConversation({ conversationId: resolvedConversationId }).unwrap();
        }
  ```
  with
  ```tsx
        if (!partner.isMuted) {
          // How long is asked first; MuteDurationDialog calls handleMuteFor.
          setMutingPartner(partner);
          return;
        }
        await unmuteConversation(resolvedConversationId).unwrap();
  ```
  and add after `handleToggleMute`:
  ```tsx
  const handleMuteFor = useCallback(
    async (ms: number | null) => {
      const partner = mutingPartner;
      setMutingPartner(null);
      const conversationId = partner ? resolveConversationId(partner) : undefined;
      if (!conversationId) return;
      try {
        await muteConversation(muteArgs(conversationId, ms)).unwrap();
        toast.success(t("chatPage.actions.muted") || "Notifications muted", {
          autoClose: 1800,
          theme: "colored",
          transition: Bounce,
        });
        refetchConversations();
      } catch (err: any) {
        toast.error(
          err?.data?.error || err?.data?.message || t("chatPage.actions.muteFailed") || "Couldn't update notifications",
          { autoClose: 3000, theme: "colored", transition: Bounce }
        );
      }
    },
    [mutingPartner, muteConversation, refetchConversations, resolveConversationId, t]
  );

  const handleToggleArchive = useCallback(
    async (e: React.MouseEvent, partner: User) => {
      e.stopPropagation();
      setOpenMenuFor(null);
      const conversationId = resolveConversationId(partner);
      if (!conversationId) return;
      try {
        if (partner.isArchived) await unarchiveConversation(conversationId).unwrap();
        else await archiveConversation(conversationId).unwrap();
        refetchConversations();
      } catch (err: any) {
        toast.error(
          err?.data?.error || err?.data?.message || t("chatPage.archive.failed") || "Couldn't update the archive",
          { autoClose: 3000, theme: "colored", transition: Bounce }
        );
      }
    },
    [archiveConversation, unarchiveConversation, refetchConversations, resolveConversationId, t]
  );
  ```
  (If P3-CHAT-6 replaced the `toast` calls with `notify`, use `notify.success`/`notify.error` here too.)
- `filteredChatPartners` becomes:
  ```tsx
  const archivedCount = useMemo(
    () => chatPartners.filter((u) => Boolean(u.isArchived)).length,
    [chatPartners]
  );

  const filteredChatPartners = useMemo(() => {
    // Archived chats live behind the toggle (web-only: the app lists them as usual).
    const inView = chatPartners.filter((u) => Boolean(u.isArchived) === showArchived);
    if (!searchQuery.trim()) return inView;
    const q = searchQuery.toLowerCase().trim();
    return inView.filter(
      (u) => u.name.toLowerCase().includes(q) || u.lastMessage?.toLowerCase().includes(q)
    );
  }, [chatPartners, searchQuery, showArchived]);
  ```
  and add an effect so the archive view never strands the reader on an empty list:
  ```tsx
  useEffect(() => {
    if (showArchived && archivedCount === 0) setShowArchived(false);
  }, [showArchived, archivedCount]);
  ```
- in the main return, directly above the `<ul …>` that maps `filteredChatPartners` (inside the same wrapper), add:
  ```tsx
        {(archivedCount > 0 || showArchived) && (
          <button
            type="button"
            className="users-list-archived-toggle"
            data-testid="users-list-archived-toggle"
            aria-pressed={showArchived}
            onClick={() => setShowArchived((v) => !v)}
          >
            {showArchived ? <ArchiveRestore size={14} /> : <Archive size={14} />}
            <span>
              {showArchived
                ? t("chatPage.archive.back") || "Back to chats"
                : t("chatPage.archive.toggle", { count: archivedCount }) || `Archived (${archivedCount})`}
            </span>
          </button>
        )}
  ```
- row menu: after the mute `<button …>` add:
  ```tsx
                        <button
                          type="button"
                          className="users-list-action-item"
                          data-testid={`users-list-archive-${user._id}`}
                          onClick={(e) => handleToggleArchive(e, user)}
                        >
                          {user.isArchived ? <ArchiveRestore size={14} /> : <Archive size={14} />}
                          <span>
                            {user.isArchived
                              ? t("chatPage.archive.unarchive") || "Unarchive chat"
                              : t("chatPage.archive.archive") || "Archive chat"}
                          </span>
                        </button>
  ```
- before the closing `ConfirmDialog` add:
  ```tsx
      {mutingPartner ? (
        <MuteDurationDialog
          name={mutingPartner.name}
          onChoose={handleMuteFor}
          onCancel={() => setMutingPartner(null)}
        />
      ) : null}
  ```

3f. Append to `src/components/chat/UsersList.css`:
```css
.users-list-archived-toggle {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  padding: 8px 16px;
  background: transparent;
  border: 0;
  border-block-end: 1px solid var(--chat-line);
  color: var(--chat-muted);
  font-size: 13px;
  text-align: start;
  cursor: pointer;
}

.users-list-archived-toggle:hover {
  background: var(--chat-hover);
}
```

3g. `STRICT_FILES` += `"components/MuteDurationDialog.tsx",`.

3h. `eng.json` `chatPage`:
```json
"mute": {
  "title": "Mute {{name}}?",
  "oneHour": "For 1 hour",
  "eightHours": "For 8 hours",
  "oneWeek": "For 1 week",
  "always": "Until I turn it back on",
  "cancel": "Cancel"
},
"archive": {
  "archive": "Archive chat",
  "unarchive": "Unarchive chat",
  "archived": "Archived on the website. The app still shows it.",
  "unarchived": "Moved back to your chats",
  "failed": "Couldn't update the archive",
  "toggle": "Archived ({{count}})",
  "back": "Back to chats"
}
```

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatActionsEndpoints muteDurations MuteDurationDialog ChatInfoPanel UsersList chatStyling chatTokens
```

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/chatSlice.ts src/store/slices/chatActionsEndpoints.test.ts \
  src/components/chat/lib/muteDurations.ts src/components/chat/lib/muteDurations.test.ts \
  src/components/chat/components/MuteDurationDialog.tsx src/components/chat/components/MuteDurationDialog.test.tsx \
  src/components/chat/ChatInfoPanel.tsx src/components/chat/ChatInfoPanel.test.tsx \
  src/components/chat/UsersList.tsx src/components/chat/UsersList.test.tsx src/components/chat/UsersList.css \
  src/components/chat/chatStyling.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(chat): archive conversations and mute for a chosen time

Mute was always permanent on web. Muting (from chat info or the list menu)
now asks for 1 hour, 8 hours, 1 week or until turned back on; the backend
already took `duration` in ms. Conversations can be archived and
unarchived; archived chats leave the web list and sit behind an "Archived"
toggle. The app has no archive screen, so it keeps listing them; the toast
says so.

Still open (Phase 3 chat): blocked banner, i18n sweep. Product: an app
archive view (or drop web archive) so both clients agree.
EOF
```

---

### Task P3-CHAT-19: "You can't message this person" banner when either side blocked (chat#17)

**Files:**
- Create: `src/components/chat/lib/useChatBlockState.ts`, `src/components/chat/components/BlockedChatBanner.tsx`
- Modify: `src/components/chat/ChatContent.tsx` (composer block `{!isRecording && (` :2140)
- Modify: `src/components/chat/ChatContent.css`, `src/components/chat/chatStyling.test.ts`, `src/utils/locales/eng.json`
- Modify: `src/components/chat/ChatContent.test.tsx`, `src/components/chat/ChatContent.pagination.test.tsx` (hook mock)
- Test: `src/components/chat/lib/useChatBlockState.test.tsx` (new), `src/components/chat/ChatContent.test.tsx` (cases)

**Interfaces:**
- Consumes: `GET /api/v1/users/:viewerId/block-status/:targetId` (`routes/userBlocks.js:17`) →
  `{success, data:{isBlocked, isBlockedBy, canMessage}}`; existing `useGetBlockStatusQuery({userId, targetUserId})`
  (`usersSlice.ts:303-308`, tag `"User"` — `blockUser`/`unblockUser` invalidate it, so unblocking from chat info lifts the
  banner without a reload). Same argument `ChatInfoPanel` passes, so both share one cache entry. App reference:
  `chat_conversation_screen.dart:389-407` (`isBlocked || isBlockedBy` → `_BlockedBanner` replaces the input,
  `conversation_input_area.dart:79`).
- Produces: `useChatBlockState(viewerId, partnerId) → {blocked, iBlocked, blockedMe}`.

- [ ] **Step 1: Write the failing tests**

`src/components/chat/lib/useChatBlockState.test.tsx`:
```tsx
import { renderHook } from "@testing-library/react";
import { useChatBlockState } from "./useChatBlockState";

const mockBlockStatus = jest.fn();
jest.mock("../../../store/slices/usersSlice", () => ({
  useGetBlockStatusQuery: (arg: any, opts: any) => mockBlockStatus(arg, opts),
}));

afterEach(() => jest.clearAllMocks());

it("asks with the same argument the info panel uses", () => {
  mockBlockStatus.mockReturnValue({ data: undefined });
  renderHook(() => useChatBlockState("me", "u2"));
  expect(mockBlockStatus).toHaveBeenCalledWith({ userId: "me", targetUserId: "u2" }, { skip: false });
});

it("is blocked when I blocked them", () => {
  mockBlockStatus.mockReturnValue({ data: { data: { isBlocked: true, isBlockedBy: false } } });
  const { result } = renderHook(() => useChatBlockState("me", "u2"));
  expect(result.current).toEqual({ blocked: true, iBlocked: true, blockedMe: false });
});

it("is blocked when they blocked me", () => {
  mockBlockStatus.mockReturnValue({ data: { data: { isBlocked: false, isBlockedBy: true } } });
  const { result } = renderHook(() => useChatBlockState("me", "u2"));
  expect(result.current).toEqual({ blocked: true, iBlocked: false, blockedMe: true });
});

it("is open while loading, on error, and for a chat with myself", () => {
  mockBlockStatus.mockReturnValue({ data: undefined, isError: true });
  expect(renderHook(() => useChatBlockState("me", "u2")).result.current.blocked).toBe(false);
  renderHook(() => useChatBlockState("me", "me"));
  expect(mockBlockStatus).toHaveBeenLastCalledWith(expect.anything(), { skip: true });
});
```

In `ChatContent.test.tsx` add at the top with the other mocks:
```tsx
const mockBlockState = jest.fn();
jest.mock("./lib/useChatBlockState", () => ({
  useChatBlockState: (...args: any[]) => mockBlockState(...args),
}));
```
in `beforeEach`: `mockBlockState.mockReturnValue({ blocked: false, iBlocked: false, blockedMe: false });` and append:
```tsx
describe("blocked chats (chat#17)", () => {
  it("replaces the composer with a banner when they blocked me, without saying who blocked whom", () => {
    mockBlockState.mockReturnValue({ blocked: true, iBlocked: false, blockedMe: true });
    renderChat("/chat/u2");
    expect(screen.getByTestId("blocked-chat-banner")).toHaveTextContent("You can't send messages in this chat.");
    expect(screen.queryByPlaceholderText("Message...")).toBeNull();
    expect(screen.queryByTestId("blocked-chat-banner-manage")).toBeNull();
  });

  it("tells me I blocked them and opens chat info to undo it", () => {
    mockBlockState.mockReturnValue({ blocked: true, iBlocked: true, blockedMe: false });
    renderChat("/chat/u2");
    expect(screen.getByTestId("blocked-chat-banner")).toHaveTextContent("You blocked this person");
    fireEvent.click(screen.getByTestId("blocked-chat-banner-manage"));
    expect(screen.getByTestId("chat-info-panel")).toBeInTheDocument();
  });

  it("keeps the composer when nobody blocked anybody", () => {
    renderChat("/chat/u2");
    expect(screen.queryByTestId("blocked-chat-banner")).toBeNull();
    expect(messageBox()).toBeInTheDocument();
  });

  it("asks about this pair", () => {
    renderChat("/chat/u2");
    expect(mockBlockState).toHaveBeenCalledWith("me", "u2");
  });
});
```
In `ChatContent.pagination.test.tsx` add (no state needed there):
```tsx
jest.mock("./lib/useChatBlockState", () => ({
  useChatBlockState: () => ({ blocked: false, iBlocked: false, blockedMe: false }),
}));
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false useChatBlockState ChatContent
```
Expected: the hook module is missing (both ChatContent suites fail to resolve the mocked path until it exists — create
an empty `export function useChatBlockState() { return { blocked: false, iBlocked: false, blockedMe: false }; }` first
if you want the ChatContent cases to fail on behaviour: then no banner is found).

- [ ] **Step 3: Implement**

3a. Create `src/components/chat/lib/useChatBlockState.ts`:
```ts
import { useGetBlockStatusQuery } from "../../../store/slices/usersSlice";

export interface ChatBlockState {
  /** Either side blocked the other: nothing can be sent. */
  blocked: boolean;
  iBlocked: boolean;
  blockedMe: boolean;
}

/**
 * Whether this chat is blocked, the app's check on open
 * (chat_conversation_screen.dart _checkBlockStatus). Same argument as
 * ChatInfoPanel, so the two share one cache entry, and block/unblock
 * invalidate it ("User"). Loading or failing counts as open: the server
 * still refuses a blocked send, and P3-CHAT-4 shows that refusal.
 */
export function useChatBlockState(viewerId?: string, partnerId?: string): ChatBlockState {
  const skip = !viewerId || !partnerId || viewerId === partnerId;
  const { data } = useGetBlockStatusQuery({ userId: viewerId, targetUserId: partnerId }, { skip: skip });
  const status: any = (!skip && data && data.data) || {};
  const iBlocked = status.isBlocked === true;
  const blockedMe = status.isBlockedBy === true;
  return { blocked: iBlocked || blockedMe, iBlocked: iBlocked, blockedMe: blockedMe };
}

export default useChatBlockState;
```

3b. Create `src/components/chat/components/BlockedChatBanner.tsx`:
```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { Ban } from "lucide-react";

interface BlockedChatBannerProps {
  iBlocked: boolean;
  onManage?: () => void;
}

/**
 * Takes the composer's place in a blocked chat, like the app's
 * _BlockedBanner. "They blocked you" is never said outright (the app's
 * wording is "User may be blocked"); a block the viewer made says so and
 * offers the way back.
 */
const BlockedChatBanner: React.FC<BlockedChatBannerProps> = ({ iBlocked, onManage }) => {
  const { t } = useTranslation();
  return (
    <div className="blocked-chat-banner" role="status" data-testid="blocked-chat-banner">
      <Ban size={16} aria-hidden="true" />
      <span className="blocked-chat-banner-text">
        {iBlocked
          ? t("chatPage.blocked.byMe") || "You blocked this person. Unblock them to send messages."
          : t("chatPage.blocked.generic") || "You can't send messages in this chat."}
      </span>
      {iBlocked && onManage ? (
        <button
          type="button"
          className="blocked-chat-banner-action"
          data-testid="blocked-chat-banner-manage"
          onClick={onManage}
        >
          {t("chatPage.blocked.manage") || "Manage"}
        </button>
      ) : null}
    </div>
  );
};

export default BlockedChatBanner;
```

3c. `ChatContent.tsx`:
- imports:
  ```tsx
  import BlockedChatBanner from "./components/BlockedChatBanner";
  import { useChatBlockState } from "./lib/useChatBlockState";
  ```
- after `const openStory = useOpenStoryFromChat();` add `const blockState = useChatBlockState(userId, selectedUser);`
- replace the composer opener
  ```tsx
      {/* Message Input */}
      {!isRecording && (
        <div className="modern-chat-input">
  ```
  with
  ```tsx
      {/* Message Input — or, in a blocked chat, the banner that replaces it. */}
      {blockState.blocked ? (
        <BlockedChatBanner iBlocked={blockState.iBlocked} onManage={() => setIsInfoOpen(true)} />
      ) : !isRecording && (
        <div className="modern-chat-input">
  ```
  (the block's closing `)}` stays as it is).
- the voice-recording bar condition `{isRecording && (` becomes `{isRecording && !blockState.blocked && (`, and in
  the "Clear state when switching conversations" effect nothing changes (the hook re-keys on `selectedUser`).

3d. Append to `ChatContent.css`:
```css
/* Blocked chat banner (chat#17) — where the composer would be. */
.blocked-chat-banner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 16px;
  background: var(--chat-surface);
  border-block-start: 1px solid var(--chat-line);
  color: var(--chat-muted);
  font-size: 14px;
  text-align: center;
}

.blocked-chat-banner-action {
  margin-inline-start: 8px;
  padding: 4px 10px;
  background: transparent;
  border: 1px solid var(--chat-line);
  border-radius: 999px;
  color: var(--chat-text);
  font-size: 13px;
  cursor: pointer;
}

.blocked-chat-banner-action:hover {
  background: var(--chat-hover);
}
```

3e. `STRICT_FILES` += `"components/BlockedChatBanner.tsx",`.

3f. `eng.json` `chatPage`:
```json
"blocked": {
  "byMe": "You blocked this person. Unblock them to send messages.",
  "generic": "You can't send messages in this chat.",
  "manage": "Manage"
}
```

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false useChatBlockState ChatContent ChatInfoPanel chatStyling chatTokens
```

- [ ] **Step 5: Commit**

```bash
git add src/components/chat/lib/useChatBlockState.ts src/components/chat/lib/useChatBlockState.test.tsx \
  src/components/chat/components/BlockedChatBanner.tsx src/components/chat/ChatContent.tsx \
  src/components/chat/ChatContent.test.tsx src/components/chat/ChatContent.pagination.test.tsx \
  src/components/chat/ChatContent.css src/components/chat/chatStyling.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(chat): blocked chats show a banner instead of the composer

The app checks block status when a chat opens and replaces the input with
a banner; the web let people type into a chat the server would refuse.
Either side's block now replaces the composer with a banner. A block the
viewer made says so and opens chat info to undo it; one made against the
viewer is worded neutrally, as in the app. Unblocking lifts the banner
live (shared block-status cache).

Still open (Phase 3 chat): i18n sweep.
EOF
```

---

### Task P3-CHAT-20: The chat's remaining hard-coded English goes through `t()` (chat#19)

**Scope:** the literals P3-CHAT-1…9 do not touch (they own the edit/delete dialogs, send-error notices and the
conversation-list previews). If one of the files below was already swept by those tasks, skip the rows it covers.

**Files:**
- Modify: `src/components/chat/UsersList.tsx` (`formatLastSeen` :104-113 and its call :901; loading/error/retry :760-790)
- Modify: `src/components/chat/actions/MessageActionMenu.tsx` (:104-171), `actions/PinnedBar.tsx` (:15-31, :56, :62),
  `actions/ReplyComposerBar.tsx` (:15-31, :43, :52), `actions/ForwardDialog.tsx` (:51, :93-128, :179)
- Modify: `src/components/chat/components/CorrectionCard.tsx` (:44-46, :59, :82, :89), `components/TranslationCard.tsx`
  (:54, :76, :86-120), `components/CorrectionModal.tsx` (:39, :44, :61-117), `src/components/chat/MediaGallery.tsx`
  (:140, :170-243, :258)
- Modify: the four `actions/*.test.tsx` suites that render these without an i18n mock
  (`MessageActionMenu`, `PinnedBar`, `ReplyComposerBar`, `ForwardDialog`)
- Modify: `src/utils/locales/eng.json`
- Test: `src/components/chat/chatI18nGuard.test.ts` (new)

**Interfaces:** none new. Every string keeps its English as the `||` fallback, so behaviour and existing assertions on
English text are unchanged once the suites mock `t` to `""` like every other chat suite.

- [ ] **Step 1: Write the failing guard test** `src/components/chat/chatI18nGuard.test.ts`:

```ts
import fs from "fs";
import path from "path";

/**
 * Every user-visible English string in these chat files must reach the
 * screen through t(): it may appear in the source ONLY as the `|| "…"`
 * fallback after a t() call. A bare JSX text node, a bare attribute value or
 * a bare string returned to the screen fails here (chat#19).
 */
const GUARDED: { [file: string]: string[] } = {
  "UsersList.tsx": ["just now", "Loading chats...", "Error loading conversations", "An unexpected error occurred", "Try Again"],
  "actions/MessageActionMenu.tsx": ["Reply", "Copy", "Forward", "Pin", "Bookmark", "Listen", "Edit", "Delete for everyone"],
  "actions/PinnedBar.tsx": ["Unpin message", "Photo", "Voice message", "Video", "File"],
  "actions/ReplyComposerBar.tsx": ["Cancel reply", "Photo", "Voice message", "Video", "File"],
  "actions/ForwardDialog.tsx": ["Forward to", "Loading conversations…", "No conversations found.", "Unknown"],
  "components/CorrectionCard.tsx": ["Accept correction", "Accepting…", "Failed to accept correction"],
  "components/TranslationCard.tsx": ["Translating…", "Save phrase", "Saved to study queue", "Failed to translate message", "Failed to save phrase", "Close translation"],
  "components/CorrectionModal.tsx": ["Language Correction", "Original Message", "Your Correction", "Send Correction", "Please provide a correction"],
  "MediaGallery.tsx": ["Shared Media", "Loading media...", "Error loading media", "Unknown file", "Unknown size"],
};

const escape = (s: string): string => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

Object.keys(GUARDED).forEach((file) => {
  const source = fs.readFileSync(path.join(__dirname, file), "utf8");
  describe(file, () => {
    it("imports useTranslation", () => {
      expect(source).toMatch(/useTranslation/);
    });
    GUARDED[file].forEach((literal) => {
      it(`shows "${literal}" only as a t() fallback`, () => {
        const all = source.match(new RegExp(`["'\`>]\\s*${escape(literal)}\\s*["'\`<]`, "g")) || [];
        const asFallback = source.match(new RegExp(`\\|\\|\\s*["'\`]${escape(literal)}["'\`]`, "g")) || [];
        expect(all.length).toBe(asFallback.length);
      });
    });
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatI18nGuard
```
Expected: most cases fail (the files have no `useTranslation`; literals are bare).

- [ ] **Step 3: Implement**

Pattern for every file that has no `t` yet:
```tsx
import { useTranslation } from "react-i18next";
// …inside the component, first line:
const { t } = useTranslation();
```
A module-level helper that returns screen text (`formatLastSeen`, `getPreviewText`) takes `t` as a parameter:
`(msg: any, t: (key: string, options?: any) => string)`; callers pass their `t`.

Replacements (each becomes `t("<key>") || "<English>"`, with `{ … }` options where shown):

| File | Literal (today) | Key | Notes |
|---|---|---|---|
| `UsersList.tsx` `formatLastSeen` | `"just now"`, `` `${diffMin}m ago` ``, `` `${diffHours}h ago` `` | `chatPage.justNow`, `chatPage.minutesAgo` `{count}`, `chatPage.hoursAgo` `{count}` | keys exist in eng.json; signature `formatLastSeen(date, t)` |
| `UsersList.tsx` :901 | `` `Last seen ${…}` `` | `chatPage.lastSeen` (exists, "Last seen") | `` `${t("chatPage.lastSeen") \|\| "Last seen"} ${formatLastSeen(lastSeenDate, t)}` `` |
| `UsersList.tsx` | "Loading chats...", "Error loading conversations", "An unexpected error occurred", "Try Again" | `chatPage.list.loading`, `.loadError`, `.unexpectedError`, `.retry` | the server's `data.message` still wins over loadError |
| `MessageActionMenu.tsx` | `aria-label="Close"`, labels Reply/Copy/Forward/Pin/Bookmark/Listen/Edit, `'Delete for everyone' : 'Delete'` | `chatPage.menu.close`, `.reply`, `.copy`, `.forward`, `.pin`, `.bookmark`, `.listen`, `.edit`, `.deleteForEveryone`, `.delete` | `label={t("chatPage.menu.reply") \|\| "Reply"}` |
| `PinnedBar.tsx` | `'📷 Photo'`, `'🎤 Voice message'`, `'🎬 Video'`, `'📎 File'`; `{pinned.length} pinned`; `aria-label="Unpin message"` | `chatPage.preview.photo`, `.voice`, `.video`, `.file`; `chatPage.pinnedBar.count` `{count}`; `chatPage.pinnedBar.unpin` | keep the emoji outside the translated word: `` `📷 ${t("chatPage.preview.photo") \|\| "Photo"}` `` — if P3-CHAT-6 already added preview keys under another name, use those instead |
| `ReplyComposerBar.tsx` | same four previews; `Replying to {name}`; `aria-label="Cancel reply"` | `chatPage.preview.*`; `chatPage.replyBar.replyingTo` `{name}`; `chatPage.replyBar.cancel` | |
| `ForwardDialog.tsx` | "Forward to", `aria-label="Close"`, `placeholder="Search"`, "Loading conversations…", "Couldn't load conversations.", "No conversations found.", `'Unknown'`, `Forward{… (n)}` | `chatPage.forward.title`, `.close`, `.search`, `.loading`, `.error`, `.empty`, `.unknownUser`, `.submit` `{count}` | submit: `selected.size > 0 ? t("chatPage.forward.submitCount", { count: selected.size }) \|\| \`Forward (${selected.size})\` : t("chatPage.forward.submit") \|\| "Forward"` |
| `CorrectionCard.tsx` | `"You"`, `{correctorName} corrected`, "Accepting…", "Accept correction", "Correction accepted — added to your learning record", "Failed to accept correction" | `chatPage.correction.you`, `.corrected` `{name}`, `.accepting`, `.accept`, `.accepted`, `.acceptFailed` | `t("chatPage.correction.corrected", { name: correctorName }) \|\| \`${correctorName} corrected\`` |
| `TranslationCard.tsx` | `Translation · {LANG}`, "Close translation", "Translating…", "Failed to translate message", "Saved to study queue", "Saving…", "Save phrase", "Failed to save phrase" | `chatPage.translation.label` `{lang}`, `.close`, `.translating`, `.failed`, `.saved`, `.saving`, `.save`, `.saveFailed` | server `data.message` still wins over `.failed` |
| `CorrectionModal.tsx` | "Please provide a correction", "The correction should be different from the original", "Language Correction", "Original Message", "Your Correction", both placeholders, "Explanation", "(optional)", the `e.g., …` hint, "Cancel", "Send Correction", close-button (add `aria-label`) | `chatPage.correctionModal.empty`, `.unchanged`, `.title`, `.original`, `.yours`, `.yoursPlaceholder`, `.explanation`, `.optional`, `.explanationPlaceholder`, `.hint`, `.cancel`, `.submit`, `.close` | |
| `MediaGallery.tsx` | "Shared Media" (×3), "Loading media...", "Error loading media", "Photos/Videos/Files", `No {activeTab} shared yet`, "Unknown file", "Unknown size", back button (add `aria-label`) | `chatPage.mediaGallery.title`, `.loading`, `.error`, `.photos`, `.videos`, `.files`, `.emptyPhotos`, `.emptyVideos`, `.emptyFiles`, `.unknownFile`, `.unknownSize`, `.back` | one key per tab for the empty state (no string concatenation of `activeTab`) |

The four `actions/*.test.tsx` suites that render these components without an i18n mock gain, at the top:
```tsx
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
```
so their English assertions (`"2 pinned"`, `"Replying to Aziz"`, `"Delete for everyone"`) keep reading the fallbacks.

Add every key above to `eng.json` under `chatPage` with the English shown in the table (full list at the end of this
section).

- [ ] **Step 4: Run → PASS**

```
cd /Users/davis/Desktop/Personal/wt-web-p3-chat && CI=true npm test -- --watchAll=false chatI18nGuard UsersList MessageActionMenu PinnedBar ReplyComposerBar ForwardDialog MessageBubble ChatContent chatStyling
```

- [ ] **Step 5: Commit**

```bash
git add src/components/chat/chatI18nGuard.test.ts src/components/chat/UsersList.tsx \
  src/components/chat/actions/MessageActionMenu.tsx src/components/chat/actions/MessageActionMenu.test.tsx \
  src/components/chat/actions/PinnedBar.tsx src/components/chat/actions/PinnedBar.test.tsx \
  src/components/chat/actions/ReplyComposerBar.tsx src/components/chat/actions/ReplyComposerBar.test.tsx \
  src/components/chat/actions/ForwardDialog.tsx src/components/chat/actions/ForwardDialog.test.tsx \
  src/components/chat/components/CorrectionCard.tsx src/components/chat/components/TranslationCard.tsx \
  src/components/chat/components/CorrectionModal.tsx src/components/chat/MediaGallery.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): route the chat's remaining English strings through t()

Action menu, pinned bar, reply bar, forward dialog, correction and
translation cards, the correction dialog, the shared-media page, and the
list's last-seen/loading/error text were English in every locale. They now
use chatPage.* keys with the English as fallback; a guard test keeps bare
literals from coming back in these files.

Still open (Phase 3 chat): translations for the new chatPage.* keys in the
17 non-English locales (coordinator i18n task), then the CHAT push.
EOF
```

---

#### Keys added by P3-CHAT-10..20

All under `chatPage` in `src/utils/locales/eng.json`.

| Key | English |
|---|---|
| `call.outgoingVoice` | Outgoing voice call |
| `call.outgoingVideo` | Outgoing video call |
| `call.incomingVoice` | Incoming voice call |
| `call.incomingVideo` | Incoming video call |
| `call.noAnswerVoice` | Voice call · No answer |
| `call.noAnswerVideo` | Video call · No answer |
| `call.missedVoice` | Missed voice call |
| `call.missedVideo` | Missed video call |
| `call.cancelledVoice` | Cancelled voice call |
| `call.cancelledVideo` | Cancelled video call |
| `call.declinedOutgoingVoice` | Voice call declined |
| `call.declinedOutgoingVideo` | Video call declined |
| `call.declinedIncomingVoice` | Declined voice call |
| `call.declinedIncomingVideo` | Declined video call |
| `call.busy` | {{name}} was on another call |
| `location.title` | Location |
| `location.open` | Open in Maps |
| `location.share` | Share location |
| `location.confirmTitle` | Share your location? |
| `location.send` | Send |
| `location.cancel` | Cancel |
| `location.unsupported` | This browser can't share a location |
| `location.denied` | Location permission was denied |
| `location.failed` | Couldn't get your location |
| `location.sendFailed` | Couldn't send your location |
| `wave.hi` | Hi! |
| `story.shared` | Shared a story |
| `story.youShared` | You shared a story |
| `story.replied` | Replied to your story |
| `story.youReplied` | You replied to their story |
| `story.unavailable` | This story is no longer available |
| `forwarded` | Forwarded |
| `editedLabel` | edited |
| `wallpaper.premiumInUse` | This chat uses a Premium wallpaper from the app. Choosing another one changes it for both of you. |
| `search.open` | Search messages |
| `search.title` | Search messages with {{name}} |
| `search.close` | Close |
| `search.placeholder` | Search this chat |
| `search.hint` | Type at least 2 characters |
| `search.searching` | Searching… |
| `search.empty` | No messages found |
| `search.unavailable` | Search isn't available right now |
| `search.you` | You |
| `search.notLoaded` | That message is further back. Scroll up to load it. |
| `bookmarks.title` | Saved messages |
| `bookmarks.close` | Close |
| `bookmarks.loading` | Loading saved messages… |
| `bookmarks.error` | Couldn't load saved messages |
| `bookmarks.empty` | No saved messages yet |
| `bookmarks.attachment` | Attachment |
| `bookmarks.open` | Open chat |
| `bookmarks.remove` | Remove from saved |
| `bookmarks.removed` | Removed from saved messages |
| `bookmarks.removeFailed` | Couldn't remove it |
| `bookmarks.added` | Saved |
| `bookmarks.addFailed` | Couldn't save the message |
| `mute.title` | Mute {{name}}? |
| `mute.oneHour` | For 1 hour |
| `mute.eightHours` | For 8 hours |
| `mute.oneWeek` | For 1 week |
| `mute.always` | Until I turn it back on |
| `mute.cancel` | Cancel |
| `archive.archive` | Archive chat |
| `archive.unarchive` | Unarchive chat |
| `archive.archived` | Archived on the website. The app still shows it. |
| `archive.unarchived` | Moved back to your chats |
| `archive.failed` | Couldn't update the archive |
| `archive.toggle` | Archived ({{count}}) |
| `archive.back` | Back to chats |
| `blocked.byMe` | You blocked this person. Unblock them to send messages. |
| `blocked.generic` | You can't send messages in this chat. |
| `blocked.manage` | Manage |
| `list.loading` | Loading chats... |
| `list.loadError` | Error loading conversations |
| `list.unexpectedError` | An unexpected error occurred |
| `list.retry` | Try Again |
| `menu.close` | Close |
| `menu.reply` | Reply |
| `menu.copy` | Copy |
| `menu.forward` | Forward |
| `menu.pin` | Pin |
| `menu.bookmark` | Bookmark |
| `menu.listen` | Listen |
| `menu.edit` | Edit |
| `menu.delete` | Delete |
| `menu.deleteForEveryone` | Delete for everyone |
| `preview.photo` | Photo |
| `preview.voice` | Voice message |
| `preview.video` | Video |
| `preview.file` | File |
| `pinnedBar.count` | {{count}} pinned |
| `pinnedBar.unpin` | Unpin message |
| `replyBar.replyingTo` | Replying to {{name}} |
| `replyBar.cancel` | Cancel reply |
| `forward.title` | Forward to |
| `forward.close` | Close |
| `forward.search` | Search |
| `forward.loading` | Loading conversations… |
| `forward.error` | Couldn't load conversations. |
| `forward.empty` | No conversations found. |
| `forward.unknownUser` | Unknown |
| `forward.submit` | Forward |
| `forward.submitCount` | Forward ({{count}}) |
| `correction.you` | You |
| `correction.corrected` | {{name}} corrected |
| `correction.accepting` | Accepting… |
| `correction.accept` | Accept correction |
| `correction.accepted` | Correction accepted — added to your learning record |
| `correction.acceptFailed` | Failed to accept correction |
| `translation.label` | Translation · {{lang}} |
| `translation.close` | Close translation |
| `translation.translating` | Translating… |
| `translation.failed` | Failed to translate message |
| `translation.saved` | Saved to study queue |
| `translation.saving` | Saving… |
| `translation.save` | Save phrase |
| `translation.saveFailed` | Failed to save phrase |
| `correctionModal.title` | Language Correction |
| `correctionModal.close` | Close |
| `correctionModal.original` | Original Message |
| `correctionModal.yours` | Your Correction |
| `correctionModal.yoursPlaceholder` | Type the corrected version... |
| `correctionModal.explanation` | Explanation |
| `correctionModal.optional` | (optional) |
| `correctionModal.explanationPlaceholder` | Explain why this correction is helpful... |
| `correctionModal.hint` | e.g., "Use 'went' instead of 'goed' - irregular past tense" |
| `correctionModal.empty` | Please provide a correction |
| `correctionModal.unchanged` | The correction should be different from the original |
| `correctionModal.cancel` | Cancel |
| `correctionModal.submit` | Send Correction |
| `mediaGallery.title` | Shared Media |
| `mediaGallery.back` | Back |
| `mediaGallery.loading` | Loading media... |
| `mediaGallery.error` | Error loading media |
| `mediaGallery.photos` | Photos |
| `mediaGallery.videos` | Videos |
| `mediaGallery.files` | Files |
| `mediaGallery.emptyPhotos` | No photos shared yet |
| `mediaGallery.emptyVideos` | No videos shared yet |
| `mediaGallery.emptyFiles` | No files shared yet |
| `mediaGallery.unknownFile` | Unknown file |
| `mediaGallery.unknownSize` | Unknown size |

Pre-existing keys reused (no translation work): `chatPage.justNow`, `chatPage.minutesAgo`, `chatPage.hoursAgo`,
`chatPage.lastSeen`.


### Task P3-CHAT-I18N: The chat unit's new strings in all 18 locales

**Files:**
- Create: `scripts/i18n/new-keys.js`, `src/utils/locales/p3Keys.test.ts`
- Create: `scripts/i18n/keys/2026-10-16-p3-chat.json` (all 18 locales; the durable record of what this unit translated)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: every English string the unit's tasks added to `eng.json` — listed in the two key tables at the end of P3-CHAT-9 (`#### Keys added by P3-CHAT-1..9`) and P3-CHAT-20 (`#### Keys added by P3-CHAT-10..20`, keys relative to `chatPage`). The script below finds them from the diff against `web/p3-base`, so a key a task added but forgot to list is still caught.
- Produces: no English-only key in this unit's push.

**Shared tooling (created by P3-CHAT-I18N; MOMENTS, COMMUNITY and LINKS copy the two files verbatim if their branch was cut before the CHAT push, so the later rebase sees identical content):**

`scripts/i18n/new-keys.js`:

```js
#!/usr/bin/env node
/* eslint-disable */
// List the eng.json strings that are new or changed since <baseRef>, as a
// keys file for scripts/i18n/merge-keys.js: { eng: {...}, kor: {...}, ... }.
// English values are filled in; every other locale gets the value already in
// <out.json> (re-runs keep finished translations) or "" for the translator.
//
// Usage: node scripts/i18n/new-keys.js <baseRef> <out.json>
const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const [, , baseRef, out] = process.argv;
if (!baseRef || !out) {
  console.error("usage: node scripts/i18n/new-keys.js <baseRef> <out.json>");
  process.exit(1);
}
const dir = path.join(__dirname, "..", "..", "src", "utils", "locales");
const leaves = (obj, prefix = "", acc = {}) => {
  for (const [k, v] of Object.entries(obj || {})) {
    const key = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === "object" && !Array.isArray(v)) leaves(v, key, acc);
    else acc[key] = v;
  }
  return acc;
};
const nest = (pairs) => {
  const root = {};
  for (const [key, value] of pairs) {
    const parts = key.split(".");
    let node = root;
    for (const p of parts.slice(0, -1)) node = node[p] = node[p] || {};
    node[parts[parts.length - 1]] = value;
  }
  return root;
};

const base = leaves(JSON.parse(execSync(`git show ${baseRef}:src/utils/locales/eng.json`, { encoding: "utf8" })));
const cur = leaves(JSON.parse(fs.readFileSync(path.join(dir, "eng.json"), "utf8")));
const changed = Object.keys(cur).filter((k) => typeof cur[k] === "string" && base[k] !== cur[k]).sort();
const prev = fs.existsSync(out) ? JSON.parse(fs.readFileSync(out, "utf8")) : {};
const codes = fs.readdirSync(dir).filter((f) => f.endsWith(".json")).map((f) => f.replace(/\.json$/, ""));

const result = {};
for (const code of codes) {
  const had = leaves(prev[code]);
  result[code] = nest(changed.map((k) => [k, code === "eng" ? cur[k] : had[k] || ""]));
}
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, JSON.stringify(result, null, 2) + "\n");
console.log(`${changed.length} new or changed keys -> ${out}`);
```

`src/utils/locales/p3Keys.test.ts`:

```ts
// Every key a Phase 3 unit added (scripts/i18n/keys/2026-10-16-p3-*.json,
// written by scripts/i18n/new-keys.js) exists in all 18 locale files, is not
// empty, and keeps the English placeholders ({{name}}, {{count}}).
import fs from "fs";
import path from "path";

const keysDir = path.join(__dirname, "../../../scripts/i18n/keys");
const keyFiles = fs.existsSync(keysDir)
  ? fs.readdirSync(keysDir).filter((f) => /^2026-10-16-p3-[a-z]+\.json$/.test(f))
  : [];
const localeFiles = fs.readdirSync(__dirname).filter((f) => f.endsWith(".json"));

const leaves = (obj: any, prefix = "", acc: { [k: string]: any } = {}) => {
  Object.keys(obj || {}).forEach((k) => {
    const v = obj[k];
    const key = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === "object" && !Array.isArray(v)) leaves(v, key, acc);
    else acc[key] = v;
  });
  return acc;
};
const lookup = (obj: any, key: string) =>
  key.split(".").reduce((node: any, part) => (node && typeof node === "object" ? node[part] : undefined), obj);
const placeholders = (s: string) =>
  (s.match(/\{\{\s*[\w.]+\s*\}\}/g) || []).map((p) => p.replace(/\s/g, "")).sort();

it("has 18 locale files", () => {
  expect(localeFiles).toHaveLength(18);
});

keyFiles.forEach((file) => {
  describe(file, () => {
    const keys = JSON.parse(fs.readFileSync(path.join(keysDir, file), "utf8"));
    const english = leaves(keys.eng);

    it("lists at least one key", () => {
      expect(Object.keys(english).length).toBeGreaterThan(0);
    });

    localeFiles.forEach((locale) => {
      it(`${locale}: every key present, non-empty, same placeholders`, () => {
        const data = JSON.parse(fs.readFileSync(path.join(__dirname, locale), "utf8"));
        const problems: string[] = [];
        Object.keys(english).forEach((key) => {
          const value = lookup(data, key);
          if (typeof value !== "string" || !value.trim()) problems.push(`${key}: missing`);
          else if (placeholders(value).join() !== placeholders(String(english[key])).join())
            problems.push(`${key}: placeholders differ`);
        });
        expect(problems).toEqual([]);
      });
    });
  });
});
```

**Translation rules:** keep `{{…}}` placeholders verbatim; keep i18next plural suffixes (`_one`/`_other`) and add the language's extra forms where it has them (`ar`: `_zero`, `_two`, `_few`, `_many`); for `ja`, `kor`, `zho`, `zh_TW`, `th`, `vi`, `id` the `_one` value may equal `_other`. Tone and terminology: follow `docs/l10n/2026-09-23-native-pass-*.md`. Brand name "BananaTalk" is never translated.


- [ ] **Step 1: Write the failing test** (the guard above) and generate the keys file

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat
node scripts/i18n/new-keys.js web/p3-base scripts/i18n/keys/2026-10-16-p3-chat.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: the script prints `N new or changed keys` (N matches the unit's key tables, give or take keys a task added beyond its table); the test FAILS with `<key>: missing` for each of the 17 non-English locales.

- [ ] **Step 2: Translate**

Fill every `""` in `scripts/i18n/keys/2026-10-16-p3-chat.json` for the 17 non-English locales (rules above). Re-running `new-keys.js` keeps what is already filled.

- [ ] **Step 3: Merge into the locale files**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p3-chat.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: all `p3Keys` cases pass; the existing `src/utils/i18n*.test.ts` suites stay green (locale chunks still parse).

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/new-keys.js src/utils/locales/p3Keys.test.ts scripts/i18n/keys/2026-10-16-p3-chat.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
i18n(chat): translate the Phase 3 chat strings into all 18 locales

Keys found by scripts/i18n/new-keys.js against web/p3-base and merged
with merge-keys.js; p3Keys.test.ts fails on any missing, empty or
placeholder-mismatched translation.

Still open (Phase 3 chat): push gate (P3-CHAT-PUSH); native review of
the new strings.
EOF
```

---
### Task P3-CHAT-PUSH: Push unit CHAT (1 of 4) — full suite + build green, then the coordinator pushes

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status line, §6 changelog line, §3 production-QA lines for the smoke list below)

- [ ] **Step 1: Every task in the unit is committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-chat
git status --short                                   # expect: nothing (except the node_modules symlink, untracked)
grep -n "P3-CHAT-" docs/REMAINING_WORK.md | grep -c "\[ \]"   # expect: 1 (this PUSH line only)
```

- [ ] **Step 2: Rebase onto the live site**

```bash
git fetch origin
git rebase origin/main
```
Conflicts: none expected (first push). If `origin/main` moved since `web/p3-base` (a hotfix), conflicts can only be in `eng.json` or `docs/REMAINING_WORK.md`: keep both sides' keys/lines.
After resolving: `git rebase --continue`, then re-run `CI=true npm test -- --watchAll=false p3Keys` (keys from earlier units must still be complete).

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `Test Suites: … 0 failed`, `Tests: … 0 failed`; passed count ≥ the previous push's count plus this unit's new tests (baseline before Phase 3: 3190 passed, 6 skipped). Any failure: fix in a new commit (never `--no-verify`, never skip a test to get green).

- [ ] **Step 4: Production build**

```bash
npm run build 2>&1 | tail -20
```
Expected: `Compiled successfully` or `Compiled with warnings` with **no** TypeScript error (TS 3.7 rejects newer syntax here first), then the prerender step finishes without an error line. Optional: `npm run test:budget` and note the first-paint size in the tracker (the budget is already over by ~5 KB; not a gate).

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P3-CHAT-PUSH`; §1 Status: "Phase 3 chat pushed (YYYY-MM-DD)"; §6 Done: one line naming the unit's fixes; §3 Production QA: one `- [ ]` line per smoke item below that is not yet checked.

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: Phase 3 chat ready to deploy

Still open (Phase 3): the remaining units' tasks; production smoke
for chat (docs/REMAINING_WORK.md §3); device QA rows.
EOF
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p3-chat:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/            # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1   # a new bundle hash
```

- [ ] **Step 7: Production smoke (two accounts: one on the web, one in app 2.6.1)**

  - [ ] Web user A + app user B (app 2.6.1 on a phone). A opens B's profile → Message: no "Conversation started" bubble appears on B's phone; the thread opens empty.
  - [ ] A edits a message within 15 min → B sees the edit; after 15 min the dialog says it's too late.
  - [ ] A deletes for everyone → B's bubble becomes "This message was deleted"; reload on web: it stays gone.
  - [ ] B sends a location, a call ends (B calls A in the app), B waves at A → A sees a map card, a call card and a greeting card (not "File", not giant text).
  - [ ] B shares a story to A, replies to A's story → A sees the story card / reference; tapping opens the stories.
  - [ ] Throttle A's network to "Slow 3G" in DevTools and send → a slow ack shows Failed + Retry, B receives exactly one copy.
  - [ ] Close A's laptop lid for 2 min while B sends 3 messages and a voice note → on wake A's list and thread show all of them without reopening.
  - [ ] A records a voice note in Safari and in Chrome → plays on web and in the iOS app (QA sheet row).
  - [ ] Conversation list: unread badge counts 5 texts from B as 5; a chat deleted in the app stays deleted on web.

Record results in `docs/REMAINING_WORK.md` §3 in the next unit's first commit (or a docs-only commit if this is the last unit). A failure that breaks a live flow → Step 8.

- [ ] **Step 8 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p3-chat-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -40
CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(The unit is a linear series after the rebase, so the range revert is clean. Note the revert in §6 and reopen the tasks.)

---

## Unit MOMENTS (push 2 of 4) — P3-MOM-1 … P3-MOM-20, P3-MOM-I18N, P3-MOM-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p3-moments`, branch `web/p3-moments` (from `web/p3-base`). One implementer,
tasks in number order: 1–11 moments and comments, 12–20 stories. P3-MOM-5 generalises `ReportMomentDialog`
(`{type: "moment"|"comment"|"story", targetId, authorId, onClose}`) and widens `blockUser`'s tags; P3-MOM-14 builds on
both. P3-MOM-10 reuses CHAT's `src/utils/recorderMime.ts`.

Unit-level facts:
- `eng.json` has `"moments": "Moments"` (a string), so `moments.*` keys can never resolve; every new moments string goes
  under `moments_section.*` (P3-MOM-11 moves the 7 `moments.saved.*` keys there). Stories strings go under the existing
  `stories` object.
- Accepted gap (moments#3): stickers on web text stories stay invisible to app 2.6.1 until 2.7.0; the web keeps offering
  them.
- App follow-ups found while planning (add to the app's `docs/REMAINING_WORK.md` when this unit lands, in the PUSH
  task's tracker commit, as a cross-repo note): the app viewer places overlays/mentions with approximate pixel offsets
  (`viewer_overlay_layer.dart:111-112`, `story_viewer_screen.dart:338-339`) instead of the exact centre the wire
  contract defines; the app parses `allowReplies`/`allowSharing` but no screen honours them.

### Conventions for P3-MOM-1..11 (read once)

- Worktree: `/Users/davis/Desktop/Personal/wt-web-p3-moments`, branch `web/p3-moments`, cut from `web/p3-base` (Task P3-0; = fba6208 + the tracker commit). All paths below are relative to it. All line numbers are from fba6208. Anchor every edit on the quoted code, not on the number.
- Test command: `cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false <pattern>`.
- TypeScript is 3.7.2. Don't use `import type`, `satisfies`, template literal types or `export * as`. `?.` and `??` are fine.
- **i18n root.** In `src/utils/locales/eng.json`, `"moments"` is a **string** (`"Moments"`, which the navbar reads via `t("moments")`). So `t("moments.saved.title")` can never resolve. That is why the Saved page is English in every language today. Every new moments string therefore goes under **`moments_section.*`**, and task 11 moves the 7 `moments.saved.*` keys to `moments_section.saved.*`. Strings use `t("moments_section.<area>.<key>") || "English"`. The English goes into `eng.json` in the same commit. The 17 translations come in the coordinator's i18n task.
- Tests mock `react-i18next` with `t: () => ""` (the English fallback renders) or `t: (k) => k` (`SingleMoment.test.tsx`). Keep both working.
- Commits have no Co-Authored-By and no AI attribution. Each commit ticks its own `- [ ] P3-MOM-N` line in `docs/REMAINING_WORK.md`. The coordinator's unit preamble splits the coarse "Phase 3 Moments" line into per-task lines first.

---

### Task P3-MOM-1: Post and save photo-, video- or voice-only moments (moments#4)

**Files:**
- Modify: `src/components/moments/CreateMoment.tsx:171-173` (enable rule), `:257-346` (submit: empty-caption failure path), `:12-17` (import `useDeleteMomentMutation`)
- Modify: `src/components/profile/EditMyMoment.tsx:139-141` (canSubmit), `:170-207` (upload order), `:266-275` (`required`)
- Test: `src/components/moments/CreateMoment.test.tsx` (extend), `src/components/profile/EditMyMoment.test.tsx` (extend + update one test)

**Interfaces:**
- Consumes (backend, deployed): `createMomentValidation` makes `description` optional (`validators/momentValidator.js:41-47`: "a photo/video/voice-only moment has no caption, and its media are uploaded after this request"). `updateMoment` refuses to clear the caption only when the moment has no images, video or audio (`controllers/moments.js:856-865`, `hasMomentContent`). It checks the images **stored before** the request, so a new photo must be uploaded before the caption is cleared.
- Produces: nothing exported. Behaviour: Share is enabled when there is a caption, **or** when the active mode has media attached. In text mode a caption is always needed. If the caption is empty and the media upload fails, the empty moment is deleted. The user sees "nothing was posted" and stays in the composer. A moment with no caption and no media would otherwise sit in the feed.

- [ ] **Step 1: Write the failing tests**

Append to `src/components/moments/CreateMoment.test.tsx`. Also add `useDeleteMomentMutation` to the existing `jest.mock("../../store/slices/momentsSlice", ...)` factory, and the `toast` import used below:

```tsx
// --- in the existing momentsSlice mock factory, add: ---
//   useDeleteMomentMutation: () => [mockDelete],
// --- and next to `const mockUpload = jest.fn();` add: ---
//   const mockDelete = jest.fn();
// --- in beforeEach add: ---
//   mockDelete.mockReturnValue({ unwrap: () => Promise.resolve({}) });

import { toast } from "react-toastify";

describe("media-only moments (moments#4)", () => {
  const originalCreate = (URL as any).createObjectURL;
  const originalRevoke = (URL as any).revokeObjectURL;
  beforeAll(() => {
    // jsdom has no object URLs; the composer previews every picked file.
    (URL as any).createObjectURL = jest.fn(() => "blob:preview");
    (URL as any).revokeObjectURL = jest.fn();
  });
  afterAll(() => {
    (URL as any).createObjectURL = originalCreate;
    (URL as any).revokeObjectURL = originalRevoke;
  });

  const pickPhoto = (container: HTMLElement) => {
    const input = container.querySelector('input[type="file"][accept="image/*"]') as HTMLInputElement;
    fireEvent.change(input, {
      target: { files: [new File(["x"], "a.jpg", { type: "image/jpeg" })] },
    });
  };

  it("shares a photo with no caption", async () => {
    const { container } = renderCreate();
    expect(screen.getByRole("button", { name: "Share" })).toBeDisabled();
    pickPhoto(container);
    expect(screen.getByRole("button", { name: "Share" })).not.toBeDisabled();
    share();
    await waitFor(() => expect(mockUpload).toHaveBeenCalled());
    expect(payload().description).toBe("");
    expect(mockUpload.mock.calls[0][0].momentId).toBe("new1");
    expect(mockDelete).not.toHaveBeenCalled();
  });

  it("shares a video with no caption", async () => {
    const { container } = renderCreate();
    fireEvent.click(screen.getByRole("button", { name: /Video/ }));
    const input = container.querySelector('input[type="file"][accept="video/*"]') as HTMLInputElement;
    fireEvent.change(input, { target: { files: [new File(["v"], "v.mp4", { type: "video/mp4" })] } });
    expect(screen.getByRole("button", { name: "Share" })).not.toBeDisabled();
  });

  it("a text moment still needs words, background or not", () => {
    renderCreate();
    fireEvent.click(screen.getByRole("button", { name: /Text/ }));
    fireEvent.click(screen.getByLabelText("gradient_ocean"));
    expect(screen.getByRole("button", { name: "Share" })).toBeDisabled();
  });

  it("a failed upload of a caption-less moment deletes it and stays in the composer", async () => {
    mockUpload.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
    const { container } = renderCreate();
    pickPhoto(container);
    share();
    await waitFor(() => expect(mockDelete).toHaveBeenCalledWith("new1"));
    expect(toast.error).toHaveBeenCalled();
    expect(toast.warn).not.toHaveBeenCalled();
    // Still here, the photo still attached, ready to retry.
    expect(screen.getByRole("button", { name: "Share" })).not.toBeDisabled();
  });

  it("a failed upload WITH a caption keeps the moment and warns, as before", async () => {
    mockUpload.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
    const { container } = renderCreate();
    describe_("Busan");
    pickPhoto(container);
    share();
    await waitFor(() => expect(toast.warn).toHaveBeenCalled());
    expect(mockDelete).not.toHaveBeenCalled();
  });
});
```

Append to `src/components/profile/EditMyMoment.test.tsx`, and **replace** the existing `it("refuses to save an empty description", ...)` (its `MOMENT` has two photos, so an empty caption is now valid):

```tsx
it("refuses to save an empty description on a moment with no media", async () => {
  renderEditor({ data: { ...MOMENT, imageUrls: [], mediaType: "text" } });
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "  " } });
  expect(screen.getByTestId("edit-moment-save")).toBeDisabled();
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(mockUpdateMoment).not.toHaveBeenCalled());
});

it("clears the caption of a photo moment (moments#4)", async () => {
  renderEditor();
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "" } });
  expect(screen.getByTestId("edit-moment-save")).not.toBeDisabled();
  expect(screen.getByTestId("edit-moment-description")).not.toBeRequired();
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
  expect(mockUpdateMoment.mock.calls[0][0].momentData).toEqual({ description: "" });
});

it("clears the caption of a video moment", async () => {
  renderEditor({
    data: { ...MOMENT, imageUrls: [], mediaType: "video", video: { url: "https://cdn.test/v.mp4" } },
  });
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "" } });
  expect(screen.getByTestId("edit-moment-save")).not.toBeDisabled();
});

it("a text moment that gains photos and loses its caption uploads the photos first", async () => {
  const order: string[] = [];
  mockUploadPhotos.mockImplementation(() => {
    order.push("upload");
    return resolved();
  });
  mockUpdateMoment.mockImplementation(() => {
    order.push("update");
    return resolved();
  });
  const originalCreate = (URL as any).createObjectURL;
  (URL as any).createObjectURL = jest.fn(() => "blob:preview");
  const { container } = renderEditor({ data: { ...MOMENT, imageUrls: [], mediaType: "text" } });
  const input = container.querySelector('input[type="file"]') as HTMLInputElement;
  fireEvent.change(input, { target: { files: [new File(["x"], "a.jpg", { type: "image/jpeg" })] } });
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "" } });
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(order).toEqual(["upload", "update"]));
  (URL as any).createObjectURL = originalCreate;
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false CreateMoment EditMyMoment`
Expected: FAIL.
- "shares a photo with no caption": Share stays disabled.
- "a failed upload of a caption-less moment…": `mockDelete` is never called.
- "clears the caption of a photo moment": save is disabled.
- "uploads the photos first": order is `["update","upload"]`.
- The `not.toBeRequired()` assertion fails.
- The rest pass.

- [ ] **Step 3: Implement**

`src/components/moments/CreateMoment.tsx`. In the import at `:12-17`, add `useDeleteMomentMutation`:

```tsx
import {
  useCreateMomentMutation,
  useDeleteMomentMutation,
  useUploadMomentPhotosMutation,
  useUploadMomentVideoMutation,
  useUploadMomentAudioMutation,
} from "../../store/slices/momentsSlice";
```

After `const [uploadMomentAudio] = useUploadMomentAudioMutation();` (`:117`) add:

```tsx
  const [deleteMoment] = useDeleteMomentMutation();
```

Replace `:171-173`:

```tsx
  useEffect(() => {
    setIsButtonEnabled(description.trim() !== "");
  }, [description]);
```

with:

```tsx
  // A moment is a caption OR media (backend momentValidator + hasMomentContent).
  // Only the active mode's media counts; a text moment always needs words.
  const hasMedia =
    (mediaMode === "photo" && selectedImages.length > 0) ||
    (mediaMode === "video" && selectedVideo !== null) ||
    (mediaMode === "voice" && audioNote !== null);
  useEffect(() => {
    setIsButtonEnabled(description.trim() !== "" || hasMedia);
  }, [description, hasMedia]);
```

In `handleSubmit`, replace the upload `catch` block (`:315-324`):

```tsx
      } catch (uploadError) {
        toast.warn("Posted, but media upload failed — try editing the moment to add it.", {
          autoClose: 4000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        navigate("/moments");
        return;
      }
```

with:

```tsx
      } catch (uploadError) {
        if (description.trim() === "") {
          // Nothing but the media made this a moment: without it the feed
          // would show an empty card. Take it back and let the user retry.
          try {
            await deleteMoment(momentId).unwrap();
          } catch (e) {
            // Best effort; the owner can still delete it from My moments.
          }
          toast.error(
            t("moments_section.create.mediaFailedNothingPosted") ||
              "The upload failed, so nothing was posted. Try again.",
            { autoClose: 4000, hideProgressBar: false, theme: "dark", transition: Bounce }
          );
          return;
        }
        toast.warn(
          t("moments_section.create.mediaFailedPosted") ||
            "Posted, but media upload failed — try editing the moment to add it.",
          { autoClose: 4000, hideProgressBar: false, theme: "dark", transition: Bounce }
        );
        navigate("/moments");
        return;
      }
```

`src/components/profile/EditMyMoment.tsx`. Replace `:139-141`:

```tsx
  // The server requires a description; a title is optional.
  const canSubmit =
    draft.description.trim() !== "" && !scheduleBlocked && !isUpdating && !isUploading;
```

with:

```tsx
  // A moment is a caption OR media: the caption may be cleared while the
  // moment keeps (or is about to gain) a photo, video or voice note.
  const hasMedia = existingImages.length > 0 || selectedImages.length > 0 || hasAvMedia;
  const canSubmit =
    (draft.description.trim() !== "" || hasMedia) && !scheduleBlocked && !isUpdating && !isUploading;
```

In `handleSubmit`, replace the `try { ... }` body (`:190-204`):

```tsx
    try {
      if (Object.keys(changes).length > 0) {
        await updateMoment({ id: momentId, momentData: changes }).unwrap();
      }

      if (selectedImages.length > 0) {
        const upload = new FormData();
        selectedImages.forEach((file) => upload.append("file", file));
        await uploadMomentPhotos({
          momentId: momentId as string,
          imageFiles: upload as any,
        }).unwrap();
      }
```

with:

```tsx
    const uploadPhotos = async () => {
      if (selectedImages.length === 0) return;
      const upload = new FormData();
      selectedImages.forEach((file) => upload.append("file", file));
      await uploadMomentPhotos({
        momentId: momentId as string,
        imageFiles: upload as any,
      }).unwrap();
    };

    try {
      // updateMoment checks the photos ALREADY stored when the caption is
      // cleared, so new photos go up first in that case.
      const clearingCaption = changes.description !== undefined && changes.description === "";
      if (clearingCaption) await uploadPhotos();
      if (Object.keys(changes).length > 0) {
        await updateMoment({ id: momentId, momentData: changes }).unwrap();
      }
      if (!clearingCaption) await uploadPhotos();
```

(Task 9 removes `as any`.) On the description `<textarea>` (`:266-275`), replace `required` with:

```tsx
                  required={!hasMedia}
```

Add to `eng.json` under `moments_section.create`:

```json
"mediaFailedNothingPosted": "The upload failed, so nothing was posted. Try again.",
"mediaFailedPosted": "Posted, but media upload failed — try editing the moment to add it."
```

- [ ] **Step 4: Run → PASS** (same command; the whole `CreateMoment` and `EditMyMoment` files are green).

- [ ] **Step 5: Commit**

```bash
git add src/components/moments/CreateMoment.tsx src/components/moments/CreateMoment.test.tsx \
  src/components/profile/EditMyMoment.tsx src/components/profile/EditMyMoment.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(moments): post and edit photo, video and voice moments without a caption

The backend and the app accept "caption or media"; the web kept Share
disabled until the caption had text and refused to save an app-made photo
moment with its caption cleared. A caption-less moment whose upload fails
is deleted again, so no empty card reaches the feed. Clearing the caption
while adding the first photos uploads the photos first, because
updateMoment checks the stored media.

Still open (Phase 3 moments): app gradients, Title field, owner comment
delete, report/block, saved paging, feed chips, comment GIF/photo/mentions,
leftovers, recorder audio/mp4, i18n, stories tasks (P3-MOM-12+).
EOF
```

---

### Task P3-MOM-2: The app's 20 moment gradients, same colours (moments#5)

**Files:**
- Modify: `src/components/moments/media/momentGradients.ts` (whole file)
- Modify: `src/components/moments/fields/BackgroundField.tsx:3,23`
- Test: `src/components/moments/media/momentGradients.test.ts` (new), `src/components/moments/fields/BackgroundField.test.tsx` (new)

**Interfaces:**
- Consumes:
  - App `lib/providers/provider_models/moments_model.dart:413-434` (`MomentGradients.presets`, ARGB pairs, default `gradient_purple`). The app draws them `topLeft → bottomRight`, which is CSS `135deg`.
  - Backend `lib/momentGradients.js` (the same 20 ids, in the same order; `''` = none).
- Produces:
  - `MOMENT_GRADIENTS: Record<string,string>` (20 keys, in app order).
  - `MOMENT_GRADIENT_KEYS: string[]` (new; the picker order).
  - `DEFAULT_GRADIENT_KEY`.
  - `gradientFor(key?)` (unchanged signature).
  - `BACKEND_VALID_GRADIENTS` is **removed**. Its only importer is `BackgroundField.tsx:3` (verified with grep).

- [ ] **Step 1: Write the failing tests**

`src/components/moments/media/momentGradients.test.ts`:

```ts
import * as gradients from "./momentGradients";
import { MOMENT_GRADIENTS, MOMENT_GRADIENT_KEYS, DEFAULT_GRADIENT_KEY, gradientFor } from "./momentGradients";

// The app's list, in its order (moments_model.dart MomentGradients.presets)
// and the backend's (lib/momentGradients.js) -- one list on three clients.
const APP_KEYS = [
  "gradient_sunset", "gradient_ocean", "gradient_forest", "gradient_purple",
  "gradient_fire", "gradient_midnight", "gradient_candy", "gradient_sky",
  "gradient_neon", "gradient_coral", "gradient_gold", "gradient_nightclub",
  "gradient_arctic", "gradient_peach", "gradient_lavender", "gradient_mint",
  "gradient_rose", "gradient_slate", "gradient_ember", "gradient_lagoon",
];

it("offers exactly the app's 20 gradients, in the app's order", () => {
  expect(MOMENT_GRADIENT_KEYS).toEqual(APP_KEYS);
  expect(Object.keys(MOMENT_GRADIENTS)).toEqual(APP_KEYS);
});

it("uses the app's colours, top-left to bottom-right", () => {
  expect(MOMENT_GRADIENTS.gradient_sunset).toBe("linear-gradient(135deg, #ff512f, #dd2476)");
  expect(MOMENT_GRADIENTS.gradient_forest).toBe("linear-gradient(135deg, #11998e, #38ef7d)");
  expect(MOMENT_GRADIENTS.gradient_nightclub).toBe("linear-gradient(135deg, #8e2de2, #ff6fd8)");
  expect(MOMENT_GRADIENTS.gradient_lagoon).toBe("linear-gradient(135deg, #43c6ac, #191654)");
});

it("defaults to purple for unknown, empty or missing keys", () => {
  expect(DEFAULT_GRADIENT_KEY).toBe("gradient_purple");
  expect(gradientFor("gradient_nope")).toBe(MOMENT_GRADIENTS.gradient_purple);
  expect(gradientFor("")).toBe(MOMENT_GRADIENTS.gradient_purple);
  expect(gradientFor(undefined)).toBe(MOMENT_GRADIENTS.gradient_purple);
});

it("no longer exports the stale 8-key backend list", () => {
  expect((gradients as any).BACKEND_VALID_GRADIENTS).toBeUndefined();
});
```

`src/components/moments/fields/BackgroundField.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { fireEvent, render, screen } from "@testing-library/react";
import BackgroundField from "./BackgroundField";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

it("offers None plus all 20 gradients, including the 7 the web never had", () => {
  render(<BackgroundField value="" onChange={() => undefined} />);
  // None + 20 swatches
  expect(screen.getAllByRole("button")).toHaveLength(21);
  ["gradient_peach", "gradient_lavender", "gradient_mint", "gradient_rose",
   "gradient_slate", "gradient_ember", "gradient_lagoon"].forEach((key) => {
    expect(screen.getByLabelText(key)).toBeInTheDocument();
  });
});

it("reports the chosen key", () => {
  const onChange = jest.fn();
  render(<BackgroundField value="" onChange={onChange} />);
  fireEvent.click(screen.getByLabelText("gradient_lagoon"));
  expect(onChange).toHaveBeenCalledWith("gradient_lagoon");
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false momentGradients BackgroundField`
Expected: FAIL. `MOMENT_GRADIENT_KEYS` is undefined, the colours differ, `BACKEND_VALID_GRADIENTS` is still defined, and there are 9 buttons instead of 21.

- [ ] **Step 3: Implement**

Replace the whole of `src/components/moments/media/momentGradients.ts`:

```ts
// Text/gradient moment backgrounds -- the app's 20 presets, same keys, same
// colours, same order (app lib/providers/provider_models/moments_model.dart
// MomentGradients.presets; backend lib/momentGradients.js holds the same ids).
// The app paints topLeft -> bottomRight, which is CSS 135deg.
// A key this list doesn't know (a future preset) renders as the default.

const css = (from: string, to: string) => `linear-gradient(135deg, ${from}, ${to})`;

export const MOMENT_GRADIENT_KEYS: string[] = [
  "gradient_sunset",
  "gradient_ocean",
  "gradient_forest",
  "gradient_purple",
  "gradient_fire",
  "gradient_midnight",
  "gradient_candy",
  "gradient_sky",
  "gradient_neon",
  "gradient_coral",
  "gradient_gold",
  "gradient_nightclub",
  "gradient_arctic",
  "gradient_peach",
  "gradient_lavender",
  "gradient_mint",
  "gradient_rose",
  "gradient_slate",
  "gradient_ember",
  "gradient_lagoon",
];

export const MOMENT_GRADIENTS: Record<string, string> = {
  gradient_sunset: css("#ff512f", "#dd2476"),
  gradient_ocean: css("#2193b0", "#6dd5ed"),
  gradient_forest: css("#11998e", "#38ef7d"),
  gradient_purple: css("#8e2de2", "#4a00e0"),
  gradient_fire: css("#ff416c", "#ff4b2b"),
  gradient_midnight: css("#0f2027", "#2c5364"),
  gradient_candy: css("#d585ff", "#00ffee"),
  gradient_sky: css("#56ccf2", "#2f80ed"),
  gradient_neon: css("#00f260", "#0575e6"),
  gradient_coral: css("#ff6b6b", "#ee5a24"),
  gradient_gold: css("#f7971e", "#ffd200"),
  gradient_nightclub: css("#8e2de2", "#ff6fd8"),
  gradient_arctic: css("#e0eafc", "#cfdef3"),
  gradient_peach: css("#ffb347", "#ffcc33"),
  gradient_lavender: css("#9d50bb", "#6e48aa"),
  gradient_mint: css("#00b09b", "#96c93d"),
  gradient_rose: css("#f4c4f3", "#fc67fa"),
  gradient_slate: css("#485563", "#29323c"),
  gradient_ember: css("#cb356b", "#bd3f32"),
  gradient_lagoon: css("#43c6ac", "#191654"),
};

export const DEFAULT_GRADIENT_KEY = "gradient_purple";

/** Resolve a gradient preset key to its CSS gradient, falling back to the default. */
export const gradientFor = (key?: string): string => {
  if (key && MOMENT_GRADIENTS[key]) {
    return MOMENT_GRADIENTS[key];
  }
  return MOMENT_GRADIENTS[DEFAULT_GRADIENT_KEY];
};
```

`src/components/moments/fields/BackgroundField.tsx`. Line 3:

```tsx
import { BACKEND_VALID_GRADIENTS, gradientFor } from "../media/momentGradients";
```
→
```tsx
import { MOMENT_GRADIENT_KEYS, gradientFor } from "../media/momentGradients";
```

Line 23, `{BACKEND_VALID_GRADIENTS.map((key: string) => (` → `{MOMENT_GRADIENT_KEYS.map((key: string) => (`. The row already has `overflow-x-auto`, so 20 swatches scroll sideways on a phone.

- [ ] **Step 4: Run → PASS.** Also run `CI=true npm test -- --watchAll=false GradientMomentCard CreateMoment EditMyMoment`. The existing ocean/default assertions read `MOMENT_GRADIENTS`, so they still pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/moments/media/momentGradients.ts src/components/moments/media/momentGradients.test.ts \
  src/components/moments/fields/BackgroundField.tsx src/components/moments/fields/BackgroundField.test.tsx \
  docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(moments): the app's 20 text-moment gradients with the app's colours

The web knew 13 ids and offered 8; the 7 newer app presets drew as the
default purple and 10 shared ids used different colours. The list now
mirrors moments_model.dart exactly (backend lib/momentGradients.js holds
the same ids); the stale 8-key BACKEND_VALID_GRADIENTS is gone.

Still open (Phase 3 moments): Title field, owner comment delete,
report/block, saved paging, feed chips, comment GIF/photo/mentions,
leftovers, recorder audio/mp4, i18n, stories tasks.
EOF
```

---

### Task P3-MOM-3: Remove the Title field from the composer (moments#6)

**Files:**
- Modify: `src/components/moments/CreateMoment.tsx:125` (state), `:268-277` (payload), `:451-464` (input + counter)
- Modify: `src/components/profile/EditMyMoment.tsx:246-261` (title only when the moment already has one)
- Test: `src/components/moments/CreateMoment.test.tsx` (update `:51-70`, add one), `src/components/profile/EditMyMoment.test.tsx` (add one)

**Interfaces:**
- Consumes: the app neither collects nor shows `title` (app `moments_model.dart` never parses it). The backend keeps `title` optional "for backward compat" (`controllers/moments.js:702,756`). `updateMoment` still lets a client edit it (`EDITABLE_FIELDS`).
- Produces:
  - Decision: the composer stops collecting and sending `title`.
  - The editor shows the title field only for a legacy moment that already has one, so its owner can still edit or clear it.
  - Feed and detail keep **displaying** an existing legacy title (`SingleMoment.tsx:424-428`, `MomentDetail.tsx:598-600`). Hiding it would drop words their author wrote, and the backend translator falls back to it (`controllers/moments.js:2030`).

- [ ] **Step 1: Write the failing tests**

In `src/components/moments/CreateMoment.test.tsx`, in `it("posts a plain moment with today's defaults", ...)`, delete the line `title: "",` from the `objectContaining`. After `expect(payload()).not.toHaveProperty("user");` add:

```tsx
  // The app has no title; the composer no longer collects or sends one (moments#6).
  expect(payload()).not.toHaveProperty("title");
```

Add:

```tsx
it("has no Title field (moments#6)", () => {
  renderCreate();
  expect(screen.queryByPlaceholderText("Add a title...")).not.toBeInTheDocument();
  expect(screen.queryByText("0/100")).not.toBeInTheDocument();
});
```

In `src/components/profile/EditMyMoment.test.tsx` add:

```tsx
it("shows no title field for a moment that has no title (moments#6)", () => {
  renderEditor({ data: { ...MOMENT, title: "" } });
  expect(screen.queryByTestId("edit-moment-title")).not.toBeInTheDocument();
});

it("keeps the title field for a legacy moment that has one", () => {
  renderEditor();
  expect(screen.getByTestId("edit-moment-title")).toBeInTheDocument();
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false CreateMoment EditMyMoment`
Expected: FAIL. The payload has `title: ""`, the placeholder exists, and the editor shows the title field for `title: ""`.

- [ ] **Step 3: Implement**

`CreateMoment.tsx`:
- Delete `:125`, `const [title, setTitle] = useState<string>("");`.
- In the payload (`:268-277`), delete the line `title,`.
- Delete the block `:451-464`. It starts at `{/* Title input */}` and runs through the `{title.length}/100` counter `</div>`. The prompt chip (`{answeredPrompt && (`) becomes the first child of the content box.
- In the `Moment` interface (`:52`), leave `title: string;`. It types the server response, which still carries the field.

`EditMyMoment.tsx`. Wrap the title `<div>` (`:246-261`, from `<div>` / `<label className={LABEL} htmlFor="moment-title">` to its closing `</div>`) in:

```tsx
              {/* The app has no title (moments#6). A legacy moment that has
                  one keeps an editable field so its owner can change or clear
                  it; nothing new gets a title from the web. */}
              {original.title.trim() !== "" && (
                <div>
                  {/* ...the existing label + input, unchanged... */}
                </div>
              )}
```

`momentEditDiff` keeps diffing `title`. When the field is hidden it never changes, so nothing is sent.

- [ ] **Step 4: Run → PASS.**

- [ ] **Step 5: Commit**

```bash
git add src/components/moments/CreateMoment.tsx src/components/moments/CreateMoment.test.tsx \
  src/components/profile/EditMyMoment.tsx src/components/profile/EditMyMoment.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(moments): drop the Title field the app never shows

Titles typed on the web were invisible to every app user. The composer
no longer collects or sends one; the editor keeps the field only for a
legacy moment that already has a title, and feed/detail still display
those so no author's words disappear.

Still open (Phase 3 moments): owner comment delete, report/block, saved
paging, feed chips, comment GIF/photo/mentions, leftovers, recorder
audio/mp4, i18n, stories tasks.
EOF
```

---

### Task P3-MOM-4: The moment's owner can delete other people's comments (moments#9)

**Files:**
- Modify: `src/components/moments/comments/CommentList.tsx:35-53` (prop), `:190-197` (pass down)
- Modify: `src/components/moments/comments/RepliesThread.tsx:29-43` (prop), `:95-104` (pass down)
- Modify: `src/components/moments/comments/CommentItem.tsx:52-71` (prop), `:163-184` (confirm for others' comments), `:194-195` (`canDelete`), `:330-341` (render)
- Modify: `src/components/moments/MomentDetail.tsx:777-784` (pass `momentOwnerId`)
- Test: `src/components/moments/comments/CommentItem.test.tsx` (extend), `src/components/moments/comments/CommentList.test.tsx` (extend)

**Interfaces:**
- Consumes: backend `routes/comment.js:24-32`. `deleteComment` allows the comment's author, the **moment's owner** and admins. The app shows Delete to the author and the moment owner (`comments_main.dart:28-34`).
- Produces:
  - `CommentList` gets the prop `momentOwnerId?: string`.
  - `CommentItem` gets the prop `momentOwnerId?: string`.
  - `RepliesThread` gets the prop `momentOwnerId?: string`.
  - Deleting your own comment stays one tap, as today. Deleting someone else's goes through `ConfirmDialog`.

- [ ] **Step 1: Write the failing tests**

Add to `src/components/moments/comments/CommentItem.test.tsx`. Extend `renderItem` so it forwards `momentOwnerId={props.momentOwnerId}` to `<CommentItem>`:

```tsx
describe("delete rights (moments#9)", () => {
  it("the moment's owner can delete someone else's comment, after confirming", async () => {
    renderItem({ myUserId: "owner-1", momentOwnerId: "owner-1" });
    fireEvent.click(screen.getByTestId("comment-delete"));
    // Someone else's words: confirm first.
    expect(mockDeleteComment).not.toHaveBeenCalled();
    fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Delete" }));
    await waitFor(() =>
      expect(mockDeleteComment).toHaveBeenCalledWith({ momentId: "moment-1", commentId: "c-1" })
    );
  });

  it("a viewer who owns neither the comment nor the moment gets no Delete", () => {
    renderItem({ myUserId: "me-1", momentOwnerId: "owner-1" });
    expect(screen.queryByTestId("comment-delete")).not.toBeInTheDocument();
  });

  it("the author still deletes their own comment in one tap", async () => {
    renderItem({
      myUserId: "author-1",
      momentOwnerId: "owner-1",
    });
    fireEvent.click(screen.getByTestId("comment-delete"));
    await waitFor(() => expect(mockDeleteComment).toHaveBeenCalled());
  });

  it("signed out: no Delete even when ids would match", () => {
    renderItem({ myUserId: "", momentOwnerId: "", isLoggedIn: false });
    expect(screen.queryByTestId("comment-delete")).not.toBeInTheDocument();
  });
});
```

Add `within` to the file's `@testing-library/react` import. The row button and the dialog's confirm are both named "Delete", so the confirm is queried inside the dialog (`ConfirmDialog` renders `role="dialog"` via `DialogShell`).

Add to `src/components/moments/comments/CommentList.test.tsx`. It mocks `CommentItem`? Read its top. If it renders the real item, add:

```tsx
it("passes the moment's owner down so the owner sees Delete on others' comments", async () => {
  // ...use the file's existing render helper with myUserId "owner-1" and a
  // comment by "author-1", plus momentOwnerId="owner-1":
  renderList({ myUserId: "owner-1", momentOwnerId: "owner-1" });
  expect(await screen.findByTestId("comment-delete")).toBeInTheDocument();
});
```

Adapt `renderList` to forward `momentOwnerId`, and the fixture comment's `user._id` to `"author-1"`.

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false comments/CommentItem comments/CommentList`
Expected: FAIL. No `comment-delete` appears for the owner.

- [ ] **Step 3: Implement**

`CommentItem.tsx`:
- Add the import `import ConfirmDialog from "../../../design/ConfirmDialog";`.
- In `CommentItemProps`, after `allowReplies?: boolean;`, add:

```tsx
  /** The moment's author: they may remove any comment on their own moment. */
  momentOwnerId?: string;
```

- Destructure `momentOwnerId,` in the component parameters.
- Add the state `const [confirmingDelete, setConfirmingDelete] = useState(false);`.
- Rename the existing `handleDelete` to `runDelete` (same body), and add after it:

```tsx
  const handleDelete = useCallback(() => {
    if (!isLoggedIn) {
      onRequireLogin();
      return;
    }
    // Your own words go in one tap, as before; someone else's need a confirm.
    if (isMine) runDelete();
    else setConfirmingDelete(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoggedIn, onRequireLogin, runDelete, comment.user, myUserId]);
```

  Move `const isMine = ...` (`:195`) above `runDelete` so `handleDelete` can read it. Then add:

```tsx
  const isMomentOwner = !!myUserId && !!momentOwnerId && momentOwnerId === myUserId;
  const canDelete = isMine || isMomentOwner;
```

- Change `{isMine && (` at `:330` to `{canDelete && (`.
- Before the closing `</div></div>` of the component, add:

```tsx
      <ConfirmDialog
        open={confirmingDelete}
        danger
        title={t("moments_section.commentEngagement.deleteOthersTitle") || "Delete this comment?"}
        body={
          t("moments_section.commentEngagement.deleteOthersBody") ||
          "It's on your moment, so you can remove it. This can't be undone."
        }
        confirmLabel={t("moments_section.commentEngagement.delete") || "Delete"}
        cancelLabel={t("moments_section.commentEngagement.cancel") || "Cancel"}
        busy={isDeleting}
        onConfirm={() => {
          setConfirmingDelete(false);
          runDelete();
        }}
        onCancel={() => setConfirmingDelete(false)}
      />
```

- In the `RepliesThread` render (`:387-394`), add `momentOwnerId={momentOwnerId}`.

`RepliesThread.tsx`: add `momentOwnerId?: string;` to `RepliesThreadProps`, destructure it, and pass `momentOwnerId={momentOwnerId}` to the `<CommentItem>` at `:95`.

`CommentList.tsx`: add the following to `CommentListProps`, destructure it, and pass `momentOwnerId={momentOwnerId}` to `<CommentItem>` at `:190`:

```tsx
  /** The moment's author, who may delete any comment on it (moments#9). */
  momentOwnerId?: string;
```

`MomentDetail.tsx`. At the `<CommentList` (`:777`) add:

```tsx
              momentOwnerId={(momentDetails.user && (momentDetails.user._id || momentDetails.user)) || undefined}
```

Add to `eng.json` under `moments_section.commentEngagement`:

```json
"deleteOthersTitle": "Delete this comment?",
"deleteOthersBody": "It's on your moment, so you can remove it. This can't be undone."
```

- [ ] **Step 4: Run → PASS.** Also run `CI=true npm test -- --watchAll=false comments RepliesThread`.

- [ ] **Step 5: Commit**

```bash
git add src/components/moments/comments/CommentItem.tsx src/components/moments/comments/CommentItem.test.tsx \
  src/components/moments/comments/CommentList.tsx src/components/moments/comments/CommentList.test.tsx \
  src/components/moments/comments/RepliesThread.tsx src/components/moments/MomentDetail.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(moments): a moment's owner can remove comments on it

The backend has allowed the moment owner to delete any comment since the
route fix; the web showed Delete only to the comment's author. Removing
someone else's comment asks first; your own stays one tap.

Still open (Phase 3 moments): report/block, saved paging, feed chips,
comment GIF/photo/mentions, leftovers, recorder audio/mp4, i18n, stories
tasks.
EOF
```

---

### Task P3-MOM-5: Report a comment, and block an author from a moment or a comment (moments#10, moment/comment part)

**Files:**
- Modify: `src/components/moments/actions/ReportMomentDialog.tsx` (generic target)
- Create: `src/components/moments/actions/BlockAuthorDialog.tsx`
- Modify: `src/components/moments/actions/MomentOverflowMenu.tsx` (Block item, new dialog props)
- Modify: `src/components/moments/comments/CommentItem.tsx` (⋯ menu: Report, Block)
- Modify: `src/store/slices/usersSlice.ts:274-288` (`blockUser`/`unblockUser` also invalidate `Moments`, `Comments`)
- Test: `src/components/moments/actions/MomentOverflowMenu.test.tsx` (extend, mock `useBlockUserMutation`), `src/components/moments/actions/ReportMomentDialog.test.tsx` (new), `src/components/moments/comments/CommentItem.test.tsx` (extend), `src/components/moments/SingleMoment.test.tsx` (mock only), `src/store/slices/usersEndpoints.test.ts` (extend)

**Interfaces:**
- Consumes:
  - `POST /api/v1/reports` via `useReportUserMutation({type, reportId, reportedUser, reason, description})` (`usersSlice.ts:334`). `models/Report.js:4-8` allows `type` ∈ `user|moment|comment|message|story|gathering|club`.
  - `POST /api/v1/users/:id/block` via `useBlockUserMutation(userId)` (`usersSlice.ts:275`).
  - The backend hides a blocked author's moments (`controllers/moments.js:109-160`) and comments (`controllers/comments.js:22-54`), so a refetch is enough to drop them.
- Produces (**the STORIES fork reuses these; the shapes are fixed**):

```ts
// src/components/moments/actions/ReportMomentDialog.tsx
export type ReportTargetType = "moment" | "comment" | "story";
export interface ReportDialogProps {
  /** What is reported; selects the title and "already reported" copy. */
  type: ReportTargetType;
  /** The reported thing's id (moment, comment or story). */
  targetId: string;
  /** Its author (Report.reportedUser). */
  authorId: string;
  onClose: () => void;
}
export const REPORT_REASONS: string[]; // unchanged
export default ReportMomentDialog;     // React.FC<ReportDialogProps>

// src/components/moments/actions/BlockAuthorDialog.tsx
export interface BlockAuthorDialogProps {
  authorId: string;
  /** Shown in the title; falls back to "this person". */
  authorName?: string;
  onClose: () => void;
  /** Called after the server confirmed the block. */
  onBlocked?: () => void;
}
export default BlockAuthorDialog;      // React.FC<BlockAuthorDialogProps>
```

  `blockUser`/`unblockUser` now invalidate `["User","Conversations","Moments","Comments"]`. Every feed, detail and comment list that is open refetches, and the blocked author's content drops out.

- [ ] **Step 1: Write the failing tests**

`src/components/moments/actions/ReportMomentDialog.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import ReportMomentDialog from "./ReportMomentDialog";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
const mockReport = jest.fn();
jest.mock("../../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [mockReport, { isLoading: false }],
}));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn(), info: jest.fn() },
}));

beforeEach(() => mockReport.mockReturnValue({ unwrap: () => Promise.resolve({}) }));

it.each([
  ["moment", "Report this moment"],
  ["comment", "Report this comment"],
  ["story", "Report this story"],
])("reports a %s with the canonical payload", async (type, title) => {
  render(<ReportMomentDialog type={type as any} targetId="t1" authorId="a1" onClose={() => undefined} />);
  expect(screen.getByText(title)).toBeInTheDocument();
  fireEvent.click(screen.getByLabelText("Spam"));
  fireEvent.click(screen.getByRole("button", { name: "Send report" }));
  await waitFor(() =>
    expect(mockReport).toHaveBeenCalledWith({
      type,
      reportId: "t1",
      reportedUser: "a1",
      reason: "spam",
      description: "",
    })
  );
});

it("says a comment was already reported in comment words", async () => {
  mockReport.mockReturnValue({
    unwrap: () => Promise.reject({ status: 400, data: { error: "You have already reported this" } }),
  });
  render(<ReportMomentDialog type="comment" targetId="c1" authorId="a1" onClose={() => undefined} />);
  fireEvent.click(screen.getByLabelText("Spam"));
  fireEvent.click(screen.getByRole("button", { name: "Send report" }));
  expect(await screen.findByText("You've already reported this comment.")).toBeInTheDocument();
});
```

Extend `src/components/moments/actions/MomentOverflowMenu.test.tsx`. Change the usersSlice mock to:

```tsx
const mockBlock = jest.fn();
jest.mock("../../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [mockReport, { isLoading: false }],
  useBlockUserMutation: () => [mockBlock, { isLoading: false }],
}));
```

and add:

```tsx
it("blocks the author after a confirm", async () => {
  mockBlock.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  renderMenu("me", { _id: "a1", name: "Ann" });
  fireEvent.click(screen.getByRole("button", { name: "More options" }));
  fireEvent.click(screen.getByRole("menuitem", { name: "Block" }));
  expect(screen.getByText("Block Ann?")).toBeInTheDocument();
  expect(mockBlock).not.toHaveBeenCalled();
  fireEvent.click(screen.getByRole("button", { name: "Block" }));
  await waitFor(() => expect(mockBlock).toHaveBeenCalledWith("a1"));
  await waitFor(() => expect(mockNotify.success).toHaveBeenCalled());
});

it("a failed block stays open with the error", async () => {
  mockBlock.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
  renderMenu("me", { _id: "a1", name: "Ann" });
  fireEvent.click(screen.getByRole("button", { name: "More options" }));
  fireEvent.click(screen.getByRole("menuitem", { name: "Block" }));
  fireEvent.click(screen.getByRole("button", { name: "Block" }));
  expect(await screen.findByText("That didn't work. Try again.")).toBeInTheDocument();
});
```

(The existing `reports with the canonical payload` test keeps expecting `type: "moment", reportId: "m1"`. It still passes.)

`src/components/moments/SingleMoment.test.tsx`. Extend its usersSlice mock, which would otherwise crash on render:

```tsx
jest.mock("../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [jest.fn(), { isLoading: false }],
  useBlockUserMutation: () => [jest.fn(), { isLoading: false }],
}));
```

Extend `src/components/moments/comments/CommentItem.test.tsx`. Add at the top:

```tsx
const mockReport = jest.fn();
const mockBlock = jest.fn();
jest.mock("../../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [mockReport, { isLoading: false }],
  useBlockUserMutation: () => [mockBlock, { isLoading: false }],
}));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn(), info: jest.fn() },
}));
```

and the tests:

```tsx
describe("report and block (moments#10)", () => {
  it("reports someone else's comment as type comment", async () => {
    mockReport.mockReturnValue({ unwrap: () => Promise.resolve({}) });
    renderItem();
    fireEvent.click(screen.getByTestId("comment-more"));
    fireEvent.click(screen.getByRole("menuitem", { name: "Report" }));
    fireEvent.click(screen.getByLabelText("Harassment"));
    fireEvent.click(screen.getByRole("button", { name: "Send report" }));
    await waitFor(() =>
      expect(mockReport).toHaveBeenCalledWith(
        expect.objectContaining({ type: "comment", reportId: "c-1", reportedUser: "author-1" })
      )
    );
  });

  it("blocks the comment's author", async () => {
    mockBlock.mockReturnValue({ unwrap: () => Promise.resolve({}) });
    renderItem();
    fireEvent.click(screen.getByTestId("comment-more"));
    fireEvent.click(screen.getByRole("menuitem", { name: "Block" }));
    fireEvent.click(screen.getByRole("button", { name: "Block" }));
    await waitFor(() => expect(mockBlock).toHaveBeenCalledWith("author-1"));
  });

  it("no menu on your own comment, and none when signed out", () => {
    renderItem({ myUserId: "author-1" });
    expect(screen.queryByTestId("comment-more")).not.toBeInTheDocument();
  });

  it("no menu when signed out", () => {
    renderItem({ isLoggedIn: false, myUserId: "" });
    expect(screen.queryByTestId("comment-more")).not.toBeInTheDocument();
  });
});
```

Extend `src/store/slices/usersEndpoints.test.ts`. Check how it builds its store; add a tag assertion with the `providesTags`/`invalidatesTags` introspection the file already uses. If it has none, add this:

```ts
it("blocking someone refetches feeds and comment lists (moments#10)", async () => {
  // A moments query that provides "Moments" is refetched after blockUser.
  const calls: string[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push(`${req.method} ${new URL(req.url).pathname}`);
    return new Response(JSON.stringify({ success: true, data: [] }), {
      status: 200, headers: { "content-type": "application/json" },
    });
  });
  const store = makeStore();
  const { momentsApiSlice } = require("./momentsSlice");
  const sub = store.dispatch(momentsApiSlice.endpoints.getSavedMoments.initiate({ page: 1, limit: 12 }));
  await sub;
  await store.dispatch((usersApiSlice.endpoints as any).blockUser.initiate("a1"));
  await new Promise((r) => setTimeout(r, 0));
  expect(calls.filter((c) => c.endsWith("/moments/saved")).length).toBe(2);
  sub.unsubscribe();
});
```

Use the names the file actually exports (`usersApiSlice`/`makeStore`). Read its header first.

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false ReportMomentDialog MomentOverflowMenu comments/CommentItem SingleMoment usersEndpoints`
Expected: FAIL. The dialog has no `type`/`targetId`, there is no Block menu item, no `comment-more` button, and `saved` is fetched once.

- [ ] **Step 3: Implement**

`ReportMomentDialog.tsx`:
- Replace `interface Props {...}` (`:32-36`) with the exported `ReportTargetType`/`ReportDialogProps` shown above.
- Change the component signature to:

```tsx
const ReportMomentDialog: React.FC<ReportDialogProps> = ({ type, targetId, authorId, onClose }) => {
```

- Add the copy table below `ENGLISH`:

```tsx
const COPY: Record<ReportTargetType, { titleKey: string; title: string; alreadyKey: string; already: string }> = {
  moment: {
    titleKey: "moments_section.report.title", title: "Report this moment",
    alreadyKey: "moments_section.report.already", already: "You've already reported this moment.",
  },
  comment: {
    titleKey: "moments_section.report.titleComment", title: "Report this comment",
    alreadyKey: "moments_section.report.alreadyComment", already: "You've already reported this comment.",
  },
  story: {
    titleKey: "moments_section.report.titleStory", title: "Report this story",
    alreadyKey: "moments_section.report.alreadyStory", already: "You've already reported this story.",
  },
};
```

- In `submit`, change `type: "moment", reportId: momentId,` to `type, reportId: targetId,`.
- Replace the title render `{tr("moments_section.report.title", "Report this moment")}` with `{tr(COPY[type].titleKey, COPY[type].title)}`.
- Replace the already-reported render `{tr("moments_section.report.already", "You've already reported this moment.")}` with `{tr(COPY[type].alreadyKey, COPY[type].already)}`.
- Change the doc comment to "Reports a moment, comment or story through the canonical POST /reports…".

Create `src/components/moments/actions/BlockAuthorDialog.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import ConfirmDialog from "../../../design/ConfirmDialog";
import notify from "../../../design/notify";
import { useBlockUserMutation } from "../../../store/slices/usersSlice";

export interface BlockAuthorDialogProps {
  authorId: string;
  /** Shown in the title; falls back to "this person". */
  authorName?: string;
  onClose: () => void;
  /** Called after the server confirmed the block. */
  onBlocked?: () => void;
}

/**
 * Block whoever wrote a moment, comment or story. Same copy and confirm as
 * the profile's Block (profile.block.*). blockUser invalidates Moments and
 * Comments, and the server filters a blocked author out of feeds and comment
 * lists, so the open lists drop their content on the refetch.
 */
const BlockAuthorDialog: React.FC<BlockAuthorDialogProps> = ({ authorId, authorName, onClose, onBlocked }) => {
  const { t } = useTranslation();
  const [blockUser, { isLoading }] = useBlockUserMutation();
  const [error, setError] = useState("");
  const name = authorName || t("profile.actions.this_person") || "this person";

  const confirm = async () => {
    setError("");
    try {
      await blockUser(authorId).unwrap();
      notify.success(t("moments_section.block.done", { name }) || `${name} is blocked.`);
      if (onBlocked) onBlocked();
      onClose();
    } catch (e) {
      setError(t("profile.actions.action_failed") || "That didn't work. Try again.");
    }
  };

  return (
    <ConfirmDialog
      open
      danger
      title={t("profile.block.title", { name }) || `Block ${name}?`}
      body={t("profile.block.body") || "They will not be able to message you or see your profile."}
      confirmLabel={t("profile.actions.block") || "Block"}
      cancelLabel={t("profile.actions.cancel") || "Cancel"}
      busy={isLoading}
      error={error || undefined}
      onConfirm={confirm}
      onCancel={onClose}
    />
  );
};

export default BlockAuthorDialog;
```

`MomentOverflowMenu.tsx`:
- Add the import `import BlockAuthorDialog from "./BlockAuthorDialog";` and the state `const [blocking, setBlocking] = useState(false);`.
- Change the report render (`:94`) to:

```tsx
            <ReportMomentDialog type="moment" targetId={momentId} authorId={authorId} onClose={() => setReporting(false)} />
```

- Inside `role="menu"`, after the Report button, add:

```tsx
          <button
            type="button"
            role="menuitem"
            onClick={(event) => {
              stop(event);
              setOpen(false);
              setBlocking(true);
            }}
            className="block w-full px-4 py-2 text-start text-sm text-red-600 hover:bg-red-50"
          >
            {t("profile.actions.block") || "Block"}
          </button>
```

- After the `reporting && createPortal(...)`, add:

```tsx
      {blocking &&
        createPortal(
          <div onClick={(event) => event.stopPropagation()}>
            <BlockAuthorDialog
              authorId={authorId}
              authorName={author && typeof author === "object" ? author.name : undefined}
              onClose={() => setBlocking(false)}
            />
          </div>,
          document.body
        )}
```

- Change the two `text-left` to `text-start` and `right-0` to `end-0` (RTL).

`CommentItem.tsx`:
- Add the imports:

```tsx
import { HiDotsHorizontal } from "react-icons/hi";
import ReportMomentDialog from "../actions/ReportMomentDialog";
import BlockAuthorDialog from "../actions/BlockAuthorDialog";
```

- Add the state:

```tsx
  const [menuOpen, setMenuOpen] = useState(false);
  const [reporting, setReporting] = useState(false);
  const [blocking, setBlocking] = useState(false);
  const authorId = idOf(comment.user);
  const canModerateAuthor = isLoggedIn && !!myUserId && !!authorId && !isMine;
```

  Place it after `isMine` is computed.
- In the action row, after the delete button, add:

```tsx
          {canModerateAuthor && (
            <div className="relative">
              <button
                type="button"
                data-testid="comment-more"
                aria-label={t("moments_section.report.menu") || "More options"}
                aria-haspopup="menu"
                aria-expanded={menuOpen}
                onClick={() => setMenuOpen((v) => !v)}
                className={actionClass}
              >
                <HiDotsHorizontal className="h-3.5 w-3.5" />
              </button>
              {menuOpen && (
                <div role="menu" className="absolute end-0 z-20 mt-1 min-w-[9rem] rounded-xl border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-900">
                  <button
                    type="button"
                    role="menuitem"
                    onClick={() => { setMenuOpen(false); setReporting(true); }}
                    className="block w-full px-4 py-2 text-start text-sm text-red-600 hover:bg-red-50"
                  >
                    {t("moments_section.report.report") || "Report"}
                  </button>
                  <button
                    type="button"
                    role="menuitem"
                    onClick={() => { setMenuOpen(false); setBlocking(true); }}
                    className="block w-full px-4 py-2 text-start text-sm text-red-600 hover:bg-red-50"
                  >
                    {t("profile.actions.block") || "Block"}
                  </button>
                </div>
              )}
            </div>
          )}
```

- Before the component's final closing tags, add:

```tsx
      {reporting && (
        <ReportMomentDialog type="comment" targetId={comment._id} authorId={authorId} onClose={() => setReporting(false)} />
      )}
      {blocking && (
        <BlockAuthorDialog authorId={authorId} authorName={comment.user.name} onClose={() => setBlocking(false)} />
      )}
```

`usersSlice.ts`. In `blockUser` and `unblockUser`, change `invalidatesTags: ["User", "Conversations"],` to:

```ts
      // Moments + Comments: the server drops a blocked author from feeds and
      // comment lists, so open lists refetch and their content disappears.
      invalidatesTags: ["User", "Conversations", "Moments", "Comments"],
```

Add to `eng.json`:
- under `moments_section.report`:

```json
"titleComment": "Report this comment",
"titleStory": "Report this story",
"alreadyComment": "You've already reported this comment.",
"alreadyStory": "You've already reported this story."
```

- a new `moments_section.block` object:

```json
"block": { "done": "{{name}} is blocked." }
```

- [ ] **Step 4: Run → PASS.** Also run `CI=true npm test -- --watchAll=false ProfileActions ChatInfoPanel ProfilePage profileCacheTags`. These mock usersSlice themselves and must stay green; the invalidation change does not affect them.

- [ ] **Step 5: Commit**

```bash
git add src/components/moments/actions/ReportMomentDialog.tsx src/components/moments/actions/ReportMomentDialog.test.tsx \
  src/components/moments/actions/BlockAuthorDialog.tsx src/components/moments/actions/MomentOverflowMenu.tsx \
  src/components/moments/actions/MomentOverflowMenu.test.tsx src/components/moments/comments/CommentItem.tsx \
  src/components/moments/comments/CommentItem.test.tsx src/components/moments/SingleMoment.test.tsx \
  src/store/slices/usersSlice.ts src/store/slices/usersEndpoints.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(moments): report comments and block authors from moments and comments

The app can report a comment and block a moment's or comment's author;
the web could only report a moment. The report dialog now takes
{type, targetId} (moment, comment or story) and goes through the same
POST /reports; Block confirms with the profile's copy. Blocking now
invalidates Moments and Comments so the server's block filter takes the
author's content out of every open list.

Still open (Phase 3 moments): saved paging, feed chips, comment
GIF/photo/mentions, leftovers, recorder audio/mp4, i18n; report story +
block from the story viewer (P3-MOM stories tasks, reuses this dialog).
EOF
```

---

### Task P3-MOM-6: Saved moments load every page and draw every kind of moment (moments#11)

**Files:**
- Modify: `src/components/moments/SavedMoments.tsx` (paging, tile renderer, list media, links)
- Create: `src/components/moments/media/MomentThumb.tsx`
- Test: `src/components/moments/SavedMoments.test.tsx` (new)

**Interfaces:**
- Consumes: `GET /api/v1/moments/saved?page&limit` → `{data, pagination:{currentPage,totalPages,totalMoments,hasNextPage}}` (`controllers/moments.js:1512-1590`). Rows carry `imageUrls`, `video{url,thumbnail}`, `audio{url,duration,waveform}`, `backgroundColor`, `mediaType`.
- Produces:
  - `MomentThumb: React.FC<{ moment: any }>`. It is a square tile in the precedence the feed uses: video (thumbnail, else `<video preload="metadata">`), voice (mic + duration), image, gradient/text (`gradientFor`), plain text.
  - In list view, `SavedMoments` uses the feed's own media components (`MomentVideoPlayer`, `VoiceNotePlayer`, `GradientMomentCard`).
  - Paging follows the `MyMoments.tsx:76-139` pattern.
  - Links go to `/moment/:id` (canonical; `/moments/:id` only redirects) and `/community/:userId`. `/user/:id` is NotFound today.

- [ ] **Step 1: Write the failing test** `src/components/moments/SavedMoments.test.tsx`

```tsx
import "@testing-library/jest-dom";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import SavedMoments from "./SavedMoments";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
jest.mock("react-toastify", () => ({ Bounce: {}, toast: { success: jest.fn(), error: jest.fn() } }));
const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));
jest.mock("./media/VoiceNotePlayer", () => () => <div data-testid="voice-player" />);
jest.mock("./media/MomentVideoPlayer", () => () => <div data-testid="video-player" />);

const row = (id: string, extra: any = {}) => ({
  _id: id,
  description: `moment ${id}`,
  likeCount: 0,
  commentCount: 0,
  createdAt: "2026-10-01T00:00:00.000Z",
  user: { _id: "u-" + id, name: "Ann" },
  ...extra,
});

const PAGE1 = Array.from({ length: 12 }, (_, i) => row(`p1-${i}`));
const PAGE2 = [
  row("audio", { mediaType: "audio", audio: { url: "https://cdn/a.m4a", duration: 7, waveform: [] } }),
  row("text", { mediaType: "text", backgroundColor: "gradient_lagoon" }),
];
const mockQueryArgs: any[] = [];
jest.mock("../../store/slices/momentsSlice", () => ({
  useGetSavedMomentsQuery: (args: any) => {
    mockQueryArgs.push(args);
    if (args.page === 1) {
      return { currentData: { data: PAGE1, pagination: { hasNextPage: true } }, isLoading: false, isFetching: false };
    }
    return { currentData: { data: PAGE2, pagination: { hasNextPage: false } }, isLoading: false, isFetching: false };
  },
  useUnsaveMomentMutation: () => [jest.fn(() => ({ unwrap: () => Promise.resolve({}) })), { isLoading: false }],
}));

const renderPage = () => render(<MemoryRouter><SavedMoments /></MemoryRouter>);

beforeEach(() => {
  mockQueryArgs.length = 0;
  mockNavigate.mockReset();
});

it("loads the next page and appends it (moments#11)", async () => {
  renderPage();
  expect(screen.getAllByTestId("saved-tile")).toHaveLength(12);
  fireEvent.click(screen.getByRole("button", { name: "Load more" }));
  await waitFor(() => expect(screen.getAllByTestId("saved-tile")).toHaveLength(14));
  expect(mockQueryArgs.some((a) => a.page === 2 && a.limit === 12)).toBe(true);
  expect(screen.queryByRole("button", { name: "Load more" })).not.toBeInTheDocument();
});

it("draws voice and gradient moments instead of an empty tile", async () => {
  renderPage();
  fireEvent.click(screen.getByRole("button", { name: "Load more" }));
  expect(await screen.findByTestId("thumb-audio")).toBeInTheDocument();
  const gradient = screen.getByTestId("thumb-gradient");
  expect(gradient.getAttribute("style") || "").toContain("linear-gradient");
});

it("opens the canonical moment and profile routes", async () => {
  renderPage();
  fireEvent.click(screen.getAllByTestId("saved-tile")[0]);
  expect(mockNavigate).toHaveBeenCalledWith("/moment/p1-0");
  fireEvent.click(screen.getByLabelText("List view"));
  fireEvent.click(screen.getAllByTestId("saved-author")[0]);
  expect(mockNavigate).toHaveBeenCalledWith("/community/u-p1-0");
});

it("list view uses the feed's voice player for a voice moment", async () => {
  renderPage();
  fireEvent.click(screen.getByRole("button", { name: "Load more" }));
  fireEvent.click(screen.getByLabelText("List view"));
  expect(await screen.findByTestId("voice-player")).toBeInTheDocument();
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false SavedMoments`
Expected: FAIL. There is no `saved-tile`, no "Load more", navigation goes to `/moments/p1-0`, and there is no `List view` label.

- [ ] **Step 3: Implement**

Create `src/components/moments/media/MomentThumb.tsx`:

```tsx
import React from "react";
import { Mic, Play } from "lucide-react";
import { gradientFor } from "./momentGradients";

const firstImage = (m: any): string => {
  const urls = m && (m.imageUrls || m.images);
  if (!Array.isArray(urls)) return "";
  for (let i = 0; i < urls.length; i += 1) {
    if (typeof urls[i] === "string" && urls[i].trim()) return urls[i].trim();
  }
  return "";
};

const formatSeconds = (s: number) => {
  const total = Math.max(0, Math.round(s || 0));
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`;
};

/**
 * A square preview of any moment, in the feed's media precedence
 * (SingleMoment: video -> audio -> text/gradient -> images). Missing or
 * broken media degrade to the caption on a plain tile, never to an empty box.
 */
const MomentThumb: React.FC<{ moment: any }> = ({ moment }) => {
  const video = moment && moment.video;
  const audio = moment && moment.audio;
  const image = firstImage(moment);
  const caption = (moment && typeof moment.description === "string" && moment.description) || "";

  if (video && video.url) {
    return (
      <div data-testid="thumb-video" className="relative h-full w-full bg-black">
        {video.thumbnail ? (
          <img src={video.thumbnail} alt="" loading="lazy" className="h-full w-full object-cover" />
        ) : (
          <video src={video.url} preload="metadata" muted className="h-full w-full object-cover" />
        )}
        <Play className="absolute start-2 top-2 h-4 w-4 text-white drop-shadow" fill="white" aria-hidden />
      </div>
    );
  }
  if (audio && audio.url) {
    return (
      <div data-testid="thumb-audio" className="flex h-full w-full flex-col items-center justify-center gap-1 bg-amber-50 p-2 text-amber-700">
        <Mic className="h-6 w-6" aria-hidden />
        <span className="text-xs font-semibold tabular-nums">{formatSeconds(audio.duration)}</span>
        {caption && <p className="line-clamp-2 text-center text-[11px] text-amber-800">{caption}</p>}
      </div>
    );
  }
  if (image) {
    return <img data-testid="thumb-image" src={image} alt="" loading="lazy" className="h-full w-full object-cover" />;
  }
  if (moment && (moment.mediaType === "text" || moment.backgroundColor)) {
    return (
      <div
        data-testid="thumb-gradient"
        className="flex h-full w-full items-center justify-center p-2"
        style={{ background: gradientFor(moment.backgroundColor) }}
      >
        <p className="line-clamp-4 text-center text-xs font-bold text-white drop-shadow-sm">{caption}</p>
      </div>
    );
  }
  return (
    <div data-testid="thumb-text" className="flex h-full w-full items-center justify-center bg-gradient-to-br from-teal-100 to-blue-100 p-2">
      <p className="line-clamp-4 text-center text-xs text-gray-600">{caption}</p>
    </div>
  );
};

export default MomentThumb;
```

`SavedMoments.tsx`, changes in order:

1. Imports. Change `import React, { useState } from "react";` to `import React, { useEffect, useMemo, useState } from "react";` and add:

```tsx
import MomentThumb from "./media/MomentThumb";
import MomentVideoPlayer from "./media/MomentVideoPlayer";
import VoiceNotePlayer from "./media/VoiceNotePlayer";
import GradientMomentCard from "./media/GradientMomentCard";
```

2. Extend `interface SavedMoment` with:

```tsx
  mediaType?: "image" | "video" | "audio" | "text";
  backgroundColor?: string;
  audio?: { url: string; duration: number; waveform: number[] };
  video?: { url: string; thumbnail?: string };
```

   Replace the existing `video?: { url: string };`.

3. Replace `:43-46`:

```tsx
  const { data, isLoading, refetch } = useGetSavedMomentsQuery({});
  const [unsaveMoment, { isLoading: isUnsaving }] = useUnsaveMomentMutation();

  const savedMoments: SavedMoment[] = data?.data || [];
```

   with the MyMoments paging pattern:

```tsx
  // The server pages this list ({data, pagination}); "Load more" asks for the
  // next page and keeps the earlier ones (same pattern as MyMoments).
  const PAGE_SIZE = 12;
  const [page, setPage] = useState(1);
  const { currentData, isLoading, isFetching, refetch } = useGetSavedMomentsQuery({ page, limit: PAGE_SIZE });
  const [pages, setPages] = useState<{ [page: number]: SavedMoment[] }>({});
  const [hasMore, setHasMore] = useState(false);
  const [removed, setRemoved] = useState<{ [id: string]: boolean }>({});
  useEffect(() => {
    if (!currentData) return;
    const rows: SavedMoment[] = Array.isArray((currentData as any).data) ? (currentData as any).data : [];
    setPages((prev) => ({ ...prev, [page]: rows }));
    const pagination = (currentData as any).pagination;
    setHasMore(
      pagination && typeof pagination.hasNextPage === "boolean" ? pagination.hasNextPage : rows.length >= PAGE_SIZE
    );
  }, [currentData, page]);
  const [unsaveMoment, { isLoading: isUnsaving }] = useUnsaveMomentMutation();

  const savedMoments: SavedMoment[] = useMemo(() => {
    const all: { [page: number]: SavedMoment[] } = { ...pages };
    if (currentData && Array.isArray((currentData as any).data)) all[page] = (currentData as any).data;
    const seen: { [id: string]: boolean } = {};
    const out: SavedMoment[] = [];
    Object.keys(all).map(Number).sort((a, b) => a - b).forEach((key) => {
      all[key].forEach((m) => {
        // An unsave shifts later pages by one, so a refetched page can repeat
        // a moment an earlier page already shows.
        if (!m || removed[m._id] || seen[m._id]) return;
        seen[m._id] = true;
        out.push(m);
      });
    });
    return out;
  }, [pages, currentData, page, removed]);
```

4. In `handleUnsave`, after `await unsaveMoment(momentId).unwrap();` add `setRemoved((prev) => ({ ...prev, [momentId]: true }));`. Keep `refetch()`.

5. `GridView`. Replace the tile's `<button ...>` opening and its media block (`:81-103`) with:

```tsx
        <button
          key={moment._id}
          data-testid="saved-tile"
          onClick={() => navigate(`/moment/${moment._id}`)}
          className="relative aspect-square bg-gray-100 overflow-hidden group"
        >
          <MomentThumb moment={moment} />
```

   (Keep the hover overlay and bookmark badge. Change the badge's `right-2` to `end-2`.)

6. `ListView`:
   - The author button `onClick={() => navigate(`/user/${moment.user._id}`)}` becomes `data-testid="saved-author" onClick={() => navigate(`/community/${moment.user._id}`)}`.
   - The content button `navigate(`/moments/${moment._id}`)` becomes `navigate(`/moment/${moment._id}`)`.
   - Replace the two media blocks (`:190-204`, the `imageUrls?.[0]` img and the `video?.url` video) with:

```tsx
            {moment.video && moment.video.url ? (
              <div className="px-4 pb-3"><MomentVideoPlayer video={moment.video as any} /></div>
            ) : moment.audio && moment.audio.url ? (
              <div className="px-4 pb-3"><VoiceNotePlayer audio={moment.audio} /></div>
            ) : moment.mediaType === "text" || (moment.backgroundColor && !(moment.imageUrls && moment.imageUrls.length)) ? (
              <div className="px-4 pb-3">
                <GradientMomentCard text={moment.description || ""} backgroundColor={moment.backgroundColor} />
              </div>
            ) : moment.imageUrls && moment.imageUrls[0] ? (
              <img src={moment.imageUrls[0]} alt="" loading="lazy" className="w-full max-h-96 object-cover" />
            ) : null}
```

   - On a gradient moment the caption is drawn on the card, so render `{moment.description && moment.mediaType !== "text" && !moment.backgroundColor && (<p ...>)}` for the plain caption line.
   - Change the menu's `right-0` to `end-0` and `text-left` to `text-start`.

7. View toggle buttons: add `aria-label={t("moments_section.saved.gridView") || "Grid view"}` and `aria-label={t("moments_section.saved.listView") || "List view"}`, plus `aria-pressed`.

8. After the grid/list render, inside the content `<div>`, add:

```tsx
        {hasMore && savedMoments.length > 0 && (
          <div className="mt-4 flex justify-center">
            <button
              type="button"
              onClick={() => setPage((p) => p + 1)}
              disabled={isFetching}
              className="rounded-full bg-white px-5 py-2 text-sm font-semibold text-teal-700 shadow disabled:opacity-50"
            >
              {t("moments_section.saved.loadMore") || "Load more"}
            </button>
          </div>
        )}
```

9. The header count `{savedMoments.length} {t("moments.saved.momentCount") || "moments saved"}` becomes:

```tsx
                {(currentData && (currentData as any).pagination && (currentData as any).pagination.totalMoments) || savedMoments.length}{" "}
                {t("moments_section.saved.momentCount") || "moments saved"}
```

   Task 11 moves the remaining `moments.saved.*` keys. Use the new `moments_section.saved.*` names here already for the three new keys.

Add to `eng.json` a new `moments_section.saved` object (task 11 adds the moved keys to it):

```json
"saved": { "loadMore": "Load more", "gridView": "Grid view", "listView": "List view", "momentCount": "moments saved" }
```

- [ ] **Step 4: Run → PASS.**

- [ ] **Step 5: Commit**

```bash
git add src/components/moments/SavedMoments.tsx src/components/moments/SavedMoments.test.tsx \
  src/components/moments/media/MomentThumb.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(moments): saved moments page through everything and draw voice/text moments

Saved Moments asked for page 1 once, so only the first 10 ever showed,
and its grid had nothing to draw for voice or gradient moments. It now
pages like My moments, tiles use one MomentThumb in the feed's media
order, the list uses the feed's players, and links go to /moment/:id
and /community/:id (/user/:id was a 404).

Still open (Phase 3 moments): feed chips, comment GIF/photo/mentions,
leftovers, recorder audio/mp4, i18n, stories tasks.
EOF
```

---

### Task P3-MOM-7: Feed cards show mood, tags and location (moments#22)

**Files:**
- Modify: `src/components/moments/SingleMoment.tsx:45-75` (props), `:90-111` (destructure), after the description block `:430-455`
- Modify: `src/components/moments/MainMoments.tsx:510-533` (pass the fields)
- Test: `src/components/moments/SingleMoment.test.tsx` (extend)

**Interfaces:**
- Consumes: feed rows already carry `mood`, `tags`, `location{formattedAddress,coordinates}`. `FEED_MOMENT_EXCLUDE` (`lib/feedProjection.js:80`) drops only `likedUsers savedBy reports comments`.
- Produces:
  - New optional props on `SingleMoment`: `mood?: string; tags?: string[]; location?: { formattedAddress?: string } | null`.
  - New export `MomentChips: React.FC<{ mood?: string; tags?: string[]; location?: {formattedAddress?: string} | null }>` in `src/components/moments/MomentChips.tsx`. Detail could reuse it later.

- [ ] **Step 1: Write the failing test** (append to `SingleMoment.test.tsx`; its `t` echoes keys)

```tsx
describe("feed card chips (moments#22)", () => {
  afterEach(() => _resetMomentViewsForTests());

  const renderWith = (extra: any) =>
    render(
      <MemoryRouter>
        <SingleMoment
          _id="moment-2"
          title=""
          description="hi"
          likeCount={0}
          likedUsers={[]}
          commentCount={0}
          createdAt={new Date().toISOString()}
          user={{ _id: "author-1", name: "Author" }}
          {...extra}
        />
      </MemoryRouter>
    );

  it("shows mood, every tag and the place", () => {
    renderWith({ mood: "happy", tags: ["kimchi", "seoul"], location: { formattedAddress: "Seoul, KR" } });
    const chips = screen.getByTestId("moment-chips");
    expect(chips).toHaveTextContent("moments_section.moods.happy");
    expect(chips).toHaveTextContent("#kimchi");
    expect(chips).toHaveTextContent("#seoul");
    expect(chips).toHaveTextContent("Seoul, KR");
  });

  it("renders no chip row when there is nothing to show", () => {
    renderWith({ mood: "", tags: [], location: null });
    expect(screen.queryByTestId("moment-chips")).not.toBeInTheDocument();
  });

  it("ignores a location without an address and an unknown mood", () => {
    renderWith({ mood: "not-a-mood", tags: undefined, location: { coordinates: [1, 2] } });
    // An unknown mood still renders its raw value rather than crashing.
    expect(screen.getByTestId("moment-chips")).toHaveTextContent("moments_section.moods.not-a-mood");
    expect(screen.queryByTestId("moment-chip-location")).not.toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false SingleMoment`
Expected: FAIL. There is no `moment-chips`.

- [ ] **Step 3: Implement**

Create `src/components/moments/MomentChips.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { moodEmoji, moodLabel } from "./fields/MoodField";

interface MomentChipsProps {
  mood?: string;
  tags?: string[];
  location?: { formattedAddress?: string } | null;
}

/** Mood, tags and place as one wrap-around chip row (the app's card shows them). */
const MomentChips: React.FC<MomentChipsProps> = ({ mood, tags, location }) => {
  const { t } = useTranslation();
  const tagList = Array.isArray(tags) ? tags.filter((x) => typeof x === "string" && x.trim()) : [];
  const place = location && typeof location.formattedAddress === "string" ? location.formattedAddress.trim() : "";
  if (!mood && tagList.length === 0 && !place) return null;
  return (
    <div data-testid="moment-chips" className="mt-2 flex flex-wrap gap-1.5">
      {mood && (
        <span className="inline-flex items-center gap-1 rounded-full bg-yellow-50 px-2 py-0.5 text-xs font-medium text-yellow-800">
          <span aria-hidden="true">{moodEmoji(mood)}</span>
          {moodLabel(t, mood)}
        </span>
      )}
      {tagList.map((tag) => (
        <span key={tag} className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700">
          #{tag}
        </span>
      ))}
      {place && (
        <span
          data-testid="moment-chip-location"
          className="inline-flex max-w-full items-center gap-1 truncate rounded-full bg-green-50 px-2 py-0.5 text-xs font-medium text-green-800"
        >
          <span aria-hidden="true">📍</span>
          <span className="truncate">{place}</span>
        </span>
      )}
    </div>
  );
};

export default MomentChips;
```

`SingleMoment.tsx`:
- Add `import MomentChips from "./MomentChips";`.
- In `MomentProps`, after `prompt?: MomentPrompt | null;`, add:

```tsx
  mood?: string;
  tags?: string[];
  location?: { formattedAddress?: string } | null;
```

- Destructure `mood, tags, location,` after `prompt,`.
- Right after the closing `)}` of the `{description && (...)}` block, still inside the Content `<div className="px-2 xs:px-3 sm:px-4">`, add:

```tsx
          <MomentChips mood={mood} tags={tags} location={location} />
```

`MainMoments.tsx` `<SingleMoment ...>` (`:510-533`): after `prompt={moment.prompt}` add:

```tsx
                            mood={moment.mood}
                            tags={moment.tags}
                            location={moment.location}
```

- [ ] **Step 4: Run → PASS** (`SingleMoment MainMoments`).

- [ ] **Step 5: Commit**

```bash
git add src/components/moments/MomentChips.tsx src/components/moments/SingleMoment.tsx \
  src/components/moments/SingleMoment.test.tsx src/components/moments/MainMoments.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(moments): mood, tags and place on feed cards

Only the detail page showed them, so a moment's mood and tags were
invisible in the feed on web while app cards show them.

Still open (Phase 3 moments): comment GIF/photo/mentions, leftovers,
recorder audio/mp4, i18n, stories tasks.
EOF
```

---

### Task P3-MOM-8: Comments with a GIF, a photo and no text, and mentions drawn (moments#21)

**Files:**
- Modify: `src/store/slices/momentsSlice.ts:183-205` (`addMomentComment` accepts `image` and `imageUrl`)
- Modify: `src/components/moments/comments/CommentComposer.tsx` (one-request photo, GIF picker, empty text)
- Create: `src/components/moments/comments/mentionText.tsx`
- Modify: `src/components/moments/comments/types.ts` (add `mentions`)
- Modify: `src/components/moments/TranslatableText.tsx:35-50,205` (optional `content`)
- Modify: `src/components/moments/comments/CommentItem.tsx:258-266` (render mentions)
- Test: `src/store/slices/momentsSlice.endpoints.test.ts` (extend), `src/components/moments/comments/CommentComposer.test.tsx` (extend), `src/components/moments/comments/mentionText.test.tsx` (new), `src/components/moments/comments/CommentItem.test.tsx` (extend)

**Interfaces:**
- Consumes (backend, deployed, `controllers/comments.js:131-236`, `routes/comment.js:22`):
  - `POST /moments/:id/comments` runs `uploadSingleCompressed('image')` before `createComment`. A **multipart** request with `text`, `parentComment` and `image` creates a photo comment in one request. An empty `text` is accepted as long as there is an image or GIF ("A comment needs text, a photo or a GIF").
  - A JSON `imageUrl` is kept only for Giphy hosts (`lib/commentMedia.js`: `https://media\d*.giphy.com` / `i.giphy.com`).
  - `mentions` are read only as a JSON array `[{user, username, offset, length}]` and stored. Multipart fields cannot carry them (multer gives strings), so a photo comment carries no mentions. The web doesn't compose mentions in this task anyway.
  - `correction` is a nested object, which multipart can't carry. **A correction with a photo keeps the old two-step** (create JSON, then `PUT /comments/:id/image`).
- Produces:
  - `addMomentComment({momentId, text?, parentComment?, correction?, image?: File, imageUrl?: string})`. With `image`, the body is `FormData`. Otherwise it is JSON, as today, plus `imageUrl` when given.
  - `renderWithMentions(text: string, mentions?: CommentMention[]): React.ReactNode[]`, exported from `comments/mentionText.tsx`.
  - `TranslatableText` gets the optional prop `content?: React.ReactNode` (rendered in place of `text`; translation still uses `text`).
  - `CommentMention` type: `{ user?: string | {_id: string}; username?: string; offset?: number; length?: number }`.

- [ ] **Step 1: Write the failing tests**

Append to `src/store/slices/momentsSlice.endpoints.test.ts`. It already builds a store and mocks fetch; reuse its helpers and add a capture of the polyfilled body:

```ts
describe("addMomentComment media (moments#21)", () => {
  const capture = () => {
    const calls: any[] = [];
    (global as any).fetch = jest.fn(async (req: any) => {
      // CRA's jsdom uses whatwg-fetch, which keeps a FormData body on
      // _bodyFormData and a JSON string on _bodyText.
      calls.push({ url: req.url, method: req.method, form: req._bodyFormData, text: req._bodyText });
      return new Response(JSON.stringify({ success: true, data: { _id: "c1" } }), {
        status: 200, headers: { "content-type": "application/json" },
      });
    });
    return calls;
  };

  it("a photo comment goes up in ONE multipart request with its text", async () => {
    const calls = capture();
    const store = makeStore();
    const file = new File(["x"], "p.jpg", { type: "image/jpeg" });
    await store.dispatch(
      (momentsApiSlice.endpoints as any).addMomentComment.initiate({ momentId: "m1", text: "", image: file, parentComment: "p1" })
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/moments/m1/comments");
    expect(calls[0].form).toBeInstanceOf(FormData);
    expect(calls[0].form.get("image")).toBeInstanceOf(File);
    expect(calls[0].form.get("text")).toBe("");
    expect(calls[0].form.get("parentComment")).toBe("p1");
  });

  it("a GIF comment is JSON with imageUrl", async () => {
    const calls = capture();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).addMomentComment.initiate({
        momentId: "m1", text: "", imageUrl: "https://media1.giphy.com/media/x/giphy.gif",
      })
    );
    expect(JSON.parse(calls[0].text)).toEqual({ text: "", imageUrl: "https://media1.giphy.com/media/x/giphy.gif" });
  });

  it("a plain comment is unchanged JSON", async () => {
    const calls = capture();
    const store = makeStore();
    await store.dispatch((momentsApiSlice.endpoints as any).addMomentComment.initiate({ momentId: "m1", text: "hi" }));
    expect(JSON.parse(calls[0].text)).toEqual({ text: "hi" });
  });
});
```

(Use the file's own `makeStore`. If it lacks one, copy `makeStore` from `momentsActionsEndpoints.test.ts:12-23`.)

`src/components/moments/comments/mentionText.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render } from "@testing-library/react";
import { renderWithMentions } from "./mentionText";

const html = (nodes: any) => render(<p>{nodes}</p>).container.querySelector("p")!;

it("highlights each mention by offset and length, keeping the rest as text", () => {
  const p = html(renderWithMentions("hi @ann and @bo!", [
    { user: "u2", username: "bo", offset: 12, length: 3 },
    { user: "u1", username: "ann", offset: 3, length: 4 },
  ]));
  const marks = p.querySelectorAll('[data-testid="comment-mention"]');
  expect(Array.from(marks).map((m) => m.textContent)).toEqual(["@ann", "@bo"]);
  expect(p.textContent).toBe("hi @ann and @bo!");
});

it("ignores out-of-range, negative and overlapping mentions", () => {
  const p = html(renderWithMentions("hello", [
    { offset: -1, length: 2 },
    { offset: 99, length: 2 },
    { offset: 0, length: 3 },
    { offset: 1, length: 3 },
  ]));
  expect(p.querySelectorAll('[data-testid="comment-mention"]')).toHaveLength(1);
  expect(p.textContent).toBe("hello");
});

it("no mentions is just the text", () => {
  const p = html(renderWithMentions("plain", undefined));
  expect(p.textContent).toBe("plain");
  expect(p.querySelector('[data-testid="comment-mention"]')).toBeNull();
});
```

Append to `src/components/moments/comments/CommentComposer.test.tsx`. Read its existing mock block first; it mocks `useAddMomentCommentMutation` as `mockAddComment` and `useUploadCommentImageMutation` as `mockUploadImage`. Add a GifPickerPanel mock at the top:

```tsx
jest.mock("../../chat/GifPickerPanel", () => (props: any) => (
  <button type="button" onClick={() => props.onSelectGif("https://media1.giphy.com/media/x/giphy.gif")}>
    pick-gif
  </button>
));
```

and the tests (use the file's render helper; `mode` defaults to `comment`):

```tsx
describe("photo, GIF and empty text (moments#21)", () => {
  const pickFile = () =>
    fireEvent.change(screen.getByTestId("comment-composer-image"), {
      target: { files: [new File(["x"], "p.jpg", { type: "image/jpeg" })] },
    });

  it("posts a photo with no text in one request", async () => {
    renderComposer();
    expect(screen.getByTestId("comment-composer-submit")).toBeDisabled();
    pickFile();
    expect(screen.getByTestId("comment-composer-submit")).not.toBeDisabled();
    fireEvent.click(screen.getByTestId("comment-composer-submit"));
    await waitFor(() => expect(mockAddComment).toHaveBeenCalledTimes(1));
    const arg = mockAddComment.mock.calls[0][0];
    expect(arg.image).toBeInstanceOf(File);
    expect(arg.text).toBe("");
    expect(mockUploadImage).not.toHaveBeenCalled();
  });

  it("posts a GIF as imageUrl", async () => {
    renderComposer();
    fireEvent.click(screen.getByTestId("comment-composer-gif"));
    fireEvent.click(screen.getByText("pick-gif"));
    expect(screen.getByTestId("comment-composer-gif-preview")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("comment-composer-submit"));
    await waitFor(() => expect(mockAddComment).toHaveBeenCalled());
    expect(mockAddComment.mock.calls[0][0].imageUrl).toBe("https://media1.giphy.com/media/x/giphy.gif");
    expect(mockAddComment.mock.calls[0][0].image).toBeUndefined();
  });

  it("a photo replaces a picked GIF and vice versa", () => {
    renderComposer();
    fireEvent.click(screen.getByTestId("comment-composer-gif"));
    fireEvent.click(screen.getByText("pick-gif"));
    pickFile();
    expect(screen.queryByTestId("comment-composer-gif-preview")).not.toBeInTheDocument();
  });

  it("a correction with a photo keeps the two-step upload", async () => {
    renderComposer({ mode: "correction" });
    fireEvent.change(screen.getByTestId("comment-composer-corrected"), { target: { value: "Fixed" } });
    pickFile();
    fireEvent.click(screen.getByTestId("comment-composer-submit"));
    await waitFor(() => expect(mockUploadImage).toHaveBeenCalled());
    expect(mockAddComment.mock.calls[0][0].image).toBeUndefined();
  });

  it("no GIF button on a correction", () => {
    renderComposer({ mode: "correction" });
    expect(screen.queryByTestId("comment-composer-gif")).not.toBeInTheDocument();
  });
});
```

(If the file's helper has a different name, use it. It must accept `{ mode }`.)

Append to `CommentItem.test.tsx`:

```tsx
it("draws app mentions highlighted (moments#21)", () => {
  renderItem({
    comment: baseComment({
      text: "thanks @mina",
      mentions: [{ user: "u9", username: "mina", offset: 7, length: 5 }],
    }),
  });
  expect(screen.getByTestId("comment-mention")).toHaveTextContent("@mina");
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false momentsSlice.endpoints mentionText CommentComposer comments/CommentItem`
Expected: FAIL. `_bodyFormData` is undefined (the body is JSON), `mentionText` can't be resolved, submit is disabled with only a photo, there is no GIF button, and there is no `comment-mention`.

If `req._bodyFormData` turns out undefined even after the implementation, this jsdom isn't on whatwg-fetch. Then capture `req.body` instead and assert `instanceof FormData`. Record which one in the commit body.

- [ ] **Step 3: Implement**

`momentsSlice.ts`. Replace the `addMomentComment` query (`:184-202`):

```ts
      query: ({
        momentId,
        text,
        parentComment,
        correction,
        image,
        imageUrl,
      }: {
        momentId: string;
        text?: string;
        parentComment?: string;
        correction?: { originalText?: string; correctedText: string; explanation?: string };
        /** A photo: sent in the SAME request as multipart (createComment's
         *  uploadSingleCompressed('image')), so a photo-only comment works. */
        image?: File;
        /** A Giphy GIF URL; the server keeps only giphy.com hosts. */
        imageUrl?: string;
      }) => {
        if (image) {
          // multipart can't carry the nested `correction`; callers keep the
          // two-step upload for corrections (CommentComposer).
          const form = new FormData();
          form.append("text", text || "");
          if (parentComment) form.append("parentComment", parentComment);
          form.append("image", image);
          return { url: `${MOMENTS_URL}/${momentId}/comments`, method: "POST", body: form };
        }
        const body: any = { text: text || "" };
        if (parentComment) body.parentComment = parentComment;
        if (correction) body.correction = correction;
        if (imageUrl) body.imageUrl = imageUrl;
        return {
          url: `${MOMENTS_URL}/${momentId}/comments`,
          method: "POST",
          body,
        };
      },
```

`comments/types.ts`. Add:

```ts
export interface CommentMention {
  user?: string | { _id: string };
  username?: string;
  /** UTF-16 offset into `text` (the app computes it with Dart String indices, the same unit as JS). */
  offset?: number;
  length?: number;
}
```

and `mentions?: CommentMention[];` in `CommentType`.

Create `src/components/moments/comments/mentionText.tsx`:

```tsx
import React from "react";
import { CommentMention } from "./types";

/**
 * The comment text with each @mention highlighted, the way the app draws
 * them (comments_main.dart _buildCommentText: primary colour, semibold, not
 * a link). Mentions that point outside the text, have no length, or overlap
 * an earlier one are skipped; the text itself is never dropped.
 */
export const renderWithMentions = (text: string, mentions?: CommentMention[]): React.ReactNode[] => {
  const source = text || "";
  const valid = (Array.isArray(mentions) ? mentions : [])
    .filter(
      (m) =>
        m &&
        typeof m.offset === "number" && typeof m.length === "number" &&
        m.offset >= 0 && m.length > 0 && m.offset < source.length
    )
    .slice()
    .sort((a, b) => (a.offset as number) - (b.offset as number));

  const out: React.ReactNode[] = [];
  let cursor = 0;
  valid.forEach((m, i) => {
    const start = m.offset as number;
    if (start < cursor) return; // overlaps the previous mention
    const end = Math.min(source.length, start + (m.length as number));
    if (start > cursor) out.push(source.slice(cursor, start));
    out.push(
      <span key={`m${i}`} data-testid="comment-mention" className="font-semibold text-brand">
        {source.slice(start, end)}
      </span>
    );
    cursor = end;
  });
  if (cursor < source.length) out.push(source.slice(cursor));
  return out;
};
```

`TranslatableText.tsx`:
- In `TranslatableTextProps`, add:

```tsx
  /** Rich rendering of `text` (e.g. highlighted mentions). Translation and
   *  the same-language check still use the plain `text`. */
  content?: React.ReactNode;
```

- Destructure `content,`.
- At `:205`, replace `{text}` with `{content !== undefined ? content : text}`.

`CommentItem.tsx`:
- Add `import { renderWithMentions } from "./mentionText";`.
- In the `TranslatableText` (`:259-265`), add:

```tsx
              content={
                comment.mentions && comment.mentions.length > 0
                  ? renderWithMentions(comment.text, comment.mentions)
                  : undefined
              }
```

`CommentComposer.tsx`:
- Imports: add `import GifPickerPanel from "../../chat/GifPickerPanel";` and change the icons import to `import { FaPaperPlane, FaImage, FaTimes } from "react-icons/fa";`.
- State: add

```tsx
  const [gifUrl, setGifUrl] = useState<string | null>(null);
  const [showGif, setShowGif] = useState(false);
```

- Replace `const canSubmit = ...` (`:84`) with:

```tsx
  // A comment needs text, a photo or a GIF (createComment); a correction
  // needs its corrected text.
  const canSubmit = isCorrection
    ? corrected.trim().length > 0
    : text.trim().length > 0 || file !== null || gifUrl !== null;
```

- In `handleFile`, after `setFile(...)`, add `setGifUrl(null);`. A photo replaces a GIF.
- In `clearComposer`, add `setGifUrl(null); setShowGif(false);`.
- In `handleSubmit`, replace the payload construction and the post/upload sequence (`:111-154`) with:

```tsx
      const payload: any = { momentId, text: text.trim() };
      if (mode === "reply" && parentComment) {
        payload.parentComment = parentComment;
      }
      if (isCorrection) {
        payload.correction = {
          originalText: original.trim(),
          correctedText: corrected.trim(),
          explanation: explanation.trim(),
        };
      }
      // Photo in the same request, except for a correction, whose nested
      // `correction` object multipart can't carry: that keeps the two-step.
      const photoInline = !!file && !isCorrection;
      if (photoInline) payload.image = file;
      if (!file && gifUrl && !isCorrection) payload.imageUrl = gifUrl;

      setError(null);
      setNotice(null);

      let created: any;
      try {
        created = await addMomentComment(payload).unwrap();
      } catch (err: any) {
        setError(
          (err && err.data && (err.data.error || err.data.message)) ||
            (err && err.message) ||
            t("moments_section.commentEngagement.postFailed") ||
            "Couldn't post that. Try again."
        );
        return;
      }

      const commentId = created && created.data && created.data._id;
      if (file && !photoInline && commentId) {
        setIsUploading(true);
        try {
          await uploadCommentImage({ commentId, file }).unwrap();
        } catch (err) {
          setNotice(
            t("moments_section.commentEngagement.imageFailed") ||
              "Comment posted, but the photo didn't attach."
          );
        } finally {
          setIsUploading(false);
        }
      }
```

  Add `gifUrl` to the `useCallback` dependency array.
- Update the header doc comment. Replace the paragraph "An image is a second request: …" with:

  "A photo goes up in the same multipart request (createComment runs uploadSingleCompressed('image')), so a photo-only comment works. A correction is the exception: its nested `correction` object can't travel as multipart, so its photo still follows with PUT /comments/:id/image. A GIF is a Giphy URL in `imageUrl`."

- In the footer row, after the photo `<label>`, add (not for corrections):

```tsx
        {!isCorrection && (
          <button
            type="button"
            data-testid="comment-composer-gif"
            onClick={() => setShowGif((v) => !v)}
            disabled={pending}
            className="rounded-full border border-gray-200 px-2 py-0.5 text-[11px] font-bold text-gray-500 hover:text-blue-600 dark:border-gray-700"
          >
            GIF
          </button>
        )}
```

  Wrap the photo label and the GIF button in `<div className="flex items-center gap-3">`.
- Above that row, add:

```tsx
      {showGif && !isCorrection && (
        <GifPickerPanel
          onSelectGif={(url) => {
            setGifUrl(url);
            setFile(null);
            if (fileInputRef.current) fileInputRef.current.value = "";
            setShowGif(false);
          }}
          onClose={() => setShowGif(false)}
        />
      )}
      {gifUrl && (
        <div data-testid="comment-composer-gif-preview" className="relative inline-block">
          <img src={gifUrl} alt="GIF" className="max-h-32 rounded-xl" />
          <button
            type="button"
            onClick={() => setGifUrl(null)}
            aria-label={t("moments_section.commentEngagement.removeGif") || "Remove GIF"}
            className="absolute end-1 top-1 rounded-full bg-black/60 p-1 text-white"
          >
            <FaTimes className="h-3 w-3" />
          </button>
        </div>
      )}
```

Add to `eng.json` under `moments_section.commentEngagement`:

```json
"removeGif": "Remove GIF"
```

(The GIF picker's own strings already live under `chatPage.gif.*`.)

- [ ] **Step 4: Run → PASS.** Also run `CI=true npm test -- --watchAll=false comments TranslatableText`.

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/momentsSlice.ts src/store/slices/momentsSlice.endpoints.test.ts \
  src/components/moments/comments/CommentComposer.tsx src/components/moments/comments/CommentComposer.test.tsx \
  src/components/moments/comments/mentionText.tsx src/components/moments/comments/mentionText.test.tsx \
  src/components/moments/comments/types.ts src/components/moments/comments/CommentItem.tsx \
  src/components/moments/comments/CommentItem.test.tsx src/components/moments/TranslatableText.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(moments): photo-only and GIF comments, and app mentions drawn

createComment has taken a multipart image on the create call all along;
the web posted text first and attached the photo with a second request,
so a photo needed words. The photo now goes up in the same request (a
correction keeps the two-step: multipart can't carry its nested object),
a GIF picker sends a Giphy imageUrl like the app, and mentions written in
the app are highlighted by offset instead of showing as plain text.

Still open (Phase 3 moments): composing @mentions on web (needs a user
picker; photo comments can't carry mentions as multipart), leftovers,
recorder audio/mp4, i18n, stories tasks.
EOF
```

---

### Task P3-MOM-9: Leftovers: `uploadMomentPhotos` typing, no `mediaType: "text"`, dead `reportMoment` (moments#23)

**Files:**
- Modify: `src/store/slices/momentsSlice.ts:74-87` (type), `:157-164` (delete `reportMoment`), `:404` (drop `useReportMomentMutation` from the export list)
- Modify: `src/components/moments/CreateMoment.tsx:281-284` (no `mediaType`)
- Modify: `src/components/profile/EditMyMoment.tsx` (drop `as any` in the photo upload added by task 1)
- Test: `src/store/slices/momentsActionsEndpoints.test.ts` (extend), `src/components/moments/CreateMoment.test.tsx:107-115` (update)

**Interfaces:**
- Consumes: backend `createMoment` ignores `mediaType`. The model defaults it to `text` (`models/Moment.js:254-258`), and the photo/video/audio uploads set it.
- Produces:
  - `uploadMomentPhotos({momentId, imageFiles: FormData})` (type fix only; the runtime request is unchanged).
  - `reportMoment` and `useReportMomentMutation` are removed. Grep verified there are no callers outside the slice. Reports go through `POST /reports` (`ReportMomentDialog`).

- [ ] **Step 1: Write the failing tests**

Append to `momentsActionsEndpoints.test.ts`:

```ts
  it("uploadMomentPhotos -> PUT /api/v1/moments/:momentId/photo with FormData (field: file)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    const formData = new FormData();
    formData.append("file", new File(["x"], "a.jpg", { type: "image/jpeg" }));
    await store.dispatch(
      (momentsApiSlice.endpoints as any).uploadMomentPhotos.initiate({ momentId: "moment-1", imageFiles: formData })
    );
    expect(new URL(calls[0].url).pathname).toBe(`${MOMENTS_URL}/moment-1/photo`);
    expect(calls[0].method).toBe("PUT");
  });

  it("the legacy reportMoment endpoint is gone (reports use POST /reports)", () => {
    expect((momentsApiSlice.endpoints as any).reportMoment).toBeUndefined();
    expect((require("./momentsSlice") as any).useReportMomentMutation).toBeUndefined();
  });
```

In `CreateMoment.test.tsx`, replace the assertion in `it("a text moment carries its background; a photo moment does not", ...)`:

```tsx
  expect(payload()).toEqual(expect.objectContaining({ mediaType: "text", backgroundColor: "gradient_ocean" }));
```
with:
```tsx
  expect(payload()).toEqual(expect.objectContaining({ backgroundColor: "gradient_ocean" }));
  // The server ignores mediaType on create (the model defaults to text).
  expect(payload()).not.toHaveProperty("mediaType");
```

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false momentsActionsEndpoints CreateMoment`
Expected: FAIL. `reportMoment` is defined and the payload still has `mediaType`. The photo test passes already, since only the type changes.

- [ ] **Step 3: Implement**

`momentsSlice.ts:78-81`. Change the parameter type `imageFiles: File[];` to:

```ts
        /** multipart body with one `file` entry per photo (field name the
         *  route's uploadMultiple expects). */
        imageFiles: FormData;
```

Delete the `// Report moment` block (`:157-164`) and `useReportMomentMutation,` from the export list.

`CreateMoment.tsx:281-284`:

```tsx
      if (mediaMode === "text") {
        payload.mediaType = "text";
        if (backgroundColor) payload.backgroundColor = backgroundColor;
      }
```
→
```tsx
      if (mediaMode === "text" && backgroundColor) payload.backgroundColor = backgroundColor;
```

`EditMyMoment.tsx`. In `uploadPhotos` (task 1), change `imageFiles: upload as any,` to `imageFiles: upload,`.

- [ ] **Step 4: Run → PASS.** Then run `npx tsc --noEmit -p . 2>&1 | grep -E "momentsSlice|CreateMoment|EditMyMoment" || echo clean`. Expected: `clean`.

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/momentsSlice.ts src/store/slices/momentsActionsEndpoints.test.ts \
  src/components/moments/CreateMoment.tsx src/components/moments/CreateMoment.test.tsx \
  src/components/profile/EditMyMoment.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
chore(moments): type the photo upload as FormData, drop dead mediaType and reportMoment

uploadMomentPhotos was typed File[] but always sent FormData; the
composer sent mediaType "text", which createMoment ignores; reportMoment
hit the legacy route and nothing called it (reports go through POST
/reports).

Still open (Phase 3 moments): recorder audio/mp4, i18n, stories tasks.
EOF
```

---

### Task P3-MOM-10: Moment voice notes record `audio/mp4` where the browser can (moments#2)

**Files:**
- Shared, from P3-CHAT-9: `src/utils/recorderMime.ts` + `src/utils/recorderMime.test.ts`. CHAT is pushed before MOMENTS. If this task starts before the CHAT push, copy both files **verbatim** from P3-CHAT-9 Step 1/Step 3 (same bytes, so the MOMENTS rebase drops the duplicate cleanly); if CHAT is already on `origin/main`, rebase first and skip the copy. Never change their API here.
- Create: `src/utils/audioUpload.ts`, `src/utils/audioUpload.test.ts`
- Modify: `src/components/moments/media/VoiceNoteRecorder.tsx:130-138,193`
- Modify: `src/components/moments/CreateMoment.tsx:308-313`, `src/components/moments/fields/MediaEditor.tsx:65-70`
- Test: `src/components/moments/media/VoiceNoteRecorder.test.tsx` (new)

**Interfaces:**
- Consumes:
  - `pickRecorderMime(): {mimeType: string|undefined; ext: string}`, `baseMime(mime: string): string` (returns `"audio/webm"` for an empty type), `extForMime(mime: string): string` from `src/utils/recorderMime.ts` (P3-CHAT-9).
  - Backend upload whitelist (`middleware/uploadToSpaces.js:65-81`) accepts `audio/mp4`, `audio/aac`, `audio/webm`, `audio/ogg`.
  - Phase 1 P1-MOM-4 transcodes anything outside the pass-through list (`audio/mpeg|mp3|aac|x-aac|mp4|m4a|x-m4a`) to AAC, so a WebM note from an older browser still ends up playable.
- Produces: `audioUpload(blob: Blob, baseName: string): { blob: Blob; filename: string }` from `src/utils/audioUpload.ts` (type without codec parameters, extension matching the type).

- [ ] **Step 1: Write the failing tests**

`src/utils/audioUpload.test.ts`:

```ts
import { audioUpload } from "./audioUpload";

it("names the upload after its real type and drops codec parameters", () => {
  const mp4 = audioUpload(new Blob(["x"], { type: "audio/mp4;codecs=mp4a.40.2" }), "voice-note");
  expect(mp4.filename).toBe("voice-note.m4a");
  expect(mp4.blob.type).toBe("audio/mp4");
});

it("an untyped blob is uploaded as WebM (the server transcodes it)", () => {
  const untyped = audioUpload(new Blob(["x"]), "voice-note");
  expect(untyped.filename).toBe("voice-note.webm");
  expect(untyped.blob.type).toBe("audio/webm");
});

it("keeps the same blob when its type is already clean", () => {
  const blob = new Blob(["x"], { type: "audio/ogg" });
  const out = audioUpload(blob, "n");
  expect(out.blob).toBe(blob);
  expect(out.filename).toBe("n.ogg");
});
```

`src/components/moments/media/VoiceNoteRecorder.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, waitFor } from "@testing-library/react";
import VoiceNoteRecorder from "./VoiceNoteRecorder";

const ctorCalls: any[] = [];
class FakeRecorder {
  static isTypeSupported = (t: string) => t === "audio/mp4";
  mimeType: string;
  state = "inactive";
  ondataavailable: any = null;
  onstop: any = null;
  constructor(_stream: any, options?: any) {
    ctorCalls.push(options);
    this.mimeType = (options && options.mimeType) || "audio/webm";
  }
  start() { this.state = "recording"; }
  stop() { this.state = "inactive"; if (this.onstop) this.onstop(); }
}

beforeEach(() => {
  ctorCalls.length = 0;
  (window as any).MediaRecorder = FakeRecorder;
  (navigator as any).mediaDevices = {
    getUserMedia: jest.fn(() => Promise.resolve({ getTracks: () => [{ stop: jest.fn() }] })),
  };
});
afterEach(() => {
  delete (window as any).MediaRecorder;
  delete (navigator as any).mediaDevices;
});

it("asks MediaRecorder for audio/mp4 when the browser supports it (moments#2)", async () => {
  render(<VoiceNoteRecorder onComplete={jest.fn()} onCancel={jest.fn()} />);
  await waitFor(() => expect(ctorCalls).toHaveLength(1));
  expect(ctorCalls[0]).toEqual({ mimeType: "audio/mp4" });
});

it("falls back to the browser default when the typed constructor throws (Safari < 18.4)", async () => {
  const Throwing: any = function (this: any, stream: any, options?: any) {
    if (options && options.mimeType) throw new Error("NotSupportedError");
    return new (FakeRecorder as any)(stream);
  };
  Throwing.isTypeSupported = () => true;
  (window as any).MediaRecorder = Throwing;
  const { findByTestId } = render(<VoiceNoteRecorder onComplete={jest.fn()} onCancel={jest.fn()} />);
  expect(await findByTestId("voice-note-recorder")).toBeInTheDocument();
  expect(ctorCalls[ctorCalls.length - 1]).toBeUndefined();
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false audioUpload VoiceNoteRecorder`
Expected: FAIL. `./audioUpload` can't be resolved; the recorder constructor is called with no options; in the throwing case status becomes `denied`, so `voice-note-recorder` isn't rendered.

- [ ] **Step 3: Implement**

`src/utils/audioUpload.ts`:

```ts
import { baseMime, extForMime } from "./recorderMime";

/**
 * The recorded blob as it should be uploaded: its type without codec
 * parameters (the upload whitelist compares the base type) and a file name
 * whose extension matches, e.g. voice-note.m4a for audio/mp4.
 */
export function audioUpload(blob: Blob, baseName: string): { blob: Blob; filename: string } {
  const type = baseMime(blob.type);
  const out = blob.type === type ? blob : new Blob([blob], { type });
  return { blob: out, filename: `${baseName}.${extForMime(type)}` };
}
```

`VoiceNoteRecorder.tsx`:
- Add `import { pickRecorderMime } from '../../../utils/recorderMime';`.
- Replace `:193` `const recorder = new MediaRecorder(stream);` with:

```tsx
      // AAC/MP4 where the browser can (plays in the iOS app); otherwise the
      // browser's default. A typed constructor can throw on Safari < 18.4.
      const preferred = pickRecorderMime().mimeType;
      let recorder: MediaRecorder;
      try {
        recorder = preferred ? new MediaRecorder(stream, { mimeType: preferred }) : new MediaRecorder(stream);
      } catch (e) {
        recorder = new MediaRecorder(stream);
      }
```

- In `finishRecording` (`:130-138`), change both fallbacks `'audio/webm'` to `recorder.mimeType || 'audio/webm'` (the `recorder.state === 'inactive'` branch currently hard-codes `'audio/webm'`).

`CreateMoment.tsx:308-313`:

```tsx
        } else if (mediaMode === "voice" && audioNote && momentId) {
          const formData = new FormData();
          formData.append("audio", audioNote.blob, "voice-note.webm");
```
→
```tsx
        } else if (mediaMode === "voice" && audioNote && momentId) {
          const formData = new FormData();
          const upload = audioUpload(audioNote.blob, "voice-note");
          formData.append("audio", upload.blob, upload.filename);
```

Add `import { audioUpload } from "../../utils/audioUpload";`.

`MediaEditor.tsx:68`: replace `formData.append("audio", blob, "voice-note.webm");` with:

```tsx
    const upload = audioUpload(blob, "voice-note");
    formData.append("audio", upload.blob, upload.filename);
```

Add `import { audioUpload } from "../../../utils/audioUpload";`.

- [ ] **Step 4: Run → PASS.** Also `CI=true npm test -- --watchAll=false recorderMime MediaEditor CreateMoment`.

- [ ] **Step 5: Commit**

```bash
git add src/utils/audioUpload.ts src/utils/audioUpload.test.ts \
  src/components/moments/media/VoiceNoteRecorder.tsx src/components/moments/media/VoiceNoteRecorder.test.tsx \
  src/components/moments/CreateMoment.tsx src/components/moments/fields/MediaEditor.tsx docs/REMAINING_WORK.md
# only if copied before the CHAT push: git add src/utils/recorderMime.ts src/utils/recorderMime.test.ts
git commit -F - <<'EOF'
fix(moments): record voice notes as audio/mp4 where the browser can

Web moment voice notes were always WebM/Opus named voice-note.webm,
which AVPlayer (the iOS app's player) can't open. The recorder now asks
for AAC in MP4 first (shared recorderMime helper from the chat unit),
falls back to the browser default and survives Safari < 18.4 throwing on
a typed constructor; the upload is named for its real type without codec
parameters. WebM from older browsers is transcoded server-side (Phase 1).

Still open (Phase 3 moments): i18n, stories tasks; device QA: a web
voice note plays in the iOS app (QA sheet row).
EOF
```

---

### Task P3-MOM-11: Moments text in every language: Saved Moments keys and hard-coded English (moments#24)

**Files:**
- Modify: `src/components/moments/SavedMoments.tsx` (`moments.saved.*` → `moments_section.saved.*`)
- Modify: `src/components/moments/SingleMoment.tsx`, `src/components/moments/CreateMoment.tsx`, `src/components/moments/media/VoiceNoteRecorder.tsx`, `src/components/moments/MainMoments.tsx`, `src/components/moments/MomentDetail.tsx` (literals → `t()`)
- Modify: `src/utils/locales/eng.json`
- Test: `src/components/moments/momentsCopy.test.ts` (new)

**Interfaces:**
- Consumes: `eng.json` `"moments": "Moments"` is a string. The navbar reads it (`MainNavbar.tsx:245,407`), so it can't become an object. That is why every `moments.saved.*` lookup fell back to English.
- Produces: the keys listed at the end of this section, all under `moments_section.*`. The coordinator's i18n task translates them into the 17 other locales.

- [ ] **Step 1: Write the failing test** `src/components/moments/momentsCopy.test.ts`

```ts
import fs from "fs";
import path from "path";

// Every moments_section.* key these files use must exist in eng.json, and
// none may use the unreachable `moments.` root ("moments" is a string).
const FILES = [
  "SavedMoments.tsx",
  "SingleMoment.tsx",
  "CreateMoment.tsx",
  "MainMoments.tsx",
  "MomentDetail.tsx",
  "MomentChips.tsx",
  "media/VoiceNoteRecorder.tsx",
  "media/MomentThumb.tsx",
  "comments/CommentItem.tsx",
  "comments/CommentComposer.tsx",
  "actions/ReportMomentDialog.tsx",
  "actions/BlockAuthorDialog.tsx",
];

const eng = JSON.parse(fs.readFileSync(path.join(__dirname, "../../utils/locales/eng.json"), "utf8"));
const has = (key: string): boolean => {
  let node: any = eng;
  const parts = key.split(".");
  for (let i = 0; i < parts.length; i += 1) {
    if (!node || typeof node !== "object") return false;
    node = node[parts[i]];
  }
  return typeof node === "string";
};

const keysIn = (file: string): string[] => {
  const source = fs.readFileSync(path.join(__dirname, file), "utf8");
  const out: string[] = [];
  const re = /\bt\(\s*["'`]([A-Za-z0-9_.]+)["'`]/g;
  let m = re.exec(source);
  while (m) {
    if (out.indexOf(m[1]) < 0) out.push(m[1]);
    m = re.exec(source);
  }
  return out;
};

it("no moments file reads the unreachable moments.* root", () => {
  FILES.forEach((file) => {
    const bad = keysIn(file).filter((k) => k.indexOf("moments.") === 0);
    expect({ file, bad }).toEqual({ file, bad: [] });
  });
});

it("every moments_section.* key the moments UI uses exists in eng.json", () => {
  FILES.forEach((file) => {
    // ReportMomentDialog builds keys from a table; its template key is skipped.
    const missing = keysIn(file).filter((k) => k.indexOf("moments_section.") === 0 && !has(k));
    expect({ file, missing }).toEqual({ file, missing: [] });
  });
});

it("the Saved page's seven strings are reachable", () => {
  ["title", "momentCount", "removeSuccess", "removeError", "remove", "noMoments", "browseMoments"].forEach((k) =>
    expect(has(`moments_section.saved.${k}`)).toBe(true)
  );
});

it("no hard-coded English left in the audited spots", () => {
  const read = (f: string) => fs.readFileSync(path.join(__dirname, f), "utf8");
  expect(read("SingleMoment.tsx")).not.toMatch(/toast\.error\("Please login to like posts"/);
  expect(read("SingleMoment.tsx")).not.toMatch(/\? "See less" : "See more"/);
  expect(read("media/VoiceNoteRecorder.tsx")).not.toMatch(/<span>Voice recording is not supported/);
  expect(read("MainMoments.tsx")).not.toMatch(/>\s*Prompt of the day\s*</);
  expect(read("MomentDetail.tsx")).not.toMatch(/>Tags:</);
  expect(read("CreateMoment.tsx")).not.toMatch(/\? 'Sharing\.\.\.' : 'Share'/);
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `CI=true npm test -- --watchAll=false momentsCopy`
Expected: FAIL. `SavedMoments.tsx` uses `moments.saved.*`, the `moments_section.saved.title` key doesn't exist yet, and the literal checks fail.

- [ ] **Step 3: Implement**

Replace each literal with the expression shown. Every `t` key below gets the English shown in `eng.json`. `VoiceNoteRecorder.tsx` has no `t` today: add `import { useTranslation } from 'react-i18next';` and `const { t } = useTranslation();` at the top of the component.

| File (fba6208 line) | Current | Replacement |
|---|---|---|
| `SavedMoments.tsx:51` | `t("moments.saved.removeSuccess")` | `t("moments_section.saved.removeSuccess")` |
| `SavedMoments.tsx:60` | `t("moments.saved.removeError")` | `t("moments_section.saved.removeError")` |
| `SavedMoments.tsx:174` | `t("moments.saved.remove")` | `t("moments_section.saved.remove")` |
| `SavedMoments.tsx:238` | `t("moments.saved.title")` | `t("moments_section.saved.title")` |
| `SavedMoments.tsx:280` | `t("moments.saved.noMoments")` | `t("moments_section.saved.noMoments")` |
| `SavedMoments.tsx:286` | `t("moments.saved.browseMoments")` | `t("moments_section.saved.browseMoments")` |
| (`:241` was moved in task 6) | `moments.saved.momentCount` | already `moments_section.saved.momentCount` |
| `SingleMoment.tsx:247` | `toast.error("Please login to like posts", {` | `toast.error(t("moments_section.card.loginToLike") \|\| "Please log in to like posts", {` |
| `SingleMoment.tsx:276` | `toast.error("Something went wrong", {` | `toast.error(t("moments_section.card.likeFailed") \|\| "Something went wrong", {` |
| `SingleMoment.tsx:451` | `{showFullDescription ? "See less" : "See more"}` | `{showFullDescription ? t("moments_section.card.seeLess") \|\| "See less" : t("moments_section.card.seeMore") \|\| "See more"}` |
| `SingleMoment.tsx:530-531` | `{commentCountNumber.toLocaleString()} comment{commentCountNumber !== 1 ? "s" : ""}` | `{t("moments_section.commentsCount", { count: commentCountNumber }) \|\| `${commentCountNumber.toLocaleString()} comments`}` (existing key `"{{count}} Comments"`) |
| `SingleMoment.tsx:549` | `aria-label="React"` | `aria-label={t("moments_section.commentEngagement.react") \|\| "React"}` |
| `SingleMoment.tsx:568` | `aria-label={saved ? "Remove bookmark" : "Bookmark"}` | `aria-label={saved ? t("moments_section.card.removeBookmark") \|\| "Remove bookmark" : t("moments_section.card.bookmark") \|\| "Bookmark"}` |
| `SingleMoment.tsx:625` | `{isLoadingLike ? (liked ? "Unliking..." : "Liking...") : "Like"}` | `{t("moments_section.likeButton") \|\| "Like"}` (`isLoadingLike` is always false, so the branch was dead) |
| `SingleMoment.tsx:635,642` | `aria-label="Comment"`, `Comment` | `t("moments_section.commentButton") \|\| "Comment"` |
| `SingleMoment.tsx:613` | `aria-label={liked ? "Unlike" : "Like"}` | `aria-label={liked ? t("moments_section.card.unlike") \|\| "Unlike" : t("moments_section.likeButton") \|\| "Like"}` |
| `CreateMoment.tsx:201` | `toast.error("Maximum 10 images allowed", {` | `toast.error(t("createMoment.toast.maxImagesError") \|\| "Maximum 10 images allowed", {` (existing key) |
| `CreateMoment.tsx:389` | `{isSubmitting ? 'Sharing...' : 'Share'}` | `{isSubmitting ? t("moments_section.create.sharing") \|\| "Sharing..." : t("moments_section.create.share") \|\| "Share"}` |
| `CreateMoment.tsx:428-431` | `label: "Photo"` / `"Video"` / `"Voice"` / `"Text"` | `label: t("moments_section.create.modePhoto") \|\| "Photo"` (and `modeVideo`, `modeVoice`, `modeText`) |
| `CreateMoment.tsx:494` | `` placeholder={`What's on your mind, ${userInfo?.name?.split(' ')[0] \|\| 'there'}?`} `` | `` placeholder={t("moments_section.create.placeholder", { name: userInfo?.name?.split(" ")[0] \|\| "" }) \|\| `What's on your mind, ${userInfo?.name?.split(" ")[0] \|\| "there"}?`} `` |
| `CreateMoment.tsx:558` | `Attach a video` | `{t("moments_section.create.attachVideo") \|\| "Attach a video"}` |
| `CreateMoment.tsx:579` | `Voice note · {Math.round(audioNote.dur)}s` | `{t("moments_section.create.voiceNoteLength", { seconds: Math.round(audioNote.dur) }) \|\| `Voice note · ${Math.round(audioNote.dur)}s`}` |
| `CreateMoment.tsx:586` | `Remove` | `{t("moments_section.create.remove") \|\| "Remove"}` |
| `CreateMoment.tsx:596` | `Record a voice note` | `{t("moments_section.create.recordVoice") \|\| "Record a voice note"}` |
| `CreateMoment.tsx:609` | `text={description \|\| "Your text moment"}` | `text={description \|\| t("moments_section.create.textPreview") \|\| "Your text moment"}` |
| `CreateMoment.tsx:681` | `How are you feeling?` | `{t("moments_section.create.moodQuestion") \|\| "How are you feeling?"}` |
| `VoiceNoteRecorder.tsx:249` | `<span>Voice recording is not supported in this browser.</span>` | `<span>{t("moments_section.voice.unsupported") \|\| "Voice recording is not supported in this browser."}</span>` |
| `VoiceNoteRecorder.tsx:260` | `<span>Microphone access was denied. …</span>` | `<span>{t("moments_section.voice.denied") \|\| "Microphone access was denied. Please allow microphone access to record a voice note."}</span>` |
| `VoiceNoteRecorder.tsx:273` | `aria-label="Cancel recording"` | `aria-label={t("moments_section.voice.cancel") \|\| "Cancel recording"}` |
| `VoiceNoteRecorder.tsx:315` | `aria-label="Stop recording and send"` | `aria-label={t("moments_section.voice.stop") \|\| "Stop recording and send"}` |
| `MainMoments.tsx:168` | `Something went wrong` | `{t("moments_section.error_loading") \|\| "Something went wrong"}` (existing key) |
| `MainMoments.tsx:195` | `aria-label="Add new moment"` | `aria-label={t("moments_section.create.header") \|\| "Create moment"}` (existing key) |
| `MainMoments.tsx:451` | `aria-label="Dismiss prompt of the day"` | `aria-label={t("moments_section.prompt.dismissCard") \|\| "Dismiss prompt of the day"}` |
| `MainMoments.tsx:464` | `Prompt of the day` | `{t("moments_section.prompt.cardTitle") \|\| "Prompt of the day"}` |
| `MainMoments.tsx:470` | `Practice writing` | `{t("moments_section.prompt.cardSubtitle") \|\| "Practice writing"}` |
| `MainMoments.tsx:475` | `<span>Answer</span>` | `<span>{t("moments_section.prompt.answer") \|\| "Answer"}</span>` |
| `MomentDetail.tsx:160` | `<span …>Tags:</span>` | `<span …>{t("moments_section.fields.tags") \|\| "Tags"}</span>`. `TagsList` is a `React.memo` outside the component, so add `const { t } = useTranslation();` inside it. |
| `MomentDetail.tsx:228,235` | `aria-label="Previous image"` / `"Next image"` | `aria-label={t("moments_section.lightbox.previous") \|\| "Previous image"}` / `…next \|\| "Next image"`. Check the existing `moments_section.lightbox` keys first and reuse them if present. |
| `MomentDetail.tsx:724` | `aria-label={saved ? "Remove bookmark" : "Bookmark"}` | same as SingleMoment (`moments_section.card.*`) |
| `MomentDetail.tsx:733` | `{saved ? "Saved" : "Save"}` | `{saved ? t("moments_section.card.saved") \|\| "Saved" : t("moments_section.card.save") \|\| "Save"}` |

`SingleMoment.test.tsx` mocks `t` as `(key) => key`. Any test querying "See more" or "Like" by text would see keys. Today it queries none (verified with grep: only `scheduled-badge`). The `MainMoments.test.tsx` strings it asserts ("Follow people…", "Find people") already go through `t(...) ||` and are untouched.

Merge into `eng.json` (deep-merge into the existing `moments_section` object; don't replace it):

```json
{
  "moments_section": {
    "saved": {
      "title": "Saved Moments",
      "momentCount": "moments saved",
      "removeSuccess": "Removed from saved",
      "removeError": "Failed to remove moment",
      "remove": "Remove",
      "noMoments": "No saved moments yet",
      "browseMoments": "Browse Moments",
      "loadMore": "Load more",
      "gridView": "Grid view",
      "listView": "List view"
    },
    "card": {
      "loginToLike": "Please log in to like posts",
      "likeFailed": "Something went wrong",
      "seeMore": "See more",
      "seeLess": "See less",
      "bookmark": "Bookmark",
      "removeBookmark": "Remove bookmark",
      "unlike": "Unlike",
      "save": "Save",
      "saved": "Saved"
    },
    "create": {
      "sharing": "Sharing...",
      "share": "Share",
      "modePhoto": "Photo",
      "modeVideo": "Video",
      "modeVoice": "Voice",
      "modeText": "Text",
      "placeholder": "What's on your mind, {{name}}?",
      "attachVideo": "Attach a video",
      "voiceNoteLength": "Voice note · {{seconds}}s",
      "remove": "Remove",
      "recordVoice": "Record a voice note",
      "textPreview": "Your text moment",
      "moodQuestion": "How are you feeling?"
    },
    "voice": {
      "unsupported": "Voice recording is not supported in this browser.",
      "denied": "Microphone access was denied. Please allow microphone access to record a voice note.",
      "cancel": "Cancel recording",
      "stop": "Stop recording and send"
    },
    "prompt": {
      "cardTitle": "Prompt of the day",
      "cardSubtitle": "Practice writing",
      "answer": "Answer",
      "dismissCard": "Dismiss prompt of the day"
    },
    "lightbox": {
      "previous": "Previous image",
      "next": "Next image"
    }
  }
}
```

(`moments_section.lightbox` already exists. Add only the keys it lacks and keep the existing ones.) Do the merge with a one-off node script so key order and other keys are preserved:

```bash
node -e '
const fs=require("fs");const p="src/utils/locales/eng.json";
const e=JSON.parse(fs.readFileSync(p,"utf8"));const add=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
const m=(t,s)=>{for(const[k,v]of Object.entries(s)){if(v&&typeof v==="object"&&!Array.isArray(v)){t[k]=m(t[k]&&typeof t[k]==="object"?t[k]:{},v)}else if(t[k]===undefined){t[k]=v}}return t};
m(e,add);fs.writeFileSync(p,JSON.stringify(e,null,2)+"\n");' /tmp/moments-eng-keys.json
```

Write the JSON block above to `/tmp/moments-eng-keys.json` first. The script never overwrites an existing key.

The 7 old `moments.saved.*` keys exist in **no** locale file (audit #24). There is nothing to delete.

- [ ] **Step 4: Run → PASS.** Then run the whole moments area: `CI=true npm test -- --watchAll=false src/components/moments src/components/profile/EditMyMoment src/components/profile/MyMoments`.

- [ ] **Step 5: Commit**

```bash
git add src/components/moments/SavedMoments.tsx src/components/moments/SingleMoment.tsx \
  src/components/moments/CreateMoment.tsx src/components/moments/media/VoiceNoteRecorder.tsx \
  src/components/moments/MainMoments.tsx src/components/moments/MomentDetail.tsx \
  src/components/moments/momentsCopy.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(moments): Saved Moments and the moments UI read real translation keys

"moments" in eng.json is the navbar's string, so every moments.saved.*
lookup fell back to English in all 18 languages. Those keys now live
under moments_section.saved, and the hard-coded English toasts, labels
and aria-labels in the card, composer, recorder, feed and detail go
through t(). English is in eng.json; the other 17 locales follow in the
unit's i18n task. A test pins that no moments file reads moments.*.

Still open (Phase 3 moments): 17-locale translations of the new
moments_section keys (unit i18n task), stories tasks (P3-MOM-12+).
EOF
```

---

#### Keys added by P3-MOM-1..11 (all in `eng.json`, English only; translate into the 17 other locales)

| Key | English | Task |
|---|---|---|
| `moments_section.create.mediaFailedNothingPosted` | The upload failed, so nothing was posted. Try again. | 1 |
| `moments_section.create.mediaFailedPosted` | Posted, but media upload failed — try editing the moment to add it. | 1 |
| `moments_section.commentEngagement.deleteOthersTitle` | Delete this comment? | 4 |
| `moments_section.commentEngagement.deleteOthersBody` | It's on your moment, so you can remove it. This can't be undone. | 4 |
| `moments_section.report.titleComment` | Report this comment | 5 |
| `moments_section.report.titleStory` | Report this story | 5 |
| `moments_section.report.alreadyComment` | You've already reported this comment. | 5 |
| `moments_section.report.alreadyStory` | You've already reported this story. | 5 |
| `moments_section.block.done` | {{name}} is blocked. | 5 |
| `moments_section.saved.loadMore` | Load more | 6 |
| `moments_section.saved.gridView` | Grid view | 6 |
| `moments_section.saved.listView` | List view | 6 |
| `moments_section.saved.momentCount` | moments saved | 6 |
| `moments_section.commentEngagement.removeGif` | Remove GIF | 8 |
| `moments_section.saved.title` | Saved Moments | 11 |
| `moments_section.saved.removeSuccess` | Removed from saved | 11 |
| `moments_section.saved.removeError` | Failed to remove moment | 11 |
| `moments_section.saved.remove` | Remove | 11 |
| `moments_section.saved.noMoments` | No saved moments yet | 11 |
| `moments_section.saved.browseMoments` | Browse Moments | 11 |
| `moments_section.card.loginToLike` | Please log in to like posts | 11 |
| `moments_section.card.likeFailed` | Something went wrong | 11 |
| `moments_section.card.seeMore` | See more | 11 |
| `moments_section.card.seeLess` | See less | 11 |
| `moments_section.card.bookmark` | Bookmark | 11 |
| `moments_section.card.removeBookmark` | Remove bookmark | 11 |
| `moments_section.card.unlike` | Unlike | 11 |
| `moments_section.card.save` | Save | 11 |
| `moments_section.card.saved` | Saved | 11 |
| `moments_section.create.sharing` | Sharing... | 11 |
| `moments_section.create.share` | Share | 11 |
| `moments_section.create.modePhoto` | Photo | 11 |
| `moments_section.create.modeVideo` | Video | 11 |
| `moments_section.create.modeVoice` | Voice | 11 |
| `moments_section.create.modeText` | Text | 11 |
| `moments_section.create.placeholder` | What's on your mind, {{name}}? | 11 |
| `moments_section.create.attachVideo` | Attach a video | 11 |
| `moments_section.create.voiceNoteLength` | Voice note · {{seconds}}s | 11 |
| `moments_section.create.remove` | Remove | 11 |
| `moments_section.create.recordVoice` | Record a voice note | 11 |
| `moments_section.create.textPreview` | Your text moment | 11 |
| `moments_section.create.moodQuestion` | How are you feeling? | 11 |
| `moments_section.voice.unsupported` | Voice recording is not supported in this browser. | 11 |
| `moments_section.voice.denied` | Microphone access was denied. Please allow microphone access to record a voice note. | 11 |
| `moments_section.voice.cancel` | Cancel recording | 11 |
| `moments_section.voice.stop` | Stop recording and send | 11 |
| `moments_section.prompt.cardTitle` | Prompt of the day | 11 |
| `moments_section.prompt.cardSubtitle` | Practice writing | 11 |
| `moments_section.prompt.answer` | Answer | 11 |
| `moments_section.prompt.dismissCard` | Dismiss prompt of the day | 11 |
| `moments_section.lightbox.previous` | Previous image (only if not already present) | 11 |
| `moments_section.lightbox.next` | Next image (only if not already present) | 11 |

Existing keys reused, with no new translation needed: `profile.block.title`, `profile.block.body`, `profile.actions.block|cancel|this_person|action_failed`, `createMoment.toast.maxImagesError`, `moments_section.commentsCount`, `moments_section.likeButton`, `moments_section.commentButton`, `moments_section.error_loading`, `moments_section.create.header`, `moments_section.fields.tags`, `moments_section.commentEngagement.react|delete|cancel`, `moments_section.report.*`, `chatPage.gif.*`.


### Stories (P3-MOM-12 … P3-MOM-20): base, conventions, and the accepted gap

- **Worktree:** `/Users/davis/Desktop/Personal/wt-web-p3-moments` (branch `web/p3-moments`), the same one P3-MOM-1…11 use.
  These tasks run **after** P3-MOM-1…11 in that worktree. Line numbers below are from `fba6208`. Earlier tasks shift
  them, so anchor every edit on the quoted code, not on the number.
- **Files these tasks own:** `src/components/stories/{CreateStory,StoryViewer,StoryCanvas,HighlightStoryViewer}.tsx`,
  `src/components/stories/storyOverlays.ts`, their tests, and one line each in `tailwind.config.js` and
  `src/store/slices/usersSlice.ts`. P3-MOM-1…11 touch none of these except `usersSlice.ts`. See the P3-MOM-14 note.
- **House rules for `src/components/stories/**`** (`storiesStyling.test.ts`, which already runs in the full suite):
  - Hex colours only in `storyOverlays.ts`, `CreateStory.tsx` and `storyBackground.ts`, never inside a `className`.
  - Inline style only for an overlay's position (`...overlayPositionStyle(...)` / `mentionPositionStyle(...)`), an
    overlay's `color`, and a text story's palette.
  - Emoji only inside a declared `const UPPER = [` palette.

  Every task below keeps to these rules. The full suite proves it, so no extra test is needed.
- **RTL:** story coordinates are fractions of the picture and must not mirror. Keep `left`/`top` as physical properties,
  as they are today. Do not switch them to `inset-inline-start`. Chrome around the picture (header, menus) uses flex and
  logical spacing (`ms-*`/`me-*`/`ps-*`), so it mirrors.
- **Old stories (app 2.6.1, pre-merge backend):** `location`, `hashtags`, `allowReplies`, `allowSharing`, `link.host`,
  `overlays[].rotation` and `fontStyle` can each be missing or `null`.
  - Every reader treats missing as the app does: replies and sharing allowed (`!== false`), no location, no tags,
    rotation 0, font `normal`.
  - Before Phase 1 item 0, the backend strips `link.host`. The viewer falls back to parsing `link.url`.

**Accepted gap (moments#3, no task):** the app's text-story branch (`story_viewer_screen.dart:994-1057`) draws no poll,
question, link or location. So stickers on a **web** text story stay invisible to app 2.6.1 users until they update to
2.7.0, which draws them (Phase 2). The web composer keeps offering them, as decided in the spec. No web code changes.

**Found while planning (app side, not a web task):** the app viewer places overlays and mentions with approximate pixel
offsets:
- overlays at `left: x*w - 60, top: y*h - 20` (`viewer_overlay_layer.dart:111-112`);
- mentions at `-40/-14` (`story_viewer_screen.dart:338-339`).

The app's own composer (`studio/story_canvas.dart:160-162`) writes `x`/`y` as the overlay's **centre**, as the wire
contract says (`overlay_draft.dart:18`). The web already centres exactly, so the web stays as it is (P3-MOM-17 pins it),
and the app's offsets go on the app's `docs/REMAINING_WORK.md` as a Phase 2 follow-up. **Coordinator: add that line
when this unit lands.**

---

### Task P3-MOM-12: a story carries one picture (moments#16)

The web picker takes up to 5 images (`CreateStory.tsx:288-289`, `multiple` at `:702`). The backend stores all of them,
but every viewer draws only `mediaUrls[0]`: the web's `storyMediaUrl()` and the app's `story_viewer_screen.dart:1066`
(`story.mediaUrl`). Images 2-5 are uploaded and never seen.

The app composer posts one picture, so the web matches it: a single-picture picker. If several files still arrive (a
browser that ignores the missing `multiple`, or a drag onto the input), the composer keeps the first and says so.

**Files:**
- Modify: `src/components/stories/CreateStory.tsx:288-289` (`images.slice(0, 5)`), `:702` (`multiple`).
- Modify: `src/utils/locales/eng.json` (`stories.one_image_only`).
- Test: `src/components/stories/CreateStory.test.tsx`. Extend the `notify` mock and add a `describe`.

**Interfaces:**
- Consumes: `POST /api/v1/stories`, multipart field `media`. Unchanged, and still accepts 1-5.
- Produces: `CreateStory` sends exactly one `media` part for an image story.

- [ ] **Step 1: Write the failing test.** In `CreateStory.test.tsx`, replace the notify mock:

```tsx
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn() },
}));
```
with:
```tsx
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn(), info: jest.fn() },
}));
```
and append:

```tsx
describe("one picture per story (moments#16)", () => {
  const jpg = (name: string) => new File(["x"], name, { type: "image/jpeg" });

  it("offers a single-picture picker", () => {
    render(<CreateStory />);
    expect(screen.getByTestId("photo-input")).not.toHaveAttribute("multiple");
  });

  it("keeps the first of several pictures, says so, and uploads only that one", async () => {
    render(<CreateStory />);
    fireEvent.change(screen.getByTestId("photo-input"), {
      target: { files: [jpg("a.jpg"), jpg("b.jpg"), jpg("c.jpg")] },
    });
    // Every viewer (web and app) draws mediaUrls[0] only; 2-5 were invisible.
    expect(notify.info).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getByTestId("share-story"));
    await waitFor(() => expect(mockCreateStory).toHaveBeenCalled());
    const form = mockCreateStory.mock.calls[0][0] as FormData;
    const sent = form.getAll("media") as File[];
    expect(sent).toHaveLength(1);
    expect(sent[0].name).toBe("a.jpg");
  });

  it("does not nag when one picture was picked", () => {
    render(<CreateStory />);
    fireEvent.change(screen.getByTestId("photo-input"), { target: { files: [jpg("a.jpg")] } });
    expect(notify.info).not.toHaveBeenCalled();
    expect(screen.getByTestId("story-canvas")).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run it and confirm it fails.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/CreateStory.test.tsx
```
Expected:
- "offers a single-picture picker" fails: the attribute is present.
- "keeps the first…" fails on `notify.info` (0 calls), and then would fail on 3 `media` parts.
- The third test passes.

- [ ] **Step 3: Implement.** In `CreateStory.tsx`, replace:

```tsx
      if (images.length > 0) {
        setMediaType("image");
        setMediaFiles(images.slice(0, 5));
        setMediaPreviews(images.slice(0, 5).map((file) => URL.createObjectURL(file)));
        setStep("edit");
      }
```
with:
```tsx
      if (images.length > 0) {
        // One picture per story, as in the app: every viewer (this one and
        // the app's) draws mediaUrls[0] only, so pictures 2-5 used to be
        // uploaded and never seen by anyone.
        if (images.length > 1) {
          notify.info(
            t("stories.one_image_only") || "A story shows one picture. We kept the first one."
          );
        }
        setMediaType("image");
        setMediaFiles(images.slice(0, 1));
        setMediaPreviews(images.slice(0, 1).map((file) => URL.createObjectURL(file)));
        setStep("edit");
      }
```
`notify` is already imported in this file (it is used at `:441`). In the photo `<input>` (`data-testid="photo-input"`),
delete the line `              multiple`.

Add to `src/utils/locales/eng.json`, inside the top-level `"stories"` object (the one at `:2349`, not the nested
`"stories"` at `:594`):
```json
    "one_image_only": "A story shows one picture. We kept the first one.",
```

- [ ] **Step 4: Run it and confirm it passes.** Use the same command. Expected: all `CreateStory.test.tsx` tests pass.

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-12`.

```bash
git add src/components/stories/CreateStory.tsx src/components/stories/CreateStory.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(stories): one picture per story, as every viewer shows

The composer let a story carry up to five images, but the web viewer and
the app viewer both draw only the first, so images 2-5 were uploaded and
never seen. The picker now takes one picture; if several arrive anyway the
first is kept and the author is told.

Still open (Phase 3 moments): story location, report/block from the viewer,
story rendering parity (font, plate colour, rotation/mentions, hashtags,
allowReplies/allowSharing, link host), moments i18n sweep.
EOF
```

---

### Task P3-MOM-13: the story viewer shows the story's location (moments#17)

The app header shows `time · 📍 name` when `story.location.name` is set (`story_viewer_screen.dart:1225-1253`,
`Key('story-location-label')`). The web never reads `location`. App stories carry it, and so do highlights after
Phase 1 (`HIGHLIGHT_STORY_FIELDS` includes `location`).

**Files:**
- Modify: `src/components/stories/StoryCanvas.tsx` (export `storyLocationName`).
- Modify: `src/components/stories/StoryViewer.tsx:28` (lucide import), `:490-492` (header).
- Modify: `src/components/stories/HighlightStoryViewer.tsx:116-121` (title row).
- Modify: `src/utils/locales/eng.json` (`stories.location_label`).
- Test: `src/components/stories/StoryViewer.test.tsx`, `src/components/stories/HighlightStoryViewer.test.tsx`.

**Interfaces:**
- Consumes: `story.location?: { name?: string; address?: string; coordinates?…; placeId?: string } | null`
  (backend `models/Story.js:99-107`; `parseLocation` stores only a non-empty trimmed `name`).
- Produces: `export function storyLocationName(story: any): string` (trimmed name, or `""`). P3-MOM-18 places hashtags
  next to it and does not duplicate it.

- [ ] **Step 1: Write the failing tests.** Append to `StoryViewer.test.tsx`:

```tsx
describe("location (moments#17)", () => {
  it("shows the place in the header, as the app does", () => {
    renderViewer([story({ location: { name: "Seoul Forest", address: "Seongdong-gu" } })]);
    expect(screen.getByTestId("story-location")).toHaveTextContent("Seoul Forest");
  });

  it("shows nothing for a story without a place, or with a blank one", () => {
    renderViewer([
      story(),
      story({ _id: "story-2", location: { name: "   " } }),
      story({ _id: "story-3", location: null }),
    ]);
    expect(screen.queryByTestId("story-location")).toBeNull();
    fireEvent.click(screen.getByTestId("story-next"));
    expect(screen.queryByTestId("story-location")).toBeNull();
    fireEvent.click(screen.getByTestId("story-next"));
    expect(screen.queryByTestId("story-location")).toBeNull();
  });
});
```
Append to `HighlightStoryViewer.test.tsx`:

```tsx
it("shows the current story's place under the title", () => {
  render(
    <HighlightStoryViewer
      highlight={{
        ...highlight,
        stories: [{ ...highlight.stories[0], location: { name: "Busan" } }, highlight.stories[1]],
      }}
      onClose={jest.fn()}
    />
  );
  expect(screen.getByTestId("highlight-story-location")).toHaveTextContent("Busan");
  act(() => { window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight" })); });
  expect(screen.queryByTestId("highlight-story-location")).toBeNull();
});
```

- [ ] **Step 2: Run them and confirm they fail.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/StoryViewer.test.tsx src/components/stories/HighlightStoryViewer.test.tsx
```
Expected: "shows the place…" and "shows the current story's place…" fail because the test id is not found. The blank
case passes.

- [ ] **Step 3: Implement.**

`StoryCanvas.tsx`: after `isVideoStory`, add:
```tsx
/**
 * The place an author tagged, or "" when there is none. The backend stores a
 * location only with a non-empty name (`parseLocation`), but older rows and
 * the app's model allow a blank one; both mean "no place", as in the app's
 * `story.location!.name.trim().isNotEmpty` check.
 */
export function storyLocationName(story: any): string {
  const location = story && story.location;
  if (!location || typeof location !== "object") return "";
  return typeof location.name === "string" ? location.name.trim() : "";
}
```

`StoryViewer.tsx`:
1. Add `MapPin,` to the lucide import list between `ChevronRight,` and `Eye,`, keeping it alphabetical.
2. Change `import StoryCanvas, { isVideoStory } from "./StoryCanvas";` to
   `import StoryCanvas, { isVideoStory, storyLocationName } from "./StoryCanvas";`.
3. Replace:
```tsx
            <span className="truncate text-sm font-semibold">{currentStory.user.name}</span>
            <span className="shrink-0 text-xs text-white/80">
              {timeAgo(currentStory.createdAt, t, { withAgo: true })}
            </span>
```
with:
```tsx
            <span className="truncate text-sm font-semibold">{currentStory.user.name}</span>
            <span className="shrink-0 text-xs text-white/80">
              {timeAgo(currentStory.createdAt, t, { withAgo: true })}
            </span>
            {storyLocationName(currentStory) && (
              // The app's header: time · pin · place, the place truncating
              // first so the name and the time stay readable.
              <span
                data-testid="story-location"
                className="flex min-w-0 items-center gap-1 text-xs text-white/80"
                aria-label={t("stories.location_label") || "Location"}
              >
                <MapPin size={12} aria-hidden className="shrink-0" />
                <span className="truncate">{storyLocationName(currentStory)}</span>
              </span>
            )}
```

`HighlightStoryViewer.tsx`:
1. Change `import StoryCanvas from "./StoryCanvas";` to `import StoryCanvas, { storyLocationName } from "./StoryCanvas";`.
2. Add `MapPin` to the lucide import: `import { ChevronLeft, ChevronRight, MapPin, X } from "lucide-react";`.
3. Directly after the closing `</h2>` (`:121`), add:
```tsx
      {storyLocationName(story) && (
        <p
          data-testid="highlight-story-location"
          className="-mt-1 flex items-center gap-1 px-4 pb-2 text-xs text-white/70"
        >
          <MapPin size={12} aria-hidden className="shrink-0" />
          <span className="truncate">{storyLocationName(story)}</span>
        </p>
      )}
```

`eng.json` (top-level `stories`): `"location_label": "Location",`

- [ ] **Step 4: Run them and confirm they pass.** Use the same command, then also run
  `CI=true npm test -- --watchAll=false src/components/stories/storiesStyling.test.ts`. Expected: everything passes.

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-13`.

```bash
git add src/components/stories/StoryCanvas.tsx src/components/stories/StoryViewer.tsx src/components/stories/HighlightStoryViewer.tsx src/components/stories/StoryViewer.test.tsx src/components/stories/HighlightStoryViewer.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(stories): show a story's tagged place in the viewer

App users tag a location on stories and the app shows it in the header;
the web never read the field. The viewer header and the highlight viewer
now show the place, and a missing or blank name shows nothing.

Still open (Phase 3 moments): report/block from the viewer, story rendering
parity (font, plate colour, rotation/mentions, hashtags,
allowReplies/allowSharing, link host), moments i18n sweep.
EOF
```

---

### Task P3-MOM-14: report a story and block its author from the viewer (moments#10, story part)

The app's viewer menu offers **Report story** and **Block** to anyone who is not the author
(`story_viewer_screen.dart:1442-1480`, `_reportStory` / `_blockStoryAuthor`). Both pause the story while their dialog is
open. The web shows the menu only to the owner (`StoryViewer.tsx:495`), so a web viewer cannot report a story at all.

**Dependency:** P3-MOM-5 (same unit, lands first) generalises `ReportMomentDialog` to the props
`{ type: "moment" | "comment" | "story"; targetId: string; authorId: string; onClose }`, adds the story title
(`moments_section.report.titleStory`, "Report this story") and `alreadyStory`, and widens `blockUser`/`unblockUser`
`invalidatesTags` to `["User", "Conversations", "Moments", "Comments"]`. This task adds `"Stories"` to `blockUser`
on top of that; do not drop P3-MOM-5's tags.

**Files:**
- Modify: `src/components/stories/StoryViewer.tsx`: state at `:170`, `isPaused` at `:202-203`, keyboard guard at `:371`,
  menu at `:495-505` and `:809-822`, new dialogs after `:861`.
- Modify: `src/store/slices/usersSlice.ts:279` (`blockUser` also invalidates `Stories`).
- Modify: `src/utils/locales/eng.json`.
- Test: `src/components/stories/StoryViewer.test.tsx`, `src/store/slices/profileCacheTags.test.ts`.

**Interfaces:**
- Consumes:
  - `ReportMomentDialog` (`src/components/moments/actions/ReportMomentDialog.tsx`), called with
    `type="story" targetId={story._id} authorId={story.user._id}`. It posts `POST /api/v1/reports
    {type:"story", reportId, reportedUser, reason, description}`, and the backend enum includes `story`
    (`models/Report.js:8`).
  - `useBlockUserMutation` → `POST /api/v1/users/:id/block` (`usersSlice.ts:275-280`).
- Produces: the `stories.report_story`, `stories.block_author`, `stories.block_confirm_title`,
  `stories.block_confirm_body`, `stories.block_confirm`, `stories.blocked` and `stories.block_failed` keys. After a
  successful block, the viewer navigates to `/stories`, and the feed refetches because the `Stories` tag is invalidated.

- [ ] **Step 1: Write the failing tests.** In `StoryViewer.test.tsx`, add these mocks after the existing `StoryShareSheet`
  mock:

```tsx
jest.mock("../moments/actions/ReportMomentDialog", () => ({
  __esModule: true,
  default: ({ type, targetId, authorId, onClose }: any) => (
    <div data-testid="report-dialog-stub">
      {`${type}:${targetId}:${authorId}`}
      <button type="button" data-testid="report-dialog-close" onClick={onClose}>
        close
      </button>
    </div>
  ),
}));

const mockBlockUser = jest.fn();
jest.mock("../../store/slices/usersSlice", () => ({
  useBlockUserMutation: () => [mockBlockUser, { isLoading: false }],
}));
```
In `beforeEach`, add `mockBlockUser.mockReturnValue(unwrappable());`. Then append:

```tsx
describe("report and block (moments#10)", () => {
  it("offers report and block to a viewer who is not the author, never to the author", () => {
    renderViewer([story()]);
    fireEvent.click(screen.getByTestId("story-menu-toggle"));
    expect(screen.getByTestId("story-report")).toBeInTheDocument();
    expect(screen.getByTestId("story-block")).toBeInTheDocument();
    expect(screen.queryByTestId("story-delete")).toBeNull();
  });

  it("keeps the owner's menu to delete only", () => {
    mockCurrentUserId = "author-1";
    renderViewer([story()]);
    fireEvent.click(screen.getByTestId("story-menu-toggle"));
    expect(screen.getByTestId("story-delete")).toBeInTheDocument();
    expect(screen.queryByTestId("story-report")).toBeNull();
    expect(screen.queryByTestId("story-block")).toBeNull();
  });

  it("reports the story as type story, paused while the dialog is open", () => {
    renderViewer([story()]);
    fireEvent.click(screen.getByTestId("story-menu-toggle"));
    fireEvent.click(screen.getByTestId("story-report"));
    expect(screen.getByTestId("report-dialog-stub")).toHaveTextContent("story:story-1:author-1");
    expect(screen.getByTestId("story-viewer")).toHaveAttribute("data-paused", "true");

    fireEvent.click(screen.getByTestId("report-dialog-close"));
    expect(screen.queryByTestId("report-dialog-stub")).toBeNull();
    expect(screen.getByTestId("story-viewer")).toHaveAttribute("data-paused", "false");
  });

  it("blocks the author after a confirmation and leaves their stories", async () => {
    renderViewer([story()]);
    fireEvent.click(screen.getByTestId("story-menu-toggle"));
    fireEvent.click(screen.getByTestId("story-block"));
    expect(screen.getByTestId("story-viewer")).toHaveAttribute("data-paused", "true");
    expect(mockBlockUser).not.toHaveBeenCalled();

    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    await waitFor(() => expect(mockBlockUser).toHaveBeenCalledWith("author-1"));
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/stories"));
  });

  it("stays on the story and says so when the block fails", async () => {
    const notify = require("../../design/notify").default;
    mockBlockUser.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
    renderViewer([story()]);
    fireEvent.click(screen.getByTestId("story-menu-toggle"));
    fireEvent.click(screen.getByTestId("story-block"));
    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    await waitFor(() => expect(notify.error).toHaveBeenCalled());
    expect(mockNavigate).not.toHaveBeenCalledWith("/stories");
  });

  it("ignores the arrow keys while the report dialog is open", () => {
    renderViewer([story(), story({ _id: "story-2", text: "Second" })]);
    fireEvent.click(screen.getByTestId("story-menu-toggle"));
    fireEvent.click(screen.getByTestId("story-report"));
    fireEvent.keyDown(window, { key: "ArrowRight" });
    expect(screen.getByTestId("report-dialog-stub")).toHaveTextContent("story:story-1");
  });
});
```
Append to `profileCacheTags.test.ts`:

```ts
it("refetches the stories feed after a block, so the blocked author's ring disappears", async () => {
  const { storiesApiSlice } = require("./storiesSlice");
  const calls = mockFetch();
  const store = makeStore();

  await store.dispatch(storiesApiSlice.endpoints.getStoryFeeds.initiate(undefined));
  expect(gets(calls, "/stories/feed")).toHaveLength(1);

  await store.dispatch(usersApiSlice.endpoints.blockUser.initiate("u2"));
  await Promise.resolve();
  await new Promise((resolve) => setTimeout(resolve, 0));

  expect(gets(calls, "/stories/feed").length).toBeGreaterThan(1);
});
```

- [ ] **Step 2: Run them and confirm they fail.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/StoryViewer.test.tsx src/store/slices/profileCacheTags.test.ts
```
Expected:
- The non-owner tests fail because `story-menu-toggle` is not found (it is owner-only).
- The owner test passes.
- The cache test fails: 1 feed GET, because `blockUser` doesn't invalidate `Stories`.

- [ ] **Step 3: Implement.**

`usersSlice.ts`, in `blockUser`, replace `      invalidatesTags: ["User", "Conversations", "Moments", "Comments"],` (the one inside `blockUser`, `:279`, as P3-MOM-5 left it) with:
```ts
      // `Stories` too: the feed would otherwise keep the blocked author's
      // ring until its 5-second cache expired, and the story viewer sends the
      // reader back to it right after a block.
      invalidatesTags: ["User", "Conversations", "Moments", "Comments", "Stories"],
```
(P3-MOM-5 already turned it into `["User", "Conversations", "Moments", "Comments"]`; the anchor is that line.)

`StoryViewer.tsx`:

1. Imports. Add `Ban, Flag,` to the lucide list (`Ban` after `ChevronRight`/`MapPin` ordering is not enforced; keep it
   readable). Then add:
```tsx
import ReportMomentDialog from "../moments/actions/ReportMomentDialog";
import { useBlockUserMutation } from "../../store/slices/usersSlice";
```

2. State. After `const [confirmDelete, setConfirmDelete] = useState(false);`, add:
```tsx
  // Viewer-side safety tools, as in the app's menu: report the story, block
  // its author. Each pauses the story while it is open (the app's
  // _reportStory/_blockStoryAuthor pause and resume the same way).
  const [reportOpen, setReportOpen] = useState(false);
  const [confirmBlock, setConfirmBlock] = useState(false);
```
After `const [answerQuestion] = useAnswerQuestionMutation();`, add:
```tsx
  const [blockUser, { isLoading: isBlocking }] = useBlockUserMutation();
```

3. Pause. Replace:
```tsx
  const isPaused =
    isHeld || isKeyPaused || showAnswerBox || openSheet !== null || confirmDelete;
```
with:
```tsx
  const isPaused =
    isHeld ||
    isKeyPaused ||
    showAnswerBox ||
    openSheet !== null ||
    confirmDelete ||
    reportOpen ||
    confirmBlock;
```
In the per-story reset effect (the one that calls `setShowMenu(false)`), add `setReportOpen(false);` and
`setConfirmBlock(false);`.

4. Handler. After `handleDeleteStory`, add:
```tsx
  const handleBlockAuthor = async () => {
    if (!currentStory || isOwner) return;
    const authorId = currentStory.user && currentStory.user._id;
    if (!authorId) return;
    try {
      await blockUser(authorId).unwrap();
      setConfirmBlock(false);
      notify.success(
        t("stories.blocked", { name: currentStory.user.name }) ||
          `${currentStory.user.name} is blocked`
      );
      // Their stories are gone for this reader now; staying on one would show
      // content the block is meant to hide.
      navigate("/stories");
    } catch (err) {
      notify.error(t("stories.block_failed") || "Couldn't block this person. Try again.");
    }
  };
```

5. Keyboard guard. Replace
   `      if (showAnswerBox || showReplyInput || openSheet !== null || confirmDelete) return;` with:
```tsx
      if (
        showAnswerBox ||
        showReplyInput ||
        openSheet !== null ||
        confirmDelete ||
        reportOpen ||
        confirmBlock
      ) {
        return;
      }
```
and add `reportOpen, confirmBlock,` to that `useCallback`'s dependency array after `confirmDelete,`.

6. Menu toggle. Replace `{isOwner && (` before the `story-menu-toggle` button with `{(isOwner || currentUserId) && (`.
   A signed-out reader has nothing to report with.

7. Menu body. Replace the whole owner-only block:
```tsx
        {/* Menu (Owner Only) */}
        {showMenu && isOwner && (
          <div className="absolute bottom-20 right-4 z-[15] rounded-chip bg-black/90 p-2 backdrop-blur motion-safe:animate-bt-rise">
            <button
              type="button"
              data-testid="story-delete"
              onClick={() => setConfirmDelete(true)}
              className="flex w-full items-center gap-3 rounded-chip border-0 bg-transparent px-4 py-3 text-left text-white transition hover:bg-white/10"
            >
              <Trash2 size={16} aria-hidden />
              {t("stories.delete_story") || "Delete Story"}
            </button>
          </div>
        )}
```
with:
```tsx
        {/* Menu: delete for the owner; report and block for everyone else,
            as in the app's popup menu. */}
        {showMenu && (
          <div className="absolute end-4 top-24 z-[15] rounded-chip bg-black/90 p-2 backdrop-blur motion-safe:animate-bt-rise">
            {isOwner ? (
              <button
                type="button"
                data-testid="story-delete"
                onClick={() => setConfirmDelete(true)}
                className="flex w-full items-center gap-3 rounded-chip border-0 bg-transparent px-4 py-3 text-start text-white transition hover:bg-white/10"
              >
                <Trash2 size={16} aria-hidden />
                {t("stories.delete_story") || "Delete Story"}
              </button>
            ) : (
              <>
                <button
                  type="button"
                  data-testid="story-report"
                  onClick={() => {
                    setShowMenu(false);
                    setReportOpen(true);
                  }}
                  className="flex w-full items-center gap-3 rounded-chip border-0 bg-transparent px-4 py-3 text-start text-white transition hover:bg-white/10"
                >
                  <Flag size={16} aria-hidden />
                  {t("stories.report_story") || "Report story"}
                </button>
                <button
                  type="button"
                  data-testid="story-block"
                  onClick={() => {
                    setShowMenu(false);
                    setConfirmBlock(true);
                  }}
                  className="flex w-full items-center gap-3 rounded-chip border-0 bg-transparent px-4 py-3 text-start text-red-300 transition hover:bg-white/10"
                >
                  <Ban size={16} aria-hidden />
                  {t("stories.block_author", { name: currentStory.user.name }) ||
                    `Block ${currentStory.user.name}`}
                </button>
              </>
            )}
          </div>
        )}
```
The menu moves from `bottom-20 right-4` to `top-24 end-4`, under the header's toggle that opens it. For a non-owner, the
old position sat on top of the reply bar. `end-4` mirrors in RTL.

8. Dialogs. After the delete `ConfirmDialog` (before the closing `</>`), add:
```tsx
      {reportOpen && currentStory.user && (
        <ReportMomentDialog
          type="story"
          targetId={currentStory._id}
          authorId={currentStory.user._id}
          onClose={() => setReportOpen(false)}
        />
      )}
      <ConfirmDialog
        open={confirmBlock}
        danger
        busy={isBlocking}
        title={
          t("stories.block_confirm_title", { name: currentStory.user.name }) ||
          `Block ${currentStory.user.name}?`
        }
        body={
          t("stories.block_confirm_body") ||
          "They won't be able to see your profile, moments or stories, or message you, and you won't see theirs."
        }
        confirmLabel={t("stories.block_confirm") || "Block"}
        cancelLabel={t("stories.cancel") || "Cancel"}
        onConfirm={handleBlockAuthor}
        onCancel={() => setConfirmBlock(false)}
      />
```

`eng.json` (top-level `stories`), add:
```json
    "report_story": "Report story",
    "block_author": "Block {{name}}",
    "block_confirm_title": "Block {{name}}?",
    "block_confirm_body": "They won't be able to see your profile, moments or stories, or message you, and you won't see theirs.",
    "block_confirm": "Block",
    "blocked": "{{name}} is blocked",
    "block_failed": "Couldn't block this person. Try again.",
```

- [ ] **Step 4: Run them and confirm they pass.** Use the same command, plus
  `CI=true npm test -- --watchAll=false src/components/stories src/store/slices/usersEndpoints.test.ts`. Expected: all
  pass. The old "Menu (Owner Only)" tests (`story-delete`) still pass, because the owner branch is unchanged.

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-14`.

```bash
git add src/components/stories/StoryViewer.tsx src/components/stories/StoryViewer.test.tsx src/store/slices/usersSlice.ts src/store/slices/profileCacheTags.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(stories): report a story and block its author from the viewer

The app lets a viewer report a story or block its author from the story
menu; the web showed the menu to the owner only, so a web reader had no way
to report a story. Non-owners now get Report (POST /reports type=story) and
Block (with a confirmation), both pausing the story while open. A block
also invalidates the stories feed and leaves the author's stories.

Still open (Phase 3 moments): story rendering parity (font, plate colour,
rotation/mentions, hashtags, allowReplies/allowSharing, link host), moments
i18n sweep.
EOF
```

---

### Task P3-MOM-15: text-story font style and overlay faces match the app (moments#25)

There are three differences from the app:
1. **Text-story body.** `StoryCanvas.tsx:106-109` paints every text story `font-semibold` and ignores `story.fontStyle`.
   The app's `ViewerTextStoryLayer._textStyleOf()` uses `normal` → regular weight, `bold` → bold, `italic` → italic,
   `handwriting` → Caveat. The web composer preview (`CreateStory.tsx:606-614`) ignores it too.
2. **Overlay faces.** The app's `viewer_overlay_layer.dart:74-83` uses `sans-serif` → w500, `serif` → serif,
   `bold` → bold, `handwritten` → Caveat italic. The web uses `font-sans` / `font-serif italic` for handwritten, and
   adds `font-semibold` to every overlay (`StoryCanvas.tsx:164`).
3. **Italic mapped to serif.** When a web text story carries stickers, its body travels as the first overlay
   (`CreateStory.tsx:511-528`), and `BODY_OVERLAY_FONT` (`:112-117`) maps `italic` → `"serif"`, a different typeface.
   The overlay vocabulary (`sans-serif|serif|bold|handwritten`, `models/Story.js:179`) has no italic. The plain face is
   the honest nearest value, and the story's own `fontStyle: "italic"` still travels for clients that read it.

No webfont is added (`src/fonts.test.ts` pins the self-hosted set). `font-hand` is a system handwriting stack that names
Caveat first, so a machine that has Caveat installed matches the app exactly.

**Files:**
- Modify: `tailwind.config.js:49-74` (`fontFamily.hand`).
- Modify: `src/components/stories/storyOverlays.ts:62-70` (`OVERLAY_FONT_CLASS`), plus a new `storyBodyFontClass`.
- Modify: `src/components/stories/StoryCanvas.tsx:106-109`, `:162-166`.
- Modify: `src/components/stories/CreateStory.tsx:112-117` (`BODY_OVERLAY_FONT.italic`), `:606-614` (text preview).
- Test: new `src/components/stories/storyFonts.test.tsx`; update `CreateStory.test.tsx`.

**Interfaces:**
- Consumes: `story.fontStyle?: "normal" | "bold" | "italic" | "handwriting"` (default `normal`);
  `overlay.fontStyle: "sans-serif" | "serif" | "bold" | "handwritten"`.
- Produces: `export function storyBodyFontClass(fontStyle?: string): string`. `OVERLAY_FONT_CLASS` gets new values, and
  both the canvas and the composer preview use it.

- [ ] **Step 1: Write the failing tests.** Create `src/components/stories/storyFonts.test.tsx`:

```tsx
import React from "react";
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import StoryCanvas from "./StoryCanvas";
import { OVERLAY_FONT_CLASS, storyBodyFontClass } from "./storyOverlays";

jest.mock("react-router-dom", () => ({
  Link: ({ to, children, ...rest }: any) => (
    <a href={to} {...rest}>
      {children}
    </a>
  ),
}));

const textStory = (fontStyle?: string) => ({
  _id: "s1",
  mediaType: "text",
  text: "Hello",
  backgroundColor: "#000000",
  textColor: "#FFFFFF",
  fontStyle,
});

describe("text-story body font (app ViewerTextStoryLayer)", () => {
  it.each([
    ["normal", "font-normal", ["italic", "font-semibold", "font-hand"]],
    ["bold", "font-bold", ["italic", "font-semibold"]],
    ["italic", "italic", ["font-serif", "font-semibold"]],
    ["handwriting", "font-hand", ["italic", "font-semibold"]],
  ])("paints %s the way the app does", (style, expected, absent) => {
    render(<StoryCanvas story={textStory(style as string)} />);
    const body = screen.getByTestId("story-text");
    expect(body.className).toContain(expected as string);
    (absent as string[]).forEach((cls) => expect(body.className.split(" ")).not.toContain(cls));
  });

  it("treats a missing or unknown style as normal (old stories)", () => {
    expect(storyBodyFontClass(undefined)).toBe(storyBodyFontClass("normal"));
    expect(storyBodyFontClass("serif")).toBe(storyBodyFontClass("normal"));
  });
});

describe("overlay faces (app viewer_overlay_layer)", () => {
  it("sans is medium weight, handwritten is the handwriting face in italic, not serif", () => {
    expect(OVERLAY_FONT_CLASS["sans-serif"]).toContain("font-medium");
    expect(OVERLAY_FONT_CLASS.handwritten).toContain("font-hand");
    expect(OVERLAY_FONT_CLASS.handwritten).toContain("italic");
    expect(OVERLAY_FONT_CLASS.handwritten).not.toContain("font-serif");
    expect(OVERLAY_FONT_CLASS.bold).toContain("font-bold");
    expect(OVERLAY_FONT_CLASS.serif).toContain("font-serif");
  });

  it("does not force every overlay to semibold", () => {
    render(
      <StoryCanvas
        story={{
          ...textStory("normal"),
          overlays: [
            { type: "text", content: "hi", x: 0.5, y: 0.5, scale: 1, color: "#FFFFFF", fontStyle: "sans-serif", bgMode: "none" },
          ],
        }}
      />
    );
    expect(screen.getByTestId("story-overlay-0").className.split(" ")).not.toContain("font-semibold");
  });
});
```
In `CreateStory.test.tsx`, append:

```tsx
describe("italic text story with stickers (moments#25)", () => {
  it("sends the body overlay in the plain face, not serif, and keeps fontStyle italic", async () => {
    openTextEditor();
    fireEvent.change(screen.getByTestId("story-text"), { target: { value: "hi" } });
    fireEvent.change(screen.getByTestId("story-font"), { target: { value: "italic" } });
    fireEvent.click(screen.getByTestId("add-text-overlay"));
    fireEvent.change(screen.getByTestId("overlay-content-0"), { target: { value: "sticker" } });
    fireEvent.click(screen.getByTestId("share-story"));

    await waitFor(() => expect(mockCreateStory).toHaveBeenCalled());
    expect(sentField(mockCreateStory, "overlays")[0].fontStyle).toBe("sans-serif");
    const form = mockCreateStory.mock.calls[0][0] as FormData;
    expect(form.get("fontStyle")).toBe("italic");
  });
});
```

- [ ] **Step 2: Run them and confirm they fail.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/storyFonts.test.tsx src/components/stories/CreateStory.test.tsx
```
Expected:
- `storyBodyFontClass` is not exported: TypeError, or every case fails.
- The overlay classes lack `font-medium`/`font-hand`.
- The CreateStory italic test gets `"serif"`.

- [ ] **Step 3: Implement.**

`tailwind.config.js`: inside `fontFamily: {`, after the `display: [...]` entry, add:
```js
        // Story handwriting face. The app draws `handwriting` text stories and
        // `handwritten` overlays in Caveat; no webfont ships for one sticker
        // style (src/fonts.test.ts pins the self-hosted set), so Caveat is named
        // first for machines that have it and the OS handwriting faces follow.
        hand: ['Caveat', '"Segoe Print"', '"Bradley Hand"', '"Comic Sans MS"', "cursive"],
```

`storyOverlays.ts`: replace:
```ts
/** Font styles as classes. There is no handwriting face in the app's stack, so
 * `handwritten` borrows the serif italic rather than shipping a font for one
 * sticker. */
export const OVERLAY_FONT_CLASS: Record<OverlayFontStyle, string> = {
  "sans-serif": "font-sans",
  serif: "font-serif",
  bold: "font-sans font-bold",
  handwritten: "font-serif italic",
};
```
with:
```ts
/**
 * Font styles as classes, mirroring the app viewer
 * (`viewer_overlay_layer.dart`): sans is weight 500, serif regular, bold
 * bold, handwritten the Caveat face in italic (`font-hand`, see
 * tailwind.config.js -- a system handwriting stack with Caveat first).
 */
export const OVERLAY_FONT_CLASS: Record<OverlayFontStyle, string> = {
  "sans-serif": "font-sans font-medium",
  serif: "font-serif font-normal",
  bold: "font-sans font-bold",
  handwritten: "font-hand font-normal italic",
};

/**
 * A TEXT story's own `fontStyle` (a different vocabulary from overlays:
 * `models/Story.js` fontStyle enum) as classes, mirroring the app's
 * `ViewerTextStoryLayer._textStyleOf()`. Missing or unknown is `normal`.
 */
const STORY_BODY_FONT_CLASS: { [style: string]: string } = {
  normal: "font-sans font-normal",
  bold: "font-sans font-bold",
  italic: "font-sans font-normal italic",
  handwriting: "font-hand font-normal",
};

export function storyBodyFontClass(fontStyle?: string): string {
  return (fontStyle && STORY_BODY_FONT_CLASS[fontStyle]) || STORY_BODY_FONT_CLASS.normal;
}
```

`StoryCanvas.tsx`:
1. Add `storyBodyFontClass,` to the `./storyOverlays` import list.
2. Replace:
```tsx
          className={[
            "flex h-full w-full items-center justify-center break-words bg-black p-10 text-center font-semibold text-white",
            bodyClassName,
          ].join(" ")}
```
with:
```tsx
          className={[
            "flex h-full w-full items-center justify-center break-words bg-black p-10 text-center text-white",
            storyBodyFontClass(story.fontStyle),
            bodyClassName,
          ].join(" ")}
```
3. In the overlay `className`, replace `"max-w-[80%] whitespace-pre-wrap text-center font-semibold leading-tight",` with
   `"max-w-[80%] whitespace-pre-wrap text-center leading-tight",`. Replace
   `(OVERLAY_FONT_CLASS as any)[overlay.fontStyle] || "font-sans",` with
   `(OVERLAY_FONT_CLASS as any)[overlay.fontStyle] || OVERLAY_FONT_CLASS["sans-serif"],`.

`CreateStory.tsx`:
1. Replace `  italic: "serif",` inside `BODY_OVERLAY_FONT` with:
```tsx
  // The overlay vocabulary has no italic. Serif is a different typeface, not
  // a slant; the plain face is the honest nearest, and the story's own
  // `fontStyle: "italic"` still travels for clients that read it.
  italic: "sans-serif",
```
2. Add `storyBodyFontClass,` to its `./storyOverlays` import list.
3. In `renderCanvasBackground`, replace
   `className="flex h-full w-full items-center justify-center p-6 text-center text-lg font-semibold"` with:
```tsx
          className={
            "flex h-full w-full items-center justify-center p-6 text-center text-lg " +
            storyBodyFontClass(fontStyle)
          }
```

- [ ] **Step 4: Run them and confirm they pass.** Use the same command, plus
  `CI=true npm test -- --watchAll=false src/components/stories src/fonts.test.ts`. Expected: all pass.
  The existing viewer test `expect(first.className).toContain("font-bold")` still holds.

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-15`.

```bash
git add tailwind.config.js src/components/stories/storyOverlays.ts src/components/stories/StoryCanvas.tsx src/components/stories/CreateStory.tsx src/components/stories/storyFonts.test.tsx src/components/stories/CreateStory.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(stories): text-story font style and overlay faces match the app

Text stories ignored their fontStyle on the web (always semibold), the
handwritten overlay borrowed serif italic, and an italic web text story
with stickers sent its body as a serif overlay. Body and overlay faces now
follow the app viewer: regular/bold/italic/handwriting, sans at weight 500,
handwritten in a Caveat-first handwriting stack; italic maps to the plain
face (the overlay format has no italic).

Still open (Phase 3 moments): solid plate colour, rotation/mention pills,
hashtags, allowReplies/allowSharing, link host, moments i18n sweep.
EOF
```

---

### Task P3-MOM-16: solid and semi plates match the app (moments#25)

`storyOverlays.ts:74-78` always paints a black plate (`bg-black`) behind a `solid` overlay. So an app overlay in black
text with a solid plate is black on black: unreadable on the web. The app (`viewer_overlay_layer.dart:96-105`) picks
the plate from the glyph colour, `color.computeLuminance() > 0.5 ? Colors.black : Colors.white`, and paints `semi` at
alpha 0.5. The web uses `bg-black/40`.

**Files:**
- Modify: `src/components/stories/storyOverlays.ts:72-78` (`OVERLAY_BG_CLASS`), plus new `overlayLuminance` and
  `overlayPlateClass`.
- Modify: `src/components/stories/StoryCanvas.tsx:167`, `src/components/stories/CreateStory.tsx:747`.
- Test: new `src/components/stories/storyPlate.test.ts`; append to `StoryViewer.test.tsx`.

**Interfaces:**
- Consumes: `overlay.color` (`#RRGGBB`, validated server-side) and `overlay.bgMode`.
- Produces: `export function overlayLuminance(hex: string): number`, the WCAG relative luminance, which equals
  Flutter's `Color.computeLuminance`. Also `export function overlayPlateClass(bgMode: string, color: string): string`.

- [ ] **Step 1: Write the failing tests.** Create `src/components/stories/storyPlate.test.ts`:

```ts
import { overlayLuminance, overlayPlateClass } from "./storyOverlays";

describe("overlay luminance (Flutter Color.computeLuminance)", () => {
  it("matches the WCAG relative luminance at the ends and in between", () => {
    expect(overlayLuminance("#FFFFFF")).toBeCloseTo(1, 5);
    expect(overlayLuminance("#000000")).toBeCloseTo(0, 5);
    // The palette's red and yellow sit on opposite sides of 0.5.
    expect(overlayLuminance("#FF3B30")).toBeLessThan(0.5);
    expect(overlayLuminance("#FFCC00")).toBeGreaterThan(0.5);
  });

  it("treats an unreadable colour as the server default (white)", () => {
    expect(overlayLuminance("red")).toBeCloseTo(1, 5);
    expect(overlayLuminance("")).toBeCloseTo(1, 5);
  });
});

describe("overlay plate (app viewer_overlay_layer)", () => {
  it("solid: black behind light text, white behind dark text", () => {
    expect(overlayPlateClass("solid", "#FFFFFF")).toContain("bg-black");
    expect(overlayPlateClass("solid", "#FFCC00")).toContain("bg-black");
    expect(overlayPlateClass("solid", "#000000")).toContain("bg-white");
    expect(overlayPlateClass("solid", "#FF3B30")).toContain("bg-white");
  });

  it("semi is black at half alpha; none is a shadow only; unknown is none", () => {
    expect(overlayPlateClass("semi", "#FFFFFF")).toContain("bg-black/50");
    expect(overlayPlateClass("none", "#FFFFFF")).not.toMatch(/\bbg-/);
    expect(overlayPlateClass("weird", "#FFFFFF")).toBe(overlayPlateClass("none", "#FFFFFF"));
  });
});
```
Append to the `structured stickers` describe in `StoryViewer.test.tsx`:

```tsx
  it("puts a white plate behind dark text on a solid overlay (black on black was unreadable)", () => {
    renderViewer([
      story({
        overlays: [
          { type: "text", content: "ink", x: 0.5, y: 0.5, scale: 1, color: "#000000", fontStyle: "sans-serif", bgMode: "solid" },
        ],
      }),
    ]);
    const classes = screen.getByTestId("story-overlay-0").className.split(" ");
    expect(classes).toContain("bg-white");
    expect(classes).not.toContain("bg-black");
  });
```

- [ ] **Step 2: Run them and confirm they fail.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/storyPlate.test.ts src/components/stories/StoryViewer.test.tsx
```
Expected: `storyPlate` fails because the exports don't exist. The viewer test finds `bg-black`.

- [ ] **Step 3: Implement.** In `storyOverlays.ts`, replace:

```ts
/** `bgMode` is the plate BEHIND the glyphs; the glyph colour is the overlay's
 * own `color` in every mode. */
export const OVERLAY_BG_CLASS: Record<OverlayBgMode, string> = {
  none: "drop-shadow-[0_1px_2px_rgba(0,0,0,0.7)]",
  semi: "rounded-lg bg-black/40 px-2 py-0.5",
  solid: "rounded-lg bg-black px-2 py-0.5",
};
```
with:
```ts
/** `bgMode` is the plate BEHIND the glyphs; the glyph colour is the overlay's
 * own `color` in every mode. `solid` has two plates because the app picks one
 * by the glyph's brightness -- see `overlayPlateClass`. */
export const OVERLAY_BG_CLASS: Record<OverlayBgMode, string> = {
  none: "drop-shadow-[0_1px_2px_rgba(0,0,0,0.7)]",
  semi: "rounded-lg bg-black/50 px-2 py-0.5",
  solid: "rounded-lg bg-black px-2 py-0.5",
};
const SOLID_LIGHT_PLATE = "rounded-lg bg-white px-2 py-0.5";

/** sRGB channel (0-255) to linear light, as WCAG 2 and Flutter define it. */
const linearChannel = (value: number): number => {
  const c = value / 255;
  return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
};

/**
 * Relative luminance of `#RRGGBB`, 0 (black) to 1 (white): the formula
 * behind Flutter's `Color.computeLuminance()`, which the app viewer uses to
 * pick a solid plate. An unreadable colour counts as white, the server's
 * default overlay colour.
 */
export function overlayLuminance(hex: string): number {
  const match = /^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/.exec(String(hex || ""));
  if (!match) return 1;
  const [r, g, b] = [match[1], match[2], match[3]].map((h) => linearChannel(parseInt(h, 16)));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/**
 * The plate class for one overlay, mirroring `viewer_overlay_layer.dart`:
 * semi is black at 0.5; solid is black behind light glyphs and white behind
 * dark ones (`computeLuminance() > 0.5 ? black : white`), so black text on a
 * solid plate is readable instead of black on black.
 */
export function overlayPlateClass(bgMode: string, color: string): string {
  if (bgMode === "solid") {
    return overlayLuminance(color) > 0.5 ? OVERLAY_BG_CLASS.solid : SOLID_LIGHT_PLATE;
  }
  return (OVERLAY_BG_CLASS as any)[bgMode] || OVERLAY_BG_CLASS.none;
}
```

`StoryCanvas.tsx`: in the import list, replace `OVERLAY_BG_CLASS,` with `overlayPlateClass,`, and replace
`(OVERLAY_BG_CLASS as any)[overlay.bgMode] || "",` with `overlayPlateClass(overlay.bgMode, overlay.color),`.

`CreateStory.tsx`: add `overlayPlateClass,` to the `./storyOverlays` import. In the overlay node's `className`, replace
`OVERLAY_BG_CLASS[overlay.bgMode],` with `overlayPlateClass(overlay.bgMode, overlay.color),`. Remove `OVERLAY_BG_CLASS`
from that import only if nothing else in the file uses it (`grep -n OVERLAY_BG_CLASS src/components/stories/CreateStory.tsx`).
This way the composer shows the same plate the viewers will.

- [ ] **Step 4: Run them and confirm they pass.** Use the same command, plus
  `CI=true npm test -- --watchAll=false src/components/stories`. Expected: all pass. The existing "paints overlays"
  test uses `bgMode: "semi"` and asserts no plate class, so it is unaffected.

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-16`.

```bash
git add src/components/stories/storyOverlays.ts src/components/stories/StoryCanvas.tsx src/components/stories/CreateStory.tsx src/components/stories/storyPlate.test.ts src/components/stories/StoryViewer.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(stories): solid overlay plate follows the glyph colour, as in the app

A solid overlay always got a black plate on the web, so dark text from the
app was black on black. The plate is now chosen like the app viewer does
(relative luminance > 0.5 -> black, else white), and the semi plate uses
the app's 0.5 alpha. The composer previews the same plate.

Still open (Phase 3 moments): rotation/mention pills, hashtags,
allowReplies/allowSharing, link host, moments i18n sweep.
EOF
```

---

### Task P3-MOM-17: overlays honour rotation; centring stays exact; mention pills look like the app's (moments#25)

What "placement" actually means after reading both sides:
- **Centre.** The wire contract (`types.ts:41-44`, app `overlay_draft.dart:18`) says `x`/`y` are the overlay's
  **centre**. The web already centres exactly (`-translate-x-1/2 -translate-y-1/2` at `StoryCanvas.tsx:163`/`:192`).
  The app viewer approximates the centre with fixed offsets. That is an app-side follow-up (see the section header), so
  the web keeps exact centring, and this task pins it, including under `dir="rtl"`.
- **Rotation is dropped on the web.** The app stores and draws `overlays[].rotation` in degrees
  (`viewer_overlay_layer.dart:113-116`, `models/Story.js:177`). `StoryCanvas` never reads it, so a tilted app sticker
  shows upright on the web.
- **Mention pills look different.**
  - App (`story_viewer_screen.dart:342-355`): black at 0.55, white bold 13 px text, fully rounded.
  - Web: `bg-white/85 text-ink-900 font-semibold text-xs`.

Rotation goes through the one allowed inline style. `overlayPositionStyle` returns a `--tw-rotate` custom property, and
Tailwind's translate classes already compose `rotate(var(--tw-rotate))` into the same `transform`. So no `transform` is
written inline, and `storiesStyling.test.ts` (which allows `...overlayPositionStyle(...)`) keeps passing.

**Files:**
- Modify: `src/components/stories/storyOverlays.ts:330-334` (`overlayPositionStyle`).
- Modify: `src/components/stories/StoryCanvas.tsx:159` (pass rotation), `:192` (mention pill classes).
- Modify: `src/components/stories/CreateStory.tsx:766` (composer mention preview, same pill).
- Test: append to `src/components/stories/storyPlate.test.ts` (pure function) and `StoryViewer.test.tsx`.

**Interfaces:**
- Consumes: `overlay.rotation?: number` (degrees; missing → 0).
- Produces: `overlayPositionStyle(x: number, y: number, rotation?: number): { left: string; top: string }`. At runtime
  it may also carry `"--tw-rotate"`. Existing two-argument callers (the composer) are unchanged.

- [ ] **Step 1: Write the failing tests.** Append to `storyPlate.test.ts`:

```ts
import { overlayPositionStyle } from "./storyOverlays";

describe("overlay rotation (app viewer_overlay_layer Transform.rotate)", () => {
  it("adds the rotation as Tailwind's rotate variable, never a raw transform", () => {
    const style: any = overlayPositionStyle(0.5, 0.25, -12.5);
    expect(style.left).toBe("50%");
    expect(style.top).toBe("25%");
    expect(style["--tw-rotate"]).toBe("-12.5deg");
    expect(style.transform).toBeUndefined();
  });

  it("leaves unrotated and malformed rotations alone", () => {
    expect(overlayPositionStyle(0.5, 0.5)).toEqual({ left: "50%", top: "50%" });
    expect(overlayPositionStyle(0.5, 0.5, 0)).toEqual({ left: "50%", top: "50%" });
    expect(overlayPositionStyle(0.5, 0.5, NaN)).toEqual({ left: "50%", top: "50%" });
    expect(overlayPositionStyle(0.5, 0.5, "15" as any)).toEqual({ left: "50%", top: "50%" });
  });
});
```
Append to the `structured stickers` describe in `StoryViewer.test.tsx`:

```tsx
  it("tilts an app overlay by its rotation and still centres it on x/y", () => {
    renderViewer([
      story({
        overlays: [
          { type: "text", content: "tilt", x: 0.3, y: 0.6, scale: 1, rotation: 20, color: "#FFFFFF", fontStyle: "sans-serif", bgMode: "none" },
        ],
      }),
    ]);
    const node = screen.getByTestId("story-overlay-0");
    expect(node).toHaveStyle({ left: "30%", top: "60%" });
    expect(node.style.getPropertyValue("--tw-rotate")).toBe("20deg");
    expect(node.className).toContain("-translate-x-1/2");
    expect(node.className).toContain("-translate-y-1/2");
  });

  it("does not mirror story coordinates in a right-to-left page", () => {
    document.documentElement.setAttribute("dir", "rtl");
    try {
      renderViewer([
        story({
          overlays: [
            { type: "text", content: "x", x: 0.25, y: 0.5, scale: 1, color: "#FFFFFF", fontStyle: "sans-serif", bgMode: "none" },
          ],
          mentions: [{ user: "u-1", username: "ann", position: { x: 20, y: 30 } }],
        }),
      ]);
      expect(screen.getByTestId("story-overlay-0")).toHaveStyle({ left: "25%" });
      expect(screen.getByTestId("story-mention-0")).toHaveStyle({ left: "20%", top: "30%" });
    } finally {
      document.documentElement.removeAttribute("dir");
    }
  });

  it("draws mentions as the app's dark pill", () => {
    renderViewer([story({ mentions: [{ user: "u-1", username: "ann", position: { x: 50, y: 50 } }] })]);
    const classes = screen.getByTestId("story-mention-0").className.split(" ");
    expect(classes).toContain("bg-black/55");
    expect(classes).toContain("text-white");
    expect(classes).toContain("font-bold");
    expect(classes).not.toContain("bg-white/85");
  });
```

- [ ] **Step 2: Run them and confirm they fail.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/storyPlate.test.ts src/components/stories/StoryViewer.test.tsx
```
Expected:
- The rotation tests fail (`--tw-rotate` undefined / `""`).
- The pill test fails (`bg-white/85`).
- The RTL test passes already, which pins the behaviour.

If jsdom's CSSStyleDeclaration drops the custom property, the component-level `getPropertyValue` assertion stays red
after Step 3. In that case, delete only that line. The pure-function test pins the value, and the render test keeps
checking the centring.

- [ ] **Step 3: Implement.** In `storyOverlays.ts`, replace:

```ts
/**
 * The ONLY inline style these stickers need: two numbers out of the JSON that
 * no utility class can express. Everything else — font, weight, plate, size —
 * is a class from the maps above.
 */
export function overlayPositionStyle(x: number, y: number): { left: string; top: string } {
  return { left: clamp01(x) * 100 + "%", top: clamp01(y) * 100 + "%" };
}
```
with:
```ts
/**
 * The ONLY inline style these stickers need: numbers out of the JSON that no
 * utility class can express. `x`/`y` are the sticker's CENTRE (the classes
 * add `-translate-x-1/2 -translate-y-1/2`); `left`/`top` stay physical so a
 * right-to-left page never mirrors a picture's coordinates.
 *
 * `rotation` (degrees, app stickers only -- the app draws it with
 * `Transform.rotate`) becomes Tailwind's own `--tw-rotate` variable, which
 * the translate classes already compose into `transform`, so no raw
 * `transform` is ever written inline. Everything else -- font, weight,
 * plate, size -- is a class.
 */
export function overlayPositionStyle(
  x: number,
  y: number,
  rotation?: number
): { left: string; top: string } {
  const style: any = { left: clamp01(x) * 100 + "%", top: clamp01(y) * 100 + "%" };
  if (typeof rotation === "number" && Number.isFinite(rotation) && rotation !== 0) {
    style["--tw-rotate"] = rotation + "deg";
  }
  return style;
}
```

`StoryCanvas.tsx`:
1. Replace `              ...overlayPositionStyle(overlay.x, overlay.y),` with
   `              ...overlayPositionStyle(overlay.x, overlay.y, overlay.rotation),`.
2. In the mention `<Link>`, replace
   `className="absolute z-10 -translate-x-1/2 -translate-y-1/2 rounded-chip bg-white/85 px-2 py-0.5 text-xs font-semibold text-ink-900 no-underline"`
   with:
```tsx
            // The app's pill (story_viewer_screen.dart _buildMentionPills):
            // black at 0.55, white bold 13px, fully rounded.
            className="absolute z-10 -translate-x-1/2 -translate-y-1/2 rounded-full bg-black/55 px-2.5 py-1 text-[13px] font-bold text-white no-underline"
```
   The comment goes above the `<Link`, not inside JSX attributes.

`CreateStory.tsx` (mention node `:766`): replace
`className="absolute -translate-x-1/2 -translate-y-1/2 cursor-move select-none rounded-chip bg-white/85 px-2 py-0.5 text-xs font-semibold text-ink-900"`
with `className="absolute -translate-x-1/2 -translate-y-1/2 cursor-move select-none rounded-full bg-black/55 px-2.5 py-1 text-[13px] font-bold text-white"`.

Add `rotation?: number;` to `StoryOverlay` in `types.ts` (after `scale: number;`) with the comment
`/** Degrees. The app's studio writes it; the web composer never rotates. */`.

- [ ] **Step 4: Run them and confirm they pass.** Use the same command, plus
  `CI=true npm test -- --watchAll=false src/components/stories`. Expected: all pass, including `storiesStyling.test.ts`
  and the existing "renders mentions as pills" test (which checks text, href and position, not colours).

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-17`.

```bash
git add src/components/stories/storyOverlays.ts src/components/stories/StoryCanvas.tsx src/components/stories/CreateStory.tsx src/components/stories/types.ts src/components/stories/storyPlate.test.ts src/components/stories/StoryViewer.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(stories): rotated app stickers tilt on the web; mention pills match

The web ignored overlays[].rotation, so a tilted sticker from the app
showed upright. Rotation now rides Tailwind's --tw-rotate variable next to
the exact-centre translate (no raw inline transform). Mention pills use the
app's dark pill. Exact centring is kept and pinned, including in RTL; the
app viewer's approximate pixel offsets are an app follow-up.

Still open (Phase 3 moments): hashtags, allowReplies/allowSharing, link
host, moments i18n sweep; app: exact-centre overlays/mentions (Phase 2).
EOF
```

---

### Task P3-MOM-18: the viewer shows a story's hashtags (moments#25)

The web composer sends `hashtags` (`CreateStory.tsx:550`), and so does the app. The app viewer shows them as labels
under the caption: light blue, semibold, `#` added when missing, and **not links**, because no hashtag search exists
(`story_viewer_screen.dart:1489-1537`, `Key('story-hashtags')`). The web shows nothing.

On the web, `StoryCanvas` draws them under the caption for media stories. It also draws them at the same spot on text
stories, where the app's early-return branch shows none (a harmless superset, and the tags are real content).

**Files:**
- Modify: `src/components/stories/StoryCanvas.tsx:131-142` (caption block).
- Modify: `src/utils/locales/eng.json` (`stories.hashtags_label`).
- Test: append to `src/components/stories/StoryViewer.test.tsx`.

**Interfaces:**
- Consumes: `story.hashtags?: string[]`. These are lower-cased, without `#`, up to 10 from the web, and possibly with
  `#` or empty from old rows.
- Produces: `data-testid="<prefix>-hashtags"` (`story-hashtags` / `highlight-story-hashtags`). Exported
  `storyHashtags(story): string[]`.

- [ ] **Step 1: Write the failing tests.** Append to `StoryViewer.test.tsx`:

```tsx
describe("hashtags (moments#25)", () => {
  it("shows each tag once with a # under the caption, as plain labels", () => {
    renderViewer([
      story({
        mediaType: "image",
        mediaUrls: ["https://cdn/p.jpg"],
        text: "Han river",
        hashtags: ["seoul", "#travel", "", "  ", "seoul"],
      }),
    ]);
    const tags = screen.getByTestId("story-hashtags");
    expect(tags).toHaveTextContent("#seoul");
    expect(tags).toHaveTextContent("#travel");
    expect(tags.textContent).not.toContain("##");
    expect(tags.querySelectorAll("span")).toHaveLength(2);
    // Labels, not links: there is no hashtag search to send anyone to.
    expect(tags.querySelector("a")).toBeNull();
    expect(screen.getByTestId("story-caption")).toHaveTextContent("Han river");
  });

  it("shows them on a text story too, and nothing when there are none", () => {
    renderViewer([story({ hashtags: ["kpop"] }), story({ _id: "story-2" })]);
    expect(screen.getByTestId("story-hashtags")).toHaveTextContent("#kpop");
    fireEvent.click(screen.getByTestId("story-next"));
    expect(screen.queryByTestId("story-hashtags")).toBeNull();
  });
});
```

- [ ] **Step 2: Run it and confirm it fails.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/StoryViewer.test.tsx
```
Expected: `story-hashtags` is not found.

- [ ] **Step 3: Implement.** In `StoryCanvas.tsx`, after `storyLocationName` (from P3-MOM-13), add:

```tsx
/**
 * The story's hashtags as the app shows them: `#` added when missing, blanks
 * and repeats dropped. Labels only -- no hashtag search exists, and a chip
 * that goes nowhere is the worse bug (the app's own reasoning).
 */
export function storyHashtags(story: any): string[] {
  const raw: any[] = story && Array.isArray(story.hashtags) ? story.hashtags : [];
  const out: string[] = [];
  raw.forEach((tag) => {
    const clean = typeof tag === "string" ? tag.trim().replace(/^#+/, "") : "";
    if (!clean) return;
    const label = "#" + clean;
    if (out.indexOf(label) === -1) out.push(label);
  });
  return out;
}
```
Add `const tags = storyHashtags(story);` after `const hasBottomSticker = …;`, then replace the caption block:

```tsx
      {/* Caption: a media story's `text` (the app's caption field). */}
      {!isText && body && (
        <p
          data-testid={testIdPrefix + "-caption"}
          className={[
            "pointer-events-none absolute inset-x-4 z-[6] m-0 whitespace-pre-wrap break-words text-center text-base text-white drop-shadow-[0_1px_3px_rgba(0,0,0,0.9)]",
            hasBottomSticker ? "top-24" : "bottom-40",
          ].join(" ")}
        >
          {body}
        </p>
      )}
```
with:
```tsx
      {/* Caption (a media story's `text`, the app's caption field) and the
          hashtags under it, as one block so they never overlap. */}
      {((!isText && body) || tags.length > 0) && (
        <div
          className={[
            "pointer-events-none absolute inset-x-4 z-[6] flex flex-col items-center gap-1.5 text-center",
            hasBottomSticker ? "top-24" : "bottom-40",
          ].join(" ")}
        >
          {!isText && body && (
            <p
              data-testid={testIdPrefix + "-caption"}
              className="m-0 whitespace-pre-wrap break-words text-base text-white drop-shadow-[0_1px_3px_rgba(0,0,0,0.9)]"
            >
              {body}
            </p>
          )}
          {tags.length > 0 && (
            <p
              data-testid={testIdPrefix + "-hashtags"}
              className="m-0 flex flex-wrap justify-center gap-x-2 gap-y-1 text-sm font-semibold text-sky-200 drop-shadow-[0_1px_3px_rgba(0,0,0,0.9)]"
            >
              {tags.map((tag) => (
                <span key={tag} dir="auto">
                  {tag}
                </span>
              ))}
            </p>
          )}
        </div>
      )}
```
`dir="auto"` keeps an Arabic or Hebrew tag's `#` on the correct side.

StoryCanvas has no `t`. The aria label lives on the viewer side and is not needed for plain text, so
`stories.hashtags_label` is **not** added. Leave `eng.json` untouched for this task.

- [ ] **Step 4: Run it and confirm it passes.** Use the same command, plus
  `CI=true npm test -- --watchAll=false src/components/stories`. Expected: all pass.

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-18`.

```bash
git add src/components/stories/StoryCanvas.tsx src/components/stories/StoryViewer.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(stories): show a story's hashtags under the caption

Hashtags were composed, sent and stored but no web screen showed them. The
canvas now lists them under the caption the way the app does (a # added,
blanks and repeats dropped, labels rather than links), for highlights too.

Still open (Phase 3 moments): allowReplies/allowSharing, link host, moments
i18n sweep.
EOF
```

---

### Task P3-MOM-19: the viewer honours `allowReplies` and `allowSharing` (moments#25)

The backend refuses a reply when `allowReplies` is false (`controllers/stories.js:1163`, 403) and a share when
`allowSharing` is false (`:1431`, 403 for **every** caller, owner included). The web viewer offers both anyway, so the
user types a reply and gets "Couldn't send your message". The app does not honour them either (the model parses them at
`story_model.dart:284-285`, but no screen reads them). The web fixes its own side. Reactions are not affected:
`reactToStory` has no such check.

Missing means allowed (`!== false`), as in the app's model.

**Files:**
- Modify: `src/components/stories/StoryViewer.tsx:705-713` (owner share pill), `:745-785` (non-owner bar).
- Modify: `src/utils/locales/eng.json` (`stories.replies_off`).
- Test: append to `src/components/stories/StoryViewer.test.tsx`.

**Interfaces:**
- Consumes: `story.allowReplies?: boolean`, `story.allowSharing?: boolean` (default true, `models/Story.js:204-205`).
- Produces: no new exports.

- [ ] **Step 1: Write the failing tests.** Append:

```tsx
describe("allowReplies / allowSharing (moments#25)", () => {
  it("hides the reply box but keeps reactions when replies are off", () => {
    renderViewer([story({ allowReplies: false })]);
    expect(screen.queryByPlaceholderText("Send a message...")).toBeNull();
    expect(screen.queryByTestId("story-reply-open")).toBeNull();
    expect(screen.getByTestId("story-replies-off")).toBeInTheDocument();
    expect(screen.getByTestId("story-reaction-toggle")).toBeInTheDocument();
  });

  it("hides share for the reader and for the owner when sharing is off", () => {
    renderViewer([story({ allowSharing: false })]);
    expect(screen.queryByTestId("story-share-button")).toBeNull();
  });

  it("hides the owner's share pill too (the server refuses the owner as well)", () => {
    mockCurrentUserId = "author-1";
    renderViewer([story({ allowSharing: false })]);
    expect(screen.queryByTestId("story-share-button")).toBeNull();
    expect(screen.getByTestId("story-viewers-button")).toBeInTheDocument();
  });

  it("treats a missing flag as allowed (old stories)", () => {
    renderViewer([story({ allowReplies: undefined, allowSharing: null })]);
    expect(screen.getByTestId("story-share-button")).toBeInTheDocument();
    expect(screen.getByTestId("story-reply-open")).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run it and confirm it fails.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/StoryViewer.test.tsx
```
Expected:
- The share buttons are still present.
- `story-replies-off` and `story-reply-open` don't exist yet, so the first and fourth tests fail.

Note that `allowSharing: null` counts as allowed: `null !== false`.

- [ ] **Step 3: Implement.** In `StoryViewer.tsx`, after `const isTimed = !isVideo;`, add:

```tsx
  // Missing means allowed, as in the app's model (`json['allowReplies'] != false`).
  // The server 403s a reply / share on a story that turned them off, so
  // offering the button only produces a failure toast.
  const canReply = currentStory.allowReplies !== false;
  const canShare = currentStory.allowSharing !== false;
```
Owner pill: wrap the owner's `story-share-button` `<button>…</button>` in `{canShare && ( … )}`.

Non-owner bar: replace the fragment that starts with the read-only `<input … onFocus={() => setShowReplyInput(true)} readOnly`
and ends before `{/* Reaction Picker */}`, from `          ) : (` through `            </>`. The `showReplyInput`
branch above it stays, and it is reachable only when `canReply`. The new fragment is:
```tsx
          ) : (
            <>
              {canReply ? (
                <input
                  type="text"
                  placeholder={t("stories.reply_placeholder") || "Send a message..."}
                  onFocus={() => setShowReplyInput(true)}
                  readOnly
                  className="mb-3 w-full rounded-full border border-white/30 bg-white/20 px-4 py-3 text-sm text-white outline-none backdrop-blur placeholder:text-white/70"
                />
              ) : (
                <p
                  data-testid="story-replies-off"
                  className="mb-3 text-center text-xs text-white/70"
                >
                  {t("stories.replies_off") || "Replies are turned off for this story"}
                </p>
              )}
              <div className="flex items-center justify-center gap-6">
                <button
                  type="button"
                  className={`${ICON_BUTTON} relative ${userReaction ? "text-red-500" : ""}`}
                  data-testid="story-reaction-toggle"
                  onClick={() => setShowReactions(!showReactions)}
                  aria-label={t("stories.react") || "React"}
                >
                  <Heart size={24} aria-hidden />
                  {userReaction && (
                    <span className="absolute -right-2 -top-2 text-base">{userReaction}</span>
                  )}
                </button>
                {canReply && (
                  <button
                    type="button"
                    className={ICON_BUTTON}
                    data-testid="story-reply-open"
                    onClick={() => setShowReplyInput(true)}
                    aria-label={t("stories.reply_placeholder") || "Send a message..."}
                  >
                    <MessageCircle size={24} aria-hidden />
                  </button>
                )}
                {canShare && (
                  <button
                    type="button"
                    className={ICON_BUTTON}
                    data-testid="story-share-button"
                    onClick={() => setOpenSheet("share")}
                    aria-label={t("stories.share_story") || "Share"}
                  >
                    <Share2 size={24} aria-hidden />
                  </button>
                )}
              </div>
            </>
          )}
```
Also guard the share sheet render: replace `{openSheet === "share" && (` with `{openSheet === "share" && canShare && (`.

`eng.json` (top-level `stories`): `"replies_off": "Replies are turned off for this story",`

- [ ] **Step 4: Run it and confirm it passes.** Use the same command. Expected: all `StoryViewer.test.tsx` tests pass,
  including "opens the share sheet for any viewer" (whose fixture has no flags).

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-19`.

```bash
git add src/components/stories/StoryViewer.tsx src/components/stories/StoryViewer.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(stories): honour allowReplies and allowSharing in the viewer

The server refuses replies and shares on stories that turned them off, but
the web viewer offered both and ended in a failure toast. The reply box and
share buttons now hide when the author turned them off (missing still
means allowed); reactions are unaffected, as on the server.

Still open (Phase 3 moments): link host line, moments i18n sweep; app:
allowReplies/allowSharing are parsed but not honoured (app follow-up).
EOF
```

---

### Task P3-MOM-20: the link sticker always shows the real host under its label (moments#25)

The web shows `link.host` only when the author gave no label (`StoryCanvas.tsx:212`). The app always shows the label
with the real host underneath (`story_viewer_screen.dart:1704-1730`, `Key('story-link-host')`). A pill reading
"Shop Now" otherwise says nothing about where a tap goes, which is the phishing trick `lib/storyLink.js` exists to
defuse.

Phase 1 item 0 makes the backend persist `host` (`models/Story.js:115`). Stories saved before that, and video stories
before 44bdacf, have no `host`, so the web derives it from `link.url` with the existing `parseLinkUrl`. A URL that
fails parsing shows no host line. The anchor still points at `link.url`, as today.

**Files:**
- Modify: `src/components/stories/StoryCanvas.tsx:203-214` (link sticker), plus the `./storyOverlays` import.
- Test: append to `src/components/stories/StoryViewer.test.tsx`.

**Interfaces:**
- Consumes: `story.link: { url: string; title?: string; displayText?: string; host?: string }`.
- Produces: `export function storyLinkHost(link: any): string` (server host, else parsed from `url`, else `""`) and
  `data-testid="<prefix>-link-host"`.

- [ ] **Step 1: Write the failing tests.** Append to the `structured stickers` describe:

```tsx
  it("shows the real host under the author's label", () => {
    renderViewer([
      story({ link: { url: "https://evil.example/x", title: "", displayText: "Shop Now", host: "evil.example" } }),
    ]);
    expect(screen.getByTestId("story-link-sticker")).toHaveTextContent("Shop Now");
    expect(screen.getByTestId("story-link-host")).toHaveTextContent("evil.example");
  });

  it("derives the host from the url when an older backend dropped it", () => {
    renderViewer([
      story({ link: { url: "https://www.Example.com:8443/a?b=c", title: "", displayText: "Read" } }),
    ]);
    expect(screen.getByTestId("story-link-host")).toHaveTextContent("example.com");
  });

  it("does not print the host twice when it is already the label", () => {
    renderViewer([
      story({ link: { url: "https://example.com/sale", title: "", displayText: "", host: "example.com" } }),
    ]);
    expect(screen.getByTestId("story-link-sticker")).toHaveTextContent("example.com");
    expect(screen.queryByTestId("story-link-host")).toBeNull();
  });
```

- [ ] **Step 2: Run them and confirm they fail.**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments && CI=true npm test -- --watchAll=false src/components/stories/StoryViewer.test.tsx
```
Expected: the first two fail because `story-link-host` is not found. The third passes.

- [ ] **Step 3: Implement.** In `StoryCanvas.tsx`, add `parseLinkUrl,` to the `./storyOverlays` import. After
  `storyHashtags`, add:

```tsx
/**
 * Where a link sticker really goes: the host the server parsed (stored from
 * Phase 1 on), else the same parse done here for stories saved before the
 * backend kept it. Shown under the label because the label is the poster's
 * words and the host is not -- the app does the same.
 */
export function storyLinkHost(link: any): string {
  if (!link) return "";
  if (typeof link.host === "string" && link.host.trim()) return link.host.trim().toLowerCase();
  const parsed = parseLinkUrl(link.url);
  return parsed ? parsed.host : "";
}
```
Replace the anchor's children:
```tsx
          {story.link.displayText || story.link.title || story.link.host || story.link.url}
        </a>
```
with:
```tsx
          {(() => {
            const host = storyLinkHost(story.link);
            const label = story.link.displayText || story.link.title || host || story.link.url;
            return (
              <span className="flex flex-col items-center leading-tight">
                <span className="max-w-[16rem] truncate">{label}</span>
                {host && host !== String(label).toLowerCase() && (
                  <span
                    data-testid={testIdPrefix + "-link-host"}
                    dir="ltr"
                    className="max-w-[16rem] truncate text-[11px] font-normal text-ink-500"
                  >
                    {host}
                  </span>
                )}
              </span>
            );
          })()}
        </a>
```
`dir="ltr"` keeps a host readable inside an RTL page.

- [ ] **Step 4: Run them and confirm they pass.** Use the same command, plus
  `CI=true npm test -- --watchAll=false src/components/stories`. Expected: all pass, including the existing "falls back
  to the real host when the author gave no label" and "opens the link sticker in a new tab" tests.

- [ ] **Step 5: Commit.** In `docs/REMAINING_WORK.md`, tick `- [ ] P3-MOM-20`.

```bash
git add src/components/stories/StoryCanvas.tsx src/components/stories/StoryViewer.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(stories): link sticker shows the real host under its label

The web showed link.host only when the author gave no label, so a "Shop
Now" pill hid where a tap goes. Like the app, the host now always sits
under the label: the server's link.host (persisted since the stories audit
merge), or parsed from the url for older stories.

Still open (Phase 3 moments): moments i18n sweep (translations of the new
stories.* keys), push unit.
EOF
```

---

#### Keys added by P3-MOM-12..20

All of these go in the top-level `"stories"` object of `src/utils/locales/eng.json`. The 17 other locales get them in
the unit's i18n sweep task.

| Key | English |
|---|---|
| `stories.one_image_only` | A story shows one picture. We kept the first one. |
| `stories.location_label` | Location |
| `stories.report_story` | Report story |
| `stories.block_author` | Block {{name}} |
| `stories.block_confirm_title` | Block {{name}}? |
| `stories.block_confirm_body` | They won't be able to see your profile, moments or stories, or message you, and you won't see theirs. |
| `stories.block_confirm` | Block |
| `stories.blocked` | {{name}} is blocked |
| `stories.block_failed` | Couldn't block this person. Try again. |
| `stories.replies_off` | Replies are turned off for this story |


### Task P3-MOM-I18N: The moments unit's new strings in all 18 locales

**Files:**
- Create if missing in this branch (verbatim copy from P3-CHAT-I18N): `scripts/i18n/new-keys.js`, `src/utils/locales/p3Keys.test.ts`
- Create: `scripts/i18n/keys/2026-10-16-p3-moments.json` (all 18 locales; the durable record of what this unit translated)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: every English string the unit's tasks added to `eng.json` — listed in the key tables at the end of P3-MOM-11 (`#### Keys added by P3-MOM-1..11`) and P3-MOM-20 (`#### Keys added by P3-MOM-12..20`). The script below finds them from the diff against `web/p3-base`, so a key a task added but forgot to list is still caught.
- Produces: no English-only key in this unit's push.

Tooling and translation rules: as in Task P3-CHAT-I18N (copy `scripts/i18n/new-keys.js` and `src/utils/locales/p3Keys.test.ts` verbatim if this branch does not have them yet).

- [ ] **Step 1: Write the failing test** (copy the guard if missing) and generate the keys file

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments
node scripts/i18n/new-keys.js web/p3-base scripts/i18n/keys/2026-10-16-p3-moments.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: the script prints `N new or changed keys` (N matches the unit's key tables, give or take keys a task added beyond its table); the test FAILS with `<key>: missing` for each of the 17 non-English locales.

- [ ] **Step 2: Translate**

Fill every `""` in `scripts/i18n/keys/2026-10-16-p3-moments.json` for the 17 non-English locales (rules above). Re-running `new-keys.js` keeps what is already filled.

- [ ] **Step 3: Merge into the locale files**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p3-moments.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: all `p3Keys` cases pass; the existing `src/utils/i18n*.test.ts` suites stay green (locale chunks still parse).

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/keys/2026-10-16-p3-moments.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
i18n(moments): translate the Phase 3 moments strings into all 18 locales

Keys found by scripts/i18n/new-keys.js against web/p3-base and merged
with merge-keys.js; p3Keys.test.ts fails on any missing, empty or
placeholder-mismatched translation.

Still open (Phase 3 moments): push gate (P3-MOM-PUSH); native review of
the new strings.
EOF
```

---
### Task P3-MOM-PUSH: Push unit MOM (2 of 4) — full suite + build green, then the coordinator pushes

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status line, §6 changelog line, §3 production-QA lines for the smoke list below)

- [ ] **Step 1: Every task in the unit is committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-moments
git status --short                                   # expect: nothing (except the node_modules symlink, untracked)
grep -n "P3-MOM-" docs/REMAINING_WORK.md | grep -c "\[ \]"   # expect: 1 (this PUSH line only)
```

- [ ] **Step 2: Rebase onto the live site**

```bash
git fetch origin
git rebase origin/main
```
Conflicts: `src/utils/locales/*.json` (keep both units' keys; re-run `node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p3-moments.json` after resolving), `docs/REMAINING_WORK.md` (keep CHAT's ticks and yours), `src/utils/recorderMime.ts` + test and `scripts/i18n/new-keys.js` + `src/utils/locales/p3Keys.test.ts` (identical adds resolve on their own; if git reports a conflict, take the live version: `git checkout origin/main -- <file>`), `src/store/slices/usersSlice.ts` only if CHAT touched it (keep both edits).
After resolving: `git rebase --continue`, then re-run `CI=true npm test -- --watchAll=false p3Keys` (keys from earlier units must still be complete).

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `Test Suites: … 0 failed`, `Tests: … 0 failed`; passed count ≥ the previous push's count plus this unit's new tests (baseline before Phase 3: 3190 passed, 6 skipped). Any failure: fix in a new commit (never `--no-verify`, never skip a test to get green).

- [ ] **Step 4: Production build**

```bash
npm run build 2>&1 | tail -20
```
Expected: `Compiled successfully` or `Compiled with warnings` with **no** TypeScript error (TS 3.7 rejects newer syntax here first), then the prerender step finishes without an error line. Optional: `npm run test:budget` and note the first-paint size in the tracker (the budget is already over by ~5 KB; not a gate).

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P3-MOM-PUSH`; §1 Status: "Phase 3 moments pushed (YYYY-MM-DD)"; §6 Done: one line naming the unit's fixes; §3 Production QA: one `- [ ]` line per smoke item below that is not yet checked.

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: Phase 3 moments ready to deploy

Still open (Phase 3): the remaining units' tasks; production smoke
for moments (docs/REMAINING_WORK.md §3); device QA rows.
EOF
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p3-moments:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/            # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1   # a new bundle hash
```

- [ ] **Step 7: Production smoke (two accounts: one on the web, one in app 2.6.1)**

  - [ ] Post a photo-only, a video-only and a voice-only moment from web → each appears in the app (2.6.1) and on web; edit an app-made photo-only moment on web without adding text.
  - [ ] Pick each of the 20 backgrounds on a text moment → the app shows the same colours (spot-check peach, lagoon, sunset).
  - [ ] As moment owner, delete someone else's comment on web; report a comment; block a comment author → their comments and moments disappear after refetch.
  - [ ] Comment with a GIF only and with a photo only → both show in the app; an app comment with @mention shows highlighted on web.
  - [ ] Saved moments with > 10 saves: scroll loads page 2; voice/text moments show a tile.
  - [ ] Create a story with 3 images selected → one story with the first image and an info toast.
  - [ ] View an app story with location, hashtags, rotation and a link sticker → web shows location, tags, rotated overlay and the link's host; a story with replies off shows no reply bar.
  - [ ] Report a story and block its author from the web viewer → story pauses during the dialog; after block you land on /stories without their ring.
  - [ ] Record a moment voice note in Safari and Chrome → plays in the iOS app (QA sheet row).

Record results in `docs/REMAINING_WORK.md` §3 in the next unit's first commit (or a docs-only commit if this is the last unit). A failure that breaks a live flow → Step 8.

- [ ] **Step 8 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p3-moments-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -40
CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(The unit is a linear series after the rebase, so the range revert is clean. Note the revert in §6 and reopen the tasks.)

---

## Unit COMMUNITY (push 3 of 4) — P3-COM-1 … P3-COM-13, P3-COM-I18N, P3-COM-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p3-community`, branch `web/p3-community` (from `web/p3-base`). One
implementer, tasks in number order. Includes the signed-out public profile reading `followersCount`/`followingCount`
(P3-COM-11) and the blocked-viewer card (P3-COM-12), which consume backend P1-PRIV-1…4 and fall back cleanly before them.

Unit-level facts:
- `eng.json` has `"community": "Community"` (a string): Nearby strings move to `communityNearby.*`, waves to the existing
  `waves` object. In production today these components show raw keys, not English.
- `NewChat.tsx` is touched by CHAT (P3-CHAT-3) and here (P3-COM-2, one line); `ProfileActions.tsx` is left to CHAT.
- No coins/rewarded unlock exists on web: wave cap and Today extras offer VIP only.

### Unit notes (COMMUNITY) — read before P3-COM-1

- Worktree: `/Users/davis/Desktop/Personal/wt-web-p3-community`, branch `web/p3-community` off `web/p3-base` (Task P3-0). Every
  command below runs there. Line numbers are from fba6208; anchor each edit on the quoted code, not the number.
- **The `community.*` i18n trap (found while planning).** `eng.json` has `"community": "Community"` — a *string*.
  So every key under `community.nearby.*` / `community.waves.*` can never exist, and the components'
  `t("community.nearby.title") || "Nearby Users"` fallback never fires in production: i18next returns the key
  itself (truthy), so users see the raw key `community.nearby.title`. This is why the audit counted "21 missing
  keys". The fix is new namespaces, not new keys under the string: Nearby → `communityNearby.*`, the waves inbox
  and wave sheet → the existing top-level `waves` object (`waves.*`, `waves.sheet.*`, `waves.cap.*`).
- Verified OK, no task: `communityMain.visitors.pill` exists as `pill_one`/`pill_other` and is called with
  `{ count }` (i18next plural lookup works); the filter sheet's gender labels already go through
  `communityMain.filterSheet.{any,male,female,other}`.
- Backend contract notes (be-integration 21959fb = live after the fix/moments-stories-audit merge):
  `GET /community/nearby` reads `latitude`, `longitude`, `radius` (km, capped by tier), `limit` (1-100, default 50),
  `offset`; each row is `{ _id, name, images (raw paths, first 3), location{type,coordinates,city,country},
  distance (km, coarsened if showCity off), native_language, language_to_learn, gender, bio, isOnline, lastSeen,
  level, topics, privacySettings{6 public toggles}, birth_year, hasActiveStory }`, already passed through
  `redactUserForViewer`. Username routes are on the `/api/v1/auth/users` router (`routes/users.js:66,69`);
  `/search/username` 400s under 2 chars. `GET /languages` → `{ success, data: [{ code, name, nativeName, flag }] }`.
  Wave cap: `429 { success:false, error, code:'wave_cap' }`, emitted only while `WAVE_CAP_ENABLED` is on.
  `GET /community/waves?archive=true` = 7–30 days; `?reveal=1` adds `revealed:true` per row + `maskedCount:0`.
- Phase 1 dependency: P3-COM-11 and P3-COM-12 read fields P1-PRIV-1/3/4 add (`followersCount`/`followingCount`,
  `isBlocked`, follow 403). Both work against today's backend too (array length fallback; `isBlocked` absent).

---

### Task P3-COM-1: Nearby works — real params, real fields, real profile route, privacy toggles (community#2)

**Files:**
- Modify: `src/store/slices/communitySlice.ts:154-167` (`getNearbyUsers`)
- Modify (rewrite): `src/components/community/NearbyUsers.tsx`
- Modify: `src/utils/locales/eng.json` (new top-level `communityNearby`)
- Test: `src/store/slices/communityEndpoints.test.ts` (append), `src/components/community/NearbyUsers.test.tsx` (new)

**Interfaces:**
- Consumes: `GET /api/v1/community/nearby?latitude&longitude&radius&limit&offset` → `{ success, data: NearbyRow[],
  pagination: { total, limit, offset, hasMore } }` (controllers/community.js:28-218). Same before and after Phase 1.
- Produces: `getNearbyUsers({ latitude, longitude, radius?, page?, limit? })` (page → `offset = (page-1)*limit`);
  exports from `NearbyUsers.tsx`: `NearbyUser`, `nearbyIsOnline(user)`, `nearbyPlace(user)`,
  `formatNearbyDistance(km)`.

- [ ] **Step 1: Write the failing tests**

Append to `src/store/slices/communityEndpoints.test.ts`:

```ts
describe("getNearbyUsers (community#2)", () => {
  // controllers/community.js reads latitude/longitude/offset. The slice sent
  // lat/lng/page, so every request answered 400 "Valid latitude and longitude
  // are required" and the page always showed "No users found nearby".
  it("-> GET /api/v1/community/nearby with latitude, longitude, radius, limit, offset", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getNearbyUsers.initiate({
        latitude: 37.5665,
        longitude: 126.978,
        radius: 10,
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe("/api/v1/community/nearby");
    expect(url.searchParams.get("latitude")).toBe("37.5665");
    expect(url.searchParams.get("longitude")).toBe("126.978");
    expect(url.searchParams.get("radius")).toBe("10");
    expect(url.searchParams.get("limit")).toBe("50");
    expect(url.searchParams.get("offset")).toBe("0");
    expect(url.searchParams.get("lat")).toBeNull();
    expect(url.searchParams.get("lng")).toBeNull();
    expect(url.searchParams.get("page")).toBeNull();
  });

  it("turns page 3 into an offset the server understands", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getNearbyUsers.initiate({
        latitude: 1,
        longitude: 2,
        page: 3,
        limit: 20,
      })
    );
    const url = new URL(calls[0].url);
    expect(url.searchParams.get("offset")).toBe("40");
    expect(url.searchParams.get("limit")).toBe("20");
  });
});
```

Create `src/components/community/NearbyUsers.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import {
  createMemoryRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from "react-router-dom";
import { makeStore } from "../../store";
import NearbyUsers, { formatNearbyDistance, nearbyIsOnline, nearbyPlace } from "./NearbyUsers";

// The key plus whatever was interpolated: behaviour, not copy.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, o?: any) => (o ? `${key} ${Object.values(o).join(" ")}` : key),
  }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const ROWS = [
  {
    _id: "n1",
    name: "Near One",
    images: ["users/n1.jpg"],
    native_language: "Korean",
    language_to_learn: "English",
    distance: 0.42,
    isOnline: true,
    location: { city: "Seoul", country: "South Korea" },
    privacySettings: { showCity: true, showCountryRegion: true, showOnlineStatus: true },
  },
  {
    // An app user who hid their city and online status. The server already
    // drops both; a stale or older payload must not show them either.
    _id: "n2",
    name: "Near Two",
    images: [],
    native_language: "Japanese",
    language_to_learn: "Korean",
    distance: 12.6,
    isOnline: true,
    location: { city: "Busan", country: "South Korea" },
    privacySettings: { showCity: false, showOnlineStatus: false },
  },
];

const requested: string[] = [];
const originalFetch = global.fetch;
const originalGeo = (navigator as any).geolocation;

beforeEach(() => {
  requested.length = 0;
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    requested.push(url);
    const body =
      url.indexOf("/community/nearby") >= 0
        ? { success: true, data: ROWS, pagination: { total: 2, limit: 50, offset: 0, hasMore: false } }
        : { success: true, data: [] };
    return Promise.resolve(
      new Response(JSON.stringify(body), {
        status: 200,
        headers: { "content-type": "application/json" },
      })
    );
  });
  Object.defineProperty(navigator, "geolocation", {
    configurable: true,
    value: {
      getCurrentPosition: (ok: any) => ok({ coords: { latitude: 37.5665, longitude: 126.978 } }),
    },
  });
});

afterEach(() => {
  global.fetch = originalFetch;
  Object.defineProperty(navigator, "geolocation", { configurable: true, value: originalGeo });
});

const SIGNED_IN = { auth: { userInfo: { user: { _id: "u1" }, token: "t" } } };

function renderNearby() {
  const router = createMemoryRouter(
    createRoutesFromElements(
      <Route path="/">
        <Route path="community/nearby" element={<NearbyUsers />} />
        <Route path="community/:userId" element={<div data-testid="profile-screen" />} />
      </Route>
    ),
    { initialEntries: ["/community/nearby"] }
  );
  render(
    <Provider store={makeStore(SIGNED_IN)}>
      <RouterProvider router={router} />
    </Provider>
  );
  return router;
}

const nearbyRequests = () => requested.filter((u) => u.indexOf("/community/nearby") >= 0);

describe("Nearby (community#2)", () => {
  it("asks with the parameter names the server reads", async () => {
    renderNearby();
    await screen.findByText("Near One");
    const url = new URL(nearbyRequests()[nearbyRequests().length - 1]);
    expect(url.searchParams.get("latitude")).toBe("37.5665");
    expect(url.searchParams.get("longitude")).toBe("126.978");
    expect(url.searchParams.get("offset")).toBe("0");
    expect(url.searchParams.get("lat")).toBeNull();
  });

  it("loads the photo from the raw storage path the endpoint returns", async () => {
    renderNearby();
    const img = await screen.findByAltText("Near One");
    expect(img).toHaveAttribute("src", "http://localhost:5003/uploads/users/n1.jpg");
  });

  it("reads the snake_case language fields", async () => {
    renderNearby();
    await screen.findByText("Near One");
    expect(screen.getAllByTestId("nearby-native")[0]).toHaveTextContent("Korean");
    expect(screen.getAllByTestId("nearby-learning")[0]).toHaveTextContent(
      "communityNearby.learning English"
    );
  });

  it("honours the hidden city and hidden online status", async () => {
    renderNearby();
    await screen.findByText("Near Two");
    expect(screen.getAllByTestId("nearby-online-dot")).toHaveLength(1);
    const places = screen.getAllByTestId("nearby-place").map((el) => el.textContent);
    expect(places).toEqual(["Seoul, South Korea", "South Korea"]);
  });

  it("opens the member on /community/:id, which is a real route", async () => {
    const router = renderNearby();
    fireEvent.click(await screen.findByText("Near One"));
    await waitFor(() => expect(router.state.location.pathname).toBe("/community/n1"));
    expect(screen.getByTestId("profile-screen")).toBeInTheDocument();
  });

  it("uses the app's distance format", () => {
    expect(formatNearbyDistance(0.42)).toBe("420m");
    expect(formatNearbyDistance(3.14)).toBe("3.1km");
    expect(formatNearbyDistance(12.6)).toBe("13km");
    expect(formatNearbyDistance(undefined)).toBe("");
  });

  it("keeps the privacy helpers pure", () => {
    expect(nearbyIsOnline({ _id: "x", name: "x", isOnline: true })).toBe(true);
    expect(
      nearbyIsOnline({ _id: "x", name: "x", isOnline: true, privacySettings: { showOnlineStatus: false } })
    ).toBe(false);
    expect(
      nearbyPlace({
        _id: "x",
        name: "x",
        location: { city: "Seoul", country: "South Korea" },
        privacySettings: { showCountryRegion: false },
      })
    ).toBe("Seoul");
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false communityEndpoints NearbyUsers`
Expected: FAIL. The slice tests see `lat`/`lng`/`page` and no `latitude`/`offset`. `NearbyUsers.test.tsx` fails to
import `formatNearbyDistance` (not exported) — TypeScript/Jest "is not a function".

- [ ] **Step 3: Implement**

`src/store/slices/communitySlice.ts` — replace:

```ts
    // Nearby Users (Discovery)
    getNearbyUsers: builder.query({
      query: ({ latitude, longitude, radius = 50, page = 1, limit = 20 }: {
        latitude: number;
        longitude: number;
        radius?: number;
        page?: number;
        limit?: number;
      }) => ({
        url: `${COMMUNITY_NEARBY}?lat=${latitude}&lng=${longitude}&radius=${radius}&page=${page}&limit=${limit}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["Community"],
    }),
```

with:

```ts
    // Nearby Users (Discovery). controllers/community.js getNearbyUsers reads
    // `latitude`, `longitude`, `radius` (km), `limit` and `offset`. It never
    // read `lat`/`lng`/`page`, so every request used to 400 and the page
    // always said nobody was nearby. `page` stays the caller's unit and is
    // turned into the offset here.
    getNearbyUsers: builder.query({
      query: ({ latitude, longitude, radius = 50, page = 1, limit = 50 }: {
        latitude: number;
        longitude: number;
        radius?: number;
        page?: number;
        limit?: number;
      }) => ({
        url: COMMUNITY_NEARBY,
        params: {
          latitude: String(latitude),
          longitude: String(longitude),
          radius: String(radius),
          limit: String(limit),
          offset: String((Math.max(1, page) - 1) * limit),
        },
      }),
      keepUnusedDataFor: 5,
      providesTags: ["Community"],
    }),
```

Replace `src/components/community/NearbyUsers.tsx` with:

```tsx
import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useGetNearbyUsersQuery } from "../../store/slices/communitySlice";
import { userAvatarUrl } from "../../utils/photoUrl";
import {
  ArrowLeft,
  MapPin,
  Loader2,
  Filter,
  Users,
  Navigation,
  AlertCircle,
} from "lucide-react";

/**
 * One row of GET /api/v1/community/nearby (controllers/community.js
 * getNearbyUsers). The server projects raw `images` (storage paths, no
 * `imageUrls`), snake_case language fields and the six public privacy
 * toggles, and has already redacted what those toggles hide. They are
 * honoured here as well, as the app's nearby_tab.dart does, so a cached or
 * older payload never shows what the person chose to hide.
 */
export interface NearbyUser {
  _id: string;
  name: string;
  images?: string[];
  imageUrls?: string[];
  bio?: string;
  distance?: number;
  native_language?: string;
  language_to_learn?: string;
  isOnline?: boolean;
  location?: { city?: string; country?: string };
  privacySettings?: {
    showCity?: boolean;
    showCountryRegion?: boolean;
    showOnlineStatus?: boolean;
  };
}

/** Online dot only when the person is online AND shows it (nearby_tab.dart:784). */
export function nearbyIsOnline(user: NearbyUser): boolean {
  const ps = user.privacySettings || {};
  return Boolean(user.isOnline) && ps.showOnlineStatus !== false;
}

/** "City, Country" with each part dropped when hidden (nearby_tab.dart:998). */
export function nearbyPlace(user: NearbyUser): string {
  const ps = user.privacySettings || {};
  const loc = user.location || {};
  const city = ps.showCity === false ? "" : loc.city || "";
  const country = ps.showCountryRegion === false ? "" : loc.country || "";
  return [city, country].filter((part) => typeof part === "string" && part.trim()).join(", ");
}

/** The app's _formatDistance: metres under 1 km, one decimal under 10 km, whole km above. */
export function formatNearbyDistance(km?: number): string {
  if (typeof km !== "number" || !isFinite(km)) return "";
  if (km < 1) return `${Math.round(km * 1000)}m`;
  if (km < 10) return `${km.toFixed(1)}km`;
  return `${Math.round(km)}km`;
}

const RADIUS_OPTIONS = [5, 10, 25, 50, 100];

const NearbyUsers: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [radius, setRadius] = useState(10);
  const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [isRequestingLocation, setIsRequestingLocation] = useState(false);

  const { data, isLoading, refetch } = useGetNearbyUsersQuery(
    {
      latitude: location ? location.lat : 0,
      longitude: location ? location.lng : 0,
      radius,
    },
    { skip: !location }
  );

  const nearbyUsers: NearbyUser[] = (data && Array.isArray(data.data) && data.data) || [];

  const requestLocation = () => {
    setIsRequestingLocation(true);
    setLocationError(null);

    if (!navigator.geolocation) {
      setLocationError(
        t("communityNearby.geolocationNotSupported") || "Geolocation is not supported"
      );
      setIsRequestingLocation(false);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({ lat: position.coords.latitude, lng: position.coords.longitude });
        setIsRequestingLocation(false);
      },
      (error) => {
        switch (error.code) {
          case error.PERMISSION_DENIED:
            setLocationError(t("communityNearby.permissionDenied") || "Location permission denied");
            break;
          case error.POSITION_UNAVAILABLE:
            setLocationError(t("communityNearby.positionUnavailable") || "Location unavailable");
            break;
          case error.TIMEOUT:
            setLocationError(t("communityNearby.timeout") || "Location request timed out");
            break;
          default:
            setLocationError(t("communityNearby.unknownError") || "An error occurred");
        }
        setIsRequestingLocation(false);
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
    );
  };

  useEffect(() => {
    requestLocation();
    // Once on mount; the Try again button asks again.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const header = (
    <div className="flex items-center gap-4">
      <button
        type="button"
        onClick={() => navigate(-1)}
        aria-label={t("communityNearby.back") || "Back"}
        className="p-2 hover:bg-white/10 rounded-lg transition-colors"
      >
        <ArrowLeft className="w-6 h-6 rtl:rotate-180" />
      </button>
      <div>
        <h1 className="text-xl font-bold">{t("communityNearby.title") || "Nearby Users"}</h1>
        <p className="text-teal-100 text-sm">
          {t("communityNearby.subtitle") || "Find people around you"}
        </p>
      </div>
    </div>
  );

  if (isRequestingLocation) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50 flex flex-col items-center justify-center p-6">
        <Loader2 className="w-12 h-12 text-teal-500 animate-spin mb-4" />
        <p className="text-gray-600">
          {t("communityNearby.gettingLocation") || "Getting your location..."}
        </p>
      </div>
    );
  }

  if (locationError) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50">
        <div className="bg-gradient-to-r from-teal-500 to-blue-500 text-white p-6">{header}</div>
        <div className="flex flex-col items-center justify-center p-8 mt-20">
          <div className="p-6 rounded-full bg-red-100 mb-6">
            <AlertCircle className="w-12 h-12 text-red-500" />
          </div>
          <h2 className="text-xl font-bold text-gray-800 mb-2">
            {t("communityNearby.locationRequired") || "Location Required"}
          </h2>
          <p className="text-gray-500 text-center mb-6 max-w-md">{locationError}</p>
          <button
            type="button"
            onClick={requestLocation}
            className="px-6 py-3 bg-gradient-to-r from-teal-500 to-blue-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
          >
            {t("communityNearby.tryAgain") || "Try Again"}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50">
      <div className="bg-gradient-to-r from-teal-500 to-blue-500 text-white p-6 pb-8">
        <div className="mb-4">{header}</div>

        <div className="bg-white/20 rounded-xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <Filter className="w-5 h-5" />
            <span className="font-medium">
              {t("communityNearby.searchRadius") || "Search Radius"}
            </span>
          </div>
          <div className="flex gap-2">
            {RADIUS_OPTIONS.map((r) => (
              <button
                key={r}
                type="button"
                onClick={() => setRadius(r)}
                aria-pressed={radius === r}
                className={`flex-1 py-2 rounded-lg font-medium transition-colors ${
                  radius === r ? "bg-white text-teal-600" : "bg-white/20 text-white hover:bg-white/30"
                }`}
              >
                {r}km
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="px-4 py-6 max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2 text-gray-600">
            <Users className="w-5 h-5" />
            <span data-testid="nearby-count">
              {t("communityNearby.usersFound", { count: nearbyUsers.length }) ||
                `${nearbyUsers.length} users found`}
            </span>
          </div>
          <button
            type="button"
            onClick={() => refetch()}
            className="flex items-center gap-2 text-teal-600 font-medium"
          >
            <Navigation className="w-4 h-4" />
            {t("communityNearby.refresh") || "Refresh"}
          </button>
        </div>

        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
          </div>
        ) : nearbyUsers.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-gray-100 w-fit mx-auto mb-4">
              <MapPin className="w-8 h-8 text-gray-400" />
            </div>
            <p className="text-gray-500">{t("communityNearby.noUsers") || "No users found nearby"}</p>
            <p className="text-gray-400 text-sm mt-2">
              {t("communityNearby.tryIncreaseRadius") || "Try increasing the search radius"}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {nearbyUsers.map((user) => {
              const avatar = userAvatarUrl(user);
              const place = nearbyPlace(user);
              return (
                <button
                  key={user._id}
                  type="button"
                  data-testid="nearby-user"
                  onClick={() => navigate(`/community/${user._id}`)}
                  className="w-full flex items-center gap-4 p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 hover:bg-white/80 hover:shadow-lg transition-all"
                >
                  <div className="relative">
                    <div className="w-14 h-14 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 overflow-hidden">
                      {avatar ? (
                        <img src={avatar} alt={user.name} className="w-full h-full object-cover" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-white text-xl font-bold">
                          {user.name ? user.name[0] : "?"}
                        </div>
                      )}
                    </div>
                    {nearbyIsOnline(user) && (
                      <div
                        data-testid="nearby-online-dot"
                        className="absolute bottom-0 end-0 w-4 h-4 bg-green-500 border-2 border-white rounded-full"
                      />
                    )}
                  </div>

                  <div className="flex-1 min-w-0 text-start">
                    <h3 className="font-semibold text-gray-800">{user.name}</h3>
                    {place && (
                      <p data-testid="nearby-place" className="text-xs text-gray-500">
                        {place}
                      </p>
                    )}
                    {user.bio && <p className="text-sm text-gray-500 line-clamp-1">{user.bio}</p>}
                    <div className="flex flex-wrap items-center gap-2 mt-1">
                      {user.native_language && (
                        <span
                          data-testid="nearby-native"
                          className="text-xs bg-blue-100 text-blue-600 px-2 py-0.5 rounded-full"
                        >
                          {user.native_language}
                        </span>
                      )}
                      {user.language_to_learn && (
                        <span
                          data-testid="nearby-learning"
                          className="text-xs bg-green-100 text-green-600 px-2 py-0.5 rounded-full"
                        >
                          {t("communityNearby.learning", { language: user.language_to_learn }) ||
                            `Learning: ${user.language_to_learn}`}
                        </span>
                      )}
                    </div>
                  </div>

                  {formatNearbyDistance(user.distance) && (
                    <div className="flex items-center gap-1 text-teal-600 font-medium">
                      <MapPin className="w-4 h-4" />
                      {formatNearbyDistance(user.distance)}
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default NearbyUsers;
```

`src/utils/locales/eng.json` — add a top-level object (next to `communityMain`):

```json
"communityNearby": {
  "title": "Nearby Users",
  "subtitle": "Find people around you",
  "back": "Back",
  "geolocationNotSupported": "Geolocation is not supported",
  "permissionDenied": "Location permission denied",
  "positionUnavailable": "Location unavailable",
  "timeout": "Location request timed out",
  "unknownError": "An error occurred",
  "gettingLocation": "Getting your location...",
  "locationRequired": "Location Required",
  "tryAgain": "Try Again",
  "searchRadius": "Search Radius",
  "usersFound_one": "{{count}} person found",
  "usersFound_other": "{{count}} people found",
  "refresh": "Refresh",
  "noUsers": "No users found nearby",
  "tryIncreaseRadius": "Try increasing the search radius",
  "learning": "Learning: {{language}}"
}
```

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false communityEndpoints NearbyUsers`
Expected: PASS (all new tests; the existing wave/count tests unchanged).

- [ ] **Step 5: Commit** (tick the `P3-COM-1` line in `docs/REMAINING_WORK.md`)

```bash
git add src/store/slices/communitySlice.ts src/components/community/NearbyUsers.tsx \
  src/components/community/NearbyUsers.test.tsx src/store/slices/communityEndpoints.test.ts \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(community): Nearby sends latitude/longitude/offset and reads the real fields

The slice sent lat/lng/page and the page passed {lat,lng}, so every Nearby
request was GET ?lat=undefined... and the server answered 400 "Valid latitude
and longitude are required". Rows were read as imageUrls/nativeLanguage
(the endpoint returns raw images and snake_case languages) and a tap went to
/user/:id, which is not a route. Photos now go through userAvatarUrl, the
online dot and city/country follow privacySettings like the app, distance
uses the app's format, and the copy moves to communityNearby.* (the old
community.nearby.* keys could never exist: "community" is a string in
eng.json, so users saw raw keys).

Still open (Phase 3 community): username search path, catalog language
filter, waves inbox, wave-cap dialog, Serious/smart/reciprocal, suggested
members, Today waved cards, dead endpoints, profile counts + blocked card,
i18n sweep + 17-locale translations.
EOF
```

---

### Task P3-COM-2: @username search uses the `/auth/users` routes (community#3)

**Files:**
- Modify: `src/store/slices/usersSlice.ts:375-388`
- Modify: `src/components/chat/NewChat.tsx:56-59` (skip under 2 characters) — **coordinate with the CHAT unit**,
  which edits `NewChat.tsx` for chat#3; this is a one-line change in the username query only.
- Test: `src/store/slices/usersEndpoints.test.ts` (append)

**Interfaces:**
- Consumes: `GET /api/v1/auth/users/search/username?q=<≥2 chars>&limit` → `{ success, count, data: User[] }` (redacted,
  blocked excluded); `GET /api/v1/auth/users/username/:username` → `{ success, data: User }` or 404. Both `protect`.
- Produces: unchanged hook names `useSearchUsersByUsernameQuery({ query, limit? })`, `useGetUserByUsernameQuery(username)`.

- [ ] **Step 1: Write the failing test** — append to `src/store/slices/usersEndpoints.test.ts`:

```ts
describe("username lookups hit the /auth/users router (community#3)", () => {
  // /api/v1/users is the userBlocks router; the username routes are mounted
  // under /api/v1/auth/users (routes/users.js:66,69). NewChat's "@handle"
  // search 404'd and showed nothing.
  it("searchUsersByUsername -> GET /api/v1/auth/users/search/username?q=", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).searchUsersByUsername.initiate({ query: "@ada lo" })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMUNITY_URL}/search/username`);
    expect(url.searchParams.get("q")).toBe("ada lo");
    expect(url.searchParams.get("limit")).toBe("20");
  });

  it("getUserByUsername -> GET /api/v1/auth/users/username/:u, @ stripped and encoded", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((usersApiSlice.endpoints as any).getUserByUsername.initiate("@ada/x"));
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMUNITY_URL}/username/ada%2Fx`);
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false usersEndpoints`
Expected: FAIL — pathnames are `/api/v1/users/search/username` and `/api/v1/users/username/ada/x`.

- [ ] **Step 3: Implement** — `src/store/slices/usersSlice.ts`, replace:

```ts
    // Get user by username (exact match)
    getUserByUsername: builder.query({
      query: (username: string) => ({
        url: `/api/v1/users/username/${username.replace('@', '')}`,
      }),
      keepUnusedDataFor: 5,
    }),

    // Search users by username (partial match)
    searchUsersByUsername: builder.query({
      query: ({ query, limit = 20 }: { query: string; limit?: number }) => ({
        url: `/api/v1/users/search/username?q=${query.replace('@', '')}&limit=${limit}`,
      }),
    }),
```

with:

```ts
    // Get user by username (exact match). The username routes live on the
    // /api/v1/auth/users router (routes/users.js:69); /api/v1/users is the
    // block router and answered 404.
    getUserByUsername: builder.query({
      query: (username: string) => ({
        url: `${COMMUNITY_URL}/username/${encodeURIComponent(username.replace(/^@/, ""))}`,
      }),
      keepUnusedDataFor: 5,
    }),

    // Search users by username (partial match, routes/users.js:66). The
    // server refuses q under 2 characters with a 400.
    searchUsersByUsername: builder.query({
      query: ({ query, limit = 20 }: { query: string; limit?: number }) => ({
        url: `${COMMUNITY_URL}/search/username`,
        params: { q: query.replace(/^@/, ""), limit: String(limit) },
      }),
    }),
```

`src/components/chat/NewChat.tsx` — replace:

```ts
    { skip: !searchByUsername || trimmedQuery.replace("@", "").length < 1 }
```

with:

```ts
    // The server 400s under 2 characters (searchUsersByUsername).
    { skip: !searchByUsername || trimmedQuery.replace("@", "").length < 2 }
```

- [ ] **Step 4: Run → PASS** (same command).

- [ ] **Step 5: Commit** (tick `P3-COM-2`)

```bash
git add src/store/slices/usersSlice.ts src/components/chat/NewChat.tsx \
  src/store/slices/usersEndpoints.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(community): @username search calls the /auth/users routes

searchUsersByUsername and getUserByUsername called /api/v1/users/..., the
block router, so every "@handle" search in New chat was a 404 and showed no
one. Both now use COMMUNITY_URL, encode the handle, and New chat waits for
the 2 characters the server requires.

Still open (Phase 3 community): catalog language filter, waves inbox,
wave-cap dialog, Serious/smart/reciprocal, suggested members, Today waved
cards, dead endpoints, profile counts + blocked card, i18n sweep +
translations.
EOF
```

---

### Task P3-COM-3: Language filter offers the whole catalog, labelled in the reader's language (community#4)

**Files:**
- Create: `src/components/community/lib/languageOptions.ts`
- Modify: `src/components/community/CommunityFilterSheet.tsx` (imports lines 1-13; the two `<select>`s at :347-372)
- Modify: `src/components/community/type.ts:25-28` (comment only; `COMMON_LANGUAGES` stays as the offline fallback)
- Test: `src/components/community/lib/languageOptions.test.ts` (new), `src/components/community/CommunityFilterSheet.test.tsx` (append)

**Interfaces:**
- Consumes: `GET /api/v1/languages` → `{ success, data: [{ code, name, nativeName, flag }] }` (public, unchanged by Phase 1);
  `stripVariant`, `toBaseIso6391` from `src/utils/languages.ts`.
- Produces: `languageOptions(catalog, locale): { value: string; label: string }[]` — `value` is the English base name
  ("Arabic" for "Arabic (Egypt)"), which the server matches by substring in its direct branch and by
  `equivalentValues` in `matchLanguage` mode, so a base name covers every variant.

- [ ] **Step 1: Write the failing tests**

Create `src/components/community/lib/languageOptions.test.ts`:

```ts
import { languageOptions } from "./languageOptions";

const CATALOG = [
  { code: "en", name: "English", nativeName: "English" },
  { code: "ko", name: "Korean", nativeName: "한국어" },
  { code: "ar", name: "Arabic", nativeName: "العربية" },
  { code: "ar-EG", name: "Arabic (Egypt)", nativeName: "العربية (مصر)" },
  { code: "uz", name: "Uzbek", nativeName: "Oʻzbek" },
  { code: "fil", name: "Filipino", nativeName: "Filipino" },
  { code: "tl", name: "Tagalog", nativeName: "Tagalog" },
  { code: "zh-CN", name: "Chinese (Simplified)", nativeName: "简体中文" },
  { code: "ase", name: "American Sign Language", nativeName: "ASL" },
];

it("offers every catalog language once, variants folded into their base", () => {
  const values = languageOptions(CATALOG, "en").map((o) => o.value);
  expect(values).toContain("Uzbek");
  expect(values).toContain("Chinese");
  expect(values.filter((v) => v === "Arabic")).toHaveLength(1);
  expect(values).not.toContain("Arabic (Egypt)");
  expect(values).not.toContain("Chinese (Simplified)");
  expect(values).toContain("American Sign Language");
});

it("keeps the English name as the value and labels it in the reader's language", () => {
  const korean = languageOptions(CATALOG, "ko").find((o) => o.value === "English");
  expect(korean).toBeDefined();
  expect(korean!.label).toBe("영어");
});

it("does not give Filipino and Tagalog the same label", () => {
  const options = languageOptions(CATALOG, "en");
  const fil = options.find((o) => o.value === "Filipino")!;
  const tl = options.find((o) => o.value === "Tagalog")!;
  expect(fil.label).not.toBe(tl.label);
});

it("accepts i18next locale ids (zh_TW) and an empty or broken catalog", () => {
  expect(languageOptions(CATALOG, "zh_TW").length).toBeGreaterThan(0);
  expect(languageOptions(undefined, "en")).toEqual([]);
  expect(languageOptions([{ code: "xx" } as any, null as any], "en")).toEqual([]);
});

it("sorts by the label in the reader's language", () => {
  const labels = languageOptions(CATALOG, "en").map((o) => o.label);
  const sorted = labels.slice().sort((a, b) => new Intl.Collator("en").compare(a, b));
  expect(labels).toEqual(sorted);
});
```

Append to `src/components/community/CommunityFilterSheet.test.tsx`:

```tsx
describe("languages come from the catalog (community#4)", () => {
  const CATALOG = [
    { code: "en", name: "English", nativeName: "English" },
    { code: "ko", name: "Korean", nativeName: "한국어" },
    { code: "uz", name: "Uzbek", nativeName: "Oʻzbek" },
    { code: "ar", name: "Arabic", nativeName: "العربية" },
    { code: "ar-EG", name: "Arabic (Egypt)", nativeName: "العربية (مصر)" },
  ];

  beforeEach(() => {
    const previous = (global as any).fetch;
    (global as any).fetch = jest.fn((input: any) => {
      const url = typeof input === "string" ? input : input?.url || "";
      if (/\/api\/v1\/languages(\?|$)/.test(url)) {
        requestedUrls.push(url);
        return Promise.resolve(
          new Response(JSON.stringify({ success: true, data: CATALOG }), {
            status: 200,
            headers: { "content-type": "application/json" },
          })
        );
      }
      return previous(input);
    });
  });

  const optionValues = (select: Element) =>
    Array.from(select.querySelectorAll("option")).map((o) => (o as HTMLOptionElement).value);

  it("offers Uzbek and one Arabic, sending the English name", async () => {
    const { container, onChange } = renderSheet();
    await waitFor(() => expect(optionValues(selects(container)[0])).toContain("Uzbek"));
    expect(optionValues(selects(container)[0]).filter((v) => v === "Arabic")).toHaveLength(1);
    expect(optionValues(selects(container)[0])).not.toContain("Arabic (Egypt)");
    fireEvent.change(selects(container)[0], { target: { value: "Uzbek" } });
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ nativeLanguage: "Uzbek" }));
  });

  it("keeps a value from an old link that the catalog no longer lists", async () => {
    const { container } = renderSheet({ ...DEFAULT_FILTERS, learningLanguage: "Klingon" });
    await waitFor(() => expect(optionValues(selects(container)[1])).toContain("Uzbek"));
    expect(optionValues(selects(container)[1])).toContain("Klingon");
  });
});
```

(`selects(container)` is the helper the file already uses at :149; if it is declared inside another `describe`,
move it to module scope in this step.)

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false languageOptions CommunityFilterSheet`
Expected: FAIL — `languageOptions` module not found; the sheet never offers "Uzbek".

- [ ] **Step 3: Implement**

Create `src/components/community/lib/languageOptions.ts`:

```ts
import { stripVariant, toBaseIso6391 } from "../../../utils/languages";

/** One row of GET /api/v1/languages (models/Language.js). */
export interface CatalogLanguage {
  code?: string;
  name?: string;
  nativeName?: string;
}

export interface LanguageOption {
  /** English base name — what the server stores and matches. */
  value: string;
  /** Shown to the reader, in their UI language. */
  label: string;
}

function languageNamer(locale: string): ((code: string) => string | undefined) | null {
  try {
    const names = new (Intl as any).DisplayNames([locale], { type: "language" });
    return (code: string) => {
      try {
        return names.of(code);
      } catch (e) {
        return undefined;
      }
    };
  } catch (e) {
    return null;
  }
}

/**
 * The filter's language list, built from the shared catalog the app uses
 * (filter_languages_section.dart reads the same GET /languages).
 *
 * - Variants fold into their base ("Arabic (Egypt)" -> "Arabic"): the server
 *   matches the base name against every variant, and four Arabics in a
 *   dropdown answer a question nobody asked.
 * - The value is always the English name (what users store); the label is
 *   the language's name in the reader's locale via Intl.DisplayNames. A code
 *   with no hyphen is looked up as is ("fil" is Filipino, not Tagalog); a
 *   hyphenated variant by its base. When Intl has no name it echoes the
 *   code, and the English name is used instead.
 */
export function languageOptions(
  catalog: CatalogLanguage[] | undefined | null,
  rawLocale: string = "en"
): LanguageOption[] {
  // i18next ids use underscores (zh_TW); Intl throws on them.
  const locale = (rawLocale || "en").replace(/_/g, "-");
  const named = languageNamer(locale);
  const seen: Record<string, boolean> = {};
  const options: LanguageOption[] = [];

  (Array.isArray(catalog) ? catalog : []).forEach((entry) => {
    const name = entry && typeof entry.name === "string" ? entry.name.trim() : "";
    if (!name) return;
    const value = stripVariant(name);
    if (!value || seen[value]) return;
    seen[value] = true;

    const code = entry && typeof entry.code === "string" ? entry.code.trim() : "";
    const lookup = code.indexOf("-") > 0 ? toBaseIso6391(code) : code;
    const local = lookup && named ? named(lookup) : undefined;
    const label =
      local && local.toLowerCase() !== String(lookup).toLowerCase() ? local : value;
    options.push({ value, label });
  });

  let collator: Intl.Collator;
  try {
    collator = new Intl.Collator(locale);
  } catch (e) {
    collator = new Intl.Collator("en");
  }
  return options.sort((a, b) => collator.compare(a.label, b.label));
}
```

`src/components/community/CommunityFilterSheet.tsx`:

Replace the import block lines 6 and 10-13:

```ts
import { COMMON_LANGUAGES } from "./type";
```
→
```ts
import { COMMON_LANGUAGES } from "./type";
import { languageOptions, LanguageOption } from "./lib/languageOptions";
```
and
```ts
import {
  useGetCommunityCountQuery,
  useGetTopicsQuery,
} from "../../store/slices/communitySlice";
```
→
```ts
import {
  useGetCommunityCountQuery,
  useGetLanguagesQuery,
  useGetTopicsQuery,
} from "../../store/slices/communitySlice";
```

After `const countries = useMemo(() => countryOptions(uiLocale), [uiLocale]);` (line 129) add:

```ts
  // The whole catalog (GET /languages, the list the app filters on), labelled
  // in the reader's language. Until it arrives — or if it fails — the ten
  // common languages keep the filter usable rather than empty.
  const { data: languagesResult } = useGetLanguagesQuery(undefined, { skip: !open });
  const catalogLanguages = useMemo<LanguageOption[]>(() => {
    const built = languageOptions(languagesResult && languagesResult.data, uiLocale);
    if (built.length > 0) return built;
    return COMMON_LANGUAGES.map((name) => ({ value: name as string, label: name as string }));
  }, [languagesResult, uiLocale]);

  /** The list, plus a value from an old link or saved filter it no longer has. */
  const languageChoices = (current?: string): LanguageOption[] =>
    current && !catalogLanguages.some((option) => option.value === current)
      ? [{ value: current, label: current }].concat(catalogLanguages)
      : catalogLanguages;
```

Replace both option loops (`:352-356` and `:369-373`):

```tsx
                  {COMMON_LANGUAGES.map((lang) => (
                    <option key={lang} value={lang}>
                      {lang}
                    </option>
                  ))}
```

first occurrence (native select) with:

```tsx
                  {languageChoices(value.nativeLanguage).map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
```

second occurrence (learning select) with:

```tsx
                  {languageChoices(value.learningLanguage).map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
```

`src/components/community/type.ts` — replace:

```ts
export const COMMON_LANGUAGES = [
```
with:
```ts
// Offline fallback only: the filter sheet lists the whole GET /languages
// catalog (lib/languageOptions.ts) and falls back to these while it loads.
export const COMMON_LANGUAGES = [
```

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false languageOptions CommunityFilterSheet languageMigration`
Expected: PASS. The existing "Korean"/"English" select tests still pass on the fallback list (their fetch mock answers
`/languages` with `data: []`).

- [ ] **Step 5: Commit** (tick `P3-COM-3`)

```bash
git add src/components/community/lib/languageOptions.ts src/components/community/lib/languageOptions.test.ts \
  src/components/community/CommunityFilterSheet.tsx src/components/community/CommunityFilterSheet.test.tsx \
  src/components/community/type.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(community): language filter lists the whole catalog, localized

The filter offered ten hard-coded English names, so Arabic, Uzbek,
Vietnamese and every other catalog language could not be filtered (58% of
learners target a non-English language). Options now come from
GET /languages like the app, variants fold into their base name (the
server matches the base against every variant), the label is the
language's name in the reader's locale, and the value stays the English
name the server stores. The ten common names remain the offline fallback;
a value from an old link is kept.

Still open (Phase 3 community): waves inbox, wave-cap dialog,
Serious/smart/reciprocal, suggested members, Today waved cards, dead
endpoints, profile counts + blocked card, i18n sweep + translations.
EOF
```

---

### Task P3-COM-4: Waves inbox — archive, reveal, loadable avatars, a real "Find people" route (community#10)

**Files:**
- Modify: `src/store/slices/communitySlice.ts:184-197` (`getWaves` gains `reveal`)
- Modify (rewrite): `src/components/community/Waves.tsx`
- Modify: `src/utils/locales/eng.json` (`waves.*`)
- Test: `src/components/community/Waves.test.tsx` (new), `src/store/slices/communityEndpoints.test.ts` (append)

**Interfaces:**
- Consumes: `GET /api/v1/community/waves?page&limit[&archive=true][&reveal=1]` → `{ data: { waves: [{ waveId, from:
  { _id, name, images }, message, createdAt, isRead, revealed? }], unreadCount, maskedCount? }, pagination: { hasMore } }`;
  `PUT /community/waves/read`; `GET /api/v1/app-config` → `boostsEnabled` (the app sends `reveal` only while it is on,
  `waves_tab.dart:63-67`).
- Produces: `getWaves({ page?, limit?, unreadOnly?, archive?, reveal? })`; `waveAvatarUrl(user)` exported from `Waves.tsx`.

- [ ] **Step 1: Write the failing tests**

Append to `src/store/slices/communityEndpoints.test.ts`:

```ts
describe("getWaves archive + reveal (community#10)", () => {
  it("sends archive=true and reveal=1 only when asked", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getWaves.initiate({ page: 1, limit: 20, archive: true, reveal: true })
    );
    const url = new URL(calls[0].url);
    expect(url.searchParams.get("archive")).toBe("true");
    expect(url.searchParams.get("reveal")).toBe("1");

    await store.dispatch((communityApiSlice.endpoints as any).getWaves.initiate({ page: 2, limit: 20 }));
    const plain = new URL(calls[1].url);
    expect(plain.searchParams.get("archive")).toBeNull();
    expect(plain.searchParams.get("reveal")).toBeNull();
  });
});
```

Create `src/components/community/Waves.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import {
  createMemoryRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from "react-router-dom";
import { makeStore } from "../../store";
import Waves, { waveAvatarUrl } from "./Waves";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, o?: any) => (o ? `${key} ${Object.values(o).join(" ")}` : key),
  }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const wave = (id: string, name: string, extra: any = {}) => ({
  waveId: id,
  from: { _id: `from-${id}`, name, images: [`users/${id}.jpg`] },
  message: "",
  createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
  isRead: true,
  ...extra,
});

let recent: any[] = [];
let archived: any[] = [];
let unread = 0;
let boostsEnabled = false;
const requests: { url: string; method: string }[] = [];
const originalFetch = global.fetch;

beforeEach(() => {
  recent = [wave("w1", "Ada")];
  archived = [wave("w9", "Old Bob")];
  unread = 0;
  boostsEnabled = false;
  requests.length = 0;
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    const method = (input && input.method) || "GET";
    requests.push({ url, method });
    let body: any = { success: true, data: [] };
    if (url.indexOf("/app-config") >= 0) {
      body = { success: true, data: { boostsEnabled } };
    } else if (url.indexOf("/community/waves/read") >= 0) {
      body = { success: true };
    } else if (url.indexOf("/community/waves") >= 0) {
      const isArchive = url.indexOf("archive=true") >= 0;
      body = {
        success: true,
        data: { waves: isArchive ? archived : recent, unreadCount: unread },
        pagination: { total: 1, page: 1, limit: 20, hasMore: false },
      };
    }
    return Promise.resolve(
      new Response(JSON.stringify(body), { status: 200, headers: { "content-type": "application/json" } })
    );
  });
});

afterEach(() => {
  global.fetch = originalFetch;
});

const SIGNED_IN = { auth: { userInfo: { user: { _id: "u1" }, token: "t" } } };

function renderWaves() {
  const router = createMemoryRouter(
    createRoutesFromElements(
      <Route path="/">
        <Route path="waves" element={<Waves />} />
        <Route path="communities" element={<div data-testid="communities-screen" />} />
        <Route path="community/:userId" element={<div data-testid="profile-screen" />} />
      </Route>
    ),
    { initialEntries: ["/waves"] }
  );
  render(
    <Provider store={makeStore(SIGNED_IN)}>
      <RouterProvider router={router} />
    </Provider>
  );
  return router;
}

const waveRequests = () =>
  requests.filter((r) => r.url.indexOf("/community/waves") >= 0 && r.url.indexOf("/read") < 0);

describe("waves inbox (community#10)", () => {
  it("loads the sender's photo from the raw storage path", async () => {
    renderWaves();
    const img = await screen.findByAltText("Ada");
    expect(img).toHaveAttribute("src", "http://localhost:5003/uploads/users/w1.jpg");
  });

  it("switches to the 7-30 day archive with archive=true", async () => {
    renderWaves();
    await screen.findByText("Ada");
    fireEvent.click(screen.getByTestId("waves-archive-toggle"));
    expect(await screen.findByText("Old Bob")).toBeInTheDocument();
    expect(screen.queryByText("Ada")).not.toBeInTheDocument();
    const last = waveRequests()[waveRequests().length - 1].url;
    expect(last).toContain("archive=true");
  });

  it("asks with reveal=1 only while boostsEnabled is on, as the app does", async () => {
    boostsEnabled = true;
    renderWaves();
    await screen.findByText("Ada");
    expect(waveRequests().every((r) => r.url.indexOf("reveal=1") >= 0)).toBe(true);
  });

  it("sends no reveal while the flag is off", async () => {
    renderWaves();
    await screen.findByText("Ada");
    expect(waveRequests().some((r) => r.url.indexOf("reveal=") >= 0)).toBe(false);
  });

  it("marks unread waves read from the recent list", async () => {
    unread = 1;
    renderWaves();
    await screen.findByText("Ada");
    await waitFor(() =>
      expect(requests.some((r) => r.url.indexOf("/community/waves/read") >= 0 && r.method === "PUT")).toBe(true)
    );
  });

  it("sends 'Find people' to /communities, which is a real route", async () => {
    recent = [];
    const router = renderWaves();
    fireEvent.click(await screen.findByText("waves.findPeople"));
    await waitFor(() => expect(router.state.location.pathname).toBe("/communities"));
  });

  it("builds avatars from imageUrls, raw paths and legacy {url} objects", () => {
    expect(waveAvatarUrl({ _id: "a", name: "a", imageUrls: ["https://cdn/x.jpg"] })).toBe("https://cdn/x.jpg");
    expect(waveAvatarUrl({ _id: "a", name: "a", images: ["users/a.jpg"] })).toBe(
      "http://localhost:5003/uploads/users/a.jpg"
    );
    expect(waveAvatarUrl({ _id: "a", name: "a", images: [{ url: "https://cdn/y.jpg" }] })).toBe(
      "https://cdn/y.jpg"
    );
    expect(waveAvatarUrl(null)).toBeUndefined();
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false communityEndpoints Waves.test`
Expected: FAIL — `waveAvatarUrl` not exported, no `waves-archive-toggle`, img src is the raw path, the button
navigates to `/community`.

- [ ] **Step 3: Implement**

`src/store/slices/communitySlice.ts` — replace the `getWaves` query:

```ts
    getWaves: builder.query({
      query: ({ page = 1, limit = 20, unreadOnly, archive }: {
        page?: number;
        limit?: number;
        unreadOnly?: boolean;
        archive?: boolean;
      } = {}) => {
        let url = `${COMMUNITY_WAVES_LIST}?page=${page}&limit=${limit}`;
        if (unreadOnly) url += `&unreadOnly=${unreadOnly}`;
        if (archive) url += `&archive=${archive}`;
        return { url };
      },
```

with:

```ts
    getWaves: builder.query({
      query: ({ page = 1, limit = 20, unreadOnly, archive, reveal }: {
        page?: number;
        limit?: number;
        unreadOnly?: boolean;
        /** 7-30 days old (the main list is the last 7 days). */
        archive?: boolean;
        /** ?reveal=1 — the app sends it while appConfig.boostsEnabled is on. */
        reveal?: boolean;
      } = {}) => {
        let url = `${COMMUNITY_WAVES_LIST}?page=${page}&limit=${limit}`;
        if (unreadOnly) url += `&unreadOnly=${unreadOnly}`;
        if (archive) url += `&archive=true`;
        if (reveal) url += `&reveal=1`;
        return { url };
      },
```

Replace `src/components/community/Waves.tsx` with:

```tsx
import React, { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ArrowLeft, Hand, History, Loader2 } from "lucide-react";
import {
  useGetWavesQuery,
  useMarkWavesReadMutation,
} from "../../store/slices/communitySlice";
import { useGetAppConfigQuery } from "../../store/slices/appConfigSlice";
import { photoUrl } from "../../utils/photoUrl";
import { timeAgo } from "../../utils/timeAgo";

/**
 * GET /api/v1/community/waves (controllers/community.js getWaves):
 *   { waveId, from: { _id, name, images }, message, createdAt, isRead, revealed? }
 * `from` is populated with `name images` only — raw storage paths, never
 * `imageUrls` — and is null when the sender's account is gone.
 */
interface WaveFromUser {
  _id: string;
  name: string;
  images?: Array<string | { url?: string; imageUrl?: string }>;
  imageUrls?: string[];
}

interface WaveItem {
  waveId: string;
  from: WaveFromUser | null;
  message?: string;
  createdAt: string;
  isRead: boolean;
}

const PAGE_LIMIT = 20;

/**
 * The sender's photo as a URL a browser can load. The old code put the raw
 * storage path ("users/x.jpg") straight into <img src>, a broken image for
 * every app user. Legacy rows carrying `{url}` objects still work.
 */
export function waveAvatarUrl(user?: WaveFromUser | null): string | undefined {
  if (!user) return undefined;
  const built = (user.imageUrls || []).find((u) => typeof u === "string" && u.trim());
  if (built) return built;
  const paths = (user.images || [])
    .map((image) =>
      typeof image === "string" ? image : (image && (image.url || image.imageUrl)) || ""
    )
    .filter((image) => Boolean(image));
  return photoUrl(paths);
}

const Waves: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  /** false = the last 7 days; true = 7-30 days (the app's "View archive"). */
  const [archive, setArchive] = useState(false);
  const [page, setPage] = useState(1);
  // RTK Query caches each {page, archive} as its own entry and does not merge
  // them, so "Load more" keeps its own running list, deduped by waveId.
  const [accumulatedWaves, setAccumulatedWaves] = useState<WaveItem[]>([]);

  // The app sends ?reveal=1 only while boostsEnabled is on (waves_tab.dart).
  // Waiting for the config keeps it to one request, not one without and one
  // with; a failed config read counts as "off".
  const { data: appConfig, isLoading: configLoading } = useGetAppConfigQuery();
  const reveal = Boolean(appConfig && (appConfig as any).boostsEnabled);

  // currentData, not data: after the archive switch `data` still holds the
  // other list until the new one lands, and would be merged into it.
  const { currentData, isLoading, isFetching } = useGetWavesQuery(
    {
      page,
      limit: PAGE_LIMIT,
      archive: archive || undefined,
      reveal: reveal || undefined,
    },
    { skip: configLoading }
  );
  const data: any = currentData;
  const [markWavesRead] = useMarkWavesReadMutation();

  const unreadCount: number = (data && data.data && data.data.unreadCount) || 0;

  useEffect(() => {
    if (!data) return;
    const fetchedWaves: WaveItem[] = (data.data && data.data.waves) || [];
    if (page === 1) {
      setAccumulatedWaves(fetchedWaves);
      return;
    }
    setAccumulatedWaves((prev) => {
      const seen = new Set(prev.map((w) => w.waveId));
      const newOnes = fetchedWaves.filter((w) => !seen.has(w.waveId));
      return newOnes.length ? prev.concat(newOnes) : prev;
    });
  }, [data, page]);

  const lastPageWaves: WaveItem[] = (data && data.data && data.data.waves) || [];
  const hasMore =
    (data && data.pagination && data.pagination.hasMore) ??
    (lastPageWaves.length > 0 && lastPageWaves.length === PAGE_LIMIT);

  // Opening the recent list marks every unread wave read (no ids = all), as
  // the app does after a successful load. The archive never does.
  useEffect(() => {
    if (!archive && data && unreadCount > 0) {
      markWavesRead(undefined).catch(() => {
        /* best-effort — the badge clears on the next load */
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [archive, Boolean(data), unreadCount > 0]);

  const handleLoadMore = useCallback(() => {
    if (!isFetching) setPage((p) => p + 1);
  }, [isFetching]);

  const switchList = () => {
    setArchive((was) => !was);
    setPage(1);
    setAccumulatedWaves([]);
  };

  const loading = configLoading || isLoading || (!data && isFetching);

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] text-white px-5 py-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-full transition-colors"
            aria-label={t("waves.back") || "Back"}
          >
            <ArrowLeft className="w-6 h-6 rtl:rotate-180" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold flex items-center gap-2">
              <Hand className="w-6 h-6" />
              {t("waves.title") || "Waves"}
            </h1>
            <p className="text-teal-50 text-sm">
              {archive
                ? t("waves.archiveHint") || "Waves from 7 to 30 days ago"
                : t("waves.subtitle") || "People who waved at you"}
            </p>
          </div>
          {!archive && unreadCount > 0 && (
            <div
              data-testid="waves-unread-badge"
              className="bg-white text-teal-600 font-bold rounded-full min-w-[2rem] h-8 px-2 flex items-center justify-center"
            >
              {unreadCount}
            </div>
          )}
        </div>
      </div>

      <div className="px-4 py-6 max-w-2xl mx-auto">
        <div className="flex justify-end pb-3">
          <button
            type="button"
            data-testid="waves-archive-toggle"
            aria-pressed={archive}
            onClick={switchList}
            className="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm font-medium text-teal-700 hover:bg-teal-50 transition-colors"
          >
            <History className="w-4 h-4" aria-hidden />
            {archive ? t("waves.recent") || "Last 7 days" : t("waves.archive") || "Older waves"}
          </button>
        </div>

        {loading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
          </div>
        ) : accumulatedWaves.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-teal-50 w-fit mx-auto mb-4">
              <Hand className="w-8 h-8 text-teal-500" />
            </div>
            <p className="text-gray-500">
              {archive
                ? t("waves.archiveEmpty") || "No older waves"
                : t("waves.noReceived") || "No waves received yet"}
            </p>
            <button
              type="button"
              onClick={() => navigate("/communities")}
              className="mt-4 px-6 py-3 bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] text-white rounded-full font-semibold hover:shadow-lg transition-all"
            >
              {t("waves.findPeople") || "Find People"}
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {accumulatedWaves.map((wave) => {
              const avatar = waveAvatarUrl(wave.from);
              const name = (wave.from && wave.from.name) || t("waves.someone") || "Someone";
              return (
                <div
                  key={wave.waveId}
                  data-testid="wave-item"
                  onClick={() => wave.from && wave.from._id && navigate(`/community/${wave.from._id}`)}
                  className={`flex items-start gap-3 rounded-2xl p-4 shadow-sm border cursor-pointer transition-colors ${
                    wave.isRead ? "bg-white border-gray-100" : "bg-teal-50/70 border-teal-200"
                  }`}
                >
                  <div className="w-12 h-12 rounded-full overflow-hidden bg-gradient-to-br from-teal-100 to-cyan-50 shrink-0 flex items-center justify-center">
                    {avatar ? (
                      <img src={avatar} alt={name} className="w-full h-full object-cover" />
                    ) : (
                      <span className="text-lg font-semibold text-teal-600">
                        {name ? name[0].toUpperCase() : "?"}
                      </span>
                    )}
                  </div>
                  <div className="flex-1 min-w-0 text-start">
                    <div className="flex items-center justify-between gap-2">
                      <h3 className="font-semibold text-gray-800 truncate">{name}</h3>
                      <span className="text-xs text-gray-400 shrink-0">
                        {timeAgo(wave.createdAt, t, { withAgo: true })}
                      </span>
                    </div>
                    <p className="text-gray-600 text-sm mt-0.5">
                      {(wave.message && wave.message.trim()) || t("waves.wavedAtYou") || "Waved at you 👋"}
                    </p>
                  </div>
                  {!wave.isRead && (
                    <span
                      data-testid="wave-item-unread-dot"
                      className="w-2.5 h-2.5 rounded-full bg-teal-500 shrink-0 mt-1.5"
                      aria-label={t("waves.unread") || "Unread"}
                    />
                  )}
                </div>
              );
            })}

            {hasMore && (
              <div className="flex justify-center pt-2">
                <button
                  type="button"
                  onClick={handleLoadMore}
                  disabled={isFetching}
                  className="px-6 py-2.5 rounded-full bg-gray-100 text-gray-700 font-medium hover:bg-gray-200 transition-colors disabled:opacity-50"
                >
                  {isFetching
                    ? t("communityMain.loadMore.loading") || "Loading..."
                    : t("communityMain.loadMore.button") || "Load more"}
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default Waves;
```

`src/utils/locales/eng.json` — extend the existing top-level `waves` object (keep its current keys):

```json
"subtitle": "People who waved at you",
"back": "Back",
"noReceived": "No waves received yet",
"findPeople": "Find People",
"archive": "Older waves",
"recent": "Last 7 days",
"archiveHint": "Waves from 7 to 30 days ago",
"archiveEmpty": "No older waves",
"someone": "Someone",
"wavedAtYou": "Waved at you 👋",
"unread": "Unread"
```

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false communityEndpoints Waves.test`
Expected: PASS.

- [ ] **Step 5: Commit** (tick `P3-COM-4`)

```bash
git add src/store/slices/communitySlice.ts src/components/community/Waves.tsx \
  src/components/community/Waves.test.tsx src/store/slices/communityEndpoints.test.ts \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(community): waves archive, reveal flag, real avatars and route

Waves 7-30 days old could not be reached on the web (the server's
?archive=true list), avatars used raw storage paths (broken for app users),
and the empty state's "Find People" went to /community, which is not a
route. The inbox now has an archive switch, sends ?reveal=1 while
boostsEnabled is on like the app, builds avatars with photoUrl, uses the
shared timeAgo, and its copy moves from the unreachable community.waves.*
keys to waves.*.

Still open (Phase 3 community): wave-cap dialog, Serious/smart/reciprocal,
suggested members, Today waved cards, dead endpoints, profile counts +
blocked card, i18n sweep + translations.
EOF
```

---

### Task P3-COM-5: Wave cap answers with a VIP dialog, not a raw English toast (community#8)

**Files:**
- Modify: `src/components/community/WaveSheet.tsx` (imports, state, `handleSend` catch, render)
- Modify: `src/utils/locales/eng.json` (`waves.cap.*`)
- Test: `src/components/community/WaveSheet.test.tsx` (render helper + new cases)

**Interfaces:**
- Consumes: `POST /api/v1/community/wave` → `429 { success:false, error:"Daily wave limit reached (N). …", code:"wave_cap" }`
  from `checkWaveLimit` (middleware/checkLimitations.js:297-303) or `sendWave` (controllers/community.js:309-315).
  Both run only while `WAVE_CAP_ENABLED` is on, so `code === 'wave_cap'` alone is the switch. **Deviation from the
  brief:** the sheet does not read `appConfig.waveCapEnabled`. The app reads it to stop the route's rate limiter (a
  429 with no code) from opening the dialog; the code check already does that, and reading app-config inside
  `WaveSheet` would add a query hook to every surface that mounts it (ProfilePage, SuggestedMembers, MainCommunity),
  whose tests mock the slices without an API store.
- Produces: unchanged `WaveSheetProps` (P3-COM-9 adds `onWaved`). The web has no coin/rewarded unlock, so the
  dialog's action is "See VIP" → `/settings/vip` (the only VIP page on the web).

- [ ] **Step 1: Write the failing test** — replace `src/components/community/WaveSheet.test.tsx` with:

```tsx
import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import WaveSheet from "./WaveSheet";

const mockSendWave = jest.fn();
const mockNavigate = jest.fn();
const mockToastError = jest.fn();
let mockIsLoading = false;

jest.mock("react-toastify", () => ({
  toast: { success: jest.fn(), error: (...args: any[]) => mockToastError(...args) },
  Bounce: {},
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../store/slices/communitySlice", () => ({
  useSendWaveMutation: () => [
    mockSendWave,
    { isLoading: mockIsLoading },
  ],
}));

const targetUser = { _id: "user-2", name: "Bob", imageUrls: ["https://example.com/bob.jpg"] };

function renderSheet(props: any = {}) {
  return render(
    <MemoryRouter>
      <WaveSheet open={true} targetUser={targetUser} onClose={jest.fn()} {...props} />
    </MemoryRouter>
  );
}

const rejectWith = (status: number, data: any) =>
  mockSendWave.mockReturnValue({ unwrap: () => Promise.reject({ status, data }) });

describe("WaveSheet", () => {
  beforeEach(() => {
    mockSendWave.mockReset();
    mockNavigate.mockReset();
    mockToastError.mockReset();
    mockIsLoading = false;
  });

  it("renders nothing when closed", () => {
    renderSheet({ open: false });
    expect(screen.queryByTestId("wave-sheet")).not.toBeInTheDocument();
  });

  it("renders the title with the target user's name", () => {
    renderSheet();
    expect(screen.getByText("Send a wave to Bob")).toBeInTheDocument();
  });

  it("sends a wave with the composed message when Send is clicked", async () => {
    mockSendWave.mockReturnValue({
      unwrap: () => Promise.resolve({ success: true, data: { waveId: "w1", isMutual: false, message: "Wave sent!" } }),
    });
    const onClose = jest.fn();
    renderSheet({ onClose });

    fireEvent.click(screen.getByText("👋"));
    fireEvent.click(screen.getByTestId("wave-sheet-send"));

    await waitFor(() => expect(mockSendWave).toHaveBeenCalledWith({
      targetUserId: "user-2",
      message: "👋 Hi!",
    }));
    await waitFor(() => expect(onClose).toHaveBeenCalled());
  });

  it("shows an already-waved state and disables Send on ALREADY_WAVED", async () => {
    rejectWith(400, { success: false, error: "already waved", code: "ALREADY_WAVED" });
    renderSheet();

    fireEvent.click(screen.getByTestId("wave-sheet-send"));

    await waitFor(() =>
      expect(screen.getByText("You already waved at Bob")).toBeInTheDocument()
    );
    expect(screen.getByTestId("wave-sheet-send")).toBeDisabled();
  });

  describe("the daily cap (community#8)", () => {
    it("opens the VIP dialog instead of a toast on 429 wave_cap", async () => {
      rejectWith(429, {
        success: false,
        error: "Daily wave limit reached (5). Upgrade to VIP for unlimited waves.",
        code: "wave_cap",
      });
      renderSheet();
      fireEvent.click(screen.getByTestId("wave-sheet-send"));

      expect(await screen.findByText("Daily wave limit reached")).toBeInTheDocument();
      expect(mockToastError).not.toHaveBeenCalled();
      expect(screen.queryByTestId("wave-sheet")).not.toBeInTheDocument();
    });

    it("See VIP closes the sheet and opens the VIP page", async () => {
      rejectWith(429, { success: false, error: "cap", code: "wave_cap" });
      const onClose = jest.fn();
      renderSheet({ onClose });
      fireEvent.click(screen.getByTestId("wave-sheet-send"));
      fireEvent.click(await screen.findByTestId("confirm-dialog-confirm"));

      expect(onClose).toHaveBeenCalled();
      expect(mockNavigate).toHaveBeenCalledWith("/settings/vip");
    });

    it("Not now just closes", async () => {
      rejectWith(429, { success: false, error: "cap", code: "wave_cap" });
      const onClose = jest.fn();
      renderSheet({ onClose });
      fireEvent.click(screen.getByTestId("wave-sheet-send"));
      fireEvent.click(await screen.findByTestId("confirm-dialog-cancel"));

      expect(onClose).toHaveBeenCalled();
      expect(mockNavigate).not.toHaveBeenCalled();
    });

    it("keeps the plain toast for a 429 without the code (the rate limiter)", async () => {
      rejectWith(429, { success: false, error: "Too many requests" });
      renderSheet();
      fireEvent.click(screen.getByTestId("wave-sheet-send"));

      await waitFor(() => expect(mockToastError).toHaveBeenCalled());
      expect(screen.queryByText("Daily wave limit reached")).not.toBeInTheDocument();
    });
  });
});
```

(These copy assertions are the English fallbacks; P3-COM-13 adds an i18n mock that resolves from `eng.json` and keeps
them green.)

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false WaveSheet`
Expected: the four existing tests still PASS (now wrapped in a router); the three cap tests FAIL (a toast fires, no
dialog). If the first two existing tests FAIL because `t` returns the key, P3-COM-13 has not landed yet — that is
fine; they still use hardcoded English here.

- [ ] **Step 3: Implement** — `src/components/community/WaveSheet.tsx`:

Replace the imports:

```ts
import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { X, Loader2, PartyPopper, Hand } from "lucide-react";
import { Bounce, toast } from "react-toastify";
import { useSendWaveMutation } from "../../store/slices/communitySlice";
```

with:

```ts
import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { X, Loader2, PartyPopper, Hand } from "lucide-react";
import { Bounce, toast } from "react-toastify";
import { useSendWaveMutation } from "../../store/slices/communitySlice";
import ConfirmDialog from "../../design/ConfirmDialog";

/** Body code of the daily wave-cap 429 (checkLimitations.js checkWaveLimit). */
const WAVE_CAP_CODE = "wave_cap";
const VIP_PAGE = "/settings/vip";
```

Replace:

```ts
  const { t } = useTranslation();
  const [message, setMessage] = useState("");
  const [alreadyWaved, setAlreadyWaved] = useState(false);
  const [sendWave, { isLoading }] = useSendWaveMutation();

  // Reset local state every time the sheet opens for a (possibly new) target.
  useEffect(() => {
    if (open) {
      setMessage("");
      setAlreadyWaved(false);
    }
  }, [open, targetUser?._id]);
```

with:

```ts
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [message, setMessage] = useState("");
  const [alreadyWaved, setAlreadyWaved] = useState(false);
  // The daily cap was hit: the sheet turns into the VIP dialog.
  const [capReached, setCapReached] = useState(false);
  const [sendWave, { isLoading }] = useSendWaveMutation();

  // Reset local state every time the sheet opens for a (possibly new) target.
  useEffect(() => {
    if (open) {
      setMessage("");
      setAlreadyWaved(false);
      setCapReached(false);
    }
  }, [open, targetUser?._id]);
```

In `handleSend`'s catch, replace:

```ts
      const code = err?.data?.code;
      if (code === "ALREADY_WAVED") {
        setAlreadyWaved(true);
        return;
      }
```

with:

```ts
      const code = err?.data?.code;
      if (code === "ALREADY_WAVED") {
        setAlreadyWaved(true);
        return;
      }
      // The daily cap. The server answers 429 with this code only while
      // WAVE_CAP_ENABLED is on; the route's rate limiter sends a 429 with no
      // code and keeps the plain toast below (the app's waveErrorAction).
      if (err?.status === 429 && code === WAVE_CAP_CODE) {
        setCapReached(true);
        return;
      }
```

After `const avatar = targetUser.imageUrls?.[0];` add:

```tsx
  if (capReached) {
    return (
      <ConfirmDialog
        open
        title={t("waves.cap.title") || "Daily wave limit reached"}
        body={
          t("waves.cap.body") ||
          "You've used today's free waves. VIP members can wave without a daily limit, or try again tomorrow."
        }
        confirmLabel={t("waves.cap.seeVip") || "See VIP"}
        cancelLabel={t("waves.cap.notNow") || "Not now"}
        onConfirm={() => {
          onClose();
          navigate(VIP_PAGE);
        }}
        onCancel={onClose}
      />
    );
  }
```

`src/utils/locales/eng.json` — inside the `waves` object add:

```json
"cap": {
  "title": "Daily wave limit reached",
  "body": "You've used today's free waves. VIP members can wave without a daily limit, or try again tomorrow.",
  "seeVip": "See VIP",
  "notNow": "Not now"
}
```

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false WaveSheet MainCommunity SuggestedMembers ProfilePage`
Expected: PASS (the surfaces that mount `WaveSheet` all render inside a router already).

- [ ] **Step 5: Commit** (tick `P3-COM-5`)

```bash
git add src/components/community/WaveSheet.tsx src/components/community/WaveSheet.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(community): wave cap opens a VIP dialog instead of a raw toast

A 429 wave_cap showed the server's English sentence in a toast. It now
opens a localized dialog with a See VIP action (/settings/vip), as the app
opens LimitExceededDialog. Only the wave_cap code opens it: the server
sends it only while WAVE_CAP_ENABLED is on, and a rate-limiter 429 keeps
the plain toast. The web has no coin/rewarded unlock, so VIP is the only
offer.

Still open (Phase 3 community): Serious/smart/reciprocal, suggested
members, Today waved cards, dead endpoints, profile counts + blocked card,
i18n sweep + translations; coin unlock for waves on web (no coins UI yet).
EOF
```

---

### Task P3-COM-6: "Serious learners" segment tab (`activeWithin=7d`) (community#9)

**Files:**
- Modify: `src/components/community/lib/buildCommunityQuery.ts` (`CommunityFilters` + mapper)
- Modify: `src/components/community/lib/communityUrlState.ts:33-40, 82-90` (tab type + list)
- Modify: `src/components/community/tandem/CommunitySubNav.tsx:26-67` (tab type + entry)
- Modify: `src/components/community/MainCommunity.tsx:272-276` (`effectiveFilters`), `:877` (`lockedTab`), segment hint
- Modify: `src/components/community/CommunityFilterSheet.tsx:69, 148-152` (`lockedTab` accepts `serious`)
- Modify: `src/utils/locales/eng.json` (`communityMain.tabs.serious`, `communityMain.tabs.seriousHint`)
- Test: `buildCommunityQuery.test.ts`, `communityUrlState.test.ts`, `tandem/CommunitySubNav.test.tsx`, `MainCommunityTabs.test.tsx`

**Interfaces:**
- Consumes: `GET /auth/users?activeWithin=7d` (controllers/users.js:218-229: `lastActive ≥ now-7d`, hides people who
  hide their online status). Old servers ignore the param.
- Produces: `CommunityFilters.activeWithin?: '7d'`; `CommunityNavTab`/`CommunityUrlTab` gain `'serious'`; the filter
  sheet's `lockedTab?: "online" | "new" | "serious"`.

- [ ] **Step 1: Write the failing tests**

Append to `src/components/community/lib/buildCommunityQuery.test.ts`:

```ts
it('Serious learners -> activeWithin=7d (the app PartnerSegment.serious)', () => {
  const q = buildCommunityQuery({ activeWithin: '7d' }, me, 1, 20);
  expect(q.activeWithin).toBe('7d');
  expect(buildCommunityQuery({}, me, 1, 20).activeWithin).toBeUndefined();
});
```

Append to `src/components/community/lib/communityUrlState.test.ts` (inside the top-level `describe`):

```ts
  describe('the serious tab', () => {
    it('round-trips ?tab=serious', () => {
      expect(decodeCommunityState(params('tab=serious')).tab).toBe('serious');
      expect(
        encodeCommunityState({ filters: {}, search: '', tab: 'serious' }).toString()
      ).toBe('tab=serious');
    });
  });
```

In `src/components/community/tandem/CommunitySubNav.test.tsx`, update the order test's expectation:

```ts
    expect(tabs.map((tab) => tab.textContent)).toEqual([
      "communityMain.tabs.forYou",
      "communityMain.tabs.all",
      "communityMain.tabs.serious",
      "communityMain.tabs.online",
      "communityMain.tabs.new",
    ]);
```

(rename the test to "offers the five in-page tabs inside one tablist, in app order").

Append to the `describe("the community tabs", …)` block of `src/components/community/MainCommunityTabs.test.tsx`:

```tsx
  it("locks the Serious tab to members active in the last week", async () => {
    renderList(["/communities?tab=serious"]);

    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    const last = memberRequests()[memberRequests().length - 1];
    expect(last).toContain("activeWithin=7d");
    expect(tab("communityMain.tabs.serious")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("segment-hint")).toHaveTextContent("communityMain.tabs.seriousHint");
  });
```

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false buildCommunityQuery communityUrlState CommunitySubNav MainCommunityTabs`
Expected: FAIL — no `activeWithin`, `serious` decodes as undefined, the tab is missing.

- [ ] **Step 3: Implement**

`buildCommunityQuery.ts` — in `CommunityFilters`, after `newUsersOnly?: boolean;` add:

```ts
  /**
   * "Serious learners" segment: active in the last 7 days. Set by the Serious
   * tab, never stored or written to the URL (the tab name says it).
   */
  activeWithin?: '7d';
```

and after `if (filters.newUsersOnly) query.joinedWithin = '7d';` add:

```ts
  // The app's PartnerSegment.serious (controllers/users.js reads 7d/30d).
  if (filters.activeWithin) query.activeWithin = filters.activeWithin;
```

`communityUrlState.ts` — in `CommunityUrlTab` add `| 'serious'` after `| 'all'`, and in `TABS` add `'serious',`
after `'all',`. Update the doc comment above the type: "`foryou`, `all`, `serious`, `online` and `new` are rendered
in place".

`CommunitySubNav.tsx` — add `Flame,` to the lucide import list; add `| "serious"` after `| "all"` in
`CommunityNavTab`; in `IN_PAGE_TABS` insert after the `all` entry:

```ts
  {
    // The app's "Serious learners" segment (partner_segment_chips.dart):
    // the All list, active this week.
    id: "serious",
    copyKey: "communityMain.tabs.serious",
    fallback: "Serious learners",
    Icon: Flame,
  },
```

`MainCommunity.tsx` — replace:

```ts
  const effectiveFilters = useMemo<CommunityFilters>(() => {
    if (activeTab === "online") return { ...filters, onlineOnly: true };
    if (activeTab === "new") return { ...filters, newUsersOnly: true };
    return filters;
  }, [filters, activeTab]);
```

with:

```ts
  const effectiveFilters = useMemo<CommunityFilters>(() => {
    if (activeTab === "online") return { ...filters, onlineOnly: true };
    if (activeTab === "new") return { ...filters, newUsersOnly: true };
    if (activeTab === "serious") return { ...filters, activeWithin: "7d" };
    return filters;
  }, [filters, activeTab]);
```

replace:

```tsx
        lockedTab={activeTab === "online" || activeTab === "new" ? activeTab : undefined}
```

with:

```tsx
        lockedTab={
          activeTab === "online" || activeTab === "new" || activeTab === "serious"
            ? activeTab
            : undefined
        }
```

and, right after the opening `<div className="community-page__container">` (before the `{!isForYou && (` block), add:

```tsx
        {activeTab === "serious" && (
          // The app's explainer line under the active segment.
          <p data-testid="segment-hint" className="px-1 pb-2 text-xs text-ink-500 dark:text-ink-400">
            {t("communityMain.tabs.seriousHint") || "Active this week"}
          </p>
        )}
```

`CommunityFilterSheet.tsx` — replace `lockedTab?: "online" | "new";` with `lockedTab?: "online" | "new" | "serious";`
and in `lockedDraft` add after the `new` line:

```ts
    if (lockedTab === "serious") return { ...debouncedValue, activeWithin: "7d" };
```

(The Serious lock has no toggle in the sheet, so `lockHint` is unchanged; the count simply matches the list.)

`eng.json` — in `communityMain.tabs` add:

```json
"serious": "Serious learners",
"seriousHint": "Active this week"
```

- [ ] **Step 4: Run → PASS** (same command, plus `CommunityFilterSheet communityPerf communityPaging`).

- [ ] **Step 5: Commit** (tick `P3-COM-6`)

```bash
git add src/components/community/lib/buildCommunityQuery.ts src/components/community/lib/buildCommunityQuery.test.ts \
  src/components/community/lib/communityUrlState.ts src/components/community/lib/communityUrlState.test.ts \
  src/components/community/tandem/CommunitySubNav.tsx src/components/community/tandem/CommunitySubNav.test.tsx \
  src/components/community/MainCommunity.tsx src/components/community/MainCommunityTabs.test.tsx \
  src/components/community/CommunityFilterSheet.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(community): Serious learners tab (activeWithin=7d)

The app's partner list has an All / Serious learners / New members
segment; the web had no Serious. It is now a tab between All and Online
that locks activeWithin=7d onto the query (the server's "active this
week", which also skips people who hide their online status), with the
app's hint line and the filter sheet's count measured the same way.

Still open (Phase 3 community): smart sort + reciprocal, suggested
members, Today waved cards, dead endpoints, profile counts + blocked card,
i18n sweep + translations.
EOF
```

---

### Task P3-COM-7: Smart sort by default when the server offers it; reciprocal ("perfect partners") filter (community#9)

**Files:**
- Modify: `src/components/community/lib/buildCommunityQuery.ts` (`sort` type, `reciprocal`)
- Modify: `src/components/community/lib/communityUrlState.ts` (`URL_KEYS` + `pair`)
- Modify: `src/components/community/MainCommunity.tsx` (imports, app-config, `queryArg`, members query `skip`,
  `countActiveFilters`)
- Modify: `src/components/community/CommunityFilterSheet.tsx` (reciprocal toggle)
- Modify: `src/components/community/ActiveFilterChips.tsx` (chip)
- Modify: `src/utils/locales/eng.json` (`communityMain.filterSheet.reciprocal`, `.reciprocalHint`)
- Test: `buildCommunityQuery.test.ts`, `communityUrlState.test.ts`, `MainCommunityTabs.test.tsx`, `CommunityFilterSheet.test.tsx`

**Interfaces:**
- Consumes: `GET /api/v1/app-config` → `smartSortEnabled: boolean`; `GET /auth/users?sort=smart` (honoured only while
  `SMART_SORT_ENABLED`, users.js:413) and `?reciprocal=true` (users.js:203-216: they speak what I learn AND learn what
  I speak). The app sends `sort=smart` only as the default, never over an explicit choice (`community_provider.dart:1300-1310`).
- Produces: `CommunityFilters.sort?: 'recently_active' | 'smart'`, `CommunityFilters.reciprocal?: boolean`; URL key `pair=1`.
- Note: the app carries `reciprocal` in its filter model but exposes no control for it; the web adds a filter-sheet
  switch because the spec lists it. Reviewers may prefer to drop the switch — the param plumbing stays either way.

- [ ] **Step 1: Write the failing tests**

`buildCommunityQuery.test.ts`:

```ts
it('reciprocal -> reciprocal=true; smart sort passes through', () => {
  const q = buildCommunityQuery({ reciprocal: true, sort: 'smart' }, me, 1, 20);
  expect(q.reciprocal).toBe('true');
  expect(q.sort).toBe('smart');
  expect(buildCommunityQuery({}, me, 1, 20).reciprocal).toBeUndefined();
});
```

`communityUrlState.test.ts` — the key-vocabulary test's expected array gains `'pair'` after `'new'`, and add:

```ts
  describe('the reciprocal filter', () => {
    it('round-trips as pair=1', () => {
      const encoded = encodeCommunityState({ filters: { reciprocal: true }, search: '', tab: 'all' });
      expect(encoded.get('pair')).toBe('1');
      expect(decodeCommunityState(params('pair=1')).filters).toEqual(
        expect.objectContaining({ reciprocal: true })
      );
    });
  });
```

`MainCommunityTabs.test.tsx` — at module scope add `let appConfig: any = {};`; in `beforeEach` reset `appConfig = {};`
and make the fetch mock answer it first:

```ts
    let body: any = { success: true, data: [] };
    if (url.indexOf("/app-config") >= 0) {
      body = { success: true, data: appConfig };
    } else if (url.indexOf("/matching/recommendations") >= 0) {
```

(the existing `if` becomes `else if`). Then add:

```tsx
describe("smart sort (community#9)", () => {
  it("asks for sort=smart by default when the server offers it, from the first request", async () => {
    appConfig = { smartSortEnabled: true };
    renderList();
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests().every((u) => u.indexOf("sort=smart") >= 0)).toBe(true);
  });

  it("never overrides the member's own sort", async () => {
    appConfig = { smartSortEnabled: true };
    renderList(["/communities?tab=all&sort=recently_active"]);
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests().some((u) => u.indexOf("sort=smart") >= 0)).toBe(false);
    expect(memberRequests()[memberRequests().length - 1]).toContain("sort=recently_active");
  });

  it("sends no sort while the flag is off", async () => {
    renderList();
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests().some((u) => u.indexOf("sort=") >= 0)).toBe(false);
  });

  it("sends reciprocal=true from a pair=1 link", async () => {
    renderList(["/communities?tab=all&pair=1"]);
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests()[memberRequests().length - 1]).toContain("reciprocal=true");
  });
});
```

`CommunityFilterSheet.test.tsx`:

```tsx
  it("turns on perfect partners (reciprocal)", () => {
    const { onChange } = renderSheet();
    fireEvent.click(screen.getByText("Perfect partners only"));
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ reciprocal: true }));
  });
```

- [ ] **Step 2: Run and confirm it fails**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false buildCommunityQuery communityUrlState MainCommunityTabs CommunityFilterSheet`
Expected: FAIL — no `reciprocal`/`pair`, no `sort=smart`, no switch.

- [ ] **Step 3: Implement**

`buildCommunityQuery.ts` — replace `  sort?: 'recently_active';` with:

```ts
  /** `smart` is only ever the page's default while appConfig.smartSortEnabled is on. */
  sort?: 'recently_active' | 'smart';
  /**
   * Strict pairs: they speak what I learn AND learn what I speak
   * (controllers/users.js `reciprocal=true`).
   */
  reciprocal?: boolean;
```

and after the `activeWithin` line add:

```ts
  if (filters.reciprocal) query.reciprocal = 'true';
```

`communityUrlState.ts` — in `URL_KEYS` insert `'pair',` after `'new',`; in `encodeCommunityState` after
`if (filters.newUsersOnly) params.set('new', '1');` add `if (filters.reciprocal) params.set('pair', '1');`; in the
decoder after the `read('new')` block add:

```ts
  if (read('pair') === '1') {
    filters.reciprocal = true;
    hasFilter = true;
  }
```

`MainCommunity.tsx`:
- Imports: add `import { useGetAppConfigQuery } from "../../store/slices/appConfigSlice";` after the usersSlice import.
- `countActiveFilters`: after `if (f.newUsersOnly) n += 1;` add `if (f.reciprocal) n += 1;`.
- Before `const queryArg = useMemo(` add:

```ts
  // Smart ranking is the DEFAULT only, and only while the server offers it
  // (the app's _sortFor): a sort the member chose always wins. The list waits
  // for the config so the first request is already the right one -- not a
  // VIP-first list that reshuffles a moment later.
  const { data: appConfig, isLoading: appConfigLoading } = useGetAppConfigQuery();
  const smartSort = Boolean(appConfig && (appConfig as any).smartSortEnabled);
  const listSort: CommunityFilters["sort"] = sort || (smartSort ? "smart" : undefined);
```

- In `queryArg`, replace `{ ...effectiveFilters, search: debouncedSearch || undefined, sort },` with
  `{ ...effectiveFilters, search: debouncedSearch || undefined, sort: listSort },` and the deps
  `[effectiveFilters, debouncedSearch, sort, me, page]` with `[effectiveFilters, debouncedSearch, listSort, me, page]`.
- Replace `} = useGetCommunityMembersQuery(queryArg, { skip: isForYou || isToday });` with
  `} = useGetCommunityMembersQuery(queryArg, { skip: isForYou || isToday || appConfigLoading });`
- `filterKey` deps stay on `sort` (the URL state); `listSort` only differs while the flag is on and is stable for
  the page's life.

`CommunityFilterSheet.tsx` — in the toggles `<section className="divide-y divide-gray-100">`, after the "New users only"
`<ToggleSwitch …/>`, add:

```tsx
            <ToggleSwitch
              checked={!!value.reciprocal}
              onChange={(checked) => set("reciprocal", checked || undefined)}
              label={t("communityMain.filterSheet.reciprocal") || "Perfect partners only"}
              hint={
                t("communityMain.filterSheet.reciprocalHint") ||
                "They speak what you learn and learn what you speak"
              }
              hintTestId="filter-sheet-reciprocal-hint"
            />
```

`ActiveFilterChips.tsx` — after the `newUsersOnly` chip add:

```ts
  if (value.reciprocal) {
    chips.push({ key: "reciprocal", label: "Perfect partners" });
  }
```

`eng.json` — in `communityMain.filterSheet` add:

```json
"reciprocal": "Perfect partners only",
"reciprocalHint": "They speak what you learn and learn what you speak"
```

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false community`
Expected: PASS — including `communityPerf` ("exactly one `/auth/users?` request on mount": the gate keeps it to one).

- [ ] **Step 5: Commit** (tick `P3-COM-7`)

```bash
git add src/components/community/lib/buildCommunityQuery.ts src/components/community/lib/buildCommunityQuery.test.ts \
  src/components/community/lib/communityUrlState.ts src/components/community/lib/communityUrlState.test.ts \
  src/components/community/MainCommunity.tsx src/components/community/MainCommunityTabs.test.tsx \
  src/components/community/CommunityFilterSheet.tsx src/components/community/CommunityFilterSheet.test.tsx \
  src/components/community/ActiveFilterChips.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(community): smart sort default behind the flag, perfect-partners filter

The app ranks the partner list with the matching scorer (sort=smart) by
default while appConfig.smartSortEnabled is on; the web never asked. The
list now does the same, waits for the config so the first request is
already ranked, and never overrides a sort the member chose. A "Perfect
partners only" switch sends reciprocal=true (they speak what you learn and
learn what you speak), kept in links as pair=1.

Still open (Phase 3 community): suggested members, Today waved cards,
dead endpoints, profile counts + blocked card, i18n sweep + translations;
ActiveFilterChips labels are still English.
EOF
```

---

### Task P3-COM-8: "More members like X" asks for people who speak X's language (community#11)

**Files:**
- Modify: `src/components/profile/parts/SuggestedMembers.tsx:58-61`
- Test: `src/components/profile/parts/SuggestedMembers.test.tsx:55-59`

**Interfaces:**
- Consumes: `GET /auth/users?nativeLanguage=X` with no `matchLanguage` → server's direct branch:
  `native_language ~ /X/i` (users.js:189-196). `language=` is not a parameter at all, so today the strip is the
  viewer's default list.
- **Deviation from the audit's wording:** the audit suggested `matchLanguage=true&nativeLanguage=&learningLanguage=`.
  With `matchLanguage=true`, `nativeLanguage=X` means "people LEARNING X" (inverted, see buildCommunityQuery.ts:4-11),
  which is X's partners, not people like X. The component's documented intent is "members sharing the profile's
  language", so the direct branch is used.

- [ ] **Step 1: Update the test** — in `SuggestedMembers.test.tsx` replace:

```ts
it("asks for one page of members sharing the profile's language", () => {
  renderStrip();
  expect(mockGetMembers.mock.calls[0][0]).toEqual({ page: 1, limit: 12, language: "English" });
  expect(mockGetMembers.mock.calls[0][1].skip).toBe(false);
});
```

with:

```ts
// `language=` is not a parameter of GET /auth/users; the server ignored it
// and the strip showed the viewer's default list. `nativeLanguage` without
// matchLanguage is the server's direct branch: native speakers of it.
it("asks for one page of native speakers of the profile's language", () => {
  renderStrip();
  expect(mockGetMembers.mock.calls[0][0]).toEqual({ page: 1, limit: 12, nativeLanguage: "English" });
  expect(mockGetMembers.mock.calls[0][0].matchLanguage).toBeUndefined();
  expect(mockGetMembers.mock.calls[0][1].skip).toBe(false);
});
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false SuggestedMembers`
Expected: FAIL — the arg is `{ page: 1, limit: 12, language: "English" }`.

- [ ] **Step 3: Implement** — `SuggestedMembers.tsx`, replace:

```ts
  const { data } = useGetCommunityMembersQuery(
    { page: 1, limit: PAGE_LIMIT, language: language || undefined },
    { skip: !language || !viewerId }
  );
```

with:

```ts
  // `nativeLanguage` WITHOUT matchLanguage is the server's direct branch
  // (controllers/users.js): people whose native language is this one. With
  // matchLanguage it would flip to "people learning it" -- this profile's
  // partners, not people like them. `language=` was never a parameter.
  const { data } = useGetCommunityMembersQuery(
    { page: 1, limit: PAGE_LIMIT, nativeLanguage: language || undefined },
    { skip: !language || !viewerId }
  );
```

- [ ] **Step 4: Run → PASS** (`SuggestedMembers ProfilePage`).

- [ ] **Step 5: Commit** (tick `P3-COM-8`)

```bash
git add src/components/profile/parts/SuggestedMembers.tsx src/components/profile/parts/SuggestedMembers.test.tsx \
  docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(profile): suggested members filter by the profile's language

"More members like X" sent language=, which GET /auth/users does not read,
so the strip was the viewer's default list. It now sends nativeLanguage
without matchLanguage, the server's direct branch: native speakers of X's
language.

Still open (Phase 3 community): Today waved cards, dead endpoints, profile
counts + blocked card, i18n sweep + translations.
EOF
```

---

### Task P3-COM-9: Today marks a card "Waved" after a wave (community#14)

**Files:**
- Modify: `src/components/community/WaveSheet.tsx` (new `onWaved` prop)
- Modify: `src/components/community/today/TodayTab.tsx` (`wavedIds` prop)
- Modify: `src/components/community/today/MatchCard.tsx` (`waved` prop)
- Modify: `src/components/community/MainCommunity.tsx` (track waved ids, wire both)
- Modify: `src/utils/locales/eng.json` (`communityMain.today.waved`)
- Test: `today/MatchCard.test.tsx`, `today/TodayTab.test.tsx`, `today/todayIntegration.test.tsx`, `WaveSheet.test.tsx`

**Interfaces:**
- Produces: `WaveSheetProps.onWaved?: (targetUserId: string, isMutual: boolean) => void` — fired after a 201 and
  after `ALREADY_WAVED` (the server already holds a wave for the pair, so the card is done either way);
  `TodayTab` prop `wavedIds?: string[]`; `MatchCard` prop `waved?: boolean`.
- In-memory for the page's life. After a reload the button is live again, and a second tap lands on the sheet's
  already-waved state, which also marks the card. No storage needed.

- [ ] **Step 1: Write the failing tests**

`today/MatchCard.test.tsx` — append (reuse the file's existing render helper and `match` fixture):

```tsx
it("shows a disabled Waved state instead of Wave once waved", () => {
  const onWave = jest.fn();
  render(
    <MemoryRouter>
      <MatchCard match={match as any} onWave={onWave} onSkip={jest.fn()} waved />
    </MemoryRouter>
  );
  expect(screen.queryByTestId("match-wave")).not.toBeInTheDocument();
  const done = screen.getByTestId("match-waved");
  expect(done).toBeDisabled();
  fireEvent.click(done);
  expect(onWave).not.toHaveBeenCalled();
});
```

(If the file's fixture is named differently, use it; `MemoryRouter`, `render`, `screen`, `fireEvent` are already
imported there.)

`today/TodayTab.test.tsx` — append inside `describe("TodayTab", …)`:

```tsx
  it("marks the cards in wavedIds as waved, and keeps them in the batch", () => {
    renderTab({ wavedIds: ["b"] });
    expect(screen.getAllByTestId("match-card")).toHaveLength(3);
    expect(screen.getAllByTestId("match-waved")).toHaveLength(1);
    expect(screen.getAllByTestId("match-wave")).toHaveLength(2);
  });
```

`today/todayIntegration.test.tsx` — make the fetch mock answer the wave POST:

```ts
    } else if (url.indexOf("/community/wave") >= 0 && (input as any).method === "POST") {
      status = 201;
      body = { success: true, data: { waveId: "w1", isMutual: false, message: "Wave sent!" } };
    } else if (/\/auth\/users\?/.test(url)) {
```

and append:

```tsx
  it("a sent wave turns the card's Wave into Waved (community#14)", async () => {
    renderAt("/communities");
    await screen.findByText("Daily One");
    fireEvent.click(screen.getByTestId("match-wave"));
    fireEvent.click(await screen.findByTestId("wave-sheet-send"));
    expect(await screen.findByTestId("match-waved")).toBeInTheDocument();
    expect(screen.queryByTestId("match-wave")).not.toBeInTheDocument();
  });
```

`WaveSheet.test.tsx` — append inside `describe("WaveSheet", …)`:

```tsx
  it("tells the caller about a sent wave and about ALREADY_WAVED", async () => {
    const onWaved = jest.fn();
    mockSendWave.mockReturnValue({
      unwrap: () => Promise.resolve({ success: true, data: { waveId: "w1", isMutual: true } }),
    });
    renderSheet({ onWaved });
    fireEvent.click(screen.getByTestId("wave-sheet-send"));
    await waitFor(() => expect(onWaved).toHaveBeenCalledWith("user-2", true));

    onWaved.mockReset();
    rejectWith(400, { success: false, error: "already", code: "ALREADY_WAVED" });
    renderSheet({ onWaved });
    fireEvent.click(screen.getAllByTestId("wave-sheet-send")[1]);
    await waitFor(() => expect(onWaved).toHaveBeenCalledWith("user-2", false));
  });
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false MatchCard TodayTab todayIntegration WaveSheet`
Expected: FAIL — no `match-waved`, `onWaved` never called.

- [ ] **Step 3: Implement**

`WaveSheet.tsx` — in `WaveSheetProps` add:

```ts
  /**
   * The server now holds a wave from the viewer to this person: fired after a
   * sent wave, and after ALREADY_WAVED (an earlier one). Today's cards use it
   * to stop offering a second wave.
   */
  onWaved?: (targetUserId: string, isMutual: boolean) => void;
```

change the component signature to `({ open, targetUser, onClose, onWaved }) =>`; in `handleSend` after
`const isMutual = !!result?.data?.isMutual;` add `if (onWaved) onWaved(targetUser._id, isMutual);`; in the
`ALREADY_WAVED` branch, before `return;`, add `if (onWaved) onWaved(targetUser._id, false);`.

`MatchCard.tsx` — props become:

```ts
const MatchCard: React.FC<{
  match: DailyMatch;
  onWave: (match: DailyMatch) => void;
  onSkip: (match: DailyMatch) => void;
  /** A wave to this person exists: the Wave action becomes a done state. */
  waved?: boolean;
}> = ({ match, onWave, onSkip, waved = false }) => {
```

and replace the Wave button:

```tsx
        <button type="button" data-testid="match-wave" onClick={() => onWave(match)} className={`${ACTION} border border-line text-ink-800 hover:bg-ink-50 dark:border-line-dark dark:text-ink-100 dark:hover:bg-white/5`}>
          <span aria-hidden>👋</span>
          {t("communityMain.today.wave") || "Wave"}
        </button>
```

with:

```tsx
        {waved ? (
          <button type="button" data-testid="match-waved" disabled className={`${ACTION} border border-line text-ink-500 opacity-70 dark:border-line-dark dark:text-ink-400`}>
            <span aria-hidden>✓</span>
            {t("communityMain.today.waved") || "Waved"}
          </button>
        ) : (
          <button type="button" data-testid="match-wave" onClick={() => onWave(match)} className={`${ACTION} border border-line text-ink-800 hover:bg-ink-50 dark:border-line-dark dark:text-ink-100 dark:hover:bg-white/5`}>
            <span aria-hidden>👋</span>
            {t("communityMain.today.wave") || "Wave"}
          </button>
        )}
```

`TodayTab.tsx` — props: add `wavedIds?: string[];` to the type and `wavedIds = []` to the destructuring
(`({ response, isLoading, isError, onRetry, onWave, onBrowse, wavedIds = [] })`); in the card map pass
`waved={wavedIds.indexOf(match.user._id) > -1}` to `<MatchCard …/>`.

`MainCommunity.tsx` — after `const [waveTarget, setWaveTarget] = useState<CommunityMemberCard | null>(null);` add:

```ts
  // People the viewer has waved at during this visit. Today's batch is cached
  // server-side for the whole day and does not drop them, so the card itself
  // has to stop offering a second wave (which would only hit ALREADY_WAVED).
  const [wavedIds, setWavedIds] = useState<string[]>([]);
  const handleWaved = useCallback((targetUserId: string) => {
    setWavedIds((prev) => (prev.indexOf(targetUserId) > -1 ? prev : prev.concat([targetUserId])));
  }, []);
```

pass `onWaved={handleWaved}` to `<WaveSheet …/>` and `wavedIds={wavedIds}` to `<TodayTab …/>`.

`eng.json` — in `communityMain.today` add `"waved": "Waved"`.

- [ ] **Step 4: Run → PASS** (same command plus `MainCommunity`).

- [ ] **Step 5: Commit** (tick `P3-COM-9`)

```bash
git add src/components/community/WaveSheet.tsx src/components/community/WaveSheet.test.tsx \
  src/components/community/today/TodayTab.tsx src/components/community/today/TodayTab.test.tsx \
  src/components/community/today/MatchCard.tsx src/components/community/today/MatchCard.test.tsx \
  src/components/community/today/todayIntegration.test.tsx src/components/community/MainCommunity.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(community): Today shows Waved after a wave instead of offering another

Today's batch is cached for the whole day and keeps people the viewer has
waved at, so the card kept its Wave button and a second tap hit
ALREADY_WAVED. WaveSheet now reports a sent (or already existing) wave and
the card turns into a disabled "Waved" state for the rest of the visit.

Still open (Phase 3 community): dead endpoints, profile counts + blocked
card, i18n sweep + translations; Today extra-matches (coins) unlock not on
web.
EOF
```

---

### Task P3-COM-10: Delete the dead community endpoints and wave shims (community#12)

**Files:**
- Modify: `src/store/slices/communitySlice.ts` — delete `getUserTopics` (:214-219), `updateMyLanguages` (:262-269),
  `getUsersByLanguage` (:270-280), `getOnlineUsers`/`getRecentlyActive`/`getNewUsers` (:282-307), their hook exports
  (:328, :333-338) and the shim block (:342-377)
- Test: `src/store/slices/communityEndpoints.test.ts` (append)

**Interfaces:**
- Removed (verified unused: `grep -rn` for every endpoint and hook name finds only `communitySlice.ts` and the
  "does NOT expose the old wave routes" test, which still passes): `useGetUserTopicsQuery`, `useUpdateMyLanguagesMutation`,
  `useGetUsersByLanguageQuery`, `useGetOnlineUsersQuery`, `useGetRecentlyActiveQuery`, `useGetNewUsersQuery`,
  `useGetReceivedWavesQuery`, `useGetSentWavesQuery`, `useMarkWaveReadMutation`, `useRespondToWaveMutation`.
  `/auth/users/online|recently-active|new` would hit `/:id` → CastError 404; `/languages/users|my-languages` and
  `/community/topics/user/:id` do not exist (routes/languages.js has only `GET /`).

- [ ] **Step 1: Write the failing test** — append to `communityEndpoints.test.ts` (add
  `import * as communitySliceExports from "./communitySlice";` to the imports):

```ts
describe("dead endpoints are gone (community#12)", () => {
  // Each pointed at a route the API does not serve; unused, but they invite
  // reuse and every reuse is a silent 404.
  it("has no endpoint for a route the API does not serve", () => {
    const names = Object.keys((communityApiSlice as any).endpoints);
    [
      "getUserTopics",
      "updateMyLanguages",
      "getUsersByLanguage",
      "getOnlineUsers",
      "getRecentlyActive",
      "getNewUsers",
    ].forEach((name) => expect(names).not.toContain(name));
  });

  it("exports none of their hooks, nor the deprecated wave shims", () => {
    const exported = communitySliceExports as any;
    [
      "useGetUserTopicsQuery",
      "useUpdateMyLanguagesMutation",
      "useGetUsersByLanguageQuery",
      "useGetOnlineUsersQuery",
      "useGetRecentlyActiveQuery",
      "useGetNewUsersQuery",
      "useGetReceivedWavesQuery",
      "useGetSentWavesQuery",
      "useMarkWaveReadMutation",
      "useRespondToWaveMutation",
    ].forEach((name) => expect(exported[name]).toBeUndefined());
  });
});
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false communityEndpoints`
Expected: FAIL — all six endpoints and ten exports exist.

- [ ] **Step 3: Implement** — in `communitySlice.ts`:
  - delete the `getUserTopics: builder.query({ … }),` block (the one with `` url: `${COMMUNITY_TOPICS}/user/${userId}` ``);
  - delete `updateMyLanguages` and `getUsersByLanguage`, keeping `getLanguages` under `// Languages`;
  - delete the `// Online Status`, `// Recently Active`, `// New Users` blocks;
  - the export list becomes:

```ts
export const {
  useGetCommunityMembersQuery,
  useGetCommunityCountQuery,
  useGetCommunityDetailsQuery,
  useGetPublicUserProfileQuery,
  // "For you"
  useGetRecommendationsQuery,
  useGetDailyMatchesQuery,
  useSkipUserMutation,
  // Nearby
  useGetNearbyUsersQuery,
  // Waves (real backend routes)
  useSendWaveMutation,
  useGetWavesQuery,
  useMarkWavesReadMutation,
  // Topics
  useGetTopicsQuery,
  useUpdateMyTopicsMutation,
  useGetUsersByTopicQuery,
  // Languages
  useGetLanguagesQuery,
} = communityApiSlice;
export default communityApiSlice.reducer;
```

  - delete everything after `export default communityApiSlice.reducer;` (the "Deprecated wave-hook compatibility
    shims" comment block and the four shim exports).

Then confirm nothing else referenced them:

```bash
grep -rnE "useGetUserTopicsQuery|useUpdateMyLanguagesMutation|useGetUsersByLanguageQuery|useGetOnlineUsersQuery|useGetRecentlyActiveQuery|useGetNewUsersQuery|useGetReceivedWavesQuery|useGetSentWavesQuery|useMarkWaveReadMutation|useRespondToWaveMutation" src
# Expected: only the names inside communityEndpoints.test.ts
```

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false communityEndpoints && npx tsc --noEmit -p .`
Expected: PASS; `tsc` prints nothing.

- [ ] **Step 5: Commit** (tick `P3-COM-10`)

```bash
git add src/store/slices/communitySlice.ts src/store/slices/communityEndpoints.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
chore(community): remove endpoints for routes the API does not serve

getOnlineUsers/getRecentlyActive/getNewUsers hit /auth/users/:id with a
word for an id (CastError 404); getUserTopics, getUsersByLanguage and
updateMyLanguages call routes that do not exist; the received/sent/respond
wave shims adapted a contract that never existed. None had a caller. A
test pins that they stay gone.

Still open (Phase 3 community): profile counts + story ring, blocked card +
follow 403, i18n sweep + translations.
EOF
```

---

### Task P3-COM-11: Profile counts from `followersCount` for signed-out visitors; story ring from `hasActiveStory` (community#6, links#11)

**Files:**
- Modify: `src/components/profile/useProfileData.ts:26-36, 98-105`
- Modify: `src/components/profile/parts/ProfileHeader.tsx` (props + Avatar)
- Modify: `src/components/profile/ProfilePage.tsx` (header props)
- Modify: `src/utils/locales/eng.json` (`profile.photos.openStory`)
- Test: `src/components/profile/useProfileData.test.tsx`, `src/components/profile/ProfilePage.test.tsx`

**Interfaces:**
- Consumes (after P1-PRIV-1/2 deploy): signed-out `GET /auth/users/:id/public` → no `followers`/`following` arrays,
  additive `followersCount`/`followingCount` numbers; every viewer gets `hasActiveStory: boolean`. Signed-in viewers
  still get the arrays (the web's `isFollowing` reads them). Before the deploy: arrays for everyone, no counts.
- Produces: `ProfileHeaderProps.hasStory?: boolean`; ring + "View story" on the avatar for a signed-in viewer of
  someone else's profile (signed-out visitors see the ring but are sent to `/login`, since `/stories/:userId`
  reads protected endpoints).

- [ ] **Step 1: Write the failing tests**

`useProfileData.test.tsx` — append:

```tsx
// P1-PRIV-1: signed-out visitors of /:id/public get counts, not id lists.
// The page read only the arrays, so every shared profile said 0 followers.
it("counts from followersCount/followingCount when the lists are absent", () => {
  mockGetPublicProfile.mockReturnValue({
    ...idle,
    data: { data: { _id: "u2", name: "Ada", followersCount: 12, followingCount: 3 } },
  });
  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper(undefined) });
  expect(result.current.stats.followers).toBe(12);
  expect(result.current.stats.following).toBe(3);
  expect(result.current.isFollowing).toBe(false);
});

it("prefers the lists when both are present (signed-in viewers)", () => {
  mockGetPublicProfile.mockReturnValue({
    ...idle,
    data: { data: { _id: "u2", followers: ["me", "x"], following: [], followersCount: 99 } },
  });
  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper("me") });
  expect(result.current.stats.followers).toBe(2);
  expect(result.current.isFollowing).toBe(true);
});
```

`ProfilePage.test.tsx` — append:

```tsx
describe("story ring (community#6)", () => {
  it("rings the avatar and opens the stories when the person has one", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["https://cdn/a.jpg"], hasActiveStory: true } },
    });
    renderPage("/profile/u2", "me");
    expect(screen.getByTestId("avatar-story-ring")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "View Ada's story" }));
    expect(mockNavigate).toHaveBeenCalledWith("/stories/u2");
  });

  it("sends a signed-out visitor to log in rather than to a protected viewer", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["https://cdn/a.jpg"], hasActiveStory: true } },
    });
    renderPage("/profile/u2", null);
    fireEvent.click(screen.getByRole("button", { name: "View Ada's story" }));
    expect(mockNavigate).toHaveBeenCalledWith("/login");
  });

  it("keeps the photo viewer when there is no story", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["https://cdn/a.jpg"] } },
    });
    renderPage("/profile/u2", "me");
    expect(screen.queryByTestId("avatar-story-ring")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Open Ada's photo" })).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false useProfileData ProfilePage`
Expected: FAIL — counts read 0; no ring; no "View Ada's story" button.

- [ ] **Step 3: Implement**

`useProfileData.ts` — after `countOf` add:

```ts
/**
 * A follower/following figure from whatever the endpoint sent. Signed-in
 * readers get the id lists (isFollowing needs them); signed-out readers of
 * /:id/public get `followersCount` / `followingCount` instead (backend
 * P1-PRIV-1 drops the lists for anonymous viewers). The list wins when both
 * are there; a server from before that change sends lists to everyone.
 */
function statOf(list: any, count: any): number {
  if (Array.isArray(list)) return list.length;
  return countOf(count);
}
```

and replace:

```ts
      followers: countOf(user && user.followers),
      following: countOf(user && user.following),
```

with:

```ts
      followers: statOf(user && user.followers, user && user.followersCount),
      following: statOf(user && user.following, user && user.followingCount),
```

`ProfileHeader.tsx` — in `ProfileHeaderProps` after `onAvatarClick?: () => void;` add:

```ts
  /** The person has a story the viewer may see: ring the avatar, and the tap opens it. */
  hasStory?: boolean;
```

add `hasStory = false,` to the destructuring, and replace the `<Avatar …/>` props:

```tsx
              onClick={avatarUrl ? onAvatarClick : undefined}
              label={t("profile.photos.openAvatar", { name }) || `Open ${name}'s photo`}
```

with:

```tsx
              hasStory={hasStory}
              onClick={avatarUrl || hasStory ? onAvatarClick : undefined}
              label={
                hasStory
                  ? t("profile.photos.openStory", { name }) || `View ${name}'s story`
                  : t("profile.photos.openAvatar", { name }) || `Open ${name}'s photo`
              }
```

`ProfilePage.tsx` — before `return (` of the main body (after the `failed` block) add:

```ts
  // Someone else's story ring (getUserPublic hasActiveStory, P1-PRIV-2). The
  // story viewer reads protected endpoints, so a signed-out visitor is sent
  // to log in first.
  const hasStory = !isOwn && Boolean(user && user.hasActiveStory);
  const handleAvatarClick = (): void => {
    if (!hasStory) {
      setAvatarOpenAt(0);
      return;
    }
    navigate(viewerId ? `/stories/${profileId}` : "/login");
  };
```

and in `<ProfileHeader …/>` replace `onAvatarClick={() => setAvatarOpenAt(0)}` with:

```tsx
            onAvatarClick={handleAvatarClick}
            hasStory={hasStory}
```

`eng.json` — in `profile.photos` add `"openStory": "View {{name}}'s story"`.

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false useProfileData ProfilePage ProfileHeader ProfileStats`
Expected: PASS.

- [ ] **Step 5: Commit** (tick `P3-COM-11` and, in the backend-linked "Web repo" line of the parity section, note the
  follower-count item done)

```bash
git add src/components/profile/useProfileData.ts src/components/profile/useProfileData.test.tsx \
  src/components/profile/parts/ProfileHeader.tsx src/components/profile/ProfilePage.tsx \
  src/components/profile/ProfilePage.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(profile): counts for signed-out visitors, story ring on profiles

Signed-out visitors of /:id/public no longer receive the follower id lists
(backend P1-PRIV-1) but followersCount/followingCount; the page read only
the lists and showed 0. It now uses the lists when present and the counts
otherwise, so it is right before and after the backend change. The avatar
is ringed when hasActiveStory is set and opens the person's stories
(signed-out visitors are sent to log in).

Still open (Phase 3 community): blocked card + follow 403, i18n sweep +
translations; own-profile story ring.
EOF
```

---

### Task P3-COM-12: Blocked viewers see a neutral card; follow refused by a block says so (community#5)

**Files:**
- Modify: `src/components/profile/ProfilePage.tsx` (blocked branch after the `failed` block)
- Modify: `src/components/profile/useFollowToggle.ts` (403 toast)
- Modify: `src/utils/locales/eng.json` (`profile.blocked.*`, `profile.actions.followBlocked`)
- Test: `src/components/profile/ProfilePage.test.tsx`, `src/components/profile/useFollowToggle.test.tsx`

**Interfaces:**
- Consumes (after P1-PRIV-3/4 deploy): a signed-in viewer in a block relationship either way gets `200 { data: { _id,
  name, username, images: [first], imageUrls: [first], isBlocked: true } }` from `/:id/public`; `POST …/follow` answers
  `403 'Cannot follow this user'`. Before the deploy: no `isBlocked`, follow succeeds (unchanged behaviour).
- Produces: `data-testid="profile-blocked"` card; `useFollowToggle` raises `notify.error` on 403 (rollback unchanged).
- Does **not** touch `ProfileActions.tsx` (the CHAT unit edits it for chat#3); the blocked branch simply does not render it.

- [ ] **Step 1: Write the failing tests**

`ProfilePage.test.tsx` — append:

```tsx
describe("blocked (community#5)", () => {
  it("shows a neutral card with only the header, no actions, stats or tabs", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", username: "ada", images: [], imageUrls: [], isBlocked: true } },
    });
    renderPage("/profile/u2", "me");

    expect(screen.getByTestId("profile-blocked")).toBeInTheDocument();
    expect(screen.getByText("Ada")).toBeInTheDocument();
    expect(screen.queryByTestId("action-more")).not.toBeInTheDocument();
    expect(screen.queryByTestId("profile-tabs")).not.toBeInTheDocument();
    expect(screen.getByText("Manage blocked people").closest("a")).toHaveAttribute("href", "/settings/blocked");
  });

  it("renders the full page when isBlocked is absent", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });
    renderPage("/profile/u2", "me");
    expect(screen.queryByTestId("profile-blocked")).not.toBeInTheDocument();
    expect(screen.getByTestId("profile-body")).toBeInTheDocument();
  });
});
```

`useFollowToggle.test.tsx` — add at the top (after the existing mocks):

```tsx
const mockNotifyError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { error: (...args: any[]) => mockNotifyError(...args), success: jest.fn(), info: jest.fn() },
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
```

and append:

```tsx
it("says why when a block refuses the follow (403), and rolls back", async () => {
  mockFollow.mockReturnValue({
    unwrap: () => Promise.reject({ status: 403, data: { success: false, error: "Cannot follow this user" } }),
  });
  renderProbe({ isFollowing: false });
  fireEvent.click(screen.getByTestId("probe"));
  await waitFor(() => expect(mockNotifyError).toHaveBeenCalledWith("You can't follow this person"));
  expect(screen.getByTestId("probe")).toHaveTextContent("Follow");
});

it("stays quiet for other failures, as before", async () => {
  mockFollow.mockReturnValue(rejected());
  renderProbe({ isFollowing: false });
  fireEvent.click(screen.getByTestId("probe"));
  await waitFor(() => expect(screen.getByTestId("probe")).toHaveTextContent("Follow"));
  expect(mockNotifyError).not.toHaveBeenCalled();
});
```

(add `mockNotifyError.mockReset();` to the file's `beforeEach`).

- [ ] **Step 2: Run → FAIL**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false ProfilePage useFollowToggle`
Expected: FAIL — the minimal card renders as a sparse full profile with actions; no toast on 403.

- [ ] **Step 3: Implement**

`ProfilePage.tsx` — after the `if (failed) { … }` block, add:

```tsx
  // A block either way (backend P1-PRIV-3): the server sends a minimal card
  // with isBlocked. Rendering it as a profile showed a Message and a Follow
  // button that could only fail, and empty stats that read as "nobody
  // follows them". The page says what is going on instead, without saying
  // who blocked whom.
  if (!isOwn && user && user.isBlocked === true) {
    return (
      <div className={PAGE}>
        {meta}
        <div className={COLUMN}>
          <div className="space-y-3">
            <ProfileHeader name={displayName} username={user.username} avatarUrl={images[0]} />
            <SurfaceCard padding="md">
              <div data-testid="profile-blocked" className="py-4 text-center">
                <UserX className="mx-auto h-8 w-8 text-ink-400" aria-hidden />
                <h2 className="pt-3 font-display text-lg text-ink-900 dark:text-ink-50">
                  {t("profile.blocked.title") || "This profile isn't available"}
                </h2>
                <p className="pt-1 text-sm text-ink-500 dark:text-ink-400">
                  {t("profile.blocked.body") ||
                    "One of you has blocked the other, so you can't message, follow or see each other's posts."}
                </p>
                <Link
                  to="/settings/blocked"
                  data-testid="profile-blocked-manage"
                  className="mt-4 inline-flex items-center justify-center rounded-chip border border-line px-4 py-2 text-sm font-semibold text-ink-700 transition-colors hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
                >
                  {t("profile.blocked.manage") || "Manage blocked people"}
                </Link>
              </div>
            </SurfaceCard>
          </div>
        </div>
      </div>
    );
  }
```

(`UserX`, `Link`, `SurfaceCard`, `ProfileHeader`, `PAGE`, `COLUMN`, `meta`, `images`, `displayName` are all already in
scope in this file — `UserX` is used by the not-found card.)

`useFollowToggle.ts` — add imports:

```ts
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
```

after `const navigate = useNavigate();` add `const { t } = useTranslation();`, and replace:

```ts
    } catch (error) {
      setFollowing(!next);
    }
  }, [viewerId, targetId, busy, following, followUser, unFollowUser, onChanged, navigate]);
```

with:

```ts
    } catch (error) {
      setFollowing(!next);
      // A block either way: followUser answers 403 (backend P1-PRIV-4). Say
      // so rather than leaving a button that silently flips back. Other
      // failures keep the quiet rollback.
      if (error && (error as any).status === 403) {
        notify.error(t("profile.actions.followBlocked") || "You can't follow this person");
      }
    }
  }, [viewerId, targetId, busy, following, followUser, unFollowUser, onChanged, navigate, t]);
```

`eng.json` — in `profile.actions` add `"followBlocked": "You can't follow this person"`, and under `profile` add:

```json
"blocked": {
  "title": "This profile isn't available",
  "body": "One of you has blocked the other, so you can't message, follow or see each other's posts.",
  "manage": "Manage blocked people"
}
```

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false ProfilePage useFollowToggle UserListPage`
Expected: PASS.

- [ ] **Step 5: Commit** (tick `P3-COM-12`)

```bash
git add src/components/profile/ProfilePage.tsx src/components/profile/ProfilePage.test.tsx \
  src/components/profile/useFollowToggle.ts src/components/profile/useFollowToggle.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(profile): blocked viewers see a neutral card; blocked follows say why

With a block either way the server now answers the profile read with a
minimal card (isBlocked) and refuses follows with 403. The page rendered
the card as a sparse profile with Message and Follow buttons that could
only fail; it now shows the header and a neutral "not available" notice
with a link to the blocked list. A 403 on follow raises a toast instead of
a silent rollback.

Still open (Phase 3 community): i18n sweep + 17-locale translations.
EOF
```

---

### Task P3-COM-13: Community copy through `t()`, and a test that every key exists (community#13)

**Files:**
- Modify: `src/components/community/WaveSheet.tsx` (header, chips, icebreakers, section titles, placeholder, buttons,
  match/sent toasts, already-waved text, dialog aria-label)
- Modify: `src/utils/locales/eng.json` (`waves.sheet.*`)
- Modify: `src/components/community/WaveSheet.test.tsx` (i18n mock resolving `eng.json`)
- Test: `src/components/community/communityCopy.test.ts` (new)

**Interfaces:**
- Produces: the key list at the end of this section — the input for the unit's 17-locale translation step.
- `t("community.waves.sentTo")` (WaveSheet.tsx:78) moves to `waves.sheet.sent` (same reason as P3-COM-1: `community`
  is a string).

- [ ] **Step 1: Write the failing test** — create `src/components/community/communityCopy.test.ts`:

```ts
/**
 * Every literal t("...") key the community surfaces use must exist in
 * eng.json as a string (or as an i18next plural pair). The trap this guards:
 * eng.json's "community" is a STRING, so community.nearby.* / community.waves.*
 * could never resolve, the `|| "fallback"` never fired, and users read raw keys.
 */
import fs from "fs";
import path from "path";

const ROOT = path.join(__dirname, "..");
const FILES = [
  "community/NearbyUsers.tsx",
  "community/Waves.tsx",
  "community/WaveSheet.tsx",
  "community/tandem/CommunitySubNav.tsx",
  "community/CommunityFilterSheet.tsx",
  "community/today/MatchCard.tsx",
  "community/today/TodayTab.tsx",
  "profile/useFollowToggle.ts",
];
/** Keys built with template literals, which the scan below cannot see. */
const DYNAMIC_KEYS = ["hi", "cool", "hey", "chat", "hello", "nice"].reduce(
  (all: string[], chip) => all.concat([`waves.sheet.chips.${chip}.label`, `waves.sheet.chips.${chip}.message`]),
  ["waves.sheet.icebreakers.0", "waves.sheet.icebreakers.1", "waves.sheet.icebreakers.2", "waves.sheet.icebreakers.3"]
);

const eng = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../../utils/locales/eng.json"), "utf8")
);

function nodeAt(key: string): any {
  let node: any = eng;
  const parts = key.split(".");
  for (let i = 0; i < parts.length; i += 1) {
    if (!node || typeof node !== "object") return undefined;
    node = node[parts[i]];
  }
  return node;
}

function exists(key: string): boolean {
  if (typeof nodeAt(key) === "string") return true;
  return typeof nodeAt(`${key}_one`) === "string" && typeof nodeAt(`${key}_other`) === "string";
}

function usedKeys(): string[] {
  const used: string[] = [];
  FILES.forEach((file) => {
    const source = fs.readFileSync(path.join(ROOT, file), "utf8");
    const re = /\bt\(\s*"([A-Za-z0-9_.]+)"/g;
    let m = re.exec(source);
    while (m) {
      if (used.indexOf(m[1]) < 0) used.push(m[1]);
      m = re.exec(source);
    }
  });
  return used.concat(DYNAMIC_KEYS);
}

it("finds the keys at all", () => {
  expect(usedKeys().length).toBeGreaterThan(40);
});

it("every community key exists in eng.json", () => {
  expect(usedKeys().filter((key) => !exists(key))).toEqual([]);
});

it("no key hangs under a string parent like the old community.nearby.*", () => {
  const underString = usedKeys().filter((key) => {
    const parts = key.split(".");
    for (let i = 1; i < parts.length; i += 1) {
      if (typeof nodeAt(parts.slice(0, i).join(".")) === "string") return true;
    }
    return false;
  });
  expect(underString).toEqual([]);
});
```

- [ ] **Step 2: Run → FAIL**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false communityCopy`
Expected: FAIL. "under a string parent" lists `community.waves.sentTo` (WaveSheet). "exists" lists it plus the
`waves.sheet.*` dynamic keys. If it also lists pre-existing keys in `CommunitySubNav`, `CommunityFilterSheet`,
`MatchCard` or `TodayTab` that eng.json lacks, add their English (the component's `||` fallback text) to eng.json in
this task — they are part of community#13.

- [ ] **Step 3: Implement** — `WaveSheet.tsx`:

Replace the two constant tables:

```ts
const EMOJI_CHIPS: { emoji: string; label: string; message: string }[] = [
  { emoji: "👋", label: "Hi", message: "👋 Hi!" },
  { emoji: "❤️", label: "Cool", message: "❤️ Cool profile!" },
  { emoji: "😊", label: "Hey", message: "😊 Hey there!" },
  { emoji: "🎉", label: "Chat", message: "🎉 Let's chat!" },
  { emoji: "✋", label: "Hello", message: "✋ Hello!" },
  { emoji: "🌟", label: "Nice", message: "🌟 Nice to meet you!" },
];

const ICEBREAKER_PROMPTS: string[] = [
  "Hi! Want to practice languages together?",
  "I noticed we're learning similar languages — hi!",
  "Your profile caught my eye, how's it going?",
  "Hey! What made you start learning a new language?",
];
```

with:

```ts
// Copy lives in eng.json under waves.sheet.chips.<id>.{label,message}; the
// English here is the fallback. The message is what the wave carries, so it
// is sent in the waver's language, as typed text would be.
const EMOJI_CHIPS: { id: string; emoji: string; label: string; message: string }[] = [
  { id: "hi", emoji: "👋", label: "Hi", message: "👋 Hi!" },
  { id: "cool", emoji: "❤️", label: "Cool", message: "❤️ Cool profile!" },
  { id: "hey", emoji: "😊", label: "Hey", message: "😊 Hey there!" },
  { id: "chat", emoji: "🎉", label: "Chat", message: "🎉 Let's chat!" },
  { id: "hello", emoji: "✋", label: "Hello", message: "✋ Hello!" },
  { id: "nice", emoji: "🌟", label: "Nice", message: "🌟 Nice to meet you!" },
];

const ICEBREAKER_PROMPTS: string[] = [
  "Hi! Want to practice languages together?",
  "I noticed we're learning similar languages — hi!",
  "Your profile caught my eye, how's it going?",
  "Hey! What made you start learning a new language?",
];
```

Inside the component, after `const avatar = targetUser.imageUrls?.[0];`:

```ts
  const chips = EMOJI_CHIPS.map((chip) => ({
    ...chip,
    label: t(`waves.sheet.chips.${chip.id}.label`) || chip.label,
    message: t(`waves.sheet.chips.${chip.id}.message`) || chip.message,
  }));
  const icebreakers = ICEBREAKER_PROMPTS.map(
    (fallback, i) => t(`waves.sheet.icebreakers.${i}`) || fallback
  );
```

Then make these replacements (render `chips` / `icebreakers` instead of the constants):

| Current | Replacement |
|---|---|
| `` `🎉 It's a match! You and ${targetUser.name} both waved at each other.` `` | `` t("waves.sheet.match", { name: targetUser.name }) \|\| `🎉 It's a match! You and ${targetUser.name} both waved at each other.` `` |
| `t("community.waves.sentTo", { name: targetUser.name }) \|\|` | `t("waves.sheet.sent", { name: targetUser.name }) \|\|` |
| `t("community.waves.sendError") \|\|` | `t("waves.sheet.sendError") \|\|` |
| ``aria-label={`Send a wave to ${targetUser.name}`}`` | ``aria-label={t("waves.sheet.title", { name: targetUser.name }) \|\| `Send a wave to ${targetUser.name}`}`` |
| `Send a wave to {targetUser.name}` (the `<h2>`) | ``{t("waves.sheet.title", { name: targetUser.name }) \|\| `Send a wave to ${targetUser.name}`}`` |
| `Say hi and break the ice 👋` | `{t("waves.sheet.subtitle") \|\| "Say hi and break the ice 👋"}` |
| `aria-label="Close"` | `aria-label={t("waves.sheet.close") \|\| "Close"}` |
| `You already waved at {targetUser.name}` | ``{t("waves.sheet.alreadyTitle", { name: targetUser.name }) \|\| `You already waved at ${targetUser.name}`}`` |
| the two-line "You can only wave once per person — …" text | `{t("waves.sheet.alreadyBody") \|\| "You can only wave once per person — send them a message instead to keep the conversation going."}` |
| `Quick replies` | `{t("waves.sheet.quickReplies") \|\| "Quick replies"}` |
| `{EMOJI_CHIPS.map((chip) => (` | `{chips.map((chip) => (` (key becomes `chip.id`) |
| `Icebreakers` | `{t("waves.sheet.icebreakersTitle") \|\| "Icebreakers"}` |
| `{ICEBREAKER_PROMPTS.map((prompt) => (` | `{icebreakers.map((prompt) => (` |
| `className={`text-left px-3 …` (icebreaker button) | `className={`text-start px-3 …` |
| `Your message` | `{t("waves.sheet.yourMessage") \|\| "Your message"}` |
| `placeholder="Write a custom message (optional)…"` | `placeholder={t("waves.sheet.placeholder") \|\| "Write a custom message (optional)…"}` |
| `<div className="text-right text-xs …">` | `<div className="text-end text-xs …">` |
| `{alreadyWaved ? "Close" : "Cancel"}` | `{alreadyWaved ? t("waves.sheet.close") \|\| "Close" : t("waves.sheet.cancel") \|\| "Cancel"}` |
| `{alreadyWaved ? "Already waved" : "Send wave"}` | `{alreadyWaved ? t("waves.sheet.already") \|\| "Already waved" : t("waves.sheet.send") \|\| "Send wave"}` |

`eng.json` — inside `waves` add:

```json
"sheet": {
  "title": "Send a wave to {{name}}",
  "subtitle": "Say hi and break the ice 👋",
  "close": "Close",
  "cancel": "Cancel",
  "send": "Send wave",
  "already": "Already waved",
  "alreadyTitle": "You already waved at {{name}}",
  "alreadyBody": "You can only wave once per person — send them a message instead to keep the conversation going.",
  "quickReplies": "Quick replies",
  "icebreakersTitle": "Icebreakers",
  "yourMessage": "Your message",
  "placeholder": "Write a custom message (optional)…",
  "sent": "Wave sent to {{name}}!",
  "match": "🎉 It's a match! You and {{name}} both waved at each other.",
  "sendError": "Failed to send wave",
  "chips": {
    "hi": { "label": "Hi", "message": "👋 Hi!" },
    "cool": { "label": "Cool", "message": "❤️ Cool profile!" },
    "hey": { "label": "Hey", "message": "😊 Hey there!" },
    "chat": { "label": "Chat", "message": "🎉 Let's chat!" },
    "hello": { "label": "Hello", "message": "✋ Hello!" },
    "nice": { "label": "Nice", "message": "🌟 Nice to meet you!" }
  },
  "icebreakers": {
    "0": "Hi! Want to practice languages together?",
    "1": "I noticed we're learning similar languages — hi!",
    "2": "Your profile caught my eye, how's it going?",
    "3": "Hey! What made you start learning a new language?"
  }
}
```

`WaveSheet.test.tsx` — add after the `react-toastify` mock, so the English assertions keep reading real copy:

```tsx
// Resolve keys from eng.json (with {{name}} interpolation): the assertions
// below read what an English reader sees, and a missing key shows up as the
// raw key instead of quietly falling back.
jest.mock("react-i18next", () => {
  const eng = require("../../utils/locales/eng.json");
  const lookup = (key: string) =>
    key.split(".").reduce((node: any, part: string) => (node && typeof node === "object" ? node[part] : undefined), eng);
  return {
    useTranslation: () => ({
      t: (key: string, vars?: any) => {
        const raw = lookup(key);
        if (typeof raw !== "string") return key;
        return raw.replace(/{{\s*(\w+)\s*}}/g, (_: string, name: string) =>
          vars && vars[name] != null ? String(vars[name]) : ""
        );
      },
    }),
  };
});
```

- [ ] **Step 4: Run → PASS**

Run: `cd /Users/davis/Desktop/Personal/wt-web-p3-community && CI=true npm test -- --watchAll=false communityCopy WaveSheet MainCommunity SuggestedMembers ProfilePage`
Expected: PASS — the WaveSheet tests still find "Send a wave to Bob", "You already waved at Bob", "👋" and
"Daily wave limit reached", now through eng.json.

- [ ] **Step 5: Commit** (tick `P3-COM-13`; the 17-locale translation of every key below is the unit's translation
  step, not this commit)

```bash
git add src/components/community/WaveSheet.tsx src/components/community/WaveSheet.test.tsx \
  src/components/community/communityCopy.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(community): wave sheet copy through t(), and a key-existence test

The wave sheet's title, chips, icebreakers, buttons and toasts were
hard-coded English, and its "sent" toast used community.waves.sentTo,
which can never resolve because "community" is a string in eng.json. All
of it now goes through waves.sheet.*. A test scans the community surfaces
for literal t() keys and fails on any key missing from eng.json or hanging
under a string parent.

Still open (Phase 3 community): translations of the new community keys
into the 17 other locales (unit translation step); ActiveFilterChips and
MemberCard copy.
EOF
```

---

#### Keys added by P3-COM-*

| Key | English |
|---|---|
| `communityNearby.title` | Nearby Users |
| `communityNearby.subtitle` | Find people around you |
| `communityNearby.back` | Back |
| `communityNearby.geolocationNotSupported` | Geolocation is not supported |
| `communityNearby.permissionDenied` | Location permission denied |
| `communityNearby.positionUnavailable` | Location unavailable |
| `communityNearby.timeout` | Location request timed out |
| `communityNearby.unknownError` | An error occurred |
| `communityNearby.gettingLocation` | Getting your location... |
| `communityNearby.locationRequired` | Location Required |
| `communityNearby.tryAgain` | Try Again |
| `communityNearby.searchRadius` | Search Radius |
| `communityNearby.usersFound_one` | {{count}} person found |
| `communityNearby.usersFound_other` | {{count}} people found |
| `communityNearby.refresh` | Refresh |
| `communityNearby.noUsers` | No users found nearby |
| `communityNearby.tryIncreaseRadius` | Try increasing the search radius |
| `communityNearby.learning` | Learning: {{language}} |
| `waves.subtitle` | People who waved at you |
| `waves.back` | Back |
| `waves.noReceived` | No waves received yet |
| `waves.findPeople` | Find People |
| `waves.archive` | Older waves |
| `waves.recent` | Last 7 days |
| `waves.archiveHint` | Waves from 7 to 30 days ago |
| `waves.archiveEmpty` | No older waves |
| `waves.someone` | Someone |
| `waves.wavedAtYou` | Waved at you 👋 |
| `waves.unread` | Unread |
| `waves.cap.title` | Daily wave limit reached |
| `waves.cap.body` | You've used today's free waves. VIP members can wave without a daily limit, or try again tomorrow. |
| `waves.cap.seeVip` | See VIP |
| `waves.cap.notNow` | Not now |
| `waves.sheet.title` | Send a wave to {{name}} |
| `waves.sheet.subtitle` | Say hi and break the ice 👋 |
| `waves.sheet.close` | Close |
| `waves.sheet.cancel` | Cancel |
| `waves.sheet.send` | Send wave |
| `waves.sheet.already` | Already waved |
| `waves.sheet.alreadyTitle` | You already waved at {{name}} |
| `waves.sheet.alreadyBody` | You can only wave once per person — send them a message instead to keep the conversation going. |
| `waves.sheet.quickReplies` | Quick replies |
| `waves.sheet.icebreakersTitle` | Icebreakers |
| `waves.sheet.yourMessage` | Your message |
| `waves.sheet.placeholder` | Write a custom message (optional)… |
| `waves.sheet.sent` | Wave sent to {{name}}! |
| `waves.sheet.match` | 🎉 It's a match! You and {{name}} both waved at each other. |
| `waves.sheet.sendError` | Failed to send wave |
| `waves.sheet.chips.{hi,cool,hey,chat,hello,nice}.label` | Hi / Cool / Hey / Chat / Hello / Nice |
| `waves.sheet.chips.{hi,cool,hey,chat,hello,nice}.message` | 👋 Hi! / ❤️ Cool profile! / 😊 Hey there! / 🎉 Let's chat! / ✋ Hello! / 🌟 Nice to meet you! |
| `waves.sheet.icebreakers.0`–`.3` | the four icebreaker sentences (P3-COM-13) |
| `communityMain.tabs.serious` | Serious learners |
| `communityMain.tabs.seriousHint` | Active this week |
| `communityMain.filterSheet.reciprocal` | Perfect partners only |
| `communityMain.filterSheet.reciprocalHint` | They speak what you learn and learn what you speak |
| `communityMain.today.waved` | Waved |
| `profile.photos.openStory` | View {{name}}'s story |
| `profile.actions.followBlocked` | You can't follow this person |
| `profile.blocked.title` | This profile isn't available |
| `profile.blocked.body` | One of you has blocked the other, so you can't message, follow or see each other's posts. |
| `profile.blocked.manage` | Manage blocked people |
| (P3-COM-13 Step 2) | any pre-existing community key the scan finds missing — add with its fallback text |


### Task P3-COM-I18N: The community unit's new strings in all 18 locales

**Files:**
- Create if missing in this branch (verbatim copy from P3-CHAT-I18N): `scripts/i18n/new-keys.js`, `src/utils/locales/p3Keys.test.ts`
- Create: `scripts/i18n/keys/2026-10-16-p3-community.json` (all 18 locales; the durable record of what this unit translated)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: every English string the unit's tasks added to `eng.json` — listed in the key table at the end of P3-COM-13 (`#### Keys added by P3-COM-*`). The script below finds them from the diff against `web/p3-base`, so a key a task added but forgot to list is still caught.
- Produces: no English-only key in this unit's push.

Tooling and translation rules: as in Task P3-CHAT-I18N (copy `scripts/i18n/new-keys.js` and `src/utils/locales/p3Keys.test.ts` verbatim if this branch does not have them yet).

- [ ] **Step 1: Write the failing test** (copy the guard if missing) and generate the keys file

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-community
node scripts/i18n/new-keys.js web/p3-base scripts/i18n/keys/2026-10-16-p3-community.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: the script prints `N new or changed keys` (N matches the unit's key tables, give or take keys a task added beyond its table); the test FAILS with `<key>: missing` for each of the 17 non-English locales.

- [ ] **Step 2: Translate**

Fill every `""` in `scripts/i18n/keys/2026-10-16-p3-community.json` for the 17 non-English locales (rules above). Re-running `new-keys.js` keeps what is already filled.

- [ ] **Step 3: Merge into the locale files**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p3-community.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: all `p3Keys` cases pass; the existing `src/utils/i18n*.test.ts` suites stay green (locale chunks still parse).

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/keys/2026-10-16-p3-community.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
i18n(community): translate the Phase 3 community strings into all 18 locales

Keys found by scripts/i18n/new-keys.js against web/p3-base and merged
with merge-keys.js; p3Keys.test.ts fails on any missing, empty or
placeholder-mismatched translation.

Still open (Phase 3 community): push gate (P3-COM-PUSH); native review of
the new strings.
EOF
```

---
### Task P3-COM-PUSH: Push unit COM (3 of 4) — full suite + build green, then the coordinator pushes

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status line, §6 changelog line, §3 production-QA lines for the smoke list below)

- [ ] **Step 1: Every task in the unit is committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-community
git status --short                                   # expect: nothing (except the node_modules symlink, untracked)
grep -n "P3-COM-" docs/REMAINING_WORK.md | grep -c "\[ \]"   # expect: 1 (this PUSH line only)
```

- [ ] **Step 2: Rebase onto the live site**

```bash
git fetch origin
git rebase origin/main
```
Conflicts: locale files and `docs/REMAINING_WORK.md` (keep both; re-run merge-keys with `scripts/i18n/keys/2026-10-16-p3-community.json`), `src/components/chat/NewChat.tsx` (CHAT removed `createChatRoom`; keep CHAT's file and re-apply P3-COM-2's one-line username-length guard), `src/store/slices/usersSlice.ts` (keep MOMENTS' `invalidatesTags` and your username URLs), the shared i18n tooling (take `origin/main`).
After resolving: `git rebase --continue`, then re-run `CI=true npm test -- --watchAll=false p3Keys` (keys from earlier units must still be complete).

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `Test Suites: … 0 failed`, `Tests: … 0 failed`; passed count ≥ the previous push's count plus this unit's new tests (baseline before Phase 3: 3190 passed, 6 skipped). Any failure: fix in a new commit (never `--no-verify`, never skip a test to get green).

- [ ] **Step 4: Production build**

```bash
npm run build 2>&1 | tail -20
```
Expected: `Compiled successfully` or `Compiled with warnings` with **no** TypeScript error (TS 3.7 rejects newer syntax here first), then the prerender step finishes without an error line. Optional: `npm run test:budget` and note the first-paint size in the tracker (the budget is already over by ~5 KB; not a gate).

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P3-COM-PUSH`; §1 Status: "Phase 3 community pushed (YYYY-MM-DD)"; §6 Done: one line naming the unit's fixes; §3 Production QA: one `- [ ]` line per smoke item below that is not yet checked.

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: Phase 3 community ready to deploy

Still open (Phase 3): the remaining units' tasks; production smoke
for community (docs/REMAINING_WORK.md §3); device QA rows.
EOF
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p3-community:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/            # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1   # a new bundle hash
```

- [ ] **Step 7: Production smoke (two accounts: one on the web, one in app 2.6.1)**

  - [ ] Community → Nearby with location allowed → people with distances; tapping one opens `/community/<id>`; someone with "show city" off shows no city.
  - [ ] New chat → type `@ab` → matching usernames appear.
  - [ ] Filter by Uzbek, Arabic, Vietnamese → results; labels are in the UI language.
  - [ ] Waves: archive toggle shows 7–30-day waves; avatars load; empty state "Find people" opens `/communities`.
  - [ ] Serious tab lists people active this week; with `SMART_SORT_ENABLED` on, the first request carries `sort=smart`.
  - [ ] Today: wave at a card → it shows "Waved"; tapping again does not error.
  - [ ] Signed out, open `https://banatalk.com/profile/<id>` → follower and following counts show numbers (not 0) after Phase 1 is deployed.
  - [ ] Block someone in the app, open their web profile → neutral card, no Follow/Message.

Record results in `docs/REMAINING_WORK.md` §3 in the next unit's first commit (or a docs-only commit if this is the last unit). A failure that breaks a live flow → Step 8.

- [ ] **Step 8 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p3-community-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -40
CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(The unit is a linear series after the rebase, so the range revert is clean. Note the revert in §6 and reopen the tasks.)

---

## Unit LINKS (push 4 of 4) — P3-LINK-1 … P3-LINK-7, P3-LINK-I18N, P3-LINK-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p3-links`, branch `web/p3-links` (from `web/p3-base`). Tasks 1–6 can be
built in parallel with the other units; P3-LINK-7 needs CHAT's `useOpenStoryFromChat` (rebase onto `origin/main` after the
CHAT push first). The nginx rule is written here and applied by the owner in Phase 5; `/story/*` is **not** claimed in the
AASA (owner step once 2.7.0 is most of the iOS base).

### Unit facts (LINKS) — read before P3-LINK-1

- Worktree: `/Users/davis/Desktop/Personal/wt-web-p3-links`, branch `web/p3-links`, off `web/p3-base` (Task P3-0).
  All line numbers are from fba6208; anchor every edit on the quoted code.
- Backend facts this unit relies on (checked in `be-integration`):
  - `GET /og/:type/:id` (`routes/og.js`, mounted outside `/api/v1`) knows `moment`, `profile`, `community`, `user`
    (`controllers/og.js` `USER_OG_TYPES`). **There is no `story` type.** An unknown type returns the generic
    BananaTalk card with status 200 (`getOg`, the `else` branch), which carries the same tags the SPA shell already
    carries. So routing `/story/<id>` previews through it loses nothing today and lights up the day the backend adds
    a `story` type (backend follow-up, written into this repo's REMAINING_WORK by P3-LINK-1; not planned here).
    `i` comes with backend P1-LINK-2; until that is deployed `/og/i/<code>` is the generic card too.
  - `GET /api/v1/stories/:id` (`routes/story.js:111-112`) is `protect`ed: **signed-out viewers get 401**. It answers
    404 for a missing, inactive or expired story (`controllers/stories.js:952-960`) and the `storyAccessError` status
    (403 for blocked / not-a-friend / not-close-friend) otherwise. 200 is `{ success, data: <story with populated user> }`.
  - `POST /api/v1/auth/google/exchange {code}` → 200 `{ success, token, refreshToken, user }`, 400
    `{ code: 'OAUTH_CODE_INVALID' }`, 403 `ACCOUNT_BANNED` (master plan P1-LINK-5). The callback redirect carries
    `?code=` **and** the legacy `?token=` until this web release is live; refusals redirect with `?error=&reason=`
    (`EMAIL_EXISTS | BANNED | GOOGLE_FAILED`).
- App facts: 2.6.1's parser (`app lib/services/deep_link_parser.dart:11`) accepts `moment`, `profile`, `community`
  and `i`; anything else returns `null` and `deep_link_service.dart:49-50` ignores it (the app just opens). `story`
  and `chat` arrive with 2.7.0 (Phase 2). `card` is never parsed — a card is a person, so it maps to `profile`.

---

### Task P3-LINK-1: Crawler rule sends link-preview bots to the backend OG cards (links#4, links#17, moments#13)

**Files:**
- Modify: `deploy/nginx.snippet.conf` (new block between the `/app.html` location, line 25, and `# Dead URLs with a successor.`, line 27)
- Modify: `README.md` (`### nginx` section, after the paragraph ending "…will be caught only by the test.", line 34)
- Modify: `docs/REMAINING_WORK.md` (§2 owner step, §4 backend follow-up line)
- Test (new): `src/seo/prerender/nginxSnippet.test.ts`

**Interfaces:**
- Consumes: backend `GET https://api.banatalk.com/og/<moment|profile|community|story|i>/<id>` (public HTML; 200 card, 404 generic card).
- Produces: nothing in code. The owner applies the snippet in Phase 5 (`docs/ops/2026-10-16-web-hosting-steps.md`).
  Until then production behaves exactly as today.

Design (why it looks like this):
- The snippet is `include`d inside `server { }`. `map` is only valid in `http { }`, so a UA `map` would need a second
  file the owner places elsewhere. Instead each preview location uses `if ($http_user_agent ~* …) { rewrite … last; }`.
  `rewrite … last` inside `if` is one of the two uses nginx documents as safe in a location.
- The `if` regex match **overwrites `$1`/`$2`**, so the location captures are copied with `set` first.
- `proxy_pass` with variables needs a `resolver`; it is set inside the internal location.
- Only link-preview fetchers are listed. Search crawlers (Googlebot, Bingbot, Applebot) render JavaScript and must
  keep indexing the real page. In-app browsers (Facebook `FBAN`, `LinkedInApp`, Telegram's in-app view) carry none
  of the listed tokens.
- Ids are matched strictly (24-hex, invite code 4–32 alphanumerics), so `/community/nearby` and `/profile/edit`
  never reach the OG endpoint.
- Upstream down or slow (5xx, 3 s connect, 5 s read) → the bot gets the SPA shell, i.e. today's generic card.
  A 404 from the OG endpoint (deleted moment) passes through with its own generic HTML.
- These locations must come **before** `include …/nginx.routes.conf`: nginx uses the first regex location that
  matches, and the generated routes regex also matches `/moment/…`.

- [ ] **Step 1: Write the failing test** `src/seo/prerender/nginxSnippet.test.ts`

```ts
/**
 * @jest-environment node
 */
import fs from "fs";
import path from "path";

/**
 * deploy/nginx.snippet.conf is applied by hand on the droplet (README "nginx"),
 * so nothing but this test notices when an edit breaks it. Link previews
 * (links#4): chat apps and social sites fetch a shared banatalk.com link once,
 * run no JavaScript, and so only ever saw the homepage's tags. The snippet now
 * sends those fetchers to the backend's real cards at api.banatalk.com/og/.
 */
const raw = fs.readFileSync(path.resolve(__dirname, "../../../deploy/nginx.snippet.conf"), "utf8");
// Comments stripped, so prose can never satisfy an assertion.
const conf = raw
  .split("\n")
  .map((line) => line.replace(/#.*$/, ""))
  .join("\n");

interface Loc { regex: RegExp; source: string; body: string; at: number }

/** Every `location ~ <regex> { ... }` block (one level of nested braces). */
function regexLocations(): Loc[] {
  const out: Loc[] = [];
  const re = /location ~(\*?) (\S+) \{((?:[^{}]|\{[^{}]*\})*)\}/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(conf))) {
    out.push({ regex: new RegExp(m[2], m[1] ? "i" : ""), source: m[2], body: m[3], at: m.index });
  }
  return out;
}

/** The UA alternations used by the bot `if`s (nginx `~*` = case-insensitive PCRE). */
function botRegexes(): RegExp[] {
  const out: RegExp[] = [];
  const re = /if \(\$http_user_agent ~\* "([^"]+)"\)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(conf))) out.push(new RegExp(m[1], "i"));
  return out;
}

const HEX = "507f1f77bcf86cd799439011";
const PREVIEW_PATHS = [`/moment/${HEX}`, `/profile/${HEX}`, `/community/${HEX}`, `/story/${HEX}`, "/i/ABCD2345"];
const botLocationFor = (p: string) => regexLocations().find((l) => l.regex.test(p) && /http_user_agent/.test(l.body));

describe("link-preview crawler rule", () => {
  it("covers all five shareable link types, with or without a trailing slash", () => {
    for (const p of PREVIEW_PATHS) {
      expect(botLocationFor(p)).toBeTruthy();
      expect(botLocationFor(`${p}/`)).toBeTruthy();
    }
  });

  it("never sends web-only pages that share a prefix to the OG endpoint", () => {
    for (const p of ["/community/nearby", "/profile/edit", `/profile/${HEX}/followers`, "/moments/saved", "/moment/"]) {
      expect(botLocationFor(p)).toBeUndefined();
    }
  });

  it("sits before the generated routes include and before location /", () => {
    const first = Math.min(...PREVIEW_PATHS.map((p) => botLocationFor(p)!.at));
    expect(first).toBeLessThan(conf.indexOf("nginx.routes.conf"));
    expect(first).toBeLessThan(conf.indexOf("location / {"));
  });

  it("copies the location captures before the UA if (the if's match overwrites $1/$2)", () => {
    for (const p of PREVIEW_PATHS) {
      const body = botLocationFor(p)!.body;
      expect(body.indexOf("set $og_id")).toBeGreaterThanOrEqual(0);
      expect(body.indexOf("set $og_id")).toBeLessThan(body.indexOf("if ("));
      expect(body).toMatch(/rewrite \^ \/__og\/[^ ]+ last;/);
      expect(body).not.toMatch(/rewrite[^;]*\$[12]/);
      // Humans still get the app exactly as the generated routes conf serves it.
      expect(body).toContain("try_files $uri $uri/index.html /app.html;");
    }
  });

  it("matches link-preview fetchers and nothing a person or a search engine uses", () => {
    const bots = botRegexes();
    expect(bots.length).toBeGreaterThan(0);
    const isBot = (ua: string) => bots.every((re) => re.test(ua));
    for (const ua of [
      "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)",
      "facebookexternalhit/1.1 Facebot Twitterbot/1.0", // iMessage
      "Twitterbot/1.0",
      "Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)",
      "kakaotalk-scrap/1.0; +https://devtalk.kakao.com/t/scrap/33984",
      "WhatsApp/2.23.20.0 A",
      "Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)",
      "LinkedInBot/1.0 (compatible; Mozilla/5.0; Apache-HttpClient +http://www.linkedin.com)",
      "TelegramBot (like TwitterBot)",
    ]) {
      expect(isBot(ua)).toBe(true);
    }
    for (const ua of [
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) [FBAN/FBIOS;FBAV/450.0]",
      "Mozilla/5.0 (Linux; Android 14) LinkedInApp/9.29",
      "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
      "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
      "Mozilla/5.0 (Macintosh) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17 Safari/605.1.15 (Applebot/0.1)",
    ]) {
      expect(isBot(ua)).toBe(false);
    }
  });

  it("proxies the internal /__og/ location to the backend card over TLS, with short timeouts and an SPA fallback", () => {
    const og = regexLocations().find((l) => l.source.indexOf("__og") >= 0);
    expect(og).toBeTruthy();
    const b = og!.body;
    expect(b).toMatch(/^\s*internal;/m);
    expect(b).toContain("proxy_pass https://api.banatalk.com/og/$1/$2;");
    expect(b).toContain("proxy_set_header Host api.banatalk.com;");
    expect(b).toContain("proxy_ssl_server_name on;");
    expect(b).toMatch(/resolver \S+/); // proxy_pass with variables needs one
    expect(b).toMatch(/proxy_connect_timeout \d+s;/);
    expect(b).toMatch(/proxy_read_timeout \d+s;/);
    expect(b).toContain("proxy_intercept_errors on;");
    expect(b).toMatch(/error_page 500 502 503 504 = @og_fallback;/);
    expect(conf).toMatch(/location @og_fallback \{\s*try_files \/app\.html =404;\s*\}/);
    for (const type of ["moment", "profile", "community", "story", "i"]) {
      expect(og!.regex.test(`/__og/${type}/abc123`)).toBe(true);
    }
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links && CI=true npm test -- --watchAll=false nginxSnippet
```
Expected: FAIL. Every test except none: `botLocationFor` finds nothing ("expected undefined to be truthy"), `botRegexes()` is empty, no `__og` location.

- [ ] **Step 3: Implement** — `deploy/nginx.snippet.conf`. After these lines (22–25):

```nginx
error_page 404 /404.html;
location = /404.html { internal; }
# The SPA shell app routes fall back to (see build/nginx.routes.conf). Internal
# only: nobody should land on an empty shell by typing /app.html.
location = /app.html { internal; }
```
insert:

```nginx

# Link previews. Chat apps and social sites fetch a shared link once to draw
# its card. They run no JavaScript, so on the SPA they only ever saw the
# homepage's tags. The backend renders the real card at
# https://api.banatalk.com/og/<type>/<id> (controllers/og.js): these locations
# send link-preview fetchers there and everyone else to the app, as before.
#
# - `if` and not `map`: this file is included inside `server { }`, and `map`
#   is only valid in `http { }`. `if` holding nothing but `rewrite ... last` is
#   one of the two uses nginx documents as safe inside a location.
# - `set` first: the `if` regex match overwrites $1/$2.
# - Only preview fetchers are listed. Search crawlers (Googlebot, Bingbot,
#   Applebot) render JavaScript and must index the real page. In-app browsers
#   (FBAN, LinkedInApp, Telegram's viewer) carry none of these tokens.
# - Strict ids, so /community/nearby and /profile/edit never reach /og/.
# - `story` has no backend OG type yet: /og/story/<id> returns the generic
#   card, the same tags the SPA shell carries. `i` needs backend P1-LINK-2.
# - MUST stay above the `include ... nginx.routes.conf` below: nginx uses the
#   first regex location that matches, and that one matches /moment/... too.
location ~ ^/(moment|profile|community|story)/([0-9a-fA-F]{24})/?$ {
  set $og_type $1;
  set $og_id $2;
  if ($http_user_agent ~* "(facebookexternalhit|Facebot|Twitterbot|Slackbot|kakaotalk-scrap|WhatsApp|Discordbot|LinkedInBot|TelegramBot|SkypeUriPreview|vkShare|Pinterestbot|redditbot|Embedly|Iframely|Viber|Mastodon|Bluesky)") {
    rewrite ^ /__og/$og_type/$og_id last;
  }
  try_files $uri $uri/index.html /app.html;
}
location ~ ^/i/([A-Za-z0-9]{4,32})/?$ {
  set $og_id $1;
  if ($http_user_agent ~* "(facebookexternalhit|Facebot|Twitterbot|Slackbot|kakaotalk-scrap|WhatsApp|Discordbot|LinkedInBot|TelegramBot|SkypeUriPreview|vkShare|Pinterestbot|redditbot|Embedly|Iframely|Viber|Mastodon|Bluesky)") {
    rewrite ^ /__og/i/$og_id last;
  }
  try_files $uri $uri/index.html /app.html;
}
location ~ ^/__og/(moment|profile|community|story|i)/([A-Za-z0-9]+)$ {
  internal;
  resolver 1.1.1.1 8.8.8.8 valid=300s ipv6=off;
  resolver_timeout 2s;
  proxy_pass https://api.banatalk.com/og/$1/$2;
  proxy_set_header Host api.banatalk.com;
  proxy_set_header User-Agent $http_user_agent;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_ssl_server_name on;
  proxy_connect_timeout 3s;
  proxy_read_timeout 5s;
  # Backend down or slow: the bot gets the SPA shell (today's generic card).
  # A 404 (deleted moment) passes through with the backend's own generic HTML.
  proxy_intercept_errors on;
  error_page 500 502 503 504 = @og_fallback;
}
location @og_fallback {
  try_files /app.html =404;
}
```

`README.md`, after the paragraph that ends "…will be caught only by the test." (line 34), add:

```markdown
#### Link previews

The snippet also sends link-preview fetchers (Facebook/iMessage, KakaoTalk, WhatsApp, Telegram, Slack, Discord, X, LinkedIn …) on `/moment|profile|community|story/<id>` and `/i/<code>` to `https://api.banatalk.com/og/<type>/<id>`, so a shared link unfurls with its own title and picture instead of the homepage card. Search crawlers are not on the list and keep getting the real page. Those locations must stay **above** the `include … nginx.routes.conf` line. Check after a reload:

    curl -s -A "facebookexternalhit/1.1" https://banatalk.com/moment/<id> | grep og:title   # the moment's text
    curl -s https://banatalk.com/moment/<id> | grep -c 'id="root"'                         # 1: people still get the app
```

`docs/REMAINING_WORK.md`, §2 Owner, add as step 3:

```markdown
3. Phase 5: apply the link-preview locations in `deploy/nginx.snippet.conf` (they must sit above the `nginx.routes.conf` include), `nginx -t`, reload, then run the two `curl` checks in README "Link previews". Previews in KakaoTalk / Telegram / WhatsApp are rows in the app's `docs/qa/regression-suite.csv` (Web area).
```
and in §4 under "Web/app parity", add: `- [ ] Backend follow-up: an OG type for `story` (`/og/story/:id` returns the generic card today; the nginx rule already routes it). S`

- [ ] **Step 4: Run → PASS** (same command).

- [ ] **Step 5: Commit** (tick `P3-LINK-1`)

```bash
git add deploy/nginx.snippet.conf README.md src/seo/prerender/nginxSnippet.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(deploy): send link-preview bots to the backend OG cards

Shared banatalk.com links always unfurled as the homepage card: preview
fetchers run no JavaScript and the backend's real cards at
api.banatalk.com/og/<type>/<id> were unreachable from banatalk.com URLs.
The nginx snippet now rewrites preview user agents on moment, profile,
community, story and invite links to an internal location that proxies
the card, with strict ids, short timeouts and an SPA fallback. Search
crawlers and people are unaffected. The owner applies it in Phase 5.

Still open (Phase 3 links): AASA excludes and /chat/* removal, per-page
smart banner and app banner, /story/:id page, Google code exchange,
http links on legal pages; owner applies the snippet; backend story OG type.
EOF
```

---

### Task P3-LINK-2: AASA stops claiming `/chat/*` and web-only pages (links#6, links#15)

**Files:**
- Modify: `public/.well-known/apple-app-site-association`
- Modify: `src/seo/appLinks.test.ts:28-33` (replace the "claims every path type" test)

**Interfaces:**
- Consumes: Apple's AASA component rules — the first matching component decides; `"exclude": true` un-claims;
  `*` matches any run of characters including `/`.
- Produces: iOS opens the browser (the web page) for `/chat/*`, `/profile/edit`, `/profile/<id>/followers|following`,
  `/community/nearby`. `/story/*` and `/chat/*` are **not** claimed: claiming them is the Phase 5 owner step once
  2.7.0 is most of the iOS base (2.6.1 drops both). The Android manifest side is Phase 2 (app).

- [ ] **Step 1: Write the failing test** — in `src/seo/appLinks.test.ts`, replace

```ts
  it("claims every path type the app can route", () => {
    const paths = detail.components.map((c: any) => c["/"]).sort();
    expect(paths).toEqual(["/chat/*", "/community/*", "/i/*", "/moment/*", "/profile/*"]);
  });
```
with

```ts
  // Claimed: only what app 2.6.1's parser routes. /chat/* and /story/* are
  // added back by the owner (Phase 5) once 2.7.0 -- which parses both -- is
  // most of the iOS base; 2.6.1 opens and drops them.
  it("claims exactly the path types app 2.6.1 routes", () => {
    const claimed = detail.components.filter((c: any) => !c.exclude).map((c: any) => c["/"]).sort();
    expect(claimed).toEqual(["/community/*", "/i/*", "/moment/*", "/profile/*"]);
    const all = detail.components.map((c: any) => c["/"]);
    expect(all).not.toContain("/chat/*");
    expect(all).not.toContain("/story/*");
  });

  // links#15: /profile/edit etc. opened the app, which read "edit" as a user id.
  // Every web route under a claimed prefix that is not the detail page itself
  // must be excluded -- derived from the router, so a new web-only page under
  // /profile/ or /community/ fails here until it is excluded too.
  it("excludes every web-only page under a claimed prefix, before the wildcard", () => {
    const { routes } = require("../router/routes");
    const DETAIL = ["moment/:id", "profile/:userId", "community/:userId", "i/:code"];
    const webOnly: string[] = (routes[0].children || [])
      .map((c: any) => c.path)
      .filter((p: any) => typeof p === "string" && /^(moment|profile|community|i)\//.test(p) && DETAIL.indexOf(p) < 0)
      .map((p: string) => "/" + p.replace(/:[A-Za-z]+/g, "*"));
    expect(webOnly.sort()).toEqual(["/community/nearby", "/profile/*/followers", "/profile/*/following", "/profile/edit"]);

    const paths: string[] = detail.components.map((c: any) => c["/"]);
    for (const p of webOnly) {
      const i = paths.indexOf(p);
      expect(i).toBeGreaterThanOrEqual(0);
      expect(detail.components[i].exclude).toBe(true);
      const wildcard = paths.indexOf("/" + p.split("/")[1] + "/*");
      expect(i).toBeLessThan(wildcard);
    }
  });

  // Apple's matching, simplified: the first component whose pattern matches decides.
  it("resolves real links the way iOS will", () => {
    const toRe = (p: string) => new RegExp("^" + p.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".") + "$");
    const opensApp = (url: string) => {
      const hit = detail.components.find((c: any) => toRe(c["/"]).test(url));
      return Boolean(hit && !hit.exclude);
    };
    const id = "507f1f77bcf86cd799439011";
    expect(opensApp(`/moment/${id}`)).toBe(true);
    expect(opensApp(`/profile/${id}`)).toBe(true);
    expect(opensApp(`/community/${id}`)).toBe(true);
    expect(opensApp("/i/ABCD2345")).toBe(true);
    expect(opensApp("/profile/edit")).toBe(false);
    expect(opensApp(`/profile/${id}/followers`)).toBe(false);
    expect(opensApp(`/profile/${id}/following`)).toBe(false);
    expect(opensApp("/community/nearby")).toBe(false);
    expect(opensApp(`/chat/${id}`)).toBe(false);
    expect(opensApp(`/story/${id}`)).toBe(false);
  });
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links && CI=true npm test -- --watchAll=false appLinks
```
Expected: FAIL. "claims exactly" gets `/chat/*` in the list. "excludes every web-only page" finds no `/community/nearby` component (index -1). "resolves real links" fails on `/profile/edit` (true) and `/chat/<id>` (true).

- [ ] **Step 3: Implement** — replace `public/.well-known/apple-app-site-association` with:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["RJF4T5CJ76.com.bananatalk.bananatalkApp"],
        "components": [
          { "/": "/profile/edit", "exclude": true, "comment": "web-only: edit your profile" },
          { "/": "/profile/*/followers", "exclude": true, "comment": "web-only list page" },
          { "/": "/profile/*/following", "exclude": true, "comment": "web-only list page" },
          { "/": "/community/nearby", "exclude": true, "comment": "web-only page" },
          { "/": "/moment/*" },
          { "/": "/profile/*" },
          { "/": "/community/*" },
          { "/": "/i/*" }
        ]
      }
    ]
  }
}
```
(Apple caches the file through its CDN for up to a day or two; that is expected.)

- [ ] **Step 4: Run → PASS** (same command).

- [ ] **Step 5: Commit** (tick `P3-LINK-2`)

```bash
git add public/.well-known/apple-app-site-association src/seo/appLinks.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(links): AASA drops /chat/* and excludes web-only pages

iOS opened the app for banatalk.com/chat/<id>, which app 2.6.1 silently
drops, and for /profile/edit, /profile/<id>/followers|following and
/community/nearby, which the app read as user ids. Those links now stay
in the browser. /chat/* and /story/* come back as a Phase 5 owner step
once 2.7.0 is most of the iOS base. A test derives the web-only pages
from the router so a new one cannot be claimed by accident.

Still open (Phase 3 links): per-page smart banner and app banner,
/story/:id page, Google code exchange, http links on legal pages; owner
applies the nginx snippet; Phase 5 re-adds /story/* and /chat/*.
EOF
```

---

### Task P3-LINK-3: Smart banner and app banner open the page being viewed (links#16)

**Files:**
- Create: `src/components/linking/smartBanner.ts`, test `src/components/linking/smartBanner.test.ts`
- Modify: `public/index.html:68-69` (meta + inline script, drop `google-play-app`)
- Modify: `src/components/linking/openInAppAction.ts` (new `AppLinkType`, `card` → `profile`)
- Modify: `src/components/linking/OpenInApp.tsx` (prop type)
- Modify: `src/components/linking/AppBanner.tsx` (patterns for `/story/:id`, `/i/:code`, `/card/:userId`; keeps the smart-banner tag in step with client navigation)
- Test: `src/components/linking/AppBanner.test.tsx`, `src/components/linking/openInAppAction.test.ts`

**Interfaces:**
- Produces: `smartBannerArgument(pathname: string): string`, `setSmartBannerArgument(pathname: string, doc?: Document): void`,
  `SMART_BANNER_APP_ID = "6755862146"` (smartBanner.ts); `type AppLinkType = ShareType | 'i' | 'story'` and
  `appSchemeUrl(type: AppLinkType, id)` (openInAppAction.ts). P3-LINK-4 renders `<OpenInApp type="story" id=… />`.
- Consumes: app parser (2.6.1: moment/profile/community/i; 2.7.0 adds story).

Decisions:
- **Story deep link = `bananatalk://story/<id>`.** 2.7.0 opens the story. 2.6.1's parser returns `null` and the app
  just opens, which is what the static banner did anyway. The alternative (the author's profile) needs a signed-in
  fetch to learn the author and is wrong for 2.7.0, so it is rejected.
- **Card → profile**: the app has no `card` route; `LanguageCard.tsx:131-134` already opens `profile`.
- **Smart banner**: Safari reads `apple-itunes-app` from the document. Direct loads of `/moment/<id>` come from the
  SPA shell (`app.html`), so a React Helmet tag would arrive after Safari has read the static one. An inline script
  right after the meta rewrites `app-argument` during parsing; `AppBanner` keeps it in step on client navigation
  (whether Safari re-reads it after load is unverified — device QA row). Prerendered pages keep the same script; the
  template (`src/seo/prerender/template.ts` `REPLACED_HEAD_TAGS`) does not touch this tag.
- `google-play-app` is dropped: Chrome ignores it; the in-page `AppBanner` covers Android.

- [ ] **Step 1: Write the failing tests**

`src/components/linking/smartBanner.test.ts` (new):

```ts
import fs from "fs";
import path from "path";
import { smartBannerArgument, setSmartBannerArgument, SMART_BANNER_APP_ID } from "./smartBanner";

const HEX = "507f1f77bcf86cd799439011";
const ROOT = "https://banatalk.com/";

const TABLE: [string, string][] = [
  ["/", ROOT],
  ["/moments", ROOT],
  [`/moment/${HEX}`, `${ROOT}moment/${HEX}`],
  [`/moment/${HEX}/`, `${ROOT}moment/${HEX}`],
  [`/profile/${HEX}`, `${ROOT}profile/${HEX}`],
  [`/community/${HEX}`, `${ROOT}community/${HEX}`],
  [`/story/${HEX}`, `${ROOT}story/${HEX}`],
  [`/card/${HEX}`, `${ROOT}profile/${HEX}`], // the app has no card route
  ["/i/ABCD2345", `${ROOT}i/ABCD2345`],
  ["/profile/edit", ROOT],
  ["/community/nearby", ROOT],
  [`/profile/${HEX}/followers`, ROOT],
  ["/i/a b", ROOT],
  ["/chat/" + HEX, ROOT], // 2.6.1 drops chat links
];

describe("smartBannerArgument", () => {
  it.each(TABLE)("%s -> %s", (p, expected) => {
    expect(smartBannerArgument(p)).toBe(expected);
  });
});

describe("setSmartBannerArgument", () => {
  it("rewrites the existing tag and leaves the app id alone", () => {
    document.head.innerHTML = `<meta name="apple-itunes-app" content="app-id=${SMART_BANNER_APP_ID}, app-argument=${ROOT}">`;
    setSmartBannerArgument(`/moment/${HEX}`);
    expect(document.querySelector('meta[name="apple-itunes-app"]')!.getAttribute("content"))
      .toBe(`app-id=${SMART_BANNER_APP_ID}, app-argument=${ROOT}moment/${HEX}`);
  });

  it("does nothing when the tag is missing", () => {
    document.head.innerHTML = "";
    expect(() => setSmartBannerArgument("/")).not.toThrow();
  });
});

// The same rule runs as an inline script in public/index.html, because Safari
// reads the tag while parsing -- before any bundle runs. The two copies must agree.
describe("public/index.html", () => {
  const html = fs.readFileSync(path.resolve(__dirname, "../../../public/index.html"), "utf8");
  const script = (html.match(/<script id="smart-banner-argument">([\s\S]*?)<\/script>/) || [])[1];

  it("has one smart-banner tag, the inline script right after it, and no google-play-app tag", () => {
    expect(html.match(/name="apple-itunes-app"/g)).toHaveLength(1);
    expect(html).not.toContain("google-play-app");
    expect(script).toBeTruthy();
    expect(html.indexOf('id="smart-banner-argument"')).toBeGreaterThan(html.indexOf('name="apple-itunes-app"'));
  });

  it.each(TABLE)("inline script on %s matches smartBannerArgument", (p) => {
    document.head.innerHTML = `<meta name="apple-itunes-app" content="app-id=${SMART_BANNER_APP_ID}, app-argument=${ROOT}">`;
    window.history.replaceState(null, "", p);
    // eslint-disable-next-line no-new-func
    new Function(script)();
    expect(document.querySelector('meta[name="apple-itunes-app"]')!.getAttribute("content"))
      .toBe(`app-id=${SMART_BANNER_APP_ID}, app-argument=${smartBannerArgument(p)}`);
  });

  afterAll(() => window.history.replaceState(null, "", "/"));
});
```

`src/components/linking/openInAppAction.test.ts` — add inside `describe('appSchemeUrl', …)`:

```ts
  it('opens a card as the person\'s profile (the app has no card route)', () => {
    expect(appSchemeUrl('card', 'u1')).toBe('bananatalk://profile/u1');
  });

  it('builds invite and story links', () => {
    expect(appSchemeUrl('i', 'ABCD2345')).toBe('bananatalk://i/ABCD2345');
    expect(appSchemeUrl('story', 's1')).toBe('bananatalk://story/s1');
  });
```

`src/components/linking/AppBanner.test.tsx` — change the `OpenInApp` mock (line 12) so props are visible:

```tsx
jest.mock("./OpenInApp", () => (p: any) => (
  <a href="#open" data-testid="open-in-app" data-type={p.type} data-id={p.id}>Open</a>
));
```
and append:

```tsx
const HEX = "507f1f77bcf86cd799439011";
const openProps = () => {
  const a = screen.getByTestId("open-in-app");
  return { type: a.getAttribute("data-type"), id: a.getAttribute("data-id") };
};

it.each([
  [`/story/${HEX}`, "story", HEX],
  ["/i/ABCD2345", "i", "ABCD2345"],
  [`/card/${HEX}`, "card", HEX],
  [`/community/${HEX}`, "community", HEX],
])("on %s offers the app with type %s", (p, type, id) => {
  setUserAgent(IPHONE);
  render(at(p));
  expect(openProps()).toEqual({ type, id });
});

it("still skips web-only pages that look like an id", () => {
  setUserAgent(IPHONE);
  render(at("/community/nearby"));
  expect(screen.queryByTestId("open-in-app")).not.toBeInTheDocument();
});

it("keeps the Safari smart-banner tag on the current page, even on desktop", () => {
  setUserAgent(MAC);
  document.head.innerHTML = '<meta name="apple-itunes-app" content="app-id=6755862146, app-argument=https://banatalk.com/">';
  render(at(`/moment/${HEX}`));
  expect(document.querySelector('meta[name="apple-itunes-app"]')!.getAttribute("content"))
    .toBe(`app-id=6755862146, app-argument=https://banatalk.com/moment/${HEX}`);
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links && CI=true npm test -- --watchAll=false linking/
```
Expected: FAIL. `smartBanner.test.ts` cannot resolve `./smartBanner`; `appSchemeUrl('card', …)` is `bananatalk://card/u1`
(and `'i'`/`'story'` are type errors only under `tsc`, runtime still builds the string); AppBanner finds no
`open-in-app` on `/story/…`, `/i/…`, `/card/…`; the meta stays on the homepage argument.

- [ ] **Step 3: Implement**

`src/components/linking/smartBanner.ts` (new):

```ts
// Safari's Smart App Banner ("Open" in the BananaTalk app) passes
// `app-argument` to the app, whose deep-link parser routes it. A static
// homepage argument opened the app at home whatever page was being read
// (links#16). The same rule runs as an inline script in public/index.html --
// Safari reads the tag while parsing, before any bundle runs -- and
// smartBanner.test.ts keeps the two copies in agreement.

export const SMART_BANNER_APP_ID = "6755862146";
const ROOT = "https://banatalk.com/";
const OBJECT_ID = /^[0-9a-fA-F]{24}$/;
const INVITE_CODE = /^[A-Za-z0-9]{4,32}$/;
const LINKABLE = /^\/(moment|profile|community|story|card|i)\/([^/]+)\/?$/;

/** The universal link the app should open for this page; the homepage when there is none. */
export function smartBannerArgument(pathname: string): string {
  const m = LINKABLE.exec(pathname || "");
  if (!m) return ROOT;
  const type = m[1];
  const id = m[2];
  if (type === "i") return INVITE_CODE.test(id) ? `${ROOT}i/${id}` : ROOT;
  if (!OBJECT_ID.test(id)) return ROOT; // profile/edit, community/nearby ...
  return `${ROOT}${type === "card" ? "profile" : type}/${id}`;
}

export function setSmartBannerArgument(pathname: string, doc: Document = document): void {
  const tag = doc.querySelector('meta[name="apple-itunes-app"]');
  if (!tag) return;
  tag.setAttribute("content", `app-id=${SMART_BANNER_APP_ID}, app-argument=${smartBannerArgument(pathname)}`);
}
```

`public/index.html`, replace lines 68–69:

```html
    <meta name="apple-itunes-app" content="app-id=6755862146, app-argument=https://banatalk.com/" />
    <meta name="google-play-app" content="app-id=com.bananatalk.app" />
```
with:

```html
    <meta name="apple-itunes-app" content="app-id=6755862146, app-argument=https://banatalk.com/" />
    <!-- Point Safari's banner at this page (src/components/linking/smartBanner.ts holds the same rule; its test compares them). -->
    <script id="smart-banner-argument">
      (function () {
        try {
          var r = "https://banatalk.com/";
          var m = /^\/(moment|profile|community|story|card|i)\/([^\/]+)\/?$/.exec(location.pathname || "");
          var arg = r;
          if (m) {
            if (m[1] === "i") {
              if (/^[A-Za-z0-9]{4,32}$/.test(m[2])) arg = r + "i/" + m[2];
            } else if (/^[0-9a-fA-F]{24}$/.test(m[2])) {
              arg = r + (m[1] === "card" ? "profile" : m[1]) + "/" + m[2];
            }
          }
          var tag = document.querySelector('meta[name="apple-itunes-app"]');
          if (tag) tag.setAttribute("content", "app-id=6755862146, app-argument=" + arg);
        } catch (e) {}
      })();
    </script>
```

`src/components/linking/openInAppAction.ts`, replace

```ts
export function appSchemeUrl(type: ShareType, id: string): string {
  return `bananatalk://${type}/${id}`;
}

export interface OpenInAppOptions {
  type: ShareType;
```
with

```ts
/**
 * Every page the app can be asked to open. `i` (invite) and `story` are not
 * share types: invite links are built by the backend, and story links by the
 * app (2.7.0 parses them; 2.6.1 opens the app and drops the link).
 */
export type AppLinkType = ShareType | 'i' | 'story';

export function appSchemeUrl(type: AppLinkType, id: string): string {
  // The app has no card route; a card is a person, so it opens their profile.
  const route = type === 'card' ? 'profile' : type;
  return `bananatalk://${route}/${id}`;
}

export interface OpenInAppOptions {
  type: AppLinkType;
```

`src/components/linking/OpenInApp.tsx`: replace `import { ShareType } from '../../utils/shareUrl';` with
`import { AppLinkType } from './openInAppAction';`, merge it into the existing `import { openInApp } from './openInAppAction';`
(→ `import { openInApp, AppLinkType } from './openInAppAction';`), and change `type: ShareType;` to `type: AppLinkType;`.

`src/components/linking/AppBanner.tsx`, replace lines 1–24:

```tsx
import React, { useEffect, useState } from 'react';
import { useLocation, matchPath } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react';
import { detectPlatform, MobilePlatform } from '../../utils/platform';
import OpenInApp from './OpenInApp';
import { ShareType } from '../../utils/shareUrl';

const PATTERNS: { pattern: string; type: ShareType }[] = [
  { pattern: '/moment/:id', type: 'moment' },
  { pattern: '/profile/:userId', type: 'profile' },
  { pattern: '/community/:id', type: 'community' },
];
…
const EXCLUDED_IDS: Record<ShareType, string[]> = {
  moment: [],
  profile: ['edit'],
  community: ['nearby'],
};
```
with

```tsx
import React, { useEffect, useState } from 'react';
import { useLocation, matchPath } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react';
import { detectPlatform, MobilePlatform } from '../../utils/platform';
import OpenInApp from './OpenInApp';
import { AppLinkType } from './openInAppAction';
import { setSmartBannerArgument } from './smartBanner';

const PATTERNS: { pattern: string; type: AppLinkType }[] = [
  { pattern: '/moment/:id', type: 'moment' },
  { pattern: '/profile/:userId', type: 'profile' },
  { pattern: '/community/:id', type: 'community' },
  { pattern: '/story/:id', type: 'story' },
  { pattern: '/card/:userId', type: 'card' },
  { pattern: '/i/:code', type: 'i' },
];

// Some real, static sub-routes share their first path segment with one of the
// dynamic detail patterns above (e.g. `/community/nearby` -> NearbyUsers,
// `/profile/edit` -> EditProfile). `matchPath` can't tell those apart from an
// actual `:id`/`:userId`, so we exclude the known static segments per type to
// avoid producing a bogus `bananatalk://community/nearby` deep link.
const EXCLUDED_IDS: { [type: string]: string[] } = {
  profile: ['edit'],
  community: ['nearby'],
};
```
then, inside the component, right after `const { t } = useTranslation();` add:

```tsx
  // Safari's smart banner reads <meta name="apple-itunes-app">; the inline
  // script in index.html sets it for the first page, this keeps it right
  // after client-side navigation. Runs on every platform: it is one attribute.
  useEffect(() => {
    setSmartBannerArgument(location.pathname);
  }, [location.pathname]);
```
and replace

```tsx
      const id = (m.params as any).id ?? (m.params as any).userId;
      if (!id || EXCLUDED_IDS[type].includes(id)) continue;
```
with

```tsx
      const params = m.params as any;
      const id = params.id ?? params.userId ?? params.code;
      if (!id || (EXCLUDED_IDS[type] || []).includes(id)) continue;
```
(The hook sits above both early `return null`s, so hook order is stable.)

- [ ] **Step 4: Run → PASS**, then the prerender-adjacent suites that read `index.html`/`OpenInApp`:

```bash
CI=true npm test -- --watchAll=false linking/ seo/ card/ invite/
```
Expected: all green.

- [ ] **Step 5: Commit** (tick `P3-LINK-3`)

```bash
git add src/components/linking/smartBanner.ts src/components/linking/smartBanner.test.ts public/index.html \
  src/components/linking/openInAppAction.ts src/components/linking/openInAppAction.test.ts \
  src/components/linking/OpenInApp.tsx src/components/linking/AppBanner.tsx src/components/linking/AppBanner.test.tsx \
  docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(links): smart banner and app banner open the page being viewed

Safari's smart banner always passed https://banatalk.com/, so "Open"
landed on the app's home screen whatever was being read, and the web
app banner ignored invite, card and story pages. An inline script now
sets app-argument from the URL while the page parses (AppBanner keeps it
right after client navigation), the app banner covers /i/, /card/ (as a
profile) and /story/, and the ignored google-play-app tag is gone.
Story links open the story in 2.7.0; 2.6.1 opens the app and drops them.

Still open (Phase 3 links): /story/:id page, Google code exchange, http
links on legal pages; device QA: Safari banner after client navigation;
owner applies the nginx snippet.
EOF
```

---

### Task P3-LINK-4: `/story/:id` page — the target of story share links (links#1, moments#1)

**Files:**
- Create: `src/components/stories/StoryLinkPage.tsx`, test `src/components/stories/StoryLinkPage.test.tsx`
- Modify: `src/router/routes.tsx` (lazy import next to line 96; route next to line 250)
- Modify: `src/router/routes.test.tsx` (route assertion), `src/seo/prerender/nginxRoutes.test.ts:22-27` (segment list)
- Modify: `src/utils/locales/eng.json` (`stories.link.*`)

**Interfaces:**
- Consumes: `useGetIndividualStoryQuery(storyId)` (`storiesSlice.ts:99-104`, `GET /stories/:id`, protected) and
  `useGetUserStoriesQuery(userId)` (`storiesSlice.ts:146`); `<OpenInApp type="story" />` from P3-LINK-3.
- Produces: route `/story/:id` (public, no auth guard). Signed in + story readable → `<Navigate replace>` to
  `/stories/<authorId>` with `state.startIndex` = the story's index in the author's list, so the existing
  `StoryViewer` (`StoryViewer.tsx:146`, reads `location.state.startIndex`) opens on it. **StoryViewer is not modified**
  (the MOMENTS unit edits it). P3-CHAT-13's story-share card links to `/story/<storyId>`. The app (2.7.0, Phase 2)
  shares `https://banatalk.com/story/<id>`.
  - `build/nginx.routes.conf` gains the `story` segment automatically (it is generated from the router).
  - The page is noindex automatically (`RouteMeta` marks every path outside `SEO_PAGES`); it is not in the sitemap.

States: invalid id → "expired" card (no fetch); signed out → "Someone shared a story" card with **Sign in**
(`/login?redirect=%2Fstory%2F<id>`) and **Open in app**; 404 → expired; 403 → unavailable; other error → failed +
Try again; author list fails → navigate anyway with index 0 (the viewer shows its own error).

- [ ] **Step 1: Write the failing test** `src/components/stories/StoryLinkPage.test.tsx`

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import StoryLinkPage, { storyIndexIn } from "./StoryLinkPage";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));
let mockUser: any = { user: { _id: "me" } };
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: mockUser } }) }));
jest.mock("../linking/OpenInApp", () => (p: any) => (
  <button data-testid="open-in-app" data-type={p.type} data-id={p.id}>open</button>
));
jest.mock("../Loader", () => () => <div data-testid="loader" />);

const mockStory = jest.fn();
const mockUserStories = jest.fn();
jest.mock("../../store/slices/storiesSlice", () => ({
  useGetIndividualStoryQuery: (...a: any[]) => mockStory(...a),
  useGetUserStoriesQuery: (...a: any[]) => mockUserStories(...a),
}));

const ID = "507f1f77bcf86cd799439011";
const AUTHOR = "60d5ec49f1b2c72b9c8e4a11";

const Where = () => {
  const loc = useLocation();
  return <div data-testid="where">{`${loc.pathname}${loc.search}|${JSON.stringify(loc.state)}`}</div>;
};
const renderAt = (id = ID) => render(
  <MemoryRouter initialEntries={[`/story/${id}`]}>
    <Routes>
      <Route path="/story/:id" element={<StoryLinkPage />} />
      <Route path="*" element={<Where />} />
    </Routes>
  </MemoryRouter>);

beforeEach(() => {
  mockUser = { user: { _id: "me" } };
  mockStory.mockReset().mockReturnValue({ isFetching: true });
  mockUserStories.mockReset().mockReturnValue({});
});

test("signed out: a sign-in card that comes back here, plus Open in app; no fetch", () => {
  mockUser = null;
  renderAt();
  expect(mockStory).toHaveBeenCalledWith(ID, { skip: true });
  expect(screen.getByText("stories.link.sign_in_title")).toBeInTheDocument();
  expect(screen.getByRole("link", { name: "stories.link.sign_in" }))
    .toHaveAttribute("href", `/login?redirect=${encodeURIComponent(`/story/${ID}`)}`);
  expect(screen.getByTestId("open-in-app")).toHaveAttribute("data-type", "story");
  expect(screen.getByTestId("open-in-app")).toHaveAttribute("data-id", ID);
});

test("signed in: opens the author's viewer on this story", () => {
  mockStory.mockReturnValue({ currentData: { success: true, data: { _id: ID, user: { _id: AUTHOR, name: "Mina" } } } });
  mockUserStories.mockReturnValue({ currentData: { success: true, data: [{ _id: "s0" }, { _id: ID }, { _id: "s2" }] } });
  renderAt();
  expect(mockUserStories).toHaveBeenLastCalledWith(AUTHOR, { skip: false });
  expect(screen.getByTestId("where")).toHaveTextContent(`/stories/${AUTHOR}|{"startIndex":1}`);
});

test("an unpopulated author id works too, and a missing story in the list starts at 0", () => {
  mockStory.mockReturnValue({ currentData: { success: true, data: { _id: ID, user: AUTHOR } } });
  mockUserStories.mockReturnValue({ currentData: [{ _id: "other" }] });
  renderAt();
  expect(screen.getByTestId("where")).toHaveTextContent(`/stories/${AUTHOR}|{"startIndex":0}`);
});

test("the author's list failing still opens the viewer (it shows its own error)", () => {
  mockStory.mockReturnValue({ currentData: { data: { _id: ID, user: { _id: AUTHOR } } } });
  mockUserStories.mockReturnValue({ error: { status: 500 } });
  renderAt();
  expect(screen.getByTestId("where")).toHaveTextContent(`/stories/${AUTHOR}`);
});

test("404 says the story expired, with a way to current stories", () => {
  mockStory.mockReturnValue({ error: { status: 404 } });
  renderAt();
  expect(screen.getByText("stories.link.expired")).toBeInTheDocument();
  expect(screen.getByRole("link", { name: "stories.link.browse" })).toHaveAttribute("href", "/stories");
});

test("403 says it is not available to you", () => {
  mockStory.mockReturnValue({ error: { status: 403 } });
  renderAt();
  expect(screen.getByText("stories.link.unavailable")).toBeInTheDocument();
});

test("other errors offer Try again", () => {
  const refetch = jest.fn();
  mockStory.mockReturnValue({ error: { status: "FETCH_ERROR" }, refetch });
  renderAt();
  fireEvent.click(screen.getByRole("button", { name: "stories.link.retry" }));
  expect(refetch).toHaveBeenCalled();
});

test("a malformed id never hits the API and reads as expired", () => {
  renderAt("not-an-id");
  expect(mockStory).toHaveBeenCalledWith("not-an-id", { skip: true });
  expect(screen.getByText("stories.link.expired")).toBeInTheDocument();
});

test("stale data for another story id is not followed", () => {
  mockStory.mockReturnValue({ currentData: { data: { _id: "someone-else", user: { _id: AUTHOR } } }, isFetching: true });
  renderAt();
  expect(screen.getByTestId("loader")).toBeInTheDocument();
});

test("storyIndexIn", () => {
  expect(storyIndexIn([{ _id: "a" }, { _id: "b" }], "b")).toBe(1);
  expect(storyIndexIn([{ _id: "a" }], "zzz")).toBe(0);
  expect(storyIndexIn([], "a")).toBe(0);
});
```

In `src/router/routes.test.tsx`, append:

```tsx
// Story share links (app 2.7.0, chat story cards): /story/<storyId>, a story id,
// next to -- not inside -- /stories/<userId>, which is keyed by the author.
it("matches /story/<id> to the story link page, not the catch-all or the viewer", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/story/507f1f77bcf86cd799439011");
  expect(matches && matches.length).toBe(2);
  expect(matches![1].route.path).toBe("story/:id");
  expect(matchRoutes(routes, "/stories/abc")![1].route.path).toBe("stories/:userId");
});
```

In `src/seo/prerender/nginxRoutes.test.ts`, extend the expected list in "lists every real top-level segment" (lines 22–25):

```ts
  for (const expected of [
    "login", "register", "chat", "profile", "download", "moments", "communities",
    "settings", "stories", "support", "privacy-policy", "terms-of-use", "data-deletion",
    "story", "moment", "i", "card",
  ]) {
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links && CI=true npm test -- --watchAll=false StoryLinkPage routes.test nginxRoutes
```
Expected: FAIL. `StoryLinkPage` cannot be resolved; the routes test matches `/story/…` to `*`; nginxRoutes lacks `story`.

- [ ] **Step 3: Implement**

`src/components/stories/StoryLinkPage.tsx` (new):

```tsx
import React from "react";
import { Link, Navigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { useGetIndividualStoryQuery, useGetUserStoriesQuery } from "../../store/slices/storiesSlice";
import OpenInApp from "../linking/OpenInApp";
import Loader from "../Loader";

// /story/<storyId>: where story share links land (the app's share sheet from
// 2.7.0, the web chat's story cards). The viewer is keyed by the AUTHOR
// (/stories/<userId>), so this page looks the story up, then hands over to
// the viewer positioned on it. GET /stories/:id needs a session: signed-out
// visitors get a card instead of a blank page.

const OBJECT_ID = /^[0-9a-fA-F]{24}$/;

const idOf = (ref: any): string =>
  ref && typeof ref === "object" ? String(ref._id || "") : String(ref || "");

const listOf = (resp: any): any[] =>
  Array.isArray(resp) ? resp : resp && Array.isArray(resp.data) ? resp.data : [];

/** Index of the story in its author's list; 0 when it is not there. */
export function storyIndexIn(stories: any[], storyId: string): number {
  const i = stories.findIndex((s) => s && s._id === storyId);
  return i < 0 ? 0 : i;
}

const Card: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="mx-auto my-16 max-w-md rounded-3xl bg-surface p-8 text-center shadow-card dark:bg-cardbg-dark">
    {children}
  </div>
);

const LINK_BTN =
  "inline-block rounded-xl bg-brand-deep px-5 py-3 font-bold text-white hover:bg-brand-deepest";
const SECONDARY_BTN =
  "rounded-xl border border-brand-deep px-5 py-3 font-bold text-brand-deep hover:bg-brand-deep/10";

const StoryLinkPage: React.FC = () => {
  const { id = "" } = useParams();
  const { t } = useTranslation();
  const loggedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo));
  const valid = OBJECT_ID.test(id);

  const story = useGetIndividualStoryQuery(id, { skip: !loggedIn || !valid });
  const storyData = story.currentData && (story.currentData.data || story.currentData);
  // Only ever follow the story that belongs to this route.
  const authorId = storyData && storyData._id === id ? idOf(storyData.user) : "";
  const author = useGetUserStoriesQuery(authorId, { skip: !authorId });

  const expired = (
    <Card>
      <p className="text-ink-700 dark:text-ink-200">
        {t("stories.link.expired") || "This story has expired or was deleted. Stories disappear after 24 hours."}
      </p>
      <Link to="/stories" className={`mt-6 ${LINK_BTN}`}>
        {t("stories.link.browse") || "See current stories"}
      </Link>
    </Card>
  );

  if (!valid) return expired;

  if (!loggedIn) {
    return (
      <Card>
        <h1 className="text-xl font-bold text-ink-900 dark:text-ink-50">
          {t("stories.link.sign_in_title") || "Someone shared a story with you"}
        </h1>
        <p className="mt-3 text-ink-700 dark:text-ink-200">
          {t("stories.link.sign_in_body") || "Sign in to watch it, or open it in the BananaTalk app."}
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          <Link to={`/login?redirect=${encodeURIComponent(`/story/${id}`)}`} className={LINK_BTN}>
            {t("stories.link.sign_in") || "Sign in"}
          </Link>
          <OpenInApp type="story" id={id} className={SECONDARY_BTN} />
        </div>
      </Card>
    );
  }

  if (story.error) {
    const status = (story.error as any).status;
    if (status === 404) return expired;
    if (status === 403) {
      return (
        <Card>
          <p className="text-ink-700 dark:text-ink-200">
            {t("stories.link.unavailable") || "This story isn't available to you."}
          </p>
          <Link to="/stories" className={`mt-6 ${LINK_BTN}`}>
            {t("stories.link.browse") || "See current stories"}
          </Link>
        </Card>
      );
    }
    return (
      <Card>
        <p className="text-ink-700 dark:text-ink-200">
          {t("stories.link.failed") || "We couldn't load this story."}
        </p>
        <button type="button" onClick={() => story.refetch && story.refetch()} className={`mt-6 ${LINK_BTN}`}>
          {t("stories.link.retry") || "Try again"}
        </button>
      </Card>
    );
  }

  if (authorId && (author.currentData || author.error)) {
    const startIndex = author.currentData ? storyIndexIn(listOf(author.currentData), id) : 0;
    return <Navigate to={`/stories/${authorId}`} replace state={{ startIndex }} />;
  }

  return <Loader />;
};

export default StoryLinkPage;
```

`src/router/routes.tsx`, after line 96
(`const StoryViewer = lazyWithRetry("../components/stories/StoryViewer", () => import("../components/stories/StoryViewer"));`) add:

```tsx
const StoryLinkPage = lazyWithRetry("../components/stories/StoryLinkPage", () => import("../components/stories/StoryLinkPage"));
```
and after line 250 (`<Route path="stories/:userId" element={lazyRoute(<StoryViewer />)} />`) add:

```tsx
    {/* Story share links: /story/<storyId> (a STORY id; the viewer above is
        keyed by the author). Public: signed-out visitors get a sign-in /
        open-in-app card. Not claimed by the AASA until 2.7.0 dominates. */}
    <Route path="story/:id" element={lazyRoute(<StoryLinkPage />)} />
```

`src/utils/locales/eng.json`, inside `"stories": { … }` add:

```json
    "link": {
      "sign_in_title": "Someone shared a story with you",
      "sign_in_body": "Sign in to watch it, or open it in the BananaTalk app.",
      "sign_in": "Sign in",
      "expired": "This story has expired or was deleted. Stories disappear after 24 hours.",
      "unavailable": "This story isn't available to you.",
      "failed": "We couldn't load this story.",
      "retry": "Try again",
      "browse": "See current stories"
    },
```

- [ ] **Step 4: Run → PASS** (same command), then `CI=true npm test -- --watchAll=false stories/ router/ seo/`.

- [ ] **Step 5: Commit** (tick `P3-LINK-4`)

```bash
git add src/components/stories/StoryLinkPage.tsx src/components/stories/StoryLinkPage.test.tsx src/router/routes.tsx \
  src/router/routes.test.tsx src/seo/prerender/nginxRoutes.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(stories): /story/:id page for story share links

The app (2.7.0) shares https://banatalk.com/story/<id> and web chat story
cards link there, but the web only had /stories/<authorId>, so the link
hit the 404 page. The new page looks the story up and opens the author's
viewer on it; signed-out visitors get a sign-in / open-in-app card, and
expired, deleted or private stories say so instead of showing a blank
page. The nginx route allowlist picks up "story" from the router.

Still open (Phase 3 links): Google code exchange, http links on legal
pages, stories.link.* translations; owner applies the nginx snippet;
Phase 5 claims /story/* in the AASA.
EOF
```

---

### Task P3-LINK-5: Google sign-in reads the one-time `code` (links#12)

**Files:**
- Modify: `src/constants.ts` (new constant after line 15)
- Modify: `src/components/auth/AuthCallback.tsx` (whole component body; `isProfileComplete` unchanged)
- Modify: `src/utils/locales/eng.json` (`authentication.callback.*`)
- Test (new): `src/components/auth/AuthCallback.test.tsx`

**Interfaces:**
- Consumes: `/auth/callback?code=<43 chars>&token=<legacy JWT>` (after backend P1-LINK-5 deploys), or `?token=` only
  (before), or `?error=<msg>&reason=<EMAIL_EXISTS|BANNED|GOOGLE_FAILED>`. `POST /api/v1/auth/google/exchange {code}` →
  `{ success, token, refreshToken, user }` | 400 `{code:'OAUTH_CODE_INVALID'}` | 403 `ACCOUNT_BANNED`.
- Produces: `setCredentials({ user, token, refreshToken, message })` — the same shape `Login.tsx:36-41` dispatches, so
  `apiSlice.ts:99-123` can refresh a Google session for the first time. After this is live, the backend removes the
  legacy `token=` from the redirect (backend REMAINING_WORK item from P1-LINK-5).

Risky inputs handled: the code is single-use, so React 18 StrictMode's double effect must not spend it twice (ref
guard); the code and token are scrubbed from the address bar and history before the first `await`; exchange failure
with a legacy token present falls back to the token (rollout window); a reload of `/auth/callback` after scrubbing
shows "Sign in didn't finish", not a crash.

- [ ] **Step 1: Write the failing test** `src/components/auth/AuthCallback.test.tsx`

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import AuthCallback from "./AuthCallback";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));
const mockDispatch = jest.fn();
jest.mock("react-redux", () => ({ useDispatch: () => mockDispatch }));
jest.mock("react-toastify", () => ({ Bounce: {}, toast: { error: jest.fn(), info: jest.fn(), success: jest.fn() } }));
jest.mock("../Loader", () => () => <div data-testid="loader" />);

const COMPLETE_USER = { _id: "u1", name: "Ada", isRegistrationComplete: true };

type Reply = { status: number; body: any };
let replies: Reply[] = [];
const calls: { url: string; init: any }[] = [];

beforeEach(() => {
  replies = [];
  calls.length = 0;
  mockDispatch.mockReset();
  sessionStorage.clear();
  (global as any).fetch = jest.fn(async (url: string, init: any) => {
    calls.push({ url, init });
    const r = replies.shift() || { status: 500, body: {} };
    return { ok: r.status >= 200 && r.status < 300, status: r.status, json: async () => r.body };
  });
});
afterAll(() => window.history.replaceState(null, "", "/"));

const Where = () => <div data-testid="where">{useLocation().pathname}</div>;
const renderAt = (search: string, strict = false) => {
  window.history.replaceState(null, "", `/auth/callback${search}`);
  const tree = (
    <MemoryRouter initialEntries={[`/auth/callback${search}`]}>
      <Routes>
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route path="*" element={<Where />} />
      </Routes>
    </MemoryRouter>
  );
  return render(strict ? <React.StrictMode>{tree}</React.StrictMode> : tree);
};
const lastCredentials = () => mockDispatch.mock.calls.map((c) => c[0]).find((a) => a && a.type === "auth/setCredentials");

test("exchanges the code once, stores both tokens and scrubs the URL", async () => {
  replies.push({ status: 200, body: { success: true, token: "T", refreshToken: "R", user: COMPLETE_USER } });
  renderAt("?code=abc&token=legacy");
  expect(window.location.search).toBe("");
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/"));
  expect(calls).toHaveLength(1);
  expect(calls[0].url).toMatch(/\/api\/v1\/auth\/google\/exchange$/);
  expect(calls[0].init.method).toBe("POST");
  expect(JSON.parse(calls[0].init.body)).toEqual({ code: "abc" });
  expect(lastCredentials().payload).toEqual(expect.objectContaining({ user: COMPLETE_USER, token: "T", refreshToken: "R" }));
});

test("StrictMode's double effect does not spend the single-use code twice", async () => {
  replies.push({ status: 200, body: { success: true, token: "T", refreshToken: "R", user: COMPLETE_USER } });
  renderAt("?code=abc", true);
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/"));
  expect(calls).toHaveLength(1);
});

test("an expired code with no legacy token says so", async () => {
  replies.push({ status: 400, body: { success: false, code: "OAUTH_CODE_INVALID" } });
  renderAt("?code=old");
  expect(await screen.findByText("authentication.callback.codeExpired")).toBeInTheDocument();
  expect(lastCredentials()).toBeUndefined();
});

test("a banned account gets the suspended message", async () => {
  replies.push({ status: 403, body: { success: false, code: "ACCOUNT_BANNED" } });
  renderAt("?code=abc");
  expect(await screen.findByText("authentication.callback.banned")).toBeInTheDocument();
});

test("exchange failing during the rollout falls back to the legacy token", async () => {
  replies.push({ status: 404, body: {} });
  replies.push({ status: 200, body: { success: true, data: COMPLETE_USER } });
  renderAt("?code=abc&token=legacy");
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/"));
  expect(calls[1].url).toMatch(/\/api\/v1\/auth\/me$/);
  expect(calls[1].init.headers.Authorization).toBe("Bearer legacy");
  expect(lastCredentials().payload.token).toBe("legacy");
});

test("legacy ?token= only (backend not yet deployed) still signs in", async () => {
  replies.push({ status: 200, body: { success: true, data: COMPLETE_USER } });
  renderAt("?token=legacy");
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/"));
  expect(calls).toHaveLength(1);
  expect(calls[0].url).toMatch(/\/api\/v1\/auth\/me$/);
});

test("reason=EMAIL_EXISTS shows a localized message and calls nothing", async () => {
  renderAt("?error=An%20account%20exists&reason=EMAIL_EXISTS");
  expect(await screen.findByText("authentication.callback.emailExists")).toBeInTheDocument();
  expect(calls).toHaveLength(0);
});

test("no code and no token (e.g. a reload after scrubbing) asks to try again", async () => {
  renderAt("");
  expect(await screen.findByText("authentication.callback.noCode")).toBeInTheDocument();
  expect(calls).toHaveLength(0);
});

test("an incomplete profile goes to the signup wizard with the exchanged user", async () => {
  replies.push({ status: 200, body: { success: true, token: "T", refreshToken: "R", user: { _id: "u2", profileCompleted: false } } });
  renderAt("?code=abc");
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/register"));
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links && CI=true npm test -- --watchAll=false AuthCallback
```
Expected: FAIL. The code tests see "No authentication token received" (no `token`) or a GET to `/auth/me`; the URL
keeps `?code=…`; StrictMode makes 2 calls; `reason` shows the raw English error.

- [ ] **Step 3: Implement**

`src/constants.ts`, after line 15 (`export const ACCEPT_TERMS_URL = "/api/v1/auth/accept-terms";`):

```ts
// Web Google login: the callback carries a single-use code (60 s) that this
// exchanges for { token, refreshToken, user }. Replaces ?token= in the URL.
export const GOOGLE_EXCHANGE_URL = "/api/v1/auth/google/exchange";
```

`src/components/auth/AuthCallback.tsx`: replace the imports (lines 1–8) with

```tsx
import { useEffect, useRef, useState } from "react";
import { useDispatch } from "react-redux";
import { useNavigate, useSearchParams } from "react-router-dom";
import { setCredentials } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import { useTranslation } from "react-i18next";
import Loader from "../Loader";
import { BASE_URL, GOOGLE_EXCHANGE_URL, USER_PROFILE_URL } from "../../constants";
```
keep `isProfileComplete` (lines 10–33) as is, and replace everything from `const AuthCallback = () => {` (line 35) to the
end of the file with:

```tsx
interface SignIn { user: any; token: string; refreshToken?: string }
type Translate = (key: string) => string;

const TOAST = { position: "top-right" as const, autoClose: 4000, theme: "dark" as const, transition: Bounce };

/** Drop ?code= / ?token= from the address bar and history before anything awaits. */
function scrubCallbackUrl(): void {
  try {
    window.history.replaceState(window.history.state, "", window.location.pathname);
  } catch (e) {
    // no history API (prerender) -- nothing to scrub
  }
}

async function exchangeCode(code: string): Promise<SignIn> {
  const res = await fetch(`${BASE_URL}${GOOGLE_EXCHANGE_URL}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ code }),
  });
  let body: any = null;
  try {
    body = await res.json();
  } catch (e) {
    body = null;
  }
  if (!res.ok || !body || !body.token) {
    const err: any = new Error((body && (body.error || body.message)) || "Code exchange failed");
    err.status = res.status;
    err.code = body && body.code;
    throw err;
  }
  return { user: body.user || body.data, token: body.token, refreshToken: body.refreshToken };
}

/** The pre-code flow: the JWT came in the URL. Kept until the backend drops `token=`. */
async function legacyTokenSignIn(token: string): Promise<SignIn> {
  const res = await fetch(`${BASE_URL}${USER_PROFILE_URL}`, {
    method: "GET",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
  });
  const body: any = res.ok ? await res.json() : null;
  if (!body || !body.success || !body.data) {
    const err: any = new Error("Failed to fetch user profile");
    err.status = res.status;
    throw err;
  }
  return { user: body.data, token };
}

function refusalMessage(t: Translate, reason: string | null, raw: string | null): string {
  if (reason === "EMAIL_EXISTS") {
    return t("authentication.callback.emailExists") || "An account with this email already exists. Sign in with your email and password.";
  }
  if (reason === "BANNED") return t("authentication.callback.banned") || "This account has been suspended.";
  if (reason === "GOOGLE_FAILED" || !raw) return t("authentication.callback.generic") || "Sign in failed. Please try again.";
  return raw;
}

function failureMessage(t: Translate, err: any): string {
  if (err && (err.status === 403 || err.code === "ACCOUNT_BANNED")) {
    return t("authentication.callback.banned") || "This account has been suspended.";
  }
  if (err && err.code === "OAUTH_CODE_INVALID") {
    return t("authentication.callback.codeExpired") || "This sign-in link has expired. Please sign in again.";
  }
  return t("authentication.callback.generic") || "Sign in failed. Please try again.";
}

const AuthCallback = () => {
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  // The code works once. React 18 StrictMode runs this effect twice in
  // development; the ref survives that remount, so only one exchange is sent.
  const started = useRef(false);

  useEffect(() => {
    if (started.current) return;
    started.current = true;

    const code = searchParams.get("code");
    const token = searchParams.get("token");
    const errorParam = searchParams.get("error");
    const reason = searchParams.get("reason");
    scrubCallbackUrl();

    const fail = (message: string) => {
      setError(message);
      setIsLoading(false);
      toast.error(message, TOAST);
      setTimeout(() => navigate("/login"), 2000);
    };

    const finish = ({ user: userInfo, token: accessToken, refreshToken }: SignIn) => {
      // Same shape as the email login (Login.tsx), so apiSlice can refresh it.
      dispatch(
        setCredentials({
          user: userInfo,
          token: accessToken,
          refreshToken,
          message: "Successfully authenticated with Google",
        })
      );
      setIsLoading(false);

      if (!isProfileComplete(userInfo)) {
        toast.info(t("authentication.register.completeProfile") || "Please complete your profile to continue", {
          ...TOAST,
          autoClose: 3000,
        });
        const normalizedGender = userInfo?.gender?.toLowerCase() || "other";
        // OAuth users already have email + name — send them into the SAME
        // signup wizard in completion mode, starting at the languages step
        // (languages → photo → finish). The wizard's finish handler will
        // patch the profile via updatedetails + record terms, NOT re-register.
        navigate("/register", {
          state: {
            oauth: true,
            startStep: "languages",
            userData: {
              _id: userInfo?._id || "",
              name: userInfo?.name || "",
              email: userInfo?.email || "",
              bio: userInfo?.bio || "Hello! I joined using Google.",
              gender: normalizedGender,
              nativeLanguage: userInfo?.native_language || "",
              languageToLearn: userInfo?.language_to_learn || "",
              birthDate:
                userInfo?.birth_year && userInfo?.birth_month && userInfo?.birth_day
                  ? `${userInfo.birth_year}-${String(userInfo.birth_month).padStart(2, "0")}-${String(userInfo.birth_day).padStart(2, "0")}`
                  : "2000-01-01",
            },
          },
        });
        return;
      }

      toast.success(t("authentication.login.successMessage") || "Login successful!", {
        ...TOAST,
        autoClose: 2000,
        hideProgressBar: false,
      });
      const redirect = sessionStorage.getItem("oauth_redirect") || "/";
      sessionStorage.removeItem("oauth_redirect");
      navigate(redirect, { replace: true });
    };

    if (errorParam || reason) {
      fail(refusalMessage(t, reason, errorParam));
      return;
    }
    if (!code && !token) {
      fail(t("authentication.callback.noCode") || "Sign in didn't finish. Please try again.");
      return;
    }

    (async () => {
      let signIn: SignIn;
      try {
        if (code) {
          try {
            signIn = await exchangeCode(code);
          } catch (exchangeError) {
            // Rollout window: the redirect still carries the legacy token.
            if (!token) throw exchangeError;
            signIn = await legacyTokenSignIn(token);
          }
        } else {
          signIn = await legacyTokenSignIn(token as string);
        }
      } catch (err: any) {
        console.error("OAuth callback error:", err);
        fail(failureMessage(t, err));
        return;
      }
      finish(signIn);
    })();
  }, [searchParams, dispatch, navigate, t]);

  if (isLoading) {
    return (
      <div className="d-flex flex-column justify-content-center align-items-center" style={{ minHeight: "50vh" }}>
        <Loader />
        <h5 className="mt-3">{t("authentication.callback.completing") || "Completing sign in..."}</h5>
        <p className="text-muted">{t("authentication.callback.wait") || "Please wait while we sign you in."}</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="d-flex flex-column justify-content-center align-items-center" style={{ minHeight: "50vh" }}>
        <div className="text-center">
          <div className="text-danger mb-3" style={{ fontSize: "3rem" }} aria-hidden="true">✕</div>
          <h5 className="text-danger">{t("authentication.callback.failedTitle") || "Sign in failed"}</h5>
          <p className="text-muted">{error}</p>
          <p className="text-muted">{t("authentication.callback.redirecting") || "Taking you back to sign in..."}</p>
        </div>
      </div>
    );
  }

  return null;
};

export default AuthCallback;
```

`src/utils/locales/eng.json`, inside `"authentication": { … }` (line 810) add:

```json
    "callback": {
      "completing": "Completing sign in...",
      "wait": "Please wait while we sign you in.",
      "failedTitle": "Sign in failed",
      "redirecting": "Taking you back to sign in...",
      "noCode": "Sign in didn't finish. Please try again.",
      "codeExpired": "This sign-in link has expired. Please sign in again.",
      "banned": "This account has been suspended.",
      "emailExists": "An account with this email already exists. Sign in with your email and password.",
      "generic": "Sign in failed. Please try again."
    },
```

- [ ] **Step 4: Run → PASS**, then `CI=true npm test -- --watchAll=false auth/`.

- [ ] **Step 5: Commit** (tick `P3-LINK-5`; add to §4: `- [ ] After this web release is live: backend removes the legacy `token=` from the Google callback redirect (backend REMAINING_WORK). S`)

```bash
git add src/constants.ts src/components/auth/AuthCallback.tsx src/components/auth/AuthCallback.test.tsx \
  src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(auth): Google sign-in exchanges a one-time code

Web Google login took the JWT from ?token= in the URL (history, logs,
Referer) and never received a refresh token. The callback now exchanges
the single-use ?code= at POST /auth/google/exchange, stores token and
refresh token like the email login, and scrubs both values from the
address bar before awaiting. StrictMode cannot spend the code twice; the
legacy ?token= path keeps working until the backend drops it; refusals
(email exists, banned, expired code) show localized messages.

Still open (Phase 3 links): http links on legal pages, callback string
translations; backend drops token= once this is live; owner applies the
nginx snippet.
EOF
```

---

### Task P3-LINK-6: Legal pages link to https://banatalk.com (links#19)

**Files:**
- Modify: `src/components/navbar/PrivacyPolicy.tsx:322`, `src/components/navbar/DataDeletion.tsx:165`
- Test (new): `src/seo/noInsecureOwnLinks.test.ts`

**Interfaces:** none. (Docs/emails with `bananatalk.com` are backend/app items, P1-LINK-8.)

- [ ] **Step 1: Write the failing test** `src/seo/noInsecureOwnLinks.test.ts`

```ts
/**
 * @jest-environment node
 */
import fs from "fs";
import path from "path";

// Our own site is https-only (http 301s). Plain-http links cost a redirect and
// show "not secure" on the hop; the parked bananatalk.com (double n) is not ours.
function walk(dir: string, out: string[] = []): string[] {
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    if (fs.statSync(full).isDirectory()) walk(full, out);
    else if (/\.(tsx?|html|json)$/.test(name) && !/\.test\./.test(name)) out.push(full);
  }
  return out;
}

it("links to banatalk.com over https only, and never to bananatalk.com", () => {
  const root = path.resolve(__dirname, "../..");
  const files = walk(path.join(root, "src")).concat(walk(path.join(root, "public")));
  const offenders = files.filter((f) => /http:\/\/(www\.)?banatalk\.com|https?:\/\/(www\.|api\.)?bananatalk\.com/.test(fs.readFileSync(f, "utf8")));
  expect(offenders.map((f) => path.relative(root, f))).toEqual([]);
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links && CI=true npm test -- --watchAll=false noInsecureOwnLinks
```
Expected: FAIL listing `src/components/navbar/PrivacyPolicy.tsx` and `src/components/navbar/DataDeletion.tsx`.

- [ ] **Step 3: Implement** — in both files replace `href="http://banatalk.com"` with `href="https://banatalk.com"`.

- [ ] **Step 4: Run → PASS.**

- [ ] **Step 5: Commit** (tick `P3-LINK-6`)

```bash
git add src/components/navbar/PrivacyPolicy.tsx src/components/navbar/DataDeletion.tsx src/seo/noInsecureOwnLinks.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(links): legal pages link to https://banatalk.com

The privacy policy and data deletion pages linked to http://banatalk.com,
a redirect hop. A test now refuses plain-http links to our domain and any
link to the parked bananatalk.com.

Still open (Phase 3 links): translations for stories.link.* and
authentication.callback.*; owner applies the nginx snippet; Phase 5 adds
/story/* and /chat/* to the AASA.
EOF
```

---

#### Keys added by P3-LINK-* (English; the unit's translation task fills the 17 other locales)

| Key | English |
|---|---|
| `stories.link.sign_in_title` | Someone shared a story with you |
| `stories.link.sign_in_body` | Sign in to watch it, or open it in the BananaTalk app. |
| `stories.link.sign_in` | Sign in |
| `stories.link.expired` | This story has expired or was deleted. Stories disappear after 24 hours. |
| `stories.link.unavailable` | This story isn't available to you. |
| `stories.link.failed` | We couldn't load this story. |
| `stories.link.retry` | Try again |
| `stories.link.browse` | See current stories |
| `authentication.callback.completing` | Completing sign in... |
| `authentication.callback.wait` | Please wait while we sign you in. |
| `authentication.callback.failedTitle` | Sign in failed |
| `authentication.callback.redirecting` | Taking you back to sign in... |
| `authentication.callback.noCode` | Sign in didn't finish. Please try again. |
| `authentication.callback.codeExpired` | This sign-in link has expired. Please sign in again. |
| `authentication.callback.banned` | This account has been suspended. |
| `authentication.callback.emailExists` | An account with this email already exists. Sign in with your email and password. |
| `authentication.callback.generic` | Sign in failed. Please try again. |

#### Device / browser QA rows for the LINKS unit (add to app `docs/qa/regression-suite.csv`, Web area)

- iOS Safari, app installed: open `https://banatalk.com/moment/<id>` directly → smart banner "Open" opens that moment (not home).
- iOS Safari: navigate inside the site from `/moments` to a moment, then tap the banner → note whether Safari used the updated argument (unverified behaviour).
- iOS, app 2.6.1: tap `https://banatalk.com/chat/<id>` and `/profile/edit` in Notes → both stay in Safari (after Apple's CDN refresh).
- Signed out on a phone: open `https://banatalk.com/story/<id>` → sign-in card; "Open in app" opens the app (2.7.0: the story).
- Google sign-in on web after backend P1-LINK-5: URL bar never shows `code=`/`token=` after landing; reload of `/auth/callback` shows "Sign in didn't finish".
- After the owner applies the nginx snippet: KakaoTalk, Telegram and WhatsApp previews of a moment, profile and `/i/<code>` link show the real title/picture.


### Task P3-LINK-7: Chat story cards open `/story/:id` (chat#9 follow-up, links#1)

P3-CHAT-13 shipped `useOpenStoryFromChat`, which reads `GET /stories/:id` and navigates to `/stories/<authorId>`
because `/story/:id` did not exist yet. P3-LINK-4 adds that page, and the page already handles every state the hook
handled (live → author's viewer at the right index, 404 expired, 403 hidden, signed out). The hook becomes a plain
navigation. Do this task **after** rebasing `web/p3-links` onto the `origin/main` that contains the CHAT push.

**Files:**
- Modify: `src/components/chat/lib/useOpenStoryFromChat.ts` (whole file, as P3-CHAT-13 Step 3a wrote it)
- Test: `src/components/chat/lib/useOpenStoryFromChat.test.tsx` (replace)
- Modify: `src/utils/locales/eng.json` only if `chatPage.story.unavailable` is no longer used anywhere (`grep -rn "chatPage.story.unavailable" src`); otherwise leave it.

**Interfaces:**
- Consumes: route `story/:id` → `StoryLinkPage` (P3-LINK-4).
- Produces: unchanged signature `useOpenStoryFromChat(): (storyId: string) => void`; `storyOwnerId` stays exported (P3-CHAT-13's test and any other caller keep compiling).

- [ ] **Step 1: Write the failing test** — replace `src/components/chat/lib/useOpenStoryFromChat.test.tsx` with:

```tsx
import { renderHook, act } from "@testing-library/react";
import { useOpenStoryFromChat, storyOwnerId } from "./useOpenStoryFromChat";

const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

const originalFetch = global.fetch;
beforeEach(() => {
  (global as any).fetch = jest.fn();
});
afterEach(() => {
  global.fetch = originalFetch;
  jest.clearAllMocks();
});

describe("storyOwnerId", () => {
  it("reads a populated or bare user", () => {
    expect(storyOwnerId({ data: { user: { _id: "u9" } } })).toBe("u9");
    expect(storyOwnerId({ data: { user: "u9" } })).toBe("u9");
    expect(storyOwnerId({ data: {} })).toBe("");
  });
});

it("opens the story's own page, without reading the story first", () => {
  const { result } = renderHook(() => useOpenStoryFromChat());
  act(() => result.current("6a0b0c0d0e0f101112131415"));
  expect(mockNavigate).toHaveBeenCalledWith("/story/6a0b0c0d0e0f101112131415");
  expect((global as any).fetch).not.toHaveBeenCalled();
});

it("encodes an odd id instead of building a broken path", () => {
  const { result } = renderHook(() => useOpenStoryFromChat());
  act(() => result.current("a/b"));
  expect(mockNavigate).toHaveBeenCalledWith("/story/a%2Fb");
});

it("does nothing without a story id", () => {
  const { result } = renderHook(() => useOpenStoryFromChat());
  act(() => result.current(""));
  expect(mockNavigate).not.toHaveBeenCalled();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links && CI=true npm test -- --watchAll=false useOpenStoryFromChat
```
Expected: FAIL — the hook needs a Redux store (`useDispatch` outside a Provider throws), and it navigates to `/stories/…` only after a fetch.

- [ ] **Step 3: Implement** — replace the whole of `src/components/chat/lib/useOpenStoryFromChat.ts` with:

```ts
import { useCallback } from "react";
import { useNavigate } from "react-router-dom";

/** The author of a GET /stories/:id answer, populated or not. */
export function storyOwnerId(response: any): string {
  const story = response && (response.data || response);
  const user = story && story.user;
  if (!user) return "";
  return typeof user === "string" ? user : user._id ? String(user._id) : "";
}

/**
 * Open the story a chat message points at. /story/:id (StoryLinkPage) reads
 * the story, sends a live one to its author's viewer at the right index, and
 * shows the expired / hidden / signed-out states itself.
 */
export function useOpenStoryFromChat(): (storyId: string) => void {
  const navigate = useNavigate();
  return useCallback(
    (storyId: string) => {
      if (!storyId) return;
      navigate(`/story/${encodeURIComponent(storyId)}`);
    },
    [navigate]
  );
}

export default useOpenStoryFromChat;
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false useOpenStoryFromChat MessageBubble ChatContent StoryLinkPage
```

- [ ] **Step 5: Commit**

```bash
git add src/components/chat/lib/useOpenStoryFromChat.ts src/components/chat/lib/useOpenStoryFromChat.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(chat): story cards open the story's own page

The chat unit had to read the story and jump to the author's stories
because /story/:id did not exist. It does now (StoryLinkPage), and it
handles expired, hidden and signed-out cases, so the card just
navigates there.

Still open (Phase 3 links): i18n, push gate; backend og type for story.
EOF
```

---

### Task P3-LINK-I18N: The links unit's new strings in all 18 locales

**Files:**
- Create if missing in this branch (verbatim copy from P3-CHAT-I18N): `scripts/i18n/new-keys.js`, `src/utils/locales/p3Keys.test.ts`
- Create: `scripts/i18n/keys/2026-10-16-p3-links.json` (all 18 locales; the durable record of what this unit translated)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: every English string the unit's tasks added to `eng.json` — listed in the key table at the end of P3-LINK-6 (`#### Keys added by P3-LINK-*`). The script below finds them from the diff against `web/p3-base`, so a key a task added but forgot to list is still caught.
- Produces: no English-only key in this unit's push.

Tooling and translation rules: as in Task P3-CHAT-I18N (copy `scripts/i18n/new-keys.js` and `src/utils/locales/p3Keys.test.ts` verbatim if this branch does not have them yet).

- [ ] **Step 1: Write the failing test** (copy the guard if missing) and generate the keys file

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links
node scripts/i18n/new-keys.js web/p3-base scripts/i18n/keys/2026-10-16-p3-links.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: the script prints `N new or changed keys` (N matches the unit's key tables, give or take keys a task added beyond its table); the test FAILS with `<key>: missing` for each of the 17 non-English locales.

- [ ] **Step 2: Translate**

Fill every `""` in `scripts/i18n/keys/2026-10-16-p3-links.json` for the 17 non-English locales (rules above). Re-running `new-keys.js` keeps what is already filled.

- [ ] **Step 3: Merge into the locale files**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p3-links.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: all `p3Keys` cases pass; the existing `src/utils/i18n*.test.ts` suites stay green (locale chunks still parse).

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/keys/2026-10-16-p3-links.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
i18n(links): translate the Phase 3 links strings into all 18 locales

Keys found by scripts/i18n/new-keys.js against web/p3-base and merged
with merge-keys.js; p3Keys.test.ts fails on any missing, empty or
placeholder-mismatched translation.

Still open (Phase 3 links): push gate (P3-LINK-PUSH); native review of
the new strings.
EOF
```

---
### Task P3-LINK-PUSH: Push unit LINK (4 of 4) — full suite + build green, then the coordinator pushes

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status line, §6 changelog line, §3 production-QA lines for the smoke list below)

- [ ] **Step 1: Every task in the unit is committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p3-links
git status --short                                   # expect: nothing (except the node_modules symlink, untracked)
grep -n "P3-LINK-" docs/REMAINING_WORK.md | grep -c "\[ \]"   # expect: 1 (this PUSH line only)
```

- [ ] **Step 2: Rebase onto the live site**

```bash
git fetch origin
git rebase origin/main
```
Conflicts: locale files and `docs/REMAINING_WORK.md` (keep both; re-run merge-keys with `scripts/i18n/keys/2026-10-16-p3-links.json`), `src/components/chat/lib/useOpenStoryFromChat.ts` (P3-LINK-7 is written against CHAT's version; if LINK-7 was done before the CHAT push, redo it after the rebase), `src/router/routes.tsx` (keep every unit's routes), the shared i18n tooling (take `origin/main`).
After resolving: `git rebase --continue`, then re-run `CI=true npm test -- --watchAll=false p3Keys` (keys from earlier units must still be complete).

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `Test Suites: … 0 failed`, `Tests: … 0 failed`; passed count ≥ the previous push's count plus this unit's new tests (baseline before Phase 3: 3190 passed, 6 skipped). Any failure: fix in a new commit (never `--no-verify`, never skip a test to get green).

- [ ] **Step 4: Production build**

```bash
npm run build 2>&1 | tail -20
```
Expected: `Compiled successfully` or `Compiled with warnings` with **no** TypeScript error (TS 3.7 rejects newer syntax here first), then the prerender step finishes without an error line. Optional: `npm run test:budget` and note the first-paint size in the tracker (the budget is already over by ~5 KB; not a gate).

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P3-LINK-PUSH`; §1 Status: "Phase 3 links pushed (YYYY-MM-DD)"; §6 Done: one line naming the unit's fixes; §3 Production QA: one `- [ ]` line per smoke item below that is not yet checked.

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: Phase 3 links ready to deploy

Still open (Phase 3): the remaining units' tasks; production smoke
for links (docs/REMAINING_WORK.md §3); device QA rows.
EOF
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p3-links:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/            # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1   # a new bundle hash
```

- [ ] **Step 7: Production smoke (two accounts: one on the web, one in app 2.6.1)**

  - [ ] `curl -s https://banatalk.com/.well-known/apple-app-site-association` → no `/chat/*`, excludes listed before the wildcards.
  - [ ] iPhone Safari: open `https://banatalk.com/moment/<id>` → the smart banner's Open goes to that moment in the app.
  - [ ] Signed out: `https://banatalk.com/story/<id>` → sign-in card with Open in app; signed in: redirects into the story; an expired id shows the expired card.
  - [ ] Google sign-in on web → lands signed in; the address bar never shows `code=` or `token=`.
  - [ ] A chat story card (P3-CHAT-13) now opens `/story/<id>`.
  - [ ] Android Chrome on `/i/<code>` and `/card/<id>` → the app banner shows and opens the app.

Record results in `docs/REMAINING_WORK.md` §3 in the next unit's first commit (or a docs-only commit if this is the last unit). A failure that breaks a live flow → Step 8.

- [ ] **Step 8 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p3-links-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -40
CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(The unit is a linear series after the rebase, so the range revert is clean. Note the revert in §6 and reopen the tasks.)

---

## After the four pushes (phase gate, not a task)

- Every `P3-` line in the web `docs/REMAINING_WORK.md` is ticked, or moved to §2 (owner) / §3 (production QA) with a reason.
- Device/browser QA rows are added to the app's `docs/qa/regression-suite.csv` (area "Web"), at minimum: a web voice
  note (chat and moment, recorded in Safari and in Chrome) plays in the iOS app; web ↔ app chat of each message kind
  (call card, location, wave, story share/reply, deleted placeholder, edited label); smart banner opens the current page
  on iOS; `/story/<id>` signed out and signed in; Google web sign-in leaves no `code=`/`token=` in the URL; link previews
  in KakaoTalk / Telegram / WhatsApp once the owner applies the nginx snippet. The LINKS section lists its six rows.
- Coordinator removes the five worktrees (`git worktree remove`) after the last push.

## Not in this plan (belongs elsewhere)

- **Owner (Phase 5):** apply `deploy/nginx.snippet.conf` incl. the crawler rule (P3-LINK-1); `www` certificate; Play
  fingerprints into `assetlinks.json`; add `/story/*` and `/chat/*` to the AASA once 2.7.0 is most of the iOS base.
- **Backend follow-ups found while planning** (file in the backend `docs/REMAINING_WORK.md`, not implemented here):
  - `controllers/og.js` has no `story` type, so `/story/<id>` previews show the generic card (the nginx rule already
    routes them; lights up when the type exists).
  - Message search may 500 on every request: a `$text` clause and an unindexed regex share one `$or`. P3-CHAT-16 Step 0
    probes prod; the web ships an "unavailable" state either way.
  - Location messages with latitude or longitude exactly `0` are refused (truthiness check in `createMessage`).
  - A photo comment can't carry mentions (multipart strings vs `sanitizeMentions` array); a correction with a photo
    can't be one multipart request.
  - Remove the `?token=` Google callback once this release is live (P3-LINK-5 keeps a fallback until then).
- **App follow-ups:** story overlay/mention pixel offsets vs exact centre; `allowReplies`/`allowSharing` unused in the
  app viewer; no archive view in the app (web-only archive, P3-CHAT-18) — product decision.
- **Web leftovers not covered:** `ActiveFilterChips` / `MemberCard` hard-coded English; composing @mentions in web
  comments (only rendering is planned); coins / rewarded unlocks on web (wave cap and Today offer VIP only); bundle budget.
- **Phase 4** (reels, gatherings/clubs, voice rooms, calls, language rooms, City/Genders tabs, Sign in with Apple):
  `2026-10-16-web-app-parity-phase4.md`.
