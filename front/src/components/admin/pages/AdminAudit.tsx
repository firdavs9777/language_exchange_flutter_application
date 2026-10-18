import React from "react";
import { useTranslation } from "react-i18next";
import { useGetAuditLogQuery } from "../../../store/slices/adminSlice";
import DataTable from "../parts/DataTable";
import RefreshButton from "../parts/RefreshButton";

/**
 * The moderation audit trail: every ban, unban, role change, delete, archive
 * and cancel, filterable by who did it, who it was done to, and what it was.
 * The backend returns a real `pagination.hasMore` here, unlike the content
 * lists, so it is used directly rather than derived.
 */

const LIMIT = 50;

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

const personLabel = (person: any, fallbackEmail?: any): string => {
  if (person && (person.name || person.email)) return person.name || person.email;
  if (fallbackEmail) return String(fallbackEmail);
  return "—";
};

const AdminAudit: React.FC = () => {
  const { t } = useTranslation();
  const [action, setAction] = React.useState("");
  const [moderatorId, setModeratorId] = React.useState("");
  const [targetId, setTargetId] = React.useState("");
  const [page, setPage] = React.useState(1);

  const audit = useGetAuditLogQuery({
    action: action || undefined,
    moderatorId: moderatorId || undefined,
    targetId: targetId || undefined,
    page,
    limit: LIMIT,
  });

  const loadError = t("admin.common.loadError") || "Couldn't load this section.";
  const loadingText = t("admin.common.loading") || "Loading…";
  const emptyText = t("admin.common.empty") || "Nothing to show yet.";

  const rows = (audit.data && audit.data.data) || [];
  const hasMore = Boolean(audit.data && audit.data.pagination && audit.data.pagination.hasMore);

  const changeAction = (value: string) => {
    setAction(value);
    setPage(1);
  };
  const changeModeratorId = (value: string) => {
    setModeratorId(value);
    setPage(1);
  };
  const changeTargetId = (value: string) => {
    setTargetId(value);
    setPage(1);
  };

  const fieldClass =
    "mt-1 rounded-chip border border-line bg-transparent px-2.5 py-1.5 text-sm dark:border-line-dark";

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-display-sm text-ink-900 dark:text-ink-50">
          {t("admin.nav.audit") || "Audit log"}
        </h1>
        <RefreshButton
          label={t("admin.common.refresh") || "Refresh"}
          isFetching={audit.isFetching}
          onRefresh={() => audit.refetch()}
        />
      </header>

      <div className="flex flex-wrap items-end gap-3">
        <label className="flex flex-col text-sm text-ink-700 dark:text-ink-200">
          {t("admin.audit.action") || "Action"}
          <input
            type="text"
            aria-label={t("admin.audit.action") || "Action"}
            value={action}
            onChange={(e) => changeAction(e.target.value)}
            className={fieldClass}
          />
        </label>
        <label className="flex flex-col text-sm text-ink-700 dark:text-ink-200">
          {t("admin.audit.moderatorId") || "Moderator ID"}
          <input
            type="text"
            aria-label={t("admin.audit.moderatorId") || "Moderator ID"}
            value={moderatorId}
            onChange={(e) => changeModeratorId(e.target.value)}
            className={fieldClass}
          />
        </label>
        <label className="flex flex-col text-sm text-ink-700 dark:text-ink-200">
          {t("admin.audit.targetId") || "Target ID"}
          <input
            type="text"
            aria-label={t("admin.audit.targetId") || "Target ID"}
            value={targetId}
            onChange={(e) => changeTargetId(e.target.value)}
            className={fieldClass}
          />
        </label>
      </div>

      {audit.isError ? (
        <div
          data-testid="section-error"
          role="status"
          className="rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-600 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-300"
        >
          {loadError}
        </div>
      ) : audit.isLoading ? (
        <div
          data-testid="section-loading"
          className="animate-pulse rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-400 dark:border-line-dark dark:bg-cardbg-dark"
        >
          {loadingText}
        </div>
      ) : (
        <DataTable
          rows={rows}
          rowKey={(row: any, index: number) => String(row._id || row.id || index)}
          emptyText={emptyText}
          page={page}
          hasMore={hasMore}
          onPageChange={(next) => setPage(Math.max(1, next))}
          columns={[
            {
              key: "timestamp",
              header: t("admin.audit.timestamp") || "Timestamp",
              className: "whitespace-nowrap",
              render: (row: any) => formatWhen(row.timestamp),
            },
            { key: "action", header: t("admin.audit.actionColumn") || "Action" },
            {
              key: "moderator",
              header: t("admin.audit.moderator") || "Moderator",
              render: (row: any) => personLabel(row.moderator),
            },
            {
              key: "target",
              header: t("admin.audit.target") || "Target",
              render: (row: any) => personLabel(row.target, row.targetEmail),
            },
            {
              key: "reason",
              header: t("admin.audit.reason") || "Reason",
              render: (row: any) => row.reason || "—",
            },
          ]}
        />
      )}
    </div>
  );
};

export default AdminAudit;
