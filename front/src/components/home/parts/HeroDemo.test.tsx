import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import HeroDemo from "./HeroDemo";
import { APP_STORE_URL, PLAY_STORE_URL } from "../../growth/StoreLink";

// `mockTMode` toggles the mocked `t` between echoing its key (proves the
// supporting line is routed through i18n) and returning "" (proves the
// `t(key) || "English"` fallback idiom). Must be prefixed with "mock" --
// babel-plugin-jest-hoist only allows referencing such names from inside a
// jest.mock() factory.
let mockTMode: "echo" | "fallback" = "fallback";
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => (mockTMode === "echo" ? key : "") }),
}));

beforeEach(() => {
  mockTMode = "fallback";
});

it("renders a headline", () => {
  render(<HeroDemo />);
  expect(screen.getByTestId("hero-headline")).toBeInTheDocument();
});

it("links to both stores, tagged as the hero", () => {
  render(<HeroDemo />);
  const ios = screen.getByTestId("store-link-ios").getAttribute("href") || "";
  const android = screen.getByTestId("store-link-android").getAttribute("href") || "";
  expect(ios).toContain(APP_STORE_URL);
  expect(android).toContain(PLAY_STORE_URL);
  [ios, android].forEach((href) => expect(href).toContain("utm_campaign=hero"));
});

// The mechanic is the argument: a message, its translation, and a correction.
it("shows the exchange, its translation and a tutor correction", () => {
  render(<HeroDemo />);
  expect(screen.getAllByTestId("demo-message").length).toBeGreaterThanOrEqual(2);
  expect(screen.getByTestId("demo-note")).toBeInTheDocument();
});

// Content must never depend on an animation having run.
it("renders all content immediately, animation aside", () => {
  render(<HeroDemo />);
  const text = screen.getByTestId("hero-demo").textContent || "";
  expect(text).toContain("안녕하세요");
  expect(text).toContain("Do you have time today?");
});

// --- Motion ----------------------------------------------------------------
// The hero runs a 14s CSS cycle: typing dots, then the message, then its
// translation. All of it is CSS-only, so none of it may gate content.

it("gives every bubble a typing indicator, hidden from assistive tech", () => {
  render(<HeroDemo />);
  const dots = screen.getAllByTestId("demo-typing");
  expect(dots).toHaveLength(3);
  dots.forEach((d) => expect(d).toHaveAttribute("aria-hidden"));
  // Reduced motion never runs the keyframe that clears the indicator, so the
  // indicator must not exist visually at all in that mode.
  dots.forEach((d) => expect(d.className).toContain("motion-reduce:hidden"));
});

it("keeps every bubble's text in the DOM regardless of the cycle", () => {
  render(<HeroDemo />);
  const bubbles = screen.getAllByTestId("demo-message");
  expect((bubbles[0].textContent || "")).toContain("안녕하세요");
  expect((bubbles[1].textContent || "")).toContain("practice Korean");
  expect((screen.getByTestId("demo-note").textContent || "")).toContain("practice");
});

it("drifts eight flags behind the hero, out of the accessibility tree", () => {
  render(<HeroDemo />);
  const layer = screen.getByTestId("hero-flags");
  expect(layer).toHaveAttribute("aria-hidden");
  const flags = Array.from(layer.children);
  expect(flags).toHaveLength(8);
  flags.forEach((f) => expect(f.className).toContain("motion-safe:animate-bt-drift"));
});

// prefers-reduced-motion must switch off everything, which it only does for
// classes that carry the variant.
it("prefixes every animation with motion-safe:", () => {
  render(<HeroDemo />);
  const all = screen.getByTestId("hero-demo").querySelectorAll("*");
  const bare: string[] = [];
  Array.prototype.forEach.call(all, (el: Element) => {
    (el.getAttribute("class") || "").split(/\s+/).forEach((token) => {
      if (token.indexOf("animate-") !== -1 && token.indexOf("motion-safe:animate-") !== 0) {
        bare.push(token);
      }
    });
  });
  expect(bare).toEqual([]);
});

// The page is prerendered in Node. Nothing here may read a browser global.
it("renders to a string on the server with its content intact", () => {
  const html = renderToString(<HeroDemo />);
  expect(html).toContain("안녕하세요");
  expect(html).toContain("hero-flags");
  expect(html).not.toContain("undefined");
});

// --- i18n --------------------------------------------------------------

// The keyword-led supporting line: the primary phrase for SEO, kept as the
// fallback so it renders even before a translation exists.
it("falls back to the keyword-led supporting line when a translation is missing", () => {
  render(<HeroDemo />);
  const text = screen.getByTestId("hero-demo").textContent || "";
  expect(text).toContain(
    "Free language exchange with native speakers. Write in your language, they read it in theirs, and you learn from the difference."
  );
});

it("routes the supporting line through home.hero.subtitle", () => {
  mockTMode = "echo";
  render(<HeroDemo />);
  expect(screen.getByText("home.hero.subtitle")).toBeInTheDocument();
});
