/* ChatInput.tsx */
import React from 'react';
import './ChatInput.css';

interface ChatInputProps {
  messageText: string;
  setMessageText: React.Dispatch<React.SetStateAction<string>>;
  onSendMessage: () => void;
  isSendingMessage: boolean;
}

const ChatInput: React.FC<ChatInputProps> = ({ messageText, setMessageText, onSendMessage, isSendingMessage }) => {
  return (
    <div className="chat-input">
      <textarea
        value={messageText}
        onChange={(e) => setMessageText(e.target.value)}
        placeholder="Type your message..."
      />
      <button onClick={onSendMessage} disabled={isSendingMessage}>
        {isSendingMessage ? 'Sending...' : 'Send'}
      </button>
    </div>
  );
};

export default ChatInput;
