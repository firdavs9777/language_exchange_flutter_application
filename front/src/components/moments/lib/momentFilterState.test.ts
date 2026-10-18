import {
  decodeMomentFilters,
  encodeMomentFilters,
  mergeMomentParams,
  momentFilterQuery,
  hasMomentFilters,
} from "./momentFilterState";
import { MOMENT_CATEGORIES, MOMENT_MOODS } from "./momentOptions";

const p = (q: string) => new URLSearchParams(q);

describe("momentOptions", () => {
  it("mirrors the server's category and mood enums", () => {
    expect(MOMENT_CATEGORIES).toHaveLength(16);
    expect(MOMENT_CATEGORIES).toContain("language-learning");
    expect(MOMENT_CATEGORIES).toContain("question");
    expect(MOMENT_MOODS.map((m) => m.value)).toEqual([
      "happy", "excited", "grateful", "motivated", "relaxed", "curious",
      "sad", "love", "funny", "thoughtful", "cool", "tired",
    ]);
  });
});

describe("momentFilterState", () => {
  it("reads every key", () => {
    expect(decodeMomentFilters(p("cat=food&lang=ko&mood=happy&tag=kimchi&q=seoul"))).toEqual({
      category: "food", language: "ko", mood: "happy", tag: "kimchi", q: "seoul",
    });
  });

  it("drops values the server would not accept", () => {
    expect(decodeMomentFilters(p("cat=rockets&lang=zz&mood=angry&tag=%20&q=%20%20"))).toEqual({});
  });

  it("caps the search at 100 characters", () => {
    expect(decodeMomentFilters(p(`q=${"a".repeat(150)}`)).q).toHaveLength(100);
  });

  it("writes keys in one canonical order and round-trips", () => {
    const f = { q: "김치", language: "ko", category: "food" };
    const once = encodeMomentFilters(f);
    expect(once.toString()).toBe("cat=food&lang=ko&q=%EA%B9%80%EC%B9%98");
    expect(decodeMomentFilters(once)).toEqual(f);
  });

  it("keeps foreign params when merging", () => {
    const merged = mergeMomentParams(p("utm=x&cat=food"), encodeMomentFilters({ mood: "sad" }));
    expect(merged.toString()).toBe("utm=x&mood=sad");
  });

  it("knows when any filter is set", () => {
    expect(hasMomentFilters({})).toBe(false);
    expect(hasMomentFilters({ q: "x" })).toBe(true);
  });

  it("builds the server query suffix", () => {
    expect(momentFilterQuery(undefined)).toBe("");
    expect(momentFilterQuery({})).toBe("");
    expect(momentFilterQuery({ language: "ko", q: "김 치", tag: "a b" })).toBe(
      "&language=ko&tags=a%20b&q=%EA%B9%80%20%EC%B9%98"
    );
    expect(momentFilterQuery({ category: "food", mood: "happy" })).toBe("&category=food&mood=happy");
  });
});
