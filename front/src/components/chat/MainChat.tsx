import React, { useState, useEffect } from "react";
import UsersList from "./UsersList";
import ChatContent from "./ChatContent";
import { useNavigate, useParams } from "react-router-dom";
import { useGetUserByIdQuery } from "../../store/slices/usersSlice";
import { useTranslation } from "react-i18next";
import { MessageCircle, Search, X, Plus, Sparkles } from "lucide-react";
import { SocketProvider } from "./hooks/useSocket";
import "./MainChat.css";

const MainChat: React.FC = () => {
  const { t } = useTranslation();
  const { userId } = useParams<{ userId?: string }>();
  const [userName, setUserName] = useState<string>("");
  const [profilePicture, setProfilePicture] = useState<string>("");
  const [initialOnlineStatus, setInitialOnlineStatus] = useState<boolean>(false);
  const [initialLastActive, setInitialLastActive] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const navigate = useNavigate();

  // Use RTK Query to fetch user info when navigating directly to chat URL
  const { data: userByIdData } = useGetUserByIdQuery(userId!, {
    skip: !userId || !!userName,
  });

  // Update userName, profilePicture, and online status when user data is fetched
  useEffect(() => {
    if (userByIdData?.data && userId && !userName) {
      setUserName(userByIdData.data.name || "");
      setProfilePicture(userByIdData.data.imageUrls?.[0] || "");
      setInitialOnlineStatus(userByIdData.data.isOnline || false);
      setInitialLastActive(userByIdData.data.lastActive || userByIdData.data.lastSeen || "");
    }
  }, [userByIdData, userId, userName]);

  // Reset user info when userId changes or becomes undefined
  useEffect(() => {
    if (!userId) {
      setUserName("");
      setProfilePicture("");
      setInitialOnlineStatus(false);
      setInitialLastActive("");
    }
  }, [userId]);

  const handleSelectUser = (
    selectedUserId: string,
    selectedUserName: string,
    selectedProfilePicture: string,
    selectedIsOnline?: boolean,
    selectedLastActive?: string
  ) => {
    if (selectedUserId !== userId) {
      navigate(`/chat/${selectedUserId}`);
    }
    setUserName(selectedUserName);
    setProfilePicture(selectedProfilePicture);
    setInitialOnlineStatus(selectedIsOnline || false);
    setInitialLastActive(selectedLastActive || "");
  };

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(e.target.value);
  };

  return (
    <SocketProvider>
    <div className={`chat-layout${userId ? " chat-selected" : ""}`}>
      {/* Sidebar */}
      <div className="chat-sidebar">
        {/* Sidebar Header */}
        <div className="sidebar-header">
          <div className="sidebar-title">
            <MessageCircle className="title-icon" />
            <h2>{t("chatPage.messages")}</h2>
          </div>
          <button className="new-chat-btn" onClick={() => navigate("/chat/new")}>
            <Plus size={20} />
          </button>
        </div>

        {/* Search Bar */}
        <div className="search-container">
          <div className="search-input-wrapper">
            <Search className="search-icon" size={18} />
            <input
              type="text"
              className="search-input"
              placeholder={t("chatPage.searchPlaceholder")}
              value={searchQuery}
              onChange={handleSearch}
            />
            {searchQuery && (
              <button
                className="clear-search-btn"
                onClick={() => setSearchQuery("")}
              >
                <X size={16} />
              </button>
            )}
          </div>
        </div>

        {/* Users List */}
        <div className="users-list-container">
          <UsersList
            onSelectUser={handleSelectUser}
            activeUserId={userId}
            searchQuery={searchQuery}
          />
        </div>
      </div>

      {/* Chat Area */}
      <div className="chat-area">
        {userId ? (
          <ChatContent
            selectedUser={userId}
            userName={userName}
            profilePicture={profilePicture}
            initialIsOnline={initialOnlineStatus}
            initialLastSeen={initialLastActive}
          />
        ) : (
          <div className="empty-chat-state">
            <div className="empty-chat-content">
              <div className="empty-icon-wrapper">
                <div className="empty-icon-bg">
                  <Sparkles className="empty-icon" size={48} />
                </div>
                <div className="empty-icon-ring" />
                <div className="empty-icon-ring delay" />
              </div>

              <h3 className="empty-title">{t("chatPage.startConversation")}</h3>
              <p className="empty-description">
                {t("chatPage.emptyDescription")}
              </p>

              <button
                className="start-chat-btn"
                onClick={() => navigate("/chat/new")}
              >
                <Plus size={20} />
                <span>{t("chatPage.newConversation")}</span>
              </button>

              <div className="empty-features">
                <div className="feature-item">
                  <div className="feature-dot" />
                  <span>{t("chatPage.features.realtime")}</span>
                </div>
                <div className="feature-item">
                  <div className="feature-dot" />
                  <span>{t("chatPage.features.exchange")}</span>
                </div>
                <div className="feature-item">
                  <div className="feature-dot" />
                  <span>{t("chatPage.features.calls")}</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
    </SocketProvider>
  );
};

export default MainChat;
