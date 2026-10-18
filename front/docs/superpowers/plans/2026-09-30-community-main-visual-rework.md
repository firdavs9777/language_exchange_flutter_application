# Community Main Visual Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put the first row of members above the fold on the All members tab, and give the page a type scale and a page-level spacing rhythm it can be reasoned about.

**Architecture:** Two layout moves (the visitors banner becomes a pill in the sub-nav; the highlighted carousel moves below the first grid row as a full-row item) plus two systematic passes (a five-step type scale replacing eleven sizes, and the gaps *between* top-level sections put onto a spacing scale). Colour tokens are deliberately untouched — piece D owns them.

**Tech Stack:** React 18 + TypeScript (CRA), Tailwind utilities in components, SCSS for `tandem-community.scss`, CSS custom properties in `src/index.css`, Jest + React Testing Library.

**Spec:** `docs/superpowers/specs/2026-09-30-community-main-visual-rework-design.md`

## Global Constraints

- **`tandem-community.scss` legitimately contains hex today** (92 literals, mostly the `$tandem-*` SCSS variables). The no-hex rule in `communityStyling.test.ts:72` applies to the member-page TSX sources, NOT to this stylesheet. Do not purge them — migrating `$tandem-*` onto tokens is piece **D**.
- **No inline `style={{}}` at all** in the member-page components, and no hex inside any inline style in community components. That is what `communityStyling.test.ts` actually enforces.
- **40px minimum tap target** in primary flows — the visitors pill is a control.
- **Online, New and For you must render exactly what they render today.** Only the All members tab changes.
- **Bundle budget has ~9KB headroom** (317.1 / 326 KB). Check it at the end.
- **Run tests with `CI=true`**; `npx react-scripts build` is the type check.

## Scope narrowing, decided before this plan was written

The spec called for every margin, padding and gap to move onto a spacing scale.
Measuring first changed that: there are **88 such declarations**, and the values
`6, 10, 14, 18, 20, 28` sit *between* the scale's steps — `20px` alone appears
11 times and would have to become 16 or 24. Each is a judgement call that shifts
the look, the implementer cannot see the rendered page, and the tests can only
assert "no raw px", never "it still looks right". Rewriting all 88 would be
churn with an invisible failure mode.

**Task 3 therefore applies the scale only to the gaps BETWEEN top-level
sections and the page container's padding** — where "vertical rhythm" actually
lives, about a dozen declarations, each individually verifiable. Intra-component
spacing keeps its current values. The type scale (Task 2) is *not* narrowed:
collapsing 14px/15px/15.2px into one step is invisible by construction, which is
the whole argument for doing it.

## Review Focus

- **A user with zero visitors** must get no pill at all, not an empty one — today `VisitorsBanner` early-returns on `totalCount === 0`. Pinned in Task 4.
- **The lean tabs** (Online, New, For you) must not gain a pill or a carousel; they render neither today. Pinned in Tasks 4 and 5.
- **The carousel as a grid child** must span the full row, or it eats one of three columns and shifts every following member — the same defect piece A hit with the interleaved ad. Pinned in Task 5.
- **A page with fewer members than one row** (1 or 2 results) still has to place the carousel sensibly, not leave a gap. Pinned in Task 5.
- **The pill is a link to `/visitors`**, so it must be keyboard reachable and meet the 40px target. Pinned in Task 4.

---

### Task 1: Spacing and type tokens

**Files:**
- Modify: `src/index.css` (the `:root` block that already holds `--bt-*`)
- Test: `src/components/community/communityStyling.test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces: `--bt-space-1..7` and `--bt-text-xs|sm|base|lg|xl`, consumed by Tasks 3 and 4.

- [ ] **Step 1: Write the failing test**

Append to `communityStyling.test.ts`. It already reads `scss`; add the index
stylesheet beside it at the top of the file if not present:

```ts
const indexCss = fs.readFileSync(path.resolve(__dirname, "../../index.css"), "utf8");

describe("the shared scales exist as tokens", () => {
  it("declares a spacing scale", () => {
    ["--bt-space-1: 4px", "--bt-space-2: 8px", "--bt-space-3: 12px",
     "--bt-space-4: 16px", "--bt-space-5: 24px", "--bt-space-6: 32px",
     "--bt-space-7: 48px"].forEach((decl) => {
      expect(indexCss).toContain(decl);
    });
  });

  it("declares a five-step type scale", () => {
    ["--bt-text-xs: 0.75rem", "--bt-text-sm: 0.875rem", "--bt-text-base: 1rem",
     "--bt-text-lg: 1.125rem", "--bt-text-xl: 1.25rem"].forEach((decl) => {
      expect(indexCss).toContain(decl);
    });
  });
});
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `CI=true npx react-scripts test --testPathPattern "communityStyling" --watchAll=false`
Expected: FAIL — neither scale exists; `--bt-*` currently carries colour, radius, shadow, font and tracking only.

