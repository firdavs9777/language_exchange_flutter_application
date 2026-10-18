import React, {
  useState,
  useEffect,
  useLayoutEffect,
  useRef,
  useCallback,
  useMemo,
} from "react";
import { useDispatch, useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import {
  chatApiSlice,
  useCreateMessageMutation,
  useGetConversationQuery,
  useSendVoiceMessageMutation,
  useSendMediaMessageMutation,
  useSendVideoMessageMutation,
  useGetVideoMessageConfigQuery,
  useEditMessageMutation,
  useDeleteMessageMutation,
  useAddReactionMutation,
  useRemoveReactionMutation,
  usePinMessageMutation,
  useBookmarkMessageMutation,
  useForwardMessageMutation,
  useReplyToMessageMutation,
  useTtsMessageMutation,
} from "../../store/slices/chatSlice";
import "./ChatContent.css";
import MessageActionMenu from "./actions/MessageActionMenu";
import ForwardDialog from "./actions/ForwardDialog";
import EditMessageDialog, { editErrorText } from "./actions/EditMessageDialog";
import DeleteMessageDialog, { deleteErrorText } from "./actions/DeleteMessageDialog";
import SendErrorDialog from "./actions/SendErrorDialog";
import ConnectionBanner from "./ConnectionBanner";
import { classifySendError } from "./lib/sendErrors";
import { emitWithAck, SOCKET_ACK_TIMEOUT_MS } from "./lib/socketAck";
import { checkVideo, limitsFromConfig, readVideoDuration } from "./lib/videoLimits";
import { pickRecorderMime, extForMime, baseMime } from "../../utils/recorderMime";
import { computeWaveform } from "../../utils/audioWaveform";
import notify from "../../design/notify";
import PinnedBar from "./actions/PinnedBar";
import ReplyComposerBar from "./actions/ReplyComposerBar";
import { canDeleteForEveryone } from "./lib/messageActions";
import StickerPanel from "./StickerPanel";
import "./StickerPanel.css";
import GifPickerPanel from "./GifPickerPanel";
import { useSocket } from "./hooks/useSocket";
import CorrectionModal from "./components/CorrectionModal";
import MessageBubble, {
  DateSeparator,
  formatDuration,
  Message,
  MessageReceiver,
  MessageStatus,
} from "./MessageBubble";
import { useSendCorrectionMutation } from "../../store/slices/learningSlice";
import {
  ArrowLeft,
  MoreVertical,
  Paperclip,
  Smile,
  Send,
  Mic,
  AlertCircle,
  ArrowUp,
  ArrowDown,
  X,
  Image as ImageIcon,
  FileImage,
  Search,
} from "lucide-react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import ChatInfoPanel from "./ChatInfoPanel";
import LocationShareButton from "./components/LocationShareButton";
import MessageSearchDialog from "./components/MessageSearchDialog";
import BlockedChatBanner from "./components/BlockedChatBanner";
import CallInAppButtons from "./components/CallInAppButtons";
import { useChatBlockState } from "./lib/useChatBlockState";
import { normalizeMessage, senderIdOf } from "./lib/normalizeMessage";
import { useOpenStoryFromChat } from "./lib/useOpenStoryFromChat";

interface RootState {
  auth: {
    userInfo: {
      user: {
        _id: string;
        name?: string;
        username?: string;
        imageUrls?: string[];
      };
      token: string;
    };
  };
}

interface ChatContentProps {
  selectedUser: string;
  userName: string;
  profilePicture: string;
  initialIsOnline?: boolean;
  initialLastSeen?: string;
}

// How far along a message is. A page fetch must never pull a tick back from
// where the socket has already taken it.
const STATUS_ORDER: { [status: string]: number } = {
  error: -1,
  sending: 0,
  sent: 1,
  delivered: 2,
  read: 3,
};
const statusRank = (status?: string): number =>
  status && STATUS_ORDER[status] !== undefined ? STATUS_ORDER[status] : 0;

// Matches the backend's own default for
// GET /messages/conversation/:senderId/:receiverId.
const MESSAGE_PAGE_SIZE = 50;

// "Deleted for everyone" stays on screen as the app's placeholder; only
// "deleted for me" removes the bubble.
const DELETED_PATCH: Partial<Message> = {
  isDeleted: true,
  deletedForEveryone: true,
  message: "This message was deleted",
  media: undefined,
  reactions: [],
};

const getReceiverId = (receiver: MessageReceiver | string): string => {
  if (typeof receiver === "object" && receiver !== null) {
    return receiver._id;
  }
  return receiver;
};

const ChatContent: React.FC<ChatContentProps> = ({
  selectedUser,
  userName,
  profilePicture,
  initialIsOnline = false,
  initialLastSeen = "",
}) => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const userId = useSelector(
    (state: RootState) => state.auth.userInfo?.user?._id
  );
  const currentUserName = useSelector(
    (state: RootState) => state.auth.userInfo?.user?.name
  );

  // History paging. The backend answers 50 messages per page, newest page
  // first; `page` walks BACKWARDS in time and the endpoint merges each older
  // page into the same cache entry, so `data.data` is always the whole thread
  // loaded so far, oldest first.
  const [page, setPage] = useState(1);
  const { data, error, isLoading, isFetching } = useGetConversationQuery(
    {
      senderId: userId,
      receiverId: selectedUser,
      page,
      limit: MESSAGE_PAGE_SIZE,
    },
    {
      skip: !userId || !selectedUser,
      // Re-entering a thread has to reach the server. The cache entry is keyed
      // on the pair alone (serializeQueryArgs drops `page`) and outlives this
      // component, and its `forceRefetch` only fires when `page` changes — so
      // coming back to a conversation with `page` reset to 1 was a plain cache
      // hit, and anything that arrived while the thread was closed (nothing
      // mounted to catch the socket event) stayed invisible until a reload.
      refetchOnMountOrArgChange: true,
    }
  );

  // How much of the thread the merged cache entry holds versus how long the
  // thread is. NOT `page < totalPages`: the entry outlives the component
  // (`keepUnusedDataFor`), while `page` resets to 1 on every remount and
  // conversation switch — so re-opening a thread inside the cache window used
  // to offer "Load earlier messages" for pages already merged, one pointless
  // request per click.
  const loadedCount = ((data as any)?.data || []).length;
  const totalMessages = (data as any)?.total || 0;
  // `totalPages` is read from whichever shape the response carries — the
  // route returns `pagination.totalPages`, other handlers answer `pages` —
  // and falls back to what `total` implies. Reading only one of them capped
  // paging at page 1 and the thread's history was unreachable again.
  const totalPages =
    (data as any)?.pagination?.totalPages ||
    (data as any)?.pages ||
    (totalMessages ? Math.ceil(totalMessages / MESSAGE_PAGE_SIZE) : 1);
  const totalPagesRef = useRef(1);
  const loadedCountRef = useRef(0);
  const pageRef = useRef(1);
  const hasMoreHistory = loadedCount < totalMessages;
  // Whether an OLDER-page request is in flight, tracked from the request
  // itself. Inferring it from `isFetching && page > 1` made every reaction and
  // every pin (both invalidate the conversation) say "Loading earlier
  // messages" at the top of a thread the reader had paged back through.
  const [isLoadingOlder, setIsLoadingOlder] = useState(false);

  const [createMessage] = useCreateMessageMutation();
  const [sendVoiceMessage] = useSendVoiceMessageMutation();
  const [sendMediaMessage] = useSendMediaMessageMutation();
  const [sendVideoMessage] = useSendVideoMessageMutation();
  const { data: videoConfig } = useGetVideoMessageConfigQuery(undefined);

  // ===== Message actions (Task 6 wiring) =====
  const [editMessage] = useEditMessageMutation();
  const [deleteMessageApi] = useDeleteMessageMutation();
  const [addReaction] = useAddReactionMutation();
  const [removeReaction] = useRemoveReactionMutation();
  const [pinMessage] = usePinMessageMutation();
  const [bookmarkMessage] = useBookmarkMessageMutation();
  const [forwardMessage] = useForwardMessageMutation();
  const [replyToMessage] = useReplyToMessageMutation();
  const [ttsMessage] = useTtsMessageMutation();

  // Message-action UI state
  const [activeActionMsg, setActiveActionMsg] = useState<Message | null>(null);
  const [replyingTo, setReplyingTo] = useState<Message | null>(null);
  const [forwardMsg, setForwardMsg] = useState<Message | null>(null);
  const [editingMsg, setEditingMsg] = useState<Message | null>(null);
  const [editBusy, setEditBusy] = useState(false);
  const [editError, setEditError] = useState("");
  const [deletingMsg, setDeletingMsg] = useState<Message | null>(null);
  const [deleteBusy, setDeleteBusy] = useState(false);
  const [deleteError, setDeleteError] = useState("");
  const [sendError, setSendError] = useState<{ kind: any; detail: string } | null>(null);

  // The "⋯" panel: profile, media, mute, wallpaper, block, report, delete.
  const [isInfoOpen, setIsInfoOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);

  const [newMessage, setNewMessage] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [isTyping, setIsTyping] = useState(false);
  const [isOnline, setIsOnline] = useState(initialIsOnline);
  const [lastSeen, setLastSeen] = useState<string>(initialLastSeen);
  const [isSending, setIsSending] = useState(false);

  // Media upload state
  const [mediaPreview, setMediaPreview] = useState<{ file: File; url: string; type: string } | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Voice recording state
  const [isRecording, setIsRecording] = useState(false);
  const [recordingDuration, setRecordingDuration] = useState(0);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const recorderMimeRef = useRef<string>("");
  const recordingIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const audioStreamRef = useRef<MediaStream | null>(null);

  // Voice playback state
  const [playingAudioId, setPlayingAudioId] = useState<string | null>(null);
  const [audioProgress, setAudioProgress] = useState<number>(0); // 0-1
  const [audioElapsed, setAudioElapsed] = useState<number>(0);
  const audioPlayerRef = useRef<HTMLAudioElement | null>(null);

  // Sticker panel state
  const [isStickerPanelOpen, setIsStickerPanelOpen] = useState(false);
  const [isGifPanelOpen, setIsGifPanelOpen] = useState(false);

  // Correction modal state
  const [correctingMessage, setCorrectingMessage] = useState<Message | null>(null);
  const [sendCorrection, { isLoading: isSendingCorrection }] = useSendCorrectionMutation();

  // Open translation cards, keyed by message _id
  const [openTranslations, setOpenTranslations] = useState<Set<string>>(new Set());
  const toggleTranslation = useCallback((messageId: string) => {
    setOpenTranslations((prev) => {
      const next = new Set(prev);
      if (next.has(messageId)) next.delete(messageId);
      else next.add(messageId);
      return next;
    });
  }, []);

  // Translation target language — defaults to i18n locale, falls back to 'en'
  const targetLanguage = (i18n.language || "en").split("-")[0].toLowerCase();

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const chatContainerRef = useRef<HTMLDivElement>(null);
  const typingTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const typingClearRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const selectedUserRef = useRef<string>(selectedUser);
  // The socket listeners are bound once per socket; they reach the current
  // reportSendError through this ref instead of re-binding on every render.
  const reportSendErrorRef = useRef<(err: any) => void>(() => {});
  // Which conversation the local list was last seeded from — a page of a
  // DIFFERENT conversation must not inherit this one's live messages.
  const seededUserRef = useRef<string>("");
  // The server objects the current local copies were built from, so an
  // unchanged message can keep its identity across a refetch.
  const seedSourceRef = useRef<{ [id: string]: any }>({});
  const isAtBottomRef = useRef(true);
  // The ref is what the scroll logic reads inside effects that must not re-run.
  // This is the same answer in a form the UI can render off: without it the
  // thread had a way UP through its history and no way back down.
  const [isAtBottom, setIsAtBottom] = useState(true);
  // How much landed while the reader was up in the history. Counted in one
  // place (the auto-scroll effect below) so every kind of message — text,
  // reply, sticker, voice, video — is counted without each handler knowing.
  const [missedCount, setMissedCount] = useState(0);
  const seenCountRef = useRef(0);
  const topSentinelRef = useRef<HTMLDivElement>(null);
  // The message the viewport was anchored on when an older page was asked for.
  const pendingOlderRef = useRef<{ id: string; top: number } | null>(null);
  // An older-page request is in flight.
  const olderRequestRef = useRef(false);
  // Whether the top sentinel is inside the viewport right now.
  const sentinelVisibleRef = useRef(false);
  // The previous value of `isFetching`, to catch the settling edge.
  const wasFetchingRef = useRef(false);
  // The conversation whose first page has already been scrolled to the bottom.
  const openedAtBottomRef = useRef<string>("");

  // Read here, seeded further down -- see the draft effect below the
  // "Clear state when switching conversations" effect.
  const [searchParams, setSearchParams] = useSearchParams();
  const draftSeededRef = useRef(false);

  // Shared socket
  const { socket, emit, connectionEpoch } = useSocket() as any;
  const openStory = useOpenStoryFromChat();
  const blockState = useChatBlockState(userId, selectedUser);

  // Keep selectedUserRef in sync
  useEffect(() => {
    selectedUserRef.current = selectedUser;
  }, [selectedUser]);

  useEffect(() => {
    totalPagesRef.current = totalPages;
    loadedCountRef.current = loadedCount;
    pageRef.current = page;
  }, [totalPages, loadedCount, page]);

  // Update online status when initial props change
  useEffect(() => {
    setIsOnline(initialIsOnline);
    setLastSeen(initialLastSeen);
  }, [initialIsOnline, initialLastSeen, selectedUser]);

  // A message the socket delivered belongs in the CACHE, not only on screen.
  //
  // The seeding effect below rebuilds local state from the `getConversation`
  // entry wholesale whenever the conversation changes, so anything that lived
  // only in state — every message the socket brought in while this thread was
  // open — was thrown away the moment the reader visited another room and came
  // back. It reappeared only after the network answered again.
  //
  // `updateQueryData` patches an entry that already exists and no-ops when it
  // does not, which is exactly right: a thread nobody is holding gets fetched
  // fresh on its next open.
  const rememberInThread = useCallback(
    (message: Message | undefined, partnerId: string | undefined) => {
      if (!message || !message._id || !userId || !partnerId) return;
      dispatch(
        (chatApiSlice.util as any).updateQueryData(
          "getConversation",
          { senderId: userId, receiverId: partnerId, page: 1, limit: MESSAGE_PAGE_SIZE },
          (draft: any) => {
            if (!draft) return;
            if (!Array.isArray(draft.data)) draft.data = [];
            const at = draft.data.findIndex((m: any) => m && m._id === message._id);
            if (at >= 0) draft.data[at] = { ...draft.data[at], ...message };
            else draft.data.push(message);
            draft.count = draft.data.length;
          }
        )
      );
    },
    [dispatch, userId]
  );

  // The other half of rememberInThread: a message that is GONE.
  //
  // `merge` on the getConversation entry only adds incoming messages and
  // updates ones it already holds — it has no branch that removes. So
  // invalidating the tag after a delete refetches the thread, merges it, and
  // leaves the deleted message sitting in the cache. Local state is rebuilt
  // from that cache wholesale on a conversation switch, so a message deleted
  // here came back the moment the reader stepped into another room and
  // returned.
  const forgetFromThread = useCallback(
    (messageId: string | undefined, partnerId: string | undefined) => {
      if (!messageId || !userId || !partnerId) return;
      dispatch(
        (chatApiSlice.util as any).updateQueryData(
          "getConversation",
          { senderId: userId, receiverId: partnerId, page: 1, limit: MESSAGE_PAGE_SIZE },
          (draft: any) => {
            if (!draft || !Array.isArray(draft.data)) return;
            const at = draft.data.findIndex((m: any) => m && m._id === messageId);
            if (at < 0) return;
            draft.data.splice(at, 1);
            draft.count = draft.data.length;
          }
        )
      );
    },
    [dispatch, userId]
  );

  // Change a message the cache already holds, without adding one it does not.
  //
  // An edit or reaction WE make goes through a mutation that invalidates the
  // Conversation tag, so the refetch carries it and `merge` updates the
  // message in place. One that ARRIVES over the socket only reached local
  // state — which is rebuilt from the cache on a conversation switch, so the
  // pre-edit text and the missing reaction came back until a refetch landed.
  const patchInThread = useCallback(
    (messageId: string | undefined, patch: Partial<Message>, partnerId: string | undefined) => {
      if (!messageId || !userId || !partnerId) return;
      dispatch(
        (chatApiSlice.util as any).updateQueryData(
          "getConversation",
          { senderId: userId, receiverId: partnerId, page: 1, limit: MESSAGE_PAGE_SIZE },
          (draft: any) => {
            if (!draft || !Array.isArray(draft.data)) return;
            const at = draft.data.findIndex((m: any) => m && m._id === messageId);
            if (at < 0) return;
            draft.data[at] = { ...draft.data[at], ...patch };
          }
        )
      );
    },
    [dispatch, userId]
  );

  // ========== Socket event listeners (shared socket) ==========
  useEffect(() => {
    if (!socket) return;

    const handleNewMessage = (notificationData: {
      message: Message;
      unreadCount: number;
      senderId?: string;
    }) => {
      console.log("[ChatContent] newMessage received:", notificationData);
      const newMsg = normalizeMessage(notificationData.message);
      const currentSelectedUser = selectedUserRef.current;

      const receiverId = getReceiverId(newMsg.receiver);
      const isFromCurrentConversation =
        newMsg.sender._id === currentSelectedUser ||
        receiverId === currentSelectedUser ||
        notificationData.senderId === currentSelectedUser;

      console.log("[ChatContent] newMessage check:", {
        senderId: newMsg.sender._id,
        receiverId,
        notifSenderId: notificationData.senderId,
        currentSelectedUser,
        isFromCurrentConversation,
      });

      if (isFromCurrentConversation) {
        setMessages((prev) => {
          if (prev.some((msg) => msg._id === newMsg._id)) {
            console.log("[ChatContent] Duplicate message, skipping");
            return prev;
          }
          console.log("[ChatContent] Adding message to state");
          return [...prev, { ...newMsg, status: "delivered" }];
        });
        rememberInThread(newMsg, currentSelectedUser);

        if (newMsg.sender._id === currentSelectedUser && socket.connected) {
          socket.emit("markAsRead", { senderId: currentSelectedUser });
        }
      }
    };

    const handleMediaMessage = (data: { message: Message }) => {
      const newMsg = normalizeMessage(data.message);
      const currentSelectedUser = selectedUserRef.current;

      const receiverId = getReceiverId(newMsg.receiver);
      const isFromCurrentConversation =
        newMsg.sender._id === currentSelectedUser ||
        receiverId === currentSelectedUser;

      if (isFromCurrentConversation) {
        setMessages((prev) => {
          if (prev.some((msg) => msg._id === newMsg._id)) return prev;
          return [...prev, { ...newMsg, status: "delivered" }];
        });
        rememberInThread(newMsg, currentSelectedUser);

        if (newMsg.sender._id === currentSelectedUser && socket.connected) {
          socket.emit("markAsRead", { senderId: currentSelectedUser });
        }
      }
    };

    const handleMessageSent = (data: { message: Message; receiverId: string }) => {
      const sent = normalizeMessage(data.message);
      const currentSelectedUser = selectedUserRef.current;
      if (data.receiverId === currentSelectedUser) {
        setMessages((prev) => {
          // The server has the message. One tick; `messageDelivered` upgrades
          // it to two when the other person's client picks it up.
          if (prev.some((msg) => msg._id === sent._id)) {
            return prev.map((msg) =>
              msg._id === sent._id && statusRank(msg.status) < statusRank("sent")
                ? { ...msg, status: "sent" }
                : msg
            );
          }
          // This tab is now among the sockets the server addresses (io.to,
          // not socket.to), so this event can be the FIRST word we get about
          // a message we sent ourselves — if the ack was lost, or arrives
          // after. The optimistic bubble is still standing under a temp id, so
          // adopt it rather than land a second copy of the same message beside
          // it. Matched on the body: a temp id is ours alone and the server
          // never knew it.
          // A bubble that timed out is still ours under its temp id: the
          // server may well have the message (it creates before it acks).
          const pending = prev.findIndex(
            (msg) =>
              (msg.isOptimistic ||
                (msg.status === "error" && String(msg._id).indexOf("temp-") === 0)) &&
              (msg.message || "") === (sent.message || "")
          );
          if (pending >= 0) {
            const next = [...prev];
            next[pending] = { ...sent, status: "sent" };
            return next;
          }
          return [...prev, { ...sent, status: "sent" }];
        });
        rememberInThread(sent, currentSelectedUser);
      }
    };

    // The other person's client has the message (or the server stamped a
    // backlog one on their reconnect): one tick becomes two.
    const handleMessageDelivered = (data: { messageId: string }) => {
      if (!data || !data.messageId) return;
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === data.messageId && statusRank(msg.status) < statusRank("delivered")
            ? { ...msg, status: "delivered" }
            : msg
        )
      );
    };

    const handleMessagesRead = (data: { readBy: string }) => {
      if (data.readBy === selectedUserRef.current) {
        setMessages((prev) =>
          prev.map((msg) => {
            // A message that failed, or is still going out, was never read by
            // anyone — "Failed" next to its Retry button must not turn into a
            // read receipt because the other person opened the thread.
            if (
              msg.sender._id === userId &&
              msg.status !== "error" &&
              !msg.isOptimistic
            ) {
              return { ...msg, status: "read", read: true, readAt: new Date().toISOString() };
            }
            return msg;
          })
        );
      }
    };

    const handleMessageDeleted = (data: {
      messageId: string;
      deletedForEveryone?: boolean;
    }) => {
      if (!data || !data.messageId) return;
      const id = String(data.messageId);
      if (data.deletedForEveryone) {
        setMessages((prev) => prev.map((m) => (m._id === id ? { ...m, ...DELETED_PATCH } : m)));
        patchInThread(id, DELETED_PATCH, selectedUserRef.current);
        return;
      }
      // Deleted for me on another of my devices.
      setMessages((prev) => prev.filter((msg) => msg._id !== id));
      forgetFromThread(id, selectedUserRef.current);
    };

    const handleUserTyping = (data: { userId: string }) => {
      if (data.userId === selectedUserRef.current) {
        setIsTyping(true);
        if (typingClearRef.current) clearTimeout(typingClearRef.current);
        typingClearRef.current = setTimeout(() => setIsTyping(false), 4000);
      }
    };

    const handleUserStoppedTyping = (data: { userId: string }) => {
      if (data.userId === selectedUserRef.current) {
        setIsTyping(false);
        if (typingClearRef.current) {
          clearTimeout(typingClearRef.current);
          typingClearRef.current = null;
        }
      }
    };

    const handleUserStatusUpdate = (data: { userId: string; status: string; lastSeen?: string }) => {
      if (data.userId === selectedUserRef.current) {
        setIsOnline(data.status === "online");
        if (data.lastSeen) setLastSeen(data.lastSeen);
      }
    };

    // A refusal for an emit that carried no callback (ours always do, so this
    // is defensive) -- explain it all the same.
    const handleMessageError = (errorData: { message?: string; error?: string }) => {
      reportSendErrorRef.current(errorData);
    };

    const handleMessageCorrection = (data: {
      messageId: string;
      correction: MessageCorrection;
    }) => {
      if (!data?.messageId || !data?.correction) return;
      setMessages((prev) =>
        prev.map((m) => {
          if (m._id !== data.messageId) return m;
          const existing = m.corrections || [];
          if (existing.some((c) => c._id === data.correction._id)) return m;
          return { ...m, corrections: [...existing, data.correction] };
        })
      );
    };

    const handleCorrectionAccepted = (data: {
      messageId: string;
      correctionId: string;
      acceptedBy: string;
    }) => {
      if (!data?.messageId || !data?.correctionId) return;
      setMessages((prev) =>
        prev.map((m) => {
          if (m._id !== data.messageId) return m;
          const updated = (m.corrections || []).map((c) =>
            c._id === data.correctionId ? { ...c, isAccepted: true } : c
          );
          return { ...m, corrections: updated };
        })
      );
    };

    const handleMessageEdited = (data: {
      messageId: string;
      message?: Message;
      editedAt?: string;
    }) => {
      if (!data?.messageId) return;
      setMessages((prev) =>
        prev.map((m) => {
          if (m._id !== data.messageId) return m;
          if (data.message) {
            return {
              ...m,
              ...data.message,
              isEdited: true,
              editedAt: data.editedAt || data.message?.editedAt,
            };
          }
          return { ...m, isEdited: true, editedAt: data.editedAt };
        })
      );
      patchInThread(
        data.messageId,
        {
          ...(data.message || {}),
          isEdited: true,
          editedAt: data.editedAt || data.message?.editedAt,
        } as Partial<Message>,
        selectedUserRef.current
      );
    };

    const handleMessageReaction = (data: {
      messageId: string;
      reactions: Array<{ user: string; emoji: string; createdAt?: string }>;
    }) => {
      if (!data?.messageId) return;
      setMessages((prev) =>
        prev.map((m) =>
          m._id === data.messageId ? { ...m, reactions: data.reactions || [] } : m
        )
      );
      patchInThread(
        data.messageId,
        { reactions: data.reactions || [] } as Partial<Message>,
        selectedUserRef.current
      );
    };

    // The other participant pinned or unpinned a message (messageManagement.js
    // pinMessage). The server keeps ONE pinned message per pair, so a new pin
    // unpins the rest — but only for the conversation this pin belongs to: the
    // event reaches us whatever thread is open.
    const handleMessagePinned = (data: { messageId: string; pinned: boolean }) => {
      if (!data || !data.messageId) return;
      const id = String(data.messageId);
      const pinned = Boolean(data.pinned);
      const repin = (list: any[]): any[] =>
        list.map((m: any) => {
          if (!m) return m;
          if (m._id === id) return m.pinned === pinned ? m : { ...m, pinned: pinned };
          if (pinned && m.pinned) return { ...m, pinned: false };
          return m;
        });
      setMessages((prev) => (prev.some((m) => m._id === id) ? (repin(prev) as Message[]) : prev));
      // The same change in the thread cache, so a conversation switch does not
      // bring the old pin back. One updater for the target AND the unpinned
      // rest; a thread that does not hold the id is left alone.
      if (userId && selectedUserRef.current) {
        dispatch(
          (chatApiSlice.util as any).updateQueryData(
            "getConversation",
            { senderId: userId, receiverId: selectedUserRef.current, page: 1, limit: MESSAGE_PAGE_SIZE },
            (draft: any) => {
              if (!draft || !Array.isArray(draft.data)) return;
              if (!draft.data.some((m: any) => m && m._id === id)) return;
              draft.data = repin(draft.data);
            }
          )
        );
      }
    };

    // The burst limiter refuses with this push and NO ack, so the newest
    // in-flight bubble would otherwise spin until the ack timeout.
    const handleMessageSendError = (errorData: { error?: string }) => {
      setMessages((prev) => {
        for (let i = prev.length - 1; i >= 0; i -= 1) {
          const m = prev[i];
          if (m.isOptimistic && m.status === "sending") {
            const next = [...prev];
            next[i] = { ...m, status: "error", isOptimistic: false };
            return next;
          }
        }
        return prev;
      });
      reportSendErrorRef.current(errorData);
    };

    const handleQueuedMessages = (
      batch: Array<{ message: Message; senderId?: string }>
    ) => {
      if (!Array.isArray(batch) || batch.length === 0) return;
      const currentSelectedUser = selectedUserRef.current;
      setMessages((prev) => {
        const existingIds = new Set(prev.map((m) => m._id));
        const incoming = batch
          .map((entry) => (entry && entry.message ? normalizeMessage(entry.message) : undefined))
          .filter((msg): msg is Message => {
            if (!msg || !msg._id || existingIds.has(msg._id)) return false;
            const receiverId = getReceiverId(msg.receiver);
            return (
              msg.sender._id === currentSelectedUser ||
              receiverId === currentSelectedUser
            );
          })
          .map((msg) => ({ ...msg, status: "delivered" as const }));
        return incoming.length > 0 ? [...prev, ...incoming] : prev;
      });
    };

    socket.on("newMessage", handleNewMessage);
    socket.on("newVoiceMessage", handleMediaMessage);
    socket.on("newVideoMessage", handleMediaMessage);
    socket.on("messageSent", handleMessageSent);
    socket.on("messageDelivered", handleMessageDelivered);
    socket.on("messagesRead", handleMessagesRead);
    socket.on("messageDeleted", handleMessageDeleted);
    socket.on("userTyping", handleUserTyping);
    socket.on("userStoppedTyping", handleUserStoppedTyping);
    socket.on("userStatusUpdate", handleUserStatusUpdate);
    socket.on("messageError", handleMessageError);
    socket.on("messageCorrection", handleMessageCorrection);
    socket.on("correctionAccepted", handleCorrectionAccepted);
    socket.on("messageEdited", handleMessageEdited);
    socket.on("messageReaction", handleMessageReaction);
    socket.on("messagePinned", handleMessagePinned);
    socket.on("messageSendError", handleMessageSendError);
    socket.on("queuedMessages", handleQueuedMessages);

    return () => {
      socket.off("newMessage", handleNewMessage);
      socket.off("newVoiceMessage", handleMediaMessage);
      socket.off("newVideoMessage", handleMediaMessage);
      socket.off("messageSent", handleMessageSent);
      socket.off("messageDelivered", handleMessageDelivered);
      socket.off("messagesRead", handleMessagesRead);
      socket.off("messageDeleted", handleMessageDeleted);
      socket.off("userTyping", handleUserTyping);
      socket.off("userStoppedTyping", handleUserStoppedTyping);
      socket.off("userStatusUpdate", handleUserStatusUpdate);
      socket.off("messageError", handleMessageError);
      socket.off("messageCorrection", handleMessageCorrection);
      socket.off("correctionAccepted", handleCorrectionAccepted);
      socket.off("messageEdited", handleMessageEdited);
      socket.off("messageReaction", handleMessageReaction);
      socket.off("messagePinned", handleMessagePinned);
      socket.off("messageSendError", handleMessageSendError);
      socket.off("queuedMessages", handleQueuedMessages);
    };
  }, [socket, userId, dispatch, rememberInThread, forgetFromThread, patchInThread]);

  // Request user status when selectedUser changes or socket connects
  useEffect(() => {
    if (!socket || !selectedUser) return;

    const requestStatus = () => {
      if (!socket.connected) return;
      console.log("[ChatContent] Requesting status for:", selectedUser);
      socket.emit("getUserStatus", { userId: selectedUser }, (response: any) => {
        console.log("[ChatContent] getUserStatus response:", response);
        if (response?.status === "success" && response?.data) {
          setIsOnline(response.data.status === "online");
          if (response.data.lastSeen) setLastSeen(response.data.lastSeen);
        }
      });
    };

    // Request now if connected
    requestStatus();

    // Also request when socket (re)connects
    socket.on("connect", requestStatus);
    return () => {
      socket.off("connect", requestStatus);
    };
  }, [selectedUser, socket]);

  // After a reconnect, re-read the newest page of this thread: anything that
  // arrived while the socket was down (laptop sleep, network drop, a kicked
  // tab) reached the server but never reached this screen. `merge` upserts by
  // id, so nothing doubles.
  useEffect(() => {
    if (!connectionEpoch || !userId || !selectedUser) return;
    const endpoint = (chatApiSlice as any).endpoints && (chatApiSlice as any).endpoints.getConversation;
    if (!endpoint) return;
    dispatch(
      endpoint.initiate(
        { senderId: userId, receiverId: selectedUser, page: 1, limit: MESSAGE_PAGE_SIZE },
        { forceRefetch: true, subscribe: false }
      )
    );
    // Only the epoch decides; a conversation switch has its own fetch.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [connectionEpoch]);

  // Seed from the cache and mark as read.
  //
  // NOT a wholesale replace. The cache entry holds whole pages; anything the
  // socket has delivered since the last fetch — and every optimistic message
  // still in flight — lives only in local state, and replacing the list threw
  // those away the moment another page arrived. So the cached page wins on
  // content, local state keeps what the cache has not heard of, and a tick the
  // socket has already advanced never travels backwards.
  useEffect(() => {
    const loaded = (data as any)?.data;
    if (!loaded) return;

    const sameConversation = seededUserRef.current === selectedUser;
    seededUserRef.current = selectedUser;

    const previousSource = seedSourceRef.current;
    const nextSource: { [id: string]: any } = {};

    setMessages((prev) => {
      const localById: { [id: string]: Message } = {};
      if (sameConversation) {
        prev.forEach((m) => {
          localById[m._id] = m;
        });
      }

      const merged: Message[] = loaded.map((msg: Message) => {
        nextSource[msg._id] = msg;
        // The server has NO usable status: `status` is a Mongoose virtual and
        // the thread is read with `.lean()`, so it never arrives. A message
        // the server holds is exactly ONE tick — `messageDelivered` is what
        // raises it to two. Synthesising "delivered" here quietly promoted
        // every message on the next refetch.
        // `delivered` is a real field on Message, not a virtual, and the
        // thread endpoint returns it -- its own comment in the model says it
        // "powers sent -> delivered -> read tick states on the client". Reading
        // only `read` meant two ticks existed solely as a live socket event, so
        // a reload dropped every delivered-but-unread message back to one.
        const fromServer: MessageStatus =
          msg.status ||
          (msg.read ? "read" : msg.delivered ? "delivered" : "sent");
        const local = localById[msg._id];
        const status =
          local && statusRank(local.status) > statusRank(fromServer)
            ? local.status
            : fromServer;
        // Same server object as last time and the same resolved status: hand
        // back the object already on screen so `React.memo` can skip the
        // bubble. Rebuilding every message gave the whole thread fresh
        // identities on every refetch.
        if (local && previousSource[msg._id] === msg && local.status === status) {
          return local;
        }
        return { ...msg, status };
      });

      if (!sameConversation) return merged;

      const known: { [id: string]: boolean } = {};
      merged.forEach((m) => {
        known[m._id] = true;
      });
      return merged.concat(prev.filter((m) => !known[m._id]));
    });

    seedSourceRef.current = nextSource;

    if (socket?.connected && selectedUser) {
      socket.emit("markAsRead", { senderId: selectedUser });
    }
  }, [data, selectedUser, socket]);

  // Clear state when switching conversations
  useEffect(() => {
    setIsTyping(false);
    setIsSearchOpen(false);
    setNewMessage("");
    setMediaPreview(null);
    setMissedCount(0);
    setIsAtBottom(true);
    seenCountRef.current = 0;
    setPage(1);
    setIsLoadingOlder(false);
    pendingOlderRef.current = null;
    olderRequestRef.current = false;
    sentinelVisibleRef.current = false;
    stopRecording();
  }, [selectedUser]);

  // A conversation starter opened this chat: the profile page navigates to
  // /chat/:userId?draft=<encoded>, and the opener belongs in the box rather
  // than sent on the viewer's behalf.
  //
  // Declared AFTER the clear effect on purpose. React flushes passive effects
  // in declaration order, and the clear above also fires on mount (deps
  // `[selectedUser]`) -- so a draft seeded before it would be wiped by the
  // very next effect, with `?draft=` already stripped from the URL and the
  // text unrecoverable. The route guarantees that mount on every Send:
  // /chat/:userId renders `<MainChat key={userId}>`.
  //
  // `seededRef` plus the functional update make this once-only and
  // non-destructive: a param that arrives late can never overwrite text the
  // viewer has already typed, and the strip happens only after the seed.
  useEffect(() => {
    const draft = searchParams.get("draft");
    if (!draft || draftSeededRef.current) return;
    draftSeededRef.current = true;
    setNewMessage((current) => current || draft);
    const next = new URLSearchParams(searchParams);
    next.delete("draft");
    setSearchParams(next, { replace: true });
  }, [searchParams, setSearchParams]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);
      if (typingClearRef.current) clearTimeout(typingClearRef.current);
      if (recordingIntervalRef.current) clearInterval(recordingIntervalRef.current);
      if (audioStreamRef.current) {
        audioStreamRef.current.getTracks().forEach((t) => t.stop());
      }
      if (audioPlayerRef.current) {
        audioPlayerRef.current.pause();
        audioPlayerRef.current = null;
      }
    };
  }, []);

  // Track if user is scrolled to bottom
  const handleScroll = useCallback(() => {
    const container = chatContainerRef.current;
    if (!container) return;
    const threshold = 100;
    const atBottom =
      container.scrollHeight - container.scrollTop - container.clientHeight < threshold;
    isAtBottomRef.current = atBottom;
    // Only on a FLIP. A scroll event fires many times a second and setting
    // state on each one would re-render the whole thread while it moves.
    setIsAtBottom((was) => (was === atBottom ? was : atBottom));
    if (atBottom) setMissedCount((n) => (n === 0 ? n : 0));
  }, []);

  /** Back to the newest message, and nothing missed any more. */
  const jumpToBottom = useCallback((behavior: ScrollBehavior = "smooth") => {
    const container = chatContainerRef.current;
    if (!container) return;
    // On the container, never `messagesEndRef.scrollIntoView`: scrollIntoView
    // walks up and scrolls ANCESTORS too, which is what made the whole page
    // lurch on a phone.
    if (typeof container.scrollTo === "function") {
      container.scrollTo({ top: container.scrollHeight, behavior });
    } else {
      container.scrollTop = container.scrollHeight;
    }
    isAtBottomRef.current = true;
    setIsAtBottom(true);
    setMissedCount(0);
  }, []);

  // ========== Older history ==========
  // Asking for the previous page prepends messages above the viewport, which
  // would yank the thread downwards under the reader's eyes. The height
  // BEFORE the prepend is measured here and the offset restored in the layout
  // effect below, so the message being read stays exactly where it was.
  const loadOlderMessages = useCallback(() => {
    if (!hasMoreHistory || isFetching) return;
    const container = chatContainerRef.current;
    // Anchor on the first message on screen, not on the scroller's height. A
    // height difference cannot tell a prepended page from a message that just
    // arrived at the BOTTOM, and the arriving message would have consumed the
    // restore, leaving the real prepend to jump the thread.
    const first = container
      ? (container.querySelector("[data-msg-id]") as HTMLElement | null)
      : null;
    pendingOlderRef.current = first
      ? {
          id: first.getAttribute("data-msg-id") || "",
          top: first.getBoundingClientRect().top,
        }
      : null;
    // Which page to ask for is decided BEFORE anything is set: a call that
    // cannot advance must change no state at all, or the re-arm below and the
    // settle effect trade renders forever. The page is derived from what is
    // already held, so a cache entry that survived a remount is continued
    // rather than re-walked from page 2.
    const fromLoaded = Math.floor(loadedCountRef.current / MESSAGE_PAGE_SIZE) + 1;
    const next = Math.max(pageRef.current + 1, fromLoaded);
    if (next > totalPagesRef.current) return;

    // Reading history is not being at the bottom: the auto-scroll must not
    // drag the view back down when the older page lands.
    isAtBottomRef.current = false;
    setIsLoadingOlder(true);
    olderRequestRef.current = true;
    setPage((current) => (next > current ? next : current));
  }, [hasMoreHistory, isFetching]);

  // Open at the newest message. The thread renders oldest-first, so without
  // this the reader lands at the TOP of the history — on the oldest message,
  // with the "load earlier" sentinel already in view. `scrollIntoView` in a
  // passive effect was not enough: it is asynchronous and smooth, and on
  // first paint it left the scroller at 0. This jumps, before paint, once per
  // conversation.
  useLayoutEffect(() => {
    if (messages.length === 0) return;
    if (openedAtBottomRef.current === selectedUser) return;
    const container = chatContainerRef.current;
    if (!container) return;
    openedAtBottomRef.current = selectedUser;
    container.scrollTop = container.scrollHeight;
    isAtBottomRef.current = true;
  }, [messages, selectedUser]);

  useLayoutEffect(() => {
    const pending = pendingOlderRef.current;
    const container = chatContainerRef.current;
    if (!pending || !container) return;
    const anchor = container.querySelector(
      `[data-msg-id="${pending.id}"]`
    ) as HTMLElement | null;
    if (!anchor) return;
    const delta = anchor.getBoundingClientRect().top - pending.top;
    // Zero means nothing was inserted ABOVE the anchor — whatever changed
    // `messages` happened below it, so the older page is still on its way.
    if (delta === 0) return;
    pendingOlderRef.current = null;
    container.scrollTop = container.scrollTop + delta;
  }, [messages]);

  // When the request settles, stop claiming to load older messages and re-read
  // where the reader actually is. A request that prepended nothing (a page the
  // entry already held, or one that failed) must not leave the anchor and the
  // disabled auto-scroll behind.
  useEffect(() => {
    const settled = wasFetchingRef.current && !isFetching;
    wasFetchingRef.current = isFetching;
    if (isFetching) return;
    if (olderRequestRef.current) {
      olderRequestRef.current = false;
      setIsLoadingOlder(false);
      handleScroll();
    }
    // An intersection that arrived WHILE a fetch was in flight was dropped,
    // and an observer only fires again when the sentinel crosses its boundary
    // anew — which never happens if it simply stayed on screen. So on the
    // settling edge, and only there, ask again for what is still in view.
    if (settled && sentinelVisibleRef.current && hasMoreHistory) {
      loadOlderMessages();
    }
  }, [isFetching, hasMoreHistory, handleScroll, loadOlderMessages]);

  // The sentinel does the asking on scroll; the button inside it is what a
  // keyboard (and a browser without IntersectionObserver) uses.
  useEffect(() => {
    if (!hasMoreHistory) return;
    const node = topSentinelRef.current;
    if (!node || typeof IntersectionObserver === "undefined") return;

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries.some((entry) => entry.isIntersecting);
        sentinelVisibleRef.current = visible;
        if (visible) loadOlderMessages();
      },
      { root: chatContainerRef.current, rootMargin: "120px" }
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [hasMoreHistory, loadOlderMessages]);

  // Auto-scroll, and the tally of what the reader did not see.
  //
  // One place for both: every send and every arrival ends in `messages`, so
  // text, replies, stickers, voice and video are all covered without each
  // handler counting for itself.
  useEffect(() => {
    const grewBy = messages.length - seenCountRef.current;
    seenCountRef.current = messages.length;

    if (messages.length === 0) return;
    if (isAtBottomRef.current) {
      jumpToBottom("smooth");
    } else if (grewBy > 0) {
      setMissedCount((n) => n + grewBy);
    }
  }, [messages, jumpToBottom]);

  // ========== Typing ==========
  const handleTyping = useCallback(() => {
    if (!socket?.connected || !selectedUser) return;

    if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);
    emit("typing", { receiver: selectedUser });

    typingTimeoutRef.current = setTimeout(() => {
      emit("stopTyping", { receiver: selectedUser });
    }, 2000);
  }, [selectedUser, socket, emit]);

  // ========== Optimistic-message helpers (shared by send paths) ==========
  const makeOptimisticMessage = (text: string, extra?: Partial<Message>): Message => ({
    _id: `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    message: text,
    sender: { _id: userId, name: currentUserName || "" },
    receiver: selectedUser,
    createdAt: new Date().toISOString(),
    isOptimistic: true,
    status: "sending",
    ...extra,
  });

  // The one place a message of ours stops being a guess and becomes a record
  // the server holds -- every send route ends here: socket ack, REST fallback,
  // reply, sticker, GIF, media, voice.
  //
  // Which is why the conversation LIST is refreshed from here. The sidebar and
  // the navbar badge refetch off `messageSent`, and the tab that sent the
  // message is the one tab that never used to see it: the server emits that
  // event with `socket.to(`user_<id>`)` (socket/socketHandler.js), and
  // socket.io's `.to()` on a socket excludes the socket doing the sending --
  // it is addressed to the sender's OTHER devices. So the phone updated and
  // the second tab updated while the window the message was typed in kept the
  // previous last message, in the previous row order, until something else
  // happened to refetch. The REST fallback emitted nothing at all.
  const finalizeOptimistic = (tempId: string, msgData: any) => {
    setMessages((prev) => {
      // Already here under its real id (messageSent beat a late ack): drop
      // the temp copy instead of holding two.
      if (msgData && msgData._id && prev.some((m) => m._id === msgData._id)) {
        return prev.filter((m) => m._id !== tempId);
      }
      return prev.map((m) =>
        m._id === tempId ? { ...msgData, status: "sent", isOptimistic: false } : m
      );
    });
    // And into the THREAD, which is a different cache entry from the two lists
    // above. Local state is rebuilt from that entry wholesale on a conversation
    // switch, so without this our own message was the one kind that could not
    // survive leaving the room: send "hi" to A, step into B, come back, and the
    // seeding effect replaced it with a cached page that had never heard of it.
    // Incoming messages have been written here since they arrive over the
    // socket; a send is confirmed by an ack instead, so it needs its own call.
    rememberInThread(msgData, selectedUser);
    dispatch(
      (chatApiSlice.util as any).invalidateTags(["Conversations"])
    );
  };

  const markOptimisticError = (tempId: string) => {
    setMessages((prev) =>
      prev.map((m) =>
        m._id === tempId ? { ...m, status: "error", isOptimistic: false } : m
      )
    );
  };

  // One place a refused send is explained. Limits / cap / block get a
  // dialog; the burst limiter and anything unexpected get a toast. The bubble
  // itself is marked failed by the caller (Retry stays available).
  const reportSendError = useCallback(
    (err: any) => {
      const classified = classifySendError(err);
      if (classified.kind === "rateLimited") {
        notify.error(t("chatPage.sendErrors.tooFast") || "You're sending messages too fast. Wait a moment.", {
          toastId: "chat-send-too-fast",
        });
        return;
      }
      if (classified.kind === "generic") {
        notify.error(t("chatPage.sendErrors.generic") || "Message not sent. Tap Retry to try again.", {
          toastId: "chat-send-failed",
        });
        return;
      }
      setSendError(classified);
    },
    [t]
  );
  useEffect(() => {
    reportSendErrorRef.current = reportSendError;
  });

  // Text, sticker and GIF over the socket. Socket only: see lib/socketAck.
  const sendInlineOverSocket = (tempId: string, text: string, messageType?: string) => {
    if (!socket) return;
    const payload: any = { receiver: selectedUser, message: text };
    if (messageType && messageType !== "text") payload.messageType = messageType;
    emitWithAck(socket as any, "sendMessage", payload, SOCKET_ACK_TIMEOUT_MS, {
      onAck: (response: any) => {
        setIsSending(false);
        if (response && response.status === "success" && response.message) {
          finalizeOptimistic(tempId, response.message);
          return;
        }
        markOptimisticError(tempId);
        reportSendError(response);
      },
      onTimeout: () => {
        setIsSending(false);
        markOptimisticError(tempId);
      },
    });
  };

  // ========== Send Text Message ==========
  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();

    // If there's a media preview, send it as media message
    if (mediaPreview) {
      await handleSendMedia();
      return;
    }

    // Reply flow — link the outgoing message to the message being replied to.
    if (replyingTo && newMessage.trim() && !isSending) {
      const messageToSend = newMessage.trim();
      const replyTarget = replyingTo;
      const optimisticMessage = makeOptimisticMessage(messageToSend, {
        replyTo: {
          _id: replyTarget._id,
          message: replyTarget.message,
          sender: { _id: replyTarget.sender._id, name: replyTarget.sender.name },
        },
      });
      const tempId = optimisticMessage._id;
      setMessages((prev) => [...prev, optimisticMessage]);
      setNewMessage("");
      setReplyingTo(null);
      setIsSending(true);
      isAtBottomRef.current = true;
      try {
        const result: any = await replyToMessage({
          messageId: replyTarget._id,
          message: messageToSend,
          receiver: selectedUser,
        }).unwrap();
        const msgData = result.data || result;
        finalizeOptimistic(tempId, msgData);
      } catch (err) {
        console.error("Reply send failed:", err);
        markOptimisticError(tempId);
        reportSendError(err);
      } finally {
        setIsSending(false);
      }
      return;
    }

    if (!newMessage.trim() || isSending) return;

    const messageToSend = newMessage.trim();

    const optimisticMessage = makeOptimisticMessage(messageToSend);
    const tempId = optimisticMessage._id;

    setMessages((prev) => [...prev, optimisticMessage]);
    setNewMessage("");
    setIsSending(true);
    isAtBottomRef.current = true;

    // Stop typing
    if (socket?.connected) {
      emit("stopTyping", { receiver: selectedUser });
      if (typingTimeoutRef.current) {
        clearTimeout(typingTimeoutRef.current);
        typingTimeoutRef.current = null;
      }
    }

    if (socket?.connected) {
      sendInlineOverSocket(tempId, messageToSend);
    } else {
      // Not connected at all: one REST request, no race with a socket copy.
      await sendViaRestApi(tempId, messageToSend);
    }
  };

  const sendViaRestApi = async (tempId: string, messageText: string) => {
    try {
      const result: any = await createMessage({
        sender: userId,
        receiver: selectedUser,
        message: messageText,
        type: "text",
      }).unwrap();

      const msgData = result.data || result;
      finalizeOptimistic(tempId, msgData);
      setIsSending(false);
    } catch (err) {
      console.error("REST API send failed:", err);
      setIsSending(false);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
      reportSendError(err);
    }
  };

  // ========== Send Sticker ==========
  // GIFs reuse the sticker pipeline — same optimistic insert + socket-with-
  // REST-fallback shape, just a different messageType. Backend treats the URL
  // as the message body; the rendering branch below picks it up by type.
  const handleSendGif = async (gifUrl: string) => {
    setIsGifPanelOpen(false);
    await sendInlineMessage(gifUrl, "gif");
  };

  const sendInlineMessage = async (text: string, messageType: string) => {
    if (isSending) return;
    const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const optimisticMessage: Message = {
      _id: tempId,
      message: text,
      messageType,
      sender: { _id: userId, name: currentUserName || "" },
      receiver: selectedUser,
      createdAt: new Date().toISOString(),
      isOptimistic: true,
      status: "sending",
    };
    setMessages((prev) => [...prev, optimisticMessage]);
    isAtBottomRef.current = true;

    if (socket?.connected) {
      sendInlineOverSocket(tempId, text, messageType);
    } else {
      await sendInlineMessageViaRest(tempId, text, messageType);
    }
  };

  const sendInlineMessageViaRest = async (
    tempId: string,
    text: string,
    messageType: string
  ) => {
    try {
      const result: any = await createMessage({
        sender: userId,
        receiver: selectedUser,
        message: text,
        type: messageType,
      }).unwrap();
      const msgData = result.data || result;
      finalizeOptimistic(tempId, msgData);
    } catch (err) {
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
      reportSendError(err);
    }
  };

  const handleSendSticker = async (sticker: string) => {
    if (isSending) return;

    const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const optimisticMessage: Message = {
      _id: tempId,
      message: sticker,
      messageType: "sticker",
      sender: { _id: userId, name: currentUserName || "" },
      receiver: selectedUser,
      createdAt: new Date().toISOString(),
      isOptimistic: true,
      status: "sending",
    };

    setMessages((prev) => [...prev, optimisticMessage]);
    setIsStickerPanelOpen(false);
    isAtBottomRef.current = true;

    if (socket?.connected) {
      sendInlineOverSocket(tempId, sticker, "sticker");
    } else {
      await sendStickerViaRest(tempId, sticker);
    }
  };

  const sendStickerViaRest = async (tempId: string, sticker: string) => {
    try {
      const result: any = await createMessage({
        sender: userId,
        receiver: selectedUser,
        message: sticker,
        type: "sticker",
      }).unwrap();

      const msgData = result.data || result;
      finalizeOptimistic(tempId, msgData);
    } catch (err) {
      console.error("Sticker send failed:", err);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
      reportSendError(err);
    }
  };

  // ========== Media Upload ==========
  const handleAttachmentClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const isImage = file.type.startsWith("image/");
    const isVideo = file.type.startsWith("video/");
    const isAudio = file.type.startsWith("audio/");

    if (!isImage && !isVideo && !isAudio) {
      // Treat as document/file
      const url = URL.createObjectURL(file);
      setMediaPreview({ file, url, type: "document" });
    } else {
      const url = URL.createObjectURL(file);
      setMediaPreview({
        file,
        url,
        type: isImage ? "image" : isVideo ? "video" : "audio",
      });
    }

    // Reset input so same file can be re-selected
    if (fileInputRef.current) fileInputRef.current.value = "";
  };

  const handleCancelMedia = () => {
    if (mediaPreview) {
      URL.revokeObjectURL(mediaPreview.url);
      setMediaPreview(null);
    }
  };

  const handleSendMedia = async () => {
    if (!mediaPreview || isSending) return;
    if (mediaPreview.type === "video") {
      const preview = mediaPreview;
      const caption = newMessage.trim();
      const limits = limitsFromConfig(videoConfig);
      const duration = await readVideoDuration(preview.file);
      const verdict = checkVideo(preview.file, limits, duration);
      if (verdict !== "ok") {
        notify.error(
          verdict === "tooBig"
            ? t("chatPage.video.tooBig", { mb: Math.round(limits.maxSize / (1024 * 1024)) }) ||
                `This video is too large. The limit is ${Math.round(limits.maxSize / (1024 * 1024))} MB.`
            : verdict === "tooLong"
            ? t("chatPage.video.tooLong", { minutes: Math.round(limits.maxDuration / 60) }) ||
                `This video is too long. The limit is ${Math.round(limits.maxDuration / 60)} minutes.`
            : t("chatPage.video.badType") || "This video format can't be sent. Try an MP4."
        );
        handleCancelMedia();
        return;
      }

      setIsSending(true);
      isAtBottomRef.current = true;
      const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
      setMessages((prev) => [
        ...prev,
        {
          _id: tempId,
          message: "",
          sender: { _id: userId, name: currentUserName || "" },
          receiver: selectedUser,
          messageType: "media",
          media: { url: preview.url, type: "video" },
          createdAt: new Date().toISOString(),
          isOptimistic: true,
          status: "sending",
        },
      ]);
      setNewMessage("");
      try {
        const formData = new FormData();
        formData.append("video", preview.file);
        formData.append("receiver", selectedUser);
        const result: any = await sendVideoMessage(formData).unwrap();
        finalizeOptimistic(tempId, result.data || result);
        // /messages/video has no caption field; the caption follows as text.
        if (caption) {
          setIsSending(false);
          await sendInlineMessage(caption, "text");
        }
      } catch (err) {
        markOptimisticError(tempId);
        reportSendError(err);
      } finally {
        setIsSending(false);
        handleCancelMedia();
      }
      return;
    }
    setIsSending(true);
    isAtBottomRef.current = true;

    const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const optimisticMessage: Message = {
      _id: tempId,
      message: newMessage.trim(),
      sender: { _id: userId, name: currentUserName || "" },
      receiver: selectedUser,
      messageType: "media",
      media: {
        url: mediaPreview.url,
        type: mediaPreview.type,
      },
      createdAt: new Date().toISOString(),
      isOptimistic: true,
      status: "sending",
    };

    setMessages((prev) => [...prev, optimisticMessage]);
    setNewMessage("");

    try {
      const formData = new FormData();
      formData.append("attachment", mediaPreview.file);
      formData.append("receiver", selectedUser);
      if (newMessage.trim()) {
        formData.append("message", newMessage.trim());
      }

      const result: any = await sendMediaMessage(formData).unwrap();
      const msgData = result.data || result;

      finalizeOptimistic(tempId, msgData);
    } catch (err) {
      console.error("Media upload failed:", err);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
      reportSendError(err);
    } finally {
      setIsSending(false);
      handleCancelMedia();
    }
  };

  // ========== Voice Recording ==========
  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      audioStreamRef.current = stream;
      audioChunksRef.current = [];

      const choice = pickRecorderMime();
      let mediaRecorder: MediaRecorder;
      try {
        mediaRecorder = choice.mimeType
          ? new MediaRecorder(stream, { mimeType: choice.mimeType })
          : new MediaRecorder(stream);
      } catch (err) {
        // A browser that said yes and then refused: let it pick.
        mediaRecorder = new MediaRecorder(stream);
      }
      recorderMimeRef.current = mediaRecorder.mimeType || choice.mimeType || "";
      mediaRecorderRef.current = mediaRecorder;

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          audioChunksRef.current.push(event.data);
        }
      };

      mediaRecorder.onstop = () => {
        // Handled in stopRecording
      };

      mediaRecorder.start(100); // Collect data every 100ms
      setIsRecording(true);
      setRecordingDuration(0);

      recordingIntervalRef.current = setInterval(() => {
        setRecordingDuration((prev) => {
          if (prev >= 300) {
            // Max 5 minutes
            stopRecording();
            return prev;
          }
          return prev + 1;
        });
      }, 1000);
    } catch (err) {
      console.error("Failed to start recording:", err);
      notify.error(
        t("chatPage.voice.unavailable") ||
          "Voice recording isn't available. Check the microphone permission for this site."
      );
    }
  };

  const stopRecording = () => {
    if (recordingIntervalRef.current) {
      clearInterval(recordingIntervalRef.current);
      recordingIntervalRef.current = null;
    }

    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== "inactive") {
      mediaRecorderRef.current.stop();
    }

    if (audioStreamRef.current) {
      audioStreamRef.current.getTracks().forEach((track) => track.stop());
      audioStreamRef.current = null;
    }

    setIsRecording(false);
  };

  const cancelRecording = () => {
    stopRecording();
    audioChunksRef.current = [];
    setRecordingDuration(0);
  };

  const sendVoiceRecording = async () => {
    if (audioChunksRef.current.length === 0) return;

    const duration = recordingDuration;
    stopRecording();

    // Wait briefly for any remaining data
    await new Promise((resolve) => setTimeout(resolve, 200));

    const recordedType = baseMime(recorderMimeRef.current);
    const audioBlob = new Blob(audioChunksRef.current, { type: recordedType });
    audioChunksRef.current = [];
    setRecordingDuration(0);

    if (audioBlob.size === 0) return;

    setIsSending(true);
    isAtBottomRef.current = true;

    const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const tempUrl = URL.createObjectURL(audioBlob);

    const optimisticMessage: Message = {
      _id: tempId,
      message: "",
      sender: { _id: userId, name: currentUserName || "" },
      receiver: selectedUser,
      messageType: "voice",
      media: {
        url: tempUrl,
        type: "voice",
        duration,
      },
      createdAt: new Date().toISOString(),
      isOptimistic: true,
      status: "sending",
    };

    setMessages((prev) => [...prev, optimisticMessage]);

    try {
      const formData = new FormData();
      formData.append("voice", audioBlob, `voice-${Date.now()}.${extForMime(recordedType)}`);
      formData.append("receiver", selectedUser);
      formData.append("duration", duration.toString());
      const waveform = await computeWaveform(audioBlob, 30);
      if (waveform && waveform.length) formData.append("waveform", JSON.stringify(waveform));

      const result: any = await sendVoiceMessage(formData).unwrap();
      const msgData = result.data || result;

      finalizeOptimistic(tempId, msgData);
    } catch (err) {
      console.error("Voice send failed:", err);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
      reportSendError(err);
    } finally {
      setIsSending(false);
      URL.revokeObjectURL(tempUrl);
    }
  };

  // ========== Voice Playback ==========
  const toggleAudioPlayback = (messageId: string, audioUrl: string) => {
    if (playingAudioId === messageId) {
      audioPlayerRef.current?.pause();
      setPlayingAudioId(null);
      return;
    }

    if (audioPlayerRef.current) {
      audioPlayerRef.current.pause();
    }

    setAudioProgress(0);
    setAudioElapsed(0);

    const audio = new Audio(audioUrl);
    audioPlayerRef.current = audio;
    setPlayingAudioId(messageId);

    audio.play().catch(console.error);

    audio.addEventListener("timeupdate", () => {
      if (audio.duration) {
        setAudioProgress(audio.currentTime / audio.duration);
        setAudioElapsed(audio.currentTime);
      }
    });

    audio.onended = () => {
      setPlayingAudioId(null);
      setAudioProgress(0);
      setAudioElapsed(0);
      audioPlayerRef.current = null;
    };
  };

  // ========== Other Handlers ==========
  const handleRetryMessage = (failedMsg: Message) => {
    // A file is not kept after a failed upload; ask for it again rather than
    // re-sending an empty bubble.
    if (failedMsg.media && failedMsg.messageType !== "sticker" && failedMsg.messageType !== "gif") {
      setMessages((prev) => prev.filter((msg) => msg._id !== failedMsg._id));
      notify.info(t("chatPage.sendErrors.reattach") || "Attach the file again to send it.");
      return;
    }

    setMessages((prev) => prev.filter((msg) => msg._id !== failedMsg._id));
    const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const optimisticMessage: Message = {
      ...failedMsg,
      _id: tempId,
      status: "sending",
      isOptimistic: true,
    };
    setMessages((prev) => [...prev, optimisticMessage]);
    isAtBottomRef.current = true;

    // A failed reply goes back through the reply route, keeping its link.
    if (failedMsg.replyTo && failedMsg.replyTo._id) {
      replyToMessage({
        messageId: failedMsg.replyTo._id,
        message: failedMsg.message,
        receiver: selectedUser,
      })
        .unwrap()
        .then((result: any) => finalizeOptimistic(tempId, result.data || result))
        .catch((err: any) => {
          markOptimisticError(tempId);
          reportSendError(err);
        });
      return;
    }

    const type = failedMsg.messageType || "text";
    if (socket?.connected) {
      setIsSending(true);
      sendInlineOverSocket(tempId, failedMsg.message, type);
    } else if (type === "sticker") {
      sendStickerViaRest(tempId, failedMsg.message);
    } else if (type === "gif") {
      sendInlineMessageViaRest(tempId, failedMsg.message, type);
    } else {
      sendViaRestApi(tempId, failedMsg.message);
    }
  };

  // ===== Message-action handlers (Task 6) =====
  const handleToggleReaction = useCallback(
    (msg: Message, emoji: string) => {
      const mine = (msg.reactions || []).some((r) => {
        const uid = typeof r.user === "string" ? r.user : (r.user as any)?._id;
        return uid === userId && r.emoji === emoji;
      });
      if (mine)
        removeReaction({ messageId: msg._id, emoji })
          .unwrap()
          .catch((e) => console.error("Remove reaction failed:", e));
      else
        addReaction({ messageId: msg._id, emoji })
          .unwrap()
          .catch((e) => console.error("Add reaction failed:", e));
    },
    [userId, addReaction, removeReaction]
  );

  // Opens the edit dialog; the save itself is handleEditSave.
  const handleEditMessageAction = useCallback((msg: Message) => {
    setEditError("");
    setEditingMsg(msg);
  }, []);

  const handleEditSave = useCallback(
    (text: string) => {
      const target = editingMsg;
      if (!target) return;
      setEditBusy(true);
      setEditError("");
      editMessage({ messageId: target._id, message: text })
        .unwrap()
        .then(() => {
          const patch = { message: text, isEdited: true, editedAt: new Date().toISOString() };
          setMessages((prev) => prev.map((m) => (m._id === target._id ? { ...m, ...patch } : m)));
          patchInThread(target._id, patch as Partial<Message>, selectedUserRef.current);
          setEditingMsg(null);
        })
        .catch((err: any) => setEditError(editErrorText(err, t as any)))
        .then(() => setEditBusy(false));
    },
    [editingMsg, editMessage, patchInThread, t]
  );

  const handleDeleteMessageAction = useCallback((msg: Message) => {
    setDeleteError("");
    setDeletingMsg(msg);
  }, []);

  const handleDeleteConfirm = useCallback(
    (forEveryone: boolean) => {
      const target = deletingMsg;
      if (!target) return;
      setDeleteBusy(true);
      setDeleteError("");
      deleteMessageApi({ messageId: target._id, forEveryone })
        .unwrap()
        .then(() => {
          if (forEveryone) {
            setMessages((prev) =>
              prev.map((m) => (m._id === target._id ? { ...m, ...DELETED_PATCH } : m))
            );
            patchInThread(target._id, DELETED_PATCH, selectedUserRef.current);
          } else {
            setMessages((prev) => prev.filter((m) => m._id !== target._id));
            forgetFromThread(target._id, selectedUserRef.current);
          }
          setDeletingMsg(null);
        })
        .catch((err: any) => setDeleteError(deleteErrorText(err, t as any)))
        .then(() => setDeleteBusy(false));
    },
    [deletingMsg, deleteMessageApi, forgetFromThread, patchInThread, t]
  );

  const handleTtsMessage = useCallback(
    async (msg: Message) => {
      try {
        const res: any = await ttsMessage({ messageId: msg._id }).unwrap();
        const url = res?.data?.audioUrl;
        if (url) new Audio(url).play().catch((e) => console.error("TTS play failed:", e));
      } catch (err) {
        console.error("TTS failed:", err);
      }
    },
    [ttsMessage]
  );

  const handleJumpToMessage = useCallback((messageId: string) => {
    const el = chatContainerRef.current?.querySelector(`[data-msg-id="${messageId}"]`);
    el?.scrollIntoView({ behavior: "smooth", block: "center" });
  }, []);

  // A search result. The search covers the whole history; the thread holds
  // only the pages loaded so far, so a result further back is explained
  // rather than silently doing nothing.
  const handleJumpFromSearch = useCallback(
    (messageId: string) => {
      setIsSearchOpen(false);
      const container = chatContainerRef.current;
      const el = container ? (container.querySelector(`[data-msg-id="${messageId}"]`) as HTMLElement | null) : null;
      if (!el) {
        notify.info(t("chatPage.search.notLoaded") || "That message is further back. Scroll up to load it.");
        return;
      }
      el.scrollIntoView({ behavior: "smooth", block: "center" });
      el.classList.add("modern-message--highlight");
      window.setTimeout(() => el.classList.remove("modern-message--highlight"), 2000);
    },
    [t]
  );

  // Stable identities for the memoized bubble. `toggleAudioPlayback` and
  // `handleRetryMessage` are re-created every render (they close over half the
  // component); handing them straight to a memoized child would defeat the
  // memo, so the bubble gets these thin, never-changing wrappers instead.
  const togglePlaybackRef = useRef<(messageId: string, url: string) => void>(() => {});
  const retryRef = useRef<(msg: Message) => void>(() => {});
  useEffect(() => {
    togglePlaybackRef.current = toggleAudioPlayback;
    retryRef.current = handleRetryMessage;
  });
  const handleTogglePlayback = useCallback((messageId: string, url: string) => {
    togglePlaybackRef.current(messageId, url);
  }, []);
  const handleRetry = useCallback((msg: Message) => {
    retryRef.current(msg);
  }, []);

  const handleLocalCorrectionAccepted = useCallback(
    (messageId: string, correctionId: string) => {
      setMessages((prev) =>
        prev.map((m) =>
          m._id === messageId
            ? {
                ...m,
                corrections: (m.corrections || []).map((c) =>
                  c._id === correctionId ? { ...c, isAccepted: true } : c
                ),
              }
            : m
        )
      );
    },
    []
  );

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  const formatDate = useCallback((dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today.getTime() - 86400000);
    const msgDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

    if (msgDate.getTime() === today.getTime()) return t("chatPage.today") || "Today";
    if (msgDate.getTime() === yesterday.getTime()) return t("chatPage.yesterday") || "Yesterday";
    return date.toLocaleDateString(undefined, { month: "long", day: "numeric", year: "numeric" });
  }, [t]);

  const formatLastSeen = (dateString: string) => {
    if (!dateString) return "";
    const date = new Date(dateString);
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));

    if (diffInMinutes < 1) return t("chatPage.justNow") || "just now";
    if (diffInMinutes < 60)
      return t("chatPage.minutesAgo", { count: diffInMinutes }) || `${diffInMinutes}m ago`;
    if (diffInMinutes < 1440)
      return (
        t("chatPage.hoursAgo", { count: Math.floor(diffInMinutes / 60) }) ||
        `${Math.floor(diffInMinutes / 60)}h ago`
      );
    return date.toLocaleDateString();
  };

  // Sort messages
  const sortedMessages = useMemo(() => {
    return [...messages].sort(
      (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
    );
  }, [messages]);

  // Pinned messages for the PinnedBar (empty -> bar renders null)
  const pinnedMessages = useMemo(
    () => sortedMessages.filter((m) => m.pinned),
    [sortedMessages]
  );

  // Group messages by date
  const messagesByDate = useMemo(() => {
    const groups: { date: string; dateKey: string; messages: Message[] }[] = [];
    let currentDateKey = "";

    sortedMessages.forEach((msg) => {
      const dateKey = new Date(msg.createdAt).toDateString();
      if (dateKey !== currentDateKey) {
        currentDateKey = dateKey;
        groups.push({ date: formatDate(msg.createdAt), dateKey, messages: [msg] });
      } else {
        groups[groups.length - 1].messages.push(msg);
      }
    });

    return groups;
  }, [sortedMessages, formatDate]);

  // Message grouping
  const getMessagePosition = (
    msgs: Message[],
    index: number
  ): "single" | "first" | "middle" | "last" => {
    const current = msgs[index];
    const prev = index > 0 ? msgs[index - 1] : null;
    const next = index < msgs.length - 1 ? msgs[index + 1] : null;

    const sameAsPrev = prev?.sender._id === current.sender._id;
    const sameAsNext = next?.sender._id === current.sender._id;

    if (!sameAsPrev && !sameAsNext) return "single";
    if (!sameAsPrev && sameAsNext) return "first";
    if (sameAsPrev && sameAsNext) return "middle";
    return "last";
  };

  if (isLoading)
    return (
      <div className="chat-loading">
        <div className="loading-spinner">
          <div className="spinner"></div>
        </div>
        <p className="loading-text">{t("chatPage.loadingConversation") || "Loading..."}</p>
      </div>
    );

  if (error)
    return (
      <div className="chat-error">
        <AlertCircle size={48} className="chat-error-icon" />
        <p>{t("chatPage.errorLoading") || "Failed to load conversation"}</p>
      </div>
    );

  return (
    <div className="modern-chat-container">
      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*,video/*,audio/*,.pdf,.doc,.docx,.txt,.zip"
        className="hidden"
        onChange={handleFileSelect}
      />

      {/* Chat Header */}
      <div className="modern-chat-header">
        <div className="header-content">
          <div className="user-info-section">
            <button
              className="back-btn"
              onClick={() => navigate("/chat")}
              aria-label={
                t("chatPage.backToConversations") || "Back to conversations"
              }
            >
              <ArrowLeft size={20} />
            </button>
            <div className="profile-avatar-container">
              {/* The avatar and the name both open the member page, the way
                  the app's header does. Two links rather than one wrapper so
                  the presence line underneath stays plain text.
                  The avatar is the NAME link's decoration: hidden from the
                  accessibility tree and out of the tab order, so a screen
                  reader and a keyboard meet one "View X's profile" link
                  instead of the same one twice. A pointer still has both. */}
              <Link
                to={`/community/${selectedUser}`}
                data-testid="chat-header-avatar-link"
                className="header-profile-link"
                aria-hidden="true"
                tabIndex={-1}
              >
                <img
                  src={profilePicture || "/default-avatar.png"}
                  alt={userName}
                  className="profile-avatar"
                  loading="lazy"
                  decoding="async"
                />
              </Link>
              <div className={`status-pulse ${isOnline ? "online" : "offline"}`}>
                <div className="pulse-dot"></div>
              </div>
            </div>
            <div className="user-details">
              <h3 className="user-name">
                <Link
                  to={`/community/${selectedUser}`}
                  data-testid="chat-header-profile-link"
                  className="header-profile-link"
                  aria-label={
                    t("chatPage.viewProfileOf", { name: userName }) ||
                    `View ${userName}'s profile`
                  }
                >
                  {userName}
                </Link>
              </h3>
              <div className="status-info">
                {isTyping ? (
                  <span className="online-status">{t("chatPage.typing") || "typing..."}</span>
                ) : isOnline ? (
                  <span className="online-status">{t("chatPage.online") || "online"}</span>
                ) : (
                  <span className="offline-status">
                    {lastSeen
                      ? `${t("chatPage.lastSeen") || "last seen"} ${formatLastSeen(lastSeen)}`
                      : t("chatPage.offline") || "offline"}
                  </span>
                )}
              </div>
            </div>
          </div>

          <div className="header-actions">
            {/* The website does not place calls (owner decision 2026-10-16):
                these buttons point to the app. Web chats are 1:1 only. */}
            <CallInAppButtons
              partnerId={selectedUser || ""}
              partnerName={userName}
              blocked={blockState.blocked}
            />
            <button
              className="action-btn"
              type="button"
              data-testid="chat-header-search"
              onClick={() => setIsSearchOpen(true)}
              aria-haspopup="dialog"
              title={t("chatPage.search.open") || "Search messages"}
              aria-label={t("chatPage.search.open") || "Search messages"}
            >
              <Search size={20} />
            </button>
            <button
              className="action-btn"
              type="button"
              data-testid="chat-header-more"
              onClick={() => setIsInfoOpen(true)}
              aria-haspopup="dialog"
              aria-expanded={isInfoOpen}
              title={t("chatPage.moreOptions") || "More options"}
              aria-label={t("chatPage.moreOptions") || "More options"}
            >
              <MoreVertical size={20} />
            </button>
          </div>
        </div>
      </div>

      {isInfoOpen && (
        <ChatInfoPanel
          userId={selectedUser}
          userName={userName}
          profilePicture={profilePicture}
          onClose={() => setIsInfoOpen(false)}
        />
      )}

      {isSearchOpen && (
        <MessageSearchDialog
          partnerId={selectedUser}
          partnerName={userName}
          onClose={() => setIsSearchOpen(false)}
          onJump={handleJumpFromSearch}
        />
      )}

      <ConnectionBanner />
      {/* Pinned messages bar (renders null when there are none) */}
      <PinnedBar
        pinned={pinnedMessages}
        onJump={handleJumpToMessage}
        onUnpin={(id) =>
          pinMessage(id).unwrap().catch((e) => console.error("Unpin failed:", e))
        }
      />

      {/* Chat Messages */}
      <div
        className="modern-chat-messages"
        ref={chatContainerRef}
        onScroll={handleScroll}
      >
        {(hasMoreHistory || isLoadingOlder) && (
          <div className="load-earlier-row" ref={topSentinelRef}>
            {isLoadingOlder && (
              <span
                className="load-earlier-status"
                role="status"
                data-testid="loading-earlier"
              >
                {t("chatPage.loadingEarlier") || "Loading earlier messages"}
              </span>
            )}
            {/* The button stays for as long as there IS more history — it is
                the fallback for a browser without an observer, and swapping
                it out mid-load took the way back off the screen. */}
            {hasMoreHistory && (
              <button
                type="button"
                className="load-earlier-btn"
                data-testid="load-earlier"
                onClick={loadOlderMessages}
                disabled={isLoadingOlder}
              >
                <ArrowUp size={14} />
                <span>{t("chatPage.loadEarlier") || "Load earlier messages"}</span>
              </button>
            )}
          </div>
        )}

        {sortedMessages.length === 0 && (
          <div className="empty-messages">
            <div className="empty-messages-icon">
              <Send size={36} />
            </div>
            <h3>{t("chatPage.noMessages") || "No messages yet"}</h3>
            <p>{t("chatPage.startConversation") || "Send a message to start the conversation"}</p>
          </div>
        )}

        {messagesByDate.map((group) => (
          <div key={group.dateKey} className="message-date-group">
            <DateSeparator label={group.date} />

            {group.messages.map((msg: Message, index: number) => {
              const isSent = senderIdOf(msg) === userId;
              const position = getMessagePosition(group.messages, index);
              const senderImages = msg.sender.images;
              const avatarUrl =
                senderImages && senderImages.length > 0
                  ? senderImages[0]
                  : profilePicture || "/default-avatar.png";

              return (
                <MessageBubble
                  key={msg._id}
                  message={msg}
                  isSent={isSent}
                  position={position}
                  isFirstInGroup={index === 0}
                  showAvatar={!isSent && (position === "single" || position === "last")}
                  hideAvatarSpace={!isSent && (position === "middle" || position === "first")}
                  avatarUrl={avatarUrl}
                  currentUserId={userId || ""}
                  otherUserName={userName}
                  timeLabel={formatTime(msg.createdAt)}
                  isTranslationOpen={openTranslations.has(msg._id)}
                  targetLanguage={targetLanguage}
                  isPlaying={playingAudioId === msg._id}
                  audioProgress={playingAudioId === msg._id ? audioProgress : 0}
                  audioElapsed={playingAudioId === msg._id ? audioElapsed : 0}
                  onTogglePlayback={handleTogglePlayback}
                  onOpenActions={setActiveActionMsg}
                  onToggleReaction={handleToggleReaction}
                  onToggleTranslation={toggleTranslation}
                  onCorrect={setCorrectingMessage}
                  onCorrectionAccepted={handleLocalCorrectionAccepted}
                  onRetry={handleRetry}
                  onOpenStory={openStory}
                />
              );
            })}
          </div>
        ))}

        {/* Typing Indicator */}
        {isTyping && (
          <div className="modern-message received modern-message--gap-normal">
            <div className="message-avatar">
              <img
                src={profilePicture || "/default-avatar.png"}
                alt={userName}
                loading="lazy"
                decoding="async"
              />
            </div>
            <div className="message-wrapper">
              <div className="typing-indicator-bubble">
                <div className="typing-animation">
                  <div className="typing-dot"></div>
                  <div className="typing-dot"></div>
                  <div className="typing-dot"></div>
                </div>
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* The way back down. Shown whenever the newest message is off screen,
          so there is always a route back; the badge says how much landed
          while the reader was up in the history. */}
      {!isAtBottom && (
        <button
          type="button"
          className="scroll-to-bottom-btn"
          data-testid="scroll-to-bottom"
          onClick={() => jumpToBottom("smooth")}
          aria-label={
            missedCount > 0
              ? `${t("chatPage.jumpToLatest") || "Jump to latest messages"} (${missedCount})`
              : t("chatPage.jumpToLatest") || "Jump to latest messages"
          }
        >
          {missedCount > 0 && (
            <span className="scroll-to-bottom-count" data-testid="scroll-to-bottom-count">
              {missedCount > 99 ? "99+" : missedCount}
            </span>
          )}
          <ArrowDown size={20} aria-hidden="true" />
        </button>
      )}

      {/* Media Preview */}
      {mediaPreview && (
        <div className="media-preview-bar">
          <div className="media-preview-content">
            {mediaPreview.type === "image" ? (
              <img
                src={mediaPreview.url}
                alt="preview"
                className="media-preview-thumb"
                loading="lazy"
                decoding="async"
              />
            ) : mediaPreview.type === "video" ? (
              <video src={mediaPreview.url} className="media-preview-thumb" />
            ) : (
              <div className="media-preview-file">
                <Paperclip size={20} />
                <span>{mediaPreview.file.name}</span>
              </div>
            )}
          </div>
          <button className="media-preview-cancel" onClick={handleCancelMedia}>
            <X size={18} />
          </button>
        </div>
      )}

      {/* Voice Recording Bar */}
      {isRecording && !blockState.blocked && (
        <div className="voice-recording-bar">
          <div className="recording-indicator">
            <div className="recording-dot" />
            <span className="recording-time">{formatDuration(recordingDuration)}</span>
          </div>
          <div className="recording-actions">
            <button className="recording-cancel-btn" onClick={cancelRecording}>
              <X size={20} />
            </button>
            <button className="recording-send-btn" onClick={sendVoiceRecording}>
              <Send size={18} />
            </button>
          </div>
        </div>
      )}

      {/* Message Input — or, in a blocked chat, the banner that replaces it. */}
      {blockState.blocked ? (
        <BlockedChatBanner iBlocked={blockState.iBlocked} onManage={() => setIsInfoOpen(true)} />
      ) : !isRecording && (
        <div className="modern-chat-input">
          {/* Sticker Panel */}
          {isStickerPanelOpen && (
            <StickerPanel
              onSendSticker={handleSendSticker}
              onClose={() => setIsStickerPanelOpen(false)}
            />
          )}

          {/* GIF Picker */}
          {isGifPanelOpen && (
            <GifPickerPanel
              onSelectGif={handleSendGif}
              onClose={() => setIsGifPanelOpen(false)}
            />
          )}

          {/* Reply band (renders null when not replying) */}
          <ReplyComposerBar replyingTo={replyingTo} onCancel={() => setReplyingTo(null)} />

          <form onSubmit={handleSendMessage} className="input-form">
            <div className="input-container">
              <button
                type="button"
                className="attachment-btn"
                title={t("chatPage.input.attachFile") || "Attach file"}
                aria-label={t("chatPage.input.attachFile") || "Attach file"}
                onClick={handleAttachmentClick}
              >
                {mediaPreview ? <ImageIcon size={20} /> : <Paperclip size={20} />}
              </button>
              <LocationShareButton receiverId={selectedUser} disabled={!!mediaPreview} />

              <div className="text-input-wrapper">
                <input
                  type="text"
                  placeholder={
                    mediaPreview
                      ? t("chatPage.addCaption") || "Add a caption..."
                      : t("chatPage.messagePlaceholder") || "Message..."
                  }
                  value={newMessage}
                  onChange={(e) => {
                    setNewMessage(e.target.value);
                    handleTyping();
                  }}
                  onFocus={() => setIsStickerPanelOpen(false)}
                  className="modern-text-input"
                />
                <button
                  type="button"
                  className={`emoji-btn ${isStickerPanelOpen ? "active" : ""}`}
                  title={t("chatPage.input.stickers") || "Stickers"}
                  aria-label={t("chatPage.input.stickers") || "Stickers"}
                  onClick={() => {
                    setIsStickerPanelOpen((v) => !v);
                    setIsGifPanelOpen(false);
                  }}
                >
                  {isStickerPanelOpen ? <X size={20} /> : <Smile size={20} />}
                </button>
                <button
                  type="button"
                  className={`emoji-btn ${isGifPanelOpen ? "active" : ""}`}
                  title={t("chatPage.input.sendGif") || "Send a GIF"}
                  aria-label={t("chatPage.input.sendGif") || "Send a GIF"}
                  onClick={() => {
                    setIsGifPanelOpen((v) => !v);
                    setIsStickerPanelOpen(false);
                  }}
                >
                  <FileImage size={20} />
                </button>
              </div>

              {newMessage.trim() || mediaPreview ? (
                <button
                  type="submit"
                  className="send-btn active"
                  disabled={isSending}
                >
                  {isSending ? (
                    <div className="spinner spinner--sm"></div>
                  ) : (
                    <Send size={18} />
                  )}
                </button>
              ) : (
                <button
                  type="button"
                  className="send-btn mic-btn"
                  title={t("chatPage.input.voiceMessage") || "Voice message"}
                  aria-label={
                    t("chatPage.input.voiceMessage") || "Voice message"
                  }
                  onClick={startRecording}
                >
                  <Mic size={18} />
                </button>
              )}
            </div>
          </form>
        </div>
      )}

      {/* Message action menu (opened via hover trigger / right-click) */}
      {activeActionMsg && (
        <div
          className="msg-action-overlay"
          onClick={() => setActiveActionMsg(null)}
        >
          <div onClick={(e) => e.stopPropagation()}>
            <MessageActionMenu
              message={activeActionMsg}
              meId={userId || ""}
              onReply={() => setReplyingTo(activeActionMsg)}
              onForward={() => setForwardMsg(activeActionMsg)}
              onCopy={() =>
                navigator.clipboard?.writeText(activeActionMsg.message || "")
              }
              onPin={() =>
                pinMessage(activeActionMsg._id)
                  .unwrap()
                  .catch((e) => console.error("Pin failed:", e))
              }
              onBookmark={() =>
                bookmarkMessage(activeActionMsg._id)
                  .unwrap()
                  .then(() => notify.success(t("chatPage.bookmarks.added") || "Saved"))
                  .catch((e: any) =>
                    notify.error(
                      (e && e.data && (e.data.error || e.data.message)) ||
                        t("chatPage.bookmarks.addFailed") ||
                        "Couldn't save the message"
                    )
                  )
              }
              onTts={() => handleTtsMessage(activeActionMsg)}
              onEdit={() => handleEditMessageAction(activeActionMsg)}
              onDelete={() => handleDeleteMessageAction(activeActionMsg)}
              onReact={(emoji) => handleToggleReaction(activeActionMsg, emoji)}
              onClose={() => setActiveActionMsg(null)}
            />
          </div>
        </div>
      )}

      {editingMsg && (
        <EditMessageDialog
          initialText={editingMsg.message || ""}
          busy={editBusy}
          error={editError}
          onSave={handleEditSave}
          onCancel={() => {
            if (!editBusy) setEditingMsg(null);
          }}
        />
      )}
      {deletingMsg && (
        <DeleteMessageDialog
          canDeleteForEveryone={canDeleteForEveryone(deletingMsg, userId || "")}
          busy={deleteBusy}
          error={deleteError}
          onDelete={handleDeleteConfirm}
          onCancel={() => {
            if (!deleteBusy) setDeletingMsg(null);
          }}
        />
      )}
      {sendError && <SendErrorDialog error={sendError} onClose={() => setSendError(null)} />}
      {/* Forward dialog */}
      <ForwardDialog
        open={!!forwardMsg}
        onForward={(ids) => {
          if (forwardMsg)
            forwardMessage({ messageId: forwardMsg._id, receivers: ids })
              .unwrap()
              .catch((e) => console.error("Forward failed:", e));
          setForwardMsg(null);
        }}
        onClose={() => setForwardMsg(null)}
      />

      {correctingMessage && (
        <CorrectionModal
          message={{
            _id: correctingMessage._id,
            content: correctingMessage.message,
            message: correctingMessage.message,
            sender: {
              _id: correctingMessage.sender._id,
              name: correctingMessage.sender.name,
            },
          }}
          onClose={() => setCorrectingMessage(null)}
          onSubmit={async ({ originalText, correctedText, explanation }) => {
            if (isSendingCorrection) return;
            const targetMsg = correctingMessage;
            setCorrectingMessage(null);
            try {
              const result: any = await sendCorrection({
                messageId: targetMsg._id,
                correctedText,
                explanation,
              }).unwrap();
              // Use API response corrections if available; socket event is the
              // canonical update, but this covers the gap before it arrives.
              const serverCorrections: MessageCorrection[] | undefined =
                Array.isArray(result?.data) ? result.data : undefined;
              setMessages((prev) =>
                prev.map((m) => {
                  if (m._id !== targetMsg._id) return m;
                  if (serverCorrections) {
                    return { ...m, corrections: serverCorrections };
                  }
                  // Fallback: add optimistic correction card
                  const optimistic: MessageCorrection = {
                    _id: `opt-${Date.now()}`,
                    corrector: { _id: userId || "", name: currentUserName || "You" },
                    originalText: originalText || targetMsg.message,
                    correctedText,
                    explanation,
                    isAccepted: false,
                  };
                  const existing = m.corrections || [];
                  return { ...m, corrections: [...existing, optimistic] };
                })
              );
            } catch (e: any) {
              console.error("[sendCorrection] failed:", e);
              alert(e?.data?.message || "Failed to send correction");
            }
          }}
        />
      )}
    </div>
  );
};

export default ChatContent;
