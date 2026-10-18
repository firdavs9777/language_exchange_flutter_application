import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Rocket, Users, CalendarHeart, Sparkles, Loader2 } from "lucide-react";
import {
  useGetActiveBoostQuery,
  useGetBoostHistoryQuery,
  usePurchaseProfileBoostMutation,
  useGetCoinBalanceQuery,
  Boost,
} from "../../store/slices/boostsSlice";
import { useWebFlag } from "../../utils/webFlags";
import { isBoostLive, boostProgress, lastEndedBoost, formatBoostRemaining, boostErrorKind, PROFILE_BOOST_COST } from "./boostLogic";

const CARD = "rounded-card border border-line bg-surface p-4 dark:border-line-dark dark:bg-cardbg-dark";
const PRIMARY =
  "inline-flex w-full items-center justify-center gap-2 rounded-chip bg-banana px-4 py-3 text-sm font-bold text-ink-900 transition-opacity hover:opacity-90 disabled:opacity-60";

/** Total impressions and where they happened. */
const ImpressionsCard: React.FC<{ boost: Boost; headline: string }> = ({ boost, headline }) => {
  const { t } = useTranslation();
  const by = boost.impressionsBySource || {};
  const row = (Icon: React.ComponentType<{ size?: number }>, label: string, n: number, id: string) => (
    <li className="mt-2 flex items-center gap-2 text-sm text-ink-700 dark:text-ink-200" data-testid={`boost-source-${id}`}>
      <Icon size={16} />
      <span className="flex-1">{label}</span>
      <strong>{n}</strong>
    </li>
  );
  return (
    <div className={CARD} data-testid="boost-impressions">
      <p className="font-semibold text-ink-900 dark:text-ink-50">{headline}</p>
      <ul className="m-0 list-none p-0">
        {row(Users, t("boost.sourcePartners") || "Partners list", by.partners || 0, "partners")}
        {row(CalendarHeart, t("boost.sourceMatches") || "Daily matches", by.matches || 0, "matches")}
        {row(Sparkles, t("boost.sourceMoments") || "Your moment in For You", by.moments || 0, "moments")}
      </ul>
    </div>
  );
};

/**
 * Profile Boost: explain, confirm, then the live boost with its progress
 * (time used, impressions by place, tips). After it ends, the last result
 * with "Boost again". Reached only behind `boostsEnabled` (route + entries).
 */
