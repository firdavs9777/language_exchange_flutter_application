import React from "react";
import { Clock, Radio, MessageCircle, GraduationCap } from "lucide-react";
import { CommunityFilters } from "./lib/buildCommunityQuery";

interface Me {
  native_language?: string;
  language_to_learn?: string;
}

export interface QuickFilterChipsProps {
  filters: CommunityFilters;
  sort?: "recently_active";
  me: Me;
  /** Replaces the whole filter object (parent persists + resets pagination). */
  onChange: (next: CommunityFilters) => void;
  onSortChange: (next?: "recently_active") => void;
}

const CHIP_BASE =
  "inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors border";
const CHIP_ON = "bg-teal-500 text-white border-teal-500";
const CHIP_OFF = "bg-white text-gray-600 border-gray-200 hover:bg-gray-50";

/**
 * Horizontal row of one-tap discovery shortcuts (App parity: partner
 * discovery quick chips). Each chip is a pure toggle over the shared filter /
 * sort state — no local state, so it always reflects the applied filters.
 *
 *  - Recently Active -> sort:'recently_active'
 *  - Online Now      -> filters.onlineOnly
 *  - Speaks {my learning} -> filters.nativeLanguage = me.language_to_learn
 *      (via buildCommunityQuery's inverted mapping this finds native speakers
 *       of the language I'm learning)
 *  - Learning {my native} -> filters.learningLanguage = me.native_language
 *      (finds users learning what I speak)
 */
const QuickFilterChips: React.FC<QuickFilterChipsProps> = ({
  filters,
  sort,
  me,
  onChange,
  onSortChange,
}) => {
  const recentlyActive = sort === "recently_active";
  const onlineOnly = !!filters.onlineOnly;
  const speaksLearning =
    !!me.language_to_learn && filters.nativeLanguage === me.language_to_learn;
  const learningNative =
    !!me.native_language && filters.learningLanguage === me.native_language;

  const toggleSort = () =>
    onSortChange(recentlyActive ? undefined : "recently_active");

  const toggleOnline = () =>
    onChange({ ...filters, onlineOnly: onlineOnly ? undefined : true });

  const toggleSpeaks = () =>
    onChange({
      ...filters,
      nativeLanguage: speaksLearning ? undefined : me.language_to_learn,
    });

  const toggleLearning = () =>
    onChange({
      ...filters,
      learningLanguage: learningNative ? undefined : me.native_language,
    });

  return (
    <div className="flex items-center gap-2 overflow-x-auto py-2 -mx-1 px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      <button
        type="button"
        aria-pressed={recentlyActive}
        onClick={toggleSort}
        className={`${CHIP_BASE} ${recentlyActive ? CHIP_ON : CHIP_OFF}`}
      >
        <Clock className="w-3.5 h-3.5" />
        Recently Active
      </button>

      <button
        type="button"
        aria-pressed={onlineOnly}
        onClick={toggleOnline}
        className={`${CHIP_BASE} ${onlineOnly ? CHIP_ON : CHIP_OFF}`}
      >
        <Radio className="w-3.5 h-3.5" />
        Online Now
      </button>

      {me.language_to_learn && (
        <button
          type="button"
          aria-pressed={speaksLearning}
          onClick={toggleSpeaks}
          className={`${CHIP_BASE} ${speaksLearning ? CHIP_ON : CHIP_OFF}`}
        >
          <MessageCircle className="w-3.5 h-3.5" />
          Speaks {me.language_to_learn}
        </button>
      )}

      {me.native_language && (
        <button
          type="button"
          aria-pressed={learningNative}
          onClick={toggleLearning}
          className={`${CHIP_BASE} ${learningNative ? CHIP_ON : CHIP_OFF}`}
        >
          <GraduationCap className="w-3.5 h-3.5" />
          Learning {me.native_language}
        </button>
      )}
    </div>
  );
};

export default QuickFilterChips;
