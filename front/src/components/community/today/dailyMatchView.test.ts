import { photoUrl, reasonChips, repliesFast, countryFlag, refreshTimeLabel } from "./dailyMatchView";
import { BASE_URL } from "../../../constants";

const t = (key: string, options?: any) => {
  if (key.startsWith("profile.topics.")) return options && options.defaultValue !== undefined && key === "profile.topics.zzz" ? options.defaultValue : `T(${key})`;
  return options ? `${key}|${JSON.stringify(options)}` : key;
};
const user = { _id: "u1", name: "Ada", language_to_learn: "Korean" };

describe("photoUrl", () => {
  it("uses an absolute URL as-is", () => {
    expect(photoUrl(["https://cdn.x/a.jpg"])).toBe("https://cdn.x/a.jpg");
  });
  it("puts a relative path under the API's /uploads", () => {
    expect(photoUrl(["users/a.jpg"])).toBe(`${BASE_URL}/uploads/users/a.jpg`);
  });
  it("skips empty entries and returns undefined for none", () => {
    expect(photoUrl(["", "https://cdn.x/b.jpg"])).toBe("https://cdn.x/b.jpg");
    expect(photoUrl([])).toBeUndefined();
    expect(photoUrl(undefined)).toBeUndefined();
  });
});

describe("reasonChips", () => {
  it("maps every known code", () => {
    expect(reasonChips(["reciprocal_pair", "same_target_language", "active_today", "same_city"], user, t)).toEqual([
      "communityMain.today.reasonReciprocal",
      'communityMain.today.reasonSameTarget|{"language":"Korean"}',
      "communityMain.today.reasonActiveToday",
      "communityMain.today.reasonSameCity",
    ]);
  });
  it("labels a shared topic through profile.topics", () => {
    expect(reasonChips(["shared_topic:music"], user, t)).toEqual([
      'communityMain.today.reasonSharedTopic|{"topic":"T(profile.topics.music)"}',
    ]);
  });
  it("an unknown topic id shows the id, never the raw key", () => {
    expect(reasonChips(["shared_topic:zzz"], user, t)).toEqual([
      'communityMain.today.reasonSharedTopic|{"topic":"zzz"}',
    ]);
  });
  it("drops codes it does not know", () => {
    expect(reasonChips(["from_the_future", "active_today"], user, t)).toEqual(["communityMain.today.reasonActiveToday"]);
    expect(reasonChips(undefined, user, t)).toEqual([]);
  });
});

describe("repliesFast", () => {
  it("is true from 0.7 up, false below and for null", () => {
    expect(repliesFast(0.7)).toBe(true);
    expect(repliesFast(0.95)).toBe(true);
    expect(repliesFast(0.69)).toBe(false);
    expect(repliesFast(null)).toBe(false);
    expect(repliesFast(undefined)).toBe(false);
  });
});

describe("countryFlag", () => {
  it("turns an English country name into its flag", () => {
    expect(countryFlag("South Korea")).toBe("🇰🇷");
    expect(countryFlag("Japan")).toBe("🇯🇵");
  });
  it("is empty for an unknown or missing country", () => {
    expect(countryFlag("Atlantis")).toBe("");
    expect(countryFlag(undefined)).toBe("");
  });
});

describe("refreshTimeLabel", () => {
  it("formats the refresh moment as a local hour and minute", () => {
    const label = refreshTimeLabel("2026-10-09T00:00:00.000Z", "en");
    expect(label).toMatch(/\d{1,2}:\d{2}/);
  });
  it("is null when missing or unparseable", () => {
    expect(refreshTimeLabel(undefined, "en")).toBeNull();
    expect(refreshTimeLabel("not a date", "en")).toBeNull();
  });
});
