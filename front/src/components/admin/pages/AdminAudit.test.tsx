import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import AdminAudit from "./AdminAudit";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockAuditLog = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  useGetAuditLogQuery: (...args: any[]) => mockAuditLog(...args),
}));

const ENTRIES = {
  data: [
    {
      _id: "a1",
      action: "user_banned",
      moderator: { _id: "m1", name: "Mo Derator", email: "mo@example.com" },
      target: { _id: "t1", name: "Target One", email: "t1@example.com" },
      reason: "spam",
      timestamp: "2026-09-20T10:00:00.000Z",
    },
    {
      _id: "a2",
      action: "club.archive",
      moderator: { _id: "m2", name: "Second Mod", email: "second@example.com" },
      target: null,
      targetEmail: "gone@example.com",
      reason: null,
      timestamp: "2026-09-21T10:00:00.000Z",
    },
  ],
  pagination: { total: 2, page: 1, limit: 50, hasMore: false },
};

const ok = (data: any, extra: any = {}) => ({
  data,
  isLoading: false,
  isFetching: false,
  isError: false,
  refetch: jest.fn(),
  ...extra,
});

beforeEach(() => {
  mockAuditLog.mockReset().mockReturnValue(ok(ENTRIES));
});

it("renders the page heading", () => {
  render(<AdminAudit />);
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Audit log");
});

it("renders audit rows", () => {
  render(<AdminAudit />);
  expect(screen.getByText("user_banned")).toBeInTheDocument();
  expect(screen.getByText("Mo Derator")).toBeInTheDocument();
  expect(screen.getByText("Target One")).toBeInTheDocument();
  expect(screen.getByText("spam")).toBeInTheDocument();
});

it("falls back to the denormalized target email when the target is gone", () => {
  render(<AdminAudit />);
  expect(screen.getByText("gone@example.com")).toBeInTheDocument();
});

it("changes the action filter and updates the query arg", () => {
  render(<AdminAudit />);
  fireEvent.change(screen.getByLabelText("Action"), { target: { value: "user_banned" } });
  const lastCall = mockAuditLog.mock.calls[mockAuditLog.mock.calls.length - 1][0];
  expect(lastCall.action).toBe("user_banned");
});

it("changes the moderatorId and targetId filters and updates the query args", () => {
  render(<AdminAudit />);
  fireEvent.change(screen.getByLabelText("Moderator ID"), { target: { value: "m1" } });
  fireEvent.change(screen.getByLabelText("Target ID"), { target: { value: "t1" } });
  const lastCall = mockAuditLog.mock.calls[mockAuditLog.mock.calls.length - 1][0];
  expect(lastCall.moderatorId).toBe("m1");
  expect(lastCall.targetId).toBe("t1");
});

it("resets to page 1 when a filter changes", () => {
  mockAuditLog.mockReturnValue(ok({ ...ENTRIES, pagination: { total: 100, page: 1, limit: 50, hasMore: true } }));
  render(<AdminAudit />);
  fireEvent.click(screen.getByTestId("data-table-next"));
  fireEvent.change(screen.getByLabelText("Action"), { target: { value: "role_changed" } });
  const lastCall = mockAuditLog.mock.calls[mockAuditLog.mock.calls.length - 1][0];
  expect(lastCall.page).toBe(1);
});

it("shows an inline error when the query fails", () => {
  mockAuditLog.mockReturnValue(ok(undefined, { isError: true }));
  render(<AdminAudit />);
  expect(screen.getByText("Couldn't load this section.")).toBeInTheDocument();
});
