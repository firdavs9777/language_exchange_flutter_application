import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import ProfileAbout, { hasAbout } from "./ProfileAbout";

// Translation is off by default (every `t()` returns "", so the components'
// English fallbacks render); one test swaps in a real lookup.
let mockTranslate: (key: string) => string = () => "";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => mockTranslate(key), i18n: { language: "en" } }),
}));

beforeEach(() => {
  mockTranslate = () => "";
});

const LONG_BIO = "a".repeat(300);

it("renders the bio in full when it is short", () => {
  render(<ProfileAbout user={{ bio: "Hi, I teach Korean." }} />);
  expect(screen.getByTestId("about-bio")).toHaveTextContent("Hi, I teach Korean.");
  expect(screen.queryByTestId("about-bio-toggle")).not.toBeInTheDocument();
});

it("collapses a bio past 240 characters behind a Read more control", () => {
  render(<ProfileAbout user={{ bio: LONG_BIO }} />);
  const bio = screen.getByTestId("about-bio");
  expect(bio.textContent && bio.textContent.length).toBeLessThan(300);
  expect(screen.getByTestId("about-bio-toggle")).toBeInTheDocument();
});

it("expands and collapses the bio again on the toggle", () => {
  render(<ProfileAbout user={{ bio: LONG_BIO }} />);
  fireEvent.click(screen.getByTestId("about-bio-toggle"));
  expect(screen.getByTestId("about-bio")).toHaveTextContent(LONG_BIO);
  fireEvent.click(screen.getByTestId("about-bio-toggle"));
  expect(screen.getByTestId("about-bio").textContent).not.toEqual(LONG_BIO);
});

it("shows occupation and school when present", () => {
  render(<ProfileAbout user={{ occupation: "Barista", school: "Yonsei" }} />);
  expect(screen.getByTestId("about-occupation")).toHaveTextContent("Barista");
  expect(screen.getByTestId("about-school")).toHaveTextContent("Yonsei");
});

it("renders one chip per topic and drops the blank ones", () => {
  render(<ProfileAbout user={{ topics: ["Music", "  ", "Travel"] }} />);
  expect(screen.getAllByTestId("about-topic")).toHaveLength(2);
  expect(screen.getByText("Music")).toBeInTheDocument();
});

// The editor renders the same interests through `profile.topics.<key>`; the
// profile used to print the raw key, so "K-Pop" on the form read "kpop" here
// and stayed English in all 18 locales.
it("translates a known topic and falls back to the raw value for a free-text one", () => {
  mockTranslate = (key: string) => (key === "profile.topics.kpop" ? "K-Pop" : "");
  render(<ProfileAbout user={{ topics: ["kpop", "Backgammon"] }} />);
  expect(screen.getByText("K-Pop")).toBeInTheDocument();
  expect(screen.getByText("Backgammon")).toBeInTheDocument();
});

it("shows MBTI and blood type as small facts", () => {
  render(<ProfileAbout user={{ mbti: "INFJ", bloodType: "O" }} />);
  expect(screen.getByTestId("about-mbti")).toHaveTextContent("INFJ");
  expect(screen.getByTestId("about-blood")).toHaveTextContent("O");
});

it("omits the rows the profile has no value for", () => {
  render(<ProfileAbout user={{ occupation: "Barista" }} />);
  expect(screen.getByTestId("about-occupation")).toBeInTheDocument();
  expect(screen.queryByTestId("about-school")).not.toBeInTheDocument();
  expect(screen.queryByTestId("about-bio")).not.toBeInTheDocument();
  expect(screen.queryByTestId("about-mbti")).not.toBeInTheDocument();
});

it("renders nothing at all when every field is empty", () => {
  const { container } = render(
    <ProfileAbout
      user={{ bio: "   ", occupation: "", school: null, topics: [], mbti: "", bloodType: "" }}
    />
  );
  expect(container).toBeEmptyDOMElement();
});

it("renders nothing without a user", () => {
  const { container } = render(<ProfileAbout />);
  expect(container).toBeEmptyDOMElement();
});

// The page draws one shared card around all four info sections, so it must ask
// each whether it has anything BEFORE drawing — a parent cannot see that a
// child returned null. These pin the predicate to the component, so the two
// cannot drift apart.
describe("hasAbout", () => {
  const cases: Array<[string, any, boolean]> = [
    ["nothing at all", {}, false],
    ["a bio", { bio: "hi" }, true],
    ["whitespace only", { bio: "   " }, false],
    ["an occupation", { occupation: "Engineer" }, true],
    ["a school", { school: "KAIST" }, true],
    ["an MBTI", { mbti: "INFJ" }, true],
    ["a blood type", { bloodType: "O" }, true],
    ["topics", { topics: ["Film"] }, true],
    ["empty topics", { topics: [] }, false],
    ["blank topics", { topics: ["  "] }, false],
  ];

  cases.forEach(([label, user, expected]) => {
    it(`agrees with the component for ${label}`, () => {
      expect(hasAbout(user)).toBe(expected);
      // And the component itself renders nothing exactly when the predicate is false.
      const { container } = render(<ProfileAbout user={user} />);
      expect(container.firstChild === null).toBe(!expected);
    });
  });

  it("drops its own card in bare mode", () => {
    // The point of `bare` is that the PAGE draws one card around all four
    // sections. A part that kept its own SurfaceCard would nest a card inside
    // a card, so the assertion that matters is the card's absence.
    const bare = render(<ProfileAbout user={{ bio: "hi" }} bare />);
    expect(bare.container.querySelector("[data-testid='surface-card']")).toBeNull();
    expect(bare.container.querySelector("[data-testid='profile-about']")).toBeInTheDocument();

    bare.unmount();

    const wrapped = render(<ProfileAbout user={{ bio: "hi" }} />);
    expect(wrapped.container.querySelector("[data-testid='surface-card']")).not.toBeNull();
  });
});

describe("intents", () => {
  it("shows learn and meet, in the canonical order", () => {
    render(<ProfileAbout user={{ intents: ["meet", "learn"] }} />);
    const chips = screen.getAllByTestId(/^about-intent-/);
    expect(chips.map((chip) => chip.getAttribute("data-testid"))).toEqual([
      "about-intent-learn",
      "about-intent-meet",
    ]);
  });

  it("never shows dating, even on an own profile read from /auth/me", () => {
    render(<ProfileAbout user={{ intents: ["date", "learn"] }} />);
    expect(screen.queryByTestId("about-intent-date")).not.toBeInTheDocument();
    expect(screen.getByTestId("about-intent-learn")).toBeInTheDocument();
  });

  it("counts toward the card having something to show", () => {
    expect(hasAbout({ intents: ["meet"] })).toBe(true);
  });

  it("does not, when dating is all there is", () => {
    expect(hasAbout({ intents: ["date"] })).toBe(false);
    const { container } = render(<ProfileAbout user={{ intents: ["date"] }} />);
    expect(container).toBeEmptyDOMElement();
  });
});
