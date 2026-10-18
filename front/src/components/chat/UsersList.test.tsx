import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, act } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import UsersList from "./UsersList";
import { CONVERSATIONS_PAGE } from "./lib/conversationMatch";

// CRA resets mocks between tests: module-scoped, `mock`-prefixed factories,
// implementations handed out in beforeEach.
const mockUseSocket = jest.fn();
const mockConversations = jest.fn();
const mockDelete = jest.fn();
const mockPin = jest.fn();
const mockUnpin = jest.fn();
const mockMute = jest.fn();
const mockArchive = jest.fn();
const mockUnarchive = jest.fn();
const mockUnmute = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("./hooks/useSocket", () => ({
  useSocket: () => mockUseSocket(),
}));

jest.mock("../../store/slices/chatSlice", () => ({
  useGetConversationsQuery: (arg: any, opts: any) => mockConversations(arg, opts),
  useDeleteConversationMutation: () => [mockDelete, { isLoading: false }],
  usePinConversationMutation: () => [mockPin, { isLoading: false }],
  useUnpinConversationMutation: () => [mockUnpin, { isLoading: false }],
  useMuteConversationMutation: () => [mockMute, { isLoading: false }],
  useUnmuteConversationMutation: () => [mockUnmute, { isLoading: false }],
  useArchiveConversationMutation: () => [mockArchive, { isLoading: false }],
  useUnarchiveConversationMutation: () => [mockUnarchive, { isLoading: false }],
}));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });

const onSelectUser = jest.fn();

function conversation(overrides: any = {}) {
  return {
    _id: "c1",
    participants: [
      { _id: "me", name: "Me", images: [] },
      { _id: "u2", name: "Ada", images: [] },
    ],
    lastMessage: { message: "hi", createdAt: "2026-09-20T10:00:00.000Z" },
    unreadCount: 0,
    isPinned: false,
    isMuted: false,
    ...overrides,
  };
}

function renderList() {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: { user: { _id: "me", name: "Me" }, token: "t" } }) =>
        state,
    },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <UsersList onSelectUser={onSelectUser} activeUserId={null} />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockUseSocket.mockReturnValue({ socket: null, isConnected: false });
  mockConversations.mockReturnValue({
    data: { data: [conversation()] },
    isLoading: false,
    isError: false,
    error: undefined,
    refetch: jest.fn(),
  });
  mockMute.mockReturnValue(resolved());
  mockArchive.mockReturnValue(resolved());
  mockUnarchive.mockReturnValue(resolved());
  mockUnmute.mockReturnValue(resolved());
  mockDelete.mockReturnValue(resolved());
});

afterEach(() => {
  jest.clearAllMocks();
});

it("asks for conversations with the argument the info panel shares", () => {
  renderList();
  expect(mockConversations).toHaveBeenCalledWith(
    CONVERSATIONS_PAGE,
    expect.objectContaining({ skip: false })
  );
});

it("resolves the conversation through the shared matcher, otherParticipant first", () => {
  mockConversations.mockReturnValue({
    data: {
      data: [
        {
          _id: "c1",
          otherParticipant: { _id: "u2", name: "Ada", images: [] },
          participants: [
            { _id: "me", name: "Me", images: [] },
            { _id: "u2", name: "Ada", images: [] },
          ],
          isMuted: false,
        },
      ],
    },
    refetch: jest.fn(),
  });
  renderList();
  fireEvent.click(screen.getByTestId("users-list-menu-u2"));
  fireEvent.click(screen.getByTestId("users-list-mute-u2"));
  fireEvent.click(screen.getByTestId("mute-option-always"));
  expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1" });
});

it("sends the row's avatar to the member page without opening the chat", () => {
  renderList();
  const link = screen.getByTestId("users-list-avatar-link-u2");
  expect(link).toHaveAttribute("href", "/community/u2");

  fireEvent.click(link);
  expect(onSelectUser).not.toHaveBeenCalled();
});

it("still opens the chat when the row itself is clicked", () => {
  renderList();
  fireEvent.click(screen.getByText("Ada"));
  expect(onSelectUser).toHaveBeenCalledWith("u2", "Ada", "", false, undefined);
});

it("mutes a conversation from the row's menu", async () => {
  renderList();
  fireEvent.click(screen.getByTestId("users-list-menu-u2"));
  fireEvent.click(screen.getByTestId("users-list-mute-u2"));
  fireEvent.click(screen.getByTestId("mute-option-always"));
  expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1" });
  await waitFor(() => expect(mockMute).toHaveBeenCalledTimes(1));
});

it("unmutes one that is already muted", async () => {
  mockConversations.mockReturnValue({
    data: { data: [conversation({ isMuted: true })] },
    refetch: jest.fn(),
  });
  renderList();
  fireEvent.click(screen.getByTestId("users-list-menu-u2"));
  fireEvent.click(screen.getByTestId("users-list-mute-u2"));
  expect(mockUnmute).toHaveBeenCalledWith("c1");
  expect(mockMute).not.toHaveBeenCalled();
});

it("asks the delete question as one sentence with the name inside it", () => {
  renderList();
  fireEvent.click(screen.getByTestId("users-list-menu-u2"));
  fireEvent.click(screen.getByTestId("users-list-delete-u2"));

  // One interpolated sentence, not a prefix concatenated with a <strong> --
  // the fragment could not be translated into a language that puts the name
  // anywhere but last.
  expect(screen.getByTestId("users-list-delete-body")).toHaveTextContent(
    "Delete your conversation with Ada?"
  );
});

