import React, { useEffect, useRef, useState } from "react";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { Search, X } from "lucide-react";
import DialogShell from "../../../design/DialogShell";
import { useSearchMessagesQuery } from "../../../store/slices/chatSlice";
import { senderIdOf } from "../lib/normalizeMessage";

interface MessageSearchDialogProps {
  /** The OTHER person: the search endpoint's `conversationId` is their user id. */
  partnerId: string;
  partnerName: string;
  onClose: () => void;
  onJump: (messageId: string) => void;
  /** Tests pass 0. The endpoint allows 20 searches a minute. */
  debounceMs?: number;
}

const MIN_CHARS = 2;
const RESULT_LIMIT = 30;

const FIELD = [
  "w-full rounded-card border border-line bg-surface py-2 ps-9 pe-3 text-sm",
  "text-ink-900 placeholder:text-ink-400",
  "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
].join(" ");
const STATUS = "px-1 py-6 text-center text-sm text-ink-500 dark:text-ink-400";

/** Search one conversation, newest first; picking a result jumps to it in the thread. */
const MessageSearchDialog: React.FC<MessageSearchDialogProps> = ({
  partnerId,
  partnerName,
  onClose,
  onJump,
  debounceMs = 350,
}) => {
  const { t, i18n } = useTranslation();
  const viewerId = useSelector((state: any) => state.auth.userInfo?.user?._id || "");
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [text, setText] = useState("");
  const [query, setQuery] = useState("");

  useEffect(() => {
    const trimmed = text.trim();
    const timer = setTimeout(() => setQuery(trimmed), debounceMs);
    return () => clearTimeout(timer);
  }, [text, debounceMs]);

  const tooShort = query.length < MIN_CHARS;
  const { data, isFetching, isError } = useSearchMessagesQuery(
    { query: query, conversationId: partnerId, limit: RESULT_LIMIT },
    { skip: tooShort || !partnerId }
  );
  const results: any[] = !tooShort && data && Array.isArray(data.data) ? data.data : [];

  const dateLabel = (iso: string): string => {
    const date = new Date(iso);
    return isNaN(date.getTime())
      ? ""
      : date.toLocaleDateString(i18n.language || undefined, { month: "short", day: "numeric", year: "numeric" });
  };

  let status: string | null = null;
  if (tooShort) status = t("chatPage.search.hint") || "Type at least 2 characters";
  else if (isError) status = t("chatPage.search.unavailable") || "Search isn't available right now";
  else if (isFetching && results.length === 0) status = t("chatPage.search.searching") || "Searching…";
  else if (results.length === 0) status = t("chatPage.search.empty") || "No messages found";

  return (
    <DialogShell
      labelledBy="chat-search-title"
      onClose={onClose}
      testId="chat-search-dialog-shell"
      backdropTestId="chat-search-backdrop"
      initialFocusRef={inputRef}
      panelClassName={[
        "relative flex max-h-[85vh] w-full max-w-lg flex-col rounded-card border border-line",
        "bg-surface p-4 shadow-lg dark:border-line-dark dark:bg-cardbg-dark",
      ].join(" ")}
    >
      <div className="flex items-start justify-between gap-2">
        <h2 id="chat-search-title" className="font-display text-base text-ink-900 dark:text-ink-50">
          {t("chatPage.search.title", { name: partnerName }) || `Search messages with ${partnerName}`}
        </h2>
        <button
          type="button"
          onClick={onClose}
          aria-label={t("chatPage.search.close") || "Close"}
          className="rounded-chip p-1.5 text-ink-500 hover:bg-ink-100 dark:text-ink-300 dark:hover:bg-ink-800"
        >
          <X className="h-4 w-4" aria-hidden />
        </button>
      </div>

      <div className="relative mt-3">
        <Search className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-400" aria-hidden />
        <input
          ref={inputRef}
          type="search"
          data-testid="chat-search-input"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder={t("chatPage.search.placeholder") || "Search this chat"}
          aria-label={t("chatPage.search.placeholder") || "Search this chat"}
          className={FIELD}
        />
      </div>

      <div className="mt-2 flex-1 overflow-y-auto" role="list">
        {status ? (
          <p className={STATUS} role="status">
            {status}
          </p>
        ) : (
          results.map((m: any) => {
            const mine = senderIdOf(m) === viewerId;
            const who = mine ? t("chatPage.search.you") || "You" : partnerName;
            const body = m.message || (m.media && m.media.fileName) || "";
            return (
              <button
                key={m._id}
                type="button"
                role="listitem"
                data-testid={`chat-search-result-${m._id}`}
                onClick={() => onJump(String(m._id))}
                className="flex w-full flex-col gap-0.5 rounded-card px-3 py-2 text-start hover:bg-ink-100 dark:hover:bg-ink-800"
              >
                <span className="flex w-full items-baseline justify-between gap-2 text-xs text-ink-500 dark:text-ink-400">
                  <span className="font-semibold text-ink-700 dark:text-ink-200">{who}</span>
                  <span>{dateLabel(m.createdAt)}</span>
                </span>
                <span className="line-clamp-2 text-sm text-ink-900 dark:text-ink-50">{body}</span>
              </button>
            );
          })
        )}
      </div>
    </DialogShell>
  );
};

export default MessageSearchDialog;
