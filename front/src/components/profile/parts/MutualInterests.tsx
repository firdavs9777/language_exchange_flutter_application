import React from "react";
import { useTranslation } from "react-i18next";
import { Check, Sparkles } from "lucide-react";
import SurfaceCard from "../../../design/SurfaceCard";

/** How many chips the card draws before it stops. */
const MAX_CHIPS = 12;

function topicsOf(user: any): string[] {
  const raw = user && user.topics;
  if (!Array.isArray(raw)) return [];
  const out: string[] = [];
  const seen: Record<string, boolean> = {};
  raw.forEach((entry: any) => {
    const name =
      typeof entry === "string"
        ? entry
        : String((entry && (entry.id || entry.name)) || "");
    const trimmed = name.trim();
    if (!trimmed) return;
    const key = trimmed.toLowerCase();
    if (seen[key]) return;
    seen[key] = true;
    out.push(trimmed);
  });
  return out;
}

/**
 * The topics both people picked, in the profile's own order.
 *
 * The app shows the shared topics first and the rest muted behind them
 * (single_community_topics.dart); on the web the non-shared topics are
 * already on the profile, so this card is strictly the intersection — and
 * with an empty intersection it is not a card at all, because "0 interests in
 * common" is a worse answer than silence.
 */
export function sharedTopics(viewer: any, user: any): string[] {
  const mine = topicsOf(viewer).map((topic) => topic.toLowerCase());
  if (mine.length === 0) return [];
  return topicsOf(user).filter((topic) => mine.indexOf(topic.toLowerCase()) !== -1);
}

export interface MutualInterestsProps {
  viewer?: any;
  user?: any;
  /** Render the contents alone, for a caller that draws the card itself. */
  bare?: boolean;
}

/** Whether this section has anything to show. Reuses the exported selector. */
export const hasMutualInterests = (viewer: any, user: any): boolean =>
  !!viewer && sharedTopics(viewer, user).length > 0;

const MutualInterests: React.FC<MutualInterestsProps> = ({ viewer, user, bare }) => {
  const { t } = useTranslation();
  const shared = sharedTopics(viewer, user);

  if (!hasMutualInterests(viewer, user)) return null;

  const body = (
    <>
      <div data-testid="mutual-interests">
        <div className="flex items-center gap-2">
          <Sparkles className="h-4 w-4 text-brand" aria-hidden />
          <h2 className="text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
            {t("communityDetail.mutual.title") || "Mutual interests"}
          </h2>
        </div>

        <p className="mt-1 text-sm text-ink-500 dark:text-ink-400">
          {/* `countLabel`, not `count`: an i18next key given a `count`
              option is treated as pluralisable, and a key literally named
              `count` invites a `count_other` collision across the 18 locales
              and their six plural rule sets. */}
          {t("communityDetail.mutual.countLabel", { count: shared.length }) ||
            `${shared.length} in common`}
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          {shared.slice(0, MAX_CHIPS).map((topic) => (
            <span
              key={topic}
              data-testid="mutual-interest-chip"
              className="inline-flex items-center gap-1.5 rounded-chip bg-brand/[0.12] px-2.5 py-1 text-xs font-semibold text-brand-deepest dark:bg-brand/[0.18] dark:text-brand-light"
            >
              <Check className="h-3 w-3" aria-hidden />
              {topic}
            </span>
          ))}
        </div>
      </div>
    </>
  );

  return bare ? body : <SurfaceCard padding="md">{body}</SurfaceCard>;
};

export default MutualInterests;
