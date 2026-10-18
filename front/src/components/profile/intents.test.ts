import {
  INTENTS,
  ageFrom,
  availableIntents,
  isVerifiedAdult,
  normalizeIntents,
  sameIntents,
  toggleIntent,
} from "./intents";

const NOW = new Date("2026-10-06T12:00:00Z");

describe("normalizeIntents", () => {
  it("keeps the enum's values and drops everything else", () => {
    expect(normalizeIntents(["learn", "nonsense", "meet"])).toEqual(["learn", "meet"]);
  });

  it("lowercases and trims, as the server's normalizer does", () => {
    expect(normalizeIntents([" Learn ", "MEET"])).toEqual(["learn", "meet"]);
  });

  it("drops repeats", () => {
    expect(normalizeIntents(["learn", "learn"])).toEqual(["learn"]);
  });

  it("takes a bare string, and anything else as empty", () => {
    expect(normalizeIntents("date")).toEqual(["date"]);
    expect(normalizeIntents(undefined)).toEqual([]);
    expect(normalizeIntents(null)).toEqual([]);
    expect(normalizeIntents(42)).toEqual([]);
    expect(normalizeIntents([null, 7, {}])).toEqual([]);
  });
});

describe("ageFrom", () => {
  // The boundary cases are the reason this is a pure function rather than an
  // inline expression: a birthday today, and the day before an 18th.
  it.each([
    ["the birthday is today", "2008", "10", "6", 18],
    ["the birthday is tomorrow", "2008", "10", "7", 17],
    ["the birthday was yesterday", "2008", "10", "5", 18],
    ["the birthday is next month", "2008", "11", "1", 17],
    ["the birthday was last month", "2008", "9", "30", 18],
  ])("%s", (unused, year, month, day, expected) => {
    expect(ageFrom({ birth_year: year, birth_month: month, birth_day: day }, NOW)).toBe(
      expected
    );
  });

  it("answers null for the birth fields production actually carries", () => {
    // lib/userAge.js: 313 accounts have `birth_year: ""` or no birth fields.
    expect(ageFrom({ birth_year: "", birth_month: "", birth_day: "" }, NOW)).toBeNull();
    expect(ageFrom({}, NOW)).toBeNull();
    expect(ageFrom(null, NOW)).toBeNull();
    expect(ageFrom({ birth_year: "1990" }, NOW)).toBeNull();
  });

  it("answers null for a date that is not one", () => {
    expect(ageFrom({ birth_year: "1990", birth_month: "13", birth_day: "1" }, NOW)).toBeNull();
    expect(ageFrom({ birth_year: "1990", birth_month: "1", birth_day: "0" }, NOW)).toBeNull();
    expect(ageFrom({ birth_year: "1700", birth_month: "1", birth_day: "1" }, NOW)).toBeNull();
    expect(ageFrom({ birth_year: "2030", birth_month: "1", birth_day: "1" }, NOW)).toBeNull();
  });
});

describe("isVerifiedAdult", () => {
  it("is false for an unknown age, not true", () => {
    // The asymmetry is deliberate and is the whole reason the server uses
    // isVerifiedAdult rather than !isMinor.
    expect(isVerifiedAdult({}, NOW)).toBe(false);
    expect(isVerifiedAdult({ birth_year: "" }, NOW)).toBe(false);
  });

  it("is true from the eighteenth birthday, not the day before", () => {
    expect(
      isVerifiedAdult({ birth_year: "2008", birth_month: "10", birth_day: "6" }, NOW)
    ).toBe(true);
    expect(
      isVerifiedAdult({ birth_year: "2008", birth_month: "10", birth_day: "7" }, NOW)
    ).toBe(false);
  });
});

describe("availableIntents", () => {
  it("offers all three to a known adult", () => {
    expect(
      availableIntents({ birth_year: "1990", birth_month: "1", birth_day: "1" }, NOW)
    ).toEqual(INTENTS);
  });

  it("withholds dating from a minor and from an unknown age", () => {
    expect(
      availableIntents({ birth_year: "2015", birth_month: "1", birth_day: "1" }, NOW)
    ).toEqual(["learn", "meet"]);
    expect(availableIntents({}, NOW)).toEqual(["learn", "meet"]);
  });
});

describe("toggleIntent", () => {
  it("adds and removes", () => {
    expect(toggleIntent([], "meet")).toEqual(["meet"]);
    expect(toggleIntent(["meet"], "meet")).toEqual([]);
  });

  it("stores the canonical order, not the tapping order", () => {
    expect(toggleIntent(["date"], "learn")).toEqual(["learn", "date"]);
    expect(toggleIntent(["meet", "learn"], "date")).toEqual(["learn", "meet", "date"]);
  });
});

describe("sameIntents", () => {
  it("disregards order and repeats", () => {
    expect(sameIntents(["learn", "meet"], ["meet", "learn"])).toBe(true);
    expect(sameIntents(["learn", "learn"], ["learn"])).toBe(true);
  });

  it("separates a real change from a new array holding the same thing", () => {
    expect(sameIntents(["learn"], ["learn"])).toBe(true);
    expect(sameIntents(["learn"], ["learn", "meet"])).toBe(false);
    expect(sameIntents([], undefined)).toBe(true);
  });
});
