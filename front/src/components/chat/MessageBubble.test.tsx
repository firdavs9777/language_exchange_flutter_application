import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import MessageBubble, { DateSeparator, Message } from "./MessageBubble";

/**
 * The bubble used to be ~200 lines inlined in `ChatContent`'s `.map`, so every
 * keystroke in the composer re-rendered every message in the thread. It is a
 * memoized component now, and this suite pins what it draws: whose side the
 * message is on, the delivery ticks, the date separator, the link card, and
 * lazy images.
 */
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mutation = () => [jest.fn(), { isLoading: false }];

jest.mock("../../store/slices/chatSlice", () => ({
  useTranslateMessageMutation: () => mutation(),
  useSaveMessageVocabularyMutation: () => mutation(),
}));

jest.mock("../../store/slices/learningSlice", () => ({
  useAcceptCorrectionMutation: () => mutation(),
}));

// A child that is always rendered, used as a render counter for the bubble.
const mockRenders = { count: 0 };
jest.mock("./actions/ReactionRow", () => ({
  __esModule: true,
  default: () => {
    mockRenders.count += 1;
    return null;
  },
}));

const message = (extra: Partial<Message> = {}): Message =>
  ({
    _id: "m1",
    message: "hello there",
    createdAt: "2026-09-20T10:00:00.000Z",
    sender: { _id: "me", name: "Me" },
    receiver: { _id: "u2", name: "Ada" },
    ...extra,
  } as Message);

function renderBubble(overrides: any = {}) {
  const props = {
    message: message(),
    isSent: true,
    position: "single" as const,
    isFirstInGroup: true,
    showAvatar: false,
    hideAvatarSpace: false,
    avatarUrl: "/ada.png",
    currentUserId: "me",
    otherUserName: "Ada",
    timeLabel: "10:00",
    isTranslationOpen: false,
    targetLanguage: "en",
    isPlaying: false,
    audioProgress: 0,
    audioElapsed: 0,
    onTogglePlayback: jest.fn(),
    onOpenActions: jest.fn(),
    onToggleReaction: jest.fn(),
    onToggleTranslation: jest.fn(),
    onCorrect: jest.fn(),
    onCorrectionAccepted: jest.fn(),
    onRetry: jest.fn(),
    ...overrides,
  };
  const view = render(<MessageBubble {...props} />);
  return { ...view, props };
}

const bubble = () => document.querySelector(".modern-message") as HTMLElement;

beforeEach(() => {
  mockRenders.count = 0;
});

describe("memoization", () => {
  it("is wrapped in React.memo", () => {
    expect((MessageBubble as any).$$typeof).toBe(Symbol.for("react.memo"));
  });

  it("does not re-render when the same props come round again", () => {
    const { props, rerender } = renderBubble();
    const after = mockRenders.count;

    rerender(<MessageBubble {...(props as any)} />);
    expect(mockRenders.count).toBe(after);

    // ...and does when its own message changed.
    rerender(
      <MessageBubble {...(props as any)} message={message({ status: "read" })} />
    );
    expect(mockRenders.count).toBe(after + 1);
  });
});

describe("whose message it is", () => {
  it("puts my own message on the sent side with no avatar", () => {
    renderBubble();

    expect(bubble()).toHaveClass("sent");
    expect(document.querySelector(".message-avatar")).toBeNull();
  });

  it("puts the other person's message on the received side with their avatar", () => {
    renderBubble({
      message: message({ sender: { _id: "u2", name: "Ada" } }),
      isSent: false,
      showAvatar: true,
    });

    expect(bubble()).toHaveClass("received");
    const avatar = document.querySelector(".message-avatar img") as HTMLImageElement;
    expect(avatar).toBeInTheDocument();
    expect(avatar).toHaveAttribute("src", "/ada.png");
  });

  it("carries the message id for the pinned bar to jump to", () => {
    renderBubble();
    expect(bubble()).toHaveAttribute("data-msg-id", "m1");
  });

  it("renders a system placeholder as a notice, not a bubble", () => {
    renderBubble({ message: message({ message: "Conversation started" }) });

    expect(document.querySelector(".system-notice")).toBeInTheDocument();
    expect(bubble()).toBeNull();
  });
});

