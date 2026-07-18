import React, { useState, useEffect, useRef, useCallback, useMemo } from "react";
import { Form, Container } from "react-bootstrap";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import {
  useCreateMessageMutation,
  useGetConversationQuery,
  useSendVoiceMessageMutation,
  useSendMediaMessageMutation,
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
import ReactionRow from "./actions/ReactionRow";
import PinnedBar from "./actions/PinnedBar";
import ReplyComposerBar from "./actions/ReplyComposerBar";
import { canDeleteForEveryone } from "./lib/messageActions";
import StickerPanel from "./StickerPanel";
import "./StickerPanel.css";
import GifPickerPanel from "./GifPickerPanel";
import { useSocket } from "./hooks/useSocket";
import CorrectionCard, { MessageCorrection } from "./components/CorrectionCard";
import CorrectionModal from "./components/CorrectionModal";
import TranslationCard from "./components/TranslationCard";
import { useSendCorrectionMutation } from "../../store/slices/learningSlice";
import {
  ArrowLeft,
  Phone,
  Video,
  MoreVertical,
  Paperclip,
  Smile,
  Send,
  Mic,
  AlertCircle,
  RefreshCw,
  X,
  Play,
  Pause,
  Image as ImageIcon,
  Edit3,
  Globe,
  FileImage,
} from "lucide-react";
import { useNavigate } from "react-router-dom";

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

interface MessageSender {
  _id: string;
  name: string;
  username?: string;
  images?: string[];
  userMode?: string;
}

interface MessageReceiver {
  _id: string;
  name: string;
  username?: string;
  images?: string[];
}

interface MessageMedia {
  url: string;
  type: string;
  thumbnail?: string;
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  duration?: number;
  waveform?: number[];
  dimensions?: { width: number; height: number };
}

interface Message {
  _id: string;
  message: string;
  sender: MessageSender;
  receiver: MessageReceiver | string;
  messageType?: string;
  read?: boolean;
  readAt?: string;
  createdAt: string;
  updatedAt?: string;
  isOptimistic?: boolean;
  status?: "sending" | "sent" | "delivered" | "read" | "error";
  media?: MessageMedia;
  replyTo?: { _id: string; message: string; sender: { _id: string; name: string } };
  corrections?: MessageCorrection[];
  reactions?: Array<{ user: string; emoji: string; createdAt?: string }>;
  isEdited?: boolean;
  editedAt?: string;
  pinned?: boolean;
}

const getReceiverId = (receiver: MessageReceiver | string): string => {
  if (typeof receiver === "object" && receiver !== null) {
    return receiver._id;
  }
  return receiver;
};

const formatDuration = (seconds: number): string => {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
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
  const userId = useSelector(
    (state: RootState) => state.auth.userInfo?.user?._id
  );
  const currentUserName = useSelector(
    (state: RootState) => state.auth.userInfo?.user?.name
  );

  const { data, error, isLoading } = useGetConversationQuery(
    {
      senderId: userId,
      receiverId: selectedUser,
    },
    {
      skip: !userId || !selectedUser,
    }
  );

  const [createMessage] = useCreateMessageMutation();
  const [sendVoiceMessage] = useSendVoiceMessageMutation();
  const [sendMediaMessage] = useSendMediaMessageMutation();

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
  const isAtBottomRef = useRef(true);

  // Shared socket
  const { socket, isConnected, emit } = useSocket();

  // Keep selectedUserRef in sync
  useEffect(() => {
    selectedUserRef.current = selectedUser;
  }, [selectedUser]);

  // Update online status when initial props change
  useEffect(() => {
    setIsOnline(initialIsOnline);
    setLastSeen(initialLastSeen);
  }, [initialIsOnline, initialLastSeen, selectedUser]);

  // ========== Socket event listeners (shared socket) ==========
  useEffect(() => {
    if (!socket) return;

    const handleNewMessage = (notificationData: {
      message: Message;
      unreadCount: number;
      senderId?: string;
    }) => {
      console.log("[ChatContent] newMessage received:", notificationData);
      const newMsg = notificationData.message;
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

        if (newMsg.sender._id === currentSelectedUser && socket.connected) {
          socket.emit("markAsRead", { senderId: currentSelectedUser });
        }
      }
    };

    const handleMediaMessage = (data: { message: Message }) => {
      const newMsg = data.message;
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

        if (newMsg.sender._id === currentSelectedUser && socket.connected) {
          socket.emit("markAsRead", { senderId: currentSelectedUser });
        }
      }
    };

    const handleMessageSent = (data: { message: Message; receiverId: string }) => {
      const currentSelectedUser = selectedUserRef.current;
      if (data.receiverId === currentSelectedUser) {
        setMessages((prev) => {
          // If already in state as our optimistic/sent message, upgrade to delivered
          if (prev.some((msg) => msg._id === data.message._id)) {
            return prev.map((msg) =>
              msg._id === data.message._id ? { ...msg, status: "delivered" } : msg
            );
          }
          return [...prev, { ...data.message, status: "delivered" }];
        });
      }
    };

    const handleMessagesRead = (data: { readBy: string }) => {
      if (data.readBy === selectedUserRef.current) {
        setMessages((prev) =>
          prev.map((msg) => {
            if (msg.sender._id === userId) {
              return { ...msg, status: "read", read: true, readAt: new Date().toISOString() };
            }
            return msg;
          })
        );
      }
    };

    const handleMessageDeleted = (data: { messageId: string }) => {
      setMessages((prev) => prev.filter((msg) => msg._id !== data.messageId));
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

    const handleMessageError = (errorData: { message: string; error: string }) => {
      console.error("[Socket] Message error:", errorData);
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
    };

    const handleMessageSendError = (errorData: { error?: string }) => {
      console.error("[Socket] messageSendError:", errorData);
    };

    const handleQueuedMessages = (
      batch: Array<{ message: Message; senderId?: string }>
    ) => {
      if (!Array.isArray(batch) || batch.length === 0) return;
      const currentSelectedUser = selectedUserRef.current;
      setMessages((prev) => {
        const existingIds = new Set(prev.map((m) => m._id));
        const incoming = batch
          .map((entry) => entry?.message)
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
    socket.on("messageSendError", handleMessageSendError);
    socket.on("queuedMessages", handleQueuedMessages);

    return () => {
      socket.off("newMessage", handleNewMessage);
      socket.off("newVoiceMessage", handleMediaMessage);
      socket.off("newVideoMessage", handleMediaMessage);
      socket.off("messageSent", handleMessageSent);
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
      socket.off("messageSendError", handleMessageSendError);
      socket.off("queuedMessages", handleQueuedMessages);
    };
  }, [socket, userId]);

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

  // Load initial messages and mark as read
  useEffect(() => {
    if ((data as any)?.data) {
      const loadedMessages = (data as any).data.map((msg: Message) => ({
        ...msg,
        status: msg.status || (msg.read ? "read" : "delivered"),
      }));
      setMessages(loadedMessages);

      if (socket?.connected && selectedUser) {
        socket.emit("markAsRead", { senderId: selectedUser });
      }
    }
  }, [data, selectedUser, socket]);

  // Clear state when switching conversations
  useEffect(() => {
    setIsTyping(false);
    setNewMessage("");
    setMediaPreview(null);
    stopRecording();
  }, [selectedUser]);

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
    isAtBottomRef.current =
      container.scrollHeight - container.scrollTop - container.clientHeight < threshold;
  }, []);

  // Auto-scroll
  useEffect(() => {
    if (messages.length > 0 && isAtBottomRef.current) {
      messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages]);

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

  const finalizeOptimistic = (tempId: string, msgData: any) => {
    setMessages((prev) =>
      prev.map((m) =>
        m._id === tempId ? { ...msgData, status: "delivered", isOptimistic: false } : m
      )
    );
  };

  const markOptimisticError = (tempId: string) => {
    setMessages((prev) =>
      prev.map((m) =>
        m._id === tempId ? { ...m, status: "error", isOptimistic: false } : m
      )
    );
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

    let resolved = false;

    if (socket?.connected) {
      socket.emit(
        "sendMessage",
        { receiver: selectedUser, message: messageToSend },
        (response: any) => {
          if (resolved) return;
          resolved = true;
          setIsSending(false);

          if (response?.status === "success" && response?.message) {
            setMessages((prev) =>
              prev.map((msg) =>
                msg._id === tempId
                  ? { ...response.message, status: "delivered", isOptimistic: false }
                  : msg
              )
            );
          } else {
            sendViaRestApi(tempId, messageToSend);
          }
        }
      );

      setTimeout(() => {
        if (resolved) return;
        resolved = true;
        sendViaRestApi(tempId, messageToSend);
      }, 5000);
    } else {
      resolved = true;
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
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId
            ? { ...msgData, status: "delivered", isOptimistic: false }
            : msg
        )
      );
      setIsSending(false);
    } catch (err) {
      console.error("REST API send failed:", err);
      setIsSending(false);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
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

    let resolved = false;
    if (socket?.connected) {
      socket.emit(
        "sendMessage",
        { receiver: selectedUser, message: text, messageType },
        (response: any) => {
          if (resolved) return;
          resolved = true;
          if (response?.status === "success" && response?.message) {
            setMessages((prev) =>
              prev.map((msg) =>
                msg._id === tempId
                  ? { ...response.message, status: "delivered", isOptimistic: false }
                  : msg
              )
            );
          } else {
            sendInlineMessageViaRest(tempId, text, messageType);
          }
        }
      );
      setTimeout(() => {
        if (resolved) return;
        resolved = true;
        sendInlineMessageViaRest(tempId, text, messageType);
      }, 5000);
    } else {
      resolved = true;
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
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId
            ? { ...msgData, status: "delivered", isOptimistic: false }
            : msg
        )
      );
    } catch (err) {
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error" } : msg
        )
      );
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

    let resolved = false;

    if (socket?.connected) {
      socket.emit(
        "sendMessage",
        { receiver: selectedUser, message: sticker, messageType: "sticker" },
        (response: any) => {
          if (resolved) return;
          resolved = true;

          if (response?.status === "success" && response?.message) {
            setMessages((prev) =>
              prev.map((msg) =>
                msg._id === tempId
                  ? { ...response.message, status: "delivered", isOptimistic: false }
                  : msg
              )
            );
          } else {
            // Fallback to REST API
            sendStickerViaRest(tempId, sticker);
          }
        }
      );

      setTimeout(() => {
        if (resolved) return;
        resolved = true;
        sendStickerViaRest(tempId, sticker);
      }, 5000);
    } else {
      resolved = true;
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
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId
            ? { ...msgData, status: "delivered", isOptimistic: false }
            : msg
        )
      );
    } catch (err) {
      console.error("Sticker send failed:", err);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
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

      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId
            ? { ...msgData, status: "delivered", isOptimistic: false }
            : msg
        )
      );
    } catch (err) {
      console.error("Media upload failed:", err);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
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

      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: MediaRecorder.isTypeSupported("audio/webm;codecs=opus")
          ? "audio/webm;codecs=opus"
          : "audio/webm",
      });
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

    const audioBlob = new Blob(audioChunksRef.current, { type: "audio/webm" });
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
      formData.append("voice", audioBlob, `voice-${Date.now()}.webm`);
      formData.append("receiver", selectedUser);
      formData.append("duration", duration.toString());

      const result: any = await sendVoiceMessage(formData).unwrap();
      const msgData = result.data || result;

      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId
            ? { ...msgData, status: "delivered", isOptimistic: false }
            : msg
        )
      );
    } catch (err) {
      console.error("Voice send failed:", err);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempId ? { ...msg, status: "error", isOptimistic: false } : msg
        )
      );
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
    setMessages((prev) => prev.filter((msg) => msg._id !== failedMsg._id));
    const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const optimisticMessage: Message = {
      ...failedMsg,
      _id: tempId,
      status: "sending",
      isOptimistic: true,
    };
    setMessages((prev) => [...prev, optimisticMessage]);
    setIsSending(true);
    isAtBottomRef.current = true;

    let resolved = false;

    if (socket?.connected && !failedMsg.media) {
      socket.emit(
        "sendMessage",
        { receiver: selectedUser, message: failedMsg.message },
        (response: any) => {
          if (resolved) return;
          resolved = true;
          setIsSending(false);

          if (response?.status === "success" && response?.message) {
            setMessages((prev) =>
              prev.map((msg) =>
                msg._id === tempId
                  ? { ...response.message, status: "delivered", isOptimistic: false }
                  : msg
              )
            );
          } else {
            sendViaRestApi(tempId, failedMsg.message);
          }
        }
      );

      setTimeout(() => {
        if (resolved) return;
        resolved = true;
        sendViaRestApi(tempId, failedMsg.message);
      }, 5000);
    } else {
      resolved = true;
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

  const handleEditMessageAction = useCallback(
    (msg: Message) => {
      const next = window.prompt(t("chatPage.edit") || "Edit message", msg.message || "");
      if (next == null) return;
      const content = next.trim();
      if (!content || content === msg.message) return;
      editMessage({ messageId: msg._id, content })
        .unwrap()
        .then(() => {
          setMessages((prev) =>
            prev.map((m) =>
              m._id === msg._id ? { ...m, message: content, isEdited: true } : m
            )
          );
        })
        .catch((err) => console.error("Edit failed:", err));
    },
    [editMessage, t]
  );

  const handleDeleteMessageAction = useCallback(
    (msg: Message) => {
      const forEveryone = canDeleteForEveryone(msg, userId || "");
      const confirmed = window.confirm(
        forEveryone ? "Delete this message for everyone?" : "Delete this message?"
      );
      if (!confirmed) return;
      deleteMessageApi({ messageId: msg._id, forEveryone })
        .unwrap()
        .then(() => setMessages((prev) => prev.filter((m) => m._id !== msg._id)))
        .catch((err) => console.error("Delete failed:", err));
    },
    [deleteMessageApi, userId]
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

  const getBubbleRadius = (isSent: boolean, position: string): string => {
    if (isSent) {
      switch (position) {
        case "single": return "18px 18px 4px 18px";
        case "first": return "18px 18px 4px 18px";
        case "middle": return "18px 4px 4px 18px";
        case "last": return "18px 4px 18px 18px";
        default: return "18px";
      }
    } else {
      switch (position) {
        case "single": return "18px 18px 18px 4px";
        case "first": return "18px 18px 18px 4px";
        case "middle": return "4px 18px 18px 4px";
        case "last": return "4px 18px 18px 18px";
        default: return "18px";
      }
    }
  };

  const renderStatusIcon = (msg: Message) => {
    if (msg.sender._id !== userId) return null;

    switch (msg.status) {
      case "sending":
        return <span className="status-text sending">Sending…</span>;
      case "delivered":
        return <span className="status-text delivered">Sent</span>;
      case "read":
        return <span className="status-text read">Read</span>;
      case "error":
        return <span className="status-text error">Failed</span>;
      default:
        return <span className="status-text delivered">Sent</span>;
    }
  };

  // ========== Render voice message bubble content ==========
  const renderVoiceMessage = (msg: Message) => {
    const duration = msg.media?.duration || 0;
    const isPlaying = playingAudioId === msg._id;
    const bars = (msg.media?.waveform || Array(20).fill(0.3)).slice(0, 30);
    const playedCount = isPlaying ? Math.floor(audioProgress * bars.length) : 0;

    return (
      <div className="voice-message">
        <button
          className="voice-play-btn"
          onClick={(e) => {
            e.stopPropagation();
            if (msg.media?.url) toggleAudioPlayback(msg._id, msg.media.url);
          }}
        >
          {isPlaying ? <Pause size={16} /> : <Play size={16} />}
        </button>
        <div className="voice-waveform">
          <div className="voice-waveform-bars">
            {bars.map((v: number, i: number) => (
              <div
                key={i}
                className={`waveform-bar${i < playedCount ? " waveform-bar--played" : ""}`}
                style={{ height: `${Math.max(4, (v || 0.3) * 24)}px` }}
              />
            ))}
          </div>
        </div>
        <span className="voice-duration">
          {isPlaying ? formatDuration(audioElapsed) : formatDuration(duration)}
        </span>
      </div>
    );
  };

  // ========== Render media content in bubble ==========
  const renderMediaContent = (msg: Message) => {
    if (!msg.media || !msg.media.type) return null;

    const mediaType = msg.media.type || msg.messageType;

    if (mediaType === "voice") {
      return renderVoiceMessage(msg);
    }

    if (mediaType === "image" || msg.media.mimeType?.startsWith("image/")) {
      return (
        <div className="message-media">
          <img src={msg.media.url} alt="media" className="message-image" loading="lazy" />
        </div>
      );
    }

    if (mediaType === "video" || msg.media.mimeType?.startsWith("video/")) {
      return (
        <div className="message-media">
          {msg.media.thumbnail ? (
            <div className="video-thumbnail-wrapper">
              <img src={msg.media.thumbnail} alt="video" className="message-image" />
              <div className="video-play-overlay">
                <Play size={32} />
              </div>
            </div>
          ) : (
            <video src={msg.media.url} controls className="message-video" preload="metadata" />
          )}
        </div>
      );
    }

    // Document/file
    return (
      <div className="message-file">
        <Paperclip size={16} />
        <span className="file-name">{msg.media.fileName || "File"}</span>
        {msg.media.fileSize && (
          <span className="file-size">
            {(msg.media.fileSize / 1024).toFixed(0)}KB
          </span>
        )}
      </div>
    );
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
        <AlertCircle size={48} color="#EF4444" />
        <p>{t("chatPage.errorLoading") || "Failed to load conversation"}</p>
      </div>
    );

  return (
    <Container fluid className="modern-chat-container">
      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*,video/*,audio/*,.pdf,.doc,.docx,.txt,.zip"
        style={{ display: "none" }}
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
              <img
                src={profilePicture || "/default-avatar.png"}
                alt={userName}
                className="profile-avatar"
              />
              <div className={`status-pulse ${isOnline ? "online" : "offline"}`}>
                <div className="pulse-dot"></div>
              </div>
            </div>
            <div className="user-details">
              <h3 className="user-name">{userName}</h3>
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
            {/* Voice/Video call buttons removed — calling is mobile-only per
                the documented web scope (Community/Chats/Moments/Profile). */}
            <button
              className="action-btn"
              title={t("chatPage.moreOptions") || "More options"}
              aria-label={t("chatPage.moreOptions") || "More options"}
            >
              <MoreVertical size={20} />
            </button>
          </div>
        </div>
      </div>

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
            <div className="date-separator">
              <span className="date-text">{group.date}</span>
            </div>

            {group.messages.map((msg: Message, index: number) => {
              const isSent = msg.sender._id === userId;
              const position = getMessagePosition(group.messages, index);
              const showAvatar = !isSent && (position === "single" || position === "last");
              const hideAvatarSpace = !isSent && (position === "middle" || position === "first");
              const gap = position === "middle" || position === "last" ? "2px" : "8px";
              const senderImages = msg.sender.images;
              const avatarUrl =
                senderImages && senderImages.length > 0
                  ? senderImages[0]
                  : profilePicture || "/default-avatar.png";

              const isVoice = msg.messageType === "voice" || msg.media?.type === "voice";
              const isSticker = msg.messageType === "sticker";
              const isGif =
                msg.messageType === "gif" ||
                (typeof msg.message === "string" &&
                  /\.gif(\?|$)|giphy\.com\/media/i.test(msg.message));
              const hasMedia = !!msg.media?.type && !isVoice;

              // System placeholder created by createConversationRoom — show as a
              // centered notice instead of a chat bubble.
              if (msg.message === "Conversation started") {
                return (
                  <div key={msg._id} className="system-notice">
                    <span>{t("chatPage.conversationStarted") || "Conversation started"}</span>
                  </div>
                );
              }

              return (
                <div
                  key={msg._id}
                  data-msg-id={msg._id}
                  className={`modern-message ${isSent ? "sent" : "received"} ${
                    msg.status === "error" ? "error" : ""
                  }`}
                  style={{ marginTop: index === 0 ? "0" : gap }}
                  onContextMenu={
                    msg.isOptimistic
                      ? undefined
                      : (e) => {
                          e.preventDefault();
                          setActiveActionMsg(msg);
                        }
                  }
                >
                  {!isSent && (
                    <div
                      className="message-avatar"
                      style={{ visibility: showAvatar ? "visible" : "hidden" }}
                    >
                      {(showAvatar || hideAvatarSpace) && (
                        <img src={avatarUrl} alt={msg.sender.name} />
                      )}
                    </div>
                  )}

                  <div className="message-wrapper">
                    <div
                      className={`message-bubble${isVoice ? " voice-bubble" : ""}${hasMedia ? " media-bubble" : ""}${isSticker ? " sticker-bubble" : ""}`}
                      style={{
                        borderRadius: getBubbleRadius(isSent, position),
                      }}
                    >
                      {isSticker ? (
                        <div className="sticker-message">{msg.message}</div>
                      ) : isGif ? (
                        <img
                          className="gif-message"
                          src={msg.message}
                          alt={t("chatPage.gif.altText") || "GIF"}
                          loading="lazy"
                        />
                      ) : (
                        <>
                          {renderMediaContent(msg)}

                          {msg.replyTo && (
                            <div className="reply-preview">
                              <span className="reply-sender">{msg.replyTo.sender.name}</span>
                              <span className="reply-text">{msg.replyTo.message}</span>
                            </div>
                          )}

                          {msg.message && !isVoice && (
                            <p className="message-text">{msg.message}</p>
                          )}

                          {openTranslations.has(msg._id) && msg.message && (
                            <TranslationCard
                              messageId={msg._id}
                              originalText={msg.message}
                              targetLanguage={targetLanguage}
                              onClose={() => toggleTranslation(msg._id)}
                            />
                          )}

                        </>
                      )}

                      <div className="message-meta">
                        <span className="message-time">
                          {formatTime(msg.createdAt)}
                        </span>
                        {isSent && (
                          <div className="message-status">
                            {renderStatusIcon(msg)}
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Message-actions trigger (opens MessageActionMenu) */}
                    {!msg.isOptimistic && (
                      <button
                        type="button"
                        className="msg-action-trigger"
                        aria-label={t("chatPage.moreOptions") || "More options"}
                        onClick={() => setActiveActionMsg(msg)}
                      >
                        <MoreVertical size={14} />
                      </button>
                    )}

                    {/* Reactions row (renders null when there are none) */}
                    <ReactionRow
                      reactions={msg.reactions}
                      myUserId={userId || ""}
                      onToggle={(emoji) => handleToggleReaction(msg, emoji)}
                    />

                    {/* Correction card lives OUTSIDE the bubble so it always
                        renders on a white background — readable for both
                        sent (teal) and received (grey) bubbles. */}
                    {msg.corrections && msg.corrections.length > 0 && (
                      <CorrectionCard
                        messageId={msg._id}
                        correction={msg.corrections[0]}
                        isMe={isSent}
                        currentUserId={userId || ""}
                        otherUserName={userName}
                        onAccepted={(correctionId) => {
                          setMessages((prev) =>
                            prev.map((m) =>
                              m._id === msg._id
                                ? {
                                    ...m,
                                    corrections: (m.corrections || []).map(
                                      (c) =>
                                        c._id === correctionId
                                          ? { ...c, isAccepted: true }
                                          : c
                                    ),
                                  }
                                : m
                            )
                          );
                        }}
                      />
                    )}

                    {!isSent && !isSticker && !isVoice && !hasMedia && msg.message && (
                      <div className="message-chip-row">
                        {/* Hide Correct chip once a correction already exists */}
                        {!(msg.corrections && msg.corrections.length > 0) && (
                          <button
                            type="button"
                            className="correct-chip"
                            onClick={() => setCorrectingMessage(msg)}
                            title="Suggest a correction"
                          >
                            <Edit3 size={12} />
                            <span>{t("chatPage.correct") || "Correct"}</span>
                          </button>
                        )}
                        <button
                          type="button"
                          className={`translate-chip ${openTranslations.has(msg._id) ? "active" : ""}`}
                          onClick={() => toggleTranslation(msg._id)}
                          title="Translate this message"
                        >
                          <Globe size={12} />
                          <span>
                            {openTranslations.has(msg._id)
                              ? t("chatPage.hide_translation") || "Hide"
                              : t("chatPage.translate") || "Translate"}
                          </span>
                        </button>
                      </div>
                    )}

                    {msg.status === "error" && (
                      <button
                        className="retry-btn"
                        onClick={() => handleRetryMessage(msg)}
                        title={t("chatPage.retrySending") || "Retry sending"}
                      >
                        <RefreshCw size={14} />
                        <span>{t("chatPage.retry") || "Retry"}</span>
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        ))}

        {/* Typing Indicator */}
        {isTyping && (
          <div className="modern-message received" style={{ marginTop: "8px" }}>
            <div className="message-avatar">
              <img src={profilePicture || "/default-avatar.png"} alt={userName} />
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

      {/* Media Preview */}
      {mediaPreview && (
        <div className="media-preview-bar">
          <div className="media-preview-content">
            {mediaPreview.type === "image" ? (
              <img src={mediaPreview.url} alt="preview" className="media-preview-thumb" />
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
      {isRecording && (
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

      {/* Message Input */}
      {!isRecording && (
        <div className="modern-chat-input" style={{ position: "relative" }}>
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

          <Form onSubmit={handleSendMessage} className="input-form">
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

              <div className="text-input-wrapper">
                <Form.Control
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
                    <div className="spinner" style={{ width: 18, height: 18, borderWidth: 2 }}></div>
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
          </Form>
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
                  .catch((e) => console.error("Bookmark failed:", e))
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
    </Container>
  );
};

export default ChatContent;
