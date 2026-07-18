import { useState, useMemo, useCallback, useEffect, useLayoutEffect, useRef } from "react";
import { Loader2, Search } from "lucide-react";
import { useNavigate, Navigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useSelector } from "react-redux";

import {
  useGetCommunityMembersQuery,
  useGetTopicsQuery,
} from "../../store/slices/communitySlice";
import { useGetProfileVisitorsQuery } from "../../store/slices/usersSlice";
import { RootState } from "../../store";
import { useDebounce } from "./utils";

import CommunitySubNav, { CommunityNavTab } from "./tandem/CommunitySubNav";
import HighlightedProfilesCarousel from "./tandem/HighlightedProfilesCarousel";
import VisitorsBanner from "./tandem/VisitorsBanner";
import MemberCard, { CommunityMemberCard } from "./MemberCard";
import CommunityFilterSheet from "./CommunityFilterSheet";
import ActiveFilterChips from "./ActiveFilterChips";
import QuickFilterChips from "./QuickFilterChips";
import WaveSheet from "./WaveSheet";
import { CommunityFilters, buildCommunityQuery } from "./lib/buildCommunityQuery";
import * as filterStorage from "./lib/filterStorage";
import { DEFAULT_FILTERS } from "./lib/filterStorage";
import "./tandem/tandem-community.scss";

const PAGE_LIMIT = 20;

/** Count how many discovery filters are active (drives the SubNav badge). */
const countActiveFilters = (f: CommunityFilters): number => {
  let n = 0;
  if (f.minAge !== undefined && f.minAge > (DEFAULT_FILTERS.minAge ?? 18)) n += 1;
  if (f.maxAge !== undefined && f.maxAge < (DEFAULT_FILTERS.maxAge ?? 100)) n += 1;
  if (f.gender) n += 1;
  if (f.nativeLanguage) n += 1;
  if (f.learningLanguage) n += 1;
  if (f.country) n += 1;
  if (f.languageLevel) n += 1;
  if (f.topics && f.topics.length) n += f.topics.length;
  if (f.topicsAtLeast) n += 1;
  if (f.onlineOnly) n += 1;
  if (f.newUsersOnly) n += 1;
  return n;
};

