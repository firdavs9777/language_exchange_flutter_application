import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Rocket, ChevronRight } from "lucide-react";
import { useGetActiveBoostQuery, useGetBoostHistoryQuery, Boost } from "../../store/slices/boostsSlice";
import { useWebFlag } from "../../utils/webFlags";
import { isBoostLive, lastEndedBoost, formatBoostRemaining } from "./boostLogic";

/**
 * One slim row that starts a Boost where people look for partners (the
 * app's BoostEntryRow). While a boost is live it shows the time left
 * instead; within 7 days of the last one, its result and "Boost again".
 * Renders nothing while `boostsEnabled` is off.
 */
const BoostEntryRow: React.FC<{ className?: string }> = ({ className = "" }) => {
  const on = useWebFlag("boostsEnabled");
  if (!on) return null;
  return <BoostEntryRowInner className={className} />;
};

const BoostEntryRowInner: React.FC<{ className: string }> = ({ className }) => {
  const { t } = useTranslation();
  const { data: active } = useGetActiveBoostQuery();
  const live = isBoostLive(active) ? (active as Boost) : null;
  const { data: history } = useGetBoostHistoryQuery(undefined, { skip: !!live });
  const last = live ? null : lastEndedBoost(history as Boost[] | undefined);

  const title = live ? t("boost.activeTitle") || "Your boost is live" : last ? t("boost.again") || "Boost again" : t("boost.title") || "Boost my profile";
  let subtitle: string;
  if (live) {
    const time = formatBoostRemaining(new Date(live.endsAt as string).getTime() - Date.now(), t);
    subtitle = `${t("boost.timeLeft", { time }) || `${time} left`} · ${t("boost.seenBy", { count: live.impressions || 0 }) || `Times shown so far: ${live.impressions || 0}`}`;
  } else if (last) {
    subtitle = t("boost.lastResult", { count: last.impressions || 0 }) || `Your last boost — times shown: ${last.impressions || 0}`;
  } else {
    subtitle = t("boost.subtitle") || "Be seen by more partners for 24h";
  }

  return (
    <Link
      to="/boost"
      data-testid="boost-entry-row"
      className={
        "flex items-center gap-3 rounded-xl px-3 py-2.5 no-underline transition-colors " +
        (live ? "bg-banana/40 hover:bg-banana/50" : "bg-banana/25 hover:bg-banana/35") +
        " " +
        className
      }
    >
      <Rocket size={20} className="shrink-0 text-banana-dark" aria-hidden />
      <span className="min-w-0 flex-1">
        <span className="block text-sm font-bold text-ink-900 dark:text-ink-50">{title}</span>
        <span className="block truncate text-xs text-ink-600 dark:text-ink-300" data-testid="boost-entry-subtitle">
          {subtitle}
        </span>
      </span>
      <ChevronRight size={18} className="text-ink-500" aria-hidden />
    </Link>
  );
};

export default BoostEntryRow;
