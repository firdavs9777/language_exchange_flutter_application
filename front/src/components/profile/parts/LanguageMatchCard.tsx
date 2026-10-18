import React from "react";
import { useTranslation } from "react-i18next";
import { ArrowLeftRight, ArrowRight, GraduationCap, Handshake, Mic, Sparkles } from "lucide-react";
import SurfaceCard from "../../../design/SurfaceCard";
import LanguageExchangePill from "../../../design/LanguageExchangePill";

/**
 * The five states the app's `LanguageMatchCard` knows
 * (language_match_card.dart:9). Kept as a union rather than an enum so the
 * value that reaches the DOM (`data-match`) is the same string the i18n key
 * is built from.
 */
export type MatchType =
  | "perfect"
  | "youLearnTheirs"
  | "theyLearnYours"
  | "sameNative"
  | "none";

function lower(value: any): string {
  return String(value || "").trim().toLowerCase();
}

/**
 * How the viewer's language pair meets this profile's.
 *
 * Mirrors `_calculateMatchType` in the Flutter widget exactly, including its
 * precedence: a perfect pair beats a one-way pair, and a one-way pair beats
 * the shared-native case. Comparison is case-insensitive because the two
 * documents are free text ("Korean" vs "korean" both occur in the data).
 *
 * An empty language never matches an empty language — otherwise two profiles
 * that have simply not filled the field in would be told they are a perfect
 * match.
 */
export function matchTypeFor(viewer: any, target: any): MatchType {
  const myNative = lower(viewer && viewer.native_language);
  const myLearning = lower(viewer && viewer.language_to_learn);
  const theirNative = lower(target && target.native_language);
  const theirLearning = lower(target && target.language_to_learn);

  const iLearnTheirNative = Boolean(myLearning) && myLearning === theirNative;
  const theyLearnMyNative = Boolean(theirLearning) && theirLearning === myNative;

  if (iLearnTheirNative && theyLearnMyNative) return "perfect";
  if (iLearnTheirNative) return "youLearnTheirs";
  if (theyLearnMyNative) return "theyLearnYours";
  if (Boolean(myNative) && myNative === theirNative) return "sameNative";
  return "none";
}

const MESSAGE_FALLBACK: Record<MatchType, string> = {
  perfect: "Perfect match — you can teach each other.",
  youLearnTheirs: "You're learning what they speak!",
  theyLearnYours: "They're learning what you speak!",
  sameNative: "You both speak the same native language.",
  none: "",
};

const MESSAGE_ICON: Record<MatchType, React.ComponentType<any>> = {
  perfect: Sparkles,
  youLearnTheirs: GraduationCap,
  theyLearnYours: Mic,
  sameNative: Handshake,
  none: Sparkles,
};

export interface LanguageMatchCardProps {
  /** The signed-in user's document. Absent means signed out. */
  viewer?: any;
  /** The profile being viewed. */
  user?: any;
}

/**
 * "Language match": the profile's own pair, and what it means for the viewer.
 *
 * Only ever drawn for a signed-in viewer who has a language of their own —
 * there is no match to report otherwise, and a card that says "no match" to
 * someone who simply has not filled their profile in is worse than no card.
 * The `none` case keeps the pair (it is still useful) and drops the verdict,
 * which is what the app does.
 */
const LanguageMatchCard: React.FC<LanguageMatchCardProps> = ({ viewer, user }) => {
  const { t } = useTranslation();

  const viewerNative = String((viewer && viewer.native_language) || "").trim();
  const viewerLearning = String((viewer && viewer.language_to_learn) || "").trim();
  const native = String((user && user.native_language) || "").trim();
  const learning = String((user && user.language_to_learn) || "").trim();
  const level = String((user && user.languageLevel) || "").trim();

  if (!viewer) return null;
  if (!viewerNative && !viewerLearning) return null;
  if (!native || !learning) return null;

  const matchType = matchTypeFor(viewer, user);
  const message =
    matchType === "none"
      ? ""
      : t(`communityDetail.match.${matchType}`) || MESSAGE_FALLBACK[matchType];
  const MessageIcon = MESSAGE_ICON[matchType];

  return (
    <SurfaceCard padding="md">
      <div data-testid="language-match-card" data-match={matchType}>
        <div className="flex items-center gap-2">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-chip bg-brand/[0.12]">
            <ArrowLeftRight className="h-4 w-4 text-brand-dark dark:text-brand-light" aria-hidden />
          </span>
          <h2 className="text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
            {t("communityDetail.match.title") || "Language match"}
          </h2>
        </div>

        <div className="mt-3 flex flex-wrap items-center gap-2">
          <LanguageExchangePill
            nativeLanguage={native}
            learningLanguage={learning}
            languageLevel={level || null}
          />
        </div>

        {/* The pill states the pair in codes; this says which half is which,
            as the app's two labelled cards do
            (communityLanguageMatchNative / …Learning). Without the labels
            neither rendering answers "who speaks what". */}
        <dl className="mt-3 flex items-center gap-3">
          <div data-testid="language-match-native" className="leading-tight">
            <dt className="text-[11px] uppercase tracking-wide text-ink-500 dark:text-ink-400">
              {t("communityDetail.match.native") || "Native"}
            </dt>
            <dd className="text-sm font-semibold text-ink-900 dark:text-ink-50">{native}</dd>
          </div>
          <ArrowRight className="h-4 w-4 shrink-0 text-ink-400" aria-hidden />
          <div data-testid="language-match-learning" className="leading-tight">
            <dt className="text-[11px] uppercase tracking-wide text-ink-500 dark:text-ink-400">
              {t("communityDetail.match.learning") || "Learning"}
            </dt>
            <dd className="text-sm font-semibold text-ink-900 dark:text-ink-50">{learning}</dd>
          </div>
        </dl>

        {message && (
          <p
            data-testid="language-match-message"
            className="mt-3 flex items-center gap-2 rounded-chip bg-brand/[0.09] px-3 py-2 text-sm font-semibold text-brand-deepest dark:bg-brand/[0.18] dark:text-brand-light"
          >
            <MessageIcon className="h-4 w-4 shrink-0" aria-hidden />
            {message}
          </p>
        )}
      </div>
    </SurfaceCard>
  );
};

export default LanguageMatchCard;