- [ ] **Step 3: Add both scales**

In `src/index.css`, inside the same `:root` block as the other `--bt-*` tokens:

```css
  /* Spacing scale. The community stylesheet grew nineteen distinct values with
     no relation between them (2 3 4 5 6 8 10 11 12 14 16 18 20 24 26 28 38 48
     64); this is the ladder new work climbs. */
  --bt-space-1: 4px;
  --bt-space-2: 8px;
  --bt-space-3: 12px;
  --bt-space-4: 16px;
  --bt-space-5: 24px;
  --bt-space-6: 32px;
  --bt-space-7: 48px;

  /* Type scale. Eleven sizes were in use, three of them within 1.2px of each
     other (0.875 / 0.9375 / 0.95rem) -- steps nobody can see are noise, not
     hierarchy. */
  --bt-text-xs: 0.75rem;
  --bt-text-sm: 0.875rem;
  --bt-text-base: 1rem;
  --bt-text-lg: 1.125rem;
  --bt-text-xl: 1.25rem;
```

- [ ] **Step 4: Run the test**

Run: `CI=true npx react-scripts test --testPathPattern "communityStyling" --watchAll=false`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/index.css src/components/community/communityStyling.test.ts
git commit -m "feat(tokens): a spacing scale and a type scale

The --bt-* family carried colour, radius, shadow, font and tracking but no
spacing and no type sizes, so every surface invented its own. Community alone
had nineteen spacing values and eleven font sizes."
```

---

### Task 2: Collapse the near-identical font sizes

**Files:**
- Modify: `src/components/community/tandem/tandem-community.scss` (10 distinct sizes, 30 declarations)
- Test: `src/components/community/communityStyling.test.ts`

**Interfaces:**
- Consumes: `--bt-text-*` from Task 1.
- Produces: a stylesheet with no bare `rem` font sizes outside commented exceptions.

- [ ] **Step 1: Write the failing test**

```ts
describe("type sizes come from the scale", () => {
  it("names no font size the scale does not have", () => {
    const sizes = scss.match(/font-size:\s*[^;]+;/g) || [];
    const offenders = sizes.filter(
      (decl) => !/var\(--bt-text-(xs|sm|base|lg|xl)\)/.test(decl) && !/inherit/.test(decl)
    );
    expect(offenders).toEqual([]);
  });
});
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `CI=true npx react-scripts test --testPathPattern "communityStyling" --watchAll=false`
Expected: FAIL, listing the bare-rem declarations.

- [ ] **Step 3: Apply this exact mapping**

Every `font-size` in `tandem-community.scss`, by current value:

| Current | Count | Becomes | Note |
|---|---|---|---|
| `0.6875rem` | 3 | `var(--bt-text-xs)` | 11px → 12px; smallest text on the page, and 11px was below the app's floor elsewhere |
| `0.75rem` | 5 | `var(--bt-text-xs)` | exact |
| `0.8125rem` | 6 | `var(--bt-text-sm)` | 13px → 14px |
| `0.875rem` | 4 | `var(--bt-text-sm)` | exact |
| `0.9375rem` | 5 | `var(--bt-text-sm)` | 15px → 14px, the collapse this task exists for |
| `0.95rem` | 1 | `var(--bt-text-sm)` | 15.2px → 14px |
| `1rem` | 3 | `var(--bt-text-base)` | exact |
| `1.0625rem` | 1 | `var(--bt-text-base)` | 17px → 16px |
| `1.125rem` | 1 | `var(--bt-text-lg)` | exact |
| `1.25rem` | 1 | `var(--bt-text-xl)` | exact |
| `inherit` | — | leave as is | not a size |

- [ ] **Step 4: Run the tests**

Run: `CI=true npx react-scripts test --testPathPattern "community" --watchAll=false`
Expected: PASS, all community suites.

- [ ] **Step 5: Commit**

```bash
git add src/components/community/tandem/tandem-community.scss src/components/community/communityStyling.test.ts
git commit -m "refactor(community): eleven font sizes become five

0.875rem, 0.9375rem and 0.95rem were 14px, 15px and 15.2px -- three steps
inside 1.2px, which reads as noise rather than hierarchy. They are one step now."
```

