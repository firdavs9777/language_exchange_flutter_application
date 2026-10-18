import "@testing-library/jest-dom";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import SavedMoments from "./SavedMoments";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
jest.mock("react-toastify", () => ({ Bounce: {}, toast: { success: jest.fn(), error: jest.fn() } }));
const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));
jest.mock("./media/VoiceNotePlayer", () => () => <div data-testid="voice-player" />);
jest.mock("./media/MomentVideoPlayer", () => () => <div data-testid="video-player" />);

const row = (id: string, extra: any = {}) => ({
  _id: id,
  description: `moment ${id}`,
  likeCount: 0,
  commentCount: 0,
  createdAt: "2026-10-01T00:00:00.000Z",
  user: { _id: "u-" + id, name: "Ann" },
  ...extra,
});

const mockPage1 = Array.from({ length: 12 }, (_, i) => row(`p1-${i}`));
const mockPage2 = [
  row("audio", { mediaType: "audio", audio: { url: "https://cdn/a.m4a", duration: 7, waveform: [] } }),
  row("text", { mediaType: "text", backgroundColor: "gradient_lagoon" }),
];
// Stable result objects, as RTK Query hands out: a fresh `currentData` on
// every render would re-run the page-merge effect forever.
const mockResult1 = { currentData: { data: mockPage1, pagination: { hasNextPage: true } }, isLoading: false, isFetching: false };
const mockResult2 = { currentData: { data: mockPage2, pagination: { hasNextPage: false } }, isLoading: false, isFetching: false };
const mockQueryArgs: any[] = [];
jest.mock("../../store/slices/momentsSlice", () => ({
  useGetSavedMomentsQuery: (args: any) => {
    mockQueryArgs.push(args);
    return args.page === 1 ? mockResult1 : mockResult2;
  },
  useUnsaveMomentMutation: () => [jest.fn(() => ({ unwrap: () => Promise.resolve({}) })), { isLoading: false }],
}));

const renderPage = () => render(<MemoryRouter><SavedMoments /></MemoryRouter>);

beforeEach(() => {
  mockQueryArgs.length = 0;
  mockNavigate.mockReset();
});

it("loads the next page and appends it (moments#11)", async () => {
  renderPage();
  expect(screen.getAllByTestId("saved-tile")).toHaveLength(12);
  fireEvent.click(screen.getByRole("button", { name: "Load more" }));
  await waitFor(() => expect(screen.getAllByTestId("saved-tile")).toHaveLength(14));
  expect(mockQueryArgs.some((a) => a.page === 2 && a.limit === 12)).toBe(true);
  expect(screen.queryByRole("button", { name: "Load more" })).not.toBeInTheDocument();
});

it("draws voice and gradient moments instead of an empty tile", async () => {
  renderPage();
  fireEvent.click(screen.getByRole("button", { name: "Load more" }));
  expect(await screen.findByTestId("thumb-audio")).toBeInTheDocument();
  const gradient = screen.getByTestId("thumb-gradient");
  expect(gradient.getAttribute("style") || "").toContain("linear-gradient");
});

it("opens the canonical moment and profile routes", async () => {
  renderPage();
  fireEvent.click(screen.getAllByTestId("saved-tile")[0]);
  expect(mockNavigate).toHaveBeenCalledWith("/moment/p1-0");
  fireEvent.click(screen.getByLabelText("List view"));
  fireEvent.click(screen.getAllByTestId("saved-author")[0]);
  expect(mockNavigate).toHaveBeenCalledWith("/community/u-p1-0");
});

it("list view uses the feed's voice player for a voice moment", async () => {
  renderPage();
  fireEvent.click(screen.getByRole("button", { name: "Load more" }));
  fireEvent.click(screen.getByLabelText("List view"));
  expect(await screen.findByTestId("voice-player")).toBeInTheDocument();
});
