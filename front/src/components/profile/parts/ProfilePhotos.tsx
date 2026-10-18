import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ChevronLeft, ChevronRight, ImagePlus, X } from "lucide-react";
import SurfaceCard from "../../../design/SurfaceCard";
import { trapTab, useBodyScrollLock } from "../../../design/dialogChrome";

export interface ProfilePhotosProps {
  /** `user.imageUrls` as the API returns it — unvalidated. */
  images: any;
  isOwn: boolean;
  /** Whose photos these are; used for the alt text. */
  name?: string;
  /**
   * Open the viewer on this index from outside — the profile header's avatar
   * is the same picture as tile 0, and tapping it should show the photo.
   * Set it to a number to open, and the owner clears it back to null when
   * `onOpenHandled` fires.
   */
  openAt?: number | null;
  onOpenHandled?: () => void;
}

/** The URLs that are actually renderable, in order, blanks dropped. */
function cleanImages(images: any): string[] {
  if (!Array.isArray(images)) return [];
  const urls: string[] = [];
  for (let i = 0; i < images.length; i += 1) {
    const url = typeof images[i] === "string" ? images[i].trim() : "";
    if (url) urls.push(url);
  }
  return urls;
}

/**
 * The person's photos, own profile and anyone else's alike.
 *
 * Replaces the old `PhotoGrid` + `ImageViewer/ImageModal` pair, which drew its
 * lightbox with react-bootstrap's `Modal`/`Carousel` (inventory §3) and could
 * be neither closed with Escape nor walked with the keyboard. This one is a
 * plain dialog: Escape closes it, the arrow keys move through the set, Tab is
 * trapped inside it, and focus returns to the tile that opened it.
 *
 * The first photo is also the avatar, so it is deliberately left in the grid —
 * a person's photo set reads wrong with its best-known picture missing.
 */
