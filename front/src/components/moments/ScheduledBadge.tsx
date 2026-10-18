import React from "react";
import { useTranslation } from "react-i18next";
import { CalendarClock } from "lucide-react";

/** "Scheduled for <time>", shown to the author in place of a relative time. */
const ScheduledBadge: React.FC<{ at: string; className?: string }> = ({ at, className }) => {
  const { t, i18n } = useTranslation();
  const locale = ((i18n && i18n.language) || "en").replace(/_/g, "-");
  let time: string;
  try {
    time = new Date(at).toLocaleString(locale, { dateStyle: "medium", timeStyle: "short" } as any);
  } catch (e) {
    time = new Date(at).toLocaleString();
  }
  const text = t("moments_section.schedule.badge", { time });
  return (
    <span
      data-testid="scheduled-badge"
      className={
        className ||
        "inline-flex items-center gap-1 rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-semibold text-amber-800"
      }
    >
      <CalendarClock className="h-3 w-3" aria-hidden />
      {text && text !== "moments_section.schedule.badge" ? text : `Scheduled for ${time}`}
    </span>
  );
};

export default ScheduledBadge;