// --- Reading a conversation has to reach the badge ------------------------
//
// Opening a thread emits `markAsRead`. The server answers the emitter through
// the ack callback and pushes `messagesRead` to the OTHER person -- so the
// tab that just did the reading never receives a socket event about it, and
// only the ack tells it anything happened. That ack refetched the messages
// query and left the conversations query alone, which is the one holding the
// unread counts the sidebar rows and the navbar badge are drawn from. The
// badge therefore kept whatever number it had until a full reload.

/** A connected socket that answers markAsRead the way the server does. */
function readingSocket() {
  const emit = jest.fn((event: string, _data: any, cb?: (r: any) => void) => {
    if (event === "markAsRead" && cb) cb({ status: "success", markedCount: 3 });
  });
  return { socket: { on: jest.fn(), off: jest.fn(), emit, connected: true }, isConnected: true };
}

function renderListFor(activeUserId: string) {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: { user: { _id: "me", name: "Me" }, token: "t" } }) =>
        state,
    },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <UsersList onSelectUser={onSelectUser} activeUserId={activeUserId} />
      </MemoryRouter>
    </Provider>
  );
}

it("refetches the conversations once the messages are marked read", async () => {
  const refetchConversations = jest.fn();
  mockUseSocket.mockReturnValue(readingSocket());
  mockConversations.mockReturnValue({
    data: { data: [conversation({ unreadCount: 3 })] },
    refetch: refetchConversations,
  });

  renderListFor("u2");

  await waitFor(() => expect(refetchConversations).toHaveBeenCalled());
});

// --- The list is the conversations endpoint, and nothing else ---------------

it("shows a conversation the server returns, with a typed preview", () => {
  mockConversations.mockReturnValue({
    data: {
      data: [conversation({ lastMessage: { messageType: "voice", message: "", createdAt: "2026-09-20T10:00:00.000Z" } })],
    },
    isLoading: false,
    isError: false,
    refetch: jest.fn(),
  });
  renderList();
  expect(screen.getByText("🎤 Voice message")).toBeInTheDocument();
});

it("does not invent rows from raw messages (deleted conversations stay deleted)", () => {
  mockConversations.mockReturnValue({ data: { data: [] }, isLoading: false, isError: false, refetch: jest.fn() });
  renderList();
  expect(screen.queryByText("Ada")).not.toBeInTheDocument();
});

it("shows the server's unread count", () => {
  mockConversations.mockReturnValue({
    data: { data: [conversation({ unreadCount: 5 })] },
    isLoading: false,
    isError: false,
    refetch: jest.fn(),
  });
  renderList();
  expect(screen.getByTestId("users-list-unread-u2")).toHaveTextContent("5");
});

it("counts a live message up from the server count instead of trusting newMessage.unreadCount", () => {
  const handlers: Record<string, Function[]> = {};
  mockUseSocket.mockReturnValue({
    socket: {
      connected: false,
      on: (e: string, fn: Function) => {
        (handlers[e] = handlers[e] || []).push(fn);
      },
      off: jest.fn(),
      emit: jest.fn(),
    },
    isConnected: false,
  });
  mockConversations.mockReturnValue({
    data: { data: [conversation({ unreadCount: 4 })] },
    isLoading: false,
    isError: false,
    refetch: jest.fn(),
  });
  renderList();
  act(() => {
    handlers["newMessage"].forEach((fn) =>
      fn({ message: { _id: "m9", sender: { _id: "u2" }, receiver: "me" }, unreadCount: 1, senderId: "u2" })
    );
  });
  expect(screen.getByTestId("users-list-unread-u2")).toHaveTextContent("5");
});

it("words a call preview from the reader's side", () => {
  mockConversations.mockReturnValue({
    data: {
      data: [
        conversation({
          lastMessage: {
            messageType: "call",
            message: "",
            sender: "u2",
            media: { type: "call", callData: { outcome: "no_answer", initiator: "u2" } },
            createdAt: "2026-09-20T10:00:00.000Z",
          },
        }),
      ],
    },
    isLoading: false,
    isError: false,
    refetch: jest.fn(),
  });
  renderList();
  expect(screen.getByText("Missed voice call")).toBeInTheDocument();
});

it("mutes from the row's menu for the chosen time", () => {
  renderList();
  fireEvent.click(screen.getByTestId("users-list-menu-u2"));
  fireEvent.click(screen.getByTestId("users-list-mute-u2"));
  fireEvent.click(screen.getByTestId("mute-option-1w"));
  expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1", duration: 604800000 });
});

it("hides archived chats from the list and shows them behind the Archived toggle", () => {
  mockConversations.mockReturnValue({
    data: {
      data: [
        conversation(),
        conversation({
          _id: "c2",
          isArchived: true,
          participants: [
            { _id: "me", name: "Me", images: [] },
            { _id: "u3", name: "Bo", images: [] },
          ],
        }),
      ],
    },
    refetch: jest.fn(),
  });
  renderList();
  expect(screen.getByText("Ada")).toBeInTheDocument();
  expect(screen.queryByText("Bo")).toBeNull();

  fireEvent.click(screen.getByTestId("users-list-archived-toggle"));
  expect(screen.getByText("Bo")).toBeInTheDocument();
  expect(screen.queryByText("Ada")).toBeNull();
});

it("archives from the row's menu", async () => {
  renderList();
  fireEvent.click(screen.getByTestId("users-list-menu-u2"));
  fireEvent.click(screen.getByTestId("users-list-archive-u2"));
  expect(mockArchive).toHaveBeenCalledWith("c1");
});

it("offers no Archived toggle when nothing is archived", () => {
  renderList();
  expect(screen.queryByTestId("users-list-archived-toggle")).toBeNull();
});
