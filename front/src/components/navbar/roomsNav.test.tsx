import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import { apiSlice } from "../../store/slices/apiSlice";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";
import MainNavbar from "./MainNavbar";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en", changeLanguage: jest.fn() } }),
}));
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: { on: jest.fn(), off: jest.fn(), emit: jest.fn() }, isConnected: true, emit: jest.fn() }),
}));

function renderNavbar(user: any = { _id: "me", name: "Me" }) {
  (global as any).fetch = jest.fn(async () => new Response(JSON.stringify({ data: [] }), { status: 200, headers: { "Content-Type": "application/json" } }));
  const store = configureStore({
    reducer: { [apiSlice.reducerPath]: apiSlice.reducer, auth: (s: any = { userInfo: user ? { user } : null }) => s },
    middleware: (g) => g().concat(apiSlice.middleware),
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <MainNavbar />
      </MemoryRouter>
    </Provider>
  );
}

const IDS = ["nav-voice-rooms", "nav-language-rooms", "nav-voice-rooms-mobile", "nav-language-rooms-mobile"];

it("shows no rooms entry while the flags are off", () => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderNavbar();
  IDS.forEach((id) => expect(screen.queryByTestId(id)).not.toBeInTheDocument());
});

it("shows no rooms entry while app-config is loading or failed", () => {
  mockAppConfig("loading");
  const a = renderNavbar();
  IDS.forEach((id) => expect(screen.queryByTestId(id)).not.toBeInTheDocument());
  a.unmount();
  mockAppConfig("error");
  renderNavbar();
  IDS.forEach((id) => expect(screen.queryByTestId(id)).not.toBeInTheDocument());
});

it("shows each entry with its own flag", () => {
  mockAppConfig(Object.assign({}, ALL_WEB_FLAGS_OFF, { webVoiceRoomsEnabled: true }));
  const a = renderNavbar();
  expect(screen.getByTestId("nav-voice-rooms")).toHaveAttribute("href", "/voice-rooms");
  expect(screen.queryByTestId("nav-language-rooms")).not.toBeInTheDocument();
  a.unmount();
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderNavbar();
  expect(screen.getByTestId("nav-language-rooms")).toHaveAttribute("href", "/rooms");
  // The mobile links live in the hamburger menu, which renders only when open.
  fireEvent.click(screen.getByLabelText("Menu"));
  expect(screen.getByTestId("nav-voice-rooms-mobile")).toBeInTheDocument();
  expect(screen.getByTestId("nav-language-rooms-mobile")).toBeInTheDocument();
});

it("never shows them to a signed-out visitor", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderNavbar(null);
  IDS.forEach((id) => expect(screen.queryByTestId(id)).not.toBeInTheDocument());
});
