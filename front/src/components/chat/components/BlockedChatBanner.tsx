import React from "react";
import { useTranslation } from "react-i18next";
import { Ban } from "lucide-react";

interface BlockedChatBannerProps {
  iBlocked: boolean;
  onManage?: () => void;
}

/**
 * Takes the composer's place in a blocked chat, like the app's
 * _BlockedBanner. "They blocked you" is never said outright (the app's
 * wording is "User may be blocked"); a block the viewer made says so and
 * offers the way back.
 */
const BlockedChatBanner: React.FC<BlockedChatBannerProps> = ({ iBlocked, onManage }) => {
  const { t } = useTranslation();
  return (
    <div className="blocked-chat-banner" role="status" data-testid="blocked-chat-banner">
      <Ban size={16} aria-hidden="true" />
      <span className="blocked-chat-banner-text">
        {iBlocked
          ? t("chatPage.blocked.byMe") || "You blocked this person. Unblock them to send messages."
          : t("chatPage.blocked.generic") || "You can't send messages in this chat."}
      </span>
      {iBlocked && onManage ? (
        <button
          type="button"
          className="blocked-chat-banner-action"
          data-testid="blocked-chat-banner-manage"
          onClick={onManage}
        >
          {t("chatPage.blocked.manage") || "Manage"}
        </button>
      ) : null}
    </div>
  );
};

export default BlockedChatBanner;
