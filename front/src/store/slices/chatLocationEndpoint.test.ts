/**
 * The web sends a location with the exact body the app sends
 * (message_provider.dart sendLocationMessage): POST /messages, JSON
 * {receiver, location:{latitude, longitude, address?, placeName?}}.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { chatApiSlice } from "./chatSlice";
import * as chatSliceExports from "./chatSlice";
import { MESSAGES_URL } from "../../constants";

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

function mockFetch(): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify({ success: true, data: {} }), {
      status: 201,
      headers: { "content-type": "application/json" },
    });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

it("exports the hook", () => {
  expect(typeof (chatSliceExports as any).useSendLocationMessageMutation).toBe("function");
});

it("POSTs {receiver, location} to /messages", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(
    (chatApiSlice.endpoints as any).sendLocationMessage.initiate({
      receiver: "u2",
      latitude: 37.5665,
      longitude: 126.978,
      placeName: "Seoul, South Korea",
      address: "Jung-gu, Seoul, South Korea",
    })
  );
  expect(calls).toHaveLength(1);
  expect(new URL(calls[0].url).pathname).toBe(MESSAGES_URL);
  expect(calls[0].method).toBe("POST");
  expect(JSON.parse(calls[0].body as string)).toEqual({
    receiver: "u2",
    location: {
      latitude: 37.5665,
      longitude: 126.978,
      placeName: "Seoul, South Korea",
      address: "Jung-gu, Seoul, South Korea",
    },
  });
});

it("leaves out a place name and address it does not have", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(
    (chatApiSlice.endpoints as any).sendLocationMessage.initiate({ receiver: "u2", latitude: 1.5, longitude: 2.5 })
  );
  expect(JSON.parse(calls[0].body as string)).toEqual({ receiver: "u2", location: { latitude: 1.5, longitude: 2.5 } });
});
