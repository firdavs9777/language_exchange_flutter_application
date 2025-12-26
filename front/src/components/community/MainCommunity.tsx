import { useState, useMemo, useEffect, useCallback } from "react";
import { 
  Search, Globe, Sparkles, X, Loader2
} from "lucide-react";
import { useGetCommunityMembersQuery } from "../../store/slices/communitySlice";

import { useTranslation } from "react-i18next";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { COMMON_LANGUAGES, LANGUAGE_FLAGS, LanguageFlagProps, TABS } from "./type";
import {  useDebounce } from "./utils";
import { MemberCard } from "./MemberCard";

export const LanguageFlag: React.FC<LanguageFlagProps> = ({ code }) => (
  <span className="text-2xl">{LANGUAGE_FLAGS[code] || code}</span>
);

// ============= MAIN COMPONENT =============
const ModernCommunity: React.FC = () => {
  // State
  const [filter, setFilter] = useState("");
  const [languageFilter, setLanguageFilter] = useState("");
  const [activeTab, setActiveTab] = useState<TabType>("all");
  const [isLoaded, setIsLoaded] = useState(false);
  const [page] = useState(1);
  
  const debouncedFilter = useDebounce(filter, 300);
  const { t, i18n } = useTranslation();

  // Selectors
  const currentUser = useSelector((state: RootState) => ({
    _id: state.auth.userInfo?.user._id,
    native_language: state.auth.userInfo?.user.native_language,
    language_to_learn: state.auth.userInfo?.user.language_to_learn
  }));

  // API Query
  const {
    data: communityData,
    isLoading,
    error: errorInfo,
    refetch,
  } = useGetCommunityMembersQuery({
    page,
    limit: 20,
    filter: debouncedFilter,
    language: languageFilter,
    sort: activeTab === "popular" ? "popular" : activeTab === "new" ? "newest" : "",
  });

  const members = communityData?.data || [];

  // Effects
  useEffect(() => {
    setIsLoaded(true);
  }, []);

  // Memoized filtered members
  const filteredMembers = useMemo(() => {
    if (!currentUser._id) return [];
    
    let filteredList = members.filter(member => {
      // Exclude current user
      return member._id !== currentUser._id;
    });
    
    // Apply text filter
    if (debouncedFilter?.trim()) {
      const searchTerm = debouncedFilter.toLowerCase();
      filteredList = filteredList.filter(member =>
        [member.name, member.native_language, member.language_to_learn, member.bio]
          .some(field => field?.toLowerCase().includes(searchTerm))
      );
    }
    
    // Apply language filter
    if (languageFilter) {
      filteredList = filteredList.filter(member =>
        member.native_language === languageFilter || 
        member.language_to_learn === languageFilter
      );
    }
    
    // Apply tab sorting
    switch (activeTab) {
      case "popular":
        return filteredList.sort(() => Math.random() - 0.5).slice(0, 6);
      case "new":
        return filteredList.slice(-4);
      default:
        return filteredList;
    }
  }, [members, currentUser, debouncedFilter, languageFilter, activeTab]);
  // Event handlers
  const handleMemberClick = useCallback((memberId: string) => {
    console.log(`Navigate to member: ${memberId}`);
  }, []);

  const handleFilterChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setFilter(e.target.value);
  }, []);

  const handleLanguageFilterChange = useCallback((language: string) => {
    setLanguageFilter(prev => prev === language ? "" : language);
  }, []);

  const handleTabChange = useCallback((tab: TabType) => {
    setActiveTab(tab);
  }, []);

  const clearFilters = useCallback(() => {
    setFilter("");
    setLanguageFilter("");
  }, []);

  // Error handling
  if (errorInfo) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 flex items-center justify-center">
        <div className="text-center text-white">
          <h2 className="text-2xl font-bold mb-4">{t("communityMain.errors.generic")}</h2>
          <p className="mb-4">{String(errorInfo)}</p>
          <button 
            onClick={refetch}
            className="bg-gradient-to-r from-pink-500 to-purple-500 px-6 py-3 rounded-full font-medium hover:scale-105 transition-transform"
          >
            {t("communityMain.errors.tryAgain")}
          </button>
        </div>
      </div>
    );
  }

  const count = filteredMembers.length;
  const plural = count !== 1 ? (i18n.language === 'ko' ? '들' : 's') : '';

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 relative overflow-hidden p-0 m-0">
      {/* Animated background elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-pink-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-yellow-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse"></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-80 h-80 bg-green-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse"></div>
      </div>
      {Array.from({ length: 15 }, (_, i) => (
        <div
          key={i}
          className="absolute opacity-20 animate-bounce"
          style={{
            left: `${Math.random() * 100}%`,
            top: `${Math.random() * 100}%`,
            animationDelay: `${Math.random() * 3}s`,
            animationDuration: `${3 + Math.random() * 2}s`
          }}
        >
          <Sparkles className="text-white w-4 h-4" />
        </div>
      ))}

      <div className={`relative z-10 container mx-auto px-4 py-6 sm:py-8 transition-all duration-1000 ${isLoaded ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'}`}>
        {/* Header */}
        <header className="text-center mb-8 sm:mb-12">
          <h1 className="text-4xl sm:text-5xl md:text-6xl font-bold bg-gradient-to-r from-pink-400 via-purple-400 to-blue-400 bg-clip-text text-transparent mb-4">
            {t("communityMain.title")}
          </h1>
          <p className="text-lg sm:text-xl text-white text-opacity-80 mb-6 sm:mb-8">
            {t("communityMain.subtitle")}
          </p>
          
          {/* Stats */}
          <div className="flex justify-center space-x-4 sm:space-x-8 mb-6 sm:mb-8">
            {[
              { value: `${members.length}+`, label: t("communityMain.stats.activeLearners") },
              { value: "50+", label: t("communityMain.stats.languages") },
              { value: "180+", label: t("communityMain.stats.countries") }
            ].map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-2xl sm:text-3xl font-bold text-white">{stat.value}</div>
                <div className="text-xs sm:text-sm text-white text-opacity-70">{stat.label}</div>
              </div>
            ))}
          </div>
        </header>

        {/* Search and Filters */}
        <div className="max-w-4xl mx-auto mb-8 sm:mb-12 space-y-4 sm:space-y-6">
          {/* Search Bar */}
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-pink-500 to-purple-500 rounded-2xl opacity-75 blur"></div>
            <div className="relative bg-white bg-opacity-10 backdrop-blur-md rounded-2xl p-1">
              <div className="flex items-center bg-white bg-opacity-5 rounded-xl px-4 sm:px-6 py-3 sm:py-4">
                <Search className="w-5 h-5 sm:w-6 sm:h-6 text-white text-opacity-60 mr-3 sm:mr-4" />
                <input
                  type="text"
                  placeholder={t("communityMain.search.placeholder")}
                  value={filter}
                  onChange={handleFilterChange}
                  className="flex-1 bg-transparent text-white placeholder-white placeholder-opacity-60 outline-none text-base sm:text-lg"
                />
                {filter && (
                  <button
                    onClick={() => setFilter("")}
                    className="ml-4 p-2 hover:bg-white hover:bg-opacity-10 rounded-full transition-colors"
                    aria-label="Clear search"
                  >
                    <X className="w-4 h-4 sm:w-5 sm:h-5 text-white" />
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Language Filter Pills */}
          <div className="flex flex-wrap justify-center gap-2 sm:gap-3">
            {COMMON_LANGUAGES.map((language) => (
              <button
                key={language}
                onClick={() => handleLanguageFilterChange(language)}
                className={`px-3 sm:px-6 py-2 sm:py-3 rounded-full font-medium transition-all duration-300 hover:scale-105 text-sm sm:text-base ${
                  languageFilter === language
                    ? 'bg-gradient-to-r from-pink-500 to-purple-500 text-white shadow-lg'
                    : 'bg-white bg-opacity-10 backdrop-blur-sm text-white text-opacity-90 hover:bg-opacity-20'
                }`}
              >
                {language}
              </button>
            ))}
          </div>

          {/* Tabs */}
          <div className="flex justify-center">
            <div className="bg-white bg-opacity-10 backdrop-blur-md rounded-2xl p-1">
              {TABS.map(({ id, label, icon: Icon }) => (
                <button
                  key={id}
                  onClick={() => handleTabChange(id)}
                  className={`flex items-center space-x-1 sm:space-x-2 px-3 sm:px-6 py-2 sm:py-3 rounded-xl font-medium transition-all duration-300 text-sm sm:text-base ${
                    activeTab === id
                      ? 'bg-gradient-to-r from-pink-500 to-purple-500 text-white shadow-lg'
                      : 'text-white text-opacity-70 hover:text-white hover:bg-white hover:bg-opacity-10'
                  }`}
                >
                  <Icon className="w-4 h-4 sm:w-5 sm:h-5" />
                  <span className="hidden sm:inline">{label}</span>
                  <span className="sm:hidden">{label.substring(0, 3)}</span>
                </button>
              ))}
            </div>
          </div>
        </div>
        {isLoading && (
          <div className="flex justify-center items-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-white" />
            <span className="ml-2 text-white">{t("communityMain.search.loading")}</span>
          </div>
        )}

        {/* Results count */}
        {!isLoading && filteredMembers.length > 0 && (
          <div className="text-center mb-6 sm:mb-8">
            <div className="inline-flex items-center space-x-2 bg-white bg-opacity-10 backdrop-blur-sm rounded-full px-4 sm:px-6 py-2 sm:py-3">
              <Globe className="w-4 h-4 sm:w-5 sm:h-5 text-white text-opacity-70" />
              <span className="text-white text-opacity-90 text-sm sm:text-base">
                {t('communityMain.results.showing', { count, plural })}
              </span>
            </div>
          </div>
        )}

        {/* Members Grid */}
        {!isLoading && filteredMembers.length === 0 ? (
          <div className="text-center py-12 sm:py-20">
            <div className="text-5xl sm:text-6xl mb-4">🌍</div>
            <h3 className="text-xl sm:text-2xl font-bold text-white mb-4">
              {t("communityMain.results.noneFound.title")}
            </h3>
            <p className="text-white text-opacity-70 mb-6 sm:mb-8 px-4">
              {t("communityMain.results.noneFound.message")}
            </p>
            {(filter || languageFilter) && (
              <button
                onClick={clearFilters}
                className="bg-gradient-to-r from-pink-500 to-purple-500 text-white px-6 sm:px-8 py-2 sm:py-3 rounded-full font-medium hover:scale-105 transition-transform shadow-lg text-sm sm:text-base"
              >
                {t("communityMain.results.noneFound.resetFilters")}
              </button>
            )}
          </div>
        ) : !isLoading && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6 lg:gap-8">
            {filteredMembers.map((member:any ) => (
              <MemberCard 
                key={member._id} 
                member={member} 
                onMemberClick={handleMemberClick}
              />
            ))}
          </div>
        )}
        {!isLoading && (filter || languageFilter) && filteredMembers.length > 0 && (
          <div className="text-center mt-8 sm:mt-12">
            <button
              onClick={clearFilters}
              className="bg-white bg-opacity-10 backdrop-blur-sm text-white px-6 sm:px-8 py-2 sm:py-3 rounded-full font-medium hover:bg-opacity-20 transition-all duration-300 hover:scale-105 text-sm sm:text-base"
            >
              {t("communityMain.buttons.clearFilters")}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default ModernCommunity;