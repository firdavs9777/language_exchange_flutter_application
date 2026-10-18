import React from "react";
import { useTranslation } from "react-i18next";
import { languageFlag } from "../../../utils/languages";

interface LanguageFlagChipProps {
  label: "FLUENT" | "LEARNS" | "NATIVE";
  language?: string;
  extra?: number;
}

const LABEL_I18N_KEYS: Record<LanguageFlagChipProps["label"], string> = {
  FLUENT: "communityMain.languageChip.fluent",
  LEARNS: "communityMain.languageChip.learns",
  NATIVE: "communityMain.languageChip.native",
};

const LanguageFlagChip: React.FC<LanguageFlagChipProps> = ({ label, language, extra }) => {
  const { t } = useTranslation();
  const flag = languageFlag(language || "");
  const localizedLabel = t(LABEL_I18N_KEYS[label]) || label;
  return (
    <div className="lang-flag-chip">
      <small className="lang-flag-chip__label">{localizedLabel}</small>
      <span className="lang-flag-chip__flag" aria-hidden>
        {flag}
      </span>
      {typeof extra === "number" && extra > 0 && (
        <span className="lang-flag-chip__extra">+{extra}</span>
      )}
    </div>
  );
};

export default LanguageFlagChip;
