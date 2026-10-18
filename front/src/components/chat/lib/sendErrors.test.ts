import { classifySendError } from "./sendErrors";

const rest = (status: number, error: string, code?: string) => ({
  status,
  data: { success: false, error, ...(code ? { code } : {}) },
});

it.each([
  [{ status: "error", error: "You can only send 5 messages until they reply. Please wait for a response." }, "firstChatLimit"],
  [rest(429, "You can only send 5 messages until they reply. Please wait for a response."), "firstChatLimit"],
  [{ status: "error", error: "Daily message limit exceeded. Used 20/20. Resets at 10/17/2026, 12:00:00 AM." }, "dailyLimit"],
  [rest(429, "Daily messages limit exceeded. You have used 20 of 20 messages today. Limit resets at midnight."), "dailyLimit"],
  [rest(403, "You have started the most conversations you can today. Watch an ad for one more, or go VIP to start as many as you want.", "CONVERSATION_START_LIMIT"), "conversationCap"],
  [{ status: "error", error: "You have started the most conversations you can today. Watch an ad for one more, or go VIP to start as many as you want." }, "conversationCap"],
  [{ status: "error", error: "Cannot send message to blocked user" }, "blocked"],
  [rest(403, "Cannot send message to this user"), "blocked"],
  [{ error: "Too many messages — slow down." }, "rateLimited"],
  [rest(500, "Server error"), "generic"],
  [undefined, "generic"],
  [new Error("Failed to fetch"), "generic"],
])("classifies %j as %s", (input: any, kind: string) => {
  expect(classifySendError(input).kind).toBe(kind);
});

it("keeps the server text as detail (the first-chat line names the number)", () => {
  expect(
    classifySendError({ status: "error", error: "You can only send 5 messages until they reply. Please wait for a response." }).detail
  ).toContain("5 messages");
});

it("prefers the machine code over the text", () => {
  expect(classifySendError(rest(403, "anything", "CONVERSATION_START_LIMIT")).kind).toBe("conversationCap");
});
