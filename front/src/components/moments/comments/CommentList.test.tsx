import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import CommentList from "./CommentList";

const mockGetComments = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../../hooks/useTargetLanguage", () => ({
  useTargetLanguage: () => "en",
}));

jest.mock("../../ads/AdUnit", () => () => null);

const noop = () => [jest.fn(() => ({ unwrap: () => Promise.resolve({}) })), {}];

jest.mock("../../../store/slices/momentsSlice", () => ({
  useGetMomentCommentsQuery: (args: any) => mockGetComments(args),
  useLikeCommentMutation: () => noop(),
  useReactToCommentMutation: () => noop(),
  useUnreactToCommentMutation: () => noop(),
  useTranslateCommentMutation: () => noop(),
  useDeleteMomentCommentMutation: () => noop(),
  useAddMomentCommentMutation: () => [jest.fn(), { isLoading: false }],
  useUploadCommentImageMutation: () => [jest.fn(), { isLoading: false }],
  useGetCommentRepliesQuery: () => ({ data: undefined, isFetching: false }),
}));

const comment = (id: string, name: string) => ({
  _id: id,
  text: `comment ${id}`,
  createdAt: new Date().toISOString(),
  user: { _id: `u-${id}`, name, imageUrls: [] },
});

const emptyResult = { data: { data: [], total: 0, page: 1, pages: 0 }, isLoading: false, isFetching: false };

const renderList = (props: any = {}) => {
  const onTotalChange = props.onTotalChange || jest.fn();
  const utils = render(
    <MemoryRouter>
      <CommentList
        momentId="moment-1"
        momentText="I go to school yesterday"
        myUserId={props.myUserId === undefined ? "me-1" : props.myUserId}
        isLoggedIn={props.isLoggedIn !== false}
        onRequireLogin={props.onRequireLogin || jest.fn()}
        onTotalChange={onTotalChange}
        momentOwnerId={props.momentOwnerId}
      />
    </MemoryRouter>
  );
  return { ...utils, onTotalChange };
};

beforeEach(() => {
  jest.clearAllMocks();
  mockGetComments.mockReturnValue(emptyResult);
});

describe("CommentList", () => {
  it("shows the empty state when there are no comments", () => {
    renderList();
    expect(screen.getByTestId("comments-empty")).toHaveTextContent(
      "No comments yet"
    );
  });

  it("renders one item per comment and counts by the envelope's total", () => {
    mockGetComments.mockReturnValue({
      data: {
        data: [comment("c-1", "Ann"), comment("c-2", "Ben")],
        total: 7,
        page: 1,
        pages: 1,
      },
      isLoading: false,
      isFetching: false,
    });

    renderList();
    expect(screen.getAllByTestId("comment-item")).toHaveLength(2);
    // `total`, not the number of rows on this page.
    expect(screen.getByTestId("comments-total")).toHaveTextContent("7");
    expect(screen.queryByTestId("comments-empty")).not.toBeInTheDocument();
  });

  it("reports the total upwards so the header counter can follow it", async () => {
    mockGetComments.mockReturnValue({
      data: { data: [comment("c-1", "Ann")], total: 12, page: 1, pages: 1 },
      isLoading: false,
      isFetching: false,
    });

    const { onTotalChange } = renderList();
    await waitFor(() => expect(onTotalChange).toHaveBeenCalledWith(12));
  });

  it("loads the next page of comments and keeps the first", () => {
    const pageOne = {
      data: { data: [comment("c-1", "Ann")], total: 2, page: 1, pages: 2 },
      isLoading: false,
      isFetching: false,
    };
    const pageTwo = {
      data: { data: [comment("c-2", "Ben")], total: 2, page: 2, pages: 2 },
      isLoading: false,
      isFetching: false,
    };
    mockGetComments.mockImplementation(({ page }: any) =>
      page === 1 ? pageOne : pageTwo
    );

    renderList();
    expect(mockGetComments).toHaveBeenCalledWith(
      expect.objectContaining({ momentId: "moment-1", page: 1, limit: 20 })
    );
    expect(screen.queryByText("Ben")).not.toBeInTheDocument();

    fireEvent.click(screen.getByTestId("comments-load-more"));

    expect(screen.getByText("Ann")).toBeInTheDocument();
    expect(screen.getByText("Ben")).toBeInTheDocument();
    expect(screen.queryByTestId("comments-load-more")).not.toBeInTheDocument();
  });

  it("offers a correction composer alongside the comment composer", () => {
    renderList();
    expect(screen.queryByTestId("comment-composer-corrected")).not.toBeInTheDocument();

    fireEvent.click(screen.getByTestId("comments-mode-correction"));
    expect(screen.getByTestId("comment-composer-original")).toHaveValue(
      "I go to school yesterday"
    );
  });

  it("shows a sign-in prompt instead of the composer when logged out", () => {
    renderList({ isLoggedIn: false, myUserId: undefined });
    expect(screen.queryByTestId("comment-composer")).not.toBeInTheDocument();
    expect(screen.getByTestId("comments-signin")).toBeInTheDocument();
  });
});

it("passes the moment's owner down so the owner sees Delete on others' comments", async () => {
  // A comment by someone else ("u-c-1"), seen by the moment's owner.
  mockGetComments.mockReturnValue({
    data: { data: [comment("c-1", "Ann")], total: 1, page: 1, pages: 1 },
    isLoading: false,
    isFetching: false,
  });
  renderList({ myUserId: "owner-1", momentOwnerId: "owner-1" });
  expect(await screen.findByTestId("comment-delete")).toBeInTheDocument();
});
