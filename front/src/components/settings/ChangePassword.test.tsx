import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import ChangePassword, { passwordProblems } from "./ChangePassword";

const mockUpdatePassword = jest.fn();
const mockNavigate = jest.fn();
const mockToastSuccess = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("react-toastify", () => ({
  Bounce: "bounce",
  toast: { success: (...args: any[]) => mockToastSuccess(...args), error: jest.fn() },
}));

jest.mock("../../store/slices/usersSlice", () => ({
  useUpdatePasswordMutation: () => [mockUpdatePassword, { isLoading: false }],
}));

const SESSION = { user: { _id: "me" }, token: "old-token", refreshToken: "r1" };

function renderPage(userInfo: any = SESSION) {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo }, action: any) =>
        action.type === "auth/setCredentials" ? { userInfo: action.payload } : state,
    },
  });
  render(
    <Provider store={store}>
      <MemoryRouter>
        <ChangePassword />
      </MemoryRouter>
    </Provider>
  );
  return store;
}

const fill = (current: string, next: string, confirm: string) => {
  fireEvent.change(screen.getByTestId("password-current"), { target: { value: current } });
  fireEvent.change(screen.getByTestId("password-new"), { target: { value: next } });
  fireEvent.change(screen.getByTestId("password-confirm"), { target: { value: confirm } });
};

beforeEach(() => {
  mockUpdatePassword.mockReturnValue({
    unwrap: () => Promise.resolve({ token: "new-token", refreshToken: "r2", user: { _id: "me" } }),
  });
});

describe("passwordProblems", () => {
  // The backend's own rule, controllers/auth.js updatePassword:
  // /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/
  it("accepts what the server accepts", () => {
    expect(passwordProblems("Abcdefg1")).toEqual([]);
    expect(passwordProblems("Abcdef1@")).toEqual([]);
  });

  it("names each rule that fails", () => {
    expect(passwordProblems("abcdefg1")).toEqual(["upper"]);
    expect(passwordProblems("ABCDEFG1")).toEqual(["lower"]);
    expect(passwordProblems("Abcdefgh")).toEqual(["number"]);
    expect(passwordProblems("Abc1")).toEqual(["length"]);
  });

  it("rejects a character outside the server's set, which it would refuse", () => {
    expect(passwordProblems("Abcdefg1#")).toEqual(["charset"]);
    expect(passwordProblems("Abcdefg1 ")).toEqual(["charset"]);
  });
});

describe("ChangePassword", () => {
  it("keeps Save disabled until all three fields are filled and valid", () => {
    renderPage();
    expect(screen.getByTestId("password-save")).toBeDisabled();
    fill("OldPass1", "NewPass1", "NewPass1");
    expect(screen.getByTestId("password-save")).not.toBeDisabled();
  });

  it("says so when the confirmation does not match, and sends nothing", () => {
    renderPage();
    fill("OldPass1", "NewPass1", "NewPass2");
    expect(screen.getByTestId("password-mismatch")).toBeInTheDocument();
    expect(screen.getByTestId("password-save")).toBeDisabled();
  });

  it("refuses a new password identical to the current one", () => {
    renderPage();
    fill("SamePass1", "SamePass1", "SamePass1");
    expect(screen.getByTestId("password-same")).toBeInTheDocument();
    expect(screen.getByTestId("password-save")).toBeDisabled();
  });

  it("shows which rules the new password still misses", () => {
    renderPage();
    fireEvent.change(screen.getByTestId("password-new"), { target: { value: "abc" } });
    expect(screen.getByTestId("password-rule-upper")).toHaveAttribute("data-met", "false");
    expect(screen.getByTestId("password-rule-lower")).toHaveAttribute("data-met", "true");
  });

  it("sends both passwords, keeps the fresh token, and goes back to settings", async () => {
    const store = renderPage();
    fill("OldPass1", "NewPass1", "NewPass1");
    fireEvent.click(screen.getByTestId("password-save"));

    await waitFor(() =>
      expect(mockUpdatePassword).toHaveBeenCalledWith({
        currentPassword: "OldPass1",
        newPassword: "NewPass1",
      })
    );
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/settings"));
    expect(mockToastSuccess).toHaveBeenCalled();
    const userInfo = (store.getState() as any).auth.userInfo;
    expect(userInfo.token).toBe("new-token");
    expect(userInfo.refreshToken).toBe("r2");
  });

  it("shows the server's own message on a wrong current password, and stays", async () => {
    mockUpdatePassword.mockReturnValue({
      unwrap: () =>
        Promise.reject({ status: 401, data: { message: "Current password is incorrect" } }),
    });
    renderPage();
    fill("Wrong123", "NewPass1", "NewPass1");
    fireEvent.click(screen.getByTestId("password-save"));

    expect(await screen.findByTestId("password-error")).toHaveTextContent(
      "Current password is incorrect"
    );
    expect(mockNavigate).not.toHaveBeenCalled();
  });
});
