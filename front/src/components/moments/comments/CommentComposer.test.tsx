import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import CommentComposer from "./CommentComposer";

const mockAddComment = jest.fn();
const mockUploadImage = jest.fn();
let mockAddState: any = { isLoading: false };

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../chat/GifPickerPanel", () => (props: any) => (
  <button type="button" onClick={() => props.onSelectGif("https://media1.giphy.com/media/x/giphy.gif")}>
    pick-gif
  </button>
));

jest.mock("../../../store/slices/momentsSlice", () => ({
  useAddMomentCommentMutation: () => [mockAddComment, mockAddState],
  useUploadCommentImageMutation: () => [mockUploadImage, { isLoading: false }],
}));

const unwrappable = (value: any) => ({ unwrap: () => Promise.resolve(value) });

const renderComposer = (props: any = {}) => {
  const onRequireLogin = props.onRequireLogin || jest.fn();
  const onDone = props.onDone || jest.fn();
  render(
    <CommentComposer
      momentId="moment-1"
      mode={props.mode}
      parentComment={props.parentComment}
      momentText={props.momentText}
      isLoggedIn={props.isLoggedIn !== false}
      onRequireLogin={onRequireLogin}
      onDone={onDone}
      inputId={props.inputId}
    />
  );
  return { onRequireLogin, onDone };
};

beforeEach(() => {
  jest.clearAllMocks();
  mockAddState = { isLoading: false };
  mockAddComment.mockReturnValue(unwrappable({ data: { _id: "c-new" } }));
  mockUploadImage.mockReturnValue(unwrappable({ data: { imageUrl: "https://cdn/x.jpg" } }));
});

describe("CommentComposer", () => {
  it("submits a plain comment with { momentId, text }", async () => {
    const { onDone } = renderComposer();
    const box = screen.getByTestId("comment-composer-text");

    fireEvent.change(box, { target: { value: "Great shot" } });
    fireEvent.click(screen.getByTestId("comment-composer-submit"));

    await waitFor(() =>
      expect(mockAddComment).toHaveBeenCalledWith({
        momentId: "moment-1",
        text: "Great shot",
      })
    );
    await waitFor(() => expect(onDone).toHaveBeenCalled());
    expect(screen.getByTestId("comment-composer-text")).toHaveValue("");
  });

  it("submits a reply with the parent comment id", async () => {
    renderComposer({ mode: "reply", parentComment: "c-1" });

    fireEvent.change(screen.getByTestId("comment-composer-text"), {
      target: { value: "Agreed" },
    });
    fireEvent.click(screen.getByTestId("comment-composer-submit"));

    await waitFor(() =>
      expect(mockAddComment).toHaveBeenCalledWith({
        momentId: "moment-1",
        text: "Agreed",
        parentComment: "c-1",
      })
    );
  });

  it("prefills the original text in correction mode and submits a correction", async () => {
    renderComposer({ mode: "correction", momentText: "I go to school yesterday" });

    expect(screen.getByTestId("comment-composer-original")).toHaveValue(
      "I go to school yesterday"
    );

    fireEvent.change(screen.getByTestId("comment-composer-corrected"), {
      target: { value: "I went to school yesterday" },
    });
    fireEvent.change(screen.getByTestId("comment-composer-explanation"), {
      target: { value: "Past tense." },
    });
    fireEvent.click(screen.getByTestId("comment-composer-submit"));

    await waitFor(() =>
      expect(mockAddComment).toHaveBeenCalledWith({
        momentId: "moment-1",
        text: "",
        correction: {
          originalText: "I go to school yesterday",
          correctedText: "I went to school yesterday",
          explanation: "Past tense.",
        },
      })
    );
  });

  // Only a correction still uploads its photo in a second request (its
  // nested `correction` can't travel as multipart, moments#21).
  it("uploads a correction's attached image onto the comment it just created", async () => {
    renderComposer({ mode: "correction" });
    const file = new File(["x"], "photo.png", { type: "image/png" });

    fireEvent.change(screen.getByTestId("comment-composer-corrected"), {
      target: { value: "Look" },
    });
    fireEvent.change(screen.getByTestId("comment-composer-image"), {
      target: { files: [file] },
    });
    fireEvent.click(screen.getByTestId("comment-composer-submit"));

    await waitFor(() =>
      expect(mockUploadImage).toHaveBeenCalledWith({ commentId: "c-new", file })
    );
  });

  it("disables submit while empty and while the request is in flight", () => {
    const { unmount } = render(
      <CommentComposer
        momentId="moment-1"
        isLoggedIn
        onRequireLogin={jest.fn()}
      />
    );
    expect(screen.getByTestId("comment-composer-submit")).toBeDisabled();

    fireEvent.change(screen.getByTestId("comment-composer-text"), {
      target: { value: "Hi" },
    });
    expect(screen.getByTestId("comment-composer-submit")).not.toBeDisabled();
    unmount();

    mockAddState = { isLoading: true };
    render(
      <CommentComposer
        momentId="moment-1"
        isLoggedIn
        onRequireLogin={jest.fn()}
      />
    );
    fireEvent.change(screen.getByTestId("comment-composer-text"), {
      target: { value: "Hi" },
    });
    expect(screen.getByTestId("comment-composer-submit")).toBeDisabled();
  });

  it("keeps submit disabled in correction mode until there is a corrected text", () => {
    renderComposer({ mode: "correction", momentText: "original" });
    expect(screen.getByTestId("comment-composer-submit")).toBeDisabled();

    fireEvent.change(screen.getByTestId("comment-composer-corrected"), {
      target: { value: "fixed" },
    });
    expect(screen.getByTestId("comment-composer-submit")).not.toBeDisabled();
  });

  it("asks a logged-out visitor to sign in instead of posting", () => {
    const { onRequireLogin } = renderComposer({ isLoggedIn: false });

    fireEvent.change(screen.getByTestId("comment-composer-text"), {
      target: { value: "Hi" },
    });
    fireEvent.click(screen.getByTestId("comment-composer-submit"));

    expect(onRequireLogin).toHaveBeenCalled();
    expect(mockAddComment).not.toHaveBeenCalled();
  });

  it("shows the server's error inline and keeps the text", async () => {
    mockAddComment.mockReturnValue({
      unwrap: () => Promise.reject({ data: { error: "Daily comment limit reached" } }),
    });
    renderComposer();

    fireEvent.change(screen.getByTestId("comment-composer-text"), {
      target: { value: "Hi" },
    });
    fireEvent.click(screen.getByTestId("comment-composer-submit"));

    await waitFor(() =>
      expect(screen.getByTestId("comment-composer-error")).toHaveTextContent(
        "Daily comment limit reached"
      )
    );
    expect(screen.getByTestId("comment-composer-text")).toHaveValue("Hi");
  });
  it("keeps a posted correction when only the photo upload fails", async () => {
    mockUploadImage.mockReturnValue({
      unwrap: () => Promise.reject({ data: { error: "Upload failed" } }),
    });
    const { onDone } = renderComposer({ mode: "correction" });
    const file = new File(["x"], "photo.png", { type: "image/png" });

    fireEvent.change(screen.getByTestId("comment-composer-corrected"), {
      target: { value: "Look" },
    });
    fireEvent.change(screen.getByTestId("comment-composer-image"), {
      target: { files: [file] },
    });
    fireEvent.click(screen.getByTestId("comment-composer-submit"));

    await waitFor(() =>
      expect(screen.getByTestId("comment-composer-notice")).toHaveTextContent(
        "Comment posted, but the photo didn't attach."
      )
    );
    // The comment itself exists: no error, the box clears, the list refreshes.
    expect(screen.queryByTestId("comment-composer-error")).not.toBeInTheDocument();
    expect(screen.getByTestId("comment-composer-corrected")).toHaveValue("");
    expect(onDone).toHaveBeenCalled();
  });

  it("clears the file input after a successful post so the same file can be picked again", async () => {
    renderComposer();
    const file = new File(["x"], "photo.png", { type: "image/png" });
    const input = screen.getByTestId("comment-composer-image") as HTMLInputElement;

    fireEvent.change(screen.getByTestId("comment-composer-text"), {
      target: { value: "Look" },
    });
    fireEvent.change(input, { target: { files: [file] } });
    fireEvent.click(screen.getByTestId("comment-composer-submit"));

    await waitFor(() => expect(input.value).toBe(""));
  });

  it("caps the fields at the lengths models/Comment.js accepts", () => {
    renderComposer({ mode: "correction", momentText: "original" });
    expect(screen.getByTestId("comment-composer-text")).toHaveAttribute("maxlength", "500");
    expect(screen.getByTestId("comment-composer-original")).toHaveAttribute("maxlength", "2000");
    expect(screen.getByTestId("comment-composer-corrected")).toHaveAttribute("maxlength", "2000");
    expect(screen.getByTestId("comment-composer-explanation")).toHaveAttribute("maxlength", "500");
  });
});

