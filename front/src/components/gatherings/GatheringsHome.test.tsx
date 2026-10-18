import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import GatheringsHome from "./GatheringsHome";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mockGatherings = jest.fn();
const mockClubs = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  GATHERING_TOPICS: jest.requireActual("../../store/slices/gatheringsSlice").GATHERING_TOPICS,
  useGetGatheringsQuery: (args: any) => mockGatherings(args),
  useGetClubsQuery: (args: any) => mockClubs(args),
}));
jest.mock("../../store/slices/communitySlice", () => ({
  useGetLanguagesQuery: () => ({ data: { data: [{ code: "ko", name: "Korean" }] } }),
}));
jest.mock("../community/lib/languageOptions", () => ({
  languageOptions: () => [
    { value: "Korean", label: "Korean" },
    { value: "Japanese", label: "Japanese" },
  ],
}));

const gathering = (id: string, extra: any = {}) => ({
  _id: id,
  title: `Gathering ${id}`,
  language: "korean",
  languageLabel: "Korean",
  startsAt: "2030-11-01T10:00:00.000Z",
  durationMinutes: 60,
  capacity: 6,
  quorum: 3,
  joinMode: "open",
  status: "scheduled",
  going: 1,
  needed: 2,
  quorumMet: false,
  viewerIsAttending: false,
  viewerIsHost: false,
  host: { _id: "h1", name: "Hana", images: [] },
  ...extra,
});
const club = (id: string, extra: any = {}) => ({
  _id: id,
  name: `Club ${id}`,
  language: "korean",
  languageLabel: "Korean",
  memberCount: 12,
  members: [{ _id: "u1", name: "Ada", username: "ada", images: [], role: "owner" }],
  viewerCanManage: false,
  viewerIsMember: false,
  viewerIsOwner: false,
  ...extra,
});
const ok = (data: any[]) => ({ data, isLoading: false, isFetching: false, isError: false, refetch: jest.fn() });

function Where() {
  const l = useLocation();
  return <div data-testid="where">{l.pathname + l.search}</div>;
}
function renderHome(path = "/gatherings") {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/gatherings" element={<><GatheringsHome /><Where /></>} />
        <Route path="/clubs" element={<><GatheringsHome initialTab="clubs" /><Where /></>} />
      </Routes>
    </MemoryRouter>
  );
}

beforeEach(() => {
  mockGatherings.mockReset();
  mockClubs.mockReset();
  mockGatherings.mockReturnValue(ok([gathering("g1"), gathering("g2", { viewerIsAttending: true })]));
  mockClubs.mockReturnValue(ok([club("c1")]));
});

it("asks for 'my languages', page 1, like the app's default", () => {
  renderHome();
  expect(mockGatherings).toHaveBeenLastCalledWith({ scope: "mine", page: 1, topic: "", when: "", hasSeat: false, language: "" });
  expect(screen.getByTestId("gathering-card-g1")).toHaveAttribute("href", "/gatherings/g1");
  expect(screen.getByTestId("gathering-card-g1")).toHaveTextContent("2 more needed to confirm · 1 going");
  expect(screen.getByTestId("gathering-card-g2")).toHaveTextContent("Going");
});

it("filters by scope, topic, time window, free seats and language", () => {
  renderHome();
  fireEvent.click(screen.getByTestId("gatherings-scope-all"));
  fireEvent.change(screen.getByTestId("gatherings-filter-topic"), { target: { value: "grammar" } });
  fireEvent.change(screen.getByTestId("gatherings-filter-when"), { target: { value: "week" } });
  fireEvent.click(screen.getByTestId("gatherings-filter-seat"));
  fireEvent.change(screen.getByTestId("gatherings-filter-language"), { target: { value: "Japanese" } });
  expect(mockGatherings).toHaveBeenLastCalledWith({
    scope: "all",
    page: 1,
    topic: "grammar",
    when: "week",
    hasSeat: true,
    language: "Japanese",
  });
});

it("loads the next page while the last one came back full, and appends it", async () => {
  const page1 = Array.from({ length: 30 }, (_, i) => gathering(`a${i}`));
  // Stable results per page, as RTK Query returns them (a fresh object each
  // render would re-run the page-append effect forever).
  const first = ok(page1);
  const second = ok([gathering("b1")]);
  mockGatherings.mockImplementation((args: any) => (args.page === 1 ? first : second));
  renderHome();
  fireEvent.click(screen.getByTestId("gatherings-load-more"));
  await waitFor(() => expect(screen.getByTestId("gathering-card-b1")).toBeInTheDocument());
  expect(screen.getByTestId("gathering-card-a0")).toBeInTheDocument();
  expect(screen.queryByTestId("gatherings-load-more")).not.toBeInTheDocument();
});

it("hides Load more after a short page", () => {
  renderHome();
  expect(screen.queryByTestId("gatherings-load-more")).not.toBeInTheDocument();
});

it("shows an empty state that offers hosting", () => {
  mockGatherings.mockReturnValue(ok([]));
  renderHome();
  expect(screen.getByTestId("gatherings-empty")).toBeInTheDocument();
  expect(screen.getAllByTestId("host-gathering-link")[0]).toHaveAttribute("href", "/gatherings/new");
});

it("shows a retry on error", () => {
  const refetch = jest.fn();
  mockGatherings.mockReturnValue({ data: undefined, isLoading: false, isFetching: false, isError: true, refetch });
  renderHome();
  fireEvent.click(screen.getByTestId("gatherings-error").querySelector("button") as HTMLButtonElement);
  expect(refetch).toHaveBeenCalled();
});

it("switches to clubs, mirrors it in the URL, and filters clubs by scope", () => {
  renderHome();
  fireEvent.click(screen.getByTestId("clubs-tab"));
  expect(screen.getByTestId("where")).toHaveTextContent("/gatherings?tab=clubs");
  expect(screen.getByTestId("club-card-c1")).toHaveAttribute("href", "/clubs/c1");
  expect(screen.getByTestId("club-card-c1")).toHaveTextContent("12 members");
  fireEvent.click(screen.getByTestId("clubs-scope-member"));
  expect(mockClubs).toHaveBeenLastCalledWith({ scope: "member", page: 1 });
  expect(screen.getByTestId("start-club-link")).toHaveAttribute("href", "/clubs/new");
});

it("opens on the clubs tab from /clubs", () => {
  renderHome("/clubs");
  expect(screen.getByTestId("club-card-c1")).toBeInTheDocument();
  expect(screen.queryByTestId("gathering-card-g1")).not.toBeInTheDocument();
});

