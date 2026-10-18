# Member Profile Phone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** On a phone, land on who someone is — languages and bio visible without tapping, photos visible on either tab at a scannable size — and stop the suggestion strip dominating the foot.

**Architecture:** Five phone-scoped changes to `ProfilePage` and its parts: flip the default tab, lift the phone photo set above the tab bar, merge four info cards into one (each part gaining a `bare` mode and an exported predicate), widen the photo tiles, and give `MemberCard` a `compact` variant for the suggestion strip.

**Tech Stack:** React 18 + TypeScript (CRA), Tailwind utilities, Jest + React Testing Library.

**Spec:** `docs/superpowers/specs/2026-09-30-member-profile-phone-design.md`

## Global Constraints

- **Desktop must render what it renders today**, bar the four-into-one card. Both tab panels are `lg:block`; do not change that.
- **`ProfilePhotos`'s lightbox is out of scope** — `role="dialog"`, `aria-modal`, Escape, arrow keys, trapped Tab, focus restore. Only the tile grid changes.
- **The duplicated `ProfilePhotos` stays** (`profile-photos-phone` / `profile-photos-desktop`) — a grid child cannot move between columns in CSS.
- **No inline `style={{}}` containing hex.** 40px minimum tap target.
- **Run tests with `CI=true`**; `npx react-scripts build` is the type check.

## Review Focus

- **A profile with nothing filled in** must show NO info card — not an empty one. Task 3.
- **`?tab=moments`** must still land on Moments after the default flips. Task 1.
- **The lightbox** must still open/close/step after the tile grid changes. Task 4.
- **The community grid must NOT go compact** — only the suggestion strip passes the prop. Task 5.
- **Predicate drift**: an exported predicate that disagrees with its component's own early return silently hides or shows a section. Task 3.

---

### Task 1: Flip the phone default tab

**Files:** Modify `src/components/profile/ProfilePage.tsx:145`; Test `src/components/profile/ProfilePage.test.tsx`

- [ ] **Step 1: Failing tests**

```tsx
it("opens on About so a phone lands on who someone is", () => {
  renderProfile("/community/u2");
  expect(screen.getByTestId("profile-about-panel").className).not.toContain("hidden");
  expect(screen.getByTestId("profile-moments-panel").className).toContain("hidden");
});

it("still honours ?tab=moments", () => {
  renderProfile("/community/u2?tab=moments");
  expect(screen.getByTestId("profile-moments-panel").className).not.toContain("hidden");
});
```

- [ ] **Step 2: Run, confirm fail** — `CI=true npx react-scripts test --testPathPattern "ProfilePage" --watchAll=false`

- [ ] **Step 3: Invert the default**

```tsx
  const tab: ProfileTab = searchParams.get("tab") === "moments" ? "moments" : "about";
```

- [ ] **Step 4: Run, confirm pass. Commit**

```bash
git commit -m "feat(profile): a phone opens on About, not on posts"
```

---

### Task 2: Photos above the tab bar on phone

**Files:** Modify `src/components/profile/ProfilePage.tsx` (~363 removal, re-insert above the tablist); Test `ProfilePage.test.tsx`

- [ ] **Step 1: Failing test**

```tsx
it("puts the phone photo set above the tabs, outside both panels", () => {
  const { container } = renderProfile("/community/u2");
  const photos = screen.getByTestId("profile-photos-phone");
  const tablist = container.querySelector('[role="tablist"]')!;
  expect(photos.closest('[role="tabpanel"]')).toBeNull();
  expect(photos.compareDocumentPosition(tablist) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
});
```

- [ ] **Step 2: Run, confirm fail**

- [ ] **Step 3: Move it.** Delete the `profile-photos-phone` wrapper from the About panel and place it immediately before the tablist:

```jsx
          <div data-testid="profile-photos-phone" className="lg:hidden">
            <ProfilePhotos images={images} isOwn={isOwn} name={name} />
          </div>
```

`profile-photos-desktop` is untouched.

- [ ] **Step 4: Run, confirm pass. Commit**

```bash
git commit -m "feat(profile): the photo set sits above the tabs on a phone"
```

---

### Task 3: One info card

**Files:** Modify `ProfileLanguages.tsx`, `ProfileAbout.tsx`, `ProfileLearning.tsx`, `MutualInterests.tsx`, `ProfilePage.tsx`; Test each part's test + `ProfilePage.test.tsx`

**Interfaces produced:** each part exports `bare?: boolean` on its props and a predicate — `hasLanguages(user)`, `hasAbout(user)`, `hasLearning(user)`, `hasMutualInterests(viewer, user)`.

- [ ] **Step 1: Failing tests**

```tsx
// ProfilePage.test.tsx
it("draws the four info sections in one card", () => {
  renderProfile("/community/u2");
  expect(screen.getAllByTestId("profile-info-card")).toHaveLength(1);
});

it("shows no info card when the profile has none of it", () => {
  renderProfile("/community/u-empty");
  expect(screen.queryByTestId("profile-info-card")).not.toBeInTheDocument();
});
```

```tsx
// ProfileAbout.test.tsx — same shape in each part's test
it("agrees with its own empty check", () => {
  expect(hasAbout({ bio: "", topics: [] } as any)).toBe(false);
  expect(hasAbout({ bio: "hi" } as any)).toBe(true);
});

it("drops its own card in bare mode", () => {
  const { container } = render(<ProfileAbout user={{ bio: "hi" } as any} bare />);
  expect(container.querySelector("[data-surface-card]")).toBeNull();
});
```

