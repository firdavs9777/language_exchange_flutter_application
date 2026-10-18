import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";
import { APPLE_JS_URL, _resetAppleJsForTests } from "./apple/appleJs";
import Login from "./Login";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-redux", () => ({
  useDispatch: () => jest.fn(),
  useSelector: (sel: any) => sel({ auth: { userInfo: null } }),
}));
jest.mock("../../store/slices/usersSlice", () => ({
  useLoginUserMutation: () => [jest.fn(), { isLoading: false }],
}));
jest.mock("../../store/slices/appleAuthSlice", () => ({
  useAppleWebLoginMutation: () => [jest.fn(), { isLoading: false }],
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const appleScripts = () => document.querySelectorAll(`script[src="${APPLE_JS_URL}"]`).length;

function renderLogin() {
  return render(
    <MemoryRouter initialEntries={["/login?redirect=/moments"]}>
      <Routes>
        <Route path="/login" element={<Login />} />
      </Routes>
    </MemoryRouter>
  );
}

beforeEach(() => {
  _resetAppleJsForTests();
  delete (window as any).AppleID;
  document.querySelectorAll(`script[src="${APPLE_JS_URL}"]`).forEach((s) => s.remove());
  process.env.REACT_APP_APPLE_SERVICES_ID = "com.bananatalk.web";
});
afterAll(() => {
  delete process.env.REACT_APP_APPLE_SERVICES_ID;
});

it("flag off: no Apple button, Google and email sign-in unchanged, nothing fetched from Apple", () => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderLogin();
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  expect(screen.getByText("Continue with Google")).toBeInTheDocument();
  fireEvent.pointerEnter(screen.getByText("Continue with Google"));
  expect(appleScripts()).toBe(0);
});

it("app-config failed: no Apple button", () => {
  mockAppConfig("error");
  renderLogin();
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
});

it("flag on but no Services ID in this build: no Apple button, nothing fetched", () => {
  process.env.REACT_APP_APPLE_SERVICES_ID = "";
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderLogin();
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
  expect(appleScripts()).toBe(0);
});

it("flag on + Services ID: the button sits under Google; Apple's script only on approach", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderLogin();
  const apple = screen.getByTestId("apple-signin-button");
  const google = screen.getByText("Continue with Google").closest("button") as HTMLElement;
  // eslint-disable-next-line no-bitwise
  expect(google.compareDocumentPosition(apple) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  expect(appleScripts()).toBe(0);
  fireEvent.pointerEnter(apple);
  expect(appleScripts()).toBe(1);
});
