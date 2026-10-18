import { displayCode, languageFlag, stripVariant, toBaseIso6391 } from "./languages";

it("strips a trailing regional parenthetical", () => {
  expect(stripVariant("Chinese (Traditional)")).toBe("Chinese");
  expect(stripVariant("Portuguese (Brazil)")).toBe("Portuguese");
  expect(stripVariant("Haitian Creole")).toBe("Haitian Creole");
});

it("maps names through the app's table", () => {
  expect(displayCode("Korean")).toBe("KO");
  expect(displayCode("English")).toBe("EN");
  expect(displayCode("Chinese (Traditional)")).toBe("ZH");
  expect(displayCode("korean")).toBe("KO");
});

// Deliberate parity quirks -- see the spec, section 3.2.1. The app's own
// doc comment claims "ISO-style, not country-style" and then returns JP for
// Japanese and YUE for Cantonese. The web mirrors that so the two products
// never disagree about the same person. If the app is fixed, these fail by
// design and must be updated in step.
it("reproduces the app's non-ISO codes exactly", () => {
  expect(displayCode("Japanese")).toBe("JP");
  expect(displayCode("Cantonese")).toBe("YUE");
});

it("falls through to a two-letter slice for unmapped names, as the app does", () => {
  expect(displayCode("Persian")).toBe("PE");
});

it("resolves three-letter bases before the two-letter check", () => {
  // Without the fil -> tl branch this returns "FI" -- Finnish, a different
  // language. That is the exact bug this module exists to end.
  expect(displayCode("fil")).toBe("TL");
  expect(displayCode("prs")).toBe("FA");
  expect(displayCode("Filipino")).toBe("TL");
});

it("returns an empty string for empty input", () => {
  expect(displayCode("")).toBe("");
  expect(displayCode("   ")).toBe("");
});

it("resolves untaggable codes to nothing rather than guessing", () => {
  expect(toBaseIso6391("ase")).toBeNull();
  expect(toBaseIso6391("haw")).toBeNull();
  expect(toBaseIso6391("pt-BR")).toBe("pt");
  expect(toBaseIso6391("en")).toBe("en");
  expect(toBaseIso6391("persian")).toBeNull();
});

// The visible half of the old bug: a slice that lands on one of the ten old
// flag keys renders a confidently wrong country.
it("fixes the collisions that rendered the wrong country", () => {
  expect(languageFlag("Estonian")).toBe("🇪🇪");
  expect(languageFlag("Estonian")).not.toBe("🇪🇸");
  expect(languageFlag("Frisian")).toBe("🇳🇱");
  expect(languageFlag("Frisian")).not.toBe("🇫🇷");
});

// The quiet half: these used to return the globe under both the old and the
// new code, so the widened table from Task 2 is what actually moves them.
it("resolves languages the old ten-key table had no flag for", () => {
  expect(languageFlag("Persian")).toBe("🇮🇷");
  expect(languageFlag("Filipino")).toBe("🇵🇭");
});

// The politically load-bearing case. A naive base-code collapse renders the
// PRC flag for every Traditional Chinese and Cantonese speaker.
it("preserves regional variants instead of collapsing them", () => {
  expect(languageFlag("Chinese (Traditional)")).toBe("🇹🇼");
  expect(languageFlag("Cantonese")).toBe("🇭🇰");
  expect(languageFlag("Portuguese (Brazil)")).toBe("🇧🇷");
  expect(languageFlag("English (UK)")).toBe("🇬🇧");
});

it("resolves a plain base name to its designated flag", () => {
  // `zh` is the one code with no base catalog row; CN is what plain
  // "Chinese" renders today, so this preserves existing behaviour.
  expect(languageFlag("Chinese")).toBe("🇨🇳");
  expect(languageFlag("Korean")).toBe("🇰🇷");
});

it("accepts a bare ISO code", () => {
  expect(languageFlag("en")).toBe("🇺🇸");
  expect(languageFlag("ko")).toBe("🇰🇷");
});

it("returns the globe rather than guessing", () => {
  expect(languageFlag("Esperanto")).toBe("🌐"); // the catalog's own answer
  expect(languageFlag("Klingon")).toBe("🌐");
  expect(languageFlag("")).toBe("🌐");
});
