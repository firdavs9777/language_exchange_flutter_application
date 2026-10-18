// What happens when a locale chunk will not load, and how the app gets out of it.
//
// The failure is real: a chunk 404s after a mid-session deploy, a captive
// portal eats the request, the tab goes offline mid-click. What must not happen
// is the language going quietly dead for the rest of the session.
//
// Two halves, both pinned here:
//   - the backend reports a final failure as `callback(err, false)`, so i18next
//     records state -1 and writes NOTHING to the store. Reporting `true`
//     instead (i18next's own retry sentinel) ends, once its retries are spent,
//     at `addResourceBundle(lng, ns, true)` -- an empty bundle that makes
//     `hasResourceBundle` true and stops every future read;
//   - switchLanguage() clears that -1 and reloads, which is the only
//     combination that actually re-fetches (measured against i18next 23.7.18:
//     neither a plain changeLanguage nor reloadResources alone will).
//
// A private i18next instance, not the app singleton: "ko" has to be genuinely
// cold, and no other suite's ordering should be able to warm it.
import i18next from "i18next";
import lazyBackend, { LOCALE_LOADERS } from "./i18nLazyBackend";
import { switchLanguage } from "./switchLanguage";
import en from "./locales/eng.json";

const EN_HERO = "Say it badly.";
const KO_HERO = "서툴러도 괜찮아요.";

const makeI18n = () => {
  const inst = i18next.createInstance();
  inst.use(lazyBackend).init({
    lng: "en",
    fallbackLng: "en",
    supportedLngs: ["en", "ko", "ja"],
    nonExplicitSupportedLngs: true,
    resources: { en: { translation: en } },
    partialBundledLanguages: true,
    initImmediate: false,
    parseMissingKeyHandler: () => "",
    returnEmptyString: true,
  });
  return inst;
};

const realKo = LOCALE_LOADERS.ko;
afterEach(() => {
  LOCALE_LOADERS.ko = realKo;
});

describe("the backend's own retry", () => {
  it("retries once and then reports the failure honestly", (done) => {
    let attempts = 0;
    LOCALE_LOADERS.ko = () => {
      attempts += 1;
      return Promise.reject(new Error("chunk 404"));
    };
    lazyBackend.read("ko", "translation", (err: any, data: any) => {
      expect(attempts).toBe(2);
      expect(err).toBeInstanceOf(Error);
      // `false`, never `true`: truthy data is what makes i18next write an empty
      // bundle into the store and never read this language again.
      expect(data).toBe(false);
      done();
    });
  }, 10000);

  it("recovers inside that retry when the failure is transient", (done) => {
    let attempts = 0;
    LOCALE_LOADERS.ko = () => {
      attempts += 1;
      return attempts === 1 ? Promise.reject(new Error("blip")) : realKo();
    };
    lazyBackend.read("ko", "translation", (err: any, data: any) => {
      expect(attempts).toBe(2);
      expect(err).toBe(null);
      expect((data as any).home.hero.title).toBe(KO_HERO);
      done();
    });
  }, 10000);
});

describe("recovering a language whose chunk failed", () => {
  it("re-fetches on the next switch instead of staying on English forever", async () => {
    const i18n = makeI18n();
    let attempts = 0;
    let broken = true;
    LOCALE_LOADERS.ko = () => {
      attempts += 1;
      return broken ? Promise.reject(new Error("chunk 404")) : realKo();
    };

    await switchLanguage(i18n, "ko");
    // The switch settles: i18next resolves even though the load failed.
    expect(attempts).toBe(2); // the backend's one retry, then it gave up
    expect(i18n.t("home.hero.title")).toBe(EN_HERO); // fell through to English
    // The store must be untouched. A bundle here -- even an empty one -- is
    // what would make every later read a no-op.
    expect(i18n.hasResourceBundle("ko", "translation")).toBe(false);
    expect((i18n as any).services.backendConnector.state["ko|translation"]).toBe(-1);

    // A plain changeLanguage cannot recover: queueLoad short-circuits on the
    // negative state. This is the assertion the previous round was missing.
    broken = false;
    const attemptsBeforePlain = attempts;
    await i18n.changeLanguage("ko");
    expect(attempts).toBe(attemptsBeforePlain);
    expect(i18n.t("home.hero.title")).toBe(EN_HERO);

    // switchLanguage does, because it clears the state before reloading.
    await switchLanguage(i18n, "ko");
    expect(attempts).toBeGreaterThan(attemptsBeforePlain);
    expect(i18n.t("home.hero.title")).toBe(KO_HERO);
    expect(i18n.language).toBe("ko");
  }, 15000);
});
