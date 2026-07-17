# Profile Modernization (Web) — Design Spec

**Date:** 2026-07-18
**Status:** Design spec (approved in brainstorming: fold into program as an adjacent slice; pending written-spec review → implementation plan).
**Relationship:** Adjacent to Package 1a; pulls the UI-modernization portion of roadmap **Package 4 — Profile** forward. Data-backed feature work (needs new backend fields) stays in Package 4. Runs in parallel with 1a (barely touches auth files). **Design system: Tailwind** (user decision 2026-07-18).

## Goal

Make the logged-in user's own profile **modern, cohesive, and optimized**, matching the visual language already established by `EditProfile.tsx`, without inventing backend features. Kill the "two different apps" split between the dated view and the modern editor.

## Current state (verified via 2026-07-18 audit)

- **View:** `src/components/profile/Profile.tsx` — **707 lines**, react-bootstrap (`Card/Row/Col/Badge/Spinner`) + `Profile.scss` (538 lines), `via.placeholder.com` avatar fallback, inline `style={{}}`, section-by-section inline editing. Defines `StatsCard`, `ProfileSection`, `PersonalInfoForm`, `PersonalInfoView`, `LanguagesForm` inline. Dated.
- **Editor:** `src/components/profile/EditProfile.tsx` — **640 lines**, **Tailwind, modern** (teal gradient header, `rounded-2xl` glass cards, lucide icons, sticky save bar, `hasChanges` dirty-tracking, per-action loading). Already collects MBTI (16-type grid), blood type, topics (20 chips, max 10). Reference for the target look.
- **Type drift:** `src/components/profile/ProfileTypes/types.ts` (shared interface) does NOT include `mbti`/`bloodType`/`topics`; `EditProfile` duplicates its own local `UserProfileData`.
- **Dual edit paths:** inline editing inside `Profile.tsx` AND the separate `/profile/edit` page overlap and can diverge.
- **Data:** both fetch `useGetUserProfileQuery` (`GET /auth/me`), mutate via `useUpdateUserInfoMutation` (`PUT /auth/updatedetails`), `useUploadUserPhotoMutation`, `useDeleteUserPhotoMutation`. `Profile.tsx` also uses followers/following/vip/visitors/moments queries.
- Supporting components already exist: `MyMoments.tsx`, `UserFollowers.tsx`, `UserFollowing.tsx`, `UserVisitors.tsx`, `ImageViewer/`, `ImageUploader/`.

## Scope

### In scope (this spec — UI modernization, no new backend fields)
1. **Rebuild `Profile.tsx` view in Tailwind** to match `EditProfile`'s design language: gradient header/banner, avatar with online-dot placeholder, `@username`, a modern stats row (followers/following/moments/visitors with the existing VIP gate), and a **tabbed** body (Overview / Moments / About) instead of stacked inline sections.
2. **Surface existing-but-hidden data:** display **MBTI, blood type, topics/interests** in the view (the editor already saves them; the view never shows them).
3. **Kill type drift:** extend the shared `ProfileTypes/types.ts` to include `mbti`, `bloodType`, `topics` (and `languageLevel`, `location`, `isOnline`, `lastActive` as optional forward-compat fields); make `EditProfile` consume the shared type instead of its local duplicate.
4. **Decompose the monoliths:** extract from `Profile.tsx` (707) and `EditProfile.tsx` (640) into focused components under `src/components/profile/parts/` — e.g. `ProfileHeader`, `StatsRow`, `AboutCard`, `LanguagesCard`, `PersonalityCard` (MBTI/blood), `TopicsCard`, `PhotoGrid`. Each < ~150 lines, one responsibility.
5. **Reconcile the dual edit paths:** the view's inline editing is removed; "Edit" routes to `/profile/edit` (single source of truth for editing). The view becomes read-only + navigation.
6. **Quick polish:** replace the `via.placeholder.com` avatar fallback with a local/gradient initials placeholder; add loading skeletons; ensure mobile responsiveness with Tailwind breakpoints; lucide icons throughout.
7. **Moments tab (display-only):** surface the user's moments inside the profile via the existing `MyMoments` data, as an in-profile tab (not a separate route jump).

### Out of scope (deferred to Package 4 — need backend fields/logic)
- **Language level / CEFR proficiency** display (field exists as `languageLevel`; wiring the selector into the profile is Package 4 — though the type is added now for forward-compat).
- **Response rate** metric (no backend field).
- **Last active / online-status indicator** as *live* data (no presence wiring here; we add the type + a placeholder dot, but real presence is Package 2/4).
- **Location** display beyond what `GET /auth/me` already returns.
- **Profile theme / wallpaper** selection.
- Any backend changes. This spec is web-only UI.

## Design

### Component structure (target)
```
src/components/profile/
  Profile.tsx              (orchestrator: fetch + tabs + compose parts; ~150 lines)
  EditProfile.tsx          (uses shared type + extracted parts)
  ProfileTypes/types.ts    (single shared interface, extended)
  parts/
    ProfileHeader.tsx      (banner + avatar + username + edit button)
    StatsRow.tsx           (followers/following/moments/visitors, VIP gate)
    AboutCard.tsx          (bio + gender + birthday + location)
    LanguagesCard.tsx      (native + learning [+ level when Pkg4])
    PersonalityCard.tsx    (MBTI + blood type)
    TopicsCard.tsx         (interest chips)
    PhotoGrid.tsx          (shared by view [read] + edit [add/delete])
    ProfileTabs.tsx        (Overview / Moments / About)
```
Files that change together live together under `parts/`. `PhotoGrid` is shared so view and edit can't diverge.

### Visual language (match `EditProfile`)
- Container: `bg-white/80 backdrop-blur-xl rounded-2xl shadow` cards on the `from-teal-50 via-sky-50 to-purple-50` app background.
- Header: teal gradient (`from-[#00BFA5] to-[#00A896]`).
- Icons: `lucide-react` (already a dependency where `EditProfile` uses it).
- Chips/badges: rounded-full teal-tinted for topics; grid for MBTI.
- Responsive: single column on mobile, 2-col cards on `md:`+.

### Data flow
No new queries. Reuse `useGetUserProfileQuery`. The extended shared type maps 1:1 to what `GET /auth/me` returns (mbti/bloodType/topics already persisted by the editor). Tabs are client-side state; Moments tab reuses the existing `MyMoments` query.

## Testing
- Unit (RTL): each extracted part renders its props (e.g. `PersonalityCard` shows MBTI + blood; `TopicsCard` renders chips; `StatsRow` shows counts + VIP gate; avatar falls back to initials, never `via.placeholder.com`).
- Type: `npx tsc --noEmit` — `EditProfile` and `Profile` both compile against the single shared `ProfileTypes/types.ts` (proves type-drift fix).
- Build: `react-scripts build` succeeds.
- Manual: view renders MBTI/blood/topics for a user who set them in the editor; edit still saves; mobile layout holds.

## Open items for the implementation plan
1. Confirm `GET /auth/me` returns `mbti`, `bloodType`, `topics` in its payload (backend `USER_PUBLIC_FIELDS` includes them — verify the `/me` handler does too).
2. Decide the initials/gradient avatar fallback util (new small `src/components/profile/parts/AvatarFallback.tsx`).
3. Confirm `lucide-react` is installed (used by `EditProfile`); if not, add it.
4. Tabs: URL-synced (`/profile?tab=moments`) vs local state — recommend local state for simplicity now.
