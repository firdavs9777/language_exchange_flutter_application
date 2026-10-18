// src/utils/i18n.ts ends with a best-effort geo-IP probe that hits
// https://ipapi.co/json/ when — and only when — the visitor has never chosen a
// language (`localStorage.i18nextLng` absent).
//
// Before locales were split, i18next ran its own detection at init and handed
// the result to the detector's cacheUserLanguage(), so that key was always
// present by the time the idle callback fired and the probe was inert in
// practice. Pinning a prerendered page's init to English removed the write —
// which would have put a third-party request on every marketing page view for
// every first-time visitor, repeated on each load because a visitor whose
// country maps to the language they already have caches nothing either.
//
// prepareForHydration now records what detection resolved to. This suite is the
// only thing standing between that one line and a silent third-party call.
export {};

jest.useFakeTimers();

const fetchSpy = jest.fn(() => Promise.reject(new Error("network disabled in tests")));
(global as any).fetch = fetchSpy;

// A prerendered page, and a visitor who has never chosen a language. jsdom's
// navigator.language is "en-US", so detection settles on English.
document.body.innerHTML = '<div id="root"><h1>Say it badly.</h1></div>';
window.localStorage.clear();

/* eslint-disable @typescript-eslint/no-var-requires */
const i18n = require("./i18n").default;
const { prepareForHydration, _resetHydrationLanguageForTests } = require("./hydrationLanguage");
/* eslint-enable @typescript-eslint/no-var-requires */

afterAll(() => {
  jest.useRealTimers();
  _resetHydrationLanguageForTests();
});

it("does not leave the English it initialised on in storage", () => {
  // i18n.ts snapshots the (absent) stored value and puts it back, so the
  // detector's cacheUserLanguage("en") is undone.
  expect(i18n.language).toBe("en");
  expect(window.localStorage.getItem("i18nextLng")).toBeNull();
});

it("records the resolved language for a first-time English visitor", () => {
  expect(prepareForHydration(i18n)).toBe("en-US");
  expect(window.localStorage.getItem("i18nextLng")).toBe("en-US");
});

it("never calls ipapi.co once a language has been resolved", () => {
  // The probe is scheduled for ~800ms after import (jsdom has no
  // requestIdleCallback, so i18n.ts takes the setTimeout branch). Run it.
  jest.advanceTimersByTime(10000);
  jest.runOnlyPendingTimers();
  expect(fetchSpy).not.toHaveBeenCalled();
});
