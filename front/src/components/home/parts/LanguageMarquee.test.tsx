import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import LanguageMarquee from "./LanguageMarquee";
import { MARQUEE_LANGUAGES } from "../../../data/marqueeLanguages";

// `mockTMode` toggles the mocked `t` between echoing its key (proves the
// title and caption are routed through i18n) and returning "" (proves the
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

it("renders a chip per language, duplicated for a seamless loop", () => {
  render(<LanguageMarquee />);
  expect(screen.getAllByTestId("marquee-chip")).toHaveLength(MARQUEE_LANGUAGES.length * 2);
});

it("gives every chip a real flag, never the globe", () => {
  render(<LanguageMarquee />);
  screen.getAllByTestId("marquee-chip").forEach((chip) => {
    expect(chip.textContent).not.toContain("🌐");
  });
});

// The app's own _untaggable set cannot represent a written exchange in these,
// so advertising them would promise something the product cannot do.
it("excludes sign languages", () => {
  const lower = MARQUEE_LANGUAGES.map((l) => l.toLowerCase());
  expect(lower.some((l) => l.includes("sign language"))).toBe(false);
});

it("is a curated list, not the whole catalog", () => {
  expect(MARQUEE_LANGUAGES).toHaveLength(24);
});

it("leads with the languages the backend calls popular", () => {
  expect(MARQUEE_LANGUAGES.slice(0, 4)).toEqual(["English", "Korean", "Japanese", "Chinese"]);
});

// The section's title is a real heading, not a styled paragraph.
it("gives the section a real heading", () => {
  const { container } = render(<LanguageMarquee />);
  expect(container.querySelector("h2")).toBeInTheDocument();
});

it("falls back to the English title and caption when a translation is missing", () => {
  render(<LanguageMarquee />);
  expect(screen.getByText("Native speakers of every language you want to learn")).toBeInTheDocument();
  expect(screen.getByText("137 languages, and counting")).toBeInTheDocument();
});

it("routes the title and caption through home.marquee.*", () => {
  mockTMode = "echo";
  render(<LanguageMarquee />);
  expect(screen.getByText("home.marquee.title")).toBeInTheDocument();
  expect(screen.getByText("home.marquee.caption")).toBeInTheDocument();
});
