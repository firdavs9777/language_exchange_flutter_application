# Member profile: what the phone shows first

**Date:** 2026-09-30
**Status:** Awaiting review
**Scope:** Piece **C** of the community decomposition. The member profile at `/community/:userId`, on phone viewports. Desktop layout is deliberately untouched.

---

## Why

Asked where checking someone's images and info is awkward, all four answers applied:

1. On a phone it is all behind the *About* tab.
2. The photo set is too small to scan.
3. The info reads poorly — four separate cards.
4. The suggestion strip at the foot now dominates.

Number 4 is a consequence of piece **A**: `MemberCard` became a photo-on-top cell,
and `SuggestedMembers` reuses it, so that strip went from a ~104px row carousel
to a ~400px card carousel. It was parked at the time and is closed here.

### What is already right, and must not be broken

This surface is better built than the two before it, so the spec says plainly
what it is not touching:

- **`ProfilePhotos` already has a correct lightbox** — `role="dialog"`,
  `aria-modal`, Escape to close, arrow keys to step, Tab trapped, focus
  returned to the tile that opened it. Its own comment records that it replaced
  a `PhotoGrid`/`ImageViewer` pair that could do none of that. **The viewer is
  not in scope. Only the tiles that open it are.**
- **On desktop both panels already render side by side** (`lg:block` on both),
  so the tabs only govern phone. Every change here is phone-only.
- **`ProfilePhotos` is deliberately declared twice** —
  `profile-photos-phone` (`lg:hidden`, in the About panel) and
  `profile-photos-desktop` (`hidden lg:block`, in the Moments panel) — because
  a grid child cannot move between columns in CSS, and `display:none` keeps the
  unused one out of the accessibility tree. That duplication stays.

## Decisions

### Rejected: dropping the tabs on phone

The option that reads best in a mockup — one top-to-bottom scroll, no tabs — is
rejected on a technical ground rather than a taste one.

`role="tabpanel"` and `aria-labelledby` live in the markup. A CSS breakpoint
cannot remove them, so "no tabs on phone" requires the component to know the
viewport in JavaScript. This app **prerenders and hydrates**: `npm run build` is
`react-scripts build && node scripts/prerender.js`, and `src/index.tsx` uses
`hydrateRoot` behind a `documentIsPrerendered` flag. A viewport-dependent render
is the classic hydration-mismatch bug.

In fairness: `/community/:userId` is **not** in `SEO_PAGES` — only marketing
routes prerender — so this would not bite today. The hazard is latent, not live.
The decision stands because the gain is one tap and the cost is introducing
viewport-aware rendering into an app that hydrates.

### Chosen

| # | Change |
|---|---|
| 1 | *About* becomes the phone default tab. You land on who someone is, not on their posts. |
| 2 | The photo set moves **above** the tab bar on phone — permanently visible on either tab. |
| 3 | The four info cards become **one** card with headings. |
| 4 | Photo tiles go 3-up → 2-up on phone (~110px → ~165px). |
| 5 | `SuggestedMembers` gets a compact variant, closing piece A's parked finding. |

Changes 1 and 2 are each small. Change 3 is what makes them fit: four separate
cards are precisely what push everything below the fold.

## Design

### The default tab

`ProfilePage.tsx:145` reads `searchParams.get("tab") === "about" ? "about" : "moments"`.
It becomes the inverse: *about* unless the URL says *moments*. A URL carrying
`?tab=moments` still lands on Moments, so existing links keep working.

Desktop is unaffected — both panels are `lg:block` regardless of `tab`.

### Photos above the tabs

`profile-photos-phone` moves out of the About panel to sit directly above the
tab bar, still `lg:hidden`. `profile-photos-desktop` is untouched.

This is a move, not a copy: the phone instance appears once, above the tabs,
rather than inside a panel.

### One info card

The four components keep their own logic and their own files. What changes is
who draws the card around them.

- Each gains a `bare?: boolean` prop. When `bare`, it renders its contents as a
  section — heading plus body — instead of wrapping itself in `SurfaceCard`.
