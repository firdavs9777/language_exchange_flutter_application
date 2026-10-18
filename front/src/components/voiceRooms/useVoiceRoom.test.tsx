import React from "react";
import { render, act, waitFor } from "@testing-library/react";
import { useVoiceRoom, UseVoiceRoom } from "./useVoiceRoom";
import { fakeRoom, failNextMedia, resetFakeLivekit, RoomEvent, DisconnectReason } from "../../lib/livekit/testing/fakeLivekit";

jest.mock("../../lib/livekit/livekitLoader", () => require("../../lib/livekit/testing/fakeLivekit").loaderMock());

// ---- socket fake -----------------------------------------------------------
type H = (...a: any[]) => void;
const handlers: { [e: string]: H[] } = {};
const emitted: Array<[string, any]> = [];
let rejoinAck: any = { ok: true, ended: false, currentHostId: "h1" };
const mockSocket = {
  connected: true,
  on: (e: string, h: H) => ((handlers[e] = handlers[e] || []).push(h)),
  off: (e: string, h: H) => (handlers[e] = (handlers[e] || []).filter((x) => x !== h)),
  emit: (e: string, p: any, cb?: (r: any) => void) => {
    emitted.push([e, p]);
    if (e === "voiceroom:rejoin" && cb) cb(rejoinAck);
  },
};
const serverSays = (e: string, p: any) => act(() => (handlers[e] || []).slice().forEach((h) => h(p)));
let mockEpoch = 0;
jest.mock("../chat/hooks/useSocket", () => ({
  useSocket: () => ({ socket: mockSocket, isConnected: true, emit: jest.fn(), connectionEpoch: mockEpoch, kicked: false, reconnect: jest.fn() }),
}));

