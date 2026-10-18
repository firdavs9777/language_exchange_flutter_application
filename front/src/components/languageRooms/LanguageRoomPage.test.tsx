import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import LanguageRoomPage from "./LanguageRoomPage";

type H = (...a: any[]) => void;
const handlers: { [e: string]: H[] } = {};
const emitted: Array<[string, any]> = [];
let ackWith: any = { status: "success" };
const mockSocket = {
  on: (e: string, h: H) => ((handlers[e] = handlers[e] || []).push(h)),
  off: (e: string, h: H) => (handlers[e] = (handlers[e] || []).filter((x) => x !== h)),
  emit: (e: string, p: any, cb?: (r: any) => void) => {
    emitted.push([e, p]);
    if (cb && ackWith !== "never") cb(ackWith);
  },
};
const serverSays = (e: string, p: any) => act(() => (handlers[e] || []).slice().forEach((h) => h(p)));
let mockEpoch = 0;
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: mockSocket, isConnected: true, emit: jest.fn(), connectionEpoch: mockEpoch, kicked: false, reconnect: jest.fn() }),
}));

let mockRoom: any = {};
let mockPage: any = { data: [], pagination: { hasNextPage: false } };
const mockJoin = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
const mockLeave = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
const mockRequest = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
const mockLoadOlder = jest.fn(() => ({ unwrap: () => Promise.resolve({ data: [{ _id: "old1", createdAt: "2026-10-16T09:00:00Z", message: "older", messageType: "text", sender: { _id: "u2", name: "Ana" } }], pagination: { hasNextPage: false } }) }));
jest.mock("../../store/slices/languageRoomsSlice", () => {
  const actual = jest.requireActual("../../store/slices/languageRoomsSlice");
  return {
    languageRoomErrorText: actual.languageRoomErrorText,
    useGetLanguageRoomQuery: () => ({ data: mockRoom, refetch: jest.fn() }),
    useGetLanguageRoomMessagesQuery: (_a: any, o: any) => (o && o.skip ? { data: undefined } : { data: mockPage, refetch: jest.fn() }),
    useLazyGetLanguageRoomMessagesQuery: () => [mockLoadOlder],
    useJoinLanguageRoomMutation: () => [mockJoin],
    useLeaveLanguageRoomMutation: () => [mockLeave],
    useRequestJoinLanguageRoomMutation: () => [mockRequest],
    useGetLanguageRoomMembersQuery: () => ({ data: { data: [] } }),
    useGetLanguageRoomRequestsQuery: () => ({ data: { data: [] } }),
    useDecideLanguageRoomRequestMutation: () => [jest.fn()],
    useRemoveLanguageRoomMemberMutation: () => [jest.fn()],
  };
});
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderPage() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me", name: "Me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/rooms/r1"]}>
        <Routes>
          <Route path="/rooms/:id" element={<LanguageRoomPage />} />
          <Route path="/rooms" element={<div data-testid="rooms-list" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  Object.keys(handlers).forEach((k) => delete handlers[k]);
  emitted.length = 0;
  ackWith = { status: "success" };
  mockEpoch = 0;
  jest.clearAllMocks();
  // CRA sets resetMocks: true, so the implementations go here, not at module level.
  mockJoin.mockImplementation(() => ({ unwrap: () => Promise.resolve({}) }));
  mockLeave.mockImplementation(() => ({ unwrap: () => Promise.resolve({}) }));
  mockRequest.mockImplementation(() => ({ unwrap: () => Promise.resolve({}) }));
  mockLoadOlder.mockImplementation(() => ({ unwrap: () => Promise.resolve({ data: [{ _id: "old1", createdAt: "2026-10-16T09:00:00Z", message: "older", messageType: "text", sender: { _id: "u2", name: "Ana" } }], pagination: { hasNextPage: false } }) }));
  mockRoom = { _id: "r1", roomType: "topic", title: "K-drama", targetLanguage: "ko", isMember: true, onlineCount: 3 };
  mockPage = {
    data: [{ _id: "m1", createdAt: "2026-10-16T10:00:00Z", message: "안녕", messageType: "text", sender: { _id: "u2", name: "Ana" } }],
    pagination: { hasNextPage: true },
  };
});

