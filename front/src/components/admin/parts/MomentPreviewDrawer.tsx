import React, { useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { Heart, MessageCircle, Eye, Share2, Flag, X } from "lucide-react";
import { useSetMomentHiddenMutation } from "../../../store/slices/adminSlice";
import { Avatar, Badge } from "../../../design";
import ConfirmDialog from "./ConfirmDialog";

export interface MomentPreviewDrawerProps {
  /** A row straight off `GET /admin/content/moments` — see `AdminMomentRow`. */
  moment: any;
  onClose: () => void;
}

const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString() : "—";

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

/** The server's message when it has one; never a raw status object. */
const errorText = (error: any, fallback: string): string | undefined => {
  if (!error) return undefined;
  return (
    (error.data && (error.data.message || error.data.error)) || error.message || fallback
  );
};

/**
 * One moment, big enough to judge, and the single action a moderator can take
 * on it.
 *
 * The row the table already holds IS the preview: `listMoments` returns a
 * projection with the image, the (truncated) text, the author and every count,
 * so opening this panel costs no request. There is no `GET /moments/:id` on the
 * admin side to fetch a longer body from — if the description a moderator needs
 * is past the backend's 200-character preview, the answer is to widen that
 * projection, not to add a second round trip here.
 *
 * Hide/Unhide goes through `ConfirmDialog` so the reason the audit log records
 * is typed before the request is built, and a failure keeps the dialog open
 * rather than closing the panel over the moderator's work.
 */
const MomentPreviewDrawer: React.FC<MomentPreviewDrawerProps> = ({ moment, onClose }) => {
  const { t } = useTranslation();
  const [setHidden, hideState] = useSetMomentHiddenMutation();
  const [confirming, setConfirming] = useState(false);
  const panelRef = useRef<HTMLDivElement | null>(null);

  const row: any = moment || {};
  const isHidden = !!row.isDeleted;
  const author = row.user || null;

  // Escape closes the drawer — unless the confirm dialog is open, which owns
  // Escape while it is up.
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
    // RTK Query keeps `error` until something resets it: a dialog reopened
    // after a failure would otherwise describe something no longer happening.
    if (typeof (hideState as any).reset === "function") (hideState as any).reset();
    setConfirming(true);
  };

  const confirm = async (reason: string) => {
    try {
      await setHidden({ id: row.id, hidden: !isHidden, reason }).unwrap();
      setConfirming(false);
      // The list and the stat strip refetch on their own: `setMomentHidden`
      // invalidates `AdminMoments` + `AdminContentStats`.
      onClose();
    } catch (e) {
      // Left open: the dialog renders the error and the moderator decides.
    }
  };

  const fieldLabel = "text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400";
  const fieldValue = "text-sm text-ink-800 dark:text-ink-100 break-words";

  const field = (label: string, value: React.ReactNode) => (
    <div>
      <div className={fieldLabel}>{label}</div>
      <div className={fieldValue}>{value}</div>
    </div>
  );

  const count = (icon: React.ReactNode, label: string, value: any) => (
    <span className="inline-flex items-center gap-1 text-sm text-ink-700 dark:text-ink-200">
      <span aria-hidden="true" className="text-ink-400 dark:text-ink-500">
        {icon}
      </span>
      <span className="sr-only">{label}</span>
      <span className="tabular-nums">{num(value)}</span>
    </span>
  );

  const hideLabel = isHidden
    ? t("admin.content.unhide") || "Unhide"
    : t("admin.content.hide") || "Hide";

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
        aria-label={t("admin.content.momentTitle") || "Moment"}
        data-testid="moment-preview-drawer"
        className={[
          "fixed inset-y-0 right-0 z-[61] w-full max-w-md overflow-y-auto",
          "border-l border-line bg-surface p-5 shadow-float outline-none",
          "dark:border-line-dark dark:bg-cardbg-dark",
        ].join(" ")}
      >
        <div className="flex items-start justify-between gap-3">
          <div>
            <h2 className="font-display text-base text-ink-900 dark:text-ink-50">
              {row.title || t("admin.content.untitled") || "Untitled moment"}
            </h2>
            <div className="pt-1 text-xs text-ink-500 dark:text-ink-400">
              {formatWhen(row.createdAt)}
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

        {isHidden ? (
          <div data-testid="moment-hidden-badge" className="pt-3">
            <Badge tone="banana">{t("admin.content.hidden") || "Hidden"}</Badge>
          </div>
        ) : null}

        {row.imageUrl ? (
          <img
            src={row.imageUrl}
            alt={row.title || t("admin.content.momentTitle") || "Moment"}
            data-testid="moment-image"
            className="mt-4 max-h-72 w-full rounded-card object-cover"
          />
        ) : null}

        <p
          data-testid="moment-text"
          className="mt-4 whitespace-pre-wrap text-sm text-ink-800 dark:text-ink-100"
        >
          {row.description || t("admin.content.noText") || "No text."}
        </p>

        <div data-testid="moment-counts" className="mt-4 flex flex-wrap items-center gap-4">
          {count(<Heart size={14} />, t("admin.content.likes") || "Likes", row.likeCount)}
          {count(
            <MessageCircle size={14} />,
            t("admin.content.comments") || "Comments",
            row.commentCount
          )}
          {count(<Eye size={14} />, t("admin.content.views") || "Views", row.viewCount)}
          {count(<Share2 size={14} />, t("admin.content.shares") || "Shares", row.shareCount)}
        </div>

        <div className="mt-5 grid grid-cols-2 gap-4">
          {field(
            t("admin.content.author") || "Author",
            author ? (
              <Link
                to={`/profile/${author.id}`}
                className="inline-flex items-center gap-2 text-brand-deep hover:underline dark:text-brand-light"
              >
                <Avatar name={author.name || "?"} src={author.image || undefined} size={24} />
                {author.name || "—"}
              </Link>
            ) : (
              "—"
            )
          )}
          {field(t("admin.content.language") || "Language", row.language || "—")}
          {field(t("admin.content.category") || "Category", row.category || "—")}
          {field(
            t("admin.content.openReports") || "Open reports",
            <span data-testid="moment-open-reports" className="inline-flex items-center gap-1">
              <Flag size={14} aria-hidden="true" className="text-ink-400 dark:text-ink-500" />
              <span className="tabular-nums">{num(row.openReports)}</span>
            </span>
          )}
        </div>

        <div className="mt-6 flex flex-wrap gap-2 border-t border-line pt-4 dark:border-line-dark">
          <button
            type="button"
            data-testid={isHidden ? "moment-unhide" : "moment-hide"}
            disabled={hideState.isLoading}
            onClick={openDialog}
            className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
          >
            {hideLabel}
          </button>
        </div>
      </div>

      <ConfirmDialog
        open={confirming}
        title={
          isHidden
            ? t("admin.content.unhideTitle") || "Unhide this moment?"
            : t("admin.content.hideTitle") || "Hide this moment?"
        }
        body={
          isHidden
            ? t("admin.content.unhideBody") ||
              "It returns to the feed. The reason is recorded in the audit log."
            : t("admin.content.hideBody") ||
              "It disappears from every feed. The reason is recorded in the audit log."
        }
        confirmLabel={hideLabel}
        cancelLabel={t("admin.common.cancel") || "Cancel"}
        requireReason
        danger={!isHidden}
        busy={hideState.isLoading}
        error={errorText(
          hideState.error,
          t("admin.content.actionFailed") || "That didn't work. Nothing was changed."
        )}
        onCancel={() => setConfirming(false)}
        onConfirm={confirm}
      />
    </>
  );
};

export default MomentPreviewDrawer;
