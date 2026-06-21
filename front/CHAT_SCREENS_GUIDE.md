# BananaTalk Chat Module - Frontend Web Developer Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [API Hooks Reference](#api-hooks-reference)
4. [Socket.IO Integration](#socketio-integration)
5. [Screen 1: Conversations List](#screen-1-conversations-list)
6. [Screen 2: Chat Room](#screen-2-chat-room)
7. [Screen 3: New Chat / User Search](#screen-3-new-chat--user-search)
8. [Screen 4: Chat Settings](#screen-4-chat-settings)
9. [Screen 5: Media Gallery](#screen-5-media-gallery)
10. [Components Library](#components-library)
11. [Message Types](#message-types)
12. [Real-time Features](#real-time-features)
13. [State Management](#state-management)
14. [Styling Guidelines](#styling-guidelines)
15. [Accessibility](#accessibility)

---

## Overview

The Chat Module provides real-time messaging with:
- Text, image, voice, video, and file messages
- Message reactions (emoji)
- Reply to messages
- Edit and delete messages
- Read receipts
- Typing indicators
- Online status
- Language corrections
- Message translation
- Conversation muting

### File Structure

```
src/components/chat/
├── MainChat.tsx                 # Conversations list
├── MainChat.scss
├── ChatContent.tsx              # Main chat room
├── ChatContent.css
├── NewChat.tsx                  # Start new conversation
├── NewChat.scss
├── ChatSettings.tsx             # Conversation settings
├── MediaGallery.tsx             # Shared media viewer
├── components/
│   ├── ConversationItem.tsx     # Single conversation row
│   ├── ConversationItem.scss
│   ├── MessageList.tsx          # Messages container
│   ├── MessageList.css
│   ├── MessageBubble.tsx        # Single message
│   ├── MessageBubble.scss
│   ├── MessageInput.tsx         # Input area
│   ├── MessageInput.scss
│   ├── VoiceRecorder.tsx        # Voice message recorder
│   ├── VoiceRecorder.scss
│   ├── MediaPreview.tsx         # Image/video preview
│   ├── EmojiPicker.tsx          # Emoji selection
│   ├── ReactionPicker.tsx       # Message reactions
│   ├── TypingIndicator.tsx      # "User is typing..."
│   ├── ReadReceipt.tsx          # Checkmarks
│   ├── OnlineStatus.tsx         # Green dot
│   ├── ReplyPreview.tsx         # Reply context
│   ├── CorrectionModal.tsx      # Language correction
│   └── TranslationBubble.tsx    # Translated message
├── hooks/
│   ├── useSocket.ts             # Socket connection
│   ├── useTyping.ts             # Typing indicator logic
│   ├── useMessages.ts           # Message operations
│   └── useVoiceRecorder.ts      # Voice recording
└── utils/
    ├── messageFormatter.ts      # Format timestamps, etc.
    ├── linkDetector.ts          # URL detection
    └── emojiUtils.ts            # Emoji helpers
```

---

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         Frontend                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Redux     │    │  Socket.IO  │    │   RTK       │     │
│  │   Store     │◄──►│   Client    │◄──►│   Query     │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                  │                  │             │
│         ▼                  ▼                  ▼             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              React Components                        │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│  │  │ Messages │  │  Input   │  │ Sidebar  │          │   │
│  │  │   List   │  │  Area    │  │  List    │          │   │
│  │  └──────────┘  └──────────┘  └──────────┘          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                         Backend                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  REST API   │    │  Socket.IO  │    │  Database   │     │
│  │  /messages  │    │   Server    │    │  MongoDB    │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## API Hooks Reference

**File:** `src/store/slices/chatSlice.ts`

```typescript
// Conversations
useGetConversationsQuery({ page, limit })
useCreateChatRoomMutation()
useDeleteConversationMutation()
useMarkConversationReadMutation()
useMuteConversationMutation()
useUnmuteConversationMutation()

// Messages
useGetMessagesQuery()
useGetUserMessagesQuery(userId)
useGetConversationQuery({ senderId, receiverId, page, limit })
useCreateMessageMutation()
useEditMessageMutation()
useDeleteMessageMutation()

// Reactions
useAddReactionMutation()
useRemoveReactionMutation()

// Voice
useSendVoiceMessageMutation()

// Media
useSendMediaMessageMutation()

// Read Receipts
useMarkMessageReadMutation()
useGetReadReceiptsQuery(messageId)

// Search
useSearchMessagesQuery({ query, conversationId, page, limit })

// Translation
useTranslateMessageMutation()

// Unread Count
useGetUnreadCountQuery()
```

---

## Socket.IO Integration

### Socket Hook

```typescript
// src/components/chat/hooks/useSocket.ts
import { useEffect, useRef, useCallback } from 'react';
import { io, Socket } from 'socket.io-client';
import { useSelector } from 'react-redux';
import { RootState } from '../../../store';

interface UseSocketOptions {
  onMessage?: (message: any) => void;
  onTyping?: (data: { conversationId: string; userId: string; isTyping: boolean }) => void;
  onMessageRead?: (data: { conversationId: string; messageId: string; readBy: string }) => void;
  onUserOnline?: (userId: string) => void;
  onUserOffline?: (userId: string) => void;
  onReaction?: (data: { messageId: string; userId: string; emoji: string }) => void;
  onMessageUpdated?: (message: any) => void;
  onMessageDeleted?: (messageId: string) => void;
}

const SOCKET_URL = process.env.REACT_APP_SOCKET_URL || 'https://api.banatalk.com';

export const useSocket = (options: UseSocketOptions = {}) => {
  const socketRef = useRef<Socket | null>(null);
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);

  useEffect(() => {
    if (!userInfo?.token) return;

    // Initialize socket connection
    socketRef.current = io(SOCKET_URL, {
      auth: { token: userInfo.token },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
    });

    const socket = socketRef.current;

    // Connection events
    socket.on('connect', () => {
      console.log('Socket connected:', socket.id);
      socket.emit('online');
    });

    socket.on('disconnect', (reason) => {
      console.log('Socket disconnected:', reason);
    });

    socket.on('connect_error', (error) => {
      console.error('Socket connection error:', error);
    });

    // Message events
    if (options.onMessage) {
      socket.on('message', options.onMessage);
      socket.on('newMessage', options.onMessage);
    }

    if (options.onTyping) {
      socket.on('typing', options.onTyping);
    }

    if (options.onMessageRead) {
      socket.on('messageRead', options.onMessageRead);
      socket.on('messagesRead', options.onMessageRead);
    }

    if (options.onUserOnline) {
      socket.on('userOnline', options.onUserOnline);
    }

    if (options.onUserOffline) {
      socket.on('userOffline', options.onUserOffline);
    }

    if (options.onReaction) {
      socket.on('reaction', options.onReaction);
    }

    if (options.onMessageUpdated) {
      socket.on('messageUpdated', options.onMessageUpdated);
    }

    if (options.onMessageDeleted) {
      socket.on('messageDeleted', options.onMessageDeleted);
    }

    // Cleanup
    return () => {
      socket.emit('offline');
      socket.disconnect();
    };
  }, [userInfo?.token]);

  // Emit functions
  const joinRoom = useCallback((conversationId: string) => {
    socketRef.current?.emit('joinRoom', conversationId);
  }, []);

  const leaveRoom = useCallback((conversationId: string) => {
    socketRef.current?.emit('leaveRoom', conversationId);
  }, []);

  const sendMessage = useCallback((data: {
    conversationId: string;
    receiverId: string;
    content: string;
    type?: string;
    replyTo?: string;
  }) => {
    socketRef.current?.emit('sendMessage', data);
  }, []);

  const sendTyping = useCallback((conversationId: string, isTyping: boolean) => {
    socketRef.current?.emit('typing', { conversationId, isTyping });
  }, []);

  const markRead = useCallback((conversationId: string, messageId: string) => {
    socketRef.current?.emit('markRead', { conversationId, messageId });
  }, []);

  return {
    socket: socketRef.current,
    joinRoom,
    leaveRoom,
    sendMessage,
    sendTyping,
    markRead,
    isConnected: socketRef.current?.connected || false,
  };
};
```

### Socket Events Reference

| Event | Direction | Payload | Description |
|-------|-----------|---------|-------------|
| `connect` | ← Server | - | Connection established |
| `disconnect` | ← Server | reason | Connection lost |
| `online` | → Server | - | Mark user as online |
| `offline` | → Server | - | Mark user as offline |
| `joinRoom` | → Server | conversationId | Join conversation room |
| `leaveRoom` | → Server | conversationId | Leave conversation room |
| `sendMessage` | → Server | MessageData | Send new message |
| `message` | ← Server | Message | Receive new message |
| `newMessage` | ← Server | Message | Receive new message |
| `typing` | ↔ Both | { conversationId, isTyping } | Typing indicator |
| `markRead` | → Server | { conversationId, messageId } | Mark message read |
| `messageRead` | ← Server | { messageId, readBy } | Message was read |
| `reaction` | ← Server | { messageId, emoji } | Reaction added |
| `messageUpdated` | ← Server | Message | Message edited |
| `messageDeleted` | ← Server | messageId | Message deleted |
| `userOnline` | ← Server | userId | User came online |
| `userOffline` | ← Server | userId | User went offline |

---

## Screen 1: Conversations List

**Route:** `/chat`
**File:** `src/components/chat/MainChat.tsx`

### Purpose
Display all conversations with last message preview, unread counts, and online status.

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Messages                              [🔍] [+ New Chat]    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🔍 Search conversations...                          │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ┌────┐                                              │    │
│  │ │ 🖼️ │  Sarah Kim                    🟢    2m ago   │    │
│  │ │    │  Hey! How's your Korean study going?    (3)  │    │
│  │ └────┘                                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ┌────┐                                              │    │
│  │ │ 🖼️ │  John Doe                     🔴    1h ago   │    │
│  │ │    │  Thanks for the help! 🙏                     │    │
│  │ └────┘                                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ┌────┐                                              │    │
│  │ │ 🖼️ │  Mike Johnson                 🟢   Just now  │    │
│  │ │    │  Typing...                                   │    │
│  │ └────┘                                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ┌────┐                                   🔇 Muted    │    │
│  │ │ 🖼️ │  Alex Park                    🔴   Yesterday │    │
│  │ │    │  You: See you tomorrow!          ✓✓         │    │
│  │ └────┘                                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Code

```typescript
// MainChat.tsx
import React, { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import {
  useGetConversationsQuery,
  useGetUnreadCountQuery,
  useDeleteConversationMutation,
  useMuteConversationMutation,
  useUnmuteConversationMutation
} from '../../store/slices/chatSlice';
import { useSocket } from './hooks/useSocket';
import ConversationItem from './components/ConversationItem';
import { RootState } from '../../store';
import './MainChat.scss';

interface Conversation {
  _id: string;
  participants: Array<{
    _id: string;
    name: string;
    photo: string;
    isOnline: boolean;
    lastActive: Date;
  }>;
  lastMessage: {
    content: string;
    type: string;
    sender: string;
    createdAt: Date;
    isRead: boolean;
  };
  unreadCount: number;
  isMuted: boolean;
  updatedAt: Date;
}

const MainChat: React.FC = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [onlineUsers, setOnlineUsers] = useState<Set<string>>(new Set());
  const [typingUsers, setTypingUsers] = useState<Map<string, string>>(new Map());

  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const userId = userInfo?.data?._id;

  const {
    data: conversationsData,
    isLoading,
    refetch
  } = useGetConversationsQuery({ page: 1, limit: 50 });

  const { data: unreadData } = useGetUnreadCountQuery();
  const [deleteConversation] = useDeleteConversationMutation();
  const [muteConversation] = useMuteConversationMutation();
  const [unmuteConversation] = useUnmuteConversationMutation();

  // Socket handlers
  const handleNewMessage = useCallback((message: any) => {
    refetch(); // Refresh conversation list
  }, [refetch]);

  const handleTyping = useCallback((data: { conversationId: string; userId: string; isTyping: boolean }) => {
    setTypingUsers(prev => {
      const newMap = new Map(prev);
      if (data.isTyping) {
        newMap.set(data.conversationId, data.userId);
      } else {
        newMap.delete(data.conversationId);
      }
      return newMap;
    });
  }, []);

  const handleUserOnline = useCallback((userId: string) => {
    setOnlineUsers(prev => new Set(prev).add(userId));
  }, []);

  const handleUserOffline = useCallback((userId: string) => {
    setOnlineUsers(prev => {
      const newSet = new Set(prev);
      newSet.delete(userId);
      return newSet;
    });
  }, []);

  const { socket } = useSocket({
    onMessage: handleNewMessage,
    onTyping: handleTyping,
    onUserOnline: handleUserOnline,
    onUserOffline: handleUserOffline,
  });

  const conversations: Conversation[] = conversationsData?.data || [];

  // Filter conversations by search
  const filteredConversations = conversations.filter(conv => {
    const otherUser = conv.participants.find(p => p._id !== userId);
    return otherUser?.name.toLowerCase().includes(searchQuery.toLowerCase());
  });

  // Get the other participant
  const getOtherUser = (conversation: Conversation) => {
    return conversation.participants.find(p => p._id !== userId);
  };

  // Check if user is typing
  const isTyping = (conversationId: string) => {
    return typingUsers.has(conversationId);
  };

  // Handle actions
  const handleDelete = async (conversationId: string) => {
    if (window.confirm('Delete this conversation?')) {
      await deleteConversation(conversationId);
      refetch();
    }
  };

  const handleMute = async (conversationId: string, isMuted: boolean) => {
    if (isMuted) {
      await unmuteConversation(conversationId);
    } else {
      await muteConversation({ conversationId });
    }
    refetch();
  };

  const handleConversationClick = (conversationId: string) => {
    navigate(`/chat/${conversationId}`);
  };

  if (isLoading) {
    return <div className="chat-loading">Loading conversations...</div>;
  }

  return (
    <div className="main-chat">
      {/* Header */}
      <header className="chat-header">
        <h1>Messages</h1>
        <div className="header-actions">
          <Link to="/chat/new" className="new-chat-btn">
            + New Chat
          </Link>
        </div>
      </header>

      {/* Search */}
      <div className="search-container">
        <input
          type="text"
          placeholder="Search conversations..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="search-input"
        />
      </div>

      {/* Conversations List */}
      <div className="conversations-list">
        {filteredConversations.length === 0 ? (
          <div className="empty-state">
            <p>No conversations yet</p>
            <Link to="/chat/new">Start a new chat</Link>
          </div>
        ) : (
          filteredConversations.map(conversation => {
            const otherUser = getOtherUser(conversation);
            const isUserOnline = onlineUsers.has(otherUser?._id || '') || otherUser?.isOnline;

            return (
              <ConversationItem
                key={conversation._id}
                conversation={conversation}
                otherUser={otherUser}
                isOnline={isUserOnline}
                isTyping={isTyping(conversation._id)}
                currentUserId={userId}
                onClick={() => handleConversationClick(conversation._id)}
                onDelete={() => handleDelete(conversation._id)}
                onMute={() => handleMute(conversation._id, conversation.isMuted)}
              />
            );
          })
        )}
      </div>

      {/* Total Unread Badge (for tab/navbar) */}
      {unreadData?.count > 0 && (
        <div className="total-unread-badge">
          {unreadData.count}
        </div>
      )}
    </div>
  );
};

export default MainChat;
```

### ConversationItem Component

```typescript
// ConversationItem.tsx
import React, { useState } from 'react';
import { formatDistanceToNow } from 'date-fns';
import OnlineStatus from './OnlineStatus';
import './ConversationItem.scss';

interface ConversationItemProps {
  conversation: any;
  otherUser: any;
  isOnline: boolean;
  isTyping: boolean;
  currentUserId: string;
  onClick: () => void;
  onDelete: () => void;
  onMute: () => void;
}

const ConversationItem: React.FC<ConversationItemProps> = ({
  conversation,
  otherUser,
  isOnline,
  isTyping,
  currentUserId,
  onClick,
  onDelete,
  onMute,
}) => {
  const [showMenu, setShowMenu] = useState(false);

  const lastMessage = conversation.lastMessage;
  const isOwnMessage = lastMessage?.sender === currentUserId;
  const isUnread = conversation.unreadCount > 0;

  const getLastMessagePreview = () => {
    if (isTyping) return 'Typing...';
    if (!lastMessage) return 'No messages yet';

    let preview = '';
    if (isOwnMessage) preview = 'You: ';

    switch (lastMessage.type) {
      case 'image':
        return preview + '📷 Photo';
      case 'voice':
        return preview + '🎤 Voice message';
      case 'video':
        return preview + '🎬 Video';
      case 'file':
        return preview + '📎 File';
      default:
        return preview + (lastMessage.content?.substring(0, 40) || '') +
               (lastMessage.content?.length > 40 ? '...' : '');
    }
  };

  const getTimeDisplay = () => {
    if (!lastMessage?.createdAt) return '';
    const date = new Date(lastMessage.createdAt);
    const now = new Date();
    const diff = now.getTime() - date.getTime();

    if (diff < 60000) return 'Just now';
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
    return formatDistanceToNow(date, { addSuffix: false });
  };

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    setShowMenu(true);
  };

  return (
    <div
      className={`conversation-item ${isUnread ? 'unread' : ''} ${isTyping ? 'typing' : ''}`}
      onClick={onClick}
      onContextMenu={handleContextMenu}
    >
      {/* Avatar */}
      <div className="avatar-container">
        <img
          src={otherUser?.photo || '/default-avatar.png'}
          alt={otherUser?.name}
          className="avatar"
        />
        <OnlineStatus isOnline={isOnline} />
      </div>

      {/* Content */}
      <div className="conversation-content">
        <div className="conversation-header">
          <span className="user-name">{otherUser?.name || 'Unknown'}</span>
          <span className="timestamp">{getTimeDisplay()}</span>
        </div>
        <div className="conversation-preview">
          <span className={`last-message ${isTyping ? 'typing' : ''}`}>
            {getLastMessagePreview()}
          </span>
          <div className="indicators">
            {conversation.isMuted && <span className="muted-icon">🔇</span>}
            {isUnread && (
              <span className="unread-badge">{conversation.unreadCount}</span>
            )}
            {isOwnMessage && lastMessage?.isRead && (
              <span className="read-receipt">✓✓</span>
            )}
            {isOwnMessage && !lastMessage?.isRead && (
              <span className="sent-receipt">✓</span>
            )}
          </div>
        </div>
      </div>

      {/* Context Menu */}
      {showMenu && (
        <div className="context-menu" onMouseLeave={() => setShowMenu(false)}>
          <button onClick={(e) => { e.stopPropagation(); onMute(); setShowMenu(false); }}>
            {conversation.isMuted ? 'Unmute' : 'Mute'}
          </button>
          <button onClick={(e) => { e.stopPropagation(); onDelete(); setShowMenu(false); }}>
            Delete
          </button>
        </div>
      )}
    </div>
  );
};

export default ConversationItem;
```

---

## Screen 2: Chat Room

**Route:** `/chat/:conversationId`
**File:** `src/components/chat/ChatContent.tsx`

### Purpose
Real-time messaging interface with all message features.

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [←]  Sarah Kim                     🟢 Online    [⋮ Menu]  │
├─────────────────────────────────────────────────────────────┤
│                     January 15, 2024                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│      ┌───────────────────────────────────┐                  │
│      │ Hey! How's your Korean study      │  10:30 AM       │
│      │ going? 😊                         │                  │
│      └───────────────────────────────────┘                  │
│                                                             │
│  ┌───────────────────────────────────┐                      │
│  │ It's going well! I learned 50     │  10:31 AM  ✓✓       │
│  │ new words this week.              │                      │
│  └───────────────────────────────────┘                      │
│                                                             │
│      ┌───────────────────────────────────┐                  │
│      │ That's amazing! 🎉               │  10:32 AM       │
│      │ Which words are the hardest?     │                  │
│      └───────────────────────────────────┘                  │
│      │ 😂 2  ❤️ 1                       │  ← Reactions     │
│                                                             │
│  ┌───────────────────────────────────┐                      │
│  │ ┌─────────────────────────────┐   │                      │
│  │ │ 🎤 Voice Message   0:15    │   │  10:33 AM  ✓✓       │
│  │ │ [▶️ ▬▬▬▬▬▬▬▬▬▬▬▬]         │   │                      │
│  │ └─────────────────────────────┘   │                      │
│  └───────────────────────────────────┘                      │
│                                                             │
│      ┌───────────────────────────────────┐                  │
│      │ ┌─────────────────────────────┐   │  10:34 AM       │
│      │ │        [Image]              │   │                  │
│      │ └─────────────────────────────┘   │                  │
│      │ Here's a pic of my notes 📝      │                  │
│      └───────────────────────────────────┘                  │
│                                                             │
│                   Sarah is typing...                        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Replying to: "That's amazing!"                  [X] │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│  [📎] [📷] [🎤]  Type a message...            [Send ➤]     │
└─────────────────────────────────────────────────────────────┘
```

### Message Bubble Variants

**Sent Message (Right-aligned):**
```
                              ┌──────────────────────┐
                              │ Hello! How are you?  │
                              └──────────────────────┘
                                          10:30 AM ✓✓
```

**Received Message (Left-aligned):**
```
┌──────────────────────┐
│ I'm good, thanks!    │
└──────────────────────┘
10:31 AM
```

**Message with Reply:**
```
┌──────────────────────────────────────┐
│ ┌────────────────────────────────┐   │
│ │ ↩ Replying to: "How are you?" │   │
│ └────────────────────────────────┘   │
│ I'm doing great today!               │
└──────────────────────────────────────┘
```

**Voice Message:**
```
┌──────────────────────────────────────┐
│ 🎤 Voice Message                     │
│ [▶️] ▬▬▬▬▬▬●▬▬▬▬▬▬  0:15 / 0:30     │
└──────────────────────────────────────┘
```

**Image Message:**
```
┌──────────────────────────────────────┐
│ ┌────────────────────────────────┐   │
│ │                                │   │
│ │          [Image]               │   │
│ │                                │   │
│ └────────────────────────────────┘   │
│ Check this out! 📸                   │
└──────────────────────────────────────┘
```

**Message with Reactions:**
```
┌──────────────────────┐
│ That's so funny! 😂  │
└──────────────────────┘
│ 😂 3  ❤️ 2  👍 1    │
```

**Corrected Message:**
```
┌──────────────────────────────────────┐
│ I [goed→went] to the store          │
│                                      │
│ 📝 Correction by Sarah              │
│ "Go → Went (irregular past tense)"  │
└──────────────────────────────────────┘
```

### Component Code

```typescript
// ChatContent.tsx
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import {
  useGetConversationQuery,
  useCreateMessageMutation,
  useEditMessageMutation,
  useDeleteMessageMutation,
  useAddReactionMutation,
  useSendVoiceMessageMutation,
  useSendMediaMessageMutation,
  useMarkConversationReadMutation,
  useTranslateMessageMutation
} from '../../store/slices/chatSlice';
import { useGetCommunityDetailsQuery } from '../../store/slices/communitySlice';
import { useSendCorrectionMutation } from '../../store/slices/learningSlice';
import { useSocket } from './hooks/useSocket';
import { useTyping } from './hooks/useTyping';
import MessageList from './components/MessageList';
import MessageInput from './components/MessageInput';
import TypingIndicator from './components/TypingIndicator';
import OnlineStatus from './components/OnlineStatus';
import ChatHeader from './components/ChatHeader';
import ReplyPreview from './components/ReplyPreview';
import CorrectionModal from './components/CorrectionModal';
import { RootState } from '../../store';
import './ChatContent.css';

interface Message {
  _id: string;
  sender: string;
  receiver: string;
  content: string;
  type: 'text' | 'image' | 'voice' | 'video' | 'file';
  mediaUrl?: string;
  duration?: number;
  replyTo?: Message;
  reactions: Array<{ userId: string; emoji: string }>;
  corrections?: Array<any>;
  translation?: string;
  isRead: boolean;
  readAt?: Date;
  isEdited: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const ChatContent: React.FC = () => {
  const { conversationId } = useParams<{ conversationId: string }>();
  const navigate = useNavigate();
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Local state
  const [messages, setMessages] = useState<Message[]>([]);
  const [replyingTo, setReplyingTo] = useState<Message | null>(null);
  const [editingMessage, setEditingMessage] = useState<Message | null>(null);
  const [correctingMessage, setCorrectingMessage] = useState<Message | null>(null);
  const [isOtherUserTyping, setIsOtherUserTyping] = useState(false);
  const [isOtherUserOnline, setIsOtherUserOnline] = useState(false);

  // Redux state
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const currentUserId = userInfo?.data?._id;

  // Get other user ID from conversation
  const otherUserId = conversationId?.split('_').find(id => id !== currentUserId) || '';

  // API hooks
  const {
    data: conversationData,
    isLoading,
    refetch
  } = useGetConversationQuery({
    senderId: currentUserId,
    receiverId: otherUserId,
    page: 1,
    limit: 50
  }, {
    skip: !currentUserId || !otherUserId
  });

  const { data: otherUserData } = useGetCommunityDetailsQuery(otherUserId, {
    skip: !otherUserId
  });

  const [createMessage] = useCreateMessageMutation();
  const [editMessage] = useEditMessageMutation();
  const [deleteMessage] = useDeleteMessageMutation();
  const [addReaction] = useAddReactionMutation();
  const [sendVoiceMessage] = useSendVoiceMessageMutation();
  const [sendMediaMessage] = useSendMediaMessageMutation();
  const [markConversationRead] = useMarkConversationReadMutation();
  const [translateMessage] = useTranslateMessageMutation();
  const [sendCorrection] = useSendCorrectionMutation();

  const otherUser = otherUserData?.data;

  // Socket handlers
  const handleNewMessage = useCallback((message: Message) => {
    if (message.sender === otherUserId || message.receiver === otherUserId) {
      setMessages(prev => [...prev, message]);
      scrollToBottom();

      // Mark as read if from other user
      if (message.sender === otherUserId && conversationId) {
        markConversationRead(conversationId);
      }
    }
  }, [otherUserId, conversationId, markConversationRead]);

  const handleTyping = useCallback((data: { userId: string; isTyping: boolean }) => {
    if (data.userId === otherUserId) {
      setIsOtherUserTyping(data.isTyping);
    }
  }, [otherUserId]);

  const handleUserOnline = useCallback((userId: string) => {
    if (userId === otherUserId) {
      setIsOtherUserOnline(true);
    }
  }, [otherUserId]);

  const handleUserOffline = useCallback((userId: string) => {
    if (userId === otherUserId) {
      setIsOtherUserOnline(false);
    }
  }, [otherUserId]);

  const handleMessageUpdated = useCallback((updatedMessage: Message) => {
    setMessages(prev => prev.map(msg =>
      msg._id === updatedMessage._id ? updatedMessage : msg
    ));
  }, []);

  const handleMessageDeleted = useCallback((messageId: string) => {
    setMessages(prev => prev.filter(msg => msg._id !== messageId));
  }, []);

  const handleReaction = useCallback((data: { messageId: string; userId: string; emoji: string }) => {
    setMessages(prev => prev.map(msg => {
      if (msg._id === data.messageId) {
        const existingReactionIndex = msg.reactions.findIndex(r => r.userId === data.userId);
        const newReactions = [...msg.reactions];

        if (existingReactionIndex >= 0) {
          if (newReactions[existingReactionIndex].emoji === data.emoji) {
            newReactions.splice(existingReactionIndex, 1);
          } else {
            newReactions[existingReactionIndex].emoji = data.emoji;
          }
        } else {
          newReactions.push({ userId: data.userId, emoji: data.emoji });
        }

        return { ...msg, reactions: newReactions };
      }
      return msg;
    }));
  }, []);

  const { joinRoom, leaveRoom, sendMessage: socketSendMessage, sendTyping, markRead } = useSocket({
    onMessage: handleNewMessage,
    onTyping: handleTyping,
    onUserOnline: handleUserOnline,
    onUserOffline: handleUserOffline,
    onMessageUpdated: handleMessageUpdated,
    onMessageDeleted: handleMessageDeleted,
    onReaction: handleReaction,
  });

  // Typing hook
  const { isTyping, startTyping, stopTyping } = useTyping((typing) => {
    if (conversationId) {
      sendTyping(conversationId, typing);
    }
  });

  // Load messages
  useEffect(() => {
    if (conversationData?.data) {
      setMessages(conversationData.data);
    }
  }, [conversationData]);

  // Join room on mount
  useEffect(() => {
    if (conversationId) {
      joinRoom(conversationId);
      markConversationRead(conversationId);
    }
    return () => {
      if (conversationId) {
        leaveRoom(conversationId);
      }
    };
  }, [conversationId, joinRoom, leaveRoom, markConversationRead]);

  // Scroll to bottom
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Message actions
  const handleSendMessage = async (content: string, type: 'text' = 'text') => {
    if (!content.trim() && type === 'text') return;

    const messageData = {
      sender: currentUserId,
      receiver: otherUserId,
      message: content,
      type,
      replyTo: replyingTo?._id
    };

    try {
      // Send via API
      await createMessage(messageData).unwrap();

      // Also emit via socket for real-time
      socketSendMessage({
        conversationId: conversationId!,
        receiverId: otherUserId,
        content,
        type,
        replyTo: replyingTo?._id
      });

      setReplyingTo(null);
      stopTyping();
    } catch (error) {
      console.error('Failed to send message:', error);
    }
  };

  const handleEditMessage = async (messageId: string, newContent: string) => {
    try {
      await editMessage({ messageId, content: newContent }).unwrap();
      setEditingMessage(null);
    } catch (error) {
      console.error('Failed to edit message:', error);
    }
  };

  const handleDeleteMessage = async (messageId: string, forEveryone: boolean = false) => {
    if (window.confirm('Delete this message?')) {
      try {
        await deleteMessage({ messageId, forEveryone }).unwrap();
      } catch (error) {
        console.error('Failed to delete message:', error);
      }
    }
  };

  const handleAddReaction = async (messageId: string, emoji: string) => {
    try {
      await addReaction({ messageId, emoji }).unwrap();
    } catch (error) {
      console.error('Failed to add reaction:', error);
    }
  };

  const handleSendVoice = async (audioBlob: Blob, duration: number) => {
    const formData = new FormData();
    formData.append('audio', audioBlob);
    formData.append('receiverId', otherUserId);
    formData.append('duration', duration.toString());

    try {
      await sendVoiceMessage({
        receiverId: otherUserId,
        audioData: formData,
        duration
      }).unwrap();
    } catch (error) {
      console.error('Failed to send voice message:', error);
    }
  };

  const handleSendMedia = async (file: File, type: 'image' | 'video' | 'file') => {
    const formData = new FormData();
    formData.append('media', file);
    formData.append('receiverId', otherUserId);
    formData.append('type', type);

    try {
      await sendMediaMessage({
        receiverId: otherUserId,
        media: formData,
        type
      }).unwrap();
    } catch (error) {
      console.error('Failed to send media:', error);
    }
  };

  const handleTranslate = async (messageId: string, targetLanguage: string) => {
    try {
      const result = await translateMessage({ messageId, targetLanguage }).unwrap();
      setMessages(prev => prev.map(msg =>
        msg._id === messageId ? { ...msg, translation: result.translation } : msg
      ));
    } catch (error) {
      console.error('Failed to translate:', error);
    }
  };

  const handleSendCorrection = async (data: {
    originalText: string;
    correctedText: string;
    explanation?: string;
  }) => {
    if (!correctingMessage) return;

    try {
      await sendCorrection({
        messageId: correctingMessage._id,
        ...data
      }).unwrap();
      setCorrectingMessage(null);
    } catch (error) {
      console.error('Failed to send correction:', error);
    }
  };

  if (isLoading) {
    return <div className="chat-loading">Loading messages...</div>;
  }

  return (
    <div className="chat-content">
      {/* Header */}
      <ChatHeader
        user={otherUser}
        isOnline={isOtherUserOnline || otherUser?.isOnline}
        onBack={() => navigate('/chat')}
        onSettings={() => navigate(`/chat/${conversationId}/settings`)}
      />

      {/* Messages */}
      <div className="messages-container">
        <MessageList
          messages={messages}
          currentUserId={currentUserId}
          onReply={setReplyingTo}
          onEdit={setEditingMessage}
          onDelete={handleDeleteMessage}
          onReact={handleAddReaction}
          onTranslate={handleTranslate}
          onCorrect={setCorrectingMessage}
        />
        <div ref={messagesEndRef} />

        {/* Typing Indicator */}
        {isOtherUserTyping && (
          <TypingIndicator userName={otherUser?.name || 'User'} />
        )}
      </div>

      {/* Reply Preview */}
      {replyingTo && (
        <ReplyPreview
          message={replyingTo}
          onCancel={() => setReplyingTo(null)}
        />
      )}

      {/* Input Area */}
      <MessageInput
        onSendMessage={handleSendMessage}
        onSendVoice={handleSendVoice}
        onSendMedia={handleSendMedia}
        onTyping={startTyping}
        onStopTyping={stopTyping}
        editingMessage={editingMessage}
        onCancelEdit={() => setEditingMessage(null)}
        onConfirmEdit={handleEditMessage}
      />

      {/* Correction Modal */}
      {correctingMessage && (
        <CorrectionModal
          message={correctingMessage}
          onSubmit={handleSendCorrection}
          onClose={() => setCorrectingMessage(null)}
        />
      )}
    </div>
  );
};

export default ChatContent;
```

### MessageInput Component

```typescript
// MessageInput.tsx
import React, { useState, useRef, useEffect } from 'react';
import VoiceRecorder from './VoiceRecorder';
import EmojiPicker from './EmojiPicker';
import './MessageInput.scss';

interface MessageInputProps {
  onSendMessage: (content: string, type?: 'text') => void;
  onSendVoice: (blob: Blob, duration: number) => void;
  onSendMedia: (file: File, type: 'image' | 'video' | 'file') => void;
  onTyping: () => void;
  onStopTyping: () => void;
  editingMessage?: any;
  onCancelEdit: () => void;
  onConfirmEdit: (messageId: string, content: string) => void;
}

const MessageInput: React.FC<MessageInputProps> = ({
  onSendMessage,
  onSendVoice,
  onSendMedia,
  onTyping,
  onStopTyping,
  editingMessage,
  onCancelEdit,
  onConfirmEdit,
}) => {
  const [message, setMessage] = useState('');
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);

  // Set edit message content
  useEffect(() => {
    if (editingMessage) {
      setMessage(editingMessage.content);
      inputRef.current?.focus();
    }
  }, [editingMessage]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!message.trim()) return;

    if (editingMessage) {
      onConfirmEdit(editingMessage._id, message);
    } else {
      onSendMessage(message, 'text');
    }
    setMessage('');
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setMessage(e.target.value);
    onTyping();
  };

  const handleBlur = () => {
    onStopTyping();
  };

  const handleEmojiSelect = (emoji: string) => {
    setMessage(prev => prev + emoji);
    setShowEmojiPicker(false);
    inputRef.current?.focus();
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>, type: 'image' | 'file') => {
    const file = e.target.files?.[0];
    if (file) {
      onSendMedia(file, type);
    }
    e.target.value = '';
  };

  const handleVoiceComplete = (blob: Blob, duration: number) => {
    onSendVoice(blob, duration);
    setIsRecording(false);
  };

  return (
    <div className="message-input-container">
      {/* Edit Mode Header */}
      {editingMessage && (
        <div className="edit-mode-header">
          <span>Editing message</span>
          <button onClick={onCancelEdit}>Cancel</button>
        </div>
      )}

      <form onSubmit={handleSubmit} className="message-form">
        {/* Attachment Buttons */}
        <div className="attachment-buttons">
          <button
            type="button"
            className="attach-btn"
            onClick={() => fileInputRef.current?.click()}
            disabled={isRecording}
          >
            📎
          </button>
          <button
            type="button"
            className="image-btn"
            onClick={() => imageInputRef.current?.click()}
            disabled={isRecording}
          >
            📷
          </button>
          <button
            type="button"
            className="voice-btn"
            onClick={() => setIsRecording(true)}
            disabled={message.length > 0}
          >
            🎤
          </button>
        </div>

        {/* Hidden File Inputs */}
        <input
          type="file"
          ref={fileInputRef}
          hidden
          onChange={(e) => handleFileSelect(e, 'file')}
        />
        <input
          type="file"
          ref={imageInputRef}
          accept="image/*,video/*"
          hidden
          onChange={(e) => handleFileSelect(e, 'image')}
        />

        {/* Voice Recorder or Text Input */}
        {isRecording ? (
          <VoiceRecorder
            onComplete={handleVoiceComplete}
            onCancel={() => setIsRecording(false)}
          />
        ) : (
          <>
            {/* Text Input */}
            <div className="input-wrapper">
              <textarea
                ref={inputRef}
                value={message}
                onChange={handleChange}
                onKeyPress={handleKeyPress}
                onBlur={handleBlur}
                placeholder="Type a message..."
                rows={1}
              />
              <button
                type="button"
                className="emoji-btn"
                onClick={() => setShowEmojiPicker(!showEmojiPicker)}
              >
                😊
              </button>
            </div>

            {/* Send Button */}
            <button
              type="submit"
              className={`send-btn ${message.trim() ? 'active' : ''}`}
              disabled={!message.trim()}
            >
              ➤
            </button>
          </>
        )}
      </form>

      {/* Emoji Picker */}
      {showEmojiPicker && (
        <EmojiPicker
          onSelect={handleEmojiSelect}
          onClose={() => setShowEmojiPicker(false)}
        />
      )}
    </div>
  );
};

export default MessageInput;
```

---

## Screen 3: New Chat / User Search

**Route:** `/chat/new`
**File:** `src/components/chat/NewChat.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  New Message                                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🔍 Search users...                                  │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Suggested                                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🖼️  Sarah Kim                              🟢       │    │
│  │     Following • 🇰🇷 Korean                         │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🖼️  John Doe                               🔴       │    │
│  │     Following • 🇯🇵 Japanese                       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Recent                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🖼️  Mike Johnson                          🟢       │    │
│  │     Last chat: Yesterday                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Search Results                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🖼️  Alex Park                              🔴       │    │
│  │     Seoul • 🇰🇷 Korean                             │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 4: Chat Settings

**Route:** `/chat/:conversationId/settings`
**File:** `src/components/chat/ChatSettings.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Chat Settings                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│        ┌─────────┐                                          │
│        │   🖼️    │                                          │
│        │ Avatar  │                                          │
│        └─────────┘                                          │
│         Sarah Kim                                           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Notifications                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Mute Notifications                    [Toggle OFF] │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Media & Files                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Shared Media                                    >   │    │
│  │ 42 photos, 3 videos                                │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Shared Files                                    >   │    │
│  │ 5 files                                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Actions                                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🔍 Search in Conversation                       >   │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🚫 Block User                                       │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ⚠️ Report User                                      │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🗑️ Delete Conversation                     (Red)    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 5: Media Gallery

**Route:** `/chat/:conversationId/media`
**File:** `src/components/chat/MediaGallery.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Shared Media                                     │
├─────────────────────────────────────────────────────────────┤
│  [Photos] [Videos] [Files]                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  January 2024                                               │
│  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐                   │
│  │       │ │       │ │       │ │       │                   │
│  │  📷   │ │  📷   │ │  📷   │ │  📷   │                   │
│  │       │ │       │ │       │ │       │                   │
│  └───────┘ └───────┘ └───────┘ └───────┘                   │
│                                                             │
│  December 2023                                              │
│  ┌───────┐ ┌───────┐ ┌───────┐                              │
│  │       │ │       │ │       │                              │
│  │  📷   │ │  📷   │ │  🎬   │                              │
│  │       │ │       │ │       │                              │
│  └───────┘ └───────┘ └───────┘                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Components Library

### Core Chat Components

```typescript
// OnlineStatus.tsx
interface OnlineStatusProps {
  isOnline: boolean;
  size?: 'small' | 'medium' | 'large';
}

// TypingIndicator.tsx
interface TypingIndicatorProps {
  userName: string;
}
// Shows: "Sarah is typing..." with animated dots

// ReadReceipt.tsx
interface ReadReceiptProps {
  status: 'sent' | 'delivered' | 'read';
}
// ✓ = sent, ✓✓ = delivered, ✓✓(blue) = read

// ReplyPreview.tsx
interface ReplyPreviewProps {
  message: Message;
  onCancel: () => void;
}

// EmojiPicker.tsx
interface EmojiPickerProps {
  onSelect: (emoji: string) => void;
  onClose: () => void;
}

// ReactionPicker.tsx
interface ReactionPickerProps {
  onSelect: (emoji: string) => void;
  selectedEmoji?: string;
}
// Quick reactions: ❤️ 😂 😮 😢 😡 👍

// VoiceRecorder.tsx
interface VoiceRecorderProps {
  onComplete: (blob: Blob, duration: number) => void;
  onCancel: () => void;
  maxDuration?: number; // seconds
}

// VoicePlayer.tsx
interface VoicePlayerProps {
  audioUrl: string;
  duration: number;
}

// MediaPreview.tsx
interface MediaPreviewProps {
  file: File;
  type: 'image' | 'video';
  onRemove: () => void;
  onSend: () => void;
}

// TranslationBubble.tsx
interface TranslationBubbleProps {
  original: string;
  translation: string;
  language: string;
}

// CorrectionModal.tsx
interface CorrectionModalProps {
  message: Message;
  onSubmit: (data: {
    originalText: string;
    correctedText: string;
    explanation?: string;
  }) => void;
  onClose: () => void;
}

// CorrectionDisplay.tsx
interface CorrectionDisplayProps {
  original: string;
  corrected: string;
  explanation?: string;
  correctorName: string;
}
```

---

## Message Types

### TypeScript Interfaces

```typescript
// Message Types
type MessageType = 'text' | 'image' | 'voice' | 'video' | 'file';

interface BaseMessage {
  _id: string;
  sender: string;
  receiver: string;
  conversationId: string;
  type: MessageType;
  isRead: boolean;
  readAt?: Date;
  isEdited: boolean;
  isDeleted: boolean;
  deletedFor: string[]; // user IDs who deleted this message
  reactions: Reaction[];
  replyTo?: string; // message ID
  createdAt: Date;
  updatedAt: Date;
}

interface TextMessage extends BaseMessage {
  type: 'text';
  content: string;
  translations?: Record<string, string>; // { 'ko': '안녕', 'es': 'hola' }
  corrections?: Correction[];
}

interface ImageMessage extends BaseMessage {
  type: 'image';
  mediaUrl: string;
  thumbnailUrl?: string;
  caption?: string;
  dimensions?: { width: number; height: number };
}

interface VoiceMessage extends BaseMessage {
  type: 'voice';
  mediaUrl: string;
  duration: number; // seconds
  waveform?: number[]; // amplitude data for visualization
  transcription?: string;
}

interface VideoMessage extends BaseMessage {
  type: 'video';
  mediaUrl: string;
  thumbnailUrl: string;
  duration: number;
  dimensions?: { width: number; height: number };
}

interface FileMessage extends BaseMessage {
  type: 'file';
  mediaUrl: string;
  fileName: string;
  fileSize: number; // bytes
  mimeType: string;
}

type Message = TextMessage | ImageMessage | VoiceMessage | VideoMessage | FileMessage;

// Reaction
interface Reaction {
  userId: string;
  emoji: string;
  createdAt: Date;
}

// Correction
interface Correction {
  _id: string;
  corrector: string;
  originalText: string;
  correctedText: string;
  explanation?: string;
  isAccepted: boolean;
  createdAt: Date;
}

// Conversation
interface Conversation {
  _id: string;
  participants: string[];
  type: 'direct' | 'group';
  lastMessage?: Message;
  unreadCount: Record<string, number>; // { 'userId': count }
  isMuted: Record<string, boolean>;
  createdAt: Date;
  updatedAt: Date;
}
```

---

## Real-time Features

### Typing Indicator Hook

```typescript
// hooks/useTyping.ts
import { useState, useRef, useCallback } from 'react';

export const useTyping = (
  onTypingChange: (isTyping: boolean) => void,
  debounceMs: number = 1000
) => {
  const [isTyping, setIsTyping] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout>();

  const startTyping = useCallback(() => {
    if (!isTyping) {
      setIsTyping(true);
      onTypingChange(true);
    }

    // Clear existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    // Set new timeout
    timeoutRef.current = setTimeout(() => {
      setIsTyping(false);
      onTypingChange(false);
    }, debounceMs);
  }, [isTyping, onTypingChange, debounceMs]);

  const stopTyping = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    setIsTyping(false);
    onTypingChange(false);
  }, [onTypingChange]);

  return { isTyping, startTyping, stopTyping };
};
```

### Voice Recording Hook

```typescript
// hooks/useVoiceRecorder.ts
import { useState, useRef, useCallback } from 'react';

interface UseVoiceRecorderReturn {
  isRecording: boolean;
  duration: number;
  startRecording: () => Promise<void>;
  stopRecording: () => Promise<Blob | null>;
  cancelRecording: () => void;
}

export const useVoiceRecorder = (maxDuration: number = 60): UseVoiceRecorderReturn => {
  const [isRecording, setIsRecording] = useState(false);
  const [duration, setDuration] = useState(0);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<NodeJS.Timer>();

  const startRecording = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      chunksRef.current = [];

      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          chunksRef.current.push(e.data);
        }
      };

      mediaRecorder.start(100);
      setIsRecording(true);
      setDuration(0);

      // Start timer
      timerRef.current = setInterval(() => {
        setDuration(d => {
          if (d >= maxDuration) {
            stopRecording();
            return d;
          }
          return d + 1;
        });
      }, 1000);
    } catch (error) {
      console.error('Failed to start recording:', error);
    }
  }, [maxDuration]);

  const stopRecording = useCallback(async (): Promise<Blob | null> => {
    return new Promise((resolve) => {
      if (!mediaRecorderRef.current) {
        resolve(null);
        return;
      }

      mediaRecorderRef.current.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: 'audio/webm' });
        resolve(blob);
      };

      mediaRecorderRef.current.stop();
      mediaRecorderRef.current.stream.getTracks().forEach(track => track.stop());

      if (timerRef.current) {
        clearInterval(timerRef.current);
      }

      setIsRecording(false);
    });
  }, []);

  const cancelRecording = useCallback(() => {
    if (mediaRecorderRef.current) {
      mediaRecorderRef.current.stop();
      mediaRecorderRef.current.stream.getTracks().forEach(track => track.stop());
    }
    if (timerRef.current) {
      clearInterval(timerRef.current);
    }
    chunksRef.current = [];
    setIsRecording(false);
    setDuration(0);
  }, []);

  return {
    isRecording,
    duration,
    startRecording,
    stopRecording,
    cancelRecording,
  };
};
```

---

## State Management

### Local Component State

```typescript
// Chat Room State
interface ChatRoomState {
  messages: Message[];
  isLoading: boolean;
  isSending: boolean;
  replyingTo: Message | null;
  editingMessage: Message | null;
  isOtherUserTyping: boolean;
  isOtherUserOnline: boolean;
}
```

### Redux State

RTK Query handles:
- Conversations list caching
- Messages caching per conversation
- Unread counts
- Optimistic updates

---

## Styling Guidelines

### Colors

```scss
// Message Bubbles
$sent-bubble-bg: #00BFA5;
$sent-bubble-text: #FFFFFF;
$received-bubble-bg: #F0F0F0;
$received-bubble-text: #1A1A1A;

// Status
$online-color: #4CAF50;
$offline-color: #9E9E9E;
$typing-color: #00BFA5;

// Read Receipts
$sent-check: #9E9E9E;
$read-check: #00BFA5;

// Reactions
$reaction-bg: #F5F5F5;
$reaction-active-bg: rgba(0, 191, 165, 0.1);
```

### Animations

```scss
// Typing dots animation
@keyframes typing-dots {
  0%, 20% { opacity: 0; }
  50% { opacity: 1; }
  80%, 100% { opacity: 0; }
}

.typing-dot {
  animation: typing-dots 1.4s infinite;
  &:nth-child(2) { animation-delay: 0.2s; }
  &:nth-child(3) { animation-delay: 0.4s; }
}

// Message send animation
@keyframes message-send {
  0% { transform: scale(0.8); opacity: 0; }
  100% { transform: scale(1); opacity: 1; }
}

// Voice recording pulse
@keyframes recording-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}
```

---

## Accessibility

### Keyboard Navigation

| Key | Action |
|-----|--------|
| `Enter` | Send message |
| `Shift + Enter` | New line |
| `Escape` | Cancel reply/edit |
| `Arrow Up` | Edit last message |
| `Tab` | Navigate between elements |

### ARIA Labels

```typescript
// Message bubble
<div
  role="article"
  aria-label={`Message from ${senderName} at ${time}`}
>

// Voice player
<button
  aria-label={isPlaying ? 'Pause voice message' : 'Play voice message'}
>

// Online status
<span
  role="status"
  aria-label={isOnline ? 'User is online' : 'User is offline'}
>
```

### Screen Reader Announcements

```typescript
// New message
<div role="status" aria-live="polite">
  New message from {senderName}
</div>

// Typing indicator
<div role="status" aria-live="polite">
  {userName} is typing
</div>
```

---

## Performance Tips

1. **Virtualize message list** - Use `react-window` for long conversations
2. **Lazy load images** - Use IntersectionObserver
3. **Compress images** - Before upload
4. **Cache audio** - Use service worker
5. **Debounce typing** - Don't emit on every keystroke
6. **Batch socket events** - Group multiple reads together
7. **Optimistic updates** - Show message before server confirms

---

## Error Handling

```typescript
// Send message with retry
const sendWithRetry = async (message: any, retries = 3) => {
  for (let i = 0; i < retries; i++) {
    try {
      await createMessage(message).unwrap();
      return true;
    } catch (error) {
      if (i === retries - 1) {
        showToast('Failed to send message. Please try again.');
        return false;
      }
      await new Promise(r => setTimeout(r, 1000 * (i + 1)));
    }
  }
  return false;
};

// Connection status
{!isConnected && (
  <div className="connection-warning">
    Connecting... Messages may be delayed.
  </div>
)}
```

---

## Testing Checklist

### Conversations
- [ ] List loads correctly
- [ ] Search filters work
- [ ] Unread badges show
- [ ] Online status updates
- [ ] Mute/unmute works
- [ ] Delete conversation works

### Messages
- [ ] Send text message
- [ ] Send image
- [ ] Send voice message
- [ ] Reply to message
- [ ] Edit message
- [ ] Delete message
- [ ] Add reaction
- [ ] Translate message
- [ ] Send correction

### Real-time
- [ ] Socket connects
- [ ] Receives new messages
- [ ] Typing indicator shows
- [ ] Online status updates
- [ ] Read receipts update

### Media
- [ ] Image upload works
- [ ] Image preview shows
- [ ] Voice recording works
- [ ] Voice playback works
- [ ] File upload works

---

## Contact

For questions about the Chat module implementation, contact the development team.
