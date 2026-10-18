import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import DialogShell from "../../../design/DialogShell";
import { SendError } from "../lib/sendErrors";

export interface SendErrorDialogProps {
  error: SendError;
  onClose: () => void;
}

/**
 * The refusals a person can do something about. The app shows these as its
 * LimitExceeded dialog / snackbars; the web has no rewarded ads or coin
 * unlock, so the action it offers is VIP (/settings/vip).
 */
const SendErrorDialog: React.FC<SendErrorDialogProps> = ({ error, onClose }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  let title = "";
  let body = "";
  let offerVip = false;
  switch (error.kind) {
    case "firstChatLimit":
      title = t("chatPage.sendErrors.firstChatTitle") || "Wait for a reply";
      body =
        t("chatPage.sendErrors.firstChatBody") ||
        "You can send 5 messages until they reply. You can write again once they answer.";
      break;
    case "dailyLimit":
      title = t("chatPage.sendErrors.dailyTitle") || "Daily message limit reached";
      body =
        t("chatPage.sendErrors.dailyBody") ||
        "You've sent all your messages for today. Go VIP for unlimited messages, or come back tomorrow.";
      offerVip = true;
      break;
    case "conversationCap":
      title = t("chatPage.sendErrors.capTitle") || "New conversation limit reached";
      body =
        t("chatPage.sendErrors.capBody") ||
        "You've started as many new conversations as you can today. Go VIP to start as many as you want.";
      offerVip = true;
      break;
    case "blocked":
      title = t("chatPage.sendErrors.blockedTitle") || "Message not sent";
      body = t("chatPage.sendErrors.blockedBody") || "You can't send messages to this person.";
      break;
    default:
      return null;
  }

  return (
    <DialogShell labelledBy="send-error-title" onClose={onClose} testId="send-error-dialog">
      <h2 id="send-error-title" className="font-display text-base text-ink-900 dark:text-ink-50">
        {title}
      </h2>
      <p className="pt-2 text-sm text-ink-600 dark:text-ink-300">{body}</p>
      <div className="mt-5 flex justify-end gap-2">
        <button
          type="button"
          data-testid="send-error-close"
          onClick={onClose}
          className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 dark:border-line-dark dark:text-ink-200"
        >
          {t("chatPage.sendErrors.ok") || "OK"}
        </button>
        {offerVip && (
          <button
            type="button"
            data-testid="send-error-vip"
            onClick={() => {
              onClose();
              navigate("/settings/vip");
            }}
            className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white"
          >
            {t("chatPage.sendErrors.goVip") || "Go VIP"}
          </button>
        )}
      </div>
    </DialogShell>
  );
};

export default SendErrorDialog;
