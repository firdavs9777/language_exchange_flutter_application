// src/utils/i18n.ts
import i18n from "i18next";
import Backend from "i18next-http-backend";
import LanguageDetector from "i18next-browser-languagedetector";
import { initReactI18next } from "react-i18next";

import en from "./locales/eng.json";
import ko from "./locales/kor.json";
import zh from "./locales/zho.json";
import ar from "./locales/ar.json";
import de from "./locales/de.json";
import es from "./locales/es.json";
import fr from "./locales/fr.json";
import hi from "./locales/hi.json";
import id from "./locales/id.json";
import it from "./locales/it.json";
import ja from "./locales/ja.json";
import pt from "./locales/pt.json";
import ru from "./locales/ru.json";
import th from "./locales/th.json";
import tl from "./locales/tl.json";
import tr from "./locales/tr.json";
import vi from "./locales/vi.json";
import zh_TW from "./locales/zh_TW.json";

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

i18n
  .use(Backend)
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en: { translation: en },
      ko: { translation: ko },
      zh: { translation: zh },
      zh_TW: { translation: zh_TW },
      ar: { translation: ar },
      de: { translation: de },
      es: { translation: es },
      fr: { translation: fr },
      hi: { translation: hi },
      id: { translation: id },
      it: { translation: it },
      ja: { translation: ja },
      pt: { translation: pt },
      ru: { translation: ru },
      th: { translation: th },
      tl: { translation: tl },
      tr: { translation: tr },
      vi: { translation: vi },
    },
    fallbackLng: "en",
    supportedLngs: SUPPORTED_LANGUAGES as unknown as string[],
    nonExplicitSupportedLngs: true,
    load: "languageOnly",
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
