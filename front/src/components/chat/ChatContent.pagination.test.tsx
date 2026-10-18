import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, act } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import ChatContent from "./ChatContent";

/**
 * The web chat asked the backend for one page of 50 messages and stopped
 * there: on a longer thread everything older was unreachable. This suite
 * covers the way back — the sentinel above the first message asks for the
 * previous page, the older messages land ABOVE what is on screen, and the
 * thread does not jump under the reader while they land.
 *
 * `useGetConversationQuery` is mocked to answer the way the merged cache
 * entry does: page 1 is the newest page, and once page 2 has been asked for
 * the entry holds both, oldest first.
 */
const mockUseSocket = jest.fn();
const mockGetConversation = jest.fn();
const mockUpdateQueryData = jest.fn();
const mockInvalidateTags = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("./hooks/useSocket", () => ({
  useSocket: () => mockUseSocket(),
}));

const mutation = () => [jest.fn(), { isLoading: false }];

jest.mock("../../store/slices/chatSlice", () => ({
  chatApiSlice: {
    util: {
      updateQueryData: (...args: any[]) => mockUpdateQueryData(...args),
      invalidateTags: (...args: any[]) => mockInvalidateTags(...args),
    },
  },
  useGetConversationQuery: (arg: any, opts: any) => mockGetConversation(arg, opts),
  useGetConversationsQuery: () => ({ data: undefined, isLoading: false, isError: false }),
  useCreateMessageMutation: () => mutation(),
  useSendVoiceMessageMutation: () => mutation(),
  useSendMediaMessageMutation: () => mutation(),
  useSendVideoMessageMutation: () => mutation(),
  useGetVideoMessageConfigQuery: () => ({ data: undefined }),
  useEditMessageMutation: () => mutation(),
  useDeleteMessageMutation: () => mutation(),
  useAddReactionMutation: () => mutation(),
  useRemoveReactionMutation: () => mutation(),
  usePinMessageMutation: () => mutation(),
  useBookmarkMessageMutation: () => mutation(),
  useForwardMessageMutation: () => mutation(),
  useReplyToMessageMutation: () => mutation(),
  useTtsMessageMutation: () => mutation(),
  useTranslateMessageMutation: () => mutation(),
  useSaveMessageVocabularyMutation: () => mutation(),
}));

jest.mock("../../store/slices/learningSlice", () => ({
  useSendCorrectionMutation: () => mutation(),
  useAcceptCorrectionMutation: () => mutation(),
}));

// Owns its own store hooks; its suite is components/LocationShareButton.test.tsx.
// Owns its own query; its suite is components/MessageSearchDialog.test.tsx.
const mockNotifyInfo = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { info: (m: string) => mockNotifyInfo(m), error: jest.fn(), success: jest.fn(), warning: jest.fn() },
}));

jest.mock("./components/MessageSearchDialog", () => ({
  __esModule: true,
  default: (props: any) =>
    require("react").createElement(
      "div",
      { "data-testid": "chat-search-dialog" },
      require("react").createElement("button", { "data-testid": "search-jump-loaded", onClick: () => props.onJump("newer-b") }),
      require("react").createElement("button", { "data-testid": "search-jump-missing", onClick: () => props.onJump("not-loaded") })
    ),
}));

jest.mock("./lib/useChatBlockState", () => ({
  useChatBlockState: () => ({ blocked: false, iBlocked: false, blockedMe: false }),
}));

jest.mock("./components/LocationShareButton", () => ({
  __esModule: true,
  default: () => require("react").createElement("span", { "data-testid": "share-location" }),
}));

jest.mock("./ChatInfoPanel", () => ({
  __esModule: true,
  default: () => require("react").createElement("div", null),
}));

const msg = (id: string, createdAt: string, own = false) => ({
  _id: id,
  message: id,
  createdAt,
  sender: own ? { _id: "me", name: "Me" } : { _id: "u2", name: "Ada" },
  receiver: own ? { _id: "u2", name: "Ada" } : { _id: "me", name: "Me" },
});

const OWN_PAGE_1 = [
  msg("newer-a", "2026-09-20T10:00:00.000Z", true),
  msg("newer-b", "2026-09-20T10:05:00.000Z", true),
];

const PAGE_1 = [
  msg("newer-a", "2026-09-20T10:00:00.000Z"),
  msg("newer-b", "2026-09-20T10:05:00.000Z"),
];
const PAGE_2 = [
  msg("older-a", "2026-09-19T10:00:00.000Z"),
  msg("older-b", "2026-09-19T10:05:00.000Z"),
];

