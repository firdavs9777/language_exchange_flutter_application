# Community Grid and Match Legibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put three members per row on the community page and show each one's match reasons as tiered chips inside the card.

**Architecture:** `MainCommunity` renders a single-column flex list of horizontal row cards today. Both tabs move to a CSS grid, `MemberCard` is reshaped from a row into a cell, the `Why: …` sentence in the parent becomes chips inside the card, and the `content-visibility` affordances tuned to a 104px row are re-tuned to the taller cell.

**Tech Stack:** React 18 + TypeScript (CRA), Tailwind utilities inside `MemberCard`, SCSS for `tandem-community.scss`, Jest + React Testing Library.

**Spec:** `docs/superpowers/specs/2026-09-30-community-grid-and-match-design.md`

## Global Constraints

- **No hex colours in `tandem-community.scss`** — tokens only. `communityStyling.test.ts` enforces it.
- **No inline `style={{}}` containing hex** in community components — same test.
- **Minimum 40px tap target** in primary flows.
- **Three columns above 1024px, two from 381–1024px, one at or below 380px.**
- **`loading="lazy"` and `decoding="async"` stay on every member image**, with explicit `width`/`height` so the browser can reserve the box.
- **`matchReasons` is 0–3 strings.** Zero is reachable and must render no chip row.
- **Run tests with `CI=true`**; `npx react-scripts build` is the type check.

## Review Focus

- **A member with no `imageUrls`** — the 16:10 photo becomes a letter placeholder; it must fill the box, not collapse it. Pinned in Task 2.
- **The story ring** is positioned for a 72×72 avatar (`-bottom-1 -left-1` siblings); on a full-width photo it must not float over the middle of the image. Pinned in Task 2.
- **The `React.memo` comparator** (`areMemberRowsEqual`) lists every prop it compares. A new `reasons` prop it does not compare means chips never update. Pinned in Task 3.
- **A long or CJK name** at a ~380px card must not force the column wider or clip mid-glyph. Pinned in Task 2.
- **A reasons array containing `""` or duplicates** — the existing parent filters `Boolean`; that filter moves into the card and must survive. Pinned in Task 3.

---

### Task 1: The grid container

**Files:**
- Modify: `src/components/community/tandem/tandem-community.scss:690-695` (and the three responsive rules at 972, 979, 1084)
- Modify: `src/components/community/MainCommunity.tsx:166` and `:904`
- Test: `src/components/community/communityStyling.test.ts`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the `.community-grid` class, used by Task 4's intrinsic-size work.

- [ ] **Step 1: Write the failing test**

Append to `src/components/community/communityStyling.test.ts`:

```ts
describe("the member list is a grid, not a column", () => {
  it("puts three members per row above 1024px", () => {
    expect(scss).toMatch(/\.community-grid\s*\{[^}]*grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\)/);
  });

  it("drops to two columns on a tablet and one on a small phone", () => {
    expect(scss).toMatch(/@media \(max-width: 1024px\)[\s\S]*?\.community-grid\s*\{[^}]*repeat\(2, minmax\(0, 1fr\)\)/);
    expect(scss).toMatch(/@media \(max-width: 380px\)[\s\S]*?\.community-grid\s*\{[^}]*repeat\(1, minmax\(0, 1fr\)\)/);
  });

  it("renders members through the grid on both tabs, not a flex column", () => {
    expect(tsx).toContain('className="community-grid"');
    expect(tsx).not.toContain('className="flex flex-col gap-3"');
  });
});
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `CI=true npx react-scripts test --testPathPattern "communityStyling" --watchAll=false`
Expected: FAIL — the grid is still `auto-fill`, and the component still renders `flex flex-col gap-3`.

- [ ] **Step 3: Rewrite the grid rule**

In `tandem-community.scss`, replace the `.community-grid` block at ~line 690:

```scss
/* ===== Member Grid =====
   repeat(3, ...) rather than auto-fill: the column count is the design, not a
   consequence of the container's width. minmax(0, 1fr) so a long unbroken name
   cannot push its column wider than its share. */
.community-grid {
  margin-top: 16px;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}
