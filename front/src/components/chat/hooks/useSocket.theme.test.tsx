import React from "react";
import { render, waitFor } from "@testing-library/react";
import { configureStore } from "@reduxjs/toolkit";
import { Provider } from "react-redux";
import { apiSlice } from "../../../store/slices/apiSlice";
import { chatApiSlice } from "../../../store/slices/chatSlice";
import { SocketProvider } from "./useSocket";

/**
 * The other person changes the wallpaper; the server pushes `themeChanged` to
 * this viewer's room. The pane reads the theme out of RTK Query, so the push
 * has to land in that cache entry — otherwise the shared wallpaper is only
 * shared after a reload.
 *
 * socket.io-client is loaded with a dynamic import inside the provider, so the
 * fake here is a module mock: one object that records handlers and can fire
 * them back.
 */
const mockHandlers: { [event: string]: Function[] } = {};

const mockFakeSocket = {
  id: "s1",
  connected: true,
  on: (event: string, handler: Function) => {
    mockHandlers[event] = (mockHandlers[event] || []).concat(handler);
  },
  off: (event: string, handler: Function) => {
    mockHandlers[event] = (mockHandlers[event] || []).filter((h) => h !== handler);
  },
  onAny: jest.fn(),
  emit: jest.fn(),
  removeAllListeners: jest.fn(),
  disconnect: jest.fn(),
};

jest.mock("socket.io-client", () => ({
  io: () => mockFakeSocket,
}));

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: { token: "t", user: { _id: "me" } } }) => state,
    },
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  Object.keys(mockHandlers).forEach((key) => delete mockHandlers[key]);
});

function mockFetch(preset: string) {
  (global as any).fetch = jest.fn(async () =>
    new Response(JSON.stringify({ success: true, data: { preset } }), {
      status: 200,
      headers: { "content-type": "application/json" },
    })
  );
}

describe("the socket's themeChanged push", () => {
  it("writes the new wallpaper into the conversation's theme cache", async () => {
    mockFetch("default");
    const store = makeStore();

    render(
      <Provider store={store}>
        <SocketProvider>
          <div />
        </SocketProvider>
      </Provider>
    );

    // The pane is holding the theme of this conversation.
    store.dispatch(
      (chatApiSlice.endpoints as any).getConversationTheme.initiate("conv-1")
    );

    await waitFor(() => expect(mockHandlers.themeChanged).toBeDefined());
    await waitFor(() => {
      const state: any = store.getState();
      const entry: any = state.api.queries["getConversationTheme(\"conv-1\")"];
      expect(entry && entry.data && entry.data.data.preset).toBe("default");
    });

    mockHandlers.themeChanged.forEach((handler) =>
      handler({
        conversationId: "conv-1",
        theme: { preset: "gradient_ocean" },
        changedBy: "u2",
      })
    );

    await waitFor(() => {
      const state: any = store.getState();
      const entry: any = state.api.queries["getConversationTheme(\"conv-1\")"];
      expect(entry.data.data.preset).toBe("gradient_ocean");
    });
  });

  it("ignores a push with no conversation or no theme", async () => {
    mockFetch("cream");
    const store = makeStore();
    render(
      <Provider store={store}>
        <SocketProvider>
          <div />
        </SocketProvider>
      </Provider>
    );
    store.dispatch(
      (chatApiSlice.endpoints as any).getConversationTheme.initiate("conv-1")
    );
    await waitFor(() => expect(mockHandlers.themeChanged).toBeDefined());

    mockHandlers.themeChanged.forEach((handler) => {
      handler(undefined);
      handler({ conversationId: "conv-1" });
      handler({ theme: { preset: "navy" } });
    });

    await waitFor(() => {
      const state: any = store.getState();
      const entry: any = state.api.queries["getConversationTheme(\"conv-1\")"];
      expect(entry.data.data.preset).toBe("cream");
    });
  });
});

describe("the socket layer keeps quiet in production", () => {
  it("no longer logs every event it receives", () => {
    const fs = require("fs");
    const path = require("path");
    const source = fs.readFileSync(path.join(__dirname, "useSocket.ts"), "utf8");
    expect(source).not.toContain("onAny");
    expect(source).not.toMatch(/^\s*console\.log/m);
  });
});
