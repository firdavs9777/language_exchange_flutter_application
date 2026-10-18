# Community completion

**Date:** 2026-10-08
**Status:** Approved in conversation; written for review
**Scope:** Sub-project 1 of 2 ("complete filters, no bugs in community"). Sub-project 2, Moments, has its own spec.
**Repos:** `language_exchange_web_front` (web) and `language_exchange_backend_application` (backend, serving the production app).

---

## Where this starts

Already shipped today (2026-10-08), and not repeated here:

- The New tab sends `joinedWithin=7d`; it used to send `newUsersOnly`, which the server never read.
- Two explicit language filters are ANDed rather than ORed.
- Language filters match every stored spelling (`equivalentValues`).
- Country is a localized list that matches exactly, endonyms included.
- A minimum age no longer admits blank birth years.
- The default match reads the account's current languages from `/auth/me`.
- Member cards have one shape; the highlighted carousel sits above the grid.

The audit found three remaining defects. This spec fixes those three and nothing else.

## 1. Search finds everyone

### Problem

`buildUsersQuery` (backend `controllers/users.js`) ANDs a plain search with the language `$or`. Both clients send the viewer's own languages as the default exchange match (`matchLanguage=true`, `nativeLanguage=<mine>`, `learningLanguage=<mine>`), so typing a name only finds that person if they sit inside the viewer's language pairing. Search a friend who speaks a third language, and they do not exist.

### Decision

A plain search ignores the **default** language match, so that it searches everyone. Filters the member chose themselves still apply. The user chose to apply this to the app as well, which needs no client change.

The server cannot see whether the language params were typed by the member or filled in as the default. It tells them apart by comparing them with the viewer's own languages:

- **Default match.** The params are *exactly* what the default sends. All of the following hold:
  - `matchLanguage === 'true'`.
  - `nativeLanguage` is present **if and only if** `req.user.native_language` is set, and when present it equals it.
  - `learningLanguage` is present **if and only if** `req.user.language_to_learn` is set, and when present it equals it.
  - At least one of the two is present.

  "If and only if" is load-bearing. One explicit filter is sent as `matchLanguage=true` with a **single** swapped param (`buildCommunityQuery.ts`). "Native speakers of Korean", from someone learning Korean, sends `learningLanguage=Korean` alone. A looser "absent or equal" rule would mistake that for the default and drop the most common filter of all during a search. Because the viewer has a native language, the default would also have sent `nativeLanguage`; its absence is what marks the request as explicit.

- **Set** means a non-empty string after trimming. An empty or whitespace-only `native_language` / `language_to_learn` counts as unset. That is the same reading `buildUsersQuery`'s own `if (nativeLanguage)` gives a param, so both sides of the comparison agree.
- **The web, before `/auth/me` answers.** Until then the page may still send the languages saved at login. If those differ from `req.user`, the request counts as explicit and the search stays narrowed — today's behaviour, and safe. It corrects itself once `/auth/me` answers. This is expected, not a bug.
- **Equal** means the same `matchKey` (`lib/matchLanguage.js`). `matchKey` returns `null` for values it does not recognise — American Sign Language, Hawaiian and Dari are real production values — so two `null` keys are **not** equal. In that case the values are compared as trimmed, case-insensitive strings, the same fallback `equivalentValues` uses.
- **Search-everyone condition.** `search` is non-empty, does not start with `@` (the `@username` branch already clears language filters), and `req.user` exists.

When both hold, the language `$or` is not applied. Every other filter still applies:

- age, gender, country, level, topics, online and `joinedWithin`;
- `reciprocal=true`. The app's "perfect partners" surface asks for it explicitly, and it is not the default match.

Accepted edge case: a member who sets *both* language filters to mirror their own two languages.

- **On the web,** that request takes the direct (AND) branch without `matchLanguage`, so it never reaches this rule.
- **On the app,** both filters are still sent with `matchLanguage=true`, and the request is byte-identical to the default. The server cannot tell the two apart, so it treats it as the default and drops the language match during a search. This is accepted: the request asked for exactly the viewer's own exchange pairing.

### Kill switch

`process.env.COMMUNITY_SEARCH_EVERYONE`. Default on; the value `'false'` restores today's behaviour after a restart, with no deploy needed. It is read per request, not at module load (the same lesson as `9a88c4b`, "read flags per tick").

### Touches

- Backend: `controllers/users.js` `buildUsersQuery`. `GET /auth/users/count` shares the builder, so the filter sheet's live count changes with it.
- Web: nothing.

## 2. Paging follows the server

### Problem

`MainCommunity.tsx:573` infers `hasMore` from `data.length === PAGE_LIMIT`. When the last page is exactly full, the page shows a "load more", fires one extra request, and gets an empty page back. `GET /auth/users` already returns `total` and `pages`.

### Decision

- `hasMore` is `page < pages` whenever `pages` is a number on the response.
- If `pages` is missing (a cached older response, or another endpoint feeding the list), fall back to today's full-page rule.
- `getCommunityMembers`' `transformResponse` already spreads the response, so `pages` passes through untouched.

### Touches

Web only: `MainCommunity.tsx`.

## 3. Match reasons in the reader's language

### Problem

The **For you** tab (`GET /matching/recommendations`) renders `matchReasons`. These are English sentences built in `controllers/matching.js` `getMatchReasons`:

