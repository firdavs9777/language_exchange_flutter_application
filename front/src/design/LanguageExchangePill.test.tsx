import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import LanguageExchangePill, { dotsForLevel } from "./LanguageExchangePill";

it("maps CEFR bands to dot counts", () => {
  expect(dotsForLevel("A1")).toBe(1);
  expect(dotsForLevel("a2")).toBe(1);
  expect(dotsForLevel("B1")).toBe(2);
  expect(dotsForLevel("B2")).toBe(2);
  expect(dotsForLevel("C1")).toBe(3);
  expect(dotsForLevel("C2")).toBe(3);
});

// Absent is not zero. languageLevel defaults to null on the backend, so this
// is the COMMON path, not an edge case.
it("returns null for an unknown level rather than zero", () => {
  expect(dotsForLevel(null)).toBeNull();
  expect(dotsForLevel(undefined)).toBeNull();
  expect(dotsForLevel("")).toBeNull();
  expect(dotsForLevel("fluent")).toBeNull();
});

it("renders both language codes", () => {
  render(<LanguageExchangePill nativeLanguage="Korean" learningLanguage="English" />);
  expect(screen.getByTestId("language-pill-native")).toHaveTextContent("KO");
  expect(screen.getByTestId("language-pill-learning")).toHaveTextContent("EN");
});

it("renders exactly three dots when the level is known", () => {
  render(
    <LanguageExchangePill nativeLanguage="Korean" learningLanguage="English" languageLevel="B1" />
  );
  expect(screen.getAllByTestId("language-pill-dot")).toHaveLength(3);
});

// The guard this component exists for.
it("renders NO dots when the level is unknown", () => {
  render(<LanguageExchangePill nativeLanguage="Korean" learningLanguage="English" />);
  expect(screen.queryAllByTestId("language-pill-dot")).toHaveLength(0);

  render(
    <LanguageExchangePill
      nativeLanguage="Korean"
      learningLanguage="English"
      languageLevel={null}
    />
  );
  expect(screen.queryAllByTestId("language-pill-dot")).toHaveLength(0);
});

it("still renders when a code cannot be resolved", () => {
  render(<LanguageExchangePill nativeLanguage="" learningLanguage="English" />);
  expect(screen.getByTestId("language-pill")).toBeInTheDocument();
  expect(screen.getByTestId("language-pill-learning")).toHaveTextContent("EN");
});

it("ships a dark-mode background variant", () => {
  render(<LanguageExchangePill nativeLanguage="Korean" learningLanguage="English" />);
  expect(screen.getByTestId("language-pill").className).toContain(
    "dark:bg-brand/[0.18]"
  );
});
