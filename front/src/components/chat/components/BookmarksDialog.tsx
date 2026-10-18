import React from "react";
import { Link } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { BookmarkMinus, MessageCircle, X } from "lucide-react";
import DialogShell from "../../../design/DialogShell";
import notify from "../../../design/notify";
import { useGetBookmarksQuery, useUnbookmarkMessageMutation } from "../../../store/slices/chatSlice";
import { idOf } from "../lib/normalizeMessage";

interface BookmarksDialogProps {
  onClose: () => void;
}

const STATUS = "px-1 py-6 text-center text-sm text-ink-500 dark:text-ink-400";
const ICON_BTN =
  "flex h-8 w-8 flex-none items-center justify-center rounded-chip text-ink-500 hover:bg-ink-100 disabled:opacity-50 dark:text-ink-300 dark:hover:bg-ink-800";

/** The viewer's saved messages from every chat, newest first, the way the app's bookmarks screen lists them. */
const BookmarksDialog: React.FC<BookmarksDialogProps> = ({ onClose }) => {
  const { t, i18n } = useTranslation();
  const viewerId = useSelector((state: any) => state.auth.userInfo?.user?._id || "");
  const { data, isLoading, isError } = useGetBookmarksQuery({ page: 1, limit: 50 });
  const [unbookmark, { isLoading: isRemoving }] = useUnbookmarkMessageMutation();

  // The server lists in the order things were saved and keeps a row whose
  // message was deleted (message: null).
  const rows: any[] = ((data && data.data) || [])
    .filter((row: any) => row && row.message && row.message._id)
    .slice()
    .reverse();

  const remove = async (messageId: string): Promise<void> => {
    try {
      await unbookmark(messageId).unwrap();
      notify.success(t("chatPage.bookmarks.removed") || "Removed from saved messages");
    } catch (error) {
      const body: any = error && (error as any).data;
      notify.error((body && (body.error || body.message)) || t("chatPage.bookmarks.removeFailed") || "Couldn't remove it");
    }
  };

  let status: string | null = null;
  if (isLoading) status = t("chatPage.bookmarks.loading") || "Loading saved messages…";
  else if (isError) status = t("chatPage.bookmarks.error") || "Couldn't load saved messages";
  else if (rows.length === 0) status = t("chatPage.bookmarks.empty") || "No saved messages yet";

  return (
    <DialogShell
      labelledBy="chat-bookmarks-title"
      onClose={onClose}
      testId="chat-bookmarks-dialog"
      backdropTestId="chat-bookmarks-backdrop"
      panelClassName={[
        "relative flex max-h-[85vh] w-full max-w-lg flex-col rounded-card border border-line",
        "bg-surface p-4 shadow-lg dark:border-line-dark dark:bg-cardbg-dark",
      ].join(" ")}
    >
      <div className="flex items-start justify-between gap-2">
        <h2 id="chat-bookmarks-title" className="font-display text-base text-ink-900 dark:text-ink-50">
          {t("chatPage.bookmarks.title") || "Saved messages"}
        </h2>
        <button type="button" onClick={onClose} aria-label={t("chatPage.bookmarks.close") || "Close"} className={ICON_BTN}>
          <X className="h-4 w-4" aria-hidden />
        </button>
      </div>

      <div className="mt-2 flex-1 overflow-y-auto">
        {status ? (
          <p className={STATUS} role="status">
            {status}
          </p>
        ) : (
          rows.map((row: any) => {
            const msg = row.message;
            const senderId = idOf(msg.sender);
            const partner = senderId === viewerId ? msg.receiver : msg.sender;
            const partnerId = idOf(partner);
            const partnerName = (partner && typeof partner === "object" && partner.name) || "";
            const body =
              msg.message ||
              (msg.media && (msg.media.fileName || msg.media.type)) ||
              t("chatPage.bookmarks.attachment") ||
              "Attachment";
            const when = new Date(msg.createdAt);
            return (
              <div
                key={msg._id}
                data-testid={`bookmark-row-${msg._id}`}
                className="flex items-start gap-2 rounded-card px-2 py-2 hover:bg-ink-50 dark:hover:bg-ink-900"
              >
                <div className="min-w-0 flex-1">
                  <p className="flex items-baseline justify-between gap-2 text-xs text-ink-500 dark:text-ink-400">
                    <span className="truncate font-semibold text-ink-700 dark:text-ink-200">{partnerName}</span>
                    <span>
                      {isNaN(when.getTime())
                        ? ""
                        : when.toLocaleDateString(i18n.language || undefined, { month: "short", day: "numeric" })}
                    </span>
                  </p>
                  <p className="line-clamp-3 text-sm text-ink-900 dark:text-ink-50">{body}</p>
                </div>
                {partnerId ? (
                  <Link
                    to={`/chat/${partnerId}`}
                    data-testid={`bookmark-open-${msg._id}`}
                    onClick={onClose}
                    aria-label={t("chatPage.bookmarks.open") || "Open chat"}
                    title={t("chatPage.bookmarks.open") || "Open chat"}
                    className={ICON_BTN}
                  >
                    <MessageCircle className="h-4 w-4" aria-hidden />
                  </Link>
                ) : null}
                <button
                  type="button"
                  data-testid={`bookmark-remove-${msg._id}`}
                  onClick={() => remove(String(msg._id))}
                  disabled={isRemoving}
                  aria-label={t("chatPage.bookmarks.remove") || "Remove from saved"}
                  title={t("chatPage.bookmarks.remove") || "Remove from saved"}
                  className={ICON_BTN}
                >
                  <BookmarkMinus className="h-4 w-4" aria-hidden />
                </button>
              </div>
            );
          })
        )}
      </div>
    </DialogShell>
  );
};

export default BookmarksDialog;
