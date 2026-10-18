import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  FaExclamationTriangle,
  FaFilter,
  FaPlus,
  FaRedo,
  FaTimes,
} from "react-icons/fa";
import { Compass, Film, PenLine, Sparkles, TrendingUp, Users, X } from "lucide-react";
import { useWebFlag } from "../../utils/webFlags";
import { useSelector } from "react-redux";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import Pagination from "../../composables/Pagination";
import {
  useGetExploreMomentsQuery,
  useGetMomentsQuery,
  useGetPromptOfDayQuery,
  useGetTrendingMomentsQuery,
} from "../../store/slices/momentsSlice";
import EmptyState from "./EmptyState";
import MomentFiltersBar from "./MomentFiltersBar";
import { isPrerendered } from "../../seo/prerender/hydrationFlag";
import { useHasHydrated } from "../../seo/prerender/useHasHydrated";
import {
  MomentFilters,
  decodeMomentFilters,
  encodeMomentFilters,
  hasMomentFilters,
  mergeMomentParams,
} from "./lib/momentFilterState";
import SingleMoment from "./SingleMoment";
import { MomentType } from "./types";
import StoriesFeed from "../stories/StoriesFeed";
import AdUnit from "../ads/AdUnit";
import { AD_SLOTS } from "../ads/adsenseConfig";

interface User {
  _id: string;
  name: string;
  images?: string[];
  imageUrls?: string[];
  language_to_learn?: string;
}

type FeedTab = "forYou" | "trending" | "explore" | "following";

interface PromptOfDay {
  text?: string;
  emoji?: string;
  promptId?: string;
  language?: string;
}

interface UserInfo {
  user: User;
}

interface AuthState {
  userInfo?: UserInfo;
}

interface RootState {
  auth: AuthState;
}

interface MomentsResponse {
  moments: MomentType[];
  pagination: {
    currentPage: number;
    totalPages: number;
    totalMoments: number;
    limit: number;
    hasNextPage: boolean;
    hasPrevPage: boolean;
    nextPage: number | null;
    prevPage: number | null;
  };
}

interface CreatePostCardProps {
  userImage: string;
  userName: string;
  handleAddMoment: () => void;
  t: (key: string) => string;
}

interface LoadingStateProps {
  t: (key: string) => string;
}

interface ErrorStateProps {
  t: (key: string) => string;
  refetch: () => void;
}

interface FloatingActionButtonProps {
  onClick: () => void;
}

// Mobile-optimized Create Post Card
const CreatePostCard: React.FC<CreatePostCardProps> = ({
  userImage,
  userName,
  handleAddMoment,
  t,
}) => (
  <div className="relative mb-4 sm:mb-6 overflow-hidden rounded-xl sm:rounded-2xl bg-gradient-to-br from-white/80 to-gray-50/50 backdrop-blur-xl border border-white/20 shadow-xl">
    <div className="absolute inset-0 bg-gradient-to-r from-blue-500/5 to-purple-500/5"></div>
    <div className="relative p-3 sm:p-6">
      <div className="flex items-center gap-2 sm:gap-4">
        <div className="relative">
          <div className="relative overflow-hidden rounded-full ring-2 ring-white/50 shadow-lg">
            <img
              src={userImage}
              alt="User"
              className="h-8 w-8 sm:h-12 sm:w-12 object-cover transition-transform duration-300 hover:scale-110"
            />
          </div>
          <div className="absolute -bottom-0.5 -right-0.5 h-3 w-3 sm:h-4 sm:w-4 rounded-full bg-gradient-to-r from-green-400 to-green-500 ring-2 ring-white shadow-sm"></div>
        </div>
        <button
          onClick={handleAddMoment}
          className="group flex-1 rounded-full bg-white/60 backdrop-blur-sm border border-white/30 px-3 py-2 sm:px-6 sm:py-3 text-left shadow-lg transition-all duration-300 hover:bg-white/80 hover:shadow-xl hover:-translate-y-0.5 focus:outline-none focus:ring-2 focus:ring-blue-400/50"
        >
          <span className="text-sm sm:text-base text-gray-600 font-medium group-hover:text-gray-700 transition-colors">
            {t("moments_section.question")} {userName.split(" ")[0]}?
          </span>
        </button>
        <button
          onClick={handleAddMoment}
          className="hidden sm:group sm:flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-r from-blue-500 to-purple-600 shadow-lg transition-all duration-300 hover:shadow-xl hover:scale-110 hover:from-blue-600 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-blue-400/50"
        >
          <FaPlus className="h-4 w-4 text-white transition-transform group-hover:rotate-90" />
        </button>
      </div>
    </div>
  </div>
);

