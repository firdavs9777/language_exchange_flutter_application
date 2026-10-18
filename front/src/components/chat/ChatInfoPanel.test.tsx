import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import ChatInfoPanel from "./ChatInfoPanel";
import { CONVERSATIONS_PAGE } from "./lib/conversationMatch";

// CRA resets mocks between tests, so every factory is module-scoped and
// `mock`-prefixed (the only names a jest.mock factory may close over) and the
// implementations are handed out in beforeEach.
const mockNavigate = jest.fn();
const mockConversations = jest.fn();
const mockBlockStatus = jest.fn();
const mockMute = jest.fn();
const mockArchive = jest.fn();
const mockUnarchive = jest.fn();
const mockUnmute = jest.fn();
const mockDelete = jest.fn();
const mockBlock = jest.fn();
const mockUnblock = jest.fn();
const mockReport = jest.fn();
const mockUserById = jest.fn();
const mockTheme = jest.fn();
const mockSetTheme = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("./components/BookmarksDialog", () => ({
  __esModule: true,
  default: () => require("react").createElement("div", { "data-testid": "bookmarks-dialog" }),
}));

jest.mock("../../store/slices/chatSlice", () => ({
  useGetConversationsQuery: (arg: any, opts: any) => mockConversations(arg, opts),
  useGetConversationThemeQuery: (arg: any, opts: any) => mockTheme(arg, opts),
  useSetConversationThemeMutation: () => [mockSetTheme, { isLoading: false }],
  useMuteConversationMutation: () => [mockMute, { isLoading: false }],
  useUnmuteConversationMutation: () => [mockUnmute, { isLoading: false }],
  useArchiveConversationMutation: () => [mockArchive, { isLoading: false }],
  useUnarchiveConversationMutation: () => [mockUnarchive, { isLoading: false }],
  useDeleteConversationMutation: () => [mockDelete, { isLoading: false }],
}));

jest.mock("../../store/slices/usersSlice", () => ({
  useGetBlockStatusQuery: (arg: any, opts: any) => mockBlockStatus(arg, opts),
  useGetUserByIdQuery: (arg: any, opts: any) => mockUserById(arg, opts),
  useBlockUserMutation: () => [mockBlock, { isLoading: false }],
  useUnblockUserMutation: () => [mockUnblock, { isLoading: false }],
  useReportUserMutation: () => [mockReport, { isLoading: false }],
}));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const rejected = () => ({ unwrap: () => Promise.reject({ data: { message: "nope" } }) });
const rejectedWith = (message: string) => ({
  unwrap: () => Promise.reject({ data: { message } }),
});

const onClose = jest.fn();

function renderPanel(props: any = {}) {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: { user: { _id: "me" }, token: "t" } }) => state,
    },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <ChatInfoPanel
          userId="u2"
          userName="Ada"
          profilePicture=""
          onClose={onClose}
          {...props}
        />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockConversations.mockReturnValue({
    data: {
      data: [
        { _id: "c1", participants: [{ _id: "me" }, { _id: "u2" }], isMuted: false },
        { _id: "c9", participants: [{ _id: "me" }, { _id: "u7" }], isMuted: true },
      ],
    },
    isLoading: false,
  });
  mockTheme.mockReturnValue({ data: { data: { preset: "navy" } } });
  mockSetTheme.mockReturnValue(resolved());
  mockBlockStatus.mockReturnValue({ data: { data: { isBlocked: false } } });
  mockUserById.mockReturnValue({
    data: { data: { native_language: "Korean", language_to_learn: "English", languageLevel: "B1" } },
  });
  mockMute.mockReturnValue(resolved());
  mockArchive.mockReturnValue(resolved());
  mockUnarchive.mockReturnValue(resolved());
  mockUnmute.mockReturnValue(resolved());
  mockDelete.mockReturnValue(resolved());
  mockBlock.mockReturnValue(resolved());
  mockUnblock.mockReturnValue(resolved());
  mockReport.mockReturnValue(resolved());
});

afterEach(() => {
  jest.clearAllMocks();
});

