import React, { useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { Flag, Users, X } from "lucide-react";
import { useArchiveAdminClubMutation } from "../../../store/slices/adminSlice";
import { Avatar, Badge } from "../../../design";
import ConfirmDialog from "./ConfirmDialog";

export interface ClubDetailDrawerProps {
  /** A row straight off `GET /admin/content/clubs` (a lean Club + `openReports`). */
  club: any;
  onClose: () => void;
}

const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString() : "—";

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

/**
 * Everything the club list already fetched, laid out so a moderator can decide
 * without opening the public page.
 *
 * `listClubs` returns the whole lean document with `owner` populated, so like
 * `MomentPreviewDrawer` this panel costs no extra request. `city` and `place`
 * are modelled but deliberately unreachable in the product today (see the Club
 * model's note) — they are shown here anyway because a club created before or
 * after that flag flips must look the same to moderation.
 */
const ClubDetailDrawer: React.FC<ClubDetailDrawerProps> = ({ club, onClose }) => {
  const { t } = useTranslation();
  const [archiveClub, archiveState] = useArchiveAdminClubMutation();
  const [confirming, setConfirming] = useState(false);
  const panelRef = useRef<HTMLDivElement | null>(null);

  const row: any = club || {};
  const isArchived = row.status === "archived";
  const owner = row.owner && typeof row.owner === "object" ? row.owner : null;
  const placeName = (row.place && row.place.name) || "";
  const where = [row.city, placeName].filter(Boolean).join(" · ");

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" && !confirming) onClose();
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [onClose, confirming]);

  useEffect(() => {
    if (panelRef.current) panelRef.current.focus();
  }, []);

  const openDialog = () => {
    if (typeof (archiveState as any).reset === "function") (archiveState as any).reset();
    setConfirming(true);
  };

  const confirm = async (reason: string) => {
    try {
      await archiveClub({ id: row._id, archived: !isArchived, reason }).unwrap();
      setConfirming(false);
      // `archiveAdminClub` invalidates `AdminContent`: the table behind this
      // panel refetches itself.
      onClose();
    } catch (e) {
      // Left open: the dialog renders the error and the moderator decides.
    }
  };

  const fieldLabel = "text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400";
  const fieldValue = "text-sm text-ink-800 dark:text-ink-100 break-words";

  const field = (label: string, value: React.ReactNode, testId?: string) => (
    <div>
      <div className={fieldLabel}>{label}</div>
      <div className={fieldValue} data-testid={testId}>
        {value}
      </div>
    </div>
  );

  const actionLabel = isArchived
    ? t("admin.content.restore") || "Restore"
    : t("admin.content.archive") || "Archive";

  return (
    <>
      <div
        data-testid="drawer-backdrop"
        onClick={onClose}
        className="fixed inset-0 z-[60] bg-ink-900/40"
      />
      <div
        ref={panelRef}
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        aria-label={t("admin.content.communityTitle") || "Community"}
        data-testid="club-detail-drawer"
        className={[
          "fixed inset-y-0 right-0 z-[61] w-full max-w-md overflow-y-auto",
          "border-l border-line bg-surface p-5 shadow-float outline-none",
          "dark:border-line-dark dark:bg-cardbg-dark",
        ].join(" ")}
      >
        <div className="flex items-start justify-between gap-3">
          <div>
            <h2 className="font-display text-base text-ink-900 dark:text-ink-50">
              {row.name || "—"}
            </h2>
            <div className="pt-1">
              <Badge tone={isArchived ? "banana" : "brand"}>
                {row.status || "active"}
              </Badge>
            </div>
          </div>
          <button
            type="button"
            data-testid="drawer-close"
            onClick={onClose}
            aria-label={t("admin.common.close") || "Close"}
            className="rounded-chip border border-line px-2 py-1 text-sm text-ink-600 hover:bg-ink-100 dark:border-line-dark dark:text-ink-300 dark:hover:bg-ink-800"
          >
            <X size={16} aria-hidden="true" />
          </button>
        </div>

        <p
          data-testid="club-description"
          className="mt-4 whitespace-pre-wrap text-sm text-ink-800 dark:text-ink-100"
        >
          {row.description || t("admin.content.noText") || "No text."}
        </p>

        <div className="mt-5 grid grid-cols-2 gap-4">
          {field(
            t("admin.content.owner") || "Owner",
            owner ? (
              <Link
                to={`/profile/${owner._id || owner.id}`}
                className="inline-flex items-center gap-2 text-brand-deep hover:underline dark:text-brand-light"
              >
                <Avatar
                  name={owner.name || "?"}
                  src={Array.isArray(owner.images) ? owner.images[0] : undefined}
                  size={24}
                />
                {owner.name || "—"}
              </Link>
            ) : (
              "—"
            )
          )}
          {field(
            t("admin.content.language") || "Language",
            row.languageLabel || row.language || "—",
            "club-language"
          )}
          {field(t("admin.content.place") || "Place", where || "—", "club-place")}
          {field(
            t("admin.content.members") || "Members",
            <span className="inline-flex items-center gap-1">
              <Users size={14} aria-hidden="true" className="text-ink-400 dark:text-ink-500" />
              <span className="tabular-nums">{num(row.memberCount)}</span>
            </span>,
            "club-members"
          )}
          {field(t("admin.content.created") || "Created", formatWhen(row.createdAt))}
          {field(
            t("admin.content.openReports") || "Open reports",
            <span className="inline-flex items-center gap-1">
              <Flag size={14} aria-hidden="true" className="text-ink-400 dark:text-ink-500" />
              <span className="tabular-nums">{num(row.openReports)}</span>
            </span>,
            "club-open-reports"
          )}
        </div>

        <div className="mt-6 flex flex-wrap gap-2 border-t border-line pt-4 dark:border-line-dark">
          <button
            type="button"
            data-testid={isArchived ? "club-restore" : "club-archive"}
            disabled={archiveState.isLoading}
            onClick={openDialog}
            className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
          >
            {actionLabel}
          </button>
        </div>
      </div>

      <ConfirmDialog
        open={confirming}
        title={
          isArchived
            ? t("admin.content.restoreTitle") || "Restore club"
            : t("admin.content.archiveTitle") || "Archive club"
        }
        body={
          isArchived
            ? t("admin.content.restoreBody") ||
              "It returns to discovery. The reason is recorded in the audit log."
            : t("admin.content.archiveBody") ||
              "It disappears from discovery. Members keep their history and it can be restored."
        }
        confirmLabel={actionLabel}
        cancelLabel={t("admin.common.cancel") || "Cancel"}
        requireReason
        danger={!isArchived}
        busy={archiveState.isLoading}
        error={errorText(
          archiveState.error,
          t("admin.content.actionFailed") || "That didn't work. Nothing was changed."
        )}
        onCancel={() => setConfirming(false)}
        onConfirm={confirm}
      />
    </>
  );
};

export default ClubDetailDrawer;
