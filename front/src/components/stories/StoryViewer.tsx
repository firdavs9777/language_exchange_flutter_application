import React, { useState, useEffect, useRef, useCallback, useMemo } from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import { useSelector } from "react-redux";
import {
  useGetUserStoriesQuery,
  useMarkIndividualStoryViewedMutation,
  useReactToStoryMutation,
  useRemoveStoryReactionMutation,
  useReplyToStoryMutation,
  useVoteOnPollMutation,
  useDeleteIndividualStoryMutation,
} from "../../store/slices/storiesSlice";
import { useTranslation } from "react-i18next";
import {
  FaTimes,
  FaChevronLeft,
  FaChevronRight,
  FaHeart,
  FaComment,
  FaShare,
  FaEllipsisH,
  FaTrash,
} from "react-icons/fa";
import { Story, STORY_REACTIONS } from "./types";
import "./StoryViewer.scss";

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

const StoryViewer: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  const location = useLocation();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const startIndex = (location.state as any)?.startIndex || 0;

  const currentUserId = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?._id || state.auth.userInfo?.data?._id || null
  );

  const [currentStoryIndex, setCurrentStoryIndex] = useState(startIndex);
  const [progress, setProgress] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const [showReactions, setShowReactions] = useState(false);
  const [replyText, setReplyText] = useState("");
  const [showReplyInput, setShowReplyInput] = useState(false);
  const [userReaction, setUserReaction] = useState<string | null>(null);
  const [showMenu, setShowMenu] = useState(false);

  const progressIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const storyRef = useRef<HTMLDivElement>(null);

  // Fetch user's stories
  const {
    data: storiesData,
    isLoading,
    error,
  } = useGetUserStoriesQuery(userId || "", { skip: !userId });

  const [markViewed] = useMarkIndividualStoryViewedMutation();
  const [reactToStory] = useReactToStoryMutation();
  const [removeReaction] = useRemoveStoryReactionMutation();
  const [replyToStory] = useReplyToStoryMutation();
  const [voteOnPoll] = useVoteOnPollMutation();
  const [deleteStory] = useDeleteIndividualStoryMutation();

  const stories = useMemo(() => {
    if (!storiesData) return [];
    const response = storiesData as { success?: boolean; data?: Story[]; count?: number };
    return Array.isArray(response) ? response : response.data || [];
  }, [storiesData]);

  const currentStory = stories[currentStoryIndex];
  const isOwner = currentStory?.user._id === currentUserId;

  // Progress bar animation
  useEffect(() => {
    if (!currentStory || isPaused || currentStory.mediaType === "text") {
      if (progressIntervalRef.current) {
        clearInterval(progressIntervalRef.current);
      }
      return;
    }

    const duration = 5000; // 5 seconds per story
    const interval = 100; // Update every 100ms
    const increment = (interval / duration) * 100;

    progressIntervalRef.current = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          handleNextStory();
          return 0;
        }
        return prev + increment;
      });
    }, interval);

    return () => {
      if (progressIntervalRef.current) {
        clearInterval(progressIntervalRef.current);
      }
    };
  }, [currentStory, isPaused]);

  // Mark story as viewed
  useEffect(() => {
    if (currentStory && !isOwner) {
      markViewed({
        storyId: currentStory._id,
        viewDuration: 5,
      });
    }
  }, [currentStory?._id, isOwner]);

  // Check user's reaction
  useEffect(() => {
    if (currentStory && currentUserId) {
      const reaction = currentStory.reactions.find(
        (r) => r.user._id === currentUserId
      );
      setUserReaction(reaction?.emoji || null);
    } else {
      setUserReaction(null);
    }
  }, [currentStory, currentUserId]);

  const handleNextStory = useCallback(() => {
    if (currentStoryIndex < stories.length - 1) {
      setCurrentStoryIndex(currentStoryIndex + 1);
      setProgress(0);
    } else {
      handleClose();
    }
  }, [currentStoryIndex, stories.length]);

  const handlePrevStory = useCallback(() => {
    if (currentStoryIndex > 0) {
      setCurrentStoryIndex(currentStoryIndex - 1);
      setProgress(0);
    }
  }, [currentStoryIndex]);

  const handleClose = () => {
    navigate("/stories");
  };

  const handleReaction = async (emoji: string) => {
    if (!currentStory) return;

    if (userReaction === emoji) {
      // Remove reaction
      try {
        await removeReaction(currentStory._id).unwrap();
        setUserReaction(null);
      } catch (error) {
        console.error("Failed to remove reaction:", error);
      }
    } else {
      // Add reaction
      try {
        await reactToStory({ storyId: currentStory._id, emoji }).unwrap();
        setUserReaction(emoji);
      } catch (error) {
        console.error("Failed to add reaction:", error);
      }
    }
    setShowReactions(false);
  };

  const handleReply = async () => {
    if (!currentStory || !replyText.trim()) return;

    try {
      await replyToStory({
        storyId: currentStory._id,
        message: replyText,
      }).unwrap();
      setReplyText("");
      setShowReplyInput(false);
    } catch (error) {
      console.error("Failed to send reply:", error);
    }
  };

  const handlePollVote = async (optionIndex: number) => {
    if (!currentStory?.poll) return;

    try {
      await voteOnPoll({
        storyId: currentStory._id,
        optionIndex,
      }).unwrap();
    } catch (error) {
      console.error("Failed to vote:", error);
    }
  };

  const handleDeleteStory = async () => {
    if (!currentStory || !isOwner) return;

    if (window.confirm(t("stories.delete_story") || "Delete this story?")) {
      try {
        await deleteStory(currentStory._id).unwrap();
        if (stories.length === 1) {
          handleClose();
        } else {
          handleNextStory();
        }
      } catch (error) {
        console.error("Failed to delete story:", error);
      }
    }
    setShowMenu(false);
  };

  const handleKeyPress = (e: KeyboardEvent) => {
    if (e.key === "ArrowLeft") handlePrevStory();
    if (e.key === "ArrowRight") handleNextStory();
    if (e.key === "Escape") handleClose();
  };

  useEffect(() => {
    window.addEventListener("keydown", handleKeyPress as any);
    return () => window.removeEventListener("keydown", handleKeyPress as any);
  }, [currentStoryIndex, stories.length]);

  if (isLoading) {
    return (
      <div className="story-viewer">
        <div className="story-viewer-loading">
          <div className="spinner"></div>
        </div>
      </div>
    );
  }

  if (error || !stories.length || !currentStory) {
    return (
      <div className="story-viewer">
        <div className="story-viewer-error">
          <button className="close-btn" onClick={handleClose}>
            <FaTimes />
          </button>
          <p>{t("stories.error_loading") || "Error loading story"}</p>
        </div>
      </div>
    );
  }

  const userImage =
    currentStory.user.imageUrls?.[0] ||
    currentStory.user.images?.[0] ||
    `https://ui-avatars.com/api/?name=${encodeURIComponent(currentStory.user.name)}&background=667eea&color=fff&size=200`;

  return (
    <div
      className="story-viewer"
      ref={storyRef}
      onMouseDown={() => setIsPaused(true)}
      onMouseUp={() => setIsPaused(false)}
      onTouchStart={() => setIsPaused(true)}
      onTouchEnd={() => setIsPaused(false)}
    >
      {/* Progress Bars */}
      <div className="story-progress-bars">
        {stories.map((_, index) => (
          <div key={index} className="progress-bar-container">
            <div
              className={`progress-bar ${
                index < currentStoryIndex ? "completed" : ""
              }`}
              style={{
                width:
                  index === currentStoryIndex
                    ? `${progress}%`
                    : index < currentStoryIndex
                    ? "100%"
                    : "0%",
              }}
            />
          </div>
        ))}
      </div>

      {/* Header */}
      <div className="story-header">
        <div className="story-user-info">
          <img src={userImage} alt={currentStory.user.name} />
          <span>{currentStory.user.name}</span>
          <span className="story-time">
            {new Date(currentStory.createdAt).toLocaleTimeString([], {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </span>
        </div>
        <div className="story-header-actions">
          {isOwner && (
            <button
              className="menu-btn"
              onClick={() => setShowMenu(!showMenu)}
            >
              <FaEllipsisH />
            </button>
          )}
          <button className="close-btn" onClick={handleClose}>
            <FaTimes />
          </button>
        </div>
      </div>

      {/* Story Content */}
      <div className="story-content">
        {currentStory.mediaType === "text" ? (
          <div
            className="story-text"
            style={{
              backgroundColor: currentStory.backgroundColor || "#000",
              color: currentStory.textColor || "#fff",
            }}
          >
            <p>{currentStory.text}</p>
          </div>
        ) : (
          <img
            src={currentStory.mediaUrls[0] || currentStory.mediaUrl}
            alt="Story"
            className="story-media"
          />
        )}

        {/* Poll Overlay */}
        {currentStory.poll && (
          <div className="story-poll-overlay">
            <h3>{currentStory.poll.question}</h3>
            {currentStory.poll.options.map((option, index) => {
              const percentage = currentStory.poll!.options.reduce(
                (sum, opt) => sum + opt.voteCount,
                0
              ) > 0
                ? (option.voteCount /
                    currentStory.poll!.options.reduce(
                      (sum, opt) => sum + opt.voteCount,
                      0
                    )) *
                  100
                : 0;
              const hasVoted = option.votes.includes(currentUserId || "");

              return (
                <button
                  key={index}
                  className={`poll-option ${hasVoted ? "voted" : ""}`}
                  onClick={() => !hasVoted && handlePollVote(index)}
                  disabled={hasVoted}
                >
                  <span>{option.text}</span>
                  {hasVoted && (
                    <span className="poll-percentage">{percentage.toFixed(0)}%</span>
                  )}
                  {hasVoted && (
                    <div
                      className="poll-progress"
                      style={{ width: `${percentage}%` }}
                    />
                  )}
                </button>
              );
            })}
          </div>
        )}

        {/* Question Box Overlay */}
        {currentStory.questionBox && !isOwner && (
          <div className="story-question-overlay">
            <p>{currentStory.questionBox.prompt}</p>
            <button onClick={() => setShowReplyInput(true)}>
              {t("stories.answer_question") || "Answer Question"}
            </button>
          </div>
        )}

        {/* Link Sticker */}
        {currentStory.link && (
          <div className="story-link-overlay">
            <button
              className="link-sticker"
              onClick={() => window.open(currentStory.link!.url, "_blank")}
            >
              <span>{currentStory.link.displayText}</span>
            </button>
          </div>
        )}
      </div>

      {/* Navigation */}
      <div className="story-navigation">
        <button
          className="nav-btn prev"
          onClick={handlePrevStory}
          disabled={currentStoryIndex === 0}
        >
          <FaChevronLeft />
        </button>
        <button
          className="nav-btn next"
          onClick={handleNextStory}
          disabled={currentStoryIndex === stories.length - 1}
        >
          <FaChevronRight />
        </button>
      </div>

      {/* Bottom Actions */}
      <div className="story-actions">
        {showReplyInput ? (
          <div className="reply-input-container">
            <input
              type="text"
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
              placeholder={t("stories.reply_placeholder") || "Send a message..."}
              onKeyPress={(e) => e.key === "Enter" && handleReply()}
              autoFocus
            />
            <button onClick={handleReply}>
              {t("stories.send_reply") || "Send"}
            </button>
            <button onClick={() => setShowReplyInput(false)}>
              <FaTimes />
            </button>
          </div>
        ) : (
          <>
            <input
              type="text"
              placeholder={t("stories.reply_placeholder") || "Send a message..."}
              onFocus={() => setShowReplyInput(true)}
              readOnly
            />
            <div className="action-buttons">
              <button
                className={`reaction-btn ${userReaction ? "active" : ""}`}
                onClick={() => setShowReactions(!showReactions)}
              >
                <FaHeart />
                {userReaction && <span className="reaction-emoji">{userReaction}</span>}
              </button>
              <button onClick={() => setShowReplyInput(true)}>
                <FaComment />
              </button>
              <button>
                <FaShare />
              </button>
            </div>
          </>
        )}

        {/* Reaction Picker */}
        {showReactions && (
          <div className="reaction-picker">
            {STORY_REACTIONS.map((emoji) => (
              <button
                key={emoji}
                className={`reaction-option ${userReaction === emoji ? "active" : ""}`}
                onClick={() => handleReaction(emoji)}
              >
                {emoji}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Menu (Owner Only) */}
      {showMenu && isOwner && (
        <div className="story-menu">
          <button onClick={handleDeleteStory}>
            <FaTrash /> {t("stories.delete_story") || "Delete Story"}
          </button>
        </div>
      )}
    </div>
  );
};

export default StoryViewer;

