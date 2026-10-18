import "@testing-library/jest-dom";
import React from "react";
import { Provider } from "react-redux";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { makeStore } from "../../store";
import ReelPolicyGate, { REEL_POLICY_STORAGE_KEY, hasAcceptedReelPolicy } from "./ReelPolicyGate";

const mockUpdate = jest.fn();
jest.mock("../../store/slices/usersSlice", () => ({
  useUpdateUserInfoMutation: () => [mockUpdate, { isLoading: false }],
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

function renderGate(user: any) {
  const store = makeStore({ auth: { userInfo: { token: "t", user } } });
  const onDeclined = jest.fn();
  render(
    <Provider store={store}>
      <ReelPolicyGate onDeclined={onDeclined}>
        <div data-testid="reels-content" />
      </ReelPolicyGate>
    </Provider>
  );
  return { store, onDeclined };
}

beforeEach(() => {
  localStorage.clear();
  mockUpdate.mockReset();
  mockUpdate.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
});

it("asks first, and shows nothing of the reels behind the dialog", () => {
  renderGate({ _id: "me" });
  expect(screen.getByTestId("reel-policy-dialog")).toHaveTextContent("zero tolerance");
  expect(screen.queryByTestId("reels-content")).not.toBeInTheDocument();
});

it("skips the dialog when the account already accepted (in the app)", () => {
  renderGate({ _id: "me", reelsPolicyAccepted: true });
  expect(screen.getByTestId("reels-content")).toBeInTheDocument();
  expect(screen.queryByTestId("reel-policy-dialog")).not.toBeInTheDocument();
});

it("skips the dialog when this browser already accepted", () => {
  localStorage.setItem(REEL_POLICY_STORAGE_KEY, "1");
  renderGate({ _id: "me" });
  expect(screen.getByTestId("reels-content")).toBeInTheDocument();
});

it("accepting shows the reels, remembers it locally and on the account", async () => {
  const { store } = renderGate({ _id: "me" });
  fireEvent.click(screen.getByTestId("reel-policy-accept"));
  expect(screen.getByTestId("reels-content")).toBeInTheDocument();
  expect(localStorage.getItem(REEL_POLICY_STORAGE_KEY)).toBe("1");
  expect((store.getState() as any).auth.userInfo.user.reelsPolicyAccepted).toBe(true);
  await waitFor(() => expect(mockUpdate).toHaveBeenCalledWith({ reelsPolicyAccepted: true }));
});

it("a failed server save does not take the reels away", async () => {
  mockUpdate.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
  renderGate({ _id: "me" });
  fireEvent.click(screen.getByTestId("reel-policy-accept"));
  await waitFor(() => expect(mockUpdate).toHaveBeenCalled());
  expect(screen.getByTestId("reels-content")).toBeInTheDocument();
});

it("declining leaves", () => {
  const { onDeclined } = renderGate({ _id: "me" });
  fireEvent.click(screen.getByTestId("reel-policy-decline"));
  expect(onDeclined).toHaveBeenCalled();
  expect(localStorage.getItem(REEL_POLICY_STORAGE_KEY)).toBe(null);
});

it("hasAcceptedReelPolicy only trusts a literal true", () => {
  expect(hasAcceptedReelPolicy({ reelsPolicyAccepted: "true" })).toBe(false);
  expect(hasAcceptedReelPolicy(undefined)).toBe(false);
  expect(hasAcceptedReelPolicy({ reelsPolicyAccepted: true })).toBe(true);
});
