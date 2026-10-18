import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, act } from "@testing-library/react";
import { mockAppConfig } from "../../../utils/testing/mockWebFlags";
import { setCredentials } from "../../../store/slices/authSlice";
import AppleSignInButton from "./AppleSignInButton";

const events: string[] = [];
const mockDispatch = jest.fn((a: any) => {
  events.push(`dispatch:${a.type}`);
  return a;
});
const mockNavigate = jest.fn((to: any) => {
  events.push(`navigate:${typeof to === "string" ? to : JSON.stringify(to)}`);
});
const mockLogin = jest.fn();
const mockSignIn = jest.fn();
const mockLoad = jest.fn(() => Promise.resolve({}));
let mockServicesId = "com.bananatalk.web";
let mockNonceCounter = 0;

jest.mock("../../../store/slices/appConfigSlice", () =>
  require("../../../utils/testing/mockWebFlags").appConfigSliceMock()
);
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("react-redux", () => ({ useDispatch: () => mockDispatch }));
jest.mock("react-router-dom", () => ({ useNavigate: () => mockNavigate }));
jest.mock("react-toastify", () => ({
  Bounce: {},
  toast: { error: jest.fn(), info: jest.fn(), success: jest.fn() },
}));
jest.mock("../../../store/slices/appleAuthSlice", () => ({
  useAppleWebLoginMutation: () => [mockLogin, { isLoading: false }],
}));
jest.mock("./appleJs", () => {
  const actual = jest.requireActual("./appleJs");
  return {
    ...actual,
    appleServicesId: () => mockServicesId,
    makeNonce: () => `nonce-${++mockNonceCounter}-${"x".repeat(30)}`,
    loadAppleJs: (...a: any[]) => mockLoad(...a),
    signInWithApple: (...a: any[]) => mockSignIn(...a),
  };
});

const { toast } = require("react-toastify");
const { AppleJsError } = require("./appleJs");

const COMPLETE = { _id: "u1", name: "Ada", profileCompleted: true, native_language: "Uzbek", language_to_learn: "Korean", gender: "female" };
const FRESH = { _id: "u2", name: "Apple User", email: "x@privaterelay.appleid.com", profileCompleted: false, isRegistrationComplete: true, gender: "" };

const loginReturns = (body: any) => mockLogin.mockReturnValue({ unwrap: () => Promise.resolve(body) });
const loginFails = (err: any) => mockLogin.mockReturnValue({ unwrap: () => Promise.reject(err) });

beforeEach(() => {
  events.length = 0;
  mockNonceCounter = 0;
  mockServicesId = "com.bananatalk.web";
  mockAppConfig({ webAppleSigninEnabled: true });
  [mockDispatch, mockNavigate, mockLogin, mockSignIn, mockLoad, toast.error, toast.info, toast.success].forEach((m: any) =>
    m.mockClear()
  );
  // CRA sets resetMocks: true, so implementations are (re)installed per test.
  mockDispatch.mockImplementation((a: any) => {
    events.push(`dispatch:${a.type}`);
    return a;
  });
  mockNavigate.mockImplementation((to: any) => {
    events.push(`navigate:${typeof to === "string" ? to : JSON.stringify(to)}`);
  });
  mockLoad.mockImplementation(() => Promise.resolve({}));
});

describe("visibility", () => {
  it("is absent while the flag is off", () => {
    mockAppConfig({ webAppleSigninEnabled: false });
    render(<AppleSignInButton redirect="/" />);
    expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  });
  it("is absent while app-config loads or failed", () => {
    mockAppConfig("loading");
    const { unmount } = render(<AppleSignInButton redirect="/" />);
    expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
    unmount();
    mockAppConfig("error");
    render(<AppleSignInButton redirect="/" />);
    expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  });
  it("is absent with the flag on but no Services ID in the build", () => {
    mockServicesId = "";
    render(<AppleSignInButton redirect="/" />);
    expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  });
  it("shows Apple's label when on, and fetches nothing until the pointer gets near it", () => {
    render(<AppleSignInButton redirect="/" />);
    expect(screen.getByTestId("apple-signin-button")).toHaveTextContent("Continue with Apple");
    expect(mockLoad).not.toHaveBeenCalled();
    fireEvent.pointerEnter(screen.getByTestId("apple-signin-button"));
    expect(mockLoad).toHaveBeenCalledTimes(1);
  });
});

