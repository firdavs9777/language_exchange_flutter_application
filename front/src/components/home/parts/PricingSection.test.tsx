import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import PricingSection from "./PricingSection";
import { FALLBACK_PLANS } from "../../../store/slices/plansSlice";
import { APP_STORE_URL, PLAY_STORE_URL } from "../../growth/StoreLink";

const mockQuery = jest.fn();
jest.mock("../../../store/slices/plansSlice", () => ({
  ...jest.requireActual("../../../store/slices/plansSlice"),
  useGetVipPlansQuery: (...args: any[]) => mockQuery(...args),
}));

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "" }),
}));

beforeEach(() => mockQuery.mockReset());

it("renders the store's own price string, unmodified", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  render(<PricingSection />);
  const prices = screen.getAllByTestId("plan-price").map((n) => n.textContent);
  expect(prices).toEqual(expect.arrayContaining(["$9.99", "$23.99", "$71.99"]));
});

it("never shows the prices the old site invented", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  const { container } = render(<PricingSection />);
  expect(container.textContent).not.toContain("$14.99");
  expect(container.textContent).not.toContain("$49.99");
});

it("falls back to real plans when the request fails", () => {
  mockQuery.mockReturnValue({ data: undefined, isError: true, isLoading: false });
  render(<PricingSection />);
  expect(screen.getAllByTestId("plan-card").length).toBeGreaterThanOrEqual(3);
  expect(screen.getAllByTestId("plan-price").map((n) => n.textContent))
    .toEqual(expect.arrayContaining(["$9.99"]));
});

it("shows a savings badge only on plans that have one", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  render(<PricingSection />);
  // monthly has savings: null; quarterly 20%, yearly 40%
  expect(screen.getAllByTestId("plan-savings")).toHaveLength(2);
});

it("highlights the recommended plan", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  render(<PricingSection />);
  expect(screen.getAllByTestId("plan-recommended")).toHaveLength(1);
});

it("tags every VIP call to action as the pricing placement", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  const { container } = render(<PricingSection />);
  const links = Array.from(container.querySelectorAll('[data-testid^="store-link-"]'));
  expect(links.length).toBe(FALLBACK_PLANS.length);
  links.forEach((a) => expect(a.getAttribute("href")).toContain("utm_campaign=pricing"));
});

it("renders the free tier alongside the paid plans", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  render(<PricingSection />);
  expect(screen.getAllByTestId("plan-card")).toHaveLength(4);
});

it("renders the same store link on the server whatever the user agent is", () => {
  // The prerendered markup is one file served to everyone, so it must not
  // depend on the user agent: reading it during render is what left Android
  // visitors stuck with the App Store link (React 18 does not patch a
  // mismatched attribute while hydrating).
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  const original = window.navigator.userAgent;
  Object.defineProperty(window.navigator, "userAgent", {
    value: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36",
    configurable: true,
  });
  try {
    const markup = renderToString(<PricingSection />);
    expect(markup).toContain(APP_STORE_URL);
    expect(markup).not.toContain(PLAY_STORE_URL);
  } finally {
    Object.defineProperty(window.navigator, "userAgent", { value: original, configurable: true });
  }
});

it("points Android visitors at Google Play once the platform is known", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  const original = window.navigator.userAgent;
  Object.defineProperty(window.navigator, "userAgent", {
    value: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36",
    configurable: true,
  });
  try {
    // The first render is always the prerendered iOS one; the mount effect
    // swaps in the real platform, and render() flushes it before returning.
    const { container } = render(<PricingSection />);
    const stores = Array.from(container.querySelectorAll('[data-testid="store-link-android"]'));
    expect(stores.length).toBe(FALLBACK_PLANS.length);
    stores.forEach((a) => expect(a.getAttribute("href")).toContain(PLAY_STORE_URL));
    expect(container.querySelectorAll('[data-testid="store-link-ios"]')).toHaveLength(0);
  } finally {
    Object.defineProperty(window.navigator, "userAgent", { value: original, configurable: true });
  }
});

it("lists the real VIP perks, not the server's stale plan features", () => {
  mockQuery.mockReturnValue({
    data: FALLBACK_PLANS.map((p) => ({
      ...p,
      features: ["Unlimited daily messages", "Priority partner matching", "Premium support"],
    })),
    isError: false,
    isLoading: false,
  });
  const { container } = render(<PricingSection />);
  const text = container.textContent || "";
  expect(text).not.toMatch(/Unlimited daily messages|Priority partner matching|Premium support/);
  expect(text).toContain("15 daily matches instead of 6");
  expect(text).toContain("See everyone who viewed you");
});
