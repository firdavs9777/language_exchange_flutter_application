# AI Study hub + floating tab bar — device QA matrix

Spec: `docs/superpowers/specs/2026-10-13-ai-study-hub-and-tab-bar-design.md`.
Plan: `docs/superpowers/plans/2026-10-14-ai-study-hub.md`.
Needs a build from `feat/ai-study-hub` and a dev backend with the study-hub config (backend branch `feat/study-hub-config`).
Record in the Result column: date, build, device/OS, tester, pass/fail + note.

## 1. Flag and appearance

| # | Check | Result |
|---|-------|--------|
| 1.1 | `STUDY_HUB_ENABLED=false`: AI Study tab shows the old screen (LegacyStudyHub), unchanged | |
| 1.2 | `STUDY_HUB_ENABLED=true`: AI Study tab shows the one-scroll hub | |
| 1.2a | Cold start with the flag on: a short neutral loader, then the hub — the old screen never flashes first | |
| 1.2b | Cold start never waits: AI Study appears instantly (no spinner), offline too. The page is picked from the last remembered flag (`study_hub_enabled_last`, kept across logout); first launch after install/update shows the old screen. After `STUDY_HUB_ENABLED` flips, the hub appears from the NEXT launch, never by swapping mid-session | |
| 1.3 | Light theme: hub, tiles, badges, sheet, tab bar all legible | |
| 1.4 | Dark theme: same | |
| 1.5 | iPhone SE (320 pt): no overflow on hub, tiles, badges, sheet, tab bar | |
| 1.6 | Text scale 1.3: no overflow or clipped text anywhere in the hub | |
| 1.7 | Korean: strings fit, no clipped tile titles or badges | |
| 1.8 | Arabic (RTL): badges sit on the leading side of the trailing edge, chevrons mirrored | |
| 1.9 | Header chip shows target language and CEFR level when the pack has one | |
| 1.10 | Badge text is readable (labelMedium, 12) and does not clip at 1.3 | |

## 2. Tiles, badges, upgrade sheet

| # | Check | Result |
|---|-------|--------|
| 2.1 | Exhausted tutor tile opens the upgrade sheet | |
| 2.2 | Sheet shows the "Unlock N for 💎X" coin label (kept, not "Try once for N coins") | |
| 2.3 | Coin unlock spends coins and opens the tutor | |
| 2.3a | After the coin unlock, back on the hub: the tutor tile shows "3 left" (not "0 left") and opens directly without the sheet; after those 3 uses it shows "0 left" again (needs backend 9d36fe0 `bonus`) | |
| 2.4 | "Get VIP" in the sheet opens plans; `study_upgrade_unlock {method: vip}` fires on tap (intent, not purchase) | |
| 2.5 | Locked tile: dev server with `STUDY_VIP_ONLY_FEATURES=photo`, non-VIP account, shows VIP lock badge and opens the sheet with Get VIP + Not now only (no coin unlock: coins can't lift a VIP lock) | |
| 2.6 | NEW badges show at most 3 at a time | |
| 2.7 | A NEW badge clears on tapping that tile | |
| 2.8 | Second account on the same device sees its own NEW badges (not the first account's) | |
| 2.9 | Today row, placed user: normal row | |
| 2.10 | Today row, unplaced user: normal row plus secondary "Take placement" action | |
| 2.11 | Language coverage: no tile shows "English only for now" yet (backend has no hard English-only restriction); confirm nothing is wrongly blocked for a non-English target | |

## 3. Guide and spotlight carousel

| # | Check | Result |
|---|-------|--------|
| 3.1 | Guide "See all features" scrolls to the feature groups | |
| 3.2 | Spotlight carousel is hidden while the guide is showing | |
| 3.3 | Dismissing the carousel persists across app restarts | |
| 3.4 | Dismissal is per account (second account still sees it) | |

## 4. Floating tab bar

| # | Check | Result |
|---|-------|--------|
| 4.1 | Hides on scroll down in every tab (AI Study, Community, Chats, Moments, Profile) | |
| 4.2 | Shows again on scroll up, at top, at end of list, and on tab switch | |
| 4.3 | Hidden while the keyboard is open in Chats search; returns when it closes | |
| 4.4 | Re-tap on the active tab scrolls it to top, on every tab (shared `TabReselectScrollToTop` wrapper; no TabsScreen widget test exists) | |
| 4.5 | Active capsule shows the tab name at 390 pt width | |
| 4.6 | 360 pt phone, default text size, English: every tab's active name shows whole (no "…"). At 320 pt or text 1.3 the name may truncate or drop (never overflows) | |
| 4.6a | Bar sits 8 pt from the screen edges; inactive icons are still easy to hit (48 pt targets, no gaps) | |
| 4.7 | Unread badges on tab icons: no overflow, count moves onto the icon when tight | |
| 4.8 | Nothing floats over content: last item of every list clears the bar | |
| 4.9 | Reels create FAB sits on the shared bar clearance, not overlapping the bar | |
| 4.10 | Chat list refresh button clears the bar | |
| 4.11 | Hide/show feel on iOS and on Android (no jitter, no flicker on short lists) | |

## 5. Support (coffee button)

| # | Check | Result |
|---|-------|--------|
| 5.1 | No coffee button floats in the tab shell | |
| 5.2 | Profile drawer > Support row opens the SupportSheet | |
