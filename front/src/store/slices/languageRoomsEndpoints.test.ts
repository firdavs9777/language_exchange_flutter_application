import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import {
  languageRoomsApiSlice,
  LANGUAGE_ROOMS_URL,
  languageRoomErrorText,
  groupRoomsByLanguage,
} from "./languageRoomsSlice";

function makeStore() {
  return configureStore({
    reducer: { [apiSlice.reducerPath]: apiSlice.reducer, auth: (s: any = { userInfo: null }) => s },
    middleware: (g) => g().concat(apiSlice.middleware),
  });
}
type Captured = { url: string; method: string; body: string | undefined };
function mockFetch(): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify({ success: true, data: [] }), { status: 200, headers: { "content-type": "application/json" } });
  });
  return calls;
}
const ep = (n: string) => (languageRoomsApiSlice.endpoints as any)[n];
const path = (c: Captured) => new URL(c.url).pathname;

it.each([
  ["joinLanguageRoom", "r1", "POST", "/r1/join"],
  ["leaveLanguageRoom", "r1", "POST", "/r1/leave"],
  ["requestJoinLanguageRoom", "r1", "POST", "/r1/request-join"],
])("%s", async (name, arg, method, suffix) => {
  const calls = mockFetch();
  await makeStore().dispatch(ep(name).initiate(arg));
  expect([calls[0].method, path(calls[0])]).toEqual([method, `${LANGUAGE_ROOMS_URL}${suffix}`]);
});

it("creates a topic room with the app's body", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(ep("createTopicRoom").initiate({ title: " K-drama talk ", targetLanguage: "ko", description: "" }));
  expect([calls[0].method, path(calls[0])]).toEqual(["POST", LANGUAGE_ROOMS_URL]);
  expect(JSON.parse(calls[0].body as string)).toEqual({ title: "K-drama talk", targetLanguage: "ko", description: "" });
});

it("pages messages and decides requests", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("getLanguageRoomMessages").initiate({ roomId: "r1", page: 2 }));
  await store.dispatch(ep("decideLanguageRoomRequest").initiate({ roomId: "r1", userId: "u2", approve: true }));
  await store.dispatch(ep("decideLanguageRoomRequest").initiate({ roomId: "r1", userId: "u3", approve: false }));
  await store.dispatch(ep("removeLanguageRoomMember").initiate({ roomId: "r1", userId: "u4" }));
  const m = new URL(calls[0].url);
  expect(m.pathname).toBe(`${LANGUAGE_ROOMS_URL}/r1/messages`);
  expect(m.searchParams.get("page")).toBe("2");
  expect(m.searchParams.get("limit")).toBe("50");
  expect([calls[1].method, path(calls[1])]).toEqual(["POST", `${LANGUAGE_ROOMS_URL}/r1/requests/u2/approve`]);
  expect([calls[2].method, path(calls[2])]).toEqual(["POST", `${LANGUAGE_ROOMS_URL}/r1/requests/u3/deny`]);
  expect([calls[3].method, path(calls[3])]).toEqual(["DELETE", `${LANGUAGE_ROOMS_URL}/r1/members/u4`]);
});

it("groups hubs and topic rooms under their language, in server order", () => {
  const rooms: any[] = [
    { _id: "h-ko", roomType: "hub", targetLanguage: "ko", title: "Korean" },
    { _id: "t1", roomType: "topic", targetLanguage: "es", title: "Travel" },
    { _id: "t2", roomType: "topic", targetLanguage: "ko", title: "K-drama" },
    { _id: "h-es", roomType: "hub", targetLanguage: "es", title: "Spanish" },
  ];
  const groups = groupRoomsByLanguage(rooms);
  expect(groups.map((g) => [g.language, g.hub && g.hub._id, g.topics.map((t) => t._id)])).toEqual([
    ["ko", "h-ko", ["t2"]],
    ["es", "h-es", ["t1"]],
  ]);
});

describe("languageRoomErrorText", () => {
  const t = () => "";
  it.each([
    [{ status: 403, data: { code: "BANNED_FROM_ROOM", error: "You have been banned from this room" } }, "You were removed from this room. You can ask the owner to let you back in."],
    [{ status: 400, data: { code: "REQUEST_ALREADY_PENDING" } }, "Your request is waiting for the owner."],
    [{ status: 400, data: { error: "You can only own up to 10 topic rooms" } }, "You already have 10 rooms. Delete one to start another."],
    [{ status: 404, data: {} }, "This room is no longer available."],
    [{ status: 500 }, "Something went wrong. Try again."],
  ])("%j", (err, text) => expect(languageRoomErrorText(err, t)).toBe(text));
});
