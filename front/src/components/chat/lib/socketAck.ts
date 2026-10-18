/**
 * Emit with an ack and a deadline, without ever giving up on the ack.
 *
 * The backend creates the message BEFORE it acks (socket/socketHandler.js
 * sendMessage), so "no ack yet" never means "not sent". The deadline only
 * changes what the bubble says (failed, with Retry); the ack, whenever it
 * comes, still reconciles it -- `late` tells the caller it already timed out.
 * Nothing here falls back to REST: a second channel for the same text is how
 * the app user got every slow message twice.
 */
export const SOCKET_ACK_TIMEOUT_MS = 10000;

export interface AckHandlers {
  onAck: (response: any, late: boolean) => void;
  onTimeout: () => void;
}

export function emitWithAck(
  socket: { emit: (event: string, payload: any, cb: (r: any) => void) => any },
  event: string,
  payload: any,
  timeoutMs: number,
  handlers: AckHandlers
): void {
  let timedOut = false;
  let acked = false;
  const timer = setTimeout(() => {
    if (acked) return;
    timedOut = true;
    handlers.onTimeout();
  }, timeoutMs);
  socket.emit(event, payload, (response: any) => {
    if (acked) return;
    acked = true;
    clearTimeout(timer);
    handlers.onAck(response, timedOut);
  });
}
