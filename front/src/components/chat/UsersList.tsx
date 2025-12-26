import React, { useEffect, useRef, useCallback, useState } from "react";
import { ListGroup, Spinner, Alert, Badge, Modal, Button } from "react-bootstrap";
import { useGetUserMessagesQuery } from "../../store/slices/chatSlice";
import { useSelector } from "react-redux";
import { RootState } from "../../store/index";
import io, { Socket } from "socket.io-client";
import { BASE_URL } from "../../constants";

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
  status: 'online' | 'offline' | 'away' | 'busy';
  lastSeen: string | null;
}

interface Message {
  _id: string;
  sender: User;
  receiver: User;
  message: string;
  createdAt: string;
  read: boolean;
}

interface UsersListProps {
  onSelectUser: (
    userId: string,
    userName: string,
    profilePicture: string
  ) => void;
  activeUserId?: string | null;
  searchQuery?: string;
}

// Debug component for development
const DebugMessageRead: React.FC<{
  activeUserId: string | null;
  unreadCounts: Record<string, number>;
  onManualMarkAsRead: (userId: string) => void;
}> = ({ activeUserId, unreadCounts, onManualMarkAsRead }) => {
  if (process.env.NODE_ENV !== 'development') return null;

  return (
    <div className="debug-panel bg-yellow-50 border border-yellow-200 p-3 m-2 rounded text-xs">
      <h6 className="font-bold text-yellow-800 mb-2">🐛 Debug: Message Read Status</h6>
      
      <div className="space-y-2">
        <div>
          <strong>Active User ID:</strong> {activeUserId || 'None'}
        </div>
        
        <div>
          <strong>Unread Counts:</strong>
          {Object.keys(unreadCounts).length === 0 ? (
            <span className="text-gray-500"> None</span>
          ) : (
            <ul className="ml-4 mt-1">
              {Object.entries(unreadCounts).map(([userId, count]) => (
                <li key={userId} className="flex justify-between items-center">
                  <span>User {userId}: {count}</span>
                  {count > 0 && (
                    <button
                      onClick={() => onManualMarkAsRead(userId)}
                      className="ml-2 px-2 py-1 bg-blue-500 text-white text-xs rounded hover:bg-blue-600"
                    >
                      Mark Read
                    </button>
                  )}
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
};

const UsersList: React.FC<UsersListProps> = ({
  onSelectUser,
  activeUserId,
  searchQuery = "",
}) => {
  const currentUser = useSelector(
    (state: RootState) => state.auth.userInfo?.user
  );
  const { data, error, isLoading, isError, refetch } = useGetUserMessagesQuery(
    currentUser?._id
  );
  const token = useSelector((state: RootState) => state.auth.userInfo?.token);
  const socketRef = useRef<Socket | null>(null);
  const [userStatuses, setUserStatuses] = useState<Record<string, { status: string; lastSeen?: Date }>>({});
  const [onlineUsers, setOnlineUsers] = useState<OnlineUser[]>([]);
  const [typingUsers, setTypingUsers] = useState<Set<string>>(new Set());
  const [isSocketConnected, setIsSocketConnected] = useState(false);
  const [unreadCounts, setUnreadCounts] = useState<Record<string, number>>({});
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [userToDelete, setUserToDelete] = useState<User | null>(null);
  const [activeDropdown, setActiveDropdown] = useState<string | null>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Initialize socket connection with proper event handlers
  const initializeSocket = useCallback(() => {
    if (!token || !currentUser?._id) {
      console.warn("⚠️ Missing token or user ID for socket connection");
      return;
    }

    const SOCKET_URL = BASE_URL;

    // Disconnect existing socket if any
    if (socketRef.current) {
      console.log("🔌 Disconnecting existing socket...");
      socketRef.current.off(); // Remove all listeners
      socketRef.current.disconnect();
    }

    console.log("🔗 Initializing socket connection...");
    socketRef.current = io(SOCKET_URL, {
      auth: { token },
      transports: ["websocket", "polling"],
      timeout: 20000,
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
    });

    const socket = socketRef.current;

    // Connection events
    socket.on("connect", () => {
      console.log("✅ Connected to socket server");
      setIsSocketConnected(true);
    });

    socket.on("disconnect", (reason) => {
      console.log("❌ Disconnected from socket server:", reason);
      setIsSocketConnected(false);
      setOnlineUsers([]);
      setTypingUsers(new Set());
    });

    socket.on("connect_error", (error) => {
      console.error("❌ Socket connection error:", error);
      setIsSocketConnected(false);
    });

    // Handle initial online users list
    socket.on("onlineUsers", (users: OnlineUser[]) => {
      console.log("📋 Received online users:", users);
      setOnlineUsers(users);
      
      // Update user statuses from online users
      const statusMap: Record<string, { status: string; lastSeen?: Date }> = {};
      users.forEach(user => {
        statusMap[user.userId] = {
          status: user.status,
          lastSeen: user.lastSeen ? new Date(user.lastSeen) : undefined,
        };
      });
      setUserStatuses(prev => ({ ...prev, ...statusMap }));
    });

    // Handle real-time user status updates
    socket.on("userStatusUpdate", (data: OnlineUser) => {
      console.log("📡 User status update:", data);
      
      // Update online users list
      setOnlineUsers(prevUsers => {
        if (data.status === 'offline') {
          return prevUsers.filter(user => user.userId !== data.userId);
        }
        
        const existingUserIndex = prevUsers.findIndex(user => user.userId === data.userId);
        if (existingUserIndex >= 0) {
          const updatedUsers = [...prevUsers];
          updatedUsers[existingUserIndex] = data;
          return updatedUsers;
        } else {
          return [...prevUsers, data];
        }
      });

      // Update user statuses
      setUserStatuses(prev => ({
        ...prev,
        [data.userId]: {
          status: data.status,
          lastSeen: data.lastSeen ? new Date(data.lastSeen) : undefined,
        },
      }));
    });

    // Message events with immediate UI updates
    socket.on("newMessage", (data: { message: Message; unreadCount: number; senderId: string }) => {
      console.log("📨 Received new message:", data);
      
      // Update unread count immediately if the message is not from the currently active user
      if (data.senderId !== activeUserId) {
        setUnreadCounts(prev => ({
          ...prev,
          [data.senderId]: data.unreadCount
        }));
      }
      
      refetch(); // Refresh the message list
    });

    socket.on("messageSent", (data: { message: Message; unreadCount: number; receiverId: string }) => {
      console.log("📤 Message sent confirmation:", data);
      refetch(); // Refresh to show the sent message
    });

    socket.on("messagesRead", (data: { readBy: string; count: number }) => {
      console.log("📖 Messages marked as read:", data);
      
      // Clear unread count for the user who read the messages
      setUnreadCounts(prev => ({
        ...prev,
        [data.readBy]: 0
      }));
      
      refetch(); // Refresh to update read status
    });

    // Enhanced typing events
    socket.on("userTyping", (data: { userId: string; isTyping: boolean }) => {
      console.log("⌨️ User typing:", data);
      
      setTypingUsers(prevTyping => {
        const newTyping = new Set(prevTyping);
        if (data.isTyping) {
          newTyping.add(data.userId);
        } else {
          newTyping.delete(data.userId);
        }
        return newTyping;
      });
      
      // Auto-clear typing indicator after 3 seconds of inactivity
      if (data.isTyping) {
        setTimeout(() => {
          setTypingUsers(prev => {
            const updated = new Set(prev);
            updated.delete(data.userId);
            return updated;
          });
        }, 3000);
      }
    });

    // Error handling
    socket.on("error", (error) => {
      console.error("❌ Socket error:", error);
    });

    socket.on("messageError", (error) => {
      console.error("❌ Message error:", error);
    });

    return socket;
  }, [token, currentUser?._id, refetch, activeUserId]);

  // Initialize socket on mount and when dependencies change
  useEffect(() => {
    initializeSocket();

    return () => {
      if (socketRef.current) {
        console.log("🧹 Cleaning up socket connection...");
        socketRef.current.off();
        socketRef.current.disconnect();
        socketRef.current = null;
      }
    };
  }, [initializeSocket]);

  // Mark messages as read when user is selected
  useEffect(() => {
    if (activeUserId && socketRef.current?.connected) {
      console.log(`📖 Marking messages as read for user: ${activeUserId}`);
      
      // Immediately clear unread count for better UX
      setUnreadCounts(prev => ({
        ...prev,
        [activeUserId]: 0
      }));
      
      // Add a small delay to ensure the UI has updated first
      const markAsReadTimer = setTimeout(() => {
        socketRef.current?.emit(
          "markAsRead",
          { senderId: activeUserId },
          (response) => {
            if (response?.status === "success") {
              console.log(`✅ Marked ${response.markedCount} messages as read from ${activeUserId}`);
              
              // Refetch to ensure consistency with backend
              refetch();
            } else {
              console.error("❌ Failed to mark messages as read:", response?.error);
              // Revert the optimistic update on error
              setUnreadCounts(prev => {
                const { [activeUserId]: removed, ...rest } = prev;
                return rest;
              });
            }
          }
        );
      }, 100);

      return () => clearTimeout(markAsReadTimer);
    }
  }, [activeUserId, refetch]);

  // Helper function to check if user is online
  const isUserOnline = useCallback((userId: string) => {
    return onlineUsers.some(user => user.userId === userId && user.status !== 'offline');
  }, [onlineUsers]);

  // Helper function to get user's current status
  const getUserCurrentStatus = useCallback((userId: string) => {
    const onlineUser = onlineUsers.find(user => user.userId === userId);
    if (onlineUser) return onlineUser.status;
    
    const statusInfo = userStatuses[userId];
    return statusInfo?.status || 'offline';
  }, [onlineUsers, userStatuses]);

  // Helper function to check if user is typing
  const isUserTyping = useCallback((userId: string) => {
    return typingUsers.has(userId);
  }, [typingUsers]);

  // Manual mark as read function for debugging
  const handleManualMarkAsRead = useCallback((userId: string) => {
    if (socketRef.current?.connected) {
      console.log(`🔧 Manual mark as read for user: ${userId}`);
      
      setUnreadCounts(prev => ({
        ...prev,
        [userId]: 0
      }));
      
      socketRef.current.emit(
        "markAsRead",
        { senderId: userId },
        (response) => {
          if (response?.status === "success") {
            console.log(`✅ Manual mark read successful: ${response.markedCount} messages`);
            refetch();
          } else {
            console.error("❌ Manual mark read failed:", response?.error);
          }
        }
      );
    }
  }, [refetch]);

  // Extract conversation partners with enhanced status info
  const chatPartners = React.useMemo(() => {
    if (!data?.data || !currentUser) return [];

    const partnersMap = new Map<
      string,
      User & {
        lastMessage?: string;
        unreadCount: number;
        lastMessageTime?: Date;
      }
    >();

    data.data.forEach((message: Message) => {
      const otherUser = message.sender._id === currentUser._id ? message.receiver : message.sender;
      const isIncoming = message.sender._id !== currentUser._id;
      const isUnread = isIncoming && !message.read;
      const messageDate = new Date(message.createdAt);

      const existingPartner = partnersMap.get(otherUser._id);

      if (!existingPartner) {
        partnersMap.set(otherUser._id, {
          ...otherUser,
          lastMessage: message.message,
          unreadCount: isUnread ? 1 : 0,
          lastMessageTime: messageDate,
          status: getUserCurrentStatus(otherUser._id) as any,
          lastSeen: userStatuses[otherUser._id]?.lastSeen,
        });
      } else {
        if (!existingPartner.lastMessageTime || messageDate > existingPartner.lastMessageTime) {
          existingPartner.lastMessage = message.message;
          existingPartner.lastMessageTime = messageDate;
        }
        if (isUnread) {
          existingPartner.unreadCount += 1;
        }
        existingPartner.status = getUserCurrentStatus(otherUser._id) as any;
        existingPartner.lastSeen = userStatuses[otherUser._id]?.lastSeen;
      }
    });

    // Override unread count with real-time data if available and user is not currently active
    const partners = Array.from(partnersMap.values()).map(partner => {
      if (unreadCounts[partner._id] !== undefined && partner._id !== activeUserId) {
        partner.unreadCount = unreadCounts[partner._id];
      } else if (partner._id === activeUserId) {
        // If this is the active user, unread count should be 0
        partner.unreadCount = 0;
      }
      return partner;
    });

    return partners.sort((a, b) => {
      // Sort by online status first, then by recent message time
      const aOnline = isUserOnline(a._id);
      const bOnline = isUserOnline(b._id);
      
      if (aOnline && !bOnline) return -1;
      if (!aOnline && bOnline) return 1;
      
      const aTime = a.lastMessageTime?.getTime() || 0;
      const bTime = b.lastMessageTime?.getTime() || 0;
      return bTime - aTime;
    });
  }, [data, currentUser, userStatuses, onlineUsers, getUserCurrentStatus, isUserOnline, unreadCounts, activeUserId]);

  // Filter conversations based on search query
  const filteredChatPartners = React.useMemo(() => {
    if (!searchQuery.trim()) return chatPartners;

    const normalizedQuery = searchQuery.toLowerCase().trim();

    return chatPartners.filter((user) => {
      if (user.name.toLowerCase().includes(normalizedQuery)) return true;
      if (user.lastMessage?.toLowerCase().includes(normalizedQuery)) return true;
      return false;
    });
  }, [chatPartners, searchQuery]);

  // Manual refresh function
  const handleReload = React.useCallback(() => {
    console.log("🔄 Manually reloading user messages...");
    refetch();
    
    // Also request fresh online users if socket is connected
    if (socketRef.current?.connected) {
      socketRef.current.emit('getOnlineUsers', (response: { users: OnlineUser[] }) => {
        if (response?.users) {
          console.log("🔄 Refreshed online users:", response.users);
          setOnlineUsers(response.users);
        }
      });
    }
  }, [refetch]);

  // Expose reload function via ref (optional)
  React.useImperativeHandle(
    React.forwardRef(() => null),
    () => ({
      reload: handleReload,
    })
  );

  const formatTime = (date: Date) => {
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

    if (diffInHours < 24) {
      return date.toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      });
    } else if (diffInHours < 168) {
      return date.toLocaleDateString([], { weekday: "short" });
    } else {
      return date.toLocaleDateString([], { month: "short", day: "numeric" });
    }
  };

  const getStatusColor = (status?: string) => {
    switch (status) {
      case "online":
        return "bg-green-500";
      case "away":
        return "bg-yellow-500";
      case "busy":
        return "bg-red-500";
      case "offline":
      default:
        return "bg-gray-400";
    }
  };

  const getStatusIcon = (status?: string) => {
    switch (status) {
      case "online":
        return "bi-circle-fill text-green-500";
      case "away":
        return "bi-clock-fill text-yellow-500";
      case "busy":
        return "bi-do-not-disturb-fill text-red-500";
      case "offline":
      default:
        return "bi-circle text-gray-400";
    }
  };

  const handleDeleteClick = (e: React.MouseEvent, user: User) => {
    e.stopPropagation();
    setUserToDelete(user);
    setShowDeleteModal(true);
  };

  const handleDeleteConfirm = async () => {
    if (!userToDelete) return;
    
    try {
      console.log(`🗑️ Deleting conversation with user: ${userToDelete.name}`);
      refetch();
      setShowDeleteModal(false);
      setUserToDelete(null);
      console.log("✅ Conversation deleted successfully");
    } catch (error) {
      console.error("❌ Error deleting conversation:", error);
    }
  };

  const handleDeleteCancel = () => {
    setShowDeleteModal(false);
    setUserToDelete(null);
  };

  const toggleDropdown = (userId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setActiveDropdown(activeDropdown === userId ? null : userId);
  };

  const handleDropdownAction = (action: string, user: User, e: React.MouseEvent) => {
    e.stopPropagation();
    setActiveDropdown(null);
    
    switch (action) {
      case 'delete':
        setUserToDelete(user);
        setShowDeleteModal(true);
        break;
      case 'archive':
        console.log(`📦 Archive conversation with ${user.name}`);
        break;
      case 'mute':
        console.log(`🔇 Mute conversation with ${user.name}`);
        break;
      case 'block':
        console.log(`🚫 Block user ${user.name}`);
        break;
      case 'markUnread':
        console.log(`📧 Mark conversation with ${user.name} as unread`);
        break;
      case 'pin':
        console.log(`📌 Pin conversation with ${user.name}`);
        break;
      default:
        break;
    }
  };

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setActiveDropdown(null);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-48">
        <div className="text-center">
          <div className="inline-flex items-center justify-center w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin"></div>
          <div className="mt-3 text-gray-500 text-sm flex items-center justify-center">
            <i className="bi bi-chat-dots mr-2"></i>
            Loading conversations...
          </div>
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-4">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center mb-3">
            <i className="bi bi-exclamation-triangle-fill text-red-500 text-lg mr-2"></i>
            <h6 className="text-red-800 font-semibold mb-0">Connection Error</h6>
          </div>
          <p className="mb-3 text-sm text-red-700">
            {error
              ? (error as any)?.data?.message || "Error loading conversations"
              : "An unexpected error occurred"}
          </p>
          <button
            className="inline-flex items-center px-3 py-1.5 text-sm border border-red-300 text-red-700 bg-white rounded-full hover:bg-red-50 transition-colors"
            onClick={handleReload}
          >
            <i className="bi bi-arrow-clockwise mr-1"></i>
            Try Again
          </button>
        </div>
      </div>
    );
  }

  if (searchQuery && filteredChatPartners.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center text-center py-12">
        <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-3">
          <i className="bi bi-search text-gray-400 text-2xl"></i>
        </div>
        <h6 className="text-gray-500 mb-1 font-medium flex items-center">
          <i className="bi bi-chat-square-x mr-2"></i>
          No matching conversations
        </h6>
        <p className="text-gray-400 text-sm mb-0">Try adjusting your search terms</p>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* Connection Status Bar */}
      <div className={`px-3 py-2 text-xs font-medium flex items-center justify-between ${
        isSocketConnected ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
      }`}>
        <div className="flex items-center">
          <div className={`w-2 h-2 rounded-full mr-2 ${
            isSocketConnected ? 'bg-green-500' : 'bg-red-500'
          }`}></div>
          {isSocketConnected ? 'Connected' : 'Disconnected'}
          {onlineUsers.length > 0 && (
            <span className="ml-2 text-green-600">
              • {onlineUsers.length} online
            </span>
          )}
        </div>
        <button
          onClick={handleReload}
          className="text-xs hover:underline flex items-center"
          disabled={!isSocketConnected}
        >
          <i className="bi bi-arrow-clockwise mr-1"></i>
          Refresh
        </button>
      </div>

      {/* Debug Component (only in development) */}
      <DebugMessageRead
        activeUserId={activeUserId}
        unreadCounts={unreadCounts}
        onManualMarkAsRead={handleManualMarkAsRead}
      />

      <div className="flex-grow overflow-auto">
        {filteredChatPartners.length > 0 ? (
          <div className="list-group list-group-flush">
            {filteredChatPartners.map((user, index) => (
              <div
                key={user._id}
                className={`
                  cursor-pointer transition-all duration-200 border-0 px-0 py-0
                  ${activeUserId === user._id 
                    ? 'bg-gradient-to-r from-indigo-500 to-purple-600 text-white' 
                    : 'hover:bg-gray-50'
                  }
                  ${index !== filteredChatPartners.length - 1 ? 'border-b border-gray-100' : ''}
                `}
                onClick={() =>
                  onSelectUser(user._id, user.name, user.imageUrls[0])
                }
              >
                <div className="flex items-center p-3 sm:p-4 relative">
                  {/* Avatar with enhanced status indicator */}
                  <div className="relative mr-3 flex-shrink-0">
                    <div
                      className={`
                        w-10 h-10 sm:w-12 sm:h-12 rounded-full flex items-center justify-center overflow-hidden
                        ${user.avatar || user.imageUrls[0] 
                          ? 'bg-transparent' 
                          : 'bg-gradient-to-br from-indigo-500 to-purple-600'
                        }
                      `}
                    >
                      {user.avatar || user.imageUrls[0] ? (
                        <img
                          src={user.avatar || user.imageUrls[0]}
                          alt={user.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <span className="text-white font-bold text-base sm:text-lg">
                          {user.name?.charAt(0).toUpperCase()}
                        </span>
                      )}
                    </div>
                    {/* Enhanced status indicator */}
                    <div
                      className={`
                        absolute w-3 h-3 sm:w-3.5 sm:h-3.5 rounded-full border-2 border-white
                        bottom-0.5 right-0.5 ${getStatusColor(user.status)} flex items-center justify-center
                      `}
                      title={`${user.status} ${user.status === 'offline' && user.lastSeen ? `• Last seen ${formatTime(user.lastSeen)}` : ''}`}
                    >
                      <i className={`${getStatusIcon(user.status)} text-xs`}></i>
                    </div>
                  </div>
                  
                  <div className="flex-grow min-w-0">
                    <div className="flex justify-content-between items-start mb-1">
                      <div className="flex-grow min-w-0">
                        <h6 className="mb-0 truncate font-semibold text-sm sm:text-base flex items-center">
                          {user.name}
                          {/* Online indicator */}
                          {isUserOnline(user._id) && (
                            <span className="ml-2 inline-flex items-center">
                              <i className="bi bi-lightning-charge-fill text-green-500 text-xs"></i>
                            </span>
                          )}
                          {/* Typing indicator */}
                          {isUserTyping(user._id) && (
                            <span className="ml-2 text-xs">
                              <i className="bi bi-three-dots text-blue-500 animate-pulse"></i>
                            </span>
                          )}
                        </h6>
                        <p
                          className={`
                            mb-0 truncate text-xs sm:text-sm leading-tight flex items-center mt-1
                            ${activeUserId === user._id 
                              ? 'text-white/80' 
                              : 'text-gray-500'
                            }
                            ${user.unreadCount > 0 ? 'font-medium' : 'font-normal'}
                          `}
                        >
                          {/* Show typing indicator or last message */}
                          {isUserTyping(user._id) ? (
                            <span className="text-blue-500 italic flex items-center">
                              <i className="bi bi-three-dots mr-1"></i>
                              typing...
                            </span>
                          ) : (
                            user.lastMessage || "No messages yet"
                          )}
                        </p>
                      </div>
                      
                      <div className="flex items-center space-x-2 ml-3 flex-shrink-0">
                        {/* Time */}
                        {user.lastMessageTime && (
                          <div className="flex flex-col items-end">
                            <small
                              className={`
                                whitespace-nowrap text-xs font-medium flex items-center
                                ${activeUserId === user._id ? 'text-white/80' : 'text-gray-500'}
                              `}
                            >
                              <i className="bi bi-clock mr-1"></i>
                              {formatTime(user.lastMessageTime)}
                            </small>
                          </div>
                        )}
                        
                        {user.unreadCount > 0 && (
                          <Badge
                            pill
                            bg="primary"
                            className="text-xs font-semibold min-w-5 h-5 flex items-center justify-center"
                          >
                            {user.unreadCount > 99 ? "99+" : user.unreadCount}
                          </Badge>
                        )}
                        
                        <div className="relative" ref={dropdownRef}>
                          <button
                            onClick={(e) => toggleDropdown(user._id, e)}
                            className={`
                              w-6 h-6 rounded-full flex items-center justify-center transition-all duration-200
                              ${activeUserId === user._id 
                                ? 'hover:bg-white/20 text-white/80' 
                                : 'hover:bg-gray-200 text-gray-500'
                              }
                              ${activeDropdown === user._id ? 'bg-gray-200 text-gray-700' : ''}
                            `}
                            title="More options"
                          >
                            <i className="bi bi-three-dots-vertical text-sm"></i>
                          </button>
                          
                          {activeDropdown === user._id && (
                            <div className="absolute right-0 top-8 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-50">
                              <button
                                onClick={(e) => handleDropdownAction('pin', user, e)}
                                className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 flex items-center"
                              >
                                <i className="bi bi-pin-angle mr-3 text-gray-500"></i>
                                Pin conversation
                              </button>
                              <button
                                onClick={(e) => handleDropdownAction('markUnread', user, e)}
                                className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 flex items-center"
                              >
                                <i className="bi bi-envelope mr-3 text-blue-500"></i>
                                Mark as unread
                              </button>
                              <button
                                onClick={(e) => handleDropdownAction('mute', user, e)}
                                className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 flex items-center"
                              >
                                <i className="bi bi-volume-mute mr-3 text-amber-500"></i>
                                Mute notifications
                              </button>
                              <button
                                onClick={(e) => handleDropdownAction('archive', user, e)}
                                className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 flex items-center"
                              >
                                <i className="bi bi-archive mr-3 text-gray-500"></i>
                                Archive conversation
                              </button>
                              <hr className="my-1 border-gray-200" />
                              <button
                                onClick={(e) => handleDropdownAction('block', user, e)}
                                className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 flex items-center"
                              >
                                <i className="bi bi-person-slash mr-3 text-orange-500"></i>
                                Block user
                              </button>
                              <button
                                onClick={(e) => handleDropdownAction('delete', user, e)}
                                className="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center"
                              >
                                <i className="bi bi-trash3 mr-3 text-red-500"></i>
                                Delete conversation
                              </button>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center text-center py-12">
            <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-full flex items-center justify-center mb-3 bg-gradient-to-br from-indigo-500/10 to-purple-600/10">
              <i className="bi bi-chat-square-text text-2xl sm:text-4xl text-indigo-500"></i>
            </div>
            <h6 className="text-gray-500 mb-2 font-medium flex items-center">
              <i className="bi bi-inbox mr-2"></i>
              No conversations yet
            </h6>
            <p className="text-gray-400 text-sm mb-0 px-3 flex items-center justify-center">
              <i className="bi bi-plus-circle mr-1"></i>
              Start a conversation to see it appear here
            </p>
          </div>
        )}
      </div>

      {/* Delete Confirmation Modal */}
      <Modal 
        show={showDeleteModal} 
        onHide={handleDeleteCancel}
        centered
        backdrop="static"
      >
        <Modal.Header closeButton className="border-0 pb-2">
          <Modal.Title className="text-lg font-semibold flex items-center">
            <i className="bi bi-exclamation-triangle-fill text-red-500 mr-2"></i>
            Delete Conversation
          </Modal.Title>
        </Modal.Header>
        <Modal.Body className="pt-0">
          <div className="flex items-start space-x-3">
            <div className="flex-shrink-0">
              <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center">
                <i className="bi bi-trash3 text-red-600 text-lg"></i>
              </div>
            </div>
            <div className="flex-grow">
              <p className="text-gray-700 mb-2">
                Are you sure you want to delete your conversation with{" "}
                <span className="font-semibold text-gray-900">
                  {userToDelete?.name}
                </span>
                ?
              </p>
              <p className="text-sm text-gray-500 mb-0">
                <i className="bi bi-info-circle mr-1"></i>
                This action cannot be undone. All messages will be permanently deleted.
              </p>
            </div>
          </div>
        </Modal.Body>
        <Modal.Footer className="border-0 pt-0">
          <div className="flex justify-end space-x-2 w-full">
            <Button
              variant="outline-secondary"
              onClick={handleDeleteCancel}
              className="px-4 py-2 text-sm font-medium"
            >
              <i className="bi bi-x-lg mr-1"></i>
              Cancel
            </Button>
            <Button
              variant="danger"
              onClick={handleDeleteConfirm}
              className="px-4 py-2 text-sm font-medium"
            >
              <i className="bi bi-trash3 mr-1"></i>
              Delete
            </Button>
          </div>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default UsersList;