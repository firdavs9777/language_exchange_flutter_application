import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, within } from "@testing-library/react";
import { MemoryRouter, useLocation } from "react-router-dom";
import AdminContent from "./AdminContent";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockStats = jest.fn();
const mockMoments = jest.fn();
const mockClubs = jest.fn();
const mockGatherings = jest.fn();
const mockReports = jest.fn();
const mockArchive = jest.fn();
const mockCancel = jest.fn();
const mockSetHidden = jest.fn();
const mockReview = jest.fn();
const mockResolve = jest.fn();
const mockDismiss = jest.fn();

jest.mock("../../../store/slices/adminSlice", () => ({
  useGetContentStatsQuery: (...args: any[]) => mockStats(...args),
  useListMomentsQuery: (...args: any[]) => mockMoments(...args),
  useGetAdminClubsQuery: (...args: any[]) => mockClubs(...args),
  useGetAdminGatheringsQuery: (...args: any[]) => mockGatherings(...args),
  useListReportsQuery: (...args: any[]) => mockReports(...args),
  useArchiveAdminClubMutation: () => mockArchive(),
  useCancelAdminGatheringMutation: () => mockCancel(),
  useSetMomentHiddenMutation: () => mockSetHidden(),
  useReviewReportMutation: () => mockReview(),
  useResolveReportMutation: () => mockResolve(),
  useDismissReportMutation: () => mockDismiss(),
}));

const STATS = {
  moments: { total: 900, today: 7, last7d: 63, hidden: 4 },
  comments: { total: 5000, last7d: 128 },
  clubs: { active: 11, archived: 2, membersTotal: 340 },
  gatherings: { upcoming: 5, past: 30, cancelled: 1 },
  reports: {
    pending: 9,
    underReview: 3,
    byType: { moment: 2, comment: 1, user: 4, club: 1, gathering: 1, message: 0, story: 0 },
  },
};

const MOMENTS = {
  data: [
    {
      id: "m1",
      title: "Seoul sunset",
      description: "Walked the river at golden hour.",
      imageUrl: "https://cdn/m1.jpg",
      language: "ko",
      category: "daily",
      user: { id: "u1", name: "Mina", image: null },
      likeCount: 12,
      commentCount: 3,
      viewCount: 480,
      shareCount: 1,
      openReports: 2,
      isDeleted: false,
      createdAt: "2026-09-20T10:00:00.000Z",
    },
    {
      id: "m2",
      title: "",
      description: "Hidden one",
      imageUrl: null,
      language: "en",
      category: "study",
      user: null,
      likeCount: 0,
      commentCount: 0,
      viewCount: 2,
      shareCount: 0,
      openReports: 0,
      isDeleted: true,
      createdAt: "2026-09-19T10:00:00.000Z",
    },
  ],
  pagination: { total: 2, count: 2 },
};

const CLUBS = {
  data: [
    {
      _id: "c1",
      name: "Seoul Speakers",
      description: "Weekly practice.",
      owner: { _id: "u9", name: "Mina" },
      city: "Seoul",
      place: { name: "Hangang Park" },
      language: "ko",
      languageLabel: "Korean",
      memberCount: 42,
      status: "active",
      openReports: 2,
      createdAt: "2026-09-01T00:00:00.000Z",
    },
    {
      _id: "c2",
      name: "Old Club",
      description: "",
      owner: null,
      city: null,
      place: null,
      language: "ja",
      languageLabel: "Japanese",
      memberCount: 5,
      status: "archived",
      openReports: 0,
      createdAt: "2026-08-01T00:00:00.000Z",
    },
  ],
  pagination: { total: 2, count: 2 },
};

const GATHERINGS = {
  data: [
    {
      _id: "g1",
      title: "Coffee chat",
      language: "es",
      startsAt: "2026-10-01T18:00:00.000Z",
      capacity: 10,
      goingCount: 4,
      status: "scheduled",
      openReports: 1,
    },
    {
      _id: "g2",
      title: "Cancelled meetup",
      language: "fr",
      startsAt: "2026-09-15T18:00:00.000Z",
      capacity: 8,
      goingCount: 0,
      status: "cancelled",
      openReports: 0,
    },
  ],
  pagination: { total: 2, count: 2 },
};

const REPORTS = [
  {
    _id: "r1",
    type: "moment",
    reason: "harassment",
    reportedBy: { _id: "u1", name: "Ana" },
    reportedUser: { _id: "u2", name: "Bruno" },
    status: "pending",
    priority: "high",
    createdAt: "2026-09-22T09:00:00.000Z",
  },
];

/** A full page of moments, for the pagination test. */
const fullMomentPage = (n = 20) =>
  Array.from({ length: n }, (_, i) => ({
    ...MOMENTS.data[0],
    id: `page-moment-${i}`,
    title: `Moment ${i}`,
  }));

const ok = (data: any, extra: any = {}) => ({
  data,
  isLoading: false,
  isFetching: false,
  isError: false,
  refetch: jest.fn(),
  ...extra,
});

