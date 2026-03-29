import { useState, useMemo, useCallback, useEffect } from "react";
import {
  Search, Sparkles, X, Loader2, Filter,
  Users, Clock, TrendingUp, Globe2, MessageCircle, Heart, ChevronDown
} from "lucide-react";
import { useGetCommunityMembersQuery } from "../../store/slices/communitySlice";
import { useTranslation } from "react-i18next";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { COMMON_LANGUAGES, LANGUAGE_FLAGS, LanguageFlagProps, TabType } from "./type";
import { useDebounce } from "./utils";
import { Link, useNavigate, Navigate } from "react-router-dom";
import "./MainCommunity.css";

export const LanguageFlag: React.FC<LanguageFlagProps> = ({ code }) => (
  <span className="text-lg">{LANGUAGE_FLAGS[code] || code}</span>
);

// Language code helper
const getLanguageCode = (language: string): string => {
  const codes: Record<string, string> = {
    English: "en", Spanish: "es", French: "fr", German: "de", Italian: "it",
    Portuguese: "pt", Russian: "ru", Japanese: "ja", Korean: "ko", Chinese: "zh",
  };
  return codes[language] || language.substring(0, 2).toLowerCase();
};

// Tandem-style Member Card
interface MemberCardProps {
  member: any;
  onWave: (id: string) => void;
  onMessage: (id: string) => void;
}

const TandemMemberCard: React.FC<MemberCardProps> = ({ member, onWave, onMessage }) => {
  const { t } = useTranslation();
  const [isLiked, setIsLiked] = useState(false);
  const navigate = useNavigate();

  const nativeCode = getLanguageCode(member.native_language || "");
  const learningCode = getLanguageCode(member.language_to_learn || "");

  // Use actual online status from member data
  const isOnline = member.isOnline || false;

  // Calculate last active time
  const getLastActiveText = () => {
    if (!member.lastActive && !member.lastSeen) return t("communityMain.memberCard.recently");
    const lastActiveDate = new Date(member.lastActive || member.lastSeen);
    const now = new Date();
    const diffMs = now.getTime() - lastActiveDate.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return t("communityMain.memberCard.justNow");
    if (diffMins < 60) return t("communityMain.memberCard.minutesAgo", { count: diffMins });
    if (diffHours < 24) return t("communityMain.memberCard.hoursAgo", { count: diffHours });
    if (diffDays < 7) return t("communityMain.memberCard.daysAgo", { count: diffDays });
    return t("communityMain.memberCard.overWeekAgo");
  };

  const lastActive = getLastActiveText();

  return (
    <div className="member-card-tandem bg-white rounded-2xl shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden border border-gray-100 group">
      {/* Card Header with gradient */}
      <div className="h-16 bg-gradient-to-r from-teal-400 via-emerald-400 to-cyan-400 relative">
        <div className="absolute -bottom-10 left-1/2 -translate-x-1/2">
          <Link to={`/community/${member._id}`}>
            <div className="relative">
              <img
                src={member.imageUrls?.[0] || "/default-avatar.png"}
                alt={member.name}
                className="w-20 h-20 rounded-full object-cover border-4 border-white shadow-lg group-hover:scale-105 transition-transform duration-300"
              />
              {/* Online indicator */}
              <div className={`absolute bottom-1 right-1 w-5 h-5 rounded-full border-2 border-white ${isOnline ? 'bg-green-500' : 'bg-gray-300'}`}>
                {isOnline && <div className="w-full h-full rounded-full bg-green-500 animate-ping opacity-75"></div>}
              </div>
            </div>
          </Link>
        </div>

        {/* Like button */}
        <button
          onClick={(e) => { e.stopPropagation(); setIsLiked(!isLiked); }}
          className="absolute top-3 right-3 p-2 rounded-full bg-white/20 backdrop-blur-sm hover:bg-white/40 transition-all"
        >
          <Heart className={`w-4 h-4 ${isLiked ? 'fill-red-500 text-red-500' : 'text-white'}`} />
        </button>
      </div>

      {/* Card Body */}
      <div className="pt-12 pb-4 px-4">
        {/* Name and Status */}
        <div className="text-center mb-3">
          <Link to={`/community/${member._id}`}>
            <h3 className="text-lg font-bold text-gray-800 hover:text-teal-600 transition-colors">
              {member.name}
            </h3>
          </Link>
          {member.username && (
            <p className="text-xs text-gray-500 mt-0.5">
              @{member.username}
            </p>
          )}
          <p className="text-xs text-gray-400 flex items-center justify-center gap-1 mt-1">
            {isOnline ? (
              <span className="text-green-500 font-medium">{t("communityMain.memberCard.onlineNow")}</span>
            ) : (
              <>
                <Clock className="w-3 h-3" />
                <span>{t("communityMain.memberCard.active")} {lastActive}</span>
              </>
            )}
          </p>
        </div>

        {/* Language Exchange Display */}
        <div className="flex items-center justify-center gap-2 mb-4 px-2">
          <div className="flex items-center gap-1.5 bg-gradient-to-r from-blue-50 to-indigo-50 px-3 py-1.5 rounded-full">
            <span className="text-base">{LANGUAGE_FLAGS[nativeCode] || "🌐"}</span>
            <span className="text-xs font-medium text-gray-600">{member.native_language || t("communityMain.memberCard.native")}</span>
          </div>
          <div className="flex items-center justify-center w-6 h-6 rounded-full bg-gray-100">
            <svg className="w-3 h-3 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
            </svg>
          </div>
          <div className="flex items-center gap-1.5 bg-gradient-to-r from-orange-50 to-rose-50 px-3 py-1.5 rounded-full">
            <span className="text-base">{LANGUAGE_FLAGS[learningCode] || "🌐"}</span>
            <span className="text-xs font-medium text-gray-600">{member.language_to_learn || t("communityMain.memberCard.learning")}</span>
          </div>
        </div>

        {/* Bio */}
        <p className="text-sm text-gray-500 text-center mb-4 line-clamp-2 min-h-[40px] px-2">
          {member.bio || t("communityMain.memberCard.defaultBio")}
        </p>

        {/* Action Buttons */}
        <div className="flex gap-2">
          <button
            onClick={() => onWave(member._id)}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-gradient-to-r from-teal-500 to-emerald-500 text-white rounded-xl font-medium text-sm hover:shadow-lg hover:shadow-teal-500/25 transition-all hover:-translate-y-0.5"
          >
            <span className="text-base">👋</span>
            {t("communityMain.memberCard.actions.wave")}
          </button>
          <button
            onClick={() => onMessage(member._id)}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-gray-100 text-gray-700 rounded-xl font-medium text-sm hover:bg-gray-200 transition-all"
          >
            <MessageCircle className="w-4 h-4" />
            {t("communityMain.memberCard.actions.message")}
          </button>
        </div>
      </div>
    </div>
  );
};

