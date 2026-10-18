// The 17 non-English locales are webpack chunks now (task D1): only
// eng.json is inlined in the entrypoint, everything else arrives through
// src/utils/i18nLazyBackend.ts the first time someone asks for it.
//
// What has to stay true across that change:
//   - the loader map covers every supported language except the inlined one,
//     and each loader really resolves the right file (ko -> kor.json, ...);
//   - `changeLanguage` still resolves *after* the bundle is in the store, so
//     `t()` never returns a raw key or an empty string in between -- the
//     English fallback holds until the switch completes (no flash);
//   - a language we do not ship falls through to English rather than erroring.
export {};

// Required rather than imported: i18n.ts configures i18next as an import side
// effect, and two things have to be true first. A stored language keeps the
// geo-IP probe (scheduled ~800ms after import) from ever reaching the network,
// and the fetch stub makes it loud if that reasoning is ever wrong.
(global as any).fetch = jest.fn(() => Promise.reject(new Error("network disabled in tests")));
window.localStorage.setItem("i18nextLng", "en");

/* eslint-disable @typescript-eslint/no-var-requires */
const i18nModule = require("./i18n");
const i18n = i18nModule.default;
const SUPPORTED_LANGUAGES: string[] = i18nModule.SUPPORTED_LANGUAGES;
const lazyBackendModule = require("./i18nLazyBackend");
const lazyBackend = lazyBackendModule.default;
const LOCALE_LOADERS = lazyBackendModule.LOCALE_LOADERS;
const {
  prepareForHydration,
  restoreAfterHydration,
  _resetHydrationLanguageForTests,
} = require("./hydrationLanguage");
/* eslint-enable @typescript-eslint/no-var-requires */

const EN_HERO = "Say it badly.";
const KO_HERO = "서툴러도 괜찮아요.";
const JA_HERO = "下手でいい。";
const ZH_TW_HERO = "講得卡卡的也沒關係。";
const ZH_HERO = "说得磕磕巴巴也没关系。";

beforeAll(async () => {
  if (!i18n.isInitialized) {
    await new Promise<void>((resolve) => i18n.on("initialized", () => resolve()));
  }
});

afterEach(() => {
  _resetHydrationLanguageForTests();
});

it("has a loader for exactly the supported languages that are not inlined", () => {
  const expected = SUPPORTED_LANGUAGES.filter((l) => l !== "en")
    .slice()
    .sort();
  expect(Object.keys(LOCALE_LOADERS).sort()).toEqual(expected);
});

it("keeps English in the entrypoint and nothing else", () => {
  // `resources` is the inlined half of the split. If a second language shows
  // up here, ~18 KB gzipped went back into main.js with it.
  expect(Object.keys(i18n.options.resources || {})).toEqual(["en"]);
  expect(i18n.options.partialBundledLanguages).toBe(true);
});

it("resolves every loader to a real translation bundle", async () => {
  const codes = Object.keys(LOCALE_LOADERS);
  const loaded = await Promise.all(codes.map((c) => LOCALE_LOADERS[c]()));
  loaded.forEach((mod, i) => {
    const data: any = (mod as any).default || mod;
    expect(typeof data).toBe("object");
    // Every locale carries the marketing hero, so this is a file-mapping
    // check as much as a shape check: ko must land on kor.json, zh on zho.json.
    expect(typeof data.home.hero.title).toBe("string");
    expect(data.home.hero.title.length).toBeGreaterThan(0);
    if (codes[i] === "ko") expect(data.home.hero.title).toBe(KO_HERO);
  });
});

it("serves English from t() until the Korean bundle has loaded, then Korean", async () => {
  await i18n.changeLanguage("en");
  expect(i18n.t("home.hero.title")).toBe(EN_HERO);

  // The first switch to Korean is the one that really fetches a chunk: no
  // test above has put kor.json into the i18next store.
  expect(i18n.hasResourceBundle("ko", "translation")).toBe(false);
  const pending = i18n.changeLanguage("ko");
  // i18next loads the bundle before it switches, so the old language is still
  // in force here -- not a key, not "" from parseMissingKeyHandler.
  expect(i18n.t("home.hero.title")).toBe(EN_HERO);

  await pending;
  expect(i18n.t("home.hero.title")).toBe(KO_HERO);
  expect(i18n.language).toBe("ko");
});

