/**
 * @jest-environment node
 */
// The prerender must render English on every build host.
//
// scripts/prerender.js runs renderRoute through @babel/register, and Node >= 21
// exposes `navigator.language` derived from LANG/LC_ALL -- which is exactly what
// i18next-browser-languagedetector's `navigator` lookup reads. Before this fix
// i18n.ts pinned the init to English only when it found a prerendered *document*,
// and Node has no document at all, so a build on a Korean host detected ko-KR,
// started an async import of kor.json, and let it land after renderRoute's
// `await changeLanguage("en")`: build/index.html came out in Korean inside a
// template declaring lang="en".
//
// Reproduced here by giving Node the navigator it would have under
// LC_ALL=ko_KR.UTF-8, before i18n.ts is imported.
export {};

(global as any).navigator = { language: "ko-KR", languages: ["ko-KR", "ko"] };

/* eslint-disable @typescript-eslint/no-var-requires */
const lazyBackend = require("./i18nLazyBackend");
/* eslint-enable @typescript-eslint/no-var-requires */

// Wrap every loader so an accidental fetch is visible rather than merely slow.
const invoked: string[] = [];
const realLoaders: Record<string, any> = {};
for (const code of Object.keys(lazyBackend.LOCALE_LOADERS)) {
  realLoaders[code] = lazyBackend.LOCALE_LOADERS[code];
  lazyBackend.LOCALE_LOADERS[code] = () => {
    invoked.push(code);
    return realLoaders[code]();
  };
}

/* eslint-disable @typescript-eslint/no-var-requires */
const i18n = require("./i18n").default;
/* eslint-enable @typescript-eslint/no-var-requires */

it("initialises in English on a Korean host and loads no locale chunk", async () => {
  expect(i18n.language).toBe("en");
  expect(invoked).toEqual([]);

  // The failure mode was a *deferred* flip, so a synchronous assertion alone
  // would have passed even before the fix. Let the macrotask queue drain.
  await new Promise<void>((resolve) => setTimeout(resolve, 0));
  expect(i18n.language).toBe("en");
  expect(invoked).toEqual([]);
});

it("still renders English after renderRoute's own changeLanguage('en')", async () => {
  await i18n.changeLanguage("en");
  expect(i18n.language).toBe("en");
  expect(i18n.t("home.hero.title")).toBe("Say it badly.");
  expect(invoked).toEqual([]);
});
