import React from "react";
import { useTranslation } from "react-i18next";
import DialogShell from "../../design/DialogShell";

export interface ConfirmDialogProps {
  title: string;
  body?: string;
  confirmLabel: string;
  danger?: boolean;
  busy?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmDialog: React.FC<ConfirmDialogProps> = ({ title, body, confirmLabel, danger, busy, onConfirm, onCancel }) => {
  const { t } = useTranslation();
  return (
    <DialogShell labelledBy="confirm-dialog-title" onClose={onCancel} testId="confirm-dialog" dismissible={!busy}>
      <h2 id="confirm-dialog-title" className="text-lg font-extrabold text-gray-900 dark:text-gray-50">
        {title}
      </h2>
      {body && <p className="mt-2 text-sm text-gray-600 dark:text-gray-300">{body}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <button type="button" data-testid="confirm-cancel" disabled={busy} onClick={onCancel} className="rounded-full px-4 py-2 text-sm font-bold">
          {t("gatherings.confirm.cancel") || "Not now"}
        </button>
        <button
          type="button"
          data-testid="confirm-ok"
          disabled={busy}
          onClick={onConfirm}
          className={`rounded-full px-4 py-2 text-sm font-extrabold text-white ${danger ? "bg-red-600" : "bg-brand"}`}
        >
          {confirmLabel}
        </button>
      </div>
    </DialogShell>
  );
};

export default ConfirmDialog;