it("gives Traditional Chinese its own file, not the Simplified one", async () => {
  // `load: "languageOnly"` used to rewrite "_" to "-" and keep only the
  // language part, collapsing zh_TW to zh: locales/zh_TW.json was unreachable
  // and every Traditional visitor silently read Simplified text. The previous
  // version of this test only checked <html lang>, which updateHtmlLang derives
  // from the *requested* code -- so it passed while the file never loaded.
  await i18n.changeLanguage("zh_TW");
  expect(i18n.t("home.hero.title")).toBe(ZH_TW_HERO);
  expect(i18n.resolvedLanguage).toBe("zh_TW");
  expect(document.documentElement.lang).toBe("zh-TW");
  // zho.json is still behind it, so a key zh_TW happens to miss falls back to
  // Simplified rather than to English.
  expect(i18n.languages.indexOf("zh")).toBeGreaterThan(i18n.languages.indexOf("zh_TW"));

  await i18n.changeLanguage("zh");
  expect(i18n.t("home.hero.title")).toBe(ZH_HERO);
  expect(i18n.resolvedLanguage).toBe("zh");
});

it("resolves a region code to its base language's bundle", async () => {
  // There is no ko-KR.json; the backend answers {} for it and "ko" behind it
  // carries the text. `resolvedLanguage` is what the UI must compare against --
  // `language` is the requested code and matches no entry in any menu.
  await i18n.changeLanguage("ko-KR");
  expect(i18n.language).toBe("ko-KR");
  expect(i18n.resolvedLanguage).toBe("ko");
  expect(i18n.t("home.hero.title")).toBe(KO_HERO);
  expect(document.documentElement.lang).toBe("ko-KR");
});

it("updates <html lang> once the switch resolves", async () => {
  await i18n.changeLanguage("en-US");
  expect(i18n.t("home.hero.title")).toBe(EN_HERO);
  expect(i18n.resolvedLanguage).toBe("en");
  expect(document.documentElement.lang).toBe("en-US");
  await i18n.changeLanguage("en");
  expect(document.documentElement.lang).toBe("en");
});

it("falls back to English for a language we do not ship", async () => {
  await i18n.changeLanguage("xx");
  expect(i18n.t("home.hero.title")).toBe(EN_HERO);
});

it("recovers from a chunk that fails to load the first time", async () => {
  // `callback(err, true)` is what buys this: i18next retries only when the
  // callback's data argument is truthy. With `false` the language would be
  // marked dead for the rest of the tab -- changeLanguage would resolve, <html
  // lang> would flip, and the text would stay English forever.
  const real = LOCALE_LOADERS.tr;
  let attempts = 0;
  LOCALE_LOADERS.tr = () => {
    attempts += 1;
    return attempts === 1 ? Promise.reject(new Error("chunk 404")) : real();
  };
  try {
    await i18n.changeLanguage("tr");
    expect(attempts).toBeGreaterThan(1);
    expect(i18n.t("home.hero.title")).toBe("Yanlış söyle.");
  } finally {
    LOCALE_LOADERS.tr = real;
    await i18n.changeLanguage("en");
  }
}, 15000);

it("reads an unknown language as an empty bundle rather than an error", (done) => {
  lazyBackend.read("xx", "translation", (err: any, data: any) => {
    expect(err).toBe(null);
    expect(data).toEqual({});
    done();
  });
});

it("restores the visitor's language after hydration", async () => {
  // The no-flash half of this contract is asserted above, on the switch that
  // really does have to fetch a chunk. Here the bundle is already in the store
  // from the earlier tests, so i18next switches without a round trip -- which
  // is also what a repeat visitor gets. Either way the assertion that matters
  // is the same: t() is English before, the visitor's language after, and
  // never a raw key or the "" that parseMissingKeyHandler returns.
  await i18n.changeLanguage("ja");
  expect(prepareForHydration(i18n)).toBe("ja");
  expect(i18n.language).toBe("en");
  expect(i18n.t("home.hero.title")).toBe(EN_HERO);

  restoreAfterHydration(i18n);
  if (i18n.language !== "ja") {
    await new Promise<void>((resolve) => i18n.on("languageChanged", () => resolve()));
  }
  expect(i18n.language).toBe("ja");
  expect(i18n.t("home.hero.title")).toBe(JA_HERO);
  await i18n.changeLanguage("en");
});
