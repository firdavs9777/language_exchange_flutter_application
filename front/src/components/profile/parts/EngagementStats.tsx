import React from "react";
import { useTranslation } from "react-i18next";
import { Sparkles, Zap } from "lucide-react";

/** How long a new account is introduced as new (engagement_stats_bar.dart). */
const NEW_MEMBER_DAYS = 14;

/** A finite 0-100 reply rate, or null — `responseRate` is absent on most records. */
export function responseRateOf(user: any): number | null {
  const raw = user && user.responseRate;
  const rate = typeof raw === "string" ? parseFloat(raw) : raw;
  if (typeof rate !== "number" || !isFinite(rate)) return null;
  if (rate < 0 || rate > 100) return null;
  return Math.round(rate);
}

/** The account was created inside the new-member window. */
export function isNewMember(user: any, now: number = Date.now()): boolean {
  const createdAt = user && user.createdAt;
  if (!createdAt) return false;
  const created = new Date(createdAt).getTime();
  if (isNaN(created)) return false;
  const age = now - created;
  return age >= 0 && age <= NEW_MEMBER_DAYS * 24 * 60 * 60 * 1000;
}

export interface EngagementStatsProps {
  user?: any;
}

/**
 * The thin stats strip under the header: how often this person replies, and
 * whether they only just arrived.
 *
 * Both facts come from the public projection (`USER_PUBLIC_FIELDS`), and
 * neither is guaranteed to be there — `responseRate` is only computed for
 * accounts that have chatted. With neither present the strip renders nothing
 * at all rather than a row of blanks: an empty stat reads as a zero.
 */
const EngagementStats: React.FC<EngagementStatsProps> = ({ user }) => {
  const { t } = useTranslation();
  const rate = responseRateOf(user);
  const isNew = isNewMember(user);

  if (rate === null && !isNew) return null;

  return (
    <div
      data-testid="engagement-stats"
      className="flex flex-wrap items-center gap-2 rounded-chip border border-line px-3 py-2 dark:border-line-dark"
    >
      {rate !== null && (
        <span
          data-testid="engagement-response-rate"
          className="inline-flex items-center gap-1.5 text-xs font-semibold text-ink-700 dark:text-ink-200"
        >
          <Zap className="h-3.5 w-3.5 text-brand" aria-hidden />
          {t("communityDetail.engagement.replies", { rate }) || `${rate}% replies`}
        </span>
      )}

      {isNew && (
        <span
          data-testid="engagement-new-member"
          className="inline-flex items-center gap-1.5 rounded-chip bg-banana/[0.28] px-2 py-0.5 text-xs font-semibold text-ink-800 dark:bg-banana/[0.22] dark:text-ink-50"
        >
          <Sparkles className="h-3.5 w-3.5" aria-hidden />
          {t("communityDetail.engagement.new") || "New member"}
        </span>
      )}
    </div>
  );
};

export default EngagementStats;
