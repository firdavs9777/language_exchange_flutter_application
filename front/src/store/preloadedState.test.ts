import { apiSlice } from "./slices/apiSlice";
import { makeStore, readPreloadedState } from "./index";

const PATH = apiSlice.reducerPath;

function preloaded() {
  return {
    [PATH]: {
      queries: {},
      mutations: {},
      provided: {},
      subscriptions: {},
      config: {
        online: true,
        focused: true,
        middlewareRegistered: true,
        refetchOnFocus: false,
        refetchOnReconnect: true,
        refetchOnMountOrArgChange: false,
        keepUnusedDataFor: 60,
        reducerPath: PATH,
      },
    },
  };
}

afterEach(() => {
  delete (window as any).__BT_PRELOADED_STATE__;
});

it("reads the prerender's state off window and takes it away again", () => {
  const state = preloaded();
  (window as any).__BT_PRELOADED_STATE__ = state;

  expect(readPreloadedState()).toEqual(state);
  // Left on window it would be a stale global for the rest of the session.
  expect((window as any).__BT_PRELOADED_STATE__).toBeUndefined();
  expect("__BT_PRELOADED_STATE__" in window).toBe(false);
});

it("returns undefined when the page carried no state", () => {
  expect(readPreloadedState()).toBeUndefined();
});

it("builds a store from the preloaded state", () => {
  (window as any).__BT_PRELOADED_STATE__ = preloaded();
  const store = makeStore(readPreloadedState());
  expect((store.getState() as any)[PATH].config.online).toBe(true);
});