const response = (data: any[], totalPages: number, total: number) => ({
  success: true,
  count: data.length,
  total,
  pagination: { currentPage: 1, totalPages, limit: 2, hasNextPage: true, hasPrevPage: false },
  data,
});

/**
 * The merged cache entry, as a function of the page asked for — exactly what
 * `getConversation`'s `merge` builds.
 */
function answerWith(
  options: {
    totalPages?: number;
    fetchingOlder?: boolean;
    total?: number;
    own?: boolean;
    /** Replace page 1 outright, for fixtures that need their own flags. */
    page1?: any[];
  } = {}
) {
  const totalPages = options.totalPages === undefined ? 2 : options.totalPages;
  const total = options.total === undefined ? 4 : options.total;
  // One STABLE object per page, the way RTK Query hands the same cache entry
  // back until it actually changes. A fresh object per render would restart
  // the effect that seeds the message list on every pass.
  const newest = {
    data: response(
      options.page1 || (options.own ? OWN_PAGE_1 : PAGE_1),
      totalPages,
      total
    ),
    error: undefined,
    isLoading: false,
    isFetching: false,
  };
  const merged = {
    data: response(PAGE_2.concat(PAGE_1), totalPages, total),
    error: undefined,
    isLoading: false,
    isFetching: !!options.fetchingOlder,
  };
  mockGetConversation.mockImplementation((arg: any) => (arg.page >= 2 ? merged : newest));
}

const liveMessage = (id: string) => ({
  _id: id,
  message: id,
  createdAt: "2026-09-20T12:00:00.000Z",
  sender: { _id: "u2", name: "Ada" },
  receiver: { _id: "me", name: "Me" },
});

/** A socket whose events a test can fire, the way the server would. */
function fakeSocket() {
  const handlers: { [event: string]: Function[] } = {};
  return {
    connected: true,
    on: (event: string, handler: Function) => {
      (handlers[event] = handlers[event] || []).push(handler);
    },
    off: (event: string, handler: Function) => {
      handlers[event] = (handlers[event] || []).filter((h) => h !== handler);
    },
    emit: jest.fn(),
    fire: (event: string, payload: any) => {
      act(() => {
        (handlers[event] || []).slice().forEach((h) => h(payload));
      });
    },
  };
}

/** Every IntersectionObserver the component makes, so a test can trip one. */
let observerCallbacks: Array<(entries: any[]) => void> = [];

function installIntersectionObserver() {
  observerCallbacks = [];
  (window as any).IntersectionObserver = class {
    constructor(cb: (entries: any[]) => void) {
      observerCallbacks.push(cb);
    }
    observe() {}
    unobserve() {}
    disconnect() {}
  };
}

function scrollTheSentinelIntoView() {
  // The live observer is the last one made; the component disconnects the
  // others on cleanup.
  act(() => {
    const cb = observerCallbacks[observerCallbacks.length - 1];
    if (cb) cb([{ isIntersecting: true }]);
  });
}

function renderChat() {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: { user: { _id: "me", name: "Me" }, token: "t" } }) => state,
    },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/chat/u2"]}>
        <ChatContent selectedUser="u2" userName="Ada" profilePicture="/ada.png" />
      </MemoryRouter>
    </Provider>
  );
}

const renderedIds = (): string[] =>
  Array.from(document.querySelectorAll("[data-msg-id]")).map(
    (el) => el.getAttribute("data-msg-id") as string
  );

const pagesAskedFor = (): number[] => mockGetConversation.mock.calls.map((c) => c[0].page);

beforeEach(() => {
  // jsdom has no layout and no scrollIntoView.
  (Element.prototype as any).scrollIntoView = jest.fn();
  installIntersectionObserver();
  mockUseSocket.mockReturnValue({ socket: null, isConnected: false, emit: jest.fn() });
  // CRA resets implementations between tests, and the component dispatches
  // whatever these hand back.
  mockUpdateQueryData.mockImplementation(() => ({ type: "chatApi/updateQueryData" }));
  mockInvalidateTags.mockImplementation((tags: any) => ({
    type: "chatApi/invalidateTags",
    payload: tags,
  }));
  answerWith();
});

afterEach(() => {
  jest.clearAllMocks();
});

