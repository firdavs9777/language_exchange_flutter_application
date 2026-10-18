import React from "react";
import { useTranslation } from "react-i18next";
import { useGetAiUsageQuery, useGetAiUsageLogsQuery } from "../../../store/slices/adminSlice";
import { SurfaceCard } from "../../../design";
import StatCard from "../parts/StatCard";
import DataTable from "../parts/DataTable";
import RefreshButton from "../parts/RefreshButton";

/**
 * AI feature usage: a total, a breakdown by feature and by day over a date
 * range, and the raw per-call log underneath. The range defaults to the last
 * 30 days — computed once, in a lazy `useState` initializer, so the default
 * is fixed at mount rather than recomputed (and potentially drifting) on
 * every render; it never reads `window`, only `Date`.
 */

const LOGS_LIMIT = 20;

const isoDate = (date: Date): string => date.toISOString().slice(0, 10);

const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString() : "—";

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

/** The aggregation projects `feature`/`date` but a defensive read covers `_id` too. */
const rowLabel = (row: any, field: string): string => String((row && (row[field] ?? row._id)) ?? "—");

const AdminAiUsage: React.FC = () => {
  const { t } = useTranslation();
  const [feature, setFeature] = React.useState("");
  const [range, setRange] = React.useState(() => {
    const to = new Date();
    const from = new Date(to.getTime() - 30 * 24 * 60 * 60 * 1000);
    return { from: isoDate(from), to: isoDate(to) };
  });
  const [page, setPage] = React.useState(1);

  const usage = useGetAiUsageQuery({
    feature: feature || undefined,
    from: range.from,
    to: range.to,
  });
  const logs = useGetAiUsageLogsQuery({
    feature: feature || undefined,
    from: range.from,
    to: range.to,
    page,
    limit: LOGS_LIMIT,
  });

  const loadError = t("admin.common.loadError") || "Couldn't load this section.";
  const loadingText = t("admin.common.loading") || "Loading…";
  const emptyText = t("admin.common.empty") || "Nothing to show yet.";
  const anonymous = t("admin.aiUsage.anonymous") || "anonymous";

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

  const byFeature = (usage.data && usage.data.byFeature) || [];
  const byDay = (usage.data && usage.data.byDay) || [];

  // The select's options must never shrink while a feature filter is active:
  // `byFeature` only ever lists what the CURRENT filter matched, so once a
  // feature is chosen every other feature's row disappears from it. This
  // accumulates every feature name ever seen (across filter changes) into a
  // stable, sorted set, and only updates state when that set actually grows —
  // never on a render where it would just be the same array again.
  const [knownFeatures, setKnownFeatures] = React.useState<string[]>([]);
  React.useEffect(() => {
    const seen = byFeature
      .map((row: any) => rowLabel(row, "feature"))
      .filter((value: string) => value !== "—");
    if (seen.length === 0) return;
    setKnownFeatures((prev) => {
      const merged = Array.from(new Set([...prev, ...seen])).sort();
      const unchanged =
        merged.length === prev.length && merged.every((value, index) => value === prev[index]);
      return unchanged ? prev : merged;
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [usage.data]);

  const logRows = (logs.data && logs.data.data) || [];
  const logsHasMore = Boolean(logs.data && logs.data.pagination && logs.data.pagination.hasMore);

  const changeFeature = (value: string) => {
    setFeature(value);
    setPage(1);
  };
  const changeFrom = (value: string) => {
    setRange((r) => ({ ...r, from: value }));
    setPage(1);
  };
  const changeTo = (value: string) => {
    setRange((r) => ({ ...r, to: value }));
    setPage(1);
  };

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-display-sm text-ink-900 dark:text-ink-50">
          {t("admin.nav.aiUsage") || "AI usage"}
        </h1>
        <RefreshButton
          label={t("admin.common.refresh") || "Refresh"}
          isFetching={usage.isFetching || logs.isFetching}
          onRefresh={() => {
            usage.refetch();
            logs.refetch();
          }}
        />
      </header>

      <div className="flex flex-wrap items-end gap-3">
        <label className="flex flex-col text-sm text-ink-700 dark:text-ink-200">
          {t("admin.aiUsage.feature") || "Feature"}
          <select
            aria-label={t("admin.aiUsage.feature") || "Feature"}
            value={feature}
            onChange={(e) => changeFeature(e.target.value)}
            className="mt-1 rounded-chip border border-line bg-transparent px-2.5 py-1.5 text-sm dark:border-line-dark"
          >
            <option value="">{t("admin.aiUsage.allFeatures") || "All features"}</option>
            {knownFeatures.map((value: string) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col text-sm text-ink-700 dark:text-ink-200">
          {t("admin.aiUsage.from") || "From"}
          <input
            type="date"
            aria-label={t("admin.aiUsage.from") || "From"}
            value={range.from}
            onChange={(e) => changeFrom(e.target.value)}
            className="mt-1 rounded-chip border border-line bg-transparent px-2.5 py-1.5 text-sm dark:border-line-dark"
          />
        </label>
        <label className="flex flex-col text-sm text-ink-700 dark:text-ink-200">
          {t("admin.aiUsage.to") || "To"}
          <input
            type="date"
            aria-label={t("admin.aiUsage.to") || "To"}
            value={range.to}
            onChange={(e) => changeTo(e.target.value)}
            className="mt-1 rounded-chip border border-line bg-transparent px-2.5 py-1.5 text-sm dark:border-line-dark"
          />
        </label>
      </div>

      {usage.isError ? (
        errorBox()
      ) : usage.isLoading ? (
        loadingBox()
      ) : (
        <>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <StatCard
              label={t("admin.aiUsage.total") || "Total calls"}
              value={num(usage.data && usage.data.total)}
            />
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <SurfaceCard padding="lg">
              <div data-testid="usage-by-feature">
                <h2 className="font-display text-base text-ink-900 dark:text-ink-50">
                  {t("admin.aiUsage.byFeature") || "Usage by feature"}
                </h2>
                <DataTable
                  className="pt-2"
                  rows={byFeature}
                  emptyText={emptyText}
                  rowKey={(row: any, index: number) => `${rowLabel(row, "feature")}-${index}`}
                  columns={[
                    {
                      key: "feature",
                      header: t("admin.aiUsage.feature") || "Feature",
                      render: (row: any) => rowLabel(row, "feature"),
                    },
                    {
                      key: "count",
                      header: t("admin.aiUsage.calls") || "Calls",
                      className: "text-right tabular-nums",
                      render: (row: any) => num(row.count),
                    },
                  ]}
                />
              </div>
            </SurfaceCard>

            <SurfaceCard padding="lg">
              <div data-testid="usage-by-day">
                <h2 className="font-display text-base text-ink-900 dark:text-ink-50">
                  {t("admin.aiUsage.byDay") || "Usage by day"}
                </h2>
                <DataTable
                  className="pt-2"
                  rows={byDay}
                  emptyText={emptyText}
                  rowKey={(row: any, index: number) => `${rowLabel(row, "date")}-${index}`}
                  columns={[
                    {
                      key: "date",
                      header: t("admin.aiUsage.date") || "Date",
                      render: (row: any) => rowLabel(row, "date"),
                    },
                    {
                      key: "count",
                      header: t("admin.aiUsage.calls") || "Calls",
                      className: "text-right tabular-nums",
                      render: (row: any) => num(row.count),
                    },
                  ]}
                />
              </div>
            </SurfaceCard>
          </div>
        </>
      )}

      <SurfaceCard padding="lg">
        <div data-testid="usage-logs">
          <h2 className="font-display text-base text-ink-900 dark:text-ink-50">
            {t("admin.aiUsage.logs") || "Usage log"}
          </h2>
          {logs.isError ? (
            <div className="pt-3">{errorBox()}</div>
          ) : logs.isLoading ? (
            <div className="pt-3">{loadingBox()}</div>
          ) : (
            <DataTable
              className="pt-2"
              rows={logRows}
              emptyText={emptyText}
              rowKey="id"
              page={page}
              hasMore={logsHasMore}
              onPageChange={(next) => setPage(Math.max(1, next))}
              columns={[
                {
                  key: "user",
                  header: t("admin.aiUsage.user") || "User",
                  render: (row: any) =>
                    row.user ? (
                      <div>
                        <div>{row.user.name || "—"}</div>
                        <div className="text-xs text-ink-500 dark:text-ink-400">
                          {row.user.email || "—"}
                        </div>
                      </div>
                    ) : (
                      anonymous
                    ),
                },
                { key: "feature", header: t("admin.aiUsage.feature") || "Feature" },
                {
                  key: "timestamp",
                  header: t("admin.aiUsage.timestamp") || "Timestamp",
                  className: "whitespace-nowrap",
                  render: (row: any) => formatWhen(row.timestamp),
                },
              ]}
            />
          )}
        </div>
      </SurfaceCard>
    </div>
  );
};

export default AdminAiUsage;
