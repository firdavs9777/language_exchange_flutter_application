import React, { createContext, useContext, useEffect, useRef, useState, useCallback } from 'react';
import { io, Socket } from 'socket.io-client';
import { useSelector } from 'react-redux';
import { RootState } from '../../../store';
import { BASE_URL } from '../../../constants';

// ---- Types ----

interface SocketContextValue {
  socket: Socket | null;
  isConnected: boolean;
  emit: (event: string, data?: any, callback?: (response: any) => void) => void;
}

// ---- Module-level singleton ----

let globalSocket: Socket | null = null;
let globalToken: string | null = null;

function getOrCreateSocket(token: string): Socket {
  // Reuse existing socket if token hasn't changed (don't check .disconnected —
  // a socket that's still connecting has disconnected=true, which would cause
  // a duplicate connection on React StrictMode remount)
  if (globalSocket && globalToken === token) {
    console.log('[Socket] Reusing existing socket:', globalSocket.id, 'connected:', globalSocket.connected, 'disconnected:', globalSocket.disconnected);
    return globalSocket;
  }

  // Clean up old socket only if token actually changed
  if (globalSocket) {
    console.log('[Socket] Token changed, destroying old socket:', globalSocket.id);
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

  const s = globalSocket;

  // Permanent debug listener on the singleton - never removed
  s.onAny((event, ...args) => {
    console.log(`[Socket:${s.id}] << ${event}`, args);
  });

  s.on('connect', () => {
    console.log(`[Socket] Connected as: ${s.id}`);
  });

  s.on('disconnect', (reason) => {
    console.log(`[Socket] Disconnected: ${reason}`);
  });

  s.on('connect_error', (err) => {
    console.error(`[Socket] Connect error: ${err.message}`);
  });

  return globalSocket;
}

// ---- Context ----

const SocketContext = createContext<SocketContextValue>({
  socket: null,
  isConnected: false,
  emit: () => {},
});

// ---- Provider ----

export const SocketProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const token = useSelector((state: RootState) => state.auth.userInfo?.token);

  useEffect(() => {
    if (!token) return;

    const s = getOrCreateSocket(token);
    setSocket(s);

    // Sync React state with socket connection state
    const onConnect = () => setIsConnected(true);
    const onDisconnect = () => setIsConnected(false);

    s.on('connect', onConnect);
    s.on('disconnect', onDisconnect);

    // If already connected (reusing existing socket), sync state
    if (s.connected) {
      setIsConnected(true);
    }

    return () => {
      s.off('connect', onConnect);
      s.off('disconnect', onDisconnect);
    };
  }, [token]);

  const emit = useCallback((event: string, data?: any, callback?: (response: any) => void) => {
    if (globalSocket?.connected) {
      globalSocket.emit(event, data, callback);
    }
  }, []);

  const value: SocketContextValue = {
    socket,
    isConnected,
    emit,
  };

  return React.createElement(SocketContext.Provider, { value }, children);
};

// ---- Hook ----

export const useSocket = () => useContext(SocketContext);

export default useSocket;
