import { voiceRoomReducer, initialVoiceRoomState, selectMembers } from "./voiceRoomState";

const detail = {
  host: { _id: "h1", name: "Mina", images: ["a.jpg"] },
  participants: [
    { user: { _id: "h1", name: "Mina", images: ["a.jpg"] }, role: "host", isMuted: false },
    { user: { _id: "u2", name: "Ana" }, role: "listener", isMuted: true },
  ],
};

it("seeds from the room detail, host first", () => {
  const s = voiceRoomReducer(initialVoiceRoomState, { type: "detail", room: detail });
  expect(s.hostId).toBe("h1");
  expect(selectMembers(s, []).map((m) => [m.userId, m.role, m.isMuted])).toEqual([
    ["h1", "host", false],
    ["u2", "listener", true],
  ]);
});

it("adds a joiner with or without a populated user, and removes a leaver", () => {
  let s = voiceRoomReducer(initialVoiceRoomState, { type: "detail", room: detail });
  s = voiceRoomReducer(s, { type: "joined", payload: { user: { _id: "u3", name: "Sam" } } });
  s = voiceRoomReducer(s, { type: "joined", payload: { userId: "u4" } });
  expect(selectMembers(s, []).map((m) => m.userId)).toEqual(["h1", "u2", "u3", "u4"]);
  s = voiceRoomReducer(s, { type: "left", payload: { userId: "u2", roomEnded: false } });
  expect(selectMembers(s, []).map((m) => m.userId)).toEqual(["h1", "u3", "u4"]);
  expect(s.ended).toBe(false);
  s = voiceRoomReducer(s, { type: "left", payload: { userId: "h1", roomEnded: true } });
  expect(s.ended).toBe(true);
});

it("tracks mute and raised hands; a joiner that left loses the hand", () => {
  let s = voiceRoomReducer(initialVoiceRoomState, { type: "detail", room: detail });
  s = voiceRoomReducer(s, { type: "hand", payload: { userId: "u2", isRaised: true, user: { _id: "u2", name: "Ana" } } });
  s = voiceRoomReducer(s, { type: "mute", payload: { userId: "h1", isMuted: true } });
  const m = selectMembers(s, []);
  expect(m.find((x) => x.userId === "u2")!.handRaised).toBe(true);
  expect(m.find((x) => x.userId === "h1")!.isMuted).toBe(true);
});

it("LiveKit is the truth for speaking and mic once connected", () => {
  const s = voiceRoomReducer(initialVoiceRoomState, { type: "detail", room: detail });
  const m = selectMembers(s, [
    { identity: "u2", name: "Ana", isLocal: false, isSpeaking: true, micOn: true, cameraOn: false, metadata: "" },
  ]);
  const ana = m.find((x) => x.userId === "u2")!;
  expect(ana.isSpeaking).toBe(true);
  expect(ana.isMuted).toBe(false);
});

it("keeps the last 200 chat lines and changes host", () => {
  let s = initialVoiceRoomState;
  for (let i = 0; i < 205; i += 1) {
    s = voiceRoomReducer(s, { type: "chat", payload: { message: `m${i}`, user: { _id: "u2", name: "Ana" }, timestamp: "2026-10-16T10:00:00Z" } });
  }
  expect(s.chat).toHaveLength(200);
  expect(s.chat[0].message).toBe("m5");
  s = voiceRoomReducer(s, { type: "host", hostId: "u2" });
  expect(s.hostId).toBe("u2");
});