```

Delete the `.community-grid` rules inside `@media (max-width: 900px)` (~line 972) and `@media (max-width: 640px)` (~line 1018), and replace the one inside `@media (max-width: 380px)` (~line 1084). Add, next to the other responsive rules:

```scss
@media (max-width: 1024px) {
  .community-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
  }
}

@media (max-width: 380px) {
  .community-grid {
    grid-template-columns: repeat(1, minmax(0, 1fr));
  }
}
```

- [ ] **Step 4: Point both tabs at the grid**

In `MainCommunity.tsx`, the *For you* list at ~line 164:

```jsx
      <div className="community-grid">
```

and the *All members* list at ~line 904:

```jsx
            <div className="community-grid">
```

Leave the skeleton container at ~line 881 on `flex flex-col gap-3` for now — Task 4 owns it. To keep the Step 1 assertion honest, that container becomes `community-skeleton-list` in this step, with a rule beside the grid:

```scss
.community-skeleton-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
```

- [ ] **Step 5: Run the tests**

Run: `CI=true npx react-scripts test --testPathPattern "community" --watchAll=false`
Expected: the three new assertions PASS. `communityPerf.test.tsx` and `MainCommunityTabs.test.tsx` still pass — they query by testid, not by container class.

- [ ] **Step 6: Commit**

```bash
git add src/components/community/tandem/tandem-community.scss src/components/community/MainCommunity.tsx src/components/community/communityStyling.test.ts
git commit -m "feat(community): three members per row instead of a single column

.community-grid existed in the stylesheet and nothing used it: both tabs
rendered a flex column, one member per row. It is now the container for both,
rewritten from auto-fill (which resolved to five columns at 1180px) to an
explicit three."
```

---

### Task 2: The card becomes a cell

**Files:**
- Modify: `src/components/community/MemberCard.tsx:86-230`
- Modify: `src/components/community/communityPerf.test.tsx:209-210`
- Test: `src/components/community/MemberCard.test.tsx`

**Interfaces:**
- Consumes: `.community-grid` from Task 1.
- Produces: `MemberCardProps` unchanged — `{ user, onWave, onOpen }`. The chip
  prop arrives in Task 3.

- [ ] **Step 1: Write the failing tests**

Append inside the existing `describe("MemberCard", …)` in `MemberCard.test.tsx`:

```tsx
it("stacks the card: photo above the details, not beside them", () => {
  const { container } = render(
    <MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />
  );
  const root = screen.getByTestId("member-card-root");
  expect(root.className).toContain("flex-col");
  expect(root.className).not.toContain("items-center");
  expect(container.querySelector("[data-testid='member-card-photo']")).toBeInTheDocument();
});

it("gives the photo a reserved 16:10 box so the grid does not reflow", () => {
  render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
  const img = screen.getByAltText("Alice") as HTMLImageElement;
  expect(img).toHaveAttribute("width", "320");
  expect(img).toHaveAttribute("height", "200");
  expect(img).toHaveAttribute("loading", "lazy");
  expect(img).toHaveAttribute("decoding", "async");
});

it("fills the photo box with an initial when the member has no picture", () => {
  render(
    <MemberCard user={{ ...baseUser, imageUrls: [] }} onWave={jest.fn()} onOpen={jest.fn()} />
  );
  const placeholder = screen.getByTestId("member-card-photo-placeholder");
  expect(placeholder).toHaveTextContent("A");
  expect(placeholder.className).toContain("w-full");
  expect(placeholder.className).toContain("h-full");
});

it("keeps the story ring on the photo corner, not across the middle", () => {
  render(
    <MemberCard
      user={{ ...baseUser, hasActiveStory: true }}
      onWave={jest.fn()}
      onOpen={jest.fn()}
    />
  );
  const ring = screen.getByTestId("member-card-story-ring");
  expect(ring.className).toContain("absolute");
});

it("does not let a long name widen its column", () => {
  render(
    <MemberCard
      user={{ ...baseUser, name: "안녕하세요반갑습니다저는한국어를배우고있어요" }}
      onWave={jest.fn()}
      onOpen={jest.fn()}
    />
  );
  expect(screen.getByTestId("member-card-name").className).toContain("truncate");
});

