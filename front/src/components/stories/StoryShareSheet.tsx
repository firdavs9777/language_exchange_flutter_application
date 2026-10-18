import React, { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { Check, Search, Send, X } from "lucide-react";
import DialogShell from "../../design/DialogShell";
import Avatar from "../../design/Avatar";
import notify from "../../design/notify";
import { useShareStoryMutation } from "../../store/slices/storiesSlice";
import { useGetConversationsQuery } from "../../store/slices/chatSlice";

export interface StoryShareSheetProps {
  storyId: string;
  /** Needed to pick the *other* participant out of each conversation. */
  currentUserId?: string | null;
  onClose: () => void;
}

interface Recipient {
  _id: string;
  name: string;
  image?: string;
}

const TITLE_ID = "story-share-title";

const PANEL = [
  "relative flex w-full max-w-md flex-col rounded-2xl border border-line bg-surface shadow-lg",
  "max-h-[70vh] dark:border-line-dark dark:bg-cardbg-dark",
].join(" ");

/**
 * Send a story into a DM. The source list is the recent conversations the
 * chat list already loads, which is the same choice the app makes
 * (`story_share_sheet.dart` uses recent chat partners rather than a second
 * people search): one request, and it covers the case people actually use.
 *
 * One recipient per click rather than a multi-select with a Send button —
 * each tap is its own `POST /:id/share`, so a recipient the backend rejects
 * (blocked, or `allowSharing` off) fails alone and visibly instead of taking
 * a batch down with it.
 *
 * There is no "Copy link" here: `/stories/:userId` is the viewer keyed by
 * AUTHOR and its data comes from a protect-only endpoint, so a copied link
 * would 401 for everyone the story was shared with. Add the button when a
 * public `/stories/:id` route exists.
 */
const StoryShareSheet: React.FC<StoryShareSheetProps> = ({
  storyId,
  currentUserId,
  onClose,
}) => {
  const { t } = useTranslation();
  const [query, setQuery] = useState("");
  const [sentTo, setSentTo] = useState<string[]>([]);
  const [sending, setSending] = useState<string | null>(null);

  const { data, isLoading, error } = useGetConversationsQuery({ page: 1, limit: 30 });
  const [shareStory] = useShareStoryMutation();

  const recipients: Recipient[] = useMemo(() => {
    const conversations = (data as any)?.data;
    if (!Array.isArray(conversations)) return [];

    const seen: { [id: string]: boolean } = {};
    const out: Recipient[] = [];
    conversations.forEach((conversation: any) => {
      const participants = conversation?.participants || [];
      const other = participants.find(
        (participant: any) => participant && participant._id !== currentUserId
      );
      if (!other || !other._id || seen[other._id]) return;
      seen[other._id] = true;
      out.push({
        _id: other._id,
        name: other.name || "",
        image: (other.imageUrls || other.images || [])[0],
      });
    });
    return out;
  }, [data, currentUserId]);

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return recipients;
    return recipients.filter((r) => r.name.toLowerCase().indexOf(needle) !== -1);
  }, [recipients, query]);

  const send = async (recipient: Recipient) => {
    if (sending || sentTo.indexOf(recipient._id) !== -1) return;
    setSending(recipient._id);
    try {
      await shareStory({
        id: storyId,
        sharedTo: "dm",
        receiverId: recipient._id,
      }).unwrap();
      setSentTo((previous) => previous.concat(recipient._id));
      notify.success(t("stories.shared") || "Sent");
    } catch (err) {
      notify.error(t("stories.share_failed") || "Couldn't share this story");
    } finally {
      setSending(null);
    }
  };

  return (
    <DialogShell
      labelledBy={TITLE_ID}
      onClose={onClose}
      testId="story-share-sheet"
      backdropTestId="story-share-backdrop"
      panelClassName={PANEL}
    >
      <div className="flex items-center gap-2 border-b border-line px-4 py-3 dark:border-line-dark">
        <Send size={18} className="text-gray-500" aria-hidden />
        <h2 id={TITLE_ID} className="flex-1 text-base font-semibold">
          {t("stories.share_story") || "Share"}
        </h2>
        <button
          type="button"
          data-testid="story-share-close"
          onClick={onClose}
          aria-label={t("stories.close") || "Close"}
          className="rounded-full p-1.5 text-gray-500 hover:bg-gray-100 dark:hover:bg-white/10"
        >
          <X size={18} />
        </button>
      </div>

      <div className="px-4 pt-3">
        <div className="flex items-center gap-2 rounded-full border border-line px-3 py-2 dark:border-line-dark">
          <Search size={16} className="text-gray-400" aria-hidden />
          <input
            type="text"
            data-testid="story-share-search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={t("stories.search_chats") || "Search chats"}
            aria-label={t("stories.search_chats") || "Search chats"}
            className="w-full bg-transparent text-sm outline-none"
          />
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-2 py-2">
        {isLoading && (
          <p
            data-testid="story-share-loading"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.loading") || "Loading…"}
          </p>
        )}

        {!isLoading && error && (
          <p
            data-testid="story-share-error"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.error_loading") || "Error loading story"}
          </p>
        )}

        {!isLoading && !error && filtered.length === 0 && (
          <p
            data-testid="story-share-empty"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.no_chats") || "No recent chats"}
          </p>
        )}

        {!isLoading &&
          !error &&
          filtered.map((recipient) => {
            const sent = sentTo.indexOf(recipient._id) !== -1;
            return (
              <button
                key={recipient._id}
                type="button"
                data-testid="story-share-row"
                onClick={() => send(recipient)}
                disabled={sent || sending === recipient._id}
                className="flex w-full items-center gap-3 rounded-xl px-2 py-2 text-left hover:bg-gray-50 disabled:opacity-70 dark:hover:bg-white/5"
              >
                <Avatar src={recipient.image} name={recipient.name} size={40} />
                <span className="min-w-0 flex-1 truncate text-sm font-medium">
                  {recipient.name}
                </span>
                {sent ? (
                  <span
                    data-testid={`story-share-sent-${recipient._id}`}
                    className="flex shrink-0 items-center gap-1 text-xs font-medium text-green-600"
                  >
                    <Check size={14} aria-hidden />
                    {t("stories.shared") || "Sent"}
                  </span>
                ) : (
                  <span className="shrink-0 text-xs font-medium text-brand">
                    {t("stories.send_reply") || "Send"}
                  </span>
                )}
              </button>
            );
          })}
      </div>
    </DialogShell>
  );
};

export default StoryShareSheet;
