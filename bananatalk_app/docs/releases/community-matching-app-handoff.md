# Community matching (app side, Plan C2) - handoff

Branch `feat/community-matching-app` (base 5743f78e, the stories app merge). Not built, not versioned, not submitted, not pushed. The server half is already deployed with every matching switch off. Server guide: `docs/rollout/community-matching.md` in the backend repo.

Goal of this build: make the Community tab (Partners list and Daily matches) load faster and use less data, once the server's `COMMUNITY_SLIM_LIST_ENABLED` switch is on. Everything new is behind one setting the app reads from the server (`communityFastListEnabled` in app-config). That setting is off in production today.

## 1. What changes for users the moment this build ships (server switch off)

Nothing visible. No screen, text, layout or navigation changes, and no new request is sent. The Partners list and Daily matches load, show and refresh exactly as they do today.

Internal differences from the current release, listed so none is a surprise later:

- **Avatars read a different field.** The avatar in a Partners list row, in a Daily match card and in the small story badge on a Partner card now reads a "small picture" field that returns today's picture whenever the server sends no thumbnail. The server sends none while its switch is off, so the same image is shown.
- **The Partners list listens for block events but does nothing with them.** The list holds an idle listener (inside the app, no network or disk) that waits for "you blocked someone". With the switch off it ignores the event. It is there on purpose, because the setting can change while the app is running.
- **Three places touch saved-cache keys that do not exist.**
  - On sign-out the app clears every saved Community first-page entry (it looks for keys starting `community_first_page_v1_`; none exist while the switch has never been on).
  - The Data & Storage "clear all cache" action does the same.
  - After a successful block the app looks for the blocked person in the user's two saved Community entries and finds nothing to remove.
  These are a few in-memory reads. They run on none of the list, load or refresh paths.
