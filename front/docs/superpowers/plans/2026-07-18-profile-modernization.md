# Profile Modernization (Pkg4 UI slice) — Implementation Plan

Spec: `docs/superpowers/specs/2026-07-18-profile-modernization-design.md`
Branch: `feat/profile-modernization`. Execute via subagent-driven-development, low-risk-first, SERIAL committers (one worktree).
Tailwind only, no new `.scss`. Reference look = `EditProfile.tsx` (teal gradient header, `rounded-2xl` glass cards, lucide icons, sticky save bar).
Web-only UI modernization — NO backend changes, NO new backend fields. Verify each task:
`CI=true npx react-scripts test src/components/profile --watchAll=false` + `CI=false react-scripts build`. Never `tsc --noEmit`.
Commit locally per task; do NOT push. After each shared/monolith edit, verify `git show --stat` scope.

## Current state (from spec audit)
- `Profile.tsx` (707L, react-bootstrap + `Profile.scss` 538L, inline editing, dated) — the view to rebuild.
- `EditProfile.tsx` (640L, Tailwind, modern; already collects MBTI/blood/topics) — the reference; consumes a LOCAL `UserProfileData` duplicate.
- `ProfileTypes/types.ts` (33L shared interface) — MISSING `mbti`/`bloodType`/`topics`.
- Data: `useGetUserProfileQuery` (GET /auth/me), `useUpdateUserInfoMutation` (PUT /auth/updatedetails), photo upload/delete hooks; plus followers/following/vip/visitors/moments queries.
- Existing supporting components: `MyMoments`, `UserFollowers/Following/Visitors`, `ImageViewer/`, `ImageUploader/`.

## Phase A — Foundation (isolated, low-risk)

### Task 1 — Extend shared profile type; de-duplicate EditProfile
`src/components/profile/ProfileTypes/types.ts`: extend the shared interface with `mbti?: string`, `bloodType?: string`, `topics?: string[]`, plus forward-compat optionals `languageLevel?: string`, `location?: any`, `isOnline?: boolean`, `lastActive?: string`. Make `EditProfile.tsx` consume the shared type instead of its local `UserProfileData` duplicate (keep behavior identical). No visual change. Isolated (2 files). Verify build + existing tests.

## Phase B — Isolated presentational parts (build in `src/components/profile/parts/`, no wiring yet)
Each is a pure display component taking props; Tailwind; dark-mode aware; lucide icons; each < ~150 lines; co-located RTL test. Build SERIALLY (one committer). These do NOT touch Profile.tsx/EditProfile.tsx.

### Task 2 — PersonalityCard + TopicsCard
`parts/PersonalityCard.tsx` (`{ mbti?, bloodType? }` → labeled cards; renders null when both empty). `parts/TopicsCard.tsx` (`{ topics?: string[] }` → interest chips; null when empty). Tests.

### Task 3 — AboutCard + LanguagesCard
`parts/AboutCard.tsx` (`{ bio?, gender?, birthday?, location? }`). `parts/LanguagesCard.tsx` (`{ native?, learning?, level? }` — level slot optional, forward-compat). Tests.

### Task 4 — ProfileHeader + StatsRow
`parts/ProfileHeader.tsx` (banner + avatar w/ gradient-initials fallback [replace `via.placeholder.com`] + `@username` + online dot placeholder + Edit button → `/profile/edit`). `parts/StatsRow.tsx` (followers/following/moments/visitors counts, existing VIP gate behavior via props). Tests.

### Task 5 — PhotoGrid (shared read/edit) + ProfileTabs
`parts/PhotoGrid.tsx` (`{ images, mode: 'view'|'edit', onAdd?, onDelete? }` — shared by view [read] and edit [add/delete] so they can't diverge; reuse existing ImageUploader/ImageViewer where sensible). `parts/ProfileTabs.tsx` (segmented Overview / Moments / About). Tests.

## Phase C — Compose (touches the monoliths — SMALL surgical wiring)

### Task 6 — Rebuild Profile.tsx view in Tailwind
Rewrite `Profile.tsx` as a ~150-line orchestrator: fetch (unchanged hooks) → `ProfileHeader` + `StatsRow` + `ProfileTabs` with Overview (`AboutCard`/`LanguagesCard`/`PersonalityCard`/`TopicsCard`), Moments (existing `MyMoments` data, in-tab), About. **Surface MBTI/blood/topics** (editor saves them, view never showed them). **Remove inline editing** — the view is read-only + navigation; Edit routes to `/profile/edit` (single edit source). Loading skeletons. Remove `Profile.scss` usage (delete the file if fully unreferenced after). Keep the route working. This is the biggest task — smallest possible edits that achieve the rebuild; do NOT change data hooks.

### Task 7 — EditProfile reuse of shared parts (cleanup)
Refactor `EditProfile.tsx` to reuse `PhotoGrid` (edit mode) and, where clean, `PersonalityCard`/`TopicsCard` edit affordances — reduce the view/edit duplication. Keep all existing edit behavior (dirty-tracking, per-action loading, save). Minimal, behavior-preserving.

## Phase D — Polish

### Task 8 — Responsive + skeleton + a11y pass
Tailwind breakpoints for mobile; consistent lucide icons; loading skeletons on the view; gradient-initials avatar fallback everywhere; ensure no `via.placeholder.com` remains. Full `src/components/profile` tests + build green.

## Out of scope (deferred to full Pkg4 — need backend)
CEFR language-level display wiring, response-rate metric, LIVE presence/last-active, location beyond `/auth/me`, profile theme/wallpaper. (Types added now for forward-compat only.)

## Notes
- SERIAL committers (a parallel git-index race bit Pkg3 — avoid).
- `PublicProfile.tsx` exists (public view) — out of scope unless a shared part trivially benefits it; don't refactor it here.
- Checkpoint with user after Phase B (all isolated parts built) before the Task 6 monolith rebuild.
