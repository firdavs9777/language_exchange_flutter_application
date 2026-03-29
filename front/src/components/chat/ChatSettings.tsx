import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import {
  ArrowLeft,
  Bell,
  BellOff,
  Image,
  FileText,
  Search,
  Ban,
  Flag,
  Trash2,
  ChevronRight,
} from 'lucide-react';
import {
  useMuteConversationMutation,
  useUnmuteConversationMutation,
  useDeleteConversationMutation,
} from '../../store/slices/chatSlice';
import { useGetUserByIdQuery } from '../../store/slices/usersSlice';
import { RootState } from '../../store';
import './ChatSettings.scss';

const ChatSettings: React.FC = () => {
  const { conversationId } = useParams<{ conversationId: string }>();
  const navigate = useNavigate();
  const [isMuted, setIsMuted] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  // Get other user ID from conversation ID
  const currentUserId = useSelector((state: RootState) => state.auth.userInfo?.user?._id);
  const otherUserId = conversationId || '';

  const { data: userData } = useGetUserByIdQuery(otherUserId, {
    skip: !otherUserId,
  });

  const [muteConversation] = useMuteConversationMutation();
  const [unmuteConversation] = useUnmuteConversationMutation();
  const [deleteConversation] = useDeleteConversationMutation();

  const user = userData?.data;
  const avatar = user?.imageUrls?.[0] || '/default-avatar.png';

  const handleToggleMute = async () => {
    if (!conversationId) return;

    try {
      if (isMuted) {
        await unmuteConversation(conversationId);
      } else {
        await muteConversation({ conversationId });
      }
      setIsMuted(!isMuted);
    } catch (error) {
      console.error('Failed to toggle mute:', error);
    }
  };

  const handleDeleteConversation = async () => {
    if (!conversationId) return;

    try {
      await deleteConversation(conversationId);
      navigate('/chat');
    } catch (error) {
      console.error('Failed to delete conversation:', error);
    }
  };

  const handleBlock = () => {
    // Implement block user logic
    console.log('Block user:', otherUserId);
  };

  const handleReport = () => {
    // Implement report user logic
    console.log('Report user:', otherUserId);
  };

  return (
    <div className="chat-settings">
      {/* Header */}
      <header className="settings-header">
        <button className="back-btn" onClick={() => navigate(-1)}>
          <ArrowLeft size={24} />
        </button>
        <h1>Chat Settings</h1>
      </header>

      {/* User Profile Section */}
      <div className="profile-section">
        <div className="profile-avatar">
          <img src={avatar} alt={user?.name || 'User'} />
        </div>
        <h2 className="profile-name">{user?.name || 'Unknown User'}</h2>
        <p className="profile-status">
          {user?.bio || 'No bio available'}
        </p>
        <button
          className="view-profile-btn"
          onClick={() => navigate(`/profile/${otherUserId}`)}
        >
          View Profile
        </button>
      </div>

      {/* Settings Sections */}
      <div className="settings-sections">
        {/* Notifications */}
        <section className="settings-section">
          <h3 className="section-title">Notifications</h3>
          <div className="settings-item toggle" onClick={handleToggleMute}>
            <div className="item-left">
              {isMuted ? <BellOff size={20} /> : <Bell size={20} />}
              <span>Mute Notifications</span>
            </div>
            <div className={`toggle-switch ${isMuted ? 'active' : ''}`}>
              <div className="toggle-thumb" />
            </div>
          </div>
        </section>

        {/* Media & Files */}
        <section className="settings-section">
          <h3 className="section-title">Media & Files</h3>
          <div
            className="settings-item"
            onClick={() => navigate(`/chat/${conversationId}/media?type=photos`)}
          >
            <div className="item-left">
              <Image size={20} />
              <div className="item-text">
                <span>Shared Media</span>
                <small>42 photos, 3 videos</small>
              </div>
            </div>
            <ChevronRight size={20} className="chevron" />
          </div>
          <div
            className="settings-item"
            onClick={() => navigate(`/chat/${conversationId}/media?type=files`)}
          >
            <div className="item-left">
              <FileText size={20} />
              <div className="item-text">
                <span>Shared Files</span>
                <small>5 files</small>
              </div>
            </div>
            <ChevronRight size={20} className="chevron" />
          </div>
        </section>

        {/* Actions */}
        <section className="settings-section">
          <h3 className="section-title">Actions</h3>
          <div
            className="settings-item"
            onClick={() => navigate(`/chat/${conversationId}/search`)}
          >
            <div className="item-left">
              <Search size={20} />
              <span>Search in Conversation</span>
            </div>
            <ChevronRight size={20} className="chevron" />
          </div>
          <div className="settings-item warning" onClick={handleBlock}>
            <div className="item-left">
              <Ban size={20} />
              <span>Block User</span>
            </div>
          </div>
          <div className="settings-item warning" onClick={handleReport}>
            <div className="item-left">
              <Flag size={20} />
              <span>Report User</span>
            </div>
          </div>
        </section>

        {/* Danger Zone */}
        <section className="settings-section danger">
          <div
            className="settings-item danger"
            onClick={() => setShowDeleteConfirm(true)}
          >
            <div className="item-left">
              <Trash2 size={20} />
              <span>Delete Conversation</span>
            </div>
          </div>
        </section>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && (
        <div className="modal-overlay" onClick={() => setShowDeleteConfirm(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h3>Delete Conversation?</h3>
            <p>
              This will permanently delete all messages in this conversation.
              This action cannot be undone.
            </p>
            <div className="modal-actions">
              <button
                className="cancel-btn"
                onClick={() => setShowDeleteConfirm(false)}
              >
                Cancel
              </button>
              <button className="delete-btn" onClick={handleDeleteConversation}>
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ChatSettings;
