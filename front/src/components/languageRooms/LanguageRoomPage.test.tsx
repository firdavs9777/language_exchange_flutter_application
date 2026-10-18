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
    useJoinLanguageRoomMutation: () => [mockJoin, { isLoading: false }],
    useLeaveLanguageRoomMutation: () => [mockLeave],
    useRequestJoinLanguageRoomMutation: () => [mockRequest],
    useGetLanguageRoomMembersQuery: () => ({ data: { data: [] } }),
    useGetLanguageRoomRequestsQuery: () => ({ data: { data: [] } }),
    useDecideLanguageRoomRequestMutation: () => [jest.fn()],
    useRemoveLanguageRoomMemberMutation: () => [jest.fn()],
    useUpdateLanguageRoomMutation: () => [mockUpdate, { isLoading: false }],
    useUploadLanguageRoomPhotoMutation: () => [mockUpload, { isLoading: false }],
    useDeleteLanguageRoomMessageMutation: () => [mockDelete],
  };
});
const mockUpdate = jest.fn();
const mockUpload = jest.fn();
const mockDelete = jest.fn();
const mockAddReaction = jest.fn();
const mockRemoveReaction = jest.fn();
let mockBlocked: any = { data: [] };
jest.mock("../../store/slices/chatSlice", () => ({
  useAddReactionMutation: () => [mockAddReaction],
  useRemoveReactionMutation: () => [mockRemoveReaction],
}));
jest.mock("../../store/slices/usersSlice", () => ({
  useGetBlockedUsersQuery: () => ({ data: mockBlocked }),
  useReportUserMutation: () => [mockReport, { isLoading: false }],
}));
const mockReport = jest.fn();
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
  mockBlocked = { data: [] };
  mockUpload.mockImplementation(() => ({ unwrap: () => Promise.resolve({ data: { _id: "ph1", conversationId: "r1", createdAt: "2026-10-16T10:09:00Z", messageType: "media", message: "look", media: { url: "https://x/p.jpg", type: "image" }, sender: { _id: "me", name: "Me" } } }) }));
  mockDelete.mockImplementation(() => ({ unwrap: () => Promise.resolve({}) }));
  mockUpdate.mockImplementation(() => ({ unwrap: () => Promise.resolve({}) }));
  mockAddReaction.mockImplementation(() => ({ unwrap: () => Promise.resolve({ data: [{ user: "me", emoji: "👍" }] }) }));
  mockRemoveReaction.mockImplementation(() => ({ unwrap: () => Promise.resolve({ data: [] }) }));
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

it("any other refusal says \"Failed to send message\" and keeps the text", () => {
  ackWith = { status: "error", error: "Join the room before participating" };
  renderPage();
  fireEvent.change(screen.getByTestId("language-room-input"), { target: { value: "hola" } });
  fireEvent.click(screen.getByTestId("language-room-send"));
  expect(screen.getByTestId("language-room-send-error")).toHaveTextContent("Failed to send message");
  expect((screen.getByTestId("language-room-input") as HTMLInputElement).value).toBe("hola");
});

it("replies with a quote and sends replyTo", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-reply-m1"));
  expect(screen.getByTestId("reply-composer-bar")).toBeInTheDocument();
  fireEvent.change(screen.getByTestId("language-room-input"), { target: { value: "네" } });
  fireEvent.click(screen.getByTestId("language-room-send"));
  expect(emitted).toContainEqual(["room:message", { roomId: "r1", message: "네", messageType: "text", replyTo: "m1" }]);
  serverSays("room:message", { _id: "m5", conversationId: "r1", createdAt: "2026-10-16T10:06:00Z", message: "네", messageType: "text", sender: { _id: "me", name: "Me" }, replyTo: { _id: "m1", message: "안녕", sender: { name: "Ana" } } });
  expect(screen.getByTestId("language-room-quote-m5")).toHaveTextContent("안녕");
});

it("sender name and avatar open that member's profile", () => {
  renderPage();
  expect(screen.getByTestId("language-room-sender-m1").getAttribute("href")).toBe("/profile/u2");
  expect(screen.getByTestId("language-room-avatar-m1").getAttribute("href")).toBe("/profile/u2");
});

