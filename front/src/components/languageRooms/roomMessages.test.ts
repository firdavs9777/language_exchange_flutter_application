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
