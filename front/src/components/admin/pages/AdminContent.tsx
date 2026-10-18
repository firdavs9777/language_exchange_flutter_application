import React from "react";
import { useTranslation } from "react-i18next";
import { Link, useSearchParams } from "react-router-dom";
import { Heart, MessageCircle, Eye } from "lucide-react";
import {
  useGetContentStatsQuery,
  useListMomentsQuery,
  useGetAdminClubsQuery,
  useGetAdminGatheringsQuery,
  useCancelAdminGatheringMutation,
} from "../../../store/slices/adminSlice";
import { Badge } from "../../../design";
import StatCard from "../parts/StatCard";
import DataTable from "../parts/DataTable";
import RefreshButton from "../parts/RefreshButton";
import ConfirmDialog from "../parts/ConfirmDialog";
import MomentPreviewDrawer from "../parts/MomentPreviewDrawer";
import ClubDetailDrawer from "../parts/ClubDetailDrawer";
import ReportsTable from "../parts/ReportsTable";

/**
 * The moderation desk: what was posted, who complained, and the two reversible
 * actions a moderator can take.
 *
 * Four lists behind one tab strip, and the tab lives in `?tab=` rather than in
 * component state — a moderator who refreshes after acting (or pastes the URL
 * into a ticket) lands back where they were instead of on Moments.
 *
 * Pagination differs per list, deliberately:
 *  - Moments: `total` is computed against the same filter the page used, so
 *    `page * LIMIT < total` is honest. `reported=true` narrows the page AFTER
 *    the database paginated it, so a short page is NOT the end of the list and
 *    row counting would hide the rest.
 *  - Clubs/gatherings: their `total` ignores `reported` entirely (it counts the
 *    unfiltered match), so there a short page IS the only honest end signal —
 *    the rule the previous version of this page shipped with, kept as it was.
 *  - Reports: `GET /reports` returns the newest 100 unpaginated, so
 *    `ReportsTable` offers filters instead of pages.
 */

const TABS = ["moments", "communities", "gatherings", "reports"];

type Tab = "moments" | "communities" | "gatherings" | "reports";

const LIMIT = 20;
const DEBOUNCE_MS = 300;

/** `—` rather than `0` for a number the backend didn't send: they differ. */
const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString() : "—";

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

/** Enough of a moment's text to recognise it in a row. */
const firstLine = (text: string): string => {
  const line = String(text || "").split("\n")[0].trim();
  return line.length > 80 ? `${line.slice(0, 80)}…` : line;
};

type Pending = { kind: "cancel"; row: any } | null;