it("reacts through the message reactions API and shows live reaction updates", async () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-react-m1"));
  fireEvent.click(screen.getByTestId("quick-pick-👍"));
  await waitFor(() => expect(mockAddReaction).toHaveBeenCalledWith({ messageId: "m1", emoji: "👍" }));
  await waitFor(() => expect(screen.getByTestId("reaction-chip-👍")).toHaveTextContent("1"));
  serverSays("messageReaction", { messageId: "m1", reactions: [{ user: "me", emoji: "👍" }, { user: "u3", emoji: "👍" }] });
  expect(screen.getByTestId("reaction-chip-👍")).toHaveTextContent("2");
  fireEvent.click(screen.getByTestId("reaction-chip-👍"));
  await waitFor(() => expect(mockRemoveReaction).toHaveBeenCalledWith({ messageId: "m1", emoji: "👍" }));
});

it("uploads a photo with the typed caption", async () => {
  renderPage();
  const file = new File(["x"], "p.jpg", { type: "image/jpeg" });
  fireEvent.change(screen.getByTestId("language-room-photo-input"), { target: { files: [file] } });
  expect(screen.getByTestId("language-room-photo-chip")).toHaveTextContent("p.jpg");
  fireEvent.change(screen.getByTestId("language-room-input"), { target: { value: "look" } });
  fireEvent.click(screen.getByTestId("language-room-send"));
  await waitFor(() => expect(mockUpload).toHaveBeenCalledWith({ roomId: "r1", file, caption: "look", replyTo: undefined }));
  await waitFor(() => expect(document.querySelector('[data-message-id="ph1"] img')).toBeTruthy());
});

it("deletes your own message after confirming; a live delete removes it for everyone", async () => {
  mockPage = {
    data: [
      { _id: "m1", createdAt: "2026-10-16T10:00:00Z", message: "안녕", messageType: "text", sender: { _id: "u2", name: "Ana" } },
      { _id: "mine", createdAt: "2026-10-16T10:01:00Z", message: "mine", messageType: "text", sender: { _id: "me", name: "Me" } },
    ],
    pagination: { hasNextPage: false },
  };
  renderPage();
  // Not a moderator: no delete on someone else's message, but report is there.
  fireEvent.click(screen.getByTestId("language-room-more-m1"));
  expect(screen.queryByTestId("language-room-delete-m1")).not.toBeInTheDocument();
  expect(screen.getByTestId("language-room-report-m1")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("language-room-more-mine"));
  fireEvent.click(screen.getByTestId("language-room-delete-mine"));
  fireEvent.click(screen.getByTestId("lr-delete-confirm"));
  await waitFor(() => expect(mockDelete).toHaveBeenCalledWith({ roomId: "r1", messageId: "mine" }));
  await waitFor(() => expect(document.querySelector('[data-message-id="mine"]')).toBeNull());
  serverSays("room:messageDeleted", { roomId: "r1", messageId: "m1" });
  expect(document.querySelector('[data-message-id="m1"]')).toBeNull();
});

it("a moderator can delete anyone's message", () => {
  mockRoom = Object.assign({}, mockRoom, { isOwnerOrAdmin: true, owner: "me" });
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-more-m1"));
  expect(screen.getByTestId("language-room-delete-m1")).toBeInTheDocument();
});

it("reports a message through the shared report dialog", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-more-m1"));
  fireEvent.click(screen.getByTestId("language-room-report-m1"));
  expect(screen.getByText("Report this message")).toBeInTheDocument();
});

it("hides messages from people you blocked, live ones too", () => {
  mockBlocked = { data: [{ userId: "u3" }] };
  renderPage();
  serverSays("room:message", { _id: "mb", conversationId: "r1", createdAt: "2026-10-16T10:07:00Z", message: "blocked", messageType: "text", sender: { _id: "u3", name: "X" } });
  expect(document.querySelector('[data-message-id="mb"]')).toBeNull();
});

