import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import AdminOverview from "./AdminOverview";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockStats = jest.fn();
const mockActivity = jest.fn();
const mockVisits = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  useGetAdminStatsQuery: (...args: any[]) => mockStats(...args),
  useGetAdminActivityQuery: (...args: any[]) => mockActivity(...args),
  useGetAnalyticsVisitsQuery: (...args: any[]) => mockVisits(...args),
}));

const STATS = {
  total: 1234,
  banned: 5,
  admins: 2,
  vip: 17,
  newToday: 3,
  newThisWeek: 21,
  activeWeek: 456,
  byGender: [],
  byRole: [],
  byMode: [],
  topNativeLanguages: [
    { _id: "English", count: 100 },
    { _id: "Korean", count: 80 },
  ],
  topLearningLanguages: [{ _id: "Spanish", count: 60 }],
  generatedAt: "2026-09-23T00:00:00.000Z",
};

const ACTIVITY = {
  counts: { today: 10, week: 20, month: 30, total: 40 },
  recentlyActive: [
    { id: "u1", name: "Ada Lovelace", email: "ada@example.com", lastActive: "2026-09-22T10:00:00.000Z" },
    { id: "u2", name: "Grace Hopper", email: "grace@example.com", lastActive: "2026-09-21T10:00:00.000Z" },
  ],
};

const VISITS = {
  thisWeek: { totalVisits: 500, uniqueVisitors: 300, newVisitors: 150 },
  lastWeek: { totalVisits: 400, uniqueVisitors: 250 },
  newVisitorRatio: 0.3,
  period: { from: "2026-09-16", to: "2026-09-23" },
};

const ok = (data: any, extra: any = {}) => ({
  data,
  isLoading: false,
  isFetching: false,
  isError: false,
  refetch: jest.fn(),
  ...extra,
});

function cardFor(label: string) {
  const node = screen.getByText(label).closest('[data-testid="stat-card"]');
  if (!node) throw new Error(`no stat card labelled ${label}`);
  return node as HTMLElement;
}

beforeEach(() => {
  mockStats.mockReset().mockReturnValue(ok(STATS));
  mockActivity.mockReset().mockReturnValue(ok(ACTIVITY));
  mockVisits.mockReset().mockReturnValue(ok(VISITS));
});

it("renders the page heading", () => {
  render(<AdminOverview />);
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Overview");
});

it("shows every headline user stat", () => {
  render(<AdminOverview />);
  expect(cardFor("Total users")).toHaveTextContent("1,234");
  expect(cardFor("New today")).toHaveTextContent("3");
  expect(cardFor("New this week")).toHaveTextContent("21");
  expect(cardFor("Active this week")).toHaveTextContent("456");
  expect(cardFor("VIP")).toHaveTextContent("17");
  expect(cardFor("Banned")).toHaveTextContent("5");
  expect(cardFor("Admins")).toHaveTextContent("2");
});

it("compares this week's visits with last week's", () => {
  render(<AdminOverview />);
  const card = cardFor("Visits this week");
  expect(card).toHaveTextContent("500");
  expect(card).toHaveTextContent("400");
  expect(card).toHaveTextContent("+25%");
});

it("does not divide by zero when last week had no visits", () => {
  mockVisits.mockReturnValue(
    ok({ ...VISITS, lastWeek: { totalVisits: 0, uniqueVisitors: 0 } })
  );
  render(<AdminOverview />);
  const card = cardFor("Visits this week");
  expect(card.textContent).not.toContain("Infinity");
  expect(card.textContent).not.toContain("NaN");
});

it("lists the top native and learning languages", () => {
  render(<AdminOverview />);
  expect(screen.getByTestId("top-native-languages")).toHaveTextContent("English");
  expect(screen.getByTestId("top-native-languages")).toHaveTextContent("100");
  expect(screen.getByTestId("top-learning-languages")).toHaveTextContent("Spanish");
});

it("tables the recently active users", () => {
  render(<AdminOverview />);
  expect(screen.getAllByTestId("data-row")).toHaveLength(2);
  expect(screen.getByText("Ada Lovelace")).toBeInTheDocument();
  expect(screen.getByText("grace@example.com")).toBeInTheDocument();
});

it("shows an inline error for the section that failed, and keeps the others", () => {
  mockStats.mockReturnValue(ok(undefined, { isError: true }));
  render(<AdminOverview />);
  expect(screen.getAllByTestId("section-error").length).toBeGreaterThan(0);
  expect(screen.getAllByText("Couldn't load this section.").length).toBeGreaterThan(0);
  // The activity table still rendered.
  expect(screen.getByText("Ada Lovelace")).toBeInTheDocument();
});

it("shows a loading placeholder while a query is in flight", () => {
  mockStats.mockReturnValue(ok(undefined, { isLoading: true }));
  render(<AdminOverview />);
  expect(screen.getAllByTestId("section-loading").length).toBeGreaterThan(0);
});

it("refetches all three queries from the refresh button", () => {
  const statsResult = ok(STATS);
  const activityResult = ok(ACTIVITY);
  const visitsResult = ok(VISITS);
  mockStats.mockReturnValue(statsResult);
  mockActivity.mockReturnValue(activityResult);
  mockVisits.mockReturnValue(visitsResult);
  render(<AdminOverview />);
  fireEvent.click(screen.getByTestId("refresh-button"));
  expect(statsResult.refetch).toHaveBeenCalled();
  expect(activityResult.refetch).toHaveBeenCalled();
  expect(visitsResult.refetch).toHaveBeenCalled();
});

it("renders without crashing when the payloads are empty", () => {
  mockStats.mockReturnValue(ok(undefined));
  mockActivity.mockReturnValue(ok(undefined));
  mockVisits.mockReturnValue(ok(undefined));
  const { container } = render(<AdminOverview />);
  expect(container.textContent).not.toContain("NaN");
  expect(screen.getByRole("heading", { level: 1 })).toBeInTheDocument();
});
