// src/i18n.ts
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

i18n
  .use(Backend)
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en: { translation: en },
      ko: { translation: ko },
      zh: { translation: zh },
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
      zh_TW: { translation: zh_TW },
    },
    lng: "en",
    fallbackLng: "en",
    interpolation: {
      escapeValue: false,
    },
  });

export default i18n;
