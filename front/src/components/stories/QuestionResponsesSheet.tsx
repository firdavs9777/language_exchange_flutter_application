import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { MessageCircleQuestion, X } from "lucide-react";
import DialogShell from "../../design/DialogShell";
import Avatar from "../../design/Avatar";
import { useGetQuestionResponsesQuery } from "../../store/slices/storiesSlice";
import { QuestionResponse } from "./types";
import timeAgo from "../../utils/timeAgo";
import { userAvatarUrl } from "../../utils/photoUrl";

export interface QuestionResponsesSheetProps {
  storyId: string;
  onClose: () => void;
}

const TITLE_ID = "story-responses-title";

const PANEL = [
  "relative flex w-full max-w-md flex-col rounded-2xl border border-line bg-surface shadow-lg",
  "max-h-[70vh] dark:border-line-dark dark:bg-cardbg-dark",
].join(" ");

/**
 * The answers to an own story's question sticker (`GET /:id/question/responses`,
 * owner-only).
 *
 * Anonymity is enforced here, not by the API: the controller populates
 * `questionBox.responses.user` for every answer, including the ones marked
 * `isAnonymous`. So an anonymous row renders a generic avatar and the word
 * "Anonymous", never the name or picture the payload still carries, and never
 * a link to the profile. Displaying the sender of an answer they chose to
 * send anonymously would be the worst bug on this screen.
 */
const QuestionResponsesSheet: React.FC<QuestionResponsesSheetProps> = ({
  storyId,
  onClose,
}) => {
  const { t } = useTranslation();
  const { data, isLoading, error } = useGetQuestionResponsesQuery(storyId, {
    skip: !storyId,
  });

  const payload = (data as any)?.data || {};
  const responses: QuestionResponse[] = Array.isArray(payload.responses)
    ? payload.responses
    : [];
  const anonymousLabel = t("stories.anonymous") || "Anonymous";

  return (
    <DialogShell
      labelledBy={TITLE_ID}
      onClose={onClose}
      testId="story-responses-sheet"
      backdropTestId="story-responses-backdrop"
      panelClassName={PANEL}
    >
      <div className="flex items-center gap-2 border-b border-line px-4 py-3 dark:border-line-dark">
        <MessageCircleQuestion size={18} className="text-gray-500" aria-hidden />
        <div className="min-w-0 flex-1">
          <h2 id={TITLE_ID} className="text-base font-semibold">
            {t("stories.responses") || "Responses"}
          </h2>
          {payload.prompt && (
            <p
              data-testid="story-responses-prompt"
              className="truncate text-xs text-gray-500"
            >
              {payload.prompt}
            </p>
          )}
        </div>
        <button
          type="button"
          data-testid="story-responses-close"
          onClick={onClose}
          aria-label={t("stories.close") || "Close"}
          className="rounded-full p-1.5 text-gray-500 hover:bg-gray-100 dark:hover:bg-white/10"
        >
          <X size={18} />
        </button>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-2 py-2">
        {isLoading && (
          <p
            data-testid="story-responses-loading"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.loading") || "Loading…"}
          </p>
        )}

        {!isLoading && error && (
          <p
            data-testid="story-responses-error"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.error_loading") || "Error loading story"}
          </p>
        )}

        {!isLoading && !error && responses.length === 0 && (
          <p
            data-testid="story-responses-empty"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.no_responses") || "No answers yet"}
          </p>
        )}

        {!isLoading &&
          !error &&
          responses.map((response, index) => {
            const masked = !!response.isAnonymous;
            const user = masked ? null : response.user;
            const name = masked ? anonymousLabel : user?.name || anonymousLabel;
            const image = masked
              ? undefined
              : userAvatarUrl(user);

            return (
              <div
                key={index}
                data-testid="story-response-row"
                className="flex items-start gap-3 rounded-xl px-2 py-2"
              >
                <Avatar src={image} name={name} size={40} />
                <div className="min-w-0 flex-1">
                  <div className="flex items-baseline gap-2">
                    {user && user._id ? (
                      <Link
                        to={`/community/${user._id}`}
                        data-testid="story-response-author"
                        onClick={onClose}
                        className="truncate text-sm font-medium hover:underline"
                      >
                        {name}
                      </Link>
                    ) : (
                      <span className="truncate text-sm font-medium text-gray-500">
                        {name}
                      </span>
                    )}
                    <span className="shrink-0 text-xs text-gray-500">
                      {timeAgo(response.respondedAt, t, { withAgo: true })}
                    </span>
                  </div>
                  <p className="whitespace-pre-wrap break-words text-sm">
                    {response.text}
                  </p>
                </div>
              </div>
            );
          })}
      </div>
    </DialogShell>
  );
};

export default QuestionResponsesSheet;