const ProfilePhotos: React.FC<ProfilePhotosProps> = ({ images, isOwn, name, openAt, onOpenHandled }) => {
  const { t } = useTranslation();
  const photos = useMemo(() => cleanImages(images), [images]);

  // An open asked for from outside. Guarded on the index existing, so a stale
  // request cannot open an empty viewer on a profile whose photos have gone.
  useEffect(() => {
    if (openAt === null || openAt === undefined) return;
    if (openAt >= 0 && openAt < photos.length) setOpenIndex(openAt);
    if (onOpenHandled) onOpenHandled();
  }, [openAt, photos.length, onOpenHandled]);
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const dialogRef = useRef<HTMLDivElement | null>(null);
  const closeRef = useRef<HTMLButtonElement | null>(null);
  // The tile that opened the dialog, so focus has somewhere to go back to.
  const opener = useRef<HTMLElement | null>(null);

  const open = openIndex !== null;
  const count = photos.length;

  const close = useCallback(() => {
    setOpenIndex(null);
    // Returning focus to the body would silently drop the keyboard user back
    // at the top of the page.
    if (opener.current && opener.current.focus) opener.current.focus();
  }, []);

  const step = useCallback(
    (delta: number) => {
      setOpenIndex((current) => {
        if (current === null || count === 0) return current;
        return (current + delta + count) % count;
      });
    },
    [count]
  );

  // Escape and the arrow keys. Bound in an effect, never read during render.
  useEffect(() => {
    if (!open) return undefined;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        close();
      } else if (event.key === "ArrowRight") {
        event.preventDefault();
        step(1);
      } else if (event.key === "ArrowLeft") {
        event.preventDefault();
        step(-1);
      }
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [open, close, step]);

  // The dialog takes focus when it opens.
  useEffect(() => {
    if (open && closeRef.current) closeRef.current.focus();
  }, [open]);

  // Body-scroll lock and the Tab trap are the shared dialog chrome
  // (design/dialogChrome), which ConfirmDialog uses too -- two overlays on the
  // same page must not behave differently under Tab.
  useBodyScrollLock(open);

  if (count === 0) return null;

  const who = (name || "").trim();
  const altFor = (index: number): string =>
    t("profile.photos.alt", { name: who, index: index + 1 }) ||
    (who ? `${who}, photo ${index + 1}` : `Photo ${index + 1}`);

  const current = openIndex === null ? 0 : openIndex;

  return (
    <SurfaceCard padding="md">
      <section data-testid="profile-photos">
        <div className="mb-3 flex items-center justify-between gap-3">
          <h2 className="text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
            {t("profile.photos.title") || "Photos"}
          </h2>
          {isOwn && (
            <Link
              to="/profile/edit"
              data-testid="photos-add"
              className="inline-flex items-center gap-1 text-xs font-extrabold text-brand-deep hover:underline dark:text-brand-light"
            >
              <ImagePlus className="h-3.5 w-3.5" aria-hidden />
              {t("profile.photos.add") || "Add photos"}
            </Link>
          )}
        </div>

        {/* Two per row on a phone (~165px a tile), three once there is room.
            At three across a phone tile is ~110px, too small to read a face in
            -- and the tiles are how someone decides to open the viewer. */}
        <ul className="grid grid-cols-2 gap-2 sm:grid-cols-3">
          {photos.map((url, index) => (
            <li key={`${index}-${url}`}>
              <button
                type="button"
                data-testid="photo-tile"
                onClick={(event) => {
                  opener.current = event.currentTarget;
                  setOpenIndex(index);
                }}
                aria-label={t("profile.photos.open", { index: index + 1 }) || altFor(index)}
                className="block aspect-square w-full overflow-hidden rounded-chip bg-ink-100 dark:bg-ink-800"
              >
                <img
                  src={url}
                  /* Decorative: the button around it already carries the
                     accessible name, and a second one would be read twice. */
                  alt=""
                  loading="lazy"
                  data-testid="photo-tile-image"
                  className="h-full w-full object-cover transition-transform duration-200 hover:scale-[1.03]"
                />
              </button>
            </li>
          ))}
        </ul>

        {open && (
          <div className="fixed inset-0 z-[70] flex items-center justify-center p-4">
            <div
              data-testid="photo-lightbox-backdrop"
              onClick={close}
              className="absolute inset-0 bg-ink-950/80"
            />
            <div
              ref={dialogRef}
              role="dialog"
              aria-modal="true"
              aria-label={t("profile.photos.title") || "Photos"}
              data-testid="photo-lightbox"
              onKeyDown={(event) => trapTab(dialogRef.current, event)}
              className="relative flex w-full max-w-3xl flex-col items-center gap-3"
            >
              <img
                src={photos[current]}
                alt={altFor(current)}
                data-testid="photo-lightbox-image"
                className="max-h-[70vh] w-auto max-w-full rounded-card object-contain"
              />

              <p
                data-testid="photo-lightbox-counter"
                className="text-sm font-semibold text-white"
              >
                {t("profile.photos.counter", { index: current + 1, total: count }) ||
                  `${current + 1} / ${count}`}
              </p>

              <button
                type="button"
                ref={closeRef}
                data-testid="photo-lightbox-close"
                onClick={close}
                aria-label={t("profile.photos.close") || "Close"}
                className="absolute right-0 top-0 rounded-full bg-ink-950/60 p-2 text-white transition-colors hover:bg-ink-950/80"
              >
                <X className="h-5 w-5" aria-hidden />
              </button>

              {count > 1 && (
                <React.Fragment>
                  <button
                    type="button"
                    data-testid="photo-lightbox-prev"
                    onClick={() => step(-1)}
                    aria-label={t("profile.photos.previous") || "Previous photo"}
                    className="absolute left-0 top-1/2 -translate-y-1/2 rounded-full bg-ink-950/60 p-2 text-white transition-colors hover:bg-ink-950/80"
                  >
                    <ChevronLeft className="h-5 w-5" aria-hidden />
                  </button>
                  <button
                    type="button"
                    data-testid="photo-lightbox-next"
                    onClick={() => step(1)}
                    aria-label={t("profile.photos.next") || "Next photo"}
                    className="absolute right-0 top-1/2 -translate-y-1/2 rounded-full bg-ink-950/60 p-2 text-white transition-colors hover:bg-ink-950/80"
                  >
                    <ChevronRight className="h-5 w-5" aria-hidden />
                  </button>
                </React.Fragment>
              )}
            </div>
          </div>
        )}
      </section>
    </SurfaceCard>
  );
};

export default ProfilePhotos;
