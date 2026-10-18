/**
 * Why a send was refused, in the terms the UI acts on.
 *
 * The backend refuses over three channels with three shapes: the socket ack
 * ({status:'error', error}), the socket `messageSendError` push ({error},
 * burst limiter, no ack) and REST ({status, data:{error, code}}). The text is
 * the contract today (only the conversation cap has a code), so the match is
 * on the server's own wording -- the same order the app uses in
 * chat_conversation_screen.dart _showSendError.
 */
export type SendErrorKind =
  | "rateLimited"
  | "firstChatLimit"
  | "dailyLimit"
  | "conversationCap"
  | "blocked"
  | "generic";

export interface SendError {
  kind: SendErrorKind;
  /** The server's own text, when there was one. */
  detail: string;
}

function textOf(input: any): string {
  if (!input) return "";
  if (typeof input === "string") return input;
  if (input.data && typeof input.data === "object") {
    return String(input.data.error || input.data.message || "");
  }
  return String(input.error || input.message || "");
}

function codeOf(input: any): string {
  if (!input || typeof input !== "object") return "";
  if (input.data && typeof input.data === "object" && input.data.code) return String(input.data.code);
  return input.code ? String(input.code) : "";
}

export function classifySendError(input: any): SendError {
  const detail = textOf(input);
  const text = detail.toLowerCase();
  const code = codeOf(input);

  if (code === "CONVERSATION_START_LIMIT" || text.indexOf("most conversations") > -1) {
    return { kind: "conversationCap", detail };
  }
  if (text.indexOf("too many messages") > -1) return { kind: "rateLimited", detail };
  if (text.indexOf("until they reply") > -1) return { kind: "firstChatLimit", detail };
  if (/daily messages? limit/.test(text)) return { kind: "dailyLimit", detail };
  if (text.indexOf("blocked") > -1 || text.indexOf("cannot send message to this user") > -1) {
    return { kind: "blocked", detail };
  }
  return { kind: "generic", detail };
}
