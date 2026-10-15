# AI Study hub + floating tab bar — device QA matrix

Spec: `docs/superpowers/specs/2026-10-13-ai-study-hub-and-tab-bar-design.md`.
Plan: `docs/superpowers/plans/2026-10-14-ai-study-hub.md`.
Rows re-checked against the code on 2026-10-15 (app `main` 5873205a, backend 9d36fe0).
Record in the Result column: date, build, device/OS, tester, pass/fail + note.

## 0. Setup

- Build: 2.7.0 from `main` (≥ 5873205a). Sections 4–5 (tab bar, support) ship to everyone and run against prod as-is.
- The hub ships dark: prod `/api/v1/app-config` returns `studyHubEnabled: false`, `studyVipOnlyFeatures: []`.
  Rows 1.2–3.4 need the hub on. There is no in-app or debug toggle, and every build (debug and release) calls
  `https://api.banatalk.com/api/v1/` (`lib/service/endpoints.dart:5`). The flag is global (backend env, read once at boot). Two ways:
  - **A. Local backend (debug build only).** Backend `config/config.env`: `STUDY_HUB_ENABLED=true` (row 2.5: `STUDY_VIP_ONLY_FEATURES=photo`),
    `node server.js` (port 5003). App: swap `endpoints.dart` lines 4/5 to `http://<Mac LAN IP>:5003/api/v1/`, build debug.
    The local `MONGO_URI` points at the Atlas cluster — check which DB before spending coins. **Revert `endpoints.dart` before the release build.**
  - **B. Prod, temporarily.** Server `config/config.env`: `STUDY_HUB_ENABLED=true`, then `pm2 restart language-app --update-env`.
    Only 2.7.0 (unreleased) reads the flag, so only testers see it. `STUDY_VIP_ONLY_FEATURES` would hit every 2.7.0 tester.
    **Turn both back off before 2.7.0 reaches users** (devices that cached `true` keep the hub one more launch).
- After any flag change: backend restart, then **cold-start the app twice** (or log out and in once) — see 1.2b.
- Accounts: one non-VIP with ≥ 80 coins, one VIP, one fresh signup (< 7 days, for the guide rows), a second account for the per-account rows.
- Tutor daily cap is 5 per UTC day (resets 09:00 KST); coin unlock = 💎80 for +3 (`config/coinCatalog.js`).

## 1. Flag and appearance

| # | Check | Result |
|---|-------|--------|
| 1.1 | `STUDY_HUB_ENABLED=false` (backend restarted, cold start ×2): AI Study tab shows the old screen (LegacyStudyHub), unchanged | |
| 1.2 | `STUDY_HUB_ENABLED=true` (backend restarted, cold start ×2): AI Study tab shows the one-scroll hub | |
| 1.2b | Cold start never waits: AI Study appears instantly (no spinner), offline too. The page comes from the last remembered flag (`study_hub_enabled_last`, kept across logout). A fresh install, or the first 2.7.0 launch, shows the old screen. After `STUDY_HUB_ENABLED` flips, the **first** cold start still shows the previous page; the new page appears from the **second** cold start. Never swaps mid-session | |
| 1.3 | Light theme: hub, tiles, badges, sheet, tab bar all legible | |
| 1.4 | Dark theme: same | |
| 1.5 | 320-pt width (iPhone SE 1st gen, or a 320 dp Android emulator): no overflow on hub, tiles, badges, sheet, tab bar | |
| 1.6 | Text scale 1.3: no overflow or clipped text anywhere in the hub | |
| 1.7 | Korean: strings fit, no clipped tile titles or badges | |
| 1.8 | Arabic (RTL): the tile badge sits after the title (to its left); the Recommended tile chevron points left; tab bar order mirrored. Known (deferred): inactive tab-icon count badges still overhang the icon's right corner | |
| 1.9 | Header chip shows "<target> · <CEFR>" (just the target when there is no A1–C2 level), after the streak/level chips; chips fade out as the header collapses | |
| 1.10 | Badge text is readable (labelMedium, 12) and does not clip at 1.3 | |
| 1.11 | Kill switch is one launch slow: flip the flag back to false → the hub stays for the first cold start, the old screen returns from the second | |
| 1.12 | Log out and log in (no kill) after the flag changed: AI Study follows the live flag immediately | |

## 2. Tiles, badges, upgrade sheet

