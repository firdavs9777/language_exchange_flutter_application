# Community Discovery Parity (Web) — Design Spec

**Date:** 2026-07-18
**Status:** Design spec (autonomous build per user's pre-confirmation). Pulls forward the **discovery** half of roadmap Package 4.
**Design system:** Tailwind (project standard, 2026-07-18). Reference look: `EditProfile.tsx` + the 1a wizard.

## Goal

Bring the web **Community / people-discovery** experience to parity with the Flutter app's Tandem-style browser, matched exactly to the backend contract. Mobile is source of truth. Verified against real app + backend code (paths below).

## Current web state (verified)

Routed: `src/components/community/MainCommunity.tsx` (369 lines, component `ModernCommunity`) is the list; `tandem/` subcomponents (`CommunitySubNav`, `CommunityFilterSheet`, `TandemMemberCard`, `LanguageFlagChip`, etc.); `CommunityDetail.tsx` (716, detail); `NearbyUsers.tsx`, `Topics.tsx`, `Waves.tsx`. Data via `src/store/slices/communitySlice.ts` (`useGetCommunityMembersQuery` → `GET /api/v1/auth/users`). Styling: hand-written `tandem-community.scss` + inline styles + lucide icons (NOT Tailwind).

### Confirmed bugs (filters don't reach the DB)
1. **Age filter broken** — UI sends `ageMin`/`ageMax`; backend reads `minAge`/`maxAge`. Ignored server-side, no client fallback.
2. **Language filter is client-only** — UI sends `language=`; backend wants `nativeLanguage`/`learningLanguage`/`matchLanguage`. Filtering happens in JS over loaded pages only.
3. **Search is client-only** — backend `search` param never sent.
4. **Online-only / New-only are client-only toggles** — backend supports `onlineOnly` natively.
5. **VIP badge never shows** — card reads `isVIP`, backend returns nested `vipSubscription.isActive`; no `transformResponse`.

## Backend contract (verified, READ-ONLY — do not modify backend in this package unless a task explicitly says so)

`GET /api/v1/auth/users` (`controllers/users.js buildUsersQuery`/`getUsers`, `protect`): params `page, limit, nativeLanguage, learningLanguage, matchLanguage, gender, minAge (>18 only), maxAge (<100 only), onlineOnly, country, languageLevel, topics (csv), topicsAtLeast, search, sort`. Sort: `recently_active` else default (VIP→online→lastActive). Returns `USER_LIST_FIELDS` (name, username, images, native_language, language_to_learn, level, **languageLevel**, userMode, location, followers/following, isOnline, lastActive, gender, birth_*, bio, occupation, school, `vipSubscription.isActive`, topics, createdAt) + computed `imageUrls, followersCount, followingCount, hasActiveStory`. Response `{success, count, total, pages, data}`.

`GET /api/v1/auth/users/count` → `{success, data:{count}}` (same filters) — powers the live match count.

**CRITICAL — inverted language semantics (from app `partner_discovery_tab._buildFilterParams`):** the API `nativeLanguage` param finds users **learning** that language; API `learningLanguage` finds users who **speak** it natively. So a UI "I want a partner whose native language is X" maps to API `learningLanguage=X`; UI "who is learning Y" maps to API `nativeLanguage=Y`. When the user sets NO language filter, default to `matchLanguage=true` (+ the current user's own native/learning) for exchange matching. This mapping MUST be centralized and unit-tested.

Community endpoints (`/api/v1/community`, `protect`):
- Waves — **real routes** are `POST /community/wave` (`{targetUserId, message?}` → `{waveId, isMutual, message}`), `GET /community/waves` (`page, limit, unreadOnly, archive` → `{data:{waves, unreadCount}}`), `PUT /community/waves/read` (`{waveIds?}`). NOTE: the web `communitySlice` currently points at non-existent `/wave/received`, `/wave/sent`, `/wave/:id/respond` — these MUST be reconciled to the real routes above.
- Topics — `GET /community/topics` (`category, lang` → `{data:[{id,name,icon,category,color,userCount}]}`), `GET /community/topics/:topicId/users` (`page,limit`), `PUT /community/topics/my` (`{topics}`).
- Nearby — `GET /community/nearby` (`latitude,longitude,radius,...` → items with `distance`). Gated by `checkNearbyAccess`.

## App UX (source of truth — verified)

Main list card `PartnerListItem` (`lib/widgets/community/partner_list_item.dart`): avatar (72, rounded-22) with **online dot** (privacy-gated), **country/native-language flag** overlay, **story ring** if `hasActiveStory`; name + `, age` (privacy-gated) + **NEW** (≤6d) + **VIP** badges; language-exchange row (native flag → arrow → learning flag) + **CEFR badge** (`languageLevel`); location row (city/country, privacy-aware); 1-line bio; up to **3 contextual tag chips** ranked: active-now/last-active → responsiveness (`responseRate` ≥80 "Very responsive", ≥50 "Quick to reply") → shared ("Both like {topic}"/"Speaks X"/"Learning X") → **MBTI** → "Joined Xd ago"; teal gradient **wave button** (right).

Filter sheet `FilterState`: `minAge(18), maxAge(100), gender, nativeLanguage, learningLanguage, country, topics[], languageLevel, onlineOnly, newUsersOnly, prioritizeNearby, topicsAtLeast`. Sections: Age range slider, Gender chips, Languages (native+learning), Country picker, **CEFR level chips (Any/A1..C2)**, Topics multi-select, Toggles (online now / new only / prioritize nearby) + **mutual-interests slider**. Header shows a **live debounced match count** (`GET auth/users/count`). Free for all; persisted to storage. Active-filter chip row with per-chip remove + Clear.

Quick chips in the list: **Recently Active** (sort), **Online Now**, **Speaks {my learning}**, **Learning {my native}**. List always client-sorted VIP-first then online-first. View modes: **List** vs **Quick Match** (swipe).

Tabs: All, Gender, Nearby, City(map), Topics, Voice Rooms, Waves, Rooms.

Waves: send sheet (emoji quick-replies + icebreaker chips + custom message), one-wave-per-pair-ever (backend `ALREADY_WAVED`), received inbox with unread badge.

## Scope

### In scope (this package — core discovery parity, Tailwind, front repo only)
1. **Centralized, unit-tested query-param mapper** `buildCommunityQuery(filters, me)` implementing the inverted native/learning semantics + `matchLanguage` default + age(minAge/maxAge)/gender/onlineOnly/country/languageLevel/topics/topicsAtLeast/search/sort/page/limit. This fixes bugs #1–#4 at the source.
2. **Server-side filtering**: wire search, language, age, online, country, level, topics through the mapper so they hit the DB (not JS over loaded pages).
3. **VIP badge fix** (#5): `transformResponse` (or selector) mapping `vipSubscription.isActive`→`isVIP`, and surface `languageLevel`, `location`, `lastActive`, `hasActiveStory`, `responseRate` (if present), `mbti` to the card model.
4. **Member card rebuild (Tailwind)** to `PartnerListItem` parity: avatar + online dot + story ring + flag overlay + NEW/VIP badges + native→learning + CEFR badge + location + age + bio + up-to-3 contextual tag chips + wave button.
5. **Filter sheet rebuild (Tailwind)** to full `FilterState` parity + **live match count** via a new `useGetCommunityCountQuery` (`GET /auth/users/count`) + active-filter chips + localStorage persistence (key `community_filters`).
6. **Quick chips** (Recently Active, Online Now, Speaks/Learning) driving the mapper.
7. **Waves** reconciled to the REAL backend routes: send sheet (emoji + icebreaker + custom), received inbox + unread badge; fix `communitySlice` wave endpoints to `POST /community/wave`, `GET /community/waves`, `PUT /community/waves/read`; handle `ALREADY_WAVED`.
8. **Pagination** preserved (page/limit + Load more), keep scroll restore.
9. **Cleanup**: remove dead `SingleCommunity.tsx`, `MemberCard.tsx`, `CommunityFilter.tsx` stub, `MainCommunity.css` if unreferenced (verify first).

### Secondary (include only if the plan stays tractable; else defer)
- **Gender tab** (Male/Female toggle + photo grid) — thin variant of the list.
- **Topics tab** polish (already exists as `Topics.tsx`).

### Out of scope (defer)
- **Nearby (GPS radius)** and **City map** — need browser geolocation / map lib; nice-to-have.
- **Voice Rooms / Rooms** tabs — separate LiveKit/rooms subsystems (Voice Rooms deep-link to app per roadmap).
- **Quick-Match swipe** view mode — defer (list view is core).
- Any backend changes (the backend already supports everything needed; only the web sends the wrong params).

## Web design

- `communitySlice.ts`: add `getCommunityCount` query; fix wave endpoints; add `transformResponse` to normalize member fields (VIP, level, etc.). Keep `getCommunityMembers`.
- New `src/components/community/lib/buildCommunityQuery.ts` (pure, unit-tested) — the param mapper (the highest-value, most bug-prone unit).
- Rebuild under `src/components/community/` in Tailwind, decomposing the large files:
  - `MemberCard.tsx` (Tailwind, PartnerListItem parity) — replaces `TandemMemberCard`.
  - `CommunityFilterSheet.tsx` (Tailwind, full FilterState + match count + chips + persistence).
  - `ActiveFilterChips.tsx`, `QuickFilterChips.tsx`.
  - `WaveSheet.tsx` (send) + `WavesInbox.tsx` (received) + unread badge.
  - `MainCommunity.tsx` slims to orchestration (fetch via mapper, list, pagination, tabs).
- Keep `lucide-react` icons. Match teal `#00BFA5`→`#00ACC1`, gold VIP gradient, green online dots, `rounded-full` pill chips.

## Testing
- Unit (Jest/RTL): `buildCommunityQuery` (inverted semantics, matchLanguage default, age→minAge/maxAge, onlineOnly, level/country/topics/topicsAtLeast, search, sort, empty-filter default) — the critical one; MemberCard renders each field/badge from a fixture (VIP shows, CEFR badge, online dot, NEW); filter sheet emits correct FilterState; wave endpoint shapes.
- Build gate: `CI=false npx react-scripts build` (NOT `tsc --noEmit` — broken repo-wide). Manual: filter by language/age/online and confirm results change server-side (count updates); send a wave; verify VIP badge appears.

## Open items for the plan
1. Confirm `responseRate` / `mbti` presence in `USER_LIST_FIELDS` — the card must degrade gracefully if absent (backend `USER_LIST_FIELDS` does NOT include `responseRate` or `mbti`; so those chips only render when present — likely absent in list payload → omit those two chip types unless a backend field is added later, which is out of scope).
2. Confirm the current user's own native/learning languages are available client-side (from auth `userInfo`) to build the `matchLanguage` default and the "Speaks/Learning" quick chips.
3. localStorage key + shape for persisted filters (mirror app's `community_filters`).
