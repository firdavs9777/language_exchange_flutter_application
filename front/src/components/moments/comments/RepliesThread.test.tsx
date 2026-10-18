import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import RepliesThread from "./RepliesThread";

const mockGetReplies = jest.fn();
const mockDeleteComment = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../../hooks/useTargetLanguage", () => ({
  useTargetLanguage: () => "en",
}));

const noop = () => [jest.fn(() => ({ unwrap: () => Promise.resolve({}) })), {}];

jest.mock("../../../store/slices/momentsSlice", () => ({
  useLikeCommentMutation: () => noop(),
  useReactToCommentMutation: () => noop(),
  useUnreactToCommentMutation: () => noop(),
  useTranslateCommentMutation: () => noop(),
  useDeleteMomentCommentMutation: () => [mockDeleteComment, {}],
  useAddMomentCommentMutation: () => [jest.fn(), { isLoading: false }],
  useUploadCommentImageMutation: () => [jest.fn(), { isLoading: false }],
  useGetCommentRepliesQuery: (args: any) => mockGetReplies(args),
}));

const reply = (id: string, name: string, extra: any = {}) => ({
  _id: id,
  text: `reply ${id}`,
  createdAt: new Date().toISOString(),
  user: { _id: `u-${id}`, name, imageUrls: [] },
  ...extra,
});

const renderThread = () =>
  render(
    <RepliesThread
      commentId="c-1"
      momentId="moment-1"
      myUserId="me-1"
      isLoggedIn
      onRequireLogin={jest.fn()}
    />
  );

beforeEach(() => {
  jest.clearAllMocks();
  mockDeleteComment.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
});

describe("RepliesThread", () => {
  it("appends the next page and keeps the replies already shown", () => {
    // RTK Query hands back a stable object until the data actually changes.
    const pageOne = {
      data: { data: [reply("r-1", "Ann")], total: 2, page: 1, pages: 2 },
      isFetching: false,
    };
    const pageTwo = {
      data: { data: [reply("r-2", "Ben")], total: 2, page: 2, pages: 2 },
      isFetching: false,
    };
    mockGetReplies.mockImplementation(({ page }: any) => (page === 1 ? pageOne : pageTwo));

    renderThread();

    expect(screen.getByText("Ann")).toBeInTheDocument();
    expect(screen.queryByText("Ben")).not.toBeInTheDocument();

    fireEvent.click(screen.getByTestId("replies-load-more"));

    expect(mockGetReplies).toHaveBeenCalledWith(
      expect.objectContaining({ commentId: "c-1", page: 2 })
    );
    expect(screen.getByText("Ann")).toBeInTheDocument();
    expect(screen.getByText("Ben")).toBeInTheDocument();
    expect(screen.queryByTestId("replies-load-more")).not.toBeInTheDocument();
  });

  it("replaces an already-loaded page when it is refetched, instead of duplicating it", () => {
    const first = {
      data: {
        data: [reply("r-1", "Ann", { likeCount: 1 }), reply("r-2", "Ben")],
        total: 2,
        page: 1,
        pages: 1,
      },
      isFetching: false,
    };
    const refetched = {
      data: {
        data: [reply("r-1", "Ann", { likeCount: 4 })],
        total: 1,
        page: 1,
        pages: 1,
      },
      isFetching: false,
    };

    mockGetReplies.mockReturnValue(first);
    const { rerender } = renderThread();
    expect(screen.getAllByTestId("comment-item")).toHaveLength(2);

    // A refetch (someone deleted Ben's reply, Ann's likes moved) must replace
    // page 1 rather than append to it.
    mockGetReplies.mockReturnValue(refetched);
    rerender(
      <RepliesThread
        commentId="c-1"
        momentId="moment-1"
        myUserId="me-1"
        isLoggedIn
        onRequireLogin={jest.fn()}
      />
    );

    expect(screen.getAllByTestId("comment-item")).toHaveLength(1);
    expect(screen.queryByText("Ben")).not.toBeInTheDocument();
    expect(screen.getByTestId("comment-like")).toHaveTextContent("4");
  });

  it("drops a reply I delete from the thread right away", async () => {
    const mine = {
      data: {
        data: [reply("r-1", "Me", { user: { _id: "me-1", name: "Me" } })],
        total: 1,
        page: 1,
        pages: 1,
      },
      isFetching: false,
    };
    mockGetReplies.mockReturnValue(mine);

    renderThread();
    expect(screen.getAllByTestId("comment-item")).toHaveLength(1);

    fireEvent.click(screen.getByTestId("comment-delete"));

    expect(mockDeleteComment).toHaveBeenCalledWith({
      momentId: "moment-1",
      commentId: "r-1",
    });
    await waitFor(() =>
      expect(screen.queryByTestId("comment-item")).not.toBeInTheDocument()
    );
  });

  it("hides load more on the last page", () => {
    mockGetReplies.mockReturnValue({
      data: { data: [reply("r-1", "Ann")], total: 1, page: 1, pages: 1 },
      isFetching: false,
    });

    renderThread();
    expect(screen.queryByTestId("replies-load-more")).not.toBeInTheDocument();
  });

  it("does not offer a nested reply button on a reply", () => {
    mockGetReplies.mockReturnValue({
      data: { data: [reply("r-1", "Ann")], total: 1, page: 1, pages: 1 },
      isFetching: false,
    });

    renderThread();
    expect(screen.queryByTestId("comment-reply")).not.toBeInTheDocument();
  });
});
