# Remaining work — monetization & growth

Last updated: 2026-10-08. Keep this file current: tick items off in the same commit that finishes them.

Context: all three tranches of `docs/superpowers/plans/2026-10-02-monetization-growth.md` are built and
deployed **dark** (every new server flag is off). Backend `main` c5ef2fe is live. App `v2.6.1` (10574) is
tagged and supersedes the never-submitted 2.4.0 / 2.5.0 / 2.6.0. Nothing below affects users on the live
store builds (2.2.4 / 2.2.5) until a flag is turned on.

## 0. Auth audit (2026-10-08) — fix before the next release

App (backend items in the backend repo's `docs/REMAINING_WORK.md`):
- [x] **Signup wipes the Google photo** — wizard sends `'images': []` to `updatedetails`.
- [ ] **Logout `prefs.clear()`** — loses theme, language, remembered email, biometric flag; leaves the biometric secure-storage token.
- [ ] **Previous user's data survives logout / account deletion** — coins, blocked users, tutor, matches, visitors, notification settings, waves unread; deletion invalidates nothing. One shared session-reset helper.
- [ ] **Session dying mid-use leaves empty screens** — `onAuthenticationError` never wired (no redirect to login on 401).
- [ ] Splash hangs if Back is pressed on the Terms screen (`splash_screen.dart:155`).
- [ ] Typed birth date `1995.13.40` passes step 1, fails at submit (step 1 uses `DateTime(y,m,d)` rollover).
- [ ] Double-tap Login / Google / Apple re-runs login (loading flag cleared before navigation).
- [ ] Suspension handler clears only `token`/`userId` (refresh token, ApiClient cache, socket, push token remain).
- [ ] Small: 423 lockout message replaced by generic text; raw exception text shown; a flaky `getLoggedInUser` after login logs the user out.

## 1. Owner (needs the keystore MacBook, store consoles or droplet)

- [ ] **Store prices** — App Store Connect + Play Console: VIP monthly **$3.99**, yearly **$24.99** (quarterly untouched; hidden in the app).
- [ ] **Build + submit 2.6.1** — follow `docs/releases/2.6.1-handoff.md` (TestFlight smoke: sandbox coin purchase, cold-start push tap, one Boost purchase while `BOOSTS_ENABLED` is flipped for 10 minutes).
- [ ] **Android App Links** — `public/.well-known/assetlinks.json` in the web repo still has `TODO_SHA256_*`. Paste the upload-key and app-signing-key SHA-256 from Play Console → App integrity → App signing. Until then no `https://banatalk.com/...` link opens the Android app.
- [ ] **Droplet `config/config.env`** — each `*_ENABLED` key must appear once (dotenv is first-key-wins; `DAILY_MATCHES_ENABLED` / `MATCHES_LAYOUT_ENABLED` were set but still read false).
- [ ] **Flags after store approval** (then `pm2 restart language-app --update-env`):
  - Day 0: `DAILY_MATCHES_ENABLED`, `MATCHES_LAYOUT_ENABLED`, `WELCOME_WAVE_ENABLED`, `LIFECYCLE_PUSH_ENABLED`, `REFERRALS_ENABLED`
  - Day 3: `BOOSTS_ENABLED`, `REWARDED_LIMITS_ENABLED`, `COIN_RECONCILE_ENABLED`
  - Keep OFF: `WAVE_CAP_ENABLED` (decision: waves stay unlimited for now), `SMART_SORT_ENABLED` (until 2.6.x is the majority build — see dashboard `buildMix`), `CONVERSATION_CAP_ENABLED` (until D7 ≥ 20%)
- [ ] **AdMob earnings** — lifetime + last 30 days (the one revenue number not measurable from the DB).
- [ ] **Native-language review** — `docs/l10n/native-qa-strings-2026-10.csv` (1,248 machine-drafted strings, 18 locales; fill the last column). Store listings: backend repo `docs/marketing/2026-10-store-listings-{zh,ar,ru}.md`.
- [ ] Optional: apply the web repo's `deploy/nginx.snippet.conf` on the droplet (serves the Apple association file as `application/json`, real 404s).

## 2. Claude, once 2.6.1 is approved and Day-0 flags are on

- [ ] Verify `/app-config`; sandbox signup receives a welcome wave within a minute; watch the first hourly lifecycle run.
- [ ] Baseline row: `node scripts/growthDashboard.js` (backend), then weekly.
- [ ] Launch campaign: `node scripts/sendCampaign.js --campaign daily_matches --dry-run`, then `--send --yes`.
- [ ] Day 3: verify Boost / rewarded unlock / reconciliation in prod.

## 3. Next phases (decided by the dashboard numbers)

- **Phase E (weeks 3–8):** Boost price test (150 vs 100), coin-pack prices, 3-day VIP trial, interstitial frequency, more rewarded placements, wave cap only if waves are heavily used, smart sort when 2.6.x is the majority.
- **Phase F (only when D7 ≥ 20%):** new-conversation cap (freemium), paid installs (Apple Search Ads in RU / IN / EG), Moment Boost with the content phase, AI tutor bundled into VIP.
- **Content phase spec** (not written yet): moments / reels / stories — lead with practice-posting, demote reels.

## 4. Known gaps (deferred on purpose; none affects a user while flags are off)

App:
- Waves-side "masked" UI is dormant: the server always reveals waves (ruling — the chat already shows the sender). Visitors are the paid reveal.
- `RemoveAdsButton` only under the chat-list banner (visitors screen banner has none).
- Russian `{coins} монет` is not plural-aware (needs ICU plural in the en source).
- Widget-test gaps: the limit dialog's rewarded flow end-to-end, the Matches extra-matches CTA wiring, the drawer rows.
- Non-English strings above are machine-drafted.

Backend (details in `docs/REMAINING_WORK.md` there):
- Rewarded ads have no server-side verification (SSV); the per-feature daily cap is the only guard.
- A booster only appears in daily batches generated after the purchase (batches are cached per day).
- Non-VIP visitors page is server-limited to 1 row, so the masked tile says "Someone viewed your profile" even when several did.
- Dashboard D1/D7 use latest activity (trend, not exact day-N return).
