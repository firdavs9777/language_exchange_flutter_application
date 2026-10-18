import React from "react";
import { useTranslation } from "react-i18next";
import DialogShell from "../../../design/DialogShell";
import { MUTE_DURATIONS } from "../lib/muteDurations";

interface MuteDurationDialogProps {
  name: string;
  busy?: boolean;
  onChoose: (ms: number | null) => void;
  onCancel: () => void;
}

const OPTION =
  "w-full rounded-card px-3 py-3 text-start text-sm text-ink-700 hover:bg-ink-100 disabled:opacity-50 dark:text-ink-200 dark:hover:bg-ink-800";

/** "Mute Ada?" with the four lengths. Picking one is the confirmation. */
const MuteDurationDialog: React.FC<MuteDurationDialogProps> = ({ name, busy, onChoose, onCancel }) => {
  const { t } = useTranslation();
  return (
    <DialogShell
      labelledBy="chat-mute-title"
      onClose={onCancel}
      testId="chat-mute-dialog"
      backdropTestId="chat-mute-backdrop"
      dismissible={!busy}
    >
      <h2 id="chat-mute-title" className="font-display text-base text-ink-900 dark:text-ink-50">
        {t("chatPage.mute.title", { name: name }) || `Mute ${name}?`}
      </h2>
      <div className="mt-3 flex flex-col gap-0.5">
        {MUTE_DURATIONS.map((option) => (
          <button
            key={option.id}
            type="button"
            data-testid={`mute-option-${option.id}`}
            disabled={busy}
            onClick={() => onChoose(option.ms)}
            className={OPTION}
          >
            {t(option.key) || option.fallback}
          </button>
        ))}
      </div>
      <div className="mt-3 flex justify-end">
        <button
          type="button"
          data-testid="mute-cancel"
          onClick={onCancel}
          disabled={busy}
          className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
        >
          {t("chatPage.mute.cancel") || "Cancel"}
        </button>
      </div>
    </DialogShell>
  );
};

export default MuteDurationDialog;
