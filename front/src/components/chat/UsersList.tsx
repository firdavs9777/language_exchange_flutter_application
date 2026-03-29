import React, { useEffect, useRef, useCallback, useState, useMemo } from "react";
import { Badge, Modal, Button } from "react-bootstrap";
import {
  useGetUserMessagesQuery,
  useGetConversationsQuery,
  useDeleteConversationMutation,
} from "../../store/slices/chatSlice";
import { useSelector } from "react-redux";
import { RootState } from "../../store/index";
import { useSocket } from "./hooks/useSocket";
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

const getMessageText = (msg: Message): string => {
  // Show media type labels for non-text messages
  if (msg.messageType === "voice" || msg.media?.type === "voice") return "\ud83c\udfa4 Voice message";
  if (msg.media?.type) {
    const mediaType = msg.media.type;
    if (mediaType === "image" || mediaType.startsWith("image")) return "\ud83d\uddbc\ufe0f Photo";
    if (mediaType === "video" || mediaType.startsWith("video")) return "\ud83c\udfa5 Video";
    if (mediaType === "document" || mediaType === "audio") return "\ud83d\udcce " + (msg.media?.fileName || "File");
    if (msg.message || msg.content) return msg.message || msg.content || "";
    return "\ud83d\udcce Attachment";
  }
  return msg.message || msg.content || "";
};

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