let archiveTrigger: jest.Mock;
let cancelTrigger: jest.Mock;
let hideTrigger: jest.Mock;

const Location: React.FC = () => {
  const location = useLocation();
  return <div data-testid="location">{location.search}</div>;
};

const renderPage = (entry = "/admin/content") =>
  render(
    <MemoryRouter initialEntries={[entry]}>
      <AdminContent />
      <Location />
    </MemoryRouter>
  );

const lastArg = (mock: jest.Mock) => mock.mock.calls[mock.mock.calls.length - 1][0];

beforeEach(() => {
  mockStats.mockReset().mockReturnValue(ok(STATS));
  mockMoments.mockReset().mockReturnValue(ok(MOMENTS));
  mockClubs.mockReset().mockReturnValue(ok(CLUBS));
  mockGatherings.mockReset().mockReturnValue(ok(GATHERINGS));
  mockReports.mockReset().mockReturnValue(ok(REPORTS));
  archiveTrigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
  cancelTrigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
  hideTrigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
  mockArchive.mockReset().mockReturnValue([archiveTrigger, { isLoading: false, reset: jest.fn() }]);
  mockCancel.mockReset().mockReturnValue([cancelTrigger, { isLoading: false, reset: jest.fn() }]);
  mockSetHidden.mockReset().mockReturnValue([hideTrigger, { isLoading: false, reset: jest.fn() }]);
  mockReview.mockReset().mockReturnValue([jest.fn(), { isLoading: false, reset: jest.fn() }]);
  mockResolve.mockReset().mockReturnValue([jest.fn(), { isLoading: false, reset: jest.fn() }]);
  mockDismiss.mockReset().mockReturnValue([jest.fn(), { isLoading: false, reset: jest.fn() }]);
});

it("renders the page heading", () => {
  renderPage();
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Content");
});

it("renders the stat strip from the content stats", () => {
  renderPage();
  const strip = screen.getByTestId("content-stat-strip");
  const values = within(strip)
    .getAllByTestId("stat-value")
    .map((node) => node.textContent);
  expect(values).toEqual(["7", "63", "4", "128", "11", "5", "9"]);
});

it("keeps the stat strip up when a stats query fails", () => {
  mockStats.mockReturnValue(ok(undefined, { isError: true }));
  renderPage();
  expect(screen.getByTestId("stats-error")).toBeInTheDocument();
  expect(screen.getByTestId("data-table")).toBeInTheDocument();
});

it("opens on the moments tab and renders moment rows", () => {
  renderPage();
  expect(screen.getByRole("tab", { name: "Moments" })).toHaveAttribute("aria-selected", "true");
  expect(screen.getByText("Seoul sunset")).toBeInTheDocument();
  expect(screen.getByText("Hidden one")).toBeInTheDocument();
});

it("shows the counts, the hidden badge and the author link on a moment row", () => {
  renderPage();
  const rows = screen.getAllByTestId("data-row");
  expect(within(rows[0]).getByRole("link", { name: "Mina" })).toHaveAttribute(
    "href",
    "/profile/u1"
  );
  expect(rows[0]).toHaveTextContent("12");
  expect(rows[0]).toHaveTextContent("480");
  expect(within(rows[1]).getByText("Hidden")).toBeInTheDocument();
});

it("reads the tab out of the URL", () => {
  renderPage("/admin/content?tab=gatherings");
  expect(screen.getByRole("tab", { name: "Gatherings" })).toHaveAttribute(
    "aria-selected",
    "true"
  );
  expect(screen.getByText("Coffee chat")).toBeInTheDocument();
});

it("falls back to moments for an unknown tab in the URL", () => {
  renderPage("/admin/content?tab=nonsense");
  expect(screen.getByRole("tab", { name: "Moments" })).toHaveAttribute("aria-selected", "true");
});

it("writes the chosen tab into the URL", () => {
  renderPage();
  fireEvent.click(screen.getByRole("tab", { name: "Communities" }));
  expect(screen.getByTestId("location")).toHaveTextContent("tab=communities");
  expect(screen.getByText("Seoul Speakers")).toBeInTheDocument();
});

it("renders communities with owner, city and created", () => {
  renderPage("/admin/content?tab=communities");
  const rows = screen.getAllByTestId("data-row");
  expect(rows[0]).toHaveTextContent("Seoul Speakers");
  expect(rows[0]).toHaveTextContent("Mina");
  expect(rows[0]).toHaveTextContent("Seoul");
  expect(rows[1]).toHaveTextContent("Old Club");
});

it("renders the reports tab", () => {
  renderPage("/admin/content?tab=reports");
  expect(screen.getByTestId("reports-status-filter")).toBeInTheDocument();
  expect(screen.getByText("harassment")).toBeInTheDocument();
});

it("debounces the moment search into the query args", async () => {
  renderPage();
  fireEvent.change(screen.getByTestId("moment-search"), { target: { value: "sunset" } });
  expect(lastArg(mockMoments).q).toBeFalsy();
  await waitFor(() => expect(lastArg(mockMoments)).toMatchObject({ q: "sunset" }));
});