---

### Task 3: Page-level vertical rhythm

**Files:**
- Modify: `src/components/community/tandem/tandem-community.scss` — `.community-page`, `.community-page__container`, and the top margin of each top-level section (`.community-subnav`, `.community-grid`, `.community-empty`, `.community-loadmore`, the carousel and visitors rules)
- Test: `src/components/community/communityStyling.test.ts`

**Interfaces:**
- Consumes: `--bt-space-*` from Task 1.
- Produces: nothing later tasks depend on.

**Deliberately narrow.** Only the container padding and the gaps *between*
top-level sections move onto the scale. Intra-component spacing (inside a card,
a chip, the filter sheet) keeps its current values — see "Scope narrowing" above.

- [ ] **Step 1: Write the failing test**

```ts
describe("the page's own rhythm comes from the scale", () => {
  const pageRule = (selector: string): string => {
    const m = scss.match(new RegExp(`\\${selector}\\s*\\{([^}]*)\\}`));
    return m ? m[1] : "";
  };

  it("pads the page container from the scale", () => {
    expect(pageRule(".community-page__container")).toMatch(/var\(--bt-space-\d\)/);
  });

  it("spaces the member grid from the scale", () => {
    expect(pageRule(".community-grid")).toMatch(/margin-top:\s*var\(--bt-space-\d\)/);
  });
});
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `CI=true npx react-scripts test --testPathPattern "communityStyling" --watchAll=false`
Expected: FAIL — these rules use raw px.

- [ ] **Step 3: Map the page-level values**

Apply to the container and the between-section gaps only:

| Current | Becomes |
|---|---|
| `16px` | `var(--bt-space-4)` |
| `20px` | `var(--bt-space-5)` (24px — the page breathes; this is the one deliberate increase) |
| `24px` | `var(--bt-space-5)` |
| `28px` | `var(--bt-space-6)` |
| `12px` | `var(--bt-space-3)` |

`.community-grid`'s own `gap` stays at `20px` — it is intra-grid spacing, tuned
against the card width in piece A, and is not page rhythm.

- [ ] **Step 4: Run the tests**

Run: `CI=true npx react-scripts test --testPathPattern "community" --watchAll=false`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/components/community/tandem/tandem-community.scss src/components/community/communityStyling.test.ts
git commit -m "style(community): the page's own rhythm comes from the scale

Only the container padding and the gaps between top-level sections. Spacing
inside a card or a chip keeps its tuned values -- nineteen ad-hoc numbers is a
page-rhythm problem, not a reason to rewrite every declaration blind."
```

---

### Task 4: The visitors banner becomes a pill in the sub-nav

**Files:**
- Modify: `src/components/community/tandem/CommunitySubNav.tsx` (props + the `community-subnav__actions` block at ~line 166)
- Modify: `src/components/community/MainCommunity.tsx` (~line 857: remove `<VisitorsBanner>`, pass the count to the sub-nav)
- Modify: `src/components/community/tandem/tandem-community.scss` (add `.community-subnav__visitors`; the `.visitors-banner` rules become dead and are removed)
- Delete: `src/components/community/tandem/VisitorsBanner.tsx`
- Modify: `src/components/community/MainCommunityTabs.test.tsx:196` — "keeps the visitors banner and the highlighted carousel on All only" asserts `.visitors-banner` IS present. Deleting the banner breaks it HERE, so this task drops the visitors half of that test; Task 5 then rewrites the carousel half.
- Test: `src/components/community/tandem/CommunitySubNav.test.tsx`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `CommunitySubNavProps` gains `visitorsCount?: number`.

- [ ] **Step 1: Write the failing tests**

Append to `CommunitySubNav.test.tsx`. Its helper is `renderNav(props)` at line 14 — use that name, not a new one:

```tsx
it("shows a visitors pill with the count", () => {
  renderNav({ visitorsCount: 12 });
  const pill = screen.getByTestId("subnav-visitors");
  expect(pill).toHaveTextContent("12");
  expect(pill).toHaveAttribute("href", "/visitors");
  expect(pill).toHaveAccessibleName();
});

it("shows no pill when nobody has visited", () => {
  renderNav({ visitorsCount: 0 });
  expect(screen.queryByTestId("subnav-visitors")).not.toBeInTheDocument();
});

it("shows no pill when the count is absent", () => {
  renderNav({});
  expect(screen.queryByTestId("subnav-visitors")).not.toBeInTheDocument();
});
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `CI=true npx react-scripts test --testPathPattern "CommunitySubNav" --watchAll=false`
Expected: FAIL — no such prop or element.

- [ ] **Step 3: Add the pill**

In `CommunitySubNav.tsx`, extend the props interface:

```ts
  /** How many people visited the viewer's profile. Absent or 0 renders nothing. */
  visitorsCount?: number;
