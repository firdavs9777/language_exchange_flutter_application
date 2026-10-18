import React from "react";
import { useTranslation } from "react-i18next";
import { useSocket } from "./hooks/useSocket";

/** Shown when the server dropped this tab for a newer connection. */
const ConnectionBanner: React.FC = () => {
  const { t } = useTranslation();
  const { kicked, reconnect } = useSocket() as any;
  if (!kicked) return null;
  return (
    <div
      role="status"
      data-testid="connection-banner"
      className="flex items-center justify-between gap-3 bg-amber-50 px-4 py-2 text-sm text-amber-900 dark:bg-amber-500/10 dark:text-amber-200"
    >
      <span>
        {t("chatPage.connection.kicked") ||
          "Chat is open somewhere else, so this tab stopped receiving messages."}
      </span>
      <button
        type="button"
        data-testid="connection-banner-reconnect"
        onClick={() => reconnect()}
        className="shrink-0 rounded-chip bg-amber-600 px-3 py-1 text-xs font-semibold text-white"
      >
        {t("chatPage.connection.reconnect") || "Use here"}
      </button>
    </div>
  );
};

export default ConnectionBanner;
