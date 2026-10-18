import { profileCompletion } from "./profileCompletion";

const FULL = {
  name: "Ada",
  gender: "female",
  bio: "Hello",
  native_language: "Korean",
  language_to_learn: "English",
  languageLevel: "B1",
  mbti: "INTJ",
  location: { city: "Seoul" },
  topics: ["music"],
  intents: ["learn"],
};

describe("profileCompletion", () => {
  it("counts the app's ten fields", () => {
    expect(profileCompletion(FULL)).toEqual({ filled: 10, total: 10, percent: 100 });
  });

  it("is zero, not a crash, for nothing at all", () => {
    expect(profileCompletion(undefined)).toEqual({ filled: 0, total: 10, percent: 0 });
    expect(profileCompletion({})).toEqual({ filled: 0, total: 10, percent: 0 });
  });

  it.each([
    ["name", { name: "" }],
    ["gender", { gender: "" }],
    ["bio", { bio: "   " }],
    ["native language", { native_language: "" }],
    ["learning language", { language_to_learn: "" }],
    ["level", { languageLevel: "" }],
    ["MBTI", { mbti: "" }],
    ["address", { location: {} }],
    ["topics", { topics: [] }],
    ["intents", { intents: [] }],
  ])("drops a point for a missing %s", (unused, missing) => {
    expect(profileCompletion({ ...FULL, ...missing }).filled).toBe(9);
  });

  it("takes the address from any of the three fields sign-up may fill", () => {
    expect(profileCompletion({ ...FULL, location: { formattedAddress: "x" } }).filled).toBe(10);
    expect(profileCompletion({ ...FULL, location: { country: "KR" } }).filled).toBe(10);
    expect(profileCompletion({ ...FULL, location: null }).filled).toBe(9);
  });

  it("ignores intents the server would not accept", () => {
    expect(profileCompletion({ ...FULL, intents: ["nonsense"] }).filled).toBe(9);
  });

  it("rounds the percentage", () => {
    expect(profileCompletion({ name: "Ada", gender: "f", bio: "x" }).percent).toBe(30);
  });
});