const AdminContent: React.FC = () => {
  const { t } = useTranslation();
  const [searchParams, setSearchParams] = useSearchParams();

  const requestedTab = searchParams.get("tab") || "";
  const tab: Tab = (TABS.indexOf(requestedTab) >= 0 ? requestedTab : "moments") as Tab;

  const [text, setText] = React.useState("");
  const [query, setQuery] = React.useState("");
  const [reportedOnly, setReportedOnly] = React.useState(false);
  const [hiddenOnly, setHiddenOnly] = React.useState(false);
  const [page, setPage] = React.useState(1);
  const [selectedMoment, setSelectedMoment] = React.useState<any>(null);
  const [selectedClub, setSelectedClub] = React.useState<any>(null);
  const [pending, setPending] = React.useState<Pending>(null);
  const [actionError, setActionError] = React.useState("");

  // Debounce the search box into `query`; the moments query reads only `query`.
  React.useEffect(() => {
    const timer = setTimeout(() => setQuery(text.trim()), DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [text]);

  // A new filter is a new result set: staying on page 4 of the old one would
  // show an empty table and look like "no results".
  React.useEffect(() => {
    setPage(1);
  }, [query, reportedOnly, hiddenOnly, tab]);

  const stats = useGetContentStatsQuery(undefined as any);

  const moments = useListMomentsQuery(
    {
      page,
      limit: LIMIT,
      q: query || undefined,
      reported: reportedOnly ? true : undefined,
      hidden: hiddenOnly ? true : undefined,
    },
    { skip: tab !== "moments" }
  );
  const clubs = useGetAdminClubsQuery(
    { page, limit: LIMIT, reported: reportedOnly ? true : undefined },
    { skip: tab !== "communities" }
  );
  const gatherings = useGetAdminGatheringsQuery(
    { page, limit: LIMIT, reported: reportedOnly ? true : undefined },
    { skip: tab !== "gatherings" }
  );

  const [cancelGathering, cancelState] = useCancelAdminGatheringMutation();

  const active = tab === "moments" ? moments : tab === "communities" ? clubs : gatherings;
  const rows: any[] = (active.data && active.data.data) || [];
  const total = (active.data && active.data.pagination && active.data.pagination.total) || 0;
  const hasMore =
    tab === "moments" ? page * LIMIT < total : rows.length === LIMIT && page * LIMIT < total;

  const s: any = stats.data || {};
  const loadError = t("admin.common.loadError") || "Couldn't load this section.";
  const loadingText = t("admin.common.loading") || "Loading…";
  const emptyText = t("admin.common.empty") || "Nothing to show yet.";

  const selectTab = (next: Tab) => {
    const params = new URLSearchParams(searchParams);
    params.set("tab", next);
    // Replace rather than push: the tab strip is a view switch, not a place —
    // back should leave the console, not walk the tabs a moderator clicked.
    setSearchParams(params, { replace: true });
  };

  const handleCancel = async (reason: string) => {
    if (!pending) return;
    setActionError("");
    try {
      await cancelGathering({ id: pending.row._id, reason }).unwrap();
      setPending(null);
    } catch (err: any) {
      setActionError(
        (err && err.data && err.data.message) ||
          (err && err.message) ||
          t("admin.common.actionError") ||
          "Something went wrong."
      );
    }
  };

  const statusTone = (status: string) =>
    status === "active" || status === "scheduled" ? "brand" : "banana";

  const personLink = (id: any, name: any) =>
    id ? (
      <Link
        to={`/profile/${id}`}
        onClick={(e) => e.stopPropagation()}
        className="text-brand-deep hover:underline dark:text-brand-light"
      >
        {name || "—"}
      </Link>
    ) : (
      <span className="text-ink-500 dark:text-ink-400">—</span>
    );

  const countPair = (icon: React.ReactNode, label: string, value: any) => (
    <span className="inline-flex items-center gap-1">
      <span aria-hidden="true" className="text-ink-400 dark:text-ink-500">
        {icon}
      </span>
      <span className="sr-only">{label}</span>
      <span className="tabular-nums">{num(value)}</span>
    </span>
  );

  const momentColumns = [
    {
      key: "imageUrl",
      header: "",
      className: "w-14",
      render: (row: any) =>
        row.imageUrl ? (
          <img
            src={row.imageUrl}
            alt=""
            data-testid="moment-thumb"
            className="h-10 w-10 rounded-card object-cover"
          />
        ) : (
          <div
            aria-hidden="true"
            className="h-10 w-10 rounded-card border border-line dark:border-line-dark"
          />
        ),
    },
    {
      key: "title",
      header: t("admin.content.title") || "Title",
      render: (row: any) => (
        <div className="max-w-xs">
          <div className="truncate font-medium text-ink-900 dark:text-ink-50">
            {row.title || firstLine(row.description) || t("admin.content.untitled") || "Untitled moment"}
          </div>
          {row.title ? (
            <div className="truncate text-xs text-ink-500 dark:text-ink-400">
              {firstLine(row.description)}
            </div>
          ) : null}
        </div>
      ),
    },
    {
      key: "user",
      header: t("admin.content.author") || "Author",
      render: (row: any) => personLink(row.user && row.user.id, row.user && row.user.name),
    },
    {
      key: "language",
      header: t("admin.content.language") || "Language",
      render: (row: any) => row.language || "—",
    },
    {
      key: "counts",
      header: t("admin.content.engagement") || "Engagement",
      className: "whitespace-nowrap",
      render: (row: any) => (
        <span className="flex items-center gap-3 text-sm text-ink-700 dark:text-ink-200">
          {countPair(<Heart size={14} />, t("admin.content.likes") || "Likes", row.likeCount)}
          {countPair(
            <MessageCircle size={14} />,
            t("admin.content.comments") || "Comments",
            row.commentCount
          )}
          {countPair(<Eye size={14} />, t("admin.content.views") || "Views", row.viewCount)}
        </span>
      ),
    },
    {
      key: "openReports",
      header: t("admin.content.openReports") || "Open reports",
      className: "text-right tabular-nums",
      render: (row: any) => num(row.openReports),
    },
    {
      key: "isDeleted",
      header: t("admin.content.status") || "Status",
      render: (row: any) =>
        row.isDeleted ? (
          <Badge tone="banana">{t("admin.content.hidden") || "Hidden"}</Badge>
        ) : (
          <Badge tone="brand">{t("admin.content.visible") || "Visible"}</Badge>
        ),
    },
    {
      key: "createdAt",
      header: t("admin.content.created") || "Created",
      className: "whitespace-nowrap",
      render: (row: any) => formatWhen(row.createdAt),
    },
  ];

  const clubColumns = [
    { key: "name", header: t("admin.content.name") || "Name" },
    {
      key: "owner",
      header: t("admin.content.owner") || "Owner",
      render: (row: any) =>
        personLink(row.owner && (row.owner._id || row.owner.id), row.owner && row.owner.name),
    },
    {
      key: "city",
      header: t("admin.content.city") || "City",
      render: (row: any) => row.city || (row.place && row.place.name) || "—",
    },
    {
      key: "language",
      header: t("admin.content.language") || "Language",
      render: (row: any) => row.languageLabel || row.language || "—",
    },
    {
      key: "memberCount",
      header: t("admin.content.members") || "Members",
      className: "text-right tabular-nums",
      render: (row: any) => num(row.memberCount),
    },
    {
      key: "status",
      header: t("admin.content.status") || "Status",
      render: (row: any) => <Badge tone={statusTone(row.status)}>{row.status}</Badge>,
    },
    {
      key: "openReports",
      header: t("admin.content.openReports") || "Open reports",
      className: "text-right tabular-nums",
      render: (row: any) => num(row.openReports),
    },
    {
      key: "createdAt",
      header: t("admin.content.created") || "Created",
      className: "whitespace-nowrap",
      render: (row: any) => formatWhen(row.createdAt),
    },
  ];

  const gatheringColumns = [
    { key: "title", header: t("admin.content.title") || "Title" },
    {
      key: "language",
      header: t("admin.content.language") || "Language",
      render: (row: any) => row.languageLabel || row.language || "—",
    },
    {
      key: "startsAt",
      header: t("admin.content.startsAt") || "Starts at",
      className: "whitespace-nowrap",
      render: (row: any) => formatWhen(row.startsAt),
    },
    {
      key: "going",
      header: t("admin.content.going") || "Going",
      className: "text-right tabular-nums",
      render: (row: any) => `${num(row.goingCount)}/${num(row.capacity)}`,
    },
    {
      key: "status",
      header: t("admin.content.status") || "Status",
      render: (row: any) => <Badge tone={statusTone(row.status)}>{row.status}</Badge>,
    },
    {
      key: "openReports",
      header: t("admin.content.openReports") || "Open reports",
      className: "text-right tabular-nums",
      render: (row: any) => num(row.openReports),
    },
    {
      key: "actions",
      header: "",
      className: "text-right",
      render: (row: any) =>
        row.status === "cancelled" ? null : (
          <button
            type="button"
            onClick={() => setPending({ kind: "cancel", row })}
            className="rounded-chip border border-line px-2.5 py-1 text-xs font-medium text-ink-700 hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
          >
            {t("admin.content.cancel") || "Cancel"}
          </button>
        ),
    },
  ];

  const tabButtonClass = (selected: boolean) =>
    [
      "rounded-chip px-3 py-1.5 text-sm font-medium transition-colors",
      selected
        ? "bg-brand-deep text-white"
        : "border border-line text-ink-700 hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800",
    ].join(" ");

  const tabLabel = (value: Tab): string => {
    if (value === "moments") return t("admin.content.moments") || "Moments";
    if (value === "communities") return t("admin.content.communities") || "Communities";
    if (value === "gatherings") return t("admin.content.gatherings") || "Gatherings";
    return t("admin.content.reports") || "Reports";
  };

  const statCards: Array<{ label: string; value: any; hint?: React.ReactNode }> = [
    {
      label: t("admin.content.momentsToday") || "Moments today",
      value: num(s.moments && s.moments.today),
      hint: `${num(s.moments && s.moments.total)} ${t("admin.content.allTime") || "all time"}`,
    },
    {
      label: t("admin.content.moments7d") || "Moments (7 days)",
      value: num(s.moments && s.moments.last7d),
    },
    {
      label: t("admin.content.momentsHidden") || "Hidden moments",
      value: num(s.moments && s.moments.hidden),
    },
    {
      label: t("admin.content.comments7d") || "Comments (7 days)",
      value: num(s.comments && s.comments.last7d),
    },
    {
      label: t("admin.content.activeCommunities") || "Active communities",
      value: num(s.clubs && s.clubs.active),
      hint: `${num(s.clubs && s.clubs.membersTotal)} ${t("admin.content.membersTotal") || "members"}`,
    },
    {
      label: t("admin.content.upcomingGatherings") || "Upcoming gatherings",
      value: num(s.gatherings && s.gatherings.upcoming),
    },
    {
      label: t("admin.content.pendingReports") || "Pending reports",
      value: num(s.reports && s.reports.pending),
      hint: `${num(s.reports && s.reports.underReview)} ${
        t("admin.content.underReview") || "under review"
      }`,
    },
  ];

  const filterLabelClass = "flex items-center gap-2 text-sm text-ink-700 dark:text-ink-200";

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-display-sm text-ink-900 dark:text-ink-50">
          {t("admin.nav.content") || "Content"}
        </h1>
        <RefreshButton
          label={t("admin.common.refresh") || "Refresh"}
          isFetching={stats.isFetching || (tab !== "reports" && active.isFetching)}
          onRefresh={() => {
            stats.refetch();
            // The reports tab owns its own query inside `ReportsTable`; every
            // report action invalidates `AdminReports`, so there is nothing
            // stale for this button to chase there.
            if (tab !== "reports") active.refetch();
          }}
        />
      </header>

      {stats.isError ? (
        <div
          data-testid="stats-error"
          role="status"
          className="rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-600 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-300"
        >
          {loadError}
        </div>
      ) : stats.isLoading ? (
        <div
          data-testid="stats-loading"
          className="animate-pulse rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-400 dark:border-line-dark dark:bg-cardbg-dark"
        >
          {loadingText}
        </div>
      ) : (
        <div
          data-testid="content-stat-strip"
          className="grid grid-cols-2 gap-3 md:grid-cols-4 xl:grid-cols-7"
        >
          {statCards.map((card) => (
            <StatCard key={card.label} label={card.label} value={card.value} hint={card.hint} />
          ))}
        </div>
      )}

      <div className="flex flex-wrap items-center justify-between gap-3">
        <div
          role="tablist"
          aria-label={t("admin.content.tabs") || "Content type"}
          className="flex flex-wrap gap-2"
        >
          {(TABS as Tab[]).map((value) => (
            <button
              key={value}
              type="button"
              role="tab"
              aria-selected={tab === value}
              className={tabButtonClass(tab === value)}
              onClick={() => selectTab(value)}
            >
              {tabLabel(value)}
            </button>
          ))}
        </div>

        {tab === "reports" ? null : (
          <div className="flex flex-wrap items-center gap-4">
            {tab === "moments" ? (
              <input
                type="search"
                data-testid="moment-search"
                value={text}
                onChange={(e) => setText(e.target.value)}
                placeholder={t("admin.content.searchMoments") || "Search moments"}
                aria-label={t("admin.content.searchMoments") || "Search moments"}
                className="rounded-chip border border-line bg-surface px-3 py-1.5 text-sm text-ink-800 placeholder:text-ink-400 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-100"
              />
            ) : null}
            <label className={filterLabelClass}>
              <input
                type="checkbox"
                checked={reportedOnly}
                onChange={(e) => setReportedOnly(e.target.checked)}
              />
              {t("admin.content.reportedOnly") || "Reported only"}
            </label>
            {tab === "moments" ? (
              <label className={filterLabelClass}>
                <input
                  type="checkbox"
                  checked={hiddenOnly}
                  onChange={(e) => setHiddenOnly(e.target.checked)}
                />
                {t("admin.content.hiddenOnly") || "Hidden only"}
              </label>
            ) : null}
          </div>
        )}
      </div>

      {tab === "reports" ? (
        <ReportsTable />
      ) : active.isError ? (
        <div
          data-testid="section-error"
          role="status"
          className="rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-600 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-300"
        >
          {loadError}
        </div>
      ) : active.isLoading ? (
        <div
          data-testid="section-loading"
          className="animate-pulse rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-400 dark:border-line-dark dark:bg-cardbg-dark"
        >
          {loadingText}
        </div>
      ) : (
        <DataTable
          rows={rows}
          rowKey={tab === "moments" ? "id" : "_id"}
          emptyText={emptyText}
          columns={
            tab === "moments"
              ? momentColumns
              : tab === "communities"
              ? clubColumns
              : gatheringColumns
          }
          onRowClick={
            tab === "moments"
              ? (row: any) => setSelectedMoment(row)
              : tab === "communities"
              ? (row: any) => setSelectedClub(row)
              : undefined
          }
          page={page}
          hasMore={hasMore}
          onPageChange={(next) => setPage(Math.max(1, next))}
        />
      )}

      {selectedMoment ? (
        <MomentPreviewDrawer
          moment={selectedMoment}
          onClose={() => setSelectedMoment(null)}
        />
      ) : null}

      {selectedClub ? (
        <ClubDetailDrawer club={selectedClub} onClose={() => setSelectedClub(null)} />
      ) : null}

      <ConfirmDialog
        open={pending !== null}
        title={t("admin.content.cancelTitle") || "Cancel gathering"}
        confirmLabel={t("admin.content.cancel") || "Cancel"}
        cancelLabel={t("admin.common.cancel") || "Cancel"}
        requireReason
        busy={cancelState.isLoading}
        error={actionError}
        onConfirm={handleCancel}
        onCancel={() => {
          setActionError("");
          setPending(null);
        }}
      />
    </div>
  );
};

export default AdminContent;
