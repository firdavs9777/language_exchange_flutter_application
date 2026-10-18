import React from "react";
import { X } from "lucide-react";
import { useTranslation } from "react-i18next";
import { PublicAnnouncement } from "../../store/slices/appConfigSlice";
import { useAnnouncementActions } from "./AnnouncementActions";

interface Props { announcement: PublicAnnouncement; onClose: () => void; preview?: boolean }

const AnnouncementBanner: React.FC<Props> = ({ announcement: a, onClose, preview = false }) => {
  const { t } = useTranslation();
  const { primary } = useAnnouncementActions(a, preview);
  return (
    <div className="px-3 pt-3 sm:px-6">
      <section role="region" aria-label={a.title} data-testid="ann-banner"
        className="mx-auto flex max-w-5xl items-center gap-3 rounded-2xl border border-ink-200 border-l-4 border-l-brand bg-surface px-3 py-2.5 shadow-[0_6px_20px_rgba(23,30,41,0.08)] dark:border-ink-700 dark:bg-cardbg-dark sm:px-4">
        <div aria-hidden="true" className="grid h-9 w-9 flex-none place-items-center rounded-xl bg-brand/10 text-lg">{a.emoji || "📢"}</div>
        <div className="min-w-0 flex-1">
          <div className="truncate text-sm font-bold text-ink-900 dark:text-ink-50">{a.title}</div>
          <div data-testid="ann-banner-body" className="truncate text-xs text-ink-500 dark:text-ink-300">{a.body}</div>
        </div>
        {primary && a.buttonLabel ? (
          <button type="button" data-testid="ann-banner-cta" onClick={primary}
            className="flex-none whitespace-nowrap rounded-full bg-brand-deep px-3.5 py-1.5 text-xs font-semibold text-white hover:bg-brand-deepest">
            {a.buttonLabel}
          </button>
        ) : null}
        <button type="button" aria-label={t("announcements.close")} onClick={onClose}
          className="grid h-7 w-7 flex-none place-items-center rounded-full text-ink-400 hover:bg-ink-100 hover:text-ink-700 dark:hover:bg-ink-800">
          <X size={14} />
        </button>
      </section>
    </div>
  );
};

export default AnnouncementBanner;