it("asks for the newest page first", () => {
  renderChat();

  expect(mockGetConversation).toHaveBeenCalledWith(
    expect.objectContaining({ senderId: "me", receiverId: "u2", page: 1, limit: 50 }),
    expect.anything()
  );
});

it("offers no way back when the whole thread is already loaded", () => {
  // Two messages held, two in the thread: there is nothing older.
  answerWith({ totalPages: 1, total: 2 });
  renderChat();

  expect(screen.queryByTestId("load-earlier")).not.toBeInTheDocument();
});

it("asks for page 2 when the top sentinel scrolls into view, and stops there", async () => {
  renderChat();

  scrollTheSentinelIntoView();
  scrollTheSentinelIntoView();

  await waitFor(() => expect(pagesAskedFor()).toContain(2));
  expect(pagesAskedFor().some((p) => p > 2)).toBe(false);
});

it("asks for page 2 from the button too, for keyboards and browsers without an observer", async () => {
  renderChat();

  fireEvent.click(screen.getByTestId("load-earlier"));

  await waitFor(() => expect(pagesAskedFor()).toContain(2));
});

it("says earlier messages are on their way while the page is in flight", async () => {
  // Six messages in the thread, so there is still history left after page 2 —
  // the way back must stay on screen while the request is out.
  answerWith({ fetchingOlder: true, total: 6 });
  renderChat();

  fireEvent.click(screen.getByTestId("load-earlier"));

  await waitFor(() => expect(screen.getByTestId("loading-earlier")).toBeInTheDocument());
  // The way back never leaves the screen — it is just not clickable twice.
  expect(screen.getByTestId("load-earlier")).toBeDisabled();
});

it("puts the older page ABOVE what was already on screen", async () => {
  renderChat();
  expect(renderedIds()).toEqual(["newer-a", "newer-b"]);

  fireEvent.click(screen.getByTestId("load-earlier"));

  await waitFor(() =>
    expect(renderedIds()).toEqual(["older-a", "older-b", "newer-a", "newer-b"])
  );
});

it("keeps the reader where they were when the older page lands", async () => {
  renderChat();

  // jsdom has no layout. The anchor — the first message on screen — sits at
  // 100px until the older page is actually in the DOM, and at 1,600px after,
  // i.e. 1,500px of history was inserted above it.
  (Element.prototype as any).getBoundingClientRect = function () {
    const id = this.getAttribute && this.getAttribute("data-msg-id");
    const prepended = document.querySelectorAll("[data-msg-id]").length > 2;
    const top = id === "newer-a" ? (prepended ? 1600 : 100) : 0;
    return { top, bottom: top, left: 0, right: 0, width: 0, height: 0, x: 0, y: top };
  };

  const container = document.querySelector(".modern-chat-messages") as HTMLElement;
  Object.defineProperty(container, "scrollHeight", { configurable: true, value: 2500 });
  Object.defineProperty(container, "clientHeight", { configurable: true, value: 400 });
  let scrollTop = 40;
  Object.defineProperty(container, "scrollTop", {
    configurable: true,
    get: () => scrollTop,
    set: (v: number) => {
      scrollTop = v;
    },
  });

  fireEvent.click(screen.getByTestId("load-earlier"));

  await waitFor(() => expect(scrollTop).toBe(1540));
});

it("does not spend the scroll restore on a message that arrives at the bottom", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: socket.emit });
  renderChat();

  // The anchor never moves: everything that changes happens below it.
  (Element.prototype as any).getBoundingClientRect = function () {
    const id = this.getAttribute && this.getAttribute("data-msg-id");
    const top = id === "newer-a" ? 100 : 0;
    return { top, bottom: top, left: 0, right: 0, width: 0, height: 0, x: 0, y: top };
  };
  const container = document.querySelector(".modern-chat-messages") as HTMLElement;
  Object.defineProperty(container, "scrollHeight", { configurable: true, value: 2500 });
  Object.defineProperty(container, "clientHeight", { configurable: true, value: 400 });
  let scrollTop = 40;
  Object.defineProperty(container, "scrollTop", {
    configurable: true,
    get: () => scrollTop,
    set: (v: number) => {
      scrollTop = v;
    },
  });

  fireEvent.click(screen.getByTestId("load-earlier"));
  socket.fire("newMessage", {
    message: liveMessage("live-1"),
    unreadCount: 1,
    senderId: "u2",
  });

  await waitFor(() => expect(renderedIds()).toContain("live-1"));
  // A message appended at the bottom is not a prepend: the scroller stays put.
  expect(scrollTop).toBe(40);
});