describe("the entries the panel offers", () => {
  it("opens the saved messages", () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-bookmarks"));
    expect(screen.getByTestId("bookmarks-dialog")).toBeInTheDocument();
  });

  it("links the profile and the media gallery by the OTHER USER's id", () => {
    renderPanel();
    expect(screen.getByTestId("chat-info-panel")).toBeInTheDocument();
    expect(screen.getByTestId("chat-info-profile")).toHaveAttribute("href", "/community/u2");
    expect(screen.getByTestId("chat-info-media")).toHaveAttribute("href", "/chat/u2/media");
  });

  it("closes on the close button", () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-close"));
    expect(onClose).toHaveBeenCalled();
  });

  it("opens the wallpaper picker on the wallpaper the conversation wears", () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-wallpaper"));
    expect(screen.getByTestId("chat-wallpaper-dialog")).toBeInTheDocument();
    // The theme is read for THIS conversation, not for the other person.
    expect(mockTheme).toHaveBeenCalledWith("c1", { skip: false });
    expect(screen.getByTestId("wallpaper-navy")).toHaveAttribute(
      "aria-pressed",
      "true"
    );
  });

  it("cannot set a wallpaper before the conversation exists", () => {
    mockConversations.mockReturnValue({ data: { data: [] }, isLoading: false });
    renderPanel();
    expect(screen.getByTestId("chat-info-wallpaper")).toBeDisabled();
  });
});

describe("the conversation the actions act on", () => {
  it("asks with the same argument UsersList does, so they share one cache entry", () => {
    renderPanel();
    expect(mockConversations).toHaveBeenCalledWith(
      CONVERSATIONS_PAGE,
      undefined
    );
    // The backend clamps `limit` to 100 and offers no participant filter, so
    // anything smaller silently hides older conversations from the panel.
    expect(CONVERSATIONS_PAGE).toEqual({ page: 1, limit: 100 });
  });

  it("matches on the otherParticipant the backend computed", () => {
    mockConversations.mockReturnValue({
      data: {
        data: [
          {
            _id: "c1",
            otherParticipant: { _id: "u2" },
            participants: [{ _id: "me" }, { _id: "u2" }],
            isMuted: false,
          },
        ],
      },
      isLoading: false,
    });
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-mute"));
    fireEvent.click(screen.getByTestId("mute-option-always"));
    expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1" });
  });

  it("says nothing about a conversation it has not finished loading", () => {
    mockConversations.mockReturnValue({ data: undefined, isLoading: true });
    renderPanel();
    // Disabled, because there is no id to act on yet -- but NOT accused of
    // never having spoken.
    expect(screen.getByTestId("chat-info-mute")).toBeDisabled();
    expect(screen.getByTestId("chat-info-panel")).not.toHaveTextContent(
      "Say something first"
    );
  });

  it("says so once the list is loaded and the conversation is not in it", () => {
    mockConversations.mockReturnValue({ data: { data: [] }, isLoading: false });
    renderPanel();
    expect(screen.getByTestId("chat-info-panel")).toHaveTextContent(
      "Say something first"
    );
  });
});

describe("the viewer's own chat", () => {
  it("offers neither Block nor Report when the other person is the viewer", () => {
    renderPanel({ userId: "me" });
    expect(screen.queryByTestId("chat-info-block")).not.toBeInTheDocument();
    expect(screen.queryByTestId("chat-info-report")).not.toBeInTheDocument();
    // And it does not ask the backend for a block status it would 400 on.
    expect(mockBlockStatus).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ skip: true })
    );
  });
});

describe("the profile section", () => {
  it("shows the language pair the two of them are exchanging", () => {
    renderPanel();
    expect(screen.getByTestId("language-pill")).toBeInTheDocument();
    expect(screen.getByTestId("language-pill-native")).toHaveTextContent("KO");
    expect(screen.getByTestId("language-pill-learning")).toHaveTextContent("EN");
  });

  it("leaves the pill out when the languages are unknown", () => {
    mockUserById.mockReturnValue({ data: { data: { name: "Ada" } } });
    renderPanel();
    expect(screen.queryByTestId("language-pill")).not.toBeInTheDocument();
  });
});

describe("mute", () => {
  it("asks how long, then mutes the conversation this pair actually has", async () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-mute"));
    expect(mockMute).not.toHaveBeenCalled();
    fireEvent.click(screen.getByTestId("mute-option-1h"));
    expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1", duration: 3600000 });
    await waitFor(() => expect(screen.queryByTestId("mute-option-1h")).toBeNull());
  });

  it("mutes until unmuted when 'always' is chosen (no duration, like the app)", () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-mute"));
    fireEvent.click(screen.getByTestId("mute-option-always"));
    expect(mockMute).toHaveBeenCalledWith({ conversationId: "c1" });
  });

  it("unmutes when the conversation is already muted", async () => {
    mockConversations.mockReturnValue({
      data: {
        data: [{ _id: "c1", participants: [{ _id: "me" }, { _id: "u2" }], isMuted: true }],
      },
      isLoading: false,
    });
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-mute"));
    expect(mockUnmute).toHaveBeenCalledWith("c1");
    expect(mockMute).not.toHaveBeenCalled();
  });

  it("disables mute and delete until a conversation document exists", () => {
    mockConversations.mockReturnValue({ data: { data: [] }, isLoading: false });
    renderPanel();
    expect(screen.getByTestId("chat-info-mute")).toBeDisabled();
    expect(screen.getByTestId("chat-info-delete")).toBeDisabled();
  });
});