const formatLastSeen = (date: Date): string => {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return "just now";
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHours = Math.floor(diffMin / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  return date.toLocaleDateString([], { month: "short", day: "numeric" });
};

// ---------- Component ----------

const UsersList: React.FC<UsersListProps> = ({
  onSelectUser,
  activeUserId,
  searchQuery = "",
}) => {
  const currentUser = useSelector(
    (state: RootState) => state.auth.userInfo?.user
  );
  const { data, error, isLoading, isError, refetch } = useGetUserMessagesQuery(
    currentUser?._id,
    { skip: !currentUser?._id }
  );
  const { data: conversationsData, refetch: refetchConversations } =
    useGetConversationsQuery(
      { page: 1, limit: 50 },
      { skip: !currentUser?._id }
    );

  const [deleteConversation] = useDeleteConversationMutation();

  // Shared socket
  const { socket, isConnected } = useSocket();
  const activeUserIdRef = useRef<string | null | undefined>(activeUserId);

  // State
  const [onlineUsers, setOnlineUsers] = useState<OnlineUser[]>([]);
  const [userStatuses, setUserStatuses] = useState<
    Record<string, { status: string; lastSeen?: Date }>
  >({});
  const [typingUsers, setTypingUsers] = useState<Set<string>>(new Set());
  const [unreadCounts, setUnreadCounts] = useState<Record<string, number>>({});
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

    const handleNewMessage = (data: { message: Message; unreadCount: number; senderId: string }) => {
      if (data.senderId !== activeUserIdRef.current) {
        setUnreadCounts((prev) => ({
          ...prev,
          [data.senderId]: data.unreadCount,
        }));
      }
      refetch();
      refetchConversations();
    };

    const handleNewVoiceMessage = (data: { message: Message; duration: number }) => {
      const senderId = data.message?.sender?._id;
      if (senderId && senderId !== activeUserIdRef.current) {
        setUnreadCounts((prev) => ({
          ...prev,
          [senderId]: (prev[senderId] || 0) + 1,
        }));
      }
      refetch();
      refetchConversations();
    };

    const handleNewVideoMessage = (data: { message: Message; duration: number; thumbnail: string }) => {
      const senderId = data.message?.sender?._id;
      if (senderId && senderId !== activeUserIdRef.current) {
        setUnreadCounts((prev) => ({
          ...prev,
          [senderId]: (prev[senderId] || 0) + 1,
        }));
      }
      refetch();
      refetchConversations();
    };

    const handleMessageSent = () => {
      refetch();
      refetchConversations();
    };

    const handleMessagesRead = (data: { readBy: string; count: number }) => {
      setUnreadCounts((prev) => ({
        ...prev,
        [data.readBy]: 0,
      }));
      refetch();
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
      refetch();
      refetchConversations();
    };

    socket.on("disconnect", handleDisconnect);
    socket.on("onlineUsers", handleOnlineUsers);
    socket.on("userStatusUpdate", handleUserStatusUpdate);
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
      socket.off("newMessage", handleNewMessage);
      socket.off("newVoiceMessage", handleNewVoiceMessage);
      socket.off("newVideoMessage", handleNewVideoMessage);
      socket.off("messageSent", handleMessageSent);
      socket.off("messagesRead", handleMessagesRead);
      socket.off("userTyping", handleUserTyping);
      socket.off("userStoppedTyping", handleUserStoppedTyping);
      socket.off("messageDeleted", handleMessageDeleted);
    };
  }, [socket, refetch, refetchConversations]);

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
              refetch();
            }
          }
        );
      }, 100);

      return () => clearTimeout(timer);
    }
  }, [activeUserId, socket, refetch]);

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

    const partnersMap = new Map<
      string,
      User & { lastMessage?: string; unreadCount: number; lastMessageTime?: Date }
    >();

    // Process messages
    if (data?.data && Array.isArray(data.data)) {
      data.data.forEach((message: Message) => {
        const otherUser =
          message.sender?._id === currentUser._id
            ? message.receiver
            : message.sender;
        if (!otherUser?._id) return;

        const isIncoming = message.sender?._id !== currentUser._id;
        const isUnread = isIncoming && !message.read;
        const messageDate = new Date(message.createdAt);
        const messageText = getMessageText(message);

        const existing = partnersMap.get(otherUser._id);

        if (!existing) {
          partnersMap.set(otherUser._id, {
            ...otherUser,
            imageUrls: otherUser.imageUrls || [],
            lastMessage: messageText,
            unreadCount: isUnread ? 1 : 0,
            lastMessageTime: messageDate,
            status: getUserStatus(otherUser._id) as any,
            lastSeen: userStatuses[otherUser._id]?.lastSeen,
          });
        } else {
          if (
            !existing.lastMessageTime ||
            messageDate > existing.lastMessageTime
          ) {
            existing.lastMessage = messageText;
            existing.lastMessageTime = messageDate;
          }
          if (isUnread) existing.unreadCount += 1;
          existing.status = getUserStatus(otherUser._id) as any;
          existing.lastSeen = userStatuses[otherUser._id]?.lastSeen;
        }
      });
    }

    // Process conversations
    if (conversationsData?.data && Array.isArray(conversationsData.data)) {
      conversationsData.data.forEach((conversation: any) => {
        const participants = conversation.participants || [];
        const otherUser = participants.find(
          (p: any) => p._id !== currentUser._id
        );
        if (!otherUser?._id) return;

        const lastMsg = conversation.lastMessage;
        const messageText = lastMsg
          ? getMessageText(lastMsg as Message)
          : "";
        const messageDate = lastMsg?.createdAt
          ? new Date(lastMsg.createdAt)
          : null;
        const convUnread = conversation.unreadCount || 0;

        const existing = partnersMap.get(otherUser._id);

        if (!existing) {
          partnersMap.set(otherUser._id, {
            ...otherUser,
            imageUrls: otherUser.imageUrls || [],
            lastMessage: messageText,
            unreadCount: convUnread,
            lastMessageTime: messageDate || undefined,
            status: getUserStatus(otherUser._id) as any,
            lastSeen: userStatuses[otherUser._id]?.lastSeen,
          });
        } else if (
          messageDate &&
          (!existing.lastMessageTime || messageDate > existing.lastMessageTime)
        ) {
          existing.lastMessage = messageText;
          existing.lastMessageTime = messageDate;
          if (convUnread > existing.unreadCount) {
            existing.unreadCount = convUnread;
          }
        }
      });
    }

    // Apply real-time unread overrides
    const partners = Array.from(partnersMap.values()).map((partner) => {
      if (partner._id === activeUserId) {
        partner.unreadCount = 0;
      } else if (unreadCounts[partner._id] !== undefined) {
        partner.unreadCount = unreadCounts[partner._id];
      }
      return partner;
    });

    // Sort by last message time (most recent first)
    return partners.sort((a, b) => {
      const aTime = a.lastMessageTime?.getTime() || 0;
      const bTime = b.lastMessageTime?.getTime() || 0;
      return bTime - aTime;
    });
  }, [
    data,
    conversationsData,
    currentUser,
    userStatuses,
    getUserStatus,
    unreadCounts,
    activeUserId,
  ]);

  const filteredChatPartners = useMemo(() => {
    if (!searchQuery.trim()) return chatPartners;
    const q = searchQuery.toLowerCase().trim();
    return chatPartners.filter(
      (u) =>
        u.name.toLowerCase().includes(q) ||
        u.lastMessage?.toLowerCase().includes(q)
    );
  }, [chatPartners, searchQuery]);

  // ---------- Delete ----------

  const handleDeleteConfirm = async () => {
    if (!userToDelete || !currentUser?._id) return;
    setIsDeleting(true);

    try {
      // Find the conversation ID for this user pair
      const conversation = conversationsData?.data?.find((c: any) => {
        const participants = c.participants || [];
        return participants.some((p: any) => p._id === userToDelete._id);
      });

      if (conversation?._id) {
        await deleteConversation(conversation._id).unwrap();
      }

      refetch();
      refetchConversations();
      setShowDeleteModal(false);
      setUserToDelete(null);
    } catch (_err) {
      // silently handle
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
          <span className="users-list-loading-text">Loading chats...</span>
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="users-list-wrapper">
        <div className="users-list-error">
          <p className="users-list-error-text">
            {error
              ? (error as any)?.data?.message || "Error loading conversations"
              : "An unexpected error occurred"}
          </p>
          <button
            className="users-list-retry-btn"
            onClick={() => {
              refetch();
              refetchConversations();
            }}
          >
            Try Again
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
          <p className="users-list-empty-title">No matching conversations</p>
          <p className="users-list-empty-subtitle">Try adjusting your search</p>
        </div>
      </div>
    );
  }

  return (
    <div className="users-list-wrapper">
      <div className="users-list-scroll">
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
                  {/* Avatar */}
                  <div className="users-list-avatar-wrap">
                    <div className="users-list-avatar">
                      {user.avatar || user.imageUrls?.[0] ? (
                        <img
                          src={user.avatar || user.imageUrls[0]}
                          alt={user.name}
                          className="users-list-avatar-img"
                        />
                      ) : (
                        <span className="users-list-avatar-letter">
                          {user.name?.charAt(0).toUpperCase()}
                        </span>
                      )}
                    </div>
                    {online && (
                      <span className="users-list-online-dot" title="Online" />
                    )}
                  </div>

                  {/* Content */}
                  <div className="users-list-content">
                    <div className="users-list-top-row">
                      <span className="users-list-name">
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
                          <em className="users-list-typing-text">typing...</em>
                        ) : (
                          user.lastMessage || (
                            <span className="users-list-no-msg">
                              {!online && lastSeenDate
                                ? `Last seen ${formatLastSeen(lastSeenDate)}`
                                : status === "online"
                                ? "Online"
                                : "No messages yet"}
                            </span>
                          )
                        )}
                      </span>
                      {hasUnread && (
                        <Badge
                          pill
                          className="users-list-badge"
                        >
                          {(user.unreadCount || 0) > 99
                            ? "99+"
                            : user.unreadCount}
                        </Badge>
                      )}
                    </div>
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
            <p className="users-list-empty-title">No conversations yet</p>
            <p className="users-list-empty-subtitle">
              Start a conversation to see it here
            </p>
          </div>
        )}
      </div>

      {/* Delete confirmation modal */}
      <Modal
        show={showDeleteModal}
        onHide={handleDeleteCancel}
        centered
        size="sm"
      >
        <Modal.Header closeButton className="border-0 pb-1">
          <Modal.Title className="fs-6 fw-semibold">
            Delete Conversation
          </Modal.Title>
        </Modal.Header>
        <Modal.Body className="pt-0">
          <p className="mb-1 text-secondary" style={{ fontSize: "0.9rem" }}>
            Delete your conversation with{" "}
            <strong>{userToDelete?.name}</strong>?
          </p>
          <p className="mb-0 text-muted" style={{ fontSize: "0.8rem" }}>
            This cannot be undone.
          </p>
        </Modal.Body>
        <Modal.Footer className="border-0 pt-0">
          <Button
            variant="light"
            size="sm"
            onClick={handleDeleteCancel}
            disabled={isDeleting}
          >
            Cancel
          </Button>
          <Button
            variant="danger"
            size="sm"
            onClick={handleDeleteConfirm}
            disabled={isDeleting}
          >
            {isDeleting ? "Deleting..." : "Delete"}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default UsersList;
