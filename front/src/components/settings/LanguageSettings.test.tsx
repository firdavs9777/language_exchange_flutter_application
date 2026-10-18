import React from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import { apiSlice } from "../../store/slices/apiSlice";
import LanguageSettings from "./LanguageSettings";

// A language switch is a chunk fetch now, so two taps inside one load window
// settle in *network* order -- and i18next has no staleness guard, so the
// slower-arriving language wins and the screen disagrees with what was tapped.
// The component re-applies the last requested code once a switch settles; this
// suite is the only thing that exercises that path with a real promise.
const mockDeferreds: Record<string, { resolve: () => void }> = {};
let mockCurrentLanguage = "en";

// Deferred on purpose: a switch settles only when the test says so, which is
// what makes the out-of-order case reproducible.
const deferredSwitch = (code: string): Promise<void> =>
  new Promise<void>((resolve) => {
    mockDeferreds[code] = {
      resolve: () => {
        mockCurrentLanguage = code;
        resolve();
      },
    };
  });

const mockChangeLanguage = jest.fn(deferredSwitch);

jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (k: string) => k,
    i18n: {
      get language() {
        return mockCurrentLanguage;
      },
      get resolvedLanguage() {
        return mockCurrentLanguage;
      },
      changeLanguage: mockChangeLanguage,
      // Everything the component switches to is already in the store here, so
      // switchLanguage takes its synchronous path and hands back the promise
      // above unchanged. The chunk-loading path has its own suite.
      hasResourceBundle: () => true,
    },
  }),
}));

jest.mock("react-toastify", () => ({
  toast: { success: jest.fn(), error: jest.fn() },
  Bounce: {},
}));

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: () => ({ userInfo: { user: { _id: "me", native_language: "English", language_to_learn: "Korean" } } }),
    },
    middleware: (gdm) => gdm().concat(apiSlice.middleware),
  });
}

// The same language names appear three times on this screen (app language,
// native language, learning language). The app-language grid is rendered
// first, so the first match is the one whose click calls changeLanguage.
const clickAppLanguage = (name: string) => fireEvent.click(screen.getAllByText(name)[0]);

const renderSettings = () =>
  render(
    <Provider store={makeStore()}>
      <MemoryRouter>
        <LanguageSettings />
      </MemoryRouter>
    </Provider>
  );

beforeEach(() => {
  mockCurrentLanguage = "en";
  // CRA sets `resetMocks: true`, which strips the implementation as well as the
  // calls before every test -- without this the mock would return undefined and
  // nothing here would ever be deferred.
  mockChangeLanguage.mockReset();
  mockChangeLanguage.mockImplementation(deferredSwitch);
  for (const key of Object.keys(mockDeferreds)) delete mockDeferreds[key];
  window.localStorage.clear();
});

it("lands on the last language tapped even when an earlier one resolves later", async () => {
  renderSettings();

  // Tap Korean, then Chinese before Korean's chunk has arrived.
  clickAppLanguage("한국어");
  clickAppLanguage("中文");
  expect(mockChangeLanguage).toHaveBeenNthCalledWith(1, "ko");
  expect(mockChangeLanguage).toHaveBeenNthCalledWith(2, "zh");

  // Chinese arrives first...
  mockDeferreds.zh.resolve();
  await waitFor(() => expect(mockCurrentLanguage).toBe("zh"));

  // ...and Korean, the earlier request, lands afterwards. Left alone, i18next
  // keeps it: the page would read Korean while the checkmark says Chinese.
  mockDeferreds.ko.resolve();
  await waitFor(() => expect(mockChangeLanguage).toHaveBeenCalledTimes(3));
  expect(mockChangeLanguage).toHaveBeenNthCalledWith(3, "zh");

  mockDeferreds.zh.resolve();
  await waitFor(() => expect(mockCurrentLanguage).toBe("zh"));
});

it("does not re-apply anything when a single switch settles cleanly", async () => {
  renderSettings();

  clickAppLanguage("한국어");
  mockDeferreds.ko.resolve();
  await waitFor(() => expect(mockCurrentLanguage).toBe("ko"));

  // One call, not two: the guard only fires when the settled language and the
  // last requested one disagree.
  await waitFor(() => expect(mockChangeLanguage).toHaveBeenCalledTimes(1));
  expect(window.localStorage.getItem("i18nextLng")).toBe("ko");
});
