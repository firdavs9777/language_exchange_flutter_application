import React from "react";
import { useTranslation } from "react-i18next";
import {
  useGetAdminStatsQuery,
  useGetAdminActivityQuery,
  useGetAnalyticsVisitsQuery,
} from "../../../store/slices/adminSlice";
import { SurfaceCard } from "../../../design";
import StatCard from "../parts/StatCard";
import DataTable from "../parts/DataTable";
import RefreshButton from "../parts/RefreshButton";

/**
 * The console's front page: who is on the product right now.
 *
 * Three independent queries feed it (stats, activity, weekly visits) and each
 * section reports its own failure. A dead `/analytics/visits` must not blank
 * the user counts — an admin opening this page during an incident is usually
 * here precisely because something is broken.
 */

/** `—` rather than `0` for a number the backend didn't send: they differ. */
const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString() : "—";

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

const AdminOverview: React.FC = () => {
  const { t } = useTranslation();
  const stats = useGetAdminStatsQuery(undefined as any);
  const activity = useGetAdminActivityQuery({} as any);
  const visits = useGetAnalyticsVisitsQuery(undefined as any);

  const loadError = t("admin.common.loadError") || "Couldn't load this section.";
  const loadingText = t("admin.common.loading") || "Loading…";

  const errorBox = (className = "") => (
    <div
      data-testid="section-error"
      role="status"
      className={[
        "rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-600",
        "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-300",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
    >
      {loadError}
    </div>
  );

  const loadingBox = (className = "") => (
    <div
      data-testid="section-loading"
      className={[
        "animate-pulse rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-400",
        "dark:border-line-dark dark:bg-cardbg-dark",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
    >
      {loadingText}
    </div>
  );

  const s = stats.data || {};
  const thisWeek = (visits.data && visits.data.thisWeek) || {};
  const lastWeek = (visits.data && visits.data.lastWeek) || {};
  const visitsDelta =
    typeof thisWeek.totalVisits === "number" &&
    typeof lastWeek.totalVisits === "number" &&
    lastWeek.totalVisits > 0
      ? Math.round(((thisWeek.totalVisits - lastWeek.totalVisits) / lastWeek.totalVisits) * 100)
      : null;

  const languageList = (
    testId: string,
    title: string,
    rows: any[],
    emptyText: string
  ) => (
    <SurfaceCard padding="lg">
      <h2 className="font-display text-base text-ink-900 dark:text-ink-50">{title}</h2>
      {stats.isError ? (
        <div className="pt-3">{errorBox()}</div>
      ) : stats.isLoading ? (
        <div className="pt-3">{loadingBox()}</div>
      ) : (
        <ul data-testid={testId} className="pt-2 text-sm">
          {(rows || []).length === 0 ? (
            <li className="py-2 text-ink-500 dark:text-ink-400">{emptyText}</li>
          ) : (
            (rows || []).map((row: any, index: number) => (
              <li
                key={String(row?._id ?? index)}
                className="flex items-center justify-between border-b border-line/70 py-1.5 last:border-0 dark:border-line-dark/70"
              >
                <span className="text-ink-800 dark:text-ink-100">
                  {String(row?._id ?? "—")}
                </span>
                <span className="tabular-nums text-ink-500 dark:text-ink-400">
                  {num(row?.count)}
                </span>
              </li>
            ))
          )}
        </ul>
      )}
    </SurfaceCard>
  );

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-display-sm text-ink-900 dark:text-ink-50">
          {t("admin.nav.overview") || "Overview"}
        </h1>
        <RefreshButton
          label={t("admin.common.refresh") || "Refresh"}
          isFetching={stats.isFetching || activity.isFetching || visits.isFetching}
          onRefresh={() => {
            stats.refetch();
            activity.refetch();
            visits.refetch();
          }}
        />
      </header>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {stats.isError ? (
          errorBox("sm:col-span-2 lg:col-span-4")
        ) : stats.isLoading ? (
          loadingBox("sm:col-span-2 lg:col-span-4")
        ) : (
          <>
            <StatCard label={t("admin.overview.totalUsers") || "Total users"} value={num(s.total)} />
            <StatCard label={t("admin.overview.newToday") || "New today"} value={num(s.newToday)} />
            <StatCard
              label={t("admin.overview.newThisWeek") || "New this week"}
              value={num(s.newThisWeek)}
            />
            <StatCard
              label={t("admin.overview.activeThisWeek") || "Active this week"}
              value={num(s.activeWeek)}
              hint={
                activity.data && activity.data.counts
                  ? `${num(activity.data.counts.today)} ${
                      t("admin.overview.activeToday") || "active today"
                    }`
                  : undefined
              }
            />
            <StatCard label={t("admin.overview.vip") || "VIP"} value={num(s.vip)} />
            <StatCard label={t("admin.overview.banned") || "Banned"} value={num(s.banned)} />
            <StatCard label={t("admin.overview.admins") || "Admins"} value={num(s.admins)} />
          </>
        )}

        {visits.isError ? (
          errorBox()
        ) : visits.isLoading ? (
          loadingBox()
        ) : (
          <StatCard
            label={t("admin.overview.visitsThisWeek") || "Visits this week"}
            value={num(thisWeek.totalVisits)}
            hint={`${t("admin.overview.vs") || "vs"} ${num(lastWeek.totalVisits)} ${
              t("admin.overview.lastWeek") || "last week"
            }${visitsDelta === null ? "" : ` (${visitsDelta >= 0 ? "+" : ""}${visitsDelta}%)`}`}
          />
        )}
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {languageList(
          "top-native-languages",
          t("admin.overview.topNativeLanguages") || "Top native languages",
          s.topNativeLanguages,
          t("admin.common.empty") || "Nothing to show yet."
        )}
        {languageList(
          "top-learning-languages",
          t("admin.overview.topLearningLanguages") || "Top learning languages",
          s.topLearningLanguages,
          t("admin.common.empty") || "Nothing to show yet."
        )}
      </div>

      <SurfaceCard padding="lg">
        <h2 className="font-display text-base text-ink-900 dark:text-ink-50">
          {t("admin.overview.recentlyActive") || "Recently active"}
        </h2>
        {activity.isError ? (
          <div className="pt-3">{errorBox()}</div>
        ) : activity.isLoading ? (
          <div className="pt-3">{loadingBox()}</div>
        ) : (
          <DataTable
            className="pt-2"
            caption={t("admin.overview.recentlyActive") || "Recently active"}
            rowKey={(row: any, index: number) => String(row?.id ?? row?._id ?? index)}
            emptyText={t("admin.common.empty") || "Nothing to show yet."}
            rows={(activity.data && activity.data.recentlyActive) || []}
            columns={[
              { key: "name", header: t("admin.overview.name") || "Name" },
              {
                key: "email",
                header: t("admin.overview.email") || "Email",
                render: (row: any) => row?.email || "—",
              },
              {
                key: "lastActive",
                header: t("admin.overview.lastActive") || "Last active",
                className: "whitespace-nowrap tabular-nums",
                render: (row: any) => formatWhen(row?.lastActive),
              },
            ]}
          />
        )}
      </SurfaceCard>
    </div>
  );
};

export default AdminOverview;
