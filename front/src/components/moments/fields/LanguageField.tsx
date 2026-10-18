import React, { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { languageOptions } from "../lib/languageOptions";
import { FIELD_LABEL, FIELD_SELECT } from "./fieldStyles";

const LanguageField: React.FC<{ value: string; onChange: (v: string) => void; id?: string }> = ({
  value,
  onChange,
  id = "moment-language",
}) => {
  const { t, i18n } = useTranslation();
  const uiLanguage = (i18n && i18n.language) || "en";
  const options = useMemo(() => languageOptions(uiLanguage), [uiLanguage]);
  return (
    <div>
      <label htmlFor={id} className={FIELD_LABEL}>
        {t("moments_section.filters.language") || "Language"}
      </label>
      <select id={id} value={value} onChange={(e) => onChange(e.target.value)} className={FIELD_SELECT}>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </div>
  );
};

export default LanguageField;
