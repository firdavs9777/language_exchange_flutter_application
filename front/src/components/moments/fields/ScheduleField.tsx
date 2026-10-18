import React from "react";
import { useTranslation } from "react-i18next";
import { isFutureInput, minScheduleInput } from "../lib/scheduling";
import { FIELD_LABEL, FIELD_SELECT } from "./fieldStyles";

/**
 * "Schedule" as a `datetime-local` value, "" meaning post now. Render it only
 * while the server enforces scheduling (useMomentSchedulingEnabled): otherwise
 * a scheduled moment would publish immediately.
 */
const ScheduleField: React.FC<{ value: string; onChange: (v: string) => void; id?: string }> = ({
  value,
  onChange,
  id = "moment-schedule",
}) => {
  const { t } = useTranslation();
  const past = Boolean(value) && !isFutureInput(value);
  return (
    <div>
      <label htmlFor={id} className={FIELD_LABEL}>
        {t("moments_section.schedule.label") || "Schedule"}
      </label>
      <input
        id={id}
        type="datetime-local"
        value={value}
        min={minScheduleInput()}
        onChange={(e) => onChange(e.target.value)}
        aria-invalid={past}
        className={FIELD_SELECT}
      />
      {past ? (
        <p role="alert" className="mt-1 text-xs text-red-600">
          {t("moments_section.schedule.past") || "Pick a time in the future"}
        </p>
      ) : (
        !value && (
          <p className="mt-1 text-xs text-gray-500">
            {t("moments_section.schedule.hint") || "Leave empty to post now"}
          </p>
        )
      )}
      {value && (
        <button type="button" onClick={() => onChange("")} className="mt-1 text-xs text-blue-600 hover:underline">
          {t("moments_section.schedule.clear") || "Post now instead"}
        </button>
      )}
    </div>
  );
};

export default ScheduleField;
