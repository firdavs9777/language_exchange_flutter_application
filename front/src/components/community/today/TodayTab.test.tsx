import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import TodayTab from "./TodayTab";

const mockSkip = jest.fn();
jest.mock("../../../store/slices/communitySlice", () => ({
  useSkipUserMutation: () => [mockSkip, { isLoading: false }],
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, o?: any) => (o ? `${key}|${JSON.stringify(o)}` : key),
    i18n: { language: "en" },
  }),
}));

const m = (id: string) => ({
  user: { _id: id, name: `N${id}`, images: [], native_language: "Korean", language_to_learn: "English" },
  matchReasons: [], responseRate: null,
});
const response = (over: any = {}) => ({
  success: true, date: "2026-10-08", nextRefreshAt: "2026-10-09T00:00:00.000Z",
  matches: [m("a"), m("b"), m("c")], ...over,
});

const renderTab = (props: any = {}) =>
  render(
    <MemoryRouter>
      <TodayTab response={response()} isLoading={false} isError={false} onRetry={jest.fn()} onWave={jest.fn()} onBrowse={jest.fn()} {...props} />
    </MemoryRouter>
  );

beforeEach(() => {
  window.sessionStorage.clear();
  mockSkip.mockReturnValue({ unwrap: () => Promise.resolve({}) });
});

describe("TodayTab", () => {
  it("titles the batch with its size and says when it refreshes", () => {
    renderTab();
    expect(screen.getByTestId("today-title")).toHaveTextContent('communityMain.today.title|{"count":3}');
    expect(screen.getByTestId("today-refresh")).toHaveTextContent("communityMain.today.refreshes");
    expect(screen.getAllByTestId("match-card")).toHaveLength(3);
  });

  it("falls back to 'at midnight' without a refresh time", () => {
    renderTab({ response: response({ nextRefreshAt: undefined }) });
    expect(screen.getByTestId("today-refresh")).toHaveTextContent("communityMain.today.refreshesMidnight");
  });

  it("Skip removes the card, posts the skip, and the count follows", () => {
    renderTab();
    fireEvent.click(screen.getAllByTestId("match-skip")[0]);
    expect(screen.getAllByTestId("match-card")).toHaveLength(2);
    expect(mockSkip).toHaveBeenCalledWith("a");
    expect(screen.getByTestId("today-title")).toHaveTextContent('{"count":2}');
  });

  it("a failed skip keeps the card gone", async () => {
    mockSkip.mockReturnValue({ unwrap: () => Promise.reject(new Error("nope")) });
    renderTab();
    await act(async () => { fireEvent.click(screen.getAllByTestId("match-skip")[0]); });
    expect(screen.getAllByTestId("match-card")).toHaveLength(2);
  });

  it("skips survive a remount within the same batch date", () => {
    const first = renderTab();
    fireEvent.click(screen.getAllByTestId("match-skip")[0]);
    first.unmount();
    renderTab();
    expect(screen.getAllByTestId("match-card")).toHaveLength(2);
  });

  it("a new batch date brings everyone back", () => {
    const first = renderTab();
    fireEvent.click(screen.getAllByTestId("match-skip")[0]);
    first.unmount();
    renderTab({ response: response({ date: "2026-10-09" }) });
    expect(screen.getAllByTestId("match-card")).toHaveLength(3);
  });

  it("shows the empty state after the last skip, and Browse partners asks for All", () => {
    const onBrowse = jest.fn();
    renderTab({ response: response({ matches: [m("a")] }), onBrowse });
    fireEvent.click(screen.getByTestId("match-skip"));
    expect(screen.getByTestId("today-empty")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("today-browse"));
    expect(onBrowse).toHaveBeenCalled();
  });

  it("an empty batch is the empty state too", () => {
    renderTab({ response: response({ matches: [] }) });
    expect(screen.getByTestId("today-empty")).toBeInTheDocument();
  });

  it("shows a skeleton while loading and an error with retry on failure", () => {
    const { unmount } = renderTab({ response: undefined, isLoading: true });
    expect(screen.getByTestId("today-skeleton")).toBeInTheDocument();
    unmount();
    const onRetry = jest.fn();
    renderTab({ response: undefined, isError: true, onRetry });
    fireEvent.click(screen.getByTestId("today-retry"));
    expect(onRetry).toHaveBeenCalled();
  });

  it("Wave hands the match up to the page", () => {
    const onWave = jest.fn();
    renderTab({ onWave });
    fireEvent.click(screen.getAllByTestId("match-wave")[1]);
    expect(onWave).toHaveBeenCalledWith(expect.objectContaining({ user: expect.objectContaining({ _id: "b" }) }));
  });

  it("refetches once when the clock passes nextRefreshAt", () => {
    jest.useFakeTimers();
    const now = new Date("2026-10-08T23:59:00.000Z").getTime();
    jest.setSystemTime(now);
    const onRetry = jest.fn();
    renderTab({ onRetry });
    act(() => { jest.advanceTimersByTime(61 * 1000); });
    expect(onRetry).toHaveBeenCalledTimes(1);
    jest.useRealTimers();
  });

  it("with storage blocked, skipping twice leaves both cards gone", () => {
    const get = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked"); });
    const set = jest.spyOn(Storage.prototype, "setItem").mockImplementation(() => { throw new Error("blocked"); });
    renderTab({ response: response({ date: "2026-10-11" }) });
    fireEvent.click(screen.getAllByTestId("match-skip")[0]);
    fireEvent.click(screen.getAllByTestId("match-skip")[0]);
    expect(screen.getAllByTestId("match-card")).toHaveLength(1);
    get.mockRestore();
    set.mockRestore();
  });

  it("marks the cards in wavedIds as waved, and keeps them in the batch", () => {
    renderTab({ wavedIds: ["b"] });
    expect(screen.getAllByTestId("match-card")).toHaveLength(3);
    expect(screen.getAllByTestId("match-waved")).toHaveLength(1);
    expect(screen.getAllByTestId("match-wave")).toHaveLength(2);
  });
});