it("gives the wave button the full width of the card foot", () => {
  render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
  const wave = screen.getByTestId("member-card-wave");
  expect(wave.className).toContain("w-full");
});
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `CI=true npx react-scripts test --testPathPattern "MemberCard" --watchAll=false`
Expected: FAIL — the root is `flex items-center`, there is no `member-card-photo`, and the avatar is 72×72.

- [ ] **Step 3: Reshape the card**

In `MemberCard.tsx`, change the root container (line ~94) from
`"flex items-center gap-4 …"` to:

```jsx
      className="flex flex-col bg-white/80 backdrop-blur-xl rounded-2xl shadow-lg border border-white/30 overflow-hidden hover:shadow-xl hover:-translate-y-0.5 transition-all cursor-pointer"
```

Replace the avatar block (the `<div className="relative shrink-0 w-[72px] h-[72px] aspect-square">` wrapper and its contents) with a full-width photo. Keep the story-ring and online-dot elements; only their container changes:

```jsx
      {/* Photo — 16:10 so a row of three is not a wall of portraits. The
          width/height are the reserved box, not the painted size. */}
      <div data-testid="member-card-photo" className="relative w-full aspect-[16/10]">
        {avatar ? (
          <img
            src={avatar}
            alt={user.name}
            width={320}
            height={200}
            loading="lazy"
            decoding="async"
            className="block w-full h-full object-cover"
          />
        ) : (
          <div
            data-testid="member-card-photo-placeholder"
            className="w-full h-full bg-gradient-to-br from-teal-100 to-yellow-50 flex items-center justify-center text-4xl font-semibold text-teal-600"
          >
            {user.name?.charAt(0)?.toUpperCase()}
          </div>
        )}
        {user.hasActiveStory && (
          <span
            data-testid="member-card-story-ring"
            className="absolute left-2 top-2 rounded-full ring-2 ring-teal-400 w-3 h-3 bg-white"
          />
        )}
        {user.isOnline && (
          <span
            data-testid="member-card-online-dot"
            className="absolute right-2 top-2 w-3 h-3 rounded-full bg-green-500 border-2 border-white"
          />
        )}
      </div>
```

Wrap the details block (`<div className="flex-1 min-w-0">`) in padding, since the root no longer has `p-4`:

```jsx
      <div className="flex-1 min-w-0 p-4">
```

Change the wave button (line ~219) from a fixed circle to a full-width foot:

```jsx
      <button
        type="button"
        data-testid="member-card-wave"
        onClick={handleWaveClick}
        aria-label={`Wave at ${user.name}`}
        className="w-full min-h-[44px] flex items-center justify-center gap-2 text-white bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] hover:brightness-105 active:scale-[.99] transition-all"
      >
```

- [ ] **Step 4: Update the perf assertion deliberately**

In `communityPerf.test.tsx`, lines 209-210 assert the old avatar box. Change to the new reserved box and record why:

```ts
      // A box the browser can reserve before a byte arrives. 320x200 is the
      // 16:10 grid photo; it was 72x72 when the card was a list row.
      expect(img).toHaveAttribute("width", "320");
      expect(img).toHaveAttribute("height", "200");
```

- [ ] **Step 5: Run the tests**

Run: `CI=true npx react-scripts test --testPathPattern "community|MemberCard" --watchAll=false`
Expected: PASS, including `communityPerf.test.tsx`.

- [ ] **Step 6: Commit**

```bash
git add src/components/community/MemberCard.tsx src/components/community/MemberCard.test.tsx src/components/community/communityPerf.test.tsx
git commit -m "feat(community): the member card is a cell, not a row

Photo on top at 16:10, details below, wave across the foot. The 72x72 avatar
belonged to a full-width list row; in a three-column grid it left most of the
cell empty. The reserved box moves with it, so the browser still holds space
before the image arrives."
```

---

### Task 3: Match reasons as tiered chips

**Files:**
- Modify: `src/components/community/MemberCard.tsx` (props, chips, memo comparator)
- Modify: `src/components/community/MainCommunity.tsx:165-180`
- Modify: `src/components/community/MainCommunityTabs.test.tsx:240`
- Test: `src/components/community/MemberCard.test.tsx`
- Test: `src/components/community/communityStyling.test.ts` (the sentence is gone)

**Interfaces:**
- Consumes: the cell layout from Task 2.
- Produces: `MemberCardProps` gains `reasons?: string[]`. `MainCommunity` passes
  `member.matchReasons`; the *All members* tab passes nothing.