it("sends the reported and hidden filters when they are switched on", () => {
  renderPage();
  fireEvent.click(screen.getByRole("checkbox", { name: "Reported only" }));
  expect(lastArg(mockMoments)).toMatchObject({ reported: true });
  fireEvent.click(screen.getByRole("checkbox", { name: "Hidden only" }));
  expect(lastArg(mockMoments)).toMatchObject({ reported: true, hidden: true });
});

it("sends no filters by default", () => {
  renderPage();
  const arg = lastArg(mockMoments);
  expect(arg.reported).toBeFalsy();
  expect(arg.hidden).toBeFalsy();
  expect(arg.q).toBeFalsy();
});

it("pages moments off the total rather than the row count", () => {
  // `reported=true` filters AFTER pagination on the backend, so a short page
  // is not proof of the end — only `total` is.
  mockMoments.mockReturnValue(
    ok({ data: [MOMENTS.data[0]], pagination: { total: 45, count: 1 } })
  );
  renderPage();
  expect(screen.getByTestId("data-table-next")).not.toBeDisabled();
  fireEvent.click(screen.getByTestId("data-table-next"));
  expect(lastArg(mockMoments)).toMatchObject({ page: 2 });
});

it("disables Next once the page covers the total", () => {
  renderPage();
  expect(screen.getByTestId("data-table-next")).toBeDisabled();
});

it("resets to page 1 when a filter changes", () => {
  mockMoments.mockReturnValue(ok({ data: fullMomentPage(20), pagination: { total: 99, count: 20 } }));
  renderPage();
  fireEvent.click(screen.getByTestId("data-table-next"));
  expect(lastArg(mockMoments)).toMatchObject({ page: 2 });
  fireEvent.click(screen.getByRole("checkbox", { name: "Hidden only" }));
  expect(lastArg(mockMoments)).toMatchObject({ page: 1 });
});

it("opens the moment drawer on a row click and hides through it", async () => {
  renderPage();
  fireEvent.click(screen.getAllByTestId("data-row")[0]);
  expect(screen.getByTestId("moment-preview-drawer")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("moment-hide"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "spam" } });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(hideTrigger).toHaveBeenCalledWith({ id: "m1", hidden: true, reason: "spam" });
  await waitFor(() =>
    expect(screen.queryByTestId("moment-preview-drawer")).not.toBeInTheDocument()
  );
});

it("opens the community drawer on a row click and archives through it", async () => {
  renderPage("/admin/content?tab=communities");
  fireEvent.click(screen.getAllByTestId("data-row")[0]);
  expect(screen.getByTestId("club-detail-drawer")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("club-archive"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "spam" } });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(archiveTrigger).toHaveBeenCalledWith({ id: "c1", archived: true, reason: "spam" });
  await waitFor(() =>
    expect(screen.queryByTestId("club-detail-drawer")).not.toBeInTheDocument()
  );
});

it("keeps the gathering cancel action", async () => {
  renderPage("/admin/content?tab=gatherings");
  fireEvent.click(screen.getByRole("button", { name: "Cancel" }));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "abuse" } });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(cancelTrigger).toHaveBeenCalledWith({ id: "g1", reason: "abuse" });
  await waitFor(() => expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument());
});

it("hides the cancel action for an already-cancelled gathering", () => {
  renderPage("/admin/content?tab=gatherings");
  const rows = screen.getAllByTestId("data-row");
  expect(rows[1]).toHaveTextContent("Cancelled meetup");
  expect(rows[1].querySelector("button")).toBeNull();
});

it("keeps the reported-only filter on the gatherings tab", () => {
  renderPage("/admin/content?tab=gatherings");
  fireEvent.click(screen.getByRole("checkbox", { name: "Reported only" }));
  expect(lastArg(mockGatherings)).toMatchObject({ reported: true });
});

it("disables Next on a short reported-only page of gatherings", () => {
  // Unlike moments, the clubs/gatherings `total` ignores the reported filter
  // entirely, so a short page is the only honest end-of-list signal there.
  mockGatherings.mockReturnValue(
    ok({ data: [GATHERINGS.data[0]], pagination: { total: 45, count: 1 } })
  );
  renderPage("/admin/content?tab=gatherings");
  fireEvent.click(screen.getByRole("checkbox", { name: "Reported only" }));
  expect(screen.getByTestId("data-table-next")).toBeDisabled();
});

it("shows an inline error when the moments query fails", () => {
  mockMoments.mockReturnValue(ok(undefined, { isError: true }));
  renderPage();
  expect(screen.getByTestId("section-error")).toBeInTheDocument();
});

it("shows the loading state while the moments query is loading", () => {
  mockMoments.mockReturnValue(ok(undefined, { isLoading: true }));
  renderPage();
  expect(screen.getByTestId("section-loading")).toBeInTheDocument();
});
