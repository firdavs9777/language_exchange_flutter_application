// Spec §4: while webGatheringsEnabled is false (or app-config is loading or
// failed) the website shows no gatherings/clubs nav entry, every gatherings
// and clubs path is a 404, and no page of the feature is ever loaded.
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route, matchRoutes } from "react-router-dom";
import { apiSlice } from "../../store/slices/apiSlice";
import {
  mockAppConfig,
  ALL_WEB_FLAGS_OFF,
  ALL_WEB_FLAGS_ON,
} from "../../utils/testing/mockWebFlags";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en", changeLanguage: jest.fn() } }),
  initReactI18next: { type: "3rdParty", init: () => {} },
}));
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: { on: jest.fn(), off: jest.fn(), emit: jest.fn(), connected: true }, isConnected: true, emit: jest.fn() }),
}));
jest.mock("../errors/NotFound", () => () => <div data-testid="not-found" />);
// If a gated route ever rendered a page while the flag is off, this would show.
jest.mock("../../router/lazyWithRetry", () => ({
  lazyWithRetry: (key: string) => () => <div data-testid={`page:${key}`} />,
}));

const PATHS = [
  "/gatherings",
  "/gatherings/new",
  "/gatherings/g1",
  "/gatherings/g1/edit",
  "/clubs",
  "/clubs/new",
  "/clubs/c1",
  "/clubs/c1/edit",
];

function store(signedIn: boolean) {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (s: any = { userInfo: signedIn ? { token: "t", user: { _id: "me", name: "Me" } } : null }) => s,
    },
    middleware: (gdm) => gdm().concat(apiSlice.middleware),
  });
}

/** Render the matched leaf route's element on its own (no App shell). */
function renderPath(path: string, signedIn = true) {
  const { routes } = require("../../router/routes");
  const matches = matchRoutes(routes, path)!;
  const leaf: any = matches[matches.length - 1].route;
  return render(
    <Provider store={store(signedIn)}>
      <MemoryRouter initialEntries={[path]}>
        <Routes>
          <Route path={`/${leaf.path}`} element={leaf.element} />
          <Route path="/login" element={<div data-testid="login-page" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

function renderNavbar(signedIn = true) {
  const MainNavbar = require("../navbar/MainNavbar").default;
  (global as any).fetch = jest.fn(async () =>
    new Response(JSON.stringify({ data: [] }), { status: 200, headers: { "Content-Type": "application/json" } })
  );
  return render(
    <Provider store={store(signedIn)}>
      <MemoryRouter>
        <MainNavbar />
      </MemoryRouter>
    </Provider>
  );
}

describe("every gatherings/clubs path resolves to a real route (not the catch-all)", () => {
  it.each(PATHS)("%s", (path) => {
    const { routes } = require("../../router/routes");
    const matches = matchRoutes(routes, path)!;
    expect(matches[matches.length - 1].route.path).not.toBe("*");
  });
});

describe("flag OFF: 404 and no page loaded", () => {
  beforeEach(() => mockAppConfig(ALL_WEB_FLAGS_OFF));
  it.each(PATHS)("%s", (path) => {
    renderPath(path);
    expect(screen.getByTestId("not-found")).toBeInTheDocument();
    expect(screen.queryByTestId(/^page:/)).not.toBeInTheDocument();
  });
});

it("flag on but GATHERINGS_ENABLED off: still a 404", () => {
  mockAppConfig({ ...ALL_WEB_FLAGS_ON, gatheringsEnabled: false });
  renderPath("/gatherings");
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
});

it("app-config failed: 404", () => {
  mockAppConfig("error");
  renderPath("/clubs/c1");
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
});

it("app-config loading: a spinner, never the page", () => {
  mockAppConfig("loading");
  renderPath("/gatherings/g1");
  expect(screen.getByTestId("flag-route-loading")).toBeInTheDocument();
  expect(screen.queryByTestId(/^page:/)).not.toBeInTheDocument();
});

it("flag ON: the page loads for a signed-in user", async () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderPath("/gatherings/g1");
  expect(await screen.findByTestId("page:../components/gatherings/GatheringDetail")).toBeInTheDocument();
});

it("flag ON, signed out: sent to login with a way back", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderPath("/clubs/c1", false);
  expect(screen.getByTestId("login-page")).toBeInTheDocument();
});

describe("navbar", () => {
  it("has no gatherings entry while the flag is off", () => {
    mockAppConfig(ALL_WEB_FLAGS_OFF);
    renderNavbar();
    expect(screen.queryByTestId("nav-gatherings")).not.toBeInTheDocument();
    expect(screen.queryByTestId("nav-gatherings-mobile")).not.toBeInTheDocument();
    expect(document.querySelector('a[href^="/gatherings"], a[href^="/clubs"]')).toBe(null);
  });

  it("shows the entry to signed-in users once the flag is on", () => {
    mockAppConfig(ALL_WEB_FLAGS_ON);
    renderNavbar();
    expect(screen.getByTestId("nav-gatherings")).toHaveAttribute("href", "/gatherings");
  });

  it("never shows it to a signed-out visitor", () => {
    mockAppConfig(ALL_WEB_FLAGS_ON);
    renderNavbar(false);
    expect(screen.queryByTestId("nav-gatherings")).not.toBeInTheDocument();
  });
});
