# Community main: section order, spacing rhythm and type hierarchy

**Date:** 2026-09-30
**Status:** Awaiting review
**Scope:** Piece **B** of the community decomposition. Follows piece A (the three-column grid and match chips), which is merged and deployed.

---

## Why

Asked what still looked wrong once the grid landed, three answers:

1. Too many competing sections before the members.
2. Vertical rhythm and spacing.
3. Typography and colour hierarchy.

Filter *interaction* was explicitly not chosen and is out of scope.

Each of the three is measurable in the current source, so this spec argues from
numbers rather than impressions.

### 1. The stack before the grid

On the **All members** tab with an active account, five bands sit between
arriving and seeing a member: sub-nav, quick filter chips, active filter chips,
highlighted-profiles carousel, visitors banner, then the member count, then the
grid.

This is already the worst case, not the normal one — the code is conditional and
deliberately so (`MainCommunity.tsx:825-859`): the chips hide on *For you*, and
the carousel and visitors banner render only on *All members* and only when
non-empty. Existing comments explain that reasoning; this spec works with it.

### 2. Spacing

Nineteen distinct pixel values across the stylesheet:

```
2 3 4 5 6 8 10 11 12 14 16 18 20 24 26 28 38 48 64
```

There is no scale, so nothing relates to anything. `11px`, `26px` and `38px`
exist for no reason a reader can reconstruct.

### 3. Type

Eleven font sizes, three of which are the same size to the eye:
`0.875rem` (14px), `0.9375rem` (15px) and `0.95rem` (15.2px) — within 1.2px of
each other — plus `1rem`/`1.0625rem` (16/17px). Steps nobody can perceive do not
produce hierarchy; they produce noise.

## Decisions

Taken by the user during design:

- **Visitors banner becomes a badge in the sub-nav** (option B).
- **The highlighted-profiles carousel moves below the first row of members**
  (option D).
- Neither the carousel nor the visitors list is deleted. Nothing is cut.

Rejected during design: merging carousel and visitors into one strip — two
components with different data shapes and different empty states, for ~40px.

## Design

### Section order (All members tab)

| Now | After |
|---|---|
| Sub-nav | Sub-nav **+ visitors pill** |
| Quick filter chips | Quick filter chips |
| Active filter chips | Active filter chips |
| Highlighted carousel | Member count |
| Visitors banner | **Member grid — first row** |
| Member count | Highlighted carousel |
| Member grid | *(grid continues)* |

The visitors pill shows the count and opens the same list the banner opened —
a notification, not a browsing surface, which is what it always was.

The carousel is re-inserted after the first grid row. The grid is a CSS grid, so
the carousel becomes a full-row item (`grid-column: 1 / -1`), the same mechanism
the interleaved ad already uses (`.community-grid__ad`).

**Other tabs are untouched.** Online, New and *For you* already omit these
sections, and this spec does not change what they render.

### Spacing scale

Add a spacing scale to the shared `--bt-*` family, which currently has colour,
radius, shadow, font and tracking tokens but **no spacing tokens**:

```
--bt-space-1: 4px    --bt-space-4: 16px
--bt-space-2: 8px    --bt-space-5: 24px
--bt-space-3: 12px   --bt-space-6: 32px
                     --bt-space-7: 48px
```

Every margin, padding and gap in `tandem-community.scss` maps onto it. The
nineteen values collapse to seven; `11 → 12`, `26 → 24`, `38 → 32|48`, `2/3/5 →
4`. Values below 4px that carry real optical meaning (hairline offsets, icon
nudges) stay literal and get a comment saying why — a scale that lies about its
exceptions is worse than none.

### Type scale

Five steps, replacing eleven:

| Token | Size | Used for |
|---|---|---|
| `--bt-text-xs` | 0.75rem | chips, meta, counts |
| `--bt-text-sm` | 0.875rem | body, labels — absorbs 0.9375 and 0.95 |
| `--bt-text-base` | 1rem | card names — absorbs 1.0625 |
| `--bt-text-lg` | 1.125rem | section headings |
| `--bt-text-xl` | 1.25rem | page heading |

`0.6875rem` (11px) is retained only where a chip genuinely needs it, as an
explicit exception with a comment.

## Explicitly out of scope

**The `$tandem-*` colour variables stay as they are in this piece.** The
stylesheet defines its own hex copies of tokens that already exist:

```scss
$tandem-text: #171e29;   // ink-900
$tandem-muted: #6b7686;  // ink-500
$tandem-border: #e5e9f0; // line
```

Those comments name the tokens they duplicate. Because the values are compiled
in, the dark-mode block is **38 rules carrying 38 hex literals** — every one a
hand-written override that exists only because the light value is hardcoded.

Migrating them is worth doing and is **deferred to piece D**, for one reason:
the hex values already equal the tokens, so the migration changes almost nothing
visually. It is a refactor, not a visual fix, and folding it in here would
multiply this diff for no visible gain while making the review much harder. D
already owns deleting the ~130 lines of dead `.tandem-member-card*` CSS
(`MemberCard` is Tailwind and uses none of it) and splitting
`MainCommunity.tsx`; the token migration and the dark-mode collapse belong with
them, in one pass over the file.

Also out of scope: filter interaction redesign (not chosen); the community
**detail** page (piece C); the accessibility debt carried over from piece A —
`title` on an `aria-hidden` flag span, and the unlabelled online dot and story
ring.

## Success

- On *All members* with an active account, the first row of members is visible
  without scrolling at 1180×900.
- The visitors count is still reachable in one interaction.
- `tandem-community.scss` uses no spacing value outside the scale except where a
  comment justifies it.
- No font size outside the five steps except a commented exception.
- Online, New and *For you* render exactly what they render today.

## Testing

Follows `communityStyling.test.ts`, which already asserts stylesheet facts
statically.

1. The spacing scale exists in `index.css` and `tandem-community.scss`
   references tokens, not raw px, outside the commented exceptions.
2. No font-size literal outside the five tokens, bar commented exceptions.
3. The visitors banner is gone from the page body; the sub-nav carries a pill
   with the count, and activating it opens the visitors list.
4. The carousel renders after the first grid row and spans the full row.
5. *Online*, *New* and *For you* render no carousel and no visitors pill —
   pinned so this does not leak into the lean tabs.
6. A user with zero visitors gets no pill at all.
7. Existing suites stay green: `communityPerf`, `MainCommunityTabs`,
   `communityStyling`, `MemberCard`.

Repo constraints: no hex in the stylesheet, tokens only; 40px minimum tap target
(the visitors pill is a control); bundle budget has ~9KB of headroom.
