import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "./socketAck";

beforeEach(() => jest.useFakeTimers());
afterEach(() => jest.useRealTimers());

function socketThatAcks(after: number | null, response: any = { status: "success", message: { _id: "m1" } }) {
  return {
    emit: jest.fn((_e: string, _p: any, cb: (r: any) => void) => {
      if (after !== null) setTimeout(() => cb(response), after);
    }),
  };
}

it("answers onAck when the ack is in time", () => {
  const onAck = jest.fn();
  const onTimeout = jest.fn();
  emitWithAck(socketThatAcks(100) as any, "sendMessage", { a: 1 }, 1000, { onAck, onTimeout });
  jest.advanceTimersByTime(100);
  expect(onAck).toHaveBeenCalledWith({ status: "success", message: { _id: "m1" } }, false);
  jest.advanceTimersByTime(5000);
  expect(onTimeout).not.toHaveBeenCalled();
});

it("times out, then still delivers a late ack flagged late", () => {
  const onAck = jest.fn();
  const onTimeout = jest.fn();
  emitWithAck(socketThatAcks(3000) as any, "sendMessage", {}, 1000, { onAck, onTimeout });
  jest.advanceTimersByTime(1000);
  expect(onTimeout).toHaveBeenCalledTimes(1);
  jest.advanceTimersByTime(2000);
  expect(onAck).toHaveBeenCalledWith(expect.anything(), true);
});

it("never calls onTimeout twice or after an ack", () => {
  const onTimeout = jest.fn();
  emitWithAck(socketThatAcks(null) as any, "sendMessage", {}, 1000, { onAck: jest.fn(), onTimeout });
  jest.advanceTimersByTime(10000);
  expect(onTimeout).toHaveBeenCalledTimes(1);
});

it("waits 10 s by default", () => {
  expect(SOCKET_ACK_TIMEOUT_MS).toBe(10000);
});
