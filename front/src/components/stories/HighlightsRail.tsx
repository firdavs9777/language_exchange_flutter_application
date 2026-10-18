import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Bookmark } from "lucide-react";
import SurfaceCard from "../../design/SurfaceCard";
import { useGetUserHighlightsQuery } from "../../store/slices/storiesSlice";
import HighlightStoryViewer from "./HighlightStoryViewer";
import { storiesOf, coverOf, countOf } from "./highlightStories";

export interface HighlightsRailProps {
  /** Whose highlights. Absent while the profile is still loading. */
  userId?: string;
  /** The profile owner's name, for the viewer header. */
  name?: string;
}

/**
 * The row of saved story collections above someone's moments, as on the app's
 * member page (`highlights_row.dart`).
 *
 * Mount-then-decide: the component always mounts, asks
 * `GET /stories/highlights/user/:id` and renders *nothing* when the answer is
 * empty -- so a profile with no highlights shows no empty card and the parent
 * needs no second render path. It lives in the lazy profile chunk; the eager
 * `/moments` path never reaches it.
 */
const HighlightsRail: React.FC<HighlightsRailProps> = ({ userId, name }) => {
  const { t } = useTranslation();
  const [openId, setOpenId] = useState<string | null>(null);

  const { data } = useGetUserHighlightsQuery(userId || "", { skip: !userId });

  const all: any[] = Array.isArray(data && (data as any).data) ? (data as any).data : [];
  // A highlight with neither a cover nor a drawable story is a dud row: the
  // owner made it and never filled it. Nothing to show, so it is not shown.
  const highlights = all.filter(
    (item) => item && item._id && (coverOf(item) || storiesOf(item).length > 0)
  );

  if (highlights.length === 0) return null;

  const open = highlights.filter((item) => item._id === openId)[0];

  return (
    <SurfaceCard padding="lg">
      <section data-testid="highlights-rail">
        <h2 className="mb-3 text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
          {t("stories.highlights_title") || "Highlights"}
        </h2>

        <div className="-mx-1 flex gap-4 overflow-x-auto px-1 pb-1">
          {highlights.map((item) => {
            const cover = coverOf(item);
            return (
              <button
                key={item._id}
                type="button"
                data-testid="highlight-rail-item"
                onClick={() => setOpenId(item._id)}
                className="flex w-[72px] shrink-0 flex-col items-center gap-1.5 text-center"
              >
                <span className="rounded-full bg-gradient-to-tr from-brand via-banana to-brand-light p-[2px]">
                  <span className="block rounded-full bg-surface p-[2px] dark:bg-cardbg-dark">
                    {cover ? (
                      <img
                        data-testid="highlight-rail-cover"
                        src={cover}
                        alt={item.title || ""}
                        loading="lazy"
                        className="h-16 w-16 rounded-full object-cover"
                      />
                    ) : (
                      <span
                        data-testid="highlight-rail-placeholder"
                        className="flex h-16 w-16 items-center justify-center rounded-full bg-ink-100 text-ink-500 dark:bg-ink-800 dark:text-ink-400"
                      >
                        <Bookmark className="h-5 w-5" aria-hidden />
                      </span>
                    )}
                  </span>
                </span>
                <span className="w-full truncate text-xs font-semibold text-ink-700 dark:text-ink-200">
                  {item.title}
                </span>
                <span className="sr-only">{countOf(item)}</span>
              </button>
            );
          })}
        </div>

        {open ? (
          <HighlightStoryViewer
            highlight={open}
            authorName={name}
            onClose={() => setOpenId(null)}
          />
        ) : null}
      </section>
    </SurfaceCard>
  );
};

export default HighlightsRail;
