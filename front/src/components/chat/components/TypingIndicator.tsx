import React from 'react';
import './TypingIndicator.scss';

interface TypingIndicatorProps {
  userName: string;
  avatar?: string;
}

const TypingIndicator: React.FC<TypingIndicatorProps> = ({ userName, avatar }) => {
  return (
    <div className="typing-indicator" role="status" aria-live="polite">
      {avatar && (
        <div className="typing-avatar">
          <img src={avatar} alt={userName} />
        </div>
      )}
      <div className="typing-bubble">
        <div className="typing-dots">
          <span className="typing-dot" />
          <span className="typing-dot" />
          <span className="typing-dot" />
        </div>
        <span className="typing-text">{userName} is typing...</span>
      </div>
    </div>
  );
};

export default TypingIndicator;
