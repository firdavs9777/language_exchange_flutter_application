import { useState, useMemo, useCallback, useEffect, useLayoutEffect, useRef } from "react";
import { Loader2, Search } from "lucide-react";
import { useGetCommunityMembersQuery } from "../../store/slices/communitySlice";
import { useGetProfileVisitorsQuery } from "../../store/slices/usersSlice";
import { useTranslation } from "react-i18next";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { LANGUAGE_FLAGS, LanguageFlagProps } from "./type";
import { useDebounce } from "./utils";
import { Navigate } from "react-router-dom";

import CommunitySubNav, { CommunityNavTab } from "./tandem/CommunitySubNav";
import HighlightedProfilesCarousel from "./tandem/HighlightedProfilesCarousel";
import VisitorsBanner from "./tandem/VisitorsBanner";
import TandemMemberCard, { TandemMember } from "./tandem/TandemMemberCard";
import CommunityFilterSheet, {
  CommunityFilters,
  EMPTY_FILTERS,
  countActiveFilters,
} from "./tandem/CommunityFilterSheet";
import "./tandem/tandem-community.scss";

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;
const isRecentlyJoined = (createdAt?: string): boolean => {
  if (!createdAt) return false;
  const t = new Date(createdAt).getTime();
  return !Number.isNaN(t) && Date.now() - t < SEVEN_DAYS_MS;
};

// Re-exported so other files (legacy MemberCard, etc.) can keep importing it.
export const LanguageFlag: React.FC<LanguageFlagProps> = ({ code }) => (
  <span style={{ fontSize: "1rem" }}>{LANGUAGE_FLAGS[code] || code}</span>
);

const getLanguageCode = (language: string): string => {
  const codes: Record<string, string> = {
    English: "en",
    Spanish: "es",
    French: "fr",
    German: "de",
    Italian: "it",
    Portuguese: "pt",
    Russian: "ru",
    Japanese: "ja",
    Korean: "ko",
    Chinese: "zh",
    Uzbek: "uz",
    Turkish: "tr",
    Arabic: "ar",
  };
  return codes[language] || language.substring(0, 2).toLowerCase();
};