const ModernCommunity: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  // Search + sort live outside `filters` (search is the SubNav box, sort is a
  // quick chip) but are folded into the query so BOTH hit the DB.
  const [search, setSearch] = useState("");
  const [sort, setSort] = useState<"recently_active" | undefined>(undefined);
  const [filters, setFilters] = useState<CommunityFilters>(() => filterStorage.load());
  const [draftFilters, setDraftFilters] = useState<CommunityFilters>(filters);

  const [activeTab, setActiveTab] = useState<CommunityNavTab>("all");
  const [isFilterSheetOpen, setIsFilterSheetOpen] = useState(false);
  const [waveTarget, setWaveTarget] = useState<CommunityMemberCard | null>(null);
  const [page, setPage] = useState(1);
  // Pages beyond the first are accumulated here so "Load more" keeps prior
  // results visible. Page 1 is derived directly from the RTK Query cache below
  // so returning from /community/:id shows the cached list on the first render
  // instead of flashing the empty state.
  const [extraPages, setExtraPages] = useState<CommunityMemberCard[]>([]);

  const debouncedSearch = useDebounce(search, 300);
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);

  const currentUser = useMemo(
    () => ({
      _id: userInfo?.user?._id,
      name: userInfo?.user?.name,
      imageUrls: userInfo?.user?.imageUrls,
    }),
    [userInfo]
  );

  // `me` drives the default language-exchange match inside buildCommunityQuery
  // (and the quick chips' "Speaks / Learning" labels).
  const me = useMemo(
    () => ({
      native_language: userInfo?.user?.native_language,
      language_to_learn: userInfo?.user?.language_to_learn,
    }),
    [userInfo]
  );

  // Single source of truth for the server query — ALL filters map to real
  // params here (inverted-language semantics handled inside the mapper).
  const queryArg = useMemo(
    () =>
      buildCommunityQuery(
        { ...filters, search: debouncedSearch || undefined, sort },
        me,
        page,
        PAGE_LIMIT
      ),
    [filters, debouncedSearch, sort, me, page]
  );

  const {
    data: communityData,
    isLoading,
    isFetching,
    error: errorInfo,
    refetch,
  } = useGetCommunityMembersQuery(queryArg);

  const { data: topicsResult } = useGetTopicsQuery({});
  const topicLabels = useMemo<Record<string, string>>(() => {
    const raw = topicsResult?.data;
    if (!Array.isArray(raw)) return {};
    const map: Record<string, string> = {};
    for (const topic of raw) {
      const id = topic._id || topic.id || topic.name;
      if (id) map[id] = topic.name;
    }
    return map;
  }, [topicsResult]);

  const { data: visitorsData } = useGetProfileVisitorsQuery(
    { userId: currentUser._id || "", page: 1, limit: 8 },
    { skip: !currentUser._id }
  );

  // Persist scroll position continuously (throttled with rAF).
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

  const hasRestoredScroll = useRef(false);

  // Append "Load more" pages. Page 1 is read off the cache in the useMemo below.
  useEffect(() => {
    if (!communityData?.data || page === 1) return;
    setExtraPages((prev) => {
      const existingIds = new Set(prev.map((m) => m._id));
      const newOnes = (communityData.data as CommunityMemberCard[]).filter(
        (m) => !existingIds.has(m._id)
      );
      return [...prev, ...newOnes];
    });
  }, [communityData, page]);

  // Reset pagination whenever the server query changes (filters / search /
  // sort). Skip the first run so a fresh mount (back-nav from /community/:id)
  // doesn't clobber restored state.
  const filterKey = useMemo(
    () => JSON.stringify({ filters, debouncedSearch, sort }),
    [filters, debouncedSearch, sort]
  );
  const skipFilterReset = useRef(true);
  useEffect(() => {
    if (skipFilterReset.current) {
      skipFilterReset.current = false;
      return;
    }
    setPage(1);
    setExtraPages([]);
  }, [filterKey]);

  // Derived union of the first page (cache) + accumulated extra pages, with a
  // stable VIP-first then online-first tiebreak. `Array.prototype.sort` is
  // stable, so equal-rank members keep server order.
  const allMembers = useMemo<CommunityMemberCard[]>(() => {
    const firstPage = (communityData?.data as CommunityMemberCard[]) || [];
    const merged: CommunityMemberCard[] = [...firstPage];
    if (extraPages.length) {
      const seen = new Set(firstPage.map((m) => m._id));
      for (const m of extraPages) {
        if (!seen.has(m._id)) {
          seen.add(m._id);
          merged.push(m);
        }
      }
    }
    const list = merged.filter((m) => (currentUser._id ? m._id !== currentUser._id : true));
    return list.sort((a, b) => {
      const av = a.isVIP ? 1 : 0;
      const bv = b.isVIP ? 1 : 0;
      if (av !== bv) return bv - av;
      const ao = a.isOnline ? 1 : 0;
      const bo = b.isOnline ? 1 : 0;
      return bo - ao;
    });
  }, [communityData, extraPages, currentUser._id]);

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

  const highlightedProfiles = useMemo(() => {
    const pros = allMembers.filter((m) => m.isVIP);
    const fillers = allMembers.filter((m) => !m.isVIP);
    return [...pros, ...fillers].slice(0, 12);
  }, [allMembers]);

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

  const hasMore = communityData?.data?.length === PAGE_LIMIT;

  const handleLoadMore = useCallback(() => {
    if (!isFetching && hasMore) setPage((p) => p + 1);
  }, [isFetching, hasMore]);

  const openFilterSheet = useCallback(() => {
    setDraftFilters(filters);
    setIsFilterSheetOpen(true);
  }, [filters]);

  const applyFilters = useCallback((next: CommunityFilters) => {
    setFilters(next);
    filterStorage.save(next);
    setIsFilterSheetOpen(false);
  }, []);

  // Reset ALL discovery filters back to defaults (used by the sheet's
  // "Clear all" and the ActiveFilterChips "Clear"). Persisted immediately.
  const clearAllFilters = useCallback(() => {
    const next = { ...DEFAULT_FILTERS };
    setDraftFilters(next);
    setFilters(next);
    filterStorage.save(next);
  }, []);

  // Remove a single active filter chip (or one topic within `topics[]`).
  const removeFilter = useCallback(
    (key: keyof CommunityFilters, topicValue?: string) => {
      setFilters((prev) => {
        const next: CommunityFilters = { ...prev };
        if (key === "topics" && topicValue) {
          const remaining = (prev.topics || []).filter((topic) => topic !== topicValue);
          if (remaining.length) next.topics = remaining;
          else delete next.topics;
        } else if (key === "minAge") {
          next.minAge = DEFAULT_FILTERS.minAge;
        } else if (key === "maxAge") {
          next.maxAge = DEFAULT_FILTERS.maxAge;
        } else {
          delete next[key];
        }
        filterStorage.save(next);
        return next;
      });
    },
    []
  );

  // Quick chips replace the filter object wholesale — persist + reset via the
  // shared applyFilters-style path (no sheet to close, so update inline).
  const handleQuickChange = useCallback((next: CommunityFilters) => {
    setFilters(next);
    filterStorage.save(next);
  }, []);

  const handleOpenMember = useCallback(
    (user: CommunityMemberCard) => {
      navigate(`/community/${user._id}`);
    },
    [navigate]
  );

  // Opens the WaveSheet for the tapped member; the sheet owns the actual
  // send call (useSendWaveMutation) + mutual/already-waved handling.
  const handleWaveMember = useCallback((user: CommunityMemberCard) => {
    setWaveTarget(user);
  }, []);

  const handleResetAll = useCallback(() => {
    setSearch("");
    setSort(undefined);
    clearAllFilters();
    setActiveTab("all");
  }, [clearAllFilters]);

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
        searchValue={search}
        onSearchChange={setSearch}
        onOpenFilters={openFilterSheet}
        hasActiveFilters={activeFilterCount > 0}
        activeFilterCount={activeFilterCount}
      />

      <CommunityFilterSheet
        open={isFilterSheetOpen}
        value={draftFilters}
        onChange={setDraftFilters}
        onApply={applyFilters}
        onClear={clearAllFilters}
        onClose={() => setIsFilterSheetOpen(false)}
      />

      <WaveSheet
        open={!!waveTarget}
        targetUser={waveTarget}
        onClose={() => setWaveTarget(null)}
      />

      <div className="community-page__container">
        <QuickFilterChips
          filters={filters}
          sort={sort}
          me={me}
          onChange={handleQuickChange}
          onSortChange={setSort}
        />

        <ActiveFilterChips
          value={filters}
          onRemove={removeFilter}
          onClear={clearAllFilters}
          topicLabels={topicLabels}
        />

        {highlightedProfiles.length > 0 && (
          <HighlightedProfilesCarousel
            profiles={highlightedProfiles as any}
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
        ) : allMembers.length === 0 ? (
          <div className="community-empty">
            <Search style={{ width: 40, height: 40, color: "#d1d5db", margin: "0 auto 12px", display: "block" }} />
            <h3>{t("communityMain.results.noneFound.title") || "No members found"}</h3>
            <p>{t("communityMain.results.noneFound.message") || "Try widening your search or clearing filters."}</p>
            <button
              type="button"
              onClick={handleResetAll}
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
            <div className="flex flex-col gap-3">
              {allMembers.map((member) => (
                <MemberCard
                  key={member._id}
                  user={member}
                  onOpen={handleOpenMember}
                  onWave={handleWaveMember}
                />
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
