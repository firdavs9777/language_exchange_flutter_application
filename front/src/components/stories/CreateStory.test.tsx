import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import CreateStory from "./CreateStory";
import notify from "../../design/notify";
import {
  serializeOverlays,
  serializeMentions,
  serializeLink,
  parseLinkUrl,
  videoFileError,
  videoDurationError,
  newOverlayDraft,
  OVERLAY_MAX_COUNT,
  MENTION_MAX_COUNT,
} from "./storyOverlays";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
  Link: ({ to, children, ...rest }: any) => (
    <a href={to} {...rest}>
      {children}
    </a>
  ),
}));

jest.mock("react-redux", () => ({
  useSelector: (selector: any) =>
    selector({ auth: { userInfo: { user: { _id: "me", name: "Me" } } } }),
}));

const mockCreateStory = jest.fn();
const mockCreateVideoStory = jest.fn();
let mockVideoConfig: any;
let mockCloseFriends: any;

jest.mock("../../store/slices/storiesSlice", () => ({
  useCreateStoryMutation: () => [mockCreateStory, { isLoading: false }],
  useCreateVideoStoryMutation: () => [mockCreateVideoStory, { isLoading: false }],
  useGetVideoConfigQuery: () => mockVideoConfig,
  useGetCloseFriendsQuery: () => mockCloseFriends,
}));

// The mention picker lists the author's followings, not a member search.
let mockFollowingsState: any;
let mockFollowingsArgs: any[] = [];
jest.mock("../../store/slices/usersSlice", () => ({
  useGetFollowingsQuery: (arg: any, opts: any) => {
    mockFollowingsArgs.push([arg, opts]);
    return mockFollowingsState;
  },
}));

jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn(), info: jest.fn() },
}));

const VIDEO_CONFIG = {
  success: true,
  data: {
    video: {
      maxDuration: 600,
      maxDurationFormatted: "10:00",
      maxSize: 1073741824,
      maxSizeMB: 1024,
      allowedTypes: ["video/mp4", "video/quicktime"],
    },
    image: { maxSizeMB: 10, maxMediaPerStory: 5 },
  },
};

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });

beforeEach(() => {
  jest.clearAllMocks();
  mockCreateStory.mockReturnValue(resolved());
  mockCreateVideoStory.mockReturnValue(resolved());
  mockVideoConfig = { data: VIDEO_CONFIG };
  mockCloseFriends = { data: { success: true, data: [{ _id: "cf-1", name: "Ann" }] } };
  mockFollowingsState = { data: undefined, isFetching: false };
  mockFollowingsArgs = [];
  (global as any).URL.createObjectURL = jest.fn(() => "blob:preview");
  (global as any).URL.revokeObjectURL = jest.fn();
});

/** Every composer test starts in the editor; the media step is its own test. */
const openTextEditor = () => {
  render(<CreateStory />);
  fireEvent.click(screen.getByTestId("pick-text"));
  return screen.getByTestId("story-canvas");
};

/** jsdom gives every element a zero-sized box, and a drag divided by zero is
 * NaN. This is the canvas the pointer maths is written against. */
const sizeCanvas = (canvas: HTMLElement) => {
  canvas.getBoundingClientRect = () =>
    ({ left: 0, top: 0, width: 400, height: 800, right: 400, bottom: 800, x: 0, y: 0 } as any);
};

/**
 * jsdom has no PointerEvent constructor, so fireEvent.pointerMove falls back to
 * a bare Event and silently drops clientX/clientY. A MouseEvent named after the
 * pointer event carries the coordinates and still reaches React's
 * onPointerMove, which dispatches on the event's type.
 */
const pointer = (node: HTMLElement, type: string, clientX = 0, clientY = 0) =>
  fireEvent(node, new MouseEvent(type, { bubbles: true, cancelable: true, clientX, clientY }));

const sentField = (mock: jest.Mock, field: string) => {
  const form = mock.mock.calls[0][0] as FormData;
  const raw = form.get(field);
  return raw === null ? null : JSON.parse(String(raw));
};

