import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { MessageCircle, X } from "lucide-react";
import Avatar from "../../../design/Avatar";
import { DailyMatch } from "./types";
import { countryFlag, photoUrl, reasonChips, repliesFast } from "./dailyMatchView";

const ACTION =
  "inline-flex min-h-[40px] flex-1 items-center justify-center gap-1.5 rounded-chip px-3 text-sm font-semibold transition-colors";

/**
 * One of today's matches, laid out as the app's match card
 * (match_card.dart): who they are, why they matched, and three actions.
 */
const MatchCard: React.FC<{
  match: DailyMatch;
  onWave: (match: DailyMatch) => void;
  onSkip: (match: DailyMatch) => void;
  /** A wave to this person exists: the Wave action becomes a done state. */
  waved?: boolean;
}> = ({ match, onWave, onSkip, waved = false }) => {
  const { t } = useTranslation();
  const user = match.user;
  const photo = photoUrl(user.images);
  const flag = countryFlag(user.location && user.location.country);
  const pair = [user.native_language, user.language_to_learn].filter((s) => s && s.trim()).join(" → ");
  const reasons = reasonChips(match.matchReasons, user, t);

  return (
    <article
      data-testid="match-card"
      className="rounded-2xl border border-line bg-surface p-4 shadow-card dark:border-line-dark dark:bg-cardbg-dark"
    >
      <div className="flex items-start gap-3">
        <Link to={`/community/${user._id}`} data-testid="match-profile-link" className="shrink-0">
          <Avatar src={photo} name={user.name} size={54} />
        </Link>
        <div className="min-w-0 flex-1">
          <Link
            to={`/community/${user._id}`}
            data-testid="match-card-name"
            className="flex items-center gap-1.5 font-display text-base text-ink-900 hover:underline dark:text-ink-50"
          >
            <span className="truncate">{user.name}</span>
            {flag && <span aria-hidden>{flag}</span>}
            {match.lastActiveBucket === "today" && (
              <span
                data-testid="match-active-dot"
                aria-label={t("communityMain.today.reasonActiveToday") || "Active today"}
                className="h-2 w-2 shrink-0 rounded-full bg-emerald-500"
              />
            )}
          </Link>
          <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
            {pair && (
              <span
                data-testid="match-pair"
                className="rounded-full bg-brand/[0.09] px-2.5 py-0.5 text-xs font-semibold text-brand-dark dark:bg-brand/[0.18] dark:text-brand-light"
              >
                {pair}
              </span>
            )}
            {repliesFast(match.responseRate) && (
              <span data-testid="match-replies-fast" className="rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300">
                {t("communityMain.today.repliesFast") || "Replies fast"}
              </span>
            )}
            {match.boosted && (
              <span data-testid="match-boosted" className="rounded-full bg-banana/25 px-2.5 py-0.5 text-xs font-semibold text-ink-800 dark:bg-banana/15 dark:text-ink-100">
                {t("communityMain.today.boosted") || "Boosted"}
              </span>
            )}
          </div>
        </div>
      </div>

      {reasons.length > 0 && (
        <ul className="mt-3 flex flex-wrap gap-1.5">
          {reasons.map((reason) => (
            <li key={reason} data-testid="match-reason" className="rounded-chip bg-ink-50 px-2.5 py-1 text-xs text-ink-700 dark:bg-white/5 dark:text-ink-200">
              {reason}
            </li>
          ))}
        </ul>
      )}

      <div className="mt-4 flex gap-2">
        <Link to={`/chat/${user._id}`} data-testid="match-say-hi" className={`${ACTION} bg-brand-deep text-white hover:bg-brand-dark`}>
          <MessageCircle className="h-4 w-4" aria-hidden />
          {t("communityMain.today.sayHi") || "Say hi"}
        </Link>
        {waved ? (
          <button type="button" data-testid="match-waved" disabled className={`${ACTION} border border-line text-ink-500 opacity-70 dark:border-line-dark dark:text-ink-400`}>
            <span aria-hidden>✓</span>
            {t("communityMain.today.waved") || "Waved"}
          </button>
        ) : (
          <button type="button" data-testid="match-wave" onClick={() => onWave(match)} className={`${ACTION} border border-line text-ink-800 hover:bg-ink-50 dark:border-line-dark dark:text-ink-100 dark:hover:bg-white/5`}>
            <span aria-hidden>👋</span>
            {t("communityMain.today.wave") || "Wave"}
          </button>
        )}
        <button type="button" data-testid="match-skip" onClick={() => onSkip(match)} className={`${ACTION} text-ink-500 hover:bg-ink-50 dark:text-ink-400 dark:hover:bg-white/5`}>
          <X className="h-4 w-4" aria-hidden />
          {t("communityMain.today.skip") || "Skip"}
        </button>
      </div>
    </article>
  );
};

export default MatchCard;
