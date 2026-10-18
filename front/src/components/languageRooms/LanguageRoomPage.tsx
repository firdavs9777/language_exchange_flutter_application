import React, { useEffect, useRef, useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate, useParams, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Send, Circle, LogOut } from "lucide-react";
import { useSocket } from "../chat/hooks/useSocket";
import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "../chat/lib/socketAck";
import {
  useGetLanguageRoomQuery,
  useGetLanguageRoomMessagesQuery,
  useLazyGetLanguageRoomMessagesQuery,
  useJoinLanguageRoomMutation,
  useLeaveLanguageRoomMutation,
  useRequestJoinLanguageRoomMutation,
  languageRoomErrorText,
} from "../../store/slices/languageRoomsSlice";
import { mergeMessages, messageLabel, RoomMessage } from "./roomMessages";
import LanguageRoomOwnerPanel from "./LanguageRoomOwnerPanel";
import "../voiceRooms/VoiceRooms.scss";
import "./LanguageRooms.scss";

const senderName = (s: RoomMessage["sender"]) => (s && typeof s === "object" ? s.name || "" : "");
const senderId = (s: RoomMessage["sender"]) => (s && typeof s === "object" ? String(s._id) : s ? String(s) : "");

const LanguageRoomPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const myId = useSelector((s: any) => String((s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id) || ""));
  const { socket, connectionEpoch } = useSocket() as any;
  const { data: room, refetch: refetchRoom } = useGetLanguageRoomQuery(id, { skip: !id });
  const isMember = !!(room && room.isMember);
  const { data: page1 } = useGetLanguageRoomMessagesQuery({ roomId: id, page: 1 }, { skip: !id || !isMember });
  const [loadPage] = useLazyGetLanguageRoomMessagesQuery();
  const [joinRoom] = useJoinLanguageRoomMutation();
  const [leaveRoom] = useLeaveLanguageRoomMutation();
  const [requestJoin] = useRequestJoinLanguageRoomMutation();

  const [messages, setMessages] = useState<RoomMessage[]>([]);
  const [online, setOnline] = useState<number | null>(null);
  const [olderPage, setOlderPage] = useState(2);
  const [hasOlder, setHasOlder] = useState(false);
  const [text, setText] = useState("");
  const [sendError, setSendError] = useState("");
  const [actionError, setActionError] = useState("");

  useEffect(() => {
    if (!page1) return;
    setMessages((prev) => mergeMessages(prev, (page1.data || []) as RoomMessage[]));
    setHasOlder(!!(page1.pagination && page1.pagination.hasNextPage));
  }, [page1]);

  // Socket subscription: members only (the server refuses others).
  useEffect(() => {
    if (!socket || !id || !isMember) return;
    const onMessage = (m: any) => {
      if (!m || String(m.conversationId) !== String(id)) return;
      setMessages((prev) => mergeMessages(prev, [m]));
    };
    const onPresence = (p: any) => {
      if (p && String(p.roomId) === String(id)) setOnline(Number(p.online) || 0);
    };
    socket.on("room:message", onMessage);
    socket.on("room:presence", onPresence);
    socket.emit("room:join", { roomId: id });
    return () => {
      socket.off("room:message", onMessage);
      socket.off("room:presence", onPresence);
      socket.emit("room:leave", { roomId: id });
    };
    // connectionEpoch: a reconnected socket has left every socket room, so subscribe again.
  }, [socket, id, isMember, connectionEpoch]);

  const send = () => {
    const message = text.trim();
    if (!message || !socket) return;
    setSendError("");
    emitWithAck(socket, "room:message", { roomId: id, message, messageType: "text" }, SOCKET_ACK_TIMEOUT_MS, {
      onAck: (ack: any) => {
        if (ack && ack.status === "success") {
          if (ack.message) setMessages((prev) => mergeMessages(prev, [ack.message]));
          setText((current) => (current.trim() === message ? "" : current));
        } else {
          setSendError(/slow down/i.test(String(ack && ack.error)) ? t("languageRooms.room.slowDown") || "You're sending too fast. Slow down a little." : t("languageRooms.room.notSent") || "Not sent. Try again.");
        }
      },
      onTimeout: () => setSendError(t("languageRooms.room.notSent") || "Not sent. Try again."),
    });
  };

  const loadOlder = async () => {
    try {
      const res = await loadPage({ roomId: id, page: olderPage }).unwrap();
      setMessages((prev) => mergeMessages(prev, (res && res.data) || []));
      setHasOlder(!!(res && res.pagination && res.pagination.hasNextPage));
      setOlderPage((p) => p + 1);
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
  };

  const act = async (fn: () => Promise<any>) => {
    setActionError("");
    try {
      await fn();
      if (refetchRoom) refetchRoom();
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
  };

  const leave = async () => {
    try {
      await leaveRoom(id).unwrap();
      navigate("/rooms");
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
  };

  // Keep the newest message in view.
  const endRef = useRef<HTMLLIElement | null>(null);
  useEffect(() => {
    if (endRef.current && typeof endRef.current.scrollIntoView === "function") endRef.current.scrollIntoView({ block: "nearest" });
  }, [messages.length]);

  return (
    <section className="vr-page" data-testid="language-room-page">
      <header className="vr-page__head">
        <div>
          <Link to="/rooms" className="vr-link">
            {t("languageRooms.room.back") || "All rooms"}
          </Link>
          <h1>{(room && room.title) || ""}</h1>
        </div>
        {isMember && (
          <span className="lr-card__meta" data-testid="language-room-online">
            <Circle size={8} className="lr-online" aria-hidden /> {online === null ? (room && room.onlineCount) || 0 : online}{" "}
            {t("languageRooms.room.online") || "online"}
          </span>
        )}
      </header>
      {actionError && (
        <p className="vr-error" role="alert">
          {actionError}
        </p>
      )}

      {room && !isMember && (
        <div className="vr-room__gate">
          {room.description && <p>{room.description}</p>}
          {room.hasPendingRequest ? (
            <p data-testid="language-room-pending">{t("languageRooms.room.pending") || "Request sent. The owner will let you in."}</p>
          ) : room.isBanned ? (
            <button type="button" className="vr-btn vr-btn--primary" data-testid="language-room-request" onClick={() => act(() => requestJoin(id).unwrap())}>
              {t("languageRooms.room.request") || "Ask to join"}
            </button>
          ) : (
            <button type="button" className="vr-btn vr-btn--primary" data-testid="language-room-join" onClick={() => act(() => joinRoom(id).unwrap())}>
              {t("languageRooms.room.join") || "Join room"}
            </button>
          )}
        </div>
      )}

      {isMember && (
        <div className="lr-room">
          <div className="lr-thread">
            <ol className="lr-thread__lines">
              {hasOlder && (
                <li>
                  <button type="button" className="vr-link" data-testid="language-room-older" onClick={loadOlder}>
                    {t("languageRooms.room.older") || "Load earlier messages"}
                  </button>
                </li>
              )}
              {messages.map((m) =>
                m.messageType === "system" ? (
                  <li key={m._id} className="lr-line__system" data-testid="language-room-line">
                    {messageLabel(m, t)}
                  </li>
                ) : (
                  <li key={m._id} className={senderId(m.sender) === myId ? "lr-line is-mine" : "lr-line"} data-testid="language-room-line">
                    <strong>{senderName(m.sender)}</strong> <span>{messageLabel(m, t)}</span>
                  </li>
                )
              )}
              <li ref={endRef} aria-hidden />
            </ol>
            {sendError && (
              <p className="vr-error" role="alert" data-testid="language-room-send-error">
                {sendError}
              </p>
            )}
            <div className="lr-thread__compose">
              <input
                data-testid="language-room-input"
                value={text}
                maxLength={2000}
                placeholder={t("languageRooms.room.placeholder") || "Write in the room's language…"}
                onChange={(e) => setText(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") send();
                }}
              />
              <button type="button" className="vr-btn vr-btn--primary" data-testid="language-room-send" onClick={send} aria-label={t("languageRooms.room.send") || "Send"}>
                <Send size={16} />
              </button>
            </div>
          </div>
          <aside className="lr-side">
            {room && room.isOwnerOrAdmin && room.roomType === "topic" && <LanguageRoomOwnerPanel roomId={id} />}
            {!(room && room.isOwnerOrAdmin && room.owner === myId) && (
              <button type="button" className="vr-btn vr-btn--ghost" data-testid="language-room-leave" onClick={leave}>
                <LogOut size={14} /> {t("languageRooms.room.leave") || "Leave room"}
              </button>
            )}
          </aside>
        </div>
      )}
    </section>
  );
};

export default LanguageRoomPage;