describe("signing in", () => {
  it("sends the same nonce to Apple and to the backend, then signs in and follows ?redirect=", async () => {
    mockSignIn.mockResolvedValue({ identityToken: "id.tok" });
    loginReturns({ success: true, token: "t", refreshToken: "r", user: COMPLETE });
    render(<AppleSignInButton redirect="/moments" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));

    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/moments", { replace: true }));
    const { nonce, state } = mockSignIn.mock.calls[0][0];
    expect(nonce).toMatch(/^[A-Za-z0-9._~-]{16,128}$/);
    expect(state).not.toBe(nonce);
    expect(mockLogin).toHaveBeenCalledWith({ identityToken: "id.tok", nonce });
    expect(mockDispatch).toHaveBeenCalledWith(
      setCredentials({ user: COMPLETE, token: "t", refreshToken: "r", message: "Signed in with Apple" })
    );
    expect(toast.success).toHaveBeenCalled();
  });

  it("passes Apple's first-consent name through to the backend", async () => {
    const user = { name: { firstName: "Ada", lastName: "Lovelace" }, email: "ada@privaterelay.appleid.com" };
    mockSignIn.mockResolvedValue({ identityToken: "id.tok", user });
    loginReturns({ success: true, token: "t", user: COMPLETE });
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(mockLogin).toHaveBeenCalled());
    expect(mockLogin.mock.calls[0][0].user).toEqual(user);
  });

  it("sends a new Apple account to the completion wizard BEFORE storing the session", async () => {
    mockSignIn.mockResolvedValue({ identityToken: "id.tok" });
    loginReturns({ success: true, token: "t", refreshToken: "r", user: FRESH });
    render(<AppleSignInButton redirect="/moments" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));

    await waitFor(() => expect(mockDispatch).toHaveBeenCalled());
    expect(events[0]).toMatch(/^navigate:/);
    expect(events[1]).toBe("dispatch:auth/setCredentials");
    expect(mockNavigate.mock.calls[0][0]).toBe("/register");
    expect(mockNavigate.mock.calls[0][1].state).toMatchObject({
      oauth: true,
      startStep: "languages",
      userData: { _id: "u2", bio: "Hello! I joined using Apple." },
    });
    expect(toast.info).toHaveBeenCalled();
  });

  it("does nothing visible when the user closes the Apple window", async () => {
    mockSignIn.mockResolvedValue(null);
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(screen.getByTestId("apple-signin-button")).not.toBeDisabled());
    expect(mockLogin).not.toHaveBeenCalled();
    expect(toast.error).not.toHaveBeenCalled();
  });

  it("locks the button while signing in (no double popup)", async () => {
    let finish: (v: any) => void = () => {};
    mockSignIn.mockReturnValue(new Promise((r) => (finish = r)));
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    expect(screen.getByTestId("apple-signin-button")).toBeDisabled();
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    expect(mockSignIn).toHaveBeenCalledTimes(1);
    await act(async () => finish(null));
  });

  it("uses a fresh nonce on every attempt", async () => {
    mockSignIn.mockResolvedValue(null);
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(screen.getByTestId("apple-signin-button")).not.toBeDisabled());
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(mockSignIn).toHaveBeenCalledTimes(2));
    expect(mockSignIn.mock.calls[0][0].nonce).not.toBe(mockSignIn.mock.calls[1][0].nonce);
  });
});

describe("failures", () => {
  it("hides itself and says so when the backend answers feature_disabled", async () => {
    mockSignIn.mockResolvedValue({ identityToken: "id.tok" });
    loginFails({ status: 404, data: { success: false, error: "Not found", code: "feature_disabled" } });
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument());
    expect(toast.error).toHaveBeenCalledWith("Sign in with Apple isn't available on the website yet.", expect.anything());
    expect(mockDispatch).not.toHaveBeenCalled();
  });

  it.each([
    [{ status: 503, data: {} }, "Sign in with Apple isn't available right now. Try again later."],
    [{ status: 403, data: { error: "suspended" } }, "This account has been suspended."],
    [{ status: 401, data: {} }, "Couldn't sign in with Apple. Try again."],
  ])("backend %j -> toast, stays visible, not signed in", async (err, text) => {
    mockSignIn.mockResolvedValue({ identityToken: "id.tok" });
    loginFails(err);
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith(text, expect.anything()));
    expect(screen.getByTestId("apple-signin-button")).not.toBeDisabled();
    expect(mockDispatch).not.toHaveBeenCalled();
  });

  it("explains a blocked popup", async () => {
    mockSignIn.mockRejectedValue(new AppleJsError("blocked"));
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() =>
      expect(toast.error).toHaveBeenCalledWith(
        "Your browser blocked the Apple window. Allow pop-ups for banatalk.com and try again.",
        expect.anything()
      )
    );
    expect(mockLogin).not.toHaveBeenCalled();
  });

  it("survives Apple's script failing to load", async () => {
    mockSignIn.mockRejectedValue(new AppleJsError("failed"));
    render(<AppleSignInButton redirect="/" />);
    fireEvent.click(screen.getByTestId("apple-signin-button"));
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith("Couldn't sign in with Apple. Try again.", expect.anything()));
  });

  it("a failed preload is silent (the click retries)", async () => {
    mockLoad.mockReturnValueOnce(Promise.reject(new AppleJsError("failed")));
    render(<AppleSignInButton redirect="/" />);
    fireEvent.focus(screen.getByTestId("apple-signin-button"));
    await Promise.resolve();
    expect(toast.error).not.toHaveBeenCalled();
  });
});
