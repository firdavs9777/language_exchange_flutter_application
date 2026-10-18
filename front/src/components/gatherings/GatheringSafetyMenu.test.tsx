import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import GatheringSafetyMenu from "./GatheringSafetyMenu";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockSuccess = jest.fn();
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: (m: any) => mockSuccess(m), error: (m: any) => mockError(m) },
}));
const mockReport = jest.fn();
jest.mock("../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [mockReport, { isLoading: false }],
}));
jest.mock("../moments/actions/BlockAuthorDialog", () => (props: any) => (
  <div data-testid="block-dialog">
    <button data-testid="block-confirm" onClick={() => props.onBlocked && props.onBlocked()} />
  </div>
));

function renderMenu(props: any = {}, me = "viewer") {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: me } } }) => s } });
  const onBlocked = jest.fn();
  render(
    <Provider store={store}>
      <GatheringSafetyMenu type="gathering" targetId="g1" ownerId="host1" ownerName="Hana" onBlocked={onBlocked} {...props} />
    </Provider>
  );
  return { onBlocked };
}

beforeEach(() => {
  mockReport.mockReset();
  mockReport.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
});

it("renders nothing for the owner", () => {
  renderMenu({}, "host1");
  expect(screen.queryByTestId("safety-menu-button")).not.toBeInTheDocument();
});

it("reports the gathering with type 'gathering' and the host as reportedUser", async () => {
  renderMenu();
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-report"));
  fireEvent.click(screen.getByTestId("safety-report-reason-spam"));
  fireEvent.click(screen.getByTestId("safety-report-submit"));
  await waitFor(() =>
    expect(mockReport).toHaveBeenCalledWith({
      type: "gathering",
      reportId: "g1",
      reportedUser: "host1",
      reason: "spam",
      description: "",
    })
  );
  await waitFor(() => expect(screen.queryByTestId("safety-report-dialog")).not.toBeInTheDocument());
  expect(mockSuccess).toHaveBeenCalled();
});

it("reports a club with type 'club'", async () => {
  renderMenu({ type: "club", targetId: "c1", ownerId: "o1" });
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-report"));
  fireEvent.click(screen.getByTestId("safety-report-reason-harassment"));
  fireEvent.click(screen.getByTestId("safety-report-submit"));
  await waitFor(() => expect(mockReport.mock.calls[0][0]).toEqual(expect.objectContaining({ type: "club", reportId: "c1", reportedUser: "o1" })));
});

it("cannot send a report without a reason", () => {
  renderMenu();
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-report"));
  expect(screen.getByTestId("safety-report-submit")).toBeDisabled();
});

it("says so when the report failed and keeps the dialog open", async () => {
  mockReport.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
  renderMenu();
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-report"));
  fireEvent.click(screen.getByTestId("safety-report-reason-other"));
  fireEvent.click(screen.getByTestId("safety-report-submit"));
  await waitFor(() => expect(mockError).toHaveBeenCalled());
  expect(screen.getByTestId("safety-report-dialog")).toBeInTheDocument();
});

it("blocks the host through the shared block dialog", () => {
  const { onBlocked } = renderMenu();
  fireEvent.click(screen.getByTestId("safety-menu-button"));
  fireEvent.click(screen.getByTestId("safety-block"));
  fireEvent.click(screen.getByTestId("block-confirm"));
  expect(onBlocked).toHaveBeenCalled();
});
