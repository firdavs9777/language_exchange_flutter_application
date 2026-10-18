import { showsAdAfter } from "./gridInterleave";

describe("where the ads go", () => {
  it("falls every sixth member", () => {
    const ctx = { total: 30 };
    expect(showsAdAfter(5, ctx)).toBe(true);
    expect(showsAdAfter(11, ctx)).toBe(true);
    expect(showsAdAfter(17, ctx)).toBe(true);
    expect(showsAdAfter(4, ctx)).toBe(false);
  });

  it("never follows the last member", () => {
    expect(showsAdAfter(5, { total: 6 })).toBe(false);
  });

  it("keeps its slot now the carousel no longer contests it", () => {
    // The carousel used to take the index-5 row on the All tab and the ad
    // yielded to it. The carousel sits above the grid now, so the ad takes
    // every sixth row on every tab.
    expect(showsAdAfter(5, { total: 8 })).toBe(true);
  });
});
