// The regression from fix round 1 of task D1, pinned.
//
// A visitor with i18nextLng="ko" landing on a *prerendered* page used to get
// React #418/#425 (text content mismatch) and a thrown-away hydration: since
// kor.json became a chunk, detection at init left `i18n.language` unset when
// index.tsx called prepareForHydration, so nothing was marked pending and
// i18next switched to Korean in the middle of hydration instead of after it.
//
// The fix is in two halves, and this suite is the only place both run together
// in their real order: src/utils/i18n.ts pins `lng` to the inlined English
// when the document is prerendered, and hydrationLanguage.ts runs the detector
// itself to find out what the visitor actually wanted.
//
// It lives in its own file because i18n.ts configures i18next as an import
// side effect: the prerendered DOM and the stored language have to exist
// *before* the module is required, which rules out a normal `import`.
export {};

// A prerendered document: #root already has markup, in English.
document.body.innerHTML = '<div id="root"><h1>Say it badly.</h1></div>';
window.localStorage.setItem("i18nextLng", "ko");
// i18n.ts schedules a geo-IP probe ~800ms after import. A stored language keeps
// it inert; the stub makes it loud rather than a real request if that changes.
(global as any).fetch = jest.fn(() => Promise.reject(new Error("network disabled in tests")));

/* eslint-disable @typescript-eslint/no-var-requires */
const i18n = require("./i18n").default;
const hydrationLanguage = require("./hydrationLanguage");
/* eslint-enable @typescript-eslint/no-var-requires */

const EN_HERO = "Say it badly.";
const KO_HERO = "서툴러도 괜찮아요.";

beforeAll(async () => {
  if (!i18n.isInitialized) {
    await new Promise<void>((resolve) => i18n.on("initialized", () => resolve()));
  }
});

it("initialises a prerendered page in English however the visitor is configured", () => {
  expect(i18n.language).toBe("en");
  expect(i18n.t("home.hero.title")).toBe(EN_HERO);
  // Nothing was fetched, so nothing can switch under React mid-hydration.
  expect(i18n.hasResourceBundle("ko", "translation")).toBe(false);
});

it("does not clobber the stored language with the English it initialised on", () => {
  // i18next hands whatever it initialises with to the detector's
  // cacheUserLanguage(); without the snapshot in i18n.ts, one visit to a
  // prerendered page would reset a Korean visitor to English permanently.
  expect(window.localStorage.getItem("i18nextLng")).toBe("ko");
});

it("marks the visitor's language pending and restores it after the commit", async () => {
  expect(hydrationLanguage.prepareForHydration(i18n)).toBe("ko");
  // Still English for the first render -- this is the whole contract.
  expect(i18n.language).toBe("en");
  expect(i18n.t("home.hero.title")).toBe(EN_HERO);
  expect(window.localStorage.getItem("i18nextLng")).toBe("ko");

  hydrationLanguage.restoreAfterHydration(i18n);
  expect(i18n.language).toBe("en");

  await new Promise<void>((resolve) => i18n.on("languageChanged", () => resolve()));
  expect(i18n.language).toBe("ko");
  expect(i18n.t("home.hero.title")).toBe(KO_HERO);
  expect(document.documentElement.lang).toBe("ko");
});

it("never reaches the network for a geo-IP guess", () => {
  expect((global as any).fetch).not.toHaveBeenCalled();
});