- `Speaks <native>, learning <learning>`
- `Native <native> speaker`
- `Online now`
- `Active today`
- `Same country`

They reach the card as-is in all 18 locales.

### Decision

**Backend.** `getMatchReasons` is split into:

- `matchReasonCodes(currentUser, matchedUser)`. It keeps today's conditions exactly, quirks included. `same_country` is emitted when `matchedUser.location?.country === currentUser.location?.country`, which is also true when **both are undefined**. Changing that would break the byte-identical strings. It returns structured entries:
  - `{ code: 'perfect_pair', native, learning }`
  - `{ code: 'native_speaker', native }`
  - `{ code: 'online_now' }`
  - `{ code: 'active_today' }`
  - `{ code: 'same_country' }`
- An English renderer that turns those codes into the **exact** strings produced today.

Each recommendation then carries both:

- `matchReasons` — unchanged, byte-identical, still what shipped app builds read.
- `matchReasonCodes` — new.

The aggregation's own `matchReasons` projection (`'Perfect language exchange partner'`, `'Recently active'`) is overwritten by `getMatchReasons` today, as the code's own comment says. That stays as it is.

**Web.**

- New keys `communityMain.reasons.{perfect_pair,native_speaker,online_now,active_today,same_country}` in all 18 locales, interpolating `{{native}}` and `{{learning}}`.
- **Rendering the chips.** When `matchReasonCodes` is present, `MainCommunity` turns each code into a chip entry `{ text, primary }`:
  - `text` is the localized string for that code;
  - `primary` is true exactly for `perfect_pair` and `native_speaker`.
- **Fallback.** When `matchReasonCodes` is absent (an older server or cache), it passes the English `matchReasons` strings, as today.
- **`MemberCard.reasons`** accepts either form:
  - plain strings keep today's English test (`isLanguageReason`, `/^Speaks |^Native /`) to decide which chip is primary — that test cannot work on Korean or Japanese text, which is why entries carry the flag;
  - entries are taken as given, primary first.
- `areMemberRowsEqual` compares entries by `text` and `primary`.
- Language names in the parameters are shown as stored — the same rule the card's own language row uses.

**Rollout.** `/recommendations` responses are cached per viewer (`recommendations:${userId}`). Until each entry expires, it is still served without `matchReasonCodes`, and those cards show the English fallback. That is expected, not a bug.

### Touches

- Backend: `controllers/matching.js`.
- Web:
  - `MainCommunity.tsx`: For You turns codes into chip entries;
  - `MemberCard.tsx`: the `reasons` prop accepts `string[] | {text, primary}[]`, the render reads `primary`, and `areMemberRowsEqual` changes;
  - 18 locale files. The `communityMain` namespace is already parity-guarded.

## Production safety (backend)

This backend serves the production app. Every change here follows these rules:

1. **Additive only.** No field is renamed or removed and no response shape changes. `matchReasonCodes` is a new field; `matchReasons` stays byte-identical.
2. **Same request, same answer.** A request without a search keeps exactly today's query. A test pins this.
3. **One behaviour change, behind a switch.** Search-everyone (section 1) is the only behaviour the app will notice. It sits behind `COMMUNITY_SEARCH_EVERYONE`.
4. **No migrations, no new indexes.**
5. **One merge per change.** Sections 1 and 3 ship as separate backend merges, so either can be reverted alone.
6. **Before every backend push:**
   - the full suite on Node 24;
   - `npm ci --omit=dev --dry-run` under npm 9.2.0, the droplet's version that broke today's deploy.
7. **After every backend push:**
   - the deploy log shows `npm ci succeeded` and PM2 `online`;
   - a live request against `api.banatalk.com` answers 200.

## Testing

Backend, with Node tests against an in-memory MongoDB, following `test/communityFilterMatching.test.js`:

- **Search-everyone, positive:** a default-match request plus a name search returns a user outside the viewer's languages.
- **Explicit filter still applies:**
  - an explicit language filter different from the viewer's own, plus a search, keeps the language constraint;
  - so does a single explicit filter **equal to the viewer's own learning language** ("native Korean" from a Korean learner), which a looser rule would mistake for the default.
- **Unrecognised languages:** two different unrecognised languages (both `matchKey` null) are not treated as equal.
- **Reciprocal:** `reciprocal=true` plus a search keeps the reciprocal constraint.
- **No search, no change:** without `search`, the result set is identical to today's.
- **`@username` unchanged.**
- **Kill switch:** with `COMMUNITY_SEARCH_EVERYONE=false`, today's narrowing returns. The env var is set inside the test, which proves it is read per request.
- **Count matches list:** `/count` agrees with the list for the same query.
- **Match reasons:**
  - `matchReasons` strings are unchanged for each reason type, pinned literally;
  - `matchReasonCodes` carries the expected code and parameters;
  - both arrays have the same length and order.

Web, with Jest:

- **Paging:** `hasMore` is false on an exactly-full last page when `pages` says so, and falls back when `pages` is absent.
- **Reason chips:** For You chips render the localized key when codes are present and the English string when they are not; language-first ordering holds with codes.
- **Locale parity** for the new keys.

## Out of scope

- The `smart` sort on web. The web cannot tell whether `SMART_SORT_ENABLED` is on, and the server falls back silently when it is off.
- Reason codes on `/daily` and `/quick`. They already return structured codes (`lib/dailyMatches.js`), and the web does not render them.
- Anything in Moments. That is sub-project 2.
