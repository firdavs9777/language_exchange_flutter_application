// src/utils/i18n.ts
import i18n from "i18next";
import LanguageDetector from "i18next-browser-languagedetector";
import { initReactI18next } from "react-i18next";

import lazyBackend from "./i18nLazyBackend";
import { documentIsPrerendered } from "../seo/prerender/hydrationFlag";

// The only locale that ships inside the entrypoint. The other 17 are
// `import()`ed by src/utils/i18nLazyBackend.ts, one webpack chunk each --
// they were ~306 KB gzipped of a 552 KB main.js that every visitor paid for.
import en from "./locales/eng.json";

export const SUPPORTED_LANGUAGES = [
  "en",
  "ko",
  "zh",
  "zh_TW",
  "ar",
  "de",
  "es",
  "fr",
  "hi",
  "id",
  "it",
  "ja",
  "pt",
  "ru",
  "th",
  "tl",
  "tr",
  "vi",
] as const;

// Map ISO country codes to a primary supported language so we can
// pick a sensible default when the browser locale doesn't match any
// of our resources (or the user is using a generic English locale).
export const COUNTRY_TO_LANGUAGE: Record<string, string> = {
  // Korean
  KR: "ko",
  KP: "ko",
  // Chinese (Simplified)
  CN: "zh",
  SG: "zh",
  // Chinese (Traditional)
  TW: "zh_TW",
  HK: "zh_TW",
  MO: "zh_TW",
  // Japanese
  JP: "ja",
  // Arabic
  SA: "ar",
  AE: "ar",
  EG: "ar",
  QA: "ar",
  KW: "ar",
  JO: "ar",
  LB: "ar",
  IQ: "ar",
  MA: "ar",
  DZ: "ar",
  TN: "ar",
  LY: "ar",
  YE: "ar",
  SY: "ar",
  OM: "ar",
  BH: "ar",
  PS: "ar",
  // German
  DE: "de",
  AT: "de",
  CH: "de",
  LI: "de",
  // Spanish
  ES: "es",
  MX: "es",
  AR: "es",
  CO: "es",
  PE: "es",
  VE: "es",
  CL: "es",
  EC: "es",
  GT: "es",
  CU: "es",
  BO: "es",
  DO: "es",
  HN: "es",
  PY: "es",
  SV: "es",
  NI: "es",
  CR: "es",
  PA: "es",
  UY: "es",
  PR: "es",
  // French
  FR: "fr",
  BE: "fr",
  CA: "fr", // Quebec-ish; not perfect but reasonable for our coverage
  SN: "fr",
  CI: "fr",
  // Hindi
  IN: "hi",
  // Indonesian
  ID: "id",
  // Italian
  IT: "it",
  // Portuguese
  PT: "pt",
  BR: "pt",
  AO: "pt",
  MZ: "pt",
  // Russian
  RU: "ru",
  BY: "ru",
  KZ: "ru",
  KG: "ru",
  // Thai
  TH: "th",
  // Tagalog / Filipino
  PH: "tl",
  // Turkish
  TR: "tr",
  // Vietnamese
  VN: "vi",
  // English defaults
  US: "en",
  GB: "en",
  AU: "en",
  NZ: "en",
  IE: "en",
  ZA: "en",
};

const STORAGE_KEY = "i18nextLng";
const GEO_CACHE_KEY = "i18nextGeoLng";