- [ ] **Step 1: Write the failing tests**

```tsx
describe("MemberCard match reasons", () => {
  const withReasons = (reasons: string[]) =>
    render(
      <MemberCard
        user={baseUser}
        reasons={reasons}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );

  it("leads with the language reason and mutes the rest", () => {
    withReasons(["Active today", "Native Korean speaker", "Same country"]);
    const chips = screen.getAllByTestId(/^member-card-reason/);
    expect(chips).toHaveLength(3);
    expect(chips[0]).toHaveTextContent("Native Korean speaker");
    expect(chips[0].getAttribute("data-testid")).toBe("member-card-reason-primary");
    expect(chips[1].getAttribute("data-testid")).toBe("member-card-reason-secondary");
  });

  it("shows presence reasons on their own when there is no language match", () => {
    withReasons(["Active today", "Same country"]);
    expect(screen.queryByTestId("member-card-reason-primary")).not.toBeInTheDocument();
    expect(screen.getAllByTestId("member-card-reason-secondary")).toHaveLength(2);
  });

  it("renders no chip row at all when there are no reasons", () => {
    withReasons([]);
    expect(screen.queryByTestId("member-card-reasons")).not.toBeInTheDocument();
  });

  it("renders no chip row when the prop is absent", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
    expect(screen.queryByTestId("member-card-reasons")).not.toBeInTheDocument();
  });

  it("drops empty strings rather than rendering a blank chip", () => {
    withReasons(["", "Active today", ""]);
    expect(screen.getAllByTestId(/^member-card-reason/)).toHaveLength(1);
  });

  it("re-renders when only the reasons change", () => {
    // Same user object and same handlers, so every other field the memo
    // comparator looks at is identical. If it does not compare reasons -- or
    // compares them after its `user === user` fast path -- this keeps the old
    // chip.
    const onWave = jest.fn();
    const onOpen = jest.fn();
    const { rerender } = render(
      <MemberCard user={baseUser} reasons={["Active today"]} onWave={onWave} onOpen={onOpen} />
    );
    rerender(
      <MemberCard user={baseUser} reasons={["Same country"]} onWave={onWave} onOpen={onOpen} />
    );
    expect(screen.getByText("Same country")).toBeInTheDocument();
    expect(screen.queryByText("Active today")).not.toBeInTheDocument();
  });

});
```

And in `src/components/community/communityStyling.test.ts`, a static check that
the sentence really left the parent. This is deliberately a source assertion
rather than a render one: `screen.queryByTestId` in a test that renders nothing
passes whatever the code does, which would be a test that asserts nothing.

```ts
it("leaves the Why sentence behind -- the card carries the reasons now", () => {
  expect(tsx).not.toContain("for-you-why");
  expect(tsx).not.toContain("communityMain.forYou.why");
});
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `CI=true npx react-scripts test --testPathPattern "MemberCard" --watchAll=false`
Expected: FAIL — `reasons` is not a prop and no chips render.

- [ ] **Step 3: Add the prop, the tiering and the chips**

Extend the interface:

```ts
export interface MemberCardProps {
  user: CommunityMemberCard;
  /** From the matching engine. 0-3 strings; see controllers/matching.js. */
  reasons?: string[];
  onWave: (user: CommunityMemberCard) => void;
  onOpen: (user: CommunityMemberCard) => void;
}
```

Add above the component:

```ts
/**
 * Only the language bucket describes compatibility -- the others are presence
 * and location facts. Leading with the language reason stops a card reading
 * "Active today - Same country" and making the matching look shallow.
 */
const isLanguageReason = (reason: string): boolean =>
  /^Speaks |^Native /.test(reason);

