import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { MemoryRouter } from "react-router-dom";
import { makeStore } from "../../store";
import VipSettings from "./VipSettings";

// `t` answers with nothing, so the English fallbacks are what renders.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "" }),
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const originalFetch = global.fetch;
beforeEach(() => {
  (global as any).fetch = jest.fn(() =>
    Promise.resolve(
      new Response(JSON.stringify({ success: true, data: { tier: "regular", isVIP: false } }), {
        status: 200,
        headers: { "content-type": "application/json" },
      })
    )
  );
});
afterEach(() => {
  global.fetch = originalFetch;
});

it("sells only the perks VIP really adds", async () => {
  render(
    <Provider store={makeStore({ auth: { userInfo: { user: { _id: "u1" }, token: "t" } } })}>
      <MemoryRouter>
        <VipSettings />
      </MemoryRouter>
    </Provider>
  );
  expect(await screen.findByText("15 daily matches instead of 6")).toBeInTheDocument();
  expect(screen.getByText("See everyone who viewed you")).toBeInTheDocument();
  expect(screen.getByText("Unlimited AI tutor and roleplay")).toBeInTheDocument();
  expect(screen.getByText("Advanced partner filters (country)")).toBeInTheDocument();
  const text = document.body.textContent || "";
  expect(text).not.toMatch(/Unlimited messages|Priority support|Limited messages per day/);
});
