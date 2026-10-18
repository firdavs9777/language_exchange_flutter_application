import { reasonChips } from "./matchReasonChips";

// `t` that proves which key and values were asked for.
const t = (key: string, options?: any) =>
  options ? `${key}|${JSON.stringify(options)}` : key;

describe("reasonChips", () => {
  it("localises each code, language reasons primary", () => {
    expect(
      reasonChips(
        [{ code: "perfect_pair", native: "Korean", learning: "English" }, { code: "online_now" }],
        ["Speaks Korean, learning English", "Online now"],
        t
      )
    ).toEqual([
      { text: 'communityMain.reasons.perfect_pair|{"native":"Korean","learning":"English"}', primary: true },
      { text: "communityMain.reasons.online_now", primary: false },
    ]);
  });

  it("marks native_speaker primary too", () => {
    expect(reasonChips([{ code: "native_speaker", native: "Korean" }], ["Native Korean speaker"], t)[0]).toEqual({
      text: 'communityMain.reasons.native_speaker|{"native":"Korean"}',
      primary: true,
    });
  });

  it("unknown code falls back to the English string at the same index", () => {
    expect(
      reasonChips([{ code: "from_the_future" }, { code: "online_now" }], ["Something new", "Online now"], t)
    ).toEqual(["Something new", { text: "communityMain.reasons.online_now", primary: false }]);
  });

  it("an unknown code with no English counterpart is dropped, not shown as a raw key", () => {
    expect(reasonChips([{ code: "from_the_future" }], [], t)).toEqual([]);
  });

  it("no codes (older server or cached response): the English strings as they are", () => {
    expect(reasonChips(undefined, ["Native Korean speaker", "Online now"], t)).toEqual([
      "Native Korean speaker",
      "Online now",
    ]);
    expect(reasonChips(undefined, undefined, t)).toEqual([]);
  });

  it("a key the locale lacks falls back to the English string", () => {
    const empty = () => "";
    expect(reasonChips([{ code: "online_now" }], ["Online now"], empty)).toEqual([
      { text: "Online now", primary: false },
    ]);
  });
});
