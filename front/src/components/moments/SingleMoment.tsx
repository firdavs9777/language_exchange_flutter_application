import moment from "moment";
import React, { useCallback, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  AiFillLike,
  AiOutlineComment,
  AiOutlineLike,
} from "react-icons/ai";
import { HiDotsHorizontal } from "react-icons/hi";
import { Bookmark, Heart, Smile } from "lucide-react";
import { useSelector } from "react-redux";
import { Link, useNavigate } from "react-router-dom";
import { Bounce, toast } from "react-toastify";
import {
  useDislikeMomentMutation,
  useLikeMomentMutation,
  useReactToMomentMutation,
  useUnreactToMomentMutation,
  useShareMomentMutation,
  useSaveMomentMutation,
  useUnsaveMomentMutation,
} from "../../store/slices/momentsSlice";
import MomentReactionRow from "./actions/MomentReactionRow";
import ShareButton from "../linking/ShareButton";
import MomentVideoPlayer from "./media/MomentVideoPlayer";
import VoiceNotePlayer from "./media/VoiceNotePlayer";
import GradientMomentCard from "./media/GradientMomentCard";

// TypeScript interfaces
interface User {
  _id: string;
  name: string;
  imageUrls?: string[];
}

interface MomentProps {
  _id: string;
  title: string;
  description: string;
  likeCount: number;
  likedUsers: string[];
  commentCount: any[] | number; // Updated to handle both array and number
  createdAt: string;
  user: User;
  imageUrls?: string[];
  refetch?: () => void;
  // Package 3 engagement (optional — feed card renders gracefully without them)
  reactions?: Array<{ user: string | { _id: string }; emoji: string }>;
  reactionCount?: number;
  shareCount?: number;
  isSaved?: boolean;
  saveCount?: number;
  // Package 3 media variants (optional — falls back to images when absent)
  mediaType?: "image" | "video" | "audio" | "text";
  video?: {
    url: string;
    thumbnail?: string;
    duration?: number;
    width?: number;
    height?: number;
  };
  audio?: { url: string; duration: number; waveform: number[] };
  backgroundColor?: string;
}

interface AuthState {
  userInfo?: {
    user: {
      _id: string;
    };
  };
}

interface RootState {
  auth: AuthState;
}