| # | Check | Result |
|---|-------|--------|
| 2.1 | Non-VIP account, 5 tutor messages in the same UTC day: the tutor tile shows "0 left" and opens the upgrade sheet | |
| 2.2 | Sheet shows **"Unlock 3 for 💎80"** above Get VIP and Not now. (If coins are off or the catalog hasn't loaded, only Get VIP + Not now show) | |
| 2.3 | Coin unlock (≥ 80 coins) spends 80, shows "Unlocked +3 more! 💎", closes the sheet and opens the tutor (persona picker first if none is set) | |
| 2.3a | Back on the hub after the unlock: the tutor tile shows **no count badge** (not "0 left") and opens directly. After 1 use "2 left", then "1 left"; after the 3rd use "0 left" and the sheet again. Within one UTC day (bonus resets 09:00 KST). Needs backend 9d36fe0 `bonus` | |
| 2.4 | "Get VIP" in the sheet opens plans; `study_upgrade_unlock {method: vip}` fires on tap (intent, not purchase) | |
| 2.5 | Backend `STUDY_VIP_ONLY_FEATURES=photo` (restarted), non-VIP account: the Photo tile shows a 🔒 VIP badge (beats exhausted/low) and opens the sheet with Get VIP + Not now only (no coin unlock: coins can't lift a VIP lock) | |
| 2.6 | NEW badges: at most 3, on the first 3 unseen tiles in grid order (Tutor, Roleplay, Story on a fresh install); tapping one moves NEW to the next unseen tile (Photo) | |
| 2.7 | A NEW badge clears on tapping that tile | |
| 2.8 | Log out, log in as a second account: NEW badges start fresh. Logging back in as the first account also starts fresh (seen state is cleared at logout, not stored per account) | |
| 2.9 | Today row, placed user: normal row | |
| 2.10 | Today row, unplaced user: normal row plus a secondary **"Find your level"** button (also on the done-for-today row). Not shown when the row asks to pick a language or the pack is empty | |
| 2.11 | Language coverage: no tile shows "English only for now" (backend has no hard English-only restriction); confirm nothing is wrongly blocked for a non-English target | |
| 2.12 | VIP account: tutor/talk/speak tiles show no count or lock badges and never open the sheet | |
| 2.13 | Not enough coins (< 80): tapping Unlock shows "Not enough coins" with a "Get more coins" action that opens the coin shop; the sheet stays open | |
| 2.14 | Upgrade sheet at 320 width and text 1.3 / 2.0: content scrolls, Not now stays reachable | |
| 2.15 | Brand-new account or offline: ProgressCard still shows with "–" placeholders and its shortcuts work | |
| 2.16 | No target language → Today row asks to pick one; done-for-today shows the check icon; pull-to-refresh refreshes pack, quotas and progress | |

## 3. Guide and spotlight carousel

The guide shows only for accounts < 7 days old with fewer than 3 of 4 activation milestones — use the fresh account.
The carousel only appears when there are live announcements.

| # | Check | Result |
|---|-------|--------|
| 3.1 | Guide "See all features" scrolls to the feature groups | |
| 3.2 | Spotlight carousel is hidden for the whole guide period, even after the guide card itself is dismissed | |
| 3.3 | Tapping X on a spotlight card removes that card; it stays gone after app restarts (others remain; the carousel disappears when none are left; max 3 cards) | |
| 3.4 | After logout, a second account sees the dismissed cards again (dismissals are cleared at logout, not stored per account) | |

## 4. Floating tab bar (ships to everyone, flag-independent)

| # | Check | Result |
|---|-------|--------|
| 4.1 | Hides after ~24 pt of downward scroll in every tab (AI Study, Community, Chats, Moments, Profile); horizontal carousels/pagers never move it | |
| 4.2 | Shows again on scroll up, at top, at end of list, and on tab switch | |
| 4.3 | Hidden whenever the keyboard is open (Chats search, Community search, chat composer); returns when it closes, even if the list now fits | |
| 4.4 | Re-tap on the active tab scrolls it to top, on every tab (shared `TabReselectScrollToTop`; no TabsScreen widget test exists). Only the visible Community sub-tab scrolls | |
| 4.5 | Active capsule shows the tab name at 390 pt width | |
| 4.6 | 360 pt phone, default text size, English: every tab's active name shows whole (no "…"). At 320 pt or text 1.3 the name may truncate or drop (never overflows) | |
| 4.6a | The pill is centred and hugs the tabs; at most 8 pt from the side edges (narrow phone / large text). Bottom: 8 pt above the screen edge with no system inset, otherwise inset − 4. Inactive icons are 48 pt targets, no gaps | |
| 4.7 | Unread badges on tab icons: no overflow, count moves onto the icon when tight | |
| 4.8 | Nothing floats over content: with the bar showing at the end of a list, the last item clears it. **Check especially Community > Waves, Matches, Gatherings (+ clubs, empty), Nearby, Voice rooms, Rooms, Topics user list, and Profile (logout button)** on gesture AND 3-button nav — moved to `FloatingTabBar.clearance` on 2026-10-15 (ef1f9ba4). Create FABs (Moments, Voice rooms, Rooms, Reels) now sit level with each other just above the bar, and lists under them end with room for the FAB | |
| 4.9 | Reels create FAB sits on the shared bar clearance, not overlapping the bar | |
| 4.10 | Chat list refresh button clears the bar | |
| 4.11 | Hide/show feel on iOS and on Android (no jitter, no flicker on short lists) | |
| 4.12 | TalkBack / VoiceOver on: the bar never hides on scroll; a keyboard-hidden bar is skipped by swipe navigation; tabs announce selection and the unread count ("Chats, 3") | |
| 4.13 | 3-button nav (Android 15): bar sits clear of the nav strip (known: ~4 dp overlap, `inset − 4`); lists with a search field shift ~36 dp while the keyboard is open (known, cosmetic) | |
| 4.14 | 320 dp phone at max Display size (< ~262 dp effective): record whether the bar row clips Profile (known) | |
| 4.15 | Log in as another account: no list scrolls on its own (reselect state reset); each Community sub-tab keeps its own position | |
| 4.16 | Moments feed create FAB clears the bar | |
| 4.17 | A deep link or notification that switches tabs, and Android back to AI Study, bring the bar back | |

## 5. Support (coffee button)

| # | Check | Result |
|---|-------|--------|
| 5.1 | No coffee button floats in the tab shell | |
| 5.2 | Profile drawer > Support section > **"Support BananaTalk"** row ("Help a solo developer keep building") closes the drawer and opens the SupportSheet | |