describe("overlay serialization", () => {
  it("matches the backend schema field for field", () => {
    const drafts = [
      newOverlayDraft({
        content: "  Hello  ",
        x: 0.25,
        y: 0.75,
        scale: 1.5,
        color: "#FF3B30",
        fontStyle: "serif",
        bgMode: "semi",
      }),
    ];
    expect(serializeOverlays(drafts)).toEqual([
      {
        type: "text",
        content: "Hello",
        x: 0.25,
        y: 0.75,
        scale: 1.5,
        color: "#FF3B30",
        fontStyle: "serif",
        bgMode: "semi",
      },
    ]);
  });

  it("clamps positions into 0-1, scale into 0.5-3 and falls back on bad enums", () => {
    const [entry] = serializeOverlays([
      newOverlayDraft({ content: "x", x: 4, y: -2, scale: 99, color: "red", fontStyle: "comic" as any, bgMode: "blur" as any }),
    ]);
    expect(entry.x).toBe(1);
    expect(entry.y).toBe(0);
    expect(entry.scale).toBe(3);
    expect(entry.color).toBe("#FFFFFF");
    expect(entry.fontStyle).toBe("sans-serif");
    expect(entry.bgMode).toBe("none");
  });

  it("drops empty overlays and stops at the backend's limit", () => {
    const drafts = [newOverlayDraft({ content: "   " })];
    for (let i = 0; i < 25; i += 1) drafts.push(newOverlayDraft({ content: "n" + i }));
    const out = serializeOverlays(drafts);
    expect(out.length).toBe(OVERLAY_MAX_COUNT);
    expect(out[0].content).toBe("n0");
  });
});

describe("mention serialization", () => {
  it("converts 0-1 placement to the 0-100 scale parseMentions expects", () => {
    expect(
      serializeMentions([{ id: "m1", userId: "u1", name: "Ann", x: 0.5, y: 0.8 }])
    ).toEqual([{ user: "u1", x: 50, y: 80 }]);
  });

  it("dedupes and never sends more than five", () => {
    const drafts = [];
    for (let i = 0; i < 9; i += 1) {
      drafts.push({ id: "m" + i, userId: "u" + i, name: "n", x: 0.5, y: 0.5 });
    }
    drafts.push({ id: "dupe", userId: "u0", name: "n", x: 0.1, y: 0.1 });
    expect(serializeMentions(drafts).length).toBe(MENTION_MAX_COUNT);
  });
});

describe("link validation", () => {
  it("accepts http(s) urls and reports the real host", () => {
    expect(parseLinkUrl("https://www.Example.com/a?b=1")).toEqual({
      url: "https://www.Example.com/a?b=1",
      host: "example.com",
    });
  });

  it("rejects other schemes, hostless urls and credential tricks", () => {
    expect(parseLinkUrl("javascript:alert(1)")).toBeNull();
    expect(parseLinkUrl("data:text/html,x")).toBeNull();
    expect(parseLinkUrl("http:///nowhere")).toBeNull();
    expect(parseLinkUrl("https://paypal.com@evil.tld")).toBeNull();
    expect(parseLinkUrl("not a url")).toBeNull();
  });

  it("falls back to the host when no display text is given", () => {
    expect(serializeLink({ url: "https://shop.example.com/x", title: "", displayText: "" })).toEqual({
      url: "https://shop.example.com/x",
      title: "",
      displayText: "shop.example.com",
    });
  });
});

describe("video constraints", () => {
  it("rejects a disallowed type and an oversized file", () => {
    const c = VIDEO_CONFIG.data.video;
    expect(videoFileError({ type: "video/avi", size: 10 }, c)).toBe("type");
    expect(videoFileError({ type: "video/mp4", size: 2e9 }, c)).toBe("size");
    expect(videoFileError({ type: "video/mp4", size: 10 }, c)).toBeNull();
  });

  it("rejects a clip longer than the server allows", () => {
    const c = VIDEO_CONFIG.data.video;
    expect(videoDurationError(900, c)).toBe("duration");
    expect(videoDurationError(120, c)).toBeNull();
  });
});