const ModernCommunity: React.FC = () => {
  const { t } = useTranslation();
  const [filter, setFilter] = useState("");
  const [filters, setFilters] = useState<CommunityFilters>(EMPTY_FILTERS);
  const [activeTab, setActiveTab] = useState<CommunityNavTab>("all");
  const [isFilterSheetOpen, setIsFilterSheetOpen] = useState(false);
  const [page, setPage] = useState(1);
  // Pages beyond the first are accumulated here so "Load more" keeps prior
  // results visible. Page 1 itself is derived directly from the RTK Query
  // cache below — that way, returning from /community/:id shows the cached
  // member list on the FIRST render instead of flashing the empty state
  // while a useEffect copy fires after paint.
  const [extraPages, setExtraPages] = useState<TandemMember[]>([]);

  // Persist scroll position continuously (throttled with rAF) so we never
  // miss a save — relying on unmount alone is fragile because the browser
  // can reset scroll before the cleanup runs in some transitions.
  useEffect(() => {
    let pending = false;
    const onScroll = () => {
      if (pending) return;
      pending = true;
      requestAnimationFrame(() => {
        sessionStorage.setItem("communityScroll", String(window.scrollY));
        pending = false;
      });
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Restore scroll once, after the first batch of members is in the DOM
  // and BEFORE the browser paints. useLayoutEffect runs synchronously
  // after layout, so the user never sees the page at y=0. Using
  // behavior: "instant" overrides scroll-behavior: smooth from App.scss /
  // MainCommunity.css — otherwise the restore would animate visibly.
  const hasRestoredScroll = useRef(false);

  const debouncedFilter = useDebounce(filter, 300);
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const currentUser = useMemo(
    () => ({
      _id: userInfo?.user?._id,
      name: userInfo?.user?.name,
      imageUrls: userInfo?.user?.imageUrls,
    }),
    [userInfo]
  );

  const {
    data: communityData,
    isLoading,
    isFetching,
    error: errorInfo,
    refetch,
  } = useGetCommunityMembersQuery({
    page,
    limit: 20,
    language: filters.language || undefined,
    gender: filters.gender || undefined,
    ageMin: filters.ageMin === "" ? undefined : filters.ageMin,
    ageMax: filters.ageMax === "" ? undefined : filters.ageMax,
  });

  const {
    data: visitorsData,
  } = useGetProfileVisitorsQuery(
    { userId: currentUser._id || "", page: 1, limit: 8 },
    { skip: !currentUser._id }
  );

  // When a "Load more" page arrives, append it to extraPages. Page 1 itself
  // is read directly off the query cache via the useMemo below — no effect
  // round-trip means no first-render flash of the empty state.
  useEffect(() => {
    if (!communityData?.data || page === 1) return;
    setExtraPages((prev) => {
      const existingIds = new Set(prev.map((m) => m._id));
      const newOnes = communityData.data.filter(
        (m: TandemMember) => !existingIds.has(m._id)
      );
      return [...prev, ...newOnes];
    });
  }, [communityData, page]);

  // Reset pagination when filters change. Skip the first run so a fresh
  // mount (back-nav from /community/:id) doesn't clobber state.
  const skipFilterReset = useRef(true);
  useEffect(() => {
    if (skipFilterReset.current) {
      skipFilterReset.current = false;
      return;
    }
    setPage(1);
    setExtraPages([]);
  }, [
    debouncedFilter,
    filters.language,
    filters.gender,
    filters.ageMin,
    filters.ageMax,
  ]);

  // Derived union of the first page (from RTK Query cache, available on the
  // very first render after remount) + any accumulated extra pages.
  const allMembers = useMemo<TandemMember[]>(() => {
    const firstPage: TandemMember[] = communityData?.data || [];
    if (!extraPages.length) return firstPage;
    const seen = new Set(firstPage.map((m) => m._id));
    const merged: TandemMember[] = [...firstPage];
    for (const m of extraPages) {
      if (!seen.has(m._id)) {
        seen.add(m._id);
        merged.push(m);
      }
    }
    return merged;
  }, [communityData, extraPages]);

  // Restore scroll exactly once, the first time the grid has rows.
  useLayoutEffect(() => {
    if (hasRestoredScroll.current) return;
    if (allMembers.length === 0) return;
    const saved = sessionStorage.getItem("communityScroll");
    if (!saved) {
      hasRestoredScroll.current = true;
      return;
    }
    const y = parseInt(saved, 10);
    if (!Number.isNaN(y) && y > 0) {
      window.scrollTo({ top: y, left: 0, behavior: "instant" as ScrollBehavior });
    }
    hasRestoredScroll.current = true;
  }, [allMembers.length]);

  const filteredMembers = useMemo(() => {
    let list: TandemMember[] = allMembers.filter((m) =>
      currentUser._id ? m._id !== currentUser._id : true
    );
    if (debouncedFilter?.trim()) {
      const term = debouncedFilter.toLowerCase();
      list = list.filter((m) =>
        [m.name, m.native_language, m.language_to_learn, m.bio]
          .some((field) => field?.toLowerCase().includes(term))
      );
    }
    if (filters.language) {
      list = list.filter(
        (m) =>
          m.native_language === filters.language ||
          m.language_to_learn === filters.language
      );
    }
    // Client-side filters that the backend doesn't surface natively.
    if (filters.onlineOnly) {
      list = list.filter((m) => m.isOnline);
    }
    if (filters.newOnly) {
      list = list.filter((m) => isRecentlyJoined(m.createdAt));
    }
    return list;
  }, [allMembers, currentUser._id, debouncedFilter, filters]);

  const highlightedProfiles = useMemo(() => {
    const pool = filteredMembers.length ? filteredMembers : allMembers;
    const pros = pool.filter((m) => m.isVIP || m.isVip);
    const fillers = pool.filter((m) => !m.isVIP && !m.isVip);
    return [...pros, ...fillers].slice(0, 12);
  }, [filteredMembers, allMembers]);

  const visitorsList = useMemo(() => {
    const raw = (visitorsData?.data ?? visitorsData?.visitors ?? []) as any[];
    return raw.map((v) => ({
      _id: v._id || v.userId || v.id,
      name: v.name || v.visitorName,
      imageUrls: v.imageUrls || (v.image ? [v.image] : undefined),
      photo: v.photo,
    }));
  }, [visitorsData]);

  const visitorsTotal = useMemo(() => {
    return (
      visitorsData?.totalCount ??
      visitorsData?.total ??
      visitorsList.length ??
      0
    );
  }, [visitorsData, visitorsList]);

  const hasMore = communityData?.data?.length === 20;

  const handleLoadMore = useCallback(() => {
    if (!isFetching && hasMore) setPage((p) => p + 1);
  }, [isFetching, hasMore]);

  const handleResetFilters = useCallback(() => {
    setFilter("");
    setFilters(EMPTY_FILTERS);
    setActiveTab("all");
  }, []);

  const activeFilterCount = useMemo(() => countActiveFilters(filters), [filters]);

  if (!userInfo) {
    return <Navigate to="/login?redirect=/communities" replace />;
  }

  if (errorInfo) {
    return (
      <div className="community-page">
        <div className="community-page__container">
          <div className="community-empty">
            <h3>{t("communityMain.errors.generic") || "Something went wrong"}</h3>
            <p>{t("communityMain.errors.loadError") || "We couldn't load the community."}</p>
            <button
              type="button"
              onClick={() => refetch()}
              className="community-loadmore"
              style={{ background: "#1f2937", color: "#fff", padding: "10px 24px", borderRadius: 999, border: "none", cursor: "pointer" }}
            >
              {t("communityMain.errors.tryAgain") || "Try again"}
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="community-page">
      <CommunitySubNav
        activeTab={activeTab}
        onTabChange={setActiveTab}
        searchValue={filter}
        onSearchChange={setFilter}
        onOpenFilters={() => setIsFilterSheetOpen(true)}
        hasActiveFilters={activeFilterCount > 0}
        activeFilterCount={activeFilterCount}
      />

      <CommunityFilterSheet
        open={isFilterSheetOpen}
        initialFilters={filters}
        onClose={() => setIsFilterSheetOpen(false)}
        onApply={(next) => {
          setFilters(next);
          setIsFilterSheetOpen(false);
        }}
      />

      <div className="community-page__container">
        {highlightedProfiles.length > 0 && (
          <HighlightedProfilesCarousel
            profiles={highlightedProfiles}
            currentUser={currentUser}
          />
        )}

        {visitorsTotal > 0 && (
          <VisitorsBanner visitors={visitorsList} totalCount={visitorsTotal} />
        )}

        {isLoading ? (
          <div className="community-empty">
            <Loader2 className="animate-spin" />
            <p>{t("communityMain.search.loading") || "Loading members..."}</p>
          </div>
        ) : filteredMembers.length === 0 ? (
          <div className="community-empty">
            <Search style={{ width: 40, height: 40, color: "#d1d5db", margin: "0 auto 12px", display: "block" }} />
            <h3>{t("communityMain.results.noneFound.title") || "No members found"}</h3>
            <p>{t("communityMain.results.noneFound.message") || "Try widening your search or clearing filters."}</p>
            <button
              type="button"
              onClick={handleResetFilters}
              style={{
                padding: "10px 24px",
                borderRadius: 999,
                background: "#1f2937",
                color: "#fff",
                border: "none",
                cursor: "pointer",
                fontWeight: 600,
              }}
            >
              {t("communityMain.results.noneFound.resetFilters") || "Reset filters"}
            </button>
          </div>
        ) : (
          <>
            <div className="community-grid">
              {filteredMembers.map((member) => (
                <TandemMemberCard key={member._id} member={member} />
              ))}
            </div>
            {hasMore && (
              <div className="community-loadmore">
                <button
                  type="button"
                  onClick={handleLoadMore}
                  disabled={isFetching}
                >
                  {isFetching
                    ? t("communityMain.loadMore.loading") || "Loading..."
                    : t("communityMain.loadMore.button") || "Load more"}
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default ModernCommunity;
