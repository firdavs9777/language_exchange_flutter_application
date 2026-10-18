import React from "react";
import { useTranslation } from "react-i18next";
import Reveal from "../anim/Reveal";
import { useInView } from "../anim/useInView";
import { useCountUp } from "../anim/useCountUp";
import { useGetPublicStatsQuery, formatCount } from "../../../store/slices/publicStatsSlice";

// Every figure here is checkable. The learner count comes from
// GET /public/stats (rounded down, null under 1,000) and leads the strip when
// present; the curated four stand alone otherwise. No ratings: the App Store
// listing has none.
// "18 app languages" -- src/utils/locales/ holds 18 JSON files and
// `SUPPORTED_LANGUAGES` in src/utils/i18n.ts lists 18 codes; re-count either
// to re-verify.
interface Stat {
  value: string;
  label: string;
  /** Appended after the (formatted) number, e.g. "+". */
  suffix?: string;
}

const CURATED: Stat[] = [
  { value: "137", label: "languages" },
  { value: "18", label: "app languages" },
  { value: "24/7", label: "AI tutor" },
  { value: "Free", label: "forever tier" },
];

/** Numeric stats tick up when the strip scrolls into view; the rest are literal. */
const StatValue: React.FC<{ stat: Stat; start: boolean }> = ({ stat, start }) => {
  const numeric = /^\d+$/.test(stat.value) ? Number(stat.value) : null;
  const counted = useCountUp(numeric ?? 0, { start: start && numeric !== null });
  return (
    <p className="text-2xl font-extrabold text-brand-dark dark:text-brand-light">
      {numeric === null ? stat.value : `${formatCount(counted)}${stat.suffix || ""}`}
    </p>
  );
};

const StatStrip: React.FC = () => {
  const { t } = useTranslation();
  const [ref, inView] = useInView<HTMLElement>();
  const { data } = useGetPublicStatsQuery();

  // Lead with the real count and keep the strip at four: the free tier is
  // already the first pricing card, so it is the one that steps aside.
  const stats: Stat[] =
    data && data.learners
      ? [{ value: String(data.learners), label: "learners", suffix: "+" }, ...CURATED.slice(0, 3)]
      : CURATED;

  return (
    <section
      ref={ref}
      data-testid="stat-strip"
      className="border-y border-gray-100 bg-surface py-8 dark:border-gray-700 dark:bg-cardbg-dark"
    >
      <div className="mx-auto grid max-w-4xl grid-cols-2 gap-6 px-4 sm:grid-cols-4">
        {stats.map((s, i) => (
          <Reveal key={s.label} delayMs={i * 90}>
            <div data-testid="stat-item" className="text-center">
              <StatValue stat={s} start={inView} />
              <p className="mt-0.5 text-[11px] font-medium uppercase tracking-wide text-gray-400">
                {t(`home.stats.${s.label}`) || s.label}
              </p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
};

export default StatStrip;
