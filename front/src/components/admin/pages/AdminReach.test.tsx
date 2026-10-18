import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import AdminReach from "./AdminReach";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockEvents = jest.fn();
const mockVisits = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  useGetAnalyticsEventsQuery: (...args: any[]) => mockEvents(...args),
  useGetAnalyticsVisitsQuery: (...args: any[]) => mockVisits(...args),
}));

const EVENTS = {
  byDay: [
    { date: "2026-09-01", pageViews: 120, storeTaps: 12 },
    // Sep 2 and 3 are missing: the backend only returns days that had events.
    { date: "2026-09-04", pageViews: 200, storeTaps: 20 },
  ],
  byPlacement: [
    { placement: "hero", platform: "ios", taps: 7 },
    { placement: "download-page", platform: "android", taps: 31 },
  ],
  topReferrers: [
    { referrer: "https://news.example", count: 44 },
    { referrer: "https://x.example", count: 12 },
  ],
  topPaths: [
    { path: "/", views: 300 },
    { path: "/download", views: 90 },
  ],
};

const VISITS = {
  thisWeek: { totalVisits: 500, uniqueVisitors: 300, newVisitors: 150 },
  lastWeek: { totalVisits: 400, uniqueVisitors: 250 },
  newVisitorRatio: 0.3,
  topCountries: [
    { _id: "KR", country: "KR", visits: 210, uniqueVisitors: 120 },
    { _id: "US", country: "US", visits: 90, uniqueVisitors: 55 },
  ],
  deviceBreakdown: [
    { _id: "mobile", device: "mobile", count: 320 },
    { _id: "desktop", device: "desktop", count: 180 },
  ],
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

beforeEach(() => {
  mockEvents.mockReset().mockReturnValue(ok(EVENTS));
  mockVisits.mockReset().mockReturnValue(ok(VISITS));
});

it("renders the page heading", () => {
  render(<AdminReach />);
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Reach");
});

it("asks for 30 days by default", () => {
  render(<AdminReach />);
  expect(mockEvents).toHaveBeenCalledWith({ days: 30 });
});

it("changes the window when a days button is pressed", () => {
  render(<AdminReach />);
  fireEvent.click(screen.getByRole("button", { name: "90 days" }));
  expect(mockEvents).toHaveBeenLastCalledWith({ days: 90 });
  fireEvent.click(screen.getByRole("button", { name: "7 days" }));
  expect(mockEvents).toHaveBeenLastCalledWith({ days: 7 });
});

it("marks the selected window", () => {
  render(<AdminReach />);
  expect(screen.getByRole("button", { name: "30 days" })).toHaveAttribute("aria-pressed", "true");
  fireEvent.click(screen.getByRole("button", { name: "7 days" }));
  expect(screen.getByRole("button", { name: "7 days" })).toHaveAttribute("aria-pressed", "true");
  expect(screen.getByRole("button", { name: "30 days" })).toHaveAttribute("aria-pressed", "false");
});

it("charts page views and store taps as two lines", () => {
  render(<AdminReach />);
  const paths = screen.getAllByTestId("line-series");
  expect(paths).toHaveLength(2);
  // Sparse byDay is filled out to four contiguous days.
  expect(((paths[0].getAttribute("d") || "").match(/L/g) || []).length).toBe(3);
});

it("strokes the two series in the readable brand tokens", () => {
  render(<AdminReach />);
  const strokes = screen.getAllByTestId("line-series").map((p) => p.getAttribute("stroke"));
  expect(strokes).toEqual(["#00BFA5", "#C9A415"]);
});

it("tables taps by placement and platform, highest first", () => {
  render(<AdminReach />);
  const table = screen.getByTestId("taps-by-placement");
  const rows = table.querySelectorAll('[data-testid="data-row"]');
  expect(rows).toHaveLength(2);
  expect(rows[0]).toHaveTextContent("download-page");
  expect(rows[0]).toHaveTextContent("android");
  expect(rows[0]).toHaveTextContent("31");
  expect(rows[1]).toHaveTextContent("hero");
});

it("tables the top referrers and paths", () => {
  render(<AdminReach />);
  expect(screen.getByTestId("top-referrers")).toHaveTextContent("https://news.example");
  expect(screen.getByTestId("top-referrers")).toHaveTextContent("44");
  expect(screen.getByTestId("top-paths")).toHaveTextContent("/download");
  expect(screen.getByTestId("top-paths")).toHaveTextContent("90");
});

it("tables countries and devices from the visit stats", () => {
  render(<AdminReach />);
  expect(screen.getByTestId("top-countries")).toHaveTextContent("KR");
  expect(screen.getByTestId("top-countries")).toHaveTextContent("210");
  expect(screen.getByTestId("device-breakdown")).toHaveTextContent("mobile");
  expect(screen.getByTestId("device-breakdown")).toHaveTextContent("320");
});

it("shows the new-visitor ratio as a percentage", () => {
  render(<AdminReach />);
  const card = screen.getByText("New visitors").closest('[data-testid="stat-card"]');
  expect(card).toHaveTextContent("30%");
});

it("shows an inline error when the events query fails", () => {
  mockEvents.mockReturnValue(ok(undefined, { isError: true }));
  render(<AdminReach />);
  expect(screen.getAllByText("Couldn't load this section.").length).toBeGreaterThan(0);
  // The visits half of the page still renders.
  expect(screen.getByTestId("top-countries")).toHaveTextContent("KR");
});

it("shows a loading placeholder while the events query is in flight", () => {
  mockEvents.mockReturnValue(ok(undefined, { isLoading: true }));
  render(<AdminReach />);
  expect(screen.getAllByTestId("section-loading").length).toBeGreaterThan(0);
});

it("renders empty payloads without NaN", () => {
  mockEvents.mockReturnValue(ok(undefined));
  mockVisits.mockReturnValue(ok(undefined));
  const { container } = render(<AdminReach />);
  expect(container.innerHTML).not.toContain("NaN");
});

it("refetches both queries from the refresh button", () => {
  const events = ok(EVENTS);
  const visits = ok(VISITS);
  mockEvents.mockReturnValue(events);
  mockVisits.mockReturnValue(visits);
  render(<AdminReach />);
  fireEvent.click(screen.getByTestId("refresh-button"));
  expect(events.refetch).toHaveBeenCalled();
  expect(visits.refetch).toHaveBeenCalled();
});
