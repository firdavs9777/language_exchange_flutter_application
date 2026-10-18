# Today's matches on the web

**Date:** 2026-10-08
**Status:** Approved in conversation; written for review
**Scope:** Web only (`language_exchange_web_front`). No backend changes.

---

## Why

The app has a **Today's matches** tab: a daily batch of six partners from `GET /api/v1/matching/daily`, with **Say hi / Wave / Skip** on each card. The web has none of it — nothing calls `/matching/daily`. The user flagged it as very important and chose:

- **Placement:** the **first tab** of `/communities`, which signed-in members land on by default.
- **Priority:** build it before the Moments work.

## What already exists, and is live

All verified against the backend code and production `/app-config` on 2026-10-08.

- **`GET /matching/daily`** (`controllers/matching.js` `getDailyMatches`, behind `protect`). When `DAILY_MATCHES_ENABLED` is off it answers **404**. Its payload:

  ```json
  {
    "success": true,
    "date": "2026-10-08",
    "nextRefreshAt": "2026-10-09T00:00:00.000Z",
    "cached": true,
    "matches": [{
      "user": { "_id": "…", "name": "…", "images": ["…"], "native_language": "…",
                "language_to_learn": "…", "location": { "country": "…" }, "intents": ["learn"] },
      "matchReasons": ["reciprocal_pair", "shared_topic:music", "active_today"],
      "reciprocal": true,
      "lastActiveBucket": "today",
      "responseRate": 0.8,
      "boosted": true
    }]
  }
  ```

  Notes on that payload:
  - `cached` is present only on cache hits.
  - `boosted` is present only when the card is boosted.
  - `user` uses the `USER_LIST_FIELDS` projection, so it carries the raw **`images`** array and no `imageUrls`.
  - The batch is the same all day and rolls over at `nextRefreshAt` (midnight UTC).
  - `BATCH_SIZE` is 6. With an extra-matches pool (bought with coins) it can be larger, so the web never assumes 6.

- **`matchReasons` on `/daily` are CODES**, not English. They are produced by `lib/dailyMatches.js` `structuredReasons`: `reciprocal_pair`, `same_target_language`, `shared_topic:<topicId>` (more than one possible), `active_today`, `same_city`.
- **`POST /interactions/skip`** with body `{ targetUserId }` records a skip, which expires after 24 hours. `getDailyMatches` does **not** read skips. Its exclusions are:
  - the viewer;
  - blocked users;
  - anyone messaged in the last 14 days;
  - anyone shown in a daily batch in the prior 7 days.

  So a skipped person stays out of tomorrow's batch only because they were already shown. Today's batch is cached for the whole UTC day, so the server sends a skipped card again on every load that day.
- **The web already has:**
  - `WaveSheet` (`src/components/community/WaveSheet.tsx`, wired through `handleWaveMember` in `MainCommunity`);
  - chat at `/chat/:userId`;
  - topic labels under `profile.topics.<id>`.
- **Production flags:** `matchesLayoutEnabled: true` and `boostsEnabled: false`. The app shows its "extra matches" coin button only when boosts are on, so it is dormant in production.

## Design

### Data

A new RTK Query endpoint in `communitySlice.ts`:

- `getDailyMatches` → `GET /api/v1/matching/daily`, `keepUnusedDataFor: 60`.
- `skipUser` → `POST /api/v1/interactions/skip` with `{ targetUserId }`.

**A 404 means "this feature is off"**, not an error. Any other failure is a real error state with a retry.

### The tab

