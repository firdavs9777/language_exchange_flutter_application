import React, { useState } from 'react';
import { MoreVertical, Bell, BellOff, Trash2, Pin, Archive } from 'lucide-react';
import OnlineStatus from './OnlineStatus';
import { formatConversationTime } from '../utils/messageFormatter';
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
  isActive?: boolean;
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
  isActive = false,
}) => {
  const [showMenu, setShowMenu] = useState(false);

  const lastMessage = conversation.lastMessage;
  const isOwnMessage = lastMessage?.sender === currentUserId;
  const isUnread = conversation.unreadCount > 0;
  const avatar = otherUser?.photo || otherUser?.imageUrls?.[0] || '/default-avatar.png';

  const getLastMessagePreview = () => {
    if (isTyping) return 'Typing...';
    if (!lastMessage) return 'No messages yet';

    let preview = '';
    if (isOwnMessage) preview = 'You: ';

    const content = lastMessage.content || lastMessage.message || '';

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
        return preview + (content.substring(0, 40) || '') +
               (content.length > 40 ? '...' : '');
    }
  };

  const handleMenuClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setShowMenu(!showMenu);
  };

  const handleAction = (action: () => void) => (e: React.MouseEvent) => {
    e.stopPropagation();
    action();
    setShowMenu(false);
  };

  return (
    <div
      className={`conversation-item ${isUnread ? 'unread' : ''} ${isTyping ? 'typing' : ''} ${isActive ? 'active' : ''}`}
      onClick={onClick}
    >
      {/* Avatar */}
      <div className="avatar-container">
        <img src={avatar} alt={otherUser?.name} className="avatar" />
        <OnlineStatus isOnline={isOnline} size="medium" />
      </div>

      {/* Content */}
      <div className="conversation-content">
        <div className="conversation-header">
          <span className="user-name">{otherUser?.name || 'Unknown'}</span>
          <span className="timestamp">
            {lastMessage?.createdAt && formatConversationTime(lastMessage.createdAt)}
          </span>
        </div>
        <div className="conversation-preview">
          <span className={`last-message ${isTyping ? 'typing' : ''}`}>
            {getLastMessagePreview()}
          </span>
          <div className="indicators">
            {conversation.isMuted && (
              <span className="muted-icon">
                <BellOff size={14} />
              </span>
            )}
            {isUnread && (
              <span className="unread-badge">
                {conversation.unreadCount > 99 ? '99+' : conversation.unreadCount}
              </span>
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

      {/* Menu Button */}
      <button className="menu-btn" onClick={handleMenuClick}>
        <MoreVertical size={18} />
      </button>

      {/* Context Menu */}
      {showMenu && (
        <div className="context-menu" onMouseLeave={() => setShowMenu(false)}>
          <button onClick={handleAction(onMute)}>
            {conversation.isMuted ? <Bell size={16} /> : <BellOff size={16} />}
            {conversation.isMuted ? 'Unmute' : 'Mute'}
          </button>
          <button>
            <Pin size={16} />
            Pin
          </button>
          <button>
            <Archive size={16} />
            Archive
          </button>
          <div className="divider" />
          <button className="delete" onClick={handleAction(onDelete)}>
            <Trash2 size={16} />
            Delete
          </button>
        </div>
      )}
    </div>
  );
};

export default ConversationItem;
