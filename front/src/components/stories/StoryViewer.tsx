import React, { useState, useEffect, useRef, useCallback, useMemo } from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import { useSelector } from "react-redux";
import {
  useGetUserStoriesQuery,
  useMarkIndividualStoryViewedMutation,
  useReactToStoryMutation,
  useRemoveReactionMutation,
  useReplyToStoryMutation,
  useVoteOnPollMutation,
  useDeleteIndividualStoryMutation,
  useAnswerQuestionMutation,
} from "../../store/slices/storiesSlice";
import { useTranslation } from "react-i18next";
import {
  Check,
  ChevronLeft,
  ChevronRight,
  MapPin,
  Eye,
  Heart,
  MessageCircle,
  MessageCircleQuestion,
  MoreHorizontal,
  Send,
  Share2,
  Trash2,
  Ban,
  Flag,
  X,
} from "lucide-react";
import Avatar from "../../design/Avatar";
import ConfirmDialog from "../../design/ConfirmDialog";
import notify from "../../design/notify";
import ReportMomentDialog from "../moments/actions/ReportMomentDialog";
import { useBlockUserMutation } from "../../store/slices/usersSlice";
import timeAgo from "../../utils/timeAgo";
import StoryViewersSheet from "./StoryViewersSheet";
import QuestionResponsesSheet from "./QuestionResponsesSheet";
import StoryShareSheet from "./StoryShareSheet";
import { Story, STORY_REACTIONS } from "./types";
import StoryCanvas, { isVideoStory, storyLocationName } from "./StoryCanvas";
import { userAvatarUrl } from "../../utils/photoUrl";

interface RootState {
  auth: {
    userInfo?: {
      user?: {
        _id: string;
        name: string;
        imageUrls?: string[];
      };
      data?: {
        _id: string;
        name: string;
        imageUrls?: string[];
      };
    };
  };
}

/** Which sheet is open, if any. Only ever one at a time. */
type OpenSheet = "viewers" | "responses" | "share" | null;

const PILL =
  "flex items-center gap-1.5 rounded-full bg-white/15 px-3 py-2 text-sm font-medium text-white backdrop-blur transition hover:bg-white/25";
/** The frosted card the poll and the question sticker share. */
const STICKER_CARD =
  "absolute inset-x-4 bottom-28 z-[5] rounded-card bg-black/60 p-5 text-white backdrop-blur";
const ICON_BUTTON =
  "flex items-center justify-center rounded-full border-0 bg-transparent p-2 text-white transition hover:bg-white/10";
const NAV_BUTTON =
  "pointer-events-auto flex h-11 w-11 items-center justify-center rounded-full border-0 bg-black/40 text-white backdrop-blur transition hover:bg-black/60 disabled:opacity-30";

/**
 * The poll's own fill bar, snapped to ten-percent steps.
 *
 * Tailwind cannot build a class out of a runtime number, and a percentage in
 * an inline `style` is what `storiesStyling.test.ts` forbids -- inline style
 * in this directory is reserved for story DATA (an overlay's position and
 * colour, a text story's palette) so that a reader can tell the two apart at
 * a glance. Ten buckets is plenty for a bar that sits behind the exact figure,
 * which is printed next to it.
 */
const FILL_STEPS = [
  "w-0",
  "w-[10%]",
  "w-[20%]",
  "w-[30%]",
  "w-[40%]",
  "w-[50%]",
  "w-[60%]",
  "w-[70%]",
  "w-[80%]",
  "w-[90%]",
  "w-full",
];
const fillClass = (percentage: number): string =>
  FILL_STEPS[Math.max(0, Math.min(10, Math.round(percentage / 10)))];

const idOf = (ref: any): string =>
  typeof ref === "string" ? ref : ref && ref._id ? String(ref._id) : "";

/**
 * Which option the viewer voted for, or null. Current backends say so in
 * `poll.userVoteIndex` (and redact everyone else's votes for non-owners);
 * older ones only send the full `votes[]` per option.
 */
function pollVoteIndex(poll: any, userId: string | null): number | null {
  if (!poll) return null;
  if (poll.userVoteIndex !== undefined) {
    return typeof poll.userVoteIndex === "number" && poll.userVoteIndex >= 0
      ? poll.userVoteIndex
      : null;
  }
  const options: any[] = Array.isArray(poll.options) ? poll.options : [];
  for (let i = 0; i < options.length; i += 1) {
    const option = options[i] || {};
    if (option.voted === true) return i;
    const votes: any[] = Array.isArray(option.votes) ? option.votes : [];
    if (userId && votes.some((v) => idOf(v) === userId)) return i;
  }
  return null;
}

