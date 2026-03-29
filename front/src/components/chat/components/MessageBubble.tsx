import React, { useState } from 'react';
import { Reply, Edit3, Trash2, Copy, Globe, CheckCircle } from 'lucide-react';
import VoicePlayer from './VoicePlayer';
import ReadReceipt from './ReadReceipt';
import ReactionPicker from './ReactionPicker';
import { formatMessageTime } from '../utils/messageFormatter';
import { isOnlyEmojis } from '../utils/emojiUtils';
import './MessageBubble.scss';

interface Reaction {
  userId: string;
  emoji: string;
}

interface Message {
  _id: string;
  content?: string;
  message?: string;
  type?: 'text' | 'image' | 'voice' | 'video' | 'file';
  mediaUrl?: string;
  duration?: number;
  sender: {
    _id: string;
    name: string;
    imageUrls?: string[];
  };
  receiver?: string;
  replyTo?: Message;
  reactions?: Reaction[];
  translation?: string;
  corrections?: any[];
  isRead?: boolean;
  isEdited?: boolean;
  isOptimistic?: boolean;
  status?: 'sending' | 'sent' | 'delivered' | 'read' | 'error';
  createdAt: string;
}

interface MessageBubbleProps {
  message: Message;
  isOwn: boolean;
  showAvatar?: boolean;
  onReply?: (message: Message) => void;
  onEdit?: (message: Message) => void;
  onDelete?: (messageId: string) => void;
  onReact?: (messageId: string, emoji: string) => void;
  onTranslate?: (messageId: string) => void;
  onCorrect?: (message: Message) => void;
}

const MessageBubble: React.FC<MessageBubbleProps> = ({
  message,
  isOwn,
  showAvatar = true,
  onReply,
  onEdit,
  onDelete,
  onReact,
  onTranslate,
  onCorrect,
}) => {
  const [showActions, setShowActions] = useState(false);
  const [showReactions, setShowReactions] = useState(false);

  const content = message.content || message.message || '';
  const isEmojiOnly = isOnlyEmojis(content) && content.length <= 8;
  const avatar = message.sender?.imageUrls?.[0] || '/default-avatar.png';

  const getMessageStatus = (): 'sending' | 'sent' | 'delivered' | 'read' | 'error' => {
    if (message.status) return message.status;
    if (message.isOptimistic) return 'sending';
    if (message.isRead) return 'read';
    return 'delivered';
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(content);
    setShowActions(false);
  };

  const renderContent = () => {
    switch (message.type) {
      case 'image':
        return (
          <div className="image-content">
            <img src={message.mediaUrl} alt="Shared image" />
            {content && <p className="image-caption">{content}</p>}
          </div>
        );

      case 'voice':
        return (
          <VoicePlayer
            audioUrl={message.mediaUrl || ''}
            duration={message.duration || 0}
          />
        );

      case 'video':
        return (
          <div className="video-content">
            <video src={message.mediaUrl} controls />
            {content && <p className="video-caption">{content}</p>}
          </div>
        );

      case 'file':
        return (
          <a href={message.mediaUrl} className="file-content" download>
            <span className="file-icon">📎</span>
            <span className="file-name">{content || 'Download file'}</span>
          </a>
        );

      default:
        return (
          <>
            {message.replyTo && (
              <div className="reply-context">
                <span className="reply-sender">{message.replyTo.sender?.name}</span>
                <span className="reply-text">
                  {message.replyTo.content || message.replyTo.message}
                </span>
              </div>
            )}
            <p className={`message-text ${isEmojiOnly ? 'emoji-only' : ''}`}>
              {content}
            </p>
            {message.translation && (
              <div className="translation">
                <Globe size={12} />
                <span>{message.translation}</span>
              </div>
            )}
            {message.corrections && message.corrections.length > 0 && (
              <div className="correction">
                <CheckCircle size={12} />
                <span>Corrected: {message.corrections[0].correctedText}</span>
              </div>
            )}
          </>
        );
    }
  };

  const renderReactions = () => {
    if (!message.reactions || message.reactions.length === 0) return null;

    const groupedReactions = message.reactions.reduce((acc, r) => {
      acc[r.emoji] = (acc[r.emoji] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return (
      <div className="reactions">
        {Object.entries(groupedReactions).map(([emoji, count]) => (
          <span key={emoji} className="reaction-item">
            {emoji} {count > 1 && <span className="count">{count}</span>}
          </span>
        ))}
      </div>
    );
  };

  return (
    <div
      className={`message-bubble ${isOwn ? 'own' : 'other'} ${isEmojiOnly ? 'emoji-only' : ''}`}
      onMouseEnter={() => setShowActions(true)}
      onMouseLeave={() => {
        setShowActions(false);
        setShowReactions(false);
      }}
    >
      {!isOwn && showAvatar && (
        <div className="message-avatar">
          <img src={avatar} alt={message.sender?.name} />
        </div>
      )}

      <div className="message-wrapper">
        {/* Reaction Picker */}
        {showReactions && (
          <div className="reaction-picker-container">
            <ReactionPicker
              onSelect={(emoji) => {
                onReact?.(message._id, emoji);
                setShowReactions(false);
              }}
              onClose={() => setShowReactions(false)}
            />
          </div>
        )}

        {/* Message Actions */}
        {showActions && (
          <div className={`message-actions ${isOwn ? 'left' : 'right'}`}>
            <button onClick={() => setShowReactions(true)} title="React">
              😊
            </button>
            <button onClick={() => onReply?.(message)} title="Reply">
              <Reply size={16} />
            </button>
            {onTranslate && (
              <button onClick={() => onTranslate(message._id)} title="Translate">
                <Globe size={16} />
              </button>
            )}
            {!isOwn && onCorrect && (
              <button onClick={() => onCorrect(message)} title="Correct">
                <CheckCircle size={16} />
              </button>
            )}
            <button onClick={handleCopy} title="Copy">
              <Copy size={16} />
            </button>
            {isOwn && (
              <>
                <button onClick={() => onEdit?.(message)} title="Edit">
                  <Edit3 size={16} />
                </button>
                <button onClick={() => onDelete?.(message._id)} title="Delete" className="delete">
                  <Trash2 size={16} />
                </button>
              </>
            )}
          </div>
        )}

        {/* Message Content */}
        <div className="bubble-content">
          {renderContent()}

          <div className="message-meta">
            {message.isEdited && <span className="edited">edited</span>}
            <span className="time">{formatMessageTime(message.createdAt)}</span>
            {isOwn && <ReadReceipt status={getMessageStatus()} />}
          </div>
        </div>

        {/* Reactions */}
        {renderReactions()}
      </div>
    </div>
  );
};

export default MessageBubble;
