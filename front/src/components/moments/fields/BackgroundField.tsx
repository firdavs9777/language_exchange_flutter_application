import React from "react";
import { useTranslation } from "react-i18next";
import { MOMENT_GRADIENT_KEYS, gradientFor } from "../media/momentGradients";

/** The text-moment backgrounds; "" is plain text. */
const BackgroundField: React.FC<{ value: string; onChange: (v: string) => void }> = ({ value, onChange }) => {
  const { t } = useTranslation();
  return (
    <div className="flex gap-2 overflow-x-auto pb-2">
      <button
        type="button"
        onClick={() => onChange("")}
        aria-pressed={value === ""}
        className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-lg border text-xs font-medium ${
          value === ""
            ? "border-blue-500 ring-2 ring-blue-500 text-blue-600"
            : "border-gray-300 text-gray-600 dark:border-gray-700 dark:text-gray-300"
        }`}
        title="No background"
      >
        {t("moments_section.fields.backgroundNone") || "None"}
      </button>
      {MOMENT_GRADIENT_KEYS.map((key: string) => (
        <button
          key={key}
          type="button"
          onClick={() => onChange(key)}
          aria-pressed={value === key}
          className={`h-12 w-12 shrink-0 rounded-lg border transition-transform ${
            value === key ? "ring-2 ring-offset-2 ring-blue-500 scale-105" : "border-gray-200 dark:border-gray-700"
          }`}
          style={{ background: gradientFor(key) }}
          aria-label={key}
        />
      ))}
    </div>
  );
};

export default BackgroundField;
