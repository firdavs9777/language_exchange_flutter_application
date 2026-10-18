import { configureStore } from "@reduxjs/toolkit";
import { setupListeners } from "@reduxjs/toolkit/query";
import { apiSlice } from "./slices/apiSlice";
import momentSliceReducer from "./slices/momentsSlice";
import authSliceReducer from "./slices/authSlice";
import commentsSliceReducer from "./slices/comments";
import chatApiSliceReducer from "./slices/chatSlice";
import storiesApiSliceReducer from "./slices/storiesSlice";

declare global {
  interface Window {
    __BT_PRELOADED_STATE__?: Record<string, unknown>;
  }
}

/**
 * A fresh store. The browser makes one; the prerender makes one per route.
 *
 * `preloadedState` is deliberately untyped: RootState is derived from this
 * function's return type, so naming it here would make the type circular.
 */
export function makeStore(preloadedState?: any) {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      moments: momentSliceReducer,
      auth: authSliceReducer,
      comments: commentsSliceReducer,
      chats: chatApiSliceReducer,
      stories: storiesApiSliceReducer,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
    devTools: true,
    preloadedState,
  });
}

/**
 * The state the prerender fetched, inlined into the page by
 * src/seo/prerender/template.ts. Hydrating without it would render the
 * fallbacks over server markup that already has the data, which React
 * reports as a hydration mismatch and recovers from by re-rendering the
 * whole tree client-side. Read once, then removed so nothing later mistakes
 * a stale global for fresh data.
 */
export function readPreloadedState(): Record<string, unknown> | undefined {
  if (typeof window === "undefined") return undefined;
  const state = window.__BT_PRELOADED_STATE__;
  if (!state || typeof state !== "object") return undefined;
  delete window.__BT_PRELOADED_STATE__;
  return state;
}

const store = makeStore(readPreloadedState());

// RTK Query's online/offline (and focus) listeners. Without this call the
// apiSlice's `refetchOnReconnect: true` did nothing. Browser only: the
// prerender builds stores in node.
if (typeof window !== "undefined") setupListeners(store.dispatch);

export type AppStore = ReturnType<typeof makeStore>;
export type RootState = ReturnType<AppStore["getState"]>;

export default store;
