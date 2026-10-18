import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { RefreshCw, Sparkles } from "lucide-react";
import MatchCard from "./MatchCard";
import { DailyMatch, DailyMatchesResponse } from "./types";
import { refreshTimeLabel } from "./dailyMatchView";
import { addSkip, loadSkips } from "./todaySkips";
import { useSkipUserMutation } from "../../../store/slices/communitySlice";

/**
 * Today's matches: the server's batch for this UTC day (GET /matching/daily),
 * as the app's Matches tab shows it. The batch is the server's choice, so
 * there is nothing here to filter or search.
 */
const TodayTab: React.FC<{
  response?: DailyMatchesResponse;
  isLoading: boolean;
  isError: boolean;
  onRetry: () => void;
  onWave: (match: DailyMatch) => void;
  onBrowse: () => void;
  wavedIds?: string[];
}> = ({ response, isLoading, isError, onRetry, onWave, onBrowse, wavedIds = [] }) => {
  const { t, i18n } = useTranslation();
  const [skipUser] = useSkipUserMutation();
  const date = (response && response.date) || "";
  const [skipped, setSkipped] = useState<string[]>(() => (date ? loadSkips(date) : []));

  // A new batch (midnight rollover) starts clean; the same date re-reads what
  // this session already skipped.
  useEffect(() => {
    setSkipped(date ? loadSkips(date) : []);
  }, [date]);

  // Roll over once the batch's refresh moment passes while the tab is open:
  // one timer for that moment, plus a check on focus for a laptop that slept
  // through it. Re-armed whenever nextRefreshAt changes; cleared on unmount.
  const nextRefreshAt = response && response.nextRefreshAt;
  useEffect(() => {
    if (!nextRefreshAt) return undefined;
    const at = new Date(nextRefreshAt).getTime();
    if (isNaN(at)) return undefined;
    let fired = false;
    const fire = () => {
      if (fired || Date.now() < at) return;
      fired = true;
      onRetry();
    };
    const timer = window.setTimeout(fire, Math.max(0, at - Date.now()) + 1000);
    window.addEventListener("focus", fire);
    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("focus", fire);
    };
  }, [nextRefreshAt, onRetry]);

  const visible = useMemo(
    () => ((response && response.matches) || []).filter((m) => m && m.user && m.user._id && skipped.indexOf(m.user._id) === -1),
    [response, skipped]
  );

  const handleSkip = (match: DailyMatch) => {
    const id = match.user._id;
    setSkipped((prev) => (date ? addSkip(date, id) : prev.concat([id])));
    // Fire-and-forget, as the app does: the card is gone either way.
    skipUser(id).unwrap().catch(() => {});
  };

  if (isLoading && !response) {
    return (
      <div data-testid="today-skeleton" aria-busy="true" className="space-y-3 py-2">
        {[0, 1, 2].map((i) => (
          <div key={i} className="h-36 animate-pulse rounded-2xl bg-ink-100 dark:bg-white/5" />
        ))}
      </div>
    );
  }

  if (isError && !response) {
    return (
      <div data-testid="today-error" className="community-empty">
        <p>{t("communityMain.today.error") || "We couldn't load today's matches"}</p>
        <button type="button" data-testid="today-retry" onClick={onRetry} className="community-empty__action">
          <RefreshCw className="h-4 w-4" aria-hidden />
          {t("communityMain.today.retry") || "Try again"}
        </button>
      </div>
    );
  }

  const refresh = refreshTimeLabel(nextRefreshAt, i18n.language);

  if (visible.length === 0) {
    return (
      <div data-testid="today-empty" className="community-empty">
        <Sparkles className="community-empty__icon" aria-hidden />
        <h3>{t("communityMain.today.emptyTitle") || "That's everyone for today"}</h3>
        <p>{t("communityMain.today.emptyBody") || "Fresh matches tomorrow. Meanwhile, browse all partners."}</p>
        <button type="button" data-testid="today-browse" onClick={onBrowse} className="community-empty__action">
          {t("communityMain.today.browse") || "Browse partners"}
        </button>
      </div>
    );
  }

  return (
    <div data-testid="today-tab" className="py-2">
      <div className="pb-3">
        <h2 data-testid="today-title" className="font-display text-xl text-ink-900 dark:text-ink-50">
          {t("communityMain.today.title", { count: visible.length })}
        </h2>
        <p data-testid="today-refresh" className="text-sm text-ink-500 dark:text-ink-400">
          {refresh
            ? t("communityMain.today.refreshes", { time: refresh })
            : t("communityMain.today.refreshesMidnight")}
        </p>
      </div>
      <div className="grid gap-3 md:grid-cols-2">
        {visible.map((match) => (
          <MatchCard
            key={match.user._id}
            match={match}
            onWave={onWave}
            onSkip={handleSkip}
            waved={wavedIds.indexOf(match.user._id) > -1}
          />
        ))}
      </div>
    </div>
  );
};

export default TodayTab;