// ---- REST fakes -------------------------------------------------------------
const ok = (data: any) => ({ unwrap: () => Promise.resolve(data) });
const mockJoin = jest.fn(() => ok({ success: true }));
const mockToken = jest.fn(() => ok({ token: "tok", url: "wss://lk.test", roomName: "r1", role: "participant" }));
const mockLeave = jest.fn(() => ok({}));
const mockEnd = jest.fn(() => ok({}));
const mockPromote = jest.fn(() => ok({}));
// One object, like RTK Query's referentially stable `data`: a fresh literal per
// render would re-seed the reducer on every render, forever.
const mockDetail = { _id: "r1", host: { _id: "h1", name: "Mina" }, participants: [{ user: { _id: "h1", name: "Mina" }, role: "host" }] };
jest.mock("../../store/slices/voiceRoomsSlice", () => ({
  useGetVoiceRoomQuery: () => ({
    data: mockDetail,
    refetch: jest.fn(),
  }),
  useJoinVoiceRoomMutation: () => [mockJoin],
  useGetVoiceRoomTokenMutation: () => [mockToken],
  useLeaveVoiceRoomMutation: () => [mockLeave],
  useEndVoiceRoomMutation: () => [mockEnd],
  usePromoteVoiceParticipantMutation: () => [mockPromote],
  voiceRoomErrorText: () => "This room is full.",
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

let api: UseVoiceRoom;
function Probe() {
  api = useVoiceRoom("r1", "me");
  return null;
}

beforeEach(() => {
  resetFakeLivekit();
  Object.keys(handlers).forEach((k) => delete handlers[k]);
  emitted.length = 0;
  mockEpoch = 0;
  rejoinAck = { ok: true, ended: false, currentHostId: "h1" };
  jest.clearAllMocks();
  // CRA sets resetMocks: true, so the implementations go here, not at module level.
  mockJoin.mockImplementation(() => ok({ success: true }));
  mockToken.mockImplementation(() => ok({ token: "tok", url: "wss://lk.test", roomName: "r1", role: "participant" }));
  mockLeave.mockImplementation(() => ok({}));
  mockEnd.mockImplementation(() => ok({}));
  mockPromote.mockImplementation(() => ok({}));
  jest.useFakeTimers();
});
afterEach(() => jest.useRealTimers());

async function joinRoom() {
  const view = render(<Probe />);
  await act(async () => {
    await api.join();
  });
  return view;
}

it("joins in the app's order, enters muted, and heartbeats every 30 s", async () => {
  await joinRoom();
  expect(mockJoin).toHaveBeenCalledWith("r1");
  expect(mockToken).toHaveBeenCalledWith("r1");
  expect(emitted[0]).toEqual(["voiceroom:join", { roomId: "r1" }]);
  expect(fakeRoom().connect).toHaveBeenCalledWith("wss://lk.test", "tok");
  expect(fakeRoom().localParticipant.setMicrophoneEnabled).not.toHaveBeenCalled();
  expect(api.phase).toBe("live");
  expect(api.role).toBe("participant");
  expect(api.micOn).toBe(false);
  act(() => {
    jest.advanceTimersByTime(30000);
  });
  expect(emitted.filter(([e]) => e === "voiceroom:heartbeat")).toEqual([["voiceroom:heartbeat", { roomId: "r1" }]]);
});

it("a refused join shows the reason and never mints a token", async () => {
  mockJoin.mockReturnValueOnce({ unwrap: () => Promise.reject({ status: 400, data: { error: "Room is full" } }) } as any);
  await joinRoom();
  expect(api.phase).toBe("error");
  expect(api.error).toBe("This room is full.");
  expect(mockToken).not.toHaveBeenCalled();
});

it("taking the mic publishes and tells the room; a denied mic says why and keeps listening", async () => {
  await joinRoom();
  await act(async () => {
    await api.setMic(true);
  });
  expect(api.micOn).toBe(true);
  expect(emitted).toContainEqual(["voiceroom:mute", { roomId: "r1", isMuted: false }]);
  await act(async () => {
    await api.setMic(false);
  });
  failNextMedia("NotAllowedError");
  await act(async () => {
    await api.setMic(true);
  });
  expect(api.micOn).toBe(false);
  expect(api.micProblem).toBe("denied");
  expect(api.phase).toBe("live");
});

it("raising a hand uses the backend's event name; taking the mic lowers it", async () => {
  await joinRoom();
  act(() => api.raiseHand(true));
  expect(emitted).toContainEqual(["voiceroom:raise_hand", { roomId: "r1", isRaised: true }]);
  expect(api.handRaised).toBe(true);
  await act(async () => {
    await api.setMic(true);
  });
  expect(emitted).toContainEqual(["voiceroom:raise_hand", { roomId: "r1", isRaised: false }]);
  expect(api.handRaised).toBe(false);
});

it("a forced mute from the host turns my mic off", async () => {
  await joinRoom();
  await act(async () => {
    await api.setMic(true);
  });
  serverSays("voiceroom:mute", { roomId: "r1", userId: "me", isMuted: true, forced: true });
  await waitFor(() => expect(api.micOn).toBe(false));
  expect(fakeRoom().localParticipant.isMicrophoneEnabled).toBe(false);
});

it("room ended by the server ends the session", async () => {
  await joinRoom();
  serverSays("voiceroom:ended", { roomId: "r1" });
  await waitFor(() => expect(api.phase).toBe("ended"));
  expect(fakeRoom().disconnect).toHaveBeenCalled();
});

it("ignores events for another room", async () => {
  await joinRoom();
  serverSays("voiceroom:ended", { roomId: "other" });
  expect(api.phase).toBe("live");
});

it("the same account joining from another tab parks this one", async () => {
  await joinRoom();
  act(() => {
    fakeRoom().emit(RoomEvent.Disconnected, DisconnectReason.DUPLICATE_IDENTITY);
  });
  expect(api.phase).toBe("elsewhere");
});

it("a dropped LiveKit connection becomes 'lost' (Rejoin offered), not a loop", async () => {
  await joinRoom();
  act(() => {
    fakeRoom().emit(RoomEvent.Disconnected, DisconnectReason.SIGNAL_CLOSE);
  });
  expect(api.phase).toBe("lost");
  expect(mockJoin).toHaveBeenCalledTimes(1);
});

it("rejoins over the socket after a reconnect and follows the host", async () => {
  const view = await joinRoom();
  rejoinAck = { ok: true, ended: false, currentHostId: "me", youArePromoted: true };
  mockEpoch = 1;
  view.rerender(<Probe />);
  await waitFor(() => expect(api.hostId).toBe("me"));
  expect(emitted.map(([e]) => e)).toContain("voiceroom:rejoin");
});

it("a rejoin ack saying the room ended ends it", async () => {
  const view = await joinRoom();
  rejoinAck = { ok: false, ended: true };
  mockEpoch = 2;
  view.rerender(<Probe />);
  await waitFor(() => expect(api.phase).toBe("ended"));
});

it("leaves over the socket and REST and disconnects; unmount while live leaves too", async () => {
  const view = await joinRoom();
  await act(async () => {
    await api.leave();
  });
  expect(emitted).toContainEqual(["voiceroom:leave", { roomId: "r1" }]);
  expect(mockLeave).toHaveBeenCalledWith("r1");
  expect(api.phase).toBe("idle");
  await act(async () => {
    await api.join();
  });
  emitted.length = 0;
  view.unmount();
  expect(emitted).toContainEqual(["voiceroom:leave", { roomId: "r1" }]);
});

it("host tools: mute all over the socket, promote and end over REST", async () => {
  mockToken.mockReturnValueOnce(ok({ token: "tok", url: "wss://lk.test", roomName: "r1", role: "host" }) as any);
  await joinRoom();
  act(() => api.muteAll());
  expect(emitted).toContainEqual(["voiceroom:mute-all", { roomId: "r1" }]);
  await act(async () => {
    await api.promote("u2");
  });
  expect(mockPromote).toHaveBeenCalledWith({ roomId: "r1", userId: "u2" });
  await act(async () => {
    await api.endRoom();
  });
  expect(emitted).toContainEqual(["voiceroom:end-intent", { roomId: "r1" }]);
  expect(mockEnd).toHaveBeenCalledWith("r1");
  expect(api.phase).toBe("ended");
});

it("sends trimmed chat, capped at 500 characters", async () => {
  await joinRoom();
  act(() => api.sendChat("  hi  "));
  act(() => api.sendChat("   "));
  act(() => api.sendChat("x".repeat(600)));
  const chats = emitted.filter(([e]) => e === "voiceroom:chat").map(([, p]) => p.message);
  expect(chats).toEqual(["hi", "x".repeat(500)]);
});
