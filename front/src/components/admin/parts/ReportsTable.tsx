import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { MoreHorizontal } from "lucide-react";
import {
  useListReportsQuery,
  useReviewReportMutation,
  useResolveReportMutation,
  useDismissReportMutation,
} from "../../../store/slices/adminSlice";
import { Badge } from "../../../design";
import DataTable from "./DataTable";
import ConfirmDialog from "./ConfirmDialog";

/**
 * The reports queue.
 *
 * `GET /api/v1/reports` is NOT paginated (controllers/report.js returns the
 * newest 100, sorted desc, after filtering), so there are no page controls
 * here on purpose: offering a "next" over a hard 100-row window would lie. The
 * two selects are the only narrowing the backend exposes — `status` and `type`
 * — and the queue runs at zero backlog, so a filter beats a pager.
 *
 * Each action is exactly one backend call: `review` (no body), `resolve`
 * (`{ action, notes }` where `action` is the Report model's `moderatorAction`
 * enum — the server acts on it, banning or removing content), `dismiss`
 * (`{ notes }`). All three invalidate `AdminReports` + `AdminContentStats` +
 * `AdminMoments`, so the table and the stat strip above it refresh themselves.
 */

/** The Report model's `moderatorAction` enum, minus the `pending` default. */
const RESOLVE_ACTIONS = [
  "content_removed",
  "user_warned",
  "user_suspended",
  "user_banned",
  "no_violation",
];

const STATUSES = ["pending", "under_review", "resolved", "dismissed"];

/** The Report model's `type` enum, in the order the stat strip counts them. */
const TARGET_TYPES = ["moment", "comment", "user", "club", "gathering", "message", "story"];

/** A report is only actionable while it is still open. */
const isOpen = (status: string): boolean =>
  status === "pending" || status === "under_review";

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

const errorText = (error: any, fallback: string): string | undefined => {
  if (!error) return undefined;
  return (
    (error.data && (error.data.message || error.data.error)) || error.message || fallback
  );
};

/** A populated user, or nothing: an unpopulated id is not a person to link to. */
const person = (value: any): { id: string; name: string } | null => {
  if (!value || typeof value !== "object") return null;
  return { id: String(value._id || value.id || ""), name: value.name || value.email || "—" };
};

type Pending = { kind: "resolve" | "dismiss"; row: any } | null;

