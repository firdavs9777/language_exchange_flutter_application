import React from "react";
import {
  useFollowUserMutation,
  useUnFollowUserMutation,
} from "../store/slices/usersSlice";

export interface FollowButtonProps {
  /** The viewer. Both mutations take { userId, targetUserId }. */
  userId: string;
  /** The person being followed. */
  targetUserId: string;
  /**
   * Current follow state, owned by the caller and read from the RTK Query
   * cache -- NOT local state. Two cards by the same author in one feed would
   * otherwise disagree after a tap.
   */
  isFollowing: boolean;
  onToggled?: (nowFollowing: boolean) => void;
}

const FollowButton: React.FC<FollowButtonProps> = ({
  userId,
  targetUserId,
  isFollowing,
  onToggled,
}) => {
  const [followUser, { isLoading: isFollowLoading }] = useFollowUserMutation();
  const [unFollowUser, { isLoading: isUnfollowLoading }] =
    useUnFollowUserMutation();
  const busy = isFollowLoading || isUnfollowLoading;

  const handleClick = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (busy) return;
    try {
      if (isFollowing) await unFollowUser({ userId, targetUserId }).unwrap();
      else await followUser({ userId, targetUserId }).unwrap();
      onToggled?.(!isFollowing);
    } catch {
      // This primitive deliberately leaves error UX to its caller -- it does
      // not toast or surface a message itself. Nothing in this codebase
      // handles the error on its behalf either: src/store/index.ts registers
      // only apiSlice.middleware, with no RTK-Query error-logging middleware,
      // and the existing consumer (CommunityDetail.tsx) does its own
      // toast.error(...) around its own call to these mutations. So a failed
      // mutation here is swallowed silently: no toast, no onToggled call: the
      // button simply stays showing the isFollowing state the caller passed
      // in, unchanged.
    }
  };

  return (
    <button
      type="button"
      data-testid="follow-button"
      onClick={handleClick}
      disabled={busy}
      aria-pressed={isFollowing}
      className={`rounded-full border px-3 py-1 text-xs font-bold transition-colors disabled:opacity-60 ${
        isFollowing
          ? "border-gray-300 text-gray-600 dark:border-gray-600 dark:text-gray-300"
          : "border-brand text-brand-dark hover:bg-brand/[0.08] dark:text-brand-light"
      }`}
    >
      {isFollowing ? "Following" : "Follow"}
    </button>
  );
};

export default FollowButton;
