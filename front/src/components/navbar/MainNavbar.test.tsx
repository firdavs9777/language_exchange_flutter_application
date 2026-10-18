import "@testing-library/jest-dom";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import { apiSlice } from "../../store/slices/apiSlice";
import MainNavbar from "./MainNavbar";
import { CONVERSATIONS_PAGE } from "../chat/lib/conversationMatch";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en", changeLanguage: jest.fn() } }),
}));
jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());

// Every web flag off is today's navbar; cases that need one on say so.
beforeEach(() => mockAppConfig(ALL_WEB_FLAGS_OFF));

const mockSocket = {
  on: jest.fn(),
  off: jest.fn(),
  emit: jest.fn(),
  connected: true,
};

jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: mockSocket, isConnected: true, emit: jest.fn() }),
}));

function makeStore(user: any = { _id: "me", name: "Me" }) {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: { user } }) => state,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

function mockConversationsFetch(conversations: any[]) {
  (global as any).fetch = jest.fn(async () =>
    new Response(JSON.stringify({ data: conversations }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })
  );
}

function renderNavbar(user?: any) {
  return render(
    <Provider store={user ? makeStore(user) : makeStore()}>
      <MemoryRouter>
        <MainNavbar />
      </MemoryRouter>
    </Provider>
  );
}

it("shows no unread badge when every conversation is read", async () => {
  mockConversationsFetch([
    { _id: "c1", unreadCount: 0 },
    { _id: "c2", unreadCount: 0 },
  ]);
  renderNavbar();
  await waitFor(() => expect(global.fetch).toHaveBeenCalled());
  expect(screen.queryByTestId("chat-unread-badge")).not.toBeInTheDocument();
});

it("sums unread counts across conversations into the navbar badge", async () => {
  mockConversationsFetch([
    { _id: "c1", unreadCount: 2 },
    { _id: "c2", unreadCount: 3 },
  ]);
  renderNavbar();
  await waitFor(() => expect(screen.getByTestId("chat-unread-badge")).toBeInTheDocument());
  expect(screen.getByTestId("chat-unread-badge")).toHaveTextContent("5");
});

it("caps the displayed badge at 99+", async () => {
  mockConversationsFetch([{ _id: "c1", unreadCount: 150 }]);
  renderNavbar();
  await waitFor(() => expect(screen.getByTestId("chat-unread-badge")).toBeInTheDocument());
  expect(screen.getByTestId("chat-unread-badge")).toHaveTextContent("99+");
});

// The console is the only surface in the app gated on role, so the navbar
// entry is the guard users actually see. `nav-item` (desktop) and
// `mobile-nav-link` both point at the same path — count links, not classes.
const adminLinks = () =>
  screen.queryAllByRole("link").filter((el) => el.getAttribute("href") === "/admin");

it("shows the Admin link to an admin, in the desktop and mobile menus", async () => {
  mockConversationsFetch([]);
  renderNavbar({ _id: "me", name: "Me", role: "admin" });
  expect(adminLinks().length).toBeGreaterThanOrEqual(1);

  fireEvent.click(screen.getByLabelText("Menu"));
  await waitFor(() => expect(adminLinks().length).toBeGreaterThanOrEqual(2));
});

it("hides the Admin link from a non-admin", async () => {
  mockConversationsFetch([]);
  renderNavbar({ _id: "me", name: "Me", role: "user" });
  expect(adminLinks()).toHaveLength(0);

  fireEvent.click(screen.getByLabelText("Menu"));
  await waitFor(() => expect(screen.getAllByText("community").length).toBeGreaterThan(1));
  expect(adminLinks()).toHaveLength(0);
});

// --- One cache entry, and every event that changes it ----------------------
//
// The badge and the chat sidebar read the same list. Asking for it with a
// different literal than UsersList does gives RTK Query a different cache key,
// which means two identical requests and, worse, two copies that go stale
// independently: UsersList could refetch after a read while the navbar's copy
// kept the old counts.

it("asks for the conversations with the argument the chat list shares", async () => {
  mockConversationsFetch([]);
  renderNavbar();
  await waitFor(() => expect(global.fetch).toHaveBeenCalled());

  const asked = (global.fetch as jest.Mock).mock.calls[0][0];
  const url = typeof asked === "string" ? asked : asked.url;
  expect(url).toContain(`limit=${CONVERSATIONS_PAGE.limit}`);
  expect(url).toContain(`page=${CONVERSATIONS_PAGE.page}`);
});

it("refreshes the badge on the events that change it, sending included", async () => {
  mockConversationsFetch([]);
  renderNavbar();
  await waitFor(() => expect(global.fetch).toHaveBeenCalled());

  const listened = mockSocket.on.mock.calls.map((c: any[]) => c[0]);
  // `messageSent` is what a sent message looks like from the sender's side --
  // the row order and the last message change even when no count does.
  expect(listened).toEqual(
    expect.arrayContaining([
      "newMessage",
      "newVoiceMessage",
      "newVideoMessage",
      "messagesRead",
      "messageSent",
    ])
  );
});

it("has no Reels entry while webReelsEnabled is off", () => {
  mockConversationsFetch([]);
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  const { container } = renderNavbar();
  expect(container.querySelector('a[href="/reels"]')).toBe(null);
});

it("shows Reels in the desktop and mobile menus once the flag is on", () => {
  mockConversationsFetch([]);
  mockAppConfig(ALL_WEB_FLAGS_ON);
  const { container } = renderNavbar();
  expect(container.querySelectorAll('a[href="/reels"]').length).toBeGreaterThanOrEqual(1);
});

it("has no Gatherings entry while webGatheringsEnabled is off", () => {
  mockConversationsFetch([]);
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  const { container } = renderNavbar();
  expect(container.querySelector('a[href="/gatherings"]')).toBe(null);
});

it("shows Gatherings in the navbar once the flag is on", () => {
  mockConversationsFetch([]);
  mockAppConfig(ALL_WEB_FLAGS_ON);
  const { container } = renderNavbar();
  expect(container.querySelectorAll('a[href="/gatherings"]').length).toBeGreaterThanOrEqual(1);
});