- [ ] **Step 2: Run, confirm fail**

- [ ] **Step 3: Add `bare` and the predicate to each part.** Pattern, using `ProfileAbout` (apply the same shape to the other three, each using ITS OWN existing condition):

```tsx
/** Whether this section has anything to show. The page asks before drawing the
 *  shared card, because a parent cannot know that a child returned null. */
export const hasAbout = (user: any): boolean => {
  const bio = (user && user.bio) || "";
  const occupation = (user && user.occupation) || "";
  const school = (user && user.school) || "";
  const mbti = (user && user.mbti) || "";
  const bloodType = (user && user.bloodType) || "";
  const topics = Array.isArray(user && user.topics) ? user.topics : [];
  return !!(bio || occupation || school || mbti || bloodType || topics.length);
};
```

and in the component, replace the early return with `if (!hasAbout(user)) return null;`, then wrap the return:

```tsx
  const body = ( /* the existing JSX that was inside SurfaceCard */ );
  return bare ? body : <SurfaceCard padding="lg">{body}</SurfaceCard>;
```

- [ ] **Step 4: Render one card in the page.** In `ProfilePage.tsx`, replace the four siblings in the About panel with:

```jsx
              {(hasLanguages(user) ||
                hasAbout(user) ||
                hasLearning(user) ||
                hasMutualInterests(viewer, user)) && (
                <SurfaceCard padding="lg" data-testid="profile-info-card">
                  <div className="space-y-5">
                    <ProfileLanguages user={user} bare />
                    <ProfileAbout user={user} bare />
                    <ProfileLearning user={user} bare />
                    {!isOwn && <MutualInterests viewer={viewer} user={user} bare />}
                  </div>
                </SurfaceCard>
              )}
```

- [ ] **Step 5: Run the profile suites, confirm pass. Commit**

```bash
git commit -m "feat(profile): four info cards become one

Each part keeps its own rule and exports it as a predicate, because a parent
cannot ask a child whether it returned null. A profile with none of the four
shows no card at all, which is what four independent early returns gave."
```

---

### Task 4: Wider photo tiles on a phone

**Files:** Modify `src/components/profile/parts/ProfilePhotos.tsx` (the `grid grid-cols-3 gap-2` list); Test `ProfilePhotos.test.tsx`

- [ ] **Step 1: Failing test**

```tsx
it("shows two tiles per row on a phone and three above it", () => {
  const { container } = render(<ProfilePhotos images={["a", "b", "c"]} isOwn={false} name="Ada" />);
  const list = container.querySelector("ul")!;
  expect(list.className).toContain("grid-cols-2");
  expect(list.className).toContain("sm:grid-cols-3");
});
```

- [ ] **Step 2: Run, confirm fail**

- [ ] **Step 3:** `grid grid-cols-3 gap-2` → `grid grid-cols-2 gap-2 sm:grid-cols-3`

- [ ] **Step 4: Run the full ProfilePhotos suite** — the lightbox tests must still pass untouched. Commit

```bash
git commit -m "feat(profile): photo tiles are scannable on a phone"
```

---

### Task 5: A compact MemberCard for the suggestion strip

**Files:** Modify `src/components/community/MemberCard.tsx`, `src/components/profile/parts/SuggestedMembers.tsx`; Test `MemberCard.test.tsx`, `SuggestedMembers.test.tsx`

- [ ] **Step 1: Failing tests**

```tsx
// MemberCard.test.tsx
it("lays out as a row in compact mode", () => {
  render(<MemberCard user={baseUser} compact onWave={jest.fn()} onOpen={jest.fn()} />);
  const root = screen.getByTestId("member-card-root");
  expect(root.className).toContain("flex-row");
  expect(screen.queryByTestId("member-card-photo")).not.toBeInTheDocument();
});

it("stays a cell by default", () => {
  render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
  expect(screen.getByTestId("member-card-photo")).toBeInTheDocument();
});
```

```tsx
// SuggestedMembers.test.tsx
it("asks for the compact card", () => {
  renderSuggested();
  expect(screen.queryByTestId("member-card-photo")).not.toBeInTheDocument();
});
```

- [ ] **Step 2: Run, confirm fail**

- [ ] **Step 3: Add the prop.** `MemberCardProps` gains `compact?: boolean`. When set: root is `flex flex-row items-center gap-3 p-3`, the full-width photo block is replaced by a 56×56 rounded avatar (keeping `loading="lazy"`, `decoding="async"`, explicit `width`/`height`), and the full-width wave foot becomes the 44px circular button on the right. The chip row is omitted in compact mode — a suggestion strip has no reasons.

Add `compact` to `areMemberRowsEqual` beside the reasons comparison, before the `a === b` fast path:

```ts
  if (prev.compact !== next.compact) return false;
```

- [ ] **Step 4:** `SuggestedMembers.tsx:95` passes `compact`.

- [ ] **Step 5: Run the full suite. Commit**

```bash
git commit -m "feat(profile): the suggestion strip gets its row card back

Piece A redesigned MemberCard for a three-column grid; SuggestedMembers reuses
it, so a ~104px row carousel became a ~400px card carousel. A horizontal strip
is not a grid — it gets the row shape back behind a prop."
```

- [ ] **Step 6: Verify**

`CI=true npx react-scripts test --watchAll=false` · `npx react-scripts build` · `BUNDLE_BUDGET=1 CI=true npx react-scripts test --testPathPattern "bundleBudget" --watchAll=false`
