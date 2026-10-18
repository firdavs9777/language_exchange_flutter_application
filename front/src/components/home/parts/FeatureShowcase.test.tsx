import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import FeatureShowcase from "./FeatureShowcase";

// `mockTMode` toggles the mocked `t` between echoing its key (proves every
// visible string is routed through i18n) and returning "" (proves the
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

it("renders a card per feature", () => {
  render(<FeatureShowcase />);
  expect(screen.getAllByTestId("feature-card").length).toBeGreaterThanOrEqual(6);
});

it("marks the mobile-only features so the install promise is honest", () => {
  render(<FeatureShowcase />);
  expect(screen.getAllByTestId("feature-mobile-only").length).toBeGreaterThanOrEqual(1);
});

it("does not mark every feature mobile-only", () => {
  render(<FeatureShowcase />);
  const all = screen.getAllByTestId("feature-card").length;
  const mobile = screen.getAllByTestId("feature-mobile-only").length;
  expect(mobile).toBeLessThan(all);
});

// Every card's title, body, and the "In the app" badge must resolve through
// i18n -- proven by making `t` echo the key it was called with.
it("routes every feature's copy through home.features.items.<key>", () => {
  mockTMode = "echo";
  render(<FeatureShowcase />);
  [
    "findPartner",
    "chatTranslate",
    "moments",
    "aiTutor",
    "voiceRooms",
    "gatherings",
  ].forEach((key) => {
    expect(screen.getByText(`home.features.items.${key}.title`)).toBeInTheDocument();
    expect(screen.getByText(`home.features.items.${key}.body`)).toBeInTheDocument();
  });
  expect(screen.getAllByText("home.features.inApp").length).toBeGreaterThanOrEqual(1);
});

// With no translation available, the English copy embedded as the fallback
// must still render.
it("falls back to the English feature copy when a translation is missing", () => {
  render(<FeatureShowcase />);
  const cards = screen.getAllByTestId("feature-card").map((c) => c.textContent || "");
  expect(cards.some((c) => c.includes("Find a partner") && c.includes("Match on the language pair you actually want to trade."))).toBe(true);
  expect(cards.some((c) => c.includes("AI tutor") && c.includes("In the app"))).toBe(true);
});
