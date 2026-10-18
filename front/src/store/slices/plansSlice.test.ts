import { inferPlatform, FALLBACK_PLANS } from "./plansSlice";

it("infers the store from the user agent", () => {
  expect(inferPlatform("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)")).toBe("ios");
  expect(inferPlatform("Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X)")).toBe("ios");
  expect(inferPlatform("Mozilla/5.0 (Linux; Android 14; Pixel 8)")).toBe("android");
});

// Desktop has no store of its own; the CTA opens a modal. iOS pricing is the
// default only because Apple and Google prices are identical today.
it("defaults to ios on desktop", () => {
  expect(inferPlatform("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)")).toBe("ios");
  expect(inferPlatform("")).toBe("ios");
});

it("ships fallback prices that match the stores, not the old website copy", () => {
  const byId = Object.fromEntries(FALLBACK_PLANS.map((p) => [p.id, p]));
  expect(byId.monthly.localizedPrice).toBe("$9.99");
  expect(byId.quarterly.localizedPrice).toBe("$23.99");
  expect(byId.yearly.localizedPrice).toBe("$71.99");
});

// The regression guard. These two numbers were on the live site and were
// never what the stores charged.
it("never reintroduces the wrong prices", () => {
  const prices = FALLBACK_PLANS.map((p) => p.localizedPrice);
  expect(prices).not.toContain("$14.99");
  expect(prices).not.toContain("$49.99");
});

it("offers all three real plans, including the quarterly the site omitted", () => {
  expect(FALLBACK_PLANS.map((p) => p.id).sort()).toEqual(["monthly", "quarterly", "yearly"]);
});

it("marks exactly one plan recommended", () => {
  const byId = Object.fromEntries(FALLBACK_PLANS.map((p) => [p.id, p]));
  expect(FALLBACK_PLANS.filter((p) => p.recommended)).toHaveLength(1);
  expect(byId.yearly.recommended).toBe(true);
  expect(byId.quarterly.recommended).toBe(false);
});