// Mobile-optimized loading state
const LoadingState: React.FC<LoadingStateProps> = ({ t }) => (
  <div className="flex flex-col items-center justify-center py-8 sm:py-16">
    <div className="relative">
      <div className="h-12 w-12 sm:h-16 sm:w-16 animate-spin rounded-full border-4 border-gray-200"></div>
      <div className="absolute top-0 left-0 h-12 w-12 sm:h-16 sm:w-16 animate-spin rounded-full border-4 border-transparent border-t-blue-500 border-r-purple-500"></div>
      <div className="absolute top-1/2 left-1/2 h-2 w-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-gradient-to-r from-blue-500 to-purple-600"></div>
    </div>
    <div className="mt-4 sm:mt-6 text-center px-4">
      <h3 className="text-base sm:text-lg font-semibold text-gray-800">
        {t("moments_section.loading_moments")}
      </h3>
      <p className="mt-1 text-xs sm:text-sm text-gray-500">
        Fetching latest updates...
      </p>
    </div>
  </div>
);

// Mobile-optimized error state
const ErrorState: React.FC<ErrorStateProps> = ({ t, refetch }) => (
  <div className="mx-2 sm:mx-4 my-4 sm:my-6 overflow-hidden rounded-xl sm:rounded-2xl bg-gradient-to-br from-red-50/80 to-pink-50/50 backdrop-blur-xl border border-red-200/30 shadow-lg">
    <div className="flex items-center gap-3 sm:gap-4 p-4 sm:p-6">
      <div className="flex h-10 w-10 sm:h-12 sm:w-12 flex-shrink-0 items-center justify-center rounded-full bg-gradient-to-r from-red-400 to-pink-500 shadow-lg">
        <FaExclamationTriangle className="h-4 w-4 sm:h-5 sm:w-5 text-white" />
      </div>
      <div className="flex-1 min-w-0">
        <h3 className="text-sm sm:text-base font-semibold text-gray-800">
          {t("moments_section.error_loading") || "Something went wrong"}
        </h3>
        <p className="mt-1 text-xs sm:text-sm text-gray-600 truncate">
          {t("moments_section.error_info")}
        </p>
      </div>
      <button
        onClick={refetch}
        className="group flex items-center gap-2 rounded-full bg-white/60 backdrop-blur-sm border border-white/30 px-3 py-2 sm:px-4 sm:py-2 text-xs sm:text-sm font-medium text-gray-700 shadow-lg transition-all duration-300 hover:bg-white/80 hover:shadow-xl hover:-translate-y-0.5 focus:outline-none focus:ring-2 focus:ring-red-400/50"
      >
        <FaRedo className="h-3 w-3 transition-transform group-hover:rotate-180" />
        <span className="hidden xs:inline">
          {t("moments_section.retry_btn")}
        </span>
      </button>
    </div>
  </div>
);

// Enhanced mobile floating action button
const FloatingActionButton: React.FC<FloatingActionButtonProps> = ({
  onClick,
}) => {
  const { t } = useTranslation();
  return (
  <div className="fixed bottom-4 right-4 sm:bottom-6 sm:right-6 z-50 lg:hidden">
    <button
      onClick={onClick}
      className="group flex h-12 w-12 sm:h-14 sm:w-14 items-center justify-center rounded-full bg-gradient-to-r from-blue-500 to-purple-600 shadow-2xl transition-all duration-300 hover:shadow-3xl hover:scale-110 hover:from-blue-600 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-blue-400/50 active:scale-95"
      aria-label={t("moments_section.create.header") || "Create moment"}
    >
      <FaPlus className="h-4 w-4 sm:h-5 sm:w-5 text-white transition-transform group-hover:rotate-90" />
    </button>
  </div>
  );
};

