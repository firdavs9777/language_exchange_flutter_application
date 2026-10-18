import React from "react";
import { useTranslation } from "react-i18next";
import {
  useGetAnalyticsEventsQuery,
  useGetAnalyticsVisitsQuery,
} from "../../../store/slices/adminSlice";
import { SurfaceCard } from "../../../design";
import StatCard from "../parts/StatCard";
import DataTable from "../parts/DataTable";
import RefreshButton from "../parts/RefreshButton";
import LineChart, { CHART_COLORS } from "../parts/LineChart";

/**
 * Where the marketing site's traffic comes from and what it does.
 *
 * Two queries, deliberately not merged: `/analytics/events` is the site's own
 * event log over a selectable window, `/analytics/visits` is the fixed weekly
 * visit report. They count different things over different periods, so they
 * are never shown in one chart — the page keeps them in separate blocks and
 * each reports its own failure.
 */

const DAY_OPTIONS = [7, 30, 90];

const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString() : "—";

/** WebVisit's aggregations project a named field but keep `_id` too. */
const label = (row: any, field: string): string =>
  String((row && (row[field] ?? row._id)) ?? "—");

const AdminReach: React.FC = () => {
  const { t } = useTranslation();
  const [days, setDays] = React.useState(30);
  const events = useGetAnalyticsEventsQuery({ days });
  const visits = useGetAnalyticsVisitsQuery(undefined as any);

  const loadError = t("admin.common.loadError") || "Couldn't load this section.";
  const loadingText = t("admin.common.loading") || "Loading…";
  const emptyText = t("admin.common.empty") || "Nothing to show yet.";

  const errorBox = () => (
    <div
      data-testid="section-error"
      role="status"
      className="rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-600 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-300"
    >
      {loadError}
    </div>
  );

  const loadingBox = () => (
    <div
      data-testid="section-loading"
      className="animate-pulse rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-400 dark:border-line-dark dark:bg-cardbg-dark"
    >
      {loadingText}
    </div>
  );

  /** One card per block, so a failed query costs only its own block. */
  const block = (
    testId: string,
    title: string,
    query: { isError?: boolean; isLoading?: boolean },
    body: React.ReactNode
  ) => (
    <SurfaceCard padding="lg">
      <div data-testid={testId}>
        <h2 className="font-display text-base text-ink-900 dark:text-ink-50">{title}</h2>
        <div className="pt-2">
          {query.isError ? errorBox() : query.isLoading ? loadingBox() : body}
        </div>
      </div>
    </SurfaceCard>
  );

  const byDay = (events.data && events.data.byDay) || [];
  const byPlacement = ((events.data && events.data.byPlacement) || [])
    .slice()
    .sort((a: any, b: any) => (Number(b?.taps) || 0) - (Number(a?.taps) || 0));
  const topReferrers = (events.data && events.data.topReferrers) || [];
  const topPaths = (events.data && events.data.topPaths) || [];

  const thisWeek = (visits.data && visits.data.thisWeek) || {};
  const topCountries = (visits.data && visits.data.topCountries) || [];
  const deviceBreakdown = (visits.data && visits.data.deviceBreakdown) || [];
  const ratio = visits.data && visits.data.newVisitorRatio;
  const ratioPercent =
    typeof ratio === "number" && isFinite(ratio) ? `${Math.round(ratio * 100)}%` : "—";

  const dayButtonClass = (selected: boolean) =>
    [
      "rounded-chip px-3 py-1.5 text-sm font-medium transition-colors",
      selected
        ? "bg-brand-deep text-white"
        : "border border-line text-ink-700 hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800",
    ].join(" ");

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-display-sm text-ink-900 dark:text-ink-50">
          {t("admin.nav.reach") || "Reach"}
        </h1>
        <div className="flex flex-wrap items-center gap-2">
          <div
            role="group"
            aria-label={t("admin.reach.window") || "Time window"}
            className="flex items-center gap-1"
          >
            {DAY_OPTIONS.map((option) => (
              <button
                key={option}
                type="button"
                aria-pressed={days === option}
                onClick={() => setDays(option)}
                className={dayButtonClass(days === option)}
              >
                {`${option} ${t("admin.reach.days") || "days"}`}
              </button>
            ))}
          </div>
          <RefreshButton
            label={t("admin.common.refresh") || "Refresh"}
            isFetching={events.isFetching || visits.isFetching}
            onRefresh={() => {
              events.refetch();
              visits.refetch();
            }}
          />
        </div>
      </header>

      {block(
        "reach-chart",
        t("admin.reach.trafficTitle") || "Page views and store taps",
        events,
        <LineChart
          height={240}
          emptyText={emptyText}
          series={[
            {
              name: t("admin.reach.pageViews") || "Page views",
              color: CHART_COLORS.pageViews,
              points: byDay.map((d: any) => ({ x: String(d?.date), y: Number(d?.pageViews) || 0 })),
            },
            {
              name: t("admin.reach.storeTaps") || "Store taps",
              color: CHART_COLORS.storeTaps,
              points: byDay.map((d: any) => ({ x: String(d?.date), y: Number(d?.storeTaps) || 0 })),
            },
          ]}
        />
      )}

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {visits.isError ? (
          errorBox()
        ) : visits.isLoading ? (
          loadingBox()
        ) : (
          <>
            <StatCard
              label={t("admin.reach.newVisitors") || "New visitors"}
              value={ratioPercent}
              hint={`${num(thisWeek.newVisitors)} ${t("admin.reach.ofVisits") || "of"} ${num(
                thisWeek.totalVisits
              )}`}
            />
            <StatCard
              label={t("admin.reach.visitsThisWeek") || "Visits this week"}
              value={num(thisWeek.totalVisits)}
            />
            <StatCard
              label={t("admin.reach.uniqueVisitors") || "Unique visitors"}
              value={num(thisWeek.uniqueVisitors)}
            />
            <StatCard
              label={t("admin.reach.period") || "Week of"}
              value={String((visits.data && visits.data.period && visits.data.period.from) || "—")}
            />
          </>
        )}
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        {block(
          "taps-by-placement",
          t("admin.reach.tapsByPlacement") || "Store taps by placement",
          events,
          <DataTable
            rows={byPlacement}
            emptyText={emptyText}
            rowKey={(row: any, index: number) => `${row?.placement}-${row?.platform}-${index}`}
            columns={[
              { key: "placement", header: t("admin.reach.placement") || "Placement" },
              { key: "platform", header: t("admin.reach.platform") || "Platform" },
              {
                key: "taps",
                header: t("admin.reach.taps") || "Taps",
                className: "text-right tabular-nums",
                render: (row: any) => num(row?.taps),
              },
            ]}
          />
        )}

        {block(
          "top-referrers",
          t("admin.reach.topReferrers") || "Top referrers",
          events,
          <DataTable
            rows={topReferrers}
            emptyText={emptyText}
            rowKey={(row: any, index: number) => `${row?.referrer}-${index}`}
            columns={[
              {
                key: "referrer",
                header: t("admin.reach.referrer") || "Referrer",
                className: "max-w-xs truncate",
              },
              {
                key: "count",
                header: t("admin.reach.views") || "Views",
                className: "text-right tabular-nums",
                render: (row: any) => num(row?.count),
              },
            ]}
          />
        )}

        {block(
          "top-paths",
          t("admin.reach.topPaths") || "Top pages",
          events,
          <DataTable
            rows={topPaths}
            emptyText={emptyText}
            rowKey={(row: any, index: number) => `${row?.path}-${index}`}
            columns={[
              {
                key: "path",
                header: t("admin.reach.path") || "Path",
                className: "max-w-xs truncate",
              },
              {
                key: "views",
                header: t("admin.reach.views") || "Views",
                className: "text-right tabular-nums",
                render: (row: any) => num(row?.views),
              },
            ]}
          />
        )}

        {block(
          "top-countries",
          t("admin.reach.topCountries") || "Top countries",
          visits,
          <DataTable
            rows={topCountries}
            emptyText={emptyText}
            rowKey={(row: any, index: number) => `${label(row, "country")}-${index}`}
            columns={[
              {
                key: "country",
                header: t("admin.reach.country") || "Country",
                render: (row: any) => label(row, "country"),
              },
              {
                key: "visits",
                header: t("admin.reach.visits") || "Visits",
                className: "text-right tabular-nums",
                render: (row: any) => num(row?.visits ?? row?.count),
              },
              {
                key: "uniqueVisitors",
                header: t("admin.reach.unique") || "Unique",
                className: "text-right tabular-nums",
                render: (row: any) => num(row?.uniqueVisitors),
              },
            ]}
          />
        )}

        {block(
          "device-breakdown",
          t("admin.reach.devices") || "Devices",
          visits,
          <DataTable
            rows={deviceBreakdown}
            emptyText={emptyText}
            rowKey={(row: any, index: number) => `${label(row, "device")}-${index}`}
            columns={[
              {
                key: "device",
                header: t("admin.reach.device") || "Device",
                render: (row: any) => label(row, "device"),
              },
              {
                key: "count",
                header: t("admin.reach.visits") || "Visits",
                className: "text-right tabular-nums",
                render: (row: any) => num(row?.count),
              },
            ]}
          />
        )}
      </div>
    </div>
  );
};

export default AdminReach;
