import React, { useEffect, useRef, useCallback, useState, useMemo } from "react";
import ConfirmDialog from "../../design/ConfirmDialog";
import {
  useGetConversationsQuery,
  useDeleteConversationMutation,
  usePinConversationMutation,
  useUnpinConversationMutation,
  useMuteConversationMutation,
  useUnmuteConversationMutation,
  useArchiveConversationMutation,
  useUnarchiveConversationMutation,
} from "../../store/slices/chatSlice";
import { Bounce, toast } from "react-toastify";
import { Link } from "react-router-dom";
import { Archive, ArchiveRestore, Bell, BellOff, MoreVertical, Pin, PinOff, Trash2 } from "lucide-react";
import { useSelector } from "react-redux";
import { RootState } from "../../store/index";
import { useSocket } from "./hooks/useSocket";
import { findConversationWith, CONVERSATIONS_PAGE } from "./lib/conversationMatch";
import { previewOf } from "./lib/conversationPreview";
import { bumpUnread, displayUnread, pruneOverrides, Counts } from "./lib/unreadOverrides";
import MuteDurationDialog from "./components/MuteDurationDialog";
import { muteArgs } from "./lib/muteDurations";
import { useTranslation } from "react-i18next";
import "./UsersList.css";

// ---------- Types ----------

interface User {
  _id: string;
  name: string;
  avatar?: string;
  lastMessage?: string;
  unreadCount?: number;
  lastMessageTime?: Date;
  imageUrls: string[];
  status?: "online" | "offline" | "away" | "busy";
  lastSeen?: Date;
  // Threaded through from the conversation record so per-conversation actions
  // (pin/unpin/delete) can hit the right document instead of looking it up.
  conversationId?: string;
  isPinned?: boolean;
  isMuted?: boolean;
  isArchived?: boolean;
}

interface OnlineUser {
  userId: string;
  status: "online" | "offline" | "away" | "busy";
  lastSeen: string | null;
  deviceCount?: number;
}

interface Message {
  _id: string;
  sender: User;
  receiver: User;
  message?: string;
  content?: string;
  createdAt: string;
  read: boolean;
  messageType?: string;
  media?: { type?: string; url?: string; fileName?: string };
}

interface UsersListProps {
  onSelectUser: (
    userId: string,
    userName: string,
    profilePicture: string,
    isOnline?: boolean,
    lastSeen?: string
  ) => void;
  activeUserId?: string | null;
  searchQuery?: string;
}

// ---------- Helpers ----------

const formatTime = (date: Date): string => {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffHours = diffMs / (1000 * 60 * 60);

  if (diffHours < 24) {
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }
  if (diffHours < 168) {
    return date.toLocaleDateString([], { weekday: "short" });
  }
  return date.toLocaleDateString([], { month: "short", day: "numeric" });
};

const formatLastSeen = (date: Date, t: (key: string, options?: any) => string): string => {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return t("chatPage.justNow") || "just now";
  if (diffMin < 60) return t("chatPage.minutesAgo", { count: diffMin }) || `${diffMin}m ago`;
  const diffHours = Math.floor(diffMin / 60);
  if (diffHours < 24) return t("chatPage.hoursAgo", { count: diffHours }) || `${diffHours}h ago`;
  return date.toLocaleDateString([], { month: "short", day: "numeric" });
};


// ---------- Component ----------

