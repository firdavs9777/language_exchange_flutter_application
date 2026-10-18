import { createLkSession, mediaErrorKind, LkPeer } from "./lkSession";
import {
  fakeRoom,
  failNextMedia,
  resetFakeLivekit,
  setFakeDefaults,
  fakeRemote,
  fakeTrack,
  RoomEvent,
  DisconnectReason,
} from "./testing/fakeLivekit";

jest.mock("./livekitLoader", () => require("./testing/fakeLivekit").loaderMock());

beforeEach(() => {
  resetFakeLivekit();
  document.body.innerHTML = "";
});

describe("mediaErrorKind", () => {
  it.each([
    ["NotAllowedError", "denied"],
    ["SecurityError", "denied"],
    ["PermissionDeniedError", "denied"],
    ["NotFoundError", "unavailable"],
    ["DevicesNotFoundError", "unavailable"],
    ["OverconstrainedError", "unavailable"],
    ["NotReadableError", "unavailable"],
    ["TrackStartError", "unavailable"],
    ["AbortError", "error"],
  ])("%s -> %s", (name, kind) => {
    expect(mediaErrorKind({ name })).toBe(kind);
  });
  it("reads a wrapped DOMException and survives junk", () => {
    expect(mediaErrorKind({ error: { name: "NotAllowedError" } })).toBe("denied");
    expect(mediaErrorKind(undefined)).toBe("error");
    expect(mediaErrorKind("boom")).toBe("error");
  });
});

function harness() {
  const events = {
    peers: [] as LkPeer[][],
    states: [] as string[],
    disconnected: [] as string[],
    blocked: [] as boolean[],
    video: [] as Array<[string, boolean]>,
  };
  const session = createLkSession({
    onPeers: (p) => events.peers.push(p),
    onState: (s) => events.states.push(s),
    onDisconnected: (r) => events.disconnected.push(r),
    onAudioBlocked: (b) => events.blocked.push(b),
    onRemoteVideo: (id, track) => events.video.push([id, !!track]),
  });
  return { session, events };
}

it("connects as a listener: no mic published, peers reported, adaptive stream on", async () => {
  const { session, events } = harness();
  const result = await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  expect(result).toBe("ok");
  const room = fakeRoom();
  expect(room.connect).toHaveBeenCalledWith("wss://lk.test", "tok");
  expect(room.options).toEqual({ adaptiveStream: true, dynacast: true });
  expect(room.localParticipant.setMicrophoneEnabled).not.toHaveBeenCalled();
  expect(events.states).toEqual(["connecting", "connected"]);
  expect(session.peers().map((p) => p.identity)).toEqual(["me"]);
  room.addRemote(fakeRemote("u2", { name: "Ana", micOn: true }));
  const last = events.peers[events.peers.length - 1];
  expect(last).toEqual([
    expect.objectContaining({ identity: "me", isLocal: true, micOn: false }),
    expect.objectContaining({ identity: "u2", name: "Ana", isLocal: false, micOn: true }),
  ]);
});

it("a denied mic resolves 'denied' and the session stays connected", async () => {
  const { session, events } = harness();
  failNextMedia("NotAllowedError");
  expect(await session.connect("wss://lk.test", "tok", { mic: true, camera: false })).toBe("denied");
  expect(events.states).toEqual(["connecting", "connected"]);
  expect(await session.setMic(true)).toBe("ok");
  expect(fakeRoom().localParticipant.isMicrophoneEnabled).toBe(true);
});

it("a missing camera resolves 'unavailable' but keeps the mic", async () => {
  const { session } = harness();
  await session.connect("wss://lk.test", "tok", { mic: true, camera: false });
  failNextMedia("NotFoundError");
  expect(await session.setCamera(true)).toBe("unavailable");
  expect(fakeRoom().localParticipant.isMicrophoneEnabled).toBe(true);
  expect(fakeRoom().localParticipant.isCameraEnabled).toBe(false);
});

