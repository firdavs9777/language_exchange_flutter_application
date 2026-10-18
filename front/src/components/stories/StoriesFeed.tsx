import React, { useMemo } from "react";
import { useGetStoryFeedsQuery, useGetMyStoriesQuery } from "../../store/slices/storiesSlice";
import { useSelector } from "react-redux";
import { Link, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Plus } from "lucide-react";
import Avatar from "../../design/Avatar";
import { StoryFeedUser, Story } from "./types";
import { userAvatarUrl } from "../../utils/photoUrl";

/**
 * The ring row, and deliberately nothing else.
 *
 * This is the ONE stories module on the eager path: `/moments` is prerendered
 * and imports it statically, so every byte here is downloaded by a visitor who
 * may never open a story. Everything a ring leads to -- the viewer, the
 * composer, My stories, highlights -- is a lazy route
 * (`src/router/routes.tsx`), and `src/seo/eagerGraph.test.ts` fails if
 * `StoryViewer.tsx` ever becomes statically reachable from here.
 *
 * So: no SCSS (the old file carried 220 lines and two inline SVG gradient
 * rings for what four Tailwind classes draw), no icon font, and the avatar is
 * the design system's `Avatar` -- which also retires the ui-avatars.com
 * placeholder URLs this used to build by hand, one third-party request per
 * ring on a prerendered page, for initials we can draw ourselves.
 */

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

/** The ring itself: a 2.5px collar behind the avatar. */
const RING = "relative rounded-full border-0 p-[2.5px] transition-transform duration-200 hover:scale-105";
const RING_LIVE = "bg-gradient-to-tr from-brand via-banana to-brand-light";
const RING_SEEN = "bg-line-strong dark:bg-line-dark";
const LABEL =
  "max-w-[70px] truncate text-center text-[11px] font-medium text-ink-600 dark:text-ink-300";
const COLUMN = "flex w-[74px] shrink-0 flex-col items-center gap-1.5";

const StoriesFeed: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userId = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?._id || state.auth.userInfo?.data?._id || null
  );
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);

  const { data: feedData, isLoading: isLoadingFeed } = useGetStoryFeedsQuery();
  const { data: myStoriesData, isLoading: isLoadingMy } = useGetMyStoriesQuery(
    {},
    { skip: !userId }
  );

  const me = useMemo(() => {
    const user = (userInfo as any)?.user || (userInfo as any)?.data;
    return {
      name: (user && user.name) || "User",
      image: user && user.imageUrls && user.imageUrls[0],
    };
  }, [userInfo]);

  const storyFeed = useMemo(() => {
    if (!feedData) return [];
    const response = feedData as { success?: boolean; data?: StoryFeedUser[] };
    return response.data || [];
  }, [feedData]);

  const myStories = useMemo(() => {
    if (!myStoriesData) return [];
    const response = myStoriesData as { success?: boolean; data?: Story[] };
    return Array.isArray(response) ? response : response.data || [];
  }, [myStoriesData]);

  const openAuthor = (authorId: string) => {
    navigate(`/stories/${authorId}`, { state: { startIndex: 0 } });
  };

  if (isLoadingFeed || isLoadingMy) {
    return (
      <div className="mb-4 flex gap-4 overflow-x-auto py-2" data-testid="stories-feed-loading">
        {[0, 1, 2, 3].map((n) => (
          <div key={n} className={COLUMN}>
            <div className="h-[59px] w-[59px] animate-pulse rounded-full bg-ink-100 dark:bg-ink-800" />
            <div className="h-2 w-12 animate-pulse rounded-full bg-ink-100 dark:bg-ink-800" />
          </div>
        ))}
      </div>
    );
  }

  const hasMine = myStories.length > 0;

  return (
    <div className="mb-4 flex gap-4 overflow-x-auto py-2" data-testid="stories-feed">
      {/* The author's own ring: their stories if they have any, the composer
          if they do not. */}
      <div className={COLUMN}>
        <button
          type="button"
          data-testid="my-story-ring"
          aria-label={
            hasMine
              ? t("stories.your_story") || "Your Story"
              : t("stories.create_story") || "Create"
          }
          onClick={() => (hasMine && userId ? openAuthor(userId) : navigate("/create-story"))}
          className={`${RING} ${hasMine ? RING_LIVE : RING_SEEN}`}
        >
          <Avatar src={me.image} name={me.name} size={54} />
          {!hasMine && (
            <span className="absolute bottom-0 right-0 flex h-5 w-5 items-center justify-center rounded-full border-2 border-surface bg-brand-deep text-surface dark:border-cardbg-dark">
              <Plus size={12} aria-hidden />
            </span>
          )}
        </button>
        <span className={LABEL}>
          {hasMine
            ? t("stories.your_story") || "Your Story"
            : t("stories.create_story") || "Create"}
        </span>
        {/* The only way into the author's own stories, highlights picker and
            archive. A <Link>, not a navigate() button: this row is in the
            eagerly-loaded /moments chunk, so it takes no new import beyond
            the one react-router already ships here. */}
        {userId && (
          <Link
            data-testid="my-stories-link"
            to="/stories/mine"
            className="block text-[11px] font-medium text-ink-500 no-underline hover:underline dark:text-ink-400"
          >
            {t("stories.my_stories") || "My stories"}
          </Link>
        )}
      </div>

      {storyFeed.map((feedUser: StoryFeedUser) => {
        const user = feedUser.user || feedUser;
        const authorId = user._id || feedUser._id;
        const unviewed = (feedUser.hasUnviewed || 0) > 0;

        return (
          <div key={authorId} className={COLUMN}>
            <button
              type="button"
              data-testid={`story-ring-${authorId}`}
              aria-label={user.name || "User"}
              onClick={() => openAuthor(authorId)}
              className={`${RING} ${unviewed ? RING_LIVE : RING_SEEN}`}
            >
              <Avatar
                src={userAvatarUrl(user)}
                name={user.name || "User"}
                size={54}
              />
            </button>
            <span className={LABEL}>{user.name || "User"}</span>
          </div>
        );
      })}
    </div>
  );
};

export default StoriesFeed;
