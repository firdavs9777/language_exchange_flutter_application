// src/types/react-i18next.d.ts
import "react-i18next";

import en from "./locales/en.json";
import ko from "./locales/kor.json";

declare module "react-i18next" {
  interface CustomTypeOptions {
    defaultNS: "translation";
    resources: {
      en: typeof en;
      ko: typeof ko;
    };
  }
}