- Each exports a predicate saying whether it has anything to show, derived from
  the same condition its existing early return uses:
  `hasLanguages(user)`, `hasAbout(user)`, `hasLearning(user)`,
  `hasMutualInterests(viewer, user)`.
- `ProfilePage` renders one `SurfaceCard` containing the four in `bare` mode,
  and renders that card **only when at least one predicate is true**.

The predicates exist because a parent cannot ask a child whether it returned
null. Exporting them from the component that owns the rule keeps one source of
truth rather than duplicating the condition in the page.

**On a profile with nothing filled in, no card appears at all** — the behaviour
four independent early-returns give today.

Desktop keeps the same merged card; the left column becomes one card instead of
four, which is an improvement there too and costs nothing.

### Photo tiles

`ProfilePhotos` uses `grid grid-cols-3 gap-2` with `aspect-square`. It becomes
2-up below `sm` and stays 3-up above it. On a ~360px phone that takes a tile
from ~110px to ~165px.

The lightbox, its keyboard handling and its focus management are untouched.

### The suggestion strip

`SuggestedMembers` (`parts/SuggestedMembers.tsx:88-93`) lays out
`w-[min(82%,22rem)]` snap items on phone and `md:grid-cols-2` on desktop, and
renders piece A's `MemberCard` — a photo-on-top cell about 400px tall.

`MemberCard` gains a `compact?: boolean` prop restoring the row shape it had
before piece A: small square avatar left, details right, no full-width photo, no
wave foot. `SuggestedMembers` passes it. The community grid does not, so the
main page is unchanged.

This is the honest fix for what piece A's review parked: the card was redesigned
for a three-column grid, and a horizontal suggestion strip is not that.

## Success

- On a phone, a member's languages and bio are visible without tapping a tab.
- Their photos are visible on both tabs without tapping, at roughly 165px.
- A profile with no languages, no bio, no learning data and no mutual interests
  shows no info card at all.
- The suggestion strip is about the height it was before piece A.
- Desktop renders exactly what it renders today, bar two deliberate changes:
  the four-into-one card, and the suggestion strip, which takes the compact row
  on every width. The strip is a carousel on a phone and a two-column grid on a
  desktop; neither wants a ~400px photo-on-top cell at the foot of a profile,
  so `compact` is passed unconditionally rather than by breakpoint — a
  breakpoint would mean viewport-aware rendering, which this spec rejects
  elsewhere for the same reason.
- The lightbox still opens on click, closes on Escape, steps with the arrow
  keys, traps Tab and restores focus.

## Testing

Follows the existing suites: `ProfilePage.test.tsx`, and the per-part tests
beside each component.

1. The phone default tab is *about*; `?tab=moments` still selects Moments.
2. `profile-photos-phone` renders above the tablist in the DOM order.
3. The merged card renders one `SurfaceCard` containing all four sections.
4. A user with none of the four renders no info card — assert the card is
   absent, not that it is empty.
5. A user with only a bio renders the card with the About section and without
   the other three.
6. Each predicate agrees with its component's own early return — table-driven,
   so the two cannot drift.
7. Photo tiles are 2-up below `sm`, 3-up above.
8. The lightbox still opens, closes on Escape and steps with arrows —
   regression cover, since this spec touches the grid that opens it.
9. `SuggestedMembers` renders `MemberCard` with `compact`; the community grid
   renders it without.
10. Existing suites stay green, `ProfilePage.test.tsx` in particular.

Repo constraints: 40px minimum tap target; no inline `style={{}}` with hex; the
bundle budget has ~9KB headroom.

## Out of scope

- The lightbox itself.
- Desktop layout, beyond inheriting the merged card.
- The tab mechanism — it stays, with its ARIA intact.
- Piece **D**: splitting `MainCommunity.tsx`, deleting the dead
  `.tandem-member-card*` CSS, migrating `$tandem-*` onto tokens, and the
  spacing sweep this piece's sibling narrowed.
