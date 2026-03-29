import React, { useMemo } from "react";
import { useGetStoryFeedsQuery, useGetMyStoriesQuery } from "../../store/slices/storiesSlice";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { FaPlus } from "react-icons/fa";
import { StoryFeedUser, Story } from "./types";
import "./StoriesFeed.scss";

interface RootState {
  auth: {
    userInfo?: {
      user?: {
        _id: string;
        name: string;
        imageUrls?: string[];
      };
      data?: {
        _id: string;
        name: string;
        imageUrls?: string[];
      };
    };
  };
}

interface StoriesFeedProps {
  compact?: boolean;
}

const StoriesFeed: React.FC<StoriesFeedProps> = ({ compact = false }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userId = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?._id || state.auth.userInfo?.data?._id || null
  );
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);

  // Get stories feed
  const { data: feedData, isLoading: isLoadingFeed } = useGetStoryFeedsQuery();
  const { data: myStoriesData, isLoading: isLoadingMy } = useGetMyStoriesQuery({}, { skip: !userId });

  // Get user image
  const userImage = useMemo(() => {
    const user = (userInfo as any)?.user || (userInfo as any)?.data;
    return (
      user?.imageUrls?.[0] ||
      `https://ui-avatars.com/api/?name=${encodeURIComponent(user?.name || "User")}&background=667eea&color=fff&size=200`
    );
  }, [userInfo]);

  const userName = useMemo(() => {
    const user = (userInfo as any)?.user || (userInfo as any)?.data;
    return user?.name || "User";
  }, [userInfo]);

  // Process feed data
  const storyFeed = useMemo(() => {
    if (!feedData) return [];
    const response = feedData as { success?: boolean; data?: StoryFeedUser[]; count?: number };
    return response.data || [];
  }, [feedData]);

  // Process my stories
  const myStories = useMemo(() => {
    if (!myStoriesData) return [];
    const response = myStoriesData as { success?: boolean; data?: Story[]; count?: number };
    return Array.isArray(response) ? response : response.data || [];
  }, [myStoriesData]);

  const handleCreateStory = () => {
    navigate("/create-story");
  };

  const handleViewStory = (userId: string, storyIndex: number = 0) => {
    navigate(`/stories/${userId}`, { state: { startIndex: storyIndex } });
  };

  const handleViewMyStory = (storyIndex: number = 0) => {
    if (userId) {
      navigate(`/stories/${userId}`, { state: { startIndex: storyIndex } });
    }
  };

  // Show loading state if still loading
  if (isLoadingFeed || isLoadingMy) {
    return (
      <div className={`stories-feed-container ${compact ? "compact" : ""}`}>
        <div className="stories-feed">
          <div className="story-circle-wrapper">
            <div className="story-circle create-story">
              <div className="story-circle-image">
                <div className="story-loading-spinner"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`stories-feed-container ${compact ? "compact" : ""}`}>
      <div className="stories-feed">
        {/* My Story Circle (Create/View) */}
        <div className="story-circle-wrapper">
          <div
            className={`story-circle ${myStories.length > 0 ? "has-stories" : "create-story"}`}
            onClick={myStories.length > 0 ? () => handleViewMyStory(0) : handleCreateStory}
          >
            <div className="story-circle-image">
              <img
                src={userImage}
                alt={userName}
                onError={(e: any) => {
                  e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(userName)}&background=667eea&color=fff&size=200`;
                }}
              />
              {myStories.length === 0 && (
                <div className="create-story-icon">
                  <FaPlus />
                </div>
              )}
            </div>
            {myStories.length > 0 && (
              <div className="story-progress-ring">
                <svg className="progress-ring" viewBox="0 0 100 100">
                  <circle
                    className="progress-ring-circle"
                    cx="50"
                    cy="50"
                    r="48"
                    fill="none"
                    stroke="url(#gradient)"
                    strokeWidth="4"
                  />
                  <defs>
                    <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" stopColor="#667eea" />
                      <stop offset="100%" stopColor="#764ba2" />
                    </linearGradient>
                  </defs>
                </svg>
              </div>
            )}
          </div>
          <div className="story-circle-label">
            {myStories.length > 0
              ? t("stories.your_story") || "Your Story"
              : t("stories.create_story") || "Create"}
          </div>
        </div>

        {/* Other Users' Stories */}
        {storyFeed.map((feedUser: StoryFeedUser) => {
          const user = feedUser.user || feedUser;
          const stories = feedUser.stories || [];
          const hasUnviewed = feedUser.hasUnviewed || 0;
          const userImageUrl =
            user.imageUrls?.[0] ||
            user.images?.[0] ||
            `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name || "User")}&background=667eea&color=fff&size=200`;

          return (
            <div key={user._id || feedUser._id} className="story-circle-wrapper">
              <div
                className={`story-circle ${hasUnviewed > 0 ? "has-unviewed" : "viewed"}`}
                onClick={() => handleViewStory(user._id || feedUser._id, 0)}
              >
                <div className="story-circle-image">
                  <img
                    src={userImageUrl}
                    alt={user.name}
                    onError={(e: any) => {
                      e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name || "User")}&background=667eea&color=fff&size=200`;
                    }}
                  />
                </div>
                {hasUnviewed > 0 && (
                  <div className="story-progress-ring unviewed">
                    <svg className="progress-ring" viewBox="0 0 100 100">
                      <circle
                        className="progress-ring-circle"
                        cx="50"
                        cy="50"
                        r="48"
                        fill="none"
                        stroke="url(#gradientUnviewed)"
                        strokeWidth="4"
                      />
                      <defs>
                        <linearGradient id="gradientUnviewed" x1="0%" y1="0%" x2="100%" y2="100%">
                          <stop offset="0%" stopColor="#f093fb" />
                          <stop offset="100%" stopColor="#f5576c" />
                        </linearGradient>
                      </defs>
                    </svg>
                  </div>
                )}
                {hasUnviewed === 0 && stories.length > 0 && (
                  <div className="story-progress-ring viewed">
                    <svg className="progress-ring" viewBox="0 0 100 100">
                      <circle
                        className="progress-ring-circle"
                        cx="50"
                        cy="50"
                        r="48"
                        fill="none"
                        stroke="#e0e0e0"
                        strokeWidth="4"
                      />
                    </svg>
                  </div>
                )}
              </div>
              <div className="story-circle-label">
                {user.name || "User"}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default StoriesFeed;

