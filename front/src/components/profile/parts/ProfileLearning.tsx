import React from "react";
import { useTranslation } from "react-i18next";
import { Flame, Sparkles, TrendingUp } from "lucide-react";
import SurfaceCard from "../../../design/SurfaceCard";

export interface ProfileLearningProps {
  /** The user document. `learningStats` only exists on an own profile. */
  user?: any;
  /** Render the contents alone, for a caller that draws the card itself. */
  bare?: boolean;
}

function positive(value: any): number | null {
  const n = typeof value === "number" ? value : parseInt(String(value), 10);
  if (!isFinite(n) || n <= 0) return null;
  return n;
}

/** "3,400". Falls back to the plain digits wherever Intl is unavailable. */
function formatCount(value: number, language: string): string {
  try {
    return new Intl.NumberFormat(language).format(value);
  } catch {
    return String(value);
  }
}

/**
 * Streak, XP and level.
 *
 * Every tile is omitted unless its own metric is a positive number, and the
 * card disappears entirely when none of them is: `learningStats` defaults to
 * `currentStreak: 0, totalXP: 0, level: 1` on the backend
 * (models/User.js:1061), so a brand new account would otherwise show three
 * confident-looking zeroes it has not earned. No fake numbers.
 *
 * `learningStats` is NOT in `USER_PUBLIC_FIELDS`, so in practice this renders
 * on own profiles only; `streakDays`/`totalXp` are read as a fallback because
 * the public field list names them (they are not on the schema today).
 */
/**
 * The three numbers this section can show, nulls dropped.
 *
 * Exported and used BOTH by the component and by `hasLearning`, so the question
 * "is there anything here" has one answer rather than two that can drift.
 */
export function learningValues(user: any): { streak: number | null; xp: number | null; level: number | null } {
  const stats = (user && user.learningStats) || {};
  const streak = positive(stats.currentStreak != null ? stats.currentStreak : user && user.streakDays);
  const xp = positive(stats.totalXP != null ? stats.totalXP : user && user.totalXp);
  // Level 1 is the schema default and means "has not levelled up", so it is
  // not a fact worth a tile -- `positive` alone would let it through.
  const rawLevel = positive(stats.level);
  const level = rawLevel !== null && rawLevel > 1 ? rawLevel : null;
  return { streak, xp, level };
}

/** Whether this section has anything to show. */
export const hasLearning = (user: any): boolean => {
  const v = learningValues(user);
  return v.streak !== null || v.xp !== null || v.level !== null;
};

const ProfileLearning: React.FC<ProfileLearningProps> = ({ user, bare }) => {
  const { t, i18n } = useTranslation();
  const language = (i18n && i18n.language) || "en";

  const { streak, xp, level } = learningValues(user);

  const tiles = [
    {
      key: "streak",
      icon: Flame,
      value: streak,
      suffix: t("profile.learning.days") || "days",
      label: t("profile.learning.streak") || "Streak",
    },
    {
      key: "xp",
      icon: Sparkles,
      value: xp,
      suffix: "",
      label: t("profile.learning.xp") || "Total XP",
    },
    {
      key: "level",
      icon: TrendingUp,
      value: level,
      suffix: "",
      label: t("profile.learning.level") || "Level",
    },
  ].filter((tile) => tile.value !== null);

  if (tiles.length === 0) return null;

  const body = (
    <>
      <div data-testid="profile-learning">
        <h2 className="mb-3 text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
          {t("profile.learning.title") || "Learning progress"}
        </h2>
        <div className="flex flex-wrap gap-3">
          {tiles.map((tile) => {
            const Icon = tile.icon;
            return (
              <div
                key={tile.key}
                data-testid={`learning-${tile.key}`}
                className="flex min-w-[6.5rem] flex-1 flex-col items-start gap-1 rounded-chip bg-brand/[0.07] px-3 py-2.5 dark:bg-brand/[0.16]"
              >
                <Icon className="h-4 w-4 text-brand" aria-hidden />
                <span className="font-display text-lg text-ink-900 dark:text-ink-50">
                  {formatCount(tile.value as number, language)}
                  {tile.suffix && (
                    <span className="ml-1 text-xs font-semibold text-ink-500 dark:text-ink-400">
                      {tile.suffix}
                    </span>
                  )}
                </span>
                <span className="text-[11px] text-ink-500 dark:text-ink-400">{tile.label}</span>
              </div>
            );
          })}
        </div>
      </div>
    </>
  );

  return bare ? body : <SurfaceCard padding="md">{body}</SurfaceCard>;
};

export default ProfileLearning;
