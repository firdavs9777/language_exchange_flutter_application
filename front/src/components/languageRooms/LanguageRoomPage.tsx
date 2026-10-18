import React, { useEffect, useMemo, useRef, useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate, useParams, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Send, Circle, ImagePlus, X, MessageCircleQuestion, ChevronRight } from "lucide-react";
import { useSocket } from "../chat/hooks/useSocket";
import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "../chat/lib/socketAck";
import ReplyComposerBar from "../chat/actions/ReplyComposerBar";
import { aggregateReactions } from "../chat/actions/ReactionRow";
import { useAddReactionMutation, useRemoveReactionMutation } from "../../store/slices/chatSlice";
import { useGetBlockedUsersQuery } from "../../store/slices/usersSlice";
import DialogShell from "../../design/DialogShell";
import ReportMomentDialog from "../moments/actions/ReportMomentDialog";
import { languageFlag } from "../../utils/languages";
import {
  useGetLanguageRoomQuery,
  useGetLanguageRoomMessagesQuery,
  useLazyGetLanguageRoomMessagesQuery,
  useJoinLanguageRoomMutation,
  useLeaveLanguageRoomMutation,
  useRequestJoinLanguageRoomMutation,
  useUploadLanguageRoomPhotoMutation,
  useDeleteLanguageRoomMessageMutation,
  languageRoomErrorText,
} from "../../store/slices/languageRoomsSlice";
import {
  mergeMessages,
  applyReactionUpdate,
  removeMessage,
  withoutBlocked,
  splitDailyPrompt,
  canDeleteMessage,
  senderIdOf,
  RoomMessage,
} from "./roomMessages";
import RoomMessageItem from "./RoomMessageItem";
import RoomInfoPanel from "./RoomInfoPanel";
import "../voiceRooms/VoiceRooms.scss";
import "./LanguageRooms.scss";

const TYPING_SEND_EVERY_MS = 3000;
const TYPING_SHOW_FOR_MS = 5000;

const LanguageRoomPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const myId = useSelector((s: any) => String((s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id) || ""));
  const { socket, connectionEpoch } = useSocket() as any;
  const { data: room, refetch: refetchRoom } = useGetLanguageRoomQuery(id, { skip: !id });
  const isMember = !!(room && room.isMember);
  const isBanned = !!(room && room.isBanned);
  const isModerator = !!(room && room.isOwnerOrAdmin);
  // Opening a room never joins it: a visitor reads the history and watches live.
  const canWatch = !!room && !isBanned;
  const { data: page1 } = useGetLanguageRoomMessagesQuery({ roomId: id, page: 1 }, { skip: !id || !canWatch });
  const [loadPage] = useLazyGetLanguageRoomMessagesQuery();
  const [joinRoom, { isLoading: joining }] = useJoinLanguageRoomMutation();
  const [leaveRoom] = useLeaveLanguageRoomMutation();
  const [requestJoin] = useRequestJoinLanguageRoomMutation();
  const [uploadPhoto, { isLoading: uploading }] = useUploadLanguageRoomPhotoMutation();
  const [deleteMessage] = useDeleteLanguageRoomMessageMutation();
  const [addReaction] = useAddReactionMutation();
  const [removeReaction] = useRemoveReactionMutation();
  const { data: blockedData } = useGetBlockedUsersQuery({ userId: myId }, { skip: !myId });
  const blockedIds: string[] = useMemo(
    () => ((blockedData && blockedData.data) || []).map((b: any) => String(b.userId || (b.user && b.user._id) || "")).filter(Boolean),
    [blockedData]
  );

  const [messages, setMessages] = useState<RoomMessage[]>([]);
  const [online, setOnline] = useState<number | null>(null);
  const [olderPage, setOlderPage] = useState(2);
  const [hasOlder, setHasOlder] = useState(false);
  const [text, setText] = useState("");
  const [sendError, setSendError] = useState("");
  const [actionError, setActionError] = useState("");
  const [replyingTo, setReplyingTo] = useState<RoomMessage | null>(null);
  const [photo, setPhoto] = useState<File | null>(null);
  const [typing, setTyping] = useState<{ [userId: string]: { name: string; at: number } }>({});
  const [showInfo, setShowInfo] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState<RoomMessage | null>(null);
  const [reporting, setReporting] = useState<RoomMessage | null>(null);
  const fileRef = useRef<HTMLInputElement | null>(null);
  const lastTypingSent = useRef(0);

  useEffect(() => {
    if (!page1) return;
    setMessages((prev) => mergeMessages(prev, (page1.data || []) as RoomMessage[]));
    setHasOlder(!!(page1.pagination && page1.pagination.hasNextPage));
  }, [page1]);

  // Live subscription: members and visitors alike (the server lets a
  // non-banned visitor watch; only sending needs membership).
  useEffect(() => {
    if (!socket || !id || !canWatch) return;
    const onMessage = (m: any) => {
      if (!m || String(m.conversationId) !== String(id)) return;
      setMessages((prev) => mergeMessages(prev, [m]));
      const sid = senderIdOf(m.sender);
      if (sid)
        setTyping((prev) => {
          if (!prev[sid]) return prev;
          const next = Object.assign({}, prev);
          delete next[sid];
          return next;
        });
    };
    const onPresence = (p: any) => {
      if (p && String(p.roomId) === String(id)) setOnline(Number(p.online) || 0);
    };
    const onTyping = (p: any) => {
      if (!p || String(p.roomId) !== String(id) || !p.userId || String(p.userId) === myId) return;
      const uid = String(p.userId);
      setTyping((prev) => {
        const next = Object.assign({}, prev);
        if (p.isTyping === false) delete next[uid];
        else next[uid] = { name: String(p.userName || ""), at: Date.now() };
        return next;
      });
    };
    const onReaction = (p: any) => setMessages((prev) => applyReactionUpdate(prev, p));
    const onDeleted = (p: any) => {
      if (p && String(p.roomId) === String(id) && p.messageId) setMessages((prev) => removeMessage(prev, String(p.messageId)));
    };
    const onRoomError = (p: any) => {
      if (p && p.message) setActionError(String(p.message));
    };
    socket.on("room:message", onMessage);
    socket.on("room:presence", onPresence);
    socket.on("room:typing", onTyping);
    socket.on("messageReaction", onReaction);
    socket.on("room:messageDeleted", onDeleted);
    socket.on("room:error", onRoomError);
    socket.emit("room:join", { roomId: id });
    return () => {
      socket.off("room:message", onMessage);
      socket.off("room:presence", onPresence);
      socket.off("room:typing", onTyping);
      socket.off("messageReaction", onReaction);
      socket.off("room:messageDeleted", onDeleted);
      socket.off("room:error", onRoomError);
      socket.emit("room:leave", { roomId: id });
    };
    // connectionEpoch: a reconnected socket has left every socket room, so subscribe again.
  }, [socket, id, canWatch, connectionEpoch, myId]);

  // Forget typists who went quiet without saying so.
  useEffect(() => {
    if (Object.keys(typing).length === 0) return;
    const timer = setTimeout(() => {
      const now = Date.now();
      setTyping((prev) => {
        const next: typeof prev = {};
        Object.keys(prev).forEach((k) => {
          if (prev[k] && now - prev[k].at < TYPING_SHOW_FOR_MS) next[k] = prev[k];
        });
        return next;
      });
    }, TYPING_SHOW_FOR_MS);
    return () => clearTimeout(timer);
  }, [typing]);

  const emitTyping = (isTyping: boolean) => {
    if (!socket || !isMember) return;
    const now = Date.now();
    if (isTyping && now - lastTypingSent.current < TYPING_SEND_EVERY_MS) return;
    lastTypingSent.current = isTyping ? now : 0;
    socket.emit("room:typing", { roomId: id, isTyping });
  };

  const failText = (err: any) =>
    /slow down/i.test(String(err || ""))
      ? t("languageRooms.room.slowDown") || "You're sending too fast. Slow down a little."
      : t("languageRooms.room.sendFailed") || "Failed to send message";

  const send = async () => {
    const message = text.trim();
    if (photo) {
      setSendError("");
      try {
        const res = await uploadPhoto({ roomId: id, file: photo, caption: message, replyTo: replyingTo ? replyingTo._id : undefined }).unwrap();
        if (res && res.data) setMessages((prev) => mergeMessages(prev, [res.data]));
        setPhoto(null);
        setText("");
        setReplyingTo(null);
        if (fileRef.current) fileRef.current.value = "";
      } catch (err) {
        setSendError(t("languageRooms.room.photoFailed") || "Couldn't send the photo. Try again.");
      }
      return;
    }
    if (!message || !socket) return;
    setSendError("");
    const payload: any = { roomId: id, message, messageType: "text" };
    if (replyingTo) payload.replyTo = replyingTo._id;
    emitTyping(false);
    emitWithAck(socket, "room:message", payload, SOCKET_ACK_TIMEOUT_MS, {
      onAck: (ack: any) => {
        if (ack && ack.status === "success") {
          if (ack.message) setMessages((prev) => mergeMessages(prev, [ack.message]));
          setText((current) => (current.trim() === message ? "" : current));
          setReplyingTo(null);
        } else {
          setSendError(failText(ack && ack.error));
        }
      },
      onTimeout: () => setSendError(failText("")),
    });
  };

  const pickPhoto = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files && e.target.files[0];
    if (!file) return;
    if (!/^image\//.test(file.type)) {
      setSendError(t("languageRooms.room.photosOnly") || "Only photos can be shared in rooms.");
      return;
    }
    setSendError("");
    setPhoto(file);
  };

  const react = async (m: RoomMessage, emoji: string) => {
    const mine = aggregateReactions(m.reactions as any, myId).find((r) => r.emoji === emoji && r.reactedByMe);
    try {
      const res: any = mine
        ? await removeReaction({ messageId: m._id, emoji }).unwrap()
        : await addReaction({ messageId: m._id, emoji }).unwrap();
      if (res && Array.isArray(res.data)) setMessages((prev) => applyReactionUpdate(prev, { messageId: m._id, reactions: res.data }));
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
  };

  const doDelete = async () => {
    const m = confirmDelete;
    setConfirmDelete(null);
    if (!m) return;
    try {
      await deleteMessage({ roomId: id, messageId: m._id }).unwrap();
      setMessages((prev) => removeMessage(prev, m._id));
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
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

  const join = () => act(() => joinRoom(id).unwrap());
  const askToJoin = () => act(() => requestJoin(id).unwrap());

  const leave = async () => {
    try {
      await leaveRoom(id).unwrap();
      navigate("/rooms");
    } catch (err) {
      setActionError(languageRoomErrorText(err, t));
    }
  };

  const visible = useMemo(() => withoutBlocked(messages, blockedIds), [messages, blockedIds]);
  const { prompt, thread } = useMemo(() => splitDailyPrompt(visible), [visible]);
  const typingNames = Object.keys(typing)
    .map((k) => typing[k].name)
    .filter(Boolean);
  const onlineNow = online === null ? (room && room.onlineCount) || 0 : online;

  // Keep the newest message in view.
  const endRef = useRef<HTMLLIElement | null>(null);
  useEffect(() => {
    if (endRef.current && typeof endRef.current.scrollIntoView === "function") endRef.current.scrollIntoView({ block: "nearest" });
  }, [thread.length]);

  return (
    <section className="vr-page" data-testid="language-room-page">
      <header className="vr-page__head">
        <div>
          <Link to="/rooms" className="vr-link">
            {t("languageRooms.room.back") || "All rooms"}
          </Link>
          <h1>
            {room ? (
              <button type="button" className="lr-title-btn" data-testid="language-room-title" onClick={() => setShowInfo(true)}>
                {room.emojiFlag || languageFlag(room.targetLanguage)} {room.title}
                <ChevronRight size={18} aria-hidden />
              </button>
            ) : (
              ""
            )}
          </h1>
        </div>
        {canWatch && (
          <span className="lr-card__meta" data-testid="language-room-online">
            <Circle size={8} className="lr-online" aria-hidden /> {onlineNow} {t("languageRooms.room.online") || "online"}
          </span>
        )}
      </header>
      {actionError && (
        <p className="vr-error" role="alert">
          {actionError}
        </p>
      )}

      {room && isBanned && (
        <div className="vr-room__gate">
          {room.hasPendingRequest ? (
            <p data-testid="language-room-pending">{t("languageRooms.room.pending") || "Request sent. The owner will let you in."}</p>
          ) : (
            <>
              <p>{t("languageRooms.errors.banned") || "You were removed from this room. You can ask the owner to let you back in."}</p>
              <button type="button" className="vr-btn vr-btn--primary" data-testid="language-room-request" onClick={askToJoin}>
                {t("languageRooms.room.request") || "Ask to join"}
              </button>
            </>
          )}
        </div>
      )}

      {canWatch && (
        <div className="lr-thread">
          {prompt && (
            <div className="lr-prompt" data-testid="language-room-prompt">
              <MessageCircleQuestion size={18} aria-hidden />
              <div>
                <strong>{t("languageRooms.room.questionOfDay") || "Question of the day"}</strong>
                <p>{prompt.message}</p>
              </div>
            </div>
          )}
          <ol className="lr-thread__lines">
            {hasOlder && (
              <li>
                <button type="button" className="vr-link" data-testid="language-room-older" onClick={loadOlder}>
                  {t("languageRooms.room.older") || "Load earlier messages"}
                </button>
              </li>
            )}
            {thread.map((m) => (
              <RoomMessageItem
                key={m._id}
                message={m}
                myId={myId}
                canInteract={isMember}
                canDelete={canDeleteMessage(m, myId, isModerator)}
                onReply={(msg) => setReplyingTo(msg)}
                onReact={react}
                onDelete={(msg) => setConfirmDelete(msg)}
                onReport={(msg) => setReporting(msg)}
              />
            ))}
            <li ref={endRef} aria-hidden />
          </ol>
          {typingNames.length > 0 && (
            <p className="lr-typing" data-testid="language-room-typing">
              {t("languageRooms.room.typing", { name: typingNames.join(", ") }) || `${typingNames.join(", ")} is typing…`}
            </p>
          )}
          {sendError && (
            <p className="vr-error" role="alert" data-testid="language-room-send-error">
              {sendError}
            </p>
          )}
          {isMember ? (
            <>
              <ReplyComposerBar replyingTo={replyingTo} onCancel={() => setReplyingTo(null)} />
              {photo && (
                <div className="lr-photo-chip" data-testid="language-room-photo-chip">
                  <ImagePlus size={14} aria-hidden /> <span>{photo.name}</span>
                  <button
                    type="button"
                    className="lr-icon-btn"
                    aria-label={t("languageRooms.room.removePhoto") || "Remove photo"}
                    onClick={() => {
                      setPhoto(null);
                      if (fileRef.current) fileRef.current.value = "";
                    }}
                  >
                    <X size={14} />
                  </button>
                </div>
              )}
              <div className="lr-thread__compose">
                <input ref={fileRef} type="file" accept="image/*" hidden data-testid="language-room-photo-input" onChange={pickPhoto} />
                <button
                  type="button"
                  className="vr-btn vr-btn--ghost"
                  data-testid="language-room-photo"
                  aria-label={t("languageRooms.room.addPhoto") || "Add a photo"}
                  onClick={() => fileRef.current && fileRef.current.click()}
                >
                  <ImagePlus size={16} />
                </button>
                <input
                  data-testid="language-room-input"
                  value={text}
                  maxLength={2000}
                  placeholder={photo ? t("languageRooms.room.caption") || "Add a caption (optional)" : t("languageRooms.room.placeholder") || "Write in the room's language…"}
                  onChange={(e) => {
                    setText(e.target.value);
                    emitTyping(e.target.value.length > 0);
                  }}
                  onBlur={() => emitTyping(false)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") send();
                  }}
                />
                <button
                  type="button"
                  className="vr-btn vr-btn--primary"
                  data-testid="language-room-send"
                  disabled={uploading}
                  onClick={send}
                  aria-label={t("languageRooms.room.send") || "Send"}
                >
                  <Send size={16} />
                </button>
              </div>
            </>
          ) : (
            <div className="lr-thread__compose">
              <button type="button" className="vr-btn vr-btn--primary lr-join-bar" data-testid="language-room-join" disabled={joining} onClick={join}>
                {t("languageRooms.room.join") || "Join room"}
              </button>
            </div>
          )}
        </div>
      )}

      {showInfo && room && (
        <RoomInfoPanel
          room={room}
          online={onlineNow}
          myId={myId}
          onClose={() => setShowInfo(false)}
          onJoin={() => {
            setShowInfo(false);
            join();
          }}
          onLeave={() => {
            setShowInfo(false);
            leave();
          }}
          onRequestJoin={() => {
            setShowInfo(false);
            askToJoin();
          }}
        />
      )}

      {confirmDelete && (
        <DialogShell labelledBy="lr-delete-title" onClose={() => setConfirmDelete(null)} testId="lr-delete-dialog">
          <h2 id="lr-delete-title" className="text-lg font-semibold text-ink-900 dark:text-ink-50">
            {t("languageRooms.room.deleteTitle") || "Delete this message?"}
          </h2>
          <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">{t("languageRooms.room.deleteBody") || "It will be removed for everyone in the room."}</p>
          <div className="vr-dialog__actions mt-4">
            <button type="button" className="vr-btn vr-btn--ghost" onClick={() => setConfirmDelete(null)}>
              {t("common.cancel") || "Cancel"}
            </button>
            <button type="button" className="vr-btn vr-btn--danger" data-testid="lr-delete-confirm" onClick={doDelete}>
              {t("languageRooms.room.delete") || "Delete"}
            </button>
          </div>
        </DialogShell>
      )}

      {reporting && (
        <ReportMomentDialog type="message" targetId={reporting._id} authorId={senderIdOf(reporting.sender)} onClose={() => setReporting(null)} />
      )}
    </section>
  );
};

export default LanguageRoomPage;
