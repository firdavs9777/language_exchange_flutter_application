import React from 'react';
import { ArrowLeft, Phone, Video, MoreVertical, Settings } from 'lucide-react';
import OnlineStatus from './OnlineStatus';
import { formatLastSeen } from '../utils/messageFormatter';
import './ChatHeader.scss';

interface User {
  _id: string;
  name: string;
  photo?: string;
  imageUrls?: string[];
  isOnline?: boolean;
  lastActive?: string | Date;
}

interface ChatHeaderProps {
  user?: User;
  isOnline?: boolean;
  lastSeen?: string;
  onBack: () => void;
  onSettings?: () => void;
  onCall?: () => void;
  onVideoCall?: () => void;
}

const ChatHeader: React.FC<ChatHeaderProps> = ({
  user,
  isOnline = false,
  lastSeen,
  onBack,
  onSettings,
  onCall,
  onVideoCall,
}) => {
  const avatar = user?.photo || user?.imageUrls?.[0] || '/default-avatar.png';

  return (
    <header className="chat-header">
      <div className="header-left">
        <button className="back-btn" onClick={onBack} aria-label="Go back">
          <ArrowLeft size={24} />
        </button>

        <div className="user-info">
          <div className="avatar-container">
            <img src={avatar} alt={user?.name || 'User'} className="avatar" />
            <OnlineStatus isOnline={isOnline} size="medium" />
          </div>

          <div className="user-details">
            <h3 className="user-name">{user?.name || 'Unknown User'}</h3>
            <span className="user-status">
              {isOnline ? (
                <span className="online-text">Online</span>
              ) : lastSeen ? (
                <span className="last-seen">Last seen {formatLastSeen(lastSeen)}</span>
              ) : (
                <span className="offline-text">Offline</span>
              )}
            </span>
          </div>
        </div>
      </div>

      <div className="header-actions">
        {onCall && (
          <button className="action-btn call-btn" onClick={onCall} aria-label="Voice call">
            <Phone size={20} />
          </button>
        )}
        {onVideoCall && (
          <button className="action-btn video-btn" onClick={onVideoCall} aria-label="Video call">
            <Video size={20} />
          </button>
        )}
        {onSettings && (
          <button className="action-btn settings-btn" onClick={onSettings} aria-label="Chat settings">
            <MoreVertical size={20} />
          </button>
        )}
      </div>
    </header>
  );
};

export default ChatHeader;