it("rejects when the room connection itself fails, and says disconnected", async () => {
  setFakeDefaults({ connectError: new Error("invalid token") });
  const { session, events } = harness();
  await expect(session.connect("wss://lk.test", "bad", { mic: false, camera: false })).rejects.toThrow("invalid token");
  expect(events.states).toEqual(["connecting", "disconnected"]);
  expect(session.peers()).toEqual([]);
});

it("reports blocked audio after connect and clears it on startAudio (Safari autoplay)", async () => {
  setFakeDefaults({ canPlaybackAudio: false });
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  expect(events.blocked).toEqual([true]);
  expect(await session.startAudio()).toBe(true);
  expect(events.blocked[events.blocked.length - 1]).toBe(false);
});

it("plays remote audio through a hidden element and removes it on unsubscribe", async () => {
  const { session } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  const room = fakeRoom();
  const p = fakeRemote("u2");
  const audio = fakeTrack("audio", "a1");
  room.emit(RoomEvent.TrackSubscribed, audio, {}, p);
  expect(document.body.querySelectorAll("audio")).toHaveLength(1);
  room.emit(RoomEvent.TrackUnsubscribed, audio, {}, p);
  expect(document.body.querySelectorAll("audio")).toHaveLength(0);
});

it("hands remote video to onRemoteVideo and takes it back", async () => {
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  const room = fakeRoom();
  const p = fakeRemote("u2");
  const video = fakeTrack("video", "v1");
  room.emit(RoomEvent.TrackSubscribed, video, {}, p);
  room.emit(RoomEvent.TrackUnsubscribed, video, {}, p);
  expect(events.video).toEqual([
    ["u2", true],
    ["u2", false],
  ]);
});

it("exposes the local camera track once published", async () => {
  const { session } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  expect(session.localVideo()).toBe(null);
  expect(await session.setCamera(true)).toBe("ok");
  const el = document.createElement("video");
  const track = session.localVideo();
  expect(track).not.toBe(null);
  track!.attach(el);
  expect(fakeRoom().localParticipant.cameraTrack.attach).toHaveBeenCalledWith(el);
});

it("maps reconnect states", async () => {
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  fakeRoom().emit(RoomEvent.Reconnecting);
  fakeRoom().emit(RoomEvent.Reconnected);
  expect(events.states).toEqual(["connecting", "connected", "reconnecting", "connected"]);
});

it.each([
  [DisconnectReason.DUPLICATE_IDENTITY, "duplicate_identity"],
  [DisconnectReason.ROOM_DELETED, "room_deleted"],
  [DisconnectReason.ROOM_CLOSED, "room_deleted"],
  [DisconnectReason.PARTICIPANT_REMOVED, "participant_removed"],
  [DisconnectReason.SERVER_SHUTDOWN, "server_shutdown"],
  [DisconnectReason.SIGNAL_CLOSE, "network"],
  [DisconnectReason.JOIN_FAILURE, "network"],
  [DisconnectReason.CONNECTION_TIMEOUT, "network"],
  [undefined, "unknown"],
])("server-side disconnect %s -> %s, and remote audio is cleaned up", async (reason, name) => {
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: false, camera: false });
  fakeRoom().emit(RoomEvent.TrackSubscribed, fakeTrack("audio"), {}, fakeRemote("u2"));
  fakeRoom().emit(RoomEvent.Disconnected, reason);
  expect(events.disconnected).toEqual([name]);
  expect(events.states[events.states.length - 1]).toBe("disconnected");
  expect(document.body.querySelectorAll("audio")).toHaveLength(0);
  expect(session.peers()).toEqual([]);
});

it("disconnect() always reports 'client', once", async () => {
  const { session, events } = harness();
  await session.connect("wss://lk.test", "tok", { mic: true, camera: false });
  await session.disconnect();
  await session.disconnect();
  expect(events.disconnected).toEqual(["client"]);
});

it("media calls before connect are an error, not a crash", async () => {
  const { session } = harness();
  expect(await session.setMic(true)).toBe("error");
  expect(await session.startAudio()).toBe(false);
  await session.disconnect();
});
