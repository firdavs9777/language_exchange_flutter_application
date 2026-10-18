import fs from "fs";
import path from "path";

// Static guards for the chat surface, in the same spirit as
// ../community/communityStyling.test.ts: they do not render anything, they
// just stop specific regressions from creeping back into the component
// source (hex colours outside a stylesheet, react-bootstrap, emoji-as-icon,
// and the dead parallel chat implementation Task H4 removed) where no
// stylesheet, no theme and no code review habit would otherwise catch them.
//
// The colour tokens themselves (`--chat-bg`, `--chat-bubble-*`, ...) and the
// CSS files that must use them are Task H3's surface (index.css,
// ChatContent.css, MainChat.css, UsersList.css) — not asserted here.

const CHAT_DIR = __dirname;

function read(relPath: string): string {
  return fs.readFileSync(path.join(CHAT_DIR, relPath), "utf8");
}

// --- Files held to the full design-system bar ------------------------------
//
// Genuinely new or self-contained surfaces: no inline style attribute at
// all, no colour named by hex, no react-bootstrap, no emoji standing in for
// an icon. (UsersList.tsx is the one file still checked separately below,
// with a narrower rule -- its non-colour inline styles are its own, unrelated
// to this task's re-tokenizing. ChatContent.tsx and MessageBubble.tsx used to
// be checked there too: react-bootstrap's `Form`/`Container` are gone, and
// every remaining inline style -- marginTop, the waveform bar height -- moved
// to a class, so both now carry the full bar.)
const STRICT_FILES = [
  "ChatContent.tsx",
  "ChatInfoPanel.tsx",
  "GifPickerPanel.tsx",
  "MainChat.tsx",
  "MediaGallery.tsx",
  "MessageBubble.tsx",
  "NewChat.tsx",
  "actions/ForwardDialog.tsx",
  "actions/MessageActionMenu.tsx",
  "actions/ReactionRow.tsx",
  "actions/DeleteMessageDialog.tsx",
  "actions/EditMessageDialog.tsx",
  "actions/SendErrorDialog.tsx",
  "ConnectionBanner.tsx",
  "components/BlockedChatBanner.tsx",
  "components/BookmarksDialog.tsx",
  "components/CallMessageCard.tsx",
  "components/CorrectionCard.tsx",
  "components/LocationMessageCard.tsx",
  "components/LocationShareButton.tsx",
  "components/MessageSearchDialog.tsx",
  "components/MuteDurationDialog.tsx",
  "components/StoryReferenceCard.tsx",
  "components/CorrectionModal.tsx",
  "components/TranslationCard.tsx",
];

// Emoji presentation blocks: pictographs, dingbats, symbols and the
// variation selector. Arrows and punctuation (em dash) are deliberately NOT
// in here -- they are typography, not icons.
const EMOJI = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]/u;

describe("chat surface: design-system hygiene", () => {
  STRICT_FILES.forEach((rel) => {
    const source = read(rel);

    it(`${rel} carries no inline style attribute`, () => {
      expect(source.match(/style=\{\{/g) || []).toEqual([]);
    });

    it(`${rel} names no colour by hex`, () => {
      expect(source.match(/#[0-9a-fA-F]{3,8}\b/g) || []).toEqual([]);
    });

    it(`${rel} imports no react-bootstrap`, () => {
      expect(source).not.toContain("react-bootstrap");
    });

    it(`${rel} draws its icons with lucide, not emoji`, () => {
      expect(EMOJI.test(source)).toBe(false);
    });
  });
});

describe("chat surface: inline styles never carry a colour", () => {
  // UsersList.tsx: inline styles are allowed to exist (layout values computed
  // at runtime), but never a hardcoded colour -- that always belongs to a
  // token in the stylesheet.
  ["UsersList.tsx"].forEach((rel) => {
    it(`${rel} keeps colours out of its inline styles`, () => {
      const source = read(rel);
      const inlineStyles = source.match(/style=\{\{[\s\S]*?\}\}/g) || [];
      const withHex = inlineStyles.filter((s) => /#[0-9a-fA-F]{3,8}\b/.test(s));
      expect(withHex).toEqual([]);
    });
  });
});

describe("the dead parallel chat implementation stays deleted", () => {
  const DEAD_PATHS = [
    "components/ChatHeader.tsx",
    "components/ChatHeader.scss",
    "components/ConversationItem.tsx",
    "components/ConversationItem.scss",
    "components/MessageBubble.tsx",
    "components/MessageBubble.scss",
    "components/MessageInput.tsx",
    "components/MessageInput.scss",
    "components/OnlineStatus.tsx",
    "components/OnlineStatus.scss",
    "components/ReadReceipt.tsx",
    "components/ReadReceipt.scss",
    "components/TypingIndicator.tsx",
    "components/TypingIndicator.scss",
    "components/EmojiPicker.tsx",
    "components/EmojiPicker.scss",
    "components/ReactionPicker.tsx",
    "components/ReactionPicker.scss",
    "components/VoiceRecorder.tsx",
    "components/VoiceRecorder.scss",
    "components/VoicePlayer.tsx",
    "components/VoicePlayer.scss",
    "components/MediaPreview.tsx",
    "components/MediaPreview.scss",
    "components/ReplyPreview.tsx",
    "components/ReplyPreview.scss",
    "components/index.ts",
    "hooks/useTyping.ts",
    "hooks/useVoiceRecorder.ts",
    "hooks/index.ts",
    "utils/emojiUtils.ts",
    "utils/messageFormatter.ts",
    "utils/index.ts",
    "MessageList.tsx",
    "MessageList.css",
    "ConversationList.tsx",
    "ConversationList.css",
    "ChatInput.tsx",
    "ChatInput.css",
    "actions/BookmarksView.tsx",
    "type.ts",
    "Chat.css",
  ];

  DEAD_PATHS.forEach((rel) => {
    it(`${rel} does not exist`, () => {
      expect(fs.existsSync(path.join(CHAT_DIR, rel))).toBe(false);
    });
  });

  // linkDetector.ts was dead too, but Task H2 wired it up as the source of
  // the message bubble's link cards -- it must stay.
  it("keeps utils/linkDetector.ts -- it is live now, not dead", () => {
    expect(fs.existsSync(path.join(CHAT_DIR, "utils/linkDetector.ts"))).toBe(true);
  });
});