const BoostPage: React.FC = () => {
  const { t } = useTranslation();
  const coinsOn = useWebFlag("coinsEnabled");
  const [now, setNow] = useState(Date.now());
  const { data: activeData, isLoading, refetch: refetchActive } = useGetActiveBoostQuery(undefined, { refetchOnMountOrArgChange: true });
  const live = isBoostLive(activeData, now) ? (activeData as Boost) : null;
  const { data: history, refetch: refetchHistory } = useGetBoostHistoryQuery(undefined, { skip: !!live, refetchOnMountOrArgChange: true });
  const { data: balance } = useGetCoinBalanceQuery(undefined, { skip: !coinsOn || !!live });
  const [purchase, { isLoading: buying }] = usePurchaseProfileBoostMutation();
  const [message, setMessage] = useState<React.ReactNode>(null);

  // Tick every 30s so the time left and the bar move; re-read impressions every minute.
  useEffect(() => {
    if (!live) return;
    let ticks = 0;
    const timer = setInterval(() => {
      setNow(Date.now());
      ticks += 1;
      if (ticks % 2 === 0) refetchActive();
    }, 30000);
    return () => clearInterval(timer);
  }, [live && live._id]); // eslint-disable-line react-hooks/exhaustive-deps

  // Just ended while open: show its result with "Boost again".
  const wasLive = React.useRef(false);
  useEffect(() => {
    if (wasLive.current && !live && refetchHistory) refetchHistory();
    wasLive.current = !!live;
  }, [live]); // eslint-disable-line react-hooks/exhaustive-deps

  const last = live ? null : lastEndedBoost(history as Boost[] | undefined, now);

  const confirm = async () => {
    if (buying) return;
    setMessage(null);
    try {
      await purchase().unwrap();
      setNow(Date.now());
    } catch (err) {
      const kind = boostErrorKind(err);
      if (kind === "insufficient_coins") {
        setMessage(
          <>
            {t("boost.needCoins", { cost: PROFILE_BOOST_COST }) || `You need ${PROFILE_BOOST_COST} coins. Coins are bought in the BananaTalk app.`}{" "}
            <Link to="/download" className="font-semibold underline" data-testid="boost-get-app">
              {t("boost.getApp") || "Get the app"}
            </Link>
          </>
        );
      } else if (kind === "already_boosted") {
        const res: any = await refetchActive();
        if (!(res && res.data && isBoostLive(res.data))) setMessage(t("boost.failed") || "Couldn't start your boost. Please try again.");
      } else if (kind === "capacity_full") {
        setMessage(t("boost.capacityFull") || "All boost slots are taken right now — try again in a few hours");
      } else {
        setMessage(t("boost.failed") || "Couldn't start your boost. Please try again.");
      }
    }
  };

  const left = live ? new Date(live.endsAt as string).getTime() - now : 0;

  return (
    <section className="mx-auto max-w-lg px-4 py-8" data-testid="boost-page">
      <div className="mb-4 flex justify-center text-banana">
        <Rocket size={56} aria-hidden />
      </div>
      <h1 className="mb-4 text-center text-2xl font-bold text-ink-900 dark:text-ink-50">{t("boost.title") || "Boost my profile"}</h1>

      {isLoading ? (
        <div className="flex justify-center" aria-busy="true">
          <Loader2 className="animate-spin" />
        </div>
      ) : live ? (
        <div className="flex flex-col gap-4" data-testid="boost-active">
          <p className="text-center text-lg font-bold text-ink-900 dark:text-ink-50">{t("boost.activeTitle") || "Your boost is live"}</p>
          <p className="text-center text-xl text-ink-800 dark:text-ink-100" data-testid="boost-time-left">
            {left < 60000
              ? formatBoostRemaining(left, t)
              : t("boost.timeLeft", { time: formatBoostRemaining(left, t) }) || `${formatBoostRemaining(left, t)} left`}
          </p>
          <div
            className="h-2 w-full overflow-hidden rounded-full bg-ink-100 dark:bg-ink-800"
            role="progressbar"
            aria-valuemin={0}
            aria-valuemax={100}
            aria-valuenow={Math.round(boostProgress(live, now) * 100)}
            data-testid="boost-progress"
          >
            <div className="h-full bg-banana" style={{ width: `${Math.round(boostProgress(live, now) * 100)}%` }} />
          </div>
          <ImpressionsCard
            boost={live}
            headline={t("boost.seenBy", { count: live.impressions || 0 }) || `Times shown so far: ${live.impressions || 0}`}
          />
          {!live.impressions && (
            <p className="text-center text-xs text-ink-500" data-testid="boost-counting-hint">
              {t("boost.countingHint") || "Views add up as people open Partners, their daily matches and For You."}
            </p>
          )}
          <div className={CARD} data-testid="boost-tips">
            <p className="font-semibold text-ink-900 dark:text-ink-50">{t("boost.tipsTitle") || "Get more from your boost"}</p>
            <p className="mt-2 text-sm text-ink-700 dark:text-ink-200">{t("boost.tipMoment") || "Post a moment now: your newest moment is featured too."}</p>
            <Link to="/add-moment" className="mt-2 inline-block text-sm font-semibold text-brand-deep underline" data-testid="boost-post-moment">
              {t("boost.postMoment") || "Post a moment"}
            </Link>
            <p className="mt-3 text-sm text-ink-700 dark:text-ink-200">{t("boost.tipProfile") || "A clear photo and a short bio get more replies."}</p>
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-4" data-testid="boost-purchase">
          {last && (
            <ImpressionsCard
              boost={last}
              headline={t("boost.lastResult", { count: last.impressions || 0 }) || `Your last boost — times shown: ${last.impressions || 0}`}
            />
          )}
          <p className="text-center text-base text-ink-800 dark:text-ink-100">
            {t("boost.explain") || "Be the 6th match for everyone whose languages fit you, for 24 hours."}
          </p>
          <p className="text-center text-sm text-ink-600 dark:text-ink-300" data-testid="boost-explain-more">
            {t("boost.explainMore") || "You also appear near the top of Partners, and your latest moment is featured in For You."}
          </p>
          <p className="text-center text-lg font-bold text-ink-900 dark:text-ink-50" data-testid="boost-cost">
            {t("boost.costLine", { cost: PROFILE_BOOST_COST }) || `Cost: ${PROFILE_BOOST_COST} coins`}
          </p>
          {coinsOn && typeof balance === "number" && (
            <p className="-mt-3 text-center text-sm text-ink-500" data-testid="boost-balance">
              {t("boost.balanceLine", { balance }) || `Your balance: ${balance} coins`}
            </p>
          )}
          <button type="button" className={PRIMARY} data-testid="boost-confirm" disabled={buying} onClick={confirm}>
            {buying && <Loader2 size={16} className="animate-spin" />}
            {last ? t("boost.again") || "Boost again" : t("boost.confirm") || "Confirm boost"}
          </button>
          {message && (
            <p className="text-center text-sm text-ink-600 dark:text-ink-300" role="alert" data-testid="boost-message">
              {message}
            </p>
          )}
        </div>
      )}
    </section>
  );
};

export default BoostPage;
