import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import Settings from "./Settings";

const mockNavigate = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("react-toastify", () => ({ Bounce: "bounce", toast: { success: jest.fn(), error: jest.fn() } }));

jest.mock("../../store/slices/usersSlice", () => ({
  useLogoutUserMutation: () => [jest.fn(), { isLoading: false }],
}));

function renderSettings(user: any) {
  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user, token: "t" } }) => state },
  });
  render(
    <Provider store={store}>
      <MemoryRouter>
        <Settings />
      </MemoryRouter>
    </Provider>
  );
}

const openChangePassword = () =>
  fireEvent.click(screen.getByText("Change Password"));

describe("Change password", () => {
  it("opens the in-app form for an account with a password", () => {
    renderSettings({ _id: "me", email: "a@b.c" });
    openChangePassword();
    expect(mockNavigate).toHaveBeenCalledWith("/settings/password");
  });

  // A Google, Apple or Facebook signup has no password to prove. The reset
  // flow is how it sets one at all, so that is where it still goes.
  it.each([["googleId"], ["appleId"], ["facebookId"]])(
    "keeps the reset flow for an account signed up with %s",
    (field) => {
      renderSettings({ _id: "me", [field]: "provider-id" });
      openChangePassword();
      expect(mockNavigate).toHaveBeenCalledWith("/forgot-password");
    }
  );
});