const readStored = (): string | null => {
  try {
    return window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
};
const writeStored = (value: string | null): void => {
  try {
    if (value === null) window.localStorage.removeItem(STORAGE_KEY);
    else window.localStorage.setItem(STORAGE_KEY, value);
  } catch {
    /* storage unavailable */
  }
};

/**
 * On a prerendered page the first client render must be English, because that
 * is what the server wrote into the HTML.
 *
 * Before the 17 locales became chunks this took care of itself: a Korean
 * visitor's resources were inlined, so `init` resolved synchronously and
 * hydrationLanguage.ts could snapshot "ko", flip to "en" for the first render
 * and put it back in an effect. Now "ko" has to be fetched, so detection at
 * init would leave `i18n.language` unset at hydrate time -- and i18next would
 * then switch languages *during* hydration, which React reports as a text
 * mismatch (#418/#425) and recovers from by throwing the markup away.
 *
 * So: pin the init to the inlined English. No background load starts, nothing
 * changes under React, and hydrationLanguage.ts runs the detector itself after
 * the first commit. A client-rendered entry (no prerendered markup) has no
 * such contract and keeps ordinary detection.
 *
 * The same pin covers Node, where there is no document at all. That is not a
 * detail: scripts/prerender.js runs `renderRoute` through @babel/register, and
 * Node >= 21 exposes `navigator.language` derived from LANG/LC_ALL, which the
 * browser detector happily reads. Left unpinned, a build on a Korean host
 * detected `ko-KR`, started an async `import("./locales/kor.json")`, and let it
 * settle *after* renderRoute's `await changeLanguage("en")` -- so the very
 * first route (`/`, i.e. build/index.html, also the SPA fallback) came out in
 * Korean inside a template declaring lang="en". The prerender must be English
 * on every host, so "no document" pins too.
 */
const PIN_ENGLISH_AT_INIT = typeof document === "undefined" || documentIsPrerendered();
// i18next calls the detector's cacheUserLanguage() for whatever it initialises
// with, so pinning to "en" would overwrite the visitor's stored choice before
// anything has had the chance to read it. Snapshot it here, put it back below.
const storedBeforeInit = PIN_ENGLISH_AT_INIT ? readStored() : null;

i18n
  .use(lazyBackend)
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    lng: PIN_ENGLISH_AT_INIT ? "en" : undefined,
    resources: {
      en: { translation: en },
    },
    // English is bundled, the rest is not: without this i18next treats a
    // populated `resources` as the complete set and never asks the backend.
    partialBundledLanguages: true,
    fallbackLng: "en",
    supportedLngs: SUPPORTED_LANGUAGES as unknown as string[],
    // A region code (ko-KR, en-GB) counts as supported: its base language is.
    nonExplicitSupportedLngs: true,
    // Deliberately NOT `load: "languageOnly"`. That mode rewrites "_" to "-"
    // and keeps only the language part, which collapses zh_TW to zh -- so
    // Traditional Chinese visitors silently got Simplified text and
    // locales/zh_TW.json was unreachable (a 17 KB chunk nothing could fetch).
    // The default resolves zh_TW as ["zh_TW", "zh", "en"]: the Traditional
    // file wins and falls back to the Simplified one for anything it misses.
    // The cost is that a region code adds one `cb(null, {})` round trip
    // through the backend (there is no ko-KR.json), which costs nothing.
    detection: {
      order: ["querystring", "localStorage", "navigator", "htmlTag"],
      lookupQuerystring: "lang",
      lookupLocalStorage: STORAGE_KEY,
      caches: ["localStorage"],
    },
    interpolation: {
      escapeValue: false,
    },
    // Return empty string when a key is missing in every locale so that
    // call sites using `t("key") || "fallback"` actually fall through to
    // their inline English fallback instead of leaking the raw key.
    parseMissingKeyHandler: () => "",
    saveMissing: false,
    returnEmptyString: true,
  });

// `init` above is synchronous for English (it is inlined), so the detector has
// already cached "en" by the time this runs.
if (PIN_ENGLISH_AT_INIT) writeStored(storedBeforeInit);

// Keep <html lang> in sync with the active language so search engines
// and screen readers see the right value.
const updateHtmlLang = (lng?: string) => {
  if (typeof document === "undefined" || !lng) return;
  document.documentElement.lang = lng.replace("_", "-");
};

updateHtmlLang(i18n.language);
i18n.on("languageChanged", updateHtmlLang);

// Geo-IP fallback — runs only when the user has no stored language
// AND the auto-detected one is the generic "en" default. The lookup
// is best-effort: a slow / blocked / failing call never breaks i18n.
const hasUserChoice = () => {
  try {
    return Boolean(window.localStorage.getItem(STORAGE_KEY));
  } catch {
    return false;
  }
};

const cacheGeoChoice = (value: string) => {
  try {
    window.localStorage.setItem(GEO_CACHE_KEY, value);
  } catch {
    // Storage may be unavailable (private mode, etc.) — ignore.
  }
};

const readGeoCache = (): string | null => {
  try {
    return window.localStorage.getItem(GEO_CACHE_KEY);
  } catch {
    return null;
  }
};

const detectByGeoIp = async (): Promise<void> => {
  if (typeof window === "undefined") return;
  if (hasUserChoice()) return;
  if (i18n.language && i18n.language !== "en") return;

  const cached = readGeoCache();
  if (cached) {
    if (cached !== i18n.language) i18n.changeLanguage(cached);
    return;
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3500);
    const response = await fetch("https://ipapi.co/json/", {
      signal: controller.signal,
    });
    clearTimeout(timeout);
    if (!response.ok) return;
    const data = await response.json();
    const country: string | undefined = data?.country_code || data?.country;
    if (!country) return;
    const mapped = COUNTRY_TO_LANGUAGE[country.toUpperCase()];
    if (mapped && mapped !== i18n.language) {
      cacheGeoChoice(mapped);
      i18n.changeLanguage(mapped);
    }
  } catch {
    // Network blocked / offline / aborted — keep current language.
  }
};

// Defer the geo-IP probe until after first paint so it never blocks
// the initial render.
if (typeof window !== "undefined") {
  if ("requestIdleCallback" in window) {
    (window as any).requestIdleCallback(detectByGeoIp, { timeout: 2000 });
  } else {
    setTimeout(detectByGeoIp, 800);
  }
}

export default i18n;