describe("delivery ticks", () => {
  it("shows one tick while the message is only sent", () => {
    renderBubble({ message: message({ status: "sent" }) });
    expect(screen.getByTestId("msg-status-sent")).toBeInTheDocument();
    expect(screen.queryByTestId("msg-status-delivered")).not.toBeInTheDocument();
  });

  it("shows the delivered tick once the socket says it arrived", () => {
    renderBubble({ message: message({ status: "delivered" }) });
    expect(screen.getByTestId("msg-status-delivered")).toBeInTheDocument();
  });

  it("marks the message read", () => {
    renderBubble({ message: message({ status: "read" }) });
    expect(screen.getByTestId("msg-status-read")).toBeInTheDocument();
  });

  it("says a message is still going out", () => {
    renderBubble({ message: message({ status: "sending", isOptimistic: true }) });
    expect(screen.getByTestId("msg-status-sending")).toBeInTheDocument();
  });

  it("names the tick for a screen reader", () => {
    renderBubble({ message: message({ status: "read" }) });
    expect(screen.getByTestId("msg-status-read")).toHaveAttribute("aria-label");
  });

  it("never puts ticks on the other person's message", () => {
    renderBubble({
      message: message({ sender: { _id: "u2", name: "Ada" }, status: "read" }),
      isSent: false,
    });
    expect(screen.queryByTestId("msg-status-read")).not.toBeInTheDocument();
  });

  it("offers a retry when sending failed", () => {
    const onRetry = jest.fn();
    renderBubble({ message: message({ status: "error" }), onRetry });

    fireEvent.click(document.querySelector(".retry-btn") as HTMLElement);
    expect(onRetry).toHaveBeenCalled();
  });
});

describe("the date separator", () => {
  it("renders the day above the first message of that day", () => {
    render(<DateSeparator label="Today" />);
    expect(document.querySelector(".date-separator")).toBeInTheDocument();
    expect(screen.getByText("Today")).toHaveClass("date-text");
  });
});

describe("link cards", () => {
  it("shows a card for the first link in a message", () => {
    renderBubble({
      message: message({ message: "read https://bananatalk.app/blog/hello today" }),
    });

    const card = screen.getByTestId("message-link-card");
    expect(card).toHaveAttribute("href", "https://bananatalk.app/blog/hello");
    expect(card).toHaveAttribute("target", "_blank");
    expect(card).toHaveAttribute("rel", "noopener noreferrer");
    expect(card).toHaveTextContent("bananatalk.app");
  });

  it("shows no card when the message has no link", () => {
    renderBubble();
    expect(screen.queryByTestId("message-link-card")).not.toBeInTheDocument();
  });

  it("shows no link card on an emoji sticker", () => {
    renderBubble({ message: message({ message: "\u{1F602}", messageType: "sticker" }) });
    expect(screen.queryByTestId("message-link-card")).toBeNull();
  });
});

describe("images", () => {
  it("loads an image message lazily", () => {
    renderBubble({
      message: message({
        message: "",
        messageType: "image",
        media: { url: "/pic.jpg", type: "image" },
      }),
    });

    const img = document.querySelector(".message-image") as HTMLImageElement;
    expect(img).toHaveAttribute("loading", "lazy");
    expect(img).toHaveAttribute("decoding", "async");
  });

  it("loads the avatar lazily too", () => {
    renderBubble({
      message: message({ sender: { _id: "u2", name: "Ada" } }),
      isSent: false,
      showAvatar: true,
    });

    const avatar = document.querySelector(".message-avatar img") as HTMLImageElement;
    expect(avatar).toHaveAttribute("loading", "lazy");
    expect(avatar).toHaveAttribute("decoding", "async");
  });

  it("loads a GIF lazily", () => {
    renderBubble({
      message: message({ message: "https://media.giphy.com/media/x.gif", messageType: "gif" }),
    });

    const gif = document.querySelector(".gif-message") as HTMLImageElement;
    expect(gif).toHaveAttribute("loading", "lazy");
    expect(gif).toHaveAttribute("decoding", "async");
  });
});

describe("what the bubble hands back", () => {
  it("opens the action menu from the overflow button", () => {
    const onOpenActions = jest.fn();
    renderBubble({ onOpenActions });

    fireEvent.click(document.querySelector(".msg-action-trigger") as HTMLElement);
    expect(onOpenActions).toHaveBeenCalledWith(expect.objectContaining({ _id: "m1" }));
  });

  it("gives an optimistic message no action menu", () => {
    renderBubble({ message: message({ isOptimistic: true, status: "sending" }) });
    expect(document.querySelector(".msg-action-trigger")).toBeNull();
  });

  it("offers Correct and Translate on the other person's text", () => {
    const onCorrect = jest.fn();
    const onToggleTranslation = jest.fn();
    renderBubble({
      message: message({ sender: { _id: "u2", name: "Ada" } }),
      isSent: false,
      onCorrect,
      onToggleTranslation,
    });

    fireEvent.click(document.querySelector(".correct-chip") as HTMLElement);
    expect(onCorrect).toHaveBeenCalled();

    fireEvent.click(document.querySelector(".translate-chip") as HTMLElement);
    expect(onToggleTranslation).toHaveBeenCalledWith("m1");
  });

  it("offers neither on my own message", () => {
    renderBubble();
    expect(document.querySelector(".message-chip-row")).toBeNull();
  });
});

