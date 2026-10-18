import React, { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';
import { useSelector, useDispatch, useStore } from 'react-redux';
import { RootState } from '../../../store';
import { logout } from '../../../store/slices/authSlice';
import { chatApiSlice } from '../../../store/slices/chatSlice';
import { BASE_URL } from '../../../constants';
import { refreshSession } from '../../../store/refreshSession';

// ---- Types ----

// `socket.io-client` is loaded with `import()` below, so it must not appear in
// a static `import` declaration -- not even a type-only one: TypeScript 3.7
// has no `import type`, and a value import whose bindings happen to be used
// only as types is still a static edge as far as src/seo/eagerGraph.test.ts
// (and, historically, as far as a stray `new Socket()` would be) is concerned.
// An `import(...)` *type* is erased by Babel and invisible to webpack.
type Socket = import('socket.io-client').Socket;
type IoFactory = typeof import('socket.io-client').io;

interface SocketContextValue {
  socket: Socket | null;
  isConnected: boolean;
  emit: (event: string, data?: any, callback?: (response: any) => void) => void;
  /** Increments on every reconnect (not the first connect). Consumers re-read on change. */
  connectionEpoch: number;
  /** The server dropped this tab (`forceDisconnect`, >5 sockets); it will not reconnect by itself. */
  kicked: boolean;
  reconnect: () => void;
}

// ---- Lazy client ----

/**
 * The socket.io client, fetched the first time somebody is signed in.
 *
 * ~13 KB gzipped (engine.io, the parsers, the reconnect manager) that a
 * logged-out visitor on a marketing page can never use: there is no token to
 * authenticate with, so the only thing importing it eagerly bought was a
 * bigger main.js for every crawler and every first-time reader. The promise is
 * cached, so a sign-out/sign-in round trip re-uses the chunk the browser
 * already has.
 *
 * The chunk is named `socketio` on purpose -- no dot, no hyphen. The check
 * that this split is real is `grep -c "socket.io" build/static/js/main.*.js`,
 * and webpack writes every named chunk into the runtime's id->name map inside
 * main.js, so a name containing the package's own spelling would answer that
 * grep with a 1 forever after.
 */
let ioLoader: Promise<IoFactory> | null = null;

function loadIo(): Promise<IoFactory> {
  if (!ioLoader) {
    ioLoader = import(/* webpackChunkName: "socketio" */ 'socket.io-client').then((m) => m.io);
  }
  return ioLoader;
}

/**
 * Errors only, and only where a developer can see them. The chat socket used
 * to narrate itself into every user's console — every event, every reconnect,
 * with payloads — which is noise at best and a transcript of someone's
 * conversation at worst.
 */
function logError(message: string, detail?: any): void {
  if (process.env.NODE_ENV === 'production') return;
  console.error(`[Socket] ${message}`, detail);
}

// ---- Module-level singleton ----

let globalSocket: Socket | null = null;
let globalToken: string | null = null;

function getOrCreateSocket(io: IoFactory, token: string): Socket {
  // Reuse existing socket if token hasn't changed (don't check .disconnected —
  // a socket that's still connecting has disconnected=true, which would cause
  // a duplicate connection on React StrictMode remount)
  if (globalSocket && globalToken === token) {
    return globalSocket;
  }

  // Clean up old socket only if token actually changed
  if (globalSocket) {
    globalSocket.removeAllListeners();
    globalSocket.disconnect();
    globalSocket = null;
  }

  globalToken = token;
  globalSocket = io(BASE_URL, {
    auth: { token },
    transports: ['websocket', 'polling'],
    reconnection: true,
    reconnectionAttempts: Infinity,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 10000,
    randomizationFactor: 0.5,
    timeout: 20000,
  });

  // No blanket event mirror and no connect/disconnect chatter: this
  // is a user's console, not ours, and the transcript of a private
  // conversation is the last thing that belongs in it. A connection that
  // FAILS is still worth a line, in development only.
  globalSocket.on('connect_error', (err) => {
    logError('connect error', err && err.message);
  });

  return globalSocket;
}

/**
 * Tear the singleton down. Called when the session ends — a sign-out, or the
 * `authError`/`tokenExpired` push that forces one — and when the token
 * rotates under us; never on unmount: a route change re-mounts the provider
 * and must not reconnect.
 */
function destroySocket(reason: string): void {
  if (!globalSocket) return;
  globalSocket.removeAllListeners();
  globalSocket.disconnect();
  globalSocket = null;
  globalToken = null;
}

// ---- Context ----

const SocketContext = createContext<SocketContextValue>({
  socket: null,
  isConnected: false,
  emit: () => {},
  connectionEpoch: 0,
  kicked: false,
  reconnect: () => {},
});

// ---- Provider ----

export const SocketProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const token = useSelector((state: RootState) => state.auth.userInfo?.token);
  const dispatch = useDispatch();
  const [connectionEpoch, setConnectionEpoch] = useState(0);
  const [kicked, setKicked] = useState(false);
  const store = useStore();
  // Survives a token-rotation socket swap, so the new socket's first connect
  // still counts as a REconnect (the thread missed whatever came meanwhile).
  const seenConnectRef = useRef(false);

  useEffect(() => {
    // Logged out: nothing to connect to, and nothing to download. Anything the
    // previous session left open is closed here — this is the sign-out path.
    if (!token) {
      setSocket(null);
      setIsConnected(false);
      seenConnectRef.current = false;
      setKicked(false);
      destroySocket('Signed out');
      return;
    }

    // The token rotated without a sign-out. This is a real path, not a
    // hypothetical one: baseQueryWithReauth dispatches `setCredentials` with a
    // fresh token after a silent 401 refresh, which re-runs this effect with a
    // new, non-null token.
    //
    // Before the client was lazy, the swap happened inside one synchronous
    // effect body, so no render ever saw the old socket after the new token
    // arrived. `loadIo()` now resolves a microtask later (the promise is
    // cached, but a promise is still a promise), and in that gap `socket`
    // would still be the old object with consumer listeners attached to it —
    // a socket about to be destroyed. So close it here, synchronously, and let
    // consumers see `null` in the gap exactly as they do when logged out:
    // every one of them already guards on it, and their effects key on
    // `[socket]`, so they re-attach when the new one arrives.
    if (globalToken && globalToken !== token) {
      setSocket(null);
      setIsConnected(false);
      destroySocket('Token rotated');
    }

    // Sync React state with socket connection state
    const onConnect = () => {
      setIsConnected(true);
      setKicked(false);
      if (seenConnectRef.current) {
        // REST, media, voice, call and wave messages sent while this tab was
        // away are not in the server's offline queue; the list re-reads now
        // and every open thread re-reads its newest page off the epoch.
        setConnectionEpoch((n) => n + 1);
        (dispatch as any)((chatApiSlice.util as any).invalidateTags(['Conversations']));
      }
      seenConnectRef.current = true;
    };
    const onForceDisconnect = () => setKicked(true);
    const onDisconnect = () => setIsConnected(false);

    // The server has given up on this token and closed the socket. Refresh
    // it the way a REST 401 would; the new token re-creates the socket. Only
    // a failed refresh ends the session (refreshSession logs out).
    const onTokenExpired = (data?: { reason?: string }) => {
      logError('tokenExpired — refreshing', data);
      refreshSession(dispatch as any, store.getState);
    };

    const onAuthError = (data?: { error?: string }) => {
      logError('authError — forcing logout', data);
      dispatch(logout());
    };

    // Heads-up only. The next REST call's 401 path rotates the token by
    // itself, so there is nothing to do and nothing to say.
    const onTokenExpiring = (_data?: { secondsRemaining?: number }) => {};

    // The other person changed the conversation's wallpaper. The theme is
    // SHARED (the server writes it on the conversation and pushes it here
    // from controllers/conversations.js), so the pane has to repaint without
    // a reload — which means writing it into the cache entry the pane reads,
    // `getConversationTheme(<conversationId>)`. A push for a conversation
    // this client is not holding patches nothing, which is correct: it will
    // be fetched fresh when that thread is next opened.
    const onThemeChanged = (data?: { conversationId?: string; theme?: any }) => {
      if (!data || !data.conversationId || !data.theme) return;
      (dispatch as any)(
        (chatApiSlice.util as any).updateQueryData(
          'getConversationTheme',
          data.conversationId,
          (draft: any) => {
            if (!draft) return;
            draft.data = Object.assign({}, draft.data || {}, data.theme);
          }
        )
      );
    };

    // The chunk arrives a tick (or a network round trip) later, so the effect
    // may already have been cleaned up by then — `cancelled` is what keeps a
    // signed-out provider from attaching listeners to a socket it will never
    // read, and `attached` is what the cleanup detaches.
    let cancelled = false;
    let attached: Socket | null = null;

    loadIo().then(
      (io) => {
        if (cancelled) return;
        const s = getOrCreateSocket(io, token);
        attached = s;
        setSocket(s);

        s.on('connect', onConnect);
        s.on('disconnect', onDisconnect);
        s.on('tokenExpired', onTokenExpired);
        s.on('tokenExpiring', onTokenExpiring);
        s.on('authError', onAuthError);
        s.on('themeChanged', onThemeChanged);
        s.on('forceDisconnect', onForceDisconnect);

        // If already connected (reusing existing socket), sync state
        if (s.connected) {
          seenConnectRef.current = true;
          setIsConnected(true);
        }
      },
      (err) => {
        // A failed chunk leaves chat inert rather than broken: every consumer
        // guards on a null socket, and the next sign-in retries the import.
        ioLoader = null;
        logError('failed to load the realtime client', err);
      }
    );

    return () => {
      cancelled = true;
      if (!attached) return;
      attached.off('connect', onConnect);
      attached.off('disconnect', onDisconnect);
      attached.off('tokenExpired', onTokenExpired);
      attached.off('tokenExpiring', onTokenExpiring);
      attached.off('authError', onAuthError);
      attached.off('themeChanged', onThemeChanged);
      attached.off('forceDisconnect', onForceDisconnect);
    };
  }, [token, dispatch, store]);

  const reconnect = useCallback(() => {
    if (globalSocket && !globalSocket.connected) globalSocket.connect();
  }, []);

  // A kicked tab comes back when the person returns to it -- never on its
  // own timer, or two open tabs would keep kicking each other.
  useEffect(() => {
    if (!kicked) return undefined;
    const onVisible = () => {
      if (document.visibilityState === 'visible') reconnect();
    };
    document.addEventListener('visibilitychange', onVisible);
    return () => document.removeEventListener('visibilitychange', onVisible);
  }, [kicked, reconnect]);

  const emit = useCallback((event: string, data?: any, callback?: (response: any) => void) => {
    if (globalSocket?.connected) {
      globalSocket.emit(event, data, callback);
    }
  }, []);

  const value: SocketContextValue = { socket, isConnected, emit, connectionEpoch, kicked, reconnect };

  return React.createElement(SocketContext.Provider, { value }, children);
};

// ---- Hook ----

export const useSocket = () => useContext(SocketContext);

export default useSocket;
