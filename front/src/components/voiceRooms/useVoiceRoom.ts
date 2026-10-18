import { useCallback, useEffect, useReducer, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { useSocket } from "../chat/hooks/useSocket";
import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "../chat/lib/socketAck";
import { createLkSession, LkPeer, LkSession } from "../../lib/livekit/lkSession";
import {
  useGetVoiceRoomQuery,
  useJoinVoiceRoomMutation,
  useGetVoiceRoomTokenMutation,
  useLeaveVoiceRoomMutation,
  useEndVoiceRoomMutation,
  usePromoteVoiceParticipantMutation,
  voiceRoomErrorText,
} from "../../store/slices/voiceRoomsSlice";
import {
  voiceRoomReducer,
  initialVoiceRoomState,
  selectMembers,
  VoiceRoomMember,
  VoiceRoomChatLine,
} from "./voiceRoomState";

export type VoiceRoomPhase = "idle" | "joining" | "live" | "reconnecting" | "ended" | "elsewhere" | "lost" | "error";

export interface UseVoiceRoom {
  phase: VoiceRoomPhase;
  error: string;
  role: "host" | "participant" | null;
  hostId: string;
  members: VoiceRoomMember[];
  micOn: boolean;
  micProblem: "denied" | "unavailable" | "error" | null;
  handRaised: boolean;
  audioBlocked: boolean;
  chat: VoiceRoomChatLine[];
  join(): Promise<void>;
  leave(): Promise<void>;
  setMic(on: boolean): Promise<void>;
  raiseHand(on: boolean): void;
  sendChat(text: string): void;
  startAudio(): Promise<void>;
  muteAll(): void;
  promote(userId: string): Promise<void>;
  endRoom(): Promise<void>;
}

const HEARTBEAT_MS = 30000;
const LIVE_PHASES: VoiceRoomPhase[] = ["live", "reconnecting"];

export function useVoiceRoom(roomId: string, myId: string): UseVoiceRoom {
  const { t } = useTranslation();
  const { socket, connectionEpoch } = useSocket() as any;
  const { data: detail, refetch: refetchDetail } = useGetVoiceRoomQuery(roomId, { skip: !roomId });
  const [joinRoom] = useJoinVoiceRoomMutation();
  const [mintToken] = useGetVoiceRoomTokenMutation();
  const [leaveRoom] = useLeaveVoiceRoomMutation();
  const [endRoomRest] = useEndVoiceRoomMutation();
  const [promoteRest] = usePromoteVoiceParticipantMutation();

  const [state, dispatch] = useReducer(voiceRoomReducer, initialVoiceRoomState);
  const [phase, setPhase] = useState<VoiceRoomPhase>("idle");
  const [error, setError] = useState("");
  const [role, setRole] = useState<"host" | "participant" | null>(null);
  const [peers, setPeers] = useState<LkPeer[]>([]);
  const [micOn, setMicOn] = useState(false);
  const [micProblem, setMicProblem] = useState<"denied" | "unavailable" | "error" | null>(null);
  const [handRaised, setHandRaised] = useState(false);
  const [audioBlocked, setAudioBlocked] = useState(false);

  const sessionRef = useRef<LkSession | null>(null);
  const phaseRef = useRef<VoiceRoomPhase>("idle");
  const heartbeatRef = useRef<any>(null);
  const handRef = useRef(false);
  const epochRef = useRef<number>(connectionEpoch || 0);
  // RTK hands back a new refetch per render in some setups; read it through a
  // ref so the socket listeners are attached once per socket, not per render.
  const refetchRef = useRef(refetchDetail);
  refetchRef.current = refetchDetail;

  const go = useCallback((p: VoiceRoomPhase) => {
    phaseRef.current = p;
    setPhase(p);
  }, []);

  const stopHeartbeat = () => {
    if (heartbeatRef.current) clearInterval(heartbeatRef.current);
    heartbeatRef.current = null;
  };

  const emit = useCallback(
    (event: string, payload: any) => {
      if (socket) socket.emit(event, payload);
    },
    [socket]
  );

  // Seed members/host from the REST detail whenever it (re)loads.
  useEffect(() => {
    if (detail) dispatch({ type: "detail", room: detail });
  }, [detail]);

  const teardown = useCallback(async () => {
    stopHeartbeat();
    const s = sessionRef.current;
    sessionRef.current = null;
    setPeers([]);
    setMicOn(false);
    if (s) await s.disconnect();
  }, []);

  // ---- socket events ---------------------------------------------------------
  useEffect(() => {
    if (!socket) return;
    const mine = (p: any) => p && String(p.roomId) === String(roomId);
    const onJoined = (p: any) => mine(p) && dispatch({ type: "joined", payload: p });
    const onLeft = (p: any) => {
      if (!mine(p)) return;
      dispatch({ type: "left", payload: p });
      if (p.roomEnded === true && LIVE_PHASES.indexOf(phaseRef.current) > -1) {
        go("ended");
        teardown();
      }
    };
    const onMute = (p: any) => {
      if (!mine(p)) return;
      dispatch({ type: "mute", payload: p });
      if (p.forced && String(p.userId) === String(myId) && p.isMuted && sessionRef.current) {
        sessionRef.current.setMic(false).then(() => setMicOn(false));
      }
    };
    const onHand = (p: any) => mine(p) && dispatch({ type: "hand", payload: p });
    const onChat = (p: any) => mine(p) && dispatch({ type: "chat", payload: p });
    const onHost = (p: any) => {
      if (!p || !p.newHostId) return;
      dispatch({ type: "host", hostId: String(p.newHostId) });
      if (String(p.newHostId) === String(myId)) setRole("host");
      if (refetchRef.current) refetchRef.current();
    };
    const onEnded = (p: any) => {
      if (!mine(p)) return;
      dispatch({ type: "ended" });
      if (LIVE_PHASES.indexOf(phaseRef.current) > -1 || phaseRef.current === "joining") {
        go("ended");
        teardown();
      }
    };
    socket.on("voiceroom:user_joined", onJoined);
    socket.on("voiceroom:user_left", onLeft);
    socket.on("voiceroom:mute", onMute);
    socket.on("voiceroom:hand_raised", onHand);
    socket.on("voiceroom:chat", onChat);
    socket.on("voiceroom:host-changed", onHost);
    socket.on("voiceroom:ended", onEnded);
    return () => {
      socket.off("voiceroom:user_joined", onJoined);
      socket.off("voiceroom:user_left", onLeft);
      socket.off("voiceroom:mute", onMute);
      socket.off("voiceroom:hand_raised", onHand);
      socket.off("voiceroom:chat", onChat);
      socket.off("voiceroom:host-changed", onHost);
      socket.off("voiceroom:ended", onEnded);
    };
  }, [socket, roomId, myId, go, teardown]);

  // ---- socket reconnect while in the room: rejoin (Phase 3 connectionEpoch) --
  useEffect(() => {
    const epoch = connectionEpoch || 0;
    if (epoch === epochRef.current) return;
    epochRef.current = epoch;
    if (!socket || LIVE_PHASES.indexOf(phaseRef.current) === -1) return;
    emitWithAck(socket, "voiceroom:rejoin", { roomId, lastSeenAt: new Date().toISOString() }, SOCKET_ACK_TIMEOUT_MS, {
      onAck: (ack: any) => {
        if (!ack || ack.ended) {
          go("ended");
          teardown();
          return;
        }
        if (ack.currentHostId) {
          dispatch({ type: "host", hostId: String(ack.currentHostId) });
          if (String(ack.currentHostId) === String(myId)) setRole("host");
        }
        if (Array.isArray(ack.participants)) dispatch({ type: "detail", room: { host: ack.currentHostId, participants: ack.participants } });
      },
      onTimeout: () => {
        // The room keeps playing over LiveKit; the next heartbeat or reconnect retries.
      },
    });
  }, [connectionEpoch, socket, roomId, myId, go, teardown]);

  // ---- actions ------------------------------------------------------------
  const join = useCallback(async () => {
    if (phaseRef.current === "joining" || LIVE_PHASES.indexOf(phaseRef.current) > -1) return;
    go("joining");
    setError("");
    setMicProblem(null);
    let token: any;
    try {
      await joinRoom(roomId).unwrap();
      token = await mintToken(roomId).unwrap();
    } catch (err) {
      setError(voiceRoomErrorText(err, t));
      go("error");
      return;
    }
    setRole(token && token.role === "host" ? "host" : "participant");
    emit("voiceroom:join", { roomId });
    const session = createLkSession({
      onPeers: (p) => setPeers(p),
      onState: (s) => {
        if (s === "reconnecting" && phaseRef.current === "live") go("reconnecting");
        if (s === "connected" && phaseRef.current === "reconnecting") go("live");
      },
      onAudioBlocked: (blocked) => setAudioBlocked(blocked),
      onDisconnected: (reason) => {
        stopHeartbeat();
        sessionRef.current = null;
        setPeers([]);
        setMicOn(false);
        if (reason === "client") return;
        if (reason === "duplicate_identity") go("elsewhere");
        else if (reason === "room_deleted" || reason === "participant_removed") go("ended");
        else go("lost");
      },
    });
    sessionRef.current = session;
    try {
      await session.connect(token.url, token.token, { mic: false, camera: false });
    } catch (err) {
      sessionRef.current = null;
      setError(t("voiceRooms.room.connectFailed") || "Couldn't connect to the room's audio. Check your connection and try again.");
      go("error");
      return;
    }
    go("live");
    stopHeartbeat();
    heartbeatRef.current = setInterval(() => emit("voiceroom:heartbeat", { roomId }), HEARTBEAT_MS);
  }, [roomId, joinRoom, mintToken, emit, go, t]);

  const leave = useCallback(async () => {
    if (phaseRef.current === "idle") return;
    emit("voiceroom:leave", { roomId });
    go("idle");
    setHandRaised(false);
    handRef.current = false;
    leaveRoom(roomId)
      .unwrap()
      .catch(() => undefined);
    await teardown();
  }, [roomId, emit, go, leaveRoom, teardown]);

  const raiseHand = useCallback(
    (on: boolean) => {
      handRef.current = on;
      setHandRaised(on);
      emit("voiceroom:raise_hand", { roomId, isRaised: on });
    },
    [roomId, emit]
  );

  const setMic = useCallback(
    async (on: boolean) => {
      const s = sessionRef.current;
      if (!s) return;
      const result = await s.setMic(on);
      if (result === "ok") {
        setMicOn(on);
        setMicProblem(null);
        emit("voiceroom:mute", { roomId, isMuted: !on });
        if (on && handRef.current) raiseHand(false);
      } else {
        setMicOn(false);
        setMicProblem(result === "denied" || result === "unavailable" ? result : "error");
      }
    },
    [roomId, emit, raiseHand]
  );

  const sendChat = useCallback(
    (text: string) => {
      const message = String(text || "").trim().slice(0, 500);
      if (!message) return;
      emit("voiceroom:chat", { roomId, message });
    },
    [roomId, emit]
  );

  const startAudio = useCallback(async () => {
    const s = sessionRef.current;
    if (s) await s.startAudio();
  }, []);

  const muteAll = useCallback(() => emit("voiceroom:mute-all", { roomId }), [roomId, emit]);

  const promote = useCallback(
    async (userId: string) => {
      try {
        await promoteRest({ roomId, userId }).unwrap();
      } catch (err) {
        setError(voiceRoomErrorText(err, t));
      }
    },
    [roomId, promoteRest, t]
  );

  const endRoom = useCallback(async () => {
    emit("voiceroom:end-intent", { roomId });
    try {
      await endRoomRest(roomId).unwrap();
    } catch (err) {
      setError(voiceRoomErrorText(err, t));
      return;
    }
    go("ended");
    await teardown();
  }, [roomId, emit, endRoomRest, go, teardown, t]);

  // ---- leave on unmount / page close (best effort) ------------------------------
  const leaveRef = useRef(leave);
  leaveRef.current = leave;
  useEffect(() => {
    const onPageHide = () => {
      if (LIVE_PHASES.indexOf(phaseRef.current) > -1) leaveRef.current();
    };
    window.addEventListener("pagehide", onPageHide);
    return () => {
      window.removeEventListener("pagehide", onPageHide);
      if (LIVE_PHASES.indexOf(phaseRef.current) > -1) leaveRef.current();
      stopHeartbeat();
    };
  }, []);

  return {
    phase,
    error,
    role,
    hostId: state.hostId,
    members: selectMembers(state, peers),
    micOn,
    micProblem,
    handRaised,
    audioBlocked,
    chat: state.chat,
    join,
    leave,
    setMic,
    raiseHand,
    sendChat,
    startAudio,
    muteAll,
    promote,
    endRoom,
  };
}