const UsersList: React.FC<UsersListProps> = ({
  onSelectUser,
  activeUserId,
  searchQuery = "",
}) => {
  const { t } = useTranslation();
  const currentUser = useSelector(
    (state: RootState) => state.auth.userInfo?.user
  );
  // The list is GET /conversations and nothing else, as in the app. It used
  // to be merged with GET /messages/user/:id (500 raw messages), which knows
  // nothing about deleted conversations or blocks -- every deleted chat came
  // back. The shared argument: ChatInfoPanel asks with the same one.
  const {
    data: conversationsData,
    isLoading,
    isError,
    refetch: refetchConversations,
  } = useGetConversationsQuery(CONVERSATIONS_PAGE, { skip: !currentUser?._id });

  const [deleteConversation] = useDeleteConversationMutation();
  const [pinConversation] = usePinConversationMutation();
  const [unpinConversation] = useUnpinConversationMutation();
  const [muteConversation] = useMuteConversationMutation();
  const [unmuteConversation] = useUnmuteConversationMutation();
  const [openMenuFor, setOpenMenuFor] = useState<string | null>(null);
  const [showArchived, setShowArchived] = useState(false);
  const [mutingPartner, setMutingPartner] = useState<User | null>(null);
  const [archiveConversation] = useArchiveConversationMutation();
  const [unarchiveConversation] = useUnarchiveConversationMutation();
  // Whether the action dropdown should open upward (when the kebab is near
  // the bottom of the viewport and a downward menu would clip).
  const [menuOpensUp, setMenuOpensUp] = useState(false);

  // The conversation document, found from the partner. Same lookup pin and
  // delete already did inline: a partner row can come from getUserMessages,
  // which knows nothing about conversations.
  const resolveConversationId = useCallback(
    (partner: User): string | undefined =>
      partner.conversationId ||
      findConversationWith(conversationsData?.data, partner._id)?._id,
    [conversationsData]
  );

  const handleToggleMute = useCallback(
    async (e: React.MouseEvent, partner: User) => {
      e.stopPropagation();
      setOpenMenuFor(null);

      const resolvedConversationId = resolveConversationId(partner);
      if (!resolvedConversationId) {
        toast.error(
          t("chatPage.actions.noConversationYet") ||
            "Start the conversation first",
          { autoClose: 3000, theme: "colored", transition: Bounce }
        );
        return;
      }

      try {
        if (!partner.isMuted) {
          // How long is asked first; MuteDurationDialog calls handleMuteFor.
          setMutingPartner(partner);
          return;
        }
        await unmuteConversation(resolvedConversationId).unwrap();
        toast.success(
          partner.isMuted
            ? t("chatPage.actions.unmuted") || "Notifications are back on"
            : t("chatPage.actions.muted") || "Notifications muted",
          { autoClose: 1800, theme: "colored", transition: Bounce }
        );
        refetchConversations();
      } catch (err: any) {
        const message =
          err?.data?.error ||
          err?.data?.message ||
          t("chatPage.actions.muteFailed") ||
          "Couldn't update notifications";
        toast.error(message, { autoClose: 3000, theme: "colored", transition: Bounce });
      }
    },
    [unmuteConversation, refetchConversations, resolveConversationId, t]
  );

  const handleMuteFor = useCallback(
    async (ms: number | null) => {
      const partner = mutingPartner;
      setMutingPartner(null);
      const conversationId = partner ? resolveConversationId(partner) : undefined;
      if (!conversationId) return;
      try {
        await muteConversation(muteArgs(conversationId, ms)).unwrap();
        toast.success(t("chatPage.actions.muted") || "Notifications muted", {
          autoClose: 1800,
          theme: "colored",
          transition: Bounce,
        });
        refetchConversations();
      } catch (err: any) {
        toast.error(
          err?.data?.error || err?.data?.message || t("chatPage.actions.muteFailed") || "Couldn't update notifications",
          { autoClose: 3000, theme: "colored", transition: Bounce }
        );
      }
    },
    [mutingPartner, muteConversation, refetchConversations, resolveConversationId, t]
  );

  const handleToggleArchive = useCallback(
    async (e: React.MouseEvent, partner: User) => {
      e.stopPropagation();
      setOpenMenuFor(null);
      const conversationId = resolveConversationId(partner);
      if (!conversationId) return;
      try {
        if (partner.isArchived) await unarchiveConversation(conversationId).unwrap();
        else await archiveConversation(conversationId).unwrap();
        refetchConversations();
      } catch (err: any) {
        toast.error(
          err?.data?.error || err?.data?.message || t("chatPage.archive.failed") || "Couldn't update the archive",
          { autoClose: 3000, theme: "colored", transition: Bounce }
        );
      }
    },
    [archiveConversation, unarchiveConversation, refetchConversations, resolveConversationId, t]
  );

  const handleTogglePin = useCallback(
    async (e: React.MouseEvent, partner: User) => {
      e.stopPropagation();
      setOpenMenuFor(null);

      // The partner record may not have conversationId threaded onto it
      // (e.g. if it came in through getUserMessages and the conversation
      // hadn't been fetched yet). Fall back to scanning conversationsData
      // for a matching participant before giving up.
      const resolvedConversationId = resolveConversationId(partner);

      if (!resolvedConversationId) {
        toast.error(
          t("chatPage.actions.noConversationYet") ||
            "Start the conversation first to pin it",
          { autoClose: 3000, theme: "colored", transition: Bounce }
        );
        return;
      }

      const action = partner.isPinned ? "unpin" : "pin";
      const endpoint = `/api/v1/conversations/${resolvedConversationId}/${action}`;
      console.log(
        `[UsersList:${action}] >> POST ${endpoint}`,
        { partner: partner.name, conversationId: resolvedConversationId }
      );

      try {
        const response = partner.isPinned
          ? await unpinConversation(resolvedConversationId).unwrap()
          : await pinConversation(resolvedConversationId).unwrap();
        console.log(`[UsersList:${action}] << OK`, response);

        toast.success(
          partner.isPinned
            ? t("chatPage.actions.unpinned") || "Conversation unpinned"
            : t("chatPage.actions.pinned") || "Conversation pinned",
          { autoClose: 1800, theme: "colored", transition: Bounce }
        );
        refetchConversations();
      } catch (err: any) {
        console.error(`[UsersList:${action}] << FAIL`, {
          status: err?.status,
          data: err?.data,
          raw: err,
        });
        const message =
          err?.data?.error ||
          err?.data?.message ||
          t("chatPage.actions.pinFailed") ||
          "Couldn't update pin";
        toast.error(message, { autoClose: 3000, theme: "colored", transition: Bounce });
      }
    },
    [
      pinConversation,
      unpinConversation,
      refetchConversations,
      resolveConversationId,
      t,
    ]
  );

  // Close the action menu when clicking anywhere outside it.
  useEffect(() => {
    if (!openMenuFor) return;
    const onDocClick = () => setOpenMenuFor(null);
    document.addEventListener("click", onDocClick);
    return () => document.removeEventListener("click", onDocClick);
  }, [openMenuFor]);

  // Shared socket
  const { socket } = useSocket();
  const activeUserIdRef = useRef<string | null | undefined>(activeUserId);

  // State
  const [onlineUsers, setOnlineUsers] = useState<OnlineUser[]>([]);
  const [userStatuses, setUserStatuses] = useState<
    Record<string, { status: string; lastSeen?: Date }>
  >({});
  const [typingUsers, setTypingUsers] = useState<Set<string>>(new Set());
  const [unreadCounts, setUnreadCounts] = useState<Record<string, number>>({});
  // The server's counts, by partner id, for the override helpers.
  const serverUnread = useMemo(() => {
    const counts: Counts = {};
    ((conversationsData && conversationsData.data) || []).forEach((c: any) => {
      const other = c.otherParticipant || (c.participants || []).find((p: any) => p && p._id !== currentUser?._id);
      if (other && other._id) counts[other._id] = c.unreadCount || 0;
    });
    return counts;
  }, [conversationsData, currentUser]);
  const serverUnreadRef = useRef<Counts>({});
  useEffect(() => {
    serverUnreadRef.current = serverUnread;
    setUnreadCounts((prev) => pruneOverrides(serverUnread, prev));
  }, [serverUnread]);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [userToDelete, setUserToDelete] = useState<User | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  // Keep activeUserIdRef in sync so socket handlers always see latest value
  useEffect(() => {
    activeUserIdRef.current = activeUserId;
  }, [activeUserId]);

  // ---------- Socket event listeners ----------
  useEffect(() => {
    if (!socket) return;

    const handleDisconnect = () => {
      setOnlineUsers([]);
      setTypingUsers(new Set());
    };

    const handleOnlineUsers = (users: OnlineUser[]) => {
      setOnlineUsers(users);
      const statusMap: Record<string, { status: string; lastSeen?: Date }> = {};
      users.forEach((u) => {
        statusMap[u.userId] = {
          status: u.status,
          lastSeen: u.lastSeen ? new Date(u.lastSeen) : undefined,
        };
      });
      setUserStatuses((prev) => ({ ...prev, ...statusMap }));
    };

    const handleUserStatusUpdate = (data: OnlineUser) => {
      setOnlineUsers((prev) => {
        if (data.status === "offline") {
          return prev.filter((u) => u.userId !== data.userId);
        }
        const idx = prev.findIndex((u) => u.userId === data.userId);
        if (idx >= 0) {
          const updated = [...prev];
          updated[idx] = data;
          return updated;
        }
        return [...prev, data];
      });
      setUserStatuses((prev) => ({
        ...prev,
        [data.userId]: {
          status: data.status,
          lastSeen: data.lastSeen ? new Date(data.lastSeen) : undefined,
        },
      }));
    };

    const handleNewMessage = (data: { message: Message; senderId?: string }) => {
      const senderId = data.senderId || (data.message && (data.message as any).sender && (data.message as any).sender._id);
      if (senderId && senderId !== activeUserIdRef.current) {
        setUnreadCounts((prev) => bumpUnread(senderId, serverUnreadRef.current, prev));
      }
      refetchConversations();
    };

    const handleNewVoiceMessage = (data: { message: Message; duration: number }) => {
      const senderId = data.message?.sender?._id;
      if (senderId && senderId !== activeUserIdRef.current) {
        setUnreadCounts((prev) => bumpUnread(senderId, serverUnreadRef.current, prev));
      }
      refetchConversations();
    };

    const handleNewVideoMessage = (data: { message: Message; duration: number; thumbnail: string }) => {
      const senderId = data.message?.sender?._id;
      if (senderId && senderId !== activeUserIdRef.current) {
        setUnreadCounts((prev) => bumpUnread(senderId, serverUnreadRef.current, prev));
      }
      refetchConversations();
    };

    const handleMessageSent = () => {
      refetchConversations();
    };

    const handleMessagesRead = (data: { readBy: string; count: number }) => {
      setUnreadCounts((prev) => ({
        ...prev,
        [data.readBy]: 0,
      }));
      refetchConversations();
    };

    const handleUserTyping = (data: { userId: string }) => {
      setTypingUsers((prev) => {
        const next = new Set(prev);
        next.add(data.userId);
        return next;
      });
    };

    const handleUserStoppedTyping = (data: { userId: string }) => {
      setTypingUsers((prev) => {
        const next = new Set(prev);
        next.delete(data.userId);
        return next;
      });
    };

    const handleMessageDeleted = () => {
      refetchConversations();
    };

    // Backend's newer per-subscriber presence stream (presence:bulk on
    // connect + presence:online / presence:offline as state changes). The
    // older onlineUsers / userStatusUpdate events still fire but are
    // global; these are scoped to "users you actually care about" and
    // arrive even when the global broadcast is throttled.
    const handlePresenceBulk = (data: { onlineUserIds?: string[] }) => {
      const ids = Array.isArray(data?.onlineUserIds) ? data.onlineUserIds : [];
      setOnlineUsers((prev) => {
        const map = new Map(prev.map((u) => [u.userId, u]));
        ids.forEach((id) => {
          map.set(id, { userId: id, status: "online", lastSeen: null });
        });
        return Array.from(map.values());
      });
      setUserStatuses((prev) => {
        const next = { ...prev };
        ids.forEach((id) => {
          next[id] = { status: "online", lastSeen: undefined };
        });
        return next;
      });
    };

    const handlePresenceOnline = (data: { userId: string }) => {
      if (!data?.userId) return;
      handleUserStatusUpdate({
        userId: data.userId,
        status: "online",
        lastSeen: null,
      });
    };

    const handlePresenceOffline = (data: {
      userId: string;
      lastSeen?: string | null;
    }) => {
      if (!data?.userId) return;
      handleUserStatusUpdate({
        userId: data.userId,
        status: "offline",
        lastSeen: data.lastSeen ?? null,
      });
    };

    socket.on("disconnect", handleDisconnect);
    socket.on("onlineUsers", handleOnlineUsers);
    socket.on("userStatusUpdate", handleUserStatusUpdate);
    socket.on("presence:bulk", handlePresenceBulk);
    socket.on("presence:online", handlePresenceOnline);
    socket.on("presence:offline", handlePresenceOffline);
    socket.on("newMessage", handleNewMessage);
    socket.on("newVoiceMessage", handleNewVoiceMessage);
    socket.on("newVideoMessage", handleNewVideoMessage);
    socket.on("messageSent", handleMessageSent);
    socket.on("messagesRead", handleMessagesRead);
    socket.on("userTyping", handleUserTyping);
    socket.on("userStoppedTyping", handleUserStoppedTyping);
    socket.on("messageDeleted", handleMessageDeleted);

    return () => {
      socket.off("disconnect", handleDisconnect);
      socket.off("onlineUsers", handleOnlineUsers);
      socket.off("userStatusUpdate", handleUserStatusUpdate);
      socket.off("presence:bulk", handlePresenceBulk);
      socket.off("presence:online", handlePresenceOnline);
      socket.off("presence:offline", handlePresenceOffline);
      socket.off("newMessage", handleNewMessage);
      socket.off("newVoiceMessage", handleNewVoiceMessage);
      socket.off("newVideoMessage", handleNewVideoMessage);
      socket.off("messageSent", handleMessageSent);
      socket.off("messagesRead", handleMessagesRead);
      socket.off("userTyping", handleUserTyping);
      socket.off("userStoppedTyping", handleUserStoppedTyping);
      socket.off("messageDeleted", handleMessageDeleted);
    };
  }, [socket, refetchConversations]);

  // Mark messages as read when selecting a user
  useEffect(() => {
    if (activeUserId && socket?.connected) {
      setUnreadCounts((prev) => ({ ...prev, [activeUserId]: 0 }));

      const timer = setTimeout(() => {
        socket?.emit(
          "markAsRead",
          { senderId: activeUserId },
          (response: any) => {
            if (response?.status === "success") {
              // And the conversations, which is where the unread counts the
              // rows and the navbar badge are drawn from actually live. The
              // server answers the reader through this ack and pushes
              // `messagesRead` to the OTHER person, so this callback is the
              // only notice this tab gets that its own counts just changed.
              refetchConversations();
            }
          }
        );
      }, 100);

      return () => clearTimeout(timer);
    }
  }, [activeUserId, socket, refetchConversations]);

  // ---------- Derived data ----------

  const isUserOnline = useCallback(
    (userId: string) =>
      onlineUsers.some((u) => u.userId === userId && u.status !== "offline"),
    [onlineUsers]
  );

  const getUserStatus = useCallback(
    (userId: string): string => {
      const online = onlineUsers.find((u) => u.userId === userId);
      if (online) return online.status;
      return userStatuses[userId]?.status || "offline";
    },
    [onlineUsers, userStatuses]
  );

  const chatPartners = useMemo(() => {
    if (!currentUser) return [];
    const rows: any[] = (conversationsData && conversationsData.data) || [];
    const partners: Array<User & { lastMessage?: string; unreadCount: number; lastMessageTime?: Date }> = [];
    const seen: { [id: string]: boolean } = {};

    rows.forEach((conversation: any) => {
      const otherUser =
        conversation.otherParticipant ||
        (conversation.participants || []).find((p: any) => p && p._id !== currentUser._id);
      if (!otherUser || !otherUser._id || seen[otherUser._id]) return;
      seen[otherUser._id] = true;

      const lastMsg = conversation.lastMessage;
      const when = (lastMsg && lastMsg.createdAt) || conversation.lastMessageAt;
      partners.push({
        ...otherUser,
        imageUrls: otherUser.imageUrls || otherUser.images || [],
        lastMessage: previewOf(lastMsg, t as any, { viewerId: currentUser._id, partnerName: otherUser.name || "" }),
        unreadCount:
          otherUser._id === activeUserId
            ? 0
            : displayUnread(otherUser._id, serverUnread, unreadCounts),
        lastMessageTime: when ? new Date(when) : undefined,
        status: getUserStatus(otherUser._id) as any,
        lastSeen: userStatuses[otherUser._id]?.lastSeen,
        conversationId: conversation._id,
        isPinned: Boolean(conversation.isPinned),
        isMuted: Boolean(conversation.isMuted),
        isArchived: Boolean(conversation.isArchived),
      });
    });

    return partners.sort((a, b) => {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      const aTime = a.lastMessageTime ? a.lastMessageTime.getTime() : 0;
      const bTime = b.lastMessageTime ? b.lastMessageTime.getTime() : 0;
      return bTime - aTime;
    });
  }, [conversationsData, currentUser, userStatuses, getUserStatus, unreadCounts, serverUnread, activeUserId, t]);

  const archivedCount = useMemo(
    () => chatPartners.filter((u) => Boolean(u.isArchived)).length,
    [chatPartners]
  );

  const filteredChatPartners = useMemo(() => {
    // Archived chats live behind the toggle (web-only: the app lists them as usual).
    const inView = chatPartners.filter((u) => Boolean(u.isArchived) === showArchived);
    if (!searchQuery.trim()) return inView;
    const q = searchQuery.toLowerCase().trim();
    return inView.filter(
      (u) => u.name.toLowerCase().includes(q) || u.lastMessage?.toLowerCase().includes(q)
    );
  }, [chatPartners, searchQuery, showArchived]);

  useEffect(() => {
    if (showArchived && archivedCount === 0) setShowArchived(false);
  }, [showArchived, archivedCount]);

  // ---------- Delete ----------

  const handleDeleteConfirm = async () => {
    if (!userToDelete || !currentUser?._id) return;
    setIsDeleting(true);

    // Prefer the conversationId we already threaded through onto the
    // partner record; fall back to the lookup for safety.
    const conversationId = resolveConversationId(userToDelete);

    const endpoint = conversationId
      ? `/api/v1/conversations/${conversationId}`
      : null;
    console.log("[UsersList:delete] >> DELETE", endpoint || "(no conversationId found)", {
      partner: userToDelete.name,
      conversationId,
    });

    try {
      if (conversationId) {
        const response = await deleteConversation(conversationId).unwrap();
        console.log("[UsersList:delete] << OK", response);
        toast.success(
          t("chatPage.actions.deleted") || "Conversation deleted",
          { autoClose: 1800, theme: "colored", transition: Bounce }
        );
      } else {
        console.warn(
          "[UsersList:delete] no conversation document found for partner; skipping API call"
        );
      }

      refetchConversations();
      setShowDeleteModal(false);
      setUserToDelete(null);
    } catch (err: any) {
      console.error("[UsersList:delete] << FAIL", {
        status: err?.status,
        data: err?.data,
        raw: err,
      });
      const message =
        err?.data?.error ||
        err?.data?.message ||
        t("chatPage.actions.deleteFailed") ||
        "Couldn't delete the conversation";
      toast.error(message, {
        autoClose: 3000,
        theme: "colored",
        transition: Bounce,
      });
    } finally {
      setIsDeleting(false);
    }
  };

  const handleDeleteCancel = () => {
    setShowDeleteModal(false);
    setUserToDelete(null);
  };

  // ---------- Click handler ----------

  const handleUserClick = useCallback(
    (user: User) => {
      const online = isUserOnline(user._id);
      const lastSeen = userStatuses[user._id]?.lastSeen;
      onSelectUser(
        user._id,
        user.name,
        user.imageUrls?.[0] || user.avatar || "",
        online,
        lastSeen ? lastSeen.toISOString() : undefined
      );
    },
    [onSelectUser, isUserOnline, userStatuses]
  );

  // ---------- Context menu (right-click to delete) ----------

  const handleContextMenu = useCallback(
    (e: React.MouseEvent, user: User) => {
      e.preventDefault();
      setUserToDelete(user);
      setShowDeleteModal(true);
    },
    []
  );

  // ---------- Render ----------

  if (isLoading) {
    return (
      <div className="users-list-wrapper">
        <div className="users-list-loading">
          <div className="users-list-spinner" />
          <span className="users-list-loading-text">{t("chatPage.list.loading") || "Loading chats..."}</span>
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="users-list-wrapper">
        <div className="users-list-error">
          <p className="users-list-error-text">
            {t("chatPage.list.loadError") || "Couldn't load your conversations"}
          </p>
          <button
            className="users-list-retry-btn"
            onClick={() => {
              refetchConversations();
            }}
          >
            {t("chatPage.list.tryAgain") || "Try again"}
          </button>
        </div>
      </div>
    );
  }

  if (searchQuery && filteredChatPartners.length === 0) {
    return (
      <div className="users-list-wrapper">
        <div className="users-list-empty">
          <div className="users-list-empty-icon">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
          </div>
          <p className="users-list-empty-title">
            {t("chatPage.list.noMatchTitle") || "No matching conversations"}
          </p>
          <p className="users-list-empty-subtitle">
            {t("chatPage.list.noMatchSubtitle") || "Try adjusting your search"}
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="users-list-wrapper">
      <div className="users-list-scroll">
        {(archivedCount > 0 || showArchived) && (
          <button
            type="button"
            className="users-list-archived-toggle"
            data-testid="users-list-archived-toggle"
            aria-pressed={showArchived}
            onClick={() => setShowArchived((v) => !v)}
          >
            {showArchived ? <ArchiveRestore size={14} /> : <Archive size={14} />}
            <span>
              {showArchived
                ? t("chatPage.archive.back") || "Back to chats"
                : t("chatPage.archive.toggle", { count: archivedCount }) || `Archived (${archivedCount})`}
            </span>
          </button>
        )}
        {filteredChatPartners.length > 0 ? (
          <ul className="users-list">
            {filteredChatPartners.map((user) => {
              const online = isUserOnline(user._id);
              const typing = typingUsers.has(user._id);
              const isActive = activeUserId === user._id;
              const hasUnread = (user.unreadCount || 0) > 0;
              const status = getUserStatus(user._id);
              const lastSeenDate = userStatuses[user._id]?.lastSeen;

              return (
                <li
                  key={user._id}
                  className={`users-list-item${isActive ? " users-list-item--active" : ""}${hasUnread ? " users-list-item--unread" : ""}`}
                  onClick={() => handleUserClick(user)}
                  onContextMenu={(e) => handleContextMenu(e, user)}
                >
                  {/* Avatar — opens the member page. The row still opens the
                      chat, so the click must not reach it. */}
                  <div className="users-list-avatar-wrap">
                    <Link
                      to={`/community/${user._id}`}
                      data-testid={`users-list-avatar-link-${user._id}`}
                      className="users-list-avatar-link"
                      onClick={(e) => e.stopPropagation()}
                      aria-label={
                        t("chatPage.actions.openProfile", { name: user.name }) ||
                        `Open ${user.name}'s profile`
                      }
                    >
                      <div className="users-list-avatar">
                        {user.avatar || user.imageUrls?.[0] ? (
                          <img
                            src={user.avatar || user.imageUrls[0]}
                            alt={user.name}
                            className="users-list-avatar-img"
                            loading="lazy"
                          />
                        ) : (
                          <span className="users-list-avatar-letter">
                            {user.name?.charAt(0).toUpperCase()}
                          </span>
                        )}
                      </div>
                    </Link>
                    {online && (
                      <span
                        className="users-list-online-dot"
                        title={t("chatPage.online") || "Online"}
                      />
                    )}
                  </div>

                  {/* Content */}
                  <div className="users-list-content">
                    <div className="users-list-top-row">
                      <span className="users-list-name">
                        {user.isPinned && (
                          <Pin
                            size={12}
                            className="users-list-pin-icon"
                            aria-label={t("chatPage.actions.pinned") || "Pinned"}
                          />
                        )}
                        {user.name}
                        {typing && (
                          <span className="users-list-typing-dots">
                            <span />
                            <span />
                            <span />
                          </span>
                        )}
                      </span>
                      {user.lastMessageTime && (
                        <span className="users-list-time">
                          {formatTime(user.lastMessageTime)}
                        </span>
                      )}
                    </div>
                    <div className="users-list-bottom-row">
                      <span className="users-list-preview">
                        {typing ? (
                          <em className="users-list-typing-text">{t("chatPage.list.typing") || "typing..."}</em>
                        ) : (
                          user.lastMessage || (
                            <span className="users-list-no-msg">
                              {!online && lastSeenDate
                                ? `${t("chatPage.lastSeen") || "Last seen"} ${formatLastSeen(lastSeenDate, t as any)}`
                                : status === "online"
                                ? t("chatPage.online") || "Online"
                                : t("chatPage.list.noMessages") || "No messages yet"}
                            </span>
                          )
                        )}
                      </span>
                      {hasUnread && (
                        <span className="users-list-badge" data-testid={`users-list-unread-${user._id}`}>
                          {(user.unreadCount || 0) > 99
                            ? "99+"
                            : user.unreadCount}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Per-conversation actions: pin/unpin + delete. Menu opens
                      on click and closes on outside click (handled by the
                      document listener registered above). */}
                  <div className="users-list-actions">
                    <button
                      type="button"
                      className="users-list-action-btn"
                      data-testid={`users-list-menu-${user._id}`}
                      aria-label={
                        t("chatPage.actions.menuLabel") || "Conversation actions"
                      }
                      onClick={(e) => {
                        e.stopPropagation();
                        // Flip menu upward when the button is in the bottom
                        // half of the viewport so it doesn't clip below.
                        const rect = (e.currentTarget as HTMLButtonElement)
                          .getBoundingClientRect();
                        setMenuOpensUp(rect.top > window.innerHeight / 2);
                        setOpenMenuFor((curr) =>
                          curr === user._id ? null : user._id
                        );
                      }}
                    >
                      <MoreVertical size={16} />
                    </button>
                    {openMenuFor === user._id && (
                      <div
                        className={`users-list-action-menu ${
                          menuOpensUp ? "users-list-action-menu--up" : ""
                        }`}
                        onClick={(e) => e.stopPropagation()}
                      >
                        <button
                          type="button"
                          className="users-list-action-item"
                          onClick={(e) => handleTogglePin(e, user)}
                        >
                          {user.isPinned ? (
                            <>
                              <PinOff size={14} />
                              <span>{t("chatPage.actions.unpin") || "Unpin"}</span>
                            </>
                          ) : (
                            <>
                              <Pin size={14} />
                              <span>{t("chatPage.actions.pin") || "Pin"}</span>
                            </>
                          )}
                        </button>
                        <button
                          type="button"
                          className="users-list-action-item"
                          data-testid={`users-list-mute-${user._id}`}
                          onClick={(e) => handleToggleMute(e, user)}
                        >
                          {user.isMuted ? (
                            <>
                              <Bell size={14} />
                              <span>{t("chatPage.actions.unmute") || "Unmute"}</span>
                            </>
                          ) : (
                            <>
                              <BellOff size={14} />
                              <span>{t("chatPage.actions.mute") || "Mute"}</span>
                            </>
                          )}
                        </button>
                        <button
                          type="button"
                          className="users-list-action-item"
                          data-testid={`users-list-archive-${user._id}`}
                          onClick={(e) => handleToggleArchive(e, user)}
                        >
                          {user.isArchived ? <ArchiveRestore size={14} /> : <Archive size={14} />}
                          <span>
                            {user.isArchived
                              ? t("chatPage.archive.unarchive") || "Unarchive chat"
                              : t("chatPage.archive.archive") || "Archive chat"}
                          </span>
                        </button>
                        <button
                          type="button"
                          className="users-list-action-item users-list-action-item--danger"
                          data-testid={`users-list-delete-${user._id}`}
                          onClick={(e) => {
                            e.stopPropagation();
                            setOpenMenuFor(null);
                            setUserToDelete(user);
                            setShowDeleteModal(true);
                          }}
                        >
                          <Trash2 size={14} />
                          <span>
                            {t("chatPage.deleteModal.confirm") || "Delete"}
                          </span>
                        </button>
                      </div>
                    )}
                  </div>
                </li>
              );
            })}
          </ul>
        ) : (
          <div className="users-list-empty">
            <div className="users-list-empty-icon">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
              </svg>
            </div>
            <p className="users-list-empty-title">
              {t("chatPage.list.emptyTitle") || "No conversations yet"}
            </p>
            <p className="users-list-empty-subtitle">
              {t("chatPage.list.emptySubtitle") ||
                "Start a conversation to see it here"}
            </p>
          </div>
        )}
      </div>

      {/* The app's own confirm dialog rather than the bootstrap modal this
          used to be: one dialog shell for the whole product means one Escape
          behaviour, one focus trap, one scroll lock — and colours that follow
          the tokens into dark mode. */}
      {mutingPartner ? (
        <MuteDurationDialog
          name={mutingPartner.name}
          onChoose={handleMuteFor}
          onCancel={() => setMutingPartner(null)}
        />
      ) : null}

      <ConfirmDialog
        open={showDeleteModal}
        danger
        title={t("chatPage.deleteModal.title") || "Delete Conversation"}
        body={
          <React.Fragment>
            {/* One sentence with the name interpolated. The old
                `bodyPrefix` + <strong>{name}</strong> + "?" could not be
                translated into any language that does not end on the name. */}
            <span className="block" data-testid="users-list-delete-body">
              {t("chatPage.deleteModal.body", { name: userToDelete?.name }) ||
                `Delete your conversation with ${userToDelete?.name}?`}
            </span>
            <span className="mt-1 block text-xs text-ink-500 dark:text-ink-400">
              {t("chatPage.deleteModal.warning") || "This cannot be undone."}
            </span>
          </React.Fragment>
        }
        confirmLabel={
          isDeleting
            ? t("chatPage.deleteModal.deleting") || "Deleting..."
            : t("chatPage.deleteModal.confirm") || "Delete"
        }
        cancelLabel={t("chatPage.deleteModal.cancel") || "Cancel"}
        busy={isDeleting}
        onConfirm={handleDeleteConfirm}
        onCancel={handleDeleteCancel}
      />
    </div>
  );
};

export default UsersList;