// --- Live messages and ticks ------------------------------------------------

it("keeps socket and optimistic messages when a page of history lands", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: socket.emit });
  renderChat();

  socket.fire("newMessage", {
    message: liveMessage("live-1"),
    unreadCount: 1,
    senderId: "u2",
  });
  await waitFor(() => expect(renderedIds()).toContain("live-1"));

  fireEvent.click(screen.getByTestId("load-earlier"));

  // The cache knows nothing of `live-1`; seeding from it must not drop it.
  await waitFor(() =>
    expect(renderedIds()).toEqual(["older-a", "older-b", "newer-a", "newer-b", "live-1"])
  );
});

it("raises one tick to two when the socket says the message was delivered", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: socket.emit });
  answerWith({ own: true });
  renderChat();

  // Straight from the cache, an own message the server holds is ONE tick.
  await waitFor(() => expect(screen.getAllByTestId("msg-status-sent").length).toBe(2));

  socket.fire("messageDelivered", { messageId: "newer-a" });

  await waitFor(() => expect(screen.getByTestId("msg-status-delivered")).toBeInTheDocument());
});

it("never pulls a read receipt back to delivered", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: socket.emit });
  answerWith({ own: true });
  renderChat();

  socket.fire("messagesRead", { readBy: "u2" });
  await waitFor(() => expect(screen.getAllByTestId("msg-status-read").length).toBe(2));

  socket.fire("messageDelivered", { messageId: "newer-a" });

  expect(screen.getAllByTestId("msg-status-read").length).toBe(2);
  expect(screen.queryByTestId("msg-status-delivered")).not.toBeInTheDocument();
});


// --- Opening the thread, and the sentinel that starts on screen -------------

it("opens at the newest message instead of the top of the history", () => {
  // jsdom has no layout: the scroller is 2,500px of content in a 400px window.
  const proto = Element.prototype as any;
  const originalScrollHeight = Object.getOwnPropertyDescriptor(proto, "scrollHeight");
  const originalClientHeight = Object.getOwnPropertyDescriptor(proto, "clientHeight");
  const originalScrollTop = Object.getOwnPropertyDescriptor(proto, "scrollTop");
  let top = 0;
  Object.defineProperty(proto, "scrollHeight", { configurable: true, get: () => 2500 });
  Object.defineProperty(proto, "clientHeight", { configurable: true, get: () => 400 });
  Object.defineProperty(proto, "scrollTop", {
    configurable: true,
    get: () => top,
    set: (v: number) => {
      top = v;
    },
  });

  try {
    renderChat();
    // The first page renders oldest-first, so landing at 0 would put the
    // reader on the oldest message with the sentinel already in view.
    expect(top).toBe(2500);
  } finally {
    if (originalScrollHeight) Object.defineProperty(proto, "scrollHeight", originalScrollHeight);
    if (originalClientHeight) Object.defineProperty(proto, "clientHeight", originalClientHeight);
    if (originalScrollTop) Object.defineProperty(proto, "scrollTop", originalScrollTop);
  }
});

it("re-arms the sentinel when the first fetch settles", async () => {
  // The sentinel comes into view while page 1 is still in flight. The
  // observer will not fire again by itself — the sentinel never leaves the
  // viewport — so the request has to be re-made when the fetch settles.
  let inFlight = true;
  const newest = {
    data: response(PAGE_1, 2, 4),
    error: undefined,
    isLoading: false,
    isFetching: true,
  };
  const settled = { ...newest, isFetching: false };
  const merged = {
    data: response(PAGE_2.concat(PAGE_1), 2, 4),
    error: undefined,
    isLoading: false,
    isFetching: false,
  };
  mockGetConversation.mockImplementation((arg: any) =>
    arg.page >= 2 ? merged : inFlight ? newest : settled
  );

  const view = renderChat();
  scrollTheSentinelIntoView();

  // Nothing while the first page is still loading.
  expect(pagesAskedFor().some((p) => p === 2)).toBe(false);

  inFlight = false;
  view.rerender(
    <Provider
      store={configureStore({
        reducer: {
          auth: (state: any = { userInfo: { user: { _id: "me", name: "Me" }, token: "t" } }) =>
            state,
        },
      })}
    >
      <MemoryRouter initialEntries={["/chat/u2"]}>
        <ChatContent selectedUser="u2" userName="Ada" profilePicture="/ada.png" />
      </MemoryRouter>
    </Provider>
  );

  await waitFor(() => expect(pagesAskedFor()).toContain(2));
  // Exactly one page further: the re-arm asks once, not in a loop.
  expect(pagesAskedFor().some((p) => p > 2)).toBe(false);
});

