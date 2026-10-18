import React from "react";
import { useTranslation } from "react-i18next";
import { moodEmoji, moodLabel } from "./fields/MoodField";

interface MomentChipsProps {
  mood?: string;
  tags?: string[];
  location?: { formattedAddress?: string } | null;
}

/** Mood, tags and place as one wrap-around chip row (the app's card shows them). */
const MomentChips: React.FC<MomentChipsProps> = ({ mood, tags, location }) => {
  const { t } = useTranslation();
  const tagList = Array.isArray(tags) ? tags.filter((x) => typeof x === "string" && x.trim()) : [];
  const place = location && typeof location.formattedAddress === "string" ? location.formattedAddress.trim() : "";
  if (!mood && tagList.length === 0 && !place) return null;
  return (
    <div data-testid="moment-chips" className="mt-2 flex flex-wrap gap-1.5">
      {mood && (
        <span className="inline-flex items-center gap-1 rounded-full bg-yellow-50 px-2 py-0.5 text-xs font-medium text-yellow-800">
          <span aria-hidden="true">{moodEmoji(mood)}</span>
          {moodLabel(t, mood)}
        </span>
      )}
      {tagList.map((tag) => (
        <span key={tag} className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700">
          #{tag}
        </span>
      ))}
      {place && (
        <span
          data-testid="moment-chip-location"
          className="inline-flex max-w-full items-center gap-1 truncate rounded-full bg-green-50 px-2 py-0.5 text-xs font-medium text-green-800"
        >
          <span aria-hidden="true">📍</span>
          <span className="truncate">{place}</span>
        </span>
      )}
    </div>
  );
};

export default MomentChips;
