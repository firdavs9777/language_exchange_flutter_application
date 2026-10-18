import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import AdminAnnouncements from "./AdminAnnouncements";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockList = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  useListAnnouncementsQuery: (...args: any[]) => mockList(...args),
}));

const ROWS = [
  {
    id: "a1", _id: "a1", status: "live", priority: 5, defaultLocale: "en", emoji: "🎉",
    translations: { en: { title: "Study Hub is here" } }, platforms: ["all"], languages: [],
    startsAt: "2026-10-12T09:00:00.000Z", endsAt: null, notify: true, showInApp: true,
    delivery: { state: "done", targeted: 1200, pushed: 410, listed: 1200, failed: 3 },
  },
  {
    id: "a2", _id: "a2", status: "draft", priority: 0, defaultLocale: "ko", emoji: null,
    translations: { ko: { title: "공지" } }, platforms: ["ios"], languages: ["ko"],
    startsAt: null, endsAt: null, notify: false, showInApp: true,
    delivery: { state: "none", targeted: 0, pushed: 0, listed: 0, failed: 0 },
  },
];

const ok = (data: any, extra: any = {}) => ({ data, isLoading: false, isFetching: false, isError: false, refetch: jest.fn(), ...extra });

const LocationProbe = () => {
  const location = useLocation();
  return <div data-testid="location">{location.pathname + location.search}</div>;
};

const renderPage = (path = "/admin/announcements") =>
  render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/admin/announcements" element={<><AdminAnnouncements /><LocationProbe /></>} />
        <Route path="/admin/announcements/:id" element={<LocationProbe />} />
      </Routes>
    </MemoryRouter>
  );

beforeEach(() => {
  mockList.mockReset().mockReturnValue(ok(ROWS));
});

it("renders heading, rows, status, audience and delivery stats", () => {
  renderPage();
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Announcements");
  expect(screen.getByText("🎉 Study Hub is here")).toBeInTheDocument();
  expect(screen.getByText("공지")).toBeInTheDocument();
  expect(screen.getByText("All platforms · all languages")).toBeInTheDocument();
  expect(screen.getByText("iOS · ko")).toBeInTheDocument();
  expect(screen.getByText("1,200 / 410 / 1,200 / 3")).toBeInTheDocument();
  expect(screen.getAllByTestId("announcement-status").map((n) => n.textContent)).toEqual(["live", "draft"]);
});

it("asks for every status by default and narrows by the status filter in the URL", () => {
  renderPage();
  expect(mockList).toHaveBeenLastCalledWith({});
  fireEvent.click(screen.getByRole("button", { name: "Live" }));
  expect(mockList).toHaveBeenLastCalledWith({ status: "live" });
  expect(screen.getByTestId("location")).toHaveTextContent("/admin/announcements?status=live");
});

it("opens the editor on row click and from New announcement", () => {
  renderPage();
  fireEvent.click(screen.getAllByTestId("data-row")[0]);
  expect(screen.getByTestId("location")).toHaveTextContent("/admin/announcements/a1");
});

it("New announcement links to the create editor", () => {
  renderPage();
  expect(screen.getByRole("link", { name: "New announcement" })).toHaveAttribute("href", "/admin/announcements/new");
});

it("shows an error state when the list fails, and a loading state while it loads", () => {
  mockList.mockReturnValue(ok(undefined, { isError: true }));
  const { unmount } = renderPage();
  expect(screen.getByRole("alert")).toHaveTextContent("Couldn't load announcements.");
  unmount();
  mockList.mockReturnValue(ok(undefined, { isLoading: true }));
  renderPage();
  expect(screen.getByText("Loading…")).toBeInTheDocument();
});

it("shows delivery state, attempts and an exhausted failed send with its error", () => {
  mockList.mockReturnValue(ok([
    ROWS[0],
    {
      ...ROWS[0], id: "a3", _id: "a3", translations: { en: { title: "Broken send" } },
      delivery: { state: "failed", targeted: 900, pushed: 120, listed: 300, failed: 0, attempts: 3, error: "FCM quota exceeded" },
    },
  ]));
  renderPage();
  expect(screen.getAllByTestId("delivery-state").map((n) => n.textContent)).toEqual(["Sent", "Failed"]);
  expect(screen.getByText("Attempts 3/3")).toBeInTheDocument();
  expect(screen.getByTestId("delivery-exhausted")).toHaveTextContent("Gave up after 3 attempts");
  expect(screen.getByTestId("delivery-error")).toHaveTextContent("FCM quota exceeded");
});

it("a failed send still under the cap is not called exhausted", () => {
  mockList.mockReturnValue(ok([{ ...ROWS[0], delivery: { state: "failed", attempts: 1, error: "boom", targeted: 1, pushed: 0, listed: 0, failed: 0 } }]));
  renderPage();
  expect(screen.getByText("Attempts 1/3")).toBeInTheDocument();
  expect(screen.queryByTestId("delivery-exhausted")).not.toBeInTheDocument();
});

it("search filters loaded rows by any locale's title or body and lives in ?q=", () => {
  renderPage();
  fireEvent.change(screen.getByRole("searchbox", { name: "Search title or text" }), { target: { value: "study" } });
  expect(screen.getByTestId("location")).toHaveTextContent("/admin/announcements?q=study");
  expect(screen.getByText("🎉 Study Hub is here")).toBeInTheDocument();
  expect(screen.queryByText("공지")).not.toBeInTheDocument();
  // The search never goes to the server: it isn't a backend parameter.
  expect(mockList).toHaveBeenLastCalledWith({});
});

it("empty states: none at all, none for a status, none matching a search", () => {
  mockList.mockReturnValue(ok([]));
  const first = renderPage();
  expect(screen.getByText("No announcements yet.")).toBeInTheDocument();
  first.unmount();
  const second = renderPage("/admin/announcements?status=live");
  expect(screen.getByText("No announcements with this status.")).toBeInTheDocument();
  second.unmount();
  mockList.mockReturnValue(ok(ROWS));
  renderPage("/admin/announcements?q=nothing-like-this");
  expect(screen.getByText("No announcements match this search.")).toBeInTheDocument();
});

it("the error state offers a retry", () => {
  const refetch = jest.fn();
  mockList.mockReturnValue(ok(undefined, { isError: true, refetch }));
  renderPage();
  fireEvent.click(screen.getByRole("button", { name: "Try again" }));
  expect(refetch).toHaveBeenCalled();
});
