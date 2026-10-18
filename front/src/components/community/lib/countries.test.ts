import { COUNTRY_CODES, countryOptions } from "./countries";

describe("countryOptions", () => {
  it("offers every listed region, each once", () => {
    const options = countryOptions("en");
    expect(options).toHaveLength(COUNTRY_CODES.length);
    expect(new Set(options.map((o) => o.code)).size).toBe(COUNTRY_CODES.length);
  });

  it("sends the English name, whatever language the labels are in", () => {
    const korea = countryOptions("ko").find((o) => o.code === "KR")!;
    expect(korea.value).toBe("South Korea");
    expect(korea.label).toBe("대한민국");
  });

  it("keeps the two Koreas, and Niger and Nigeria, apart -- the point of a list", () => {
    const values = countryOptions("en").map((o) => o.value);
    expect(values).toEqual(expect.arrayContaining(["South Korea", "North Korea", "Niger", "Nigeria"]));
  });

  it("sorts by the label the reader sees", () => {
    const labels = countryOptions("en").map((o) => o.label);
    expect(labels).toEqual([...labels].sort(new Intl.Collator("en").compare));
  });

  it("falls back to English for a locale it cannot use", () => {
    const options = countryOptions("not-a-locale!!");
    expect(options.find((o) => o.code === "JP")!.label).toBe("Japan");
  });

  it("reads the app's own locale ids, underscore and all", () => {
    expect(countryOptions("zh_TW").find((o) => o.code === "KR")!.label).toBe("南韓");
  });
});
