import moment from "moment";
import React, { useCallback, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  AiFillLike,
  AiOutlineComment,
  AiOutlineLike,
  AiOutlineShareAlt,
} from "react-icons/ai";
import { HiDotsHorizontal } from "react-icons/hi";
import { useSelector } from "react-redux";
import { Link, useNavigate } from "react-router-dom";
import { Bounce, toast } from "react-toastify";
import {
  useDislikeMomentMutation,
  useLikeMomentMutation,
} from "../../store/slices/momentsSlice";

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
}) => {
  const userId = useSelector(
    (state: RootState) => state.auth.userInfo?.user._id
  );

  // Mock mutation hooks - replace with your actual hooks
  const [likeMoment] = useLikeMomentMutation();
  const [dislikeMoment] = useDislikeMomentMutation();
  const isLiking = false;
  const isDisliking = false;

  const [liked, setLiked] = useState<boolean>(false);
  const [isHovered, setIsHovered] = useState<boolean>(false);
  const [currentLikeCount, setCurrentLikeCount] = useState<number>(likeCount);
  const [showFullDescription, setShowFullDescription] =
    useState<boolean>(false);

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

  const handleShare = useCallback(
    (e: React.MouseEvent) => {
      e.preventDefault();
      e.stopPropagation();
      if (navigator.share) {
        navigator.share({
          title: title,
          text: description,
          url: `${window.location.origin}/moment/${_id}`,
        });
      } else {
        navigator.clipboard.writeText(
          `${window.location.origin}/moment/${_id}`
        );
        toast.success("Link copied to clipboard!", {
          autoClose: 2000,
          hideProgressBar: true,
          theme: "colored",
        });
      }
    },
    [title, description, _id]
  );
  const formatDate = (dateString: string): string => {
    return moment(dateString).fromNow();
  };

  const toggleDescription = useCallback(() => {
    setShowFullDescription(!showFullDescription);
  }, [showFullDescription]);

  const defaultProfileImage =
    "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face";

  const shouldTruncateDescription = description.length > 200;
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
            <Link
              to={`/community/${user._id}`}
              className="flex items-center flex-1 min-w-0 group/user no-underline"
            >
              <div className="relative flex-shrink-0">
                <img
                  src={user?.imageUrls?.[0] || defaultProfileImage}
                  alt={user.name}
                  className="w-8 h-8 xs:w-10 xs:h-10 sm:w-12 sm:h-12 md:w-14 md:h-14 rounded-full object-cover border-2 border-transparent group-hover/user:border-blue-100 transition-all duration-200"
                />
              </div>

              <div className="ml-2 xs:ml-3 flex-1 min-w-0">
                <div className="flex items-center gap-1 xs:gap-2">
                  <h3 className="font-semibold text-gray-900 text-xs xs:text-sm sm:text-base md:text-lg truncate group-hover/user:text-blue-600 transition-colors no-underline">
                    {user.name}
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
            </Link>

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

        {/* Images */}
        {imageUrls && imageUrls.length > 0 && (
          <div className="mt-2 xs:mt-3">
            <Link to={`/moment/${_id}`} className="block no-underline">
              <div className="relative overflow-hidden bg-gray-100">
                <img
                  src={imageUrls[0]}
                  alt={title || "Post image"}
                  className="w-full h-auto max-h-64 xs:max-h-80 sm:max-h-96 md:max-h-[450px] lg:max-h-[500px] xl:max-h-[600px] object-cover transition-transform duration-300 group-hover:scale-[1.01]"
                  loading="lazy"
                />

                {imageUrls.length > 1 && (
                  <div className="absolute top-2 xs:top-3 right-2 xs:right-3">
                    <div className="bg-black/70 text-white px-1.5 xs:px-2 py-0.5 xs:py-1 rounded-full text-xs font-medium backdrop-blur-sm">
                      +{imageUrls.length - 1}
                    </div>
                  </div>
                )}
              </div>
            </Link>
          </div>
        )}

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
                  <Link
                    to={`/moment/${_id}`}
                    className="hover:text-blue-600 transition-colors font-medium no-underline"
                  >
                    {commentCountNumber.toLocaleString()} comment
                    {commentCountNumber !== 1 ? "s" : ""}
                  </Link>
                )}
              </div>
            </div>
          </div>
        )}

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
          <Link
            to={`/moment/${_id}`}
            className="flex items-center justify-center py-2 xs:py-2.5 sm:py-3 text-gray-600 hover:text-blue-600 hover:bg-gray-50 transition-all duration-200 focus:outline-none focus:bg-gray-50 no-underline"
            aria-label="Comment"
          >
            <div className="flex items-center gap-1 xs:gap-2">
              <AiOutlineComment className="w-4 h-4 xs:w-5 xs:h-5 transition-transform hover:scale-110" />
              <span className="font-medium text-xs xs:text-sm hidden sm:inline">
                Comment
              </span>
            </div>
          </Link>

          {/* Share Button */}
          <button
            onClick={handleShare}
            className="flex items-center justify-center py-2 xs:py-2.5 sm:py-3 text-gray-600 hover:text-blue-600 hover:bg-gray-50 transition-all duration-200 focus:outline-none focus:bg-gray-50"
            aria-label="Share"
          >
            <div className="flex items-center gap-1 xs:gap-2">
              <AiOutlineShareAlt className="w-4 h-4 xs:w-5 xs:h-5 transition-transform hover:scale-110" />
              <span className="font-medium text-xs xs:text-sm hidden sm:inline">
                Share
              </span>
            </div>
          </button>
        </div>
      </article>
    </Link>
  );
};

export default React.memo(SingleMoment);
