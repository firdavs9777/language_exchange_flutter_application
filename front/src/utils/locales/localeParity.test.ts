import fs from "fs";
import path from "path";

// Namespaces introduced by the reach work. Every locale must carry exactly the
// English key set, so a missing translation is a failing test rather than a
// silent fallback. Later tasks append to this list.
const NAMESPACES = ["seo", "notFound", "consent", "admin", "moments_section", "home", "download", "meet", "learnKorean", "communities", "errors", "growth", "profile", "editMoment", "communityMain", "communityDetail", "chatPage", "newChat", "topics", "stories", "card"];

const dir = __dirname;
const files = fs.readdirSync(dir).filter((f) => f.endsWith(".json"));
const read = (f: string) => JSON.parse(fs.readFileSync(path.join(dir, f), "utf8"));
const flatten = (o: any, prefix = ""): string[] =>
  Object.entries(o).flatMap(([k, v]) =>
    v && typeof v === "object" ? flatten(v, `${prefix}${k}.`) : [`${prefix}${k}`]
  );

// i18next plural keys (`foo_one`, `foo_other`, and, for languages whose CLDR
// rule needs them, `foo_zero` / `foo_two` / `foo_few` / `foo_many`) are all
// the same logical string in different locales: English only ever needs
// `one`/`other`, but Russian needs `one`/`few`/`many`/`other` and Arabic needs
// still more. Comparing the raw flattened keys would fail every locale that
// legitimately carries more plural categories than English does, so parity
// is checked on the base key (the plural suffix stripped) instead -- that
// still catches a genuinely missing or misspelled translation.
const PLURAL_SUFFIX = /_(zero|one|two|few|many|other)$/;
const baseKey = (k: string) => k.replace(PLURAL_SUFFIX, "");
const baseKeySet = (keys: string[]) => Array.from(new Set(keys.map(baseKey))).sort();

// Collapsing to the base key is what makes parity work across languages, but
// on its own it hides the opposite mistake: a locale that keeps `foo_one` and
// drops `foo_other` still shows the base key `foo` and passes, while i18next
// has nothing to select for every count that is not one. So each pluralised
// key is also checked for completeness, against the categories the language
// ACTUALLY has -- read from Intl rather than a hand-kept table, so the rule
// cannot drift from CLDR.
const TAGS: Record<string, string> = {
  eng: "en", kor: "ko", zho: "zh", zh_TW: "zh-TW", ar: "ar", de: "de",
  es: "es", fr: "fr", hi: "hi", id: "id", it: "it", ja: "ja", pt: "pt",
  ru: "ru", th: "th", tl: "tl", tr: "tr", vi: "vi",
};

const categoriesFor = (file: string): string[] => {
  const tag = TAGS[file.replace(/\.json$/, "")];
  if (!tag) return ["other"];
  try {
    return new Intl.PluralRules(tag).resolvedOptions().pluralCategories.slice().sort();
  } catch {
    // An Intl build without this language still has to carry `other`.
    return ["other"];
  }
};

/** The plural suffixes a file actually supplies for one base key. */
const suffixesFor = (keys: string[], base: string): string[] =>
  keys
    .filter((k) => baseKey(k) === base && PLURAL_SUFFIX.test(k))
    .map((k) => (k.match(PLURAL_SUFFIX) as RegExpMatchArray)[1])
    .sort();

const en = read("eng.json");

describe.each(NAMESPACES)("locale parity: %s", (ns) => {
  const expected = baseKeySet(flatten(en[ns] || {}));

  it("exists in English", () => {
    expect(expected.length).toBeGreaterThan(0);
  });

  it.each(files)("%s carries the same keys as English", (file) => {
    const value = read(file)[ns];
    expect(value ? baseKeySet(flatten(value)) : null).toEqual(expected);
  });

  it("has 18 locale files", () => {
    expect(files.length).toBe(18);
  });

  // Which base keys English GENUINELY pluralises, i.e. supplies more than one
  // category for.
  //
  // More than one, because the suffix is not always a plural category. The
  // profile list headings use `_own` and `_other` to mean "yours" and "someone
  // else's" and are read with the suffix written into the key
  // (UserListPage.tsx: `t("profile.lists.title_other")`), with no `count`
  // anywhere. Treating those as plurals would demand Arabic supply `few` and
  // `many` forms of "Connections" -- 86 translations nobody will ever select.
  // A key English gives both `one` and `other` is one i18next really will
  // select on, and that is the one every locale owes a complete set.
  const englishKeys = flatten(en[ns] || {});
  const pluralBases = Array.from(
    new Set(englishKeys.filter((k) => PLURAL_SUFFIX.test(k)).map(baseKey))
  )
    .filter((base) => suffixesFor(englishKeys, base).length > 1)
    .sort();

  it.each(files)("%s carries every plural form its language needs", (file) => {
    if (pluralBases.length === 0) return;
    const value = read(file)[ns];
    const keys = value ? flatten(value) : [];
    const required = categoriesFor(file);

    const missing: string[] = [];
    pluralBases.forEach((base) => {
      const have = suffixesFor(keys, base);
      required.forEach((category) => {
        if (have.indexOf(category) === -1) missing.push(`${base}_${category}`);
      });
    });

    expect(missing).toEqual([]);
  });
});