it("draws a placeholder for a message deleted for everyone, with no actions", () => {
  const { props } = renderBubble({
    message: message({ isDeleted: true, deletedForEveryone: true, message: "This message was deleted" } as any),
  });
  expect(screen.getByTestId("message-deleted-placeholder")).toHaveTextContent("This message was deleted");
  fireEvent.contextMenu(document.querySelector('[data-msg-id="m1"]') as HTMLElement);
  expect(props.onOpenActions).not.toHaveBeenCalled();
});

describe("call history messages (chat#6)", () => {
  const callMessage = (callData: any, extra: Partial<Message> = {}): Message =>
    message({
      messageType: "call",
      message: "📞 Missed voice call",
      media: { type: "call", url: "", callData } as any,
      ...extra,
    });

  it("draws a call card, not a File attachment", () => {
    renderBubble({
      message: callMessage({ type: "audio", outcome: "completed", duration: 75, initiator: "me" }),
    });

    expect(screen.getByTestId("call-card")).toBeInTheDocument();
    expect(screen.queryByText("File")).toBeNull();
    expect(screen.getByText("Outgoing voice call")).toBeInTheDocument();
    expect(screen.getByText("1:15")).toBeInTheDocument();
  });

  it("words a missed call from the side of the person who missed it", () => {
    renderBubble({
      message: callMessage(
        { type: "audio", outcome: "no_answer", initiator: "u2" },
        { sender: { _id: "u2", name: "Ada" } }
      ),
      isSent: false,
    });

    expect(screen.getByText("Missed voice call")).toBeInTheDocument();
    expect(screen.getByTestId("call-card")).toHaveClass("call-card--negative");
  });

  it("reads the legacy status of rows written before outcome existed", () => {
    renderBubble({ message: callMessage({ type: "audio", status: "rejected", initiator: "me" }) });
    expect(screen.getByText("Voice call declined")).toBeInTheDocument();
  });

  it("does not print the server's fallback text under the card", () => {
    renderBubble({ message: callMessage({ type: "audio", outcome: "no_answer", initiator: "me" }) });
    expect(screen.queryByText("📞 Missed voice call")).toBeNull();
  });

  it("offers no Correct or Translate chip on a call", () => {
    renderBubble({
      message: callMessage(
        { type: "video", outcome: "completed", initiator: "u2", duration: 5 },
        { sender: { _id: "u2", name: "Ada" } }
      ),
      isSent: false,
    });
    expect(screen.queryByText("Correct")).toBeNull();
    expect(screen.queryByText("Translate")).toBeNull();
  });

  it("survives a call message whose callData is missing", () => {
    renderBubble({ message: callMessage(undefined) });
    expect(screen.getByTestId("call-card")).toBeInTheDocument();
    expect(screen.queryByText("File")).toBeNull();
  });
});

describe("location messages (chat#7)", () => {
  const locationMessage = (location: any): Message =>
    message({ message: "", media: { type: "location", url: "", location } as any });

  it("draws a map card that opens the pin in Maps, not a File attachment", () => {
    renderBubble({
      message: locationMessage({ latitude: 37.5665, longitude: 126.978, placeName: "Seoul", address: "Jung-gu" }),
    });
    const card = screen.getByTestId("location-card");
    expect(card).toHaveAttribute("href", "https://www.google.com/maps/search/?api=1&query=37.5665,126.978");
    expect(card).toHaveAttribute("target", "_blank");
    expect(screen.getByText("Seoul")).toBeInTheDocument();
    expect(screen.getByText("Jung-gu")).toBeInTheDocument();
    expect(screen.queryByText("File")).toBeNull();
  });

  it("titles a pin with no names 'Location'", () => {
    renderBubble({ message: locationMessage({ latitude: 1, longitude: 2, placeName: null, address: null }) });
    expect(screen.getByText("Location")).toBeInTheDocument();
  });

  it("draws a card with no link when the coordinates are missing", () => {
    renderBubble({ message: locationMessage(undefined) });
    expect(screen.getByTestId("location-card")).not.toHaveAttribute("href");
  });
});