it("knows how many pages there are when the response says `pages`", async () => {
  // The conversation route answers `pagination.totalPages`; other handlers
  // answer a bare `pages`. Reading only the first capped paging at page 1.
  // Stable objects: a fresh one per call would restart the seeding effect on
  // every render.
  const newest = {
    data: { success: true, count: 2, total: 4, pages: 2, data: PAGE_1 },
    error: undefined,
    isLoading: false,
    isFetching: false,
  };
  const merged = {
    data: { success: true, count: 4, total: 4, pages: 2, data: PAGE_2.concat(PAGE_1) },
    error: undefined,
    isLoading: false,
    isFetching: false,
  };
  mockGetConversation.mockImplementation((arg: any) => (arg.page >= 2 ? merged : newest));

  renderChat();
  fireEvent.click(screen.getByTestId("load-earlier"));

  await waitFor(() => expect(pagesAskedFor()).toContain(2));
});

// --- The header (H1 review follow-up) --------------------------------------
it("announces one profile link, not the same one twice", () => {
  renderChat();

  const avatarLink = screen.getByTestId("chat-header-avatar-link");
  expect(avatarLink).toHaveAttribute("aria-hidden", "true");
  expect(avatarLink).toHaveAttribute("tabindex", "-1");
  expect(avatarLink).not.toHaveAttribute("aria-label");
  expect(screen.getByTestId("chat-header-profile-link")).toHaveAttribute("aria-label");
});

// --- Coming back to a thread ------------------------------------------------
//
// Reported from production: the list row showed the newest message ("how are
// u", 18:18) while the thread itself stopped at the one before it. Visiting
// another room and coming back was enough to reproduce.
//
// Two things put it there, and both are fixed below.
//
// First, a message delivered by the socket lived ONLY in this component's
// state. Nothing wrote it into the `getConversation` cache entry — and that
// entry is what the seeding effect rebuilds state from, wholesale, whenever
// the conversation changes (`if (!sameConversation) return merged`). So a
// message that arrived while the thread was open was dropped the moment the
// reader switched rooms and came back.
//
// Second, the entry is keyed on the pair alone and outlives the component, and
// its `forceRefetch` only fires when `page` changes. Re-entering a thread with
// `page` back at 1 is a plain cache hit, so nothing that arrived while the
// thread was CLOSED (no socket handler mounted to catch it) was ever fetched
// either.

it("asks the server again when a thread is re-entered", () => {
  renderChat();

  expect(mockGetConversation).toHaveBeenCalledWith(
    expect.anything(),
    expect.objectContaining({ refetchOnMountOrArgChange: true })
  );
});

it("writes a live incoming message into the thread cache, not just the screen", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  socket.fire("newMessage", {
    message: liveMessage("live-1"),
    unreadCount: 1,
    senderId: "u2",
  });

  await waitFor(() => expect(renderedIds()).toContain("live-1"));
  expect(mockUpdateQueryData).toHaveBeenCalledWith(
    "getConversation",
    expect.objectContaining({ senderId: "me", receiverId: "u2" }),
    expect.any(Function)
  );
});

it("writes a message we sent into it too", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  socket.fire("messageSent", {
    message: { ...liveMessage("sent-1"), sender: { _id: "me", name: "Me" }, receiver: { _id: "u2" } },
    receiverId: "u2",
  });

  await waitFor(() => expect(renderedIds()).toContain("sent-1"));
  expect(mockUpdateQueryData).toHaveBeenCalledWith(
    "getConversation",
    expect.objectContaining({ senderId: "me", receiverId: "u2" }),
    expect.any(Function)
  );
});

// --- A deleted message must not come back ----------------------------------
//
// The mirror of the bug above. `merge` on the getConversation entry only ever
// ADDS incoming messages and UPDATES ones it already holds — it has no branch
// that removes. So invalidating the tag after a delete refetches the thread
// and merges it, and the deleted message survives in the cache untouched.
//
// Both delete paths only filtered local state, and local state is rebuilt from
// that cache wholesale on a conversation switch. Delete a message, step into
// another room, come back, and it was there again.