const orderReasons = (reasons: string[]): string[] => {
  const clean = reasons.filter(Boolean);
  return [...clean.filter(isLanguageReason), ...clean.filter((r) => !isLanguageReason(r))];
};
```

Render the chip row after the details block, before the wave button:

```jsx
      {orderedReasons.length > 0 && (
        <div data-testid="member-card-reasons" className="flex flex-wrap gap-1.5 px-4 pb-3">
          {orderedReasons.map((reason) => {
            const primary = isLanguageReason(reason);
            return (
              <span
                key={reason}
                data-testid={primary ? "member-card-reason-primary" : "member-card-reason-secondary"}
                className={
                  primary
                    ? "text-[11px] font-semibold text-teal-700 bg-teal-50 border border-teal-200 rounded-full px-2 py-0.5"
                    : "text-[11px] text-gray-600 bg-gray-100 border border-gray-200 rounded-full px-2 py-0.5"
                }
              >
                {reason}
              </span>
            );
          })}
        </div>
      )}
```

with, beside the other derived values at the top of `MemberCardRow`:

```ts
  const orderedReasons = orderReasons(reasons || []);
```

and the signature updated to `({ user, reasons, onWave, onOpen })`.

- [ ] **Step 4: Teach the memo comparator about the new prop**

`MemberCard` is `React.memo(MemberCardRow, areMemberRowsEqual)` and that
comparator lists every prop it compares. Without this a card keeps the chips it
first rendered.

**The placement matters.** The comparator has an `if (a === b) return true;`
fast path for an unchanged user object. A reasons check placed *after* it never
runs when the user object is reused — which is exactly what the list does. It
goes **before** that line.

`areMemberRowsEqual` at `MemberCard.tsx:243` already takes
`(prev: MemberCardProps, next: MemberCardProps)`, so only the body changes.
Insert the reasons comparison directly after the handler check:

```ts
export const areMemberRowsEqual = (
  prev: MemberCardProps,
  next: MemberCardProps
): boolean => {
  // The handlers end up on onClick/onKeyDown, so a new identity is a real
  // difference. Both callers pass useCallback'd ones.
  if (prev.onOpen !== next.onOpen || prev.onWave !== next.onWave) return false;

  // Before the `a === b` fast path below: the list reuses the user object
  // between renders, so a comparison placed after it would never run and the
  // chips would freeze at whatever first rendered.
  const ra = prev.reasons || [];
  const rb = next.reasons || [];
  if (ra.length !== rb.length) return false;
  if (ra.some((reason, index) => reason !== rb[index])) return false;

  const a = prev.user;
  const b = next.user;
  if (a === b) return true;

  return (
    a._id === b._id &&
    a.name === b.name &&
    a.bio === b.bio &&
    a.native_language === b.native_language &&
    a.language_to_learn === b.language_to_learn &&
    a.birth_year === b.birth_year &&
    a.createdAt === b.createdAt &&
    a.isNew === b.isNew &&
    a.isVIP === b.isVIP &&
    a.languageLevel === b.languageLevel &&
    a.hasActiveStory === b.hasActiveStory &&
    a.isOnline === b.isOnline &&
    // Only the first image is painted; the rest of the array is not the
    // card's business.
    (a.imageUrls ? a.imageUrls[0] : undefined) ===
      (b.imageUrls ? b.imageUrls[0] : undefined) &&
    formatLocation(a.location) === formatLocation(b.location)
  );
};
```

- [ ] **Step 5: Move the rendering out of the parent**

In `MainCommunity.tsx`, replace the *For you* block at ~line 165:

```jsx
      <div className="community-grid">
        {members.map((member) => (
          <div key={member._id} className={CARD_SLOT}>
            <MemberCard
              user={member}
              reasons={member.matchReasons}
              onOpen={onOpen}
              onWave={onWave}
            />
          </div>
        ))}
      </div>
```

The `reasons` const, the `for-you-why` paragraph and its `t("communityMain.forYou.why")`
call all go. Leave the *All members* mapping alone — it passes no `reasons`.

- [ ] **Step 6: Update the tab test that asserted the sentence**

`MainCommunityTabs.test.tsx:240` does `await screen.findAllByTestId("for-you-why")`.
Replace with the chips:

```tsx
    const why = await screen.findAllByTestId(/^member-card-reason/);
    expect(why.length).toBeGreaterThan(0);
