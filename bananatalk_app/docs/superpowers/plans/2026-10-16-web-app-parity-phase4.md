# Web ↔ App Parity — Phase 4 (new website features, dark behind flags) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give banatalk.com the features it never had — reels, gatherings/clubs, voice rooms, language rooms with the community City and Genders tabs, 1:1 voice/video calls with app users, and Sign in with Apple — each one invisible (no nav entry, no route, no button) until its `/app-config` flag is switched on by the owner after browser QA.

**Architecture:** Five push units, each built in its own worktree and ending in a push gate (full Jest suite + `npm run build` green, then the coordinator pushes, which deploys — dark). Order of pushes: REELS → GATHERINGS → ROOMS → CALLS → APPLE. REELS, GATHERINGS, ROOMS and APPLE branch off one shared base (`web/p4-base`, Task P4-0); CALLS branches off `web/p4-rooms` right after P4-ROOM-1 (the LiveKit wrapper it reuses) and rebases onto `origin/main` once ROOMS is pushed. Every feature is a client of endpoints the app already uses (pinned by the backend's `test/webFeatureContracts.test.js`, backend `07febec`, deployed); the only backend endpoint new for the web is `POST /api/v1/auth/apple/web`. One shared flag module (`src/utils/webFlags.ts` + `src/router/FlagRoute.tsx`, Task P4-0) is the only place the website reads the six flags. One new npm dependency: `livekit-client@2.22.4` (exact), added by P4-ROOM-1 behind a JS loader + `.d.ts` because its typings do not parse under TypeScript 3.7.

**Tech Stack:** React 18 + TypeScript **3.7.2** (CRA 5 / react-scripts), RTK Query (`apiSlice.injectEndpoints`), socket.io-client 4 (shared `SocketProvider`), react-i18next (18 locale JSON files in `src/utils/locales/`), react-toastify, Jest + React Testing Library; new: `livekit-client` 2.22.4 (WebRTC, lazy chunk `livekit`), Apple JS (`appleid.auth.js`, loaded from Apple's CDN at click time).

**Spec:** `bananatalk_app/docs/superpowers/specs/2026-10-16-web-app-parity-design.md` §3 Phase 4 and §4 Flags. **Previous phase:** `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md` (fully pushed; web `origin/main` = `6b905f4`) (its announced APIs are listed under "Depends on Phase 3" below). **Backend contract:** `be-integration/test/webFeatureContracts.test.js` (endpoints + fields), `be-integration/controllers/appConfig.js:151-157` (flags), `be-integration/controllers/auth.js:455-495` (`appleWebLogin`). **App reference:** `bananatalk_app/lib/` (cited per task).

## Global Constraints

- **Web deploys on push to `main`** (`.github/workflows/deploy.yml`, Node 18, `npm ci` then `npm run build`). Never push without a green full suite and a green `npm run build` in the worktree you push from. Only the coordinator pushes, only at a unit's `*-PUSH` step.
- **Precondition:** Phase 3 is complete — all four Phase 3 units are pushed (web `origin/main` = `6b905f4` "docs: Phase 3 chat pushed; Phase 3 complete" or later, and `git show origin/main:docs/REMAINING_WORK.md | grep -c -- "- \[ \] P3-"` prints `0`) and the backend at `07febec` or later is live: `curl -s https://api.banatalk.com/api/v1/app-config | grep -o '"web[A-Za-z]*Enabled":[a-z]*'` prints the six flags, all `false`. Phase 4 never branches from the stale local `main` of `/Users/davis/Desktop/Personal/language_exchange_web_front`.
- **Dark until flagged (spec §4).** While a unit's flag is `false` (and while `/app-config` is loading or failed) the website shows **no** nav entry, **no** route (the path renders `NotFound`), and **no** button for that feature. All reads go through `useWebFlag()` / `<FlagRoute>` from P4-0 — no component reads `appConfig.web*` directly. Global switches still apply on top: reels also need `reelsEnabled`, gatherings/clubs `gatheringsEnabled`, language rooms `roomsEnabled` (encoded once in `WEB_FLAG_REQUIRES`). Every unit has a task whose test renders the router, the navbar and the touched screens with every flag `false` and asserts each entry point is absent.
- **Flag flip semantics.** Flags are re-read on window focus (`refetchOnFocus`, needs Phase 3's `setupListeners` in `src/store/index.ts`). Flipping a flag **off** hides entry points on the next read but never tears down a call or room already in progress (the endpoints are shared with the app and stay live). Flipping **on** shows the feature on the next focus/reload.
- **Legacy data:** reels and moments written by app 2.6.1 (no `video.thumbnail`, `video.duration` missing or `0`, unpopulated `user`), gatherings/clubs with missing optional fields, call history rows from before `callUuid` existed — all render without a crash or a blank card.
- **TypeScript 3.7.2:** no `import type`, no `export * as ns`, no `satisfies`, no template-literal types, no labelled/variadic tuples, no `#private` fields, no `abstract` constructor types. `?.` and `??` are fine. Slices keep the house style (`builder: any`, hooks re-exported `as any`). **Third-party typings that need TS ≥ 3.8 must never enter the program**: `livekit-client` is reached only through `src/lib/livekit/livekitLoader.js` (listed in `tsconfig.json` `exclude`) and its hand-written `livekitLoader.d.ts`. Verified while planning (2026-10-16, scratch copy of `origin/main` `fba6208`): importing `livekit-client` from a `.ts` file under TS 3.7.2 gives 621 parse errors (its `typesVersions` fallback `dist/ts4.2` still uses `import type`); the loader + `.d.ts` + `exclude` pattern gives 0, and a CRA 5 production build of `origin/main` plus the loader emits a separate `livekit.<hash>.chunk.js` (596 KB raw / 151 KB gzipped) with no `livekit-client` string in `main.js`. **Know what enforces this:** `react-scripts build` does **not** fail on type errors in this repo (a deliberate `const x: number = "s"` in `src/utils/timeAgo.ts` built fine; Babel strips types, and Babel parses newer syntax such as `import type` too). So the TS 3.7 rules are a house rule held by review, by editors running the repo's TS 3.7.2, and by this check, which every `*-PUSH` task of ROOMS and CALLS runs: `npx tsc -p . 2>&1 | grep "error TS" | grep -c -i livekit` → `0` (plain `tsc` is already noisy on `origin/main` — ~1,850 parse errors inside `node_modules` typings such as RTK and react-bootstrap — so the check greps for the new package only).
- **Lazy, never eager:** every Phase 4 screen is a `lazyWithRetry` route; `livekit-client` and Apple JS are fetched only when a user joins a room, places/accepts a call, or clicks "Sign in with Apple". `src/seo/eagerGraph.test.ts` gains `livekit-client` as a forbidden eager package (P4-ROOM-1). The only eager additions are the tiny `FlagRoute`, `webFlags.ts` and the CALLS `IncomingCallHost`/`callBridge` shell plus the navbar's `CallsNavLink` (which imports `callsSlice` for the missed-call badge) — together ≤ 3 KB gzipped, no LiveKit import; the call engine is the lazy `calls` chunk.
- **Strings:** every new user-facing string goes through `t("<ns>.<key>") || "English fallback"`. Each task adds its English to `src/utils/locales/eng.json` in its own commit. The other 17 locales are filled once per unit by that unit's `*-I18N` task through `scripts/i18n/new-keys.js` (diff base `web/p4-base`) and `scripts/i18n/merge-keys.js` (which refuses partial input), before the unit's push. Keys files are `scripts/i18n/keys/2026-10-16-p4-<unit>.json`; the guard is the Phase 3 `src/utils/locales/p3Keys.test.ts`, widened by P4-0 to also read `2026-10-16-p4-*.json`. No unit is pushed with English-only keys. Namespaces: `reels.*`, `gatherings.*`, `clubs.*`, `voiceRooms.*`, `languageRooms.*`, `community.cityTab.*`/`community.gendersTab.*`, `calls.*`, `auth.apple.*`.
- **RTL (`ar`):** new layout uses logical properties (`margin-inline-start`, `padding-inline-end`, `inset-inline-*`, `text-align: start`). Video tiles, the reels swipe axis and call controls are never mirrored.
- **Media permissions:** every `getUserMedia` path (mic for voice rooms, mic/camera for calls) maps errors through `mediaErrorKind()` (P4-ROOM-1): `NotAllowedError`/`SecurityError` → `denied`, `NotFoundError`/`OverconstrainedError`/`NotReadableError` → `unavailable`; each kind has a localized message; a denied mic never blocks listening.
- **Tests:** TDD per task. Single file: `CI=true npm test -- --watchAll=false <pattern>`. Full: `CI=true npm test -- --watchAll=false`. Build: `npm run build` (CRA build + `scripts/prerender.js`). Copy mocks from the neighbouring test file named in each task; do not invent new global mocks. CRA's Jest config sets `resetMocks: true`, so mock implementations (`mockReturnValue`, `mockImplementation`) are set in `beforeEach`, never once at module level. **Jest never loads the real `livekit-client`** (it is ESM-only `.mjs` and outside `transformIgnorePatterns`): every test that reaches a room or a call does `jest.mock("<rel>/lib/livekit/livekitLoader", () => require("<rel>/lib/livekit/testing/fakeLivekit").loaderMock())` with the fake from P4-ROOM-1 — or, for CALLS, mocks the `lkSession` module itself (`src/lib/livekit/testing/fakeLkSession.ts`, P4-CALL-2/8, keeping the real `mediaErrorKind`), which is the contract boundary and never reaches the loader. Apple JS is never fetched in tests (`window.AppleID` is stubbed).
- **Commits:** one per task. `git add` explicit paths (never `-A` inside a unit) plus `docs/REMAINING_WORK.md`, which each commit edits: tick the task's own `- [ ] P4-…` line, and end the body with `Still open (Phase 4 <unit>): …`. **No `Co-Authored-By`, no AI attribution** in commits or PRs.
- **Tracker:** the web repo's `docs/REMAINING_WORK.md`, section "Web/app parity". Task P4-0 replaces the six coarse "Phase 4 …" lines with one line per task, so each task can tick its own.
- **Node modules:** REELS, GATHERINGS and APPLE worktrees symlink the main checkout's `node_modules` (as Phase 3 did) and install nothing. ROOMS and CALLS get a **real** `node_modules` (`npm ci` in the worktree) because ROOMS adds `livekit-client@2.22.4`; never run `npm install` through a symlinked `node_modules` (npm would prune or add packages in the shared tree used by every other worktree). **After ROOMS is pushed**, every worktree that rebases onto `origin/main` (CALLS already has it; APPLE) needs `livekit-client` to build: `ls node_modules/livekit-client >/dev/null 2>&1 || (rm node_modules && npm ci)` right after the rebase.

## Depends on Phase 3 (shared files and announced APIs)

Phase 4 starts after all four Phase 3 units are pushed; it plans against `origin/main` **plus** these Phase 3 interfaces (from the Phase 3 plan's `Produces:` lines). If one of them is missing on `origin/main` when a unit starts, stop and ask the coordinator — do not re-implement it.

| Phase 3 task | What Phase 4 uses | Used by |
|---|---|---|
| P3-CHAT-7 | `useSocket()` → `{ socket, isConnected, emit, connectionEpoch, kicked, reconnect }`; `refreshSession(dispatch, getState)`; `setupListeners(store.dispatch)` in `src/store/index.ts` | CALLS (re-sync ringing state on every `connectionEpoch` change), ROOMS (voice-room socket events), P4-0 (`refetchOnFocus`) |
| P3-CHAT-5 | `emitWithAck(socket, event, payload, timeoutMs, {onAck, onTimeout})`, `SOCKET_ACK_TIMEOUT_MS` from `src/components/chat/lib/socketAck.ts` | ROOMS, CALLS (acked socket emits) |
| P3-CHAT-10 | call-history message card in `MessageBubble.tsx` (`media.type === 'call'`) | CALLS adds "Call back" on that card |
| P3-CHAT-4 | limit/paywall/block dialog helpers in chat | CALLS reuses the block dialog for a 403 on `/calls/initiate` |
| P3-CHAT-I18N | `scripts/i18n/new-keys.js`, `src/utils/locales/p3Keys.test.ts` | every `*-I18N` task |
| P3-COM-6 / P3-COM-13 | community segment tabs (Serious) and the community keys test | ROOMS (City, Genders tabs next to them) |
| P3-MOM-1 / P3-MOM-8 | moment composer media upload, comment composer (GIF/photo) | REELS (reuses the comment sheet and upload endpoint) |
| P3-LINK-5 | Google sign-in reads the one-time `code` on `Login.tsx`/`AuthCallback.tsx` | APPLE (button sits next to Google; same `setCredentials` path) |

Files more than one Phase 4 unit edits (expect rebase conflicts only here; keep both sides): `src/router/routes.tsx` (each unit adds its lazy imports + `<Route>`s in its own commented block), `src/components/navbar/MainNavbar.tsx` (each unit adds one flagged entry), `src/utils/locales/*.json`, `docs/REMAINING_WORK.md`, `package.json`/`package-lock.json` + `tsconfig.json` (ROOMS only), `src/App.tsx` (CALLS only), `src/seo/eagerGraph.test.ts` (ROOMS only), and the tests `src/components/navbar/MainNavbar.test.tsx` (each unit adds the app-config mock + its flag-off case; the first unit to push adds the mock, later units keep it) and `src/components/moments/MainMoments.test.tsx` (REELS; its react-i18next mock gains `i18n.language`).

## Review Focus

Five inputs most likely to bite real users. Reviewers check each unit against these before its push step.

1. **Camera/mic permission denied, missing or busy.** Safari asks every session; Chrome remembers a "Block"; a laptop with no camera; a mic held by another app (`NotReadableError`); an `http://` dev origin (no `mediaDevices`). A listener in a voice room must still hear the room with the mic denied; "Request to speak" explains how to unblock instead of failing silently; a callee who accepts a video call with the camera denied joins audio-only and the caller sees "camera off"; a caller whose mic is denied never leaves the callee's phone ringing (the call is ended via `POST /calls/:id/end` before or right after `initiate`). Pinned by `mediaErrorKind` tests (P4-ROOM-1) and the denied-permission cases in P4-ROOM and P4-CALL tasks.
2. **The same user in several places at once.** Two web tabs plus the app on a phone: an incoming call rings in every open tab and on the phone (push from the backend); answering in one tab stops the ring in the other tabs and on the phone; declining in a tab stops everything; the user already in a call (web or app) answers a second caller as busy. A voice room joined in tab A and again in tab B must not double-publish the mic (LiveKit kicks the duplicate identity; the kicked tab shows "Joined from another tab", not a reconnect loop). Pinned by the multi-tab tests in P4-CALL and P4-ROOM.
3. **Dropped connections.** Wi-Fi drop mid-call (LiveKit `Reconnecting` → `Reconnected`, or `Disconnected` after its retries), the socket reconnecting (Phase 3 `connectionEpoch`) while ringing or in a call, laptop sleep, closing the tab mid-call (best-effort `end` on `pagehide`), a host whose tab dies (room ownership as the backend decides), and an access token expiring during a 40-minute call (REST refresh; the LiveKit token is not re-minted mid-session). No ghost "ringing" banner, no zombie participant, no duplicate call-history row. Pinned by the reconnect tests in P4-ROOM and P4-CALL.
4. **Autoplay and audio unlock (Safari, iOS Safari, Chrome autoplay policy).** Remote audio in a room or call is blocked until a user gesture; the ringtone cannot play in a tab the user never clicked. The UI shows an explicit "Tap to enable sound" control (`LkSession.startAudio()`), an incoming call is visible without sound (banner + title flash), and reels start muted with a visible unmute. Pinned by the `onAudioBlocked` tests (P4-ROOM-1), the ring banner tests (P4-CALL) and the reels autoplay test (P4-REEL).
5. **Flags flipped mid-session, and the TypeScript 3.7 / lazy-chunk boundary.** A flag turned off while a user is in a room or a call does not end it, but entry points vanish on the next focus; a deep link to a flagged route while `/app-config` is still loading shows a spinner, not a 404 flash; a failed `/app-config` hides everything. The `livekit` chunk failing to load (a tab open across a deploy) shows a retryable error, not a white screen; no `.ts` file imports `livekit-client` directly (the build would fail on TS 3.7); Jest never loads it. Pinned by P4-0's flag tests, the flag-off test in every unit, and P4-ROOM-1's loader/eager-graph tests.

## Execution

1. Coordinator: Task P4-0 (shared base branch `web/p4-base`: flag module, route gate, widened keys guard, per-task tracker lines).
2. Worktrees off `web/p4-base`, worked in parallel (one implementer each, tasks in order inside a unit):
   - REELS `/Users/davis/Desktop/Personal/wt-web-p4-reels` (branch `web/p4-reels`)
   - GATHERINGS `/Users/davis/Desktop/Personal/wt-web-p4-gatherings` (branch `web/p4-gatherings`)
   - ROOMS `/Users/davis/Desktop/Personal/wt-web-p4-rooms` (branch `web/p4-rooms`)
   - APPLE `/Users/davis/Desktop/Personal/wt-web-p4-apple` (branch `web/p4-apple`)
   - CALLS `/Users/davis/Desktop/Personal/wt-web-p4-calls` (branch `web/p4-calls`) — created **from `web/p4-rooms` after P4-ROOM-1 is committed** (see P4-CALL-0), so the LiveKit wrapper and the `livekit-client` dependency are already there.
3. Pushes in order REELS → GATHERINGS → ROOMS → CALLS → APPLE, each through its `*-PUSH` task. A later unit rebases on the new `origin/main` first (CALLS: after ROOMS is pushed, its copy of P4-ROOM-1 is already upstream and drops out of the rebase). Expected conflicts are listed in each push task.
4. After APPLE is pushed: the owner turns the flags on one at a time after browser QA (Phase 5, `docs/ops/2026-10-16-web-hosting-steps.md`), Apple last (needs the Services ID). Phase 4 is done when the five units are deployed dark and every `P4-` line in the tracker is ticked or moved to an owner/device line.

## Shared contracts (fixed here so parallel units agree)

**Flags (P4-0)** — `src/utils/webFlags.ts`:
- `type WebFlag = "webReelsEnabled" | "webGatheringsEnabled" | "webVoiceRoomsEnabled" | "webLanguageRoomsEnabled" | "webCallsEnabled" | "webAppleSigninEnabled"`
- `WEB_FLAG_REQUIRES: { [K in WebFlag]?: string }` = `{ webReelsEnabled: "reelsEnabled", webGatheringsEnabled: "gatheringsEnabled", webLanguageRoomsEnabled: "roomsEnabled" }`
- `useWebFlagState(flag): { on: boolean; ready: boolean }`, `useWebFlag(flag): boolean`, `isWebFlagOn(config, flag): boolean` (pure, for non-hook callers and tests).
- `src/router/FlagRoute.tsx`: default export `FlagRoute` props `{ flag: WebFlag; children: React.ReactNode }` — spinner (`data-testid="flag-route-loading"`) while not ready, `NotFound` when off, children when on.
- Test helper `src/utils/testing/mockWebFlags.ts`: `mockAppConfig(flags: Partial<AppConfig> | "loading" | "error")` sets what the mocked `useGetAppConfigQuery` returns; used as `jest.mock("<rel>/store/slices/appConfigSlice", () => require("<rel>/utils/testing/mockWebFlags").appConfigSliceMock())`.

**LiveKit (P4-ROOM-1; CALLS reuses it unchanged)** — `src/lib/livekit/`:
- `livekitLoader.js` + `livekitLoader.d.ts`: `loadLivekit(): Promise<any>` (cached `import(/* webpackChunkName: "livekit" */ "livekit-client")`, cache cleared on failure).
- `lkSession.ts`: `createLkSession(events: LkEvents): LkSession`; `mediaErrorKind(err): LkMediaResult`;
  `type LkMediaResult = "ok" | "denied" | "unavailable" | "error"`;
  `interface LkPeer { identity: string; name: string; isLocal: boolean; isSpeaking: boolean; micOn: boolean; cameraOn: boolean; metadata: string }`;
  `interface LkVideoTrack { attach(el: HTMLVideoElement): void; detach(el?: HTMLVideoElement): void }`;
  `interface LkEvents { onPeers?(peers: LkPeer[]): void; onState?(s: "connecting" | "connected" | "reconnecting" | "disconnected"): void; onDisconnected?(reason: string): void; onAudioBlocked?(blocked: boolean): void; onRemoteVideo?(identity: string, track: LkVideoTrack | null): void; }`;
  `interface LkSession { connect(url: string, token: string, opts: { mic: boolean; camera: boolean }): Promise<LkMediaResult>; setMic(on: boolean): Promise<LkMediaResult>; setCamera(on: boolean): Promise<LkMediaResult>; localVideo(): LkVideoTrack | null; startAudio(): Promise<boolean>; peers(): LkPeer[]; disconnect(): Promise<void>; }`
  (`connect` resolves with the media result of publishing the requested mic/camera; the room connection itself rejects only on a network/token failure.) `onDisconnected` reasons: `"client"`, `"duplicate_identity"`, `"room_deleted"`, `"participant_removed"`, `"server_shutdown"`, `"network"`, `"unknown"`.
- `testing/fakeLivekit.ts`: `loaderMock()` (module shape for `jest.mock`), `fakeRoom()` → the last created fake `Room` with `emit(event, ...args)`, `localParticipant` spies (`setMicrophoneEnabled`, `setCameraEnabled`), `connect`/`disconnect` spies, `startAudio` spy, `canPlaybackAudio` flag, and `failNextMedia(name: string)` to throw a `DOMException`-like `{name}` from the next `set*Enabled`.

---

### Task P4-0: Shared base branch — flag module, route gate, keys guard, per-task tracker lines

**Files:**
- Create: `src/utils/webFlags.ts`, `src/utils/webFlags.test.tsx`, `src/router/FlagRoute.tsx`, `src/router/FlagRoute.test.tsx`, `src/utils/testing/mockWebFlags.ts`
- Modify: `src/utils/locales/p3Keys.test.ts` (key-file pattern), `docs/REMAINING_WORK.md` (section "Web/app parity": the six lines starting `- [ ] Phase 4 `)

**Interfaces:**
- Consumes: `GET /api/v1/app-config?platform=web&lang=<lng>` → `data.webReelsEnabled … data.webAppleSigninEnabled` (booleans, default false; `be/controllers/appConfig.js:151-157`), plus the global `reelsEnabled`, `gatheringsEnabled`, `roomsEnabled` (`:131,144,149`). `useGetAppConfigQuery` (`src/store/slices/appConfigSlice.ts`), called with exactly the args `useWebAnnouncements` uses (`{ platform: "web", lang: i18n.language }`) so both share one cache entry and one request.
- Produces: see "Shared contracts → Flags" above.

- [ ] **Step 1: Base worktree on origin/main**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
git fetch origin
git log origin/main --oneline -1                                      # expect 6b905f4 or later
git show origin/main:docs/REMAINING_WORK.md | grep -c -- "- \[ \] P3-"  # expect 0 (Phase 3 complete)
git worktree add -b web/p4-base /Users/davis/Desktop/Personal/wt-web-p4-base origin/main
cd /Users/davis/Desktop/Personal/wt-web-p4-base
ln -s /Users/davis/Desktop/Personal/language_exchange_web_front/node_modules node_modules
grep -n "setupListeners" src/store/index.ts      # expect one line (P3-CHAT-7); stop if absent
ls scripts/i18n/new-keys.js src/utils/locales/p3Keys.test.ts   # expect both (P3-CHAT-I18N)
CI=true npm test -- --watchAll=false 2>&1 | tail -5          # record the baseline counts in the tracker commit
```

- [ ] **Step 2: Write the failing tests**

Create `src/utils/testing/mockWebFlags.ts`:

```ts
// Test helper: what the mocked useGetAppConfigQuery returns. Every Phase 4
// flag-off test uses it, so "flag off", "loading" and "app-config failed"
// mean the same thing in every suite.
//
//   jest.mock("../../store/slices/appConfigSlice", () =>
//     require("../../utils/testing/mockWebFlags").appConfigSliceMock());
//   mockAppConfig({ webReelsEnabled: true, reelsEnabled: true });
let current: any = { data: {}, isError: false };
export const appConfigCalls: any[][] = [];

export function mockAppConfig(flags: { [k: string]: any } | "loading" | "error"): void {
  if (flags === "loading") current = { data: undefined, isError: false, isLoading: true };
  else if (flags === "error") current = { data: undefined, isError: true, isLoading: false };
  else current = { data: flags, isError: false, isLoading: false };
}

export const ALL_WEB_FLAGS_ON = {
  webReelsEnabled: true,
  webGatheringsEnabled: true,
  webVoiceRoomsEnabled: true,
  webLanguageRoomsEnabled: true,
  webCallsEnabled: true,
  webAppleSigninEnabled: true,
  reelsEnabled: true,
  gatheringsEnabled: true,
  roomsEnabled: true,
};

export const ALL_WEB_FLAGS_OFF = {
  webReelsEnabled: false,
  webGatheringsEnabled: false,
  webVoiceRoomsEnabled: false,
  webLanguageRoomsEnabled: false,
  webCallsEnabled: false,
  webAppleSigninEnabled: false,
  reelsEnabled: true,
  gatheringsEnabled: true,
  roomsEnabled: true,
};

export function appConfigSliceMock() {
  return {
    useGetAppConfigQuery: (...args: any[]) => {
      appConfigCalls.push(args);
      return current;
    },
  };
}
```

Create `src/utils/webFlags.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { mockAppConfig, appConfigCalls } from "./testing/mockWebFlags";
import { useWebFlagState, isWebFlagOn, WEB_FLAG_REQUIRES } from "./webFlags";

jest.mock("../store/slices/appConfigSlice", () => require("./testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "ko" } }),
}));

function Probe({ flag }: { flag: any }) {
  const s = useWebFlagState(flag);
  return <span data-testid="state">{`${s.on}/${s.ready}`}</span>;
}
const state = () => screen.getByTestId("state").textContent;

beforeEach(() => {
  appConfigCalls.length = 0;
});

it("is off and not ready while app-config loads", () => {
  mockAppConfig("loading");
  render(<Probe flag="webCallsEnabled" />);
  expect(state()).toBe("false/false");
});

it("is off and ready when app-config failed (everything stays hidden)", () => {
  mockAppConfig("error");
  render(<Probe flag="webCallsEnabled" />);
  expect(state()).toBe("false/true");
});

it("is off when the flag is missing (an older backend) or false", () => {
  mockAppConfig({});
  render(<Probe flag="webVoiceRoomsEnabled" />);
  expect(state()).toBe("false/true");
});

it("is on only for a literal true", () => {
  mockAppConfig({ webVoiceRoomsEnabled: "true" });
  const { unmount } = render(<Probe flag="webVoiceRoomsEnabled" />);
  expect(state()).toBe("false/true");
  unmount();
  mockAppConfig({ webVoiceRoomsEnabled: true });
  render(<Probe flag="webVoiceRoomsEnabled" />);
  expect(state()).toBe("true/true");
});

it("needs the global switch too where the spec names one", () => {
  expect(WEB_FLAG_REQUIRES).toEqual({
    webReelsEnabled: "reelsEnabled",
    webGatheringsEnabled: "gatheringsEnabled",
    webLanguageRoomsEnabled: "roomsEnabled",
  });
  expect(isWebFlagOn({ webReelsEnabled: true, reelsEnabled: false }, "webReelsEnabled")).toBe(false);
  expect(isWebFlagOn({ webReelsEnabled: true, reelsEnabled: true }, "webReelsEnabled")).toBe(true);
  expect(isWebFlagOn({ webGatheringsEnabled: true }, "webGatheringsEnabled")).toBe(false);
  expect(isWebFlagOn({ webLanguageRoomsEnabled: true, roomsEnabled: true }, "webLanguageRoomsEnabled")).toBe(true);
  // Voice rooms, calls and Apple have no global switch (spec §4).
  expect(isWebFlagOn({ webCallsEnabled: true }, "webCallsEnabled")).toBe(true);
  expect(isWebFlagOn(undefined, "webCallsEnabled")).toBe(false);
});

it("shares the announcements' cache entry and re-reads on focus", () => {
  mockAppConfig({});
  render(<Probe flag="webReelsEnabled" />);
  expect(appConfigCalls[0][0]).toEqual({ platform: "web", lang: "ko" });
  expect(appConfigCalls[0][1]).toEqual({ refetchOnFocus: true });
});
```

Create `src/router/FlagRoute.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { mockAppConfig } from "../utils/testing/mockWebFlags";
import FlagRoute from "./FlagRoute";

jest.mock("../store/slices/appConfigSlice", () => require("../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
jest.mock("../components/errors/NotFound", () => () => <div data-testid="not-found" />);
jest.mock("../components/Loader", () => () => <div data-testid="loader" />);

const page = () => (
  <FlagRoute flag="webGatheringsEnabled">
    <div data-testid="feature" />
  </FlagRoute>
);

it("shows a spinner, not a 404, while app-config loads (deep links)", () => {
  mockAppConfig("loading");
  render(page());
  expect(screen.getByTestId("flag-route-loading")).toBeInTheDocument();
  expect(screen.queryByTestId("not-found")).not.toBeInTheDocument();
  expect(screen.queryByTestId("feature")).not.toBeInTheDocument();
});

it("is a 404 while the flag is off", () => {
  mockAppConfig({ webGatheringsEnabled: false, gatheringsEnabled: true });
  render(page());
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
  expect(screen.queryByTestId("feature")).not.toBeInTheDocument();
});

it("is a 404 when app-config failed", () => {
  mockAppConfig("error");
  render(page());
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
});

it("renders the page when the flag and its global switch are on", () => {
  mockAppConfig({ webGatheringsEnabled: true, gatheringsEnabled: true });
  render(page());
  expect(screen.getByTestId("feature")).toBeInTheDocument();
});
```

- [ ] **Step 3: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-base && CI=true npm test -- --watchAll=false webFlags FlagRoute
```
Expected: FAIL — `Cannot find module './webFlags'` and `Cannot find module './FlagRoute'`.

- [ ] **Step 4: Implement**

Create `src/utils/webFlags.ts`:

```ts
import { useTranslation } from "react-i18next";
import { useGetAppConfigQuery, AppConfig } from "../store/slices/appConfigSlice";

/**
 * The website-only feature flags (web parity spec §4). Server env
 * WEB_*_ENABLED -> /app-config booleans, default false. This module is the
 * only place the website reads them: a feature is hidden -- no nav entry, no
 * route, no button -- unless its flag is a literal `true`.
 */
export type WebFlag =
  | "webReelsEnabled"
  | "webGatheringsEnabled"
  | "webVoiceRoomsEnabled"
  | "webLanguageRoomsEnabled"
  | "webCallsEnabled"
  | "webAppleSigninEnabled";

/**
 * Global switches that still apply on top of the web flag (spec §4):
 * REELS_ENABLED, GATHERINGS_ENABLED, ROOMS_ENABLED (language rooms). Voice
 * rooms, calls and Apple sign-in have none.
 */
export const WEB_FLAG_REQUIRES: { [flag: string]: string } = {
  webReelsEnabled: "reelsEnabled",
  webGatheringsEnabled: "gatheringsEnabled",
  webLanguageRoomsEnabled: "roomsEnabled",
};

export function isWebFlagOn(config: AppConfig | undefined | null, flag: WebFlag): boolean {
  if (!config || config[flag] !== true) return false;
  const global = WEB_FLAG_REQUIRES[flag];
  return global ? config[global] === true : true;
}

export interface WebFlagState {
  on: boolean;
  /** false only while the first app-config request is in flight. */
  ready: boolean;
}

export function useWebFlagState(flag: WebFlag): WebFlagState {
  const { i18n } = useTranslation();
  // Some suites mock react-i18next without `i18n`; fall back to "en" so the
  // hook never crashes a screen that merely shows a flagged button.
  const lang = (i18n && i18n.language) || "en";
  // Same args as useWebAnnouncements: one cache entry, one request. Re-read on
  // window focus (setupListeners, Phase 3) so a flag the owner flips shows up
  // without a reload -- and a flag flipped off hides its entry points.
  const { data, isError } = useGetAppConfigQuery(
    { platform: "web", lang },
    { refetchOnFocus: true }
  );
  if (isError && !data) return { on: false, ready: true };
  if (!data) return { on: false, ready: false };
  return { on: isWebFlagOn(data, flag), ready: true };
}

export function useWebFlag(flag: WebFlag): boolean {
  return useWebFlagState(flag).on;
}
```

Create `src/router/FlagRoute.tsx`:

```tsx
import React from "react";
import Loader from "../components/Loader";
import NotFound from "../components/errors/NotFound";
import { useWebFlagState, WebFlag } from "../utils/webFlags";

/**
 * Route gate for a Phase 4 feature. While its flag is off the path is a plain
 * 404 -- the feature does not exist as far as a visitor (or a crawler) can
 * tell. While app-config is still loading, a spinner: a deep link into a
 * flagged-on feature must not flash "page not found" first.
 */
const FlagRoute: React.FC<{ flag: WebFlag; children: React.ReactNode }> = ({ flag, children }) => {
  const { on, ready } = useWebFlagState(flag);
  if (!ready) {
    return (
      <div
        data-testid="flag-route-loading"
        style={{ minHeight: "60vh", display: "flex", alignItems: "center", justifyContent: "center" }}
        aria-busy="true"
      >
        <Loader />
      </div>
    );
  }
  if (!on) return <NotFound />;
  return <>{children}</>;
};

export default FlagRoute;
```

In `src/utils/locales/p3Keys.test.ts` replace

```ts
  ? fs.readdirSync(keysDir).filter((f) => /^2026-10-16-p3-[a-z]+\.json$/.test(f))
```
with
```ts
  ? fs.readdirSync(keysDir).filter((f) => /^2026-10-16-p[34]-[a-z]+\.json$/.test(f))
```
(and change its header comment's first line to `// Every key a Phase 3 or Phase 4 unit added (…p3-*.json / …p4-*.json, …`).

- [ ] **Step 5: Run → PASS**

```bash
CI=true npm test -- --watchAll=false webFlags FlagRoute p3Keys eagerGraph
```
Expected: all pass (`eagerGraph` stays green: `FlagRoute`/`webFlags` import nothing heavy).

- [ ] **Step 6: Per-task tracker lines**

In `docs/REMAINING_WORK.md`, replace the six coarse lines starting `- [ ] Phase 4 Reels:`, `- [ ] Phase 4 Gatherings/clubs:`, `- [ ] Phase 4 Voice rooms:`, `- [ ] Phase 4 Calls:`, `- [ ] Phase 4 Language rooms`, `- [ ] Phase 4 Sign in with Apple` with the block below (exact text; tasks tick their own line):

```markdown
Phase 4 Reels (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [ ] P4-REEL-1 Reels feed endpoint, video-config endpoint and a reel normaliser that survives 2.6.1 data
- [ ] P4-REEL-2 One-time reels content-policy gate (Apple 1.2), shared with the app via `reelsPolicyAccepted`
- [ ] P4-REEL-3 `/reels` grid: cursor paging, empty/unavailable states, "Create reel" entry
- [ ] P4-REEL-4 Full-screen reel viewer: one playing video, muted autoplay with unmute, swipe/wheel/keys, views recorded
- [ ] P4-REEL-5 Viewer actions: like, comments drawer, share, report, block
- [ ] P4-REEL-6 Create a reel: video ≤ 180 s checked before upload, `isReel: true`, rollback on a failed upload
- [ ] P4-REEL-7 Routes, navbar and Moments entry behind `webReelsEnabled` + `reelsEnabled`; flag-off test
- [ ] P4-REEL-I18N New reels strings in all 18 locales
- [ ] P4-REEL-PUSH Push unit reels (suite + build green, deployed dark, production smoke recorded)

Phase 4 Gatherings/clubs (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [ ] P4-GATH-1 Gatherings + clubs endpoints in one slice, same requests the app sends
- [ ] P4-GATH-2 Shared helpers: local start time, quorum line, host-decision window, error text
- [ ] P4-GATH-3 Browse page: Gatherings and Clubs tabs, the app's filters, load more
- [ ] P4-GATH-4 Gathering page: details, RSVP / request / leave, report or block the host
- [ ] P4-GATH-5 Host a gathering: create and edit form with the backend's limits
- [ ] P4-GATH-6 Host decisions: join requests, run it or call it off, cancel, end
- [ ] P4-GATH-7 Club page: members and roles, join/leave, upcoming gatherings, manage members
- [ ] P4-GATH-8 Create, edit and delete a club
- [ ] P4-GATH-9 Optional cover photo for a gathering or a club
- [ ] P4-GATH-10 Routes and nav entry behind `webGatheringsEnabled`; nothing visible while it is off
- [ ] P4-GATH-I18N New gatherings/clubs strings in all 18 locales
- [ ] P4-GATH-PUSH Push unit gatherings (suite + build green, deployed dark, production smoke recorded)

Phase 4 Rooms — voice rooms, language rooms, City/Genders (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [ ] P4-ROOM-1 `livekit-client@2.22.4` behind a JS loader + `.d.ts`, excluded from tsconfig, kept out of the eager graph
- [ ] P4-ROOM-2 `lkSession` facade (connect, mic/camera, audio unlock, peers, disconnect reasons) + the shared LiveKit test fake
- [ ] P4-ROOM-3 Voice rooms REST slice (list, detail, create, join, token, leave, end, promote, RSVP)
- [ ] P4-ROOM-4 Voice rooms list page with create dialog and scheduled-room RSVP
- [ ] P4-ROOM-5 `useVoiceRoom`: join → token → socket → LiveKit, heartbeat, live events, rejoin after reconnect, leave
- [ ] P4-ROOM-6 Voice room page: listen, take the mic, raise a hand, tap-to-enable-sound, mic-denied help, room chat
- [ ] P4-ROOM-7 Host controls: raised hands, mute all, make co-host, end room
- [ ] P4-ROOM-8 Language rooms REST slice + list page grouped by language + create topic room
- [ ] P4-ROOM-9 Language room page: history, live messages, send with ack, presence, join/leave/request to join
- [ ] P4-ROOM-10 Language room owner tools: join requests approve/deny, remove member
- [ ] P4-ROOM-11 Community City and Genders tabs (community#7), same queries as the app
- [ ] P4-ROOM-12 Routes and nav entries behind `webVoiceRoomsEnabled` / `webLanguageRoomsEnabled`; flag-off test
- [ ] P4-ROOM-I18N New rooms strings in all 18 locales
- [ ] P4-ROOM-PUSH Push unit rooms (suite + build + livekit checks green, deployed dark, production smoke recorded)

Phase 4 Calls (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [ ] P4-CALL-0 CALLS worktree off `web/p4-rooms` after the LiveKit wrapper (P4-ROOM-1), real node_modules
- [ ] P4-CALL-1 `callsSlice`: initiate / accept / decline / end / upgrade / current / history / missed count / missed seen
- [ ] P4-CALL-2 Call error classifier, per-tab device id, mic/camera preflight
- [ ] P4-CALL-3 Pure call state machine (incoming, outgoing, accepted elsewhere, terminal outcomes, resync after reconnect)
- [ ] P4-CALL-4 Eager `IncomingCallHost` + call bridge in App.tsx; the call engine is a lazy chunk, inert while `webCallsEnabled` is off
- [ ] P4-CALL-5 Call engine: socket events, other tabs (BroadcastChannel), resync on reconnect and after a reload
- [ ] P4-CALL-6 Incoming call banner: ringtone with an autoplay fallback, title flash, accept, decline, decline with a message
- [ ] P4-CALL-7 Placing a call: mic/camera preflight before anything rings, busy / unavailable / blocked / conversation-cap refusals in a dialog
- [ ] P4-CALL-8 Call screen: ringback + cancel, LiveKit media, mute, camera on/off (voice → video upgrade), remote video, "tap to enable sound", reconnecting, hang up, declined / no answer / busy / dropped outcome line
- [ ] P4-CALL-9 Entry points: voice/video buttons in the chat header and on profiles, "Call back" on the chat call card
- [ ] P4-CALL-10 Call history page `/calls` and the missed-call badge
- [ ] P4-CALL-11 Flag off: no call button, no `/calls`, no socket listener, no engine chunk
- [ ] P4-CALL-I18N New calls strings in all 18 locales
- [ ] P4-CALL-PUSH Push unit calls (suite + build green, deployed dark, production smoke recorded)

Phase 4 Sign in with Apple (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [ ] P4-APPLE-1 Apple JS loader, nonce and popup sign-in wrapper (script fetched only on click)
- [ ] P4-APPLE-2 `POST /auth/apple/web` endpoint and the error text for each refusal
- [ ] P4-APPLE-3 One "finish social sign-in" path shared by Google and Apple (profile completion included)
- [ ] P4-APPLE-4 "Sign in with Apple" button: nonce → Apple popup → backend → signed in
- [ ] P4-APPLE-5 Button on Login and Register; hidden while `webAppleSigninEnabled` is off or no Services ID is configured
- [ ] P4-APPLE-I18N New Apple sign-in strings in all 18 locales
- [ ] P4-APPLE-PUSH Push unit apple (suite + build green, deployed dark, production smoke recorded)
```

- [ ] **Step 7: Commit**

```bash
git add src/utils/webFlags.ts src/utils/webFlags.test.tsx src/router/FlagRoute.tsx src/router/FlagRoute.test.tsx src/utils/testing/mockWebFlags.ts src/utils/locales/p3Keys.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(flags): one module for the website feature flags, a 404 route gate

useWebFlag/useWebFlagState read the six web* flags from /app-config
(same cache entry as announcements, re-read on focus); the spec's global
switches apply on top. FlagRoute renders a spinner while app-config
loads, NotFound while a flag is off. The i18n keys guard also reads the
Phase 4 key files. Phase 4 split into per-task tracker lines.

Still open (Phase 4): every P4- line; owner turns flags on after QA.
EOF
```

- [ ] **Step 8: Unit worktrees off the base (CALLS comes later, P4-CALL-0)**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
for u in reels gatherings apple; do
  git worktree add -b web/p4-$u /Users/davis/Desktop/Personal/wt-web-p4-$u web/p4-base
  ln -s /Users/davis/Desktop/Personal/language_exchange_web_front/node_modules /Users/davis/Desktop/Personal/wt-web-p4-$u/node_modules
done
# ROOMS gets a real node_modules: it adds livekit-client (P4-ROOM-1).
git worktree add -b web/p4-rooms /Users/davis/Desktop/Personal/wt-web-p4-rooms web/p4-base
cd /Users/davis/Desktop/Personal/wt-web-p4-rooms && npm ci 2>&1 | tail -2
CI=true npm test -- --watchAll=false 2>&1 | tail -5
```
Expected: same counts as Step 1 plus the P4-0 tests. Not pushed now: the base commit travels with the REELS push.

---

## Unit REELS (push 1 of 5) — P4-REEL-1 … P4-REEL-7, P4-REEL-I18N, P4-REEL-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p4-reels`, branch `web/p4-reels` (from `web/p4-base`, symlinked
`node_modules`, nothing installed). One implementer, tasks in number order: 1–2 are data and policy, 3–6 are the
screens, 7 wires routes/nav behind the flag and proves the feature is invisible while it is off. Push 1 of 5 also
carries the P4-0 base commit.

Unit-level facts (read once):
- **Endpoints — all already used by the app, none new:**
  - `GET /api/v1/moments/reels?limit=&before=` (`be/routes/moments.js:60`, `protect` + `reelsEnabledGuard`;
    `be/controllers/moments.js:328-450`). Answers `{success, data: Moment[], nextCursor: string | null}`. The cursor is
    opaque (`"<score>:<anchorMs>"`, a score cursor — **never** build one from `createdAt`); pass it back verbatim as
    `before`. `limit` is capped at 50; the app asks for 12 (`bananatalk_app/lib/services/reels_api_client.dart`).
    404 `{error:"Not found"}` while `REELS_ENABLED` is off (`be/lib/reelsFeed.js:180-187`). The feed excludes the
    viewer's own reels, blocked authors, non-public, hidden-pending-review and video-less rows
    (`be/lib/reelsFeed.js:36-63`). Each row has `isLiked`, `isSaved`, `likeCount`, `commentCount`, `video{url,
    thumbnail, duration, width?, height?}`, `user{_id,name,images}` (`be/lib/feedProjection.js:105-125`;
    contract test `be/test/webFeatureContracts.test.js:76-104`).
  - `GET /api/v1/moments/video-config` (public, `be/controllers/moments.js:80-96`): `data.video.allowedTypes`
    (mp4, quicktime, x-msvideo, webm, 3gpp, x-m4v), `maxSize` (1 GiB), `maxDuration` (600 — the **non-reel** cap).
  - Create = two steps, exactly as the app (`bananatalk_app/lib/pages/moments/create/create_moment.dart:1256,1577`):
    `POST /api/v1/moments {description, privacy:'public', category:'general', language, isReel:true}` (only a literal
    boolean `true` marks a reel, `be/lib/reelsFeed.js:189-200`; `description` optional, ≤ 2000,
    `be/validators/momentValidator.js:41-90`), then `PUT /api/v1/moments/:id/video` multipart field **`video`**
    (`be/routes/moments.js:91-98`, existing web mutation `uploadMomentVideo` in `momentsSlice.ts:326-333`). Over 180 s
    the server deletes the upload and answers 400 `{code:'REEL_TOO_LONG', error:'Reels must be 180 seconds or under'}`
    (`be/controllers/moments.js:1074-1088`). A reel row whose video never arrived is invisible in the feed, but the web
    still deletes it on failure (P3-MOM-1's rule: no empty moment left behind).
  - Like `POST /moments/:id/like`, unlike `POST /moments/:id/dislike` (existing `likeMoment`/`dislikeMoment`, body
    `{userId}`), share count `POST /moments/:id/share` (existing `shareMoment`), comments via the existing
    `CommentList` (P3-MOM-8 composer), views `POST /moments/views` via the existing `observeMoment()`
    (`src/components/moments/useMomentViews.ts:165`) — the ranking's "seen in 7 days" signal reads these.
  - Report via the Report collection `POST /api/v1/reports {type:'moment', reportId, reportedUser, reason}` — the only
    path that triggers the 2-report auto-hide (app: `reels_feed_screen.dart:517-565`). On web that is P3-MOM-5's
    `ReportMomentDialog` (`type="moment"`), never the legacy `/moments/:id/report`. Block = P3-MOM-5's
    `BlockAuthorDialog` (invalidates `Moments`, so the feed refetches without the author).
  - Policy acceptance: `PUT /api/v1/auth/updatedetails {reelsPolicyAccepted:true}` (`be/controllers/auth.js:1662`;
    existing web `updateUserInfo` mutation, `usersSlice.ts:117-124`); app gate `reel_policy_dialog.dart`.
- **Shares** link to `https://banatalk.com/moment/<id>` (`shareUrl('moment', id)`): a reel is a moment, `/moment/:id`
  already plays its video, and it stays reachable for a signed-out visitor even while the reels flag is off.
- **Legacy data** (2.6.1 / early reels): `video.thumbnail` null, `video.duration` missing or `0`, `user` an unpopulated
  id string, `user.images` empty, `description` empty. Normalised once in `reelModel.ts` (P4-REEL-1); no component
  reads raw rows.
- **Autoplay:** browsers only autoplay muted video. Every reel starts muted with a visible unmute button; the choice
  persists for the session (module variable), never in storage.
- New code lives in `src/components/reels/` and `src/store/slices/reelsSlice.ts` (a new slice file, so Phase 4 does
  not reopen `momentsSlice.ts`, which Phase 3 MOMENTS edited heavily). Shared files this unit edits:
  `src/router/routes.tsx`, `src/components/navbar/MainNavbar.tsx`, `src/components/moments/MainMoments.tsx` (one
  flagged link), `src/utils/locales/*.json`, `docs/REMAINING_WORK.md`.

### Task P4-REEL-1: Reels feed endpoint, video-config endpoint and a reel normaliser that survives 2.6.1 data

**Files:**
- Create: `src/store/slices/reelsSlice.ts`, `src/store/slices/reelsEndpoints.test.ts`
- Create: `src/components/reels/lib/reelModel.ts`, `src/components/reels/lib/reelModel.test.ts`

**Interfaces:**
- Consumes: `GET /api/v1/moments/reels?limit=12[&before=<cursor>]` → `{success, data, nextCursor}` (`be/controllers/moments.js:328-450`); `GET /api/v1/moments/video-config` → `{data:{video:{allowedTypes, maxSize, …}}}` (`:80-96`).
- Produces:
  - `reelsApiSlice` with `getReelsPage(args: { before?: string | null; limit?: number })` → `ReelsPage { reels: Reel[]; nextCursor: string | null }` (normalised; `providesTags: ["Moments"]`, so like/block/delete invalidations refetch it) and `getVideoConfig()` → `VideoConfig { allowedTypes: string[]; maxSize: number }` (falls back to `DEFAULT_VIDEO_CONFIG` on an odd payload). Hooks `useGetReelsPageQuery`, `useLazyGetReelsPageQuery`, `useGetVideoConfigQuery` (re-exported `as any`).
  - From `reelModel.ts`: `REEL_MAX_SECONDS = 180`, `REELS_PAGE_SIZE = 12`, `type Reel`, `normalizeReel(raw: any): Reel | null`, `mergeReels(prev: Reel[], next: Reel[]): Reel[]` (dedupe by id, keeps the first copy — the app's `_dedupedById`), `formatReelDuration(sec?: number | null): string | null`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/reels/lib/reelModel.test.ts`:

```ts
import { normalizeReel, mergeReels, formatReelDuration, REEL_MAX_SECONDS } from "./reelModel";

const full = {
  _id: "r1",
  description: "hello",
  language: "ko",
  likeCount: 3,
  commentCount: 2,
  shareCount: 1,
  isLiked: true,
  isSaved: false,
  createdAt: "2026-10-01T00:00:00.000Z",
  mediaType: "video",
  video: { url: "https://cdn.test/r.mp4", thumbnail: "https://cdn.test/r.jpg", duration: 12.4, width: 720, height: 1280 },
  user: { _id: "u1", name: "Mina", images: ["https://cdn.test/a.jpg"] },
};

it("keeps every field the viewer reads", () => {
  expect(normalizeReel(full)).toEqual({
    id: "r1",
    description: "hello",
    language: "ko",
    likeCount: 3,
    commentCount: 2,
    shareCount: 1,
    isLiked: true,
    createdAt: "2026-10-01T00:00:00.000Z",
    videoUrl: "https://cdn.test/r.mp4",
    thumbnail: "https://cdn.test/r.jpg",
    duration: 12.4,
    portrait: true,
    author: { id: "u1", name: "Mina", avatar: "https://cdn.test/a.jpg" },
  });
});

it("survives a 2.6.1 reel: no thumbnail, zero duration, unpopulated user, no counts", () => {
  const r = normalizeReel({ _id: "r2", video: { url: "https://cdn.test/x.mp4", duration: 0 }, user: "u9" });
  expect(r).not.toBe(null);
  expect(r!.thumbnail).toBe(null);
  expect(r!.duration).toBe(null);
  expect(r!.author).toEqual({ id: "u9", name: "", avatar: undefined });
  expect(r!.likeCount).toBe(0);
  expect(r!.commentCount).toBe(0);
  expect(r!.isLiked).toBe(false);
  expect(r!.description).toBe("");
  expect(r!.portrait).toBe(true); // unknown size: assume the 9:16 the app records
});

it("drops rows that cannot play", () => {
  expect(normalizeReel(null)).toBe(null);
  expect(normalizeReel({ _id: "r3" })).toBe(null);
  expect(normalizeReel({ _id: "r4", video: { url: "" } })).toBe(null);
  expect(normalizeReel({ video: { url: "https://cdn.test/x.mp4" } })).toBe(null);
});

it("reads a landscape video as landscape", () => {
  expect(normalizeReel({ ...full, video: { ...full.video, width: 1920, height: 1080 } })!.portrait).toBe(false);
});

it("merges pages without duplicates (a score cursor can repeat a boundary item)", () => {
  const a = normalizeReel(full)!;
  const b = normalizeReel({ ...full, _id: "r5" })!;
  expect(mergeReels([a], [a, b]).map((r) => r.id)).toEqual(["r1", "r5"]);
});

it("formats durations and caps reels at 180 s", () => {
  expect(REEL_MAX_SECONDS).toBe(180);
  expect(formatReelDuration(65.7)).toBe("1:05");
  expect(formatReelDuration(0)).toBe(null);
  expect(formatReelDuration(undefined)).toBe(null);
});
```

Create `src/store/slices/reelsEndpoints.test.ts` (fetch capture in the style of `momentsSlice.endpoints.test.ts:15-40`):

```ts
import { makeStore } from "../../store";
import { reelsApiSlice } from "./reelsSlice";
import { MOMENTS_URL } from "../../constants";

function mockFetch(body: any, status = 200) {
  const calls: { url: string; method: string }[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push({ url: req.url, method: req.method });
    return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const reelRow = (id: string) => ({ _id: id, video: { url: `https://cdn.test/${id}.mp4` }, user: { _id: "u", name: "U" } });

it("GET /moments/reels?limit=12 for the first page and normalises the rows", async () => {
  const calls = mockFetch({ success: true, data: [reelRow("a"), { _id: "broken" }], nextCursor: "0.91:1760000000000" });
  const store = makeStore();
  const res: any = await store.dispatch((reelsApiSlice.endpoints as any).getReelsPage.initiate({}));
  const url = new URL(calls[0].url);
  expect(url.pathname).toBe(`${MOMENTS_URL}/reels`);
  expect(url.searchParams.get("limit")).toBe("12");
  expect(url.searchParams.has("before")).toBe(false);
  expect(res.data.reels.map((r: any) => r.id)).toEqual(["a"]);
  expect(res.data.nextCursor).toBe("0.91:1760000000000");
});

it("passes the opaque cursor back verbatim as `before`", async () => {
  const calls = mockFetch({ success: true, data: [], nextCursor: null });
  const store = makeStore();
  const res: any = await store.dispatch(
    (reelsApiSlice.endpoints as any).getReelsPage.initiate({ before: "0.5:1760000000000" })
  );
  expect(new URL(calls[0].url).searchParams.get("before")).toBe("0.5:1760000000000");
  expect(res.data).toEqual({ reels: [], nextCursor: null });
});

it("GET /moments/video-config and falls back to safe defaults", async () => {
  const calls = mockFetch({ success: true, data: { video: { allowedTypes: ["video/mp4"], maxSize: 1000 } } });
  const store = makeStore();
  const res: any = await store.dispatch((reelsApiSlice.endpoints as any).getVideoConfig.initiate(undefined));
  expect(new URL(calls[0].url).pathname).toBe(`${MOMENTS_URL}/video-config`);
  expect(res.data).toEqual({ allowedTypes: ["video/mp4"], maxSize: 1000 });

  mockFetch({ success: true, data: {} });
  const store2 = makeStore();
  const res2: any = await store2.dispatch((reelsApiSlice.endpoints as any).getVideoConfig.initiate(undefined));
  expect(res2.data.allowedTypes).toContain("video/mp4");
  expect(res2.data.maxSize).toBe(1024 * 1024 * 1024);
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels && CI=true npm test -- --watchAll=false reelModel reelsEndpoints
```
Expected: FAIL — `Cannot find module './reelModel'` and `Cannot find module './reelsSlice'`.

- [ ] **Step 3: Implement**

Create `src/components/reels/lib/reelModel.ts`:

```ts
import { userAvatarUrl } from "../../../utils/photoUrl";

/** Server cap for a reel (be/lib/reelsFeed.js isReelOverCap). */
export const REEL_MAX_SECONDS = 180;
/** The app's page size (bananatalk_app reels_api_client.dart). */
export const REELS_PAGE_SIZE = 12;

export interface ReelAuthor {
  id: string;
  name: string;
  avatar: string | undefined;
}

/** The only shape reel components read. Built by normalizeReel. */
export interface Reel {
  id: string;
  description: string;
  language: string;
  likeCount: number;
  commentCount: number;
  shareCount: number;
  isLiked: boolean;
  createdAt: string;
  videoUrl: string;
  thumbnail: string | null;
  /** Seconds, or null when the server never measured it (old rows store 0). */
  duration: number | null;
  /** True unless the stored size says landscape; the app records 9:16. */
  portrait: boolean;
  author: ReelAuthor;
}

const num = (v: any): number => (typeof v === "number" && isFinite(v) && v > 0 ? v : 0);

/**
 * One feed row -> Reel, or null when it cannot play (no id or no video url).
 * Tolerates what app 2.6.1 and the first reels wrote: no thumbnail, a 0 or
 * missing duration, an unpopulated `user` id string, missing counters.
 */
export function normalizeReel(raw: any): Reel | null {
  if (!raw || typeof raw !== "object") return null;
  const id = raw._id ? String(raw._id) : "";
  const video = raw.video && typeof raw.video === "object" ? raw.video : null;
  const videoUrl = video && typeof video.url === "string" ? video.url.trim() : "";
  if (!id || !videoUrl) return null;

  const user = raw.user;
  const author: ReelAuthor =
    user && typeof user === "object"
      ? { id: String(user._id || ""), name: String(user.name || ""), avatar: userAvatarUrl(user) }
      : { id: user ? String(user) : "", name: "", avatar: undefined };

  const width = num(video.width);
  const height = num(video.height);
  const duration = num(video.duration);

  return {
    id,
    description: typeof raw.description === "string" ? raw.description : "",
    language: typeof raw.language === "string" ? raw.language : "",
    likeCount: num(raw.likeCount),
    commentCount: num(raw.commentCount),
    shareCount: num(raw.shareCount),
    isLiked: raw.isLiked === true,
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : "",
    videoUrl,
    thumbnail: typeof video.thumbnail === "string" && video.thumbnail ? video.thumbnail : null,
    duration: duration || null,
    portrait: width && height ? height >= width : true,
    author,
  };
}

/**
 * Append a page, dropping ids already shown. The feed pages by a score
 * cursor, and a boundary item can come back on the next page; the app keeps
 * the first copy (reels_provider.dart _dedupedById), so does this.
 */
export function mergeReels(prev: Reel[], next: Reel[]): Reel[] {
  const seen: { [id: string]: true } = {};
  const out: Reel[] = [];
  prev.concat(next).forEach((r) => {
    if (seen[r.id]) return;
    seen[r.id] = true;
    out.push(r);
  });
  return out;
}

export function formatReelDuration(sec?: number | null): string | null {
  if (typeof sec !== "number" || !isFinite(sec) || sec <= 0) return null;
  const total = Math.floor(sec);
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${m}:${s < 10 ? "0" : ""}${s}`;
}
```

Create `src/store/slices/reelsSlice.ts`:

```ts
import { MOMENTS_URL } from "../../constants";
import { apiSlice } from "./apiSlice";
import { normalizeReel, Reel, REELS_PAGE_SIZE } from "../../components/reels/lib/reelModel";

export interface ReelsPage {
  reels: Reel[];
  nextCursor: string | null;
}

export interface VideoConfig {
  allowedTypes: string[];
  maxSize: number;
}

/** Mirrors be/utils/videoUtils.js; used when video-config is odd or down. */
export const DEFAULT_VIDEO_CONFIG: VideoConfig = {
  allowedTypes: ["video/mp4", "video/quicktime", "video/x-msvideo", "video/webm", "video/3gpp", "video/x-m4v"],
  maxSize: 1024 * 1024 * 1024,
};

export const reelsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // GET /api/v1/moments/reels?limit=&before=. `before` is the server's
    // opaque score cursor ("<score>:<anchorMs>") -- passed back verbatim,
    // never derived from createdAt (be/controllers/moments.js getReelsFeed).
    getReelsPage: builder.query({
      query: ({ before, limit }: { before?: string | null; limit?: number }) => {
        const params = new URLSearchParams();
        params.set("limit", String(limit || REELS_PAGE_SIZE));
        if (before) params.set("before", before);
        return { url: `${MOMENTS_URL}/reels?${params.toString()}` };
      },
      transformResponse: (response: any): ReelsPage => {
        const rows = response && Array.isArray(response.data) ? response.data : [];
        const reels: Reel[] = [];
        rows.forEach((row: any) => {
          const r = normalizeReel(row);
          if (r) reels.push(r);
        });
        const cursor = response && response.nextCursor;
        return { reels, nextCursor: typeof cursor === "string" && cursor ? cursor : null };
      },
      providesTags: ["Moments"],
    }),
    // GET /api/v1/moments/video-config (public).
    getVideoConfig: builder.query({
      query: () => ({ url: `${MOMENTS_URL}/video-config` }),
      transformResponse: (response: any): VideoConfig => {
        const v = response && response.data && response.data.video;
        const types = v && Array.isArray(v.allowedTypes) && v.allowedTypes.length ? v.allowedTypes : null;
        const size = v && typeof v.maxSize === "number" && v.maxSize > 0 ? v.maxSize : null;
        return {
          allowedTypes: types || DEFAULT_VIDEO_CONFIG.allowedTypes,
          maxSize: size || DEFAULT_VIDEO_CONFIG.maxSize,
        };
      },
      keepUnusedDataFor: 3600,
    }),
  }),
});

export const {
  useGetReelsPageQuery,
  useLazyGetReelsPageQuery,
  useGetVideoConfigQuery,
} = reelsApiSlice as any;
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false reelModel reelsEndpoints
```
Expected: 9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/reelsSlice.ts src/store/slices/reelsEndpoints.test.ts src/components/reels/lib/reelModel.ts src/components/reels/lib/reelModel.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(reels): feed and video-config endpoints, a reel normaliser

GET /moments/reels with the server's opaque score cursor passed back
verbatim; rows normalised once (no thumbnail, zero duration and
unpopulated users from app 2.6.1 render; unplayable rows dropped);
pages merged without duplicates like the app. Nothing reaches it yet:
no route uses it until P4-REEL-7 (flag webReelsEnabled).

Still open (Phase 4 reels): policy gate, grid, viewer, actions, create,
routes behind the flag, i18n, push.
EOF
```

---

### Task P4-REEL-2: One-time reels content-policy gate (Apple 1.2), shared with the app via `reelsPolicyAccepted`

**Files:**
- Create: `src/components/reels/ReelPolicyGate.tsx`, `src/components/reels/ReelPolicyGate.test.tsx`, `src/components/reels/Reels.scss` (the unit's one stylesheet; later tasks append to it)
- Modify: `src/utils/locales/eng.json` (`reels.policy.*`)

**Interfaces:**
- Consumes: `state.auth.userInfo.user.reelsPolicyAccepted` (the login payload carries the user document; `be/models/User.js:80`); `PUT /api/v1/auth/updatedetails {reelsPolicyAccepted:true}` through the existing `useUpdateUserInfoMutation` (`src/store/slices/usersSlice.ts:117-124`; accepted by `be/controllers/auth.js:1662`); `setCredentials` (`src/store/slices/authSlice.ts:103`). App behaviour copied: `bananatalk_app/lib/pages/moments/reels/reel_policy_dialog.dart` — local flag first, then the server field; the dialog cannot be dismissed by clicking outside; accepting persists locally at once and on the server best-effort; declining leaves reels.
- Produces: `ReelPolicyGate` default export, props `{ children: React.ReactNode; onDeclined(): void }` — renders `children` once accepted, else the dialog (testids `reel-policy-dialog`, `reel-policy-accept`, `reel-policy-decline`). `hasAcceptedReelPolicy(user: any): boolean` and `REEL_POLICY_STORAGE_KEY = "reels_policy_accepted"` named exports. P4-REEL-3 wraps the grid in it, P4-REEL-6 wraps the composer (as the app gates both the grid and the create flow).

- [ ] **Step 1: Write the failing test**

Create `src/components/reels/ReelPolicyGate.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { Provider } from "react-redux";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { makeStore } from "../../store";
import ReelPolicyGate, { REEL_POLICY_STORAGE_KEY, hasAcceptedReelPolicy } from "./ReelPolicyGate";

const mockUpdate = jest.fn();
jest.mock("../../store/slices/usersSlice", () => ({
  useUpdateUserInfoMutation: () => [mockUpdate, { isLoading: false }],
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

function renderGate(user: any) {
  const store = makeStore({ auth: { userInfo: { token: "t", user } } });
  const onDeclined = jest.fn();
  render(
    <Provider store={store}>
      <ReelPolicyGate onDeclined={onDeclined}>
        <div data-testid="reels-content" />
      </ReelPolicyGate>
    </Provider>
  );
  return { store, onDeclined };
}

beforeEach(() => {
  localStorage.clear();
  mockUpdate.mockReset();
  mockUpdate.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
});

it("asks first, and shows nothing of the reels behind the dialog", () => {
  renderGate({ _id: "me" });
  expect(screen.getByTestId("reel-policy-dialog")).toHaveTextContent("zero tolerance");
  expect(screen.queryByTestId("reels-content")).not.toBeInTheDocument();
});

it("skips the dialog when the account already accepted (in the app)", () => {
  renderGate({ _id: "me", reelsPolicyAccepted: true });
  expect(screen.getByTestId("reels-content")).toBeInTheDocument();
  expect(screen.queryByTestId("reel-policy-dialog")).not.toBeInTheDocument();
});

it("skips the dialog when this browser already accepted", () => {
  localStorage.setItem(REEL_POLICY_STORAGE_KEY, "1");
  renderGate({ _id: "me" });
  expect(screen.getByTestId("reels-content")).toBeInTheDocument();
});

it("accepting shows the reels, remembers it locally and on the account", async () => {
  const { store } = renderGate({ _id: "me" });
  fireEvent.click(screen.getByTestId("reel-policy-accept"));
  expect(screen.getByTestId("reels-content")).toBeInTheDocument();
  expect(localStorage.getItem(REEL_POLICY_STORAGE_KEY)).toBe("1");
  expect((store.getState() as any).auth.userInfo.user.reelsPolicyAccepted).toBe(true);
  await waitFor(() => expect(mockUpdate).toHaveBeenCalledWith({ reelsPolicyAccepted: true }));
});

it("a failed server save does not take the reels away", async () => {
  mockUpdate.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
  renderGate({ _id: "me" });
  fireEvent.click(screen.getByTestId("reel-policy-accept"));
  await waitFor(() => expect(mockUpdate).toHaveBeenCalled());
  expect(screen.getByTestId("reels-content")).toBeInTheDocument();
});

it("declining leaves", () => {
  const { onDeclined } = renderGate({ _id: "me" });
  fireEvent.click(screen.getByTestId("reel-policy-decline"));
  expect(onDeclined).toHaveBeenCalled();
  expect(localStorage.getItem(REEL_POLICY_STORAGE_KEY)).toBe(null);
});

it("hasAcceptedReelPolicy only trusts a literal true", () => {
  expect(hasAcceptedReelPolicy({ reelsPolicyAccepted: "true" })).toBe(false);
  expect(hasAcceptedReelPolicy(undefined)).toBe(false);
  expect(hasAcceptedReelPolicy({ reelsPolicyAccepted: true })).toBe(true);
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels && CI=true npm test -- --watchAll=false ReelPolicyGate
```
Expected: FAIL — `Cannot find module './ReelPolicyGate'`.

- [ ] **Step 3: Implement**

Create `src/components/reels/ReelPolicyGate.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { useDispatch, useSelector } from "react-redux";
import { setCredentials } from "../../store/slices/authSlice";
import { useUpdateUserInfoMutation } from "../../store/slices/usersSlice";

/** Same key name the app keeps in SharedPreferences (reel_policy_dialog.dart). */
export const REEL_POLICY_STORAGE_KEY = "reels_policy_accepted";

export function hasAcceptedReelPolicy(user: any): boolean {
  return !!user && user.reelsPolicyAccepted === true;
}

function readLocal(): boolean {
  try {
    return localStorage.getItem(REEL_POLICY_STORAGE_KEY) === "1";
  } catch (e) {
    return false;
  }
}

function writeLocal(): void {
  try {
    localStorage.setItem(REEL_POLICY_STORAGE_KEY, "1");
  } catch (e) {
    // Private mode: the account field below still carries it.
  }
}

/**
 * One-time objectionable-content agreement before any reel is shown or
 * posted (Apple Guideline 1.2 -- public user-generated video). The account
 * field is shared with the app, so accepting on either side counts on both.
 */
const ReelPolicyGate: React.FC<{ children: React.ReactNode; onDeclined: () => void }> = ({
  children,
  onDeclined,
}) => {
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const userInfo = useSelector((state: any) => state.auth.userInfo);
  const user = userInfo && userInfo.user;
  const [acceptedNow, setAcceptedNow] = useState(false);
  const [updateUserInfo] = useUpdateUserInfoMutation();

  if (acceptedNow || hasAcceptedReelPolicy(user) || readLocal()) return <>{children}</>;

  const accept = () => {
    writeLocal();
    setAcceptedNow(true);
    if (userInfo && user) {
      dispatch(setCredentials({ ...userInfo, user: { ...user, reelsPolicyAccepted: true } }));
    }
    // Best effort, as in the app: the local flag already gates this browser.
    Promise.resolve()
      .then(() => updateUserInfo({ reelsPolicyAccepted: true }).unwrap())
      .catch(() => {});
  };

  return (
    <div className="reel-policy-backdrop" role="presentation">
      <div
        className="reel-policy-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="reel-policy-title"
        data-testid="reel-policy-dialog"
      >
        <h2 id="reel-policy-title" className="reel-policy-title">
          {t("reels.policy.title") || "Reels content guidelines"}
        </h2>
        <p className="reel-policy-body">
          {t("reels.policy.body") ||
            "Reels are short language-learning videos — prompt answers, speaking practice, native-speaker explainers, and culture clips.\n\nBananaTalk has zero tolerance for objectionable content: no nudity, hate speech, harassment, violence, or illegal content. Reported videos are automatically hidden pending review after 2 reports, and violations can result in content removal or account bans.\n\nYou can report or block from any reel at any time."}
        </p>
        <div className="reel-policy-actions">
          <button type="button" className="reel-btn reel-btn-ghost" data-testid="reel-policy-decline" onClick={onDeclined}>
            {t("reels.policy.decline") || "Decline"}
          </button>
          <button type="button" className="reel-btn reel-btn-primary" data-testid="reel-policy-accept" onClick={accept}>
            {t("reels.policy.accept") || "I agree"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReelPolicyGate;
```

The styles for `.reel-policy-*` and `.reel-btn*` go into `src/components/reels/Reels.scss`, created here and imported by `ReelPolicyGate.tsx` (`import "./Reels.scss";` — CRA's Jest config maps `.scss` to a stub). Start it with:

```scss
// Reels (Phase 4). Logical properties only; the swipe axis is vertical and
// never mirrored.
.reel-policy-backdrop {
  position: fixed;
  inset: 0;
  z-index: 1060;
  display: flex;
  align-items: center;
  justify-content: center;
  padding-inline: 16px;
  background: rgba(0, 0, 0, 0.6);
}
.reel-policy-dialog {
  max-inline-size: 440px;
  inline-size: 100%;
  padding: 24px;
  border-radius: 16px;
  background: #fff;
  text-align: start;
}
.reel-policy-title { font-size: 1.125rem; font-weight: 800; margin-block-end: 12px; }
.reel-policy-body { white-space: pre-line; font-size: 0.875rem; color: #4b5563; }
.reel-policy-actions { display: flex; justify-content: flex-end; gap: 8px; margin-block-start: 16px; }
.reel-btn { border-radius: 999px; padding: 8px 18px; font-weight: 700; border: 0; }
.reel-btn-primary { background: #f5b800; color: #111; }
.reel-btn-ghost { background: transparent; color: #4b5563; }
.reel-btn:disabled { opacity: 0.5; }
```

Add to `src/utils/locales/eng.json` (merge into a new top-level `reels` object):

```json
"reels": {
  "policy": {
    "title": "Reels content guidelines",
    "body": "Reels are short language-learning videos — prompt answers, speaking practice, native-speaker explainers, and culture clips.\n\nBananaTalk has zero tolerance for objectionable content: no nudity, hate speech, harassment, violence, or illegal content. Reported videos are automatically hidden pending review after 2 reports, and violations can result in content removal or account bans.\n\nYou can report or block from any reel at any time.",
    "decline": "Decline",
    "accept": "I agree"
  }
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false ReelPolicyGate
```
Expected: 7 tests pass. (The test's `t` returns `""`, so the English fallbacks render — that is what the "zero tolerance" assertion reads.)

- [ ] **Step 5: Commit**

```bash
git add src/components/reels/ReelPolicyGate.tsx src/components/reels/ReelPolicyGate.test.tsx src/components/reels/Reels.scss src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(reels): one-time content-policy gate shared with the app

Same agreement as the app (Apple 1.2): asked before any reel is shown or
posted, skipped when this browser or the account (reelsPolicyAccepted,
set in the app too) already agreed; accepting saves locally at once and
on the account best-effort; declining leaves.

Still open (Phase 4 reels): grid, viewer, actions, create, routes behind
the flag, i18n, push.
EOF
```

---

### Task P4-REEL-3: `/reels` grid: cursor paging, empty/unavailable states, "Create reel" entry

**Files:**
- Create: `src/components/reels/useReelsFeed.ts`, `src/components/reels/useReelsFeed.test.tsx`
- Create: `src/components/reels/ReelsGridPage.tsx`, `src/components/reels/ReelTile.tsx`, `src/components/reels/ReelsGridPage.test.tsx`
- Modify: `src/components/reels/Reels.scss` (grid styles), `src/utils/locales/eng.json` (`reels.grid.*`)

**Interfaces:**
- Consumes: `useLazyGetReelsPageQuery` (P4-REEL-1). Errors: 404 (`REELS_ENABLED` off, `be/lib/reelsFeed.js:180-187`) → "unavailable"; anything else → retryable error. App reference: grid `bananatalk_app/lib/pages/moments/reels/reels_grid_screen.dart`, empty/error copy from `reels_api_client.dart:46-48`.
- Produces:
  - `useReelsFeed()` → `ReelsFeed { reels: Reel[]; status: "loading" | "ready" | "error" | "unavailable"; hasMore: boolean; loadingMore: boolean; loadMore(): void; reload(): void; patchReel(id: string, patch: Partial<Reel>): void; removeWhere(test: (r: Reel) => boolean): void }`. `loadMore` is a no-op while a page is in flight or when there is no cursor.
  - `ReelsGridPage` default export (the `/reels` page; P4-REEL-7 routes it). Testids: `reels-page`, `reel-tile-<id>`, `reels-load-more`, `reels-empty`, `reels-unavailable`, `reels-error`, `reels-retry`, `reels-create` (a `Link` to `/reels/new`). Holds `openIndex: number | null` (set by a tile click) for the viewer added in P4-REEL-4.
  - `ReelTile` default export, props `{ reel: Reel; onOpen(): void }`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/reels/useReelsFeed.test.tsx`:

```tsx
import React from "react";
import { render, screen, act, waitFor } from "@testing-library/react";
import { useReelsFeed, ReelsFeed } from "./useReelsFeed";

const mockTrigger = jest.fn();
jest.mock("../../store/slices/reelsSlice", () => ({
  useLazyGetReelsPageQuery: () => [mockTrigger],
}));

const reel = (id: string, authorId = "a") => ({
  id, description: "", language: "ko", likeCount: 0, commentCount: 0, shareCount: 0, isLiked: false,
  createdAt: "", videoUrl: `https://cdn.test/${id}.mp4`, thumbnail: null, duration: null, portrait: true,
  author: { id: authorId, name: "A", avatar: undefined },
});
const page = (ids: string[], nextCursor: string | null) => ({
  unwrap: () => Promise.resolve({ reels: ids.map((i) => reel(i)), nextCursor }),
});
const fail = (status: any) => ({ unwrap: () => Promise.reject({ status }) });

let feed: ReelsFeed;
function Probe() {
  feed = useReelsFeed();
  return <span data-testid="ids">{feed.status + ":" + feed.reels.map((r) => r.id).join(",")}</span>;
}
const ids = () => screen.getByTestId("ids").textContent;

beforeEach(() => mockTrigger.mockReset());

it("loads the first page without a cursor, then the next with the server's cursor", async () => {
  mockTrigger.mockReturnValueOnce(page(["a", "b"], "c1")).mockReturnValueOnce(page(["b", "c"], null));
  render(<Probe />);
  await waitFor(() => expect(ids()).toBe("ready:a,b"));
  expect(mockTrigger.mock.calls[0][0]).toEqual({ before: null });
  expect(feed.hasMore).toBe(true);
  await act(async () => feed.loadMore());
  expect(mockTrigger.mock.calls[1][0]).toEqual({ before: "c1" });
  expect(ids()).toBe("ready:a,b,c");
  expect(feed.hasMore).toBe(false);
  await act(async () => feed.loadMore());
  expect(mockTrigger).toHaveBeenCalledTimes(2);
});

it("a 404 means reels are switched off; anything else can be retried", async () => {
  mockTrigger.mockReturnValueOnce(fail(404));
  const { unmount } = render(<Probe />);
  await waitFor(() => expect(ids()).toBe("unavailable:"));
  unmount();
  mockTrigger.mockReturnValueOnce(fail("FETCH_ERROR")).mockReturnValueOnce(page(["a"], null));
  render(<Probe />);
  await waitFor(() => expect(ids()).toBe("error:"));
  await act(async () => feed.reload());
  expect(ids()).toBe("ready:a");
});

it("patches and removes reels locally (likes, blocks, deletes)", async () => {
  mockTrigger.mockReturnValueOnce(page(["a", "b"], null));
  render(<Probe />);
  await waitFor(() => expect(ids()).toBe("ready:a,b"));
  act(() => feed.patchReel("a", { likeCount: 5, isLiked: true }));
  expect(feed.reels[0].likeCount).toBe(5);
  act(() => feed.removeWhere((r) => r.id === "b"));
  expect(ids()).toBe("ready:a");
});
```

Create `src/components/reels/ReelsGridPage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { MemoryRouter } from "react-router-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import ReelsGridPage from "./ReelsGridPage";

let mockFeed: any;
jest.mock("./useReelsFeed", () => ({ useReelsFeed: () => mockFeed }));
jest.mock("./ReelPolicyGate", () => ({ __esModule: true, default: (p: any) => <>{p.children}</> }));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const reel = (id: string, extra: any = {}) => ({
  id, description: "caption " + id, language: "ko", likeCount: 4, commentCount: 1, shareCount: 0, isLiked: false,
  createdAt: "", videoUrl: `https://cdn.test/${id}.mp4`, thumbnail: `https://cdn.test/${id}.jpg`, duration: 65,
  portrait: true, author: { id: "u", name: "Mina", avatar: undefined }, ...extra,
});
const feed = (over: any = {}) => ({
  reels: [], status: "ready", hasMore: false, loadingMore: false,
  loadMore: jest.fn(), reload: jest.fn(), patchReel: jest.fn(), removeWhere: jest.fn(), ...over,
});
const renderPage = () =>
  render(
    <MemoryRouter>
      <ReelsGridPage />
    </MemoryRouter>
  );

it("draws a tile per reel with its thumbnail, duration and likes", () => {
  mockFeed = feed({ reels: [reel("a"), reel("b")] });
  renderPage();
  const tile = screen.getByTestId("reel-tile-a");
  expect(tile.querySelector("img")).toHaveAttribute("src", "https://cdn.test/a.jpg");
  expect(tile).toHaveTextContent("1:05");
  expect(tile).toHaveTextContent("4");
  expect(screen.getByTestId("reel-tile-b")).toBeInTheDocument();
});

it("falls back to the video's first frame when there is no thumbnail (2.6.1 reels)", () => {
  mockFeed = feed({ reels: [reel("a", { thumbnail: null, duration: null })] });
  renderPage();
  const video = screen.getByTestId("reel-tile-a").querySelector("video") as HTMLVideoElement;
  expect(video).toHaveAttribute("src", "https://cdn.test/a.mp4#t=0.1");
  expect(video).toHaveAttribute("preload", "metadata");
  expect(video.muted).toBe(true);
});

it("loads more only when the server said there is more", () => {
  mockFeed = feed({ reels: [reel("a")], hasMore: true });
  const { unmount } = renderPage();
  fireEvent.click(screen.getByTestId("reels-load-more"));
  expect(mockFeed.loadMore).toHaveBeenCalled();
  unmount();
  mockFeed = feed({ reels: [reel("a")], hasMore: false });
  renderPage();
  expect(screen.queryByTestId("reels-load-more")).not.toBeInTheDocument();
});

it("offers to create a reel, and says so when there are none yet", () => {
  mockFeed = feed();
  renderPage();
  expect(screen.getByTestId("reels-empty")).toBeInTheDocument();
  expect(screen.getByTestId("reels-create")).toHaveAttribute("href", "/reels/new");
});

it("says reels are unavailable on a 404, and offers a retry on other errors", () => {
  mockFeed = feed({ status: "unavailable" });
  const { unmount } = renderPage();
  expect(screen.getByTestId("reels-unavailable")).toBeInTheDocument();
  expect(screen.queryByTestId("reels-create")).not.toBeInTheDocument();
  unmount();
  mockFeed = feed({ status: "error" });
  renderPage();
  fireEvent.click(screen.getByTestId("reels-retry"));
  expect(mockFeed.reload).toHaveBeenCalled();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels && CI=true npm test -- --watchAll=false useReelsFeed ReelsGridPage
```
Expected: FAIL — `Cannot find module './useReelsFeed'` / `'./ReelsGridPage'`.

- [ ] **Step 3: Implement**

Create `src/components/reels/useReelsFeed.ts`:

```ts
import { useCallback, useEffect, useRef, useState } from "react";
import { useLazyGetReelsPageQuery } from "../../store/slices/reelsSlice";
import { mergeReels, Reel } from "./lib/reelModel";

export type ReelsStatus = "loading" | "ready" | "error" | "unavailable";

export interface ReelsFeed {
  reels: Reel[];
  status: ReelsStatus;
  hasMore: boolean;
  loadingMore: boolean;
  loadMore(): void;
  reload(): void;
  patchReel(id: string, patch: Partial<Reel>): void;
  removeWhere(test: (r: Reel) => boolean): void;
}

/**
 * The reels feed as one growing list. Pages come from GET /moments/reels and
 * are appended (deduplicated) here rather than kept per cache entry: the
 * cursor is a score snapshot, so page N only makes sense after page N-1 of
 * the same session.
 */
export function useReelsFeed(): ReelsFeed {
  const [trigger] = useLazyGetReelsPageQuery();
  const [reels, setReels] = useState<Reel[]>([]);
  const [status, setStatus] = useState<ReelsStatus>("loading");
  const [cursor, setCursor] = useState<string | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);
  const inFlight = useRef(false);
  const alive = useRef(true);

  useEffect(() => {
    alive.current = true;
    return () => {
      alive.current = false;
    };
  }, []);

  const fetchPage = useCallback(
    async (before: string | null) => {
      if (inFlight.current) return;
      inFlight.current = true;
      if (before) setLoadingMore(true);
      try {
        const page = await trigger({ before }, false).unwrap();
        if (!alive.current) return;
        setReels((prev) => (before ? mergeReels(prev, page.reels) : page.reels));
        setCursor(page.nextCursor);
        setStatus("ready");
      } catch (err) {
        if (!alive.current) return;
        // A failed "load more" keeps what is on screen; only a failed first
        // page replaces it with an error state.
        if (!before) setStatus(err && (err as any).status === 404 ? "unavailable" : "error");
      } finally {
        inFlight.current = false;
        if (alive.current) setLoadingMore(false);
      }
    },
    [trigger]
  );

  useEffect(() => {
    fetchPage(null);
  }, [fetchPage]);

  const loadMore = useCallback(() => {
    if (cursor) fetchPage(cursor);
  }, [cursor, fetchPage]);

  const reload = useCallback(() => {
    setStatus("loading");
    setCursor(null);
    return fetchPage(null);
  }, [fetchPage]);

  const patchReel = useCallback((id: string, patch: Partial<Reel>) => {
    setReels((prev) => prev.map((r) => (r.id === id ? { ...r, ...patch } : r)));
  }, []);

  const removeWhere = useCallback((test: (r: Reel) => boolean) => {
    setReels((prev) => prev.filter((r) => !test(r)));
  }, []);

  return {
    reels,
    status,
    hasMore: !!cursor,
    loadingMore,
    loadMore,
    reload: reload as () => void,
    patchReel,
    removeWhere,
  };
}
```

Create `src/components/reels/ReelTile.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { FaHeart, FaPlay } from "react-icons/fa";
import { formatReelDuration, Reel } from "./lib/reelModel";

const ReelTile: React.FC<{ reel: Reel; onOpen: () => void }> = ({ reel, onOpen }) => {
  const { t } = useTranslation();
  const duration = formatReelDuration(reel.duration);
  const label =
    (t("reels.grid.open_reel", { name: reel.author.name }) || `Play reel by ${reel.author.name}`).trim();
  return (
    <button type="button" className="reel-tile" data-testid={`reel-tile-${reel.id}`} onClick={onOpen} aria-label={label}>
      {reel.thumbnail ? (
        <img src={reel.thumbnail} alt="" loading="lazy" className="reel-tile-media" />
      ) : (
        // 2.6.1 reels have no thumbnail: the first frame, fetched as metadata only.
        <video
          src={`${reel.videoUrl}#t=0.1`}
          preload="metadata"
          muted
          playsInline
          className="reel-tile-media"
          aria-hidden="true"
        />
      )}
      <span className="reel-tile-play" aria-hidden="true">
        <FaPlay />
      </span>
      <span className="reel-tile-meta">
        <span className="reel-tile-likes">
          <FaHeart aria-hidden="true" /> {reel.likeCount}
        </span>
        {duration && <span className="reel-tile-duration">{duration}</span>}
      </span>
    </button>
  );
};

export default ReelTile;
```

Create `src/components/reels/ReelsGridPage.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Link, useNavigate } from "react-router-dom";
import ReelPolicyGate from "./ReelPolicyGate";
import ReelTile from "./ReelTile";
import { useReelsFeed } from "./useReelsFeed";
import "./Reels.scss";

/**
 * /reels -- the grid (the app's Reels tab, reels_grid_screen.dart). Only
 * routed while webReelsEnabled and reelsEnabled are on (P4-REEL-7).
 */
const ReelsGridPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const feed = useReelsFeed();
  // Read by the viewer (P4-REEL-4).
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const createLink = (
    <Link to="/reels/new" className="reel-btn reel-btn-primary" data-testid="reels-create">
      {t("reels.grid.create") || "Create reel"}
    </Link>
  );

  let body: React.ReactNode;
  if (feed.status === "loading") {
    body = <div className="reels-state" aria-busy="true">{t("reels.grid.loading") || "Loading reels…"}</div>;
  } else if (feed.status === "unavailable") {
    body = (
      <div className="reels-state" data-testid="reels-unavailable">
        {t("reels.grid.unavailable") || "Reels are currently unavailable."}
      </div>
    );
  } else if (feed.status === "error") {
    body = (
      <div className="reels-state" data-testid="reels-error">
        <p>{t("reels.grid.error") || "Couldn't load reels."}</p>
        <button type="button" className="reel-btn reel-btn-ghost" data-testid="reels-retry" onClick={feed.reload}>
          {t("reels.grid.retry") || "Try again"}
        </button>
      </div>
    );
  } else if (feed.reels.length === 0) {
    body = (
      <div className="reels-state" data-testid="reels-empty">
        <p>{t("reels.grid.empty") || "No reels yet. Be the first to post one."}</p>
      </div>
    );
  } else {
    body = (
      <>
        <div className="reels-grid">
          {feed.reels.map((reel, i) => (
            <ReelTile key={reel.id} reel={reel} onOpen={() => setOpenIndex(i)} />
          ))}
        </div>
        {feed.hasMore && (
          <div className="reels-more">
            <button
              type="button"
              className="reel-btn reel-btn-ghost"
              data-testid="reels-load-more"
              disabled={feed.loadingMore}
              onClick={feed.loadMore}
            >
              {feed.loadingMore ? t("reels.grid.loading") || "Loading reels…" : t("reels.grid.load_more") || "Load more"}
            </button>
          </div>
        )}
      </>
    );
  }

  return (
    <ReelPolicyGate onDeclined={() => navigate("/moments")}>
      <section className="reels-page" data-testid="reels-page">
        <header className="reels-header">
          <h1 className="reels-title">{t("reels.grid.title") || "Reels"}</h1>
          {feed.status !== "unavailable" && createLink}
        </header>
        {body}
        {openIndex !== null && null /* viewer: P4-REEL-4 */}
      </section>
    </ReelPolicyGate>
  );
};

export default ReelsGridPage;
```

Append to `src/components/reels/Reels.scss`:

```scss
.reels-page { max-inline-size: 960px; margin-inline: auto; padding: 16px; }
.reels-header { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-block-end: 16px; }
.reels-title { font-size: 1.5rem; font-weight: 800; margin: 0; }
.reels-state { padding-block: 64px; text-align: center; color: #6b7280; }
.reels-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 6px; }
.reel-tile { position: relative; aspect-ratio: 9 / 16; overflow: hidden; border: 0; padding: 0; border-radius: 10px; background: #111; }
.reel-tile-media { inline-size: 100%; block-size: 100%; object-fit: cover; display: block; }
.reel-tile-play { position: absolute; inset-block-start: 8px; inset-inline-end: 8px; color: #fff; opacity: 0.85; }
.reel-tile-meta { position: absolute; inset-inline: 0; inset-block-end: 0; display: flex; justify-content: space-between; padding: 6px 8px; color: #fff; font-size: 0.75rem; font-weight: 700; background: linear-gradient(transparent, rgba(0, 0, 0, 0.6)); }
.reels-more { display: flex; justify-content: center; margin-block: 16px; }
```

Add to `eng.json` under `reels`:

```json
"grid": {
  "title": "Reels",
  "create": "Create reel",
  "loading": "Loading reels…",
  "unavailable": "Reels are currently unavailable.",
  "error": "Couldn't load reels.",
  "retry": "Try again",
  "empty": "No reels yet. Be the first to post one.",
  "load_more": "Load more",
  "open_reel": "Play reel by {{name}}"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false useReelsFeed ReelsGridPage
```
Expected: 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/reels/useReelsFeed.ts src/components/reels/useReelsFeed.test.tsx src/components/reels/ReelsGridPage.tsx src/components/reels/ReelTile.tsx src/components/reels/ReelsGridPage.test.tsx src/components/reels/Reels.scss src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(reels): the reels grid with cursor paging

/reels page (not routed yet): tiles with thumbnail or first frame for
old reels, duration and likes; "Load more" follows the server cursor and
merges without duplicates; empty, unavailable (404 while REELS_ENABLED
is off) and retryable error states; behind the content-policy gate.

Still open (Phase 4 reels): viewer, actions, create, routes behind the
flag, i18n, push.
EOF
```

---

### Task P4-REEL-4: Full-screen reel viewer: one playing video, muted autoplay with unmute, swipe/wheel/keys, views recorded

**Files:**
- Create: `src/components/reels/ReelViewer.tsx`, `src/components/reels/ReelViewer.test.tsx`
- Modify: `src/components/reels/ReelsGridPage.tsx` (open the viewer from a tile; `?reel=<id>` in the URL so Back closes it), `src/components/reels/ReelsGridPage.test.tsx` (one case, one mock)
- Modify: `src/components/reels/Reels.scss`, `src/utils/locales/eng.json` (`reels.viewer.*`)

**Interfaces:**
- Consumes: `useMomentViews({momentId, isLoggedIn})` → ref callback (`src/components/moments/useMomentViews.ts:180-200`; batches `POST /moments/views {views:[{momentId, watchedMs, completed}]}` — the feed's "seen in the last 7 days" ranking input, `be/controllers/moments.js:375-392`). App behaviour copied from `reels_feed_screen.dart`: vertical paging, one active video, loop, pause when not active, prefetch the next page when 3 from the end (`reel_prefetch_policy.dart`).
- Produces: `ReelViewer` default export, props:
  ```ts
  interface ReelViewerProps {
    reels: Reel[];
    index: number;                 // controlled
    hasMore: boolean;
    onIndexChange(next: number): void;
    onNeedMore(): void;            // called when index >= reels.length - 3 and hasMore
    onClose(): void;
    renderActions?: (reel: Reel) => React.ReactNode;   // P4-REEL-5's action rail
  }
  ```
  Testids `reel-viewer`, `reel-slide-<id>`, `reel-video`, `reel-mute`, `reel-tap-to-play`, `reel-close`, `reel-prev`, `reel-next`. Named export `_resetReelMuteForTests()`. Mute choice lives in a module variable for the page session (never in storage); every reel starts muted until the user unmutes once.

- [ ] **Step 1: Write the failing tests**

Create `src/components/reels/ReelViewer.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React, { useState } from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import ReelViewer, { _resetReelMuteForTests } from "./ReelViewer";

const mockViewRef = jest.fn();
jest.mock("../moments/useMomentViews", () => ({
  useMomentViews: (args: any) => {
    mockViewRef(args.momentId);
    return () => {};
  },
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const reel = (id: string) => ({
  id, description: "about " + id, language: "ko", likeCount: 0, commentCount: 0, shareCount: 0, isLiked: false,
  createdAt: "", videoUrl: `https://cdn.test/${id}.mp4`, thumbnail: null, duration: null, portrait: true,
  author: { id: "u", name: "Mina", avatar: undefined },
});
const REELS = ["a", "b", "c", "d", "e"].map(reel);

let playMock: jest.Mock;
beforeEach(() => {
  _resetReelMuteForTests();
  playMock = jest.fn().mockResolvedValue(undefined);
  window.HTMLMediaElement.prototype.play = playMock;
  window.HTMLMediaElement.prototype.pause = jest.fn();
  mockViewRef.mockClear();
});

function Harness(props: any) {
  const [index, setIndex] = useState(props.start || 0);
  return (
    <ReelViewer
      reels={props.reels || REELS}
      index={index}
      hasMore={!!props.hasMore}
      onIndexChange={setIndex}
      onNeedMore={props.onNeedMore || jest.fn()}
      onClose={props.onClose || jest.fn()}
    />
  );
}
const current = () => (screen.getByTestId("reel-viewer").querySelector("[data-testid^='reel-slide-']") as HTMLElement).dataset.testid;

it("plays exactly one video, muted, and records a view for it", async () => {
  await act(async () => {
    render(<Harness start={1} />);
  });
  expect(current()).toBe("reel-slide-b");
  const videos = screen.getByTestId("reel-viewer").querySelectorAll("video");
  expect(videos).toHaveLength(1);
  expect((videos[0] as HTMLVideoElement).muted).toBe(true);
  expect(videos[0]).toHaveAttribute("src", "https://cdn.test/b.mp4");
  expect(playMock).toHaveBeenCalled();
  expect(mockViewRef).toHaveBeenCalledWith("b");
});

it("moves with the arrow keys and closes on Escape", async () => {
  const onClose = jest.fn();
  await act(async () => {
    render(<Harness onClose={onClose} />);
  });
  fireEvent.keyDown(window, { key: "ArrowUp" });
  expect(current()).toBe("reel-slide-a");
  fireEvent.keyDown(window, { key: "ArrowDown" });
  expect(current()).toBe("reel-slide-b");
  fireEvent.keyDown(window, { key: "Escape" });
  expect(onClose).toHaveBeenCalled();
});

it("moves once per wheel gesture, and on a vertical swipe", async () => {
  const now = jest.spyOn(Date, "now");
  now.mockReturnValue(1000);
  await act(async () => {
    render(<Harness />);
  });
  const viewer = screen.getByTestId("reel-viewer");
  fireEvent.wheel(viewer, { deltaY: 120 });
  fireEvent.wheel(viewer, { deltaY: 120 }); // same gesture: ignored
  expect(current()).toBe("reel-slide-b");
  now.mockReturnValue(2000);
  fireEvent.wheel(viewer, { deltaY: -120 });
  expect(current()).toBe("reel-slide-a");
  fireEvent.touchStart(viewer, { touches: [{ clientY: 500 }] });
  fireEvent.touchEnd(viewer, { changedTouches: [{ clientY: 380 }] });
  expect(current()).toBe("reel-slide-b");
  now.mockRestore();
});

it("asks for the next page three reels from the end", async () => {
  const onNeedMore = jest.fn();
  await act(async () => {
    render(<Harness start={1} hasMore onNeedMore={onNeedMore} />);
  });
  expect(onNeedMore).not.toHaveBeenCalled();
  fireEvent.keyDown(window, { key: "ArrowDown" }); // index 2 = length - 3
  expect(onNeedMore).toHaveBeenCalled();
});

it("unmutes on request and keeps the choice for the next reel", async () => {
  await act(async () => {
    render(<Harness />);
  });
  fireEvent.click(screen.getByTestId("reel-mute"));
  expect((screen.getByTestId("reel-video") as HTMLVideoElement).muted).toBe(false);
  fireEvent.keyDown(window, { key: "ArrowDown" });
  expect((screen.getByTestId("reel-video") as HTMLVideoElement).muted).toBe(false);
});

it("shows a tap-to-play button when the browser refuses autoplay", async () => {
  playMock.mockRejectedValueOnce(Object.assign(new Error("blocked"), { name: "NotAllowedError" }));
  await act(async () => {
    render(<Harness />);
  });
  const tap = screen.getByTestId("reel-tap-to-play");
  await act(async () => {
    fireEvent.click(tap);
  });
  expect(playMock).toHaveBeenCalledTimes(2);
  expect(screen.queryByTestId("reel-tap-to-play")).not.toBeInTheDocument();
});
```

In `src/components/reels/ReelsGridPage.test.tsx` add the mock

```tsx
jest.mock("./ReelViewer", () => ({
  __esModule: true,
  default: (p: any) => <div data-testid="viewer-stub">{p.reels[p.index].id}</div>,
}));
```

and the case

```tsx
it("opens the viewer on the clicked reel and puts it in the URL", () => {
  mockFeed = feed({ reels: [reel("a"), reel("b")] });
  renderPage();
  fireEvent.click(screen.getByTestId("reel-tile-b"));
  expect(screen.getByTestId("viewer-stub")).toHaveTextContent("b");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels && CI=true npm test -- --watchAll=false ReelViewer ReelsGridPage
```
Expected: FAIL — `Cannot find module './ReelViewer'` (the grid test's mock factory fails to resolve the path too until the file exists).

- [ ] **Step 3: Implement**

Create `src/components/reels/ReelViewer.tsx`:

```tsx
import React, { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { FaChevronDown, FaChevronUp, FaPlay, FaTimes, FaVolumeMute, FaVolumeUp } from "react-icons/fa";
import { useMomentViews } from "../moments/useMomentViews";
import { Reel } from "./lib/reelModel";

// Browsers autoplay only muted video, so every session starts muted; once the
// user unmutes, later reels keep sound for the rest of the page session.
let sessionMuted = true;
export function _resetReelMuteForTests() {
  sessionMuted = true;
}

const WHEEL_LOCK_MS = 450;
const SWIPE_MIN_PX = 60;

export interface ReelViewerProps {
  reels: Reel[];
  index: number;
  hasMore: boolean;
  onIndexChange(next: number): void;
  onNeedMore(): void;
  onClose(): void;
  renderActions?: (reel: Reel) => React.ReactNode;
}

const ReelSlide: React.FC<{ reel: Reel; muted: boolean; children?: React.ReactNode }> = ({ reel, muted, children }) => {
  const { t } = useTranslation();
  const videoRef = useRef<HTMLVideoElement>(null);
  const [blocked, setBlocked] = useState(false);
  const viewRef = useMomentViews({ momentId: reel.id, isLoggedIn: true });

  const play = useCallback(() => {
    const el = videoRef.current;
    if (!el) return;
    let result: any;
    try {
      result = el.play();
    } catch (e) {
      setBlocked(true);
      return;
    }
    if (result && typeof result.then === "function") {
      result.then(
        () => setBlocked(false),
        () => setBlocked(true)
      );
    }
  }, []);

  useEffect(() => {
    play();
    const el = videoRef.current;
    return () => {
      if (el) el.pause();
    };
  }, [reel.id, play]);

  useEffect(() => {
    if (videoRef.current) videoRef.current.muted = muted;
  }, [muted]);

  return (
    <div className="reel-slide" data-testid={`reel-slide-${reel.id}`} ref={viewRef}>
      <video
        key={reel.id}
        ref={videoRef}
        data-testid="reel-video"
        className={`reel-video ${reel.portrait ? "" : "reel-video-landscape"}`}
        src={reel.videoUrl}
        poster={reel.thumbnail || undefined}
        muted={muted}
        loop
        playsInline
        preload="auto"
        onClick={() => {
          const el = videoRef.current;
          if (el && !el.paused) el.pause();
          else play();
        }}
      />
      {blocked && (
        <button type="button" className="reel-tap-to-play" data-testid="reel-tap-to-play" onClick={play}>
          <FaPlay aria-hidden="true" />
          <span>{t("reels.viewer.tap_to_play") || "Tap to play"}</span>
        </button>
      )}
      <div className="reel-caption">
        <div className="reel-author">{reel.author.name}</div>
        {reel.description && <p className="reel-description">{reel.description}</p>}
      </div>
      {children && <div className="reel-rail">{children}</div>}
    </div>
  );
};

/**
 * Full-screen vertical reel player (the app's reels_feed_screen.dart). One
 * <video> element at a time -- the active reel -- so nothing plays in the
 * background and a slow connection downloads one stream, not five.
 */
const ReelViewer: React.FC<ReelViewerProps> = ({
  reels,
  index,
  hasMore,
  onIndexChange,
  onNeedMore,
  onClose,
  renderActions,
}) => {
  const { t } = useTranslation();
  const [muted, setMuted] = useState(sessionMuted);
  const lastWheel = useRef(0);
  const touchStartY = useRef<number | null>(null);
  const reel = reels[index];

  const go = useCallback(
    (delta: number) => {
      const next = index + delta;
      if (next < 0 || next >= reels.length) return;
      onIndexChange(next);
    },
    [index, reels.length, onIndexChange]
  );

  useEffect(() => {
    if (hasMore && index >= reels.length - 3) onNeedMore();
  }, [index, reels.length, hasMore, onNeedMore]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "ArrowDown" || e.key === "j") go(1);
      else if (e.key === "ArrowUp" || e.key === "k") go(-1);
      else if (e.key === "Escape") onClose();
      else if (e.key === "m") toggleMute();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [go, onClose]);

  // Lock page scroll behind the overlay.
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  function toggleMute() {
    setMuted((m) => {
      sessionMuted = !m;
      return !m;
    });
  }

  if (!reel) return null;

  return (
    <div
      className="reel-viewer"
      role="dialog"
      aria-modal="true"
      aria-label={t("reels.viewer.label") || "Reels"}
      data-testid="reel-viewer"
      onWheel={(e) => {
        const now = Date.now();
        if (Math.abs(e.deltaY) < 30 || now - lastWheel.current < WHEEL_LOCK_MS) return;
        lastWheel.current = now;
        go(e.deltaY > 0 ? 1 : -1);
      }}
      onTouchStart={(e) => {
        touchStartY.current = e.touches && e.touches[0] ? e.touches[0].clientY : null;
      }}
      onTouchEnd={(e) => {
        const start = touchStartY.current;
        const end = e.changedTouches && e.changedTouches[0] ? e.changedTouches[0].clientY : null;
        touchStartY.current = null;
        if (start === null || end === null || Math.abs(start - end) < SWIPE_MIN_PX) return;
        go(start > end ? 1 : -1);
      }}
    >
      <ReelSlide key={reel.id} reel={reel} muted={muted}>
        {renderActions ? renderActions(reel) : null}
      </ReelSlide>

      <button type="button" className="reel-icon-btn reel-close" data-testid="reel-close" onClick={onClose}
        aria-label={t("reels.viewer.close") || "Close"}>
        <FaTimes aria-hidden="true" />
      </button>
      <button type="button" className="reel-icon-btn reel-mute" data-testid="reel-mute" onClick={toggleMute}
        aria-label={muted ? t("reels.viewer.unmute") || "Unmute" : t("reels.viewer.mute") || "Mute"}>
        {muted ? <FaVolumeMute aria-hidden="true" /> : <FaVolumeUp aria-hidden="true" />}
      </button>
      <div className="reel-nav">
        <button type="button" className="reel-icon-btn" data-testid="reel-prev" disabled={index === 0}
          onClick={() => go(-1)} aria-label={t("reels.viewer.previous") || "Previous reel"}>
          <FaChevronUp aria-hidden="true" />
        </button>
        <button type="button" className="reel-icon-btn" data-testid="reel-next" disabled={index >= reels.length - 1}
          onClick={() => go(1)} aria-label={t("reels.viewer.next") || "Next reel"}>
          <FaChevronDown aria-hidden="true" />
        </button>
      </div>
    </div>
  );
};

export default ReelViewer;
```

In `src/components/reels/ReelsGridPage.tsx`:
- imports: `import { Link, useLocation, useNavigate, useSearchParams } from "react-router-dom";` and `import ReelViewer from "./ReelViewer";`
- replace `const [openIndex, setOpenIndex] = useState<number | null>(null);` with

```tsx
  // The open reel lives in the URL (?reel=<id>) so Back closes the viewer
  // instead of leaving /reels. A link shared by id that is not in this
  // session's feed simply opens the grid.
  const [searchParams, setSearchParams] = useSearchParams();
  const location = useLocation();
  const openId = searchParams.get("reel");
  const openIndex = openId ? feed.reels.findIndex((r) => r.id === openId) : -1;
  const openReel = (i: number) =>
    setSearchParams({ reel: feed.reels[i].id }, { state: { reelOpened: true } } as any);
  const moveTo = (i: number) => setSearchParams({ reel: feed.reels[i].id }, { replace: true, state: location.state } as any);
  const closeViewer = () => {
    if (location.state && (location.state as any).reelOpened) navigate(-1);
    else setSearchParams({}, { replace: true } as any);
  };
```
  (drop the now-unused `useState` import)
- tile: `onOpen={() => openReel(i)}`
- replace `{openIndex !== null && null /* viewer: P4-REEL-4 */}` with

```tsx
        {openIndex >= 0 && (
          <ReelViewer
            reels={feed.reels}
            index={openIndex}
            hasMore={feed.hasMore}
            onIndexChange={moveTo}
            onNeedMore={feed.loadMore}
            onClose={closeViewer}
          />
        )}
```

Append to `Reels.scss`:

```scss
.reel-viewer { position: fixed; inset: 0; z-index: 1050; background: #000; display: flex; align-items: center; justify-content: center; touch-action: none; }
.reel-slide { position: relative; block-size: 100%; inline-size: min(100vw, calc(100vh * 9 / 16)); }
.reel-video { inline-size: 100%; block-size: 100%; object-fit: cover; background: #000; }
.reel-video-landscape { object-fit: contain; }
.reel-tap-to-play { position: absolute; inset: 0; margin: auto; inline-size: 120px; block-size: 120px; border: 0; border-radius: 999px; background: rgba(0, 0, 0, 0.55); color: #fff; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; font-weight: 700; }
.reel-caption { position: absolute; inset-inline-start: 12px; inset-inline-end: 72px; inset-block-end: 16px; color: #fff; text-align: start; text-shadow: 0 1px 2px rgba(0, 0, 0, 0.6); }
.reel-author { font-weight: 800; }
.reel-description { margin: 4px 0 0; font-size: 0.875rem; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
.reel-rail { position: absolute; inset-inline-end: 8px; inset-block-end: 24px; display: flex; flex-direction: column; gap: 14px; align-items: center; }
.reel-icon-btn { border: 0; border-radius: 999px; inline-size: 40px; block-size: 40px; background: rgba(255, 255, 255, 0.15); color: #fff; display: inline-flex; align-items: center; justify-content: center; }
.reel-icon-btn:disabled { opacity: 0.3; }
.reel-close { position: absolute; inset-block-start: 16px; inset-inline-start: 16px; }
.reel-mute { position: absolute; inset-block-start: 16px; inset-inline-end: 16px; }
.reel-nav { position: absolute; inset-inline-end: 16px; inset-block-start: 50%; transform: translateY(-50%); display: flex; flex-direction: column; gap: 8px; }
@media (max-width: 640px) { .reel-nav { display: none; } }
```

Add to `eng.json` under `reels`:

```json
"viewer": {
  "label": "Reels",
  "tap_to_play": "Tap to play",
  "close": "Close",
  "mute": "Mute",
  "unmute": "Unmute",
  "previous": "Previous reel",
  "next": "Next reel"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false ReelViewer ReelsGridPage
```
Expected: 6 viewer tests and 6 grid tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/reels/ReelViewer.tsx src/components/reels/ReelViewer.test.tsx src/components/reels/ReelsGridPage.tsx src/components/reels/ReelsGridPage.test.tsx src/components/reels/Reels.scss src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(reels): full-screen viewer with muted autoplay and swipe

One video element at a time, looping; starts muted (browser autoplay
rule) with an unmute that holds for the session; a tap-to-play button
when autoplay is refused; arrow keys, one step per wheel gesture and
vertical swipes; next page fetched three reels from the end; views
recorded for the feed's ranking; ?reel=<id> so Back closes it.

Still open (Phase 4 reels): like/comment/share/report actions, create,
routes behind the flag, i18n, push.
EOF
```

---

### Task P4-REEL-5: Viewer actions: like, comments drawer, share, report, block

**Files:**
- Create: `src/components/reels/ReelActions.tsx`, `src/components/reels/ReelActions.test.tsx`
- Modify: `src/components/reels/ReelsGridPage.tsx` (pass `renderActions`), `src/components/reels/Reels.scss`, `src/utils/locales/eng.json` (`reels.actions.*`)

**Interfaces:**
- Consumes (all existing web code; app parity from `reels_feed_screen.dart:400-565` and `widgets/reel_overlays.dart`):
  - `useLikeMomentMutation` / `useDislikeMomentMutation` → `POST /moments/:id/like` / `POST /moments/:id/dislike`, body `{userId}` (`src/store/slices/momentsSlice.ts:88-103`; 400 "Already liked" is treated as success, as the server's answer for a double tap).
  - `useShareMomentMutation` → `POST /moments/:id/share` (`momentsSlice.ts` `shareMoment`; `be/controllers/moments.js:1675-1695`), and `ShareButton` (`src/components/linking/ShareButton.tsx`, props `{type, id, title, text?, className?}`) for the OS share sheet / clipboard — same pattern as `SingleMoment.tsx:643-660`: the wrapper's click records the share count.
  - `CommentList` (`src/components/moments/comments/CommentList.tsx`, props `{momentId, momentText?, myUserId?, isLoggedIn, onRequireLogin, onTotalChange?}`) with the Phase 3 composer (P3-MOM-8: GIF, photo-only, mentions drawn).
  - Phase 3 P3-MOM-5 dialogs: `ReportMomentDialog` (`{type:"moment", targetId, authorId, onClose}`, posts `POST /api/v1/reports` — the path that counts towards the 2-report auto-hide) and `BlockAuthorDialog` (`{authorId, authorName?, onClose, onBlocked?}`; invalidates `Moments`).
  - The viewer never shows the viewer's own reels: the feed excludes them (`be/controllers/moments.js:358`), so there is no owner menu here; owners manage their reels in My Moments.
- Produces: `ReelActions` default export, props `{ reel: Reel; myUserId: string; onPatch(patch: Partial<Reel>): void; onAuthorBlocked(authorId: string): void }`. Testids `reel-like`, `reel-like-count`, `reel-comments`, `reel-comment-count`, `reel-comments-drawer`, `reel-comments-close`, `reel-share`, `reel-more`, `reel-report`, `reel-block`, `reel-author-link`.

- [ ] **Step 1: Write the failing test**

Create `src/components/reels/ReelActions.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { MemoryRouter } from "react-router-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import ReelActions from "./ReelActions";

const mockLike = jest.fn();
const mockDislike = jest.fn();
const mockShare = jest.fn();
jest.mock("../../store/slices/momentsSlice", () => ({
  useLikeMomentMutation: () => [mockLike, { isLoading: false }],
  useDislikeMomentMutation: () => [mockDislike, { isLoading: false }],
  useShareMomentMutation: () => [mockShare, { isLoading: false }],
}));
jest.mock("../moments/comments/CommentList", () => ({
  __esModule: true,
  default: (p: any) => (
    <div data-testid="comment-list-stub" data-moment={p.momentId}>
      <button onClick={() => p.onTotalChange && p.onTotalChange(7)}>total</button>
    </div>
  ),
}));
jest.mock("../linking/ShareButton", () => ({
  __esModule: true,
  default: (p: any) => <button data-testid="share-stub" data-type={p.type} data-id={p.id} />,
}));
jest.mock("../moments/actions/ReportMomentDialog", () => ({
  __esModule: true,
  default: (p: any) => <div data-testid="report-stub">{`${p.type}:${p.targetId}:${p.authorId}`}</div>,
}));
jest.mock("../moments/actions/BlockAuthorDialog", () => ({
  __esModule: true,
  default: (p: any) => (
    <button data-testid="block-stub" onClick={() => p.onBlocked && p.onBlocked()}>
      {p.authorId}
    </button>
  ),
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const ok = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const reel = (over: any = {}) => ({
  id: "r1", description: "hi", language: "ko", likeCount: 2, commentCount: 1, shareCount: 0, isLiked: false,
  createdAt: "", videoUrl: "https://cdn.test/r1.mp4", thumbnail: null, duration: null, portrait: true,
  author: { id: "u9", name: "Mina", avatar: undefined }, ...over,
});

function renderActions(r: any = reel()) {
  const onPatch = jest.fn();
  const onAuthorBlocked = jest.fn();
  render(
    <MemoryRouter>
      <ReelActions reel={r} myUserId="me" onPatch={onPatch} onAuthorBlocked={onAuthorBlocked} />
    </MemoryRouter>
  );
  return { onPatch, onAuthorBlocked };
}

beforeEach(() => {
  [mockLike, mockDislike, mockShare].forEach((m) => {
    m.mockReset();
    m.mockReturnValue(ok());
  });
});

it("likes optimistically with the app's request", async () => {
  const { onPatch } = renderActions();
  fireEvent.click(screen.getByTestId("reel-like"));
  expect(onPatch).toHaveBeenCalledWith({ isLiked: true, likeCount: 3 });
  await waitFor(() => expect(mockLike).toHaveBeenCalledWith({ momentId: "r1", userId: "me" }));
});

it("unlikes through /dislike, and rolls back when the server refuses", async () => {
  mockDislike.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
  const { onPatch } = renderActions(reel({ isLiked: true, likeCount: 3 }));
  fireEvent.click(screen.getByTestId("reel-like"));
  expect(onPatch).toHaveBeenNthCalledWith(1, { isLiked: false, likeCount: 2 });
  await waitFor(() => expect(onPatch).toHaveBeenNthCalledWith(2, { isLiked: true, likeCount: 3 }));
});

it("treats 'Already liked' as liked (a double tap from another device)", async () => {
  mockLike.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { message: "Already liked" } }) });
  const { onPatch } = renderActions();
  fireEvent.click(screen.getByTestId("reel-like"));
  await waitFor(() => expect(mockLike).toHaveBeenCalled());
  expect(onPatch).toHaveBeenCalledTimes(1);
});

it("opens the comments of this reel and follows the server's total", () => {
  const { onPatch } = renderActions();
  fireEvent.click(screen.getByTestId("reel-comments"));
  expect(screen.getByTestId("comment-list-stub")).toHaveAttribute("data-moment", "r1");
  fireEvent.click(screen.getByText("total"));
  expect(onPatch).toHaveBeenCalledWith({ commentCount: 7 });
  fireEvent.click(screen.getByTestId("reel-comments-close"));
  expect(screen.queryByTestId("reel-comments-drawer")).not.toBeInTheDocument();
});

it("shares the moment link and counts the share", () => {
  const { onPatch } = renderActions();
  const share = screen.getByTestId("share-stub");
  expect(share).toHaveAttribute("data-type", "moment");
  expect(share).toHaveAttribute("data-id", "r1");
  fireEvent.click(screen.getByTestId("reel-share"));
  expect(mockShare).toHaveBeenCalledWith("r1");
  expect(onPatch).toHaveBeenCalledWith({ shareCount: 1 });
});

it("reports through the Report collection, typed as a moment", () => {
  renderActions();
  fireEvent.click(screen.getByTestId("reel-more"));
  fireEvent.click(screen.getByTestId("reel-report"));
  expect(screen.getByTestId("report-stub")).toHaveTextContent("moment:r1:u9");
});

it("blocks the author and tells the viewer to drop their reels", () => {
  const { onAuthorBlocked } = renderActions();
  fireEvent.click(screen.getByTestId("reel-more"));
  fireEvent.click(screen.getByTestId("reel-block"));
  fireEvent.click(screen.getByTestId("block-stub"));
  expect(onAuthorBlocked).toHaveBeenCalledWith("u9");
});

it("links the author to their profile", () => {
  renderActions();
  expect(screen.getByTestId("reel-author-link")).toHaveAttribute("href", "/profile/u9");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels && CI=true npm test -- --watchAll=false ReelActions
```
Expected: FAIL — `Cannot find module './ReelActions'`.

- [ ] **Step 3: Implement**

Create `src/components/reels/ReelActions.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { FaCommentDots, FaEllipsisH, FaFlag, FaHeart, FaRegHeart, FaShare, FaTimes, FaUserSlash } from "react-icons/fa";
import { useDislikeMomentMutation, useLikeMomentMutation, useShareMomentMutation } from "../../store/slices/momentsSlice";
import CommentList from "../moments/comments/CommentList";
import ShareButton from "../linking/ShareButton";
import ReportMomentDialog from "../moments/actions/ReportMomentDialog";
import BlockAuthorDialog from "../moments/actions/BlockAuthorDialog";
import { Reel } from "./lib/reelModel";

export interface ReelActionsProps {
  reel: Reel;
  myUserId: string;
  onPatch(patch: Partial<Reel>): void;
  onAuthorBlocked(authorId: string): void;
}

const isAlreadyLiked = (err: any) => {
  const d = err && err.data;
  const msg = (d && (d.message || d.error)) || "";
  return err && err.status === 400 && /already liked/i.test(String(msg));
};

/** The right-hand action rail of a reel (the app's reel_overlays.dart). */
const ReelActions: React.FC<ReelActionsProps> = ({ reel, myUserId, onPatch, onAuthorBlocked }) => {
  const { t } = useTranslation();
  const [likeMoment] = useLikeMomentMutation();
  const [dislikeMoment] = useDislikeMomentMutation();
  const [shareMoment] = useShareMomentMutation();
  const [commentsOpen, setCommentsOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [dialog, setDialog] = useState<"report" | "block" | null>(null);

  const toggleLike = () => {
    const before = { isLiked: reel.isLiked, likeCount: reel.likeCount };
    const liking = !reel.isLiked;
    onPatch({ isLiked: liking, likeCount: Math.max(0, reel.likeCount + (liking ? 1 : -1)) });
    const call = liking ? likeMoment : dislikeMoment;
    Promise.resolve()
      .then(() => call({ momentId: reel.id, userId: myUserId }).unwrap())
      .catch((err: any) => {
        if (liking && isAlreadyLiked(err)) return;
        onPatch(before);
      });
  };

  const trackShare = () => {
    onPatch({ shareCount: reel.shareCount + 1 });
    Promise.resolve()
      .then(() => shareMoment(reel.id).unwrap())
      .catch(() => {});
  };

  return (
    <>
      <Link to={`/profile/${reel.author.id}`} className="reel-avatar" data-testid="reel-author-link"
        aria-label={reel.author.name || t("reels.actions.profile") || "Profile"}>
        {reel.author.avatar ? <img src={reel.author.avatar} alt="" /> : <span>{(reel.author.name || "?").charAt(0)}</span>}
      </Link>

      <button type="button" className="reel-action" data-testid="reel-like" onClick={toggleLike}
        aria-pressed={reel.isLiked} aria-label={reel.isLiked ? t("reels.actions.unlike") || "Unlike" : t("reels.actions.like") || "Like"}>
        {reel.isLiked ? <FaHeart aria-hidden="true" className="reel-liked" /> : <FaRegHeart aria-hidden="true" />}
        <span data-testid="reel-like-count">{reel.likeCount}</span>
      </button>

      <button type="button" className="reel-action" data-testid="reel-comments" onClick={() => setCommentsOpen(true)}
        aria-label={t("reels.actions.comments") || "Comments"}>
        <FaCommentDots aria-hidden="true" />
        <span data-testid="reel-comment-count">{reel.commentCount}</span>
      </button>

      <span className="reel-action" data-testid="reel-share" onClick={trackShare}>
        <ShareButton type="moment" id={reel.id} title={reel.author.name || "BananaTalk"} text={reel.description}
          className="reel-share-inner" />
        <FaShare aria-hidden="true" />
        <span>{reel.shareCount}</span>
      </span>

      <div className="reel-more-wrap">
        <button type="button" className="reel-action" data-testid="reel-more" aria-haspopup="menu"
          aria-expanded={menuOpen} onClick={() => setMenuOpen((o) => !o)} aria-label={t("reels.actions.more") || "More"}>
          <FaEllipsisH aria-hidden="true" />
        </button>
        {menuOpen && (
          <div className="reel-menu" role="menu">
            <button type="button" role="menuitem" data-testid="reel-report"
              onClick={() => { setMenuOpen(false); setDialog("report"); }}>
              <FaFlag aria-hidden="true" /> {t("reels.actions.report") || "Report"}
            </button>
            <button type="button" role="menuitem" data-testid="reel-block" className="reel-menu-danger"
              onClick={() => { setMenuOpen(false); setDialog("block"); }}>
              <FaUserSlash aria-hidden="true" /> {t("reels.actions.block") || "Block user"}
            </button>
          </div>
        )}
      </div>

      {commentsOpen && (
        <div className="reel-comments-drawer" data-testid="reel-comments-drawer" role="dialog"
          aria-label={t("reels.actions.comments") || "Comments"}
          onWheel={(e) => e.stopPropagation()} onTouchStart={(e) => e.stopPropagation()} onTouchEnd={(e) => e.stopPropagation()}
          onKeyDown={(e) => e.stopPropagation()}>
          <div className="reel-comments-head">
            <strong>{t("reels.actions.comments") || "Comments"}</strong>
            <button type="button" className="reel-icon-btn" data-testid="reel-comments-close"
              onClick={() => setCommentsOpen(false)} aria-label={t("reels.viewer.close") || "Close"}>
              <FaTimes aria-hidden="true" />
            </button>
          </div>
          <CommentList
            momentId={reel.id}
            momentText={reel.description}
            myUserId={myUserId}
            isLoggedIn
            onRequireLogin={() => {}}
            onTotalChange={(total) => onPatch({ commentCount: total })}
          />
        </div>
      )}

      {dialog === "report" && (
        <ReportMomentDialog type="moment" targetId={reel.id} authorId={reel.author.id} onClose={() => setDialog(null)} />
      )}
      {dialog === "block" && (
        <BlockAuthorDialog authorId={reel.author.id} authorName={reel.author.name} onClose={() => setDialog(null)}
          onBlocked={() => { setDialog(null); onAuthorBlocked(reel.author.id); }} />
      )}
    </>
  );
};

export default ReelActions;
```

The comments drawer stops wheel, touch and key events from reaching the viewer: scrolling the comment list or typing `j`/`k` in the composer must not change reels. Note the viewer listens for keys on `window`; add this guard at the top of the viewer's `onKey` in `ReelViewer.tsx`:

```ts
      const target = e.target as HTMLElement | null;
      if (target && (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable)) return;
```

In `src/components/reels/ReelsGridPage.tsx`:
- `import { useSelector } from "react-redux";` and `import ReelActions from "./ReelActions";`
- `const myUserId = useSelector((state: any) => (state.auth.userInfo && state.auth.userInfo.user && state.auth.userInfo.user._id) || "");`
- pass to `<ReelViewer … renderActions={(reel) => (
  <ReelActions
    reel={reel}
    myUserId={myUserId}
    onPatch={(patch) => feed.patchReel(reel.id, patch)}
    onAuthorBlocked={(authorId) => {
      closeViewer();
      feed.removeWhere((r) => r.author.id === authorId);
    }}
  />
)} />`

Append to `Reels.scss`:

```scss
.reel-avatar { inline-size: 44px; block-size: 44px; border-radius: 999px; overflow: hidden; border: 2px solid #fff; background: #374151; color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 800; }
.reel-avatar img { inline-size: 100%; block-size: 100%; object-fit: cover; }
.reel-action { position: relative; border: 0; background: transparent; color: #fff; display: flex; flex-direction: column; align-items: center; gap: 2px; font-size: 0.75rem; font-weight: 700; cursor: pointer; }
.reel-action svg { font-size: 1.6rem; filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.6)); }
.reel-liked { color: #ef4444; }
.reel-share-inner { position: absolute; inset: 0; opacity: 0; } // ShareButton covers the icon, invisible
.reel-more-wrap { position: relative; }
.reel-menu { position: absolute; inset-inline-end: 48px; inset-block-end: 0; min-inline-size: 160px; background: #fff; border-radius: 12px; padding: 6px; box-shadow: 0 6px 24px rgba(0, 0, 0, 0.25); }
.reel-menu button { display: flex; gap: 8px; align-items: center; inline-size: 100%; border: 0; background: transparent; padding: 8px 10px; text-align: start; border-radius: 8px; }
.reel-menu-danger { color: #dc2626; }
.reel-comments-drawer { position: fixed; inset-block: 0; inset-inline-end: 0; inline-size: min(420px, 100vw); background: #fff; z-index: 1055; overflow-y: auto; padding: 12px 16px; text-align: start; touch-action: auto; }
.reel-comments-head { display: flex; align-items: center; justify-content: space-between; margin-block-end: 8px; }
.reel-comments-head .reel-icon-btn { color: #111; background: #f3f4f6; }
```

Add to `eng.json` under `reels`:

```json
"actions": {
  "profile": "Profile",
  "like": "Like",
  "unlike": "Unlike",
  "comments": "Comments",
  "more": "More",
  "report": "Report",
  "block": "Block user"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false ReelActions ReelViewer ReelsGridPage
```
Expected: 8 action tests pass; viewer and grid tests stay green.

- [ ] **Step 5: Commit**

```bash
git add src/components/reels/ReelActions.tsx src/components/reels/ReelActions.test.tsx src/components/reels/ReelViewer.tsx src/components/reels/ReelsGridPage.tsx src/components/reels/Reels.scss src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(reels): like, comment, share, report and block from the viewer

Same endpoints as the app: like/dislike with an optimistic count and
rollback, the moments comment list in a side drawer, the moment link
shared and counted, reports through POST /reports (counts towards the
2-report auto-hide), block drops the author's reels. Typing in the
comment box never changes reels.

Still open (Phase 4 reels): create, routes behind the flag, i18n, push.
EOF
```

---

### Task P4-REEL-6: Create a reel: video ≤ 180 s checked before upload, `isReel: true`, rollback on a failed upload

**Files:**
- Create: `src/components/reels/lib/videoChecks.ts`, `src/components/reels/lib/videoChecks.test.ts`
- Create: `src/components/reels/ReelCreatePage.tsx`, `src/components/reels/ReelCreatePage.test.tsx`
- Modify: `src/components/reels/Reels.scss`, `src/utils/locales/eng.json` (`reels.create.*`)

**Interfaces:**
- Consumes:
  - `useCreateMomentMutation` → `POST /api/v1/moments` (`momentsSlice.ts:51-58`), body exactly `{description, privacy:'public', category:'general', language, isReel:true}` (the app's reel composer: public only, no mood/tags/location/schedule/background — `create_moment.dart:1256,1577`; `privacy:'public'` because the feed only serves public reels, `be/lib/reelsFeed.js:39`). `language` omitted when empty (validator: optional). Answer `{data:{_id,…}}`.
  - `useUploadMomentVideoMutation` → `PUT /moments/:id/video` FormData field `video` (`momentsSlice.ts:326-333`; `be/routes/moments.js:91-98`). Server errors: 400 `code:'REEL_TOO_LONG'` (> 180 s, upload deleted, `be/controllers/moments.js:1081-1088`), 400 invalid type, 413 too large.
  - `useDeleteMomentMutation` → `DELETE /moments/:id` (rollback when the upload fails — P3-MOM-1's rule: never leave an empty moment).
  - `useGetVideoConfigQuery` (P4-REEL-1): allowed types and max size.
  - `ReelPolicyGate` (P4-REEL-2) — the app gates creation too (`reel_policy_dialog.dart` doc comment).
  - `LanguageField` (`src/components/moments/fields/LanguageField.tsx`, props `{value, onChange, id?}`).
- Produces:
  - `videoChecks.ts`: `readVideoDuration(file: File): Promise<number | null>` (null when the browser cannot tell — e.g. WebM reporting `Infinity`; the server still enforces the cap), `checkReelFile(file: {type: string; name: string; size: number}, config: VideoConfig): "ok" | "type" | "size"`, `REEL_ACCEPT = "video/*"`.
  - `ReelCreatePage` default export (`/reels/new`, routed in P4-REEL-7). Testids `reel-create`, `reel-file`, `reel-preview`, `reel-caption`, `reel-post`, `reel-create-error`. On success navigates to `/moment/<id>` (the viewer's own reels are not in the reels feed) with a success toast.

- [ ] **Step 1: Write the failing tests**

Create `src/components/reels/lib/videoChecks.test.ts`:

```ts
import { checkReelFile, readVideoDuration } from "./videoChecks";

const config = { allowedTypes: ["video/mp4", "video/quicktime", "video/webm"], maxSize: 1000 };

it("accepts an allowed type within the size limit", () => {
  expect(checkReelFile({ type: "video/mp4", name: "a.mp4", size: 999 }, config)).toBe("ok");
});

it("accepts a known extension when the browser gives no type (some .mov on Windows)", () => {
  expect(checkReelFile({ type: "", name: "clip.MOV", size: 10 }, config)).toBe("ok");
});

it("refuses other types and oversized files", () => {
  expect(checkReelFile({ type: "image/gif", name: "a.gif", size: 10 }, config)).toBe("type");
  expect(checkReelFile({ type: "video/mp4", name: "a.mp4", size: 1001 }, config)).toBe("size");
});

describe("readVideoDuration", () => {
  const realCreate = document.createElement.bind(document);
  let fakeVideo: any;
  beforeEach(() => {
    (URL as any).createObjectURL = jest.fn(() => "blob:x");
    (URL as any).revokeObjectURL = jest.fn();
    fakeVideo = { set src(_v: string) { setTimeout(() => fakeVideo.onloadedmetadata && fakeVideo.onloadedmetadata(), 0); }, duration: 0 };
    jest.spyOn(document, "createElement").mockImplementation((tag: string) =>
      tag === "video" ? fakeVideo : realCreate(tag)
    );
  });
  afterEach(() => jest.restoreAllMocks());

  it("reads the duration from the file's metadata and frees the object URL", async () => {
    fakeVideo.duration = 95.2;
    await expect(readVideoDuration(new File(["x"], "a.mp4", { type: "video/mp4" }))).resolves.toBe(95.2);
    expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:x");
  });

  it("returns null when the browser cannot tell (WebM reports Infinity)", async () => {
    fakeVideo.duration = Infinity;
    await expect(readVideoDuration(new File(["x"], "a.webm", { type: "video/webm" }))).resolves.toBe(null);
  });

  it("returns null when the file cannot be decoded", async () => {
    fakeVideo = { set src(_v: string) { setTimeout(() => fakeVideo.onerror && fakeVideo.onerror(), 0); } };
    await expect(readVideoDuration(new File(["x"], "a.mp4", { type: "video/mp4" }))).resolves.toBe(null);
  });
});
```

Create `src/components/reels/ReelCreatePage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { render, screen, fireEvent, waitFor, act } from "@testing-library/react";
import ReelCreatePage from "./ReelCreatePage";

const mockCreate = jest.fn();
const mockUpload = jest.fn();
const mockDelete = jest.fn();
let mockDuration: number | null = 30;
jest.mock("../../store/slices/momentsSlice", () => ({
  useCreateMomentMutation: () => [mockCreate, { isLoading: false }],
  useUploadMomentVideoMutation: () => [mockUpload, { isLoading: false }],
  useDeleteMomentMutation: () => [mockDelete, { isLoading: false }],
}));
jest.mock("../../store/slices/reelsSlice", () => ({
  useGetVideoConfigQuery: () => ({ data: { allowedTypes: ["video/mp4"], maxSize: 5000 } }),
}));
jest.mock("./lib/videoChecks", () => {
  const actual = jest.requireActual("./lib/videoChecks");
  return { ...actual, readVideoDuration: () => Promise.resolve(mockDuration) };
});
jest.mock("./ReelPolicyGate", () => ({ __esModule: true, default: (p: any) => <>{p.children}</> }));
jest.mock("../moments/fields/LanguageField", () => ({
  __esModule: true,
  default: (p: any) => <input data-testid="lang" value={p.value} onChange={(e) => p.onChange(e.target.value)} />,
}));
jest.mock("react-toastify", () => ({ toast: { success: jest.fn(), error: jest.fn() } }));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const ok = (data: any) => ({ unwrap: () => Promise.resolve(data) });
const fail = (err: any) => ({ unwrap: () => Promise.reject(err) });

function renderPage() {
  (URL as any).createObjectURL = jest.fn(() => "blob:preview");
  (URL as any).revokeObjectURL = jest.fn();
  render(
    <MemoryRouter initialEntries={["/reels/new"]}>
      <Routes>
        <Route path="/reels/new" element={<ReelCreatePage />} />
        <Route path="/moment/:id" element={<div data-testid="moment-page" />} />
      </Routes>
    </MemoryRouter>
  );
}

async function pick(file: File) {
  await act(async () => {
    fireEvent.change(screen.getByTestId("reel-file"), { target: { files: [file] } });
  });
}
const mp4 = (size = 100) => new File([new Uint8Array(size)], "clip.mp4", { type: "video/mp4" });

beforeEach(() => {
  mockDuration = 30;
  [mockCreate, mockUpload, mockDelete].forEach((m) => m.mockReset());
  mockCreate.mockReturnValue(ok({ success: true, data: { _id: "m1" } }));
  mockUpload.mockReturnValue(ok({ success: true }));
  mockDelete.mockReturnValue(ok({ success: true }));
});

it("posts a public reel with isReel:true, then uploads the video as `video`", async () => {
  renderPage();
  expect(screen.getByTestId("reel-post")).toBeDisabled();
  await pick(mp4());
  expect(screen.getByTestId("reel-preview")).toHaveAttribute("src", "blob:preview");
  fireEvent.change(screen.getByTestId("reel-caption"), { target: { value: "  My first reel  " } });
  fireEvent.change(screen.getByTestId("lang"), { target: { value: "ko" } });
  await act(async () => {
    fireEvent.click(screen.getByTestId("reel-post"));
  });
  expect(mockCreate).toHaveBeenCalledWith({
    description: "My first reel",
    privacy: "public",
    category: "general",
    language: "ko",
    isReel: true,
  });
  const { momentId, formData } = mockUpload.mock.calls[0][0];
  expect(momentId).toBe("m1");
  expect((formData as FormData).get("video")).toBeInstanceOf(File);
  await waitFor(() => expect(screen.getByTestId("moment-page")).toBeInTheDocument());
});

it("refuses a video over 3 minutes before uploading anything", async () => {
  mockDuration = 181;
  renderPage();
  await pick(mp4());
  expect(screen.getByTestId("reel-create-error")).toHaveTextContent("3:00");
  expect(screen.getByTestId("reel-post")).toBeDisabled();
  expect(mockCreate).not.toHaveBeenCalled();
});

it("allows a video whose length the browser cannot read (the server checks it)", async () => {
  mockDuration = null;
  renderPage();
  await pick(mp4());
  expect(screen.queryByTestId("reel-create-error")).not.toBeInTheDocument();
  expect(screen.getByTestId("reel-post")).not.toBeDisabled();
});

it("refuses a wrong type or an oversized file", async () => {
  renderPage();
  await pick(new File(["x"], "a.gif", { type: "image/gif" }));
  expect(screen.getByTestId("reel-create-error")).toBeInTheDocument();
  await pick(mp4(6000));
  expect(screen.getByTestId("reel-create-error")).toBeInTheDocument();
  expect(screen.getByTestId("reel-post")).toBeDisabled();
});

it("deletes the empty reel and says why when the server finds it too long", async () => {
  mockUpload.mockReturnValue(fail({ status: 400, data: { code: "REEL_TOO_LONG", error: "Reels must be 180 seconds or under" } }));
  renderPage();
  await pick(mp4());
  await act(async () => {
    fireEvent.click(screen.getByTestId("reel-post"));
  });
  await waitFor(() => expect(mockDelete).toHaveBeenCalledWith("m1"));
  expect(screen.getByTestId("reel-create-error")).toHaveTextContent("3 minutes");
  expect(screen.queryByTestId("moment-page")).not.toBeInTheDocument();
});

it("keeps the form when creating the moment fails (posting limit, network)", async () => {
  mockCreate.mockReturnValue(fail({ status: 429, data: { error: "Daily moment limit reached" } }));
  renderPage();
  await pick(mp4());
  await act(async () => {
    fireEvent.click(screen.getByTestId("reel-post"));
  });
  expect(mockUpload).not.toHaveBeenCalled();
  expect(screen.getByTestId("reel-create-error")).toHaveTextContent("Daily moment limit reached");
  expect(screen.getByTestId("reel-post")).not.toBeDisabled();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels && CI=true npm test -- --watchAll=false videoChecks ReelCreatePage
```
Expected: FAIL — `Cannot find module './videoChecks'` / `'./ReelCreatePage'`.

- [ ] **Step 3: Implement**

Create `src/components/reels/lib/videoChecks.ts`:

```ts
import { VideoConfig } from "../../../store/slices/reelsSlice";

export const REEL_ACCEPT = "video/*";

const EXT_TYPES: { [ext: string]: string } = {
  mp4: "video/mp4",
  mov: "video/quicktime",
  avi: "video/x-msvideo",
  webm: "video/webm",
  "3gp": "video/3gpp",
  m4v: "video/x-m4v",
};

/** Type and size against GET /moments/video-config; the duration is separate. */
export function checkReelFile(
  file: { type: string; name: string; size: number },
  config: VideoConfig
): "ok" | "type" | "size" {
  const ext = (file.name.split(".").pop() || "").toLowerCase();
  const type = file.type || EXT_TYPES[ext] || "";
  if (!type || config.allowedTypes.indexOf(type) < 0) return "type";
  if (file.size > config.maxSize) return "size";
  return "ok";
}

/**
 * The video's length in seconds from its metadata, or null when the browser
 * cannot say (MediaRecorder WebM reports Infinity; undecodable codecs error).
 * Null is allowed through: the server measures every upload and refuses a
 * reel over 180 s with REEL_TOO_LONG.
 */
export function readVideoDuration(file: File): Promise<number | null> {
  return new Promise((resolve) => {
    let url = "";
    try {
      url = URL.createObjectURL(file);
    } catch (e) {
      resolve(null);
      return;
    }
    const video: any = document.createElement("video");
    const done = (value: number | null) => {
      try {
        URL.revokeObjectURL(url);
      } catch (e) {
        // ignore
      }
      resolve(value);
    };
    video.preload = "metadata";
    video.muted = true;
    video.onloadedmetadata = () => {
      const d = Number(video.duration);
      done(isFinite(d) && d > 0 ? d : null);
    };
    video.onerror = () => done(null);
    video.src = url;
  });
}
```

Create `src/components/reels/ReelCreatePage.tsx`:

```tsx
import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import {
  useCreateMomentMutation,
  useDeleteMomentMutation,
  useUploadMomentVideoMutation,
} from "../../store/slices/momentsSlice";
import { DEFAULT_VIDEO_CONFIG, useGetVideoConfigQuery } from "../../store/slices/reelsSlice";
import LanguageField from "../moments/fields/LanguageField";
import ReelPolicyGate from "./ReelPolicyGate";
import { checkReelFile, readVideoDuration, REEL_ACCEPT } from "./lib/videoChecks";
import { formatReelDuration, REEL_MAX_SECONDS } from "./lib/reelModel";
import "./Reels.scss";

const CAPTION_MAX = 2000;

function serverError(err: any): string {
  const d = err && err.data;
  const msg = d && (d.error || d.message);
  return typeof msg === "string" ? msg : "";
}

/**
 * /reels/new -- the app's reel composer (create_reel_flow.dart +
 * CreateMoment in isReel mode), minus the trim/filter editor (spec
 * non-goal): pick a video of at most 3 minutes, caption, language, post.
 */
const ReelCreatePage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { data: config } = useGetVideoConfigQuery(undefined);
  const [createMoment] = useCreateMomentMutation();
  const [uploadMomentVideo] = useUploadMomentVideoMutation();
  const [deleteMoment] = useDeleteMomentMutation();

  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string>("");
  const [caption, setCaption] = useState("");
  const [language, setLanguage] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    return () => {
      if (preview) {
        try {
          URL.revokeObjectURL(preview);
        } catch (e) {
          // ignore
        }
      }
    };
  }, [preview]);

  const tooLongText = (seconds?: number | null) =>
    t("reels.create.too_long", { duration: formatReelDuration(seconds || 0) || "" }) ||
    `Reels can be up to 3:00. This video is ${formatReelDuration(seconds || 0) || "longer"}.`;

  const onPick = async (picked: File | null) => {
    setError("");
    setFile(null);
    setPreview("");
    if (!picked) return;
    const verdict = checkReelFile(picked, config || DEFAULT_VIDEO_CONFIG);
    if (verdict === "type") {
      setError(t("reels.create.bad_type") || "This file type isn't supported. Use MP4, MOV or WebM.");
      return;
    }
    if (verdict === "size") {
      setError(t("reels.create.too_big") || "This video is too large to upload.");
      return;
    }
    const duration = await readVideoDuration(picked);
    if (duration !== null && duration > REEL_MAX_SECONDS) {
      setError(tooLongText(duration));
      return;
    }
    setFile(picked);
    setPreview(URL.createObjectURL(picked));
  };

  const post = async () => {
    if (!file || busy) return;
    setBusy(true);
    setError("");
    let momentId = "";
    try {
      // The app's reel body: public only (the feed serves public reels),
      // isReel a literal boolean, language only when chosen.
      const body: any = { description: caption.trim(), privacy: "public", category: "general" };
      if (language) body.language = language;
      body.isReel = true;
      const created: any = await createMoment(body).unwrap();
      momentId = created && created.data && created.data._id ? String(created.data._id) : "";
      if (!momentId) throw new Error("no id");
    } catch (err) {
      setBusy(false);
      setError(serverError(err) || t("reels.create.failed") || "Couldn't post your reel. Try again.");
      return;
    }
    try {
      const formData = new FormData();
      formData.append("video", file, file.name);
      await uploadMomentVideo({ momentId, formData }).unwrap();
    } catch (err) {
      // No empty reel left behind (P3-MOM-1's rule).
      Promise.resolve()
        .then(() => deleteMoment(momentId).unwrap())
        .catch(() => {});
      setBusy(false);
      const code = err && (err as any).data && (err as any).data.code;
      setError(
        code === "REEL_TOO_LONG"
          ? t("reels.create.server_too_long") || "Reels must be 3 minutes or shorter."
          : t("reels.create.upload_failed") || "The video didn't upload. Nothing was posted — try again."
      );
      return;
    }
    toast.success(t("reels.create.posted") || "Your reel is posted.");
    navigate(`/moment/${momentId}`);
  };

  return (
    <ReelPolicyGate onDeclined={() => navigate("/moments")}>
      <section className="reel-create" data-testid="reel-create">
        <h1 className="reels-title">{t("reels.create.title") || "New reel"}</h1>
        <p className="reel-create-hint">
          {t("reels.create.hint") || "A short language-learning video, up to 3 minutes. Vertical (9:16) looks best."}
        </p>

        <label className="reel-file-label">
          <span>{file ? t("reels.create.change_video") || "Choose another video" : t("reels.create.choose_video") || "Choose a video"}</span>
          <input
            type="file"
            accept={REEL_ACCEPT}
            data-testid="reel-file"
            className="reel-file-input"
            disabled={busy}
            onChange={(e) => onPick(e.target.files && e.target.files[0] ? e.target.files[0] : null)}
          />
        </label>

        {preview && (
          <video data-testid="reel-preview" className="reel-preview" src={preview} controls muted playsInline />
        )}

        <label htmlFor="reel-caption" className="reel-field-label">
          {t("reels.create.caption") || "Caption"}
        </label>
        <textarea
          id="reel-caption"
          data-testid="reel-caption"
          className="reel-caption-input"
          value={caption}
          maxLength={CAPTION_MAX}
          rows={3}
          disabled={busy}
          onChange={(e) => setCaption(e.target.value)}
          placeholder={t("reels.create.caption_placeholder") || "What are you practising?"}
        />

        <LanguageField id="reel-language" value={language} onChange={setLanguage} />

        {error && (
          <p className="reel-create-error" role="alert" data-testid="reel-create-error">
            {error}
          </p>
        )}

        <button type="button" className="reel-btn reel-btn-primary reel-post" data-testid="reel-post"
          disabled={!file || busy} onClick={post}>
          {busy ? t("reels.create.posting") || "Posting…" : t("reels.create.post") || "Post reel"}
        </button>
      </section>
    </ReelPolicyGate>
  );
};

export default ReelCreatePage;
```

Append to `Reels.scss`:

```scss
.reel-create { max-inline-size: 560px; margin-inline: auto; padding: 16px; display: flex; flex-direction: column; gap: 12px; text-align: start; }
.reel-create-hint { color: #6b7280; font-size: 0.875rem; margin: 0; }
.reel-file-label { display: inline-flex; align-self: flex-start; align-items: center; gap: 8px; padding: 10px 16px; border-radius: 999px; border: 2px dashed #f5b800; font-weight: 700; cursor: pointer; }
.reel-file-input { position: absolute; inline-size: 1px; block-size: 1px; opacity: 0; }
.reel-preview { inline-size: 100%; max-block-size: 60vh; border-radius: 12px; background: #000; }
.reel-field-label { font-weight: 700; font-size: 0.875rem; }
.reel-caption-input { inline-size: 100%; border: 1px solid #d1d5db; border-radius: 10px; padding: 10px; }
.reel-create-error { color: #dc2626; font-size: 0.875rem; margin: 0; }
.reel-post { align-self: flex-end; }
```

Add to `eng.json` under `reels`:

```json
"create": {
  "title": "New reel",
  "hint": "A short language-learning video, up to 3 minutes. Vertical (9:16) looks best.",
  "choose_video": "Choose a video",
  "change_video": "Choose another video",
  "caption": "Caption",
  "caption_placeholder": "What are you practising?",
  "bad_type": "This file type isn't supported. Use MP4, MOV or WebM.",
  "too_big": "This video is too large to upload.",
  "too_long": "Reels can be up to 3:00. This video is {{duration}}.",
  "server_too_long": "Reels must be 3 minutes or shorter.",
  "upload_failed": "The video didn't upload. Nothing was posted — try again.",
  "failed": "Couldn't post your reel. Try again.",
  "posting": "Posting…",
  "post": "Post reel",
  "posted": "Your reel is posted."
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false videoChecks ReelCreatePage
```
Expected: 6 + 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/reels/lib/videoChecks.ts src/components/reels/lib/videoChecks.test.ts src/components/reels/ReelCreatePage.tsx src/components/reels/ReelCreatePage.test.tsx src/components/reels/Reels.scss src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(reels): post a reel from the web, 3 minutes at most

Same two steps as the app: POST /moments {isReel:true, public} then the
video as `video` to PUT /moments/:id/video. Type, size and length are
checked before anything is sent (a length the browser can't read goes
through; the server refuses > 180 s with REEL_TOO_LONG). A failed upload
deletes the empty reel and keeps the form.

Still open (Phase 4 reels): routes behind the flag, i18n, push.
EOF
```

---

### Task P4-REEL-7: Routes, navbar and Moments entry behind `webReelsEnabled` + `reelsEnabled`; flag-off test

**Files:**
- Create: `src/components/reels/SignedInOnly.tsx`, `src/components/reels/reelsFlagOff.test.tsx`
- Modify: `src/router/routes.tsx` (lazy imports in a "Reels (Phase 4)" block after the "Stories / reels" group; two `<Route>`s after `highlights`)
- Modify: `src/components/navbar/MainNavbar.tsx` (desktop links after the Moments `NavLink` at `:240-246`; mobile links after `:409-411`), `src/components/navbar/MainNavbar.test.tsx` (app-config mock + two cases)
- Modify: `src/components/moments/MainMoments.tsx` (a Reels link beside the feed heading, `:483-487`), `src/components/moments/MainMoments.test.tsx` (i18n mock gains `i18n`, app-config mock, two cases)
- Modify: `src/utils/locales/eng.json` (`reels.nav`, `reels.moments_link`)

**Interfaces:**
- Consumes: `useWebFlag("webReelsEnabled")` and `FlagRoute` (P4-0; the flag module also requires `reelsEnabled`, `WEB_FLAG_REQUIRES`), `mockAppConfig` / `ALL_WEB_FLAGS_ON` / `ALL_WEB_FLAGS_OFF` (`src/utils/testing/mockWebFlags.ts`), `lazyWithRetry` + `lazyRoute` (`routes.tsx`).
- Produces: routes `/reels` (grid + viewer, `?reel=<id>`) and `/reels/new` (composer), each `<FlagRoute flag="webReelsEnabled">` around `<SignedInOnly>` around the lazy page; navbar entry `a[href="/reels"]` (desktop and mobile) and Moments link `data-testid="moments-reels-link"`, all rendered only while the flag is on. `SignedInOnly` default export, props `{ children }` — `Navigate` to `/login` when there is no session (the reels endpoints are `protect`ed; same rule as `MyMoments.tsx:157`).

- [ ] **Step 1: Write the failing tests**

Create `src/components/reels/reelsFlagOff.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { Provider } from "react-redux";
import { MemoryRouter, matchRoutes } from "react-router-dom";
import { render, screen } from "@testing-library/react";
import { configureStore } from "@reduxjs/toolkit";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";
import FlagRoute from "../../router/FlagRoute";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
jest.mock("../errors/NotFound", () => () => <div data-testid="not-found" />);
jest.mock("./ReelsGridPage", () => ({ __esModule: true, default: () => <div data-testid="reels-grid" /> }));
jest.mock("./ReelCreatePage", () => ({ __esModule: true, default: () => <div data-testid="reels-create-page" /> }));

const { routes } = require("../../router/routes");

function elementFor(path: string) {
  const matches = matchRoutes(routes, path);
  expect(matches && matches.length).toBe(2);
  return matches![1].route;
}

const store = configureStore({
  reducer: { auth: (s: any = { userInfo: { token: "t", user: { _id: "me" } } }) => s },
});
const renderAt = (path: string) =>
  render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <React.Suspense fallback={<div data-testid="chunk-loading" />}>{elementFor(path).element}</React.Suspense>
      </MemoryRouter>
    </Provider>
  );

it.each(["/reels", "/reels/new"])("%s is a real route gated by webReelsEnabled", (path) => {
  const route = elementFor(path);
  expect(route.path).not.toBe("*");
  expect(route.element.type).toBe(FlagRoute);
  expect(route.element.props.flag).toBe("webReelsEnabled");
});

it.each(["/reels", "/reels/new"])("%s is a 404 while the flag is off", (path) => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderAt(path);
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
  expect(screen.queryByTestId("reels-grid")).not.toBeInTheDocument();
  expect(screen.queryByTestId("reels-create-page")).not.toBeInTheDocument();
});

it("is a 404 when the web flag is on but REELS_ENABLED is off", () => {
  mockAppConfig({ ...ALL_WEB_FLAGS_ON, reelsEnabled: false });
  renderAt("/reels");
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
});

it("renders the page once both switches are on", async () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderAt("/reels");
  expect(await screen.findByTestId("reels-grid")).toBeInTheDocument();
});
```

In `src/components/navbar/MainNavbar.test.tsx`:
- add after the `react-i18next` mock:

```tsx
jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
```
  and `import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";`, plus `beforeEach(() => mockAppConfig(ALL_WEB_FLAGS_OFF));` (existing cases keep passing: every flag off is today's navbar);
- append:

```tsx
it("has no Reels entry while webReelsEnabled is off", () => {
  mockConversationsFetch([]);
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  const { container } = renderNavbar();
  expect(container.querySelector('a[href="/reels"]')).toBe(null);
});

it("shows Reels in the desktop and mobile menus once the flag is on", () => {
  mockConversationsFetch([]);
  mockAppConfig(ALL_WEB_FLAGS_ON);
  const { container } = renderNavbar();
  expect(container.querySelectorAll('a[href="/reels"]').length).toBeGreaterThanOrEqual(1);
});
```

In `src/components/moments/MainMoments.test.tsx`:
- change the i18n mock to `useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),` (the flag hook reads `i18n.language`),
- add `jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());`, the same import, and `mockAppConfig(ALL_WEB_FLAGS_OFF);` at the top of the existing `beforeEach`,
- append:

```tsx
it("offers no Reels link while the flag is off", () => {
  renderMainMoments(loggedInUser);
  expect(screen.queryByTestId("moments-reels-link")).not.toBeInTheDocument();
});

it("links to /reels for a signed-in user once the flag is on", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderMainMoments(loggedInUser);
  expect(screen.getByTestId("moments-reels-link")).toHaveAttribute("href", "/reels");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels && CI=true npm test -- --watchAll=false reelsFlagOff MainNavbar MainMoments routes
```
Expected: FAIL — `/reels` matches the catch-all (`matches[1].route.path` is `*`); the "flag on" navbar and Moments cases find no link. The existing navbar, Moments and routes cases pass.

- [ ] **Step 3: Implement**

Create `src/components/reels/SignedInOnly.tsx`:

```tsx
import React from "react";
import { useSelector } from "react-redux";
import { Navigate } from "react-router-dom";

/** The reels endpoints need a session; a signed-out visitor goes to /login. */
const SignedInOnly: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const userId = useSelector((state: any) => state.auth.userInfo && state.auth.userInfo.user && state.auth.userInfo.user._id);
  if (!userId) return <Navigate to="/login" replace />;
  return <>{children}</>;
};

export default SignedInOnly;
```

In `src/router/routes.tsx`:
- imports (eager, both tiny): `import FlagRoute from "./FlagRoute";` (if P4-0's import is not already there) and `import SignedInOnly from "../components/reels/SignedInOnly";`
- after the `// Stories / reels` lazy group:

```tsx
// Reels (Phase 4). Dark until /app-config says webReelsEnabled AND
// reelsEnabled (FlagRoute); a signed-out visitor is sent to /login.
const ReelsGridPage = lazyWithRetry("../components/reels/ReelsGridPage", () => import("../components/reels/ReelsGridPage"));
const ReelCreatePage = lazyWithRetry("../components/reels/ReelCreatePage", () => import("../components/reels/ReelCreatePage"));
```
- after `<Route path="highlights" … />`:

```tsx
    {/* Reels (Phase 4, flag webReelsEnabled). "reels/new" is static and
        outranks any future "reels/:id". */}
    <Route
      path="reels"
      element={<FlagRoute flag="webReelsEnabled"><SignedInOnly>{lazyRoute(<ReelsGridPage />)}</SignedInOnly></FlagRoute>}
    />
    <Route
      path="reels/new"
      element={<FlagRoute flag="webReelsEnabled"><SignedInOnly>{lazyRoute(<ReelCreatePage />)}</SignedInOnly></FlagRoute>}
    />
```

In `src/components/navbar/MainNavbar.tsx`:
- add `FaFilm` to the `react-icons/fa` import and `import { useWebFlag } from "../../utils/webFlags";`
- in the component body: `const reelsOn = useWebFlag("webReelsEnabled");`
- desktop, right after the Moments `NavLink`:

```tsx
                {reelsOn && (
                  <NavLink
                    to="/reels"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaFilm />
                    <span>{t("reels.nav") || "Reels"}</span>
                  </NavLink>
                )}
```
- mobile, right after the mobile Moments `NavLink`:

```tsx
                  {reelsOn && (
                    <NavLink to="/reels" className="mobile-nav-link" onClick={closeMobileMenu}>
                      <FaFilm /> {t("reels.nav") || "Reels"}
                    </NavLink>
                  )}
```

In `src/components/moments/MainMoments.tsx` (eager and prerendered — the hook only reads the RTK cache, which the prerender never fills, so the link is never in static HTML):
- `import { useWebFlag } from "../../utils/webFlags";` and add `Film` to the `lucide-react` import;
- body: `const reelsOn = useWebFlag("webReelsEnabled");`
- replace the heading block at `:483-487` with:

```tsx
              <div className="flex items-center justify-between mb-3 sm:mb-4">
                <h1 className="text-xl sm:text-2xl font-bold text-gray-800">
                  Stories list
                </h1>
                {reelsOn && userInfo && (
                  <Link
                    to="/reels"
                    data-testid="moments-reels-link"
                    className="inline-flex items-center gap-1.5 rounded-full bg-gray-900 px-3 py-1.5 text-sm font-bold text-white"
                  >
                    <Film className="h-4 w-4" aria-hidden="true" />
                    {t("reels.moments_link") || "Watch reels"}
                  </Link>
                )}
              </div>
```
(The "Stories list" literal is pre-existing and out of scope.)

Add to `eng.json` under `reels`: `"nav": "Reels"`, `"moments_link": "Watch reels"`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false reelsFlagOff MainNavbar MainMoments routes eagerGraph renderRoute
```
Expected: all pass. `routes.test.tsx` still imports `routes` in plain Node (`FlagRoute`/`SignedInOnly` touch no browser global at import time); `renderRoute` still prerenders `/moments` with one `<h1>` and no reels link; `eagerGraph` stays green (the reels pages are lazy).

- [ ] **Step 5: Commit**

```bash
git add src/components/reels/SignedInOnly.tsx src/components/reels/reelsFlagOff.test.tsx src/router/routes.tsx src/components/navbar/MainNavbar.tsx src/components/navbar/MainNavbar.test.tsx src/components/moments/MainMoments.tsx src/components/moments/MainMoments.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(reels): /reels and /reels/new behind webReelsEnabled

Routes, the navbar entry and the Moments "Watch reels" link exist only
while /app-config has webReelsEnabled and reelsEnabled; otherwise the
paths are the 404 page and nothing links to them (tested with every
flag off). Signed-out visitors are sent to /login.

Still open (Phase 4 reels): i18n of the unit's strings, push; owner
flips WEB_REELS_ENABLED after browser QA.
EOF
```

---

### Task P4-REEL-I18N: The reels unit's new strings in all 18 locales

**Files:**
- Create: `scripts/i18n/keys/2026-10-16-p4-reels.json` (all 18 locales; the durable record of what this unit translated)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: every `reels.*` key P4-REEL-2…7 added to `eng.json` (`reels.policy.*`, `reels.grid.*`, `reels.viewer.*`, `reels.actions.*`, `reels.create.*`, `reels.nav`, `reels.moments_link`) — found by `scripts/i18n/new-keys.js` from the diff against `web/p4-base`, so a key a task forgot to list is still caught. The guard is Phase 3's `src/utils/locales/p3Keys.test.ts`, which P4-0 widened to read `2026-10-16-p4-*.json`.
- Produces: no English-only key in this unit's push.

**Translation rules:** as in P3-CHAT-I18N — keep `{{name}}` and `{{duration}}` verbatim; "BananaTalk" is never translated; "Reels" follows the app's own translation of its Reels tab (`bananatalk_app/lib/l10n/app_<lang>.arb`, keys `reels*`), and `reels.policy.body` reuses the app's `momentsReelPolicyBody` text for that language where it exists (same agreement on both platforms); tone per `docs/l10n/2026-09-23-native-pass-*.md`.

- [ ] **Step 1: Generate the keys file and watch the guard fail**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels
node scripts/i18n/new-keys.js web/p4-base scripts/i18n/keys/2026-10-16-p4-reels.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: the script prints `44 new or changed keys` (± a key a task added beyond its table); the test FAILS with `reels.…: missing` for each of the 17 non-English locales.

- [ ] **Step 2: Translate**

Fill every `""` in `scripts/i18n/keys/2026-10-16-p4-reels.json` for the 17 non-English locales. For `reels.policy.body`, copy the app's `momentsReelPolicyBody` for that language from `bananatalk_app/lib/l10n/app_<code>.arb` (map: `kor`→`ko`, `jpn`→`ja`, `zho`→`zh`, `zh_TW`→`zh_TW`/`zh`, others by ISO code), replacing "Bananatalk" with "BananaTalk". Re-running `new-keys.js` keeps what is already filled.

- [ ] **Step 3: Merge into the locale files**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p4-reels.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: every `p3Keys` case passes, including `2026-10-16-p4-reels.json`; the `src/utils/i18n*.test.ts` suites stay green.

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/keys/2026-10-16-p4-reels.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
i18n(reels): translate the Phase 4 reels strings into all 18 locales

Keys found by scripts/i18n/new-keys.js against web/p4-base and merged
with merge-keys.js; the policy text follows the app's own translation
of the same agreement.

Still open (Phase 4 reels): push gate (P4-REEL-PUSH); native review of
the new strings.
EOF
```

---

### Task P4-REEL-PUSH: Push unit REELS (1 of 5) — full suite + build green, then the coordinator pushes (deploys dark)

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status line, §6 changelog line, §3 production-QA lines for the flag-on checklist below)

- [ ] **Step 1: Every task in the unit is committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-reels
git status --short                                    # expect: nothing (the node_modules symlink is untracked)
grep -n "P4-REEL-" docs/REMAINING_WORK.md | grep -c "\[ \]"   # expect: 1 (this PUSH line only)
git log --oneline web/p4-base..HEAD | wc -l           # expect: 8 (P4-REEL-1..7 and -I18N; the status commit comes in Step 5)
```

- [ ] **Step 2: Rebase onto the live site**

```bash
git fetch origin
git rebase origin/main
```
This is the first Phase 4 push; it also carries the P4-0 base commit. Conflicts: none expected. If `origin/main` moved after `web/p4-base` (a hotfix), conflicts can only be in `src/utils/locales/*.json`, `src/router/routes.tsx`, `src/components/navbar/MainNavbar.tsx` or `docs/REMAINING_WORK.md`: keep both sides. After resolving: `git rebase --continue`, then `CI=true npm test -- --watchAll=false p3Keys`.

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `Test Suites: … 0 failed`, `Tests: … 0 failed`; passed count ≥ the Phase 3 final count + P4-0's 11 tests + this unit's ~55 new tests. Any failure: fix in a new commit (never `--no-verify`, never skip a test to get green).

- [ ] **Step 4: Production build**

```bash
npm run build 2>&1 | tail -20
ls build/static/js | grep -c chunk                                       # more chunks than before (the reels pages are lazy)
grep -c "reel-policy-dialog\|ReelCreatePage" build/static/js/main.*.js   # expect 0: no reels code in the entrypoint
```
Expected: `Compiled successfully` or `Compiled with warnings` (warnings are pre-existing lint), then the prerender step finishes without an error line. `react-scripts build` does **not** type-check in this repo (verified while planning), so a green build says nothing about TS 3.7 compliance: that is held by review of the unit's diff (no `import type`, `satisfies`, template-literal types, labelled tuples). Optional: `npm run test:budget` and note the first-paint size (the flag hook, `FlagRoute` and `SignedInOnly` are the only eager additions).

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P4-REEL-PUSH`; §1 Status: "Phase 4 reels pushed dark (YYYY-MM-DD)"; §6 Done: one line ("Reels on web: feed, viewer, create ≤ 180 s, like/comment/share/report/block — dark behind WEB_REELS_ENABLED"); §3 Production QA: one `- [ ]` line per item of the flag-on checklist in Step 8.

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: Phase 4 reels ready to deploy (dark)

Still open (Phase 4): gatherings, rooms, calls, apple units; reels
flag-on browser QA (docs/REMAINING_WORK.md §3) before the owner sets
WEB_REELS_ENABLED=true.
EOF
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p4-reels:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/            # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1   # a new bundle hash
```

- [ ] **Step 7: Production smoke with the flag still OFF (the only state this push may show)**

  - [ ] `curl -s https://api.banatalk.com/api/v1/app-config | grep -o '"webReelsEnabled":[a-z]*'` → `"webReelsEnabled":false`.
  - [ ] Signed in on banatalk.com: no "Reels" in the navbar (desktop and mobile menu), no "Watch reels" on /moments.
  - [ ] `https://banatalk.com/reels` and `/reels/new` show the 404 page (after the spinner), signed in and signed out.
  - [ ] DevTools → Network on /moments: no request to `/api/v1/moments/reels` or `/video-config`; no reels chunk loaded.
  - [ ] Existing moments feed, a video moment's detail page and the composer behave as before.

  A failure that breaks a live flow → Step 9.

- [ ] **Step 8: Flag-on checklist (recorded in §3; run right after the owner flips `WEB_REELS_ENABLED=true` with two test accounts, ready to flip it back — the flag only hides the web UI, the endpoints are the app's and already live)**

  - [ ] Policy dialog appears once; an account that accepted in the app never sees it on web; declining returns to /moments.
  - [ ] Grid loads, "Load more" pages without duplicates; a 2.6.1 reel without a thumbnail shows its first frame.
  - [ ] Viewer: Chrome and Safari start muted and play; unmute holds for the next reel; Safari with "Never auto-play" shows Tap to play; arrow keys, trackpad wheel and a phone swipe move one reel; Esc and Back close.
  - [ ] Like/unlike counts match the app for the same reel; a comment posted on web appears in the app; share copies `https://banatalk.com/moment/<id>`; report from two accounts hides the reel (auto-hide); block removes the author's reels.
  - [ ] Create: a 2:59 MP4 posts and plays in the iOS and Android app's reels; a 3:10 video is refused before upload; a WebM screen recording whose length the browser can't read is refused by the server with the 3-minute message and leaves no empty moment.

- [ ] **Step 9 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p4-reels-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -15
CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(Keep P4-0's base commit unless it is the cause: GATHERINGS, ROOMS, CALLS and APPLE build on it. Note the revert in §6 and reopen the tasks.)

---

---

## Unit GATHERINGS (push 2 of 5) — P4-GATH-1 … P4-GATH-10, P4-GATH-I18N, P4-GATH-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p4-gatherings`, branch `web/p4-gatherings` (from `web/p4-base`, symlinked
`node_modules`, installs nothing). One implementer, tasks in number order: 1–2 are the data layer and pure helpers,
3–9 the screens (each screen is self-contained and rendered directly in its tests), 10 wires routes and the nav entry
behind the flag and proves nothing is reachable while it is off. Nothing in this unit is reachable from the UI before
task 10, so tasks 1–9 can never leak a half-built screen even if pushed by accident.

Unit-level facts (read once):
- **Backend** (deployed `07febec`): `routes/gatherings.js`, `routes/clubs.js`, `controllers/gatherings.js`,
  `controllers/clubs.js`, `lib/gatheringQuorum.js`, `lib/gatheringFilters.js`, `lib/clubMembers.js`. Both routers sit
  behind `gatheringsEnabledGuard` (global `GATHERINGS_ENABLED`, a 404 while off) and `protect`. The fields the web reads
  are the ones `test/webFeatureContracts.test.js` pins (gathering: `_id, title, language, startsAt, durationMinutes,
  capacity, quorum, going, needed, status, joinMode, host, viewerIsHost, viewerIsAttending`; club: `_id, name,
  description, language, languageLabel, interest, owner, memberCount, members, roleCounts, viewerCanManage,
  viewerIsMember, viewerIsOwner`), plus the extra fields `present()` already sends (`quorumMet`, `topic`, `level`,
  `languageLabel`, `coverImage`, `hostCity`, `hostCountry`, `viewerRequestPending`, `requests` (host only),
  `description`; club detail adds `upcoming`, `pastCount`, `gatherings`, club `city`, `place`, `coverImage`).
- **App reference:** `bananatalk_app/lib/services/gathering_api_client.dart` (exact requests: `startsAt` sent as UTC
  ISO; edit is a partial `PUT` that sends only changed fields; `topic: null` clears; `hasSeat` only sent when on),
  `lib/pages/community/gatherings/{gatherings_tab,gathering_detail_screen,create_gathering_form,club_detail_screen,
  create_club_sheet,club_people_section,gathering_safety_menu,gathering_filter_bar}.dart`.
- **Only online gatherings exist** (`type: 'online_event'`; the backend refuses anything else at
  `controllers/gatherings.js:162-164`). The web never offers a type picker.
- **Times:** `startsAt` is stored UTC; the web shows it in the viewer's zone (`Intl.DateTimeFormat`, the site language)
  and, when the host's zone (`hostTimezone`) differs, adds the host's local time underneath, like the app's
  `lib/utils/gathering_time.dart`. The form uses `<input type="datetime-local">` (local wall time) and sends
  `new Date(value).toISOString()`.
- **Host decision window:** the app shows "run it anyway / call it off" to the host when `!quorumMet` and the start is
  ≤ 120 minutes away (`gathering_detail_screen.dart:386-392`; backend `HOST_DECISION_HOURS = 2`). The web shows it under
  the same condition **and** only while `status === 'scheduled'` (after "run anyway" the status is `confirmed`, so the
  question disappears instead of nagging, which the app still does).
- **Not offered on web (same as the app):** removing an attendee (`DELETE /gatherings/:id/attendees/:userId` exists but
  `present()` exposes no list of who is going, and the app has no caller either — `grep -rn removeParticipant lib`
  finds only the API client). Recorded as a backend follow-up, not built.
- **Reports:** `POST /api/v1/reports` accepts `type: "gathering"` and `type: "club"` (`be/models/Report.js:8`), reasons
  from the model enum (`spam, harassment, hate_speech, violence, nudity, false_information, copyright, other`). The web
  reuses `useReportUserMutation` (`src/store/slices/usersSlice.ts:334`, body `{type, reportId, reportedUser, reason,
  description}`) and `useBlockUserMutation`.
- **Language picker:** `languageOptions(catalog, locale)` from `src/components/community/lib/languageOptions.ts`
  (P3-COM-3) over `useGetLanguagesQuery()` (`communitySlice.ts:256`). Its `value` is the English base name ("Korean"),
  which the backend's `matchKey()` turns into the stored key — the same string the app sends.
- **Styling:** Tailwind utility classes (as `NotFound.tsx` and the Phase 3 dialogs use), logical variants only (`ms-*`,
  `me-*`, `ps-*`, `pe-*`, `text-start`, `start-*`). No new SCSS file.
- Gatherings and clubs are private (signed-in only, `protect`); the routes in task 10 send a signed-out visitor to
  `/login?redirect=<path>` (the `AnnouncementPage.tsx:44` pattern) like the other authenticated pages, and a crawler gets the 404 while the flag is off.

### Task P4-GATH-1: Gatherings + clubs endpoints in one slice, same requests the app sends

**Files:**
- Create: `src/store/slices/gatheringsSlice.ts`
- Modify: `src/constants.ts` (after `PUBLIC_COMMUNITIES_URL`, `:85`): `GATHERINGS_URL`, `CLUBS_URL`
- Modify: `src/store/slices/apiSlice.ts` `tagTypes` (`:149-197`): add `"Gatherings"`, `"Gathering"`, `"Clubs"`, `"Club"` before `"NotificationSettings"`
- Test: `src/store/slices/gatheringsEndpoints.test.ts` (new; mocked-fetch pattern of `publicCommunitiesSlice.endpoints.test.ts`)

**Interfaces:**
- Consumes (all behind `protect`, all `{ success, data }`):
  - `GET /api/v1/gatherings?scope&language&level&topic&when&hasSeat&page&limit` (`be/controllers/gatherings.js:257-325`): `scope` `mine` (default, viewer's languages) | `all` | `me` (hosting or holding a seat/request); `when` `today` | `week` (`lib/gatheringFilters.js:105-118`); `topic` one of `conversation, exam_prep, grammar, pronunciation, culture, media, games, business, travel` (`:24-34`); `hasSeat` only `'true'` counts; `limit` ≤ 50, default 30; sorted soonest first; `data: Gathering[]`, `count`.
  - `GET /api/v1/gatherings/:id` (`:332-356`; 404 for a blocked host, indistinguishable from missing).
  - `POST /api/v1/gatherings` body `{title, language, startsAt, description, level?, durationMinutes, capacity, quorum, joinMode, topic?, club?}` → 201 (`:138-251`).
  - `PUT /api/v1/gatherings/:id` partial body (`:539-645`; `topic: null` clears; `quorum` is **not** editable).
  - `DELETE /api/v1/gatherings/:id` (cancel, host) (`:648-700`).
  - `POST /api/v1/gatherings/:id/rsvp` → `data: {...gathering, pending}` and root `pending` (`:369-478`); `DELETE …/rsvp` (`:481-536`).
  - `POST /api/v1/gatherings/:id/decision` `{run: boolean}` (`:707-746`); `POST …/end` (`:790-870`); `POST …/requests/:userId` `{approve: boolean}` (`:873-930`).
  - `POST|DELETE /api/v1/gatherings/:id/cover` (multipart field `image`) (`routes/gatherings.js:33-35`).
  - `GET /api/v1/clubs?scope&language&interest&page&limit` (`controllers/clubs.js:108-161`): `scope` `mine` | `all` | `member`.
  - `GET /api/v1/clubs/:id` → club + `upcoming`, `pastCount`, `gatherings[]` (`:164-221`).
  - `POST /api/v1/clubs` `{name, description, language, interest}` (`:70-105`); `PUT /api/v1/clubs/:id` `{name?, description?, interest?, city?, place?}` (`:307-353`); `DELETE /api/v1/clubs/:id` (owner) (`:356-381`).
  - `POST|DELETE /api/v1/clubs/:id/join` (`:224-290`).
  - `DELETE /api/v1/clubs/:id/members/:userId` (`:384-425`); `PUT /api/v1/clubs/:id/members/:userId` `{role: 'organizer'|'member'}` → `data: {userId, role}` (`:428-459`).
  - `POST|DELETE /api/v1/clubs/:id/cover` (multipart field `image`).
- Produces: types `Gathering`, `GatheringPerson`, `Club`, `ClubMember`, `GatheringListArgs`, `ClubListArgs`, `GatheringInput`; `GATHERING_TOPICS`, `GATHERING_LEVELS`; hooks `useGetGatheringsQuery`, `useGetGatheringQuery`, `useCreateGatheringMutation`, `useUpdateGatheringMutation`, `useCancelGatheringMutation`, `useRsvpGatheringMutation`, `useCancelRsvpMutation`, `useHostDecisionMutation`, `useEndGatheringMutation`, `useDecideJoinRequestMutation`, `useSetGatheringCoverMutation`, `useRemoveGatheringCoverMutation`, `useGetClubsQuery`, `useGetClubQuery`, `useCreateClubMutation`, `useUpdateClubMutation`, `useDeleteClubMutation`, `useJoinClubMutation`, `useLeaveClubMutation`, `useRemoveClubMemberMutation`, `useSetClubMemberRoleMutation`, `useSetClubCoverMutation`, `useRemoveClubCoverMutation`; pure `gatheringListQuery(args): string`, `gatheringEditBody(before, after): object`.

- [ ] **Step 1: Write the failing test**

Create `src/store/slices/gatheringsEndpoints.test.ts`:

```ts
// Every request the website sends for gatherings and clubs, against the real
// backend routes (be/routes/gatherings.js, be/routes/clubs.js) and in the same
// shape the app's GatheringApiClient sends.
import { makeStore } from "../../store";
import { gatheringsApiSlice, gatheringListQuery, gatheringEditBody } from "./gatheringsSlice";
import { GATHERINGS_URL, CLUBS_URL } from "../../constants";

type Captured = { url: string; method: string; body: string | null; contentType: string | null };

function mockFetch(payload: any = { success: true, data: {} }, status = 200): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    let body: string | null = null;
    if (req.method !== "GET" && req.method !== "HEAD") {
      // A FormData body is not readable as text under the jsdom fetch polyfill.
      try {
        body = await req.clone().text();
      } catch (e) {
        body = "[form-data]";
      }
    }
    calls.push({
      url: req.url,
      method: req.method,
      body,
      contentType: req.headers && req.headers.get ? req.headers.get("content-type") : null,
    });
    return new Response(JSON.stringify(payload), { status, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

const ep = () => (gatheringsApiSlice.endpoints as any);
const run = async (name: string, arg?: any) => {
  const store = makeStore();
  return store.dispatch(ep()[name].initiate(arg));
};
const path = (c: Captured) => new URL(c.url).pathname;
const json = (c: Captured) => JSON.parse(c.body as string);

describe("gatheringListQuery (what the browse page asks for)", () => {
  it("always sends scope and page, like the app", () => {
    expect(gatheringListQuery({})).toBe("scope=mine&page=1");
  });
  it("adds only the filters that are set, and hasSeat only when on", () => {
    expect(
      gatheringListQuery({ scope: "all", page: 2, topic: "grammar", when: "week", hasSeat: true, language: "Korean" })
    ).toBe("scope=all&page=2&language=Korean&topic=grammar&when=week&hasSeat=true");
    expect(gatheringListQuery({ scope: "me", hasSeat: false, topic: "" })).toBe("scope=me&page=1");
  });
});

describe("gatherings", () => {
  it("lists with GET /gatherings?<query> and unwraps data to an array", async () => {
    const calls = mockFetch({ success: true, count: 1, data: [{ _id: "g1" }] });
    const res: any = await run("getGatherings", { scope: "all", page: 1 });
    expect(path(calls[0])).toBe(GATHERINGS_URL);
    expect(new URL(calls[0].url).search).toBe("?scope=all&page=1");
    expect(res.data).toEqual([{ _id: "g1" }]);
  });

  it("an empty or odd envelope is still an array (the page maps over it)", async () => {
    mockFetch({ success: true });
    const res: any = await run("getGatherings", {});
    expect(res.data).toEqual([]);
  });

  it("detail is GET /gatherings/:id, unwrapped", async () => {
    const calls = mockFetch({ success: true, data: { _id: "g1", title: "Coffee" } });
    const res: any = await run("getGathering", "g1");
    expect(path(calls[0])).toBe(`${GATHERINGS_URL}/g1`);
    expect(res.data).toEqual({ _id: "g1", title: "Coffee" });
  });

  it("creates with POST /gatherings and the app's body", async () => {
    const calls = mockFetch();
    await run("createGathering", {
      title: "Korean coffee chat",
      language: "Korean",
      startsAt: "2026-11-01T10:00:00.000Z",
      description: "",
      durationMinutes: 60,
      capacity: 6,
      quorum: 3,
      joinMode: "open",
      topic: "conversation",
      club: "c1",
    });
    expect(calls[0].method).toBe("POST");
    expect(path(calls[0])).toBe(GATHERINGS_URL);
    expect(json(calls[0])).toEqual({
      title: "Korean coffee chat",
      language: "Korean",
      startsAt: "2026-11-01T10:00:00.000Z",
      description: "",
      durationMinutes: 60,
      capacity: 6,
      quorum: 3,
      joinMode: "open",
      topic: "conversation",
      club: "c1",
    });
  });

  it("edits with PUT /gatherings/:id and only the changed fields", async () => {
    const calls = mockFetch();
    await run("updateGathering", { id: "g1", body: { title: "New" } });
    expect(calls[0].method).toBe("PUT");
    expect(path(calls[0])).toBe(`${GATHERINGS_URL}/g1`);
    expect(json(calls[0])).toEqual({ title: "New" });
  });

  it.each([
    ["cancelGathering", "g1", "DELETE", "/g1", null],
    ["rsvpGathering", "g1", "POST", "/g1/rsvp", null],
    ["cancelRsvp", "g1", "DELETE", "/g1/rsvp", null],
    ["hostDecision", { id: "g1", run: false }, "POST", "/g1/decision", { run: false }],
    ["endGathering", "g1", "POST", "/g1/end", null],
    ["decideJoinRequest", { id: "g1", userId: "u9", approve: true }, "POST", "/g1/requests/u9", { approve: true }],
    ["removeGatheringCover", "g1", "DELETE", "/g1/cover", null],
  ])("%s -> %s %s", async (name, arg, method, suffix, body) => {
    const calls = mockFetch();
    await run(name as string, arg);
    expect(calls[0].method).toBe(method);
    expect(path(calls[0])).toBe(`${GATHERINGS_URL}${suffix}`);
    if (body) expect(json(calls[0])).toEqual(body);
  });

  it("rsvp keeps the server's `pending` flag on the result", async () => {
    mockFetch({ success: true, data: { _id: "g1", viewerIsAttending: false, pending: true }, pending: true });
    const res: any = await run("rsvpGathering", "g1");
    expect(res.data).toEqual({ _id: "g1", viewerIsAttending: false, pending: true });
  });

  it("uploads a cover as a FormData body with field `image` (uploadSingleCompressed('image'))", async () => {
    const calls = mockFetch({ success: true, data: { coverImage: "https://cdn/x.jpg" } });
    const append = jest.spyOn(FormData.prototype, "append");
    const file = new File(["x"], "cover.jpg", { type: "image/jpeg" });
    await run("setGatheringCover", { id: "g1", file });
    expect(calls[0].method).toBe("POST");
    expect(path(calls[0])).toBe(`${GATHERINGS_URL}/g1/cover`);
    // fetchBaseQuery only JSON-encodes plain objects; a FormData body keeps
    // the browser's multipart boundary (no JSON content type set).
    expect(calls[0].contentType || "").not.toMatch(/application\/json/);
    expect(append).toHaveBeenCalledWith("image", file);
  });
});

describe("clubs", () => {
  it("lists with scope and page", async () => {
    const calls = mockFetch({ success: true, data: [] });
    await run("getClubs", { scope: "member", page: 1 });
    expect(path(calls[0])).toBe(CLUBS_URL);
    expect(new URL(calls[0].url).search).toBe("?scope=member&page=1");
  });

  it.each([
    ["getClub", "c1", "GET", "/c1", null],
    ["createClub", { name: "Seoul readers", description: "Books", language: "Korean", interest: "books" }, "POST", "", { name: "Seoul readers", description: "Books", language: "Korean", interest: "books" }],
    ["updateClub", { id: "c1", body: { city: "Seoul" } }, "PUT", "/c1", { city: "Seoul" }],
    ["deleteClub", "c1", "DELETE", "/c1", null],
    ["joinClub", "c1", "POST", "/c1/join", null],
    ["leaveClub", "c1", "DELETE", "/c1/join", null],
    ["removeClubMember", { id: "c1", userId: "u2" }, "DELETE", "/c1/members/u2", null],
    ["setClubMemberRole", { id: "c1", userId: "u2", role: "organizer" }, "PUT", "/c1/members/u2", { role: "organizer" }],
    ["removeClubCover", "c1", "DELETE", "/c1/cover", null],
  ])("%s -> %s", async (name, arg, method, suffix, body) => {
    const calls = mockFetch({ success: true, data: name === "getClubs" ? [] : {} });
    await run(name as string, arg);
    expect(calls[0].method).toBe(method);
    expect(path(calls[0])).toBe(`${CLUBS_URL}${suffix}`);
    if (body) expect(json(calls[0])).toEqual(body);
  });
});

describe("gatheringEditBody (partial PUT, like the app)", () => {
  const before: any = {
    title: "A", description: "", language: "korean", languageLabel: "Korean", level: null, topic: null,
    startsAt: "2026-11-01T10:00:00.000Z", durationMinutes: 60, capacity: 6, joinMode: "open",
  };
  it("sends nothing when nothing changed", () => {
    expect(gatheringEditBody(before, { ...before })).toEqual({});
  });
  it("sends only the changed fields, and the label as `language`", () => {
    expect(
      gatheringEditBody(before, { ...before, title: "B", capacity: 8, languageLabel: "Japanese" })
    ).toEqual({ title: "B", capacity: 8, language: "Japanese" });
  });
  it("sends topic: null to clear a topic", () => {
    expect(gatheringEditBody({ ...before, topic: "grammar" }, { ...before, topic: null })).toEqual({ topic: null });
  });
  it("compares start times as instants, not strings", () => {
    expect(gatheringEditBody(before, { ...before, startsAt: "2026-11-01T10:00:00Z" })).toEqual({});
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false gatheringsEndpoints
```
Expected: FAIL — `Cannot find module './gatheringsSlice'`.

- [ ] **Step 3: Implement**

`src/constants.ts`, after `export const PUBLIC_COMMUNITIES_URL = "/api/v1/public/communities";` add:

```ts
// 모임: gatherings and clubs (be/routes/gatherings.js, be/routes/clubs.js).
// Both behind GATHERINGS_ENABLED (404 while off) and, on the website, behind
// the webGatheringsEnabled flag (src/utils/webFlags.ts).
export const GATHERINGS_URL = "/api/v1/gatherings";
export const CLUBS_URL = "/api/v1/clubs";
```

`src/store/slices/apiSlice.ts`, in `tagTypes`, before `"NotificationSettings",` add:

```ts
    // Gatherings and clubs (Phase 4). A list tag and a per-id tag each, so an
    // RSVP refreshes that gathering's page and the list -- not every club.
    "Gatherings",
    "Gathering",
    "Clubs",
    "Club",
```

Create `src/store/slices/gatheringsSlice.ts`:

```ts
import { apiSlice } from "./apiSlice";
import { GATHERINGS_URL, CLUBS_URL } from "../../constants";

/** be/lib/gatheringFilters.js GATHERING_TOPICS, same order. */
export const GATHERING_TOPICS = [
  "conversation",
  "exam_prep",
  "grammar",
  "pronunciation",
  "culture",
  "media",
  "games",
  "business",
  "travel",
];

/** be/models/Gathering.js `level` enum. */
export const GATHERING_LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"];

export interface GatheringPerson {
  _id: string;
  name: string;
  username: string;
  images: string[];
  requestedAt?: string | null;
}

export interface GatheringHost {
  _id: string;
  name?: string;
  username?: string;
  images?: string[];
  imageUrls?: string[];
}

/** be/controllers/gatherings.js present(). Every field optional-safe on read. */
export interface Gathering {
  _id: string;
  title: string;
  description?: string;
  language: string;
  languageLabel?: string;
  level?: string | null;
  topic?: string | null;
  coverImage?: string | null;
  type?: string;
  host?: GatheringHost | string | null;
  hostCity?: string | null;
  hostCountry?: string | null;
  hostTimezone?: string | null;
  startsAt: string;
  durationMinutes: number;
  capacity: number;
  quorum: number;
  joinMode: "open" | "approval";
  status: "scheduled" | "confirmed" | "live" | "ended" | "cancelled";
  going: number;
  needed: number;
  quorumMet?: boolean;
  viewerIsAttending: boolean;
  viewerRequestPending?: boolean;
  viewerIsHost: boolean;
  requests?: GatheringPerson[];
  /** Only on an RSVP response: the RSVP became a request (approval mode). */
  pending?: boolean;
}

export interface ClubMember {
  _id: string;
  name: string;
  username: string;
  images: string[];
  role: "owner" | "organizer" | "member";
  joinedAt?: string | null;
}

/** be/controllers/clubs.js present() (+ detail-only fields). */
export interface Club {
  _id: string;
  name: string;
  description?: string;
  language: string;
  languageLabel?: string;
  interest?: string;
  owner?: GatheringHost | string | null;
  memberCount: number;
  status?: "active" | "archived";
  coverImage?: string | null;
  city?: string | null;
  place?: { name: string | null; address: string | null } | null;
  members: ClubMember[];
  roleCounts?: { owner: number; organizer: number; member: number };
  viewerCanManage: boolean;
  viewerIsMember: boolean;
  viewerIsOwner: boolean;
  upcoming?: number;
  pastCount?: number;
  gatherings?: Gathering[];
}

export interface GatheringListArgs {
  scope?: "mine" | "all" | "me";
  page?: number;
  language?: string;
  topic?: string;
  when?: "" | "today" | "week";
  hasSeat?: boolean;
}

export interface ClubListArgs {
  scope?: "mine" | "all" | "member";
  page?: number;
  language?: string;
}

/** What the create form sends (POST /gatherings). */
export interface GatheringInput {
  title: string;
  language: string;
  startsAt: string;
  description: string;
  level?: string;
  durationMinutes: number;
  capacity: number;
  quorum: number;
  joinMode: "open" | "approval";
  topic?: string;
  club?: string;
}

/**
 * The browse query, in the app's order: scope and page always, everything else
 * only when set, and hasSeat only when true -- the server treats anything but
 * 'true' as off (GatheringApiClient.getGatherings).
 */
export function gatheringListQuery(args: GatheringListArgs): string {
  const p = new URLSearchParams();
  p.set("scope", args.scope || "mine");
  p.set("page", String(args.page || 1));
  if (args.language) p.set("language", args.language);
  if (args.topic) p.set("topic", args.topic);
  if (args.when) p.set("when", args.when);
  if (args.hasSeat) p.set("hasSeat", "true");
  return p.toString();
}

function clubListQuery(args: ClubListArgs): string {
  const p = new URLSearchParams();
  p.set("scope", args.scope || "mine");
  p.set("page", String(args.page || 1));
  if (args.language) p.set("language", args.language);
  return p.toString();
}

/** Editable fields of a gathering as the form holds them. */
export interface GatheringEditable {
  title: string;
  description?: string;
  languageLabel?: string;
  language?: string;
  level?: string | null;
  topic?: string | null;
  startsAt: string;
  durationMinutes: number;
  capacity: number;
  joinMode: "open" | "approval";
}

/**
 * The partial PUT body: only what changed, like the app's updateGathering, so
 * moving the time can never blank the description. `topic: null` is sent on
 * purpose -- it is how a topic is cleared. Quorum is not editable server-side.
 */
export function gatheringEditBody(before: GatheringEditable, after: GatheringEditable): { [k: string]: any } {
  const body: { [k: string]: any } = {};
  const same = (a: any, b: any) => (a === undefined || a === null ? null : a) === (b === undefined || b === null ? null : b);
  if (!same(before.title, after.title)) body.title = after.title;
  if (!same(before.description || "", after.description || "")) body.description = after.description || "";
  const beforeLang = before.languageLabel || before.language;
  const afterLang = after.languageLabel || after.language;
  if (!same(beforeLang, afterLang)) body.language = afterLang;
  if (!same(before.level, after.level)) body.level = after.level || null;
  if (!same(before.topic, after.topic)) body.topic = after.topic || null;
  if (new Date(before.startsAt).getTime() !== new Date(after.startsAt).getTime()) body.startsAt = after.startsAt;
  if (!same(before.durationMinutes, after.durationMinutes)) body.durationMinutes = after.durationMinutes;
  if (!same(before.capacity, after.capacity)) body.capacity = after.capacity;
  if (!same(before.joinMode, after.joinMode)) body.joinMode = after.joinMode;
  return body;
}

const unwrapList = (response: any): any[] => {
  if (Array.isArray(response)) return response;
  const data = response && response.data;
  return Array.isArray(data) ? data : [];
};
const unwrapOne = (response: any): any => (response && response.data) || null;

const coverForm = (file: File) => {
  const form = new FormData();
  form.append("image", file);
  return form;
};

const gatheringTags = (id: string) => [{ type: "Gathering", id }, "Gatherings"];
const clubTags = (id: string) => [{ type: "Club", id }, "Clubs"];

export const gatheringsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // ---- gatherings -------------------------------------------------------
    getGatherings: builder.query({
      query: (args: GatheringListArgs = {}) => ({ url: `${GATHERINGS_URL}?${gatheringListQuery(args)}` }),
      transformResponse: unwrapList,
      providesTags: ["Gatherings"],
      keepUnusedDataFor: 30,
    }),
    getGathering: builder.query({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}` }),
      transformResponse: unwrapOne,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "Gathering", id }],
    }),
    createGathering: builder.mutation({
      query: (body: GatheringInput) => ({ url: GATHERINGS_URL, method: "POST", body }),
      transformResponse: unwrapOne,
      invalidatesTags: ["Gatherings", "Club"],
    }),
    updateGathering: builder.mutation({
      query: ({ id, body }: { id: string; body: { [k: string]: any } }) => ({
        url: `${GATHERINGS_URL}/${id}`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => gatheringTags(a.id),
    }),
    cancelGathering: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}`, method: "DELETE" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),
    rsvpGathering: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}/rsvp`, method: "POST" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),
    cancelRsvp: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}/rsvp`, method: "DELETE" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),
    hostDecision: builder.mutation({
      query: ({ id, run }: { id: string; run: boolean }) => ({
        url: `${GATHERINGS_URL}/${id}/decision`,
        method: "POST",
        body: { run },
      }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => gatheringTags(a.id),
    }),
    endGathering: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}/end`, method: "POST" }),
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),
    decideJoinRequest: builder.mutation({
      query: ({ id, userId, approve }: { id: string; userId: string; approve: boolean }) => ({
        url: `${GATHERINGS_URL}/${id}/requests/${userId}`,
        method: "POST",
        body: { approve },
      }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => gatheringTags(a.id),
    }),
    setGatheringCover: builder.mutation({
      query: ({ id, file }: { id: string; file: File }) => ({
        url: `${GATHERINGS_URL}/${id}/cover`,
        method: "POST",
        body: coverForm(file),
      }),
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => gatheringTags(a.id),
    }),
    removeGatheringCover: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}/cover`, method: "DELETE" }),
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),

    // ---- clubs ------------------------------------------------------------
    getClubs: builder.query({
      query: (args: ClubListArgs = {}) => ({ url: `${CLUBS_URL}?${clubListQuery(args)}` }),
      transformResponse: unwrapList,
      providesTags: ["Clubs"],
      keepUnusedDataFor: 30,
    }),
    getClub: builder.query({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}` }),
      transformResponse: unwrapOne,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "Club", id }, "Club"],
    }),
    createClub: builder.mutation({
      query: (body: { name: string; description: string; language: string; interest: string }) => ({
        url: CLUBS_URL,
        method: "POST",
        body,
      }),
      transformResponse: unwrapOne,
      invalidatesTags: ["Clubs"],
    }),
    updateClub: builder.mutation({
      query: ({ id, body }: { id: string; body: { [k: string]: any } }) => ({
        url: `${CLUBS_URL}/${id}`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => clubTags(a.id),
    }),
    deleteClub: builder.mutation({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}`, method: "DELETE" }),
      invalidatesTags: (_r: any, _e: any, id: string) => clubTags(id),
    }),
    joinClub: builder.mutation({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}/join`, method: "POST" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => clubTags(id),
    }),
    leaveClub: builder.mutation({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}/join`, method: "DELETE" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => clubTags(id),
    }),
    removeClubMember: builder.mutation({
      query: ({ id, userId }: { id: string; userId: string }) => ({
        url: `${CLUBS_URL}/${id}/members/${userId}`,
        method: "DELETE",
      }),
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => clubTags(a.id),
    }),
    setClubMemberRole: builder.mutation({
      query: ({ id, userId, role }: { id: string; userId: string; role: "organizer" | "member" }) => ({
        url: `${CLUBS_URL}/${id}/members/${userId}`,
        method: "PUT",
        body: { role },
      }),
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => clubTags(a.id),
    }),
    setClubCover: builder.mutation({
      query: ({ id, file }: { id: string; file: File }) => ({
        url: `${CLUBS_URL}/${id}/cover`,
        method: "POST",
        body: coverForm(file),
      }),
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => clubTags(a.id),
    }),
    removeClubCover: builder.mutation({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}/cover`, method: "DELETE" }),
      invalidatesTags: (_r: any, _e: any, id: string) => clubTags(id),
    }),
  }),
});

export const {
  useGetGatheringsQuery,
  useGetGatheringQuery,
  useCreateGatheringMutation,
  useUpdateGatheringMutation,
  useCancelGatheringMutation,
  useRsvpGatheringMutation,
  useCancelRsvpMutation,
  useHostDecisionMutation,
  useEndGatheringMutation,
  useDecideJoinRequestMutation,
  useSetGatheringCoverMutation,
  useRemoveGatheringCoverMutation,
  useGetClubsQuery,
  useGetClubQuery,
  useCreateClubMutation,
  useUpdateClubMutation,
  useDeleteClubMutation,
  useJoinClubMutation,
  useLeaveClubMutation,
  useRemoveClubMemberMutation,
  useSetClubMemberRoleMutation,
  useSetClubCoverMutation,
  useRemoveClubCoverMutation,
} = gatheringsApiSlice as any;
```

(`baseQueryWithReauth` in `apiSlice.ts` already sets the bearer token and leaves `FormData` bodies alone, as the moment photo upload relies on — `momentsSlice.ts` `uploadMomentPhotos`.)

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false gatheringsEndpoints apiSlice
```
Expected: all `gatheringsEndpoints` cases pass; `apiSlice.test.ts` stays green.

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/gatheringsSlice.ts src/store/slices/gatheringsEndpoints.test.ts src/constants.ts src/store/slices/apiSlice.ts docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(gatherings): gatherings and clubs endpoints, same requests as the app

One RTK slice for every gathering/club route the app's
GatheringApiClient uses: list with the app's query order, partial PUT
edits (topic null clears), RSVP keeping the pending flag, host
decisions, join requests, covers as multipart `image`, club
membership and roles. Not reachable from the UI yet.

Still open (Phase 4 gatherings): helpers, screens, routes behind
webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-2: Shared helpers: local start time, quorum line, host-decision window, error text

**Files:**
- Create: `src/components/gatherings/lib/gatheringFormat.ts`
- Modify: `src/utils/locales/eng.json` (`gatherings.time.*`, `gatherings.quorum.*`, `gatherings.errors.*`, `gatherings.topics.*`, `gatherings.status.*`)
- Test: `src/components/gatherings/lib/gatheringFormat.test.ts` (new)

**Interfaces:**
- Consumes: `Gathering` (P4-GATH-1). Backend error strings (exact text, `be/controllers/gatherings.js` and `clubs.js`): `"This gathering is full"`, `"You are already going"`, `"This gathering was cancelled"`, `"This gathering has ended"`, `"This gathering has already started"`, `"Your request is waiting for the host to approve it"`, `"Cancel the gathering instead of leaving it"`, `"A gathering must start in the future"`, `"Capacity cannot be lower than the N already going"`, `"You have cancelled or missed too many of your own gatherings to host a new one"` (403), `"Join the club before hosting for it"` (403), `"A gathering cannot end before it starts"`, `"The owner cannot leave their own club"`, `"That club is archived"` / `"This club is archived"`, `"Gathering not found"` / `"Club not found"` (404 — also what a blocked host's gathering returns).
- Produces (all pure, named exports): `formatGatheringTime(iso, lang, timeZone?)`, `hostLocalTime(g, lang, viewerZone?) : string | null`, `minutesUntil(iso, now)`, `isHostDecisionDue(g, now)`, `seatsLeft(g)`, `quorumLine(g, t)`, `statusLabel(status, t)`, `topicLabel(topic, t)`, `toLocalInputValue(iso)`, `fromLocalInputValue(value)`, `gatheringErrorText(err, t)`, `personId(p)`, `personName(p)`, `rsvpState(g): "host" | "going" | "pending" | "full" | "closed" | "join" | "request"`.

- [ ] **Step 1: Write the failing test**

Create `src/components/gatherings/lib/gatheringFormat.test.ts`:

```ts
import {
  formatGatheringTime,
  hostLocalTime,
  minutesUntil,
  isHostDecisionDue,
  seatsLeft,
  quorumLine,
  toLocalInputValue,
  fromLocalInputValue,
  gatheringErrorText,
  personId,
  personName,
  rsvpState,
  topicLabel,
} from "./gatheringFormat";

const t: any = () => "";
const NOW = new Date("2026-11-01T08:00:00.000Z");
const base: any = {
  _id: "g1",
  title: "Coffee",
  language: "korean",
  startsAt: "2026-11-01T10:00:00.000Z",
  durationMinutes: 60,
  capacity: 6,
  quorum: 3,
  joinMode: "open",
  status: "scheduled",
  going: 1,
  needed: 2,
  quorumMet: false,
  viewerIsAttending: false,
  viewerIsHost: false,
};

describe("time", () => {
  it("formats in the given zone and language", () => {
    expect(formatGatheringTime("2026-11-01T10:00:00.000Z", "en", "UTC")).toMatch(/10:00/);
    expect(formatGatheringTime("2026-11-01T10:00:00.000Z", "en", "Asia/Seoul")).toMatch(/7:00/);
  });
  it("never throws on a bad date or zone", () => {
    expect(formatGatheringTime("not a date", "en")).toBe("");
    expect(formatGatheringTime("2026-11-01T10:00:00.000Z", "en", "Not/AZone")).not.toBe("");
  });
  it("adds the host's local time only when their zone differs", () => {
    expect(hostLocalTime({ ...base, hostTimezone: "Asia/Seoul" }, "en", "UTC")).toMatch(/7:00/);
    expect(hostLocalTime({ ...base, hostTimezone: "UTC" }, "en", "UTC")).toBe(null);
    expect(hostLocalTime({ ...base, hostTimezone: null }, "en", "UTC")).toBe(null);
    expect(hostLocalTime({ ...base, hostTimezone: "Bogus/Zone" }, "en", "UTC")).toBe(null);
  });
  it("round-trips datetime-local values through the viewer's zone", () => {
    const iso = fromLocalInputValue("2026-11-01T19:30");
    expect(toLocalInputValue(iso)).toBe("2026-11-01T19:30");
    expect(fromLocalInputValue("")).toBe("");
    expect(toLocalInputValue("garbage")).toBe("");
  });
  it("counts minutes to the start (negative once started)", () => {
    expect(minutesUntil(base.startsAt, NOW)).toBe(120);
    expect(minutesUntil(base.startsAt, new Date("2026-11-01T10:30:00.000Z"))).toBe(-30);
  });
});

describe("host decision window (app: !quorumMet && <= 120 min; web also needs status scheduled)", () => {
  const host = { ...base, viewerIsHost: true };
  it("is due for the host inside two hours with quorum unmet", () => {
    expect(isHostDecisionDue(host, NOW)).toBe(true);
  });
  it("is not due earlier, for a guest, once met, or after a decision", () => {
    expect(isHostDecisionDue(host, new Date("2026-11-01T07:59:00.000Z"))).toBe(false);
    expect(isHostDecisionDue(base, NOW)).toBe(false);
    expect(isHostDecisionDue({ ...host, quorumMet: true }, NOW)).toBe(false);
    expect(isHostDecisionDue({ ...host, status: "confirmed" }, NOW)).toBe(false);
    expect(isHostDecisionDue({ ...host, status: "cancelled" }, NOW)).toBe(false);
  });
  it("treats a missing quorumMet as needed === 0 (older payloads)", () => {
    expect(isHostDecisionDue({ ...host, quorumMet: undefined, needed: 0 }, NOW)).toBe(false);
  });
});

describe("quorum and seats", () => {
  it("seats left never goes negative", () => {
    expect(seatsLeft(base)).toBe(5);
    expect(seatsLeft({ ...base, going: 9 })).toBe(0);
  });
  it("says how many more are needed, or that it is confirmed", () => {
    expect(quorumLine(base, t)).toBe("2 more needed to confirm · 1 going");
    expect(quorumLine({ ...base, going: 3, needed: 0, quorumMet: true, status: "confirmed" }, t)).toBe(
      "Confirmed · 3 going"
    );
    expect(quorumLine({ ...base, status: "cancelled" }, t)).toBe("Cancelled");
    expect(quorumLine({ ...base, status: "ended" }, t)).toBe("Ended");
  });
  it("labels topics, unknown ones as-is", () => {
    expect(topicLabel("exam_prep", t)).toBe("Exam prep");
    expect(topicLabel("weird", t)).toBe("weird");
    expect(topicLabel(null, t)).toBe("");
  });
});

describe("rsvpState", () => {
  it("covers every button state the page can show", () => {
    expect(rsvpState({ ...base, viewerIsHost: true })).toBe("host");
    expect(rsvpState({ ...base, viewerIsAttending: true })).toBe("going");
    expect(rsvpState({ ...base, viewerRequestPending: true })).toBe("pending");
    expect(rsvpState({ ...base, going: 6 })).toBe("full");
    expect(rsvpState({ ...base, status: "cancelled" })).toBe("closed");
    expect(rsvpState({ ...base, status: "ended" })).toBe("closed");
    expect(rsvpState(base)).toBe("join");
    expect(rsvpState({ ...base, joinMode: "approval" })).toBe("request");
  });
});

describe("people", () => {
  it("reads populated and bare-id hosts", () => {
    expect(personId({ _id: "u1", name: "Ada" })).toBe("u1");
    expect(personId("u2")).toBe("u2");
    expect(personId(null)).toBe("");
    expect(personName({ _id: "u1", name: "", username: "ada" })).toBe("@ada");
    expect(personName("u2")).toBe("");
  });
});

describe("gatheringErrorText", () => {
  const err = (status: number, error: string) => ({ status, data: { success: false, error } });
  it("maps the backend's known refusals to friendly text", () => {
    expect(gatheringErrorText(err(400, "This gathering is full"), t)).toBe("This gathering is full.");
    expect(gatheringErrorText(err(400, "Your request is waiting for the host to approve it"), t)).toBe(
      "Your request is waiting for the host."
    );
    expect(
      gatheringErrorText(err(403, "You have cancelled or missed too many of your own gatherings to host a new one"), t)
    ).toBe("You can't host right now: too many of your gatherings were cancelled or missed.");
    expect(gatheringErrorText(err(400, "Capacity cannot be lower than the 4 already going"), t)).toBe(
      "Capacity can't be lower than the 4 people already going."
    );
    expect(gatheringErrorText(err(404, "Gathering not found"), t)).toBe("This gathering isn't available.");
    expect(gatheringErrorText(err(404, "Club not found"), t)).toBe("This club isn't available.");
  });
  it("falls back to a generic line, never raw server text", () => {
    expect(gatheringErrorText(err(400, "Something internal"), t)).toBe("Something went wrong. Try again.");
    expect(gatheringErrorText(undefined, t)).toBe("Something went wrong. Try again.");
    expect(gatheringErrorText({ status: "FETCH_ERROR" }, t)).toBe("You're offline. Check your connection.");
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false gatheringFormat
```
Expected: FAIL — `Cannot find module './gatheringFormat'`.

- [ ] **Step 3: Implement**

Create `src/components/gatherings/lib/gatheringFormat.ts`:

```ts
import { Gathering } from "../../../store/slices/gatheringsSlice";

type T = (key: string, opts?: any) => string;

const validZone = (zone?: string | null): string | undefined => {
  if (!zone) return undefined;
  try {
    new Intl.DateTimeFormat("en", { timeZone: zone });
    return zone;
  } catch (e) {
    return undefined;
  }
};

/** "Sun, Nov 1, 7:00 PM" in the viewer's language (and a zone, for tests and the host line). */
export function formatGatheringTime(iso: string, lang: string, timeZone?: string | null): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const opts: Intl.DateTimeFormatOptions = {
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  };
  const zone = validZone(timeZone);
  if (zone) opts.timeZone = zone;
  try {
    return new Intl.DateTimeFormat(lang || "en", opts).format(d);
  } catch (e) {
    return new Intl.DateTimeFormat("en", opts).format(d);
  }
}

/** The viewer's own zone; injectable for tests. */
export function viewerZone(): string | undefined {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  } catch (e) {
    return undefined;
  }
}

/**
 * The start time in the host's zone, only when it differs from the viewer's
 * (lib/utils/gathering_time.dart does the same): "7:00 PM for the host".
 */
export function hostLocalTime(g: Gathering, lang: string, viewer?: string | null): string | null {
  const hostZone = validZone(g.hostTimezone);
  if (!hostZone) return null;
  const mine = validZone(viewer === undefined ? viewerZone() : viewer);
  if (mine && formatGatheringTime(g.startsAt, "en", mine) === formatGatheringTime(g.startsAt, "en", hostZone)) {
    return null;
  }
  return formatGatheringTime(g.startsAt, lang, hostZone);
}

export function minutesUntil(iso: string, now: Date): number {
  return Math.round((new Date(iso).getTime() - now.getTime()) / 60000);
}

/**
 * The host's "run it anyway / call it off" question. The app asks when quorum
 * is unmet and the start is <= 120 minutes away (backend HOST_DECISION_HOURS);
 * the web also requires `scheduled`, so the question goes away once answered.
 */
export function isHostDecisionDue(g: Gathering, now: Date): boolean {
  if (!g.viewerIsHost || g.status !== "scheduled") return false;
  const met = g.quorumMet !== undefined ? g.quorumMet : g.needed === 0;
  if (met) return false;
  return minutesUntil(g.startsAt, now) <= 120;
}

export function seatsLeft(g: Gathering): number {
  return Math.max(0, (g.capacity || 0) - (g.going || 0));
}

export function statusLabel(status: string, t: T): string {
  switch (status) {
    case "cancelled":
      return t("gatherings.status.cancelled") || "Cancelled";
    case "ended":
      return t("gatherings.status.ended") || "Ended";
    case "live":
      return t("gatherings.status.live") || "Happening now";
    case "confirmed":
      return t("gatherings.status.confirmed") || "Confirmed";
    default:
      return t("gatherings.status.scheduled") || "Scheduled";
  }
}

export function quorumLine(g: Gathering, t: T): string {
  if (g.status === "cancelled" || g.status === "ended") return statusLabel(g.status, t);
  const going = g.going || 0;
  const met = g.quorumMet !== undefined ? g.quorumMet : g.needed === 0;
  if (met || g.status === "confirmed") {
    return t("gatherings.quorum.confirmed", { count: going }) || `Confirmed · ${going} going`;
  }
  return (
    t("gatherings.quorum.needed", { count: g.needed, going }) ||
    `${g.needed} more needed to confirm · ${going} going`
  );
}

const TOPIC_FALLBACK: { [k: string]: string } = {
  conversation: "Conversation",
  exam_prep: "Exam prep",
  grammar: "Grammar",
  pronunciation: "Pronunciation",
  culture: "Culture",
  media: "Music, film & TV",
  games: "Games",
  business: "Business",
  travel: "Travel",
};

export function topicLabel(topic: string | null | undefined, t: T): string {
  if (!topic) return "";
  const fallback = TOPIC_FALLBACK[topic];
  if (!fallback) return topic;
  return t(`gatherings.topics.${topic}`) || fallback;
}

const pad = (n: number) => (n < 10 ? `0${n}` : String(n));

/** ISO -> the `YYYY-MM-DDTHH:mm` a datetime-local input shows, in the viewer's zone. */
export function toLocalInputValue(iso: string): string {
  const d = new Date(iso);
  if (!iso || Number.isNaN(d.getTime())) return "";
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** datetime-local value (viewer's wall time) -> UTC ISO, as the app sends `startsAt`. */
export function fromLocalInputValue(value: string): string {
  if (!value) return "";
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? "" : d.toISOString();
}

export function personId(p: any): string {
  if (!p) return "";
  if (typeof p === "string") return p;
  return p._id ? String(p._id) : "";
}

export function personName(p: any): string {
  if (!p || typeof p === "string") return "";
  if (p.name) return p.name;
  return p.username ? `@${p.username}` : "";
}

export type RsvpState = "host" | "going" | "pending" | "full" | "closed" | "join" | "request";

export function rsvpState(g: Gathering): RsvpState {
  if (g.viewerIsHost) return "host";
  if (g.status === "cancelled" || g.status === "ended") return "closed";
  if (g.viewerIsAttending) return "going";
  if (g.viewerRequestPending || g.pending) return "pending";
  if (seatsLeft(g) === 0) return "full";
  return g.joinMode === "approval" ? "request" : "join";
}

/** Backend refusal -> a sentence for a toast or an inline error. Never raw server text. */
export function gatheringErrorText(err: any, t: T): string {
  if (err && err.status === "FETCH_ERROR") {
    return t("gatherings.errors.offline") || "You're offline. Check your connection.";
  }
  const raw: string = (err && err.data && (err.data.error || err.data.message)) || "";
  const capacity = raw.match(/^Capacity cannot be lower than the (\d+) already going/);
  if (capacity) {
    const count = Number(capacity[1]);
    return t("gatherings.errors.capacityBelowGoing", { count }) || `Capacity can't be lower than the ${count} people already going.`;
  }
  const known: { [k: string]: [string, string] } = {
    "This gathering is full": ["full", "This gathering is full."],
    "You are already going": ["alreadyGoing", "You're already going."],
    "This gathering was cancelled": ["cancelled", "This gathering was cancelled."],
    "This gathering has ended": ["ended", "This gathering has ended."],
    "This gathering has already started": ["started", "This gathering has already started."],
    "Your request is waiting for the host to approve it": ["pending", "Your request is waiting for the host."],
    "Cancel the gathering instead of leaving it": ["hostCannotLeave", "As the host, cancel the gathering instead of leaving it."],
    "A gathering must start in the future": ["pastStart", "Pick a start time in the future."],
    "You have cancelled or missed too many of your own gatherings to host a new one": [
      "hostBlocked",
      "You can't host right now: too many of your gatherings were cancelled or missed.",
    ],
    "Join the club before hosting for it": ["joinClubFirst", "Join the club before hosting for it."],
    "A gathering cannot end before it starts": ["endBeforeStart", "You can end the gathering once it has started."],
    "The owner cannot leave their own club": ["ownerCannotLeave", "As the owner, you can delete the club but not leave it."],
    "That club is archived": ["clubArchived", "This club is archived."],
    "This club is archived": ["clubArchived", "This club is archived."],
    "Gathering not found": ["gatheringGone", "This gathering isn't available."],
    "Club not found": ["clubGone", "This club isn't available."],
  };
  const hit = known[raw];
  if (hit) return t(`gatherings.errors.${hit[0]}`) || hit[1];
  return t("gatherings.errors.generic") || "Something went wrong. Try again.";
}
```

Add to `src/utils/locales/eng.json` a top-level `"gatherings"` object (merge with later tasks' keys; keep alphabetical inside):

```json
"gatherings": {
  "errors": {
    "alreadyGoing": "You're already going.",
    "cancelled": "This gathering was cancelled.",
    "capacityBelowGoing": "Capacity can't be lower than the {{count}} people already going.",
    "clubArchived": "This club is archived.",
    "clubGone": "This club isn't available.",
    "endBeforeStart": "You can end the gathering once it has started.",
    "ended": "This gathering has ended.",
    "full": "This gathering is full.",
    "gatheringGone": "This gathering isn't available.",
    "generic": "Something went wrong. Try again.",
    "hostBlocked": "You can't host right now: too many of your gatherings were cancelled or missed.",
    "hostCannotLeave": "As the host, cancel the gathering instead of leaving it.",
    "joinClubFirst": "Join the club before hosting for it.",
    "offline": "You're offline. Check your connection.",
    "ownerCannotLeave": "As the owner, you can delete the club but not leave it.",
    "pastStart": "Pick a start time in the future.",
    "pending": "Your request is waiting for the host.",
    "started": "This gathering has already started."
  },
  "quorum": {
    "confirmed": "Confirmed · {{count}} going",
    "needed": "{{count}} more needed to confirm · {{going}} going"
  },
  "status": {
    "cancelled": "Cancelled",
    "confirmed": "Confirmed",
    "ended": "Ended",
    "live": "Happening now",
    "scheduled": "Scheduled"
  },
  "time": {
    "hostLocal": "{{time}} for the host"
  },
  "topics": {
    "business": "Business",
    "conversation": "Conversation",
    "culture": "Culture",
    "exam_prep": "Exam prep",
    "games": "Games",
    "grammar": "Grammar",
    "media": "Music, film & TV",
    "pronunciation": "Pronunciation",
    "travel": "Travel"
  }
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false gatheringFormat i18n
```
Expected: all pass (Node's ICU in Jest has full zone data; `Asia/Seoul` resolves).

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/lib/gatheringFormat.ts src/components/gatherings/lib/gatheringFormat.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(gatherings): time, quorum, host-decision and error helpers

Start times in the viewer's zone with the host's local time when it
differs; "N more needed to confirm" / "Confirmed"; the app's T-2h host
decision window (web hides it once answered); RSVP button state; the
backend's refusals mapped to friendly text, never raw server strings.

Still open (Phase 4 gatherings): screens, routes behind
webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-3: Browse page: Gatherings and Clubs tabs, the app's filters, load more

**Files:**
- Create: `src/components/gatherings/GatheringsHome.tsx`, `src/components/gatherings/GatheringCard.tsx`, `src/components/gatherings/ClubCard.tsx`
- Modify: `src/utils/locales/eng.json` (`gatherings.home.*`, `clubs.card.*`)
- Test: `src/components/gatherings/GatheringsHome.test.tsx` (new)

**Interfaces:**
- Consumes: `useGetGatheringsQuery(GatheringListArgs)`, `useGetClubsQuery(ClubListArgs)` (P4-GATH-1); helpers from P4-GATH-2; `useGetLanguagesQuery` (`src/store/slices/communitySlice.ts:256`) + `languageOptions(catalog, locale)` (`src/components/community/lib/languageOptions.ts`, P3-COM-3); `photoUrl` (`src/utils/photoUrl.ts`). App reference: `gatherings_tab.dart` (two inner tabs, Gatherings and Clubs), `gathering_filter_bar.dart` (topic, when, has-seat), scopes `mine` (default: my languages) / `all` / `me`; clubs `mine` / `all` / `member`. Page size: the server default 30 (`controllers/gatherings.js:315`), so "Load more" shows while the last page came back full.
- Produces: default export `GatheringsHome` (props `{ initialTab?: "gatherings" | "clubs" }`; the tab is mirrored in `?tab=clubs`). `GatheringCard` props `{ gathering: Gathering }` (testid `gathering-card-<id>`, a `Link` to `/gatherings/<id>`). `ClubCard` props `{ club: Club }` (testid `club-card-<id>`, `Link` to `/clubs/<id>`). Testids: `gatherings-tab`, `clubs-tab`, `gatherings-scope-<scope>`, `clubs-scope-<scope>`, `gatherings-filter-topic`, `gatherings-filter-when`, `gatherings-filter-seat`, `gatherings-filter-language`, `gatherings-load-more`, `gatherings-empty`, `clubs-empty`, `gatherings-error`, `host-gathering-link`, `start-club-link`.

- [ ] **Step 1: Write the failing test**

Create `src/components/gatherings/GatheringsHome.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import GatheringsHome from "./GatheringsHome";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mockGatherings = jest.fn();
const mockClubs = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useGetGatheringsQuery: (args: any) => mockGatherings(args),
  useGetClubsQuery: (args: any) => mockClubs(args),
}));
jest.mock("../../store/slices/communitySlice", () => ({
  useGetLanguagesQuery: () => ({ data: { data: [{ code: "ko", name: "Korean" }] } }),
}));
jest.mock("../community/lib/languageOptions", () => ({
  languageOptions: () => [
    { value: "Korean", label: "Korean" },
    { value: "Japanese", label: "Japanese" },
  ],
}));

const gathering = (id: string, extra: any = {}) => ({
  _id: id,
  title: `Gathering ${id}`,
  language: "korean",
  languageLabel: "Korean",
  startsAt: "2030-11-01T10:00:00.000Z",
  durationMinutes: 60,
  capacity: 6,
  quorum: 3,
  joinMode: "open",
  status: "scheduled",
  going: 1,
  needed: 2,
  quorumMet: false,
  viewerIsAttending: false,
  viewerIsHost: false,
  host: { _id: "h1", name: "Hana", images: [] },
  ...extra,
});
const club = (id: string, extra: any = {}) => ({
  _id: id,
  name: `Club ${id}`,
  language: "korean",
  languageLabel: "Korean",
  memberCount: 12,
  members: [{ _id: "u1", name: "Ada", username: "ada", images: [], role: "owner" }],
  viewerCanManage: false,
  viewerIsMember: false,
  viewerIsOwner: false,
  ...extra,
});
const ok = (data: any[]) => ({ data, isLoading: false, isFetching: false, isError: false, refetch: jest.fn() });

function Where() {
  const l = useLocation();
  return <div data-testid="where">{l.pathname + l.search}</div>;
}
function renderHome(path = "/gatherings") {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/gatherings" element={<><GatheringsHome /><Where /></>} />
        <Route path="/clubs" element={<><GatheringsHome initialTab="clubs" /><Where /></>} />
      </Routes>
    </MemoryRouter>
  );
}

beforeEach(() => {
  mockGatherings.mockReset();
  mockClubs.mockReset();
  mockGatherings.mockReturnValue(ok([gathering("g1"), gathering("g2", { viewerIsAttending: true })]));
  mockClubs.mockReturnValue(ok([club("c1")]));
});

it("asks for 'my languages', page 1, like the app's default", () => {
  renderHome();
  expect(mockGatherings).toHaveBeenLastCalledWith({ scope: "mine", page: 1, topic: "", when: "", hasSeat: false, language: "" });
  expect(screen.getByTestId("gathering-card-g1")).toHaveAttribute("href", "/gatherings/g1");
  expect(screen.getByTestId("gathering-card-g1")).toHaveTextContent("2 more needed to confirm · 1 going");
  expect(screen.getByTestId("gathering-card-g2")).toHaveTextContent("Going");
});

it("filters by scope, topic, time window, free seats and language", () => {
  renderHome();
  fireEvent.click(screen.getByTestId("gatherings-scope-all"));
  fireEvent.change(screen.getByTestId("gatherings-filter-topic"), { target: { value: "grammar" } });
  fireEvent.change(screen.getByTestId("gatherings-filter-when"), { target: { value: "week" } });
  fireEvent.click(screen.getByTestId("gatherings-filter-seat"));
  fireEvent.change(screen.getByTestId("gatherings-filter-language"), { target: { value: "Japanese" } });
  expect(mockGatherings).toHaveBeenLastCalledWith({
    scope: "all",
    page: 1,
    topic: "grammar",
    when: "week",
    hasSeat: true,
    language: "Japanese",
  });
});

it("loads the next page while the last one came back full, and appends it", async () => {
  const page1 = Array.from({ length: 30 }, (_, i) => gathering(`a${i}`));
  mockGatherings.mockImplementation((args: any) => (args.page === 1 ? ok(page1) : ok([gathering("b1")])));
  renderHome();
  fireEvent.click(screen.getByTestId("gatherings-load-more"));
  await waitFor(() => expect(screen.getByTestId("gathering-card-b1")).toBeInTheDocument());
  expect(screen.getByTestId("gathering-card-a0")).toBeInTheDocument();
  expect(screen.queryByTestId("gatherings-load-more")).not.toBeInTheDocument();
});

it("hides Load more after a short page", () => {
  renderHome();
  expect(screen.queryByTestId("gatherings-load-more")).not.toBeInTheDocument();
});

it("shows an empty state that offers hosting", () => {
  mockGatherings.mockReturnValue(ok([]));
  renderHome();
  expect(screen.getByTestId("gatherings-empty")).toBeInTheDocument();
  expect(screen.getAllByTestId("host-gathering-link")[0]).toHaveAttribute("href", "/gatherings/new");
});

it("shows a retry on error", () => {
  const refetch = jest.fn();
  mockGatherings.mockReturnValue({ data: undefined, isLoading: false, isFetching: false, isError: true, refetch });
  renderHome();
  fireEvent.click(screen.getByTestId("gatherings-error").querySelector("button") as HTMLButtonElement);
  expect(refetch).toHaveBeenCalled();
});

it("switches to clubs, mirrors it in the URL, and filters clubs by scope", () => {
  renderHome();
  fireEvent.click(screen.getByTestId("clubs-tab"));
  expect(screen.getByTestId("where")).toHaveTextContent("/gatherings?tab=clubs");
  expect(screen.getByTestId("club-card-c1")).toHaveAttribute("href", "/clubs/c1");
  expect(screen.getByTestId("club-card-c1")).toHaveTextContent("12 members");
  fireEvent.click(screen.getByTestId("clubs-scope-member"));
  expect(mockClubs).toHaveBeenLastCalledWith({ scope: "member", page: 1 });
  expect(screen.getByTestId("start-club-link")).toHaveAttribute("href", "/clubs/new");
});

it("opens on the clubs tab from /clubs", () => {
  renderHome("/clubs");
  expect(screen.getByTestId("club-card-c1")).toBeInTheDocument();
  expect(screen.queryByTestId("gathering-card-g1")).not.toBeInTheDocument();
});

```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false GatheringsHome
```
Expected: FAIL — `Cannot find module './GatheringsHome'`.

- [ ] **Step 3: Implement**

Create `src/components/gatherings/GatheringCard.tsx`:

```tsx
import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Gathering } from "../../store/slices/gatheringsSlice";
import { formatGatheringTime, quorumLine, seatsLeft, topicLabel, personName, rsvpState } from "./lib/gatheringFormat";

const GatheringCard: React.FC<{ gathering: Gathering }> = ({ gathering: g }) => {
  const { t, i18n } = useTranslation();
  const state = rsvpState(g);
  const seats = seatsLeft(g);
  const host = personName(g.host);
  return (
    <Link
      to={`/gatherings/${g._id}`}
      data-testid={`gathering-card-${g._id}`}
      className="block rounded-2xl border border-gray-200 bg-white p-4 text-start no-underline shadow-sm hover:shadow dark:border-gray-700 dark:bg-gray-900"
    >
      {g.coverImage && (
        <img src={g.coverImage} alt="" className="mb-3 h-32 w-full rounded-xl object-cover" loading="lazy" />
      )}
      <div className="flex items-center gap-2 text-xs font-bold text-brand-dark dark:text-brand-light">
        <span>{formatGatheringTime(g.startsAt, i18n.language)}</span>
        <span aria-hidden>·</span>
        <span>{g.languageLabel || g.language}</span>
        {g.topic && (
          <>
            <span aria-hidden>·</span>
            <span>{topicLabel(g.topic, t)}</span>
          </>
        )}
      </div>
      <h3 className="mt-1 text-base font-extrabold text-gray-900 dark:text-gray-50">{g.title}</h3>
      {host && (
        <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
          {t("gatherings.card.hostedBy", { name: host }) || `Hosted by ${host}`}
        </p>
      )}
      <p className="mt-2 text-sm font-semibold text-gray-800 dark:text-gray-100">{quorumLine(g, t)}</p>
      <div className="mt-2 flex flex-wrap gap-2 text-xs">
        {state === "going" && (
          <span className="rounded-full bg-brand px-2 py-0.5 font-bold text-white">
            {t("gatherings.card.going") || "Going"}
          </span>
        )}
        {state === "pending" && (
          <span className="rounded-full bg-amber-100 px-2 py-0.5 font-bold text-amber-800">
            {t("gatherings.card.requested") || "Requested"}
          </span>
        )}
        {state === "host" && (
          <span className="rounded-full bg-gray-900 px-2 py-0.5 font-bold text-white">
            {t("gatherings.card.hosting") || "You're hosting"}
          </span>
        )}
        {state !== "closed" && (
          <span className="rounded-full bg-gray-100 px-2 py-0.5 text-gray-700 dark:bg-gray-800 dark:text-gray-200">
            {seats === 0
              ? t("gatherings.card.full") || "Full"
              : t("gatherings.card.seatsLeft", { count: seats }) || `${seats} seats left`}
          </span>
        )}
        {g.joinMode === "approval" && (
          <span className="rounded-full bg-gray-100 px-2 py-0.5 text-gray-700 dark:bg-gray-800 dark:text-gray-200">
            {t("gatherings.card.approval") || "Host approves"}
          </span>
        )}
      </div>
    </Link>
  );
};

export default GatheringCard;
```

Create `src/components/gatherings/ClubCard.tsx`:

```tsx
import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Club } from "../../store/slices/gatheringsSlice";
import { photoUrl } from "../../utils/photoUrl";

const ClubCard: React.FC<{ club: Club }> = ({ club: c }) => {
  const { t } = useTranslation();
  const count = c.memberCount || 0;
  return (
    <Link
      to={`/clubs/${c._id}`}
      data-testid={`club-card-${c._id}`}
      className="block rounded-2xl border border-gray-200 bg-white p-4 text-start no-underline shadow-sm hover:shadow dark:border-gray-700 dark:bg-gray-900"
    >
      {c.coverImage && (
        <img src={c.coverImage} alt="" className="mb-3 h-28 w-full rounded-xl object-cover" loading="lazy" />
      )}
      <h3 className="text-base font-extrabold text-gray-900 dark:text-gray-50">{c.name}</h3>
      <p className="mt-1 text-xs font-bold text-brand-dark dark:text-brand-light">
        {c.languageLabel || c.language}
        {c.interest ? ` · ${c.interest}` : ""}
      </p>
      <div className="mt-2 flex items-center gap-2">
        <div className="flex -space-x-2 rtl:space-x-reverse">
          {(c.members || []).slice(0, 4).map((m) => {
            const src = photoUrl(m.images);
            return src ? (
              <img key={m._id} src={src} alt="" className="h-6 w-6 rounded-full border-2 border-white object-cover" />
            ) : (
              <span key={m._id} className="h-6 w-6 rounded-full border-2 border-white bg-gray-200" />
            );
          })}
        </div>
        <span className="text-sm text-gray-700 dark:text-gray-200">
          {t("clubs.card.members", { count }) || `${count} members`}
        </span>
        {c.viewerIsMember && (
          <span className="ms-auto rounded-full bg-brand px-2 py-0.5 text-xs font-bold text-white">
            {t("clubs.card.joined") || "Joined"}
          </span>
        )}
      </div>
    </Link>
  );
};

export default ClubCard;
```

Create `src/components/gatherings/GatheringsHome.tsx`:

```tsx
import React, { useEffect, useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetGatheringsQuery,
  useGetClubsQuery,
  GATHERING_TOPICS,
  Gathering,
  Club,
} from "../../store/slices/gatheringsSlice";
import { useGetLanguagesQuery } from "../../store/slices/communitySlice";
import { languageOptions } from "../community/lib/languageOptions";
import GatheringCard from "./GatheringCard";
import ClubCard from "./ClubCard";
import { topicLabel } from "./lib/gatheringFormat";
import Loader from "../Loader";

const PAGE_SIZE = 30; // the server's default `limit` (controllers/gatherings.js)

type Tab = "gatherings" | "clubs";
type GScope = "mine" | "all" | "me";
type CScope = "mine" | "all" | "member";

const chip = (active: boolean) =>
  `rounded-full px-3 py-1 text-sm font-bold ${
    active ? "bg-brand text-white" : "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-200"
  }`;

/** Accumulates pages of one list; resets whenever `key` (the filters) changes. */
function usePaged<T extends { _id: string }>(key: string, page: number, data: T[] | undefined): T[] {
  const [items, setItems] = useState<T[]>([]);
  useEffect(() => {
    setItems([]);
  }, [key]);
  useEffect(() => {
    if (!data) return;
    setItems((prev) => {
      if (page === 1) return data;
      const seen = new Set(prev.map((x) => x._id));
      return prev.concat(data.filter((x) => !seen.has(x._id)));
    });
  }, [data, page]);
  return items;
}

const GatheringsHome: React.FC<{ initialTab?: Tab }> = ({ initialTab }) => {
  const { t, i18n } = useTranslation();
  const [params, setParams] = useSearchParams();
  const tab: Tab = params.get("tab") === "clubs" || (!params.get("tab") && initialTab === "clubs") ? "clubs" : "gatherings";
  const setTab = (next: Tab) => {
    const p = new URLSearchParams(params);
    if (next === "clubs") p.set("tab", "clubs");
    else p.delete("tab");
    setParams(p, { replace: true });
  };

  // ---- gatherings filters
  const [scope, setScope] = useState<GScope>("mine");
  const [topic, setTopic] = useState("");
  const [when, setWhen] = useState<"" | "today" | "week">("");
  const [hasSeat, setHasSeat] = useState(false);
  const [language, setLanguage] = useState("");
  const [page, setPage] = useState(1);
  const filterKey = [scope, topic, when, hasSeat, language].join("|");
  useEffect(() => setPage(1), [filterKey]);

  const gq = useGetGatheringsQuery(
    { scope, page, topic, when, hasSeat, language },
    { skip: tab !== "gatherings" }
  );
  const gatherings = usePaged<Gathering>(filterKey, page, gq.data);

  // ---- clubs filters
  const [clubScope, setClubScope] = useState<CScope>("mine");
  const [clubPage, setClubPage] = useState(1);
  useEffect(() => setClubPage(1), [clubScope]);
  const cq = useGetClubsQuery({ scope: clubScope, page: clubPage }, { skip: tab !== "clubs" });
  const clubs = usePaged<Club>(clubScope, clubPage, cq.data);

  const { data: catalog } = useGetLanguagesQuery();
  const langs = useMemo(
    () => languageOptions((catalog && catalog.data) || [], i18n.language),
    [catalog, i18n.language]
  );

  const active = tab === "gatherings" ? gq : cq;
  const lastPageFull = Array.isArray(active.data) && active.data.length >= PAGE_SIZE;

  return (
    <section className="mx-auto max-w-3xl px-4 py-6" data-testid="gatherings-home">
      <div className="flex items-center gap-3">
        <h1 className="text-2xl font-extrabold text-gray-900 dark:text-gray-50">
          {t("gatherings.home.title") || "Gatherings"}
        </h1>
        <div className="ms-auto">
          {tab === "gatherings" ? (
            <Link to="/gatherings/new" data-testid="host-gathering-link" className="rounded-full bg-brand px-4 py-2 text-sm font-extrabold text-white no-underline">
              {t("gatherings.home.host") || "Host a gathering"}
            </Link>
          ) : (
            <Link to="/clubs/new" data-testid="start-club-link" className="rounded-full bg-brand px-4 py-2 text-sm font-extrabold text-white no-underline">
              {t("clubs.home.start") || "Start a club"}
            </Link>
          )}
        </div>
      </div>

      <div role="tablist" className="mt-4 flex gap-2 border-b border-gray-200 dark:border-gray-700">
        <button
          type="button"
          role="tab"
          aria-selected={tab === "gatherings"}
          data-testid="gatherings-tab"
          className={`px-3 py-2 text-sm font-extrabold ${tab === "gatherings" ? "border-b-2 border-brand text-brand-dark" : "text-gray-500"}`}
          onClick={() => setTab("gatherings")}
        >
          {t("gatherings.home.tabGatherings") || "Gatherings"}
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={tab === "clubs"}
          data-testid="clubs-tab"
          className={`px-3 py-2 text-sm font-extrabold ${tab === "clubs" ? "border-b-2 border-brand text-brand-dark" : "text-gray-500"}`}
          onClick={() => setTab("clubs")}
        >
          {t("gatherings.home.tabClubs") || "Clubs"}
        </button>
      </div>

      {tab === "gatherings" ? (
        <>
          <div className="mt-4 flex flex-wrap gap-2">
            {(["mine", "all", "me"] as GScope[]).map((s) => (
              <button key={s} type="button" data-testid={`gatherings-scope-${s}`} className={chip(scope === s)} onClick={() => setScope(s)}>
                {s === "mine"
                  ? t("gatherings.home.scopeMine") || "My languages"
                  : s === "all"
                  ? t("gatherings.home.scopeAll") || "All"
                  : t("gatherings.home.scopeMe") || "My gatherings"}
              </button>
            ))}
          </div>
          <div className="mt-3 flex flex-wrap items-center gap-2 text-sm">
            <select
              data-testid="gatherings-filter-topic"
              aria-label={t("gatherings.home.topic") || "Topic"}
              value={topic}
              onChange={(e) => setTopic(e.target.value)}
              className="rounded-lg border border-gray-300 px-2 py-1 dark:border-gray-600 dark:bg-gray-900"
            >
              <option value="">{t("gatherings.home.anyTopic") || "Any topic"}</option>
              {GATHERING_TOPICS.map((k) => (
                <option key={k} value={k}>
                  {topicLabel(k, t)}
                </option>
              ))}
            </select>
            <select
              data-testid="gatherings-filter-when"
              aria-label={t("gatherings.home.when") || "When"}
              value={when}
              onChange={(e) => setWhen(e.target.value as any)}
              className="rounded-lg border border-gray-300 px-2 py-1 dark:border-gray-600 dark:bg-gray-900"
            >
              <option value="">{t("gatherings.home.anyTime") || "Any time"}</option>
              <option value="today">{t("gatherings.home.today") || "Today"}</option>
              <option value="week">{t("gatherings.home.week") || "This week"}</option>
            </select>
            <select
              data-testid="gatherings-filter-language"
              aria-label={t("gatherings.home.language") || "Language"}
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className="rounded-lg border border-gray-300 px-2 py-1 dark:border-gray-600 dark:bg-gray-900"
            >
              <option value="">{t("gatherings.home.anyLanguage") || "My languages"}</option>
              {langs.map((o: { value: string; label: string }) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
            <label className="flex items-center gap-1">
              <input type="checkbox" data-testid="gatherings-filter-seat" checked={hasSeat} onChange={() => setHasSeat(!hasSeat)} />
              {t("gatherings.home.hasSeat") || "Has a free seat"}
            </label>
          </div>
        </>
      ) : (
        <div className="mt-4 flex flex-wrap gap-2">
          {(["mine", "all", "member"] as CScope[]).map((s) => (
            <button key={s} type="button" data-testid={`clubs-scope-${s}`} className={chip(clubScope === s)} onClick={() => setClubScope(s)}>
              {s === "mine"
                ? t("clubs.home.scopeMine") || "My languages"
                : s === "all"
                ? t("clubs.home.scopeAll") || "All"
                : t("clubs.home.scopeMember") || "Joined"}
            </button>
          ))}
        </div>
      )}

      <div className="mt-4 grid gap-3">
        {active.isError && (
          <div data-testid="gatherings-error" className="rounded-xl bg-red-50 p-4 text-sm text-red-800">
            {t("gatherings.home.error") || "Couldn't load this list."}{" "}
            <button type="button" className="font-bold underline" onClick={() => active.refetch()}>
              {t("gatherings.home.retry") || "Try again"}
            </button>
          </div>
        )}
        {active.isLoading && <Loader />}

        {tab === "gatherings" &&
          gatherings.map((g) => <GatheringCard key={g._id} gathering={g} />)}
        {tab === "clubs" && clubs.map((c) => <ClubCard key={c._id} club={c} />)}

        {tab === "gatherings" && !gq.isLoading && !gq.isError && gq.data && gatherings.length === 0 && (
          <div data-testid="gatherings-empty" className="rounded-2xl bg-gray-50 p-6 text-center dark:bg-gray-800">
            <p className="font-bold">{t("gatherings.home.empty") || "Nothing scheduled here yet."}</p>
            <Link to="/gatherings/new" data-testid="host-gathering-link" className="mt-3 inline-block font-extrabold text-brand-dark">
              {t("gatherings.home.emptyCta") || "Host the first one"}
            </Link>
          </div>
        )}
        {tab === "clubs" && !cq.isLoading && !cq.isError && cq.data && clubs.length === 0 && (
          <div data-testid="clubs-empty" className="rounded-2xl bg-gray-50 p-6 text-center dark:bg-gray-800">
            <p className="font-bold">{t("clubs.home.empty") || "No clubs here yet."}</p>
          </div>
        )}

        {lastPageFull && !active.isFetching && (
          <button
            type="button"
            data-testid="gatherings-load-more"
            className="rounded-full border-2 border-brand px-4 py-2 text-sm font-extrabold text-brand-dark"
            onClick={() => (tab === "gatherings" ? setPage(page + 1) : setClubPage(clubPage + 1))}
          >
            {t("gatherings.home.loadMore") || "Load more"}
          </button>
        )}
      </div>
    </section>
  );
};

export default GatheringsHome;
```

Add to `eng.json` (merge into `gatherings` and a new top-level `clubs`):

```json
"gatherings": {
  "card": {
    "approval": "Host approves",
    "full": "Full",
    "going": "Going",
    "hostedBy": "Hosted by {{name}}",
    "hosting": "You're hosting",
    "requested": "Requested",
    "seatsLeft_one": "{{count}} seat left",
    "seatsLeft_other": "{{count}} seats left"
  },
  "home": {
    "anyLanguage": "My languages",
    "anyTime": "Any time",
    "anyTopic": "Any topic",
    "empty": "Nothing scheduled here yet.",
    "emptyCta": "Host the first one",
    "error": "Couldn't load this list.",
    "hasSeat": "Has a free seat",
    "host": "Host a gathering",
    "language": "Language",
    "loadMore": "Load more",
    "retry": "Try again",
    "scopeAll": "All",
    "scopeMe": "My gatherings",
    "scopeMine": "My languages",
    "tabClubs": "Clubs",
    "tabGatherings": "Gatherings",
    "title": "Gatherings",
    "today": "Today",
    "topic": "Topic",
    "week": "This week",
    "when": "When"
  }
},
"clubs": {
  "card": {
    "joined": "Joined",
    "members_one": "{{count}} member",
    "members_other": "{{count}} members"
  },
  "home": {
    "empty": "No clubs here yet.",
    "scopeAll": "All",
    "scopeMember": "Joined",
    "scopeMine": "My languages",
    "start": "Start a club"
  }
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false GatheringsHome
```
Expected: 8 passed.

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/GatheringsHome.tsx src/components/gatherings/GatheringCard.tsx src/components/gatherings/ClubCard.tsx src/components/gatherings/GatheringsHome.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(gatherings): browse page with Gatherings and Clubs tabs

The app's scopes (my languages / all / mine; clubs: joined), topic,
time window, free-seat and language filters, quorum line and seats on
every card, load more while a page comes back full, empty and error
states. Not routed yet.

Still open (Phase 4 gatherings): detail, host forms and decisions,
clubs, covers, routes behind webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-4: Gathering page: details, RSVP / request / leave, report or block the host

**Files:**
- Create: `src/components/gatherings/GatheringDetail.tsx`, `src/components/gatherings/GatheringSafetyMenu.tsx`, `src/components/gatherings/ConfirmDialog.tsx`
- Modify: `src/utils/locales/eng.json` (`gatherings.detail.*`, `gatherings.safety.*`, `gatherings.confirm.*`)
- Test: `src/components/gatherings/GatheringDetail.test.tsx`, `src/components/gatherings/GatheringSafetyMenu.test.tsx` (new)

**Interfaces:**
- Consumes: `useGetGatheringQuery(id)`, `useRsvpGatheringMutation`, `useCancelRsvpMutation` (P4-GATH-1); `rsvpState`, `quorumLine`, `formatGatheringTime`, `hostLocalTime`, `topicLabel`, `gatheringErrorText`, `personId`, `personName` (P4-GATH-2). RSVP: open mode → `going` (may flip `scheduled → confirmed`); approval mode → request, response `data.pending === true` (`controllers/gatherings.js:396,472-477`). Leaving and cancelling a request are the same call, `DELETE …/rsvp` (it removes any attendee row of the viewer, `:494-500`). The host gets 400 "Cancel the gathering instead of leaving it", so the page never offers Leave to the host. Report: `useReportUserMutation({type: "gathering", reportId, reportedUser: hostId, reason, description})`, reasons `REPORT_REASONS` from `src/components/moments/actions/ReportMomentDialog.tsx` (labels under `moments_section.report.reasons.*`, already in 18 locales). Block: `BlockAuthorDialog` (`src/components/moments/actions/BlockAuthorDialog.tsx`, P3-MOM-5: props `{authorId, authorName?, onClose, onBlocked?}`); after a block the host's gatherings 404 for this viewer (`:350-353`), so `onBlocked` navigates to `/gatherings`.
- Produces: default export `GatheringDetail` (reads `:id`; for the host an "Edit" link here, and P4-GATH-6 adds `<GatheringHostPanel>` below it). `GatheringSafetyMenu` props `{ type: "gathering" | "club"; targetId: string; ownerId: string; ownerName?: string; onBlocked(): void }` (renders nothing when `ownerId` is the viewer; testids `safety-menu-button`, `safety-report`, `safety-block`, `safety-report-dialog`, `safety-report-reason-<value>`, `safety-report-submit`). `ConfirmDialog` props `{ title: string; body?: string; confirmLabel: string; danger?: boolean; busy?: boolean; onConfirm(): void; onCancel(): void }` (testids `confirm-dialog`, `confirm-ok`, `confirm-cancel`). Testids on the page: `gathering-detail`, `gathering-unavailable`, `gathering-time`, `gathering-host-time`, `gathering-quorum`, `gathering-rsvp`, `gathering-leave`, `gathering-cancel-request`, `gathering-full`, `gathering-closed`, `gathering-edit-link`, `gathering-host-link`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/gatherings/GatheringSafetyMenu.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import GatheringSafetyMenu from "./GatheringSafetyMenu";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockSuccess = jest.fn();
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: (m: any) => mockSuccess(m), error: (m: any) => mockError(m) },
}));
const mockReport = jest.fn();
jest.mock("../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [mockReport, { isLoading: false }],
}));
jest.mock("../moments/actions/BlockAuthorDialog", () => (props: any) => (
  <div data-testid="block-dialog">
    <button data-testid="block-confirm" onClick={() => props.onBlocked && props.onBlocked()} />
  </div>
));

function renderMenu(props: any = {}, me = "viewer") {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: me } } }) => s } });
  const onBlocked = jest.fn();
  render(
    <Provider store={store}>
      <GatheringSafetyMenu type="gathering" targetId="g1" ownerId="host1" ownerName="Hana" onBlocked={onBlocked} {...props} />
    </Provider>
  );
  return { onBlocked };
}

beforeEach(() => {
  mockReport.mockReset();
  mockReport.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
});

it("renders nothing for the owner", () => {
  renderMenu({}, "host1");
  expect(screen.queryByTestId("safety-menu-button")).not.toBeInTheDocument();
});

it("reports the gathering with type 'gathering' and the host as reportedUser", async () => {
  renderMenu();
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-report"));
  fireEvent.click(screen.getByTestId("safety-report-reason-spam"));
  fireEvent.click(screen.getByTestId("safety-report-submit"));
  await waitFor(() =>
    expect(mockReport).toHaveBeenCalledWith({
      type: "gathering",
      reportId: "g1",
      reportedUser: "host1",
      reason: "spam",
      description: "",
    })
  );
  await waitFor(() => expect(screen.queryByTestId("safety-report-dialog")).not.toBeInTheDocument());
  expect(mockSuccess).toHaveBeenCalled();
});

it("reports a club with type 'club'", async () => {
  renderMenu({ type: "club", targetId: "c1", ownerId: "o1" });
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-report"));
  fireEvent.click(screen.getByTestId("safety-report-reason-harassment"));
  fireEvent.click(screen.getByTestId("safety-report-submit"));
  await waitFor(() => expect(mockReport.mock.calls[0][0]).toEqual(expect.objectContaining({ type: "club", reportId: "c1", reportedUser: "o1" })));
});

it("cannot send a report without a reason", () => {
  renderMenu();
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-report"));
  expect(screen.getByTestId("safety-report-submit")).toBeDisabled();
});

it("says so when the report failed and keeps the dialog open", async () => {
  mockReport.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
  renderMenu();
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-report"));
  fireEvent.click(screen.getByTestId("safety-report-reason-other"));
  fireEvent.click(screen.getByTestId("safety-report-submit"));
  await waitFor(() => expect(mockError).toHaveBeenCalled());
  expect(screen.getByTestId("safety-report-dialog")).toBeInTheDocument();
});

it("blocks the host through the shared block dialog", () => {
  const { onBlocked } = renderMenu();
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-block"));
  fireEvent.click(screen.getByTestId("block-confirm"));
  expect(onBlocked).toHaveBeenCalled();
});
```

Create `src/components/gatherings/GatheringDetail.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import GatheringDetail from "./GatheringDetail";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockSuccess = jest.fn();
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: (m: any) => mockSuccess(m), error: (m: any) => mockError(m) },
}));

let mockQuery: any;
const mockRsvp = jest.fn();
const mockLeave = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useGetGatheringQuery: () => mockQuery,
  useRsvpGatheringMutation: () => [mockRsvp, { isLoading: false }],
  useCancelRsvpMutation: () => [mockLeave, { isLoading: false }],
}));
jest.mock("./GatheringSafetyMenu", () => () => <div data-testid="safety-menu" />);

const gathering = (extra: any = {}) => ({
  _id: "g1",
  title: "Korean coffee chat",
  description: "Bring a topic",
  language: "korean",
  languageLabel: "Korean",
  level: "B1",
  topic: "conversation",
  startsAt: "2030-11-01T10:00:00.000Z",
  durationMinutes: 60,
  hostTimezone: "Asia/Seoul",
  capacity: 6,
  quorum: 3,
  joinMode: "open",
  status: "scheduled",
  going: 1,
  needed: 2,
  quorumMet: false,
  viewerIsAttending: false,
  viewerIsHost: false,
  host: { _id: "h1", name: "Hana", images: [] },
  ...extra,
});

function renderDetail() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/gatherings/g1"]}>
        <Routes>
          <Route path="/gatherings/:id" element={<GatheringDetail />} />
          <Route path="/gatherings" element={<div data-testid="list-page" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}
const ok = (data: any) => ({ data, isLoading: false, isError: false, error: undefined, refetch: jest.fn() });

beforeEach(() => {
  mockRsvp.mockReset();
  mockLeave.mockReset();
  mockSuccess.mockReset();
  mockError.mockReset();
  mockQuery = ok(gathering());
});

it("shows the gathering with its time, the host's local time, quorum and host", () => {
  // Pin the viewer to UTC so the Seoul host's time always differs, whatever
  // zone the test machine runs in.
  const zone = jest
    .spyOn(Intl.DateTimeFormat.prototype, "resolvedOptions")
    .mockReturnValue({ timeZone: "UTC" } as any);
  renderDetail();
  expect(screen.getByTestId("gathering-detail")).toHaveTextContent("Korean coffee chat");
  expect(screen.getByTestId("gathering-time")).not.toBeEmptyDOMElement();
  expect(screen.getByTestId("gathering-host-time")).toHaveTextContent("for the host");
  expect(screen.getByTestId("gathering-quorum")).toHaveTextContent("2 more needed to confirm · 1 going");
  expect(screen.getByTestId("gathering-host-link")).toHaveAttribute("href", "/profile/h1");
  expect(screen.getByTestId("safety-menu")).toBeInTheDocument();
  zone.mockRestore();
});

it("RSVPs in open mode and confirms it", async () => {
  mockRsvp.mockReturnValue({ unwrap: () => Promise.resolve({ ...gathering(), viewerIsAttending: true, pending: false }) });
  renderDetail();
  fireEvent.click(screen.getByTestId("gathering-rsvp"));
  await waitFor(() => expect(mockRsvp).toHaveBeenCalledWith("g1"));
  await waitFor(() => expect(mockSuccess).toHaveBeenCalledWith("You're going."));
});

it("sends a request in approval mode and says it is waiting", async () => {
  mockQuery = ok(gathering({ joinMode: "approval" }));
  mockRsvp.mockReturnValue({ unwrap: () => Promise.resolve({ ...gathering(), pending: true }) });
  renderDetail();
  expect(screen.getByTestId("gathering-rsvp")).toHaveTextContent("Ask to join");
  fireEvent.click(screen.getByTestId("gathering-rsvp"));
  await waitFor(() => expect(mockSuccess).toHaveBeenCalledWith("Request sent. The host will decide."));
});

it("leaves after confirming", async () => {
  mockQuery = ok(gathering({ viewerIsAttending: true, going: 2, needed: 1 }));
  mockLeave.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  renderDetail();
  fireEvent.click(screen.getByTestId("gathering-leave"));
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockLeave).toHaveBeenCalledWith("g1"));
});

it("cancels a pending request with the same call", async () => {
  mockQuery = ok(gathering({ joinMode: "approval", viewerRequestPending: true }));
  mockLeave.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  renderDetail();
  fireEvent.click(screen.getByTestId("gathering-cancel-request"));
  await waitFor(() => expect(mockLeave).toHaveBeenCalledWith("g1"));
});

it("shows Full and Closed instead of a button", () => {
  mockQuery = ok(gathering({ going: 6, needed: 0, quorumMet: true }));
  const { unmount } = renderDetail();
  expect(screen.getByTestId("gathering-full")).toBeInTheDocument();
  expect(screen.queryByTestId("gathering-rsvp")).not.toBeInTheDocument();
  unmount();
  mockQuery = ok(gathering({ status: "cancelled" }));
  renderDetail();
  expect(screen.getByTestId("gathering-closed")).toHaveTextContent("Cancelled");
});

it("never offers Leave to the host; shows Edit instead", () => {
  mockQuery = ok(gathering({ viewerIsHost: true, viewerIsAttending: true }));
  renderDetail();
  expect(screen.queryByTestId("gathering-leave")).not.toBeInTheDocument();
  expect(screen.getByTestId("gathering-edit-link")).toHaveAttribute("href", "/gatherings/g1/edit");
});

it("maps a refusal to friendly text", async () => {
  mockRsvp.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { error: "This gathering is full" } }) });
  renderDetail();
  fireEvent.click(screen.getByTestId("gathering-rsvp"));
  await waitFor(() => expect(mockError).toHaveBeenCalledWith("This gathering is full."));
});

it("a missing or blocked gathering is 'not available', not a crash", () => {
  mockQuery = { data: undefined, isLoading: false, isError: true, error: { status: 404, data: { error: "Gathering not found" } }, refetch: jest.fn() };
  renderDetail();
  expect(screen.getByTestId("gathering-unavailable")).toHaveTextContent("This gathering isn't available.");
});

it("tolerates a legacy payload with an unpopulated host and no topic/level", () => {
  mockQuery = ok(gathering({ host: "h1", topic: null, level: null, hostTimezone: null, quorumMet: undefined }));
  renderDetail();
  expect(screen.getByTestId("gathering-detail")).toBeInTheDocument();
  expect(screen.queryByTestId("gathering-host-time")).not.toBeInTheDocument();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false GatheringDetail GatheringSafetyMenu
```
Expected: FAIL — `Cannot find module './GatheringDetail'` / `'./GatheringSafetyMenu'`.

- [ ] **Step 3: Implement**

Create `src/components/gatherings/ConfirmDialog.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import DialogShell from "../../design/DialogShell";

export interface ConfirmDialogProps {
  title: string;
  body?: string;
  confirmLabel: string;
  danger?: boolean;
  busy?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmDialog: React.FC<ConfirmDialogProps> = ({ title, body, confirmLabel, danger, busy, onConfirm, onCancel }) => {
  const { t } = useTranslation();
  return (
    <DialogShell labelledBy="confirm-dialog-title" onClose={onCancel} testId="confirm-dialog" dismissible={!busy}>
      <h2 id="confirm-dialog-title" className="text-lg font-extrabold text-gray-900 dark:text-gray-50">
        {title}
      </h2>
      {body && <p className="mt-2 text-sm text-gray-600 dark:text-gray-300">{body}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <button type="button" data-testid="confirm-cancel" disabled={busy} onClick={onCancel} className="rounded-full px-4 py-2 text-sm font-bold">
          {t("gatherings.confirm.cancel") || "Not now"}
        </button>
        <button
          type="button"
          data-testid="confirm-ok"
          disabled={busy}
          onClick={onConfirm}
          className={`rounded-full px-4 py-2 text-sm font-extrabold text-white ${danger ? "bg-red-600" : "bg-brand"}`}
        >
          {confirmLabel}
        </button>
      </div>
    </DialogShell>
  );
};

export default ConfirmDialog;
```

Create `src/components/gatherings/GatheringSafetyMenu.tsx`:

```tsx
import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import DialogShell from "../../design/DialogShell";
import notify from "../../design/notify";
import { useReportUserMutation } from "../../store/slices/usersSlice";
import { REPORT_REASONS } from "../moments/actions/ReportMomentDialog";
import BlockAuthorDialog from "../moments/actions/BlockAuthorDialog";

export interface GatheringSafetyMenuProps {
  type: "gathering" | "club";
  targetId: string;
  ownerId: string;
  ownerName?: string;
  onBlocked: () => void;
}

const REASON_FALLBACK: { [k: string]: string } = {
  spam: "Spam",
  harassment: "Harassment",
  hate_speech: "Hate speech",
  violence: "Violence",
  nudity: "Nudity",
  false_information: "False information",
  copyright: "Copyright",
  other: "Something else",
};

/**
 * Report-or-block for a gathering or a club, like the app's
 * gathering_safety_menu.dart. The backend has always accepted `gathering` and
 * `club` reports (models/Report.js); the reported user is the host/owner.
 */
const GatheringSafetyMenu: React.FC<GatheringSafetyMenuProps> = ({ type, targetId, ownerId, ownerName, onBlocked }) => {
  const { t } = useTranslation();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id);
  const [open, setOpen] = useState(false);
  const [dialog, setDialog] = useState<"" | "report" | "block">("");
  const [reason, setReason] = useState("");
  const [description, setDescription] = useState("");
  const [busy, setBusy] = useState(false);
  const [report] = useReportUserMutation();

  if (!ownerId || String(ownerId) === String(me)) return null;

  const send = async () => {
    if (!reason) return;
    setBusy(true);
    try {
      await report({ type, reportId: targetId, reportedUser: ownerId, reason, description: description.trim() }).unwrap();
      notify.success(t("gatherings.safety.reported") || "Thanks — our moderators will review it.");
      setDialog("");
      setReason("");
      setDescription("");
    } catch (e) {
      notify.error(t("gatherings.safety.reportFailed") || "Couldn't send the report. Try again.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="relative">
      <button
        type="button"
        data-testid="safety-menu-button"
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label={t("gatherings.safety.more") || "More"}
        className="rounded-full px-3 py-1 text-xl leading-none text-gray-600"
        onClick={() => setOpen(!open)}
      >
        ⋯
      </button>
      {open && (
        <div role="menu" className="absolute end-0 z-10 mt-1 w-48 rounded-xl border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-900">
          <button type="button" role="menuitem" data-testid="safety-report" className="block w-full px-4 py-2 text-start text-sm"
            onClick={() => { setOpen(false); setDialog("report"); }}>
            {type === "club" ? t("gatherings.safety.reportClub") || "Report club" : t("gatherings.safety.reportGathering") || "Report gathering"}
          </button>
          <button type="button" role="menuitem" data-testid="safety-block" className="block w-full px-4 py-2 text-start text-sm text-red-700"
            onClick={() => { setOpen(false); setDialog("block"); }}>
            {type === "club" ? t("gatherings.safety.blockOwner") || "Block the owner" : t("gatherings.safety.blockHost") || "Block the host"}
          </button>
        </div>
      )}

      {dialog === "report" && (
        <DialogShell labelledBy="safety-report-title" onClose={() => setDialog("")} testId="safety-report-dialog" dismissible={!busy}>
          <h2 id="safety-report-title" className="text-lg font-extrabold">
            {type === "club" ? t("gatherings.safety.reportClub") || "Report club" : t("gatherings.safety.reportGathering") || "Report gathering"}
          </h2>
          <fieldset className="mt-3 grid gap-1">
            <legend className="text-sm font-bold">{t("moments_section.report.reasonLabel") || "Why are you reporting it?"}</legend>
            {REPORT_REASONS.map((value) => (
              <label key={value} className="flex items-center gap-2 text-sm">
                <input type="radio" name="gathering-report-reason" data-testid={`safety-report-reason-${value}`} checked={reason === value} onChange={() => setReason(value)} />
                <span>{t(`moments_section.report.reasons.${value}`) || REASON_FALLBACK[value] || value}</span>
              </label>
            ))}
          </fieldset>
          <textarea
            className="mt-3 w-full rounded-lg border border-gray-300 p-2 text-sm"
            maxLength={500}
            value={description}
            placeholder={t("moments_section.report.descriptionLabel") || "Anything else? (optional)"}
            onChange={(e) => setDescription(e.target.value)}
          />
          <div className="mt-4 flex justify-end gap-2">
            <button type="button" disabled={busy} onClick={() => setDialog("")} className="rounded-full px-4 py-2 text-sm font-bold">
              {t("moments_section.report.cancel") || "Cancel"}
            </button>
            <button type="button" data-testid="safety-report-submit" disabled={!reason || busy} onClick={send}
              className="rounded-full bg-red-600 px-4 py-2 text-sm font-extrabold text-white disabled:opacity-50">
              {t("moments_section.report.submit") || "Send report"}
            </button>
          </div>
        </DialogShell>
      )}

      {dialog === "block" && (
        <BlockAuthorDialog authorId={ownerId} authorName={ownerName} onClose={() => setDialog("")} onBlocked={onBlocked} />
      )}
    </div>
  );
};

export default GatheringSafetyMenu;
```

Create `src/components/gatherings/GatheringDetail.tsx`:

```tsx
import React, { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import Loader from "../Loader";
import { useGetGatheringQuery, useRsvpGatheringMutation, useCancelRsvpMutation } from "../../store/slices/gatheringsSlice";
import {
  formatGatheringTime,
  hostLocalTime,
  quorumLine,
  rsvpState,
  statusLabel,
  topicLabel,
  gatheringErrorText,
  personId,
  personName,
} from "./lib/gatheringFormat";
import GatheringSafetyMenu from "./GatheringSafetyMenu";
import ConfirmDialog from "./ConfirmDialog";
import { photoUrl } from "../../utils/photoUrl";

const GatheringDetail: React.FC = () => {
  const { id = "" } = useParams();
  const navigate = useNavigate();
  const { t, i18n } = useTranslation();
  const { data: g, isLoading, isError, refetch } = useGetGatheringQuery(id, { skip: !id });
  const [rsvp, rsvpState_] = useRsvpGatheringMutation();
  const [leave, leaveState] = useCancelRsvpMutation();
  const [confirmLeave, setConfirmLeave] = useState(false);
  const busy = !!(rsvpState_ && rsvpState_.isLoading) || !!(leaveState && leaveState.isLoading);

  if (isLoading) return <Loader />;
  if (isError || !g) {
    return (
      <section data-testid="gathering-unavailable" className="mx-auto max-w-xl px-4 py-16 text-center">
        <p className="text-lg font-bold">{t("gatherings.errors.gatheringGone") || "This gathering isn't available."}</p>
        <Link to="/gatherings" className="mt-4 inline-block font-extrabold text-brand-dark">
          {t("gatherings.detail.back") || "See other gatherings"}
        </Link>
      </section>
    );
  }

  const state = rsvpState(g);
  const hostId = personId(g.host);
  const hostName = personName(g.host);
  const hostAvatar = g.host && typeof g.host === "object" ? photoUrl(g.host.images) : undefined;
  const hostTime = hostLocalTime(g, i18n.language);

  const doRsvp = async () => {
    try {
      const res: any = await rsvp(id).unwrap();
      notify.success(
        res && res.pending
          ? t("gatherings.detail.requestSent") || "Request sent. The host will decide."
          : t("gatherings.detail.youreGoing") || "You're going."
      );
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
      refetch();
    }
  };
  const doLeave = async () => {
    try {
      await leave(id).unwrap();
      setConfirmLeave(false);
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    }
  };

  return (
    <article data-testid="gathering-detail" className="mx-auto max-w-2xl px-4 py-6 text-start">
      {g.coverImage && <img src={g.coverImage} alt="" className="mb-4 h-48 w-full rounded-2xl object-cover" />}
      <div className="flex items-start gap-2">
        <div className="min-w-0 flex-1">
          <p className="text-xs font-bold uppercase text-brand-dark dark:text-brand-light">{statusLabel(g.status, t)}</p>
          <h1 className="text-2xl font-extrabold text-gray-900 dark:text-gray-50">{g.title}</h1>
        </div>
        <GatheringSafetyMenu type="gathering" targetId={g._id} ownerId={hostId} ownerName={hostName} onBlocked={() => navigate("/gatherings")} />
      </div>

      <p data-testid="gathering-time" className="mt-2 font-semibold">
        {formatGatheringTime(g.startsAt, i18n.language)}
        {" · "}
        {t("gatherings.detail.duration", { count: g.durationMinutes }) || `${g.durationMinutes} min`}
      </p>
      {hostTime && (
        <p data-testid="gathering-host-time" className="text-sm text-gray-600 dark:text-gray-300">
          {t("gatherings.time.hostLocal", { time: hostTime }) || `${hostTime} for the host`}
        </p>
      )}

      <div className="mt-3 flex flex-wrap gap-2 text-xs">
        <span className="rounded-full bg-gray-100 px-2 py-0.5 dark:bg-gray-800">{g.languageLabel || g.language}</span>
        {g.level && <span className="rounded-full bg-gray-100 px-2 py-0.5 dark:bg-gray-800">{g.level}</span>}
        {g.topic && <span className="rounded-full bg-gray-100 px-2 py-0.5 dark:bg-gray-800">{topicLabel(g.topic, t)}</span>}
        <span className="rounded-full bg-gray-100 px-2 py-0.5 dark:bg-gray-800">
          {t("gatherings.detail.online") || "Online"}
        </span>
      </div>

      <p data-testid="gathering-quorum" className="mt-4 text-base font-bold">{quorumLine(g, t)}</p>
      <p className="text-sm text-gray-600 dark:text-gray-300">
        {t("gatherings.detail.capacity", { count: g.capacity, quorum: g.quorum }) ||
          `Up to ${g.capacity} people · confirms at ${g.quorum}`}
      </p>

      {g.description && <p className="mt-4 whitespace-pre-wrap text-gray-800 dark:text-gray-100">{g.description}</p>}

      {hostId && (
        <Link to={`/profile/${hostId}`} data-testid="gathering-host-link" className="mt-5 flex items-center gap-3 no-underline">
          {hostAvatar ? (
            <img src={hostAvatar} alt="" className="h-10 w-10 rounded-full object-cover" />
          ) : (
            <span className="h-10 w-10 rounded-full bg-gray-200" />
          )}
          <span className="text-sm">
            <span className="block text-gray-500">{t("gatherings.detail.host") || "Host"}</span>
            <span className="font-bold text-gray-900 dark:text-gray-50">{hostName || t("gatherings.detail.someone") || "A BananaTalk member"}</span>
            {(g.hostCity || g.hostCountry) && (
              <span className="block text-xs text-gray-500">{[g.hostCity, g.hostCountry].filter(Boolean).join(", ")}</span>
            )}
          </span>
        </Link>
      )}

      <div className="mt-6">
        {state === "join" && (
          <button type="button" data-testid="gathering-rsvp" disabled={busy} onClick={doRsvp} className="w-full rounded-full bg-brand px-5 py-3 font-extrabold text-white">
            {t("gatherings.detail.join") || "I'm going"}
          </button>
        )}
        {state === "request" && (
          <button type="button" data-testid="gathering-rsvp" disabled={busy} onClick={doRsvp} className="w-full rounded-full bg-brand px-5 py-3 font-extrabold text-white">
            {t("gatherings.detail.askToJoin") || "Ask to join"}
          </button>
        )}
        {state === "going" && (
          <button type="button" data-testid="gathering-leave" disabled={busy} onClick={() => setConfirmLeave(true)} className="w-full rounded-full border-2 border-gray-300 px-5 py-3 font-extrabold">
            {t("gatherings.detail.leave") || "I can't go any more"}
          </button>
        )}
        {state === "pending" && (
          <button type="button" data-testid="gathering-cancel-request" disabled={busy} onClick={doLeave} className="w-full rounded-full border-2 border-gray-300 px-5 py-3 font-extrabold">
            {t("gatherings.detail.cancelRequest") || "Cancel my request"}
          </button>
        )}
        {state === "full" && (
          <p data-testid="gathering-full" className="rounded-full bg-gray-100 px-5 py-3 text-center font-bold dark:bg-gray-800">
            {t("gatherings.card.full") || "Full"}
          </p>
        )}
        {state === "closed" && (
          <p data-testid="gathering-closed" className="rounded-full bg-gray-100 px-5 py-3 text-center font-bold dark:bg-gray-800">
            {statusLabel(g.status, t)}
          </p>
        )}
        {state === "host" && (
          <Link to={`/gatherings/${g._id}/edit`} data-testid="gathering-edit-link" className="block w-full rounded-full border-2 border-brand px-5 py-3 text-center font-extrabold text-brand-dark no-underline">
            {t("gatherings.detail.edit") || "Edit gathering"}
          </Link>
        )}
      </div>

      {confirmLeave && (
        <ConfirmDialog
          title={t("gatherings.confirm.leaveTitle") || "Give up your seat?"}
          body={t("gatherings.confirm.leaveBody") || "The others are counting on the people who said yes."}
          confirmLabel={t("gatherings.confirm.leaveOk") || "Give up my seat"}
          danger
          busy={busy}
          onConfirm={doLeave}
          onCancel={() => setConfirmLeave(false)}
        />
      )}
    </article>
  );
};

export default GatheringDetail;
```

Add to `eng.json`:

```json
"gatherings": {
  "confirm": {
    "cancel": "Not now",
    "leaveBody": "The others are counting on the people who said yes.",
    "leaveOk": "Give up my seat",
    "leaveTitle": "Give up your seat?"
  },
  "detail": {
    "askToJoin": "Ask to join",
    "back": "See other gatherings",
    "cancelRequest": "Cancel my request",
    "capacity": "Up to {{count}} people · confirms at {{quorum}}",
    "duration": "{{count}} min",
    "edit": "Edit gathering",
    "host": "Host",
    "join": "I'm going",
    "leave": "I can't go any more",
    "online": "Online",
    "requestSent": "Request sent. The host will decide.",
    "someone": "A BananaTalk member",
    "youreGoing": "You're going."
  },
  "safety": {
    "blockHost": "Block the host",
    "blockOwner": "Block the owner",
    "more": "More",
    "reportClub": "Report club",
    "reportFailed": "Couldn't send the report. Try again.",
    "reportGathering": "Report gathering",
    "reported": "Thanks — our moderators will review it."
  }
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false GatheringDetail GatheringSafetyMenu
```
Expected: 16 passed (10 detail, 6 safety menu).

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/GatheringDetail.tsx src/components/gatherings/GatheringSafetyMenu.tsx src/components/gatherings/ConfirmDialog.tsx src/components/gatherings/GatheringDetail.test.tsx src/components/gatherings/GatheringSafetyMenu.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(gatherings): gathering page with RSVP, request, leave, report, block

Times in the viewer's zone with the host's local time; the quorum
line; I'm going / Ask to join / Cancel my request / give up a seat
(confirmed in a dialog); Full and Cancelled states; the host never
sees Leave. Report gathering (type "gathering") and block the host via
the shared Phase 3 block dialog. Missing or blocked = "not available".

Still open (Phase 4 gatherings): host form and decisions, clubs,
covers, routes behind webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-5: Host a gathering: create and edit form with the backend's limits

**Files:**
- Create: `src/components/gatherings/GatheringForm.tsx`, `src/components/gatherings/lib/gatheringFormRules.ts`
- Modify: `src/utils/locales/eng.json` (`gatherings.form.*`)
- Test: `src/components/gatherings/lib/gatheringFormRules.test.ts`, `src/components/gatherings/GatheringForm.test.tsx` (new)

**Interfaces:**
- Consumes: `useCreateGatheringMutation`, `useUpdateGatheringMutation`, `useGetGatheringQuery`, `gatheringEditBody`, `GATHERING_TOPICS`, `GATHERING_LEVELS` (P4-GATH-1); `toLocalInputValue`, `fromLocalInputValue`, `topicLabel`, `gatheringErrorText` (P4-GATH-2); `useGetLanguagesQuery` + `languageOptions` (P3-COM-3). Backend rules (`controllers/gatherings.js:138-251`, `:539-645`; `models/Gathering.js:46-112`): title required, ≤ 120; description ≤ 2000; language required; `startsAt` strictly in the future; `level` one of A1–C2 or none; `topic` one of the nine or none; capacity 2–50 (model) — the app's form offers **2–20** (`create_gathering_form.dart` capacity stepper `min: 2, max: 20`) and the web matches the app; quorum ≥ 2 and clamped to ≤ capacity (`:211-214` of the app form); `durationMinutes` is fixed at 60 in the app (`static const int _duration = 60`) — the web sends 60 and shows it read-only; `joinMode` `open` | `approval`. Edit: quorum is **not** editable (the server ignores it; the form shows it read-only), capacity ≥ the people already going (400 otherwise), only changed fields are sent. Defaults, as the app's form: the viewer's target language (`auth.userInfo.user.language_to_learn`), tomorrow 19:00 local, 6 seats, quorum 3, open; start no more than 90 days ahead (the app's date picker `lastDate: now + 90 days`). `?club=<id>` in the URL (from a club page, P4-GATH-7) is sent as `club`.
- Produces: default export `GatheringForm` props `{ mode: "create" | "edit" }` (edit reads `:id`). `validateGatheringForm(v: GatheringFormValues, ctx: { mode, now: Date, going?: number }): { [field: string]: string }` (error keys; empty object = valid), `defaultGatheringValues(now: Date, language: string): GatheringFormValues`, `GatheringFormValues` from `lib/gatheringFormRules.ts`. Testids: `gathering-form`, `gf-title`, `gf-description`, `gf-language`, `gf-level`, `gf-topic`, `gf-starts-at`, `gf-capacity`, `gf-quorum`, `gf-join-open`, `gf-join-approval`, `gf-submit`, `gf-error-<field>`, `gf-server-error`, `gf-not-host`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/gatherings/lib/gatheringFormRules.test.ts`:

```ts
import { validateGatheringForm, defaultGatheringValues, MAX_CAPACITY, MAX_DAYS_AHEAD } from "./gatheringFormRules";

const NOW = new Date("2026-11-01T08:00:00.000Z");
const good = () => ({ ...defaultGatheringValues(NOW, "Korean"), title: "Coffee chat" });

it("defaults like the app: target language, tomorrow 19:00 local, 6 seats, quorum 3, open, 60 min", () => {
  const v = defaultGatheringValues(NOW, "Korean");
  const start = new Date(v.startsAt);
  expect(v.language).toBe("Korean");
  expect(start.getHours()).toBe(19);
  expect(start.getMinutes()).toBe(0);
  expect(start.getTime()).toBeGreaterThan(NOW.getTime());
  expect(v).toEqual(expect.objectContaining({ capacity: 6, quorum: 3, joinMode: "open", durationMinutes: 60, level: "", topic: "" }));
  expect(MAX_CAPACITY).toBe(20);
  expect(MAX_DAYS_AHEAD).toBe(90);
});

it("accepts a complete form", () => {
  expect(validateGatheringForm(good(), { mode: "create", now: NOW })).toEqual({});
});

it("requires a title of at most 120 characters and a language", () => {
  expect(validateGatheringForm({ ...good(), title: "   " }, { mode: "create", now: NOW })).toEqual({ title: "titleRequired" });
  expect(validateGatheringForm({ ...good(), title: "x".repeat(121) }, { mode: "create", now: NOW })).toEqual({ title: "titleTooLong" });
  expect(validateGatheringForm({ ...good(), language: "" }, { mode: "create", now: NOW })).toEqual({ language: "languageRequired" });
});

it("caps the description at 2000", () => {
  expect(validateGatheringForm({ ...good(), description: "x".repeat(2001) }, { mode: "create", now: NOW })).toEqual({
    description: "descriptionTooLong",
  });
});

it("needs a start in the future and within 90 days", () => {
  expect(validateGatheringForm({ ...good(), startsAt: "" }, { mode: "create", now: NOW })).toEqual({ startsAt: "startRequired" });
  expect(validateGatheringForm({ ...good(), startsAt: "2026-11-01T07:00:00.000Z" }, { mode: "create", now: NOW })).toEqual({
    startsAt: "startInPast",
  });
  expect(validateGatheringForm({ ...good(), startsAt: "2027-03-01T10:00:00.000Z" }, { mode: "create", now: NOW })).toEqual({
    startsAt: "startTooFar",
  });
});

it("keeps capacity 2-20 and quorum 2..capacity", () => {
  expect(validateGatheringForm({ ...good(), capacity: 1 }, { mode: "create", now: NOW })).toEqual({ capacity: "capacityRange" });
  expect(validateGatheringForm({ ...good(), capacity: 21 }, { mode: "create", now: NOW })).toEqual({ capacity: "capacityRange" });
  expect(validateGatheringForm({ ...good(), quorum: 1 }, { mode: "create", now: NOW })).toEqual({ quorum: "quorumRange" });
  expect(validateGatheringForm({ ...good(), capacity: 4, quorum: 5 }, { mode: "create", now: NOW })).toEqual({ quorum: "quorumRange" });
});

it("on edit, an unchanged start time is not re-checked (it is not sent)", () => {
  const past = "2026-10-01T10:00:00.000Z";
  expect(validateGatheringForm({ ...good(), startsAt: past }, { mode: "edit", now: NOW, originalStartsAt: past })).toEqual({});
  expect(validateGatheringForm({ ...good(), startsAt: "2026-10-02T10:00:00.000Z" }, { mode: "edit", now: NOW, originalStartsAt: past })).toEqual({
    startsAt: "startInPast",
  });
});

it("on edit, capacity cannot drop below the people already going, and quorum is not checked", () => {
  expect(validateGatheringForm({ ...good(), capacity: 3, quorum: 9 }, { mode: "edit", now: NOW, going: 4 })).toEqual({
    capacity: "capacityBelowGoing",
  });
  expect(validateGatheringForm({ ...good(), capacity: 4, quorum: 9 }, { mode: "edit", now: NOW, going: 4 })).toEqual({});
});
```

Create `src/components/gatherings/GatheringForm.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import GatheringForm from "./GatheringForm";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: jest.fn() } }));

const mockCreate = jest.fn();
const mockUpdate = jest.fn();
let mockQuery: any = { data: undefined, isLoading: false, isError: false };
jest.mock("../../store/slices/gatheringsSlice", () => {
  const actual = jest.requireActual("../../store/slices/gatheringsSlice");
  return {
    GATHERING_TOPICS: actual.GATHERING_TOPICS,
    GATHERING_LEVELS: actual.GATHERING_LEVELS,
    gatheringEditBody: actual.gatheringEditBody,
    useCreateGatheringMutation: () => [mockCreate, { isLoading: false }],
    useUpdateGatheringMutation: () => [mockUpdate, { isLoading: false }],
    useGetGatheringQuery: () => mockQuery,
  };
});
jest.mock("../../store/slices/communitySlice", () => ({ useGetLanguagesQuery: () => ({ data: { data: [] } }) }));
jest.mock("../community/lib/languageOptions", () => ({
  languageOptions: () => [
    { value: "Korean", label: "Korean" },
    { value: "Japanese", label: "Japanese" },
  ],
}));

function Where() {
  const l = useLocation();
  return <div data-testid="where">{l.pathname}</div>;
}
function renderForm(path: string, mode: "create" | "edit") {
  const store = configureStore({
    reducer: { auth: (s: any = { userInfo: { user: { _id: "me", language_to_learn: "Korean" } } }) => s },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Routes>
          <Route path="/gatherings/new" element={<GatheringForm mode="create" />} />
          <Route path="/gatherings/:id/edit" element={<GatheringForm mode="edit" />} />
          <Route path="/gatherings/:id" element={<Where />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}
const type = (id: string, value: string) => fireEvent.change(screen.getByTestId(id), { target: { value } });
/** A datetime-local value n days from now at 19:30 (inside the 90-day window). */
function inDays(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() + n);
  const p = (x: number) => (x < 10 ? `0${x}` : String(x));
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T19:30`;
}

beforeEach(() => {
  mockCreate.mockReset();
  mockUpdate.mockReset();
  mockQuery = { data: undefined, isLoading: false, isError: false };
});

it("prefills like the app and creates, sending startsAt as UTC and the club from ?club=", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.resolve({ _id: "g9" }) });
  renderForm("/gatherings/new?club=c1", "create");
  expect((screen.getByTestId("gf-language") as HTMLSelectElement).value).toBe("Korean");
  expect((screen.getByTestId("gf-capacity") as HTMLInputElement).value).toBe("6");
  type("gf-title", "  Korean coffee chat  ");
  const when = inDays(2);
  type("gf-starts-at", when);
  fireEvent.change(screen.getByTestId("gf-topic"), { target: { value: "conversation" } });
  fireEvent.click(screen.getByTestId("gf-join-approval"));
  fireEvent.click(screen.getByTestId("gf-submit"));
  await waitFor(() => expect(mockCreate).toHaveBeenCalled());
  expect(mockCreate.mock.calls[0][0]).toEqual({
    title: "Korean coffee chat",
    language: "Korean",
    startsAt: new Date(when).toISOString(),
    description: "",
    durationMinutes: 60,
    capacity: 6,
    quorum: 3,
    joinMode: "approval",
    topic: "conversation",
    club: "c1",
  });
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/gatherings/g9"));
});

it("shows field errors and does not submit", () => {
  renderForm("/gatherings/new", "create");
  type("gf-title", "");
  fireEvent.click(screen.getByTestId("gf-submit"));
  expect(screen.getByTestId("gf-error-title")).toHaveTextContent("Give your gathering a title.");
  expect(mockCreate).not.toHaveBeenCalled();
});

it("clamps quorum when capacity drops below it", () => {
  renderForm("/gatherings/new", "create");
  type("gf-quorum", "5");
  type("gf-capacity", "4");
  expect((screen.getByTestId("gf-quorum") as HTMLInputElement).value).toBe("4");
});

it("shows the server's refusal inside the form", async () => {
  mockCreate.mockReturnValue({
    unwrap: () =>
      Promise.reject({ status: 403, data: { error: "You have cancelled or missed too many of your own gatherings to host a new one" } }),
  });
  renderForm("/gatherings/new", "create");
  type("gf-title", "Chat");
  type("gf-starts-at", inDays(2));
  fireEvent.click(screen.getByTestId("gf-submit"));
  await waitFor(() =>
    expect(screen.getByTestId("gf-server-error")).toHaveTextContent("too many of your gatherings were cancelled or missed")
  );
});

const existing = {
  _id: "g1",
  title: "Old title",
  description: "desc",
  language: "korean",
  languageLabel: "Korean",
  level: null,
  topic: "grammar",
  startsAt: "2030-11-01T10:00:00.000Z",
  durationMinutes: 60,
  capacity: 6,
  quorum: 3,
  joinMode: "open",
  status: "scheduled",
  going: 4,
  needed: 0,
  viewerIsHost: true,
  viewerIsAttending: true,
};

it("edits with only the changed fields and keeps quorum read-only", async () => {
  mockQuery = { data: existing, isLoading: false, isError: false };
  mockUpdate.mockReturnValue({ unwrap: () => Promise.resolve(existing) });
  renderForm("/gatherings/g1/edit", "edit");
  expect((screen.getByTestId("gf-title") as HTMLInputElement).value).toBe("Old title");
  expect(screen.getByTestId("gf-quorum")).toBeDisabled();
  type("gf-title", "New title");
  fireEvent.change(screen.getByTestId("gf-topic"), { target: { value: "" } });
  fireEvent.click(screen.getByTestId("gf-submit"));
  await waitFor(() => expect(mockUpdate).toHaveBeenCalledWith({ id: "g1", body: { title: "New title", topic: null } }));
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/gatherings/g1"));
});

it("refuses a capacity below the people already going, before asking the server", () => {
  mockQuery = { data: existing, isLoading: false, isError: false };
  renderForm("/gatherings/g1/edit", "edit");
  type("gf-capacity", "3");
  fireEvent.click(screen.getByTestId("gf-submit"));
  expect(screen.getByTestId("gf-error-capacity")).toHaveTextContent("4");
  expect(mockUpdate).not.toHaveBeenCalled();
});

it("saving with no change just goes back", async () => {
  mockQuery = { data: existing, isLoading: false, isError: false };
  renderForm("/gatherings/g1/edit", "edit");
  fireEvent.click(screen.getByTestId("gf-submit"));
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/gatherings/g1"));
  expect(mockUpdate).not.toHaveBeenCalled();
});

it("only the host can edit", () => {
  mockQuery = { data: { ...existing, viewerIsHost: false }, isLoading: false, isError: false };
  renderForm("/gatherings/g1/edit", "edit");
  expect(screen.getByTestId("gf-not-host")).toBeInTheDocument();
  expect(screen.queryByTestId("gathering-form")).not.toBeInTheDocument();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false gatheringFormRules GatheringForm
```
Expected: FAIL — `Cannot find module './gatheringFormRules'` / `'./GatheringForm'`.

- [ ] **Step 3: Implement**

Create `src/components/gatherings/lib/gatheringFormRules.ts`:

```ts
/** The app's capacity stepper (create_gathering_form.dart: min 2, max 20). The model allows 50. */
export const MIN_CAPACITY = 2;
export const MAX_CAPACITY = 20;
export const MIN_QUORUM = 2;
/** The app's date picker: lastDate = now + 90 days. */
export const MAX_DAYS_AHEAD = 90;
/** Fixed in the app (`static const int _duration = 60`). */
export const DURATION_MINUTES = 60;
export const TITLE_MAX = 120;
export const DESCRIPTION_MAX = 2000;

export interface GatheringFormValues {
  title: string;
  description: string;
  language: string;
  level: string;
  topic: string;
  /** UTC ISO. */
  startsAt: string;
  durationMinutes: number;
  capacity: number;
  quorum: number;
  joinMode: "open" | "approval";
}

/** Tomorrow 19:00 in the viewer's zone, six seats, quorum three -- the app's pre-filled draft. */
export function defaultGatheringValues(now: Date, language: string): GatheringFormValues {
  const start = new Date(now.getTime());
  start.setDate(start.getDate() + 1);
  start.setHours(19, 0, 0, 0);
  return {
    title: "",
    description: "",
    language: language || "",
    level: "",
    topic: "",
    startsAt: start.toISOString(),
    durationMinutes: DURATION_MINUTES,
    capacity: 6,
    quorum: 3,
    joinMode: "open",
  };
}

export function validateGatheringForm(
  v: GatheringFormValues,
  ctx: { mode: "create" | "edit"; now: Date; going?: number; originalStartsAt?: string }
): { [field: string]: string } {
  const errors: { [field: string]: string } = {};
  const title = (v.title || "").trim();
  if (!title) errors.title = "titleRequired";
  else if (title.length > TITLE_MAX) errors.title = "titleTooLong";
  if ((v.description || "").length > DESCRIPTION_MAX) errors.description = "descriptionTooLong";
  if (!v.language) errors.language = "languageRequired";

  const start = v.startsAt ? new Date(v.startsAt).getTime() : NaN;
  // An edit that leaves the time alone does not send it (gatheringEditBody),
  // so the server does not re-check it -- neither does the form.
  const unchangedStart =
    ctx.mode === "edit" && !!ctx.originalStartsAt && new Date(ctx.originalStartsAt).getTime() === start;
  if (unchangedStart) {
    // nothing to check
  } else if (!v.startsAt || Number.isNaN(start)) errors.startsAt = "startRequired";
  else if (start <= ctx.now.getTime()) errors.startsAt = "startInPast";
  else if (start > ctx.now.getTime() + MAX_DAYS_AHEAD * 24 * 3600 * 1000) errors.startsAt = "startTooFar";

  const capacity = Number(v.capacity);
  if (!Number.isFinite(capacity) || capacity < MIN_CAPACITY || capacity > MAX_CAPACITY) {
    errors.capacity = "capacityRange";
  } else if (ctx.mode === "edit" && typeof ctx.going === "number" && capacity < ctx.going) {
    errors.capacity = "capacityBelowGoing";
  }

  if (ctx.mode === "create") {
    const quorum = Number(v.quorum);
    if (!Number.isFinite(quorum) || quorum < MIN_QUORUM || (Number.isFinite(capacity) && quorum > capacity)) {
      errors.quorum = "quorumRange";
    }
  }
  return errors;
}
```

Create `src/components/gatherings/GatheringForm.tsx`:

```tsx
import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import Loader from "../Loader";
import {
  useCreateGatheringMutation,
  useUpdateGatheringMutation,
  useGetGatheringQuery,
  gatheringEditBody,
  GATHERING_TOPICS,
  GATHERING_LEVELS,
} from "../../store/slices/gatheringsSlice";
import { useGetLanguagesQuery } from "../../store/slices/communitySlice";
import { languageOptions } from "../community/lib/languageOptions";
import { toLocalInputValue, fromLocalInputValue, topicLabel, gatheringErrorText } from "./lib/gatheringFormat";
import {
  GatheringFormValues,
  defaultGatheringValues,
  validateGatheringForm,
  MIN_CAPACITY,
  MAX_CAPACITY,
  MIN_QUORUM,
  TITLE_MAX,
  DESCRIPTION_MAX,
  MAX_DAYS_AHEAD,
} from "./lib/gatheringFormRules";

const ERROR_TEXT: { [k: string]: string } = {
  titleRequired: "Give your gathering a title.",
  titleTooLong: "Keep the title under 120 characters.",
  descriptionTooLong: "Keep the description under 2000 characters.",
  languageRequired: "Pick the language you'll practise.",
  startRequired: "Pick a day and time.",
  startInPast: "Pick a start time in the future.",
  startTooFar: "Pick a time within the next 90 days.",
  capacityRange: "Seats must be between 2 and 20.",
  quorumRange: "The gathering confirms at 2 or more, and not more than the seats.",
};

const field = "mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 dark:border-gray-600 dark:bg-gray-900";

const GatheringForm: React.FC<{ mode: "create" | "edit" }> = ({ mode }) => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const [params] = useSearchParams();
  const clubId = params.get("club") || "";
  const targetLanguage = useSelector(
    (s: any) => (s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user.language_to_learn) || ""
  );
  const existing = useGetGatheringQuery(id, { skip: mode !== "edit" || !id });
  const [createGathering, createState] = useCreateGatheringMutation();
  const [updateGathering, updateState] = useUpdateGatheringMutation();
  const busy = !!(createState && createState.isLoading) || !!(updateState && updateState.isLoading);

  const [values, setValues] = useState<GatheringFormValues>(() =>
    defaultGatheringValues(new Date(), String(targetLanguage).replace(/\s*\([^)]*\)\s*$/, ""))
  );
  const [loadedId, setLoadedId] = useState("");
  const [errors, setErrors] = useState<{ [k: string]: string }>({});
  const [serverError, setServerError] = useState("");

  const g = existing.data;
  useEffect(() => {
    if (mode === "edit" && g && g._id !== loadedId) {
      setValues({
        title: g.title || "",
        description: g.description || "",
        language: g.languageLabel || g.language || "",
        level: g.level || "",
        topic: g.topic || "",
        startsAt: g.startsAt,
        durationMinutes: g.durationMinutes || 60,
        capacity: g.capacity,
        quorum: g.quorum,
        joinMode: g.joinMode === "approval" ? "approval" : "open",
      });
      setLoadedId(g._id);
    }
  }, [mode, g, loadedId]);

  const { data: catalog } = useGetLanguagesQuery();
  const langs = useMemo(() => {
    const opts: { value: string; label: string }[] = languageOptions((catalog && catalog.data) || [], i18n.language);
    // An existing gathering's label that the catalog does not list (an old
    // variant name) must still be selectable, or saving would silently change it.
    if (values.language && !opts.some((o) => o.value === values.language)) {
      return [{ value: values.language, label: values.language }].concat(opts);
    }
    return opts;
  }, [catalog, i18n.language, values.language]);

  if (mode === "edit") {
    if (existing.isLoading) return <Loader />;
    if (existing.isError || !g) {
      return (
        <p data-testid="gf-not-host" className="mx-auto max-w-xl px-4 py-16 text-center font-bold">
          {t("gatherings.errors.gatheringGone") || "This gathering isn't available."}
        </p>
      );
    }
    if (!g.viewerIsHost) {
      return (
        <p data-testid="gf-not-host" className="mx-auto max-w-xl px-4 py-16 text-center font-bold">
          {t("gatherings.form.notHost") || "Only the host can edit this gathering."}
        </p>
      );
    }
  }

  const set = (patch: Partial<GatheringFormValues>) => setValues((v) => Object.assign({}, v, patch));
  const errorText = (key: string) => {
    if (key === "capacityBelowGoing") {
      const count = g ? g.going : 0;
      return t("gatherings.errors.capacityBelowGoing", { count }) || `Capacity can't be lower than the ${count} people already going.`;
    }
    return t(`gatherings.form.errors.${key}`) || ERROR_TEXT[key] || key;
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setServerError("");
    const found = validateGatheringForm(values, {
      mode,
      now: new Date(),
      going: g ? g.going : undefined,
      originalStartsAt: g ? g.startsAt : undefined,
    });
    setErrors(found);
    if (Object.keys(found).length) return;

    try {
      if (mode === "create") {
        const body: any = {
          title: values.title.trim(),
          language: values.language,
          startsAt: values.startsAt,
          description: values.description.trim(),
          durationMinutes: values.durationMinutes,
          capacity: Number(values.capacity),
          quorum: Math.min(Number(values.quorum), Number(values.capacity)),
          joinMode: values.joinMode,
        };
        if (values.level) body.level = values.level;
        if (values.topic) body.topic = values.topic;
        if (clubId) body.club = clubId;
        const created: any = await createGathering(body).unwrap();
        navigate(`/gatherings/${created && created._id ? created._id : ""}`, { replace: true });
      } else if (g) {
        const body = gatheringEditBody(
          {
            title: g.title,
            description: g.description || "",
            languageLabel: g.languageLabel || g.language,
            level: g.level || null,
            topic: g.topic || null,
            startsAt: g.startsAt,
            durationMinutes: g.durationMinutes,
            capacity: g.capacity,
            joinMode: g.joinMode,
          },
          {
            title: values.title.trim(),
            description: values.description.trim(),
            languageLabel: values.language,
            level: values.level || null,
            topic: values.topic || null,
            startsAt: values.startsAt,
            durationMinutes: values.durationMinutes,
            capacity: Number(values.capacity),
            joinMode: values.joinMode,
          }
        );
        if (Object.keys(body).length) await updateGathering({ id: g._id, body }).unwrap();
        navigate(`/gatherings/${g._id}`, { replace: true });
      }
    } catch (err) {
      setServerError(gatheringErrorText(err, t));
    }
  };

  const now = new Date();
  const minLocal = toLocalInputValue(now.toISOString());
  const maxLocal = toLocalInputValue(new Date(now.getTime() + MAX_DAYS_AHEAD * 24 * 3600 * 1000).toISOString());
  const err = (name: string) =>
    errors[name] ? (
      <p data-testid={`gf-error-${name}`} className="mt-1 text-sm text-red-700">
        {errorText(errors[name])}
      </p>
    ) : null;

  return (
    <form data-testid="gathering-form" onSubmit={submit} noValidate className="mx-auto grid max-w-xl gap-4 px-4 py-6 text-start">
      <h1 className="text-2xl font-extrabold">
        {mode === "create" ? t("gatherings.form.createTitle") || "Host a gathering" : t("gatherings.form.editTitle") || "Edit gathering"}
      </h1>

      <label className="block text-sm font-bold">
        {t("gatherings.form.title") || "Title"}
        <input data-testid="gf-title" className={field} maxLength={TITLE_MAX} value={values.title} onChange={(e) => set({ title: e.target.value })} />
        {err("title")}
      </label>

      <label className="block text-sm font-bold">
        {t("gatherings.form.language") || "Language"}
        <select data-testid="gf-language" className={field} value={values.language} onChange={(e) => set({ language: e.target.value })}>
          <option value="">{t("gatherings.form.pickLanguage") || "Pick a language"}</option>
          {langs.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
        {err("language")}
      </label>

      <label className="block text-sm font-bold">
        {t("gatherings.form.startsAt") || "Starts"}
        <input
          data-testid="gf-starts-at"
          type="datetime-local"
          className={field}
          min={minLocal}
          max={maxLocal}
          value={toLocalInputValue(values.startsAt)}
          onChange={(e) => set({ startsAt: fromLocalInputValue(e.target.value) })}
        />
        <span className="mt-1 block text-xs font-normal text-gray-500">
          {t("gatherings.form.duration", { count: values.durationMinutes }) || `Lasts ${values.durationMinutes} minutes · in your time zone`}
        </span>
        {err("startsAt")}
      </label>

      <div className="grid grid-cols-2 gap-3">
        <label className="block text-sm font-bold">
          {t("gatherings.form.capacity") || "Seats"}
          <input
            data-testid="gf-capacity"
            type="number"
            min={MIN_CAPACITY}
            max={MAX_CAPACITY}
            className={field}
            value={values.capacity}
            onChange={(e) => {
              const capacity = Number(e.target.value);
              set(mode === "create" && values.quorum > capacity && capacity >= MIN_QUORUM ? { capacity, quorum: capacity } : { capacity });
            }}
          />
          {err("capacity")}
        </label>
        <label className="block text-sm font-bold">
          {t("gatherings.form.quorum") || "Confirms at"}
          <input
            data-testid="gf-quorum"
            type="number"
            min={MIN_QUORUM}
            max={values.capacity}
            className={field}
            disabled={mode === "edit"}
            value={values.quorum}
            onChange={(e) => set({ quorum: Number(e.target.value) })}
          />
          {err("quorum")}
        </label>
      </div>

      <fieldset className="text-sm">
        <legend className="font-bold">{t("gatherings.form.joinMode") || "Who can join"}</legend>
        <label className="me-4 inline-flex items-center gap-1">
          <input type="radio" name="joinMode" data-testid="gf-join-open" checked={values.joinMode === "open"} onChange={() => set({ joinMode: "open" })} />
          {t("gatherings.form.joinOpen") || "Anyone"}
        </label>
        <label className="inline-flex items-center gap-1">
          <input type="radio" name="joinMode" data-testid="gf-join-approval" checked={values.joinMode === "approval"} onChange={() => set({ joinMode: "approval" })} />
          {t("gatherings.form.joinApproval") || "I approve each person"}
        </label>
      </fieldset>

      <div className="grid grid-cols-2 gap-3">
        <label className="block text-sm font-bold">
          {t("gatherings.form.topic") || "Topic"}
          <select data-testid="gf-topic" className={field} value={values.topic} onChange={(e) => set({ topic: e.target.value })}>
            <option value="">{t("gatherings.form.noTopic") || "No topic"}</option>
            {GATHERING_TOPICS.map((k: string) => (
              <option key={k} value={k}>
                {topicLabel(k, t)}
              </option>
            ))}
          </select>
        </label>
        <label className="block text-sm font-bold">
          {t("gatherings.form.level") || "Level"}
          <select data-testid="gf-level" className={field} value={values.level} onChange={(e) => set({ level: e.target.value })}>
            <option value="">{t("gatherings.form.anyLevel") || "Any level"}</option>
            {GATHERING_LEVELS.map((l: string) => (
              <option key={l} value={l}>
                {l}
              </option>
            ))}
          </select>
        </label>
      </div>

      <label className="block text-sm font-bold">
        {t("gatherings.form.description") || "What will you do? (optional)"}
        <textarea data-testid="gf-description" className={field} rows={4} maxLength={DESCRIPTION_MAX} value={values.description} onChange={(e) => set({ description: e.target.value })} />
        {err("description")}
      </label>

      {serverError && (
        <p data-testid="gf-server-error" role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-800">
          {serverError}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Link to={mode === "edit" && g ? `/gatherings/${g._id}` : "/gatherings"} className="rounded-full px-4 py-2 font-bold">
          {t("gatherings.form.cancel") || "Cancel"}
        </Link>
        <button type="submit" data-testid="gf-submit" disabled={busy} className="rounded-full bg-brand px-5 py-2 font-extrabold text-white disabled:opacity-50">
          {mode === "create" ? t("gatherings.form.create") || "Post gathering" : t("gatherings.form.save") || "Save"}
        </button>
      </div>
    </form>
  );
};

export default GatheringForm;
```

Add to `eng.json` (`gatherings.form`):

```json
"form": {
  "anyLevel": "Any level",
  "cancel": "Cancel",
  "capacity": "Seats",
  "create": "Post gathering",
  "createTitle": "Host a gathering",
  "description": "What will you do? (optional)",
  "duration_one": "Lasts {{count}} minute · in your time zone",
  "duration_other": "Lasts {{count}} minutes · in your time zone",
  "editTitle": "Edit gathering",
  "errors": {
    "capacityRange": "Seats must be between 2 and 20.",
    "descriptionTooLong": "Keep the description under 2000 characters.",
    "languageRequired": "Pick the language you'll practise.",
    "quorumRange": "The gathering confirms at 2 or more, and not more than the seats.",
    "startInPast": "Pick a start time in the future.",
    "startRequired": "Pick a day and time.",
    "startTooFar": "Pick a time within the next 90 days.",
    "titleRequired": "Give your gathering a title.",
    "titleTooLong": "Keep the title under 120 characters."
  },
  "joinApproval": "I approve each person",
  "joinMode": "Who can join",
  "joinOpen": "Anyone",
  "language": "Language",
  "level": "Level",
  "noTopic": "No topic",
  "notHost": "Only the host can edit this gathering.",
  "pickLanguage": "Pick a language",
  "quorum": "Confirms at",
  "save": "Save",
  "startsAt": "Starts",
  "title": "Title",
  "topic": "Topic"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false gatheringFormRules GatheringForm
```
Expected: 8 rules cases + 8 form cases pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/GatheringForm.tsx src/components/gatherings/lib/gatheringFormRules.ts src/components/gatherings/lib/gatheringFormRules.test.ts src/components/gatherings/GatheringForm.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(gatherings): host a gathering, and edit it

The app's pre-filled draft (target language, tomorrow 19:00 local,
6 seats, confirms at 3, 60 minutes, open) and its limits: title <=120,
start in the future within 90 days, seats 2-20, quorum clamped to the
seats. startsAt sent as UTC; ?club= hosts for a club. Edits send only
what changed (topic null clears), quorum read-only, capacity never
below the people already going. Server refusals shown in the form.

Still open (Phase 4 gatherings): host decisions, clubs, covers, routes
behind webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-6: Host decisions: join requests, run it or call it off, cancel, end

**Files:**
- Create: `src/components/gatherings/GatheringHostPanel.tsx`
- Modify: `src/components/gatherings/GatheringDetail.tsx` (render `<GatheringHostPanel gathering={g} />` right after the `state === "host"` Edit link, inside the same `<div className="mt-6">`)
- Modify: `src/utils/locales/eng.json` (`gatherings.host.*`)
- Test: `src/components/gatherings/GatheringHostPanel.test.tsx` (new); `src/components/gatherings/GatheringDetail.test.tsx` (one mock line + one case)

**Interfaces:**
- Consumes: `useDecideJoinRequestMutation` (`POST …/requests/:userId {approve}`; approving re-checks capacity → 400 "This gathering is full"; a decline removes the request outright, `controllers/gatherings.js:873-930`), `useHostDecisionMutation` (`POST …/decision {run}`; `run:false` cancels and notifies, `:707-746`), `useCancelGatheringMutation` (`DELETE …/:id`, notifies every attendee on push and email, `:648-700`), `useEndGatheringMutation` (`POST …/end`; refused before the start time — "A gathering cannot end before it starts" — because attending exempts a first message from the conversation cap, `:790-870`; the app only offers End once `startsAt` has passed, `gathering_detail_screen.dart:446-460`). `isHostDecisionDue`, `minutesUntil`, `gatheringErrorText`, `personName` (P4-GATH-2); `ConfirmDialog` (P4-GATH-4). App copy: `gatheringHostDecision` ("Only N people are coming so far. Run it anyway, or call it off?"), `gatheringRunAnyway`, `gatheringCallItOff`, `gatheringEnd`, `gatheringEndedThanks` ("Ended — message anyone you met, it's free"), `gatheringCancelConfirm` ("N people are expecting this. They'll be told it's off."), `gatheringRequests` ("N waiting to join").
- Produces: default export `GatheringHostPanel` props `{ gathering: Gathering; now?: Date }` (renders nothing unless `viewerIsHost` and the gathering is not cancelled/ended). Testids: `host-panel`, `host-requests`, `host-request-<userId>`, `host-approve-<userId>`, `host-decline-<userId>`, `host-decision`, `host-run-anyway`, `host-call-off`, `host-end`, `host-cancel`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/gatherings/GatheringHostPanel.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import GatheringHostPanel from "./GatheringHostPanel";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockSuccess = jest.fn();
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: (m: any) => mockSuccess(m), error: (m: any) => mockError(m) },
}));
const mockDecide = jest.fn();
const mockDecision = jest.fn();
const mockCancel = jest.fn();
const mockEnd = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useDecideJoinRequestMutation: () => [mockDecide, { isLoading: false }],
  useHostDecisionMutation: () => [mockDecision, { isLoading: false }],
  useCancelGatheringMutation: () => [mockCancel, { isLoading: false }],
  useEndGatheringMutation: () => [mockEnd, { isLoading: false }],
}));

const NOW = new Date("2026-11-01T08:00:00.000Z");
const resolved = () => ({ unwrap: () => Promise.resolve({}) });
const host = (extra: any = {}) => ({
  _id: "g1",
  title: "Coffee",
  language: "korean",
  startsAt: "2026-11-01T09:30:00.000Z",
  durationMinutes: 60,
  capacity: 6,
  quorum: 3,
  joinMode: "approval",
  status: "scheduled",
  going: 1,
  needed: 2,
  quorumMet: false,
  viewerIsAttending: true,
  viewerIsHost: true,
  requests: [{ _id: "u7", name: "Mina", username: "mina", images: [] }],
  ...extra,
});

beforeEach(() => {
  [mockDecide, mockDecision, mockCancel, mockEnd, mockSuccess, mockError].forEach((m) => m.mockReset());
  [mockDecide, mockDecision, mockCancel, mockEnd].forEach((m) => m.mockReturnValue(resolved()));
});

it("renders nothing for a guest or a finished gathering", () => {
  const { container, rerender } = render(<GatheringHostPanel gathering={host({ viewerIsHost: false }) as any} now={NOW} />);
  expect(container).toBeEmptyDOMElement();
  rerender(<GatheringHostPanel gathering={host({ status: "ended" }) as any} now={NOW} />);
  expect(container).toBeEmptyDOMElement();
});

it("lists join requests and approves or declines each", async () => {
  render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  expect(screen.getByTestId("host-requests")).toHaveTextContent("1 waiting to join");
  expect(screen.getByTestId("host-request-u7")).toHaveTextContent("Mina");
  fireEvent.click(screen.getByTestId("host-approve-u7"));
  await waitFor(() => expect(mockDecide).toHaveBeenCalledWith({ id: "g1", userId: "u7", approve: true }));
  fireEvent.click(screen.getByTestId("host-decline-u7"));
  await waitFor(() => expect(mockDecide).toHaveBeenCalledWith({ id: "g1", userId: "u7", approve: false }));
});

it("says why an approval failed (the gathering filled up)", async () => {
  mockDecide.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { error: "This gathering is full" } }) });
  render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  fireEvent.click(screen.getByTestId("host-approve-u7"));
  await waitFor(() => expect(mockError).toHaveBeenCalledWith("This gathering is full."));
});

it("asks the T-2h question when quorum is unmet, and runs it anyway", async () => {
  render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  // `going` counts the host, so going: 1 means nobody else yet.
  expect(screen.getByTestId("host-decision")).toHaveTextContent("Only you are coming so far");
  fireEvent.click(screen.getByTestId("host-run-anyway"));
  await waitFor(() => expect(mockDecision).toHaveBeenCalledWith({ id: "g1", run: true }));
});

it("counts the people coming when there are some", () => {
  render(<GatheringHostPanel gathering={host({ going: 2, needed: 1 }) as any} now={NOW} />);
  expect(screen.getByTestId("host-decision")).toHaveTextContent("Only 2 people are coming so far");
});

it("calls it off only after confirming", async () => {
  render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  fireEvent.click(screen.getByTestId("host-call-off"));
  expect(mockDecision).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockDecision).toHaveBeenCalledWith({ id: "g1", run: false }));
});

it("does not ask earlier than two hours before", () => {
  render(<GatheringHostPanel gathering={host({ startsAt: "2026-11-01T12:00:00.000Z" }) as any} now={NOW} />);
  expect(screen.queryByTestId("host-decision")).not.toBeInTheDocument();
});

it("offers End only once the start has passed", async () => {
  const { rerender } = render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  expect(screen.queryByTestId("host-end")).not.toBeInTheDocument();
  rerender(<GatheringHostPanel gathering={host({ status: "confirmed", quorumMet: true }) as any} now={new Date("2026-11-01T10:00:00.000Z")} />);
  fireEvent.click(screen.getByTestId("host-end"));
  await waitFor(() => expect(mockEnd).toHaveBeenCalledWith("g1"));
  expect(mockSuccess).toHaveBeenCalledWith("Ended — message anyone you met, it's free");
});

it("cancels after a confirmation that says how many are expecting it", async () => {
  render(<GatheringHostPanel gathering={host({ going: 4, needed: 0, quorumMet: true, status: "confirmed" }) as any} now={NOW} />);
  fireEvent.click(screen.getByTestId("host-cancel"));
  expect(screen.getByTestId("confirm-dialog")).toHaveTextContent("3 people are expecting this");
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockCancel).toHaveBeenCalledWith("g1"));
});
```

In `src/components/gatherings/GatheringDetail.test.tsx` add, next to the `GatheringSafetyMenu` mock:

```tsx
jest.mock("./GatheringHostPanel", () => () => <div data-testid="host-panel" />);
```

and append:

```tsx
it("shows the host panel to the host", () => {
  mockQuery = ok(gathering({ viewerIsHost: true, viewerIsAttending: true }));
  renderDetail();
  expect(screen.getByTestId("host-panel")).toBeInTheDocument();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false GatheringHostPanel GatheringDetail
```
Expected: FAIL — `Cannot find module './GatheringHostPanel'` (both files).

- [ ] **Step 3: Implement**

Create `src/components/gatherings/GatheringHostPanel.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import {
  Gathering,
  useDecideJoinRequestMutation,
  useHostDecisionMutation,
  useCancelGatheringMutation,
  useEndGatheringMutation,
} from "../../store/slices/gatheringsSlice";
import { isHostDecisionDue, minutesUntil, gatheringErrorText, personName } from "./lib/gatheringFormat";
import ConfirmDialog from "./ConfirmDialog";
import { photoUrl } from "../../utils/photoUrl";

/**
 * Everything only the host can do, in the app's order: answer join requests,
 * answer the T-2h "run it anyway?" question, end it once it has started, and
 * -- last, because it strands everyone who said yes -- cancel it.
 */
const GatheringHostPanel: React.FC<{ gathering: Gathering; now?: Date }> = ({ gathering: g, now }) => {
  const { t } = useTranslation();
  const [decide] = useDecideJoinRequestMutation();
  const [decision] = useHostDecisionMutation();
  const [cancel] = useCancelGatheringMutation();
  const [end] = useEndGatheringMutation();
  const [confirm, setConfirm] = useState<"" | "callOff" | "cancel">("");
  const [busy, setBusy] = useState(false);

  if (!g.viewerIsHost || g.status === "cancelled" || g.status === "ended") return null;
  const at = now || new Date();
  const started = minutesUntil(g.startsAt, at) <= 0;
  const requests = g.requests || [];
  // Everyone the host would let down: the people going, minus the host.
  const expecting = Math.max(0, (g.going || 0) - 1);

  const run = async (fn: () => Promise<any>, success?: string) => {
    setBusy(true);
    try {
      await fn();
      if (success) notify.success(success);
      setConfirm("");
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div data-testid="host-panel" className="mt-4 grid gap-4">
      {requests.length > 0 && (
        <section data-testid="host-requests" className="rounded-2xl border border-gray-200 p-4 dark:border-gray-700">
          <h2 className="text-sm font-extrabold">
            {t("gatherings.host.requests", { count: requests.length }) || `${requests.length} waiting to join`}
          </h2>
          <ul className="mt-2 grid gap-2">
            {requests.map((p) => {
              const src = photoUrl(p.images);
              return (
                <li key={p._id} data-testid={`host-request-${p._id}`} className="flex items-center gap-2">
                  {src ? <img src={src} alt="" className="h-8 w-8 rounded-full object-cover" /> : <span className="h-8 w-8 rounded-full bg-gray-200" />}
                  <span className="flex-1 truncate text-sm font-bold">{personName(p) || t("gatherings.detail.someone") || "A BananaTalk member"}</span>
                  <button type="button" data-testid={`host-approve-${p._id}`} disabled={busy}
                    onClick={() => run(() => decide({ id: g._id, userId: p._id, approve: true }).unwrap())}
                    className="rounded-full bg-brand px-3 py-1 text-xs font-extrabold text-white">
                    {t("gatherings.host.approve") || "Approve"}
                  </button>
                  <button type="button" data-testid={`host-decline-${p._id}`} disabled={busy}
                    onClick={() => run(() => decide({ id: g._id, userId: p._id, approve: false }).unwrap())}
                    className="rounded-full border border-gray-300 px-3 py-1 text-xs font-bold">
                    {t("gatherings.host.decline") || "Decline"}
                  </button>
                </li>
              );
            })}
          </ul>
        </section>
      )}

      {isHostDecisionDue(g, at) && (
        <section data-testid="host-decision" className="rounded-2xl bg-amber-50 p-4 text-amber-900">
          <p className="text-sm font-bold">
            {g.going <= 1
              ? t("gatherings.host.decisionAlone") || "Only you are coming so far. Run it anyway, or call it off?"
              : t("gatherings.host.decision", { count: g.going }) || `Only ${g.going} people are coming so far. Run it anyway, or call it off?`}
          </p>
          <div className="mt-3 flex gap-2">
            <button type="button" data-testid="host-run-anyway" disabled={busy}
              onClick={() => run(() => decision({ id: g._id, run: true }).unwrap())}
              className="flex-1 rounded-full bg-brand px-4 py-2 text-sm font-extrabold text-white">
              {t("gatherings.host.runAnyway") || "Run it anyway"}
            </button>
            <button type="button" data-testid="host-call-off" disabled={busy} onClick={() => setConfirm("callOff")}
              className="flex-1 rounded-full border-2 border-amber-700 px-4 py-2 text-sm font-extrabold">
              {t("gatherings.host.callOff") || "Call it off"}
            </button>
          </div>
        </section>
      )}

      {started && (
        <button type="button" data-testid="host-end" disabled={busy}
          onClick={() => run(() => end(g._id).unwrap(), t("gatherings.host.ended") || "Ended — message anyone you met, it's free")}
          className="w-full rounded-full bg-brand px-5 py-3 font-extrabold text-white">
          {t("gatherings.host.end") || "End gathering"}
        </button>
      )}

      <button type="button" data-testid="host-cancel" disabled={busy} onClick={() => setConfirm("cancel")}
        className="w-full rounded-full px-5 py-2 text-sm font-bold text-red-700">
        {t("gatherings.host.cancel") || "Cancel gathering"}
      </button>

      {confirm && (
        <ConfirmDialog
          title={confirm === "callOff" ? t("gatherings.host.callOffTitle") || "Call it off?" : t("gatherings.host.cancelTitle") || "Cancel this gathering?"}
          body={
            expecting === 0
              ? t("gatherings.host.nobodyExpecting") || "Nobody else has said yes yet."
              : t("gatherings.host.cancelConfirm", { count: expecting }) ||
                `${expecting} ${expecting === 1 ? "person is" : "people are"} expecting this. They'll be told it's off.`
          }
          confirmLabel={confirm === "callOff" ? t("gatherings.host.callOff") || "Call it off" : t("gatherings.host.cancelOk") || "Cancel gathering"}
          danger
          busy={busy}
          onConfirm={() =>
            run(() => (confirm === "callOff" ? decision({ id: g._id, run: false }).unwrap() : cancel(g._id).unwrap()))
          }
          onCancel={() => setConfirm("")}
        />
      )}
    </div>
  );
};

export default GatheringHostPanel;
```

In `src/components/gatherings/GatheringDetail.tsx`: add `import GatheringHostPanel from "./GatheringHostPanel";` and, directly after the closing `)}` of the `{state === "host" && ( <Link … gathering-edit-link …/> )}` block, add:

```tsx
        {state === "host" && <GatheringHostPanel gathering={g} />}
```

Add to `eng.json` (`gatherings.host`):

```json
"host": {
  "approve": "Approve",
  "callOff": "Call it off",
  "callOffTitle": "Call it off?",
  "cancel": "Cancel gathering",
  "cancelConfirm_one": "{{count}} person is expecting this. They'll be told it's off.",
  "cancelConfirm_other": "{{count}} people are expecting this. They'll be told it's off.",
  "cancelOk": "Cancel gathering",
  "cancelTitle": "Cancel this gathering?",
  "decision_one": "Only {{count}} person is coming so far. Run it anyway, or call it off?",
  "decision_other": "Only {{count}} people are coming so far. Run it anyway, or call it off?",
  "decisionAlone": "Only you are coming so far. Run it anyway, or call it off?",
  "decline": "Decline",
  "end": "End gathering",
  "ended": "Ended — message anyone you met, it's free",
  "nobodyExpecting": "Nobody else has said yes yet.",
  "requests_one": "{{count}} waiting to join",
  "requests_other": "{{count}} waiting to join",
  "runAnyway": "Run it anyway"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false GatheringHostPanel GatheringDetail
```
Expected: 9 panel cases + 11 detail cases pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/GatheringHostPanel.tsx src/components/gatherings/GatheringHostPanel.test.tsx src/components/gatherings/GatheringDetail.tsx src/components/gatherings/GatheringDetail.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(gatherings): host decisions on the gathering page

Approve or decline join requests (a full gathering says so), the app's
T-2h "run it anyway or call it off?" question (gone once answered),
End once the start has passed, and Cancel behind a confirmation that
says how many people are expecting it.

Still open (Phase 4 gatherings): clubs, covers, routes behind
webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-7: Club page: members and roles, join/leave, upcoming gatherings, manage members

**Files:**
- Create: `src/components/gatherings/ClubDetail.tsx`, `src/components/gatherings/ClubPeople.tsx`
- Modify: `src/utils/locales/eng.json` (`clubs.detail.*`, `clubs.people.*`)
- Test: `src/components/gatherings/ClubDetail.test.tsx`, `src/components/gatherings/ClubPeople.test.tsx` (new)

**Interfaces:**
- Consumes: `useGetClubQuery(id)` → club + `upcoming`, `pastCount`, `gatherings[]` (`controllers/clubs.js:164-221`; 404 for a blocked owner); `useJoinClubMutation` (one tap, no approval; 400 "This club is archived", 400 "You are already a member", `:224-264`), `useLeaveClubMutation` (owner → 400 "The owner cannot leave their own club", `:267-290`); `useRemoveClubMemberMutation` (owner or organizer; the owner cannot be removed; only the owner removes an organizer, `:384-425`); `useSetClubMemberRoleMutation` (owner only; role `organizer` | `member`, `:428-459`). `members` is a preview — owner first, then organizers, then the 12 most recent (`lib/clubMembers.js:16,44-56`), each `{_id, name, username, images, role, joinedAt}`; `roleCounts {owner, organizer, member}`; `viewerCanManage` (owner or organizer), `viewerIsOwner`, `viewerIsMember`. App reference: `club_detail_screen.dart`, `club_people_section.dart`. `GatheringCard` (P4-GATH-3), `GatheringSafetyMenu`, `ConfirmDialog` (P4-GATH-4), `gatheringErrorText`, `personId`, `personName` (P4-GATH-2).
- Produces: default export `ClubDetail` (reads `:id`). `ClubPeople` props `{ club: Club }`. Testids: `club-detail`, `club-unavailable`, `club-join`, `club-leave`, `club-owner-note`, `club-edit-link`, `club-host-gathering-link`, `club-gatherings`, `club-no-gatherings`, `club-people`, `club-member-<userId>`, `club-member-role-<userId>`, `club-member-menu-<userId>`, `club-make-organizer-<userId>`, `club-make-member-<userId>`, `club-remove-<userId>`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/gatherings/ClubPeople.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import ClubPeople from "./ClubPeople";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: (m: any) => mockError(m) } }));
const mockRemove = jest.fn();
const mockRole = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useRemoveClubMemberMutation: () => [mockRemove, { isLoading: false }],
  useSetClubMemberRoleMutation: () => [mockRole, { isLoading: false }],
}));

const members = [
  { _id: "own", name: "Olga", username: "olga", images: [], role: "owner" },
  { _id: "org", name: "Omar", username: "omar", images: [], role: "organizer" },
  { _id: "mem", name: "Mina", username: "mina", images: [], role: "member" },
];
const club = (extra: any = {}) => ({
  _id: "c1",
  name: "Seoul readers",
  language: "korean",
  memberCount: 3,
  members,
  roleCounts: { owner: 1, organizer: 1, member: 1 },
  viewerCanManage: false,
  viewerIsMember: true,
  viewerIsOwner: false,
  owner: { _id: "own" },
  ...extra,
});
function renderPeople(c: any, me = "mem") {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: me } } }) => s } });
  return render(
    <Provider store={store}>
      <ClubPeople club={c} />
    </Provider>
  );
}

beforeEach(() => {
  [mockRemove, mockRole, mockError].forEach((m) => m.mockReset());
  mockRemove.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockRole.mockReturnValue({ unwrap: () => Promise.resolve({ data: { userId: "mem", role: "organizer" } }) });
});

it("shows owner first, organizers, then members, with role labels", () => {
  renderPeople(club());
  const rows = screen.getAllByTestId(/^club-member-(own|org|mem)$/);
  expect(rows.map((r) => r.getAttribute("data-testid"))).toEqual(["club-member-own", "club-member-org", "club-member-mem"]);
  expect(screen.getByTestId("club-member-role-own")).toHaveTextContent("Owner");
  expect(screen.getByTestId("club-member-role-org")).toHaveTextContent("Organizer");
});

it("offers no management to a plain member", () => {
  renderPeople(club());
  expect(screen.queryByTestId("club-member-menu-mem")).not.toBeInTheDocument();
});

it("the owner can promote, demote and remove, but never touch themselves", async () => {
  renderPeople(club({ viewerCanManage: true, viewerIsOwner: true }), "own");
  expect(screen.queryByTestId("club-member-menu-own")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("club-member-menu-mem"));
  fireEvent.click(screen.getByTestId("club-make-organizer-mem"));
  await waitFor(() => expect(mockRole).toHaveBeenCalledWith({ id: "c1", userId: "mem", role: "organizer" }));
  fireEvent.click(screen.getByTestId("club-member-menu-org"));
  fireEvent.click(screen.getByTestId("club-make-member-org"));
  await waitFor(() => expect(mockRole).toHaveBeenCalledWith({ id: "c1", userId: "org", role: "member" }));
  fireEvent.click(screen.getByTestId("club-member-menu-mem"));
  fireEvent.click(screen.getByTestId("club-remove-mem"));
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockRemove).toHaveBeenCalledWith({ id: "c1", userId: "mem" }));
});

it("an organizer can remove members but not organizers, and cannot change roles", () => {
  renderPeople(club({ viewerCanManage: true }), "org");
  expect(screen.queryByTestId("club-member-menu-org")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("club-member-menu-mem"));
  expect(screen.getByTestId("club-remove-mem")).toBeInTheDocument();
  expect(screen.queryByTestId("club-make-organizer-mem")).not.toBeInTheDocument();
});

it("says so when a role change is refused", async () => {
  mockRole.mockReturnValue({ unwrap: () => Promise.reject({ status: 403, data: { error: "Only the club owner can change roles" } }) });
  renderPeople(club({ viewerCanManage: true, viewerIsOwner: true }), "own");
  fireEvent.click(screen.getByTestId("club-member-menu-mem"));
  fireEvent.click(screen.getByTestId("club-make-organizer-mem"));
  await waitFor(() => expect(mockError).toHaveBeenCalledWith("Something went wrong. Try again."));
});
```

Create `src/components/gatherings/ClubDetail.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import ClubDetail from "./ClubDetail";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: (m: any) => mockError(m) } }));
let mockQuery: any;
const mockJoin = jest.fn();
const mockLeave = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useGetClubQuery: () => mockQuery,
  useJoinClubMutation: () => [mockJoin, { isLoading: false }],
  useLeaveClubMutation: () => [mockLeave, { isLoading: false }],
}));
jest.mock("./ClubPeople", () => () => <div data-testid="club-people" />);
jest.mock("./GatheringSafetyMenu", () => () => <div data-testid="safety-menu" />);
jest.mock("./GatheringCard", () => (p: any) => <div data-testid={`gathering-card-${p.gathering._id}`} />);
jest.mock("./ClubOwnerActions", () => () => <div data-testid="club-owner-actions" />);

const club = (extra: any = {}) => ({
  _id: "c1",
  name: "Seoul readers",
  description: "Books in Korean",
  language: "korean",
  languageLabel: "Korean",
  interest: "books",
  city: "Seoul",
  place: { name: "Cafe Ink", address: null },
  memberCount: 12,
  members: [],
  roleCounts: { owner: 1, organizer: 0, member: 11 },
  viewerCanManage: false,
  viewerIsMember: false,
  viewerIsOwner: false,
  owner: { _id: "own", name: "Olga" },
  upcoming: 1,
  pastCount: 11,
  gatherings: [{ _id: "g1" }],
  ...extra,
});
const ok = (data: any) => ({ data, isLoading: false, isError: false });
function renderClub() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/clubs/c1"]}>
        <Routes>
          <Route path="/clubs/:id" element={<ClubDetail />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  [mockJoin, mockLeave, mockError].forEach((m) => m.mockReset());
  mockJoin.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockLeave.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockQuery = ok(club());
});

it("shows the club, where it meets, its history and its upcoming gatherings", () => {
  renderClub();
  const page = screen.getByTestId("club-detail");
  expect(page).toHaveTextContent("Seoul readers");
  expect(page).toHaveTextContent("Cafe Ink");
  expect(page).toHaveTextContent("Seoul");
  expect(page).toHaveTextContent("Met 11 times");
  expect(screen.getByTestId("gathering-card-g1")).toBeInTheDocument();
  expect(screen.getByTestId("club-people")).toBeInTheDocument();
});

it("joins in one tap; a non-member cannot host for the club", async () => {
  renderClub();
  expect(screen.queryByTestId("club-host-gathering-link")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("club-join"));
  await waitFor(() => expect(mockJoin).toHaveBeenCalledWith("c1"));
});

it("a member can leave (after confirming) and host a gathering for the club", async () => {
  mockQuery = ok(club({ viewerIsMember: true }));
  renderClub();
  expect(screen.getByTestId("club-host-gathering-link")).toHaveAttribute("href", "/gatherings/new?club=c1");
  fireEvent.click(screen.getByTestId("club-leave"));
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockLeave).toHaveBeenCalledWith("c1"));
});

it("the owner sees no Leave, a note instead, and the owner actions", () => {
  mockQuery = ok(club({ viewerIsMember: true, viewerIsOwner: true, viewerCanManage: true }));
  renderClub();
  expect(screen.queryByTestId("club-leave")).not.toBeInTheDocument();
  expect(screen.getByTestId("club-owner-note")).toBeInTheDocument();
  expect(screen.getByTestId("club-edit-link")).toHaveAttribute("href", "/clubs/c1/edit");
  expect(screen.getByTestId("club-owner-actions")).toBeInTheDocument();
});

it("an empty club says nothing is planned yet", () => {
  mockQuery = ok(club({ gatherings: [], upcoming: 0, pastCount: 0 }));
  renderClub();
  expect(screen.getByTestId("club-no-gatherings")).toBeInTheDocument();
});

it("a missing, deleted or blocked club is 'not available'", () => {
  mockQuery = { data: undefined, isLoading: false, isError: true };
  renderClub();
  expect(screen.getByTestId("club-unavailable")).toHaveTextContent("This club isn't available.");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false ClubPeople ClubDetail
```
Expected: FAIL — `Cannot find module './ClubPeople'` / `'./ClubDetail'` (and `./ClubOwnerActions`, created in P4-GATH-8; this task creates a stub of it, see Step 3).

- [ ] **Step 3: Implement**

Create `src/components/gatherings/ClubPeople.tsx`:

```tsx
import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import { Club, ClubMember, useRemoveClubMemberMutation, useSetClubMemberRoleMutation } from "../../store/slices/gatheringsSlice";
import { gatheringErrorText, personName } from "./lib/gatheringFormat";
import ConfirmDialog from "./ConfirmDialog";
import { photoUrl } from "../../utils/photoUrl";

const RANK: { [role: string]: number } = { owner: 0, organizer: 1, member: 2 };

/**
 * Who runs the club, then who is in it (the server's preview: owner,
 * organizers, the 12 newest -- lib/clubMembers.js). Management follows the
 * server's rules: owner or organizer removes, only the owner removes an
 * organizer or changes roles, nobody touches the owner.
 */
const ClubPeople: React.FC<{ club: Club }> = ({ club }) => {
  const { t } = useTranslation();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id);
  const [removeMember] = useRemoveClubMemberMutation();
  const [setRole] = useSetClubMemberRoleMutation();
  const [menu, setMenu] = useState("");
  const [removing, setRemoving] = useState<ClubMember | null>(null);
  const [busy, setBusy] = useState(false);

  const members = (club.members || []).slice().sort((a, b) => (RANK[a.role] ?? 2) - (RANK[b.role] ?? 2));
  const canManage = (m: ClubMember) => {
    if (!club.viewerCanManage || m.role === "owner" || String(m._id) === String(me)) return false;
    if (m.role === "organizer" && !club.viewerIsOwner) return false;
    return true;
  };
  const roleText = (role: string) =>
    role === "owner"
      ? t("clubs.people.owner") || "Owner"
      : role === "organizer"
      ? t("clubs.people.organizer") || "Organizer"
      : "";

  const act = async (fn: () => Promise<any>) => {
    setBusy(true);
    try {
      await fn();
      setMenu("");
      setRemoving(null);
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    } finally {
      setBusy(false);
    }
  };

  return (
    <section data-testid="club-people" className="mt-6">
      <h2 className="text-sm font-extrabold">
        {t("clubs.people.title", { count: club.memberCount || members.length }) || `Members · ${club.memberCount || members.length}`}
      </h2>
      <ul className="mt-2 grid gap-2">
        {members.map((m) => {
          const src = photoUrl(m.images);
          return (
            <li key={m._id} data-testid={`club-member-${m._id}`} className="relative flex items-center gap-2">
              {src ? <img src={src} alt="" className="h-8 w-8 rounded-full object-cover" /> : <span className="h-8 w-8 rounded-full bg-gray-200" />}
              <span className="flex-1 truncate text-sm font-bold">{personName(m) || t("gatherings.detail.someone") || "A BananaTalk member"}</span>
              <span data-testid={`club-member-role-${m._id}`} className="text-xs text-gray-500">{roleText(m.role)}</span>
              {canManage(m) && (
                <button type="button" data-testid={`club-member-menu-${m._id}`} aria-label={t("gatherings.safety.more") || "More"}
                  className="px-2 text-lg leading-none" onClick={() => setMenu(menu === m._id ? "" : m._id)}>
                  ⋯
                </button>
              )}
              {menu === m._id && (
                <div role="menu" className="absolute end-0 top-8 z-10 w-48 rounded-xl border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-900">
                  {club.viewerIsOwner && m.role === "member" && (
                    <button type="button" role="menuitem" data-testid={`club-make-organizer-${m._id}`} disabled={busy}
                      className="block w-full px-4 py-2 text-start text-sm"
                      onClick={() => act(() => setRole({ id: club._id, userId: m._id, role: "organizer" }).unwrap())}>
                      {t("clubs.people.makeOrganizer") || "Make organizer"}
                    </button>
                  )}
                  {club.viewerIsOwner && m.role === "organizer" && (
                    <button type="button" role="menuitem" data-testid={`club-make-member-${m._id}`} disabled={busy}
                      className="block w-full px-4 py-2 text-start text-sm"
                      onClick={() => act(() => setRole({ id: club._id, userId: m._id, role: "member" }).unwrap())}>
                      {t("clubs.people.makeMember") || "Remove organizer role"}
                    </button>
                  )}
                  <button type="button" role="menuitem" data-testid={`club-remove-${m._id}`} disabled={busy}
                    className="block w-full px-4 py-2 text-start text-sm text-red-700"
                    onClick={() => { setMenu(""); setRemoving(m); }}>
                    {t("clubs.people.remove") || "Remove from club"}
                  </button>
                </div>
              )}
            </li>
          );
        })}
      </ul>
      {removing && (
        <ConfirmDialog
          title={t("clubs.people.removeTitle", { name: personName(removing) }) || `Remove ${personName(removing) || "this member"}?`}
          confirmLabel={t("clubs.people.remove") || "Remove from club"}
          danger
          busy={busy}
          onConfirm={() => act(() => removeMember({ id: club._id, userId: removing._id }).unwrap())}
          onCancel={() => setRemoving(null)}
        />
      )}
    </section>
  );
};

export default ClubPeople;
```

Create `src/components/gatherings/ClubOwnerActions.tsx` as a stub that P4-GATH-8 fills in (so this task's page compiles and is testable on its own):

```tsx
import React from "react";
import { Club } from "../../store/slices/gatheringsSlice";

/** Owner-only actions on the club page (delete). Filled in by P4-GATH-8. */
const ClubOwnerActions: React.FC<{ club: Club }> = () => null;

export default ClubOwnerActions;
```

Create `src/components/gatherings/ClubDetail.tsx`:

```tsx
import React, { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import Loader from "../Loader";
import { useGetClubQuery, useJoinClubMutation, useLeaveClubMutation } from "../../store/slices/gatheringsSlice";
import { gatheringErrorText, personId, personName } from "./lib/gatheringFormat";
import GatheringCard from "./GatheringCard";
import GatheringSafetyMenu from "./GatheringSafetyMenu";
import ConfirmDialog from "./ConfirmDialog";
import ClubPeople from "./ClubPeople";
import ClubOwnerActions from "./ClubOwnerActions";

const ClubDetail: React.FC = () => {
  const { id = "" } = useParams();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { data: club, isLoading, isError } = useGetClubQuery(id, { skip: !id });
  const [join, joinState] = useJoinClubMutation();
  const [leave, leaveState] = useLeaveClubMutation();
  const [confirmLeave, setConfirmLeave] = useState(false);
  const busy = !!(joinState && joinState.isLoading) || !!(leaveState && leaveState.isLoading);

  if (isLoading) return <Loader />;
  if (isError || !club) {
    return (
      <section data-testid="club-unavailable" className="mx-auto max-w-xl px-4 py-16 text-center">
        <p className="text-lg font-bold">{t("gatherings.errors.clubGone") || "This club isn't available."}</p>
        <Link to="/gatherings?tab=clubs" className="mt-4 inline-block font-extrabold text-brand-dark">
          {t("clubs.detail.back") || "See other clubs"}
        </Link>
      </section>
    );
  }

  const run = async (fn: () => Promise<any>) => {
    try {
      await fn();
      setConfirmLeave(false);
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    }
  };
  const gatherings = club.gatherings || [];
  const past = club.pastCount || 0;
  const where = [club.place && club.place.name, club.place && club.place.address, club.city].filter(Boolean).join(" · ");

  return (
    <article data-testid="club-detail" className="mx-auto max-w-2xl px-4 py-6 text-start">
      {club.coverImage && <img src={club.coverImage} alt="" className="mb-4 h-44 w-full rounded-2xl object-cover" />}
      <div className="flex items-start gap-2">
        <div className="min-w-0 flex-1">
          <h1 className="text-2xl font-extrabold text-gray-900 dark:text-gray-50">{club.name}</h1>
          <p className="text-sm font-bold text-brand-dark dark:text-brand-light">
            {club.languageLabel || club.language}
            {club.interest ? ` · ${club.interest}` : ""}
          </p>
        </div>
        <GatheringSafetyMenu type="club" targetId={club._id} ownerId={personId(club.owner)} ownerName={personName(club.owner)}
          onBlocked={() => navigate("/gatherings?tab=clubs")} />
      </div>

      {where && <p className="mt-2 text-sm text-gray-700 dark:text-gray-200">{where}</p>}
      <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
        {past > 0
          ? t("clubs.detail.metTimes", { count: past }) || `Met ${past} times`
          : t("clubs.detail.neverMet") || "Hasn't met yet"}
      </p>
      {club.description && <p className="mt-4 whitespace-pre-wrap">{club.description}</p>}

      <div className="mt-5 flex flex-wrap gap-2">
        {!club.viewerIsMember && (
          <button type="button" data-testid="club-join" disabled={busy} onClick={() => run(() => join(club._id).unwrap())}
            className="rounded-full bg-brand px-5 py-2 font-extrabold text-white">
            {t("clubs.detail.join") || "Join club"}
          </button>
        )}
        {club.viewerIsMember && !club.viewerIsOwner && (
          <button type="button" data-testid="club-leave" disabled={busy} onClick={() => setConfirmLeave(true)}
            className="rounded-full border-2 border-gray-300 px-5 py-2 font-extrabold">
            {t("clubs.detail.leave") || "Leave club"}
          </button>
        )}
        {club.viewerIsOwner && (
          <p data-testid="club-owner-note" className="rounded-full bg-gray-100 px-4 py-2 text-sm dark:bg-gray-800">
            {t("clubs.detail.youOwn") || "You own this club"}
          </p>
        )}
        {club.viewerCanManage && (
          <Link to={`/clubs/${club._id}/edit`} data-testid="club-edit-link" className="rounded-full border-2 border-brand px-5 py-2 font-extrabold text-brand-dark no-underline">
            {t("clubs.detail.edit") || "Edit club"}
          </Link>
        )}
      </div>

      <section className="mt-6">
        <div className="flex items-center">
          <h2 className="text-sm font-extrabold">{t("clubs.detail.upcoming") || "Coming up"}</h2>
          {club.viewerIsMember && (
            <Link to={`/gatherings/new?club=${club._id}`} data-testid="club-host-gathering-link" className="ms-auto text-sm font-extrabold text-brand-dark">
              {t("clubs.detail.host") || "Host a gathering for this club"}
            </Link>
          )}
        </div>
        {gatherings.length === 0 ? (
          <p data-testid="club-no-gatherings" className="mt-2 rounded-xl bg-gray-50 p-4 text-sm dark:bg-gray-800">
            {t("clubs.detail.noGatherings") || "Nothing planned yet."}
          </p>
        ) : (
          <div data-testid="club-gatherings" className="mt-2 grid gap-3">
            {gatherings.map((g) => (
              <GatheringCard key={g._id} gathering={g} />
            ))}
          </div>
        )}
      </section>

      <ClubPeople club={club} />
      {club.viewerIsOwner && <ClubOwnerActions club={club} />}

      {confirmLeave && (
        <ConfirmDialog
          title={t("clubs.detail.leaveTitle") || "Leave this club?"}
          confirmLabel={t("clubs.detail.leave") || "Leave club"}
          busy={busy}
          onConfirm={() => run(() => leave(club._id).unwrap())}
          onCancel={() => setConfirmLeave(false)}
        />
      )}
    </article>
  );
};

export default ClubDetail;
```

Add to `eng.json` (merge into `clubs`):

```json
"detail": {
  "back": "See other clubs",
  "edit": "Edit club",
  "host": "Host a gathering for this club",
  "join": "Join club",
  "leave": "Leave club",
  "leaveTitle": "Leave this club?",
  "metTimes_one": "Met once",
  "metTimes_other": "Met {{count}} times",
  "neverMet": "Hasn't met yet",
  "noGatherings": "Nothing planned yet.",
  "upcoming": "Coming up",
  "youOwn": "You own this club"
},
"people": {
  "makeMember": "Remove organizer role",
  "makeOrganizer": "Make organizer",
  "organizer": "Organizer",
  "owner": "Owner",
  "remove": "Remove from club",
  "removeTitle": "Remove {{name}}?",
  "title": "Members · {{count}}"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false ClubPeople ClubDetail
```
Expected: 5 people cases + 6 detail cases pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/ClubDetail.tsx src/components/gatherings/ClubPeople.tsx src/components/gatherings/ClubOwnerActions.tsx src/components/gatherings/ClubDetail.test.tsx src/components/gatherings/ClubPeople.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(clubs): club page with members, roles, join/leave and upcoming

Where it meets, how often it has met, what is coming up; join in one
tap, leave after confirming (never offered to the owner); members host
gatherings for the club; owner/organizers manage members with the
server's rules (only the owner changes roles or removes organizers,
nobody touches the owner). Report club / block the owner.

Still open (Phase 4 gatherings): club create/edit/delete, covers,
routes behind webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-8: Create, edit and delete a club

**Files:**
- Create: `src/components/gatherings/ClubForm.tsx`
- Modify: `src/components/gatherings/ClubOwnerActions.tsx` (replace the P4-GATH-7 stub)
- Modify: `src/utils/locales/eng.json` (`clubs.form.*`, `clubs.owner.*`)
- Test: `src/components/gatherings/ClubForm.test.tsx`, `src/components/gatherings/ClubOwnerActions.test.tsx` (new)

**Interfaces:**
- Consumes: `useCreateClubMutation` (`POST /clubs {name, description, language, interest}`; name required; language required and matched to a key; the creator becomes owner and member #1, `controllers/clubs.js:70-105`), `useUpdateClubMutation` (`PUT /clubs/:id` with any of `{name, description, interest, city, place: {name, address}}`; **language is not editable**; owner or organizer, `:307-353`), `useDeleteClubMutation` (owner only; the club's gatherings are kept — people RSVP'd to them, `:356-381`), `useGetClubQuery`. Model limits (`be/models/Club.js:34-51`): name ≤ 80, description ≤ 2000, interest ≤ 60. App reference: `create_club_sheet.dart` (create: name, language, description, interest). `languageOptions` (P3-COM-3), `gatheringErrorText` (P4-GATH-2), `ConfirmDialog` (P4-GATH-4).
- Produces: default export `ClubForm` props `{ mode: "create" | "edit" }` (edit reads `:id`; only `viewerCanManage` may edit). `ClubOwnerActions` props `{ club: Club }` (testids `club-delete`, then `confirm-ok`). Form testids: `club-form`, `cf-name`, `cf-language`, `cf-description`, `cf-interest`, `cf-city`, `cf-place-name`, `cf-place-address`, `cf-submit`, `cf-error-<field>`, `cf-server-error`, `cf-not-allowed`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/gatherings/ClubForm.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import ClubForm from "./ClubForm";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockCreate = jest.fn();
const mockUpdate = jest.fn();
let mockQuery: any = { data: undefined, isLoading: false, isError: false };
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useCreateClubMutation: () => [mockCreate, { isLoading: false }],
  useUpdateClubMutation: () => [mockUpdate, { isLoading: false }],
  useGetClubQuery: () => mockQuery,
}));
jest.mock("../../store/slices/communitySlice", () => ({ useGetLanguagesQuery: () => ({ data: { data: [] } }) }));
jest.mock("../community/lib/languageOptions", () => ({
  languageOptions: () => [{ value: "Korean", label: "Korean" }],
}));

function Where() {
  return <div data-testid="where">{useLocation().pathname}</div>;
}
function renderForm(path: string) {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me", language_to_learn: "Korean" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Routes>
          <Route path="/clubs/new" element={<ClubForm mode="create" />} />
          <Route path="/clubs/:id/edit" element={<ClubForm mode="edit" />} />
          <Route path="/clubs/:id" element={<Where />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}
const type = (id: string, value: string) => fireEvent.change(screen.getByTestId(id), { target: { value } });

beforeEach(() => {
  mockCreate.mockReset();
  mockUpdate.mockReset();
  mockQuery = { data: undefined, isLoading: false, isError: false };
});

it("creates a club with the app's four fields and opens it", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.resolve({ _id: "c9" }) });
  renderForm("/clubs/new");
  expect(screen.queryByTestId("cf-city")).not.toBeInTheDocument();
  type("cf-name", "  Seoul readers ");
  type("cf-description", "Books");
  type("cf-interest", "books");
  fireEvent.click(screen.getByTestId("cf-submit"));
  await waitFor(() =>
    expect(mockCreate).toHaveBeenCalledWith({ name: "Seoul readers", description: "Books", language: "Korean", interest: "books" })
  );
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/clubs/c9"));
});

it("requires a name (<= 80) and a language; interest <= 60", () => {
  renderForm("/clubs/new");
  fireEvent.click(screen.getByTestId("cf-submit"));
  expect(screen.getByTestId("cf-error-name")).toHaveTextContent("Give your club a name.");
  type("cf-name", "x".repeat(81));
  type("cf-interest", "y".repeat(61));
  fireEvent.change(screen.getByTestId("cf-language"), { target: { value: "" } });
  fireEvent.click(screen.getByTestId("cf-submit"));
  expect(screen.getByTestId("cf-error-name")).toHaveTextContent("80");
  expect(screen.getByTestId("cf-error-interest")).toHaveTextContent("60");
  expect(screen.getByTestId("cf-error-language")).toBeInTheDocument();
  expect(mockCreate).not.toHaveBeenCalled();
});

const existing = {
  _id: "c1",
  name: "Seoul readers",
  description: "Books",
  language: "korean",
  languageLabel: "Korean",
  interest: "books",
  city: null,
  place: null,
  memberCount: 3,
  members: [],
  viewerCanManage: true,
  viewerIsMember: true,
  viewerIsOwner: true,
};

it("edits only what changed, with city and meeting place; language is shown but fixed", async () => {
  mockQuery = { data: existing, isLoading: false, isError: false };
  mockUpdate.mockReturnValue({ unwrap: () => Promise.resolve(existing) });
  renderForm("/clubs/c1/edit");
  expect(screen.getByTestId("cf-language")).toBeDisabled();
  type("cf-city", "Seoul");
  type("cf-place-name", "Cafe Ink");
  fireEvent.click(screen.getByTestId("cf-submit"));
  await waitFor(() =>
    expect(mockUpdate).toHaveBeenCalledWith({ id: "c1", body: { city: "Seoul", place: { name: "Cafe Ink", address: null } } })
  );
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/clubs/c1"));
});

it("clearing the city sends null", async () => {
  mockQuery = { data: { ...existing, city: "Seoul" }, isLoading: false, isError: false };
  mockUpdate.mockReturnValue({ unwrap: () => Promise.resolve(existing) });
  renderForm("/clubs/c1/edit");
  type("cf-city", "");
  fireEvent.click(screen.getByTestId("cf-submit"));
  await waitFor(() => expect(mockUpdate).toHaveBeenCalledWith({ id: "c1", body: { city: null } }));
});

it("only the owner or an organizer can edit", () => {
  mockQuery = { data: { ...existing, viewerCanManage: false }, isLoading: false, isError: false };
  renderForm("/clubs/c1/edit");
  expect(screen.getByTestId("cf-not-allowed")).toBeInTheDocument();
});

it("shows a server refusal in the form", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.reject({ status: "FETCH_ERROR" }) });
  renderForm("/clubs/new");
  type("cf-name", "Club");
  fireEvent.click(screen.getByTestId("cf-submit"));
  await waitFor(() => expect(screen.getByTestId("cf-server-error")).toHaveTextContent("You're offline"));
});
```

Create `src/components/gatherings/ClubOwnerActions.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import ClubOwnerActions from "./ClubOwnerActions";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: (m: any) => mockError(m) } }));
const mockDelete = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useDeleteClubMutation: () => [mockDelete, { isLoading: false }],
}));

const club: any = { _id: "c1", name: "Seoul readers", memberCount: 5, upcoming: 2, viewerIsOwner: true };
function renderActions(c: any = club) {
  return render(
    <MemoryRouter initialEntries={["/clubs/c1"]}>
      <Routes>
        <Route path="/clubs/:id" element={<ClubOwnerActions club={c} />} />
        <Route path="/gatherings" element={<div data-testid="list-page" />} />
      </Routes>
    </MemoryRouter>
  );
}

beforeEach(() => {
  mockDelete.mockReset();
  mockError.mockReset();
});

it("deletes after a confirmation that says the gatherings stay", async () => {
  mockDelete.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  renderActions();
  fireEvent.click(screen.getByTestId("club-delete"));
  expect(screen.getByTestId("confirm-dialog")).toHaveTextContent("gatherings already planned will still happen");
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockDelete).toHaveBeenCalledWith("c1"));
  await waitFor(() => expect(screen.getByTestId("list-page")).toBeInTheDocument());
});

it("renders nothing for anyone but the owner", () => {
  const { container } = renderActions({ ...club, viewerIsOwner: false });
  expect(container).toBeEmptyDOMElement();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false ClubForm ClubOwnerActions
```
Expected: FAIL — `Cannot find module './ClubForm'`; the owner-actions cases fail because the stub renders nothing.

- [ ] **Step 3: Implement**

Create `src/components/gatherings/ClubForm.tsx`:

```tsx
import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import Loader from "../Loader";
import { useCreateClubMutation, useUpdateClubMutation, useGetClubQuery } from "../../store/slices/gatheringsSlice";
import { useGetLanguagesQuery } from "../../store/slices/communitySlice";
import { languageOptions } from "../community/lib/languageOptions";
import { gatheringErrorText } from "./lib/gatheringFormat";

const NAME_MAX = 80;
const DESCRIPTION_MAX = 2000;
const INTEREST_MAX = 60;

interface ClubValues {
  name: string;
  language: string;
  description: string;
  interest: string;
  city: string;
  placeName: string;
  placeAddress: string;
}

const ERROR_TEXT: { [k: string]: string } = {
  nameRequired: "Give your club a name.",
  nameTooLong: "Keep the name under 80 characters.",
  languageRequired: "Pick the club's language.",
  descriptionTooLong: "Keep the description under 2000 characters.",
  interestTooLong: "Keep the interest under 60 characters.",
};

export function validateClub(v: ClubValues, mode: "create" | "edit"): { [k: string]: string } {
  const e: { [k: string]: string } = {};
  const name = v.name.trim();
  if (!name) e.name = "nameRequired";
  else if (name.length > NAME_MAX) e.name = "nameTooLong";
  if (mode === "create" && !v.language) e.language = "languageRequired";
  if (v.description.length > DESCRIPTION_MAX) e.description = "descriptionTooLong";
  if (v.interest.trim().length > INTEREST_MAX) e.interest = "interestTooLong";
  return e;
}

const field = "mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 dark:border-gray-600 dark:bg-gray-900";
const orNull = (s: string) => (s.trim() ? s.trim() : null);

const ClubForm: React.FC<{ mode: "create" | "edit" }> = ({ mode }) => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const target = useSelector(
    (s: any) => (s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user.language_to_learn) || ""
  );
  const existing = useGetClubQuery(id, { skip: mode !== "edit" || !id });
  const [createClub, createState] = useCreateClubMutation();
  const [updateClub, updateState] = useUpdateClubMutation();
  const busy = !!(createState && createState.isLoading) || !!(updateState && updateState.isLoading);
  const [v, setV] = useState<ClubValues>({
    name: "",
    language: String(target).replace(/\s*\([^)]*\)\s*$/, ""),
    description: "",
    interest: "",
    city: "",
    placeName: "",
    placeAddress: "",
  });
  const [loadedId, setLoadedId] = useState("");
  const [errors, setErrors] = useState<{ [k: string]: string }>({});
  const [serverError, setServerError] = useState("");
  const c = existing.data;

  useEffect(() => {
    if (mode === "edit" && c && c._id !== loadedId) {
      setV({
        name: c.name || "",
        language: c.languageLabel || c.language || "",
        description: c.description || "",
        interest: c.interest || "",
        city: c.city || "",
        placeName: (c.place && c.place.name) || "",
        placeAddress: (c.place && c.place.address) || "",
      });
      setLoadedId(c._id);
    }
  }, [mode, c, loadedId]);

  const { data: catalog } = useGetLanguagesQuery();
  const langs = useMemo(() => {
    const opts: { value: string; label: string }[] = languageOptions((catalog && catalog.data) || [], i18n.language);
    if (v.language && !opts.some((o) => o.value === v.language)) return [{ value: v.language, label: v.language }].concat(opts);
    return opts;
  }, [catalog, i18n.language, v.language]);

  if (mode === "edit") {
    if (existing.isLoading) return <Loader />;
    if (existing.isError || !c || !c.viewerCanManage) {
      return (
        <p data-testid="cf-not-allowed" className="mx-auto max-w-xl px-4 py-16 text-center font-bold">
          {t("clubs.form.notAllowed") || "Only the club's owner or an organizer can edit it."}
        </p>
      );
    }
  }

  const set = (patch: Partial<ClubValues>) => setV((x) => Object.assign({}, x, patch));
  const errorText = (key: string) => t(`clubs.form.errors.${key}`) || ERROR_TEXT[key] || key;

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setServerError("");
    const found = validateClub(v, mode);
    setErrors(found);
    if (Object.keys(found).length) return;
    try {
      if (mode === "create") {
        const created: any = await createClub({
          name: v.name.trim(),
          description: v.description.trim(),
          language: v.language,
          interest: v.interest.trim(),
        }).unwrap();
        navigate(`/clubs/${created && created._id ? created._id : ""}`, { replace: true });
      } else if (c) {
        const body: { [k: string]: any } = {};
        if (v.name.trim() !== (c.name || "")) body.name = v.name.trim();
        if (v.description.trim() !== (c.description || "")) body.description = v.description.trim();
        if (v.interest.trim() !== (c.interest || "")) body.interest = v.interest.trim();
        if (orNull(v.city) !== (c.city || null)) body.city = orNull(v.city);
        const beforePlace = { name: (c.place && c.place.name) || null, address: (c.place && c.place.address) || null };
        const afterPlace = { name: orNull(v.placeName), address: orNull(v.placeAddress) };
        if (beforePlace.name !== afterPlace.name || beforePlace.address !== afterPlace.address) {
          body.place = afterPlace;
        }
        if (Object.keys(body).length) await updateClub({ id: c._id, body }).unwrap();
        navigate(`/clubs/${c._id}`, { replace: true });
      }
    } catch (err) {
      setServerError(gatheringErrorText(err, t));
    }
  };

  const err = (name: string) =>
    errors[name] ? (
      <p data-testid={`cf-error-${name}`} className="mt-1 text-sm text-red-700">
        {errorText(errors[name])}
      </p>
    ) : null;

  return (
    <form data-testid="club-form" onSubmit={submit} noValidate className="mx-auto grid max-w-xl gap-4 px-4 py-6 text-start">
      <h1 className="text-2xl font-extrabold">
        {mode === "create" ? t("clubs.form.createTitle") || "Start a club" : t("clubs.form.editTitle") || "Edit club"}
      </h1>
      <label className="block text-sm font-bold">
        {t("clubs.form.name") || "Name"}
        <input data-testid="cf-name" className={field} value={v.name} onChange={(e) => set({ name: e.target.value })} />
        {err("name")}
      </label>
      <label className="block text-sm font-bold">
        {t("clubs.form.language") || "Language"}
        <select data-testid="cf-language" className={field} value={v.language} disabled={mode === "edit"}
          onChange={(e) => set({ language: e.target.value })}>
          <option value="">{t("gatherings.form.pickLanguage") || "Pick a language"}</option>
          {langs.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
        {err("language")}
      </label>
      <label className="block text-sm font-bold">
        {t("clubs.form.interest") || "What brings you together (e.g. books, K-drama)"}
        <input data-testid="cf-interest" className={field} value={v.interest} onChange={(e) => set({ interest: e.target.value })} />
        {err("interest")}
      </label>
      <label className="block text-sm font-bold">
        {t("clubs.form.description") || "About the club (optional)"}
        <textarea data-testid="cf-description" className={field} rows={4} value={v.description} onChange={(e) => set({ description: e.target.value })} />
        {err("description")}
      </label>
      {mode === "edit" && (
        <>
          <label className="block text-sm font-bold">
            {t("clubs.form.city") || "City (optional)"}
            <input data-testid="cf-city" className={field} value={v.city} onChange={(e) => set({ city: e.target.value })} />
          </label>
          <div className="grid grid-cols-2 gap-3">
            <label className="block text-sm font-bold">
              {t("clubs.form.placeName") || "Where you meet (optional)"}
              <input data-testid="cf-place-name" className={field} value={v.placeName} onChange={(e) => set({ placeName: e.target.value })} />
            </label>
            <label className="block text-sm font-bold">
              {t("clubs.form.placeAddress") || "Address (optional)"}
              <input data-testid="cf-place-address" className={field} value={v.placeAddress} onChange={(e) => set({ placeAddress: e.target.value })} />
            </label>
          </div>
        </>
      )}
      {serverError && (
        <p data-testid="cf-server-error" role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-800">
          {serverError}
        </p>
      )}
      <div className="flex justify-end gap-2">
        <Link to={mode === "edit" && c ? `/clubs/${c._id}` : "/gatherings?tab=clubs"} className="rounded-full px-4 py-2 font-bold">
          {t("gatherings.form.cancel") || "Cancel"}
        </Link>
        <button type="submit" data-testid="cf-submit" disabled={busy} className="rounded-full bg-brand px-5 py-2 font-extrabold text-white disabled:opacity-50">
          {mode === "create" ? t("clubs.form.create") || "Create club" : t("gatherings.form.save") || "Save"}
        </button>
      </div>
    </form>
  );
};

export default ClubForm;
```

(No `maxLength` on name/interest inputs on purpose: the test types past the limit to see the message; the validator, not the browser, is what refuses — and an IME composing Korean past a hard `maxLength` truncates mid-syllable.)

Replace `src/components/gatherings/ClubOwnerActions.tsx`:

```tsx
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import { Club, useDeleteClubMutation } from "../../store/slices/gatheringsSlice";
import { gatheringErrorText } from "./lib/gatheringFormat";
import ConfirmDialog from "./ConfirmDialog";

/**
 * Owner-only: delete the club. Its gatherings are NOT deleted
 * (controllers/clubs.js deleteClub) -- people RSVP'd to them -- and the
 * confirmation says so.
 */
const ClubOwnerActions: React.FC<{ club: Club }> = ({ club }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [del, state] = useDeleteClubMutation();
  const [confirm, setConfirm] = useState(false);
  if (!club.viewerIsOwner) return null;
  const busy = !!(state && state.isLoading);

  const doDelete = async () => {
    try {
      await del(club._id).unwrap();
      navigate("/gatherings?tab=clubs", { replace: true });
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    }
  };

  return (
    <div className="mt-8">
      <button type="button" data-testid="club-delete" onClick={() => setConfirm(true)} className="text-sm font-bold text-red-700">
        {t("clubs.owner.delete") || "Delete club"}
      </button>
      {confirm && (
        <ConfirmDialog
          title={t("clubs.owner.deleteTitle", { name: club.name }) || `Delete ${club.name}?`}
          body={t("clubs.owner.deleteBody") || "Members lose the club. Gatherings already planned will still happen."}
          confirmLabel={t("clubs.owner.delete") || "Delete club"}
          danger
          busy={busy}
          onConfirm={doDelete}
          onCancel={() => setConfirm(false)}
        />
      )}
    </div>
  );
};

export default ClubOwnerActions;
```

Add to `eng.json` (merge into `clubs`):

```json
"form": {
  "city": "City (optional)",
  "create": "Create club",
  "createTitle": "Start a club",
  "description": "About the club (optional)",
  "editTitle": "Edit club",
  "errors": {
    "descriptionTooLong": "Keep the description under 2000 characters.",
    "interestTooLong": "Keep the interest under 60 characters.",
    "languageRequired": "Pick the club's language.",
    "nameRequired": "Give your club a name.",
    "nameTooLong": "Keep the name under 80 characters."
  },
  "interest": "What brings you together (e.g. books, K-drama)",
  "language": "Language",
  "name": "Name",
  "notAllowed": "Only the club's owner or an organizer can edit it.",
  "placeAddress": "Address (optional)",
  "placeName": "Where you meet (optional)"
},
"owner": {
  "delete": "Delete club",
  "deleteBody": "Members lose the club. Gatherings already planned will still happen.",
  "deleteTitle": "Delete {{name}}?"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false ClubForm ClubOwnerActions ClubDetail
```
Expected: 6 form cases + 2 owner-action cases pass; `ClubDetail` stays green (it mocks `ClubOwnerActions`).

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/ClubForm.tsx src/components/gatherings/ClubForm.test.tsx src/components/gatherings/ClubOwnerActions.tsx src/components/gatherings/ClubOwnerActions.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(clubs): start, edit and delete a club

Create with the app's four fields (name, language, interest,
description); edit sends only changes, adds city and meeting place,
keeps the language fixed (the server does not change it); owner deletes
after a confirmation that planned gatherings still happen.

Still open (Phase 4 gatherings): covers, routes behind
webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-9: Optional cover photo for a gathering or a club

**Files:**
- Create: `src/components/gatherings/CoverEditor.tsx`
- Modify: `src/components/gatherings/GatheringHostPanel.tsx` (cover editor at the top of the panel), `src/components/gatherings/ClubDetail.tsx` (cover editor under the action buttons when `viewerCanManage`)
- Modify: `src/utils/locales/eng.json` (`gatherings.cover.*`)
- Test: `src/components/gatherings/CoverEditor.test.tsx` (new); one mock line each in `GatheringHostPanel.test.tsx` and `ClubDetail.test.tsx`

**Interfaces:**
- Consumes: `useSetGatheringCoverMutation` / `useRemoveGatheringCoverMutation` (`POST|DELETE /gatherings/:id/cover`, host only, multipart field `image`, response `data: {coverImage}`, `controllers/gatherings.js:953-996`), `useSetClubCoverMutation` / `useRemoveClubCoverMutation` (`/clubs/:id/cover`, owner or organizer, `controllers/clubs.js:476-521`). Accepted types: `image/jpeg`, `image/png`, `image/gif`, `image/webp` (`be/middleware/uploadToSpaces.js:48`); the server compresses. The server has no image-specific size cap (only the 1 GB upload ceiling); the web refuses files over 10 MB before uploading so a phone photo is fine and an accidental huge file never starts. Optional by design: a gathering or club is valid without a cover (`routes/gatherings.js:30-32`).
- Produces: default export `CoverEditor` props `{ kind: "gathering" | "club"; id: string; hasCover: boolean }`. Testids `cover-editor`, `cover-input`, `cover-remove`, `cover-error`.

- [ ] **Step 1: Write the failing test**

Create `src/components/gatherings/CoverEditor.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import CoverEditor, { COVER_MAX_BYTES } from "./CoverEditor";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: jest.fn() } }));
const mockSetG = jest.fn();
const mockRemoveG = jest.fn();
const mockSetC = jest.fn();
const mockRemoveC = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useSetGatheringCoverMutation: () => [mockSetG, { isLoading: false }],
  useRemoveGatheringCoverMutation: () => [mockRemoveG, { isLoading: false }],
  useSetClubCoverMutation: () => [mockSetC, { isLoading: false }],
  useRemoveClubCoverMutation: () => [mockRemoveC, { isLoading: false }],
}));

const ok = () => ({ unwrap: () => Promise.resolve({}) });
beforeEach(() => {
  [mockSetG, mockRemoveG, mockSetC, mockRemoveC].forEach((m) => {
    m.mockReset();
    m.mockReturnValue(ok());
  });
});
const pick = (file: File) => fireEvent.change(screen.getByTestId("cover-input"), { target: { files: [file] } });

it("uploads a gathering cover", async () => {
  render(<CoverEditor kind="gathering" id="g1" hasCover={false} />);
  const file = new File(["x"], "c.jpg", { type: "image/jpeg" });
  pick(file);
  await waitFor(() => expect(mockSetG).toHaveBeenCalledWith({ id: "g1", file }));
  expect(screen.queryByTestId("cover-remove")).not.toBeInTheDocument();
});

it("uploads and removes a club cover", async () => {
  render(<CoverEditor kind="club" id="c1" hasCover />);
  const file = new File(["x"], "c.webp", { type: "image/webp" });
  pick(file);
  await waitFor(() => expect(mockSetC).toHaveBeenCalledWith({ id: "c1", file }));
  fireEvent.click(screen.getByTestId("cover-remove"));
  await waitFor(() => expect(mockRemoveC).toHaveBeenCalledWith("c1"));
});

it("refuses a type the server does not take, and a file over 10 MB", () => {
  render(<CoverEditor kind="gathering" id="g1" hasCover={false} />);
  pick(new File(["x"], "c.heic", { type: "image/heic" }));
  expect(screen.getByTestId("cover-error")).toHaveTextContent("JPEG, PNG, GIF or WebP");
  const big = new File(["x"], "big.jpg", { type: "image/jpeg" });
  Object.defineProperty(big, "size", { value: COVER_MAX_BYTES + 1 });
  pick(big);
  expect(screen.getByTestId("cover-error")).toHaveTextContent("10 MB");
  expect(mockSetG).not.toHaveBeenCalled();
});
```

In `GatheringHostPanel.test.tsx` and `ClubDetail.test.tsx` add next to the other component mocks:

```tsx
jest.mock("./CoverEditor", () => () => <div data-testid="cover-editor" />);
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false CoverEditor
```
Expected: FAIL — `Cannot find module './CoverEditor'`.

- [ ] **Step 3: Implement**

Create `src/components/gatherings/CoverEditor.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import {
  useSetGatheringCoverMutation,
  useRemoveGatheringCoverMutation,
  useSetClubCoverMutation,
  useRemoveClubCoverMutation,
} from "../../store/slices/gatheringsSlice";
import { gatheringErrorText } from "./lib/gatheringFormat";

/** be/middleware/uploadToSpaces.js ALLOWED_IMAGE_TYPES. */
export const COVER_TYPES = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"];
/** Web-side cap; the server compresses and has no image-specific limit. */
export const COVER_MAX_BYTES = 10 * 1024 * 1024;

const CoverEditor: React.FC<{ kind: "gathering" | "club"; id: string; hasCover: boolean }> = ({ kind, id, hasCover }) => {
  const { t } = useTranslation();
  const [setG] = useSetGatheringCoverMutation();
  const [removeG] = useRemoveGatheringCoverMutation();
  const [setC] = useSetClubCoverMutation();
  const [removeC] = useRemoveClubCoverMutation();
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const run = async (fn: () => Promise<any>) => {
    setBusy(true);
    try {
      await fn();
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    } finally {
      setBusy(false);
    }
  };

  const onPick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files && e.target.files[0];
    e.target.value = "";
    setError("");
    if (!file) return;
    if (COVER_TYPES.indexOf(file.type) === -1) {
      setError(t("gatherings.cover.badType") || "Use a JPEG, PNG, GIF or WebP image.");
      return;
    }
    if (file.size > COVER_MAX_BYTES) {
      setError(t("gatherings.cover.tooBig") || "That image is over 10 MB.");
      return;
    }
    run(() => (kind === "club" ? setC({ id, file }).unwrap() : setG({ id, file }).unwrap()));
  };

  return (
    <div data-testid="cover-editor" className="flex flex-wrap items-center gap-3 text-sm">
      <label className="cursor-pointer font-extrabold text-brand-dark">
        {hasCover ? t("gatherings.cover.change") || "Change cover photo" : t("gatherings.cover.add") || "Add a cover photo"}
        <input data-testid="cover-input" type="file" accept={COVER_TYPES.join(",")} className="sr-only" disabled={busy} onChange={onPick} />
      </label>
      {hasCover && (
        <button type="button" data-testid="cover-remove" disabled={busy} className="font-bold text-gray-600"
          onClick={() => run(() => (kind === "club" ? removeC(id).unwrap() : removeG(id).unwrap()))}>
          {t("gatherings.cover.remove") || "Remove cover"}
        </button>
      )}
      {error && (
        <p data-testid="cover-error" role="alert" className="w-full text-red-700">
          {error}
        </p>
      )}
    </div>
  );
};

export default CoverEditor;
```

In `GatheringHostPanel.tsx`: `import CoverEditor from "./CoverEditor";` and make the first child of `<div data-testid="host-panel" …>`:

```tsx
      <CoverEditor kind="gathering" id={g._id} hasCover={!!g.coverImage} />
```

In `ClubDetail.tsx`: `import CoverEditor from "./CoverEditor";` and right after the closing `</div>` of the `mt-5 flex flex-wrap gap-2` action row add:

```tsx
      {club.viewerCanManage && (
        <div className="mt-3">
          <CoverEditor kind="club" id={club._id} hasCover={!!club.coverImage} />
        </div>
      )}
```

Add to `eng.json` (`gatherings.cover`):

```json
"cover": {
  "add": "Add a cover photo",
  "badType": "Use a JPEG, PNG, GIF or WebP image.",
  "change": "Change cover photo",
  "remove": "Remove cover",
  "tooBig": "That image is over 10 MB."
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false CoverEditor GatheringHostPanel ClubDetail
```
Expected: 3 cover cases pass; host panel and club page suites stay green.

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/CoverEditor.tsx src/components/gatherings/CoverEditor.test.tsx src/components/gatherings/GatheringHostPanel.tsx src/components/gatherings/GatheringHostPanel.test.tsx src/components/gatherings/ClubDetail.tsx src/components/gatherings/ClubDetail.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(gatherings): optional cover photo for gatherings and clubs

Host (gathering) or owner/organizer (club) adds, changes or removes a
cover; only the types the server takes, at most 10 MB, sent as the
multipart `image` field.

Still open (Phase 4 gatherings): routes and nav behind
webGatheringsEnabled, i18n, push.
MSG
```

---

### Task P4-GATH-10: Routes and nav entry behind `webGatheringsEnabled`; nothing visible while it is off

**Files:**
- Create: `src/components/gatherings/RequireSignIn.tsx`, `src/components/gatherings/gatheringsFlagOff.test.tsx`
- Modify: `src/router/routes.tsx` — a new lazy group after `// Courses` (`:116-117`) and a `{/* Gatherings & clubs */}` route block after `{/* Moments */}` (`:270-273`)
- Modify: `src/components/navbar/MainNavbar.tsx` — imports (`:1-30`), desktop links after the Moments `NavLink` (`:240-246`), mobile links after the Moments `NavLink` (`:406-408`)
- Modify: `src/utils/locales/eng.json` (`gatherings.nav`)

**Interfaces:**
- Consumes: `FlagRoute` (`src/router/FlagRoute.tsx`, P4-0), `useWebFlag("webGatheringsEnabled")` (`src/utils/webFlags.ts`, P4-0 — on only when `webGatheringsEnabled && gatheringsEnabled`), `mockAppConfig`, `appConfigSliceMock`, `ALL_WEB_FLAGS_OFF`, `ALL_WEB_FLAGS_ON` (`src/utils/testing/mockWebFlags.ts`, P4-0); `lazyWithRetry` (`src/router/lazyWithRetry.ts`); the login redirect pattern `/login?redirect=<path>` (`src/components/announcements/AnnouncementPage.tsx:44`).
- Produces: routes `/gatherings`, `/gatherings/new`, `/gatherings/:id`, `/gatherings/:id/edit`, `/clubs`, `/clubs/new`, `/clubs/:id`, `/clubs/:id/edit`, each `FlagRoute(webGatheringsEnabled) → RequireSignIn → Suspense → lazy page`; navbar entry `data-testid="nav-gatherings"` (desktop) / `nav-gatherings-mobile`, signed-in users only, only while the flag is on. `RequireSignIn` default export props `{ children }`.

- [ ] **Step 1: Write the failing test**

Create `src/components/gatherings/gatheringsFlagOff.test.tsx`:

```tsx
// Spec §4: while webGatheringsEnabled is false (or app-config is loading or
// failed) the website shows no gatherings/clubs nav entry, every gatherings
// and clubs path is a 404, and no page of the feature is ever loaded.
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route, matchRoutes } from "react-router-dom";
import { apiSlice } from "../../store/slices/apiSlice";
import {
  mockAppConfig,
  ALL_WEB_FLAGS_OFF,
  ALL_WEB_FLAGS_ON,
} from "../../utils/testing/mockWebFlags";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en", changeLanguage: jest.fn() } }),
}));
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: { on: jest.fn(), off: jest.fn(), emit: jest.fn(), connected: true }, isConnected: true, emit: jest.fn() }),
}));
jest.mock("../errors/NotFound", () => () => <div data-testid="not-found" />);
// If a gated route ever rendered a page while the flag is off, this would show.
jest.mock("../../router/lazyWithRetry", () => ({
  lazyWithRetry: (key: string) => () => <div data-testid={`page:${key}`} />,
}));

const PATHS = [
  "/gatherings",
  "/gatherings/new",
  "/gatherings/g1",
  "/gatherings/g1/edit",
  "/clubs",
  "/clubs/new",
  "/clubs/c1",
  "/clubs/c1/edit",
];

function store(signedIn: boolean) {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (s: any = { userInfo: signedIn ? { token: "t", user: { _id: "me", name: "Me" } } : null }) => s,
    },
    middleware: (gdm) => gdm().concat(apiSlice.middleware),
  });
}

/** Render the matched leaf route's element on its own (no App shell). */
function renderPath(path: string, signedIn = true) {
  const { routes } = require("../../router/routes");
  const matches = matchRoutes(routes, path)!;
  const leaf: any = matches[matches.length - 1].route;
  return render(
    <Provider store={store(signedIn)}>
      <MemoryRouter initialEntries={[path]}>
        <Routes>
          <Route path={`/${leaf.path}`} element={leaf.element} />
          <Route path="/login" element={<div data-testid="login-page" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

function renderNavbar(signedIn = true) {
  const MainNavbar = require("../navbar/MainNavbar").default;
  (global as any).fetch = jest.fn(async () =>
    new Response(JSON.stringify({ data: [] }), { status: 200, headers: { "Content-Type": "application/json" } })
  );
  return render(
    <Provider store={store(signedIn)}>
      <MemoryRouter>
        <MainNavbar />
      </MemoryRouter>
    </Provider>
  );
}

describe("every gatherings/clubs path resolves to a real route (not the catch-all)", () => {
  it.each(PATHS)("%s", (path) => {
    const { routes } = require("../../router/routes");
    const matches = matchRoutes(routes, path)!;
    expect(matches[matches.length - 1].route.path).not.toBe("*");
  });
});

describe("flag OFF: 404 and no page loaded", () => {
  beforeEach(() => mockAppConfig(ALL_WEB_FLAGS_OFF));
  it.each(PATHS)("%s", (path) => {
    renderPath(path);
    expect(screen.getByTestId("not-found")).toBeInTheDocument();
    expect(screen.queryByTestId(/^page:/)).not.toBeInTheDocument();
  });
});

it("flag on but GATHERINGS_ENABLED off: still a 404", () => {
  mockAppConfig({ ...ALL_WEB_FLAGS_ON, gatheringsEnabled: false });
  renderPath("/gatherings");
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
});

it("app-config failed: 404", () => {
  mockAppConfig("error");
  renderPath("/clubs/c1");
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
});

it("app-config loading: a spinner, never the page", () => {
  mockAppConfig("loading");
  renderPath("/gatherings/g1");
  expect(screen.getByTestId("flag-route-loading")).toBeInTheDocument();
  expect(screen.queryByTestId(/^page:/)).not.toBeInTheDocument();
});

it("flag ON: the page loads for a signed-in user", async () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderPath("/gatherings/g1");
  expect(await screen.findByTestId("page:../components/gatherings/GatheringDetail")).toBeInTheDocument();
});

it("flag ON, signed out: sent to login with a way back", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderPath("/clubs/c1", false);
  expect(screen.getByTestId("login-page")).toBeInTheDocument();
});

describe("navbar", () => {
  it("has no gatherings entry while the flag is off", () => {
    mockAppConfig(ALL_WEB_FLAGS_OFF);
    renderNavbar();
    expect(screen.queryByTestId("nav-gatherings")).not.toBeInTheDocument();
    expect(screen.queryByTestId("nav-gatherings-mobile")).not.toBeInTheDocument();
    expect(document.querySelector('a[href^="/gatherings"], a[href^="/clubs"]')).toBe(null);
  });

  it("shows the entry to signed-in users once the flag is on", () => {
    mockAppConfig(ALL_WEB_FLAGS_ON);
    renderNavbar();
    expect(screen.getByTestId("nav-gatherings")).toHaveAttribute("href", "/gatherings");
  });

  it("never shows it to a signed-out visitor", () => {
    mockAppConfig(ALL_WEB_FLAGS_ON);
    renderNavbar(false);
    expect(screen.queryByTestId("nav-gatherings")).not.toBeInTheDocument();
  });
});
```

(The mobile menu renders its links only while open; `nav-gatherings-mobile` is asserted absent in the closed state above and present in Step 4's manual check. The desktop assertion is the binding one.)

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings && CI=true npm test -- --watchAll=false gatheringsFlagOff
```
Expected: FAIL — the eight paths match the `*` catch-all (first `describe`), and "flag ON" cases find no page; navbar "flag on" finds no `nav-gatherings`.

- [ ] **Step 3: Implement**

Create `src/components/gatherings/RequireSignIn.tsx`:

```tsx
import React from "react";
import { useSelector } from "react-redux";
import { Navigate, useLocation } from "react-router-dom";

/**
 * Gatherings and clubs are private (`protect` on every route). A signed-out
 * visitor goes to login and comes back -- the AnnouncementPage pattern.
 */
const RequireSignIn: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const signedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo && s.auth.userInfo.token));
  const location = useLocation();
  if (!signedIn) {
    return <Navigate to={`/login?redirect=${encodeURIComponent(location.pathname + location.search)}`} replace />;
  }
  return <>{children}</>;
};

export default RequireSignIn;
```

`src/router/routes.tsx` — imports, next to `import MomentLinkRedirect from "./MomentLinkRedirect";`:

```tsx
import FlagRoute from "./FlagRoute";
import RequireSignIn from "../components/gatherings/RequireSignIn";
```

After the `// Courses` lazy line:

```tsx
// Gatherings & clubs (Phase 4). Dark until webGatheringsEnabled (and the
// global GATHERINGS_ENABLED) -- FlagRoute renders NotFound until then, so
// none of these chunks is ever requested while the feature is off.
const GatheringsHome = lazyWithRetry("../components/gatherings/GatheringsHome", () => import("../components/gatherings/GatheringsHome"));
const GatheringDetail = lazyWithRetry("../components/gatherings/GatheringDetail", () => import("../components/gatherings/GatheringDetail"));
const GatheringForm = lazyWithRetry("../components/gatherings/GatheringForm", () => import("../components/gatherings/GatheringForm"));
const ClubDetail = lazyWithRetry("../components/gatherings/ClubDetail", () => import("../components/gatherings/ClubDetail"));
const ClubForm = lazyWithRetry("../components/gatherings/ClubForm", () => import("../components/gatherings/ClubForm"));
```

After the `lazyAdminRoute` helper:

```tsx
// A Phase 4 gatherings page: flag first (a 404 while off, for everyone),
// then sign-in, then the lazy chunk.
const gatheringsRoute = (node: React.ReactNode) => (
  <FlagRoute flag="webGatheringsEnabled">
    <RequireSignIn>{lazyRoute(node)}</RequireSignIn>
  </FlagRoute>
);
```

In the route tree, after the `{/* Moments */}` block (before `{/* Admin console. …`):

```tsx
    {/* Gatherings & clubs (Phase 4, dark behind webGatheringsEnabled).
        Static "new" segments outrank ":id" in react-router v6. */}
    <Route path="gatherings" element={gatheringsRoute(<GatheringsHome />)} />
    <Route path="gatherings/new" element={gatheringsRoute(<GatheringForm mode="create" />)} />
    <Route path="gatherings/:id" element={gatheringsRoute(<GatheringDetail />)} />
    <Route path="gatherings/:id/edit" element={gatheringsRoute(<GatheringForm mode="edit" />)} />
    <Route path="clubs" element={gatheringsRoute(<GatheringsHome initialTab="clubs" />)} />
    <Route path="clubs/new" element={gatheringsRoute(<ClubForm mode="create" />)} />
    <Route path="clubs/:id" element={gatheringsRoute(<ClubDetail />)} />
    <Route path="clubs/:id/edit" element={gatheringsRoute(<ClubForm mode="edit" />)} />
```

`src/components/navbar/MainNavbar.tsx`:
- add `FaCalendarAlt,` to the `react-icons/fa` import list;
- add `import { useWebFlag } from "../../utils/webFlags";` after the `useSocket` import;
- in the component body after `const { t, i18n } = useTranslation();`: `const gatheringsOn = useWebFlag("webGatheringsEnabled");`
- desktop, after the Moments `NavLink` (inside the `userInfo &&` fragment):

```tsx
                {gatheringsOn && (
                  <NavLink
                    to="/gatherings"
                    data-testid="nav-gatherings"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaCalendarAlt />
                    <span>{t("gatherings.nav") || "Gatherings"}</span>
                  </NavLink>
                )}
```

- mobile, after the Moments `NavLink`:

```tsx
                  {gatheringsOn && (
                    <NavLink to="/gatherings" data-testid="nav-gatherings-mobile" className="mobile-nav-link" onClick={closeMobileMenu}>
                      <FaCalendarAlt /> {t("gatherings.nav") || "Gatherings"}
                    </NavLink>
                  )}
```

Add to `eng.json`: `"gatherings": { "nav": "Gatherings" }` (merge).

- [ ] **Step 4: Run → PASS, plus the neighbours**

```bash
CI=true npm test -- --watchAll=false gatheringsFlagOff routes MainNavbar eagerGraph FlagRoute
```
Expected: all `gatheringsFlagOff` cases pass (8 route-match + 8 flag-off + 5 single cases + 3 navbar). `routes.test.tsx` stays green (it requires the module in plain Node: `FlagRoute`/`RequireSignIn` touch no browser global at import). `MainNavbar.test.tsx` stays green (its fetch mock answers app-config with `{data: [...]}` → no `web*` flag → off). `eagerGraph.test.ts` stays green: the five pages are behind `import()`; only `FlagRoute`, `webFlags` and `RequireSignIn` are eager, and they import nothing heavy.

Manual check (dev server, `npm start`, signed in): with the backend's flags off the navbar has no Gatherings entry and `/gatherings` is the 404 page; with a local backend `WEB_GATHERINGS_ENABLED=true` the entry appears on desktop and in the open mobile menu.

- [ ] **Step 5: Commit**

```bash
git add src/components/gatherings/RequireSignIn.tsx src/components/gatherings/gatheringsFlagOff.test.tsx src/router/routes.tsx src/components/navbar/MainNavbar.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(gatherings): routes and nav entry, dark behind webGatheringsEnabled

Eight lazy routes (gatherings and clubs: list, new, detail, edit), each
behind FlagRoute(webGatheringsEnabled) and sign-in; one navbar entry
for signed-in users while the flag is on. A test pins that with the
flag off (or GATHERINGS_ENABLED off, or app-config failed) every path
is a 404, no page chunk is rendered, and the navbar has no entry.

Still open (Phase 4 gatherings): i18n for the new strings, push gate.
MSG
```

---

#### Keys added by P4-GATH-2..10

All new, under two new top-level namespaces (neither exists in `eng.json` on `origin/main`): `gatherings.{errors,quorum,status,time,topics,card,home,confirm,detail,safety,form,host,cover,nav}` and `clubs.{card,home,detail,people,form,owner}`. Plural keys (`_one`/`_other`): `gatherings.card.seatsLeft`, `gatherings.form.duration`, `gatherings.host.cancelConfirm`, `gatherings.host.decision`, `gatherings.host.requests`, `clubs.card.members`, `clubs.detail.metTimes`. Report reasons reuse `moments_section.report.*` (already in all 18 locales). Topic names follow the app's `gatheringTopic*` ARB strings (`bananatalk_app/lib/l10n/app_<lang>.arb`) where the app has them — reuse those translations rather than re-translating.

### Task P4-GATH-I18N: The gatherings unit's new strings in all 18 locales

**Files:**
- Create: `scripts/i18n/keys/2026-10-16-p4-gatherings.json` (all 18 locales; the durable record of what this unit translated)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: every English string P4-GATH-2..10 added to `eng.json` (table above). `scripts/i18n/new-keys.js` (P3-CHAT-I18N) finds them from the diff against `web/p4-base`, so a key a task added but the table missed is still caught. The guard is `src/utils/locales/p3Keys.test.ts`, which P4-0 widened to read `2026-10-16-p4-*.json`.
- Produces: no English-only key in this unit's push.

Translation rules: as in P3-CHAT-I18N (keep `{{…}}` placeholders verbatim; keep `_one`/`_other` and add `ar`'s `_zero`/`_two`/`_few`/`_many`; for `ja`, `kor`, `zho`, `zh_TW`, `th`, `vi`, `id` `_one` may equal `_other`; follow `docs/l10n/2026-09-23-native-pass-*.md`; "BananaTalk" is never translated). Where the app already translates the same idea (`bananatalk_app/lib/l10n/app_*.arb`: `gatheringRunAnyway`, `gatheringCallItOff`, `gatheringEnd`, `gatheringEndedThanks`, `gatheringCancelConfirm`, `gatheringRequests`, `gatheringHostDecision`, topic names, "모임"), use the app's wording so the two clients say the same thing; note the ARB→web locale mapping (`ko`→`kor`, `zh`→`zho`, `en`→`eng`, …) used by `scripts/i18n/merge-keys.js`'s file names.

- [ ] **Step 1: Generate the keys file and see the guard fail**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings
node scripts/i18n/new-keys.js web/p4-base scripts/i18n/keys/2026-10-16-p4-gatherings.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: the script prints `N new or changed keys` (≈ 170, matching the table); the guard FAILS with `<key>: missing` for each of the 17 non-English locales under `2026-10-16-p4-gatherings.json`.

- [ ] **Step 2: Translate**

Fill every `""` in `scripts/i18n/keys/2026-10-16-p4-gatherings.json` for the 17 non-English locales (rules above). Re-running `new-keys.js` keeps what is already filled.

- [ ] **Step 3: Merge into the locale files**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p4-gatherings.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: all `p3Keys` cases pass (Phase 3 files and the new Phase 4 file); `src/utils/i18n*.test.ts` stay green.

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/keys/2026-10-16-p4-gatherings.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
i18n(gatherings): translate the gatherings and clubs strings into all 18 locales

Keys found by scripts/i18n/new-keys.js against web/p4-base and merged
with merge-keys.js; the keys guard fails on any missing, empty or
placeholder-mismatched translation. Wording follows the app's ARB
strings where the app already says the same thing.

Still open (Phase 4 gatherings): push gate (P4-GATH-PUSH); native review
of the new strings.
MSG
```

---

### Task P4-GATH-PUSH: Push unit GATHERINGS (2 of 5) — full suite + build green, deployed dark, then the coordinator pushes

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status line, §6 changelog line, §3 production-QA lines for the flag-on checklist below)

- [ ] **Step 1: Every task in the unit is committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-gatherings
git status --short                                     # expect: nothing (except the node_modules symlink, untracked)
grep -n "P4-GATH-" docs/REMAINING_WORK.md | grep -c "\[ \]"   # expect: 1 (this PUSH line only)
```

- [ ] **Step 2: Rebase onto the live site (REELS is already pushed)**

```bash
git fetch origin
git log origin/main --oneline | grep -ci "phase 4 reels"   # expect >= 1 (the REELS push landed)
git rebase origin/main
```
Expected conflicts, and how to resolve them (keep both sides every time):
- `src/router/routes.tsx` — REELS added its own lazy group and `{/* Reels */}` route block; keep both blocks and both import lines (`FlagRoute` is imported once — if REELS already added `import FlagRoute from "./FlagRoute";`, drop the duplicate line from this side).
- `src/components/navbar/MainNavbar.tsx` — both units added one icon to the `react-icons/fa` import, one `useWebFlag` line and one flagged `NavLink` (desktop + mobile) after Moments; keep both, Reels first, then Gatherings; import `useWebFlag` once.
- `src/utils/locales/*.json` — different top-level namespaces (`reels` vs `gatherings`/`clubs`); keep both. Re-run `CI=true npm test -- --watchAll=false p3Keys` after resolving.
- `docs/REMAINING_WORK.md` — keep both units' ticks.
After resolving: `git rebase --continue`.

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `Test Suites: … 0 failed`, `Tests: … 0 failed`; passed count ≥ the REELS push's count plus this unit's new tests (≈ 110). Any failure: fix in a new commit (never `--no-verify`, never skip a test).

- [ ] **Step 4: Production build**

```bash
npm run build 2>&1 | tail -20
ls build/static/js | grep -c "chunk.js"          # more chunks than before: the five gatherings pages are lazy
grep -l "Host a gathering" build/static/js/main.*.js | wc -l   # expect 0: no gatherings page code in main.js
```
Expected: `Compiled successfully` or `Compiled with warnings` (warnings only from files this unit did not touch), then the prerender step finishes without an error line. The build does **not** type-check (Babel strips types; see Global Constraints) — TS 3.7 limits in this unit's files were held by review. Optional: `npm run test:budget` and note the first-paint size in the tracker (the eager additions are `RequireSignIn` and the navbar's flag read; expect < 1 KB gzipped growth).

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P4-GATH-PUSH`; §1 Status: "Phase 4 gatherings pushed dark (YYYY-MM-DD)"; §6 Done: one line naming the unit; §3 Production QA: one `- [ ]` line per item of the flag-on checklist in Step 8 (they run when the owner turns the flag on, Phase 5).

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'MSG'
docs: Phase 4 gatherings ready to deploy (dark)

Still open (Phase 4): ROOMS, CALLS and APPLE units; flag-on QA for
gatherings and clubs (docs/REMAINING_WORK.md §3); native review of the
new strings.
MSG
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p4-gatherings:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/            # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1   # a new bundle hash
```

- [ ] **Step 7: Production smoke with the flag OFF (it must be invisible)**

```bash
curl -s https://api.banatalk.com/api/v1/app-config | grep -o '"webGatheringsEnabled":[a-z]*'   # "webGatheringsEnabled":false
```
  - [ ] Signed in on banatalk.com (desktop and a phone-width window): the navbar has no "Gatherings" entry; the open mobile menu has none either.
  - [ ] `https://banatalk.com/gatherings`, `/gatherings/new`, `/clubs`, `/clubs/<any id>` show the 404 page (signed in and signed out).
  - [ ] DevTools → Network on those paths: no request to `/api/v1/gatherings` or `/api/v1/clubs`, and no `GatheringsHome`/`GatheringDetail`/`ClubDetail` chunk is fetched.
  - [ ] `/communities` (public clubs list) and the rest of the site behave exactly as before.

A failure that shows any gatherings UI with the flag off, or breaks an existing page → Step 9.

- [ ] **Step 8: Flag-on checklist (recorded now in §3; run when the owner turns `WEB_GATHERINGS_ENABLED=true`, web user A + app user B on app 2.6.1+)**

  - [ ] A opens Gatherings: the list matches what B sees in the app's 모임 tab for the same languages; Clubs tab matches the app's clubs.
  - [ ] A hosts a gathering (approval mode) for tomorrow 19:00 in A's zone → B sees it in the app at the right local time; B asks to join → A sees "1 waiting to join" on web and approves → B shows as going in both clients.
  - [ ] B RSVPs to A's open gathering until quorum → the web page flips to "Confirmed"; B leaves → back to "N more needed".
  - [ ] A edits the time → B gets the time-change notification (backend `notifyTimeChanged`); A cancels → B gets the cancellation.
  - [ ] Inside two hours with quorum unmet, A sees "Run it anyway / Call it off"; after the start A can End and sees "Ended — message anyone you met, it's free".
  - [ ] A creates a club, B joins it in the app; A makes B organizer; B (app) edits the club; A deletes it → its planned gathering still opens.
  - [ ] A reports a gathering and blocks its host → the gathering is "not available" for A; the report shows in the admin console's reports queue with type `gathering`.
  - [ ] Cover photo: A adds a JPEG cover on web → visible in the app; a HEIC file is refused with the type message.
  - [ ] RTL (`ar`): list cards, detail page, forms and the members menu sit on the correct side.

- [ ] **Step 9 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p4-gatherings-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -20
CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(The unit is a linear series after the rebase, so the range revert is clean. Because every screen sits behind the flag, a rollback is only needed for a regression in shared files — `routes.tsx`, `MainNavbar.tsx`, `apiSlice.ts` tags. Note the revert in §6 and reopen the tasks.)

---

---

## Unit ROOMS (push 3 of 5) — P4-ROOM-1 … P4-ROOM-12, P4-ROOM-I18N, P4-ROOM-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p4-rooms`, branch `web/p4-rooms` (from `web/p4-base`, created by P4-0 Step 8 with a **real** `node_modules` from `npm ci`). One implementer, tasks in number order. P4-ROOM-1 and P4-ROOM-2 come first and are committed early: the CALLS worktree is cut from the P4-ROOM-2 commit (P4-CALL-0) and consumes `src/lib/livekit/` unchanged — **do not change the API in "Shared contracts → LiveKit"** after P4-ROOM-2 is committed; if a change is unavoidable, tell the CALLS implementer and the coordinator first.

Unit-level facts (read once):
- **Flags.** Voice rooms: `webVoiceRoomsEnabled` only (no global switch, spec §4). Language rooms: `webLanguageRoomsEnabled` + `roomsEnabled` (the backend's `roomsEnabledGuard` 404s every `/rooms` route while `ROOMS_ENABLED` is off, `be/routes/rooms.js:39`). **City and Genders tabs: `webLanguageRoomsEnabled`** — the spec puts them in the same bullet as language rooms ("Language rooms … and the community City and Genders tabs (community#7)"), and they need no LiveKit. They use `useWebFlag("webLanguageRoomsEnabled")` unchanged, so they also follow `roomsEnabled` (one rule, one switch for the owner; `ROOMS_ENABLED` is on in production because the app's language rooms are live). If product later wants the tabs without language rooms, that is a seventh flag, not a special case in this code.
- **Who may speak.** The backend has no speaker permission: every voice-room token is minted with `canPublish: true` (`be/services/livekitService.js:34-60`, `be/controllers/voiceRooms.js:397-404`, metadata `{role: "host" | "participant"}`). The app's model is: everyone joins muted as a listener; "taking the mic" is unmuting (publishing the microphone); "requesting to speak" is raising a hand, which the host sees. The web does exactly that. There is no "grant" event (and the host cannot lower someone else's hand: `voiceroom:raise_hand` always acts on the sender), so the web host sees the raised hands in a list and can make a person co-host (`PUT /voicerooms/:id/promote/:userId`) or mute everyone (`voiceroom:mute-all`); the listener takes the mic themselves, as in the app. Recorded as a backend follow-up: a real speaker role.
- **Socket event names (backend is the truth, `be/socket/voiceRoomHandler.js`).** Client → server: `voiceroom:join {roomId}`, `voiceroom:leave {roomId}`, `voiceroom:mute {roomId,isMuted}`, `voiceroom:mute-all {roomId}` (host only), `voiceroom:raise_hand {roomId,isRaised}` (**underscore**), `voiceroom:chat {roomId,message}` (≤500 chars, participants only), `voiceroom:heartbeat {roomId}` (every 30 s; the list hides rooms without a heartbeat in the last 60 s, `be/controllers/voiceRooms.js:22-46`), `voiceroom:rejoin {roomId,lastSeenAt}` with ack `{ok, ended, currentHostId?, youArePromoted?, participants?}`, `voiceroom:end-intent {roomId}`. Server → client: `voiceroom:joined {roomId, participants, iceServers}`, `voiceroom:user_joined {roomId, user:{_id,name,images}, participantCount}` (or `{roomId,userId,joinedAt}` from rejoin), `voiceroom:user_left {roomId,userId,roomEnded}`, `voiceroom:mute {roomId,userId,isMuted,forced?}`, `voiceroom:hand_raised {roomId,userId,isRaised,user}`, `voiceroom:chat {roomId,message,user,timestamp}`, `voiceroom:host-changed {newHostId,previousHostId}`, `voiceroom:ended {roomId}`, `voiceroom:error {message}`.
- **App 2.6.1 mismatches (do not copy them).** The app emits `voiceroom:raise-hand` (hyphen) and listens for `voiceroom:hand-raised`, `voiceroom:participant-joined/left`, `voiceroom:kicked`, and emits `voiceroom:kick`, none of which the backend has (`bananatalk_app/lib/services/voice_room_manager.dart:589,623`, `chat_socket_service.dart:526-576`). Consequences: a hand raised on the web is not seen by an app host and vice versa; there is no kick. The web uses the backend's names and offers no "remove from room". Logged as a backend/app follow-up (accept both spellings server-side; add `voiceroom:kick`).
- **LiveKit identity** is the user id (`identity: req.user._id.toString()`, room name = voice room id). A second tab of the same user joining the same room makes LiveKit disconnect the first with `DUPLICATE_IDENTITY` → `onDisconnected("duplicate_identity")` → the first tab shows "Joined from another tab" and does **not** reconnect.
- **Language rooms** are Conversations with `roomType: 'hub' | 'topic'` (`be/controllers/rooms.js`). REST: `GET /rooms` (auto-joins the caller's learning-language hub, sorted caller-first), `GET /rooms/:id`, `GET /rooms/:id/messages?page&limit` (oldest-first page, `pagination.hasNextPage` = older pages), `POST /rooms {title, targetLanguage, description}` (topic room, ≤10 per owner, title ≤60, description ≤300), `POST /rooms/:id/join` / `leave`, `POST /rooms/:id/request-join` (banned users), `GET /rooms/:id/requests`, `POST /rooms/:id/requests/:userId/approve|deny`, `DELETE /rooms/:id/members/:userId`. Socket (`be/socket/roomHandler.js`): `room:join {roomId}`, `room:leave {roomId}`, `room:message {roomId, message, messageType:'text'}` with ack `{status:'success', message}` or `{status:'error', error}`, `room:typing {roomId}`; server emits `room:message <Message>`, `room:presence {roomId, online}`, `room:typing {roomId,userId}`, `room:error {message}`.
- **City / Genders** are both `GET /api/v1/auth/users` with `country` (English name, exact-matched via `toIso2`, `be/controllers/users.js:323-329`), `search`, `gender` (`male|female`, `:271-278`), plus the viewer's languages with `matchLanguage` — the same params the web list already sends through `getCommunityMembers`. The app's "search a city" sends `search`, which the backend matches against name/username/bio/languages only, **not** `location.city` (`users.js` getUsers search block) — the web copies the app's request and the gap is logged for the backend.
- **Phase 3 dependencies:** `useSocket()` with `connectionEpoch` (P3-CHAT-7), `emitWithAck` (P3-CHAT-5), community sub-nav after P3-COM-6/7 (Serious tab, smart sort). If `CommunitySubNav.tsx` on `origin/main` already has a `"serious"` tab id, add `"city"` and `"genders"` after it.

### Task P4-ROOM-1: `livekit-client@2.22.4` behind a JS loader + `.d.ts`, excluded from tsconfig, kept out of the eager graph

**Files:**
- Modify: `package.json`, `package-lock.json` (via `npm install --save-exact`)
- Modify: `tsconfig.json` (add `exclude`)
- Create: `src/lib/livekit/livekitLoader.js`, `src/lib/livekit/livekitLoader.d.ts`
- Modify: `src/seo/eagerGraph.test.ts` (forbidden package list + one proof case)
- Test: `src/lib/livekit/livekitLoader.test.ts` (new)

**Interfaces:**
- Consumes: npm `livekit-client@2.22.4` (latest 2.x on 2026-10-16; `exports["."].import` = `dist/livekit-client.esm.mjs`; deps `@livekit/protocol 1.52.1`, `jose ^6`, `webrtc-adapter 9.0.6`; peer `@types/dom-mediacapture-record ^1`, which npm 7+ installs automatically). Compatible with the backend's `livekit-server-sdk ^2.15.2` (`be/package.json:48`): the server SDK only mints JWTs (`AccessToken` grants `roomJoin`, `canPublish`, `canSubscribe`, `canPublishData`, `metadata`), which every 2.x client accepts; signalling is with LiveKit Cloud, not with our backend. The app uses `livekit_client ^2.7.0` (Flutter) against the same rooms, so web and app peers meet in one room.
- Produces: `loadLivekit(): Promise<any>` — the module namespace of `livekit-client`, fetched once as the webpack chunk `livekit`; a rejected fetch clears the cache so the next call retries.

- [ ] **Step 1: Install the dependency (real `node_modules` only)**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-rooms
test -L node_modules && { echo "node_modules is a symlink: run 'rm node_modules && npm ci' first"; exit 1; }
npm install --save-exact livekit-client@2.22.4 2>&1 | tail -3
grep -n '"livekit-client"' package.json            # expect: "livekit-client": "2.22.4",
ls node_modules/@types/dom-mediacapture-record >/dev/null && echo "peer types present"
git diff --stat package.json package-lock.json
```
Expected: `"livekit-client": "2.22.4"` (no caret) in `dependencies`; `package-lock.json` gains `livekit-client`, `@livekit/protocol`, `@livekit/mutex`, `jose`, `webrtc-adapter`, `sdp`, `sdp-transform`, `loglevel`, `machina`, `typed-emitter`, `events`, `@bufbuild/protobuf`, `@types/dom-mediacapture-record` (and possibly `rxjs`). Nothing else in the lock changes; if `npm` rewrote unrelated entries, `git checkout package-lock.json` and rerun with `npm install --save-exact --no-audit --no-fund livekit-client@2.22.4`.

- [ ] **Step 2: Write the failing tests**

Create `src/lib/livekit/livekitLoader.test.ts`:

```ts
// The loader is the only module that names livekit-client. Jest must never
// load the real package (ESM-only .mjs, outside transformIgnorePatterns), so
// the dynamic import is mocked here with a virtual module.
jest.mock("livekit-client", () => ({ Room: function Room() {}, __fake: true }), { virtual: true });

import fs from "fs";
import path from "path";

beforeEach(() => {
  jest.resetModules();
});

it("loads the module once and caches it", async () => {
  const { loadLivekit } = require("./livekitLoader");
  const a = await loadLivekit();
  const b = await loadLivekit();
  expect(a.__fake).toBe(true);
  expect(a).toBe(b);
});

it("is the only source file that names the package, and only in import()", () => {
  const src = path.join(__dirname, "..", "..");
  const offenders: string[] = [];
  const walk = (dir: string) => {
    fs.readdirSync(dir).forEach((name) => {
      const full = path.join(dir, name);
      if (fs.statSync(full).isDirectory()) return walk(full);
      if (!/\.(ts|tsx|js|jsx)$/.test(name) || /\.test\.(ts|tsx)$/.test(name)) return;
      if (fs.readFileSync(full, "utf8").indexOf("livekit-client") > -1) offenders.push(path.relative(src, full));
    });
  };
  walk(src);
  // The .d.ts declares the loader's shape without naming the package; the
  // fake under testing/ names nothing either. Only the loader may.
  expect(offenders.filter((f) => f !== path.join("lib", "livekit", "livekitLoader.js"))).toEqual([]);
  const loader = fs.readFileSync(path.join(__dirname, "livekitLoader.js"), "utf8");
  expect(loader).toMatch(/import\(\s*\/\*\s*webpackChunkName:\s*"livekit"\s*\*\/\s*"livekit-client"\s*\)/);
});

it("keeps the loader out of the TypeScript program (TS 3.7 cannot parse livekit's typings)", () => {
  const raw = fs.readFileSync(path.join(__dirname, "..", "..", "..", "tsconfig.json"), "utf8");
  const config = JSON.parse(raw.replace(/^\s*\/\/.*$/gm, ""));
  expect(config.exclude).toEqual(expect.arrayContaining(["src/lib/livekit/livekitLoader.js"]));
  expect(fs.existsSync(path.join(__dirname, "livekitLoader.d.ts"))).toBe(true);
});
```

In `src/seo/eagerGraph.test.ts`:
- below `const SOCKET_MODULE = …;` add

```ts
// Phase 4 (voice rooms, calls): livekit-client is ~151 KB gzipped of WebRTC
// that only a member joining a room or a call can use. It is reached only
// through src/lib/livekit/livekitLoader.js, which `import()`s it; a static
// import anywhere in the eager graph would put it in main.js.
const FORBIDDEN_LIVEKIT_PACKAGE = "livekit-client";
```
- in `walkEagerGraph`, extend the `else if (` condition with
```ts
        spec === FORBIDDEN_LIVEKIT_PACKAGE ||
        spec.indexOf(FORBIDDEN_LIVEKIT_PACKAGE + "/") === 0 ||
```
- append

```ts
it("never reaches the LiveKit loader or livekit-client from an eager module", () => {
  const loader = path.join(SRC, "lib", "livekit", "livekitLoader.js");
  expect(graph.modules.indexOf(loader)).toBe(-1);
  expect(graph.packageHits.filter((hit) => hit.indexOf(FORBIDDEN_LIVEKIT_PACKAGE) > -1)).toEqual([]);
  // The guard can fire: a static import is seen, the loader's import() is not.
  expect(staticSpecifiers('import { Room } from "livekit-client";\n')).toContain(FORBIDDEN_LIVEKIT_PACKAGE);
  expect(staticSpecifiers(fs.readFileSync(loader, "utf8"))).not.toContain(FORBIDDEN_LIVEKIT_PACKAGE);
});
```

- [ ] **Step 3: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false livekitLoader eagerGraph
```
Expected: FAIL — `Cannot find module './livekitLoader'`; the tsconfig case fails on `exclude` (undefined); the new eagerGraph case fails reading the missing loader file.

- [ ] **Step 4: Implement**

Create `src/lib/livekit/livekitLoader.js`:

```js
// The ONLY module that names livekit-client.
//
// Why a .js file with a hand-written .d.ts: livekit-client's typings (and its
// `typesVersions` fallback for TS < 4.8, dist/ts4.2) use `import type`, which
// TypeScript 3.7.2 cannot parse -- 621 errors from one `import { Room }`.
// This file is listed in tsconfig.json "exclude", so the TS program never
// resolves the package; .ts callers see only livekitLoader.d.ts.
//
// Why import(): ~151 KB gzipped of WebRTC that no visitor needs until they
// join a voice room or a call. The chunk is named "livekit" (src/seo/
// eagerGraph.test.ts and the push checks grep main.js for "livekit-client").
let pending = null;

export function loadLivekit() {
  if (!pending) {
    pending = import(/* webpackChunkName: "livekit" */ "livekit-client").catch((err) => {
      // A chunk that failed (flaky network, a tab open across a deploy) must
      // not poison every later attempt.
      pending = null;
      throw err;
    });
  }
  return pending;
}
```

Create `src/lib/livekit/livekitLoader.d.ts`:

```ts
// Shape of livekitLoader.js for the TypeScript program. Deliberately `any`:
// the real typings need TS >= 3.8. lkSession.ts is the typed facade.
export declare function loadLivekit(): Promise<any>;
```

In `tsconfig.json`, after the `"include": [ "src" ]` entry add (keep the existing comment line inside `compilerOptions` untouched):

```json
  ,
  "exclude": [
    "src/lib/livekit/livekitLoader.js"
  ]
```
(so the file ends `"include": ["src"], "exclude": ["src/lib/livekit/livekitLoader.js"] }`; `include` already limits the program to `src`, so the default `node_modules` exclusion is not needed.)

- [ ] **Step 5: Run → PASS, then the TS 3.7 check**

```bash
CI=true npm test -- --watchAll=false livekitLoader eagerGraph
npx tsc -p . 2>&1 | grep "error TS" | grep -c -i livekit
```
Expected: tests pass; the grep prints `0` (before the `exclude` it printed 600+ once a `.ts` file reached the package — the planning experiment counted 621). `react-scripts build` would not catch a regression here (it does not type-check this repo), which is why this grep is a push gate.

- [ ] **Step 6: Commit**

```bash
git add package.json package-lock.json tsconfig.json src/lib/livekit/livekitLoader.js src/lib/livekit/livekitLoader.d.ts src/lib/livekit/livekitLoader.test.ts src/seo/eagerGraph.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
build(livekit): add livekit-client 2.22.4 behind a lazy JS loader

The package's typings need TS >= 3.8, so it is reached only through
src/lib/livekit/livekitLoader.js (excluded from tsconfig, typed by a
hand-written .d.ts) and loaded as the "livekit" chunk on demand. The
eager-graph test now forbids a static import of it.

Still open (Phase 4 rooms): lkSession facade, voice rooms, language
rooms, City/Genders tabs, i18n, push.
EOF
```

---

### Task P4-ROOM-2: `lkSession` facade (connect, mic/camera, audio unlock, peers, disconnect reasons) + the shared LiveKit test fake

**Files:**
- Create: `src/lib/livekit/lkSession.ts`, `src/lib/livekit/testing/fakeLivekit.ts`
- Test: `src/lib/livekit/lkSession.test.ts` (new)

**Interfaces:**
- Consumes: `loadLivekit()` (P4-ROOM-1). From the module it resolves: `Room` (`new Room({adaptiveStream, dynacast})`, `connect(url, token)`, `disconnect()`, `startAudio()`, `canPlaybackAudio`, `localParticipant`, `remoteParticipants: Map`), `RoomEvent` (`participantConnected`, `participantDisconnected`, `activeSpeakersChanged`, `trackSubscribed`, `trackUnsubscribed`, `trackMuted`, `trackUnmuted`, `localTrackPublished`, `localTrackUnpublished`, `participantMetadataChanged`, `reconnecting`, `reconnected`, `disconnected`, `audioPlaybackChanged`), `DisconnectReason` (protocol enum: `CLIENT_INITIATED=1`, `DUPLICATE_IDENTITY=2`, `SERVER_SHUTDOWN=3`, `PARTICIPANT_REMOVED=4`, `ROOM_DELETED=5`, `JOIN_FAILURE=7`, `SIGNAL_CLOSE=9`, `ROOM_CLOSED=10`, `CONNECTION_TIMEOUT=14`, `MEDIA_FAILURE=15`), `Track.Source.Camera = "camera"`, `Track.Kind` `"audio"|"video"`; participant fields `identity`, `name`, `metadata`, `isSpeaking`, `isMicrophoneEnabled`, `isCameraEnabled`, `getTrackPublication(source)?.videoTrack`; `localParticipant.setMicrophoneEnabled(bool)`, `setCameraEnabled(bool)`; remote `track.attach()` → `HTMLMediaElement`, `track.detach()` → elements. (Names checked against `livekit-client@2.22.4` `dist/src/room/events.d.ts`, `Room.d.ts`, `participant/*.d.ts`.)
- Produces: exactly "Shared contracts → LiveKit" in the plan header: `createLkSession(events)`, `mediaErrorKind(err)`, types `LkMediaResult`, `LkPeer`, `LkVideoTrack`, `LkEvents`, `LkSession`. Plus the fake: `loaderMock()`, `fakeRoom()`, `failNextMedia(name)`, and helpers `resetFakeLivekit()`, `setFakeDefaults({canPlaybackAudio?, connectError?})`, `fakeRemote(identity, opts?)`, `fakeTrack(kind, sid?)`, `fakeModule` (the namespace object). `loaderMock()` also installs an empty `navigator.mediaDevices` when jsdom has none, so code that checks for it behaves as in a secure-context browser.
- Behaviour pinned for both ROOMS and CALLS: `connect` rejects only when `room.connect` rejects (bad token/URL, network) and then reports `onState("disconnected")`; publishing failures resolve with the `LkMediaResult` instead (a denied mic never fails the join). Remote audio tracks are attached to hidden `<audio>` elements under `document.body` and removed on unsubscribe/disconnect. `onAudioBlocked(true)` right after connect when `canPlaybackAudio` is false, and on every `audioPlaybackChanged`. `disconnect()` always ends with `onDisconnected("client")`, whatever reason LiveKit reports.

- [ ] **Step 1: Write the fake (test infrastructure, no test of its own)**

Create `src/lib/livekit/testing/fakeLivekit.ts`:

```ts
// A stand-in for the LiveKit SDK's module namespace, for Jest only.
//
//   jest.mock("../../lib/livekit/livekitLoader", () =>
//     require("../../lib/livekit/testing/fakeLivekit").loaderMock());
//
// Never imported by application code (so never bundled). Mirrors only what
// src/lib/livekit/lkSession.ts touches; event names and enum values are the
// real ones from the SDK, version 2.22.4. (This file must not spell the
// package name: livekitLoader.test.ts allows it in the loader only.)
type Handler = (...args: any[]) => void;

export const RoomEvent = {
  ParticipantConnected: "participantConnected",
  ParticipantDisconnected: "participantDisconnected",
  ActiveSpeakersChanged: "activeSpeakersChanged",
  TrackSubscribed: "trackSubscribed",
  TrackUnsubscribed: "trackUnsubscribed",
  TrackMuted: "trackMuted",
  TrackUnmuted: "trackUnmuted",
  LocalTrackPublished: "localTrackPublished",
  LocalTrackUnpublished: "localTrackUnpublished",
  ParticipantMetadataChanged: "participantMetadataChanged",
  Reconnecting: "reconnecting",
  Reconnected: "reconnected",
  Disconnected: "disconnected",
  AudioPlaybackStatusChanged: "audioPlaybackChanged",
};

export const DisconnectReason = {
  UNKNOWN_REASON: 0,
  CLIENT_INITIATED: 1,
  DUPLICATE_IDENTITY: 2,
  SERVER_SHUTDOWN: 3,
  PARTICIPANT_REMOVED: 4,
  ROOM_DELETED: 5,
  STATE_MISMATCH: 6,
  JOIN_FAILURE: 7,
  MIGRATION: 8,
  SIGNAL_CLOSE: 9,
  ROOM_CLOSED: 10,
  CONNECTION_TIMEOUT: 14,
  MEDIA_FAILURE: 15,
};

export const Track = {
  Source: { Camera: "camera", Microphone: "microphone" },
  Kind: { Audio: "audio", Video: "video" },
};

let defaults: { canPlaybackAudio: boolean; connectError: any } = { canPlaybackAudio: true, connectError: null };
let pendingMediaFailure: string | null = null;
const rooms: FakeRoom[] = [];

export function setFakeDefaults(next: { canPlaybackAudio?: boolean; connectError?: any }): void {
  defaults = Object.assign({}, defaults, next);
}

/** The next setMicrophoneEnabled/setCameraEnabled throws {name}. */
export function failNextMedia(name: string): void {
  pendingMediaFailure = name;
}

export function resetFakeLivekit(): void {
  defaults = { canPlaybackAudio: true, connectError: null };
  pendingMediaFailure = null;
  rooms.length = 0;
}

function takeMediaFailure(): void {
  if (!pendingMediaFailure) return;
  const name = pendingMediaFailure;
  pendingMediaFailure = null;
  const err: any = new Error(name);
  err.name = name;
  throw err;
}

class FakeEmitter {
  private handlers: { [event: string]: Handler[] } = {};
  on(event: string, handler: Handler) {
    (this.handlers[event] = this.handlers[event] || []).push(handler);
    return this;
  }
  off(event: string, handler: Handler) {
    this.handlers[event] = (this.handlers[event] || []).filter((h) => h !== handler);
    return this;
  }
  removeAllListeners() {
    this.handlers = {};
    return this;
  }
  emit(event: string, ...args: any[]) {
    (this.handlers[event] || []).slice().forEach((h) => h(...args));
    return true;
  }
}

export function fakeTrack(kind: "audio" | "video", sid?: string) {
  const elements: HTMLMediaElement[] = [];
  return {
    kind,
    sid: sid || `${kind}-${Math.random().toString(36).slice(2, 8)}`,
    attach: jest.fn((el?: HTMLMediaElement) => {
      const node = el || (document.createElement(kind === "audio" ? "audio" : "video") as HTMLMediaElement);
      elements.push(node);
      return node;
    }),
    detach: jest.fn((el?: HTMLMediaElement) => {
      if (el) return [el];
      return elements.splice(0, elements.length);
    }),
  };
}

export function fakeRemote(identity: string, opts: { name?: string; micOn?: boolean; cameraOn?: boolean; metadata?: string } = {}) {
  return {
    identity,
    name: opts.name || identity,
    metadata: opts.metadata || "",
    isSpeaking: false,
    isMicrophoneEnabled: !!opts.micOn,
    isCameraEnabled: !!opts.cameraOn,
    getTrackPublication: (_source: string): any => undefined,
  };
}

class FakeLocalParticipant {
  identity = "me";
  name = "Me";
  metadata = "";
  isSpeaking = false;
  isMicrophoneEnabled = false;
  isCameraEnabled = false;
  cameraTrack: any = null;
  setMicrophoneEnabled = jest.fn(async (on: boolean) => {
    takeMediaFailure();
    this.isMicrophoneEnabled = on;
    return undefined;
  });
  setCameraEnabled = jest.fn(async (on: boolean) => {
    takeMediaFailure();
    this.isCameraEnabled = on;
    this.cameraTrack = on ? fakeTrack("video", "local-camera") : null;
    return undefined;
  });
  getTrackPublication = (source: string): any =>
    source === Track.Source.Camera && this.cameraTrack ? { videoTrack: this.cameraTrack } : undefined;
}

export class FakeRoom extends FakeEmitter {
  options: any;
  localParticipant = new FakeLocalParticipant();
  remoteParticipants = new Map<string, any>();
  canPlaybackAudio = defaults.canPlaybackAudio;
  connect = jest.fn(async (_url: string, _token: string) => {
    if (defaults.connectError) throw defaults.connectError;
  });
  disconnect = jest.fn(async () => {
    this.emit(RoomEvent.Disconnected, DisconnectReason.CLIENT_INITIATED);
  });
  startAudio = jest.fn(async () => {
    this.canPlaybackAudio = true;
    this.emit(RoomEvent.AudioPlaybackStatusChanged, true);
  });
  constructor(options?: any) {
    super();
    this.options = options;
    rooms.push(this);
  }
  /** Test helper: a remote participant joins. */
  addRemote(p: any) {
    this.remoteParticipants.set(p.identity, p);
    this.emit(RoomEvent.ParticipantConnected, p);
  }
  /** Test helper: a remote participant leaves. */
  removeRemote(identity: string) {
    const p = this.remoteParticipants.get(identity);
    this.remoteParticipants.delete(identity);
    this.emit(RoomEvent.ParticipantDisconnected, p);
  }
}

export const fakeModule = { Room: FakeRoom, RoomEvent, DisconnectReason, Track };

/** The last Room the code under test created. */
export function fakeRoom(): FakeRoom {
  return rooms[rooms.length - 1];
}

/** Module shape of src/lib/livekit/livekitLoader for jest.mock. */
export function loaderMock() {
  if (typeof navigator !== "undefined" && !(navigator as any).mediaDevices) {
    Object.defineProperty(navigator, "mediaDevices", { value: {}, configurable: true });
  }
  return { loadLivekit: () => Promise.resolve(fakeModule) };
}
```

- [ ] **Step 2: Write the failing tests**

Create `src/lib/livekit/lkSession.test.ts`:

```ts
import { createLkSession, mediaErrorKind, LkPeer } from "./lkSession";
import {
  fakeRoom,
  failNextMedia,
  resetFakeLivekit,
  setFakeDefaults,
  fakeRemote,
  fakeTrack,
  RoomEvent,
  DisconnectReason,
} from "./testing/fakeLivekit";

jest.mock("./livekitLoader", () => require("./testing/fakeLivekit").loaderMock());

beforeEach(() => {
  resetFakeLivekit();
  document.body.innerHTML = "";
});

describe("mediaErrorKind", () => {
  it.each([
    ["NotAllowedError", "denied"],
    ["SecurityError", "denied"],
    ["PermissionDeniedError", "denied"],
    ["NotFoundError", "unavailable"],
    ["DevicesNotFoundError", "unavailable"],
    ["OverconstrainedError", "unavailable"],
    ["NotReadableError", "unavailable"],
    ["TrackStartError", "unavailable"],
    ["AbortError", "error"],
  ])("%s -> %s", (name, kind) => {
    expect(mediaErrorKind({ name })).toBe(kind);
  });
  it("reads a wrapped DOMException and survives junk", () => {
    expect(mediaErrorKind({ error: { name: "NotAllowedError" } })).toBe("denied");
    expect(mediaErrorKind(undefined)).toBe("error");
    expect(mediaErrorKind("boom")).toBe("error");
  });
});

function harness() {
  const events = {
    peers: [] as LkPeer[][],
    states: [] as string[],
    disconnected: [] as string[],
    blocked: [] as boolean[],
    video: [] as Array<[string, boolean]>,
  };
  const session = createLkSession({
    onPeers: (p) => events.peers.push(p),
    onState: (s) => events.states.push(s),
    onDisconnected: (r) => events.disconnected.push(r),
    onAudioBlocked: (b) => events.blocked.push(b),
    onRemoteVideo: (id, track) => events.video.push([id, !!track]),
  });
  return { session, events };
}

it("connects as a listener: no mic published, peers reported, adaptive stream on", async () => {
  const { session, events } = harness();
  const result = await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  expect(result).toBe("ok");
  const room = fakeRoom();
  expect(room.connect).toHaveBeenCalledWith("wss://lk.test", "tok");
  expect(room.options).toEqual({ adaptiveStream: true, dynacast: true });
  expect(room.localParticipant.setMicrophoneEnabled).not.toHaveBeenCalled();
  expect(events.states).toEqual(["connecting", "connected"]);
  expect(session.peers().map((p) => p.identity)).toEqual(["me"]);
  room.addRemote(fakeRemote("u2", { name: "Ana", micOn: true }));
  const last = events.peers[events.peers.length - 1];
  expect(last).toEqual([
    expect.objectContaining({ identity: "me", isLocal: true, micOn: false }),
    expect.objectContaining({ identity: "u2", name: "Ana", isLocal: false, micOn: true }),
  ]);
});

it("a denied mic resolves 'denied' and the session stays connected", async () => {
  const { session, events } = harness();
  failNextMedia("NotAllowedError");
  expect(await session.connect("wss://lk.test", "tok", { mic: true, camera: false })).toBe("denied");
  expect(events.states).toEqual(["connecting", "connected"]);
  expect(await session.setMic(true)).toBe("ok");
  expect(fakeRoom().localParticipant.isMicrophoneEnabled).toBe(true);
});

it("a missing camera resolves 'unavailable' but keeps the mic", async () => {
  const { session } = harness();
  await session.connect("wss://lk.test", "tok", { mic: true, camera: false });
  failNextMedia("NotFoundError");
  expect(await session.setCamera(true)).toBe("unavailable");
  expect(fakeRoom().localParticipant.isMicrophoneEnabled).toBe(true);
  expect(fakeRoom().localParticipant.isCameraEnabled).toBe(false);
});

it("rejects when the room connection itself fails, and says disconnected", async () => {
  setFakeDefaults({ connectError: new Error("invalid token") });
  const { session, events } = harness();
  await expect(session.connect("wss://lk.test", "bad", { mic: false, camera: false })).rejects.toThrow("invalid token");
  expect(events.states).toEqual(["connecting", "disconnected"]);
  expect(session.peers()).toEqual([]);
});

it("reports blocked audio after connect and clears it on startAudio (Safari autoplay)", async () => {
  setFakeDefaults({ canPlaybackAudio: false });
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  expect(events.blocked).toEqual([true]);
  expect(await session.startAudio()).toBe(true);
  expect(events.blocked[events.blocked.length - 1]).toBe(false);
});

it("plays remote audio through a hidden element and removes it on unsubscribe", async () => {
  const { session } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  const room = fakeRoom();
  const p = fakeRemote("u2");
  const audio = fakeTrack("audio", "a1");
  room.emit(RoomEvent.TrackSubscribed, audio, {}, p);
  expect(document.body.querySelectorAll("audio")).toHaveLength(1);
  room.emit(RoomEvent.TrackUnsubscribed, audio, {}, p);
  expect(document.body.querySelectorAll("audio")).toHaveLength(0);
});

it("hands remote video to onRemoteVideo and takes it back", async () => {
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  const room = fakeRoom();
  const p = fakeRemote("u2");
  const video = fakeTrack("video", "v1");
  room.emit(RoomEvent.TrackSubscribed, video, {}, p);
  room.emit(RoomEvent.TrackUnsubscribed, video, {}, p);
  expect(events.video).toEqual([
    ["u2", true],
    ["u2", false],
  ]);
});

it("exposes the local camera track once published", async () => {
  const { session } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  expect(session.localVideo()).toBe(null);
  expect(await session.setCamera(true)).toBe("ok");
  const el = document.createElement("video");
  const track = session.localVideo();
  expect(track).not.toBe(null);
  track!.attach(el);
  expect(fakeRoom().localParticipant.cameraTrack.attach).toHaveBeenCalledWith(el);
});

it("maps reconnect states", async () => {
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  fakeRoom().emit(RoomEvent.Reconnecting);
  fakeRoom().emit(RoomEvent.Reconnected);
  expect(events.states).toEqual(["connecting", "connected", "reconnecting", "connected"]);
});

it.each([
  [DisconnectReason.DUPLICATE_IDENTITY, "duplicate_identity"],
  [DisconnectReason.ROOM_DELETED, "room_deleted"],
  [DisconnectReason.ROOM_CLOSED, "room_deleted"],
  [DisconnectReason.PARTICIPANT_REMOVED, "participant_removed"],
  [DisconnectReason.SERVER_SHUTDOWN, "server_shutdown"],
  [DisconnectReason.SIGNAL_CLOSE, "network"],
  [DisconnectReason.JOIN_FAILURE, "network"],
  [DisconnectReason.CONNECTION_TIMEOUT, "network"],
  [undefined, "unknown"],
])("server-side disconnect %s -> %s, and remote audio is cleaned up", async (reason, name) => {
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  fakeRoom().emit(RoomEvent.TrackSubscribed, fakeTrack("audio"), {}, fakeRemote("u2"));
  fakeRoom().emit(RoomEvent.Disconnected, reason);
  expect(events.disconnected).toEqual([name]);
  expect(events.states[events.states.length - 1]).toBe("disconnected");
  expect(document.body.querySelectorAll("audio")).toHaveLength(0);
  expect(session.peers()).toEqual([]);
});

it("disconnect() always reports 'client', once", async () => {
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: true, camera: false });
  await session.disconnect();
  await session.disconnect();
  expect(events.disconnected).toEqual(["client"]);
});

it("media calls before connect are an error, not a crash", async () => {
  const { session } = harness();
  expect(await session.setMic(true)).toBe("error");
  expect(await session.startAudio()).toBe(false);
  await session.disconnect();
});
```

- [ ] **Step 3: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false lkSession
```
Expected: FAIL — `Cannot find module './lkSession'`.

- [ ] **Step 4: Implement**

Create `src/lib/livekit/lkSession.ts`:

```ts
import { loadLivekit } from "./livekitLoader";

/**
 * The typed facade over LiveKit that voice rooms (P4-ROOM) and calls
 * (P4-CALL) share. Nothing outside src/lib/livekit touches the SDK: its
 * typings need TS >= 3.8, and every SDK quirk (autoplay, remote audio
 * elements, disconnect reasons) is handled once, here.
 */
export type LkMediaResult = "ok" | "denied" | "unavailable" | "error";

export interface LkPeer {
  identity: string;
  name: string;
  isLocal: boolean;
  isSpeaking: boolean;
  micOn: boolean;
  cameraOn: boolean;
  metadata: string;
}

export interface LkVideoTrack {
  attach(el: HTMLVideoElement): void;
  detach(el?: HTMLVideoElement): void;
}

export interface LkEvents {
  onPeers?(peers: LkPeer[]): void;
  onState?(s: "connecting" | "connected" | "reconnecting" | "disconnected"): void;
  onDisconnected?(reason: string): void;
  onAudioBlocked?(blocked: boolean): void;
  onRemoteVideo?(identity: string, track: LkVideoTrack | null): void;
}

export interface LkSession {
  connect(url: string, token: string, opts: { mic: boolean; camera: boolean }): Promise<LkMediaResult>;
  setMic(on: boolean): Promise<LkMediaResult>;
  setCamera(on: boolean): Promise<LkMediaResult>;
  localVideo(): LkVideoTrack | null;
  startAudio(): Promise<boolean>;
  peers(): LkPeer[];
  disconnect(): Promise<void>;
}

const DENIED = ["NotAllowedError", "SecurityError", "PermissionDeniedError"];
const UNAVAILABLE = ["NotFoundError", "DevicesNotFoundError", "OverconstrainedError", "NotReadableError", "TrackStartError"];

/** getUserMedia failures, by what the member can do about them. */
export function mediaErrorKind(err: any): LkMediaResult {
  const name = String((err && (err.name || (err.error && err.error.name))) || "");
  if (DENIED.indexOf(name) > -1) return "denied";
  if (UNAVAILABLE.indexOf(name) > -1) return "unavailable";
  return "error";
}

function hasMediaDevices(): boolean {
  return typeof navigator !== "undefined" && !!(navigator as any).mediaDevices;
}

export function createLkSession(events: LkEvents): LkSession {
  let lk: any = null;
  let room: any = null;
  let closedByClient = false;
  let finished = false;
  const audioEls: { [sid: string]: HTMLMediaElement[] } = {};

  const toPeer = (p: any, isLocal: boolean): LkPeer => ({
    identity: String((p && p.identity) || ""),
    name: String((p && p.name) || ""),
    isLocal,
    isSpeaking: !!(p && p.isSpeaking),
    micOn: !!(p && p.isMicrophoneEnabled),
    cameraOn: !!(p && p.isCameraEnabled),
    metadata: String((p && p.metadata) || ""),
  });

  const peers = (): LkPeer[] => {
    if (!room) return [];
    const out: LkPeer[] = [toPeer(room.localParticipant, true)];
    room.remoteParticipants.forEach((p: any) => out.push(toPeer(p, false)));
    return out;
  };
  const emitPeers = () => {
    if (events.onPeers) events.onPeers(peers());
  };
  const wrapTrack = (track: any): LkVideoTrack => ({
    attach: (el: HTMLVideoElement) => {
      track.attach(el);
    },
    detach: (el?: HTMLVideoElement) => {
      if (el) track.detach(el);
      else track.detach();
    },
  });

  const reasonName = (reason: any): string => {
    if (closedByClient) return "client";
    const R = (lk && lk.DisconnectReason) || {};
    if (reason === undefined || reason === null) return "unknown";
    if (reason === R.CLIENT_INITIATED) return "client";
    if (reason === R.DUPLICATE_IDENTITY) return "duplicate_identity";
    if (reason === R.ROOM_DELETED || reason === R.ROOM_CLOSED) return "room_deleted";
    if (reason === R.PARTICIPANT_REMOVED) return "participant_removed";
    if (reason === R.SERVER_SHUTDOWN) return "server_shutdown";
    if (
      reason === R.JOIN_FAILURE ||
      reason === R.SIGNAL_CLOSE ||
      reason === R.CONNECTION_TIMEOUT ||
      reason === R.MEDIA_FAILURE ||
      reason === R.STATE_MISMATCH
    ) {
      return "network";
    }
    return "unknown";
  };

  const removeAudio = (sid?: string) => {
    const keys = sid ? [sid] : Object.keys(audioEls);
    keys.forEach((k) => {
      (audioEls[k] || []).forEach((el) => {
        if (el.parentNode) el.parentNode.removeChild(el);
      });
      delete audioEls[k];
    });
  };

  const finish = (reason: any) => {
    if (finished) return;
    finished = true;
    removeAudio();
    const name = reasonName(reason);
    room = null;
    if (events.onState) events.onState("disconnected");
    if (events.onDisconnected) events.onDisconnected(name);
  };

  const wire = (r: any) => {
    const E = lk.RoomEvent;
    [
      E.ParticipantConnected,
      E.ParticipantDisconnected,
      E.ActiveSpeakersChanged,
      E.TrackMuted,
      E.TrackUnmuted,
      E.LocalTrackPublished,
      E.LocalTrackUnpublished,
      E.ParticipantMetadataChanged,
    ].forEach((ev: string) => r.on(ev, emitPeers));

    r.on(E.TrackSubscribed, (track: any, _pub: any, participant: any) => {
      if (track && track.kind === "audio") {
        const el = track.attach() as HTMLMediaElement;
        el.setAttribute("data-lk-audio", "1");
        el.style.display = "none";
        document.body.appendChild(el);
        audioEls[track.sid] = (audioEls[track.sid] || []).concat([el]);
      } else if (track && track.kind === "video" && events.onRemoteVideo) {
        events.onRemoteVideo(String(participant && participant.identity), wrapTrack(track));
      }
      emitPeers();
    });
    r.on(E.TrackUnsubscribed, (track: any, _pub: any, participant: any) => {
      if (track && track.kind === "audio") {
        track.detach();
        removeAudio(track.sid);
      } else if (track && track.kind === "video" && events.onRemoteVideo) {
        events.onRemoteVideo(String(participant && participant.identity), null);
      }
      emitPeers();
    });
    r.on(E.Reconnecting, () => {
      if (events.onState) events.onState("reconnecting");
    });
    r.on(E.Reconnected, () => {
      if (events.onState) events.onState("connected");
      emitPeers();
    });
    r.on(E.AudioPlaybackStatusChanged, () => {
      if (events.onAudioBlocked && room) events.onAudioBlocked(!room.canPlaybackAudio);
    });
    r.on(E.Disconnected, (reason: any) => finish(reason));
  };

  const setMic = async (on: boolean): Promise<LkMediaResult> => {
    if (!room) return "error";
    if (on && !hasMediaDevices()) return "unavailable";
    try {
      await room.localParticipant.setMicrophoneEnabled(on);
      emitPeers();
      return "ok";
    } catch (err) {
      emitPeers();
      return mediaErrorKind(err);
    }
  };

  const setCamera = async (on: boolean): Promise<LkMediaResult> => {
    if (!room) return "error";
    if (on && !hasMediaDevices()) return "unavailable";
    try {
      await room.localParticipant.setCameraEnabled(on);
      emitPeers();
      return "ok";
    } catch (err) {
      emitPeers();
      return mediaErrorKind(err);
    }
  };

  return {
    async connect(url, token, opts) {
      lk = await loadLivekit();
      closedByClient = false;
      finished = false;
      const r = new lk.Room({ adaptiveStream: true, dynacast: true });
      room = r;
      wire(r);
      if (events.onState) events.onState("connecting");
      try {
        await r.connect(url, token);
      } catch (err) {
        room = null;
        finished = true;
        if (events.onState) events.onState("disconnected");
        throw err;
      }
      if (events.onState) events.onState("connected");
      if (!r.canPlaybackAudio && events.onAudioBlocked) events.onAudioBlocked(true);
      emitPeers();
      let result: LkMediaResult = "ok";
      if (opts.mic) result = await setMic(true);
      if (opts.camera) {
        const cam = await setCamera(true);
        if (result === "ok") result = cam;
      }
      return result;
    },
    setMic,
    setCamera,
    localVideo() {
      if (!room || !lk) return null;
      const pub = room.localParticipant.getTrackPublication(lk.Track.Source.Camera);
      const track = pub && pub.videoTrack;
      return track ? wrapTrack(track) : null;
    },
    async startAudio() {
      if (!room) return false;
      try {
        await room.startAudio();
      } catch (err) {
        return false;
      }
      const ok = !!(room && room.canPlaybackAudio);
      if (events.onAudioBlocked) events.onAudioBlocked(!ok);
      return ok;
    },
    peers,
    async disconnect() {
      if (!room || finished) return;
      closedByClient = true;
      const r = room;
      try {
        await r.disconnect();
      } finally {
        // LiveKit emits Disconnected itself; this covers an SDK that did not.
        finish(undefined);
      }
    },
  };
}
```

- [ ] **Step 5: Run → PASS, plus the loader guard**

```bash
CI=true npm test -- --watchAll=false lkSession livekitLoader
npx tsc -p . 2>&1 | grep "error TS" | grep -c -i livekit
```
Expected: all pass (the loader test's "only the loader names the package" case still passes — neither new file contains that string); grep prints `0`.

- [ ] **Step 6: Commit**

```bash
git add src/lib/livekit/lkSession.ts src/lib/livekit/lkSession.test.ts src/lib/livekit/testing/fakeLivekit.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(livekit): typed session facade shared by voice rooms and calls

createLkSession wraps Room: connect (a denied mic or camera resolves
with the reason instead of failing the join), mic/camera, local video,
remote audio in hidden elements, remote video handed to the caller,
Safari audio unlock, reconnect states and disconnect reasons
(duplicate identity, room deleted, removed, network). A Jest fake of
the module namespace goes with it.

Still open (Phase 4 rooms): voice rooms, language rooms, City/Genders
tabs, i18n, push. CALLS branches from this commit.
EOF
git log --oneline -1     # tell the coordinator this hash: P4-CALL-0 branches from it
```

---

### Task P4-ROOM-3: Voice rooms REST slice (list, detail, create, join, token, leave, end, promote, RSVP)

**Files:**
- Create: `src/store/slices/voiceRoomsSlice.ts`
- Test: `src/store/slices/voiceRoomsEndpoints.test.ts` (new; harness copied from `chatActionsEndpoints.test.ts:13-45`)

**Interfaces:**
- Consumes (`be/routes/voiceRooms.js`, all behind `protect`):
  - `GET /api/v1/voicerooms?status=&language=&page=&limit=` → `{data: Room[], pagination:{total,page,limit,hasMore}}`; list rows carry `_id,title,description,topic,language,secondaryLanguage,host{_id,name,images},participantCount,maxParticipants,participants[≤5]{_id,name,images,role,isSpeaking},status,tags,scheduledFor,rsvps[{user}],category,createdAt` (`be/controllers/voiceRooms.js:76-102`). Default status = waiting+active with a heartbeat in the last 60 s; `status=scheduled`; `status=all`.
  - `GET /voicerooms/:id` → full document, `host`/`coHosts`/`participants.user` populated; 404 for a block relationship (`:118-145`).
  - `GET /voicerooms/my` → the caller's active room or `null` (`:632`).
  - `POST /voicerooms {title, description?, topic?, language, secondaryLanguage?, maxParticipants?, isPublic?, tags?, category?, scheduledFor?}` → 201 `{data: room}`; 403 "Voice rooms are not available for your account type…" from `checkVoiceRoomAccess` (`be/middleware/checkLimitations.js:244-268`); 400 title/language required; `category ∈ casual|language_practice|topic|qa`; `maxParticipants` clamped 2..50 (and by tier).
  - `POST /:id/join` → 200 (idempotent, `alreadyJoined:true` when already in); 400 "Room is full"/"This room has ended"; 403 "You cannot join this room" (block) (`:277-352`).
  - `POST /:id/token` → `{data:{token,url,roomName,role:"host"|"participant"}}`; 403 before `/join` (`:358-416`; contract test `webFeatureContracts.test.js` "voice rooms").
  - `POST /:id/leave`, `POST /:id/end` (host/co-host/admin, 403 otherwise), `PUT /:id/promote/:userId` (host only → co-host), `POST|DELETE /:id/rsvp` (scheduled rooms only).
- Produces: `voiceRoomsApiSlice` with hooks `useGetVoiceRoomsQuery({status?, language?, page?})`, `useGetVoiceRoomQuery(id)`, `useGetMyVoiceRoomQuery()`, `useCreateVoiceRoomMutation()`, `useJoinVoiceRoomMutation()`, `useGetVoiceRoomTokenMutation()`, `useLeaveVoiceRoomMutation()`, `useEndVoiceRoomMutation()`, `usePromoteVoiceParticipantMutation()`, `useRsvpVoiceRoomMutation()`; `VOICE_ROOMS_URL = "/api/v1/voicerooms"`; types `VoiceRoomSummary`, `VoiceRoomToken`; `voiceRoomErrorText(err, t)`.

- [ ] **Step 1: Write the failing tests**

Create `src/store/slices/voiceRoomsEndpoints.test.ts`:

```ts
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { voiceRoomsApiSlice, VOICE_ROOMS_URL, voiceRoomErrorText } from "./voiceRoomsSlice";

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

function mockFetch(payload: any = { success: true, data: {} }): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify(payload), { status: 200, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const ep = (name: string) => (voiceRoomsApiSlice.endpoints as any)[name];

it("lists live rooms by default and passes status/language/page", async () => {
  const calls = mockFetch({ success: true, data: [], pagination: { hasMore: false } });
  const store = makeStore();
  await store.dispatch(ep("getVoiceRooms").initiate({}));
  await store.dispatch(ep("getVoiceRooms").initiate({ status: "scheduled", language: "Korean", page: 2 }));
  const first = new URL(calls[0].url);
  expect(first.pathname).toBe(VOICE_ROOMS_URL);
  expect(first.searchParams.get("status")).toBe(null);
  expect(first.searchParams.get("page")).toBe("1");
  const second = new URL(calls[1].url);
  expect(second.searchParams.get("status")).toBe("scheduled");
  expect(second.searchParams.get("language")).toBe("Korean");
  expect(second.searchParams.get("page")).toBe("2");
});

it.each([
  ["joinVoiceRoom", "r1", "POST", "/r1/join"],
  ["getVoiceRoomToken", "r1", "POST", "/r1/token"],
  ["leaveVoiceRoom", "r1", "POST", "/r1/leave"],
  ["endVoiceRoom", "r1", "POST", "/r1/end"],
])("%s -> %s %s", async (name, arg, method, suffix) => {
  const calls = mockFetch();
  await makeStore().dispatch(ep(name).initiate(arg));
  expect(calls[0].method).toBe(method);
  expect(new URL(calls[0].url).pathname).toBe(`${VOICE_ROOMS_URL}${suffix}`);
});

it("creates with the app's body and drops empty optional fields", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(
    ep("createVoiceRoom").initiate({
      title: "Evening Korean",
      description: "",
      topic: "language_exchange",
      language: "Korean",
      maxParticipants: 8,
      category: "language_practice",
      scheduledFor: undefined,
    })
  );
  expect(calls[0].method).toBe("POST");
  expect(new URL(calls[0].url).pathname).toBe(VOICE_ROOMS_URL);
  expect(JSON.parse(calls[0].body as string)).toEqual({
    title: "Evening Korean",
    topic: "language_exchange",
    language: "Korean",
    maxParticipants: 8,
    category: "language_practice",
  });
});

it("promotes with PUT /:id/promote/:userId and RSVPs with POST/DELETE", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("promoteVoiceParticipant").initiate({ roomId: "r1", userId: "u9" }));
  await store.dispatch(ep("rsvpVoiceRoom").initiate({ roomId: "r1", going: true }));
  await store.dispatch(ep("rsvpVoiceRoom").initiate({ roomId: "r1", going: false }));
  expect([calls[0].method, new URL(calls[0].url).pathname]).toEqual(["PUT", `${VOICE_ROOMS_URL}/r1/promote/u9`]);
  expect([calls[1].method, new URL(calls[1].url).pathname]).toEqual(["POST", `${VOICE_ROOMS_URL}/r1/rsvp`]);
  expect([calls[2].method, new URL(calls[2].url).pathname]).toEqual(["DELETE", `${VOICE_ROOMS_URL}/r1/rsvp`]);
});

describe("voiceRoomErrorText", () => {
  const t = () => "";
  it.each([
    [{ status: 400, data: { error: "Room is full" } }, "This room is full."],
    [{ status: 400, data: { error: "This room has ended" } }, "This room has ended."],
    [{ status: 403, data: { error: "You cannot join this room" } }, "You can't join this room."],
    [
      { status: 403, data: { error: "Voice rooms are not available for your account type. Upgrade to create voice rooms." } },
      "Creating voice rooms needs a VIP plan.",
    ],
    [{ status: 404, data: { error: "Voice room not found" } }, "This room is no longer available."],
    [{ status: 500, data: { error: "Mongo exploded" } }, "Something went wrong. Try again."],
    [undefined, "Something went wrong. Try again."],
  ])("%j", (err, text) => {
    expect(voiceRoomErrorText(err, t)).toBe(text);
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-rooms && CI=true npm test -- --watchAll=false voiceRoomsEndpoints
```
Expected: FAIL — `Cannot find module './voiceRoomsSlice'`.

- [ ] **Step 3: Implement**

Create `src/store/slices/voiceRoomsSlice.ts`:

```ts
import { apiSlice } from "./apiSlice";

/** Voice rooms (LiveKit audio rooms). Same endpoints as the app. */
export const VOICE_ROOMS_URL = "/api/v1/voicerooms";

export interface VoiceRoomUser {
  _id: string;
  name?: string;
  images?: string[];
}

export interface VoiceRoomSummary {
  _id: string;
  title: string;
  description?: string;
  topic?: string;
  language: string;
  secondaryLanguage?: string;
  host: VoiceRoomUser | string;
  participantCount?: number;
  maxParticipants: number;
  participants?: Array<{ _id?: string; name?: string; images?: string[]; role?: string; isSpeaking?: boolean }>;
  status: "scheduled" | "waiting" | "active" | "ended";
  tags?: string[];
  scheduledFor?: string | null;
  rsvps?: Array<{ user: string }>;
  category?: string | null;
  createdAt?: string;
}

export interface VoiceRoomToken {
  token: string;
  url: string;
  roomName: string;
  role: "host" | "participant";
}

export interface CreateVoiceRoomBody {
  title: string;
  description?: string;
  topic?: string;
  language: string;
  secondaryLanguage?: string;
  maxParticipants?: number;
  category?: string;
  scheduledFor?: string;
}

const compact = (obj: { [k: string]: any }) => {
  const out: { [k: string]: any } = {};
  Object.keys(obj).forEach((k) => {
    const v = obj[k];
    if (v !== undefined && v !== null && v !== "") out[k] = v;
  });
  return out;
};

const tagged = apiSlice.enhanceEndpoints({ addTagTypes: ["VoiceRooms"] });

export const voiceRoomsApiSlice = tagged.injectEndpoints({
  endpoints: (builder: any) => ({
    getVoiceRooms: builder.query({
      query: (arg: { status?: "scheduled" | "all"; language?: string; page?: number } = {}) => ({
        url: VOICE_ROOMS_URL,
        params: compact({ status: arg.status, language: arg.language, page: String(arg.page || 1), limit: "20" }),
      }),
      keepUnusedDataFor: 15,
      providesTags: ["VoiceRooms"],
    }),
    getVoiceRoom: builder.query({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}` }),
      transformResponse: (r: any) => (r && r.data) || null,
      keepUnusedDataFor: 5,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "VoiceRooms", id }],
    }),
    getMyVoiceRoom: builder.query({
      query: () => ({ url: `${VOICE_ROOMS_URL}/my` }),
      transformResponse: (r: any) => (r && r.data) || null,
      keepUnusedDataFor: 0,
    }),
    createVoiceRoom: builder.mutation({
      query: (body: CreateVoiceRoomBody) => ({ url: VOICE_ROOMS_URL, method: "POST", body: compact(body as any) }),
      invalidatesTags: ["VoiceRooms"],
    }),
    joinVoiceRoom: builder.mutation({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}/join`, method: "POST" }),
    }),
    getVoiceRoomToken: builder.mutation({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}/token`, method: "POST" }),
      transformResponse: (r: any): VoiceRoomToken => r && r.data,
    }),
    leaveVoiceRoom: builder.mutation({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}/leave`, method: "POST" }),
      invalidatesTags: ["VoiceRooms"],
    }),
    endVoiceRoom: builder.mutation({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}/end`, method: "POST" }),
      invalidatesTags: ["VoiceRooms"],
    }),
    promoteVoiceParticipant: builder.mutation({
      query: ({ roomId, userId }: { roomId: string; userId: string }) => ({
        url: `${VOICE_ROOMS_URL}/${roomId}/promote/${userId}`,
        method: "PUT",
      }),
      invalidatesTags: (_r: any, _e: any, arg: { roomId: string }) => [{ type: "VoiceRooms", id: arg.roomId }],
    }),
    rsvpVoiceRoom: builder.mutation({
      query: ({ roomId, going }: { roomId: string; going: boolean }) => ({
        url: `${VOICE_ROOMS_URL}/${roomId}/rsvp`,
        method: going ? "POST" : "DELETE",
      }),
      invalidatesTags: ["VoiceRooms"],
    }),
  }),
});

/**
 * The backend's refusal, in words a member can act on. Never the raw server
 * string: those are English-only and some are written for developers.
 */
export function voiceRoomErrorText(err: any, t: (k: string) => string): string {
  const raw = String((err && err.data && (err.data.error || err.data.message)) || "");
  if (/Room is full/i.test(raw)) return t("voiceRooms.errors.full") || "This room is full.";
  if (/has ended/i.test(raw)) return t("voiceRooms.errors.ended") || "This room has ended.";
  if (/cannot join/i.test(raw)) return t("voiceRooms.errors.blocked") || "You can't join this room.";
  if (/not available for your account type/i.test(raw))
    return t("voiceRooms.errors.vipToCreate") || "Creating voice rooms needs a VIP plan.";
  if (err && err.status === 404) return t("voiceRooms.errors.gone") || "This room is no longer available.";
  return t("voiceRooms.errors.generic") || "Something went wrong. Try again.";
}

export const {
  useGetVoiceRoomsQuery,
  useGetVoiceRoomQuery,
  useGetMyVoiceRoomQuery,
  useCreateVoiceRoomMutation,
  useJoinVoiceRoomMutation,
  useGetVoiceRoomTokenMutation,
  useLeaveVoiceRoomMutation,
  useEndVoiceRoomMutation,
  usePromoteVoiceParticipantMutation,
  useRsvpVoiceRoomMutation,
} = voiceRoomsApiSlice as any;
```

Add to `src/utils/locales/eng.json` under a new top-level `"voiceRooms"` object:

```json
"errors": {
  "full": "This room is full.",
  "ended": "This room has ended.",
  "blocked": "You can't join this room.",
  "vipToCreate": "Creating voice rooms needs a VIP plan.",
  "gone": "This room is no longer available.",
  "generic": "Something went wrong. Try again."
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false voiceRoomsEndpoints apiSlice
```
Expected: all pass (`apiSlice.test` stays green: `enhanceEndpoints` adds a tag type without touching the base slice's list).

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/voiceRoomsSlice.ts src/store/slices/voiceRoomsEndpoints.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(voice-rooms): REST slice for the app's voice room endpoints

List (live/scheduled), detail, my room, create, join, LiveKit token,
leave, end, promote to co-host, RSVP — same requests the app sends.
Refusals map to member-readable text, never the raw server string.

Still open (Phase 4 rooms): voice room pages and host tools, language
rooms, City/Genders tabs, i18n, push.
EOF
```

---

### Task P4-ROOM-4: Voice rooms list page with create dialog and scheduled-room RSVP

**Files:**
- Create: `src/components/voiceRooms/VoiceRoomsPage.tsx`, `src/components/voiceRooms/CreateVoiceRoomDialog.tsx`, `src/components/voiceRooms/VoiceRooms.scss`
- Modify: `src/utils/locales/eng.json` (`voiceRooms.list.*`, `voiceRooms.create.*`)
- Test: `src/components/voiceRooms/VoiceRoomsPage.test.tsx`, `src/components/voiceRooms/CreateVoiceRoomDialog.test.tsx` (new)

**Interfaces:**
- Consumes: `useGetVoiceRoomsQuery`, `useCreateVoiceRoomMutation`, `useRsvpVoiceRoomMutation`, `voiceRoomErrorText` (P4-ROOM-3); `state.auth.userInfo.user` (`_id`, `language_to_learn`, `native_language`); `photoUrl(images)` (`src/utils/photoUrl.ts:8`); `notify` (`src/design/notify`).
- Produces: default export `VoiceRoomsPage` (route `/voice-rooms`, wired in P4-ROOM-12); default export `CreateVoiceRoomDialog` props `{ open: boolean; defaultLanguage: string; onClose(): void; onCreated(roomId: string): void }`; named `buildCreateBody(form)`. Test ids: `voice-rooms-page`, `voice-rooms-tab-live`, `voice-rooms-tab-scheduled`, `voice-room-card-<id>`, `voice-room-join-<id>`, `voice-room-rsvp-<id>`, `voice-rooms-create`, `voice-rooms-empty`, `create-voice-room-dialog`, `create-voice-room-title`, `create-voice-room-language`, `create-voice-room-category`, `create-voice-room-max`, `create-voice-room-when`, `create-voice-room-submit`, `create-voice-room-error`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/voiceRooms/CreateVoiceRoomDialog.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import CreateVoiceRoomDialog, { buildCreateBody } from "./CreateVoiceRoomDialog";

const mockCreate = jest.fn();
jest.mock("../../store/slices/voiceRoomsSlice", () => ({
  useCreateVoiceRoomMutation: () => [mockCreate, { isLoading: false }],
  voiceRoomErrorText: (err: any) => (err && err.status === 403 ? "Creating voice rooms needs a VIP plan." : "Something went wrong. Try again."),
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

beforeEach(() => mockCreate.mockReset());

it("builds the app's body: trimmed title, clamped size, ISO start only in the future", () => {
  const future = new Date(Date.now() + 3600 * 1000);
  const local = new Date(future.getTime() - future.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  expect(
    buildCreateBody({ title: "  Evening Korean ", description: "", language: "Korean", category: "language_practice", maxParticipants: 80, when: local })
  ).toEqual({
    title: "Evening Korean",
    topic: "language_exchange",
    language: "Korean",
    category: "language_practice",
    maxParticipants: 50,
    scheduledFor: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
  });
  expect(buildCreateBody({ title: "x", description: "d", language: "ko", category: "", maxParticipants: 1, when: "" })).toEqual({
    title: "x",
    description: "d",
    topic: "language_exchange",
    language: "ko",
    maxParticipants: 2,
  });
});

it("creates and hands back the new room id", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.resolve({ success: true, data: { _id: "r9" } }) });
  const onCreated = jest.fn();
  render(<CreateVoiceRoomDialog open defaultLanguage="Korean" onClose={jest.fn()} onCreated={onCreated} />);
  expect((screen.getByTestId("create-voice-room-language") as HTMLInputElement).value).toBe("Korean");
  expect(screen.getByTestId("create-voice-room-submit")).toBeDisabled();
  fireEvent.change(screen.getByTestId("create-voice-room-title"), { target: { value: "Evening Korean" } });
  fireEvent.click(screen.getByTestId("create-voice-room-submit"));
  await waitFor(() => expect(onCreated).toHaveBeenCalledWith("r9"));
  expect(mockCreate).toHaveBeenCalledWith(expect.objectContaining({ title: "Evening Korean", language: "Korean", maxParticipants: 8 }));
});

it("shows the VIP refusal inside the dialog", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.reject({ status: 403, data: { error: "Voice rooms are not available for your account type." } }) });
  render(<CreateVoiceRoomDialog open defaultLanguage="Korean" onClose={jest.fn()} onCreated={jest.fn()} />);
  fireEvent.change(screen.getByTestId("create-voice-room-title"), { target: { value: "Room" } });
  fireEvent.click(screen.getByTestId("create-voice-room-submit"));
  await waitFor(() => expect(screen.getByTestId("create-voice-room-error")).toHaveTextContent("VIP"));
});

it("renders nothing when closed", () => {
  render(<CreateVoiceRoomDialog open={false} defaultLanguage="" onClose={jest.fn()} onCreated={jest.fn()} />);
  expect(screen.queryByTestId("create-voice-room-dialog")).not.toBeInTheDocument();
});
```

Create `src/components/voiceRooms/VoiceRoomsPage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import VoiceRoomsPage from "./VoiceRoomsPage";

let mockRooms: any = { data: { data: [] }, isLoading: false, isError: false };
const mockArgs: any[] = [];
const mockRsvp = jest.fn();
jest.mock("../../store/slices/voiceRoomsSlice", () => ({
  useGetVoiceRoomsQuery: (arg: any) => {
    mockArgs.push(arg);
    return mockRooms;
  },
  useRsvpVoiceRoomMutation: () => [mockRsvp, { isLoading: false }],
  useCreateVoiceRoomMutation: () => [jest.fn(), { isLoading: false }],
  voiceRoomErrorText: () => "Something went wrong. Try again.",
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const room = (over: any = {}) => ({
  _id: "r1",
  title: "Evening Korean",
  language: "Korean",
  host: { _id: "h1", name: "Mina", images: [] },
  participantCount: 3,
  maxParticipants: 8,
  participants: [],
  status: "active",
  rsvps: [],
  ...over,
});

function renderPage() {
  const store = configureStore({
    reducer: { auth: (s: any = { userInfo: { user: { _id: "me", language_to_learn: "Korean" } } }) => s },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/voice-rooms"]}>
        <Routes>
          <Route path="/voice-rooms" element={<VoiceRoomsPage />} />
          <Route path="/voice-rooms/:id" element={<div data-testid="room-page" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockArgs.length = 0;
  mockRsvp.mockReset();
  mockRsvp.mockReturnValue({ unwrap: () => Promise.resolve({}) });
});

it("lists live rooms with host, language and fill, and opens one", () => {
  mockRooms = { data: { data: [room()] }, isLoading: false, isError: false };
  renderPage();
  const card = screen.getByTestId("voice-room-card-r1");
  expect(card).toHaveTextContent("Evening Korean");
  expect(card).toHaveTextContent("Mina");
  expect(card).toHaveTextContent("3/8");
  fireEvent.click(screen.getByTestId("voice-room-join-r1"));
  expect(screen.getByTestId("room-page")).toBeInTheDocument();
});

it("a full room cannot be joined from the list", () => {
  mockRooms = { data: { data: [room({ participantCount: 8 })] }, isLoading: false, isError: false };
  renderPage();
  expect(screen.getByTestId("voice-room-join-r1")).toBeDisabled();
});

it("switches to scheduled rooms and RSVPs", () => {
  mockRooms = { data: { data: [room({ status: "scheduled", scheduledFor: "2030-01-01T10:00:00.000Z" })] }, isLoading: false, isError: false };
  renderPage();
  fireEvent.click(screen.getByTestId("voice-rooms-tab-scheduled"));
  expect(mockArgs[mockArgs.length - 1]).toEqual({ status: "scheduled", page: 1 });
  fireEvent.click(screen.getByTestId("voice-room-rsvp-r1"));
  expect(mockRsvp).toHaveBeenCalledWith({ roomId: "r1", going: true });
});

it("shows RSVP'd rooms as going and lets the member cancel", () => {
  mockRooms = { data: { data: [room({ status: "scheduled", rsvps: [{ user: "me" }] })] }, isLoading: false, isError: false };
  renderPage();
  fireEvent.click(screen.getByTestId("voice-rooms-tab-scheduled"));
  fireEvent.click(screen.getByTestId("voice-room-rsvp-r1"));
  expect(mockRsvp).toHaveBeenCalledWith({ roomId: "r1", going: false });
});

it("has an empty state and a create button", () => {
  mockRooms = { data: { data: [] }, isLoading: false, isError: false };
  renderPage();
  expect(screen.getByTestId("voice-rooms-empty")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("voice-rooms-create"));
  expect(screen.getByTestId("create-voice-room-dialog")).toBeInTheDocument();
});

it("survives an unpopulated host (legacy row)", () => {
  mockRooms = { data: { data: [room({ host: "h1", participants: undefined, participantCount: undefined })] }, isLoading: false, isError: false };
  renderPage();
  expect(screen.getByTestId("voice-room-card-r1")).toHaveTextContent("0/8");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false voiceRooms/
```
Expected: FAIL — `Cannot find module './CreateVoiceRoomDialog'` / `'./VoiceRoomsPage'`.

- [ ] **Step 3: Implement**

Create `src/components/voiceRooms/CreateVoiceRoomDialog.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { useCreateVoiceRoomMutation, voiceRoomErrorText, CreateVoiceRoomBody } from "../../store/slices/voiceRoomsSlice";

export const VOICE_ROOM_CATEGORIES = ["casual", "language_practice", "topic", "qa"];

export interface CreateVoiceRoomForm {
  title: string;
  description: string;
  language: string;
  category: string;
  maxParticipants: number;
  /** <input type="datetime-local"> value, local time, or "" for "start now". */
  when: string;
}

/** The body the app sends (POST /voicerooms). A past start time means "now". */
export function buildCreateBody(form: CreateVoiceRoomForm): CreateVoiceRoomBody {
  const body: CreateVoiceRoomBody = {
    title: form.title.trim(),
    topic: "language_exchange",
    language: form.language.trim(),
    maxParticipants: Math.min(50, Math.max(2, Math.round(form.maxParticipants || 8))),
  };
  if (form.description.trim()) body.description = form.description.trim();
  if (VOICE_ROOM_CATEGORIES.indexOf(form.category) > -1) body.category = form.category;
  if (form.when) {
    const start = new Date(form.when);
    if (!isNaN(start.getTime()) && start.getTime() > Date.now()) body.scheduledFor = start.toISOString();
  }
  // Key order mirrors the app's request; tests compare with toEqual, which
  // ignores order anyway.
  return body;
}

interface Props {
  open: boolean;
  defaultLanguage: string;
  onClose(): void;
  onCreated(roomId: string): void;
}

const CreateVoiceRoomDialog: React.FC<Props> = ({ open, defaultLanguage, onClose, onCreated }) => {
  const { t } = useTranslation();
  const [createRoom, { isLoading }] = useCreateVoiceRoomMutation();
  const [form, setForm] = useState<CreateVoiceRoomForm>({
    title: "",
    description: "",
    language: defaultLanguage || "",
    category: "language_practice",
    maxParticipants: 8,
    when: "",
  });
  const [error, setError] = useState("");
  if (!open) return null;

  const set = (patch: Partial<CreateVoiceRoomForm>) => setForm((f) => Object.assign({}, f, patch));
  const valid = form.title.trim().length > 0 && form.title.trim().length <= 100 && form.language.trim().length > 0;

  const submit = async () => {
    if (!valid || isLoading) return;
    setError("");
    try {
      const res = await createRoom(buildCreateBody(form)).unwrap();
      const id = res && res.data && res.data._id;
      if (id) onCreated(String(id));
    } catch (err) {
      setError(voiceRoomErrorText(err, t));
    }
  };

  return (
    <div className="vr-dialog-backdrop" role="presentation">
      <div className="vr-dialog" role="dialog" aria-modal="true" data-testid="create-voice-room-dialog">
        <h2 className="vr-dialog__title">{t("voiceRooms.create.title") || "Start a voice room"}</h2>
        <label className="vr-field">
          <span>{t("voiceRooms.create.name") || "Room name"}</span>
          <input
            data-testid="create-voice-room-title"
            value={form.title}
            maxLength={100}
            onChange={(e) => set({ title: e.target.value })}
          />
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.description") || "What will you talk about? (optional)"}</span>
          <textarea value={form.description} maxLength={500} onChange={(e) => set({ description: e.target.value })} />
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.language") || "Language"}</span>
          <input
            data-testid="create-voice-room-language"
            value={form.language}
            onChange={(e) => set({ language: e.target.value })}
          />
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.category") || "Kind of room"}</span>
          <select
            data-testid="create-voice-room-category"
            value={form.category}
            onChange={(e) => set({ category: e.target.value })}
          >
            <option value="casual">{t("voiceRooms.category.casual") || "Casual chat"}</option>
            <option value="language_practice">{t("voiceRooms.category.language_practice") || "Language practice"}</option>
            <option value="topic">{t("voiceRooms.category.topic") || "Topic"}</option>
            <option value="qa">{t("voiceRooms.category.qa") || "Q&A"}</option>
          </select>
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.max") || "Up to how many people"}</span>
          <input
            data-testid="create-voice-room-max"
            type="number"
            min={2}
            max={50}
            value={form.maxParticipants}
            onChange={(e) => set({ maxParticipants: parseInt(e.target.value, 10) || 8 })}
          />
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.when") || "Start later (optional)"}</span>
          <input
            data-testid="create-voice-room-when"
            type="datetime-local"
            value={form.when}
            onChange={(e) => set({ when: e.target.value })}
          />
        </label>
        {error && (
          <p className="vr-error" role="alert" data-testid="create-voice-room-error">
            {error}
          </p>
        )}
        <div className="vr-dialog__actions">
          <button type="button" className="vr-btn vr-btn--ghost" onClick={onClose} disabled={isLoading}>
            {t("common.cancel") || "Cancel"}
          </button>
          <button
            type="button"
            className="vr-btn vr-btn--primary"
            data-testid="create-voice-room-submit"
            disabled={!valid || isLoading}
            onClick={submit}
          >
            {form.when ? t("voiceRooms.create.schedule") || "Schedule" : t("voiceRooms.create.start") || "Start room"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default CreateVoiceRoomDialog;
```

Create `src/components/voiceRooms/VoiceRoomsPage.tsx`:

```tsx
import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Mic, Users, CalendarClock, Plus } from "lucide-react";
import {
  useGetVoiceRoomsQuery,
  useRsvpVoiceRoomMutation,
  voiceRoomErrorText,
  VoiceRoomSummary,
} from "../../store/slices/voiceRoomsSlice";
import { photoUrl } from "../../utils/photoUrl";
import notify from "../../design/notify";
import CreateVoiceRoomDialog from "./CreateVoiceRoomDialog";
import "./VoiceRooms.scss";

type Tab = "live" | "scheduled";

const hostName = (host: VoiceRoomSummary["host"]) => (host && typeof host === "object" ? host.name || "" : "");
const hostImages = (host: VoiceRoomSummary["host"]) => (host && typeof host === "object" ? host.images : undefined);

const VoiceRoomsPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user);
  const myId = me && me._id ? String(me._id) : "";
  const [tab, setTab] = useState<Tab>("live");
  const [creating, setCreating] = useState(false);
  const args = tab === "scheduled" ? { status: "scheduled", page: 1 } : { page: 1 };
  const { data, isLoading, isError, refetch } = useGetVoiceRoomsQuery(args, { pollingInterval: 30000 });
  const [rsvp] = useRsvpVoiceRoomMutation();
  const rooms: VoiceRoomSummary[] = (data && Array.isArray(data.data) ? data.data : []) as VoiceRoomSummary[];

  const toggleRsvp = async (room: VoiceRoomSummary, going: boolean) => {
    try {
      await rsvp({ roomId: room._id, going }).unwrap();
    } catch (err) {
      notify.error(voiceRoomErrorText(err, t));
    }
  };

  const formatStart = (iso?: string | null) => {
    if (!iso) return "";
    const d = new Date(iso);
    return isNaN(d.getTime())
      ? ""
      : d.toLocaleString(i18n.language, { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
  };

  return (
    <section className="vr-page" data-testid="voice-rooms-page">
      <header className="vr-page__head">
        <h1>{t("voiceRooms.list.title") || "Voice rooms"}</h1>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="voice-rooms-create" onClick={() => setCreating(true)}>
          <Plus size={16} /> {t("voiceRooms.list.create") || "Start a room"}
        </button>
      </header>
      <div className="vr-tabs" role="tablist">
        <button
          type="button"
          role="tab"
          aria-selected={tab === "live"}
          data-testid="voice-rooms-tab-live"
          className={tab === "live" ? "is-active" : ""}
          onClick={() => setTab("live")}
        >
          {t("voiceRooms.list.live") || "Live now"}
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={tab === "scheduled"}
          data-testid="voice-rooms-tab-scheduled"
          className={tab === "scheduled" ? "is-active" : ""}
          onClick={() => setTab("scheduled")}
        >
          {t("voiceRooms.list.scheduled") || "Coming up"}
        </button>
      </div>

      {isError && (
        <p className="vr-error" role="alert">
          {t("voiceRooms.list.error") || "Couldn't load voice rooms."}{" "}
          <button type="button" className="vr-link" onClick={() => refetch()}>
            {t("common.retry") || "Retry"}
          </button>
        </p>
      )}
      {!isLoading && !isError && rooms.length === 0 && (
        <p className="vr-empty" data-testid="voice-rooms-empty">
          {tab === "live"
            ? t("voiceRooms.list.emptyLive") || "No one is talking right now. Start a room and invite people in."
            : t("voiceRooms.list.emptyScheduled") || "No rooms are scheduled yet."}
        </p>
      )}

      <ul className="vr-grid">
        {rooms.map((room) => {
          const count = room.participantCount || 0;
          const full = count >= room.maxParticipants;
          const going = (room.rsvps || []).some((r) => String(r.user) === myId);
          const avatar = photoUrl(hostImages(room.host));
          return (
            <li key={room._id} className="vr-card" data-testid={`voice-room-card-${room._id}`}>
              <div className="vr-card__top">
                <span className="vr-chip">{room.language}</span>
                <span className="vr-card__count">
                  <Users size={14} /> {count}/{room.maxParticipants}
                </span>
              </div>
              <h2 className="vr-card__title">{room.title}</h2>
              {room.description && <p className="vr-card__desc">{room.description}</p>}
              <div className="vr-card__host">
                {avatar ? <img src={avatar} alt="" /> : <span className="vr-avatar-fallback" aria-hidden />}
                <span>{hostName(room.host)}</span>
              </div>
              {tab === "live" ? (
                <button
                  type="button"
                  className="vr-btn vr-btn--primary"
                  data-testid={`voice-room-join-${room._id}`}
                  disabled={full}
                  onClick={() => navigate(`/voice-rooms/${room._id}`)}
                >
                  <Mic size={16} /> {full ? t("voiceRooms.list.full") || "Full" : t("voiceRooms.list.join") || "Join"}
                </button>
              ) : (
                <div className="vr-card__scheduled">
                  <span>
                    <CalendarClock size={14} /> {formatStart(room.scheduledFor)}
                  </span>
                  <button
                    type="button"
                    className={`vr-btn ${going ? "vr-btn--ghost" : "vr-btn--primary"}`}
                    data-testid={`voice-room-rsvp-${room._id}`}
                    onClick={() => toggleRsvp(room, !going)}
                  >
                    {going ? t("voiceRooms.list.going") || "Going ✓" : t("voiceRooms.list.rsvp") || "Remind me"}
                  </button>
                </div>
              )}
            </li>
          );
        })}
      </ul>

      <CreateVoiceRoomDialog
        open={creating}
        defaultLanguage={(me && me.language_to_learn) || ""}
        onClose={() => setCreating(false)}
        onCreated={(id) => {
          setCreating(false);
          navigate(`/voice-rooms/${id}`);
        }}
      />
    </section>
  );
};

export default VoiceRoomsPage;
```

(The scheduled RSVP test expects `{ status: "scheduled", page: 1 }`; the live tab passes `{ page: 1 }` and the slice omits `status`.)

Create `src/components/voiceRooms/VoiceRooms.scss` (shared by the list and the room page; logical properties only):

```scss
.vr-page { max-width: 960px; margin-inline: auto; padding-block: 24px; padding-inline: 16px; }
.vr-page__head { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-block-end: 16px; }
.vr-page__head h1 { font-size: 1.5rem; font-weight: 800; margin: 0; }
.vr-tabs { display: flex; gap: 8px; margin-block-end: 16px; }
.vr-tabs button { border: 1px solid var(--bs-border-color, #ddd); background: transparent; border-radius: 999px; padding-block: 6px; padding-inline: 14px; font-weight: 700; }
.vr-tabs button.is-active { background: #ffd600; border-color: #ffd600; }
.vr-grid { list-style: none; padding: 0; margin: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 12px; }
.vr-card { border: 1px solid var(--bs-border-color, #eee); border-radius: 16px; padding: 16px; display: flex; flex-direction: column; gap: 8px; text-align: start; }
.vr-card__top { display: flex; justify-content: space-between; align-items: center; }
.vr-card__title { font-size: 1.05rem; font-weight: 800; margin: 0; }
.vr-card__desc { margin: 0; color: #666; font-size: 0.9rem; }
.vr-card__host { display: flex; align-items: center; gap: 8px; font-size: 0.9rem; }
.vr-card__host img, .vr-avatar-fallback { inline-size: 28px; block-size: 28px; border-radius: 50%; object-fit: cover; background: #eee; display: inline-block; }
.vr-card__scheduled { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.vr-chip { background: #fff4b3; border-radius: 999px; padding-block: 2px; padding-inline: 10px; font-size: 0.8rem; font-weight: 700; }
.vr-btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; border-radius: 999px; padding-block: 8px; padding-inline: 16px; font-weight: 800; border: 0; }
.vr-btn--primary { background: #ffd600; color: #111; }
.vr-btn--ghost { background: transparent; border: 1px solid var(--bs-border-color, #ddd); }
.vr-btn--danger { background: #e53935; color: #fff; }
.vr-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.vr-link { background: none; border: 0; padding: 0; text-decoration: underline; font-weight: 700; }
.vr-error { color: #c62828; }
.vr-empty { color: #666; padding-block: 32px; text-align: center; }
.vr-dialog-backdrop { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.45); display: flex; align-items: center; justify-content: center; z-index: 1050; }
.vr-dialog { background: var(--bs-body-bg, #fff); border-radius: 16px; padding: 20px; inline-size: min(440px, 92vw); max-block-size: 90vh; overflow: auto; display: flex; flex-direction: column; gap: 10px; }
.vr-dialog__title { font-size: 1.2rem; font-weight: 800; margin: 0; }
.vr-dialog__actions { display: flex; justify-content: flex-end; gap: 8px; }
.vr-field { display: flex; flex-direction: column; gap: 4px; font-size: 0.9rem; }
.vr-field input, .vr-field textarea, .vr-field select { border: 1px solid var(--bs-border-color, #ddd); border-radius: 10px; padding: 8px; }
```

Add to `eng.json` under `"voiceRooms"` (next to `errors`):

```json
"list": {
  "title": "Voice rooms",
  "create": "Start a room",
  "live": "Live now",
  "scheduled": "Coming up",
  "error": "Couldn't load voice rooms.",
  "emptyLive": "No one is talking right now. Start a room and invite people in.",
  "emptyScheduled": "No rooms are scheduled yet.",
  "full": "Full",
  "join": "Join",
  "going": "Going ✓",
  "rsvp": "Remind me"
},
"create": {
  "title": "Start a voice room",
  "name": "Room name",
  "description": "What will you talk about? (optional)",
  "language": "Language",
  "category": "Kind of room",
  "max": "Up to how many people",
  "when": "Start later (optional)",
  "schedule": "Schedule",
  "start": "Start room"
},
"category": {
  "casual": "Casual chat",
  "language_practice": "Language practice",
  "topic": "Topic",
  "qa": "Q&A"
}
```
(`common.cancel` / `common.retry`: use them if `eng.json` already has them — `grep -n '"common"' src/utils/locales/eng.json`; if not, add `"common": {"cancel": "Cancel", "retry": "Retry"}` only for the missing keys.)

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false voiceRooms/
```
Expected: all cases pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/voiceRooms/VoiceRoomsPage.tsx src/components/voiceRooms/CreateVoiceRoomDialog.tsx src/components/voiceRooms/VoiceRooms.scss src/components/voiceRooms/VoiceRoomsPage.test.tsx src/components/voiceRooms/CreateVoiceRoomDialog.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(voice-rooms): list page, create dialog, scheduled-room RSVP

Live and coming-up tabs over GET /voicerooms (polled every 30 s, the
server drops rooms without a heartbeat), a create dialog that sends
the app's body (VIP refusal shown in the dialog), and RSVP for
scheduled rooms. Not routed yet (P4-ROOM-12).

Still open (Phase 4 rooms): joining a room, host tools, language
rooms, City/Genders tabs, routes, i18n, push.
EOF
```

---

### Task P4-ROOM-5: `useVoiceRoom`: join → token → socket → LiveKit, heartbeat, live events, rejoin after reconnect, leave

**Files:**
- Create: `src/components/voiceRooms/voiceRoomState.ts` (pure reducer), `src/components/voiceRooms/useVoiceRoom.ts`
- Test: `src/components/voiceRooms/voiceRoomState.test.ts`, `src/components/voiceRooms/useVoiceRoom.test.tsx` (new)

**Interfaces:**
- Consumes: P4-ROOM-3 mutations (`joinVoiceRoom`, `getVoiceRoomToken`, `leaveVoiceRoom`, `endVoiceRoom`, `promoteVoiceParticipant`) and `useGetVoiceRoomQuery(id)` (detail: `host` populated, `participants[].user` populated, `participants[].{role,isMuted,isSpeaking}`); `createLkSession` (P4-ROOM-2); `useSocket()` → `{socket, connectionEpoch}` (P3-CHAT-7); `emitWithAck` + `SOCKET_ACK_TIMEOUT_MS` (P3-CHAT-5, `src/components/chat/lib/socketAck.ts`); socket events listed in the unit facts (`be/socket/voiceRoomHandler.js:189-582`).
- Order (same as the app, `voice_room_manager.dart:500-545`): `POST /:id/join` → `POST /:id/token` → emit `voiceroom:join {roomId}` → LiveKit connect **with the mic off** (everyone enters as a listener) → heartbeat `voiceroom:heartbeat {roomId}` every 30 s while live. Leave: emit `voiceroom:leave`, `POST /:id/leave` (best effort; a 400 "You are not in this room" after the socket leave is expected and ignored), LiveKit disconnect.
- Produces: `useVoiceRoom(roomId: string, myId: string): UseVoiceRoom` with
  `phase: "idle" | "joining" | "live" | "reconnecting" | "ended" | "elsewhere" | "lost" | "error"`, `error: string`, `role: "host" | "participant" | null`, `hostId: string`, `members: VoiceRoomMember[]`, `micOn: boolean`, `micProblem: "denied" | "unavailable" | "error" | null`, `handRaised: boolean`, `audioBlocked: boolean`, `chat: VoiceRoomChatLine[]`, actions `join()`, `leave()`, `setMic(on)`, `raiseHand(on)`, `sendChat(text)`, `startAudio()`, `muteAll()`, `promote(userId)`, `endRoom()`.
  `VoiceRoomMember { userId: string; name: string; images?: string[]; role: string; isMuted: boolean; isSpeaking: boolean; handRaised: boolean }`; `VoiceRoomChatLine { id: string; userId: string; name: string; message: string; at: string }`.
  Pure reducer `voiceRoomReducer(state, action)` + `initialVoiceRoomState` + `selectMembers(state, peers)`.
- Rules pinned by tests: a forced `voiceroom:mute` for me turns my LiveKit mic off; `voiceroom:ended` or `user_left{roomEnded:true}` → `ended`; LiveKit `duplicate_identity` → `elsewhere` (no auto-reconnect); `room_deleted`/`participant_removed` → `ended`; `network`/`unknown`/`server_shutdown` → `lost` (the page offers "Rejoin"); a socket reconnect (`connectionEpoch` change) while live → `voiceroom:rejoin` with ack; ack `{ended:true}` → `ended`; ack `currentHostId` updates `hostId`; unmount while live leaves; `pagehide` leaves.

- [ ] **Step 1: Write the failing tests**

Create `src/components/voiceRooms/voiceRoomState.test.ts`:

```ts
import { voiceRoomReducer, initialVoiceRoomState, selectMembers } from "./voiceRoomState";

const detail = {
  host: { _id: "h1", name: "Mina", images: ["a.jpg"] },
  participants: [
    { user: { _id: "h1", name: "Mina", images: ["a.jpg"] }, role: "host", isMuted: false },
    { user: { _id: "u2", name: "Ana" }, role: "listener", isMuted: true },
  ],
};

it("seeds from the room detail, host first", () => {
  const s = voiceRoomReducer(initialVoiceRoomState, { type: "detail", room: detail });
  expect(s.hostId).toBe("h1");
  expect(selectMembers(s, []).map((m) => [m.userId, m.role, m.isMuted])).toEqual([
    ["h1", "host", false],
    ["u2", "listener", true],
  ]);
});

it("adds a joiner with or without a populated user, and removes a leaver", () => {
  let s = voiceRoomReducer(initialVoiceRoomState, { type: "detail", room: detail });
  s = voiceRoomReducer(s, { type: "joined", payload: { user: { _id: "u3", name: "Sam" } } });
  s = voiceRoomReducer(s, { type: "joined", payload: { userId: "u4" } });
  expect(selectMembers(s, []).map((m) => m.userId)).toEqual(["h1", "u2", "u3", "u4"]);
  s = voiceRoomReducer(s, { type: "left", payload: { userId: "u2", roomEnded: false } });
  expect(selectMembers(s, []).map((m) => m.userId)).toEqual(["h1", "u3", "u4"]);
  expect(s.ended).toBe(false);
  s = voiceRoomReducer(s, { type: "left", payload: { userId: "h1", roomEnded: true } });
  expect(s.ended).toBe(true);
});

it("tracks mute and raised hands; a joiner that left loses the hand", () => {
  let s = voiceRoomReducer(initialVoiceRoomState, { type: "detail", room: detail });
  s = voiceRoomReducer(s, { type: "hand", payload: { userId: "u2", isRaised: true, user: { _id: "u2", name: "Ana" } } });
  s = voiceRoomReducer(s, { type: "mute", payload: { userId: "h1", isMuted: true } });
  const m = selectMembers(s, []);
  expect(m.find((x) => x.userId === "u2")!.handRaised).toBe(true);
  expect(m.find((x) => x.userId === "h1")!.isMuted).toBe(true);
});

it("LiveKit is the truth for speaking and mic once connected", () => {
  const s = voiceRoomReducer(initialVoiceRoomState, { type: "detail", room: detail });
  const m = selectMembers(s, [
    { identity: "u2", name: "Ana", isLocal: false, isSpeaking: true, micOn: true, cameraOn: false, metadata: "" },
  ]);
  const ana = m.find((x) => x.userId === "u2")!;
  expect(ana.isSpeaking).toBe(true);
  expect(ana.isMuted).toBe(false);
});

it("keeps the last 200 chat lines and changes host", () => {
  let s = initialVoiceRoomState;
  for (let i = 0; i < 205; i += 1) {
    s = voiceRoomReducer(s, { type: "chat", payload: { message: `m${i}`, user: { _id: "u2", name: "Ana" }, timestamp: "2026-10-16T10:00:00Z" } });
  }
  expect(s.chat).toHaveLength(200);
  expect(s.chat[0].message).toBe("m5");
  s = voiceRoomReducer(s, { type: "host", hostId: "u2" });
  expect(s.hostId).toBe("u2");
});
```

Create `src/components/voiceRooms/useVoiceRoom.test.tsx`:

```tsx
import React from "react";
import { render, act, waitFor } from "@testing-library/react";
import { useVoiceRoom, UseVoiceRoom } from "./useVoiceRoom";
import { fakeRoom, failNextMedia, resetFakeLivekit, RoomEvent, DisconnectReason } from "../../lib/livekit/testing/fakeLivekit";

jest.mock("../../lib/livekit/livekitLoader", () => require("../../lib/livekit/testing/fakeLivekit").loaderMock());

// ---- socket fake -----------------------------------------------------------
type H = (...a: any[]) => void;
const handlers: { [e: string]: H[] } = {};
const emitted: Array<[string, any]> = [];
let rejoinAck: any = { ok: true, ended: false, currentHostId: "h1" };
const mockSocket = {
  connected: true,
  on: (e: string, h: H) => ((handlers[e] = handlers[e] || []).push(h)),
  off: (e: string, h: H) => (handlers[e] = (handlers[e] || []).filter((x) => x !== h)),
  emit: (e: string, p: any, cb?: (r: any) => void) => {
    emitted.push([e, p]);
    if (e === "voiceroom:rejoin" && cb) cb(rejoinAck);
  },
};
const serverSays = (e: string, p: any) => act(() => (handlers[e] || []).slice().forEach((h) => h(p)));
let mockEpoch = 0;
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: mockSocket, isConnected: true, emit: jest.fn(), connectionEpoch: mockEpoch, kicked: false, reconnect: jest.fn() }),
}));

// ---- REST fakes -------------------------------------------------------------
const ok = (data: any) => ({ unwrap: () => Promise.resolve(data) });
const mockJoin = jest.fn(() => ok({ success: true }));
const mockToken = jest.fn(() => ok({ token: "tok", url: "wss://lk.test", roomName: "r1", role: "participant" }));
const mockLeave = jest.fn(() => ok({}));
const mockEnd = jest.fn(() => ok({}));
const mockPromote = jest.fn(() => ok({}));
jest.mock("../../store/slices/voiceRoomsSlice", () => ({
  useGetVoiceRoomQuery: () => ({
    data: { _id: "r1", host: { _id: "h1", name: "Mina" }, participants: [{ user: { _id: "h1", name: "Mina" }, role: "host" }] },
    refetch: jest.fn(),
  }),
  useJoinVoiceRoomMutation: () => [mockJoin],
  useGetVoiceRoomTokenMutation: () => [mockToken],
  useLeaveVoiceRoomMutation: () => [mockLeave],
  useEndVoiceRoomMutation: () => [mockEnd],
  usePromoteVoiceParticipantMutation: () => [mockPromote],
  voiceRoomErrorText: () => "This room is full.",
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

let api: UseVoiceRoom;
function Probe() {
  api = useVoiceRoom("r1", "me");
  return null;
}

beforeEach(() => {
  resetFakeLivekit();
  Object.keys(handlers).forEach((k) => delete handlers[k]);
  emitted.length = 0;
  mockEpoch = 0;
  rejoinAck = { ok: true, ended: false, currentHostId: "h1" };
  jest.clearAllMocks();
  jest.useFakeTimers();
});
afterEach(() => jest.useRealTimers());

async function joinRoom() {
  const view = render(<Probe />);
  await act(async () => {
    await api.join();
  });
  return view;
}

it("joins in the app's order, enters muted, and heartbeats every 30 s", async () => {
  await joinRoom();
  expect(mockJoin).toHaveBeenCalledWith("r1");
  expect(mockToken).toHaveBeenCalledWith("r1");
  expect(emitted[0]).toEqual(["voiceroom:join", { roomId: "r1" }]);
  expect(fakeRoom().connect).toHaveBeenCalledWith("wss://lk.test", "tok");
  expect(fakeRoom().localParticipant.setMicrophoneEnabled).not.toHaveBeenCalled();
  expect(api.phase).toBe("live");
  expect(api.role).toBe("participant");
  expect(api.micOn).toBe(false);
  act(() => {
    jest.advanceTimersByTime(30000);
  });
  expect(emitted.filter(([e]) => e === "voiceroom:heartbeat")).toEqual([["voiceroom:heartbeat", { roomId: "r1" }]]);
});

it("a refused join shows the reason and never mints a token", async () => {
  mockJoin.mockReturnValueOnce({ unwrap: () => Promise.reject({ status: 400, data: { error: "Room is full" } }) } as any);
  await joinRoom();
  expect(api.phase).toBe("error");
  expect(api.error).toBe("This room is full.");
  expect(mockToken).not.toHaveBeenCalled();
});

it("taking the mic publishes and tells the room; a denied mic says why and keeps listening", async () => {
  await joinRoom();
  await act(async () => {
    await api.setMic(true);
  });
  expect(api.micOn).toBe(true);
  expect(emitted).toContainEqual(["voiceroom:mute", { roomId: "r1", isMuted: false }]);
  await act(async () => {
    await api.setMic(false);
  });
  failNextMedia("NotAllowedError");
  await act(async () => {
    await api.setMic(true);
  });
  expect(api.micOn).toBe(false);
  expect(api.micProblem).toBe("denied");
  expect(api.phase).toBe("live");
});

it("raising a hand uses the backend's event name; taking the mic lowers it", async () => {
  await joinRoom();
  act(() => api.raiseHand(true));
  expect(emitted).toContainEqual(["voiceroom:raise_hand", { roomId: "r1", isRaised: true }]);
  expect(api.handRaised).toBe(true);
  await act(async () => {
    await api.setMic(true);
  });
  expect(emitted).toContainEqual(["voiceroom:raise_hand", { roomId: "r1", isRaised: false }]);
  expect(api.handRaised).toBe(false);
});

it("a forced mute from the host turns my mic off", async () => {
  await joinRoom();
  await act(async () => {
    await api.setMic(true);
  });
  serverSays("voiceroom:mute", { roomId: "r1", userId: "me", isMuted: true, forced: true });
  await waitFor(() => expect(api.micOn).toBe(false));
  expect(fakeRoom().localParticipant.isMicrophoneEnabled).toBe(false);
});

it("room ended by the server ends the session", async () => {
  await joinRoom();
  serverSays("voiceroom:ended", { roomId: "r1" });
  await waitFor(() => expect(api.phase).toBe("ended"));
  expect(fakeRoom().disconnect).toHaveBeenCalled();
});

it("ignores events for another room", async () => {
  await joinRoom();
  serverSays("voiceroom:ended", { roomId: "other" });
  expect(api.phase).toBe("live");
});

it("the same account joining from another tab parks this one", async () => {
  await joinRoom();
  act(() => {
    fakeRoom().emit(RoomEvent.Disconnected, DisconnectReason.DUPLICATE_IDENTITY);
  });
  expect(api.phase).toBe("elsewhere");
});

it("a dropped LiveKit connection becomes 'lost' (Rejoin offered), not a loop", async () => {
  await joinRoom();
  act(() => {
    fakeRoom().emit(RoomEvent.Disconnected, DisconnectReason.SIGNAL_CLOSE);
  });
  expect(api.phase).toBe("lost");
  expect(mockJoin).toHaveBeenCalledTimes(1);
});

it("rejoins over the socket after a reconnect and follows the host", async () => {
  const view = await joinRoom();
  rejoinAck = { ok: true, ended: false, currentHostId: "me", youArePromoted: true };
  mockEpoch = 1;
  view.rerender(<Probe />);
  await waitFor(() => expect(api.hostId).toBe("me"));
  expect(emitted.map(([e]) => e)).toContain("voiceroom:rejoin");
});

it("a rejoin ack saying the room ended ends it", async () => {
  const view = await joinRoom();
  rejoinAck = { ok: false, ended: true };
  mockEpoch = 2;
  view.rerender(<Probe />);
  await waitFor(() => expect(api.phase).toBe("ended"));
});

it("leaves over the socket and REST and disconnects; unmount while live leaves too", async () => {
  const view = await joinRoom();
  await act(async () => {
    await api.leave();
  });
  expect(emitted).toContainEqual(["voiceroom:leave", { roomId: "r1" }]);
  expect(mockLeave).toHaveBeenCalledWith("r1");
  expect(api.phase).toBe("idle");
  await act(async () => {
    await api.join();
  });
  emitted.length = 0;
  view.unmount();
  expect(emitted).toContainEqual(["voiceroom:leave", { roomId: "r1" }]);
});

it("host tools: mute all over the socket, promote and end over REST", async () => {
  mockToken.mockReturnValueOnce(ok({ token: "tok", url: "wss://lk.test", roomName: "r1", role: "host" }) as any);
  await joinRoom();
  act(() => api.muteAll());
  expect(emitted).toContainEqual(["voiceroom:mute-all", { roomId: "r1" }]);
  await act(async () => {
    await api.promote("u2");
  });
  expect(mockPromote).toHaveBeenCalledWith({ roomId: "r1", userId: "u2" });
  await act(async () => {
    await api.endRoom();
  });
  expect(emitted).toContainEqual(["voiceroom:end-intent", { roomId: "r1" }]);
  expect(mockEnd).toHaveBeenCalledWith("r1");
  expect(api.phase).toBe("ended");
});

it("sends trimmed chat, capped at 500 characters", async () => {
  await joinRoom();
  act(() => api.sendChat("  hi  "));
  act(() => api.sendChat("   "));
  act(() => api.sendChat("x".repeat(600)));
  const chats = emitted.filter(([e]) => e === "voiceroom:chat").map(([, p]) => p.message);
  expect(chats).toEqual(["hi", "x".repeat(500)]);
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false voiceRoomState useVoiceRoom
```
Expected: FAIL — `Cannot find module './voiceRoomState'` / `'./useVoiceRoom'`.

- [ ] **Step 3: Implement**

Create `src/components/voiceRooms/voiceRoomState.ts`:

```ts
import { LkPeer } from "../../lib/livekit/lkSession";

export interface VoiceRoomMember {
  userId: string;
  name: string;
  images?: string[];
  role: string;
  isMuted: boolean;
  isSpeaking: boolean;
  handRaised: boolean;
}

export interface VoiceRoomChatLine {
  id: string;
  userId: string;
  name: string;
  message: string;
  at: string;
}

export interface VoiceRoomState {
  members: { [userId: string]: VoiceRoomMember };
  order: string[];
  hostId: string;
  chat: VoiceRoomChatLine[];
  ended: boolean;
}

export const initialVoiceRoomState: VoiceRoomState = { members: {}, order: [], hostId: "", chat: [], ended: false };

export type VoiceRoomAction =
  | { type: "detail"; room: any }
  | { type: "joined"; payload: any }
  | { type: "left"; payload: any }
  | { type: "mute"; payload: any }
  | { type: "hand"; payload: any }
  | { type: "chat"; payload: any }
  | { type: "host"; hostId: string }
  | { type: "ended" }
  | { type: "reset" };

const idOf = (v: any): string => (v && typeof v === "object" ? String(v._id || "") : v ? String(v) : "");
const CHAT_LIMIT = 200;
let chatSeq = 0;

function upsert(state: VoiceRoomState, userId: string, patch: Partial<VoiceRoomMember>): VoiceRoomState {
  if (!userId) return state;
  const prev = state.members[userId];
  const next: VoiceRoomMember = Object.assign(
    { userId, name: "", role: "listener", isMuted: true, isSpeaking: false, handRaised: false },
    prev || {},
    patch
  );
  return Object.assign({}, state, {
    members: Object.assign({}, state.members, { [userId]: next }),
    order: prev ? state.order : state.order.concat([userId]),
  });
}

export function voiceRoomReducer(state: VoiceRoomState, action: VoiceRoomAction): VoiceRoomState {
  switch (action.type) {
    case "detail": {
      const room = action.room || {};
      let next: VoiceRoomState = Object.assign({}, state, { hostId: idOf(room.host) || state.hostId });
      (Array.isArray(room.participants) ? room.participants : []).forEach((p: any) => {
        const u = p && p.user;
        const userId = idOf(u);
        next = upsert(next, userId, {
          name: (u && typeof u === "object" && u.name) || (next.members[userId] && next.members[userId].name) || "",
          images: u && typeof u === "object" ? u.images : undefined,
          role: (p && p.role) || (userId === next.hostId ? "host" : "listener"),
          isMuted: p && typeof p.isMuted === "boolean" ? p.isMuted : true,
        });
      });
      // Host first, everyone else in join order.
      const order = next.order.slice().sort((a, b) => (a === next.hostId ? -1 : b === next.hostId ? 1 : 0));
      return Object.assign({}, next, { order });
    }
    case "joined": {
      const p = action.payload || {};
      const userId = idOf(p.user) || idOf(p.userId);
      return upsert(state, userId, {
        name: (p.user && p.user.name) || (state.members[userId] && state.members[userId].name) || "",
        images: p.user && p.user.images,
      });
    }
    case "left": {
      const p = action.payload || {};
      const userId = idOf(p.userId);
      const members = Object.assign({}, state.members);
      delete members[userId];
      return Object.assign({}, state, {
        members,
        order: state.order.filter((id) => id !== userId),
        ended: state.ended || p.roomEnded === true,
      });
    }
    case "mute": {
      const p = action.payload || {};
      return upsert(state, idOf(p.userId), { isMuted: !!p.isMuted });
    }
    case "hand": {
      const p = action.payload || {};
      const userId = idOf(p.userId);
      return upsert(state, userId, {
        handRaised: p.isRaised === true,
        name: (p.user && p.user.name) || (state.members[userId] && state.members[userId].name) || "",
      });
    }
    case "chat": {
      const p = action.payload || {};
      chatSeq += 1;
      const line: VoiceRoomChatLine = {
        id: `c${chatSeq}`,
        userId: idOf(p.user),
        name: (p.user && p.user.name) || "",
        message: String(p.message || ""),
        at: String(p.timestamp || new Date().toISOString()),
      };
      const chat = state.chat.concat([line]);
      return Object.assign({}, state, { chat: chat.length > CHAT_LIMIT ? chat.slice(chat.length - CHAT_LIMIT) : chat });
    }
    case "host": {
      const next = Object.assign({}, state, { hostId: action.hostId });
      return action.hostId && next.members[action.hostId] ? upsert(next, action.hostId, { role: "host" }) : next;
    }
    case "ended":
      return Object.assign({}, state, { ended: true });
    case "reset":
      return initialVoiceRoomState;
    default:
      return state;
  }
}

/** Members in display order, with LiveKit's view of speaking/mic applied. */
export function selectMembers(state: VoiceRoomState, peers: LkPeer[]): VoiceRoomMember[] {
  const byId: { [id: string]: LkPeer } = {};
  peers.forEach((p) => {
    byId[p.identity] = p;
  });
  return state.order
    .map((id) => state.members[id])
    .filter(Boolean)
    .map((m) => {
      const peer = byId[m.userId];
      return peer ? Object.assign({}, m, { isSpeaking: peer.isSpeaking, isMuted: !peer.micOn }) : m;
    });
}
```

Create `src/components/voiceRooms/useVoiceRoom.ts`:

```ts
import { useCallback, useEffect, useReducer, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { useSocket } from "../chat/hooks/useSocket";
import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "../chat/lib/socketAck";
import { createLkSession, LkPeer, LkSession } from "../../lib/livekit/lkSession";
import {
  useGetVoiceRoomQuery,
  useJoinVoiceRoomMutation,
  useGetVoiceRoomTokenMutation,
  useLeaveVoiceRoomMutation,
  useEndVoiceRoomMutation,
  usePromoteVoiceParticipantMutation,
  voiceRoomErrorText,
} from "../../store/slices/voiceRoomsSlice";
import {
  voiceRoomReducer,
  initialVoiceRoomState,
  selectMembers,
  VoiceRoomMember,
  VoiceRoomChatLine,
} from "./voiceRoomState";

export type VoiceRoomPhase = "idle" | "joining" | "live" | "reconnecting" | "ended" | "elsewhere" | "lost" | "error";

export interface UseVoiceRoom {
  phase: VoiceRoomPhase;
  error: string;
  role: "host" | "participant" | null;
  hostId: string;
  members: VoiceRoomMember[];
  micOn: boolean;
  micProblem: "denied" | "unavailable" | "error" | null;
  handRaised: boolean;
  audioBlocked: boolean;
  chat: VoiceRoomChatLine[];
  join(): Promise<void>;
  leave(): Promise<void>;
  setMic(on: boolean): Promise<void>;
  raiseHand(on: boolean): void;
  sendChat(text: string): void;
  startAudio(): Promise<void>;
  muteAll(): void;
  promote(userId: string): Promise<void>;
  endRoom(): Promise<void>;
}

const HEARTBEAT_MS = 30000;
const LIVE_PHASES: VoiceRoomPhase[] = ["live", "reconnecting"];

export function useVoiceRoom(roomId: string, myId: string): UseVoiceRoom {
  const { t } = useTranslation();
  const { socket, connectionEpoch } = useSocket() as any;
  const { data: detail, refetch: refetchDetail } = useGetVoiceRoomQuery(roomId, { skip: !roomId });
  const [joinRoom] = useJoinVoiceRoomMutation();
  const [mintToken] = useGetVoiceRoomTokenMutation();
  const [leaveRoom] = useLeaveVoiceRoomMutation();
  const [endRoomRest] = useEndVoiceRoomMutation();
  const [promoteRest] = usePromoteVoiceParticipantMutation();

  const [state, dispatch] = useReducer(voiceRoomReducer, initialVoiceRoomState);
  const [phase, setPhase] = useState<VoiceRoomPhase>("idle");
  const [error, setError] = useState("");
  const [role, setRole] = useState<"host" | "participant" | null>(null);
  const [peers, setPeers] = useState<LkPeer[]>([]);
  const [micOn, setMicOn] = useState(false);
  const [micProblem, setMicProblem] = useState<"denied" | "unavailable" | "error" | null>(null);
  const [handRaised, setHandRaised] = useState(false);
  const [audioBlocked, setAudioBlocked] = useState(false);

  const sessionRef = useRef<LkSession | null>(null);
  const phaseRef = useRef<VoiceRoomPhase>("idle");
  const heartbeatRef = useRef<any>(null);
  const handRef = useRef(false);
  const epochRef = useRef<number>(connectionEpoch || 0);
  // RTK hands back a new refetch per render in some setups; read it through a
  // ref so the socket listeners are attached once per socket, not per render.
  const refetchRef = useRef(refetchDetail);
  refetchRef.current = refetchDetail;

  const go = useCallback((p: VoiceRoomPhase) => {
    phaseRef.current = p;
    setPhase(p);
  }, []);

  const stopHeartbeat = () => {
    if (heartbeatRef.current) clearInterval(heartbeatRef.current);
    heartbeatRef.current = null;
  };

  const emit = useCallback(
    (event: string, payload: any) => {
      if (socket) socket.emit(event, payload);
    },
    [socket]
  );

  // Seed members/host from the REST detail whenever it (re)loads.
  useEffect(() => {
    if (detail) dispatch({ type: "detail", room: detail });
  }, [detail]);

  const teardown = useCallback(async () => {
    stopHeartbeat();
    const s = sessionRef.current;
    sessionRef.current = null;
    setPeers([]);
    setMicOn(false);
    if (s) await s.disconnect();
  }, []);

  // ---- socket events ---------------------------------------------------------
  useEffect(() => {
    if (!socket) return;
    const mine = (p: any) => p && String(p.roomId) === String(roomId);
    const onJoined = (p: any) => mine(p) && dispatch({ type: "joined", payload: p });
    const onLeft = (p: any) => {
      if (!mine(p)) return;
      dispatch({ type: "left", payload: p });
      if (p.roomEnded === true && LIVE_PHASES.indexOf(phaseRef.current) > -1) {
        go("ended");
        teardown();
      }
    };
    const onMute = (p: any) => {
      if (!mine(p)) return;
      dispatch({ type: "mute", payload: p });
      if (p.forced && String(p.userId) === String(myId) && p.isMuted && sessionRef.current) {
        sessionRef.current.setMic(false).then(() => setMicOn(false));
      }
    };
    const onHand = (p: any) => mine(p) && dispatch({ type: "hand", payload: p });
    const onChat = (p: any) => mine(p) && dispatch({ type: "chat", payload: p });
    const onHost = (p: any) => {
      if (!p || !p.newHostId) return;
      dispatch({ type: "host", hostId: String(p.newHostId) });
      if (String(p.newHostId) === String(myId)) setRole("host");
      if (refetchRef.current) refetchRef.current();
    };
    const onEnded = (p: any) => {
      if (!mine(p)) return;
      dispatch({ type: "ended" });
      if (LIVE_PHASES.indexOf(phaseRef.current) > -1 || phaseRef.current === "joining") {
        go("ended");
        teardown();
      }
    };
    socket.on("voiceroom:user_joined", onJoined);
    socket.on("voiceroom:user_left", onLeft);
    socket.on("voiceroom:mute", onMute);
    socket.on("voiceroom:hand_raised", onHand);
    socket.on("voiceroom:chat", onChat);
    socket.on("voiceroom:host-changed", onHost);
    socket.on("voiceroom:ended", onEnded);
    return () => {
      socket.off("voiceroom:user_joined", onJoined);
      socket.off("voiceroom:user_left", onLeft);
      socket.off("voiceroom:mute", onMute);
      socket.off("voiceroom:hand_raised", onHand);
      socket.off("voiceroom:chat", onChat);
      socket.off("voiceroom:host-changed", onHost);
      socket.off("voiceroom:ended", onEnded);
    };
  }, [socket, roomId, myId, go, teardown]);

  // ---- socket reconnect while in the room: rejoin (Phase 3 connectionEpoch) --
  useEffect(() => {
    const epoch = connectionEpoch || 0;
    if (epoch === epochRef.current) return;
    epochRef.current = epoch;
    if (!socket || LIVE_PHASES.indexOf(phaseRef.current) === -1) return;
    emitWithAck(socket, "voiceroom:rejoin", { roomId, lastSeenAt: new Date().toISOString() }, SOCKET_ACK_TIMEOUT_MS, {
      onAck: (ack: any) => {
        if (!ack || ack.ended) {
          go("ended");
          teardown();
          return;
        }
        if (ack.currentHostId) {
          dispatch({ type: "host", hostId: String(ack.currentHostId) });
          if (String(ack.currentHostId) === String(myId)) setRole("host");
        }
        if (Array.isArray(ack.participants)) dispatch({ type: "detail", room: { host: ack.currentHostId, participants: ack.participants } });
      },
      onTimeout: () => {
        // The room keeps playing over LiveKit; the next heartbeat or reconnect retries.
      },
    });
  }, [connectionEpoch, socket, roomId, myId, go, teardown]);

  // ---- actions ------------------------------------------------------------
  const join = useCallback(async () => {
    if (phaseRef.current === "joining" || LIVE_PHASES.indexOf(phaseRef.current) > -1) return;
    go("joining");
    setError("");
    setMicProblem(null);
    let token: any;
    try {
      await joinRoom(roomId).unwrap();
      token = await mintToken(roomId).unwrap();
    } catch (err) {
      setError(voiceRoomErrorText(err, t));
      go("error");
      return;
    }
    setRole(token && token.role === "host" ? "host" : "participant");
    emit("voiceroom:join", { roomId });
    const session = createLkSession({
      onPeers: (p) => setPeers(p),
      onState: (s) => {
        if (s === "reconnecting" && phaseRef.current === "live") go("reconnecting");
        if (s === "connected" && phaseRef.current === "reconnecting") go("live");
      },
      onAudioBlocked: (blocked) => setAudioBlocked(blocked),
      onDisconnected: (reason) => {
        stopHeartbeat();
        sessionRef.current = null;
        setPeers([]);
        setMicOn(false);
        if (reason === "client") return;
        if (reason === "duplicate_identity") go("elsewhere");
        else if (reason === "room_deleted" || reason === "participant_removed") go("ended");
        else go("lost");
      },
    });
    sessionRef.current = session;
    try {
      await session.connect(token.url, token.token, { mic: false, camera: false });
    } catch (err) {
      sessionRef.current = null;
      setError(t("voiceRooms.room.connectFailed") || "Couldn't connect to the room's audio. Check your connection and try again.");
      go("error");
      return;
    }
    go("live");
    stopHeartbeat();
    heartbeatRef.current = setInterval(() => emit("voiceroom:heartbeat", { roomId }), HEARTBEAT_MS);
  }, [roomId, joinRoom, mintToken, emit, go, t]);

  const leave = useCallback(async () => {
    if (phaseRef.current === "idle") return;
    emit("voiceroom:leave", { roomId });
    go("idle");
    setHandRaised(false);
    handRef.current = false;
    leaveRoom(roomId)
      .unwrap()
      .catch(() => undefined);
    await teardown();
  }, [roomId, emit, go, leaveRoom, teardown]);

  const raiseHand = useCallback(
    (on: boolean) => {
      handRef.current = on;
      setHandRaised(on);
      emit("voiceroom:raise_hand", { roomId, isRaised: on });
    },
    [roomId, emit]
  );

  const setMic = useCallback(
    async (on: boolean) => {
      const s = sessionRef.current;
      if (!s) return;
      const result = await s.setMic(on);
      if (result === "ok") {
        setMicOn(on);
        setMicProblem(null);
        emit("voiceroom:mute", { roomId, isMuted: !on });
        if (on && handRef.current) raiseHand(false);
      } else {
        setMicOn(false);
        setMicProblem(result === "denied" || result === "unavailable" ? result : "error");
      }
    },
    [roomId, emit, raiseHand]
  );

  const sendChat = useCallback(
    (text: string) => {
      const message = String(text || "").trim().slice(0, 500);
      if (!message) return;
      emit("voiceroom:chat", { roomId, message });
    },
    [roomId, emit]
  );

  const startAudio = useCallback(async () => {
    const s = sessionRef.current;
    if (s) await s.startAudio();
  }, []);

  const muteAll = useCallback(() => emit("voiceroom:mute-all", { roomId }), [roomId, emit]);

  const promote = useCallback(
    async (userId: string) => {
      try {
        await promoteRest({ roomId, userId }).unwrap();
      } catch (err) {
        setError(voiceRoomErrorText(err, t));
      }
    },
    [roomId, promoteRest, t]
  );

  const endRoom = useCallback(async () => {
    emit("voiceroom:end-intent", { roomId });
    try {
      await endRoomRest(roomId).unwrap();
    } catch (err) {
      setError(voiceRoomErrorText(err, t));
      return;
    }
    go("ended");
    await teardown();
  }, [roomId, emit, endRoomRest, go, teardown, t]);

  // ---- leave on unmount / page close (best effort) ------------------------------
  const leaveRef = useRef(leave);
  leaveRef.current = leave;
  useEffect(() => {
    const onPageHide = () => {
      if (LIVE_PHASES.indexOf(phaseRef.current) > -1) leaveRef.current();
    };
    window.addEventListener("pagehide", onPageHide);
    return () => {
      window.removeEventListener("pagehide", onPageHide);
      if (LIVE_PHASES.indexOf(phaseRef.current) > -1) leaveRef.current();
      stopHeartbeat();
    };
  }, []);

  return {
    phase,
    error,
    role,
    hostId: state.hostId,
    members: selectMembers(state, peers),
    micOn,
    micProblem,
    handRaised,
    audioBlocked,
    chat: state.chat,
    join,
    leave,
    setMic,
    raiseHand,
    sendChat,
    startAudio,
    muteAll,
    promote,
    endRoom,
  };
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false voiceRoomState useVoiceRoom lkSession
```
Expected: all pass. If the heartbeat test flakes because `act` and fake timers interleave with the awaited join, keep `jest.useFakeTimers()` (modern timers resolve promises normally) and do not switch to legacy timers.

- [ ] **Step 5: Commit**

```bash
git add src/components/voiceRooms/voiceRoomState.ts src/components/voiceRooms/voiceRoomState.test.ts src/components/voiceRooms/useVoiceRoom.ts src/components/voiceRooms/useVoiceRoom.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(voice-rooms): join, listen, speak and leave a voice room

useVoiceRoom runs the app's sequence (REST join, LiveKit token, socket
voiceroom:join, LiveKit connect with the mic off), heartbeats every
30 s, follows the room's socket events with the backend's own names
(raise_hand, hand_raised, user_joined/left, mute incl. forced, host
change, ended), rejoins after a socket reconnect, parks a tab replaced
by another one, and leaves on unmount and pagehide.

Still open (Phase 4 rooms): room page UI, host tools, language rooms,
City/Genders tabs, routes, i18n, push.
EOF
```

---

### Task P4-ROOM-6: Voice room page: listen, take the mic, raise a hand, tap-to-enable-sound, mic-denied help, room chat

**Files:**
- Create: `src/components/voiceRooms/VoiceRoomPage.tsx`, `src/components/voiceRooms/VoiceRoomChat.tsx`
- Modify: `src/components/voiceRooms/VoiceRooms.scss` (room page block), `src/utils/locales/eng.json` (`voiceRooms.room.*`)
- Test: `src/components/voiceRooms/VoiceRoomPage.test.tsx` (new)

**Interfaces:**
- Consumes: `useVoiceRoom(roomId, myId)` (P4-ROOM-5), `useGetVoiceRoomQuery(id)` for the title/language header, `state.auth.userInfo.user._id`, `photoUrl`.
- Produces: default export `VoiceRoomPage` (route `/voice-rooms/:id`). The page never joins on mount: **Join is a click**, which is also the user gesture browsers want before they play room audio. Test ids: `voice-room-page`, `voice-room-join`, `voice-room-joining`, `voice-room-member-<userId>`, `voice-room-mic`, `voice-room-hand`, `voice-room-leave`, `voice-room-enable-sound`, `voice-room-mic-problem`, `voice-room-reconnecting`, `voice-room-ended`, `voice-room-elsewhere`, `voice-room-use-here`, `voice-room-lost`, `voice-room-rejoin`, `voice-room-error`, `voice-room-chat-input`, `voice-room-chat-send`, `voice-room-chat-line`.

- [ ] **Step 1: Write the failing test**

Create `src/components/voiceRooms/VoiceRoomPage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import VoiceRoomPage from "./VoiceRoomPage";

const actions = {
  join: jest.fn(),
  leave: jest.fn(),
  setMic: jest.fn(),
  raiseHand: jest.fn(),
  sendChat: jest.fn(),
  startAudio: jest.fn(),
  muteAll: jest.fn(),
  promote: jest.fn(),
  endRoom: jest.fn(),
};
let mockState: any = {};
jest.mock("./useVoiceRoom", () => ({ useVoiceRoom: () => Object.assign({}, mockState, actions) }));
jest.mock("../../store/slices/voiceRoomsSlice", () => ({
  useGetVoiceRoomQuery: () => ({ data: { _id: "r1", title: "Evening Korean", language: "Korean" } }),
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const base = {
  phase: "live",
  error: "",
  role: "participant",
  hostId: "h1",
  members: [
    { userId: "h1", name: "Mina", role: "host", isMuted: false, isSpeaking: true, handRaised: false },
    { userId: "me", name: "Me", role: "listener", isMuted: true, isSpeaking: false, handRaised: false },
  ],
  micOn: false,
  micProblem: null,
  handRaised: false,
  audioBlocked: false,
  chat: [],
};

function renderPage(state: any = {}) {
  mockState = Object.assign({}, base, state);
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/voice-rooms/r1"]}>
        <Routes>
          <Route path="/voice-rooms/:id" element={<VoiceRoomPage />} />
          <Route path="/voice-rooms" element={<div data-testid="list" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => Object.keys(actions).forEach((k) => (actions as any)[k].mockReset()));

it("does not join on its own; Join is a click", () => {
  renderPage({ phase: "idle" });
  expect(actions.join).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("voice-room-join"));
  expect(actions.join).toHaveBeenCalled();
});

it("shows members with the speaker ring and mic state", () => {
  renderPage();
  expect(screen.getByTestId("voice-room-member-h1")).toHaveClass("is-speaking");
  expect(screen.getByTestId("voice-room-member-me")).toHaveClass("is-muted");
  expect(screen.getByText("Evening Korean")).toBeInTheDocument();
});

it("takes the mic, and raises a hand only while muted", () => {
  const { unmount } = renderPage();
  fireEvent.click(screen.getByTestId("voice-room-hand"));
  expect(actions.raiseHand).toHaveBeenCalledWith(true);
  fireEvent.click(screen.getByTestId("voice-room-mic"));
  expect(actions.setMic).toHaveBeenCalledWith(true);
  unmount();
  renderPage({ micOn: true });
  expect(screen.queryByTestId("voice-room-hand")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("voice-room-mic"));
  expect(actions.setMic).toHaveBeenCalledWith(false);
});

it("offers 'tap to enable sound' when the browser blocked audio", () => {
  renderPage({ audioBlocked: true });
  fireEvent.click(screen.getByTestId("voice-room-enable-sound"));
  expect(actions.startAudio).toHaveBeenCalled();
});

it.each([
  ["denied", /allow the microphone/i],
  ["unavailable", /no microphone/i],
])("explains a %s mic and keeps the room playing", (problem, text) => {
  renderPage({ micProblem: problem });
  expect(screen.getByTestId("voice-room-mic-problem")).toHaveTextContent(text);
  expect(screen.getByTestId("voice-room-leave")).toBeInTheDocument();
});

it("shows reconnecting, ended, elsewhere, lost and error states", () => {
  const { unmount } = renderPage({ phase: "reconnecting" });
  expect(screen.getByTestId("voice-room-reconnecting")).toBeInTheDocument();
  unmount();
  const a = renderPage({ phase: "ended" });
  expect(screen.getByTestId("voice-room-ended")).toBeInTheDocument();
  a.unmount();
  const b = renderPage({ phase: "elsewhere" });
  fireEvent.click(screen.getByTestId("voice-room-use-here"));
  expect(actions.join).toHaveBeenCalled();
  b.unmount();
  const c = renderPage({ phase: "lost" });
  fireEvent.click(screen.getByTestId("voice-room-rejoin"));
  expect(actions.join).toHaveBeenCalledTimes(2);
  c.unmount();
  renderPage({ phase: "error", error: "This room is full." });
  expect(screen.getByTestId("voice-room-error")).toHaveTextContent("This room is full.");
});

it("leaving goes back to the list", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("voice-room-leave"));
  expect(actions.leave).toHaveBeenCalled();
  expect(screen.getByTestId("list")).toBeInTheDocument();
});

it("chats", () => {
  renderPage({ chat: [{ id: "c1", userId: "h1", name: "Mina", message: "안녕!", at: "2026-10-16T10:00:00Z" }] });
  expect(screen.getByTestId("voice-room-chat-line")).toHaveTextContent("안녕!");
  fireEvent.change(screen.getByTestId("voice-room-chat-input"), { target: { value: "hi" } });
  fireEvent.click(screen.getByTestId("voice-room-chat-send"));
  expect(actions.sendChat).toHaveBeenCalledWith("hi");
  expect((screen.getByTestId("voice-room-chat-input") as HTMLInputElement).value).toBe("");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false VoiceRoomPage
```
Expected: FAIL — `Cannot find module './VoiceRoomPage'`.

- [ ] **Step 3: Implement**

Create `src/components/voiceRooms/VoiceRoomChat.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Send } from "lucide-react";
import { VoiceRoomChatLine } from "./voiceRoomState";

const VoiceRoomChat: React.FC<{ lines: VoiceRoomChatLine[]; onSend(text: string): void; disabled?: boolean }> = ({
  lines,
  onSend,
  disabled,
}) => {
  const { t } = useTranslation();
  const [text, setText] = useState("");
  const send = () => {
    if (!text.trim()) return;
    onSend(text);
    setText("");
  };
  return (
    <aside className="vr-chat" aria-label={t("voiceRooms.room.chat") || "Room chat"}>
      <ol className="vr-chat__lines">
        {lines.map((l) => (
          <li key={l.id} data-testid="voice-room-chat-line">
            <strong>{l.name}</strong> <span>{l.message}</span>
          </li>
        ))}
      </ol>
      <div className="vr-chat__compose">
        <input
          data-testid="voice-room-chat-input"
          value={text}
          maxLength={500}
          disabled={disabled}
          placeholder={t("voiceRooms.room.chatPlaceholder") || "Say something…"}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") send();
          }}
        />
        <button type="button" data-testid="voice-room-chat-send" disabled={disabled} onClick={send} aria-label={t("voiceRooms.room.send") || "Send"}>
          <Send size={16} />
        </button>
      </div>
    </aside>
  );
};

export default VoiceRoomChat;
```

Create `src/components/voiceRooms/VoiceRoomPage.tsx`:

```tsx
import React from "react";
import { useSelector } from "react-redux";
import { useNavigate, useParams, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Mic, MicOff, Hand, LogOut, Volume2, Crown } from "lucide-react";
import { useGetVoiceRoomQuery } from "../../store/slices/voiceRoomsSlice";
import { useVoiceRoom } from "./useVoiceRoom";
import { photoUrl } from "../../utils/photoUrl";
import Loader from "../Loader";
import VoiceRoomChat from "./VoiceRoomChat";
import "./VoiceRooms.scss";

const VoiceRoomPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const myId = useSelector((s: any) => String((s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id) || ""));
  const { data: room } = useGetVoiceRoomQuery(id, { skip: !id });
  const vr = useVoiceRoom(id, myId);
  const live = vr.phase === "live" || vr.phase === "reconnecting";

  const leave = () => {
    vr.leave();
    navigate("/voice-rooms");
  };

  const header = (
    <header className="vr-room__head">
      <Link to="/voice-rooms" className="vr-link">
        {t("voiceRooms.room.back") || "All rooms"}
      </Link>
      <h1>{(room && room.title) || ""}</h1>
      {room && room.language && <span className="vr-chip">{room.language}</span>}
    </header>
  );

  let body: React.ReactNode = null;
  if (vr.phase === "idle") {
    body = (
      <div className="vr-room__gate">
        <p>{t("voiceRooms.room.joinHint") || "You'll join as a listener. Take the mic whenever you're ready."}</p>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="voice-room-join" onClick={() => vr.join()}>
          {t("voiceRooms.room.join") || "Join room"}
        </button>
      </div>
    );
  } else if (vr.phase === "joining") {
    body = (
      <div className="vr-room__gate" data-testid="voice-room-joining" aria-busy="true">
        <Loader />
      </div>
    );
  } else if (vr.phase === "ended") {
    body = (
      <div className="vr-room__gate" data-testid="voice-room-ended">
        <p>{t("voiceRooms.room.ended") || "This room has ended."}</p>
        <Link to="/voice-rooms" className="vr-btn vr-btn--primary">
          {t("voiceRooms.room.findAnother") || "Find another room"}
        </Link>
      </div>
    );
  } else if (vr.phase === "elsewhere") {
    body = (
      <div className="vr-room__gate" data-testid="voice-room-elsewhere">
        <p>{t("voiceRooms.room.elsewhere") || "You joined this room from another tab or device."}</p>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="voice-room-use-here" onClick={() => vr.join()}>
          {t("voiceRooms.room.useHere") || "Listen here instead"}
        </button>
      </div>
    );
  } else if (vr.phase === "lost") {
    body = (
      <div className="vr-room__gate" data-testid="voice-room-lost">
        <p>{t("voiceRooms.room.lost") || "Connection to the room was lost."}</p>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="voice-room-rejoin" onClick={() => vr.join()}>
          {t("voiceRooms.room.rejoin") || "Rejoin"}
        </button>
      </div>
    );
  } else if (vr.phase === "error") {
    body = (
      <div className="vr-room__gate">
        <p className="vr-error" role="alert" data-testid="voice-room-error">
          {vr.error}
        </p>
        <button type="button" className="vr-btn vr-btn--primary" onClick={() => vr.join()}>
          {t("common.retry") || "Retry"}
        </button>
      </div>
    );
  }

  return (
    <section className="vr-page vr-room" data-testid="voice-room-page">
      {header}
      {body}
      {live && (
        <>
          {vr.phase === "reconnecting" && (
            <p className="vr-banner" role="status" data-testid="voice-room-reconnecting">
              {t("voiceRooms.room.reconnecting") || "Reconnecting…"}
            </p>
          )}
          {vr.audioBlocked && (
            <button type="button" className="vr-banner vr-banner--action" data-testid="voice-room-enable-sound" onClick={() => vr.startAudio()}>
              <Volume2 size={16} /> {t("voiceRooms.room.enableSound") || "Tap to turn on the room's sound"}
            </button>
          )}
          {vr.micProblem && (
            <p className="vr-banner vr-banner--warn" role="alert" data-testid="voice-room-mic-problem">
              {vr.micProblem === "denied"
                ? t("voiceRooms.room.micDenied") ||
                  "Your browser is blocking the microphone. Allow the microphone for banatalk.com in the address bar, then try again. You can keep listening."
                : vr.micProblem === "unavailable"
                ? t("voiceRooms.room.micUnavailable") || "No microphone was found (or another app is using it). You can keep listening."
                : t("voiceRooms.room.micError") || "Couldn't turn on the microphone. Try again."}
            </p>
          )}
          <ul className="vr-members">
            {vr.members.map((m) => {
              const avatar = photoUrl(m.images);
              const cls = ["vr-member", m.isSpeaking ? "is-speaking" : "", m.isMuted ? "is-muted" : ""].join(" ").trim();
              return (
                <li key={m.userId} className={cls} data-testid={`voice-room-member-${m.userId}`}>
                  <span className="vr-member__avatar">
                    {avatar ? <img src={avatar} alt="" /> : <span className="vr-avatar-fallback" aria-hidden />}
                    {m.handRaised && <Hand className="vr-member__hand" size={16} aria-label={t("voiceRooms.room.handUp") || "Hand raised"} />}
                  </span>
                  <span className="vr-member__name">
                    {m.userId === vr.hostId && <Crown size={12} aria-label={t("voiceRooms.room.host") || "Host"} />} {m.name}
                    {m.userId === myId ? ` (${t("voiceRooms.room.you") || "you"})` : ""}
                  </span>
                  {m.isMuted ? <MicOff size={14} aria-hidden /> : <Mic size={14} aria-hidden />}
                </li>
              );
            })}
          </ul>
          <div className="vr-controls">
            <button
              type="button"
              className={`vr-btn ${vr.micOn ? "vr-btn--ghost" : "vr-btn--primary"}`}
              data-testid="voice-room-mic"
              onClick={() => vr.setMic(!vr.micOn)}
            >
              {vr.micOn ? <MicOff size={16} /> : <Mic size={16} />}{" "}
              {vr.micOn ? t("voiceRooms.room.mute") || "Mute" : t("voiceRooms.room.takeMic") || "Take the mic"}
            </button>
            {!vr.micOn && (
              <button
                type="button"
                className={`vr-btn ${vr.handRaised ? "vr-btn--primary" : "vr-btn--ghost"}`}
                data-testid="voice-room-hand"
                aria-pressed={vr.handRaised}
                onClick={() => vr.raiseHand(!vr.handRaised)}
              >
                <Hand size={16} /> {vr.handRaised ? t("voiceRooms.room.lowerHand") || "Lower hand" : t("voiceRooms.room.raiseHand") || "Raise hand"}
              </button>
            )}
            <button type="button" className="vr-btn vr-btn--danger" data-testid="voice-room-leave" onClick={leave}>
              <LogOut size={16} /> {t("voiceRooms.room.leave") || "Leave"}
            </button>
          </div>
          <VoiceRoomChat lines={vr.chat} onSend={vr.sendChat} disabled={vr.phase !== "live"} />
        </>
      )}
    </section>
  );
};

export default VoiceRoomPage;
```

Append to `src/components/voiceRooms/VoiceRooms.scss`:

```scss
.vr-room__head { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; margin-block-end: 16px; }
.vr-room__head h1 { font-size: 1.4rem; font-weight: 800; margin: 0; }
.vr-room__gate { display: flex; flex-direction: column; align-items: center; gap: 12px; padding-block: 48px; text-align: center; }
.vr-banner { display: flex; align-items: center; gap: 8px; border-radius: 12px; padding-block: 10px; padding-inline: 14px; background: #f1f3f5; margin-block-end: 12px; inline-size: 100%; text-align: start; border: 0; }
.vr-banner--action { background: #fff4b3; font-weight: 800; cursor: pointer; }
.vr-banner--warn { background: #fff3e0; color: #8a4b00; }
.vr-members { list-style: none; padding: 0; margin: 0 0 16px; display: grid; grid-template-columns: repeat(auto-fill, minmax(110px, 1fr)); gap: 12px; }
.vr-member { display: flex; flex-direction: column; align-items: center; gap: 6px; text-align: center; font-size: 0.85rem; }
.vr-member__avatar { position: relative; display: inline-block; border-radius: 50%; padding: 3px; border: 3px solid transparent; }
.vr-member__avatar img, .vr-member__avatar .vr-avatar-fallback { inline-size: 64px; block-size: 64px; border-radius: 50%; object-fit: cover; }
.vr-member.is-speaking .vr-member__avatar { border-color: #2ecc71; }
.vr-member.is-muted { opacity: 0.85; }
.vr-member__hand { position: absolute; inset-block-start: -4px; inset-inline-end: -4px; background: #ffd600; border-radius: 50%; padding: 2px; }
.vr-controls { display: flex; gap: 8px; flex-wrap: wrap; justify-content: center; margin-block-end: 16px; }
.vr-chat { border: 1px solid var(--bs-border-color, #eee); border-radius: 16px; padding: 12px; display: flex; flex-direction: column; gap: 8px; }
.vr-chat__lines { list-style: none; padding: 0; margin: 0; max-block-size: 240px; overflow-y: auto; display: flex; flex-direction: column; gap: 4px; text-align: start; }
.vr-chat__compose { display: flex; gap: 8px; }
.vr-chat__compose input { flex: 1; border: 1px solid var(--bs-border-color, #ddd); border-radius: 999px; padding-block: 6px; padding-inline: 12px; }
.vr-chat__compose button { border: 0; background: #ffd600; border-radius: 50%; inline-size: 36px; block-size: 36px; }
```

Add to `eng.json` under `"voiceRooms"`:

```json
"room": {
  "back": "All rooms",
  "joinHint": "You'll join as a listener. Take the mic whenever you're ready.",
  "join": "Join room",
  "ended": "This room has ended.",
  "findAnother": "Find another room",
  "elsewhere": "You joined this room from another tab or device.",
  "useHere": "Listen here instead",
  "lost": "Connection to the room was lost.",
  "rejoin": "Rejoin",
  "connectFailed": "Couldn't connect to the room's audio. Check your connection and try again.",
  "reconnecting": "Reconnecting…",
  "enableSound": "Tap to turn on the room's sound",
  "micDenied": "Your browser is blocking the microphone. Allow the microphone for banatalk.com in the address bar, then try again. You can keep listening.",
  "micUnavailable": "No microphone was found (or another app is using it). You can keep listening.",
  "micError": "Couldn't turn on the microphone. Try again.",
  "handUp": "Hand raised",
  "host": "Host",
  "you": "you",
  "mute": "Mute",
  "takeMic": "Take the mic",
  "lowerHand": "Lower hand",
  "raiseHand": "Raise hand",
  "leave": "Leave",
  "chat": "Room chat",
  "chatPlaceholder": "Say something…",
  "send": "Send"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false VoiceRoomPage voiceRooms/
```
Expected: all pass. (The "leaving goes back to the list" case relies on the page calling `navigate("/voice-rooms")` right after `leave()`.)

- [ ] **Step 5: Commit**

```bash
git add src/components/voiceRooms/VoiceRoomPage.tsx src/components/voiceRooms/VoiceRoomChat.tsx src/components/voiceRooms/VoiceRoomPage.test.tsx src/components/voiceRooms/VoiceRooms.scss src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(voice-rooms): room page — listen, take the mic, raise a hand

Join is a click (the gesture browsers need before playing audio);
members show who is speaking and muted; a blocked-audio banner calls
startAudio; a denied or missing mic explains what to do while the
room keeps playing; reconnecting, ended, joined-elsewhere, lost and
error states each have a way forward; room chat.

Still open (Phase 4 rooms): host tools, language rooms, City/Genders
tabs, routes, i18n, push.
EOF
```

---

### Task P4-ROOM-7: Host controls: raised hands, mute all, make co-host, end room

**Files:**
- Create: `src/components/voiceRooms/VoiceRoomHostPanel.tsx`
- Modify: `src/components/voiceRooms/VoiceRoomPage.tsx` (render the panel under `.vr-controls` when I am the host), `src/utils/locales/eng.json` (`voiceRooms.host.*`)
- Test: `src/components/voiceRooms/VoiceRoomHostPanel.test.tsx` (new), `VoiceRoomPage.test.tsx` (two cases)

**Interfaces:**
- Consumes: `UseVoiceRoom.members/hostId/role/muteAll/promote/endRoom` (P4-ROOM-5). Backend: `voiceroom:mute-all` is accepted only from `room.host` (`be/socket/voiceRoomHandler.js:384-427`); `PUT /promote/:userId` only from the host, makes a `cohost` (`be/controllers/voiceRooms.js:565-626`); `POST /end` from host, co-host or admin (`:469-508`).
- Produces: default export `VoiceRoomHostPanel` props `{ members: VoiceRoomMember[]; myId: string; hostId: string; isHost: boolean; canEnd: boolean; onMuteAll(): void; onPromote(userId: string): void; onEnd(): void }`. The panel renders when `isHost || canEnd` (co-hosts can end, only the host can mute everyone or promote). Test ids: `vr-host-panel`, `vr-host-hand-<userId>`, `vr-host-promote-<userId>`, `vr-host-mute-all`, `vr-host-end`, `vr-host-end-confirm`, `vr-host-end-cancel`.
- No "remove from room": the backend has no kick (the app's `voiceroom:kick` reaches no handler). Logged as a backend follow-up.

- [ ] **Step 1: Write the failing tests**

Create `src/components/voiceRooms/VoiceRoomHostPanel.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import VoiceRoomHostPanel from "./VoiceRoomHostPanel";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const members = [
  { userId: "me", name: "Me", role: "host", isMuted: false, isSpeaking: false, handRaised: false },
  { userId: "u2", name: "Ana", role: "listener", isMuted: true, isSpeaking: false, handRaised: true },
  { userId: "u3", name: "Sam", role: "cohost", isMuted: true, isSpeaking: false, handRaised: true },
  { userId: "u4", name: "Lee", role: "listener", isMuted: true, isSpeaking: false, handRaised: false },
];

function renderPanel(props: any = {}) {
  const handlers = { onMuteAll: jest.fn(), onPromote: jest.fn(), onEnd: jest.fn() };
  render(<VoiceRoomHostPanel members={members} myId="me" hostId="me" isHost canEnd {...handlers} {...props} />);
  return handlers;
}

it("lists raised hands, oldest first, and promotes a listener to co-host", () => {
  const h = renderPanel();
  expect(screen.getByTestId("vr-host-hand-u2")).toHaveTextContent("Ana");
  expect(screen.getByTestId("vr-host-hand-u3")).toBeInTheDocument();
  expect(screen.queryByTestId("vr-host-hand-u4")).not.toBeInTheDocument();
  expect(screen.queryByTestId("vr-host-promote-u3")).not.toBeInTheDocument(); // already co-host
  fireEvent.click(screen.getByTestId("vr-host-promote-u2"));
  expect(h.onPromote).toHaveBeenCalledWith("u2");
});

it("mutes everyone", () => {
  const h = renderPanel();
  fireEvent.click(screen.getByTestId("vr-host-mute-all"));
  expect(h.onMuteAll).toHaveBeenCalled();
});

it("asks before ending the room", () => {
  const h = renderPanel();
  fireEvent.click(screen.getByTestId("vr-host-end"));
  expect(h.onEnd).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("vr-host-end-cancel"));
  expect(screen.queryByTestId("vr-host-end-confirm")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("vr-host-end"));
  fireEvent.click(screen.getByTestId("vr-host-end-confirm"));
  expect(h.onEnd).toHaveBeenCalled();
});

it("a co-host may end the room but not mute everyone or promote", () => {
  renderPanel({ isHost: false, canEnd: true, hostId: "u9" });
  expect(screen.getByTestId("vr-host-end")).toBeInTheDocument();
  expect(screen.queryByTestId("vr-host-mute-all")).not.toBeInTheDocument();
  expect(screen.queryByTestId("vr-host-promote-u2")).not.toBeInTheDocument();
});

it("renders nothing for a listener", () => {
  renderPanel({ isHost: false, canEnd: false, hostId: "u9" });
  expect(screen.queryByTestId("vr-host-panel")).not.toBeInTheDocument();
});
```

Append to `src/components/voiceRooms/VoiceRoomPage.test.tsx`:

```tsx
it("shows the host panel to the host and wires its actions", () => {
  renderPage({ role: "host", hostId: "me", members: base.members.map((m: any) => (m.userId === "me" ? Object.assign({}, m, { role: "host" }) : m)) });
  expect(screen.getByTestId("vr-host-panel")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("vr-host-mute-all"));
  expect(actions.muteAll).toHaveBeenCalled();
});

it("hides the host panel from a listener", () => {
  renderPage();
  expect(screen.queryByTestId("vr-host-panel")).not.toBeInTheDocument();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false VoiceRoomHostPanel VoiceRoomPage
```
Expected: FAIL — `Cannot find module './VoiceRoomHostPanel'`; the page's host case finds no `vr-host-panel`.

- [ ] **Step 3: Implement**

Create `src/components/voiceRooms/VoiceRoomHostPanel.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Hand, MicOff, Power, ShieldPlus } from "lucide-react";
import { VoiceRoomMember } from "./voiceRoomState";

interface Props {
  members: VoiceRoomMember[];
  myId: string;
  hostId: string;
  isHost: boolean;
  canEnd: boolean;
  onMuteAll(): void;
  onPromote(userId: string): void;
  onEnd(): void;
}

const VoiceRoomHostPanel: React.FC<Props> = ({ members, myId, hostId, isHost, canEnd, onMuteAll, onPromote, onEnd }) => {
  const { t } = useTranslation();
  const [confirming, setConfirming] = useState(false);
  if (!isHost && !canEnd) return null;
  const hands = members.filter((m) => m.handRaised && m.userId !== myId);

  return (
    <section className="vr-host" data-testid="vr-host-panel" aria-label={t("voiceRooms.host.title") || "Host tools"}>
      <h2 className="vr-host__title">{t("voiceRooms.host.title") || "Host tools"}</h2>
      <h3 className="vr-host__sub">
        <Hand size={14} /> {t("voiceRooms.host.hands") || "Raised hands"}
      </h3>
      {hands.length === 0 ? (
        <p className="vr-host__empty">{t("voiceRooms.host.noHands") || "No one has raised a hand."}</p>
      ) : (
        <ul className="vr-host__hands">
          {hands.map((m) => (
            <li key={m.userId} data-testid={`vr-host-hand-${m.userId}`}>
              <span>{m.name}</span>
              {isHost && m.role !== "cohost" && m.userId !== hostId && (
                <button
                  type="button"
                  className="vr-btn vr-btn--ghost"
                  data-testid={`vr-host-promote-${m.userId}`}
                  onClick={() => onPromote(m.userId)}
                >
                  <ShieldPlus size={14} /> {t("voiceRooms.host.makeCohost") || "Make co-host"}
                </button>
              )}
            </li>
          ))}
        </ul>
      )}
      <p className="vr-host__note">
        {t("voiceRooms.host.speakNote") || "Anyone in the room can take the mic. A raised hand asks you for a turn."}
      </p>
      <div className="vr-host__actions">
        {isHost && (
          <button type="button" className="vr-btn vr-btn--ghost" data-testid="vr-host-mute-all" onClick={onMuteAll}>
            <MicOff size={14} /> {t("voiceRooms.host.muteAll") || "Mute everyone"}
          </button>
        )}
        {canEnd && !confirming && (
          <button type="button" className="vr-btn vr-btn--danger" data-testid="vr-host-end" onClick={() => setConfirming(true)}>
            <Power size={14} /> {t("voiceRooms.host.end") || "End room"}
          </button>
        )}
        {canEnd && confirming && (
          <span className="vr-host__confirm" role="group">
            <span>{t("voiceRooms.host.endConfirm") || "End the room for everyone?"}</span>
            <button type="button" className="vr-btn vr-btn--danger" data-testid="vr-host-end-confirm" onClick={onEnd}>
              {t("voiceRooms.host.endYes") || "End room"}
            </button>
            <button type="button" className="vr-btn vr-btn--ghost" data-testid="vr-host-end-cancel" onClick={() => setConfirming(false)}>
              {t("common.cancel") || "Cancel"}
            </button>
          </span>
        )}
      </div>
    </section>
  );
};

export default VoiceRoomHostPanel;
```

In `src/components/voiceRooms/VoiceRoomPage.tsx`:
- add `import VoiceRoomHostPanel from "./VoiceRoomHostPanel";`
- after `const live = …;` add

```tsx
  const me = vr.members.find((m) => m.userId === myId);
  const isHost = vr.role === "host" || (!!myId && vr.hostId === myId);
  const canEnd = isHost || (!!me && me.role === "cohost");
  const endRoom = async () => {
    await vr.endRoom();
    navigate("/voice-rooms");
  };
```
- between the closing `</div>` of `.vr-controls` and `<VoiceRoomChat …/>` insert

```tsx
          <VoiceRoomHostPanel
            members={vr.members}
            myId={myId}
            hostId={vr.hostId}
            isHost={isHost}
            canEnd={canEnd}
            onMuteAll={vr.muteAll}
            onPromote={(userId) => vr.promote(userId)}
            onEnd={endRoom}
          />
```

Append to `VoiceRooms.scss`:

```scss
.vr-host { border: 1px dashed #ffd600; border-radius: 16px; padding: 12px; margin-block-end: 16px; text-align: start; }
.vr-host__title { font-size: 1rem; font-weight: 800; margin: 0 0 8px; }
.vr-host__sub { font-size: 0.85rem; font-weight: 700; display: flex; align-items: center; gap: 6px; margin: 0 0 6px; }
.vr-host__hands { list-style: none; padding: 0; margin: 0 0 8px; display: flex; flex-direction: column; gap: 6px; }
.vr-host__hands li { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.vr-host__empty, .vr-host__note { color: #666; font-size: 0.85rem; margin: 0 0 8px; }
.vr-host__actions, .vr-host__confirm { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
```

Add to `eng.json` under `"voiceRooms"`:

```json
"host": {
  "title": "Host tools",
  "hands": "Raised hands",
  "noHands": "No one has raised a hand.",
  "makeCohost": "Make co-host",
  "speakNote": "Anyone in the room can take the mic. A raised hand asks you for a turn.",
  "muteAll": "Mute everyone",
  "end": "End room",
  "endConfirm": "End the room for everyone?",
  "endYes": "End room"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false VoiceRoomHostPanel VoiceRoomPage useVoiceRoom
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/voiceRooms/VoiceRoomHostPanel.tsx src/components/voiceRooms/VoiceRoomHostPanel.test.tsx src/components/voiceRooms/VoiceRoomPage.tsx src/components/voiceRooms/VoiceRoomPage.test.tsx src/components/voiceRooms/VoiceRooms.scss src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(voice-rooms): host tools — raised hands, mute all, co-host, end

The host sees raised hands and can make someone co-host, mute
everyone, or end the room after a confirmation; co-hosts can end it.
No "remove" button: the backend has no kick (logged as a follow-up).

Still open (Phase 4 rooms): language rooms, City/Genders tabs, routes,
i18n, push. Backend: speaker role, kick, raise-hand name mismatch with
the app.
EOF
```

---

### Task P4-ROOM-8: Language rooms REST slice + list page grouped by language + create topic room

**Files:**
- Create: `src/store/slices/languageRoomsSlice.ts`, `src/components/languageRooms/LanguageRoomsPage.tsx`, `src/components/languageRooms/CreateTopicRoomDialog.tsx`, `src/components/languageRooms/LanguageRooms.scss`
- Modify: `src/utils/locales/eng.json` (`languageRooms.*`)
- Test: `src/store/slices/languageRoomsEndpoints.test.ts`, `src/components/languageRooms/LanguageRoomsPage.test.tsx` (new)

**Interfaces:**
- Consumes (`be/routes/rooms.js`, `roomsEnabledGuard` then `protect`; all 404 while `ROOMS_ENABLED` is off):
  - `GET /api/v1/rooms` → `{count, data: Room[]}`; each `Room` = `_id, roomType ('hub'|'topic'), title, description, emojiFlag, targetLanguage, owner, admins, memberCount, maxMembers, lastActivityAt, isSeeded, isBanned, hasPendingRequest, pendingRequestCount? (owner/admin only), onlineCount, isMember, isOwnerOrAdmin` (`be/controllers/rooms.js:207-237`, contract test "language rooms"). Already sorted: the caller's learning-language hub first, then by `memberCount`. Calling it auto-joins the caller's hub (same as the app).
  - `GET /rooms/:id` (same fields), `POST /rooms {title, targetLanguage, description}` → 201 (title ≤60, description ≤300, ≤10 topic rooms per owner; 400 messages at `:134-170`), `POST /:id/join` → `{data:{isNewMember}}`; 403 `BANNED_FROM_ROOM` for a banned topic-room user (`:328-401`), `POST /:id/leave`, `POST /:id/request-join` (400 `ALREADY_MEMBER` / `REQUEST_ALREADY_PENDING` / `TOO_MANY_PENDING_REQUESTS`), `GET /:id/messages?page&limit` (`:266-326`), `GET /:id/members` (403 for non-members; `data[]` = `_id,name,username,imageUrls,role('owner'|'admin'|'member'),muted`), `GET /:id/requests` (owner/admin, topic rooms; `data[]` = `{user:{_id,name,username,images},requestedAt,status}`), `POST /:id/requests/:userId/approve|deny`, `DELETE /:id/members/:userId` (400 `CANNOT_KICK_OWNER`).
- Produces: `languageRoomsApiSlice` with hooks `useGetLanguageRoomsQuery()`, `useGetLanguageRoomQuery(id)`, `useCreateTopicRoomMutation()`, `useJoinLanguageRoomMutation()`, `useLeaveLanguageRoomMutation()`, `useRequestJoinLanguageRoomMutation()`, `useGetLanguageRoomMessagesQuery({roomId, page})`, `useGetLanguageRoomMembersQuery(id)`, `useGetLanguageRoomRequestsQuery(id)`, `useDecideLanguageRoomRequestMutation()` (`{roomId, userId, approve}`), `useRemoveLanguageRoomMemberMutation()`; `LANGUAGE_ROOMS_URL = "/api/v1/rooms"`; `languageRoomErrorText(err, t)`; `groupRoomsByLanguage(rooms)` → `Array<{ language: string; hub: Room | null; topics: Room[] }>` keeping server order of first appearance. Default export `LanguageRoomsPage` (route `/rooms`, wired in P4-ROOM-12); `CreateTopicRoomDialog` props `{ open; defaultLanguage; onClose(); onCreated(id) }`. Test ids: `language-rooms-page`, `language-rooms-group-<lang>`, `language-room-card-<id>`, `language-rooms-create`, `create-topic-room-dialog`, `create-topic-room-title`, `create-topic-room-language`, `create-topic-room-description`, `create-topic-room-submit`, `create-topic-room-error`.

- [ ] **Step 1: Write the failing tests**

Create `src/store/slices/languageRoomsEndpoints.test.ts`:

```ts
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import {
  languageRoomsApiSlice,
  LANGUAGE_ROOMS_URL,
  languageRoomErrorText,
  groupRoomsByLanguage,
} from "./languageRoomsSlice";

function makeStore() {
  return configureStore({
    reducer: { [apiSlice.reducerPath]: apiSlice.reducer, auth: (s: any = { userInfo: null }) => s },
    middleware: (g) => g().concat(apiSlice.middleware),
  });
}
type Captured = { url: string; method: string; body: string | undefined };
function mockFetch(): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify({ success: true, data: [] }), { status: 200, headers: { "content-type": "application/json" } });
  });
  return calls;
}
const ep = (n: string) => (languageRoomsApiSlice.endpoints as any)[n];
const path = (c: Captured) => new URL(c.url).pathname;

it.each([
  ["joinLanguageRoom", "r1", "POST", "/r1/join"],
  ["leaveLanguageRoom", "r1", "POST", "/r1/leave"],
  ["requestJoinLanguageRoom", "r1", "POST", "/r1/request-join"],
])("%s", async (name, arg, method, suffix) => {
  const calls = mockFetch();
  await makeStore().dispatch(ep(name).initiate(arg));
  expect([calls[0].method, path(calls[0])]).toEqual([method, `${LANGUAGE_ROOMS_URL}${suffix}`]);
});

it("creates a topic room with the app's body", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(ep("createTopicRoom").initiate({ title: " K-drama talk ", targetLanguage: "ko", description: "" }));
  expect([calls[0].method, path(calls[0])]).toEqual(["POST", LANGUAGE_ROOMS_URL]);
  expect(JSON.parse(calls[0].body as string)).toEqual({ title: "K-drama talk", targetLanguage: "ko", description: "" });
});

it("pages messages and decides requests", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("getLanguageRoomMessages").initiate({ roomId: "r1", page: 2 }));
  await store.dispatch(ep("decideLanguageRoomRequest").initiate({ roomId: "r1", userId: "u2", approve: true }));
  await store.dispatch(ep("decideLanguageRoomRequest").initiate({ roomId: "r1", userId: "u3", approve: false }));
  await store.dispatch(ep("removeLanguageRoomMember").initiate({ roomId: "r1", userId: "u4" }));
  const m = new URL(calls[0].url);
  expect(m.pathname).toBe(`${LANGUAGE_ROOMS_URL}/r1/messages`);
  expect(m.searchParams.get("page")).toBe("2");
  expect(m.searchParams.get("limit")).toBe("50");
  expect([calls[1].method, path(calls[1])]).toEqual(["POST", `${LANGUAGE_ROOMS_URL}/r1/requests/u2/approve`]);
  expect([calls[2].method, path(calls[2])]).toEqual(["POST", `${LANGUAGE_ROOMS_URL}/r1/requests/u3/deny`]);
  expect([calls[3].method, path(calls[3])]).toEqual(["DELETE", `${LANGUAGE_ROOMS_URL}/r1/members/u4`]);
});

it("groups hubs and topic rooms under their language, in server order", () => {
  const rooms: any[] = [
    { _id: "h-ko", roomType: "hub", targetLanguage: "ko", title: "Korean" },
    { _id: "t1", roomType: "topic", targetLanguage: "es", title: "Travel" },
    { _id: "t2", roomType: "topic", targetLanguage: "ko", title: "K-drama" },
    { _id: "h-es", roomType: "hub", targetLanguage: "es", title: "Spanish" },
  ];
  const groups = groupRoomsByLanguage(rooms);
  expect(groups.map((g) => [g.language, g.hub && g.hub._id, g.topics.map((t) => t._id)])).toEqual([
    ["ko", "h-ko", ["t2"]],
    ["es", "h-es", ["t1"]],
  ]);
});

describe("languageRoomErrorText", () => {
  const t = () => "";
  it.each([
    [{ status: 403, data: { code: "BANNED_FROM_ROOM", error: "You have been banned from this room" } }, "You were removed from this room. You can ask the owner to let you back in."],
    [{ status: 400, data: { code: "REQUEST_ALREADY_PENDING" } }, "Your request is waiting for the owner."],
    [{ status: 400, data: { error: "You can only own up to 10 topic rooms" } }, "You already have 10 rooms. Delete one to start another."],
    [{ status: 404, data: {} }, "This room is no longer available."],
    [{ status: 500 }, "Something went wrong. Try again."],
  ])("%j", (err, text) => expect(languageRoomErrorText(err, t)).toBe(text));
});
```

Create `src/components/languageRooms/LanguageRoomsPage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import LanguageRoomsPage from "./LanguageRoomsPage";

let mockRooms: any = { data: [], isLoading: false, isError: false };
const mockCreate = jest.fn();
jest.mock("../../store/slices/languageRoomsSlice", () => {
  const actual = jest.requireActual("../../store/slices/languageRoomsSlice");
  return {
    groupRoomsByLanguage: actual.groupRoomsByLanguage,
    languageRoomErrorText: actual.languageRoomErrorText,
    useGetLanguageRoomsQuery: () => mockRooms,
    useCreateTopicRoomMutation: () => [mockCreate, { isLoading: false }],
  };
});
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderPage() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me", language_to_learn: "Korean" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/rooms"]}>
        <Routes>
          <Route path="/rooms" element={<LanguageRoomsPage />} />
          <Route path="/rooms/:id" element={<div data-testid="room-page" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => mockCreate.mockReset());

it("shows each language with its hub and topic rooms, member and online counts", () => {
  mockRooms = {
    data: {
      data: [
        { _id: "h-ko", roomType: "hub", targetLanguage: "ko", title: "Korean", emojiFlag: "🇰🇷", memberCount: 240, onlineCount: 12, isMember: true },
        { _id: "t2", roomType: "topic", targetLanguage: "ko", title: "K-drama", memberCount: 9, onlineCount: 1, isMember: false },
      ],
    },
    isLoading: false,
    isError: false,
  };
  renderPage();
  const group = screen.getByTestId("language-rooms-group-ko");
  expect(group).toHaveTextContent("Korean");
  expect(screen.getByTestId("language-room-card-h-ko")).toHaveTextContent("240");
  expect(screen.getByTestId("language-room-card-h-ko")).toHaveTextContent("12");
  fireEvent.click(screen.getByTestId("language-room-card-t2"));
  expect(screen.getByTestId("room-page")).toBeInTheDocument();
});

it("creates a topic room and opens it", async () => {
  mockRooms = { data: { data: [] }, isLoading: false, isError: false };
  mockCreate.mockReturnValue({ unwrap: () => Promise.resolve({ data: { _id: "new1" } }) });
  renderPage();
  fireEvent.click(screen.getByTestId("language-rooms-create"));
  fireEvent.change(screen.getByTestId("create-topic-room-title"), { target: { value: "Travel" } });
  fireEvent.change(screen.getByTestId("create-topic-room-language"), { target: { value: "es" } });
  fireEvent.click(screen.getByTestId("create-topic-room-submit"));
  await waitFor(() => expect(screen.getByTestId("room-page")).toBeInTheDocument());
  expect(mockCreate).toHaveBeenCalledWith({ title: "Travel", targetLanguage: "es", description: "" });
});

it("keeps the dialog open with the reason on a refusal", async () => {
  mockRooms = { data: { data: [] }, isLoading: false, isError: false };
  mockCreate.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { error: "You can only own up to 10 topic rooms" } }) });
  renderPage();
  fireEvent.click(screen.getByTestId("language-rooms-create"));
  fireEvent.change(screen.getByTestId("create-topic-room-title"), { target: { value: "Travel" } });
  fireEvent.click(screen.getByTestId("create-topic-room-submit"));
  await waitFor(() => expect(screen.getByTestId("create-topic-room-error")).toHaveTextContent("10 rooms"));
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false languageRoomsEndpoints LanguageRoomsPage
```
Expected: FAIL — `Cannot find module './languageRoomsSlice'` / `'./LanguageRoomsPage'`.

- [ ] **Step 3: Implement**

Create `src/store/slices/languageRoomsSlice.ts`:

```ts
import { apiSlice } from "./apiSlice";

/** Language rooms ("hubs" + user topic rooms), routes/rooms.js. Same calls as the app. */
export const LANGUAGE_ROOMS_URL = "/api/v1/rooms";

export interface LanguageRoom {
  _id: string;
  roomType: "hub" | "topic";
  title: string;
  description?: string;
  emojiFlag?: string;
  targetLanguage: string;
  owner?: string;
  memberCount?: number;
  maxMembers?: number;
  onlineCount?: number;
  isMember?: boolean;
  isOwnerOrAdmin?: boolean;
  isBanned?: boolean;
  hasPendingRequest?: boolean;
  pendingRequestCount?: number;
  lastActivityAt?: string;
}

export function groupRoomsByLanguage(rooms: LanguageRoom[]): Array<{ language: string; hub: LanguageRoom | null; topics: LanguageRoom[] }> {
  const order: string[] = [];
  const groups: { [lang: string]: { language: string; hub: LanguageRoom | null; topics: LanguageRoom[] } } = {};
  (rooms || []).forEach((room) => {
    const lang = String(room.targetLanguage || "");
    if (!groups[lang]) {
      groups[lang] = { language: lang, hub: null, topics: [] };
      order.push(lang);
    }
    if (room.roomType === "hub" && !groups[lang].hub) groups[lang].hub = room;
    else groups[lang].topics.push(room);
  });
  return order.map((lang) => groups[lang]);
}

const tagged = apiSlice.enhanceEndpoints({ addTagTypes: ["LanguageRooms", "LanguageRoomRequests"] });

export const languageRoomsApiSlice = tagged.injectEndpoints({
  endpoints: (builder: any) => ({
    getLanguageRooms: builder.query({
      query: () => ({ url: LANGUAGE_ROOMS_URL }),
      keepUnusedDataFor: 30,
      providesTags: ["LanguageRooms"],
    }),
    getLanguageRoom: builder.query({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}` }),
      transformResponse: (r: any) => (r && r.data) || null,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "LanguageRooms", id }],
    }),
    createTopicRoom: builder.mutation({
      query: (body: { title: string; targetLanguage: string; description?: string }) => ({
        url: LANGUAGE_ROOMS_URL,
        method: "POST",
        body: { title: String(body.title || "").trim(), targetLanguage: body.targetLanguage, description: String(body.description || "").trim() },
      }),
      invalidatesTags: ["LanguageRooms"],
    }),
    joinLanguageRoom: builder.mutation({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/join`, method: "POST" }),
      invalidatesTags: (_r: any, _e: any, id: string) => ["LanguageRooms", { type: "LanguageRooms", id }],
    }),
    leaveLanguageRoom: builder.mutation({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/leave`, method: "POST" }),
      invalidatesTags: (_r: any, _e: any, id: string) => ["LanguageRooms", { type: "LanguageRooms", id }],
    }),
    requestJoinLanguageRoom: builder.mutation({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/request-join`, method: "POST" }),
      invalidatesTags: (_r: any, _e: any, id: string) => [{ type: "LanguageRooms", id }],
    }),
    getLanguageRoomMessages: builder.query({
      query: ({ roomId, page = 1 }: { roomId: string; page?: number }) => ({
        url: `${LANGUAGE_ROOMS_URL}/${roomId}/messages`,
        params: { page: String(page), limit: "50" },
      }),
      keepUnusedDataFor: 0,
    }),
    getLanguageRoomMembers: builder.query({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/members` }),
      providesTags: (_r: any, _e: any, id: string) => [{ type: "LanguageRooms", id: `${id}:members` }],
    }),
    getLanguageRoomRequests: builder.query({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/requests` }),
      providesTags: (_r: any, _e: any, id: string) => [{ type: "LanguageRoomRequests", id }],
    }),
    decideLanguageRoomRequest: builder.mutation({
      query: ({ roomId, userId, approve }: { roomId: string; userId: string; approve: boolean }) => ({
        url: `${LANGUAGE_ROOMS_URL}/${roomId}/requests/${userId}/${approve ? "approve" : "deny"}`,
        method: "POST",
      }),
      invalidatesTags: (_r: any, _e: any, a: { roomId: string }) => [
        { type: "LanguageRoomRequests", id: a.roomId },
        { type: "LanguageRooms", id: `${a.roomId}:members` },
        { type: "LanguageRooms", id: a.roomId },
      ],
    }),
    removeLanguageRoomMember: builder.mutation({
      query: ({ roomId, userId }: { roomId: string; userId: string }) => ({
        url: `${LANGUAGE_ROOMS_URL}/${roomId}/members/${userId}`,
        method: "DELETE",
      }),
      invalidatesTags: (_r: any, _e: any, a: { roomId: string }) => [
        { type: "LanguageRooms", id: `${a.roomId}:members` },
        { type: "LanguageRooms", id: a.roomId },
      ],
    }),
  }),
});

export function languageRoomErrorText(err: any, t: (k: string) => string): string {
  const data = (err && err.data) || {};
  const code = String(data.code || "");
  const raw = String(data.error || data.message || "");
  if (code === "BANNED_FROM_ROOM")
    return t("languageRooms.errors.banned") || "You were removed from this room. You can ask the owner to let you back in.";
  if (code === "REQUEST_ALREADY_PENDING") return t("languageRooms.errors.pending") || "Your request is waiting for the owner.";
  if (code === "TOO_MANY_PENDING_REQUESTS") return t("languageRooms.errors.busy") || "This room has too many requests right now. Try later.";
  if (code === "CANNOT_KICK_OWNER") return t("languageRooms.errors.owner") || "The owner can't be removed.";
  if (/up to \d+ topic rooms/i.test(raw)) return t("languageRooms.errors.tooMany") || "You already have 10 rooms. Delete one to start another.";
  if (/characters or fewer|1-\d+ characters/i.test(raw)) return t("languageRooms.errors.titleLength") || "The name can be up to 60 characters.";
  if (err && err.status === 404) return t("languageRooms.errors.gone") || "This room is no longer available.";
  return t("languageRooms.errors.generic") || "Something went wrong. Try again.";
}

export const {
  useGetLanguageRoomsQuery,
  useGetLanguageRoomQuery,
  useCreateTopicRoomMutation,
  useJoinLanguageRoomMutation,
  useLeaveLanguageRoomMutation,
  useRequestJoinLanguageRoomMutation,
  useGetLanguageRoomMessagesQuery,
  useLazyGetLanguageRoomMessagesQuery,
  useGetLanguageRoomMembersQuery,
  useGetLanguageRoomRequestsQuery,
  useDecideLanguageRoomRequestMutation,
  useRemoveLanguageRoomMemberMutation,
} = languageRoomsApiSlice as any;
```

Create `src/components/languageRooms/CreateTopicRoomDialog.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { useCreateTopicRoomMutation, languageRoomErrorText } from "../../store/slices/languageRoomsSlice";

interface Props {
  open: boolean;
  defaultLanguage: string;
  onClose(): void;
  onCreated(id: string): void;
}

const CreateTopicRoomDialog: React.FC<Props> = ({ open, defaultLanguage, onClose, onCreated }) => {
  const { t } = useTranslation();
  const [create, { isLoading }] = useCreateTopicRoomMutation();
  const [title, setTitle] = useState("");
  const [language, setLanguage] = useState(defaultLanguage || "");
  const [description, setDescription] = useState("");
  const [error, setError] = useState("");
  if (!open) return null;
  const valid = title.trim().length > 0 && title.trim().length <= 60 && language.trim().length > 0;

  const submit = async () => {
    if (!valid || isLoading) return;
    setError("");
    try {
      const res = await create({ title: title.trim(), targetLanguage: language.trim(), description: description.trim() }).unwrap();
      const id = res && res.data && res.data._id;
      if (id) onCreated(String(id));
    } catch (err) {
      setError(languageRoomErrorText(err, t));
    }
  };

  return (
    <div className="vr-dialog-backdrop" role="presentation">
      <div className="vr-dialog" role="dialog" aria-modal="true" data-testid="create-topic-room-dialog">
        <h2 className="vr-dialog__title">{t("languageRooms.create.title") || "Start a topic room"}</h2>
        <label className="vr-field">
          <span>{t("languageRooms.create.name") || "Topic"}</span>
          <input data-testid="create-topic-room-title" value={title} maxLength={60} onChange={(e) => setTitle(e.target.value)} />
        </label>
        <label className="vr-field">
          <span>{t("languageRooms.create.language") || "Language"}</span>
          <input data-testid="create-topic-room-language" value={language} onChange={(e) => setLanguage(e.target.value)} />
        </label>
        <label className="vr-field">
          <span>{t("languageRooms.create.description") || "Description (optional)"}</span>
          <textarea data-testid="create-topic-room-description" value={description} maxLength={300} onChange={(e) => setDescription(e.target.value)} />
        </label>
        {error && (
          <p className="vr-error" role="alert" data-testid="create-topic-room-error">
            {error}
          </p>
        )}
        <div className="vr-dialog__actions">
          <button type="button" className="vr-btn vr-btn--ghost" onClick={onClose} disabled={isLoading}>
            {t("common.cancel") || "Cancel"}
          </button>
          <button type="button" className="vr-btn vr-btn--primary" data-testid="create-topic-room-submit" disabled={!valid || isLoading} onClick={submit}>
            {t("languageRooms.create.submit") || "Create room"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default CreateTopicRoomDialog;
```

Create `src/components/languageRooms/LanguageRoomsPage.tsx`:

```tsx
import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Users, Circle, Plus, Lock } from "lucide-react";
import { useGetLanguageRoomsQuery, groupRoomsByLanguage, LanguageRoom } from "../../store/slices/languageRoomsSlice";
import { languageFlag } from "../../utils/languages";
import CreateTopicRoomDialog from "./CreateTopicRoomDialog";
import "../voiceRooms/VoiceRooms.scss";
import "./LanguageRooms.scss";

const LanguageRoomsPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user);
  const { data, isLoading, isError, refetch } = useGetLanguageRoomsQuery();
  const [creating, setCreating] = useState(false);
  const rooms: LanguageRoom[] = (data && Array.isArray(data.data) ? data.data : []) as LanguageRoom[];
  const groups = groupRoomsByLanguage(rooms);

  const card = (room: LanguageRoom) => (
    <li key={room._id}>
      <button type="button" className="lr-card" data-testid={`language-room-card-${room._id}`} onClick={() => navigate(`/rooms/${room._id}`)}>
        <span className="lr-card__title">
          {room.roomType === "hub" ? room.emojiFlag || languageFlag(room.targetLanguage) : "#"} {room.title}
          {room.isBanned && <Lock size={12} aria-label={t("languageRooms.list.locked") || "Locked"} />}
        </span>
        <span className="lr-card__meta">
          <Users size={12} /> {room.memberCount || 0}
          <Circle size={8} className="lr-online" aria-hidden /> {room.onlineCount || 0}
          {room.isMember && <span className="vr-chip">{t("languageRooms.list.joined") || "Joined"}</span>}
        </span>
      </button>
    </li>
  );

  return (
    <section className="vr-page" data-testid="language-rooms-page">
      <header className="vr-page__head">
        <h1>{t("languageRooms.list.title") || "Language rooms"}</h1>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="language-rooms-create" onClick={() => setCreating(true)}>
          <Plus size={16} /> {t("languageRooms.list.create") || "New topic room"}
        </button>
      </header>
      {isError && (
        <p className="vr-error" role="alert">
          {t("languageRooms.list.error") || "Couldn't load language rooms."}{" "}
          <button type="button" className="vr-link" onClick={() => refetch()}>
            {t("common.retry") || "Retry"}
          </button>
        </p>
      )}
      {!isLoading && !isError && groups.length === 0 && <p className="vr-empty">{t("languageRooms.list.empty") || "No rooms yet."}</p>}
      {groups.map((g) => (
        <section key={g.language} className="lr-group" data-testid={`language-rooms-group-${g.language}`}>
          <h2 className="lr-group__title">{g.hub ? g.hub.title : g.language}</h2>
          <ul className="lr-list">
            {g.hub && card(g.hub)}
            {g.topics.map(card)}
          </ul>
        </section>
      ))}
      <CreateTopicRoomDialog
        open={creating}
        defaultLanguage={(me && me.language_to_learn) || ""}
        onClose={() => setCreating(false)}
        onCreated={(id) => {
          setCreating(false);
          navigate(`/rooms/${id}`);
        }}
      />
    </section>
  );
};

export default LanguageRoomsPage;
```

(The create test types `es` over the default `Korean`; the backend normalises `targetLanguage` itself — `normalizeLanguage` in `be/controllers/rooms.js:146-150` — and answers 400 "A valid targetLanguage is required" for anything it cannot map, which the dialog shows as the generic line.)

Create `src/components/languageRooms/LanguageRooms.scss`:

```scss
.lr-group { margin-block-end: 20px; }
.lr-group__title { font-size: 1.05rem; font-weight: 800; margin-block: 0 8px; }
.lr-list { list-style: none; padding: 0; margin: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 8px; }
.lr-card { inline-size: 100%; text-align: start; border: 1px solid var(--bs-border-color, #eee); border-radius: 14px; padding: 12px; background: transparent; display: flex; flex-direction: column; gap: 6px; }
.lr-card__title { font-weight: 800; display: flex; align-items: center; gap: 6px; }
.lr-card__meta { display: flex; align-items: center; gap: 6px; font-size: 0.85rem; color: #666; }
.lr-online { color: #2ecc71; fill: #2ecc71; margin-inline-start: 6px; }
.lr-room { display: grid; grid-template-columns: 1fr; gap: 12px; }
@media (min-width: 900px) { .lr-room { grid-template-columns: 1fr 280px; } }
.lr-thread { border: 1px solid var(--bs-border-color, #eee); border-radius: 16px; display: flex; flex-direction: column; min-block-size: 60vh; }
.lr-thread__lines { list-style: none; margin: 0; padding: 12px; flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 8px; text-align: start; }
.lr-line__system { color: #888; font-size: 0.8rem; text-align: center; }
.lr-thread__compose { display: flex; gap: 8px; padding: 12px; border-block-start: 1px solid var(--bs-border-color, #eee); }
.lr-thread__compose input { flex: 1; border: 1px solid var(--bs-border-color, #ddd); border-radius: 999px; padding-block: 8px; padding-inline: 14px; }
.lr-side { border: 1px solid var(--bs-border-color, #eee); border-radius: 16px; padding: 12px; text-align: start; }
```

Add to `eng.json` a new top-level `"languageRooms"`:

```json
"list": {
  "title": "Language rooms",
  "create": "New topic room",
  "error": "Couldn't load language rooms.",
  "empty": "No rooms yet.",
  "joined": "Joined",
  "locked": "Locked"
},
"create": {
  "title": "Start a topic room",
  "name": "Topic",
  "language": "Language",
  "description": "Description (optional)",
  "submit": "Create room"
},
"errors": {
  "banned": "You were removed from this room. You can ask the owner to let you back in.",
  "pending": "Your request is waiting for the owner.",
  "busy": "This room has too many requests right now. Try later.",
  "owner": "The owner can't be removed.",
  "tooMany": "You already have 10 rooms. Delete one to start another.",
  "titleLength": "The name can be up to 60 characters.",
  "gone": "This room is no longer available.",
  "generic": "Something went wrong. Try again."
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false languageRoomsEndpoints LanguageRoomsPage
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/store/slices/languageRoomsSlice.ts src/store/slices/languageRoomsEndpoints.test.ts src/components/languageRooms/LanguageRoomsPage.tsx src/components/languageRooms/CreateTopicRoomDialog.tsx src/components/languageRooms/LanguageRooms.scss src/components/languageRooms/LanguageRoomsPage.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(language-rooms): REST slice, rooms grouped by language, topic rooms

GET /rooms grouped into each language's hub plus its topic rooms, in
the server's order (the member's own language first), with member and
online counts; create a topic room with the app's body and its limits.

Still open (Phase 4 rooms): room page, owner tools, City/Genders tabs,
routes, i18n, push.
EOF
```

---

### Task P4-ROOM-9: Language room page: history, live messages, send with ack, presence, join/leave/request to join

**Files:**
- Create: `src/components/languageRooms/LanguageRoomPage.tsx`, `src/components/languageRooms/roomMessages.ts`
- Modify: `src/utils/locales/eng.json` (`languageRooms.room.*`)
- Test: `src/components/languageRooms/roomMessages.test.ts`, `src/components/languageRooms/LanguageRoomPage.test.tsx` (new)

**Interfaces:**
- Consumes: P4-ROOM-8 hooks (`useGetLanguageRoomQuery`, `useGetLanguageRoomMessagesQuery`, `useLazyGetLanguageRoomMessagesQuery`, `useJoinLanguageRoomMutation`, `useLeaveLanguageRoomMutation`, `useRequestJoinLanguageRoomMutation`, `languageRoomErrorText`); `useSocket()` `{socket, connectionEpoch}`; `emitWithAck` + `SOCKET_ACK_TIMEOUT_MS`. Socket (`be/socket/roomHandler.js:146-296`): emit `room:join {roomId}` (members only; non-members get `room:error`), `room:leave {roomId}`, `room:message {roomId, message, messageType:'text'}` → ack `{status:'success', message}` | `{status:'error', error}` (rate-limited: "Too many messages — slow down."); listen `room:message <Message>` (also delivered to the sender — the server emits to the whole socket room), `room:presence {roomId, online}`, `room:error {message}`. History: `GET /rooms/:id/messages?page=N&limit=50` returns that page **oldest-first**; page 1 = newest 50; `pagination.hasNextPage` = older pages exist. Messages: `_id, conversationId, sender{_id,name,username,images,userMode}, message, messageType ('text'|'system'|'media'|'voice'|'sticker'|'gif'|…), createdAt`.
- Produces: default export `LanguageRoomPage` (route `/rooms/:id`); `mergeMessages(existing, incoming)` (dedupe by `_id`, sorted by `createdAt`) and `messageLabel(msg, t)` from `roomMessages.ts`. Test ids: `language-room-page`, `language-room-join`, `language-room-request`, `language-room-pending`, `language-room-leave`, `language-room-online`, `language-room-line`, `language-room-older`, `language-room-input`, `language-room-send`, `language-room-send-error`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/languageRooms/roomMessages.test.ts`:

```ts
import { mergeMessages, messageLabel } from "./roomMessages";

const m = (id: string, at: string, extra: any = {}) => Object.assign({ _id: id, createdAt: at, message: id, messageType: "text" }, extra);

it("dedupes by id and keeps chronological order across pages and live events", () => {
  const page1 = [m("b", "2026-10-16T10:01:00Z"), m("c", "2026-10-16T10:02:00Z")];
  const older = [m("a", "2026-10-16T10:00:00Z"), m("b", "2026-10-16T10:01:00Z")];
  const live = [m("c", "2026-10-16T10:02:00Z"), m("d", "2026-10-16T10:03:00Z")];
  expect(mergeMessages(mergeMessages(page1, older), live).map((x) => x._id)).toEqual(["a", "b", "c", "d"]);
});

it("labels kinds the web does not draw instead of showing nothing", () => {
  const t = () => "";
  expect(messageLabel(m("x", "2026", { message: "hola" }), t)).toBe("hola");
  expect(messageLabel(m("x", "2026", { messageType: "voice", message: "" }), t)).toBe("Voice message — open the app to listen");
  expect(messageLabel(m("x", "2026", { messageType: "media", message: "" }), t)).toBe("Photo or video — open the app to see it");
  expect(messageLabel(m("x", "2026", { messageType: "sticker", message: "" }), t)).toBe("Sticker");
  expect(messageLabel(m("x", "2026", { messageType: "poll", message: "" }), t)).toBe("Open the app to see this message");
});
```

Create `src/components/languageRooms/LanguageRoomPage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import LanguageRoomPage from "./LanguageRoomPage";

type H = (...a: any[]) => void;
const handlers: { [e: string]: H[] } = {};
const emitted: Array<[string, any]> = [];
let ackWith: any = { status: "success" };
const mockSocket = {
  on: (e: string, h: H) => ((handlers[e] = handlers[e] || []).push(h)),
  off: (e: string, h: H) => (handlers[e] = (handlers[e] || []).filter((x) => x !== h)),
  emit: (e: string, p: any, cb?: (r: any) => void) => {
    emitted.push([e, p]);
    if (cb && ackWith !== "never") cb(ackWith);
  },
};
const serverSays = (e: string, p: any) => act(() => (handlers[e] || []).slice().forEach((h) => h(p)));
let mockEpoch = 0;
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: mockSocket, isConnected: true, emit: jest.fn(), connectionEpoch: mockEpoch, kicked: false, reconnect: jest.fn() }),
}));

let mockRoom: any = {};
let mockPage: any = { data: [], pagination: { hasNextPage: false } };
const mockJoin = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
const mockLeave = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
const mockRequest = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
const mockLoadOlder = jest.fn(() => ({ unwrap: () => Promise.resolve({ data: [{ _id: "old1", createdAt: "2026-10-16T09:00:00Z", message: "older", messageType: "text", sender: { _id: "u2", name: "Ana" } }], pagination: { hasNextPage: false } }) }));
jest.mock("../../store/slices/languageRoomsSlice", () => {
  const actual = jest.requireActual("../../store/slices/languageRoomsSlice");
  return {
    languageRoomErrorText: actual.languageRoomErrorText,
    useGetLanguageRoomQuery: () => ({ data: mockRoom, refetch: jest.fn() }),
    useGetLanguageRoomMessagesQuery: (_a: any, o: any) => (o && o.skip ? { data: undefined } : { data: mockPage, refetch: jest.fn() }),
    useLazyGetLanguageRoomMessagesQuery: () => [mockLoadOlder],
    useJoinLanguageRoomMutation: () => [mockJoin],
    useLeaveLanguageRoomMutation: () => [mockLeave],
    useRequestJoinLanguageRoomMutation: () => [mockRequest],
    useGetLanguageRoomMembersQuery: () => ({ data: { data: [] } }),
    useGetLanguageRoomRequestsQuery: () => ({ data: { data: [] } }),
    useDecideLanguageRoomRequestMutation: () => [jest.fn()],
    useRemoveLanguageRoomMemberMutation: () => [jest.fn()],
  };
});
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderPage() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me", name: "Me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/rooms/r1"]}>
        <Routes>
          <Route path="/rooms/:id" element={<LanguageRoomPage />} />
          <Route path="/rooms" element={<div data-testid="rooms-list" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  Object.keys(handlers).forEach((k) => delete handlers[k]);
  emitted.length = 0;
  ackWith = { status: "success" };
  mockEpoch = 0;
  jest.clearAllMocks();
  mockRoom = { _id: "r1", roomType: "topic", title: "K-drama", targetLanguage: "ko", isMember: true, onlineCount: 3 };
  mockPage = {
    data: [{ _id: "m1", createdAt: "2026-10-16T10:00:00Z", message: "안녕", messageType: "text", sender: { _id: "u2", name: "Ana" } }],
    pagination: { hasNextPage: true },
  };
});

it("a member sees history, subscribes to the room, and leaves the socket room on unmount", () => {
  const view = renderPage();
  expect(screen.getAllByTestId("language-room-line")[0]).toHaveTextContent("안녕");
  expect(emitted).toContainEqual(["room:join", { roomId: "r1" }]);
  view.unmount();
  expect(emitted).toContainEqual(["room:leave", { roomId: "r1" }]);
});

it("live messages and presence update the page; other rooms are ignored", () => {
  renderPage();
  serverSays("room:message", { _id: "m2", conversationId: "r1", createdAt: "2026-10-16T10:01:00Z", message: "hi", messageType: "text", sender: { _id: "u3", name: "Sam" } });
  serverSays("room:message", { _id: "m3", conversationId: "other", createdAt: "2026-10-16T10:02:00Z", message: "nope", messageType: "text", sender: { _id: "u3" } });
  serverSays("room:presence", { roomId: "r1", online: 7 });
  expect(screen.getAllByTestId("language-room-line").map((n) => n.textContent)).toEqual([expect.stringContaining("안녕"), expect.stringContaining("hi")]);
  expect(screen.getByTestId("language-room-online")).toHaveTextContent("7");
});

it("sends over the socket with an ack; the echoed message appears once", () => {
  renderPage();
  fireEvent.change(screen.getByTestId("language-room-input"), { target: { value: " hola " } });
  fireEvent.click(screen.getByTestId("language-room-send"));
  expect(emitted).toContainEqual(["room:message", { roomId: "r1", message: "hola", messageType: "text" }]);
  const echo = { _id: "m9", conversationId: "r1", createdAt: "2026-10-16T10:05:00Z", message: "hola", messageType: "text", sender: { _id: "me", name: "Me" } };
  serverSays("room:message", echo);
  serverSays("room:message", echo);
  expect(screen.getAllByTestId("language-room-line").filter((n) => /hola/.test(n.textContent || ""))).toHaveLength(1);
});

it("a refused send keeps the text and says why", () => {
  ackWith = { status: "error", error: "Too many messages — slow down." };
  renderPage();
  fireEvent.change(screen.getByTestId("language-room-input"), { target: { value: "spam" } });
  fireEvent.click(screen.getByTestId("language-room-send"));
  expect(screen.getByTestId("language-room-send-error")).toHaveTextContent(/slow down/i);
  expect((screen.getByTestId("language-room-input") as HTMLInputElement).value).toBe("spam");
});

it("loads older messages above", async () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-older"));
  await waitFor(() => expect(screen.getAllByTestId("language-room-line")[0]).toHaveTextContent("older"));
  expect(mockLoadOlder).toHaveBeenCalledWith({ roomId: "r1", page: 2 });
});

it("re-subscribes after a socket reconnect", () => {
  const view = renderPage();
  emitted.length = 0;
  mockEpoch = 1;
  view.rerender(
    <Provider store={configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s } })}>
      <MemoryRouter initialEntries={["/rooms/r1"]}>
        <Routes>
          <Route path="/rooms/:id" element={<LanguageRoomPage />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
  expect(emitted).toContainEqual(["room:join", { roomId: "r1" }]);
});

it("a non-member joins first; a banned member asks to come back", async () => {
  mockRoom = Object.assign({}, mockRoom, { isMember: false });
  const view = renderPage();
  expect(emitted.find(([e]) => e === "room:join")).toBeUndefined();
  fireEvent.click(screen.getByTestId("language-room-join"));
  await waitFor(() => expect(mockJoin).toHaveBeenCalledWith("r1"));
  view.unmount();
  mockRoom = Object.assign({}, mockRoom, { isMember: false, isBanned: true });
  const v2 = renderPage();
  fireEvent.click(screen.getByTestId("language-room-request"));
  await waitFor(() => expect(mockRequest).toHaveBeenCalledWith("r1"));
  v2.unmount();
  mockRoom = Object.assign({}, mockRoom, { isMember: false, isBanned: true, hasPendingRequest: true });
  renderPage();
  expect(screen.getByTestId("language-room-pending")).toBeInTheDocument();
});

it("leaves the room and returns to the list", async () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-leave"));
  await waitFor(() => expect(screen.getByTestId("rooms-list")).toBeInTheDocument());
  expect(mockLeave).toHaveBeenCalledWith("r1");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false roomMessages LanguageRoomPage
```
Expected: FAIL — `Cannot find module './roomMessages'` / `'./LanguageRoomPage'`.

- [ ] **Step 3: Implement**

Create `src/components/languageRooms/roomMessages.ts`:

```ts
export interface RoomMessage {
  _id: string;
  conversationId?: string;
  sender?: { _id: string; name?: string; images?: string[] } | string;
  message?: string;
  messageType?: string;
  createdAt: string;
}

export function mergeMessages(existing: RoomMessage[], incoming: RoomMessage[]): RoomMessage[] {
  const byId: { [id: string]: RoomMessage } = {};
  existing.concat(incoming || []).forEach((m) => {
    if (m && m._id) byId[String(m._id)] = m;
  });
  return Object.keys(byId)
    .map((id) => byId[id])
    .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
}

/** Text for a message; kinds the web does not draw get an honest label. */
export function messageLabel(m: RoomMessage, t: (k: string) => string): string {
  const type = m.messageType || "text";
  if ((type === "text" || type === "system") && m.message) return m.message;
  if (m.message && type !== "voice" && type !== "media") return m.message;
  if (type === "voice") return t("languageRooms.room.voice") || "Voice message — open the app to listen";
  if (type === "media") return t("languageRooms.room.media") || "Photo or video — open the app to see it";
  if (type === "sticker" || type === "gif") return t("languageRooms.room.sticker") || "Sticker";
  return t("languageRooms.room.unsupported") || "Open the app to see this message";
}
```

Create `src/components/languageRooms/LanguageRoomPage.tsx`:

```tsx
import React, { useEffect, useRef, useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate, useParams, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Send, Circle, LogOut } from "lucide-react";
import { useSocket } from "../chat/hooks/useSocket";
import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "../chat/lib/socketAck";
import {
  useGetLanguageRoomQuery,
  useGetLanguageRoomMessagesQuery,
  useLazyGetLanguageRoomMessagesQuery,
  useJoinLanguageRoomMutation,
  useLeaveLanguageRoomMutation,
  useRequestJoinLanguageRoomMutation,
  languageRoomErrorText,
} from "../../store/slices/languageRoomsSlice";
import { mergeMessages, messageLabel, RoomMessage } from "./roomMessages";
import LanguageRoomOwnerPanel from "./LanguageRoomOwnerPanel";
import "../voiceRooms/VoiceRooms.scss";
import "./LanguageRooms.scss";

const senderName = (s: RoomMessage["sender"]) => (s && typeof s === "object" ? s.name || "" : "");
const senderId = (s: RoomMessage["sender"]) => (s && typeof s === "object" ? String(s._id) : s ? String(s) : "");

const LanguageRoomPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const myId = useSelector((s: any) => String((s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id) || ""));
  const { socket, connectionEpoch } = useSocket() as any;
  const { data: room, refetch: refetchRoom } = useGetLanguageRoomQuery(id, { skip: !id });
  const isMember = !!(room && room.isMember);
  const { data: page1 } = useGetLanguageRoomMessagesQuery({ roomId: id, page: 1 }, { skip: !id || !isMember });
  const [loadPage] = useLazyGetLanguageRoomMessagesQuery();
  const [joinRoom] = useJoinLanguageRoomMutation();
  const [leaveRoom] = useLeaveLanguageRoomMutation();
  const [requestJoin] = useRequestJoinLanguageRoomMutation();

  const [messages, setMessages] = useState<RoomMessage[]>([]);
  const [online, setOnline] = useState<number | null>(null);
  const [olderPage, setOlderPage] = useState(2);
  const [hasOlder, setHasOlder] = useState(false);
  const [text, setText] = useState("");
  const [sendError, setSendError] = useState("");
  const [actionError, setActionError] = useState("");

  useEffect(() => {
    if (!page1) return;
    setMessages((prev) => mergeMessages(prev, (page1.data || []) as RoomMessage[]));
    setHasOlder(!!(page1.pagination && page1.pagination.hasNextPage));
  }, [page1]);

  // Socket subscription: members only (the server refuses others).
  useEffect(() => {
    if (!socket || !id || !isMember) return;
    const onMessage = (m: any) => {
      if (!m || String(m.conversationId) !== String(id)) return;
      setMessages((prev) => mergeMessages(prev, [m]));
    };
    const onPresence = (p: any) => {
      if (p && String(p.roomId) === String(id)) setOnline(Number(p.online) || 0);
    };
    socket.on("room:message", onMessage);
    socket.on("room:presence", onPresence);
    socket.emit("room:join", { roomId: id });
    return () => {
      socket.off("room:message", onMessage);
      socket.off("room:presence", onPresence);
      socket.emit("room:leave", { roomId: id });
    };
    // connectionEpoch: a reconnected socket has left every socket room, so subscribe again.
  }, [socket, id, isMember, connectionEpoch]);

  const send = () => {
    const message = text.trim();
    if (!message || !socket) return;
    setSendError("");
    emitWithAck(socket, "room:message", { roomId: id, message, messageType: "text" }, SOCKET_ACK_TIMEOUT_MS, {
      onAck: (ack: any) => {
        if (ack && ack.status === "success") {
          if (ack.message) setMessages((prev) => mergeMessages(prev, [ack.message]));
          setText((current) => (current.trim() === message ? "" : current));
        } else {
          setSendError(/slow down/i.test(String(ack && ack.error)) ? t("languageRooms.room.slowDown") || "You're sending too fast. Slow down a little." : t("languageRooms.room.notSent") || "Not sent. Try again.");
        }
      },
      onTimeout: () => setSendError(t("languageRooms.room.notSent") || "Not sent. Try again."),
    });
  };

  const loadOlder = async () => {
    try {
      const res = await loadPage({ roomId: id, page: olderPage }).unwrap();
      setMessages((prev) => mergeMessages(prev, (res && res.data) || []));
      setHasOlder(!!(res && res.pagination && res.pagination.hasNextPage));
      setOlderPage((p) => p + 1);
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
  };

  const act = async (fn: () => Promise<any>) => {
    setActionError("");
    try {
      await fn();
      if (refetchRoom) refetchRoom();
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
  };

  const leave = async () => {
    try {
      await leaveRoom(id).unwrap();
      navigate("/rooms");
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
  };

  // Keep the newest message in view.
  const endRef = useRef<HTMLLIElement | null>(null);
  useEffect(() => {
    if (endRef.current && typeof endRef.current.scrollIntoView === "function") endRef.current.scrollIntoView({ block: "nearest" });
  }, [messages.length]);

  return (
    <section className="vr-page" data-testid="language-room-page">
      <header className="vr-page__head">
        <div>
          <Link to="/rooms" className="vr-link">
            {t("languageRooms.room.back") || "All rooms"}
          </Link>
          <h1>{(room && room.title) || ""}</h1>
        </div>
        {isMember && (
          <span className="lr-card__meta" data-testid="language-room-online">
            <Circle size={8} className="lr-online" aria-hidden /> {online === null ? (room && room.onlineCount) || 0 : online}{" "}
            {t("languageRooms.room.online") || "online"}
          </span>
        )}
      </header>
      {actionError && (
        <p className="vr-error" role="alert">
          {actionError}
        </p>
      )}

      {room && !isMember && (
        <div className="vr-room__gate">
          {room.description && <p>{room.description}</p>}
          {room.hasPendingRequest ? (
            <p data-testid="language-room-pending">{t("languageRooms.room.pending") || "Request sent. The owner will let you in."}</p>
          ) : room.isBanned ? (
            <button type="button" className="vr-btn vr-btn--primary" data-testid="language-room-request" onClick={() => act(() => requestJoin(id).unwrap())}>
              {t("languageRooms.room.request") || "Ask to join"}
            </button>
          ) : (
            <button type="button" className="vr-btn vr-btn--primary" data-testid="language-room-join" onClick={() => act(() => joinRoom(id).unwrap())}>
              {t("languageRooms.room.join") || "Join room"}
            </button>
          )}
        </div>
      )}

      {isMember && (
        <div className="lr-room">
          <div className="lr-thread">
            <ol className="lr-thread__lines">
              {hasOlder && (
                <li>
                  <button type="button" className="vr-link" data-testid="language-room-older" onClick={loadOlder}>
                    {t("languageRooms.room.older") || "Load earlier messages"}
                  </button>
                </li>
              )}
              {messages.map((m) =>
                m.messageType === "system" ? (
                  <li key={m._id} className="lr-line__system" data-testid="language-room-line">
                    {messageLabel(m, t)}
                  </li>
                ) : (
                  <li key={m._id} className={senderId(m.sender) === myId ? "lr-line is-mine" : "lr-line"} data-testid="language-room-line">
                    <strong>{senderName(m.sender)}</strong> <span>{messageLabel(m, t)}</span>
                  </li>
                )
              )}
              <li ref={endRef} aria-hidden />
            </ol>
            {sendError && (
              <p className="vr-error" role="alert" data-testid="language-room-send-error">
                {sendError}
              </p>
            )}
            <div className="lr-thread__compose">
              <input
                data-testid="language-room-input"
                value={text}
                maxLength={2000}
                placeholder={t("languageRooms.room.placeholder") || "Write in the room's language…"}
                onChange={(e) => setText(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") send();
                }}
              />
              <button type="button" className="vr-btn vr-btn--primary" data-testid="language-room-send" onClick={send} aria-label={t("languageRooms.room.send") || "Send"}>
                <Send size={16} />
              </button>
            </div>
          </div>
          <aside className="lr-side">
            {room && room.isOwnerOrAdmin && room.roomType === "topic" && <LanguageRoomOwnerPanel roomId={id} />}
            {!(room && room.isOwnerOrAdmin && room.owner === myId) && (
              <button type="button" className="vr-btn vr-btn--ghost" data-testid="language-room-leave" onClick={leave}>
                <LogOut size={14} /> {t("languageRooms.room.leave") || "Leave room"}
              </button>
            )}
          </aside>
        </div>
      )}
    </section>
  );
};

export default LanguageRoomPage;
```

`LanguageRoomOwnerPanel` is created in P4-ROOM-10. So this task compiles on its own, create a placeholder now, `src/components/languageRooms/LanguageRoomOwnerPanel.tsx`:

```tsx
import React from "react";

/** Owner/admin tools for a topic room. Filled in by P4-ROOM-10. */
const LanguageRoomOwnerPanel: React.FC<{ roomId: string }> = () => null;

export default LanguageRoomOwnerPanel;
```

Add to `eng.json` under `"languageRooms"`:

```json
"room": {
  "back": "All rooms",
  "online": "online",
  "pending": "Request sent. The owner will let you in.",
  "request": "Ask to join",
  "join": "Join room",
  "older": "Load earlier messages",
  "placeholder": "Write in the room's language…",
  "send": "Send",
  "leave": "Leave room",
  "slowDown": "You're sending too fast. Slow down a little.",
  "notSent": "Not sent. Try again.",
  "voice": "Voice message — open the app to listen",
  "media": "Photo or video — open the app to see it",
  "sticker": "Sticker",
  "unsupported": "Open the app to see this message"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false roomMessages LanguageRoomPage
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/languageRooms/LanguageRoomPage.tsx src/components/languageRooms/roomMessages.ts src/components/languageRooms/roomMessages.test.ts src/components/languageRooms/LanguageRoomPage.test.tsx src/components/languageRooms/LanguageRoomOwnerPanel.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(language-rooms): room page with history, live messages and sending

Members get the newest 50 messages plus older pages on demand, live
room:message/presence over the socket (re-subscribed after a
reconnect), and send with an ack — a refusal or a timeout keeps the
text and says so, the echo never doubles. Non-members join; banned
members ask to come back.

Still open (Phase 4 rooms): owner tools, City/Genders tabs, routes,
i18n, push.
EOF
```

---

### Task P4-ROOM-10: Language room owner tools: join requests approve/deny, remove member

**Files:**
- Modify: `src/components/languageRooms/LanguageRoomOwnerPanel.tsx` (replace the P4-ROOM-9 placeholder)
- Modify: `src/utils/locales/eng.json` (`languageRooms.owner.*`)
- Test: `src/components/languageRooms/LanguageRoomOwnerPanel.test.tsx` (new)

**Interfaces:**
- Consumes: `useGetLanguageRoomRequestsQuery(id)` (`data[] = {user:{_id,name,username,images}, requestedAt, status}`, owner/admin of a topic room only, `be/controllers/rooms.js:697-711`), `useDecideLanguageRoomRequestMutation()` (`approve` un-bans + adds; `deny` clears the request, `:722-786`), `useGetLanguageRoomMembersQuery(id)` (`data[] = {_id,name,username,imageUrls,role,muted}`, owner first), `useRemoveLanguageRoomMemberMutation()` (bans from a topic room; 400 `CANNOT_KICK_OWNER`), `languageRoomErrorText`.
- Produces: default export `LanguageRoomOwnerPanel` props `{ roomId: string }`; rendered by `LanguageRoomPage` only when `room.isOwnerOrAdmin && room.roomType === "topic"`. Test ids: `lr-owner-panel`, `lr-request-<userId>`, `lr-approve-<userId>`, `lr-deny-<userId>`, `lr-member-<userId>`, `lr-remove-<userId>`, `lr-remove-confirm-<userId>`, `lr-owner-error`. Mute (`POST /members/:userId/mute`) is not offered: the app does not offer it either.

- [ ] **Step 1: Write the failing test**

Create `src/components/languageRooms/LanguageRoomOwnerPanel.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import LanguageRoomOwnerPanel from "./LanguageRoomOwnerPanel";

const mockDecide = jest.fn();
const mockRemove = jest.fn();
let mockRequests: any[] = [];
let mockMembers: any[] = [];
jest.mock("../../store/slices/languageRoomsSlice", () => {
  const actual = jest.requireActual("../../store/slices/languageRoomsSlice");
  return {
    languageRoomErrorText: actual.languageRoomErrorText,
    useGetLanguageRoomRequestsQuery: () => ({ data: { data: mockRequests } }),
    useGetLanguageRoomMembersQuery: () => ({ data: { data: mockMembers } }),
    useDecideLanguageRoomRequestMutation: () => [mockDecide],
    useRemoveLanguageRoomMemberMutation: () => [mockRemove],
  };
});
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

beforeEach(() => {
  mockDecide.mockReset().mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockRemove.mockReset().mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockRequests = [{ user: { _id: "u5", name: "Kim" }, requestedAt: "2026-10-16T10:00:00Z", status: "pending" }];
  mockMembers = [
    { _id: "me", name: "Me", role: "owner", imageUrls: [] },
    { _id: "u2", name: "Ana", role: "member", imageUrls: [] },
  ];
});

it("approves and denies join requests", async () => {
  render(<LanguageRoomOwnerPanel roomId="r1" />);
  expect(screen.getByTestId("lr-request-u5")).toHaveTextContent("Kim");
  fireEvent.click(screen.getByTestId("lr-approve-u5"));
  await waitFor(() => expect(mockDecide).toHaveBeenCalledWith({ roomId: "r1", userId: "u5", approve: true }));
  fireEvent.click(screen.getByTestId("lr-deny-u5"));
  await waitFor(() => expect(mockDecide).toHaveBeenCalledWith({ roomId: "r1", userId: "u5", approve: false }));
});

it("removes a member after a confirmation; never offers it for the owner", async () => {
  render(<LanguageRoomOwnerPanel roomId="r1" />);
  expect(screen.queryByTestId("lr-remove-me")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("lr-remove-u2"));
  expect(mockRemove).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("lr-remove-confirm-u2"));
  await waitFor(() => expect(mockRemove).toHaveBeenCalledWith({ roomId: "r1", userId: "u2" }));
});

it("shows a refusal", async () => {
  mockRemove.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { code: "CANNOT_KICK_OWNER" } }) });
  render(<LanguageRoomOwnerPanel roomId="r1" />);
  fireEvent.click(screen.getByTestId("lr-remove-u2"));
  fireEvent.click(screen.getByTestId("lr-remove-confirm-u2"));
  await waitFor(() => expect(screen.getByTestId("lr-owner-error")).toHaveTextContent("can't be removed"));
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false LanguageRoomOwnerPanel
```
Expected: FAIL — the placeholder renders nothing (`Unable to find … lr-request-u5`).

- [ ] **Step 3: Implement**

Replace `src/components/languageRooms/LanguageRoomOwnerPanel.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Check, X, UserMinus } from "lucide-react";
import {
  useGetLanguageRoomRequestsQuery,
  useGetLanguageRoomMembersQuery,
  useDecideLanguageRoomRequestMutation,
  useRemoveLanguageRoomMemberMutation,
  languageRoomErrorText,
} from "../../store/slices/languageRoomsSlice";

const LanguageRoomOwnerPanel: React.FC<{ roomId: string }> = ({ roomId }) => {
  const { t } = useTranslation();
  const { data: requestsData } = useGetLanguageRoomRequestsQuery(roomId);
  const { data: membersData } = useGetLanguageRoomMembersQuery(roomId);
  const [decide] = useDecideLanguageRoomRequestMutation();
  const [remove] = useRemoveLanguageRoomMemberMutation();
  const [confirming, setConfirming] = useState<string | null>(null);
  const [error, setError] = useState("");

  const requests: any[] = (requestsData && requestsData.data) || [];
  const members: any[] = (membersData && membersData.data) || [];

  const run = async (fn: () => Promise<any>) => {
    setError("");
    try {
      await fn();
    } catch (err) {
      setError(languageRoomErrorText(err, t));
    }
  };

  return (
    <section className="lr-owner" data-testid="lr-owner-panel">
      <h2 className="vr-host__title">{t("languageRooms.owner.requests") || "Join requests"}</h2>
      {requests.length === 0 ? (
        <p className="vr-host__empty">{t("languageRooms.owner.noRequests") || "No one is waiting."}</p>
      ) : (
        <ul className="vr-host__hands">
          {requests.map((r) => {
            const uid = String((r.user && r.user._id) || r.user);
            return (
              <li key={uid} data-testid={`lr-request-${uid}`}>
                <span>{(r.user && r.user.name) || ""}</span>
                <span>
                  <button type="button" className="vr-btn vr-btn--primary" data-testid={`lr-approve-${uid}`} onClick={() => run(() => decide({ roomId, userId: uid, approve: true }).unwrap())} aria-label={t("languageRooms.owner.approve") || "Let in"}>
                    <Check size={14} />
                  </button>{" "}
                  <button type="button" className="vr-btn vr-btn--ghost" data-testid={`lr-deny-${uid}`} onClick={() => run(() => decide({ roomId, userId: uid, approve: false }).unwrap())} aria-label={t("languageRooms.owner.deny") || "Decline"}>
                    <X size={14} />
                  </button>
                </span>
              </li>
            );
          })}
        </ul>
      )}
      <h2 className="vr-host__title">{t("languageRooms.owner.members") || "Members"}</h2>
      <ul className="vr-host__hands">
        {members.map((m) => (
          <li key={m._id} data-testid={`lr-member-${m._id}`}>
            <span>
              {m.name}
              {m.role !== "member" ? ` · ${m.role === "owner" ? t("languageRooms.owner.owner") || "owner" : t("languageRooms.owner.admin") || "admin"}` : ""}
            </span>
            {m.role === "member" &&
              (confirming === m._id ? (
                <span className="vr-host__confirm">
                  <button type="button" className="vr-btn vr-btn--danger" data-testid={`lr-remove-confirm-${m._id}`} onClick={() => run(async () => {
                    await remove({ roomId, userId: m._id }).unwrap();
                    setConfirming(null);
                  })}>
                    {t("languageRooms.owner.removeYes") || "Remove"}
                  </button>
                  <button type="button" className="vr-btn vr-btn--ghost" onClick={() => setConfirming(null)}>
                    {t("common.cancel") || "Cancel"}
                  </button>
                </span>
              ) : (
                <button type="button" className="vr-btn vr-btn--ghost" data-testid={`lr-remove-${m._id}`} onClick={() => setConfirming(m._id)} aria-label={t("languageRooms.owner.remove") || "Remove from room"}>
                  <UserMinus size={14} />
                </button>
              ))}
          </li>
        ))}
      </ul>
      <p className="vr-host__note">{t("languageRooms.owner.removeNote") || "Removed members can ask to come back; you decide."}</p>
      {error && (
        <p className="vr-error" role="alert" data-testid="lr-owner-error">
          {error}
        </p>
      )}
    </section>
  );
};

export default LanguageRoomOwnerPanel;
```

Add to `eng.json` under `"languageRooms"`:

```json
"owner": {
  "requests": "Join requests",
  "noRequests": "No one is waiting.",
  "approve": "Let in",
  "deny": "Decline",
  "members": "Members",
  "owner": "owner",
  "admin": "admin",
  "remove": "Remove from room",
  "removeYes": "Remove",
  "removeNote": "Removed members can ask to come back; you decide."
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false LanguageRoomOwnerPanel LanguageRoomPage
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/languageRooms/LanguageRoomOwnerPanel.tsx src/components/languageRooms/LanguageRoomOwnerPanel.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(language-rooms): owner tools — join requests and removing members

Owners and admins of a topic room let people in or decline them, and
remove a member after a confirmation (the owner can't be removed).
Same endpoints as the app.

Still open (Phase 4 rooms): City/Genders tabs, routes, i18n, push.
EOF
```

---

### Task P4-ROOM-11: Community City and Genders tabs (community#7), same queries as the app

**Files:**
- Create: `src/components/community/cityGenders/countryPins.ts`, `src/components/community/cityGenders/useMemberPages.ts`, `src/components/community/cityGenders/CityPage.tsx`, `src/components/community/cityGenders/GendersPage.tsx`, `src/components/community/cityGenders/cityGenders.scss`
- Modify: `src/components/community/tandem/CommunitySubNav.tsx` (two flagged links after the Topics link, `:198-206` on `origin/main`)
- Modify: `src/utils/locales/eng.json` (`community.cityTab.*`, `community.gendersTab.*`, `communityMain.subnav.city`, `communityMain.subnav.genders`)
- Test: `src/components/community/cityGenders/CityPage.test.tsx`, `src/components/community/cityGenders/GendersPage.test.tsx`, `src/components/community/cityGenders/subnavLinks.test.tsx` (new); possibly one mock line in existing community suites (Step 5)

**Interfaces:**
- Consumes: `useGetCommunityMembersQuery(arg)` (`src/store/slices/communitySlice.ts`, `GET /api/v1/auth/users`, any non-empty key becomes a param) and `useGetCommunityCountQuery(params)` (`GET /api/v1/auth/users/count` → `{data:{count}}`, `be/controllers/users.js:579-583`). The app's requests (`bananatalk_app/lib/pages/community/tabs/city_tab.dart:415-445`, `genders_tab.dart:105-215`): City = `country=<English name>` **or** `search=<typed city>`, page/limit 20, plus the viewer's languages; Genders = `gender=male|female` (default `female`), page/limit 20, plus — when the viewer set no language filter — `nativeLanguage=<my native>`, `learningLanguage=<my learning>`, `matchLanguage=true`; counts are two `limit:1` calls per gender (the web uses the count endpoint instead: same filter, one number). Backend: `country` matches every spelling of the country via `toIso2` (`users.js:318-330`, only among people who show their country); `gender` maps variants (`:271-278`). `MemberCard` (`onWave`, `onOpen`), `WaveSheet` (`open`, `targetUser {_id,name,imageUrls}`, `onClose`, `onWaved`), `useWebFlag` (P4-0).
- Produces: routes `/community/city` and `/community/genders` (wired in P4-ROOM-12 behind `webLanguageRoomsEnabled`); `COUNTRY_PINS: Array<{ name: string; flag: string }>` (the app's 30 pins, same order and English names); `useMemberPages(params)` → `{ members, isLoading, isError, hasMore, loadMore(), refetch() }` (pages of 20, resets when `params` change, de-duplicates by `_id`); `languageMatchParams(me)` → `{ nativeLanguage, learningLanguage, matchLanguage: "true" }` or `{}`. Subnav links `data-testid="subnav-city"` / `"subnav-genders"`, only while the flag is on. Test ids: `city-page`, `city-country-<name>`, `city-search`, `city-search-go`, `city-results`, `city-empty`, `genders-page`, `genders-female`, `genders-male`, `genders-count-female`, `genders-count-male`, `genders-results`, `member-pages-more`.
- Known gap carried from the app: the city search sends `search`, which the backend matches against name/username/bio/languages, **not** `location.city` — a city name only finds people who wrote it in their bio. Logged as a backend follow-up; the web copies the app's request so both behave the same.

- [ ] **Step 1: Write the failing tests**

Create `src/components/community/cityGenders/CityPage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import CityPage from "./CityPage";
import { COUNTRY_PINS } from "./countryPins";

const mockArgs: any[] = [];
let mockResult: any = { data: { data: [] }, isLoading: false, isError: false, isFetching: false };
jest.mock("../../../store/slices/communitySlice", () => ({
  useGetCommunityMembersQuery: (arg: any, opts: any) => {
    mockArgs.push({ arg, opts });
    return opts && opts.skip ? { data: undefined, isLoading: false } : mockResult;
  },
}));
jest.mock("../MemberCard", () => (p: any) => <div data-testid={`member-${p.user._id}`}>{p.user.name}</div>);
jest.mock("../WaveSheet", () => () => null);
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderPage() {
  const store = configureStore({
    reducer: { auth: (s: any = { userInfo: { user: { _id: "me", native_language: "English", language_to_learn: "Korean" } } }) => s },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <CityPage />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockArgs.length = 0;
  mockResult = { data: { data: [] }, isLoading: false, isError: false, isFetching: false };
});

it("offers the app's 30 countries, in its order", () => {
  expect(COUNTRY_PINS).toHaveLength(30);
  expect(COUNTRY_PINS[0]).toEqual({ name: "South Korea", flag: "🇰🇷", iso: "KR" });
  expect(COUNTRY_PINS[29].name).toBe("Bangladesh");
  expect(COUNTRY_PINS.map((p) => p.name)).toContain("Uzbekistan");
  renderPage();
  expect(screen.getByTestId("city-country-South Korea")).toHaveTextContent("South Korea");
});

it("asks for nothing until a country or a city is chosen", () => {
  renderPage();
  expect(mockArgs.every((c) => c.opts && c.opts.skip)).toBe(true);
});

it("a country asks /auth/users with its English name and my languages", () => {
  mockResult = { data: { data: [{ _id: "u1", name: "Jisoo" }] }, isLoading: false, isError: false, isFetching: false };
  renderPage();
  fireEvent.click(screen.getByTestId("city-country-Japan"));
  const last = mockArgs[mockArgs.length - 1];
  expect(last.opts.skip).toBe(false);
  expect(last.arg).toEqual({
    page: 1,
    limit: 20,
    country: "Japan",
    nativeLanguage: "English",
    learningLanguage: "Korean",
    matchLanguage: "true",
  });
  expect(screen.getByTestId("member-u1")).toBeInTheDocument();
});

it("a typed city replaces the country and is sent as search, like the app", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("city-country-Japan"));
  fireEvent.change(screen.getByTestId("city-search"), { target: { value: " Busan " } });
  fireEvent.click(screen.getByTestId("city-search-go"));
  const last = mockArgs[mockArgs.length - 1].arg;
  expect(last.search).toBe("Busan");
  expect(last.country).toBeUndefined();
});

it("says so when no one is there", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("city-country-Nigeria"));
  expect(screen.getByTestId("city-empty")).toBeInTheDocument();
});
```

Create `src/components/community/cityGenders/GendersPage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import GendersPage from "./GendersPage";

const mockArgs: any[] = [];
const mockCountArgs: any[] = [];
jest.mock("../../../store/slices/communitySlice", () => ({
  useGetCommunityMembersQuery: (arg: any) => {
    mockArgs.push(arg);
    return { data: { data: [{ _id: `u-${arg.gender}`, name: arg.gender }] }, isLoading: false, isError: false, isFetching: false };
  },
  useGetCommunityCountQuery: (params: any) => {
    mockCountArgs.push(params);
    return { data: { data: { count: params.gender === "male" ? 120 : 340 } } };
  },
}));
jest.mock("../MemberCard", () => (p: any) => <div data-testid={`member-${p.user._id}`}>{p.user.name}</div>);
jest.mock("../WaveSheet", () => () => null);
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderPage(user: any = { _id: "me", native_language: "English", language_to_learn: "Korean" }) {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <GendersPage />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockArgs.length = 0;
  mockCountArgs.length = 0;
});

it("starts on women, like the app, with my languages matched", () => {
  renderPage();
  expect(mockArgs[mockArgs.length - 1]).toEqual({
    page: 1,
    limit: 20,
    gender: "female",
    nativeLanguage: "English",
    learningLanguage: "Korean",
    matchLanguage: "true",
  });
  expect(screen.getByTestId("member-u-female")).toBeInTheDocument();
});

it("shows both counts from the count endpoint with the same filter", () => {
  renderPage();
  expect(screen.getByTestId("genders-count-female")).toHaveTextContent("340");
  expect(screen.getByTestId("genders-count-male")).toHaveTextContent("120");
  expect(mockCountArgs).toContainEqual({ gender: "male", nativeLanguage: "English", learningLanguage: "Korean", matchLanguage: "true" });
});

it("switches to men", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("genders-male"));
  expect(mockArgs[mockArgs.length - 1].gender).toBe("male");
  expect(screen.getByTestId("member-u-male")).toBeInTheDocument();
});

it("without languages on my profile, asks by gender alone", () => {
  renderPage({ _id: "me" });
  expect(mockArgs[mockArgs.length - 1]).toEqual({ page: 1, limit: 20, gender: "female" });
});
```

Create `src/components/community/cityGenders/subnavLinks.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { mockAppConfig } from "../../../utils/testing/mockWebFlags";
import CommunitySubNav from "../tandem/CommunitySubNav";

jest.mock("../../../store/slices/appConfigSlice", () => require("../../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const nav = () =>
  render(
    <MemoryRouter>
      <CommunitySubNav activeTab="all" onTabChange={jest.fn()} searchValue="" onSearchChange={jest.fn()} onOpenFilters={jest.fn()} />
    </MemoryRouter>
  );

it("links City and Genders while the language-rooms flag is on", () => {
  mockAppConfig({ webLanguageRoomsEnabled: true, roomsEnabled: true });
  nav();
  expect(screen.getByTestId("subnav-city")).toHaveAttribute("href", "/community/city");
  expect(screen.getByTestId("subnav-genders")).toHaveAttribute("href", "/community/genders");
});

it.each([[{ webLanguageRoomsEnabled: false, roomsEnabled: true }], [{ webLanguageRoomsEnabled: true, roomsEnabled: false }], ["loading"], ["error"]])(
  "hides them for %j",
  (cfg: any) => {
    mockAppConfig(cfg);
    nav();
    expect(screen.queryByTestId("subnav-city")).not.toBeInTheDocument();
    expect(screen.queryByTestId("subnav-genders")).not.toBeInTheDocument();
  }
);
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false cityGenders
```
Expected: FAIL — `Cannot find module './CityPage'`, `'./GendersPage'`, `'./countryPins'`; the subnav test finds no `subnav-city`.

- [ ] **Step 3: Implement**

Create `src/components/community/cityGenders/countryPins.ts`:

```ts
/**
 * The City tab's countries: the app's 30 pins, same order, same English
 * names (bananatalk_app/lib/pages/community/tabs/city_tab.dart _countryPins).
 * The backend matches `country` by every spelling of the country (toIso2),
 * so the English name is the right thing to send in every locale; the label
 * shown is localized with Intl.DisplayNames where the browser has it.
 */
export const COUNTRY_PINS: Array<{ name: string; flag: string; iso: string }> = [
  { name: "South Korea", flag: "🇰🇷", iso: "KR" },
  { name: "Japan", flag: "🇯🇵", iso: "JP" },
  { name: "United States", flag: "🇺🇸", iso: "US" },
  { name: "China", flag: "🇨🇳", iso: "CN" },
  { name: "United Kingdom", flag: "🇬🇧", iso: "GB" },
  { name: "Germany", flag: "🇩🇪", iso: "DE" },
  { name: "France", flag: "🇫🇷", iso: "FR" },
  { name: "Spain", flag: "🇪🇸", iso: "ES" },
  { name: "Brazil", flag: "🇧🇷", iso: "BR" },
  { name: "India", flag: "🇮🇳", iso: "IN" },
  { name: "Russia", flag: "🇷🇺", iso: "RU" },
  { name: "Turkey", flag: "🇹🇷", iso: "TR" },
  { name: "Indonesia", flag: "🇮🇩", iso: "ID" },
  { name: "Thailand", flag: "🇹🇭", iso: "TH" },
  { name: "Vietnam", flag: "🇻🇳", iso: "VN" },
  { name: "Philippines", flag: "🇵🇭", iso: "PH" },
  { name: "Mexico", flag: "🇲🇽", iso: "MX" },
  { name: "Italy", flag: "🇮🇹", iso: "IT" },
  { name: "Canada", flag: "🇨🇦", iso: "CA" },
  { name: "Australia", flag: "🇦🇺", iso: "AU" },
  { name: "Uzbekistan", flag: "🇺🇿", iso: "UZ" },
  { name: "Taiwan", flag: "🇹🇼", iso: "TW" },
  { name: "Malaysia", flag: "🇲🇾", iso: "MY" },
  { name: "Saudi Arabia", flag: "🇸🇦", iso: "SA" },
  { name: "Egypt", flag: "🇪🇬", iso: "EG" },
  { name: "Argentina", flag: "🇦🇷", iso: "AR" },
  { name: "Colombia", flag: "🇨🇴", iso: "CO" },
  { name: "Nigeria", flag: "🇳🇬", iso: "NG" },
  { name: "Pakistan", flag: "🇵🇰", iso: "PK" },
  { name: "Bangladesh", flag: "🇧🇩", iso: "BD" },
];

export function countryLabel(pin: { name: string; iso: string }, language: string): string {
  try {
    const DN = (Intl as any).DisplayNames;
    if (DN) return new DN([language], { type: "region" }).of(pin.iso) || pin.name;
  } catch (e) {
    // Old browsers / unknown locale: the English name is still correct.
  }
  return pin.name;
}
```

Create `src/components/community/cityGenders/useMemberPages.ts`:

```ts
import { useEffect, useMemo, useState } from "react";
import { useGetCommunityMembersQuery } from "../../../store/slices/communitySlice";

export function languageMatchParams(me: any): { [k: string]: string } {
  if (me && me.native_language && me.language_to_learn) {
    return { nativeLanguage: String(me.native_language), learningLanguage: String(me.language_to_learn), matchLanguage: "true" };
  }
  return {};
}

/** Pages of 20 from GET /auth/users for one fixed filter; resets when it changes. */
export function useMemberPages(params: { [k: string]: string | undefined } | null) {
  const key = JSON.stringify(params || null);
  const [page, setPage] = useState(1);
  const [members, setMembers] = useState<any[]>([]);
  useEffect(() => {
    setPage(1);
    setMembers([]);
  }, [key]);
  const arg = useMemo(() => (params ? Object.assign({ page, limit: 20 }, params) : { page: 1, limit: 20 }), [key, page]); // eslint-disable-line react-hooks/exhaustive-deps
  const { data, isLoading, isError, isFetching, refetch } = useGetCommunityMembersQuery(arg, { skip: !params });
  const rows: any[] = (data && Array.isArray(data.data) ? data.data : []) as any[];
  useEffect(() => {
    if (!params) return;
    setMembers((prev) => {
      const seen: { [id: string]: boolean } = {};
      const out: any[] = [];
      (page === 1 ? [] : prev).concat(rows).forEach((m: any) => {
        if (m && m._id && !seen[m._id]) {
          seen[m._id] = true;
          out.push(m);
        }
      });
      return out;
    });
  }, [data]); // eslint-disable-line react-hooks/exhaustive-deps
  return {
    members: params ? (members.length || page > 1 ? members : rows) : [],
    isLoading: !!params && !!isLoading,
    isError: !!params && !!isError,
    hasMore: !!params && rows.length === 20 && !isFetching,
    loadMore: () => setPage((p) => p + 1),
    refetch,
  };
}
```

Create `src/components/community/cityGenders/CityPage.tsx`:

```tsx
import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Search } from "lucide-react";
import MemberCard, { CommunityMemberCard } from "../MemberCard";
import WaveSheet from "../WaveSheet";
import { COUNTRY_PINS, countryLabel } from "./countryPins";
import { useMemberPages, languageMatchParams } from "./useMemberPages";
import "./cityGenders.scss";

const CityPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user);
  const [country, setCountry] = useState<string | null>(null);
  const [cityInput, setCityInput] = useState("");
  const [city, setCity] = useState("");
  const [waveTarget, setWaveTarget] = useState<CommunityMemberCard | null>(null);

  const params = country
    ? Object.assign({ country }, languageMatchParams(me))
    : city
    ? Object.assign({ search: city }, languageMatchParams(me))
    : null;
  const { members, isLoading, isError, hasMore, loadMore } = useMemberPages(params);
  const searchCity = () => {
    const value = cityInput.trim();
    if (!value) return;
    setCountry(null);
    setCity(value);
  };

  return (
    <section className="cg-page" data-testid="city-page">
      <header className="cg-head">
        <Link to="/communities" className="vr-link">
          {t("community.cityTab.back") || "Community"}
        </Link>
        <h1>{t("community.cityTab.title") || "People by place"}</h1>
      </header>
      <div className="cg-search">
        <Search size={16} aria-hidden />
        <input
          data-testid="city-search"
          value={cityInput}
          placeholder={t("community.cityTab.searchPlaceholder") || "Search a city"}
          onChange={(e) => setCityInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") searchCity();
          }}
        />
        <button type="button" className="vr-btn vr-btn--primary" data-testid="city-search-go" onClick={searchCity}>
          {t("community.cityTab.search") || "Search"}
        </button>
      </div>
      <ul className="cg-chips" aria-label={t("community.cityTab.countries") || "Countries"}>
        {COUNTRY_PINS.map((pin) => (
          <li key={pin.name}>
            <button
              type="button"
              data-testid={`city-country-${pin.name}`}
              className={country === pin.name ? "cg-chip is-active" : "cg-chip"}
              aria-pressed={country === pin.name}
              onClick={() => {
                setCity("");
                setCountry(pin.name);
              }}
            >
              <span aria-hidden>{pin.flag}</span> {countryLabel(pin, i18n.language)}
            </button>
          </li>
        ))}
      </ul>
      {params && (
        <>
          <h2 className="cg-results-title">
            {country
              ? countryLabel(COUNTRY_PINS.filter((p) => p.name === country)[0], i18n.language)
              : (t("community.cityTab.searchTitle", { query: city }) as string) || `People in “${city}”`}
          </h2>
          {isError && <p className="vr-error">{t("community.cityTab.error") || "Couldn't load people. Try again."}</p>}
          {!isLoading && !isError && members.length === 0 && (
            <p className="vr-empty" data-testid="city-empty">
              {t("community.cityTab.empty") || "No one here matches yet. Try another place."}
            </p>
          )}
          <div className="cg-grid" data-testid="city-results">
            {members.map((m: any) => (
              <MemberCard key={m._id} user={m} onWave={(u) => setWaveTarget(u)} onOpen={(u) => navigate(`/community/${u._id}`)} />
            ))}
          </div>
          {hasMore && (
            <button type="button" className="vr-btn vr-btn--ghost cg-more" data-testid="member-pages-more" onClick={loadMore}>
              {t("community.cityTab.more") || "Show more"}
            </button>
          )}
        </>
      )}
      <WaveSheet
        open={!!waveTarget}
        targetUser={waveTarget ? { _id: waveTarget._id, name: waveTarget.name, imageUrls: waveTarget.imageUrls } : null}
        onClose={() => setWaveTarget(null)}
      />
    </section>
  );
};

export default CityPage;
```

(If `WaveTargetUser` on `origin/main` names its id field differently, adapt the one object literal — `grep -n "interface WaveTargetUser" -A4 src/components/community/WaveSheet.tsx`.)

Create `src/components/community/cityGenders/GendersPage.tsx`:

```tsx
import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import MemberCard, { CommunityMemberCard } from "../MemberCard";
import WaveSheet from "../WaveSheet";
import { useGetCommunityCountQuery } from "../../../store/slices/communitySlice";
import { useMemberPages, languageMatchParams } from "./useMemberPages";
import "./cityGenders.scss";

type Gender = "female" | "male";

const GendersPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user);
  const [gender, setGender] = useState<Gender>("female");
  const [waveTarget, setWaveTarget] = useState<CommunityMemberCard | null>(null);
  const lang = languageMatchParams(me);
  const { members, isLoading, isError, hasMore, loadMore } = useMemberPages(Object.assign({ gender }, lang));
  const female = useGetCommunityCountQuery(Object.assign({ gender: "female" }, lang));
  const male = useGetCommunityCountQuery(Object.assign({ gender: "male" }, lang));
  const count = (q: any) => (q && q.data && q.data.data && typeof q.data.data.count === "number" ? q.data.data.count : null);

  const tab = (g: Gender, label: string, q: any) => (
    <button
      type="button"
      role="tab"
      aria-selected={gender === g}
      data-testid={`genders-${g}`}
      className={gender === g ? "cg-chip is-active" : "cg-chip"}
      onClick={() => setGender(g)}
    >
      {label} <span data-testid={`genders-count-${g}`}>{count(q) === null ? "" : count(q)}</span>
    </button>
  );

  return (
    <section className="cg-page" data-testid="genders-page">
      <header className="cg-head">
        <Link to="/communities" className="vr-link">
          {t("community.gendersTab.back") || "Community"}
        </Link>
        <h1>{t("community.gendersTab.title") || "Browse by gender"}</h1>
      </header>
      <div className="cg-chips" role="tablist">
        {tab("female", t("community.gendersTab.female") || "Women", female)}
        {tab("male", t("community.gendersTab.male") || "Men", male)}
      </div>
      {isError && <p className="vr-error">{t("community.gendersTab.error") || "Couldn't load people. Try again."}</p>}
      {!isLoading && !isError && members.length === 0 && <p className="vr-empty">{t("community.gendersTab.empty") || "No one matches yet."}</p>}
      <div className="cg-grid" data-testid="genders-results">
        {members.map((m: any) => (
          <MemberCard key={m._id} user={m} onWave={(u) => setWaveTarget(u)} onOpen={(u) => navigate(`/community/${u._id}`)} />
        ))}
      </div>
      {hasMore && (
        <button type="button" className="vr-btn vr-btn--ghost cg-more" data-testid="member-pages-more" onClick={loadMore}>
          {t("community.gendersTab.more") || "Show more"}
        </button>
      )}
      <WaveSheet
        open={!!waveTarget}
        targetUser={waveTarget ? { _id: waveTarget._id, name: waveTarget.name, imageUrls: waveTarget.imageUrls } : null}
        onClose={() => setWaveTarget(null)}
      />
    </section>
  );
};

export default GendersPage;
```

Create `src/components/community/cityGenders/cityGenders.scss`:

```scss
@import "../../voiceRooms/VoiceRooms.scss";
.cg-page { max-width: 1100px; margin-inline: auto; padding-block: 24px; padding-inline: 16px; }
.cg-head { display: flex; align-items: center; gap: 12px; margin-block-end: 12px; }
.cg-head h1 { font-size: 1.4rem; font-weight: 800; margin: 0; }
.cg-search { display: flex; align-items: center; gap: 8px; margin-block-end: 12px; }
.cg-search input { flex: 1; border: 1px solid var(--bs-border-color, #ddd); border-radius: 999px; padding-block: 8px; padding-inline: 14px; }
.cg-chips { list-style: none; padding: 0; margin: 0 0 16px; display: flex; flex-wrap: wrap; gap: 6px; }
.cg-chip { border: 1px solid var(--bs-border-color, #ddd); background: transparent; border-radius: 999px; padding-block: 6px; padding-inline: 12px; font-weight: 700; font-size: 0.85rem; }
.cg-chip.is-active { background: #ffd600; border-color: #ffd600; }
.cg-results-title { font-size: 1.05rem; font-weight: 800; margin-block: 8px; }
.cg-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 12px; }
.cg-more { margin-block-start: 16px; margin-inline: auto; display: flex; }
```

In `src/components/community/tandem/CommunitySubNav.tsx`:
- imports: add `Building2, Users` to the `lucide-react` import list and `import { useWebFlag } from "../../../utils/webFlags";`
- in the component body after `const activeRef = …;` add `const cityGendersOn = useWebFlag("webLanguageRoomsEnabled");`
- right after the Topics `<Link …>…</Link>` add

```tsx
          {cityGendersOn && (
            <>
              <Link
                to="/community/city"
                data-testid="subnav-city"
                className="community-subnav__btn community-subnav__btn--icon shrink-0 no-underline"
              >
                <span className="community-subnav__icon">
                  <Building2 size={14} />
                </span>
                <span>{t("communityMain.subnav.city") || "City"}</span>
              </Link>
              <Link
                to="/community/genders"
                data-testid="subnav-genders"
                className="community-subnav__btn community-subnav__btn--icon shrink-0 no-underline"
              >
                <span className="community-subnav__icon">
                  <Users size={14} />
                </span>
                <span>{t("communityMain.subnav.genders") || "Genders"}</span>
              </Link>
            </>
          )}
```
(They are links, not tabs, for the reason the file's header gives for Nearby and Topics: separate pages.)

Add to `eng.json`: under `communityMain.subnav` `"city": "City"`, `"genders": "Genders"`; and under `community`:

```json
"cityTab": {
  "back": "Community",
  "title": "People by place",
  "searchPlaceholder": "Search a city",
  "search": "Search",
  "countries": "Countries",
  "searchTitle": "People in “{{query}}”",
  "error": "Couldn't load people. Try again.",
  "empty": "No one here matches yet. Try another place.",
  "more": "Show more"
},
"gendersTab": {
  "back": "Community",
  "title": "Browse by gender",
  "female": "Women",
  "male": "Men",
  "error": "Couldn't load people. Try again.",
  "empty": "No one matches yet.",
  "more": "Show more"
}
```
(If `eng.json` has no `community` object yet — P3-COM-13 added `community.nearby.*`/`community.waves.*` — create it.)

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false cityGenders
```
Expected: all pass.

- [ ] **Step 5: Existing community suites still pass**

```bash
CI=true npm test -- --watchAll=false src/components/community
```
`CommunitySubNav` now calls `useWebFlag`, which issues `GET /app-config` through the real store in suites that render `MainCommunity` with a mocked `fetch`. If a suite fails because it asserts the exact list of requested URLs or answers every fetch with a list payload, add to that test file (only those that fail):

```ts
jest.mock("../../utils/webFlags", () => ({ useWebFlag: () => false, useWebFlagState: () => ({ on: false, ready: true }) }));
```
(path relative to the test file). Do not change assertions. Expected afterwards: all community suites green.

- [ ] **Step 6: Commit**

```bash
git add src/components/community/cityGenders src/components/community/tandem/CommunitySubNav.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git add -u src/components/community   # only test files touched in Step 5 (review with git diff --cached --stat)
git commit -F - <<'EOF'
feat(community): City and Genders pages, the app's two missing tabs

City: the app's 30 countries (English names, labels localized) or a
typed city sent as search, exactly like the app; Genders: women/men
with counts from the count endpoint and the member's languages
matched. Linked from the community sub-nav only while
webLanguageRoomsEnabled is on (community#7).

Still open (Phase 4 rooms): routes + nav, i18n, push. Backend: city
search ignores location.city (same in the app).
EOF
```

---

### Task P4-ROOM-12: Routes and nav entries behind `webVoiceRoomsEnabled` / `webLanguageRoomsEnabled`; flag-off test

**Files:**
- Modify: `src/router/routes.tsx` (a commented "Phase 4 — rooms" lazy block after the Community lazy imports, and six `<Route>`s after the `{/* Community */}` group)
- Modify: `src/components/navbar/MainNavbar.tsx` (desktop links after the Moments `NavLink`, `:240-246` on `origin/main`; mobile links after the mobile Moments link, `:404-406`)
- Modify: `src/utils/locales/eng.json` (`nav.voiceRooms`, `nav.languageRooms`)
- Test: `src/router/roomsRoutes.test.tsx` (new, node env like `routes.test.tsx`), `src/components/navbar/roomsNav.test.tsx` (new)

**Interfaces:**
- Consumes: `FlagRoute` + `useWebFlag` (P4-0); the six pages from P4-ROOM-4/6/8/9/11.
- Produces: routes `/voice-rooms` → `VoiceRoomsPage`, `/voice-rooms/:id` → `VoiceRoomPage` (flag `webVoiceRoomsEnabled`); `/rooms` → `LanguageRoomsPage`, `/rooms/:id` → `LanguageRoomPage`, `/community/city` → `CityPage`, `/community/genders` → `GendersPage` (flag `webLanguageRoomsEnabled`, which also needs `roomsEnabled`). Each element is `lazyRoute(<FlagRoute flag="…"><Page /></FlagRoute>)`. `/community/city` and `/community/genders` are static segments, so react-router ranks them above `community/:userId` (same rule the file already relies on for `community/nearby`). Navbar test ids: `nav-voice-rooms`, `nav-language-rooms`, `nav-voice-rooms-mobile`, `nav-language-rooms-mobile` — signed-in members only, each only while its flag is on.

- [ ] **Step 1: Write the failing tests**

Create `src/router/roomsRoutes.test.tsx`:

```tsx
/**
 * @jest-environment node
 */
import { matchRoutes } from "react-router-dom";

const FLAGGED: Array<[string, string]> = [
  ["/voice-rooms", "webVoiceRoomsEnabled"],
  ["/voice-rooms/r1", "webVoiceRoomsEnabled"],
  ["/rooms", "webLanguageRoomsEnabled"],
  ["/rooms/r1", "webLanguageRoomsEnabled"],
  ["/community/city", "webLanguageRoomsEnabled"],
  ["/community/genders", "webLanguageRoomsEnabled"],
];

it.each(FLAGGED)("%s is a real route gated by %s", (path, flag) => {
  const { routes } = require("./routes");
  const FlagRoute = require("./FlagRoute").default;
  const matches = matchRoutes(routes, path);
  expect(matches && matches.length).toBe(2);
  const route: any = matches![1].route;
  expect(route.path).not.toBe("*");
  const gate = route.element.props.children; // <Suspense><FlagRoute …><Page/></FlagRoute></Suspense>
  expect(gate.type).toBe(FlagRoute);
  expect(gate.props.flag).toBe(flag);
});

it("City and Genders win over /community/:userId", () => {
  const { routes } = require("./routes");
  expect(matchRoutes(routes, "/community/city")![1].route.path).toBe("community/city");
  expect(matchRoutes(routes, "/community/abc123")![1].route.path).toBe("community/:userId");
});

it("still imports without a DOM", () => {
  expect(typeof window).toBe("undefined");
});
```

Create `src/components/navbar/roomsNav.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import { apiSlice } from "../../store/slices/apiSlice";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";
import MainNavbar from "./MainNavbar";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en", changeLanguage: jest.fn() } }),
}));
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: { on: jest.fn(), off: jest.fn(), emit: jest.fn() }, isConnected: true, emit: jest.fn() }),
}));

function renderNavbar(user: any = { _id: "me", name: "Me" }) {
  (global as any).fetch = jest.fn(async () => new Response(JSON.stringify({ data: [] }), { status: 200, headers: { "Content-Type": "application/json" } }));
  const store = configureStore({
    reducer: { [apiSlice.reducerPath]: apiSlice.reducer, auth: (s: any = { userInfo: user ? { user } : null }) => s },
    middleware: (g) => g().concat(apiSlice.middleware),
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <MainNavbar />
      </MemoryRouter>
    </Provider>
  );
}

const IDS = ["nav-voice-rooms", "nav-language-rooms", "nav-voice-rooms-mobile", "nav-language-rooms-mobile"];

it("shows no rooms entry while the flags are off", () => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderNavbar();
  IDS.forEach((id) => expect(screen.queryByTestId(id)).not.toBeInTheDocument());
});

it("shows no rooms entry while app-config is loading or failed", () => {
  mockAppConfig("loading");
  const a = renderNavbar();
  IDS.forEach((id) => expect(screen.queryByTestId(id)).not.toBeInTheDocument());
  a.unmount();
  mockAppConfig("error");
  renderNavbar();
  IDS.forEach((id) => expect(screen.queryByTestId(id)).not.toBeInTheDocument());
});

it("shows each entry with its own flag", () => {
  mockAppConfig(Object.assign({}, ALL_WEB_FLAGS_OFF, { webVoiceRoomsEnabled: true }));
  const a = renderNavbar();
  expect(screen.getByTestId("nav-voice-rooms")).toHaveAttribute("href", "/voice-rooms");
  expect(screen.queryByTestId("nav-language-rooms")).not.toBeInTheDocument();
  a.unmount();
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderNavbar();
  expect(screen.getByTestId("nav-language-rooms")).toHaveAttribute("href", "/rooms");
  expect(screen.getByTestId("nav-voice-rooms-mobile")).toBeInTheDocument();
  expect(screen.getByTestId("nav-language-rooms-mobile")).toBeInTheDocument();
});

it("never shows them to a signed-out visitor", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderNavbar(null);
  IDS.forEach((id) => expect(screen.queryByTestId(id)).not.toBeInTheDocument());
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false roomsRoutes roomsNav
```
Expected: FAIL — `/voice-rooms` matches the catch-all; no `nav-voice-rooms`.

- [ ] **Step 3: Implement**

In `src/router/routes.tsx`:
- next to the other eager imports add `import FlagRoute from "./FlagRoute";` (if P4-0 or an earlier Phase 4 push already added it, keep one)
- after the `// Community, authenticated.` lazy block add

```tsx
// Phase 4 — rooms (dark until webVoiceRoomsEnabled / webLanguageRoomsEnabled).
// Every element is wrapped in FlagRoute, so with the flag off these paths are
// the 404 page. Voice rooms pull in LiveKit only after Join (lib/livekit).
const VoiceRoomsPage = lazyWithRetry("../components/voiceRooms/VoiceRoomsPage", () => import("../components/voiceRooms/VoiceRoomsPage"));
const VoiceRoomPage = lazyWithRetry("../components/voiceRooms/VoiceRoomPage", () => import("../components/voiceRooms/VoiceRoomPage"));
const LanguageRoomsPage = lazyWithRetry("../components/languageRooms/LanguageRoomsPage", () => import("../components/languageRooms/LanguageRoomsPage"));
const LanguageRoomPage = lazyWithRetry("../components/languageRooms/LanguageRoomPage", () => import("../components/languageRooms/LanguageRoomPage"));
const CityPage = lazyWithRetry("../components/community/cityGenders/CityPage", () => import("../components/community/cityGenders/CityPage"));
const GendersPage = lazyWithRetry("../components/community/cityGenders/GendersPage", () => import("../components/community/cityGenders/GendersPage"));
```
- after `<Route path="topics" element={lazyRoute(<Topics />)} />` add

```tsx
    {/* Phase 4 — rooms. Dark until their flags are on (FlagRoute → 404). */}
    <Route path="voice-rooms" element={lazyRoute(<FlagRoute flag="webVoiceRoomsEnabled"><VoiceRoomsPage /></FlagRoute>)} />
    <Route path="voice-rooms/:id" element={lazyRoute(<FlagRoute flag="webVoiceRoomsEnabled"><VoiceRoomPage /></FlagRoute>)} />
    <Route path="rooms" element={lazyRoute(<FlagRoute flag="webLanguageRoomsEnabled"><LanguageRoomsPage /></FlagRoute>)} />
    <Route path="rooms/:id" element={lazyRoute(<FlagRoute flag="webLanguageRoomsEnabled"><LanguageRoomPage /></FlagRoute>)} />
    <Route path="community/city" element={lazyRoute(<FlagRoute flag="webLanguageRoomsEnabled"><CityPage /></FlagRoute>)} />
    <Route path="community/genders" element={lazyRoute(<FlagRoute flag="webLanguageRoomsEnabled"><GendersPage /></FlagRoute>)} />
```

In `src/components/navbar/MainNavbar.tsx`:
- add `FaMicrophone, FaDoorOpen` to the `react-icons/fa` import and `import { useWebFlag } from "../../utils/webFlags";`
- in the component body after `const isAdmin = useSelector(selectIsAdmin);` add

```tsx
  // Phase 4 rooms: dark until the owner turns the flags on.
  const voiceRoomsOn = useWebFlag("webVoiceRoomsEnabled");
  const languageRoomsOn = useWebFlag("webLanguageRoomsEnabled");
```
- desktop, right after the Moments `</NavLink>` inside `{userInfo && (<>…</>)}`:

```tsx
                {voiceRoomsOn && (
                  <NavLink
                    to="/voice-rooms"
                    data-testid="nav-voice-rooms"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaMicrophone />
                    <span>{t("nav.voiceRooms") || "Voice rooms"}</span>
                  </NavLink>
                )}
                {languageRoomsOn && (
                  <NavLink
                    to="/rooms"
                    data-testid="nav-language-rooms"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaDoorOpen />
                    <span>{t("nav.languageRooms") || "Language rooms"}</span>
                  </NavLink>
                )}
```
- mobile, right after the mobile Moments `</NavLink>`:

```tsx
                  {voiceRoomsOn && (
                    <NavLink to="/voice-rooms" className="mobile-nav-link" data-testid="nav-voice-rooms-mobile" onClick={closeMobileMenu}>
                      <FaMicrophone /> {t("nav.voiceRooms") || "Voice rooms"}
                    </NavLink>
                  )}
                  {languageRoomsOn && (
                    <NavLink to="/rooms" className="mobile-nav-link" data-testid="nav-language-rooms-mobile" onClick={closeMobileMenu}>
                      <FaDoorOpen /> {t("nav.languageRooms") || "Language rooms"}
                    </NavLink>
                  )}
```
(If the REELS or GATHERINGS push already added entries in the same spots, put these after theirs.)

Add to `eng.json` under `"nav"` (create it if absent): `"voiceRooms": "Voice rooms"`, `"languageRooms": "Language rooms"`.

- [ ] **Step 4: Run → PASS, plus the neighbours**

```bash
CI=true npm test -- --watchAll=false roomsRoutes roomsNav routes.test MainNavbar FlagRoute eagerGraph
```
Expected: all pass. `MainNavbar.test.tsx` keeps passing: its fetch mock answers `/app-config` with `{data: [...]}`, which the flag module reads as "no flags" (off). `routes.test.tsx`'s `routes[0].children.length > 30` still holds. `eagerGraph` stays green: the new pages are behind `lazyWithRetry`; `FlagRoute`/`webFlags` import nothing heavy.

- [ ] **Step 5: Commit**

```bash
git add src/router/routes.tsx src/router/roomsRoutes.test.tsx src/components/navbar/MainNavbar.tsx src/components/navbar/roomsNav.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(rooms): routes and nav entries, dark behind their flags

/voice-rooms(/:id) behind webVoiceRoomsEnabled; /rooms(/:id),
/community/city and /community/genders behind webLanguageRoomsEnabled
(plus roomsEnabled). With a flag off the paths are the 404 page and the
navbar shows nothing; tests pin both, and loading/failed app-config.

Still open (Phase 4 rooms): i18n, push; browser QA with app users
before the owner turns the flags on.
EOF
```

---

### Task P4-ROOM-I18N: The rooms unit's new strings in all 18 locales

**Files:**
- Create: `scripts/i18n/keys/2026-10-16-p4-rooms.json` (all 18 locales; the durable record of what this unit translated)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: every English string P4-ROOM-3…12 added to `eng.json` — namespaces `voiceRooms.*`, `languageRooms.*`, `community.cityTab.*`, `community.gendersTab.*`, `communityMain.subnav.city|genders`, `nav.voiceRooms|languageRooms`, and any `common.*` key a task had to add. `scripts/i18n/new-keys.js` (P3-CHAT-I18N) finds them from the diff against `web/p4-base`, so a key a task forgot to list is still caught. `src/utils/locales/p3Keys.test.ts` (widened by P4-0 to `2026-10-16-p[34]-*.json`) is the guard.
- Produces: no English-only key in this unit's push.

**Translation rules:** keep `{{…}}` placeholders verbatim (`community.cityTab.searchTitle` has `{{query}}`); keep curly quotes around the placeholder only where the target language uses them (else its own quotation marks); "BananaTalk" and "banatalk.com" are never translated; "co-host" follows the app's ARB wording for that locale (`bananatalk_app/lib/l10n/app_<locale>.arb`, search `cohost`/`coHost`) so web and app say the same; tone/terminology from `docs/l10n/2026-09-23-native-pass-*.md`.

- [ ] **Step 1: Generate the keys file and watch the guard fail**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-rooms
node scripts/i18n/new-keys.js web/p4-base scripts/i18n/keys/2026-10-16-p4-rooms.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: the script prints `N new or changed keys` (about 120); the test FAILS with `<key>: missing` for each of the 17 non-English locales.

- [ ] **Step 2: Translate**

Fill every `""` in `scripts/i18n/keys/2026-10-16-p4-rooms.json` for the 17 non-English locales (rules above). Re-running `new-keys.js` keeps what is already filled.

- [ ] **Step 3: Merge into the locale files**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p4-rooms.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: all `p3Keys` cases pass (including the earlier Phase 3/4 key files); `src/utils/i18n*.test.ts` stay green.

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/keys/2026-10-16-p4-rooms.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
i18n(rooms): translate the voice room, language room and City/Genders strings

Keys found by scripts/i18n/new-keys.js against web/p4-base and merged
with merge-keys.js into all 18 locales; p3Keys.test.ts now covers the
p4-rooms key file.

Still open (Phase 4 rooms): push gate (P4-ROOM-PUSH); native review of
the new strings.
EOF
```

---

### Task P4-ROOM-PUSH: Push unit ROOMS (3 of 5) — suite, build and LiveKit checks green, then the coordinator pushes (dark)

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status line, §6 changelog line, §3 production-QA lines for the flag-on checklist below)

- [ ] **Step 1: Every task in the unit is committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-rooms
git status --short                                         # expect: nothing
grep -n "P4-ROOM-" docs/REMAINING_WORK.md | grep -c "\[ \]"  # expect: 1 (this PUSH line only)
```

- [ ] **Step 2: Rebase onto the live site (REELS and GATHERINGS are already pushed)**

```bash
git fetch origin
git rebase origin/main
```
Expected conflicts and their resolution (keep both sides in every case):
- `src/router/routes.tsx` — REELS/GATHERINGS added their own lazy blocks and `<Route>`s; keep theirs and ours, one `import FlagRoute from "./FlagRoute";` only.
- `src/components/navbar/MainNavbar.tsx` — their flagged entries sit where ours go; keep all, ours after theirs, one `useWebFlag` import, both `react-icons/fa` additions.
- `src/utils/locales/*.json`, `docs/REMAINING_WORK.md` — union of keys/lines.
- `package.json` / `package-lock.json` — only if an earlier push changed dependencies (none planned). If they conflict: take `origin/main`'s files, then rerun `npm install --save-exact livekit-client@2.22.4` and `git add` both.
After `git rebase --continue`: `npm ci` (lock may have moved), then `CI=true npm test -- --watchAll=false p3Keys` (every unit's keys still complete).

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `0 failed` suites and tests; passed count ≥ the GATHERINGS push's count plus this unit's new tests. Any failure: fix in a new commit (never skip a test).

- [ ] **Step 4: Production build and the LiveKit checks**

```bash
npm run build 2>&1 | tail -20
ls build/static/js | grep -c '^livekit\..*\.chunk\.js$'          # expect: 1
grep -c "livekit-client" build/static/js/main.*.js                # expect: 0
npx tsc -p . 2>&1 | grep "error TS" | grep -c -i livekit          # expect: 0
npm run test:budget 2>&1 | tail -5                                 # note the first-paint size; not a gate
```
Expected: `Compiled successfully` or `Compiled with warnings`, the prerender step ends without an error line; one `livekit.<hash>.chunk.js`; no `livekit-client` in `main.js`; the TS 3.7 grep prints `0`. (`react-scripts build` does not type-check this repo, so the `tsc | grep livekit` line is the only check that the loader + `.d.ts` + `exclude` pattern still holds.)

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P4-ROOM-PUSH`; §1 Status: "Phase 4 rooms pushed dark (YYYY-MM-DD)"; §6 Done: one line ("voice rooms, language rooms, City/Genders behind webVoiceRoomsEnabled/webLanguageRoomsEnabled; livekit-client 2.22.4 added"); §3 Production QA: one `- [ ]` line per flag-on item in Step 8; §2 (backend follow-ups for the backend repo's tracker): speaker role + kick for voice rooms, accept the app's `voiceroom:raise-hand`/`hand-raised` spellings, city search ignores `location.city`.

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: Phase 4 rooms ready to deploy (dark)

Still open (Phase 4): calls, Apple; flag-on browser QA for voice rooms
(web + app in one room), language rooms and City/Genders before the
owner turns WEB_VOICE_ROOMS_ENABLED / WEB_LANGUAGE_ROOMS_ENABLED on.
EOF
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p4-rooms:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/            # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1   # a new bundle hash
```
(The deploy runs `npm ci` on Node 18: `livekit-client@2.22.4` and its deps install there from the committed lock. A failure at "Install dependencies" means the lock is out of sync — rerun Step 2's `npm ci` locally, recommit the lock, push again.)

- [ ] **Step 7: Production smoke with the flags still OFF (must show nothing)**

  - [ ] `curl -s https://api.banatalk.com/api/v1/app-config | grep -o '"web\(VoiceRooms\|LanguageRooms\)Enabled":[a-z]*'` → both `false`.
  - [ ] Signed in on https://banatalk.com: no "Voice rooms" / "Language rooms" in the navbar (desktop and the mobile menu); `/communities` sub-nav shows no City/Genders links.
  - [ ] `https://banatalk.com/voice-rooms`, `/voice-rooms/x`, `/rooms`, `/rooms/x`, `/community/city`, `/community/genders` each show the 404 page (after a brief spinner at most).
  - [ ] DevTools → Network on `/communities` and `/chat`: no `livekit.*.chunk.js` request.
  - [ ] Chat, moments and community behave as before (one message sent, one moment opened).

A failure that breaks a live flow → Step 9.

- [ ] **Step 8: Flag-on checklist (recorded in §3 now, run later on a staging flip or with the owner, before `WEB_*` goes on for everyone)**

  - [ ] Voice room: web user creates a room; an app 2.7.0 user and a second web user join. Everyone hears everyone; speaking ring follows the speaker; mute state matches on web and app.
  - [ ] Web listener's mic denied (Chrome "Block", Safari "Don't allow") → help banner, room keeps playing; after allowing, "Take the mic" works.
  - [ ] Safari (macOS and iOS) joins: "Tap to turn on the room's sound" appears if audio is blocked and fixes it.
  - [ ] Host (web) mutes everyone → app and web participants are muted; makes a web participant co-host; ends the room → everyone sees "This room has ended", the list drops it.
  - [ ] Same account joins the room in a second tab → first tab shows "You joined this room from another tab or device"; "Listen here instead" takes it back.
  - [ ] Wi-Fi off for 20 s while in a room → "Reconnecting…", then back; Wi-Fi off for 2 min → "Connection lost" + Rejoin works; the room still appears in the list for others (heartbeat resumed).
  - [ ] Known gap shown to QA, not a bug in this unit: a hand raised on web is not visible to an app host and vice versa (event-name mismatch, backend follow-up).
  - [ ] Language rooms: the member's own language hub is first; a message sent on web appears in the app's room and the reverse; older messages load; a topic room created on web shows in the app; owner approves a request from an app user.
  - [ ] City: pick Japan → the same people the app's City tab shows for Japan; Genders: Women/Men counts and lists match the app's Genders tab for the same account.

- [ ] **Step 9 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p4-rooms-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -30
npm ci && CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(The unit is a linear series after the rebase, so the range revert is clean. Reverting also removes `livekit-client` from `package.json`; if CALLS is already pushed on top, revert CALLS first. Note the revert in §6 and reopen the tasks.)

---

---

## Unit CALLS (push 4 of 5) — P4-CALL-0 … P4-CALL-11, P4-CALL-I18N, P4-CALL-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p4-calls`, branch `web/p4-calls`, created from `web/p4-rooms` **at the P4-ROOM-1 commit** (P4-CALL-0) so `livekit-client@2.22.4`, `src/lib/livekit/*` and the `tsconfig.json` exclude are present. Real `node_modules` (`npm ci`). One implementer, tasks in number order. Rebases onto `origin/main` after ROOMS is pushed (P4-CALL-PUSH); P4-ROOM-1 then drops out of the rebase as already upstream.

Unit facts (read once):
- **Everything about a call's lifecycle is REST + server-side state** (`be/services/callStateService.js`; one conditional write per transition, losers get `409 {code:'CALL_STATE', status}`). Sockets only *announce* transitions. Exact backend contract (`be-integration` `07febec`):
  - `POST /api/v1/calls/initiate {receiverId, type:'audio'|'video'}` → `200 {data:{call:{_id, callUuid, …}, token, url, roomName}}` (`controllers/callController.js:181-277`). Refusals: `400` bad input; `403 "Cannot call this user"` (block, either side, `:198-200`); `403 code CONVERSATION_START_LIMIT` (`:204-207`); `409 code CALLEE_UNAVAILABLE` (calls off / quiet hours, `:209-218`); `409 CALLER_BUSY` / `409 CALLEE_BUSY` (`:220-231`); `503 "Could not start the call"` (LiveKit mint failed, `:244-248`). The receiver gets push (phone rings via CallKit/FCM) **and** socket `call:incoming` to room `user_<receiverId>` = every socket (every tab, every device) of that user (`:255-266`).
  - `POST /calls/:id/accept {deviceId?}` → `{data:{call, token, url, roomName}}`; `409 CALL_STATE` if someone (another tab, the phone, the ring timer) got there first (`controllers/callController.js:281-309`).
  - `POST /calls/:id/decline {deviceId?, message? ≤ 200}` → `{data:{call, messageDelivered?}}` (`:317-360`). `messageDelivered` is present only when a message was sent; `false` = block or daily cap (never named).
  - `POST /calls/:id/end` from either side: ringing → caller cancels / receiver declines; active → ended + LiveKit room closed; terminal → idempotent `200` (`:362-391`).
  - `POST /calls/:id/upgrade` → active voice call becomes video, emits `call:state` with `type:'video'` (`:393-406`).
  - `GET /calls/current` → `{data:{call:null}}` or `{data:{call:{id, callUuid, type, status:'ringing'|'active', direction:'in'|'out', otherParty:{id,name,avatar}|null, roomName, startTime}, token?, url?}}` — token only for `active` (`:85-123`). Ringing is reported only to the receiver and only while < 60 s old (`services/callService.js` `getCurrentCall`, `callStateService.js:76`).
  - `GET /calls?page&limit` (limit ≤ 50) → `{data:[{id, callUuid, type, direction, outcome, duration, otherParty, createdAt}], pagination:{total,page,limit,hasMore}}` (`services/callService.js:95-127`, `toHistoryItem` + `getCallHistory`); `outcome ∈ completed|no_answer|cancelled|declined|busy|null` (`callStateService.js:81-90`). `GET /calls/missed/count` → `{data:{count}}`; `POST /calls/missed/seen` clears it.
  - Server ring timeout 45 s → `missed` (`callStateService.js:23-25`). An active call whose participant leaves LiveKit is ended after a 20 s grace by the LiveKit webhook (`services/callLivenessService.js`), so a page reload can rejoin within 20 s.
- **Socket events (exact names).** Server → client: `call:incoming {callId, callUuid, caller:{_id,name,profilePicture}, callType, roomName}`; `call:state {callId, callUuid, status, outcome, endReason, duration, type, by}` to **both** users' rooms on every transition (`services/callEvents.js:20-61`); legacy `call:accepted` / `call:declined` / `call:ended` (no callId filtering in old apps — the web **ignores** them, exactly as new app builds do, `call_manager.dart:353-363`); in-call relays `call:mute {callId,userId,isMuted}`, `call:video-toggle {callId,userId,isVideoEnabled}`, `call:peer-reconnecting {callId,userId}`, `call:peer-reconnected {callId,userId}`, `call:failed {callId,reason}` (`socket/callRelayHandler.js`). Client → server (acked `{status:'success'|'error'}`, only while the call is `active`): `call:mute {callId,isMuted}`, `call:video-toggle {callId,isVideoEnabled}`, `call:reconnecting {callId}`, `call:reconnected {callId}`, `call:failed {callId,reason}`.
- **"Answered elsewhere"** is derived exactly like the app (`call_manager.dart:733-735`): a `call:state` with `status:'active'` for the ringing call that *this tab* did not accept closes the banner silently. The phone's CallKit ring is stopped by the backend's `call_cancelled` push (it skips the accepting `deviceId`), so the web always sends a per-tab `deviceId` (`web-<random>`, sessionStorage). Other web tabs are additionally told at once over `BroadcastChannel("bt-calls")` (no wait for the socket round trip).
- **No ring without an open tab** (spec non-goal): the app's push still rings the phone.
- **Media**: the web uses the shared LiveKit wrapper from P4-ROOM-1 unchanged (`createLkSession`, `mediaErrorKind`, `LkSession.connect/setMic/setCamera/localVideo/startAudio/disconnect`, `LkEvents.onPeers/onState/onDisconnected/onAudioBlocked/onRemoteVideo`). CALLS tests mock at that contract boundary (`src/lib/livekit/lkSession` via `src/components/calls/testing/fakeLkSession.ts`, keeping the real `mediaErrorKind`), so they do not depend on how ROOMS drives the fake `Room`; ROOMS' own tests cover `lkSession` against `fakeLivekit`. The LiveKit room name is `call:<callId>`; the token's identity is the user id.
- **Bundle**: only `src/components/calls/callBridge.ts` and `src/components/calls/IncomingCallHost.tsx` are eager (mounted in `App.tsx`); everything else is the lazy `calls` chunk, and `livekit-client` stays in the lazy `livekit` chunk.
- **Phase 3 dependencies** (stop and ask if missing on the base): `useSocket()` with `connectionEpoch` (P3-CHAT-7), `CallMessageCard` (P3-CHAT-10, `src/components/chat/components/CallMessageCard.tsx`), `setupListeners` in the store.
- **Ringtone/ringback**: the app's `assets/sounds/ringtone.m4a` and `ringback.m4a` (AAC; plays in Chrome, Safari, Edge and Firefox) are copied to `public/sounds/`.
- Every commit step ticks that task's own `- [ ] P4-CALL-n` line in `docs/REMAINING_WORK.md` (Global Constraints → Commits), even where the step text only lists the file in `git add`.
- Product decisions recorded as open in the tracker: no incoming-call ring on pages other than an open BananaTalk tab; the web does not offer "upgrade to video" for a callee whose camera is denied (stays voice).

### Task P4-CALL-0: CALLS worktree off `web/p4-rooms` after the LiveKit wrapper

**Files:**
- Modify: `docs/REMAINING_WORK.md` (tick `P4-CALL-0`)

**Interfaces:**
- Consumes: the P4-ROOM-1 commit on `web/p4-rooms` (subject starts `feat(livekit):`), which adds `livekit-client@2.22.4` to `package.json`/`package-lock.json`, `src/lib/livekit/{livekitLoader.js,livekitLoader.d.ts,lkSession.ts,testing/fakeLivekit.ts}` and the `tsconfig.json` exclude.
- Produces: branch `web/p4-calls`, worktree `/Users/davis/Desktop/Personal/wt-web-p4-calls` with a real `node_modules`.

- [ ] **Step 1: Find the wrapper commit and branch from it**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
ROOM1=$(git log web/p4-rooms --format=%H --grep='^feat(livekit):' -1)
test -n "$ROOM1" && git show --stat $ROOM1 | head -20     # expect src/lib/livekit/* + package.json + tsconfig.json
git worktree add -b web/p4-calls /Users/davis/Desktop/Personal/wt-web-p4-calls $ROOM1
cd /Users/davis/Desktop/Personal/wt-web-p4-calls
npm ci 2>&1 | tail -2
node -e "console.log(require('livekit-client/package.json').version)"   # 2.22.4
grep -n "createLkSession\|mediaErrorKind" src/lib/livekit/lkSession.ts | head -4
CI=true npm test -- --watchAll=false 2>&1 | tail -5
```
Expected: `2.22.4`; both exports found; the suite is green with the P4-0 and P4-ROOM-1 tests. If `lkSession.ts` deviates from the header's "Shared contracts → LiveKit", stop and reconcile with the ROOMS implementer before P4-CALL-8.

- [ ] **Step 2: Tick and commit**

Tick `- [ ] P4-CALL-0` in `docs/REMAINING_WORK.md`.

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'MSG'
docs: start the Phase 4 calls unit on top of the LiveKit wrapper

Still open (Phase 4 calls): P4-CALL-1 … P4-CALL-11, I18N, PUSH.
MSG
```

---

### Task P4-CALL-1: `callsSlice` — the `/calls` REST contract

**Files:**
- Create: `src/store/slices/callsSlice.ts`, `src/store/slices/callsEndpoints.test.ts`
- Modify: `src/constants.ts` (add `CALLS_URL` after `CONVERSATIONS_URL`), `src/store/slices/apiSlice.ts` (`tagTypes`: add `"Calls"` after `"ChatTheme"`)

**Interfaces:**
- Consumes: the endpoints listed in the unit facts (`be/routes/calls.js`, `be/controllers/callController.js`).
- Produces (`callsSlice.ts`): `callsApiSlice`; hooks `useInitiateCallMutation` (`{receiverId, type}`), `useAcceptCallMutation` (`{callId, deviceId}`), `useDeclineCallMutation` (`{callId, deviceId, message?}`), `useEndCallMutation` (`{callId, deviceId}`), `useUpgradeCallMutation` (`callId`), `useLazyGetCurrentCallQuery` (no arg), `useGetCallHistoryQuery` (`{page, limit}`), `useGetMissedCallCountQuery` (`void`, returns a number), `useMarkMissedCallsSeenMutation`. Types `CallType`, `CallOutcomeWire`, `CallParty`, `CallHistoryItem`, `CurrentCallSummary`, `CurrentCallResponse`. History, missed count and current call are tagged `"Calls"`; every lifecycle mutation invalidates it.

- [ ] **Step 1: Write the failing test**

Create `src/store/slices/callsEndpoints.test.ts`:

```ts
// The request shapes the website sends to /api/v1/calls are the ones the app
// sends (lib/services/call/call_api.dart) and the backend contract test pins
// (be/test/webFeatureContracts.test.js "calls: …").
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { callsApiSlice } from "./callsSlice";
import { CALLS_URL } from "../../constants";

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

function mockFetch(responseData: any = {}): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify(Object.assign({ success: true }, responseData)), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
});

const ep = (name: string) => (callsApiSlice.endpoints as any)[name];
const path = (c: Captured) => new URL(c.url).pathname;
const json = (c: Captured) => (c.body ? JSON.parse(c.body as string) : undefined);

it("CALLS_URL is the backend mount", () => {
  expect(CALLS_URL).toBe("/api/v1/calls");
});

it("initiateCall -> POST /calls/initiate {receiverId, type}", async () => {
  const calls = mockFetch({ data: { call: { _id: "c1", callUuid: "U1" }, token: "t", url: "wss://lk", roomName: "call:c1" } });
  const res: any = await makeStore().dispatch(ep("initiateCall").initiate({ receiverId: "u2", type: "video" }));
  expect(path(calls[0])).toBe(`${CALLS_URL}/initiate`);
  expect(calls[0].method).toBe("POST");
  expect(json(calls[0])).toEqual({ receiverId: "u2", type: "video" });
  expect(res.data.data.token).toBe("t");
});

it("acceptCall -> POST /calls/:id/accept {deviceId}", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(ep("acceptCall").initiate({ callId: "c1", deviceId: "web-abc" }));
  expect(path(calls[0])).toBe(`${CALLS_URL}/c1/accept`);
  expect(calls[0].method).toBe("POST");
  expect(json(calls[0])).toEqual({ deviceId: "web-abc" });
});

it("declineCall sends the message only when there is one", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("declineCall").initiate({ callId: "c1", deviceId: "web-abc", message: "  Text me?  " }));
  await store.dispatch(ep("declineCall").initiate({ callId: "c2", deviceId: "web-abc", message: "   " }));
  expect(path(calls[0])).toBe(`${CALLS_URL}/c1/decline`);
  expect(json(calls[0])).toEqual({ deviceId: "web-abc", message: "Text me?" });
  expect(json(calls[1])).toEqual({ deviceId: "web-abc" });
});

it("endCall -> POST /calls/:id/end {deviceId}; upgradeCall -> POST /calls/:id/upgrade", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("endCall").initiate({ callId: "c1", deviceId: "web-abc" }));
  await store.dispatch(ep("upgradeCall").initiate("c1"));
  expect(path(calls[0])).toBe(`${CALLS_URL}/c1/end`);
  expect(json(calls[0])).toEqual({ deviceId: "web-abc" });
  expect(path(calls[1])).toBe(`${CALLS_URL}/c1/upgrade`);
  expect(calls[1].method).toBe("POST");
});

it("getCurrentCall -> GET /calls/current, returns data as is", async () => {
  const calls = mockFetch({ data: { call: null } });
  const res: any = await makeStore().dispatch(ep("getCurrentCall").initiate(undefined));
  expect(path(calls[0])).toBe(`${CALLS_URL}/current`);
  expect(calls[0].method).toBe("GET");
  expect(res.data).toEqual({ call: null });
});

it("getCallHistory -> GET /calls?page&limit, keeps data + pagination", async () => {
  const calls = mockFetch({
    data: [{ id: "c1", type: "audio", direction: "in", outcome: "no_answer", duration: 0, otherParty: null, createdAt: "x" }],
    pagination: { total: 1, page: 1, limit: 20, hasMore: false },
  });
  const res: any = await makeStore().dispatch(ep("getCallHistory").initiate({ page: 1, limit: 20 }));
  const url = new URL(calls[0].url);
  expect(url.pathname).toBe(CALLS_URL);
  expect(url.searchParams.get("page")).toBe("1");
  expect(url.searchParams.get("limit")).toBe("20");
  expect(res.data.items).toHaveLength(1);
  expect(res.data.hasMore).toBe(false);
});

it("missed count reads data.count (0 when absent); missed seen -> POST /calls/missed/seen", async () => {
  const calls = mockFetch({ data: { count: 3 } });
  const store = makeStore();
  const res: any = await store.dispatch(ep("getMissedCallCount").initiate(undefined));
  expect(path(calls[0])).toBe(`${CALLS_URL}/missed/count`);
  expect(res.data).toBe(3);
  await store.dispatch(ep("markMissedCallsSeen").initiate(undefined));
  expect(path(calls[1])).toBe(`${CALLS_URL}/missed/seen`);
  expect(calls[1].method).toBe("POST");
});

it("encodes a callUuid id safely", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(ep("endCall").initiate({ callId: "A1B2/../x", deviceId: "d" }));
  expect(calls[0].url).toContain(`${CALLS_URL}/A1B2%2F..%2Fx/end`);
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-calls && CI=true npm test -- --watchAll=false callsEndpoints
```
Expected: FAIL — `Cannot find module './callsSlice'` (and `CALLS_URL` undefined).

- [ ] **Step 3: Implement**

`src/constants.ts`, after `export const CONVERSATIONS_URL = "/api/v1/conversations";` add:

```ts
export const CALLS_URL = "/api/v1/calls";
```

`src/store/slices/apiSlice.ts`, in `tagTypes`, after `"ChatTheme",` add:

```ts
    // Call history + the missed-call badge (Phase 4 calls). Invalidated by
    // every call lifecycle mutation.
    "Calls",
```

Create `src/store/slices/callsSlice.ts`:

```ts
import { apiSlice } from "./apiSlice";
import { CALLS_URL } from "../../constants";

/** 1:1 calls. Same routes and bodies as the app (lib/services/call/call_api.dart). */
export type CallType = "audio" | "video";
export type CallOutcomeWire = "completed" | "no_answer" | "cancelled" | "declined" | "busy" | null;

export interface CallParty {
  id: string;
  name: string;
  avatar: string | null;
}

/** One row of GET /calls (be/services/callService.js toHistoryItem). */
export interface CallHistoryItem {
  id: string;
  callUuid: string | null;
  type: CallType;
  direction: "in" | "out";
  outcome: CallOutcomeWire;
  duration: number;
  otherParty: CallParty | null;
  createdAt: string;
}

/** GET /calls/current data.call (be/controllers/callController.js getCurrentCall). */
export interface CurrentCallSummary {
  id: string;
  callUuid: string | null;
  type: CallType;
  status: "ringing" | "active";
  direction: "in" | "out";
  otherParty: CallParty | null;
  roomName: string;
  startTime: string;
}

export interface CurrentCallResponse {
  call: CurrentCallSummary | null;
  token?: string;
  url?: string;
}

const idPath = (callId: string) => `${CALLS_URL}/${encodeURIComponent(callId)}`;

export const callsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    initiateCall: builder.mutation({
      query: ({ receiverId, type }: { receiverId: string; type: CallType }) => ({
        url: `${CALLS_URL}/initiate`,
        method: "POST",
        body: { receiverId, type },
      }),
      invalidatesTags: ["Calls"],
    }),
    acceptCall: builder.mutation({
      query: ({ callId, deviceId }: { callId: string; deviceId: string }) => ({
        url: `${idPath(callId)}/accept`,
        method: "POST",
        body: { deviceId },
      }),
      invalidatesTags: ["Calls"],
    }),
    declineCall: builder.mutation({
      query: ({ callId, deviceId, message }: { callId: string; deviceId: string; message?: string }) => {
        const text = typeof message === "string" ? message.trim() : "";
        const body: { deviceId: string; message?: string } = { deviceId };
        if (text) body.message = text;
        return { url: `${idPath(callId)}/decline`, method: "POST", body };
      },
      invalidatesTags: ["Calls"],
    }),
    endCall: builder.mutation({
      query: ({ callId, deviceId }: { callId: string; deviceId: string }) => ({
        url: `${idPath(callId)}/end`,
        method: "POST",
        body: { deviceId },
      }),
      invalidatesTags: ["Calls"],
    }),
    upgradeCall: builder.mutation({
      query: (callId: string) => ({ url: `${idPath(callId)}/upgrade`, method: "POST" }),
    }),
    getCurrentCall: builder.query({
      query: () => ({ url: `${CALLS_URL}/current` }),
      transformResponse: (response: any): CurrentCallResponse =>
        (response && response.data) || { call: null },
      keepUnusedDataFor: 0,
    }),
    getCallHistory: builder.query({
      query: ({ page, limit }: { page: number; limit: number }) => ({
        url: `${CALLS_URL}?page=${page}&limit=${limit}`,
      }),
      transformResponse: (response: any) => ({
        items: (response && Array.isArray(response.data) ? response.data : []) as CallHistoryItem[],
        hasMore: Boolean(response && response.pagination && response.pagination.hasMore),
      }),
      providesTags: ["Calls"],
    }),
    getMissedCallCount: builder.query({
      query: () => ({ url: `${CALLS_URL}/missed/count` }),
      transformResponse: (response: any): number =>
        response && response.data && typeof response.data.count === "number" ? response.data.count : 0,
      providesTags: ["Calls"],
    }),
    markMissedCallsSeen: builder.mutation({
      query: () => ({ url: `${CALLS_URL}/missed/seen`, method: "POST" }),
      invalidatesTags: ["Calls"],
    }),
  }),
});

export const {
  useInitiateCallMutation,
  useAcceptCallMutation,
  useDeclineCallMutation,
  useEndCallMutation,
  useUpgradeCallMutation,
  useLazyGetCurrentCallQuery,
  useGetCallHistoryQuery,
  useGetMissedCallCountQuery,
  useMarkMissedCallsSeenMutation,
} = callsApiSlice as any;
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false callsEndpoints apiSlice
```
Expected: all pass.

- [ ] **Step 5: Commit**

Tick `P4-CALL-1` in `docs/REMAINING_WORK.md`.

```bash
git add src/store/slices/callsSlice.ts src/store/slices/callsEndpoints.test.ts src/constants.ts src/store/slices/apiSlice.ts docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): RTK Query slice for the /calls contract

initiate, accept, decline (message only when non-empty), end, upgrade,
current, history, missed count and missed seen, with the same bodies
the app sends. Not used by any screen yet.

Still open (Phase 4 calls): P4-CALL-2 … P4-CALL-11, I18N, PUSH.
MSG
```

---

### Task P4-CALL-2: Call error classifier, per-tab device id, mic/camera preflight

**Files:**
- Create: `src/components/calls/lib/callErrors.ts`, `src/components/calls/lib/callErrors.test.ts`
- Create: `src/components/calls/lib/deviceId.ts`, `src/components/calls/lib/deviceId.test.ts`
- Create: `src/components/calls/lib/mediaPreflight.ts`, `src/components/calls/lib/mediaPreflight.test.ts`
- Modify: `src/utils/locales/eng.json` (`calls.errors.*`, `calls.media.*`)

**Interfaces:**
- Consumes: initiate/accept refusals (unit facts); `mediaErrorKind(err): LkMediaResult` from `src/lib/livekit/lkSession.ts` (P4-ROOM-1); `navigator.mediaDevices.getUserMedia`.
- Produces:
  - `classifyCallError(err: any): CallError` with `CallError = { kind: CallErrorKind; detail: string }`, `CallErrorKind = "callerBusy" | "calleeBusy" | "calleeUnavailable" | "blocked" | "conversationCap" | "callState" | "startFailed" | "network" | "generic"`; `callErrorText(e: CallError, t, name: string): string`.
  - `mediaProblemText(device: "mic" | "camera", kind: LkMediaResult, t): string`.
  - `callDeviceId(): string` — `web-<16 hex>`, stable for the page load, different per tab (deliberately not sessionStorage: a duplicated tab copies sessionStorage and would share it).
  - `preflightMedia(wantCamera: boolean): Promise<{ mic: LkMediaResult; camera: LkMediaResult | null }>` — asks once, stops every track it got (the LiveKit session asks again when it publishes; the preflight only makes the permission prompt happen *before* the phone rings).

- [ ] **Step 1: Write the failing tests**

Create `src/components/calls/lib/callErrors.test.ts`:

```ts
import { classifyCallError, callErrorText, mediaProblemText } from "./callErrors";

const t = () => "";
const err = (status: any, data: any = {}) => ({ status, data });

describe("classifyCallError", () => {
  it.each([
    [err(409, { code: "CALLER_BUSY", error: "You are already in a call" }), "callerBusy"],
    [err(409, { code: "CALLEE_BUSY", error: "Mina is on another call" }), "calleeBusy"],
    [err(409, { code: "CALLEE_UNAVAILABLE", error: "Mina isn't taking calls right now" }), "calleeUnavailable"],
    [err(403, { code: "CONVERSATION_START_LIMIT", error: "You have started the most…" }), "conversationCap"],
    [err(403, { error: "Cannot call this user" }), "blocked"],
    [err(409, { code: "CALL_STATE", status: "active" }), "callState"],
    [err(503, { error: "Could not start the call" }), "startFailed"],
    [err("FETCH_ERROR"), "network"],
    [err(500, { error: "boom" }), "generic"],
    [undefined, "generic"],
  ])("%j -> %s", (input, kind) => {
    expect(classifyCallError(input).kind).toBe(kind);
  });

  it("keeps the server sentence as detail", () => {
    expect(classifyCallError(err(409, { code: "CALLEE_BUSY", error: "Mina is on another call" })).detail).toBe(
      "Mina is on another call"
    );
  });
});

describe("callErrorText (English fallbacks; never the raw server text)", () => {
  it("names the person where the app does", () => {
    expect(callErrorText({ kind: "calleeBusy", detail: "" }, t, "Mina")).toBe("Mina is on another call.");
    expect(callErrorText({ kind: "calleeUnavailable", detail: "" }, t, "Mina")).toBe(
      "Mina isn't taking calls right now."
    );
  });
  it("covers the rest", () => {
    expect(callErrorText({ kind: "callerBusy", detail: "" }, t, "Mina")).toBe(
      "You're already in a call on another device or tab."
    );
    expect(callErrorText({ kind: "blocked", detail: "" }, t, "Mina")).toBe("You can't call this person.");
    expect(callErrorText({ kind: "conversationCap", detail: "" }, t, "Mina")).toBe(
      "You've started as many new conversations as you can today. Go VIP to start more."
    );
    expect(callErrorText({ kind: "startFailed", detail: "" }, t, "Mina")).toBe(
      "The call couldn't be started. Try again in a moment."
    );
    expect(callErrorText({ kind: "network", detail: "" }, t, "Mina")).toBe(
      "You're offline. Check your connection and try again."
    );
    expect(callErrorText({ kind: "generic", detail: "boom" }, t, "Mina")).toBe("Something went wrong with the call.");
  });
});

describe("mediaProblemText", () => {
  it("tells a blocked user where to unblock", () => {
    expect(mediaProblemText("mic", "denied", t)).toBe(
      "BananaTalk can't use your microphone. Allow it in your browser's site settings, then try again."
    );
    expect(mediaProblemText("camera", "denied", t)).toBe(
      "BananaTalk can't use your camera. Allow it in your browser's site settings, then try again."
    );
  });
  it("explains a missing or busy device", () => {
    expect(mediaProblemText("mic", "unavailable", t)).toBe(
      "No microphone was found, or another app is using it."
    );
    expect(mediaProblemText("camera", "unavailable", t)).toBe("No camera was found, or another app is using it.");
    expect(mediaProblemText("camera", "error", t)).toBe("Your camera couldn't be started.");
  });
});
```

Create `src/components/calls/lib/deviceId.test.ts`:

```ts
import { callDeviceId } from "./deviceId";

it("is web-<16 hex>, the same for the whole page load", () => {
  const a = callDeviceId();
  expect(a).toMatch(/^web-[0-9a-f]{16}$/);
  expect(callDeviceId()).toBe(a);
});

it("is never written to storage (a duplicated tab would share it)", () => {
  const set = jest.spyOn(Storage.prototype, "setItem");
  callDeviceId();
  expect(set).not.toHaveBeenCalled();
  set.mockRestore();
});
```

Create `src/components/calls/lib/mediaPreflight.test.ts`:

```ts
import { preflightMedia } from "./mediaPreflight";

const track = () => ({ stop: jest.fn() });
function stream() {
  const tracks = [track(), track()];
  return { tracks, getTracks: () => tracks };
}
const domError = (name: string) => Object.assign(new Error(name), { name });

function setGetUserMedia(impl: any) {
  Object.defineProperty(navigator, "mediaDevices", {
    configurable: true,
    value: impl ? { getUserMedia: impl } : undefined,
  });
}

afterEach(() => setGetUserMedia(undefined));

it("voice call: asks for the mic only and stops what it got", async () => {
  const s = stream();
  const gum = jest.fn().mockResolvedValue(s);
  setGetUserMedia(gum);
  expect(await preflightMedia(false)).toEqual({ mic: "ok", camera: null });
  expect(gum).toHaveBeenCalledWith({ audio: true });
  s.tracks.forEach((x) => expect(x.stop).toHaveBeenCalled());
});

it("video call: mic + camera in one prompt", async () => {
  setGetUserMedia(jest.fn().mockResolvedValue(stream()));
  expect(await preflightMedia(true)).toEqual({ mic: "ok", camera: "ok" });
});

it("video call with the camera denied falls back to the mic", async () => {
  const gum = jest
    .fn()
    .mockRejectedValueOnce(domError("NotAllowedError"))
    .mockResolvedValueOnce(stream());
  setGetUserMedia(gum);
  expect(await preflightMedia(true)).toEqual({ mic: "ok", camera: "denied" });
  expect(gum).toHaveBeenLastCalledWith({ audio: true });
});

it("no camera at all is 'unavailable', not 'denied'", async () => {
  setGetUserMedia(
    jest.fn().mockRejectedValueOnce(domError("NotFoundError")).mockResolvedValueOnce(stream())
  );
  expect(await preflightMedia(true)).toEqual({ mic: "ok", camera: "unavailable" });
});

it("mic denied", async () => {
  setGetUserMedia(jest.fn().mockRejectedValue(domError("NotAllowedError")));
  expect(await preflightMedia(false)).toEqual({ mic: "denied", camera: null });
});

it("no mediaDevices (http:// origin, old browser)", async () => {
  setGetUserMedia(undefined);
  expect(await preflightMedia(true)).toEqual({ mic: "unavailable", camera: "unavailable" });
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false calls/lib/callErrors calls/lib/deviceId calls/lib/mediaPreflight
```
Expected: FAIL — the three modules cannot be resolved.

- [ ] **Step 3: Implement**

Create `src/components/calls/lib/callErrors.ts`:

```ts
import { LkMediaResult } from "../../../lib/livekit/lkSession";

export type CallErrorKind =
  | "callerBusy"
  | "calleeBusy"
  | "calleeUnavailable"
  | "blocked"
  | "conversationCap"
  | "callState"
  | "startFailed"
  | "network"
  | "generic";

export interface CallError {
  kind: CallErrorKind;
  /** The server's sentence, for logs only. Never shown: it is English. */
  detail: string;
}

type T = (key: string, opts?: any) => string;

/**
 * An RTK Query error from /calls/* -> one kind. Codes first (they are the
 * contract, be/controllers/callController.js), then status: a 403 without a
 * code is the block refusal, which the backend words neutrally on purpose.
 */
export function classifyCallError(err: any): CallError {
  const status = err ? err.status : undefined;
  const data = (err && err.data) || {};
  const detail = typeof data.error === "string" ? data.error : "";
  switch (data.code) {
    case "CALLER_BUSY":
      return { kind: "callerBusy", detail };
    case "CALLEE_BUSY":
      return { kind: "calleeBusy", detail };
    case "CALLEE_UNAVAILABLE":
      return { kind: "calleeUnavailable", detail };
    case "CONVERSATION_START_LIMIT":
      return { kind: "conversationCap", detail };
    case "CALL_STATE":
      return { kind: "callState", detail };
    default:
      break;
  }
  if (status === 403) return { kind: "blocked", detail };
  if (status === 503) return { kind: "startFailed", detail };
  if (status === "FETCH_ERROR") return { kind: "network", detail };
  return { kind: "generic", detail };
}

export function callErrorText(e: CallError, t: T, name: string): string {
  switch (e.kind) {
    case "callerBusy":
      return t("calls.errors.callerBusy") || "You're already in a call on another device or tab.";
    case "calleeBusy":
      return t("calls.errors.calleeBusy", { name }) || `${name} is on another call.`;
    case "calleeUnavailable":
      return t("calls.errors.calleeUnavailable", { name }) || `${name} isn't taking calls right now.`;
    case "blocked":
      return t("calls.errors.blocked") || "You can't call this person.";
    case "conversationCap":
      return (
        t("calls.errors.conversationCap") ||
        "You've started as many new conversations as you can today. Go VIP to start more."
      );
    case "startFailed":
      return t("calls.errors.startFailed") || "The call couldn't be started. Try again in a moment.";
    case "network":
      return t("calls.errors.network") || "You're offline. Check your connection and try again.";
    default:
      return t("calls.errors.generic") || "Something went wrong with the call.";
  }
}

export function mediaProblemText(device: "mic" | "camera", kind: LkMediaResult, t: T): string {
  const mic = device === "mic";
  if (kind === "denied") {
    return mic
      ? t("calls.media.micDenied") ||
          "BananaTalk can't use your microphone. Allow it in your browser's site settings, then try again."
      : t("calls.media.cameraDenied") ||
          "BananaTalk can't use your camera. Allow it in your browser's site settings, then try again.";
  }
  if (kind === "unavailable") {
    return mic
      ? t("calls.media.micUnavailable") || "No microphone was found, or another app is using it."
      : t("calls.media.cameraUnavailable") || "No camera was found, or another app is using it.";
  }
  return mic
    ? t("calls.media.micError") || "Your microphone couldn't be started."
    : t("calls.media.cameraError") || "Your camera couldn't be started.";
}
```

Create `src/components/calls/lib/deviceId.ts`:

```ts
/**
 * The id this tab sends as `deviceId` on accept / decline / end. The backend
 * uses it to skip the acting device when it sends the `call_cancelled` push
 * that stops the ring on the user's other devices (be/controllers/
 * callController.js deviceIdFrom). Module-level on purpose: one per page
 * load, never shared between tabs -- sessionStorage would be copied into a
 * duplicated tab.
 */
let id: string | null = null;

function randomHex(bytes: number): string {
  const out: string[] = [];
  const c: any = typeof window !== "undefined" ? (window as any).crypto : undefined;
  if (c && typeof c.getRandomValues === "function") {
    const arr = new Uint8Array(bytes);
    c.getRandomValues(arr);
    for (let i = 0; i < arr.length; i++) out.push(("0" + arr[i].toString(16)).slice(-2));
    return out.join("");
  }
  for (let i = 0; i < bytes; i++) out.push(("0" + Math.floor(Math.random() * 256).toString(16)).slice(-2));
  return out.join("");
}

export function callDeviceId(): string {
  if (!id) id = `web-${randomHex(8)}`;
  return id;
}
```

Create `src/components/calls/lib/mediaPreflight.ts`:

```ts
import { mediaErrorKind, LkMediaResult } from "../../../lib/livekit/lkSession";

export interface PreflightResult {
  mic: LkMediaResult;
  camera: LkMediaResult | null;
}

function stopAll(stream: any): void {
  if (stream && typeof stream.getTracks === "function") {
    stream.getTracks().forEach((track: any) => track && track.stop && track.stop());
  }
}

/**
 * Ask for the mic (and the camera for a video call) BEFORE a call rings or is
 * accepted, so a "Block" never leaves the other person's phone ringing for a
 * call this browser cannot speak in. Every track is stopped at once; the
 * LiveKit session asks again (silently, the grant is remembered) when it
 * publishes.
 */
export async function preflightMedia(wantCamera: boolean): Promise<PreflightResult> {
  const md: any = typeof navigator !== "undefined" ? (navigator as any).mediaDevices : undefined;
  if (!md || typeof md.getUserMedia !== "function") {
    return { mic: "unavailable", camera: wantCamera ? "unavailable" : null };
  }
  let camera: LkMediaResult | null = null;
  if (wantCamera) {
    try {
      stopAll(await md.getUserMedia({ audio: true, video: true }));
      return { mic: "ok", camera: "ok" };
    } catch (err) {
      camera = mediaErrorKind(err);
    }
  }
  try {
    stopAll(await md.getUserMedia({ audio: true }));
    return { mic: "ok", camera };
  } catch (err) {
    return { mic: mediaErrorKind(err), camera };
  }
}
```

Add to `src/utils/locales/eng.json` (new top-level `calls` object; later tasks add sibling keys):

```json
"calls": {
  "errors": {
    "callerBusy": "You're already in a call on another device or tab.",
    "calleeBusy": "{{name}} is on another call.",
    "calleeUnavailable": "{{name}} isn't taking calls right now.",
    "blocked": "You can't call this person.",
    "conversationCap": "You've started as many new conversations as you can today. Go VIP to start more.",
    "startFailed": "The call couldn't be started. Try again in a moment.",
    "network": "You're offline. Check your connection and try again.",
    "generic": "Something went wrong with the call."
  },
  "media": {
    "micDenied": "BananaTalk can't use your microphone. Allow it in your browser's site settings, then try again.",
    "cameraDenied": "BananaTalk can't use your camera. Allow it in your browser's site settings, then try again.",
    "micUnavailable": "No microphone was found, or another app is using it.",
    "cameraUnavailable": "No camera was found, or another app is using it.",
    "micError": "Your microphone couldn't be started.",
    "cameraError": "Your camera couldn't be started."
  }
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false calls/lib i18n
```
Expected: all pass (`mediaErrorKind` is the real one from P4-ROOM-1: `NotAllowedError` → `denied`, `NotFoundError` → `unavailable`).

- [ ] **Step 5: Commit**

```bash
git add src/components/calls/lib/callErrors.ts src/components/calls/lib/callErrors.test.ts src/components/calls/lib/deviceId.ts src/components/calls/lib/deviceId.test.ts src/components/calls/lib/mediaPreflight.ts src/components/calls/lib/mediaPreflight.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): error kinds, per-tab device id, mic/camera preflight

Initiate/accept refusals map to one kind each (codes first, a bare 403
is the neutral block refusal); a per-page-load web-<hex> device id for
accept/decline/end; a preflight that asks for the mic (and camera)
before the phone rings and stops every track it got.

Still open (Phase 4 calls): P4-CALL-3 … P4-CALL-11, I18N, PUSH.
MSG
```

---

### Task P4-CALL-3: Pure call state machine

**Files:**
- Create: `src/components/calls/lib/callMachine.ts`, `src/components/calls/lib/callMachine.test.ts`

**Interfaces:**
- Consumes: payload shapes of `call:incoming`, `call:state` and `GET /calls/current` (unit facts); `CallType`, `CurrentCallResponse`, `CurrentCallSummary` from `callsSlice.ts`.
- Produces: `callReducer(state: CallState, action: CallAction): CallState`, `IDLE_CALL: CallState`, `isInCall(state): boolean` (any phase except `idle`/`ended`), `sameCallId(a, b): boolean` (case-insensitive; live iOS builds use upper-case uuids), `resyncAction(state, current: CurrentCallResponse | null | undefined, rejoinCallId: string | null): CallAction | null`; types `CallPhase`, `CallState`, `CallAction`, `CallPeer`, `CallEndOutcome`, `CallEndReason`, `IncomingCallPayload`, `CallStatePayload`.
- Rules (mirroring `call_manager.dart` `_onCallState` `:691-747` and `handleIncoming` `:388-…`): one call at a time; a second `call:incoming` while busy is ignored (the server's atomic busy check means it should never arrive); every `call:state` is filtered by `callId`; `active` for a ringing incoming call this tab did not accept = answered elsewhere (ends silently, reason `elsewhere`); a repeat `active` with `type:'video'` during a call is the peer's upgrade; terminal statuses `ended|missed|rejected|busy|failed` end the call with the server's `outcome` (`failed` with no outcome → `failed`).

- [ ] **Step 1: Write the failing test**

Create `src/components/calls/lib/callMachine.test.ts`:

```ts
import { callReducer, IDLE_CALL, isInCall, resyncAction, sameCallId, CallState } from "./callMachine";

const incoming = {
  callId: "c1",
  callUuid: "UUID-1",
  caller: { _id: "u2", name: "Mina", profilePicture: "https://cdn/x.jpg" },
  callType: "video",
  roomName: "call:c1",
};
const lk = { url: "wss://lk.test", token: "tok" };
const ringingIn = () => callReducer(IDLE_CALL, { type: "INCOMING", payload: incoming });
const ringingOut = () =>
  callReducer(IDLE_CALL, {
    type: "OUTGOING",
    callId: "c9",
    callUuid: "U9",
    peer: { id: "u2", name: "Mina", avatar: null },
    callType: "audio",
    lk,
  });
const state = (callId: string, status: string, extra: any = {}) =>
  ({ type: "SERVER_STATE", payload: Object.assign({ callId, status }, extra) } as any);

describe("incoming", () => {
  it("rings with the caller as the peer", () => {
    const s = ringingIn();
    expect(s.phase).toBe("incoming");
    expect(s.direction).toBe("in");
    expect(s.type).toBe("video");
    expect(s.peer).toEqual({ id: "u2", name: "Mina", avatar: "https://cdn/x.jpg" });
    expect(isInCall(s)).toBe(true);
  });

  it("ignores a payload without a callId and a second call while busy", () => {
    expect(callReducer(IDLE_CALL, { type: "INCOMING", payload: { callId: "" } as any })).toBe(IDLE_CALL);
    const s = ringingIn();
    expect(callReducer(s, { type: "INCOMING", payload: Object.assign({}, incoming, { callId: "c2" }) })).toBe(s);
  });

  it("accept: ACCEPTING then ACCEPTED -> connecting with credentials", () => {
    let s = callReducer(ringingIn(), { type: "ACCEPTING" });
    expect(s.accepting).toBe(true);
    // The server's call:state 'active' for our own accept arrives first: no change.
    s = callReducer(s, state("c1", "active"));
    expect(s.phase).toBe("incoming");
    s = callReducer(s, { type: "ACCEPTED", lk });
    expect(s.phase).toBe("connecting");
    expect(s.lk).toEqual(lk);
    expect(s.accepting).toBe(false);
  });

  it("answered elsewhere: 'active' that this tab did not accept ends silently", () => {
    const s = callReducer(ringingIn(), state("C1", "active"));
    expect(s.phase).toBe("ended");
    expect(s.endReason).toBe("elsewhere");
    expect(s.outcome).toBe(null);
  });

  it("caller cancelled / ring timed out -> ended with the server outcome", () => {
    const s = callReducer(ringingIn(), state("c1", "missed", { outcome: "cancelled" }));
    expect(s.phase).toBe("ended");
    expect(s.outcome).toBe("cancelled");
    expect(s.endReason).toBe("remote");
  });

  it("ACCEPT_FAILED clears accepting and keeps ringing", () => {
    const s = callReducer(callReducer(ringingIn(), { type: "ACCEPTING" }), { type: "ACCEPT_FAILED" });
    expect(s.phase).toBe("incoming");
    expect(s.accepting).toBe(false);
  });
});

describe("outgoing", () => {
  it("rings, then 'active' -> connecting; a video type in the same event upgrades", () => {
    const s = callReducer(ringingOut(), state("c9", "active", { type: "video" }));
    expect(s.phase).toBe("connecting");
    expect(s.type).toBe("video");
    expect(s.lk).toEqual(lk);
  });

  it.each([
    ["rejected", "declined", "declined"],
    ["missed", "no_answer", "no_answer"],
    ["busy", "busy", "busy"],
    ["failed", null, "failed"],
  ])("%s -> ended(%s)", (status, outcome, expected) => {
    const s = callReducer(ringingOut(), state("c9", status, { outcome }));
    expect(s.phase).toBe("ended");
    expect(s.outcome).toBe(expected);
  });

  it("drops events for another call", () => {
    const s = ringingOut();
    expect(callReducer(s, state("other", "rejected", { outcome: "declined" }))).toBe(s);
  });
});

describe("in call", () => {
  const live = (): CallState =>
    callReducer(callReducer(ringingOut(), state("c9", "active")), { type: "MEDIA_CONNECTED", at: 1000 });

  it("MEDIA_CONNECTED -> connected and keeps the first timestamp", () => {
    const s = live();
    expect(s.phase).toBe("connected");
    expect(s.connectedAt).toBe(1000);
    expect(callReducer(s, { type: "MEDIA_CONNECTED", at: 5000 }).connectedAt).toBe(1000);
  });

  it("peer mute / video / reconnecting relays, filtered by callId", () => {
    let s = callReducer(live(), { type: "PEER_MUTE", callId: "c9", muted: true });
    s = callReducer(s, { type: "PEER_VIDEO", callId: "c9", on: true });
    s = callReducer(s, { type: "PEER_RECONNECTING", callId: "c9", on: true });
    expect([s.peerMuted, s.peerVideo, s.peerReconnecting]).toEqual([true, true, true]);
    expect(callReducer(s, { type: "PEER_MUTE", callId: "zz", muted: false }).peerMuted).toBe(true);
  });

  it("a repeat 'active' with type video is the peer's upgrade", () => {
    const s = callReducer(live(), state("c9", "active", { type: "video" }));
    expect(s.phase).toBe("connected");
    expect(s.type).toBe("video");
  });

  it("'ended' from the server -> ended(completed)", () => {
    const s = callReducer(live(), state("c9", "ended", { outcome: "completed", duration: 42 }));
    expect(s.outcome).toBe("completed");
  });

  it("LOCAL_END and RESET", () => {
    const s = callReducer(live(), { type: "LOCAL_END", outcome: "completed", reason: "local" });
    expect(s.phase).toBe("ended");
    expect(s.lk).toBe(null);
    expect(callReducer(s, { type: "RESET" })).toEqual(IDLE_CALL);
    expect(callReducer(IDLE_CALL, { type: "LOCAL_END", outcome: null, reason: "local" })).toBe(IDLE_CALL);
  });

  it("a new incoming call is accepted again once the last one ended", () => {
    const ended = callReducer(live(), { type: "LOCAL_END", outcome: "completed", reason: "local" });
    expect(callReducer(ended, { type: "INCOMING", payload: incoming }).phase).toBe("incoming");
  });
});

describe("resyncAction (after a socket reconnect, and on first load)", () => {
  const summary = (status: string, direction = "in", id = "c1") => ({
    id,
    callUuid: "UUID-1",
    type: "audio",
    status,
    direction,
    otherParty: { id: "u2", name: "Mina", avatar: null },
    roomName: `call:${id}`,
    startTime: "2026-10-16T10:00:00Z",
  });

  it("server has no call: a ringing or connecting call here is over", () => {
    expect(resyncAction(ringingIn(), { call: null }, null)).toEqual({ type: "LOCAL_END", outcome: null, reason: "remote" });
    expect(resyncAction(IDLE_CALL, { call: null }, null)).toBe(null);
  });

  it("a call that started ringing while we were offline rings now", () => {
    const a: any = resyncAction(IDLE_CALL, { call: summary("ringing") as any }, null);
    expect(a.type).toBe("INCOMING");
    expect(a.payload.callId).toBe("c1");
    expect(a.payload.caller).toEqual({ _id: "u2", name: "Mina", profilePicture: null });
  });

  it("an outgoing ringing call is not ours to show", () => {
    expect(resyncAction(IDLE_CALL, { call: summary("ringing", "out") as any }, null)).toBe(null);
  });

  it("an active call is rejoined only by the tab that was in it (reload within the 20 s grace)", () => {
    const current: any = { call: summary("active"), token: "fresh", url: "wss://lk" };
    expect(resyncAction(IDLE_CALL, current, null)).toBe(null);
    expect(resyncAction(IDLE_CALL, current, "other")).toBe(null);
    const a: any = resyncAction(IDLE_CALL, current, "C1");
    expect(a.type).toBe("REJOIN");
    expect(a.lk).toEqual({ url: "wss://lk", token: "fresh" });
  });

  it("our ringing banner for a call that is now active elsewhere closes", () => {
    expect(resyncAction(ringingIn(), { call: summary("active") as any }, null)).toEqual({
      type: "LOCAL_END",
      outcome: null,
      reason: "elsewhere",
    });
  });

  it("outgoing call accepted while our socket was down -> connecting", () => {
    const a: any = resyncAction(ringingOut(), { call: summary("active", "out", "c9") as any }, null);
    expect(a).toEqual({ type: "SERVER_STATE", payload: { callId: "c9", status: "active", type: "audio" } });
  });
});

it("sameCallId ignores case and empties", () => {
  expect(sameCallId("ABC", "abc")).toBe(true);
  expect(sameCallId("", "")).toBe(false);
  expect(sameCallId(null, "x")).toBe(false);
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false callMachine
```
Expected: FAIL — `Cannot find module './callMachine'`.

- [ ] **Step 3: Implement**

Create `src/components/calls/lib/callMachine.ts`:

```ts
import { CallType, CurrentCallResponse } from "../../../store/slices/callsSlice";

/**
 * One call at a time, the way the app's CallManager runs it
 * (lib/services/call_manager.dart). Pure: the engine (CallEngine.tsx) feeds
 * it socket events, REST results and LiveKit state, and performs the side
 * effects the new state implies.
 */
export type CallPhase = "idle" | "incoming" | "outgoing" | "connecting" | "connected" | "ended";
export type CallEndOutcome = "completed" | "no_answer" | "cancelled" | "declined" | "busy" | "failed" | null;
/** Why it ended, as far as this tab is concerned. */
export type CallEndReason = "remote" | "local" | "elsewhere" | "failed" | "duplicate";

export interface CallPeer {
  id: string;
  name: string;
  avatar: string | null;
}

export interface LkCredentials {
  url: string;
  token: string;
}

export interface CallState {
  phase: CallPhase;
  callId: string | null;
  callUuid: string | null;
  type: CallType;
  direction: "in" | "out" | null;
  peer: CallPeer | null;
  /** This tab pressed Accept and is waiting for POST /accept. */
  accepting: boolean;
  lk: LkCredentials | null;
  connectedAt: number | null;
  peerMuted: boolean;
  peerVideo: boolean;
  peerReconnecting: boolean;
  outcome: CallEndOutcome;
  endReason: CallEndReason | null;
}

/** socket `call:incoming` (be/controllers/callController.js initiateCall). */
export interface IncomingCallPayload {
  callId: string;
  callUuid?: string | null;
  caller?: { _id?: any; name?: string; profilePicture?: string | null } | null;
  callType?: string;
  roomName?: string;
}

/** socket `call:state` (be/services/callEvents.js statePayload). */
export interface CallStatePayload {
  callId: string;
  status: string;
  outcome?: string | null;
  type?: string;
  duration?: number;
}

export type CallAction =
  | { type: "INCOMING"; payload: IncomingCallPayload }
  | { type: "OUTGOING"; callId: string; callUuid: string | null; peer: CallPeer; callType: CallType; lk: LkCredentials }
  | { type: "ACCEPTING" }
  | { type: "ACCEPT_FAILED" }
  | { type: "ACCEPTED"; lk: LkCredentials }
  | { type: "SERVER_STATE"; payload: CallStatePayload }
  | { type: "MEDIA_CONNECTED"; at: number }
  | { type: "PEER_MUTE"; callId: string; muted: boolean }
  | { type: "PEER_VIDEO"; callId: string; on: boolean }
  | { type: "PEER_RECONNECTING"; callId: string; on: boolean }
  | { type: "TYPE_VIDEO" }
  | { type: "REJOIN"; callId: string; callUuid: string | null; peer: CallPeer | null; callType: CallType; direction: "in" | "out"; lk: LkCredentials }
  | { type: "LOCAL_END"; outcome: CallEndOutcome; reason: CallEndReason }
  | { type: "RESET" };

export const IDLE_CALL: CallState = {
  phase: "idle",
  callId: null,
  callUuid: null,
  type: "audio",
  direction: null,
  peer: null,
  accepting: false,
  lk: null,
  connectedAt: null,
  peerMuted: false,
  peerVideo: false,
  peerReconnecting: false,
  outcome: null,
  endReason: null,
};

const TERMINAL = ["ended", "missed", "rejected", "busy", "failed"];
const OUTCOMES = ["completed", "no_answer", "cancelled", "declined", "busy"];

export function sameCallId(a: string | null | undefined, b: string | null | undefined): boolean {
  if (!a || !b) return false;
  return String(a).toLowerCase() === String(b).toLowerCase();
}

export function isInCall(s: CallState): boolean {
  return s.phase !== "idle" && s.phase !== "ended";
}

const matches = (s: CallState, callId: string | null | undefined) =>
  sameCallId(s.callId, callId) || sameCallId(s.callUuid, callId);

const asType = (t: any): CallType => (t === "video" ? "video" : "audio");

function end(s: CallState, outcome: CallEndOutcome, reason: CallEndReason): CallState {
  return Object.assign({}, s, {
    phase: "ended" as CallPhase,
    outcome,
    endReason: reason,
    accepting: false,
    lk: null,
    peerReconnecting: false,
  });
}

function peerFromCaller(caller: IncomingCallPayload["caller"]): CallPeer | null {
  if (!caller || !caller._id) return null;
  return { id: String(caller._id), name: caller.name || "", avatar: caller.profilePicture || null };
}

export function callReducer(s: CallState, a: CallAction): CallState {
  switch (a.type) {
    case "INCOMING": {
      const p = a.payload;
      if (!p || !p.callId) return s;
      if (isInCall(s)) return s;
      if (s.phase === "ended" && matches(s, p.callId)) return s;
      return Object.assign({}, IDLE_CALL, {
        phase: "incoming" as CallPhase,
        callId: String(p.callId),
        callUuid: p.callUuid || null,
        type: asType(p.callType),
        direction: "in" as "in",
        peer: peerFromCaller(p.caller),
      });
    }
    case "OUTGOING":
      if (isInCall(s)) return s;
      return Object.assign({}, IDLE_CALL, {
        phase: "outgoing" as CallPhase,
        callId: a.callId,
        callUuid: a.callUuid,
        type: a.callType,
        direction: "out" as "out",
        peer: a.peer,
        lk: a.lk,
      });
    case "ACCEPTING":
      return s.phase === "incoming" ? Object.assign({}, s, { accepting: true }) : s;
    case "ACCEPT_FAILED":
      return s.phase === "incoming" ? Object.assign({}, s, { accepting: false }) : s;
    case "ACCEPTED":
      if (s.phase !== "incoming" || !s.accepting) return s;
      return Object.assign({}, s, { phase: "connecting" as CallPhase, lk: a.lk, accepting: false });
    case "SERVER_STATE": {
      const p = a.payload;
      if (!p || !matches(s, p.callId) || !isInCall(s)) return s;
      if (p.status === "active") {
        if (s.phase === "outgoing") {
          return Object.assign({}, s, {
            phase: "connecting" as CallPhase,
            type: p.type === "video" ? "video" : s.type,
          });
        }
        if (s.phase === "incoming") {
          if (s.accepting) return s;
          return end(s, null, "elsewhere");
        }
        return p.type === "video" && s.type !== "video" ? Object.assign({}, s, { type: "video" as CallType }) : s;
      }
      if (TERMINAL.indexOf(p.status) >= 0) {
        const o = p.outcome && OUTCOMES.indexOf(p.outcome) >= 0 ? (p.outcome as CallEndOutcome) : null;
        return end(s, o || (p.status === "failed" ? "failed" : null), "remote");
      }
      return s;
    }
    case "MEDIA_CONNECTED":
      if (s.phase !== "connecting" && s.phase !== "connected") return s;
      return Object.assign({}, s, {
        phase: "connected" as CallPhase,
        connectedAt: s.connectedAt || a.at,
        peerReconnecting: false,
      });
    case "PEER_MUTE":
      return isInCall(s) && matches(s, a.callId) ? Object.assign({}, s, { peerMuted: a.muted }) : s;
    case "PEER_VIDEO":
      return isInCall(s) && matches(s, a.callId) ? Object.assign({}, s, { peerVideo: a.on }) : s;
    case "PEER_RECONNECTING":
      return isInCall(s) && matches(s, a.callId) ? Object.assign({}, s, { peerReconnecting: a.on }) : s;
    case "TYPE_VIDEO":
      return s.phase === "connecting" || s.phase === "connected"
        ? Object.assign({}, s, { type: "video" as CallType })
        : s;
    case "REJOIN":
      if (s.phase !== "idle" && s.phase !== "ended") return s;
      return Object.assign({}, IDLE_CALL, {
        phase: "connecting" as CallPhase,
        callId: a.callId,
        callUuid: a.callUuid,
        type: a.callType,
        direction: a.direction,
        peer: a.peer,
        lk: a.lk,
      });
    case "LOCAL_END":
      return isInCall(s) ? end(s, a.outcome, a.reason) : s;
    case "RESET":
      return IDLE_CALL;
    default:
      return s;
  }
}

/**
 * What GET /calls/current says this tab should do after its socket came back
 * (Phase 3 connectionEpoch) or on first load. `rejoinCallId` is the call this
 * tab was in before a reload (sessionStorage, set by the engine).
 */
export function resyncAction(
  s: CallState,
  current: CurrentCallResponse | null | undefined,
  rejoinCallId: string | null
): CallAction | null {
  const c = current ? current.call : null;
  if (!c) {
    return isInCall(s) ? { type: "LOCAL_END", outcome: null, reason: "remote" } : null;
  }
  if (c.status === "ringing" && c.direction === "in" && !isInCall(s)) {
    return {
      type: "INCOMING",
      payload: {
        callId: c.id,
        callUuid: c.callUuid,
        caller: c.otherParty
          ? { _id: c.otherParty.id, name: c.otherParty.name, profilePicture: c.otherParty.avatar }
          : null,
        callType: c.type,
        roomName: c.roomName,
      },
    };
  }
  if (c.status === "active") {
    if (s.phase === "idle" && sameCallId(rejoinCallId, c.id) && current && current.token && current.url) {
      return {
        type: "REJOIN",
        callId: c.id,
        callUuid: c.callUuid,
        peer: c.otherParty ? { id: c.otherParty.id, name: c.otherParty.name, avatar: c.otherParty.avatar } : null,
        callType: c.type,
        direction: c.direction,
        lk: { url: current.url, token: current.token },
      };
    }
    if (s.phase === "incoming" && matches(s, c.id) && !s.accepting) {
      return { type: "LOCAL_END", outcome: null, reason: "elsewhere" };
    }
    if (s.phase === "outgoing" && matches(s, c.id)) {
      return { type: "SERVER_STATE", payload: { callId: c.id, status: "active", type: c.type } };
    }
  }
  return null;
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false callMachine
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/calls/lib/callMachine.ts src/components/calls/lib/callMachine.test.ts docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): pure call state machine with resync rules

One call at a time; call:state filtered by callId; "active" for a ring
this tab did not accept closes it (answered elsewhere); a repeat active
with type video is the peer's upgrade; terminal states carry the
server's outcome. resyncAction turns GET /calls/current into the action
a reconnected or reloaded tab needs.

Still open (Phase 4 calls): P4-CALL-4 … P4-CALL-11, I18N, PUSH.
MSG
```

---

### Task P4-CALL-4: Eager `IncomingCallHost` + call bridge in App.tsx; the engine is a lazy chunk

**Files:**
- Create: `src/components/calls/callBridge.ts`, `src/components/calls/IncomingCallHost.tsx`, `src/components/calls/CallEngine.tsx` (placeholder, filled by P4-CALL-5)
- Create: `src/components/calls/IncomingCallHost.test.tsx`, `src/components/calls/callsBundle.test.ts`
- Modify: `src/App.tsx` (import + `<IncomingCallHost />` right after `<AnnouncementSurfaces />`)

**Interfaces:**
- Consumes: `useWebFlag("webCallsEnabled")` (P4-0), `state.auth.userInfo.token`.
- Produces:
  - `callBridge.ts`: `interface CallApi { startCall(peer: { id: string; name: string; avatar: string | null }, type: "audio" | "video"): void; inCall: boolean }`; `registerCallApi(api: CallApi | null): void`; `getCallApi(): CallApi | null`; `useCallApi(): CallApi | null` (re-renders on every register). The bridge is how eager/lazy code anywhere (chat header, profile, call card, history page) reaches the lazily loaded engine without a context provider wrapping the app (a lazy provider would suspend the whole page while its chunk loads).
  - `IncomingCallHost` default export (no props): renders nothing while signed out or while `webCallsEnabled` is off — **except** that an engine with a call in progress stays mounted if the flag flips off mid-call; otherwise renders the lazy `CallEngine` (chunk `calls`). A failed chunk load leaves calls inert (renders nothing) instead of reaching the route `errorElement`.
  - `CallEngine` default export: the engine (P4-CALL-5). In this task a placeholder that registers `{ startCall: () => {}, inCall: false }` and renders `null`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/calls/IncomingCallHost.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, act } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { mockAppConfig, ALL_WEB_FLAGS_OFF } from "../../utils/testing/mockWebFlags";
import { registerCallApi } from "./callBridge";
import IncomingCallHost from "./IncomingCallHost";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
const mockEngineMounts = jest.fn();
jest.mock("./CallEngine", () => ({
  __esModule: true,
  default: () => {
    mockEngineMounts();
    return <div data-testid="call-engine" />;
  },
}));

function renderHost(token: string | null) {
  const store = configureStore({
    reducer: { auth: (s: any = { userInfo: token ? { token, user: { _id: "me" } } : null }) => s },
  });
  return render(
    <Provider store={store}>
      <IncomingCallHost />
    </Provider>
  );
}

beforeEach(() => {
  mockEngineMounts.mockClear();
  registerCallApi(null);
});

it("loads nothing while the flag is off", async () => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderHost("tok");
  await act(async () => {});
  expect(screen.queryByTestId("call-engine")).not.toBeInTheDocument();
  expect(mockEngineMounts).not.toHaveBeenCalled();
});

it("loads nothing while app-config is loading or failed", async () => {
  mockAppConfig("loading");
  const { unmount } = renderHost("tok");
  await act(async () => {});
  expect(screen.queryByTestId("call-engine")).not.toBeInTheDocument();
  unmount();
  mockAppConfig("error");
  renderHost("tok");
  await act(async () => {});
  expect(screen.queryByTestId("call-engine")).not.toBeInTheDocument();
});

it("loads nothing for a signed-out visitor, flag on or not", async () => {
  mockAppConfig({ webCallsEnabled: true });
  renderHost(null);
  await act(async () => {});
  expect(screen.queryByTestId("call-engine")).not.toBeInTheDocument();
});

it("loads the engine when signed in and the flag is on", async () => {
  mockAppConfig({ webCallsEnabled: true });
  renderHost("tok");
  expect(await screen.findByTestId("call-engine")).toBeInTheDocument();
});

it("keeps a call in progress when the flag flips off mid-call", async () => {
  mockAppConfig({ webCallsEnabled: true });
  const { rerender } = renderHost("tok");
  await screen.findByTestId("call-engine");
  act(() => registerCallApi({ startCall: () => {}, inCall: true }));
  mockAppConfig({ webCallsEnabled: false });
  rerender(
    <Provider store={configureStore({ reducer: { auth: (s: any = { userInfo: { token: "tok" } }) => s } })}>
      <IncomingCallHost />
    </Provider>
  );
  expect(screen.getByTestId("call-engine")).toBeInTheDocument();
});
```

Create `src/components/calls/callsBundle.test.ts`:

```ts
/**
 * @jest-environment node
 */
// Source-level guard, like src/seo/eagerGraph.test.ts: App.tsx is eager, so
// whatever IncomingCallHost / callBridge import statically lands in main.js
// for every visitor. The engine, the REST slice and the LiveKit wrapper must
// only be reachable through import().
import fs from "fs";
import path from "path";

const read = (p: string) => fs.readFileSync(path.join(__dirname, p), "utf8");
const staticImports = (src: string) =>
  (src.match(/^\s*import\s[^;]*?from\s+["']([^"']+)["']/gm) || []).map((l) =>
    l.replace(/^[\s\S]*from\s+["']([^"']+)["'][\s\S]*$/, "$1")
  );

it.each(["IncomingCallHost.tsx", "callBridge.ts"])("%s imports nothing heavy statically", (file) => {
  const imports = staticImports(read(file));
  imports.forEach((spec) => {
    expect(spec).not.toMatch(/CallEngine|callsSlice|lib\/livekit|livekit-client|socket\.io-client/);
  });
});

it("IncomingCallHost reaches the engine only through import()", () => {
  expect(read("IncomingCallHost.tsx")).toMatch(/import\(\s*\/\*\s*webpackChunkName:\s*"calls"\s*\*\/\s*"\.\/CallEngine"\s*\)/);
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false IncomingCallHost callsBundle
```
Expected: FAIL — `./callBridge` / `./IncomingCallHost` cannot be resolved; `callsBundle` cannot read `IncomingCallHost.tsx`.

- [ ] **Step 3: Implement**

Create `src/components/calls/callBridge.ts`:

```ts
import { useEffect, useState } from "react";

/**
 * The seam between the always-loaded parts of the site (chat header, profile,
 * call card, history page) and the lazily loaded call engine. The engine
 * registers itself here when it mounts and unregisters when it unmounts; a
 * null api means "calls are not available right now" and every entry point
 * hides itself.
 */
export interface CallApi {
  startCall(peer: { id: string; name: string; avatar: string | null }, type: "audio" | "video"): void;
  /** A call is ringing or in progress in this tab. */
  inCall: boolean;
}

let current: CallApi | null = null;
const listeners: Array<() => void> = [];

export function registerCallApi(api: CallApi | null): void {
  current = api;
  listeners.slice().forEach((l) => l());
}

export function getCallApi(): CallApi | null {
  return current;
}

export function useCallApi(): CallApi | null {
  const [, setTick] = useState(0);
  useEffect(() => {
    const listener = () => setTick((n) => n + 1);
    listeners.push(listener);
    return () => {
      const i = listeners.indexOf(listener);
      if (i >= 0) listeners.splice(i, 1);
    };
  }, []);
  return current;
}
```

Create `src/components/calls/IncomingCallHost.tsx`:

```tsx
import React from "react";
import { useSelector } from "react-redux";
import { useWebFlag } from "../../utils/webFlags";
import { useCallApi } from "./callBridge";

// The engine, the calls REST slice, the call screens and (through them) the
// LiveKit wrapper live in the lazy "calls" chunk. A chunk that fails to load
// leaves calls inert instead of throwing to the route's errorElement, which
// would replace the whole page with a reload prompt.
const CallEngine = React.lazy(() =>
  import(/* webpackChunkName: "calls" */ "./CallEngine").catch(() => ({ default: () => null }))
);

/**
 * Mounted once in App.tsx. Listens for incoming calls in every open tab of a
 * signed-in user while WEB_CALLS_ENABLED is on (spec §3 Phase 4 "Calls").
 * A flag flipped off mid-call does not end the call: the engine stays mounted
 * until the call is over, then unmounts.
 */
const IncomingCallHost: React.FC = () => {
  const token = useSelector((state: any) => (state.auth && state.auth.userInfo ? state.auth.userInfo.token : null));
  const enabled = useWebFlag("webCallsEnabled");
  const api = useCallApi();
  const keepForCall = !!api && api.inCall;
  if (!token) return null;
  if (!enabled && !keepForCall) return null;
  return (
    <React.Suspense fallback={null}>
      <CallEngine />
    </React.Suspense>
  );
};

export default IncomingCallHost;
```

Create the placeholder `src/components/calls/CallEngine.tsx` (P4-CALL-5 replaces it):

```tsx
import { useEffect } from "react";
import { registerCallApi } from "./callBridge";

const CallEngine = () => {
  useEffect(() => {
    registerCallApi({ startCall: () => {}, inCall: false });
    return () => registerCallApi(null);
  }, []);
  return null;
};

export default CallEngine;
```

`src/App.tsx`: add the import below `import AnnouncementSurfaces from "./components/announcements/AnnouncementSurfaces";`

```tsx
import IncomingCallHost from "./components/calls/IncomingCallHost";
```

and render it right after `<AnnouncementSurfaces />`:

```tsx
        <AnnouncementSurfaces />
        {/* Incoming web calls (Phase 4, dark behind WEB_CALLS_ENABLED). Renders
            nothing for signed-out visitors and while the flag is off; the
            engine itself is a lazy chunk. */}
        <IncomingCallHost />
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false IncomingCallHost callsBundle eagerGraph App renderRoute
```
Expected: all pass. `renderRoute` (prerender) stays green: signed out, `IncomingCallHost` renders `null`.

- [ ] **Step 5: Commit**

```bash
git add src/components/calls/callBridge.ts src/components/calls/IncomingCallHost.tsx src/components/calls/CallEngine.tsx src/components/calls/IncomingCallHost.test.tsx src/components/calls/callsBundle.test.ts src/App.tsx docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): incoming-call host in App, engine behind a lazy chunk

IncomingCallHost renders nothing signed out or while webCallsEnabled is
off (or app-config is loading/failed); otherwise it lazy-loads the call
engine, which registers itself on a small bridge the entry points read.
A call in progress survives the flag flipping off. A failed chunk
leaves calls inert.

Still open (Phase 4 calls): P4-CALL-5 … P4-CALL-11, I18N, PUSH.
MSG
```

---

### Task P4-CALL-5: Call engine — socket events, other tabs, resync on reconnect and after a reload

**Files:**
- Create: `src/components/calls/useCallEngine.ts`, `src/components/calls/useCallEngine.test.tsx`
- Create: `src/components/calls/testing/fakeSocket.ts`, `src/components/calls/testing/fakeBroadcastChannel.ts`, `src/components/calls/testing/callsSliceMock.ts`
- Modify: `src/components/calls/CallEngine.tsx` (replace the placeholder: use the hook, register the bridge)
- Modify: `src/utils/locales/eng.json` (`calls.notices.*`)

**Interfaces:**
- Consumes: `useSocket()` → `{ socket, connectionEpoch }` (P3-CHAT-7); socket events listed in the unit facts; `callsSlice` hooks (P4-CALL-1); `callReducer`, `resyncAction`, `isInCall`, `sameCallId` (P4-CALL-3); `callDeviceId`, `preflightMedia`, `classifyCallError`, `callErrorText`, `mediaProblemText` (P4-CALL-2); `registerCallApi` (P4-CALL-4); `state.auth.userInfo.token` and `BASE_URL`/`CALLS_URL` for the `pagehide` beacon.
- Produces: `useCallEngine(): CallEngineApi` with
  ```ts
  interface CallEngineApi {
    state: CallState;
    dispatch(a: CallAction): void;            // used by the media hook (P4-CALL-8)
    accept(): Promise<void>;
    decline(message?: string): Promise<void>;
    hangUp(): Promise<void>;                  // incoming → decline; outgoing → cancel; connecting/connected → end
    startCall(peer: CallPeer, type: CallType): Promise<void>;   // body added in P4-CALL-7 (here: no-op)
    cameraAllowed: boolean;                   // last preflight said the camera may be used
    notice: string | null;                    // one localized line (toast-like), cleared by clearNotice()
    clearNotice(): void;
  }
  ```
  `CALL_REJOIN_KEY = "bt.call.active"` (sessionStorage: the call this tab is in, for a reload rejoin), `CALL_CHANNEL = "bt-calls"` (BroadcastChannel message `{ kind: "handled"; callId: string; deviceId: string }`), `ENDED_LINGER_MS = 2500`, `RING_SAFETY_MS = 60000`.
- Behaviour:
  - Listens to `call:incoming`, `call:state`, `call:mute`, `call:video-toggle`, `call:peer-reconnecting`, `call:peer-reconnected`, `call:failed`; never to the legacy `call:accepted` / `call:declined` / `call:ended`.
  - On mount and on every `connectionEpoch` change: `GET /calls/current` → `resyncAction(state, data, sessionStorage[CALL_REJOIN_KEY])`.
  - Accept: preflight first (mic required; a denied mic leaves the call ringing and shows how to unblock); then tells other tabs (`handled`), `POST /accept {deviceId}`; `409 CALL_STATE` → ends quietly (answered elsewhere / timed out).
  - Decline: ends locally at once, tells other tabs, `POST /decline {deviceId, message?}`; `messageDelivered === false` → notice "Your message couldn't be delivered."
  - `pagehide` while an **outgoing** call is ringing → `fetch(…/end, {method:'POST', keepalive:true})` so the callee's phone stops ringing. An active call is not ended on `pagehide`: the LiveKit webhook ends it after 20 s, and a reload within that window rejoins (`CALL_REJOIN_KEY`).
  - A ring with no news for 60 s ends locally (the server's own timeout is 45 s; this covers a lost socket event).
  - `ended` lingers 2.5 s (outcome shown), then resets.

- [ ] **Step 1: Test helpers**

Create `src/components/calls/testing/fakeSocket.ts`:

```ts
/** A socket.io client stand-in: records handlers and emits; `serverEmit` plays the backend. */
export function makeFakeSocket() {
  const handlers: { [event: string]: Array<(data: any) => void> } = {};
  const socket: any = {
    connected: true,
    emitted: [] as Array<{ event: string; data: any }>,
    on: jest.fn((event: string, fn: (data: any) => void) => {
      (handlers[event] = handlers[event] || []).push(fn);
    }),
    off: jest.fn((event: string, fn: (data: any) => void) => {
      handlers[event] = (handlers[event] || []).filter((h) => h !== fn);
    }),
    emit: jest.fn((event: string, data: any, ack?: (r: any) => void) => {
      socket.emitted.push({ event, data });
      if (typeof ack === "function") ack({ status: "success" });
    }),
    serverEmit(event: string, data: any) {
      (handlers[event] || []).slice().forEach((h) => h(data));
    },
    listening(event: string) {
      return (handlers[event] || []).length;
    },
  };
  return socket;
}
```

Create `src/components/calls/testing/fakeBroadcastChannel.ts`:

```ts
/** jsdom has no BroadcastChannel. Same-name instances deliver to each other (never to themselves). */
export class FakeBroadcastChannel {
  static all: FakeBroadcastChannel[] = [];
  name: string;
  onmessage: ((e: { data: any }) => void) | null = null;
  closed = false;
  constructor(name: string) {
    this.name = name;
    FakeBroadcastChannel.all.push(this);
  }
  postMessage(data: any) {
    FakeBroadcastChannel.all
      .filter((c) => c !== this && c.name === this.name && !c.closed)
      .forEach((c) => c.onmessage && c.onmessage({ data }));
  }
  close() {
    this.closed = true;
  }
}

export function installFakeBroadcastChannel() {
  FakeBroadcastChannel.all = [];
  (window as any).BroadcastChannel = FakeBroadcastChannel;
}

/** A message from "another tab". */
export function fromOtherTab(data: any) {
  new FakeBroadcastChannel("bt-calls").postMessage(data);
}
```

Create `src/components/calls/testing/callsSliceMock.ts`:

```ts
/**
 * jest.mock("../../store/slices/callsSlice", () =>
 *   require("./testing/callsSliceMock").callsSliceMock());
 * Each mutation is a jest.fn returning { unwrap }; set results per test with
 * callsApi.<name>.mockReturnValue(ok(...)) / fail(...).
 */
export const ok = (value: any) => ({ unwrap: () => Promise.resolve(value) });
export const fail = (error: any) => ({ unwrap: () => Promise.reject(error) });

export const callsApi = {
  initiate: jest.fn(() => ok({ data: {} })),
  accept: jest.fn(() => ok({ data: {} })),
  decline: jest.fn(() => ok({ data: {} })),
  end: jest.fn(() => ok({ data: {} })),
  upgrade: jest.fn(() => ok({ data: {} })),
  current: jest.fn(() => ok({ call: null })),
  markSeen: jest.fn(() => ok({})),
};

export function resetCallsApi() {
  callsApi.initiate.mockImplementation(() => ok({ data: {} }));
  callsApi.accept.mockImplementation(() => ok({ data: {} }));
  callsApi.decline.mockImplementation(() => ok({ data: {} }));
  callsApi.end.mockImplementation(() => ok({ data: {} }));
  callsApi.upgrade.mockImplementation(() => ok({ data: {} }));
  callsApi.current.mockImplementation(() => ok({ call: null }));
  callsApi.markSeen.mockImplementation(() => ok({}));
  Object.keys(callsApi).forEach((k) => (callsApi as any)[k].mockClear());
}

export function callsSliceMock() {
  return {
    useInitiateCallMutation: () => [callsApi.initiate, { isLoading: false }],
    useAcceptCallMutation: () => [callsApi.accept, { isLoading: false }],
    useDeclineCallMutation: () => [callsApi.decline, { isLoading: false }],
    useEndCallMutation: () => [callsApi.end, { isLoading: false }],
    useUpgradeCallMutation: () => [callsApi.upgrade, { isLoading: false }],
    useLazyGetCurrentCallQuery: () => [callsApi.current, {}],
    useMarkMissedCallsSeenMutation: () => [callsApi.markSeen, {}],
  };
}
```

- [ ] **Step 2: Write the failing test**

Create `src/components/calls/useCallEngine.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, act, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { makeFakeSocket } from "./testing/fakeSocket";
import { installFakeBroadcastChannel, fromOtherTab, FakeBroadcastChannel } from "./testing/fakeBroadcastChannel";
import { callsApi, resetCallsApi, ok, fail } from "./testing/callsSliceMock";
import { useCallEngine, CallEngineApi, CALL_REJOIN_KEY } from "./useCallEngine";
import { getCallApi } from "./callBridge";

jest.mock("../../store/slices/callsSlice", () => require("./testing/callsSliceMock").callsSliceMock());
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockPreflight = jest.fn();
jest.mock("./lib/mediaPreflight", () => ({ preflightMedia: (...a: any[]) => mockPreflight(...a) }));
jest.mock("./lib/deviceId", () => ({ callDeviceId: () => "web-tab1" }));
let mockSocketCtx: any;
jest.mock("../chat/hooks/useSocket", () => ({ useSocket: () => mockSocketCtx }));

let api: CallEngineApi;
function Harness() {
  api = useCallEngine();
  return null;
}
function mount() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { token: "tok", user: { _id: "me" } } }) => s } });
  const view = render(
    <Provider store={store}>
      <Harness />
    </Provider>
  );
  return Object.assign(view, {
    rerenderWith(ctx: any) {
      mockSocketCtx = ctx;
      view.rerender(
        <Provider store={store}>
          <Harness />
        </Provider>
      );
    },
  });
}

const incoming = {
  callId: "c1",
  callUuid: "U1",
  caller: { _id: "u2", name: "Mina", profilePicture: null },
  callType: "audio",
  roomName: "call:c1",
};

let socket: any;
beforeEach(() => {
  resetCallsApi();
  // GET /calls/current stays pending unless a test says otherwise: a resync
  // landing in the middle of a test would end the call it is driving.
  callsApi.current.mockImplementation(() => ({ unwrap: () => new Promise(() => {}) }));
  installFakeBroadcastChannel();
  sessionStorage.clear();
  socket = makeFakeSocket();
  mockSocketCtx = { socket, isConnected: true, emit: jest.fn(), connectionEpoch: 0 };
  mockPreflight.mockResolvedValue({ mic: "ok", camera: null });
});

it("listens to the new call events only (never the legacy ones)", () => {
  mount();
  ["call:incoming", "call:state", "call:mute", "call:video-toggle", "call:peer-reconnecting", "call:peer-reconnected", "call:failed"].forEach(
    (e) => expect(socket.listening(e)).toBe(1)
  );
  ["call:accepted", "call:declined", "call:ended"].forEach((e) => expect(socket.listening(e)).toBe(0));
});

it("rings on call:incoming and registers inCall on the bridge", async () => {
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  expect(api.state.phase).toBe("incoming");
  expect(api.state.peer).toEqual({ id: "u2", name: "Mina", avatar: null });
  expect(getCallApi()!.inCall).toBe(true);
});

it("accept: preflight, tells other tabs, POST /accept with this tab's device id", async () => {
  const other = new FakeBroadcastChannel("bt-calls");
  const seen: any[] = [];
  other.onmessage = (e) => seen.push(e.data);
  callsApi.accept.mockReturnValue(ok({ data: { token: "rtok", url: "wss://lk", roomName: "call:c1" } }));
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  await act(async () => {
    await api.accept();
  });
  expect(mockPreflight).toHaveBeenCalledWith(false);
  expect(seen).toEqual([{ kind: "handled", callId: "c1", deviceId: "web-tab1" }]);
  expect(callsApi.accept).toHaveBeenCalledWith({ callId: "c1", deviceId: "web-tab1" });
  expect(api.state.phase).toBe("connecting");
  expect(api.state.lk).toEqual({ url: "wss://lk", token: "rtok" });
  expect(sessionStorage.getItem(CALL_REJOIN_KEY)).toBe("c1");
});

it("accept with the mic denied keeps ringing and says how to unblock", async () => {
  mockPreflight.mockResolvedValue({ mic: "denied", camera: null });
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  await act(async () => {
    await api.accept();
  });
  expect(callsApi.accept).not.toHaveBeenCalled();
  expect(api.state.phase).toBe("incoming");
  expect(api.notice).toMatch(/can't use your microphone/);
});

it("accept that lost the race (409 CALL_STATE) ends quietly", async () => {
  callsApi.accept.mockReturnValue(fail({ status: 409, data: { code: "CALL_STATE", status: "active" } }));
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  await act(async () => {
    await api.accept();
  });
  expect(api.state.phase).toBe("ended");
  expect(api.state.endReason).toBe("elsewhere");
  expect(api.notice).toBe(null);
});

it("answered in another tab: the BroadcastChannel closes the ring before the socket says so", () => {
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  act(() => fromOtherTab({ kind: "handled", callId: "c1", deviceId: "web-tab2" }));
  expect(api.state.phase).toBe("ended");
  expect(api.state.endReason).toBe("elsewhere");
});

it("answered on the phone: call:state active closes the ring", () => {
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  act(() => socket.serverEmit("call:state", { callId: "c1", status: "active", type: "audio", by: "u-me" }));
  expect(api.state.endReason).toBe("elsewhere");
});

it("decline with a message: ends at once, POSTs it, tells the user when it was not delivered", async () => {
  callsApi.decline.mockReturnValue(ok({ data: { messageDelivered: false } }));
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  await act(async () => {
    await api.decline("Can't talk now. Text me?");
  });
  expect(callsApi.decline).toHaveBeenCalledWith({ callId: "c1", deviceId: "web-tab1", message: "Can't talk now. Text me?" });
  expect(api.state.phase).toBe("ended");
  expect(api.state.outcome).toBe("declined");
  expect(api.notice).toBe("Your message couldn't be delivered.");
});

it("resyncs from GET /calls/current on mount and after every reconnect", async () => {
  callsApi.current.mockReturnValue(
    ok({
      call: { id: "c7", callUuid: "U7", type: "video", status: "ringing", direction: "in", otherParty: { id: "u3", name: "Jun", avatar: null }, roomName: "call:c7", startTime: "x" },
    })
  );
  const view = mount();
  await waitFor(() => expect(api.state.phase).toBe("incoming"));
  expect(callsApi.current).toHaveBeenCalledTimes(1);
  callsApi.current.mockReturnValue(ok({ call: null }));
  view.rerenderWith(Object.assign({}, mockSocketCtx, { connectionEpoch: 1 }));
  await waitFor(() => expect(api.state.phase).toBe("ended"));
  expect(callsApi.current).toHaveBeenCalledTimes(2);
});

it("a reload during a call rejoins it with a fresh token", async () => {
  sessionStorage.setItem(CALL_REJOIN_KEY, "c5");
  callsApi.current.mockReturnValue(
    ok({
      call: { id: "c5", callUuid: null, type: "audio", status: "active", direction: "out", otherParty: { id: "u2", name: "Mina", avatar: null }, roomName: "call:c5", startTime: "x" },
      token: "fresh",
      url: "wss://lk",
    })
  );
  mount();
  await waitFor(() => expect(api.state.phase).toBe("connecting"));
  expect(api.state.lk).toEqual({ url: "wss://lk", token: "fresh" });
});

it("relays: peer mute / video / reconnecting / failed", () => {
  mount();
  act(() => api.dispatch({ type: "REJOIN", callId: "c5", callUuid: null, peer: null, callType: "audio", direction: "out", lk: { url: "u", token: "t" } }));
  act(() => socket.serverEmit("call:mute", { callId: "c5", userId: "u2", isMuted: true }));
  act(() => socket.serverEmit("call:video-toggle", { callId: "c5", userId: "u2", isVideoEnabled: true }));
  act(() => socket.serverEmit("call:peer-reconnecting", { callId: "c5", userId: "u2" }));
  expect([api.state.peerMuted, api.state.peerVideo, api.state.peerReconnecting]).toEqual([true, true, true]);
  act(() => socket.serverEmit("call:peer-reconnected", { callId: "c5", userId: "u2" }));
  expect(api.state.peerReconnecting).toBe(false);
  act(() => socket.serverEmit("call:failed", { callId: "c5", reason: "Connection failed" }));
  expect(api.state.outcome).toBe("failed");
});

it("ended lingers, then resets and clears the rejoin key", () => {
  jest.useFakeTimers();
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  act(() => socket.serverEmit("call:state", { callId: "c1", status: "missed", outcome: "cancelled" }));
  expect(api.state.phase).toBe("ended");
  act(() => {
    jest.advanceTimersByTime(2500);
  });
  expect(api.state.phase).toBe("idle");
  expect(sessionStorage.getItem(CALL_REJOIN_KEY)).toBe(null);
  jest.useRealTimers();
});

it("a ring with no news for 60 s ends locally", () => {
  jest.useFakeTimers();
  mount();
  act(() => socket.serverEmit("call:incoming", incoming));
  act(() => {
    jest.advanceTimersByTime(60000);
  });
  expect(api.state.phase).toBe("ended");
  jest.useRealTimers();
});

it("pagehide while an outgoing call rings cancels it with a keepalive request", () => {
  const fetchSpy = jest.fn(() => Promise.resolve(new Response("{}")));
  (global as any).fetch = fetchSpy;
  mount();
  act(() =>
    api.dispatch({ type: "OUTGOING", callId: "c9", callUuid: null, peer: { id: "u2", name: "Mina", avatar: null }, callType: "audio", lk: { url: "u", token: "t" } })
  );
  act(() => {
    window.dispatchEvent(new Event("pagehide"));
  });
  expect(fetchSpy).toHaveBeenCalledTimes(1);
  const [url, init] = (fetchSpy.mock.calls[0] as any) as [string, any];
  expect(url).toMatch(/\/api\/v1\/calls\/c9\/end$/);
  expect(init.method).toBe("POST");
  expect(init.keepalive).toBe(true);
  expect(init.headers.Authorization).toBe("Bearer tok");
  expect(JSON.parse(init.body)).toEqual({ deviceId: "web-tab1" });
});

it("unregisters from the bridge and stops listening on unmount", () => {
  const view = mount();
  view.unmount();
  expect(getCallApi()).toBe(null);
  expect(socket.listening("call:incoming")).toBe(0);
});
```

- [ ] **Step 3: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false useCallEngine
```
Expected: FAIL — `Cannot find module './useCallEngine'`.

- [ ] **Step 4: Implement**

Create `src/components/calls/useCallEngine.ts`:

```ts
import { useCallback, useEffect, useReducer, useRef, useState } from "react";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { useSocket } from "../chat/hooks/useSocket";
import {
  useAcceptCallMutation,
  useDeclineCallMutation,
  useEndCallMutation,
  useLazyGetCurrentCallQuery,
  CallType,
} from "../../store/slices/callsSlice";
import { BASE_URL, CALLS_URL } from "../../constants";
import { callReducer, IDLE_CALL, isInCall, resyncAction, sameCallId, CallAction, CallPeer, CallState } from "./lib/callMachine";
import { callDeviceId } from "./lib/deviceId";
import { preflightMedia } from "./lib/mediaPreflight";
import { classifyCallError, mediaProblemText } from "./lib/callErrors";
import { registerCallApi } from "./callBridge";

export const CALL_REJOIN_KEY = "bt.call.active";
export const CALL_CHANNEL = "bt-calls";
export const ENDED_LINGER_MS = 2500;
export const RING_SAFETY_MS = 60000;

export interface CallEngineApi {
  state: CallState;
  dispatch(a: CallAction): void;
  accept(): Promise<void>;
  decline(message?: string): Promise<void>;
  hangUp(): Promise<void>;
  startCall(peer: CallPeer, type: CallType): Promise<void>;
  cameraAllowed: boolean;
  notice: string | null;
  clearNotice(): void;
  /** Set by P4-CALL-7: shows a call error dialog. */
  setNotice(text: string | null): void;
}

function readRejoin(): string | null {
  try {
    return sessionStorage.getItem(CALL_REJOIN_KEY);
  } catch (e) {
    return null;
  }
}
function writeRejoin(callId: string | null): void {
  try {
    if (callId) sessionStorage.setItem(CALL_REJOIN_KEY, callId);
    else sessionStorage.removeItem(CALL_REJOIN_KEY);
  } catch (e) {
    /* private mode: no reload rejoin, nothing else breaks */
  }
}

export function useCallEngine(): CallEngineApi {
  const { t } = useTranslation();
  const { socket, connectionEpoch } = useSocket() as any;
  const token: string | null = useSelector((s: any) => (s.auth && s.auth.userInfo ? s.auth.userInfo.token : null));
  const [state, dispatch] = useReducer(callReducer, IDLE_CALL);
  const [notice, setNotice] = useState<string | null>(null);
  const [cameraAllowed, setCameraAllowed] = useState(true);
  const stateRef = useRef<CallState>(state);
  stateRef.current = state;
  const tokenRef = useRef<string | null>(token);
  tokenRef.current = token;
  const channelRef = useRef<any>(null);

  const [acceptCall] = useAcceptCallMutation();
  const [declineCall] = useDeclineCallMutation();
  const [endCall] = useEndCallMutation();
  const [fetchCurrent] = useLazyGetCurrentCallQuery();

  // --- socket events ------------------------------------------------------
  useEffect(() => {
    if (!socket) return undefined;
    const onIncoming = (p: any) => dispatch({ type: "INCOMING", payload: p });
    const onState = (p: any) => dispatch({ type: "SERVER_STATE", payload: p });
    const onMute = (p: any) => p && dispatch({ type: "PEER_MUTE", callId: p.callId, muted: p.isMuted === true });
    const onVideo = (p: any) => p && dispatch({ type: "PEER_VIDEO", callId: p.callId, on: p.isVideoEnabled === true });
    const onPeerReconnecting = (p: any) => p && dispatch({ type: "PEER_RECONNECTING", callId: p.callId, on: true });
    const onPeerReconnected = (p: any) => p && dispatch({ type: "PEER_RECONNECTING", callId: p.callId, on: false });
    const onFailed = (p: any) => p && dispatch({ type: "SERVER_STATE", payload: { callId: p.callId, status: "failed" } });
    const table: Array<[string, (p: any) => void]> = [
      ["call:incoming", onIncoming],
      ["call:state", onState],
      ["call:mute", onMute],
      ["call:video-toggle", onVideo],
      ["call:peer-reconnecting", onPeerReconnecting],
      ["call:peer-reconnected", onPeerReconnected],
      ["call:failed", onFailed],
    ];
    table.forEach(([e, h]) => socket.on(e, h));
    return () => table.forEach(([e, h]) => socket.off(e, h));
  }, [socket]);

  // --- resync on mount and after every reconnect --------------------------
  useEffect(() => {
    let cancelled = false;
    Promise.resolve(fetchCurrent(undefined))
      .then((r: any) => (r && typeof r.unwrap === "function" ? r.unwrap() : r))
      .then((current: any) => {
        if (cancelled) return;
        const action = resyncAction(stateRef.current, current, readRejoin());
        if (action) dispatch(action);
      })
      .catch(() => {
        /* offline: the next reconnect tries again */
      });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [connectionEpoch]);

  // --- other tabs of this browser -----------------------------------------
  useEffect(() => {
    const BC: any = typeof window !== "undefined" ? (window as any).BroadcastChannel : undefined;
    if (!BC) return undefined;
    const ch = new BC(CALL_CHANNEL);
    ch.onmessage = (e: any) => {
      const m = e && e.data;
      if (!m || m.kind !== "handled" || m.deviceId === callDeviceId()) return;
      const s = stateRef.current;
      if (s.phase === "incoming" && !s.accepting && sameCallId(s.callId, m.callId)) {
        dispatch({ type: "LOCAL_END", outcome: null, reason: "elsewhere" });
      }
    };
    channelRef.current = ch;
    return () => {
      ch.close();
      channelRef.current = null;
    };
  }, []);
  const tellOtherTabs = (callId: string) => {
    if (channelRef.current) channelRef.current.postMessage({ kind: "handled", callId, deviceId: callDeviceId() });
  };

  // --- rejoin key, linger, ring safety ------------------------------------
  useEffect(() => {
    if ((state.phase === "connecting" || state.phase === "connected") && state.callId) writeRejoin(state.callId);
    if (state.phase === "idle" || state.phase === "ended") writeRejoin(null);
    if (state.phase === "ended") {
      const id = setTimeout(() => dispatch({ type: "RESET" }), ENDED_LINGER_MS);
      return () => clearTimeout(id);
    }
    if (state.phase === "incoming" || state.phase === "outgoing") {
      const id = setTimeout(() => {
        const s = stateRef.current;
        if (s.phase === "outgoing" && s.callId) {
          Promise.resolve(endCall({ callId: s.callId, deviceId: callDeviceId() })).catch(() => {});
        }
        dispatch({ type: "LOCAL_END", outcome: s.phase === "outgoing" ? "no_answer" : null, reason: "remote" });
      }, RING_SAFETY_MS);
      return () => clearTimeout(id);
    }
    return undefined;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state.phase, state.callId]);

  // --- pagehide: never leave the callee's phone ringing -------------------
  useEffect(() => {
    const onPageHide = () => {
      const s = stateRef.current;
      if (s.phase !== "outgoing" || !s.callId || !tokenRef.current) return;
      try {
        fetch(`${BASE_URL}${CALLS_URL}/${encodeURIComponent(s.callId)}/end`, {
          method: "POST",
          keepalive: true,
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${tokenRef.current}` },
          body: JSON.stringify({ deviceId: callDeviceId() }),
        }).catch(() => {});
      } catch (e) {
        /* best effort */
      }
    };
    window.addEventListener("pagehide", onPageHide);
    return () => window.removeEventListener("pagehide", onPageHide);
  }, []);

  // --- actions ------------------------------------------------------------
  const accept = useCallback(async () => {
    const s = stateRef.current;
    if (s.phase !== "incoming" || !s.callId || s.accepting) return;
    const media = await preflightMedia(s.type === "video");
    if (media.mic !== "ok") {
      setNotice(mediaProblemText("mic", media.mic, t as any));
      return;
    }
    setCameraAllowed(media.camera === null || media.camera === "ok");
    if (media.camera && media.camera !== "ok") setNotice(mediaProblemText("camera", media.camera, t as any));
    const callId = s.callId;
    dispatch({ type: "ACCEPTING" });
    tellOtherTabs(callId);
    try {
      const res: any = await acceptCall({ callId, deviceId: callDeviceId() }).unwrap();
      const d = (res && res.data) || {};
      dispatch({ type: "ACCEPTED", lk: { url: d.url, token: d.token } });
    } catch (err) {
      const kind = classifyCallError(err).kind;
      if (kind === "callState") {
        dispatch({ type: "LOCAL_END", outcome: null, reason: "elsewhere" });
      } else {
        dispatch({ type: "ACCEPT_FAILED" });
        setNotice(t("calls.notices.acceptFailed") || "Couldn't answer the call. Try again.");
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [acceptCall, t]);

  const decline = useCallback(
    async (message?: string) => {
      const s = stateRef.current;
      if (s.phase !== "incoming" || !s.callId) return;
      const callId = s.callId;
      dispatch({ type: "LOCAL_END", outcome: "declined", reason: "local" });
      tellOtherTabs(callId);
      try {
        const res: any = await declineCall({ callId, deviceId: callDeviceId(), message }).unwrap();
        if (message && res && res.data && res.data.messageDelivered === false) {
          setNotice(t("calls.notices.declineMessageNotDelivered") || "Your message couldn't be delivered.");
        }
      } catch (err) {
        /* 409: it ended some other way first; anything else: the ring timer ends it */
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [declineCall, t]
  );

  const hangUp = useCallback(async () => {
    const s = stateRef.current;
    if (s.phase === "incoming") return decline();
    if (!isInCall(s) || !s.callId) return;
    const callId = s.callId;
    dispatch({ type: "LOCAL_END", outcome: s.phase === "outgoing" ? "cancelled" : "completed", reason: "local" });
    try {
      await endCall({ callId, deviceId: callDeviceId() }).unwrap();
    } catch (err) {
      /* idempotent on the server; LiveKit liveness ends it otherwise */
    }
  }, [decline, endCall]);

  // P4-CALL-7 replaces this with the real outgoing flow.
  const startCall = useCallback(async (_peer: CallPeer, _type: CallType) => {}, []);

  // --- bridge -------------------------------------------------------------
  const inCall = isInCall(state);
  useEffect(() => {
    registerCallApi({ startCall: (peer, type) => void startCall(peer, type), inCall });
  }, [startCall, inCall]);
  useEffect(() => () => registerCallApi(null), []);

  return {
    state,
    dispatch,
    accept,
    decline,
    hangUp,
    startCall,
    cameraAllowed,
    notice,
    clearNotice: () => setNotice(null),
    setNotice,
  };
}
```

Replace `src/components/calls/CallEngine.tsx`:

```tsx
import React from "react";
import { useCallEngine } from "./useCallEngine";

/**
 * The lazily loaded call engine (chunk "calls"). One per tab. The screens it
 * renders arrive in P4-CALL-6 (incoming), P4-CALL-7 (outgoing) and
 * P4-CALL-8 (in call).
 */
const CallEngine: React.FC = () => {
  useCallEngine();
  return null;
};

export default CallEngine;
```

Add to `eng.json` under `calls`:

```json
"notices": {
  "acceptFailed": "Couldn't answer the call. Try again.",
  "declineMessageNotDelivered": "Your message couldn't be delivered."
}
```

- [ ] **Step 5: Run → PASS**

```bash
CI=true npm test -- --watchAll=false useCallEngine IncomingCallHost callMachine
```
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add src/components/calls/useCallEngine.ts src/components/calls/useCallEngine.test.tsx src/components/calls/testing/fakeSocket.ts src/components/calls/testing/fakeBroadcastChannel.ts src/components/calls/testing/callsSliceMock.ts src/components/calls/CallEngine.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): engine listens for calls in every tab and stays in sync

call:incoming / call:state and the in-call relays drive the state
machine (legacy call:accepted/declined/ended are ignored, like new app
builds). Accept preflights the mic, tells other tabs over
BroadcastChannel and sends this tab's device id; a lost race ends
quietly. GET /calls/current resyncs on mount and on every reconnect,
and rejoins the call this tab was in after a reload. pagehide cancels
an outgoing ring so the callee's phone stops.

Still open (Phase 4 calls): screens (P4-CALL-6..8), entry points,
history, flag-off test, I18N, PUSH.
MSG
```

---

### Task P4-CALL-6: Incoming call banner — ringtone with an autoplay fallback, title flash, accept, decline, decline with a message

**Files:**
- Create: `public/sounds/ringtone.m4a`, `public/sounds/ringback.m4a` (copied from the app's `assets/sounds/`)
- Create: `src/components/calls/lib/ringer.ts`, `src/components/calls/lib/ringer.test.ts`, `src/components/calls/lib/titleFlash.ts`
- Create: `src/components/calls/IncomingCallBanner.tsx`, `src/components/calls/DeclineMessageSheet.tsx`, `src/components/calls/IncomingCallBanner.test.tsx`, `src/components/calls/calls.css`
- Modify: `src/components/calls/CallEngine.tsx` (render the banner; notices go to `toast`), `src/utils/locales/eng.json` (`calls.incoming.*`, `calls.decline.*`)

**Interfaces:**
- Consumes: `CallEngineApi` (P4-CALL-5). App reference for the decline sheet: `lib/widgets/call/decline_message_sheet.dart` — two canned replies (`callDeclineCannedLater` "Can't talk now. I'll call you back.", `callDeclineCannedText` "Can't talk now. Text me?") plus a custom line; the backend caps it at 200 characters (`callMessageService.MAX_DECLINE_MESSAGE`).
- Produces:
  - `createRinger(src: string, onBlocked: (blocked: boolean) => void): { start(): void; stop(): void }` — loops `src`; a rejected `play()` (autoplay policy: the user never interacted with this tab) calls `onBlocked(true)`; `start()` again (from a click) retries.
  - `startTitleFlash(text: string, everyMs?: number): () => void` — alternates `document.title` with `text`, the returned function restores the original title.
  - `IncomingCallBanner` props `{ peer: CallPeer | null; type: CallType; accepting: boolean; onAccept(): void; onDecline(): void; onDeclineWithMessage(text: string): void }`; testids `incoming-call`, `call-accept`, `call-decline`, `call-decline-message`, `call-sound-blocked`.
  - `DeclineMessageSheet` props `{ onSend(text: string): void; onCancel(): void }`; testids `decline-sheet`, `decline-canned-0`, `decline-canned-1`, `decline-custom`, `decline-send`.

- [ ] **Step 1: Copy the sounds**

```bash
mkdir -p public/sounds
cp /Users/davis/Desktop/Personal/bt-integration/bananatalk_app/assets/sounds/ringtone.m4a public/sounds/ringtone.m4a
cp /Users/davis/Desktop/Personal/bt-integration/bananatalk_app/assets/sounds/ringback.m4a public/sounds/ringback.m4a
ls -la public/sounds
```
Expected: two files, each a few tens of KB.

- [ ] **Step 2: Write the failing tests**

Create `src/components/calls/lib/ringer.test.ts`:

```ts
import { createRinger } from "./ringer";
import { startTitleFlash } from "./titleFlash";

const play = jest.spyOn(window.HTMLMediaElement.prototype, "play");
const pause = jest.spyOn(window.HTMLMediaElement.prototype, "pause").mockImplementation(() => {});

afterEach(() => {
  play.mockReset();
  pause.mockClear();
});

it("loops the sound and stops it", async () => {
  play.mockImplementation(() => Promise.resolve());
  const onBlocked = jest.fn();
  const r = createRinger("/sounds/ringtone.m4a", onBlocked);
  r.start();
  await Promise.resolve();
  expect(play).toHaveBeenCalledTimes(1);
  expect(onBlocked).toHaveBeenLastCalledWith(false);
  r.stop();
  expect(pause).toHaveBeenCalled();
});

it("reports an autoplay refusal instead of throwing", async () => {
  play.mockImplementation(() => Promise.reject(Object.assign(new Error("x"), { name: "NotAllowedError" })));
  const onBlocked = jest.fn();
  createRinger("/sounds/ringtone.m4a", onBlocked).start();
  await new Promise((r) => setTimeout(r, 0));
  expect(onBlocked).toHaveBeenCalledWith(true);
});

it("survives a browser whose play() returns undefined (old Safari, jsdom)", () => {
  play.mockImplementation((() => undefined) as any);
  expect(() => createRinger("/s.m4a", jest.fn()).start()).not.toThrow();
});

it("title flash alternates and restores", () => {
  jest.useFakeTimers();
  document.title = "BananaTalk";
  const stop = startTitleFlash("📞 Mina is calling", 1000);
  jest.advanceTimersByTime(1000);
  expect(document.title).toBe("📞 Mina is calling");
  jest.advanceTimersByTime(1000);
  expect(document.title).toBe("BananaTalk");
  jest.advanceTimersByTime(1000);
  stop();
  expect(document.title).toBe("BananaTalk");
  jest.useRealTimers();
});
```

Create `src/components/calls/IncomingCallBanner.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import IncomingCallBanner from "./IncomingCallBanner";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockStart = jest.fn();
const mockStop = jest.fn();
let mockOnBlocked: (b: boolean) => void = () => {};
jest.mock("./lib/ringer", () => ({
  createRinger: (_src: string, onBlocked: (b: boolean) => void) => {
    mockOnBlocked = onBlocked;
    return { start: mockStart, stop: mockStop };
  },
}));
const mockStopFlash = jest.fn();
jest.mock("./lib/titleFlash", () => ({ startTitleFlash: () => mockStopFlash }));

const peer = { id: "u2", name: "Mina", avatar: null };
function renderBanner(props: any = {}) {
  const handlers = { onAccept: jest.fn(), onDecline: jest.fn(), onDeclineWithMessage: jest.fn() };
  const view = render(<IncomingCallBanner peer={peer} type="video" accepting={false} {...handlers} {...props} />);
  return Object.assign(view, handlers);
}

beforeEach(() => {
  mockStart.mockClear();
  mockStop.mockClear();
  mockStopFlash.mockClear();
});

it("announces the caller and the call type, rings, flashes the title", () => {
  renderBanner();
  const banner = screen.getByTestId("incoming-call");
  expect(banner).toHaveAttribute("role", "alertdialog");
  expect(banner).toHaveTextContent("Mina");
  expect(banner).toHaveTextContent("Incoming video call");
  expect(mockStart).toHaveBeenCalled();
});

it("stops ringing and restores the title when it closes", () => {
  const view = renderBanner();
  view.unmount();
  expect(mockStop).toHaveBeenCalled();
  expect(mockStopFlash).toHaveBeenCalled();
});

it("accept and decline", () => {
  const view = renderBanner();
  fireEvent.click(screen.getByTestId("call-accept"));
  expect(view.onAccept).toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("call-decline"));
  expect(view.onDecline).toHaveBeenCalled();
});

it("while answering, the buttons are locked and the ring stops", () => {
  renderBanner({ accepting: true });
  expect(screen.getByTestId("call-accept")).toBeDisabled();
  expect(screen.getByTestId("call-decline")).toBeDisabled();
  expect(mockStop).toHaveBeenCalled();
});

it("shows a visible hint when the browser blocks the ringtone; a click retries it", () => {
  renderBanner();
  act(() => mockOnBlocked(true));
  expect(screen.getByTestId("call-sound-blocked")).toHaveTextContent("Sound is off");
  mockStart.mockClear();
  fireEvent.click(screen.getByTestId("call-sound-blocked"));
  expect(mockStart).toHaveBeenCalled();
});

it("decline with a message: canned replies like the app, or a custom line up to 200 characters", () => {
  const view = renderBanner();
  fireEvent.click(screen.getByTestId("call-decline-message"));
  expect(screen.getByTestId("decline-canned-0")).toHaveTextContent("Can't talk now. I'll call you back.");
  expect(screen.getByTestId("decline-canned-1")).toHaveTextContent("Can't talk now. Text me?");
  expect(screen.getByTestId("decline-custom")).toHaveAttribute("maxLength", "200");
  fireEvent.click(screen.getByTestId("decline-canned-1"));
  expect(view.onDeclineWithMessage).toHaveBeenCalledWith("Can't talk now. Text me?");
});

it("a custom message is trimmed; an empty one cannot be sent", () => {
  const view = renderBanner();
  fireEvent.click(screen.getByTestId("call-decline-message"));
  expect(screen.getByTestId("decline-send")).toBeDisabled();
  fireEvent.change(screen.getByTestId("decline-custom"), { target: { value: "  In class, after 5?  " } });
  fireEvent.click(screen.getByTestId("decline-send"));
  expect(view.onDeclineWithMessage).toHaveBeenCalledWith("In class, after 5?");
});

it("a voice call says so and a missing caller name still reads", () => {
  renderBanner({ type: "audio", peer: null });
  expect(screen.getByTestId("incoming-call")).toHaveTextContent("Incoming voice call");
  expect(screen.getByTestId("incoming-call")).toHaveTextContent("Someone");
});
```

- [ ] **Step 3: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false calls/lib/ringer IncomingCallBanner
```
Expected: FAIL — modules not found.

- [ ] **Step 4: Implement**

Create `src/components/calls/lib/ringer.ts`:

```ts
/**
 * A looping sound for an incoming call (ringtone) or an outgoing one
 * (ringback). Browsers refuse audio in a tab the user never interacted with
 * (Chrome/Safari autoplay policy): play() rejects with NotAllowedError, which
 * is reported through onBlocked so the banner can show "Sound is off" and
 * retry on the next click. It never throws.
 */
export function createRinger(src: string, onBlocked: (blocked: boolean) => void) {
  let audio: HTMLAudioElement | null = null;
  return {
    start() {
      if (!audio) {
        audio = new Audio(src);
        audio.loop = true;
      }
      try {
        const p: any = audio.play();
        if (p && typeof p.then === "function") {
          p.then(
            () => onBlocked(false),
            () => onBlocked(true)
          );
        }
      } catch (e) {
        onBlocked(true);
      }
    },
    stop() {
      if (!audio) return;
      try {
        audio.pause();
        audio.currentTime = 0;
      } catch (e) {
        /* nothing to stop */
      }
    },
  };
}
```

Create `src/components/calls/lib/titleFlash.ts`:

```ts
/** Alternate the tab title with `text` so a ringing call is seen in a background tab. */
export function startTitleFlash(text: string, everyMs: number = 1000): () => void {
  const original = document.title;
  let on = false;
  const id = setInterval(() => {
    on = !on;
    document.title = on ? text : original;
  }, everyMs);
  return () => {
    clearInterval(id);
    document.title = original;
  };
}
```

Create `src/components/calls/DeclineMessageSheet.tsx`:

```tsx
import React, { useState } from "react";
import { useTranslation } from "react-i18next";

/** The app's decline-with-message sheet (lib/widgets/call/decline_message_sheet.dart). */
const MAX = 200;

const DeclineMessageSheet: React.FC<{ onSend(text: string): void; onCancel(): void }> = ({ onSend, onCancel }) => {
  const { t } = useTranslation();
  const [text, setText] = useState("");
  const canned = [
    t("calls.decline.cannedLater") || "Can't talk now. I'll call you back.",
    t("calls.decline.cannedText") || "Can't talk now. Text me?",
  ];
  const trimmed = text.trim();
  return (
    <div className="call-decline-sheet" data-testid="decline-sheet" role="group" aria-label={t("calls.decline.title") || "Decline with a message"}>
      <p className="call-decline-title">{t("calls.decline.title") || "Decline with a message"}</p>
      {canned.map((line, i) => (
        <button key={i} type="button" className="call-decline-canned" data-testid={`decline-canned-${i}`} onClick={() => onSend(line)}>
          {line}
        </button>
      ))}
      <div className="call-decline-custom-row">
        <input
          data-testid="decline-custom"
          className="call-decline-custom"
          value={text}
          maxLength={MAX}
          placeholder={t("calls.decline.customHint") || "Write a message…"}
          onChange={(e) => setText(e.target.value)}
        />
        <button type="button" data-testid="decline-send" disabled={!trimmed} onClick={() => onSend(trimmed)}>
          {t("calls.decline.send") || "Send"}
        </button>
      </div>
      <button type="button" className="call-decline-cancel" onClick={onCancel}>
        {t("calls.decline.cancel") || "Cancel"}
      </button>
    </div>
  );
};

export default DeclineMessageSheet;
```

Create `src/components/calls/IncomingCallBanner.tsx`:

```tsx
import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { Phone, PhoneOff, MessageSquare, Video, VolumeX } from "lucide-react";
import { CallPeer } from "./lib/callMachine";
import { CallType } from "../../store/slices/callsSlice";
import { createRinger } from "./lib/ringer";
import { startTitleFlash } from "./lib/titleFlash";
import DeclineMessageSheet from "./DeclineMessageSheet";
import "./calls.css";

interface Props {
  peer: CallPeer | null;
  type: CallType;
  accepting: boolean;
  onAccept(): void;
  onDecline(): void;
  onDeclineWithMessage(text: string): void;
}

/**
 * Incoming call while a BananaTalk tab is open (any page). Visible without
 * sound: the ringtone may be blocked by the autoplay policy, so the banner,
 * the title flash and the "Sound is off" hint carry the ring on their own.
 */
const IncomingCallBanner: React.FC<Props> = ({ peer, type, accepting, onAccept, onDecline, onDeclineWithMessage }) => {
  const { t } = useTranslation();
  const [soundBlocked, setSoundBlocked] = useState(false);
  const [sheet, setSheet] = useState(false);
  const ringer = useMemo(() => createRinger("/sounds/ringtone.m4a", setSoundBlocked), []);
  const name = (peer && peer.name) || t("calls.incoming.someone") || "Someone";

  useEffect(() => {
    ringer.start();
    const stopFlash = startTitleFlash(t("calls.incoming.titleFlash", { name }) || `📞 ${name} is calling`);
    return () => {
      ringer.stop();
      stopFlash();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (accepting) ringer.stop();
  }, [accepting, ringer]);

  const kind =
    type === "video"
      ? t("calls.incoming.video") || "Incoming video call"
      : t("calls.incoming.voice") || "Incoming voice call";

  return (
    <div className="incoming-call" data-testid="incoming-call" role="alertdialog" aria-live="assertive" aria-label={`${kind}: ${name}`}>
      <div className="incoming-call-who">
        <img className="incoming-call-avatar" src={(peer && peer.avatar) || "/default-avatar.png"} alt="" />
        <div>
          <p className="incoming-call-name">{name}</p>
          <p className="incoming-call-kind">
            {type === "video" ? <Video size={14} aria-hidden="true" /> : <Phone size={14} aria-hidden="true" />} {kind}
          </p>
        </div>
      </div>
      {soundBlocked && !accepting && (
        <button type="button" className="incoming-call-sound" data-testid="call-sound-blocked" onClick={() => ringer.start()}>
          <VolumeX size={14} aria-hidden="true" /> {t("calls.incoming.soundBlocked") || "Sound is off — click to turn on the ringtone"}
        </button>
      )}
      {sheet ? (
        <DeclineMessageSheet onSend={(text) => onDeclineWithMessage(text)} onCancel={() => setSheet(false)} />
      ) : (
        <div className="incoming-call-actions">
          <button type="button" className="call-btn call-btn--decline" data-testid="call-decline" disabled={accepting} onClick={onDecline}>
            <PhoneOff size={18} aria-hidden="true" /> {t("calls.incoming.decline") || "Decline"}
          </button>
          <button type="button" className="call-btn" data-testid="call-decline-message" disabled={accepting} onClick={() => setSheet(true)}>
            <MessageSquare size={18} aria-hidden="true" /> {t("calls.incoming.message") || "Message"}
          </button>
          <button type="button" className="call-btn call-btn--accept" data-testid="call-accept" disabled={accepting} onClick={onAccept}>
            <Phone size={18} aria-hidden="true" /> {accepting ? t("calls.incoming.answering") || "Answering…" : t("calls.incoming.accept") || "Accept"}
          </button>
        </div>
      )}
    </div>
  );
};

export default IncomingCallBanner;
```

Create `src/components/calls/calls.css` (logical properties; the call surfaces are never mirrored in RTL except text alignment):

```css
.incoming-call {
  position: fixed;
  inset-block-start: 16px;
  inset-inline-end: 16px;
  z-index: 2000;
  width: min(360px, calc(100vw - 32px));
  padding: 16px;
  border-radius: 16px;
  background: #111827;
  color: #fff;
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.35);
  text-align: start;
}
.incoming-call-who { display: flex; align-items: center; gap: 12px; }
.incoming-call-avatar { width: 48px; height: 48px; border-radius: 50%; object-fit: cover; }
.incoming-call-name { margin: 0; font-weight: 700; font-size: 16px; }
.incoming-call-kind { margin: 2px 0 0; font-size: 13px; opacity: 0.8; display: flex; align-items: center; gap: 4px; }
.incoming-call-sound { margin-block-start: 10px; background: none; border: 0; color: #fbbf24; font-size: 12px; cursor: pointer; padding: 0; }
.incoming-call-actions { display: flex; gap: 8px; margin-block-start: 14px; }
.call-btn { flex: 1; display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 10px 8px; border: 0; border-radius: 999px; background: #374151; color: #fff; font-weight: 600; cursor: pointer; }
.call-btn:disabled { opacity: 0.6; cursor: default; }
.call-btn--accept { background: #16a34a; }
.call-btn--decline { background: #dc2626; }
.call-decline-sheet { margin-block-start: 12px; display: flex; flex-direction: column; gap: 8px; }
.call-decline-title { margin: 0; font-weight: 600; }
.call-decline-canned { text-align: start; padding: 8px 12px; border-radius: 12px; border: 1px solid #4b5563; background: transparent; color: #fff; cursor: pointer; }
.call-decline-custom-row { display: flex; gap: 8px; }
.call-decline-custom { flex: 1; padding: 8px 12px; border-radius: 12px; border: 1px solid #4b5563; background: #1f2937; color: #fff; }
.call-decline-cancel { background: none; border: 0; color: #9ca3af; cursor: pointer; align-self: flex-end; }
```

Replace `src/components/calls/CallEngine.tsx`:

```tsx
import React, { useEffect } from "react";
import { toast } from "react-toastify";
import { useCallEngine } from "./useCallEngine";
import IncomingCallBanner from "./IncomingCallBanner";

/** The lazily loaded call engine (chunk "calls"). One per tab. */
const CallEngine: React.FC = () => {
  const engine = useCallEngine();
  const { state, notice, clearNotice } = engine;

  useEffect(() => {
    if (!notice) return;
    toast.info(notice, { toastId: `call-notice-${notice}` });
    clearNotice();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [notice]);

  if (state.phase === "incoming") {
    return (
      <IncomingCallBanner
        key={state.callId || "incoming"}
        peer={state.peer}
        type={state.type}
        accepting={state.accepting}
        onAccept={() => void engine.accept()}
        onDecline={() => void engine.decline()}
        onDeclineWithMessage={(text) => void engine.decline(text)}
      />
    );
  }
  return null;
};

export default CallEngine;
```

Add to `eng.json` under `calls`:

```json
"incoming": {
  "someone": "Someone",
  "titleFlash": "📞 {{name}} is calling",
  "video": "Incoming video call",
  "voice": "Incoming voice call",
  "soundBlocked": "Sound is off — click to turn on the ringtone",
  "decline": "Decline",
  "message": "Message",
  "accept": "Accept",
  "answering": "Answering…"
},
"decline": {
  "title": "Decline with a message",
  "cannedLater": "Can't talk now. I'll call you back.",
  "cannedText": "Can't talk now. Text me?",
  "customHint": "Write a message…",
  "send": "Send",
  "cancel": "Cancel"
}
```

- [ ] **Step 5: Run → PASS**

```bash
CI=true npm test -- --watchAll=false calls/lib/ringer IncomingCallBanner useCallEngine
```
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add public/sounds/ringtone.m4a public/sounds/ringback.m4a src/components/calls/lib/ringer.ts src/components/calls/lib/ringer.test.ts src/components/calls/lib/titleFlash.ts src/components/calls/IncomingCallBanner.tsx src/components/calls/DeclineMessageSheet.tsx src/components/calls/IncomingCallBanner.test.tsx src/components/calls/calls.css src/components/calls/CallEngine.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): incoming call banner with ringtone, title flash, decline message

The banner rings with the app's ringtone; when the autoplay policy
blocks it, a visible "Sound is off" hint retries on click and the tab
title flashes. Accept, Decline, and the app's decline-with-message
sheet (two canned replies, or a custom line up to 200 characters).

Still open (Phase 4 calls): outgoing (P4-CALL-7), in-call screen,
entry points, history, flag-off test, I18N, PUSH.
MSG
```

---

### Task P4-CALL-7: Placing a call — preflight, initiate, refusals in a dialog

**Files:**
- Modify: `src/components/calls/useCallEngine.ts` (real `startCall`; `callError` + `clearCallError` on the api)
- Create: `src/components/calls/CallErrorDialog.tsx`, `src/components/calls/CallErrorDialog.test.tsx`
- Modify: `src/components/calls/useCallEngine.test.tsx` (append the outgoing cases), `src/components/calls/CallEngine.tsx` (render the dialog)
- Modify: `src/utils/locales/eng.json` (`calls.errorDialog.*`)

**Interfaces:**
- Consumes: `POST /calls/initiate` and its refusals (unit facts); `preflightMedia`, `classifyCallError`, `callErrorText`, `mediaProblemText` (P4-CALL-2).
- Produces: `CallEngineApi.startCall(peer, type)` — refuses locally while this tab is already in a call (`callerBusy`), preflights (a denied mic opens the dialog and **nothing is initiated**, so no phone rings), then `POST /initiate`; success → `OUTGOING` with the caller's LiveKit credentials (the caller joins the room only when the callee accepts, P4-CALL-8). `CallEngineApi.callError: { kind: CallErrorKind | "media"; text: string } | null`, `clearCallError()`. `CallErrorDialog` props `{ error: { kind: string; text: string }; onClose(): void }`, testids `call-error-dialog`, `call-error-vip` (only for `conversationCap`, links `/settings/vip`), `call-error-close`.

- [ ] **Step 1: Write the failing tests**

Append to `src/components/calls/useCallEngine.test.tsx`:

```tsx
describe("placing a call", () => {
  const mina = { id: "u2", name: "Mina", avatar: null };

  it("preflights, POSTs initiate, rings out with the caller's credentials", async () => {
    callsApi.initiate.mockReturnValue(
      ok({ data: { call: { _id: "c9", callUuid: "U9" }, token: "ctok", url: "wss://lk", roomName: "call:c9" } })
    );
    mount();
    await act(async () => {
      await api.startCall(mina, "video");
    });
    expect(mockPreflight).toHaveBeenCalledWith(true);
    expect(callsApi.initiate).toHaveBeenCalledWith({ receiverId: "u2", type: "video" });
    expect(api.state.phase).toBe("outgoing");
    expect(api.state.callId).toBe("c9");
    expect(api.state.lk).toEqual({ url: "wss://lk", token: "ctok" });
    expect(api.state.peer).toEqual(mina);
  });

  it("mic denied: no request, nothing rings, the dialog explains", async () => {
    mockPreflight.mockResolvedValue({ mic: "denied", camera: "denied" });
    mount();
    await act(async () => {
      await api.startCall(mina, "video");
    });
    expect(callsApi.initiate).not.toHaveBeenCalled();
    expect(api.state.phase).toBe("idle");
    expect(api.callError).toEqual({ kind: "media", text: expect.stringMatching(/can't use your microphone/) });
  });

  it("camera denied on a video call: rings anyway with the camera off", async () => {
    mockPreflight.mockResolvedValue({ mic: "ok", camera: "denied" });
    callsApi.initiate.mockReturnValue(ok({ data: { call: { _id: "c9" }, token: "t", url: "u" } }));
    mount();
    await act(async () => {
      await api.startCall(mina, "video");
    });
    expect(api.state.phase).toBe("outgoing");
    expect(api.cameraAllowed).toBe(false);
  });

  it.each([
    [{ status: 409, data: { code: "CALLEE_BUSY" } }, "calleeBusy", "Mina is on another call."],
    [{ status: 409, data: { code: "CALLEE_UNAVAILABLE" } }, "calleeUnavailable", "Mina isn't taking calls right now."],
    [{ status: 409, data: { code: "CALLER_BUSY" } }, "callerBusy", "You're already in a call on another device or tab."],
    [{ status: 403, data: { error: "Cannot call this user" } }, "blocked", "You can't call this person."],
    [{ status: 403, data: { code: "CONVERSATION_START_LIMIT" } }, "conversationCap", expect.stringMatching(/Go VIP/)],
  ])("refusal %j opens the dialog (%s)", async (error, kind, text) => {
    callsApi.initiate.mockReturnValue(fail(error));
    mount();
    await act(async () => {
      await api.startCall(mina, "audio");
    });
    expect(api.state.phase).toBe("idle");
    expect(api.callError).toEqual({ kind, text });
  });

  it("refuses a second call while one is in progress in this tab", async () => {
    mount();
    act(() => socket.serverEmit("call:incoming", incoming));
    await act(async () => {
      await api.startCall(mina, "audio");
    });
    expect(callsApi.initiate).not.toHaveBeenCalled();
    expect(api.callError!.kind).toBe("callerBusy");
  });

  it("a double click places one call", async () => {
    let resolve: any;
    callsApi.initiate.mockReturnValue({ unwrap: () => new Promise((r) => (resolve = r)) } as any);
    mount();
    await act(async () => {
      api.startCall(mina, "audio");
      api.startCall(mina, "audio");
      await Promise.resolve();
    });
    await act(async () => {
      resolve({ data: { call: { _id: "c9" }, token: "t", url: "u" } });
    });
    expect(callsApi.initiate).toHaveBeenCalledTimes(1);
  });
});
```

Create `src/components/calls/CallErrorDialog.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import CallErrorDialog from "./CallErrorDialog";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

it("shows the text and closes", () => {
  const onClose = jest.fn();
  render(
    <MemoryRouter>
      <CallErrorDialog error={{ kind: "calleeBusy", text: "Mina is on another call." }} onClose={onClose} />
    </MemoryRouter>
  );
  expect(screen.getByTestId("call-error-dialog")).toHaveTextContent("Mina is on another call.");
  expect(screen.queryByTestId("call-error-vip")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("call-error-close"));
  expect(onClose).toHaveBeenCalled();
});

it("offers VIP only for the conversation cap", () => {
  render(
    <MemoryRouter>
      <CallErrorDialog error={{ kind: "conversationCap", text: "x" }} onClose={() => {}} />
    </MemoryRouter>
  );
  expect(screen.getByTestId("call-error-vip")).toHaveAttribute("href", "/settings/vip");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false useCallEngine CallErrorDialog
```
Expected: FAIL — `startCall` is a no-op (`initiate` never called, phase stays `idle`); `CallErrorDialog` not found.

- [ ] **Step 3: Implement**

In `src/components/calls/useCallEngine.ts`:

1. Extend the imports:
```ts
import {
  useAcceptCallMutation,
  useDeclineCallMutation,
  useEndCallMutation,
  useInitiateCallMutation,
  useLazyGetCurrentCallQuery,
  CallType,
} from "../../store/slices/callsSlice";
import { classifyCallError, callErrorText, mediaProblemText, CallErrorKind } from "./lib/callErrors";
```
(replacing the two existing import lines for those modules).

2. Add to `CallEngineApi`:
```ts
  callError: { kind: CallErrorKind | "media"; text: string } | null;
  clearCallError(): void;
```

3. Inside the hook, next to `const [notice, setNotice] = …`:
```ts
  const [callError, setCallError] = useState<{ kind: CallErrorKind | "media"; text: string } | null>(null);
  const startingRef = useRef(false);
  const [initiateCall] = useInitiateCallMutation();
```

4. Replace the placeholder
```ts
  // P4-CALL-7 replaces this with the real outgoing flow.
  const startCall = useCallback(async (_peer: CallPeer, _type: CallType) => {}, []);
```
with
```ts
  const startCall = useCallback(
    async (peer: CallPeer, type: CallType) => {
      if (startingRef.current) return;
      if (isInCall(stateRef.current)) {
        setCallError({ kind: "callerBusy", text: callErrorText({ kind: "callerBusy", detail: "" }, t as any, peer.name) });
        return;
      }
      startingRef.current = true;
      try {
        // Ask for the mic (and camera) BEFORE anything rings: a refused mic
        // must never leave the other person's phone ringing for a call this
        // browser cannot speak in.
        const media = await preflightMedia(type === "video");
        if (media.mic !== "ok") {
          setCallError({ kind: "media", text: mediaProblemText("mic", media.mic, t as any) });
          return;
        }
        setCameraAllowed(media.camera === null || media.camera === "ok");
        if (media.camera && media.camera !== "ok") setNotice(mediaProblemText("camera", media.camera, t as any));
        const res: any = await initiateCall({ receiverId: peer.id, type }).unwrap();
        const d = (res && res.data) || {};
        const call = d.call || {};
        dispatch({
          type: "OUTGOING",
          callId: String(call._id),
          callUuid: call.callUuid || null,
          peer,
          callType: type,
          lk: { url: d.url, token: d.token },
        });
      } catch (err) {
        const e = classifyCallError(err);
        setCallError({ kind: e.kind, text: callErrorText(e, t as any, peer.name) });
      } finally {
        startingRef.current = false;
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [initiateCall, t]
  );
```

5. Add to the returned object:
```ts
    callError,
    clearCallError: () => setCallError(null),
```

Create `src/components/calls/CallErrorDialog.tsx`:

```tsx
import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import "./calls.css";

const CallErrorDialog: React.FC<{ error: { kind: string; text: string }; onClose(): void }> = ({ error, onClose }) => {
  const { t } = useTranslation();
  return (
    <div className="call-error-backdrop" role="presentation" onClick={onClose}>
      <div
        className="call-error-dialog"
        data-testid="call-error-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-label={t("calls.errorDialog.title") || "Call"}
        onClick={(e) => e.stopPropagation()}
      >
        <p className="call-error-text">{error.text}</p>
        <div className="call-error-actions">
          {error.kind === "conversationCap" && (
            <Link to="/settings/vip" className="call-btn call-btn--accept" data-testid="call-error-vip" onClick={onClose}>
              {t("calls.errorDialog.vip") || "See VIP"}
            </Link>
          )}
          <button type="button" className="call-btn" data-testid="call-error-close" onClick={onClose}>
            {t("calls.errorDialog.ok") || "OK"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default CallErrorDialog;
```

Append to `src/components/calls/calls.css`:

```css
.call-error-backdrop { position: fixed; inset: 0; z-index: 2100; background: rgba(0, 0, 0, 0.45); display: flex; align-items: center; justify-content: center; padding: 16px; }
.call-error-dialog { width: min(380px, 100%); background: #fff; color: #111827; border-radius: 16px; padding: 20px; text-align: start; }
.call-error-text { margin: 0 0 16px; font-size: 15px; }
.call-error-actions { display: flex; gap: 8px; justify-content: flex-end; }
.call-error-dialog .call-btn { flex: 0 0 auto; padding-inline: 18px; text-decoration: none; }
```

In `src/components/calls/CallEngine.tsx`, add `import CallErrorDialog from "./CallErrorDialog";` and render the dialog on top of whatever the phase renders: change the body to

```tsx
  const dialog = engine.callError ? <CallErrorDialog error={engine.callError} onClose={engine.clearCallError} /> : null;
  if (state.phase === "incoming") {
    return (
      <>
        <IncomingCallBanner
          key={state.callId || "incoming"}
          peer={state.peer}
          type={state.type}
          accepting={state.accepting}
          onAccept={() => void engine.accept()}
          onDecline={() => void engine.decline()}
          onDeclineWithMessage={(text) => void engine.decline(text)}
        />
        {dialog}
      </>
    );
  }
  return dialog;
```

Add to `eng.json` under `calls`:

```json
"errorDialog": {
  "title": "Call",
  "vip": "See VIP",
  "ok": "OK"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false useCallEngine CallErrorDialog
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/calls/useCallEngine.ts src/components/calls/useCallEngine.test.tsx src/components/calls/CallErrorDialog.tsx src/components/calls/CallErrorDialog.test.tsx src/components/calls/calls.css src/components/calls/CallEngine.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): place a call — preflight first, refusals in a dialog

startCall refuses while this tab is in a call, asks for the mic (and
camera) before anything rings, then POSTs /calls/initiate. Busy,
unavailable, blocked and conversation-cap refusals open a dialog (VIP
link for the cap); a denied camera still rings with the camera off.

Still open (Phase 4 calls): in-call screen (P4-CALL-8), entry points,
history, flag-off test, I18N, PUSH.
MSG
```

---

### Task P4-CALL-8: In-call screen — LiveKit media, mute, camera (voice → video), remote video, "tap to enable sound", reconnecting, hang up

**Files:**
- Create: `src/components/calls/useCallMedia.ts`, `src/components/calls/CallScreen.tsx`, `src/components/calls/lib/callOutcomeText.ts`
- Create: `src/components/calls/testing/fakeLkSession.ts`, `src/components/calls/CallEngine.test.tsx`
- Modify: `src/components/calls/CallEngine.tsx` (render `CallScreen` for outgoing / connecting / connected / ended), `src/components/calls/calls.css` (append), `src/utils/locales/eng.json` (`calls.screen.*`, `calls.outcome.*`)

**Interfaces:**
- Consumes: `createLkSession`, `LkSession`, `LkEvents`, `LkPeer`, `LkVideoTrack`, `mediaErrorKind` (P4-ROOM-1, unchanged); the relays `call:mute`, `call:video-toggle`, `call:reconnecting`, `call:reconnected`, `call:failed` (client → server, `socket/callRelayHandler.js:42-80`); `POST /calls/:id/upgrade` (`useUpgradeCallMutation`); `CallEngineApi` (P4-CALL-5/7).
- Produces:
  - `useCallMedia(engine: CallEngineApi, socket: any): CallMedia` with `CallMedia = { micOn: boolean; cameraOn: boolean; audioBlocked: boolean; reconnecting: boolean; remoteVideo: LkVideoTrack | null; localVideo: LkVideoTrack | null; toggleMic(): Promise<void>; toggleCamera(): Promise<void>; enableAudio(): Promise<void> }`. Joins the LiveKit room (`call:<callId>`) when the state reaches `connecting` (callee after `ACCEPTED`, caller after the server's `active`, a reloaded tab after `REJOIN`) with `{ mic: true, camera: type === "video" && cameraAllowed }`; the first remote participant in `onPeers` → `MEDIA_CONNECTED`; leaves the room when the call ends or the engine unmounts.
  - `onDisconnected` mapping: `"client"` → nothing; `"duplicate_identity"` → ends locally with the notice "The call continued in another tab." (no `call:failed`); `"room_deleted"` → ends locally as completed (the server ended it; its `call:state` follows); anything else (`"network"`, `"server_shutdown"`, `"participant_removed"`, `"unknown"`) → emits `call:failed {callId, reason:"Connection lost"}` and ends locally as failed.
  - `CallScreen` props `{ state: CallState; media: CallMedia; onHangUp(): void }`; testids `call-screen`, `call-status`, `call-timer`, `call-remote-video`, `call-local-video`, `call-mute`, `call-camera`, `call-hangup`, `call-enable-audio`, `call-reconnecting`, `call-peer-muted`, `call-ended`.
  - `callOutcomeText(state, t): string | null` — the ended line: completed "Call ended", declined "{{name}} declined", no_answer "No answer", busy "{{name}} was on another call", cancelled "Call cancelled", failed "The call dropped."; `null` for answered elsewhere / another tab / an incoming call this user declined.

- [ ] **Step 1: Test helper**

Create `src/components/calls/testing/fakeLkSession.ts`:

```ts
/**
 * jest.mock("../../lib/livekit/lkSession", () =>
 *   require("./testing/fakeLkSession").lkSessionMock());
 * CALLS tests stop at the LkSession contract (header "Shared contracts →
 * LiveKit"); how lkSession drives livekit-client is ROOMS' tests' job.
 * mediaErrorKind stays the real one.
 */
export const lkSessions: any[] = [];

export function lastLk(): any {
  return lkSessions[lkSessions.length - 1];
}

export function lkSessionMock() {
  const actual = jest.requireActual("../../../lib/livekit/lkSession");
  return {
    __esModule: true,
    mediaErrorKind: actual.mediaErrorKind,
    createLkSession: (events: any) => {
      const session = {
        events,
        connect: jest.fn(() => Promise.resolve("ok")),
        setMic: jest.fn(() => Promise.resolve("ok")),
        setCamera: jest.fn(() => Promise.resolve("ok")),
        localVideo: jest.fn(() => null),
        startAudio: jest.fn(() => Promise.resolve(true)),
        peers: jest.fn(() => []),
        disconnect: jest.fn(() => Promise.resolve()),
      };
      lkSessions.push(session);
      return session;
    },
  };
}

export const remotePeer = (over: any = {}) =>
  Object.assign(
    { identity: "u2", name: "Mina", isLocal: false, isSpeaking: false, micOn: true, cameraOn: false, metadata: "" },
    over
  );
export const localPeer = () =>
  ({ identity: "me", name: "Me", isLocal: true, isSpeaking: false, micOn: true, cameraOn: false, metadata: "" });
```

- [ ] **Step 2: Write the failing test**

Create `src/components/calls/CallEngine.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, act, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { MemoryRouter } from "react-router-dom";
import { configureStore } from "@reduxjs/toolkit";
import { makeFakeSocket } from "./testing/fakeSocket";
import { installFakeBroadcastChannel } from "./testing/fakeBroadcastChannel";
import { callsApi, resetCallsApi, ok } from "./testing/callsSliceMock";
import { lkSessions, lastLk, remotePeer, localPeer } from "./testing/fakeLkSession";
import CallEngine from "./CallEngine";

jest.mock("../../store/slices/callsSlice", () => {
  const base = require("./testing/callsSliceMock").callsSliceMock();
  return base;
});
jest.mock("../../lib/livekit/lkSession", () => require("./testing/fakeLkSession").lkSessionMock());
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockToast = jest.fn();
jest.mock("react-toastify", () => ({ toast: { info: (...a: any[]) => mockToast(...a) } }));
const mockPreflight = jest.fn();
jest.mock("./lib/mediaPreflight", () => ({ preflightMedia: (...a: any[]) => mockPreflight(...a) }));
jest.mock("./lib/deviceId", () => ({ callDeviceId: () => "web-tab1" }));
jest.mock("./lib/ringer", () => ({ createRinger: () => ({ start: jest.fn(), stop: jest.fn() }) }));
jest.mock("./lib/titleFlash", () => ({ startTitleFlash: () => () => {} }));
let mockSocketCtx: any;
jest.mock("../chat/hooks/useSocket", () => ({ useSocket: () => mockSocketCtx }));

const incoming = {
  callId: "c1",
  callUuid: "U1",
  caller: { _id: "u2", name: "Mina", profilePicture: null },
  callType: "audio",
  roomName: "call:c1",
};
let socket: any;

function mount() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { token: "tok", user: { _id: "me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <CallEngine />
      </MemoryRouter>
    </Provider>
  );
}

async function answeredCall(type = "audio") {
  callsApi.accept.mockReturnValue(ok({ data: { token: "rtok", url: "wss://lk", roomName: "call:c1" } }));
  const view = mount();
  act(() => socket.serverEmit("call:incoming", Object.assign({}, incoming, { callType: type })));
  await act(async () => {
    fireEvent.click(screen.getByTestId("call-accept"));
  });
  await waitFor(() => expect(lkSessions.length).toBe(1));
  await act(async () => {
    lastLk().events.onState && lastLk().events.onState("connected");
    lastLk().events.onPeers([localPeer(), remotePeer()]);
  });
  return view;
}

beforeEach(() => {
  resetCallsApi();
  callsApi.current.mockImplementation(() => ({ unwrap: () => new Promise(() => {}) }));
  installFakeBroadcastChannel();
  sessionStorage.clear();
  lkSessions.length = 0;
  mockToast.mockClear();
  socket = makeFakeSocket();
  mockSocketCtx = { socket, isConnected: true, emit: jest.fn(), connectionEpoch: 0 };
  mockPreflight.mockResolvedValue({ mic: "ok", camera: null });
});

it("callee: accept joins the room with the mic on and the camera off for a voice call", async () => {
  await answeredCall();
  expect(lastLk().connect).toHaveBeenCalledWith("wss://lk", "rtok", { mic: true, camera: false });
  expect(screen.getByTestId("call-screen")).toBeInTheDocument();
  expect(screen.getByTestId("call-timer")).toHaveTextContent("0:00");
});

it("caller: rings out (no room yet), joins when the callee accepts", async () => {
  callsApi.initiate.mockReturnValue(ok({ data: { call: { _id: "c9" }, token: "ctok", url: "wss://lk" } }));
  mount();
  const { getCallApi } = require("./callBridge");
  await act(async () => {
    getCallApi().startCall({ id: "u2", name: "Mina", avatar: null }, "video");
  });
  await waitFor(() => expect(screen.getByTestId("call-status")).toHaveTextContent("Calling Mina…"));
  expect(lkSessions.length).toBe(0);
  act(() => socket.serverEmit("call:state", { callId: "c9", status: "active", type: "video" }));
  await waitFor(() => expect(lkSessions.length).toBe(1));
  expect(lastLk().connect).toHaveBeenCalledWith("wss://lk", "ctok", { mic: true, camera: true });
});

it("caller: declined -> '{name} declined', then the screen goes away", async () => {
  jest.useFakeTimers();
  callsApi.initiate.mockReturnValue(ok({ data: { call: { _id: "c9" }, token: "t", url: "u" } }));
  mount();
  const { getCallApi } = require("./callBridge");
  await act(async () => {
    getCallApi().startCall({ id: "u2", name: "Mina", avatar: null }, "audio");
  });
  act(() => socket.serverEmit("call:state", { callId: "c9", status: "rejected", outcome: "declined" }));
  expect(screen.getByTestId("call-ended")).toHaveTextContent("Mina declined");
  act(() => {
    jest.advanceTimersByTime(2500);
  });
  expect(screen.queryByTestId("call-screen")).not.toBeInTheDocument();
  jest.useRealTimers();
});

it("mute: unpublishes the mic and tells the peer", async () => {
  await answeredCall();
  await act(async () => {
    fireEvent.click(screen.getByTestId("call-mute"));
  });
  expect(lastLk().setMic).toHaveBeenCalledWith(false);
  expect(socket.emitted).toContainEqual({ event: "call:mute", data: { callId: "c1", isMuted: true } });
  expect(screen.getByTestId("call-mute")).toHaveAttribute("aria-pressed", "true");
});

it("camera on in a voice call upgrades it to video and tells the peer", async () => {
  await answeredCall("audio");
  await act(async () => {
    fireEvent.click(screen.getByTestId("call-camera"));
  });
  expect(lastLk().setCamera).toHaveBeenCalledWith(true);
  expect(callsApi.upgrade).toHaveBeenCalledWith("c1");
  expect(socket.emitted).toContainEqual({ event: "call:video-toggle", data: { callId: "c1", isVideoEnabled: true } });
});

it("camera denied mid-call: says why, nothing is upgraded", async () => {
  await answeredCall("audio");
  lastLk().setCamera.mockResolvedValueOnce("denied");
  await act(async () => {
    fireEvent.click(screen.getByTestId("call-camera"));
  });
  expect(callsApi.upgrade).not.toHaveBeenCalled();
  expect(mockToast).toHaveBeenCalledWith(expect.stringMatching(/can't use your camera/), expect.anything());
});

it("video call accepted with the camera denied joins audio-only", async () => {
  mockPreflight.mockResolvedValue({ mic: "ok", camera: "denied" });
  await answeredCall("video");
  expect(lastLk().connect).toHaveBeenCalledWith("wss://lk", "rtok", { mic: true, camera: false });
});

it("remote video is attached to the video element when the peer's camera is on", async () => {
  await answeredCall("video");
  const track = { attach: jest.fn(), detach: jest.fn() };
  await act(async () => {
    lastLk().events.onRemoteVideo("u2", track);
    lastLk().events.onPeers([localPeer(), remotePeer({ cameraOn: true })]);
  });
  const el = screen.getByTestId("call-remote-video");
  expect(track.attach).toHaveBeenCalledWith(el);
});

it("Safari autoplay: a 'Tap to enable sound' button calls startAudio", async () => {
  await answeredCall();
  act(() => lastLk().events.onAudioBlocked(true));
  await act(async () => {
    fireEvent.click(screen.getByTestId("call-enable-audio"));
  });
  expect(lastLk().startAudio).toHaveBeenCalled();
  act(() => lastLk().events.onAudioBlocked(false));
  expect(screen.queryByTestId("call-enable-audio")).not.toBeInTheDocument();
});

it("reconnecting: shows the chip and tells the peer, then clears", async () => {
  await answeredCall();
  act(() => lastLk().events.onState("reconnecting"));
  expect(screen.getByTestId("call-reconnecting")).toBeInTheDocument();
  expect(socket.emitted).toContainEqual({ event: "call:reconnecting", data: { callId: "c1" } });
  act(() => lastLk().events.onState("connected"));
  expect(screen.queryByTestId("call-reconnecting")).not.toBeInTheDocument();
  expect(socket.emitted).toContainEqual({ event: "call:reconnected", data: { callId: "c1" } });
});

it("the peer reconnecting (relay) shows the chip too", async () => {
  await answeredCall();
  act(() => socket.serverEmit("call:peer-reconnecting", { callId: "c1", userId: "u2" }));
  expect(screen.getByTestId("call-reconnecting")).toBeInTheDocument();
});

it("joined from another tab (duplicate identity): ends here quietly, no call:failed", async () => {
  await answeredCall();
  act(() => lastLk().events.onDisconnected("duplicate_identity"));
  expect(socket.emitted.find((e: any) => e.event === "call:failed")).toBeUndefined();
  expect(mockToast).toHaveBeenCalledWith("The call continued in another tab.", expect.anything());
});

it("lost connection for good: call:failed, 'The call dropped.'", async () => {
  await answeredCall();
  act(() => lastLk().events.onDisconnected("network"));
  expect(socket.emitted).toContainEqual({ event: "call:failed", data: { callId: "c1", reason: "Connection lost" } });
  expect(screen.getByTestId("call-ended")).toHaveTextContent("The call dropped.");
});

it("hang up: POST end, leaves the room", async () => {
  await answeredCall();
  await act(async () => {
    fireEvent.click(screen.getByTestId("call-hangup"));
  });
  expect(callsApi.end).toHaveBeenCalledWith({ callId: "c1", deviceId: "web-tab1" });
  expect(lastLk().disconnect).toHaveBeenCalled();
  expect(screen.getByTestId("call-ended")).toHaveTextContent("Call ended");
});

it("the other side hangs up: leaves the room", async () => {
  await answeredCall();
  act(() => socket.serverEmit("call:state", { callId: "c1", status: "ended", outcome: "completed", duration: 12 }));
  expect(lastLk().disconnect).toHaveBeenCalled();
});

it("unmount (sign-out) leaves the room", async () => {
  const view = await answeredCall();
  const session = lastLk();
  view.unmount();
  expect(session.disconnect).toHaveBeenCalled();
});
```

- [ ] **Step 3: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false CallEngine.test
```
Expected: FAIL — no `call-screen` is rendered after accept and no LiveKit session is created.

- [ ] **Step 4: Implement**

Create `src/components/calls/lib/callOutcomeText.ts`:

```ts
import { CallState } from "./callMachine";

type T = (key: string, opts?: any) => string;

/** The line an ended call shows for 2.5 s, or null when there is nothing to say. */
export function callOutcomeText(s: CallState, t: T): string | null {
  if (s.phase !== "ended") return null;
  if (s.endReason === "elsewhere" || s.endReason === "duplicate") return null;
  if (s.direction === "in" && !s.connectedAt) return null; // declined / missed here: the banner just closes
  const name = (s.peer && s.peer.name) || t("calls.incoming.someone") || "Someone";
  switch (s.outcome) {
    case "declined":
      return t("calls.outcome.declined", { name }) || `${name} declined`;
    case "no_answer":
      return t("calls.outcome.noAnswer") || "No answer";
    case "busy":
      return t("calls.outcome.busy", { name }) || `${name} was on another call`;
    case "cancelled":
      return t("calls.outcome.cancelled") || "Call cancelled";
    case "failed":
      return t("calls.outcome.failed") || "The call dropped.";
    default:
      return t("calls.outcome.ended") || "Call ended";
  }
}
```

Create `src/components/calls/useCallMedia.ts`:

```ts
import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { createLkSession, LkSession, LkPeer, LkVideoTrack } from "../../lib/livekit/lkSession";
import { useUpgradeCallMutation } from "../../store/slices/callsSlice";
import { mediaProblemText } from "./lib/callErrors";
import { CallEngineApi } from "./useCallEngine";

export interface CallMedia {
  micOn: boolean;
  cameraOn: boolean;
  audioBlocked: boolean;
  reconnecting: boolean;
  remoteVideo: LkVideoTrack | null;
  localVideo: LkVideoTrack | null;
  toggleMic(): Promise<void>;
  toggleCamera(): Promise<void>;
  enableAudio(): Promise<void>;
}

/**
 * The LiveKit side of a 1:1 call, through the shared wrapper (P4-ROOM-1).
 * Room "call:<callId>", identity = user id, token from accept / initiate /
 * current (be/controllers/callController.js). Mirrors the app's
 * CallLiveKitManager wiring (call_manager.dart _wireLiveKit).
 */
export function useCallMedia(engine: CallEngineApi, socket: any): CallMedia {
  const { t } = useTranslation();
  const { state, dispatch } = engine;
  const [upgradeCall] = useUpgradeCallMutation();
  const sessionRef = useRef<LkSession | null>(null);
  const callIdRef = useRef<string | null>(null);
  const wasReconnecting = useRef(false);
  const [micOn, setMicOn] = useState(true);
  const [cameraOn, setCameraOn] = useState(false);
  const [audioBlocked, setAudioBlocked] = useState(false);
  const [reconnecting, setReconnecting] = useState(false);
  const [remoteVideo, setRemoteVideo] = useState<LkVideoTrack | null>(null);
  const [localVideo, setLocalVideo] = useState<LkVideoTrack | null>(null);

  const relay = (event: string, data: any) => {
    if (socket && callIdRef.current) socket.emit(event, Object.assign({ callId: callIdRef.current }, data), () => {});
  };

  const leave = () => {
    const s = sessionRef.current;
    sessionRef.current = null;
    if (s) s.disconnect().catch(() => {});
    setRemoteVideo(null);
    setLocalVideo(null);
    setReconnecting(false);
    setAudioBlocked(false);
  };

  // Join when the call reaches "connecting" with credentials.
  useEffect(() => {
    if (state.phase !== "connecting" || !state.lk || sessionRef.current) return;
    const callId = state.callId as string;
    callIdRef.current = callId;
    const wantCamera = state.type === "video" && engine.cameraAllowed;
    setMicOn(true);
    setCameraOn(wantCamera);
    const session = createLkSession({
      onPeers: (peers: LkPeer[]) => {
        const remote = peers.filter((p) => !p.isLocal)[0];
        if (!remote) return;
        dispatch({ type: "MEDIA_CONNECTED", at: Date.now() });
        dispatch({ type: "PEER_VIDEO", callId, on: remote.cameraOn });
        dispatch({ type: "PEER_MUTE", callId, muted: !remote.micOn });
      },
      onState: (s) => {
        if (s === "reconnecting") {
          wasReconnecting.current = true;
          setReconnecting(true);
          relay("call:reconnecting", {});
        } else if (s === "connected") {
          setReconnecting(false);
          if (wasReconnecting.current) relay("call:reconnected", {});
          wasReconnecting.current = false;
        }
      },
      onDisconnected: (reason: string) => {
        if (reason === "client" || sessionRef.current !== session) return;
        if (reason === "duplicate_identity") {
          engine.setNotice(t("calls.notices.otherTab") || "The call continued in another tab.");
          dispatch({ type: "LOCAL_END", outcome: null, reason: "duplicate" });
        } else if (reason === "room_deleted") {
          dispatch({ type: "LOCAL_END", outcome: "completed", reason: "remote" });
        } else {
          relay("call:failed", { reason: "Connection lost" });
          dispatch({ type: "LOCAL_END", outcome: "failed", reason: "failed" });
        }
      },
      onAudioBlocked: (blocked: boolean) => setAudioBlocked(blocked),
      onRemoteVideo: (_identity: string, track: LkVideoTrack | null) => setRemoteVideo(track),
    });
    sessionRef.current = session;
    session
      .connect(state.lk.url, state.lk.token, { mic: true, camera: wantCamera })
      .then((result) => {
        if (sessionRef.current !== session) return;
        if (wantCamera) setLocalVideo(session.localVideo());
        if (result !== "ok" && wantCamera) {
          setCameraOn(false);
          setLocalVideo(null);
          engine.setNotice(mediaProblemText("camera", result, t as any));
          relay("call:video-toggle", { isVideoEnabled: false });
        }
      })
      .catch(() => {
        if (sessionRef.current !== session) return;
        relay("call:failed", { reason: "Could not connect" });
        dispatch({ type: "LOCAL_END", outcome: "failed", reason: "failed" });
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state.phase, state.lk]);

  // Leave when the call is over (either side), and on unmount.
  useEffect(() => {
    if ((state.phase === "ended" || state.phase === "idle") && sessionRef.current) leave();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state.phase]);
  useEffect(() => () => leave(), []);

  const toggleMic = useCallback(async () => {
    const s = sessionRef.current;
    if (!s) return;
    const next = !micOn;
    const result = await s.setMic(next);
    if (result !== "ok") {
      engine.setNotice(mediaProblemText("mic", result, t as any));
      return;
    }
    setMicOn(next);
    relay("call:mute", { isMuted: !next });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [micOn, t]);

  const toggleCamera = useCallback(async () => {
    const s = sessionRef.current;
    if (!s) return;
    const next = !cameraOn;
    const result = await s.setCamera(next);
    if (result !== "ok") {
      engine.setNotice(mediaProblemText("camera", result, t as any));
      return;
    }
    setCameraOn(next);
    setLocalVideo(next ? s.localVideo() : null);
    if (next && state.type !== "video" && callIdRef.current) {
      try {
        await upgradeCall(callIdRef.current).unwrap();
        dispatch({ type: "TYPE_VIDEO" });
      } catch (e) {
        /* the call stays "voice" in history; the camera still works */
      }
    }
    relay("call:video-toggle", { isVideoEnabled: next });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cameraOn, state.type, t]);

  const enableAudio = useCallback(async () => {
    const s = sessionRef.current;
    if (s && (await s.startAudio())) setAudioBlocked(false);
  }, []);

  return { micOn, cameraOn, audioBlocked, reconnecting, remoteVideo, localVideo, toggleMic, toggleCamera, enableAudio };
}
```

Create `src/components/calls/CallScreen.tsx`:

```tsx
import React, { useEffect, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { Mic, MicOff, PhoneOff, Video, VideoOff, Volume2, WifiOff } from "lucide-react";
import { CallState } from "./lib/callMachine";
import { callOutcomeText } from "./lib/callOutcomeText";
import { createRinger } from "./lib/ringer";
import { CallMedia } from "./useCallMedia";
import "./calls.css";

const fmt = (secs: number) => `${Math.floor(secs / 60)}:${("0" + (secs % 60)).slice(-2)}`;

function useTicker(since: number | null): number {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    if (!since) return undefined;
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, [since]);
  return since ? Math.max(0, Math.floor((now - since) / 1000)) : 0;
}

const VideoView: React.FC<{ track: any; testId: string; className: string; muted?: boolean }> = ({ track, testId, className, muted }) => {
  const ref = useRef<HTMLVideoElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || !track) return undefined;
    track.attach(el);
    return () => track.detach(el);
  }, [track]);
  return <video ref={ref} data-testid={testId} className={className} autoPlay playsInline muted={muted} />;
};

/** Outgoing ring, connecting, the call itself, and the 2.5 s "ended" line. */
const CallScreen: React.FC<{ state: CallState; media: CallMedia; onHangUp(): void }> = ({ state, media, onHangUp }) => {
  const { t } = useTranslation();
  const name = (state.peer && state.peer.name) || t("calls.incoming.someone") || "Someone";
  const secs = useTicker(state.phase === "connected" ? state.connectedAt : null);
  const ringback = useMemo(() => createRinger("/sounds/ringback.m4a", () => {}), []);

  useEffect(() => {
    if (state.phase === "outgoing") ringback.start();
    else ringback.stop();
    return () => ringback.stop();
  }, [state.phase, ringback]);

  const ended = callOutcomeText(state, t as any);
  const status =
    state.phase === "outgoing"
      ? t("calls.screen.calling", { name }) || `Calling ${name}…`
      : state.phase === "connecting"
      ? t("calls.screen.connecting") || "Connecting…"
      : null;
  const showRemoteVideo = state.phase === "connected" && !!media.remoteVideo && state.peerVideo;
  const live = state.phase !== "ended";

  return (
    <div className="call-screen" data-testid="call-screen" role="dialog" aria-label={t("calls.screen.label", { name }) || `Call with ${name}`}>
      <div className="call-stage">
        {showRemoteVideo ? (
          <VideoView track={media.remoteVideo} testId="call-remote-video" className="call-remote-video" />
        ) : (
          <div className="call-peer">
            <img className="call-peer-avatar" src={(state.peer && state.peer.avatar) || "/default-avatar.png"} alt="" />
            <p className="call-peer-name">{name}</p>
          </div>
        )}
        {media.cameraOn && media.localVideo && live && (
          <VideoView track={media.localVideo} testId="call-local-video" className="call-local-video" muted />
        )}
      </div>

      <div className="call-info">
        {status && <p data-testid="call-status">{status}</p>}
        {state.phase === "connected" && <p data-testid="call-timer">{fmt(secs)}</p>}
        {ended && <p data-testid="call-ended">{ended}</p>}
        {live && (media.reconnecting || state.peerReconnecting) && (
          <p className="call-chip" data-testid="call-reconnecting">
            <WifiOff size={14} aria-hidden="true" /> {t("calls.screen.reconnecting") || "Reconnecting…"}
          </p>
        )}
        {live && state.phase === "connected" && state.peerMuted && (
          <p className="call-chip" data-testid="call-peer-muted">
            <MicOff size={14} aria-hidden="true" /> {t("calls.screen.peerMuted", { name }) || `${name} is muted`}
          </p>
        )}
        {live && media.audioBlocked && (
          <button type="button" className="call-btn call-btn--accept" data-testid="call-enable-audio" onClick={() => void media.enableAudio()}>
            <Volume2 size={16} aria-hidden="true" /> {t("calls.screen.enableAudio") || "Tap to enable sound"}
          </button>
        )}
      </div>

      {live && (
        <div className="call-controls">
          {(state.phase === "connecting" || state.phase === "connected") && (
            <>
              <button
                type="button"
                className="call-round"
                data-testid="call-mute"
                aria-pressed={!media.micOn}
                aria-label={media.micOn ? t("calls.screen.mute") || "Mute" : t("calls.screen.unmute") || "Unmute"}
                onClick={() => void media.toggleMic()}
              >
                {media.micOn ? <Mic size={22} aria-hidden="true" /> : <MicOff size={22} aria-hidden="true" />}
              </button>
              <button
                type="button"
                className="call-round"
                data-testid="call-camera"
                aria-pressed={media.cameraOn}
                aria-label={media.cameraOn ? t("calls.screen.cameraOff") || "Turn camera off" : t("calls.screen.cameraOn") || "Turn camera on"}
                onClick={() => void media.toggleCamera()}
              >
                {media.cameraOn ? <Video size={22} aria-hidden="true" /> : <VideoOff size={22} aria-hidden="true" />}
              </button>
            </>
          )}
          <button
            type="button"
            className="call-round call-round--hangup"
            data-testid="call-hangup"
            aria-label={state.phase === "outgoing" ? t("calls.screen.cancel") || "Cancel call" : t("calls.screen.hangUp") || "Hang up"}
            onClick={onHangUp}
          >
            <PhoneOff size={22} aria-hidden="true" />
          </button>
        </div>
      )}
    </div>
  );
};

export default CallScreen;
```

Append to `src/components/calls/calls.css`:

```css
.call-screen { position: fixed; inset: 0; z-index: 2000; background: #0b1220; color: #fff; display: flex; flex-direction: column; align-items: center; justify-content: space-between; padding: 24px 16px; }
.call-stage { position: relative; flex: 1; width: 100%; display: flex; align-items: center; justify-content: center; }
.call-remote-video { width: 100%; height: 100%; object-fit: contain; background: #000; border-radius: 12px; }
.call-local-video { position: absolute; inset-block-end: 12px; inset-inline-end: 12px; width: 28%; max-width: 200px; border-radius: 12px; background: #000; transform: scaleX(-1); }
.call-peer { text-align: center; }
.call-peer-avatar { width: 112px; height: 112px; border-radius: 50%; object-fit: cover; }
.call-peer-name { margin-block-start: 12px; font-size: 22px; font-weight: 700; }
.call-info { min-height: 72px; display: flex; flex-direction: column; align-items: center; gap: 6px; text-align: center; }
.call-info p { margin: 0; }
.call-chip { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 999px; background: rgba(255, 255, 255, 0.12); font-size: 13px; }
.call-controls { display: flex; gap: 20px; padding-block: 16px; }
.call-round { width: 60px; height: 60px; border-radius: 50%; border: 0; background: #374151; color: #fff; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; }
.call-round[aria-pressed="true"] { background: #f9fafb; color: #111827; }
.call-round--hangup { background: #dc2626; }
```

Replace `src/components/calls/CallEngine.tsx`:

```tsx
import React, { useEffect } from "react";
import { toast } from "react-toastify";
import { useSocket } from "../chat/hooks/useSocket";
import { useCallEngine } from "./useCallEngine";
import { useCallMedia } from "./useCallMedia";
import { callOutcomeText } from "./lib/callOutcomeText";
import IncomingCallBanner from "./IncomingCallBanner";
import CallScreen from "./CallScreen";
import CallErrorDialog from "./CallErrorDialog";
import { useTranslation } from "react-i18next";

/** The lazily loaded call engine (chunk "calls"). One per tab. */
const CallEngine: React.FC = () => {
  const { t } = useTranslation();
  const { socket } = useSocket() as any;
  const engine = useCallEngine();
  const media = useCallMedia(engine, socket);
  const { state, notice, clearNotice } = engine;

  useEffect(() => {
    if (!notice) return;
    toast.info(notice, { toastId: `call-notice-${notice}` });
    clearNotice();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [notice]);

  const dialog = engine.callError ? <CallErrorDialog error={engine.callError} onClose={engine.clearCallError} /> : null;

  if (state.phase === "incoming") {
    return (
      <>
        <IncomingCallBanner
          key={state.callId || "incoming"}
          peer={state.peer}
          type={state.type}
          accepting={state.accepting}
          onAccept={() => void engine.accept()}
          onDecline={() => void engine.decline()}
          onDeclineWithMessage={(text) => void engine.decline(text)}
        />
        {dialog}
      </>
    );
  }
  const showScreen =
    state.phase === "outgoing" ||
    state.phase === "connecting" ||
    state.phase === "connected" ||
    (state.phase === "ended" && callOutcomeText(state, t as any) !== null);
  if (showScreen) {
    return (
      <>
        <CallScreen state={state} media={media} onHangUp={() => void engine.hangUp()} />
        {dialog}
      </>
    );
  }
  return dialog;
};

export default CallEngine;
```

Add to `eng.json` under `calls`:

```json
"screen": {
  "label": "Call with {{name}}",
  "calling": "Calling {{name}}…",
  "connecting": "Connecting…",
  "reconnecting": "Reconnecting…",
  "peerMuted": "{{name}} is muted",
  "enableAudio": "Tap to enable sound",
  "mute": "Mute",
  "unmute": "Unmute",
  "cameraOn": "Turn camera on",
  "cameraOff": "Turn camera off",
  "cancel": "Cancel call",
  "hangUp": "Hang up"
},
"outcome": {
  "declined": "{{name}} declined",
  "noAnswer": "No answer",
  "busy": "{{name}} was on another call",
  "cancelled": "Call cancelled",
  "failed": "The call dropped.",
  "ended": "Call ended"
}
```
and under `calls.notices`: `"otherTab": "The call continued in another tab."`.

- [ ] **Step 5: Run → PASS**

```bash
CI=true npm test -- --watchAll=false calls/
```
Expected: every suite under `src/components/calls/` passes.

- [ ] **Step 6: TS 3.7 / LiveKit boundary check**

```bash
grep -rn "from ['\"]livekit-client['\"]" src | grep -v "src/lib/livekit/livekitLoader.js" ; echo "direct imports above (expect none)"
npx tsc -p . 2>&1 | grep "error TS" | grep -c -i livekit
```
Expected: no direct import lines; `0`.

- [ ] **Step 7: Commit**

```bash
git add src/components/calls/useCallMedia.ts src/components/calls/CallScreen.tsx src/components/calls/lib/callOutcomeText.ts src/components/calls/testing/fakeLkSession.ts src/components/calls/CallEngine.test.tsx src/components/calls/CallEngine.tsx src/components/calls/calls.css src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): in-call screen over the shared LiveKit wrapper

Joins call:<callId> when the call connects (callee after accept, caller
after the server's active, a reloaded tab after rejoin); mute and
camera relay to the peer, camera-on in a voice call upgrades it;
remote video, "tap to enable sound" for blocked autoplay, a
reconnecting chip both ways, ringback while ringing out, and the
outcome line after the call. A duplicate identity (joined in another
tab) ends quietly; a lost connection reports call:failed.

Still open (Phase 4 calls): entry points (P4-CALL-9), history, flag-off
test, I18N, PUSH.
MSG
```

---

### Task P4-CALL-9: Entry points — chat header, profile, "Call back" on the chat call card

**Files:**
- Create: `src/components/calls/CallButtons.tsx`, `src/components/calls/CallBackButton.tsx`, `src/components/calls/CallButtons.test.tsx`, `src/components/chat/components/CallMessageCard.callback.test.tsx`
- Modify: `src/components/chat/ChatContent.tsx` — the `header-actions` block (`origin/main` `:1930-1946`; anchor on the comment `{/* Voice/Video call buttons removed — calling is mobile-only per` which this task deletes)
- Modify: `src/components/profile/parts/ProfileActions.tsx` — after the `action-message` button (`origin/main` `:194-203`)
- Modify: `src/components/chat/components/CallMessageCard.tsx` (P3-CHAT-10) — renders `CallBackButton` under the label
- Modify (mocks only, so the existing suites keep their store-less setup): `src/components/chat/ChatContent.test.tsx`, `src/components/profile/parts/ProfileActions.test.tsx`, `src/components/chat/MessageBubble.test.tsx`
- Modify: `src/utils/locales/eng.json` (`calls.buttons.*`)

**Interfaces:**
- Consumes: `useWebFlag("webCallsEnabled")` (P4-0), `useCallApi()` (P4-CALL-4); `CallData` from `src/components/chat/lib/callLabel.ts` (P3-CHAT-10: `participants: string[]`, `initiator`, `type`).
- Produces:
  - `CallButtons` props `{ peer: { id: string; name: string; avatar: string | null }; variant: "header" | "profile" }` — renders nothing unless the flag is on **and** the engine is registered; testids `call-start-audio`, `call-start-video`; both disabled while `inCall`.
  - `CallBackButton` props `{ otherId: string | null; otherName: string; type: "audio" | "video" }` — same visibility rule; testid `call-card-callback`.
  - `callBackTarget(callData, viewerId): string | null` (exported from `CallBackButton.tsx`) — the participant that is not the viewer.

- [ ] **Step 1: Write the failing tests**

Create `src/components/calls/CallButtons.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { mockAppConfig } from "../../utils/testing/mockWebFlags";
import { registerCallApi } from "./callBridge";
import CallButtons from "./CallButtons";
import CallBackButton, { callBackTarget } from "./CallBackButton";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const peer = { id: "u2", name: "Mina", avatar: null };
const startCall = jest.fn();

beforeEach(() => {
  startCall.mockClear();
  registerCallApi(null);
});

it("hidden while the flag is off, even with an engine", () => {
  mockAppConfig({ webCallsEnabled: false });
  registerCallApi({ startCall, inCall: false });
  render(<CallButtons peer={peer} variant="header" />);
  expect(screen.queryByTestId("call-start-audio")).not.toBeInTheDocument();
});

it("hidden while the engine is not loaded (signed out, chunk failed)", () => {
  mockAppConfig({ webCallsEnabled: true });
  render(<CallButtons peer={peer} variant="header" />);
  expect(screen.queryByTestId("call-start-audio")).not.toBeInTheDocument();
});

it("voice and video buttons start the call", () => {
  mockAppConfig({ webCallsEnabled: true });
  registerCallApi({ startCall, inCall: false });
  render(<CallButtons peer={peer} variant="profile" />);
  fireEvent.click(screen.getByTestId("call-start-audio"));
  expect(startCall).toHaveBeenLastCalledWith(peer, "audio");
  fireEvent.click(screen.getByTestId("call-start-video"));
  expect(startCall).toHaveBeenLastCalledWith(peer, "video");
  expect(screen.getByTestId("call-start-video")).toHaveAttribute("aria-label", "Video call Mina");
});

it("disabled during a call; appears when the engine registers later", () => {
  mockAppConfig({ webCallsEnabled: true });
  render(<CallButtons peer={peer} variant="header" />);
  act(() => registerCallApi({ startCall, inCall: true }));
  expect(screen.getByTestId("call-start-audio")).toBeDisabled();
});

describe("Call back", () => {
  it("finds the other participant", () => {
    expect(callBackTarget({ participants: ["me", "u2"] } as any, "me")).toBe("u2");
    expect(callBackTarget({ participants: [{ _id: "u2" }, { _id: "me" }] } as any, "me")).toBe("u2");
    expect(callBackTarget({ participants: [] } as any, "me")).toBe(null);
    expect(callBackTarget(null, "me")).toBe(null);
  });

  it("calls back with the same kind of call", () => {
    mockAppConfig({ webCallsEnabled: true });
    registerCallApi({ startCall, inCall: false });
    render(<CallBackButton otherId="u2" otherName="Mina" type="video" />);
    fireEvent.click(screen.getByTestId("call-card-callback"));
    expect(startCall).toHaveBeenCalledWith({ id: "u2", name: "Mina", avatar: null }, "video");
  });

  it("hidden without a target or while the flag is off", () => {
    mockAppConfig({ webCallsEnabled: true });
    registerCallApi({ startCall, inCall: false });
    const { unmount } = render(<CallBackButton otherId={null} otherName="Mina" type="audio" />);
    expect(screen.queryByTestId("call-card-callback")).not.toBeInTheDocument();
    unmount();
    mockAppConfig({ webCallsEnabled: false });
    render(<CallBackButton otherId="u2" otherName="Mina" type="audio" />);
    expect(screen.queryByTestId("call-card-callback")).not.toBeInTheDocument();
  });
});
```

Create `src/components/chat/components/CallMessageCard.callback.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import CallMessageCard from "./CallMessageCard";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("../../calls/CallBackButton", () => {
  const actual = jest.requireActual("../../calls/CallBackButton");
  return {
    __esModule: true,
    callBackTarget: actual.callBackTarget,
    default: (props: any) => <span data-testid="callback-probe" data-other={props.otherId} data-type={props.type} />,
  };
});

it("offers a call back to the other participant, same call type", () => {
  render(
    <CallMessageCard
      callData={{ initiator: "u2", participants: ["u2", "me"], type: "video", outcome: "no_answer", duration: 0 } as any}
      viewerId="me"
      isSent={false}
      otherName="Mina"
    />
  );
  const probe = screen.getByTestId("callback-probe");
  expect(probe).toHaveAttribute("data-other", "u2");
  expect(probe).toHaveAttribute("data-type", "video");
});
```

Append to `src/components/chat/ChatContent.test.tsx` (and add the mock at the top, next to the other `jest.mock` calls):

```tsx
jest.mock("../calls/CallButtons", () => ({
  __esModule: true,
  default: (props: any) => <div data-testid="call-buttons" data-peer={props.peer.id} data-variant={props.variant} />,
}));
```

```tsx
it("puts the call buttons in the chat header for the person in the thread", async () => {
  renderChat("/chat/u2");
  const buttons = await screen.findByTestId("call-buttons");
  expect(buttons).toHaveAttribute("data-peer", "u2");
  expect(buttons).toHaveAttribute("data-variant", "header");
});
```

In `src/components/profile/parts/ProfileActions.test.tsx` add next to the other mocks:

```tsx
jest.mock("../../calls/CallButtons", () => ({
  __esModule: true,
  default: (props: any) => <div data-testid="call-buttons" data-peer={props.peer.id} />,
}));
```
and append:
```tsx
it("offers calls on someone else's profile, never on your own", () => {
  const { unmount } = renderActions();
  expect(screen.getByTestId("call-buttons")).toHaveAttribute("data-peer", "u2");
  unmount();
  renderActions({ isOwn: true, userId: "me" });
  expect(screen.queryByTestId("call-buttons")).not.toBeInTheDocument();
});
```

In `src/components/chat/MessageBubble.test.tsx` add next to the other mocks (the call card there has no store):

```tsx
jest.mock("../calls/CallBackButton", () => {
  const actual = jest.requireActual("../calls/CallBackButton");
  return { __esModule: true, callBackTarget: actual.callBackTarget, default: () => null };
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false CallButtons CallMessageCard.callback ChatContent.test ProfileActions MessageBubble
```
Expected: FAIL — `./CallButtons` / `../../calls/CallBackButton` not found; no `call-buttons` in the header or on the profile.

- [ ] **Step 3: Implement**

Create `src/components/calls/CallButtons.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { Phone, Video } from "lucide-react";
import { useWebFlag } from "../../utils/webFlags";
import { useCallApi } from "./callBridge";

interface Props {
  peer: { id: string; name: string; avatar: string | null };
  variant: "header" | "profile";
}

/**
 * Voice and video call buttons (chat header, profile). Nothing at all unless
 * WEB_CALLS_ENABLED is on and the call engine is loaded for this signed-in
 * tab -- the same rule every Phase 4 entry point follows.
 */
const CallButtons: React.FC<Props> = ({ peer, variant }) => {
  const { t } = useTranslation();
  const enabled = useWebFlag("webCallsEnabled");
  const api = useCallApi();
  if (!enabled || !api || !peer.id) return null;
  const cls = variant === "header" ? "action-btn" : "call-profile-btn";
  const voice = t("calls.buttons.voice", { name: peer.name }) || `Voice call ${peer.name}`;
  const video = t("calls.buttons.video", { name: peer.name }) || `Video call ${peer.name}`;
  return (
    <>
      <button type="button" className={cls} data-testid="call-start-audio" disabled={api.inCall} title={voice} aria-label={voice} onClick={() => api.startCall(peer, "audio")}>
        <Phone size={variant === "header" ? 20 : 16} aria-hidden="true" />
      </button>
      <button type="button" className={cls} data-testid="call-start-video" disabled={api.inCall} title={video} aria-label={video} onClick={() => api.startCall(peer, "video")}>
        <Video size={variant === "header" ? 20 : 16} aria-hidden="true" />
      </button>
    </>
  );
};

export default CallButtons;
```

Create `src/components/calls/CallBackButton.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { PhoneCall } from "lucide-react";
import { useWebFlag } from "../../utils/webFlags";
import { useCallApi } from "./callBridge";

/** The participant of a call message who is not the viewer (callData.participants: ids, or populated users). */
export function callBackTarget(callData: any, viewerId: string): string | null {
  const list: any[] = callData && Array.isArray(callData.participants) ? callData.participants : [];
  for (let i = 0; i < list.length; i++) {
    const id = list[i] && typeof list[i] === "object" ? String(list[i]._id || "") : String(list[i] || "");
    if (id && id !== String(viewerId)) return id;
  }
  return null;
}

const CallBackButton: React.FC<{ otherId: string | null; otherName: string; type: "audio" | "video" }> = ({ otherId, otherName, type }) => {
  const { t } = useTranslation();
  const enabled = useWebFlag("webCallsEnabled");
  const api = useCallApi();
  if (!enabled || !api || !otherId) return null;
  return (
    <button
      type="button"
      className="call-card-callback"
      data-testid="call-card-callback"
      disabled={api.inCall}
      onClick={() => api.startCall({ id: otherId, name: otherName, avatar: null }, type)}
    >
      <PhoneCall size={14} aria-hidden="true" /> {t("calls.buttons.callBack") || "Call back"}
    </button>
  );
};

export default CallBackButton;
```

`src/components/chat/components/CallMessageCard.tsx` (P3-CHAT-10): add the import

```tsx
import CallBackButton, { callBackTarget } from "../../calls/CallBackButton";
```
and inside `.call-card-body`, after the duration span:
```tsx
        <CallBackButton
          otherId={callBackTarget(callData, viewerId)}
          otherName={otherName}
          type={label.isVideo ? "video" : "audio"}
        />
```

`src/components/chat/ChatContent.tsx`: add `import CallButtons from "../calls/CallButtons";` next to `import ChatInfoPanel from "./ChatInfoPanel";`, and in `header-actions` replace

```tsx
            {/* Voice/Video call buttons removed — calling is mobile-only per
                the documented web scope (Community/Chats/Moments/Profile). */}
```
with
```tsx
            {/* Voice/video calls (Phase 4): render nothing unless
                WEB_CALLS_ENABLED is on and the call engine is loaded. */}
            <CallButtons
              peer={{ id: selectedUser, name: userName, avatar: profilePicture || null }}
              variant="header"
            />
```

`src/components/profile/parts/ProfileActions.tsx`: add `import CallButtons from "../../calls/CallButtons";` and right after the closing `</button>` of `data-testid="action-message"` insert

```tsx
      <CallButtons peer={{ id: userId, name: personName, avatar: null }} variant="profile" />
```

Append to `src/components/calls/calls.css` and import it from `CallButtons.tsx` (`import "./calls.css";`):

```css
.call-profile-btn { display: inline-flex; align-items: center; justify-content: center; width: 38px; height: 38px; border-radius: 999px; border: 1px solid #e5e7eb; background: transparent; cursor: pointer; }
.call-profile-btn:disabled, .call-card-callback:disabled { opacity: 0.5; cursor: default; }
.call-card-callback { display: inline-flex; align-items: center; gap: 4px; margin-block-start: 4px; padding: 0; border: 0; background: none; color: inherit; font-size: 12px; font-weight: 600; text-decoration: underline; cursor: pointer; }
```

Add to `eng.json` under `calls`:

```json
"buttons": {
  "voice": "Voice call {{name}}",
  "video": "Video call {{name}}",
  "callBack": "Call back"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false CallButtons CallMessageCard ChatContent.test ProfileActions MessageBubble chatStyling
```
Expected: all pass (`chatStyling` keeps its rules: the new CSS lives in `calls.css`, not in the chat stylesheets).

- [ ] **Step 5: Commit**

```bash
git add src/components/calls/CallButtons.tsx src/components/calls/CallBackButton.tsx src/components/calls/CallButtons.test.tsx src/components/chat/components/CallMessageCard.callback.test.tsx src/components/chat/components/CallMessageCard.tsx src/components/chat/ChatContent.tsx src/components/chat/ChatContent.test.tsx src/components/profile/parts/ProfileActions.tsx src/components/profile/parts/ProfileActions.test.tsx src/components/chat/MessageBubble.test.tsx src/components/calls/calls.css src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): call buttons in the chat header and on profiles, call back from a call card

Voice/video buttons and "Call back" render nothing unless
webCallsEnabled is on and the call engine is loaded; they are disabled
during a call. The stale "calling is mobile-only" comment goes.

Still open (Phase 4 calls): history + missed badge (P4-CALL-10),
flag-off test, I18N, PUSH.
MSG
```

---

### Task P4-CALL-10: Call history page `/calls` and the missed-call badge

**Files:**
- Create: `src/components/calls/CallHistoryPage.tsx`, `src/components/calls/CallHistoryPage.test.tsx`, `src/components/calls/lib/historyLabel.ts`, `src/components/calls/CallsNavLink.tsx`, `src/components/calls/CallsNavLink.test.tsx`
- Modify: `src/router/routes.tsx` (lazy import + flagged route), `src/components/navbar/MainNavbar.tsx` (user dropdown after "My moments", mobile menu after "Moments"), `src/components/calls/testing/callsSliceMock.ts` (history + missed count hooks)
- Modify: `src/utils/locales/eng.json` (`calls.history.*`, `calls.nav.*`)

**Interfaces:**
- Consumes: `GET /calls?page&limit` (`useGetCallHistoryQuery`), `GET /calls/missed/count` (`useGetMissedCallCountQuery`), `POST /calls/missed/seen` (`useMarkMissedCallsSeenMutation`) (P4-CALL-1); `call:state` socket event (refresh the badge); `FlagRoute` (P4-0); `CallBackButton` (P4-CALL-9). App reference for the row labels: `lib/l10n/app_en.arb` `callLabelOutgoing` / `callLabelIncoming` / `callLabelNoAnswer` / `callLabelMissed` / `callLabelCancelled` / `callLabelDeclinedOutgoing` / `callLabelDeclinedIncoming` / `callLabelBusy`.
- Produces: route `/calls` (404 while the flag is off); `historyLabel(item, t): { text: string; missed: boolean }`; `CallsNavLink` props `{ variant: "dropdown" | "mobile"; onNavigate(): void }`, testids `nav-calls`, `calls-missed-badge`; `CallHistoryPage` testids `call-history`, `call-history-row`, `call-history-more`, `call-history-empty`.

- [ ] **Step 1: Write the failing tests**

Extend `src/components/calls/testing/callsSliceMock.ts` — add to `callsApi`:

```ts
  history: jest.fn((_arg: any, _opts?: any) => ({ data: { items: [], hasMore: false }, isLoading: false, isFetching: false })),
  missedCount: jest.fn((_arg: any, _opts?: any) => ({ data: 0, refetch: jest.fn() })),
```
and to the object `callsSliceMock()` returns:
```ts
    useGetCallHistoryQuery: (arg: any, opts?: any) => callsApi.history(arg, opts),
    useGetMissedCallCountQuery: (arg: any, opts?: any) => callsApi.missedCount(arg, opts),
```
(`resetCallsApi` clears them with the rest; tests set `mockImplementation` as needed.)

Create `src/components/calls/CallHistoryPage.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { callsApi, resetCallsApi } from "./testing/callsSliceMock";
import CallHistoryPage from "./CallHistoryPage";
import { historyLabel } from "./lib/historyLabel";

jest.mock("../../store/slices/callsSlice", () => require("./testing/callsSliceMock").callsSliceMock());
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("./CallBackButton", () => ({
  __esModule: true,
  callBackTarget: () => null,
  default: (p: any) => <span data-testid="row-callback" data-other={p.otherId} />,
}));

const t = () => "";
const row = (over: any) =>
  Object.assign(
    { id: "c1", callUuid: null, type: "audio", direction: "in", outcome: "completed", duration: 75, otherParty: { id: "u2", name: "Mina", avatar: null }, createdAt: "2026-10-16T10:00:00Z" },
    over
  );

describe("historyLabel (the app's call labels)", () => {
  it.each([
    [{ direction: "out", outcome: "completed", type: "audio" }, "Outgoing voice call", false],
    [{ direction: "in", outcome: "completed", type: "video" }, "Incoming video call", false],
    [{ direction: "out", outcome: "no_answer", type: "audio" }, "Voice call · No answer", false],
    [{ direction: "in", outcome: "no_answer", type: "audio" }, "Missed voice call", true],
    [{ direction: "in", outcome: "cancelled", type: "video" }, "Missed video call", true],
    [{ direction: "out", outcome: "cancelled", type: "audio" }, "Cancelled voice call", false],
    [{ direction: "out", outcome: "declined", type: "video" }, "Video call declined", false],
    [{ direction: "in", outcome: "declined", type: "audio" }, "Declined voice call", false],
    [{ direction: "out", outcome: "busy", type: "audio" }, "Mina was on another call", false],
    [{ direction: "in", outcome: null, type: "audio" }, "Incoming voice call", false],
  ])("%j", (over, text, missed) => {
    expect(historyLabel(row(over), t)).toEqual({ text, missed });
  });
});

beforeEach(() => resetCallsApi());

it("marks missed calls seen when opened and lists the calls", () => {
  callsApi.history.mockImplementation(() => ({
    data: { items: [row({}), row({ id: "c2", direction: "in", outcome: "no_answer" })], hasMore: false },
    isLoading: false,
    isFetching: false,
  }));
  render(
    <MemoryRouter>
      <CallHistoryPage />
    </MemoryRouter>
  );
  expect(callsApi.markSeen).toHaveBeenCalled();
  const rows = screen.getAllByTestId("call-history-row");
  expect(rows).toHaveLength(2);
  expect(rows[0]).toHaveTextContent("Mina");
  expect(rows[0]).toHaveTextContent("1:15");
  expect(rows[1]).toHaveClass("call-history-row--missed");
  expect(screen.getAllByTestId("row-callback")[0]).toHaveAttribute("data-other", "u2");
  expect(screen.queryByTestId("call-history-more")).not.toBeInTheDocument();
});

it("loads the next page", () => {
  callsApi.history.mockImplementation((arg: any) => ({
    data: { items: [row({ id: `p${arg.page}` })], hasMore: arg.page < 2 },
    isLoading: false,
    isFetching: false,
  }));
  render(
    <MemoryRouter>
      <CallHistoryPage />
    </MemoryRouter>
  );
  fireEvent.click(screen.getByTestId("call-history-more"));
  expect(callsApi.history).toHaveBeenCalledWith({ page: 2, limit: 20 }, undefined);
  expect(screen.getAllByTestId("call-history-row")).toHaveLength(2);
});

it("a deleted account still renders a row", () => {
  callsApi.history.mockImplementation(() => ({ data: { items: [row({ otherParty: null })], hasMore: false }, isLoading: false, isFetching: false }));
  render(
    <MemoryRouter>
      <CallHistoryPage />
    </MemoryRouter>
  );
  expect(screen.getByTestId("call-history-row")).toHaveTextContent("Deleted account");
});

it("empty state", () => {
  render(
    <MemoryRouter>
      <CallHistoryPage />
    </MemoryRouter>
  );
  expect(screen.getByTestId("call-history-empty")).toHaveTextContent("No calls yet");
});
```

Create `src/components/calls/CallsNavLink.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, act } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { mockAppConfig } from "../../utils/testing/mockWebFlags";
import { callsApi, resetCallsApi } from "./testing/callsSliceMock";
import { makeFakeSocket } from "./testing/fakeSocket";
import CallsNavLink from "./CallsNavLink";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("../../store/slices/callsSlice", () => require("./testing/callsSliceMock").callsSliceMock());
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
let mockSocket: any;
jest.mock("../chat/hooks/useSocket", () => ({ useSocket: () => ({ socket: mockSocket }) }));

function renderLink(signedIn = true) {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: signedIn ? { token: "t", user: { _id: "me" } } : null }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <CallsNavLink variant="dropdown" onNavigate={() => {}} />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  resetCallsApi();
  mockSocket = makeFakeSocket();
});

it("absent while the flag is off, and never asks for the count", () => {
  mockAppConfig({ webCallsEnabled: false });
  renderLink();
  expect(screen.queryByTestId("nav-calls")).not.toBeInTheDocument();
  callsApi.missedCount.mock.calls.forEach((c: any[]) => expect(c[1]).toEqual({ skip: true }));
});

it("links to /calls with the missed count", () => {
  mockAppConfig({ webCallsEnabled: true });
  callsApi.missedCount.mockImplementation(() => ({ data: 3, refetch: jest.fn() }));
  renderLink();
  expect(screen.getByTestId("nav-calls")).toHaveAttribute("href", "/calls");
  expect(screen.getByTestId("calls-missed-badge")).toHaveTextContent("3");
});

it("no badge at zero; signed out shows nothing", () => {
  mockAppConfig({ webCallsEnabled: true });
  const { unmount } = renderLink();
  expect(screen.queryByTestId("calls-missed-badge")).not.toBeInTheDocument();
  unmount();
  renderLink(false);
  expect(screen.queryByTestId("nav-calls")).not.toBeInTheDocument();
});

it("refreshes the count when a call ends", () => {
  mockAppConfig({ webCallsEnabled: true });
  const refetch = jest.fn();
  callsApi.missedCount.mockImplementation(() => ({ data: 0, refetch }));
  renderLink();
  act(() => mockSocket.serverEmit("call:state", { callId: "c1", status: "missed" }));
  expect(refetch).toHaveBeenCalled();
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
CI=true npm test -- --watchAll=false CallHistoryPage CallsNavLink
```
Expected: FAIL — modules not found.

- [ ] **Step 3: Implement**

Create `src/components/calls/lib/historyLabel.ts`:

```ts
import { CallHistoryItem } from "../../../store/slices/callsSlice";

type T = (key: string, opts?: any) => string;

/** Row text, worded like the app's call labels (lib/l10n/app_en.arb callLabel*). */
export function historyLabel(item: CallHistoryItem, t: T): { text: string; missed: boolean } {
  const video = item.type === "video";
  const kind = video ? "video" : "voice";
  const name = (item.otherParty && item.otherParty.name) || t("calls.history.deletedAccount") || "Deleted account";
  const out = item.direction === "out";
  switch (item.outcome) {
    case "no_answer":
      return out
        ? { text: t(`calls.history.noAnswer_${kind}`) || (video ? "Video call · No answer" : "Voice call · No answer"), missed: false }
        : { text: t(`calls.history.missed_${kind}`) || (video ? "Missed video call" : "Missed voice call"), missed: true };
    case "cancelled":
      return out
        ? { text: t(`calls.history.cancelled_${kind}`) || (video ? "Cancelled video call" : "Cancelled voice call"), missed: false }
        : { text: t(`calls.history.missed_${kind}`) || (video ? "Missed video call" : "Missed voice call"), missed: true };
    case "declined":
      return out
        ? { text: t(`calls.history.declinedOut_${kind}`) || (video ? "Video call declined" : "Voice call declined"), missed: false }
        : { text: t(`calls.history.declinedIn_${kind}`) || (video ? "Declined video call" : "Declined voice call"), missed: false };
    case "busy":
      return { text: t("calls.history.busy", { name }) || `${name} was on another call`, missed: false };
    default:
      return out
        ? { text: t(`calls.history.outgoing_${kind}`) || (video ? "Outgoing video call" : "Outgoing voice call"), missed: false }
        : { text: t(`calls.history.incoming_${kind}`) || (video ? "Incoming video call" : "Incoming voice call"), missed: false };
  }
}
```

Create `src/components/calls/CallHistoryPage.tsx`:

```tsx
import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Phone, Video, PhoneMissed } from "lucide-react";
import {
  useGetCallHistoryQuery,
  useMarkMissedCallsSeenMutation,
  CallHistoryItem,
} from "../../store/slices/callsSlice";
import { historyLabel } from "./lib/historyLabel";
import CallBackButton from "./CallBackButton";
import "./calls.css";

const LIMIT = 20;
const fmt = (secs: number) => `${Math.floor(secs / 60)}:${("0" + (secs % 60)).slice(-2)}`;

/** One page of history; pages are stacked by the parent (each its own cache entry). */
const HistoryPage: React.FC<{ page: number; onHasMore(page: number, more: boolean): void }> = ({ page, onHasMore }) => {
  const { t, i18n } = useTranslation();
  const { data } = useGetCallHistoryQuery({ page, limit: LIMIT }, undefined);
  const items: CallHistoryItem[] = (data && data.items) || [];
  const hasMore = !!(data && data.hasMore);
  useEffect(() => {
    if (data) onHasMore(page, hasMore);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data, hasMore]);
  return (
    <>
      {items.map((item) => {
        const label = historyLabel(item, t as any);
        const other = item.otherParty;
        const name = (other && other.name) || t("calls.history.deletedAccount") || "Deleted account";
        const Icon = label.missed ? PhoneMissed : item.type === "video" ? Video : Phone;
        return (
          <li key={item.id} data-testid="call-history-row" className={`call-history-row${label.missed ? " call-history-row--missed" : ""}`}>
            <img className="call-history-avatar" src={(other && other.avatar) || "/default-avatar.png"} alt="" />
            <div className="call-history-main">
              {other ? (
                <Link to={`/chat/${other.id}`} className="call-history-name">{name}</Link>
              ) : (
                <span className="call-history-name">{name}</span>
              )}
              <span className="call-history-label">
                <Icon size={14} aria-hidden="true" /> {label.text}
                {item.outcome === "completed" && item.duration > 0 ? ` · ${fmt(item.duration)}` : ""}
              </span>
              <span className="call-history-time">{new Date(item.createdAt).toLocaleString(i18n.language)}</span>
            </div>
            <CallBackButton otherId={other ? other.id : null} otherName={name} type={item.type} />
          </li>
        );
      })}
    </>
  );
};

/** /calls — call history + missed calls (flagged: webCallsEnabled). Opening it clears the missed badge. */
const CallHistoryPage: React.FC = () => {
  const { t } = useTranslation();
  const [markSeen] = useMarkMissedCallsSeenMutation();
  const [pages, setPages] = useState(1);
  const [more, setMore] = useState<{ [page: number]: boolean }>({});
  const [firstEmpty, setFirstEmpty] = useState(false);
  const firstPage = useGetCallHistoryQuery({ page: 1, limit: LIMIT }, undefined);

  useEffect(() => {
    Promise.resolve(markSeen(undefined)).catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  useEffect(() => {
    const d = firstPage && firstPage.data;
    setFirstEmpty(!!d && Array.isArray(d.items) && d.items.length === 0);
  }, [firstPage]);

  const pageList: number[] = [];
  for (let p = 1; p <= pages; p++) pageList.push(p);

  return (
    <section className="call-history" data-testid="call-history">
      <h1 className="call-history-title">{t("calls.history.title") || "Calls"}</h1>
      {firstEmpty ? (
        <p data-testid="call-history-empty" className="call-history-empty">
          {t("calls.history.empty") || "No calls yet. Start one from a chat or a profile."}
        </p>
      ) : (
        <ul className="call-history-list">
          {pageList.map((p) => (
            <HistoryPage key={p} page={p} onHasMore={(page, m) => setMore((prev) => Object.assign({}, prev, { [page]: m }))} />
          ))}
        </ul>
      )}
      {more[pages] && (
        <button type="button" className="call-history-more" data-testid="call-history-more" onClick={() => setPages(pages + 1)}>
          {t("calls.history.more") || "Show more"}
        </button>
      )}
    </section>
  );
};

export default CallHistoryPage;
```

Create `src/components/calls/CallsNavLink.tsx`:

```tsx
import React, { useEffect } from "react";
import { NavLink } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { FaPhone } from "react-icons/fa";
import { useWebFlag } from "../../utils/webFlags";
import { useGetMissedCallCountQuery } from "../../store/slices/callsSlice";
import { useSocket } from "../chat/hooks/useSocket";

/** Navbar entry to /calls with the unseen missed-call count. Absent unless webCallsEnabled is on and signed in. */
const CallsNavLink: React.FC<{ variant: "dropdown" | "mobile"; onNavigate(): void }> = ({ variant, onNavigate }) => {
  const { t } = useTranslation();
  const signedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo && s.auth.userInfo.token));
  const enabled = useWebFlag("webCallsEnabled");
  const on = enabled && signedIn;
  const { data: missed, refetch } = useGetMissedCallCountQuery(undefined, { skip: !on });
  const { socket } = useSocket() as any;

  useEffect(() => {
    if (!on || !socket || typeof refetch !== "function") return undefined;
    const onState = () => refetch();
    socket.on("call:state", onState);
    return () => socket.off("call:state", onState);
  }, [on, socket, refetch]);

  if (!on) return null;
  const count = typeof missed === "number" ? missed : 0;
  return (
    <NavLink to="/calls" data-testid="nav-calls" className={variant === "dropdown" ? "dropdown-item" : "mobile-nav-link"} onClick={onNavigate}>
      <FaPhone /> {t("calls.nav.calls") || "Calls"}
      {count > 0 && (
        <span className="navbar-unread-badge" data-testid="calls-missed-badge">
          {count > 99 ? "99+" : count}
        </span>
      )}
    </NavLink>
  );
};

export default CallsNavLink;
```

`src/components/navbar/MainNavbar.tsx`: add `import CallsNavLink from "../calls/CallsNavLink";`; in the user dropdown, after the `/my-moments` `NavLink`, add
```tsx
                    <CallsNavLink variant="dropdown" onNavigate={() => setIsUserDropdownOpen(false)} />
```
and in the mobile menu, after the `/moments` `NavLink`, add
```tsx
                  <CallsNavLink variant="mobile" onNavigate={closeMobileMenu} />
```

`src/router/routes.tsx`: in the lazy section add (next to the chat group)

```tsx
// Calls (Phase 4, dark behind WEB_CALLS_ENABLED). The history page only; the
// call screens are mounted by App.tsx's IncomingCallHost, not by a route.
const CallHistoryPage = lazyWithRetry("../components/calls/CallHistoryPage", () => import("../components/calls/CallHistoryPage"));
```
add `import FlagRoute from "./FlagRoute";` to the imports if no earlier unit added it, and after the `chat/:userId?` route:
```tsx
    <Route path="calls" element={<FlagRoute flag="webCallsEnabled">{lazyRoute(<CallHistoryPage />)}</FlagRoute>} />
```

Append to `src/components/calls/calls.css`:

```css
.call-history { max-width: 640px; margin: 0 auto; padding: 24px 16px; }
.call-history-title { font-size: 22px; font-weight: 800; margin-block-end: 16px; }
.call-history-list { list-style: none; margin: 0; padding: 0; }
.call-history-row { display: flex; align-items: center; gap: 12px; padding-block: 10px; border-block-end: 1px solid #e5e7eb; }
.call-history-row--missed .call-history-label { color: #dc2626; }
.call-history-avatar { width: 44px; height: 44px; border-radius: 50%; object-fit: cover; }
.call-history-main { flex: 1; min-width: 0; display: flex; flex-direction: column; text-align: start; }
.call-history-name { font-weight: 700; color: inherit; text-decoration: none; }
.call-history-label { display: inline-flex; align-items: center; gap: 4px; font-size: 13px; color: #4b5563; }
.call-history-time { font-size: 12px; color: #9ca3af; }
.call-history-empty { color: #6b7280; }
.call-history-more { margin-block-start: 16px; padding: 8px 16px; border-radius: 999px; border: 1px solid #e5e7eb; background: transparent; cursor: pointer; }
```

Add to `eng.json` under `calls`:

```json
"nav": { "calls": "Calls" },
"history": {
  "title": "Calls",
  "empty": "No calls yet. Start one from a chat or a profile.",
  "more": "Show more",
  "deletedAccount": "Deleted account",
  "outgoing_voice": "Outgoing voice call",
  "outgoing_video": "Outgoing video call",
  "incoming_voice": "Incoming voice call",
  "incoming_video": "Incoming video call",
  "noAnswer_voice": "Voice call · No answer",
  "noAnswer_video": "Video call · No answer",
  "missed_voice": "Missed voice call",
  "missed_video": "Missed video call",
  "cancelled_voice": "Cancelled voice call",
  "cancelled_video": "Cancelled video call",
  "declinedOut_voice": "Voice call declined",
  "declinedOut_video": "Video call declined",
  "declinedIn_voice": "Declined voice call",
  "declinedIn_video": "Declined video call",
  "busy": "{{name}} was on another call"
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false CallHistoryPage CallsNavLink MainNavbar routes
```
Expected: all pass. `MainNavbar.test.tsx` stays green: its store has no app-config data, so `webCallsEnabled` is off and `CallsNavLink` renders nothing and skips the count query.

- [ ] **Step 5: Commit**

```bash
git add src/components/calls/CallHistoryPage.tsx src/components/calls/CallHistoryPage.test.tsx src/components/calls/lib/historyLabel.ts src/components/calls/CallsNavLink.tsx src/components/calls/CallsNavLink.test.tsx src/components/calls/testing/callsSliceMock.ts src/components/calls/calls.css src/router/routes.tsx src/components/navbar/MainNavbar.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): call history page and the missed-call badge

/calls lists call history with the app's labels, pages by 20, offers
call back, and clears the missed badge when opened. The navbar "Calls"
entry shows the unseen missed count and refreshes on call:state. Both
are absent (and /calls is a 404) while webCallsEnabled is off.

Still open (Phase 4 calls): flag-off test (P4-CALL-11), I18N, PUSH.
MSG
```

---

### Task P4-CALL-11: Flag off — no call button, no `/calls`, no socket listener, no engine chunk

**Files:**
- Create: `src/components/calls/callsFlagOff.test.tsx`

**Interfaces:**
- Consumes: everything this unit added; `ALL_WEB_FLAGS_OFF`, `mockAppConfig` (P4-0).
- Produces: the unit's dark-launch guarantee as one suite (spec §4: "The website hides the nav entry, routes and buttons while false").

- [ ] **Step 1: Write the test**

Create `src/components/calls/callsFlagOff.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import fs from "fs";
import path from "path";
import React from "react";
import { render, screen, act } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { mockAppConfig, ALL_WEB_FLAGS_OFF } from "../../utils/testing/mockWebFlags";
import { callsApi, resetCallsApi } from "./testing/callsSliceMock";
import { lkSessions } from "./testing/fakeLkSession";
import { makeFakeSocket } from "./testing/fakeSocket";
import { registerCallApi, getCallApi } from "./callBridge";
import IncomingCallHost from "./IncomingCallHost";
import CallButtons from "./CallButtons";
import CallBackButton from "./CallBackButton";
import CallsNavLink from "./CallsNavLink";
import CallHistoryPage from "./CallHistoryPage";
import FlagRoute from "../../router/FlagRoute";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("../../store/slices/callsSlice", () => require("./testing/callsSliceMock").callsSliceMock());
jest.mock("../../lib/livekit/lkSession", () => require("./testing/fakeLkSession").lkSessionMock());
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("../errors/NotFound", () => () => <div data-testid="not-found" />);
let mockSocket: any;
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: mockSocket, isConnected: true, emit: jest.fn(), connectionEpoch: 0 }),
}));

const SRC = path.join(__dirname, "..", "..");
const store = () =>
  configureStore({ reducer: { auth: (s: any = { userInfo: { token: "tok", user: { _id: "me" } } }) => s } });
const wrap = (node: React.ReactNode) => (
  <Provider store={store()}>
    <MemoryRouter>{node}</MemoryRouter>
  </Provider>
);

beforeEach(() => {
  resetCallsApi();
  registerCallApi(null);
  lkSessions.length = 0;
  mockSocket = makeFakeSocket();
  mockAppConfig(ALL_WEB_FLAGS_OFF);
});

it("IncomingCallHost: no engine, no call socket listener, no LiveKit, nothing on the bridge", async () => {
  render(wrap(<IncomingCallHost />));
  await act(async () => {});
  expect(mockSocket.on).not.toHaveBeenCalledWith("call:incoming", expect.anything());
  expect(mockSocket.on).not.toHaveBeenCalledWith("call:state", expect.anything());
  expect(callsApi.current).not.toHaveBeenCalled();
  expect(lkSessions).toHaveLength(0);
  expect(getCallApi()).toBe(null);
});

it("chat header / profile buttons and Call back render nothing, even if an engine were registered", () => {
  registerCallApi({ startCall: jest.fn(), inCall: false });
  render(
    wrap(
      <>
        <CallButtons peer={{ id: "u2", name: "Mina", avatar: null }} variant="header" />
        <CallButtons peer={{ id: "u2", name: "Mina", avatar: null }} variant="profile" />
        <CallBackButton otherId="u2" otherName="Mina" type="audio" />
      </>
    )
  );
  expect(screen.queryByTestId("call-start-audio")).not.toBeInTheDocument();
  expect(screen.queryByTestId("call-start-video")).not.toBeInTheDocument();
  expect(screen.queryByTestId("call-card-callback")).not.toBeInTheDocument();
});

it("navbar: no Calls entry and no missed-count request", () => {
  render(wrap(<CallsNavLink variant="dropdown" onNavigate={() => {}} />));
  expect(screen.queryByTestId("nav-calls")).not.toBeInTheDocument();
  callsApi.missedCount.mock.calls.forEach((c: any[]) => expect(c[1]).toEqual({ skip: true }));
});

it("/calls is a 404 and asks the server nothing", () => {
  render(wrap(<FlagRoute flag="webCallsEnabled"><CallHistoryPage /></FlagRoute>));
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
  expect(callsApi.history).not.toHaveBeenCalled();
  expect(callsApi.markSeen).not.toHaveBeenCalled();
});

it("routes.tsx gates /calls with FlagRoute(webCallsEnabled)", () => {
  const routes = fs.readFileSync(path.join(SRC, "router", "routes.tsx"), "utf8");
  expect(routes).toMatch(/<Route path="calls" element=\{<FlagRoute flag="webCallsEnabled">/);
});

it("no component reads webCallsEnabled except through useWebFlag", () => {
  const offenders: string[] = [];
  const walk = (dir: string) => {
    fs.readdirSync(dir).forEach((f) => {
      const p = path.join(dir, f);
      if (fs.statSync(p).isDirectory()) return walk(p);
      if (!/\.(ts|tsx)$/.test(f) || /\.test\.tsx?$/.test(f) || /testing/.test(p)) return;
      const src = fs.readFileSync(p, "utf8");
      const lines = src.split("\n").filter((l) => l.indexOf("webCallsEnabled") >= 0);
      lines.forEach((l) => {
        if (/useWebFlag(State)?\("webCallsEnabled"\)|flag="webCallsEnabled"/.test(l)) return;
        if (p.endsWith(path.join("utils", "webFlags.ts"))) return;
        offenders.push(`${path.relative(SRC, p)}: ${l.trim()}`);
      });
    });
  };
  walk(SRC);
  expect(offenders).toEqual([]);
});
```

- [ ] **Step 2: Run**

```bash
CI=true npm test -- --watchAll=false callsFlagOff
```
Expected: PASS on the first run (the behaviour was built flag-first in P4-CALL-4…10). If any case fails, fix the component, not the test, in this task's commit.

- [ ] **Step 3: Commit**

```bash
git add src/components/calls/callsFlagOff.test.tsx docs/REMAINING_WORK.md
git commit -F - <<'MSG'
test(calls): everything stays dark while webCallsEnabled is off

One suite for the unit's dark launch: no engine, no call socket
listener, no LiveKit session; no call buttons, Call back, navbar entry
or missed-count request; /calls is a 404; nothing reads the flag
outside useWebFlag.

Still open (Phase 4 calls): I18N, PUSH.
MSG
```

---

### Task P4-CALL-I18N: The calls unit's new strings in all 18 locales

**Files:**
- Create: `scripts/i18n/keys/2026-10-16-p4-calls.json` (all 18 locales; the durable record of what this unit translated)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: every English string P4-CALL-2 … P4-CALL-10 added under `calls.*` in `eng.json` (`errors`, `media`, `notices`, `incoming`, `decline`, `errorDialog`, `screen`, `outcome`, `buttons`, `nav`, `history`); `scripts/i18n/new-keys.js` and the guard `src/utils/locales/p3Keys.test.ts` (Phase 3, widened to `p4` files by P4-0). Diff base: the commit CALLS branched from. Because `web/p4-calls` was cut from `web/p4-rooms`, `web/p4-base` would also report the ROOMS strings; use the P4-ROOM-1 commit as the base so only this unit's keys are listed.
- Produces: no English-only key in this unit's push.

**Translation rules:** as P3-CHAT-I18N — keep `{{name}}` verbatim; "BananaTalk" is never translated; follow `docs/l10n/2026-09-23-native-pass-*.md` for tone. Where the app already has the same sentence (`callDeclineCannedLater`, `callDeclineCannedText`, `callDeclineSheetTitle`, `callDeclineCustomHint`, `callDeclineSend`, `callLabel*`, `callUnavailable`), copy the app's translation from `bananatalk_app/lib/l10n/app_<lang>.arb` (convert ICU `{name}` to `{{name}}`, and split each ICU `select` into its `_voice`/`_video` key) so web and app say the same thing.

- [ ] **Step 1: Generate the keys file and see the guard fail**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-calls
ROOM1=$(git log --format=%H --grep='^feat(livekit):' -1)
node scripts/i18n/new-keys.js $ROOM1 scripts/i18n/keys/2026-10-16-p4-calls.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: about 75 new keys; `p3Keys` FAILS with `calls.…: missing` for each of the 17 non-English locales.

- [ ] **Step 2: Translate** — fill every `""` for the 17 locales (rules above). Re-running `new-keys.js` keeps finished values.

- [ ] **Step 3: Merge**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p4-calls.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/keys/2026-10-16-p4-calls.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'MSG'
i18n(calls): translate the Phase 4 calls strings into all 18 locales

Strings that exist in the app (decline sheet, call labels, "isn't
taking calls") reuse the app's translations.

Still open (Phase 4 calls): push gate (P4-CALL-PUSH); native review of
the new strings.
MSG
```

---

### Task P4-CALL-PUSH: Push unit CALLS (4 of 5) — full suite + build green, then the coordinator pushes (dark)

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status, §6 changelog line, §3 production-QA lines below)

- [ ] **Step 1: Every task committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-calls
git status --short                                             # nothing but the untracked node_modules
grep -n "P4-CALL-" docs/REMAINING_WORK.md | grep -c "\[ \]"     # 1 (this PUSH line)
```

- [ ] **Step 2: Rebase onto the live site (after ROOMS is pushed)**

```bash
git fetch origin
git log origin/main --oneline | grep -c "Phase 4 rooms ready to deploy"   # 1; stop if ROOMS is not pushed yet
git rebase origin/main
```
P4-ROOM-1 is already upstream and is dropped by the rebase (same patch). Expected conflicts and resolutions:
- `src/router/routes.tsx` — keep every unit's lazy imports and routes; one `import FlagRoute from "./FlagRoute";` only.
- `src/components/navbar/MainNavbar.tsx` — keep the other units' entries and `CallsNavLink`.
- `src/App.tsx` — only CALLS touches it; a conflict means a hotfix landed: keep both.
- `src/components/chat/ChatContent.tsx`, `src/components/profile/parts/ProfileActions.tsx`, `src/components/chat/components/CallMessageCard.tsx` — only CALLS touches them in Phase 4; keep both sides of any hotfix.
- `src/utils/locales/*.json`, `docs/REMAINING_WORK.md`, `src/store/slices/apiSlice.ts` (`tagTypes`) — keep both sides' lines.
- `package.json` / `package-lock.json` / `tsconfig.json` — take `origin/main` (ROOMS already carries the same change), then `npm ci`.

After resolving: `git rebase --continue`, `npm ci`, `CI=true npm test -- --watchAll=false p3Keys`.

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `0 failed`; passed ≥ the ROOMS push's count plus this unit's tests. Fix failures in a new commit (never skip a test).

- [ ] **Step 4: Production build and the bundle boundaries**

```bash
npm run build 2>&1 | tail -20
grep -c "livekit-client" build/static/js/main.*.js                      # 0
ls build/static/js | grep -E "^(livekit|calls)\." | sort                 # livekit.<hash>.chunk.js and calls.<hash>.chunk.js
grep -c "call:incoming" build/static/js/main.*.js                        # 0 (the engine is in the calls chunk)
npx tsc -p . 2>&1 | grep "error TS" | grep -c -i livekit                 # 0
grep -rn "from ['\"]livekit-client['\"]" src | grep -v livekitLoader.js | wc -l   # 0
```
Expected: `Compiled successfully` or `Compiled with warnings` and the prerender finishes; each check prints the value in its comment. `react-scripts build` does **not** type-check this repo (Global Constraints), so the `tsc | grep livekit` line is the TypeScript gate for the new code paths that touch the wrapper.

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P4-CALL-PUSH`; §1 Status: "Phase 4 calls pushed dark (YYYY-MM-DD)"; §6 Done: one line; §3 Production QA: one `- [ ]` line per item of Step 8 (flag-on QA, owner-gated).

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'MSG'
docs: Phase 4 calls ready to deploy (dark)

Still open (Phase 4): APPLE unit; browser↔app call QA with
WEB_CALLS_ENABLED on (docs/REMAINING_WORK.md §3); owner flips the flag
after QA.
MSG
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p4-calls:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/                   # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1          # new bundle hash
curl -s https://api.banatalk.com/api/v1/app-config | grep -o '"webCallsEnabled":[a-z]*'   # "webCallsEnabled":false
```

- [ ] **Step 7: Production smoke with the flag OFF (signed in as a test web user)**

  - [ ] Chat header with any partner: only the "⋯" button, no phone/video buttons; profile of another user: Message / Follow / ⋯ only.
  - [ ] User dropdown and mobile menu: no "Calls"; `https://banatalk.com/calls` shows the 404 page.
  - [ ] DevTools → Network, reload a chat page: no request to `/api/v1/calls/*`, no `calls.*.chunk.js`, no `livekit.*.chunk.js`.
  - [ ] An app user (2.6.1) calls the web user's account: the phone side behaves exactly as before (no web ring is expected while the flag is off); the call card in the web chat has no "Call back".

- [ ] **Step 8: Flag-on QA (owner turns `WEB_CALLS_ENABLED=true` on a test window; rows also go to `bananatalk_app/docs/qa/regression-suite.csv`, area "Web")**

  - [ ] Web (Chrome) → app (iOS) voice call: phone rings (CallKit), answer, both hear, mute both ways shows "muted", hang up from web → both screens close; history row "Outgoing voice call · m:ss" on web, call card in chat.
  - [ ] App (Android) → web video call: banner + ringtone in the open tab (after one click on the page), accept, video both ways; camera off on web → app shows camera off; hang up from app.
  - [ ] Web user with **two tabs** open and the app signed in on a phone: app user B calls → both tabs and the phone ring; answer in tab 1 → tab 2 banner closes at once and the phone stops; decline in tab 2 on the next call → tab 1 and the phone stop.
  - [ ] Decline with "Can't talk now. Text me?" → caller sees the text in chat; with the caller blocked afterwards → "Your message couldn't be delivered."
  - [ ] Busy: web user in a call, a third user calls → caller gets "… is on another call"; web user calls someone in a call → same dialog.
  - [ ] Camera denied (Chrome "Block") → video call is placed with the camera off and a notice; mic denied → dialog, the other phone never rings.
  - [ ] Safari (macOS) incoming call in a tab never clicked: banner and title flash visible, "Sound is off — click…" shown; after accept, "Tap to enable sound" appears if remote audio is blocked and fixes it.
  - [ ] Wi-Fi off for 10 s mid-call → "Reconnecting…" on both sides, then recovers; off for 60 s → "The call dropped." and the call ends on both sides.
  - [ ] Reload the web tab mid-call → it rejoins within 20 s; close the tab mid-call → the app ends the call after ~20 s.
  - [ ] Close the tab while an outgoing call rings → the callee's phone stops ringing.
  - [ ] Missed call while the web tab is open → "Missed voice call" row in red, badge on "Calls"; opening `/calls` clears it.
  - [ ] Flip `WEB_CALLS_ENABLED` off during a call → the call continues; after it ends and the window regains focus, the buttons and "Calls" are gone.

- [ ] **Step 9 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p4-calls-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -30
CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(Flag off already hides everything, so a revert is only needed for a regression outside the flag — e.g. `App.tsx`, the chat header or the profile row. Note it in §6 and reopen the tasks.)

---

---

## Unit APPLE (push 5 of 5) — P4-APPLE-1 … P4-APPLE-5, P4-APPLE-I18N, P4-APPLE-PUSH

Worktree `/Users/davis/Desktop/Personal/wt-web-p4-apple`, branch `web/p4-apple` (from `web/p4-base`, symlinked
`node_modules`; nothing to install — Apple JS is a script tag from Apple's CDN, not an npm package). One implementer,
tasks in number order: 1–3 are independent building blocks, 4 composes them, 5 mounts the button and adds the flag-off
guard.

Unit facts (read before P4-APPLE-1):
- **Backend contract** (`be-integration`, deployed `07febec`): `POST /api/v1/auth/apple/web` (`routes/auth.js:160`,
  behind `authLimiter`), body `{ identityToken, nonce, user? }` (`controllers/auth.js:460-495`).
  - 404 `{success:false, error:'Not found', code:'feature_disabled'}` while `WEB_APPLE_SIGNIN_ENABLED` is false (read
    per request, so the site can race a flag flip).
  - 503 "Sign in with Apple is not available right now" while `APPLE_WEB_SERVICES_ID` is unset.
  - 400 "Identity token is required" / "A valid nonce is required" — nonce must match `/^[A-Za-z0-9._~-]{16,128}$/`
    (`controllers/auth.js:457`).
  - 403 for a banned identity or banned user (`bannedError`, `:309-330`); 401/500 when Apple's token fails to verify.
  - 200 `{ success: true, token, refreshToken?, user }` — the same shape as every other login (`sendTokenResponse`,
    `controllers/auth.js:1912-1950`).
- **Nonce is compared raw.** `appleIdentityLogin` passes `{ audience: APPLE_WEB_SERVICES_ID, nonce }` to
  `apple-signin-auth` `verifyIdToken` (`controllers/auth.js:297-303`), which hands the options to
  `jsonwebtoken.verify` (`node_modules/apple-signin-auth/lib/index.js`, `verifyIdToken`); jsonwebtoken compares the
  token's `nonce` claim to the option **as is** (no hashing). Apple JS copies the `nonce` given to `AppleID.auth.init`
  into the id_token verbatim. So the page sends exactly the string it gave Apple — no SHA-256 (that is the native
  iOS/Firebase convention, not Apple JS). Pinned by backend `test/appleWebLogin.test.js:28`.
- **First consent only:** Apple returns `user: { name: { firstName, lastName }, email }` only the very first time an
  Apple ID authorises the Services ID. The page must send it on that response or the account is named "Apple User"
  forever. The backend reads the web shape (`appleDisplayName`, `controllers/auth.js:269-280`, `web.firstName`).
  Email always comes from the verified token, never from `user.email`.
- **New Apple accounts are incomplete.** The backend creates them with empty gender/languages/birth date and
  `profileCompleted:false` (`controllers/auth.js:341-365`). After sign-in the web sends them into the same completion
  wizard Google sign-ups use (`/register` with `state.oauth`, `Register.tsx:103-112`), or ~19% of them stop at a blank
  profile (memory: blank social signups).
- **Same person on app and web:** Apple's `sub` is per developer team, so the Services ID (owner step, Phase 5) must be
  grouped with the app's primary App ID `com.bananatalk.bananatalkApp` — then a web Apple sign-in lands on the account
  the person already has from the iOS app.
- **Decided configuration:**
  - Services ID comes from the build env `REACT_APP_APPLE_SERVICES_ID` (CRA inlines it at build time). It is added to
    `.env.production` **empty**; the button is hidden while it is empty, even if the flag is on. The owner fills it in
    Phase 5 (one-line commit → deploy) when the Services ID exists.
  - `redirectURI` = `${window.location.origin}/login` — on production `https://banatalk.com/login`, which the owner
    registers as the Services ID's return URL (www is 301'd to the apex in Phase 5, so only the apex is registered).
    With `usePopup: true` Apple answers through `postMessage` and never loads that URL, but it must still match a
    registered return URL exactly. Local dev (`http://localhost:3000`) cannot be registered (Apple requires HTTPS and
    rejects localhost), so local testing of the real popup is not possible — unit tests stub `window.AppleID`.
  - Script URL: `https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js`, injected on
    the first click (never on page load, never when the button is hidden), so a visitor who does not click downloads
    nothing from Apple. Popup blockers allow it because `AppleID.auth.signIn()` runs from the click — the loader is
    awaited first, so on the very first click the script may arrive too late for the popup to count as user-initiated
    in Safari; the button therefore **preloads** the script on `pointerenter`/`focus` (still only when visible), and if
    the popup is blocked anyway (`popup_blocked_by_browser`) it says "Allow pop-ups for banatalk.com and try again".
  - No CSP to change: `public/index.html` has no CSP meta and `deploy/nginx.snippet.conf` sends no
    `Content-Security-Policy` header (checked on `origin/main`). If one is added later it needs
    `script-src https://appleid.cdn-apple.com` and `frame-src https://appleid.apple.com`.
- **Cancel is not an error:** the user closing the popup rejects with `{ error: "popup_closed_by_user" }` (and
  `"user_cancelled_authorize"` when they press Cancel) — the button just returns to idle, no toast.
- **Where it sits:** under the Google button on `/login` (`Login.tsx:101-109`, after Phase 3's P3-LINK-5 the Google
  button is unchanged), and on the email step of `/register` above the email field (`Register.tsx:507-540`). It is
  never shown in Register's OAuth completion mode (`completionMode`).
- **Shared files touched:** `src/components/auth/Login.tsx`, `src/components/auth/Register.tsx`,
  `src/components/auth/AuthCallback.tsx` (P4-APPLE-3: import of the moved helpers only), `src/constants.ts` (one
  constant), `.env.production` (one empty line), `src/utils/locales/*.json`, `docs/REMAINING_WORK.md`. No routes, no
  navbar entry (the feature is a button, not a page).
- **Known limitation (backend, recorded, not fixed here):** a web-only Apple sign-up has no stored Apple refresh token
  (`appleWebLogin` passes `authorizationCode: null` because `lib/appleAuthTokens` uses the bundle id as `client_id`),
  so account deletion cannot revoke the web authorisation. Listed under "Backend follow-ups".

### Task P4-APPLE-1: Apple JS loader, nonce and popup sign-in wrapper (script fetched only on click)

**Files:**
- Create: `src/components/auth/apple/appleJs.ts`
- Test: `src/components/auth/apple/appleJs.test.ts` (new)

**Interfaces:**
- Consumes: Apple JS (`appleid.auth.js`): `window.AppleID.auth.init({ clientId, scope, redirectURI, state, nonce, usePopup })`
  and `window.AppleID.auth.signIn(): Promise<{ authorization: { id_token: string; code: string; state?: string }; user?: { name?: { firstName?: string; lastName?: string }; email?: string } }>`,
  rejecting with `{ error: string }` (`popup_closed_by_user`, `user_cancelled_authorize`, `popup_blocked_by_browser`, …).
- Produces (all named exports of `appleJs.ts`):
  - `APPLE_JS_URL: string`
  - `appleServicesId(): string` — `process.env.REACT_APP_APPLE_SERVICES_ID` trimmed, read on every call (tests set it).
  - `appleRedirectUri(): string` — `${window.location.origin}/login`.
  - `makeNonce(): string` — 43 base64url chars from 32 random bytes (`crypto.getRandomValues`); always matches the
    backend's `/^[A-Za-z0-9._~-]{16,128}$/`.
  - `loadAppleJs(timeoutMs?: number): Promise<AppleIdAuth>` — injects the script once (cached promise; cache cleared on
    failure or timeout so the next click retries); resolves immediately when `window.AppleID` already exists.
  - `signInWithApple(opts: { nonce: string; state: string }): Promise<AppleSignInResult | null>` — `null` means the
    user cancelled; throws `AppleJsError` with `kind: "blocked" | "state_mismatch" | "no_token" | "failed"`.
  - `interface AppleSignInResult { identityToken: string; user?: { name?: { firstName?: string; lastName?: string }; email?: string } }`
  - `class AppleJsError extends Error { kind: string }` (plain class with a `kind` field — no `#private`, TS 3.7 safe).
  - `_resetAppleJsForTests(): void`.

- [ ] **Step 1: Write the failing test**

Create `src/components/auth/apple/appleJs.test.ts`:

```ts
import {
  APPLE_JS_URL,
  appleServicesId,
  appleRedirectUri,
  makeNonce,
  loadAppleJs,
  signInWithApple,
  AppleJsError,
  _resetAppleJsForTests,
} from "./appleJs";

const NONCE_RE = /^[A-Za-z0-9._~-]{16,128}$/; // controllers/auth.js:457

function stubAppleId(signIn: () => Promise<any>) {
  const init = jest.fn();
  (window as any).AppleID = { auth: { init, signIn: jest.fn(signIn) } };
  return init;
}

const scripts = () => Array.from(document.querySelectorAll(`script[src="${APPLE_JS_URL}"]`)) as HTMLScriptElement[];

// CRA 5's jsdom may not have Web Crypto; the browsers we target all do.
beforeAll(() => {
  if (!(window as any).crypto || !(window as any).crypto.getRandomValues) {
    const nodeCrypto = require("crypto");
    Object.defineProperty(window, "crypto", {
      configurable: true,
      value: { getRandomValues: (a: Uint8Array) => nodeCrypto.randomFillSync(a) },
    });
  }
});

beforeEach(() => {
  _resetAppleJsForTests();
  delete (window as any).AppleID;
  scripts().forEach((s) => s.remove());
  delete process.env.REACT_APP_APPLE_SERVICES_ID;
});

describe("configuration", () => {
  it("reads the Services ID from the build env, trimmed, empty when unset", () => {
    expect(appleServicesId()).toBe("");
    process.env.REACT_APP_APPLE_SERVICES_ID = "  com.bananatalk.web \n";
    expect(appleServicesId()).toBe("com.bananatalk.web");
  });

  it("returns to /login on this origin (the URL the owner registers)", () => {
    expect(appleRedirectUri()).toBe(`${window.location.origin}/login`);
  });

  it("makes a fresh nonce the backend accepts", () => {
    const a = makeNonce();
    const b = makeNonce();
    expect(a).toMatch(NONCE_RE);
    expect(a).toHaveLength(43);
    expect(a).not.toBe(b);
  });
});

describe("loadAppleJs", () => {
  it("injects Apple's script once and resolves when it loads", async () => {
    const p1 = loadAppleJs();
    const p2 = loadAppleJs();
    expect(scripts()).toHaveLength(1);
    stubAppleId(() => Promise.resolve({}));
    scripts()[0].dispatchEvent(new Event("load"));
    await expect(p1).resolves.toBe((window as any).AppleID.auth);
    await expect(p2).resolves.toBe((window as any).AppleID.auth);
  });

  it("does not inject anything when AppleID is already on the page", async () => {
    stubAppleId(() => Promise.resolve({}));
    await loadAppleJs();
    expect(scripts()).toHaveLength(0);
  });

  it("rejects on a script error and retries on the next call", async () => {
    const p = loadAppleJs();
    scripts()[0].dispatchEvent(new Event("error"));
    await expect(p).rejects.toBeInstanceOf(AppleJsError);
    expect(scripts()).toHaveLength(0); // the dead tag is removed
    loadAppleJs();
    expect(scripts()).toHaveLength(1);
  });

  it("gives up after the timeout (Apple's CDN unreachable)", async () => {
    jest.useFakeTimers();
    const p = loadAppleJs(5000);
    jest.advanceTimersByTime(5001);
    await expect(p).rejects.toMatchObject({ kind: "failed" });
    jest.useRealTimers();
  });
});

describe("signInWithApple", () => {
  beforeEach(() => {
    process.env.REACT_APP_APPLE_SERVICES_ID = "com.bananatalk.web";
  });

  it("initialises Apple JS with the nonce, state, popup mode and name+email scope", async () => {
    const init = stubAppleId(() =>
      Promise.resolve({ authorization: { id_token: "id.tok", code: "c", state: "st-1" } })
    );
    await signInWithApple({ nonce: "n".repeat(43), state: "st-1" });
    expect(init).toHaveBeenCalledWith({
      clientId: "com.bananatalk.web",
      scope: "name email",
      redirectURI: `${window.location.origin}/login`,
      state: "st-1",
      nonce: "n".repeat(43),
      usePopup: true,
    });
  });

  it("returns the identity token and, on first consent, the name", async () => {
    stubAppleId(() =>
      Promise.resolve({
        authorization: { id_token: "id.tok", code: "c", state: "st-1" },
        user: { name: { firstName: "Ada", lastName: "Lovelace" }, email: "ada@privaterelay.appleid.com" },
      })
    );
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "st-1" })).resolves.toEqual({
      identityToken: "id.tok",
      user: { name: { firstName: "Ada", lastName: "Lovelace" }, email: "ada@privaterelay.appleid.com" },
    });
  });

  it("returns null when the user closes the popup or cancels", async () => {
    stubAppleId(() => Promise.reject({ error: "popup_closed_by_user" }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).resolves.toBe(null);
    stubAppleId(() => Promise.reject({ error: "user_cancelled_authorize" }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).resolves.toBe(null);
  });

  it("names a blocked popup", async () => {
    stubAppleId(() => Promise.reject({ error: "popup_blocked_by_browser" }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).rejects.toMatchObject({ kind: "blocked" });
  });

  it("refuses a response whose state is not ours", async () => {
    stubAppleId(() => Promise.resolve({ authorization: { id_token: "id.tok", state: "other" } }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "mine" })).rejects.toMatchObject({
      kind: "state_mismatch",
    });
  });

  it("refuses a response without an id_token", async () => {
    stubAppleId(() => Promise.resolve({ authorization: { code: "c", state: "s" } }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).rejects.toMatchObject({ kind: "no_token" });
  });

  it("wraps any other Apple failure", async () => {
    stubAppleId(() => Promise.reject({ error: "invalid_client" }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).rejects.toMatchObject({ kind: "failed" });
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-apple && CI=true npm test -- --watchAll=false appleJs
```
Expected: FAIL — `Cannot find module './appleJs'`.

- [ ] **Step 3: Implement**

Create `src/components/auth/apple/appleJs.ts`:

```ts
/**
 * Sign in with Apple on the website, through Apple JS (appleid.auth.js).
 *
 * Nothing here runs until a visitor reaches for the Apple button: the script
 * is injected on the first hover/focus/click, never on page load, and never
 * while the button is hidden (flag off or no Services ID configured).
 *
 * The nonce goes to Apple verbatim and to POST /auth/apple/web verbatim: Apple
 * JS copies it into the id_token's `nonce` claim as given, and the backend's
 * jsonwebtoken check compares it as is (be controllers/auth.js:297-303). No
 * SHA-256 -- that is the native iOS convention, not Apple JS.
 */

export const APPLE_JS_URL =
  "https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js";

export interface AppleIdAuth {
  init(config: {
    clientId: string;
    scope: string;
    redirectURI: string;
    state: string;
    nonce: string;
    usePopup: boolean;
  }): void;
  signIn(): Promise<any>;
}

export interface AppleSignInResult {
  identityToken: string;
  user?: { name?: { firstName?: string; lastName?: string }; email?: string };
}

export class AppleJsError extends Error {
  kind: string;
  constructor(kind: "blocked" | "state_mismatch" | "no_token" | "failed", message?: string) {
    super(message || kind);
    this.kind = kind;
    // TS 3.7 targeting es6 keeps the prototype, but be explicit for Babel's class transform.
    Object.setPrototypeOf(this, AppleJsError.prototype);
  }
}

/** Read per call (not at import): CRA inlines it at build, tests set it at run time. */
export function appleServicesId(): string {
  return String(process.env.REACT_APP_APPLE_SERVICES_ID || "").trim();
}

/** Must match a return URL registered on the Services ID exactly (owner step). */
export function appleRedirectUri(): string {
  return `${window.location.origin}/login`;
}

/** 32 random bytes as base64url: 43 chars of [A-Za-z0-9_-]. */
export function makeNonce(): string {
  const bytes = new Uint8Array(32);
  if (!window.crypto || !window.crypto.getRandomValues) throw new AppleJsError("failed", "no Web Crypto");
  window.crypto.getRandomValues(bytes);
  let bin = "";
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return window.btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

let loader: Promise<AppleIdAuth> | null = null;

export function _resetAppleJsForTests(): void {
  loader = null;
}

function appleAuth(): AppleIdAuth | null {
  const w = window as any;
  return w.AppleID && w.AppleID.auth ? (w.AppleID.auth as AppleIdAuth) : null;
}

export function loadAppleJs(timeoutMs: number = 15000): Promise<AppleIdAuth> {
  const ready = appleAuth();
  if (ready) return Promise.resolve(ready);
  if (loader) return loader;

  loader = new Promise<AppleIdAuth>((resolve, reject) => {
    const script = document.createElement("script");
    script.src = APPLE_JS_URL;
    script.async = true;
    let settled = false;
    const fail = () => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      script.remove();
      loader = null; // the next click retries
      reject(new AppleJsError("failed", "Apple JS could not be loaded"));
    };
    const timer = setTimeout(fail, timeoutMs);
    script.onload = () => {
      if (settled) return;
      const auth = appleAuth();
      if (!auth) {
        fail();
        return;
      }
      settled = true;
      clearTimeout(timer);
      resolve(auth);
    };
    script.onerror = fail;
    document.head.appendChild(script);
  });
  return loader;
}

const CANCELLED = ["popup_closed_by_user", "user_cancelled_authorize"];

export async function signInWithApple(opts: { nonce: string; state: string }): Promise<AppleSignInResult | null> {
  const auth = await loadAppleJs();
  auth.init({
    clientId: appleServicesId(),
    scope: "name email",
    redirectURI: appleRedirectUri(),
    state: opts.state,
    nonce: opts.nonce,
    usePopup: true,
  });

  let response: any;
  try {
    response = await auth.signIn();
  } catch (err) {
    const code = err && typeof err === "object" ? String((err as any).error || "") : "";
    if (CANCELLED.indexOf(code) !== -1) return null;
    if (code === "popup_blocked_by_browser") throw new AppleJsError("blocked", code);
    throw new AppleJsError("failed", code || "apple_sign_in_failed");
  }

  const authorization = (response && response.authorization) || {};
  if (authorization.state !== undefined && authorization.state !== opts.state) {
    throw new AppleJsError("state_mismatch");
  }
  if (typeof authorization.id_token !== "string" || !authorization.id_token) {
    throw new AppleJsError("no_token");
  }
  const result: AppleSignInResult = { identityToken: authorization.id_token };
  if (response.user && typeof response.user === "object") result.user = response.user;
  return result;
}
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false appleJs
```
Expected: 14 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/components/auth/apple/appleJs.ts src/components/auth/apple/appleJs.test.ts docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(auth): Apple JS loader and popup sign-in wrapper for the website

Injects appleid.auth.js on demand (cached, retried after a failure or a
timeout), makes a base64url nonce the backend accepts, and turns Apple's
popup answer into {identityToken, user?}: null when the user cancels,
a typed error for a blocked popup, a foreign state or a missing token.
Not mounted anywhere yet.

Still open (Phase 4 apple): P4-APPLE-2..5, I18N, push; owner creates the
Services ID and fills REACT_APP_APPLE_SERVICES_ID.
EOF
```

---

### Task P4-APPLE-2: `POST /auth/apple/web` endpoint and the error text for each refusal

**Files:**
- Modify: `src/constants.ts` (one constant after `GOOGLE_EXCHANGE_URL`)
- Create: `src/store/slices/appleAuthSlice.ts` (own small slice: `usersSlice.ts` is a 450-line file every unit avoids)
- Create: `src/components/auth/apple/appleErrors.ts`
- Modify: `src/utils/locales/eng.json` (`auth.apple.errors.*`)
- Test: `src/store/slices/appleAuthEndpoints.test.ts` (new), `src/components/auth/apple/appleErrors.test.ts` (new)

**Interfaces:**
- Consumes: `POST /api/v1/auth/apple/web` `{ identityToken, nonce, user? }` → 200 `{ success, token, refreshToken?, user }`;
  404 `{ code: "feature_disabled" }`; 503; 400; 403 (banned); 429 (`authLimiter`); 401/500 (token rejected by Apple
  verification). (`be/routes/auth.js:160`, `be/controllers/auth.js:460-495`.)
- Produces: `APPLE_WEB_LOGIN_URL = "/api/v1/auth/apple/web"`; `appleAuthApiSlice` with mutation `appleWebLogin`,
  hook `useAppleWebLoginMutation` (re-exported `as any`, house style); `appleErrorKind(err): AppleErrorKind` and
  `appleErrorText(kind, t): string` where
  `type AppleErrorKind = "disabled" | "unavailable" | "banned" | "rate_limited" | "blocked" | "failed"`.

- [ ] **Step 1: Write the failing tests**

Create `src/store/slices/appleAuthEndpoints.test.ts` (same technique as `usersEndpoints.test.ts`: a real store,
`global.fetch` mocked, read the Request RTK Query builds):

```ts
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { appleAuthApiSlice } from "./appleAuthSlice";
import { APPLE_WEB_LOGIN_URL } from "../../constants";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: null }) => state,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; body: string | undefined; auth: string | null };
function mockFetch(status = 200, body: any = { success: true, token: "t", refreshToken: "r", user: { _id: "u1" } }) {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push({
      url: req.url,
      method: req.method,
      body: req.clone ? await req.clone().text() : undefined,
      auth: req.headers && req.headers.get ? req.headers.get("authorization") : null,
    });
    return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
});

it("posts {identityToken, nonce, user} to /api/v1/auth/apple/web", async () => {
  const calls = mockFetch();
  const store = makeStore();
  const result: any = await store.dispatch(
    (appleAuthApiSlice.endpoints as any).appleWebLogin.initiate({
      identityToken: "id.tok",
      nonce: "n".repeat(43),
      user: { name: { firstName: "Ada", lastName: "Lovelace" } },
    })
  );
  expect(calls).toHaveLength(1);
  expect(new URL(calls[0].url).pathname).toBe(APPLE_WEB_LOGIN_URL);
  expect(APPLE_WEB_LOGIN_URL).toBe("/api/v1/auth/apple/web");
  expect(calls[0].method).toBe("POST");
  expect(JSON.parse(calls[0].body as string)).toEqual({
    identityToken: "id.tok",
    nonce: "n".repeat(43),
    user: { name: { firstName: "Ada", lastName: "Lovelace" } },
  });
  expect(result.data).toEqual({ success: true, token: "t", refreshToken: "r", user: { _id: "u1" } });
});

it("leaves `user` out when Apple sent none (every sign-in after the first)", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(
    (appleAuthApiSlice.endpoints as any).appleWebLogin.initiate({ identityToken: "id.tok", nonce: "n".repeat(43) })
  );
  expect(JSON.parse(calls[0].body as string)).toEqual({ identityToken: "id.tok", nonce: "n".repeat(43) });
});

it("surfaces the 404 feature_disabled body as the error", async () => {
  mockFetch(404, { success: false, error: "Not found", code: "feature_disabled" });
  const result: any = await makeStore().dispatch(
    (appleAuthApiSlice.endpoints as any).appleWebLogin.initiate({ identityToken: "x", nonce: "n".repeat(43) })
  );
  expect(result.error).toMatchObject({ status: 404, data: { code: "feature_disabled" } });
});
```

Create `src/components/auth/apple/appleErrors.test.ts`:

```ts
import { appleErrorKind, appleErrorText } from "./appleErrors";
import { AppleJsError } from "./appleJs";

const t = () => "";

it.each([
  [{ status: 404, data: { code: "feature_disabled" } }, "disabled"],
  [{ status: 404, data: {} }, "failed"],
  [{ status: 503, data: { error: "Sign in with Apple is not available right now" } }, "unavailable"],
  [{ status: 403, data: { error: "This account has been permanently suspended" } }, "banned"],
  [{ status: 429, data: {} }, "rate_limited"],
  [{ status: 400, data: { error: "A valid nonce is required" } }, "failed"],
  [{ status: 401, data: {} }, "failed"],
  [{ status: "FETCH_ERROR", error: "TypeError: Failed to fetch" }, "failed"],
  [new AppleJsError("blocked"), "blocked"],
  [new AppleJsError("state_mismatch"), "failed"],
  [undefined, "failed"],
])("%j -> %s", (err, kind) => {
  expect(appleErrorKind(err)).toBe(kind);
});

it("has an English line for every kind and never shows the backend's raw text", () => {
  expect(appleErrorText("disabled", t)).toBe("Sign in with Apple isn't available on the website yet.");
  expect(appleErrorText("unavailable", t)).toBe("Sign in with Apple isn't available right now. Try again later.");
  expect(appleErrorText("banned", t)).toBe("This account has been suspended.");
  expect(appleErrorText("rate_limited", t)).toBe("Too many sign-in attempts. Wait a minute and try again.");
  expect(appleErrorText("blocked", t)).toBe("Your browser blocked the Apple window. Allow pop-ups for banatalk.com and try again.");
  expect(appleErrorText("failed", t)).toBe("Couldn't sign in with Apple. Try again.");
});

it("uses the translation when there is one", () => {
  const tr = (k: string) => (k === "auth.apple.errors.failed" ? "Échec" : "");
  expect(appleErrorText("failed", tr)).toBe("Échec");
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-apple && CI=true npm test -- --watchAll=false appleAuthEndpoints appleErrors
```
Expected: FAIL — `Cannot find module './appleAuthSlice'` and `Cannot find module './appleErrors'`.

- [ ] **Step 3: Implement**

`src/constants.ts`, after the `GOOGLE_EXCHANGE_URL` line:

```ts
// Web Sign in with Apple (Apple JS identity token + the nonce the page made).
// 404 {code:'feature_disabled'} while WEB_APPLE_SIGNIN_ENABLED is off.
export const APPLE_WEB_LOGIN_URL = "/api/v1/auth/apple/web";
```

Create `src/store/slices/appleAuthSlice.ts`:

```ts
import { apiSlice } from "./apiSlice";
import { APPLE_WEB_LOGIN_URL } from "../../constants";

export interface AppleWebLoginArgs {
  identityToken: string;
  nonce: string;
  /** Apple sends it only on the first consent: { name: { firstName, lastName }, email }. */
  user?: { name?: { firstName?: string; lastName?: string }; email?: string };
}

export const appleAuthApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // POST /api/v1/auth/apple/web -> { success, token, refreshToken?, user },
    // the same answer as every other login (be controllers/auth.js:460).
    appleWebLogin: builder.mutation({
      query: (args: AppleWebLoginArgs) => {
        const body: any = { identityToken: args.identityToken, nonce: args.nonce };
        if (args.user) body.user = args.user;
        return { url: APPLE_WEB_LOGIN_URL, method: "POST", body };
      },
    }),
  }),
});

export const { useAppleWebLoginMutation } = appleAuthApiSlice as any;
```

Create `src/components/auth/apple/appleErrors.ts`:

```ts
import { AppleJsError } from "./appleJs";

export type AppleErrorKind = "disabled" | "unavailable" | "banned" | "rate_limited" | "blocked" | "failed";

type Translate = (key: string) => string;

/** RTK Query error, AppleJsError, or anything else -> one of six things to tell the user. */
export function appleErrorKind(err: any): AppleErrorKind {
  if (err instanceof AppleJsError) return err.kind === "blocked" ? "blocked" : "failed";
  if (!err || typeof err !== "object") return "failed";
  const data = err.data || {};
  if (err.status === 404 && data.code === "feature_disabled") return "disabled";
  if (err.status === 503) return "unavailable";
  if (err.status === 403) return "banned";
  if (err.status === 429) return "rate_limited";
  return "failed";
}

const ENGLISH: { [k in AppleErrorKind]: string } = {
  disabled: "Sign in with Apple isn't available on the website yet.",
  unavailable: "Sign in with Apple isn't available right now. Try again later.",
  banned: "This account has been suspended.",
  rate_limited: "Too many sign-in attempts. Wait a minute and try again.",
  blocked: "Your browser blocked the Apple window. Allow pop-ups for banatalk.com and try again.",
  failed: "Couldn't sign in with Apple. Try again.",
};

export function appleErrorText(kind: AppleErrorKind, t: Translate): string {
  return t(`auth.apple.errors.${kind}`) || ENGLISH[kind];
}
```

`src/utils/locales/eng.json` — add a top-level `"auth"` object (it does not exist yet; the existing sign-in strings live
under `"authentication"`, the header fixes `auth.apple.*` for this unit):

```json
  "auth": {
    "apple": {
      "errors": {
        "disabled": "Sign in with Apple isn't available on the website yet.",
        "unavailable": "Sign in with Apple isn't available right now. Try again later.",
        "banned": "This account has been suspended.",
        "rate_limited": "Too many sign-in attempts. Wait a minute and try again.",
        "blocked": "Your browser blocked the Apple window. Allow pop-ups for banatalk.com and try again.",
        "failed": "Couldn't sign in with Apple. Try again."
      }
    }
  },
```

(Before adding, `node -e 'console.log(Object.keys(require("./src/utils/locales/eng.json")).includes("auth"))'` must print
`false`; if a Phase 3/4 unit already created `auth`, merge into it instead.)

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false appleAuthEndpoints appleErrors
```
Expected: 3 + 13 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/constants.ts src/store/slices/appleAuthSlice.ts src/store/slices/appleAuthEndpoints.test.ts src/components/auth/apple/appleErrors.ts src/components/auth/apple/appleErrors.test.ts src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(auth): web Apple sign-in endpoint and its refusal messages

appleWebLogin posts {identityToken, nonce, user?} to /auth/apple/web
(user only when Apple sent it). appleErrorKind maps the backend's 404
feature_disabled, 503, 403, 429 and a blocked popup to six localized
lines; the raw validator text is never shown.

Still open (Phase 4 apple): P4-APPLE-3..5, I18N, push.
EOF
```

---

### Task P4-APPLE-3: One "finish social sign-in" path shared by Google and Apple (profile completion included)

**Files:**
- Create: `src/components/auth/socialSignIn.ts`
- Modify: `src/components/auth/AuthCallback.tsx` — delete the local `isProfileComplete` (`:10-33` on `origin/main`,
  kept verbatim by P3-LINK-5) and import it; in `finish` (P3-LINK-5's version) replace the inline
  `navigate("/register", { state: { oauth: true, startStep: "languages", userData: {…} } })` object with
  `oauthCompletionState(userInfo, "google")`.
- Test: `src/components/auth/socialSignIn.test.ts` (new); `src/components/auth/AuthCallback.test.tsx` (P3-LINK-5's,
  unchanged — it must stay green, which proves Google behaves exactly as before)

**Interfaces:**
- Consumes: the `user` object of any login response (`isRegistrationComplete`, `profileCompleted`, `native_language`,
  `language_to_learn`, `gender`, `birth_year|month|day`, `name`, `email`, `bio`, `_id`); Register's completion mode,
  `state: { oauth: true, startStep: "languages", userData }` (`Register.tsx:103-112`).
- Produces: `isProfileComplete(user): boolean` (moved; one deliberate change: `profileCompleted === false` is checked first — see Step 1);
  `oauthCompletionState(user, provider: "google" | "apple"): { oauth: true; startStep: "languages"; userData: {…} }`.
  The only difference between providers is the default bio ("Hello! I joined using Google." / "… Apple."), which
  matches what the Google path wrote before.

- [ ] **Step 1: Write the failing test**

Create `src/components/auth/socialSignIn.test.ts`:

```ts
import { isProfileComplete, oauthCompletionState } from "./socialSignIn";

describe("isProfileComplete (moved from AuthCallback)", () => {
  // Every new social account is created with isRegistrationComplete:true AND
  // profileCompleted:false (Apple: be controllers/auth.js:341-365; Google:
  // :241-249 + the model default, models/User.js:356). The old order returned
  // true on isRegistrationComplete first, so new sign-ups skipped the wizard.
  it("a fresh social account (isRegistrationComplete but profileCompleted:false) is incomplete", () => {
    expect(isProfileComplete({ isRegistrationComplete: true, profileCompleted: false })).toBe(false);
  });
  it("isRegistrationComplete still counts when profileCompleted is absent (older payloads)", () => {
    expect(isProfileComplete({ isRegistrationComplete: true })).toBe(true);
  });
  it("is incomplete while profileCompleted is false or missing", () => {
    expect(isProfileComplete({ profileCompleted: false, native_language: "Korean" })).toBe(false);
    expect(isProfileComplete({})).toBe(false);
    expect(isProfileComplete(undefined)).toBe(false);
  });
  it("treats the old placeholder defaults as incomplete", () => {
    expect(
      isProfileComplete({ profileCompleted: true, native_language: "English", language_to_learn: "Korean", gender: "other" })
    ).toBe(false);
  });
  it("is complete with real values", () => {
    expect(
      isProfileComplete({ profileCompleted: true, native_language: "Uzbek", language_to_learn: "Korean", gender: "male" })
    ).toBe(true);
  });
});

describe("oauthCompletionState", () => {
  // A brand-new Apple account as be controllers/auth.js:341-365 creates it.
  const freshApple = {
    _id: "u1",
    name: "Ada Lovelace",
    email: "abc@privaterelay.appleid.com",
    gender: "",
    bio: "",
    birth_year: "",
    birth_month: "",
    birth_day: "",
    native_language: "",
    language_to_learn: "",
    profileCompleted: false,
    isRegistrationComplete: true,
  };

  it("sends a new Apple account into the wizard at the languages step", () => {
    expect(oauthCompletionState(freshApple, "apple")).toEqual({
      oauth: true,
      startStep: "languages",
      userData: {
        _id: "u1",
        name: "Ada Lovelace",
        email: "abc@privaterelay.appleid.com",
        bio: "Hello! I joined using Apple.",
        gender: "other",
        nativeLanguage: "",
        languageToLearn: "",
        birthDate: "2000-01-01",
      },
    });
  });

  it("keeps Google's default bio and pads a stored birth date", () => {
    const s = oauthCompletionState(
      { _id: "u2", name: "B", email: "b@x.io", gender: "Female", birth_year: "1999", birth_month: "3", birth_day: "7" },
      "google"
    );
    expect(s.userData.bio).toBe("Hello! I joined using Google.");
    expect(s.userData.gender).toBe("female");
    expect(s.userData.birthDate).toBe("1999-03-07");
  });

  it("keeps a bio the person already wrote", () => {
    expect(oauthCompletionState({ _id: "u3", bio: "Hi from Tashkent" }, "apple").userData.bio).toBe("Hi from Tashkent");
  });
});
```

**Behaviour change, on purpose:** today `isProfileComplete` (`AuthCallback.tsx:12-15` on `origin/main`) returns `true`
as soon as `isRegistrationComplete === true`, and the backend sets exactly that on every new Google
(`be/controllers/auth.js:241-249`, with `profileCompleted` defaulting to `false`, `be/models/User.js:356`) and Apple
(`:341-365`) account. So a brand-new social sign-up skips the completion wizard and lands on a blank profile — one cause
of the blank social sign-ups measured on 2026-09-14. The moved helper checks `profileCompleted === false` first. Effect:
new Google sign-ups on the web now see the wizard too (as the app does); existing accounts with `profileCompleted: true`
are unaffected.

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-apple && CI=true npm test -- --watchAll=false socialSignIn
```
Expected: FAIL — `Cannot find module './socialSignIn'`.

- [ ] **Step 3: Implement**

Create `src/components/auth/socialSignIn.ts`:

```ts
/**
 * What happens after any social sign-in (Google callback, Apple popup):
 * is the profile complete, and if not, the state that opens the signup
 * wizard in completion mode (Register.tsx, `state.oauth`).
 */

export function isProfileComplete(userInfo: any): boolean {
  // A social account the backend just created says isRegistrationComplete
  // AND profileCompleted:false (be controllers/auth.js, Apple and Google).
  // The explicit "not completed" wins; before Phase 4 the order was the other
  // way round and a fresh Apple sign-up skipped the wizard.
  if (userInfo?.profileCompleted === false) return false;

  if (userInfo?.isRegistrationComplete === true) return true;

  if (userInfo?.profileCompleted === undefined) return false;

  const nativeLanguage = userInfo?.native_language;
  const languageToLearn = userInfo?.language_to_learn;
  const gender = userInfo?.gender;

  const hasDefaultValues =
    (!nativeLanguage || nativeLanguage === "" || nativeLanguage === "English") &&
    (!languageToLearn || languageToLearn === "" || languageToLearn === "Korean") &&
    (!gender || gender === "other" || gender === "");

  return !hasDefaultValues;
}

export interface OAuthCompletionState {
  oauth: true;
  startStep: "languages";
  userData: {
    _id: string;
    name: string;
    email: string;
    bio: string;
    gender: string;
    nativeLanguage: string;
    languageToLearn: string;
    birthDate: string;
  };
}

const DEFAULT_BIO: { [p: string]: string } = {
  google: "Hello! I joined using Google.",
  apple: "Hello! I joined using Apple.",
};

export function oauthCompletionState(userInfo: any, provider: "google" | "apple"): OAuthCompletionState {
  const u = userInfo || {};
  const pad = (v: any) => String(v).padStart(2, "0");
  return {
    oauth: true,
    startStep: "languages",
    userData: {
      _id: u._id || "",
      name: u.name || "",
      email: u.email || "",
      bio: u.bio || DEFAULT_BIO[provider],
      gender: (u.gender && String(u.gender).toLowerCase()) || "other",
      nativeLanguage: u.native_language || "",
      languageToLearn: u.language_to_learn || "",
      birthDate:
        u.birth_year && u.birth_month && u.birth_day
          ? `${u.birth_year}-${pad(u.birth_month)}-${pad(u.birth_day)}`
          : "2000-01-01",
    },
  };
}
```

`src/components/auth/AuthCallback.tsx`:
- delete the comment `// Helper function to check if user profile is complete` and the whole `const isProfileComplete = …` function;
- add `import { isProfileComplete, oauthCompletionState } from "./socialSignIn";` after the `../../constants` import;
- in `finish`, replace the `const normalizedGender = …;` line, the comment block below it and the
  `navigate("/register", { state: { … } });` call with:

```tsx
        // OAuth users already have email + name — the SAME signup wizard in
        // completion mode, starting at the languages step (socialSignIn.ts).
        navigate("/register", { state: oauthCompletionState(userInfo, "google") });
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false socialSignIn AuthCallback Register
```
Expected: `socialSignIn` passes (8 tests); P3-LINK-5's `AuthCallback.test.tsx` stays green unchanged. If one of its
cases used a user with `isRegistrationComplete: true, profileCompleted: false` and expected the redirect, that case now
lands on `/register` instead — check `grep -n "profileCompleted" src/components/auth/AuthCallback.test.tsx`; the
fixtures there (`COMPLETE_USER = { _id, name, isRegistrationComplete: true }`) have no `profileCompleted`, so no change
is expected.

- [ ] **Step 5: Commit**

```bash
git add src/components/auth/socialSignIn.ts src/components/auth/socialSignIn.test.ts src/components/auth/AuthCallback.tsx docs/REMAINING_WORK.md
git commit -F - <<'EOF'
refactor(auth): one profile-completion check for Google and Apple sign-in

isProfileComplete and the completion-wizard state move out of
AuthCallback into socialSignIn.ts so the Apple button can reuse them.
profileCompleted:false now wins over isRegistrationComplete: the backend
sets both on every new social account, and the old order let a fresh
sign-up skip the wizard and land on a blank profile.

Still open (Phase 4 apple): P4-APPLE-4..5, I18N, push.
EOF
```

---

### Task P4-APPLE-4: "Sign in with Apple" button: nonce → Apple popup → backend → signed in

**Files:**
- Create: `src/components/auth/apple/AppleSignInButton.tsx`
- Modify: `src/utils/locales/eng.json` (`auth.apple.continue`, `auth.apple.signingIn`, `auth.apple.signedIn`)
- Test: `src/components/auth/apple/AppleSignInButton.test.tsx` (new)

**Interfaces:**
- Consumes: `useWebFlag("webAppleSigninEnabled")` (P4-0), `appleServicesId`, `makeNonce`, `loadAppleJs`,
  `signInWithApple` (P4-APPLE-1), `useAppleWebLoginMutation`, `appleErrorKind`, `appleErrorText` (P4-APPLE-2),
  `isProfileComplete`, `oauthCompletionState` (P4-APPLE-3), `setCredentials` (`authSlice.ts:103`, normalises
  `{ user, token, refreshToken, message }`).
- Produces: default export `AppleSignInButton`, props `{ redirect: string }`; renders `null` unless the flag is on
  **and** `appleServicesId()` is non-empty **and** the backend has not answered `feature_disabled` in this page view.
  Test ids: `apple-signin-button`. Preloads Apple JS on `pointerenter`/`focus`; never before.

Behaviour, in order, on click:
1. `nonce = makeNonce()`, `state = makeNonce()` (fresh per attempt; a retry never reuses a nonce).
2. `signInWithApple({ nonce, state })` → `null` (cancelled): back to idle, no toast.
3. `appleWebLogin({ identityToken, nonce, user })` → `{ token, refreshToken, user }`.
4. Incomplete profile (`!isProfileComplete(user)`): **navigate first** to `/register` with
   `oauthCompletionState(user, "apple")`, **then** `dispatch(setCredentials(…))` — `Login.tsx:26-30` redirects to
   `?redirect=` as soon as `userInfo` appears, and dispatching first would let that effect race the wizard.
   Complete profile: dispatch, success toast, `navigate(redirect, { replace: true })`.
5. Any failure: `appleErrorKind` → localized toast; `disabled` also hides the button for the rest of the page view
   (the flag was flipped off server-side after `/app-config` was read).

- [ ] **Step 1: Write the failing test**

Create `src/components/auth/apple/AppleSignInButton.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, act } from "@testing-library/react";
import { mockAppConfig } from "../../../utils/testing/mockWebFlags";
import { setCredentials } from "../../../store/slices/authSlice";
import AppleSignInButton from "./AppleSignInButton";

const events: string[] = [];
const mockDispatch = jest.fn((a: any) => {
  events.push(`dispatch:${a.type}`);
  return a;
});
const mockNavigate = jest.fn((to: any) => {
  events.push(`navigate:${typeof to === "string" ? to : JSON.stringify(to)}`);
});
const mockLogin = jest.fn();
const mockSignIn = jest.fn();
const mockLoad = jest.fn(() => Promise.resolve({}));
let mockServicesId = "com.bananatalk.web";
let nonceCounter = 0;

jest.mock("../../../store/slices/appConfigSlice", () =>
  require("../../../utils/testing/mockWebFlags").appConfigSliceMock()
);
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("react-redux", () => ({ useDispatch: () => mockDispatch }));
jest.mock("react-router-dom", () => ({ useNavigate: () => mockNavigate }));
jest.mock("react-toastify", () => ({
  Bounce: {},
  toast: { error: jest.fn(), info: jest.fn(), success: jest.fn() },
}));
jest.mock("../../../store/slices/appleAuthSlice", () => ({
  useAppleWebLoginMutation: () => [mockLogin, { isLoading: false }],
}));
jest.mock("./appleJs", () => {
  const actual = jest.requireActual("./appleJs");
  return {
    ...actual,
    appleServicesId: () => mockServicesId,
    makeNonce: () => `nonce-${++nonceCounter}-${"x".repeat(30)}`,
    loadAppleJs: (...a: any[]) => mockLoad(...a),
    signInWithApple: (...a: any[]) => mockSignIn(...a),
  };
});

const { toast } = require("react-toastify");
const { AppleJsError } = require("./appleJs");

const COMPLETE = { _id: "u1", name: "Ada", profileCompleted: true, native_language: "Uzbek", language_to_learn: "Korean", gender: "female" };
const FRESH = { _id: "u2", name: "Apple User", email: "x@privaterelay.appleid.com", profileCompleted: false, isRegistrationComplete: true, gender: "" };

const loginReturns = (body: any) => mockLogin.mockReturnValue({ unwrap: () => Promise.resolve(body) });
const loginFails = (err: any) => mockLogin.mockReturnValue({ unwrap: () => Promise.reject(err) });

beforeEach(() => {
  events.length = 0;
  nonceCounter = 0;
  mockServicesId = "com.bananatalk.web";
  mockAppConfig({ webAppleSigninEnabled: true });
  [mockDispatch, mockNavigate, mockLogin, mockSignIn, mockLoad, toast.error, toast.info, toast.success].forEach((m: any) =>
    m.mockClear()
  );
});

describe("visibility", () => {
  it("is absent while the flag is off", () => {
    mockAppConfig({ webAppleSigninEnabled: false });
    render(<AppleSignInButton redirect="/" />);
    expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  });
  it("is absent while app-config loads or failed", () => {
    mockAppConfig("loading");
    const { unmount } = render(<AppleSignInButton redirect="/" />);
    expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
    unmount();
    mockAppConfig("error");
    render(<AppleSignInButton redirect="/" />);
    expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  });
  it("is absent with the flag on but no Services ID in the build", () => {
    mockServicesId = "";
    render(<AppleSignInButton redirect="/" />);
    expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  });
  it("shows Apple's label when on, and fetches nothing until the pointer gets near it", () => {
    render(<AppleSignInButton redirect="/" />);
    expect(screen.getByTestId("apple-signin-button")).toHaveTextContent("Continue with Apple");
    expect(mockLoad).not.toHaveBeenCalled();
    fireEvent.pointerEnter(screen.getByTestId("apple-signin-button"));
    expect(mockLoad).toHaveBeenCalledTimes(1);
  });
});

describe("signing in", () => {
  it("sends the same nonce to Apple and to the backend, then signs in and follows ?redirect=", async () => {
    mockSignIn.mockResolvedValue({ identityToken: "id.tok" });
    loginReturns({ success: true, token: "t", refreshToken: "r", user: COMPLETE });
    render(<AppleSignInButton redirect="/moments" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));

    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/moments", { replace: true }));
    const { nonce, state } = mockSignIn.mock.calls[0][0];
    expect(nonce).toMatch(/^[A-Za-z0-9._~-]{16,128}$/);
    expect(state).not.toBe(nonce);
    expect(mockLogin).toHaveBeenCalledWith({ identityToken: "id.tok", nonce });
    expect(mockDispatch).toHaveBeenCalledWith(
      setCredentials({ user: COMPLETE, token: "t", refreshToken: "r", message: "Signed in with Apple" })
    );
    expect(toast.success).toHaveBeenCalled();
  });

  it("passes Apple's first-consent name through to the backend", async () => {
    const user = { name: { firstName: "Ada", lastName: "Lovelace" }, email: "ada@privaterelay.appleid.com" };
    mockSignIn.mockResolvedValue({ identityToken: "id.tok", user });
    loginReturns({ success: true, token: "t", user: COMPLETE });
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(mockLogin).toHaveBeenCalled());
    expect(mockLogin.mock.calls[0][0].user).toEqual(user);
  });

  it("sends a new Apple account to the completion wizard BEFORE storing the session", async () => {
    mockSignIn.mockResolvedValue({ identityToken: "id.tok" });
    loginReturns({ success: true, token: "t", refreshToken: "r", user: FRESH });
    render(<AppleSignInButton redirect="/moments" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));

    await waitFor(() => expect(mockDispatch).toHaveBeenCalled());
    expect(events[0]).toMatch(/^navigate:/);
    expect(events[1]).toBe("dispatch:auth/setCredentials");
    expect(mockNavigate.mock.calls[0][0]).toBe("/register");
    expect(mockNavigate.mock.calls[0][1].state).toMatchObject({
      oauth: true,
      startStep: "languages",
      userData: { _id: "u2", bio: "Hello! I joined using Apple." },
    });
    expect(toast.info).toHaveBeenCalled();
  });

  it("does nothing visible when the user closes the Apple window", async () => {
    mockSignIn.mockResolvedValue(null);
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(screen.getByTestId("apple-signin-button")).not.toBeDisabled());
    expect(mockLogin).not.toHaveBeenCalled();
    expect(toast.error).not.toHaveBeenCalled();
  });

  it("locks the button while signing in (no double popup)", async () => {
    let finish: (v: any) => void = () => {};
    mockSignIn.mockReturnValue(new Promise((r) => (finish = r)));
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    expect(screen.getByTestId("apple-signin-button")).toBeDisabled();
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    expect(mockSignIn).toHaveBeenCalledTimes(1);
    await act(async () => finish(null));
  });

  it("uses a fresh nonce on every attempt", async () => {
    mockSignIn.mockResolvedValue(null);
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(screen.getByTestId("apple-signin-button")).not.toBeDisabled());
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(mockSignIn).toHaveBeenCalledTimes(2));
    expect(mockSignIn.mock.calls[0][0].nonce).not.toBe(mockSignIn.mock.calls[1][0].nonce);
  });
});

describe("failures", () => {
  it("hides itself and says so when the backend answers feature_disabled", async () => {
    mockSignIn.mockResolvedValue({ identityToken: "id.tok" });
    loginFails({ status: 404, data: { success: false, error: "Not found", code: "feature_disabled" } });
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument());
    expect(toast.error).toHaveBeenCalledWith("Sign in with Apple isn't available on the website yet.", expect.anything());
    expect(mockDispatch).not.toHaveBeenCalled();
  });

  it.each([
    [{ status: 503, data: {} }, "Sign in with Apple isn't available right now. Try again later."],
    [{ status: 403, data: { error: "suspended" } }, "This account has been suspended."],
    [{ status: 401, data: {} }, "Couldn't sign in with Apple. Try again."],
  ])("backend %j -> toast, stays visible, not signed in", async (err, text) => {
    mockSignIn.mockResolvedValue({ identityToken: "id.tok" });
    loginFails(err);
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith(text, expect.anything()));
    expect(screen.getByTestId("apple-signin-button")).not.toBeDisabled();
    expect(mockDispatch).not.toHaveBeenCalled();
  });

  it("explains a blocked popup", async () => {
    mockSignIn.mockRejectedValue(new AppleJsError("blocked"));
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() =>
      expect(toast.error).toHaveBeenCalledWith(
        "Your browser blocked the Apple window. Allow pop-ups for banatalk.com and try again.",
        expect.anything()
      )
    );
    expect(mockLogin).not.toHaveBeenCalled();
  });

  it("survives Apple's script failing to load", async () => {
    mockSignIn.mockRejectedValue(new AppleJsError("failed"));
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith("Couldn't sign in with Apple. Try again.", expect.anything()));
  });

  it("a failed preload is silent (the click retries)", async () => {
    mockLoad.mockReturnValueOnce(Promise.reject(new AppleJsError("failed")));
    render(<AppleSignInButton redirect="/" />);
    fireEvent.focus(screen.getByTestId("apple-signin-button"));
    await Promise.resolve();
    expect(toast.error).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-apple && CI=true npm test -- --watchAll=false AppleSignInButton
```
Expected: FAIL — `Cannot find module './AppleSignInButton'`.

- [ ] **Step 3: Implement**

Create `src/components/auth/apple/AppleSignInButton.tsx`:

```tsx
import React, { useRef, useState } from "react";
import { useDispatch } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Bounce, toast } from "react-toastify";
import { FaApple } from "react-icons/fa";
import { useWebFlag } from "../../../utils/webFlags";
import { setCredentials } from "../../../store/slices/authSlice";
import { useAppleWebLoginMutation } from "../../../store/slices/appleAuthSlice";
import { appleServicesId, loadAppleJs, makeNonce, signInWithApple } from "./appleJs";
import { appleErrorKind, appleErrorText } from "./appleErrors";
import { isProfileComplete, oauthCompletionState } from "../socialSignIn";

const TOAST = { position: "top-right" as const, theme: "dark" as const, transition: Bounce };

/**
 * Sign in with Apple (Apple JS popup -> POST /auth/apple/web). Hidden unless
 * webAppleSigninEnabled is on AND this build has a Services ID; hidden again
 * for the rest of the page view if the backend says the feature is off.
 * Apple's style rules: black button, white logo, "Continue with Apple".
 */
const AppleSignInButton: React.FC<{ redirect: string }> = ({ redirect }) => {
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const enabled = useWebFlag("webAppleSigninEnabled");
  const [appleWebLogin] = useAppleWebLoginMutation();
  const [busy, setBusy] = useState(false);
  const [serverDisabled, setServerDisabled] = useState(false);
  const busyRef = useRef(false);

  if (!enabled || serverDisabled || !appleServicesId()) return null;

  // Warm the script so the popup opens inside the click's user activation
  // (Safari drops popups opened after a slow await).
  const preload = () => {
    loadAppleJs().catch(() => {
      /* the click retries and reports */
    });
  };

  const onClick = async () => {
    if (busyRef.current) return;
    busyRef.current = true;
    setBusy(true);
    try {
      const nonce = makeNonce();
      const state = makeNonce();
      const apple = await signInWithApple({ nonce, state });
      if (!apple) return; // closed the window: nothing to say

      const args: any = { identityToken: apple.identityToken, nonce };
      if (apple.user) args.user = apple.user;
      const res: any = await appleWebLogin(args).unwrap();
      const user = res.user || res.data;
      const credentials = setCredentials({
        user,
        token: res.token,
        refreshToken: res.refreshToken,
        message: "Signed in with Apple",
      });

      if (!isProfileComplete(user)) {
        toast.info(t("authentication.register.completeProfile") || "Please complete your profile to continue", {
          ...TOAST,
          autoClose: 3000,
        });
        // Navigate BEFORE storing the session: Login.tsx redirects to
        // ?redirect= the moment userInfo appears, which would skip the wizard.
        navigate("/register", { state: oauthCompletionState(user, "apple") });
        dispatch(credentials);
        return;
      }

      dispatch(credentials);
      toast.success(t("auth.apple.signedIn") || "Signed in with Apple", { ...TOAST, autoClose: 2000 });
      navigate(redirect, { replace: true });
    } catch (err) {
      const kind = appleErrorKind(err);
      if (kind === "disabled") setServerDisabled(true);
      toast.error(appleErrorText(kind, t), { ...TOAST, autoClose: 4000 });
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  };

  return (
    <button
      type="button"
      data-testid="apple-signin-button"
      onClick={onClick}
      onPointerEnter={preload}
      onFocus={preload}
      disabled={busy}
      aria-busy={busy}
      className="apple-btn flex w-full items-center justify-center gap-3 rounded-xl bg-black px-6 py-3.5 text-base font-semibold text-white transition hover:bg-gray-900 disabled:cursor-wait disabled:opacity-60"
      style={{ marginBlockStart: "0.75rem" }}
    >
      <FaApple size={20} aria-hidden />
      <span>
        {busy
          ? t("auth.apple.signingIn") || "Signing in with Apple…"
          : t("auth.apple.continue") || "Continue with Apple"}
      </span>
    </button>
  );
};

export default AppleSignInButton;
```

Note on the `return` inside `try` for a cancelled popup: `finally` still runs, so the button unlocks.

`src/utils/locales/eng.json`, inside `"auth": { "apple": { … } }` next to `"errors"`:

```json
      "continue": "Continue with Apple",
      "signingIn": "Signing in with Apple…",
      "signedIn": "Signed in with Apple",
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false AppleSignInButton appleJs appleErrors socialSignIn
```
Expected: `AppleSignInButton` 17 tests pass; the others stay green.

- [ ] **Step 5: Commit**

```bash
git add src/components/auth/apple/AppleSignInButton.tsx src/components/auth/apple/AppleSignInButton.test.tsx src/utils/locales/eng.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(auth): "Continue with Apple" button for the website (not mounted yet)

Fresh nonce + state per attempt, Apple JS popup, POST /auth/apple/web
with the same nonce and Apple's first-consent name. A new Apple account
goes to the completion wizard (navigate before storing the session so
Login's redirect cannot skip it). Cancel is silent; feature_disabled
hides the button; 503/403/blocked popup get their own line. Renders
nothing unless webAppleSigninEnabled is on and a Services ID is built in.

Still open (Phase 4 apple): P4-APPLE-5 (mount + flag-off guard), I18N, push.
EOF
```

---

### Task P4-APPLE-5: Button on Login and Register; hidden while `webAppleSigninEnabled` is off or no Services ID is configured

**Files:**
- Modify: `src/components/auth/Login.tsx` — import; `<AppleSignInButton redirect={redirect} />` right after the Google
  `</button>` (`:101-109` on `origin/main`; P3-LINK-5 does not touch `Login.tsx`)
- Modify: `src/components/auth/Register.tsx` — import; the button on the email step after the email field block
  (`:513-528`, before the "already have an account" line `:529`); the default export becomes a wrapper keyed by mode
  (`:… export default Register;`, last line)
- Modify: `.env.production` (one empty variable + comment)
- Test: `src/components/auth/Login.apple.test.tsx` (new), `src/components/auth/Register.apple.test.tsx` (new)

**Interfaces:**
- Consumes: `AppleSignInButton` (P4-APPLE-4); `useWebFlag` via the mocked app-config (`mockWebFlags`, P4-0);
  `REACT_APP_APPLE_SERVICES_ID` (build env).
- Produces: the Apple entry point on `/login` and on `/register` (email step only; never in OAuth completion mode).
  `Register`'s default export is now `RegisterRoute` (same props: none), which remounts the wizard when the router
  state switches between sign-up and completion mode — needed because an Apple sign-in on the email step navigates to
  the same `/register` route with `state.oauth`, and without a remount the wizard keeps its sign-up steps and empty
  prefill (`useState` initialisers at `Register.tsx:113-140` run once).

- [ ] **Step 1: Write the failing tests**

Create `src/components/auth/Login.apple.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";
import { APPLE_JS_URL, _resetAppleJsForTests } from "./apple/appleJs";
import Login from "./Login";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-redux", () => ({
  useDispatch: () => jest.fn(),
  useSelector: (sel: any) => sel({ auth: { userInfo: null } }),
}));
jest.mock("../../store/slices/usersSlice", () => ({
  useLoginUserMutation: () => [jest.fn(), { isLoading: false }],
}));
jest.mock("../../store/slices/appleAuthSlice", () => ({
  useAppleWebLoginMutation: () => [jest.fn(), { isLoading: false }],
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const appleScripts = () => document.querySelectorAll(`script[src="${APPLE_JS_URL}"]`).length;

function renderLogin() {
  return render(
    <MemoryRouter initialEntries={["/login?redirect=/moments"]}>
      <Routes>
        <Route path="/login" element={<Login />} />
      </Routes>
    </MemoryRouter>
  );
}

beforeEach(() => {
  _resetAppleJsForTests();
  delete (window as any).AppleID;
  document.querySelectorAll(`script[src="${APPLE_JS_URL}"]`).forEach((s) => s.remove());
  process.env.REACT_APP_APPLE_SERVICES_ID = "com.bananatalk.web";
});
afterAll(() => {
  delete process.env.REACT_APP_APPLE_SERVICES_ID;
});

it("flag off: no Apple button, Google and email sign-in unchanged, nothing fetched from Apple", () => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderLogin();
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  expect(screen.getByText("Continue with Google")).toBeInTheDocument();
  fireEvent.pointerEnter(screen.getByText("Continue with Google"));
  expect(appleScripts()).toBe(0);
});

it("app-config failed: no Apple button", () => {
  mockAppConfig("error");
  renderLogin();
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
});

it("flag on but no Services ID in this build: no Apple button, nothing fetched", () => {
  process.env.REACT_APP_APPLE_SERVICES_ID = "";
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderLogin();
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  expect(appleScripts()).toBe(0);
});

it("flag on + Services ID: the button sits under Google; Apple's script only on approach", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderLogin();
  const apple = screen.getByTestId("apple-signin-button");
  const google = screen.getByText("Continue with Google").closest("button") as HTMLElement;
  // eslint-disable-next-line no-bitwise
  expect(google.compareDocumentPosition(apple) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  expect(appleScripts()).toBe(0);
  fireEvent.pointerEnter(apple);
  expect(appleScripts()).toBe(1);
});
```

Create `src/components/auth/Register.apple.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";
import Register from "./Register";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-redux", () => ({
  useDispatch: () => jest.fn(),
  useSelector: (sel: any) => sel({ auth: { userInfo: null } }),
}));
// Register (and its username/location fields) use many usersSlice hooks; every
// mutation is an idle stub, every lazy query a stub trigger, every query empty.
jest.mock("../../store/slices/usersSlice", () =>
  new Proxy(
    {},
    {
      get: (_target: any, key: any) => {
        const k = String(key);
        if (k === "__esModule") return true;
        if (k.indexOf("useLazy") === 0) return () => [jest.fn(), { isFetching: false }];
        if (/Mutation$/.test(k)) return () => [jest.fn(), { isLoading: false }];
        if (/^use.*Query$/.test(k)) return () => ({ data: undefined, isLoading: false });
        return undefined;
      },
    }
  )
);
jest.mock("../../store/slices/appleAuthSlice", () => ({
  useAppleWebLoginMutation: () => [jest.fn(), { isLoading: false }],
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderAt(entry: any) {
  return render(
    <MemoryRouter initialEntries={[entry]}>
      <Routes>
        <Route path="/register" element={<Register />} />
      </Routes>
    </MemoryRouter>
  );
}

beforeEach(() => {
  process.env.REACT_APP_APPLE_SERVICES_ID = "com.bananatalk.web";
});
afterAll(() => {
  delete process.env.REACT_APP_APPLE_SERVICES_ID;
});

it("flag off: the email step has no Apple button", () => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderAt("/register");
  expect(document.querySelector('input[type="email"]')).not.toBe(null); // the email step rendered
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
});

it("flag on: the email step offers Continue with Apple", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderAt("/register");
  expect(screen.getByTestId("apple-signin-button")).toBeInTheDocument();
});

it("never in OAuth completion mode, even with the flag on", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderAt({
    pathname: "/register",
    state: {
      oauth: true,
      startStep: "languages",
      userData: { _id: "u2", name: "Ada", email: "a@privaterelay.appleid.com", bio: "", gender: "other", nativeLanguage: "", languageToLearn: "", birthDate: "2000-01-01" },
    },
  });
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
});
```

If `Register.apple` fails to render because a register sub-field (`UsernameAvailabilityField`, `LocationField`) reaches
a module the mocks above do not cover, mock that module in this file the same way (idle stubs) — do not change the
component to suit the test.

- [ ] **Step 2: Run and confirm it fails**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-apple && CI=true npm test -- --watchAll=false Login.apple Register.apple
```
Expected: FAIL — the three "flag on" cases cannot find `apple-signin-button` (the button is not mounted yet); the
flag-off cases already pass (nothing to hide yet) and keep guarding once it is mounted.

- [ ] **Step 3: Implement**

`src/components/auth/Login.tsx`:
- add after `import "./Login.scss";`: `import AppleSignInButton from "./apple/AppleSignInButton";`
- after the Google button's closing `</button>` (`:109`) and before `{/* Divider */}`, insert:

```tsx
            {/* Apple — renders nothing unless webAppleSigninEnabled is on and the
                build has a Services ID (P4-APPLE-4). */}
            <AppleSignInButton redirect={redirect} />
```

`src/components/auth/Register.tsx`:
- add after the `LocationField` import: `import AppleSignInButton from "./apple/AppleSignInButton";`
- in the `{currentStep === "email" && (` block, between the email field's closing `</div>` (the `mb-4` block, ends at
  `:528`) and `<div className="text-center mt-4 text-sm text-gray-600">`, insert:

```tsx
            {!completionMode && <AppleSignInButton redirect={redirect} />}
```

- replace the last line `export default Register;` with:

```tsx
// Keyed by mode. An Apple sign-in on the email step navigates to this same
// route with `state.oauth` (completion mode). Same route, same element: React
// would keep the sign-up wizard's state (steps, empty prefill). A new key
// remounts it so the completion wizard starts from the new router state.
const RegisterRoute = () => {
  const { state } = useLocation();
  const mode = state && (state as any).oauth === true ? "completion" : "signup";
  return <Register key={mode} />;
};

export default RegisterRoute;
```

`.env.production`, append:

```bash

# Sign in with Apple on the website: the Services ID (owner creates it in
# Phase 5, grouped with com.bananatalk.bananatalkApp, return URL
# https://banatalk.com/login). Empty = the Apple button stays hidden even
# when /app-config says webAppleSigninEnabled.
REACT_APP_APPLE_SERVICES_ID=
```

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false Login Register AuthCallback apple socialSignIn
```
Expected: `Login.apple` 4, `Register.apple` 3 pass; the existing `Login.test.tsx` (Back-after-login) and the register
helper suites stay green.

- [ ] **Step 5: Commit**

```bash
git add src/components/auth/Login.tsx src/components/auth/Register.tsx src/components/auth/Login.apple.test.tsx src/components/auth/Register.apple.test.tsx .env.production docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(auth): Continue with Apple on login and register, dark behind the flag

The button sits under Google on /login and on the email step of
/register (never in completion mode). It renders nothing, and Apple's
script is never requested, while webAppleSigninEnabled is off, while
app-config is loading or failed, or while the build has no Services ID
(REACT_APP_APPLE_SERVICES_ID, empty until the owner creates it).
Register remounts when it switches into completion mode.

Still open (Phase 4 apple): I18N, push; owner: Services ID, return URL,
REACT_APP_APPLE_SERVICES_ID, APPLE_WEB_SERVICES_ID, then the flag.
EOF
```

---

#### Keys added by P4-APPLE-2 and P4-APPLE-4 (all under `auth.apple`)

| Key | English |
|---|---|
| `continue` | Continue with Apple |
| `signingIn` | Signing in with Apple… |
| `signedIn` | Signed in with Apple |
| `errors.disabled` | Sign in with Apple isn't available on the website yet. |
| `errors.unavailable` | Sign in with Apple isn't available right now. Try again later. |
| `errors.banned` | This account has been suspended. |
| `errors.rate_limited` | Too many sign-in attempts. Wait a minute and try again. |
| `errors.blocked` | Your browser blocked the Apple window. Allow pop-ups for banatalk.com and try again. |
| `errors.failed` | Couldn't sign in with Apple. Try again. |

`continue` follows Apple's localized button titles where Apple publishes one for the locale (Human Interface
Guidelines, "Sign in with Apple" button titles: e.g. `kor` "Apple로 계속하기", `ja` "Appleで続ける", `zho` "通过 Apple 继续",
`fr` "Continuer avec Apple", `de` "Mit Apple fortfahren", `es` "Continuar con Apple"); "Apple" is never translated or
transliterated.

### Task P4-APPLE-I18N: The Apple unit's new strings in all 18 locales

**Files:**
- Create: `scripts/i18n/keys/2026-10-16-p4-apple.json` (all 18 locales; the durable record of this unit's translations)
- Modify: `src/utils/locales/*.json` (17 non-English files, via `scripts/i18n/merge-keys.js`)

**Interfaces:**
- Consumes: the 9 keys in the table above (found from the diff against `web/p4-base` by `scripts/i18n/new-keys.js`,
  so a key added beyond the table is still caught); the guard `src/utils/locales/p3Keys.test.ts`, which P4-0 widened to
  read `2026-10-16-p4-*.json`.
- Produces: no English-only key in this unit's push.

Translation rules: as in P3-CHAT-I18N (placeholders verbatim — this unit has none; tone per
`docs/l10n/2026-09-23-native-pass-*.md`; "BananaTalk", "Apple" and "banatalk.com" never translated). `ar` is RTL: the
button keeps the logo before the label in reading order (the flex row follows `dir`), nothing to mirror by hand.

- [ ] **Step 1: Generate the keys file and watch the guard fail**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-apple
node scripts/i18n/new-keys.js web/p4-base scripts/i18n/keys/2026-10-16-p4-apple.json
CI=true npm test -- --watchAll=false p3Keys
```
Expected: `9 new or changed keys -> scripts/i18n/keys/2026-10-16-p4-apple.json`; the test FAILS with
`auth.apple.…: missing` for each of the 17 non-English locales.

- [ ] **Step 2: Translate**

Fill every `""` in `scripts/i18n/keys/2026-10-16-p4-apple.json` for the 17 non-English locales (rules above).

- [ ] **Step 3: Merge into the locale files**

```bash
node scripts/i18n/merge-keys.js scripts/i18n/keys/2026-10-16-p4-apple.json
```
Expected: `merged into 18 locale files`.

- [ ] **Step 4: Run → PASS**

```bash
CI=true npm test -- --watchAll=false p3Keys i18n
```
Expected: every `2026-10-16-p4-apple.json` case passes; the earlier units' key files stay complete; `src/utils/i18n*.test.ts`
stay green.

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/keys/2026-10-16-p4-apple.json src/utils/locales/*.json docs/REMAINING_WORK.md
git commit -F - <<'EOF'
i18n(auth): translate the Sign in with Apple strings into all 18 locales

Keys found by scripts/i18n/new-keys.js against web/p4-base and merged
with merge-keys.js; the keys guard fails on any missing translation.

Still open (Phase 4 apple): push gate (P4-APPLE-PUSH); native review of
the new strings.
EOF
```

---

### Task P4-APPLE-PUSH: Push unit APPLE (5 of 5) — full suite + build green, then the coordinator pushes

**Files:**
- Modify: `docs/REMAINING_WORK.md` (§1 Status line, §6 changelog line, §2 owner lines, §3 production-QA lines below)

- [ ] **Step 1: Every task in the unit is committed and ticked**

```bash
cd /Users/davis/Desktop/Personal/wt-web-p4-apple
git status --short                                     # expect: nothing (except the node_modules symlink, untracked)
grep -n "P4-APPLE-" docs/REMAINING_WORK.md | grep -c "\[ \]"   # expect: 1 (this PUSH line only)
```

- [ ] **Step 2: Rebase onto the live site (after CALLS is pushed)**

```bash
git fetch origin
git log origin/main --oneline | grep -c "Phase 4 .* ready to deploy"   # expect 4 (REELS, GATHERINGS, ROOMS, CALLS)
git rebase origin/main
```
Expected conflicts, only in: `src/utils/locales/*.json` (keep both sides' keys — this unit only adds the `auth`
object), `docs/REMAINING_WORK.md` (keep both sides' lines and ticks), and `src/utils/locales/p3Keys.test.ts` only if an
earlier unit also touched its pattern (keep `/^2026-10-16-p[34]-[a-z]+\.json$/`). `Login.tsx`/`Register.tsx`/
`AuthCallback.tsx`/`constants.ts`/`.env.production` are touched by no other Phase 4 unit; a conflict there means a
hotfix landed — keep both changes. `package.json`/`package-lock.json` come in from ROOMS unchanged: after the rebase
the symlinked `node_modules` (main checkout) has no `livekit-client`, so before Step 3 run
`ls node_modules/livekit-client >/dev/null 2>&1 || (rm node_modules && npm ci)` — the suite imports the LiveKit
loader only through mocks, but `npm run build` resolves the real package for the `livekit` chunk.
After resolving: `git rebase --continue`, then `CI=true npm test -- --watchAll=false p3Keys`.

- [ ] **Step 3: Full suite**

```bash
CI=true npm test -- --watchAll=false 2>&1 | tail -8
```
Expected: `Test Suites: … 0 failed`, `Tests: … 0 failed`; passed count ≥ the CALLS push's count plus this unit's 62
new tests. Any failure: fix in a new commit (never `--no-verify`, never skip a test to get green).

- [ ] **Step 4: Production build**

```bash
npm run build 2>&1 | tail -20
grep -c "appleid.cdn-apple.com" build/static/js/main.*.js     # 0 or 1 — see below
grep -l "appleid.cdn-apple.com" build/static/js/*.js
```
Expected: `Compiled successfully` or `Compiled with warnings` and the prerender step finishes without an error line.
The build does **not** type-check this repo (verified while planning), so TS 3.7 limits in this unit are held by review:
no `import type`, no `#private`, `AppleJsError` is a plain class with a `kind` field. The Apple CDN URL must appear only
in the lazy `Login`/`Register` chunks, never in `main.*.js` (the auth pages are `lazyWithRetry` routes; the first grep
prints `0`). If it prints `1`, something eager imported `apple/appleJs` — find it with
`grep -rn "apple/appleJs\|AppleSignInButton" src --include=*.tsx --include=*.ts` and move it behind the lazy boundary.

- [ ] **Step 5: Tracker and status commit**

In `docs/REMAINING_WORK.md`: tick `P4-APPLE-PUSH`; §1 Status: "Phase 4 apple pushed dark (YYYY-MM-DD); all Phase 4
units deployed dark"; §6 Done: one line naming the unit; §2 Owner, add (if not already there from Phase 5 notes):
`- [ ] Apple Services ID (team RJF4T5CJ76, grouped with com.bananatalk.bananatalkApp), domain banatalk.com, return URL https://banatalk.com/login; set APPLE_WEB_SERVICES_ID on the backend and REACT_APP_APPLE_SERVICES_ID in .env.production (commit → deploy); then WEB_APPLE_SIGNIN_ENABLED=true after the QA rows below pass`;
§3 Production QA: one `- [ ]` line per item of Step 8.

```bash
git add docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: Phase 4 apple ready to deploy

Still open (Phase 4): owner creates the Apple Services ID and sets
APPLE_WEB_SERVICES_ID + REACT_APP_APPLE_SERVICES_ID; flag flips after
browser QA (docs/REMAINING_WORK.md §2/§3); device QA rows.
EOF
```

- [ ] **Step 6: Coordinator pushes (deploys) and watches**

```bash
git push origin web/p4-apple:main
gh run watch $(gh run list --workflow deploy.yml -L 1 --json databaseId -q '.[0].databaseId') --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://banatalk.com/            # 200
curl -s https://banatalk.com/ | grep -o 'main\.[0-9a-f]*\.js' | head -1   # a new bundle hash
```

- [ ] **Step 7: Production smoke with the flag OFF (what users get today)**

  - [ ] `curl -s -o /dev/null -w "%{http_code}\n" -X POST -H 'Content-Type: application/json' -d '{}' https://api.banatalk.com/api/v1/auth/apple/web` → `404` (endpoint dark).
  - [ ] `curl -s https://api.banatalk.com/api/v1/app-config?platform=web | grep -o '"webAppleSigninEnabled":[a-z]*'` → `"webAppleSigninEnabled":false`.
  - [ ] Open https://banatalk.com/login and https://banatalk.com/register in Chrome and Safari: no Apple button; DevTools → Network filtered on `apple`: no request to `appleid.cdn-apple.com`, also after hovering the Google button.
  - [ ] Email sign-in and Google sign-in still work on `/login` (Google: the P3-LINK-5 code flow lands signed in, URL clean).
  - [ ] A brand-new Google account now lands in the completion wizard (languages step) instead of a blank profile (P4-APPLE-3 behaviour change), and finishing it opens `/communities`.

- [ ] **Step 8: QA after the owner step (record as §3 lines now; run when the Services ID exists, flag still off for everyone else)**

The flag is global, so this runs in the short window after the owner sets `WEB_APPLE_SIGNIN_ENABLED=true` (or on a
staging backend with the flag on and the same Services ID):
  - [ ] Safari macOS, Chrome desktop, iOS Safari: "Continue with Apple" opens Apple's popup (not blocked) on the first click after hover; closing it leaves the page idle with no toast.
  - [ ] A new Apple ID (never used with BananaTalk): signs in, name from Apple is the profile name (not "Apple User"), lands in the completion wizard, finishing it signs in fully.
  - [ ] The Apple ID already used in the iOS app: web sign-in lands on the **same** account (same profile, chats, followers) — proves the Services ID is grouped with the app's App ID.
  - [ ] "Hide my email" Apple ID: account email is the `privaterelay.appleid.com` address; no crash, no blank name.
  - [ ] Apple sign-in from `/register` email step: lands in the completion wizard with name/email prefilled (Register remount).
  - [ ] `/login?redirect=/moments` with an existing complete account: lands on `/moments`.
  - [ ] Flip `WEB_APPLE_SIGNIN_ENABLED=false` with the login page open, click the button: toast "isn't available on the website yet", button disappears.
  - [ ] QA sheet row added to the app's `docs/qa/regression-suite.csv` (area "Web"): "Sign in with Apple on web, same Apple ID as the app → same account".

Record results in `docs/REMAINING_WORK.md` §3 in a docs-only commit. A failure that breaks a live flow (email or Google
sign-in) → Step 9.

- [ ] **Step 9 (only if needed): Roll back the unit**

```bash
git fetch origin
git checkout -b web/p4-apple-revert origin/main
git revert --no-edit <first-unit-commit>^..<last-unit-commit>   # hashes from: git log --oneline origin/main | head -20
CI=true npm test -- --watchAll=false && npm run build
git push origin HEAD:main
```
(The unit is a linear series after the rebase, so the range revert is clean. Reverting also undoes the P4-APPLE-3
profile-completion fix for Google; if only the Apple button is the problem, revert P4-APPLE-5 alone instead — the
button then exists nowhere. Note the revert in §6 and reopen the tasks.)

---

#### Backend follow-ups found while planning APPLE (file in the backend `docs/REMAINING_WORK.md`, not implemented here)

- Web-only Apple sign-ups store no Apple refresh token (`appleWebLogin` passes `authorizationCode: null`;
  `lib/appleAuthTokens` uses the bundle id as `client_id`), so account deletion cannot revoke the web authorisation
  (App Store guideline 5.1.1(v) applies to the app; for web it is good practice). Needs a Services-ID client secret
  path in `lib/appleAuthTokens` and the web sending `authorization.code`.
- The Services ID lives in the web build env (`REACT_APP_APPLE_SERVICES_ID`), so turning Apple on needs a web commit as
  well as the backend env. Exposing `appleWebServicesId` in `/app-config` (it is public anyway — it appears in Apple's
  popup URL) would make the backend env the single switch.
- New Google accounts are created with `isRegistrationComplete: true` and `profileCompleted` defaulting to `false`
  (`controllers/auth.js:241-249`); clients had to second-guess which flag wins. Worth documenting in the auth
  response contract (P4-APPLE-3 makes the web treat `profileCompleted === false` as authoritative).

## After the five pushes (phase gate, not a task)

- Every `P4-` line in the web `docs/REMAINING_WORK.md` is ticked, or moved to §2 (owner) / §3 (production QA) with a reason.
- All five units are live **dark**: with every flag still `false`, `https://banatalk.com/reels`, `/gatherings`, `/clubs`, `/voice-rooms`, `/rooms`, `/community/city`, `/community/genders`, `/calls` render the 404 page; the navbar, chat header, profile, community and login/register pages show no Phase 4 entry; no request to `appleid.cdn-apple.com` and no `livekit` chunk is fetched on any page.
- Browser/device QA rows are added to the app's `docs/qa/regression-suite.csv` (area "Web"), at minimum: reels feed/viewer/create in Chrome and Safari, a web reel playing in the iOS app; gathering RSVP and club join web ↔ app; a voice room with one app user and one web user (listen, request to speak, host grants, host mutes/removes, end room); browser → app call and app → browser call, voice and video, each with decline-with-message, missed call and busy; incoming call with two web tabs open and the phone ringing at once; camera/mic denied on web; Safari "tap to enable sound"; Sign in with Apple on web (after the Services ID exists) with the same Apple ID as an app account.
- The owner turns flags on one at a time after the matching QA rows pass (Phase 5, `docs/ops/2026-10-16-web-hosting-steps.md`): `WEB_REELS_ENABLED` → `WEB_GATHERINGS_ENABLED` → `WEB_LANGUAGE_ROOMS_ENABLED` → `WEB_VOICE_ROOMS_ENABLED` → `WEB_CALLS_ENABLED` → `WEB_APPLE_SIGNIN_ENABLED` (with `APPLE_WEB_SERVICES_ID` on the backend and `REACT_APP_APPLE_SERVICES_ID` in the web build).
- Coordinator removes the six worktrees (`git worktree remove`) after the last push.

## Not in this plan (belongs elsewhere)

- **Owner (Phase 5):** flag flips after QA; Apple Services ID + return URL + domain verification; `APPLE_WEB_SERVICES_ID` (backend) and the web build's Services ID value.
- **Spec non-goals:** background ringing for web calls (needs Web Push + a service worker); group calls; reel editing beyond trim; converting old WebM voice notes.
- **Backend follow-ups found while planning** (file in the backend `docs/REMAINING_WORK.md`, not implemented here):
  - Apple: web-only Apple sign-ups store no Apple refresh token (`authorizationCode` null; `lib/appleAuthTokens` uses the bundle id), so account deletion cannot revoke the web authorisation. Optional: expose `appleWebServicesId` in `/app-config` so the backend env is the single switch instead of the web build's `REACT_APP_APPLE_SERVICES_ID`.
  - Gatherings: `present()` exposes no attendee list (so `DELETE /gatherings/:id/attendees/:userId` has no UI anywhere); club `members` is a preview (owner, organizers, 12 newest) with no full-list endpoint; a gathering carries no `club` field; `hostDecisionAskedAt` is not exposed.
  - Reels: the feed excludes the viewer's own reels (owners manage them from My Moments); the legacy `POST /moments/:id/report` does not feed the 2-report auto-hide (web uses `POST /reports`, like the app).
  - Calls: `call:state` carries `by` (user id) but no `deviceId`, so "answered in my other tab" vs "on my phone" is told apart client-side; `GET /calls/current` reports a ringing call only to the receiver and only for 60 s.
  - Rooms: no speaker permission server-side (every voice-room token is minted `canPublish: true`, `be/services/livekitService.js:34-60`), so "speaker" is a client convention; no kick handler (the app's `voiceroom:kick` reaches nothing); raised hands use different event names in the app and the backend, so a hand raised on web is invisible to an app host and vice versa; the community city search sends `search`, which never matches `location.city`.
- **Product decision (APPLE, P4-APPLE-3):** new web Google sign-ups go through the profile-completion wizard too (the shared helper checks `profileCompleted === false` first). Keep or revert before the APPLE push.