it("a member sees history, subscribes to the room, and leaves the socket room on unmount", () => {
  const view = renderPage();
  expect(screen.getAllByTestId("language-room-line")[0]).toHaveTextContent("안녕");
  expect(emitted).toContainEqual(["room:join", { roomId: "r1" }]);
  view.unmount();
  expect(emitted).toContainEqual(["room:leave", { roomId: "r1" }]);
});

it("live messages and presence update the page; other rooms are ignored", () => {
  renderPage();
  serverSays("room:message", { _id: "m2", conversationId: "r1", createdAt: "2026-10-16T10:01:00Z", message: "hi", messageType: "text", sender: { _id: "u3", name: "Sam" } });
  serverSays("room:message", { _id: "m3", conversationId: "other", createdAt: "2026-10-16T10:02:00Z", message: "nope", messageType: "text", sender: { _id: "u3" } });
  serverSays("room:presence", { roomId: "r1", online: 7 });
  expect(screen.getAllByTestId("language-room-line").map((n) => n.textContent)).toEqual([expect.stringContaining("안녕"), expect.stringContaining("hi")]);
  expect(screen.getByTestId("language-room-online")).toHaveTextContent("7");
});

it("sends over the socket with an ack; the echoed message appears once", () => {
  renderPage();
  fireEvent.change(screen.getByTestId("language-room-input"), { target: { value: " hola " } });
  fireEvent.click(screen.getByTestId("language-room-send"));
  expect(emitted).toContainEqual(["room:message", { roomId: "r1", message: "hola", messageType: "text" }]);
  const echo = { _id: "m9", conversationId: "r1", createdAt: "2026-10-16T10:05:00Z", message: "hola", messageType: "text", sender: { _id: "me", name: "Me" } };
  serverSays("room:message", echo);
  serverSays("room:message", echo);
  expect(screen.getAllByTestId("language-room-line").filter((n) => /hola/.test(n.textContent || ""))).toHaveLength(1);
});

it("a refused send keeps the text and says why", () => {
  ackWith = { status: "error", error: "Too many messages — slow down." };
  renderPage();
  fireEvent.change(screen.getByTestId("language-room-input"), { target: { value: "spam" } });
  fireEvent.click(screen.getByTestId("language-room-send"));
  expect(screen.getByTestId("language-room-send-error")).toHaveTextContent(/slow down/i);
  expect((screen.getByTestId("language-room-input") as HTMLInputElement).value).toBe("spam");
});

it("loads older messages above", async () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-older"));
  await waitFor(() => expect(screen.getAllByTestId("language-room-line")[0]).toHaveTextContent("older"));
  expect(mockLoadOlder).toHaveBeenCalledWith({ roomId: "r1", page: 2 });
});

it("re-subscribes after a socket reconnect", () => {
  const view = renderPage();
  emitted.length = 0;
  mockEpoch = 1;
  view.rerender(
    <Provider store={configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s } })}>
      <MemoryRouter initialEntries={["/rooms/r1"]}>
        <Routes>
          <Route path="/rooms/:id" element={<LanguageRoomPage />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
  expect(emitted).toContainEqual(["room:join", { roomId: "r1" }]);
});

it("a non-member joins first; a banned member asks to come back", async () => {
  mockRoom = Object.assign({}, mockRoom, { isMember: false });
  const view = renderPage();
  expect(emitted.find(([e]) => e === "room:join")).toBeUndefined();
  fireEvent.click(screen.getByTestId("language-room-join"));
  await waitFor(() => expect(mockJoin).toHaveBeenCalledWith("r1"));
  view.unmount();
  mockRoom = Object.assign({}, mockRoom, { isMember: false, isBanned: true });
  const v2 = renderPage();
  fireEvent.click(screen.getByTestId("language-room-request"));
  await waitFor(() => expect(mockRequest).toHaveBeenCalledWith("r1"));
  v2.unmount();
  mockRoom = Object.assign({}, mockRoom, { isMember: false, isBanned: true, hasPendingRequest: true });
  renderPage();
  expect(screen.getByTestId("language-room-pending")).toBeInTheDocument();
});

it("leaves the room and returns to the list", async () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-leave"));
  await waitFor(() => expect(screen.getByTestId("rooms-list")).toBeInTheDocument());
  expect(mockLeave).toHaveBeenCalledWith("r1");
});