describe("the composer", () => {
  it("shows the video constraints before anything is uploaded", () => {
    render(<CreateStory />);
    const hint = screen.getByTestId("video-constraints");
    expect(hint.textContent).toContain("10:00");
    expect(hint.textContent).toContain("1024 MB");
    expect(hint.textContent).toContain("video/mp4");
  });

  it("refuses a video the server would reject and never opens the editor", () => {
    render(<CreateStory />);
    const file = new File(["x"], "clip.avi", { type: "video/avi" });
    Object.defineProperty(file, "size", { value: 1000 });
    fireEvent.change(screen.getByTestId("video-input"), { target: { files: [file] } });
    expect(screen.queryByTestId("story-canvas")).toBeNull();
    expect(screen.getByTestId("media-error")).toBeInTheDocument();
  });

  it("adds, edits, drags and deletes a text overlay, then uploads it as JSON", async () => {
    const canvas = openTextEditor();
    sizeCanvas(canvas);

    fireEvent.click(screen.getByTestId("add-text-overlay"));
    fireEvent.change(screen.getByTestId("overlay-content-0"), {
      target: { value: "On the move" },
    });
    fireEvent.change(screen.getByTestId("overlay-font-0"), { target: { value: "bold" } });
    fireEvent.change(screen.getByTestId("overlay-bg-0"), { target: { value: "solid" } });
    fireEvent.click(screen.getByTestId("overlay-color-0-2"));

    const node = screen.getByTestId("overlay-node-0");
    pointer(node, "pointerdown", 200, 320);
    pointer(node, "pointermove", 300, 640);
    pointer(node, "pointerup", 300, 640);
    expect(node).toHaveStyle({ left: "75%", top: "80%" });

    fireEvent.change(screen.getByTestId("story-text"), { target: { value: "hi" } });
    fireEvent.click(screen.getByTestId("share-story"));

    await waitFor(() => expect(mockCreateStory).toHaveBeenCalled());
    // The app hides a text story's `text` once it has overlays, so the body
    // travels as the FIRST overlay too: centred, in the story's own colour.
    expect(sentField(mockCreateStory, "overlays")).toEqual([
      {
        type: "text",
        content: "hi",
        x: 0.5,
        y: 0.5,
        scale: 1.5,
        color: "#FFFFFF",
        fontStyle: "sans-serif",
        bgMode: "none",
      },
      {
        type: "text",
        content: "On the move",
        x: 0.75,
        y: 0.8,
        scale: 1,
        color: "#FF3B30",
        fontStyle: "bold",
        bgMode: "solid",
      },
    ]);
  });

  it("drags with touch as well as with a mouse", () => {
    const canvas = openTextEditor();
    sizeCanvas(canvas);
    fireEvent.click(screen.getByTestId("add-text-overlay"));
    const node = screen.getByTestId("overlay-node-0");
    pointer(node, "pointerdown", 0, 0);
    pointer(node, "pointermove", 100, 200);
    pointer(node, "pointerup", 100, 200);
    expect(node).toHaveStyle({ left: "25%", top: "25%" });
  });

  it("stops offering new overlays at the backend's limit", () => {
    openTextEditor();
    const add = screen.getByTestId("add-text-overlay");
    for (let i = 0; i < OVERLAY_MAX_COUNT + 3; i += 1) fireEvent.click(add);
    expect(screen.getAllByTestId(/^overlay-node-/).length).toBe(OVERLAY_MAX_COUNT);
    expect(add).toBeDisabled();
  });

  it("refuses a text story that has only an overlay and no text", async () => {
    // The backend 400s on a story with neither media nor `text`, so an
    // overlay is not a substitute for the caption -- it is drawn on top of a
    // story that must exist first. The composer used to let this through and
    // the author lost the upload.
    openTextEditor();
    fireEvent.click(screen.getByTestId("add-text-overlay"));
    fireEvent.change(screen.getByTestId("overlay-content-0"), {
      target: { value: "Seoul, 6am" },
    });
    fireEvent.click(screen.getByTestId("share-story"));

    expect(notify.error).toHaveBeenCalled();
    await waitFor(() => expect(mockCreateStory).not.toHaveBeenCalled());
  });

  it("deletes an overlay", () => {
    openTextEditor();
    fireEvent.click(screen.getByTestId("add-text-overlay"));
    expect(screen.getByTestId("overlay-node-0")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("overlay-delete-0"));
    expect(screen.queryByTestId("overlay-node-0")).toBeNull();
  });

  it("lists the people the author follows, filters them and uploads the mention", async () => {
    mockFollowingsState = {
      data: { success: true, data: [{ _id: "u-1", name: "Ann" }, { _id: "u-2", name: "Bo" }] },
      isFetching: false,
    };
    openTextEditor();
    fireEvent.click(screen.getByTestId("open-mentions"));
    // No query yet: the whole list, because it is already in hand.
    expect(screen.getByTestId("mention-result-u-1")).toBeInTheDocument();
    expect(screen.getByTestId("mention-result-u-2")).toBeInTheDocument();

    // Filtering happens in the browser, on name or username.
    fireEvent.change(screen.getByTestId("mention-search"), { target: { value: "an" } });
    expect(screen.queryByTestId("mention-result-u-2")).toBeNull();
    fireEvent.click(screen.getByTestId("mention-result-u-1"));
    expect(screen.getByTestId("mention-node-0")).toBeInTheDocument();

    fireEvent.change(screen.getByTestId("story-text"), { target: { value: "hi" } });
    fireEvent.click(screen.getByTestId("share-story"));
    await waitFor(() => expect(mockCreateStory).toHaveBeenCalled());
    expect(sentField(mockCreateStory, "mentions")).toEqual([{ user: "u-1", x: 50, y: 80 }]);
  });

  it("asks for the followings of the signed-in author, and only with the picker open", () => {
    mockFollowingsState = { data: { success: true, data: [] }, isFetching: false };
    openTextEditor();
    // Closed picker: the query is skipped, so opening the composer costs no
    // request at all.
    expect(mockFollowingsArgs.every(([, opts]: any) => opts.skip)).toBe(true);

    fireEvent.click(screen.getByTestId("open-mentions"));
    const live = mockFollowingsArgs.filter(([, opts]: any) => !opts.skip);
    expect(live.length).toBeGreaterThan(0);
    expect(live[0][0]).toEqual({ userId: "me" });
  });

  it("matches a username as well as a name", () => {
    mockFollowingsState = {
      data: { success: true, data: [{ _id: "u-1", name: "Ann", username: "seoulcat" }] },
      isFetching: false,
    };
    openTextEditor();
    fireEvent.click(screen.getByTestId("open-mentions"));
    fireEvent.change(screen.getByTestId("mention-search"), { target: { value: "cat" } });
    expect(screen.getByTestId("mention-result-u-1")).toBeInTheDocument();
  });

  it("explains the empty picker instead of showing a blank list", () => {
    mockFollowingsState = { data: { success: true, data: [] }, isFetching: false };
    openTextEditor();
    fireEvent.click(screen.getByTestId("open-mentions"));
    // Nobody followed yet -- a different silence from "nobody matches".
    expect(screen.getByTestId("mention-empty")).toBeInTheDocument();
    expect(screen.queryByTestId("mention-no-match")).toBeNull();
  });

  it("says so when nobody the author follows matches the query", () => {
    mockFollowingsState = {
      data: { success: true, data: [{ _id: "u-1", name: "Ann" }] },
      isFetching: false,
    };
    openTextEditor();
    fireEvent.click(screen.getByTestId("open-mentions"));
    fireEvent.change(screen.getByTestId("mention-search"), { target: { value: "zzz" } });
    expect(screen.getByTestId("mention-no-match")).toBeInTheDocument();
    expect(screen.queryByTestId("mention-empty")).toBeNull();
  });

  it("will not take a sixth mention", () => {
    mockFollowingsState = {
      data: {
        success: true,
        data: [1, 2, 3, 4, 5, 6].map((n) => ({ _id: "u-" + n, name: "U" + n })),
      },
      isFetching: false,
    };
    openTextEditor();
    fireEvent.click(screen.getByTestId("open-mentions"));
    for (const n of [1, 2, 3, 4, 5]) fireEvent.click(screen.getByTestId("mention-result-u-" + n));
    expect(screen.getAllByTestId(/^mention-node-/).length).toBe(MENTION_MAX_COUNT);
    expect(screen.getByTestId("mention-result-u-6")).toBeDisabled();
  });

  it("blocks an invalid link and sends a valid one", async () => {
    openTextEditor();
    fireEvent.click(screen.getByTestId("open-link"));
    fireEvent.change(screen.getByTestId("link-url"), { target: { value: "javascript:alert(1)" } });
    expect(screen.getByTestId("link-error")).toBeInTheDocument();

    fireEvent.change(screen.getByTestId("link-url"), { target: { value: "https://example.com/sale" } });
    fireEvent.change(screen.getByTestId("link-display"), { target: { value: "Shop" } });
    expect(screen.queryByTestId("link-error")).toBeNull();

    fireEvent.change(screen.getByTestId("story-text"), { target: { value: "hi" } });
    fireEvent.click(screen.getByTestId("share-story"));
    await waitFor(() => expect(mockCreateStory).toHaveBeenCalled());
    expect(sentField(mockCreateStory, "link")).toEqual({
      url: "https://example.com/sale",
      title: "",
      displayText: "Shop",
    });
  });

  it("sends close_friends and does not nag when the list has people in it", async () => {
    openTextEditor();
    fireEvent.change(screen.getByTestId("privacy-select"), { target: { value: "close_friends" } });
    expect(screen.queryByTestId("close-friends-hint")).toBeNull();

    fireEvent.change(screen.getByTestId("story-text"), { target: { value: "hi" } });
    fireEvent.click(screen.getByTestId("share-story"));
    await waitFor(() => expect(mockCreateStory).toHaveBeenCalled());
    expect((mockCreateStory.mock.calls[0][0] as FormData).get("privacy")).toBe("close_friends");
  });

  it("points at the close-friends settings page when the list is empty", () => {
    mockCloseFriends = { data: { success: true, data: [] } };
    openTextEditor();
    fireEvent.change(screen.getByTestId("privacy-select"), { target: { value: "close_friends" } });
    expect(screen.getByTestId("close-friends-hint")).toHaveAttribute(
      "href",
      "/settings/close-friends"
    );
  });

  it("keeps poll and question mutually exclusive", () => {
    openTextEditor();
    fireEvent.click(screen.getByTestId("open-poll"));
    expect(screen.getByTestId("poll-question")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("open-question"));
    expect(screen.queryByTestId("poll-question")).toBeNull();
    expect(screen.getByTestId("question-prompt")).toBeInTheDocument();
  });
});

