import { languageOptions } from "./languageOptions";

const CATALOG = [
  { code: "en", name: "English", nativeName: "English" },
  { code: "ko", name: "Korean", nativeName: "한국어" },
  { code: "ar", name: "Arabic", nativeName: "العربية" },
  { code: "ar-EG", name: "Arabic (Egypt)", nativeName: "العربية (مصر)" },
  { code: "uz", name: "Uzbek", nativeName: "Oʻzbek" },
  { code: "fil", name: "Filipino", nativeName: "Filipino" },
  { code: "tl", name: "Tagalog", nativeName: "Tagalog" },
  { code: "zh-CN", name: "Chinese (Simplified)", nativeName: "简体中文" },
  { code: "ase", name: "American Sign Language", nativeName: "ASL" },
];

it("offers every catalog language once, variants folded into their base", () => {
  const values = languageOptions(CATALOG, "en").map((o) => o.value);
  expect(values).toContain("Uzbek");
  expect(values).toContain("Chinese");
  expect(values.filter((v) => v === "Arabic")).toHaveLength(1);
  expect(values).not.toContain("Arabic (Egypt)");
  expect(values).not.toContain("Chinese (Simplified)");
  expect(values).toContain("American Sign Language");
});

it("keeps the English name as the value and labels it in the reader's language", () => {
  const korean = languageOptions(CATALOG, "ko").find((o) => o.value === "English");
  expect(korean).toBeDefined();
  expect(korean!.label).toBe("영어");
});

it("does not give Filipino and Tagalog the same label", () => {
  const options = languageOptions(CATALOG, "en");
  const fil = options.find((o) => o.value === "Filipino")!;
  const tl = options.find((o) => o.value === "Tagalog")!;
  expect(fil.label).not.toBe(tl.label);
});

it("accepts i18next locale ids (zh_TW) and an empty or broken catalog", () => {
  expect(languageOptions(CATALOG, "zh_TW").length).toBeGreaterThan(0);
  expect(languageOptions(undefined, "en")).toEqual([]);
  expect(languageOptions([{ code: "xx" } as any, null as any], "en")).toEqual([]);
});

it("sorts by the label in the reader's language", () => {
  const labels = languageOptions(CATALOG, "en").map((o) => o.label);
  const sorted = labels.slice().sort((a, b) => new Intl.Collator("en").compare(a, b));
  expect(labels).toEqual(sorted);
});
