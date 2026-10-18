import React from "react";
import { useTranslation } from "react-i18next";
import DialogShell from "../../../design/DialogShell";

type Translate = (key: string, options?: any) => string;

export function deleteErrorText(err: any, t: Translate): string {
  const raw = String((err && err.data && (err.data.error || err.data.message)) || "");
  if (/within 1 hour/i.test(raw)) {
    return (
      t("chatPage.deleteMessage.tooLate") ||
      "You can only delete a message for everyone within 1 hour of sending it."
    );
  }
  return t("chatPage.deleteMessage.failed") || "Couldn't delete the message. Try again.";
}

export interface DeleteMessageDialogProps {
  canDeleteForEveryone: boolean;
  busy: boolean;
  error: string;
  onDelete: (forEveryone: boolean) => void;
  onCancel: () => void;
}

/** Replaces window.confirm. The same two choices as the app's delete sheet. */
const DeleteMessageDialog: React.FC<DeleteMessageDialogProps> = ({
  canDeleteForEveryone,
  busy,
  error,
  onDelete,
  onCancel,
}) => {
  const { t } = useTranslation();
  const button =
    "w-full rounded-chip px-3 py-2 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50";
  return (
    <DialogShell
      labelledBy="delete-message-title"
      onClose={onCancel}
      testId="delete-message-dialog"
      backdropTestId="delete-message-backdrop"
      dismissible={!busy}
    >
      <h2 id="delete-message-title" className="font-display text-base text-ink-900 dark:text-ink-50">
        {t("chatPage.deleteMessage.title") || "Delete message?"}
      </h2>
      {error ? (
        <div
          data-testid="delete-message-error"
          role="alert"
          className="mt-3 rounded-card border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-500/40 dark:bg-red-500/10 dark:text-red-300"
        >
          {error}
        </div>
      ) : null}
      <div className="mt-4 flex flex-col gap-2">
        {canDeleteForEveryone && (
          <button
            type="button"
            data-testid="delete-for-everyone"
            disabled={busy}
            onClick={() => onDelete(true)}
            className={`${button} bg-red-600 text-white hover:bg-red-700`}
          >
            {t("chatPage.deleteMessage.forEveryone") || "Delete for everyone"}
          </button>
        )}
        <button
          type="button"
          data-testid="delete-for-me"
          disabled={busy}
          onClick={() => onDelete(false)}
          className={`${button} border border-red-300 text-red-700 dark:border-red-500/40 dark:text-red-300`}
        >
          {t("chatPage.deleteMessage.forMe") || "Delete for me"}
        </button>
        <button
          type="button"
          data-testid="delete-message-cancel"
          disabled={busy}
          onClick={onCancel}
          className={`${button} border border-line text-ink-700 dark:border-line-dark dark:text-ink-200`}
        >
          {t("chatPage.deleteMessage.cancel") || "Cancel"}
        </button>
      </div>
    </DialogShell>
  );
};

export default DeleteMessageDialog;