it("takes a deleted message out of the thread cache, not just the screen", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  expect(renderedIds()).toContain("newer-a");

  socket.fire("messageDeleted", { messageId: "newer-a" });

  await waitFor(() => expect(renderedIds()).not.toContain("newer-a"));

  expect(mockUpdateQueryData).toHaveBeenCalledWith(
    "getConversation",
    expect.objectContaining({ senderId: "me", receiverId: "u2" }),
    expect.any(Function)
  );

  // The recipe has to actually drop it, not merely be handed over.
  const recipe = mockUpdateQueryData.mock.calls
    .map((c: any[]) => c[2])
    .pop() as (draft: any) => void;
  const draft = { data: [{ _id: "newer-a" }, { _id: "newer-b" }], count: 2 };
  recipe(draft);
  expect(draft.data.map((m: any) => m._id)).toEqual(["newer-b"]);
  expect(draft.count).toBe(1);
});

// --- Edits and reactions have to reach the cache too -----------------------
//
// Same family as the two above. An edit or a reaction we make ourselves goes
// through a mutation that invalidates the Conversation tag, so the refetch
// carries it and `merge` updates the message in place. One that ARRIVES over
// the socket only touched local state — and local state is rebuilt from the
// cache on a conversation switch, so the old text came back until a refetch
// happened to land.

it("writes an edited message into the thread cache", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  socket.fire("messageEdited", {
    messageId: "newer-a",
    message: { _id: "newer-a", message: "edited text" },
    editedAt: "2026-09-30T10:00:00.000Z",
  });

  await waitFor(() => expect(mockUpdateQueryData).toHaveBeenCalled());
  const recipe = mockUpdateQueryData.mock.calls
    .map((c: any[]) => c[2])
    .pop() as (draft: any) => void;
  const draft = { data: [{ _id: "newer-a", message: "old text" }], count: 1 };
  recipe(draft);
  expect(draft.data[0].message).toBe("edited text");
  expect(draft.data[0].isEdited).toBe(true);
});

it("writes a reaction into the thread cache", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  socket.fire("messageReaction", {
    messageId: "newer-b",
    reactions: [{ user: "u2", emoji: "🎉" }],
  });

  await waitFor(() => expect(mockUpdateQueryData).toHaveBeenCalled());
  const recipe = mockUpdateQueryData.mock.calls
    .map((c: any[]) => c[2])
    .pop() as (draft: any) => void;
  const draft = { data: [{ _id: "newer-b", reactions: [] }], count: 1 };
  recipe(draft);
  expect(draft.data[0].reactions).toEqual([{ user: "u2", emoji: "🎉" }]);
});

// --- The way back down -----------------------------------------------------
//
// The thread had a way UP through its history and no way back. Once a reader
// scrolled off the newest message the only route down was dragging through
// everything they had just loaded, and nothing told them a message had landed
// while they were reading.
//
// `isAtBottomRef` already knew the answer but it is a ref, so no UI could
// render off it.

/** A scroller jsdom can drive: it has no layout, so every metric is faked. */
function installScroller({ scrollHeight = 2000, clientHeight = 400, top = 1600 } = {}) {
  const container = document.querySelector(".modern-chat-messages") as HTMLElement;
  let scrollTop = top;
  Object.defineProperty(container, "scrollHeight", { configurable: true, get: () => scrollHeight });
  Object.defineProperty(container, "clientHeight", { configurable: true, get: () => clientHeight });
  Object.defineProperty(container, "scrollTop", {
    configurable: true,
    get: () => scrollTop,
    set: (v: number) => { scrollTop = v; },
  });
  (container as any).scrollTo = (opts: any) => {
    scrollTop = typeof opts === "number" ? opts : opts.top;
  };
  return {
    container,
    /** Move the reader and tell the component, the way a real scroll does. */
    moveTo(v: number) {
      scrollTop = v;
      fireEvent.scroll(container);
    },
    get position() { return scrollTop; },
    get scrollHeight() { return scrollHeight; },
  };
}

const wayDown = () => screen.queryByTestId("scroll-to-bottom");

it("offers no way down while the newest message is already on screen", () => {
  mockUseSocket.mockReturnValue({ socket: fakeSocket(), isConnected: true, emit: jest.fn() });
  renderChat();
  const scroller = installScroller();

  scroller.moveTo(1600); // bottom: 2000 - 1600 - 400 = 0

  expect(wayDown()).not.toBeInTheDocument();
});

