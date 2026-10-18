import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, within } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import ReportsTable from "./ReportsTable";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockList = jest.fn();
const mockReview = jest.fn();
const mockResolve = jest.fn();
const mockDismiss = jest.fn();

jest.mock("../../../store/slices/adminSlice", () => ({
  useListReportsQuery: (...args: any[]) => mockList(...args),
  useReviewReportMutation: () => mockReview(),
  useResolveReportMutation: () => mockResolve(),
  useDismissReportMutation: () => mockDismiss(),
}));

const REPORTS = [
  {
    _id: "r1",
    type: "moment",
    reason: "harassment",
    reportedBy: { _id: "u1", name: "Ana", email: "ana@example.com" },
    reportedUser: { _id: "u2", name: "Bruno", email: "bruno@example.com" },
    status: "pending",
    priority: "high",
    createdAt: "2026-09-22T09:00:00.000Z",
  },
  {
    _id: "r2",
    type: "user",
    reason: "spam",
    reportedBy: { _id: "u3", name: "Chen", email: "chen@example.com" },
    reportedUser: { _id: "u4", name: "Dima", email: "dima@example.com" },
    status: "under_review",
    priority: "low",
    createdAt: "2026-09-21T09:00:00.000Z",
  },
  {
    _id: "r3",
    type: "club",
    reason: "other",
    reportedBy: "u5",
    reportedUser: null,
    status: "resolved",
    priority: "medium",
    createdAt: "2026-09-20T09:00:00.000Z",
  },
];

const ok = (data: any, extra: any = {}) => ({
  data,
  isLoading: false,
  isFetching: false,
  isError: false,
  refetch: jest.fn(),
  ...extra,
});

let reviewTrigger: jest.Mock;
let resolveTrigger: jest.Mock;
let dismissTrigger: jest.Mock;

const renderTable = () =>
  render(
    <MemoryRouter>
      <ReportsTable />
    </MemoryRouter>
  );

const openMenu = (id: string) => fireEvent.click(screen.getByTestId(`report-menu-${id}`));

beforeEach(() => {
  mockList.mockReset().mockReturnValue(ok(REPORTS));
  reviewTrigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
  resolveTrigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
  dismissTrigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
  mockReview.mockReset().mockReturnValue([reviewTrigger, { isLoading: false, reset: jest.fn() }]);
  mockResolve.mockReset().mockReturnValue([resolveTrigger, { isLoading: false, reset: jest.fn() }]);
  mockDismiss.mockReset().mockReturnValue([dismissTrigger, { isLoading: false, reset: jest.fn() }]);
});

it("renders a row per report with the reporter and reported user linked", () => {
  renderTable();
  expect(screen.getAllByTestId("data-row")).toHaveLength(3);
  expect(screen.getByRole("link", { name: "Ana" })).toHaveAttribute("href", "/profile/u1");
  expect(screen.getByRole("link", { name: "Bruno" })).toHaveAttribute("href", "/profile/u2");
  expect(screen.getByText("harassment")).toBeInTheDocument();
});

it("shows the status and priority of each report", () => {
  renderTable();
  const first = screen.getAllByTestId("data-row")[0];
  expect(first).toHaveTextContent("pending");
  expect(first).toHaveTextContent("high");
});

it("filters by status", () => {
  renderTable();
  fireEvent.change(screen.getByTestId("reports-status-filter"), {
    target: { value: "under_review" },
  });
  const last = mockList.mock.calls[mockList.mock.calls.length - 1][0];
  expect(last).toMatchObject({ status: "under_review" });
});

it("filters by target type", () => {
  renderTable();
  fireEvent.change(screen.getByTestId("reports-type-filter"), { target: { value: "club" } });
  const last = mockList.mock.calls[mockList.mock.calls.length - 1][0];
  expect(last).toMatchObject({ targetType: "club" });
});

it("sends no filters by default", () => {
  renderTable();
  const first = mockList.mock.calls[0][0];
  expect(first.status).toBeFalsy();
  expect(first.targetType).toBeFalsy();
});

it("starts a review straight from the row menu", async () => {
  renderTable();
  openMenu("r1");
  fireEvent.click(screen.getByTestId("report-review-r1"));
  await waitFor(() => expect(reviewTrigger).toHaveBeenCalledWith("r1"));
});

it("offers no Start review on a report already under review", () => {
  renderTable();
  openMenu("r2");
  expect(screen.queryByTestId("report-review-r2")).not.toBeInTheDocument();
  expect(screen.getByTestId("report-resolve-r2")).toBeInTheDocument();
});

it("offers no actions on a resolved report", () => {
  renderTable();
  expect(screen.queryByTestId("report-menu-r3")).not.toBeInTheDocument();
});

it("resolves with the chosen moderator action and notes", async () => {
  renderTable();
  openMenu("r1");
  fireEvent.click(screen.getByTestId("report-resolve-r1"));
  fireEvent.change(screen.getByTestId("resolve-action"), { target: { value: "user_banned" } });
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "repeat offender" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(resolveTrigger).toHaveBeenCalledWith({
    id: "r1",
    action: "user_banned",
    notes: "repeat offender",
  });
  await waitFor(() =>
    expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument()
  );
});

it("dismisses with notes", async () => {
  renderTable();
  openMenu("r2");
  fireEvent.click(screen.getByTestId("report-dismiss-r2"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "no violation found" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(dismissTrigger).toHaveBeenCalledWith({ id: "r2", notes: "no violation found" });
  await waitFor(() =>
    expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument()
  );
});

it("resolves with empty notes -- the backend treats them as optional", async () => {
  renderTable();
  openMenu("r1");
  fireEvent.click(screen.getByTestId("report-resolve-r1"));
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(resolveTrigger).toHaveBeenCalledWith({
    id: "r1",
    action: "content_removed",
    notes: "",
  });
  await waitFor(() =>
    expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument()
  );
});

it("dismisses with empty notes -- the backend treats them as optional", async () => {
  renderTable();
  openMenu("r2");
  fireEvent.click(screen.getByTestId("report-dismiss-r2"));
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(dismissTrigger).toHaveBeenCalledWith({ id: "r2", notes: "" });
  await waitFor(() =>
    expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument()
  );
});

it("keeps the resolve dialog open when the mutation fails", async () => {
  resolveTrigger = jest.fn(() => ({ unwrap: () => Promise.reject({ data: { message: "Boom" } }) }));
  mockResolve.mockReturnValue([
    resolveTrigger,
    { isLoading: false, error: { data: { message: "Boom" } }, reset: jest.fn() },
  ]);
  renderTable();
  openMenu("r1");
  fireEvent.click(screen.getByTestId("report-resolve-r1"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "x" } });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() =>
    expect(screen.getByTestId("confirm-dialog-error")).toHaveTextContent("Boom")
  );
});

it("reads a raw envelope as well as an unwrapped array", () => {
  mockList.mockReturnValue(ok({ data: REPORTS }));
  renderTable();
  expect(screen.getAllByTestId("data-row")).toHaveLength(3);
});

it("shows an inline error when the query fails", () => {
  mockList.mockReturnValue(ok(undefined, { isError: true }));
  renderTable();
  expect(screen.getByTestId("section-error")).toBeInTheDocument();
});

it("shows the empty state when there are no reports", () => {
  mockList.mockReturnValue(ok([]));
  renderTable();
  expect(screen.getByText("Nothing to show yet.")).toBeInTheDocument();
});

it("survives an unpopulated reporter", () => {
  renderTable();
  const rows = screen.getAllByTestId("data-row");
  expect(within(rows[2]).queryByRole("link")).toBeNull();
});
