import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Heart, MessageCircle } from "lucide-react";
import SurfaceCard from "../../../design/SurfaceCard";
import ScheduledBadge from "../../moments/ScheduledBadge";
import { isScheduledLater } from "../../moments/lib/scheduling";
import { useGetMyMomentsQuery } from "../../../store/slices/momentsSlice";

export interface ProfileMomentsProps {
  /** Whose moments to show. Absent while the own profile is still loading. */
  userId?: string;
  isOwn: boolean;
  /**
   * Cap the grid at this many tiles. `GET /moments/user/:id` is unpaginated,
   * so a profile that embeds the section asks for a cap and leaves the rest
   * behind "See all"; the standalone uses pass nothing and show everything.
   */
  limit?: number;
}

/** How many skeleton tiles stand in for the grid while it loads. */
const SKELETONS = 6;

function countOf(value: any): number {
  if (Array.isArray(value)) return value.length;
  if (typeof value === "number" && isFinite(value)) return value;
  return 0;
}

function firstImage(moment: any): string {
  const urls = moment && (moment.imageUrls || moment.images);
  if (Array.isArray(urls)) {
    for (let i = 0; i < urls.length; i += 1) {
      const url = typeof urls[i] === "string" ? urls[i].trim() : "";
      if (url) return url;
    }
  }
  return "";
}

function captionOf(moment: any): string {
  const description = typeof moment.description === "string" ? moment.description.trim() : "";
  if (description) return description;
  return typeof moment.title === "string" ? moment.title.trim() : "";
}

/**
 * The person's moments as a grid of square tiles.
 *
 * A moment with a photo is the photo; a text-only moment is its own tile with
 * the text set large, rather than a grey box — moments are frequently text
 * only, and an empty square would read as a broken image. Counts are drawn
 * with `lucide-react`, never with emoji glyphs (inventory §3).
 */
const ProfileMoments: React.FC<ProfileMomentsProps> = ({ userId, isOwn, limit }) => {
  const { t } = useTranslation();

  const { data, isLoading } = useGetMyMomentsQuery(
    { userId: userId || "" },
    { skip: !userId }
  );

  const all: any[] = Array.isArray(data && (data as any).data) ? (data as any).data : [];
  const moments = limit && limit > 0 ? all.slice(0, limit) : all;
  const showSkeleton = isLoading && moments.length === 0;

  return (
    <SurfaceCard padding="lg">
      <section data-testid="profile-moments" id="moments">
        <div className="mb-3 flex items-center justify-between gap-3">
          <h2 className="text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
            {t("profile.stats.moments") || "Moments"}
          </h2>
          {/* Only the owner has a page listing every moment. Another person's
              feed has no route yet (P4), so their heading carries no link
              rather than a link that goes nowhere. */}
          {isOwn && (
            <Link
              to="/my-moments"
              data-testid="moments-see-all"
              className="text-xs font-extrabold text-brand-deep hover:underline dark:text-brand-light"
            >
              {t("profile.moments.see_all") || "See all"}
            </Link>
          )}
        </div>

        {showSkeleton && (
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {Array.from({ length: SKELETONS }).map((unused, index) => (
              <div
                key={index}
                data-testid="moment-skeleton"
                className="aspect-square animate-pulse rounded-chip bg-ink-100 dark:bg-ink-800"
              />
            ))}
          </div>
        )}

        {!showSkeleton && moments.length === 0 && (
          <p
            data-testid="moments-empty"
            className="py-6 text-center text-sm text-ink-500 dark:text-ink-400"
          >
            {isOwn
              ? t("profile.moments.empty_own") || "Share your first moment"
              : t("profile.moments.empty_other") || "No moments yet"}
          </p>
        )}

        {!showSkeleton && moments.length > 0 && (
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {moments.map((moment: any) => {
              const image = firstImage(moment);
              const caption = captionOf(moment);
              return (
                <Link
                  key={moment._id}
                  to={`/moment/${moment._id}`}
                  data-testid="moment-tile"
                  className="group relative block aspect-square overflow-hidden rounded-chip bg-ink-100 dark:bg-ink-800"
                >
                  {image ? (
                    <img
                      src={image}
                      alt={caption || t("profile.moments.photo_alt") || "Moment photo"}
                      loading="lazy"
                      data-testid="moment-tile-image"
                      className="h-full w-full object-cover transition-transform duration-200 group-hover:scale-[1.03]"
                    />
                  ) : (
                    <span
                      data-testid="moment-tile-text"
                      className="flex h-full w-full items-center justify-center overflow-hidden p-3 text-center text-xs font-semibold leading-snug text-ink-700 dark:text-ink-100"
                    >
                      {caption}
                    </span>
                  )}

                  {isOwn && isScheduledLater(moment) && (
                    <ScheduledBadge
                      at={moment.scheduledFor}
                      className="absolute left-1 top-1 inline-flex items-center gap-1 rounded-full bg-amber-100/95 px-2 py-0.5 text-[10px] font-semibold text-amber-800"
                    />
                  )}
                  <span className="absolute inset-x-0 bottom-0 flex items-center gap-3 bg-ink-950/50 px-2 py-1 text-[11px] font-semibold text-white">
                    <span data-testid="moment-likes" className="inline-flex items-center gap-1">
                      <Heart className="h-3 w-3" aria-hidden />
                      {countOf(moment.likeCount)}
                    </span>
                    <span data-testid="moment-comments" className="inline-flex items-center gap-1">
                      <MessageCircle className="h-3 w-3" aria-hidden />
                      {countOf(moment.commentCount)}
                    </span>
                  </span>
                </Link>
              );
            })}
          </div>
        )}
      </section>
    </SurfaceCard>
  );
};

export default ProfileMoments;
