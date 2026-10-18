import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { FaFilter, FaSearch, FaTimes } from "react-icons/fa";
import { MomentFilters, hasMomentFilters } from "./lib/momentFilterState";
import { MOMENT_CATEGORIES, MOMENT_MOODS } from "./lib/momentOptions";
import { languageOptions } from "./lib/languageOptions";

interface Props {
  filters: MomentFilters;
  onChange: (next: MomentFilters) => void;
}

const SELECT =
  "w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm text-gray-700 focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-400/30";
const LABEL = "mb-1 block text-xs font-medium text-gray-600";

/**
 * The moments feed's filter bar. It only edits the filter state; the server
 * does the filtering, over every moment rather than the page on screen.
 */
const MomentFiltersBar: React.FC<Props> = ({ filters, onChange }) => {
  const { t, i18n } = useTranslation();
  const tr = (key: string, fallback: string) => t(key) || fallback;
  const [open, setOpen] = useState(false);
  const [searchInput, setSearchInput] = useState(filters.q || "");

  // A Back/Forward or a cleared filter changes `q` from outside.
  useEffect(() => {
    setSearchInput(filters.q || "");
  }, [filters.q]);

  const uiLanguage = (i18n && i18n.language) || "en";
  const languages = useMemo(() => languageOptions(uiLanguage), [uiLanguage]);
  const active = hasMomentFilters(filters);
  const activeCount = (["category", "language", "mood", "tag", "q"] as const).filter((k) => filters[k]).length;

  const set = (key: keyof MomentFilters, value: string) => {
    const next = { ...filters, [key]: value || undefined };
    if (!value) delete next[key];
    onChange(next);
  };

  const submitSearch = (event: React.FormEvent) => {
    event.preventDefault();
    set("q", searchInput.trim());
  };

  return (
    <div className="mb-4">
      <div className="flex items-center justify-between gap-2">
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          aria-expanded={open}
          className="flex items-center gap-2 rounded-lg border border-gray-200 bg-white/80 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-white"
        >
          <FaFilter className="h-4 w-4 text-gray-600" />
          <span>{tr("moments_section.filters.button", "Filters")}</span>
          {active && (
            <span className="rounded-full bg-blue-500 px-2 py-0.5 text-xs text-white">{activeCount}</span>
          )}
        </button>
        {active && (
          <button
            type="button"
            onClick={() => onChange({})}
            className="flex items-center gap-1 text-sm text-red-600 hover:text-red-700"
          >
            <FaTimes className="h-3 w-3" />
            <span>{tr("moments_section.filters.clear", "Clear filters")}</span>
          </button>
        )}
      </div>

      {open && (
        <div className="mt-3 space-y-3 rounded-xl border border-gray-200 bg-white/90 p-3 sm:p-4">
          <form role="search" onSubmit={submitSearch} className="flex gap-2">
            <input
              type="search"
              value={searchInput}
              maxLength={100}
              onChange={(e) => setSearchInput(e.target.value)}
              placeholder={tr("moments_section.filters.searchPlaceholder", "Search moments")}
              aria-label={tr("moments_section.filters.searchPlaceholder", "Search moments")}
              className={SELECT}
            />
            <button
              type="submit"
              className="flex items-center gap-1 rounded-lg bg-blue-500 px-3 py-2 text-sm font-medium text-white hover:bg-blue-600"
            >
              <FaSearch className="h-3 w-3" />
              <span>{tr("moments_section.filters.search", "Search")}</span>
            </button>
          </form>

          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <label>
              <span className={LABEL}>{tr("moments_section.filters.category", "Category")}</span>
              <select className={SELECT} value={filters.category || ""} onChange={(e) => set("category", e.target.value)}>
                <option value="">{tr("moments_section.filters.any", "Any")}</option>
                {MOMENT_CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {tr(`moments_section.categories.${c}`, c)}
                  </option>
                ))}
              </select>
            </label>
            <label>
              <span className={LABEL}>{tr("moments_section.filters.language", "Language")}</span>
              <select className={SELECT} value={filters.language || ""} onChange={(e) => set("language", e.target.value)}>
                <option value="">{tr("moments_section.filters.any", "Any")}</option>
                {languages.map((l) => (
                  <option key={l.value} value={l.value}>
                    {l.label}
                  </option>
                ))}
              </select>
            </label>
            <label>
              <span className={LABEL}>{tr("moments_section.filters.mood", "Mood")}</span>
              <select className={SELECT} value={filters.mood || ""} onChange={(e) => set("mood", e.target.value)}>
                <option value="">{tr("moments_section.filters.any", "Any")}</option>
                {MOMENT_MOODS.map((m) => (
                  <option key={m.value} value={m.value}>
                    {m.emoji} {tr(`moments_section.moods.${m.value}`, m.value)}
                  </option>
                ))}
              </select>
            </label>
            <TagInput
              value={filters.tag || ""}
              label={tr("moments_section.filters.tag", "Tag")}
              placeholder={tr("moments_section.filters.tagPlaceholder", "Any tag")}
              onCommit={(v) => set("tag", v)}
            />
          </div>
        </div>
      )}
    </div>
  );
};

/** Commits on Enter or blur, so typing does not refetch on every key. */
const TagInput: React.FC<{ value: string; label: string; placeholder: string; onCommit: (v: string) => void }> = ({
  value,
  label,
  placeholder,
  onCommit,
}) => {
  const [draft, setDraft] = useState(value);
  useEffect(() => setDraft(value), [value]);
  const commit = () => {
    if (draft.trim() !== value) onCommit(draft.trim());
  };
  return (
    <label>
      <span className={LABEL}>{label}</span>
      <input
        className={SELECT}
        value={draft}
        placeholder={placeholder}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => {
          if (e.key === "Enter") {
            e.preventDefault();
            commit();
          }
        }}
      />
    </label>
  );
};

export default MomentFiltersBar;