```

and render it first inside `community-subnav__actions` (~line 166):

```jsx
        {typeof visitorsCount === "number" && visitorsCount > 0 && (
          <Link
            to="/visitors"
            data-testid="subnav-visitors"
            className="community-subnav__visitors"
            aria-label={
              t("communityMain.visitors.pill", { count: visitorsCount }) ||
              `${visitorsCount} people visited your profile`
            }
          >
            <span aria-hidden>👋</span>
            <span>{visitorsCount > 99 ? "99+" : visitorsCount}</span>
          </Link>
        )}
```

Import `Link` from `react-router-dom` if it is not already imported.

- [ ] **Step 4: Style it**

In `tandem-community.scss`, beside the other `.community-subnav__*` rules:

```scss
.community-subnav__visitors {
  display: inline-flex;
  align-items: center;
  gap: var(--bt-space-1);
  /* 40px is this app's floor for a tap target in a primary flow. */
  min-height: 40px;
  padding: 0 var(--bt-space-3);
  border-radius: var(--bt-radius-chip);
  background: $tandem-pink-soft;
  color: $tandem-pink;
  font-size: var(--bt-text-sm);
  font-weight: 600;
  text-decoration: none;
  white-space: nowrap;
}
```

- [ ] **Step 5: Remove the banner**

In `MainCommunity.tsx`, delete the `{activeTab === "all" && visitorsTotal > 0 && (<VisitorsBanner … />)}` block (~line 857) and its import, and pass the count to the sub-nav (~line 792):

```jsx
        visitorsCount={activeTab === "all" ? visitorsTotal : 0}
```

Delete `VisitorsBanner.tsx` and the `.visitors-banner*` rules from the
stylesheet. Then fix `MainCommunityTabs.test.tsx:196`, which asserts
`.visitors-banner` is present and will fail the moment the component is gone:
remove its two `.visitors-banner` assertions and rename it to
`"keeps the highlighted carousel on All only"`. Leave the carousel assertions
alone — Task 5 rewrites those. Nothing else references the banner. Verify with:
`grep -rn "VisitorsBanner\|visitors-banner" src/` before committing; only the
i18n keys should remain, and `communityMain.visitors.seeAll` becomes unused —
leave the keys in place, they are shared with `/visitors`.

- [ ] **Step 6: Run the tests**

Run: `CI=true npx react-scripts test --testPathPattern "community|CommunitySubNav" --watchAll=false`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add -A src/components/community src/index.css
git commit -m "feat(community): visitors become a pill in the sub-nav

A full-width banner for a notification. It is a count and a link to the same
list, so it belongs beside the other sub-nav actions -- one band fewer between
arriving and seeing a member, with the information kept."
```

---

### Task 5: The carousel moves below the first row of members

**Files:**
- Modify: `src/components/community/MainCommunity.tsx` (~line 851 removal; re-insertion inside the grid loop at ~line 905)
- Modify: `src/components/community/tandem/tandem-community.scss` (add `.community-grid__feature`)
- Modify: `src/components/community/MainCommunityTabs.test.tsx:196` — the existing test "keeps the visitors banner and the highlighted carousel on All only" asserts both sit above the grid; Task 4 deleted the banner and this task moves the carousel, so it must be rewritten, not deleted
- Test: `src/components/community/MainCommunityTabs.test.tsx`

**Interfaces:**
- Consumes: `.community-grid` and the full-row mechanism `.community-grid__ad` already uses.
- Produces: nothing. Last task.

- [ ] **Step 1: Write the failing tests**

`MainCommunityTabs.test.tsx`'s helper is `renderList(entries: string[])` at line
112 — there is no props-based helper. Members come from a `global.fetch` mock
installed at line 72, and the carousel is found by its class `.highlighted-banner`,
not a testid.

**First, update the existing test at line 196**, which this task invalidates. It
currently asserts the visitors banner and the carousel are both present above the
grid on All and absent on Online. The banner is gone (Task 4) and the carousel
has moved, so it becomes:

