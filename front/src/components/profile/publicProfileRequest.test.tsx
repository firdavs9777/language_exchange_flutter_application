/**
 * The one test that proves the route is actually public.
 *
 * Everything else in this folder mocks the RTK Query hooks, so a switch back
 * to the protected `/auth/users/:id` would stay green. This renders the real
 * `ProfilePage` for a signed-OUT viewer against a real store and a mocked
 * `fetch`, and asserts the request that leaves is the PUBLIC one — the
 * endpoint that answers an anonymous visitor at all, and the only one that
 * applies the owner's privacy redaction.
 */
import "@testing-library/jest-dom";
import React from "react";
import { render, waitFor } from "@testing-library/react";
import { HelmetProvider } from "react-helmet-async";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "../../store/slices/apiSlice";
import ProfilePage from "./ProfilePage";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const originalFetch = global.fetch;

function mockFetch(): string[] {
  const urls: string[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    urls.push(typeof req === "string" ? req : req.url);
    return new Response(
      JSON.stringify({ success: true, data: { _id: "u2", name: "Minji" } }),
      { status: 200, headers: { "content-type": "application/json" } }
    );
  });
  return urls;
}

afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

function renderSignedOut(path: string) {
  const store = configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      // No session at all: this is the shared-link visitor.
      auth: (state: any = { userInfo: null }) => state,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
  return render(
    <Provider store={store}>
      <HelmetProvider>
        <MemoryRouter initialEntries={[path]}>
          <Routes>
            <Route path="/profile/:userId" element={<ProfilePage />} />
            <Route path="/login" element={<div data-testid="login-screen" />} />
          </Routes>
        </MemoryRouter>
      </HelmetProvider>
    </Provider>
  );
}

it("asks the PUBLIC endpoint for /profile/:userId when nobody is signed in", async () => {
  const urls = mockFetch();
  renderSignedOut("/profile/u2");

  await waitFor(() =>
    expect(urls.some((url) => new URL(url).pathname.slice(-7) === "/public")).toBe(true)
  );

  const profileCalls = urls
    .map((url) => new URL(url).pathname)
    .filter((pathname) => pathname.indexOf("/auth/users/u2") === 0 || pathname.indexOf("/api/v1/auth/users/u2") === 0);

  expect(profileCalls).toContain("/api/v1/auth/users/u2/public");
  // The protected endpoint 401s for an anonymous visitor: it must not be asked.
  expect(profileCalls).not.toContain("/api/v1/auth/users/u2");
});
