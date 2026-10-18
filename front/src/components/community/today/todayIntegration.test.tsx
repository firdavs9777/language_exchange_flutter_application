import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { createMemoryRouter, createRoutesFromElements, Route, RouterProvider } from "react-router-dom";
import { makeStore } from "../../../store";
import MainCommunity from "../MainCommunity";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string, o?: any) => (o ? `${key} ${Object.values(o).join(" ")}` : key), i18n: { language: "en" } }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn(), info: jest.fn(), warning: jest.fn(), show: jest.fn(), dismiss: jest.fn() },
}));

const SIGNED_IN = { auth: { userInfo: { user: { _id: "u1", native_language: "English", language_to_learn: "Korean" }, token: "t" } } };
const daily = {
  success: true, date: "2026-10-08", nextRefreshAt: "2026-10-09T00:00:00.000Z",
  matches: [{ user: { _id: "d1", name: "Daily One", images: [], native_language: "Korean", language_to_learn: "English" }, matchReasons: ["reciprocal_pair"], responseRate: null }],
};
const requested: string[] = [];
const originalFetch = global.fetch;
let dailyStatus = 200;

beforeEach(() => {
  requested.length = 0;
  dailyStatus = 200;
  window.sessionStorage.clear();
  (global as any).IntersectionObserver = class { observe() {} disconnect() {} unobserve() {} };
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    requested.push(url);
    let status = 200;
    let body: any = { success: true, data: [] };
    if (url.indexOf("/matching/daily") >= 0) {
      status = dailyStatus;
      body = dailyStatus === 200 ? daily : { success: false, error: "Not found" };
    } else if (url.indexOf("/community/wave") >= 0 && (input as any).method === "POST") {
      status = 201;
      body = { success: true, data: { waveId: "w1", isMutual: false, message: "Wave sent!" } };
    } else if (/\/auth\/users\?/.test(url)) {
      body = { success: true, total: 1, pages: 1, data: [{ _id: "m1", name: "Listed Member", native_language: "Korean", language_to_learn: "English", imageUrls: [] }] };
    }
    return Promise.resolve(new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } }));
  });
});
afterEach(() => { global.fetch = originalFetch; });

function renderAt(path: string, state: any = SIGNED_IN) {
  const router = createMemoryRouter(
    createRoutesFromElements(<Route path="/communities" element={<MainCommunity />} />),
    { initialEntries: [path] }
  );
  const { container } = render(<Provider store={makeStore(state)}><RouterProvider router={router} /></Provider>);
  (router as any).container = container;
  return router;
}

describe("Today on /communities", () => {
  it("lands a signed-in member on Today, and asks for the batch rather than the list", async () => {
    renderAt("/communities");
    expect(await screen.findByText("Daily One")).toBeInTheDocument();
    expect(requested.some((u) => u.indexOf("/matching/daily") >= 0)).toBe(true);
    expect(requested.some((u) => /\/auth\/users\?/.test(u))).toBe(false);
  });

  it("?tab=all still opens All", async () => {
    renderAt("/communities?tab=all");
    expect((await screen.findAllByText("Listed Member")).length).toBeGreaterThan(0);
  });

  it("old filtered links land on All and keep their params", async () => {
    const router = renderAt("/communities?native=Korean");
    expect((await screen.findAllByText("Listed Member")).length).toBeGreaterThan(0);
    expect(router.state.location.search).toContain("native=Korean");
  });

  it("feature off (404): shows All, hides the Today button, leaves the address bar alone", async () => {
    dailyStatus = 404;
    const router = renderAt("/communities");
    expect((await screen.findAllByText("Listed Member")).length).toBeGreaterThan(0);
    expect((router as any).container.querySelector("#community-tab-today")).toBeNull();
    expect(router.state.location.search).toBe("");
  });

  it("Today hides filters, search and the carousel, and writes no filter params", async () => {
    const router = renderAt("/communities");
    await screen.findByText("Daily One");
    expect((router as any).container.querySelector(".community-subnav__search")).toBeNull();
    expect(screen.queryByLabelText(/communityMain\.subnav\.filters/)).not.toBeInTheDocument();
    expect((router as any).container.querySelector("#community-tab-today")).not.toBeNull();
    expect(router.state.location.search).toBe("");
  });

  it("Browse partners switches to All, written into the URL", async () => {
    const router = renderAt("/communities");
    await screen.findByText("Daily One");
    fireEvent.click(screen.getByTestId("match-skip"));
    fireEvent.click(await screen.findByTestId("today-browse"));
    await waitFor(() => expect(router.state.location.search).toBe("?tab=all"));
  });

  it("Wave opens the wave sheet for that person", async () => {
    renderAt("/communities");
    await screen.findByText("Daily One");
    fireEvent.click(screen.getByTestId("match-wave"));
    expect(await screen.findByRole("dialog")).toBeInTheDocument();
  });

  it("a sent wave turns the card's Wave into Waved (community#14)", async () => {
    renderAt("/communities");
    await screen.findByText("Daily One");
    fireEvent.click(screen.getByTestId("match-wave"));
    fireEvent.click(await screen.findByTestId("wave-sheet-send"));
    expect(await screen.findByTestId("match-waved")).toBeInTheDocument();
    expect(screen.queryByTestId("match-wave")).not.toBeInTheDocument();
  });
});