```

- [ ] **Step 7: Run the tests**

Run: `CI=true npx react-scripts test --testPathPattern "community|MemberCard" --watchAll=false`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add src/components/community/MemberCard.tsx src/components/community/MemberCard.test.tsx src/components/community/MainCommunity.tsx src/components/community/MainCommunityTabs.test.tsx
git commit -m "feat(community): match reasons are chips on the card, tiered

The reasons were a 'Why: a - b - c' sentence under the card, on the For you
tab only. They are chips inside the card now, with the language reason leading
in an accent chip and presence and location muted behind it -- only one of the
three buckets getMatchReasons draws from is about compatibility.

Zero reasons renders no row and no placeholder: an empty state should not
advertise an absence.

The memo comparator had to learn the new prop, or a card would keep the chips
it first rendered."
```

---

### Task 4: Re-tune the content-visibility affordances

**Files:**
- Modify: `src/components/community/tandem/tandem-community.scss:1217-1232`
- Modify: `src/components/community/MainCommunity.tsx:881` (skeleton container)
- Test: `src/components/community/communityStyling.test.ts`

**Interfaces:**
- Consumes: the cell from Task 2 and the grid from Task 1.
- Produces: nothing later tasks depend on. Last task.

- [ ] **Step 1: Write the failing test**

```ts
describe("the list still skips work it cannot see", () => {
  it("reserves the cell's height, not the old row's", () => {
    expect(scss).toMatch(/\.community-card-slot\s*\{[^}]*content-visibility:\s*auto/);
    expect(scss).toMatch(/\.community-card-slot\s*\{[^}]*contain-intrinsic-size:\s*auto 320px/);
    expect(scss).not.toContain("contain-intrinsic-size: auto 104px");
  });

  it("shapes the skeleton like the card it stands in for", () => {
    expect(scss).toMatch(/\.community-card-skeleton\s*\{[^}]*flex-direction:\s*column/);
    expect(scss).toMatch(/\.community-card-skeleton\s*\{[^}]*min-height:\s*320px/);
  });

  it("lays the skeletons out in the same grid as the members", () => {
    expect(tsx).not.toContain('className="community-skeleton-list"');
  });
});
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `CI=true npx react-scripts test --testPathPattern "communityStyling" --watchAll=false`
Expected: FAIL — the slot still reserves 104px and the skeleton is still a row.

- [ ] **Step 3: Re-tune the slot and the skeleton**

In `tandem-community.scss`:

```scss
/* The cell is roughly 320px tall: a 16:10 photo on a ~330px column is ~206px,
   plus details, chips and the wave foot. A wrong estimate here makes the
   scrollbar jump as cards render, which is worse than no content-visibility
   at all. */
.community-card-slot {
  content-visibility: auto;
  contain-intrinsic-size: auto 320px;
  padding: 8px 8px 20px;
  margin: -8px -8px -20px;
}

/* A cell-shaped placeholder, the same height as the card it stands in for. */
.community-card-skeleton {
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 320px;
  padding: 0 0 16px;
  border-radius: 16px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.3);
}
```

- [ ] **Step 4: Put the skeletons in the grid**

In `MainCommunity.tsx` at ~line 881, the skeleton container becomes the grid, so
the first paint does not reflow into a different layout:

```jsx
          <div
            className="community-grid"
            data-testid="community-skeletons"
            aria-busy="true"
          >
```

Delete the `.community-skeleton-list` rule added in Task 1.

- [ ] **Step 5: Run the whole suite**

Run: `CI=true npx react-scripts test --watchAll=false`
Expected: PASS, all suites.

- [ ] **Step 6: Type check and budget**

Run: `npx react-scripts build`
Expected: "Compiled with warnings" and no TypeScript error.

Run: `BUNDLE_BUDGET=1 CI=true npx react-scripts test --testPathPattern "bundleBudget" --watchAll=false`
Expected: PASS. Headroom is thin (317.0 / 326 KB before this change), so a
failure here is a real signal, not noise.

- [ ] **Step 7: Commit**

```bash
git add src/components/community/tandem/tandem-community.scss src/components/community/MainCommunity.tsx src/components/community/communityStyling.test.ts
git commit -m "perf(community): reserve the cell's height, not the old row's

content-visibility: auto is only as good as contain-intrinsic-size. The slot
reserved 104px, the height of the list row the card used to be; a grid cell is
about 320px, and the gap between estimate and reality is what makes a
scrollbar jump while you scroll. The skeleton takes the cell's shape for the
same reason -- a row-shaped placeholder reflows into a grid on first paint."
```
