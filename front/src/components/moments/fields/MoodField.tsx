import React from "react";
import { useTranslation } from "react-i18next";
import { MOMENT_MOODS } from "../lib/momentOptions";

const ENGLISH: Record<string, string> = {
  happy: "Happy",
  excited: "Excited",
  grateful: "Grateful",
  motivated: "Motivated",
  relaxed: "Relaxed",
  curious: "Curious",
  sad: "Sad",
  love: "In love",
  funny: "Funny",
  thoughtful: "Thoughtful",
  cool: "Cool",
  tired: "Tired",
};

export const moodLabel = (t: (k: string) => string, value: string) =>
  t(`moments_section.moods.${value}`) || ENGLISH[value] || value;

export const moodEmoji = (value: string) => {
  const mood = MOMENT_MOODS.find((m) => m.value === value);
  return mood ? mood.emoji : "";
};

/** The twelve moods as a grid of buttons; `allowNone` adds "No mood". */
const MoodField: React.FC<{
  value: string;
  onChange: (v: string) => void;
  allowNone?: boolean;
  /** Labels only, no emoji (the design-system editor). */
  plain?: boolean;
}> = ({ value, onChange, allowNone, plain }) => {
  const { t } = useTranslation();
  const chip = (active: boolean) =>
    `flex items-center gap-2 p-2 rounded text-left text-sm ${active ? "bg-yellow-100 text-yellow-800" : "hover:bg-gray-100"}`;
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
      {allowNone && (
        <button type="button" onClick={() => onChange("")} className={chip(value === "")} aria-pressed={value === ""}>
          {!plain && <span>—</span>}
          <span>{t("moments_section.fields.noMood") || "No mood"}</span>
        </button>
      )}
      {MOMENT_MOODS.map((m) => (
        <button
          key={m.value}
          type="button"
          onClick={() => onChange(m.value)}
          className={chip(value === m.value)}
          aria-pressed={value === m.value}
        >
          {!plain && <span>{m.emoji}</span>}
          <span>{moodLabel(t, m.value)}</span>
        </button>
      ))}
    </div>
  );
};

export default MoodField;
