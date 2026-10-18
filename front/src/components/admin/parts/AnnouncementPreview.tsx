import React from "react";

export interface AnnouncementPreviewProps {
  emoji: string;
  imageUrl: string;
  title: string;
  body: string;
  buttonLabel: string;
}

/**
 * What the app's AnnouncementModal shows (lib/widgets/promo/announcement_modal.dart):
 * emoji, optional image, title, body and one button. A visual stand-in, not a
 * pixel copy — it exists so an admin sees line breaks and length before
 * publishing to everyone.
 */
const AnnouncementPreview: React.FC<AnnouncementPreviewProps> = ({ emoji, imageUrl, title, body, buttonLabel }) => (
  <div
    data-testid="announcement-preview"
    className="mx-auto w-full max-w-xs rounded-3xl border border-line bg-white p-5 text-center shadow-card dark:border-line-dark dark:bg-ink-900"
  >
    {emoji ? <div className="text-4xl" aria-hidden="true">{emoji}</div> : null}
    {imageUrl ? (
      <img data-testid="preview-image" src={imageUrl} alt="" className="mt-3 max-h-40 w-full rounded-card object-cover" />
    ) : null}
    <div className="mt-3 text-lg font-bold text-ink-900 dark:text-ink-50">{title || "Title"}</div>
    <p className="mt-2 whitespace-pre-line text-sm text-ink-600 dark:text-ink-300">{body || "Body"}</p>
    {buttonLabel ? (
      <div className="mt-4 rounded-chip bg-brand-deep px-4 py-2 text-sm font-semibold text-white">{buttonLabel}</div>
    ) : null}
  </div>
);

export default AnnouncementPreview;
