import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { boostsApiSlice, BOOSTS_URL, COIN_BALANCE_URL } from "./boostsSlice";

function makeStore() {
  return configureStore({
    reducer: { [apiSlice.reducerPath]: apiSlice.reducer, auth: (s: any = { userInfo: null }) => s },
    middleware: (g) => g().concat(apiSlice.middleware),
  });
}
type Captured = { url: string; method: string; body: string | undefined };
function mockFetch(payload: any): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.clone ? await req.clone().text() : undefined;
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify(payload), { status: 200, headers: { "content-type": "application/json" } });
  });
  return calls;
}
const ep = (n: string) => (boostsApiSlice.endpoints as any)[n];
const path = (c: Captured) => new URL(c.url).pathname;

it("buys a profile boost with the app's body and unwraps data.boost", async () => {
  const calls = mockFetch({ success: true, data: { boost: { _id: "b1" } } });
  const res: any = await makeStore().dispatch(ep("purchaseProfileBoost").initiate());
  expect([calls[0].method, path(calls[0])]).toEqual(["POST", BOOSTS_URL]);
  expect(JSON.parse(calls[0].body as string)).toEqual({ kind: "profile" });
  expect(res.data).toEqual({ _id: "b1" });
});

it("reads the live boost (or null) and the history", async () => {
  let calls = mockFetch({ success: true, data: { boost: null } });
  const store = makeStore();
  const active: any = await store.dispatch(ep("getActiveBoost").initiate());
  expect(path(calls[0])).toBe(`${BOOSTS_URL}/active`);
  expect(active.data).toBeNull();
  calls = mockFetch({ success: true, data: { boosts: [{ _id: "b1" }] } });
  const history: any = await store.dispatch(ep("getBoostHistory").initiate());
  expect(path(calls[0])).toBe(`${BOOSTS_URL}/history`);
  expect(history.data).toEqual([{ _id: "b1" }]);
});

it("reads the coin balance", async () => {
  const calls = mockFetch({ success: true, balance: 210 });
  const res: any = await makeStore().dispatch(ep("getCoinBalance").initiate());
  expect(path(calls[0])).toBe(COIN_BALANCE_URL);
  expect(res.data).toBe(210);
});