const MainMoments: React.FC = () => {
  const [limit] = useState(10);

  // Filters live in the URL (?cat=&lang=&mood=&tag=&q=) and run on the server.
  const [searchParams, setSearchParams] = useSearchParams();
  // A shared filtered link is served the unfiltered prerendered page, so a
  // prerendered document hydrates unfiltered first (matching its markup) and
  // applies the URL's filters on the render after.
  const [hydratingPrerender] = useState(() => isPrerendered());
  const hasHydrated = useHasHydrated();
  const filtersLive = !hydratingPrerender || hasHydrated;
  const filterKey = filtersLive
    ? encodeMomentFilters(decodeMomentFilters(searchParams)).toString()
    : "";
  const filters = useMemo<MomentFilters>(
    () => decodeMomentFilters(new URLSearchParams(filterKey)),
    [filterKey]
  );
  const queryFilters = hasMomentFilters(filters) ? filters : undefined;

  // The page belongs to one set of filters: any change of filters, including
  // Back/Forward, starts at page 1 without first asking for the old page.
  const [pageState, setPageState] = useState({ key: filterKey, page: 1 });
  const currentPage = pageState.key === filterKey ? pageState.page : 1;
  const setCurrentPage = useCallback(
    (page: number) => setPageState({ key: filterKey, page }),
    [filterKey]
  );

  const applyFilters = useCallback(
    (next: MomentFilters) => {
      setSearchParams(
        (current) => mergeMomentParams(current, encodeMomentFilters(next)),
        { replace: true }
      );
    },
    [setSearchParams]
  );

  // Feed tab state (For You / Trending / Explore)
  const [activeTab, setActiveTab] = useState<FeedTab>("forYou");
  const [promptDismissed, setPromptDismissed] = useState(false);

  // Fetch only the active tab's feed; other tabs are skipped (lazy).
  const forYouFeed = useGetMomentsQuery(
    { page: currentPage, limit, filters: queryFilters },
    { skip: activeTab !== "forYou" }
  );
  const trendingFeed = useGetTrendingMomentsQuery(
    { page: currentPage, limit, filters: queryFilters },
    { skip: activeTab !== "trending" }
  );
  const exploreFeed = useGetExploreMomentsQuery(
    { page: currentPage, limit, filters: queryFilters },
    { skip: activeTab !== "explore" }
  );
  const followingFeed = useGetMomentsQuery(
    { page: currentPage, limit, feed: "following", filters: queryFilters },
    { skip: activeTab !== "following" }
  );

  // Select the active tab's query result to drive the feed pipeline.
  const activeFeed =
    activeTab === "trending"
      ? trendingFeed
      : activeTab === "explore"
      ? exploreFeed
      : activeTab === "following"
      ? followingFeed
      : forYouFeed;
  const { data, isLoading, error, refetch } = activeFeed;

  const userId = useSelector(
    (state: RootState) => state.auth.userInfo?.user?._id
  );
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const { t } = useTranslation();
  const reelsOn = useWebFlag("webReelsEnabled");
  const navigate = useNavigate();

  // Feed tabs: labels are localized with English fallbacks; Following only
  // shows for signed-in users (the backend serves it only for them anyway).
  const feedTabs = useMemo(() => {
    const tabs: { key: FeedTab; label: string; Icon: typeof Sparkles }[] = [
      {
        key: "forYou",
        label: t("moments_section.tabs.forYou") || "For You",
        Icon: Sparkles,
      },
      {
        key: "trending",
        label: t("moments_section.tabs.trending") || "Trending",
        Icon: TrendingUp,
      },
      {
        key: "explore",
        label: t("moments_section.tabs.explore") || "Explore",
        Icon: Compass,
      },
    ];
    if (userInfo?.user) {
      tabs.push({
        key: "following",
        label: t("moments_section.tabs.following") || "Following",
        Icon: Users,
      });
    }
    return tabs;
  }, [t, userInfo]);

  // If the user logs out while viewing Following (or the tab otherwise
  // becomes unavailable), fall back to For You rather than querying a feed
  // the backend won't serve to an anonymous request.
  useEffect(() => {
    if (activeTab === "following" && !userInfo?.user) {
      setActiveTab("forYou");
      setCurrentPage(1);
    }
  }, [activeTab, userInfo, setCurrentPage]);

  // Memoize user data with proper typing
  const { userName, userImage } = useMemo(
    () => ({
      userName: userInfo?.user?.name || "User",
      userImage:
        userInfo?.user?.imageUrls?.[0] ||
        "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face",
    }),
    [userInfo]
  );

  // Prompt of the day (For You tab only). Degrades gracefully on 404/error.
  const promptLanguage = userInfo?.user?.language_to_learn || undefined;
  const { data: promptRaw, error: promptError } = useGetPromptOfDayQuery(
    { language: promptLanguage },
    { skip: activeTab !== "forYou" }
  );
  const promptOfDay = useMemo<PromptOfDay | null>(() => {
    if (!promptRaw) return null;
    // Tolerate both {..} and {data: {..}} shapes.
    const p = (promptRaw.data ?? promptRaw) as PromptOfDay;
    if (!p || !p.text) return null;
    return p;
  }, [promptRaw]);

  const showPrompt =
    activeTab === "forYou" && !promptDismissed && !promptError && !!promptOfDay;

  // Switch feed tabs, resetting pagination.
  const handleTabChange = useCallback((tab: FeedTab) => {
    setActiveTab(tab);
    setCurrentPage(1);
  }, [setCurrentPage]);

  // Navigate to create-moment prefilled from the prompt of the day.
  const handleAnswerPrompt = useCallback(() => {
    navigate("/add-moment", {
      state: {
        promptText: promptOfDay?.text,
        promptId: promptOfDay?.promptId,
        promptLanguage: promptOfDay?.language,
        promptEmoji: promptOfDay?.emoji,
      },
    });
  }, [navigate, promptOfDay]);

  // The page as served: the server has already filtered and paged it.
  const { moments, pagination } = useMemo(() => {
    if (!data) return { moments: [] as MomentType[], pagination: null };
    if (Array.isArray(data)) return { moments: data as MomentType[], pagination: null };
    const response = data as MomentsResponse;
    return { moments: response.moments || [], pagination: response.pagination || null };
  }, [data]);

  const totalPages = pagination ? pagination.totalPages || 1 : 1;
  const filtersActive = hasMomentFilters(filters);

  // Callback for adding a new moment
  const handleAddMoment = useCallback(() => {
    navigate("/add-moment");
  }, [navigate]);

  // Handle page change
  const handlePageChange = useCallback((page: number) => {
    setCurrentPage(page);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [setCurrentPage]);

  // Reset to page 1 when refetching
  const handleRefetch = useCallback(() => {
    setCurrentPage(1);
    refetch();
  }, [refetch, setCurrentPage]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-purple-50/30">
      <div className="mx-auto max-w-2xl px-2 sm:px-4 py-3 sm:py-6 lg:px-6">
        <div className="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-white/60 backdrop-blur-xl border border-white/30 shadow-2xl">
          <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent"></div>

          <div className="relative">
            {/* Stories ring strip */}
            <div className="px-3 sm:px-4 lg:px-6 pt-3 sm:pt-4">
              <StoriesFeed />
            </div>

            {/* Create post area */}
            <div className="p-3 sm:p-4 lg:p-6">
              <CreatePostCard
                userImage={userImage}
                userName={userName}
                handleAddMoment={handleAddMoment}
                t={t}
              />
            </div>

            <div className="px-3 sm:px-4 lg:px-6">
              {/* Feed tabs: For You / Trending / Explore */}
              <div
                role="tablist"
                aria-label="Feed"
                className="mb-4 flex gap-1 rounded-full bg-white/60 dark:bg-gray-800/50 backdrop-blur-sm border border-white/30 dark:border-gray-700/50 p-1 shadow-lg"
              >
                {feedTabs.map(({ key, label, Icon }) => {
                  const isActive = activeTab === key;
                  return (
                    <button
                      key={key}
                      role="tab"
                      aria-selected={isActive}
                      onClick={() => handleTabChange(key)}
                      className={`flex flex-1 items-center justify-center gap-1.5 rounded-full px-3 py-2 text-xs sm:text-sm font-medium transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-teal-400/50 ${
                        isActive
                          ? "bg-gradient-to-r from-teal-500 to-indigo-500 text-white shadow"
                          : "text-gray-600 dark:text-gray-300 hover:bg-white/70 dark:hover:bg-gray-700/50"
                      }`}
                    >
                      <Icon className="h-4 w-4" />
                      <span>{label}</span>
                    </button>
                  );
                })}
              </div>

              {/* Prompt of the Day (For You tab only) */}
              {showPrompt && promptOfDay && (
                <div className="mb-4 relative overflow-hidden rounded-xl sm:rounded-2xl bg-gradient-to-br from-teal-50/80 to-indigo-50/60 dark:from-teal-900/30 dark:to-indigo-900/20 backdrop-blur-xl border border-teal-200/40 dark:border-teal-700/40 shadow-lg">
                  <div className="relative p-4 sm:p-5">
                    <button
                      onClick={() => setPromptDismissed(true)}
                      aria-label={t("moments_section.prompt.dismissCard") || "Dismiss prompt of the day"}
                      className="absolute top-2 right-2 p-1.5 rounded-full text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 hover:bg-white/60 dark:hover:bg-gray-700/50 transition-colors"
                    >
                      <X className="h-4 w-4" />
                    </button>
                    <div className="flex items-start gap-3 pr-6">
                      <div className="text-2xl sm:text-3xl leading-none">
                        {promptOfDay.emoji || "✨"}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-[11px] font-semibold uppercase tracking-wide text-teal-600 dark:text-teal-400">
                          {t("moments_section.prompt.cardTitle") || "Prompt of the day"}
                        </p>
                        <p className="mt-0.5 text-sm sm:text-base font-medium text-gray-800 dark:text-gray-100">
                          {promptOfDay.text}
                        </p>
                        <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                          {t("moments_section.prompt.cardSubtitle") || "Practice writing"}
                        </p>
                        <button
                          onClick={handleAnswerPrompt}
                          className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-gradient-to-r from-teal-500 to-indigo-500 px-4 py-2 text-xs sm:text-sm font-semibold text-white shadow-lg transition-all duration-200 hover:from-teal-600 hover:to-indigo-600 hover:shadow-xl focus:outline-none focus:ring-2 focus:ring-teal-400/50"
                        >
                          <PenLine className="h-4 w-4" />
                          <span>{t("moments_section.prompt.answer") || "Answer"}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between mb-3 sm:mb-4">
                <h1 className="text-xl sm:text-2xl font-bold text-gray-800">
                  Stories list
                </h1>
                {reelsOn && userInfo && (
                  <Link
                    to="/reels"
                    data-testid="moments-reels-link"
                    className="inline-flex items-center gap-1.5 rounded-full bg-gray-900 px-3 py-1.5 text-sm font-bold text-white"
                  >
                    <Film className="h-4 w-4" aria-hidden="true" />
                    {t("reels.moments_link") || "Watch reels"}
                  </Link>
                )}
              </div>

              {/* Filter Component */}
              <MomentFiltersBar filters={filters} onChange={applyFilters} />
            </div>

            {/* Content states */}
            {isLoading ? (
              <LoadingState t={t} />
            ) : error ? (
              <ErrorState t={t} refetch={handleRefetch} />
            ) : moments.length > 0 ? (
              <>
                <div className="space-y-3 sm:space-y-4 px-2 sm:px-4 pb-4 sm:pb-6 lg:px-6">
                  {moments.map((moment, index) => (
                    <React.Fragment key={moment._id}>
                      <div
                        className="group transform transition-all duration-500 hover:-translate-y-1 hover:shadow-xl"
                        style={{
                          animationDelay: `${index * 0.1}s`,
                        }}
                      >
                        <div className="overflow-hidden rounded-xl sm:rounded-2xl bg-white/80 backdrop-blur-sm border border-white/30 shadow-lg transition-all duration-300 group-hover:bg-white/90 group-hover:shadow-2xl">
                          <SingleMoment
                            _id={moment._id}
                            title={moment.title}
                            description={moment.description}
                            likeCount={moment.likeCount}
                            commentCount={
                              moment.commentCount || moment.comments || []
                            }
                            user={moment.user}
                            likedUsers={moment.likedUsers}
                            imageUrls={moment.imageUrls}
                            createdAt={moment.createdAt}
                            refetch={refetch}
                            reactions={moment.reactions}
                            reactionCount={moment.reactionCount}
                            shareCount={moment.shareCount}
                            isSaved={moment.isSaved}
                            saveCount={moment.saveCount}
                            mediaType={moment.mediaType}
                            video={moment.video}
                            audio={moment.audio}
                            prompt={moment.prompt}
                            mood={moment.mood}
                            tags={moment.tags}
                            location={moment.location}
                            backgroundColor={moment.backgroundColor}
                            scheduledFor={moment.scheduledFor}
                          />
                        </div>
                      </div>
                      {/* Interleave a feed ad every 4 moments (parity with
                          Flutter _adEveryNPosts = 4), but never after the last
                          item. No-op until AdSense is configured. */}
                      {(index + 1) % 4 === 0 &&
                        index !== moments.length - 1 && (
                          <AdUnit slot={AD_SLOTS.feed} className="my-3" />
                        )}
                    </React.Fragment>
                  ))}
                </div>

                {/* Pagination component */}
                <Pagination
                  currentPage={currentPage}
                  totalPages={totalPages}
                  onPageChange={handlePageChange}
                  hasNextPage={pagination ? Boolean(pagination.hasNextPage) : false}
                  hasPrevPage={currentPage > 1}
                  totalMoments={pagination ? pagination.totalMoments || 0 : moments.length}
                  isLoading={isLoading}
                />
              </>
            ) : filtersActive ? (
              <div className="text-center py-12 sm:py-16 px-4">
                <div className="max-w-md mx-auto">
                  <div className="w-16 h-16 mx-auto mb-6 bg-gradient-to-br from-blue-100 to-purple-100 rounded-full flex items-center justify-center">
                    <FaFilter className="w-8 h-8 text-blue-500" />
                  </div>
                  <h3 className="text-lg sm:text-xl font-semibold text-gray-800 mb-3">
                    {t("moments_section.filters.emptyTitle") ||
                      "No moments match these filters"}
                  </h3>
                  <p className="text-gray-600 mb-6 leading-relaxed">
                    {t("moments_section.filters.emptyBody") ||
                      "Try removing a filter or searching for something else."}
                  </p>
                  <button
                    onClick={() => applyFilters({})}
                    className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-full hover:from-blue-600 hover:to-purple-700 transition-all duration-200 shadow-lg hover:shadow-xl focus:outline-none focus:ring-2 focus:ring-blue-400/50"
                  >
                    <FaTimes className="w-4 h-4" />
                    <span className="font-medium">
                      {t("moments_section.filters.clear") || "Clear filters"}
                    </span>
                  </button>
                </div>
              </div>
            ) : activeTab === "following" ? (
              <div
                className="text-center py-12 sm:py-16 px-4"
                data-testid="following-empty-state"
              >
                <div className="max-w-md mx-auto">
                  <div className="mx-auto mb-6 sm:mb-8 flex h-16 w-16 sm:h-20 sm:w-20 items-center justify-center rounded-full bg-gradient-to-r from-teal-500 to-indigo-500 shadow-lg">
                    <Users className="h-6 w-6 sm:h-8 sm:w-8 text-white" />
                  </div>
                  <h3 className="text-lg sm:text-xl font-bold text-gray-800 mb-3">
                    {t("moments_section.following.empty") ||
                      "Follow people to see their moments here"}
                  </h3>
                  <Link
                    to="/communities"
                    className="inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-teal-500 to-indigo-500 px-6 py-3 text-sm sm:text-base font-semibold text-white shadow-lg transition-all duration-300 hover:shadow-xl hover:scale-105 focus:outline-none focus:ring-2 focus:ring-teal-400/50"
                  >
                    {t("moments_section.following.findPeople") ||
                      "Find people"}
                  </Link>
                </div>
              </div>
            ) : (
              <EmptyState t={t} handleAddMoment={handleAddMoment} />
            )}
          </div>
        </div>

        {/* Mobile floating action button */}
        {userId && <FloatingActionButton onClick={handleAddMoment} />}
      </div>
    </div>
  );
};

export default React.memo(MainMoments);
