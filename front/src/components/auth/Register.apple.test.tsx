import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";
import Register from "./Register";

jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-redux", () => ({
  useDispatch: () => jest.fn(),
  useSelector: (sel: any) => sel({ auth: { userInfo: null } }),
}));
// Register (and its username/location fields) use many usersSlice hooks; every
// mutation is an idle stub, every lazy query a stub trigger, every query empty.
jest.mock("../../store/slices/usersSlice", () =>
  new Proxy(
    {},
    {
      get: (_target: any, key: any) => {
        const k = String(key);
        if (k === "__esModule") return true;
        if (k.indexOf("useLazy") === 0) return () => [jest.fn(), { isFetching: false }];
        if (/Mutation$/.test(k)) return () => [jest.fn(), { isLoading: false }];
        if (/^use.*Query$/.test(k)) return () => ({ data: undefined, isLoading: false });
        return undefined;
      },
    }
  )
);
jest.mock("../../store/slices/appleAuthSlice", () => ({
  useAppleWebLoginMutation: () => [jest.fn(), { isLoading: false }],
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderAt(entry: any) {
  return render(
    <MemoryRouter initialEntries={[entry]}>
      <Routes>
        <Route path="/register" element={<Register />} />
      </Routes>
    </MemoryRouter>
  );
}

beforeEach(() => {
  process.env.REACT_APP_APPLE_SERVICES_ID = "com.bananatalk.web";
});
afterAll(() => {
  delete process.env.REACT_APP_APPLE_SERVICES_ID;
});

it("flag off: the email step has no Apple button", () => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  renderAt("/register");
  expect(document.querySelector('input[type="email"]')).not.toBe(null); // the email step rendered
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
});

it("flag on: the email step offers Continue with Apple", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderAt("/register");
  expect(screen.getByTestId("apple-signin-button")).toBeInTheDocument();
});

it("never in OAuth completion mode, even with the flag on", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderAt({
    pathname: "/register",
    state: {
      oauth: true,
      startStep: "languages",
      userData: { _id: "u2", name: "Ada", email: "a@privaterelay.appleid.com", bio: "", gender: "other", nativeLanguage: "", languageToLearn: "", birthDate: "2000-01-01" },
    },
  });
  expect(screen.queryByTestId("apple-signin-button")).not.toBeInTheDocument();
});
