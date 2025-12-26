// src/components/Chat/MessageList.tsx
import React from 'react';
import './MessageList.css';
import { Message } from './type';

interface MessageListProps {
  messages: Message[];
  currentUserId: string;
  messagesEndRef: React.RefObject<HTMLDivElement>;
}

const MessageList: React.FC<MessageListProps> = ({ messages, currentUserId, messagesEndRef }) => {
  if (messages.length === 0) {
    return (
      <div className="no-messages">
        <p>No messages yet</p>
        <p>Start the conversation by sending a message!</p>
      </div>
    );
  }

  const formatTime = (timestamp: string): string => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="messages-list">
      {messages.map((message) => (
        <div
          key={message._id}
          className={`message-item ${message.sender._id === currentUserId ? 'sent' : 'received'}`}
        >
          {message.sender._id !== currentUserId && (
            <img 
              src={message.sender.image || '/default-avatar.png'} 
              alt={message.sender.name} 
              className="message-avatar" 
            />
          )}
          <div className="message-content">
            <div className="message-bubble">
              <p>{message.message}</p>
            </div>
            <span className="message-time">{formatTime(message.createdAt)}</span>
          </div>
        </div>
      ))}
      <div ref={messagesEndRef} />
    </div>
  );
};

export default MessageList;
