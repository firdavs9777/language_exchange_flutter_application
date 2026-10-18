import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import BoostPage from "./BoostPage";
import BoostEntryRow from "./BoostEntryRow";

const H = 3600000;
let mockActive: any = { data: null, isLoading: false };
let mockHistory: any = { data: [] };
let mockBalance: any = { data: 200 };
let mockFlags: { [k: string]: boolean } = { boostsEnabled: true, coinsEnabled: true };
const mockPurchase = jest.fn();
const mockRefetchActive = jest.fn();
jest.mock("../../store/slices/boostsSlice", () => ({
  useGetActiveBoostQuery: () => Object.assign({ refetch: mockRefetchActive }, mockActive),
  useGetBoostHistoryQuery: (_a: any, o: any) => (o && o.skip ? { data: undefined, refetch: jest.fn() } : Object.assign({ refetch: jest.fn() }, mockHistory)),
  useGetCoinBalanceQuery: (_a: any, o: any) => (o && o.skip ? { data: undefined } : mockBalance),
  usePurchaseProfileBoostMutation: () => [mockPurchase, { isLoading: false }],
}));
jest.mock("../../utils/webFlags", () => ({ useWebFlag: (f: string) => !!mockFlags[f] }));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const iso = (ms: number) => new Date(ms).toISOString();
const page = () =>
  render(
    <MemoryRouter>
      <BoostPage />
    </MemoryRouter>
  );

beforeEach(() => {
  mockActive = { data: null, isLoading: false };
  mockHistory = { data: [] };
  mockBalance = { data: 200 };
  mockFlags = { boostsEnabled: true, coinsEnabled: true };
  mockPurchase.mockReset();
  mockRefetchActive.mockReset();
  mockRefetchActive.mockImplementation(() => Promise.resolve({ data: null }));
});

it("explains the boost, shows the cost and balance, and buys it", async () => {
  mockPurchase.mockReturnValue({ unwrap: () => Promise.resolve({ _id: "b1" }) });
  page();
  expect(screen.getByTestId("boost-explain-more")).toHaveTextContent("near the top of Partners");
  expect(screen.getByTestId("boost-cost")).toHaveTextContent("150");
  expect(screen.getByTestId("boost-balance")).toHaveTextContent("200");
  expect(screen.getByTestId("boost-confirm")).toHaveTextContent("Confirm boost");
  fireEvent.click(screen.getByTestId("boost-confirm"));
  await waitFor(() => expect(mockPurchase).toHaveBeenCalled());
});

it("hides the balance when coins are off", () => {
  mockFlags = { boostsEnabled: true, coinsEnabled: false };
  page();
  expect(screen.queryByTestId("boost-balance")).not.toBeInTheDocument();
});

it.each([
  [{ status: 402, data: { error: "insufficient_coins" } }, /You need 150 coins/],
  [{ status: 429, data: { error: "capacity_full" } }, /slots are taken/],
  [{ status: 500, data: {} }, /Couldn't start your boost/],
])("says why a purchase was refused (%j)", async (err, text) => {
  mockPurchase.mockReturnValue({ unwrap: () => Promise.reject(err) });
  page();
  fireEvent.click(screen.getByTestId("boost-confirm"));
  await waitFor(() => expect(screen.getByTestId("boost-message")).toHaveTextContent(text));
});

it("not enough coins links to the app", async () => {
  mockPurchase.mockReturnValue({ unwrap: () => Promise.reject({ status: 402, data: { error: "insufficient_coins" } }) });
  page();
  fireEvent.click(screen.getByTestId("boost-confirm"));
  await waitFor(() => expect(screen.getByTestId("boost-get-app").getAttribute("href")).toBe("/download"));
});

it("while live: time left, progress, views by place, the zero-views hint and tips", () => {
  mockActive = {
    isLoading: false,
    data: { _id: "b1", status: "active", startsAt: iso(Date.now() - 6 * H), endsAt: iso(Date.now() + 18 * H), impressions: 0, impressionsBySource: {} },
  };
  page();
  expect(screen.getByTestId("boost-active")).toBeInTheDocument();
  expect(screen.getByTestId("boost-time-left")).toHaveTextContent(/1[78]h \d+m left/);
  expect(Number(screen.getByTestId("boost-progress").getAttribute("aria-valuenow"))).toBeGreaterThanOrEqual(24);
  expect(screen.getByTestId("boost-impressions")).toHaveTextContent("Times shown so far: 0");
  expect(screen.getByTestId("boost-counting-hint")).toBeInTheDocument();
  expect(screen.getByTestId("boost-post-moment").getAttribute("href")).toBe("/add-moment");
});

it("shows the per-place breakdown and no hint once it has views", () => {
  mockActive = {
    isLoading: false,
    data: { _id: "b1", status: "active", startsAt: iso(Date.now() - H), endsAt: iso(Date.now() + 23 * H), impressions: 12, impressionsBySource: { partners: 7, matches: 3, moments: 2 } },
  };
  page();
  expect(screen.getByTestId("boost-source-partners")).toHaveTextContent("7");
  expect(screen.getByTestId("boost-source-matches")).toHaveTextContent("3");
  expect(screen.getByTestId("boost-source-moments")).toHaveTextContent("2");
  expect(screen.queryByTestId("boost-counting-hint")).not.toBeInTheDocument();
});

it("after a boost ends: its result and Boost again", () => {
  mockHistory = { data: [{ _id: "old", status: "expired", startsAt: iso(Date.now() - 30 * H), endsAt: iso(Date.now() - 6 * H), impressions: 41 }] };
  page();
  expect(screen.getByTestId("boost-impressions")).toHaveTextContent("41");
  expect(screen.getByTestId("boost-confirm")).toHaveTextContent("Boost again");
});

describe("BoostEntryRow", () => {
  const row = () =>
    render(
      <MemoryRouter>
        <BoostEntryRow />
      </MemoryRouter>
    );

  it("offers a boost, linking to /boost", () => {
    row();
    expect(screen.getByTestId("boost-entry-row")).toHaveTextContent("Boost my profile");
    expect(screen.getByTestId("boost-entry-row").getAttribute("href")).toBe("/boost");
  });

  it("shows the live boost's time left", () => {
    mockActive = { isLoading: false, data: { _id: "b1", status: "active", startsAt: iso(Date.now() - H), endsAt: iso(Date.now() + 5 * H + 120000), impressions: 3 } };
    row();
    expect(screen.getByTestId("boost-entry-row")).toHaveTextContent("Your boost is live");
    expect(screen.getByTestId("boost-entry-subtitle")).toHaveTextContent(/5h \dm left · Times shown so far: 3/);
  });

  it("offers Boost again with the last result", () => {
    mockHistory = { data: [{ _id: "old", status: "expired", endsAt: iso(Date.now() - H), impressions: 9 }] };
    row();
    expect(screen.getByTestId("boost-entry-row")).toHaveTextContent("Boost again");
    expect(screen.getByTestId("boost-entry-subtitle")).toHaveTextContent("9");
  });

  it("renders nothing while boosts are off", () => {
    mockFlags = { boostsEnabled: false };
    row();
    expect(screen.queryByTestId("boost-entry-row")).not.toBeInTheDocument();
  });
});