- `CommunityUrlTab` / `CommunityNavTab` gain **`today`**, the first entry in the sub-nav. It is rendered in place by the list, like `foryou`.
- **Default tab: `today` becomes the URL's left-out default, and `all` is written explicitly.**
  - Today, `encodeCommunityState` leaves out `tab` when it is `all`, and `MainCommunity` reads `decoded.tab || "all"`. If "no `?tab=`" simply meant Today, clicking All would write a bare `/communities` and show Today again, and All would be unreachable.
  - So `encodeCommunityState` now leaves `tab` out when it is **`today`** and writes `tab=all` like any other tab. `TABS` includes `today`.
  - **An absent `tab` means `today` only when the URL carries no filter, search or sort params; otherwise it means `all`.**
    - Every filtered or searched All link shared before today has no `tab` (for example `/communities?native=ko&learning=en` or `?q=anna`). Read as Today, it would open on a tab that ignores filters, and the canonical-URL rewrite would then strip the shared params.
    - The rule stays canonical: `encode` never writes filter params for `today`, so `encode(decode(encode(x)))` still holds.
    - This lives where the default is applied (`listState.tab = decoded.tab || (url carries filters/search/sort ? "all" : "today")`), not inside `decodeCommunityState`, whose contract is to return only what the URL said.
  - Every path that targets All therefore writes `?tab=all`: the tab itself, `handleResetAll`, and Browse partners. Reload, Back and shared links all keep it.
  - An explicit `?tab=…` always wins.
  - Accepted consequence: old **bare** `/communities` links, which used to mean All, now open on Today. That is what the user chose.
  - **Internal links audited.** The links into `/communities` from these places stay bare and open on Today, since they are entry points:
    - `MainNavbar`, `FooterMain`, `MainMoments`;
    - LanguageCard's missing-card link;
    - ProfilePage's `AFTER_BLOCK`;
    - Register's post-signup redirect;
    - `Topics.tsx`'s back link.

    `SuggestedMembers`' "see more" means "browse everyone", so it points at `/communities?tab=all`.
- **When the feature is off** (404), the fallback is **display-only**:
  - `activeTab` = the URL tab, except that `today` is shown as `all` while the feature is off.
  - The canonical-URL effect (`writeUrl`) keeps writing the **URL-derived** tab (`listState.tab`), not the displayed one. So a bare `/communities` or `?tab=today` stays as it is in the address bar while All is shown.
  - **User-driven writes use the displayed tab.** That covers `applyState`'s base state and the Copy-link encode. A filter change while the feature is off therefore writes `?tab=all`, which describes what is on screen.
  - The Today tab button is hidden.
- **The All list is requested only after `/matching/daily` answers 404.** For members with the feature off, that costs one round-trip before the list shows. This is intended; the alternative is fetching All on every Today landing.
- **No filter params on Today.** Like `foryou` it writes none, and the stored filters stand in. The `forYouWithoutFilters` special case in `listState` and `writeUrl` is extended to `today`. Otherwise the default landing would become `/communities?native=…&learning=…`.
- **Before the first answer,** the Today tab shows a skeleton of match cards. It does not switch tabs while loading, so nothing jumps.
- **Signed out:** no Today tab, because the endpoint is behind `protect`. Logged-out visitors keep seeing `PublicCommunities` as today; the prerendered `/communities` page is unaffected.
- **Hidden on the Today tab:** the filter button, search, sort and the highlighted carousel. The batch is the server's choice; filters do not apply to it.

### The header

- **"Your {{count}} matches today"**, counting the cards still showing — skips decrease it.
- **"Refreshes at {{time}}"**, with `nextRefreshAt` in the reader's local time (`Intl.DateTimeFormat`, hour and minute). If it is missing: "Refreshes at midnight".
- **Rollover:** when the clock passes `nextRefreshAt` while the tab is open, the query refetches once. This is checked on window focus and with one timer set for that moment. The timer is cleared on unmount and re-armed whenever `nextRefreshAt` changes, so no stale timer outlives its batch.

### The card — `src/components/community/MatchCard.tsx`

A row card, not the grid's photo cell, matching the app's layout:

- **Avatar:** `images[0]`. An absolute URL is used as-is; a relative path becomes `${BASE_URL}/uploads/<path>`, the rule `MainNavbar` already uses. No photo means the shared `Avatar` initials fallback.
- **Name,** then the country flag, then a green dot when `lastActiveBucket === 'today'`.
- **Language pair chip:** `<native> → <learning>`, leaving out whichever side is empty.
- **Reason chips,** localized from the codes:

  | Code | Chip |
  |---|---|
  | `reciprocal_pair` | "You're learning each other's language" |
  | `same_target_language` | "Also learning {{language}}", where language is the card user's `language_to_learn` |
  | `shared_topic:<id>` | "Shared interest: {{topic}}", where topic is `t('profile.topics.<id>', { defaultValue: id })`. A plain `t(...) \|\| id` never falls back, because a missing key returns the key itself. |
  | `active_today` | "Active today" |
  | `same_city` | "Lives in your city" |

  An unknown code renders nothing. These are codes, so there is no English string to fall back to, and a raw code is never shown.
