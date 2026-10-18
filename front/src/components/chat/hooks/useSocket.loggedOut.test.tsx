import "@testing-library/jest-dom";
import React from "react";
import { render, screen, act } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import authReducer from "../../../store/slices/authSlice";
import { SocketProvider, useSocket } from "./useSocket";

// The one assertion task D2 exists for: a logged-out visitor -- every crawler,
// every first-time reader of a marketing page -- must not download the socket
// client at all.
//
// It lives in its own file because Jest gives each *file* a fresh module
// registry but shares one across the tests inside a file. In useSocket.test.tsx
// the first signed-in test loads socket.io-client and it stays loaded, so this
// case would silently depend on being declared first there. Here nothing else
// can have loaded it, and `jest.resetModules()` -- which would hand the
// provider a second copy of React and break hooks -- is not needed.
//
// The counter is a faithful stand-in for "webpack fetched the chunk": Jest
// runs a mock factory the first time the module is `require`d, and the CRA
// test preset compiles `import("...")` to a `require` inside a promise. It
// touches `global` only, never a module-scope const, so a static import at the
// top of useSocket.ts fails this as a number rather than as a TDZ crash in the
// factory ("suite failed to run", which reads like a broken test).
const mockIo = jest.fn();
(global as any).__btIo = (...args: any[]) => mockIo(...args);

jest.mock("socket.io-client", () => {
  (global as any).__btIoLoads = ((global as any).__btIoLoads || 0) + 1;
  return { io: (...args: any[]) => (global as any).__btIo(...args) };
});

const loadCount = (): number => (global as any).__btIoLoads || 0;

const Probe: React.FC = () => {
  const { socket, isConnected, emit } = useSocket();
  return (
    <div>
      <span data-testid="socket">{socket ? (socket as any).id : "none"}</span>
      <span data-testid="connected">{isConnected ? "yes" : "no"}</span>
      <span data-testid="emit">{typeof emit}</span>
    </div>
  );
};

it("never loads the socket client for a logged-out visitor", async () => {
  const store = configureStore({
    reducer: { auth: authReducer },
    preloadedState: { auth: { userInfo: null } } as any,
  });

  render(
    <Provider store={store}>
      <SocketProvider>
        <Probe />
      </SocketProvider>
    </Provider>
  );
  // Settle anything the provider might have queued. Nothing should have been.
  await act(async () => {
    await Promise.resolve();
  });

  expect(loadCount()).toBe(0);
  expect(mockIo).not.toHaveBeenCalled();

  // And the context still has the shape every consumer destructures.
  expect(screen.getByTestId("socket")).toHaveTextContent("none");
  expect(screen.getByTestId("connected")).toHaveTextContent("no");
  expect(screen.getByTestId("emit")).toHaveTextContent("function");
});
