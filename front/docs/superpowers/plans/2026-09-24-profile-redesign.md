# Profile Redesign Implementation Plan

> **For agentic workers:** execute task-by-task with a fresh implementer per task and a review after each. Steps use `- [ ]`.

**Goal:** one professional profile experience for both the signed-in user (`/profile`) and any other user (`/profile/:userId`), built on the existing type system and `src/design/` primitives, fully localized, showing everything the backend already knows (languages with levels, bio, occupation, school, topics, MBTI, VIP and verified badges, streak/XP, followers, moments), with the social actions wired (follow, message, block, report) and the lists (followers, following, visitors) restyled to match.

**Input:** `.superpowers/sdd/profile-inventory.md` (routes, files, endpoints, Bootstrap remnants, backend fields; read it first — it is the map). Design language: `src/index.css` type system, `ink` scale, brand/banana tones, `src/design/{Badge,SurfaceCard,LanguageExchangePill}.tsx`, the already-modern `src/components/profile/parts/*` (2026-07-18) which set the visual direction; icons only from `lucide-react`.

## Global Constraints

- Repo `/Users/davis/Desktop/Personal/language_exchange_web_front`, branch `feat/profile-redesign` off `main`. **No `Co-Authored-By` trailers. Commit with an explicit pathspec.**
- Tests `CI=true npx react-scripts test --testPathPattern=<pattern>` (foreground). TypeScript 3.7.2 (no `import type`, no `export type {}`; build is the type check). Baseline after Phase B: 126 suites / 1003 tests.
- No `react-bootstrap`, no `bi-*`, no emoji-as-icon, no hex colours, no inline `style={{}}` in any file this plan touches; SCSS/CSS files that only served replaced markup are deleted. Tailwind classes that collide with Bootstrap `!important` utilities (`p-*`, `m-*`, `gap-*`, `d-*`, `text-*`) still work here because Bootstrap loads after Tailwind only for the classes it defines — check the rendered result in the browser smoke, and prefer arbitrary values (`p-[18px]`) where a collision is visible.
- Copy via `t("profile.<area>.<key>") || "English"`; reuse existing keys from the `profile*`/`userProfile*` namespaces listed in the inventory where the string already exists; new keys land in all 18 locales in the final task; `localeParity` NAMESPACES gains `profile`.
- Data: use the RTK endpoints the inventory lists (`src/store/slices/*`) — no new backend work; own vs other is decided by comparing the route param with `state.auth.userInfo._id`; never read `localStorage` during render.
- `/profile/:userId` stays a lazy authenticated route (not prerendered); `/community/:id` keeps using `CommunityDetail.tsx` untouched.

---

### Task P1: profile data hook and header
**Files:** create `src/components/profile/useProfileData.ts` (+test): `useProfileData(userId?: string)` → `{ isOwn, user, stats: { followers, following, moments }, isFollowing, loading, error, refetch }` from the existing endpoints (own: `getMe`/current user + counts; other: `getUserProfile(userId)` + follow state), memoized; create `src/components/profile/parts/ProfileHeader.tsx` (+test): cover band (brand gradient, no image dependency), avatar with fallback initials, name, age (from birth fields if the API returns them, else omitted), location (city/country if present), `Badge` row: **VIP** (`userMode === 'vip'`), **Verified** (email verified flag — read the field name from `USER_PUBLIC_FIELDS`), "Joined <month year>", "Active <relative>" (uses `lastActive`); `ProfileStats.tsx` (+test): three tappable stat tiles Followers / Following / Moments → `/profile/:id/followers`, `/profile/:id/following`, own → `/my-moments`; `ProfileActions.tsx` (+test): own → **Edit profile** (`/profile/edit`) + **Settings**; other → **Message** (opens/creates the chat the way `CommunityDetail.tsx` does today — read it), **Follow/Unfollow** (existing mutation, optimistic), overflow menu with **Block** and **Report** wired to the existing mutations (confirm dialog reused from `src/components/admin/parts/ConfirmDialog.tsx` — move it to `src/design/ConfirmDialog.tsx` and re-export from the admin path).
- [ ] TDD (own vs other branches, badge conditions, follow toggle optimistic + rollback, block/report call the mutations); commit `feat(profile): header, stats and actions on the design system`.

