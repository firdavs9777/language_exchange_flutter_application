import React from 'react';
import { X, Reply } from 'lucide-react';
import './ReplyPreview.scss';

interface Message {
  _id: string;
  content?: string;
  message?: string;
  type?: string;
  sender?: {
    _id: string;
    name: string;
  };
}

interface ReplyPreviewProps {
  message: Message;
  onCancel: () => void;
}

const ReplyPreview: React.FC<ReplyPreviewProps> = ({ message, onCancel }) => {
  const getPreviewText = () => {
    const content = message.content || message.message;

    switch (message.type) {
      case 'image':
        return '📷 Photo';
      case 'voice':
        return '🎤 Voice message';
      case 'video':
        return '🎬 Video';
      case 'file':
        return '📎 File';
      default:
        return content?.substring(0, 60) + (content && content.length > 60 ? '...' : '') || '';
    }
  };

  return (
    <div className="reply-preview">
      <div className="reply-indicator">
        <Reply size={16} />
      </div>
      <div className="reply-content">
        <span className="reply-to">
          Replying to <strong>{message.sender?.name || 'User'}</strong>
        </span>
        <span className="reply-text">{getPreviewText()}</span>
      </div>
      <button className="cancel-reply" onClick={onCancel} aria-label="Cancel reply">
        <X size={18} />
      </button>
    </div>
  );
};

export default ReplyPreview;
