import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import { Crown } from "lucide-react";
import { VIP_PATH } from "./vipStatus";

/**
 * Daily free limits (moments 10/day, comments 50/day, stories 5/day) come
 * back as HTTP 429 with `{ success:false, error, message }` from
 * backend/utils/limitations.js formatLimitError ("Daily moments limit
 * exceeded. ..."). The message-translation limit is a 403 with
 * `error: "TRANSLATION_LIMIT_REACHED"`. Plain IP rate limiting is also a 429
 * ("Too many requests ...") and is NOT a daily limit, so it is excluded.
 *
 * Returns the server's message when `err` (an RTK Query error) is a daily
 * limit, otherwise null.
 */
export function getDailyLimitMessage(err: any): string | null {
  if (!err) return null;
  const status = err.status ?? err.originalStatus;
  const data = err.data || {};
  const message: string =
    (typeof data.message === "string" && data.message) ||
    (typeof data.error === "string" && data.error) ||
    "";

  if (data.error === "TRANSLATION_LIMIT_REACHED") {
    return typeof data.message === "string" ? data.message : "";
  }
  if (status === 429 && /limit/i.test(message) && !/too many/i.test(message)) {
    return message;
  }
  return null;
}

export const DailyLimitToastContent: React.FC<{ message?: string }> = ({ message }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  return (
    <div className="flex flex-col gap-2" data-testid="daily-limit-toast">
      <strong>{t("vip.limit.title") || "Daily limit reached"}</strong>
      <span className="text-sm opacity-80">
        {t("vip.limit.body") || "You've used today's free allowance. VIP removes the daily limits."}
      </span>
      {message ? <span className="text-xs opacity-60">{message}</span> : null}
      <button
        type="button"
        onClick={() => navigate(VIP_PATH)}
        className="self-start mt-1 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-semibold text-black bg-gradient-to-r from-[#FFD700] to-[#FFA500]"
      >
        <Crown className="w-4 h-4" />
        {t("vip.limit.cta") || "Upgrade to VIP"}
      </button>
    </div>
  );
};

/**
 * Shows the upgrade toast when `err` is a daily-limit error.
 * Returns true when it handled the error so callers can skip their own toast.
 */
export function showDailyLimitToast(err: any): boolean {
  const message = getDailyLimitMessage(err);
  if (message === null) return false;
  notify.warning(<DailyLimitToastContent message={message} />, {
    toastId: "daily-limit",
    autoClose: 8000,
  });
  return true;
}
