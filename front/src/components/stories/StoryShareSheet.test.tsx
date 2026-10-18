import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import StoryShareSheet from "./StoryShareSheet";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mockShareStory = jest.fn();
let mockConversationsState: any = { data: undefined, isLoading: true, error: undefined };

jest.mock("../../store/slices/storiesSlice", () => ({
  useShareStoryMutation: () => [mockShareStory, { isLoading: false }],
}));
jest.mock("../../store/slices/chatSlice", () => ({
  useGetConversationsQuery: () => mockConversationsState,
}));
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn() },
}));
const notify = require("../../design/notify").default;

const unwrappable = (value: any) => ({ unwrap: () => Promise.resolve(value) });
const rejecting = () => ({ unwrap: () => Promise.reject(new Error("nope")) });

const CONVERSATIONS = {
  success: true,
  data: [
    {
      _id: "c-1",
      participants: [
        { _id: "me", name: "Me" },
        { _id: "u-1", name: "Mina", imageUrls: ["https://cdn/m.jpg"] },
      ],
    },
    {
      _id: "c-2",
      participants: [
        { _id: "me", name: "Me" },
        { _id: "u-2", name: "Tom", images: ["https://cdn/t.jpg"] },
      ],
    },
  ],
};

const renderSheet = (props: any = {}) => {
  const onClose = props.onClose || jest.fn();
  render(
    <StoryShareSheet
      storyId={props.storyId || "story-1"}
      currentUserId={props.currentUserId === undefined ? "me" : props.currentUserId}
      onClose={onClose}
    />
  );
  return onClose;
};

beforeEach(() => {
  jest.clearAllMocks();
  mockShareStory.mockReturnValue(unwrappable({ success: true }));
  mockConversationsState = { data: undefined, isLoading: true, error: undefined };
});

describe("StoryShareSheet", () => {
  it("shows a loading state while recent conversations load", () => {
    renderSheet();
    expect(screen.getByTestId("story-share-loading")).toBeInTheDocument();
  });

  it("lists the other participant of each recent conversation", () => {
    mockConversationsState = { data: CONVERSATIONS, isLoading: false, error: undefined };
    renderSheet();

    expect(screen.getAllByTestId("story-share-row")).toHaveLength(2);
    expect(screen.getByText("Mina")).toBeInTheDocument();
    expect(screen.getByText("Tom")).toBeInTheDocument();
    // Never the signed-in user themselves.
    expect(screen.queryByText("Me")).not.toBeInTheDocument();
  });

  it("sends to a DM with { id, sharedTo: 'dm', receiverId } and toasts", async () => {
    mockConversationsState = { data: CONVERSATIONS, isLoading: false, error: undefined };
    renderSheet();

    fireEvent.click(screen.getAllByTestId("story-share-row")[0]);

    await waitFor(() =>
      expect(mockShareStory).toHaveBeenCalledWith({
        id: "story-1",
        sharedTo: "dm",
        receiverId: "u-1",
      })
    );
    await waitFor(() => expect(notify.success).toHaveBeenCalled());
  });

  it("marks a recipient as sent and will not send to them twice", async () => {
    mockConversationsState = { data: CONVERSATIONS, isLoading: false, error: undefined };
    renderSheet();

    const row = screen.getAllByTestId("story-share-row")[0];
    fireEvent.click(row);
    await waitFor(() =>
      expect(screen.getByTestId("story-share-sent-u-1")).toBeInTheDocument()
    );

    fireEvent.click(row);
    expect(mockShareStory).toHaveBeenCalledTimes(1);
  });

  it("toasts an error and leaves the row sendable when the share fails", async () => {
    mockConversationsState = { data: CONVERSATIONS, isLoading: false, error: undefined };
    mockShareStory.mockReturnValue(rejecting());
    renderSheet();

    fireEvent.click(screen.getAllByTestId("story-share-row")[0]);

    await waitFor(() => expect(notify.error).toHaveBeenCalled());
    expect(screen.queryByTestId("story-share-sent-u-1")).not.toBeInTheDocument();
  });

  it("filters the list by name", () => {
    mockConversationsState = { data: CONVERSATIONS, isLoading: false, error: undefined };
    renderSheet();

    fireEvent.change(screen.getByTestId("story-share-search"), {
      target: { value: "to" },
    });
    expect(screen.getAllByTestId("story-share-row")).toHaveLength(1);
    expect(screen.getByText("Tom")).toBeInTheDocument();
  });

  it("shows an empty state when there are no recent chats", () => {
    mockConversationsState = {
      data: { success: true, data: [] },
      isLoading: false,
      error: undefined,
    };
    renderSheet();
    expect(screen.getByTestId("story-share-empty")).toBeInTheDocument();
  });

  it("closes from its own close button", () => {
    mockConversationsState = {
      data: { success: true, data: [] },
      isLoading: false,
      error: undefined,
    };
    const onClose = renderSheet();
    fireEvent.click(screen.getByTestId("story-share-close"));
    expect(onClose).toHaveBeenCalled();
  });
});