```tsx
  it("keeps the highlighted carousel on All only, below the first row", async () => {
    const { container, router } = renderList();

    await waitFor(() =>
      expect(container.querySelector(".highlighted-banner")).toBeInTheDocument()
    );
    // It is inside the grid now, not a sibling above it.
    const grid = container.querySelector(".community-grid")!;
    expect(grid.querySelector(".highlighted-banner")).toBeInTheDocument();
    expect(container.querySelector(".visitors-banner")).not.toBeInTheDocument();

    fireEvent.click(tab("communityMain.tabs.online"));
    await waitFor(() => expect(router.state.location.search).toBe("?tab=online"));

    expect(container.querySelector(".highlighted-banner")).not.toBeInTheDocument();
  });
```

Then add:

```tsx
  it("places the carousel after the first row of three, spanning the row", async () => {
    const { container } = renderList();
    const grid = await waitFor(() => container.querySelector(".community-grid")!);
    await waitFor(() =>
      expect(grid.querySelector(".highlighted-banner")).toBeInTheDocument()
    );

    const feature = grid.querySelector(".community-grid__feature")!;
    expect(feature).toBeInTheDocument();
    // Three members per row, so the carousel is the fourth child of the grid.
    expect(Array.from(grid.children).indexOf(feature)).toBe(3);
  });

  it("still places the carousel when a search returns fewer than one row", async () => {
    // The shared mock returns a full page; this one returns two members so the
    // index === 2 branch is never reached and the fallback has to carry it.
    const realFetch = global.fetch;
    (global as any).fetch = jest.fn((input: any) => {
      const url = String(input);
      if (/\/auth\/users\?/.test(url)) {
        return Promise.resolve(new Response(JSON.stringify({
          data: [
            { _id: "m1", name: "Ada", imageUrls: [], native_language: "English", language_to_learn: "Korean" },
            { _id: "m2", name: "Bo", imageUrls: [], native_language: "Korean", language_to_learn: "English" },
          ],
          total: 2,
        }), { status: 200, headers: { "Content-Type": "application/json" } }));
      }
      return (realFetch as any)(input);
    });

    const { container } = renderList();
    const grid = await waitFor(() => container.querySelector(".community-grid")!);
    await waitFor(() =>
      expect(grid.querySelector(".highlighted-banner")).toBeInTheDocument()
    );
    global.fetch = realFetch;
  });
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `CI=true npx react-scripts test --testPathPattern "MainCommunityTabs" --watchAll=false`
Expected: FAIL — the carousel is still above the grid.

- [ ] **Step 3: Move it into the grid**

Delete the standalone block at ~line 851. Inside the All-members member loop
(~line 905), after index 2 — the third member, i.e. the end of the first row —
emit the carousel as a full-row item:

```jsx
                  {index === 2 && activeTab === "all" && highlightedProfiles.length > 0 && (
                    <div className="community-grid__feature">
                      <HighlightedProfilesCarousel
                        profiles={highlightedProfiles as any}
                        currentUser={currentUser}
                      />
                    </div>
                  )}
```

A thread shorter than one row never reaches index 2, so also emit it after the
last member when `allMembers.length < 3`:

```jsx
                  {allMembers.length < 3 &&
                    index === allMembers.length - 1 &&
                    activeTab === "all" &&
                    highlightedProfiles.length > 0 && (
                    <div className="community-grid__feature">
                      <HighlightedProfilesCarousel
                        profiles={highlightedProfiles as any}
                        currentUser={currentUser}
                      />
                    </div>
                  )}
```

- [ ] **Step 4: Make it span the row**

```scss
/* A full-row item in the member grid, like .community-grid__ad: a carousel that
   took one of three columns would shift every member after it. */
.community-grid__feature {
  grid-column: 1 / -1;
  margin: var(--bt-space-2) 0;
}
```

- [ ] **Step 5: Run the whole suite**

Run: `CI=true npx react-scripts test --watchAll=false`
Expected: PASS, all suites.

- [ ] **Step 6: Type check and budget**

Run: `npx react-scripts build`
Expected: "Compiled with warnings" (pre-existing eslint warnings in
NearbyUsers.tsx, MomentDetail.tsx, MainNavbar.tsx, MyMoments.tsx,
StoryViewer.tsx — not yours), no TypeScript error.

Run: `BUNDLE_BUDGET=1 CI=true npx react-scripts test --testPathPattern "bundleBudget" --watchAll=false`
Expected: PASS. Headroom is ~9KB, so a failure is a real signal.

- [ ] **Step 7: Commit**

```bash
git add src/components/community
git commit -m "feat(community): the page opens on people, not on promos

The highlighted carousel sat between the filters and the first member. It is a
full-row item after the first row now, so the grid starts above the fold and
the carousel is still found by anyone who scrolls. Nothing was deleted."
```
