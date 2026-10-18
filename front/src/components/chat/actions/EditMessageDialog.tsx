import React, { useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import DialogShell from "../../../design/DialogShell";

/** The backend's own cap (controllers/messageManagement.js editMessage). */
export const EDIT_MAX_LENGTH = 2000;

type Translate = (key: string, options?: any) => string;

/**
 * What to tell the writer when an edit is refused. Only the 15-minute window
 * is worth naming — it is the one refusal a person can understand and stop
 * trying; everything else (validator text, 403, network) reads as "try again".
 */
export function editErrorText(err: any, t: Translate): string {
  const raw = String((err && err.data && (err.data.error || err.data.message)) || "");
  if (/15 minutes/i.test(raw)) {
    return (
      t("chatPage.editDialog.tooLate") ||
      "You can only edit a message within 15 minutes of sending it."
    );
  }
  return t("chatPage.editDialog.failed") || "Couldn't edit the message. Try again.";
}

export interface EditMessageDialogProps {
  initialText: string;
  busy: boolean;
  error: string;
  onSave: (text: string) => void;
  onCancel: () => void;
}

/** Replaces window.prompt: same rules as the app's edit sheet (non-empty, changed, <= 2000). */
const EditMessageDialog: React.FC<EditMessageDialogProps> = ({
  initialText,
  busy,
  error,
  onSave,
  onCancel,
}) => {
  const { t } = useTranslation();
  const [text, setText] = useState(initialText || "");
  const inputRef = useRef<HTMLTextAreaElement | null>(null);
  const trimmed = text.trim();
  const canSave = !busy && trimmed.length > 0 && trimmed !== (initialText || "").trim();

  return (
    <DialogShell
      labelledBy="edit-message-title"
      onClose={onCancel}
      testId="edit-message-dialog"
      backdropTestId="edit-message-backdrop"
      initialFocusRef={inputRef}
      dismissible={!busy}
    >
      <h2 id="edit-message-title" className="font-display text-base text-ink-900 dark:text-ink-50">
        {t("chatPage.editDialog.title") || "Edit message"}
      </h2>
      <textarea
        ref={inputRef}
        data-testid="edit-message-input"
        aria-label={t("chatPage.editDialog.label") || "Message"}
        value={text}
        maxLength={EDIT_MAX_LENGTH}
        rows={4}
        dir="auto"
        onChange={(e) => setText(e.target.value)}
        className="mt-3 w-full rounded-card border border-line bg-surface px-3 py-2 text-sm text-ink-900 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50"
      />
      {error ? (
        <div
          data-testid="edit-message-error"
          role="alert"
          className="mt-3 rounded-card border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-500/40 dark:bg-red-500/10 dark:text-red-300"
        >
          {error}
        </div>
      ) : null}
      <div className="mt-4 flex justify-end gap-2">
        <button
          type="button"
          data-testid="edit-message-cancel"
          onClick={onCancel}
          disabled={busy}
          className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 disabled:opacity-50 dark:border-line-dark dark:text-ink-200"
        >
          {t("chatPage.editDialog.cancel") || "Cancel"}
        </button>
        <button
          type="button"
          data-testid="edit-message-save"
          onClick={() => canSave && onSave(trimmed)}
          disabled={!canSave}
          aria-busy={busy}
          className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white disabled:opacity-50"
        >
          {t("chatPage.editDialog.save") || "Save"}
        </button>
      </div>
    </DialogShell>
  );
};

export default EditMessageDialog;
