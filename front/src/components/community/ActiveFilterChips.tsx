import React from "react";
import { X } from "lucide-react";
import { CommunityFilters } from "./lib/buildCommunityQuery";
import { DEFAULT_FILTERS } from "./lib/filterStorage";

export interface ActiveFilterChipsProps {
  value: CommunityFilters;
  /** `topicValue` is passed when removing a single entry from `topics[]`. */
  onRemove: (key: keyof CommunityFilters, topicValue?: string) => void;
  onClear: () => void;
  /** Optional map of topic ids to display names (for label rendering). */
  topicLabels?: Record<string, string>;
}

interface Chip {
  key: keyof CommunityFilters;
  topicValue?: string;
  label: string;
}

function buildChips(value: CommunityFilters, topicLabels?: Record<string, string>): Chip[] {
  const chips: Chip[] = [];

  const minAge = value.minAge ?? DEFAULT_FILTERS.minAge;
  const maxAge = value.maxAge ?? DEFAULT_FILTERS.maxAge;
  if (minAge !== undefined && minAge > (DEFAULT_FILTERS.minAge ?? 18)) {
    chips.push({ key: "minAge", label: `Min age: ${minAge}` });
  }
  if (maxAge !== undefined && maxAge < (DEFAULT_FILTERS.maxAge ?? 100)) {
    chips.push({ key: "maxAge", label: `Max age: ${maxAge}` });
  }
  if (value.gender) {
    chips.push({ key: "gender", label: `Gender: ${value.gender}` });
  }
  if (value.nativeLanguage) {
    chips.push({ key: "nativeLanguage", label: `Native: ${value.nativeLanguage}` });
  }
  if (value.learningLanguage) {
    chips.push({ key: "learningLanguage", label: `Learning: ${value.learningLanguage}` });
  }
  if (value.country) {
    chips.push({ key: "country", label: `Country: ${value.country}` });
  }
  if (value.languageLevel) {
    chips.push({ key: "languageLevel", label: `Level: ${value.languageLevel}` });
  }
  (value.topics || []).forEach((topic) => {
    const displayLabel = topicLabels?.[topic] ?? topic;
    chips.push({ key: "topics", topicValue: topic, label: `Topic: ${displayLabel}` });
  });
  if (value.topicsAtLeast) {
    chips.push({ key: "topicsAtLeast", label: `Shared topics ≥ ${value.topicsAtLeast}` });
  }
  if (value.onlineOnly) {
    chips.push({ key: "onlineOnly", label: "Online now" });
  }
  if (value.newUsersOnly) {
    chips.push({ key: "newUsersOnly", label: "New users only" });
  }
  if (value.search) {
    chips.push({ key: "search", label: `Search: ${value.search}` });
  }

  return chips;
}

const ActiveFilterChips: React.FC<ActiveFilterChipsProps> = ({ value, onRemove, onClear, topicLabels }) => {
  const chips = buildChips(value, topicLabels);

  if (chips.length === 0) return null;

  return (
    <div className="flex flex-wrap items-center gap-2 py-2">
      {chips.map((chip, index) => (
        <button
          key={`${chip.key}-${chip.topicValue ?? index}`}
          type="button"
          onClick={() => onRemove(chip.key, chip.topicValue)}
          className="flex items-center gap-1.5 pl-3 pr-2 py-1.5 rounded-full text-sm font-medium bg-teal-50 text-teal-700 border border-teal-200 hover:bg-teal-100 transition-colors"
        >
          <span>{chip.label}</span>
          <X className="w-3.5 h-3.5" />
        </button>
      ))}
      <button
        type="button"
        onClick={onClear}
        className="text-sm font-medium text-gray-500 hover:text-gray-700 underline underline-offset-2 px-1"
      >
        Clear
      </button>
    </div>
  );
};

export default ActiveFilterChips;