it("offers a way down once the reader goes up into the history", () => {
  mockUseSocket.mockReturnValue({ socket: fakeSocket(), isConnected: true, emit: jest.fn() });
  renderChat();
  const scroller = installScroller();

  scroller.moveTo(200);

  expect(wayDown()).toBeInTheDocument();
  expect(wayDown()).toHaveAttribute("aria-label");
});

it("the way down returns to the newest message", () => {
  mockUseSocket.mockReturnValue({ socket: fakeSocket(), isConnected: true, emit: jest.fn() });
  renderChat();
  const scroller = installScroller();
  scroller.moveTo(200);

  fireEvent.click(wayDown()!);

  expect(scroller.position).toBe(scroller.scrollHeight);
});

it("counts what arrived while the reader was up in the history", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  const scroller = installScroller();
  scroller.moveTo(200);

  socket.fire("newMessage", {
    message: liveMessage("live-1"),
    unreadCount: 1,
    senderId: "u2",
  });

  await waitFor(() =>
    expect(screen.getByTestId("scroll-to-bottom-count")).toHaveTextContent("1")
  );
});

it("stops counting once the reader is back at the newest message", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  const scroller = installScroller();
  scroller.moveTo(200);

  socket.fire("newMessage", {
    message: liveMessage("live-1"),
    unreadCount: 1,
    senderId: "u2",
  });
  await waitFor(() => expect(screen.getByTestId("scroll-to-bottom-count")).toBeInTheDocument());

  fireEvent.click(wayDown()!);

  expect(screen.queryByTestId("scroll-to-bottom-count")).not.toBeInTheDocument();
});

it("counts nothing for a message that lands while the reader is at the bottom", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  const scroller = installScroller();
  scroller.moveTo(1600);

  socket.fire("newMessage", {
    message: liveMessage("live-1"),
    unreadCount: 1,
    senderId: "u2",
  });

  await waitFor(() => expect(renderedIds()).toContain("live-1"));
  expect(screen.queryByTestId("scroll-to-bottom-count")).not.toBeInTheDocument();
});

// --- The tick state a reload used to lose --------------------------------
//
// Message has a `delivered` field whose own comment says it "powers sent ->
// delivered -> read tick states on the client", the send path sets it once the
// receiver's socket has the message, and GET /messages/conversation returns it
// (`.select('-__v')` drops only the version key).
//
// The seeding effect ignored it: `msg.status || (msg.read ? "read" : "sent")`.
// So "delivered" existed ONLY as a live socket event. Reload the thread and
// every delivered-but-unread message fell back from two ticks to one, which is
// what the mobile app gets right and the web did not.

it("reads delivered off the server, so a reload keeps two ticks", async () => {
  mockUseSocket.mockReturnValue({ socket: fakeSocket(), isConnected: true, emit: jest.fn() });
  answerWith({
    own: true,
    page1: [
      { ...msg("newer-a", "2026-09-20T10:00:00.000Z", true), delivered: true, read: false },
      { ...msg("newer-b", "2026-09-20T10:05:00.000Z", true), delivered: false, read: false },
    ],
  });
  renderChat();

  await waitFor(() =>
    expect(screen.getByTestId("msg-status-delivered")).toBeInTheDocument()
  );
  // The one the receiver's client never picked up stays on a single tick.
  expect(screen.getAllByTestId("msg-status-sent")).toHaveLength(1);
});

it("still prefers read over delivered", async () => {
  mockUseSocket.mockReturnValue({ socket: fakeSocket(), isConnected: true, emit: jest.fn() });
  answerWith({
    own: true,
    page1: [{ ...msg("newer-a", "2026-09-20T10:00:00.000Z", true), delivered: true, read: true }],
  });
  renderChat();

  await waitFor(() => expect(screen.getByTestId("msg-status-read")).toBeInTheDocument());
  expect(screen.queryByTestId("msg-status-delivered")).not.toBeInTheDocument();
});

// --- Bare-id senders (chat#8) ------------------------------------------------
//
// The wave mirror and story_share emits carried an UNPOPULATED sender: a bare
// id string. `msg.sender._id` was undefined, so a wave the web user sent
// showed as RECEIVED, with a broken avatar, until a reload.

