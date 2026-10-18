# Community main: member grid and match legibility

**Date:** 2026-09-30
**Status:** Awaiting review (rewritten — the first draft was wrong, see *Correction*)
**Scope:** The member list on `MainCommunity` and how match reasons are shown. Piece **A** of a four-part decomposition (see *Out of scope*).

---

## Correction

The first draft of this spec claimed the page renders a five-column grid that
crushes each card to 220px, and that fixing the column count would also fix
match legibility. **That was wrong.** It was derived from `.community-grid` in
`tandem-community.scss` without checking whether anything uses that class.

Nothing does. `.community-grid` is dead CSS, along with most of the
`.tandem-member-card*` rules beside it — remnants of the Tandem-style redesign
in `76f3381`, orphaned when `61e4fd0` ("perf(community): lazy media, memoized
cards, sentinel paging, content-visibility") replaced the grid with a list.

The decisions taken during design are unaffected and still stand: **3 per row**,
and **reason chips with no score**. What changed is the size of the work.

## Current state, as verified

Both tabs render the same container (`MainCommunity.tsx:166` for *For you*,
`:904` for *All members*):

```jsx
<div className="flex flex-col gap-3">
  <div className="community-card-slot"><MemberCard … /></div>
```

- **One member per row.** A single-column vertical list, full width.
- **`MemberCard` is a horizontal row card**, built from Tailwind utilities
  inline in the TSX (`MemberCard.tsx:94`): `flex items-center gap-4`, a 72×72
  avatar left, `flex-1 min-w-0` details centre, a 44px wave button right. It
  does not use the `.tandem-member-card` SCSS classes at all.
- **The row height is load-bearing.** `.community-card-slot` sets
  `content-visibility: auto; contain-intrinsic-size: auto 104px`, and
  `.community-card-skeleton` is a matching 104px row. Both come from the perf
  commit and both assume a short, wide row.
- **Match reasons are a sentence, not chips**, and only on *For you*
  (`MainCommunity.tsx:171`): `Why: Native Korean speaker · Active today`.
  *All members* shows none, because only the recommendations endpoint returns
  them.

So the work is not retuning a grid. It is **introducing a grid where there is a
list, and reshaping the card from a row into a cell** — with the perf
affordances that were tuned for rows updated to match.

## Intent

**What the user asked for:** "like tandem showing 3 or 4 users in one row",
matching more visible, and a general UI improvement to community main.

**Decided during design, by the user:**
- **3 per row** at desktop width (chosen over the recommended 4).
- **Reason chips only, no score number.** The score still orders the list.

**Assumption to flag:** 3-up shows roughly 6 members per screen where the
current list shows 5–6 in the same space, so this is not a density loss — but
each card becomes ~3× taller, which is what forces the perf changes below.

**Success:** at 1180px, three members sit per row; a member's name, both
languages and every match reason returned are readable without truncation; a
card with no reasons still looks deliberate; and the list still scrolls and
pages as smoothly as it does today.

## The data, as verified

`getMatchReasons` (`controllers/matching.js:475`) is authoritative — line 229
overwrites the aggregation's projected `matchReasons` with its return value. It
draws from three independent buckets:

| Bucket | Possible values |
|---|---|
| Language | `Speaks {native}, learning {learning}` · `Native {native} speaker` · *nothing* |
| Activity | `Online now` · `Active today` · *nothing* |
| Location | `Same country` · *nothing* |

**`matchReasons.length` is 0–3, and 0 is reachable.** A candidate who is not a
language match, has not been active in 24 hours, and is in another country
returns an empty array.

**Only the language bucket describes compatibility.** The other two are presence
and location. Styling all three identically would make matching look shallow,
because a common card reads `Active today · Same country`.

## Design

### The grid

Replace the flex column with a grid, on both tabs:

```jsx
<div className="community-grid">
```

`.community-grid` is rewritten rather than reused as-is — its `auto-fill`
rule is what would put five cards in a row:

```scss
.community-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}
```

`repeat(3, …)` rather than `auto-fill`, so the column count is the design and
not a consequence of container width. `minmax(0, 1fr)` so a long unbroken name
cannot force a column wider than its share.

| Viewport | Columns | Reason |
|---|---|---|
| > 1024px | 3 | The chosen desktop density |
| 381–1024px | 2 | 3-up below ~1024px gives ~300px cards, which re-crowds |
| ≤ 380px | 1 | Two columns on a 380px phone gives ~170px cards |

This replaces the three existing rules (900px, 640px, 380px).

### The card

`MemberCard` changes from a row to a cell. It keeps its Tailwind approach — the
file is already written that way and this spec does not migrate it to SCSS.

| Part | Now | Becomes |
|---|---|---|
| Container | `flex items-center gap-4` | `flex flex-col` |
| Photo | 72×72 avatar, left | Full-width 16:10 image at the top |
| Details | `flex-1 min-w-0`, centre | Below the photo |
| Wave | 44px circle, right | Full-width button at the foot |
| Reasons | none (sentence lives in the parent) | chip row, inside the card |

The 44px wave button becomes full-width, keeping it well above the 40px tap
target floor this repo holds itself to.

### Reason chips

Two tiers, because only one bucket is about compatibility:

- **Primary** — the language reason. Accent chip, always first.
- **Secondary** — `Online now` / `Active today` / `Same country`. Muted chip.

Ordered by tier, not by array order, so a card leads with its strongest claim.
The rendering moves from `MainCommunity.tsx:171` into `MemberCard`, so both
tabs go through one path; *All members* simply passes no reasons.

**Empty state (0 reasons):** no chip row, no placeholder. The card falls back to
name and languages — which is exactly what *All members* shows. Explicitly not a
"No reasons" chip, which would advertise an absence.

**Overflow:** at most three chips exist, so no truncation logic is needed. A test
pins that, so a fourth bucket added server-side fails loudly here.

### Perf affordances that must move with it

These are not optional; they are tuned to the row shape and will mis-size a grid
cell:

1. **`.community-card-slot`** — `contain-intrinsic-size: auto 104px` must become
   the grid card's height. A wrong estimate makes the scrollbar jump as cards
   render, which is worse than not using `content-visibility` at all.
2. **`.community-card-skeleton`** — currently a 104px flex row. It must take the
   card's shape, or the first paint reflows into a different layout.
3. **Avatar dimensions** — `MemberCard` renders `width={72} height={72}` and
   `communityPerf.test.tsx:209` asserts exactly that. Both change together.
   `loading="lazy"` and `decoding="async"` stay.

### Where the changes live

| File | Change |
|---|---|
| `MemberCard.tsx` | Row → cell layout; photo dimensions; chip row and tiering; empty-reason branch |
| `MainCommunity.tsx` | `flex flex-col gap-3` → `community-grid` in both places; remove the `for-you-why` sentence; pass reasons into `MemberCard` |
| `tandem/tandem-community.scss` | Rewrite `.community-grid`; `.community-card-slot` intrinsic size; `.community-card-skeleton` shape; chip tier classes |
| `communityPerf.test.tsx` | Update the 72×72 assertion to the new dimensions |
| `MainCommunityTabs.test.tsx:240` | Asserts `for-you-why`, which this removes — it becomes an assertion on the chips instead |

`MainCommunity.tsx` is 978 lines and wants splitting, but that is piece **D**
and not required here. Nothing in this spec should grow it.

## Testing

Follows the existing patterns in `MemberCard.test.tsx`, `communityStyling.test.ts`
and `communityPerf.test.tsx`.

1. **Three columns at desktop** — assert the stylesheet rule, as
   `communityStyling.test.ts` already asserts stylesheet facts.
2. **Both tabs use the grid** — neither renders `flex flex-col gap-3` for members.
3. **Three reasons** render three chips, language chip first.
4. **Only secondary reasons** (`Active today`, `Same country`) render with no
   primary chip.
5. **Zero reasons** renders no chip row and no placeholder text.
6. **Chip tiering** — the language reason carries the primary class, the others
   the muted class.
7. **The `for-you-why` sentence is gone**, and its testid with it.
8. **Perf suite stays green**, with the avatar assertion updated deliberately
   rather than deleted.
9. **Skeleton and card agree** — the skeleton's reserved height matches the
   card's `contain-intrinsic-size`.

Repo constraints this must satisfy: no hex colours in the stylesheet, tokens
only, no inline `style={{}}` with hex in community components
(`communityStyling.test.ts`), and a 40px minimum tap target.

## Risks

- **Scroll jank** is the main one. `content-visibility: auto` with a wrong
  `contain-intrinsic-size` is worse than none. Test 9 exists for this.
- **Dead SCSS.** `.tandem-member-card*` rules stay dead after this change, since
  `MemberCard` is Tailwind. Removing them is tempting and out of scope — it
  belongs with piece **D**.

## Out of scope

| | Piece | Why deferred |
|---|---|---|
| **B** | Whole-page visual rework — spacing, typography, filters, sub-nav | Scope it against the improved page |
| **C** | Community **detail** page — image viewing and info legibility | A separate surface with its own flow |
| **D** | Splitting `MainCommunity.tsx`; deleting the dead `.tandem-member-card*` CSS | Needed for B, not for this |

No backend change. `getMatchReasons` is correct as it stands; this spec only
changes how its output is displayed.
