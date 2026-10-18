import "@testing-library/jest-dom";
import React from "react";
import { render, screen, act, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import authReducer, { logout, setCredentials } from "../../../store/slices/authSlice";
import { BASE_URL } from "../../../constants";
import { SocketProvider, useSocket } from "./useSocket";

// The signed-in half of the provider. The logged-out half -- "never loads the
// client at all" -- is useSocket.loggedOut.test.tsx, in its own file because
// Jest shares one module registry across the tests inside a file: the first
// test here loads socket.io-client and it stays loaded, which would make that
// assertion quietly depend on declaration order.
//
// `global` rather than a module-scope const, so the factory cannot hit a TDZ
// if something ever evaluates the module at import time.
const mockIo = jest.fn();
(global as any).__btIo = (...args: any[]) => mockIo(...args);

jest.mock("socket.io-client", () => {
  return { io: (...args: any[]) => (global as any).__btIo(...args) };
});

interface FakeSocket {
  id: string;
  connected: boolean;
  on: jest.Mock;
  off: jest.Mock;
  onAny: jest.Mock;
  emit: jest.Mock;
  disconnect: jest.Mock;
  removeAllListeners: jest.Mock;
  connect: jest.Mock;
  fire: (event: string, ...args: any[]) => void;
  handlerCount: (event: string) => number;
}

/** A socket.io stand-in: records listeners so a test can fire server events. */
function makeFakeSocket(id: string): FakeSocket {
  const handlers: Record<string, Function[]> = {};
  const socket: FakeSocket = {
    id,
    connected: false,
    on: jest.fn((event: string, handler: Function) => {
      handlers[event] = (handlers[event] || []).concat(handler);
      return socket;
    }),
    off: jest.fn((event: string, handler: Function) => {
      handlers[event] = (handlers[event] || []).filter((h) => h !== handler);
      return socket;
    }),
    onAny: jest.fn(),
    emit: jest.fn(),
    disconnect: jest.fn(() => {
      socket.connected = false;
      return socket;
    }),
    removeAllListeners: jest.fn(() => {
      Object.keys(handlers).forEach((k) => delete handlers[k]);
      return socket;
    }),
    connect: jest.fn(() => {
      socket.connected = true;
      return socket;
    }),
    fire: (event: string, ...args: any[]) => {
      (handlers[event] || []).slice().forEach((h) => h(...args));
    },
    handlerCount: (event: string) => (handlers[event] || []).length,
  };
  return socket;
}

/** Renders the context value so assertions read the same shape consumers do. */
const Probe: React.FC = () => {
  const { socket, isConnected, emit, connectionEpoch, kicked } = useSocket() as any;
  return (
    <div>
      <span data-testid="socket">{socket ? (socket as any).id : "none"}</span>
      <span data-testid="connected">{isConnected ? "yes" : "no"}</span>
      <span data-testid="emit">{typeof emit}</span>
      <span data-testid="epoch">{String(connectionEpoch)}</span>
      <span data-testid="kicked">{kicked ? "yes" : "no"}</span>
    </div>
  );
};

const makeTestStore = (token?: string) =>
  configureStore({
    reducer: { auth: authReducer },
    preloadedState: token
      ? ({ auth: { userInfo: { user: { _id: "u1" }, token } } } as any)
      : ({ auth: { userInfo: null } } as any),
  });

async function renderProvider(store: ReturnType<typeof makeTestStore>) {
  const utils = render(
    <Provider store={store}>
      <SocketProvider>
        <Probe />
      </SocketProvider>
    </Provider>
  );
  // Let the dynamic import's microtask settle (a no-op when nothing loads).
  await act(async () => {
    await Promise.resolve();
  });
  return utils;
}

beforeEach(() => {
  mockIo.mockReset();
  mockIo.mockImplementation(() => makeFakeSocket("sock-default"));
  localStorage.clear();
});

it("loads the client and connects with the token once a visitor is signed in", async () => {
  const sock = makeFakeSocket("sock-signed-in");
  mockIo.mockImplementation(() => sock);

  await renderProvider(makeTestStore("tok-signed-in"));

  await waitFor(() => expect(mockIo).toHaveBeenCalledTimes(1));
  expect(mockIo.mock.calls[0][0]).toBe(BASE_URL);
  expect(mockIo.mock.calls[0][1]).toEqual(
    expect.objectContaining({
      auth: { token: "tok-signed-in" },
      transports: ["websocket", "polling"],
      reconnection: true,
    })
  );
  await waitFor(() => expect(screen.getByTestId("socket")).toHaveTextContent("sock-signed-in"));

  // The provider syncs React state off the socket's own connect/disconnect.
  act(() => {
    sock.connected = true;
    sock.fire("connect");
  });
  expect(screen.getByTestId("connected")).toHaveTextContent("yes");

  act(() => {
    sock.connected = false;
    sock.fire("disconnect", "transport close");
  });
  expect(screen.getByTestId("connected")).toHaveTextContent("no");
});

it("disconnects and drops the socket when the user signs out", async () => {
  const sock = makeFakeSocket("sock-sign-out");
  mockIo.mockImplementation(() => sock);
  const store = makeTestStore("tok-sign-out");

  await renderProvider(store);
  await waitFor(() => expect(mockIo).toHaveBeenCalledTimes(1));

  await act(async () => {
    store.dispatch(logout(undefined));
    await Promise.resolve();
  });

  expect(sock.disconnect).toHaveBeenCalled();
  await waitFor(() => expect(screen.getByTestId("socket")).toHaveTextContent("none"));
  expect(screen.getByTestId("connected")).toHaveTextContent("no");
});

// Both pushes mean the same thing -- the server has given up on this token --
// and they have separate, near-identical handlers, so both are fired here
// rather than one being trusted to stand in for the other.
it.each(["authError", "tokenExpired"])("forces a logout when the server pushes %s", async (event: string) => {
  const sock = makeFakeSocket(`sock-${event}`);
  mockIo.mockImplementation(() => sock);
  const store = makeTestStore(`tok-${event}`);

  await renderProvider(store);
  await waitFor(() => expect(sock.handlerCount("authError")).toBe(1));
  expect(sock.handlerCount("tokenExpired")).toBe(1);

  await act(async () => {
    sock.fire(event, { error: "invalid token", reason: "expired" });
    await Promise.resolve();
  });

  expect(store.getState().auth.userInfo).toBe(null);
  expect(sock.disconnect).toHaveBeenCalled();
  expect(screen.getByTestId("socket")).toHaveTextContent("none");
});

// The silent-refresh path: src/store/slices/apiSlice.ts's baseQueryWithReauth
// dispatches setCredentials with a fresh token after a 401, so the token
// rotates with nobody signing out. Before the client was lazy this swap was
// one synchronous effect body; now the loader resolves a microtask later, and
// what this test pins is that the gap is empty rather than stale -- consumers
// see `null`, not a socket that is about to be destroyed with their listeners
// still on it.
it("drops the stale socket synchronously when the token rotates", async () => {
  const a = makeFakeSocket("sock-token-a");
  const b = makeFakeSocket("sock-token-b");
  mockIo.mockImplementationOnce(() => a).mockImplementationOnce(() => b);
  const store = makeTestStore("tok-a");

  await renderProvider(store);
  await waitFor(() => expect(screen.getByTestId("socket")).toHaveTextContent("sock-token-a"));
  act(() => {
    a.connected = true;
    a.fire("connect");
  });
  expect(screen.getByTestId("connected")).toHaveTextContent("yes");

  // No logout — the same user, a new access token.
  act(() => {
    store.dispatch(setCredentials({ user: { _id: "u1" }, token: "tok-b" }));
  });

  // Synchronously, in the same tick the effect ran: the old socket is closed
  // and gone from the context, and the new one does not exist yet (the
  // loader's `.then` is a microtask, which cannot run before this assertion).
  expect(a.disconnect).toHaveBeenCalled();
  expect(a.removeAllListeners).toHaveBeenCalled();
  expect(screen.getByTestId("socket")).toHaveTextContent("none");
  expect(screen.getByTestId("connected")).toHaveTextContent("no");
  expect(mockIo).toHaveBeenCalledTimes(1);

  // And then the new one arrives, authenticated with token B.
  await act(async () => {
    await Promise.resolve();
  });
  await waitFor(() => expect(screen.getByTestId("socket")).toHaveTextContent("sock-token-b"));
  expect(mockIo).toHaveBeenCalledTimes(2);
  expect(mockIo.mock.calls[1][1]).toEqual(
    expect.objectContaining({ auth: { token: "tok-b" } })
  );
  act(() => {
    b.connected = true;
    b.fire("connect");
  });
  expect(screen.getByTestId("connected")).toHaveTextContent("yes");
  // B never inherited A's listeners, and A never got B's.
  expect(a.handlerCount("connect")).toBe(0);
});

it("reuses one socket for the same token and detaches its listeners on unmount", async () => {
  const sock = makeFakeSocket("sock-reuse");
  mockIo.mockImplementation(() => sock);

  const first = await renderProvider(makeTestStore("tok-reuse"));
  await waitFor(() => expect(mockIo).toHaveBeenCalledTimes(1));
  // One "connect" listener: the provider's state sync. (The singleton used
  // to add a permanent debug one on top; it logged every event of every
  // conversation to the reader's console and is gone.)
  await waitFor(() => expect(sock.handlerCount("connect")).toBe(1));

  first.unmount();
  expect(sock.handlerCount("connect")).toBe(0);
  expect(sock.handlerCount("authError")).toBe(0);
  // Unmount is not a sign-out: the singleton survives so a remount (a route
  // change that re-renders the shell) does not reconnect.
  expect(sock.disconnect).not.toHaveBeenCalled();

  await renderProvider(makeTestStore("tok-reuse"));
  await waitFor(() => expect(screen.getByTestId("socket")).toHaveTextContent("sock-reuse"));
  expect(mockIo).toHaveBeenCalledTimes(1);
});

it("counts reconnects, not the first connect", async () => {
  const sock = makeFakeSocket("sock-epoch");
  mockIo.mockImplementation(() => sock);
  await renderProvider(makeTestStore("tok-epoch"));
  await waitFor(() => expect(sock.handlerCount("connect")).toBeGreaterThan(0));

  act(() => sock.fire("connect"));
  expect(screen.getByTestId("epoch")).toHaveTextContent("0");
  act(() => sock.fire("disconnect"));
  act(() => sock.fire("connect"));
  expect(screen.getByTestId("epoch")).toHaveTextContent("1");
});

it("marks a tab the server kicked and reconnects it when it is shown again", async () => {
  const sock = makeFakeSocket("sock-kicked");
  mockIo.mockImplementation(() => sock);
  await renderProvider(makeTestStore("tok-kicked"));
  await waitFor(() => expect(sock.handlerCount("forceDisconnect")).toBe(1));

  act(() => {
    sock.connected = false;
    sock.fire("forceDisconnect", { reason: "max_connections" });
  });
  expect(screen.getByTestId("kicked")).toHaveTextContent("yes");

  Object.defineProperty(document, "visibilityState", { configurable: true, get: () => "visible" });
  act(() => {
    document.dispatchEvent(new Event("visibilitychange"));
  });
  expect(sock.connect).toHaveBeenCalled();
});

it("refreshes the session on tokenExpired when a refresh token is stored", async () => {
  const sock = makeFakeSocket("sock-refresh");
  mockIo.mockImplementation(() => sock);
  (global as any).fetch = jest.fn(() =>
    Promise.resolve(new Response(JSON.stringify({ token: "tok-fresh" }), { status: 200, headers: { "content-type": "application/json" } }))
  );
  const store = configureStore({
    reducer: { auth: authReducer },
    preloadedState: { auth: { userInfo: { user: { _id: "u1" }, token: "tok-old", refreshToken: "r1" } } } as any,
  });
  await renderProvider(store);
  await waitFor(() => expect(sock.handlerCount("tokenExpired")).toBe(1));

  await act(async () => {
    sock.fire("tokenExpired", { reason: "token_expired" });
    await Promise.resolve();
    await Promise.resolve();
  });

  await waitFor(() => expect((store.getState() as any).auth.userInfo.token).toBe("tok-fresh"));
});
