import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import {
  createMemoryRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from "react-router-dom";
import { makeStore } from "../../store";
import Waves, { waveAvatarUrl } from "./Waves";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, o?: any) => (o ? `${key} ${Object.values(o).join(" ")}` : key),
  }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const wave = (id: string, name: string, extra: any = {}) => ({
  waveId: id,
  from: { _id: `from-${id}`, name, images: [`users/${id}.jpg`] },
  message: "",
  createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
  isRead: true,
  ...extra,
});

let recent: any[] = [];
let archived: any[] = [];
let unread = 0;
let boostsEnabled = false;
const requests: { url: string; method: string }[] = [];
const originalFetch = global.fetch;

beforeEach(() => {
  recent = [wave("w1", "Ada")];
  archived = [wave("w9", "Old Bob")];
  unread = 0;
  boostsEnabled = false;
  requests.length = 0;
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    const method = (input && input.method) || "GET";
    requests.push({ url, method });
    let body: any = { success: true, data: [] };
    if (url.indexOf("/app-config") >= 0) {
      body = { success: true, data: { boostsEnabled } };
    } else if (url.indexOf("/community/waves/read") >= 0) {
      body = { success: true };
    } else if (url.indexOf("/community/waves") >= 0) {
      const isArchive = url.indexOf("archive=true") >= 0;
      body = {
        success: true,
        data: { waves: isArchive ? archived : recent, unreadCount: unread },
        pagination: { total: 1, page: 1, limit: 20, hasMore: false },
      };
    }
    return Promise.resolve(
      new Response(JSON.stringify(body), { status: 200, headers: { "content-type": "application/json" } })
    );
  });
});

afterEach(() => {
  global.fetch = originalFetch;
});

const SIGNED_IN = { auth: { userInfo: { user: { _id: "u1" }, token: "t" } } };

function renderWaves() {
  const router = createMemoryRouter(
    createRoutesFromElements(
      <Route path="/">
        <Route path="waves" element={<Waves />} />
        <Route path="communities" element={<div data-testid="communities-screen" />} />
        <Route path="community/:userId" element={<div data-testid="profile-screen" />} />
      </Route>
    ),
    { initialEntries: ["/waves"] }
  );
  render(
    <Provider store={makeStore(SIGNED_IN)}>
      <RouterProvider router={router} />
    </Provider>
  );
  return router;
}

const waveRequests = () =>
  requests.filter((r) => r.url.indexOf("/community/waves") >= 0 && r.url.indexOf("/read") < 0);

describe("waves inbox (community#10)", () => {
  it("loads the sender's photo from the raw storage path", async () => {
    renderWaves();
    const img = await screen.findByAltText("Ada");
    expect(img).toHaveAttribute("src", "http://localhost:5003/uploads/users/w1.jpg");
  });

  it("switches to the 7-30 day archive with archive=true", async () => {
    renderWaves();
    await screen.findByText("Ada");
    fireEvent.click(screen.getByTestId("waves-archive-toggle"));
    expect(await screen.findByText("Old Bob")).toBeInTheDocument();
    expect(screen.queryByText("Ada")).not.toBeInTheDocument();
    const last = waveRequests()[waveRequests().length - 1].url;
    expect(last).toContain("archive=true");
  });

  it("asks with reveal=1 only while boostsEnabled is on, as the app does", async () => {
    boostsEnabled = true;
    renderWaves();
    await screen.findByText("Ada");
    expect(waveRequests().every((r) => r.url.indexOf("reveal=1") >= 0)).toBe(true);
  });

  it("sends no reveal while the flag is off", async () => {
    renderWaves();
    await screen.findByText("Ada");
    expect(waveRequests().some((r) => r.url.indexOf("reveal=") >= 0)).toBe(false);
  });

  it("marks unread waves read from the recent list", async () => {
    unread = 1;
    renderWaves();
    await screen.findByText("Ada");
    await waitFor(() =>
      expect(requests.some((r) => r.url.indexOf("/community/waves/read") >= 0 && r.method === "PUT")).toBe(true)
    );
  });

  it("sends 'Find people' to /communities, which is a real route", async () => {
    recent = [];
    const router = renderWaves();
    fireEvent.click(await screen.findByText("waves.findPeople"));
    await waitFor(() => expect(router.state.location.pathname).toBe("/communities"));
  });

  it("builds avatars from imageUrls, raw paths and legacy {url} objects", () => {
    expect(waveAvatarUrl({ _id: "a", name: "a", imageUrls: ["https://cdn/x.jpg"] })).toBe("https://cdn/x.jpg");
    expect(waveAvatarUrl({ _id: "a", name: "a", images: ["users/a.jpg"] })).toBe(
      "http://localhost:5003/uploads/users/a.jpg"
    );
    expect(waveAvatarUrl({ _id: "a", name: "a", images: [{ url: "https://cdn/y.jpg" }] })).toBe(
      "https://cdn/y.jpg"
    );
    expect(waveAvatarUrl(null)).toBeUndefined();
  });
});
