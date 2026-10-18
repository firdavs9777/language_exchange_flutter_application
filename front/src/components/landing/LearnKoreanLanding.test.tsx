import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import LearnKoreanLanding from "./LearnKoreanLanding";

// See MeetLanding.test.tsx for why the mocked `t` has two modes.
let mockTMode: "echo" | "fallback" = "fallback";
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => (mockTMode === "echo" ? key : "") }),
}));

beforeEach(() => {
  mockTMode = "fallback";
});

it("leads with the phrase the page targets, in a single h1", () => {
  const { container } = render(<LearnKoreanLanding />);
  const h1s = container.querySelectorAll("h1");
  expect(h1s).toHaveLength(1);
  expect((h1s[0].textContent || "").toLowerCase()).toContain("learn korean by chatting");
});

it("assembles the hero, the steps, the features, the marquee and the closing CTA", () => {
  render(<LearnKoreanLanding />);
  ["hero-demo", "how-it-works", "feature-showcase", "language-marquee", "final-cta"].forEach((id) =>
    expect(screen.getByTestId(id)).toBeInTheDocument()
  );
});

// The demo has to be Korean as it is actually written, and the tutor note has
// to teach the thing every learner gets wrong first (spec §5.4).
it("shows Hangul, its translation, and a tutor note on 존댓말 vs 반말", () => {
  render(<LearnKoreanLanding />);
  const hero = screen.getByTestId("hero-demo").textContent || "";
  expect(hero).toContain("주말에 뭐 했어요?");
  expect(hero).toContain("What did you do this weekend?");
  const note = screen.getByTestId("demo-note").textContent || "";
  expect(note).toContain("존댓말");
  expect(note).toContain("반말");
});

// The supporting line has to agree with the demo below it: on this page the
// learner is the one writing Korean, and the tutor is correcting them.
it("promises the learner writes Korean, which is what the demo shows", () => {
  const { container } = render(<LearnKoreanLanding />);
  const text = container.textContent || "";
  expect(text).toContain("You try it in 한국어");
  expect(text).not.toContain("You write English");
});

// Prerendered at build time: nothing here can know who is awake. "Korean
// speakers are learning your language right now" is a claim about the world;
// "online now" would be a claim about this minute's roster.
it("claims no live availability", () => {
  const { container } = render(<LearnKoreanLanding />);
  expect(container.textContent || "").not.toMatch(/\bonline\b/i);
});

it("says what it is: a language exchange, with native speakers", () => {
  const { container } = render(<LearnKoreanLanding />);
  const text = (container.textContent || "").toLowerCase();
  expect(text).toContain("language exchange");
  expect(text).toContain("native speakers");
});

it("tags every store link as the learn-korean placement", () => {
  render(<LearnKoreanLanding />);
  const hrefs = [
    ...screen.getAllByTestId("store-link-ios"),
    ...screen.getAllByTestId("store-link-android"),
  ].map((a) => a.getAttribute("href") || "");
  expect(hrefs.length).toBe(4);
  hrefs.forEach((href) => expect(href).toContain("utm_campaign=learn-korean"));
});

it("shows the features a Korean learner is buying, not all six", () => {
  render(<LearnKoreanLanding />);
  const cards = screen.getAllByTestId("feature-card").map((c) => c.textContent || "");
  expect(cards.length).toBe(3);
  expect(cards.some((c) => c.includes("AI tutor"))).toBe(true);
  expect(cards.some((c) => c.includes("Gatherings"))).toBe(false);
});

it("routes its own copy through the learnKorean.* namespace", () => {
  mockTMode = "echo";
  const { container } = render(<LearnKoreanLanding />);
  const text = container.textContent || "";
  [
    "learnKorean.hero.title",
    "learnKorean.hero.titleAccent",
    "learnKorean.hero.subtitle",
    "learnKorean.howItWorks.title",
    "learnKorean.howItWorks.steps.1.title",
    "learnKorean.features.title",
    "learnKorean.cta.title",
  ].forEach((key) => expect(text).toContain(key));
});

it("renders to a string on the server with its content intact", () => {
  const html = renderToString(<LearnKoreanLanding />);
  expect((html.match(/<h1[\s>]/g) || []).length).toBe(1);
  expect(html).toContain("Learn Korean by chatting");
  expect(html).toContain("주말에");
  expect(html).not.toContain("undefined");
});