describe("waves and stickers are sized by what they say (chat#8)", () => {
  it("draws a greeting card for a wave, with the hand the message carried", () => {
    renderBubble({ message: message({ message: "\u{1F44B}\u{1F3FD}", messageType: "sticker" }) });
    const card = screen.getByTestId("wave-card");
    expect(card).toHaveTextContent("\u{1F44B}\u{1F3FD}");
    expect(card).toHaveTextContent("Hi!");
    expect(document.querySelector(".sticker-message")).toBeNull();
  });

  it("draws a wave sentence stored as 'sticker' as a normal text bubble", () => {
    renderBubble({
      message: message({ message: "\u{1F44B} Hi! I'm learning Korean, want to practise?", messageType: "sticker" }),
    });
    expect(document.querySelector(".sticker-message")).toBeNull();
    expect(document.querySelector(".message-text")).toHaveTextContent("I'm learning Korean");
  });

  it("draws one to three emoji at sticker size, whatever the messageType", () => {
    renderBubble({ message: message({ message: "\u{1F602}\u{1F602}", messageType: "text" }) });
    expect(document.querySelector(".sticker-message")).toHaveTextContent("\u{1F602}\u{1F602}");
  });

  it("draws four emoji as text", () => {
    renderBubble({ message: message({ message: "\u{1F602}\u{1F602}\u{1F602}\u{1F602}" }) });
    expect(document.querySelector(".sticker-message")).toBeNull();
  });
});

describe("story shares, replies and reactions (chat#9)", () => {
  it("draws a story card for a story_share and hides the server's English text", () => {
    const onOpenStory = jest.fn();
    renderBubble({
      message: message({
        messageType: "story_share",
        message: "Shared a story",
        storyReference: { storyId: "s1", thumbnail: "https://cdn.example/s1.jpg" },
        sender: { _id: "u2", name: "Ada" },
      } as any),
      isSent: false,
      onOpenStory,
    });
    const card = screen.getByTestId("story-ref");
    expect(card).toHaveTextContent("Shared a story");
    expect(document.querySelectorAll(".message-text")).toHaveLength(0);
    expect((card.querySelector("img") as HTMLImageElement).src).toBe("https://cdn.example/s1.jpg");
    fireEvent.click(card);
    expect(onOpenStory).toHaveBeenCalledWith("s1");
  });

  it("puts the story above a reply's text", () => {
    renderBubble({
      message: message({
        message: "Love this!",
        storyReference: { storyId: "s1", thumbnail: null },
        sender: { _id: "u2", name: "Ada" },
      } as any),
      isSent: false,
    });
    expect(screen.getByTestId("story-ref")).toHaveTextContent("Replied to your story");
    expect(document.querySelector(".message-text")).toHaveTextContent("Love this!");
  });

  it("keeps the story above an emoji reaction drawn as a sticker", () => {
    renderBubble({
      message: message({ message: "\u{1F525}", storyReference: { storyId: "s1", thumbnail: null } } as any),
    });
    expect(screen.getByTestId("story-ref")).toHaveTextContent("You replied to their story");
    expect(document.querySelector(".sticker-message")).not.toBeNull();
  });

  it("draws a placeholder when a text story has no thumbnail", () => {
    renderBubble({
      message: message({ message: "hi", storyReference: { storyId: "s1", thumbnail: null } } as any),
    });
    expect(screen.getByTestId("story-ref").querySelector("img")).toBeNull();
  });

  it("does not offer to open a story_share that lost its reference", () => {
    renderBubble({ message: message({ messageType: "story_share", message: "Shared a story" } as any), onOpenStory: jest.fn() });
    expect(screen.getByTestId("story-ref")).toBeDisabled();
  });
});

describe("edited, forwarded and corrections (chat#14)", () => {
  it("labels an edited message", () => {
    renderBubble({ message: message({ isEdited: true }) });
    expect(screen.getByTestId("message-edited")).toHaveTextContent("edited");
  });

  it("says nothing on a message that was never edited", () => {
    renderBubble();
    expect(screen.queryByTestId("message-edited")).toBeNull();
  });

  it("marks a forwarded message", () => {
    renderBubble({ message: message({ isForwarded: true } as any) });
    expect(screen.getByTestId("message-forwarded")).toHaveTextContent("Forwarded");
  });

  it("shows every correction, not only the first", () => {
    renderBubble({
      message: message({
        sender: { _id: "u2", name: "Ada" },
        corrections: [
          { _id: "c1", originalText: "I goed", correctedText: "I went", corrector: { _id: "me", name: "Me" } },
          { _id: "c2", originalText: "I goed", correctedText: "I have gone", corrector: { _id: "u3", name: "Bo" } },
        ],
      } as any),
      isSent: false,
    });
    expect(screen.getByText("I went")).toBeInTheDocument();
    expect(screen.getByText("I have gone")).toBeInTheDocument();
  });
});
