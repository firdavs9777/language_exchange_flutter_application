import { useCallback, useMemo } from "react";
import { useSelector } from "react-redux";
import { useGetUserProfileQuery } from "../../store/slices/usersSlice";
import { useGetPublicUserProfileQuery } from "../../store/slices/communitySlice";
import { useGetMyMomentsQuery } from "../../store/slices/momentsSlice";

export interface ProfileStatsData {
  followers: number;
  following: number;
  moments: number;
}

export interface ProfileData {
  /** The profile belongs to the signed-in user. */
  isOwn: boolean;
  /** The raw user document, `undefined` until it arrives. */
  user: any;
  stats: ProfileStatsData;
  /** The viewer follows this person. Always false on an own profile. */
  isFollowing: boolean;
  loading: boolean;
  error: any;
  refetch: () => void;
}

/**
 * `followers` / `following` come back as an array of ids from
 * `USER_PUBLIC_FIELDS`, but a populated list of user objects from some code
 * paths and a plain number from none of them today — so all three are handled
 * rather than assumed.
 */
function countOf(value: any): number {
  if (Array.isArray(value)) return value.length;
  if (typeof value === "number" && isFinite(value)) return value;
  return 0;
}

/**
 * A follower/following figure from whatever the endpoint sent. Signed-in
 * readers get the id lists (isFollowing needs them); signed-out readers of
 * /:id/public get `followersCount` / `followingCount` instead (backend
 * P1-PRIV-1 drops the lists for anonymous viewers). The list wins when both
 * are there; a server from before that change sends lists to everyone.
 */
function statOf(list: any, count: any): number {
  if (Array.isArray(list)) return list.length;
  return countOf(count);
}

function idOf(entry: any): string {
  if (!entry) return "";
  if (typeof entry === "string") return entry;
  return String(entry._id || entry.id || "");
}

/**
 * Everything the profile page needs about one person, own or other.
 *
 * Own profiles read `/auth/me` (the whole user document — `isEmailVerified`
 * and `learningStats` only exist here); other people read the PUBLIC
 * `/auth/users/:id/public`, never the protected `/auth/users/:id`. The route
 * `/profile/:userId` is public: the protected endpoint 401s for an anonymous
 * visitor, so every shared profile link would break, and it skips the privacy
 * redaction `getUserPublic` applies (age, city/country, online status and
 * gifting level are dropped when the owner turned them off). Both endpoints
 * return `{ success, data }`, so a single parser covers them.
 *
 * Follow state is derived from the target's own `followers` array rather than
 * from a second request: the array is already in the response, and a separate
 * source would let the badge and the button disagree.
 */
export default function useProfileData(userId?: string): ProfileData {
  const viewerId = useSelector(
    (state: any) => state.auth.userInfo?.user?._id || state.auth.userInfo?._id
  );

  const isOwn = !userId || userId === viewerId;
  const profileUserId = isOwn ? viewerId : userId;

  const own = useGetUserProfileQuery({}, { skip: !isOwn || !viewerId });
  const other = useGetPublicUserProfileQuery(userId || "", { skip: isOwn || !userId });
  const moments = useGetMyMomentsQuery(
    { userId: profileUserId || "" },
    { skip: !profileUserId }
  );

  const active: any = isOwn ? own : other;
  const user = (active.data && (active.data.data || active.data.user)) || undefined;

  const ownRefetch = own.refetch;
  const otherRefetch = other.refetch;
  const momentsRefetch = moments.refetch;
  const refetch = useCallback(() => {
    if (isOwn) {
      if (ownRefetch) ownRefetch();
    } else if (otherRefetch) {
      otherRefetch();
    }
    if (momentsRefetch) momentsRefetch();
  }, [isOwn, ownRefetch, otherRefetch, momentsRefetch]);

  const momentsData: any = moments.data;
  const momentCount = useMemo(() => {
    if (!momentsData) return 0;
    if (typeof momentsData.totalMoments === "number") return momentsData.totalMoments;
    if (typeof momentsData.count === "number") return momentsData.count;
    return Array.isArray(momentsData.data) ? momentsData.data.length : 0;
  }, [momentsData]);

  const stats = useMemo<ProfileStatsData>(
    () => ({
      followers: statOf(user && user.followers, user && user.followersCount),
      following: statOf(user && user.following, user && user.followingCount),
      moments: momentCount,
    }),
    [user, momentCount]
  );

  const isFollowing = useMemo(() => {
    if (isOwn || !viewerId || !user || !Array.isArray(user.followers)) return false;
    return user.followers.some((entry: any) => idOf(entry) === viewerId);
  }, [isOwn, viewerId, user]);

  return useMemo(
    () => ({
      isOwn,
      user,
      stats,
      isFollowing,
      loading: Boolean(active.isLoading),
      error: active.error,
      refetch,
    }),
    [isOwn, user, stats, isFollowing, active.isLoading, active.error, refetch]
  );
}
