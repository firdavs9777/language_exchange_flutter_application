import React from "react";
import { ArrowLeftRight } from "lucide-react";
import { displayCode } from "../utils/languages";

/**
 * Dots to fill for a CEFR level, or null when we do not know the level.
 *
 * Null is not zero. `languageLevel` defaults to null on the backend
 * (models/User.js:744), so a profile with no level renders NO dots rather
 * than three empty ones -- an empty indicator reads as "beginner", a claim
 * the data has not made.
 */
export function dotsForLevel(level?: string | null): number | null {
  switch ((level || "").trim().toUpperCase()) {
    case "A1":
    case "A2":
      return 1;
    case "B1":
    case "B2":
      return 2;
    case "C1":
    case "C2":
      return 3;
    default:
      return null;
  }
}

export interface LanguageExchangePillProps {
  nativeLanguage: string;
  learningLanguage: string;
  /** The candidate's CEFR level in `learningLanguage`. Null renders no dots. */
  languageLevel?: string | null;
  /** Smaller type and tighter padding, for the moment card header. */
  dense?: boolean;
}

const LanguageExchangePill: React.FC<LanguageExchangePillProps> = ({
  nativeLanguage,
  learningLanguage,
  languageLevel,
  dense = false,
}) => {
  const filled = dotsForLevel(languageLevel);
  const native = displayCode(nativeLanguage);
  const learning = displayCode(learningLanguage);

  const text = dense ? "text-[10px]" : "text-[11px]";
  const pad = dense ? "px-2 py-0.5" : "px-2.5 py-1";

  return (
    <span
      data-testid="language-pill"
      className={`inline-flex items-center rounded-full bg-brand/[0.09] dark:bg-brand/[0.18] ${pad}`}
    >
      {/* No dots on the native side: always three-of-three, so they varied
          for nobody and cost width the moment header could not spare. */}
      <span
        data-testid="language-pill-native"
        className={`font-extrabold text-brand-dark dark:text-brand-light ${text}`}
      >
        {native}
      </span>

      <ArrowLeftRight className="mx-1.5 h-3 w-3 shrink-0 text-brand" aria-hidden />

      <span
        data-testid="language-pill-learning"
        className={`font-extrabold text-brand-dark dark:text-brand-light ${text}`}
      >
        {learning}
      </span>

      {filled !== null && (
        <span className="ml-1 flex items-center gap-0.5">
          {[0, 1, 2].map((i) => (
            <span
              key={i}
              data-testid="language-pill-dot"
              className={`block h-1 w-1 rounded-full ${
                i < filled ? "bg-brand" : "bg-brand/[0.28]"
              }`}
            />
          ))}
        </span>
      )}
    </span>
  );
};

export default LanguageExchangePill;