describe("block and unblock", () => {
  it("blocks behind a confirmation and leaves the conversation", async () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-block"));
    expect(mockBlock).not.toHaveBeenCalled();

    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    expect(mockBlock).toHaveBeenCalledWith("u2");
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/chat"));
  });

  it("offers Unblock while the live status says blocked", async () => {
    mockBlockStatus.mockReturnValue({ data: { data: { isBlocked: true } } });
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-block"));
    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    expect(mockUnblock).toHaveBeenCalledWith("u2");
    expect(mockBlock).not.toHaveBeenCalled();
    // Unblocking keeps you where you are -- there is a conversation to read.
    await waitFor(() => expect(mockUnblock).toHaveBeenCalledTimes(1));
    expect(mockNavigate).not.toHaveBeenCalled();
  });

  it("asks for the block status of this pair", () => {
    renderPanel();
    expect(mockBlockStatus).toHaveBeenCalledWith(
      { userId: "me", targetUserId: "u2" },
      expect.objectContaining({ skip: false })
    );
  });
});

describe("report", () => {
  it("sends the reason the picker collected in the body the backend accepts", async () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-report"));
    fireEvent.change(screen.getByTestId("chat-report-reason"), {
      target: { value: "harassment" },
    });
    fireEvent.change(screen.getByTestId("chat-report-description"), {
      target: { value: "kept messaging after I asked them to stop" },
    });
    fireEvent.submit(screen.getByTestId("chat-report-form"));
    expect(mockReport).toHaveBeenCalledWith({
      type: "user",
      reportedUser: "u2",
      reason: "harassment",
      description: "kept messaging after I asked them to stop",
    });
    await waitFor(() =>
      expect(screen.queryByTestId("chat-report-form")).not.toBeInTheDocument()
    );
  });

  it("only offers reasons the Report model's enum accepts", () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-report"));
    const values = Array.prototype.slice
      .call(screen.getByTestId("chat-report-reason").querySelectorAll("option"))
      .map((o: any) => o.value);
    expect(values).toEqual([
      "spam",
      "harassment",
      "hate_speech",
      "violence",
      "nudity",
      "false_information",
      "copyright",
      "other",
    ]);
  });

  it("keeps the form open and shows what the backend said when it is rejected", async () => {
    // The 400 everyone hits twice: controllers/report.js refuses a second
    // report of the same thing by the same person, and its message is the
    // only explanation the reader gets.
    mockReport.mockReturnValue(
      rejectedWith("You have already reported this content. Please wait for moderation.")
    );
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-report"));
    fireEvent.submit(screen.getByTestId("chat-report-form"));
    await waitFor(() =>
      expect(screen.getByTestId("chat-report-error")).toHaveTextContent(
        "You have already reported this content"
      )
    );
    expect(screen.getByTestId("chat-report-form")).toBeInTheDocument();
  });
});

describe("delete", () => {
  it("deletes behind a confirmation and returns to the list", async () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-delete"));
    expect(mockDelete).not.toHaveBeenCalled();

    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    expect(mockDelete).toHaveBeenCalledWith("c1");
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/chat"));
  });

  it("stays put when the delete fails", async () => {
    mockDelete.mockReturnValue(rejected());
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-delete"));
    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    await waitFor(() => expect(mockDelete).toHaveBeenCalled());
    expect(mockNavigate).not.toHaveBeenCalled();
  });
});

describe("archive", () => {
  it("archives the conversation", async () => {
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-archive"));
    expect(mockArchive).toHaveBeenCalledWith("c1");
  });

  it("unarchives one that is archived", () => {
    mockConversations.mockReturnValue({
      data: { data: [{ _id: "c1", participants: [{ _id: "me" }, { _id: "u2" }], isArchived: true }] },
      isLoading: false,
    });
    renderPanel();
    fireEvent.click(screen.getByTestId("chat-info-archive"));
    expect(mockUnarchive).toHaveBeenCalledWith("c1");
    expect(mockArchive).not.toHaveBeenCalled();
  });

  it("cannot archive before the conversation exists", () => {
    mockConversations.mockReturnValue({ data: { data: [] }, isLoading: false });
    renderPanel();
    expect(screen.getByTestId("chat-info-archive")).toBeDisabled();
  });
});
