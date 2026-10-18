import "@testing-library/jest-dom";
import React from "react";
import { Provider } from "react-redux";
import { MemoryRouter, matchRoutes } from "react-router-dom";
import { render, screen } from "@testing-library/react";
import { configureStore } from "@reduxjs/toolkit";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";
import FlagRoute from "../../router/FlagRoute";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
  // routes.tsx pulls in src/utils/i18n.ts, which registers this plugin.
  initReactI18next: { type: "3rdParty", init: () => {} },
}));
// The layout route is never rendered here (matches[1] is the page).
jest.mock("../../App", () => ({ __esModule: true, default: () => null }));
jest.mock("../errors/NotFound", () => () => <div data-testid="not-found" />);
jest.mock("./ReelsGridPage", () => ({ __esModule: true, default: () => <div data-testid="reels-grid" /> }));
jest.mock("./ReelCreatePage", () => ({ __esModule: true, default: () => <div data-testid="reels-create-page" /> }));

const { routes } = require("../../router/routes");

function elementFor(path: string) {
  const matches = matchRoutes(routes, path);
  expect(matches && matches.length).toBe(2);
  return matches![1].route;
}

const store = configureStore({
  reducer: { auth: (s: any = { userInfo: { token: "t", user: { _id: "me" } } }) => s },
});
const renderAt = (path: string) =>
  render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <React.Suspense fallback={<div data-testid="chunk-loading" />}>{elementFor(path).element}</React.Suspense>
      </MemoryRouter>
    </Provider>
  );

it.each(["/reels", "/reels/new"])("%s is a real route gated by webReelsEnabled", (path) => {
  const route = elementFor(path);
  expect(route.path).not.toBe("*");
  expect(route.element.type).toBe(FlagRoute);
  expect(route.element.props.flag).toBe("webReelsEnabled");
});

it.each(["/reels", "/reels/new"])("%s is a 404 while the flag is off", (path) => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderAt(path);
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
  expect(screen.queryByTestId("reels-grid")).not.toBeInTheDocument();
  expect(screen.queryByTestId("reels-create-page")).not.toBeInTheDocument();
});

it("is a 404 when the web flag is on but REELS_ENABLED is off", () => {
  mockAppConfig({ ...ALL_WEB_FLAGS_ON, reelsEnabled: false });
  renderAt("/reels");
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
});

it("renders the page once both switches are on", async () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderAt("/reels");
  expect(await screen.findByTestId("reels-grid")).toBeInTheDocument();
});
