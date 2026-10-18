import { isSuppressed, recordDismissal, SUPPRESSION_DAYS } from "./growthGate";
import { STORE_HOSTS } from "./StoreLink";

// Spelled out nowhere: the store hostnames live only in StoreLink.tsx
// (src/components/growth/storeUrls.test.ts greps for copies of them).
const [IOS_HOST, ANDROID_HOST] = STORE_HOSTS;

const base = {
  pathname: "/",
  referrer: "https://www.google.com/",
  viewportWidth: 1280,
};

beforeEach(() => window.localStorage.clear());

it("is not suppressed for a fresh desktop visitor", () => {
  expect(isSuppressed("download-popup", base)).toBe(false);
});

it("suppresses after a dismissal, until the window expires", () => {
  const t0 = 1_000_000_000_000;
  recordDismissal("download-popup", t0);

  const dayMs = 24 * 60 * 60 * 1000;
  const withinWindow = t0 + (SUPPRESSION_DAYS["download-popup"] - 1) * dayMs;
  const afterWindow = t0 + (SUPPRESSION_DAYS["download-popup"] + 1) * dayMs;

  expect(isSuppressed("download-popup", { ...base, now: withinWindow })).toBe(true);
  expect(isSuppressed("download-popup", { ...base, now: afterWindow })).toBe(false);
});

it("keeps each key's dismissal separate", () => {
  recordDismissal("download-popup", 1_000);
  expect(isSuppressed("download-popup", { ...base, now: 1_000 })).toBe(true);
  expect(isSuppressed("promo-carousel", { ...base, now: 1_000 })).toBe(false);
});

it("suppresses the popup for visitors arriving from an app store", () => {
  expect(
    isSuppressed("download-popup", { ...base, referrer: `https://${IOS_HOST}/us/app/x` })
  ).toBe(true);
  expect(
    isSuppressed("download-popup", { ...base, referrer: `https://${ANDROID_HOST}/store/apps/x` })
  ).toBe(true);
});

it("suppresses the popup on auth routes", () => {
  expect(isSuppressed("download-popup", { ...base, pathname: "/register" })).toBe(true);
  expect(isSuppressed("download-popup", { ...base, pathname: "/login" })).toBe(true);
});

it("suppresses the popup on narrow viewports, where the sticky banner takes over", () => {
  expect(isSuppressed("download-popup", { ...base, viewportWidth: 500 })).toBe(true);
  expect(isSuppressed("sticky-banner", { ...base, viewportWidth: 500 })).toBe(false);
});

it("suppresses the sticky banner on wide viewports", () => {
  expect(isSuppressed("sticky-banner", { ...base, viewportWidth: 1280 })).toBe(true);
});

// A storage failure must not take the page down, and must fail OPEN.
it("treats unreadable storage as not suppressed", () => {
  const spy = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => {
    throw new Error("SecurityError");
  });
  expect(() => isSuppressed("download-popup", base)).not.toThrow();
  expect(isSuppressed("download-popup", base)).toBe(false);
  spy.mockRestore();
});

it("does not throw when a dismissal cannot be written", () => {
  const spy = jest.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
    throw new Error("QuotaExceeded");
  });
  expect(() => recordDismissal("download-popup", 1_000)).not.toThrow();
  spy.mockRestore();
});

it("uses hostname parsing for app store detection, not substring matching", () => {
  // Empty referrer (direct visit) should not suppress
  expect(isSuppressed("download-popup", { ...base, referrer: "" })).toBe(false);

  // Normal non-store referrer should not suppress
  expect(isSuppressed("download-popup", { ...base, referrer: "https://www.google.com/" })).toBe(
    false
  );

  // Genuine store referrers should suppress
  expect(isSuppressed("download-popup", { ...base, referrer: `https://${IOS_HOST}/` })).toBe(
    true
  );
  expect(
    isSuppressed("download-popup", { ...base, referrer: `https://subdomain.${IOS_HOST}/` })
  ).toBe(true);

  // Substring match false positive: a store host in a query parameter must NOT suppress
  expect(
    isSuppressed("download-popup", {
      ...base,
      referrer: `https://www.example.com/?redirect=https://${IOS_HOST}/`,
    })
  ).toBe(false);

  // A lookalike domain that merely ends with the host's text must NOT suppress
  expect(
    isSuppressed("download-popup", {
      ...base,
      referrer: `https://not${IOS_HOST}.example.com/x`,
    })
  ).toBe(false);
});

it("ensures popup and sticky banner are never both shown and never both hidden", () => {
  // Test the boundary at 767, 768, 769
  [767, 768, 769].forEach((width) => {
    const popupSuppressed = isSuppressed("download-popup", { ...base, viewportWidth: width });
    const bannerSuppressed = isSuppressed("sticky-banner", { ...base, viewportWidth: width });

    // Exactly one of them should be permitted (not suppressed)
    const popupPermitted = !popupSuppressed;
    const bannerPermitted = !bannerSuppressed;

    expect(popupPermitted).toBe(!bannerPermitted);
  });
});
