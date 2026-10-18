import React, { useMemo, useState } from "react";
import { Link, Navigate, useLocation, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { Crown, Eye, History, RefreshCw, Search, Trash2, UserPlus, Users } from "lucide-react";
import PageMeta from "../../seo/PageMeta";
import SurfaceCard from "../../design/SurfaceCard";
import Avatar from "../../design/Avatar";
import ConfirmDialog from "../../design/ConfirmDialog";
import LanguageExchangePill from "../../design/LanguageExchangePill";
import useFollowToggle from "./useFollowToggle";
import {
  useGetFollowersQuery,
  useGetFollowingsQuery,
  useGetProfileVisitorsQuery,
  useGetVisitedProfilesQuery,
  useClearVisitorsMutation,
} from "../../store/slices/usersSlice";
import { useGetCommunityDetailsQuery } from "../../store/slices/communitySlice";
import timeAgo from "../../utils/timeAgo";

type Tab = "followers" | "following" | "visitors" | "visited";

interface PersonRowData {
  id: string;
  name: string;
  avatar: string;
  native: string;
  learning: string;
  /** Visitors: when they last came by. Visited: when you last went. */
  visitedAt?: string;
}

/** The grey rows that stand in for the list while it loads. */
const SKELETONS = [0, 1, 2, 3, 4, 5];

const PAGE = "min-h-screen bg-canvas dark:bg-canvas-dark";
const COLUMN = "mx-auto w-full min-w-0 max-w-3xl px-3 pb-16 pt-4 sm:px-4 sm:pt-6";
// `shrink-0` + `whitespace-nowrap` keeps a tab's label on one line; the nav
// scrolls instead of widening the document, which is what three tabs did at
// 390px. `flex-1` still spreads them across the bar when there is room.
const TAB =
  "flex flex-1 shrink-0 items-center justify-center gap-1.5 whitespace-nowrap rounded-chip px-3 py-2 text-sm font-semibold transition-colors";
const TAB_ON = "bg-surface text-brand-deep shadow-card dark:bg-cardbg-dark dark:text-brand-light";
const TAB_OFF = "text-ink-500 hover:text-ink-700 dark:text-ink-400 dark:hover:text-ink-200";
const CTA =
  "inline-flex items-center justify-center gap-1.5 rounded-chip bg-brand-deep px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-brand-dark";

/**
 * Which list the URL is asking for.
 *
 * The path is the single source of truth — the tabs are links, not local
 * state — so a tab is shareable, survives a reload and answers the back
 * button. The three own-list paths predate this page and are kept verbatim so
 * every existing link into them still works.
 */
export function tabForPath(pathname: string): Tab {
  const path = (pathname || "").toLowerCase().replace(/\/+$/, "");
  const endsWith = (suffix: string): boolean =>
    path.length >= suffix.length && path.lastIndexOf(suffix) === path.length - suffix.length;

  if (path === "/visitors") return "visitors";
  if (path === "/visited") return "visited";
  if (path === "/followingslist" || endsWith("/following")) return "following";
  return "followers";
}

/** A visitors row wraps the person; a followers/following row is the person. */
function personOf(entry: any): any {
  if (!entry || typeof entry !== "object") return null;
  if (entry.user && typeof entry.user === "object") return entry.user;
  return entry;
}

function firstImage(person: any): string {
  const urls = person.imageUrls || person.images;
  if (Array.isArray(urls)) {
    for (let i = 0; i < urls.length; i += 1) {
      const url = typeof urls[i] === "string" ? urls[i].trim() : "";
      if (url) return url;
    }
  }
  return typeof person.photo === "string" ? person.photo : "";
}

function rowsOf(payload: any): PersonRowData[] {
  const list = payload && Array.isArray(payload.data) ? payload.data : [];
  const rows: PersonRowData[] = [];
  for (let i = 0; i < list.length; i += 1) {
    const entry = list[i];
    const person = personOf(entry);
    const id = person ? String(person._id || person.id || "") : "";
    if (!id) continue;
    rows.push({
      id,
      name: String(person.name || person.username || ""),
      avatar: firstImage(person),
      native: person.native_language || person.nativeLanguage || "",
      learning: person.language_to_learn || person.languageToLearn || "",
      // `lastVisit` on who-viewed-me, `visitedAt` on who-I-viewed.
      visitedAt:
        entry && typeof entry.lastVisit === "string"
          ? entry.lastVisit
          : entry && typeof entry.visitedAt === "string"
          ? entry.visitedAt
          : undefined,
    });
  }
  return rows;
}

/** The ids the viewer already follows, so every row starts on the right label. */
function idsOf(payload: any): { [id: string]: boolean } {
  const map: { [id: string]: boolean } = {};
  const list = payload && Array.isArray(payload.data) ? payload.data : [];
  for (let i = 0; i < list.length; i += 1) {
    const person = personOf(list[i]);
    const id = person ? String(person._id || person.id || "") : "";
    if (id) map[id] = true;
  }
  return map;
}

/**
 * The visitor counters the endpoint sends alongside the list, in display
 * order. A field the response omits yields no tile — `GET /users/:id/visitors`
 * has only ever returned `stats` for some accounts, and a zero drawn for a
 * number the server never sent is a number we made up.
 */
const VISITOR_STATS: Array<{ field: string; key: string; fallback: string }> = [
  { field: "totalVisits", key: "profile.visitors.total_visits", fallback: "Total Visits" },
  { field: "uniqueVisitors", key: "profile.visitors.unique_visitors", fallback: "Unique Visitors" },
  { field: "visitsToday", key: "profile.visitors.visits_today", fallback: "Today" },
  { field: "visitsThisWeek", key: "profile.visitors.visits_week", fallback: "This Week" },
];

interface VisitorStatsRowProps {
  /** The visitors response, unvalidated. */
  payload: any;
}

/** Total / unique / today / this week, restored from the old visitors page. */
const VisitorStatsRow: React.FC<VisitorStatsRowProps> = ({ payload }) => {
  const { t } = useTranslation();
  const stats = payload && payload.stats;
  if (!stats || typeof stats !== "object") return null;

  const tiles = VISITOR_STATS.filter(
    (entry) => typeof stats[entry.field] === "number" && isFinite(stats[entry.field])
  );
  if (tiles.length === 0) return null;

  return (
    <dl
      data-testid="visitor-stats"
      className="grid grid-cols-2 gap-2 pb-3 sm:grid-cols-4"
    >
      {tiles.map((entry) => (
        <div
          key={entry.field}
          data-testid={`visitor-stat-${entry.field}`}
          className="rounded-chip bg-ink-100 px-3 py-2 text-center dark:bg-ink-800"
        >
          <dt className="text-[11px] font-semibold uppercase tracking-wide text-ink-500 dark:text-ink-400">
            {t(entry.key) || entry.fallback}
          </dt>
          <dd className="pt-0.5 font-display text-lg text-ink-900 dark:text-ink-50">
            {stats[entry.field]}
          </dd>
        </div>
      ))}
    </dl>
  );
};

interface PersonRowProps {
  row: PersonRowData;
  /** The signed-in user. No viewer, or the viewer's own row: no button. */
  viewerId?: string;
  isFollowing: boolean;
}

const PersonRow: React.FC<PersonRowProps> = ({ row, viewerId, isFollowing }) => {
  const { t } = useTranslation();
  const { following, busy, toggle } = useFollowToggle(row.id, isFollowing);
  const showFollow = Boolean(viewerId) && row.id !== viewerId;
  // Shared helper, same four moments keys. `beyondWeek: "days"` keeps this
  // page's behaviour: a visit from last spring reads "342d", not a date --
  // here the distance is the point, not the day it happened on.
  const visited = timeAgo(row.visitedAt, t, { beyondWeek: "days" });

  return (
    <li data-testid={`list-row-${row.id}`} className="flex items-center gap-3 py-2.5">
      {/* Out of the tab order, but NOT `aria-hidden`: an element that is still
          focusable and clickable must stay in the accessibility tree (WCAG
          4.1.2, axe `aria-hidden-focus`). The Avatar's alt/label names the
          link, so it is announced rather than being an anonymous link; the
          keyboard still reaches the row exactly once, through the name. */}
      <Link to={`/profile/${row.id}`} tabIndex={-1} className="shrink-0">
        <Avatar src={row.avatar || undefined} name={row.name} size={40} />
      </Link>

      <div className="min-w-0 flex-1">
        <Link
          to={`/profile/${row.id}`}
          data-testid={`list-name-${row.id}`}
          className="block truncate text-sm font-semibold text-ink-900 hover:underline dark:text-ink-50"
        >
          {row.name}
        </Link>
        <div className="flex items-center gap-2 pt-1">
          {row.native && row.learning && (
            // No `languageLevel`: the followers/following/visitors populate
            // selects `name images bio gender mbti location language_to_learn
            // native_language` (controllers/users.js) and never sends it, so
            // reading it here only ever produced `undefined`. The pill renders
            // without its CEFR dots, which is the truthful list row.
            <LanguageExchangePill
              nativeLanguage={row.native}
              learningLanguage={row.learning}
              dense
            />
          )}
          {visited && (
            <span className="truncate text-[11px] text-ink-500 dark:text-ink-400">{visited}</span>
          )}
        </div>
      </div>

      {showFollow && (
        <button
          type="button"
          data-testid={`list-follow-${row.id}`}
          onClick={toggle}
          disabled={busy}
          aria-pressed={following}
          className={`shrink-0 rounded-chip border px-3 py-1.5 text-xs font-bold transition-colors disabled:opacity-60 ${
            following
              ? "border-line text-ink-600 hover:bg-ink-100 dark:border-line-dark dark:text-ink-300 dark:hover:bg-ink-800"
              : "border-brand text-brand-dark hover:bg-brand/[0.08] dark:text-brand-light"
          }`}
        >
          {following
            ? t("profile.actions.following") || "Following"
            : t("profile.actions.follow") || "Follow"}
        </button>
      )}
    </li>
  );
};

const ListSkeleton: React.FC = () => (
  <ul data-testid="list-skeleton" aria-busy="true" className="animate-pulse">
    {SKELETONS.map((i) => (
      <li key={i} className="flex items-center gap-3 py-2.5">
        <div className="h-10 w-10 shrink-0 rounded-full bg-ink-100 dark:bg-ink-800" />
        <div className="flex-1 space-y-2">
          <div className="h-3 w-32 rounded-chip bg-ink-100 dark:bg-ink-800" />
          <div className="h-3 w-20 rounded-chip bg-ink-100 dark:bg-ink-800" />
        </div>
        <div className="h-7 w-20 shrink-0 rounded-chip bg-ink-100 dark:bg-ink-800" />
      </li>
    ))}
  </ul>
);

/**
 * Followers, following and visitors — one page, three tabs.
 *
 * It answers five paths: the three own-list paths that predate it
 * (`/followersList`, `/followingsList`, `/visitors`, kept so old links still
 * land) and `/profile/:userId/followers` / `/profile/:userId/following`, which
 * the profile's stat tiles link to. Whose lists these are comes from the route
 * param, exactly as the profile page decides it; another person's lists carry
 * no Visitors tab, because visitors are the owner's alone.
 *
 * Only the open tab is fetched. The viewer's own following list is fetched
 * alongside it, which is what lets every row start on the right label instead
 * of claiming "Follow" for someone the viewer already follows.
 */
const UserListPage: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  const location = useLocation();
  const { t } = useTranslation();

  const viewerId = useSelector(
    (state: any) => state.auth.userInfo?.user?._id || state.auth.userInfo?._id
  );
  const isOwn = !userId || userId === viewerId;
  const ownerId = userId || viewerId || "";
  const tab = tabForPath(location.pathname);
  // Visitors is an own-profile idea; a tab bar that offered it on someone
  // else's list would be offering a page that does not exist.
  const activeTab: Tab = (tab === "visitors" || tab === "visited") && !isOwn ? "followers" : tab;

  const [query, setQuery] = useState("");

  // DELETE /me/visitors removes every visit to this profile and zeroes the
  // counters. Irreversible, so it goes through a confirmation, and a failure
  // stays in the dialog rather than closing it as though it had worked.
  const [clearVisitors, { isLoading: clearing }] = useClearVisitorsMutation();
  const [confirmClear, setConfirmClear] = useState(false);
  const [clearError, setClearError] = useState("");

  const followers = useGetFollowersQuery(
    { userId: ownerId },
    { skip: !ownerId || activeTab !== "followers" }
  );
  const following = useGetFollowingsQuery(
    { userId: ownerId },
    { skip: !ownerId || activeTab !== "following" }
  );
  const visitors = useGetProfileVisitorsQuery(
    { userId: ownerId, page: 1, limit: 50 },
    { skip: !ownerId || activeTab !== "visitors" || !isOwn }
  );
  // Profiles the viewer opened, newest first. Not paywalled — it is your own
  // browsing — and the server drops rows for accounts deleted since.
  const visited = useGetVisitedProfilesQuery(
    { limit: 50 },
    { skip: !viewerId || activeTab !== "visited" || !isOwn }
  );
  // The viewer's own following list, for the row labels. On an own "Following"
  // tab this is the identical query argument, which RTK Query serves once.
  const viewerFollowing = useGetFollowingsQuery(
    { userId: viewerId || "" },
    { skip: !viewerId }
  );

  // Another person's lists name them in the heading; their profile is
  // already in the cache whenever the viewer arrived from it.
  const owner = useGetCommunityDetailsQuery(userId || "", { skip: !userId });
  const ownerName = String(
    ((owner.data as any) && (owner.data as any).data && (owner.data as any).data.name) || ""
  );

  const active: any =
    activeTab === "followers"
      ? followers
      : activeTab === "following"
      ? following
      : activeTab === "visited"
      ? visited
      : visitors;

  const rows = useMemo(() => rowsOf(active.data), [active.data]);

  const handleClear = async (): Promise<void> => {
    setClearError("");
    try {
      await clearVisitors(undefined).unwrap();
      setConfirmClear(false);
      // The list is not tagged by anything the mutation invalidates, so it is
      // refetched by hand rather than left showing the people just removed.
      if (visitors.refetch) visitors.refetch();
    } catch (error) {
      setClearError(
        t("profile.lists.error_body") || "Check your connection and try again."
      );
    }
  };
  const followingIds = useMemo(() => idsOf(viewerFollowing.data), [viewerFollowing.data]);

  const needle = query.trim().toLowerCase();
  const visible = useMemo(
    () => (needle ? rows.filter((row) => row.name.toLowerCase().indexOf(needle) > -1) : rows),
    [rows, needle]
  );

  // A signed-out visitor has no own lists to show — and `/followersList` and
  // friends carry no id to fall back on (routes.tsx guards nothing itself).
  if (!userId && !viewerId) return <Navigate to="/login" replace />;

  const tabs: Array<{ key: Tab; to: string; label: string; icon: any }> = [
    {
      key: "followers",
      to: userId ? `/profile/${userId}/followers` : "/followersList",
      label: t("profile.stats.followers") || "Followers",
      icon: Users,
    },
    {
      key: "following",
      to: userId ? `/profile/${userId}/following` : "/followingsList",
      label: t("profile.stats.following") || "Following",
      icon: UserPlus,
    },
  ];
  if (isOwn) {
    tabs.push({
      key: "visitors",
      to: "/visitors",
      label: t("profile.stats.visitors") || "Visitors",
      icon: Eye,
    });
    tabs.push({
      key: "visited",
      to: "/visited",
      label: t("profile.stats.visited") || "Visited",
      icon: History,
    });
  }

  const activeLabel = (tabs.filter((entry) => entry.key === activeTab)[0] || tabs[0]).label;
  let heading: string;
  if (isOwn) {
    heading = t("profile.lists.title") || "Your connections";
  } else if (ownerName) {
    heading = t("profile.lists.title_of", { name: ownerName }) || `${ownerName}'s connections`;
  } else {
    // Their name has not arrived yet; a heading is still needed above the tabs.
    heading = t("profile.lists.title_other") || "Connections";
  }

  // Who may see this list is the server's ruling, and it sends it: `locked` is
  // the NUMBER of visitors `controllers/profileVisits.js` withheld, 0 when it
  // withheld none. Deciding it here instead — from the VIP status endpoint —
  // locked out everyone the server would have let in by another door: an
  // active `who_waved` grant (24h, bought with coins) and a VIP inside the
  // expiry grace period both open the list there, and neither reports
  // `isActive`. Someone who had just spent coins on exactly this was shown an
  // ad for it.
  const withheld = Number((visitors.data as any)?.locked) || 0;
  const locked = activeTab === "visitors" && withheld > 0;
  const loading = Boolean(active.isLoading);
  const failed = !loading && Boolean(active.error);
  const empty = !loading && !failed && rows.length === 0;
  const searchEmpty = !loading && !failed && rows.length > 0 && visible.length === 0;

  const emptyCopy = (): string => {
    if (activeTab === "visitors") {
      return t("profile.visitors.no_visitors_desc") || "When people visit your profile, they'll appear here";
    }
    if (activeTab === "visited") {
      return t("profile.visitors.no_visited") || "Profiles you look at will appear here";
    }
    if (activeTab === "following") {
      return isOwn
        ? t("profile.lists.empty_following_own") || "You are not following anyone yet."
        : t("profile.lists.empty_following_other") || "They are not following anyone yet.";
    }
    return isOwn
      ? t("profile.lists.empty_followers_own") || "Nobody follows you yet."
      : t("profile.lists.empty_followers_other") || "Nobody follows them yet.";
  };

  const searchLabel = t("profile.lists.search") || "Search by name";

  return (
    <div className={PAGE}>
      <PageMeta noindex title={`${activeLabel} · BananaTalk`} />
      <div className={COLUMN}>
        <div data-testid="list-page" className="space-y-3">
          <div className="flex items-baseline gap-2">
            <h1 className="font-display text-xl text-ink-900 dark:text-ink-50">{heading}</h1>
            {!loading && !failed && rows.length > 0 && (
              <span data-testid="list-count" className="text-sm text-ink-500 dark:text-ink-400">
                {/* What the list below actually shows: with a search active
                    the unfiltered total contradicts the rows on screen. */}
                {visible.length}
              </span>
            )}
          </div>

          <nav
            aria-label={heading}
            data-testid="list-tabs"
            className="flex gap-1 overflow-x-auto rounded-chip bg-ink-100 p-1 dark:bg-ink-800"
          >
            {tabs.map((entry) => {
              const Icon = entry.icon;
              const on = entry.key === activeTab;
              return (
                <Link
                  key={entry.key}
                  to={entry.to}
                  data-testid={`tab-${entry.key}`}
                  aria-current={on ? "page" : undefined}
                  className={`${TAB} ${on ? TAB_ON : TAB_OFF}`}
                >
                  <Icon className="h-4 w-4" aria-hidden />
                  {entry.label}
                </Link>
              );
            })}
          </nav>

          {!locked && (
            <div className="relative">
              <Search
                className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-400"
                aria-hidden
              />
              <input
                type="search"
                data-testid="list-search"
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                aria-label={searchLabel}
                placeholder={searchLabel}
                className="w-full rounded-chip border border-line bg-surface py-2 pl-9 pr-3 text-sm text-ink-900 placeholder:text-ink-400 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50"
              />
            </div>
          )}

          <SurfaceCard padding="lg">
            {activeTab === "visitors" && !loading && !failed && (
              <VisitorStatsRow payload={visitors.data} />
            )}

            {activeTab === "visitors" && !loading && !failed && rows.length > 0 && (
              <div className="flex justify-end pb-2">
                <button
                  type="button"
                  data-testid="visitors-clear"
                  onClick={() => setConfirmClear(true)}
                  className="inline-flex min-h-[40px] items-center gap-1.5 rounded-chip px-3 text-sm font-semibold text-ink-500 hover:bg-ink-50 hover:text-ink-700 dark:text-ink-400 dark:hover:bg-white/5"
                >
                  <Trash2 className="h-4 w-4" aria-hidden />
                  {t("profile.visitors.clear") || "Clear history"}
                </button>
              </div>
            )}

            {loading && <ListSkeleton />}

            {failed && (
              <div data-testid="list-error" role="alert" className="py-4 text-center">
                <h2 className="font-display text-lg text-ink-900 dark:text-ink-50">
                  {t("profile.lists.error_title") || "We couldn't load this list"}
                </h2>
                <p className="pt-1 text-sm text-ink-500 dark:text-ink-400">
                  {t("profile.lists.error_body") || "Check your connection and try again."}
                </p>
                <button
                  type="button"
                  data-testid="list-retry"
                  onClick={active.refetch}
                  className={`mt-4 ${CTA}`}
                >
                  <RefreshCw className="h-4 w-4" aria-hidden />
                  {t("profile.lists.retry") || "Try again"}
                </button>
              </div>
            )}

            {empty && (
              <p
                data-testid="list-empty"
                className="py-6 text-center text-sm text-ink-500 dark:text-ink-400"
              >
                {emptyCopy()}
              </p>
            )}

            {searchEmpty && (
              <p
                data-testid="list-search-empty"
                className="py-6 text-center text-sm text-ink-500 dark:text-ink-400"
              >
                {t("profile.lists.search_empty", { query: query.trim() }) ||
                  `No one here matches "${query.trim()}"`}
              </p>
            )}

            {!loading && !failed && visible.length > 0 && (
              <ul className="divide-y divide-line dark:divide-line-dark">
                {visible.map((row) => (
                  <PersonRow
                    key={row.id}
                    row={row}
                    viewerId={viewerId}
                    isFollowing={Boolean(followingIds[row.id])}
                  />
                ))}
              </ul>
            )}

            {locked && !loading && !failed && (
              <div
                data-testid="visitors-locked"
                className="border-t border-line py-4 text-center dark:border-line-dark"
              >
                <Crown className="mx-auto h-8 w-8 text-banana-dark" aria-hidden />
                <h2 className="pt-3 font-display text-lg text-ink-900 dark:text-ink-50">
                  {t("profile.visitors.vipOnly") || "VIP Feature"}
                </h2>
                <p className="mx-auto max-w-sm pt-1 text-sm text-ink-500 dark:text-ink-400">
                  {t("profile.visitors.vipOnlyDesc") ||
                    "See who visited your profile by upgrading to VIP. This feature is available exclusively for VIP members."}
                </p>
                <Link to="/settings/vip" data-testid="visitors-vip-link" className={`mt-4 ${CTA}`}>
                  {t("profile.visitors.learnMore") || "Learn More About VIP"}
                </Link>
              </div>
            )}
          </SurfaceCard>
        </div>
      </div>

      <ConfirmDialog
        open={confirmClear}
        danger
        title={t("profile.visitors.clear_title") || "Clear your visitor history?"}
        body={
          t("profile.visitors.clear_body") ||
          "Everyone who viewed your profile is removed, and your visit counters go back to zero. This cannot be undone."
        }
        confirmLabel={t("profile.visitors.clear") || "Clear history"}
        cancelLabel={t("profile.actions.cancel") || "Cancel"}
        busy={clearing}
        error={clearError || undefined}
        onConfirm={handleClear}
        onCancel={() => {
          setConfirmClear(false);
          setClearError("");
        }}
      />
    </div>
  );
};

export default UserListPage;