- **One more internal helper in the daily request code.** Daily matches use a shared request/parse routine for both the old and the new path. The request, headers and errors are the same as before.
- **Provider bookkeeping.** Three new internal state holders: the flag, the disk-cache helper and the cached daily batch. Only the cached daily batch holds per-user state and is registered with the sign-out reset; the flag (derived from app-config) and the disk-cache helper (stateless) are app-wide and are not reset. With the switch off the cached daily batch is never created.
- **The setting is read in three more places**: when the Partners tab starts, when a Daily card is skipped, and when the daily request starts. Reading it creates a small in-app value derived from app-config (already loaded); no request.
- **The Partners list holder is first touched a few milliseconds earlier**, when the tab starts and asks for the excluded users (before, at the tab's first build). Same request, same timing.
- **In-memory bookkeeping only**: the list remembers when and with which filters it loaded; a list response keeps its decoded rows for its own lifetime. Nothing of this changes a request or a frame with the switch off.
- **No new text, no new widget, no new padding.**

## 2. What appears when the server switch goes on (`COMMUNITY_SLIM_LIST_ENABLED`, app-config `communityFastListEnabled`)

| What | What the user notices |
|---|---|
| Small avatars (once the server has a thumbnail for that person) | Faces in the list, match cards and story badges appear sooner and use less data. A person with no thumbnail yet looks as today. |
| Slim rows | The Partners list downloads lighter rows. Looks the same. A row's follow state still comes right (the server sends a "you follow them" flag). |
| Cursor paging (only when the server's ranking switch is also on, the request uses the server's `smart` order -- app-config `smartSortEnabled` on, server `SMART_SORT_ENABLED` on, no sort chosen by the user -- and there is no search) | Scrolling a long Partners list continues from where the ranking left off. No one should see a gap. Rarely, after the server rebuilds its list while you scroll, someone you already saw could come again; the app removes such repeats. |
| Partners list kept 10 minutes across tab switches | Go to another tab and come back within 10 minutes: the list is still there, no reload, no spinner. After 10 minutes, or with different filters, it reloads as today. |
| First page painted from disk on a cold open (network on) | Open the app and go to Community: the last Partners page you saw (first 20 people, default view only) shows as soon as app-config and your profile have loaded (and the excluded/blocked lookups, so nobody hidden flashes back), before the list request answers; today's Daily matches show as soon as app-config has loaded. Both then update when the network answers. This saves the list round trip, not the start-up requests. Offline nothing is painted from disk: without app-config the setting reads off. |

## 3. What is NOT in this build, and why

- **Nearby cards and the large Partner card background keep the full photo.** They are big cover images (about half the screen wide), so a small thumbnail would look blurry. Using a bigger server-made size would need a model change and a server size: a follow-up.
- **The picture passed into a chat screen is unchanged** (it is the person's profile picture in the chat, not a list avatar).
- **No change to when the first Partners request starts.** Measured: it already starts within one frame of the profile being available, and it needs the profile's languages (the default filter is the viewer's languages; the country filter is VIP-only). Starting earlier would need those cached per user and could load the wrong list.
- **No scroll-position restoration.** When the list is kept across tab switches you land at the top of the kept list.
- **Daily cards do not stay on screen if the network fails after a cached paint.** Today's error view shows (cards vanish with the error). No new widget was allowed to carry "cards plus an error".

## 4. Order with the backend rollout

1. The backend is deployed first, with all switches dark (done).
2. The ranking switches (signals, rank v2, exposure cap) do not depend on this build. They can go on in the server's order whenever the owner wants; old builds get the better ranking too.
3. `COMMUNITY_SLIM_LIST_ENABLED` gives its full effect only after this build is adopted by most users. Before that, old builds just get thumbnails added to rows. Turn it on after the build is out and adopted.
4. Thumbnails for existing photos need the server-side backfill (`node scripts/backfillAvatarThumbs.js`, run on the server; dry-run first). Without it the small avatars only exist for newly uploaded photos. If the CDN URL migration is going to run, run it before the backfill.
5. Daily cards show thumbnails only from the first batch made after the switch (a batch made earlier today has none).
6. Cursor paging needs the server's ranking switch on and a request in the server's `smart` order (app-config `smartSortEnabled` on, server `SMART_SORT_ENABLED` on, no sort chosen by the user) with no search; otherwise the app pages by number as today.

## 5. Device checks before release

Use a test server with the switch on, and two test accounts A and B. Turn the switch on, restart the server, then open the app (it reads app-config at start).

- [ ] Cold open, network on. Kill the app. Open it, go to Community, Partners. The first page from last time appears once app-config and the profile have loaded, before the list request answers, then updates to the fresh list without a flash of "no partners". Then open Matches: yesterday-or-today's cards show first, then update.
- [ ] Cold open, no network. Kill the app, switch to airplane mode, open Community. Expected: Community behaves as the current release (error view, no cached rows). Offline the app has no app-config, so the setting reads off and nothing is read from disk; the Partners tab also waits for the profile, which has no offline copy. Tapping Retry with the network back loads the list. (The cached rows only stay on screen with Retry when app-config and the profile load and the list request alone fails; optional to check, it needs a proxy that fails only `auth/users`.)
- [ ] Skip everyone on page 1, then kill and relaunch with the network on. You see the loading skeleton, not "No partners found", until the real list lands.
- [ ] Tab switches. Open Partners, scroll a bit, go to another tab and back within 10 minutes: no reload, no spinner. Wait more than 10 minutes and come back: it reloads. Change a filter, switch away and back: it reloads.
- [ ] Paging with the server's ranking ON: scroll 5 or more pages of Partners. No person twice, no gap, no end too early. Repeat with the ranking OFF (page numbers). A short page in the middle must not stop the scroll.
- [ ] Change a filter (and then search) while scrolling pages 3 or more: the list restarts from page 1 with the new filter, no old rows mixed in.
- [ ] Block someone from a chat (menu) and then someone from their profile. Return to Partners at once: they are gone. Kill and relaunch: still gone from Partners, including the cached first page. **Matches: a person in today's batch who is blocked today comes back in Matches until the server's day rolls over (UTC midnight).** Pre-existing server behaviour (the server's cached daily batch filters skips but not blocks): expected for now, see section 6 owner decision B and the backend follow-up. Check that they are gone from Matches after the roll-over, and that the server refuses actions on them.
- [ ] Sign out and sign in as another user without killing the app. The new user sees no Partners rows or exclusions from the first user, and never the first user's cached (disk) Daily cards, not even for a frame. **Known, pre-existing (section 6, owner decision A): if the first user's Daily batch had loaded from the network, the second user sees those cards until their own batch lands** -- the current release does the same.
- [ ] Daily matches across the midnight refresh (server day rolls at UTC midnight): leave Matches open past the roll-over, or relaunch after it. New cards, not yesterday's, and a cached batch past its refresh time is not shown.
- [ ] Open a profile from a slim Partners row: the follow button shows the right state (following or not) and follow/unfollow works; return to the list.
- [ ] Extra-matches purchase button: absent on a cached Daily batch (first paint after a cold open), present on the fresh batch when applicable.
- [ ] Low-end Android: scroll the Partners list fast through several pages. Smooth, no jank, no blank avatars. Check avatar sharpness at the three sizes: the 68 px list row, the 56 px match card, the 32 px story badge. Compare against the current release.
- [ ] Data & Storage, "clear all cache": afterwards a cold open shows no cached Partners or Matches (loading instead).
- [ ] Switch OFF (server flag false, restart, reopen the app): everything above behaves as the current release (no cached paint, tab reload on every switch).

## 6. Known limits and open items, most important first

1. **Device checks above have not been run.** The cold-open paint (Partners and Matches), the sign-out/sign-in cases and low-end scroll have only been tested in automated tests.
2. **OWNER DECISION A (pre-existing, not fixed here, flag-independent): after sign-out and sign-in as another user in one app run, user A's Daily batch is shown to user B until B's fetch lands**, with Say hi / Wave / Skip live. Cause: the app keeps one provider container; the sign-out reset invalidates `dailyMatchesProvider`, which keeps A's value while reloading, and the tab shows a reload's old data. The current release does the same; a fix changes behaviour with the switch off, so it is the owner's call. Smallest fix (reviewer): a session-epoch provider bumped in `resetUserSession` and watched by `dailyMatchesProvider`, so the reload shows loading instead of A's batch (the disk-paint gate then treats that reload as "no value"). The other non-autoDispose `FutureProvider`s in the reset list retain values the same way (only the daily one was traced). This build's own variant (A's cached disk cards shown to B for one frame, switch on) is fixed; that fix does not close decision A.
3. **OWNER DECISION B (pre-existing, backend): a person blocked today stays in the server's cached daily batch**, so Matches shows them again (from the network) until UTC midnight; the app does not filter daily cards by blocked ids either (as today). Smallest fix (backend, reviewer): in `withoutSkipped` (`controllers/matching.js`, the cached-batch path) also drop `getBlockedUserIds(viewerId)`. The app's disk copy already drops the blocked person.
4. **Daily `user` objects on disk (answered by the final review):** they hold only what the card already receives (the server's list fields, redacted per the person's privacy toggles); no email, phone, token, device or exact location. The full birth date (when the person shows their age) and follower/following id lists are in the entry, as in today's response. A cached row keeps a profile as it was when saved, for up to 24 hours (a later privacy change or block shows only once the fresh page lands; the server refuses actions). If the server answers with full rows (slim switch off after the app read app-config, or a server fallback), the Partners entry holds them as sent; a large one is refused by the 300 KB cap.
5. **A daily network failure after a cached paint shows today's full error view** (cards vanish). Keeping the cards would need a new "cards plus error" affordance.
6. **Cached Daily card actions stay enabled** (Say hi, Wave, Skip). The server rejects blocked targets. Same exposure as a list loaded minutes ago: you could wave at someone no longer in today's batch.
7. **Blocked people (fixed in the final fix wave, switch on):** the Partners list keeps this session's blocked ids in their own set (a refresh does not clear it); every page (page 1, later pages, the disk paint) is filtered by it before it reaches the screen, so a page in flight or a server that still returns them cannot bring them back. `BlockService` fires the block event before its local cleanup; a test shows a throwing listener cannot break the block (its error goes to its zone), so that code is unchanged.
8. **Skips on a kept list (switch on):** a remounted tab filters a kept list by this session's skips and blocks at once, also while the exclusions refetch is out, and keeps them when the refetch lands (a skip still on its way to the server stays hidden). Switch off: unchanged (a skip that failed to reach the server can reappear after a refetch, as today).
9. **Cursor paging:** after a server rebuild mid-scroll one person can repeat (removed on the client). A scroll stops after 3 pages in a row that add nobody new (when a cursor is in use); a number-paged page in between resets that count. The tab's "fewer than 5 rows, load more" top-up has no widget test with cursor paging.
10. **Cache rules.** The first-page cache holds at most 20 rows for Partners and 24 for Daily (a VIP batch with extras), 300 KB and 24 hours per slot; Daily is also dropped at its server refresh time. Only the default Partners view is cached (no segment, quick chip or search); saved filters are covered by a fingerprint of the exact request (including sort). The chip-reset load never writes the cache. The first Partners load with the switch on waits for the user-id lookup and the disk read before sending the request (as the Moments feed does).
11. **Flag-off exceptions** (accepted rulings, listed in section 1): an idle block-event listener per session; cache key reads on block, sign-out and "clear all cache". `partnerFilterProvider` reads the stateless cache provider even with the switch off (no I/O).
12. **Nearby cards and large Partner card photos keep the full image** (section 3); a `NearbyUser.avatarThumb` field plus a bigger cover size would be a follow-up. Optional follow-up: cache the viewer's learning language and VIP flag per user so `/users` can start before the profile.
13. **Pre-existing, not caused here:** the app-config flag parser `(json[k] as bool?) ?? false` throws on a non-bool value for the older flags (the new key is safe). The Matches tab's `dataView` body keeps its old indentation (not reformatted on purpose). Several tests print debug noise (pre-existing).
14. **The worktree's `.env`** was copied from `.env.example` (git-ignored, not committed) because the real one could not be copied; build from a tree with the real `.env`.
15. **Checks run on this branch (before the final fix wave; the fix wave's runs are in `final-fix-report.md`).** `flutter analyze`: 1,136 issues, 0 errors, 3 warnings, 1,133 infos; main shows the same totals and the same 3 warnings (all in tests). Full `flutter test`: 3,987 passed, 1 failed. The one failure, `test/services/session_reset_test.dart` ("every provider in lib/ is classified"), lists `alreadyWavedProvider`, `userMomentsPagedProvider`, `userMomentsTotalProvider`: identical on main (also fails there alone). Details in `.superpowers/sdd/2026-11-14-community-matching-plan-c2-app/task-7-report.md`.

## 7. Strings

No new strings in this build. `git diff 5743f78e..HEAD --stat -- bananatalk_app/lib/l10n` shows no change, so there is no native review to do.

## 8. Release steps still to do (owner)

Final review of the branch, merge, version bump, release build (the signed build is manual; see the release how-to), Play/App Store submission, then the device checks above, then the server's slim switch once the build is adopted. Not pushed, not built, no version bump yet.