const ReportsTable: React.FC = () => {
  const { t } = useTranslation();
  const [status, setStatus] = useState("");
  const [targetType, setTargetType] = useState("");
  const [menuFor, setMenuFor] = useState<string | null>(null);
  const [pending, setPending] = useState<Pending>(null);
  const [resolveAction, setResolveAction] = useState(RESOLVE_ACTIONS[0]);

  const reports = useListReportsQuery({
    status: status || undefined,
    targetType: targetType || undefined,
  });

  const [reviewReport, reviewState] = useReviewReportMutation();
  const [resolveReport, resolveState] = useResolveReportMutation();
  const [dismissReport, dismissState] = useDismissReportMutation();

  // Close the row menu on any click outside it. Bound in an effect, never read
  // during render.
  useEffect(() => {
    if (!menuFor) return undefined;
    const onDocumentClick = (event: MouseEvent) => {
      const target = event.target as HTMLElement | null;
      if (target && target.closest && target.closest("[data-menu-root]")) return;
      setMenuFor(null);
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setMenuFor(null);
    };
    document.addEventListener("click", onDocumentClick);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("click", onDocumentClick);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [menuFor]);

  // `listReports` unwraps the `{ success, data }` envelope; the raw envelope is
  // read too so a transform change can't blank the queue.
  const payload: any = reports.data;
  const rows: any[] = Array.isArray(payload)
    ? payload
    : (payload && Array.isArray(payload.data) && payload.data) || [];

  const failed = t("admin.content.actionFailed") || "That didn't work. Nothing was changed.";
  const busy = resolveState.isLoading || dismissState.isLoading || reviewState.isLoading;

  const openDialog = (kind: "resolve" | "dismiss", row: any) => {
    const state: any = kind === "resolve" ? resolveState : dismissState;
    if (typeof state.reset === "function") state.reset();
    setResolveAction(RESOLVE_ACTIONS[0]);
    setMenuFor(null);
    setPending({ kind, row });
  };

  const startReview = async (row: any) => {
    setMenuFor(null);
    try {
      await reviewReport(String(row._id)).unwrap();
    } catch (e) {
      // The row keeps its status and the list refetches on the next poll —
      // nothing was changed, so nothing is claimed here.
    }
  };

  const confirm = async (notes: string) => {
    if (!pending) return;
    const id = String(pending.row._id);
    try {
      if (pending.kind === "resolve") {
        await resolveReport({ id, action: resolveAction, notes }).unwrap();
      } else {
        await dismissReport({ id, notes }).unwrap();
      }
      setPending(null);
    } catch (e) {
      // Left open: the dialog renders the error and the moderator decides.
    }
  };

  const selectClass = [
    "rounded-chip border border-line bg-surface px-2.5 py-1.5 text-sm text-ink-800",
    "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-100",
  ].join(" ");

  const menuItemClass = [
    "block w-full px-3 py-1.5 text-left text-sm text-ink-700 hover:bg-ink-100",
    "dark:text-ink-200 dark:hover:bg-ink-800",
  ].join(" ");

  const personCell = (value: any) => {
    const p = person(value);
    if (!p || !p.id) return <span className="text-ink-500 dark:text-ink-400">—</span>;
    return (
      <Link
        to={`/profile/${p.id}`}
        onClick={(e) => e.stopPropagation()}
        className="text-brand-deep hover:underline dark:text-brand-light"
      >
        {p.name}
      </Link>
    );
  };

  const columns = [
    { key: "type", header: t("admin.content.reportType") || "Type" },
    { key: "reason", header: t("admin.content.reason") || "Reason" },
    {
      key: "people",
      header: t("admin.content.reporterAndReported") || "Reporter → Reported",
      render: (row: any) => (
        <span className="inline-flex items-center gap-1">
          {personCell(row.reportedBy)}
          <span aria-hidden="true" className="text-ink-400 dark:text-ink-500">
            →
          </span>
          {personCell(row.reportedUser)}
        </span>
      ),
    },
    {
      key: "priority",
      header: t("admin.content.priority") || "Priority",
      render: (row: any) => (
        <Badge tone={row.priority === "high" || row.priority === "urgent" ? "banana" : "brand"}>
          {row.priority || "medium"}
        </Badge>
      ),
    },
    {
      key: "status",
      header: t("admin.content.status") || "Status",
      render: (row: any) => (
        <Badge tone={isOpen(row.status) ? "banana" : "brand"}>{row.status}</Badge>
      ),
    },
    {
      key: "createdAt",
      header: t("admin.content.created") || "Created",
      className: "whitespace-nowrap",
      render: (row: any) => formatWhen(row.createdAt),
    },
    {
      key: "actions",
      header: "",
      className: "text-right",
      render: (row: any) => {
        const id = String(row._id);
        if (!isOpen(row.status)) return null;
        return (
          <div data-menu-root="" className="relative inline-block text-left">
            <button
              type="button"
              data-testid={`report-menu-${id}`}
              aria-haspopup="menu"
              aria-expanded={menuFor === id}
              aria-label={t("admin.content.reportActions") || "Report actions"}
              disabled={busy}
              onClick={() => setMenuFor(menuFor === id ? null : id)}
              className="rounded-chip border border-line px-2 py-1 text-ink-700 hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
            >
              <MoreHorizontal size={16} aria-hidden="true" />
            </button>
            {menuFor === id ? (
              <div
                role="menu"
                className={[
                  "absolute right-0 z-20 mt-1 w-44 overflow-hidden rounded-card border border-line",
                  "bg-surface py-1 shadow-float dark:border-line-dark dark:bg-cardbg-dark",
                ].join(" ")}
              >
                {row.status === "pending" ? (
                  <button
                    type="button"
                    role="menuitem"
                    data-testid={`report-review-${id}`}
                    onClick={() => startReview(row)}
                    className={menuItemClass}
                  >
                    {t("admin.content.startReview") || "Start review"}
                  </button>
                ) : null}
                <button
                  type="button"
                  role="menuitem"
                  data-testid={`report-resolve-${id}`}
                  onClick={() => openDialog("resolve", row)}
                  className={menuItemClass}
                >
                  {t("admin.content.resolve") || "Resolve"}
                </button>
                <button
                  type="button"
                  role="menuitem"
                  data-testid={`report-dismiss-${id}`}
                  onClick={() => openDialog("dismiss", row)}
                  className={menuItemClass}
                >
                  {t("admin.content.dismiss") || "Dismiss"}
                </button>
              </div>
            ) : null}
          </div>
        );
      },
    },
  ];

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-3">
        <label className="flex items-center gap-2 text-sm text-ink-700 dark:text-ink-200">
          {t("admin.content.status") || "Status"}
          <select
            data-testid="reports-status-filter"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            className={selectClass}
          >
            <option value="">{t("admin.content.anyStatus") || "Any status"}</option>
            {STATUSES.map((value) => (
              <option key={value} value={value}>
                {t(`admin.content.reportStatus.${value}`) || value}
              </option>
            ))}
          </select>
        </label>

        <label className="flex items-center gap-2 text-sm text-ink-700 dark:text-ink-200">
          {t("admin.content.reportType") || "Type"}
          <select
            data-testid="reports-type-filter"
            value={targetType}
            onChange={(e) => setTargetType(e.target.value)}
            className={selectClass}
          >
            <option value="">{t("admin.content.anyType") || "Any type"}</option>
            {TARGET_TYPES.map((value) => (
              <option key={value} value={value}>
                {t(`admin.content.targetType.${value}`) || value}
              </option>
            ))}
          </select>
        </label>
      </div>

      {reports.isError ? (
        <div
          data-testid="section-error"
          role="status"
          className="rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-600 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-300"
        >
          {t("admin.common.loadError") || "Couldn't load this section."}
        </div>
      ) : reports.isLoading ? (
        <div
          data-testid="section-loading"
          className="animate-pulse rounded-card border border-line bg-surface px-4 py-3 text-sm text-ink-400 dark:border-line-dark dark:bg-cardbg-dark"
        >
          {t("admin.common.loading") || "Loading…"}
        </div>
      ) : (
        <DataTable
          rows={rows}
          rowKey="_id"
          columns={columns}
          emptyText={t("admin.common.empty") || "Nothing to show yet."}
          caption={t("admin.content.reports") || "Reports"}
        />
      )}

      <ConfirmDialog
        open={pending !== null && pending.kind === "resolve"}
        title={t("admin.content.resolveTitle") || "Resolve this report?"}
        body={
          <label className="block text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
            {t("admin.content.moderatorAction") || "Moderator action"}
            <select
              data-testid="resolve-action"
              value={resolveAction}
              onChange={(e) => setResolveAction(e.target.value)}
              className={`mt-1 w-full ${selectClass}`}
            >
              {RESOLVE_ACTIONS.map((value) => (
                <option key={value} value={value}>
                  {t(`admin.content.moderatorActions.${value}`) || value}
                </option>
              ))}
            </select>
          </label>
        }
        confirmLabel={t("admin.content.resolve") || "Resolve"}
        cancelLabel={t("admin.common.cancel") || "Cancel"}
        showReason
        reasonLabel={t("admin.content.notes") || "Notes"}
        busy={resolveState.isLoading}
        error={errorText(resolveState.error, failed)}
        onCancel={() => setPending(null)}
        onConfirm={confirm}
      />

      <ConfirmDialog
        open={pending !== null && pending.kind === "dismiss"}
        title={t("admin.content.dismissTitle") || "Dismiss this report?"}
        body={
          t("admin.content.dismissBody") ||
          "No action is taken against the reported content or user. The notes are kept on the report."
        }
        confirmLabel={t("admin.content.dismiss") || "Dismiss"}
        cancelLabel={t("admin.common.cancel") || "Cancel"}
        showReason
        reasonLabel={t("admin.content.notes") || "Notes"}
        busy={dismissState.isLoading}
        error={errorText(dismissState.error, failed)}
        onCancel={() => setPending(null)}
        onConfirm={confirm}
      />
    </div>
  );
};

export default ReportsTable;
