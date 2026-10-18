import { mergeMessages, messageLabel } from "./roomMessages";

const m = (id: string, at: string, extra: any = {}) => Object.assign({ _id: id, createdAt: at, message: id, messageType: "text" }, extra);

it("dedupes by id and keeps chronological order across pages and live events", () => {
  const page1 = [m("b", "2026-10-16T10:01:00Z"), m("c", "2026-10-16T10:02:00Z")];
  const older = [m("a", "2026-10-16T10:00:00Z"), m("b", "2026-10-16T10:01:00Z")];
  const live = [m("c", "2026-10-16T10:02:00Z"), m("d", "2026-10-16T10:03:00Z")];
  expect(mergeMessages(mergeMessages(page1, older), live).map((x) => x._id)).toEqual(["a", "b", "c", "d"]);
});

it("labels kinds the web does not draw instead of showing nothing", () => {
  const t = () => "";
  expect(messageLabel(m("x", "2026", { message: "hola" }), t)).toBe("hola");
  expect(messageLabel(m("x", "2026", { messageType: "voice", message: "" }), t)).toBe("Voice message — open the app to listen");
  expect(messageLabel(m("x", "2026", { messageType: "media", message: "" }), t)).toBe("Photo or video — open the app to see it");
  expect(messageLabel(m("x", "2026", { messageType: "sticker", message: "" }), t)).toBe("Sticker");
  expect(messageLabel(m("x", "2026", { messageType: "poll", message: "" }), t)).toBe("Open the app to see this message");
});

describe("room thread helpers", () => {
  const {
    applyReactionUpdate,
    removeMessage,
    withoutBlocked,
    splitDailyPrompt,
    canDeleteMessage,
    replyPreview,
  } = require("./roomMessages");
  const list = [
    m("a", "2026-10-16T10:00:00Z", { sender: { _id: "u1" } }),
    m("p", "2026-10-16T10:01:00Z", { messageType: "system", promptId: "q1", message: "What did you eat?" }),
    m("j", "2026-10-16T10:02:00Z", { messageType: "system", message: "Ana joined" }),
    m("b", "2026-10-16T10:03:00Z", { sender: { _id: "u2" } }),
  ];

  it("applies a reaction update only to the matching message", () => {
    const next = applyReactionUpdate(list, { messageId: "b", reactions: [{ user: "u1", emoji: "👍" }] });
    expect(next.find((x: any) => x._id === "b").reactions).toEqual([{ user: "u1", emoji: "👍" }]);
    expect(applyReactionUpdate(list, { messageId: "zzz", reactions: [] })).toBe(list);
  });

  it("removes deleted messages and hides blocked senders", () => {
    expect(removeMessage(list, "a").map((x: any) => x._id)).toEqual(["p", "j", "b"]);
    expect(withoutBlocked(list, ["u2"]).map((x: any) => x._id)).toEqual(["a", "p", "j"]);
    expect(withoutBlocked(list, [])).toBe(list);
  });

  it("pins the newest daily prompt and keeps other system lines inline", () => {
    const { prompt, thread } = splitDailyPrompt(list);
    expect(prompt._id).toBe("p");
    expect(thread.map((x: any) => x._id)).toEqual(["a", "j", "b"]);
    expect(splitDailyPrompt([list[0]]).prompt).toBeNull();
  });

  it("lets the sender or a moderator delete, never a system line", () => {
    expect(canDeleteMessage(list[0], "u1", false)).toBe(true);
    expect(canDeleteMessage(list[0], "u2", false)).toBe(false);
    expect(canDeleteMessage(list[0], "u2", true)).toBe(true);
    expect(canDeleteMessage(list[2], "u2", true)).toBe(false);
  });

  it("previews a quoted text, photo or removed message", () => {
    const t = () => "";
    expect(replyPreview({ message: "hola" }, t)).toBe("hola");
    expect(replyPreview({ media: { url: "x.jpg" } }, t)).toBe("Photo");
    expect(replyPreview({ isDeleted: true }, t)).toBe("Message removed");
  });

  it("drops server-deleted messages when merging", () => {
    expect(mergeMessages([m("a", "2026")], [m("b", "2026", { isDeleted: true })]).map((x) => x._id)).toEqual(["a"]);
  });
});

describe("roomLanguageName", () => {
  const { roomLanguageName } = require("./roomLanguages");
  it("names a code in the reader's language and falls back to the code", () => {
    expect(roomLanguageName("ko", "en")).toBe("Korean");
    expect(roomLanguageName("", "en")).toBe("");
    expect(roomLanguageName("qqq", "en")).toBe("qqq");
  });
});