### Task P2: about, languages, learning, moments
**Files:** create `src/components/profile/parts/ProfileLanguages.tsx` (+test): native → learning as `LanguageExchangePill` with the level dots (`dotsForLevel`), plus extra learning languages if the model has them; `ProfileAbout.tsx` (+test): bio (with "Read more" past 240 chars), occupation, school, topics/interests as chips, MBTI and blood type as small facts (only when present — an empty About section is not rendered); `ProfileLearning.tsx` (+test): streak days, total XP, level if `learningStats` is present — hidden otherwise (spec §4.6: no fake numbers); `ProfileMoments.tsx` (+test): grid of the user's moments (image or text tile, like/comment counts) via the existing moments-by-user endpoint, "See all" → `/my-moments` (own) or the user's feed; empty state copy for own ("Share your first moment") vs other ("No moments yet").
- [ ] TDD; commit `feat(profile): languages, about, learning progress and moments sections`.

### Task P3: the page, both routes
**Files:** create `src/components/profile/ProfilePage.tsx` (+test) composing P1/P2 in a two-column layout ≥ 1024px (header full width; left: languages + about + learning; right: moments) and a single column below; loading skeleton (no spinner jump), error state with retry, "user not found" state; modify `src/router/routes.tsx` (`/profile` and `/profile/:userId` both render `ProfilePage`; `/profile/:userId` no longer mounts `CommunityDetail`), `src/components/profile/Profile.tsx` and `PublicProfile.tsx` (become thin wrappers or are deleted — delete if nothing else imports them; update tests), `src/seo/PageMeta`/`RouteMeta` usage for the title ("<name> · BananaTalk", `noindex` — check how other authenticated pages set metadata).
- [ ] TDD (both routes render `ProfilePage`; own vs other decided from store; not-found state); commit `feat(profile): one page for own and public profiles`.

### Task P4: followers, following, visitors
**Files:** create `src/components/profile/UserListPage.tsx` (+test): tabs Followers / Following (and Visitors when own), search-in-list, each row = avatar, name, `LanguageExchangePill`, follow/unfollow button (other people) and a link to their profile; used by `/followersList`, `/followingsList`, `/visitors` (own) and new routes `/profile/:userId/followers`, `/profile/:userId/following`; replace `UserFollowers.tsx`, `UserFollowing.tsx`, `UserVisitors.tsx` (delete them and their SCSS once the routes point at the new page; update `src/lazyIcons.ts` importers — these were the last `bi-*` users, so the icon CSS import may become unused: check and remove if so, then `eagerGraph.test.ts` still passes).
- [ ] TDD; commit `feat(profile): followers, following and visitors on one list page`.

### Task P5: edit profile and my moments
**Files:** `src/components/profile/EditProfile.tsx` and its `parts/` (restyle every remaining Bootstrap/hex/inline-style piece to Tailwind + primitives; keep the form logic and endpoints; sections: Photos, Basics, Languages (with level), About (bio, occupation, school, topics, MBTI, blood type), with a sticky Save bar and unsaved-changes guard), `MyMoments.tsx` (grid consistent with `ProfileMoments`; **wire the delete button to the real `deleteMoment` mutation** with `ConfirmDialog` — it currently only logs), `EditMyMoment.tsx` (restyle), `InfoRow/LanguageView/EditModal/ImageModal` (restyle or fold into the parts), all emoji icons → `lucide-react`.
- [ ] TDD (save calls the mutation with the edited fields; delete moment calls the mutation and removes the tile; unsaved guard); commit `feat(profile): edit profile and my moments on the design system; delete actually deletes`.

### Task P6: locales, verification, merge
- [ ] Inventory every new `profile.*` key → 18 locales via merge script; `localeParity` NAMESPACES += `profile`.
- [ ] Full suite; build; prerender unchanged (10 routes); browser smoke with a mocked signed-in session (see the Phase C admin smoke approach) on `/profile`, `/profile/<other id>`, `/profile/edit`, `/followersList` at 390 and 1280: no console errors, no Bootstrap classes in the rendered profile DOM (`document.querySelectorAll('[class*="btn-"], .card, .row').length === 0` inside the profile root), no emoji glyphs in icon positions; screenshots saved for the report.
- [ ] Merge `feat/profile-redesign` into `main` `--no-ff`; push.

## Not in this plan
New backend fields, profile prerendering/SEO for public profiles, story highlights on the profile (Moments Phase 2), Bootstrap retirement outside the profile files.