- **"Replies fast"** when `responseRate` is a number `>= 0.7`. The server sends `null` when it has no rate, so the type is `number | null`.
- **"Boosted"** when `boosted`.
- **Actions:**
  - **Say hi** — a link to `/chat/<id>`. It is primary.
  - **Wave** — opens the existing `WaveSheet` for this person. `WaveSheet` takes its avatar from `imageUrls?.[0]`, so the card passes the user with `imageUrls: [<resolved photo URL>]`, the same URL its own avatar uses.
  - **Skip** — the card leaves at once and `POST /interactions/skip` is sent. If the request fails, the card stays gone and nothing is reported, the same as the app.
- **Skips survive a reload.** The server sends the same cached batch all day, skipped cards included. So skipped ids are kept in `sessionStorage` under `bt.todaySkips.<date>`, with `date` taken from the payload, and filtered out on every render.
  - When the batch's `date` changes, the old key is ignored and the new day starts clean.
  - Reads and writes are wrapped, so blocked storage only means skips last until reload.
  - This deliberately improves on the app, which keeps skips in memory only.
- **Name or avatar** opens `/community/<id>`.

### Empty state

When every card has been skipped, or the batch is empty:

- "That's everyone for today"
- "Fresh matches tomorrow. Meanwhile, browse all partners."
- A **Browse partners** button that switches to `all`.

### Copy

A new `communityMain.today.*` namespace, in all 18 locales and parity-guarded. The wording follows the app's strings (`matchesTodayTitle`, `matchesRefreshHint`, `matchReason*`, `matchRepliesFast`, `boostedChip`, `matchesEmpty*`, `wave`, `skip`). Where the app's own translation exists in its `.arb` files, it is lifted from there, as was done for intents.

### Left out

- The extra-matches coin button. It is dormant in production, where boosts are off.
- Push-notification priming.
- Interstitial ads.
- Any backend change.

## Testing (Jest + Testing Library)

- **Slice:**
  - `getDailyMatches` requests `GET /api/v1/matching/daily`;
  - `skipUser` posts `{ targetUserId }` to `/api/v1/interactions/skip`.
- **Tab:**
  - a signed-in `/communities` with no tab lands on Today;
  - `?tab=all` still lands on All;
  - a 404 hides the tab and falls back to All;
  - signed out, there is no Today tab;
  - filters, search, sort and the carousel are absent on Today.
- **Header:** the count follows skips; the refresh time is rendered from `nextRefreshAt`; the fallback text appears when it is missing.
- **Card:**
  - every reason code maps to its chip, `shared_topic` uses the topic label, an unknown code renders nothing;
  - the photo URL rule works for absolute and relative paths;
  - the active dot, "Replies fast" (0.7 boundary) and "Boosted" each appear when they should;
  - Say hi links to `/chat/<id>`, Wave opens the sheet, and Skip removes the card and posts the skip;
  - a failed skip keeps the card gone.
- **Empty state** after the last skip, with Browse partners switching to All.
- **Rollover** refetches once after `nextRefreshAt`.
- **Locale parity** for `communityMain.today.*`.
- **URL state:**
  - `communityUrlState` round-trips with `today` as the left-out default and `all` written explicitly;
  - its existing tests that assumed `all` is left out are updated.
- **Feature off:** a bare `/communities` shows All while the address bar keeps no `tab`, and `?tab=today` likewise. The Today button is hidden.
- **Old filtered links:** `/communities?native=ko` (no `tab`) lands on **All** and keeps its params. So do `?q=anna` and `?sort=recently_active`.
- **Today writes no filter params.**
- **Skips:** a skipped card stays gone after a remount within the same batch `date`, and comes back once the `date` changes.
- **Existing suites stay green.**
  - `communityPerf.test.tsx` is **reworked, not just re-counted**. Almost every test there renders a bare `/communities` and asserts on the All grid (cards, `/auth/users?` requests, visitors, paging, search). Those tests switch to `?tab=all`, and a new one pins the Today default's mount budget.
  - `MainCommunityTabs.test.tsx` and `MainCommunityUrlState.test.tsx` get the same treatment wherever they relied on bare-URL = All.