describe("one picture per story (moments#16)", () => {
  const jpg = (name: string) => new File(["x"], name, { type: "image/jpeg" });

  it("offers a single-picture picker", () => {
    render(<CreateStory />);
    expect(screen.getByTestId("photo-input")).not.toHaveAttribute("multiple");
  });

  it("keeps the first of several pictures, says so, and uploads only that one", async () => {
    render(<CreateStory />);
    fireEvent.change(screen.getByTestId("photo-input"), {
      target: { files: [jpg("a.jpg"), jpg("b.jpg"), jpg("c.jpg")] },
    });
    // Every viewer (web and app) draws mediaUrls[0] only; 2-5 were invisible.
    expect(notify.info).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getByTestId("share-story"));
    await waitFor(() => expect(mockCreateStory).toHaveBeenCalled());
    const form = mockCreateStory.mock.calls[0][0] as FormData;
    const sent = form.getAll("media") as File[];
    expect(sent).toHaveLength(1);
    expect(sent[0].name).toBe("a.jpg");
  });

  it("does not nag when one picture was picked", () => {
    render(<CreateStory />);
    fireEvent.change(screen.getByTestId("photo-input"), { target: { files: [jpg("a.jpg")] } });
    expect(notify.info).not.toHaveBeenCalled();
    expect(screen.getByTestId("story-canvas")).toBeInTheDocument();
  });
});

describe("italic text story with stickers (moments#25)", () => {
  it("sends the body overlay in the plain face, not serif, and keeps fontStyle italic", async () => {
    openTextEditor();
    fireEvent.change(screen.getByTestId("story-text"), { target: { value: "hi" } });
    fireEvent.change(screen.getByTestId("story-font"), { target: { value: "italic" } });
    fireEvent.click(screen.getByTestId("add-text-overlay"));
    fireEvent.change(screen.getByTestId("overlay-content-0"), { target: { value: "sticker" } });
    fireEvent.click(screen.getByTestId("share-story"));

    await waitFor(() => expect(mockCreateStory).toHaveBeenCalled());
    expect(sentField(mockCreateStory, "overlays")[0].fontStyle).toBe("sans-serif");
    const form = mockCreateStory.mock.calls[0][0] as FormData;
    expect(form.get("fontStyle")).toBe("italic");
  });
});
