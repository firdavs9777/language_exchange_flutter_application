import i18next from "i18next";
import { prepareForHydration, restoreAfterHydration, _resetHydrationLanguageForTests } from "./hydrationLanguage";

function makeI18n(lng: string) {
  const inst = i18next.createInstance();
  inst.init({
    lng,
    fallbackLng: "en",
    initImmediate: false,
    resources: { en: { translation: { hi: "hi" } }, ko: { translation: { hi: "안녕" } } },
  });
  return inst;
}

beforeEach(() => {
  window.localStorage.clear();
  _resetHydrationLanguageForTests();
});

it("switches to English for the first render and back after commit", () => {
  const i18n = makeI18n("ko");
  expect(prepareForHydration(i18n)).toBe("ko");
  expect(i18n.language).toBe("en");
  restoreAfterHydration(i18n);
  expect(i18n.language).toBe("ko");
});

it("preserves the visitor's stored choice across the English pass", () => {
  window.localStorage.setItem("i18nextLng", "ko");
  const i18n = makeI18n("ko");
  prepareForHydration(i18n);
  expect(window.localStorage.getItem("i18nextLng")).toBe("ko");
});

it("is a no-op for English visitors and for client-rendered pages", () => {
  const i18n = makeI18n("en");
  expect(prepareForHydration(i18n)).toBe("en");
  expect(i18n.language).toBe("en");
  const other = makeI18n("ko");
  restoreAfterHydration(other); // prepare was never called for this instance
  expect(other.language).toBe("ko");
});
