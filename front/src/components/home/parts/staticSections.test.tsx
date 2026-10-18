import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import StatStrip from "./StatStrip";
import HowItWorks from "./HowItWorks";
import EarlyAdopterBand from "./EarlyAdopterBand";
import FinalCta from "./FinalCta";
import { APP_STORE_URL, PLAY_STORE_URL } from "../../growth/StoreLink";

// `mockTMode` toggles the mocked `t` between echoing its key (proves every
// visible string in these sections is routed through i18n) and returning ""
// (proves the `t(key) || "English"` fallback idiom). Must be prefixed with
// "mock" -- babel-plugin-jest-hoist only allows referencing such names from
// inside a jest.mock() factory.
let mockTMode: "echo" | "fallback" = "fallback";
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => (mockTMode === "echo" ? key : "") }),
}));
jest.mock("../../../store/slices/publicStatsSlice", () => ({
  ...jest.requireActual("../../../store/slices/publicStatsSlice"),
  useGetPublicStatsQuery: () => ({ data: undefined }),
}));

// jsdom has no matchMedia. Without a stub, prefersReducedMotion() returns
// false, useCountUp animates from 0, and the first render shows "0" instead
// of the target -- failing the "137" assertion below for reasons unrelated
// to the component. Reporting reduced motion makes useCountUp return its
// target synchronously, which is both deterministic and exercises the
// reduced-motion path the spec requires.
beforeEach(() => {
  mockTMode = "fallback";
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    configurable: true,
    value: (query: string) => ({
      matches: query.includes("reduce"),
      media: query,
      addEventListener: () => {},
      removeEventListener: () => {},
      addListener: () => {},
      removeListener: () => {},
      dispatchEvent: () => false,
    }),
  });
});

it("shows exactly the four verifiable stats", () => {
  render(<StatStrip />);
  expect(screen.getAllByTestId("stat-item")).toHaveLength(4);
  expect(screen.getByTestId("stat-strip").textContent).toContain("137");
});

// The "app languages" figure must match the real locale list. Importing
// SUPPORTED_LANGUAGES from src/utils/i18n.ts directly breaks this suite:
// that module calls `i18n.use(initReactI18next)` at import time, and this
// file's `jest.mock("react-i18next", ...)` above replaces the whole module
// -- including `initReactI18next`, which becomes undefined -- so i18next.use()
// throws before any test can run ("You are passing an undefined module!").
// Asserting the literal figure here instead; re-verify by counting the
// files in src/utils/locales/ or the entries in SUPPORTED_LANGUAGES.
it("states the app language count as 18, matching SUPPORTED_LANGUAGES", () => {
  render(<StatStrip />);
  expect(screen.getByTestId("stat-strip").textContent).toContain("18");
});

// Nothing on this page may claim social proof the product has not earned.
it("claims no members, ratings or reviews", () => {
  render(<StatStrip />);
  const text = (screen.getByTestId("stat-strip").textContent || "").toLowerCase();
  expect(text).not.toContain("member");
  expect(text).not.toContain("rating");
  expect(text).not.toContain("review");
  expect(text).not.toContain("★");
});

it("walks through three steps", () => {
  render(<HowItWorks />);
  expect(screen.getAllByTestId("how-step")).toHaveLength(3);
});

// Every step's title and body must resolve through i18n, not a hardcoded
// string -- proven by making `t` echo the key it was called with.
it("routes every step's copy through home.howItWorks.steps.<n>", () => {
  mockTMode = "echo";
  render(<HowItWorks />);
  [1, 2, 3].forEach((n) => {
    expect(screen.getByText(`home.howItWorks.steps.${n}.title`)).toBeInTheDocument();
    expect(screen.getByText(`home.howItWorks.steps.${n}.body`)).toBeInTheDocument();
  });
});

// With no translation available, the English copy embedded as the fallback
// must still render.
it("falls back to the English step copy when a translation is missing", () => {
  render(<HowItWorks />);
  const steps = screen.getAllByTestId("how-step").map((s) => s.textContent || "");
  expect(steps[0]).toContain("Tell us what you speak, and what you want");
  expect(steps[0]).toContain("Pick your native language and the one you're learning. That pair is how we match you.");
  expect(steps[1]).toContain("Find someone worth talking to");
  expect(steps[2]).toContain("Talk badly, improve fast");
});

it("frames the launch honestly rather than borrowing credibility", () => {
  render(<EarlyAdopterBand />);
  const text = screen.getByTestId("early-adopter-band").textContent || "";
  expect(text).toContain("2025");
  expect(text.toLowerCase()).not.toContain("trusted by");
});

it("routes every early-adopter string through home.earlyAdopter.*", () => {
  mockTMode = "echo";
  render(<EarlyAdopterBand />);
  const band = screen.getByTestId("early-adopter-band");
  expect(band).toHaveTextContent("home.earlyAdopter.badge");
  expect(band).toHaveTextContent("home.earlyAdopter.title");
  expect(band).toHaveTextContent("home.earlyAdopter.body");
});

it("falls back to the English early-adopter copy when a translation is missing", () => {
  render(<EarlyAdopterBand />);
  const text = screen.getByTestId("early-adopter-band").textContent || "";
  expect(text).toContain("Launched December 2025");
  expect(text).toContain("Be one of the first");
  expect(text).toContain(
    "BananaTalk is new. The people you meet here are the ones building what this community becomes — which is a better reason to join early than any review."
  );
});

it("closes with both store links, tagged as the closing CTA", () => {
  render(<FinalCta />);
  const cta = screen.getByTestId("final-cta");
  const ios = cta.querySelector('[data-testid="store-link-ios"]');
  const android = cta.querySelector('[data-testid="store-link-android"]');
  expect((ios as Element).getAttribute("href")).toContain(APP_STORE_URL);
  expect((android as Element).getAttribute("href")).toContain(PLAY_STORE_URL);
  expect((ios as Element).getAttribute("href")).toContain("utm_campaign=final-cta");
});

// The closing CTA breathes rather than sitting flat -- a background-position
// loop, so it costs no layout and stops dead under reduced motion.
it("runs a shifting gradient behind the closing CTA", () => {
  render(<FinalCta />);
  const cta = screen.getByTestId("final-cta");
  expect(cta.className).toContain("motion-safe:animate-bt-gradient");
  expect(cta.className).toContain("bg-gradient-to-br");
});

// Contrast: white on the darkest stop of the gradient, never a tinted grey.
it("keeps the CTA heading white against every stop of the gradient", () => {
  render(<FinalCta />);
  const h2 = screen.getByTestId("final-cta").querySelector("h2");
  expect((h2 as Element).className).toContain("text-white");
});
