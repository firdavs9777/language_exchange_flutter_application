import React, { useState, useEffect, useRef } from "react";
import { Button, Form, Container, Row, Col } from "react-bootstrap";
import { useSelector } from "react-redux";
import {
  useCreateMessageMutation,
  useGetConversationQuery,
} from "../../store/slices/chatSlice";
import io, { Socket } from "socket.io-client";
import "./ChatContent.css";
import { BASE_URL } from "../../constants";

// Define types for Redux state
interface RootState {
  auth: {
    userInfo: {
      user: {
        _id: string;
      };
      token: string;
    };
  };
}

// Define the Socket.IO instance
let socket: Socket | null = null;

interface ChatContentProps {
  selectedUser: string;
  userName: string;
  profilePicture: string;
}

interface Message {
  _id: string;
  message: string;
  sender: {
    _id: string;
    name: string;
    imageUrls?: string[];
  };
  receiver: string;
  createdAt: string;
  isOptimistic?: boolean;
  status?: "sent" | "delivered" | "error";
}

const ChatContent: React.FC<ChatContentProps> = ({
  selectedUser,
  userName,
  profilePicture,
}) => {
  const userId = useSelector(
    (state: RootState) => state.auth.userInfo?.user._id
  );
  const token = useSelector((state: RootState) => state.auth.userInfo?.token);

  const { data, error, isLoading } = useGetConversationQuery({
    senderId: userId,
    receiverId: selectedUser,
  });

  const [newMessage, setNewMessage] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [isTyping, setIsTyping] = useState(false);
  const [isOnline, setIsOnline] = useState(true);
  const [lastSeen, setLastSeen] = useState<string>("");
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const chatContainerRef = useRef<HTMLDivElement>(null);
  const typingTimeoutRef = useRef<NodeJS.Timeout>();
  const tempIdRef = useRef<string>();
  const lastMessageId = useRef<string>();

  // Initialize Socket.IO connection when token changes
  useEffect(() => {
    if (!token) return;

    const SOCKET_URL = BASE_URL;

    // Disconnect existing socket if any
    if (socket) {
      socket.disconnect();
    }

    socket = io(SOCKET_URL, {
      auth: {
        token: token,
      },
      transports: ["websocket"],
    });

    socket.on("connect", () => {
      console.log("Connected to socket server");
    });

    socket.on("connect_error", (error: Error) => {
      console.error("Socket connection error:", error);
    });

    // Enhanced online status listeners
    socket.on("userOnline", (data: { userId: string }) => {
      if (data.userId === selectedUser) {
        setIsOnline(true);
        setLastSeen("");
      }
    });

    socket.on("userOffline", (data: { userId: string; lastSeen: string }) => {
      if (data.userId === selectedUser) {
        setIsOnline(false);
        setLastSeen(data.lastSeen);
      }
    });

    return () => {
      if (socket) {
        socket.off();
        socket.disconnect();
        socket = null;
      }
    };
  }, [token, selectedUser]);

  // Load initial messages
  useEffect(() => {
    if (data?.data) {
      setMessages(data.data);
    }
  }, [data]);

  useEffect(() => {
    if (!socket || !selectedUser) return;

    // Handler for new messages - Updated to match server event name
    const handleNewMessage = (notificationData: {
      message: Message;
      unreadCount: number;
      isNewConversation: boolean;
    }) => {
      const newMsg = notificationData.message;
      console.log("Received new message:", newMsg);

      setMessages((prevMessages) => {
        if (prevMessages.some((msg) => msg._id === newMsg._id)) {
          return prevMessages;
        }
        return [...prevMessages, newMsg];
      });
    };

    // Handler for message errors
    const handleMessageError = (errorData: {
      message: string;
      error: string;
    }) => {
      console.error("Message error:", errorData);
      setMessages((prevMessages) => {
        return prevMessages.map((msg) => {
          if (msg.isOptimistic && msg._id === tempIdRef.current) {
            return { ...msg, status: "error" };
          }
          return msg;
        });
      });
    };

    // Handler for typing indicators - Updated to match server event
    const handleUserTyping = (data: { userId: string; isTyping: boolean }) => {
      if (data.userId === selectedUser) {
        setIsTyping(data.isTyping);
      }
    };

    // Register event listeners with correct event names
    socket.on("newMessage", handleNewMessage);
    socket.on("messageError", handleMessageError);
    socket.on("userTyping", handleUserTyping);

    return () => {
      socket?.off("newMessage", handleNewMessage);
      socket?.off("messageError", handleMessageError);
      socket?.off("userTyping", handleUserTyping);
    };
  }, [userId, selectedUser]);

  // Handle typing indicator
  const handleTyping = () => {
    if (!socket || !selectedUser) return;

    if (typingTimeoutRef.current) {
      clearTimeout(typingTimeoutRef.current);
    }

    // Send typing event with correct format
    socket.emit("typing", { receiver: selectedUser });

    typingTimeoutRef.current = setTimeout(() => {
      socket?.emit("stopTyping", { receiver: selectedUser });
    }, 2000);
  };

  // Auto-scroll to bottom only when new messages arrive
  useEffect(() => {
    if (messages.length > 0) {
      const currentLastId = messages[messages.length - 1]._id;
      if (lastMessageId.current !== currentLastId) {
        scrollToBottom();
        lastMessageId.current = currentLastId;
      }
    }
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !socket) return;

    try {
      // Clear typing indicator
      socket.emit("stopTyping", { receiver: selectedUser });

      // Create optimistic message
      const tempId = `temp-${Date.now()}`;
      tempIdRef.current = tempId;
      const optimisticMessage: Message = {
        _id: tempId,
        message: newMessage,
        sender: { _id: userId, name: userName },
        receiver: selectedUser,
        createdAt: new Date().toISOString(),
        isOptimistic: true,
        status: "sent",
      };

      setMessages((prev) => [...prev, optimisticMessage]);
      const messageToSend = newMessage;
      setNewMessage("");

      // Send message via socket with callback for acknowledgment
      socket.emit(
        "sendMessage",
        {
          receiver: selectedUser,
          message: messageToSend,
        },
        (response: any) => {
          if (response.status === "success") {
            console.log("Message sent successfully:", response);
            // Update the optimistic message with the real one
            setMessages((prevMessages) => {
              return prevMessages.map((msg) => {
                if (msg._id === tempId) {
                  return { ...response.message, status: "delivered" };
                }
                return msg;
              });
            });
          } else {
            console.error("Message send failed:", response);
            // Mark message as error
            setMessages((prevMessages) => {
              return prevMessages.map((msg) => {
                if (msg._id === tempId) {
                  return { ...msg, status: "error" };
                }
                return msg;
              });
            });
          }
        }
      );
    } catch (error) {
      console.error("Error sending message:", error);
      setMessages((prev) =>
        prev.map((msg) =>
          msg._id === tempIdRef.current ? { ...msg, status: "error" } : msg
        )
      );
    }
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString();
  };

  const formatLastSeen = (dateString: string) => {
    if (!dateString) return "";
    const date = new Date(dateString);
    const now = new Date();
    const diffInMinutes = Math.floor(
      (now.getTime() - date.getTime()) / (1000 * 60)
    );

    if (diffInMinutes < 1) return "Just now";
    if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
    if (diffInMinutes < 1440) return `${Math.floor(diffInMinutes / 60)}h ago`;
    return date.toLocaleDateString();
  };

  // Group messages by date
  const groupMessagesByDate = (messages: Message[]) => {
    const groups: { [date: string]: Message[] } = {};

    messages.forEach((msg) => {
      const dateStr = formatDate(msg.createdAt);
      if (!groups[dateStr]) {
        groups[dateStr] = [];
      }
      groups[dateStr].push(msg);
    });

    return groups;
  };

  if (isLoading)
    return (
      <div className="chat-loading">
        <div className="loading-spinner">
          <div className="spinner"></div>
        </div>
        <p className="loading-text">Loading conversation...</p>
      </div>
    );

  if (error)
    return (
      <div className="chat-error">
        <div className="error-icon">⚠️</div>
        <p>Error loading conversation</p>
      </div>
    );

  // Sort messages by timestamp
  const sortedMessages = [...messages].sort((a, b) => {
    return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
  });

  const messagesByDate = groupMessagesByDate(sortedMessages);

  return (
    <Container fluid className="modern-chat-container">
      {/* Enhanced Chat Header */}
      <div className="modern-chat-header">
        <div className="header-content">
          <div className="user-info-section">
            <div className="profile-avatar-container">
              <img
                src={profilePicture || "/default-avatar.png"}
                alt={userName}
                className="profile-avatar"
              />
              <div
                className={`status-pulse ${isOnline ? "online" : "offline"}`}
              >
                <div className="pulse-ring"></div>
                <div className="pulse-dot"></div>
              </div>
            </div>
            <div className="user-details">
              <h3 className="user-name">{userName}</h3>
              <div className="status-info">
                {isOnline ? (
                  <span className="online-status">
                    <span className="status-dot online"></span>
                    Online
                  </span>
                ) : (
                  <span className="offline-status">
                    <span className="status-dot offline"></span>
                    {lastSeen
                      ? `Last seen ${formatLastSeen(lastSeen)}`
                      : "Offline"}
                  </span>
                )}
              </div>
            </div>
          </div>

          <div className="header-actions">
            <button className="action-btn call-btn">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
              </svg>
            </button>
            <button className="action-btn video-btn">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <polygon points="23 7 16 12 23 17 23 7" />
                <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
              </svg>
            </button>
            <button className="action-btn info-btn">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <circle cx="12" cy="12" r="10" />
                <line x1="12" y1="16" x2="12" y2="12" />
                <line x1="12" y1="8" x2="12.01" y2="8" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Enhanced Chat Messages */}
      <div className="modern-chat-messages" ref={chatContainerRef}>
        {Object.entries(messagesByDate).map(([date, msgs]) => (
          <div key={date} className="message-date-group">
            <div className="date-separator">
              <span className="date-text">{date}</span>
            </div>

            {msgs.map((msg: Message) => (
              <div
                key={msg._id}
                className={`modern-message ${
                  msg.sender._id === userId ? "sent" : "received"
                } ${msg.status === "error" ? "error" : ""}`}
              >
                {msg.sender._id !== userId && (
                  <div className="message-avatar">
                    <img
                      src={msg.sender.imageUrls?.[0] || "/default-avatar.png"}
                      alt={msg.sender.name}
                    />
                  </div>
                )}

                <div className="message-wrapper">
                  <div className="message-bubble">
                    <p className="message-text">{msg.message}</p>
                    <div className="message-meta">
                      <span className="message-time">
                        {formatTime(msg.createdAt)}
                      </span>
                      {msg.sender._id === userId && (
                        <div className="message-status">
                          {msg.status === "error" ? (
                            <svg
                              className="status-icon error"
                              viewBox="0 0 24 24"
                              fill="currentColor"
                            >
                              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
                            </svg>
                          ) : msg.isOptimistic ? (
                            <svg
                              className="status-icon sent"
                              viewBox="0 0 24 24"
                              fill="currentColor"
                            >
                              <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
                            </svg>
                          ) : (
                            <svg
                              className="status-icon delivered"
                              viewBox="0 0 24 24"
                              fill="currentColor"
                            >
                              <path d="M18 7l-1.41-1.41-6.34 6.34 1.41 1.41L18 7zm4.24-1.41L11.66 16.17 7.48 12l-1.41 1.41L11.66 19l12-12-1.42-1.41zM.41 13.41L6 19l1.41-1.41L1.83 12 .41 13.41z" />
                            </svg>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ))}

        {/* Enhanced Typing Indicator */}
        {isTyping && (
          <div className="modern-message received">
            <div className="message-avatar">
              <img
                src={profilePicture || "/default-avatar.png"}
                alt={userName}
              />
            </div>
            <div className="message-wrapper">
              <div className="typing-indicator-bubble">
                <div className="typing-animation">
                  <div className="typing-dot"></div>
                  <div className="typing-dot"></div>
                  <div className="typing-dot"></div>
                </div>
                <span className="typing-text">{userName} is typing...</span>
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Enhanced Message Input */}
      <div className="modern-chat-input">
        <Form onSubmit={handleSendMessage} className="input-form">
          <div className="input-container">
            <button type="button" className="attachment-btn">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <circle cx="12" cy="12" r="10" />
                <line x1="12" y1="8" x2="12" y2="16" />
                <line x1="8" y1="12" x2="16" y2="12" />
              </svg>
            </button>

            <div className="text-input-wrapper">
              <Form.Control
                type="text"
                placeholder="Type your message..."
                value={newMessage}
                onChange={(e) => {
                  setNewMessage(e.target.value);
                  handleTyping();
                }}
                className="modern-text-input "
              />
              <button type="button" className="emoji-btn">
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                >
                  <circle cx="12" cy="12" r="10" />
                  <path d="M8 14s1.5 2 4 2 4-2 4-2" />
                  <line x1="9" y1="9" x2="9.01" y2="9" />
                  <line x1="15" y1="9" x2="15.01" y2="9" />
                </svg>
              </button>
            </div>

            <button
              type="submit"
              className={`send-btn ${newMessage.trim() ? "active" : ""}`}
              disabled={!newMessage.trim()}
            >
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <line x1="22" y1="2" x2="11" y2="13" />
                <polygon points="22,2 15,22 11,13 2,9 22,2" />
              </svg>
            </button>
          </div>
        </Form>
      </div>

      <style jsx>{`
        .modern-chat-container {
          height: 100vh;
          display: flex;
          flex-direction: column;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          position: relative;
          overflow: hidden;
        }

        .modern-chat-container::before {
          content: "";
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(255, 255, 255, 0.02);
          backdrop-filter: blur(10px);
          z-index: 0;
        }

        .modern-chat-header {
          background: rgba(255, 255, 255, 0.1);
          backdrop-filter: blur(20px);
          border-bottom: 1px solid rgba(255, 255, 255, 0.1);
          padding: 1rem 1.5rem;
          z-index: 2;
          position: relative;
        }

        .header-content {
          display: flex;
          align-items: center;
          justify-content: space-between;
        }

        .user-info-section {
          display: flex;
          align-items: center;
          gap: 1rem;
        }

        .profile-avatar-container {
          position: relative;
        }

        .profile-avatar {
          width: 48px;
          height: 48px;
          border-radius: 50%;
          object-fit: cover;
          border: 3px solid rgba(255, 255, 255, 0.3);
        }

        .status-pulse {
          position: absolute;
          bottom: 2px;
          right: 2px;
          width: 16px;
          height: 16px;
        }

        .status-pulse.online .pulse-ring {
          border: 2px solid #00ff88;
          border-radius: 50%;
          height: 16px;
          width: 16px;
          position: absolute;
          animation: pulse-ring 1.25s cubic-bezier(0.215, 0.61, 0.355, 1)
            infinite;
        }

        .status-pulse.online .pulse-dot {
          background-color: #00ff88;
          border-radius: 50%;
          height: 8px;
          width: 8px;
          position: absolute;
          top: 4px;
          left: 4px;
        }

        .status-pulse.offline .pulse-dot {
          background-color: #ff6b6b;
          border-radius: 50%;
          height: 8px;
          width: 8px;
          position: absolute;
          top: 4px;
          left: 4px;
        }

        @keyframes pulse-ring {
          0% {
            transform: scale(0.33);
          }
          80%,
          100% {
            opacity: 0;
          }
        }

        .user-details {
          color: white;
        }

        .user-name {
          font-size: 1.2rem;
          font-weight: 600;
          margin: 0;
          text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
        }

        .status-info {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          margin-top: 0.25rem;
        }

        .online-status,
        .offline-status {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          font-size: 0.875rem;
          opacity: 0.9;
        }

        .status-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
        }

        .status-dot.online {
          background-color: #00ff88;
          box-shadow: 0 0 8px rgba(0, 255, 136, 0.5);
        }

        .status-dot.offline {
          background-color: #ff6b6b;
        }

        .header-actions {
          display: flex;
          gap: 0.5rem;
        }

        .action-btn {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          border: none;
          background: rgba(255, 255, 255, 0.1);
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.2s ease;
          backdrop-filter: blur(10px);
        }

        .action-btn:hover {
          background: rgba(255, 255, 255, 0.2);
          transform: translateY(-1px);
        }

        .action-btn svg {
          width: 18px;
          height: 18px;
        }

        .modern-chat-messages {
          flex: 1;
          overflow-y: auto;
          padding: 1.5rem;
          z-index: 1;
          position: relative;
        }

        .message-date-group {
          margin-bottom: 2rem;
        }

        .date-separator {
          text-align: center;
          margin: 2rem 0 1.5rem;
        }

        .date-text {
          background: rgba(255, 255, 255, 0.15);
          color: white;
          padding: 0.5rem 1rem;
          border-radius: 20px;
          font-size: 0.875rem;
          font-weight: 500;
          backdrop-filter: blur(10px);
        }

        .modern-message {
          display: flex;
          margin-bottom: 1rem;
          animation: slideInMessage 0.3s ease-out;
        }

        .modern-message.sent {
          justify-content: flex-end;
        }

        .modern-message.received {
          justify-content: flex-start;
        }

        @keyframes slideInMessage {
          from {
            opacity: 0;
            transform: translateY(10px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        .message-avatar {
          width: 36px;
          height: 36px;
          margin-right: 0.75rem;
          flex-shrink: 0;
        }

        .message-avatar img {
          width: 100%;
          height: 100%;
          border-radius: 50%;
          object-fit: cover;
          border: 2px solid rgba(255, 255, 255, 0.3);
        }

        .message-wrapper {
          max-width: 70%;
        }

        .message-bubble {
          padding: 1rem 1.25rem;
          border-radius: 18px;
          position: relative;
          backdrop-filter: blur(20px);
          border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .modern-message.sent .message-bubble {
          background: linear-gradient(
            135deg,
            rgba(255, 255, 255, 0.25),
            rgba(255, 255, 255, 0.15)
          );
          color: white;
          margin-left: auto;
        }

        .modern-message.received .message-bubble {
          background: rgba(255, 255, 255, 0.9);
          color: #333;
        }

        .message-text {
          margin: 0;
          line-height: 1.4;
          word-wrap: break-word;
        }

        .message-meta {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-top: 0.5rem;
          gap: 0.5rem;
        }

        .message-time {
          font-size: 0.75rem;
          opacity: 0.7;
        }

        .message-status {
          display: flex;
          align-items: center;
        }

        .status-icon {
          width: 16px;
          height: 16px;
        }

        .status-icon.sent {
          color: rgba(255, 255, 255, 0.7);
        }

        .status-icon.delivered {
          color: #00ff88;
        }

        .status-icon.error {
          color: #ff6b6b;
        }

        .typing-indicator-bubble {
          background: rgba(255, 255, 255, 0.9);
          padding: 1rem 1.25rem;
          border-radius: 18px;
          display: flex;
          align-items: center;
          gap: 0.75rem;
          backdrop-filter: blur(20px);
          border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .typing-animation {
          display: flex;
          gap: 4px;
        }

        .typing-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          background-color: #667eea;
          animation: typing-bounce 1.4s infinite ease-in-out;
        }

        .typing-dot:nth-child(1) {
          animation-delay: -0.32s;
        }
        .typing-dot:nth-child(2) {
          animation-delay: -0.16s;
        }

        @keyframes typing-bounce {
          0%,
          80%,
          100% {
            transform: scale(0.7);
            opacity: 0.5;
          }
          40% {
            transform: scale(1);
            opacity: 1;
          }
        }

        .typing-text {
          font-size: 0.875rem;
          color: #666;
          font-style: italic;
        }

        .modern-chat-input {
          padding: 1.5rem;
          background: rgba(255, 255, 255, 0.1);
          backdrop-filter: blur(20px);
          border-top: 1px solid rgba(255, 255, 255, 0.1);
          z-index: 2;
          position: relative;
        }

        .input-form {
          margin: 0;
        }

        .input-container {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          background: rgba(255, 255, 255, 0.15);
          border-radius: 25px;
          padding: 0.5rem;
          backdrop-filter: blur(20px);
          border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .attachment-btn,
        .emoji-btn {
          width: 36px;
          height: 36px;
          border-radius: 50%;
          border: none;
          background: transparent;
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .attachment-btn:hover,
        .emoji-btn:hover {
          background: rgba(255, 255, 255, 0.1);
          transform: scale(1.1);
        }

        .attachment-btn svg,
        .emoji-btn svg {
          width: 20px;
          height: 20px;
        }

        .text-input-wrapper {
          flex: 1;
          position: relative;
          display: flex;
          align-items: center;
        }

        .modern-text-input {
          border: none;
          background: transparent;
          color: white;
          font-size: 1rem;
          padding: 0.75rem 1rem;
          flex: 1;
          outline: none;
        }

        .modern-text-input::placeholder {
          color: rgba(255, 255, 255, 0.6);
        }

        .modern-text-input:focus {
          box-shadow: none;
          border: none;
          background: transparent;
        }

        .send-btn {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          border: none;
          background: linear-gradient(135deg, #667eea, #764ba2);
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.3s ease;
          opacity: 0.5;
          transform: scale(0.9);
        }

        .send-btn.active {
          opacity: 1;
          transform: scale(1);
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }

        .send-btn:hover.active {
          transform: scale(1.05);
          box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
        }

        .send-btn:disabled {
          cursor: not-allowed;
        }

        .send-btn svg {
          width: 20px;
          height: 20px;
        }

        .chat-loading {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          height: 100vh;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }

        .loading-spinner {
          margin-bottom: 1rem;
        }

        .spinner {
          width: 40px;
          height: 40px;
          border: 4px solid rgba(255, 255, 255, 0.3);
          border-top: 4px solid white;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }

        @keyframes spin {
          0% {
            transform: rotate(0deg);
          }
          100% {
            transform: rotate(360deg);
          }
        }

        .loading-text {
          font-size: 1.1rem;
          opacity: 0.9;
          margin: 0;
        }

        .chat-error {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          height: 100vh;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          text-align: center;
        }

        .error-icon {
          font-size: 3rem;
          margin-bottom: 1rem;
        }

        .chat-error p {
          font-size: 1.1rem;
          margin: 0;
          opacity: 0.9;
        }

        /* Scrollbar Styling */
        .modern-chat-messages::-webkit-scrollbar {
          width: 6px;
        }

        .modern-chat-messages::-webkit-scrollbar-track {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 3px;
        }

        .modern-chat-messages::-webkit-scrollbar-thumb {
          background: rgba(255, 255, 255, 0.3);
          border-radius: 3px;
        }

        .modern-chat-messages::-webkit-scrollbar-thumb:hover {
          background: rgba(255, 255, 255, 0.5);
        }

        /* Responsive Design */
        @media (max-width: 768px) {
          .modern-chat-header {
            padding: 1rem;
          }

          .header-actions {
            gap: 0.25rem;
          }

          .action-btn {
            width: 36px;
            height: 36px;
          }

          .action-btn svg {
            width: 16px;
            height: 16px;
          }

          .modern-chat-messages {
            padding: 1rem;
          }

          .message-wrapper {
            max-width: 85%;
          }

          .modern-chat-input {
            padding: 1rem;
          }

          .user-name {
            font-size: 1.1rem;
          }

          .profile-avatar {
            width: 42px;
            height: 42px;
          }
        }

        /* Message Error State */
        .modern-message.error .message-bubble {
          border: 1px solid rgba(255, 107, 107, 0.5);
          background: linear-gradient(
            135deg,
            rgba(255, 107, 107, 0.15),
            rgba(255, 107, 107, 0.05)
          );
        }

        /* Message Animation on Send */
        .modern-message.sent .message-bubble {
          animation: messageSlideIn 0.3s ease-out;
        }

        @keyframes messageSlideIn {
          from {
            opacity: 0;
            transform: translateX(20px) scale(0.95);
          }
          to {
            opacity: 1;
            transform: translateX(0) scale(1);
          }
        }

        /* Enhanced Focus States */
        .modern-text-input:focus {
          outline: none;
        }

        .input-container:focus-within {
          border-color: rgba(255, 255, 255, 0.4);
          box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.1);
        }

        /* Pulse Animation for Online Status */
        @keyframes pulse-ring {
          0% {
            transform: scale(0.33);
            opacity: 1;
          }
          80%,
          100% {
            opacity: 0;
            transform: scale(2.33);
          }
        }

        /* Message Hover Effects */
        .modern-message:hover .message-bubble {
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        /* Smooth Transitions */
        * {
          transition: all 0.2s ease;
        }

        /* Custom Form Control Override */
        .modern-text-input.form-control {
          border: none !important;
          box-shadow: none !important;
          background: transparent !important;
        }

        .modern-text-input.form-control:focus {
          border: none !important;
          box-shadow: none !important;
          background: transparent !important;
        }
      `}</style>
    </Container>
  );
};

export default ChatContent;
