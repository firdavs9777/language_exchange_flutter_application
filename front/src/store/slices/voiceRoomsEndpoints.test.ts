import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { voiceRoomsApiSlice, VOICE_ROOMS_URL, voiceRoomErrorText } from "./voiceRoomsSlice";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: null }) => state,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; body: string | undefined };

function mockFetch(payload: any = { success: true, data: {} }): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify(payload), { status: 200, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const ep = (name: string) => (voiceRoomsApiSlice.endpoints as any)[name];

it("lists live rooms by default and passes status/language/page", async () => {
  const calls = mockFetch({ success: true, data: [], pagination: { hasMore: false } });
  const store = makeStore();
  await store.dispatch(ep("getVoiceRooms").initiate({}));
  await store.dispatch(ep("getVoiceRooms").initiate({ status: "scheduled", language: "Korean", page: 2 }));
  const first = new URL(calls[0].url);
  expect(first.pathname).toBe(VOICE_ROOMS_URL);
  expect(first.searchParams.get("status")).toBe(null);
  expect(first.searchParams.get("page")).toBe("1");
  const second = new URL(calls[1].url);
  expect(second.searchParams.get("status")).toBe("scheduled");
  expect(second.searchParams.get("language")).toBe("Korean");
  expect(second.searchParams.get("page")).toBe("2");
});

it.each([
  ["joinVoiceRoom", "r1", "POST", "/r1/join"],
  ["getVoiceRoomToken", "r1", "POST", "/r1/token"],
  ["leaveVoiceRoom", "r1", "POST", "/r1/leave"],
  ["endVoiceRoom", "r1", "POST", "/r1/end"],
])("%s -> %s %s", async (name, arg, method, suffix) => {
  const calls = mockFetch();
  await makeStore().dispatch(ep(name).initiate(arg));
  expect(calls[0].method).toBe(method);
  expect(new URL(calls[0].url).pathname).toBe(`${VOICE_ROOMS_URL}${suffix}`);
});

it("creates with the app's body and drops empty optional fields", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(
    ep("createVoiceRoom").initiate({
      title: "Evening Korean",
      description: "",
      topic: "language_exchange",
      language: "Korean",
      maxParticipants: 8,
      category: "language_practice",
      scheduledFor: undefined,
    })
  );
  expect(calls[0].method).toBe("POST");
  expect(new URL(calls[0].url).pathname).toBe(VOICE_ROOMS_URL);
  expect(JSON.parse(calls[0].body as string)).toEqual({
    title: "Evening Korean",
    topic: "language_exchange",
    language: "Korean",
    maxParticipants: 8,
    category: "language_practice",
  });
});

it("promotes with PUT /:id/promote/:userId and RSVPs with POST/DELETE", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("promoteVoiceParticipant").initiate({ roomId: "r1", userId: "u9" }));
  await store.dispatch(ep("rsvpVoiceRoom").initiate({ roomId: "r1", going: true }));
  await store.dispatch(ep("rsvpVoiceRoom").initiate({ roomId: "r1", going: false }));
  expect([calls[0].method, new URL(calls[0].url).pathname]).toEqual(["PUT", `${VOICE_ROOMS_URL}/r1/promote/u9`]);
  expect([calls[1].method, new URL(calls[1].url).pathname]).toEqual(["POST", `${VOICE_ROOMS_URL}/r1/rsvp`]);
  expect([calls[2].method, new URL(calls[2].url).pathname]).toEqual(["DELETE", `${VOICE_ROOMS_URL}/r1/rsvp`]);
});

describe("voiceRoomErrorText", () => {
  const t = () => "";
  it.each([
    [{ status: 400, data: { error: "Room is full" } }, "This room is full."],
    [{ status: 400, data: { error: "This room has ended" } }, "This room has ended."],
    [{ status: 403, data: { error: "You cannot join this room" } }, "You can't join this room."],
    [
      { status: 403, data: { error: "Voice rooms are not available for your account type. Upgrade to create voice rooms." } },
      "Creating voice rooms needs a VIP plan.",
    ],
    [{ status: 404, data: { error: "Voice room not found" } }, "This room is no longer available."],
    [{ status: 500, data: { error: "Mongo exploded" } }, "Something went wrong. Try again."],
    [undefined, "Something went wrong. Try again."],
  ])("%j", (err, text) => {
    expect(voiceRoomErrorText(err, t)).toBe(text);
  });
});
