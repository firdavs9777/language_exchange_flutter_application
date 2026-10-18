import React, { useEffect, useRef, useState } from "react";
import { X } from "lucide-react";
import { useTranslation } from "react-i18next";
import { PublicAnnouncement } from "../../store/slices/appConfigSlice";
import { trapTab, useBodyScrollLock } from "../../design/dialogChrome";
import { useAnnouncementActions } from "./AnnouncementActions";

interface Props {
  announcement: PublicAnnouncement;
  /** remember = true for ✕ / Escape (don't show again); false for a backdrop click. */
  onClose: (remember: boolean) => void;
  preview?: boolean;
}

const AnnouncementModal: React.FC<Props> = ({ announcement: a, onClose, preview = false }) => {
  const { t } = useTranslation();
  const { primary, readMore } = useAnnouncementActions(a, preview);
  // Track the URL that failed, so a new URL (or a first upload) is tried afresh.
  const [failedUrl, setFailedUrl] = useState<string | null>(null);
  const imageOk = !!a.imageUrl && failedUrl !== a.imageUrl;
  const closeRef = useRef<HTMLButtonElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const titleId = `ann-title-${a.id}`;

  useBodyScrollLock(!preview);

  useEffect(() => {
    if (preview) return;
    const opener = document.activeElement as HTMLElement | null;
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(true); };
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("keydown", onKey);
      if (opener && typeof opener.focus === "function" && document.contains(opener)) opener.focus();
    };
  }, [onClose, preview]);

  const card = (
    <div ref={panelRef} data-testid="ann-modal"
      {...(preview
        ? { role: "group", "aria-label": "Website pop-up preview" }
        : { role: "dialog", "aria-modal": true, "aria-labelledby": titleId })}
      onKeyDown={preview ? undefined : (e) => trapTab(panelRef.current, e)}
      onClick={(e) => e.stopPropagation()}
      className={`relative w-full rounded-t-3xl bg-surface shadow-float dark:bg-cardbg-dark sm:max-w-[420px] sm:rounded-3xl ${
        preview ? "overflow-hidden" : "max-h-[90dvh] overflow-y-auto"}`}>
      <button ref={closeRef} type="button" aria-label={t("announcements.close")} onClick={() => onClose(true)}
        className="absolute right-3 top-3 z-10 grid h-8 w-8 place-items-center rounded-full bg-white/25 text-white backdrop-blur hover:bg-white/40 focus:outline-none focus-visible:ring-2 focus-visible:ring-white">
        <X size={16} />
      </button>
      {imageOk && a.imageUrl ? (
        <img data-testid="ann-hero-image" src={a.imageUrl} alt="" onError={() => setFailedUrl(a.imageUrl)}
          className="h-40 w-full object-cover sm:h-44" />
      ) : (
        <div className="grid h-36 place-items-center bg-gradient-to-br from-brand-deepest via-brand to-brand-light sm:h-40">
          <span data-testid="ann-hero-emoji" aria-hidden="true" className="text-6xl drop-shadow">{a.emoji || "📢"}</span>
        </div>
      )}
      <div className="px-6 pb-5 pt-5">
        <span className="inline-block rounded-full bg-banana-light/60 px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wide text-ink-800">
          {t("announcements.new")}
        </span>
        <h2 id={titleId} className="mt-2.5 text-xl font-bold text-ink-900 dark:text-ink-50">{a.title}</h2>
        <p className="mt-2 line-clamp-5 whitespace-pre-line text-[15px] leading-relaxed text-ink-600 dark:text-ink-300">{a.body}</p>
        <div className="mt-5 grid gap-1.5">
          {primary && a.buttonLabel ? (
            <button type="button" onClick={primary}
              className="w-full rounded-xl bg-brand-deep px-4 py-3 text-[15px] font-bold text-white transition hover:bg-brand-deepest focus:outline-none focus-visible:ring-2 focus-visible:ring-brand">
              {a.buttonLabel}
            </button>
          ) : null}
          <button type="button" onClick={readMore}
            className="w-full rounded-xl px-4 py-2 text-sm font-semibold text-ink-500 hover:text-ink-800 dark:hover:text-ink-100">
            {t("announcements.readMore")}
          </button>
        </div>
      </div>
    </div>
  );

  if (preview) return card;

  return (
    <div data-testid="ann-backdrop" onClick={() => onClose(false)}
      className="fixed inset-0 z-[60] flex items-end justify-center bg-ink-900/55 backdrop-blur-sm sm:items-center sm:p-4">
      {card}
    </div>
  );
};

export default AnnouncementModal;