// Filter Pill Component
const FilterPill: React.FC<{
  label: string;
  active: boolean;
  onClick: () => void;
  icon?: React.ReactNode;
}> = ({ label, active, onClick, icon }) => (
  <button
    onClick={onClick}
    className={`flex items-center gap-2 px-4 py-2 rounded-full font-medium text-sm transition-all duration-200 ${
      active
        ? 'bg-teal-500 text-white shadow-lg shadow-teal-500/25'
        : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
    }`}
  >
    {icon}
    {label}
  </button>
);

// Main Component
const ModernCommunity: React.FC = () => {
  const [filter, setFilter] = useState("");
  const [languageFilter, setLanguageFilter] = useState("");
  const [activeTab, setActiveTab] = useState<TabType>("all");
  const [showLanguageDropdown, setShowLanguageDropdown] = useState(false);
  const [page, setPage] = useState(1);
  const [allMembers, setAllMembers] = useState<any[]>([]);

  const debouncedFilter = useDebounce(filter, 300);
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { userInfo } = useSelector((state: RootState) => state.auth);

  const currentUser = useSelector((state: RootState) => ({
    _id: state.auth.userInfo?.user?._id,
    native_language: state.auth.userInfo?.user?.native_language,
    language_to_learn: state.auth.userInfo?.user?.language_to_learn
  }));

  const {
    data: communityData,
    isLoading,
    isFetching,
    error: errorInfo,
    refetch,
  } = useGetCommunityMembersQuery({
    page,
    limit: 20,
    filter: debouncedFilter,
    language: languageFilter,
    sort: activeTab === "popular" ? "popular" : activeTab === "new" ? "newest" : "",
  });

  // Reset and accumulate members when data changes
  useEffect(() => {
    if (communityData?.data) {
      if (page === 1) {
        setAllMembers(communityData.data);
      } else {
        setAllMembers(prev => {
          const existingIds = new Set(prev.map((m: any) => m._id));
          const newMembers = communityData.data.filter((m: any) => !existingIds.has(m._id));
          return [...prev, ...newMembers];
        });
      }
    }
  }, [communityData, page]);

  // Reset page when filters change
  useEffect(() => {
    setPage(1);
    setAllMembers([]);
  }, [debouncedFilter, languageFilter, activeTab]);

  const members = allMembers;
  const hasMore = communityData?.data?.length === 20;

  const filteredMembers = useMemo(() => {
    let filteredList = members.filter((member: any) => {
      if (currentUser._id) {
        return member._id !== currentUser._id;
      }
      return true;
    });

    if (debouncedFilter?.trim()) {
      const searchTerm = debouncedFilter.toLowerCase();
      filteredList = filteredList.filter((member: any) =>
        [member.name, member.native_language, member.language_to_learn, member.bio]
          .some(field => field?.toLowerCase().includes(searchTerm))
      );
    }

    if (languageFilter) {
      filteredList = filteredList.filter((member: any) =>
        member.native_language === languageFilter ||
        member.language_to_learn === languageFilter
      );
    }

    switch (activeTab) {
      case "popular":
        return filteredList.sort(() => Math.random() - 0.5).slice(0, 12);
      case "new":
        return filteredList.slice(-8);
      default:
        return filteredList;
    }
  }, [members, currentUser, debouncedFilter, languageFilter, activeTab]);

  const handleWave = useCallback((memberId: string) => {
    console.log(`Waved at: ${memberId}`);
    // Add wave mutation here
  }, []);

  const handleMessage = useCallback((memberId: string) => {
    navigate(`/chat/${memberId}`);
  }, [navigate]);

  const handleLoadMore = useCallback(() => {
    if (!isFetching && hasMore) {
      setPage(prev => prev + 1);
    }
  }, [isFetching, hasMore]);

  // Redirect to login if not authenticated
  if (!userInfo) {
    return <Navigate to="/login?redirect=/community" replace />;
  }

  if (errorInfo) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="text-center bg-white rounded-2xl p-8 shadow-lg max-w-md">
          <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <X className="w-8 h-8 text-red-500" />
          </div>
          <h2 className="text-xl font-bold text-gray-800 mb-2">{t("communityMain.errors.generic")}</h2>
          <p className="text-gray-500 mb-6">{t("communityMain.errors.loadError")}</p>
          <button
            onClick={() => refetch()}
            className="px-6 py-3 bg-teal-500 text-white rounded-xl font-medium hover:bg-teal-600 transition-colors"
          >
            {t("communityMain.errors.tryAgain")}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-teal-50 via-white to-gray-50">
      {/* Hero Section */}
      <div className="bg-gradient-to-r from-teal-500 via-emerald-500 to-cyan-500 text-white">
        <div className="max-w-7xl mx-auto px-4 py-12 sm:py-16">
          {/* Header */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full mb-4">
              <Globe2 className="w-4 h-4" />
              <span className="text-sm font-medium">{t("communityMain.badge")}</span>
            </div>
            <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold mb-4">
              {t("communityMain.heroTitle")}
              <br />
              <span className="bg-gradient-to-r from-yellow-200 to-orange-200 bg-clip-text text-transparent">
                {t("communityMain.heroTitleHighlight")}
              </span>
            </h1>
            <p className="text-lg text-white/80 max-w-2xl mx-auto">
              {t("communityMain.heroDescription")}
            </p>
          </div>

          {/* Stats */}
          <div className="flex justify-center gap-8 sm:gap-16 mb-8">
            {[
              { value: `${members.length}+`, label: t("communityMain.stats.activeUsers") },
              { value: "50+", label: t("communityMain.stats.languages") },
              { value: "180+", label: t("communityMain.stats.countries") }
            ].map((stat, i) => (
              <div key={i} className="text-center">
                <div className="text-2xl sm:text-3xl font-bold">{stat.value}</div>
                <div className="text-sm text-white/70">{stat.label}</div>
              </div>
            ))}
          </div>

          {/* Search Bar */}
          <div className="max-w-2xl mx-auto">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder={t("communityMain.search.placeholder")}
                value={filter}
                onChange={(e) => setFilter(e.target.value)}
                className="w-full pl-12 pr-12 py-4 bg-white rounded-2xl text-gray-800 placeholder-gray-400 shadow-xl focus:outline-none focus:ring-4 focus:ring-white/30"
              />
              {filter && (
                <button
                  onClick={() => setFilter("")}
                  className="absolute right-4 top-1/2 -translate-y-1/2 p-1 hover:bg-gray-100 rounded-full"
                >
                  <X className="w-5 h-5 text-gray-400" />
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Filters Section */}
      <div className="sticky top-0 z-40 bg-white/80 backdrop-blur-lg border-b border-gray-100 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex flex-wrap items-center gap-3">
            {/* Tab Filters */}
            <div className="flex gap-2">
              <FilterPill
                label={t("communityMain.tabs.all")}
                active={activeTab === "all"}
                onClick={() => setActiveTab("all")}
                icon={<Users className="w-4 h-4" />}
              />
              <FilterPill
                label={t("communityMain.tabs.popular")}
                active={activeTab === "popular"}
                onClick={() => setActiveTab("popular")}
                icon={<TrendingUp className="w-4 h-4" />}
              />
              <FilterPill
                label={t("communityMain.tabs.new")}
                active={activeTab === "new"}
                onClick={() => setActiveTab("new")}
                icon={<Sparkles className="w-4 h-4" />}
              />
            </div>

            <div className="h-6 w-px bg-gray-200 hidden sm:block"></div>

            {/* Language Dropdown */}
            <div className="relative">
              <button
                onClick={() => setShowLanguageDropdown(!showLanguageDropdown)}
                className={`flex items-center gap-2 px-4 py-2 rounded-full font-medium text-sm transition-all ${
                  languageFilter
                    ? 'bg-teal-500 text-white'
                    : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
                }`}
              >
                <Filter className="w-4 h-4" />
                {languageFilter || t("communityMain.filters.language")}
                <ChevronDown className={`w-4 h-4 transition-transform ${showLanguageDropdown ? 'rotate-180' : ''}`} />
              </button>

              {showLanguageDropdown && (
                <div className="absolute top-full left-0 mt-2 bg-white rounded-xl shadow-xl border border-gray-100 py-2 min-w-[200px] z-50">
                  <button
                    onClick={() => { setLanguageFilter(""); setShowLanguageDropdown(false); }}
                    className="w-full px-4 py-2 text-left text-sm hover:bg-gray-50 text-gray-500"
                  >
                    {t("communityMain.filters.allLanguages")}
                  </button>
                  {COMMON_LANGUAGES.map((lang) => (
                    <button
                      key={lang}
                      onClick={() => { setLanguageFilter(lang); setShowLanguageDropdown(false); }}
                      className={`w-full px-4 py-2 text-left text-sm hover:bg-gray-50 flex items-center gap-2 ${
                        languageFilter === lang ? 'bg-teal-50 text-teal-600' : 'text-gray-700'
                      }`}
                    >
                      <span>{LANGUAGE_FLAGS[getLanguageCode(lang)] || "🌐"}</span>
                      {lang}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Clear Filters */}
            {(languageFilter || filter) && (
              <button
                onClick={() => { setFilter(""); setLanguageFilter(""); }}
                className="flex items-center gap-1 px-3 py-2 text-sm text-gray-500 hover:text-gray-700"
              >
                <X className="w-4 h-4" />
                {t("communityMain.filters.clear")}
              </button>
            )}

            {/* Results count */}
            <div className="ml-auto text-sm text-gray-500">
              {t("communityMain.results.membersFound", { count: filteredMembers.length })}
            </div>
          </div>
        </div>
      </div>

      {/* Members Grid */}
      <div className="max-w-7xl mx-auto px-4 py-8">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin mb-4" />
            <p className="text-gray-500">{t("communityMain.search.loading")}</p>
          </div>
        ) : filteredMembers.length === 0 ? (
          <div className="text-center py-20">
            <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Search className="w-10 h-10 text-gray-300" />
            </div>
            <h3 className="text-xl font-bold text-gray-800 mb-2">{t("communityMain.results.noneFound.title")}</h3>
            <p className="text-gray-500 mb-6">{t("communityMain.results.noneFound.message")}</p>
            <button
              onClick={() => { setFilter(""); setLanguageFilter(""); setActiveTab("all"); }}
              className="px-6 py-3 bg-teal-500 text-white rounded-xl font-medium hover:bg-teal-600 transition-colors"
            >
              {t("communityMain.results.noneFound.resetFilters")}
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredMembers.map((member: any) => (
              <TandemMemberCard
                key={member._id}
                member={member}
                onWave={handleWave}
                onMessage={handleMessage}
              />
            ))}
          </div>
        )}

        {/* Load More */}
        {!isLoading && filteredMembers.length > 0 && hasMore && (
          <div className="text-center mt-12">
            <button
              onClick={handleLoadMore}
              disabled={isFetching}
              className="px-8 py-3 bg-white border-2 border-teal-500 text-teal-600 rounded-xl font-medium hover:bg-teal-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 mx-auto"
            >
              {isFetching ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  {t("communityMain.loadMore.loading")}
                </>
              ) : (
                t("communityMain.loadMore.button")
              )}
            </button>
          </div>
        )}
      </div>

      {/* Bottom CTA */}
      <div className="bg-gradient-to-r from-teal-500 to-emerald-500 text-white py-12">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h2 className="text-2xl sm:text-3xl font-bold mb-4">
            {t("communityMain.cta.title")}
          </h2>
          <p className="text-white/80 mb-6">
            {t("communityMain.cta.description")}
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link
              to="/register"
              className="px-8 py-3 bg-white text-teal-600 rounded-xl font-semibold hover:shadow-lg transition-all"
            >
              {t("communityMain.cta.getStarted")}
            </Link>
            <Link
              to="/waves"
              className="px-8 py-3 bg-white/20 backdrop-blur-sm text-white rounded-xl font-semibold hover:bg-white/30 transition-all"
            >
              {t("communityMain.cta.viewWaves")}
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ModernCommunity;
