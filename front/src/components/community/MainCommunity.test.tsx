import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import { makeStore } from "../../store";
import MainCommunity from "./MainCommunity";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => key }),
  // MemberCard and the sub-nav pull the Trans component in indirectly; a
  // passthrough keeps this test about the auth split, not about copy.
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const originalFetch = global.fetch;
beforeEach(() => {
  (global as any).fetch = jest.fn(() =>
    Promise.resolve(
      new Response(JSON.stringify({ success: true, data: [] }), {
        status: 200,
        headers: { "content-type": "application/json" },
      })
    )
  );
});
afterEach(() => {
  global.fetch = originalFetch;
  jest.clearAllMocks();
});

// Stands in for the login page and prints where the guard sent us.
const LoginProbe = () => {
  const location = useLocation();
  return <div data-testid="login-probe">{location.pathname + location.search}</div>;
};

function renderWith(preloadedState?: any, entry = "/communities") {
  return render(
    <Provider store={makeStore(preloadedState)}>
      <MemoryRouter initialEntries={[entry]}>
        <Routes>
          <Route path="/communities" element={<MainCommunity />} />
          <Route path="/login" element={<LoginProbe />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

const SIGNED_IN = {
  auth: { userInfo: { user: { _id: "u1", name: "Me" }, token: "t" } },
};

// /communities is members-only (owner decision 2026-10-16). It is not
// prerendered any more, so the stored session is in the store from the first
// render (authSlice's getInitialUserInfo) and the guard can decide at once.
it("renders the member-discovery page for a signed-in member on the first render", () => {
  const { container } = renderWith(SIGNED_IN);
  expect(screen.queryByTestId("login-probe")).not.toBeInTheDocument();
  expect(container.querySelector(".community-page")).toBeInTheDocument();
});

it("sends a signed-out visitor to login with a redirect back to /communities", () => {
  const { container } = renderWith({ auth: { userInfo: null } });
  expect(screen.getByTestId("login-probe")).toHaveTextContent("/login?redirect=%2Fcommunities");
  expect(container.querySelector(".community-page")).not.toBeInTheDocument();
});

it("keeps the query string in the redirect", () => {
  renderWith({ auth: { userInfo: null } }, "/communities?tab=all&native=ko");
  const sent = screen.getByTestId("login-probe").textContent || "";
  const redirect = new URLSearchParams(sent.split("?")[1]).get("redirect");
  expect(redirect).toBe("/communities?tab=all&native=ko");
});

// The discovery hooks (members, topics, visitors) must not fire for someone
// who is not signed in -- every one of them is an authenticated route.
it("issues no requests for a signed-out visitor", () => {
  renderWith({ auth: { userInfo: null } });
  expect(global.fetch).not.toHaveBeenCalled();
});