/** An option's tally: `voteCount` when sent, else the length of `votes`. */
const voteCountOf = (option: any): number => {
  if (option && typeof option.voteCount === "number" && isFinite(option.voteCount)) {
    return option.voteCount;
  }
  return option && Array.isArray(option.votes) ? option.votes.length : 0;
};

/**
 * Whether the viewer already answered the question sticker: the server's
 * `hasAnswered` when sent, else their own entry among the responses (older
 * backends sent every response to everyone).
 */
function hasAnsweredQuestion(questionBox: any, userId: string | null): boolean {
  if (!questionBox) return false;
  if (typeof questionBox.hasAnswered === "boolean") return questionBox.hasAnswered;
  const responses: any[] = Array.isArray(questionBox.responses) ? questionBox.responses : [];
  return Boolean(userId) && responses.some((r) => r && idOf(r.user) === userId);
}

const StoryViewer: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  const location = useLocation();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const startIndex = (location.state as any)?.startIndex || 0;

  const currentUserId = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?._id || state.auth.userInfo?.data?._id || null
  );

  const [currentStoryIndex, setCurrentStoryIndex] = useState(startIndex);
  const [isHeld, setIsHeld] = useState(false);
  // Space toggles this; a finger held on the picture sets `isHeld`. Two
  // states, because releasing the mouse must not undo a deliberate pause.
  const [isKeyPaused, setIsKeyPaused] = useState(false);
  const [showReactions, setShowReactions] = useState(false);
  const [replyText, setReplyText] = useState("");
  const [showReplyInput, setShowReplyInput] = useState(false);
  const [userReaction, setUserReaction] = useState<string | null>(null);
  const [showMenu, setShowMenu] = useState(false);
  // Question sticker: the inline answer box, its anonymous toggle, and the
  // "sent" state that replaces both afterwards.
  const [showAnswerBox, setShowAnswerBox] = useState(false);
  const [answerText, setAnswerText] = useState("");
  const [answerAnonymously, setAnswerAnonymously] = useState(false);
  const [answerSent, setAnswerSent] = useState(false);
  const [openSheet, setOpenSheet] = useState<OpenSheet>(null);
  const [confirmDelete, setConfirmDelete] = useState(false);
  // Viewer-side safety tools, as in the app's menu: report the story, block
  // its author. Each pauses the story while it is open (the app's
  // _reportStory/_blockStoryAuthor pause and resume the same way).
  const [reportOpen, setReportOpen] = useState(false);
  const [confirmBlock, setConfirmBlock] = useState(false);

  const storyRef = useRef<HTMLDivElement>(null);

  // Fetch user's stories
  const {
    data: storiesData,
    isLoading,
    error,
  } = useGetUserStoriesQuery(userId || "", { skip: !userId });

  const [markViewed] = useMarkIndividualStoryViewedMutation();
  const [reactToStory] = useReactToStoryMutation();
  const [removeReaction] = useRemoveReactionMutation();
  const [replyToStory] = useReplyToStoryMutation();
  const [voteOnPoll] = useVoteOnPollMutation();
  const [deleteStory] = useDeleteIndividualStoryMutation();
  const [answerQuestion] = useAnswerQuestionMutation();
  const [blockUser, { isLoading: isBlocking }] = useBlockUserMutation();

  const stories = useMemo(() => {
    if (!storiesData) return [];
    const response = storiesData as { success?: boolean; data?: Story[]; count?: number };
    return Array.isArray(response) ? response : response.data || [];
  }, [storiesData]);

  const currentStory = stories[currentStoryIndex];
  const isOwner = currentStory?.user._id === currentUserId;

  // Five reasons to stand still: a finger held on the story, Space, an answer
  // being typed, a sheet covering it, or a confirmation waiting. Anything
  // that takes the reader's attention off the picture stops the clock, or the
  // story they come back to is not the one they left.
  const isPaused =
    isHeld ||
    isKeyPaused ||
    showAnswerBox ||
    openSheet !== null ||
    confirmDelete ||
    reportOpen ||
    confirmBlock;

  // Mark story as viewed
  useEffect(() => {
    if (currentStory && !isOwner) {
      markViewed(currentStory._id);
    }
  }, [currentStory?._id, isOwner]);

  // Restore the viewer's own reaction. The server sends `myReaction` (an
  // emoji or null) on current backends; older ones only send `reactions[]`,
  // whose `user` is a bare id string rather than a populated user.
  useEffect(() => {
    if (currentStory && currentUserId) {
      const mine = (currentStory as any).myReaction;
      if (mine !== undefined) {
        setUserReaction(typeof mine === "string" && mine ? mine : null);
        return;
      }
      const reaction = (currentStory.reactions || []).find((r: any) => {
        const reactor = r && r.user;
        const reactorId =
          typeof reactor === "string" ? reactor : reactor && reactor._id ? String(reactor._id) : "";
        return reactorId === currentUserId;
      });
      setUserReaction((reaction && reaction.emoji) || null);
    } else {
      setUserReaction(null);
    }
  }, [currentStory, currentUserId]);

  // Everything below belongs to one story and nothing else: a half-typed
  // answer must not follow the reader to the next one, "sent" must not make
  // the next question sticker look already answered, and a pause is about the
  // picture the reader was looking at.
  useEffect(() => {
    setShowAnswerBox(false);
    setAnswerText("");
    setAnswerAnonymously(false);
    setAnswerSent(false);
    setOpenSheet(null);
    setShowReactions(false);
    setShowMenu(false);
    setReportOpen(false);
    setConfirmBlock(false);
    setIsKeyPaused(false);
  }, [currentStory?._id]);

  const handleClose = useCallback(() => {
    navigate("/stories");
  }, [navigate]);

  const handleNextStory = useCallback(() => {
    if (currentStoryIndex < stories.length - 1) {
      setCurrentStoryIndex(currentStoryIndex + 1);
    } else {
      handleClose();
    }
  }, [currentStoryIndex, stories.length, handleClose]);

  const handlePrevStory = useCallback(() => {
    if (currentStoryIndex > 0) {
      setCurrentStoryIndex(currentStoryIndex - 1);
    }
  }, [currentStoryIndex]);

  const handleReaction = async (emoji: string) => {
    if (!currentStory) return;
    const storyId = currentStory._id;

    try {
      if (userReaction === emoji) {
        // DELETE, not another POST. `POST /:id/react` REPLACES the viewer's
        // reaction with the emoji it is given — it does not toggle — so
        // re-posting the same emoji left the reaction on the story while the
        // UI cleared it: the reader thought they had taken it back and the
        // owner still saw it.
        await removeReaction({ storyId, emoji }).unwrap();
        setUserReaction(null);
      } else {
        await reactToStory({ storyId, emoji }).unwrap();
        setUserReaction(emoji);
      }
    } catch (err) {
      notify.error(t("stories.reaction_failed") || "Couldn't save your reaction");
    }
    setShowReactions(false);
  };

  const handleReply = async () => {
    if (!currentStory || !replyText.trim()) return;

    try {
      await replyToStory({
        storyId: currentStory._id,
        message: replyText,
      }).unwrap();
      setReplyText("");
      setShowReplyInput(false);
    } catch (error) {
      notify.error(t("stories.reply_failed") || "Couldn't send your message");
    }
  };

  /**
   * The question sticker's own endpoint — `POST /:id/question/answer` — and
   * not the DM reply the "Answer" button used to open. An answer belongs to
   * the sticker: the owner reads it in the responses sheet, and it can be
   * sent anonymously, which a DM never can.
   */
  const handleAnswerQuestion = async () => {
    const text = answerText.trim();
    if (!currentStory || !text) return;

    try {
      await answerQuestion({
        id: currentStory._id,
        text,
        isAnonymous: answerAnonymously,
      }).unwrap();
      setAnswerText("");
      setShowAnswerBox(false);
      setAnswerSent(true);
      notify.success(t("stories.answer_sent") || "Answer sent");
    } catch (err) {
      notify.error(t("stories.answer_failed") || "Couldn't send your answer");
    }
  };

  const handlePollVote = async (optionIndex: number) => {
    if (!currentStory?.poll) return;

    try {
      await voteOnPoll({
        storyId: currentStory._id,
        optionIndex,
      }).unwrap();
    } catch (error) {
      notify.error(t("stories.vote_failed") || "Couldn't save your vote");
    }
  };

  const handleDeleteStory = async () => {
    if (!currentStory || !isOwner) return;

    try {
      await deleteStory(currentStory._id).unwrap();
      setConfirmDelete(false);
      if (stories.length === 1) {
        handleClose();
      } else {
        handleNextStory();
      }
    } catch (error) {
      notify.error(t("stories.delete_failed") || "Couldn't delete this story");
    }
    setShowMenu(false);
  };

  const handleBlockAuthor = async () => {
    if (!currentStory || isOwner) return;
    const authorId = currentStory.user && currentStory.user._id;
    if (!authorId) return;
    try {
      await blockUser(authorId).unwrap();
      setConfirmBlock(false);
      notify.success(
        t("stories.blocked", { name: currentStory.user.name }) ||
          `${currentStory.user.name} is blocked`
      );
      // Their stories are gone for this reader now; staying on one would show
      // content the block is meant to hide.
      navigate("/stories");
    } catch (err) {
      notify.error(t("stories.block_failed") || "Couldn't block this person. Try again.");
    }
  };

  /**
   * The viewer's keyboard: ← / → step, Space pauses and resumes, Escape
   * leaves.
   *
   * It stands down whenever something else has a better claim on the keys: an
   * answer being typed, a reply being typed, an open sheet or confirmation
   * (whose Escape belongs to `DialogShell`), or a focused field of any kind.
   * Space inside a text box is a space, not a pause.
   */
  const handleKeyPress = useCallback(
    (e: KeyboardEvent) => {
      if (
        showAnswerBox ||
        showReplyInput ||
        openSheet !== null ||
        confirmDelete ||
        reportOpen ||
        confirmBlock
      ) {
        return;
      }
      const tag = String((e.target as any) && (e.target as any).tagName).toLowerCase();
      if (tag === "input" || tag === "textarea" || tag === "select") return;

      if (e.key === "ArrowLeft") handlePrevStory();
      if (e.key === "ArrowRight") handleNextStory();
      if (e.key === " " || e.key === "Spacebar" || e.key === "Space") {
        // Otherwise the page scrolls under the fixed viewer.
        e.preventDefault();
        setIsKeyPaused((paused) => !paused);
      }
      if (e.key === "Escape") handleClose();
    },
    [
      showAnswerBox,
      showReplyInput,
      openSheet,
      confirmDelete,
      reportOpen,
      confirmBlock,
      handlePrevStory,
      handleNextStory,
      handleClose,
    ]
  );

  useEffect(() => {
    window.addEventListener("keydown", handleKeyPress as any);
    return () => window.removeEventListener("keydown", handleKeyPress as any);
  }, [handleKeyPress]);

  if (isLoading) {
    return (
      <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black">
        <div
          data-testid="story-loading"
          className="h-12 w-12 animate-spin rounded-full border-4 border-white/30 border-t-white"
        />
      </div>
    );
  }

  if (error || !stories.length || !currentStory) {
    return (
      <div className="fixed inset-0 z-[9999] flex flex-col items-center justify-center gap-4 bg-black text-white">
        <button
          type="button"
          className={`${ICON_BUTTON} absolute right-4 top-4`}
          onClick={handleClose}
          aria-label={t("stories.close") || "Close"}
        >
          <X size={24} aria-hidden />
        </button>
        <p>{t("stories.error_loading") || "Error loading story"}</p>
      </div>
    );
  }

  const isVideo = isVideoStory(currentStory);
  // A video runs to its own length and says when it is done (`onEnded`);
  // everything else gets the five-second clock the segment bar draws.
  const isTimed = !isVideo;
  // Missing means allowed, as in the app's model (`json['allowReplies'] != false`).
  // The server 403s a reply / share on a story that turned them off, so
  // offering the button only produces a failure toast.
  const canReply = currentStory.allowReplies !== false;
  const canShare = currentStory.allowSharing !== false;

  return (
    <>
      <div
        className="fixed inset-0 z-[9999] flex flex-col overflow-hidden bg-black"
        data-testid="story-viewer"
        data-paused={isPaused ? "true" : "false"}
        ref={storyRef}
        onMouseDown={() => setIsHeld(true)}
        onMouseUp={() => setIsHeld(false)}
        onTouchStart={() => setIsHeld(true)}
        onTouchEnd={() => setIsHeld(false)}
      >
        {/* Segment bar. The current segment IS the clock: a CSS animation
            draws the fill, `animation-play-state: paused` is the whole of
            hold-to-pause, and `animationend` is the whole of auto-advance --
            one source of truth instead of a 100ms interval writing an inline
            width that could drift out of step with it. Keyed by story id so
            a new story restarts the run. */}
        <div className="absolute inset-x-0 top-0 z-10 flex gap-1 px-2 pb-2 pt-3">
          {stories.map((segment, index) => (
            <div
              key={segment._id || index}
              className="h-[3px] flex-1 overflow-hidden rounded-full bg-white/30"
            >
              {index < currentStoryIndex && (
                <div className="h-full w-full rounded-full bg-white/50" />
              )}
              {index === currentStoryIndex &&
                (isTimed ? (
                  <div
                    key={currentStory._id}
                    data-testid="story-progress-active"
                    data-running={isPaused ? "false" : "true"}
                    onAnimationEnd={handleNextStory}
                    className={[
                      "h-full w-0 rounded-full bg-white motion-safe:animate-bt-story-progress",
                      isPaused ? "[animation-play-state:paused]" : "",
                    ].join(" ")}
                  />
                ) : (
                  <div
                    data-testid="story-progress-active"
                    className="h-full w-full rounded-full bg-white/70"
                  />
                ))}
            </div>
          ))}
        </div>

        {/* Header */}
        <div className="absolute inset-x-0 top-0 z-10 flex items-center justify-between bg-gradient-to-b from-black/50 to-transparent px-4 pb-4 pt-12">
          <div className="flex min-w-0 items-center gap-3 text-white">
            <Avatar
              src={userAvatarUrl(currentStory.user)}
              name={currentStory.user.name}
              size={40}
            />
            <span className="truncate text-sm font-semibold">{currentStory.user.name}</span>
            <span className="shrink-0 text-xs text-white/80">
              {timeAgo(currentStory.createdAt, t, { withAgo: true })}
            </span>
            {storyLocationName(currentStory) && (
              // The app's header: time · pin · place, the place truncating
              // first so the name and the time stay readable.
              <span
                data-testid="story-location"
                className="flex min-w-0 items-center gap-1 text-xs text-white/80"
                aria-label={t("stories.location_label") || "Location"}
              >
                <MapPin size={12} aria-hidden className="shrink-0" />
                <span className="truncate">{storyLocationName(currentStory)}</span>
              </span>
            )}
          </div>
          <div className="flex shrink-0 items-center gap-1">
            {(isOwner || currentUserId) && (
              <button
                type="button"
                className={ICON_BUTTON}
                data-testid="story-menu-toggle"
                onClick={() => setShowMenu(!showMenu)}
                aria-label={t("stories.more") || "More"}
              >
                <MoreHorizontal size={20} aria-hidden />
              </button>
            )}
            <button
              type="button"
              className={ICON_BUTTON}
              data-testid="story-close"
              onClick={handleClose}
              aria-label={t("stories.close") || "Close"}
            >
              <X size={20} aria-hidden />
            </button>
          </div>
        </div>

        {/* Story Content */}
        <div className="relative flex flex-1 items-center justify-center overflow-hidden">
          <StoryCanvas story={currentStory} onVideoEnded={handleNextStory} />

          {/* Poll Overlay */}
          {currentStory.poll && (
            <div className={STICKER_CARD}>
              <h3 className="mb-4 text-lg font-semibold">{currentStory.poll.question}</h3>
              {currentStory.poll.options.map((option, index) => {
                const poll: any = currentStory.poll;
                const votedIndex = pollVoteIndex(poll, currentUserId);
                // Once the viewer has voted, every option shows its share --
                // the result is what a vote buys. Another option can still be
                // tapped to change the vote (the server moves it).
                const showResults = votedIndex !== null;
                const total =
                  typeof poll.totalVotes === "number" && poll.totalVotes > 0
                    ? poll.totalVotes
                    : (poll.options as any[]).reduce((sum: number, opt: any) => sum + voteCountOf(opt), 0);
                const percentage = total > 0 ? (voteCountOf(option) / total) * 100 : 0;
                const hasVoted = votedIndex === index;

                return (
                  <button
                    key={index}
                    type="button"
                    data-testid={`story-poll-option-${index}`}
                    className={[
                      "relative mb-2 flex w-full items-center justify-between overflow-hidden",
                      "rounded-chip border-2 px-4 py-3 text-left text-base font-medium text-white transition",
                      hasVoted
                        ? "border-white bg-white/30"
                        : "border-white/30 bg-white/20 hover:border-white/50 hover:bg-white/30",
                    ].join(" ")}
                    onClick={() => !hasVoted && handlePollVote(index)}
                    disabled={hasVoted}
                  >
                    {showResults && (
                      <span
                        aria-hidden
                        className={`absolute inset-y-0 left-0 -z-10 bg-white/40 ${fillClass(
                          percentage
                        )}`}
                      />
                    )}
                    <span className="flex items-center gap-1.5">
                      {hasVoted && <Check size={16} aria-hidden />}
                      {option.text}
                    </span>
                    {showResults && (
                      <span className="text-sm font-semibold">{percentage.toFixed(0)}%</span>
                    )}
                  </button>
                );
              })}
            </div>
          )}

          {/* Question Box Overlay */}
          {currentStory.questionBox && !isOwner && (
            <div className={`${STICKER_CARD} text-center`}>
              <p className="mb-4 text-base">{currentStory.questionBox.prompt}</p>

              {answerSent || hasAnsweredQuestion(currentStory.questionBox, currentUserId) ? (
                <p
                  data-testid="story-answer-sent"
                  className="flex items-center justify-center gap-1.5 text-sm font-medium text-white"
                >
                  <Check size={16} aria-hidden />
                  {t("stories.answer_sent") || "Answer sent"}
                </p>
              ) : showAnswerBox ? (
                <div data-testid="story-answer-form" className="flex flex-col gap-2">
                  <div className="flex items-center gap-2">
                    <input
                      type="text"
                      data-testid="story-answer-input"
                      value={answerText}
                      onChange={(e) => setAnswerText(e.target.value)}
                      onKeyPress={(e) => {
                        if (e.key === "Enter") handleAnswerQuestion();
                      }}
                      placeholder={t("stories.answer_placeholder") || "Type your answer…"}
                      aria-label={t("stories.answer_question") || "Answer Question"}
                      autoFocus
                      className="min-w-0 flex-1 rounded-full bg-white/20 px-4 py-2 text-sm text-white outline-none placeholder:text-white/60"
                    />
                    <button
                      type="button"
                      data-testid="story-answer-submit"
                      onClick={handleAnswerQuestion}
                      aria-label={t("stories.send_reply") || "Send"}
                      className="rounded-full bg-white/20 p-2 text-white transition hover:bg-white/30"
                    >
                      <Send size={16} />
                    </button>
                  </div>
                  <div className="flex items-center justify-between gap-3">
                    <label className="flex items-center gap-2 text-xs text-white/90">
                      <input
                        type="checkbox"
                        data-testid="story-answer-anonymous"
                        checked={answerAnonymously}
                        onChange={(e) => setAnswerAnonymously(e.target.checked)}
                      />
                      {t("stories.answer_anonymously") || "Answer anonymously"}
                    </label>
                    <button
                      type="button"
                      data-testid="story-answer-cancel"
                      onClick={() => {
                        setShowAnswerBox(false);
                        setAnswerText("");
                      }}
                      className="text-xs text-white/70 underline"
                    >
                      {t("stories.cancel") || "Cancel"}
                    </button>
                  </div>
                </div>
              ) : (
                <button
                  type="button"
                  data-testid="story-question-answer"
                  onClick={() => setShowAnswerBox(true)}
                  className="rounded-full border-0 bg-white px-6 py-3 font-semibold text-ink-900 transition hover:opacity-90"
                >
                  {t("stories.answer_question") || "Answer Question"}
                </button>
              )}
            </div>
          )}

        </div>

        {/* Navigation */}
        <div className="pointer-events-none absolute inset-x-0 top-1/2 z-[5] flex -translate-y-1/2 justify-between px-4">
          <button
            type="button"
            className={NAV_BUTTON}
            data-testid="story-prev"
            onClick={handlePrevStory}
            disabled={currentStoryIndex === 0}
            aria-label={t("stories.previous") || "Previous"}
          >
            <ChevronLeft size={20} aria-hidden />
          </button>
          <button
            type="button"
            className={NAV_BUTTON}
            data-testid="story-next"
            onClick={handleNextStory}
            disabled={currentStoryIndex === stories.length - 1}
            aria-label={t("stories.next") || "Next"}
          >
            <ChevronRight size={20} aria-hidden />
          </button>
        </div>

        {/* Bottom Actions */}
        <div className="absolute inset-x-0 bottom-0 z-10 bg-gradient-to-t from-black/50 to-transparent p-4">
          {isOwner ? (
            // Tools, not a reply box: there is nobody to DM on your own story.
            <div className="flex flex-wrap items-center justify-center gap-2">
              <button
                type="button"
                data-testid="story-viewers-button"
                onClick={() => setOpenSheet("viewers")}
                className={PILL}
              >
                <Eye size={16} aria-hidden />
                {t("stories.viewers") || "Viewers"}
                <span className="opacity-80">{currentStory.viewCount || 0}</span>
              </button>

              {currentStory.questionBox && (
                <button
                  type="button"
                  data-testid="story-responses-button"
                  onClick={() => setOpenSheet("responses")}
                  className={PILL}
                >
                  <MessageCircleQuestion size={16} aria-hidden />
                  {t("stories.responses") || "Responses"}
                </button>
              )}

              {canShare && (
                <button
                  type="button"
                  data-testid="story-share-button"
                  onClick={() => setOpenSheet("share")}
                  className={PILL}
                >
                  <Share2 size={16} aria-hidden />
                  {t("stories.share_story") || "Share"}
                </button>
              )}
            </div>
          ) : showReplyInput ? (
            <div className="flex items-center gap-2">
              <input
                type="text"
                data-testid="story-reply-input"
                value={replyText}
                onChange={(e) => setReplyText(e.target.value)}
                placeholder={t("stories.reply_placeholder") || "Send a message..."}
                onKeyPress={(e) => e.key === "Enter" && handleReply()}
                autoFocus
                className="min-w-0 flex-1 rounded-full border border-white/30 bg-white/20 px-4 py-3 text-sm text-white outline-none backdrop-blur placeholder:text-white/70 focus:border-white/50 focus:bg-white/30"
              />
              <button
                type="button"
                className={ICON_BUTTON}
                data-testid="story-reply-send"
                onClick={handleReply}
                aria-label={t("stories.send_reply") || "Send"}
              >
                <Send size={18} aria-hidden />
              </button>
              <button
                type="button"
                className={ICON_BUTTON}
                onClick={() => setShowReplyInput(false)}
                aria-label={t("stories.cancel") || "Cancel"}
              >
                <X size={18} aria-hidden />
              </button>
            </div>
          ) : (
            <>
              {canReply ? (
                <input
                  type="text"
                  placeholder={t("stories.reply_placeholder") || "Send a message..."}
                  onFocus={() => setShowReplyInput(true)}
                  readOnly
                  className="mb-3 w-full rounded-full border border-white/30 bg-white/20 px-4 py-3 text-sm text-white outline-none backdrop-blur placeholder:text-white/70"
                />
              ) : (
                <p
                  data-testid="story-replies-off"
                  className="mb-3 text-center text-xs text-white/70"
                >
                  {t("stories.replies_off") || "Replies are turned off for this story"}
                </p>
              )}
              <div className="flex items-center justify-center gap-6">
                <button
                  type="button"
                  className={`${ICON_BUTTON} relative ${userReaction ? "text-red-500" : ""}`}
                  data-testid="story-reaction-toggle"
                  onClick={() => setShowReactions(!showReactions)}
                  aria-label={t("stories.react") || "React"}
                >
                  <Heart size={24} aria-hidden />
                  {userReaction && (
                    <span className="absolute -right-2 -top-2 text-base">{userReaction}</span>
                  )}
                </button>
                {canReply && (
                  <button
                    type="button"
                    className={ICON_BUTTON}
                    data-testid="story-reply-open"
                    onClick={() => setShowReplyInput(true)}
                    aria-label={t("stories.reply_placeholder") || "Send a message..."}
                  >
                    <MessageCircle size={24} aria-hidden />
                  </button>
                )}
                {canShare && (
                  <button
                    type="button"
                    className={ICON_BUTTON}
                    data-testid="story-share-button"
                    onClick={() => setOpenSheet("share")}
                    aria-label={t("stories.share_story") || "Share"}
                  >
                    <Share2 size={24} aria-hidden />
                  </button>
                )}
              </div>
            </>
          )}

          {/* Reaction Picker */}
          {showReactions && (
            <div className="mt-3 flex justify-center gap-3 rounded-sheet bg-black/80 p-4 backdrop-blur motion-safe:animate-bt-rise">
              {STORY_REACTIONS.map((emoji) => (
                <button
                  key={emoji}
                  type="button"
                  className={[
                    "rounded-full border-0 bg-transparent p-2 text-3xl transition hover:scale-110 hover:bg-white/10",
                    userReaction === emoji ? "scale-110 bg-white/20" : "",
                  ].join(" ")}
                  data-testid={`story-reaction-${emoji}`}
                  onClick={() => handleReaction(emoji)}
                >
                  {emoji}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Menu: delete for the owner; report and block for everyone else,
            as in the app's popup menu. */}
        {showMenu && (
          <div className="absolute end-4 top-24 z-[15] rounded-chip bg-black/90 p-2 backdrop-blur motion-safe:animate-bt-rise">
            {isOwner ? (
              <button
                type="button"
                data-testid="story-delete"
                onClick={() => setConfirmDelete(true)}
                className="flex w-full items-center gap-3 rounded-chip border-0 bg-transparent px-4 py-3 text-start text-white transition hover:bg-white/10"
              >
                <Trash2 size={16} aria-hidden />
                {t("stories.delete_story") || "Delete Story"}
              </button>
            ) : (
              <>
                <button
                  type="button"
                  data-testid="story-report"
                  onClick={() => {
                    setShowMenu(false);
                    setReportOpen(true);
                  }}
                  className="flex w-full items-center gap-3 rounded-chip border-0 bg-transparent px-4 py-3 text-start text-white transition hover:bg-white/10"
                >
                  <Flag size={16} aria-hidden />
                  {t("stories.report_story") || "Report story"}
                </button>
                <button
                  type="button"
                  data-testid="story-block"
                  onClick={() => {
                    setShowMenu(false);
                    setConfirmBlock(true);
                  }}
                  className="flex w-full items-center gap-3 rounded-chip border-0 bg-transparent px-4 py-3 text-start text-red-300 transition hover:bg-white/10"
                >
                  <Ban size={16} aria-hidden />
                  {t("stories.block_author", { name: currentStory.user.name }) ||
                    `Block ${currentStory.user.name}`}
                </button>
              </>
            )}
          </div>
        )}
      </div>

      {/* The sheets sit outside the story surface so that a click inside a
          dialog never reaches the hold-to-pause handlers on it. */}
      {openSheet === "viewers" && isOwner && (
        <StoryViewersSheet
          storyId={currentStory._id}
          onClose={() => setOpenSheet(null)}
        />
      )}
      {openSheet === "responses" && isOwner && (
        <QuestionResponsesSheet
          storyId={currentStory._id}
          onClose={() => setOpenSheet(null)}
        />
      )}
      {openSheet === "share" && canShare && (
        <StoryShareSheet
          storyId={currentStory._id}
          currentUserId={currentUserId}
          onClose={() => setOpenSheet(null)}
        />
      )}

      {/* `window.confirm()` used to ask this: a browser dialog on top of a
          full-screen viewer, unstyleable and, on a phone, barely readable. */}
      <ConfirmDialog
        open={confirmDelete}
        danger
        title={t("stories.delete_story") || "Delete Story"}
        body={
          t("stories.delete_story_confirm") ||
          "This story and its views are removed for everyone."
        }
        confirmLabel={t("stories.delete") || "Delete"}
        cancelLabel={t("stories.cancel") || "Cancel"}
        onConfirm={handleDeleteStory}
        onCancel={() => setConfirmDelete(false)}
      />
      {reportOpen && currentStory.user && (
        <ReportMomentDialog
          type="story"
          targetId={currentStory._id}
          authorId={currentStory.user._id}
          onClose={() => setReportOpen(false)}
        />
      )}
      <ConfirmDialog
        open={confirmBlock}
        danger
        busy={isBlocking}
        title={
          t("stories.block_confirm_title", { name: currentStory.user.name }) ||
          `Block ${currentStory.user.name}?`
        }
        body={
          t("stories.block_confirm_body") ||
          "They won't be able to see your profile, moments or stories, or message you, and you won't see theirs."
        }
        confirmLabel={t("stories.block_confirm") || "Block"}
        cancelLabel={t("stories.cancel") || "Cancel"}
        onConfirm={handleBlockAuthor}
        onCancel={() => setConfirmBlock(false)}
      />
    </>
  );
};

export default StoryViewer;
