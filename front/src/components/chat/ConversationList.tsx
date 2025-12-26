// src/components/Chat/ConversationList.tsx
import React from 'react';

import { Conversation } from './type';
import './ConversationList.css';
interface ConversationListProps {
  conversations: Conversation[];
  activeConversation: Conversation | null;
  onSelectConversation: (conversation: Conversation) => void;
  currentUserId: string;
}

const ConversationList: React.FC<ConversationListProps> = ({ 
  conversations, 
  activeConversation, 
  onSelectConversation, 
  currentUserId 
}) => {
  if (conversations.length === 0) {
    return (
      <div className="no-conversations">
        <p>No conversations yet</p>
        <p>Find language partners to start chatting!</p>
      </div>
    );
  }

  return (
    <div className="conversations-list">
      {conversations.map((conversation) => (
        <div
          key={conversation._id}
          className={`conversation-item ${activeConversation && activeConversation._id === conversation._id ? 'active' : ''}`}
          onClick={() => onSelectConversation(conversation)}
        >
          <img 
            src={conversation.image || '/default-avatar.png'} 
            alt={conversation.name} 
            className="profile-image-small" 
          />
          <div className="conversation-info">
            <h4>{conversation.name}</h4>
            <p className="language-info">
              {conversation.native_language} → {conversation.language_to_learn}
            </p>
            {conversation.recentMessage && (
              <p className="preview-message">
                {conversation.recentMessage.content.length > 30
                  ? conversation.recentMessage.content.substring(0, 30) + '...'
                  : conversation.recentMessage.content}
              </p>
            )}
          </div>
          <div className="conversation-time">
            {conversation.recentMessage && new Date(conversation.recentMessage.sentAt).toLocaleDateString()}
          </div>
        </div>
      ))}
    </div>
  );
};

export default ConversationList;
