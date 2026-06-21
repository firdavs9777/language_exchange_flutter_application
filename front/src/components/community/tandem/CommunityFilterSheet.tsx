import React, { useEffect, useState } from "react";
import { X } from "lucide-react";
import { useTranslation } from "react-i18next";
import { COMMON_LANGUAGES, LANGUAGE_FLAGS, LANGUAGE_CODES } from "../type";

export interface CommunityFilters {
  language: string;
  gender: "" | "male" | "female" | "other";
  ageMin: number | "";
  ageMax: number | "";
  onlineOnly: boolean;
  newOnly: boolean;
}

export const EMPTY_FILTERS: CommunityFilters = {
  language: "",
  gender: "",
  ageMin: "",
  ageMax: "",
  onlineOnly: false,
  newOnly: false,
};

export const countActiveFilters = (f: CommunityFilters): number => {
  let n = 0;
  if (f.language) n += 1;
  if (f.gender) n += 1;
  if (f.ageMin !== "" || f.ageMax !== "") n += 1;
  if (f.onlineOnly) n += 1;
  if (f.newOnly) n += 1;
  return n;
};

interface CommunityFilterSheetProps {
  open: boolean;
  initialFilters: CommunityFilters;
  onClose: () => void;
  onApply: (filters: CommunityFilters) => void;
}

const CommunityFilterSheet: React.FC<CommunityFilterSheetProps> = ({
  open,
  initialFilters,
  onClose,
  onApply,
}) => {
  const { t } = useTranslation();
  const [draft, setDraft] = useState<CommunityFilters>(initialFilters);

  useEffect(() => {
    if (open) setDraft(initialFilters);
  }, [open, initialFilters]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  const handleReset = () => setDraft(EMPTY_FILTERS);
  const handleApply = () => onApply(draft);

  return (
    <div
      className="filter-sheet"
      role="dialog"
      aria-modal="true"
      aria-label={t("communityMain.filterSheet.title") || "Filters"}
    >
      <div className="filter-sheet__backdrop" onClick={onClose} />
      <div className="filter-sheet__panel">
        <header className="filter-sheet__header">
          <h2>{t("communityMain.filterSheet.title") || "Filters"}</h2>
          <button
            type="button"
            className="filter-sheet__close"
            onClick={onClose}
            aria-label={t("communityMain.filterSheet.title") || "Close filters"}
          >
            <X size={18} />
          </button>
        </header>

        <div className="filter-sheet__body">
          <section className="filter-section">
            <h3>{t("communityMain.filterSheet.language") || "Language"}</h3>
            <div className="filter-chips">
              <button
                type="button"
                className={`filter-chip ${!draft.language ? "filter-chip--active" : ""}`}
                onClick={() => setDraft((d) => ({ ...d, language: "" }))}
              >
                {t("communityMain.filterSheet.any") || "Any"}
              </button>
              {COMMON_LANGUAGES.map((lang) => (
                <button
                  key={lang}
                  type="button"
                  className={`filter-chip ${draft.language === lang ? "filter-chip--active" : ""}`}
                  onClick={() => setDraft((d) => ({ ...d, language: lang }))}
                >
                  <span>
                    {LANGUAGE_FLAGS[LANGUAGE_CODES[lang]] || "🌐"}
                  </span>
                  {lang}
                </button>
              ))}
            </div>
          </section>

          <section className="filter-section">
            <h3>{t("communityMain.filterSheet.gender") || "Gender"}</h3>
            <div className="filter-chips">
              {(["", "male", "female", "other"] as const).map((g) => {
                const label =
                  g === ""
                    ? t("communityMain.filterSheet.any") || "Any"
                    : t(`communityMain.filterSheet.${g}`) ||
                      g.charAt(0).toUpperCase() + g.slice(1);
                return (
                  <button
                    key={g || "any"}
                    type="button"
                    className={`filter-chip ${draft.gender === g ? "filter-chip--active" : ""}`}
                    onClick={() => setDraft((d) => ({ ...d, gender: g }))}
                  >
                    {label}
                  </button>
                );
              })}
            </div>
          </section>

          <section className="filter-section">
            <h3>{t("communityMain.filterSheet.ageRange") || "Age range"}</h3>
            <div className="filter-age">
              <label>
                <span>{t("communityMain.filterSheet.min") || "Min"}</span>
                <input
                  type="number"
                  min={13}
                  max={120}
                  placeholder="—"
                  value={draft.ageMin}
                  onChange={(e) => {
                    const v = e.target.value;
                    setDraft((d) => ({ ...d, ageMin: v === "" ? "" : Number(v) }));
                  }}
                />
              </label>
              <span className="filter-age__dash">–</span>
              <label>
                <span>{t("communityMain.filterSheet.max") || "Max"}</span>
                <input
                  type="number"
                  min={13}
                  max={120}
                  placeholder="—"
                  value={draft.ageMax}
                  onChange={(e) => {
                    const v = e.target.value;
                    setDraft((d) => ({ ...d, ageMax: v === "" ? "" : Number(v) }));
                  }}
                />
              </label>
            </div>
          </section>

          <section className="filter-section">
            <h3>{t("communityMain.filterSheet.experience") || "Member experience"}</h3>
            <label className="filter-toggle">
              <input
                type="checkbox"
                checked={draft.onlineOnly}
                onChange={(e) => setDraft((d) => ({ ...d, onlineOnly: e.target.checked }))}
              />
              <span>{t("communityMain.filterSheet.onlineNow") || "Online now"}</span>
            </label>
            <label className="filter-toggle">
              <input
                type="checkbox"
                checked={draft.newOnly}
                onChange={(e) => setDraft((d) => ({ ...d, newOnly: e.target.checked }))}
              />
              <span>
                {t("communityMain.filterSheet.newMembersOnly") ||
                  "New members only (last 7 days)"}
              </span>
            </label>
          </section>
        </div>

        <footer className="filter-sheet__footer">
          <button type="button" className="filter-sheet__reset" onClick={handleReset}>
            {t("communityMain.filterSheet.reset") || "Reset"}
          </button>
          <button type="button" className="filter-sheet__apply" onClick={handleApply}>
            {t("communityMain.filterSheet.apply") || "Apply"}
          </button>
        </footer>
      </div>
    </div>
  );
};

export default CommunityFilterSheet;