const SingleMoment: React.FC<MomentProps> = ({
  _id,
  title,
  description,
  likeCount,
  likedUsers,
  createdAt,
  user,
  commentCount,
  imageUrls,
  refetch,
  reactions,
  shareCount = 0,
  isSaved = false,
  mediaType,
  video,
  audio,
  backgroundColor,
}) => {
  const userId = useSelector(
    (state: RootState) => state.auth.userInfo?.user?._id
  );

  // Mock mutation hooks - replace with your actual hooks
  const [likeMoment] = useLikeMomentMutation();
  const [dislikeMoment] = useDislikeMomentMutation();
  const [reactToMoment] = useReactToMomentMutation();
  const [unreactToMoment] = useUnreactToMomentMutation();
  const [shareMoment] = useShareMomentMutation();
  const [saveMoment] = useSaveMomentMutation();
  const [unsaveMoment] = useUnsaveMomentMutation();
  const isLiking = false;
  const isDisliking = false;

  const [liked, setLiked] = useState<boolean>(false);
  const [isHovered, setIsHovered] = useState<boolean>(false);
  const [currentLikeCount, setCurrentLikeCount] = useState<number>(likeCount);
  const [showFullDescription, setShowFullDescription] =
    useState<boolean>(false);
  const [showReactions, setShowReactions] = useState<boolean>(false);
  const [saved, setSaved] = useState<boolean>(isSaved);
  const [localShareCount, setLocalShareCount] = useState<number>(shareCount);
  const [showHeartBurst, setShowHeartBurst] = useState<boolean>(false);

  const navigate = useNavigate();
  const { t } = useTranslation();

  // Check if any like/dislike operation is in progress
  const isLoadingLike = isLiking || isDisliking;

  // Get comment count as number - handle both array and number formats
  const getCommentCount = useCallback((): number => {
    if (Array.isArray(commentCount)) {
      return commentCount.length;
    }
    return typeof commentCount === "number" ? commentCount : 0;
  }, [commentCount]);

  const commentCountNumber = getCommentCount();

  useEffect(() => {
    setLiked(userId ? likedUsers.includes(userId) : false);
    setCurrentLikeCount(likeCount);
  }, [likedUsers, userId, likeCount]);

  useEffect(() => {
    setSaved(isSaved);
  }, [isSaved]);

  useEffect(() => {
    setLocalShareCount(shareCount);
  }, [shareCount]);

  // Stop the surrounding card <Link> from navigating when interacting with
  // an inner control.
  const stopLink = useCallback((e: React.SyntheticEvent) => {
    e.preventDefault();
    e.stopPropagation();
  }, []);

  // Emoji reactions — "mine" = a reaction on this emoji whose user matches me
  // (user may be a string id or a populated { _id } object).
  const handleToggleReaction = useCallback(
    (emoji: string) => {
      if (!userId) return;
      const mine =
        Array.isArray(reactions) &&
        reactions.some(
          (r) =>
            r?.emoji === emoji &&
            (typeof r.user === "string" ? r.user : r.user?._id) === userId
        );
      if (mine) {
        unreactToMoment(_id).unwrap().catch(console.error);
      } else {
        reactToMoment({ momentId: _id, emoji }).unwrap().catch(console.error);
      }
    },
    [userId, reactions, _id, reactToMoment, unreactToMoment]
  );

  const handleSaveToggle = useCallback(
    (e: React.MouseEvent) => {
      stopLink(e);
      if (!userId) return;
      const next = !saved;
      setSaved(next);
      (next ? saveMoment(_id) : unsaveMoment(_id))
        .unwrap()
        .catch((err) => {
          setSaved(!next);
          console.error(err);
        });
    },
    [stopLink, userId, saved, _id, saveMoment, unsaveMoment]
  );

  const handleShareTrack = useCallback(
    (e: React.MouseEvent) => {
      stopLink(e);
      setLocalShareCount((prev) => prev + 1);
      shareMoment(_id).unwrap().catch(console.error);
    },
    [stopLink, _id, shareMoment]
  );

  // Double-tap the media to like (like only — never unlike), with a brief
  // heart-burst affordance.
  const handleDoubleTapLike = useCallback(
    (e: React.MouseEvent) => {
      stopLink(e);
      if (!userId) return;
      setShowHeartBurst(true);
      window.setTimeout(() => setShowHeartBurst(false), 700);
      if (!liked) {
        setLiked(true);
        setCurrentLikeCount((prev) => prev + 1);
      }
      likeMoment({ momentId: _id, userId }).unwrap().catch(console.error);
    },
    [stopLink, userId, liked, _id, likeMoment]
  );

  const handleLikeToggle = useCallback(
    async (e: React.MouseEvent) => {
      e.preventDefault();
      e.stopPropagation();

      if (!userId) {
        toast.error("Please login to like posts", {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "colored",
          transition: Bounce,
        });
        navigate("/login");
        return;
      }

      if (isLoadingLike) return;

      const previousLiked = liked;
      const previousCount = currentLikeCount;

      setLiked(!liked);
      setCurrentLikeCount((prev) => (liked ? prev - 1 : prev + 1));

      try {
        if (liked) {
          await dislikeMoment({ momentId: _id, userId }).unwrap();
        } else {
          await likeMoment({ momentId: _id, userId }).unwrap();
        }

        // if (refetch) refetch();
      } catch (error) {
        setLiked(previousLiked);
        setCurrentLikeCount(previousCount);
        toast.error("Something went wrong", {
          autoClose: 3000,
          theme: "colored",
          transition: Bounce,
        });
        console.error("Like/unlike error:", error);
      }
    },
    [userId, _id, currentLikeCount, isLoadingLike, navigate, refetch]
  );

  const formatDate = (dateString: string): string => {
    return moment(dateString).fromNow();
  };

  const toggleDescription = useCallback(() => {
    setShowFullDescription(!showFullDescription);
  }, [showFullDescription]);

  const defaultProfileImage =
    "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face";

  // Handle user profile navigation without triggering parent Link
  const handleUserClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (user?._id) {
      navigate(`/community/${user._id}`);
    }
  };

  // Return null if user data is missing
  if (!user) {
    return null;
  }

  const shouldTruncateDescription = description?.length > 200;
  const displayDescription =
    shouldTruncateDescription && !showFullDescription
      ? description.substring(0, 200)
      : description;

  return (
    <Link to={`/moment/${_id}`} className="block no-underline">
      <article
        className={`group relative w-full bg-white shadow-sm border border-gray-200 transition-all duration-300 hover:shadow-md ${
          isHovered ? "shadow-md" : ""
        } rounded-none sm:rounded-lg`}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        {/* Header */}
        <header className="p-2 xs:p-3 sm:p-4 md:p-5">
          <div className="flex items-center justify-between gap-2">
            <div
              onClick={handleUserClick}
              className="flex items-center flex-1 min-w-0 group/user no-underline cursor-pointer"
            >
              <div className="relative flex-shrink-0">
                <img
                  src={user?.imageUrls?.[0] || defaultProfileImage}
                  alt={user?.name || "User"}
                  className="w-8 h-8 xs:w-10 xs:h-10 sm:w-12 sm:h-12 md:w-14 md:h-14 rounded-full object-cover border-2 border-transparent group-hover/user:border-blue-100 transition-all duration-200"
                />
              </div>

              <div className="ml-2 xs:ml-3 flex-1 min-w-0">
                <div className="flex items-center gap-1 xs:gap-2">
                  <h3 className="font-semibold text-gray-900 text-xs xs:text-sm sm:text-base md:text-lg truncate group-hover/user:text-blue-600 transition-colors no-underline">
                    {user?.name}
                  </h3>
                </div>
                <div className="flex items-center gap-1 text-xs sm:text-sm text-gray-500 mt-0.5">
                  <time className="truncate">{formatDate(createdAt)}</time>
                  <span className="hidden xs:inline">•</span>
                  <svg
                    className="w-3 h-3 text-gray-400 hidden xs:block"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 2C5.58 2 2 5.58 2 10s3.58 8 8 8 8-3.58 8-8-3.58-8-8-8zM9 9V6h2v3h3v2H9z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
              </div>
            </div>

            <button
              className="flex-shrink-0 p-1 xs:p-2 -mr-1 xs:-mr-2 rounded-full hover:bg-gray-100 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-200"
              aria-label="More options"
            >
              <HiDotsHorizontal className="w-4 h-4 xs:w-5 xs:h-5 text-gray-500" />
            </button>
          </div>
        </header>

        {/* Content */}
        <div className="px-2 xs:px-3 sm:px-4 md:px-5">
          {/* Text Content */}
          {title && (
            <h2 className="font-semibold text-gray-900 text-sm xs:text-base sm:text-lg md:text-xl lg:text-2xl mb-1 xs:mb-2 leading-tight no-underline decoration-none">
              {title}
            </h2>
          )}

          {description && (
            <div className="text-gray-800 text-xs xs:text-sm sm:text-base md:text-lg leading-normal">
              <p className="whitespace-pre-wrap break-words no-underline">
                {displayDescription}
                {shouldTruncateDescription && !showFullDescription && "..."}
              </p>

              {shouldTruncateDescription && (
                <button
                  onClick={toggleDescription}
                  className="text-blue-600 hover:text-blue-700 font-medium text-xs xs:text-sm mt-1 focus:outline-none focus:underline"
                >
                  {showFullDescription ? "See less" : "See more"}
                </button>
              )}
            </div>
          )}
        </div>

        {/* Media — precedence: video → audio → text/gradient → images */}
        {video?.url ? (
          <div className="mt-2 xs:mt-3 px-2 xs:px-3 sm:px-4 md:px-5">
            <div className="relative" onDoubleClick={handleDoubleTapLike}>
              <MomentVideoPlayer video={video} />
              {showHeartBurst && (
                <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                  <Heart className="w-20 h-20 text-white fill-white drop-shadow-lg animate-ping" />
                </div>
              )}
            </div>
          </div>
        ) : audio?.url ? (
          <div className="mt-2 xs:mt-3 px-2 xs:px-3 sm:px-4 md:px-5">
            <VoiceNotePlayer audio={audio} />
          </div>
        ) : mediaType === "text" ||
          (backgroundColor && !(imageUrls && imageUrls.length > 0)) ? (
          <div className="mt-2 xs:mt-3 px-2 xs:px-3 sm:px-4 md:px-5">
            <GradientMomentCard
              text={description}
              backgroundColor={backgroundColor}
            />
          </div>
        ) : imageUrls && imageUrls.length > 0 ? (
          <div className="mt-2 xs:mt-3">
            <div
              className="relative overflow-hidden bg-gray-100"
              onDoubleClick={handleDoubleTapLike}
            >
              <img
                src={imageUrls[0]}
                alt={title || "Post image"}
                className="w-full h-auto max-h-64 xs:max-h-80 sm:max-h-96 md:max-h-[450px] lg:max-h-[500px] xl:max-h-[600px] object-cover transition-transform duration-300 group-hover:scale-[1.01]"
                loading="lazy"
              />

              {showHeartBurst && (
                <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                  <Heart className="w-20 h-20 text-white fill-white drop-shadow-lg animate-ping" />
                </div>
              )}

              {imageUrls.length > 1 && (
                <div className="absolute top-2 xs:top-3 right-2 xs:right-3">
                  <div className="bg-black/70 text-white px-1.5 xs:px-2 py-0.5 xs:py-1 rounded-full text-xs font-medium backdrop-blur-sm">
                    +{imageUrls.length - 1}
                  </div>
                </div>
              )}
            </div>
          </div>
        ) : null}

        {/* Engagement Stats */}
        {(currentLikeCount > 0 || commentCountNumber > 0) && (
          <div className="px-2 xs:px-3 sm:px-4 md:px-5 py-1.5 xs:py-2 border-b border-gray-100">
            <div className="flex items-center justify-between text-xs xs:text-sm text-gray-500">
              <div className="flex items-center gap-2 xs:gap-3">
                {currentLikeCount > 0 && (
                  <button className="flex items-center gap-1 hover:text-blue-600 transition-colors no-underline">
                    <div className="w-3 h-3 xs:w-4 xs:h-4 bg-blue-500 rounded-full flex items-center justify-center">
                      <AiFillLike className="w-2 h-2 xs:w-2.5 xs:h-2.5 text-white" />
                    </div>
                    <span className="font-medium">
                      {currentLikeCount.toLocaleString()}
                    </span>
                  </button>
                )}
              </div>

              <div className="flex items-center gap-2 xs:gap-3">
                {commentCountNumber > 0 && (
                  <span className="hover:text-blue-600 transition-colors font-medium">
                    {commentCountNumber.toLocaleString()} comment
                    {commentCountNumber !== 1 ? "s" : ""}
                  </span>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Reactions + Save bar */}
        <div
          className="flex items-center justify-between gap-2 px-2 xs:px-3 sm:px-4 md:px-5 py-1.5 border-t border-gray-100"
          onClick={stopLink}
        >
          <div className="flex items-center gap-1 min-w-0">
            <button
              type="button"
              onClick={(e) => {
                stopLink(e);
                setShowReactions((v) => !v);
              }}
              aria-label="React"
              aria-expanded={showReactions}
              className="flex-shrink-0 rounded-full p-1 text-gray-500 hover:bg-gray-100 hover:text-blue-600 dark:hover:bg-gray-700 transition-colors"
            >
              <Smile className="w-4 h-4 xs:w-5 xs:h-5" />
            </button>
            {userId && (
              <MomentReactionRow
                reactions={reactions}
                myUserId={userId}
                onToggle={handleToggleReaction}
                showQuickPick={showReactions}
              />
            )}
          </div>

          <button
            type="button"
            onClick={handleSaveToggle}
            aria-pressed={saved}
            aria-label={saved ? "Remove bookmark" : "Bookmark"}
            className={`flex-shrink-0 rounded-full p-1 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700 ${
              saved ? "text-blue-600" : "text-gray-500 hover:text-blue-600"
            }`}
          >
            <Bookmark
              className={`w-4 h-4 xs:w-5 xs:h-5 ${saved ? "fill-current" : ""}`}
            />
          </button>
        </div>

        {/* Action Buttons */}
        <div className="grid grid-cols-3 border-t border-gray-100">
          {/* Like Button */}
          <button
            onClick={handleLikeToggle}
            disabled={isLoadingLike}
            className={`flex items-center justify-center py-2 xs:py-2.5 sm:py-3 transition-all duration-200 hover:bg-gray-50 focus:outline-none focus:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed ${
              liked ? "text-blue-600" : "text-gray-600"
            }`}
            aria-label={liked ? "Unlike" : "Like"}
          >
            <div
              className={`flex items-center gap-1 xs:gap-2 ${
                isLoadingLike ? "animate-pulse" : ""
              }`}
            >
              {liked ? (
                <AiFillLike className="w-4 h-4 xs:w-5 xs:h-5 transition-transform hover:scale-110" />
              ) : (
                <AiOutlineLike className="w-4 h-4 xs:w-5 xs:h-5 transition-transform hover:scale-110" />
              )}
              <span className="font-medium text-xs xs:text-sm hidden sm:inline">
                {isLoadingLike ? (liked ? "Unliking..." : "Liking...") : "Like"}
              </span>
            </div>
          </button>

          {/* Comment Button */}
          <div
            className="flex items-center justify-center py-2 xs:py-2.5 sm:py-3 text-gray-600 hover:text-blue-600 hover:bg-gray-50 transition-all duration-200 focus:outline-none focus:bg-gray-50 cursor-pointer"
            aria-label="Comment"
          >
            <div className="flex items-center gap-1 xs:gap-2">
              <AiOutlineComment className="w-4 h-4 xs:w-5 xs:h-5 transition-transform hover:scale-110" />
              <span className="font-medium text-xs xs:text-sm hidden sm:inline">
                Comment
              </span>
            </div>
          </div>

          {/* Share Button — ShareButton does the OS/clipboard share; the
              wrapper click also records a share (shareCount). */}
          <span
            onClick={handleShareTrack}
            className="flex items-center justify-center gap-1 py-2 xs:py-2.5 sm:py-3 text-gray-600 hover:text-blue-600 hover:bg-gray-50 transition-all duration-200 cursor-pointer"
          >
            <ShareButton
              type="moment"
              id={_id}
              title={title}
              text={description}
              className="flex items-center gap-1 xs:gap-2 font-medium text-xs xs:text-sm"
            />
            {localShareCount > 0 && (
              <span className="text-xs font-medium">{localShareCount}</span>
            )}
          </span>
        </div>
      </article>
    </Link>
  );
};

export default React.memo(SingleMoment);
