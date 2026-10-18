import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Phone, Video } from "lucide-react";
import DialogShell from "../../../design/DialogShell";
import { openInApp } from "../../linking/openInAppAction";

interface CallInAppButtonsProps {
  partnerId: string;
  partnerName: string;
  isGroup?: boolean;
  blocked?: boolean;
}

/**
 * Voice/video buttons for the chat header. The website does not place calls
 * (owner decision 2026-10-16): either button explains that calls happen in
 * the app and offers to open the partner there. On desktop the open-in-app
 * helper goes to /download instead. Hidden in group and blocked chats.
 */
const CallInAppButtons: React.FC<CallInAppButtonsProps> = ({
  partnerId,
  partnerName,
  isGroup,
  blocked,
}) => {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);

  if (!partnerId || isGroup || blocked) return null;

  const handleOpenApp = () => {
    setOpen(false);
    openInApp({
      type: "profile",
      id: partnerId,
      ua: navigator.userAgent,
      navigate: (url) => {
        window.location.href = url;
      },
      schedule: (fn, ms) => {
        window.setTimeout(fn, ms);
      },
      isVisible: () => document.visibilityState === "visible",
    });
  };

  const voiceLabel = t("chatPage.callInApp.voice") || "Voice call";
  const videoLabel = t("chatPage.callInApp.video") || "Video call";

  return (
    <>
      <button
        className="action-btn"
        type="button"
        data-testid="chat-header-voice-call"
        onClick={() => setOpen(true)}
        aria-haspopup="dialog"
        title={voiceLabel}
        aria-label={voiceLabel}
      >
        <Phone size={20} />
      </button>
      <button
        className="action-btn"
        type="button"
        data-testid="chat-header-video-call"
        onClick={() => setOpen(true)}
        aria-haspopup="dialog"
        title={videoLabel}
        aria-label={videoLabel}
      >
        <Video size={20} />
      </button>
      {open && (
        <DialogShell
          labelledBy="call-in-app-title"
          onClose={() => setOpen(false)}
          testId="call-in-app-dialog"
          backdropTestId="call-in-app-backdrop"
        >
          <h2 id="call-in-app-title" className="font-display text-base text-ink-900 dark:text-ink-50">
            {t("chatPage.callInApp.title") || "Calls happen in the BananaTalk app"}
          </h2>
          <p className="mt-2 text-sm text-ink-700 dark:text-ink-200">
            {t("chatPage.callInApp.body", { name: partnerName }) ||
              `Open the app to call ${partnerName}. Incoming calls ring on your phone.`}
          </p>
          <div className="mt-4 flex justify-end gap-2">
            <button
              type="button"
              data-testid="call-in-app-dismiss"
              onClick={() => setOpen(false)}
              className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
            >
              {t("chatPage.callInApp.notNow") || "Not now"}
            </button>
            <button
              type="button"
              data-testid="call-in-app-open"
              onClick={handleOpenApp}
              className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-bold text-white hover:bg-brand-deep/90"
            >
              {t("chatPage.callInApp.openApp") || "Open the app"}
            </button>
          </div>
        </DialogShell>
      )}
    </>
  );
};

export default CallInAppButtons;
