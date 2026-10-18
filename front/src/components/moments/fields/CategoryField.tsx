import React from "react";
import { useTranslation } from "react-i18next";
import { MOMENT_CATEGORIES } from "../lib/momentOptions";
import { FIELD_LABEL, FIELD_SELECT } from "./fieldStyles";

const ENGLISH: Record<string, string> = {
  general: "General",
  "language-learning": "Language learning",
  culture: "Culture",
  food: "Food",
  travel: "Travel",
  music: "Music",
  books: "Books",
  hobbies: "Hobbies",
  "daily-life": "Daily life",
  technology: "Technology",
  entertainment: "Entertainment",
  sports: "Sports",
  movies: "Movies",
  study: "Study",
  work: "Work",
  question: "Question",
};

export const categoryLabel = (t: (k: string) => string, value: string) =>
  t(`moments_section.categories.${value}`) || ENGLISH[value] || value;

const CategoryField: React.FC<{ value: string; onChange: (v: string) => void; id?: string }> = ({
  value,
  onChange,
  id = "moment-category",
}) => {
  const { t } = useTranslation();
  return (
    <div>
      <label htmlFor={id} className={FIELD_LABEL}>
        {t("moments_section.filters.category") || "Category"}
      </label>
      <select id={id} value={value} onChange={(e) => onChange(e.target.value)} className={FIELD_SELECT}>
        {MOMENT_CATEGORIES.map((c) => (
          <option key={c} value={c}>
            {categoryLabel(t, c)}
          </option>
        ))}
      </select>
    </div>
  );
};

export default CategoryField;