describe("photo, GIF and empty text (moments#21)", () => {
  const pickFile = () =>
    fireEvent.change(screen.getByTestId("comment-composer-image"), {
      target: { files: [new File(["x"], "p.jpg", { type: "image/jpeg" })] },
    });

  it("posts a photo with no text in one request", async () => {
    renderComposer();
    expect(screen.getByTestId("comment-composer-submit")).toBeDisabled();
    pickFile();
    expect(screen.getByTestId("comment-composer-submit")).not.toBeDisabled();
    fireEvent.click(screen.getByTestId("comment-composer-submit"));
    await waitFor(() => expect(mockAddComment).toHaveBeenCalledTimes(1));
    const arg = mockAddComment.mock.calls[0][0];
    expect(arg.image).toBeInstanceOf(File);
    expect(arg.text).toBe("");
    expect(mockUploadImage).not.toHaveBeenCalled();
  });

  it("posts a GIF as imageUrl", async () => {
    renderComposer();
    fireEvent.click(screen.getByTestId("comment-composer-gif"));
    fireEvent.click(screen.getByText("pick-gif"));
    expect(screen.getByTestId("comment-composer-gif-preview")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("comment-composer-submit"));
    await waitFor(() => expect(mockAddComment).toHaveBeenCalled());
    expect(mockAddComment.mock.calls[0][0].imageUrl).toBe("https://media1.giphy.com/media/x/giphy.gif");
    expect(mockAddComment.mock.calls[0][0].image).toBeUndefined();
  });

  it("a photo replaces a picked GIF and vice versa", () => {
    renderComposer();
    fireEvent.click(screen.getByTestId("comment-composer-gif"));
    fireEvent.click(screen.getByText("pick-gif"));
    pickFile();
    expect(screen.queryByTestId("comment-composer-gif-preview")).not.toBeInTheDocument();
  });

  it("a correction with a photo keeps the two-step upload", async () => {
    renderComposer({ mode: "correction" });
    fireEvent.change(screen.getByTestId("comment-composer-corrected"), { target: { value: "Fixed" } });
    pickFile();
    fireEvent.click(screen.getByTestId("comment-composer-submit"));
    await waitFor(() => expect(mockUploadImage).toHaveBeenCalled());
    expect(mockAddComment.mock.calls[0][0].image).toBeUndefined();
  });

  it("no GIF button on a correction", () => {
    renderComposer({ mode: "correction" });
    expect(screen.queryByTestId("comment-composer-gif")).not.toBeInTheDocument();
  });
});
