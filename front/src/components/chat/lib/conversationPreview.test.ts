import { previewOf } from "./conversationPreview";

const t = () => "";

it.each([
  [{ message: "hi", messageType: "text" }, "hi"],
  [{ message: "Conversation started" }, ""],
  [{ messageType: "voice", message: "" }, "🎤 Voice message"],
  [{ messageType: "media", media: { type: "image" } }, "🖼️ Photo"],
  [{ messageType: "media", media: { type: "video" } }, "🎥 Video"],
  [{ messageType: "media", media: { type: "document" } }, "📎 File"],
  [{ messageType: "media" }, "📎 Attachment"],
  [{ messageType: "call", media: { type: "call" } }, "📞 Call"],
  [{ messageType: "call" }, "📞 Call"],
  [{ messageType: "location" }, "📍 Location"],
  [{ messageType: "location", media: { type: "location" } }, "📍 Location"],
  [{ messageType: "gif", message: "https://media.giphy.com/x.gif" }, "GIF"],
  [{ messageType: "sticker", message: "👋" }, "👋"],
  [{ messageType: "story_share", message: "Shared a story" }, "📖 Story"],
  [{ messageType: "poll", message: "" }, "📊 Poll"],
  [null, ""],
  [undefined, ""],
])("%j -> %s", (msg: any, expected: string) => {
  expect(previewOf(msg, t)).toBe(expected);
});

it("prefers the translation when there is one", () => {
  const tr = (key: string) => (key === "chatPage.preview.voice" ? "🎤 Sprachnachricht" : "");
  expect(previewOf({ messageType: "voice" }, tr)).toBe("🎤 Sprachnachricht");
});

it("shows a caption under a photo when the message has one (legacy media rows)", () => {
  expect(previewOf({ messageType: "media", media: { type: "image" }, message: "look" }, t)).toBe("🖼️ look");
});
