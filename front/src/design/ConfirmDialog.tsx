import React, { useEffect, useRef, useState } from "react";
import DialogShell from "./DialogShell";

export interface ConfirmDialogProps {
  open: boolean;
  title: string;
  body?: React.ReactNode;
  confirmLabel: string;
  cancelLabel?: string;
  /** Ask for a moderation reason; confirm stays disabled until one is typed. */
  requireReason?: boolean;
  /** Show the reason field without requiring it -- notes the backend treats as optional. */
  showReason?: boolean;
  /**
   * Ask the moderator to retype this exact string (the user's email for a hard
   * delete). Case-sensitive on purpose: an irreversible action should cost a
   * deliberate keystroke, not a muscle-memory click.
   */
  requireTypedValue?: string;
  /** Red confirm button for destructive actions. */
  danger?: boolean;
  /** The reason is passed through trimmed; `""` when none was asked for. */
  onConfirm: (reason: string) => void;
  onCancel: () => void;
  /**
   * Mutation in flight. Confirm is disabled so nothing is sent twice, and so
   * is every way out of the dialog — Cancel, the backdrop and Escape. A
   * dialog that can be dismissed mid-request leaves the caller holding a
   * promise whose result has nowhere to land: the delete still happens, the
   * error never shows.
   */
  busy?: boolean;
  /**
   * The failure from the mutation, shown inside the dialog. The dialog stays
   * open on an error and nothing is retried automatically — a moderation call
   * that silently repeats is worse than one that visibly failed.
   */
  error?: React.ReactNode;
  reasonLabel?: string;
  typedLabel?: React.ReactNode;
  /**
   * Hard cap on the reason, with a live counter once the writer is close to
   * it. Pass the limit the backend enforces (a report's `description` is
   * capped at 500 by models/Report.js): a validation failure arriving after
   * the round trip is the worst possible moment to tell someone their
   * account of what happened was too long.
   */
  reasonMaxLength?: number;
}

/**
 * The one way the console asks "are you sure?".
 *
 * Every moderation action routes through this so the reason requirement the
 * backend enforces (`POST /users/:id/ban` 400s without one) is enforced in the
 * UI too, before the request is ever built.
 *
 * Escape, the backdrop, initial focus, focus restore, the body-scroll lock and
 * the Tab loop all live in DialogShell; this component owns only the question
 * it asks and the conditions under which it may be answered.
 */
const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  open,
  title,
  body,
  confirmLabel,
  cancelLabel = "Cancel",
  requireReason = false,
  showReason = false,
  requireTypedValue,
  danger = false,
  onConfirm,
  onCancel,
  busy = false,
  error,
  reasonLabel = "Reason",
  typedLabel,
  reasonMaxLength,
}) => {
  const [reason, setReason] = useState("");
  const [typed, setTyped] = useState("");
  const firstFieldRef = useRef<HTMLTextAreaElement | HTMLButtonElement | null>(null);

  // A reopened dialog starts empty: the previous action's reason must never be
  // carried into the next one.
  useEffect(() => {
    if (open) {
      setReason("");
      setTyped("");
    }
  }, [open]);

  if (!open) return null;

  const reasonOk = !requireReason || reason.trim().length > 0;
  const typedOk = !requireTypedValue || typed === requireTypedValue;
  const canConfirm = reasonOk && typedOk && !busy;

  const fieldClass = [
    "mt-1 w-full rounded-card border border-line bg-surface px-3 py-2 text-sm",
    "text-ink-900 placeholder:text-ink-400",
    "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
  ].join(" ");

  return (
    <DialogShell
      labelledBy="confirm-dialog-title"
      onClose={onCancel}
      testId="confirm-dialog"
      backdropTestId="confirm-dialog-backdrop"
      initialFocusRef={firstFieldRef}
      dismissible={!busy}
    >
      <h2
        id="confirm-dialog-title"
        className="font-display text-base text-ink-900 dark:text-ink-50"
      >
        {title}
      </h2>
      {body ? (
        <div className="pt-2 text-sm text-ink-600 dark:text-ink-300">{body}</div>
      ) : null}

      {requireReason || showReason ? (
        <label className="mt-4 block text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
          {reasonLabel}
          <textarea
            data-testid="confirm-dialog-reason"
            ref={(node) => {
              firstFieldRef.current = node;
            }}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={3}
            maxLength={reasonMaxLength}
            className={fieldClass}
          />
          {reasonMaxLength ? (
            <span
              data-testid="confirm-dialog-reason-count"
              className="mt-1 block text-right text-[11px] font-normal normal-case tracking-normal text-ink-400 dark:text-ink-500"
            >
              {`${reason.length} / ${reasonMaxLength}`}
            </span>
          ) : null}
        </label>
      ) : null}

      {requireTypedValue ? (
        <label className="mt-4 block text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
          {typedLabel || `Type ${requireTypedValue} to confirm`}
          <input
            data-testid="confirm-dialog-typed"
            type="text"
            value={typed}
            onChange={(e) => setTyped(e.target.value)}
            autoComplete="off"
            className={fieldClass}
          />
        </label>
      ) : null}

      {error ? (
        <div
          data-testid="confirm-dialog-error"
          role="alert"
          className="mt-4 rounded-card border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-500/40 dark:bg-red-500/10 dark:text-red-300"
        >
          {error}
        </div>
      ) : null}

      <div className="mt-5 flex justify-end gap-2">
        <button
          type="button"
          data-testid="confirm-dialog-cancel"
          onClick={onCancel}
          disabled={busy}
          className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
        >
          {cancelLabel}
        </button>
        <button
          type="button"
          data-testid="confirm-dialog-confirm"
          ref={(node) => {
            if (!requireReason) firstFieldRef.current = node;
          }}
          onClick={() => {
            if (!canConfirm) return;
            onConfirm(reason.trim());
          }}
          disabled={!canConfirm}
          aria-busy={busy}
          className={[
            "rounded-chip px-3 py-1.5 text-sm font-semibold text-white",
            "disabled:cursor-not-allowed disabled:opacity-50",
            danger ? "bg-red-600 hover:bg-red-700" : "bg-brand-deep hover:bg-brand-dark",
          ].join(" ")}
        >
          {confirmLabel}
        </button>
      </div>
    </DialogShell>
  );
};

export default ConfirmDialog;