it("puts a wave I sent, with a bare-id sender, on my side", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  socket.fire("messageSent", {
    message: {
      _id: "wave-1",
      message: "\u{1F44B}",
      messageType: "sticker",
      createdAt: "2026-09-20T12:00:00.000Z",
      sender: "me",
      receiver: "u2",
    },
    receiverId: "u2",
  });

  await waitFor(() => expect(renderedIds()).toContain("wave-1"));
  const bubble = document.querySelector('[data-msg-id="wave-1"]') as HTMLElement;
  expect(bubble).toHaveClass("sent");
  expect(bubble.querySelector('[data-testid="wave-card"]')).not.toBeNull();
});

it("puts their wave, with a bare-id sender, on their side", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();

  socket.fire("newMessage", {
    message: {
      _id: "wave-2",
      message: "\u{1F44B}",
      messageType: "sticker",
      createdAt: "2026-09-20T12:00:00.000Z",
      sender: "u2",
      receiver: "me",
    },
    unreadCount: 1,
  });

  await waitFor(() => expect(renderedIds()).toContain("wave-2"));
  expect(document.querySelector('[data-msg-id="wave-2"]')).toHaveClass("received");
});

// --- messagePinned (chat#14) -------------------------------------------------
//
// The backend emits messagePinned to the other participant; the web never
// listened (a comment even said the server does not emit it), so a pin made
// in the app only appeared on web after a reload.

it("shows a pin the other person made, live", async () => {
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  await waitFor(() => expect(renderedIds()).toContain("newer-b"));
  expect(screen.queryByTestId("pinned-bar")).toBeNull();

  socket.fire("messagePinned", { messageId: "newer-b", pinned: true, pinnedBy: "u2" });

  expect(await screen.findByTestId("pinned-bar")).toHaveTextContent("newer-b");
  expect(mockUpdateQueryData).toHaveBeenCalledWith(
    "getConversation",
    expect.objectContaining({ senderId: "me", receiverId: "u2" }),
    expect.any(Function)
  );
});

it("unpins the old message when a new one is pinned, as the server does", async () => {
  answerWith({
    page1: [
      { ...PAGE_1[0], pinned: true },
      PAGE_1[1],
    ],
  });
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  expect(await screen.findByTestId("pinned-bar")).toHaveTextContent("newer-a");

  socket.fire("messagePinned", { messageId: "newer-b", pinned: true, pinnedBy: "u2" });

  await waitFor(() => expect(screen.getByTestId("pinned-bar")).toHaveTextContent("newer-b"));
  expect(screen.getByTestId("pinned-bar")).not.toHaveTextContent("newer-a");
});

it("ignores a pin from a conversation that is not open", async () => {
  answerWith({ page1: [{ ...PAGE_1[0], pinned: true }, PAGE_1[1]] });
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  expect(await screen.findByTestId("pinned-bar")).toHaveTextContent("newer-a");

  socket.fire("messagePinned", { messageId: "elsewhere", pinned: true, pinnedBy: "u7" });

  expect(screen.getByTestId("pinned-bar")).toHaveTextContent("newer-a");
});

it("clears the bar when the pin is removed", async () => {
  answerWith({ page1: [{ ...PAGE_1[0], pinned: true }, PAGE_1[1]] });
  const socket = fakeSocket();
  mockUseSocket.mockReturnValue({ socket, isConnected: true, emit: jest.fn() });
  renderChat();
  expect(await screen.findByTestId("pinned-bar")).toBeInTheDocument();

  socket.fire("messagePinned", { messageId: "newer-a", pinned: false, pinnedBy: "u2" });

  await waitFor(() => expect(screen.queryByTestId("pinned-bar")).toBeNull());
});

// --- Message search (chat#17) ------------------------------------------------

it("jumps to a search result that is on screen and flashes it", async () => {
  renderChat();
  await waitFor(() => expect(renderedIds()).toContain("newer-b"));
  fireEvent.click(screen.getByTestId("chat-header-search"));
  fireEvent.click(screen.getByTestId("search-jump-loaded"));

  const bubble = document.querySelector('[data-msg-id="newer-b"]') as HTMLElement;
  expect((Element.prototype as any).scrollIntoView).toHaveBeenCalled();
  expect(bubble).toHaveClass("modern-message--highlight");
  expect(screen.queryByTestId("chat-search-dialog")).toBeNull();
});

it("explains a result that is further back than what is loaded", async () => {
  renderChat();
  fireEvent.click(screen.getByTestId("chat-header-search"));
  fireEvent.click(screen.getByTestId("search-jump-missing"));
  expect(mockNotifyInfo).toHaveBeenCalledWith("That message is further back. Scroll up to load it.");
});