it("pins the daily prompt as the question of the day; other system lines stay inline", () => {
  renderPage();
  serverSays("room:message", { _id: "q", conversationId: "r1", createdAt: "2026-10-16T10:08:00Z", message: "What's your favourite food?", messageType: "system", promptId: "p1" });
  serverSays("room:message", { _id: "s", conversationId: "r1", createdAt: "2026-10-16T10:08:30Z", message: "Sam joined", messageType: "system" });
  expect(screen.getByTestId("language-room-prompt")).toHaveTextContent("favourite food");
  const lines = screen.getAllByTestId("language-room-line").map((n) => n.textContent);
  expect(lines).toContain("Sam joined");
  expect(lines.some((l) => /favourite food/.test(l || ""))).toBe(false);
});

it("shows who is typing and sends typing for members", () => {
  renderPage();
  serverSays("room:typing", { roomId: "r1", userId: "u2", userName: "Ana", isTyping: true });
  expect(screen.getByTestId("language-room-typing")).toHaveTextContent("Ana");
  serverSays("room:typing", { roomId: "r1", userId: "u2", userName: "Ana", isTyping: false });
  expect(screen.queryByTestId("language-room-typing")).not.toBeInTheDocument();
  fireEvent.change(screen.getByTestId("language-room-input"), { target: { value: "a" } });
  expect(emitted).toContainEqual(["room:typing", { roomId: "r1", isTyping: true }]);
});

it("the title opens room info; a moderator can edit it", async () => {
  mockRoom = Object.assign({}, mockRoom, { isOwnerOrAdmin: true, owner: "me", description: "Talk dramas", memberCount: 9 });
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-title"));
  expect(screen.getByTestId("lr-info-language")).toHaveTextContent("Korean");
  expect(screen.getByTestId("lr-info-counts")).toHaveTextContent("9");
  expect(screen.getByTestId("lr-info-description")).toHaveTextContent("Talk dramas");
  fireEvent.click(screen.getByTestId("lr-info-edit"));
  fireEvent.change(screen.getByTestId("lr-edit-title"), { target: { value: "K-drama club" } });
  fireEvent.click(screen.getByTestId("lr-edit-save"));
  await waitFor(() => expect(mockUpdate).toHaveBeenCalledWith({ roomId: "r1", title: "K-drama club", description: "Talk dramas" }));
});

it("room info offers no edit to ordinary members", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-title"));
  expect(screen.queryByTestId("lr-info-edit")).not.toBeInTheDocument();
  expect(screen.getByTestId("lr-info-members")).toBeInTheDocument();
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

it("a visitor reads and watches live without joining, and joins from the bar; a banned member asks to come back", async () => {
  mockRoom = Object.assign({}, mockRoom, { isMember: false });
  const view = renderPage();
  expect(screen.getAllByTestId("language-room-line")[0]).toHaveTextContent("안녕");
  expect(emitted).toContainEqual(["room:join", { roomId: "r1" }]);
  expect(screen.queryByTestId("language-room-input")).not.toBeInTheDocument();
  expect(screen.queryByTestId("language-room-reply-m1")).not.toBeInTheDocument();
  expect(mockJoin).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("language-room-join"));
  await waitFor(() => expect(mockJoin).toHaveBeenCalledWith("r1"));
  view.unmount();
  mockRoom = Object.assign({}, mockRoom, { isMember: false, isBanned: true });
  emitted.length = 0;
  const v2 = renderPage();
  expect(emitted.find(([e]) => e === "room:join")).toBeUndefined();
  fireEvent.click(screen.getByTestId("language-room-request"));
  await waitFor(() => expect(mockRequest).toHaveBeenCalledWith("r1"));
  v2.unmount();
  mockRoom = Object.assign({}, mockRoom, { isMember: false, isBanned: true, hasPendingRequest: true });
  renderPage();
  expect(screen.getByTestId("language-room-pending")).toBeInTheDocument();
});

it("leaves the room from room info and returns to the list", async () => {
  renderPage();
  fireEvent.click(screen.getByTestId("language-room-title"));
  fireEvent.click(screen.getByTestId("language-room-leave"));
  await waitFor(() => expect(screen.getByTestId("rooms-list")).toBeInTheDocument());
  expect(mockLeave).toHaveBeenCalledWith("r1");
});
