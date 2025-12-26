import ISO6391 from "iso-639-1";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  FaExclamationTriangle,
  FaFilter,
  FaPlus,
  FaRedo,
  FaSearch,
  FaTimes,
} from "react-icons/fa";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import Pagination from "../../composables/Pagination";
import { useGetMomentsQuery } from "../../store/slices/momentsSlice";
import EmptyState from "./EmptyState";
import SingleMoment from "./SingleMoment";
import { MomentType } from "./types";

interface User {
  _id: string;
  name: string;
  images?: string[];
  imageUrls?: string[];
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

interface FilterState {
  category: string;
  language: string;
  mood: string;
  tag: string;
  user: string;
  search: string;
  searchInput: string;
}

interface FilterComponentProps {
  filters: FilterState;
  onFilterChange: (key: keyof FilterState, value: string) => void;
  onClearFilters: () => void;
  moments: MomentType[];
  isOpen: boolean;
  onToggle: () => void;
}

// Filter Component with ISO6391 and Search Button
const FilterComponent: React.FC<FilterComponentProps> = ({
  filters,
  onFilterChange,
  onClearFilters,
  moments,
  isOpen,
  onToggle,
}) => {
  // Get all available language options from ISO6391
  const allLanguageOptions = useMemo(() => {
    return ISO6391.getAllCodes()
      .map((code) => ({
        value: code,
        label: ISO6391.getName(code),
      }))
      .sort((a, b) => a.label.localeCompare(b.label));
  }, []);

  // Extract unique values from moments data
  const filterOptions = useMemo(() => {
    const categories = [
      ...new Set(
        moments.map((m) => m.category || "uncategorized").filter(Boolean)
      ),
    ];
    const usedLanguages = [
      ...new Set(
        moments.map((m) => m.language || "unspecified").filter(Boolean)
      ),
    ];
    const moods = [
      ...new Set(moments.map((m) => m.mood || "neutral").filter(Boolean)),
    ];
    const tags = [
      ...new Set(
        moments
          .flatMap((m) => (m.tags && m.tags.length > 0 ? m.tags : ["untagged"]))
          .filter(Boolean)
      ),
    ];
    const users = [
      ...new Set(moments.map((m) => m.user?.name).filter(Boolean)),
    ];

    return { categories, usedLanguages, moods, tags, users };
  }, [moments]);

  const hasActiveFilters = Object.entries(filters).some(
    ([key, value]) => key !== "searchInput" && value !== ""
  );

  // Handle search functionality
  const handleSearchClick = useCallback(() => {
    onFilterChange("search", filters.searchInput.trim());
  }, [filters.searchInput, onFilterChange]);

  const handleSearchInputChange = useCallback(
    (value: string) => {
      onFilterChange("searchInput", value);
    },
    [onFilterChange]
  );

  const handleSearchKeyPress = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Enter") {
        e.preventDefault();
        handleSearchClick();
      }
    },
    [handleSearchClick]
  );

  // Get language display name
  const getLanguageDisplayName = useCallback((languageCode: string) => {
    if (languageCode === "unspecified") return "Unspecified";
    const languageName = ISO6391.getName(languageCode);
    return (
      languageName ||
      languageCode.charAt(0).toUpperCase() + languageCode.slice(1)
    );
  }, []);

  return (
    <div className="mb-4 sm:mb-6">
      {/* Filter Toggle Button */}
      <div className="flex items-center justify-between mb-3">
        <button
          onClick={onToggle}
          className="flex items-center gap-2 px-4 py-2 bg-white/80 backdrop-blur-sm border border-white/30 rounded-lg shadow-lg hover:bg-white/90 transition-all duration-200"
        >
          <FaFilter className="w-4 h-4 text-gray-600" />
          <span className="text-sm font-medium text-gray-700">Filters</span>
          {hasActiveFilters && (
            <span className="bg-blue-500 text-white text-xs px-2 py-0.5 rounded-full">
              {
                Object.entries(filters).filter(
                  ([key, value]) => key !== "searchInput" && value !== ""
                ).length
              }
            </span>
          )}
        </button>

        {hasActiveFilters && (
          <button
            onClick={onClearFilters}
            className="flex items-center gap-1 px-3 py-1.5 bg-red-100 text-red-600 rounded-lg hover:bg-red-200 transition-colors text-sm"
          >
            <FaTimes className="w-3 h-3" />
            <span>Clear All</span>
          </button>
        )}
      </div>

      {/* Filter Panel */}
      {isOpen && (
        <div className="bg-white/80 backdrop-blur-sm border border-white/30 rounded-xl shadow-lg p-4 space-y-4">
          {/* Enhanced Search with Button */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Search in title/description
            </label>
            <div className="flex gap-2">
              <div className="relative flex-1">
                <FaSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  value={filters.searchInput}
                  onChange={(e) => handleSearchInputChange(e.target.value)}
                  onKeyPress={handleSearchKeyPress}
                  placeholder="Type your search term..."
                  className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white/90 transition-all"
                />
              </div>
              <button
                onClick={handleSearchClick}
                disabled={!filters.searchInput.trim()}
                className="px-4 py-2.5 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed focus:ring-2 focus:ring-blue-500 focus:outline-none transition-all duration-200 flex items-center gap-2 min-w-[100px] justify-center"
              >
                <FaSearch className="w-4 h-4" />
                <span className="hidden sm:inline font-medium">Search</span>
              </button>
            </div>

            {/* Active Search Display */}
            {filters.search && (
              <div className="mt-3 p-2 bg-blue-50 rounded-lg border border-blue-200">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <FaSearch className="w-3 h-3 text-blue-600" />
                    <span className="text-sm text-blue-800">
                      Searching for: <strong>"{filters.search}"</strong>
                    </span>
                  </div>
                  <button
                    onClick={() => {
                      onFilterChange("search", "");
                      onFilterChange("searchInput", "");
                    }}
                    className="text-blue-600 hover:text-blue-800 p-1"
                    title="Clear search"
                  >
                    <FaTimes className="w-3 h-3" />
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Filter Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {/* Category Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Category
              </label>
              <select
                value={filters.category}
                onChange={(e) => onFilterChange("category", e.target.value)}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white/80"
              >
                <option value="">All Categories</option>
                {filterOptions.categories.map((category) => (
                  <option key={category} value={category}>
                    {category === "uncategorized"
                      ? "Uncategorized"
                      : category
                          .replace(/-/g, " ")
                          .replace(/\b\w/g, (l) => l.toUpperCase())}
                  </option>
                ))}
              </select>
            </div>

            {/* Enhanced Language Filter with ISO6391 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Language
              </label>
              <select
                value={filters.language}
                onChange={(e) => onFilterChange("language", e.target.value)}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white/80"
              >
                <option value="">All Languages</option>

                {/* Languages used in moments */}
                {filterOptions.usedLanguages.length > 0 && (
                  <optgroup label="Languages in Posts">
                    {filterOptions.usedLanguages.map((language) => (
                      <option key={`used-${language}`} value={language}>
                        {getLanguageDisplayName(language)}
                      </option>
                    ))}
                  </optgroup>
                )}

                {/* All available languages */}
                <optgroup label="All Available Languages">
                  {allLanguageOptions.map(({ value, label }) => (
                    <option key={`all-${value}`} value={value}>
                      {label} ({value.toUpperCase()})
                    </option>
                  ))}
                </optgroup>
              </select>
            </div>

            {/* Tag Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Tag
              </label>
              <select
                value={filters.tag}
                onChange={(e) => onFilterChange("tag", e.target.value)}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white/80"
              >
                <option value="">All Tags</option>
                {filterOptions.tags.map((tag) => (
                  <option key={tag} value={tag}>
                    {tag === "untagged" ? "Untagged" : tag}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Active Filters Display */}
          {hasActiveFilters && (
            <div className="pt-3 border-t border-gray-200">
              <p className="text-xs text-gray-500 mb-2">Active filters:</p>
              <div className="flex flex-wrap gap-2">
                {Object.entries(filters).map(([key, value]) => {
                  if (!value || key === "searchInput") return null;

                  // Format display value
                  let displayValue = value;
                  if (key === "category" && value === "uncategorized")
                    displayValue = "Uncategorized";
                  if (key === "language")
                    displayValue = getLanguageDisplayName(value);
                  if (key === "mood" && value === "neutral")
                    displayValue = "Neutral/None";
                  if (key === "tag" && value === "untagged")
                    displayValue = "Untagged";

                  return (
                    <span
                      key={key}
                      className="inline-flex items-center gap-1 px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
                    >
                      <span className="font-medium capitalize">{key}:</span>
                      <span>{displayValue}</span>
                      <button
                        onClick={() =>
                          onFilterChange(key as keyof FilterState, "")
                        }
                        className="ml-1 hover:bg-blue-200 rounded-full p-0.5 transition-colors"
                        aria-label={`Remove ${key} filter`}
                      >
                        <FaTimes className="w-3 h-3" />
                      </button>
                    </span>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

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
          Something went wrong
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
          {t("moments_section.rety_btn")}
        </span>
      </button>
    </div>
  </div>
);

// Enhanced mobile floating action button
const FloatingActionButton: React.FC<FloatingActionButtonProps> = ({
  onClick,
}) => (
  <div className="fixed bottom-4 right-4 sm:bottom-6 sm:right-6 z-50 lg:hidden">
    <button
      onClick={onClick}
      className="group flex h-12 w-12 sm:h-14 sm:w-14 items-center justify-center rounded-full bg-gradient-to-r from-blue-500 to-purple-600 shadow-2xl transition-all duration-300 hover:shadow-3xl hover:scale-110 hover:from-blue-600 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-blue-400/50 active:scale-95"
      aria-label="Add new moment"
    >
      <FaPlus className="h-4 w-4 sm:h-5 sm:w-5 text-white transition-transform group-hover:rotate-90" />
    </button>
  </div>
);

const MainMoments: React.FC = () => {
  // Pagination state
  const [currentPage, setCurrentPage] = useState(1);
  const [limit] = useState(10);

  // Filter states with searchInput for controlled search
  const [filters, setFilters] = useState<FilterState>({
    category: "",
    language: "",
    mood: "",
    tag: "",
    user: "",
    search: "",
    searchInput: "",
  });
  const [isFilterOpen, setIsFilterOpen] = useState(false);

  const { data, isLoading, error, refetch } = useGetMomentsQuery({
    page: currentPage,
    limit: limit,
  });

  const userId = useSelector(
    (state: RootState) => state.auth.userInfo?.user._id
  );
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const { t } = useTranslation();
  const navigate = useNavigate();

  // Memoize user data with proper typing
  const { userName, userImage } = useMemo(
    () => ({
      userName: userInfo?.user.name || "User",
      userImage:
        userInfo?.user.imageUrls?.[0] ||
        "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face",
    }),
    [userInfo]
  );

  // Extract moments and pagination from response
  const { allMoments } = useMemo(() => {
    if (!data) {
      return {
        allMoments: [] as MomentType[],
      };
    }

    if (Array.isArray(data)) {
      return {
        allMoments: data as MomentType[],
      };
    } else {
      const response = data as MomentsResponse;
      return {
        allMoments: response.moments || [],
      };
    }
  }, [data]);

  // Filter moments based on current filters - handle optional fields properly
  const filteredMoments = useMemo(() => {
    return allMoments.filter((moment) => {
      // Search filter
      if (filters.search) {
        const searchTerm = filters.search.toLowerCase();
        const titleMatch = moment.title?.toLowerCase().includes(searchTerm);
        const descriptionMatch = moment.description
          ?.toLowerCase()
          .includes(searchTerm);
        if (!titleMatch && !descriptionMatch) return false;
      }

      // Category filter - handle empty/null categories
      if (filters.category) {
        const momentCategory = moment.category || "uncategorized";
        if (momentCategory !== filters.category) {
          return false;
        }
      }

      // Language filter - handle empty/null languages
      if (filters.language) {
        const momentLanguage = moment.language || "unspecified";
        if (momentLanguage !== filters.language) {
          return false;
        }
      }

      // Mood filter - handle empty/null moods
      if (filters.mood) {
        const momentMood = moment.mood || "neutral";
        if (momentMood !== filters.mood) {
          return false;
        }
      }

      // Tag filter - handle empty/null tags
      if (filters.tag) {
        const momentTags =
          moment.tags && moment.tags.length > 0 ? moment.tags : ["untagged"];
        if (!momentTags.includes(filters.tag)) {
          return false;
        }
      }

      // User filter
      if (filters.user && moment.user?.name !== filters.user) {
        return false;
      }

      return true;
    });
  }, [allMoments, filters]);

  // Handle filter changes
  const handleFilterChange = useCallback(
    (key: keyof FilterState, value: string) => {
      setFilters((prev) => ({ ...prev, [key]: value }));
      setCurrentPage(1); // Reset to first page when filter changes
    },
    []
  );

  // Clear all filters
  const handleClearFilters = useCallback(() => {
    setFilters({
      category: "",
      language: "",
      mood: "",
      tag: "",
      user: "",
      search: "",
      searchInput: "",
    });
    setCurrentPage(1);
  }, []);

  // Toggle filter panel
  const toggleFilterPanel = useCallback(() => {
    setIsFilterOpen((prev) => !prev);
  }, []);

  // Callback for adding a new moment
  const handleAddMoment = useCallback(() => {
    navigate("/add-moment");
  }, [navigate]);

  // Handle page change
  const handlePageChange = useCallback((page: number) => {
    setCurrentPage(page);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, []);

  // Reset to page 1 when refetching
  const handleRefetch = useCallback(() => {
    setCurrentPage(1);
    refetch();
  }, [refetch]);

  // Calculate pagination for filtered results
  const paginatedMoments = useMemo(() => {
    const startIndex = (currentPage - 1) * limit;
    const endIndex = startIndex + limit;
    return filteredMoments.slice(startIndex, endIndex);
  }, [filteredMoments, currentPage, limit]);

  const filteredPagination = useMemo(() => {
    const totalFilteredMoments = filteredMoments.length;
    const totalPages = Math.ceil(totalFilteredMoments / limit);

    return {
      currentPage,
      totalPages,
      totalMoments: totalFilteredMoments,
      limit,
      hasNextPage: currentPage < totalPages,
      hasPrevPage: currentPage > 1,
      nextPage: currentPage < totalPages ? currentPage + 1 : null,
      prevPage: currentPage > 1 ? currentPage - 1 : null,
    };
  }, [filteredMoments.length, currentPage, limit]);

  // Reset page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [filters]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-purple-50/30">
      <div className="mx-auto max-w-2xl px-2 sm:px-4 py-3 sm:py-6 lg:px-6">
        <div className="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-white/60 backdrop-blur-xl border border-white/30 shadow-2xl">
          <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent"></div>

          <div className="relative">
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
              <div className="flex items-center justify-between mb-3 sm:mb-4">
                <h1 className="text-xl sm:text-2xl font-bold text-gray-800">
                  Stories list
                  {filteredMoments.length !== allMoments.length && (
                    <span className="text-sm font-normal text-gray-500 ml-2">
                      ({filteredMoments.length} of {allMoments.length})
                    </span>
                  )}
                </h1>
              </div>

              {/* Filter Component */}
              <FilterComponent
                filters={filters}
                onFilterChange={handleFilterChange}
                onClearFilters={handleClearFilters}
                moments={allMoments}
                isOpen={isFilterOpen}
                onToggle={toggleFilterPanel}
              />
            </div>

            {/* Content states */}
            {isLoading ? (
              <LoadingState t={t} />
            ) : error ? (
              <ErrorState t={t} refetch={handleRefetch} />
            ) : paginatedMoments.length > 0 ? (
              <>
                <div className="space-y-3 sm:space-y-6 px-2 sm:px-4 pb-4 sm:pb-6 lg:px-6">
                  {paginatedMoments.map((moment, index) => (
                    <div
                      key={moment._id}
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
                        />
                      </div>
                    </div>
                  ))}
                </div>

                {/* Pagination component */}
                <Pagination
                  currentPage={filteredPagination.currentPage}
                  totalPages={filteredPagination.totalPages}
                  onPageChange={handlePageChange}
                  hasNextPage={filteredPagination.hasNextPage}
                  hasPrevPage={filteredPagination.hasPrevPage}
                  totalMoments={filteredPagination.totalMoments}
                  isLoading={isLoading}
                />
              </>
            ) : filteredMoments.length === 0 && allMoments.length > 0 ? (
              <div className="text-center py-12 sm:py-16 px-4">
                <div className="max-w-md mx-auto">
                  <div className="w-16 h-16 mx-auto mb-6 bg-gradient-to-br from-blue-100 to-purple-100 rounded-full flex items-center justify-center">
                    <FaFilter className="w-8 h-8 text-blue-500" />
                  </div>
                  <h3 className="text-lg sm:text-xl font-semibold text-gray-800 mb-3">
                    No moments match your filters
                  </h3>
                  <p className="text-gray-600 mb-6 leading-relaxed">
                    We couldn't find any moments that match your current filter
                    criteria. Try adjusting or removing some filters to see more
                    results.
                  </p>

                  {/* Show current filter summary */}
                  <div className="bg-gray-50 rounded-lg p-4 mb-6">
                    <p className="text-sm text-gray-600 mb-2">
                      Current filters:
                    </p>
                    <div className="flex flex-wrap gap-2 justify-center">
                      {Object.entries(filters).map(([key, value]) => {
                        if (!value || key === "searchInput") return null;
                        let displayValue = value;
                        if (key === "category" && value === "uncategorized")
                          displayValue = "Uncategorized";
                        if (key === "language" && value === "unspecified")
                          displayValue = "Unspecified";
                        if (key === "mood" && value === "neutral")
                          displayValue = "Neutral/None";
                        if (key === "tag" && value === "untagged")
                          displayValue = "Untagged";

                        return (
                          <span
                            key={key}
                            className="inline-flex items-center gap-1 px-2 py-1 bg-white border border-gray-200 rounded-md text-xs text-gray-700"
                          >
                            <span className="font-medium capitalize">
                              {key}:
                            </span>
                            <span>{displayValue}</span>
                          </span>
                        );
                      })}
                    </div>
                  </div>

                  <button
                    onClick={handleClearFilters}
                    className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-full hover:from-blue-600 hover:to-purple-700 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 focus:outline-none focus:ring-2 focus:ring-blue-400/50"
                  >
                    <FaTimes className="w-4 h-4" />
                    <span className="font-medium">Clear All Filters</span>
                  </button>
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
