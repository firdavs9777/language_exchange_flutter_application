import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, within } from "@testing-library/react";
import AdminAiUsage from "./AdminAiUsage";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockUsage = jest.fn();
const mockLogs = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  useGetAiUsageQuery: (...args: any[]) => mockUsage(...args),
  useGetAiUsageLogsQuery: (...args: any[]) => mockLogs(...args),
}));

const USAGE = {
  total: 87,
  byFeature: [
    { feature: "translate", count: 60 },
    { feature: "chat-assist", count: 27 },
  ],
  byDay: [
    { date: "2026-09-01", count: 40 },
    { date: "2026-09-02", count: 47 },
  ],
};

const LOGS = {
  data: [
    {
      id: "l1",
      user: { id: "u1", name: "Dana", email: "dana@example.com" },
      feature: "translate",
      timestamp: "2026-09-02T10:00:00.000Z",
    },
    {
      id: "l2",
      user: null,
      feature: "chat-assist",
      timestamp: "2026-09-02T11:00:00.000Z",
    },
  ],
  pagination: { total: 2, page: 1, limit: 20, hasMore: false },
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
  mockUsage.mockReset().mockReturnValue(ok(USAGE));
  mockLogs.mockReset().mockReturnValue(ok(LOGS));
});

it("renders the page heading", () => {
  render(<AdminAiUsage />);
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("AI usage");
});

it("defaults to a 30-day range without reading window", () => {
  render(<AdminAiUsage />);
  const [arg] = mockUsage.mock.calls[0];
  expect(typeof arg.from).toBe("string");
  expect(typeof arg.to).toBe("string");
  const days = (new Date(arg.to).getTime() - new Date(arg.from).getTime()) / 86400000;
  expect(Math.round(days)).toBe(30);
});

it("shows the total in a stat card", () => {
  render(<AdminAiUsage />);
  const card = screen.getByText("87").closest('[data-testid="stat-card"]');
  expect(card).not.toBeNull();
});

it("tables usage by feature and by day", () => {
  render(<AdminAiUsage />);
  const byFeature = within(screen.getByTestId("usage-by-feature"));
  expect(byFeature.getByText("translate")).toBeInTheDocument();
  expect(byFeature.getByText("chat-assist")).toBeInTheDocument();
  expect(within(screen.getByTestId("usage-by-day")).getByText("2026-09-01")).toBeInTheDocument();
});

it("renders the logs table with user name/email or anonymous", () => {
  render(<AdminAiUsage />);
  const logs = within(screen.getByTestId("usage-logs"));
  expect(logs.getByText("Dana")).toBeInTheDocument();
  expect(logs.getByText("dana@example.com")).toBeInTheDocument();
  expect(logs.getByText("anonymous")).toBeInTheDocument();
});

it("changes the feature filter and updates both query args", () => {
  render(<AdminAiUsage />);
  fireEvent.change(screen.getByLabelText("Feature"), { target: { value: "translate" } });
  const lastUsageCall = mockUsage.mock.calls[mockUsage.mock.calls.length - 1][0];
  const lastLogsCall = mockLogs.mock.calls[mockLogs.mock.calls.length - 1][0];
  expect(lastUsageCall.feature).toBe("translate");
  expect(lastLogsCall.feature).toBe("translate");
});

it("keeps every feature seen so far in the select, even after filtering narrows byFeature", () => {
  mockUsage.mockImplementation((arg: any) => {
    if (arg && arg.feature === "translate") {
      return ok({ ...USAGE, byFeature: [{ feature: "translate", count: 60 }] });
    }
    return ok(USAGE);
  });
  render(<AdminAiUsage />);
  const select = screen.getByLabelText("Feature") as HTMLSelectElement;
  const optionValues = () => Array.from(select.options).map((o) => o.value);
  expect(optionValues()).toEqual(expect.arrayContaining(["translate", "chat-assist"]));

  fireEvent.change(select, { target: { value: "translate" } });

  // The mock now returns only "translate" in byFeature (as the real backend
  // would once the filter is applied), but the select must not have shed
  // "chat-assist" — that would make it impossible to filter back to it.
  expect(optionValues()).toEqual(expect.arrayContaining(["translate", "chat-assist"]));
});

it("changes the from/to filters and updates the query args", () => {
  render(<AdminAiUsage />);
  fireEvent.change(screen.getByLabelText("From"), { target: { value: "2026-08-01" } });
  fireEvent.change(screen.getByLabelText("To"), { target: { value: "2026-08-31" } });
  const lastUsageCall = mockUsage.mock.calls[mockUsage.mock.calls.length - 1][0];
  expect(lastUsageCall.from).toBe("2026-08-01");
  expect(lastUsageCall.to).toBe("2026-08-31");
});

it("paginates the logs table", () => {
  mockLogs.mockReturnValue(ok({ ...LOGS, pagination: { total: 50, page: 1, limit: 20, hasMore: true } }));
  render(<AdminAiUsage />);
  expect(screen.getByTestId("data-table-next")).not.toBeDisabled();
  fireEvent.click(screen.getByTestId("data-table-next"));
  const lastLogsCall = mockLogs.mock.calls[mockLogs.mock.calls.length - 1][0];
  expect(lastLogsCall.page).toBe(2);
});

it("shows inline errors for the usage and logs sections", () => {
  mockUsage.mockReturnValue(ok(undefined, { isError: true }));
  render(<AdminAiUsage />);
  expect(screen.getAllByText("Couldn't load this section.").length).toBeGreaterThan(0);
});
