import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import PrivacySettings from "./PrivacySettings";
import { isGaDisabled, setGaDisabled } from "../../analytics/consent";

// The screen is a lazy route behind auth, so the store, the router and the
// mutation hook are stubbed: what is under test is the analytics row, not the
// six profile toggles that were already here.
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
jest.mock("react-router-dom", () => ({ useNavigate: () => () => {} }));
// One stable object: the screen's `useEffect` depends on `userInfo.user`, so a
// fresh literal per call would re-run it on every render for ever.
const mockUserInfo = { user: { privacySettings: {} } };
// A save writes the stored privacySettings back into the session, so the
// screen also dispatches.
jest.mock("react-redux", () => ({ useSelector: () => mockUserInfo, useDispatch: () => jest.fn() }));
jest.mock("../../store/slices/usersSlice", () => ({
  useUpdateUserInfoMutation: () => [() => ({ unwrap: () => Promise.resolve({}) }), { isLoading: false }],
}));
jest.mock("../../analytics/ga", () => ({ GA_MEASUREMENT_ID: "G-TEST", loadGa: jest.fn(), gaEvent: jest.fn() }));
const { loadGa } = require("../../analytics/ga");

beforeEach(() => {
  window.localStorage.clear();
  setGaDisabled(false, "G-TEST");
  document.cookie = "_ga=GA1.1.7.7; path=/";
  (loadGa as jest.Mock).mockClear();
});

it("carries an analytics cookies row that withdraws and restores consent", () => {
  window.localStorage.setItem("bt.consent", "granted");
  render(<PrivacySettings />);

  // The same switch as the six rows above it, not a second control language.
  const row = screen.getByTestId("analytics-consent-row");
  const toggle = row.querySelector("button") as HTMLButtonElement;
  expect(screen.getByText("Analytics cookies")).toBeInTheDocument();
  expect(screen.getByText("Analytics cookies are on.")).toBeInTheDocument();

  fireEvent.click(toggle);
  expect(window.localStorage.getItem("bt.consent")).toBe("denied");
  expect(isGaDisabled("G-TEST")).toBe(true);
  expect(document.cookie).not.toContain("_ga=");
  expect(screen.getByText("Analytics cookies are off.")).toBeInTheDocument();

  (loadGa as jest.Mock).mockClear();
  fireEvent.click(toggle);
  expect(window.localStorage.getItem("bt.consent")).toBe("granted");
  expect(isGaDisabled("G-TEST")).toBe(false);
  expect(loadGa).toHaveBeenCalledTimes(1);
});

it("loads GA on mount for a visitor who accepted on an earlier visit", () => {
  window.localStorage.setItem("bt.consent", "granted");
  render(<PrivacySettings />);
  expect(loadGa).toHaveBeenCalledTimes(1); // the hook's job, not the bar's
});
