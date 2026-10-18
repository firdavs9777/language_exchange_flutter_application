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
import NearbyUsers, {
  formatNearbyDistance,
  nearbyIsOnline,
  nearbyPlace,
  isRadiusLocked,
  RADIUS_OPTIONS,
} from "./NearbyUsers";

// The key plus whatever was interpolated: behaviour, not copy.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, o?: any) => (o ? `${key} ${Object.values(o).join(" ")}` : key),
  }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const ROWS = [
  {
    _id: "n1",
    name: "Near One",
    images: ["users/n1.jpg"],
    native_language: "Korean",
    language_to_learn: "English",
    distance: 0.42,
    isOnline: true,
    location: { city: "Seoul", country: "South Korea" },
    privacySettings: { showCity: true, showCountryRegion: true, showOnlineStatus: true },
  },
  {
    // An app user who hid their city and online status. The server already
    // drops both; a stale or older payload must not show them either.
    _id: "n2",
    name: "Near Two",
    images: [],
    native_language: "Japanese",
    language_to_learn: "Korean",
    distance: 12.6,
    isOnline: true,
    location: { city: "Busan", country: "South Korea" },
    privacySettings: { showCity: false, showOnlineStatus: false },
  },
];

const requested: string[] = [];
let searchMeta: any = undefined;
const originalFetch = global.fetch;
const originalGeo = (navigator as any).geolocation;

beforeEach(() => {
  requested.length = 0;
  searchMeta = undefined;
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    requested.push(url);
    const body =
      url.indexOf("/community/nearby") >= 0
        ? {
            success: true,
            data: ROWS,
            pagination: { total: 2, limit: 50, offset: 0, hasMore: false },
            ...(searchMeta ? { search: searchMeta } : {}),
          }
        : { success: true, data: [] };
    return Promise.resolve(
      new Response(JSON.stringify(body), {
        status: 200,
        headers: { "content-type": "application/json" },
      })
    );
  });
  Object.defineProperty(navigator, "geolocation", {
    configurable: true,
    value: {
      getCurrentPosition: (ok: any) => ok({ coords: { latitude: 37.5665, longitude: 126.978 } }),
    },
  });
});

afterEach(() => {
  global.fetch = originalFetch;
  Object.defineProperty(navigator, "geolocation", { configurable: true, value: originalGeo });
});

const SIGNED_IN = { auth: { userInfo: { user: { _id: "u1" }, token: "t" } } };

function renderNearby() {
  const router = createMemoryRouter(
    createRoutesFromElements(
      <Route path="/">
        <Route path="community/nearby" element={<NearbyUsers />} />
        <Route path="community/:userId" element={<div data-testid="profile-screen" />} />
        <Route path="settings/vip" element={<div data-testid="vip-screen" />} />
      </Route>
    ),
    { initialEntries: ["/community/nearby"] }
  );
  render(
    <Provider store={makeStore(SIGNED_IN)}>
      <RouterProvider router={router} />
    </Provider>
  );
  return router;
}

const nearbyRequests = () => requested.filter((u) => u.indexOf("/community/nearby") >= 0);

describe("Nearby radius cap (free 50 km, VIP 500 km)", () => {
  it("offers 5..200 km and locks what is above the cap", () => {
    expect(RADIUS_OPTIONS).toEqual([5, 10, 25, 50, 100, 200]);
    expect(isRadiusLocked(50)).toBe(false);
    expect(isRadiusLocked(100)).toBe(true);
    expect(isRadiusLocked(200, 500)).toBe(false);
  });

  it("a locked radius opens the VIP page instead of searching", async () => {
    searchMeta = { radiusKm: 10, maxRadiusKm: 50 };
    const router = renderNearby();
    await screen.findByText("Near One");
    expect(screen.getAllByTestId("nearby-radius-lock")).toHaveLength(2);
    const before = nearbyRequests().length;
    fireEvent.click(screen.getByTestId("nearby-radius-100"));
    await waitFor(() => expect(router.state.location.pathname).toBe("/settings/vip"));
    expect(nearbyRequests().filter((u) => u.indexOf("radius=100") >= 0)).toHaveLength(0);
    expect(nearbyRequests().length).toBe(before);
  });

  it("a VIP cap from the server unlocks every option", async () => {
    searchMeta = { radiusKm: 10, maxRadiusKm: 500 };
    renderNearby();
    await screen.findByText("Near One");
    await waitFor(() => expect(screen.queryByTestId("nearby-radius-lock")).not.toBeInTheDocument());
  });
});

describe("Nearby (community#2)", () => {
  it("asks with the parameter names the server reads", async () => {
    renderNearby();
    await screen.findByText("Near One");
    const url = new URL(nearbyRequests()[nearbyRequests().length - 1]);
    expect(url.searchParams.get("latitude")).toBe("37.5665");
    expect(url.searchParams.get("longitude")).toBe("126.978");
    expect(url.searchParams.get("offset")).toBe("0");
    expect(url.searchParams.get("lat")).toBeNull();
  });

  it("loads the photo from the raw storage path the endpoint returns", async () => {
    renderNearby();
    const img = await screen.findByAltText("Near One");
    expect(img).toHaveAttribute("src", "http://localhost:5003/uploads/users/n1.jpg");
  });

  it("reads the snake_case language fields", async () => {
    renderNearby();
    await screen.findByText("Near One");
    expect(screen.getAllByTestId("nearby-native")[0]).toHaveTextContent("Korean");
    expect(screen.getAllByTestId("nearby-learning")[0]).toHaveTextContent(
      "communityNearby.learning English"
    );
  });

  it("honours the hidden city and hidden online status", async () => {
    renderNearby();
    await screen.findByText("Near Two");
    expect(screen.getAllByTestId("nearby-online-dot")).toHaveLength(1);
    const places = screen.getAllByTestId("nearby-place").map((el) => el.textContent);
    expect(places).toEqual(["Seoul, South Korea", "South Korea"]);
  });

  it("opens the member on /community/:id, which is a real route", async () => {
    const router = renderNearby();
    fireEvent.click(await screen.findByText("Near One"));
    await waitFor(() => expect(router.state.location.pathname).toBe("/community/n1"));
    expect(screen.getByTestId("profile-screen")).toBeInTheDocument();
  });

  it("uses the app's distance format", () => {
    expect(formatNearbyDistance(0.42)).toBe("420m");
    expect(formatNearbyDistance(3.14)).toBe("3.1km");
    expect(formatNearbyDistance(12.6)).toBe("13km");
    expect(formatNearbyDistance(undefined)).toBe("");
  });

  it("keeps the privacy helpers pure", () => {
    expect(nearbyIsOnline({ _id: "x", name: "x", isOnline: true })).toBe(true);
    expect(
      nearbyIsOnline({ _id: "x", name: "x", isOnline: true, privacySettings: { showOnlineStatus: false } })
    ).toBe(false);
    expect(
      nearbyPlace({
        _id: "x",
        name: "x",
        location: { city: "Seoul", country: "South Korea" },
        privacySettings: { showCountryRegion: false },
      })
    ).toBe("Seoul");
  });
});
